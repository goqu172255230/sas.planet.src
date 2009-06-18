unit UWikiLayer;
interface
uses Classes,GR32,UgeoFun,math,UKmlParse,UMapType, UResStrings;
type
  TWikiLayer = class
   public
    name_blok:string;
    num_blok:string;
    description:string;
    LT,RD:Tpoint;
    AarrKt:array of TPoint;
  end;
  PWikiLayer = ^TWikilayer;
var WikiLayer:array of TWikiLayer;


    old_x,old_y:integer;
    kml:TKML;
    procedure destroyWL;
    procedure addWL(name,descript,num:string;coordinatesLT,coordinatesRD:TExtendedPoint;coordinates: Array of TExtendedPoint);
    procedure loadWL(Alayer:PMapType);
    procedure MouseOnReg(var PWL:TResObj;xy:TPoint);

implementation
uses unit1, SysUtils, StrUtils, UImgFun;

procedure MouseOnReg(var PWL:TResObj;xy:TPoint);
var i,j:integer;
    l:integer;
begin
 for i:=0 to length(Wikilayer)-1 do
   if (xy.x>Wikilayer[i].lt.X-5)and(xy.x<Wikilayer[i].rd.X+5)and
      (xy.y>Wikilayer[i].lt.Y-5)and(xy.y<Wikilayer[i].rd.Y+5) then
   begin
    if length(Wikilayer[i].AarrKt)=1 then
     begin
      PWL.name:=Wikilayer[i].name_blok;
      PWL.descr:=Wikilayer[i].description;
      PWL.numid:=Wikilayer[i].num_blok;
      PWL.find:=true;
      exit;
     end;
    l:=length(Wikilayer[i].AarrKt)-1;
    if l<0 then continue;
    j:=1;
    if (Wikilayer[i].AarrKt[0].X<>Wikilayer[i].AarrKt[l].x)or
       (Wikilayer[i].AarrKt[0].y<>Wikilayer[i].AarrKt[l].y)then
      while (j<length(Wikilayer[i].AarrKt)) do
       begin
        if CursorOnLinie(xy.x, xy.Y, Wikilayer[i].AarrKt[j-1].x, Wikilayer[i].AarrKt[j-1].y,
                         Wikilayer[i].AarrKt[j].x, Wikilayer[i].AarrKt[j].y, 3)
           then begin
                 PWL.name:=Wikilayer[i].name_blok;
                 PWL.descr:=Wikilayer[i].description;
                 PWL.numid:=Wikilayer[i].num_blok;
                 PWL.find:=true;
                 exit;
                end;
        inc(j);
       end
     else
     if PtInRgn(Wikilayer[i].AarrKt,xy) then
      begin
       if (PolygonSquare(Wikilayer[i].AarrKt)>PWL.S)and(PWL.S<>0)
        then continue;
       PWL.S:=PolygonSquare(Wikilayer[i].AarrKt);
       PWL.name:=Wikilayer[i].name_blok;
       PWL.descr:=Wikilayer[i].description;
      // PWL.descr:=PWL.descr+#13#10+SAS_STR_S+': '+RoundEx(CalcS( ,sat_map_both),2)+' '+SAS_UNITS_m2; //Fmain.R2ShortStr(CalcS(poly,sat_map_both),4,' '+SAS_UNITS_km+'.',' '+SAS_UNITS_m);
       PWL.numid:=Wikilayer[i].num_blok;
       PWL.find:=true;
      end
 end;
end;

procedure destroyWL;
var i:integer;
begin
 for i:=0 to length(Wikilayer)-1 do
  begin
   Wikilayer[i].Free;
   Wikilayer[i]:=nil;
  end;
 SetLength(WikiLayer,0);
 LayerMapWiki.Visible:=false;
// LayerMapWiki.Bitmap.Clear(clBlack);
end;

procedure loadWL(Alayer:PMapType);
var path:string;
    Ax,Ay,i,j,ii,Azoom:integer;
    APos:TPoint;
    AmapType:TMapType;
begin
 LayerMapWiki.Visible:=true;
 AmapType:=TmapType.Create;
 AmapType.projection:=1;
 for i:=0 to hg_x do
  for j:=0 to hg_y do
   begin
    Azoom:=zoom_size;
    APos:=ConvertPosM2M(pos,Azoom,sat_map_both,Alayer);
    if CiclMap then Ax:=Fmain.X2AbsX(APos.X-pr_x+(i shl 8),zoom_size)
               else Ax:=APos.X-pr_x+(i shl 8);
    Ay:=APos.y-pr_y+(j shl 8);
    path:=ffpath(Ax,Ay,Azoom,Alayer^,false);
    KML:=TKML.Create;
    if kml.loadFromFile(path) then
     for ii:=0 to length(KML.Data)-1 do
      addWL(KML.Data[ii].Name,KML.Data[ii].description,KML.Data[ii].PlacemarkID,KML.Data[ii].coordinatesLT,KML.Data[ii].coordinatesRD,KML.Data[ii].coordinates);
    KML.Free;
   end;
 AmapType.Free;
end;

