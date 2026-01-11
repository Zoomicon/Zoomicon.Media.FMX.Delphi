//Description: Media Models
//Source: https://github.com/Zoomicon/Zoomicon.Media.FMX.Delphi
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Media.FMX.Models;

interface
  uses
    System.Classes, //for TStream
    System.Types, //for TSizeF
    System.UITypes, //for TAlphaColor
    FMX.Controls, //for TControl
    FMX.Graphics, //for TBitmap
    FMX.Media, //for TMediaTime
    FMX.Surfaces, //for TBitmapSurface
    FMX.Objects; //for TImageWrapMode

  {$REGION 'IClipboardEnabled'}

   type
    IClipboardEnabled = interface
      ['{FDD22AC7-873A-4127-B200-E99DB4F2DEBF}']
      procedure Delete;
      procedure Cut; //does Copy, then Delete
      procedure Copy;
      procedure Paste;
    end;

  {$ENDREGION}

  {$REGION 'IMediaPlayer'}

  type
    TOnPlay = procedure of object;
    TOnPause = procedure of object;
    TOnStop = procedure of object;
    TOnAtStart = procedure of object;
    TOnAtEnd = procedure of object;
    TCurrentTimeChange = procedure(Sender: TObject; const NewTime: TMediaTime) of object;

    IMediaPlayer = interface
      ['{5D5F02BF-8066-49C0-B552-2B127DC8A6AD}']
      //-- Methods
      procedure Play(const FromStart: Boolean = false);
      procedure Rewind;
      procedure Pause;
      procedure Stop;
      {MediaLoaded}
      function IsMediaLoaded: Boolean;
      {Playing}
      function IsPlaying: Boolean;
      procedure SetPlaying(const Value: Boolean);
      {AtStart}
      function IsAtStart: Boolean;
      {AtEnd}
      function IsAtEnd: Boolean;
      {Finished}
      function IsFinished: Boolean;
      {AutoPlaying}
      function IsAutoPlaying: Boolean;
      procedure SetAutoPlaying(const Value: Boolean);
      {Looping}
      function IsLooping: Boolean;
      procedure SetLooping(const Value: Boolean);
      {Filename}
      function GetFilename: String;
      procedure SetFilename(const Value: String);
      {Stream}
      procedure SetStream(const Value: TStream);

      //-- Properties
      property MediaLoaded: Boolean read IsMediaLoaded; //stored false
      property Playing: Boolean read IsPlaying write SetPlaying; //stored false
      property AtStart: Boolean read IsAtStart;
      property AtEnd: Boolean read IsAtEnd;
      property Finished: Boolean read IsFinished;
      property AutoPlaying: Boolean read IsAutoPlaying write SetAutoPlaying;
      property Looping: Boolean read IsLooping write SetLooping;
      property Filename: String read GetFilename write SetFilename; //stored when not loaded from a Stream
      property Stream: TStream write SetStream; //stored false
    end;

  {$ENDREGION}

  {$REGION 'IMediaDisplay'}

  const

    {$IF DEFINED(MSWINDOWS)}
    EXT_BMP = '.bmp';
    {$ENDIF}
    EXT_SVG = '.svg';
    EXT_PNG = '.png';
    EXT_JPG = '.jpg';
    EXT_JPEG = '.jpeg';

    {$region 'with Skia4Delphi'}
    //TODO: Skia4Delphi library registers the following codecs (https://github.com/skia4delphi/skia4delphi?tab=readme-ov-file#image-formats)
    //  VCL: .svg, .webp, .wbmp and raw images (.arw, .cr2, .dng, .nef, .nrw, .orf, .raf, .rw2, .pef and .srw).
    //  FMX: .bmp, .gif, .ico, .webp, .wbmp and raw images (.arw, .cr2, .dng, .nef, .nrw, .orf, .raf, .rw2, .pef and .srw).
    //
    EXT_LOTTIE = '.lottie';
    EXT_LOTTIE_JSON = '.json';
    EXT_TELEGRAM_STICKER = '.tgs';
    EXT_GIF = '.gif'; //also supports animation
    EXT_WEBP = '.webp'; //also supports animation

    (*
    The Skia4Delphi library supports many image formats (https://github.com/skia4delphi/skia4delphi?tab=readme-ov-file#codecs):

    Supported formats for decoding

    Image Format    Extensions
    Bitmap  .bmp
    GIF .gif
    Icon    .ico
    JPEG    .jpg, .jpeg
    PNG .png
    Raw Adobe DNG Digital Negative  .dng
    Raw Canon   .cr2
    Raw Fujifilm RAF    .raf
    Raw Nikon   .nef, .nrw
    Raw Olympus ORF .orf
    Raw Panasonic   .rw2
    Raw Pentax PEF  .pef
    Raw Samsung SRW .srw
    Raw Sony    .arw
    WBMP    .wbmp
    WebP    .webp
    Note: Raw images are limited to non-windows platforms

    Supported formats for encoding

    Image Format    Extensions
    JPEG    .jpg, .jpeg
    PNG .png
    WebP    .webp
    *)

    {$endregion}

    SVG_BLANK = '<svg xmlns="http://www.w3.org/2000/svg"></svg>';

  type
    IMediaDisplay = interface
      {Presenter}
      procedure InitPresenter(const Value: TControl);
      function GetPresenter: TControl;
      procedure SetPresenter(const Value: TControl);

      {AutoSize}
      function IsAutoSize: Boolean;
      procedure SetAutoSize(const Value: Boolean);
      function GetContentSize: TSizeF;

      {WrapMode}
      function GetWrapMode: TImageWrapMode;
      procedure SetWrapMode(const Value: TImageWrapMode);

      {Looping (for Animation)}
      function IsLooping: Boolean;
      procedure SetLooping(const Value: Boolean);

      {ForegroundColor}
      function GetForegroundColor: TAlphaColor;
      procedure SetForegroundColor(const Value: TAlphaColor);

      {Bitmap}
      function GetBitmap: TBitmap;
      procedure SetBitmap(const Value: TBitmap); overload;
      procedure SetBitmap(const Value: TBitmapSurface); overload;

      {SVGText}
      function GetSVGText: String;
      procedure SetSVGText(const Value: String);

      {SVGLines}
      function GetSVGLines: TStrings;
      procedure SetSVGLines(const Value: TStrings);

      {Loading}
      procedure Load(const Stream: TStream; const ContentFormat: String);
      procedure LoadBitmap(const Stream: TStream; const ContentFormat: String);
      procedure LoadSVG(const Stream: TStream; const ContentFormat: String);
      procedure LoadAnimation(const Stream: TStream; const ContentFormat: String);

      property Presenter: TControl read GetPresenter write SetPresenter;

      property AutoSize: Boolean read IsAutoSize write SetAutoSize;
      property ContentSize: TSizeF read GetContentSize;
      property WrapMode: TImageWrapMode read GetWrapMode write SetWrapMode;
      property Looping: Boolean read IsLooping write SetLooping;
      property ForegroundColor: TAlphaColor read GetForegroundColor write SetForegroundColor;

      property Bitmap: TBitmap read GetBitmap write SetBitmap;
      property SVGText: String read GetSVGText write SetSVGText;
      property SVGLines: TStrings read GetSVGLines write SetSVGLines;
    end;

  {$ENDREGION}

implementation

end.

