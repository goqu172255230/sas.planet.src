{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2016, SAS.Planet development team.                      *}
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

unit u_StorageExportToMBTiles;

interface

uses
  Types,
  Classes,
  SysUtils,
  SQLite3Handler,
  i_BinaryData,
  t_GeoTypes;

const
  cKeyValSep = '=';

type
  TSQLiteStorageBase = class
  private
    FName: string;
    FDescription: string;
    FAttribution: string;
    FImgType: string;
    FImgFormat: string;
    FScheme: string;
    FUseXYZScheme: Boolean;

    FExportPath: string;
    FExportFileName: string;

    FSQLite3DB: TSQLite3DbHandler;
    FSQLiteAvailable: Boolean;

    FFormatSettings: TFormatSettings;
  protected
    procedure InsertMetaKeyVal(const AKey, AValue: string);

    procedure WriteMetadata(const AKeyValList: TStringList);

    function KeyValToStr(
      const AKey, AValue: string;
      const ASep: Char = cKeyValSep
    ): string;

    function GetBoundsStr(const ALonLatRect: TDoubleRect): string;

    function GetCenterStr(
      const ALonLatRect: TDoubleRect;
      const AMinZoom: Byte
    ): string;
  public
    procedure Init(
      const AExportPath: string;
      const AExportFileName: string;
      const AName: string;
      const ADescription: string;
      const AAttribution: string;
      const AIsLayer: Boolean;
      const AImgFormat: string;
      const AUseXYZScheme: Boolean
    );

    procedure Add(
      const ATile: TPoint;
      const AZoom: Byte;
      const AData: IBinaryData
    ); virtual; abstract;

    procedure Open(
      const ALonLatRect: TDoubleRect;
      const AZooms: TByteDynArray
    ); virtual; abstract;

    procedure Close;
  end;

  TSQLiteStorageMBTiles = class(TSQLiteStorageBase)
  public
    procedure Add(
      const ATile: TPoint;
      const AZoom: Byte;
      const AData: IBinaryData
    ); override;

    procedure Open(
      const ALonLatRect: TDoubleRect;
      const AZooms: TByteDynArray
    ); override;
  end;

implementation

uses
  ALString,
  ALSqlite3Wrapper,
  u_GeoFunc;

const
  // metadata
  TABLE_METADATA_DDL = 'CREATE TABLE IF NOT EXISTS metadata (name text, value text)';
  INDEX_METADATA_DDL = 'CREATE UNIQUE INDEX IF NOT EXISTS metadata_idx  ON metadata (name)';
  INSERT_METADATA_SQL = 'INSERT INTO metadata (name, value) VALUES (%s,%s)';

  // tiles
  TABLE_TILES_DDL = 'CREATE TABLE IF NOT EXISTS tiles (zoom_level integer, tile_column integer, tile_row integer, tile_data blob)';
  INDEX_TILES_DDL = 'CREATE INDEX IF NOT EXISTS tiles_idx on tiles (zoom_level, tile_column, tile_row)';
  INSERT_TILES_SQL = 'INSERT OR REPLACE INTO tiles (zoom_level, tile_column, tile_row, tile_data) VALUES (%d,%d,%d,?)';


{ TSQLiteStorageBase }

procedure TSQLiteStorageBase.Init(
  const AExportPath: string;
  const AExportFileName: string;
  const AName: string;
  const ADescription: string;
  const AAttribution: string;
  const AIsLayer: Boolean;
  const AImgFormat: string;
  const AUseXYZScheme: Boolean
);
begin
  FExportPath := AExportPath;
  FExportFileName := AExportFileName;

  FName := AName;
  if FName = '' then begin
    FName := 'Unnamed map';
  end;

  FDescription := ADescription;
  if FDescription = '' then begin
    FDescription := 'Created by SAS.Planet';
  end;

  FAttribution := AAttribution;

  if AIsLayer then begin
    FImgType := 'overlay';
  end else begin
    FImgType := 'baselayer';
  end;

  FImgFormat := AImgFormat;

  FUseXYZScheme := AUseXYZScheme;

  if FUseXYZScheme then begin
    FScheme := 'xyz';
  end else begin
    FScheme := 'tms';
  end;

  FFormatSettings.DecimalSeparator := '.';

  FSQLiteAvailable := FSQLite3DB.Init;
end;

procedure TSQLiteStorageBase.Close;
begin
  if FSQLite3DB.Opened then begin
    FSQLite3DB.Commit;
    FSQLite3DB.Close;
  end;
end;

function TSQLiteStorageBase.KeyValToStr(
  const AKey, AValue: string;
  const ASep: Char
): string;
begin
  Result := AKey + ASep + AValue;
end;

