object FLogo: TFLogo
  Left = 269
  Top = 224
  AutoSize = True
  BorderStyle = bsNone
  Caption = 'Logo'
  ClientHeight = 276
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Image321: TImage32
    Left = 0
    Top = 0
    Width = 480
    Height = 276
    Align = alClient
    Bitmap.ResamplerClassName = 'TNearestResampler'
    BitmapAlign = baTopLeft
    Scale = 1.000000000000000000
    ScaleMode = smNormal
    TabOrder = 0
    OnClick = Image321Click
    object Label1: TLabel
      Left = 398
      Top = 249
      Width = 69
      Height = 13
      Alignment = taRightJustify
      AutoSize = False
      Color = clWhite
      ParentColor = False
      Transparent = True
    end
    object Label2: TLabel
      Left = 8
      Top = 254
      Width = 91
      Height = 16
      Caption = 'http://sasgis.ru'
      Font.Charset = RUSSIAN_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      Transparent = True
      Layout = tlCenter
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 8
    Top = 8
  end
end
