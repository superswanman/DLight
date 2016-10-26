unit UDLight.Debug;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.TypInfo, System.Rtti,
  ToolsAPI, ToolUtils, DebugAPI, Events;

type
  PCodePos = ^CodePos;
  CodePos = record
    file_index: Cardinal;
    line_no: Cardinal;
    symtab_no: Cardinal;
  end;

  DbkAddr32 = record
    off: Cardinal;
  end;

  DbkAddrF32 = record
    off: Cardinal;
    sel: Word;
  end;

  DbkAddr64 = record
    off: UInt64;
  end;

  DbkAddrJava = record
    loc: UInt64;
  end;

  DbkAddrWMCIL = record
    modId: Cardinal;
    funcTok: Cardinal;
    off: Cardinal;
  end;

  DbkProcAddrU = record
    case Integer of
      0: (a32: DbkAddr32);
      1: (a32f: DbkAddrF32);
      2: (a64: DbkAddr64);
      3: (j: DbkAddrJava);
      4: (wmcil: DbkAddrWMCIL);
  end;

  DbkProcAddr_t = record
    form: Cardinal;
    u: DbkProcAddrU;
  end;

  IDbkInspect = interface
    ['{781D7176-4DCA-11D2-8800-00C04FB17199}']
    function resultsAvailable: HRESULT; stdcall;
    function inspkind(var kindPtr: Cardinal): HRESULT; stdcall;
    function flags(var flagsPtr: Cardinal): HRESULT; stdcall;
    function memberCount(var countPtr: Integer): HRESULT; stdcall;
    function propertyCount(var countPtr: Integer): HRESULT; stdcall;
    function methodCount(var countPtr: Integer): HRESULT; stdcall;
    function baseCount(var countPtr: Integer): HRESULT; stdcall;
    function titleLine(var titleLinePtr: PAnsiChar): HRESULT; stdcall;
    function typeName(var typeNamePtr: PAnsiChar): HRESULT; stdcall;
    function address(var addressPtr: PAnsiChar): HRESULT; stdcall;
    function value(var valuePtr: PAnsiChar): HRESULT; stdcall;
    function originalString(var originalStringPtr: PAnsiChar): HRESULT; stdcall;
    function errStr(var errStrPtr: PAnsiChar): HRESULT; stdcall;
    function setInspectRange(start: Integer; count: Integer): HRESULT; stdcall;
    function inspectRangeStartIndex(var startIndexPtr: Integer): HRESULT; stdcall;
    function objectSourcePos(var cpPtr: CodePos): HRESULT; stdcall;
    function getBaseInfo(index: Integer; var typeName: PAnsiChar;
      var membStart: Integer; var membCount: Integer; var methStart: Integer;
      var methCount: Integer; var propStart: Integer; var propCount: Integer): HRESULT; stdcall;
    function getMember(index: Integer; var name: PAnsiChar; var _type: PAnsiChar;
      var value: PAnsiChar; var addr: DbkProcAddr_t; var flags: Cardinal;
      var varType: Cardinal; var rc: Integer): HRESULT; stdcall;
    function getProperty(index: Integer; var name: PAnsiChar; var _type: PAnsiChar;
      var value: PAnsiChar; var flags: Cardinal; var rc: Integer): HRESULT; stdcall;
    function getMeth(index: Integer; var name: PAnsiChar; var _type: PAnsiChar;
      var value: PAnsiChar; var addr: DbkProcAddr_t; var flags: Cardinal;
      var rc: Integer): HRESULT; stdcall;
    function inspRc(var rcPtr: Integer): HRESULT; stdcall;
    function refreshInspector: HRESULT; stdcall;
    function verifyInspector(var retCodePtr: Integer): HRESULT; stdcall;
    function changeInspectValue(index: Integer; valueString: PAnsiChar;
      var retCodePtr: Integer): HRESULT; stdcall;
    function changePropertyValue(index: Integer; valueString: PAnsiChar;
      var rc: Integer): HRESULT; stdcall;
    function setDisplayFlags(newFlags: Cardinal; var oldFlags: Cardinal): HRESULT; stdcall;
    function subInsp(membMethFlag: Integer; index: Integer;
      out inspPtr: IDbkInspect): HRESULT; stdcall;
    function delInsp: HRESULT; stdcall;
    function bindToLocation(var rc: Integer): HRESULT; stdcall;
  end;

  IDbkThread = interface
    ['{65FB7680-92DC-11D7-94C8-005056C00001}']
    function threadType(var threadTyPtr: Cardinal): HRESULT; stdcall;
    function threadState(var threadStatePtr: Cardinal): HRESULT; stdcall;
    function dbkThreadId(var threadIdPtr: Cardinal): HRESULT; stdcall;
    function whyStoppedMask(var maskPtr: Integer): HRESULT; stdcall;
    function faultString(var strPtr: PAnsiChar): HRESULT; stdcall;
    function threadOsInfo(var dbkThreadOsInfo: Pointer{DbkThreadOsInfo}): HRESULT; stdcall;
    function ourProc(out procPtr: IInterface{IDbkProc}): HRESULT; stdcall;
    function run: HRESULT; stdcall;
    function stop: HRESULT; stdcall;
    function stmtStep(useRunTo1stSource: LongBool): HRESULT; stdcall;
    function stmtStepOver(useRunTo1stSource: LongBool): HRESULT; stdcall;
    function instrStep: HRESULT; stdcall;
    function instrStepOver: HRESULT; stdcall;
    function returnFromFunction: HRESULT; stdcall;
    function getContext(out contextPtr: IInterface{IDbkTContext}): HRESULT; stdcall;
    function getDisasm(out disasmPtr: IInterface{IDbkDisasm}): HRESULT; stdcall;
    function getEvaluator(out evalPtr: IInterface{IDbkEvaluator}): HRESULT; stdcall;
    function setEvaluator(const evalPtr: IInterface{IDbkEvaluator}): HRESULT; stdcall;
    function evaluate(expStr: PAnsiChar; resultStr: PAnsiChar;
      resultStrSize: Cardinal; var canModify: Integer; sideEffectsAllowed: Integer;
      sp: CodePos; optionsStr: PAnsiChar; var resultAddr: DbkProcAddr_t;
      var resultSize: Integer; typeStr: PAnsiChar; typeStrSize: Cardinal;
      var evaluatorResultVal: Integer): HRESULT; stdcall;
    function modify(valueStr: PAnsiChar; resultStr: PAnsiChar;
      resultStrSize: Cardinal; var evaluatorResult: Integer): HRESULT; stdcall;
    function evalCondition(expStr: PAnsiChar; errStr: PAnsiChar; errSize: Cardinal;
      var _result: Integer): HRESULT; stdcall;
    function getCallCount(var callCountPtr: Integer): HRESULT; stdcall;
    function getCallHeader(index: Cardinal; hdr: PAnsiChar; hdrSize: Cardinal): HRESULT; stdcall;
    function getCallPos(index: Cardinal; var funcStart: CodePos;
      var funcEnd: CodePos; var frameNo: Integer; var addr: DbkProcAddr_t;
      var codePosPtr: CodePos): HRESULT; stdcall;
    function getStackCallSites(out callSitesPtr: IInterface{IDbkStackCallSites}): HRESULT; stdcall;
    function newInsp(expr: PAnsiChar; sp: PCodePos; frameNo: Integer;
      out inspPtr: IDbkInspect): HRESULT; stdcall;
    function newInspLocals(sp: PCodePos; frameNo: Integer;
      out inspPtr: IDbkInspect): HRESULT; stdcall;
    function getInterpThread(out threadPtr: IDbkThread): HRESULT; stdcall;
    function getInterpHostThread(out threadPtr: IDbkThread): HRESULT; stdcall;
  end;

  TThread = class
  private
    class var
      FDbkThreadProp: PPropInfo;
    class procedure Init;
    function GetDbkThread: IDbkThread;
  public
    property DbkThread: IDbkThread read GetDbkThread;
  end;

  TProcess = class
  private
    class var
      FCurrentThreadProp: PPropInfo;
      FEvaluatorBusyMethod: function(Self: TObject): Boolean;
    class procedure Init;
    function GetCurrentThread: TThread;
  public
    function EvaluatorBusy: Boolean; inline;
    property CurrentThread: TThread read GetCurrentThread;
  end;

  TDebugger = class
  private
    class var
      FGetCurrentDbkDebuggerFunc: function: TDebugger;
      FLockEvaluatorMethod: function(Self: TObject): Integer;
      FUnlockEvaluatorMethod: function(Self: TObject): Integer;
      FProcessProp: PPropInfo;
    class procedure Init;
    function GetProcess: TProcess;
  public
    class function GetCurrentDbkDebugger: TDebugger; inline; static;
    function LockEvaluator: Integer; inline;
    function UnlockEvaluator: Integer; inline;
    property Process: TProcess read GetProcess;
  end;

  InspectGetMemberInfo_t = record
    memberRC: Integer;
    memberIndex: Integer;
    memberName: PAnsiChar;
    memberType: PAnsiChar;
    memberValue: PAnsiChar;
    memberAddr: DbkProcAddr_t;
    memberFlags: Cardinal;
  end;

  DbkErrInfoData_t = record
    case Integer of
