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

unit u_SensorViewTextTBXPanel;

interface

uses
  Windows,
  Classes,
  ImgList,
  GR32_Image,
  TB2Item,
  TB2Dock,
  TBX,
  TBXControls,
  i_JclNotify,
  i_JclListenerNotifierLinksList,
  i_Bitmap32Static,
  i_ValueToStringConverter,
  i_SensorList,
  i_Sensor;

type
  TSensorViewTBXPanelBase = class(TInterfacedObject, ISensorView)
  private
    FListEntity: ISensorListEntity;
    FSensor: ISensor;
    FConfig: ISensorViewConfig;
    FOwner: TComponent;
    FDefaultDoc: TTBDock;
    FParentMenu: TTBCustomItem;
    FImages: TCustomImageList;
    FImageIndexReset: TImageIndex;
    FLinksList: IJclListenerNotifierLinksList;

    FBar: TTBXToolWindow;
    FpnlTop: TTBXAlignmentPanel;
    FlblCaption: TTBXLabel;
    FbtnReset: TTBXButton;

    FResetItem: TTBXItem;
    FVisibleItem: TTBXCustomItem;
    FVisibleItemWithReset: TTBXSubmenuItem;

    FValueChangeId: Integer;
    FValueShowId: Integer;

    function GuidToComponentName(
      const APrefix: string;
      const AGUID: TGUID
    ): string;
    procedure CreateMenu;
    procedure UpdateControls;

    procedure OnBarVisibleChanged(Sender: TObject);
    procedure OnVisibleItemClick(Sender: TObject);
    procedure OnResetClick(Sender: TObject);
    procedure OnTimer;
    procedure OnConfigChange;
    procedure OnSensorChange;
    procedure OnSensorDataUpdate;
  protected
    procedure CreatePanel; virtual;
    procedure UpdateDataView; virtual; abstract;
  protected
    function GetConfig: ISensorViewConfig;
    function GetSensor: ISensor;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
    destructor Destroy; override;
  end;

  TSensorViewTextTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FSensor: ISensorText;
    FlblValue: TTBXLabel;
    FLastText: string;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewSpeedTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FValueConverterConfig: IValueToStringConverterConfig;
    FSensor: ISensorSpeed;
    FlblValue: TTBXLabel;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      const AValueConverterConfig: IValueToStringConverterConfig;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewLengthTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FValueConverterConfig: IValueToStringConverterConfig;
    FSensor: ISensorLength;
    FlblValue: TTBXLabel;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      const AValueConverterConfig: IValueToStringConverterConfig;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewDegreesTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FValueConverterConfig: IValueToStringConverterConfig;
    FSensor: ISensorDegrees;
    FlblValue: TTBXLabel;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      const AValueConverterConfig: IValueToStringConverterConfig;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewTimeTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FValueConverterConfig: IValueToStringConverterConfig;
    FSensor: ISensorTime;
    FlblValue: TTBXLabel;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      const AValueConverterConfig: IValueToStringConverterConfig;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewPositionTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FValueConverterConfig: IValueToStringConverterConfig;
    FSensor: ISensorPosition;
    FlblValue: TTBXLabel;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      const AValueConverterConfig: IValueToStringConverterConfig;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

  TSensorViewBitmapTBXPanel = class(TSensorViewTBXPanelBase)
  private
    FSensor: ISensorBitmap;
    FImage: TImage32;
    FBitmap: IBitmap32Static;
  protected
    procedure CreatePanel; override;
    procedure UpdateDataView; override;
  public
    constructor Create(
      const AListEntity: ISensorListEntity;
      const AConfig: ISensorViewConfig;
      const ATimerNoifier: IJclNotifier;
      AOwner: TComponent;
      ADefaultDoc: TTBDock;
      AParentMenu: TTBCustomItem;
      AImages: TCustomImageList;
      AImageIndexReset: TImageIndex
    );
  end;

implementation

