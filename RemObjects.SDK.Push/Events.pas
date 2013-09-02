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
  MessageFailedDelegate = public delegate(aSender: Object; aMessage: Object; anException: Exception);
  /// <summary>
  /// Device subscribtion/registration ID expired
  /// aNewId is assigned if a new subscribtion/registration ID was provided by the push service
  /// </summary>
  DeviceExpiredDelegate = public delegate(aSender: Object; anOldId, aNewId: String);
  /// <summary>
  /// general unhandled exception appeared in connect during message sending
  /// </summary>
  PushExceptionHandler = public delegate(aSender: Object; anArgs: PushExceptionEventArgs);


  PushExceptionEventArgs = public class(RemObjects.SDK.ExceptionEventArgs)
  public
    property Handled: Boolean := false;
    property Connect: IPushConnect read protected write;
    constructor(aConnect: IPushConnect; anException: Exception);
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

end.
