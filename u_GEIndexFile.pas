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

unit u_GEIndexFile;

interface

(*
uses
  Types,
  SysUtils,
  Classes,
  i_MapVersionInfo,
  i_StorageStateInternal,
  u_MapTypeCacheConfig;
*)

(*
type
  TServerRec = record        // ������ � �������
    LastAuth : LongWord;     // ����� ��������� ����������� �� �������
    Unk      : Word;         // ������ = $0000
    Name     : Char;         // url ������� (������ � Punycode)
  end;
*)

  {
  TAuthRec = packed record       // ������ � �����������
    Magic    : LongWord;         // ������������� = $C39AC6B0
    ANumber  : LongWord;         // ����� ������ ������ �����������
    Unk      : LongWord;         // ������ = $00001000
    ATime    : LongWord;         // ����� ������ �����������
  end;

  TCache_Head = record             // ���������
    Magic  : LongWord;             // ������������� = $D5E1C1CA
    MaxSz  : LongWord;             // ������������ ������ ����� ����
    ACount : LongWord;             // ����� ������� �����������
    SCount : LongWord;             // ����� ������� ��������
    Server : array of TServerRec;  // ������ ��������
    Auth   : array of TAuthRec;    // ������ �����������
  end;
  }

(*
  TCache_Head = record             // ���������
    Magic  : LongWord;             // ������������� = $D5E1C1CA
    MaxSz  : LongWord;             // ������������ ������ ����� ����
    ACount : LongWord;             // ����� ������� �����������
    SCount : LongWord;             // ����� ������� ��������
  end;

  TTileRec = packed record // �������� �����, ������ ��������� 36 ����
    Magic   : LongWord;    // ������������� = $853662F7
    RecSz   : LongWord;    // ������ ������ p����� �����: �������� + ���� + nil
    Ver     : Word;        // ������ �����
    TileID  : Byte;        // ��� �����
    RX01    : Byte;        // �������. ������ ��� �����. ������: 1-� ����� ����
    Zoom    : Byte;        // ���
    Unk1    : Byte;        // ? �� �������. ��� $20 - ��� �����. ������ (? 0 ��� ������������� ������)
    Layer   : Word;        // ����� ���� ��� 2-� ����� ���� ��� �����. ������
    NameLo  : LongWord;    // ������ ����� �����
    NameHi  : LongWord;    // ������ ����� �����
    Server  : Word;        // ����� ������� �� ��������� ���� (������ ����)
    Unk2    : Word;        // ? ������� ���� ������� �� �� (� Win - ����, � Linux - ���)
    Size    : LongWord;    // ������ �����
    CRC     : LongWord;    // ����������� ����� �����
  end;
  PTileRec = ^TTileRec;

  TIndexRec = packed record
    Magic  : LongWord;  // �����-������������� =  D5 BF 93 75
    Ver    : Word;      // ������ �����
    TileID : Byte;      // ��� �����
    RX01   : Byte;      // ? �������. ������ ��� �����. ������: 1-� ����� ����
    Zoom   : Byte;      // ������� ����
    Res2   : Byte;      // ?
    Layer  : Word;      // ����� ���� (������ ��� ����, ����� = 0) ? ��� 2-� ����� ���� ��� �����. ������
    NameLo : LongWord;  // ������ ����� �����
    NameHi : LongWord;  // ������ ����� �����
    ServID : Word;      // ����� ������� �� ������ � dbCache.dat
    Unk    : Word;      // ? ������� ���� ������� �� �� (� Win - ����, � Linux - ���)
    Offset : LongWord;  // ������� ����� � ���� dbCache.dat
    Size   : LongWord;  // ������ �����
  end;
*)

(*
  TGenericTileInfo = packed record
    Ver    : Word;
    ServID : Word;
    Offset : LongWord;
    Size   : LongWord;
    Layer  : Word;
    RX01   : Byte;
  end;
  PGenericTileInfo = ^TGenericTileInfo;
*)