uses
  Graphics,
  Controls,
  Math,
  SysUtils,
  u_JclListenerNotifierLinksList,
  u_NotifyEventListener,
  u_GeoToStr,
  u_ResStrings;

{ TSensorViewTBXPanelBase }

constructor TSensorViewTBXPanelBase.Create(
  const AListEntity: ISensorListEntity;
  const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  AOwner: TComponent;
  ADefaultDoc: TTBDock;
  AParentMenu: TTBCustomItem;
  AImages: TCustomImageList;
  AImageIndexReset: TImageIndex
);
begin
  inherited Create;
  FListEntity := AListEntity;
  FSensor := FListEntity.GetSensor;
  FConfig := AConfig;
  FOwner := AOwner;
  FValueChangeId := 0;
  FValueShowId := 0;
  Assert(FOwner is TWinControl);
  FDefaultDoc := ADefaultDoc;
  FParentMenu := AParentMenu;
  FImages := AImages;
  FImageIndexReset := AImageIndexReset;

  FLinksList := TJclListenerNotifierLinksList.Create;

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnTimer),
    ATimerNoifier
  );

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnSensorChange),
    FListEntity.GetChangeNotifier
  );

  FLinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnSensorDataUpdate),
    FSensor.GetDataUpdateNotifier
  );

  CreatePanel;
  CreateMenu;
  UpdateControls;

  FLinksList.ActivateLinks;
  OnConfigChange;
  OnSensorDataUpdate;
end;

destructor TSensorViewTBXPanelBase.Destroy;
begin
  FLinksList.DeactivateLinks;
  FLinksList := nil;
  FreeAndNil(FBar);
  FConfig := nil;
  FSensor := nil;
  inherited;
end;

procedure TSensorViewTBXPanelBase.CreateMenu;
begin
  if FSensor.CanReset then begin
    FVisibleItemWithReset := TTBXSubmenuItem.Create(FBar);
    FVisibleItemWithReset.DropdownCombo := True;
    FVisibleItem := FVisibleItemWithReset;

    FResetItem := TTBXItem.Create(FBar);

    FResetItem.Name := GuidToComponentName('SensorReset_', FListEntity.GetGUID);
    FResetItem.OnClick := Self.OnResetClick;
    FResetItem.Hint := '';
    FResetItem.Images := FImages;
    FResetItem.ImageIndex := FImageIndexReset;
    FVisibleItemWithReset.Add(FResetItem);
  end else begin
    FVisibleItem := TTBXItem.Create(FBar);
    FVisibleItemWithReset := nil;
  end;
  FVisibleItem.Name := GuidToComponentName('Sensor_', FListEntity.GetGUID);
  FVisibleItem.AutoCheck := True;
  FVisibleItem.OnClick := Self.OnVisibleItemClick;
  FParentMenu.Add(FVisibleItem);
end;

procedure TSensorViewTBXPanelBase.CreatePanel;
begin
  FBar := TTBXToolWindow.Create(FOwner);
  FpnlTop := TTBXAlignmentPanel.Create(FBar);
  FlblCaption := TTBXLabel.Create(FBar);

  FBar.Name := GuidToComponentName('Sensor_', FListEntity.GetGUID);
  FBar.Align := alTop;
  FBar.ActivateParent := True;
  FBar.DefaultDock := FDefaultDoc;
  FBar.UseLastDock := False;
  FBar.ClientAreaHeight := 32;
  FBar.ClientAreaWidth := 150;
  FBar.DockRow := FDefaultDoc.GetHighestRow(False) + 1;
  FBar.DockPos := 0;
  FBar.Stretch := True;
  FBar.OnVisibleChanged := Self.OnBarVisibleChanged;
  FBar.Visible := True;
  FBar.Parent := FDefaultDoc;
  FBar.CurrentDock := FDefaultDoc;

  FpnlTop.Parent := FBar;
  FpnlTop.Left := 0;
  FpnlTop.Top := 0;
  FpnlTop.Width := 150;
  FpnlTop.Height := 18;
  FpnlTop.Align := alTop;

  if FSensor.CanReset then begin
    FbtnReset := TTBXButton.Create(FBar);
    FbtnReset.Parent := FpnlTop;
    FbtnReset.Left := 133;
    FbtnReset.Top := 0;
    FbtnReset.Width := 18;
    FbtnReset.Height := 18;
    FbtnReset.Align := alRight;
    FbtnReset.TabStop := False;
    FbtnReset.Images := FImages;
    FbtnReset.ImageIndex := FImageIndexReset;
    FbtnReset.ButtonStyle := bsFlat;

    FbtnReset.OnClick := Self.OnResetClick;
  end;

  FlblCaption.Parent := FpnlTop;
  FlblCaption.Left := 0;
  FlblCaption.Top := 0;
  FlblCaption.Width := 133;
  FlblCaption.Height := 18;
  FlblCaption.Align := alClient;
  FlblCaption.Wrapping := twEndEllipsis;
