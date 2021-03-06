{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2017, SAS.Planet development team.                      *}
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
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit u_WindowLayerSunCalcDetailsPanel;

interface

uses
  Types,
  Controls,
  Classes,
  GR32,
  GR32_Image,
  GR32_Layers,
  t_SunCalcConfig,
  t_GeoTypes,
  i_PopUp,
  i_SunCalcConfig,
  i_SunCalcProvider,
  i_NotifierOperation,
  i_LocalCoordConverterChangeable,
  i_InternalPerformanceCounter,
  u_GeoFunc,
  u_WindowLayerWithBitmapBase;

type
  TRenderedTextRec = record
    Text: string;
    Bitmap: TBitmap32;
  end;
  PRenderedTextRec = ^TRenderedTextRec;

  TTextAlign = (
    taLeft,
    taCenter,
    taRight
  );

  TWindowLayerSunCalcDetailsPanel = class(TWindowLayerWithBitmapBase)
  private
    FFont: TSunCalcFontInfo;
    FColors: TSunCalcDetailsPanelColors;

    FMargins: TRect;
    FBorder: TRect;

    FHeight: Integer;
    FWidth: Integer;

    FLocation: TDoublePoint;
    FDateTime: TDateTime;
    FTzOffset: Extended;

    FPopUpMenu: IPopUp;
    FSunCalcConfig: ISunCalcConfig;
    FSunCalcProvider: ISunCalcProvider;
    FLocalCoordConverter: ILocalCoordConverterChangeable;

    FRowHeight: Integer;
    FRowsCount: Integer;

    FColWidth: TSunCalcDetailsPanelColsWidth;

    FRenderedText: array of TRenderedTextRec;

    FIsDetailedView: Boolean;

    procedure ClearRenderedText;

    procedure RenderText(
      const ACol, ARow: Integer;
      const AText: string;
      const AAlign: TTextAlign = taLeft
    );

    procedure OnMouseDown(
      Sender: TObject;
      Button: TMouseButton;
      Shift: TShiftState;
      X, Y: Integer
    );
    procedure DrawRow(
      const ARowNum: Integer;
      const ATime: TDateTime;
      const AName: string
    );
    procedure OnPosChange;
    procedure OnSunCalcConfigChange;
    procedure OnSunCalcProviderChange;
  protected
    function GetNewBitmapSize: TPoint; override;
    function GetNewLayerLocation: TFloatRect; override;
    procedure DoUpdateBitmapDraw; override;
    procedure DoUpdateLayerVisibility; override;
    procedure StartThreads; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const ALocalCoordConverter: ILocalCoordConverterChangeable;
      const ASunCalcConfig: ISunCalcConfig;
      const ASunCalcProvider: ISunCalcProvider;
      const ASunCalcPopUpMenu: IPopUp
    );
    destructor Destroy; override;
  end;

implementation

uses
  Math,
  SysUtils,
  DateUtils,
  SunCalc,
  i_LocalCoordConverter,
  u_ListenerByEvent,
  u_TimeZoneInfo;

resourcestring
  rsTime = 'Time';
  rsAz = 'Az.';
  rsAlt = 'Alt.';
  rsEvent = 'Event';

  rsAstroStart = 'Astro. twilight start';
  rsNauticalSatrt = 'Nautical twilight start';
  rsCivilStart = 'Civil twilight start';
  rsRise = 'Rise';
  rsGoldenHrEnd = 'Golden hour end';
  rsNoon = 'Noon';
  rsGoldenHrStart = 'Golden hour start';
  rsSet = 'Set';
  rsCivilEnd = 'Civil twilight end';
  rsNauticalEnd = 'Nautical twilight end';
  rsAstroEnd = 'Astro. twilight end';
  rsMidnight = 'Midnight';

const
  cDetailedRowsCount = 12 + 1;
  cDetailedColsCount = 4;

{ TWindowLayerSunCalcDetailsPanel }

