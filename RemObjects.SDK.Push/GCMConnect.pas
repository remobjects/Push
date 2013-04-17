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
  public
    // TODO fill response better
    property StatusCode: HttpStatusCode;
  end;

  GCMConnect = public class
  private
    const GCM_SEND_URL: String = 'https://android.googleapis.com/gcm/send';

    var fSenderApiKey: String := String.Empty;

    method PreparePushRequestBody(aMessage: GCMMessage): String;
  protected
  public
    property SenderApiKey: String read fSenderApiKey;
    method PushMessage(aMessage: GCMMessage);
    method TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;

    constructor(aSenderApiKey: String);

  end;

implementation

constructor GCMConnect(aSenderApiKey: String);
require
  not String.IsNullOrEmpty(aSenderApiKey);
begin
  self.fSenderApiKey := aSenderApiKey;
end;

method GCMConnect.PushMessage(aMessage: GCMMessage);
begin
  var lResponse: GCMResponse;
  if (not self.TryPushMessage(aMessage, out lResponse)) then
    raise new Exception('Error during sending GCM push notification');
end;

method GCMConnect.TryPushMessage(aMessage: GCMMessage; out aResponse: GCMResponse): Boolean;
begin

  var lWebRequest := HttpWebRequest(WebRequest.Create(GCM_SEND_URL));
  lWebRequest.Method := 'POST';
  lWebRequest.ContentType := 'application/json';
  lWebRequest.UserAgent := 'RemObjects.SDK.Push';
  lWebRequest.Headers.Add('Authorization: key=' + self.fSenderApiKey);  
  var lRequestBody := self.PreparePushRequestBody(aMessage);

  using lStream := lWebRequest.GetRequestStream() do begin
    using lWriter := new StreamWriter(lStream) do begin
      lWriter.Write(lRequestBody);
    end;
  end;
  var lResponse: HttpWebResponse;
  try
    lResponse := HttpWebResponse(lWebRequest.GetResponse());
    aResponse := new GCMResponse(StatusCode := lResponse.StatusCode);
  except
    on we: WebException do begin
      aResponse := new GCMResponse();
      aResponse.StatusCode := HttpWebResponse(we.Response).StatusCode;
    end;
  finally
    lResponse:Close();
  end;
  exit (aResponse:StatusCode = HttpStatusCode.OK);
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

end.