end;

function TSensorViewTBXPanelBase.GetConfig: ISensorViewConfig;
begin
  Result := FConfig;
end;

function TSensorViewTBXPanelBase.GetSensor: ISensor;
begin
  Result := FSensor;
end;

function TSensorViewTBXPanelBase.GuidToComponentName(
  const APrefix: string;
  const AGUID: TGUID
): string;
var
  VGUIDStr: string;
begin
  VGUIDStr := GUIDToString(AGUID);
  VGUIDStr := StringReplace(VGUIDStr, '{', '', [rfReplaceAll]);
  VGUIDStr := StringReplace(VGUIDStr, '}', '', [rfReplaceAll]);
  VGUIDStr := StringReplace(VGUIDStr, '-', '_', [rfReplaceAll]);
  Result := APrefix + VGUIDStr;
end;

procedure TSensorViewTBXPanelBase.OnBarVisibleChanged(Sender: TObject);
begin
  FConfig.Visible := FBar.Visible;
end;

procedure TSensorViewTBXPanelBase.OnConfigChange;
var
  VVisible: Boolean;
begin
  VVisible := FConfig.Visible;
  FBar.Visible := VVisible;
  FVisibleItem.Checked := VVisible;
end;

procedure TSensorViewTBXPanelBase.OnResetClick(Sender: TObject);
begin
  if FSensor.CanReset then begin
    if (MessageBox(TWinControl(FOwner).Handle, pchar(SAS_MSG_youasurerefrsensor), pchar(SAS_MSG_coution), 36) = IDYES) then begin
      FSensor.Reset;
      OnTimer;
    end;
  end;
end;

procedure TSensorViewTBXPanelBase.OnSensorChange;
begin
  UpdateControls;
end;

procedure TSensorViewTBXPanelBase.OnSensorDataUpdate;
begin
  InterlockedIncrement(FValueChangeId);
end;

procedure TSensorViewTBXPanelBase.OnTimer;
begin
  if FConfig.Visible then begin
    if FValueChangeId <> FValueShowId then begin
      UpdateDataView;
      FValueShowId := FValueChangeId;
    end;
  end;
end;

procedure TSensorViewTBXPanelBase.OnVisibleItemClick(Sender: TObject);
begin
  FConfig.Visible := FVisibleItem.Checked;
end;

procedure TSensorViewTBXPanelBase.UpdateControls;
begin
  FVisibleItem.Caption := FListEntity.GetMenuItemName;
  FBar.Caption := FListEntity.GetCaption;
  FBar.Hint := FListEntity.GetDescription;
  FlblCaption.Caption := FListEntity.GetCaption;
  if FResetItem <> nil then begin
    FResetItem.Caption := SAS_STR_SensorReset;
  end;
  if FbtnReset <> nil then begin
    FbtnReset.Hint := SAS_STR_SensorReset;
  end;
