unit u_SelectionLayer;

interface

uses
  Types,
  GR32,
  GR32_Image,
  i_JclNotify,
  t_GeoTypes,
  i_IConfigDataProvider,
  i_IConfigDataWriteProvider,
  u_MapViewPortState,
  u_MapLayerScaledBase;

type
  TSelectionLayer = class(TMapLayerScaledBase)
  protected
    FColor: TColor32;
    FPolygon: TExtendedPointArray;
    FSelectionChangeListener: IJclListener;
    procedure DoRedraw; override;
    function GetVisibleRectInMapPixels: TRect; override;
    procedure PaintLayer(Sender: TObject; Buffer: TBitmap32);
    function LonLatArrayToVisualFloatArray(APolygon: TExtendedPointArray): TExtendedPointArray;
    procedure ChangeSelection(Sender: TObject);
  public
    constructor Create(AParentMap: TImage32; AViewPortState: TMapViewPortState);
    destructor Destroy; override;
    procedure LoadConfig(AConfigProvider: IConfigDataProvider); override;
    procedure SaveConfig(AConfigProvider: IConfigDataWriteProvider); override;
  end;


implementation

uses
  Classes,
  GR32_PolygonsEx,
  GR32_VPR,
  GR32_VectorUtils,
  u_JclNotify,
  i_ICoordConverter,
  u_GlobalState,
  Ugeofun;

{ TSelectionChangeListener }

type
  TSelectionChangeListener = class(TJclBaseListener)
  private
    FEvent: TNotifyEvent;
  protected
    procedure Notification(msg: IJclNotificationMessage); override;
  public
    constructor Create(AEvent: TNotifyEvent);
  end;

constructor TSelectionChangeListener.Create(AEvent: TNotifyEvent);
begin
  FEvent := AEvent;
end;

procedure TSelectionChangeListener.Notification(msg: IJclNotificationMessage);
begin
  inherited;
  if Assigned(FEvent) then begin
    FEvent(nil);
  end;
end;

{ TSelectionLayer }

procedure TSelectionLayer.ChangeSelection(Sender: TObject);
begin
  FColor := GState.LastSelectionInfo.Color32;
  FPolygon := GState.LastSelectionInfo.Polygon;
  FLayerPositioned.Changed;
end;

constructor TSelectionLayer.Create(AParentMap: TImage32;
  AViewPortState: TMapViewPortState);
begin
  inherited;
  FLayerPositioned.OnPaint := PaintLayer;
  FSelectionChangeListener := TSelectionChangeListener.Create(ChangeSelection);
  GState.LastSelectionInfo.ChangeNotifier.Add(FSelectionChangeListener);
end;

destructor TSelectionLayer.Destroy;
begin
  GState.LastSelectionInfo.ChangeNotifier.Remove(FSelectionChangeListener);
  FSelectionChangeListener := nil;
  inherited;
end;

procedure TSelectionLayer.DoRedraw;
begin
  inherited;
  FColor := GState.LastSelectionInfo.Color32;
  FPolygon := Copy(GState.LastSelectionInfo.Polygon);
end;

function TSelectionLayer.GetVisibleRectInMapPixels: TRect;
begin
  Result := MakeRect(0, 0, FViewSize.X, FViewSize.Y);
end;

procedure TSelectionLayer.LoadConfig(AConfigProvider: IConfigDataProvider);
var
  VConfigProvider: IConfigDataProvider;
begin
  inherited;
  VConfigProvider := AConfigProvider.GetSubItem('VIEW');
  if VConfigProvider <> nil then begin
    Visible := VConfigProvider.ReadBool('ShowLastSelection',false);
  end;
end;

function TSelectionLayer.LonLatArrayToVisualFloatArray(
  APolygon: TExtendedPointArray): TExtendedPointArray;
var
  i: Integer;
  VPointsCount: Integer;
  VViewRect: TExtendedRect;
begin
  VPointsCount := Length(APolygon);
  SetLength(Result, VPointsCount);
  FViewPortState.LockRead;
  try
    for i := 0 to VPointsCount - 1 do begin
      Result[i] := FViewPortState.LonLat2VisiblePixel(APolygon[i]);
    end;
    VViewRect := ExtendedRect(FViewPortState.GetViewRectInVisualPixel);
  finally
    FViewPortState.UnLockRead;
  end;
end;

procedure TSelectionLayer.PaintLayer(Sender: TObject; Buffer: TBitmap32);
var
  VVisualPolygon: TExtendedPointArray;
  VFloatPoints: TArrayOfFloatPoint;
  VPointCount: Integer;
  i: Integer;
begin
  VPointCount := Length(FPolygon);
  if VPointCount > 0 then begin
    VVisualPolygon := LonLatArrayToVisualFloatArray(FPolygon);

    SetLength(VFloatPoints, VPointCount);
    for i := 0 to VPointCount - 1 do begin
      VFloatPoints[i] := FloatPoint(VVisualPolygon[i].X, VVisualPolygon[i].Y);
    end;
    PolylineFS(Buffer, VFloatPoints, FColor, True, 2, jsBevel);
  end;
end;

procedure TSelectionLayer.SaveConfig(AConfigProvider: IConfigDataWriteProvider);
var
  VConfigProvider: IConfigDataWriteProvider;
begin
  inherited;
  VConfigProvider := AConfigProvider.GetOrCreateSubItem('VIEW');
  VConfigProvider.WriteBool('ShowLastSelection', Visible);
end;

end.
