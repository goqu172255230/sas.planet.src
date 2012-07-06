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

unit u_MarkPolyLineLayerConfig;

interface

uses
  i_MarkPolyLineLayerConfig,
  i_PolyLineLayerConfig,
  u_ConfigDataElementComplexBase;

type
  TMarkPolyLineLayerConfig = class(TConfigDataElementComplexBase, IMarkPolyLineLayerConfig)
  private
    FLineConfig: ILineLayerConfig;
    FPointsConfig: IPointsSetLayerConfig;
  private
    function GetLineConfig: ILineLayerConfig;
    function GetPointsConfig: IPointsSetLayerConfig;
  public
    constructor Create;
  end;

implementation

uses
  GR32,
  u_ConfigSaveLoadStrategyBasicUseProvider,
  u_PolyLineLayerConfig;

{ TMarkPolyLineLayerConfig }

constructor TMarkPolyLineLayerConfig.Create;
begin
  inherited Create;
  FLineConfig := TLineLayerConfig.Create;
  FLineConfig.LineColor := SetAlpha(ClRed32, 150);
  FLineConfig.LineWidth := 3;
  Add(FLineConfig, TConfigSaveLoadStrategyBasicUseProvider.Create);

  FPointsConfig := TPointsSetLayerConfig.Create;
  FPointsConfig.PointFillColor := SetAlpha(clYellow32, 150);
  FPointsConfig.PointRectColor := SetAlpha(ClRed32, 150);
  FPointsConfig.PointFirstColor := SetAlpha(ClGreen32, 255);
  FPointsConfig.PointActiveColor := SetAlpha(ClRed32, 255);
  FPointsConfig.PointSize := 8;
  Add(FPointsConfig, TConfigSaveLoadStrategyBasicUseProvider.Create);
end;

function TMarkPolyLineLayerConfig.GetLineConfig: ILineLayerConfig;
begin
  Result := FLineConfig;
end;

function TMarkPolyLineLayerConfig.GetPointsConfig: IPointsSetLayerConfig;
begin
  Result := FPointsConfig;
end;

end.
