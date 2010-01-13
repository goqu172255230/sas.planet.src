unit UOpGenPreviousZoom;

interface

uses
  Windows,
  Forms,
  SysUtils,
  Classes,
  math,
  Graphics,
  Dialogs,
  GR32,
  GR32_Resamplers,
  UMapType,
  UGeoFun,
  unit4,
  UResStrings,
  Uimgfun,
  t_GeoTypes;

type
  TOpGenPreviousZoom = class(TThread)
  private
    Replace:boolean;
    savefull:boolean;
    GenFormPrev:boolean;
    PolygLL: TExtendedPointArray;
    FromZoom:byte;
    InZooms: TArrayOfByte;
    typemap:TMapType;
    max,min:TPoint;
    ProcessTiles:integer;

    Resampler:TTileResamplingType;
    polyg:TPointArray;
    Fprogress: TFprogress2;
    TileInProc:integer;
    CurrentTile:integer;
    FMainTileXY: TPoint;
    FMainTileZoom: byte;
    FChildeTileXY: TPoint;
    FChildeTileZoom: byte;
    bmp_ex:TBitmap32;
    bmp:TBitmap32;
    procedure GenPreviousZoom;
    procedure SetProgressForm;
    procedure UpdateProgressForm;
    procedure CloseProgressForm;
    procedure SyncShowMessage;
    procedure CloseFProgress(Sender: TObject; var Action: TCloseAction);
  protected
    procedure Execute; override;
  public
    destructor destroy; override;
    constructor Create(
      Azoom: byte;
      AInZooms: TArrayOfByte;
      APolygLL: TExtendedPointArray;
      Atypemap: TMapType;
      AReplace: boolean;
      Asavefull: boolean;
      AGenFormPrev: boolean
    );
  end;

implementation

uses
  u_GlobalState,
  unit1;

constructor TOpGenPreviousZoom.Create(Azoom:byte; AInZooms: TArrayOfByte; APolygLL: TExtendedPointArray; Atypemap:TMapType; AReplace:boolean; Asavefull:boolean; AGenFormPrev:boolean);
begin
  inherited Create(False);
  Priority := tpLowest;
  FreeOnTerminate:=true;
  Replace := AReplace;
  savefull := Asavefull;
  GenFormPrev := AGenFormPrev;
  InZooms := AInZooms;
  PolygLL := APolygLL;
  bmp_ex:=TBitmap32.Create;
  bmp:=TBitmap32.Create;
  TileInProc:=0;
  FromZoom:=Azoom;
  typemap:=Atypemap;
  Resampler := GState.Resampling;
end;

destructor TOpGenPreviousZoom.destroy;
begin
 bmp_ex.Free;
 bmp.Free;
 Synchronize(CloseProgressForm);
 inherited ;
end;

procedure TOpGenPreviousZoom.Execute;
var i:integer;
begin
 setlength(polyg,length(PolygLL));
 ProcessTiles:=0;
 for i:=0 to length(InZooms)-1 do
   begin
    polyg := typemap.GeoConvert.PoligonProject((InZooms[i] - 1) + 8, PolygLL);
    if (not GenFormPrev)or(i=0) then
                  inc(ProcessTiles,GetDwnlNum(min,max,Polyg,true)*Round(IntPower(4,FromZoom-InZooms[i])))
             else inc(ProcessTiles,GetDwnlNum(min,max,Polyg,true)*Round(IntPower(4,InZooms[i-1]-InZooms[i])));
   end;
 Synchronize(SetProgressForm);
 GenPreviousZoom;
end;

procedure TOpGenPreviousZoom.CloseFProgress(Sender: TObject; var Action: TCloseAction);
begin
 if not(Terminated) then Terminate;
end;

procedure TOpGenPreviousZoom.CloseProgressForm;
begin
 fprogress.Free;
 GState.MainFileCache.Clear;
 Fmain.generate_im(nilLastLoad,'');
end;

procedure TOpGenPreviousZoom.UpdateProgressForm;
begin
  fprogress.MemoInfo.Lines[0]:=SAS_STR_Saves+': '+inttostr(TileInProc)+' '+SAS_STR_files;
  FProgress.ProgressBar1.Progress1:=CurrentTile;
  fprogress.MemoInfo.Lines[1]:=SAS_STR_Processed+' '+inttostr(CurrentTile);
end;

