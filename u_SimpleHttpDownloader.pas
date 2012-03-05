unit u_SimpleHttpDownloader;

interface

uses
  i_OperationNotifier,
  i_Downloader,
  i_InetConfig,
  i_SimpleHttpDownloader;

type
  TSimpleHttpDownloader = class(TInterfacedObject, ISimpleHttpDownloader)
  private
    FDownloader: IDownloader;
    FInetConfig: IInetConfigStatic;
    FCancelNotifier: IOperationNotifier;
    FOperationID: Integer;
  protected
    function DoHttpRequest(const ARequestUrl, ARequestHeader, APostData: string; out AResponseHeader, AResponseData: string): Cardinal;
  public
    constructor Create(
      ADownloader: IDownloader;
      AInetConfig: IInetConfigStatic;
      ACancelNotifier: IOperationNotifier;
      AOperationID: Integer
    );
  end;

implementation

uses
  SysUtils,
  i_DownloadRequest,
  i_DownloadResult,
  u_DownloadRequest;

{ TSimpleHttpDownloader }

constructor TSimpleHttpDownloader.Create(
  ADownloader: IDownloader;
  AInetConfig: IInetConfigStatic;
  ACancelNotifier: IOperationNotifier;
  AOperationID: Integer
);
begin
  FDownloader := ADownloader;
  FInetConfig := AInetConfig;
  FCancelNotifier := ACancelNotifier;
  FOperationID := AOperationID;
end;

function TSimpleHttpDownloader.DoHttpRequest(
  const ARequestUrl, ARequestHeader, APostData: string;
  out AResponseHeader, AResponseData: string
): Cardinal;
var
  VRequest: IDownloadRequest;
  VResult: IDownloadResult;
  VResultOk: IDownloadResultOk;
  VResultWithRespond: IDownloadResultWithServerRespond;
begin
  Result := 0;
  AResponseHeader := '';
  AResponseData := '';
  if not FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    if Length(APostData) > 0 then begin
      VRequest :=
        TDownloadPostRequest.Create(
          ARequestUrl,
          ARequestHeader,
          @APostData[1],
          Length(APostData),
          FInetConfig
        );
    end else begin
      VRequest :=
        TDownloadRequest.Create(
          ARequestUrl,
          ARequestHeader,
          FInetConfig
        );
    end;
    VResult := FDownloader.DoRequest(VRequest, FCancelNotifier, FOperationID);
    if VRequest <> nil then begin
      if Supports(VResult, IDownloadResultWithServerRespond, VResultWithRespond) then begin
        AResponseHeader := VResultWithRespond.RawResponseHeader;
        Result := VResultWithRespond.StatusCode;
        if Supports(VResult, IDownloadResultOk, VResultOk) then begin
          AResponseHeader := VResultOk.RawResponseHeader;
          SetLength(AResponseData, VResultOk.Size);
          Move(VResultOk.Buffer^, AResponseData[1], VResultOk.Size);
        end;
      end;
    end;
  end;
end;

end.