constructor TWindowLayerSunCalcDetailsPanel.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier:INotifierOneOperation;
  const AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const ALocalCoordConverter: ILocalCoordConverterChangeable;
  const ASunCalcConfig: ISunCalcConfig;
  const ASunCalcProvider: ISunCalcProvider;
  const ASunCalcPopUpMenu: IPopUp
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier,
    TBitmapLayer.Create(AParentMap.Layers)
  );

  FPopUpMenu := ASunCalcPopUpMenu;
  FSunCalcConfig := ASunCalcConfig;
  FSunCalcProvider := ASunCalcProvider;
  FLocalCoordConverter := ALocalCoordConverter;

  Layer.OnMouseDown := OnMouseDown;

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnSunCalcProviderChange),
    FSunCalcProvider.ChangeNotifier
  );

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnSunCalcConfigChange),
    FSunCalcConfig.ChangeNotifier
  );

  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnPosChange),
    FLocalCoordConverter.ChangeNotifier
  );

  FFont.FontName := '';
  FFont.FontSize := 0;
  FFont.TextColor := 0;
  FFont.BgColor := 0;

  FMargins := Rect(0, FSunCalcConfig.DetailsPanelRowHight, 0, 0);
  FBorder := Rect(10, 5, 0, 0);

  FDateTime := 0;
  FLocation := CEmptyDoublePoint;
  FTzOffset := NaN;

  FIsDetailedView := False;

  SetLength(FRenderedText, cDetailedColsCount * cDetailedRowsCount);
  ClearRenderedText;
end;

destructor TWindowLayerSunCalcDetailsPanel.Destroy;
begin
  ClearRenderedText;
  inherited Destroy;
end;

procedure TWindowLayerSunCalcDetailsPanel.ClearRenderedText;
var
  I: Integer;
begin
  for I := Low(FRenderedText) to High(FRenderedText) do begin
    FRenderedText[I].Text := '';
    FreeAndNil(FRenderedText[I].Bitmap);
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.OnMouseDown(
  Sender: TObject;
  Button: TMouseButton;
  Shift: TShiftState;
  X, Y: Integer
);
begin
  if Button = mbRight then begin
    FPopUpMenu.PopUp;
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.RenderText(
  const ACol, ARow: Integer;
  const AText: string;
  const AAlign: TTextAlign
);
var
  I: Integer;
  X, X2, Y: Integer;
  VTextRec: PRenderedTextRec;
  VTextSize: TSize;
begin
  VTextRec := @FRenderedText[ARow * cDetailedColsCount + ACol];

  if not Assigned(VTextRec.Bitmap) then begin
    VTextRec.Bitmap := TBitmap32.Create;
  end;

  if VTextRec.Text <> AText then begin
    VTextRec.Text := AText;

    if FFont.FontName <> '' then begin
      VTextRec.Bitmap.Font.Name := FFont.FontName;
    end;

    if FFont.FontSize > 0 then begin
      VTextRec.Bitmap.Font.Size := FFont.FontSize;
    end;

    VTextSize := VTextRec.Bitmap.TextExtent(VTextRec.Text);
    VTextRec.Bitmap.SetSize(VTextSize.cx, VTextSize.cy);

    VTextRec.Bitmap.Clear(FColors.BgColor);

    VTextRec.Bitmap.RenderText(0, 0, VTextRec.Text, 0, FFont.TextColor);
    VTextRec.Bitmap.DrawMode := dmBlend;
  end;

  X := FBorder.Left;

  if ACol > 0 then begin
    for I := 0 to ACol - 1 do begin
      Inc(X, FColWidth[ACol - 1]);
    end;
  end;

  X2 := X + FColWidth[ACol] - 20;
  case AAlign of
    taRight: begin
      X := X2 - VTextRec.Bitmap.Width;
    end;
    taCenter: begin
      X := X + (X2 - X - VTextRec.Bitmap.Width) div 2;
    end;
  end;

  Y := FBorder.Top + ARow * FRowHeight;

  VTextRec.Bitmap.DrawTo(Layer.Bitmap, X, Y);
end;

procedure TWindowLayerSunCalcDetailsPanel.DrawRow(
  const ARowNum: Integer;
  const ATime: TDateTime;
  const AName: string
);
var
  I: Integer;
  VSunPos: TSunPos;
  VTime: string;
  VAzimuth: string;
  VAltitude: string;
  VLocalTime: TDateTime;
