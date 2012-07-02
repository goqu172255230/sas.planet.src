unit u_MapLayerBasic;

interface

uses
  GR32,
  GR32_Layers,
  GR32_Image,
  t_GeoTypes,
  i_LocalCoordConverter,
  i_LocalCoordConverterFactorySimpe,
  i_ViewPortState,
  i_SimpleFlag,
  i_ImageResamplerConfig,
  i_InternalPerformanceCounter,
  u_WindowLayerWithPos;

type
  TMapLayerBase = class(TWindowLayerBasic)
  protected
    procedure SetLayerCoordConverter(
      const AValue: ILocalCoordConverter
    ); override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      ALayer: TCustomLayer;
      const AViewPortState: IViewPortState
    );
  end;

  TMapLayerBasicFullView = class(TMapLayerBase)
  private
    FLayer: TPositionedLayer;

    FNeedUpdateLocationFlag: ISimpleFlag;
  protected
    function GetMapLayerLocationRect(const ANewVisualCoordConverter: ILocalCoordConverter): TFloatRect; virtual;
    procedure UpdateLayerLocationIfNeed; virtual;
    procedure UpdateLayerLocation; virtual;
    procedure DoUpdateLayerLocation(const ANewLocation: TFloatRect); virtual;
  protected
    procedure SetViewCoordConverter(const AValue: ILocalCoordConverter); override;
    procedure SetNeedRedraw; override;
    procedure SetNeedUpdateLocation;
    procedure DoViewUpdate; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      ALayer: TPositionedLayer;
      const AViewPortState: IViewPortState
    );
  end;

  TMapLayerBasicNoBitmap = class(TMapLayerBase)
  private
    FOnPaintCounter: IInternalPerformanceCounter;
    procedure OnPaintLayer(
      Sender: TObject;
      Buffer: TBitmap32
    );
  protected
    procedure PaintLayer(
      ABuffer: TBitmap32;
      const ALocalConverter: ILocalCoordConverter
    ); virtual; abstract;
  protected
    procedure DoRedraw; override;
    procedure SetViewCoordConverter(const AValue: ILocalCoordConverter); override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      AParentMap: TImage32;
      const AViewPortState: IViewPortState
    );
    procedure StartThreads; override;
  end;

  TMapLayerBasic = class(TMapLayerBasicFullView)
  private
    FLayer: TBitmapLayer;
    FNeedUpdateLayerSizeFlag: ISimpleFlag;
    FConverterFactory: ILocalCoordConverterFactorySimpe;
  protected
    procedure SetNeedUpdateLayerSize; virtual;
    procedure UpdateLayerSize; virtual;
    procedure UpdateLayerSizeIfNeed; virtual;

    procedure ClearLayerBitmap; virtual;
    procedure DoUpdateLayerSize(const ANewSize: TPoint); virtual;
    function GetLayerSizeForView(
      const ANewVisualCoordConverter: ILocalCoordConverter
    ): TPoint; virtual;
    property Layer: TBitmapLayer read FLayer;
    property ConverterFactory: ILocalCoordConverterFactorySimpe read FConverterFactory;
  protected
    function GetMapLayerLocationRect(const ANewVisualCoordConverter: ILocalCoordConverter): TFloatRect; override;
    procedure DoViewUpdate; override;
    procedure SetLayerCoordConverter(const AValue: ILocalCoordConverter); override;
    function GetLayerCoordConverterByViewConverter(
      const ANewViewCoordConverter: ILocalCoordConverter
    ): ILocalCoordConverter; override;
    procedure DoShow; override;
    procedure DoHide; override;
    procedure DoRedraw; override;
  public
    constructor Create(
      const APerfList: IInternalPerformanceCounterList;
      AParentMap: TImage32;
      const AViewPortState: IViewPortState;
      const AResamplerConfig: IImageResamplerConfig;
      const ACoordConverterFactory: ILocalCoordConverterFactorySimpe
    );
  end;

implementation

uses
  Types,
  u_SimpleFlagWithInterlock;

{ TMapLayerBase }

constructor TMapLayerBase.Create(
  const APerfList: IInternalPerformanceCounterList;
  ALayer: TCustomLayer;
  const AViewPortState: IViewPortState
);
begin
  inherited Create(APerfList, ALayer, AViewPortState, True);
end;

