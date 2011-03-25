unit u_MarkCategory;

interface

uses
  i_IMarkCategory;

type
  TMarkCategory = class(TInterfacedObject, IMarkCategory)
  private
    FId: Integer;
    FName: string;
    FVisible: Boolean;
    FAfterScale: integer;
    FBeforeScale: integer;
  protected
    function GetId: integer; stdcall;
    function GetName: string; stdcall;
    function GetVisible: boolean; stdcall;
    function GetAfterScale: integer; stdcall;
    function GetBeforeScale: integer; stdcall;
  public
    constructor Create(
      AId: Integer;
      AName: string;
      AVisible: Boolean;
      AAfterScale: integer;
      ABeforeScale: integer
    ); overload;
    constructor Create(ACategory: IMarkCategory); overload;
  end;

implementation

{ TMarkCategory }

constructor TMarkCategory.Create(ACategory: IMarkCategory);
begin
  FId := ACategory.Id;
  FName := ACategory.Name;
  FVisible := ACategory.Visible;
  FAfterScale := ACategory.AfterScale;
  FBeforeScale := ACategory.BeforeScale;
end;

constructor TMarkCategory.Create(AId: Integer; AName: string; AVisible: Boolean;
  AAfterScale, ABeforeScale: integer);
begin
  FId := AId;
  FName := AName;
  FVisible := AVisible;
  FAfterScale := AAfterScale;
  FBeforeScale := ABeforeScale;
end;

function TMarkCategory.GetAfterScale: integer;
begin
  Result := FAfterScale;
end;

function TMarkCategory.GetBeforeScale: integer;
begin
  Result := FBeforeScale;
end;

function TMarkCategory.GetId: integer;
begin
  Result := FId;
end;

function TMarkCategory.GetName: string;
begin
  Result := FName;
end;

function TMarkCategory.GetVisible: boolean;
begin
  Result := FVisible;
end;

end.
