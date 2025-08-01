//Description: TakePhotoFromCameraActionEx - fixes and enhancements to TTakePhotoCameraAction
//Source: https://github.com/Zoomicon/Zoomicon.Media.FMX.Delphi
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Media.FMX.TakePhotoFromCameraActionEx;

interface
  uses
    FMX.MediaLibrary.Actions; //for TTakePhotoCameraAction

  type

    TTakePhotoFromCameraActionEx = class(TTakePhotoFromCameraAction)
    protected
      FRequestPermission: boolean;
    public
      //TODO: add a RequestCameraPermission method and reuse from ExecuteTarget when RequestPermission=true
      procedure ExecuteTarget(Sender: TObject); override;
    published
      property RequestPermission: boolean read FRequestPermission write FRequestPermission;
    end;

  procedure Register;

implementation
  uses
    {$IF DEFINED(ANDROID)}
    Androidapi.Helpers, //for JStringToString
    Androidapi.JNI.Os, //for TJManifest_permission
    Androidapi.JNI.JavaTypes, //to avoid [DCC Hint] H2443 Inline function 'JStringToString' has not been expanded because unit 'Androidapi.JNI.JavaTypes' is not specified in USES list
    {$ENDIF}
    System.Classes, //for GroupDescendentsWith, RegisterComponents
    System.Types, //for TClassicStringDynArray
    FMX.Types, //for RegisterFmxClasses, log.d
    System.SysUtils, //to avoid [dcc32 Hint] H2443 Inline function 'Log.d' has not been expanded because unit 'System.SysUtils' is not specified in USES list
    System.Permissions; // Required for permission handling

  {$REGION 'TTakePhotoCameraActionEx' -----------------------------------------}

  procedure TTakePhotoFromCameraActionEx.ExecuteTarget(Sender: TObject);
  begin
    if not CanActionExec then exit; //fix for Delphi 12.2 ExecuteTarget, was not calling CanActionExec, thus not firing OnActionExec event

    if not RequestPermission then
    begin
      log.d('Info', Self, 'TTakePhotoFromCameraActionEx', 'Captruring photo (can request permission at OnCanActionExec event handler)');
      inherited; //Capture photo
      exit;
    end;

    //enhancement, doing automatic permission checking if RequestPermission=true
    {$IF DEFINED(ANDROID)}
    log.d('Info', Self, 'TTakePhotoFromCameraActionEx', 'Requesting permission');
    PermissionsService.RequestPermissions([JStringToString(TJManifest_permission.JavaClass.CAMERA)], //TJManifest_permission.JavaClass.CAMERA = 'android.permission.CAMERA'
      procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
      begin
        if (Length(AGrantResults) > 0) and (AGrantResults[0] = TPermissionStatus.Granted) then //check if permission granted
          //execute the action now that permission is granted, ensuring action executes on the main thread
          TThread.Queue(nil,
            procedure
            begin
              log.d('Info', Self, 'TTakePhotoFromCameraActionEx', 'Captruring photo');
              inherited; //Capture photo
            end);
      end);
    {$ELSE}
    //TODO: add permissions checking for iOS too? Doesn't seem to be needed currently (Dec2024)
    //...if TAVCaptureDevice.OCClass.authorizationStatusForMediaType(AVMediaTypeVideo) <> AVAuthorizationStatusAuthorized then begin TAVCaptureDevice.OCClass.requestAccessForMediaType(AVMediaTypeVideo, procedure(granted: Boolean) begin ...end)

    log.d('Info', Self, 'TTakePhotoFromCameraActionEx', 'Captruring photo');
    inherited; //Capture photo
    {$ENDIF}
  end;

  {$ENDREGION}

  {$REGION 'Registration' -----------------------------------------------------}

  procedure RegisterSerializationClasses;
  begin
    RegisterFmxClasses([TTakePhotoFromCameraActionEx]);
  end;

  procedure Register;
  begin
    GroupDescendentsWith(TTakePhotoFromCameraActionEx, TTakePhotoFromCameraAction);
    RegisterSerializationClasses;
    RegisterComponents('Zoomicon', [TTakePhotoFromCameraActionEx]);
  end;

  {$ENDREGION}

initialization
  RegisterSerializationClasses; //don't call Register here, it's called by the IDE automatically on a package installation (fails at runtime)

end.
