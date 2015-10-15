namespace RemObjects.SDK.Push;

interface

uses
  System.IO;

type
  PushLog = public class
  private
    class var
      fCount: Int32 := 0;
      fFilename: String;
    class const MAX_LOGFILE_SIZE = 1*1024*1024; { 1MB }
  protected
    class constructor;
    class property Enabled: Boolean;
  public
    class method Log(aMessage: String); locked;
    class operator Explicit(aString: String): PushLog;
  end;
  
implementation

class constructor PushLog;
begin
  fFilename := Path.ChangeExtension(typeOf(self).Assembly.Location, '.'+System.Environment.MachineName+'.log')
end;

class method PushLog.Log(aMessage: String);
begin
  if not Enabled then exit;

  inc(fCount);
  if (fCount > 100) and (new FileInfo(fFilename).Length > MAX_LOGFILE_SIZE) then begin
    var lTemp := Path.ChangeExtension(fFilename, '.previous.log');
    if File.Exists(lTemp) then File.Delete(lTemp);
    File.Move(fFilename, lTemp);
    fCount := 0;
  end;

  File.AppendAllText(fFilename, DateTime.Now.ToString('yyyy-MM-dd HH:mm:ss')+' '+aMessage+#13#10);
  Console.WriteLine(aMessage);
end;

class operator PushLog.Explicit(aString: String): PushLog;
begin
  Log(aString);
end;

end.