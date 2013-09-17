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
  MessageType = public flags (Text = 1, Badge = 2, Sound = 4, Sync = 8);

  GenericMessageData = public class
  public
    Title: String;
    Text: String;
    Sound: String;
    Image: String;
    Badge: nullable Int32;
    SyncNeeded: Boolean;
  end;

  GenericPushConnect = public class(IPushConnect)
  private
    fPushSent: MessageSentHandler;
    fPushFailed: MessageFailedHandler;
    fDeviceExpired: DeviceExpiredHandler;

    class var fInstance: GenericPushConnect;
    class method getInstance: GenericPushConnect;

    method getConnects(): sequence of IPushConnect; iterator;
    
    method Push(aDevice: PushDeviceInfo; anAction: Action);
    method sendGcmMessage(aMessage: GCMMessage);
    method sendMpnsMessage(aMessage: MPNSMessage);

    method removeOnPushSent(param: MessageSentHandler);
    method addOnPushSent(param: MessageSentHandler);
    method addOnPushFailed(param: MessageFailedHandler);
    method removeOnPushFailed(param: MessageFailedHandler);
    method addOnDeviceExpired(param: DeviceExpiredHandler);
    method removeOnDeviceExpired(param: DeviceExpiredHandler);
  protected
    method OnMessageCreating(args: MessageCreateEventArgs);
    method OnMessageCreated(args: MessageCreateEventArgs);
  public
    property &Type: String read "Generic";
    property APSConnect: APSConnect := new APSConnect; readonly;
    property GCMConnect: GCMConnect := new GCMConnect; readonly;
    property MPNSConnect: MPNSConnect := new MPNSConnect; readonly;
    method CheckSetup;

    // the problem with generic connect is that in Android the reaction on message is defined clientside (toast, notification bar, widget, etc)
    // while on Windows Phone and iOs server decides what it will be (toast, alert, tile, badge, etc).

    // suggested types
    // Message (text, subtext)
    // Tile (badge, text, image?)
    // Raw (any key-value pairs)
    // Common (text, sound, badge, sync)

    // all types turned to Raw messages for each connect. If you want other type of messages (i.e. Toast of Tile for MPNS, then handle MessageCreating event)

    
    method PushMessage(aDevice: PushDeviceInfo; aTitle, aText: String);
    method PushCommon(aDevice: PushDeviceInfo; aTitle, aText: String; aBadge: nullable Int32; aSound, anImage: String);
    method PushBadge(aDevice: PushDeviceInfo; aBadge: nullable Int32);
    method PushSound(aDevice: PushDeviceInfo; aSound: String);
    method PushSyncNeeded(aDevice:PushDeviceInfo);
    event PushSent: MessageSentHandler add addOnPushSent remove removeOnPushSent;
    event PushFailed: MessageFailedHandler add addOnPushFailed remove removeOnPushFailed;
    event DeviceExpired: DeviceExpiredHandler add addOnDeviceExpired remove removeOnDeviceExpired;
    event ConnectException: PushExceptionHandler raise;

    event MessageSend: MessageSendHandler raise;
    event MessageCreating: MessageCreateHandler raise;
    event MessageCreated: MessageCreateHandler raise;
    // TODO maybe later
    //method PushData(aDevice: PushDeviceInfo; aData: Dictionary<String, Object>);

    class property Instance: GenericPushConnect read getInstance;
  end;

implementation

