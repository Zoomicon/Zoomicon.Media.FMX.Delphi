unit Zoomicon.Media.FMX.VertScrollBoxWithArrows;

interface
  {$region 'Used units'}
  uses
    System.Classes, System.SysUtils, System.Types, System.UITypes,
    FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Objects, FMX.Text,
    FMX.ScrollBox;
  {$endregion}

  type

    {$REGION 'TVertScrollBoxWithArrows'}

    TVertScrollBoxWithArrows = class(TVertScrollBox)
    protected
      FTopBtn: TSpeedButton;
      FBottomBtn: TSpeedButton;
      FRepeatTimer: TTimer;
      FScrollDirection: Integer;
      FScrollStep: Integer;
      FRepeatInterval: Integer;
      procedure CreateArrowButton(var Btn: TSpeedButton; const ArrowChar: string);
      procedure UpdateArrowVisibility;
      procedure UpdateArrowPositions;
      procedure DoScrollStep;
      procedure OnViewportChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
      procedure ArrowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
      procedure ArrowMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
      procedure RepeatTimerTick(Sender: TObject);
      procedure SetScrollStep(const Value: Integer);
      procedure SetRepeatInterval(const Value: Integer);
      procedure Resize; override;
      procedure Loaded; override;
      procedure DoAddObject(const AObject: TFmxObject); override;
    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
    published
      property ScrollStep: Integer read FScrollStep write SetScrollStep default 40;
      property RepeatInterval: Integer read FRepeatInterval write SetRepeatInterval default 60;
    end;

    {$ENDREGION}

  procedure Register;

