{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2011, SAS.Planet development team.                      *}
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

unit u_BitmapMarkerProviderSimpleBase;

interface

uses
  Types,
  GR32,
  i_JclNotify,
  i_BitmapMarker,
  i_BitmapMarkerProviderSimpleConfig;

type
  TBitmapMarkerProviderSimpleBase = class(TInterfacedObject, IBitmapMarkerProvider)
  private
    FConfig: IBitmapMarkerProviderSimpleConfigStatic;
    FUseDirection: Boolean;
    FDefaultDirection: Double;
    FMarker: IBitmapMarker;
    function ModifyMarkerWithRotation(ASourceMarker: IBitmapMarker; AAngle: Double): IBitmapMarker;
  protected
    property Config: IBitmapMarkerProviderSimpleConfigStatic read FConfig;
    function CreateMarker(ASize: Integer): IBitmapMarker; virtual; abstract;
  protected
    function GetUseDirection: Boolean;

    function GetMarker: IBitmapMarker;
    function GetMarkerBySize(ASize: Integer): IBitmapMarker;
    function GetMarkerWithRotation(AAngle: Double): IBitmapMarker;
    function GetMarkerWithRotationBySize(AAngle: Double;  ASize: Integer): IBitmapMarker;
  public
    constructor CreateProvider(AConfig: IBitmapMarkerProviderSimpleConfigStatic); virtual; abstract;
    constructor Create(
      AUseDirection: Boolean;
      ADefaultDirection: Double;
      AConfig: IBitmapMarkerProviderSimpleConfigStatic
    );
  end;

  TBitmapMarkerProviderSimpleBaseClass = class of TBitmapMarkerProviderSimpleBase;

  TBitmapMarkerProviderChangeableWithConfig = class(TInterfacedObject, IBitmapMarkerProviderChangeable)
  private
    FConfig: IBitmapMarkerProviderSimpleConfig;
    FProviderClass: TBitmapMarkerProviderSimpleBaseClass;
    FProviderStatic: IBitmapMarkerProvider;

    FConfigChangeListener: IJclListener;
    FChangeNotifier: IJclNotifier;
    procedure OnConfigChange(Sender: TObject);
  protected
    function GetStatic: IBitmapMarkerProvider;
    function GetChangeNotifier: IJclNotifier;
  public
    constructor Create(
      AProviderClass: TBitmapMarkerProviderSimpleBaseClass;
      AConfig: IBitmapMarkerProviderSimpleConfig
    );
    destructor Destroy; override;
  end;


implementation

uses
  GR32_Blend,
  GR32_Rasterizers,
  GR32_Resamplers,
  GR32_Transforms,
  u_JclNotify,
  u_NotifyEventListener,
  u_GeoFun,
  u_BitmapMarker;

const
  CAngleDelta = 1.0;

{ TBitmapMarkerProviderSimpleBase }

constructor TBitmapMarkerProviderSimpleBase.Create(
  AUseDirection: Boolean;
  ADefaultDirection: Double;
  AConfig: IBitmapMarkerProviderSimpleConfigStatic
);
begin
  FConfig := AConfig;
  FUseDirection := AUseDirection;
  FDefaultDirection := ADefaultDirection;

  FMarker := CreateMarker(FConfig.MarkerSize);
end;

function TBitmapMarkerProviderSimpleBase.GetMarker: IBitmapMarker;
begin
  Result := FMarker;
end;

function TBitmapMarkerProviderSimpleBase.GetMarkerBySize(
  ASize: Integer): IBitmapMarker;
begin
  if ASize = FConfig.MarkerSize then begin
    Result := FMarker;
  end else begin
    Result := CreateMarker(ASize);
  end;
end;

function TBitmapMarkerProviderSimpleBase.GetMarkerWithRotation(
  AAngle: Double): IBitmapMarker;
begin
  if (not FUseDirection) or (Abs(CalcAngleDelta(AAngle, FDefaultDirection)) < CAngleDelta) then begin
    Result := FMarker;
  end else begin
    Result := ModifyMarkerWithRotation(FMarker, AAngle);
  end;
end;

function TBitmapMarkerProviderSimpleBase.GetMarkerWithRotationBySize(
  AAngle: Double; ASize: Integer): IBitmapMarker;
begin
  if (not FUseDirection) or (Abs(CalcAngleDelta(AAngle, FDefaultDirection)) < CAngleDelta) then begin
    Result := GetMarkerBySize(ASize);
  end else begin
    Result := ModifyMarkerWithRotation(GetMarkerBySize(ASize), AAngle);
  end;
