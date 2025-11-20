//Description: MediaDisplay control
//Source: https://github.com/Zoomicon/Zoomicon.Media.FMX.Delphi
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Media.FMX.MediaDisplay;

interface
  {$region 'Used units'}
  uses
    System.Classes, //for TStream, GroupDescendentsWith, RegisterComponents
    System.Types, //for TSizeF
    System.UITypes, //for TAlphaColor, TAlphaColorRec
    //
    FMX.Types, //for RegisterFmxClasses
    FMX.Layouts, //for TLayout
    FMX.Controls, //for TControl
    FMX.Media, //for TMediaTime
    FMX.Graphics, //for TBitmap
    FMX.Surfaces, //for TBitmapSurface
    FMX.Objects, //for TImage, TImageWrapMode
    FMX.Skia, //for TSkSvg, TSkAnimatedImage
    //
    Zoomicon.Media.FMX.Models; //for IMediaDisplay
  {$endregion}

  {$REGION 'TMediaDisplay'}

  resourcestring
    MSG_UNKNOWN_CONTENT_FORMAT = 'Unknown Content Format %s';

  type

    TMediaDisplay = class(TLayout, IMediaDisplay)
    protected
      FPresenter: TControl;
      FSVGLines: TStringList;
      FAutoSize: Boolean;
      FWrapMode: TImageWrapMode;
      FForegroundColor: TAlphaColor;

      {Presenter}
      procedure InitPresenter(const Value: TControl); virtual;
      procedure SetPresenter(const Value: TControl); overload; virtual;
      //Note: calling the following as SetXX instead of GetXX since they cause side-effects (they call SetPresenter if needed)
      function SetPresenter(const ContentFormat: String): TControl; overload; virtual;
      function SetSVGPresenter: TSkSvg; virtual;
      function SetAnimationPresenter: TSkAnimatedImage; virtual;
      function SetBitmapPresenter: TImage; virtual;

      {Content}
      procedure InitContent;

      {AutoSize}
      procedure SetAutoSize(const Value: Boolean); virtual;
      procedure DoAutoSize; virtual;
      function GetContentSize: TSizeF; virtual;

      {WrapMode}
      procedure SetWrapMode(const Value: TImageWrapMode); virtual;
      procedure DoWrap; virtual;

      {ForegroundColor}
      procedure SetForegroundColor(const Value: TAlphaColor); virtual;
      procedure ApplyForegroundColor; virtual;

      {Bitmap}
      function GetBitmap: TBitmap; virtual;
      procedure SetBitmap(const Value: TBitmap); overload; virtual;
      procedure SetBitmap(const Value: TBitmapSurface); overload; virtual;

      {SVGText}
      function GetSVGText: String; virtual;
      procedure SetSVGText(const Value: String); virtual;

      {SVGLines}
      function GetSVGLines: TStrings; virtual;
      procedure SetSVGLines(const Value: TStrings); virtual;

    public
      class function IsContentFormatBitmap(const ContentFormat: String): Boolean; virtual;
      class function IsContentFormatSVG(const ContentFormat: String): Boolean; virtual;
      class function IsContentFormatAnimation(const ContentFormat: String): Boolean; virtual;

      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;

      procedure Load(const Stream: TStream; const ContentFormat: String); virtual;
      procedure LoadBitmap(const Stream: TStream; const ContentFormat: String); virtual;
      procedure LoadSVG(const Stream: TStream; const ContentFormat: String); virtual;
      procedure LoadAnimation(const Stream: TStream; const ContentFormat: String); virtual;

      function HasNonEmptyBitmap: Boolean; virtual;
      function HasNonDefaultSVG: Boolean; virtual;

    published
      const
        DEFAULT_AUTOSIZE = false;
        DEFAULT_FOREGROUND_COLOR = TAlphaColorRec.Null; //claNull
        DEFAULT_SVG_TEXT = SVG_BLANK;
        DEFAULT_WRAP_MODE = TImageWrapMode.Stretch;

      property Presenter: TControl read FPresenter write SetPresenter stored false;

      property AutoSize: Boolean read FAutoSize write SetAutoSize default DEFAULT_AUTOSIZE;
      property ContentSize: TSizeF read GetContentSize;

      property WrapMode: TImageWrapMode read FWrapMode write SetWrapMode default DEFAULT_WRAP_MODE;

      property ForegroundColor: TAlphaColor read FForegroundColor write SetForegroundColor default DEFAULT_FOREGROUND_COLOR;

      property Bitmap: TBitmap read GetBitmap write SetBitmap stored HasNonEmptyBitmap default nil;
      property SVGText: String read GetSVGText write SetSVGText stored HasNonDefaultSVG;
      property SVGLines: TStrings read GetSVGLines write SetSVGLines stored false;
    end;

  {$ENDREGION}

  {$REGION 'Helpers'}

  function ImageWrapModeToSkSvg(AMode: TImageWrapMode): TSkSvgWrapMode;
  function ImageWrapModeToSkAnimated(AMode: TImageWrapMode): TSkAnimatedImageWrapMode;

  {$ENDREGION}

  procedure Register;

