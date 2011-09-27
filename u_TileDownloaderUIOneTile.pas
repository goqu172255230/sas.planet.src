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

unit u_TileDownloaderUIOneTile;

interface

uses
  Windows,
  Classes,
  Types,
  i_TileError,
  i_DownloadInfoSimple,
  u_TileDownloaderThreadBase,
  u_MapType;

type
  TTileDownloaderUIOneTile = class(TTileDownloaderThreadBase)
  private
    FMapTileUpdateEvent: TMapTileUpdateEvent;
    FErrorLogger: ITileErrorLogger;
    FDownloadInfo: IDownloadInfoSimple;
    FLoadXY: TPoint;

    procedure AfterWriteToFile;
  protected
    procedure Execute; override;
  public
    constructor Create(
      AXY: TPoint;
      AZoom: byte;
      AMapType: TMapType;
      ADownloadInfo: IDownloadInfoSimple;
      AMapTileUpdateEvent: TMapTileUpdateEvent;
      AErrorLogger: ITileErrorLogger
    ); overload;
  end;

implementation

uses
  SysUtils,
  i_DownloadResult,
  u_TileErrorInfo,
  u_ResStrings;

constructor TTileDownloaderUIOneTile.Create(
  AXY: TPoint;
  AZoom: byte;
  AMapType: TMapType;
  ADownloadInfo: IDownloadInfoSimple;
  AMapTileUpdateEvent: TMapTileUpdateEvent;
  AErrorLogger: ITileErrorLogger
);
begin
  inherited Create(False);
  FMapTileUpdateEvent := AMapTileUpdateEvent;
  FDownloadInfo := ADownloadInfo;
  FErrorLogger := AErrorLogger;
  FLoadXY := AXY;
  FZoom := AZoom;
  FMapType := AMapType;

  Priority := tpLower;
  FreeOnTerminate := true;
  randomize;
end;

procedure TTileDownloaderUIOneTile.AfterWriteToFile;
begin
  if Addr(FMapTileUpdateEvent) <> nil then begin
    FMapTileUpdateEvent(FMapType, FZoom, FLoadXY);
  end;
end;

procedure TTileDownloaderUIOneTile.Execute;
var
  VResult: IDownloadResult;
  VErrorString: string;
  VResultOk: IDownloadResultOk;
  VResultDownloadError: IDownloadResultError;
  VOperatonID: Integer;
begin
  VOperatonID := FCancelNotifier.CurrentOperation;
  if FMapType.Abilities.UseDownload then begin
      try
        VResult := FMapType.DownloadTile(VOperatonID, FCancelNotifier, FLoadXY, FZoom, false);
        if not Terminated then begin
          VErrorString := '';
          if Supports(VResult, IDownloadResultOk, VResultOk) then begin
            FDownloadInfo.Add(1, VResultOk.Size);
          end else if Supports(VResult, IDownloadResultError, VResultDownloadError) then begin
            VErrorString := VResultDownloadError.ErrorText;
          end;
        end;
      except
        on E: Exception do begin
          VErrorString := E.Message;
        end;
      end;
  end else begin
    VErrorString := SAS_ERR_NotLoads;
  end;
  if not Terminated then begin
    if VErrorString = '' then begin
      Synchronize(AfterWriteToFile);
    end else begin
      FErrorLogger.LogError(
        TTileErrorInfo.Create(
          FMapType,
          FZoom,
          FLoadXY,
          VErrorString
        )
      );
    end;
  end;
end;

end.
