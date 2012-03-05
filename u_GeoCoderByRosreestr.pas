{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2011, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_GeoCoderByRosreestr;

interface

uses
  Classes,
  i_CoordConverter,
  u_GeoCoderBasic;

type
  TGeoCoderByRosreestr = class(TGeoCoderBasic)
  protected
    function PrepareURL(ASearch: WideString): string; override;
    function ParseStringToPlacemarksList(AStr: string; ASearch: WideString): IInterfaceList; override;
  public
  end;

implementation

uses
  SysUtils,
  StrUtils,
  RegExprUtils,
  t_GeoTypes,
  i_GeoCoder,
  u_ResStrings,
  u_GeoCodePlacemark;

{ TGeoCoderByRosreestr }
procedure meters_to_lonlat( in_x,in_y : Double; var outout : TDoublePoint);
const
 pi = 3.1415926535897932384626433832795;
begin
  outout.X := in_X/6378137*180/pi;
  outout.Y := ((arctan(exp(in_Y/6378137))-pi/4)*360)/pi;
end;

function TGeoCoderByRosreestr.ParseStringToPlacemarksList(
  AStr: string; ASearch: WideString): IInterfaceList;

var
  slat, slon, sname, sdesc, sfulldesc, VtempString: string;
  i, j : integer;
  VPoint: TDoublePoint;
  VPlace: IGeoCodePlacemark;
  VList: IInterfaceList;
  VFormatSettings: TFormatSettings;

begin
  sfulldesc := '';
  sdesc := '';
  VtempString:= '';
  if AStr = '' then begin
    raise EParserError.Create(SAS_ERR_EmptyServerResponse);
  end;

  VFormatSettings.DecimalSeparator := '.';
  VList := TInterfaceList.Create;
  i:=PosEx('_jsonpCallback', AStr);
  AStr := ReplaceStr(AStr,'\"','''');
  AStr := ReplaceStr(AStr,'\/','/');
  //�� ������������ ������
  while (PosEx('{"attributes"', AStr, i) > i)and(i>0) do begin
    j := PosEx('{"attributes"', AStr, i);
    sdesc := '';

    i := PosEx('"PARCELID":"', AStr, j);
    j := PosEx('"', AStr, i + 12);
    sname:= Utf8ToAnsi(Copy(AStr, i + 12, j - (i + 12)));
    sname:=copy(sname,1,2)+':'+copy(sname,3,2)+':'+copy(sname,5,7)+':'+copy(sname,13,5);

    i := PosEx('"FULLADDRESS":"', AStr, j);
    j := PosEx('"', AStr, i + 15);
    sdesc:= sdesc + Utf8ToAnsi(Copy(AStr, i + 15, j - (i + 15)));

    i := PosEx('"UTILIZATION_BYDOCUMENT":"', AStr, j);
    if i>j then begin
     j := PosEx('"', AStr, i + 27);
     VtempString := Utf8ToAnsi(Copy(AStr, i + 27, j - (i + 27)));
     if VtempString <> ':null,' then sdesc := sdesc +' '+ VtempString;
    end;

    i := PosEx('"CATEGORY":"', AStr, j);
    if i>j then begin
     j := PosEx('"', AStr, i + 12);
     VtempString := Utf8ToAnsi(Copy(AStr, i + 12, j - (i + 12)));
     if VtempString <> ':null,' then sdesc := sdesc +' '+ VtempString;
    end;

    i := PosEx('"x":', AStr, j);
    j := PosEx('.', AStr, i + 4 );
    slon := Copy(AStr, i + 4, j - (i + 4));

    i := PosEx('"y":', AStr, j);
    j := PosEx('.', AStr, i + 4 );
    slat := Copy(AStr, i + 4, j - (i + 4));


    try
      meters_to_lonlat(StrToFloat(slon, VFormatSettings),StrToFloat(slat, VFormatSettings),Vpoint);
    except
      raise EParserError.CreateFmt(SAS_ERR_CoordParseError, [slat, slon]);
    end;
    i := (PosEx('}}', AStr, i));
    VPlace := TGeoCodePlacemark.Create(VPoint, sname, sdesc, sfulldesc, 4);
    VList.Add(VPlace);
  end;

  // �� ������������
  while (PosEx('address', AStr, i) > i)and(i>0) do begin
    j := i;

    i := PosEx('"address":"', AStr, j);
    j := PosEx('"', AStr, i + 11);
    sname:= Utf8ToAnsi(Copy(AStr, i + 11, j - (i + 11)));

    i := PosEx('"x":', AStr, j);
    j := PosEx('.', AStr, i + 4 );
    slon := Copy(AStr, i + 4, j - (i + 4));

    i := PosEx('"y":', AStr, j);
    j := PosEx('.', AStr, i + 4 );
    slat := Copy(AStr, i + 4, j - (i + 4));

    i := PosEx('"ParentName":"', AStr, j);
    j := PosEx('"', AStr, i + 14);
    sdesc:=Utf8ToAnsi(Copy(AStr, i + 14, j - (i + 14)));
    try
      meters_to_lonlat(StrToFloat(slon, VFormatSettings),StrToFloat(slat, VFormatSettings),Vpoint);
    except
      raise EParserError.CreateFmt(SAS_ERR_CoordParseError, [slat, slon]);
    end;
    i := (PosEx('}}', AStr, i));
    VPlace := TGeoCodePlacemark.Create(VPoint, sname, sdesc, sfulldesc, 4);
    VList.Add(VPlace);
  end;
  Result := VList;
end;

function TGeoCoderByRosreestr.PrepareURL(ASearch: WideString): string;
var
  VSearch: String;
  VConverter: ICoordConverter;
  VZoom: Byte;
  VMapRect: TDoubleRect;
  VLonLatRect: TDoubleRect;
  i: integer;
  S1, S2, S3, S4: string;
begin
  VSearch := ASearch;
  VConverter:=FLocalConverter.GetGeoConverter;
  VZoom := FLocalConverter.GetZoom;
  VMapRect := FLocalConverter.GetRectInMapPixelFloat;
  VConverter.CheckPixelRectFloat(VMapRect, VZoom);
  VLonLatRect := VConverter.PixelRectFloat2LonLatRect(VMapRect, VZoom);
  VSearch := ReplaceStr(ReplaceStr(VSearch,'*',''),':','');// ������� * � : �� ������ ������������ ������

  if ''= RegExprReplaceMatchSubStr(VSearch,'[0-9]','') then begin //cadastre number
   VSearch := ASearch;
   i := PosEx(':', VSearch, 1);
   s1 := copy(VSearch,1,i-1);
   VSearch := copy(VSearch,i+1,length(VSearch)-i+1);

   i := PosEx(':', VSearch, 1);
   s2 := copy(VSearch,1,i-1);
   VSearch := copy(VSearch,i+1,length(VSearch)-i+1);

   i := PosEx(':', VSearch, 1);
   s3 := copy(VSearch,1,i-1);
   VSearch := copy(VSearch,i+1,length(VSearch)-i+1);

   s4 := VSearch;

   if ''= RegExprReplaceMatchSubStr(s1,'[0-9]','') then while length(s1)<2 do s1:='0'+s1;
   if ''= RegExprReplaceMatchSubStr(s2,'[0-9]','') then while length(s2)<2 do s2:='0'+s2;
   if ''= RegExprReplaceMatchSubStr(s3,'[0-9]','') then while length(s3)<7 do s3:='0'+s3;
   if ''= RegExprReplaceMatchSubStr(s4,'[0-9]','') then while length(s4)<5 do s4:='0'+s4;

   VSearch := s1+s2+s3+s4;
   VSearch := ReplaceStr(VSearch,'*','');// ������� * �� ������ ������������ ������

   if ''= RegExprReplaceMatchSubStr(VSearch,'[0-9]','') then
    Result := 'http://maps.rosreestr.ru/ArcGIS/rest/services/Cadastre/CadastreInfo/MapServer/2/query?f=json&where=PARCELID%20like%20'''+URLEncode(AnsiToUtf8(VSearch))+'%25''&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&callback=dojo.io.script.jsonp_dojoIoScript17._jsonpCallback'
   else
    Result := 'http://maps.rosreestr.ru/ArcGIS/rest/services/Cadastre/CadastreInfo/MapServer/2/query?f=json&where=PARCELID%20like%20'''+URLEncode(AnsiToUtf8(VSearch))+'%25''&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&callback=dojo.io.script.jsonp_dojoIoScript27._jsonpCallback';

  end else begin //name
   VSearch := ASearch;
   Result := 'http://maps.rosreestr.ru/ArcGIS/rest/services/Address/Locator_Composite/GeocodeServer/findAddressCandidates?SingleLine='+URLEncode(AnsiToUtf8(VSearch))+'&f=json&outFields=*&callback=dojo.io.script.jsonp_dojoIoScript10._jsonpCallback';
  end;

//  http://maps.rosreestr.ru/ArcGIS/rest/services/Cadastre/CadastreInfo/MapServer/2/query?f=json&where=PARCELID%20like%20'23430116030%25'&returnGeometry=true&spatialRel=esriSpatialRelIntersects&outFields=*&callback=dojo.io.script.jsonp_dojoIoScript17._jsonpCallback
//  http://maps.rosreestr.ru/ArcGIS/rest/services/Address/Locator_Composite/GeocodeServer/findAddressCandidates?SingleLine=%D0%BD%D0%BE%D0%B2%D1%8B%D0%B9&f=json&outFields=*&callback=dojo.io.script.jsonp_dojoIoScript10._jsonpCallback
end;

end.