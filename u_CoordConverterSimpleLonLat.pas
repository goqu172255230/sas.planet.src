unit u_CoordConverterSimpleLonLat;

interface

uses
  Types,
  t_GeoTypes,
  u_CoordConverterAbstract;

type
  TCoordConverterSimpleLonLat = class(TCoordConverterAbstract)
  protected
    FExct,FRadiusb: Extended;
	  function LonLat2MetrInternal(const ALl: TExtendedPoint): TExtendedPoint; override;
    function LonLat2RelativeInternal(const XY: TExtendedPoint): TExtendedPoint; override; stdcall;
    function Relative2LonLatInternal(const XY: TExtendedPoint): TExtendedPoint; override; stdcall;
  public
    constructor Create(Aradiusa, Aradiusb: Extended);
    function CalcDist(AStart: TExtendedPoint; AFinish: TExtendedPoint): Extended; override;
  end;

implementation

uses
  Math;

{ TCoordConverterSimpleLonLat }

constructor TCoordConverterSimpleLonLat.Create(Aradiusa, Aradiusb: Extended);
begin
  inherited Create;
  FRadiusa := Aradiusa;
  FRadiusb := Aradiusb;
  FExct := sqrt(FRadiusa*FRadiusa - FRadiusb*FRadiusb)/FRadiusa;
  if (Abs(FRadiusa - 6378137) <  1) and (Abs(FRadiusb - 6356752) <  1) then begin
    FProjEPSG := 4326;
    FDatumEPSG := 4326;
    FCellSizeUnits := CELL_UNITS_DEGREES;
  end else begin
    FDatumEPSG := 0;
    FProjEPSG := 0;
    FCellSizeUnits := CELL_UNITS_UNKNOWN;
  end;
end;

function TCoordConverterSimpleLonLat.LonLat2MetrInternal(const ALl: TExtendedPoint): TExtendedPoint;
var
  VLL: TExtendedPoint;
  b,bs:extended;
begin
  VLL := ALL;
  Vll.x:=Vll.x*(Pi/180);
  Vll.y:=Vll.y*(Pi/180);
  result.x:=Fradiusa*Vll.x;

  bs:=FExct*sin(VLl.y);
  b:=Tan((Vll.y+PI/2)/2) * power((1-bs)/(1+bs),(FExct/2));
  result.y:=Fradiusa*Ln(b);
end;

function TCoordConverterSimpleLonLat.CalcDist(AStart,
  AFinish: TExtendedPoint): Extended;
const
  D2R: Double = 0.017453292519943295769236907684886;// ��������� ��� �������������� �������� � �������
var
  fPhimean,fdLambda,fdPhi,fAlpha,fRho,fNu,fR,fz,fTemp,a,e2:Double;
  VStart, VFinish: TExtendedPoint; // ���������� � ��������
begin
  result := 0;
  if (AStart.X = AFinish.X) and (AStart.Y = AFinish.Y) then exit;
  e2 := FExct*FExct;
  a := FRadiusa;

  VStart.X := AStart.X * D2R;
  VStart.Y := AStart.Y * D2R;
  VFinish.X := AFinish.X * D2R;
  VFinish.Y := AFinish.Y * D2R;

  fdLambda := VStart.X - VFinish.X;
  fdPhi := VStart.Y - VFinish.Y;
  fPhimean := (VStart.Y + VFinish.Y) / 2.0;
  fTemp := 1 - e2 * (Power(Sin(fPhimean), 2));
  fRho := (a * (1 - e2)) / Power(fTemp, 1.5);
  fNu := a / (Sqrt(1 - e2 * (Sin(fPhimean) * Sin(fPhimean))));
  fz:=Sqrt(Power(Sin(fdPhi/2),2)+Cos(VFinish.Y)*Cos(VStart.Y)*Power(Sin(fdLambda/2),2));
  fz := 2*ArcSin(fz);
  fAlpha := Cos(VFinish.Y) * Sin(fdLambda) * 1 / Sin(fz);
  fAlpha := ArcSin(fAlpha);
  fR:=(fRho*fNu)/((fRho*Power(Sin(fAlpha),2))+(fNu*Power(Cos(fAlpha),2)));
  result := (fz * fR);
end;

function TCoordConverterSimpleLonLat.LonLat2RelativeInternal(
  const XY: TExtendedPoint): TExtendedPoint;
begin
  Result.x := (0.5 + XY.x / 360);
  Result.y := (0.5 - XY.y / 360);
end;

function TCoordConverterSimpleLonLat.Relative2LonLatInternal(
  const XY: TExtendedPoint): TExtendedPoint;
begin
  Result.X := (XY.x - 0.5) * 360;
  Result.y := -(XY.y - 0.5) * 360;
end;

end.
