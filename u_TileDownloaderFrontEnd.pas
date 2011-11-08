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

unit u_TileDownloaderFrontEnd;

interface

uses
  Windows,
  SysUtils,
  i_CoordConverterFactory,
  i_LanguageManager,
  i_InvisibleBrowser,
  i_DownloadChecker,
  i_TileRequestBuilderConfig,
  i_TileDownloader,
  i_TileDownloaderConfig,
  i_ZmpInfo;

type
  TTileDownloaderFrontEnd = class
  private
    FDownloader: ITileDownloader;
    FEnabled: Boolean;
  public
    constructor Create(
      ATileDownloaderConfig: ITileDownloaderConfig;
      ATileRequestBuilderConfig: ITileRequestBuilderConfig;
      AZmp: IZmpInfo;
      ADownloadChecker: IDownloadChecker;
      ACoordConverterFactory: ICoordConverterFactory;
      ALangManager: ILanguageManager;
      AInvisibleBrowser: IInvisibleBrowser
    );
    destructor Destroy; override;
    procedure Download(AEvent: ITileDownloaderEvent);
    property Enabled: Boolean read FEnabled;
  end;

implementation

uses
  u_TileDownloaderBaseCore;

{ TTileDownloaderFrontEnd }

constructor TTileDownloaderFrontEnd.Create(
  ATileDownloaderConfig: ITileDownloaderConfig;
  ATileRequestBuilderConfig: ITileRequestBuilderConfig;
  AZmp: IZmpInfo;
  ADownloadChecker: IDownloadChecker;
  ACoordConverterFactory: ICoordConverterFactory;
  ALangManager: ILanguageManager;
  AInvisibleBrowser: IInvisibleBrowser
);
begin
  inherited Create;
  FEnabled := False;
  FDownloader := TTileDownloaderBaseCore.Create(
    ATileDownloaderConfig,
    ATileRequestBuilderConfig,
    AZmp,
    ADownloadChecker,
    ACoordConverterFactory,
    ALangManager,
    AInvisibleBrowser
  );
  FEnabled := FDownloader.Enabled;
end;

destructor TTileDownloaderFrontEnd.Destroy;
begin
  FDownloader := nil;
  inherited Destroy;
end;

procedure TTileDownloaderFrontEnd.Download(AEvent: ITileDownloaderEvent);
begin
  if Assigned(AEvent) then begin
    FDownloader.Download(AEvent)
  end;
end;

end.
