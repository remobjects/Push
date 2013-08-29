namespace RemObjects.SDK.Push.GCM;

interface

uses
  System.Runtime.CompilerServices,
  RemObjects.SDK.Push;

type
  [&Extension]
  GCMConnectExtension = public static class
  public
    method PushMessage(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aMessage: String; aBadge: nullable Int32 := nil; aSound: String := nil): GCMResponse;
    method PushBadge(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aBadge: nullable Int32): GCMResponse;
    method PushSound(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aSound: String): GCMResponse;
  end;

  [&Extension]
  GCMMessageExtension = public static class
  public
    method WithId(aMessage: GCMMessage; aRegistrationId: String): GCMMessage;
    method WithText(aMessage: GCMMessage; aText: String): GCMMessage;
    method WithSound(aMessage: GCMMessage; aSound: String): GCMMessage;
    method WithBadge(aMessage: GCMMessage; aBadge: Integer): GCMMessage;
    method WithData(aMessage: GCMMessage; aKey, aValue: String): GCMMessage;
    method GetSingleMessage(aMessage: GCMMessage; aIndex: Integer): GCMMessage;
  end;

implementation

method GCMConnectExtension.PushMessage(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aMessage: String; aBadge: nullable Int32; aSound: String): GCMResponse;
begin
  var lMessage := new GCMMessage();
  lMessage.RegistrationIds.Add(aDevice.RegistrationID);
  lMessage.Data.Add("message", aMessage);
  if (assigned(aBadge)) then
    lMessage.Data.Add("badge", aBadge.ToString(System.Globalization.CultureInfo.InvariantCulture));
  if (assigned(aSound)) then
    lMessage.Data.Add("sound", aSound);
  
  exit (connect.PushMessage(lMessage));

end;

method GCMConnectExtension.PushBadge(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aBadge: nullable Int32): GCMResponse;
begin
  var lMessage := new GCMMessage();
  lMessage.RegistrationIds.Add(aDevice.RegistrationID);
  lMessage.Data.Add("badge", aBadge.ToString(System.Globalization.CultureInfo.InvariantCulture));
  
  exit (connect.PushMessage(lMessage));

end;

method GCMConnectExtension.PushSound(connect: GCMConnect; aDevice: GooglePushDeviceInfo; aSound: String): GCMResponse;
begin
  var lMessage := new GCMMessage();
  lMessage.RegistrationIds.Add(aDevice.RegistrationID);
  lMessage.Data.Add("sound", aSound);
  
  exit (connect.PushMessage(lMessage));

end;

method GCMMessageExtension.WithId(aMessage: GCMMessage; aRegistrationId: String): GCMMessage;
begin
  aMessage.RegistrationIds.Add(aRegistrationId);
  exit (aMessage);
end;

method GCMMessageExtension.WithText(aMessage: GCMMessage; aText: String): GCMMessage;
begin
  if (length(aText) > 0) then
    aMessage.Data["message"] := aText;
  exit (aMessage);
end;

method GCMMessageExtension.WithSound(aMessage: GCMMessage; aSound: String): GCMMessage;
begin
  if (length(aSound) > 0) then
    aMessage.Data["sound"] := aSound;
  exit (aMessage);
end;

method GCMMessageExtension.WithBadge(aMessage: GCMMessage; aBadge: Integer): GCMMessage;
begin
  if (aBadge > 0) then
  aMessage.Data["badge"] := aBadge.ToString(System.Globalization.CultureInfo.InvariantCulture);
  exit (aMessage);
end;

method GCMMessageExtension.WithData(aMessage: GCMMessage; aKey: String; aValue: String): GCMMessage;
begin
  aMessage.Data.Add(aKey, aValue);
  exit (aMessage);
end;

method GCMMessageExtension.GetSingleMessage(aMessage: GCMMessage; aIndex: Integer): GCMMessage;
begin
  result := new GCMMessage();
  result.RegistrationIds.Add(aMessage.RegistrationIds[aIndex]);
  result.CollapseKey := aMessage.CollapseKey;
  result.Data := aMessage.Data;
  result.DelayWhileIdle := aMessage.DelayWhileIdle;
  result.TimeToLeave := aMessage.TimeToLeave;
end;


end.