implementation
  uses
    System.SysUtils; //for FreeAndNil

  {$REGION 'Helpers'}

  function ImageWrapModeToSkSvg(AMode: TImageWrapMode): TSkSvgWrapMode;
  begin
    case AMode of
      TImageWrapMode.Original: Result := TSkSvgWrapMode.Original;
      TImageWrapMode.Fit:      Result := TSkSvgWrapMode.Fit;
      TImageWrapMode.Stretch:  Result := TSkSvgWrapMode.Stretch;
      TImageWrapMode.Tile:     Result := TSkSvgWrapMode.Tile;
      TImageWrapMode.Center:   Result := TSkSvgWrapMode.OriginalCenter;
      TImageWrapMode.Place:    Result := TSkSvgWrapMode.Place;
    else
      Result := TSkSvgWrapMode.Default; // respect SVG control default
    end;
  end;

  function ImageWrapModeToSkAnimated(AMode: TImageWrapMode): TSkAnimatedImageWrapMode;
  begin
    case AMode of
      TImageWrapMode.Original: Result := TSkAnimatedImageWrapMode.Original;
      TImageWrapMode.Fit:      Result := TSkAnimatedImageWrapMode.Fit;
      TImageWrapMode.Stretch:  Result := TSkAnimatedImageWrapMode.Stretch;
      TImageWrapMode.Center:   Result := TSkAnimatedImageWrapMode.OriginalCenter;
      TImageWrapMode.Place:    Result := TSkAnimatedImageWrapMode.Place;
      //TImageWrapMode.Tile has no animated equivalent; fall through
    else
      Result := TSkAnimatedImageWrapMode.Fit; // respect TSkAnimatedImage default
    end;
  end;

  {$ENDREGION}

  {$REGION 'TMediaDisplay'}

  {$region 'Initialization / Destruction'}

  constructor TMediaDisplay.Create(AOwner: TComponent);
  begin
    inherited;
    FSVGLines := TStringList.Create;

    //if not (csLoading in ComponentState) then
    //begin
      AutoSize := DEFAULT_AUTOSIZE;
      ForegroundColor := DEFAULT_FOREGROUND_COLOR;
      SVGText := DEFAULT_SVG_TEXT;
    //end;
  end;

  destructor TMediaDisplay.Destroy;
  begin
    FreeAndNil(FSVGLines);
    inherited;
  end;

  {$endregion}

  {$region 'Presenter'}

  procedure TMediaDisplay.InitPresenter(const Value: TControl);
  begin
    if not Assigned(Value) then
      exit;

    with Value do
    begin
      Stored := false; //don't store state, should use state from designed .FMX resource
      SetSubComponent(true);
      Align := TAlignLayout.Contents;
      HitTest := false; //don't capture mouse events, let the MediaDisplay control handle them
    end;

    Value.Parent := Self; //don't place in "with" statement, Self has to be the TMediaDisplay instance

    //Init per-presenter class type

    if (Value is TImage) then //for Bitmaps //Note: don't need to check this last, since TSkSvg and TSkAnimatedImage don't descend from TImage
    begin
      var img := (Value as TImage);
      img.WrapMode := TImageWrapMode.Stretch; //stretch the Bitmap
    end

    else if (Value is TSkSvg) then //for SVG
    begin
      var img := (Value as TSkSvg);
      img.Svg.WrapMode := TSkSvgWrapMode.Stretch; //stretch the SVG
    end

    else if (Value is TSkAnimatedImage) then //for Animation
    begin
      var img := (Value as TSkAnimatedImage);
      img.WrapMode := TSkAnimatedImageWrapMode.Stretch; //stretch the Animation
      //img.Animation.Enabled := true; //default is already true
      //img.Animation.Loop := true; //default is already true
    end;
  end;

  procedure TMediaDisplay.SetPresenter(const Value: TControl);
  begin
    if (Value = FPresenter) then
      exit;

    if Assigned(FPresenter) then
    begin
      FreeAndNil(FPresenter); //no need to remove from its Parent (Self) first
      FSVGLines.Clear; //do clear, but don't FreeAndNil
    end;

    InitPresenter(Value); //does check if Assigned (not nil)

    FPresenter := Value;
  end;

  function TMediaDisplay.SetPresenter(const ContentFormat: String): TControl;
  begin
    if IsContentFormatSVG(ContentFormat) then //checking for SVG first since it's less file extensions to check
      result := SetSVGPresenter
    else if IsContentFormatAnimation(ContentFormat) then
      result := SetAnimationPresenter
    else if IsContentFormatBitmap(ContentFormat) then
      result := SetBitmapPresenter
    else
      result := nil;
  end;

  function TMediaDisplay.SetBitmapPresenter: TImage;
  begin
    if not (Presenter is TImage) then //since TSkSvg and TSkAnimatedImage are not descending from TImage, we're safe to only do this check (else we'd also have to check if it's one of those two classes)
      Presenter := TImage.Create(Self);

    result := Presenter as TImage;
  end;

  function TMediaDisplay.SetSVGPresenter: TSkSvg;
  begin
    if not (Presenter is TSkSvg) then
      Presenter := TSkSvg.Create(Self);

    result := Presenter as TSkSvg;
  end;

  function TMediaDisplay.SetAnimationPresenter: TSkAnimatedImage;
  begin
    if not (Presenter is TSkAnimatedImage) then
      Presenter := TSkAnimatedImage.Create(Self);

    result := Presenter as TSkAnimatedImage;
  end;

  {$endregion}

  {$region 'AutoSize'}

  procedure TMediaDisplay.SetAutoSize(const Value: Boolean);
  begin
    if Value then DoAutoSize;
    FAutoSize := Value;
  end;

  procedure TMediaDisplay.DoAutoSize;
  begin
    Size.Size := ContentSize;
  end;

  function TMediaDisplay.GetContentSize: TSizeF;
  begin
    if (Presenter is TImage) then //for Bitmaps //Note: don't need to check this last, since TSkSvg and TSkAnimatedImage don't descend from TImage
      result := (Presenter as TImage).Bitmap.Size

    else if (Presenter is TSkSvg) then //for SVG
      result := (Presenter as TSkSvg).Svg.OriginalSize

    else if (Presenter is TSkAnimatedImage) then //for Animation
      result := (Presenter as TSkAnimatedImage).OriginalSize //if content is assigned will ask codec for size

    else
      result := TSizeF.Create(0, 0);
  end;

  {$endregion}

  {$region 'WrapMode'}

  procedure TMediaDisplay.SetWrapMode(const Value: TImageWrapMode);
  begin
    FWrapMode := Value;
    DoWrap;
  end;

  procedure TMediaDisplay.DoWrap;
  begin
    if (FPresenter is TImage) then //for Bitmaps
      (FPresenter as TImage).WrapMode := FWrapMode

    else if (FPresenter is TSkSvg) then //for SVG
      (FPresenter as TSkSvg).Svg.WrapMode := ImageWrapModeToSkSvg(FWrapMode)

    else if (FPresenter is TSkAnimatedImage) then //for Animation
      (FPresenter as TSkAnimatedImage).WrapMode := ImageWrapModeToSkAnimated(FWrapMode);
  end;

  {$endregion}

  {$region 'ForegroundColor'}

  procedure TMediaDisplay.SetForegroundColor(const Value: TAlphaColor);
  begin
    FForegroundColor := Value; //keep the foreground color

    ApplyForegroundColor;
  end;

  procedure TMediaDisplay.ApplyForegroundColor;
  begin
    if (FForegroundColor = TAlphaColorRec.Null) then
      exit; //never apply the null color as foreground, using it to mark no color replacement mode (the default)

    if (FPresenter is TImage) then //for Bitmaps //Note: don't need to check this last, since TSkSvg and TSkAnimatedImage don't descend from TImage
    begin
      var Bmp := (FPresenter as TImage).Bitmap;
      var M: TBitmapData;
      if (not Bmp.IsEmpty) and Bmp.Map(TMapAccess.ReadWrite, M) then
        try
          Bmp.ReplaceOpaqueColor(FForegroundColor);
        finally
          Bmp.Unmap(M);
        end;
    end //TODO: move to some TImageHelper

    else if (FPresenter is TSkSvg) then //for SVG
      (FPresenter as TSkSvg).Svg.OverrideColor := FForegroundColor;

    //else if (FPresenter is TSkAnimatedImage) then //for Animation
      //(FPresenter as TSkAnimatedImage).OverrideColor := FForegroundColor
  end;

  {$endregion}

  {$region 'Content'}

  procedure TMediaDisplay.InitContent;
  begin
    DoWrap;

    if FAutoSize then
      DoAutoSize;

    ApplyForegroundColor;
  end;

  {$region 'Bitmap'}

  function TMediaDisplay.HasNonEmptyBitmap: Boolean;
  begin
    const LBitmap = GetBitmap;
    result := Assigned(LBitmap);
    if result then
    begin
      const LBitmapImage = LBitmap.Image;
      result := Assigned(LBitmapImage) and (LBitmapImage.Width <> 0) and (LBitmapImage.Height <> 0); //checking LBitmap isn't enough
    end;
  end;

  function TMediaDisplay.GetBitmap: TBitmap;
  begin
    if (Presenter is TImage) then //it's safe to just check this since TSkSvg and TSkAnimatedImage don't descend from TImage
      result := (Presenter as TImage).Bitmap
    else
      result := nil;
  end;

  procedure TMediaDisplay.SetBitmap(const Value: TBitmap);
  begin
    if (Value = nil) then
      SetPresenter(nil)
    else
      SetBitmapPresenter.Bitmap := Value; //this does "Assign" internally and copies the Bitmap

    InitContent; //this does DoAutoSize (if AutoSize is set) and DoWrap
  end;

  procedure TMediaDisplay.SetBitmap(const Value: TBitmapSurface);
  begin
    if (Value = nil) then
      SetPresenter(nil)
    else
      SetBitmapPresenter.Bitmap.Assign(Value); //we can Assign TBitmapSurfaces to TBitmaps

    InitContent; //this does DoAutoSize (if AutoSize is set) and DoWrap
  end;

  {$endregion}

  {$region 'SVGText'}

  function TMediaDisplay.GetSVGText: String;
  begin
    result := FSVGLines.Text;
  end;

  procedure TMediaDisplay.SetSVGText(const Value: String);
  begin
    if (Value = '') or (Value.ToLower = SVG_BLANK) then
      SetPresenter(nil)
    else
    begin
      FSVGLines.Text := Value; //note: reusing a single TStrings instance
      SetSVGPresenter.Svg.Source := Value;
    end;

    InitContent; //this does DoAutoSize (if AutoSize is set) and DoWrap
  end;

  {$endregion}

  {$region 'SVGLines'}

  function TMediaDisplay.HasNonDefaultSVG: Boolean;
  var LSVGText: String;
  begin
    LSVGText := SVGText;
    result := (LSVGText <> '') and (LSVGText <> DEFAULT_SVG_TEXT);
  end;

  function TMediaDisplay.GetSVGLines: TStrings;
  begin
    result := FSVGLines;
  end;

  procedure TMediaDisplay.SetSVGLines(const Value: TStrings);
  begin
    if (Value <> nil) then
      SVGText := Value.Text //this will also update FSVGLines //Note: if we'd be setting FSVGLines directly here, we'd need to use FSVGLines.Assign(Value), not FSVGLines := Value
    else
      SVGText := '';
  end;

  {$endregion}

  {$region 'IsContentFormat'}

  class function TMediaDisplay.IsContentFormatBitmap(const ContentFormat: String): Boolean;
  begin
    result :=
      {$IF DEFINED(MSWINDOWS)}
      (ContentFormat = EXT_BMP) or
      {$ENDIF}
      (ContentFormat = EXT_PNG) or
      (ContentFormat = EXT_JPEG) or
      (ContentFormat = EXT_JPG);
  end;

  class function TMediaDisplay.IsContentFormatAnimation(const ContentFormat: String): Boolean;
  begin
    result :=
      (ContentFormat = EXT_LOTTIE) or
      (ContentFormat = EXT_LOTTIE_JSON) or
      (ContentFormat = EXT_TELEGRAM_STICKER) or
      (ContentFormat = EXT_GIF) or
      (ContentFormat = EXT_WEBP);
  end;

  class function TMediaDisplay.IsContentFormatSVG(const ContentFormat: String): Boolean;
  begin
    result := (ContentFormat = EXT_SVG); //TODO: add support for .SVGZ (Gzipped SVG)
  end;
  
  {$endregion}

  {$region 'Load'}

  procedure TMediaDisplay.Load(const Stream: TStream; const ContentFormat: String);
  begin
     //checking for SVG first since it's less file extensions to check
    if IsContentFormatSVG(ContentFormat) then
      LoadSVG(Stream, ContentFormat)
    else if IsContentFormatAnimation(ContentFormat) then //since some bitmap formats (like GIF, WEBP) also support animation, better check first
      LoadAnimation(Stream, ContentFormat)
    else if IsContentFormatBitmap(ContentFormat) then
      LoadBitmap(Stream, ContentFormat)
    else
      raise Exception.CreateFmt(MSG_UNKNOWN_CONTENT_FORMAT, [ContentFormat]);
  end;

  procedure TMediaDisplay.LoadBitmap(const Stream: TStream; const ContentFormat: String);
  begin
    if not IsContentFormatBitmap(ContentFormat) then //TODO: this causes rechecking of file extension when called via Load
      exit;

    const LImage = SetBitmapPresenter;

    LImage.Bitmap.LoadFromStream(Stream);

    InitContent; //this does DoAutoSize (if AutoSize is set) and DoWrap
  end;

  procedure TMediaDisplay.LoadSVG(const Stream: TStream; const ContentFormat: String);
  begin //TODO: add support for SVG (Gzipped SVG)
    if not IsContentFormatSVG(ContentFormat) then //TODO: this causes rechecking of file extension when called via Load
      exit;

    SetSVGPresenter;

    //SVGText := ReadAllText(Stream); //TODO: using this as workaround since LoadFromStream doesn't seem to be compilable anymore //TODO: see why it fails (stack pointer corruption?)

    var s := TStringList.Create(#0, #13);
    try
      s.LoadFromStream(Stream);
      SVGText := s.DelimitedText; //use this instead of setting SVGText of the SVG presenter directly so that any extra side-effects like DoWrap and DoAutoSize are done in one place
    finally
      FreeAndNil(s);
    end;
  end;

  procedure TMediaDisplay.LoadAnimation(const Stream: TStream; const ContentFormat: String);
  begin
    if not IsContentFormatAnimation(ContentFormat) then //TODO: this causes rechecking of file extension when called via Load
      exit;

    const LAnimation = SetAnimationPresenter;

    LAnimation.LoadFromStream(Stream);

    InitContent; //this does DoAutoSize (if AutoSize is set) and DoWrap
  end;

  {$endregion}

  {$endregion}

  {$ENDREGION}

  {$REGION 'Registration'}

  procedure RegisterSerializationClasses;
  begin
    RegisterFmxClasses([TMediaDisplay]);
  end;

  procedure Register;
  begin
    GroupDescendentsWith(TMediaDisplay, TComponent);
    RegisterSerializationClasses;
    RegisterComponents('Zoomicon', [TMediaDisplay]);
  end;

  {$ENDREGION}

initialization
  RegisterSerializationClasses; //don't call Register here, it's called by the IDE automatically on a package installation (fails at runtime)

end.
