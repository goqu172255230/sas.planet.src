unit u_GlobalState;

interface

uses
  Windows,
  ExtCtrls,
  Graphics,
  Classes,
  IniFiles,
  SysUtils,
  GR32,
  {$IFDEF SasDebugWithJcl}
  JclDebug,
  {$ENDIF SasDebugWithJcl}
  i_JclNotify,
  i_GPSPositionFactory,
  i_LanguageManager,
  i_MemObjCache,
  i_InetConfig,
  i_ConfigDataWriteProvider,
  i_ConfigDataProvider,
  i_TileFileNameGeneratorsList,
  i_BitmapTypeExtManager,
  i_ContentTypeManager,
  i_KmlInfoSimpleLoader,
  i_MapTypeIconsList,
  i_CoordConverterFactory,
  i_LocalCoordConverterFactorySimpe,
  i_ProxySettings,
  i_GSMGeoCodeConfig,
  i_MainFormConfig,
  i_GlobalAppConfig,
  i_BitmapPostProcessingConfig,
  i_ValueToStringConverter,
  u_GarbageCollectorThread,
  i_LastSelectionInfo,
  i_DownloadInfoSimple,
  i_ImageResamplerConfig,
  i_GeoCoderList,
  i_MainMemCacheConfig,
  i_MarkPicture,
  i_InternalPerformanceCounter,
  u_LastSelectionInfo,
  u_MarksDb,
  u_MapType,
  u_MapTypesMainList,
  u_MemFileCache,
  i_GPSConfig,
  i_MarkCategoryFactoryConfig,
  i_GlobalViewMainConfig,
  i_GlobalDownloadConfig,
  i_StartUpLogoConfig,
  i_DownloadResultTextProvider,
  i_ImportFile,
  i_PathDetalizeProviderList,
  i_GPSRecorder,
  i_SatellitesInViewMapDraw,
  i_SensorList,
  u_IeEmbeddedProtocolRegistration,
  u_GPSState,
  u_GlobalCahceConfig;

