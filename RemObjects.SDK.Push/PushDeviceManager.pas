namespace RemObjects.SDK.ApplePushProvider;

interface

uses
  System.Collections.Generic,
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
  PushDeviceInfo = public abstract class
  public
    property &Type: String read; abstract;
    property ID: String read; abstract;
    property UserReference: String;
    property ClientInfo: String;
    property ServerInfo: String;
    property LastSeen: DateTime;
  end;

  ApplePushDeviceInfo = public class(PushDeviceInfo)
  public
    property &Type: String read 'APS'; override;
    property ID: String read PushDeviceManager.BinaryToString(Token); override;
    property Token: Binary;
    property SubType: String;
  end;

  AndroidPushDeviceInfo = public class(PushDeviceInfo)
  public
    property &Type: String read 'GCM'; override;
    property ID: String read RegistrationID; override;
    property RegistrationID: String;
  end;

  WindowsPushDeviceInfo = public class(PushDeviceInfo)
  public
    property &Type: String read 'WNS'; override;
    property ID: String read URI.ToString(); override;
    property URI: Uri;
  end;

  WindowsPhonePushDeviceInfo = public class(WindowsPushDeviceInfo)
  public
    property &Type: String read 'MPNS'; override;
    property ID: String read DeviceID; override;
    property DeviceID: String;
    property OSVersion: String;
  end;

  PushDeviceManager = public class
  private
    fDevices: Dictionary<String, PushDeviceInfo>;
    fFilename: String;
    class var fInstance: PushDeviceManager;
    
    method set_Filename(value: String);
    class method get_Instance: PushDeviceManager;
    method Load;
    method Save;
  assembly
  public
    constructor; empty;
    constructor (aDeviceStoreFile: String);

    class property Instance: PushDeviceManager read get_Instance;

    property Devices: Dictionary<String, PushDeviceInfo> read fDevices;

    // Filename for Device Store XML
    property DeviceStoreFile: String read fFilename write set_Filename;

    // Toggles whether Users need to Log in before registering devices
    property RequireSession: Boolean;

    {method PushMessageNotificationToAllDevices(aMessage: String);
    method PushBadgeNotificationToAllDevices(aBadge: Int32);
    method PushAudioNotificationToAllDevices(aSound: String);
    method PushCombinedNotificationToAllDevices(aMessage: String; aBadge: nullable Int32; aSound: String);}

    class method StringToBinary(aString: String): Binary;
    class method BinaryToString(aBinary: Binary): String;

    method Flush;

    event DeviceRegistered: DeviceEvent assembly raise;
    event DeviceUnregistered: DeviceEvent assembly raise;
  end;

  DeviceEvent = public delegate(sender: Object; ea: DeviceEventArgs);

  DeviceEventArgs = public class(EventArgs)
  public
    property DeviceToken: String;
  end;  

implementation

constructor PushDeviceManager(aDeviceStoreFile: String);
begin
  DeviceStoreFile := aDeviceStoreFile;
end;

method PushDeviceManager.set_Filename(value: String);
begin
  if fFilename <> value then begin
    fFilename := value;
    Load();
  end;
end;

{method PushDeviceManager.set_CertificateFile(value: String);
begin
//  fAPSConnect := new APSConnect(lCertificate);
end;}

method PushDeviceManager.Flush;
begin
  Save;
end;

class method PushDeviceManager.BinaryToString(aBinary: Binary):String;
begin
  var sb := new StringBuilder;
  for i: Int32 := 0 to 31 do begin
    sb.Append(String.Format('{0:x2}',aBinary.ToArray[i]));
    //if i < 31 then sb.Append('-');
  end;
  result := sb.ToString;
end;

class method PushDeviceManager.StringToBinary(aString: String):Binary;
begin
  var aArray := new Byte[32];
  for i: Int32 := 0 to 31 do begin
    var s := aString.Substring(i*2, 2);
    aArray[i] := Int32.Parse(s, NumberStyles.HexNumber);
  end;
  result := new Binary(aArray);
end;

method PushDeviceManager.Save;
begin
  var x := new XDocument;
  var lRoot := new XElement('Devices');
  for each k in fDevices.Keys do begin
    
    var lDeviceNode := new XElement('Device');
    var lInfo := fDevices[k]; 

    lDeviceNode.Add(new XAttribute('Type', lInfo.Type));
    case lInfo type of
      ApplePushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('Token', BinaryToString(ApplePushDeviceInfo(lInfo).Token)));
          lDeviceNode.Add(new XAttribute('SubType', ApplePushDeviceInfo(lInfo).SubType));
        end;
      AndroidPushDeviceInfo: begin
          lDeviceNode.Add(new XAttribute('RegistrationID', AndroidPushDeviceInfo(lInfo).RegistrationID));
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

method PushDeviceManager.Load;
begin
  fDevices := new Dictionary<String,PushDeviceInfo>;

  if assigned(DeviceStoreFile) and File.Exists(DeviceStoreFile) then begin

    var x := XDocument.Load(DeviceStoreFile);
    for each matching lDeviceNode: XElement in x.Root.Elements do begin

      var lInfo: PushDeviceInfo;

      var lType := lDeviceNode.Attribute('Type'):Value;
      case lType of
        nil, 
        'APS': lInfo := new ApplePushDeviceInfo();
        'GCM': lInfo := new AndroidPushDeviceInfo();
        'WNS': lInfo := new WindowsPushDeviceInfo();
        'MPNS': lInfo := new WindowsPhonePushDeviceInfo();
      end;

      case lInfo type of
        ApplePushDeviceInfo: begin
            var lToken := lDeviceNode.Attribute('Token').Value;
            ApplePushDeviceInfo(lInfo).Token := StringToBinary(lToken);
            ApplePushDeviceInfo(lInfo).SubType := coalesce(lDeviceNode.Attribute('SubType'):Value, 'iOS');
          end;
        AndroidPushDeviceInfo: begin
            AndroidPushDeviceInfo(lInfo).RegistrationID := lDeviceNode.Attribute('RegistrationID').Value;
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

class method PushDeviceManager.get_Instance: PushDeviceManager;
begin
  if not assigned(fInstance) then fInstance := new PushDeviceManager;
  result := fInstance;
end;


{method PushDeviceManager.PushMessageNotificationToAllDevices(aMessage: String);
begin
  for each d in fDevices.Values do 
  //  fAPSConnect.PushMessageNotification(d.Token.ToArray, aMessage);
end;

method PushDeviceManager.PushBadgeNotificationToAllDevices(aBadge: Int32);
begin
  for each d in fDevices.Values do 
  //  fAPSConnect.PushBadgeNotification(d.Token.ToArray, aBadge);
end;

method PushDeviceManager.PushAudioNotificationToAllDevices(aSound: String);
begin
  for each d in fDevices.Values do 
 //   fAPSConnect.PushAudioNotification(d.Token.ToArray, aSound);
end;

method PushDeviceManager.PushCombinedNotificationToAllDevices(aMessage: String; aBadge: nullable Int32; aSound: String);
begin
  for each d in fDevices.Values do 
 //   fAPSConnect.PushCombinedNotification(d.Token.ToArray, aMessage, aBadge, aSound);
end;}

end.
