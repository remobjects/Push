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
    method AddDevice(aDevice: PushDeviceInfo);
    method RemoveDevice(anId: String): Boolean;
    method UpdateDevice(aDevice: PushDeviceInfo; anAdditionalClientInfo: String);
  public
    property DeviceManager: IDeviceManager read fDeviceManager write Set_DeviceManager;
    property PushConnect: GenericPushConnect read GenericPushConnect.Instance;

    // Toggles whether Users need to Log in before registering devices
    property RequireSession: Boolean;

    method Save;

    event DeviceRegistered: DeviceEvent assembly raise;
    event DeviceUnregistered: DeviceEvent assembly raise;

    method PushMessage(aMessage: String; aBadge: nullable Int32 := nil; aSound: String := nil);
    method PushBadge(aBadge: nullable Int32);
    method PushSound(aSound: String);

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
begin
  fDeviceManager.Save();
end;

method PushManager.Set_DeviceManager(aDeviceManager: IDeviceManager);
require
  assigned(aDeviceManager);
begin
  if (fDeviceManager ≠ aDeviceManager) then begin
    if assigned(fDeviceManager) then Save();
    fDeviceManager := aDeviceManager;
  end;
end;

class method PushManager.AddDevice(aDevice: PushDeviceInfo);
begin
  DeviceManager.AddDevice(aDevice.ID, aDevice);
  DeviceRegistered(DeviceManager, new DeviceEventArgs(DeviceToken := aDevice.ID, Mode := DeviceEventArgs.EventMode.Registered));
end;

class method PushManager.RemoveDevice(anId: String): Boolean;
begin
  result := DeviceManager.RemoveDevice(anId);
  if (result) then
    DeviceUnregistered(DeviceManager, new DeviceEventArgs(DeviceToken := anId, Mode := DeviceEventArgs.EventMode.Unregistered));
end;

class method PushManager.UpdateDevice(aDevice: PushDeviceInfo; anAdditionalClientInfo: String);
begin
  aDevice.ClientInfo := anAdditionalClientInfo;
  aDevice.LastSeen := DateTime.Now;
  DeviceRegistered(DeviceManager, new DeviceEventArgs(DeviceToken := aDevice.ID, Mode := DeviceEventArgs.EventMode.EntryUpdated));
end;

class method PushManager.PushMessage(aMessage: String; aBadge: nullable Int32; aSound: String);
begin
  for each device in fDeviceManager.Devices do
    PushConnect.PushMessage(device, aMessage, aBadge, aSound);
end;

class method PushManager.PushBadge(aBadge: nullable Int32);
begin
  for each device in fDeviceManager.Devices do
    PushConnect.PushBadge(device, aBadge);
end;

class method PushManager.PushSound(aSound: String);
begin
  for each device in fDeviceManager.Devices do
    PushConnect.PushSound(device, aSound);
end;



end.
