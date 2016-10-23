unit UDLight.Options;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TOptionsForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    cbTextColor: TColorBox;
    cbBackgroundColor: TColorBox;
    pnlPreview: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    procedure ChangeColor(Sender: TObject);
  private
    procedure UpdatePreview;
  end;

function ShowDLightOptions(var TextColor, BackgroundColor: TColor): Boolean;

implementation

{$R *.dfm}

function ShowDLightOptions(var TextColor, BackgroundColor: TColor): Boolean;
var
  form: TOptionsForm;
begin
  form := TOptionsForm.Create(nil);
  try
    form.cbTextColor.Selected := TextColor;
    form.cbBackgroundColor.Selected := BackgroundColor;
    form.UpdatePreview;

    Result := form.ShowModal = mrOk;
    if not Result then Exit;

    TextColor := form.cbTextColor.Selected;
    BackgroundColor := form.cbBackgroundColor.Selected;
  finally
    form.Free;
  end;
end;

{ TOptionsForm }

procedure TOptionsForm.ChangeColor(Sender: TObject);
begin
  UpdatePreview;
end;

procedure TOptionsForm.UpdatePreview;
begin
  pnlPreview.Font.Color := cbTextColor.Selected;
  pnlPreview.Color := cbBackgroundColor.Selected;
end;

end.
