namespace RemObjects.SDK.Push.GCM;

interface

uses
  System.Collections.Generic,
  System.IO,
  System.Linq,
  System.Net,
  System.Text,
  RemObjects.SDK,
  RemObjects.SDK.Push;

type

  GCMConnect = public class (IPushConnect)
  private
    const GCM_SEND_URL: String = 'https://android.googleapis.com/gcm/send';

    method PreparePushRequestBody(aMessage: GCMMessage): String;
    method ParseCloudResponse(aWebResponse: HttpWebResponse; aMessage: GCMMessage; out aResponse: GCMResponse);
    method ProcessResponse(aResponse: GCMResponse);
  protected
  public
    property &Type: String read "GCM";
    property ApiKey: String;
    method PushMessage(aMessage: GCMMessage): GCMResponse;
    method TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;

    event OnPushSent: MessageSentDelegate protected raise;
    event OnPushFailed: MessageFailedDelegate protected raise;
    event OnConnectException: PushExceptionDelegate protected raise;
    event OnDeviceExpired: DeviceExpiredDelegate protected raise;
    constructor; empty;
  end;

  GCMServerException = public class(Exception)
  public
    property Response: GCMResponse read assembly write;
  end;

implementation

// on error: should raise GCMException
method GCMConnect.PushMessage(aMessage: GCMMessage): GCMResponse;
begin
  var lResponse: GCMResponse;
  if (not self.TryPushMessage(aMessage, out lResponse)) then begin
    raise new GCMServerException('Error during GCM push notification', Response := lResponse);
  end;
  exit (lResponse);
end;

// on error: should return false, and out GmcResponse with error filled 
method GCMConnect.TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;
begin
  var lWebRequest := HttpWebRequest(WebRequest.Create(GCM_SEND_URL));
  lWebRequest.Method := 'POST';
  lWebRequest.ContentType := 'application/json';
  lWebRequest.UserAgent := 'RemObjects.SDK.Push';
  lWebRequest.Headers.Add('Authorization: key=' + self.ApiKey);  
  var lRequestBody := self.PreparePushRequestBody(aMessage);

  using lStream := lWebRequest.GetRequestStream() do begin
    using lWriter := new StreamWriter(lStream) do begin
      lWriter.Write(lRequestBody);
    end;
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
  exit (aResponse:Status = GCMResponse.ResponseStatus.OK);
end;

method GCMConnect.PreparePushRequestBody(aMessage: GCMMessage): String;
require
  assigned(aMessage);
  aMessage.RegistrationIds.Count > 0;
begin
  var lRequest := new JsonObject();
  var lRegIdList := new List<JsonBaseObject>();
  for each regId: String in aMessage.RegistrationIds do
    lRegIdList.Add(new JsonString(regId));
  lRequest.Add(new JsonString("registration_ids"), new JsonArray(lRegIdList));

  if (aMessage.Data.Count > 0) then begin
    var lData := new JsonObject();
    for each pair: KeyValuePair<String, String> in aMessage.Data do begin
      lData.Add(new JsonString(pair.Key), new JsonString(pair.Value));
    end;
    lRequest.Add(new JsonString("data"), lData);
  end;

  if (not String.IsNullOrEmpty(aMessage.CollapseKey)) then
    lRequest.Add(new JsonString("collapse_key"), new JsonString(aMessage.CollapseKey));

  if (aMessage.DelayWhileIdle) then
    lRequest.Add(new JsonString("delay_while_idle"), new JsonTrue());

  if (aMessage.TimeToLeave < GCMMessage.DEFAULT_TIME_TO_LIVE) then
    lRequest.Add(new JsonString("time_to_live"), new JsonNumber(aMessage.TimeToLeave));

  if (not String.IsNullOrEmpty(aMessage.RestrictedPackageName)) then
    lRequest.Add(new JsonString("restricted_package_name"), new JsonString(aMessage.RestrictedPackageName));

  if (aMessage.DryRun) then
    lRequest.Add(new JsonString("dry_run"), new JsonTrue());

  var lBuilder := new StringBuilder();
  lRequest.Serialize(new JsonWriter(lBuilder, false));
  exit (lBuilder.ToString());
end;

