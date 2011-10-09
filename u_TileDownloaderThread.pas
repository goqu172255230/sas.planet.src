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

unit u_TileDownloaderThread;

interface

uses
  Windows,
  Classes,
  SyncObjs,
  i_DownloadInfoSimple,
  i_OperationNotifier,
  u_OperationNotifier,
  i_TileError,
  i_TileDownloader,
  u_MapType,
  u_TileDownloaderEventElement;

type
  TTileDownloaderThread = class (TThread)
  private
    FCancelNotifierInternal: IOperationNotifierInternal;
  protected
    FMapType: TMapType;
    FErrorLogger: ITileErrorLogger;
    FDownloadInfo: IDownloadInfoSimple;
    FMapTileUpdateEvent: TMapTileUpdateEvent;
    
    FCancelEvent: TEvent;
    FCancelNotifier: IOperationNotifier;
    FMaxRequestCount: Integer;
    FSemaphore: THandle;
    function  GetNewEventElement(
      ATile: TPoint;
      AZoom: Byte;
      ACallBack: TOnDownloadCallBack;
      ACheckExistsTileSize: Boolean;
      ACancelNotifier: IOperationNotifier;
      AOperationID: Integer
    ): ITileDownloaderEvent;
    procedure Download(
      ATile: TPoint;
      AZoom: Byte;
      ACallBack: TOnDownloadCallBack;
      ACheckExistsTileSize: Boolean;
      ACancelNotifier: IOperationNotifier;
      AOperationID: Integer
    );
    procedure SleepCancelable(ATime: Cardinal);
  public
    constructor Create(
      ACreateSuspended: Boolean;
      ADownloadInfo: IDownloadInfoSimple;
      AMapTileUpdateEvent: TMapTileUpdateEvent;
      AErrorLogger: ITileErrorLogger;
      AMaxRequestCount: Integer
    );
    destructor Destroy; override;
    procedure OnTileDownload(AEvent: ITileDownloaderEvent); virtual;
    procedure Terminate; reintroduce;
  end;

implementation

uses
  SysUtils;

{ TTileDownloaderThread }

constructor TTileDownloaderThread.Create(
  ACreateSuspended: Boolean;
  ADownloadInfo: IDownloadInfoSimple;
  AMapTileUpdateEvent: TMapTileUpdateEvent;
  AErrorLogger: ITileErrorLogger;
  AMaxRequestCount: Integer);
var
  VOperationNotifier: TOperationNotifier;
begin
  inherited Create(ACreateSuspended);
  FCancelEvent := TEvent.Create;
  VOperationNotifier := TOperationNotifier.Create;
  FCancelNotifierInternal := VOperationNotifier;
  FCancelNotifier := VOperationNotifier;
  FMapType := nil;
  FDownloadInfo := ADownloadInfo;
  FMapTileUpdateEvent := AMapTileUpdateEvent;
  FErrorLogger := AErrorLogger;
  FMaxRequestCount := AMaxRequestCount;
  FSemaphore := CreateSemaphore(nil, FMaxRequestCount, FMaxRequestCount, nil);
end;

destructor TTileDownloaderThread.Destroy;
begin
  try
    Terminate;
    FreeAndNil(FCancelEvent);
    CloseHandle(FSemaphore);
  finally
    inherited Destroy;
  end;
end;

procedure TTileDownloaderThread.Terminate;
begin
  inherited;
  FCancelEvent.SetEvent;
  FCancelNotifierInternal.NextOperation;
end;

procedure TTileDownloaderThread.SleepCancelable(ATime: Cardinal);
begin
  if ATime > 0 then begin
    FCancelEvent.WaitFor(ATime);
  end;
end;

procedure TTileDownloaderThread.OnTileDownload(AEvent: ITileDownloaderEvent);
begin
  ReleaseSemaphore(FSemaphore, 1, nil);
end;

function TTileDownloaderThread.GetNewEventElement(
  ATile: TPoint;
  AZoom: Byte;
  ACallBack: TOnDownloadCallBack;
  ACheckExistsTileSize: Boolean;
  ACancelNotifier: IOperationNotifier;
  AOperationID: Integer
): ITileDownloaderEvent;
begin
  Result := TTileDownloaderEventElement.Create(
              FDownloadInfo,
              FMapTileUpdateEvent,
              FErrorLogger,
              FMapType,
              ACancelNotifier,
              AOperationID
            );
  Result.AddToCallBackList(ACallBack);
  Result.TileXY := ATile;
  Result.TileZoom := AZoom;
  Result.CheckTileSize := ACheckExistsTileSize;
end;

procedure TTileDownloaderThread.Download(
  ATile: TPoint;
  AZoom: Byte;
  ACallBack: TOnDownloadCallBack;
  ACheckExistsTileSize: Boolean;
  ACancelNotifier: IOperationNotifier;
  AOperationID: Integer
);
begin
  repeat // �������� �������
    if WaitForSingleObject(FSemaphore, 300) = WAIT_OBJECT_0 then begin
      FMapType.DownloadTile(
        GetNewEventElement(
          ATile,
          AZoom,
          ACallBack,
          ACheckExistsTileSize,
          ACancelNotifier,
          AOperationID
        )
      );
      Break;
    end else if Terminated then begin
      Break;
    end;
  until False;
  if not Terminated then begin
    repeat // ��� ������������ ������(��)
      if WaitForSingleObject(FSemaphore, 300) = WAIT_OBJECT_0 then begin
        ReleaseSemaphore(FSemaphore, 1, nil);
        Break;
      end else if Terminated then begin
        Break;
      end;
    until False;
  end;
end;

end.
