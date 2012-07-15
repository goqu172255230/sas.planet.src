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

unit u_SensorsFromGPSRecorder;

interface

uses
  i_GPS,
  i_GPSRecorder,
  i_Sensor,
  u_SensorFromGPSRecorderBase;

type
  TSensorFromGPSRecorderLastSpeed = class(TSensorDoubeleValueFromGPSRecorder, ISensorSpeed)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
  end;

  TSensorFromGPSRecorderAvgSpeed = class(TSensorDoubeleValueFromGPSRecorder, ISensorSpeed, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderMaxSpeed = class(TSensorDoubeleValueFromGPSRecorder, ISensorSpeed, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderDist = class(TSensorDoubeleValueFromGPSRecorder, ISensorDistance, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderOdometer1 = class(TSensorDoubeleValueFromGPSRecorder, ISensorDistance, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderOdometer2 = class(TSensorDoubeleValueFromGPSRecorder, ISensorDistance, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderAltitude = class(TSensorDoubeleValueFromGPSRecorder, ISensorDistance)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
  end;

  TSensorFromGPSRecorderHeading = class(TSensorDoubeleValueFromGPSRecorder, ISensorDegrees)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
  end;

  TSensorFromGPSRecorderHDOP = class(TSensorDoubeleValueFromGPSRecorder, ISensorDouble)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
  end;

  TSensorFromGPSRecorderVDOP = class(TSensorDoubeleValueFromGPSRecorder, ISensorDouble)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: Double; override;
  end;

  TSensorFromGPSRecorderUTCTime = class(TSensorDateTimeValueFromGPSRecorder, ISensorTime)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: TDateTime; override;
  end;

  TSensorFromGPSRecorderLocalTime = class(TSensorDateTimeValueFromGPSRecorder, ISensorTime, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: TDateTime; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderDGPS = class(TSensorTextValueFromGPSRecorder, ISensorText, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: string; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderGPSUnitInfo = class(TSensorTextValueFromGPSRecorder, ISensorText, ISensorResetable)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: string; override;
    procedure Reset;
  end;

  TSensorFromGPSRecorderGPSSatellites = class(TSensorGPSSatellitesValueFromGPSRecorder, ISensorGPSSatellites)
  protected
    function GetSensorTypeIID: TGUID; override;
    function GetCurrentValue: IGPSSatellitesInView; override;
  end;

implementation

uses
  SysUtils,
  u_GeoToStr,
  vsagps_public_base,
  vsagps_public_position,
  vsagps_public_time;

{ TSensorFromGPSRecorderLastSpeed }

function TSensorFromGPSRecorderLastSpeed.GetCurrentValue: Double;
begin
  Result := GPSRecorder.LastSpeed;
end;

function TSensorFromGPSRecorderLastSpeed.GetSensorTypeIID: TGUID;
begin
  Result := ISensorSpeed;
end;

{ TSensorFromGPSRecorderAvgSpeed }

function TSensorFromGPSRecorderAvgSpeed.GetCurrentValue: Double;
begin
  Result := GPSRecorder.AvgSpeed;
end;

function TSensorFromGPSRecorderAvgSpeed.GetSensorTypeIID: TGUID;
begin
  Result := ISensorSpeed;
end;

procedure TSensorFromGPSRecorderAvgSpeed.Reset;
begin
  inherited;
  GPSRecorder.ResetAvgSpeed;
end;

{ TSensorFromGPSRecorderMaxSpeed }

function TSensorFromGPSRecorderMaxSpeed.GetCurrentValue: Double;
begin
  Result := GPSRecorder.MaxSpeed;
end;

function TSensorFromGPSRecorderMaxSpeed.GetSensorTypeIID: TGUID;
begin
  Result := ISensorSpeed;
end;

procedure TSensorFromGPSRecorderMaxSpeed.Reset;
begin
  inherited;
  GPSRecorder.ResetMaxSpeed;
end;

{ TSensorFromGPSRecorderDist }

function TSensorFromGPSRecorderDist.GetCurrentValue: Double;
begin
  Result := GPSRecorder.Dist;
end;

function TSensorFromGPSRecorderDist.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDistance;
end;

procedure TSensorFromGPSRecorderDist.Reset;
begin
  inherited;
  GPSRecorder.ResetDist;
end;

{ TSensorFromGPSRecorderOdometer1 }

function TSensorFromGPSRecorderOdometer1.GetCurrentValue: Double;
begin
  Result := GPSRecorder.Odometer1;
end;

function TSensorFromGPSRecorderOdometer1.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDistance;
end;

procedure TSensorFromGPSRecorderOdometer1.Reset;
begin
  inherited;
  GPSRecorder.ResetOdometer1;
end;

{ TSensorFromGPSRecorderOdometer2 }

function TSensorFromGPSRecorderOdometer2.GetCurrentValue: Double;
begin
  Result := GPSRecorder.Odometer2;
end;

function TSensorFromGPSRecorderOdometer2.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDistance;
end;

procedure TSensorFromGPSRecorderOdometer2.Reset;
begin
  inherited;
  GPSRecorder.ResetOdometer2;
end;

{ TSensorFromGPSRecorderAltitude }

function TSensorFromGPSRecorderAltitude.GetCurrentValue: Double;
begin
  Result := GPSRecorder.LastAltitude;
end;

function TSensorFromGPSRecorderAltitude.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDistance;
end;

{ TSensorFromGPSRecorderHeading }

function TSensorFromGPSRecorderHeading.GetCurrentValue: Double;
begin
  Result := GPSRecorder.LastHeading;
end;

function TSensorFromGPSRecorderHeading.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDegrees;
end;

{ TSensorFromGPSRecorderHDOP }

function TSensorFromGPSRecorderHDOP.GetCurrentValue: Double;
var
  VPosition: IGPSPosition;
begin
  VPosition := GPSRecorder.CurrentPosition;
  Result := VPosition.GetPosParams^.HDOP;
end;

function TSensorFromGPSRecorderHDOP.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDouble;
end;

{ TSensorFromGPSRecorderVDOP }

function TSensorFromGPSRecorderVDOP.GetCurrentValue: Double;
var
  VPosition: IGPSPosition;
begin
  VPosition := GPSRecorder.CurrentPosition;
  Result := VPosition.GetPosParams^.VDOP;
end;

function TSensorFromGPSRecorderVDOP.GetSensorTypeIID: TGUID;
begin
  Result := ISensorDouble;
end;

{ TSensorFromGPSRecorderUTCTime }

function TSensorFromGPSRecorderUTCTime.GetCurrentValue: TDateTime;
var
  VPosition: IGPSPosition;
begin
  VPosition := GPSRecorder.CurrentPosition;
  with VPosition.GetPosParams^ do begin
    Result := (UTCDate + UTCTime);
  end;
end;

function TSensorFromGPSRecorderUTCTime.GetSensorTypeIID: TGUID;
begin
  Result := ISensorTime;
end;

{ TSensorFromGPSRecorderLocalTime }

function TSensorFromGPSRecorderLocalTime.GetCurrentValue: TDateTime;
var
  VPosition: IGPSPosition;
begin
  VPosition := GPSRecorder.CurrentPosition;
  with VPosition.GetPosParams^ do begin
    Result := (UTCDate + UTCTime);
  end;
  if (0 <> Result) then begin
    Result := SystemTimeToLocalTime(Result);
  end;
end;

function TSensorFromGPSRecorderLocalTime.GetSensorTypeIID: TGUID;
begin
  Result := ISensorTime;
end;

procedure TSensorFromGPSRecorderLocalTime.Reset;
begin
  inherited;
  GPSRecorder.ExecuteGPSCommand(Self, cUnitIndex_ALL, gpsc_Apply_UTCDateTime, nil);
end;

{ TSensorFromGPSRecorderDGPS }

function TSensorFromGPSRecorderDGPS.GetCurrentValue: string;
var
  VPosition: IGPSPosition;
begin
  VPosition := GPSRecorder.CurrentPosition;
  with VPosition.GetPosParams^.DGPS do begin
    case Nmea23_Mode of
      'A': begin
        Result := 'A';
      end; //'Autonomous';
      'D': begin
        Result := 'DGPS';
      end; //'DGPS';
      'E': begin
        Result := 'DR';
      end; //'Dead Reckoning';
      'R': begin
        Result := 'CP';
      end; //'Coarse Position';
      'P': begin
        Result := 'PPS';
      end; //'PPS';
    else begin
      Result := 'N';
    end; //#0 if no data or 'N' = Not Valid
    end;

    if (Dimentions > 1) then begin
      Result := Result + ' (' + IntToStr(Dimentions) + 'D)';
    end;

    if (not NoData_Float32(DGPS_Age_Second)) then begin
      if (DGPS_Age_Second > 0) then begin
        Result := Result + ': ' + RoundEx(DGPS_Age_Second, 2);
      end;//+' '+SAS_UNITS_Secund;
      if (DGPS_Station_ID > 0) then begin
        Result := Result + ' #' + IntToStr(DGPS_Station_ID);
      end;
    end;
  end;
end;

function TSensorFromGPSRecorderDGPS.GetSensorTypeIID: TGUID;
begin
  Result := ISensorText;
end;

procedure TSensorFromGPSRecorderDGPS.Reset;
begin
  inherited;
  GPSRecorder.ExecuteGPSCommand(Self, cUnitIndex_ALL, gpsc_Reset_DGPS, nil);
end;

{ TSensorFromGPSRecorderGPSUnitInfo }

function TSensorFromGPSRecorderGPSUnitInfo.GetCurrentValue: string;
begin
  Result := GPSRecorder.GPSUnitInfo;
end;

function TSensorFromGPSRecorderGPSUnitInfo.GetSensorTypeIID: TGUID;
begin
  Result := ISensorText;
end;

procedure TSensorFromGPSRecorderGPSUnitInfo.Reset;
begin
  inherited;
  GPSRecorder.ExecuteGPSCommand(Self, cUnitIndex_ALL, gpsc_Refresh_GPSUnitInfo, nil);
end;

{ TSensorFromGPSRecorderGPSSatellites }

function TSensorFromGPSRecorderGPSSatellites.GetCurrentValue: IGPSSatellitesInView;
var
  VPosition: IGPSPosition;
begin
  Result := nil;
  VPosition := GPSRecorder.CurrentPosition;
  if VPosition <> nil then begin
    Result := VPosition.Satellites;
  end;
end;

function TSensorFromGPSRecorderGPSSatellites.GetSensorTypeIID: TGUID;
begin
  Result := ISensorGPSSatellites;
end;

end.
