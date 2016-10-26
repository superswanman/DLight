unit UDLight.Utils;

interface

uses
  System.SysUtils;

type
  TUIString = (uisDebuggerOptions);
  TUILanguage = (uilUnknown, uilJapanese, uilEnglish, uilGerman, uilFrench);

function CreateMethod(Self: TObject; Proc: Pointer): TMethod;
function GetUIString(Value: TUIString): string;

implementation

const
  UI_STRINGS: array[TUIString] of array[uilJapanese..uilFrench] of string = (
    ('デバッガ オプション', 'Debugger Options', 'Debugger-Optionen', 'Options du débogueur')
  );

var
  FUILanguage: TUILanguage = uilUnknown;

function CreateMethod(Self: TObject; Proc: Pointer): TMethod;
begin
  TMethod(Result).Code := Proc;
  TMethod(Result).Data := Self;
end;

function GetUIString(Value: TUIString): string;
const
  UI_LANGS: array[uilJapanese..uilFrench] of string = ('JA', 'EN', 'DE', 'FR');

  function TryStrToLang(const Value: string; out Language: TUILanguage): Boolean;
  var
    lang: TUILanguage;
  begin
    for lang := Low(UI_LANGS) to High(UI_LANGS) do
      if SameText(UI_LANGS[Lang], Value) then
      begin
        Language := lang;
        Exit(True);
      end;
    Result := False;
  end;

  function GetLanguage: TUILanguage;
  var
    s: string;
    lang: TUILanguage;
  begin
    for s in PreferredUILanguageList do
      if TryStrToLang(s, lang) then
        Exit(lang);
    Result := uilEnglish;
  end;

begin
  if FUILanguage = uilUnknown then
    FUILanguage := GetLanguage;
  Result := UI_STRINGS[Value][FUILanguage];
end;

end.