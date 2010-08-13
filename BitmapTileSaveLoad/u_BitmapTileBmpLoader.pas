unit u_BitmapTileBmpLoader;

interface

uses
  Classes,
  GR32,
  i_BitmapTileSaveLoad;

type
  TBmpBitmapTileLoader = class(TInterfacedObject, IBitmapTileLoader)
  public
    procedure LoadFromFile(AFileName: string; ABtm: TCustomBitmap32);
    procedure LoadFromStream(AStream: TStream; ABtm: TCustomBitmap32);
  end;

implementation

{ TBmpBitmapTileLoader }

procedure TBmpBitmapTileLoader.LoadFromFile(AFileName: string;
  ABtm: TCustomBitmap32);
begin
  ABtm.LoadFromFile(AFileName);
end;

procedure TBmpBitmapTileLoader.LoadFromStream(AStream: TStream;
  ABtm: TCustomBitmap32);
begin
  AStream.Position := 0;
  ABtm.LoadFromStream(AStream);
end;

end.
 