unit u_ProviderTilesDelete;

interface

uses
  Windows,
  t_GeoTypes,
  i_VectorItemLonLat,
  u_ExportProviderAbstract,
  fr_TilesDelete;

type
  TProviderTilesDelete = class(TExportProviderAbstract)
  private
    FFrame: TfrTilesDelete;
  public
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
  u_ThreadDeleteTiles,
  u_ResStrings,
  u_MapType;

{ TProviderTilesDelete }

destructor TProviderTilesDelete.Destroy;
begin
  FreeAndNil(FFrame);
  inherited;
end;

function TProviderTilesDelete.GetCaption: string;
begin
  Result := SAS_STR_OperationDeleteCaption;
end;

procedure TProviderTilesDelete.InitFrame(Azoom: byte; APolygon: ILonLatPolygon);
begin
  if FFrame = nil then begin
    FFrame := TfrTilesDelete.Create(
      nil,
      Self.MainMapsConfig,
      Self.FullMapsSet,
      Self.GUIConfigList
    );
    FFrame.Visible := False;
    FFrame.Parent := Self.Parent;
  end;
  FFrame.Init(Azoom);
end;

procedure TProviderTilesDelete.RefreshTranslation;
begin
  inherited;
  if FFrame <> nil then begin
    FFrame.RefreshTranslation;
  end;
end;

procedure TProviderTilesDelete.Hide;
begin
  inherited;
  if FFrame <> nil then begin
    if FFrame.Visible then begin
      FFrame.Hide;
    end;
  end;
end;

procedure TProviderTilesDelete.Show;
begin
  inherited;
  if FFrame <> nil then begin
    if not FFrame.Visible then begin
      FFrame.Show;
    end;
  end;
end;

procedure TProviderTilesDelete.StartProcess(APolygon: ILonLatPolygon);
var
  VMapType: TMapType;
  VDelBySize: Boolean;
  VDelSize: Cardinal;
begin
  inherited;
  if (MessageBox(FFrame.handle,pchar(SAS_MSG_youasure),pchar(SAS_MSG_coution),36)=IDYES) then begin
    VMapType:=TMapType(FFrame.cbbMap.Items.Objects[FFrame.cbbMap.ItemIndex]);
    if FFrame.cbbZoom.ItemIndex < 0 then begin
      FFrame.cbbZoom.ItemIndex := 0;
    end;
    VDelSize := 0;
    VDelBySize := FFrame.chkDelBySize.Checked;
    if VDelBySize then begin
      VDelSize := FFrame.seDelSize.Value;
    end;
    TThreadDeleteTiles.Create(
      APolygon.Item[0],
      FFrame.cbbZoom.ItemIndex,
      VMapType,
      VDelBySize,
      VDelSize
    );
  end;
end;

end.

