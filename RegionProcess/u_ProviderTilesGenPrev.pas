unit u_ProviderTilesGenPrev;

interface

uses
  Controls,
  t_GeoTypes,
  i_LanguageManager,
  i_VectorItemLonLat,
  i_MapTypes,
  i_ActiveMapsConfig,
  i_MapTypeGUIConfigList,
  i_ImageResamplerConfig,
  i_GlobalViewMainConfig,
  u_ExportProviderAbstract,
  fr_TilesGenPrev;

type
  TProviderTilesGenPrev = class(TExportProviderAbstract)
  private
    FFrame: TfrTilesGenPrev;
    FImageResamplerConfig: IImageResamplerConfig;
    FViewConfig: IGlobalViewMainConfig;
  public
    constructor Create(
      AParent: TWinControl;
      ALanguageManager: ILanguageManager;
      AMainMapsConfig: IMainMapsConfig;
      AFullMapsSet: IMapTypeSet;
      AGUIConfigList: IMapTypeGUIConfigList;
      AViewConfig: IGlobalViewMainConfig;
      AImageResamplerConfig: IImageResamplerConfig
    );
    destructor Destroy; override;
    function GetCaption: string; override;
    procedure InitFrame(Azoom: byte; APolygon: ILonLatPolygon); override;
    procedure Show; override;
    procedure Hide; override;
    procedure RefreshTranslation; override;
    procedure StartProcess(APolygon: ILonLatPolygon); override;
  end;


implementation

uses
  SysUtils,
  GR32,
  i_ImageResamplerFactory,
  u_ThreadGenPrevZoom,
  u_ResStrings,
  u_MapType;

{ TProviderTilesGenPrev }

constructor TProviderTilesGenPrev.Create(
  AParent: TWinControl;
  ALanguageManager: ILanguageManager;
  AMainMapsConfig: IMainMapsConfig;
  AFullMapsSet: IMapTypeSet;
  AGUIConfigList: IMapTypeGUIConfigList;
  AViewConfig: IGlobalViewMainConfig;
  AImageResamplerConfig: IImageResamplerConfig
);
begin
  inherited Create(AParent, ALanguageManager, AMainMapsConfig, AFullMapsSet, AGUIConfigList);
  FViewConfig := AViewConfig;
  FImageResamplerConfig := AImageResamplerConfig;
end;

destructor TProviderTilesGenPrev.Destroy;
begin
  FreeAndNil(FFrame);
  inherited;
end;

function TProviderTilesGenPrev.GetCaption: string;
begin
  Result := SAS_STR_OperationGenPrevCaption;
end;

procedure TProviderTilesGenPrev.InitFrame(Azoom: byte; APolygon: ILonLatPolygon);
begin
  if FFrame = nil then begin
    FFrame := TfrTilesGenPrev.Create(
      nil,
      Self.MainMapsConfig,
      Self.FullMapsSet,
      Self.GUIConfigList,
      FImageResamplerConfig
    );
    FFrame.Visible := False;
    FFrame.Parent := Self.Parent;
  end;
  FFrame.Init(Azoom);
end;

procedure TProviderTilesGenPrev.RefreshTranslation;
begin
  inherited;
  if FFrame <> nil then begin
    FFrame.RefreshTranslation;
  end;
end;

procedure TProviderTilesGenPrev.Hide;
begin
  inherited;
  if FFrame <> nil then begin
    if FFrame.Visible then begin
      FFrame.Hide;
    end;
  end;
end;

procedure TProviderTilesGenPrev.Show;
begin
  inherited;
  if FFrame <> nil then begin
    if not FFrame.Visible then begin
      FFrame.Show;
    end;
  end;
end;

procedure TProviderTilesGenPrev.StartProcess(APolygon: ILonLatPolygon);
var
  i:integer;
  VInZooms: TArrayOfByte;
  VMapType: TMapType;
  VZoomsCount: Integer;
  VFromZoom: Byte;
  VResampler: IImageResamplerFactory;
begin
  inherited;
  VMapType:=TMapType(FFrame.cbbMap.Items.Objects[FFrame.cbbMap.ItemIndex]);
  VFromZoom := FFrame.cbbFromZoom.ItemIndex + 1;
  VZoomsCount := 0;
  for i:=0 to FFrame.cbbFromZoom.ItemIndex do begin
    if FFrame.chklstZooms.ItemEnabled[i] then begin
      if FFrame.chklstZooms.Checked[i] then begin
        SetLength(VInZooms, VZoomsCount + 1);
        VInZooms[VZoomsCount] := FFrame.cbbFromZoom.ItemIndex - i;
        Inc(VZoomsCount);
      end;
    end;
  end;
  try
    if FFrame.cbbResampler.ItemIndex >= 0 then begin
      VResampler := FImageResamplerConfig.GetList.Items[FFrame.cbbResampler.ItemIndex];
    end else begin
      VResampler := FImageResamplerConfig.GetActiveFactory;
    end;
  except
    VResampler := FImageResamplerConfig.GetActiveFactory;
  end;

  TThreadGenPrevZoom.Create(
    VFromZoom,
    VInZooms,
    APolygon.Item[0],
    VMapType,
    FFrame.chkReplace.Checked,
    FFrame.chkSaveFullOnly.Checked,
    FFrame.chkFromPrevZoom.Checked,
    FFrame.chkUsePrevTiles.Checked,    
    Color32(FViewConfig.BackGroundColor),
    VResampler
  );
end;

end.