begin
  if ATime <> 0 then begin
    if FIsDetailedView then begin
      VSunPos := SunCalc.GetPosition(ATime, FLocation.Y, FLocation.X);
      VAzimuth := Format('%.0f�', [RadToDeg(VSunPos.Azimuth + Pi)]);
      VAltitude := Format('%.1f�', [RadToDeg(VSunPos.Altitude)]);
    end;
    VLocalTime := TTimeZoneInfo.UTCToTzLocalTime(ATime, FTzOffset);
    VTime := FormatDateTime('hh:mm', VLocalTime);
  end else begin
    VTime := '';
    VAzimuth := '';
    VAltitude := '';
  end;

  I := 0;

  RenderText(I, ARowNum, VTime, taCenter);
  Inc(I);

  if FIsDetailedView then begin
    RenderText(I, ARowNum, VAzimuth, taRight);
    Inc(I);

    RenderText(I, ARowNum, VAltitude, taRight);
    Inc(I);
  end;

  RenderText(I, ARowNum, AName);
end;

procedure TWindowLayerSunCalcDetailsPanel.DoUpdateBitmapDraw;
var
  I: Integer;
  VDay: TDateTime;
  VSunTimes: TSunCalcTimes;
begin
  inherited;

  Layer.Bitmap.BeginUpdate;
  try
    Layer.Bitmap.Clear(FColors.BgColor);

    Layer.Bitmap.Font.Name := FFont.FontName;
    Layer.Bitmap.Font.Size := FFont.FontSize;

    for I := 0 to FRowsCount - 1 do begin
      Layer.Bitmap.HorzLineS(0, FRowHeight * (I + 1), FWidth - 1, FColors.GridLinesColor);
    end;

    I := 0;

    if FIsDetailedView then begin
      RenderText(0, I, rsTime, taCenter);
      RenderText(1, I, rsAz, taCenter);
      RenderText(2, I, rsAlt, taCenter);
      RenderText(3, I, rsEvent, taCenter);
      Inc(I);
    end;

    VDay := StartOfTheDay(TTimeZoneInfo.UTCToTzLocalTime(FDateTime, FTzOffset));
    VSunTimes := SunCalc.GetTimes(VDay, FLocation.Y, FLocation.X);

    if FIsDetailedView then begin
      DrawRow(I, VSunTimes[nightEnd].Value, rsAstroStart);
      Inc(I);

      DrawRow(I, VSunTimes[nauticalDawn].Value, rsNauticalSatrt);
      Inc(I);
    end;

    DrawRow(I, VSunTimes[Dawn].Value, rsCivilStart);
    Inc(I);

    DrawRow(I, VSunTimes[sunrise].Value, rsRise);
    Inc(I);

    if FIsDetailedView then begin
      DrawRow(I, VSunTimes[goldenHourEnd].Value, rsGoldenHrEnd);
      Inc(I);
    end;

    DrawRow(I, VSunTimes[solarNoon].Value, rsNoon);
    Inc(I);

    if FIsDetailedView then begin
      DrawRow(I, VSunTimes[goldenHour].Value, rsGoldenHrStart);
      Inc(I);
    end;

    DrawRow(I, VSunTimes[sunset].Value, rsSet);
    Inc(I);

    DrawRow(I, VSunTimes[Dusk].Value, rsCivilEnd);
    Inc(I);

    if FIsDetailedView then begin
      DrawRow(I, VSunTimes[nauticalDusk].Value, rsNauticalEnd);
      Inc(I);

      DrawRow(I, VSunTimes[night].Value, rsAstroEnd);
      Inc(I);

      DrawRow(I, VSunTimes[nadir].Value, rsMidnight);
    end;
  finally
    Layer.Bitmap.EndUpdate;
    Layer.Bitmap.Changed;
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.DoUpdateLayerVisibility;
begin
  inherited;
  Layer.MouseEvents := Visible;
end;

function TWindowLayerSunCalcDetailsPanel.GetNewBitmapSize: TPoint;
begin
  Result.X := FWidth;
  Result.Y := FHeight;
end;

