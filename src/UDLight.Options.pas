unit UDLight.Options;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TOptionsFrame = class(TFrame)
    Label1: TLabel;
    Label2: TLabel;
    cbTextColor: TColorBox;
    cbBackgroundColor: TColorBox;
    pnlPreview: TPanel;
    procedure ChangeColor(Sender: TObject);
  public
    procedure UpdatePreview;
  end;

implementation

{$R *.dfm}

{ TOptionsFrame }

procedure TOptionsFrame.ChangeColor(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TOptionsFrame.UpdatePreview;
begin
  pnlPreview.Font.Color := cbTextColor.Selected;
  pnlPreview.Color := cbBackgroundColor.Selected;
end;

end.
