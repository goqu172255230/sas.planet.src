unit u_MapType;

interface

uses
  Windows,
  sysutils,
  Classes,
  Dialogs,
  GR32,
  t_GeoTypes,
  i_ContentTypeInfo,
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_OperationNotifier,
  i_TileObjCache,
  i_DownloadResult,
  i_TileDownloaderConfig,
  i_LanguageManager,
  i_CoordConverter,
  i_DownloadChecker,
  i_TileDownlodSession,
  i_LastResponseInfo,
  i_MapVersionConfig,
  i_TileRequestBuilder,
  i_TileRequestBuilderConfig,
  i_IPoolOfObjectsSimple,
  i_BitmapTileSaveLoad,
  i_VectorDataLoader,
  i_ListOfObjectsWithTTL,
  i_DownloadResultFactory,
  i_AntiBan,
  i_MemObjCache,
  i_InetConfig,
  i_DownloadResultTextProvider,
  i_ImageResamplerConfig,
  i_ContentTypeManager,
  i_GlobalDownloadConfig,
  i_MapAbilitiesConfig,
  i_SimpleTileStorageConfig,
  i_ZmpInfo,
  i_MapTypeGUIConfig,
  i_ProxySettings,
  i_CoordConverterFactory,
  i_TileFileNameGeneratorsList,
  i_VectorDataItemSimple,
  u_GlobalCahceConfig,
  u_MapTypeCacheConfig,
  u_TileStorageAbstract,
  u_ResStrings;