end;

function TBitmapMarkerProviderSimpleBase.GetUseDirection: Boolean;
begin
  Result := FUseDirection;
end;

function TBitmapMarkerProviderSimpleBase.ModifyMarkerWithRotation(
  ASourceMarker: IBitmapMarker; AAngle: Double): IBitmapMarker;
var
  VSizeSource: TPoint;
  VTargetRect: TFloatRect;
  VSizeTarget: TPoint;
  VBitmap: TCustomBitmap32;
  VFixedOnBitmap: TFloatPoint;
  VTransform: TAffineTransformation;
  VRasterizer: TRasterizer;
  VTransformer: TTransformer;
  VCombineInfo: TCombineInfo;
  VSampler: TCustomResampler;
begin
  VTransform := TAffineTransformation.Create;
  try
    VSizeSource := ASourceMarker.BitmapSize;
    VTransform.SrcRect := FloatRect(0, 0, VSizeSource.X, VSizeSource.Y);
    VTransform.Rotate(0, 0, ASourceMarker.Direction - AAngle);
    VTargetRect := VTransform.GetTransformedBounds;
    VSizeTarget.X := Trunc(VTargetRect.Right - VTargetRect.Left) + 1;
    VSizeTarget.Y := Trunc(VTargetRect.Bottom - VTargetRect.Top) + 1;
    VTransform.Translate(-VTargetRect.Left, -VTargetRect.Top);
    VBitmap := TCustomBitmap32.Create;
    try
      VBitmap.SetSize(VSizeTarget.X, VSizeTarget.Y);
      VBitmap.Clear(0);

      VRasterizer := TRegularRasterizer.Create;
      try
        VSampler := TLinearResampler.Create;
        try
          VSampler.Bitmap := ASourceMarker.Bitmap;
          VTransformer := TTransformer.Create(VSampler, VTransform);
          try
            VRasterizer.Sampler := VTransformer;
            VCombineInfo.SrcAlpha := 255;
            VCombineInfo.DrawMode := dmOpaque;
            VCombineInfo.CombineMode := cmBlend;
            VCombineInfo.TransparentColor := 0;
            VRasterizer.Rasterize(VBitmap, VBitmap.BoundsRect, VCombineInfo);
          finally
            EMMS;
            VTransformer.Free;
          end;
        finally
          VSampler.Free;
        end;
      finally
        VRasterizer.Free;
      end;

      VFixedOnBitmap := VTransform.Transform(FloatPoint(ASourceMarker.AnchorPoint.X, ASourceMarker.AnchorPoint.Y));
      Result :=
        TBitmapMarker.Create(
          VBitmap,
          DoublePoint(VFixedOnBitmap.X, VFixedOnBitmap.Y),
          True,
          AAngle
        );
    finally
      VBitmap.Free;
    end;
  finally
    VTransform.Free;
  end;
end;

{ TBitmapMarkerProviderChangeableWithConfig }

constructor TBitmapMarkerProviderChangeableWithConfig.Create(
  AProviderClass: TBitmapMarkerProviderSimpleBaseClass;
  AConfig: IBitmapMarkerProviderSimpleConfig);
begin
  FProviderClass := AProviderClass;
  FConfig := AConfig;

  FConfigChangeListener := TNotifyEventListener.Create(Self.OnConfigChange);
  FConfig.GetChangeNotifier.Add(FConfigChangeListener);

  FChangeNotifier := TJclBaseNotifier.Create;
  OnConfigChange(nil);
end;

destructor TBitmapMarkerProviderChangeableWithConfig.Destroy;
begin
  FConfig.GetChangeNotifier.Remove(FConfigChangeListener);
  FConfigChangeListener := nil;

  inherited;
end;

function TBitmapMarkerProviderChangeableWithConfig.GetChangeNotifier: IJclNotifier;
begin
  Result := FChangeNotifier;
end;

function TBitmapMarkerProviderChangeableWithConfig.GetStatic: IBitmapMarkerProvider;
begin
  Result := FProviderStatic;
end;

procedure TBitmapMarkerProviderChangeableWithConfig.OnConfigChange(
  Sender: TObject);
begin
  FProviderStatic := FProviderClass.CreateProvider(FConfig.GetStatic);
  FChangeNotifier.Notify(nil);
end;

end.

