namespace RemObjects.SDK.Push.MPNS;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  MPNSResponse = public class
  protected
    fMessage: MPNSMessage;
  public
    property Message: MPNSMessage read fMessage;
    property MessageId: Guid read assembly or protected write;
    property NotificationStatus: MPNSResponse.NotificationStatus read assembly or protected write;
    property SubscriptionStatus: MPNSResponse.SubscriptionStatus read assembly or protected write;
    property DeviceConnectionStatus: MPNSResponse.DeviceConnectionStatus read assembly or protected write;
    property HttpStatus: System.Net.HttpStatusCode read assembly or protected write;
    constructor(aMessage: MPNSMessage);
  end;

  NotificationStatus nested in MPNSResponse = public enum(Undefined = 0, Received, Dropped, Suppressed, QueueFull);
  SubscriptionStatus nested in MPNSResponse = public enum(Undefined = 0, Active, Expired);
  DeviceConnectionStatus nested in MPNSResponse = public enum(Undefined = 0, Connected, TempDisconnected, Disconnected, InActive);

  MPNSServerException = public class(Exception)
  public
    property Response: MPNSResponse read assembly write;
  end;

implementation

constructor MPNSResponse(aMessage: MPNSMessage);
begin
  fMessage := aMessage;
end;

end.
