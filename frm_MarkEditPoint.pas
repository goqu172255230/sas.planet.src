unit frm_MarkEditPoint;

interface

uses
  Windows,
  SysUtils,
  Classes,
  Controls,
  Forms,
  Dialogs,
  graphics,
  ExtCtrls,
  StdCtrls,
  Grids,
  Buttons,
  Spin,
  GR32,
  GR32_Resamplers,
  u_CommonFormAndFrameParents,
  UResStrings,
  i_MarkPicture,
  i_MarksSimple,
  i_MarkCategory,
  u_MarksDbGUIHelper,
  fr_MarkDescription,
  fr_LonLat,
  t_GeoTypes;

type
  TfrmMarkEditPoint = class(TCommonFormParent)
    edtName: TEdit;
    lblName: TLabel;
    btnOk: TButton;
    btnCancel: TButton;
    Bevel1: TBevel;
    chkVisible: TCheckBox;
    clrbxTextColor: TColorBox;
    lblTextColor: TLabel;
    lblShadowColor: TLabel;
    seFontSize: TSpinEdit;
    lblFontSize: TLabel;
    clrbxShadowColor: TColorBox;
    lblIconSize: TLabel;
    seIconSize: TSpinEdit;
    seTransp: TSpinEdit;
    lblTransp: TLabel;
    btnTextColor: TSpeedButton;
    btnShadowColor: TSpeedButton;
    ColorDialog1: TColorDialog;
    lblCategory: TLabel;
    CBKateg: TComboBox;
    drwgrdIcons: TDrawGrid;
    imgIcon: TImage;
    pnlBottomButtons: TPanel;
    flwpnlTrahsparent: TFlowPanel;
    flwpnlTextColor: TFlowPanel;
    flwpnlShadowColor: TFlowPanel;
    flwpnlFontSize: TFlowPanel;
    flwpnlIconSize: TFlowPanel;
    grdpnlStyleRows: TGridPanel;
    grdpnlLine1: TGridPanel;
    grdpnlLine2: TGridPanel;
    pnlDescription: TPanel;
    pnlLonLat: TPanel;
    pnlTop: TPanel;
    pnlImage: TPanel;
    pnlTopMain: TPanel;
    pnlCategory: TPanel;
    pnlName: TPanel;
    procedure btnOkClick(Sender: TObject);
    procedure btnTextColorClick(Sender: TObject);
    procedure btnShadowColorClick(Sender: TObject);
    procedure drwgrdIconsDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure imgIconMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure drwgrdIconsMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
  private
    FPicName: string;
    FPic: IMarkPicture;
    frMarkDescription: TfrMarkDescription;
    frLonLatPoint: TfrLonLat;
    FMarkDBGUI: TMarksDbGUIHelper;
    FCategoryList: IInterfaceList;
    FCategory: IMarkCategory;
    procedure DrawFromMarkIcons(canvas:TCanvas; APic: IMarkPicture; bound:TRect);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function EditMark(AMark: IMarkFull; AMarkDBGUI: TMarksDbGUIHelper): IMarkFull;
    procedure RefreshTranslation; override;
  end;

var
  frmMarkEditPoint: TfrmMarkEditPoint;

implementation

uses
  Math;

{$R *.dfm}

function TfrmMarkEditPoint.EditMark(AMark: IMarkFull; AMarkDBGUI: TMarksDbGUIHelper): IMarkFull;
var
  VLastUsedCategoryName:string;
  i: Integer;
  VCategory: IMarkCategory;
  VId: integer;
  VPicCount: Integer;
  VColCount: Integer;
  VRowCount: Integer;
  VPictureList: IMarkPictureList;
  VLonLat:TDoublePoint;
begin
  FMarkDBGUI := AMarkDBGUI;
  frMarkDescription.Description:='';
  VLastUsedCategoryName:=CBKateg.Text;
  FCategoryList := FMarkDBGUI.MarksDB.CategoryDB.GetCategoriesList;
  try
    FMarkDBGUI.CategoryListToStrings(FCategoryList, CBKateg.Items);
    CBKateg.Sorted:=true;
    CBKateg.Text:=VLastUsedCategoryName;
    VPictureList := FMarkDBGUI.MarkPictureList;
    VPicCount := VPictureList.Count;
    VColCount := drwgrdIcons.ColCount;
    VRowCount := VPicCount div VColCount;
    if (VPicCount mod VColCount) > 0 then begin
      Inc(VRowCount);
    end;
    drwgrdIcons.RowCount := VRowCount;
    drwgrdIcons.Repaint;
    FPicName := AMark.PicName;
    FPic := AMark.Pic;
    edtName.Text:=AMark.name;
    frMarkDescription.Description:=AMark.Desc;
    seFontSize.Value:=AMark.Scale1;
    seIconSize.Value:=AMark.Scale2;
    seTransp.Value:=100-round(AlphaComponent(AMark.Color1)/255*100);
    clrbxTextColor.Selected:=WinColor(AMark.Color1);
    clrbxShadowColor.Selected:=WinColor(AMark.Color2);
    chkVisible.Checked:= FMarkDBGUI.MarksDB.MarksDb.GetMarkVisible(AMark);
    VId := AMark.CategoryId;
    for i := 0 to CBKateg.Items.Count - 1 do begin
      VCategory := IMarkCategory(Pointer(CBKateg.Items.Objects[i]));
      if VCategory <> nil then begin
        if VCategory.id = VId then begin
          CBKateg.ItemIndex := i;
          Break;
        end;
      end;
    end;
    if AMark.IsNew then begin
      Caption:=SAS_STR_AddNewMark;
      btnOk.Caption:=SAS_STR_Add;
    end else begin
      Caption:=SAS_STR_EditMark;
      btnOk.Caption:=SAS_STR_Edit;
    end;
    DrawFromMarkIcons(imgIcon.canvas, AMark.Pic, bounds(4,4,36,36));
    frLonLatPoint.LonLat := AMark.Points[0];
    if ShowModal=mrOk then begin
      VLonLat := frLonLatPoint.LonLat;
      Result := AMarkDBGUI.MarksDB.MarksDb.Factory.ModifyPoint(
        AMark,
        edtName.Text,
        chkVisible.Checked,
        FPicName,
        FPic,
        FCategory,
        frMarkDescription.Description,
        VLonLat,
        SetAlpha(Color32(clrbxTextColor.Selected),round(((100-seTransp.Value)/100)*256)),
        SetAlpha(Color32(clrbxShadowColor.Selected),round(((100-seTransp.Value)/100)*256)),
        seFontSize.Value,
        seIconSize.Value
      );
    end else begin
      Result := nil;
    end;
  finally
    FCategoryList := nil;
  end;