type
  TGlobalState = class
  private
    FMainConfigProvider: IConfigDataWriteProvider;

    FGlobalAppConfig: IGlobalAppConfig;
    FStartUpLogoConfig: IStartUpLogoConfig;
    FTileNameGenerator: ITileFileNameGeneratorsList;
    FGCThread: TGarbageCollectorThread;
    FBitmapTypeManager: IBitmapTypeExtManager;
    FContentTypeManager: IContentTypeManager;
    FMapCalibrationList: IInterfaceList;
    FKmlLoader: IKmlInfoSimpleLoader;
    FKmzLoader: IKmlInfoSimpleLoader;
    FCacheConfig: TGlobalCahceConfig;
    FMapTypeIcons18List: IMapTypeIconsList;
    FMapTypeIcons24List: IMapTypeIconsList;
    FLanguageManager: ILanguageManager;
    FLastSelectionInfo: ILastSelectionInfo;
    FMarksDB: TMarksDB;
    FCoordConverterFactory: ICoordConverterFactory;
    FLocalConverterFactory: ILocalCoordConverterFactorySimpe;
    FMainMapsList: TMapTypesMainList;
    FInetConfig: IInetConfig;
    FGPSConfig: IGPSConfig;
    FGSMpar: IGSMGeoCodeConfig;
    FGPSPositionFactory: IGPSPositionFactory;
    FMainFormConfig: IMainFormConfig;
    FBitmapPostProcessingConfig: IBitmapPostProcessingConfig;
    FValueToStringConverterConfig: IValueToStringConverterConfig;
    FDownloadInfo: IDownloadInfoSimple;
    FDownloadConfig: IGlobalDownloadConfig;
    FProgramPath: string;
    FImageResamplerConfig: IImageResamplerConfig;
    FGeoCoderList: IGeoCoderList;
    FMainMemCacheBitmap: IMemObjCacheBitmap;
    FMainMemCacheVector: IMemObjCacheVector;
    FMainMemCacheConfig: IMainMemCacheConfig;
    FMarkPictureList: IMarkPictureList;
    FMarksCategoryFactoryConfig: IMarkCategoryFactoryConfig;
    FGPSpar: TGPSpar;
    FImportFileByExt: IImportFile;
    FViewConfig: IGlobalViewMainConfig;
    FGPSRecorder: IGPSRecorder;
    FSkyMapDraw: ISatellitesInViewMapDraw;
    FGUISyncronizedTimer: TTimer;
    FGUISyncronizedTimerNotifier: IJclNotifier;
    FSensorList: ISensorList;
    FPerfCounterList: IInternalPerformanceCounterList;
    FDownloadResultTextProvider: IDownloadResultTextProvider;
    FProtocol: TIeEmbeddedProtocolRegistration;
    FPathDetalizeList: IPathDetalizeProviderList;

    procedure OnGUISyncronizedTimer(Sender: TObject);
    function GetMarkIconsPath: string;
    function GetMapsPath: string;
    function GetTrackLogPath: string;
    procedure LoadMapIconsList;
    {$IFDEF SasDebugWithJcl}
    procedure DoException(Sender: TObject; E: Exception);
    {$ENDIF SasDebugWithJcl}
    // ���� � ����� � �������
    property MapsPath: string read GetMapsPath;
  public
    property MapType: TMapTypesMainList read FMainMapsList;
    property CacheConfig: TGlobalCahceConfig read FCacheConfig;
    property GCThread: TGarbageCollectorThread read FGCThread;
    property MarksDB: TMarksDB read FMarksDB;
    property GPSpar: TGPSpar read FGPSpar;
    property ProgramPath: string read FProgramPath;

    property GlobalAppConfig: IGlobalAppConfig read FGlobalAppConfig;
    // ������ ����������� ���� ������ � �������
    property TileNameGenerator: ITileFileNameGeneratorsList read FTileNameGenerator;
    // �������� ����� ��������� ������. ������������, ������ ����� ����� ����� ���� �����������.
    property BitmapTypeManager: IBitmapTypeExtManager read FBitmapTypeManager;
    property ContentTypeManager: IContentTypeManager read FContentTypeManager;
    property CoordConverterFactory: ICoordConverterFactory read FCoordConverterFactory;
    property LocalConverterFactory: ILocalCoordConverterFactorySimpe read FLocalConverterFactory;
    property MapCalibrationList: IInterfaceList read FMapCalibrationList;
    property MapTypeIcons18List: IMapTypeIconsList read FMapTypeIcons18List;
    property MapTypeIcons24List: IMapTypeIconsList read FMapTypeIcons24List;

    property MainConfigProvider: IConfigDataWriteProvider read FMainConfigProvider;
    property LastSelectionInfo: ILastSelectionInfo read FLastSelectionInfo;
    property DownloadInfo: IDownloadInfoSimple read FDownloadInfo;
    property MainMemCacheBitmap: IMemObjCacheBitmap read FMainMemCacheBitmap;
    property MainMemCacheVector: IMemObjCacheVector read FMainMemCacheVector;
    property ImportFileByExt: IImportFile read FImportFileByExt;
    property DownloadResultTextProvider: IDownloadResultTextProvider read FDownloadResultTextProvider;
    property SkyMapDraw: ISatellitesInViewMapDraw read FSkyMapDraw;
    property GUISyncronizedTimerNotifier: IJclNotifier read FGUISyncronizedTimerNotifier;
    property PerfCounterList: IInternalPerformanceCounterList read FPerfCounterList;

    property LanguageManager: ILanguageManager read FLanguageManager;
    property GSMpar: IGSMGeoCodeConfig read FGSMpar;
    property InetConfig: IInetConfig read FInetConfig;
    property MainFormConfig: IMainFormConfig read FMainFormConfig;
    property BitmapPostProcessingConfig: IBitmapPostProcessingConfig read FBitmapPostProcessingConfig;
    property ValueToStringConverterConfig: IValueToStringConverterConfig read FValueToStringConverterConfig;
    property ImageResamplerConfig: IImageResamplerConfig read FImageResamplerConfig;
    property MainMemCacheConfig: IMainMemCacheConfig read FMainMemCacheConfig;
    property GPSConfig: IGPSConfig read FGPSConfig;
    property MarksCategoryFactoryConfig: IMarkCategoryFactoryConfig read FMarksCategoryFactoryConfig;
    property ViewConfig: IGlobalViewMainConfig read FViewConfig;
    property GPSRecorder: IGPSRecorder read FGPSRecorder;
    property PathDetalizeList: IPathDetalizeProviderList read FPathDetalizeList;
    property SensorList: ISensorList read FSensorList;
    property DownloadConfig: IGlobalDownloadConfig read FDownloadConfig;
    property StartUpLogoConfig: IStartUpLogoConfig read FStartUpLogoConfig;

    constructor Create;
    destructor Destroy; override;
    procedure LoadConfig;
    procedure SaveMainParams;
    procedure StartThreads;
    procedure SendTerminateToThreads;

    procedure StartExceptionTracking;
    procedure StopExceptionTracking;
  end;

