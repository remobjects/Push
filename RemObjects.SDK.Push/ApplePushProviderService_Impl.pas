namespace RemObjects.SDK.Push;

interface

uses
  System,
  System.IO,
  System.Runtime.Remoting.Messaging,
  RemObjects.SDK,
  RemObjects.SDK.Types,
  RemObjects.SDK.Server,
  RemObjects.SDK.Server.ClassFactories;
    
type
  [RemObjects.SDK.Server.ClassFactories.StandardClassFactory]
  [RemObjects.SDK.Server.Service(Name := 'ApplePushProviderService', InvokerClass := typeOf(ApplePushProviderService_Invoker), ActivatorClass := typeOf(ApplePushProviderService_Activator))]
  ApplePushProviderService = public class(RemObjects.SDK.Server.Service, IApplePushProviderService)
  private 
    method Log(aMessage: String);
    method InitializeComponent;
    var components: System.ComponentModel.Container := nil;
  protected 
    method Dispose(aDisposing: System.Boolean); override;
  public 
    constructor;
    method registerDevice(deviceToken: RemObjects.SDK.Types.Binary; additionalInfo: System.String); locked on typeOf(PushManager);
    method unregisterDevice(deviceToken: RemObjects.SDK.Types.Binary); locked on typeOf(PushManager);
  end;

implementation

constructor ApplePushProviderService;
begin
  inherited constructor();
  self.InitializeComponent();
  self.RequireSession := PushManager.Instance.RequireSession;
end;

method ApplePushProviderService.Log(aMessage: String);
begin
  File.AppendAllText(Path.ChangeExtension(typeOf(self).Assembly.Location, '.log'), DateTime.Now.ToString('yyyy-MM-dd HH:mm:ss')+' '+aMessage+#13#10);
end;

method ApplePushProviderService.InitializeComponent;
begin
end;

method ApplePushProviderService.Dispose(aDisposing: System.Boolean);
begin
  if aDisposing then begin
    if (self.components <> nil) then begin
      self.components.Dispose();
    end;
  end;
  inherited Dispose(aDisposing);
end;

method ApplePushProviderService.registerDevice(deviceToken: RemObjects.SDK.Types.Binary; additionalInfo: System.String);
var lPush := PushManager.Instance;
begin
  try
    var lStringToken := APSConnect.BinaryToString(deviceToken);
    Log('Push registration for '+ lStringToken);
    var lDevice: PushDeviceInfo;
    if lPush.DeviceManager.TryGetDevice(lStringToken, out lDevice) then begin
      Log('Push registration updated for '+lStringToken);

      lDevice.ClientInfo := additionalInfo;
      lDevice.LastSeen := DateTime.Now;
      lPush.Flush;
      lPush.DeviceRegistered(self, new DeviceEventArgs(DeviceToken := lStringToken, Mode := DeviceEventArgs.EventMode.Registered));
    end
    else begin
      Log('Push registration new for '+ lStringToken);
      lDevice := new ApplePushDeviceInfo(Token := deviceToken, 
                                       SubType := 'iOS',
                                       UserReference := iif(HasSession, Session['UserID']:ToString, nil),
                                       ClientInfo := additionalInfo, 
                                       ServerInfo := nil,
                                       LastSeen := DateTime.Now);
      lPush.DeviceManager.AddDevice(lStringToken, lDevice);
      lPush.Flush;
    end;
  except
    on E:Exception do begin
      Log(E.Message);
      Log(E.StackTrace);
    end;
  end;
end;

method ApplePushProviderService.unregisterDevice(deviceToken: RemObjects.SDK.Types.Binary);
var lPush := PushManager.Instance;
begin
  var lStringToken := APSConnect.BinaryToString(deviceToken);
  if (lPush.DeviceManager.RemoveDevice(lStringToken)) then begin
    lPush.Flush;
    lPush.DeviceUnregistered(self, new DeviceEventArgs(DeviceToken := lStringToken, Mode := DeviceEventArgs.EventMode.Unregistered));
  end;
end;

end.