(*
  TGEIndexFile = class
  private
    FSync: TMultiReadExclusiveWriteSynchronizer;
    FCacheConfig: TMapTypeCacheConfigGE;
    FStorageStateInternal: IStorageStateInternal;
    FIndexFileName: string;
    FIndexInfo: array of TIndexRec;
    //FConfigChangeListener: IJclListener;
    FFileInited: Boolean;
    procedure GEXYZtoHexTileName(APoint: TPoint; AZoom: Byte; out ANameHi, ANameLo: LongWord);
    procedure _UpdateIndexInfo;
    procedure CopyToGeneric(const AIndexRec: TIndexRec; var AGeneric: TGenericTileInfo);
  public
    constructor Create(
      AStorageStateInternal: IStorageStateInternal;
      ACacheConfig: TMapTypeCacheConfigGE
    );
    destructor Destroy; override;

    // obtain info about single tile
    function FindTileInfo(
      const APoint: TPoint;
      const AZoom: Byte;
      const ACheckServerID: Boolean;
      const AServerID: Word;
      const AAskVer: Word;
      const AAskTileDate: String;
      var ARec: TGenericTileInfo;
      AListOfOffsets: TList
    ): Boolean;

    // get single index item
    function GetIndexRecByIndex(i: Integer; var ARec: TGenericTileInfo): Boolean;

    procedure OnConfigChange;
  end;
*)

(*
function MakeGEDateToStr(const ARX01: Byte; const ALayer: Word): String;
function TileDateToHexDate(const ATileDate: String): String;
*)

implementation

(*
uses
  t_CommonTypes;
*)

(*
function MakeGEDateToStr(const ARX01: Byte; const ALayer: Word): String;
var
  VYear, VMonth, VDay: Word;
  VTileDate: TDateTime;
begin
  Result := '';
  try
    VDay := ARX01 div 8;
    VMonth := (ALayer and $F);
    VYear := (ALayer shr 4);
    if TryEncodeDate(VYear, VMonth, VDay, VTileDate) then
      Result := FormatDateTime('yyyy:mm:dd', VTileDate);
  except
  end;
end;

function TileDateToHexDate(const ATileDate: String): String;
var
  y,m,d: Integer;
begin
  // or yyyymmdd
  Result := '';
  // yyyy:mm:dd
  if (10=Length(ATileDate)) then begin
    if TryStrToInt(System.Copy(ATileDate,1,4), y) then
    if TryStrToInt(System.Copy(ATileDate,6,2), m) then
    if TryStrToInt(System.Copy(ATileDate,9,2), d) then begin
      Result := IntToHex((y*512) + (m*32) + d, 5); // like 'fb29a'
    end;
  end;
end;
*)

{ TGEIndexFile }

