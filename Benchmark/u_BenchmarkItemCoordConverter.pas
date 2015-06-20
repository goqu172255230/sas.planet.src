{******************************************************************************}
{* SAS.Planet (SAS.Планета)                                                   *}
{* Copyright (C) 2007-2014, SAS.Planet development team.                      *}
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

unit u_BenchmarkItemCoordConverter;

interface

uses
  i_CoordConverter,
  u_BenchmarkItemDoublePointBaseTest;

type
  TBenchmarkItemCoordConverterForvard = class(TBenchmarkItemDoublePointBaseTest)
  private
    FCoordConverter: ICoordConverter;
  protected
    function RunOneStep: Integer; override;
  public
    constructor Create(
      const ACoordConverterName: string;
      const ACoordConverter: ICoordConverter
    );
  end;

  TBenchmarkItemCoordConverterBackvard = class(TBenchmarkItemDoublePointBaseTest)
  private
    FCoordConverter: ICoordConverter;
  protected
    function RunOneStep: Integer; override;
  public
    constructor Create(
      const ACoordConverterName: string;
      const ACoordConverter: ICoordConverter
    );
  end;

implementation

uses
  t_GeoTypes,
  u_GeoFunc;

const CPointsCount = 1000;

{ TBenchmarkItemCoordConverterForvard }

constructor TBenchmarkItemCoordConverterForvard.Create(
  const ACoordConverterName: string;
  const ACoordConverter: ICoordConverter
);
begin
  inherited Create(
    Assigned(ACoordConverter),
    'CoordConverter LlToRel ' + ACoordConverterName,
    CPointsCount,
    DoubleRect(-170, -75, 170, 75)
  );
  FCoordConverter := ACoordConverter;
end;

function TBenchmarkItemCoordConverterForvard.RunOneStep: Integer;
var
  i: Integer;
  VResult: TDoublePoint;
begin
  Result := 0;
  for i := 0 to FCount - 1 do begin
    VResult := FCoordConverter.LonLat2Relative(FPoints[i]);
    Inc(Result);
  end;
end;

{ TBenchmarkItemCoordConverterBackvard }

constructor TBenchmarkItemCoordConverterBackvard.Create(
  const ACoordConverterName: string;
  const ACoordConverter: ICoordConverter
);
begin
  inherited Create(
    Assigned(ACoordConverter),
    'CoordConverter RelToLl ' + ACoordConverterName,
    CPointsCount,
    DoubleRect(0, 0, 1, 1)
  );
  FCoordConverter := ACoordConverter;
end;

function TBenchmarkItemCoordConverterBackvard.RunOneStep: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FCount - 1 do begin
    FDst[i] := FCoordConverter.Relative2LonLat(FPoints[i]);
    Inc(Result);
  end;
end;

end.