//      1: (osErrInfo: OsErrInfo_t);
//      2: (evalResultInfo: EvalResultInfo_t);
//      3: (modifyResultInfo: ModifyResultInfo_t);
//      4: (evalConditionResultInfo: EvalConditionResultInfo_t);
//      5: (inspectResultInfo: InspectResultInfo_t);
      6: (inspectGetMemberInfo: InspectGetMemberInfo_t);
//      7: (inspectGetPropertyInfo: InspectGetPropertyInfo_t);
//      8: (inspectChangePropertyInfo: InspectChangePropertyInfo_t);
//      9: (inspectChangeValueInfo: InspectChangeValue_t);
  end;

  DbkErrInfo = record
    dbkErrInfoStructSize: Integer;
    errVal: Cardinal;
    errCode: Cardinal;
    errInfoTy: Cardinal;
    errNum: Integer;
    errInfo: DbkErrInfoData_t;
  end;

  TApiCompleteEvent = procedure(Sender: TObject; var ErrInfo: DbkErrInfo) of object;

  TDbkApiEvent = class(TEvent)
  public
    procedure Add(AHandler: TApiCompleteEvent);
    procedure Remove(AHandler: TApiCompleteEvent);
  end;

  PDebugKernel = ^TDebugKernel;
  TDebugKernel = class
  private
    class var
      FEvApiCompleteProp: PPropInfo;
      FProcessEventsMethod: procedure(Self: TObject);
      FAbortDBKSessionVar: PBoolean;
      FGlobalVar: PDebugKernel;
    class procedure Init;
    function GetEvApiComplete: TDbkApiEvent;
    class function GetCurrent: TDebugKernel; static;
    class function GetAbortDBKSession: Boolean; static;
  public
    procedure ProcessEvents; inline;
    property EvApiComplete: TDbkApiEvent read GetEvApiComplete;
    class property Current: TDebugKernel read GetCurrent;
    class property AbortDBKSession: Boolean read GetAbortDBKSession;
  end;

  TLocalVariable = record
    VarName: string;
    VarValue: string;
    VarType: string;
    VarAddress: DbkProcAddr_t;
    VarFlags: Cardinal;
  end;

