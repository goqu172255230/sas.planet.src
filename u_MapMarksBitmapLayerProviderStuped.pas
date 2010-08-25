unit u_MapMarksBitmapLayerProviderStuped;

interface

uses
  Types,
  GR32,
  i_ICoordConverter,
  i_IBitmapLayerProvider;

type
  TMapMarksBitmapLayerProviderStuped = class(TInterfacedObject, IBitmapLayerProvider)
  private
    procedure GetBitmapRect(
      ATargetBmp: TCustomBitmap32;
      AConverter: ICoordConverter;
      ATargetRect: TRect;
      ATargetZoom: Byte
    );
  public
  end;
implementation

uses
  Classes,
  SysUtils,
  DB,
  GR32_Resamplers,
  GR32_Polygons,
  t_GeoTypes,
  t_CommonTypes,
  u_GlobalState,
  Ugeofun,
  u_MarksSimple,
  u_MarksReadWriteSimple;

{ TMapMarksBitmapLayerProviderStupedThreaded }

type
  TMapMarksBitmapLayerProviderStupedThreaded = class
  private
    FTargetBmp: TCustomBitmap32;
    FGeoConvert: ICoordConverter;
    FTargetRect: TRect;
    FZoom: Byte;
    FLLRect: TExtendedRect;
    function MapPixel2BitmapPixel(Pnt: TPoint): TPoint; overload; virtual;
    function MapPixel2BitmapPixel(Pnt: TExtendedPoint): TExtendedPoint; overload; virtual;
    procedure drawPath2Bitmap(pathll:TExtendedPointArray; color1, color2:TColor32; linew:integer; poly:boolean);
  public
    constructor Create(
      ATargetBmp: TCustomBitmap32;
      AConverter: ICoordConverter;
      ATargetRect: TRect;
      ATargetZoom: Byte
    );
    procedure SyncGetBitmap;
  end;

constructor TMapMarksBitmapLayerProviderStupedThreaded.Create(
  ATargetBmp: TCustomBitmap32; AConverter: ICoordConverter;
  ATargetRect: TRect; ATargetZoom: Byte);
var
  VDeltaLL: TExtendedPoint;
begin
  FTargetBmp := ATargetBmp;
  FGeoConvert := AConverter;
  FTargetRect := ATargetRect;
  FZoom := FZoom;
  FLLRect := FGeoConvert.PixelRect2LonLatRect(FTargetRect, FZoom);
  VDeltaLL:=ExtPoint((FLLRect.Right-FLLRect.Left)/2,(FLLRect.Top-FLLRect.Bottom)/2);
  FLLRect.Left := FLLRect.Left - VDeltaLL.X;
  FLLRect.Top := FLLRect.Top - VDeltaLL.Y;
  FLLRect.Right := FLLRect.Right + VDeltaLL.X;
  FLLRect.Bottom := FLLRect.Bottom + VDeltaLL.Y;
end;

function TMapMarksBitmapLayerProviderStupedThreaded.MapPixel2BitmapPixel(
  Pnt: TPoint): TPoint;
begin
  Result.X := Pnt.X - FTargetRect.Left;
  Result.Y := Pnt.Y - FTargetRect.Top;
end;

function TMapMarksBitmapLayerProviderStupedThreaded.MapPixel2BitmapPixel(
  Pnt: TExtendedPoint): TExtendedPoint;
begin
  Result.X := Pnt.X - FTargetRect.Left;
  Result.Y := Pnt.Y - FTargetRect.Top;
end;

procedure TMapMarksBitmapLayerProviderStupedThreaded.drawPath2Bitmap(
  pathll: TExtendedPointArray; color1, color2: TColor32; linew: integer;
  poly: boolean);
var
  i,adp,j:integer;
  k1,k2,k4:TPoint;
  k3:TextendedPoint;
  polygon: TPolygon32;
  VLonLat: TExtendedPoint;
begin
  try
    polygon:=TPolygon32.Create;
    try
      polygon.Antialiased:=true;
      polygon.AntialiasMode:=am4times;
      polygon.Closed:=poly;
      if length(pathll)>0 then begin
        for i:=0 to length(pathll)-1 do begin
          VLonLat := pathll[i];
          FGeoConvert.CheckLonLatPos(VLonLat);
          k1:=FGeoConvert.LonLat2PixelPos(VLonLat,FZoom);
          k1:=MapPixel2BitmapPixel(k1);
          if (k1.x<32767)and(k1.x>-32767)and(k1.y<32767)and(k1.y>-32767) then begin
            polygon.Add(FixedPoint(k1));
          end;
          if i<length(pathll)-1 then begin
            VLonLat := pathll[i+1];
            FGeoConvert.CheckLonLatPos(VLonLat);
            k2:=FGeoConvert.LonLat2PixelPos(VLonLat,FZoom);
            k2:=MapPixel2BitmapPixel(k2);
            if (k2.x-k1.x)>(k2.y-k1.y) then begin
              adp:=(k2.x-k1.x)div 32767+2;
            end else begin
              adp:=(k2.y-k1.y)div 32767+2;
            end;
            k3:=extPoint(((k2.X-k1.x)/adp),((k2.y-k1.y)/adp));
            if adp>2 then begin
              for j:=1 to adp-1 do begin
                k4:=Point(round(k1.x+k3.x*j),round(k1.Y+k3.y*j));
                if(k4.x<32767)and(k4.x>-32767)and(k4.y<32767)and(k4.y>-32767)then begin
                  polygon.Add(FixedPoint(k4.x,k4.y));
                end;
              end;
            end;
          end;
        end;
        if poly then begin
          Polygon.DrawFill(FTargetBmp, color2);
        end;
        with Polygon.Outline do try
          with Grow(Fixed(linew / 2), 0.5) do try
            FillMode := pfWinding;
            DrawFill(FTargetBmp, color1);
          finally
            free;
          end;
        finally
          free;
        end;
      end;
    finally
      polygon.Free;
    end;
  except
  end;
