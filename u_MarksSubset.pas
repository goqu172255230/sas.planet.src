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

unit u_MarksSubset;

interface

uses
  Classes,
  ActiveX,
  t_GeoTypes,
  i_MarksSimple;

type
  TMarksSubset = class(TInterfacedObject, IMarksSubset)
  private
    FList: IInterfaceList;
  protected
    function GetSubsetByLonLatRect(ARect: TDoubleRect): IMarksSubset;
    function GetEnum: IEnumUnknown;
    function IsEmpty: Boolean;
  public
    constructor Create(AList: IInterfaceList);
  end;

implementation

uses
  u_EnumUnknown;

{ TMarksSubset }

constructor TMarksSubset.Create(AList: IInterfaceList);
begin
  FList := AList;
end;

function TMarksSubset.GetEnum: IEnumUnknown;
begin
  Result := TEnumUnknown.Create(FList);
end;

function TMarksSubset.GetSubsetByLonLatRect(ARect: TDoubleRect): IMarksSubset;
var
  VNewList: IInterfaceList;
  i: Integer;
  VMark: IMark;
  VMarkLonLatRect: TDoubleRect;
begin
  VNewList := TInterfaceList.Create;
  VNewList.Lock;
  try
    for i := 0 to FList.Count - 1 do begin
      VMark := IMark(FList.Items[i]);
      VMarkLonLatRect := VMark.LLRect;
      if(
        (ARect.Right >= VMarkLonLatRect.Left)and
        (ARect.Left <= VMarkLonLatRect.Right)and
        (ARect.Bottom <= VMarkLonLatRect.Top)and
        (ARect.Top >= VMarkLonLatRect.Bottom))
      then begin
        VNewList.Add(VMark);
      end;
    end;
  finally
    VNewList.Unlock;
  end;
  Result := TMarksSubset.Create(VNewList);
end;

function TMarksSubset.IsEmpty: Boolean;
begin
  Result := FList.Count = 0;
end;

end.
