unit UDLight.Utils;

interface

function CreateMethod(Self: TObject; Proc: Pointer): TMethod;

implementation

function CreateMethod(Self: TObject; Proc: Pointer): TMethod;
begin
  TMethod(Result).Code := Proc;
  TMethod(Result).Data := Self;
end;

end.