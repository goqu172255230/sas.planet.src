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
  SyncObjs,
  i_JclNotify,
  i_SimpleTileStorageConfig,
  i_TileFileNameGeneratorsList,
  u_GlobalCahceConfig,
  u_ETS_Path,
  i_TileFileNameGenerator;

type
  TOnAfterMapSettingsEdit = procedure(Sender: TObject) of object;

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
    function GetTileFileName(AXY: TPoint; Azoom: byte): string; virtual;

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
  private
    FCS: TCriticalSection;
    FNameInCache: String;
    FOnSettingsEdit: TOnAfterMapSettingsEdit;
  protected
    procedure OnSettingsEdit; override;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AGlobalCacheConfig: TGlobalCahceConfig;
      AOnSettingsEdit: TOnAfterMapSettingsEdit
    );
    destructor Destroy; override;

    function GetIndexFileName: string;
    function GetDataFileName: string;
    function GetNameInCache: string;
  end;

  TMapTypeCacheConfigBerkeleyDB = class(TMapTypeCacheConfigAbstract)
  private
    FCS: TCriticalSection;
  protected
    FOnSettingsEdit: TOnAfterMapSettingsEdit;
    procedure OnSettingsEdit; override;
  public
    constructor Create(
      AConfig: ISimpleTileStorageConfig;
      AFileNameGenerator: ITileFileNameGenerator;
      AGlobalCacheConfig: TGlobalCahceConfig;
      AOnSettingsEdit: TOnAfterMapSettingsEdit
    );
    destructor Destroy; override;
    function GetTileFileName(AXY: TPoint; Azoom: byte): string; override;
    property BasePath: string read FBasePath;
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
  Windows,
  SysUtils,
  ShLwApi,
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
  if VCacheType = c_File_Cache_Id_DEFAULT then begin
    VCacheType := FGlobalCacheConfig.DefCache;
  end;
  FEffectiveCacheType := VCacheType;
  FFileNameGenerator := FTileNameGeneratorList.GetGenerator(FEffectiveCacheType);

  if (c_File_Cache_Id_DBMS=FEffectiveCacheType) then begin
    // very special
    FBasePath:=ETS_TilePath_Single(FGlobalCacheConfig.DBMSCachepath, VConfig.NameInCache);
    Exit;
  end;


  VBasePath := VConfig.NameInCache;
  //TODO: � ���� �������� ����� ���-�� ����� �������
  if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
    case FEffectiveCacheType of
      c_File_Cache_Id_GMV: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.OldCpath) + VBasePath;
      end;
      c_File_Cache_Id_SAS: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.NewCpath)+VBasePath;
      end;
      c_File_Cache_Id_ES: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.ESCpath)+VBasePath;
      end;
      c_File_Cache_Id_GM,c_File_Cache_Id_GM_Aux: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.GMTilespath)+VBasePath;
      end;
      c_File_Cache_Id_GE: begin
        VBasePath:=IncludeTrailingPathDelimiter(FGlobalCacheConfig.GECachepath)+VBasePath;
      end;
      c_File_Cache_Id_BDB: begin
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
  AGlobalCacheConfig: TGlobalCahceConfig;
  AOnSettingsEdit: TOnAfterMapSettingsEdit
);
begin
  inherited Create(AConfig, AGlobalCacheConfig);
  FCS := TCriticalSection.Create;
  FOnSettingsEdit := AOnSettingsEdit;
  OnSettingsEdit;
end;

procedure TMapTypeCacheConfigGE.OnSettingsEdit;
var
  VBasePath: string;
