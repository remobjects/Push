namespace RemObjects.SDK.Push.GCM;

interface

uses
  System.Collections.Generic,
  System.Linq,
  System.Text;

type
  GCMResponse = public class
  protected
    fMessage: GCMMessage;
  assembly
    property MulticastId: Integer := 0;
  public
    property Message: GCMMessage read fMessage;
    property SuccessesCount: Integer := 0;
    property FailuresCount: Integer := 0;
    property CanonicalIdCount: Integer := 0;
    property Results: List<GCMMessageResult> := new List<GCMMessageResult>();    
    property Status: GCMResponse.ResponseStatus;
    constructor(aMessage: GCMMessage);
  end;

  GCMMessageResult = public class
    assembly MessageId: String;
    property RegisteredId: String; // get it from request
    property NewRegistrationId: String;
    property Status: ResultStatus := ResultStatus.Ok;


  end;

  ResultStatus nested in GCMMessageResult = public enum (
    Undefined,
    Ok,
    NewRegistrationId, // new canonical registration Id was provided - update your db record
    Unavailable, // GCM were busy/internal timeout, retry is honoured (Retry-After header)
    NotRegistered, // remove regId from DB
    MissingRegistration, // regId is not present in request
    InvalidRegistration, // regId is invalid/malformed
    MismatchSenderId, // app with this regID is supposed to get pushes from other SenderID.
    MessageTooBig, // payload is more then 4kb
    InvalidDataKey, // invalid key payload data
    InvalidTtl, // ttl should be in 0..2,419,200(4 weeks)
    InternalServerError, // (Status=500) - retry honoured
    InvalidPackageName  // package name of regId app doesn't match restricted_package_name from the request
  );

  ResponseStatus nested in GCMResponse = public enum (OK, MalformedJson, AuthenticationFailed, CanonicalId, ProcessingErrors, ServerInternalError);


implementation


constructor GCMResponse(aMessage: GCMMessage);
begin
  fMessage := aMessage;
end;

end.