var
  GState: TGlobalState;

implementation

uses
  Types,
  Forms,
  u_JclNotify,
  i_BitmapTileSaveLoad,
  u_SASMainConfigProvider,
  u_ConfigDataProviderByIniFile,
  u_ConfigDataWriteProviderByIniFile,
  i_ListOfObjectsWithTTL,
  u_ListOfObjectsWithTTL,
  u_BitmapTypeExtManagerSimple,
  u_ContentTypeManagerSimple,
  u_MapCalibrationListBasic,
  u_KmlInfoSimpleParser,
  u_KmzInfoSimpleParser,
  u_MapTypeIconsList,
  u_CoordConverterFactorySimple,
  u_LanguageManager,
  u_DownloadInfoSimple,
  u_StartUpLogoConfig,
  u_InetConfig,
  u_Datum,
  u_GSMGeoCodeConfig,
  u_GPSConfig,
  u_MarkCategoryFactoryConfig,
  u_GeoCoderListSimple,
  u_BitmapPostProcessingConfig,
  u_ValueToStringConverterConfig,
  u_GlobalAppConfig,
  u_MainMemCacheConfig,
  u_MarkPictureListSimple,
  u_ImageResamplerConfig,
  u_ImageResamplerFactoryListStaticSimple,
  u_ImportByFileExt,
  u_GlobalViewMainConfig,
  u_GlobalDownloadConfig,
  u_GPSRecorderStuped,
  u_GPSLogWriterToPlt,
  u_SatellitesInViewMapDrawSimple,
  u_GPSModuleFactoryByZylGPS,
  u_GPSPositionFactory,
  u_LocalCoordConverterFactorySimpe,
  u_DownloadResultTextProvider,
  u_MainFormConfig,
  u_SensorListStuped,
  u_InternalPerformanceCounterList,
  u_IeEmbeddedProtocolFactory,
  u_PathDetalizeProviderListSimple,
  u_InternalDomainInfoProviderList,
  u_InternalDomainInfoProviderByMapTypeList,
  u_ResStrings,
  u_TileFileNameGeneratorsSimpleList;

{ TGlobalState }

constructor TGlobalState.Create;
var
  VList: IListOfObjectsWithTTL;
  VViewCnonfig: IConfigDataProvider;
  VInternalDomainInfoProviderList: TInternalDomainInfoProviderList;
