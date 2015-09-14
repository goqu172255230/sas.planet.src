{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2014, SAS.Planet development team.                      *}
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
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit u_CoordConverterFactorySimple;

interface

uses
  i_Datum,
  i_HashFunction,
  i_CoordConverter,
  i_ProjectionType,
  i_ProjectionSet,
  i_ConfigDataProvider,
  i_CoordConverterFactory,
  u_BaseInterfacedObject;

type
  TProjectionTypeFactorySimple = class(TBaseInterfacedObject, IProjectionTypeFactory)
  private
    FHashFunction: IHashFunction;
    FDatumFactory: IDatumFactory;

    FGoogle: IProjectionType;
    FYandex: IProjectionType;
    FLonLat: IProjectionType;
    FEPSG53004: IProjectionType;
  private
    function GetByConfig(const AConfig: IConfigDataProvider): IProjectionType;
    function GetByCode(
      AProjectionEPSG: Integer
    ): IProjectionType;
  public
    constructor Create(
      const AHashFunction: IHashFunction;
      const ADatumFactory: IDatumFactory
    );
  end;


  TCoordConverterFactorySimple = class(TBaseInterfacedObject, IProjectionSetFactory)
  private
    FHashFunction: IHashFunction;
    FDatumFactory: IDatumFactory;

    FGoogle: ICoordConverter;
    FYandex: ICoordConverter;
    FLonLat: ICoordConverter;
    FEPSG53004: ICoordConverter;

    FProjectionSetGoogle: IProjectionSet;
    FProjectionSetYandex: IProjectionSet;
    FProjectionSetLonLat: IProjectionSet;
    function CreateProjectionSet(const AConverter: ICoordConverter): IProjectionSet;
  private
    function GetCoordConverterByConfig(const AConfig: IConfigDataProvider): ICoordConverter;
    function GetCoordConverterByCode(
      AProjectionEPSG: Integer;
      ATileSplitCode: Integer
    ): ICoordConverter;
  private
    function GetProjectionSetByConfig(const AConfig: IConfigDataProvider): IProjectionSet;
    function GetProjectionSetByCode(
      AProjectionEPSG: Integer;
      ATileSplitCode: Integer
    ): IProjectionSet;
  public
    constructor Create(
      const AHashFunction: IHashFunction;
      const ADatumFactory: IDatumFactory
    );
  end;

implementation

uses
  SysUtils,
  t_Hash,
  c_CoordConverter,
  i_InterfaceListSimple,
  i_ProjectionInfo,
  u_InterfaceListSimple,
  u_CoordConverterMercatorOnSphere,
  u_CoordConverterMercatorOnEllipsoid,
  u_CoordConverterSimpleLonLat,
  u_ProjectionTypeMercatorOnSphere,
  u_ProjectionTypeMercatorOnEllipsoid,
  u_ProjectionTypeGELonLat,
  u_ProjectionInfo,
  u_ProjectionSetSimple,
  u_ResStrings;

{ TCoordConverterFactorySimple }

constructor TCoordConverterFactorySimple.Create(
  const AHashFunction: IHashFunction;
  const ADatumFactory: IDatumFactory
);
var
  VHash: THashValue;
  VDatum: IDatum;
begin
  inherited Create;
  FHashFunction := AHashFunction;
  FDatumFactory := ADatumFactory;

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(CGoogleDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGoogleProjectionEPSG);
  FGoogle := TCoordConverterMercatorOnSphere.Create(VHash, VDatum, CGoogleProjectionEPSG);
  FProjectionSetGoogle := CreateProjectionSet(FGoogle);

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(53004);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, 53004);
  FEPSG53004 := TCoordConverterMercatorOnSphere.Create(VHash, VDatum, 53004);

  VHash := FHashFunction.CalcHashByInteger(2);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CYandexProjectionEPSG);
  FYandex := TCoordConverterMercatorOnEllipsoid.Create(VHash, VDatum, CYandexProjectionEPSG);
  FProjectionSetYandex := CreateProjectionSet(FYandex);

  VHash := FHashFunction.CalcHashByInteger(3);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGELonLatProjectionEPSG);
  FLonLat := TCoordConverterSimpleLonLat.Create(VHash, VDatum, CGELonLatProjectionEPSG);
  FProjectionSetLonLat := CreateProjectionSet(FLonLat);
end;

function TCoordConverterFactorySimple.CreateProjectionSet(
  const AConverter: ICoordConverter
): IProjectionSet;
var
  VZooms: IInterfaceListSimple;
  i: Integer;
  VHash: THashValue;
  VProjection: IProjectionInfo;
