unit i_IGPSRecorder;

interface

uses
  t_GeoTypes;

type
  TGPSTrackPoint = record
    Point: TExtendedPoint;
    Speed: Extended;
  end;

  TGPSTrackPointArray = array of TGPSTrackPoint;

  IGPSRecorder = interface
    ['{E8525CFD-243B-4454-82AA-C66108A74B8F}']
    procedure AddPoint(APoint: TGPSTrackPoint);
    procedure ClearTrack;
    function IsEmpty: Boolean;
    function GetLastPoint: TExtendedPoint;
    function GetTwoLastPoints(var APointLast, APointPrev: TExtendedPoint): Boolean;
    function LastVisiblePoints: TGPSTrackPointArray;
    function GetAllPoints: TExtendedPointArray;
    function GetAllTracPoints: TGPSTrackPointArray;
  end;

implementation

end.
