{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2015, SAS.Planet development team.                      *}
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

unit c_MarkSystem;

interface

const
  cSMLMarksDbGUID: TGUID = '{F5A9FB07-FF9B-4B4A-98D3-AB8C5F24F36B}';
  cORMSQLiteMarksDbGUID: TGUID = '{776BC34B-7A4B-4237-BE9A-D905228FDA1A}';

const
  cSMLMarksDbDefFileName = 'marks';
  cSMLMarksDbFileExt = '.sml';

  cORMSQLiteMarksDbDefFileName = 'Marks';
  cORMSQLiteMarksDbFileExt = '.db3';

resourcestring
  rsSMLMarksDbName = 'SML';
  rsORMSQLiteMarksDbName = 'SQLite3';

implementation

end.
