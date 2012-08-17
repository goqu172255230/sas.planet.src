{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
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

unit u_TileStorageBerkeleyDB;

interface

uses
  Types,
  SysUtils,
  i_BinaryData,
  i_SimpleTileStorageConfig,
  i_MapVersionInfo,
  i_ContentTypeInfo,
  i_TileInfoBasic,
  i_ContentTypeManager,
  i_NotifierTTLCheck,
  i_ListenerTTLCheck,
  i_InternalPerformanceCounter,
  u_TileStorageBerkeleyDBHelper,
  u_GlobalCahceConfig,
  u_MapTypeCacheConfig,
  u_TileInfoBasicMemCache,
  u_TileStorageAbstract;

{$IFDEF DEBUG}
  {$DEFINE WITH_PERF_COUNTER}
{$ENDIF}

type
  TTileStorageBerkeleyDB = class(TTileStorageAbstract)
  private
    FHelper: TTileStorageBerkeleyDBHelper;
    FCacheConfig: TMapTypeCacheConfigBerkeleyDB;
    FMainContentType: IContentTypeInfoBasic;
    FContentTypeManager: IContentTypeManager;
    FTileNotExistsTileInfo: ITileInfoBasic;
    FGCList: INotifierTTLCheck;
    FBDBTTLListener: IListenerTTLCheck;
    FMemCacheTTLListener: IListenerTTLCheck;
    FTileInfoMemCache: TTileInfoBasicMemCache;
    {$IFDEF WITH_PERF_COUNTER}
    FPerfCounterList: IInternalPerformanceCounterList;
    FGetTileInfoCounter: IInternalPerformanceCounter;
    FLoadTileCounter: IInternalPerformanceCounter;
    FDeleteTileCounter: IInternalPerformanceCounter;
    FDeleteTNECounter: IInternalPerformanceCounter;
    FSaveTileCounter: IInternalPerformanceCounter;
    FSaveTNECounter: IInternalPerformanceCounter;
    {$ENDIF}
    procedure OnMapSettingsEdit(Sender: TObject);
    procedure OnTTLSync(Sender: TObject);
  public
    constructor Create(
      const AGCList: INotifierTTLCheck;
      const AConfig: ISimpleTileStorageConfig;
      AGlobalCacheConfig: TGlobalCahceConfig;
      const AContentTypeManager: IContentTypeManager;
      const APerfCounterList: IInternalPerformanceCounterList
    );
    destructor Destroy; override;

    function GetMainContentType: IContentTypeInfoBasic; override;
    function GetAllowDifferentContentTypes: Boolean; override;

    function GetCacheConfig: TMapTypeCacheConfigAbstract; override;

    function GetTileFileName(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): string; override;

    function GetTileInfo(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo;
      const AMode: TGetTileInfoMode
    ): ITileInfoBasic; override;

    function GetTileRectInfo(
      const ARect: TRect;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): ITileRectInfo; override;

    function DeleteTile(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): Boolean; override;

    function DeleteTNE(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ): Boolean; override;

    procedure SaveTile(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo;
      const AData: IBinaryData
    ); override;

    procedure SaveTNE(
      const AXY: TPoint;
      const AZoom: Byte;
      const AVersionInfo: IMapVersionInfo
    ); override;

    procedure Scan(
      const AOnTileStorageScan: TOnTileStorageScan;
      const AIgnoreTNE: Boolean;
      const ARemoveTileAfterProcess: Boolean
    ); override;
  end;

implementation

uses
  WideStrings,
  t_CommonTypes,
  i_TileIterator,
  i_FileNameIterator,
  i_TileFileNameParser,
  u_MapVersionFactorySimpleString,
  u_ListenerTTLCheck,
//  u_TileRectInfo,
  u_TileRectInfoShort,
  u_TileFileNameBDB,
  u_TileIteratorByRect,
  u_TileStorageTypeAbilities,
  u_FileNameIteratorFolderWithSubfolders,
  u_FoldersIteratorRecursiveByLevels,
  u_FileNameIteratorInFolderByMaskList,
  u_TreeFolderRemover,
  u_TileInfoBasic;

{ TTileStorageBerkeleyDB }

constructor TTileStorageBerkeleyDB.Create(
  const AGCList: INotifierTTLCheck;
  const AConfig: ISimpleTileStorageConfig;
  AGlobalCacheConfig: TGlobalCahceConfig;
  const AContentTypeManager: IContentTypeManager;
  const APerfCounterList: IInternalPerformanceCounterList
);
const
  CBDBSync = 300000; // 5 min
  CBDBSyncCheckInterval = 60000; // 60 sec
begin
  inherited Create(
    TTileStorageTypeAbilitiesBerkeleyDB.Create,
    TMapVersionFactorySimpleString.Create,
    AConfig
  );

  {$IFDEF WITH_PERF_COUNTER}
  FPerfCounterList := APerfCounterList.CreateAndAddNewSubList('BerkeleyDB');
  FGetTileInfoCounter := FPerfCounterList.CreateAndAddNewCounter('GetTileInfo');
  FLoadTileCounter := FPerfCounterList.CreateAndAddNewCounter('LoadTile');
  FDeleteTileCounter := FPerfCounterList.CreateAndAddNewCounter('DeleteTile');
  FDeleteTNECounter := FPerfCounterList.CreateAndAddNewCounter('DeleteTNE');
  FSaveTileCounter := FPerfCounterList.CreateAndAddNewCounter('SaveTile');
  FSaveTNECounter := FPerfCounterList.CreateAndAddNewCounter('SaveTNE');
  {$ENDIF}

  FTileNotExistsTileInfo := TTileInfoBasicNotExists.Create(0, nil);
  FCacheConfig := TMapTypeCacheConfigBerkeleyDB.Create(
    AConfig,
    TTileFileNameBDB.Create,
    AGlobalCacheConfig,
    Self.OnMapSettingsEdit
  );
  FContentTypeManager := AContentTypeManager;
  FMainContentType := FContentTypeManager.GetInfoByExt(Config.TileFileExt);
  FHelper := TTileStorageBerkeleyDBHelper.Create(
    FCacheConfig.BasePath,
    AConfig.CoordConverter.Datum.EPSG
  );

  FBDBTTLListener := TListenerTTLCheck.Create(
    FHelper.Sync,
    CBDBSync,
    CBDBSyncCheckInterval
  );

  FMemCacheTTLListener := TListenerTTLCheck.Create(
    Self.OnTTLSync,
    CBDBSync,
    CBDBSyncCheckInterval
  );

  FGCList := AGCList;
  FGCList.Add(FBDBTTLListener);
  FGCList.Add(FMemCacheTTLListener);

  FTileInfoMemCache := TTileInfoBasicMemCache.Create(100, 30000);
end;

destructor TTileStorageBerkeleyDB.Destroy;
begin
  if Assigned(FGCList) then begin
    FGCList.Remove(FMemCacheTTLListener);
    FGCList.Remove(FBDBTTLListener);
    FGCList := nil;
  end;
  FBDBTTLListener := nil;
  FMemCacheTTLListener := nil;
  FTileInfoMemCache.Free;
  FreeAndNil(FHelper);
  FMainContentType := nil;
  FContentTypeManager := nil;
  FreeAndNil(FCacheConfig);
  FTileNotExistsTileInfo := nil;
  inherited;
end;

procedure TTileStorageBerkeleyDB.OnTTLSync(Sender: TObject);
begin
  FTileInfoMemCache.ClearByTTL;
end;

procedure TTileStorageBerkeleyDB.OnMapSettingsEdit(Sender: TObject);
var
  VCacheConfig: TMapTypeCacheConfigBerkeleyDB;
begin
  if Assigned(FHelper) then begin
    if Sender is TMapTypeCacheConfigBerkeleyDB then begin
      VCacheConfig := Sender as TMapTypeCacheConfigBerkeleyDB;
      if Assigned(VCacheConfig) then begin
        FHelper.ChangeRootPath(VCacheConfig.BasePath);
      end;
    end;
  end;
end;

function TTileStorageBerkeleyDB.GetAllowDifferentContentTypes: Boolean;
begin
  Result := True;
end;

function TTileStorageBerkeleyDB.GetCacheConfig: TMapTypeCacheConfigAbstract;
begin
  Result := FCacheConfig;
end;

function TTileStorageBerkeleyDB.GetMainContentType: IContentTypeInfoBasic;
begin
  Result := FMainContentType;
end;

function TTileStorageBerkeleyDB.GetTileFileName(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): string;
begin
  Result := FCacheConfig.GetTileFileName(AXY, AZoom) + PathDelim +
    'x' + IntToStr(AXY.X) + PathDelim + 'y' + IntToStr(AXY.Y) +
    FMainContentType.GetDefaultExt;
end;

function TTileStorageBerkeleyDB.GetTileInfo(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo;
  const AMode: TGetTileInfoMode
): ITileInfoBasic;
var
  VPath: string;
  VResult: Boolean;
  VTileBinaryData: IBinaryData;
  VTileVersion: WideString;
  VTileContentType: WideString;
  VTileDate: TDateTime;
{$IFDEF WITH_PERF_COUNTER}
  VCounterContext: TInternalPerformanceCounterContext;
{$ENDIF}
begin
  Result := FTileInfoMemCache.Get(AXY, AZoom);
  if Result <> nil then begin
    Exit;
  end;
  {$IFDEF WITH_PERF_COUNTER}
  VCounterContext := FGetTileInfoCounter.StartOperation;
  try
  {$ENDIF}
    Result := FTileNotExistsTileInfo;
    if StorageStateStatic.ReadAccess <> asDisabled then begin

      VPath := FCacheConfig.GetTileFileName(AXY, AZoom);

      VResult := False;

      if FileExists(VPath) then begin

        VResult := FHelper.LoadTile(
          VPath,
          AXY,
          AZoom,
          AVersionInfo,
          VTileBinaryData,
          VTileVersion,
          VTileContentType,
          VTileDate
        );

        if VResult then begin
          if AMode = gtimWithoutData then begin
            Result := TTileInfoBasicExists.Create(
              VTileDate,
              VTileBinaryData.Size,
              MapVersionFactory.CreateByStoreString(VTileVersion),
              FContentTypeManager.GetInfo(VTileContentType)
            );
          end else begin
            Result := TTileInfoBasicExistsWithTile.Create(
              VTileDate,
              VTileBinaryData,
              MapVersionFactory.CreateByStoreString(VTileVersion),
              FContentTypeManager.GetInfo(VTileContentType)
            );
          end;
        end;
      end;

      if not VResult then begin
        VPath := ChangeFileExt(VPath, '.tne');
        if FileExists(VPath) then begin
          VResult := FHelper.IsTNEFound(
            VPath,
            AXY,
            AZoom,
            AVersionInfo,
            VTileDate
          );
          if VResult then begin
            Result := TTileInfoBasicTNE.Create(VTileDate, AVersionInfo);
          end;
        end;
      end;

      if not VResult then begin
        Result := TTileInfoBasicNotExists.Create(0, AVersionInfo);
      end;
    end;

    FTileInfoMemCache.Add(AXY, AZoom, AVersionInfo, Result);

  {$IFDEF WITH_PERF_COUNTER}
  finally
    FGetTileInfoCounter.FinishOperation(VCounterContext);
  end;
  {$ENDIF}
end;

function TTileStorageBerkeleyDB.GetTileRectInfo(
  const ARect: TRect;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): ITileRectInfo;

type
  TInfo = record
    Name: string;
    PrevName: string;
    Exists: Boolean;
    PrevExists: Boolean;
  end;

  procedure ClearInfo(var AInfo: TInfo);
  begin
    AInfo.Name := '';
    AInfo.PrevName := '';
    AInfo.Exists := False;
    AInfo.PrevExists := False;
  end;

var
  VRect: TRect;
  VZoom: Byte;
  VCount: TPoint;
  //VItems: PTileInfoInternalArray;
  VItems: PTileInfoShortInternalArray;
  VIndex: Integer;
  VTile: TPoint;
  VIterator: ITileIterator;
  VFolderInfo: TInfo;
  VFileInfo: TInfo;
  VTneFileInfo: TInfo;
  VTileExists: Boolean;
  VTileBinaryData: IBinaryData;
  VTileVersion: WideString;
  VTileContentType: WideString;
  VTileDate: TDateTime;
begin
  Result := nil;
  if StorageStateStatic.ReadAccess <> asDisabled then begin
    VRect := ARect;
    VZoom := AZoom;
    Config.CoordConverter.CheckTileRect(VRect, VZoom);
    VCount.X := VRect.Right - VRect.Left;
    VCount.Y := VRect.Bottom - VRect.Top;
    if (VCount.X > 0) and (VCount.Y > 0) then begin
      //VItems := GetMemory(VCount.X * VCount.Y * SizeOf(TTileInfoInternal));
      VItems := GetMemory(VCount.X * VCount.Y * SizeOf(TTileInfoShortInternal));
      try
        ClearInfo(VFolderInfo);
        ClearInfo(VFileInfo);
        ClearInfo(VTneFileInfo);
        VIterator := TTileIteratorByRect.Create(VRect);
        while VIterator.Next(VTile) do begin
          VIndex := (VTile.Y - VRect.Top) * VCount.X + (VTile.X - VRect.Left);
          VFileInfo.Name := FCacheConfig.GetTileFileName(VTile, VZoom);
          VTneFileInfo.Name := ChangeFileExt(VFileInfo.Name, '.tne');
          VFolderInfo.Name := ExtractFilePath(VFileInfo.Name);

          if VFolderInfo.Name = VFolderInfo.PrevName then begin
            VFolderInfo.Exists := VFolderInfo.PrevExists;
          end else begin
            VFolderInfo.Exists := DirectoryExists(VFolderInfo.Name);
            VFolderInfo.PrevName := VFolderInfo.Name;
            VFolderInfo.PrevExists := VFolderInfo.Exists;
          end;

          if VFileInfo.Name = VFileInfo.PrevName then begin
            VFileInfo.Exists := VFileInfo.PrevExists;
          end else begin
            VFileInfo.Exists := FileExists(VFileInfo.Name);
            VFileInfo.PrevName := VFileInfo.Name;
            VFileInfo.PrevExists := VFileInfo.Exists;
          end;

          if VTneFileInfo.Name = VTneFileInfo.PrevName then begin
            VTneFileInfo.Exists := VTneFileInfo.PrevExists;
          end else begin
            VTneFileInfo.Exists := FileExists(VTneFileInfo.Name);
            VTneFileInfo.PrevName := VTneFileInfo.Name;
            VTneFileInfo.PrevExists := VTneFileInfo.Exists;
          end;

          if
            (VFolderInfo.Exists and (VFileInfo.Exists or VTneFileInfo.Exists))
          then begin
            VTileExists := FHelper.LoadTile(
              VFileInfo.Name,
              VTile,
              VZoom,
              AVersionInfo,
              VTileBinaryData,
              VTileVersion,
              VTileContentType,
              VTileDate
            );
            if VTileExists then begin             
              // tile exists
              VItems[VIndex].FLoadDate := VTileDate;
              //VItems[VIndex].FVersionInfo := MapVersionFactory.CreateByStoreString(VTileVersion);
              //VItems[VIndex].FContentType := FContentTypeManager.GetInfo(VTileContentType);
              //VItems[VIndex].FData := VTileBinaryData;
              VItems[VIndex].FSize := VTileBinaryData.Size;
              VItems[VIndex].FInfoType := titExists;
            end else begin
              VTileExists := FHelper.IsTNEFound(
                VTneFileInfo.Name,
                VTile,
                VZoom,
                AVersionInfo,
                VTileDate
              );
              if VTileExists then begin
                // tne exists
                VItems[VIndex].FLoadDate := VTileDate;
                //VItems[VIndex].FVersionInfo := AVersionInfo;
                //VItems[VIndex].FContentType := nil;
                //VItems[VIndex].FData := nil;
                VItems[VIndex].FSize := 0;
                VItems[VIndex].FInfoType := titTneExists;
              end else begin
                // neither tile nor tne
                VItems[VIndex].FLoadDate := 0;
                //VItems[VIndex].FVersionInfo := nil;
                //VItems[VIndex].FContentType := nil;
                //VItems[VIndex].FData := nil;
                VItems[VIndex].FSize := 0;
                VItems[VIndex].FInfoType := titNotExists;
              end;
            end;
          end else begin
            // neither tile nor tne
            VItems[VIndex].FLoadDate := 0;
            //VItems[VIndex].FVersionInfo := nil;
            //VItems[VIndex].FContentType := nil;
            //VItems[VIndex].FData := nil;
            VItems[VIndex].FSize := 0;
            VItems[VIndex].FInfoType := titNotExists;
          end;
        end;
        //Result :=
        //  TTileRectInfo.CreateWithOwn(
        //    VRect,
        //    VZoom,
        //    VItems
        //  );
        Result :=
          TTileRectInfoShort.CreateWithOwn(
            VRect,
            VZoom,
            nil,
            FMainContentType,
            VItems
          );
        VItems := nil;
      finally
        if VItems <> nil then begin
          FreeMemory(VItems);
        end;
      end;
    end;
  end;
end;

procedure TTileStorageBerkeleyDB.SaveTile(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo;
  const AData: IBinaryData
);
var
  VPath: string;
  VResult: Boolean;
  VTileInfo: ITileInfoBasic;
{$IFDEF WITH_PERF_COUNTER}
  VCounterContext: TInternalPerformanceCounterContext;
{$ENDIF}
begin
  {$IFDEF WITH_PERF_COUNTER}
  VCounterContext := FSaveTileCounter.StartOperation;
  try
  {$ENDIF}
    if StorageStateStatic.WriteAccess <> asDisabled then begin
      VPath := FCacheConfig.GetTileFileName(AXY, AZoom);
      if FHelper.CreateDirIfNotExists(VPath) then begin
        VResult := FHelper.SaveTile(
          VPath,
          AXY,
          AZoom,
          Now,
          AVersionInfo,
          PWideChar(FMainContentType.GetContentType),
          AData
        );
        if VResult then begin
          VTileInfo :=
            TTileInfoBasicExistsWithTile.Create(
              Now,
              AData,
              AVersionInfo,
              FMainContentType
            );
          FTileInfoMemCache.Add(
            AXY,
            AZoom,
            AVersionInfo,
            VTileInfo
          );
          NotifyTileUpdate(AXY, AZoom, AVersionInfo);
        end;
      end;
    end;
  {$IFDEF WITH_PERF_COUNTER}
  finally
    FSaveTileCounter.FinishOperation(VCounterContext);
  end;
  {$ENDIF}
end;

procedure TTileStorageBerkeleyDB.SaveTNE(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
);
var
  VPath: String;
  VResult: Boolean;
{$IFDEF WITH_PERF_COUNTER}
  VCounterContext: TInternalPerformanceCounterContext;
{$ENDIF}
begin
  {$IFDEF WITH_PERF_COUNTER}
  VCounterContext := FSaveTNECounter.StartOperation;
  try
  {$ENDIF}
    if StorageStateStatic.WriteAccess <> asDisabled then begin
      VPath := FCacheConfig.GetTileFileName(AXY, AZoom);
      VPath := ChangeFileExt(VPath, '.tne');
      if FHelper.CreateDirIfNotExists(VPath) then begin
        VResult := FHelper.SaveTile(
          VPath,
          AXY,
          AZoom,
          Now,
          AVersionInfo,
          PWideChar(FMainContentType.GetContentType),
          nil
        );
        if VResult then begin
          FTileInfoMemCache.Add(
            AXY,
            AZoom,
            AVersionInfo,
            TTileInfoBasicTNE.Create(Now, AVersionInfo)
          );
          NotifyTileUpdate(AXY, AZoom, AVersionInfo);
        end;
      end;
    end;
  {$IFDEF WITH_PERF_COUNTER}
  finally
    FSaveTNECounter.FinishOperation(VCounterContext);
  end;
  {$ENDIF}
end;

function TTileStorageBerkeleyDB.DeleteTile(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): Boolean;
var
  VPath: string;
{$IFDEF WITH_PERF_COUNTER}
  VCounterContext: TInternalPerformanceCounterContext;
{$ENDIF}
begin
  {$IFDEF WITH_PERF_COUNTER}
  VCounterContext := FDeleteTileCounter.StartOperation;
  try
  {$ENDIF}
    Result := False;
    if StorageStateStatic.DeleteAccess <> asDisabled then begin
      try
        VPath := FCacheConfig.GetTileFileName(AXY, AZoom);
        if FileExists(VPath) then begin
          Result := FHelper.DeleteTile(
            VPath,
            AXY,
            AZoom,
            AVersionInfo
          );
        end;
        if not Result then begin
          Result := DeleteTNE(AXY, AZoom, AVersionInfo);
        end;
      except
        Result := False;
      end;
      if Result then begin
        FTileInfoMemCache.Add(
          AXY,
          AZoom,
          AVersionInfo,
          TTileInfoBasicNotExists.Create(0, AVersionInfo)
        );
        NotifyTileUpdate(AXY, AZoom, AVersionInfo);
      end;
    end;
  {$IFDEF WITH_PERF_COUNTER}
  finally
    FDeleteTileCounter.FinishOperation(VCounterContext);
  end;
  {$ENDIF}
end;

function TTileStorageBerkeleyDB.DeleteTNE(
  const AXY: TPoint;
  const AZoom: Byte;
  const AVersionInfo: IMapVersionInfo
): Boolean;
var
  VPath: string;
{$IFDEF WITH_PERF_COUNTER}
  VCounterContext: TInternalPerformanceCounterContext;
{$ENDIF}
begin
  {$IFDEF WITH_PERF_COUNTER}
  VCounterContext := FDeleteTNECounter.StartOperation;
  try
  {$ENDIF}
    Result := False;
    if StorageStateStatic.DeleteAccess <> asDisabled then begin
      try
        VPath := FCacheConfig.GetTileFileName(AXY, AZoom);
        VPath := ChangeFileExt(VPath, '.tne');
        if FileExists(VPath) then begin
          Result := FHelper.DeleteTile(
            VPath,
            AXY,
            AZoom,
            AVersionInfo
          );
        end;
      except
        Result := False;
      end;
    end;
  {$IFDEF WITH_PERF_COUNTER}
  finally
    FDeleteTNECounter.FinishOperation(VCounterContext);
  end;
  {$ENDIF}
end;

procedure TTileStorageBerkeleyDB.Scan(
  const AOnTileStorageScan: TOnTileStorageScan;
  const AIgnoreTNE: Boolean;
  const ARemoveTileAfterProcess: Boolean
);
const
  cMaxFolderDepth = 100;
var
  I: Integer;
  VTileXY: TPoint;
  VTileZoom: Byte;
  VTilesArray: TPointArray;
  VTileFileName: string;
  VTileFileNameW: WideString;
  VFileNameParser: ITileFileNameParser;
  VTileInfo: ITileInfoBasic;
  VTileInfoWithData: ITileInfoWithData;
  VData: IBinaryData;
  VProcessFileMasks: TWideStringList;
  VFilesIterator: IFileNameIterator;
  VFoldersIteratorFactory: IFileNameIteratorFactory;
  VFilesInFolderIteratorFactory: IFileNameIteratorFactory;
  VAbort: Boolean;
begin
  VProcessFileMasks := TWideStringList.Create;
  try
    VProcessFileMasks.Add('*.sdb');
    if not AIgnoreTNE then begin
      VProcessFileMasks.Add('*.tne');
    end;

    VFoldersIteratorFactory :=
      TFoldersIteratorRecursiveByLevelsFactory.Create(cMaxFolderDepth);

    VFilesInFolderIteratorFactory :=
      TFileNameIteratorInFolderByMaskListFactory.Create(VProcessFileMasks, True);

    VFilesIterator := TFileNameIteratorFolderWithSubfolders.Create(
      FCacheConfig.BasePath,
      '',
      VFoldersIteratorFactory,
      VFilesInFolderIteratorFactory
    );

    VFileNameParser := TTileFileNameBDB.Create;

    VAbort := False;

    while VFilesIterator.Next(VTileFileNameW) do begin
      VTileFileName := WideCharToString(PWideChar(VTileFileNameW));
      if VFileNameParser.GetTilePoint(VTileFileName, VTileXY, VTileZoom) and
        FHelper.GetTileExistsArray(FCacheConfig.BasePath + VTileFileName, VTileZoom, nil, VTilesArray) then begin
        for I := 0 to Length(VTilesArray) - 1 do begin
          VTileXY := VTilesArray[I];
          VTileInfo := Self.GetTileInfo(VTileXY, VTileZoom, nil, gtimWithData);
          VData := nil;
          if Supports(VTileInfo, ITileInfoWithData, VTileInfoWithData) then begin
            VData := VTileInfoWithData.TileData;
          end;
          VAbort := not AOnTileStorageScan(
            Self,
            VTileFileName,
            VTileXY,
            VTileZoom,
            VTileInfo,
            VData
          );
          VData := nil;
          if (not VAbort and ARemoveTileAfterProcess) then begin
            if VTileInfo.IsExists then begin
              Self.DeleteTile(VTileXY, VTileZoom, nil);
            end else if VTileInfo.IsExistsTNE then begin
              Self.DeleteTNE(VTileXY, VTileZoom, nil);
            end;
          end;
          if VAbort then begin
            Break;
          end;
        end;
      end else begin
        VAbort := True;
      end;
      if VAbort then begin
        Break;
      end;
    end;

    if (not VAbort and ARemoveTileAfterProcess) then begin
      FullRemoveDir(FCacheConfig.BasePath, True, False, True);
    end;

  finally
    VProcessFileMasks.Free;
  end;
end;

end.
