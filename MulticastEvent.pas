{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  Multicast event management classes

  Version 1.1.1 (2024-05-03)

  Last change 2024-10-04

  ©2015-2024 František Milt

  Contacts:
    František Milt: frantisek.milt@gmail.com

  Support:
    If you find this code useful, please consider supporting its author(s) by
    making a small donation using the following link(s):

      https://www.paypal.me/FMilt

  Changelog:
    For detailed changelog and history please refer to this git repository:

      github.com/TheLazyTomcat/Lib.MulticastEvent

  Dependencies:
    AuxClasses    - github.com/TheLazyTomcat/Lib.AuxClasses
  * AuxExceptions - github.com/TheLazyTomcat/Lib.AuxExceptions

  Library AuxExceptions is required only when rebasing local exception classes
  (see symbol MulticastEvent_UseAuxExceptions for details).

  Library AuxExceptions might also be required as an indirect dependency.

  Indirect dependencies:
    AuxTypes    - github.com/TheLazyTomcat/Lib.AuxTypes
    SimpleCPUID - github.com/TheLazyTomcat/Lib.SimpleCPUID
    StrRect     - github.com/TheLazyTomcat/Lib.StrRect
    UInt64Utils - github.com/TheLazyTomcat/Lib.UInt64Utils
    WinFileInfo - github.com/TheLazyTomcat/Lib.WinFileInfo

===============================================================================}
unit MulticastEvent;
{
  MulticastEvent_UseAuxExceptions

  If you want library-specific exceptions to be based on more advanced classes
  provided by AuxExceptions library instead of basic Exception class, and don't
  want to or cannot change code in this unit, you can define global symbol
  MulticastEvent_UseAuxExceptions to achieve this.
}
{$IF Defined(MulticastEvent_UseAuxExceptions)}
  {$DEFINE UseAuxExceptions}
{$IFEND}  

//------------------------------------------------------------------------------

{$IFDEF FPC}
  {$MODE ObjFPC}
  {$DEFINE FPC_DisableWarns}
  {$MACRO ON}
{$ENDIF}
{$H+}

interface

uses
  SysUtils,
  AuxClasses{$IFDEF UseAuxExceptions}, AuxExceptions{$ENDIF};

type
  EMCEException = class({$IFDEF UseAuxExceptions}EAEGeneralException{$ELSE}Exception{$ENDIF});

  EMCEIndexOutOfBounds = class(EMCEException);

{===============================================================================
--------------------------------------------------------------------------------
                                TMulticastEvent                                
--------------------------------------------------------------------------------
===============================================================================}
type
  TCallback = procedure;
  TEvent    = procedure of object;

  TMulticastEntry = record
    case IsMethod: Boolean of
      False:  (HandlerProcedure: TProcedure);
      True:   (HandlerMethod:    TMethod);
  end;

{===============================================================================
    TMulticastEvent - class declaration
===============================================================================}
type
  TMulticastEvent = class(TCustomListObject)
  protected
    fOwner:   TObject;
    fEntries: array of TMulticastEntry;
    fCount:   Integer;
    Function GetEntry(Index: Integer): TMulticastEntry; virtual;
    Function GetCapacity: Integer; override;
    procedure SetCapacity(Value: Integer); override;
    Function GetCount: Integer; override;
    procedure SetCount(Value: Integer); override;
  public
    constructor Create(Owner: TObject = nil);
    destructor Destroy; override;
    Function LowIndex: Integer; override;
    Function HighIndex: Integer; override;
    Function IndexOf(const Handler: TCallback): Integer; overload; virtual;
    Function IndexOf(const Handler: TEvent): Integer; overload; virtual;
    Function Find(const Handler: TCallback; out Index: Integer): Boolean; overload; virtual;
    Function Find(const Handler: TEvent; out Index: Integer): Boolean; overload; virtual;
    Function Add(const Handler: TCallback; AllowDuplicity: Boolean = False): Integer; overload; virtual;
    Function Add(const Handler: TEvent; AllowDuplicity: Boolean = False): Integer; overload; virtual;
    Function Remove(const Handler: TCallback; RemoveAll: Boolean = True): Integer; overload; virtual;
    Function Remove(const Handler: TEvent; RemoveAll: Boolean = True): Integer; overload; virtual;
    procedure Delete(Index: Integer); virtual;
    procedure Clear; virtual;
    procedure Call; overload; virtual;
    property Entries[Index: Integer]: TMulticastEntry read GetEntry;
    property Owner: TObject read fOwner;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                             TMulticastNotifyEvent                                                             
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TMulticastNotifyEvent - class declaration
===============================================================================}
type
  TMulticastNotifyEvent = class(TMulticastEvent)
  public
    Function IndexOf(const Handler: TNotifyCallback): Integer; reintroduce; overload;
    Function IndexOf(const Handler: TNotifyEvent): Integer; reintroduce; overload;
    Function Find(const Handler: TNotifyCallback; out Index: Integer): Boolean; reintroduce; overload;
    Function Find(const Handler: TNotifyEvent; out Index: Integer): Boolean; reintroduce; overload;
    Function Add(const Handler: TNotifyCallback; AllowDuplicity: Boolean = False): Integer; reintroduce; overload;
    Function Add(const Handler: TNotifyEvent; AllowDuplicity: Boolean = False): Integer; reintroduce; overload;
    Function Remove(const Handler: TNotifyCallback; RemoveAll: Boolean = True): Integer; reintroduce; overload;
    Function Remove(const Handler: TNotifyEvent; RemoveAll: Boolean = True): Integer; reintroduce; overload;
    procedure Call(Sender: TObject); reintroduce;
  end;

