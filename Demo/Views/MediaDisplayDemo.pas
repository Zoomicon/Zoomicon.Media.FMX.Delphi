unit MediaDisplayDemo;

interface
  {$region 'Used units'}
  uses
    System.SysUtils,
    System.Types,
    System.UITypes,
    System.Classes,
    System.Variants,
    //
    FMX.Types,
    FMX.Controls,
    FMX.Forms,
    FMX.Graphics,
    FMX.Dialogs,
    FMX.Layouts,
    FMX.Memo.Types,
    FMX.Controls.Presentation,
    FMX.ScrollBox,
    FMX.Memo,
    //
    Zoomicon.Media.FMX.MediaDisplay;
  {$endregion}

type
  TMediaDisplayDemo1 = class(TForm)
    MediaDisplay1: TMediaDisplay;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MediaDisplayDemo1: TMediaDisplayDemo1;

implementation

{$R *.fmx}

end.
