object frmDebugInfo: TfrmDebugInfo
  Left = 0
  Top = 0
  ClientHeight = 480
  ClientWidth = 348
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object sgrdDebugInfo: TStringGrid
    Left = 0
    Top = 0
    Width = 348
    Height = 451
    Align = alClient
    ColCount = 4
    DefaultColWidth = 80
    DefaultRowHeight = 20
    FixedCols = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing]
    TabOrder = 0
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 451
    Width = 348
    Height = 29
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object btnRefresh: TButton
      AlignWithMargins = True
      Left = 271
      Top = 2
      Width = 75
      Height = 25
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alRight
      Caption = 'Refresh'
      TabOrder = 0
      OnClick = btnRefreshClick
    end
    object btnReset: TButton
      AlignWithMargins = True
      Left = 2
      Top = 2
      Width = 75
      Height = 25
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alLeft
      Caption = 'Reset'
      TabOrder = 1
      OnClick = btnResetClick
    end
  end
end
