namespace RemObjects.SDK.Push;

interface

uses
  System.IO,
  System.Net,
  System.Net.Security,
  System.Runtime.Remoting.Messaging,
  System.Security.Cryptography,
  System.Security.Cryptography.X509Certificates,
  System.Security.Permissions,
  System.Text,
  RemObjects.SDK,
  RemObjects.SDK.Types;

type
  APSConnect = public class(IDisposable)
  private
    {$IFDEF MONO}
    fSslStream: Mono.Security.Protocol.Tls.SslClientStream;
    {$ELSE}
    fSslStream: SslStream;
    {$ENDIF}
    fTcpClient: System.Net.Sockets.TcpClient;
    fMacCertificate, fiOSCertificate: X509Certificate2;
    method CreateStream;
    method FindCertificate(aName: String): X509Certificate2;
    method Log(aMessage: String);
    method set_MacCertificateFile(value: String);
    method set_iOSCertificateFile(value: String);
  protected
  public
    method Dispose;

    // Filename for Certificate .p12
    property MacCertificateFile: String write set_MacCertificateFile;
    property iOSCertificateFile: String write set_iOSCertificateFile;

    method PushRawNotification(aDeviceToken: Binary; Json: String); // async;
    method PushMessageNotification(aDeviceToken: Binary; aMessage: String);
    method PushBadgeNotification(aDeviceToken: Binary; aBadge: Int32);
    method PushAudioNotification(aDeviceToken: Binary; aSound: String);
    method PushCombinedNotification(aDeviceToken: Binary; aMessage: String; aBadge: nullable Int32; aSound: String);

    method GetFeedback;

    property ApsHost: String := 'gateway.push.apple.com';
    property ApsPort: Int32 := 2195;

    property ApsFeedbackHost: String := 'feedback.push.apple.com';
    property ApsFeedbackPort: Int32 := 2196;
    
    class method StringToBinary(aString: String): RemObjects.SDK.Types.Binary;
    class method BinaryToString(aBinary: RemObjects.SDK.Types.Binary): String;
  end;
  
implementation

method APSConnect.CreateStream;
require
  assigned(fiOSCertificate);
begin
  fTcpClient := new System.Net.Sockets.TcpClient(ApsHost, ApsPort);
{$IFDEF MONO}
  fSslStream := new Mono.Security.Protocol.Tls.SslClientStream(fTcpClient.GetStream(), ApsHost, fiOSCertificate); 
 // fSslStream.WriteTimeout := 120 000;
  fSslStream.PrivateKeyCertSelectionDelegate := method (certificate: X509Certificate; targetHost: String): AsymmetricAlgorithm; 
    begin
      result := X509Certificate2(certificate).PrivateKey;
    end;
  fSslStream.ClientCertSelectionDelegate := method (clientCertificates: X509CertificateCollection; 
    serverCertificate: X509Certificate; targetHost: String; 
    serverRequestedCertificates: X509CertificateCollection): X509Certificate; 
    begin
      result := fiOSCertificate;  
    end;
  fSslStream.ServerCertValidationDelegate := method (certificate: X509Certificate; certificateErrors: array of Int32): Boolean; 
    begin
      result := true;
    end;
{$ELSE}
  fSslStream := new SslStream(fTcpClient.GetStream(), true, 
    method(sender: Object; certificate: X509Certificate; chain: X509Chain; sslPolicyErrors: SslPolicyErrors): Boolean 
    begin
      result := true; // todo: check for server cert errors here..
    end,
    method(sender: Object; targetHost: String; localCertificates: X509CertificateCollection; remoteCertificate: X509Certificate; acceptableIssuers: Array of String): X509Certificate 
    begin
      result := fCertificate;
    end);
  fSslStream.AuthenticateAsClient(ApsHost);
{$ENDIF}
end;

method APSConnect.FindCertificate(aName: String): X509Certificate2;
begin
  // We assume the certificate was exported from the Mac keychain as .p12 and 
  // imported into "Personal" user store by double-clicking the file in Windows.
  var store := new X509Store(StoreLocation.LocalMachine);//CurrentUser); 
  store.Open(OpenFlags.OpenExistingOnly or OpenFlags.ReadOnly);
  for each c: X509Certificate2 in store.Certificates do
    if c.SubjectName.Name.Contains(aName) then exit c;
end;

method APSConnect.PushRawNotification(aDeviceToken: Binary; Json: String);
require
  aDeviceToken.Length = 32;
  assigned(fiOSCertificate);
  assigned(ApsHost);
  ApsPort > 0;
begin 
  Log('3a');
  Log(Json);
  locking self do begin
    Log('3b');
    for i: Int32 := 0 to 3 do try

      using m := new MemoryStream() do begin
        using w := new BinaryWriter(m) do begin
          w.Write([0,0,32]);
          w.Write(aDeviceToken.ToArray());
          var data := Encoding.UTF8.GetBytes(Json);
          w.Write([Byte(data.Length and $ff00 div $100), Byte(data.Length and $ff)]);
          w.Write(data);
          w.Flush;
      
          //todo: this is temp; we need to cache the connection but also proeprly recover from loss
          Log('4a');
          CreateStream;
          Log('4b');
          try
            fSslStream.Write(m.ToArray);
            Log('4c');
            fSslStream.Flush;
            Log('4d');
          finally
            Log('4e');
            fSslStream.Dispose();
            Log('4f');
            fTcpClient.Close();
            Log('4g');
            fSslStream := nil;
            fTcpClient := nil;
          end;
          //Debug: StreamHelpers.SaveStreamToFile(m, 'w:\test.data');
        end;
      end;
      
      break; // break the for loop - unless there was an expcetion, thne we'll retry 3 times.

    except
      on E: IOException do begin
         Log('Failed on Push, try '+i.ToString+': '+E.Message);
      end;
    end;

    Log('3c');
  end;
  Log('3d');