procedure TOpGenPreviousZoom.SetProgressForm;
begin
  Application.CreateForm(TFProgress2, FProgress);
  FProgress.OnClose:=CloseFProgress;
  FProgress.Visible:=true;
  fprogress.Caption:=SAS_STR_ProcessedNoMore+': '+inttostr(ProcessTiles)+' '+SAS_STR_files;
  fprogress.MemoInfo.Lines[0]:=SAS_STR_Processed+' 0';
  fprogress.MemoInfo.Lines[1]:=SAS_STR_Saves+': 0';
  FProgress.ProgressBar1.Progress1:=0;
  FProgress.ProgressBar1.Max:=ProcessTiles;
end;

procedure TOpGenPreviousZoom.GenPreviousZoom;
var bmp2:TBitmap32;
    i,c_d,p_x,p_y,d2562,p_i,p_j,p_x_x,p_y_y:integer;
    save_len_tile:integer;
    VZoom: Integer;
begin
 bmp2:=TBitmap32.Create;
 bmp.Resampler := CreateResampler(Resampler);

 TileInProc:=0;
 CurrentTile:=0;
 for i:=0 to length(InZooms)-1 do
  begin
   if Terminated then continue;
   polyg := typemap.GeoConvert.PoligonProject((InZooms[i] - 1) + 8, PolygLL);
   if (not GenFormPrev)or(i=0) then
                 c_d:=round(power(2,FromZoom-InZooms[i]))
            else c_d:=round(power(2,InZooms[i-1]-InZooms[i]));
   GetDwnlNum(min,max,Polyg,false);
   p_x:=min.x;
   while (p_x<max.X)and(not Terminated) do
    begin
     p_y:=min.y;
     while (p_y<max.y)and(not Terminated) do
      begin
       if not(RgnAndRgn(Polyg,p_x,p_y,false)) then begin
                                                   inc(p_y,256);
                                                   continue;
                                                  end;
       FMainTileXY.X := p_x;
       FMainTileXY.Y := p_y;
       FMainTileZoom := InZooms[i];
       if typemap.TileExists(p_x,p_y,InZooms[i])then begin
                                if not(Replace)
                                 then begin
                                       Synchronize(UpdateProgressForm);
                                       inc(p_y,256);
                                       continue;
                                      end;
                                typemap.LoadTile(bmp_Ex, FMainTileXY.X, FMainTileXY.y, FMainTileZoom, false);
                               end
                          else begin
                                bmp_ex.width:=256;
                                bmp_ex.Height:=256;
                                bmp_ex.Canvas.Brush.Color:=GState.BGround;
                                bmp_ex.Canvas.FillRect(bmp_ex.Canvas.ClipRect);
                               end;
       d2562:=256 div c_d;
       save_len_tile:=0;
       for p_i:=1 to c_d do
        for p_j:=1 to c_d do
         begin
          if Terminated then continue;
          p_x_x:=((p_x-128) * c_d)+((p_i-1)*256);
          p_y_y:=((p_y-128) * c_d)+((p_j-1)*256);

          if (not GenFormPrev)or(i=0) then
                        VZoom := FromZoom
                   else VZoom := InZooms[i-1];
          if typemap.TileExists(p_x_x,p_y_y,VZoom) then
           begin
            FChildeTileXY.X := p_x_x;
            FChildeTileXY.Y := p_y_y;
            FChildeTileZoom := VZoom;
            typemap.LoadTile(bmp, FChildeTileXY.X, FChildeTileXY.Y, FChildeTileZoom, false);
            bmp_ex.Draw(bounds((p_i-1)*d2562,(p_j-1)*d2562,256 div c_d,256 div c_d),bounds(0,0,256,256),bmp);
            inc(save_len_tile);
           end;
          inc(CurrentTile);
          if (CurrentTile mod 30 = 0) then Synchronize(UpdateProgressForm);
         end;
       if ((savefull)and(save_len_tile<>c_d*c_d))or(save_len_tile=0) then
        begin
         inc(p_y,256);
         continue;
        end;
       try
        typemap.SaveTileSimple(FMainTileXY.X, FMainTileXY.Y, FMainTileZoom,bmp_ex);
        inc(TileInProc);
       except
        Synchronize(SyncShowMessage);
        Terminate;
       end;
       inc(p_y,256);
      end;
     inc(p_x,256);
    end;
  end;
 bmp2.Free;
end;

procedure TOpGenPreviousZoom.SyncShowMessage;
begin
  ShowMessage(SAS_ERR_Write);
end;

end.
