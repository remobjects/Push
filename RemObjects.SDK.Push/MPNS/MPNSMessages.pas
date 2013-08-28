namespace RemObjects.SDK.Push.MPNS;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text,
  System.Xml.Linq;

type
  MPNSMessageType = public enum (Tile = 1, Toast = 2, Raw = 3);
  MPNSMessageInterval = public enum (Immediate = 0, Within450Sec = 1, Within900Sec = 2);
  MPNSDeviceVersion = public enum (Seven, Mango, Eight);

  MPNSMessage = public abstract class
  protected
    method XmlEscape(aText: String): String;
  public    
    method ToXmlString(): String; abstract;

    /// <summary>
    /// notification message ID associated with the response
    /// </summary>
    property MessageId: Guid := Guid.NewGuid();
    /// <summary>
    /// Batching interval that indicates when the push notification will be sent to the app from the push notification service.
    /// If this header is not present, the message will be delivered by the push notification service immediately. 
    ///</summary>
    /// <value>X2 - Toast(02, 12, 22),X1 - Tile(01, 11, 21),X3 - Raw(03, 13, 23)
    /// 0X - Immeadiate, 1X - within 450 sec, 2X -within 900 sec 
    ///</value>
    property SendInterval: nullable MPNSMessageInterval;

    /// <summary>
    /// type of push notification being sent.
    /// </summary>
    /// <value>Possible options are Tile, toast, and raw. Raw by default.</value>
    property NotificationType: nullable MPNSMessageType read protected write;

    property NotificationURI: String;
  end;

  MPNSRawMessage = public class(MPNSMessage)
  public
    method ToXmlString: String; override;
    property RawData: String;
    constructor;
  end;

  MPNSDataMessage = public class(MPNSRawMessage)
  private
    fData: Dictionary<String, Object> := new Dictionary<String,Object>();
  public
    method ToXmlString: String; override;
    property Data: Dictionary<String, Object> read fData;
  end;

implementation

method MPNSMessage.XmlEscape(aText: String): String;
begin
  if (assigned(aText)) then
    exit (System.Security.SecurityElement.Escape(aText))
  else
    exit String.Empty;
end;

constructor MPNSRawMessage;
begin
  self.NotificationType := MPNSMessageType.Raw;
end;

method MPNSRawMessage.ToXmlString: String;
begin
  exit iif(assigned(RawData), RawData, String.Empty);
end;

method MPNSDataMessage.ToXmlString: String;
begin
  var lDoc := new XElement("root", 
      from item in self.Data select new XElement('item', 
                                        new XText(XmlEscape(item.Value:ToString)),
                                        new XAttribute("key", XmlEscape(item.Key))));

  exit (lDoc.ToString());
end;

end.
