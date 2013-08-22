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
    property ID: String read APSConnect.ByteArrayToString(Token); override;
    property Token: array of Byte;
    property SubType: String;
  end;

  GooglePushDeviceInfo = public class(PushDeviceInfo)
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
begin
  if assigned(fDeviceManager) and (fDeviceManager is IDeviceStorage) then
    IDeviceStorage(fDeviceManager).Save();
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

end.