procedure TMapLayerBase.SetLayerCoordConverter(const AValue: ILocalCoordConverter);
begin
  if (LayerCoordConverter = nil) or (not LayerCoordConverter.GetIsSameConverter(AValue)) then begin
    SetNeedRedraw;
  end;
  inherited;
end;

{ TMapLayerBasicFullView }

constructor TMapLayerBasicFullView.Create(
  const APerfList: IInternalPerformanceCounterList;
  ALayer: TPositionedLayer;
  const AViewPortState: IViewPortState
);
begin
  inherited Create(APerfList, ALayer, AViewPortState);
  FLayer := ALayer;
  FNeedUpdateLocationFlag := TSimpleFlagWithInterlock.Create;
end;

procedure TMapLayerBasicFullView.DoUpdateLayerLocation(
  const ANewLocation: TFloatRect
);
begin
  FLayer.Location := ANewLocation;
end;

procedure TMapLayerBasicFullView.DoViewUpdate;
begin
  inherited;
  UpdateLayerLocationIfNeed;
end;

function TMapLayerBasicFullView.GetMapLayerLocationRect(const ANewVisualCoordConverter: ILocalCoordConverter): TFloatRect;
begin
  if ANewVisualCoordConverter <> nil then begin
    Result := FloatRect(ANewVisualCoordConverter.GetLocalRect);
  end else begin
    Result := FloatRect(0, 0, 0, 0);
  end;
end;

procedure TMapLayerBasicFullView.SetNeedRedraw;
begin
  inherited;
  SetNeedUpdateLocation;
end;

procedure TMapLayerBasicFullView.SetNeedUpdateLocation;
begin
  FNeedUpdateLocationFlag.SetFlag;
end;

procedure TMapLayerBasicFullView.SetViewCoordConverter(
  const AValue: ILocalCoordConverter
);
var
  VLocalConverter: ILocalCoordConverter;
begin
  VLocalConverter := ViewCoordConverter;
  if (VLocalConverter = nil) or (not VLocalConverter.GetIsSameConverter(AValue)) then begin
    SetNeedUpdateLocation;
  end;
  inherited;
end;

procedure TMapLayerBasicFullView.UpdateLayerLocation;
begin
  if Visible then begin
    FNeedUpdateLocationFlag.CheckFlagAndReset;
    DoUpdateLayerLocation(GetMapLayerLocationRect(ViewCoordConverter));
  end;
end;

procedure TMapLayerBasicFullView.UpdateLayerLocationIfNeed;
begin
  if FNeedUpdateLocationFlag.CheckFlagAndReset then begin
    UpdateLayerLocation;
  end;
end;

{ TMapLayerBasic }

procedure TMapLayerBasic.ClearLayerBitmap;
begin
  if Visible then begin
    Layer.Bitmap.Lock;
    try
      Layer.Bitmap.Clear(0);
    finally
      Layer.Bitmap.UnLock;
    end;
  end;
end;

constructor TMapLayerBasic.Create(
  const APerfList: IInternalPerformanceCounterList;
  AParentMap: TImage32;
  const AViewPortState: IViewPortState;
  const AResamplerConfig: IImageResamplerConfig;
  const ACoordConverterFactory: ILocalCoordConverterFactorySimpe
);
begin
  FConverterFactory := ACoordConverterFactory;
  FLayer := TBitmapLayer.Create(AParentMap.Layers);
  inherited Create(APerfList, FLayer, AViewPortState);
  FLayer.Bitmap.DrawMode := dmBlend;
  FNeedUpdateLayerSizeFlag := TSimpleFlagWithInterlock.Create;
end;

procedure TMapLayerBasic.DoViewUpdate;
begin
  UpdateLayerSizeIfNeed;
  inherited;
end;

function TMapLayerBasic.GetMapLayerLocationRect(const ANewVisualCoordConverter: ILocalCoordConverter): TFloatRect;
var
  VBitmapOnMapRect: TDoubleRect;
  VBitmapOnVisualRect: TDoubleRect;
  VBitmapConverter: ILocalCoordConverter;
begin
  VBitmapConverter := LayerCoordConverter;
  if (VBitmapConverter <> nil) and (ANewVisualCoordConverter <> nil) then begin
    VBitmapOnMapRect := VBitmapConverter.GetRectInMapPixelFloat;
    VBitmapOnVisualRect := ANewVisualCoordConverter.MapRectFloat2LocalRectFloat(VBitmapOnMapRect);
    Result := FloatRect(VBitmapOnVisualRect.Left, VBitmapOnVisualRect.Top, VBitmapOnVisualRect.Right, VBitmapOnVisualRect.Bottom);
  end else begin
    Result := FloatRect(0, 0, 0, 0);
  end;
