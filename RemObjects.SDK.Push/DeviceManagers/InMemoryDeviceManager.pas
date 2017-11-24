namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
 InMemoryDeviceManager = public class (IDeviceManager)
  protected
    fDevices: Dictionary<String, PushDeviceInfo> := new Dictionary<String, PushDeviceInfo>();
  public
    property Devices: sequence of PushDeviceInfo read fDevices.Values;

    method AddDevice(anId: String; aDevice: PushDeviceInfo); virtual;
    method RemoveDevice(anId: String): Boolean; virtual;
    method TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
    method HasDevice(anId: String): Boolean;
    method Save; empty; virtual;
    method Load; empty; virtual;
  end;


implementation

method InMemoryDeviceManager.AddDevice(anId: String; aDevice: PushDeviceInfo);
begin
  writeLn("inseriting key '"+anId+"'");
  fDevices.Add(anId, aDevice);
end;

method InMemoryDeviceManager.RemoveDevice(anId: String): Boolean;
begin
  result := fDevices.Remove(anId);
end;

method InMemoryDeviceManager.TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
begin
  result := fDevices.TryGetValue(anId, out aDevice);
end;

method InMemoryDeviceManager.HasDevice(anId: String): Boolean;
begin
  result := fDevices.ContainsKey(anId);
end;

end.