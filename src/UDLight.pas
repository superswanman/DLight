unit UDLight;

interface

{$IFNDEF CONDITIONALEXPRESSIONS}
  {$MESSAGE ERROR '10 Seattle or higher is required'}
{$ELSE}
  {$IF RTLVersion < 30.0}
    {$MESSAGE ERROR '10 Seattle or higher is required'}
  {$IFEND}
{$ENDIF}

procedure Register;

implementation

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.UITypes, System.UIConsts, System.RTLConsts, System.Rtti, System.TypInfo,
  System.Generics.Collections, System.Generics.Defaults, Vcl.Graphics, Vcl.Forms,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Tabs, ToolsAPI, DebugAPI, UDLight.DDetours;

type
  TExprItem = record
  public
    Expr: string;
    Value: string;
    TypeName: string;
    class function Create(AExpressionInspector: IOTAExpressionInspector): TExprItem; overload; static;
    class function Create(AExpressionInspector: IOTAExpressionInspector; AMemberIndex: Integer): TExprItem; overload; static;
  end;

  TIDENotifier = class(TNotifierObject, IOTAIDENotifier)
  private
    FEditorNotifiers: TList<IOTAEditorNotifier>;
  public
    constructor Create;
    destructor Destroy; override;

    { IOTAIDENotifier }
    procedure FileNotification(NotifyCode: TOTAFileNotification;
      const FileName: string; var Cancel: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean); overload;
    procedure AfterCompile(Succeeded: Boolean); overload;
  end;

  TEditorNotifier = class(TNotifierObject, IOTANotifier, IOTAEditorNotifier)
  private
    FSourceEditor: IOTASourceEditor;
    FEditViewNotifiers: TList<INTAEditViewNotifier>;
    FNotifierIndex: Integer;
    procedure RemoveNotifiers;
  public
    constructor Create(ASourceEditor: IOTASourceEditor);
    destructor Destroy; override;

    { IOTANotifier }
    procedure Destroyed;
    { IOTAEditorNotifier }
    procedure ViewNotification(const View: IOTAEditView; Operation: TOperation);
    procedure ViewActivated(const View: IOTAEditView);
  end;

  TEditViewNotifier = class(TNotifierObject, IOTANotifier, INTAEditViewNotifier)
  private
    FEditView: IOTAEditView;
    FNotifierIndex: Integer;
    procedure RemoveNotifier;
  public
    constructor Create(AEditView: IOTAEditView);
    destructor Destroy; override;

    { IOTANotifier }
    procedure Destroyed;
    { INTAEditViewNotifier }
    procedure EditorIdle(const View: IOTAEditView);
    procedure BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);
    procedure PaintLine(const View: IOTAEditView; LineNumber: Integer;
      const LineText: PAnsiChar; const TextWidth: Word; const LineAttributes: TOTAAttributeArray;
      const Canvas: TCanvas; const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
    procedure EndPaint(const View: IOTAEditView);
  end;

  TDebuggerNotifier = class(TNotifierObject, IOTADebuggerNotifier, IOTADebuggerNotifier90)
  private
    FDebugger: IOTADebugger;
    FNotifierIndex: Integer;
    procedure RemoveNotifier;
  public
    constructor Create(ADebugger: IOTADebugger);
    destructor Destroy; override;

    { IOTANotifier }
    procedure Destroyed;
    { IOTADebuggerNotifier }
    procedure ProcessCreated(const Process: IOTAProcess);
    procedure ProcessDestroyed(const Process: IOTAProcess);
    procedure BreakpointAdded(const Breakpoint: IOTABreakpoint);
    procedure BreakpointDeleted(const Breakpoint: IOTABreakpoint);
    { IOTADebuggerNotifier90 }
    procedure BreakpointChanged(const Breakpoint: IOTABreakpoint);
    procedure CurrentProcessChanged(const Process: IOTAProcess);
    procedure ProcessStateChanged(const Process: IOTAProcess);
    function BeforeProgramLaunch(const Project: IOTAProject): Boolean;
    procedure ProcessMemoryChanged;
  end;

  TDebuggerManagerNotifier = class(TNotifierObject, IOTADebuggerManagerNotifier)
  private
    FDebuggerNotifiers: TList<IOTADebuggerNotifier>;
  public
    constructor Create;
    destructor Destroy; override;
    { IOTADebuggerManagerNotifier }
    procedure DebuggerAdded(const Debugger: IOTADebugger);
    procedure DebuggerRemoved(const Debugger: IOTADebugger);
  end;

  PStringList = ^TStringList;

  PWatchItem = ^TWatchItem;
  TWatchItem = record
  public
    Expr: string; // Ofs=0000
    Value: string; // Ofs=0004
    Address: Cardinal; // Ofs=0008
    Size: Cardinal; // Ofs=000C
    Format: TWatchFormats; // Ofs=0010
    RepeatCount: Integer; // Ofs=0014
    Digits: Integer; // Ofs=0018
    EvalErr: Boolean; // Ofs=001C
    Enabled: Boolean; // Ofs=001D
    Evaluated: Boolean; // Ofs=001E
    Inspected: Boolean; // Ofs=001F
    BPSet: Boolean; // Ofs=0020
    AllowSideEffects: Boolean; // Ofs=0021
    CanModify: Boolean; // Ofs=0022
    UseVisualizer: Boolean; // Ofs=0023
    HasVisualizerInspectDeferred: Boolean; // Ofs=0024
    VisualizerValue: string; // Ofs=0028
    TabName: string; // Ofs=002C
    ExpressionInspector: IOTAExpressionInspector; // Ofs=0030
  end;
  {$IF SizeOf(TWatchItem) <> 52}
  {$MESSAGE ERROR 'The size of the TWatchItem must be 52 bytes'}
  {$IFEND}

var
  FDLightEnabled: Boolean;
  FIDENotifierIndex: Integer = -1;
  FDebuggerManagerNotifierIndex: Integer = -1;
  FLocalVariables: TDictionary<string,TExprItem>;
  FWatchExpressions: TList<TExprItem>;
  FCurrentBuffer: IOTAEditBuffer;
  FRepaintAll: Boolean;
  FHideLocalVarIfLineContainsExpr: Boolean = True;
  FRepaintTimer: TTimer;
  FEvaluateTimer: TTimer;
  FTWatchWindow_GetWatchItemCount: function(Self: TObject): Integer;
  FTrampolineWatchWindowAddWatch: procedure(Self: TObject; const Watch: string; aTabName: string);
  FOriginalWindowProc: TWndMethod;
  FWatchWindow: TForm;
  FWatchTabList: PStringList;
  FLeftGutter: Integer;
  FLeftGutterProp: PPropInfo;
{$IFDEF DEBUG}
  FEditorNotifierCount: Integer;
  FEditViewNotifierCount: Integer;
  FDebuggerNotifierCount: Integer;
{$ENDIF}

function CreateMethod(Self: TObject; Proc: Pointer): TMethod;
begin
  TMethod(Result).Code := Proc;
  TMethod(Result).Data := Self;
end;

{ TExprItem }

class function TExprItem.Create(
  AExpressionInspector: IOTAExpressionInspector): TExprItem;
begin
  Result.Expr := AExpressionInspector.FullExpression;
  Result.Value := AExpressionInspector.Value;
  Result.TypeName := AExpressionInspector.TypeName;
end;

class function TExprItem.Create(AExpressionInspector: IOTAExpressionInspector;
  AMemberIndex: Integer): TExprItem;
begin
  Result.Expr := AExpressionInspector.MemberName[eimtData, AMemberIndex];
  Result.Value := AExpressionInspector.MemberValue[eimtData, AMemberIndex];
  Result.TypeName := AExpressionInspector.MemberType[eimtData, AMemberIndex];
end;

{ TIDENotifier }

constructor TIDENotifier.Create;
var
  moduleServices: IOTAModuleServices;
  i, j: Integer;
  module: IOTAModule;
  editor: IOTASourceEditor;
begin
  inherited;
  FEditorNotifiers := TList<IOTAEditorNotifier>.Create;

  moduleServices := BorlandIDEServices as IOTAModuleServices;
  for i := 0 to moduleServices.ModuleCount-1 do
  begin
    module := moduleServices.Modules[i];

    for j := 0 to module.ModuleFileCount-1 do
      if Supports(module.ModuleFileEditors[j], IOTASourceEditor, editor) then
        FEditorNotifiers.Add(TEditorNotifier.Create(editor));
  end;
end;

destructor TIDENotifier.Destroy;
var
  i: Integer;
begin
  for i := 0 to FEditorNotifiers.Count-1 do
    FEditorNotifiers[i].Destroyed;
  FEditorNotifiers.Free;
  inherited;
end;

procedure TIDENotifier.FileNotification(NotifyCode: TOTAFileNotification;
  const FileName: string; var Cancel: Boolean);
var
  module: IOTAModule;
  i: Integer;
  editor: IOTASourceEditor;
begin
  if NotifyCode = ofnFileOpened then
  begin
    module := (BorlandIDEServices as IOTAModuleServices).FindModule(FileName);
    if not Assigned(Module) then Exit;
    for i := 0 to module.ModuleFileCount-1 do
      if Supports(module.ModuleFileEditors[i], IOTASourceEditor, editor) then
        FEditorNotifiers.Add(TEditorNotifier.Create(editor));
  end;
end;

procedure TIDENotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
end;

procedure TIDENotifier.AfterCompile(Succeeded: Boolean);
begin
end;

{ TEditorNotifier }

constructor TEditorNotifier.Create(ASourceEditor: IOTASourceEditor);
var
  i: Integer;
begin
  inherited Create;
  FEditViewNotifiers := TList<INTAEditViewNotifier>.Create;
  FSourceEditor := ASourceEditor;

  FNotifierIndex := FSourceEditor.AddNotifier(Self);
{$IFDEF DEBUG}
  Inc(FEditorNotifierCount);
{$ENDIF}
  for i := 0 to FSourceEditor.EditViewCount-1 do
  begin
    FEditViewNotifiers.Add(TEditViewNotifier.Create(FSourceEditor.EditViews[i]));
  end;

end;

destructor TEditorNotifier.Destroy;
begin
  RemoveNotifiers;
  FEditViewNotifiers.Free;
  inherited;
end;

procedure TEditorNotifier.Destroyed;
begin
  RemoveNotifiers;
end;

procedure TEditorNotifier.ViewNotification(const View: IOTAEditView; Operation: TOperation);
begin
  if Operation = opInsert then
    FEditViewNotifiers.Add(TEditViewNotifier.Create(View));
end;

procedure TEditorNotifier.ViewActivated(const View: IOTAEditView);
begin
end;

procedure TEditorNotifier.RemoveNotifiers;
var
  i: Integer;
begin
  for i := 0 to FEditViewNotifiers.Count-1 do
    FEditViewNotifiers[i].Destroyed;
  FEditViewNotifiers.Clear;

  if Assigned(FSourceEditor) and (FNotifierIndex >= 0) then
  begin
    FSourceEditor.RemoveNotifier(FNotifierIndex);
    FNotifierIndex := -1;
    FSourceEditor := nil;
{$IFDEF DEBUG}
    Dec(FEditorNotifierCount);
{$ENDIF}
  end;
end;

{ TEditViewNotifier }

constructor TEditViewNotifier.Create(AEditView: IOTAEditView);
begin
  inherited Create;
  FEditView := AEditView;
  FNotifierIndex := FEditView.AddNotifier(Self);
{$IFDEF DEBUG}
  Inc(FEditViewNotifierCount);
{$ENDIF}
end;

destructor TEditViewNotifier.Destroy;
begin
  RemoveNotifier;
  inherited;
end;

procedure TEditViewNotifier.Destroyed;
begin
  RemoveNotifier;
end;

procedure TEditViewNotifier.EditorIdle(const View: IOTAEditView);
begin
end;

procedure TEditViewNotifier.BeginPaint(const View: IOTAEditView; var FullRepaint: Boolean);

  function FindEditControl(AControl: TWinControl): TWinControl;
  var
    i: Integer;
  begin
    if AControl.QualifiedClassName = 'EditorControl.TEditControl' then
      Exit(AControl);

    for i := 0 to AControl.ControlCount-1 do
    begin
      if not (AControl.Controls[i] is TWinControl) then Continue;
      Result := FindEditControl(TWinControl(AControl.Controls[i]));
      if Result <> nil then Exit;
    end;
    Result := nil;
  end;

var
  control: TWinControl;
begin
  if FRepaintAll then
  begin
    FullRepaint := True;
    FRepaintAll := False;
  end;

  if FDLightEnabled and (FLeftGutterProp <> nil) then
  begin
    control := FindEditControl(View.GetEditWindow.Form);
    if control <> nil then
    FLeftGutter := GetOrdProp(control, FLeftGutterProp);
  end;
end;

function GetIdentifiers(const LineText: PAnsiChar; const TextWidth: Word;
  const LineAttributes: TOTAAttributeArray): TArray<string>;
var
  isIdentifier: Boolean;
  i: Integer;
  p, p1: PAnsiChar;
  identA: AnsiString;
  identU: string;
  idents: TStringList;
begin
  idents := TStringlist.Create;
  try
    idents.CaseSensitive := False;

    isIdentifier := False;
    p := LineText;
    p1 := LineText;
    for i := Low(LineAttributes) to High(LineAttributes) do
    begin
      case LineAttributes[i] of
        atIdentifier:
        begin
          if not isIdentifier then
          begin
            isIdentifier := True;
            p1 := p;
          end
        end;
      else
        if isIdentifier then
        begin
          isIdentifier := False;

          SetString(identA, p1, p - p1);
          identU := string(identA);
          if idents.IndexOf(identU) < 0 then
            idents.Add(identU);
        end;
      end;
      Inc(p);
    end;
    if isIdentifier then
    begin
      SetString(identA, p1, p - p1);
      identU := string(identA);
      if idents.IndexOf(identU) < 0 then
        idents.Add(identU);
    end;

    Result := idents.ToStringArray;
  finally
    idents.Free;
  end;
end;

procedure TEditViewNotifier.PaintLine(const View: IOTAEditView; LineNumber: Integer;
  const LineText: PAnsiChar; const TextWidth: Word; const LineAttributes: TOTAAttributeArray;
  const Canvas: TCanvas; const TextRect: TRect; const LineRect: TRect; const CellSize: TSize);
var
  i, p, lastPos: Integer;
  idents: TArray<string>;
  item: TExprItem;
  list: TList<TPair<Integer,TExprItem>>;
  lineTextUtf8, exprUtf8: UTF8String;
  dispItems: TArray<TExprItem>;
  x, y: Integer;
  clipRect: TRect;
  rgn: HRGN;

  function TryStrToColor(const S: string; out Name: string; out Color: TColor): Boolean;
  var
    LColor64: Int64;
    LColor: Integer absolute LColor64;
  begin
    if not IdentToColor(S, LColor) then
    begin
      Result := TryStrToInt64(S, LColor64);
      if Result then
      begin
        if not ColorToIdent(LColor, Name) then
          Name := HexDisplayPrefix + IntToHex(LColor, 6);
        Color := TColor(LColor);
      end;
    end
    else begin
      Name := ColorToString(TColor(LColor));
      Color := TColor(LColor);
      Result := True;
    end;
  end;

  function TryStrToAlphaColor(const S: string; out Name: string; out Color: TAlphaColor): Boolean;
  var
    LColor64: Int64;
    LColor: Integer absolute LColor64;
  begin
    if not IdentToAlphaColor(S, LColor) then
    begin
      Result := TryStrToInt64(S, LColor64);
      if Result then
      begin
        if not AlphaColorToIdent(LColor, Name) then
          Name := HexDisplayPrefix + IntToHex(LColor, 8);
        Color := TAlphaColor(LColor);
      end;
    end
    else begin
      Name := AlphaColorToString(TAlphaColor(LColor));
      Color := TAlphaColor(LColor);
      Result := True;
    end;
  end;

  procedure DrawString(const Text: string);
  var
    textWidth: Integer;
  begin
    Canvas.Brush.Color := clTeal;
    Canvas.Font.Color := clAqua;
    textWidth := Canvas.TextWidth(Text);
    Canvas.TextOut(x, y, Text);
    Inc(x, textWidth);
  end;

  procedure DrawPad(Count: Integer = 1);
  var
    width: Integer;
  begin
    width := CellSize.cx * Count;
    Canvas.Brush.Color := clTeal;
    Canvas.FillRect(Bounds(x, y, width, TextRect.Height));
    Inc(x, width);
  end;

  procedure DrawColor(Color: TColor);
  begin
    Canvas.Brush.Color := clTeal;
    Canvas.FillRect(Bounds(x, y, TextRect.Height, TextRect.Height));
    Canvas.Pen.Color := clBlack;
    Canvas.Brush.Color := ColorToRGB(Color);
    Canvas.Rectangle(Bounds(x+1, y+1, TextRect.Height-2, TextRect.Height-2));
    Inc(x, TextRect.Height);
  end;

  procedure DrawAlphaColor(Color: TAlphaColor);
  var
    c: TColor;
  begin
    TColorRec(c).R := TAlphaColorRec(Color).R;
    TColorRec(c).G := TAlphaColorRec(Color).G;
    TColorRec(c).B := TAlphaColorRec(Color).B;
    TColorRec(c).A := 0; //TAlphaColorRec(Color).A;
    DrawColor(c);
  end;

  procedure DrawTextValue(const Item: TExprItem);
  begin
    DrawString(item.Expr + '=' + item.Value);
  end;

  procedure DrawColorValue(const Item: TExprItem);
  var
    name: string;
    color: TColor;
  begin
    if TryStrToColor(Item.Value, name, color) then
    begin
      DrawString(Item.Expr + '=');
      DrawColor(color);
      DrawString(name);
    end
    else begin
      DrawTextValue(Item);
    end;
  end;

  procedure DrawAlphaColorValue(const Item: TExprItem);
  var
    name: string;
    color: TAlphaColor;
  begin
    if TryStrToAlphaColor(Item.Value, name, color) then
    begin
      DrawString(Item.Expr + '=');
      DrawAlphaColor(color);
      DrawString(name);
    end
    else begin
      DrawTextValue(Item);
    end;
  end;

begin
//  if not FDLightEnabled then
//  begin
//    Canvas.Brush.Style := bsClear;
//    Canvas.TextOut(TextRect.Right, TextRect.Top, '💩');
//    Canvas.Brush.Style := bsSolid;
//  end;

  if not FDLightEnabled then
    Exit;
  if (FCurrentBuffer = nil) or (View.Buffer <> FCurrentBuffer) then
    Exit;
  if (FLocalVariables.Count = 0) and (FWatchExpressions.Count = 0) then
    Exit;

  // Watch expressions
  lineTextUtf8 := UTF8String(LowerCase(string(UTF8String(LineText))));
  list := TList<TPair<Integer,TExprItem>>.Create;
  try
    for i := 0 to FWatchExpressions.Count-1 do
    begin
      exprUtf8 := UTF8String(FWatchExpressions[i].Expr.ToLower);
      p := Pos(exprUtf8, lineTextUtf8);
      if p = 0 then Continue;
      if LineAttributes[p-1] <> atIdentifier then Continue;
      if (p >= 2) and (LineAttributes[p-2] = atIdentifier) then Continue;
      lastPos := p + Length(exprUtf8) - 2;
      if (LineAttributes[lastPos] = atIdentifier) and
        (lastPos + 1 < Length(LineAttributes)) and (LineAttributes[lastPos + 1] = atIdentifier) then Continue;
      list.Add(TPair<Integer,TExprItem>.Create(p, FWatchExpressions[i]));
    end;
    list.Sort(TComparer<TPair<Integer,TExprItem>>.Construct(
      function(const Left, Right: TPair<Integer,TExprItem>): Integer
      begin
        Result := Left.Key - Right.Key;
      end));
    SetLength(dispItems, list.Count);
    for i := 0 to list.Count-1 do
    begin
      dispItems[i] := list[i].Value;
    end;
  finally
    list.Free;
  end;

  // Local variables
  lineTextUtf8 := UTF8String(LowerCase(string(UTF8String(LineText))));
  if not FHideLocalVarIfLineContainsExpr or (Length(dispItems) = 0) then
  begin
    idents := GetIdentifiers(LineText, TextWidth, LineAttributes);
    if FLocalVariables.Count > 0 then
    begin
      for i := Low(idents) to High(idents) do
      begin
        if FLocalVariables.TryGetValue(LowerCase(idents[i]), item) then
        begin
          item.Expr := idents[i];
          dispItems := dispItems + [item];
       end;
      end;
    end;
  end;

  if Length(dispItems) = 0 then Exit;

  x := FLeftGutter + (TextWidth - (View.LeftColumn - 1)) * CellSize.cx;
  y := TextRect.Top;

  clipRect := LineRect;
  clipRect.Left := FLeftGutter;
  rgn := CreateRectRgn(clipRect.Left, clipRect.Top, clipRect.Right, clipRect.Bottom);
  try
    SelectClipRgn(Canvas.Handle, rgn);
    try
      DrawPad;
      for i := Low(dispItems) to High(dispItems) do
      begin
        if i <> Low(dispItems) then
          DrawPad(2);

        item := dispItems[i];
        if item.TypeName = 'TColor' then
        begin
          DrawColorValue(item);
        end
        else if item.TypeName = 'TAlphaColor' then
        begin
          DrawAlphaColorValue(item);
        end
        else begin
          DrawTextValue(item);
        end;
      end;
      DrawPad;
    finally
      SelectClipRgn(Canvas.Handle, 0);
    end;
  finally
    DeleteObject(rgn);
  end;
end;

procedure TEditViewNotifier.EndPaint(const View: IOTAEditView);
begin
end;

procedure TEditViewNotifier.RemoveNotifier;
begin
  if Assigned(FEditView) and (FNotifierIndex >= 0) then
  begin
    FEditView.RemoveNotifier(FNotifierIndex);
    FNotifierIndex := -1;
    FEditView := nil;
{$IFDEF DEBUG}
    Dec(FEditViewNotifierCount);
{$ENDIF}
  end;
end;

{ TDebuggerNotifier }

constructor TDebuggerNotifier.Create(ADebugger: IOTADebugger);
begin
  inherited Create;

  FDebugger := ADebugger;
  FNotifierIndex := FDebugger.AddNotifier(Self);
{$IFDEF DEBUG}
  Inc(FDebuggerNotifierCount);
{$ENDIF}
end;

destructor TDebuggerNotifier.Destroy;
begin
  RemoveNotifier;
  inherited;
{$IFDEF DEBUG}
  Dec(FDebuggerNotifierCount);
{$ENDIF}
end;

procedure TDebuggerNotifier.Destroyed;
begin
  RemoveNotifier;
end;

procedure TDebuggerNotifier.RemoveNotifier;
begin
  if Assigned(FDebugger) and (FNotifierIndex >= 0) then
  begin
    FDebugger.RemoveNotifier(FNotifierIndex);
    FNotifierIndex := -1;
    FDebugger := nil;
  end;
end;

procedure WatchWindowProc(Self: TForm; var Message: TMessage); forward;

procedure TDebuggerNotifier.ProcessCreated(const Process: IOTAProcess);
begin
  FWatchWindow := TForm(Application.FindComponent('WatchWindow'));
  if FWatchWindow = nil then Exit;
  if Assigned(FOriginalWindowProc) then Exit;

  FOriginalWindowProc := FWatchWindow.WindowProc;
  FWatchWindow.WindowProc := TWndMethod(CreateMethod(FWatchWindow, @WatchWindowProc));
end;

procedure TDebuggerNotifier.ProcessDestroyed(const Process: IOTAProcess);
begin
  if Assigned(FWatchWindow) and Assigned(FOriginalWindowProc) then
  begin
    FWatchWindow.WindowProc := FOriginalWindowProc;
    FOriginalWindowProc := nil;
  end;

  FCurrentBuffer := nil;
  FLocalVariables.Clear;
  FWatchExpressions.Clear;
  FRepaintTimer.Enabled := True;
end;

procedure TDebuggerNotifier.BreakpointAdded(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.BreakpointDeleted(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.BreakpointChanged(const Breakpoint: IOTABreakpoint);
begin
end;

procedure TDebuggerNotifier.CurrentProcessChanged(const Process: IOTAProcess);
begin
end;

procedure GetLocalVariables;
var
  debuggerLocalVariables: IOTADebuggerLocalVariables;
  expressionInspector: IOTAExpressionInspector;
  i, memberCount: Integer;
  item: TExprItem;
begin
  FLocalVariables.Clear;
  if not FDLightEnabled then
    Exit;
  if not Supports(DebuggerManagerServices.CurrentDebugger, IOTADebuggerLocalVariables, debuggerLocalVariables) then
    Exit;
  if debuggerLocalVariables.InspectLocalVariables(expressionInspector) <> erOK then
    Exit;

  memberCount := expressionInspector.MemberCount[eimtData];
  for i := 0 to memberCount-1 do
  begin
    item := TExprItem.Create(expressionInspector, i);
    FLocalVariables.Add(LowerCase(item.Expr), item);
  end;
end;

procedure GetWatchExpressions;
var
  i: Integer;
  expr: TExprItem;
  watchTabs: TTabSet;
  list: TList;
  item: PWatchItem;
begin
  FWatchExpressions.Clear;

  if FWatchWindow = nil then Exit;
  watchTabs := TTabSet(FWatchWindow.FindComponent('WatchTabs'));
  if watchTabs = nil then Exit;
  if not Assigned(FWatchTabList) then Exit;
  if not Assigned(FWatchTabList^) then Exit;
  if watchTabs.TabIndex < 0 then Exit;
  if watchTabs.TabIndex >= FWatchTabList^.Count then Exit;

  list := TList(FWatchTabList^.Objects[watchTabs.TabIndex]);
  for i := 0 to list.Count-1 do
  begin
    item := list[i];
    if Assigned(item^.ExpressionInspector) then
    begin
      expr := TExprItem.Create(item^.ExpressionInspector);
      FWatchExpressions.Add(expr);
    end
    else if not item^.EvalErr then
    begin
      expr.Expr := item^.Expr;
      expr.Value := item^.Value;
      expr.TypeName := '';
      FWatchExpressions.Add(expr);
    end;
  end;
end;

procedure TDebuggerNotifier.ProcessStateChanged(const Process: IOTAProcess);
var
  view: IOTAEditView;
begin
  FDLightEnabled := False;

  view := (BorlandIDEServices as IOTAEditorServices).TopView;
  if view = nil then
  begin
    FCurrentBuffer := nil;
    FLocalVariables.Clear;
    FWatchExpressions.Clear;
    Exit;
  end;

  if Process.ProcessState <> psStopped then
  begin
    FRepaintTimer.Enabled := True;
    Exit;
  end;

  FDLightEnabled := True;
  FCurrentBuffer := view.Buffer;
  FRepaintTimer.Enabled := False;

  GetLocalVariables;
  FEvaluateTimer.Enabled := True;
end;

function TDebuggerNotifier.BeforeProgramLaunch(const Project: IOTAProject): Boolean;
begin
  Result := True;
end;

procedure TDebuggerNotifier.ProcessMemoryChanged;
begin
end;

{ TDebuggerManagerNotifier }

constructor TDebuggerManagerNotifier.Create;
var
  i: Integer;
begin
  inherited;
  FDebuggerNotifiers := TList<IOTADebuggerNotifier>.Create;
  for i := 0 to DebuggerManagerServices.DebuggerCount-1 do
    FDebuggerNotifiers.Add(TDebuggerNotifier.Create(DebuggerManagerServices.Debuggers[i]));
end;

destructor TDebuggerManagerNotifier.Destroy;
var
  i: Integer;
begin
  for i := 0 to FDebuggerNotifiers.Count-1 do
    FDebuggerNotifiers[i].Destroyed;
  FDebuggerNotifiers.Free;
  inherited;
end;

procedure TDebuggerManagerNotifier.DebuggerAdded(const Debugger: IOTADebugger);
begin
  FDebuggerNotifiers.Add(TDebuggerNotifier.Create(Debugger));
end;

procedure TDebuggerManagerNotifier.DebuggerRemoved(const Debugger: IOTADebugger);
var
  i: Integer;
begin
  for i := 0 to FDebuggerNotifiers.Count-1 do
    if (FDebuggerNotifiers[i] as TDebuggerNotifier).FDebugger = Debugger then
      FDebuggerNotifiers[i].Destroyed;
end;

procedure DoRepaint;
var
  i: Integer;
begin
  FRepaintAll := True;
  if FCurrentBuffer <> nil then
  begin
    for i := 0 to FCurrentBuffer.EditViewCount-1 do
      FCurrentBuffer.EditViews[i].Paint;
  end;
end;

procedure TimerRepaint(Self: TTimer; Sender: TObject);
begin
  Self.Enabled := False;
  DoRepaint;
  FCurrentBuffer := nil;
end;

procedure TimerEvaluate(Self: TTimer; Sender: TObject);
begin
  Self.Enabled := False;
  GetWatchExpressions;
  DoRepaint;
end;

procedure WatchWindowProc(Self: TForm; var Message: TMessage);
begin
  if (Message.Msg = $50D) and FDLightEnabled then
  begin
    FEvaluateTimer.Enabled := True;
  end;
  FOriginalWindowProc(Message);
end;

procedure MyWatchWindowAddWatch(Self: TObject; const Watch: string; aTabName: string);
begin
  FTrampolineWatchWindowAddWatch(Self, Watch, aTabName);
  if FDLightEnabled then
  begin
    FEvaluateTimer.Enabled := True;
  end;
end;

procedure GetWatchWindowInfo;
var
  ctx: TRttiContext;
  typ: TRttiType;
  coreIdePackageName: string;
  propWatchExpr: TRttiIndexedProperty;
  propWatchCount: TRttiProperty;
begin
  typ := ctx.FindType('WatchWin.TWatchWindow');
  if typ = nil then Exit;
  propWatchExpr := typ.GetIndexedProperty('WatchExpression');
  if propWatchExpr = nil then Exit;
  propWatchCount := typ.GetProperty('WatchItemCount');
  if propWatchCount = nil then Exit;

  FTWatchWindow_GetWatchItemCount := TRttiInstanceProperty(propWatchCount).PropInfo^.GetProc;
  coreIdePackageName := ExtractFileName(typ.Package.Name);
  @FTrampolineWatchWindowAddWatch := InterceptCreate(coreIdePackageName, '@Watchwin@TWatchWindow@AddWatch$qqrx20System@UnicodeString20System@UnicodeString', @MyWatchWindowAddWatch);
end;

function GetWatchTabList: PStringList;
var
  p: PByte;
begin
  Result := nil;

  if not Assigned(FTWatchWindow_GetWatchItemCount) then Exit;

  p := @FTWatchWindow_GetWatchItemCount;

  // PUSH EBX
  if p^ <> $53 then Exit;
  Inc(p);
  // MOV EBX,EAX
  if PWord(p)^ <> $D88B then Exit;
  Inc(p, 2);
  // MOV EAX,DWORD PTR [EBX+4A0] 4A0=WatchWin.TWatchWindow.WatchTabs
  if PWord(p)^ <> $838B then Exit;
  Inc(p, 2 + 4);
  // MOV EDX,DWORD PTR [EAX+2AC] 2AC=Vcl.Tabs.TTabSet.FTabIndex
  if PWord(p)^ <> $908B then Exit;
  Inc(p, 2 + 4);
  // MOV EAX,DWORD PTR [xxxxxxxx]
  if p^ <> $A1 then Exit;
  Inc(p);

  Result := PPointer(p)^;
end;

procedure Register;
var
  ctx: TRttiContext;
  typ: TRttiType;
  prop: TRttiProperty;
begin
  FDebuggerManagerNotifierIndex := DebuggerManagerServices.AddNotifier(TDebuggerManagerNotifier.Create);
  FIDENotifierIndex := (BorlandIDEServices as IOTAServices).AddNotifier(TIDENotifier.Create);

  FLocalVariables := TDictionary<string,TExprItem>.Create;
  FWatchExpressions := TList<TExprItem>.Create;
  FRepaintTimer := TTimer.Create(nil);
  FRepaintTimer.Enabled := False;
  FRepaintTimer.Interval := 150;
  FRepaintTimer.OnTimer := TNotifyEvent(CreateMethod(FRepaintTimer, @TimerRepaint));
  FEvaluateTimer := TTimer.Create(nil);
  FEvaluateTimer.Enabled := False;
  FEvaluateTimer.Interval := 50;
  FEvaluateTimer.OnTimer := TNotifyEvent(CreateMethod(FEvaluateTimer, @TimerEvaluate));
  GetWatchWindowInfo;
  FWatchTabList := GetWatchTabList;

  typ := ctx.FindType('EditorControl.TEditControl');
  if typ <> nil then
  begin
    prop := typ.GetProperty('LeftGutter');
    if prop <> nil then
      FLeftGutterProp := TRttiInstanceProperty(prop).PropInfo;
  end;

{$IFDEF DEBUG}
  OutputDebugString('DLight installed');
{$ENDIF}
end;

procedure Unregister;
begin
  if FDebuggerManagerNotifierIndex >= 0 then
    DebuggerManagerServices.RemoveNotifier(FDebuggerManagerNotifierIndex);
  if FIDENotifierIndex >= 0 then
    (BorlandIDEServices as IOTAServices).RemoveNotifier(FIDENotifierIndex);

  FRepaintTimer.Free;
  FEvaluateTimer.Free;
  FLocalVariables.Free;
  FWatchExpressions.Free;
  if Assigned(FTrampolineWatchWIndowAddWatch) then
    InterceptRemove(@FTrampolineWatchWIndowAddWatch);

{$IFDEF DEBUG}
  OutputDebugString(PChar(Format('EditorNotifierCount: %d', [FEditorNotifierCount])));
  OutputDebugString(PChar(Format('EditViewNotifierCount: %d', [FEditViewNotifierCount])));
  OutputDebugString(PChar(Format('DebuggerNotifierCount: %d', [FDebuggerNotifierCount])));

  OutputDebugString('DLight uninstalled');
{$ENDIF}
end;

initialization
finalization
  Unregister;
end.