function GetCurrentLocalVariables: TArray<TLocalVariable>;

implementation

uses
  UDLight.Utils;

var
  FMembers: TArray<TLocalVariable>;
  FDeferredMemberIndex: Integer;
  FDeferredGetMemberCompleted: Boolean;

procedure GetMemberComplete(Self, Sender: TObject; var ErrInfo: DbkErrInfo);
var
  debugger: TDebugger;
begin
  try
    if ErrInfo.errInfoTy = 6 then
    begin
      debugger := TDebugger.GetCurrentDbkDebugger;
      if debugger <> nil then
      begin
        debugger.UnlockEvaluator;
      end;

      if ErrInfo.errInfo.inspectGetMemberInfo.memberRC = 0 then
      begin
        FMembers[FDeferredMemberIndex].VarName := UTF8ToString(ErrInfo.errInfo.inspectGetMemberInfo.memberName);
        FMembers[FDeferredMemberIndex].VarValue := UTF8ToString(ErrInfo.errInfo.inspectGetMemberInfo.memberValue);
        FMembers[FDeferredMemberIndex].VarType := UTF8ToString(ErrInfo.errInfo.inspectGetMemberInfo.memberType);
        FMembers[FDeferredMemberIndex].VarAddress := ErrInfo.errInfo.inspectGetMemberInfo.memberAddr;
        FMembers[FDeferredMemberIndex].VarFlags := ErrInfo.errInfo.inspectGetMemberInfo.memberFlags;
      end;
    end;
  finally
    TDebugKernel.Current.EvApiComplete.Remove(TApiCompleteEvent(CreateMethod(nil, @GetMemberComplete)));
    FDeferredMemberIndex := -1;
    FDeferredGetMemberCompleted := True;
  end;