end;

procedure TMapMarksBitmapLayerProviderStupedThreaded.SyncGetBitmap;
var
  xy:Tpoint;
  btm:TCustomBitmap32;
  TestArrLenLonLatRect: TExtendedRect;
  TestArrLenPixelRect: TRect;
  buf_line_arr:TExtendedPointArray;
  indexmi:integer;
  imw,texth:integer;
  VIconSource: TCustomBitmap32;
  VBtmEx: TBitmap32;
  VScale1: Integer;
  VColor1: TColor32;
  VColor2: TColor32;
  VPointCount: Integer;
  VMarkName: string;
  VMarksIterator: TMarksIteratorVisibleInRect;
  VMark: TMarkFull;
begin
  VMarksIterator := TMarksIteratorVisibleInRect.Create(FZoom, FLLRect);
  try
    VBtmEx := TBitmap32.Create;
    btm:=TCustomBitmap32.Create;
    try
      VBtmEx.Font.Name:='Tahoma';
      VBtmEx.Font.Style:=[];
      VBtmEx.DrawMode := dmBlend;
      btm.DrawMode:=dmBlend;
      btm.Resampler:=TLinearResampler.Create;
      While VMarksIterator.Next do begin
        VMark := VMarksIterator.Current;
        VScale1 := VMark.Scale1;
        VColor1 := VMark.Color1;
        VColor2 := VMark.Color2;
        VMarkName := VMark.name;
        buf_line_arr := VMark.Points;
        VPointCount := length(buf_line_arr);
        if VPointCount>1 then begin
          TestArrLenLonLatRect := VMark.LLRect;
          FGeoConvert.CheckLonLatRect(TestArrLenLonLatRect);
          TestArrLenPixelRect := FGeoConvert.LonLatRect2PixelRect(TestArrLenLonLatRect, FZoom);
          if (abs(TestArrLenPixelRect.Left-TestArrLenPixelRect.Right)>VScale1+2)or(abs(TestArrLenPixelRect.Top-TestArrLenPixelRect.Bottom)>VScale1+2) then begin
            drawPath2Bitmap(buf_line_arr,VColor1,VColor2,VScale1,
              (buf_line_arr[0].x=buf_line_arr[VPointCount-1].x)and(buf_line_arr[0].y=buf_line_arr[VPointCount-1].y));
          end;
        end else if VPointCount =1 then begin
          xy:=FGeoConvert.LonLat2PixelPos(buf_line_arr[0],FZoom);
          xy := MapPixel2BitmapPixel(xy);
          imw:=VMark.Scale2;
          indexmi:=GState.MarkIcons.IndexOf(VMark.PicName);
          if(indexmi=-1)and(GState.MarkIcons.Count>0) then begin
            indexmi:=0;
          end;
          if(indexmi>-1)then begin
            VIconSource := TCustomBitmap32(GState.MarkIcons.Objects[indexmi]);
            btm.SetSize(VIconSource.Width, VIconSource.Height);
            btm.Draw(0, 0, VIconSource);
            FTargetBmp.Draw(bounds(xy.x-(imw div 2),xy.y-imw,imw,imw),bounds(0,0,btm.Width,btm.Height), btm);
          end;
          if VScale1>0 then begin
//TODO: ������� ����� �������� ��� �����.
//            VBtmEx.Font.Size:=VScale1;
//            texth:=VBtmEx.TextHeight(VMarkName) div 2;
//            VBtmEx.RenderText(xy.x+(imw div 2)+2,xy.y-(imw div 2)-texth+1,VMarkName,1,VColor2);
//            VBtmEx.RenderText(xy.x+(imw div 2)+1,xy.y-(imw div 2)-texth,VMarkName,1,VColor1);
          end;
        end;
      end;
    finally
      btm.Free;
      VBtmEx.Free;
    end;
  finally
    VMarksIterator.Free;
  end;
end;

{ TMapMarksBitmapLayerProviderStuped }

procedure TMapMarksBitmapLayerProviderStuped.GetBitmapRect(
  ATargetBmp: TCustomBitmap32; AConverter: ICoordConverter;
  ATargetRect: TRect; ATargetZoom: Byte);
var
  VWorker: TMapMarksBitmapLayerProviderStupedThreaded;
begin
  if (GState.show_point <> mshNone) then begin;
    VWorker := TMapMarksBitmapLayerProviderStupedThreaded.Create(
      ATargetBmp, AConverter, ATargetRect, ATargetZoom);
    try
      TThread.Synchronize(nil, VWorker.SyncGetBitmap);
    finally
      VWorker.Free;
    end;
  end;
end;

end.
