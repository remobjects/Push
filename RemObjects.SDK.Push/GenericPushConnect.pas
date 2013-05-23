namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  GenericPushConnect = public class
  private
  protected
  public
    property APSConnect: APSConnect := new APSConnect; readonly;
    property GCMConnect: GCMConnect := new GCMConnect; readonly;

    method PushMessageNotification(aDevice: PushDeviceInfo; aMessage: String);
    method PushBadgeNotification(aDevice: PushDeviceInfo; aBadge: Int32);
    method PushAudioNotification(aDevice: PushDeviceInfo; aSound: String);

    method PushMessageAndBadgeNotification(aDevice: PushDeviceInfo; aMessage: String; aBadge: nullable Int32);
  end;

implementation

method GenericPushConnect.PushMessageNotification(aDevice: PushDeviceInfo; aMessage: String);
begin
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushMessageNotification((aDevice as ApplePushDeviceInfo).Token, aMessage);
  end;
end;

method GenericPushConnect.PushBadgeNotification(aDevice: PushDeviceInfo; aBadge: Int32);
begin
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushBadgeNotification((aDevice as ApplePushDeviceInfo).Token, aBadge);
  end;
end;

method GenericPushConnect.PushAudioNotification(aDevice: PushDeviceInfo; aSound: String);
begin
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushAudioNotification((aDevice as ApplePushDeviceInfo).Token, aSound);
  end;
end;

method GenericPushConnect.PushMessageAndBadgeNotification(aDevice: PushDeviceInfo; aMessage: String; aBadge: nullable Int32);
begin
  // nil value for aBadge means we clear the badge.
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushCombinedNotification((aDevice as ApplePushDeviceInfo).Token, aMessage, valueOrDefault(aBadge), nil); // send 0 to clear the Badge, on APS
  end;
end;

end.
