unit u_TileRectUpdateNotifier;

interface

uses
  Types,
  SysUtils,
  i_JclNotify,
  i_TileKey,
  i_CoordConverter,
  i_TileRectUpdateNotifier;

type
  TListenerRecord = record
    Listener: IJclListener;
    Rect: TRect;
  end;

  TTileRectUpdateNotifier = class(TInterfacedObject, ITileRectUpdateNotifier, ITileRectUpdateNotifierInternal)
  private
    FGeoCoder: ICoordConverter;
    FZoom: Byte;
    FSynchronizer: TMultiReadExclusiveWriteSynchronizer;
    FCount: Integer;
    FList: array of TListenerRecord;
    function CalcGrowSize(AOldSize: Integer): Integer;
  protected
    function GetGeoCoder: ICoordConverter; stdcall;
    function GetZoom: Byte; stdcall;

    procedure Add(const AListener: IJclListener; const ATileRect: TRect); stdcall;
    procedure Remove(const AListener: IJclListener); stdcall;

    procedure TileUpdateNotify(const ATileKey: ITileKey); stdcall;
  public
    constructor Create(
      AZoom: Byte;
      const AGeoCoder: ICoordConverter
    );
    destructor Destroy; override;
  end;

implementation

{ TTileRectUpdateNotifier }

constructor TTileRectUpdateNotifier.Create(
  AZoom: Byte;
  const AGeoCoder: ICoordConverter
);
begin
  FZoom := AZoom;
  FGeoCoder := AGeoCoder;
  FSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TTileRectUpdateNotifier.Destroy;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do begin
    FList[i].Listener := nil;
  end;
  FList := nil;
  FGeoCoder := nil;
  FreeAndNil(FSynchronizer);
  inherited;
end;

function TTileRectUpdateNotifier.CalcGrowSize(AOldSize: Integer): Integer;
begin
  if AOldSize < 8 then begin
    Result := 8;
  end else begin
    Result := AOldSize * 2;
  end;
end;

procedure TTileRectUpdateNotifier.Add(
  const AListener: IJclListener;
  const ATileRect: TRect
);
var
  i: Integer;
  VIndex: Integer;
begin
  Assert(AListener <> nil);
  FSynchronizer.BeginWrite;
  try
    VIndex := -1;
    for i := 0 to FCount - 1 do begin
      if FList[i].Listener = AListener then begin
        VIndex := i;
        Break;
      end;
    end;
    if VIndex < 0 then begin
      if FCount >= Length(FList) then begin
        SetLength(FList, CalcGrowSize(Length(FList)));
      end;
      VIndex := FCount;
      Inc(FCount);
    end;
    FList[VIndex].Listener := AListener;
    FList[VIndex].Rect := ATileRect;
  finally
    FSynchronizer.EndWrite;
  end;
end;

function TTileRectUpdateNotifier.GetGeoCoder: ICoordConverter;
begin
  Result := FGeoCoder;
end;

function TTileRectUpdateNotifier.GetZoom: Byte;
begin
  Result := FZoom;
end;

procedure TTileRectUpdateNotifier.Remove(
  const AListener: IJclListener
);
var
  i: Integer;
  VIndex: Integer;
begin
  Assert(AListener <> nil);
  FSynchronizer.BeginWrite;
  try
    VIndex := -1;
    for i := 0 to FCount - 1 do begin
      if FList[i].Listener = AListener then begin
        VIndex := i;
        Break;
      end;
    end;
    if VIndex >= 0 then begin
      FList[VIndex].Listener := nil;
      Dec(FCount);
      if VIndex < FCount then begin
        System.Move(
          FList[VIndex + 1],
          FList[VIndex],
          (FCount - VIndex) * SizeOf(TListenerRecord)
        );
        Pointer(FList[FCount].Listener) := nil;
      end;
    end;
  finally
    FSynchronizer.EndWrite;
  end;
end;

procedure TTileRectUpdateNotifier.TileUpdateNotify(const ATileKey: ITileKey);
var
  i: Integer;
  VTile: TPoint;
begin
  FSynchronizer.BeginRead;
  try
    VTile := ATileKey.Tile;
    for i := 0 to FCount - 1 do begin
      if PtInRect(FList[i].Rect, VTile) then begin
        FList[i].Listener.Notification(ATileKey);
      end;
    end;
  finally
    FSynchronizer.EndRead;
  end;
end;

end.
