unit u_MapLayerGPSMarkerRings;

interface

uses
  SysUtils,
  GR32,
  GR32_Image,
  t_GeoTypes,
  i_Notifier,
  i_NotifierOperation,
  i_Datum,
  i_ProjectionInfo,
  i_LocalCoordConverter,
  i_InternalPerformanceCounter,
  i_SimpleFlag,
  i_ProjectedDrawableElement,
  i_MarkerRingsConfig,
  i_VectorItemLonLat,
  i_VectorItemProjected,
  i_VectorItmesFactory,
  i_GPSRecorder,
  i_ViewPortState,
  u_MapLayerBasic;

type
  TMapLayerGPSMarkerRings = class(TMapLayerBasicNoBitmap)
  private
    FConfig: IMarkerRingsConfig;
    FGPSRecorder: IGPSRecorder;
    FVectorItemsFactory: IVectorItmesFactory;

    FGpsPosChangeFlag: ISimpleFlag;

    FGPSPosCS: IReadWriteSync;
    FGPSPosLonLat: TDoublePoint;
    FCirclesLonLat: ILonLatPolygon;
    FCirclesProjected: IProjectedDrawableElement;

    function GetLonLatCirclesByPoint(
      const APos: TDoublePoint;
      const ADatum: IDatum;
      const AConfig: IMarkerRingsConfigStatic
    ): ILonLatPolygon;
    function GetProjectedCirclesByLonLat(
      const ASource: ILonLatPolygon;
      const AProjectionInfo: IProjectionInfo
    ): IProjectedPolygon;
    procedure GPSReceiverReceive;
    procedure OnConfigChange;
    procedure OnTimer;
  protected
    procedure PaintLayer(
      ABuffer: TBitmap32;
      const ALocalConverter: ILocalCoordConverter
    ); override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const AViewPortState: IViewPortState;
      const ATimerNoifier: INotifier;
      const AVectorItemsFactory: IVectorItmesFactory;
      const AConfig: IMarkerRingsConfig;
      const AGPSRecorder: IGPSRecorder
    );
  end;

implementation

uses
  GR32_Polygons,
  vsagps_public_position,
  i_GPS,
  i_DoublePointsAggregator,
  u_GeoFun,
  u_Synchronizer,
  u_SimpleFlagWithInterlock,
  u_DoublePointsAggregator,
  u_ListenerByEvent,
  u_ProjectedDrawableElementByPolygon;

{ TMapLayerGPSMarkerRings }

constructor TMapLayerGPSMarkerRings.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier, AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const AViewPortState: IViewPortState;
  const ATimerNoifier: INotifier;
  const AVectorItemsFactory: IVectorItmesFactory;
  const AConfig: IMarkerRingsConfig;
  const AGPSRecorder: IGPSRecorder
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier,
    AParentMap,
    AViewPortState
  );
  FConfig := AConfig;
  FGPSRecorder := AGPSRecorder;
  FVectorItemsFactory := AVectorItemsFactory;

  FGpsPosChangeFlag := TSimpleFlagWithInterlock.Create;
  FGPSPosCS := MakeSyncRW_Var(Self, False);

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnTimer),
    ATimerNoifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.GPSReceiverReceive),
    FGPSRecorder.GetChangeNotifier
  );
end;

function TMapLayerGPSMarkerRings.GetLonLatCirclesByPoint(
  const APos: TDoublePoint;
  const ADatum: IDatum;
  const AConfig: IMarkerRingsConfigStatic
): ILonLatPolygon;
var
  VAggreagator: IDoublePointsAggregator;
  i, j: Integer;
  VDist: Double;
  VAngle: Double;
  VPoint: TDoublePoint;
begin
  VAggreagator := TDoublePointsAggregator.Create;
  for i := 1 to AConfig.Count do begin
    VDist := AConfig.StepDistance * i;
    for j := 0 to 64 do begin
      VAngle := j * 360 / 64;
      VPoint := ADatum.CalcFinishPosition(APos, VAngle, VDist);
      VAggreagator.Add(VPoint);
    end;
    VAggreagator.Add(CEmptyDoublePoint);
  end;
  Result := FVectorItemsFactory.CreateLonLatPolygon(VAggreagator.Points, VAggreagator.Count);
