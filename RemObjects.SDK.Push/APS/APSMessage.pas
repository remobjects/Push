namespace RemObjects.SDK.Push.APS;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text,
  RemObjects.SDK;

type
  APSMessage = public class
  public
    property Identifier: Integer;
    property DeviceToken: String;
    property Expiration: DateTime;

    property Payload: Payload;

    constructor; empty;
    constructor(aToken: String; aPayload: Payload := nil); empty;

  end;

  Payload nested in APSMessage = public class
  public
    property Alert: Alert;
    property Badge: nullable Integer;
    property Sound: String;
    property ContentAvailable: Boolean;
    property Data: Dictionary<String, array of Object> := new Dictionary<String, array of Object>(); 
    property HideAction: Boolean := false;

    constructor;
    constructor(anAlert: String);
    constructor(anAlert: String; aBadge: Integer; aSound: String := nil);

    method AddCustomData(aKey: String; params aValues: array of Object): Payload;
    method ToJsonString(): String;
  end;

  Alert nested in APSMessage = public class
  public
    property Body: String;
    property ActionLocKey: String;
    property MessageLocKey: String;
    property MessageLocArgs: List<String> := new List<String>;
    property LaunchImage: String;
    
    method AddMessageLocArgs(params aValues: array of String);
    method IsEmpty: Boolean;
    method IsSimple: Boolean;
  end;

implementation

constructor APSMessage.Payload;
begin
  self.Alert := new Alert();
end;

constructor APSMessage.Payload(anAlert: String);
begin
  self.Alert := new Alert(Body:= anAlert);
end;

constructor APSMessage.Payload(anAlert: String; aBadge: Integer; aSound: String);
begin
  self.Alert := new Alert(Body := anAlert);
  self.Badge := aBadge;
  self.Sound := aSound;
end;

method APSMessage.Payload.AddCustomData(aKey: String; params aValues: array of Object): Payload;
begin
  if (length(aKey)> 0) and (length(aValues)> 0) then
    self.Data[aKey] := aValues;

  exit (self);
end;

method APSMessage.Payload.ToJsonString: String;
  method Encode(aValue: Object): String;
  var
    lTempDbl: Double;
    lTempBool: Boolean;
    lTextValue: String := aValue.ToString;
  begin
    if (Double.TryParse(lTextValue, out lTempDbl)) or (Boolean.TryParse(lTextValue, out lTempBool)) then
      exit lTextValue
    else // consider it as string
      exit JsonTokenizer.EncodeString(lTextValue);
  end;
begin
  var json := new StringBuilder();

  var aps := new StringBuilder();

  if  (not self.Alert.IsEmpty) then begin
    if (self.Alert.IsSimple) and (not self.HideAction) then begin
      aps.AppendFormat('"alert":{0},', JsonTokenizer.EncodeString(self.Alert.Body));
    end
    else begin
      var jsonAlert := new StringBuilder();

      if length(self.Alert.MessageLocKey) > 0 then
        jsonAlert.AppendFormat('"loc-key":{0},', JsonTokenizer.EncodeString(self.Alert.MessageLocKey));

      if (self.Alert.MessageLocArgs:Count > 0) then begin
        var locArgs := new StringBuilder();

        for each larg in self.Alert.MessageLocArgs do begin
          locArgs.AppendFormat('{0},', Encode(larg));
        end;

        jsonAlert.AppendFormat('"loc-args":[{0}],', locArgs.ToString().TrimEnd(','))
      end;

      if  length(self.Alert.Body) > 0  then
        jsonAlert.AppendFormat('"body":{0},', JsonTokenizer.EncodeString(self.Alert.Body));

      if  self.HideAction  then
        jsonAlert.AppendFormat('"action-loc-key":null,')
      else
        if  length(self.Alert.ActionLocKey) > 0  then
          jsonAlert.AppendFormat('"action-loc-key":{0},', JsonTokenizer.EncodeString(self.Alert.ActionLocKey));

      aps.Append('"alert":{');
      aps.Append(jsonAlert.ToString().TrimEnd(','));
      aps.Append('},')
    end
  end;

  if  assigned(self.Badge)  then
    aps.AppendFormat('"badge":{0},', self.Badge.ToString());

  if  length(self.Sound) > 0  then
    aps.AppendFormat('"sound":{0},', JsonTokenizer.EncodeString(self.Sound));

  if self.ContentAvailable  then
    aps.AppendFormat('"content-available":1,');

  json.Append('"aps":{');
  json.Append(aps.ToString().TrimEnd(','));
  json.Append('},');

  for each key: System.String in self.Data.Keys do begin
    var lItem := self.Data[key];
    if self.Data[key].Length = 1 then
      json.AppendFormat('"{0}":{1},', key, Encode(self.Data[key][0]))
    else
      if self.Data[key].Length > 1 then begin
      var jarr := new StringBuilder();

      for each item in self.Data[key] do begin
          jarr.AppendFormat('{0},', Encode(item))
      end;

      json.AppendFormat('"{0}":[{1}],', key, jarr.ToString().Trim(','))
    end
  end;

  var rawString:= '{' + json.ToString().TrimEnd(',') + '}';

  exit (rawString);
end;

method APSMessage.Alert.AddMessageLocArgs(params aValues: array of String);
begin
  self.MessageLocArgs.AddRange(aValues);
end;

method APSMessage.Alert.IsEmpty: Boolean;
begin
  exit  String.IsNullOrEmpty(self.Body) and String.IsNullOrEmpty(ActionLocKey) and
        String.IsNullOrEmpty(MessageLocKey) and String.IsNullOrEmpty(LaunchImage) and
        (length(MessageLocArgs) = 0);
end;

method APSMessage.Alert.IsSimple: Boolean;
begin
  exit  (not String.IsNullOrEmpty(Body)) and String.IsNullOrEmpty(ActionLocKey) and
        String.IsNullOrEmpty(MessageLocKey) and String.IsNullOrEmpty(LaunchImage) and
        (length(MessageLocArgs) = 0);
end;

end.