end;

procedure TfrmMarkEditPoint.btnOkClick(Sender: TObject);
var
  VIndex: Integer;
  VCategoryText: string;
begin
  FCategory := nil;
  VCategoryText := CBKateg.Text;
  VIndex := CBKateg.ItemIndex;
  if VIndex < 0 then begin
    VIndex:= CBKateg.Items.IndexOf(VCategoryText);
  end;
  if VIndex >= 0 then begin
    FCategory := IMarkCategory(Pointer(CBKateg.Items.Objects[VIndex]));
  end;
  if FCategory = nil then begin
    FCategory := FMarkDBGUI.AddKategory(VCategoryText);
  end;
  ModalResult := mrOk;
end;

procedure TfrmMarkEditPoint.FormShow(Sender: TObject);
begin
  frLonLatPoint.Parent := pnlLonLat;
  frMarkDescription.Parent := pnlDescription;
  edtName.SetFocus;
  drwgrdIcons.Visible:=false;
end;

procedure TfrmMarkEditPoint.btnTextColorClick(Sender: TObject);
begin
 if ColorDialog1.Execute then clrbxTextColor.Selected:=ColorDialog1.Color;
end;

procedure TfrmMarkEditPoint.btnShadowColorClick(Sender: TObject);
begin
 if ColorDialog1.Execute then clrbxShadowColor.Selected:=ColorDialog1.Color;
end;

constructor TfrmMarkEditPoint.Create(AOwner: TComponent);
begin
  inherited;
  frMarkDescription := TfrMarkDescription.Create(nil);
  frLonLatPoint := TfrLonLat.Create(nil);
end;

destructor TfrmMarkEditPoint.Destroy;
begin
  FreeAndNil(frMarkDescription);
  FreeAndNil(frLonLatPoint);
  inherited;
end;

procedure TfrmMarkEditPoint.DrawFromMarkIcons(canvas:TCanvas; APic: IMarkPicture; bound:TRect);
var
  Bitmap: TCustomBitmap32;
  Bitmap2: TBitmap32;
  wdth:integer;
begin
  canvas.FillRect(bound);
  if APic <> nil then begin
    wdth:=min(bound.Right-bound.Left,bound.Bottom-bound.Top);
    Bitmap:=TCustomBitmap32.Create;
    try
      APic.LoadBitmap(Bitmap);
      Bitmap.DrawMode:=dmBlend;
      Bitmap.Resampler:=TKernelResampler.Create;
      TKernelResampler(Bitmap.Resampler).Kernel:=TLinearKernel.Create;

      Bitmap2:=TBitmap32.Create;
      try
        Bitmap2.SetSize(wdth,wdth);
        Bitmap2.Clear(clWhite32);
        Bitmap2.Draw(Bounds(0, 0, wdth,wdth), Bounds(0, 0, Bitmap.Width,Bitmap.Height),Bitmap);
        Bitmap2.DrawTo(canvas.Handle, bound, Bounds(0, 0, Bitmap2.Width,Bitmap2.Height));
      finally
        Bitmap2.Free;
      end;
    finally
      Bitmap.Free;
    end;
  end;
end;

procedure TfrmMarkEditPoint.drwgrdIconsDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  i:Integer;
  VPictureList: IMarkPictureList;
begin
  i:=(Arow*drwgrdIcons.ColCount)+ACol;
  VPictureList := FMarkDBGUI.MarkPictureList;
  if i < VPictureList.Count then
    DrawFromMarkIcons(drwgrdIcons.Canvas, VPictureList.Get(i), drwgrdIcons.CellRect(ACol,ARow));
end;

procedure TfrmMarkEditPoint.imgIconMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 drwgrdIcons.Visible:=not(drwgrdIcons.Visible);
 if drwgrdIcons.Visible then drwgrdIcons.SetFocus;
end;

procedure TfrmMarkEditPoint.RefreshTranslation;
begin
  inherited;
  frLonLatPoint.RefreshTranslation;
  frMarkDescription.RefreshTranslation;
end;

procedure TfrmMarkEditPoint.drwgrdIconsMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i:integer;
  ACol,ARow: Integer;
  VPictureList: IMarkPictureList;
begin
 drwgrdIcons.MouseToCell(X,Y,ACol,ARow);
 i:=(ARow*drwgrdIcons.ColCount)+ACol;
 VPictureList := FMarkDBGUI.MarkPictureList;
 if (ARow>-1)and(ACol>-1) and (i < VPictureList.Count) then begin
   FPic := VPictureList.Get(i);
   FPicName := VPictureList.GetName(i);
   imgIcon.Canvas.FillRect(imgIcon.Canvas.ClipRect);
   DrawFromMarkIcons(imgIcon.Canvas, FPic, bounds(5,5,36,36));
   drwgrdIcons.Visible:=false;
 end;
end;

end.
