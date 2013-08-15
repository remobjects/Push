namespace RemObjects.SDK.Push;

interface

type
  IPushConnect = public interface
    property &Type: String read;
    event OnPushSent: MessageSentDelegate;
    event OnPushFailed: MessageFailedDelegate;
    event OnConnectException: PushExceptionDelegate;
    event OnDeviceExpired: DeviceExpiredDelegate;
  end;

implementation

end.