end;

method APSConnect.PushMessageNotification(aDeviceToken: Binary; aMessage: String);
begin
  //todo: escape illegal JSON chars in message
  var lJson := String.Format('{{"aps":{{"alert":{0}}}}}',  JsonTokenizer.EncodeString(aMessage));
  PushRawNotification(aDeviceToken, lJson);
end;

method APSConnect.PushBadgeNotification(aDeviceToken: Binary; aBadge: Int32);
begin
  var lJson := String.Format('{{"aps":{{"badge":{0}}}}}', aBadge);
  PushRawNotification(aDeviceToken, lJson);
end;

method APSConnect.PushAudioNotification(aDeviceToken: Binary; aSound: String);
begin
  var lJson := String.Format('{{"aps":{{"sound":{0}}}}}',  JsonTokenizer.EncodeString(aSound));
  PushRawNotification(aDeviceToken, lJson);
end;

method APSConnect.PushCombinedNotification(aDeviceToken: Binary; aMessage: String; aBadge: nullable Int32; aSound: String);
begin
  Log('2a');
  var lData := '';
  if assigned(aMessage) then begin
    lData := lData+String.Format('"alert":{0}', JsonTokenizer.EncodeString(aMessage));
  end;
  if assigned(aBadge) then begin
   if length(lData) > 0 then lData := lData+',';
    lData := lData+String.Format('"badge":{0}', aBadge);
  end;
  if assigned(aSound) then begin
    if length(lData) > 0 then lData := lData+',';
    lData := lData+String.Format('"sound":{0}',  JsonTokenizer.EncodeString(aSound));
  end;

  Log('2b');
  var lJson := String.Format('{{"aps":{{{0}}}}}', lData);
  Log('2c');
  PushRawNotification(aDeviceToken, lJson);
  Log('2d');
end;

method APSConnect.Dispose;
begin
  fSslStream.Dispose;
  fTcpClient.Close;
end;

method APSConnect.GetFeedback;
require
  assigned(fiOSCertificate);
begin
  var lTcpClient := new System.Net.Sockets.TcpClient(ApsFeedbackHost, ApsFeedbackPort);
  using lSslStream := new Mono.Security.Protocol.Tls.SslClientStream(lTcpClient.GetStream(), ApsHost, fiOSCertificate) do begin
    
    lSslStream.PrivateKeyCertSelectionDelegate := method (certificate: X509Certificate; targetHost: String): AsymmetricAlgorithm; 
      begin
        result := X509Certificate2(certificate).PrivateKey;
      end;
    lSslStream.ClientCertSelectionDelegate := method (clientCertificates: X509CertificateCollection; 
      serverCertificate: X509Certificate; targetHost: String; 
      serverRequestedCertificates: X509CertificateCollection): X509Certificate; 
      begin
        result := fiOSCertificate;  
      end;
    lSslStream.ServerCertValidationDelegate := method (certificate: X509Certificate; certificateErrors: array of Int32): Boolean; 
      begin
        result := true;
      end;

    var lBuffer := new Byte[4+4+32];
    while lSslStream.Read(lBuffer) <> 0 do begin
      Console.WriteLine(lBuffer.Length);
    end;

  end;
  lTcpClient.Close();
end;

method APSConnect.Log(aMessage: String);
begin
  File.AppendAllText(Path.ChangeExtension(typeOf(self).Assembly.Location, '.log'), DateTime.Now.ToString('yyyy-MM-dd HH:mm:ss')+' '+aMessage+#13#10);
end;

method APSConnect.set_MacCertificateFile(value: String);
begin
  var lData := Mono.Security.X509.PKCS12.LoadFromFile(value, nil);
  fMacCertificate := new X509Certificate2(lData.Certificates[0].RawData);
  fMacCertificate.PrivateKey := System.Security.Cryptography.AsymmetricAlgorithm(lData.Keys[0]);
end;

method APSConnect.set_iOSCertificateFile(value: String);
begin
  var lData := Mono.Security.X509.PKCS12.LoadFromFile(value, nil);
  fiOSCertificate := new X509Certificate2(lData.Certificates[0].RawData);
  fiOSCertificate.PrivateKey := System.Security.Cryptography.AsymmetricAlgorithm(lData.Keys[0]);
end;

class method APSConnect.BinaryToString(aBinary: Binary):String;
begin
  var sb := new StringBuilder;
  for i: Int32 := 0 to 31 do begin
    sb.Append(String.Format('{0:x2}',aBinary.ToArray[i]));
    //if i < 31 then sb.Append('-');
  end;
  result := sb.ToString;
end;

class method APSConnect.StringToBinary(aString: String):Binary;
begin
  var aArray := new Byte[32];
  for i: Int32 := 0 to 31 do begin
    var s := aString.Substring(i*2, 2);
    aArray[i] := Int32.Parse(s, System.Globalization.NumberStyles.HexNumber);
  end;
  result := new Binary(aArray);
end;

end.