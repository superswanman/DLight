object OptionsForm: TOptionsForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'DLight Options'
  ClientHeight = 163
  ClientWidth = 173
  Color = clBtnFace
  ParentFont = True
  OldCreateOrder = False
  Position = poMainFormCenter
  Scaled = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 54
    Height = 13
    Caption = 'Text Color:'
  end
  object Label2: TLabel
    Left = 8
    Top = 55
    Width = 88
    Height = 13
    Caption = 'Background Color:'
  end
  object cbTextColor: TColorBox
    Left = 8
    Top = 27
    Width = 156
    Height = 22
    Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor]
    TabOrder = 0
    OnChange = ChangeColor
  end
  object cbBackgroundColor: TColorBox
    Left = 8
    Top = 74
    Width = 156
    Height = 22
    Style = [cbStandardColors, cbExtendedColors, cbSystemColors, cbCustomColor]
    TabOrder = 1
    OnChange = ChangeColor
  end
  object pnlPreview: TPanel
    Left = 8
    Top = 102
    Width = 156
    Height = 22
    BevelOuter = bvLowered
    Caption = 'I=12345'
    ParentBackground = False
    TabOrder = 2
  end
  object btnOk: TButton
    Left = 8
    Top = 130
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TButton
    Left = 89
    Top = 130
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
