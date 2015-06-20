object frSearchResultsItem: TfrSearchResultsItem
  Left = 0
  Top = 0
  Width = 451
  Height = 129
  Align = alTop
  AutoSize = True
  Color = clWhite
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  OnContextPopup = FrameContextPopup
  object Bevel1: TBevel
    AlignWithMargins = True
    Left = 3
    Top = 124
    Width = 445
    Height = 5
    Margins.Bottom = 0
    Align = alTop
    Shape = bsTopLine
  end
  object PanelCaption: TPanel
    Left = 0
    Top = 0
    Width = 451
    Height = 22
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 0
    object LabelCaption: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 7
      Height = 16
      Cursor = crHandPoint
      Align = alClient
      Caption = '_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      WordWrap = True
      OnClick = LabelCaptionClick
    end
    object TBXOperationsToolbar: TTBXToolbar
      Left = 427
      Top = 0
      Width = 23
      Height = 23
      ActivateParent = False
      Align = alRight
      AutoResize = False
      BorderStyle = bsNone
      DockableTo = []
      DockPos = 0
      DragHandleStyle = dhNone
      FloatingMode = fmOnTopOfAllForms
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Images = frmMain.MenusImageList
      ParentFont = False
      TabOrder = 0
      ChevronHint = ''
      object tbtmHide: TTBItem
        ImageIndex = 35
        OnClick = tbtmHideClick
        Caption = ''
        Hint = ''
      end
    end
  end
  object PanelDesc: TPanel
    Left = 0
    Top = 41
    Width = 451
    Height = 20
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 1
    object LabelDesc: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 6
      Height = 14
      Align = alTop
      Caption = '_'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      WordWrap = True
      OnDblClick = LabelDescDblClick
    end
  end
  object PanelFullDescImg: TPanel
    Left = 0
    Top = 61
    Width = 451
    Height = 40
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 2
    object LabelFullDescImg: TLabel
      AlignWithMargins = True
      Left = 376
      Top = 3
      Width = 72
      Height = 13
      Cursor = crHandPoint
      Align = alRight
      Alignment = taRightJustify
      Caption = 'Full Description'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsUnderline]
      ParentFont = False
      Layout = tlBottom
      WordWrap = True
      OnMouseUp = LabelFullDescImgMouseUp
    end
    object LabelMarkInfo: TLabel
      AlignWithMargins = True
      Left = 43
      Top = 3
      Width = 3
      Height = 14
      Cursor = crHandPoint
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGray
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      WordWrap = True
      OnClick = LabelCaptionClick
      OnDblClick = LabelDescDblClick
    end
    object imgIcon: TImage32
      Left = 0
      Top = 0
      Width = 40
      Height = 40
      Cursor = crHandPoint
      Align = alLeft
      AutoSize = True
      Bitmap.CombineMode = cmMerge
      Bitmap.ResamplerClassName = 'TLinearResampler'
      BitmapAlign = baCenter
      Color = clBtnFace
      ParentColor = False
      Scale = 1.000000000000000000
      ScaleMode = smOptimal
      TabOrder = 0
      Visible = False
      OnClick = LabelCaptionClick
      OnDblClick = LabelDescDblClick
    end
  end
  object PanelFullDescShort: TPanel
    Left = 0
    Top = 101
    Width = 451
    Height = 20
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 3
    object LabelFullDescShort: TLabel
      AlignWithMargins = True
      Left = 376
      Top = 3
      Width = 72
      Height = 13
      Cursor = crHandPoint
      Align = alRight
      Alignment = taRightJustify
      Caption = 'Full Description'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsUnderline]
      ParentFont = False
      Layout = tlBottom
      OnMouseUp = LabelFullDescImgMouseUp
    end
  end
  object PanelCategory: TPanel
    Left = 0
    Top = 22
    Width = 451
    Height = 19
    Align = alTop
    AutoSize = True
    BevelOuter = bvNone
    TabOrder = 4
    object LabelCategory: TLabel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 3
      Height = 13
      Cursor = crHandPoint
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
      WordWrap = True
      OnClick = LabelCaptionClick
    end
  end
end
