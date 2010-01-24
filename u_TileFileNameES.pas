unit u_TileFileNameES;

interface

uses
  Types,
  i_ITileFileNameGenerator;

type
  TTileFileNameES = class(TInterfacedObject, ITileFileNameGenerator)
  private
    class function FullInt(i: Integer; AZoom: byte): string;
  public
    function GetTileFileName(AXY: TPoint; Azoom: byte): string;
  end;

implementation

uses
  StrUtils,
  SysUtils;

{ TTileFileNameES }

class function TTileFileNameES.FullInt(i: Integer; AZoom: byte): string;
begin
  Result := IntToStr(i);
  if AZoom < 4 then begin
  end else if AZoom < 7 then begin
    Result := RightStr('0' + Result, 2);
  end else if AZoom < 10 then begin
    Result := RightStr('00' + Result, 3);
  end else if AZoom < 14 then begin
    Result := RightStr('000' + Result, 4);
  end else if AZoom < 17 then begin
    Result := RightStr('0000' + Result, 5);
  end else if AZoom < 20 then begin
    Result := RightStr('00000' + Result, 6);
  end else begin
    Result := RightStr('000000' + Result, 7);
  end;
end;

function TTileFileNameES.GetTileFileName(AXY: TPoint;
  Azoom: byte): string;
var
  VZoomStr: string;
  VFileName: string;
begin
  inherited;
  if (Azoom >= 9) then begin
    VZoomStr := IntToStr(Azoom + 1);
  end else begin
    VZoomStr := '0' + IntToStr(Azoom + 1);
  end;
  VFileName := VZoomStr + '-' + FullInt(AXY.X, AZoom) + '-' + FullInt(AXY.Y, AZoom);
  if Azoom < 6 then begin
    Result := VZoomStr + '\';
  end else if Azoom < 10 then begin
    Result := VZoomStr + '\' +
      Chr(60 + Azoom) + FullInt(AXY.X shr 5, Azoom - 5) + FullInt(AXY.Y shr 5, Azoom - 5) + '\';
  end else begin
    Result := '10' + '-' + FullInt(AXY.X shr (AZoom - 9), 9) + '-' + FullInt(AXY.Y shr (AZoom - 9), 9) + '\' + VZoomStr + '\' + Chr(60 + Azoom) + FullInt(AXY.X shr 5, Azoom - 5) + FullInt(AXY.Y shr 5, Azoom - 5) + '\';
  end;
  Result := Result + VFileName;
end;

end.
