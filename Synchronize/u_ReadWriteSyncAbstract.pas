unit u_ReadWriteSyncAbstract;

interface

uses
  SysUtils,
  i_InternalPerformanceCounter,
  i_ReadWriteSyncFactory;

type
  TReadWriteSyncAbstract = class(TInterfacedObject)
  private
    FName: AnsiString;
  public
    constructor Create(const AName: AnsiString);
  end;

  TReadWriteSyncDebugWrapper = class(TInterfacedObject, IReadWriteSync)
  private
    FLock: IReadWriteSync;
    FLockClassName: AnsiString;
    FName: ShortString;
  protected
    procedure DoDebugGlobalLocks(const AProcedure, AEvent: AnsiString);
  private
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
  public
    constructor Create(
      const ALock: IReadWriteSync;
      const ALockClassName: AnsiString;
      const AName: AnsiString
    );
  end;

  TReadWriteSyncCounterWrapper = class(TInterfacedObject, IReadWriteSync)
  private
    FLock: IReadWriteSync;
    FBeginReadCounter: IInternalPerformanceCounter;
    FEndReadCounter: IInternalPerformanceCounter;
    FBeginWriteCounter: IInternalPerformanceCounter;
    FEndWriteCounter: IInternalPerformanceCounter;
    FDestroyCounter: IInternalPerformanceCounter;
  private
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
  public
    constructor Create(
      const ALock: IReadWriteSync;
      const ABeginReadCounter: IInternalPerformanceCounter;
      const AEndReadCounter: IInternalPerformanceCounter;
      const ABeginWriteCounter: IInternalPerformanceCounter;
      const AEndWriteCounter: IInternalPerformanceCounter;
      const ADestroyCounter: IInternalPerformanceCounter
    );
    destructor Destroy; override;
  end;

  TSynchronizerFake = class(TReadWriteSyncAbstract, IReadWriteSync)
  private
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
  end;

  TSynchronizerFakeFactory = class(TInterfacedObject, IReadWriteSyncFactory)
  private
    function Make(const AName: AnsiString): IReadWriteSync;
  end;

  TSynchronizerMREWFactory = class(TInterfacedObject, IReadWriteSyncFactory)
  private
    function Make(const AName: AnsiString): IReadWriteSync;
  end;

  TSynchronizerFactoryWithDebug = class(TInterfacedObject, IReadWriteSyncFactory)
  private
    FFactory: IReadWriteSyncFactory;
    FLockClassName: AnsiString;
  private
    function Make(const AName: AnsiString): IReadWriteSync;
  public
    constructor Create(
      const AFactory: IReadWriteSyncFactory;
      const ALockClassName: AnsiString
    );
  end;

  TSynchronizerFactoryWithCounters = class(TInterfacedObject, IReadWriteSyncFactory)
  private
    FFactory: IReadWriteSyncFactory;
    FBeginReadCounter: IInternalPerformanceCounter;
    FEndReadCounter: IInternalPerformanceCounter;
    FBeginWriteCounter: IInternalPerformanceCounter;
    FEndWriteCounter: IInternalPerformanceCounter;
    FDestroyCounter: IInternalPerformanceCounter;
  private
    function Make(const AName: AnsiString): IReadWriteSync;
  public
    constructor Create(
      const AFactory: IReadWriteSyncFactory;
      const ABeginReadCounter: IInternalPerformanceCounter;
      const AEndReadCounter: IInternalPerformanceCounter;
      const ABeginWriteCounter: IInternalPerformanceCounter;
      const AEndWriteCounter: IInternalPerformanceCounter;
      const ADestroyCounter: IInternalPerformanceCounter
    );
  end;

  TSynchronizerFactoryWithMakeCounter = class(TInterfacedObject, IReadWriteSyncFactory)
  private
    FFactory: IReadWriteSyncFactory;
    FCounter: IInternalPerformanceCounter;
  private
    function Make(const AName: AnsiString): IReadWriteSync;
  public
    constructor Create(
      const AFactory: IReadWriteSyncFactory;
      const ACounter: IInternalPerformanceCounter
    );
  end;


var
  DebugGlobalLocks_Enabled: Boolean;

implementation

uses
  Windows;

{ TReadWriteSyncAbstractSimple }

constructor TReadWriteSyncAbstract.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
end;

{ TSynchronizerFake }

procedure TSynchronizerFake.BeginRead;
begin
  // Do nothing
end;

function TSynchronizerFake.BeginWrite: Boolean;
begin
  // Do nothing
  Result := False;
