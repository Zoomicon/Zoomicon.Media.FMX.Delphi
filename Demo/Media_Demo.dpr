program Media_Demo;

uses
  System.StartUpCopy,
  FMX.Forms,
  MediaDisplayDemo in 'Views\MediaDisplayDemo.pas' {MediaDisplayDemo1},
  Zoomicon.Media.FMX.MediaDisplay in '..\Zoomicon.Media.FMX.MediaDisplay.pas',
  Zoomicon.Media.FMX.Models in '..\Zoomicon.Media.FMX.Models.pas',
  MediaPlayerDemo in 'Views\MediaPlayerDemo.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMediaDisplayDemo1, MediaDisplayDemo1);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
