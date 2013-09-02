namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text,
  RemObjects.SDK.Push.APS,
  RemObjects.SDK.Push.GCM,
  RemObjects.SDK.Push.MPNS;

type
  GenericPushConnect = public class(IPushConnect)
  private
    fPushSent: MessageSentHandler;
    fPushFailed: MessageFailedDelegate;
    fPushException: PushExceptionHandler;
    fDeviceExpired: DeviceExpiredDelegate;

    class var fInstance: GenericPushConnect;
    class method getInstance: GenericPushConnect;

    method getConnects(): sequence of IPushConnect; iterator;
    
    method Push(aDevice: PushDeviceInfo; anAction: Action);
    method sendGcmMessage(aMessage: GCMMessage);

    method removeOnPushSent(param: MessageSentHandler);
    method addOnPushSent(param: MessageSentHandler);
    method addOnPushFailed(param: MessageFailedDelegate);
    method removeOnPushFailed(param: MessageFailedDelegate);
    method addOnPushException(param: PushExceptionHandler);
    method removeOnPushException(param: PushExceptionHandler);
    method addOnDeviceExpired(param: DeviceExpiredDelegate);
    method removeOnDeviceExpired(param: DeviceExpiredDelegate);
  protected
  public
    property &Type: String read "Generic";
    property APSConnect: APSConnect := new APSConnect; readonly;
    property GCMConnect: GCMConnect := new GCMConnect; readonly;
    property MPNSConnect: MPNSConnect := new MPNSConnect; readonly;
    method CheckSetup;


    
    method PushMessage(aDevice: PushDeviceInfo; aMessage: String; aBadge: nullable Int32 := nil; aSound: String := nil; sync: Boolean := false);
    method PushBadge(aDevice: PushDeviceInfo; aBadge: nullable Int32);
    method PushSound(aDevice: PushDeviceInfo; aSound: String);
    method PushSyncNeeded(aDevice:PushDeviceInfo);
    event OnPushSent: MessageSentHandler add addOnPushSent remove removeOnPushSent;
    event OnPushFailed: MessageFailedDelegate add addOnPushFailed remove removeOnPushFailed;
    event OnConnectException: PushExceptionHandler add addOnPushException remove removeOnPushException;
    event OnDeviceExpired: DeviceExpiredDelegate add addOnDeviceExpired remove removeOnDeviceExpired;
    // TODO maybe later
    //method PushData(aDevice: PushDeviceInfo; aData: Dictionary<String, Object>);

    class property Instance: GenericPushConnect read getInstance;
  end;

implementation

method GenericPushConnect.PushMessage(aDevice: PushDeviceInfo; aMessage: String; aBadge: nullable Int32 := nil; aSound: String := nil; sync: Boolean := false);
begin
  self.Push(aDevice, ()-> begin
    case aDevice type of
      ApplePushDeviceInfo: begin
        self.APSConnect.PushCombinedNotification((aDevice as ApplePushDeviceInfo), aMessage, aBadge, aSound, 1);
      end;
      GooglePushDeviceInfo: begin
        var gDevice := aDevice as GooglePushDeviceInfo;

        var lMessage := new GCMMessage()
                            .WithId(gDevice.RegistrationID)
                            .WithText(aMessage)
                            .WithSound(aSound)
                            .WithBadge(valueOrDefault(aBadge, 0));
        if (sync) then
          lMessage.WithSyncNeeded();

        self.sendGcmMessage(lMessage);
        end;
    end;
  end);  
end;

method GenericPushConnect.PushBadge(aDevice: PushDeviceInfo; aBadge: nullable Int32);
begin
  self.Push(aDevice, ()-> begin
    case aDevice type of
      ApplePushDeviceInfo: APSConnect.PushBadgeNotification((aDevice as ApplePushDeviceInfo), valueOrDefault(aBadge));
      GooglePushDeviceInfo: begin
        var gDevice := aDevice as GooglePushDeviceInfo;
        var lMessage := new GCMMessage()
                            .WithId(gDevice.RegistrationID)
                            .WithBadge(valueOrDefault(aBadge, 0));
        self.sendGcmMessage(lMessage);
      end;
    end;
  end);
end;

method GenericPushConnect.PushSound(aDevice: PushDeviceInfo; aSound: String);
begin
  self.Push(aDevice, ()-> begin
    case aDevice type of
      ApplePushDeviceInfo: APSConnect.PushAudioNotification((aDevice as ApplePushDeviceInfo), aSound);
      GooglePushDeviceInfo: begin
        var gDevice := aDevice as GooglePushDeviceInfo;
        var lMessage := new GCMMessage()
                            .WithId(gDevice.RegistrationID)
                            .WithSound(aSound);
        self.sendGcmMessage(lMessage);
      end;
    end;
  end);