end;

procedure TSynchronizerFake.EndRead;
begin
  // Do nothing
end;

procedure TSynchronizerFake.EndWrite;
begin
  // Do nothing
end;

{ TSynchronizerFakeFactory }

function TSynchronizerFakeFactory.Make(const AName: AnsiString): IReadWriteSync;
begin
  Result := TSynchronizerFake.Create(AName);
end;

{ TReadWriteSyncDebugWrapper }

constructor TReadWriteSyncDebugWrapper.Create(
  const ALock: IReadWriteSync;
  const ALockClassName: AnsiString;
  const AName: AnsiString
);
begin
  Assert(ALock <> nil);
  inherited Create;
  FLock := ALock;
  FLockClassName := ALockClassName;
  FName := AName;
end;

procedure TReadWriteSyncDebugWrapper.BeginRead;
begin
  DoDebugGlobalLocks('BeginRead', 'IN');
  FLock.BeginRead;
  DoDebugGlobalLocks('BeginRead', 'OUT');
end;

function TReadWriteSyncDebugWrapper.BeginWrite: Boolean;
begin
  DoDebugGlobalLocks('BeginWrite', 'IN');
  Result := FLock.BeginWrite;
  DoDebugGlobalLocks('BeginWrite', 'OUT');
end;

procedure TReadWriteSyncDebugWrapper.DoDebugGlobalLocks(const AProcedure,
  AEvent: String);
const
  c_SEP: AnsiString = ', ' + Chr(VK_TAB);
var
  VText: AnsiString;
begin
  if (not DebugGlobalLocks_Enabled) then
    Exit;
  VText := FLockClassName + ' at $'+ IntToHex(Integer(Pointer(Self)), 8)+' (from '+FName+')' + c_SEP + 'ThreadId=' + IntToStr(GetCurrentThreadId) + c_SEP +  AProcedure + c_SEP + AEvent;
  OutputDebugString(PChar(VText));
end;

procedure TReadWriteSyncDebugWrapper.EndRead;
begin
  DoDebugGlobalLocks('EndRead', 'IN');
  FLock.EndRead;
  DoDebugGlobalLocks('EndRead', 'OUT');
end;

procedure TReadWriteSyncDebugWrapper.EndWrite;
begin
  DoDebugGlobalLocks('EndWrite', 'IN');
  FLock.EndWrite;
  DoDebugGlobalLocks('EndWrite', 'OUT');
end;

{ TReadWriteSyncCounterWrapper }

constructor TReadWriteSyncCounterWrapper.Create(
  const ALock: IReadWriteSync;
  const ABeginReadCounter: IInternalPerformanceCounter;
  const AEndReadCounter: IInternalPerformanceCounter;
  const ABeginWriteCounter: IInternalPerformanceCounter;
  const AEndWriteCounter: IInternalPerformanceCounter;
  const ADestroyCounter: IInternalPerformanceCounter
);
begin
  Assert(ALock <> nil);
  inherited Create;
  FLock := ALock;
  FBeginReadCounter := ABeginReadCounter;
  FEndReadCounter := AEndReadCounter;
  FBeginWriteCounter := ABeginWriteCounter;
  FEndWriteCounter := AEndWriteCounter;
  FDestroyCounter := ADestroyCounter;
end;

destructor TReadWriteSyncCounterWrapper.Destroy;
var
  VCounter: Pointer;
  VContext: TInternalPerformanceCounterContext;
begin
  VCounter := Pointer(FDestroyCounter);
  if VCounter <> nil then begin
    VContext := IInternalPerformanceCounter(VCounter).StartOperation;
    FLock := nil;
    FBeginReadCounter := nil;
    FEndReadCounter := nil;
    FBeginWriteCounter := nil;
    FEndWriteCounter := nil;
    inherited;
    IInternalPerformanceCounter(VCounter).FinishOperation(VContext);
  end else begin
    FLock := nil;
    FBeginReadCounter := nil;
    FEndReadCounter := nil;
    FBeginWriteCounter := nil;
    FEndWriteCounter := nil;
    inherited;
  end;
end;

procedure TReadWriteSyncCounterWrapper.BeginRead;
var
  VCounter: Pointer;
  VContext: TInternalPerformanceCounterContext;
begin
  VCounter := Pointer(FBeginReadCounter);
  if VCounter <> nil then begin
    VContext := IInternalPerformanceCounter(VCounter).StartOperation;
    FLock.BeginRead;
    IInternalPerformanceCounter(VCounter).FinishOperation(VContext);
  end else begin
    FLock.BeginRead;
  end;
