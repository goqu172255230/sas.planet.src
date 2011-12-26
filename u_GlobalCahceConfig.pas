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

unit u_GlobalCahceConfig;

interface

uses
  i_JclNotify,
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider;

type
  TGlobalCahceConfig = class
  private
    FCacheGlobalPath: string;

    //������ ������� ���� ��-���������.
    FDefCache: byte;

    //���� � ����� ������ �����
    FNewCPath: string;
    FOldCPath: string;
    FESCpath: string;
    FGMTilespath: string;
    FGECachepath: string;
    FBDBCachepath: string;

    FCacheChangeNotifier: IJclNotifier;
    procedure SetDefCache(const Value: byte);
    procedure SetESCpath(const Value: string);
    procedure SetGECachepath(const Value: string);
    procedure SetBDBCachepath(const Value: string);
    procedure SetGMTilespath(const Value: string);
    procedure SetNewCPath(const Value: string);
    procedure SetOldCPath(const Value: string);
  public
    constructor Create(
      ACacheGlobalPath: string
    );
    destructor Destroy; override;

    procedure LoadConfig(AConfigProvider: IConfigDataProvider);
    procedure SaveConfig(AConfigProvider: IConfigDataWriteProvider);

    //������ ������� ���� ��-���������.
    property DefCache: byte read FDefCache write SetDefCache;

    //���� � ����� ������ �����
    property NewCPath: string read FNewCPath write SetNewCPath;
    property OldCPath: string read FOldCPath write SetOldCPath;
    property ESCpath: string read FESCpath write SetESCpath;
    property GMTilespath: string read FGMTilespath write SetGMTilespath;
    property GECachepath: string read FGECachepath write SetGECachepath;
    property BDBCachepath: string read FBDBCachepath write SetBDBCachepath;

    property  CacheGlobalPath: string read FCacheGlobalPath;
    property CacheChangeNotifier: IJclNotifier read FCacheChangeNotifier;
  end;

implementation

uses
  SysUtils,
  u_JclNotify;

{ TGlobalCahceConfig }

constructor TGlobalCahceConfig.Create(
  ACacheGlobalPath: string
);
begin
  FCacheGlobalPath := ACacheGlobalPath;
  FDefCache := 2;
  FCacheChangeNotifier := TJclBaseNotifier.Create;
  FOldCpath := 'cache_old' + PathDelim;
  FNewCpath := 'cache' + PathDelim;
  FESCpath := 'cache_ES' + PathDelim;
  FGMTilesPath := 'cache_gmt' + PathDelim;
  FGECachePath := 'cache_GE' + PathDelim;
  FBDBCachePath := 'cache_db' + PathDelim;
end;

destructor TGlobalCahceConfig.Destroy;
begin
  FCacheChangeNotifier := nil;
  inherited;
end;

procedure TGlobalCahceConfig.LoadConfig(AConfigProvider: IConfigDataProvider);
var
  VViewConfig: IConfigDataProvider;
  VPathConfig: IConfigDataProvider;
begin
  VViewConfig := AConfigProvider.GetSubItem('VIEW');
  if VViewConfig <> nil then begin
    DefCache := VViewConfig.ReadInteger('DefCache', FDefCache);
  end;

  VPathConfig := AConfigProvider.GetSubItem('PATHtoCACHE');
  if VPathConfig <> nil then begin
    OldCpath := VPathConfig.ReadString('GMVC', OldCpath);
    NewCpath := VPathConfig.ReadString('SASC', NewCpath);
    ESCpath := VPathConfig.ReadString('ESC', ESCpath);
    GMTilesPath := VPathConfig.ReadString('GMTiles', GMTilesPath);
    GECachePath := VPathConfig.ReadString('GECache', GECachePath);
    BDBCachePath := VPathConfig.ReadString('BDBCache', BDBCachePath);
  end;
end;

procedure TGlobalCahceConfig.SaveConfig(
  AConfigProvider: IConfigDataWriteProvider);
var
  VViewConfig: IConfigDataWriteProvider;
  VPathConfig: IConfigDataWriteProvider;
begin
  VViewConfig := AConfigProvider.GetOrCreateSubItem('VIEW');
  VPathConfig := AConfigProvider.GetOrCreateSubItem('PATHtoCACHE');
  VViewConfig.WriteInteger('DefCache', FDefCache);

  VPathConfig.WriteString('GMVC', OldCpath);
  VPathConfig.WriteString('SASC', NewCpath);
  VPathConfig.WriteString('ESC', ESCpath);
  VPathConfig.WriteString('GMTiles', GMTilesPath);
  VPathConfig.WriteString('GECache', GECachePath);
  VPathConfig.WriteString('BDBCache', BDBCachePath);
end;

procedure TGlobalCahceConfig.SetDefCache(const Value: byte);
begin
  if Value in [1, 2, 3, 4, 41, 6] then begin
    if FDefCache <> Value then begin
      FDefCache := Value;
      FCacheChangeNotifier.Notify(nil);
    end;
  end;
end;

procedure TGlobalCahceConfig.SetESCpath(const Value: string);
begin
  if FESCpath <> Value then begin
    FESCpath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

procedure TGlobalCahceConfig.SetGECachepath(const Value: string);
begin
  if FGECachepath <> Value then begin
    FGECachepath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

procedure TGlobalCahceConfig.SetBDBCachepath(const Value: string);
begin
  if FBDBCachepath <> Value then begin
    FBDBCachepath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

procedure TGlobalCahceConfig.SetGMTilespath(const Value: string);
begin
  if FGMTilespath <> Value then begin
    FGMTilespath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

procedure TGlobalCahceConfig.SetNewCPath(const Value: string);
begin
  if FNewCPath <> Value then begin
    FNewCPath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

procedure TGlobalCahceConfig.SetOldCPath(const Value: string);
begin
  if FOldCPath <> Value then begin
    FOldCPath := Value;
    FCacheChangeNotifier.Notify(nil);
  end;
end;

end.
