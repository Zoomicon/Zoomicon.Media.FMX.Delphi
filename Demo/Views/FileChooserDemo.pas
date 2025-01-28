unit FileChooserDemo;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  Zoomicon.Media.FMX.FileChooser;

type
  TFileChooserDemo1 = class(TForm)
    FileChooser1: TFileChooser;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FileChooserDemo1: TFileChooserDemo1;

implementation
  uses
    System.IOUtils; //for TPath

{$R *.fmx}

procedure TFileChooserDemo1.FormCreate(Sender: TObject);
begin
  FileChooser1.FolderPath := TPath.GetDocumentsPath;
end;

end.
