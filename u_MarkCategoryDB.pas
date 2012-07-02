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

unit u_MarkCategoryDB;

interface

uses
  Windows,
  Classes,
  SysUtils,
  DBClient,
  i_IDList,
  i_PathConfig,
  i_MarkCategory,
  i_MarkCategoryFactory,
  i_MarkCategoryFactoryDbInternal,
  i_MarkCategoryFactoryConfig,
  i_MarkCategoryDB,
  i_MarkCategoryDBSmlInternal,
  i_ReadWriteStateInternal,
  u_ConfigDataElementBase;

type
  TMarkCategoryDB = class(TConfigDataElementBaseEmptySaveLoad, IMarkCategoryDB, IMarkCategoryDBSmlInternal)
  private
    FBasePath: IPathConfig;
    FStateInternal: IReadWriteStateInternal;

    FStream: TStream;
    FCdsKategory: TClientDataSet;
    FList: IIDInterfaceList;
    FFactoryDbInternal: IMarkCategoryFactoryDbInternal;
    FFactory: IMarkCategoryFactory;
    function ReadCurrentCategory(out AId: Integer): IMarkCategory;
    procedure WriteCurrentCategory(const ACategory: IMarkCategory);
    function GetMarksCategoryBackUpFileName: string;
    function GetMarksCategoryFileName: string;
    procedure InitEmptyDS;
  protected
    function GetCategoryByName(const AName: string): IMarkCategory;
    function UpdateCategory(
      const AOldCategory: IMarkCategory;
      const ANewCategory: IMarkCategory
    ): IMarkCategory;

    function GetCategoriesList: IInterfaceList;
    procedure SetAllCategoriesVisible(ANewVisible: Boolean);

    function GetFactory: IMarkCategoryFactory;
  protected
    function SaveCategory2File: boolean;
    procedure LoadCategoriesFromFile;
    function GetCategoryByID(id: integer): IMarkCategory;
  public
    constructor Create(
      const AStateInternal: IReadWriteStateInternal;
      const ABasePath: IPathConfig;
      const AFactoryConfig: IMarkCategoryFactoryConfig
    );
    destructor Destroy; override;
  end;

implementation

uses
  DB,
  t_CommonTypes,
  i_EnumID,
  u_IDInterfaceList,
  i_MarksDbSmlInternal,
  u_MarkCategoryFactory;

constructor TMarkCategoryDB.Create(
  const AStateInternal: IReadWriteStateInternal;
  const ABasePath: IPathConfig;
  const AFactoryConfig: IMarkCategoryFactoryConfig
);
var
  VFactory: TMarkCategoryFactory;
begin
  inherited Create;
  FBasePath := ABasePath;
  FStateInternal := AStateInternal;
  FList := TIDInterfaceList.Create;
  VFactory := TMarkCategoryFactory.Create(AFactoryConfig);
  FFactoryDbInternal := VFactory;
  FFactory := VFactory;
  FCdsKategory := TClientDataSet.Create(nil);
  FCdsKategory.Name := 'CDSKategory';
  FCdsKategory.DisableControls;
  InitEmptyDS;
end;

destructor TMarkCategoryDB.Destroy;
begin
  FreeAndNil(FStream);
  FreeAndNil(FCdsKategory);
  FList := nil;
  FFactory := nil;
  FFactoryDbInternal := nil;
  inherited;
end;

function TMarkCategoryDB.ReadCurrentCategory(out AId: Integer): IMarkCategory;
var
  VName: string;
  VVisible: Boolean;
  VAfterScale: Integer;
  VBeforeScale: Integer;
begin
  AId := FCdsKategory.fieldbyname('id').AsInteger;
  VName := FCdsKategory.fieldbyname('name').AsString;
  VVisible := FCdsKategory.FieldByName('visible').AsBoolean;
  VAfterScale := FCdsKategory.fieldbyname('AfterScale').AsInteger;
  VBeforeScale := FCdsKategory.fieldbyname('BeforeScale').AsInteger;
  Result := FFactoryDbInternal.CreateCategory(AId, VName, VVisible, VAfterScale, VBeforeScale);
end;

procedure TMarkCategoryDB.WriteCurrentCategory(const ACategory: IMarkCategory);
begin
  FCdsKategory.fieldbyname('name').AsString := ACategory.name;
  FCdsKategory.FieldByName('visible').AsBoolean := ACategory.visible;
  FCdsKategory.fieldbyname('AfterScale').AsInteger := ACategory.AfterScale;
  FCdsKategory.fieldbyname('BeforeScale').AsInteger := ACategory.BeforeScale;
end;

function TMarkCategoryDB.UpdateCategory(
  const AOldCategory: IMarkCategory;
  const ANewCategory: IMarkCategory
): IMarkCategory;
var
  VIdOld: Integer;
  VIdNew: Integer;
  VLocated: Boolean;
  VCategoryInternal: IMarkCategorySMLInternal;
  VOldCategory: IMarkCategory;
