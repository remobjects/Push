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
    method BinaryToString(aBinary: Binary): String;
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
  self.RequireSession := PushManager.RequireSession;
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

method ApplePushProviderService.BinaryToString(aBinary: Binary):String;
begin
  result := APSConnect.ByteArrayToString(aBinary.ToArray());
end;

method ApplePushProviderService.registerDevice(deviceToken: RemObjects.SDK.Types.Binary; additionalInfo: System.String);
begin
  try
    var lStringToken := BinaryToString(deviceToken);
    Log('Push registration for '+ lStringToken);
    var lDevice: PushDeviceInfo;
    if PushManager.DeviceManager.TryGetDevice(lStringToken, out lDevice) then begin
      Log('Push registration updated for '+lStringToken);

      PushManager.UpdateDevice(lDevice, additionalInfo);
      PushManager.Save;
    end
    else begin
      Log('Push registration new for '+ lStringToken);
      lDevice := new ApplePushDeviceInfo(Token := deviceToken.ToArray(), 
                                       SubType := 'iOS',
                                       UserReference := iif(HasSession, Session['UserID']:ToString, nil),
                                       ClientInfo := additionalInfo, 
                                       ServerInfo := nil,
                                       LastSeen := DateTime.Now);

      PushManager.AddDevice(lDevice);
      PushManager.Save;
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
  var lStringToken := BinaryToString(deviceToken);
  if (PushManager.RemoveDevice(lStringToken)) then
    PushManager.Save;
end;

end.