end;

function TMapLayerGPSMarkerRings.GetProjectedCirclesByLonLat(
  const ASource: ILonLatPolygon;
  const AProjectionInfo: IProjectionInfo): IProjectedPolygon;
begin
  Result := FVectorItemsFactory.CreateProjectedPolygonByLonLatPolygon(AProjectionInfo, ASource);
end;

procedure TMapLayerGPSMarkerRings.GPSReceiverReceive;
begin
  FGpsPosChangeFlag.SetFlag;
end;

procedure TMapLayerGPSMarkerRings.OnConfigChange;
begin
  ViewUpdateLock;
  try
    FGPSPosCS.BeginWrite;
    try
      FCirclesLonLat := nil;
      FCirclesProjected := nil;
    finally
      FGPSPosCS.EndWrite;
    end;
    SetNeedRedraw;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TMapLayerGPSMarkerRings.OnTimer;
var
  VGPSPosition: IGPSPosition;
  VpPos: PSingleGPSData;
  VLonLat: TDoublePoint;
begin
  if FGpsPosChangeFlag.CheckFlagAndReset then begin
    ViewUpdateLock;
    try
      VGPSPosition := FGPSRecorder.CurrentPosition;
      VpPos := VGPSPosition.GetPosParams;
      if (not VpPos^.PositionOK) then begin
        // no position
        Hide;
      end else begin
        // ok
        VLonLat.X := VpPos^.PositionLon;
        VLonLat.Y := VpPos^.PositionLat;
        FGPSPosCS.BeginWrite;
        try
          if not DoublePointsEqual(FGPSPosLonLat, VLonLat) then begin
            FGPSPosLonLat := VLonLat;
            FCirclesLonLat := nil;
            FCirclesProjected := nil;
            SetNeedRedraw;
          end;
        finally
          FGPSPosCS.EndWrite;
        end;
        Show;
      end;
    finally
      ViewUpdateUnlock;
    end;
  end;
end;

procedure TMapLayerGPSMarkerRings.PaintLayer(ABuffer: TBitmap32;
  const ALocalConverter: ILocalCoordConverter);
var
  VLonLat: TDoublePoint;
  VConfig: IMarkerRingsConfigStatic;
  VCirclesLonLat: ILonLatPolygon;
  VCirclesProjected: IProjectedPolygon;
  VDrawable: IProjectedDrawableElement;
begin
  inherited;
  VConfig := FConfig.GetStatic;
  if VConfig.Count <= 0 then begin
    Exit;
  end;

  FGPSPosCS.BeginRead;
  try
    VLonLat := FGPSPosLonLat;
    VCirclesLonLat := FCirclesLonLat;
    VDrawable := FCirclesProjected;
  finally
    FGPSPosCS.EndRead;
  end;
  if VDrawable <> nil then begin
    if not VDrawable.ProjectionInfo.GetIsSameProjectionInfo(ALocalConverter.ProjectionInfo) then  begin
      VDrawable := nil;
    end;
  end;
  if VCirclesLonLat = nil then begin
    VCirclesLonLat := GetLonLatCirclesByPoint(VLonLat, ALocalConverter.ProjectionInfo.GeoConverter.Datum, VConfig);
  end;
  if VCirclesLonLat = nil then begin
    Exit;
  end;
  FGPSPosCS.BeginWrite;
  try
    if DoublePointsEqual(VLonLat, FGPSPosLonLat) then begin
      FCirclesLonLat := VCirclesLonLat;
    end;
  finally
    FGPSPosCS.EndWrite
  end;
  if VDrawable = nil then begin
    VCirclesProjected := GetProjectedCirclesByLonLat(VCirclesLonLat, ALocalConverter.ProjectionInfo);
    VDrawable := TProjectedDrawableElementByPolygonSimpleEdge.Create(VCirclesProjected, amNone, clRed32);
  end;
  if VDrawable = nil then begin
    Exit;
  end;
  FGPSPosCS.BeginWrite;
  try
    if DoublePointsEqual(VLonLat, FGPSPosLonLat) then begin
      FCirclesProjected := VDrawable;
    end;
  finally
    FGPSPosCS.EndWrite
  end;
  VDrawable.Draw(ABuffer, ALocalConverter);
end;

end.
