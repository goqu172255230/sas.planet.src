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

unit u_TileDownloaderBaseThread;

interface

uses
  Windows,
  SysUtils,
  Classes,
  SyncObjs,
  i_JclNotify,
  i_OperationNotifier,
  i_SimpleDownloader,
  i_InetConfig,
  i_LastResponseInfo,
  i_DownloadChecker,
  i_DownloadResultFactory,
  i_TileDownloadRequestBuilder,
  i_TileDownloader,
  i_TileDownloaderConfig,
  u_TileDownloaderHttp;

type
  TThreadTTLEvent = procedure(Sender: TObject; AThreadID: Cardinal) of object;

  TTileDownloaderBaseThread = class(TThread)
  private
    FCancelListener: IJclListener;
    FCancelEvent: TEvent;
    FLastResponseInfo: ILastResponseInfo;
    FResultFactory: IDownloadResultFactory;
    FTileDownloadRequestBuilder: ITileDownloadRequestBuilder;
    FTileDownloaderConfig: ITileDownloaderConfig;
    FHttpDownloader: ISimpleDownloader;
    FEvent: ITileDownloaderEvent;
    FSemaphore: THandle;
    FParentSemaphore: THandle;
    FBusy: Boolean;
    FWasConnectError: Boolean;
    FLastDownloadTime: Cardinal;
    FSessionCS: TCriticalSection;
    FOnTTLEvent: TThreadTTLEvent;
    FLastUsedTime: Cardinal;
    procedure DoRequest;
    procedure SetIsCanceled;
    procedure SetNotCanceled;
    procedure SleepCancelable(ATime: Cardinal);
    procedure OnCancelEvent;
  protected
    procedure Execute; override;
  public
    constructor Create(
      AResultFactory: IDownloadResultFactory;
      AOnTTL: TThreadTTLEvent;
      AParentSemaphore: THandle;
      ATileDownloadRequestBuilder: ITileDownloadRequestBuilder;
      ATileDownloaderConfig: ITileDownloaderConfig
    );
    destructor Destroy; override;
    procedure Terminate; overload;
    procedure AddEvent(AEvent: ITileDownloaderEvent);
    property Busy: Boolean read FBusy default False;
  end;

const
  CThreadTTL = 30000; // ms, �����, � ������� �������� ����� ������� ������ �������

implementation

uses
  i_DownloadResult,
  i_TileDownloadRequest,
  i_TileDownloadChecker,
  u_NotifyEventListener,
  u_LastResponseInfo;

{ TTileDownloaderBaseThread }

constructor TTileDownloaderBaseThread.Create(
  AResultFactory: IDownloadResultFactory;
  AOnTTL: TThreadTTLEvent;
  AParentSemaphore: THandle;
  ATileDownloadRequestBuilder: ITileDownloadRequestBuilder;
  ATileDownloaderConfig: ITileDownloaderConfig
);
begin
  FLastResponseInfo := TLastResponseInfo.Create;
  FCancelEvent := TEvent.Create;
  FCancelListener := TNotifyNoMmgEventListener.Create(Self.OnCancelEvent);
  FSessionCS := TCriticalSection.Create;
  FSemaphore := CreateSemaphore(nil, 0, 1, nil);
  FResultFactory := AResultFactory;
  FHttpDownloader := TTileDownloaderHttp.Create(AResultFactory);
  FWasConnectError := False;
  FOnTTLEvent := AOnTTL;
  FParentSemaphore := AParentSemaphore;
  FTileDownloadRequestBuilder := ATileDownloadRequestBuilder;
  FTileDownloaderConfig := ATileDownloaderConfig;
  FLastUsedTime := GetTickCount;
  FLastDownloadTime := MaxInt;
  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TTileDownloaderBaseThread.Destroy;
begin
  try
    FHttpDownloader := nil;
    CloseHandle(FSemaphore);
    FreeAndNil(FCancelEvent);
    FreeAndNil(FSessionCS);
  finally
    inherited Destroy;
  end;
end;

procedure TTileDownloaderBaseThread.Terminate;
begin
  try
    ReleaseSemaphore(FSemaphore, 1, nil);
  finally
    inherited Terminate;
  end;
end;

procedure TTileDownloaderBaseThread.AddEvent(AEvent: ITileDownloaderEvent);
begin
  FBusy := True;
  FEvent := AEvent;
  ReleaseSemaphore(FSemaphore, 1, nil);
end;

procedure TTileDownloaderBaseThread.DoRequest;

  procedure SleepIfConnectErrorOrWaitInterval(
    ATileDownloaderConfigStatic: ITileDownloaderConfigStatic
  );
  var
    VNow: Cardinal;
    VTimeFromLastDownload: Cardinal;
    VSleepTime: Cardinal;
    VInetConfig: IInetConfigStatic;
  begin
    VInetConfig := ATileDownloaderConfigStatic.InetConfigStatic;
    VNow := GetTickCount;
    if VNow >= FLastDownloadTime then begin
      VTimeFromLastDownload := VNow - FLastDownloadTime;
    end else begin
      VTimeFromLastDownload := MaxInt;
    end;
    if FWasConnectError then begin
      if VTimeFromLastDownload < VInetConfig.SleepOnResetConnection then begin
        VSleepTime := VInetConfig.SleepOnResetConnection - VTimeFromLastDownload;
        SleepCancelable(VSleepTime);
      end;
    end else begin
      if VTimeFromLastDownload < ATileDownloaderConfigStatic.WaitInterval then begin
        VSleepTime := ATileDownloaderConfigStatic.WaitInterval - VTimeFromLastDownload;
        SleepCancelable(VSleepTime);
      end;
    end;
  end;

