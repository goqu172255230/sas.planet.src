unit u_MapGPSLayer;

interface

uses
  Types,
  GR32,
  GR32_Image,
  t_GeoTypes,
  i_IGPSRecorder,
  i_IMapLayerGPSTrackConfig,
  i_IViewPortState,
  u_MapLayerBasic;

type
  TMapGPSLayer = class(TMapLayerBasic)
  private
    FConfig: IMapLayerGPSTrackConfig;
    FGPSRecorder: IGPSRecorder;
    procedure DrawPath;
    procedure OnConfigChange(Sender: TObject);
  protected
    procedure DoRedraw; override;
  public
    procedure StartThreads; override;
  public
    constructor Create(
      AParentMap: TImage32;
      AViewPortState: IViewPortState;
      AConfig: IMapLayerGPSTrackConfig;
      AGPSRecorder: IGPSRecorder
    );
  end;

implementation

uses
  Graphics,
  SysUtils,
  GR32_Polygons,
  i_ILocalCoordConverter,
  u_NotifyEventListener;

{ TMapGPSLayer }

constructor TMapGPSLayer.Create(
  AParentMap: TImage32;
  AViewPortState: IViewPortState;
  AConfig: IMapLayerGPSTrackConfig;
  AGPSRecorder: IGPSRecorder
);
begin
  inherited Create(AParentMap, AViewPortState);
  FConfig := AConfig;
  FGPSRecorder := AGPSRecorder;
  LinksList.Add(
    TNotifyEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );
end;

procedure TMapGPSLayer.DrawPath;
var
  j, speed: integer;
  VPolygon: TPolygon32;
  VMapPointCurr: TDoublePoint;
  VMapPointPrev: TDoublePoint;
  VPointCurrIsEmpty: Boolean;
  VPointPrevIsEmpty: Boolean;
  VPointPrev: TDoublePoint;
  VPointCurr: TDoublePoint;
  VPointsCount: Integer;
  VSegmentColor: TColor32;
  VSpeed: Extended;
  VMaxSpeed: Extended;
  VPoints: TGPSTrackPointArray;
  VLocalConverter: ILocalCoordConverter;
  VLineWidth: Double;
  VIsChangePrevPoint: Boolean;
begin
  FConfig.LockRead;
  try
    VPointsCount := FConfig.LastPointCount;
    VLineWidth := FConfig.LineWidth;
  finally
    FConfig.UnlockRead
  end;
  VPoints := FGPSRecorder.LastPoints(VPointsCount);
  VLocalConverter := BitmapCoordConverter;
  VPointsCount := length(VPoints);
  with FLayer.Bitmap do begin
    if (VPointsCount > 1) then begin
      VMaxSpeed := VPoints[0].Speed;
      for j := 1 to VPointsCount - 1 do begin
        if VMaxSpeed < VPoints[j].Speed then begin
          VMaxSpeed := VPoints[j].Speed;
        end;
      end;

      VPolygon := TPolygon32.Create;
      try
        VPolygon.Antialiased := true;
        VPolygon.AntialiasMode := am4times;
        VPolygon.Closed := false;
        VMapPointPrev := VPoints[0].Point;
        VPointPrevIsEmpty := (VMapPointPrev.X = 0) and (VMapPointPrev.Y = 0);
        VPointPrev := VLocalConverter.LonLat2LocalPixelFloat(VMapPointPrev);
        for j := 1 to VPointsCount - 1 do begin
          VMapPointCurr := VPoints[j].Point;
          VPointCurrIsEmpty := (VMapPointCurr.X = 0) and (VMapPointCurr.Y = 0);
          if (not VPointCurrIsEmpty) and (not VPointPrevIsEmpty) then begin
            VPointCurr := VLocalConverter.LonLat2LocalPixelFloat(VMapPointCurr);
            if (abs(VPointPrev.X - VPointCurr.X) > 1) or (Abs(VPointPrev.Y - VPointCurr.Y) > 1) then begin
              if (VPointPrev.x < 32767) and (VPointPrev.x > -32767) and (VPointPrev.y < 32767) and (VPointPrev.y > -32767) then begin
                VPolygon.Add(FixedPoint(VPointPrev.X, VPointPrev.Y));
                VPolygon.Add(FixedPoint(VPointCurr.X, VPointCurr.Y));
                with VPolygon.Outline do try
                  with Grow(Fixed(VLineWidth / 2), 0.5) do try
                    VSpeed := VPoints[j - 1].Speed;
                    if (VMaxSpeed > 0) then begin
                      speed := round((255 * VSpeed) / VMaxSpeed);
                    end else begin
                      speed := 0;
                    end;
                    VSegmentColor := Color32(speed, 0, 256 - speed, 150);
                    DrawFill(FLayer.Bitmap, VSegmentColor);
                  finally
                    free;
                  end;
                finally
                  free;
                end;
                VPolygon.Clear;
              end;
              VIsChangePrevPoint := True;
            end else begin
              VIsChangePrevPoint := False;
            end;
          end else begin
            VIsChangePrevPoint := True;
          end;
          if VIsChangePrevPoint then begin
            VMapPointPrev := VMapPointCurr;
            VPointPrev := VPointCurr;
            VPointPrevIsEmpty := VPointCurrIsEmpty;
          end;
        end;
      finally
        VPolygon.Free;
      end;
    end;
  end;
end;

procedure TMapGPSLayer.OnConfigChange(Sender: TObject);
begin
  if FConfig.Visible then begin
    Redraw;
    Show;
  end else begin
    Hide;
  end;
end;

procedure TMapGPSLayer.StartThreads;
begin
  inherited;
  OnConfigChange(nil);
end;

procedure TMapGPSLayer.DoRedraw;
begin
  inherited;
  FLayer.Bitmap.Clear(clBlack);
  DrawPath;
end;

end.
