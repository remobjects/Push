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
  IDeviceManager = public interface
    method AddDevice(anId: String; aDevice: PushDeviceInfo);
    method RemoveDevice(anId: String): Boolean;
    method TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
    property Devices: sequence of PushDeviceInfo read;
  end;

  IDeviceStorage = public interface
    method Load();
    method Save();
  end;

  InMemoryDeviceManager = public class (IDeviceManager)
  protected
    fDevices: Dictionary<String, PushDeviceInfo> := new Dictionary<String, PushDeviceInfo>();
  public
    property Devices: sequence of PushDeviceInfo read fDevices.Values;

    method AddDevice(anId: String; aDevice: PushDeviceInfo); virtual;
    method RemoveDevice(anId: String): Boolean; virtual;
    method TryGetDevice(anId: String; out aDevice: PushDeviceInfo): Boolean;
  end;

  FileDeviceManager = public class (InMemoryDeviceManager, IDeviceManager, IDeviceStorage)
  private
    fDevices: Dictionary<String, PushDeviceInfo> := new Dictionary<String, PushDeviceInfo>();
    fFilename: String; 
    method set_Filename(value: String);
  public
    // Filename for Device Store XML
    property DeviceStoreFile: String read fFilename write set_Filename;
    property AutoSave: Boolean := true;

    method Load;
    method Save;
    method AddDevice(anId: String; aDevice: PushDeviceInfo); override;
    method RemoveDevice(anId: String): Boolean; override;
    constructor; empty;
    constructor(aFileName: String);
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

method FileDeviceManager.Save;
begin
  var x := new XDocument;
  var lRoot := new XElement('Devices');
  for each k in fDevices.Keys do begin
    
    var lDeviceNode := new XElement('Device');
    var lInfo := fDevices[k]; 

    lDeviceNode.Add(new XAttribute('Type', lInfo.Type));
    case lInfo type of
      ApplePushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('Token', APSConnect.BinaryToString(ApplePushDeviceInfo(lInfo).Token)));
          lDeviceNode.Add(new XAttribute('SubType', ApplePushDeviceInfo(lInfo).SubType));
        end;
      GooglePushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('RegistrationID', GooglePushDeviceInfo(lInfo).RegistrationID));
        end;
      WindowsPhonePushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('URI', WindowsPushDeviceInfo(lInfo).URI.ToString()));
          lDeviceNode.Add(new XAttribute('OSVersion', WindowsPhonePushDeviceInfo(lInfo).OSVersion));
          lDeviceNode.Add(new XAttribute('DeviceID', WindowsPhonePushDeviceInfo(lInfo).DeviceID));
        end;
      WindowsPushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('URI', WindowsPushDeviceInfo(lInfo).URI.ToString()));
        end;
    end;
    lDeviceNode.Add(new XElement('User',lInfo.UserReference));
    lDeviceNode.Add(new XElement('ClientInfo',lInfo.ClientInfo));
    lDeviceNode.Add(new XElement('ServerInfo',lInfo.ServerInfo));
    lDeviceNode.Add(new XElement('Date',lInfo.LastSeen.ToString('yyyy-MM-dd HH:mm:ss'))); 

    lRoot.Add(lDeviceNode);
  end;
  x.Add(lRoot);
  x.Save(DeviceStoreFile);
end;

method FileDeviceManager.Load;
begin
  fDevices.Clear();

  if assigned(DeviceStoreFile) and File.Exists(DeviceStoreFile) then begin

    var x := XDocument.Load(DeviceStoreFile);
    for each matching lDeviceNode: XElement in x.Root.Elements do begin

      var lInfo: PushDeviceInfo;

      var lType := lDeviceNode.Attribute('Type'):Value;
      case lType of
        nil, 
        'APS': lInfo := new ApplePushDeviceInfo();
        'GCM': lInfo := new GooglePushDeviceInfo();
        'WNS': lInfo := new WindowsPushDeviceInfo();
        'MPNS': lInfo := new WindowsPhonePushDeviceInfo();
      end;

      case lInfo type of
        ApplePushDeviceInfo: begin
            var lToken := lDeviceNode.Attribute('Token').Value;
            ApplePushDeviceInfo(lInfo).Token := APSConnect.StringToBinary(lToken);
            ApplePushDeviceInfo(lInfo).SubType := coalesce(lDeviceNode.Attribute('SubType'):Value, 'iOS');
          end;
        GooglePushDeviceInfo: begin
            GooglePushDeviceInfo(lInfo).RegistrationID := lDeviceNode.Attribute('RegistrationID').Value;
          end;
        WindowsPhonePushDeviceInfo: begin
            WindowsPushDeviceInfo(lInfo).URI := new Uri(lDeviceNode.Attribute('URL').Value);
            WindowsPhonePushDeviceInfo(lInfo).OSVersion := lDeviceNode.Attribute('OSVersion').Value;
            WindowsPhonePushDeviceInfo(lInfo).DeviceID := lDeviceNode.Attribute('DeviceID').Value;
          end;
        WindowsPushDeviceInfo: begin
            WindowsPushDeviceInfo(lInfo).URI := new Uri(lDeviceNode.Attribute('URL').Value);
          end;
      end;

      var lDate := DateTime.Now;
      DateTime.TryParse(lDeviceNode.Element('Date'):Value, CultureInfo.InvariantCulture, DateTimeStyles.None, out lDate);

      lInfo.UserReference := lDeviceNode.Element('User').Value;
      lInfo.ClientInfo := lDeviceNode.Element('ClientInfo').Value;
      lInfo.ServerInfo := lDeviceNode.Element('ServerInfo').Value;
      lInfo.LastSeen := lDate;

      fDevices.Add(lInfo.ID, lInfo);
      //if assigned(fAPSConnect) then fAPSConnect.PushMessageNotification(lToken.ToArray, 'Welcome back. Server has been Started.');
    end;
  end;
end;


method FileDeviceManager.set_Filename(value: String);
begin
  if fFilename <> value then begin
    fFilename := value;
    Load();
  end;
end;

constructor FileDeviceManager(aFileName: String);
begin
  self.DeviceStoreFile := aFileName;
end;

method FileDeviceManager.AddDevice(anId: String; aDevice: PushDeviceInfo);
begin
  inherited.AddDevice(anId, aDevice);
  if (self.AutoSave) then
    Save();
end;

method FileDeviceManager.RemoveDevice(anId: String): Boolean;
begin
  result := inherited.RemoveDevice(anId);
  if (self.AutoSave and result) then
    Save();
end;

end.
