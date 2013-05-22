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
    property ID: String read APSConnect.BinaryToString(Token); override;
    property Token: Binary;
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

  PushManager = public class
  private
    fDeviceManager: IDeviceManager;
    class var fInstance: PushManager;
    class method get_Instance: PushManager;
    method Set_DeviceManager(aDeviceManager: IDeviceManager);
  assembly
  public
    constructor; empty;
    constructor (aDeviceManager: IDeviceManager);

    class property Instance: PushManager read get_Instance;

    property DeviceManager: IDeviceManager read fDeviceManager write Set_DeviceManager;

    // Toggles whether Users need to Log in before registering devices
    property RequireSession: Boolean;

    {method PushMessageNotificationToAllDevices(aMessage: String);
    method PushBadgeNotificationToAllDevices(aBadge: Int32);
    method PushAudioNotificationToAllDevices(aSound: String);
    method PushCombinedNotificationToAllDevices(aMessage: String; aBadge: nullable Int32; aSound: String);}


    method Flush;

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

constructor PushManager(aDeviceManager: IDeviceManager);
require
  assigned(aDeviceManager);
begin
  fDeviceManager := aDeviceManager;
end;

method PushManager.Flush;
require
  assigned(fDeviceManager);
begin
  if (fDeviceManager is RemObjects.SDK.Push.IDeviceStorage) then
    IDeviceStorage(fDeviceManager).Save();
end;


class method PushManager.get_Instance: PushManager;
begin
  if not assigned(fInstance) then fInstance := new PushManager;
  result := fInstance;
end;

method PushManager.Set_DeviceManager(aDeviceManager: IDeviceManager);
require
  assigned(aDeviceManager);
begin
  if (fDeviceManager <> aDeviceManager) then begin
    if (fDeviceManager <> nil) then
      Flush();
    fDeviceManager := aDeviceManager;
  end;
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