end;

function GetCurrentLocalVariables: TArray<TLocalVariable>;
var
  cpos: CodePos;
  debugger: TDebugger;
  process: TProcess;
  thread: TThread;
  dbkThread: IDbkThread;
  dbkInspect: IDbkInspect;
  rc: Integer;
  inspectorKind: Cardinal;
  i, count: Integer;
  name, _type, value: PAnsiChar;
  addr: DbkProcAddr_t;
  flags, varType: Cardinal;

  function IsDeferred(Status: HRESULT): Boolean;
  begin
    Result := Status and $60000000 = $60000000;
  end;

begin
  Result := nil;

  debugger := TDebugger.GetCurrentDbkDebugger;
  if not Assigned(debugger) then Exit;
  process := debugger.Process;
  if not Assigned(process) then Exit;
  thread := process.CurrentThread;
  if not Assigned(thread) then Exit;

  if TDebugKernel.AbortDBKSession then
    Exit;

  if process.EvaluatorBusy then Exit;

  FillChar(cpos, SizeOf(cpos), 0);
  dbkThread := thread.DbkThread;
  dbkThread.newInspLocals(@cpos, 1, dbkInspect);

  if Assigned(dbkInspect) then
  try
    rc := 1;
    dbkInspect.inspRc(rc);
    if rc <> 0 then Exit;
    if IsDeferred(dbkInspect.resultsAvailable) then Exit;

    dbkInspect.inspkind(inspectorKind);
    if inspectorKind = 3 then Exit;

    count := 0;
    dbkInspect.memberCount(count);
    SetLength(FMembers, count);
    for i := 0 to count-1 do
    begin
      if IsDeferred(dbkInspect.getMember(i, name, _type, value, addr, flags, varType, rc)) then
      begin
        debugger.LockEvaluator;
        FDeferredMemberIndex := i;
        FDeferredGetMemberCompleted := False;
        TDebugKernel.Current.EvApiComplete.Add(TApiCompleteEvent(CreateMethod(nil, @GetMemberComplete)));
        repeat
          TDebugKernel.Current.ProcessEvents;
          if not FDeferredGetMemberCompleted then
            Sleep(50);
        until FDeferredGetMemberCompleted;
      end
      else begin
        FMembers[i].VarName := UTF8ToString(name);
        FMembers[i].VarValue := UTF8ToString(value);
        FMembers[i].VarType := UTF8ToString(_type);
        FMembers[i].VarAddress := addr;
        FMembers[i].VarFlags := flags;
      end;
    end;
    Result := FMembers;
  finally
    dbkInspect.delInsp;
  end;
end;

{ TThread }

class procedure TThread.Init;
var
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
begin
  typ := ctx.FindType('Debug.TThread');
  if not Assigned(typ) then
    raise Exception.Create('RTTI not found (TThread)');
  prop := typ.GetProperty('DbkThread');
  if not Assigned(prop) then
    raise Exception.Create('RTTI not found (TThread.DbkThread)');
  FDbkThreadProp := TRttiInstanceProperty(prop).PropInfo;
end;

function TThread.GetDbkThread: IDbkThread;
begin
  Result := IDbkThread(GetInterfaceProp(Self, FDbkThreadProp));
end;

{ TProcess }

class procedure TProcess.Init;
var
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
  meth: TRttiMethod;
begin
  typ := ctx.FindType('Debug.TProcess');
  if not Assigned(typ) then
    raise Exception.Create('RTTI not found (TProcess)');
  prop := typ.GetProperty('CurrentThread');
  if not Assigned(prop) then
    raise Exception.Create('RTTI not found (TProcess.CurrentThread)');
  FCurrentThreadProp := TRttiInstanceProperty(prop).PropInfo;
  meth := typ.GetMethod('EvaluatorBusy');
  if not Assigned(meth) then
    raise Exception.Create('RTTI not found (TProcess.EvaluatorBusy)');
  @FEvaluatorBusyMethod := meth.CodeAddress;
end;

function TProcess.EvaluatorBusy: Boolean;
begin
  Result := FEvaluatorBusyMethod(Self);
end;

function TProcess.GetCurrentThread: TThread;
begin
  Result := TThread(GetObjectProp(Self, FCurrentThreadProp));
end;

{ TDebugger }

