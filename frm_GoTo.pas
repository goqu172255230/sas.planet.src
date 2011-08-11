unit frm_GoTo;

interface

uses
  Windows,
  SysUtils,
  Forms,
  Classes,
  StdCtrls,
  ExtCtrls,
  ComCtrls,
  Controls,
  t_GeoTypes,
  i_GeoCoder,
  u_CommonFormAndFrameParents,
  u_MarksDbGUIHelper,
  fr_LonLat;

type

  TfrmGoTo = class(TCommonFormParent)
    lblZoom: TLabel;
    btnGoTo: TButton;
    cbbZoom: TComboBox;
    btnCancel: TButton;
    pnlBottomButtons: TPanel;
    cbbGeoCode: TComboBox;
    pgcSearchType: TPageControl;
    tsPlaceMarks: TTabSheet;
    tsSearch: TTabSheet;
    tsCoordinates: TTabSheet;
    cbbAllMarks: TComboBox;
    cbbSearcherType: TComboBox;
    procedure btnGoToClick(Sender: TObject);
    procedure cbbAllMarksDropDown(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FLonLat: TDoublePoint;
    FResult: IGeoCodeResult;
    frLonLatPoint: TfrLonLat;
    FMarkDBGUI: TMarksDbGUIHelper;
    FMarksList: IInterfaceList;
    function GeocodeResultFromLonLat(ASearch: WideString; ALonLat: TDoublePoint; AMessage: WideString): IGeoCodeResult;
    procedure InitGeoCoders;
    procedure EmptyGeoCoders;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ShowGeocodeModal(
      ALonLat: TDoublePoint;
      var AResult: IGeoCodeResult;
      var AZoom: Byte;
      AMarkDBGUI: TMarksDbGUIHelper
    ): Boolean;
    procedure RefreshTranslation; override;
  end;

var
  frmGoTo: TfrmGoTo;

implementation

uses
  ActiveX,
  c_GeoCoderGUIDSimple,
  i_GeoCoderList,
  i_MarksSimple,
  u_GlobalState,
  u_GeoCodeResult,
  u_GeoCodePlacemark;

{$R *.dfm}

function TfrmGoTo.GeocodeResultFromLonLat(ASearch: WideString;
  ALonLat: TDoublePoint; AMessage: WideString): IGeoCodeResult;
var
  VPlace: IGeoCodePlacemark;
  VList: IInterfaceList;
begin
  VPlace := TGeoCodePlacemark.Create(ALonLat, AMessage, 4);
  VList := TInterfaceList.Create;
  VList.Add(VPlace);
  Result := TGeoCodeResult.Create(ASearch, 203, '', VList);
end;

procedure TfrmGoTo.InitGeoCoders;
var
  VEnum: IEnumGUID;
  VGUID: TGUID;
  i: Cardinal;
  VItem: IGeoCoderListEntity;
  VIndex: Integer;
  VActiveGUID: TGUID;
  VActiveIndex: Integer;
begin
  VEnum := GState.MainFormConfig.MainGeoCoderConfig.GetList.GetGUIDEnum;
  VActiveGUID := GState.MainFormConfig.MainGeoCoderConfig.ActiveGeoCoderGUID;
  VActiveIndex := -1;
  while VEnum.Next(1, VGUID, i) = S_OK do begin
    VItem := GState.MainFormConfig.MainGeoCoderConfig.GetList.Get(VGUID);
    VItem._AddRef;
    VIndex := cbbSearcherType.Items.AddObject(VItem.GetCaption, Pointer(VItem));
    if IsEqualGUID(VGUID, VActiveGUID) then begin
      VActiveIndex := VIndex;
    end;
  end;
  if VActiveIndex < 0 then begin
    VActiveIndex := 0;
  end;
  cbbSearcherType.ItemIndex := VActiveIndex;
  GState.MainFormConfig.MainGeoCoderConfig.SearchHistory.LockRead;
  try
    for i := 0 to GState.MainFormConfig.MainGeoCoderConfig.SearchHistory.Count - 1 do begin
      cbbGeoCode.Items.Add(GState.MainFormConfig.MainGeoCoderConfig.SearchHistory.GetItem(i));
    end;
  finally
    GState.MainFormConfig.MainGeoCoderConfig.SearchHistory.LockRead;
  end;
end;

procedure TfrmGoTo.btnGoToClick(Sender: TObject);
var
  textsrch:String;
  VIndex: Integer;
  VMarkId: IMarkID;
  VMark: IMarkFull;
  VLonLat: TDoublePoint;
  VGeoCoderItem: IGeoCoderListEntity;
begin
  if pgcSearchType.ActivePage = tsPlaceMarks then begin
    VIndex := cbbAllMarks.ItemIndex;
    if VIndex >= 0 then begin
      VMarkId := IMarkId(Pointer(cbbAllMarks.Items.Objects[VIndex]));
      VMark := GState.MarksDb.MarksDb.GetMarkByID(VMarkId);
        VLonLat := VMark.GetGoToLonLat;
        FResult := GeocodeResultFromLonLat(cbbAllMarks.Text, VLonLat, VMark.name);
      ModalResult := mrOk;
    end else begin
      ModalResult := mrCancel;
    end;
  end else if pgcSearchType.ActivePage = tsCoordinates then begin
    VLonLat := frLonLatPoint.LonLat;
    textsrch := GState.ValueToStringConverterConfig.GetStatic.LonLatConvert(VLonLat);
    FResult := GeocodeResultFromLonLat(textsrch, VLonLat, textsrch);
    ModalResult := mrOk;
  end else if pgcSearchType.ActivePage = tsSearch then begin
    textsrch:= Trim(cbbGeoCode.Text);
    VGeoCoderItem := nil;
    VIndex := cbbSearcherType.ItemIndex;
    if VIndex >= 0 then begin
      VGeoCoderItem := IGeoCoderListEntity(Pointer(cbbSearcherType.Items.Objects[VIndex]));
    end;
    if VGeoCoderItem <> nil then begin
      FResult := VGeoCoderItem.GetGeoCoder.GetLocations(textsrch, FLonLat);
      GState.MainFormConfig.MainGeoCoderConfig.SearchHistory.AddItem(textsrch);
      GState.MainFormConfig.MainGeoCoderConfig.ActiveGeoCoderGUID := VGeoCoderItem.GetGUID;
      ModalResult := mrOk;
    end else begin
      ModalResult := mrCancel;
    end;
  end;
end;

procedure TfrmGoTo.RefreshTranslation;
begin
  inherited;
  frLonLatPoint.RefreshTranslation;
end;

function TfrmGoTo.ShowGeocodeModal(
  ALonLat: TDoublePoint;
  var AResult: IGeoCodeResult;
  var AZoom: Byte;
  AMarkDBGUI: TMarksDbGUIHelper
): Boolean;
begin
  FLonLat := ALonLat;
  FMarkDBGUI := AMarkDBGUI;
  frLonLatPoint.Parent := tsCoordinates;
  cbbZoom.ItemIndex := Azoom;
  frLonLatPoint.LonLat := FLonLat;
  InitGeoCoders;
  try
    if ShowModal = mrOk then begin
      Result := true;
      AResult := FResult;
      AZoom := cbbZoom.ItemIndex;
    end else begin
      Result := False;
      AResult := nil;
      AZoom := 0;
    end;
  finally
    EmptyGeoCoders;
  end;
  cbbAllMarks.Clear;
  FMarksList:=nil;
end;

procedure TfrmGoTo.cbbAllMarksDropDown(Sender: TObject);
begin
  if cbbAllMarks.Items.Count=0 then begin
    FMarksList := FMarkDBGUI.MarksDB.MarksDb.GetAllMarskIdList;
    FMarkDBGUI.MarksListToStrings(FMarksList, cbbAllMarks.Items);
  end;
end;

constructor TfrmGoTo.Create(AOwner: TComponent);
begin
  inherited;
  frLonLatPoint := TfrLonLat.Create(nil, GState.MainFormConfig.ViewPortState, GState.ValueToStringConverterConfig);
  frLonLatPoint.Width:= tsCoordinates.Width;
  frLonLatPoint.Height:= tsCoordinates.Height;
end;

destructor TfrmGoTo.Destroy;
begin
  FreeAndNil(frLonLatPoint);
  inherited;
end;

procedure TfrmGoTo.EmptyGeoCoders;
var
  VObj: IInterface;
  i: Integer;
begin
  for i := 0 to cbbSearcherType.Items.Count - 1 do begin
    VObj := IInterface(Pointer(cbbSearcherType.Items.Objects[i]));
    VObj._Release;
  end;
  cbbSearcherType.Clear;
end;

procedure TfrmGoTo.FormShow(Sender: TObject);
begin
  if pgcSearchType.ActivePage = tsPlaceMarks then begin
    cbbAllMarks.SetFocus;
  end else if pgcSearchType.ActivePage = tsCoordinates then begin
    frLonLatPoint.SetFocus;
  end else if pgcSearchType.ActivePage = tsSearch then begin
    cbbGeoCode.SetFocus;
  end;
end;

end.
