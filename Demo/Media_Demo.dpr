program Media_Demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MediaPlayerDemo in 'Views\MediaPlayerDemo.pas' {MediaPlayerDemo1},
  MediaDisplayDemo in 'Views\MediaDisplayDemo.pas' {MediaDisplayDemo1},
  FileChooserDemo in 'Views\FileChooserDemo.pas' {FileChooserDemo1};

{$R *.res}

begin
  Application.Initialize;

  //All forms are displayed at startup since their "Visible" property is set to "True" in the form designer (stored in respective .fmx files)
  Application.CreateForm(TMediaDisplayDemo1, MediaDisplayDemo1); //Application.MainForm
  Application.CreateForm(TMediaPlayerDemo1, MediaPlayerDemo1);
  Application.CreateForm(TFileChooserDemo1, FileChooserDemo1);

  Application.Run;
end.