method GCMConnect.ParseCloudResponse(aWebResponse: HttpWebResponse; aMessage: GCMMessage; out aResponse: GCMResponse);
begin
  // success response has
  // - multicast_id
  // - success - num of messages w/o errors
  // - failure - num of messages with errors
  // - canonical_ids - Number of results that contain a canonical registration ID
  // - results - ARRAY of result, where RESULT is:
  //   - message_id - String representing the message when it was successfully processed
  //   - registration_id - (optional) - new registrationID for the device (need to replace with it in DB); not set if error
  //   - error - string with description. Values:
  //         "Unavailable" - GCM were busy/internal timeout, retry is honoured (Retry-After header)
  //         "NotRegistered" - remove regId from DB
  //         "MissingRegistration" - regId is not present in request
  //         "InvalidRegistration" - regId is invalid/malformed
  //         "MismatchSenderId" - app with this regID is supposed to get pushes from other SenderID.
  //         "MessageTooBig" - payload is more then 4kb
  //         "InvalidDataKey" - invalid key payload data
  //         "InvalidTtl" - ttl should be in 0..2,419,200(4 weeks)
  //         "InternalServerError" (Status=500) - retry honoured
  //         "InvalidPackageName" - package name of regId app doesn't match restricted_package_name from the request

  // http code = 401 - Authentication Error (authorization header missing|invalid SenderId|
  //                                          GCM service disabled|server not whitelisted)
  // http code = 400 - malformed JSON

  aResponse := new GCMResponse(aMessage, Status := GCMResponse.ResponseStatus.OK);

  case (Integer(aWebResponse.StatusCode)) of
    400:  begin
      aResponse.Status := GCMResponse.ResponseStatus.MalformedJson;
      exit;
    end;
    401:  begin
      aResponse.Status := GCMResponse.ResponseStatus.AuthenticationFailed;
      exit;
    end;
    500..599: begin
      aResponse.Status := GCMResponse.ResponseStatus.ServerInternalError;
      exit;
    end;
  end;

  var lResponseBody := new StreamReader(aWebResponse.GetResponseStream()).ReadToEnd();

  var lJsonParser := new JsonTokenizer(lResponseBody);
  var lRespObject := JsonBaseObject.ParseCurrent(lJsonParser);

  aResponse.SuccessesCount := Convert.ToInt32(JsonSerializer.GetJsonNodeByKey<JsonNumber>(lRespObject, 'success').Value);
  aResponse.FailuresCount := Convert.ToInt32(JsonSerializer.GetJsonNodeByKey<JsonNumber>(lRespObject, 'failure').Value);
  aResponse.CanonicalIdCount := Convert.ToInt32(JsonSerializer.GetJsonNodeByKey<JsonNumber>(lRespObject, 'canonical_ids').Value);

  if (aResponse.FailuresCount + aResponse.CanonicalIdCount = 0) then
    exit; // all fine, no neeed in further parsing

  var lResults := JsonSerializer.GetJsonNodeByKey<JsonArray>(lRespObject, 'results');
  
  if (assigned(lResults) and (lResults.Count > 0)) then begin
    aResponse.Status := GCMResponse.ResponseStatus.ProcessingErrors; // there were some errors during procesing of regIds
    for idx: Integer := 0 to lResults.Count - 1 do begin
      var lJsonRes := lResults[idx];
      var lGcmRes := new GCMMessageResult();
      lGcmRes.RegisteredId := aMessage.RegistrationIds[idx];
      aResponse.Results.Add(lGcmRes);

      lGcmRes.MessageId := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'message_id'):Value;

      if (not String.IsNullOrEmpty(lGcmRes.MessageId)) then begin
        lGcmRes.Status := GCMMessageResult.ResultStatus.Ok;
        lGcmRes.NewRegistrationId := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'registration_id'):Value;

        if (not String.IsNullOrEmpty(lGcmRes.NewRegistrationId)) then begin
          lGcmRes.Status := GCMMessageResult.ResultStatus.NewRegistrationId;
          continue;
        end;
      end
      else begin
        var lError := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'error'):Value;
        if (not String.IsNullOrEmpty(lError)) then begin
          case lError.Trim().ToLower() of 
            'missingregistration':    lGcmRes.Status := GCMMessageResult.ResultStatus.MissingRegistration;
            'unavailable':            lGcmRes.Status := GCMMessageResult.ResultStatus.Unavailable;
            'notregistered':          lGcmRes.Status := GCMMessageResult.ResultStatus.NotRegistered;
            'invalidregistration':    lGcmRes.Status := GCMMessageResult.ResultStatus.InvalidRegistration;
            'mismatchsenderid':       lGcmRes.Status := GCMMessageResult.ResultStatus.MismatchSenderId;
            'messagetoobig':          lGcmRes.Status := GCMMessageResult.ResultStatus.MessageTooBig;
            'invaliddatakey':         lGcmRes.Status := GCMMessageResult.ResultStatus.InvalidDataKey;
            'invalidttl':             lGcmRes.Status := GCMMessageResult.ResultStatus.InvalidTtl;
            'internalservererror':    lGcmRes.Status := GCMMessageResult.ResultStatus.InternalServerError;
            else
              lGcmRes.Status := GCMMessageResult.ResultStatus.Undefined;
          end;
        end;
      end;        
    end;
  end;  
end;

method GCMConnect.ProcessResponse(aResponse: GCMResponse);
begin
  // send events
  for each res in aResponse.Results index idx do begin
    var lMessage := aResponse.Message;
    var lSingleMessage := iif(lMessage.RegistrationIds.Count > 0, lMessage.GetSingleMessage(idx), lMessage);

    if (res.Status = GCMMessageResult.ResultStatus.Ok) then
      self.OnPushSent(self, lSingleMessage)
    else if (res.Status = GCMMessageResult.ResultStatus.NewRegistrationId) then begin
      var lNew := res.NewRegistrationId;
      var lOld := String.Empty;
      if (lSingleMessage.RegistrationIds:Count > 0) then
        lOld := lSingleMessage.RegistrationIds[0];

      self.OnDeviceExpired(self, lOld, lNew);
    end
    else if (res.Status = GCMMessageResult.ResultStatus.Unavailable) then begin
      self.OnPushFailed(self, lSingleMessage, new Exception('GCM was busy or unavailable'));
    end
    else if (res.Status = GCMMessageResult.ResultStatus.NotRegistered) then begin
      self.OnDeviceExpired(self, lSingleMessage.RegistrationIds:First(), nil);
    end
  end;
end;


end.
