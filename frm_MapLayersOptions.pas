{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit frm_MapLayersOptions;

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
  ComCtrls,
  StdCtrls,
  ExtCtrls,
  Spin,
  Buttons,
  i_LanguageManager,
  i_ScaleLineConfig,
  i_StatBarConfig,
  u_CommonFormAndFrameParents;

type
  TfrmMapLayersOptions = class(TFormWitghLanguageManager)
    pgcOptions: TPageControl;
    tsStatBar: TTabSheet;
    tsScaleLine: TTabSheet;
    chkScaleLineHide: TCheckBox;
    chkShowVertScaleLine: TCheckBox;
    rgScaleLineNumbFormat: TRadioGroup;
    seScaleLineWidth: TSpinEdit;
    clrbxScaleLineColor: TColorBox;
    lblScalelineColor: TLabel;
    lblScaleLineWidth: TLabel;
    seScaleLineFontSize: TSpinEdit;
    lblScaleLineOutlineColor: TLabel;
    clrbxScaleLineOutlineColor: TColorBox;
    btnScaleLineFont: TSpeedButton;
    btnCancel: TButton;
    btnApply: TButton;
    lblScaleLineColorOpacity: TLabel;
    seScaleLineColorOpacity: TSpinEdit;
    seScaleLineOutlineOpacity: TSpinEdit;
    lblScalelineOutlineOpacity: TLabel;
    dlgFont: TFontDialog;
    grpScaleLineFont: TGroupBox;
    edtScaleLineFont: TEdit;
    btnOk: TButton;
    chkStatBarHide: TCheckBox;
    lblStatBarTextColor: TLabel;
    lblStatBarTextOpacity: TLabel;
    clrbxStatBarTextColor: TColorBox;
    seStatBarTextOpacity: TSpinEdit;
    lblStatBarBackgroundColor: TLabel;
    lblStatBarBackgroundOpacity: TLabel;
    clrbxStatBarBackgroundColor: TColorBox;
    seStatBarBackgroundOpacity: TSpinEdit;
    grpStatBarFont: TGroupBox;
    btnStatBarFont: TSpeedButton;
    seStatBarFontSize: TSpinEdit;
    edtStatBarFontName: TEdit;
    lblStatBarHeight: TLabel;
    seStatBarHeight: TSpinEdit;
    seStatBarRedrawTime: TSpinEdit;
    lblStatBarRedrawTime: TLabel;
    chkStatBarZoomInfo: TCheckBox;
    chkStatBarLonLatInfo: TCheckBox;
    chkStatBarMetrPerPixInfo: TCheckBox;
    chkStatBarTimeZoneInfo: TCheckBox;
    chkStatBarDownloadInfo: TCheckBox;
    chkStatBarQueueInfo: TCheckBox;
    chkStatBarTilePathInfo: TCheckBox;
    procedure FormShow(Sender: TObject);
    procedure btnScaleLineFontClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure btnStatBarFontClick(Sender: TObject);
  private
    FLanguageManager: ILanguageManager;
    FScaleLineConfig: IScaleLineConfig;
    FStatBarConfig: IStatBarConfig;
  public
    constructor Create(
      const ALanguageManager: ILanguageManager;
      const AScaleLineConfig: IScaleLineConfig;
      const AStatBarConfig: IStatBarConfig
    ); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  GR32,
  u_ResStrings,
  u_TimeZoneInfo;

{ TfrmMapLayersOptions }

{$R *.dfm}

constructor TfrmMapLayersOptions.Create(
  const ALanguageManager: ILanguageManager;
  const AScaleLineConfig: IScaleLineConfig;
  const AStatBarConfig: IStatBarConfig
);
begin
  inherited Create(ALanguageManager);
  FLanguageManager := ALanguageManager;
  FScaleLineConfig := AScaleLineConfig;
  FStatBarConfig := AStatBarConfig;
end;

destructor TfrmMapLayersOptions.Destroy;
begin
  inherited Destroy;
end;

procedure TfrmMapLayersOptions.FormShow(Sender: TObject);
begin
  // Status Bar
  chkStatBarHide.Checked := not FStatBarConfig.Visible;
  chkStatBarZoomInfo.Checked := FStatBarConfig.ViewZoomInfo;
  chkStatBarLonLatInfo.Checked := FStatBarConfig.ViewLonLatInfo;
  chkStatBarMetrPerPixInfo.Checked := FStatBarConfig.ViewMetrPerPixInfo;

  chkStatBarTimeZoneInfo.Checked :=
    FStatBarConfig.ViewTimeZoneTimeInfo and
    FStatBarConfig.TimeZoneInfoAvailable;
  chkStatBarTimeZoneInfo.Enabled := FStatBarConfig.TimeZoneInfoAvailable;
  if not FStatBarConfig.TimeZoneInfoAvailable then begin
    if not (Pos(cTimeZoneDllName, chkStatBarTimeZoneInfo.Caption) > 0) then begin
      chkStatBarTimeZoneInfo.Caption := chkStatBarTimeZoneInfo.Caption + ' ' +
        Format(SAS_ERR_TimeZoneInfoDisabled, [cTimeZoneDllName]);
    end;
  end;

  chkStatBarDownloadInfo.Checked := FStatBarConfig.ViewDownloadedInfo;
  chkStatBarQueueInfo.Checked := FStatBarConfig.ViewHttpQueueInfo;
  chkStatBarTilePathInfo.Checked := FStatBarConfig.ViewTilePathInfo;
  seStatBarHeight.Value := FStatBarConfig.Height;
  seStatBarRedrawTime.Value := FStatBarConfig.MinUpdateTickCount;
  edtStatBarFontName.Text := FStatBarConfig.FontName;
  seStatBarFontSize.Value := FStatBarConfig.FontSize;
  clrbxStatBarTextColor.Selected := WinColor(FStatBarConfig.TextColor);
  seStatBarTextOpacity.Value := AlphaComponent(FStatBarConfig.TextColor);
  clrbxStatBarBackgroundColor.Selected := WinColor(FStatBarConfig.BgColor);
  seStatBarBackgroundOpacity.Value := AlphaComponent(FStatBarConfig.BgColor);
  // Scale Line
  chkScaleLineHide.Checked := not FScaleLineConfig.Visible;
  chkShowVertScaleLine.Checked := FScaleLineConfig.Extended;
  rgScaleLineNumbFormat.ItemIndex := Integer(FScaleLineConfig.NumbersFormat);
  seScaleLineWidth.Value := FScaleLineConfig.Width;
  edtScaleLineFont.Text := FScaleLineConfig.FontName;
  seScaleLineFontSize.Value := FScaleLineConfig.FontSize;
  clrbxScaleLineColor.Selected := WinColor(FScaleLineConfig.Color);
  seScaleLineColorOpacity.Value := AlphaComponent(FScaleLineConfig.Color);
  clrbxScaleLineOutlineColor.Selected := WinColor(FScaleLineConfig.OutLineColor);
  seScaleLineOutlineOpacity.Value := AlphaComponent(FScaleLineConfig.OutLineColor);
end;

procedure TfrmMapLayersOptions.btnApplyClick(Sender: TObject);
begin
  // Status Bar
  FStatBarConfig.Visible := not chkStatBarHide.Checked;
  FStatBarConfig.ViewZoomInfo := chkStatBarZoomInfo.Checked;
  FStatBarConfig.ViewLonLatInfo := chkStatBarLonLatInfo.Checked;
  FStatBarConfig.ViewMetrPerPixInfo := chkStatBarMetrPerPixInfo.Checked;
  FStatBarConfig.ViewTimeZoneTimeInfo := chkStatBarTimeZoneInfo.Checked;
  FStatBarConfig.ViewDownloadedInfo := chkStatBarDownloadInfo.Checked;
  FStatBarConfig.ViewHttpQueueInfo := chkStatBarQueueInfo.Checked;
  FStatBarConfig.ViewTilePathInfo := chkStatBarTilePathInfo.Checked;
  FStatBarConfig.Height := seStatBarHeight.Value;
  FStatBarConfig.MinUpdateTickCount := seStatBarRedrawTime.Value;
  FStatBarConfig.FontName := edtStatBarFontName.Text;
  FStatBarConfig.FontSize := seStatBarFontSize.Value;
  FStatBarConfig.TextColor := SetAlpha(
    Color32(clrbxStatBarTextColor.Selected),
    seStatBarTextOpacity.Value
  );
  FStatBarConfig.BgColor := SetAlpha(
    Color32(clrbxStatBarBackgroundColor.Selected),
    seStatBarBackgroundOpacity.Value
  );
  // Scale Line
  FScaleLineConfig.Visible := not chkScaleLineHide.Checked;
  FScaleLineConfig.Extended := chkShowVertScaleLine.Checked;
  FScaleLineConfig.NumbersFormat := TScaleLegendNumbersFormat(rgScaleLineNumbFormat.ItemIndex);
  FScaleLineConfig.Width := seScaleLineWidth.Value;
  FScaleLineConfig.FontName := edtScaleLineFont.Text;
  FScaleLineConfig.FontSize := seScaleLineFontSize.Value;
  FScaleLineConfig.Color := SetAlpha(
    Color32(clrbxScaleLineColor.Selected),
    seScaleLineColorOpacity.Value
  );
  FScaleLineConfig.OutLineColor := SetAlpha(
    Color32(clrbxScaleLineOutlineColor.Selected),
    seScaleLineOutlineOpacity.Value
  );
end;

procedure TfrmMapLayersOptions.btnOkClick(Sender: TObject);
begin
  btnApplyClick(Sender);
  Close;
end;

procedure TfrmMapLayersOptions.btnScaleLineFontClick(Sender: TObject);
begin
  if dlgFont.Execute then begin
    edtScaleLineFont.Text := dlgFont.Font.Name;
    seScaleLineFontSize.Value := dlgFont.Font.Size;
  end;
end;

procedure TfrmMapLayersOptions.btnStatBarFontClick(Sender: TObject);
begin
  if dlgFont.Execute then begin
    edtStatBarFontName.Text := dlgFont.Font.Name;
    seStatBarFontSize.Value := dlgFont.Font.Size;
  end;
end;

end.
