unit u_MapLayerBasic;

interface

uses
  Windows,
  GR32,
  GR32_Image,
  GR32_Layers,
  u_WindowLayerBasic,
  t_GeoTypes;


type
  TMapLayerBasic =  class(TWindowLayerBasic)
  protected

    FScale: Double;
    FScaleCenterInVisualPixel: TPoint;
    FScaleCenterInBitmapPixel: TPoint;
    FFreezeInCenter: Boolean;
    FCenterMove: TPoint;
    FScreenCenterPos: TPoint;

    function GetBitmapSizeInPixel: TPoint; override;
    function GetFreezePointInVisualPixel: TPoint; override;
    function GetFreezePointInBitmapPixel: TPoint; override;
    function GetScale: double; override;

    function VisiblePixel2MapPixel(Pnt: TPoint): TPoint; overload; virtual;
    function VisiblePixel2MapPixel(Pnt: TExtendedPoint): TExtendedPoint; overload; virtual;
    function MapPixel2VisiblePixel(Pnt: TPoint): TPoint; overload; virtual;
    function MapPixel2VisiblePixel(Pnt: TExtendedPoint): TExtendedPoint; overload; virtual;

    function BitmapPixel2MapPixel(Pnt: TPoint): TPoint; overload; virtual;
    function BitmapPixel2MapPixel(Pnt: TExtendedPoint): TExtendedPoint; overload; virtual;
    function MapPixel2BitmapPixel(Pnt: TPoint): TPoint; overload; virtual;
    function MapPixel2BitmapPixel(Pnt: TExtendedPoint): TExtendedPoint; overload; virtual;
  public
    constructor Create(AParentMap: TImage32; ACenter: TPoint);
    procedure MoveTo(Pnt: TPoint); virtual;
    procedure ScaleTo(AScale: Double; ACenterPoint: TPoint); virtual;
    procedure SetScreenCenterPos(const Value: TPoint); virtual;
    property ScreenCenterPos: TPoint read FScreenCenterPos;
  end;
implementation

uses
  Types,
  Forms,
  Graphics,
  Math,
  u_GlobalState;

{ TGPSTrackLayer }

constructor TMapLayerBasic.Create(AParentMap: TImage32; ACenter: TPoint);
begin
  inherited Create(AParentMap);
  FScreenCenterPos := ACenter;
end;

procedure TMapLayerBasic.SetScreenCenterPos(const Value: TPoint);
var
  VBitmapSize: TPoint;
  VVisualSize: TPoint;
begin
  FScreenCenterPos := Value;
  FScale := 1;
  FCenterMove := Point(0, 0);

  FFreezeInCenter := True;

  if Visible then begin
    Redraw;
    Resize;
  end;
end;

function TMapLayerBasic.BitmapPixel2MapPixel(Pnt: TPoint): TPoint;
var
  VSizeInPixel: TPoint;
begin
  VSizeInPixel := GetBitmapSizeInPixel;
  Result.X := ScreenCenterPos.X - VSizeInPixel.X div 2 + Pnt.X;
  Result.Y := ScreenCenterPos.Y - VSizeInPixel.Y div 2 + Pnt.y;
end;

function TMapLayerBasic.BitmapPixel2MapPixel(Pnt: TExtendedPoint): TExtendedPoint;
var
  VSizeInPixel: TPoint;
begin
  VSizeInPixel := GetBitmapSizeInPixel;
  Result.X := ScreenCenterPos.X - VSizeInPixel.X / 2 + Pnt.X;
  Result.Y := ScreenCenterPos.Y - VSizeInPixel.Y / 2 + Pnt.y;
end;

function TMapLayerBasic.MapPixel2BitmapPixel(Pnt: TPoint): TPoint;
var
  VSize: TPoint;
begin
  VSize := GetBitmapSizeInPixel;
  Result.X := Pnt.X - ScreenCenterPos.X + (VSize.X div 2);
  Result.Y := Pnt.Y - ScreenCenterPos.Y + (VSize.Y div 2);
end;

function TMapLayerBasic.MapPixel2BitmapPixel(Pnt: TExtendedPoint): TExtendedPoint;
var
  VSize: TPoint;
begin
  VSize := GetBitmapSizeInPixel;
  Result.X := Pnt.X - ScreenCenterPos.X + (VSize.X / 2);
  Result.Y := Pnt.Y - ScreenCenterPos.Y + (VSize.Y / 2);
end;

function TMapLayerBasic.MapPixel2VisiblePixel(Pnt: TPoint): TPoint;
var
  VPoint: TPoint;
begin
  VPoint := MapPixel2BitmapPixel(Pnt);
  Result := BitmapPixel2VisiblePixel(Pnt);
end;

function TMapLayerBasic.MapPixel2VisiblePixel(Pnt: TExtendedPoint): TExtendedPoint;
var
  VPoint: TExtendedPoint;
begin
  VPoint := MapPixel2BitmapPixel(Pnt);
  Result := BitmapPixel2VisiblePixel(VPoint);
end;

function TMapLayerBasic.VisiblePixel2MapPixel(Pnt:TPoint):TPoint;
var
  VPoint: TPoint;
begin
  VPoint := VisiblePixel2BitmapPixel(Pnt);
  Result := BitmapPixel2MapPixel(VPoint);
end;

function TMapLayerBasic.VisiblePixel2MapPixel(Pnt: TExtendedPoint): TExtendedPoint;
var
  VPoint: TExtendedPoint;
begin
  VPoint := VisiblePixel2BitmapPixel(Pnt);
  Result := BitmapPixel2MapPixel(VPoint);
end;

procedure TMapLayerBasic.MoveTo(Pnt: TPoint);
begin
  if Visible then begin
    FCenterMove := Pnt;
    FFreezeInCenter := True;
    Resize;
  end;
end;

procedure TMapLayerBasic.ScaleTo(AScale: Double; ACenterPoint: TPoint);
begin
  if Visible then begin
    FScaleCenterInBitmapPixel := VisiblePixel2BitmapPixel(ACenterPoint);
    FScaleCenterInVisualPixel := ACenterPoint;
    FScale := AScale;
    FFreezeInCenter := False;
    Resize;
  end;
end;


function TMapLayerBasic.GetFreezePointInBitmapPixel: TPoint;
var
  VBitmapSize: TPoint;
begin
  if FFreezeInCenter then begin
    VBitmapSize := GetBitmapSizeInPixel;
    Result := Point(VBitmapSize.X div 2, VBitmapSize.Y div 2);
  end else begin
    Result := FScaleCenterInBitmapPixel;
  end;
end;

function TMapLayerBasic.GetFreezePointInVisualPixel: TPoint;
var
  VVisibleSize: TPoint;
begin
  if FFreezeInCenter then begin
    VVisibleSize := GetVisibleSizeInPixel;
    Result := Point(VVisibleSize.X div 2 - FCenterMove.X, VVisibleSize.Y div 2 - FCenterMove.Y);
  end else begin
    Result := Point(FScaleCenterInVisualPixel.X - FCenterMove.X, FScaleCenterInVisualPixel.Y - FCenterMove.Y);
  end;
end;

function TMapLayerBasic.GetScale: double;
begin
  Result := FScale;
end;

function TMapLayerBasic.GetBitmapSizeInPixel: TPoint;
begin
  Result.X := Screen.Width + 2 * 256 * GState.TilesOut;
  Result.Y := Screen.Height + 2 * 256 * GState.TilesOut;
end;

end.