function TWindowLayerSunCalcDetailsPanel.GetNewLayerLocation: TFloatRect;
begin
  Result.Left := FLocalCoordConverter.GetStatic.GetLocalRectSize.X - FWidth;
  Result.Top := FSunCalcConfig.YearTimeLineHight + FSunCalcConfig.DayTimeLineHight + FMargins.Top;
  Result.Right := Result.Left + Layer.Bitmap.Width;
  Result.Bottom := Result.Top + Layer.Bitmap.Height;
end;

procedure TWindowLayerSunCalcDetailsPanel.OnSunCalcConfigChange;
var
  I: Integer;
  VColorSchema: ISunCalcColorSchema;
  VColorSchemaStatic: ISunCalcColorSchemaStatic;
begin
  ViewUpdateLock;
  try
    FSunCalcConfig.LockRead;
    try
      Visible := FSunCalcConfig.Visible;
      
      FIsDetailedView := FSunCalcConfig.IsDetailedView;

      FColWidth := FSunCalcConfig.DetailsPanelColsWidth;
      if not FIsDetailedView then begin
        FColWidth[1] := 0; // Az.
        FColWidth[2] := 0; // Alt.
      end;

      FWidth := 0;
      for I := 0 to Length(FColWidth) - 1 do begin
        Inc(FWidth, FColWidth[I]);
      end;

      if FIsDetailedView then begin
        FRowsCount := cDetailedRowsCount;
      end else begin
        FRowsCount := 5;
      end;
      FRowHeight := FSunCalcConfig.DetailsPanelRowHight;
      FHeight := FRowHeight * FRowsCount;

      VColorSchema := FSunCalcConfig.ColorSchemaList.GetActiveColorSchema;
      VColorSchemaStatic := VColorSchema.GetStatic;

      FFont := VColorSchemaStatic.DetailsPanelFont;
      FColors := VColorSchemaStatic.DetailsPanelColors;
    finally
      FSunCalcConfig.UnlockRead;
    end;

    ClearRenderedText;

    SetNeedUpdateBitmapSize;
    SetNeedUpdateLayerLocation;
    SetNeedUpdateBitmapDraw;
    SetNeedUpdateLayerVisibility;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.OnSunCalcProviderChange;
var
  VLocation: TDoublePoint;
  VDateTime: TDateTime;
  VTzOffset: Extended;
  VIsSameLocation: Boolean;
  VIsSameDate: Boolean;
  VIsSameTzOffset: Boolean;
begin
  ViewUpdateLock;
  try
    FSunCalcProvider.LockRead;
    try
      VLocation := FSunCalcProvider.Location;
      VDateTime := FSunCalcProvider.UTCDateTime;
    finally
      FSunCalcProvider.UnlockRead;
    end;

    if (VDateTime = 0) or PointIsEmpty(VLocation) then begin
      Exit;
    end;

    VIsSameLocation := DoublePointsEqual(VLocation, FLocation);
    VIsSameDate := SameDate(VDateTime, FDateTime);

    if IsNan(FTzOffset) or not VIsSameLocation or not VIsSameDate then begin
      if not FSunCalcProvider.GetTzOffset(VDateTime, VTzOffset) then begin
        VTzOffset := TTimeZoneInfo.GetSystemTzOffset(VDateTime);
      end;
      if IsNan(FTzOffset) then begin
        VIsSameTzOffset := False;
      end else begin
        VIsSameTzOffset := SameValue(VTzOffset, FTzOffset);
      end;
    end else begin
      VTzOffset := FTzOffset;
      VIsSameTzOffset := True;
    end;

    if not VIsSameLocation or not VIsSameDate or not VIsSameTzOffset then begin
      SetNeedUpdateBitmapDraw;
    end;

    FDateTime := VDateTime;
    FLocation := VLocation;
    FTzOffset := VTzOffset;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.OnPosChange;
begin
  ViewUpdateLock;
  try
    SetNeedUpdateBitmapSize;
    SetNeedUpdateLayerLocation;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TWindowLayerSunCalcDetailsPanel.StartThreads;
begin
  inherited;
  OnSunCalcConfigChange;
  OnSunCalcProviderChange;
end;

end.
