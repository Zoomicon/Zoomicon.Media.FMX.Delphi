unit Zoomicon.Media.FMX.VertScrollBoxWithArrows;

interface
  {$region 'Used units'}
  uses
    System.Classes, System.Types, System.UITypes,
    FMX.Types, FMX.Controls, FMX.StdCtrls, FMX.Layouts, FMX.Objects,
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
      procedure UpdateArrowVisibility;
      procedure DoScrollStep;
      procedure OnViewportChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
      procedure ArrowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
      procedure ArrowMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
      procedure RepeatTimerTick(Sender: TObject);
      procedure SetScrollStep(const Value: Integer);
      procedure SetRepeatInterval(const Value: Integer);
      procedure Resize; override;
    public
      constructor Create(AOwner: TComponent); override;
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

    FTopBtn := TSpeedButton.Create(Self);
    FTopBtn.Parent := Self;
    FTopBtn.Align := TAlignLayout.Top;
    FTopBtn.Height := 22;
    FTopBtn.Text := '▲';
    FTopBtn.Visible := False;
    FTopBtn.HitTest := True;
    FTopBtn.OnMouseDown := ArrowMouseDown;
    FTopBtn.OnMouseUp := ArrowMouseUp;

    FBottomBtn := TSpeedButton.Create(Self);
    FBottomBtn.Parent := Self;
    FBottomBtn.Align := TAlignLayout.Bottom;
    FBottomBtn.Height := 22;
    FBottomBtn.Text := '▼';
    FBottomBtn.Visible := False;
    FBottomBtn.HitTest := True;
    FBottomBtn.OnMouseDown := ArrowMouseDown;
    FBottomBtn.OnMouseUp := ArrowMouseUp;

    OnViewportPositionChange := OnViewportChanged;
  end;

  procedure TVertScrollBoxWithArrows.Resize;
  begin
    inherited;
    UpdateArrowVisibility;
  end;

  procedure TVertScrollBoxWithArrows.OnViewportChanged(Sender: TObject; const OldViewportPosition, NewViewportPosition: TPointF; const ContentSizeChanged: Boolean);
  begin
    UpdateArrowVisibility;
  end;

  procedure TVertScrollBoxWithArrows.UpdateArrowVisibility;
  var
    CanScrollUp, CanScrollDown: Boolean;
  begin
    CanScrollUp := ViewportPosition.Y > 0;
    CanScrollDown := ContentBounds.Height > Height + ViewportPosition.Y;
    FTopBtn.Visible := CanScrollUp;
    FBottomBtn.Visible := CanScrollDown;
  end;

  procedure TVertScrollBoxWithArrows.DoScrollStep;
  begin
    if AniCalculations <> nil then AniCalculations.MouseWheel(0, FScrollDirection * FScrollStep);
  end;

  procedure TVertScrollBoxWithArrows.ArrowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    if Sender = FTopBtn then FScrollDirection := -1 else FScrollDirection := +1;
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
    FRepeatTimer.Interval := Value;
  end;

  {$ENDREGION}

  {$REGION 'Registration' -----------------------------------------------------}

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
  RegisterSerializationClasses; //don't call Register here, it's called by the IDE automatically on a package installation (fails at runtime)

end.

