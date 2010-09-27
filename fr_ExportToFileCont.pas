unit fr_ExportToFileCont;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  CheckLst,
  ExtCtrls,
  u_CommonFormAndFrameParents;

type
  TfrExportToFileCont = class(TFrame)
    pnlCenter: TPanel;
    pnlRight: TPanel;
    lblZooms: TLabel;
    chkAllZooms: TCheckBox;
    chklstZooms: TCheckListBox;
    pnlMain: TPanel;
    lblMap: TLabel;
    cbbMap: TComboBox;
    pnlTop: TPanel;
    lblTargetFile: TLabel;
    edtTargetFile: TEdit;
    btnSelectTargetFile: TButton;
    dlgSaveTargetFile: TSaveDialog;
    cbbNamesType: TComboBox;
    lblNamesType: TLabel;
    procedure btnSelectTargetFileClick(Sender: TObject);
    procedure chkAllZoomsClick(Sender: TObject);
  private
  public
    constructor CreateForFileType(AOwner: TComponent; AFileFilters: string; AFileExtDefault: string);
    procedure Init;
    procedure RefreshTranslation; override;
  end;

implementation

uses
  u_GlobalState,
  UMapType;

{$R *.dfm}

procedure TfrExportToFileCont.btnSelectTargetFileClick(Sender: TObject);
begin
  if dlgSaveTargetFile.Execute then begin
    edtTargetFile.Text := dlgSaveTargetFile.FileName;
  end;
end;

procedure TfrExportToFileCont.chkAllZoomsClick(Sender: TObject);
var
  i: byte;
begin
  for i:=0 to chklstZooms.Count-1 do begin
    chklstZooms.Checked[i] := TCheckBox(sender).Checked;
  end;
end;

constructor TfrExportToFileCont.CreateForFileType(AOwner: TComponent; AFileFilters,
  AFileExtDefault: string);
begin
  inherited Create(AOwner);
  dlgSaveTargetFile.Filter := AFileFilters;
  dlgSaveTargetFile.DefaultExt := AFileExtDefault;
  cbbNamesType.ItemIndex := 1;
end;

procedure TfrExportToFileCont.Init;
var
  i: integer;
  VMapType: TMapType;
  VActiveMap: TMapType;
  VAddedIndex: Integer;
begin
  chklstZooms.Items.Clear;
  for i:=1 to 24 do begin
    chklstZooms.Items.Add(inttostr(i));
  end;

  VActiveMap := GState.ViewState.GetCurrentMap;
  cbbMap.items.Clear;
  For i:=0 to length(GState.MapType)-1 do begin
    VMapType := GState.MapType[i];
    VAddedIndex := cbbMap.Items.AddObject(VMapType.name,VMapType);
    if VMapType = VActiveMap then begin
      cbbMap.ItemIndex:=VAddedIndex;
    end;
  end;
  if (cbbMap.Items.Count > 0) and (cbbMap.ItemIndex < 0) then begin
    cbbMap.ItemIndex := 0;
  end;
end;

procedure TfrExportToFileCont.RefreshTranslation;
var
  i: Integer;
begin
  i := cbbNamesType.ItemIndex;
  inherited;
  cbbNamesType.ItemIndex := i;
end;

end.
