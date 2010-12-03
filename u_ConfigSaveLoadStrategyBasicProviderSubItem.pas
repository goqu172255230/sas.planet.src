unit u_ConfigSaveLoadStrategyBasicProviderSubItem;

uses
  i_IConfigDataProvider,
  i_IConfigDataWriteProvider,
  i_IConfigDataElement,
  i_IConfigSaveLoadStrategy;

type
  TConfigSaveLoadStrategyBasicProviderSubItem = class(TInterfacedObject, IConfigSaveLoadStrategy)
  private
    FSubItemName: string;
  protected
    procedure WriteConfig(
      AProvider: IConfigDataWriteProvider;
      AElement: IConfigDataElement
    );
    procedure ReadConfig(
      AProvider: IConfigDataProvider;
      AElement: IConfigDataElement
    );
  public
    constructor Create(ASubItemName: string);
  end;

interface

implementation

{ TConfigSaveLoadStrategyBasicProviderSubItem }

constructor TConfigSaveLoadStrategyBasicProviderSubItem.Create(
  ASubItemName: string);
begin
  FSubItemName := ASubItemName;
end;

procedure TConfigSaveLoadStrategyBasicProviderSubItem.ReadConfig(
  AProvider: IConfigDataProvider; AElement: IConfigDataElement);
var
  VProvider: IConfigDataProvider;
begin
  if AProvider = nil then begin
    VProvider := nil;
  end else begin
    VProvider := AProvider.GetSubItem(FSubItemName);
  end;
  AElement.ReadConfig(VProvider);
end;

procedure TConfigSaveLoadStrategyBasicProviderSubItem.WriteConfig(
  AProvider: IConfigDataWriteProvider; AElement: IConfigDataElement);
var
  VProvider: IConfigDataWriteProvider;
begin
  if AProvider = nil then begin
    VProvider := nil;
  end else begin
    VProvider := AProvider.GetOrCreateSubItem(FSubItemName);
  end;
  AElement.WriteConfig(VProvider);
end;

end.
