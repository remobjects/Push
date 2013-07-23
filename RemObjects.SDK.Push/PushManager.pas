namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.Collections.ObjectModel,
  System.Globalization,
  System.IO,
  System.Linq,
  System.Linq.Expressions,
  System.Security.Cryptography.X509Certificates,
  System.Text, 
  System.Xml,
  System.Xml.Linq,
  System.Xml.Serialization,
  RemObjects.SDK.Types;

type
  
  PushManager = public static class
  private
    fDeviceManager: IDeviceManager;
    method Set_DeviceManager(aDeviceManager: IDeviceManager);
  assembly
  public
    property DeviceManager: IDeviceManager read fDeviceManager write Set_DeviceManager;
    property PushConnect: GenericPushConnect read GenericPushConnect.Instance;

    // Toggles whether Users need to Log in before registering devices
    property RequireSession: Boolean;

    method Save;

    event DeviceRegistered: DeviceEvent assembly raise;
    event DeviceUnregistered: DeviceEvent assembly raise;
  end;

  DeviceEvent = public delegate(sender: Object; ea: DeviceEventArgs);

  DeviceEventArgs = public class(EventArgs)
  public
    property DeviceToken: String;
    property Mode: EventMode;
  end;

  EventMode nested in DeviceEventArgs = public enum (Registered, Unregistered, EntryUpdated);

implementation

method PushManager.Save;
require
  assigned(fDeviceManager);
begin
  fDeviceManager.Save();
end;

method PushManager.Set_DeviceManager(aDeviceManager: IDeviceManager);
require
  assigned(aDeviceManager);
begin
  if (fDeviceManager ≠ aDeviceManager) then begin
    Save();
    fDeviceManager := aDeviceManager;
  end;
end;

end.
