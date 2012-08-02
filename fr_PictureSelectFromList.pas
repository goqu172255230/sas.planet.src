unit fr_PictureSelectFromList;

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
  Grids,
  i_MarkPicture,
  i_LanguageManager,
  u_CommonFormAndFrameParents, StdCtrls;

type
  TfrPictureSelectFromList = class(TFrame)
    drwgrdIcons: TDrawGrid;
    procedure drwgrdIconsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect:
        TRect; State: TGridDrawState);
    procedure drwgrdIconsKeyDown(Sender: TObject; var Key: Word; Shift:
        TShiftState);
    procedure drwgrdIconsMouseMove(Sender: TObject; Shift: TShiftState; X, Y:
        Integer);
    procedure drwgrdIconsMouseUp(Sender: TObject; Button: TMouseButton; Shift:
        TShiftState; X, Y: Integer);
    procedure FrameEnter(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    FPictureList: IMarkPictureList;
    FOnSelect: TNotifyEvent;
    FPicture: IMarkPicture;
    procedure DrawFromMarkIcons(
      canvas: TCanvas;
      const APic: IMarkPicture;
      const bound: TRect
    );
  public
    property Picture: IMarkPicture read FPicture write FPicture;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const APictureList: IMarkPictureList;
      AOnSelect: TNotifyEvent
    ); reintroduce;
  end;

implementation

uses
  Math,
  GR32,
  GR32_Resamplers,
  i_BitmapMarker;

{$R *.dfm}

constructor TfrPictureSelectFromList.Create(
  const ALanguageManager: ILanguageManager;
  const APictureList: IMarkPictureList;
  AOnSelect: TNotifyEvent
);
begin
  inherited Create(ALanguageManager);
  FPictureList := APictureList;
  FOnSelect := AOnSelect;
end;

procedure TfrPictureSelectFromList.DrawFromMarkIcons(canvas: TCanvas;
  const APic: IMarkPicture; const bound: TRect);
var
  VBitmap: TBitmap32;
  wdth:integer;
  VResampler: TCustomResampler;
  VMarker: IBitmapMarker;
begin
  canvas.FillRect(bound);
  if APic <> nil then begin
    VMarker := APic.GetMarker;
    if VMarker <> nil then begin
      wdth:=min(bound.Right-bound.Left,bound.Bottom-bound.Top);
      VBitmap:=TBitmap32.Create;
      try
        VBitmap.SetSize(wdth,wdth);
        VBitmap.Clear(clWhite32);
        VResampler := TKernelResampler.Create;
        try
          TKernelResampler(VResampler).Kernel := TLinearKernel.Create;
          StretchTransfer(
            VBitmap,
            VBitmap.BoundsRect,
            VBitmap.ClipRect,
            VMarker.Bitmap,
            VMarker.Bitmap.BoundsRect,
            VResampler,
            dmBlend,
            cmBlend
          );
        finally
          VResampler.Free;
        end;
        VBitmap.DrawTo(canvas.Handle, bound, VBitmap.BoundsRect);
      finally
        VBitmap.Free;
      end;
    end;
  end;
end;

procedure TfrPictureSelectFromList.drwgrdIconsDrawCell(Sender: TObject; ACol, ARow: Integer;
    Rect: TRect; State: TGridDrawState);
var
  i:Integer;
  VPictureList: IMarkPictureList;
begin
  i:=(Arow*drwgrdIcons.ColCount)+ACol;
  VPictureList := FPictureList;
  if i < VPictureList.Count then
    DrawFromMarkIcons(drwgrdIcons.Canvas, VPictureList.Get(i), drwgrdIcons.CellRect(ACol,ARow));
end;

procedure TfrPictureSelectFromList.drwgrdIconsKeyDown(Sender: TObject; var Key:
    Word; Shift: TShiftState);
var
  i:integer;
begin
  if Key = VK_SPACE then begin
    i:=(drwgrdIcons.Row*drwgrdIcons.ColCount)+drwgrdIcons.Col;
    if (i >= 0) and (i < FPictureList.Count) then begin
      FPicture := FPictureList.Get(i);
      FOnSelect(Self);
    end;
  end;
end;

procedure TfrPictureSelectFromList.drwgrdIconsMouseMove(Sender: TObject; Shift:
    TShiftState; X, Y: Integer);
var
  i:integer;
  ACol,ARow: Integer;
begin
  drwgrdIcons.MouseToCell(X, Y, ACol, ARow);
  i:=(ARow*drwgrdIcons.ColCount)+ACol;
  if (ARow>-1)and(ACol>-1) and (i < FPictureList.Count) then begin
    drwgrdIcons.Hint := FPictureList.Get(i).GetName;
  end;
end;

procedure TfrPictureSelectFromList.drwgrdIconsMouseUp(Sender: TObject; Button:
    TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i:integer;
  ACol,ARow: Integer;
begin
  drwgrdIcons.MouseToCell(X, Y, ACol, ARow);
  i:=(ARow*drwgrdIcons.ColCount)+ACol;
  if (ARow>-1)and(ACol>-1) and (i < FPictureList.Count) then begin
    FPicture := FPictureList.Get(i);
    FOnSelect(Self);
  end;
end;

procedure TfrPictureSelectFromList.FrameEnter(Sender: TObject);
begin
  drwgrdIcons.SetFocus;
end;

procedure TfrPictureSelectFromList.FrameResize(Sender: TObject);
var
  VPicCount: Integer;
  VColCount: Integer;
  VRowCount: Integer;
begin
  VPicCount := FPictureList.Count;
  VColCount := Trunc(drwgrdIcons.ClientWidth / drwgrdIcons.DefaultColWidth);
  drwgrdIcons.ColCount := VColCount;
  VRowCount := VPicCount div VColCount;
  if (VPicCount mod VColCount) > 0 then begin
    Inc(VRowCount);
  end;
  drwgrdIcons.RowCount := VRowCount;
  drwgrdIcons.Repaint;
end;

end.
