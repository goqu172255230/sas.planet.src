unit i_FillingMapColorer;

interface

uses
  GR32,
  i_TileInfoBasic;

type
  IFillingMapColorer = interface
    ['{7DCF5BFC-3E85-4371-91AF-B90C866BD9CB}']
    function GetColor(ATileInfo: ITileInfoBasic): TColor32;
  end;

implementation

end.
