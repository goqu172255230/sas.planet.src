unit u_ZmpInfo;

interface

uses
  SysUtils,
  Graphics,
  Classes,
  i_CoordConverter,
  i_ConfigDataProvider,
  i_TileRequestBuilderConfig,
  i_LanguageManager,
  i_CoordConverterFactory,
  i_ZmpInfo;

type
  TZmpInfo = class(TInterfacedObject, IZmpInfo)
  private
    FGUID: TGUID;
    FFileName: string;
    FNameDef: string;
    FName: string;
    FSortIndex: Integer;
    FInfoDef: string;
    FInfo: string;
    FBmp18: TBitmap;
    FBmp24: TBitmap;
    FHotKey: TShortCut;
    FSleep: Cardinal;
    FSeparator: Boolean;
    FParentSubMenuDef: string;
    FParentSubMenu: string;
    FEnabled: Boolean;
    FTileRequestBuilderConfig: ITileRequestBuilderConfigStatic;
    FGeoConvert: ICoordConverter;
    FMainGeoConvert: ICoordConverter;

    FConfig: IConfigDataProvider;
    FConfigIni: IConfigDataProvider;
    FConfigIniParams: IConfigDataProvider;
    FCurrentLanguageCode: string;
    FLanguageManager: ILanguageManager;
  private
    procedure LoadConfig(
      ACoordConverterFactory: ICoordConverterFactory
    );
    function LoadGUID(AConfig : IConfigDataProvider): TGUID;
    procedure LoadIcons(AConfig : IConfigDataProvider);
    procedure LoadProjectionInfo(
      AConfig : IConfigDataProvider;
      ACoordConverterFactory: ICoordConverterFactory
    );
    procedure LoadUIParams(AConfig : IConfigDataProvider);
    procedure LoadInfo(AConfig : IConfigDataProvider);
    procedure LoadTileRequestBuilderConfig(AConfig : IConfigDataProvider);

    procedure LoadByLang(ALanguageCode: string);
    procedure LoadInfoLang(AConfig : IConfigDataProvider; ALanguageCode: string);
    procedure LoadUIParamsLang(AConfig : IConfigDataProvider; ALanguageCode: string);
  protected
    function GetGUID: TGUID;
    function GetFileName: string;
    function GetName: string;
    function GetSortIndex: Integer;
    function GetInfo: string;
    function GetBmp18: TBitmap;
    function GetBmp24: TBitmap;
    function GetHotKey: TShortCut;
    function GetSleep: Cardinal;
    function GetSeparator: Boolean;
    function GetParentSubMenu: string;
    function GetEnabled: Boolean;
    function GetTileRequestBuilderConfig: ITileRequestBuilderConfigStatic;
    function GetGeoConvert: ICoordConverter;
    function GetMainGeoConvert: ICoordConverter;
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      ACoordConverterFactory: ICoordConverterFactory;
      AFileName: string;
      AConfig: IConfigDataProvider;
      Apnum: Integer
    );
    destructor Destroy; override;
  end;

  EZmpError = class(Exception);
  EZmpIniNotFound = class(EZmpError);
  EZmpParamsNotFound = class(EZmpError);
  EZmpGUIDError = class(EZmpError);

implementation

uses
  gnugettext,
  u_TileRequestBuilderConfig,
  u_ResStrings;

{ TZmpInfo }

constructor TZmpInfo.Create(
  ALanguageManager: ILanguageManager;
  ACoordConverterFactory: ICoordConverterFactory;
  AFileName: string;
  AConfig: IConfigDataProvider;
  Apnum: Integer
);
begin
  FLanguageManager := ALanguageManager;
  FNameDef:='map#'+inttostr(Apnum);
  FFileName := AFileName;
  FConfig := AConfig;
  FConfigIni := FConfig.GetSubItem('params.txt');
  if FConfigIni = nil then begin
    raise EZmpIniNotFound.Create(_('Not found "params.txt" in zmp'));
  end;
  FConfigIniParams := FConfigIni.GetSubItem('PARAMS');
  if FConfigIniParams = nil then begin
    raise EZmpParamsNotFound.Create(_('Not found PARAMS section in zmp'));
  end;

  FCurrentLanguageCode := FLanguageManager.GetCurrentLanguageCode;
  LoadConfig(ACoordConverterFactory);
  LoadByLang(FCurrentLanguageCode);
end;

destructor TZmpInfo.Destroy;
begin
  FreeAndNil(FBmp18);
  FreeAndNil(FBmp24);
  inherited;
end;

function TZmpInfo.GetBmp18: TBitmap;
begin
  Result := FBmp18;
end;

function TZmpInfo.GetBmp24: TBitmap;
begin
  Result := FBmp24;
end;

function TZmpInfo.GetEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TZmpInfo.GetFileName: string;
begin
  Result := FFileName;
end;

function TZmpInfo.GetGeoConvert: ICoordConverter;
begin
  Result := FGeoConvert;
end;

function TZmpInfo.GetGUID: TGUID;
begin
  Result := FGUID;
end;

function TZmpInfo.GetHotKey: TShortCut;
begin
  Result := FHotKey;
end;

function TZmpInfo.GetMainGeoConvert: ICoordConverter;
begin
  Result := FMainGeoConvert;
end;

function TZmpInfo.GetInfo: string;
begin
  Result := FInfo;
end;

function TZmpInfo.GetName: string;
begin
  Result := FName;
end;

function TZmpInfo.GetParentSubMenu: string;
begin
  Result := FParentSubMenu;
end;

function TZmpInfo.GetSeparator: Boolean;
begin
  Result := FSeparator;
end;