begin
  Result := nil;
  Assert((AOldCategory <> nil) or (ANewCategory <> nil));
  VIdOld := CNotExistCategoryID;
  if Supports(AOldCategory, IMarkCategorySMLInternal, VCategoryInternal) then begin
    VIdOld := VCategoryInternal.Id;
  end;
  VIdNew := CNotExistCategoryID;
  LockWrite;
  try
    VOldCategory := nil;
    VLocated := False;
    if VIdOld >= 0 then begin
      VOldCategory := IMarkCategory(FList.GetByID(VIdOld));
      if VOldCategory <> nil then begin
        if VOldCategory.IsEqual(ANewCategory) then begin
          Result := VOldCategory;
          Exit;
        end;
      end;
      VLocated := FCdsKategory.Locate('id', VIdOld, []);
    end;
    if VLocated then begin
      if ANewCategory <> nil then begin
        FCdsKategory.Edit;
        WriteCurrentCategory(ANewCategory);
        FCdsKategory.post;
        SetChanged;
        Result := ReadCurrentCategory(VIdNew);
        Assert(Result <> nil);
        Assert(VIdNew >= 0);
        Assert(VIdNew = VIdOld);
      end else begin
        FCdsKategory.Delete;
        SetChanged;
      end;
    end else begin
      FCdsKategory.Insert;
      WriteCurrentCategory(ANewCategory);
      FCdsKategory.post;
      Result := ReadCurrentCategory(VIdNew);
      SetChanged;
      Assert(Result <> nil);
      Assert(VIdNew >= 0);
    end;
    if VIdOld >= 0 then begin
      if VIdNew >= 0 then begin
        if VIdNew <> VIdOld then begin
          FList.Remove(VIdOld);
          FList.Add(VIdNew, Result);
        end else begin
          FList.Replace(VIdOld, Result);
        end;
      end else begin
        FList.Remove(VIdOld);
      end;
    end else begin
      if VIdNew >= 0 then begin
        FList.Add(VIdNew, Result);
      end;
    end;
    SaveCategory2File;
  finally
    UnlockWrite;
  end;
end;

procedure TMarkCategoryDB.InitEmptyDS;
begin
  FCdsKategory.Close;
  FCdsKategory.XMLData :=
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<DATAPACKET Version="2.0">' +
    '<METADATA>' +
    '<FIELDS>' +
    '<FIELD attrname="id" fieldtype="i4" readonly="true" SUBTYPE="Autoinc"/>' +
    '<FIELD attrname="name" fieldtype="string" WIDTH="256"/>' +
    '<FIELD attrname="visible" fieldtype="boolean"/>' +
    '<FIELD attrname="AfterScale" fieldtype="i2"/>' +
    '<FIELD attrname="BeforeScale" fieldtype="i2"/>' +
    '</FIELDS>' +
    '<PARAMS AUTOINCVALUE="1"/>' +
    '</METADATA>' +
    '<ROWDATA></ROWDATA>' +
    '</DATAPACKET>';
  FCdsKategory.Open;
end;

function TMarkCategoryDB.GetCategoryByID(id: integer): IMarkCategory;
begin
  Result := nil;
  LockRead;
  try
    Result := IMarkCategory(FList.GetByID(id));
  finally
    UnlockRead;
  end;
end;

function TMarkCategoryDB.GetCategoryByName(const AName: string): IMarkCategory;
var
  VEnum: IEnumID;
  i: Cardinal;
  VId: Integer;
  VCategory: IMarkCategory;
begin
  Result := nil;
  LockRead;
  try
    VEnum := FList.GetIDEnum;
    while VEnum.Next(1, VId, i) = S_OK do begin
      VCategory := IMarkCategory(FList.GetByID(VId));
      if SameStr(VCategory.Name, AName) then begin
        Result := VCategory;
        Break;
      end;
    end;
  finally
    UnlockRead;
  end;
end;

function TMarkCategoryDB.GetFactory: IMarkCategoryFactory;
begin
  Result := FFactory;
end;

procedure TMarkCategoryDB.SetAllCategoriesVisible(ANewVisible: Boolean);
var
  VCategory: IMarkCategory;
  VId: Integer;
  VChanged: Boolean;
begin
  LockWrite;
  try
    VChanged := False;
    FCdsKategory.Filtered := false;
    FCdsKategory.First;
    while not (FCdsKategory.Eof) do begin
      if FCdsKategory.FieldByName('visible').AsBoolean <> ANewVisible then begin
        FCdsKategory.Edit;
        FCdsKategory.FieldByName('visible').AsBoolean := ANewVisible;
        FCdsKategory.post;
        VCategory := ReadCurrentCategory(VId);
        FList.Replace(VId, VCategory);
        VChanged := True;
      end;
      FCdsKategory.Next;
    end;
    if VChanged then begin
      SetChanged;
    end;
  finally
    UnlockWrite;
  end;
