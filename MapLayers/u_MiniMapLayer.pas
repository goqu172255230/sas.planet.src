unit u_MiniMapLayer;

interface

uses
  Windows,
  Classes,
  Graphics,
  Controls,
  TBX,
  TB2Item,
  GR32,
  GR32_Image,
  GR32_Layers,
  t_GeoTypes,
  i_MapTypes,
  i_MapTypeIconsList,
  i_ActiveMapsConfig,
  i_LocalCoordConverter,
  i_LocalCoordConverterFactorySimpe,
  i_ViewPortState,
  i_MiniMapLayerConfig,
  i_BitmapPostProcessingConfig,
  u_MapType,
  u_WindowLayerWithPos;

type
  TMiniMapLayer = class(TWindowLayerFixedSizeWithBitmap)
  private
    FConfig: IMiniMapLayerConfig;
    FParentMap: TImage32;
    FBitmapCoordConverterFactory: ILocalCoordConverterFactorySimpe;

    FPopup: TTBXPopupMenu;
    FIconsList: IMapTypeIconsList;
    FPlusButton: TBitmapLayer;
    FPlusButtonPressed: Boolean;
    FMinusButton: TBitmapLayer;
    FMinusButtonPressed: Boolean;
    FLeftBorder: TBitmapLayer;
    FLeftBorderMoved: Boolean;
    FLeftBorderMovedClickDelta: Double;
    FTopBorder: TBitmapLayer;
    FViewRectDrawLayer: TBitmapLayer;
    FPosMoved: Boolean;
    FViewRectMoveDelta: TDoublePoint;

    FBottomMargin: Integer;
    FUsePrevZoomAtMap: Boolean;
    FUsePrevZoomAtLayer: Boolean;
    FBackGroundColor: TColor32;

    procedure DrawMap(AMapType: TMapType; ADrawMode: TDrawMode);
    procedure DrawMainViewRect;

    procedure PlusButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure PlusButtonMouseUP(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure MinusButtonMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MinusButtonMouseUP(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

    procedure LeftBorderMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LeftBorderMouseUP(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LeftBorderMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);

    procedure LayerMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerMouseUP(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure LayerMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);


    function GetActualZoom(AVisualCoordConverter: ILocalCoordConverter): Byte;

    procedure BuildPopUpMenu;
    procedure BuildMapsListUI(AMapssSubMenu, ALayersSubMenu: TTBCustomItem);
    procedure CreateLayers(AParentMap: TImage32);
    procedure OnClickMapItem(Sender: TObject);
    procedure OnClickLayerItem(Sender: TObject);
    procedure OnConfigChange(Sender: TObject);
  protected
    function GetMapLayerLocationRect: TFloatRect; override;
    procedure DoShow; override;
    procedure DoHide; override;
    procedure DoRedraw; override;
    procedure DoUpdateLayerSize(ANewSize: TPoint); override;
    procedure DoUpdateLayerLocation(ANewLocation: TFloatRect); override;
    function GetLayerSizeForView(ANewVisualCoordConverter: ILocalCoordConverter): TPoint; override;
    function GetLayerCoordConverterByViewConverter(ANewVisualCoordConverter: ILocalCoordConverter): ILocalCoordConverter; override;
    procedure SetLayerCoordConverter(AValue: ILocalCoordConverter); override;
  public
    procedure StartThreads; override;
  public
    constructor Create(AParentMap: TImage32; AViewPortState: IViewPortState; AConfig: IMiniMapLayerConfig; APostProcessingConfig:IBitmapPostProcessingConfig);
    destructor Destroy; override;
    property BottomMargin: Integer read FBottomMargin write FBottomMargin;
  end;

implementation

uses
  ActiveX,
  SysUtils,
  Types,
  GR32_Polygons,
  c_ZeroGUID,
  i_CoordConverter,
  u_GeoFun,
  u_ResStrings,
  i_TileIterator,
  u_GlobalState,
  u_LocalCoordConverterFactorySimpe,
  u_NotifyEventListener,
  u_TileIteratorByRect,
  u_MapTypeMenuItemsGeneratorBasic;

{ TMapMainLayer }

constructor TMiniMapLayer.Create(AParentMap: TImage32; AViewPortState: IViewPortState; AConfig: IMiniMapLayerConfig; APostProcessingConfig:IBitmapPostProcessingConfig);
begin
  inherited Create(AParentMap, AViewPortState);
  FConfig := AConfig;
  FBitmapCoordConverterFactory := TLocalCoordConverterFactorySimpe.Create;
  FParentMap := AParentMap;
  FIconsList := GState.MapTypeIcons18List;

  FViewRectMoveDelta := DoublePoint(0, 0);

  FPopup := TTBXPopupMenu.Create(AParentMap);
  FPopup.Name := 'PopupMiniMap';
  FPopup.Images := FIconsList.GetImageList;

  CreateLayers(AParentMap);

  BuildPopUpMenu;
  LinksList.Add(
    TNotifyEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyEventListener.Create(Self.OnConfigChange),
    GState.ViewConfig.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyEventListener.Create(Self.OnConfigChange),
    APostProcessingConfig.GetChangeNotifier
  );
end;

destructor TMiniMapLayer.Destroy;
begin
  FBitmapCoordConverterFactory := nil;
  inherited;
end;

function TMiniMapLayer.GetLayerCoordConverterByViewConverter(
  ANewVisualCoordConverter: ILocalCoordConverter): ILocalCoordConverter;
var
  VVisualMapCenter: TDoublePoint;
  VZoom: Byte;
  VSourceZoom: Byte;
  VConverter: ICoordConverter;
  VVisualMapCenterInRelative: TDoublePoint;
  VVisualMapCenterInLayerMap: TDoublePoint;
  VLocalTopLeftAtMap: TDoublePoint;
  VLayerSize: TPoint;
begin
  VVisualMapCenter := ANewVisualCoordConverter.GetCenterMapPixelFloat;
  VSourceZoom := ANewVisualCoordConverter.GetZoom;
  VConverter := ANewVisualCoordConverter.GetGeoConverter;
  VVisualMapCenterInRelative := VConverter.PixelPosFloat2Relative(VVisualMapCenter, VSourceZoom);
  VZoom := GetActualZoom(ANewVisualCoordConverter);
  VVisualMapCenterInLayerMap := VConverter.Relative2PixelPosFloat(VVisualMapCenterInRelative, VZoom);
  VLayerSize := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
  VLocalTopLeftAtMap.X := Trunc(VVisualMapCenterInLayerMap.X - (VLayerSize.X / 2));
  VLocalTopLeftAtMap.Y := Trunc(VVisualMapCenterInLayerMap.Y - (VLayerSize.Y / 2));


  Result := FBitmapCoordConverterFactory.CreateConverter(
    Rect(0, 0, VLayerSize.X, VLayerSize.Y),
    VZoom,
    VConverter,
    DoublePoint(1, 1),
    VLocalTopLeftAtMap
  );
end;

function TMiniMapLayer.GetLayerSizeForView(
  ANewVisualCoordConverter: ILocalCoordConverter): TPoint;
var
  VWidth: Integer;
begin
  VWidth := FConfig.Width;
  Result := Point(VWidth, VWidth);
end;

procedure TMiniMapLayer.CreateLayers(AParentMap: TImage32);
begin
  FLeftBorder := TBitmapLayer.Create(AParentMap.Layers);
  FLeftBorder.Visible := False;
  FLeftBorder.MouseEvents := false;
  FLeftBorder.Cursor := crSizeNWSE;
  FLeftBorder.Bitmap.DrawMode := dmBlend;
  FLeftBorder.Bitmap.CombineMode := cmMerge;
  FLeftBorder.OnMouseDown := LeftBorderMouseDown;
  FLeftBorder.OnMouseUp := LeftBorderMouseUP;
  FLeftBorder.OnMouseMove := LeftBorderMouseMove;
  FLeftBorderMoved := False;

  FTopBorder := TBitmapLayer.Create(AParentMap.Layers);
  FTopBorder.Visible := False;
  FTopBorder.MouseEvents := false;
  FTopBorder.Bitmap.DrawMode := dmBlend;
  FTopBorder.Bitmap.CombineMode := cmMerge;

  FViewRectDrawLayer := TBitmapLayer.Create(AParentMap.Layers);
  FViewRectDrawLayer.Visible := False;
  FViewRectDrawLayer.MouseEvents := false;
  FViewRectDrawLayer.Bitmap.DrawMode := dmBlend;
  FViewRectDrawLayer.Bitmap.CombineMode := cmMerge;
  FViewRectDrawLayer.OnMouseDown := LayerMouseDown;
  FViewRectDrawLayer.OnMouseUp := LayerMouseUP;
  FViewRectDrawLayer.OnMouseMove := LayerMouseMove;

  FPlusButton := TBitmapLayer.Create(AParentMap.Layers);
  FPlusButton.Visible := False;
  FPlusButton.MouseEvents := false;
  FPlusButton.Bitmap.DrawMode := dmBlend;
  FPlusButton.Bitmap.CombineMode := cmMerge;
  FPlusButton.OnMouseDown := PlusButtonMouseDown;
  FPlusButton.OnMouseUp := PlusButtonMouseUP;
  FPlusButton.Cursor := crHandPoint;
  FPlusButtonPressed := False;

  FMinusButton := TBitmapLayer.Create(AParentMap.Layers);
  FMinusButton.Visible := False;
  FMinusButton.MouseEvents := false;
  FMinusButton.Bitmap.DrawMode := dmBlend;
  FMinusButton.Bitmap.CombineMode := cmMerge;
  FMinusButton.OnMouseDown := MinusButtonMouseDown;
  FMinusButton.OnMouseUp := MinusButtonMouseUP;
  FMinusButton.Cursor := crHandPoint;
  FMinusButtonPressed := False;
end;

procedure TMiniMapLayer.BuildPopUpMenu;
var
  VSubMenuItem: TTBXSubmenuItem;
  VLayersSubMenu: TTBXSubmenuItem;
begin
  VSubMenuItem := TTBXSubmenuItem.Create(FPopup);
  VSubMenuItem.Name := 'MiniMapLayers';
  VSubMenuItem.Caption := SAS_STR_Layers;
  VSubMenuItem.Hint := '';
  VSubMenuItem.SubMenuImages := FPopup.Images;
  FPopup.Items.Add(VSubMenuItem);
  VLayersSubMenu := VSubMenuItem;

  BuildMapsListUI(FPopup.Items, VLayersSubMenu);
end;

procedure TMiniMapLayer.BuildMapsListUI(AMapssSubMenu, ALayersSubMenu: TTBCustomItem);
var
  VGenerator: TMapMenuGeneratorBasic;
begin
  VGenerator := TMapMenuGeneratorBasic.Create(
    FConfig.MapsConfig.GetMapsSet,
    AMapssSubMenu,
    Self.OnClickMapItem,
    FIconsList,
    false
  );
  try
    VGenerator.BuildControls;
  finally
    FreeAndNil(VGenerator);
  end;
  VGenerator := TMapMenuGeneratorBasic.Create(
    FConfig.MapsConfig.GetLayers,
    ALayersSubMenu,
    Self.OnClickLayerItem,
    FIconsList,
    false
  );
  try
   VGenerator.BuildControls;
  finally
    FreeAndNil(VGenerator);
  end;
end;

procedure TMiniMapLayer.DoRedraw;
var
  i: Cardinal;
  VMapType: TMapType;
  VActiveMaps: IMapTypeList;
  VGUID: TGUID;
  VItem: IMapType;
  VEnum: IEnumGUID;
begin
  inherited;
  FLayer.Bitmap.Clear(FBackGroundColor);
  VMapType := FConfig.MapsConfig.GetActiveMiniMap.MapType;
  VActiveMaps := FConfig.MapsConfig.GetLayers.GetSelectedMapsList;

  DrawMap(VMapType, dmOpaque);
  VEnum := VActiveMaps.GetIterator;
  while VEnum.Next(1, VGUID, i) = S_OK do begin
    VItem := VActiveMaps.GetMapTypeByGUID(VGUID);
    VMapType := VItem.GetMapType;
    DrawMap(VMapType, dmBlend);
  end;
  DrawMainViewRect;
end;

procedure TMiniMapLayer.DrawMainViewRect;
var
  {
    ������������� �������� ������ � ����������� ������� �������� �����
  }
  VLoadedRect: TDoubleRect;
  VZoomSource: Byte;
  VZoom: Byte;
  VMiniMapRect: TDoubleRect;
  VBitmapRect: TDoubleRect;
  VRelRect: TDoubleRect;
  VPolygon: TPolygon32;
  VBitmapSize: TPoint;
  VVisualCoordConverter: ILocalCoordConverter;
  VBitmapCoordConverter: ILocalCoordConverter;
  VGeoConvert: ICoordConverter;
  VZoomDelta: Integer;
begin
  FViewRectDrawLayer.Bitmap.Clear(clBlack);
  VVisualCoordConverter := ViewCoordConverter;
  VBitmapCoordConverter := LayerCoordConverter;
  if (VVisualCoordConverter <> nil) and (VBitmapCoordConverter <> nil) then begin
    VGeoConvert := VVisualCoordConverter.GetGeoConverter;
    VZoomDelta := FConfig.ZoomDelta;
    if VZoomDelta > 0 then begin
      VLoadedRect := VVisualCoordConverter.GetRectInMapPixelFloat;
      VZoomSource := VBitmapCoordConverter.GetZoom;
      VZoom := VVisualCoordConverter.GetZoom;
      VGeoConvert.CheckPixelRectFloat(VLoadedRect, VZoom);
      VRelRect := VGeoConvert.PixelRectFloat2RelativeRect(VLoadedRect, VZoom);
      VMiniMapRect := VGeoConvert.RelativeRect2PixelRectFloat(VRelRect, VZoomSource);
      VBitmapRect := VBitmapCoordConverter.MapRectFloat2LocalRectFloat(VMiniMapRect);
      VBitmapRect.Left := VBitmapRect.Left + FViewRectMoveDelta.X;
      VBitmapRect.Top := VBitmapRect.Top + FViewRectMoveDelta.Y;
      VBitmapRect.Right := VBitmapRect.Right + FViewRectMoveDelta.X;
      VBitmapRect.Bottom := VBitmapRect.Bottom + FViewRectMoveDelta.Y;

      VBitmapSize := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
      if (VBitmapRect.Left >= 0) or (VBitmapRect.Top >= 0)
        or (VBitmapRect.Right <= VBitmapSize.X)
        or (VBitmapRect.Bottom <= VBitmapSize.Y)
      then begin
        VPolygon := TPolygon32.Create;
        try
          VPolygon.Antialiased := true;
          VPolygon.Add(FixedPoint(VBitmapRect.Left, VBitmapRect.Top));
          VPolygon.Add(FixedPoint(VBitmapRect.Right, VBitmapRect.Top));
          VPolygon.Add(FixedPoint(VBitmapRect.Right, VBitmapRect.Bottom));
          VPolygon.Add(FixedPoint(VBitmapRect.Left, VBitmapRect.Bottom));
          with VPolygon.Outline do try
            with Grow(Fixed(3.2 / 2), 0.5) do try
              FillMode := pfWinding;
              DrawFill(FViewRectDrawLayer.Bitmap, SetAlpha(clNavy32, (VZoomDelta)*43));
            finally
              Free;
            end;
          finally
            Free;
          end;
          VPolygon.DrawFill(FViewRectDrawLayer.Bitmap, SetAlpha(clWhite32, (VZoomDelta) * 35));
        finally
          VPolygon.Free;
        end;
      end;
    end;
  end;
end;

procedure TMiniMapLayer.DrawMap(AMapType: TMapType; ADrawMode: TDrawMode);
var
  VZoom: Byte;
  VBmp: TCustomBitmap32;

  { ������������� �������� ������ � ����������� ��������� ���������� }
  VBitmapOnMapPixelRect: TRect;
  { ������������� ������ �������� ����, ����������� �����, � ������������
    ��������� ���������� }
  VTileSourceRect: TRect;
  { ������� ���� � ������������ ��������� ���������� }
  VTile: TPoint;
  { ������������� ������� �������� ����� � ������������ ��������� ���������� }
  VCurrTilePixelRect: TRect;
  { ������������� ����� ���������� ����������� �� ������� ����� }
  VTilePixelsToDraw: TRect;
  { ������������� �������� � ������� ����� ���������� ������� ���� }
  VCurrTileOnBitmapRect: TRect;

  VGeoConvert: ICoordConverter;
  VUsePre: Boolean;
  VBitmapConverter: ILocalCoordConverter;
  VTileIterator: ITileIterator;
  VRecolorConfig: IBitmapPostProcessingConfigStatic;
begin
  if AMapType.asLayer then begin
    VUsePre := FUsePrevZoomAtLayer;
  end else begin
    VUsePre := FUsePrevZoomAtMap;
  end;
  VRecolorConfig := GState.BitmapPostProcessingConfig.GetStatic;

  VBitmapConverter := LayerCoordConverter;
  VGeoConvert := VBitmapConverter.GetGeoConverter;
  VZoom := VBitmapConverter.GetZoom;

  VBitmapOnMapPixelRect := VBitmapConverter.GetRectInMapPixel;
  VGeoConvert.CheckPixelRect(VBitmapOnMapPixelRect, VZoom);

  VTileSourceRect := VGeoConvert.PixelRect2TileRect(VBitmapOnMapPixelRect, VZoom);
  VTileIterator := TTileIteratorByRect.Create(VTileSourceRect);
  VBitmapOnMapPixelRect := VBitmapConverter.GetRectInMapPixel;

  VBmp := TCustomBitmap32.Create;
  try
    while VTileIterator.Next(VTile) do begin
        VCurrTilePixelRect := VGeoConvert.TilePos2PixelRect(VTile, VZoom);

        VTilePixelsToDraw.TopLeft := Point(0, 0);
        VTilePixelsToDraw.Right := VCurrTilePixelRect.Right - VCurrTilePixelRect.Left;
        VTilePixelsToDraw.Bottom := VCurrTilePixelRect.Bottom - VCurrTilePixelRect.Top;

        if VCurrTilePixelRect.Left < VBitmapOnMapPixelRect.Left then begin
          VTilePixelsToDraw.Left := VBitmapOnMapPixelRect.Left - VCurrTilePixelRect.Left;
          VCurrTilePixelRect.Left := VBitmapOnMapPixelRect.Left;
        end;

        if VCurrTilePixelRect.Top < VBitmapOnMapPixelRect.Top then begin
          VTilePixelsToDraw.Top := VBitmapOnMapPixelRect.Top - VCurrTilePixelRect.Top;
          VCurrTilePixelRect.Top := VBitmapOnMapPixelRect.Top;
        end;

        if VCurrTilePixelRect.Right > VBitmapOnMapPixelRect.Right then begin
          VTilePixelsToDraw.Right := VTilePixelsToDraw.Right - (VCurrTilePixelRect.Right - VBitmapOnMapPixelRect.Right);
          VCurrTilePixelRect.Right := VBitmapOnMapPixelRect.Right;
        end;

        if VCurrTilePixelRect.Bottom > VBitmapOnMapPixelRect.Bottom then begin
          VTilePixelsToDraw.Bottom := VTilePixelsToDraw.Bottom - (VCurrTilePixelRect.Bottom - VBitmapOnMapPixelRect.Bottom);
          VCurrTilePixelRect.Bottom := VBitmapOnMapPixelRect.Bottom;
        end;
        VCurrTileOnBitmapRect.TopLeft := VBitmapConverter.MapPixel2LocalPixel(VCurrTilePixelRect.TopLeft);
        VCurrTileOnBitmapRect.BottomRight := VBitmapConverter.MapPixel2LocalPixel(VCurrTilePixelRect.BottomRight);
        if AMapType.LoadTileUni(VBmp, VTile, VZoom, true, VGeoConvert, VUsePre, True, True) then begin
          VRecolorConfig.ProcessBitmap(VBmp);
          FLayer.Bitmap.Lock;
          try
            VBmp.DrawMode := ADrawMode;
            Assert(VCurrTileOnBitmapRect.Right - VCurrTileOnBitmapRect.Left = VTilePixelsToDraw.Right - VTilePixelsToDraw.Left);
            Assert(VCurrTileOnBitmapRect.Bottom - VCurrTileOnBitmapRect.Top = VTilePixelsToDraw.Bottom - VTilePixelsToDraw.Top);
            FLayer.Bitmap.Draw(VCurrTileOnBitmapRect, VTilePixelsToDraw, Vbmp);
          finally
            FLayer.Bitmap.UnLock;
          end;
        end;
    end;
  finally
    VBmp.Free;
  end;
end;

function TMiniMapLayer.GetActualZoom(AVisualCoordConverter: ILocalCoordConverter): Byte;
var
  VZoom: Byte;
  VGeoConvert: ICoordConverter;
  VZoomDelta: Integer;
begin
  VZoom := AVisualCoordConverter.GetZoom;
  VGeoConvert := AVisualCoordConverter.GetGeoConverter;
  VZoomDelta := FConfig.ZoomDelta;
  if VZoomDelta = 0 then begin
    Result := VZoom;
  end else if VZoomDelta > 0 then begin
    if VZoom > VZoomDelta then begin
      Result := VZoom - VZoomDelta;
    end else begin
      Result := 0;
    end;
  end else begin
    Result := VZoom - VZoomDelta;
    VGeoConvert.CheckZoom(Result);
  end;
end;

function TMiniMapLayer.GetMapLayerLocationRect: TFloatRect;
var
  VSize: TPoint;
  VViewSize: TPoint;
begin
  VSize := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
  VViewSize := ViewCoordConverter.GetLocalRectSize;
  Result.Right := VViewSize.X;
  Result.Bottom := VViewSize.Y - FBottomMargin;
  Result.Left := Result.Right - VSize.X;
  Result.Top := Result.Bottom - VSize.Y;
end;

procedure TMiniMapLayer.DoHide;
begin
  inherited;
  FViewRectDrawLayer.Visible := false;
  FViewRectDrawLayer.MouseEvents := false;

  FLeftBorder.Visible := False;
  FLeftBorder.MouseEvents := false;

  FTopBorder.Visible := False;

  FPlusButton.Visible := False;
  FPlusButton.MouseEvents := false;

  FMinusButton.Visible := False;
  FMinusButton.MouseEvents := false;
end;

procedure TMiniMapLayer.LayerMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  VLayerSize: TPoint;
  VBitmapCenter: TDoublePoint;
  VVisibleCenter: TDoublePoint;
  Vlocation: TFloatRect;
begin
  FParentMap.PopupMenu := nil;
  case button of
    mbRight: FParentMap.PopupMenu := FPopup;
    mbLeft: begin
      VLayerSize := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
      VBitmapCenter := DoublePoint(VLayerSize.X / 2, VLayerSize.Y / 2);
      Vlocation := FLayer.Location;
      VVisibleCenter.X := VBitmapCenter.X + Vlocation.Left;
      VVisibleCenter.Y := VBitmapCenter.Y + Vlocation.Top;
      FPosMoved := True;
      FViewRectMoveDelta := DoublePoint(X - VVisibleCenter.X, Y - VVisibleCenter.Y);
      DrawMainViewRect;
    end;
  end;
end;

procedure TMiniMapLayer.LayerMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  VBitmapSize: TPoint;
  VBitmapCenter: TDoublePoint;
  VVisibleCenter: TDoublePoint;
  VLocation: TFloatRect;
begin
  if FPosMoved then begin
    VBitmapSize := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
    VBitmapCenter := DoublePoint(VBitmapSize.X / 2, VBitmapSize.Y / 2);

    VLocation := FLayer.Location;

    VVisibleCenter.X := VLocation.Left + VBitmapCenter.X;
    VVisibleCenter.Y := VLocation.Top + VBitmapCenter.Y;

    if X < VLocation.Left then begin
      FViewRectMoveDelta.X := VLocation.Left - VVisibleCenter.X;
    end else if X > VLocation.Right then begin
      FViewRectMoveDelta.X := VLocation.Right - VVisibleCenter.X;
    end else begin
      FViewRectMoveDelta.X := X - VVisibleCenter.X;
    end;
    if Y < VLocation.Top then begin
      FViewRectMoveDelta.Y := VLocation.Top - VVisibleCenter.Y;
    end else if Y > VLocation.Bottom then begin
      FViewRectMoveDelta.Y := VLocation.Bottom - VVisibleCenter.Y;
    end else begin
      FViewRectMoveDelta.Y := Y - VVisibleCenter.Y;
    end;

    DrawMainViewRect;
  end;
end;

procedure TMiniMapLayer.LayerMouseUP(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  VBitmapCoordConverter: ILocalCoordConverter;
  VConverter: ICoordConverter;
  VZoom: Byte;
  VBitmapPos: TDoublePoint;
  Vlocation: TFloatRect;
  VMapPoint: TDoublePoint;
  VLonLat: TDoublePoint;
begin
  if FPosMoved then begin
    if FLayer.HitTest(X, Y) then begin
      VBitmapCoordConverter := LayerCoordConverter;
      Vlocation := FLayer.Location;
      VBitmapPos.X := X - Vlocation.Left;
      VBitmapPos.Y := Y - Vlocation.Top;
      VConverter := VBitmapCoordConverter.GetGeoConverter;
      VZoom := VBitmapCoordConverter.GetZoom;

      VMapPoint := VBitmapCoordConverter.LocalPixelFloat2MapPixelFloat(VBitmapPos);
      VConverter.CheckPixelPosFloatStrict(VMapPoint, VZoom, false);
      VLonLat := VConverter.PixelPosFloat2LonLat(VMapPoint, VZoom);
      FViewRectMoveDelta := DoublePoint(0, 0);

      ViewPortState.ChangeLonLat(VLonLat);
    end else begin
      FViewRectMoveDelta := DoublePoint(0, 0);
      DrawMainViewRect;
    end;
  end;
  FPosMoved := False;
end;

procedure TMiniMapLayer.LeftBorderMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    FLeftBorderMoved := true;
    FLeftBorderMovedClickDelta := FLayer.Location.Left - X;
  end;
end;

procedure TMiniMapLayer.LeftBorderMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  VNewWidth: Integer;
  VVisibleSize: TPoint;
begin
  if FLeftBorderMoved then begin
    VVisibleSize := ViewCoordConverter.GetLocalRectSize;
    VNewWidth := Trunc(FLayer.Location.Right - X - FLeftBorderMovedClickDelta);
    if VNewWidth < 40 then begin
      VNewWidth := 40;
    end;
    if VNewWidth > VVisibleSize.X then begin
      VNewWidth := VVisibleSize.X;
    end;
    if VNewWidth > VVisibleSize.Y then begin
      VNewWidth := VVisibleSize.Y;
    end;
    FConfig.Width := VNewWidth;
  end;
end;

procedure TMiniMapLayer.LeftBorderMouseUP(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FLeftBorderMoved then begin
    SetNeedRedraw;
    FLeftBorderMoved := False;
    ViewUpdate;
  end;
end;

procedure TMiniMapLayer.MinusButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    FMinusButtonPressed := True;
  end;
end;

procedure TMiniMapLayer.MinusButtonMouseUP(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    if FMinusButtonPressed then begin
      FMinusButtonPressed := False;
      if FMinusButton.HitTest(X, Y) then begin
        FConfig.LockWrite;
        try
          FConfig.ZoomDelta := FConfig.ZoomDelta + 1;
        finally
          FConfig.UnlockWrite;
        end;
      end;
    end;
  end;
end;

procedure TMiniMapLayer.OnClickLayerItem(Sender: TObject);
var
  VSender: TTBCustomItem;
  VAtiveMap: IActiveMapSingle;
  VMap: IMapType;
begin
  if Sender is TTBCustomItem then begin
    VSender := TTBCustomItem(Sender);
    VAtiveMap := IActiveMapSingle(VSender.Tag);
    if VAtiveMap <> nil then begin
      VMap := VAtiveMap.GetMapType;
      if VMap <> nil then begin
        FConfig.MapsConfig.LockWrite;
        try
          if not FConfig.MapsConfig.GetLayers.IsGUIDSelected(VMap.GUID) then begin
            FConfig.MapsConfig.SelectLayerByGUID(VMap.GUID);
          end else begin
            FConfig.MapsConfig.UnSelectLayerByGUID(VMap.GUID);
          end;
        finally
          FConfig.MapsConfig.UnlockWrite;
        end;
      end;
    end;
  end;
end;

procedure TMiniMapLayer.OnClickMapItem(Sender: TObject);
var
  VSender: TComponent;
  VAtiveMap: IActiveMapSingle;
  VMap: IMapType;
begin
  if Sender is TComponent then begin
    VSender := TComponent(Sender);
    VAtiveMap := IActiveMapSingle(VSender.Tag);
    if VAtiveMap <> nil then begin
      VMap := VAtiveMap.GetMapType;
      if VMap <> nil then begin
        FConfig.MapsConfig.SelectMainByGUID(VMap.GUID);
      end else begin
        FConfig.MapsConfig.SelectMainByGUID(CGUID_Zero);
      end;
    end;
  end;
end;

procedure TMiniMapLayer.OnConfigChange(Sender: TObject);
begin
  ViewUpdateLock;
  try
  GState.ViewConfig.LockRead;
  try
    FBackGroundColor := Color32(GState.ViewConfig.BackGroundColor);
    FUsePrevZoomAtMap := GState.ViewConfig.UsePrevZoomAtMap;
    FUsePrevZoomAtLayer := GState.ViewConfig.UsePrevZoomAtLayer;
  finally
    GState.ViewConfig.UnlockRead;
  end;
  FConfig.LockRead;
  try
    FPlusButton.Bitmap.Assign(FConfig.PlusButton);
    FPlusButton.Bitmap.DrawMode := dmTransparent;
    FMinusButton.Bitmap.Assign(FConfig.MinusButton);
    FMinusButton.Bitmap.DrawMode := dmTransparent;

    FMinusButton.Bitmap.MasterAlpha := FConfig.MasterAlpha;
    FPlusButton.Bitmap.MasterAlpha := FConfig.MasterAlpha;
    FTopBorder.Bitmap.MasterAlpha := FConfig.MasterAlpha;
    FLeftBorder.Bitmap.MasterAlpha := FConfig.MasterAlpha;
    FLayer.Bitmap.MasterAlpha := FConfig.MasterAlpha;
    SetVisible(FConfig.Visible);
    SetNeedRedraw;
    SetNeedUpdateLayerSize;
  finally
    FConfig.UnlockRead;
  end;
  finally
    ViewUpdateUnlock;
  end;
  ViewUpdate;
end;

procedure TMiniMapLayer.PlusButtonMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    FPlusButtonPressed := True;
  end;
end;

procedure TMiniMapLayer.PlusButtonMouseUP(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    if FPlusButtonPressed then begin
      if FPlusButton.HitTest(X, Y) then begin
        FConfig.LockWrite;
        try
          FConfig.ZoomDelta := FConfig.ZoomDelta - 1;
        finally
          FConfig.UnlockWrite;
        end;
      end;
      FPlusButtonPressed := False;
    end;
  end;
end;

procedure TMiniMapLayer.SetLayerCoordConverter(AValue: ILocalCoordConverter);
var
  VNewSize: TPoint;
begin
  VNewSize := GetLayerSizeForView(AValue);
  FLayer.Bitmap.Lock;
  try
    if (FLayer.Bitmap.Width <> VNewSize.X) or (FLayer.Bitmap.Height <> VNewSize.Y) then begin
      SetNeedUpdateLayerSize;
    end;
  finally
    FLayer.Bitmap.Unlock;
  end;

  if (LayerCoordConverter = nil) or (not LayerCoordConverter.GetIsSameConverter(AValue)) then begin
    SetNeedRedraw;
  end;
  inherited;
end;

procedure TMiniMapLayer.StartThreads;
begin
  inherited;
  OnConfigChange(nil);
end;

procedure TMiniMapLayer.DoShow;
begin
  inherited;
  FViewRectDrawLayer.Visible := True;
  FViewRectDrawLayer.MouseEvents := True;

  FLeftBorder.Visible := True;
  FLeftBorder.MouseEvents := True;

  FTopBorder.Visible := True;

  FPlusButton.Visible := True;
  FPlusButton.MouseEvents := True;

  FMinusButton.Visible := True;
  FMinusButton.MouseEvents := True;
end;

procedure TMiniMapLayer.DoUpdateLayerLocation(ANewLocation: TFloatRect);
var
  VRect: TFloatRect;
begin
  inherited;
  FViewRectDrawLayer.Location := ANewLocation;

  VRect.Left := ANewLocation.Left - 5;
  VRect.Top := ANewLocation.Top - 5;
  VRect.Right := ANewLocation.Left;
  VRect.Bottom := ANewLocation.Bottom;
  FLeftBorder.Location := VRect;

  VRect.Left := ANewLocation.Left;
  VRect.Top := ANewLocation.Top - 5;
  VRect.Right := ANewLocation.Right;
  VRect.Bottom := ANewLocation.Top;
  FTopBorder.Location := VRect;

  VRect.Left := ANewLocation.Left + 6;
  VRect.Top := ANewLocation.Top + 6;
  VRect.Right := VRect.Left + FPlusButton.Bitmap.Width;
  VRect.Bottom := VRect.Top + FPlusButton.Bitmap.Height;
  FPlusButton.Location := VRect;

  VRect.Left := ANewLocation.Left + 19;
  VRect.Top := ANewLocation.Top + 6;
  VRect.Right := VRect.Left + FMinusButton.Bitmap.Width;
  VRect.Bottom := VRect.Top + FMinusButton.Bitmap.Height;
  FMinusButton.Location := VRect;
end;

procedure TMiniMapLayer.DoUpdateLayerSize(ANewSize: TPoint);
var
  VBitmapSizeInPixel: TPoint;
  VBorderWidth: Integer;
begin
  inherited;
  VBorderWidth := 5;
  VBitmapSizeInPixel := Point(FLayer.Bitmap.Width, FLayer.Bitmap.Height);
  FViewRectDrawLayer.Bitmap.SetSize(VBitmapSizeInPixel.X, VBitmapSizeInPixel.Y);
  if (FLeftBorder.Bitmap.Height <> VBitmapSizeInPixel.Y + VBorderWidth) then begin
    FLeftBorder.Bitmap.Lock;
    try
      FLeftBorder.Bitmap.SetSize(VBorderWidth, VBitmapSizeInPixel.Y + VBorderWidth);
      FLeftBorder.Bitmap.Clear(clLightGray32);
      FLeftBorder.Bitmap.VertLineS(0, 0, VBitmapSizeInPixel.Y + VBorderWidth - 1, clBlack32);
      FLeftBorder.Bitmap.VertLineS(VBorderWidth - 1, VBorderWidth - 1, VBitmapSizeInPixel.Y + VBorderWidth - 1, clBlack32);
      FLeftBorder.Bitmap.HorzLineS(0, 0, VBorderWidth - 1, clBlack32);
      FLeftBorder.bitmap.Pixel[2, VBorderWidth + (VBitmapSizeInPixel.Y div 2) - 6] := clBlack;
      FLeftBorder.bitmap.Pixel[2, VBorderWidth + (VBitmapSizeInPixel.Y div 2) - 2] := clBlack;
      FLeftBorder.bitmap.Pixel[2, VBorderWidth + (VBitmapSizeInPixel.Y div 2) + 2] := clBlack;
      FLeftBorder.bitmap.Pixel[2, VBorderWidth + (VBitmapSizeInPixel.Y div 2) + 6] := clBlack;
    finally
      FLeftBorder.Bitmap.Unlock;
    end;
  end;
  if (FTopBorder.Bitmap.Width <> VBitmapSizeInPixel.X) then begin
    FTopBorder.Bitmap.Lock;
    try
      FTopBorder.Bitmap.SetSize(VBitmapSizeInPixel.X, VBorderWidth);
      FTopBorder.Bitmap.Clear(clLightGray32);
      FTopBorder.Bitmap.HorzLineS(0, 0, VBitmapSizeInPixel.X, clBlack32);
      FTopBorder.Bitmap.HorzLineS(0, VBorderWidth - 1, VBitmapSizeInPixel.X, clBlack32);
    finally
      FTopBorder.Bitmap.Unlock;
    end;
  end;
end;

end.


