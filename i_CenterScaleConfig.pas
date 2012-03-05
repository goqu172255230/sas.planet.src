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

unit i_CenterScaleConfig;

interface

uses
  i_Bitmap32Static,
  i_ConfigDataElement;

type
  ICenterScaleConfig = interface(IConfigDataElement)
    ['{8C83DD24-D0D4-4DAD-ACEF-9359587DDE0B}']
    function GetVisible: Boolean;
    procedure SetVisible(const AValue: Boolean);
    property Visible: Boolean read GetVisible write SetVisible;

    function GetBitmap: IBitmap32Static;
    procedure SetBitmap(AValue: IBitmap32Static);
    property Bitmap: IBitmap32Static read GetBitmap write SetBitmap;
 end;

implementation

end.
