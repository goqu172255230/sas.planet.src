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

unit u_PathDetalizeProviderListSimple;

interface

uses
  i_LanguageManager,
  i_ProxySettings,
  i_VectorDataLoader,
  u_PathDetalizeProviderListBase;

type
  TPathDetalizeProviderListSimple = class(TPathDetalizeProviderListBase)
  public
    constructor Create(
      ALanguageManager: ILanguageManager;
      AProxyConfig: IProxyConfig;
      AKmlLoader: IVectorDataLoader
    );
  end;

implementation

uses
  i_PathDetalizeProviderList,
  u_PathDetalizeProviderYourNavigation,
  u_PathDetalizeProviderMailRu,
  u_PathDetalizeProviderCloudMade;

{ TPathDetalizeProviderListSimple }

constructor TPathDetalizeProviderListSimple.Create(
  ALanguageManager: ILanguageManager;
  AProxyConfig: IProxyConfig;
  AKmlLoader: IVectorDataLoader
);
var
  VEntity: IPathDetalizeProviderListEntity;
begin
  inherited Create;
  VEntity := TPathDetalizeProviderMailRuShortest.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderMailRuFastest.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderMailRuFastestWithTraffic.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderYourNavigationFastestByCar.Create(ALanguageManager, AProxyConfig, AKmlLoader);
  Add(VEntity);
  VEntity := TPathDetalizeProviderYourNavigationShortestByCar.Create(ALanguageManager, AProxyConfig, AKmlLoader);
  Add(VEntity);
  VEntity := TPathDetalizeProviderYourNavigationFastestByBicycle.Create(ALanguageManager, AProxyConfig, AKmlLoader);
  Add(VEntity);
  VEntity := TPathDetalizeProviderYourNavigationShortestByBicycle.Create(ALanguageManager, AProxyConfig, AKmlLoader);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeFastestByCar.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeFastestByFoot.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeFastestByBicycle.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeShortestByCar.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeShortestByFoot.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
  VEntity := TPathDetalizeProviderCloudMadeShortestByBicycle.Create(ALanguageManager, AProxyConfig);
  Add(VEntity);
end;

end.