begin
  FCS.Acquire;
  try
    // current GE cache path
    FNameInCache := FConfig.GetStatic.NameInCache;
    if (Length(FNameInCache) > 0) then
      if (FNameInCache[Length(FNameInCache)] <> PathDelim) then
        FNameInCache := FNameInCache + PathDelim;

    // global GE cache path
    VBasePath:=FGlobalCacheConfig.GECachepath;
    //TODO: � ���� �������� ����� ���-�� ����� �������
    if (length(VBasePath) < 2) or ((VBasePath[2] <> '\') and (system.pos(':', VBasePath) = 0)) then begin
      VBasePath := IncludeTrailingPathDelimiter(FGlobalCacheConfig.CacheGlobalPath) + VBasePath;
    end;
    VBasePath := IncludeTrailingPathDelimiter(VBasePath);
    FBasePath := VBasePath;

    if Assigned(FOnSettingsEdit) then begin
      FOnSettingsEdit(Self);
    end;
  finally
    FCS.Release;
  end;
end;

destructor TMapTypeCacheConfigGE.Destroy;
begin
  FreeAndNil(FCS);
  inherited Destroy;
end;

function TMapTypeCacheConfigGE.GetDataFileName: string;
begin
  Result := GetNameInCache + 'dbCache.dat';
end;

function TMapTypeCacheConfigGE.GetIndexFileName: string;
begin
  Result := GetNameInCache + 'dbCache.dat.index';
end;

function TMapTypeCacheConfigGE.GetNameInCache: string;
begin
  FCS.Acquire;
  try
    Result := FNameInCache;
    if (0=Length(Result)) then
      Result := FBasePath;
  finally
    FCS.Release;
  end;
end;

{ TMapTypeCacheConfigBerkeleyDB }

constructor TMapTypeCacheConfigBerkeleyDB.Create(
  AConfig: ISimpleTileStorageConfig;
  AFileNameGenerator: ITileFileNameGenerator;
  AGlobalCacheConfig: TGlobalCahceConfig;
  AOnSettingsEdit: TOnAfterMapSettingsEdit
);
begin
  inherited Create(AConfig, AGlobalCacheConfig);
  FCS := TCriticalSection.Create;
  FFileNameGenerator := AFileNameGenerator;
  FOnSettingsEdit := AOnSettingsEdit;
  OnSettingsEdit;
end;

destructor TMapTypeCacheConfigBerkeleyDB.Destroy;
begin
  FCS.Free;
  inherited Destroy;
end;

procedure TMapTypeCacheConfigBerkeleyDB.OnSettingsEdit;

  function RelativeToAbsolutePath(const ABasePath, ARelativePath: string): string;
  begin
    SetLength(Result, MAX_PATH);
    PathCombine(@Result[1], PChar(ABasePath), PChar(ARelativePath));
    SetLength(Result, StrLen(@Result[1]));
  end;

var
  VBasePath: string;
  VCachePath: string;
begin
  FCS.Acquire;
  try
    VBasePath := FConfig.GetStatic.NameInCache;
    if PathIsRelative(PAnsiChar(VBasePath)) then begin
      VCachePath := IncludeTrailingPathDelimiter(FGlobalCacheConfig.BDBCachepath);
      if PathIsRelative(PAnsiChar(VCachePath)) then begin
        VCachePath := RelativeToAbsolutePath(
          IncludeTrailingPathDelimiter(FGlobalCacheConfig.CacheGlobalPath),
          VCachePath
        );
      end;
      VBasePath := RelativeToAbsolutePath(VCachePath, VBasePath);
    end;
    FBasePath := IncludeTrailingPathDelimiter(VBasePath);
    if Addr(FOnSettingsEdit) <> nil then begin
      FOnSettingsEdit(Self);
    end;
  finally
    FCS.Release;
  end;
end;

function TMapTypeCacheConfigBerkeleyDB.GetTileFileName(AXY: TPoint; AZoom: Byte): string;
begin
  FCS.Acquire;
  try
    Result := FBasePath + FFileNameGenerator.GetTileFileName(AXY, AZoom) + '.sdb';
  finally
    FCS.Release;
  end;
end;

{ TMapTypeCacheConfigDBMS }

procedure TMapTypeCacheConfigDBMS.OnSettingsEdit;
begin
  FGlobalStorageIdentifier := FGlobalCacheConfig.DBMSCachepath;
  FServiceName := FConfig.GetStatic.NameInCache;
  FBasePath := ETS_TilePath_Single(FGlobalStorageIdentifier, FServiceName);
end;

end.
