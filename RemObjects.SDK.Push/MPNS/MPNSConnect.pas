namespace RemObjects.SDK.Push.MPNS;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Net,
  System.Text,
  RemObjects.SDK.Push;

type
  MPNSConnect = public class (IPushConnect)
  private
    method ParseCloudResponse(aWebResponse: HttpWebResponse; aMessage: MPNSMessage; out aResponse: MPNSResponse);
    method ProcessResponse(aResponse: MPNSResponse);
  public
    event OnPushSent : MessageSentDelegate protected raise;
    event OnPushFailed : MessageFailedDelegate protected raise;
    event OnConnectException : PushExceptionDelegate protected raise;
    event OnDeviceExpired : DeviceExpiredDelegate protected raise;
    property &Type: String read "MPNS";

    property WebServiceCertificate: System.Security.Cryptography.X509Certificates.X509Certificate2;

    method PushMessage(aMessage: MPNSMessage): MPNSResponse;
    method TryPushMessage(aMessage: MPNSMessage; out aResponse: MPNSResponse): Boolean;
  end;

implementation

method MPNSConnect.PushMessage(aMessage: MPNSMessage): MPNSResponse;
begin
  var lResponse: MPNSResponse;
  if (not self.TryPushMessage(aMessage, out lResponse)) then begin
    raise new MPNSServerException('Error during MPNS push notification', Response := lResponse);
  end;
  exit (lResponse);
end;

method MPNSConnect.TryPushMessage(aMessage: MPNSMessage; out aResponse: MPNSResponse): Boolean;
begin
  var lWebRequest := HttpWebRequest(WebRequest.Create(aMessage.NotificationURI));
  lWebRequest.Method := 'POST';
  lWebRequest.ContentType := 'text/xml';

  if (assigned(aMessage.MessageId)) then
    lWebRequest.Headers.Add("X-MessageID", aMessage.MessageId.ToString());

  var lNotificationType: MPNSMessageType := MPNSMessageType.Raw;
  if (assigned(aMessage.NotificationType)) then begin
    lNotificationType := valueOrDefault(aMessage.NotificationType);
    if (lNotificationType = MPNSMessageType.Toast) then
      lWebRequest.Headers.Add("X-WindowsPhone-Target", 'toast');
    if (lNotificationType = MPNSMessageType.Tile) then
      lWebRequest.Headers.Add("X-WindowsPhone-Target", 'token');
  end;

  if (assigned(aMessage.SendInterval)) then begin
    var lValue: Integer := Integer(lNotificationType)*10 + Integer(valueOrDefault(aMessage.SendInterval));
    lWebRequest.Headers.Add("X-NotificationClass", lValue.ToString());
  end;
  if (assigned(self.WebServiceCertificate)) then
    lWebRequest.ClientCertificates.Add(self.WebServiceCertificate);

  var lBodyText := aMessage.ToXmlString();
  var lBody := Encoding.Default.GetBytes(lBodyText);

  lWebRequest.ContentLength := lBody.Length;

  using requestStream := lWebRequest.GetRequestStream() do begin
    requestStream.Write(lBody, 0, lBody.Length);
  end;
  var lResponse: HttpWebResponse;
  try  
    lResponse := HttpWebResponse(lWebRequest.GetResponse());
    ParseCloudResponse(lResponse, aMessage, out aResponse);    
  except
    on we: WebException do begin
      ParseCloudResponse(HttpWebResponse(we.Response), aMessage, out aResponse);
    end;
  finally
    lResponse:Close();
  end;
  ProcessResponse(aResponse);
end;

method MPNSConnect.ParseCloudResponse(aWebResponse: HttpWebResponse; aMessage: MPNSMessage; out aResponse: MPNSResponse);
begin
  aResponse := new MPNSResponse(aMessage);
  aResponse.HttpStatus := aWebResponse.StatusCode;

  var lMessageId := aWebResponse.Headers['X-MessageID'];
  var lNotificationStatus := aWebResponse.Headers['X-NotificationStatus'];
  var lSubscriptionStatus := aWebResponse.Headers['X-SubscriptionStatus'];
  var lDeviceConnectionStatus := aWebResponse.Headers['X-DeviceConnectionStatus'];
 
  try
    aResponse.MessageId := new Guid(lMessageId);
  except
  end;
  try
    aResponse.DeviceConnectionStatus := MPNSResponse.DeviceConnectionStatus(Enum.Parse(
                                       typeOf(MPNSResponse.DeviceConnectionStatus), lDeviceConnectionStatus, true));
  except
  end;
  try
    aResponse.NotificationStatus := MPNSResponse.NotificationStatus(Enum.Parse(
                                       typeOf(MPNSResponse.NotificationStatus), lNotificationStatus, true));
  except
  end;
  try
    aResponse.SubscriptionStatus := MPNSResponse.SubscriptionStatus(Enum.Parse(
                                       typeOf(MPNSResponse.SubscriptionStatus), lSubscriptionStatus, true));
  except
  end;
end;

method MPNSConnect.ProcessResponse(aResponse: MPNSResponse);
require
  assigned(aResponse)
begin
  case (aResponse.HttpStatus) of
    HttpStatusCode.OK: begin // 200
      case (aResponse.NotificationStatus) of
        MPNSResponse.NotificationStatus.Received, // delivered to device
        MPNSResponse.NotificationStatus.Suppressed: // not delivered due to device app
          self.OnPushSent(self, aResponse.Message);
        MPNSResponse.NotificationStatus.QueueFull:
          self.OnPushFailed(self, aResponse.Message, new Exception('Message discarded as device queue is full (30 messages).'));
      end;
    end;
    HttpStatusCode.BadRequest: begin // 400
      self.OnPushFailed(self, aResponse.Message, new Exception('Malformed notification URI'));
    end;
    HttpStatusCode.Unauthorized: begin // 401
      self.OnPushFailed(self, aResponse.Message, new Exception('Sending notification is unauthorized'));
    end;
    HttpStatusCode.NotFound: begin // 404
      self.OnDeviceExpired(self, aResponse.Message.NotificationURI, String.Empty);
      //self.OnPushFailed(self, aResponse.Message, new Exception('Subscription is invalid'));
    end;
    HttpStatusCode.NotAcceptable: begin // 406
      self.OnPushFailed(self, aResponse.Message, new Exception('Per day throttling limit reached for the subscription.'));
    end;
    HttpStatusCode.PreconditionFailed: begin // 412
      self.OnPushFailed(self, aResponse.Message, new Exception('Message won''t be delivered. Device is disconnected'));
    end;
    HttpStatusCode.ServiceUnavailable: begin
      self.OnPushFailed(self, aResponse.Message, new Exception('Push Notification Service is unable to process the request. Resend later.'));
    end
    else
      self.OnPushFailed(self, aResponse.Message,new Exception('Unexpected http error ' + Int32(aResponse.HttpStatus)));
  end;
end;

end.
