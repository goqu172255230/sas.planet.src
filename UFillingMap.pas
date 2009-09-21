unit UFillingMap;

interface

uses
  Windows,
  Forms,
  SysUtils,
  Classes,
  Graphics,
  Dialogs,
  Math,

  GR32,
  GR32_Layers,
  GR32_Resamplers,

  UMapType,
  UImgFun,
  UGeoFun,
  unit4,
  UResStrings;

type
  TFillingMap = class(TThread)
  private
    LayerMap:TBitmapLayer;
    needRepaint:boolean;
    stop:boolean;

    ClMZ:TColor32;
    dZoom:Byte;
    y_draw,x_draw:longint;
    Ahg_x,Ahg_y,Apr_x,Apr_y,ppaprx,ppapry:integer;
    d2562,x2,xyTiles:integer;
    procedure SetupLayer;
    procedure UpdateLayer;
    procedure SetLocation(const Value: TFloatRect);
  protected
    procedure Execute; override;
  public
    destructor destroy; override;
    constructor Create(CrSusp:Boolean);
    procedure StartDrow;
    procedure StopDrow;
    property Location: TFloatRect write SetLocation;
  end;

var
  fillingmaptype:TMapType;

implementation

uses
  unit1,
  USaveas;

constructor TFillingMap.Create(CrSusp:Boolean);
begin
  LayerMap:=TBitmapLayer.Create(FMain.map.Layers);
  LayerMap.bitmap.DrawMode:=dmBlend;
  needRepaint:=false;
  inherited Create(CrSusp);
end;

destructor TFillingMap.destroy;
begin
  LayerMap.Free;
  inherited;
end;

procedure TFillingMap.UpdateLayer;
begin
  LayerMap.Update;
end;

procedure TFillingMap.SetupLayer;
begin
  LayerMap.bitmap.Clear(clBlack);
  LayerMap.Bitmap.Width:=xhgpx;
  LayerMap.Bitmap.Height:=yhgpx;
  LayerMap.Location:=Unit1.LayerMap.Location;
  LayerMap.Visible:=true;
  dZoom:=zoom_mapzap-zoom_size;
  x2:=trunc(power(2,dZoom));
  ClMZ:=SetAlpha(Color32(MapZapColor),MapZapAlpha);
  d2562:=256 shr dZoom;
  xyTiles:=1;
  if d2562=0 then begin
    xyTiles:=trunc(power(2,(dZoom-8)));
    d2562:=1;
  end;
  Ahg_x:=(FMain.map.Width div d2562)+1;
  Ahg_y:=(FMain.map.Height div d2562)+1;
  Apr_x:=(d2562*Ahg_x)div 2;
  Apr_y:=(d2562*Ahg_y)div 2;
  x_draw:=((d2562+((FMain.pos.x-Apr_x)mod d2562))mod d2562)-((pr_x-Apr_x));
  y_draw:=((d2562+((FMain.pos.y-Apr_y)mod d2562))mod d2562)-((pr_y-Apr_y));
  ppaprx:=FMain.pos.x-Apr_x;
  ppapry:=FMain.pos.y-Apr_y;
end;

procedure TFillingMap.Execute;
var
  VTileFileName:String;
  VCurrFolderName:string;
  VPrevFolderName:string;
  VPrevTileFolderExist:boolean;
  VTileExist:boolean;
  i,j,ii,jj,ixT,jxT:integer;
  imd256x,imd256y,xx,yy,x1,y1:longint;

  VMapType:TMapType;
begin
  repeat
    Synchronize(SetupLayer);
    ppaprx:=ppaprx*x2;
    ppapry:=ppapry*x2;
    VPrevTileFolderExist:=true;
    imd256x:=0;
    VTileExist:=true;
    for i:=0 to Ahg_x do begin
      imd256y:=0;
      if (Terminated)or(needRepaint)or(stop) then begin
        continue;
      end;
      for j:=0 to Ahg_y do begin
        if (Terminated)or(needRepaint)or(stop) then begin
          continue;
        end;
        if fillingmaptype=nil then begin
          VMapType := sat_map_both;
        end else begin
          VMapType := fillingmaptype;
        end;
        ixT:=0;
        While ixT<(xyTiles) do begin
          xx:=ppaprx+(imd256x shl dZoom)+(ixT*256);
          if (Terminated)or(needRepaint)or(stop)or(xx<0)or(xx>=zoom[zoom_mapzap]) then begin
            inc(ixT);
            continue;
          end;
          jxT:=0;
          While jxT<(xyTiles) do begin
            yy:=ppapry+(imd256y shl dZoom)+(jxT*256);
            if (Terminated)or(needRepaint)or(stop)or(yy<0)or(yy>=zoom[zoom_mapzap]) then begin
              VTileExist:=true;
              inc(jxT);
              continue;
            end;
            //TODO: �������� �������� ���������� �� ����� ����������� � ��������� ����� ������ ��� �����.
            VTileFileName := VMapType.GetTileFileName(xx,yy,zoom_mapzap);
            VCurrFolderName := ExtractFilePath(VTileFileName);
            if VCurrFolderName=VPrevFolderName then begin
              if VPrevTileFolderExist then begin
                VTileExist:=VMapType.TileExists(xx,yy,zoom_mapzap)
              end else begin
                VTileExist:=false
              end;
            end else begin
              VPrevTileFolderExist:=DirectoryExists(VCurrFolderName);
              if VPrevTileFolderExist then begin
                VTileExist:=VMapType.TileExists(xx,yy,zoom_mapzap)
              end else begin
                VTileExist:=false;
              end;
            end;
            VPrevFolderName:=VCurrFolderName;
            if VTileExist then begin
              ixT:=xyTiles;
              jxT:=xyTiles;
            end;
            inc(jxT);
          end;
          inc(ixT);
        end;
        if not(VTileExist) then begin
          x1:=imd256x-x_draw; y1:=imd256y-y_draw;
          if (x1<x1+(d2562-1))and(y1<y1+(d2562-1)) then begin
            for ii:=x1 to x1+(d2562-1) do begin
              for jj:=y1 to y1+(d2562-1) do begin
                LayerMap.Bitmap.PixelS[ii,jj]:=clMZ;
              end;
            end;
          end else begin
            LayerMap.Bitmap.PixelS[x1,y1]:=clMZ;
          end;
        end;
        inc(imd256y,d2562)
      end;
      if ((i+1) mod 30 = 0 ) then begin
        Synchronize(UpdateLayer);
      end;
      inc(imd256x,d2562)
    end;
    Synchronize(UpdateLayer);
    if (stop) then begin
      Suspend;
    end;
    while (not Terminated)and(not needRepaint) do begin
      sleep(1);
    end;
    needRepaint:=false;
  until terminated;
end;

procedure TFillingMap.StartDrow;
begin
  stop:=false;
  needRepaint:=true;
  Suspended:=false;
  LayerMap.bitmap.Clear(clBlack);;
end;

procedure TFillingMap.StopDrow;
begin
  stop:=true;
  LayerMap.Visible:=false;
end;

procedure TFillingMap.SetLocation(const Value: TFloatRect);
begin
  if (LayerMap<>nil) and (LayerMap.Visible) then  begin
    LayerMap.Location := Value;
  end;
end;

end.
