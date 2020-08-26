unit MessageRegistration;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions;

type
MessageState = (
	msEmpty      = -1,
	msSuccesfull = 0,
	msWarning    = 1,
	msInfo       = 2,
	msError      = 3,
	msWait       = 4,
	msHint       = 5

);

MessageRegistrator = class
private
  DebugMessage : Boolean;
public
  constructor Create;
  procedure setDebugMode(dstate : Boolean);
  function getDebugMode(): Boolean;
  procedure AddMessage(description : string; mstate: MessageState; param: TStringList = nil); virtual;
  procedure Status(_message_ : string); virtual;

  procedure AddError(description : string); overload;

  procedure AddError(description : string; parname1: string; par1: string); overload;

  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string); overload;

  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string;
                         parname3: string; par3: string); overload;

  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string;
                         parname3: string; par3: string;
                         parname4: string; par4: string); overload;
  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string;
                         parname3: string; par3: string;
                         parname4: string; par4: string;
                         parname5: string; par5: string); overload;
  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string;
                         parname3: string; par3: string;
                         parname4: string; par4: string;
                         parname5: string; par5: string;
                         parname6: string; par6: string); overload;
  procedure AddError(description : string;
                         parname1: string; par1: string;
                         parname2: string; par2: string;
                         parname3: string; par3: string;
                         parname4: string; par4: string;
                         parname5: string; par5: string;
                         parname6: string; par6: string;
                         parname7: string; par7: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string;
                            parname3: string; par3: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string;
                            parname3: string; par3: string;
                            parname4: string; par4: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string;
                            parname3: string; par3: string;
                            parname4: string; par4: string;
                            parname5: string; par5: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string;
                            parname3: string; par3: string;
                            parname4: string; par4: string;
                            parname5: string; par5: string;
                            parname6: string; par6: string); overload;

  procedure AddMessage_(description : string; mstate: MessageState;
                            parname1: string; par1: string;
                            parname2: string; par2: string;
                            parname3: string; par3: string;
                            parname4: string; par4: string;
                            parname5: string; par5: string;
                            parname6: string; par6: string;
                            parname7: string; par7: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string;
                                 parname3: string; par3: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string;
                                 parname3: string; par3: string;
                                 parname4: string; par4: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string;
                                 parname3: string; par3: string;
                                 parname4: string; par4: string;
                                 parname5: string; par5: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string;
                                 parname3: string; par3: string;
                                 parname4: string; par4: string;
                                 parname5: string; par5: string;
                                 parname6: string; par6: string); overload;

  procedure AddDebugMessage_(description : string; mstate: MessageState;
                                 parname1: string; par1: string;
                                 parname2: string; par2: string;
                                 parname3: string; par3: string;
                                 parname4: string; par4: string;
                                 parname5: string; par5: string;
                                 parname6: string; par6: string;
                                 parname7: string; par7: string); overload;



end;

implementation

{ MessageRegistrator }

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2,
      parname3, par3,
      parname4, par4,
      parname5, par5);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2,
      parname3, par3,
      parname4, par4);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5, parname6, par6, parname7, par7: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2,
      parname3, par3,
      parname4, par4,
      parname5, par5,
      parname6, par6,
      parname7, par7);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5, parname6, par6: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2,
      parname3, par3,
      parname4, par4,
      parname5, par5,
      parname6, par6);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState);
begin
  if not DebugMessage then
    Exit;
  AddMessage(description, mstate);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2,
      parname3, par3);
end;

procedure MessageRegistrator.AddDebugMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2: string);
begin
  if not DebugMessage then
    Exit;
  AddMessage_(description, mstate,
      parname1, par1,
      parname2, par2);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2, parname3, par3, parname4, par4, parname5, par5: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2, parname3, par3, parname4, par4: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2, parname3, par3, parname4, par4, parname5, par5, parname6, par6,
  parname7, par7: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  ts.Add(parname6 + ' = ' + par6);
  ts.Add(parname7 + ' = ' + par7);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2, parname3, par3, parname4, par4, parname5, par5, parname6, par6: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  ts.Add(parname6 + ' = ' + par6);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description, parname1, par1: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description: string);
begin
  AddMessage(description, msError);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2, parname3, par3: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddError(description, parname1, par1, parname2,
  par2: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  AddMessage(description, msError, ts);
end;

procedure MessageRegistrator.AddMessage(description: string;
  mstate: MessageState; param: TStringList);
begin

end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  AddMessage(description, mstate, ts);
end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  AddMessage(description, mstate, ts);
end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  AddMessage(description, mstate, ts);
end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  AddMessage(description, mstate, ts);
end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  AddMessage(description, mstate, ts);
end;



procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5, parname6, par6, parname7, par7: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  ts.Add(parname6 + ' = ' + par6);
  ts.Add(parname7 + ' = ' + par7);
  AddMessage(description, mstate, ts);
end;

procedure MessageRegistrator.AddMessage_(description: string;
  mstate: MessageState; parname1, par1, parname2, par2, parname3, par3,
  parname4, par4, parname5, par5, parname6, par6: string);
var
  ts: TStringList;
begin
  ts:= TStringList.Create;
  ts.Add(parname1 + ' = ' + par1);
  ts.Add(parname2 + ' = ' + par2);
  ts.Add(parname3 + ' = ' + par3);
  ts.Add(parname4 + ' = ' + par4);
  ts.Add(parname5 + ' = ' + par5);
  ts.Add(parname6 + ' = ' + par6);
  AddMessage(description, mstate, ts);
end;

constructor MessageRegistrator.Create;
begin
  DebugMessage := False;
end;

function MessageRegistrator.getDebugMode: Boolean;
begin
  Result := DebugMessage;
end;

procedure MessageRegistrator.setDebugMode(dstate: Boolean);
begin
  DebugMessage := dstate;
end;

procedure MessageRegistrator.Status(_message_: string);
begin

end;

end.
