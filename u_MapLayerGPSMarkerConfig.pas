{******************************************************************************}
{* SAS.������� (SAS.Planet)                                                   *}
{* Copyright (C) 2007-2011, ������ ��������� SAS.������� (SAS.Planet).        *}
{* ��� ��������� �������� ��������� ����������� ������������. �� ������       *}
{* �������������� �/��� �������������� � �������� �������� �����������       *}
{* ������������ �������� GNU, �������������� ������ ���������� ������������   *}
{* �����������, ������ 3. ��� ��������� ���������������� � �������, ��� ���   *}
{* ����� ��������, �� ��� ������ ��������, � ��� ����� ���������������        *}
{* �������� ��������� ��������� ��� ������� � �������� ��� ������˨�����      *}
{* ����������. �������� ����������� ������������ �������� GNU ������ 3, ���   *}
{* ��������� �������������� ����������. �� ������ ���� �������� �����         *}
{* ����������� ������������ �������� GNU ������ � ����������. � ������ �     *}
{* ����������, ���������� http://www.gnu.org/licenses/.                       *}
{*                                                                            *}
{* http://sasgis.ru/sasplanet                                                 *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_MapLayerGPSMarkerConfig;

interface

uses
  Types,
  GR32,
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_MapLayerGPSMarkerConfig,
  i_BitmapMarkerProviderSimpleConfig,
  u_ConfigDataElementComplexBase;

type
  TMapLayerGPSMarkerConfig = class(TConfigDataElementComplexBase, IMapLayerGPSMarkerConfig)
  private
    FMinMoveSpeed: Double;
    FMovedMarkerConfig: IBitmapMarkerProviderSimpleConfig;
    FStopedMarkerConfig: IBitmapMarkerProviderSimpleConfig;

  protected
    procedure DoReadConfig(AConfigData: IConfigDataProvider); override;
    procedure DoWriteConfig(AConfigData: IConfigDataWriteProvider); override;
  protected
    function GetMinMoveSpeed: Double;
    procedure SetMinMoveSpeed(AValue: Double);

    function GetMovedMarkerConfig: IBitmapMarkerProviderSimpleConfig;
    function GetStopedMarkerConfig: IBitmapMarkerProviderSimpleConfig;
  public
    constructor Create;
  end;

implementation

uses
  SysUtils,
  u_BitmapMarkerProviderSimpleConfig,
  u_BitmapMarkerProviderSimpleConfigStatic,
  u_ConfigSaveLoadStrategyBasicProviderSubItem;

{ TMapLayerGPSMarkerConfig }

constructor TMapLayerGPSMarkerConfig.Create;
begin
  inherited;
  FMinMoveSpeed := 1;

  FMovedMarkerConfig :=
    TBitmapMarkerProviderSimpleConfig.Create(
      TBitmapMarkerProviderSimpleConfigStatic.Create(
        25,
        SetAlpha(clRed32, 150),
        SetAlpha(clBlack32, 200)
      )
    );
  Add(FMovedMarkerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MarkerMoved'));

  FStopedMarkerConfig :=
    TBitmapMarkerProviderSimpleConfig.Create(
      TBitmapMarkerProviderSimpleConfigStatic.Create(
        10,
        SetAlpha(clRed32, 200),
        SetAlpha(clBlack32, 200)
      )
    );
  Add(FStopedMarkerConfig, TConfigSaveLoadStrategyBasicProviderSubItem.Create('MarkerStoped'));
end;

procedure TMapLayerGPSMarkerConfig.DoReadConfig(
  AConfigData: IConfigDataProvider);
begin
  inherited;
  if AConfigData <> nil then begin
    FMinMoveSpeed := AConfigData.ReadFloat('MinSpeed', FMinMoveSpeed);
    SetChanged;
  end;
end;

procedure TMapLayerGPSMarkerConfig.DoWriteConfig(
  AConfigData: IConfigDataWriteProvider);
begin
  inherited;
  AConfigData.WriteFloat('MinSpeed', FMinMoveSpeed);
end;

function TMapLayerGPSMarkerConfig.GetMinMoveSpeed: Double;
begin
  LockRead;
  try
    Result := FMinMoveSpeed;
  finally
    UnlockRead;
  end;
end;

function TMapLayerGPSMarkerConfig.GetMovedMarkerConfig: IBitmapMarkerProviderSimpleConfig;
begin
  Result := FMovedMarkerConfig;
end;

function TMapLayerGPSMarkerConfig.GetStopedMarkerConfig: IBitmapMarkerProviderSimpleConfig;
begin
  Result := FStopedMarkerConfig;
end;

procedure TMapLayerGPSMarkerConfig.SetMinMoveSpeed(AValue: Double);
begin
  LockWrite;
  try
    if FMinMoveSpeed <> AValue then begin
      FMinMoveSpeed := AValue;
      SetChanged;
    end;
  finally
    UnlockWrite;
  end;
end;

end.
