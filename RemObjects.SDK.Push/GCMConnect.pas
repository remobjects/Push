namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.IO,
  System.Linq,
  System.Net,
  System.Text,
  RemObjects.SDK;

type
  GCMMessage = public class
  public   
    const DEFAULT_TIME_TO_LIVE: Integer = 3600 * 24 * 4; //4 weeks, in seconds
  public
    property RegistrationIds: List<String> := new List<String>;
    property CollapseKey: String read write;
    property Data: Dictionary<String, String> := new Dictionary<String,String>();
    property DelayWhileIdle: Boolean := false;
    property TimeToLeave: Integer := DEFAULT_TIME_TO_LIVE;
    property RestrictedPackageName: String;
    property DryRun: Boolean := false;
  end;

  GCMResponse = public class
  assembly
    property MulticastId: Integer := 0;
  public
    property SuccessesCount: Integer := 0;
    property FailuresCount: Integer := 0;
    property CanonicalIdCount: Integer := 0;
    property Results: List<ResponseResult> := new List<ResponseResult>();    
    property Status: GCMServerResponseStatus;
  end;

  ResponseResult nested in GCMResponse = public class
    assembly MessageId: String;
    property RegisteredId: String; // get it from request
    property NewRegistrationId: String;
    property Status: ResponseResultStatus := ResponseResultStatus.Ok;


  end;

  ResponseResultStatus nested in GCMResponse = public enum (
    Undefined,
    Ok,
    NewRegistrationId, // new canonical registration Id was provided - update your db record
    Unavailable, // GCM were busy/internal timeout, retry is honoured (Retry-After header)
    NotRegistered, // remove regId from DB
    MissingRegistration, // regId is not present in request
    InvalidRegistration, // regId is invalid/malformed
    MismatchSenderId, // app with this regID is supposed to get pushes from other SenderID.
    MessageTooBig, // payload is more then 4kb
    InvalidDataKey, // invalid key payload data
    InvalidTtl, // ttl should be in 0..2,419,200(4 weeks)
    InternalServerError, // (Status=500) - retry honoured
    InvalidPackageName  // package name of regId app doesn't match restricted_package_name from the request
  );

  GCMServerResponseStatus = public enum (OK, MalformedJson, AuthenticationFailed, ProcessingErrors , ServerInternalError);

  GCMServerException = public class(Exception)
  public
    property Response: GCMResponse read assembly write;
  end;

  GCMConnect = public class
  private
    const GCM_SEND_URL: String = 'https://android.googleapis.com/gcm/send';

    method PreparePushRequestBody(aMessage: GCMMessage): String;
    method ParseCloudResponse(aWebResponse: HttpWebResponse; aMessage: GCMMessage; out aResponse: GCMResponse);
  protected
  public
    property SenderApiKey: String;
    method PushMessage(aMessage: GCMMessage);
    method TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;

    constructor; empty;

  end;

implementation

// on error: should raise GCMException
method GCMConnect.PushMessage(aMessage: GCMMessage);
begin
  var lResponse: GCMResponse;
  if (not self.TryPushMessage(aMessage, out lResponse)) then begin
    raise new GCMServerException('Error during GCM push notification', Response := lResponse);
  end;
end;

// on error: should return false, and our GmcResponse with error filled 
method GCMConnect.TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;
begin

  var lWebRequest := HttpWebRequest(WebRequest.Create(GCM_SEND_URL));
  lWebRequest.Method := 'POST';
  lWebRequest.ContentType := 'application/json';
  lWebRequest.UserAgent := 'RemObjects.SDK.Push';
  lWebRequest.Headers.Add('Authorization: key=' + self.SenderApiKey);  
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
  exit (aResponse:Status = GCMServerResponseStatus.OK);
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

  aResponse := new RemObjects.SDK.Push.GCMResponse(Status := RemObjects.SDK.Push.GCMServerResponseStatus.OK);

  case (Integer(aWebResponse.StatusCode)) of
    400:  begin
      aResponse.Status := RemObjects.SDK.Push.GCMServerResponseStatus.MalformedJson;
      exit;
    end;
    401:  begin
      aResponse.Status := RemObjects.SDK.Push.GCMServerResponseStatus.AuthenticationFailed;
      exit;
    end;
    500..599: begin
      aResponse.Status := RemObjects.SDK.Push.GCMServerResponseStatus.ServerInternalError;
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
    aResponse.Status := GCMServerResponseStatus.ProcessingErrors; // there were some errors during procesing of regIds
    for idx: Integer := 0 to lResults.Count - 1 do begin
      var lJsonRes := lResults[idx];
      var lGcmRes := new GCMResponse.ResponseResult();
      lGcmRes.RegisteredId := aMessage.RegistrationIds[idx];
      aResponse.Results.Add(lGcmRes);

      lGcmRes.MessageId := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'message_id'):Value;

      if (not String.IsNullOrEmpty(lGcmRes.MessageId)) then begin
        lGcmRes.Status := GCMResponse.ResponseResultStatus.Ok;
        lGcmRes.NewRegistrationId := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'registration_id'):Value;

        if (not String.IsNullOrEmpty(lGcmRes.NewRegistrationId)) then begin
          lGcmRes.Status := GCMResponse.ResponseResultStatus.NewRegistrationId;
          continue;
        end;
      end
      else begin
        var lError := JsonSerializer.GetJsonNodeByKey<JsonString>(lJsonRes, 'error'):Value;
        if (not String.IsNullOrEmpty(lError)) then begin
          case lError.Trim().ToLower() of 
            'missingregistration':    lGcmRes.Status := GCMResponse.ResponseResultStatus.MissingRegistration;
            'unavailable':            lGcmRes.Status := GCMResponse.ResponseResultStatus.Unavailable;
            'notregistered':          lGcmRes.Status := GCMResponse.ResponseResultStatus.NotRegistered;
            'invalidregistration':    lGcmRes.Status := GCMResponse.ResponseResultStatus.InvalidRegistration;
            'mismatchsenderid':       lGcmRes.Status := GCMResponse.ResponseResultStatus.MismatchSenderId;
            'messagetoobig':          lGcmRes.Status := GCMResponse.ResponseResultStatus.MessageTooBig;
            'invaliddatakey':         lGcmRes.Status := GCMResponse.ResponseResultStatus.InvalidDataKey;
            'invalidttl':             lGcmRes.Status := GCMResponse.ResponseResultStatus.InvalidTtl;
            'internalservererror':    lGcmRes.Status := GCMResponse.ResponseResultStatus.InternalServerError;
            else
              lGcmRes.Status := GCMResponse.ResponseResultStatus.Undefined;
          end;
        end;
      end;        
    end;
  end;
end;

end.
