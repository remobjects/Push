namespace RemObjects.SDK.Push.MPNS;

interface

uses
  System.Runtime.CompilerServices,
  RemObjects.SDK.Push;

type
  [&Extension]
  MPNSMessageExtension = public static class
  public
    method ForId(aMessage: MPNSMessage; aMessageId: Guid): MPNSMessage;
    method ForNotificationUri(aMessage: MPNSMessage; aNotificationUri: String): MPNSMessage;
    method WithTitle(aMessage: MPNSDataMessage; aTitle: String): MPNSDataMessage;
    method WithText(aMessage: MPNSDataMessage; aText: String): MPNSDataMessage;
    method WithSound(aMessage: MPNSDataMessage; aSound: String): MPNSDataMessage;
    method WithImage(aMessage: MPNSDataMessage; anImage: String): MPNSDataMessage;
    method WithBadge(aMessage: MPNSDataMessage; aBadge: Integer): MPNSDataMessage;    
    method WithSyncNeeded(aMessage: MPNSDataMessage): MPNSDataMessage;
    method WithData(aMessage: MPNSDataMessage; aKey, aValue: String): MPNSDataMessage;
  end;

implementation

method MPNSMessageExtension.ForId(aMessage: MPNSMessage; aMessageId: Guid): MPNSMessage;
begin
  aMessage.MessageId := aMessageId;
  exit (aMessage);
end;

method MPNSMessageExtension.ForNotificationUri(aMessage: MPNSMessage; aNotificationUri: String): MPNSMessage;
begin
  aMessage.NotificationURI := aNotificationUri;
  exit (aMessage);
end;

method MPNSMessageExtension.WithTitle(aMessage: MPNSDataMessage; aTitle: String): MPNSDataMessage;
begin
  if (length(aTitle) > 0) then
    aMessage.Data["message"] := aTitle;
  exit (aMessage);
end;

method MPNSMessageExtension.WithText(aMessage: MPNSDataMessage; aText: String): MPNSDataMessage;
begin
  if (length(aText) > 0) then
    aMessage.Data["message"] := aText;
  exit (aMessage);
end;

method MPNSMessageExtension.WithSound(aMessage: MPNSDataMessage; aSound: String): MPNSDataMessage;
begin
  if (length(aSound) > 0) then
    aMessage.Data["sound"] := aSound;
  exit (aMessage);
end;

method MPNSMessageExtension.WithImage(aMessage: MPNSDataMessage; anImage: String): MPNSDataMessage;
begin
  if (length(anImage) > 0) then
    aMessage.Data["sound"] := anImage;
  exit (aMessage);
end;

method MPNSMessageExtension.WithBadge(aMessage: MPNSDataMessage; aBadge: Integer): MPNSDataMessage;
begin
  if (aBadge > 0) then
    aMessage.Data["badge"] := aBadge.ToString(System.Globalization.CultureInfo.InvariantCulture);
  exit (aMessage);
end;

method MPNSMessageExtension.WithSyncNeeded(aMessage: MPNSDataMessage): MPNSDataMessage;
begin
  aMessage.Data['sync'] := 'true';
  exit (aMessage);
end;

method MPNSMessageExtension.WithData(aMessage: MPNSDataMessage; aKey: String; aValue: String): MPNSDataMessage;
begin
  aMessage.Data.Add(aKey, aValue);
  exit (aMessage);
end;


end.
