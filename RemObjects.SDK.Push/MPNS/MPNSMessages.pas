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

    property OSVersion: nullable MPNSDeviceVersion;

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

  MPNSDataMessage = public sealed class(MPNSRawMessage)
  private
    fData: Dictionary<String, Object> := new Dictionary<String,Object>();
  public
    method ToXmlString: String; override;
    property Data: Dictionary<String, Object> read fData;
  end;

  MPNSToastMessage = public sealed class(MPNSMessage) 
  public
    method ToXmlString: String; override;
    constructor;

    property Text1: String;
    property Text2: String;
    property NavigatePath: String;
    property Parameters: Dictionary<String, String>:= new Dictionary<String,String>();
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

  exit ('<?xml version="1.0" encoding="utf-8"?>' + Environment.NewLine + lDoc.ToString());
end;

method MPNSToastMessage.ToXmlString: String;
begin
  var wp: XNamespace := 'WPNotification';
  var lPayload := new XElement(wp + 'Notification',
                                   new XAttribute(XNamespace.Xmlns + 'wp', 'WPNotification'));

  var lToast := new XElement(wp + 'Toast');

  if (not String.IsNullOrEmpty(Text1)) then
    lToast.Add(new XElement(wp + 'Text1', Text1));

  if not String.IsNullOrEmpty(Text2) then
    lToast.Add(new XElement(wp + 'Text2', Text2));


  if  (self.OSVersion > MPNSDeviceVersion.Seven)  then  begin
    if  (not String.IsNullOrEmpty(NavigatePath)) or (Parameters.Count > 0)  then  begin
      var lBuilder := new StringBuilder();

      if not String.IsNullOrEmpty(NavigatePath) then
        lBuilder.Append(XmlEscape('/' + NavigatePath.TrimStart('/')));

      if (Parameters.Count > 0) then begin
        lBuilder.Append('?');

        for each key: String in Parameters.Keys do
          lBuilder.Append(XmlEscape(key + '=' + Parameters[key].ToString()) + '&amp;')
      end;

      var lValue := lBuilder.ToString();

      if (not String.IsNullOrEmpty(lValue)) and (lValue.EndsWith('&amp;')) then
        lValue.Substring(0, lValue.Length - '&amp;'.Length);

      if not String.IsNullOrEmpty(lValue) then
        lToast.Add(new XElement(wp + 'Param', lValue))
    end
  end;

  lPayload.Add(lToast);
  exit ('<?xml version="1.0" encoding="utf-8"?>' + Environment.NewLine + lPayload.ToString);
end;

constructor MPNSToastMessage;
begin
  self.NotificationType := MPNSMessageType.Toast;
end;

end.