procedure TSQLiteStorageBase.InsertMetaKeyVal(const AKey, AValue: string);
begin
  FSQLite3DB.ExecSQL(
    ALFormat(
      INSERT_METADATA_SQL,
      [ '''' + UTF8Encode(AKey) + '''', '''' + UTF8Encode(AValue) + '''']
    )
  );
end;

procedure TSQLiteStorageBase.WriteMetadata(const AKeyValList: TStringList);
var
  I: Integer;
  VKey, VVal: string;
begin
  FSQLite3DB.BeginTran;
  try
    for I := 0 to AKeyValList.Count - 1 do begin
      VKey := AKeyValList.Names[I];
      VVal := AKeyValList.ValueFromIndex[I];
      InsertMetaKeyVal(VKey, VVal);
    end;
    FSQLite3DB.Commit;
  except
    FSQLite3DB.Rollback;
    raise;
  end;
end;

function TSQLiteStorageBase.GetBoundsStr(const ALonLatRect: TDoubleRect): string;
begin
  Result :=
    Format(
      '%.8f,%.8f,%.8f,%.8f',
      [ALonLatRect.Left, ALonLatRect.Bottom, ALonLatRect.Right, ALonLatRect.Top],
      FFormatSettings
    );
end;

function TSQLiteStorageBase.GetCenterStr(
  const ALonLatRect: TDoubleRect;
  const AMinZoom: Byte
): string;
var
  VRectCenter: TDoublePoint;
begin
  VRectCenter := RectCenter(ALonLatRect);
  Result :=
    Format(
      '%.8f, %.8f, %d',
      [VRectCenter.X, VRectCenter.Y, AMinZoom],
      FFormatSettings
    );
end;

{ TSQLiteStorageMBTiles }

procedure TSQLiteStorageMBTiles.Open(
  const ALonLatRect: TDoubleRect;
  const AZooms: TByteDynArray
);
var
  VFileName: string;
  VMetadata: TStringList;
begin
  if not FSQLiteAvailable then begin
    raise ESQLite3SimpleError.Create('SQLite not available');
  end;

  Close;

  VFileName := FExportPath + FExportFileName;

  if FileExists(VFileName) then begin
    if not DeleteFile(VFileName) then begin
      raise ESQLite3SimpleError.CreateFmt('Can''t delete database: %s', [VFileName]);
    end;
  end;

  FSQLite3Db.OpenW(VFileName);

  FSQLite3DB.SetExclusiveLockingMode;
  FSQLite3DB.ExecSQL('PRAGMA synchronous=OFF');

  FSQLite3DB.ExecSQL(TABLE_TILES_DDL);
  FSQLite3DB.ExecSQL(INDEX_TILES_DDL);

  FSQLite3DB.ExecSQL(TABLE_METADATA_DDL);
  FSQLite3DB.ExecSQL(INDEX_METADATA_DDL);

  VMetadata := TStringList.Create;
  try
    VMetadata.NameValueSeparator := cKeyValSep;

    // base fields of MBTiles format
    // https://github.com/mapbox/mbtiles-spec/blob/master/1.2/spec.md

    // 1.0
    VMetadata.Add( KeyValToStr('name', FName) );
    VMetadata.Add( KeyValToStr('type', FImgType) );
    VMetadata.Add( KeyValToStr('version', '1.2') );
    VMetadata.Add( KeyValToStr('description', FDescription) );

    // 1.1
    VMetadata.Add( KeyValToStr('format', FImgFormat) );
    VMetadata.Add( KeyValToStr('bounds', GetBoundsStr(ALonLatRect)) );

    // 1.2
    VMetadata.Add( KeyValToStr('attribution', FAttribution) );

    // additional fiels from TileJSON standart
    // https://github.com/mapbox/tilejson-spec/tree/master/2.1.0

    VMetadata.Add( KeyValToStr('scheme', FScheme) );
    VMetadata.Add( KeyValToStr('minzoom', IntToStr(AZooms[Low(AZooms)])) );
    VMetadata.Add( KeyValToStr('maxzoom', IntToStr(AZooms[High(AZooms)])) );
    VMetadata.Add( KeyValToStr('center', GetCenterStr(ALonLatRect, AZooms[Low(AZooms)])) );

    WriteMetadata(VMetadata)
  finally
    VMetadata.Free;
  end;

  FSQLite3DB.BeginTran;
end;

procedure TSQLiteStorageMBTiles.Add(
  const ATile: TPoint;
  const AZoom: Byte;
  const AData: IBinaryData
);
var
  X, Y: Integer;
begin
  Assert(AData <> nil);

  X := ATile.X;

  if FUseXYZScheme then begin
    Y := ATile.Y;
  end else begin
    Y := (1 shl AZoom) - ATile.Y - 1;
  end;

  FSQLite3DB.ExecSQLWithBLOB(
    ALFormat(INSERT_TILES_SQL, [AZoom, X, Y]),
    AData.Buffer,
    AData.Size
  );
end;

end.
