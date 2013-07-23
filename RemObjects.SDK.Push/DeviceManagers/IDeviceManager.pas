namespace RemObjects.SDK.Push;

interface

type
  IDeviceManager = public interface
    method AddDevice(anId: String; aDevice: PushDeviceInfo);
    method RemoveDevice(anId: String): Boolean;
    method TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
    property Devices: sequence of PushDeviceInfo read;

    method Load();
    method Save();
  end;
  
implementation

end.
