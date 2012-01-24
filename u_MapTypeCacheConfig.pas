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

unit u_MapTypeCacheConfig;

interface

uses
  Types,
  i_JclNotify,
  i_SimpleTileStorageConfig,
  i_TileFileNameGeneratorsList,
  u_GlobalCahceConfig,
  u_ETS_Path,
  i_TileFileNameGenerator;

type
  TMapTypeCacheConfigAbstract = class
  private
    FConfig: ISimpleTileStorageConfig;

    FGlobalCacheConfig: TGlobalCahceConfig;
    FGlobalSettingsListener: IJclListener;
    procedure OnSettingsEdit; virtual; abstract;
  protected
    FEffectiveCacheType: Byte;
    FBasePath: String;
    FFileNameGenerator: ITileFileNameGenerator;

    FConfigChangeNotifier: IJclNotifier;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AGlobalCacheConfig: TGlobalCahceConfig
    );
    destructor Destroy; override;
    function GetTileFileName(AXY: TPoint; Azoom: byte): string;

    property ConfigChangeNotifier: IJclNotifier read FConfigChangeNotifier;
  end;

  TMapTypeCacheConfig = class(TMapTypeCacheConfigAbstract)
  private
    FTileNameGeneratorList: ITileFileNameGeneratorsList;
    procedure OnSettingsEdit; override;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AGlobalCacheConfig: TGlobalCahceConfig;
      ATileNameGeneratorList: ITileFileNameGeneratorsList
    );
  end;

  TMapTypeCacheConfigGE = class(TMapTypeCacheConfigAbstract)
  protected
    procedure OnSettingsEdit; override;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AGlobalCacheConfig: TGlobalCahceConfig
    );
    function GetIndexFileName: string;
    function GetDataFileName: string;
    function GetNameInCache: string;
  end;

  TMapTypeCacheConfigBerkeleyDB = class(TMapTypeCacheConfigAbstract)
  protected
    procedure OnSettingsEdit; override;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AFileNameGenerator: ITileFileNameGenerator;
      AGlobalCacheConfig: TGlobalCahceConfig
    );
    function GetTileFileName(AXY: TPoint; Azoom: byte): string; reintroduce;
  end;

  TMapTypeCacheConfigDBMS = class(TMapTypeCacheConfigAbstract)
  protected
    FGlobalStorageIdentifier: String;
    FServiceName: String;
    procedure OnSettingsEdit; override;
  public
    property ServiceName: String read FServiceName;
    property GlobalStorageIdentifier: String read FGlobalStorageIdentifier;
  end;


implementation

uses
  SysUtils,
  u_JclNotify,
  u_NotifyEventListener;

{ TMapTypeCacheConfigAbstract }

constructor TMapTypeCacheConfigAbstract.Create(
  AConfig: ISimpleTileStorageConfig;
  AGlobalCacheConfig: TGlobalCahceConfig
);
begin
  FConfig := AConfig;
  FGlobalCacheConfig := AGlobalCacheConfig;
  FConfigChangeNotifier := TJclBaseNotifier.Create;

  FGlobalSettingsListener := TNotifyNoMmgEventListener.Create(Self.OnSettingsEdit);
  FGlobalCacheConfig.CacheChangeNotifier.Add(FGlobalSettingsListener);
  FConfig.ChangeNotifier.Add(FGlobalSettingsListener);
end;

destructor TMapTypeCacheConfigAbstract.Destroy;
begin
  FConfig.ChangeNotifier.Remove(FGlobalSettingsListener);
  FGlobalCacheConfig.CacheChangeNotifier.Remove(FGlobalSettingsListener);
  FGlobalSettingsListener := nil;

  FConfigChangeNotifier := nil;
  inherited;
end;

function TMapTypeCacheConfigAbstract.GetTileFileName(AXY: TPoint; Azoom: byte): string;
begin
  Result := FBasePath + FFileNameGenerator.GetTileFileName(AXY, Azoom) + FConfig.GetStatic.TileFileExt;
end;

{ TMapTypeCacheConfig }

constructor TMapTypeCacheConfig.Create(
  AConfig: ISimpleTileStorageConfig;
  AGlobalCacheConfig: TGlobalCahceConfig;
  ATileNameGeneratorList: ITileFileNameGeneratorsList
);
begin
  inherited Create(AConfig, AGlobalCacheConfig);
  FTileNameGeneratorList := ATileNameGeneratorList;
  OnSettingsEdit;
end;

procedure TMapTypeCacheConfig.OnSettingsEdit;
var
  VCacheType: Byte;
  VBasePath: string;
  VConfig: ISimpleTileStorageConfigStatic;