end;

function TReadWriteSyncCounterWrapper.BeginWrite: Boolean;
var
  VCounter: Pointer;
  VContext: TInternalPerformanceCounterContext;
begin
  VCounter := Pointer(FBeginWriteCounter);
  if VCounter <> nil then begin
    VContext := IInternalPerformanceCounter(VCounter).StartOperation;
    Result := FLock.BeginWrite;
    IInternalPerformanceCounter(VCounter).FinishOperation(VContext);
  end else begin
    Result := FLock.BeginWrite;
  end;
end;

procedure TReadWriteSyncCounterWrapper.EndRead;
var
  VCounter: Pointer;
  VContext: TInternalPerformanceCounterContext;
begin
  VCounter := Pointer(FEndReadCounter);
  if VCounter <> nil then begin
    VContext := IInternalPerformanceCounter(VCounter).StartOperation;
    FLock.EndRead;
    IInternalPerformanceCounter(VCounter).FinishOperation(VContext);
  end else begin
    FLock.EndRead;
  end;
end;

procedure TReadWriteSyncCounterWrapper.EndWrite;
var
  VCounter: Pointer;
  VContext: TInternalPerformanceCounterContext;
begin
  VCounter := Pointer(FEndWriteCounter);
  if VCounter <> nil then begin
    VContext := IInternalPerformanceCounter(VCounter).StartOperation;
    FLock.EndWrite;
    IInternalPerformanceCounter(VCounter).FinishOperation(VContext);
  end else begin
    FLock.EndWrite;
  end;
end;

{ TSynchronizerFactoryWithDebug }

constructor TSynchronizerFactoryWithDebug.Create(
  const AFactory: IReadWriteSyncFactory; const ALockClassName: AnsiString);
begin
  Assert(AFactory <> nil);
  inherited Create;
  FFactory := AFactory;
  FLockClassName := ALockClassName;
end;

function TSynchronizerFactoryWithDebug.Make(
  const AName: AnsiString
): IReadWriteSync;
begin
  Result :=
    TReadWriteSyncDebugWrapper.Create(
      FFactory.Make(AName),
      FLockClassName,
      AName
    );
end;

{ TSynchronizerFactoryWithCounters }

constructor TSynchronizerFactoryWithCounters.Create(
  const AFactory: IReadWriteSyncFactory;
  const ABeginReadCounter: IInternalPerformanceCounter;
  const AEndReadCounter: IInternalPerformanceCounter;
  const ABeginWriteCounter: IInternalPerformanceCounter;
  const AEndWriteCounter: IInternalPerformanceCounter;
  const ADestroyCounter: IInternalPerformanceCounter
);
begin
  Assert(AFactory <> nil);
  inherited Create;
  FFactory := AFactory;
  FBeginReadCounter := ABeginReadCounter;
  FEndReadCounter := AEndReadCounter;
  FBeginWriteCounter := ABeginWriteCounter;
  FEndWriteCounter := AEndWriteCounter;
  FDestroyCounter := ADestroyCounter;
end;

function TSynchronizerFactoryWithCounters.Make(
  const AName: AnsiString): IReadWriteSync;
begin
  Result :=
    TReadWriteSyncCounterWrapper.Create(
      FFactory.Make(AName),
      FBeginReadCounter,
      FEndReadCounter,
      FBeginWriteCounter,
      FEndWriteCounter,
      FDestroyCounter
    );
end;

{ TSynchronizerFactoryWithMakeCounter }

constructor TSynchronizerFactoryWithMakeCounter.Create(
  const AFactory: IReadWriteSyncFactory;
  const ACounter: IInternalPerformanceCounter
);
begin
  Assert(AFactory <> nil);
  Assert(ACounter <> nil);
  inherited Create;
  FFactory := AFactory;
  FCounter := ACounter;
end;

function TSynchronizerFactoryWithMakeCounter.Make(
  const AName: AnsiString): IReadWriteSync;
var
  VContext: TInternalPerformanceCounterContext;
begin
  VContext := FCounter.StartOperation;
  try
    Result := FFactory.Make(AName);
  finally
    FCounter.FinishOperation(VContext);
  end;
end;

{ TSynchronizerMREWFactory }

function TSynchronizerMREWFactory.Make(const AName: AnsiString): IReadWriteSync;
begin
  Result := TMultiReadExclusiveWriteSynchronizer.Create;
end;

initialization
  DebugGlobalLocks_Enabled := FALSE;
end.
