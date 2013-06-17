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
    ApplePushDeviceInfo: self.APSConnect.PushMessageNotification((aDevice as ApplePushDeviceInfo), aMessage);
    GooglePushDeviceInfo: begin
      var gDevice := aDevice as GooglePushDeviceInfo;
      var lMessage := new GCMMessage();
      lMessage.RegistrationIds.Add(gDevice.RegistrationID);
      lMessage.Data.Add("message", aMessage);
      self.GCMConnect.PushMessage(lMessage);
    end;
  end;
end;

method GenericPushConnect.PushBadgeNotification(aDevice: PushDeviceInfo; aBadge: Int32);
begin
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushBadgeNotification((aDevice as ApplePushDeviceInfo), aBadge);
    GooglePushDeviceInfo: begin
      var gDevice := aDevice as GooglePushDeviceInfo;
      var lMessage := new GCMMessage();
      lMessage.RegistrationIds.Add(gDevice.RegistrationID);
      lMessage.Data.Add("badge", aBadge.ToString);
      self.GCMConnect.PushMessage(lMessage);
    end;
  end;
end;

method GenericPushConnect.PushAudioNotification(aDevice: PushDeviceInfo; aSound: String);
begin
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushAudioNotification((aDevice as ApplePushDeviceInfo), aSound);
    GooglePushDeviceInfo: begin
      var gDevice := aDevice as GooglePushDeviceInfo;
      var lMessage := new GCMMessage();
      lMessage.RegistrationIds.Add(gDevice.RegistrationID);
      lMessage.Data.Add("audio", aSound);
      self.GCMConnect.PushMessage(lMessage);
    end;
  end;
end;

method GenericPushConnect.PushMessageAndBadgeNotification(aDevice: PushDeviceInfo; aMessage: String; aBadge: nullable Int32);
begin
  // nil value for aBadge means we clear the badge.
  case aDevice type of
    ApplePushDeviceInfo: APSConnect.PushCombinedNotification((aDevice as ApplePushDeviceInfo), aMessage, valueOrDefault(aBadge), nil); // send 0 to clear the Badge, on APS
    GooglePushDeviceInfo: begin
      var gDevice := aDevice as GooglePushDeviceInfo;
      var lMessage := new GCMMessage();
      lMessage.RegistrationIds.Add(gDevice.RegistrationID);
      lMessage.Data.Add("message", aMessage);
      lMessage.Data.Add("badge", valueOrDefault(aBadge, 0).ToString);
      self.GCMConnect.PushMessage(lMessage);
    end;
  end;
end;

end.