end;

procedure TMapLayerBasic.SetLayerCoordConverter(const AValue: ILocalCoordConverter);
var
  VNewSize: TPoint;
begin
  VNewSize := GetLayerSizeForView(AValue);
  Layer.Bitmap.Lock;
  try
    if (Layer.Bitmap.Width <> VNewSize.X) or (Layer.Bitmap.Height <> VNewSize.Y) then begin
      SetNeedUpdateLayerSize;
    end;
  finally
    Layer.Bitmap.Unlock;
  end;
  inherited;
end;

procedure TMapLayerBasic.SetNeedUpdateLayerSize;
begin
  FNeedUpdateLayerSizeFlag.SetFlag;
end;

procedure TMapLayerBasic.DoHide;
begin
  inherited;
  SetNeedUpdateLayerSize;
end;

procedure TMapLayerBasic.DoRedraw;
begin
  ClearLayerBitmap;
  inherited;
end;

procedure TMapLayerBasic.DoShow;
begin
  inherited;
  SetNeedUpdateLayerSize;
end;

procedure TMapLayerBasic.DoUpdateLayerSize(const ANewSize: TPoint);
var
  VNedRedraw: Boolean;
begin
  FLayer.Bitmap.Lock;
  try
    VNedRedraw := FLayer.Bitmap.SetSize(ANewSize.X, ANewSize.Y);
  finally
    FLayer.Bitmap.Unlock;
  end;
  if VNedRedraw then begin
    SetNeedRedraw;
  end;
end;

procedure TMapLayerBasic.UpdateLayerSize;
begin
  FNeedUpdateLayerSizeFlag.CheckFlagAndReset;
  DoUpdateLayerSize(GetLayerSizeForView(LayerCoordConverter));
end;

procedure TMapLayerBasic.UpdateLayerSizeIfNeed;
begin
  if FNeedUpdateLayerSizeFlag.CheckFlagAndReset then begin
    UpdateLayerSize;
  end;
end;

function TMapLayerBasic.GetLayerCoordConverterByViewConverter(
  const ANewViewCoordConverter: ILocalCoordConverter
): ILocalCoordConverter;
begin
  Result := FConverterFactory.CreateBySourceWithStableTileRect(ANewViewCoordConverter);
end;

function TMapLayerBasic.GetLayerSizeForView(
  const ANewVisualCoordConverter: ILocalCoordConverter
): TPoint;
begin
  if Visible then begin
    Result := ANewVisualCoordConverter.GetLocalRectSize;
  end else begin
    Result := Point(0, 0);
  end;
end;

{ TMapLayerBasicNoBitmap }

constructor TMapLayerBasicNoBitmap.Create(
  const APerfList: IInternalPerformanceCounterList;
  AParentMap: TImage32;
  const AViewPortState: IViewPortState
);
begin
  inherited Create(APerfList, TCustomLayer.Create(AParentMap.Layers), AViewPortState);
  FOnPaintCounter := PerfList.CreateAndAddNewCounter('OnPaint');
end;

procedure TMapLayerBasicNoBitmap.DoRedraw;
begin
  inherited;
  Layer.Changed;
end;

procedure TMapLayerBasicNoBitmap.OnPaintLayer(
  Sender: TObject;
  Buffer: TBitmap32
);
var
  VLocalConverter: ILocalCoordConverter;
  VCounterContext: TInternalPerformanceCounterContext;
begin
  VLocalConverter := ViewCoordConverter;
  if VLocalConverter <> nil then begin
    VCounterContext := FOnPaintCounter.StartOperation;
    try
      PaintLayer(Buffer, VLocalConverter);
    finally
      FOnPaintCounter.FinishOperation(VCounterContext);
    end;
  end;
end;

procedure TMapLayerBasicNoBitmap.SetViewCoordConverter(
  const AValue: ILocalCoordConverter
);
var
  VLocalConverter: ILocalCoordConverter;
begin
  VLocalConverter := ViewCoordConverter;
  if (VLocalConverter = nil) or (not VLocalConverter.GetIsSameConverter(AValue)) then begin
    SetNeedRedraw;
  end;
  inherited;
end;

procedure TMapLayerBasicNoBitmap.StartThreads;
begin
  inherited;
  Layer.OnPaint := OnPaintLayer;
end;

end.
