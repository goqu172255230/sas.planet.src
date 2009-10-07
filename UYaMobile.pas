unit UYaMobile;

interface

uses
  SysUtils,
  classes;

const
 TableOffset=10;
 Head:int64 = $000A000158444E59;//288230381927550553;

var
 TableSize:integer;
 DataOffset:integer;
 Header:array [0..7] of byte;
 tileinfo:array [0..5] of byte;

 procedure WriteTileInCache(x,y:integer;z,Mt,sm_xy:byte;cache_path:string;tile:TMemoryStream;replace:boolean);

implementation

uses
  Unit1;
  
function GetMobileFile(X,Y:integer;Z:byte;Mt:byte):string;
var Mask,num:integer;
begin
    result:=IntToStr(Z)+'\';
    if(Z>15) then
    begin
      Mask:=(1 shl (Z-15))-1;
      Num:=(((X shr 15) and Mask) shl 4)+(((Y shr 15) and Mask));
      result:=result+IntToHex(Num,2)+'\';
    end;
    if(Z>11) then
    begin
      Mask:=(1 shl (Z-11))-1;
      Mask:=Mask and $F;
      Num:=(((X shr 11) and Mask) shl 4)+(((Y shr 11) and Mask));
      result:=result+IntToHex(Num,2)+'\';
    end;
    if(Z>7) then
    begin
      Mask:=(1 shl (Z-7))-1;
      Mask:=Mask and $F;
      Num:=(((X shr 7) and Mask) shl 8)+(((Y shr 7) and Mask) shl 4)+Mt;
    end
    else Num:=Mt;
    result:=result+IntToHex(Num,3);
end;

function GetMobileFilePos(X,Y:integer;Z:byte):integer;
begin
  x:=X and $7F;
  y:=Y and $7F;
  result:=((y and $40) shl 9)+((x and $40) shl 8)+((y and $20) shl 8)+((x and $20) shl 7)
          +((y and $10) shl 7)+((x and $10) shl 6)+((y and $08) shl 6)+((x and $08) shl 5)
          +((y and $04) shl 5)+((x and $04) shl 4)+((y and $02) shl 4)+((x and $02) shl 3)
          +((y and $01) shl 3)+((x and $01) shl 2);
end;

procedure createdirif(path:string);
begin
 path:=copy(path, 1, LastDelimiter('\', path));
 if not(DirectoryExists(path)) then ForceDirectories(path);
end;

procedure CreateNilFile(path:string);
var i:integer;
    ms:TMemoryStream;
    n:array [0..TableOffset-8-1] of byte;
begin
 createdirif(path);
 ms:=TMemoryStream.Create;
 ms.Write(Head,8);
 FillChar(n,TableOffset-8,0);
 ms.Write(n,TableOffset-8);
 for i:=0 to sqr(TableSize)-1 do
  ms.Write(tileinfo,6);
 ms.SaveToFile(path);
 ms.Free;
end;

procedure WriteTileInCache(x,y:integer;z,Mt,sm_xy:byte;cache_path:string;tile:TMemoryStream;replace:boolean);
var MobileFilePath:string;
    MobileFile:TFileStream;
    TablePos:integer;
    Adr,RAdr:integer;
    Len:Smallint;
    realTableOffset:integer;
begin
 dec(Z);
 if z>7 then TableSize:=256
        else TableSize:=2 shl Z;
 DataOffset:=TableOffset+sqr(TableSize)*6;
 MobileFilePath:=cache_path+GetMobileFile(X,Y,Z,Mt);
 if not(FileExists(MobileFilePath))
  then CreateNilFile(MobileFilePath);
 MobileFile:=TFileStream.Create(MobileFilePath,fmOpenReadWrite);

 MobileFile.Read(Header,8);
 realTableOffset:=(header[6]or(header[7]shl 8));
 TablePos:=GetMobileFilePos(X,Y,Z)*6+sm_xy*6;

 Adr:=MobileFile.Size;
 Len:=tile.Size;
 MobileFile.Position:=realTableOffset+TablePos;
 MobileFile.Read(RAdr,4);
 if (RAdr=0)or(replace) then
  begin
   MobileFile.Position:=realTableOffset+TablePos;
   MobileFile.Write(Adr,4);
   MobileFile.Write(Len,2);
   MobileFile.Position:=MobileFile.Size;
   MobileFile.Write(tile.Memory^,tile.Size);
  end;
 MobileFile.Free;
end;

end.