function TZmpInfo.GetSleep: Cardinal;
begin
  Result := FSleep;
end;

function TZmpInfo.GetSortIndex: Integer;
begin
  Result := FSortIndex;
end;

function TZmpInfo.GetTileRequestBuilderConfig: ITileRequestBuilderConfigStatic;
begin
  Result := FTileRequestBuilderConfig;
end;

procedure TZmpInfo.LoadByLang(ALanguageCode: string);
begin
  LoadInfoLang(FConfig, ALanguageCode);
  LoadUIParamsLang(FConfigIniParams, ALanguageCode);
end;

procedure TZmpInfo.LoadConfig(ACoordConverterFactory: ICoordConverterFactory);
begin
  FGUID := LoadGUID(FConfigIniParams);
  LoadUIParams(FConfigIniParams);
  LoadIcons(FConfig);
  LoadInfo(FConfig);
  LoadProjectionInfo(FConfigIni, ACoordConverterFactory);
  LoadTileRequestBuilderConfig(FConfigIniParams);
  FSleep := FConfigIniParams.ReadInteger('Sleep', 0);
end;

function TZmpInfo.LoadGUID(AConfig: IConfigDataProvider): TGUID;
var
  VGUIDStr: String;
begin
  VGUIDStr := AConfig.ReadString('GUID', '');
  if Length(VGUIDStr) > 0 then begin
    try
      Result := StringToGUID(VGUIDStr);
    except
      raise EZmpGUIDError.CreateResFmt(@SAS_ERR_MapGUIDBad, [VGUIDStr]);
    end;
  end else begin
    raise EZmpGUIDError.CreateRes(@SAS_ERR_MapGUIDEmpty);
  end;
end;

procedure TZmpInfo.LoadIcons(AConfig: IConfigDataProvider);
var
  VStream:TMemoryStream;
begin
  Fbmp24:=TBitmap.create;
  VStream:=TMemoryStream.Create;
  try
    try
      AConfig.ReadBinaryStream('24.bmp', VStream);
      VStream.Position:=0;
      Fbmp24.LoadFromStream(VStream);
    except
      Fbmp24.Canvas.FillRect(Fbmp24.Canvas.ClipRect);
      Fbmp24.Width:=24;
      Fbmp24.Height:=24;
      Fbmp24.Canvas.TextOut(7,3,copy(FNameDef,1,1));
    end;
  finally
    FreeAndNil(VStream);
  end;
  Fbmp18:=TBitmap.create;
  VStream:=TMemoryStream.Create;
  try
    try
      AConfig.ReadBinaryStream('18.bmp', VStream);
      VStream.Position:=0;
      Fbmp18.LoadFromStream(VStream);
    except
      Fbmp18.Canvas.FillRect(Fbmp18.Canvas.ClipRect);
      Fbmp18.Width:=18;
      Fbmp18.Height:=18;
      Fbmp18.Canvas.TextOut(3,2,copy(FName,1,1));
    end;
  finally
    FreeAndNil(VStream);
  end;
end;

procedure TZmpInfo.LoadInfo(AConfig: IConfigDataProvider);
begin
  FInfoDef := AConfig.ReadString('info.txt', '');
end;

procedure TZmpInfo.LoadInfoLang(AConfig: IConfigDataProvider; ALanguageCode: string);
begin
  FInfo := AConfig.ReadString('info_'+ALanguageCode+'.txt', FInfoDef);
end;

procedure TZmpInfo.LoadProjectionInfo(AConfig: IConfigDataProvider; ACoordConverterFactory: ICoordConverterFactory);
var
  VParams: IConfigDataProvider;
begin
  VParams := AConfig.GetSubItem('ViewInfo');
  if VParams <> nil then begin
    FMainGeoConvert := ACoordConverterFactory.GetCoordConverterByConfig(VParams);
  end;
  FGeoConvert := ACoordConverterFactory.GetCoordConverterByConfig(FConfigIniParams);
  if FMainGeoConvert = nil then begin
    FMainGeoConvert := FGeoConvert;
  end;
end;

procedure TZmpInfo.LoadTileRequestBuilderConfig(AConfig: IConfigDataProvider);
var
  VUrlBase: string;
  VRequestHead: string;
begin
  VURLBase := AConfig.ReadString('DefURLBase', '');
  VURLBase := AConfig.ReadString('URLBase', VURLBase);
  VRequestHead := AConfig.ReadString('RequestHead', '');
  VRequestHead := StringReplace(VRequestHead, '\r\n', #13#10, [rfIgnoreCase, rfReplaceAll]);
  FTileRequestBuilderConfig := TTileRequestBuilderConfigStatic.Create(VUrlBase, VRequestHead);
end;

procedure TZmpInfo.LoadUIParams(AConfig: IConfigDataProvider);
begin
  FNameDef := AConfig.ReadString('name', FNameDef);
  FHotKey :=AConfig.ReadInteger('DefHotKey', 0);
  FHotKey :=AConfig.ReadInteger('HotKey', FHotKey);
  FParentSubMenuDef := AConfig.ReadString('ParentSubMenu', '');
  FSeparator := AConfig.ReadBool('separator', false);
  FEnabled := AConfig.ReadBool('Enabled', true);
  FSortIndex := AConfig.ReadInteger('pnum', -1);
end;

procedure TZmpInfo.LoadUIParamsLang(AConfig: IConfigDataProvider; ALanguageCode: string);
begin
  FName := AConfig.ReadString('name_' + ALanguageCode, FNameDef);
  FParentSubMenu := AConfig.ReadString('ParentSubMenu_' + ALanguageCode, FParentSubMenuDef);
end;

end.