implementation

  {$REGION 'TVertScrollBoxWithArrows'}

  constructor TVertScrollBoxWithArrows.Create(AOwner: TComponent);
  begin
    inherited;
    FScrollStep := 40;
    FRepeatInterval := 60;

    FRepeatTimer := TTimer.Create(Self);
    FRepeatTimer.Enabled := False;
    FRepeatTimer.Interval := FRepeatInterval;
    FRepeatTimer.OnTimer := RepeatTimerTick;

    CreateArrowButton(FTopBtn, '▲');
    CreateArrowButton(FBottomBtn, '▼');

    OnViewportPositionChange := OnViewportChanged;
  end;

  destructor TVertScrollBoxWithArrows.Destroy;
  begin
    if Assigned(FRepeatTimer) then
      FreeAndNil(FRepeatTimer);
    if Assigned(FTopBtn) then
      FreeAndNil(FTopBtn);
    if Assigned(FBottomBtn) then
      FreeAndNil(FBottomBtn);
    inherited;
  end;

  procedure TVertScrollBoxWithArrows.CreateArrowButton(var Btn: TSpeedButton; const ArrowChar: string);
  var
    BackText, FrontText: TText;
    FrontSize, BackSize: Single;
    BaselineAdjust: Single;
  begin
    Btn := TSpeedButton.Create(Self);
    Btn.Parent := Self;            // keep inside the scrollbox content
    Btn.Stored := False;
    Btn.Align := TAlignLayout.None;
    Btn.Width := 36;
    Btn.Height := 36;
    Btn.Text := '';
    Btn.HitTest := True;
    Btn.StyleLookup := '';        // avoid style chrome interfering

    // Choose sizes: front smaller, back larger so outline is visible all around
    FrontSize := 18;
    BackSize := FrontSize + 6; // make the back text noticeably larger for a clear outline

    // Back (outline) text: black, larger
    BackText := TText.Create(Btn);
    BackText.Parent := Btn;
    BackText.Align := TAlignLayout.Client;
    BackText.Text := ArrowChar;
    BackText.TextSettings.HorzAlign := TTextAlign.Center;
    BackText.TextSettings.VertAlign := TTextAlign.Center;
    BackText.TextSettings.Font.Size := BackSize;
    BackText.TextSettings.Font.Style := [TFontStyle.fsBold];
    BackText.TextSettings.FontColor := TAlphaColorRec.Black;
    BackText.HitTest := False;

    // Glyph-specific baseline correction
    if ArrowChar = '▲' then
      BaselineAdjust := -1   // lift outline
    else if ArrowChar = '▼' then
      BaselineAdjust := 2   // lower outline
    else
      BaselineAdjust := 0;

    // Auto-center the larger outline behind the smaller fill
    BackText.Margins.Top := ((FrontSize - BackSize) / 2) + BaselineAdjust;

    // Front (fill) text: white, smaller and centered over back text
    FrontText := TText.Create(Btn);
    FrontText.Parent := Btn;
    FrontText.Align := TAlignLayout.Client;
    FrontText.Text := ArrowChar;
    FrontText.TextSettings.HorzAlign := TTextAlign.Center;
    FrontText.TextSettings.VertAlign := TTextAlign.Center;
    FrontText.TextSettings.Font.Size := FrontSize;
    FrontText.TextSettings.Font.Style := [TFontStyle.fsBold];
    FrontText.TextSettings.FontColor := TAlphaColorRec.White;
    FrontText.HitTest := False;

    Btn.OnMouseDown := ArrowMouseDown;
    Btn.OnMouseUp := ArrowMouseUp;
    Btn.Visible := False;
  end;

  procedure TVertScrollBoxWithArrows.Loaded;
  begin
    inherited;
    UpdateArrowPositions;
    UpdateArrowVisibility;
    if Assigned(FTopBtn) then FTopBtn.BringToFront;
    if Assigned(FBottomBtn) then FBottomBtn.BringToFront;
  end;

  procedure TVertScrollBoxWithArrows.DoAddObject(const AObject: TFmxObject);
  begin
    inherited;
    if not (csLoading in ComponentState) then
    begin
      if Assigned(FTopBtn) then FTopBtn.BringToFront;
      if Assigned(FBottomBtn) then FBottomBtn.BringToFront;
    end;
  end;

  procedure TVertScrollBoxWithArrows.Resize;
  begin
    inherited;
    UpdateArrowPositions;
    UpdateArrowVisibility;
    if Assigned(FTopBtn) then FTopBtn.BringToFront;
    if Assigned(FBottomBtn) then FBottomBtn.BringToFront;
  end;

  procedure TVertScrollBoxWithArrows.UpdateArrowPositions;
  var
    VX, VY: Single;
    CX: Single;
  begin
    VX := ViewportPosition.X;
    VY := ViewportPosition.Y;
    CX := (Width - FTopBtn.Width) * 0.5;

    if Assigned(FTopBtn) then
    begin
      FTopBtn.Position.X := VX + CX;
      FTopBtn.Position.Y := VY + 6;
    end;

    if Assigned(FBottomBtn) then
    begin
      FBottomBtn.Position.X := VX + CX;
      FBottomBtn.Position.Y := VY + Height - FBottomBtn.Height - 6;
    end;
  end;

  procedure TVertScrollBoxWithArrows.OnViewportChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
  begin
    UpdateArrowVisibility;
    UpdateArrowPositions;
    if Assigned(FTopBtn) then FTopBtn.BringToFront;
    if Assigned(FBottomBtn) then FBottomBtn.BringToFront;
  end;

  procedure TVertScrollBoxWithArrows.UpdateArrowVisibility;
  var
    CanScrollUp, CanScrollDown: Boolean;
  begin
    CanScrollUp := ViewportPosition.Y > 0;
    CanScrollDown := ContentBounds.Height > Height + ViewportPosition.Y;
    if Assigned(FTopBtn) then FTopBtn.Visible := CanScrollUp;
    if Assigned(FBottomBtn) then FBottomBtn.Visible := CanScrollDown;
  end;

  procedure TVertScrollBoxWithArrows.DoScrollStep;
  begin
    if AniCalculations <> nil then
      AniCalculations.MouseWheel(0, FScrollDirection * FScrollStep);
    UpdateArrowVisibility;
    UpdateArrowPositions;
    if Assigned(FTopBtn) then FTopBtn.BringToFront;
    if Assigned(FBottomBtn) then FBottomBtn.BringToFront;
  end;

  procedure TVertScrollBoxWithArrows.ArrowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    if Sender = FTopBtn then
      FScrollDirection := -1
    else
      FScrollDirection := +1;
    DoScrollStep;
    FRepeatTimer.Enabled := True;
  end;

  procedure TVertScrollBoxWithArrows.ArrowMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    FRepeatTimer.Enabled := False;
  end;

  procedure TVertScrollBoxWithArrows.RepeatTimerTick(Sender: TObject);
  begin
    DoScrollStep;
  end;

  procedure TVertScrollBoxWithArrows.SetScrollStep(const Value: Integer);
  begin
    FScrollStep := Value;
  end;

  procedure TVertScrollBoxWithArrows.SetRepeatInterval(const Value: Integer);
  begin
    FRepeatInterval := Value;
    if Assigned(FRepeatTimer) then
      FRepeatTimer.Interval := Value;
  end;

  {$ENDREGION}

  {$REGION 'Registration'}

  procedure RegisterSerializationClasses;
  begin
    RegisterFmxClasses([TVertScrollBoxWithArrows]);
  end;

  procedure Register;
  begin
    GroupDescendentsWith(TVertScrollBox, TVertScrollBoxWithArrows);
    RegisterSerializationClasses;
    RegisterComponents('Zoomicon', [TVertScrollBoxWithArrows]);
  end;

  {$ENDREGION}

initialization
  RegisterSerializationClasses;

end.

