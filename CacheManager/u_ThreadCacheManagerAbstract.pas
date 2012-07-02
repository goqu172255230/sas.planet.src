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

unit u_ThreadCacheManagerAbstract;

interface

uses
  Classes,
  i_JclNotify,
  i_OperationNotifier;

type
  TThreadCacheManagerAbstract = class(TThread)
  private
    FOperationID: Integer;
    FCancelListener: IListener;
    FMessageForShow: string;
    FCancelNotifier: IOperationNotifier;
    procedure OnCancel;
    procedure SynShowMessage;
    procedure ShowMessageSync(const AMessage: string);
  protected
    procedure Process; virtual; abstract;
    procedure Execute; override;
    property CancelNotifier: IOperationNotifier read FCancelNotifier;
  public
    constructor Create(
      const ACancelNotifier: IOperationNotifier;
      const AOperationID: Integer
    );
    destructor Destroy; override;
  end;

implementation

uses
  Dialogs,
  SysUtils,
  u_NotifyEventListener;

{ TThreadCacheManagerAbstract }

constructor TThreadCacheManagerAbstract.Create(
  const ACancelNotifier: IOperationNotifier;
  const AOperationID: Integer
);
begin
  inherited Create(True);
  Self.Priority := tpNormal;
  Self.FreeOnTerminate := True;
  FCancelNotifier := ACancelNotifier;
  FOperationID := AOperationID;
  if not FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    FCancelListener := TNotifyNoMmgEventListener.Create(Self.OnCancel);
    FCancelNotifier.AddListener(FCancelListener);
  end;
  if FCancelNotifier.IsOperationCanceled(FOperationID) then begin
    Terminate;
  end else begin
    Resume;
  end;
end;

destructor TThreadCacheManagerAbstract.Destroy;
begin
  if (FCancelListener <> nil) and (FCancelNotifier <> nil) then begin
    FCancelNotifier.RemoveListener(FCancelListener);
    FCancelListener := nil;
    FCancelNotifier := nil;
  end;
  inherited;
end;

procedure TThreadCacheManagerAbstract.Execute;
begin
  try
    Process;
  except
    on E: Exception do begin
      ShowMessageSync(E.Message);
    end;
  end;
end;

procedure TThreadCacheManagerAbstract.OnCancel;
begin
  Terminate;
end;

procedure TThreadCacheManagerAbstract.ShowMessageSync(const AMessage: string);
begin
  FMessageForShow := AMessage;
  Synchronize(SynShowMessage);
end;

procedure TThreadCacheManagerAbstract.SynShowMessage;
begin
  ShowMessage(FMessageForShow);
end;

end.