procedure addWL(name,descript,num:string;coordinatesLT,coordinatesRD:TExtendedPoint;coordinates: Array of TExtendedPoint);
var i,lenLay:integer;
begin
 Delete(descript,posEx('#ge',descript,0),1);
 setLength(WikiLayer,length(WikiLayer)+1);
 lenLay:=length(WikiLayer);
 WikiLayer[lenLay-1]:=TWikiLayer.Create;
 With WikiLayer[lenLay-1] do
  begin
   if coordinatesLT.X=coordinatesRD.x then
    begin
     LT.X:=Fmain.Lon2X(coordinatesLT.X)-3;
     RD.x:=Fmain.Lon2X(coordinatesRD.x)+3;
    end else
    begin
     LT.X:=Fmain.Lon2X(coordinatesLT.X);
     RD.x:=Fmain.Lon2X(coordinatesRD.x);
    end;
   if coordinatesLT.y=coordinatesRD.y then
    begin
     LT.Y:=Fmain.Lat2y(coordinatesLT.Y)-3;
     RD.Y:=Fmain.Lat2y(coordinatesRD.Y)+3;
    end else
    begin
     LT.Y:=Fmain.Lat2y(coordinatesLT.Y);
     RD.Y:=Fmain.Lat2y(coordinatesRD.Y);
    end;
   if(((RD.x-LT.x)<=1)or((RD.y-LT.y)<=1)or
     ((LT.y>Fmain.map.Height)or(RD.y<0)or(LT.x>Fmain.map.Width)or(RD.x<0))){and(length(coordinates)>1)} then
     begin
      LT.X:=LT.X+(pr_x-mWd2);
      RD.x:=RD.x+(pr_x-mWd2);
      LT.Y:=LT.Y+(pr_y-mHd2);
      RD.Y:=RD.Y+(pr_y-mHd2);
      exit;
     end;
   LT.X:=LT.X+(pr_x-mWd2);
   RD.x:=RD.x+(pr_x-mWd2);
   LT.Y:=LT.Y+(pr_y-mHd2);
   RD.Y:=RD.Y+(pr_y-mHd2);
   name_blok:=name;
   num_blok:=num;
   description:=descript;
   setLength(AarrKt,length(coordinates));
   if length(coordinates)=1 then
    begin
     setLength(AarrKt,5);
     AarrKt[0]:=Point(Fmain.Lon2X(coordinates[0].X)+(pr_x-mWd2)-2,Fmain.Lat2Y(coordinates[0].Y)+(pr_y-mHd2)-2);
     AarrKt[1]:=Point(Fmain.Lon2X(coordinates[0].X)+(pr_x-mWd2)+2,Fmain.Lat2Y(coordinates[0].Y)+(pr_y-mHd2)-2);
     AarrKt[2]:=Point(Fmain.Lon2X(coordinates[0].X)+(pr_x-mWd2)+2,Fmain.Lat2Y(coordinates[0].Y)+(pr_y-mHd2)+2);
     AarrKt[3]:=Point(Fmain.Lon2X(coordinates[0].X)+(pr_x-mWd2)-2,Fmain.Lat2Y(coordinates[0].Y)+(pr_y-mHd2)+2);
     AarrKt[4]:=Point(Fmain.Lon2X(coordinates[0].X)+(pr_x-mWd2)-2,Fmain.Lat2Y(coordinates[0].Y)+(pr_y-mHd2)-2);
    end
   else
   for i:=0 to length(coordinates)-1 do
    begin
     AarrKt[i].X:=Fmain.Lon2X(coordinates[i].X)+(pr_x-mWd2);
     AarrKt[i].Y:=Fmain.Lat2Y(coordinates[i].Y)+(pr_y-mHd2);
     //Polyg.Add(FixedPoint(WikiLayer[lenLay-1].AarrKt[i].X+(pr_x-mWd2),WikiLayer[lenLay-1].AarrKt[i].Y+(pr_y-mHd2)));
    end;
     LayerMapWiki.Bitmap.Canvas.Pen.Width:=3;
     LayerMapWiki.Bitmap.Canvas.Pen.Color:=Wikim_set.FonColor;
     if length(coordinates)=1 then LayerMapWiki.Bitmap.Canvas.Ellipse(AarrKt[0].x,AarrKt[0].y,AarrKt[2].x,AarrKt[2].y)
                              else LayerMapWiki.Bitmap.Canvas.Polyline(AarrKt);
     LayerMapWiki.Bitmap.Canvas.Pen.Width:=1;
     LayerMapWiki.Bitmap.Canvas.Pen.Color:=Wikim_set.MainColor;
     if length(coordinates)=1 then LayerMapWiki.Bitmap.Canvas.Ellipse(AarrKt[0].x,AarrKt[0].y,AarrKt[2].x,AarrKt[2].y)
                              else LayerMapWiki.Bitmap.Canvas.Polyline(AarrKt);
  end;
{ Outli := Polyg.Outline.Grow(Fixed(1.5), 0.5);
 Outli.FillMode := pfWinding;
 Outli.DrawFill(LayerMapWiki.Bitmap, SetAlpha(clBlack32, 110)); //WikiLayer[lenLay-1].Bitmap.Canvas.Polyline(WikiLayer[lenLay-1].AarrKt);
{ Outli := Polyg.Outline.Grow(Fixed(0.6), 0.5);
 Outli.DrawFill(LayerMapWiki.Bitmap, SetAlpha(clWhite32, 255)); //WikiLayer[lenLay-1].Bitmap.Canvas.Polyline(WikiLayer[lenLay-1].AarrKt);
 Outli.Free;}
end;

end.