type
 TMapType = class
   private
    FZmp: IZmpInfo;

    FAntiBan: IAntiBan;
    FCacheBitmap: ITileObjCacheBitmap;
    FCacheVector: ITileObjCacheVector;
    FStorage: TTileStorageAbstract;
    FTileRequestBuilder: ITileRequestBuilder;
    FBitmapLoaderFromStorage: IBitmapTileLoader;
    FBitmapSaverToStorage: IBitmapTileSaver;
    FKmlLoaderFromStorage: IVectorDataLoader;
    FCoordConverter : ICoordConverter;
    FViewCoordConverter : ICoordConverter;
    FPoolOfDownloaders: IPoolOfObjectsSimple;
    FLoadPrevMaxZoomDelta: Integer;
    FContentType: IContentTypeInfoBasic;
    FLanguageManager: ILanguageManager;
    FLastResponseInfo: ILastResponseInfo;
    FVersionConfig: IMapVersionConfig;
    FTileDownloaderConfig: ITileDownloaderConfig;
    FTileRequestBuilderConfig: ITileRequestBuilderConfig;
    FDownloadResultFactory: IDownloadResultFactory;
    FImageResamplerConfig: IImageResamplerConfig;
    FContentTypeManager: IContentTypeManager;
    FDownloadConfig: IGlobalDownloadConfig;
    FGUIConfig: IMapTypeGUIConfig;
    FAbilitiesConfig: IMapAbilitiesConfig;
    FStorageConfig: ISimpleTileStorageConfig;

    function GetIsBitmapTiles: Boolean;
    function GetIsKmlTiles: Boolean;
    function GetIsHybridLayer: Boolean;
    procedure LoadUrlScript(
      ACoordConverterFactory: ICoordConverterFactory
    );
    procedure LoadDownloader(
      AGCList: IListOfObjectsWithTTL;
      AProxyConfig: IProxyConfig
    );
    procedure LoadStorageParams(
      AMemCacheBitmap: IMemObjCacheBitmap;
      AMemCacheVector: IMemObjCacheVector;
      AGlobalCacheConfig: TGlobalCahceConfig;
      ATileNameGeneratorList: ITileFileNameGeneratorsList;
      ACoordConverterFactory: ICoordConverterFactory
    );
    procedure SaveTileDownload(AXY: TPoint; Azoom: byte; ATileStream: TCustomMemoryStream; AMimeType: string);
    procedure SaveTileNotExists(AXY: TPoint; Azoom: byte);
    procedure CropOnDownload(ABtm: TCustomBitmap32; ATileSize: TPoint);
    procedure SaveBitmapTileToStorage(AXY: TPoint; Azoom: byte; btm: TCustomBitmap32);
    function LoadBitmapTileFromStorage(AXY: TPoint; Azoom: byte; btm: TCustomBitmap32): Boolean;
    function LoadKmlTileFromStorage(AXY: TPoint; Azoom: byte; var AKml: IVectorDataItemList): boolean;
    procedure LoadMapType(
      AMemCacheBitmap: IMemObjCacheBitmap;
      AMemCacheVector: IMemObjCacheVector;
      AGCList: IListOfObjectsWithTTL;
      AProxyConfig: IProxyConfig;
      AGlobalCacheConfig: TGlobalCahceConfig;
      ATileNameGeneratorList: ITileFileNameGeneratorsList;
      ACoordConverterFactory: ICoordConverterFactory;
      AConfig : IConfigDataProvider
    );

    function LoadTileFromPreZ(
      spr: TCustomBitmap32;
      AXY: TPoint;
      Azoom: byte;
      IgnoreError: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean;
    function GetAbilitiesConfigStatic: IMapAbilitiesConfigStatic;
   public
    procedure SaveConfig(ALocalConfig: IConfigDataWriteProvider);
    function GetLink(AXY: TPoint; Azoom: byte): string;
    function GetTileFileName(AXY: TPoint; Azoom: byte): string;
    function GetTileShowName(AXY: TPoint; Azoom: byte): string;
    function TileExists(AXY: TPoint; Azoom: byte): Boolean;
    function TileNotExistsOnServer(AXY: TPoint; Azoom: byte): Boolean;
    function LoadTile(
      btm: TCustomBitmap32;
      AXY: TPoint;
      Azoom: byte;
      IgnoreError: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean; overload;
    function LoadTile(
      var AKml: IVectorDataItemList;
      AXY: TPoint;
      Azoom: byte;
      IgnoreError: Boolean;
      ACache: ITileObjCacheVector = nil
    ): boolean; overload;
    function LoadTileOrPreZ(
      spr: TCustomBitmap32;
      AXY: TPoint;
      Azoom: byte;
      IgnoreError: Boolean;
      AUsePre: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean;
    function LoadTileUni(
      spr: TCustomBitmap32;
      AXY: TPoint;
      Azoom: byte;
      ACoordConverterTarget: ICoordConverter;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean;
    function LoadBtimap(
      spr: TCustomBitmap32;
      APixelRectTarget: TRect;
      Azoom: byte;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean;
    function LoadBtimapUni(
      spr: TCustomBitmap32;
      APixelRectTarget: TRect;
      Azoom: byte;
      ACoordConverterTarget: ICoordConverter;
      AUsePre, AAllowPartial, IgnoreError: Boolean;
      ACache: ITileObjCacheBitmap = nil
    ): boolean;
    function DeleteTile(AXY: TPoint; Azoom: byte): Boolean;
    procedure SaveTileSimple(AXY: TPoint; Azoom: byte; btm: TCustomBitmap32);
    function TileLoadDate(AXY: TPoint; Azoom: byte): TDateTime;
    function TileSize(AXY: TPoint; Azoom: byte): integer;
    function TileExportToFile(AXY: TPoint; Azoom: byte; AFileName: string; OverWrite: boolean): boolean;

    function LoadFillingMap(
      AOperationID: Integer;
      ACancelNotifier: IOperationNotifier;
      btm: TCustomBitmap32;
      AXY: TPoint;
      Azoom: byte;
      ASourceZoom: byte;
      ANoTileColor: TColor32;
      AShowTNE: Boolean;
      ATNEColor: TColor32
    ): boolean;
    function GetShortFolderName: string;
    function DownloadTile(
      AOperationID: Integer;
      ACancelNotifier: IOperationNotifier;
      ATile: TPoint;
      AZoom: byte;
      ACheckTileSize: Boolean
    ): IDownloadResult;
    property Zmp: IZmpInfo read FZmp;
    property GeoConvert: ICoordConverter read FCoordConverter;
    property ViewGeoConvert: ICoordConverter read FViewCoordConverter;
    property VersionConfig: IMapVersionConfig read FVersionConfig;

    property Abilities: IMapAbilitiesConfigStatic read GetAbilitiesConfigStatic;
    property StorageConfig: ISimpleTileStorageConfig read FStorageConfig;
    property IsBitmapTiles: Boolean read GetIsBitmapTiles;
    property IsKmlTiles: Boolean read GetIsKmlTiles;
    property IsHybridLayer: Boolean read GetIsHybridLayer;

    property TileStorage: TTileStorageAbstract read FStorage;
    property GUIConfig: IMapTypeGUIConfig read FGUIConfig;
    property TileDownloaderConfig: ITileDownloaderConfig read FTileDownloaderConfig;
    property TileRequestBuilderConfig: ITileRequestBuilderConfig read FTileRequestBuilderConfig;
    property CacheBitmap: ITileObjCacheBitmap read FCacheBitmap;
    property CacheVector: ITileObjCacheVector read FCacheVector;

    constructor Create(
      ALanguageManager: ILanguageManager;
      AZmp: IZmpInfo;
      AMemCacheBitmap: IMemObjCacheBitmap;
      AMemCacheVector: IMemObjCacheVector;
      AGlobalCacheConfig: TGlobalCahceConfig;
      ATileNameGeneratorList: ITileFileNameGeneratorsList;
      AGCList: IListOfObjectsWithTTL;
      AInetConfig: IInetConfig;
      AImageResamplerConfig: IImageResamplerConfig;
      ADownloadConfig: IGlobalDownloadConfig;
      AContentTypeManager: IContentTypeManager;
      ACoordConverterFactory: ICoordConverterFactory;
      ADownloadResultTextProvider: IDownloadResultTextProvider;
      AConfig: IConfigDataProvider
    );
    destructor Destroy; override;
 end;

type
  TMapUpdateEvent = procedure(AMapType: TMapType) of object;
  TMapTileUpdateEvent = procedure(AMapType: TMapType; AZoom: Byte;
    ATile: TPoint) of object;

implementation

uses
  Types,
  GR32_Resamplers,
  i_ObjectWithTTL,
  i_PoolElement,
  i_TileInfoBasic,
  i_ContentConverter,
  i_TileDownloadRequest,
  u_PoolOfObjectsSimple,
  u_TileDownloaderConfig,
  u_TileRequestBuilderConfig,
  u_TileRequestBuilderPascalScript,
  u_TileDownloaderBaseFactory,
  u_DownloadResultFactory,
  u_AntiBanStuped,
  u_TileCacheSimpleGlobal,
  u_SimpleTileStorageConfig,
  u_MapAbilitiesConfig,
  u_MapTypeGUIConfig,
  u_LastResponseInfo,
  u_MapVersionConfig,
  u_DownloadCheckerStuped,
  u_TileStorageGE,
  u_TileStorageFileSystem;

procedure TMapType.LoadUrlScript(
  ACoordConverterFactory: ICoordConverterFactory
);
begin
  FTileRequestBuilder := nil;
  FAbilitiesConfig.LockWrite;
  try
    if FAbilitiesConfig.UseDownload then begin
      try
        FTileRequestBuilder :=
          TTileRequestBuilderPascalScript.Create(
            FZmp,
            FTileRequestBuilderConfig,
            Zmp.DataProvider,
            ACoordConverterFactory,
            FLanguageManager
          );
      except
        on E: Exception do begin
          ShowMessageFmt(SAS_ERR_UrlScriptError, [FZmp.GUI.Name, E.Message, FZmp.FileName]);
          FTileRequestBuilder := nil;
        end;
      else
        ShowMessageFmt(SAS_ERR_UrlScriptUnexpectedError, [FZmp.GUI.Name, FZmp.FileName]);
        FTileRequestBuilder := nil;
      end;
    end;
    if FTileRequestBuilder = nil then begin
      FAbilitiesConfig.UseDownload := False;
    end;
  finally
    FAbilitiesConfig.UnlockWrite;
  end;
end;

procedure TMapType.LoadStorageParams(
  AMemCacheBitmap: IMemObjCacheBitmap;
  AMemCacheVector: IMemObjCacheVector;
  AGlobalCacheConfig: TGlobalCahceConfig;
  ATileNameGeneratorList: ITileFileNameGeneratorsList;
  ACoordConverterFactory: ICoordConverterFactory
);
var
  VContentTypeBitmap: IContentTypeInfoBitmap;
  VContentTypeKml: IContentTypeInfoVectorData;
begin
  if FStorageConfig.CacheTypeCode = 5  then begin
    FStorage := TTileStorageGE.Create(FStorageConfig, AGlobalCacheConfig, FContentTypeManager);
  end else begin
    FStorage := TTileStorageFileSystem.Create(FStorageConfig, AGlobalCacheConfig, ATileNameGeneratorList, FContentTypeManager);
  end;
  FContentType := FStorage.GetMainContentType;
  if Supports(FContentType, IContentTypeInfoBitmap, VContentTypeBitmap) then begin
    FBitmapLoaderFromStorage := VContentTypeBitmap.GetLoader;
    if FStorageConfig.AllowAdd then begin
      FBitmapSaverToStorage := VContentTypeBitmap.GetSaver;
    end;
  end else if Supports(FContentType, IContentTypeInfoVectorData, VContentTypeKml) then begin
    FKmlLoaderFromStorage := VContentTypeKml.GetLoader;
  end;
  FCacheBitmap := TTileCacheSimpleGlobalBitmap.Create(FZmp.GUID, AMemCacheBitmap);
  FCacheVector := TTileCacheSimpleGlobalVector.Create(FZmp.GUID, AMemCacheVector);
end;

procedure TMapType.LoadDownloader(
  AGCList: IListOfObjectsWithTTL;
  AProxyConfig: IProxyConfig
);
var
  VDownloader: TTileDownloaderFactory;
begin
  FAbilitiesConfig.LockWrite;
  try
    if FAbilitiesConfig.UseDownload then begin
      try
        VDownloader := TTileDownloaderFactory.Create(FDownloadResultFactory, FTileDownloaderConfig);
        FPoolOfDownloaders :=
          TPoolOfObjectsSimple.Create(
            FTileDownloaderConfig.MaxConnectToServerCount,
            VDownloader,
            60000,
            60000
          );
        AGCList.AddObject(FPoolOfDownloaders as IObjectWithTTL);
        FAntiBan := TAntiBanStuped.Create(AProxyConfig, FZmp.DataProvider);
      except
        if ExceptObject <> nil then begin
          ShowMessageFmt(SAS_ERR_MapDownloadByError,[ZMP.FileName, (ExceptObject as Exception).Message]);
        end;
        FAbilitiesConfig.UseDownload := false;
      end;
    end;
  finally
    FAbilitiesConfig.UnlockWrite;
  end;
end;

procedure TMapType.LoadMapType(
  AMemCacheBitmap: IMemObjCacheBitmap;
  AMemCacheVector: IMemObjCacheVector;
  AGCList: IListOfObjectsWithTTL;
  AProxyConfig: IProxyConfig;
  AGlobalCacheConfig: TGlobalCahceConfig;
  ATileNameGeneratorList: ITileFileNameGeneratorsList;
  ACoordConverterFactory: ICoordConverterFactory;
  AConfig: IConfigDataProvider
);
begin
  FGUIConfig.ReadConfig(AConfig);
  FStorageConfig.ReadConfig(AConfig);
  FAbilitiesConfig.ReadConfig(AConfig);
  FVersionConfig.ReadConfig(AConfig);
  FTileDownloaderConfig.ReadConfig(AConfig);
  LoadStorageParams(AMemCacheBitmap, AMemCacheVector, AGlobalCacheConfig, ATileNameGeneratorList, ACoordConverterFactory);
  FCoordConverter := FStorageConfig.CoordConverter;
  FViewCoordConverter := Zmp.ViewGeoConvert;
  FTileRequestBuilderConfig.ReadConfig(AConfig);
  LoadUrlScript(ACoordConverterFactory);
  LoadDownloader(AGCList, AProxyConfig);
end;

function TMapType.GetLink(AXY: TPoint; Azoom: byte): string;
var
  VRequest: ITileDownloadRequest;
begin
  Result := '';
  if FAbilitiesConfig.UseDownload then begin
    FCoordConverter.CheckTilePosStrict(AXY, Azoom, True);
    VRequest := FTileRequestBuilder.BuildRequest(AXY, AZoom, FVersionConfig.GetStatic, FLastResponseInfo);
    if VRequest <> nil then begin
      Result := VRequest.Url;
    end;
  end;
end;

function TMapType.GetTileFileName(AXY: TPoint; Azoom: byte): string;
begin
  Result := FStorage.GetTileFileName(AXY, Azoom, FVersionConfig.GetStatic);
end;

function TMapType.TileExists(AXY: TPoint; Azoom: byte): Boolean;
var
  VTileInfo: ITileInfoBasic;
begin
  VTileInfo := FStorage.GetTileInfo(AXY, Azoom, FVersionConfig.GetStatic);
  Result := VTileInfo.GetIsExists;
end;

function TMapType.DeleteTile(AXY: TPoint; Azoom: byte): Boolean;
begin
  Result := FStorage.DeleteTile(AXY, Azoom, FVersionConfig.GetStatic);
end;

function TMapType.TileNotExistsOnServer(AXY: TPoint; Azoom: byte): Boolean;
var
  VTileInfo: ITileInfoBasic;
begin
  VTileInfo := FStorage.GetTileInfo(AXY, Azoom, FVersionConfig.GetStatic);
  Result := VTileInfo.GetIsExistsTNE;
end;

procedure TMapType.SaveBitmapTileToStorage(AXY: TPoint; Azoom: byte;
  btm: TCustomBitmap32);
var
  VMemStream: TMemoryStream;
begin
  VMemStream := TMemoryStream.Create;
  try
    FBitmapSaverToStorage.SaveToStream(btm, VMemStream);
    FStorage.SaveTile(AXY, Azoom, FVersionConfig.GetStatic, VMemStream);
  finally
    VMemStream.Free;
  end;
end;

procedure TMapType.SaveConfig(ALocalConfig: IConfigDataWriteProvider);
begin
  FGUIConfig.WriteConfig(ALocalConfig);
  FTileRequestBuilderConfig.WriteConfig(ALocalConfig);
  FTileDownloaderConfig.WriteConfig(ALocalConfig);
  FVersionConfig.WriteConfig(ALocalConfig);
  FStorageConfig.WriteConfig(ALocalConfig);
end;

function TMapType.LoadBitmapTileFromStorage(AXY: TPoint; Azoom: byte;
  btm: TCustomBitmap32): Boolean;
var
  VTileInfo: ITileInfoBasic;
  VMemStream: TMemoryStream;
begin
  VMemStream := TMemoryStream.Create;
  try
    Result := FStorage.LoadTile(AXY, Azoom, FVersionConfig.GetStatic, VMemStream, VTileInfo);
    if Result then begin
      FBitmapLoaderFromStorage.LoadFromStream(VMemStream, btm);
    end;
  finally
    VMemStream.Free;
  end;
end;

function TMapType.LoadKmlTileFromStorage(AXY: TPoint; Azoom: byte;
  var AKml: IVectorDataItemList): boolean;
var
  VTileInfo: ITileInfoBasic;
  VMemStream: TMemoryStream;
begin
  VMemStream := TMemoryStream.Create;
  try
    Result := FStorage.LoadTile(AXY, Azoom, FVersionConfig.GetStatic, VMemStream, VTileInfo);
    if Result then  begin
      FKmlLoaderFromStorage.LoadFromStream(VMemStream, AKml);
      Result := AKml <> nil;
    end;
  finally
    VMemStream.Free;
  end;
end;

procedure TMapType.SaveTileDownload(AXY: TPoint; Azoom: byte;
  ATileStream: TCustomMemoryStream; AMimeType: string);
var
  btmSrc:TCustomBitmap32;
  VContentType: IContentTypeInfoBasic;
  VContentTypeBitmap: IContentTypeInfoBitmap;
  VConverter: IContentConverter;
  VLoader: IBitmapTileLoader;
  VMemStream: TMemoryStream;
begin
  if FStorageConfig.AllowAdd then begin
    if GetIsBitmapTiles and FZmp.TilePostDownloadCropConfig.IsCropOnDownload then begin
      VContentType := FContentTypeManager.GetInfo(AMimeType);
      if VContentType <> nil then begin
        if Supports(VContentType, IContentTypeInfoBitmap, VContentTypeBitmap) then begin
          VLoader := VContentTypeBitmap.GetLoader;
          if VLoader <> nil then begin
            btmsrc := TCustomBitmap32.Create;
            try
              ATileStream.Position := 0;
              VLoader.LoadFromStream(ATileStream, btmSrc);
              CropOnDownload(btmSrc, FCoordConverter.GetTileSize(AXY, Azoom));
              SaveBitmapTileToStorage(AXY, Azoom, btmSrc);
            finally
              FreeAndNil(btmSrc);
            end;
          end else begin
            raise Exception.CreateResFmt(@SAS_ERR_BadMIMEForDownloadRastr, [AMimeType]);
          end;
        end else begin
          raise Exception.CreateResFmt(@SAS_ERR_BadMIMEForDownloadRastr, [AMimeType]);
        end;
      end else begin
        raise Exception.CreateResFmt(@SAS_ERR_BadMIMEForDownloadRastr, [AMimeType]);
      end;
    end else begin
      VConverter := FContentTypeManager.GetConverter(AMimeType, FContentType.GetContentType);
      if VConverter <> nil then begin
        if VConverter.GetIsSimpleCopy then begin
          FStorage.SaveTile(AXY, Azoom, FVersionConfig.GetStatic, ATileStream);
        end else begin
          VMemStream := TMemoryStream.Create;
          try
            ATileStream.Position := 0;
            VConverter.ConvertStream(ATileStream, VMemStream);
            FStorage.SaveTile(AXY, Azoom, FVersionConfig.GetStatic, VMemStream);
          finally
            VMemStream.Free;
          end;
        end;
      end else begin
        raise Exception.CreateResFmt(@SAS_ERR_BadMIMEForDownloadRastr, [AMimeType]);
      end;
    end;
    FCacheBitmap.DeleteTileFromCache(AXY, Azoom);
  end else begin
    raise Exception.Create('��� ���� ����� ��������� ���������� ������.');
  end;
end;

function TMapType.TileLoadDate(AXY: TPoint; Azoom: byte): TDateTime;
var
  VTileInfo: ITileInfoBasic;
begin
  VTileInfo := FStorage.GetTileInfo(AXY, Azoom, FVersionConfig.GetStatic);
  Result := VTileInfo.GetLoadDate;
end;

function TMapType.TileSize(AXY: TPoint; Azoom: byte): integer;
var
  VTileInfo: ITileInfoBasic;
begin
  VTileInfo := FStorage.GetTileInfo(AXY, Azoom, FVersionConfig.GetStatic);
  Result := VTileInfo.GetSize;
end;

procedure TMapType.SaveTileNotExists(AXY: TPoint; Azoom: byte);
begin
  FStorage.SaveTNE(AXY, Azoom, FVersionConfig.GetStatic);
end;

procedure TMapType.SaveTileSimple(AXY: TPoint; Azoom: byte; btm: TCustomBitmap32);
begin
  SaveBitmapTileToStorage(AXY, Azoom, btm);
end;

function TMapType.TileExportToFile(AXY: TPoint; Azoom: byte;
  AFileName: string; OverWrite: boolean): boolean;
var
  VFileStream: TFileStream;
  VFileExists: Boolean;
  VExportPath: string;
  VTileInfo: ITileInfoBasic;
begin
  VFileExists := FileExists(AFileName);
  if VFileExists and not OverWrite then begin
    Result := False;
  end else begin
    if VFileExists then begin
      DeleteFile(AFileName);
    end else begin
      VExportPath := ExtractFilePath(AFileName);
      ForceDirectories(VExportPath);
    end;
    VFileStream := TFileStream.Create(AFileName, fmCreate);
    try
      Result := FStorage.LoadTile(AXY, Azoom, FVersionConfig.GetStatic, VFileStream, VTileInfo);
      if Result then begin
        FileSetDate(AFileName, DateTimeToFileDate(VTileInfo.GetLoadDate));
      end;
    finally
      VFileStream.Free;
    end;
  end;
end;

function TMapType.LoadFillingMap(
  AOperationID: Integer;
  ACancelNotifier: IOperationNotifier;
  btm: TCustomBitmap32;
  AXY: TPoint;
  Azoom, ASourceZoom: byte;
  ANoTileColor: TColor32;
  AShowTNE: Boolean;
  ATNEColor: TColor32
): boolean;
begin
  Result :=
    FStorage.LoadFillingMap(
      AOperationID,
      ACancelNotifier,
      btm,
      AXY,
      Azoom,
      ASourceZoom,
      FVersionConfig.GetStatic,
      ANoTileColor,
      AShowTNE,
      ATNEColor
    );
end;

function TMapType.GetShortFolderName: string;
begin
  Result := ExtractFileName(ExtractFileDir(IncludeTrailingPathDelimiter(FStorageConfig.NameInCache)));
end;

constructor TMapType.Create(
  ALanguageManager: ILanguageManager;
  AZmp: IZmpInfo;
  AMemCacheBitmap: IMemObjCacheBitmap;
  AMemCacheVector: IMemObjCacheVector;
  AGlobalCacheConfig: TGlobalCahceConfig;
  ATileNameGeneratorList: ITileFileNameGeneratorsList;
  AGCList: IListOfObjectsWithTTL;
  AInetConfig: IInetConfig;
  AImageResamplerConfig: IImageResamplerConfig;
  ADownloadConfig: IGlobalDownloadConfig;
  AContentTypeManager: IContentTypeManager;
  ACoordConverterFactory: ICoordConverterFactory;
  ADownloadResultTextProvider: IDownloadResultTextProvider;
  AConfig: IConfigDataProvider
);
begin
  FZmp := AZmp;
  FGUIConfig :=
    TMapTypeGUIConfig.Create(
      ALanguageManager,
      FZmp.GUI
    );
  FLanguageManager := ALanguageManager;
  FImageResamplerConfig := AImageResamplerConfig;
  FDownloadConfig := ADownloadConfig;
  FContentTypeManager := AContentTypeManager;
  FTileDownloaderConfig := TTileDownloaderConfig.Create(AInetConfig, Zmp.TileDownloaderConfig);
  FTileRequestBuilderConfig := TTileRequestBuilderConfig.Create(Zmp.TileRequestBuilderConfig);
  FLastResponseInfo := TLastResponseInfo.Create;
  FVersionConfig := TMapVersionConfig.Create(FZmp.VersionConfig);
  FStorageConfig := TSimpleTileStorageConfig.Create(FZmp.StorageConfig);
  FAbilitiesConfig :=
    TMapAbilitiesConfig.Create(
      FZmp.Abilities,
      FStorageConfig
    );
  FDownloadResultFactory :=
    TDownloadResultFactory.Create(
      ADownloadResultTextProvider
    );
  LoadMapType(
    AMemCacheBitmap,
    AMemCacheVector,
    AGCList,
    AInetConfig.ProxyConfig,
    AGlobalCacheConfig,
    ATileNameGeneratorList,
    ACoordConverterFactory,
    AConfig
  );
  if FAbilitiesConfig.IsLayer then begin
    FLoadPrevMaxZoomDelta := 4;
  end else begin
    FLoadPrevMaxZoomDelta := 6;
  end;
end;

destructor TMapType.Destroy;
begin
  FCoordConverter := nil;
  FPoolOfDownloaders := nil;
  FCacheBitmap := nil;
  FCacheVector := nil;
  FreeAndNil(FStorage);
  inherited;
end;

function TMapType.DownloadTile(
  AOperationID: Integer;
  ACancelNotifier: IOperationNotifier;
  ATile: TPoint;
  AZoom: byte;
  ACheckTileSize: Boolean
): IDownloadResult;
var
  VPoolElement: IPoolElement;
  VDownloader: ITileDownlodSession;
  VDownloadChecker: IDownloadChecker;
  VConfig: ITileDownloaderConfigStatic;
  VResultOk: IDownloadResultOk;
  VOldTileSize: Integer;
  VResultStream: TMemoryStream;
  VContentType: string;
  VRequest: ITileDownloadRequest;
begin
  if FAbilitiesConfig.UseDownload then begin
    FCoordConverter.CheckTilePosStrict(ATile, AZoom, True);
    VRequest := FTileRequestBuilder.BuildRequest(ATile, AZoom, FVersionConfig.GetStatic, FLastResponseInfo);
    if VRequest = nil then begin
      Result := FDownloadResultFactory.BuildNotNecessary(VRequest, 'Empty request', '');
    end else begin
      VPoolElement := FPoolOfDownloaders.TryGetPoolElement(AOperationID, ACancelNotifier);
      if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
        Result := FDownloadResultFactory.BuildCanceled(VRequest);
      end else begin
        VDownloader := VPoolElement.GetObject as ITileDownlodSession;
        if FAntiBan <> nil then begin
          FAntiBan.PreDownload(VRequest, VDownloader);
        end;
        if ACancelNotifier.IsOperationCanceled(AOperationID) then begin
          Result := FDownloadResultFactory.BuildCanceled(VRequest);
        end else begin
          VConfig := FTileDownloaderConfig.GetStatic;
          VOldTileSize := FStorage.GetTileInfo(ATile, AZoom, FVersionConfig.GetStatic).GetSize;
          VDownloadChecker := TDownloadCheckerStuped.Create(
            FDownloadResultFactory,
            VConfig.IgnoreMIMEType,
            VConfig.ExpectedMIMETypes,
            VConfig.DefaultMIMEType,
            ACheckTileSize,
            VOldTileSize
          );
          Result :=
            VDownloader.DownloadTile(
              AOperationID,
              ACancelNotifier,
              VRequest,
              VDownloadChecker
            );
          if FAntiBan <> nil then begin
            Result :=
              FAntiBan.PostCheckDownload(
                FDownloadResultFactory,
                VDownloader,
                Result
              );
          end;
        end;
      end;
    end;
    if Supports(Result, IDownloadResultOk, VResultOk) then begin
      FLastResponseInfo.ResponseHead := VResultOk.RawResponseHeader;
      VResultStream := TMemoryStream.Create;
      try
        VResultStream.WriteBuffer(VResultOk.Buffer^, VResultOk.Size);
        VContentType := VResultOk.ContentType;
        VContentType := Zmp.ContentTypeSubst.GetContentType(VContentType);
        SaveTileDownload(ATile, AZoom, VResultStream, VContentType);
      finally
        VResultStream.Free;
      end;
    end else if Supports(Result, IDownloadResultDataNotExists) then begin
      if FDownloadConfig.IsSaveTileNotExists then begin
        SaveTileNotExists(ATile, AZoom);
      end;
    end;
  end else begin
    raise Exception.Create('��� ���� ����� �������� ���������.');
  end;
end;

function TMapType.GetTileShowName(AXY: TPoint; Azoom: byte): string;
begin
  if FStorageConfig.IsStoreFileCache then begin
    Result := FStorage.GetTileFileName(AXY, Azoom, FVersionConfig.GetStatic)
  end else begin
    Result := 'z' + IntToStr(Azoom + 1) + 'x' + IntToStr(AXY.X) + 'y' + IntToStr(AXY.Y);
  end;
end;

procedure TMapType.CropOnDownload(ABtm: TCustomBitmap32; ATileSize: TPoint);
var
  VBtmSrc: TCustomBitmap32;
  VBtmDest: TCustomBitmap32;
begin
  VBtmSrc := TCustomBitmap32.Create;
  try
    VBtmSrc.Assign(ABtm);
    VBtmSrc.Resampler := TLinearResampler.Create;
    VBtmDest := TCustomBitmap32.Create;
    try
      VBtmDest.SetSize(ATileSize.X, ATileSize.Y);
      VBtmDest.Draw(Bounds(0, 0, ATileSize.X, ATileSize.Y), FZmp.TilePostDownloadCropConfig.CropRect, VBtmSrc);
      ABtm.Assign(VBtmDest);
    finally
      VBtmDest.Free;
    end;
  finally
    VBtmSrc.Free;
  end;
end;

function TMapType.GetAbilitiesConfigStatic: IMapAbilitiesConfigStatic;
begin
  Result := FAbilitiesConfig.GetStatic;
end;

function TMapType.GetIsBitmapTiles: Boolean;
begin
  Result := FBitmapLoaderFromStorage <> nil;
end;

function TMapType.GetIsKmlTiles: Boolean;
begin
  Result := FKmlLoaderFromStorage <> nil;
end;

function TMapType.GetIsHybridLayer: Boolean;
begin
  Result := IsBitmapTiles and FAbilitiesConfig.IsLayer;
end;

function TMapType.LoadTile(
  btm: TCustomBitmap32;
  AXY: TPoint;
  Azoom: byte;
  IgnoreError: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
begin
  try
    if (ACache = nil) or (not ACache.TryLoadTileFromCache(btm, AXY, Azoom)) then begin
      result:=LoadBitmapTileFromStorage(AXY, Azoom, btm);
      if ((result)and(ACache <> nil)) then ACache.AddTileToCache(btm, AXY, Azoom);
    end else begin
      result:=true;
    end;
  except
    if not IgnoreError then begin
      raise;
    end else begin
      Result := False;
    end;
  end;
end;

function TMapType.LoadTile(
  var AKml: IVectorDataItemList;
  AXY: TPoint;
  Azoom: byte;
  IgnoreError: Boolean;
  ACache: ITileObjCacheVector
): boolean;
begin
  try
    if (ACache = nil) or (not ACache.TryLoadTileFromCache(AKml, AXY, Azoom)) then begin
      result:=LoadKmlTileFromStorage(AXY, Azoom, AKml);
      if ((result)and(ACache <> nil)) then ACache.AddTileToCache(AKml, AXY, Azoom);
    end else begin
      result:=true;
    end;
  except
    if not IgnoreError then begin
      raise;
    end else begin
      Result := False;
    end;
  end;
end;

function TMapType.LoadTileFromPreZ(
  spr: TCustomBitmap32;
  AXY: TPoint;
  Azoom: byte;
  IgnoreError: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
var
  i: integer;
  VBmp: TCustomBitmap32;
  VTileTargetBounds:TRect;
  VTileSourceBounds:TRect;
  VTileParent: TPoint;
  VTargetTilePixelRect: TRect;
  VSourceTilePixelRect: TRect;
  VRelative: TDoublePoint;
  VRelativeRect: TDoubleRect;
  VParentZoom: Byte;
  VMinZoom: Integer;
begin
  result:=false;
  if (ACache = nil) or (not ACache.TryLoadTilePreFromCache(spr, AXY, Azoom)) then begin
    VRelative := FCoordConverter.TilePos2Relative(AXY, Azoom);
    VMinZoom :=  Azoom - FLoadPrevMaxZoomDelta;
    if VMinZoom < 0 then begin
      VMinZoom := 0;
    end;
    if Azoom - 1 > VMinZoom then begin
      VBmp:=TCustomBitmap32.Create;
      try
        for i := Azoom - 1 downto VMinZoom do begin
          VParentZoom := i;
          VTileParent := FCoordConverter.Relative2Tile(VRelative, i);
          if LoadTile(VBmp, VTileParent, VParentZoom, IgnoreError, ACache)then begin
            VTargetTilePixelRect := FCoordConverter.TilePos2PixelRect(AXY, Azoom);
            VRelativeRect := FCoordConverter.PixelRect2RelativeRect(VTargetTilePixelRect, Azoom);
            VTileTargetBounds.Left := 0;
            VTileTargetBounds.Top := 0;
            VTileTargetBounds.Right := VTargetTilePixelRect.Right - VTargetTilePixelRect.Left;
            VTileTargetBounds.Bottom := VTargetTilePixelRect.Bottom - VTargetTilePixelRect.Top;

            VBmp.Resampler := FImageResamplerConfig.GetActiveFactory.CreateResampler;

            VSourceTilePixelRect := FCoordConverter.TilePos2PixelRect(VTileParent, VParentZoom);
            VTargetTilePixelRect := FCoordConverter.RelativeRect2PixelRect(VRelativeRect, VParentZoom);
            VTileSourceBounds.Left := VTargetTilePixelRect.Left - VSourceTilePixelRect.Left;
            VTileSourceBounds.Top := VTargetTilePixelRect.Top - VSourceTilePixelRect.Top;
            VTileSourceBounds.Right := VTargetTilePixelRect.Right - VSourceTilePixelRect.Left;
            VTileSourceBounds.Bottom := VTargetTilePixelRect.Bottom - VSourceTilePixelRect.Top;
            try
              VBmp.DrawMode := dmOpaque;
              spr.SetSize(VTileTargetBounds.Right, VTileTargetBounds.Bottom);
              spr.Draw(VTileTargetBounds, VTileSourceBounds, VBmp);
              Result := true;
              if ACache <> nil then begin
                ACache.AddTilePreToCache(spr, AXY, Azoom);
              end;
              Break;
            except
              if not IgnoreError then begin
                raise
              end;
            end;
          end;
        end;
      finally
        FreeAndNil(VBmp);
      end;
    end;
  end else begin
    result:=true;
  end;
end;

function TMapType.LoadTileOrPreZ(
  spr: TCustomBitmap32;
  AXY: TPoint;
  Azoom: byte;
  IgnoreError: Boolean;
  AUsePre: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
var
  VRect: TRect;
  VSize: TPoint;
  bSpr:TCustomBitmap32;
begin
  VRect := FCoordConverter.TilePos2PixelRect(AXY, Azoom);
  VSize := Point(VRect.Right - VRect.Left, VRect.Bottom - VRect.Top);
  Result := LoadTile(spr, AXY, Azoom, IgnoreError, ACache);
  if Result then begin
    if (spr.Width < VSize.X) or
      (spr.Height < VSize.Y) then begin
      bSpr:=TCustomBitmap32.Create;
      try
        bSpr.Assign(spr);
        spr.SetSize(VSize.X, VSize.Y);
        spr.Clear(0);
        spr.Draw(0,0,bSpr);
      finally
        bSpr.Free;
      end;
    end;
  end;
  if not Result then begin
    if AUsePre then begin
      Result := LoadTileFromPreZ(spr, AXY, Azoom, IgnoreError, ACache);
    end;
  end;
end;

function TMapType.LoadBtimap(
  spr: TCustomBitmap32;
  APixelRectTarget: TRect;
  Azoom: byte;
  AUsePre, AAllowPartial, IgnoreError: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
var
  VPixelRectTarget: TRect;
  VTileRect: TRect;
  VTargetImageSize: TPoint;
  VPixelRectCurrTile: TRect;
  i, j: Integer;
  VTile: TPoint;
  VSpr:TCustomBitmap32;
  VLoadResult: Boolean;
  VSourceBounds: TRect;
  VTargetBounds: TRect;
begin
  Result := False;

  VTargetImageSize.X := APixelRectTarget.Right - APixelRectTarget.Left;
  VTargetImageSize.Y := APixelRectTarget.Bottom - APixelRectTarget.Top;

  VPixelRectTarget := APixelRectTarget;
  FCoordConverter.CheckPixelRect(VPixelRectTarget, Azoom);
  VTileRect := FCoordConverter.PixelRect2TileRect(VPixelRectTarget, Azoom);
  if (VTileRect.Left = VTileRect.Right - 1) and
    (VTileRect.Top = VTileRect.Bottom - 1)
  then begin
    VPixelRectCurrTile := FCoordConverter.TilePos2PixelRect(VTileRect.TopLeft, Azoom);
    if
      (VPixelRectCurrTile.Left = APixelRectTarget.Left) and
      (VPixelRectCurrTile.Top = APixelRectTarget.Top) and
      (VPixelRectCurrTile.Right = APixelRectTarget.Right) and
      (VPixelRectCurrTile.Bottom = APixelRectTarget.Bottom)
    then begin
      Result := LoadTileOrPreZ(spr, VTileRect.TopLeft, Azoom, IgnoreError, AUsePre, ACache);
      exit;
    end;
  end;

  spr.SetSize(VTargetImageSize.X, VTargetImageSize.Y);
  spr.Clear(0);

  VSpr := TCustomBitmap32.Create;
  try
    for i := VTileRect.Top to VTileRect.Bottom - 1 do begin
      VTile.Y := i;
      for j := VTileRect.Left to VTileRect.Right - 1 do begin
        VTile.X := j;
        VLoadResult := LoadTileOrPreZ(VSpr, VTile, Azoom, IgnoreError, AUsePre, ACache);
        if VLoadResult then begin
          VPixelRectCurrTile := FCoordConverter.TilePos2PixelRect(VTile, Azoom);

          if VPixelRectCurrTile.Top < APixelRectTarget.Top then begin
            VSourceBounds.Top := APixelRectTarget.Top - VPixelRectCurrTile.Top;
          end else begin
            VSourceBounds.Top := 0;
          end;

          if VPixelRectCurrTile.Left < APixelRectTarget.Left then begin
            VSourceBounds.Left := APixelRectTarget.Left - VPixelRectCurrTile.Left;
          end else begin
            VSourceBounds.Left := 0;
          end;

          if VPixelRectCurrTile.Bottom < APixelRectTarget.Bottom then begin
            VSourceBounds.Bottom := VPixelRectCurrTile.Bottom - VPixelRectCurrTile.Top;
          end else begin
            VSourceBounds.Bottom := APixelRectTarget.Bottom - VPixelRectCurrTile.Top;
          end;

          if VPixelRectCurrTile.Right < APixelRectTarget.Right then begin
            VSourceBounds.Right := VPixelRectCurrTile.Right - VPixelRectCurrTile.Left;
          end else begin
            VSourceBounds.Right := APixelRectTarget.Right - VPixelRectCurrTile.Left;
          end;

          if VPixelRectCurrTile.Top < APixelRectTarget.Top then begin
            VTargetBounds.Top := 0;
          end else begin
            VTargetBounds.Top := VPixelRectCurrTile.Top - APixelRectTarget.Top;
          end;

          if VPixelRectCurrTile.Left < APixelRectTarget.Left then begin
            VTargetBounds.Left := 0;
          end else begin
            VTargetBounds.Left := VPixelRectCurrTile.Left - APixelRectTarget.Left;
          end;

          if VPixelRectCurrTile.Bottom < APixelRectTarget.Bottom then begin
            VTargetBounds.Bottom := VPixelRectCurrTile.Bottom - APixelRectTarget.Top;
          end else begin
            VTargetBounds.Bottom := APixelRectTarget.Bottom - APixelRectTarget.Top;
          end;

          if VPixelRectCurrTile.Right < APixelRectTarget.Right then begin
            VTargetBounds.Right := VPixelRectCurrTile.Right - APixelRectTarget.Left;
          end else begin
            VTargetBounds.Right := APixelRectTarget.Right - APixelRectTarget.Left;
          end;

          spr.Draw(VTargetBounds, VSourceBounds, VSpr);
        end else begin
          if not AAllowPartial then begin
            Exit;
          end;
        end;
      end;
    end;
    Result := True;
  finally
    VSpr.Free;
  end;
end;

function TMapType.LoadBtimapUni(
  spr: TCustomBitmap32;
  APixelRectTarget: TRect;
  Azoom: byte;
  ACoordConverterTarget: ICoordConverter;
  AUsePre, AAllowPartial, IgnoreError: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
var
  VPixelRectTarget: TRect;
  VLonLatRectTarget: TDoubleRect;
  VTileRectInSource: TRect;
  VPixelRectOfTargetPixelRectInSource: TRect;
  i, j: Integer;
  VTile: TPoint;
  VSpr:TCustomBitmap32;
  VLoadResult: Boolean;
  VPixelRectCurTileInSource:  TRect;
  VLonLatRectCurTile:  TDoubleRect;
  VPixelRectCurTileInTarget:  TRect;
  VSourceBounds: TRect;
  VTargetBounds: TRect;
  VTargetImageSize: TPoint;
begin
  Result := False;

  if FCoordConverter.IsSameConverter(ACoordConverterTarget) then begin
    Result := LoadBtimap(spr, APixelRectTarget, Azoom, AUsePre, AAllowPartial, IgnoreError, ACache);
  end else begin
    VTargetImageSize.X := APixelRectTarget.Right - APixelRectTarget.Left;
    VTargetImageSize.Y := APixelRectTarget.Bottom - APixelRectTarget.Top;

    spr.SetSize(VTargetImageSize.X, VTargetImageSize.Y);
    spr.Clear(0);
    VPixelRectTarget := APixelRectTarget;
    ACoordConverterTarget.CheckPixelRect(VPixelRectTarget, Azoom);
    VLonLatRectTarget := ACoordConverterTarget.PixelRect2LonLatRect(VPixelRectTarget, Azoom);
    FCoordConverter.CheckLonLatRect(VLonLatRectTarget);
    VPixelRectOfTargetPixelRectInSource := FCoordConverter.LonLatRect2PixelRect(VLonLatRectTarget, Azoom);
    VTileRectInSource := FCoordConverter.PixelRect2TileRect(VPixelRectOfTargetPixelRectInSource, Azoom);

    VSpr := TCustomBitmap32.Create;
    try
      for i := VTileRectInSource.Top to VTileRectInSource.Bottom - 1 do begin
        VTile.Y := i;
        for j := VTileRectInSource.Left to VTileRectInSource.Right - 1 do begin
          VTile.X := j;
          VLoadResult := LoadTileOrPreZ(VSpr, VTile, Azoom, IgnoreError, AUsePre, ACache);
          if VLoadResult then begin
            VPixelRectCurTileInSource := FCoordConverter.TilePos2PixelRect(VTile, Azoom);
            VLonLatRectCurTile := FCoordConverter.PixelRect2LonLatRect(VPixelRectCurTileInSource, Azoom);
            ACoordConverterTarget.CheckLonLatRect(VLonLatRectCurTile);
            VPixelRectCurTileInTarget := ACoordConverterTarget.LonLatRect2PixelRect(VLonLatRectCurTile, Azoom);

            if VPixelRectCurTileInSource.Top < VPixelRectOfTargetPixelRectInSource.Top then begin
              VSourceBounds.Top := VPixelRectOfTargetPixelRectInSource.Top - VPixelRectCurTileInSource.Top;
            end else begin
              VSourceBounds.Top := 0;
            end;

            if VPixelRectCurTileInSource.Left < VPixelRectOfTargetPixelRectInSource.Left then begin
              VSourceBounds.Left := VPixelRectOfTargetPixelRectInSource.Left - VPixelRectCurTileInSource.Left;
            end else begin
              VSourceBounds.Left := 0;
            end;

            if VPixelRectCurTileInSource.Bottom < VPixelRectOfTargetPixelRectInSource.Bottom then begin
              VSourceBounds.Bottom := VPixelRectCurTileInSource.Bottom - VPixelRectCurTileInSource.Top;
            end else begin
              VSourceBounds.Bottom := VPixelRectOfTargetPixelRectInSource.Bottom - VPixelRectCurTileInSource.Top;
            end;

            if VPixelRectCurTileInSource.Right < VPixelRectOfTargetPixelRectInSource.Right then begin
              VSourceBounds.Right := VPixelRectCurTileInSource.Right - VPixelRectCurTileInSource.Left;
            end else begin
              VSourceBounds.Right := VPixelRectOfTargetPixelRectInSource.Right - VPixelRectCurTileInSource.Left;
            end;

            if VPixelRectCurTileInTarget.Top < APixelRectTarget.Top then begin
              VTargetBounds.Top := 0;
            end else begin
              VTargetBounds.Top := VPixelRectCurTileInTarget.Top - APixelRectTarget.Top;
            end;

            if VPixelRectCurTileInTarget.Left < APixelRectTarget.Left then begin
              VTargetBounds.Left := 0;
            end else begin
              VTargetBounds.Left := VPixelRectCurTileInTarget.Left - APixelRectTarget.Left;
            end;

            if VPixelRectCurTileInTarget.Bottom < APixelRectTarget.Bottom then begin
              VTargetBounds.Bottom := VPixelRectCurTileInTarget.Bottom - APixelRectTarget.Top;
            end else begin
              VTargetBounds.Bottom := APixelRectTarget.Bottom - APixelRectTarget.Top;
            end;

            if VPixelRectCurTileInTarget.Right < APixelRectTarget.Right then begin
              VTargetBounds.Right := VPixelRectCurTileInTarget.Right - APixelRectTarget.Left;
            end else begin
              VTargetBounds.Right := APixelRectTarget.Right - APixelRectTarget.Left;
            end;

            spr.Draw(VTargetBounds, VSourceBounds, VSpr);
          end else begin
            if not AAllowPartial then begin
              Exit;
            end;
          end;
        end;
      end;
      Result := True;
    finally
      VSpr.Free;
    end;
  end;
end;

function TMapType.LoadTileUni(
  spr: TCustomBitmap32;
  AXY: TPoint;
  Azoom: byte;
  ACoordConverterTarget: ICoordConverter;
  AUsePre, AAllowPartial, IgnoreError: Boolean;
  ACache: ITileObjCacheBitmap
): boolean;
var
  VPixelRect: TRect;
begin
  VPixelRect := ACoordConverterTarget.TilePos2PixelRect(AXY, Azoom);
  Result := LoadBtimapUni(spr, VPixelRect, Azoom, ACoordConverterTarget, AUsePre, AAllowPartial, IgnoreError, ACache);
end;

end.