end;

function TMarkCategoryDB.GetCategoriesList: IInterfaceList;
var
  VEnum: IEnumID;
  i: Cardinal;
  VId: Integer;
  VCategory: IMarkCategory;
begin
  Result := TInterfaceList.Create;
  LockRead;
  try
    VEnum := FList.GetIDEnum;
    while VEnum.Next(1, VId, i) = S_OK do begin
      VCategory := IMarkCategory(FList.GetByID(VId));
      Result.Add(VCategory);
    end;
  finally
    UnlockRead;
  end;
end;

function TMarkCategoryDB.GetMarksCategoryBackUpFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(FBasePath.FullPath) + 'Categorymarks.~sml';
end;

function TMarkCategoryDB.GetMarksCategoryFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(FBasePath.FullPath) + 'Categorymarks.sml';
end;

procedure TMarkCategoryDB.LoadCategoriesFromFile;
var
  VFileName: string;
  VCategory: IMarkCategory;
  VId: Integer;
  XML: string;
  VStream: TFileStream;
begin
  VFileName := GetMarksCategoryFileName;
  FStateInternal.LockWrite;
  try
    LockWrite;
    try
      InitEmptyDS;
      FList.Clear;
      if FStateInternal.ReadAccess <> asDisabled then begin
        VStream := nil;
        try
          if FileExists(VFileName) then begin
            if FStateInternal.WriteAccess <> asDisabled then begin
              try
                VStream := TFileStream.Create(VFileName, fmOpenReadWrite + fmShareDenyWrite);
                FStateInternal.WriteAccess := asEnabled;
              except
                VStream := nil;
                FStateInternal.WriteAccess := asDisabled;
              end;
            end;
            if VStream = nil then begin
              try
                VStream := TFileStream.Create(VFileName, fmOpenRead + fmShareDenyNone);
                FStateInternal.ReadAccess := asEnabled;
              except
                FStateInternal.ReadAccess := asDisabled;
                VStream := nil;
              end;
            end;
            if VStream <> nil then begin
              try
                SetLength(XML, VStream.Size);
                VStream.ReadBuffer(XML[1], length(XML));
              except
                FStateInternal.ReadAccess := asDisabled;
                VStream.Free;
                VStream := nil;
              end;
            end;

            if length(XML) > 0 then begin
              try
                FCdsKategory.XMLData := XML;
              except
                InitEmptyDS;
              end;
            end;

            if FCdsKategory.RecordCount > 0 then begin
              if FStateInternal.WriteAccess = asEnabled then begin
                CopyFile(PChar(VFileName), PChar(GetMarksCategoryBackUpFileName), false);
              end;
            end;

            FCdsKategory.Filtered := false;
            FCdsKategory.First;
            while not (FCdsKategory.Eof) do begin
              VCategory := ReadCurrentCategory(VId);
              FList.Add(VId, VCategory);
              FCdsKategory.Next;
            end;
          end else begin
            if FStateInternal.WriteAccess <> asDisabled then begin
              try
                VStream := TFileStream.Create(VFileName, fmCreate);
                VStream.Free;
                VStream := nil;
              except
                FStateInternal.WriteAccess := asDisabled;
                VStream := nil;
              end;
              if FStateInternal.WriteAccess <> asDisabled then begin
                try
                  VStream := TFileStream.Create(VFileName, fmOpenReadWrite + fmShareDenyWrite);
                  FStateInternal.WriteAccess := asEnabled;
                except
                  VStream := nil;
                  FStateInternal.WriteAccess := asDisabled;
                end;
              end;
            end;
          end;
          if FStream <> nil then begin
            FreeAndNil(FStream);
          end;
          if FStateInternal.WriteAccess = asEnabled then begin
            FStream := VStream;
            VStream := nil;
          end;
        finally
          VStream.Free;
        end;
      end;
    finally
      UnlockWrite;
    end;
  finally
    FStateInternal.UnlockWrite;
  end;
end;

function TMarkCategoryDB.SaveCategory2File: boolean;
var
  XML: string;
begin
  result := true;
  try
    FStateInternal.LockRead;
    try
      if FStateInternal.WriteAccess = asEnabled then begin
        LockRead;
        try
          if FStream <> nil then begin
            FCdsKategory.MergeChangeLog;
            XML := FCdsKategory.XMLData;
            FStream.Size := length(XML);
            FStream.Position := 0;
            FStream.WriteBuffer(XML[1], length(XML));
          end;
        finally
          UnlockRead;
        end;
      end;
    finally
      FStateInternal.UnlockRead;
    end;
  except
    result := false;
  end;
end;


end.
