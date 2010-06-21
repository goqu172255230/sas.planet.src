unit u_MapViewGotoOnFMain;

interface

uses
  t_GeoTypes,
  i_IMapViewGoto;

type
  TMapViewGotoOnFMain = class(TInterfacedObject, IMapViewGoto)
  private
    procedure GotoPos(ALonLat: TDoublePoint);
  end;

implementation

uses
  Unit1,
  u_GlobalState;

{ TMapViewGotoOnFMain }

procedure TMapViewGotoOnFMain.GotoPos(ALonLat: TDoublePoint);
var
  VPoint: TExtendedPoint;
begin
  VPoint.X := ALonLat.X;
  VPoint.Y := ALonLat.Y;
  Fmain.topos(VPoint, GState.ViewState.GetCurrentZoom, True);
end;

end.