begin
  FProgramPath := ExtractFilePath(ParamStr(0));
  FMainConfigProvider := TSASMainConfigProvider.Create(FProgramPath, ExtractFileName(ParamStr(0)), HInstance);

  FGUISyncronizedTimer := TTimer.Create(nil);
  FGUISyncronizedTimer.Enabled := False;
  FGUISyncronizedTimer.Interval := 500;
  FGUISyncronizedTimer.OnTimer := Self.OnGUISyncronizedTimer;

  FPerfCounterList := TInternalPerformanceCounterList.Create('Main');

  FGUISyncronizedTimerNotifier := TJclBaseNotifier.Create;

  FGlobalAppConfig := TGlobalAppConfig.Create;

  FLocalConverterFactory := TLocalCoordConverterFactorySimpe.Create;

  FCacheConfig := TGlobalCahceConfig.Create;
  FDownloadInfo := TDownloadInfoSimple.Create(nil);
  FMainMapsList := TMapTypesMainList.Create;
  VViewCnonfig := FMainConfigProvider.GetSubItem('VIEW');
  FLanguageManager := TLanguageManager.Create;
  FLanguageManager.ReadConfig(VViewCnonfig);
  if VViewCnonfig <> nil then begin
    FGlobalAppConfig.ReadConfig(VViewCnonfig);
  end;
  FDownloadConfig := TGlobalDownloadConfig.Create;
  FImageResamplerConfig :=
    TImageResamplerConfig.Create(
      TImageResamplerFactoryListStaticSimple.Create
    );
  FInetConfig := TInetConfig.Create;
  FGPSConfig := TGPSConfig.Create(GetTrackLogPath);
  FGPSPositionFactory := TGPSPositionFactory.Create;
  FGPSRecorder :=
    TGPSRecorderStuped.Create(
      TDatum.Create(3395, 6378137, 6356752),
      FGPSPositionFactory
    );
  FGSMpar := TGSMGeoCodeConfig.Create;
  FCoordConverterFactory := TCoordConverterFactorySimple.Create;
  FMainMemCacheConfig := TMainMemCacheConfig.Create;
  FViewConfig := TGlobalViewMainConfig.Create;

  FMainMemCacheBitmap := TMemFileCacheBitmap.Create(FMainMemCacheConfig, FPerfCounterList.CreateAndAddNewSubList('BitmapCache'));
  FMainMemCacheVector := TMemFileCacheVector.Create(FMainMemCacheConfig, FPerfCounterList.CreateAndAddNewSubList('VectorCache'));

  FTileNameGenerator := TTileFileNameGeneratorsSimpleList.Create;
  FBitmapTypeManager := TBitmapTypeExtManagerSimple.Create;
  FContentTypeManager := TContentTypeManagerSimple.Create;

  FStartUpLogoConfig := TStartUpLogoConfig.Create(FContentTypeManager);
  FStartUpLogoConfig.ReadConfig(FMainConfigProvider.GetSubItem('StartUpLogo'));

  FMapCalibrationList := TMapCalibrationListBasic.Create;
  FKmlLoader := TKmlInfoSimpleParser.Create;
  FKmzLoader := TKmzInfoSimpleParser.Create;
  FImportFileByExt := TImportByFileExt.Create(FKmlLoader, FKmzLoader);
  VList := TListOfObjectsWithTTL.Create;
  FGCThread := TGarbageCollectorThread.Create(VList, 1000);
  FBitmapPostProcessingConfig := TBitmapPostProcessingConfig.Create;
  FValueToStringConverterConfig := TValueToStringConverterConfig.Create(FLanguageManager);
  FGPSpar :=
    TGPSpar.Create(
      TGPSModuleFactoryByZylGPS.Create(FGPSPositionFactory),
      TPltLogWriter.Create(GetTrackLogPath),
      FGPSConfig,
      FGPSRecorder,
      GUISyncronizedTimerNotifier,
      FPerfCounterList
    );
  FLastSelectionInfo := TLastSelectionInfo.Create;
  FGeoCoderList := TGeoCoderListSimple.Create(FInetConfig.ProxyConfig as IProxySettings);
  FMarkPictureList := TMarkPictureListSimple.Create(GetMarkIconsPath, FBitmapTypeManager);
  FMarksCategoryFactoryConfig := TMarkCategoryFactoryConfig.Create(SAS_STR_NewCategory);
  FMarksDB := TMarksDB.Create(FProgramPath, FMarkPictureList, FMarksCategoryFactoryConfig);
  FSkyMapDraw := TSatellitesInViewMapDrawSimple.Create;
  FDownloadResultTextProvider := TDownloadResultTextProvider.Create(FLanguageManager);
  FPathDetalizeList := TPathDetalizeProviderListSimple.Create(FLanguageManager, FKmlLoader);
  VInternalDomainInfoProviderList := TInternalDomainInfoProviderList.Create;
  VInternalDomainInfoProviderList.Add('ZmpInfo', TInternalDomainInfoProviderByMapTypeList.Create);
  FProtocol := TIeEmbeddedProtocolRegistration.Create('sas', TIeEmbeddedProtocolFactory.Create(VInternalDomainInfoProviderList));
end;

