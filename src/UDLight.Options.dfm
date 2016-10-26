object OptionsFrame: TOptionsFrame
  Left = 0
  Top = 0
  Width = 320
  Height = 240
  TabOrder = 0
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
end
