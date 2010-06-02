unit u_SearchResultPresenterStuped;

interface

uses
  i_IMapViewGoto,
  i_GeoCoder,
  i_ISearchResultPresenter;

type
  TSearchResultPresenterStuped = class(TInterfacedObject, ISearchResultPresenter)
  private
    FMapGoto: IMapViewGoto;
    procedure ShowSearchResults(ASearchResult: IGeoCodeResult);
  public
    constructor Create(AMapGoto: IMapViewGoto);
    destructor Destroy; override;
  end;

implementation

uses
  ActiveX,
  Dialogs,
  SysUtils,
  UResStrings;

{ TSearchResultPresenterStuped }

constructor TSearchResultPresenterStuped.Create(AMapGoto: IMapViewGoto);
begin
  FMapGoto := AMapGoto;
end;

destructor TSearchResultPresenterStuped.Destroy;
begin
  FMapGoto := nil;
  inherited;
end;

procedure TSearchResultPresenterStuped.ShowSearchResults(
  ASearchResult: IGeoCodeResult);
var
  VEnum: IEnumUnknown;
  VPlacemark: IGeoCodePalcemark;
  i: Cardinal;
begin
  if ASearchResult.GetPlacemarksCount <= 0 then begin
    ShowMessage(SAS_STR_notfound);
  end else begin
    VEnum := ASearchResult.GetPlacemarks;
    if VEnum.Next(1, VPlacemark, @i) = S_OK then begin
      FMapGoto.GotoPos(VPlacemark.GetPoint);
      ShowMessage(SAS_STR_foundplace+' "'+VPlacemark.GetAddress+'"');
    end;
  end;
end;

end.