begin
  VZooms := TInterfaceListSimple.Create;
  VZooms.Capacity := 24;

  for i := 0 to 24 - 1 do begin
    VHash := AConverter.Hash;
    FHashFunction.UpdateHashByInteger(VHash, i);
    VProjection := TProjectionInfo.Create(VHash, AConverter, i);
    VZooms.Add(VProjection);
  end;
  Result :=
    TProjectionSetSimple.Create(
      AConverter.Hash,
      VZooms.MakeStaticAndClear
    );
end;

function TCoordConverterFactorySimple.GetCoordConverterByCode(
  AProjectionEPSG, ATileSplitCode: Integer
): ICoordConverter;
begin
  Result := nil;
  if ATileSplitCode = CTileSplitQuadrate256x256 then begin
    case AProjectionEPSG of
      CGoogleProjectionEPSG: begin
        Result := FGoogle;
      end;
      53004: begin
        Result := FEPSG53004;
      end;
      CYandexProjectionEPSG: begin
        Result := FYandex;
      end;
      CGELonLatProjectionEPSG: begin
        Result := FLonLat;
      end;
    else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(AProjectionEPSG)]);
    end;
    end;
  end else begin
    raise Exception.Create('����������� ��� ���������� ����� �� �����');
  end;
end;

function TCoordConverterFactorySimple.GetCoordConverterByConfig(
  const AConfig: IConfigDataProvider
): ICoordConverter;
var
  VProjection: byte;
  VRadiusA: Double;
  VRadiusB: Double;
  VEPSG: Integer;
  VTileSplitCode: Integer;
  VDatum: IDatum;
  VHash: THashValue;
begin
  Result := nil;
  VTileSplitCode := CTileSplitQuadrate256x256;
  VEPSG := 0;
  VProjection := 1;
  VRadiusA := 6378137;
  VRadiusB := VRadiusA;

  if AConfig <> nil then begin
    VEPSG := AConfig.ReadInteger('EPSG', VEPSG);
    VProjection := AConfig.ReadInteger('projection', VProjection);
    VRadiusA := AConfig.ReadFloat('sradiusa', VRadiusA);
    VRadiusB := AConfig.ReadFloat('sradiusb', VRadiusA);
  end;

  if VEPSG = 0 then begin
    case VProjection of
      1: begin
        if Abs(VRadiusA - 6378137) < 1 then begin
          VEPSG := CGoogleProjectionEPSG;
        end else if Abs(VRadiusA - 6371000) < 1 then begin
          VEPSG := 53004;
        end;
      end;
      2: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CYandexProjectionEPSG;
        end;
      end;
      3: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CGELonLatProjectionEPSG;
        end;
      end else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;

  if VEPSG <> 0 then begin
    try
      Result := GetCoordConverterByCode(VEPSG, VTileSplitCode);
    except
      Result := nil;
    end;
  end;

  if Result = nil then begin
    case VProjection of
      1: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusA);
        if VDatum.EPSG = CGoogleDatumEPSG then begin
          Result := FGoogle;
        end else if VDatum.EPSG = 53004 then begin
          Result := FEPSG53004;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(1);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TCoordConverterMercatorOnSphere.Create(VHash, VDatum, 0);
        end;
      end;
      2: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FYandex;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(2);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TCoordConverterMercatorOnEllipsoid.Create(VHash, VDatum, 0);
        end;
      end;
      3: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FLonLat;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(3);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TCoordConverterSimpleLonLat.Create(VHash, VDatum, 0);
        end;
      end;
    else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;
end;

function TCoordConverterFactorySimple.GetProjectionSetByCode(
  AProjectionEPSG, ATileSplitCode: Integer
): IProjectionSet;
var
  VConverter: ICoordConverter;
begin
  VConverter := GetCoordConverterByCode(AProjectionEPSG, ATileSplitCode);
  case VConverter.ProjectionType.ProjectionEPSG of
    CGoogleProjectionEPSG: begin
      Result := FProjectionSetGoogle;
    end;
    CYandexProjectionEPSG: begin
      Result := FProjectionSetYandex;
    end;
    CGELonLatProjectionEPSG: begin
      Result := FProjectionSetLonLat;
    end;
  else begin
    Result := CreateProjectionSet(VConverter);
  end;
  end;
end;

function TCoordConverterFactorySimple.GetProjectionSetByConfig(
  const AConfig: IConfigDataProvider
): IProjectionSet;
var
  VConverter: ICoordConverter;
begin
  VConverter := GetCoordConverterByConfig(AConfig);
  case VConverter.ProjectionType.ProjectionEPSG of
    CGoogleProjectionEPSG: begin
      Result := FProjectionSetGoogle;
    end;
    CYandexProjectionEPSG: begin
      Result := FProjectionSetYandex;
    end;
    CGELonLatProjectionEPSG: begin
      Result := FProjectionSetLonLat;
    end;
  else begin
    Result := CreateProjectionSet(VConverter);
  end;
  end;