end;

{ TSensorViewTextTBXPanel }

constructor TSensorViewTextTBXPanel.Create(
  const AListEntity: ISensorListEntity;
  const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  AOwner: TComponent;
  ADefaultDoc: TTBDock;
  AParentMenu: TTBCustomItem;
  AImages: TCustomImageList;
  AImageIndexReset: TImageIndex
);
begin
  inherited;
  if not Supports(FListEntity.GetSensor, ISensorText, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewTextTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewTextTBXPanel.UpdateDataView;
var
  VText: string;
begin
  VText := FSensor.GetText;
  if FLastText <> VText then begin
    FLastText := VText;
    FlblValue.Caption := FLastText;
  end;
end;

{ TSensorViewBitmapTBXPanel }

constructor TSensorViewBitmapTBXPanel.Create(
  const AListEntity: ISensorListEntity;
  const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  AOwner: TComponent;
  ADefaultDoc: TTBDock;
  AParentMenu: TTBCustomItem;
  AImages: TCustomImageList;
  AImageIndexReset: TImageIndex
);
begin
  inherited;
  if not Supports(FListEntity.GetSensor, ISensorBitmap, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewBitmapTBXPanel.CreatePanel;
begin
  inherited;
  FImage := TImage32.Create(FBar);

  FImage.Parent := FBar;
  FImage.AutoSize := True;
  FImage.Left := 0;
  FImage.Top := 17;
  FImage.Width := 150;
  FImage.Height := 15;
  FImage.Align := alTop;

  FBar.ClientAreaHeight := FImage.Top + FImage.Height + 2;
end;

procedure TSensorViewBitmapTBXPanel.UpdateDataView;
var
  VBitmap: IBitmap32Static;
begin
  VBitmap := FSensor.Bitmap;
  if FBitmap <> VBitmap then begin
    FBitmap := VBitmap;
    FImage.Bitmap.Assign(VBitmap.Bitmap);
  end;
end;

{ TSensorViewSpeedTBXPanel }

constructor TSensorViewSpeedTBXPanel.Create(
  const AListEntity: ISensorListEntity; const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  const AValueConverterConfig: IValueToStringConverterConfig;
  AOwner: TComponent; ADefaultDoc: TTBDock; AParentMenu: TTBCustomItem;
  AImages: TCustomImageList; AImageIndexReset: TImageIndex);
begin
  inherited Create(AListEntity, AConfig, ATimerNoifier, AOwner, ADefaultDoc, AParentMenu, AImages, AImageIndexReset);
  FValueConverterConfig := AValueConverterConfig;
  if not Supports(FListEntity.GetSensor, ISensorSpeed, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewSpeedTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewSpeedTBXPanel.UpdateDataView;
var
  VText: string;
begin
  VText := FValueConverterConfig.GetStatic.SpeedConvert(FSensor.GetValue);
  FlblValue.Caption := VText;
end;

{ TSensorViewLengthTBXPanel }

constructor TSensorViewLengthTBXPanel.Create(
  const AListEntity: ISensorListEntity; const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  const AValueConverterConfig: IValueToStringConverterConfig;
  AOwner: TComponent; ADefaultDoc: TTBDock; AParentMenu: TTBCustomItem;
  AImages: TCustomImageList; AImageIndexReset: TImageIndex);
begin
  inherited Create(AListEntity, AConfig, ATimerNoifier, AOwner, ADefaultDoc, AParentMenu, AImages, AImageIndexReset);
  FValueConverterConfig := AValueConverterConfig;
  if not Supports(FListEntity.GetSensor, ISensorLength, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewLengthTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewLengthTBXPanel.UpdateDataView;
var
  VText: string;
begin
  VText := FValueConverterConfig.GetStatic.DistConvert(FSensor.GetValue);
  FlblValue.Caption := VText;
end;

{ TSensorViewDegreesTBXPanel }

constructor TSensorViewDegreesTBXPanel.Create(
  const AListEntity: ISensorListEntity; const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  const AValueConverterConfig: IValueToStringConverterConfig;
  AOwner: TComponent; ADefaultDoc: TTBDock; AParentMenu: TTBCustomItem;
  AImages: TCustomImageList; AImageIndexReset: TImageIndex);
begin
  inherited Create(AListEntity, AConfig, ATimerNoifier, AOwner, ADefaultDoc, AParentMenu, AImages, AImageIndexReset);
  FValueConverterConfig := AValueConverterConfig;
  if not Supports(FListEntity.GetSensor, ISensorDegrees, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewDegreesTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewDegreesTBXPanel.UpdateDataView;
var
  VText: string;
begin
  VText := RoundEx(FSensor.GetValue, 2) + '�';
  FlblValue.Caption := VText;
end;

{ TSensorViewTimeTBXPanel }

constructor TSensorViewTimeTBXPanel.Create(const AListEntity: ISensorListEntity;
  const AConfig: ISensorViewConfig; const ATimerNoifier: IJclNotifier;
  const AValueConverterConfig: IValueToStringConverterConfig;
  AOwner: TComponent; ADefaultDoc: TTBDock; AParentMenu: TTBCustomItem;
  AImages: TCustomImageList; AImageIndexReset: TImageIndex);
begin
  inherited Create(AListEntity, AConfig, ATimerNoifier, AOwner, ADefaultDoc, AParentMenu, AImages, AImageIndexReset);
  FValueConverterConfig := AValueConverterConfig;
  if not Supports(FListEntity.GetSensor, ISensorTime, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewTimeTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewTimeTBXPanel.UpdateDataView;
var
  VValue: TDateTime;
  VText: string;
begin
  VValue := FSensor.GetValue;
  if IsNan(VValue) or (VValue = 0) then begin
    VText := '';
  end else begin
    VText := FormatDateTime('hh:nn:ss', VValue);
  end;
  FlblValue.Caption := VText;
end;

{ TSensorViewPositionTBXPanel }

constructor TSensorViewPositionTBXPanel.Create(
  const AListEntity: ISensorListEntity; const AConfig: ISensorViewConfig;
  const ATimerNoifier: IJclNotifier;
  const AValueConverterConfig: IValueToStringConverterConfig;
  AOwner: TComponent; ADefaultDoc: TTBDock; AParentMenu: TTBCustomItem;
  AImages: TCustomImageList; AImageIndexReset: TImageIndex);
begin
  inherited Create(AListEntity, AConfig, ATimerNoifier, AOwner, ADefaultDoc, AParentMenu, AImages, AImageIndexReset);
  FValueConverterConfig := AValueConverterConfig;
  if not Supports(FListEntity.GetSensor, ISensorPosition, FSensor) then begin
    raise Exception.Create('���������������� ��� �������');
  end;
end;

procedure TSensorViewPositionTBXPanel.CreatePanel;
begin
  inherited;
  FlblValue := TTBXLabel.Create(FBar);

  FlblValue.Parent := FBar;
  FlblValue.AutoSize := True;
  FlblValue.Left := 0;
  FlblValue.Top := 17;
  FlblValue.Width := 150;
  FlblValue.Height := 15;
  FlblValue.Align := alTop;
  FlblValue.Font.Height := -16;
  FlblValue.Font.Name := 'Arial';
  FlblValue.Font.Style := [fsBold];
  FlblValue.ParentFont := False;
  FlblValue.Wrapping := twEndEllipsis;
  FlblValue.Caption := '';

  FBar.ClientAreaHeight := FlblValue.Top + FlblValue.Height + 2;
end;

procedure TSensorViewPositionTBXPanel.UpdateDataView;
var
  VText: string;
begin
  VText := FValueConverterConfig.GetStatic.LonLatConvert(FSensor.GetValue);
  FlblValue.Caption := VText;
end;

end.
