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

unit u_ConfigDataProviderWithLocal;

interface

uses
  Classes,
  i_BinaryData,
  i_ConfigDataProvider;

type
  TConfigDataProviderWithLocal = class(TInterfacedObject, IConfigDataProvider)
  private
    FProviderMain: IConfigDataProvider;
    FProviderLocal: IConfigDataProvider;
    function PrepareIdent(const AIdent: string; out AUseMain, AUseLocal: Boolean): string;
  protected
    function GetSubItem(const AIdent: string): IConfigDataProvider; virtual;
    function ReadBinary(const AIdent: string): IBinaryData; virtual;
    function ReadString(const AIdent: string; const ADefault: string): string; virtual;
    function ReadInteger(const AIdent: string; const ADefault: Longint): Longint; virtual;
    function ReadBool(const AIdent: string; const ADefault: Boolean): Boolean; virtual;
    function ReadDate(const AIdent: string; const ADefault: TDateTime): TDateTime; virtual;
    function ReadDateTime(const AIdent: string; const ADefault: TDateTime): TDateTime; virtual;
    function ReadFloat(const AIdent: string; const ADefault: Double): Double; virtual;
    function ReadTime(const AIdent: string; const ADefault: TDateTime): TDateTime; virtual;

    procedure ReadSubItemsList(AList: TStrings); virtual;
    procedure ReadValuesList(AList: TStrings); virtual;
  public
    constructor Create(
      AProviderMain: IConfigDataProvider;
      AProviderLocal: IConfigDataProvider
    );
    destructor Destroy; override;
  public

  end;

implementation

uses
  StrUtils,
  SysUtils;

{ TConfigDataProviderWithLocal }

constructor TConfigDataProviderWithLocal.Create(AProviderMain,
  AProviderLocal: IConfigDataProvider);
begin
  FProviderMain := AProviderMain;
  FProviderLocal := AProviderLocal;
end;

destructor TConfigDataProviderWithLocal.Destroy;
begin
  FProviderMain := nil;
  FProviderLocal := nil;
  inherited;
end;

function TConfigDataProviderWithLocal.GetSubItem(
  const AIdent: string): IConfigDataProvider;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
  VSubItemMain: IConfigDataProvider;
  VSubItemLocal: IConfigDataProvider;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  if VUseMain then begin
    if FProviderMain <> nil then begin
      VSubItemMain := FProviderMain.GetSubItem(VIdent);
    end;
  end;
  if VUseLocal then begin
    if FProviderLocal <> nil then begin
      VSubItemLocal := FProviderLocal.GetSubItem(VIdent);
    end;
  end;
  if VUseLocal and VUseMain then begin
    if (VSubItemMain = nil) and (VSubItemLocal = nil) then begin
      Result := nil;
    end else begin
      Result := TConfigDataProviderWithLocal.Create(VSubItemMain, VSubItemLocal);
    end;
  end else if VUseLocal then begin
    Result := VSubItemLocal;
  end else if VUseMain then begin
    Result := VSubItemMain;
  end else begin
    Result := nil;
  end;
end;

function TConfigDataProviderWithLocal.PrepareIdent(
  const AIdent: string;
  out AUseMain,
  AUseLocal: Boolean): string;
var
  VPrefix: string;
  VSeparatorPos: Integer;
  VIdentLength: Integer;
begin
  VSeparatorPos := Pos(':', AIdent);
  if VSeparatorPos > 0 then begin
    VIdentLength := Length(AIdent);
    VPrefix := UpperCase(LeftStr(AIdent, VSeparatorPos - 1));
    Result := MidStr(AIdent, VSeparatorPos + 1, VIdentLength - VSeparatorPos);
  end else begin
    Result := AIdent;
  end;
  AUseMain := True;
  AUseLocal := True;
  if VPrefix = 'LOCAL' then begin
    AUseMain := False;
  end else if VPrefix = 'MAIN' then begin
    AUseLocal := False;
  end;
end;

function TConfigDataProviderWithLocal.ReadBinary(const AIdent: string): IBinaryData;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := nil;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadBinary(VIdent);
  end;
  if (Result = nil) and VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadBinary(VIdent);
  end;
end;

function TConfigDataProviderWithLocal.ReadBool(const AIdent: string;
  const ADefault: Boolean): Boolean;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadBool(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadBool(VIdent, Result);
  end;
end;

function TConfigDataProviderWithLocal.ReadDate(const AIdent: string;
  const ADefault: TDateTime): TDateTime;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadDate(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadDate(VIdent, Result);
  end;
end;

function TConfigDataProviderWithLocal.ReadDateTime(const AIdent: string;
  const ADefault: TDateTime): TDateTime;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadDateTime(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadDateTime(VIdent, Result);
  end;
end;

function TConfigDataProviderWithLocal.ReadFloat(const AIdent: string;
  const ADefault: Double): Double;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadFloat(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadFloat(VIdent, Result);
  end;
end;

function TConfigDataProviderWithLocal.ReadInteger(const AIdent: string;
  const ADefault: Integer): Longint;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadInteger(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadInteger(VIdent, Result);
  end;
end;

function TConfigDataProviderWithLocal.ReadString(const AIdent,
  ADefault: string): string;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadString(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadString(VIdent, Result);
  end;
end;

procedure TConfigDataProviderWithLocal.ReadSubItemsList(AList: TStrings);
var
  VList: TStrings;
begin
  VList := TStringList.Create;
  try
    if (FProviderMain <> nil) then begin
      VList.Clear;
      FProviderMain.ReadSubItemsList(VList);
      AList.AddStrings(VList);
    end;
    if (FProviderLocal <> nil) then begin
      VList.Clear;
      FProviderLocal.ReadSubItemsList(VList);
      AList.AddStrings(VList);
    end;
  finally
    VList.Free;
  end;
end;

function TConfigDataProviderWithLocal.ReadTime(const AIdent: string;
  const ADefault: TDateTime): TDateTime;
var
  VIdent: string;
  VUseLocal: Boolean;
  VUseMain: Boolean;
begin
  VIdent := PrepareIdent(AIdent, VUseMain, VUseLocal);
  Result := ADefault;
  if VUseMain and (FProviderMain <> nil) then begin
    Result := FProviderMain.ReadTime(VIdent, Result);
  end;
  if VUseLocal and (FProviderLocal <> nil) then begin
    Result := FProviderLocal.ReadTime(VIdent, Result);
  end;
end;

procedure TConfigDataProviderWithLocal.ReadValuesList(AList: TStrings);
var
  VList: TStrings;
begin
  VList := TStringList.Create;
  try
    if (FProviderMain <> nil) then begin
      VList.Clear;
      FProviderMain.ReadValuesList(VList);
      AList.AddStrings(VList);
    end;
    if (FProviderLocal <> nil) then begin
      VList.Clear;
      FProviderLocal.ReadValuesList(VList);
      AList.AddStrings(VList);
    end;
  finally
    VList.Free;
  end;
end;

end.
