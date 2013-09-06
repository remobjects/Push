namespace RemObjects.SDK.Push;

interface

type
  IPushConnect = public interface
    property &Type: String read;
    event PushSent: MessageSentHandler;
    event PushFailed: MessageFailedHandler;
    event DeviceExpired: DeviceExpiredHandler;
    method CheckSetup();
  end;

implementation

end.
