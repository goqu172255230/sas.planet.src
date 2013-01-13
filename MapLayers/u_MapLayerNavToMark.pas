unit u_MapLayerNavToMark;

interface

uses
  GR32,
  GR32_Image,
  i_Notifier,
  t_GeoTypes,
  i_NotifierOperation,
  i_LocalCoordConverter,
  i_LocalCoordConverterChangeable,
  i_InternalPerformanceCounter,
  i_NavigationToPoint,
  i_MapLayerNavToPointMarkerConfig,
  i_MarkerDrawable,
  u_MapLayerBasic;

type
  TNavToMarkLayer = class(TMapLayerBasicNoBitmap)
  private
    FConfig: IMapLayerNavToPointMarkerConfig;
    FNavToPoint: INavigationToPoint;
    FArrowMarkerChangeable: IMarkerDrawableWithDirectionChangeable;
    FReachedMarkerChangeable: IMarkerDrawableChangeable;

    FMarkPoint: TDoublePoint;
    procedure OnNavToPointChange;
    procedure OnConfigChange;
  protected
    procedure PaintLayer(
      ABuffer: TBitmap32;
      const ALocalConverter: ILocalCoordConverter
    ); override;
    procedure StartThreads; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const AView: ILocalCoordConverterChangeable;
      const ANavToPoint: INavigationToPoint;
      const AArrowMarkerChangeable: IMarkerDrawableWithDirectionChangeable;
      const AReachedMarkerChangeable: IMarkerDrawableChangeable;
      const AConfig: IMapLayerNavToPointMarkerConfig
    );
  end;

implementation

uses
  Math,
  i_CoordConverter,
  u_ListenerByEvent;

{ TNavToMarkLayer }

constructor TNavToMarkLayer.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier: INotifierOneOperation;
  const AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const AView: ILocalCoordConverterChangeable;
  const ANavToPoint: INavigationToPoint;
  const AArrowMarkerChangeable: IMarkerDrawableWithDirectionChangeable;
  const AReachedMarkerChangeable: IMarkerDrawableChangeable;
  const AConfig: IMapLayerNavToPointMarkerConfig
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier,
    AParentMap,
    AView
  );
  FNavToPoint := ANavToPoint;
  FArrowMarkerChangeable := AArrowMarkerChangeable;
  FReachedMarkerChangeable := AReachedMarkerChangeable;
  FConfig := AConfig;

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FArrowMarkerChangeable.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FReachedMarkerChangeable.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnNavToPointChange),
    FNavToPoint.GetChangeNotifier
  );
end;

procedure TNavToMarkLayer.OnConfigChange;
begin
  ViewUpdateLock;
  try
    SetNeedRedraw;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TNavToMarkLayer.OnNavToPointChange;
begin
  ViewUpdateLock;
  try
    SetNeedRedraw;
    FMarkPoint := FNavToPoint.LonLat;
    SetVisible(FNavToPoint.IsActive);
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TNavToMarkLayer.PaintLayer(
  ABuffer: TBitmap32;
  const ALocalConverter: ILocalCoordConverter
);
var
  VMarkMapPos: TDoublePoint;
  VScreenCenterMapPos: TDoublePoint;
  VDelta: TDoublePoint;
  VDeltaNormed: TDoublePoint;
  VZoom: Byte;
  VConverter: ICoordConverter;
  VCrossDist: Double;
  VDistInPixel: Double;
  VAngle: Double;
  VFixedOnView: TDoublePoint;
begin
  VConverter := ALocalConverter.GetGeoConverter;
  VZoom := ALocalConverter.GetZoom;
  VScreenCenterMapPos := ALocalConverter.GetCenterMapPixelFloat;
  VMarkMapPos := VConverter.LonLat2PixelPosFloat(FMarkPoint, VZoom);
  VDelta.X := VMarkMapPos.X - VScreenCenterMapPos.X;
  VDelta.Y := VMarkMapPos.Y - VScreenCenterMapPos.Y;
  VDistInPixel := Sqrt(Sqr(VDelta.X) + Sqr(VDelta.Y));
  VCrossDist := FConfig.CrossDistInPixels;
  if VDistInPixel < VCrossDist then begin
    VFixedOnView := ALocalConverter.LonLat2LocalPixelFloat(FMarkPoint);
    FReachedMarkerChangeable.GetStatic.DrawToBitmap(ABuffer, VFixedOnView);
  end else begin
    VDeltaNormed.X := VDelta.X / VDistInPixel * VCrossDist;
    VDeltaNormed.Y := VDelta.Y / VDistInPixel * VCrossDist;
    VMarkMapPos.X := VScreenCenterMapPos.X + VDeltaNormed.X;
    VMarkMapPos.Y := VScreenCenterMapPos.Y + VDeltaNormed.Y;
    VFixedOnView := ALocalConverter.MapPixelFloat2LocalPixelFloat(VMarkMapPos);
    VAngle := ArcSin(VDelta.X / VDistInPixel) / Pi * 180;
    if VDelta.Y > 0 then begin
      VAngle := 180 - VAngle;
    end;
    FArrowMarkerChangeable.GetStatic.DrawToBitmapWithDirection(ABuffer, VFixedOnView, VAngle);
  end;
end;

procedure TNavToMarkLayer.StartThreads;
begin
  inherited;
  OnNavToPointChange;
end;

end.