end;

method GenericPushConnect.PushSyncNeeded(aDevice: PushDeviceInfo);
begin
  case aDevice type of
    ApplePushDeviceInfo: begin
      APSConnect.PushSyncNeededNotification(aDevice as ApplePushDeviceInfo, 1);
    end;
    GooglePushDeviceInfo: begin
      var gDevice := aDevice as GooglePushDeviceInfo;
      var lMessage := new GCMMessage()
                          .WithId(gDevice.RegistrationID)
                          .WithSyncNeeded();
      lMessage.CollapseKey := gDevice.RegistrationID:Substring(10);
      self.sendGcmMessage(lMessage);
    end;
  end;
end;

class method GenericPushConnect.getInstance: GenericPushConnect;
begin
  if not assigned(fInstance) then fInstance := new GenericPushConnect();
  result := fInstance;
end;

method GenericPushConnect.sendGcmMessage(aMessage: GCMMessage);
begin
  var lDummyResponse: GCMResponse;
  if (not self.GCMConnect.TryPushMessage(aMessage, out lDummyResponse)) then begin
    // need to do something here
    // - log error
    // - raise PushMessageFailed event with additional info about error
    //   in this case user app can - let's say - remove broken regId from DB
  end;
end;

method GenericPushConnect.Push(aDevice: PushDeviceInfo; anAction: Action);
begin
  try
    anAction.Invoke();
  except
    on ex: Exception do begin
      var lEvent := self.fPushException;
      if (assigned(lEvent)) then begin
        var lConnect: IPushConnect;
        case aDevice type of
          ApplePushDeviceInfo: lConnect := self.APSConnect;
          GooglePushDeviceInfo: lConnect := self.GCMConnect;
        end;
        var lArgs := new PushExceptionEventArgs(lConnect, ex);
        lEvent(self, lArgs);
        if (not lArgs.Handled) then
          raise;
      end
      else
        raise;
    end;
  end;
end;

method GenericPushConnect.getConnects: sequence of IPushConnect;
begin
  yield self.GCMConnect;
  yield self.APSConnect;
  yield self.MPNSConnect;
end;

method GenericPushConnect.addOnPushSent(param: MessageSentHandler);
begin  
  fPushSent := MessageSentHandler(&Delegate.Combine(fPushSent, param));
  for each connect in getConnects do
    connect.OnPushSent += param;
end;

method GenericPushConnect.removeOnPushSent(param: MessageSentHandler);
begin
  fPushSent := MessageSentHandler(&Delegate.Remove(fPushSent, param));
  for each connect in getConnects do
    connect.OnPushSent -= param;
end;

method GenericPushConnect.addOnPushFailed(param: MessageFailedDelegate);
begin
  fPushFailed := MessageFailedDelegate(&Delegate.Combine(fPushFailed, param));
  for each connect in getConnects do
    connect.OnPushFailed += param;
end;

method GenericPushConnect.removeOnPushFailed(param: MessageFailedDelegate);
begin
  fPushFailed := MessageFailedDelegate(&Delegate.Remove(fPushFailed, param));
  for each connect in getConnects do
    connect.OnPushFailed -= param;
end;

method GenericPushConnect.addOnPushException(param: PushExceptionHandler);
begin
  fPushException := PushExceptionHandler(&Delegate.Combine(fPushException, param));
  for each connect in getConnects do
    connect.OnConnectException += param;
end;

method GenericPushConnect.removeOnPushException(param: PushExceptionHandler);
begin
  fPushException := PushExceptionHandler(&Delegate.Remove(fPushException, param));
  for each connect in getConnects do
    connect.OnConnectException -= param;
end;

method GenericPushConnect.addOnDeviceExpired(param: DeviceExpiredDelegate);
begin
  fDeviceExpired := DeviceExpiredDelegate(&Delegate.Combine(fDeviceExpired, param));
  for each connect in getConnects do
    connect.OnDeviceExpired += param;
end;

method GenericPushConnect.removeOnDeviceExpired(param: DeviceExpiredDelegate);
begin
  fDeviceExpired := DeviceExpiredDelegate(&Delegate.Remove(fDeviceExpired, param));
  for each connect in getConnects do
    connect.OnDeviceExpired -= param;
end;

method GenericPushConnect.CheckSetup;
begin
  for each connect in self.getConnects() do begin
    connect.CheckSetup();
  end;
end;

end.

