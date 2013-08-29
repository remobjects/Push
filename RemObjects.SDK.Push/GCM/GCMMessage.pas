namespace RemObjects.SDK.Push.GCM;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  GCMMessage = public class
  public   
    const DEFAULT_TIME_TO_LIVE: Integer = 3600 * 24 * 4; //4 weeks, in seconds
  public
    property RegistrationIds: List<String> := new List<String>;
    property CollapseKey: String read write;
    property Data: Dictionary<String, String> := new Dictionary<String,String>();
    property DelayWhileIdle: Boolean := false;
    property TimeToLeave: Integer := DEFAULT_TIME_TO_LIVE;
    property RestrictedPackageName: String;
    property DryRun: Boolean := false;
  end;

implementation

end.
