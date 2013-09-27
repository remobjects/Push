namespace RemObjects.SDK.Push.APS;

interface

uses
  System,
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  APSMessage = public class
  public
    property Identifier: Integer;
    property DeviceToken: String;
    property Expiration: DateTime;

    property Payload: Payload;

    constructor; empty;
    constructor(aToken: String; aPayload: Payload := nil); empty;

  end;

  Payload nested in APSMessage = public class
  public
    property AlertSimple: String;
    property Alert: Alert;
    property Badge: nullable Integer;
    property Sound: String;
    property ContentAvailable: Boolean;
    property Data: Dictionary<String, String>;
    property HideActionButton: Boolean;  
  end;

  Alert nested in APSMessage = public class
  public
    property Body: String;
    property ActionLocKey: String := nil;
    property MessageLocKey: String;
    property MessageLocArgs: array of String;
    property LaunchImage: String;
  end;

implementation

end.