(*
procedure TGEIndexFile.CopyToGeneric(const AIndexRec: TIndexRec; var AGeneric: TGenericTileInfo);
begin
  AGeneric.Ver := AIndexRec.Ver;
  AGeneric.ServID := AIndexRec.ServID;
  AGeneric.Offset := AIndexRec.Offset;
  AGeneric.Size := AIndexRec.Size;
  AGeneric.Layer := AIndexRec.Layer;
  AGeneric.RX01 := AIndexRec.RX01;
end;

constructor TGEIndexFile.Create(
  AStorageStateInternal: IStorageStateInternal;
  ACacheConfig: TMapTypeCacheConfigGE
);
begin
  FSync := TMultiReadExclusiveWriteSynchronizer.Create;
  FCacheConfig := ACacheConfig;
  FStorageStateInternal := AStorageStateInternal;
  FFileInited := False;
  //FConfigChangeListener := TNotifyNoMmgEventListener.Create(Self.OnConfigChange);
  //FCacheConfig.ConfigChangeNotifier.Add(FConfigChangeListener);
end;

destructor TGEIndexFile.Destroy;
begin
  //FCacheConfig.ConfigChangeNotifier.Remove(FConfigChangeListener);
  //FConfigChangeListener := nil;
  FreeAndNil(FSync);
  FIndexInfo := nil;
  inherited;
end;

procedure TGEIndexFile.GEXYZtoHexTileName(APoint: TPoint; AZoom: Byte; out ANameHi, ANameLo: LongWord);
var
  VMask: Integer;
  i: byte;
  VValue: Byte;
begin
  ANameHi := 0;
  ANameLo := 0;
  if AZoom > 0 then begin
    VMask := 1 shl (AZoom - 1);
    for i := 1 to AZoom do begin
      if (APoint.X and VMask) > 0 then begin
        if (APoint.y and VMask) > 0 then begin
          VValue := 1;
        end else begin
          VValue := 2;
        end;
      end else begin
        if (APoint.y and VMask) > 0 then begin
          VValue := 0;
        end else begin
          VValue := 3;
        end;
      end;
      if i <= 16 then begin
        ANameLo := ANameLo or (LongWord(VValue) shl (32 - i * 2));
      end else begin
        ANameHi := ANameHi or (LongWord(VValue) shl (32 - (i - 16) * 2));
      end;
      VMask := VMask shr 1;
    end;
  end;
end;

function TGEIndexFile.FindTileInfo(
  const APoint: TPoint;
  const AZoom: Byte;
  const ACheckServerID: Boolean;
  const AServerID: Word;
  const AAskVer: Word;
  const AAskTileDate: String;
  var ARec: TGenericTileInfo;
  AListOfOffsets: TList
): Boolean;
var
  VNameLo: LongWord;
  VNameHi: LongWord;
  i: Integer;
  VProcessed: Boolean;

  function _FilterOK(const ARX01: Byte;
                     const ALayer: Word;
                     const AVer: Word): Boolean;
  var VCurTileDate: String;
  begin
    Result:=((0=AAskVer) or (AAskVer=AVer));

    if (not Result) then
      Exit;

    // if no TileDate filter - check version
    if (0=Length(AAskTileDate)) then
      Exit;

    VCurTileDate := MakeGEDateToStr(FIndexInfo[i].RX01, FIndexInfo[i].Layer);
    if (0=Length(VCurTileDate)) then
      Exit;

    // if tile info with date information
    Result := SameText(AAskTileDate, VCurTileDate);
  end;
begin
  Result := False;

  VProcessed := False;
  while not VProcessed do begin
    if not FFileInited then begin
      FSync.BeginWrite;
      try
        if not FFileInited then begin
          _UpdateIndexInfo;
        end;
      finally
        FSync.EndWrite;
      end;
    end;
    FSync.BeginRead;
    try
      if FFileInited then begin
        if Length(FIndexInfo) > 0 then begin
          GEXYZtoHexTileName(APoint, AZoom, VNameHi, VNameLo);
          for i := Length(FIndexInfo) - 1 downto 0 do begin
            if FIndexInfo[i].Magic = $7593BFD5 then begin
              if FIndexInfo[i].TileID = 130 then begin
                if (not ACheckServerID) or (AServerID = FIndexInfo[i].ServID) then begin
                  if FIndexInfo[i].Zoom = AZoom then begin
                    if (FIndexInfo[i].NameLo = VNameLo) and (FIndexInfo[i].NameHi = VNameHi) then begin
                      // found
                      if (not Result) and
                         _FilterOK(FIndexInfo[i].RX01, FIndexInfo[i].Layer, FIndexInfo[i].Ver) then begin
                        // second entrance will fail because of Result
                        CopyToGeneric(FIndexInfo[i], ARec);
                        Result := True;
                      end;
                      // collecting offsets for complete list of tiles
                      if (AListOfOffsets <> nil) then begin
                        AListOfOffsets.Add(Pointer(i));
                      end else begin
                        if Result then begin
                          Break;
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
        VProcessed := True;
      end;
    finally
      FSync.EndRead;
    end;
  end;
end;

function TGEIndexFile.GetIndexRecByIndex(i: Integer; var ARec: TGenericTileInfo): Boolean;
begin
  Result := FALSE;
  if FFileInited then
  if Length(FIndexInfo) > 0 then
  if (i >= 0) then
  if (i < Length(FIndexInfo)) then begin
    Move(FIndexInfo[i], ARec, sizeof(ARec));
    Inc(Result);
  end;
end;

procedure TGEIndexFile.OnConfigChange;
begin
  FSync.BeginWrite;
  try
    FFileInited := False;
  finally
    FSync.EndWrite;
  end;
end;

procedure TGEIndexFile._UpdateIndexInfo;
var
  VFileName: string;
  VFileStream: TFileStream;
  VCount: Cardinal;
begin
  VFileName := FCacheConfig.GetNameInCache + 'dbCache.dat.index';
  if VFileName <> FIndexFileName then begin
    FIndexInfo := nil;
    FIndexFileName := VFileName;
    if FileExists(VFileName) then begin
      VFileStream := TFileStream.Create(VFileName, fmOpenRead);
      try
        VCount := VFileStream.Size div SizeOf(FIndexInfo[0]);
        SetLength(FIndexInfo, VCount );
        VFileStream.ReadBuffer(FIndexInfo[0], VCount * SizeOf(FIndexInfo[0]));
        FStorageStateInternal.ReadAccess := asEnabled;
      finally
        FreeAndNil(VFileStream);
      end;
    end else begin
      FStorageStateInternal.ReadAccess := asDisabled;
    end;
  end;
  FFileInited := True;
end;

*)

end.
