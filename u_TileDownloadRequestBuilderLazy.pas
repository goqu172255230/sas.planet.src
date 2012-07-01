unit u_TileDownloadRequestBuilderLazy;

interface

uses
  SysUtils,
  i_OperationNotifier,
  i_TileRequest,
  i_Downloader,
  i_LastResponseInfo,
  i_TileDownloadRequest,
  i_TileDownloadRequestBuilder,
  i_TileDownloadRequestBuilderFactory;

type
  TTileDownloadRequestBuilderLazy = class(TInterfacedObject, ITileDownloadRequestBuilder)
  private
    FFactory: ITileDownloadRequestBuilderFactory;
    FDownloader: IDownloader;
    FBuilder: ITileDownloadRequestBuilder;
    FBuilderCS: IReadWriteSync;
  protected
    function BuildRequest(
      const ASource: ITileRequest;
      const ALastResponseInfo: ILastResponseInfo;
      const ACancelNotifier: IOperationNotifier;
      AOperationID: Integer
    ): ITileDownloadRequest;
  public
    constructor Create(
      const ADownloader: IDownloader;
      const AFactory: ITileDownloadRequestBuilderFactory
    );
    destructor Destroy; override;
  end;

implementation

uses
  u_Synchronizer;

{ TTileDownloadRequestBuilderLazy }

constructor TTileDownloadRequestBuilderLazy.Create(
  const ADownloader: IDownloader;
  const AFactory: ITileDownloadRequestBuilderFactory
);
begin
  inherited Create;
  FBuilderCS := MakeSyncRW_Var(Self, False);
  FDownloader := ADownloader;
  FFactory := AFactory;
end;

destructor TTileDownloadRequestBuilderLazy.Destroy;
begin
  FBuilderCS := nil;
  inherited;
end;

function TTileDownloadRequestBuilderLazy.BuildRequest(
  const ASource: ITileRequest;
  const ALastResponseInfo: ILastResponseInfo;
  const ACancelNotifier: IOperationNotifier;
  AOperationID: Integer
): ITileDownloadRequest;
var
  VBuilder: ITileDownloadRequestBuilder;
begin
  Result := nil;
  if (ACancelNotifier <> nil) and (not ACancelNotifier.IsOperationCanceled(AOperationID)) then begin
    if FFactory.State.GetStatic.Enabled then begin
      // allow build
      FBuilderCS.BeginWrite;
      try
        VBuilder := FBuilder;
        if VBuilder = nil then begin
          if FFactory.State.GetStatic.Enabled then begin
            VBuilder := FFactory.BuildRequestBuilder(FDownloader);
            if VBuilder <> nil then begin
              FBuilder := VBuilder;
            end;
          end;
        end;
      finally
        FBuilderCS.EndWrite;
      end;

      if VBuilder <> nil then begin
        Result := VBuilder.BuildRequest(ASource, ALastResponseInfo, ACancelNotifier, AOperationID);
      end;
    end;
  end;
end;

end.
