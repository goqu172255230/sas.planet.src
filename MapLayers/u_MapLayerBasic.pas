unit u_MapLayerBasic;

interface

uses
  GR32,
  GR32_Layers,
  GR32_Image,
  i_NotifierOperation,
  i_LocalCoordConverter,
  i_LocalCoordConverterChangeable,
  i_SimpleFlag,
  i_InternalPerformanceCounter,
  u_WindowLayerBasic;

type
  TMapLayerBasicNoBitmap = class(TWindowLayerAbstract)
  private
    FView: ILocalCoordConverterChangeable;
    FVisible: Boolean;
    FLayer: TCustomLayer;

    FNeedRedrawFlag: ISimpleFlag;
    FRedrawCounter: IInternalPerformanceCounter;
    FOnPaintCounter: IInternalPerformanceCounter;
    procedure OnPaintLayer(
      Sender: TObject;
      Buffer: TBitmap32
    );
    procedure OnViewChange;
    procedure RedrawIfNeed;

    function GetVisible: Boolean;
    procedure SetVisible(const Value: Boolean);
  protected
    procedure SetNeedRedraw;

    procedure Show;
    procedure DoShow; virtual;
    procedure Hide;
    procedure DoHide; virtual;

    procedure PaintLayer(
      ABuffer: TBitmap32;
      const ALocalConverter: ILocalCoordConverter
    ); virtual; abstract;

    property Visible: Boolean read GetVisible write SetVisible;
    property View: ILocalCoordConverterChangeable read FView;
  protected
    procedure StartThreads; override;
    procedure DoViewUpdate; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      const AAppStartedNotifier: INotifierOneOperation;
      const AAppClosingNotifier: INotifierOneOperation;
      AParentMap: TImage32;
      const AView: ILocalCoordConverterChangeable
    );
    destructor Destroy; override;
  end;

implementation

uses
  u_SimpleFlagWithInterlock,
  u_ListenerByEvent;

{ TMapLayerBasicNoBitmap }

constructor TMapLayerBasicNoBitmap.Create(
  const APerfList: IInternalPerformanceCounterList;
  const AAppStartedNotifier: INotifierOneOperation;
  const AAppClosingNotifier: INotifierOneOperation;
  AParentMap: TImage32;
  const AView: ILocalCoordConverterChangeable
);
begin
  inherited Create(
    APerfList,
    AAppStartedNotifier,
    AAppClosingNotifier
  );

  FView := AView;
  FLayer := TCustomLayer.Create(AParentMap.Layers);
  FRedrawCounter := PerfList.CreateAndAddNewCounter('Redraw');

  FLayer.MouseEvents := false;
  FLayer.Visible := false;
  FVisible := False;
  FNeedRedrawFlag := TSimpleFlagWithInterlock.Create;
  FOnPaintCounter := PerfList.CreateAndAddNewCounter('OnPaint');
  LinksList.Add(
    TNotifyNoMmgEventListener.Create(Self.OnViewChange),
    View.ChangeNotifier
  );
end;

destructor TMapLayerBasicNoBitmap.Destroy;
begin
  FLayer := nil;
  inherited;
end;

procedure TMapLayerBasicNoBitmap.DoViewUpdate;
begin
  inherited;
  RedrawIfNeed;
end;

procedure TMapLayerBasicNoBitmap.OnPaintLayer(
  Sender: TObject;
  Buffer: TBitmap32
);
var
  VLocalConverter: ILocalCoordConverter;
  VCounterContext: TInternalPerformanceCounterContext;
begin
  VLocalConverter := View.GetStatic;
  if VLocalConverter <> nil then begin
    VCounterContext := FOnPaintCounter.StartOperation;
    try
      PaintLayer(Buffer, VLocalConverter);
    finally
      FOnPaintCounter.FinishOperation(VCounterContext);
    end;
  end;
end;

procedure TMapLayerBasicNoBitmap.OnViewChange;
begin
  SetNeedRedraw;
end;

procedure TMapLayerBasicNoBitmap.StartThreads;
begin
  inherited;
  FLayer.OnPaint := OnPaintLayer;
end;

procedure TMapLayerBasicNoBitmap.Hide;
begin
  ViewUpdateLock;
  try
    if FVisible then begin
      DoHide;
    end;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TMapLayerBasicNoBitmap.DoHide;
begin
  FVisible := False;
  FLayer.Visible := False;
  SetNeedRedraw;
end;

procedure TMapLayerBasicNoBitmap.Show;
begin
  ViewUpdateLock;
  try
    if not Visible then begin
      DoShow;
    end;
  finally
    ViewUpdateUnlock;
  end;
end;

procedure TMapLayerBasicNoBitmap.DoShow;
begin
  FVisible := True;
  FLayer.Visible := True;
  SetNeedRedraw;
end;

function TMapLayerBasicNoBitmap.GetVisible: Boolean;
begin
  Result := FVisible;
end;

procedure TMapLayerBasicNoBitmap.RedrawIfNeed;
var
  VCounterContext: TInternalPerformanceCounterContext;
begin
  if FNeedRedrawFlag.CheckFlagAndReset then begin
    if FVisible then begin
      FNeedRedrawFlag.CheckFlagAndReset;
      VCounterContext := FRedrawCounter.StartOperation;
      try
        FLayer.Changed;
      finally
        FRedrawCounter.FinishOperation(VCounterContext);
      end;
    end;
  end;
end;

procedure TMapLayerBasicNoBitmap.SetNeedRedraw;
begin
  FNeedRedrawFlag.SetFlag;
end;

procedure TMapLayerBasicNoBitmap.SetVisible(const Value: Boolean);
begin
  if Value then begin
    Show;
  end else begin
    Hide;
  end;
end;

end.