begin
  VConfig := FConfig.GetStatic;
  VCacheType := VConfig.CacheTypeCode;
  if VCacheType = 0 then begin
    VCacheType := FGlobalCacheConfig.DefCache;
  end;
  FEffectiveCacheType := VCacheType;
  FFileNameGenerator := FTileNameGeneratorList.GetGenerator(FEffectiveCacheType);

  if (7=FEffectiveCacheType) then begin
    // very special
    FBasePath:=ETS_TilePath_Single(FGlobalCacheConfig.DBMSCachepath, VConfig.NameInCache);
    Exit;
  end;


  VBasePath := VConfig.NameInCache;
  //TODO: � ���� �������� ����� ���-�� ����� �������
  if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
    case FEffectiveCacheType of
      1: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.OldCpath) + VBasePath;
      end;
      2: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.NewCpath)+VBasePath;
      end;
      3: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.ESCpath)+VBasePath;
      end;
      4,41: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.GMTilespath)+VBasePath;
      end;
      5: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.GECachepath)+VBasePath;
      end;
      6: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.BDBCachepath)+VBasePath;
      end;
    end;
  end;
  //TODO: � ���� �������� ����� ���-�� ����� �������
  if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
    VBasePath := IncludeTrailingPathDelimiter(FGlobalCacheConfig.CacheGlobalPath) + VBasePath;
  end;
  VBasePath := IncludeTrailingPathDelimiter(VBasePath);
  FBasePath := VBasePath;
end;

{ TMapTypeCacheConfigGE }

constructor TMapTypeCacheConfigGE.Create(
  AConfig: ISimpleTileStorageConfig;
  AGlobalCacheConfig: TGlobalCahceConfig
);
begin
  inherited Create(AConfig, AGlobalCacheConfig);
  OnSettingsEdit;
end;

procedure TMapTypeCacheConfigGE.OnSettingsEdit;
var
  VBasePath: string;
begin
  VBasePath:=FGlobalCacheConfig.GECachepath;
  //TODO: � ���� �������� ����� ���-�� ����� �������
  if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
    VBasePath := IncludeTrailingPathDelimiter(FGlobalCacheConfig.CacheGlobalPath) + VBasePath;
  end;
  VBasePath := IncludeTrailingPathDelimiter(VBasePath);
  FBasePath := VBasePath;
end;

function TMapTypeCacheConfigGE.GetDataFileName: string;
begin
  Result := FBasePath + 'dbCache.dat';
end;

function TMapTypeCacheConfigGE.GetIndexFileName: string;
begin
  Result := FBasePath + 'dbCache.dat.index';
end;

function TMapTypeCacheConfigGE.GetNameInCache: string;
begin
  Result := FConfig.GetStatic.NameInCache;
end;

{ TMapTypeCacheConfigBerkeleyDB }

constructor TMapTypeCacheConfigBerkeleyDB.Create(
  AConfig: ISimpleTileStorageConfig;
  AFileNameGenerator: ITileFileNameGenerator;
  AGlobalCacheConfig: TGlobalCahceConfig
);
begin
  inherited Create(AConfig, AGlobalCacheConfig);
  FFileNameGenerator := AFileNameGenerator;
  OnSettingsEdit;
end;

procedure TMapTypeCacheConfigBerkeleyDB.OnSettingsEdit;
var
  VBasePath: string;
begin
  VBasePath := FGlobalCacheConfig.BDBCachepath + FConfig.GetStatic.NameInCache;
  //TODO: � ���� �������� ����� ���-�� ����� �������
  if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
    VBasePath := IncludeTrailingPathDelimiter(FGlobalCacheConfig.CacheGlobalPath) + VBasePath;
  end;
  VBasePath := IncludeTrailingPathDelimiter(VBasePath);
  FBasePath := VBasePath;
end;

function TMapTypeCacheConfigBerkeleyDB.GetTileFileName(AXY: TPoint; AZoom: Byte): string;
begin
  Result := FBasePath + FFileNameGenerator.GetTileFileName(AXY, AZoom) + '.sdb';
end;

{ TMapTypeCacheConfigDBMS }

procedure TMapTypeCacheConfigDBMS.OnSettingsEdit;
begin
  FGlobalStorageIdentifier := FGlobalCacheConfig.DBMSCachepath;
  FServiceName := FConfig.GetStatic.NameInCache;
  FBasePath := ETS_TilePath_Single(FGlobalStorageIdentifier, FServiceName);
end;

end.
