//Description: FullScreen utility (Fullscreen implementation for iOS, Exit fullscreen fix for Windows for Delphi 12.3)
//Source: https://github.com/Zoomicon/Zoomicon.Media.FMX.Delphi
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Media.FMX.FullScreen;

interface
  uses FMX.Forms;

  {$IF DEFINED(MSWINDOWS)}
  procedure SetFullscreen_WindowsFix(const AForm: TCommonCustomForm; const AValue: Boolean);
  {$ENDIF}

  {$region 'TFullScreenServiceiOS'}
  (*
  Description: FireMonkey TPlatformServices - IFMXFullScreenWindowService for iOS
  Author: Stephen Ball

  Info: https://delphiaball.co.uk/2014/10/16/expanding-firemonkey-tplatformservices/
  Source code: http://cc.embarcadero.com/item/30023

  Copyright: No significant restrictions
  Terms of use: Embarcadero use at your own risk disclaimer
  *)
  {$IF DEFINED(IOS)}
  type
    TFullScreenServiceiOS = class(TInterfacedObject, IFMXFullScreenWindowService)
    private
      FOriginalBorderStyle : TFmxFormBorderStyle;
    public
      function GetFullScreen(const AForm: TCommonCustomForm): Boolean;
      procedure SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
      procedure SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
    end;
  {$ENDIF}
  {$endregion}

implementation
  uses
    {$IF DEFINED(MSWINDOWS)}
    System.Generics.Collections, //TODO: fullscreen fix for Delphi 12.2 which can't exit fullscreen
    System.Types, //for TPointF, TSizeF
    System.UITypes, //for TWindowState
    {$ELSEIF DEFINED(IOS)}
    FMX.Platform,
    {$ENDIF}
    System.RTLConsts, //for SParamIsNil
    System.SysUtils; //for EArgumentException

  procedure RaiseIfNil(const AObject: TObject; const AArgumentName: string); //copied from FMX.Platform.Win //TODO: maybe move to Zoomicon.RTL.Helpers
  begin
    if AObject = nil then
      raise EArgumentException.CreateFmt(SParamIsNil, [AArgumentName]);
  end;

  {$region 'Fullscreen fix for Windows'} //TODO: temp fullscreen fix for Delphi 12.2 which can't exit fullscreen
  {$IF DEFINED(MSWINDOWS)}
  type //copied from FMX.Platform.Win
    TFullScreenSavedState = record
      BorderStyle: TFmxFormBorderStyle;
      WindowState: TWindowState;
      Position: TPointF;
      Size: TSizeF;
      IsFullscreen: Boolean;
    end;

  var FFullScreenSupport : TDictionary<TCommonCustomForm, TFullScreenSavedState>; //copied from FMX.Platform.Win (was a class field, here we create/destroy it at initialization and finalization section of this unit below)

  procedure SetFullscreen_WindowsFix(const AForm: TCommonCustomForm; const AValue: Boolean);
  var
    SavedState: TFullScreenSavedState;
  begin
    RaiseIfNil(AForm, 'AForm');

    if AValue and not (TFmxFormState.Showing in AForm.FormState) then
      AForm.Visible := True;

    if not FFullScreenSupport.TryGetValue(AForm, SavedState) then
    begin
      FillChar(SavedState, SizeOf(SavedState), 0);
      FFullScreenSupport.Add(AForm, SavedState);
    end;

    if AValue and (AForm.Visible or (TFmxFormState.Showing in AForm.FormState)) then
    begin
      SavedState.IsFullscreen := AValue;
      SavedState.WindowState := AForm.WindowState;
      SavedState.BorderStyle := AForm.BorderStyle;
      if AForm.WindowState = TWindowState.wsNormal then
      begin
        SavedState.Size := TSizeF.Create(AForm.Width, AForm.Height);
        SavedState.Position := TPointF.Create(AForm.Left, AForm.Top);
      end;
      FFullScreenSupport.Items[AForm] := SavedState;
      if AForm.WindowState = TWindowState.wsMinimized then
        AForm.WindowState := TWindowState.wsMaximized;
      AForm.BorderStyle := TFmxFormBorderStyle.None;
      AForm.WindowState := TWindowState.wsMaximized;
    end
    else if SavedState.IsFullscreen then
    begin
      // Restore the saved state
      AForm.BorderStyle := SavedState.BorderStyle;
      AForm.SetBoundsF(SavedState.Position.X, SavedState.Position.Y, SavedState.Size.Width, SavedState.Size.Height);
      AForm.WindowState := SavedState.WindowState;
      SavedState.IsFullscreen := False;
      FFullScreenSupport.Items[AForm] := SavedState; // Update saved state to reflect not fullscreen
    end;
  end;
  {$ENDIF}
  {$endregion}

  {$region 'TFullScreenServiceiOS'}
  {$IF DEFINED(IOS)}
  function TFullScreenServiceiOS.GetFullScreen(const AForm: TCommonCustomForm): Boolean;
  begin
    if (AForm = nil) then
      Exit(False);

    Result := AForm.BorderStyle = TFmxFormBorderStyle.None;
  end;

  procedure TFullScreenServiceiOS.SetFullScreen(const AForm: TCommonCustomForm; const AValue: Boolean);
  begin
    if (AForm = nil) then
      Exit;

    if AValue then
    begin
      if AForm.BorderStyle <> TFmxFormBorderStyle.None then
        FOriginalBorderStyle := AForm.BorderStyle;

      AForm.BorderStyle := TFmxFormBorderStyle.None
    end
    else
    begin
      if (FOriginalBorderStyle = TFmxFormBorderStyle.None) and (AValue = False) then
        FOriginalBorderStyle := TFmxFormBorderStyle.Sizeable;

      AForm.BorderStyle := FOriginalBorderStyle;
    end;
  end;

  procedure TFullScreenServiceiOS.SetShowFullScreenIcon(const AForm: TCommonCustomForm; const AValue: Boolean);
  begin
    // N/A
  end;

  procedure RegisterFullScreenServiceiOS;
  begin
    if not TPlatformServices.Current.SupportsPlatformService(IFMXFullScreenWindowService) then
      //Note: recent Delphi versions implement  fullscreen service for iOS too, keep that one (could remove it and register ours - adding it twice would cause crash giving back GUID of that service interface, aka {103EB4B7-E899-4684-8174-2EEEE24F1E58})
      TPlatformServices.Current.AddPlatformService(IFMXFullScreenWindowService, TFullScreenServiceiOS.Create);
  end;
  {$ENDIF}
  {$endregion}

initialization
  {$IF DEFINED(MSWINDOWS)}
  FFullScreenSupport := TDictionary<TCommonCustomForm, TFullScreenSavedState>.Create; //TODO: temp fullscreen fix for Delphi 12.2 which can't exit fullscreen
  {$ENDIF}

  {$IF DEFINED(IOS)}
  RegisterFullScreenServiceiOS;
  {$ENDIF}

finalization
  {$IF DEFINED(MSWINDOWS)}
  FreeAndNil(FFullScreenSupport); //TODO: temp fullscreen fix for Delphi 12.2 which can't exit fullscreen
  {$ENDIF}
end.

