{******************************************************************************}
{* SAS.������� (SAS.Planet)                                                   *}
{* Copyright (C) 2007-2011, ������ ��������� SAS.������� (SAS.Planet).        *}
{* ��� ��������� �������� ��������� ����������� ������������. �� ������       *}
{* �������������� �/��� �������������� � �������� �������� �����������       *}
{* ������������ �������� GNU, �������������� ������ ���������� ������������   *}
{* �����������, ������ 3. ��� ��������� ���������������� � �������, ��� ���   *}
{* ����� ��������, �� ��� ������ ��������, � ��� ����� ���������������        *}
{* �������� ��������� ��������� ��� ������� � �������� ��� ������˨�����      *}
{* ����������. �������� ����������� ������������ �������� GNU ������ 3, ���   *}
{* ��������� �������������� ����������. �� ������ ���� �������� �����         *}
{* ����������� ������������ �������� GNU ������ � ����������. � ������ �     *}
{* ����������, ���������� http://www.gnu.org/licenses/.                       *}
{*                                                                            *}
{* http://sasgis.ru/sasplanet                                                 *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_MenuGeneratorByStaticTreeSimple;

interface

uses
  Classes,
  TB2Item,
  i_StaticTreeItem,
  i_MenuGeneratorByTree;

type
  TMenuGeneratorByStaticTreeSimple = class(TInterfacedObject, IMenuGeneratorByTree)
  private
    FOnClick: TNotifyEvent;
  protected
    procedure AddSubItems(AParent: TTBCustomItem; AItem: IStaticTreeItem); virtual;
    procedure AddItem(AParent: TTBCustomItem; AItem: IStaticTreeItem); virtual;
    procedure ClearOldItems(ARootMenu: TTBCustomItem); virtual;
    function IsFlatSubTree(AItem: IStaticTreeItem): Boolean; virtual;
  protected
    procedure BuildMenu(
      ARootMenu: TTBCustomItem;
      ATree: IStaticTreeItem
    );
  public
    constructor Create(
      AOnClick: TNotifyEvent
    );
  end;
implementation

uses
  TBX,
  TBXExtItems;

{ TMenuGeneratorByStaticTreeSimple }

constructor TMenuGeneratorByStaticTreeSimple.Create(AOnClick: TNotifyEvent);
begin
  FOnClick := AOnClick;
end;

procedure TMenuGeneratorByStaticTreeSimple.AddItem(AParent: TTBCustomItem;
  AItem: IStaticTreeItem);
var
  VItem: TTBCustomItem;
  VLabel: TTBXLabelItem;
begin
  if AItem.SubItemCount > 0 then begin
    if IsFlatSubTree(AItem) then begin
      if Length(AItem.Name) > 0 then begin
        VLabel := TTBXLabelItem.Create(AParent);
        VLabel.ShowAccelChar := False;
        VLabel.FontSettings.Bold := tsTrue;
        VItem := VLabel;
        VItem.Caption := AItem.Name;
        VItem.Tag := -1;
        AParent.Add(VItem);
        AddSubItems(AParent, AItem);
      end else begin
        AddSubItems(AParent, AItem);
        VItem := TTBSeparatorItem.Create(AParent);
        VItem.Tag := -1;
        AParent.Add(VItem);
      end;
    end else begin
      VItem := TTBXSubmenuItem.Create(AParent);
      VItem.Caption := AItem.Name;
      VItem.Tag := -1;
      AParent.Add(VItem);
      AddSubItems(VItem, AItem);
    end;
  end else begin
    if AItem.Data <> nil then begin
      VItem := TTBXItem.Create(AParent);
      VItem.Caption := AItem.Name;
      VItem.Tag := Integer(AItem.Data);
      VItem.OnClick := FOnClick;
      AParent.Add(VItem);
    end;
  end;

end;

procedure TMenuGeneratorByStaticTreeSimple.AddSubItems(AParent: TTBCustomItem;
  AItem: IStaticTreeItem);
var
  i: Integer;
begin
  for i := 0 to AItem.SubItemCount - 1 do begin
    AddItem(AParent, AItem.SubItem[i]);
  end;
end;

procedure TMenuGeneratorByStaticTreeSimple.BuildMenu(ARootMenu: TTBCustomItem;
  ATree: IStaticTreeItem);
begin
  ClearOldItems(ARootMenu);
  AddSubItems(ARootMenu, ATree);
end;

procedure TMenuGeneratorByStaticTreeSimple.ClearOldItems(ARootMenu: TTBCustomItem);
var
  i: integer;
begin
  for i := ARootMenu.Count - 1 downto 0 do begin
    if ARootMenu.Items[i].Tag <> 0 then begin
      ARootMenu.Items[i].Free;
    end;
  end;
end;

function TMenuGeneratorByStaticTreeSimple.IsFlatSubTree(
  AItem: IStaticTreeItem): Boolean;
var
  VLen: Integer;
begin
  Result := False;
  VLen := Length(AItem.GroupName);
  if VLen > 0 then begin
    Result := AItem.GroupName[VLen] = '~';
  end;
end;

end.
