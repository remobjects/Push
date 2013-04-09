namespace RemObjects.SDK.ApplePushProvider;

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
    method registerDevice(deviceToken: RemObjects.SDK.Types.Binary; additionalInfo: System.String); locked on typeOf(PushDeviceManager);
    method unregisterDevice(deviceToken: RemObjects.SDK.Types.Binary); locked on typeOf(PushDeviceManager);
  end;

implementation

constructor ApplePushProviderService;
begin
  inherited constructor();
  self.InitializeComponent();
  self.RequireSession := PushDeviceManager.RequireSession;
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
begin
  try
    var lStringToken := PushDeviceManager.BinaryToString(deviceToken);
    Log('Push registration for '+lStringToken);
    if PushDeviceManager.Devices.ContainsKey(lStringToken) then begin
      Log('Push registration updated for '+lStringToken);

      var p := PushDeviceManager.Devices[lStringToken];
      p.ClientInfo := additionalInfo;
      p.LastSeen := DateTime.Now;
      PushDeviceManager.Flush;
      PushDeviceManager.DeviceRegistered(nil, new DeviceEventArgs(DeviceToken := lStringToken));
    end
    else begin
      Log('Push registration new for '+lStringToken);
      var p := new ApplePushDeviceInfo(Token := deviceToken, 
                                       SubType := 'iOS',
                                       UserReference := iif(HasSession, Session['UserID']:ToString, nil),
                                       ClientInfo := additionalInfo, 
                                       ServerInfo := nil,
                                       LastSeen := DateTime.Now);
      PushDeviceManager.Devices.Add(lStringToken, p);
      PushDeviceManager.Flush;
    end;
  except
    on E:Exception do begin
      Log(E.Message);
      Log(E.StackTrace);
    end;
  end;
end;

method ApplePushProviderService.unregisterDevice(deviceToken: RemObjects.SDK.Types.Binary);
begin
  var lStringToken := PushDeviceManager.BinaryToString(deviceToken);
  PushDeviceManager.Devices.Remove(lStringToken);
  PushDeviceManager.Flush;
  PushDeviceManager.DeviceUnregistered(nil, new DeviceEventArgs(DeviceToken := lStringToken));
end;

end.