implementation

{$IFDEF FPC_DisableWarns}
  {$DEFINE FPCDWM}
  {$DEFINE W5024:={$WARN 5024 OFF}} // Parameter "$1" not used
{$ENDIF}

{===============================================================================
--------------------------------------------------------------------------------
                                TMulticastEvent                                
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TMulticastEvent - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    TMulticastEvent - protected methods
-------------------------------------------------------------------------------}

Function TMulticastEvent.GetEntry(Index: Integer): TMulticastEntry;
begin
If CheckIndex(Index) then
  Result := fEntries[Index]
else
  raise EMCEIndexOutOfBounds.CreateFmt('TMulticastEvent.GetEntry: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.GetCapacity: Integer;
begin
Result := Length(fEntries);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.SetCapacity(Value: Integer);
begin
If Value <> Length(fEntries) then
  begin
    If Value < Length(fEntries) then
      fCount := Value;
    SetLength(fEntries,Value);
  end;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.GetCount: Integer;
begin
Result := fCount;
end;

//------------------------------------------------------------------------------

{$IFDEF FPCDWM}{$PUSH}W5024{$ENDIF}
procedure TMulticastEvent.SetCount(Value: Integer);
begin
// do nothing
end;
{$IFDEF FPCDWM}{$POP}{$ENDIF}

{-------------------------------------------------------------------------------
    TMulticastEvent - public methods
-------------------------------------------------------------------------------}

constructor TMulticastEvent.Create(Owner: TObject = nil);
begin
inherited Create;
fOwner := Owner;
SetLength(fEntries,0);
fCount := 0;
// adjust growing, no need for fast growth
GrowMode := gmLinear;
GrowFactor := 16;
end;

//------------------------------------------------------------------------------

destructor TMulticastEvent.Destroy;
begin
Clear;
inherited;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.LowIndex: Integer;
begin
Result := Low(fEntries);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.HighIndex: Integer;
begin
Result := Pred(fCount);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.IndexOf(const Handler: TCallback): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If not fEntries[i].IsMethod then
    If @fEntries[i].HandlerProcedure = @Handler then
      begin
        Result := i;
        Break{For i};
      end;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastEvent.IndexOf(const Handler: TEvent): Integer;
var
  i:  Integer;
begin
Result := -1;
For i := LowIndex to HighIndex do
  If fEntries[i].IsMethod then
    If (fEntries[i].HandlerMethod.Code = TMethod(Handler).Code) and
       (fEntries[i].HandlerMethod.Data = TMethod(Handler).Data) then
      begin
        Result := i;
        Break{For i};
      end;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.Find(const Handler: TCallback; out Index: Integer): Boolean;
begin
Index := IndexOf(Handler);
Result := CheckIndex(Index);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastEvent.Find(const Handler: TEvent; out Index: Integer): Boolean;
begin
Index := IndexOf(Handler);
Result := CheckIndex(Index);
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.Add(const Handler: TCallback; AllowDuplicity: Boolean = False): Integer;
begin
If Assigned(Handler) then
  begin
    If not Find(Handler,Result) or AllowDuplicity then
      begin
        Grow;
        Result := fCount;
        fEntries[Result].IsMethod := False;
        fEntries[Result].HandlerProcedure := TProcedure(Handler);
        Inc(fCount);
      end;
  end
else Result := -1;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastEvent.Add(const Handler: TEvent; AllowDuplicity: Boolean = False): Integer;
begin
If Assigned(TMethod(Handler).Code) and Assigned(TMethod(Handler).Data) then
  begin
    If not Find(Handler,Result) or AllowDuplicity then
      begin
        Grow;
        Result := fCount;
        fEntries[Result].IsMethod := True;
        fEntries[Result].HandlerMethod := TMethod(Handler);
        Inc(fCount);
      end;
  end
else Result := -1;
end;

//------------------------------------------------------------------------------

Function TMulticastEvent.Remove(const Handler: TCallback; RemoveAll: Boolean = True): Integer;
begin
repeat
  If Find(Handler,Result) then
    Delete(Result);
until not RemoveAll or (Result < 0);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastEvent.Remove(const Handler: TEvent; RemoveAll: Boolean = True): Integer;
begin
repeat
  If Find(Handler,Result) then
    Delete(Result);
until not RemoveAll or (Result < 0);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Delete(Index: Integer);
var
  i:  Integer;
begin
If CheckIndex(Index) then
  begin
    For i := Index to Pred(HighIndex) do
      fEntries[i] := fEntries[i + 1];
    Dec(fCount);
    Shrink;
  end
else raise EMCEIndexOutOfBounds.CreateFmt('TMulticastEvent.Delete: Index (%d) out of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Clear;
begin
fCount := 0;
Shrink;
end;

//------------------------------------------------------------------------------

procedure TMulticastEvent.Call;
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  If fEntries[i].IsMethod then
    TEvent(fEntries[i].HandlerMethod)
  else
    TCallback(fEntries[i].HandlerProcedure);
end;


{===============================================================================
--------------------------------------------------------------------------------
                             TMulticastNotifyEvent                                                             
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    TMulticastNotifyEvent - class implementation
===============================================================================}  
{-------------------------------------------------------------------------------
    TMulticastNotifyEvent - public methods
-------------------------------------------------------------------------------}

Function TMulticastNotifyEvent.IndexOf(const Handler: TNotifyCallback): Integer;
begin
Result := inherited IndexOf(TCallback(Handler));
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastNotifyEvent.IndexOf(const Handler: TNotifyEvent): Integer;
begin
Result := inherited IndexOf(TEvent(Handler));
end;

//------------------------------------------------------------------------------

Function TMulticastNotifyEvent.Find(const Handler: TNotifyCallback; out Index: Integer): Boolean;
begin
Result := inherited Find(TCallback(Handler),Index);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastNotifyEvent.Find(const Handler: TNotifyEvent; out Index: Integer): Boolean;
begin
Result := inherited Find(TEvent(Handler),Index);
end;

//------------------------------------------------------------------------------

Function TMulticastNotifyEvent.Add(const Handler: TNotifyCallback; AllowDuplicity: Boolean = False): Integer;
begin
Result := inherited Add(TCallback(Handler),AllowDuplicity);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastNotifyEvent.Add(const Handler: TNotifyEvent; AllowDuplicity: Boolean = False): Integer;
begin
Result := inherited Add(TEvent(Handler),AllowDuplicity);
end;

//------------------------------------------------------------------------------

Function TMulticastNotifyEvent.Remove(const Handler: TNotifyCallback; RemoveAll: Boolean = True): Integer;
begin
Result := inherited Remove(TCallback(Handler),RemoveAll);
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function TMulticastNotifyEvent.Remove(const Handler: TNotifyEvent; RemoveAll: Boolean = True): Integer;
begin
Result := inherited Remove(TEvent(Handler),RemoveAll);
end;

//------------------------------------------------------------------------------

procedure TMulticastNotifyEvent.Call(Sender: TObject);
var
  i:  Integer;
begin
For i := LowIndex to HighIndex do
  If fEntries[i].IsMethod then
    TNotifyEvent(fEntries[i].HandlerMethod)(Sender)
  else
    TNotifyCallback(fEntries[i].HandlerProcedure)(Sender);
end;

end.