var
  VCount: Integer;
  VTryCount: Integer;
  VTileDownloaderConfigStatic: ITileDownloaderConfigStatic;
  VDownloadRequest: ITileDownloadRequest;
  VResultWithRespond: IDownloadResultWithServerRespond;
  VTileRequestWithChecker: ITileRequestWithChecker;
begin
  VTileDownloaderConfigStatic := FTileDownloaderConfig.GetStatic;
  SetNotCanceled;
  try
    try
      if (VTileDownloaderConfigStatic <> nil) and (FTileDownloadRequestBuilder <> nil) then begin
        try
          FEvent.Request.CancelNotifier.AddListener(FCancelListener);
          if FEvent.Request.CancelNotifier.IsOperationCanceled(FEvent.Request.OperationID)then begin
            FEvent.DownloadResult := nil;
          end else begin
            VCount := 0;
            VTryCount := VTileDownloaderConfigStatic.InetConfigStatic.DownloadTryCount;
            FWasConnectError := False;
            repeat
              SleepIfConnectErrorOrWaitInterval(VTileDownloaderConfigStatic);
              if FEvent.Request.CancelNotifier.IsOperationCanceled(FEvent.Request.OperationID)then begin
                FEvent.DownloadResult := nil;
                Break;
              end;
              VDownloadRequest := FTileDownloadRequestBuilder.BuildRequest(
                FEvent.Request,
                FLastResponseInfo
              );
              if FEvent.Request.CancelNotifier.IsOperationCanceled(FEvent.Request.OperationID)then begin
                FEvent.DownloadResult := FResultFactory.BuildCanceled(VDownloadRequest);
                Break;
              end;
              FEvent.DownloadResult :=
                FHttpDownloader.DoRequest(
                  VDownloadRequest,
                  FEvent.Request.CancelNotifier,
                  FEvent.Request.OperationID
                );
              Inc(VCount);
              FLastDownloadTime := GetTickCount;
              if FEvent.DownloadResult <> nil then begin
                if FEvent.DownloadResult.IsServerExists then begin
                  if Supports(FEvent.DownloadResult, IDownloadResultWithServerRespond, VResultWithRespond) then begin
                    FLastResponseInfo.ResponseHead := VResultWithRespond.RawResponseHeader;
                  end;
                end else begin
                  FWasConnectError := not FEvent.DownloadResult.IsServerExists;
                end;
              end;
              if Supports(FEvent.Request, ITileRequestWithChecker, VTileRequestWithChecker) then begin
                VTileRequestWithChecker.Checker.AfterDownload(FEvent.DownloadResult);
              end;
            until (not FWasConnectError) or (VCount >= VTryCount);
          end;
        finally
          FEvent.Request.CancelNotifier.RemoveListener(FCancelListener);
        end;
      end;
    finally
      FEvent.ProcessEvent;
    end;
  finally
    FEvent := nil;
    FBusy := False;
    if FParentSemaphore <> 0 then begin
      ReleaseSemaphore(FParentSemaphore, 1, nil);
    end;
  end;
end;

procedure TTileDownloaderBaseThread.Execute;
begin
  repeat
    if Terminated then begin
      Break;
    end;
    repeat
      if WaitForSingleObject(FSemaphore, 300) = WAIT_OBJECT_0  then begin
        Break
      end else if Terminated then begin
        Break;
      end else if (GetTickCount - FLastUsedTime) > CThreadTTL then begin
        if Addr(FOnTTLEvent) <> nil then begin
          FOnTTLEvent(Self, Self.ThreadID)
        end;
      end;
    until False;
    if Assigned(FEvent) then begin
      try
        DoRequest;
      finally
        FLastUsedTime := GetTickCount;
      end;
    end;
  until False;
end;

procedure TTileDownloaderBaseThread.OnCancelEvent;
begin
  SetIsCanceled;
end;

procedure TTileDownloaderBaseThread.SetIsCanceled;
begin
  FSessionCS.Acquire;
  try
    FCancelEvent.SetEvent;
  finally
    FSessionCS.Release;
  end;
end;

procedure TTileDownloaderBaseThread.SetNotCanceled;
begin
  FSessionCS.Acquire;
  try
    FCancelEvent.ResetEvent;
  finally
    FSessionCS.Release;
  end;
end;

procedure TTileDownloaderBaseThread.SleepCancelable(ATime: Cardinal);
begin
  if ATime > 0 then begin
    FCancelEvent.WaitFor(ATime);
  end;
end;

end.
