unit u_LayerScaleLine;

interface

uses
  Types,
  GR32_Image,
  u_WindowLayerBasic;

type
  TLayerScaleLine = class(TWindowLayerBasic)
  protected
    function GetBitmapSizeInPixel: TPoint; override;
    function GetFreezePointInVisualPixel: TPoint; override;
    function GetFreezePointInBitmapPixel: TPoint; override;
    procedure DoRedraw; override;
  public
    constructor Create(AParentMap: TImage32);
  end;

implementation

uses
  Math,
  SysUtils,
  GR32,
  uMapType,
  Unit1,
  UResStrings,
  t_GeoTypes,
  u_GlobalState;

{ TLayerScaleLine }

constructor TLayerScaleLine.Create(AParentMap: TImage32);
begin
  inherited Create(AParentMap);
  FLayer.Bitmap.Font.Name := 'arial';
  FLayer.Bitmap.Font.Size := 10;
end;

procedure TLayerScaleLine.DoRedraw;
var
  rnum,len_p,textstrt,textwidth: integer;
  s,se: string;
  LL: TExtendedPoint;
  temp,num: real;
  VBitmapSize: TPoint;
  VRad: Extended;
begin
  inherited;
  Resize;
  VBitmapSize := GetBitmapSizeInPixel;
  LL:=GState.sat_map_both.GeoConvert.PixelPos2LonLat(Fmain.ScreenCenterPos, GState.zoom_size-1);
  VRad := GState.sat_map_both.GeoConvert.GetSpheroidRadius;
  num:=106/((zoom[GState.zoom_size]/(2*PI))/(VRad*cos(LL.y*D2R)));
  if num>10000 then begin
    num:=num/1000;
    se:=' '+SAS_UNITS_km+'.';
  end else if num<10    then begin
    num:=num*100;
    se:=' '+SAS_UNITS_sm+'.';
  end else begin
    se:=' '+SAS_UNITS_m+'.';
  end;
  rnum:=round(num);
  temp:=power(5,(length(inttostr(rnum))-1));
  if ((rnum/temp)<1.25) then begin
    rnum:=round(temp);
  end else if ((rnum/temp)>=3.75)then begin
    rnum:=5*round(temp);
  end else begin
    rnum:=round(2.5*temp);
  end;
  len_p:=round(106/(num/rnum));
  s:=inttostr(rnum)+se;
  textwidth:=FLayer.bitmap.TextWidth(s);
  while (len_p<textwidth+15)and(not(len_p=0)) do begin
    rnum:=rnum*2;
    len_p:=round(106/(num/rnum));
  end;
  s:=inttostr(rnum)+se;
  len_p:=round(106/(num/rnum));
  textwidth:=FLayer.bitmap.TextWidth(s);

  FLayer.Bitmap.Clear(SetAlpha(clWhite32,0));
  FLayer.Bitmap.FillRectS(Rect(0,0, len_p, VBitmapSize.Y - 1), SetAlpha(clWhite32,135));
  FLayer.bitmap.LineS(0, 0, 0, VBitmapSize.Y - 1, SetAlpha(clBlack32,256));
  FLayer.bitmap.LineS(len_p-1,0,len_p-1,VBitmapSize.Y - 1,SetAlpha(clBlack32,256));
  textstrt:=(len_p div 2)-(textwidth div 2);
  FLayer.bitmap.RenderText(textstrt,0,s, 2, clBlack32);
end;

function TLayerScaleLine.GetBitmapSizeInPixel: TPoint;
begin
  Result.X := 128;
  Result.Y := 15;
end;

function TLayerScaleLine.GetFreezePointInBitmapPixel: TPoint;
var
  VBitmapSize: TPoint;
begin
  VBitmapSize := GetBitmapSizeInPixel;
  Result := Point(0, VBitmapSize.Y);
end;

function TLayerScaleLine.GetFreezePointInVisualPixel: TPoint;
var
  VVisibleSize: TPoint;
begin
  VVisibleSize := GetVisibleSizeInPixel;
  Result := Point(6, VVisibleSize.Y - 6);
  if GState.ShowStatusBar then begin
    Result.Y := Result.Y - 17;
  end;
end;

end.
