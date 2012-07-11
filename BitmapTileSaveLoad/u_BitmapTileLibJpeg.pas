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

unit u_BitmapTileLibJpeg;

interface

uses
  Classes,
  SysUtils,
  GR32,
  i_InternalPerformanceCounter,
  i_BinaryData,
  i_Bitmap32Static,
  i_BitmapTileSaveLoad;

type
  TLibJpegTileLoader = class(TInterfacedObject, IBitmapTileLoader)
  private
    FLoadStreamCounter: IInternalPerformanceCounter;
    function ReadLine(
      Sender: TObject;
      ALine: PByte;
      ALineSize: Cardinal;
      ALineNumber: Integer
    ): Boolean;
  private
    function Load(const AData: IBinaryData): IBitmap32Static;
  public
    constructor Create(const APerfCounterList: IInternalPerformanceCounterList);
    destructor Destroy; override;
  end;

  TLibJpegTileSaver = class(TInterfacedObject, IBitmapTileSaver)
  private
    FSaveCounter: IInternalPerformanceCounter;
    FCompressionQuality: Byte;
    function WriteLine(
      Sender: TObject;
      ALineNumber: Integer;
      out Abort: Boolean
    ): PByte;
  private
    function Save(const ABitmap: IBitmap32Static): IBinaryData;
  public
    constructor Create(ACompressionQuality: Byte; const APerfCounterList: IInternalPerformanceCounterList);
    destructor Destroy; override;
  end;

implementation

uses
  LibJpegRead,
  LibJpegWrite,
  u_Bitmap32Static,
  u_StreamReadOnlyByBinaryData,
  u_BinaryDataByMemStream;

type
  TColor32Rec = packed record
    B, G, R, A: Byte;
  end;

  TWriterAppData = record
    Bitmap: TCustomBitmap32;
    Line: PByte;
  end;

{ TLibJpegTileLoader }

constructor TLibJpegTileLoader.Create(
  const APerfCounterList: IInternalPerformanceCounterList
);
begin
  inherited Create;
  FLoadStreamCounter := APerfCounterList.CreateAndAddNewCounter('LibJPEG/LoadStream');
end;

destructor TLibJpegTileLoader.Destroy;
begin
  inherited;
end;

function TLibJpegTileLoader.Load(const AData: IBinaryData): IBitmap32Static;
var
  VCounterContext: TInternalPerformanceCounterContext;
  VJpeg: TJpegReader;
  VStream: TStream;
  VBitmap: TCustomBitmap32;
begin
  Result := nil;
  VCounterContext := FLoadStreamCounter.StartOperation;
  try
    VStream := TStreamReadOnlyByBinaryData.Create(AData);
    try
      VStream.Position := 0;
      VJpeg := TJpegReader.Create(VStream);
      try
        if VJpeg.ReadHeader() then begin
          VBitmap := TCustomBitmap32.Create;
          try
            VBitmap.Width := VJpeg.Width;
            VBitmap.Height := VJpeg.Height;
            VJpeg.AppData := @VBitmap;
            if not VJpeg.Decompress(Self.ReadLine) then begin
              raise Exception.Create('Jpeg decompress error!');
            end;
            Result := TBitmap32Static.CreateWithOwn(VBitmap);
            VBitmap := nil;
          finally
            VBitmap.Free;
          end;
        end else begin
          raise Exception.Create('Jpeg open error!');
        end;
      finally
        VJpeg.Free;
      end;
    finally
      VStream.Free;
    end;
  finally
    FLoadStreamCounter.FinishOperation(VCounterContext);
  end;
end;

function TLibJpegTileLoader.ReadLine(
  Sender: TObject;
  ALine: PByte;
  ALineSize: Cardinal;
  ALineNumber: Integer
): Boolean;
var
  VJpeg: TJpegReader;
  VBtm: TCustomBitmap32;
  VColor: TColor32Rec;
  I: Integer;
begin
  VJpeg := Sender as TJpegReader;
  VBtm := TCustomBitmap32(VJpeg.AppData^);
  for I := 0 to VBtm.Width - 1 do begin
    VColor.R := ALine^;
    Inc(ALine, 1);
    VColor.G := ALine^;
    Inc(ALine, 1);
    VColor.B := ALine^;
    Inc(ALine, 1);
    VColor.A := $FF;
    VBtm.Pixel[I, ALineNumber] := TColor32(VColor);
  end;
  Result := True;
end;

{ TLibJpegTileSaver }

constructor TLibJpegTileSaver.Create(ACompressionQuality: Byte; const APerfCounterList: IInternalPerformanceCounterList);
begin
  inherited Create;
  FSaveCounter := APerfCounterList.CreateAndAddNewCounter('LibJPEG/SaveStream');
  FCompressionQuality := ACompressionQuality;
end;

destructor TLibJpegTileSaver.Destroy;
begin
  inherited Destroy;
end;

function TLibJpegTileSaver.Save(const ABitmap: IBitmap32Static): IBinaryData;
var
  VCounterContext: TInternalPerformanceCounterContext;
  VJpeg: TJpegWriter;
  VAppData: TWriterAppData;
  VMemStream: TMemoryStream;
begin
  Result := nil;
  VCounterContext := FSaveCounter.StartOperation;
  try
    VMemStream := TMemoryStream.Create;
    try
      VJpeg := TJpegWriter.Create(VMemStream);
      try
        VAppData.Bitmap := ABitmap.Bitmap;
        GetMem(VAppData.Line, VAppData.Bitmap.Width * 3);
        try
          VJpeg.Width := VAppData.Bitmap.Width;
          VJpeg.Height := VAppData.Bitmap.Height;
          VJpeg.Quality := FCompressionQuality;
          VJpeg.AppData := @VAppData;
          if not VJpeg.Compress(Self.WriteLine) then begin
            raise Exception.Create('Jpeg compression error!');
          end;
          VMemStream.Position := 0;
        finally
          FreeMem(VAppData.Line);
        end;
      finally
        VJpeg.Free;
      end;
      Result := TBinaryDataByMemStream.CreateWithOwn(VMemStream);
      VMemStream := nil;
    finally
      VMemStream.Free;
    end;
  finally
    FSaveCounter.FinishOperation(VCounterContext);
  end;
end;

function TLibJpegTileSaver.WriteLine(
  Sender: TObject;
  ALineNumber: Integer;
  out Abort: Boolean
): PByte;
var
  VJpeg: TJpegWriter;
  VAppData: TWriterAppData;
  VPixColor: TColor32Rec;
  VLine: PByte;
  I: Integer;
begin
  VJpeg := Sender as TJpegWriter;
  VAppData := TWriterAppData(VJpeg.AppData^);
  VLine := VAppData.Line;
  for I := 0 to VAppData.Bitmap.Width - 1 do begin
    VPixColor := TColor32Rec(VAppData.Bitmap.Pixel[I, ALineNumber]);
    VLine^ := VPixColor.R;
    Inc(VLine);
    VLine^ := VPixColor.G;
    Inc(VLine);
    VLine^ := VPixColor.B;
    Inc(VLine);
  end;
  Result := VAppData.Line;
  Abort := False;
end;

end.
