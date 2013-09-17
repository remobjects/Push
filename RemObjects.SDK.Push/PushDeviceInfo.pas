namespace RemObjects.SDK.Push;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

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
    property ID: String read RemObjects.SDK.Push.APS.APSConnect.ByteArrayToString(Token); override;
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
    property ID: String read NotificationURI.ToString(); override;
    property NotificationURI: Uri;
  end;

  WindowsPhonePushDeviceInfo = public class(WindowsPushDeviceInfo)
  public
    property &Type: String read 'MPNS'; override;
    property ID: String read DeviceID; override;
    property DeviceID: String;
    property OSVersion: String;
  end;

implementation

end.
