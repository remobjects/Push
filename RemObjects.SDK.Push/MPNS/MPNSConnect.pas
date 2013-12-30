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
    event PushSent : MessageSentHandler protected raise;
    event PushFailed : MessageFailedHandler protected raise;
    event DeviceExpired : DeviceExpiredHandler protected raise;
    property &Type: String read "MPNS";
    method CheckSetup; empty; virtual; // no setup needed for this connect

    property WebServiceCertificate: System.Security.Cryptography.X509Certificates.X509Certificate2;

    method PushMessage(aMessage: MPNSMessage): MPNSResponse;
    method TryPushMessage(aMessage: MPNSMessage; out aResponse: MPNSResponse): Boolean;

    // additional global setup
    // raw - delivered only if app started
    // raw - more flexible
    // toast, tile - can be delivered always

    // from generic connect
    //  push text [, sound][, badge][, syncNeeded] -> toast [with params] or raw or tile
    //  push sync needed -> toast('synchronization needed') or raw (sync=true)
    //  push badge -> tile

    // let's always send raw. If user wants toast, he handle MessageCreating event!
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

  var lNotificationType :=  valueOrDefault(aMessage.NotificationType);
  if (lNotificationType = MPNSMessageType.Toast) then
    lWebRequest.Headers.Add("X-WindowsPhone-Target", 'toast');
  if (lNotificationType = MPNSMessageType.Tile) then
    lWebRequest.Headers.Add("X-WindowsPhone-Target", 'token');

  var lSendInterval: Integer := Integer(valueOrDefault(aMessage.SendInterval))*10 + Integer(lNotificationType);
  lWebRequest.Headers.Add("X-NotificationClass", lSendInterval.ToString(System.Globalization.CultureInfo.InvariantCulture));

  if (assigned(self.WebServiceCertificate)) then
    lWebRequest.ClientCertificates.Add(self.WebServiceCertificate);

  var lBodyText := aMessage.ToXmlString();
  var lBody := Encoding.UTF8.GetBytes(lBodyText);

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
  exit (aResponse.NotificationStatus in [MPNSResponse.NotificationStatus.Suppressed, MPNSResponse.NotificationStatus.Received]);
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
          self.PushSent(self, aResponse.Message);
        MPNSResponse.NotificationStatus.QueueFull:
          self.PushFailed(self, aResponse.Message, new Exception('Message discarded as device queue is full (30 messages).'));
      end;
    end;
    HttpStatusCode.BadRequest: begin // 400
      self.PushFailed(self, aResponse.Message, new Exception('Malformed notification URI'));
    end;
    HttpStatusCode.Unauthorized: begin // 401
      self.PushFailed(self, aResponse.Message, new Exception('Sending notification is unauthorized'));
    end;
    HttpStatusCode.NotFound: begin // 404
      self.DeviceExpired(self, aResponse.Message.NotificationURI, String.Empty);
      //self.OnPushFailed(self, aResponse.Message, new Exception('Subscription is invalid'));
    end;
    HttpStatusCode.NotAcceptable: begin // 406
      self.PushFailed(self, aResponse.Message, new Exception('Per day throttling limit reached for the subscription.'));
    end;
    HttpStatusCode.PreconditionFailed: begin // 412
      self.PushFailed(self, aResponse.Message, new Exception('Message won''t be delivered. Device is disconnected'));
    end;
    HttpStatusCode.ServiceUnavailable: begin
      self.PushFailed(self, aResponse.Message, new Exception('Push Notification Service is unable to process the request. Resend later.'));
    end
    else
      self.PushFailed(self, aResponse.Message,new Exception('Unexpected http error ' + Int32(aResponse.HttpStatus)));
  end;
end;

end.
