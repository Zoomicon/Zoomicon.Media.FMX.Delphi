unit MediaPlayerDemo;

//TODO: add fetch and play from stream (TMediaPlayerEx does via temp file)

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Media,
  Zoomicon.Media.FMX.MediaPlayerEx;

type
  TMediaPlayerDemo1 = class(TForm)
    MediaPlayerEx1: TMediaPlayerEx;
    MediaPlayerControl1: TMediaPlayerControl;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MediaPlayerDemo1: TMediaPlayerDemo1;

implementation

{$R *.fmx}

end.