class procedure TDebugger.Init;
var
  dbkDebugIde: string;
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
  meth: TRttiMethod;
begin
  typ := ctx.FindType('Debug.TDebugger');
  if typ = nil then
    raise Exception.Create('RTTI not found (TDebugger)');
  dbkDebugIde := ExtractFileName(typ.Package.Name);
  prop := typ.GetProperty('Process');
  if prop = nil then
    raise Exception.Create('RTTI not found (TDebugger.Process)');
  FProcessProp := TRttiInstanceProperty(prop).PropInfo;
  meth := typ.GetMethod('LockEvaluator');
  if not Assigned(meth) then
    raise Exception.Create('RTTI not found (TDebugger.LockEvaluator)');
  @FLockEvaluatorMethod := meth.CodeAddress;
  meth := typ.GetMethod('UnlockEvaluator');
  if not Assigned(meth) then
    raise Exception.Create('RTTI not found (TDebugger.UnlockEvaluator)');
  @FUnlockEvaluatorMethod := meth.CodeAddress;

  @FGetCurrentDbkDebuggerFunc := GetProcAddress(GetModuleHandle(PChar(dbkDebugIde)), '@Debug@GetCurrentDbkDebugger$qqrv');
  if not Assigned(FGetCurrentDbkDebuggerFunc) then
    raise Exception.Create('Function not found (GetCurrentDbkDebugger)');
end;

class function TDebugger.GetCurrentDbkDebugger: TDebugger;
begin
  Result := FGetCurrentDbkDebuggerFunc;
end;

function TDebugger.LockEvaluator: Integer;
begin
  Result := FLockEvaluatorMethod(Self);
end;

function TDebugger.UnlockEvaluator: Integer;
begin
  Result := FUnlockEvaluatorMethod(Self);
end;

function TDebugger.GetProcess: TProcess;
begin
  Result := TProcess(GetObjectProp(Self, FProcessProp));
end;

{ TDbkApiEvent }

procedure TDbkApiEvent.Add(AHandler: TApiCompleteEvent);
begin
  inherited Add(TNotifyEvent(AHandler));
end;

procedure TDbkApiEvent.Remove(AHandler: TApiCompleteEvent);
begin
  inherited Remove(TNotifyEvent(AHandler));
end;

{ TDebugKernel }

class procedure TDebugKernel.Init;
var
  dbkDebugIde: string;
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
  meth: TRttiMethod;
begin
  typ := ctx.FindType('Debug.TDebugKernel');
  if not Assigned(typ) then
    raise Exception.Create('RTTI not found (TDebugKernel)');
  dbkDebugIde := ExtractFileName(typ.Package.Name);
  prop := typ.GetProperty('EvApiComplete');
  if not Assigned(prop) then
    raise Exception.Create('RTTI not found (TDebugKernel.EvApiComplete)');
  FEvApiCompleteProp := TRttiInstanceProperty(prop).PropInfo;
  meth := typ.GetMethod('ProcessEvents');
  if not Assigned(meth) then
    raise Exception.Create('RTTI not found (TDebugKernel.ProcessEvents)');
  FProcessEventsMethod := meth.CodeAddress;

  FGlobalVar := GetProcAddress(GetModuleHandle(PChar(dbkDebugIde)), '@Debug@DebuggerKernel');
  if not Assigned(FGlobalVar) then
    raise Exception.Create('Variable not found (DebuggerKernel)');
  FAbortDBKSessionVar := GetProcAddress(GetModuleHandle(PChar(dbkDebugIde)), '@Debug@TDebugKernel@FAbortDBKSession');
  if not Assigned(FAbortDBKSessionVar) then
    raise Exception.Create('Variable not found (TDebugKernel.AbortDBKSession)');
end;

procedure TDebugKernel.ProcessEvents;
begin
  FProcessEventsMethod(Self);
end;

function TDebugKernel.GetEvApiComplete: TDbkApiEvent;
begin
  Result := TDbkApiEvent(GetObjectProp(Self, FEvApiCompleteProp));
end;

class function TDebugKernel.GetCurrent: TDebugKernel;
begin
  Result := FGlobalVar^;
end;

class function TDebugKernel.GetAbortDBKSession: Boolean;
begin
  Result := FAbortDBKSessionVar^;
end;

initialization
  TThread.Init;
  TProcess.Init;
  TDebugger.Init;
  TDebugKernel.Init;
end.