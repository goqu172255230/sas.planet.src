unit i_MainFormConfig;

interface

uses
  i_IConfigDataElement,
  i_INavigationToPoint,
  i_IStatBarConfig,
  i_IMapLayerGPSMarkerConfig,
  i_IMapLayerGPSTrackConfig,
  i_IMapLayerNavToPointMarkerConfig,
  i_IMainFormBehaviourByGPSConfig,
  i_MapLayerGridsConfig;

type
  IMainFormMainConfig = interface(IConfigDataElement)
    ['{5388E4B8-801A-445F-BF07-DE520A5AFA06}']
    // ����������� ����� ��������� �������� ��� �������� ����
    function GetZoomingAtMousePos: Boolean;
    procedure SetZoomingAtMousePos(AValue: Boolean);
    property ZoomingAtMousePos: Boolean read GetZoomingAtMousePos write SetZoomingAtMousePos;

    function GetShowMapName: Boolean;
    procedure SetShowMapName(AValue: Boolean);
    property ShowMapName: Boolean read GetShowMapName write SetShowMapName;
  end;

  IMainWindowToolbarsLock = interface(IConfigDataElement)
    ['{CA2386E9-10BE-4A7C-AE42-3E771BD390BA}']
    function GetIsLock: Boolean;
    procedure SetLock(AValue: Boolean);
  end;

  IMainFormLayersConfig = interface(IConfigDataElement)
    ['{02A323E8-25E4-43E5-BE24-AABDF9B331EC}']
    function GetMapLayerGridsConfig: IMapLayerGridsConfig;
    property MapLayerGridsConfig: IMapLayerGridsConfig read GetMapLayerGridsConfig;

    function GetStatBar: IStatBarConfig;
    property StatBar: IStatBarConfig read GetStatBar;

    function GetGPSMarker: IMapLayerGPSMarkerConfig;
    property GPSMarker: IMapLayerGPSMarkerConfig read GetGPSMarker;

    function GetGPSTrackConfig: IMapLayerGPSTrackConfig;
    property GPSTrackConfig: IMapLayerGPSTrackConfig read GetGPSTrackConfig;

    function GetNavToPointMarkerConfig: IMapLayerNavToPointMarkerConfig;
    property NavToPointMarkerConfig: IMapLayerNavToPointMarkerConfig read GetNavToPointMarkerConfig;
  end;

  IMainFormConfig = interface(IConfigDataElement)
    ['{87184149-7B22-4184-A0BF-703C0C89B3AB}']
    function GetMainConfig: IMainFormMainConfig;
    property MainConfig: IMainFormMainConfig read GetMainConfig;

    function GetLayersConfig: IMainFormLayersConfig;
    property LayersConfig: IMainFormLayersConfig read GetLayersConfig;

    function GetToolbarsLock: IMainWindowToolbarsLock;
    property ToolbarsLock: IMainWindowToolbarsLock read GetToolbarsLock;

    function GetNavToPoint: INavigationToPoint;
    property NavToPoint: INavigationToPoint read GetNavToPoint;

    function GetGPSBehaviour: IMainFormBehaviourByGPSConfig;
    property GPSBehaviour: IMainFormBehaviourByGPSConfig read GetGPSBehaviour;
  end;

implementation

end.
