namespace RemObjects.SDK.Push;

interface

type
  /// <summary>
  /// Message sent successfully
  /// </summary>
  MessageSentHandler = public delegate(aSender: Object; aMessage: Object);
  /// <summary>
  /// Message failed to sent. anException containes the explanation.
  /// </summary>
  MessageFailedHandler = public delegate(aSender: Object; aMessage: Object; anException: Exception);
  /// <summary>
  /// Device subscribtion/registration ID expired
  /// aNewId is assigned if a new subscribtion/registration ID was provided by the push service
  /// </summary>
  DeviceExpiredHandler = public delegate(aSender: Object; anOldId, aNewId: String);
  /// <summary>
  /// general unhandled exception appeared in connect during message sending
  /// </summary>
  PushExceptionHandler = public delegate(aSender: Object; anArgs: PushExceptionEventArgs);

  MessageSendHandler = public delegate(aSender: Object; anArgs: MessageSendEventArgs);
  MessageCreateHandler = public delegate(aSender: Object; anArgs: MessageCreateEventArgs);


  PushExceptionEventArgs = public class(RemObjects.SDK.ExceptionEventArgs)
  public
    property Handled: Boolean := false;
    property Connect: IPushConnect read protected write;
    constructor(aConnect: IPushConnect; anException: Exception);
  end;

  MessageSendEventArgs = public class(EventArgs)
  public
    property Device: PushDeviceInfo; readonly;
    property MessageData: GenericMessageData; readonly;
    property Handled: Boolean := false;
  private
    constructor; empty;
  assembly
    constructor(aDevice: PushDeviceInfo; aData: GenericMessageData);
  end;

  MessageCreateEventArgs = public class(EventArgs)
  public
    property Device: PushDeviceInfo; readonly;
    property MessageData: GenericMessageData; readonly;
    property Message: Object;
  private
    constructor; empty;
  assembly
    constructor(aDevice: PushDeviceInfo; aData: GenericMessageData);
  end;

  DeviceExpiredException = public class(Exception)
  public
    property OldRegistrationId: String;
    property NewRegistrationId: String;
  end;

  InvalidSetupException = public class(Exception)
  public
    property Connect: IPushConnect; readonly;
    constructor(aConnect: IPushConnect; aMessage: String; aInnerException: Exception := nil);
  end;

implementation

constructor InvalidSetupException(aConnect: IPushConnect; aMessage: String; aInnerException: Exception);
begin
  self.Connect := aConnect;
  inherited constructor(aMessage, aInnerException);
end;

constructor PushExceptionEventArgs(aConnect: IPushConnect; anException: Exception);
begin
  self.Connect := aConnect;
  inherited constructor(anException);
end;

constructor MessageSendEventArgs(aDevice: PushDeviceInfo; aData: GenericMessageData);
begin
  self.Device := aDevice;
  self.MessageData := aData;
end;

constructor MessageCreateEventArgs(aDevice: PushDeviceInfo; aData: GenericMessageData);
begin  
  self.Device := aDevice;
  self.MessageData := aData;
end;

end.
