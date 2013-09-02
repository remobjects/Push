namespace RemObjects.SDK.Push;

interface

type
  IPushConnect = public interface
    property &Type: String read;
    event OnPushSent: MessageSentHandler;
    event OnPushFailed: MessageFailedDelegate;
    event OnConnectException: PushExceptionHandler;
    event OnDeviceExpired: DeviceExpiredDelegate;
    method CheckSetup();
  end;

implementation

end.