end;

{ TProjectionTypeFactorySimple }

constructor TProjectionTypeFactorySimple.Create(
  const AHashFunction: IHashFunction;
  const ADatumFactory: IDatumFactory
);
var
  VHash: THashValue;
  VDatum: IDatum;
begin
  inherited Create;
  FHashFunction := AHashFunction;
  FDatumFactory := ADatumFactory;

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(CGoogleDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGoogleProjectionEPSG);
  FGoogle := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, CGoogleProjectionEPSG);

  VHash := FHashFunction.CalcHashByInteger(1);
  VDatum := FDatumFactory.GetByCode(53004);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, 53004);
  FEPSG53004 := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, 53004);

  VHash := FHashFunction.CalcHashByInteger(2);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CYandexProjectionEPSG);
  FYandex := TProjectionTypeMercatorOnEllipsoid.Create(VHash, VDatum, CYandexProjectionEPSG);

  VHash := FHashFunction.CalcHashByInteger(3);
  VDatum := FDatumFactory.GetByCode(CYandexDatumEPSG);
  FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
  FHashFunction.UpdateHashByInteger(VHash, CGELonLatProjectionEPSG);
  FLonLat := TProjectionTypeGELonLat.Create(VHash, VDatum, CGELonLatProjectionEPSG);
end;

function TProjectionTypeFactorySimple.GetByCode(
  AProjectionEPSG: Integer
): IProjectionType;
begin
  Result := nil;
  case AProjectionEPSG of
    CGoogleProjectionEPSG: begin
      Result := FGoogle;
    end;
    53004: begin
      Result := FEPSG53004;
    end;
    CYandexProjectionEPSG: begin
      Result := FYandex;
    end;
    CGELonLatProjectionEPSG: begin
      Result := FLonLat;
    end;
  else begin
    raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(AProjectionEPSG)]);
  end;
  end;
end;

function TProjectionTypeFactorySimple.GetByConfig(
  const AConfig: IConfigDataProvider
): IProjectionType;
var
  VProjection: byte;
  VRadiusA: Double;
  VRadiusB: Double;
  VEPSG: Integer;
  VDatum: IDatum;
  VHash: THashValue;
begin
  Result := nil;
  VEPSG := 0;
  VProjection := 1;
  VRadiusA := 6378137;
  VRadiusB := VRadiusA;

  if AConfig <> nil then begin
    VEPSG := AConfig.ReadInteger('EPSG', VEPSG);
    VProjection := AConfig.ReadInteger('projection', VProjection);
    VRadiusA := AConfig.ReadFloat('sradiusa', VRadiusA);
    VRadiusB := AConfig.ReadFloat('sradiusb', VRadiusA);
  end;

  if VEPSG = 0 then begin
    case VProjection of
      1: begin
        if Abs(VRadiusA - 6378137) < 1 then begin
          VEPSG := CGoogleProjectionEPSG;
        end else if Abs(VRadiusA - 6371000) < 1 then begin
          VEPSG := 53004;
        end;
      end;
      2: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CYandexProjectionEPSG;
        end;
      end;
      3: begin
        if (Abs(VRadiusA - 6378137) < 1) and (Abs(VRadiusB - 6356752) < 1) then begin
          VEPSG := CGELonLatProjectionEPSG;
        end;
      end else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;

  if VEPSG <> 0 then begin
    try
      Result := GetByCode(VEPSG);
    except
      Result := nil;
    end;
  end;

  if Result = nil then begin
    case VProjection of
      1: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusA);
        if VDatum.EPSG = CGoogleDatumEPSG then begin
          Result := FGoogle;
        end else if VDatum.EPSG = 53004 then begin
          Result := FEPSG53004;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(1);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeMercatorOnSphere.Create(VHash, VDatum, 0);
        end;
      end;
      2: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FYandex;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(2);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeMercatorOnEllipsoid.Create(VHash, VDatum, 0);
        end;
      end;
      3: begin
        VDatum := FDatumFactory.GetByRadius(VRadiusA, VRadiusB);
        if VDatum.EPSG = CYandexDatumEPSG then begin
          Result := FLonLat;
        end else begin
          VHash := FHashFunction.CalcHashByInteger(3);
          FHashFunction.UpdateHashByHash(VHash, VDatum.Hash);
          FHashFunction.UpdateHashByInteger(VHash, 0);
          Result := TProjectionTypeGELonLat.Create(VHash, VDatum, 0);
        end;
      end;
    else begin
      raise Exception.CreateFmt(SAS_ERR_MapProjectionUnexpectedType, [IntToStr(VProjection)]);
    end;
    end;
  end;
end;

end.
