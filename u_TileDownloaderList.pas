unit u_TileDownloaderList;

interface

uses
  i_JclNotify,
  i_ConfigDataProvider,
  i_CoordConverterFactory,
  i_LanguageManager,
  i_ZmpInfo,
  i_TileDownloaderConfig,
  i_TileDownloaderAsync,
  i_DownloadResultFactory,
  i_TTLCheckNotifier,
  i_TileDownloadRequestBuilderConfig,
  i_TileDownloaderList;

type
  TTileDownloaderList = class(TInterfacedObject, ITileDownloaderList)
  private
    FGCList: ITTLCheckNotifier;
    FAppClosingNotifier: IJclNotifier;
    FResultFactory: IDownloadResultFactory;
    FTileDownloaderConfig: ITileDownloaderConfig;
    FRequestBuilderConfig: ITileDownloadRequestBuilderConfig;
    FZmp: IZmpInfo;
    FLangManager: ILanguageManager;


    FChangeNotifier: IJclNotifier;
    FStatic: ITileDownloaderListStatic;
    FConfigListener: IJclListener;

    procedure OnConfigChange;
    function CreateDownloader: ITileDownloader;
  protected
    function GetStatic: ITileDownloaderListStatic;
    function GetChangeNotifier: IJclNotifier;
  public
    constructor Create(
      AGCList: ITTLCheckNotifier;
      AAppClosingNotifier: IJclNotifier;
      AResultFactory: IDownloadResultFactory;
      ATileDownloaderConfig: ITileDownloaderConfig;
      ARequestBuilderConfig: ITileDownloadRequestBuilderConfig;
      AZmp: IZmpInfo;
      ALangManager: ILanguageManager
    );
    destructor Destroy; override;
  end;

implementation

uses
  u_JclNotify,
  u_NotifyEventListener,
  u_LastResponseInfo,
  u_TileDownloadRequestBuilderPascalScript,
  u_TileDownloaderHttpWithTTL,
  u_TileDownloaderSimple,
  u_TileDownloaderListStatic;

{ TTileDownloaderList }

constructor TTileDownloaderList.Create(
  AGCList: ITTLCheckNotifier;
  AAppClosingNotifier: IJclNotifier;
  AResultFactory: IDownloadResultFactory;
  ATileDownloaderConfig: ITileDownloaderConfig;
  ARequestBuilderConfig: ITileDownloadRequestBuilderConfig;
  AZmp: IZmpInfo;
  ALangManager: ILanguageManager
);
begin
  FGCList := AGCList;
  FAppClosingNotifier := AAppClosingNotifier;
  FResultFactory := AResultFactory;
  FTileDownloaderConfig := ATileDownloaderConfig;
  FRequestBuilderConfig := ARequestBuilderConfig;
  FZmp := AZmp;
  FLangManager := ALangManager;

  FChangeNotifier := TJclBaseNotifier.Create;

  FConfigListener := TNotifyNoMmgEventListener.Create(Self.OnConfigChange);
  FTileDownloaderConfig.ChangeNotifier.Add(FConfigListener);
  OnConfigChange;
end;

function TTileDownloaderList.CreateDownloader: ITileDownloader;
begin
  Result :=
    TTileDownloaderSimple.Create(
      FAppClosingNotifier,
      TTileDownloadRequestBuilderPascalScript.Create(
        FZmp,
        FRequestBuilderConfig,
        FTileDownloaderConfig,
        FLangManager
      ),
      FTileDownloaderConfig,
      TTileDownloaderHttpWithTTL.Create(
        FGCList,
        FResultFactory
      ),
      TLastResponseInfo.Create
    );
end;

destructor TTileDownloaderList.Destroy;
begin
  FTileDownloaderConfig.ChangeNotifier.Remove(FConfigListener);
  FConfigListener := nil;
  FTileDownloaderConfig := nil;

  inherited;
end;

function TTileDownloaderList.GetChangeNotifier: IJclNotifier;
begin
  Result := FChangeNotifier;
end;

function TTileDownloaderList.GetStatic: ITileDownloaderListStatic;
begin
  Result := FStatic;
end;

procedure TTileDownloaderList.OnConfigChange;
var
  VStatic: ITileDownloaderListStatic;
  VList: array of ITileDownloader;
  VCount: Integer;
  VOldCount: Integer;
  VCountForCopy: Integer;
  i: Integer;
begin
  VStatic := FStatic;
  VCount := FTileDownloaderConfig.MaxConnectToServerCount;
  VOldCount := 0;
  if VStatic <> nil then begin
    VOldCount := VStatic.Count;
  end;

  if VOldCount <> VCount then begin
    SetLength(VList, VCount);
    VCountForCopy := VOldCount;
    if VCount < VCountForCopy then begin
      VCountForCopy := VCount;
    end;
    for i := 0 to VCountForCopy - 1 do begin
      VList[i] := VStatic.Item[i];
    end;
    for i := VCountForCopy to VCount - 1 do begin
      VList[i] := CreateDownloader;
    end;
    FStatic := TTileDownloaderListStatic.Create(VList);
    FChangeNotifier.Notify(nil);
  end;
end;

end.