destructor TGlobalState.Destroy;
begin
  FGCThread.Terminate;
  FGCThread.WaitFor;
  FreeAndNil(FGCThread);
  FLanguageManager := nil;
  FMainMemCacheBitmap := nil;
  FMainMemCacheVector := nil;
  FTileNameGenerator := nil;
  FBitmapTypeManager := nil;
  FContentTypeManager := nil;
  FMapCalibrationList := nil;
  FKmlLoader := nil;
  FKmzLoader := nil;
  FreeAndNil(FMarksDB);
  FMapTypeIcons18List := nil;
  FMapTypeIcons24List := nil;
  FLastSelectionInfo := nil;
  FGPSConfig := nil;
  FGPSRecorder := nil;
  FreeAndNil(FGPSpar);
  FreeAndNil(FMainMapsList);
  FCoordConverterFactory := nil;
  FGSMpar := nil;
  FInetConfig := nil;
  FViewConfig := nil;
  FImageResamplerConfig := nil;
  FMainFormConfig := nil;
  FBitmapPostProcessingConfig := nil;
  FValueToStringConverterConfig := nil;
  FMainMemCacheConfig := nil;
  FMarksCategoryFactoryConfig := nil;
  FMarkPictureList := nil;
  FreeAndNil(FCacheConfig);
  FSkyMapDraw := nil;
  FreeAndNil(FProtocol);
  FreeAndNil(FGUISyncronizedTimer);
  FGUISyncronizedTimerNotifier := nil;
  FMainConfigProvider := nil;
  inherited;
end;

{$IFDEF SasDebugWithJcl}
procedure TGlobalState.DoException(Sender: TObject; E: Exception);
var
  Str: TStringList;
begin
  Str := TStringList.Create;
  try
    JclLastExceptStackListToStrings(Str, True, True, True, True);
    Str.Insert(0, E.Message);
    Str.Insert(1, '');
    Application.MessageBox(PChar(Str.Text), '������', MB_OK or MB_ICONSTOP);
  finally
    FreeAndNil(Str);
  end;
end;
{$ENDIF SasDebugWithJcl}

procedure TGlobalState.StartExceptionTracking;
begin
  {$IFDEF SasDebugWithJcl}
  JclStackTrackingOptions := JclStackTrackingOptions + [stRAWMode];
  JclStartExceptionTracking;
  Application.OnException := DoException;
  {$ENDIF SasDebugWithJcl}
end;

procedure TGlobalState.StartThreads;
begin
  GPSpar.StartThreads;
  FGUISyncronizedTimer.Enabled := True;
end;

procedure TGlobalState.StopExceptionTracking;
begin
  {$IFDEF SasDebugWithJcl}
  Application.OnException := nil;
  JclStopExceptionTracking;
  {$ENDIF SasDebugWithJcl}
end;

function TGlobalState.GetMarkIconsPath: string;
begin
  Result := FProgramPath + 'marksicons' + PathDelim;
end;

function TGlobalState.GetMapsPath: string;
begin
  Result := FProgramPath + 'Maps' + PathDelim;
end;

function TGlobalState.GetTrackLogPath: string;
begin
  Result := FProgramPath + 'TrackLog' + PathDelim;
end;

procedure TGlobalState.LoadConfig;
var
  VLocalMapsConfig: IConfigDataProvider;
  Ini: TMeminifile;
begin
  CreateDir(MapsPath);
  Ini := TMeminiFile.Create(MapsPath + 'Maps.ini');
  VLocalMapsConfig := TConfigDataProviderByIniFile.Create(Ini);
  FMainMapsList.LoadMaps(
    FLanguageManager,
    FCoordConverterFactory,
    VLocalMapsConfig,
    MapsPath
  );
  FMainFormConfig := TMainFormConfig.Create(
    FLocalConverterFactory,
    FContentTypeManager,
    FGeoCoderList,
    FMainMapsList.MapsList,
    FMainMapsList.LayersList,
    FMainMapsList.FirstMainMap.Zmp.GUID,
    FPerfCounterList.CreateAndAddNewSubList('ViewState')
  );

  FSensorList := TSensorListStuped.Create(
      FLanguageManager,
      FMainFormConfig.ViewPortState,
      FMainFormConfig.NavToPoint,
      FGPSRecorder,
      FValueToStringConverterConfig
    );

  FCacheConfig.LoadConfig(FMainConfigProvider);
  LoadMapIconsList;
  FViewConfig.ReadConfig(MainConfigProvider.GetSubItem('View'));
  FGPSRecorder.ReadConfig(MainConfigProvider.GetSubItem('GPS'));
  FGPSConfig.ReadConfig(MainConfigProvider.GetSubItem('GPS'));
  FInetConfig.ReadConfig(MainConfigProvider.GetSubItem('Internet'));
  FDownloadConfig.ReadConfig(MainConfigProvider.GetSubItem('Internet'));
  FGSMpar.ReadConfig(MainConfigProvider.GetSubItem('GSM'));
  FBitmapPostProcessingConfig.ReadConfig(MainConfigProvider.GetSubItem('COLOR_LEVELS'));
  FValueToStringConverterConfig.ReadConfig(MainConfigProvider.GetSubItem('ValueFormats'));
  FMainFormConfig.ReadConfig(MainConfigProvider);
  FLastSelectionInfo.ReadConfig(MainConfigProvider.GetSubItem('LastSelection'));
  FImageResamplerConfig.ReadConfig(MainConfigProvider.GetSubItem('View'));
  FMainMemCacheConfig.ReadConfig(MainConfigProvider.GetSubItem('View'));
  FMarkPictureList.ReadConfig(MainConfigProvider);
  FMarksCategoryFactoryConfig.ReadConfig(MainConfigProvider.GetSubItem('MarkNewCategory'));
  FMarksDb.ReadConfig(MainConfigProvider);
