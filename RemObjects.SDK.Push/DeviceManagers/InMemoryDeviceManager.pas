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
    method Save; empty; virtual;
    method Load; empty; virtual;
  end;


implementation

method InMemoryDeviceManager.AddDevice(anId: String; aDevice: PushDeviceInfo);
begin
  fDevices.Add(anId, aDevice);
end;

method InMemoryDeviceManager.RemoveDevice(anId: String): Boolean;
begin
  exit (fDevices.Remove(anId));
end;

method InMemoryDeviceManager.TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
begin
  exit  (fDevices.TryGetValue(anId, out aDevice));
end;

end.