method GenericPushConnect.PushCommon(aDevice: PushDeviceInfo; aTitle, aText: String; aBadge: nullable Int32; aSound, anImage: String);
begin
  self.Push(aDevice, ()-> begin
    
    var lCbSend := self.MessageSend;
    var lCbCreating := self.MessageCreating;
    var lCbCreated := self.MessageCreated;
    var lMessageData: GenericMessageData;
    if (lCbSend <> nil) or (lCbCreated <> nil) or (lCbCreating <> nil) then begin
      lMessageData := new GenericMessageData(Text := aText, Title := aTitle, Badge := aBadge, Sound := aSound, Image := anImage, SyncNeeded := false);
    end;

    {$REGION  protected method OnMessageSend() begin }
    if (assigned(lCbSend)) then begin
      var lSendArgs := new MessageSendEventArgs(aDevice, lMessageData);
      lCbSend(self, lSendArgs);
      if (lSendArgs.Handled) then
        exit; // message sent or suspended by the user event handler
    end;
    {$ENDREGION}
    
    var lArgs: MessageCreateEventArgs;
    case aDevice type of

      ApplePushDeviceInfo: begin
        self.APSConnect.PushCombinedNotification((aDevice as ApplePushDeviceInfo), aText, aBadge, aSound, 1);
      end;

      GooglePushDeviceInfo: begin
        var lMessage: GCMMessage;
        {$REGION protected method OnMessageCreating(args) begin}
        if (assigned(lCbCreating)) then begin
          lArgs := new MessageCreateEventArgs(aDevice, lMessageData);
          lCbCreating(self, lArgs);
          if (assigned(lArgs.Message)) then
            if (lArgs.Message is GCMMessage) then
              lMessage := GCMMessage(lArgs.Message)
            else
              raise new InvalidCastException('MessageCreating callback created message of wrong type. Should create '+ typeOf(GCMMessage).Name);
          lMessage := lArgs.Message as GCMMessage;
        end;
        {$ENDREGION }
        
        if (lMessage = nil) then begin // default message creation
          var gDevice := aDevice as GooglePushDeviceInfo;

          lMessage := new GCMMessage()
                              .WithId(gDevice.RegistrationID)
                              .WithText(aText)
                              .WithTitle(aTitle)
                              .WithSound(aSound)
                              .WithImage(anImage)
                              .WithBadge(valueOrDefault(aBadge, 0));
        end;

        {$REGION protected method OnMessageCreated() begin }
        if (assigned(lCbCreated)) then begin
          if (lArgs = nil) then
            lArgs := new MessageCreateEventArgs(aDevice, lMessageData);
          lArgs.Message := lMessage;
          lCbCreated(self, lArgs);  
        end;
        {$ENDREGION }
        self.sendGcmMessage(lMessage);
      end;

      WindowsPhonePushDeviceInfo: begin        
        var lMessage: MPNSMessage;
        {$REGION protected method OnMessageCreating(args) begin}
        if (assigned(lCbCreating)) then begin
          lArgs := new MessageCreateEventArgs(aDevice, lMessageData);
          lCbCreating(self, lArgs);
          if (assigned(lArgs.Message)) then
            if (lArgs.Message is MPNSMessage) then
              lMessage := MPNSMessage(lArgs.Message)
            else
              raise new InvalidCastException('MessageCreating callback created message of wrong type. Should create '+ typeOf(MPNSMessage).Name);
          lMessage := lArgs.Message as MPNSMessage;
        end;
        {$ENDREGION }
        if (lMessage = nil) then begin // default message creation
          var lWpDevice := aDevice as WindowsPhonePushDeviceInfo;
          var lDataMessage := new MPNSDataMessage();
          lDataMessage.NotificationURI := lWpDevice.NotificationURI.ToString;
          lDataMessage.Data.Add('message', aText);
          if (assigned(aBadge)) then
            lDataMessage.Data["badge"] := aBadge.ToString(System.Globalization.CultureInfo.InvariantCulture);
          if (not String.IsNullOrEmpty(aSound)) then
            lDataMessage.Data["sound"]:= aSound;
          if (not String.IsNullOrEmpty(aSound)) then
            lDataMessage.Data["image"] := anImage;

          lMessage := lDataMessage;
        end;
        {$REGION protected method OnMessageCreated() begin }
        if (assigned(lCbCreated)) then begin
          if (lArgs = nil) then
            lArgs := new MessageCreateEventArgs(aDevice, lMessageData);
          lArgs.Message := lMessage;
          lCbCreated(self, lArgs);  
        end;
        {$ENDREGION }
        self.sendMpnsMessage(lMessage);
      end;
    end;
  end);  
end;

method GenericPushConnect.PushMessage(aDevice: PushDeviceInfo; aTitle: String; aText: String);
begin
  self.Push(aDevice, ()-> begin
    case aDevice type of
      ApplePushDeviceInfo: APSConnect.PushMessageNotification((aDevice as ApplePushDeviceInfo), aText);
      GooglePushDeviceInfo: begin
        var gDevice := aDevice as GooglePushDeviceInfo;
        var lMessage := new GCMMessage()
                            .WithId(gDevice.RegistrationID)
                            .WithText(aText)
                            .WithTitle(aTitle);
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

method GenericPushConnect.sendMpnsMessage(aMessage: MPNSMessage);
begin
  var lDummyResponse: MPNSResponse;
  if (not self.MPNSConnect.TryPushMessage(aMessage, out lDummyResponse)) then begin
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
      var lEvent := self.ConnectException;
      if (assigned(lEvent)) then begin
        var lConnect: IPushConnect;
        lConnect := case aDevice type of
          ApplePushDeviceInfo: self.APSConnect as IPushConnect;
          GooglePushDeviceInfo: self.GCMConnect as IPushConnect;
          WindowsPhonePushDeviceInfo: self.MPNSConnect as IPushConnect;
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
    connect.PushSent += param;
end;

method GenericPushConnect.removeOnPushSent(param: MessageSentHandler);
begin
  fPushSent := MessageSentHandler(&Delegate.Remove(fPushSent, param));
  for each connect in getConnects do
    connect.PushSent -= param;
end;

method GenericPushConnect.addOnPushFailed(param: MessageFailedHandler);
begin
  fPushFailed := MessageFailedHandler(&Delegate.Combine(fPushFailed, param));
  for each connect in getConnects do
    connect.PushFailed += param;
end;

method GenericPushConnect.removeOnPushFailed(param: MessageFailedHandler);
begin
  fPushFailed := MessageFailedHandler(&Delegate.Remove(fPushFailed, param));
  for each connect in getConnects do
    connect.PushFailed -= param;
end;

method GenericPushConnect.addOnDeviceExpired(param: DeviceExpiredHandler);
begin
  fDeviceExpired := DeviceExpiredHandler(&Delegate.Combine(fDeviceExpired, param));
  for each connect in getConnects do
    connect.DeviceExpired += param;
end;

method GenericPushConnect.removeOnDeviceExpired(param: DeviceExpiredHandler);
begin
  fDeviceExpired := DeviceExpiredHandler(&Delegate.Remove(fDeviceExpired, param));
  for each connect in getConnects do
    connect.DeviceExpired -= param;
end;

method GenericPushConnect.CheckSetup;
begin
  for each connect in self.getConnects() do begin
    connect.CheckSetup();
  end;
end;

method GenericPushConnect.OnMessageCreating(args: MessageCreateEventArgs);
begin
  MessageCreating(self, args);
end;

method GenericPushConnect.OnMessageCreated(args: MessageCreateEventArgs);
begin
  MessageCreated(self, args);
end;


end.

