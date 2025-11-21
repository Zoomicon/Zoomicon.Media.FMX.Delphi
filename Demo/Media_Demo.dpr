program Media_Demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MediaPlayerDemo in 'Views\MediaPlayerDemo.pas' {MediaPlayerDemo1},
  MediaDisplayDemo in 'Views\MediaDisplayDemo.pas' {MediaDisplayDemo1},
  FileChooserDemo in 'Views\FileChooserDemo.pas' {FileChooserDemo1},
  Zoomicon.Media.FMX.ClickableGlyph in '..\Source\Zoomicon.Media.FMX.ClickableGlyph.pas',
  Zoomicon.Media.FMX.DataBinding in '..\Source\Zoomicon.Media.FMX.DataBinding.pas',
  Zoomicon.Media.FMX.FileChooser in '..\Source\Zoomicon.Media.FMX.FileChooser.pas' {FileChooser: TFrame},
  Zoomicon.Media.FMX.FullScreen in '..\Source\Zoomicon.Media.FMX.FullScreen.pas',
  Zoomicon.Media.FMX.MediaDisplay in '..\Source\Zoomicon.Media.FMX.MediaDisplay.pas',
  Zoomicon.Media.FMX.MediaPlayerEx in '..\Source\Zoomicon.Media.FMX.MediaPlayerEx.pas',
  Zoomicon.Media.FMX.ModalFrame in '..\Source\Zoomicon.Media.FMX.ModalFrame.pas' {ModalFrame: TFrame},
  Zoomicon.Media.FMX.Models in '..\Source\Zoomicon.Media.FMX.Models.pas',
  Zoomicon.Media.FMX.TakePhotoFromCameraActionEx in '..\Source\Zoomicon.Media.FMX.TakePhotoFromCameraActionEx.pas',
  Zoomicon.Media.FMX.SkiaUtils in '..\Source\Zoomicon.Media.FMX.SkiaUtils.pas';

{$R *.res}

begin
  Application.Initialize;

  //All forms are displayed at startup since their "Visible" property is set to "True" in the form designer (stored in respective .fmx files)
  Application.CreateForm(TMediaDisplayDemo1, MediaDisplayDemo1);
  //Application.MainForm
  Application.CreateForm(TMediaPlayerDemo1, MediaPlayerDemo1);
  Application.CreateForm(TFileChooserDemo1, FileChooserDemo1);

  Application.Run;
end.
