unit u_BitmapLayerProviderInPolygon;

interface

uses
  i_OperationNotifier,
  i_Bitmap32Static,
  i_LocalCoordConverter,
  i_VectorItemProjected,
  i_BitmapLayerProvider;

type
  TBitmapLayerProviderInPolygon = class(TInterfacedObject, IBitmapLayerProvider)
  private
    FSourceProvider: IBitmapLayerProvider;
    FPolyProjected: IProjectedPolygon;
    FLine: IProjectedPolygonLine;
  private
    function GetBitmapRect(
      AOperationID: Integer;
      ACancelNotifier: IOperationNotifier;
      ALocalConverter: ILocalCoordConverter
    ): IBitmap32Static;
  public
    constructor Create(
      APolyProjected: IProjectedPolygon;
      ASourceProvider: IBitmapLayerProvider
    );
  end;

implementation

{ TBitmapLayerProviderInPolygon }

constructor TBitmapLayerProviderInPolygon.Create(
  APolyProjected: IProjectedPolygon;
  ASourceProvider: IBitmapLayerProvider
);
begin
  FSourceProvider := ASourceProvider;
  FPolyProjected := APolyProjected;
  Assert(FSourceProvider <> nil);
  Assert(FPolyProjected <> nil);
  Assert(FPolyProjected.Count > 0);
  FLine := FPolyProjected.Item[0];
end;

function TBitmapLayerProviderInPolygon.GetBitmapRect(
  AOperationID: Integer;
  ACancelNotifier: IOperationNotifier;
  ALocalConverter: ILocalCoordConverter
): IBitmap32Static;
begin
  if FLine.IsRectIntersectPolygon(ALocalConverter.GetRectInMapPixelFloat) then begin
    Result :=
      FSourceProvider.GetBitmapRect(
        AOperationID,
        ACancelNotifier,
        ALocalConverter
      );
  end else begin
    Result := nil;
  end;
end;

end.
