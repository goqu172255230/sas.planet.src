unit u_MapsConfigInIniFileSection;

interface

uses
  IniFiles,
  i_IGUIDList,
  i_IActiveMapsConfig,
  i_ActiveMapsConfigSaveLoad;

type
  TMapsConfigInIniFileSection = class(TInterfacedObject, IActiveMapsConfigSaver, IActiveMapsConfigLoader)
  private
    FIniFile: TCustomIniFile;
    FSectionName: string;
    procedure SaveMap(AConfig: IActiveMapsConfig);
    procedure SaveHybrids(AConfig: IActiveMapsConfig);
    procedure Save(AConfig: IActiveMapsConfig);
    procedure LoadMap(AConfig: IActiveMapsConfig);
    procedure LoadHybrids(AConfig: IActiveMapsConfig);
    procedure LoadHybridGUIDs(AConfig: IActiveMapsConfig; AGUIDList: IGUIDList);
    procedure LoadHybridByList(AConfig: IActiveMapsConfig; AGUIDList: IGUIDList);
    procedure Load(AConfig: IActiveMapsConfig);
  public
    constructor Create(AIniFile: TCustomIniFile; ASectionName: string);
  end;

implementation

uses
  ActiveX,
  Classes,
  ComObj,
  StrUtils,
  SysUtils,
  UMapType,
  u_GUIDList,
  i_MapTypes;

const
  CKeyNameMap = 'Map';
  CKeyNameLayer = 'Layer';

{ TMapsConfigInIniFileSection }

constructor TMapsConfigInIniFileSection.Create(AIniFile: TCustomIniFile;
  ASectionName: string);
begin
  FIniFile := AIniFile;
  FSectionName := ASectionName;
end;

procedure TMapsConfigInIniFileSection.Load(AConfig: IActiveMapsConfig);
begin
  LoadMap(AConfig);
  LoadHybrids(AConfig);
end;

procedure TMapsConfigInIniFileSection.LoadHybridByList(
  AConfig: IActiveMapsConfig; AGUIDList: IGUIDList);
var
  VEnum: IEnumGUID;
  VGUID: TGUID;
  i: Cardinal;
begin
  VEnum := AConfig.HybrList.GetIterator;
  while VEnum.Next(1, VGUID, i) = S_OK do begin
    if AGUIDList.GetByGUID(VGUID) <> nil then begin
      AConfig.SelectHybrByGUID(VGUID);
    end else begin
      AConfig.UnSelectHybrByGUID(VGUID);
    end;
  end;
end;

procedure TMapsConfigInIniFileSection.LoadHybridGUIDs(
  AConfig: IActiveMapsConfig; AGUIDList: IGUIDList);
var
  VList: TStringList;
  i: Integer;
  VKeyName: string;
  VGUIDString: string;
  VGUID: TGUID;
  VMap: IMapType;
begin
  VList := TStringList.Create;
  try
    FIniFile.ReadSection(FSectionName, VList);
    for i := 0 to VList.Count - 1 do begin
      VKeyName := VList.Strings[i];
      if SameText(LeftStr(VKeyName, length(CKeyNameLayer)), CKeyNameLayer) then begin
        VGUIDString := FIniFile.ReadString(FSectionName, VKeyName, '');
        if VGUIDString <> '' then begin
          try
            VGUID := StringToGUID(VGUIDString);
          except
            VGUID := CGUID_Zero;
          end;
        end else begin
          VGUID := CGUID_Zero;
        end;
        if not IsEqualGUID(VGUID, CGUID_Zero) then begin
          VMap := AConfig.HybrList.GetMapTypeByGUID(VGUID);
          if VMap <> nil then begin
            AGUIDList.Add(VGUID, VMap);
          end;
        end;
      end;
    end;
  finally
    VList.Free;
  end;
end;

procedure TMapsConfigInIniFileSection.LoadHybrids(
  AConfig: IActiveMapsConfig);
var
  VGUIDList: IGUIDList;
begin
  VGUIDList := TGUIDList.Create;
  LoadHybridGUIDs(AConfig, VGUIDList);
  LoadHybridByList(AConfig, VGUIDList);
  VGUIDList := nil;
end;

procedure TMapsConfigInIniFileSection.LoadMap(AConfig: IActiveMapsConfig);
var
  VGUIDString: string;
  VGUID: TGUID;
begin
  VGUIDString := FIniFile.ReadString(FSectionName, CKeyNameMap, '');
  if VGUIDString <> '' then begin
    try
      VGUID := StringToGUID(VGUIDString);
    except
      VGUID := CGUID_Zero;
    end;
  end else begin
    VGUID := CGUID_Zero;
  end;
  AConfig.SelectMapByGUID(VGUID);
end;

procedure TMapsConfigInIniFileSection.Save(AConfig: IActiveMapsConfig);
begin
  FIniFile.EraseSection(FSectionName);
  SaveMap(AConfig);
  SaveHybrids(AConfig);
end;

procedure TMapsConfigInIniFileSection.SaveHybrids(
  AConfig: IActiveMapsConfig);
var
  VEnum: IEnumGUID;
  VGUID: TGUID;
  i: Cardinal;
  VGUIDString: string;
  VIndex: Integer;
begin
  VIndex := 0;
  VEnum := AConfig.HybrList.GetIterator;
  while VEnum.Next(1, VGUID, i) = S_OK do begin
    if AConfig.IsHybrGUIDSelected(VGUID) then begin
      VGUIDString := GUIDToString(VGUID);
      FIniFile.WriteString(FSectionName, CKeyNameLayer+IntToStr(VIndex), VGUIDString);
      Inc(VIndex);
    end;
  end;
end;

procedure TMapsConfigInIniFileSection.SaveMap(AConfig: IActiveMapsConfig);
var
  VGUIDString: string;
  VGUID: TGUID;
begin
  VGUID := AConfig.GetSelectedMapGUID;
  VGUIDString := GUIDToString(VGUID);
  FIniFile.WriteString(FSectionName, CKeyNameMap, VGUIDString);
end;

end.