end;

procedure TGlobalState.LoadMapIconsList;
var
  i: Integer;
  VMapType: TMapType;
  VList18: TMapTypeIconsList;
  VList24: TMapTypeIconsList;
begin
  VList18 := TMapTypeIconsList.Create(18, 18);
  FMapTypeIcons18List := VList18;

  VList24 := TMapTypeIconsList.Create(24, 24);
  FMapTypeIcons24List := VList24;

  for i := 0 to MapType.Count - 1 do begin
    VMapType := MapType[i];
    VList18.Add(VMapType.Zmp.GUID, VMapType.Zmp.Bmp18);
    VList24.Add(VMapType.Zmp.GUID, VMapType.Zmp.Bmp24);
  end;
end;

procedure TGlobalState.OnGUISyncronizedTimer(Sender: TObject);
begin
  FGUISyncronizedTimerNotifier.Notify(nil);
end;

procedure TGlobalState.SaveMainParams;
var
  Ini: TMeminifile;
  VLocalMapsConfig: IConfigDataWriteProvider;
begin
  Ini := TMeminiFile.Create(MapsPath + 'Maps.ini');
  VLocalMapsConfig := TConfigDataWriteProviderByIniFile.Create(Ini);
  FMainMapsList.SaveMaps(VLocalMapsConfig);

  FGPSRecorder.WriteConfig(MainConfigProvider.GetOrCreateSubItem('GPS'));
  FGPSConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('GPS'));
  FInetConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('Internet'));
  FDownloadConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('Internet'));
  FGSMpar.WriteConfig(MainConfigProvider.GetOrCreateSubItem('GSM'));
  FViewConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('View'));
  FLastSelectionInfo.WriteConfig(MainConfigProvider.GetOrCreateSubItem('LastSelection'));
  FLanguageManager.WriteConfig(FMainConfigProvider.GetOrCreateSubItem('VIEW'));
  FGlobalAppConfig.WriteConfig(FMainConfigProvider.GetOrCreateSubItem('VIEW'));
  FStartUpLogoConfig.WriteConfig(FMainConfigProvider.GetOrCreateSubItem('StartUpLogo'));
  FBitmapPostProcessingConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('COLOR_LEVELS'));
  FValueToStringConverterConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('ValueFormats'));
  FMainFormConfig.WriteConfig(MainConfigProvider);
  FCacheConfig.SaveConfig(FMainConfigProvider);
  FImageResamplerConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('View'));
  FMainMemCacheConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('View'));
  FMarkPictureList.WriteConfig(MainConfigProvider);
  FMarksCategoryFactoryConfig.WriteConfig(MainConfigProvider.GetOrCreateSubItem('MarkNewCategory'));
  FMarksDb.WriteConfig(MainConfigProvider);
end;

procedure TGlobalState.SendTerminateToThreads;
begin
  FGUISyncronizedTimer.Enabled := False;
  GPSpar.SendTerminateToThreads;
  FGCThread.Terminate;
end;

end.
