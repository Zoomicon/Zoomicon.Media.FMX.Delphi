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
      procedure ExecuteTarget(Sender: TObject); override;
    published
      property RequestPermission: boolean read FRequestPermission write FRequestPermission;
    end;

  procedure Register;

implementation
  uses
    System.Classes, //for GroupDescendentsWith, RegisterComponents
    System.Types, //for TClassicStringDynArray
    FMX.Types, //for RegisterFmxClasses
    System.Permissions; // Required for permission handling

  {$REGION 'TTakePhotoCameraActionEx' -----------------------------------------}

  procedure TTakePhotoFromCameraActionEx.ExecuteTarget(Sender: TObject);
  begin
    if not CanActionExec then exit; //fix for Delphi 12.2 ExecuteTarget, was not calling CanActionExec, thus not firing OnActionExec event

    if not RequestPermission then
      inherited; //Capture photo

    //enhancement, doing automatic permission checking if RequestPermission=true
    PermissionsService.RequestPermissions(['android.permission.CAMERA'],
      procedure(const APermissions: TClassicStringDynArray; const AGrantResults: TClassicPermissionStatusDynArray)
      begin
        if (Length(AGrantResults) > 0) and (AGrantResults[0] = TPermissionStatus.Granted) then //check if permission granted
          //execute the action now that permission is granted, ensuring action executes on the main thread
          TThread.Queue(nil,
            procedure
            begin
              log.d('Info', Self, 'TakePhotoFromCameraActionCanActionExec', 'Executing action');

              inherited; //Capture photo
            end);
      end);
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