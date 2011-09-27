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

unit u_JclListenerNotifierLinksList;

interface

uses
  Classes,
  SyncObjs,
  i_JclNotify,
  i_JclListenerNotifierLinksList;

type
  TJclListenerNotifierLinksList = class(TInterfacedObject, IJclListenerNotifierLinksList)
  private
    FCS: TCriticalSection;
    FLinksActive: Boolean;
    FListenerList: IInterfaceList;
    FNotifierList: IInterfaceList;
    function GetCount: Integer;
    procedure ActivateLink(AIndex: Integer);
    procedure DeactivateLink(AIndex: Integer);
    procedure DoActivateLinks;
    procedure DoDeactivateLinks;
  protected
    procedure Add(AListener: IJclListener; ANotifier: IJclNotifier);
    procedure ActivateLinks;
    procedure DeactivateLinks;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils;

{ TJclListenerNotifierLinksList }

constructor TJclListenerNotifierLinksList.Create;
begin
  FCS := TCriticalSection.Create;
  FListenerList := TInterfaceList.Create;
  FNotifierList := TInterfaceList.Create;
  FLinksActive := False;
end;

destructor TJclListenerNotifierLinksList.Destroy;
begin
  FreeAndNil(FCS);
  FListenerList := nil;
  FNotifierList := nil;
  inherited;
end;

procedure TJclListenerNotifierLinksList.DoActivateLinks;
var
  i: Integer;
begin
  if not FLinksActive then begin
    for i := 0 to GetCount - 1 do begin
      ActivateLink(i);
    end;
    FLinksActive := True;
  end;
end;

procedure TJclListenerNotifierLinksList.DoDeactivateLinks;
var
  i: Integer;
begin
  if FLinksActive then begin
    for i := 0 to GetCount - 1 do begin
      DeactivateLink(i);
    end;
    FLinksActive := False;
  end;
end;

function TJclListenerNotifierLinksList.GetCount: Integer;
begin
  Result := FListenerList.Count;
end;

procedure TJclListenerNotifierLinksList.ActivateLink(AIndex: Integer);
var
  VListener: IJclListener;
  VNotifier: IJclNotifier;
begin
  VListener := IJclListener(FListenerList.Items[AIndex]);
  VNotifier := IJclNotifier(FNotifierList.Items[AIndex]);
  if (VListener <> nil) and (VNotifier <> nil) then begin
    VNotifier.Add(VListener);
  end;
end;


procedure TJclListenerNotifierLinksList.ActivateLinks;
begin
  FCS.Acquire;
  try
    DoActivateLinks;
  finally
    FCS.Release;
  end;
end;

procedure TJclListenerNotifierLinksList.Add(AListener: IJclListener;
  ANotifier: IJclNotifier);
var
  VListenerIndex: Integer;
  VNotifierIndex: Integer;
begin
  FCS.Acquire;
  try
    VListenerIndex := FListenerList.Add(AListener);
    VNotifierIndex := FNotifierList.Add(ANotifier);
    Assert(VListenerIndex = VNotifierIndex);
    if FLinksActive then begin
      ActivateLink(VListenerIndex);
    end;
  finally
    FCS.Release;
  end;
end;

procedure TJclListenerNotifierLinksList.DeactivateLink(AIndex: Integer);
var
  VListener: IJclListener;
  VNotifier: IJclNotifier;
begin
  VListener := IJclListener(FListenerList.Items[AIndex]);
  VNotifier := IJclNotifier(FNotifierList.Items[AIndex]);
  if (VListener <> nil) and (VNotifier <> nil) then begin
    VNotifier.Remove(VListener);
  end;
end;

procedure TJclListenerNotifierLinksList.DeactivateLinks;
begin
  FCS.Acquire;
  try
    DoDeactivateLinks;
  finally
    FCS.Release;
  end;
end;

end.
