unit MetaData;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions, System.Syncobjs, System.Generics.Collections,
     System.WideStrUtils, ZZlib, APIcfBase, Parse_tree;


type
//---------------------------------------------------------------------------
// Версии контейнера 1С
// значения версий должны обязательно располагаться по возрастанию, чтобы можно было сравнивать версии на >, < и =
ContainerVer = (
	cv_2_0   = 1,
	cv_5_0   = 2,
	cv_6_0   = 3,
	cv_106_0 = 4,
	cv_200_0 = 5,
	cv_202_2 = 6,
	cv_216_0 = 7

);

//---------------------------------------------------------------------------
// Версии 1С
// значения версий должны обязательно располагаться по возрастанию, чтобы можно было сравнивать версии на >, < и =
Version1C = (
	v1C_min    = 0,
	v1C_8_0    = 1,
	v1C_8_1    = 2,
	v1C_8_2    = 3,
	v1C_8_2_14 = 4,
	v1C_8_3_1  = 5,
	v1C_8_3_2  = 6,
	v1C_8_3_3  = 7,
	v1C_8_3_4  = 8,
	v1C_8_3_5  = 9,
	v1C_8_3_6  = 10

);

//---------------------------------------------------------------------------
// Способы выгрузки
ExportType =
(
	et_default = 0,
	et_catalog = 1,
	et_file    = 2
);

//---------------------------------------------------------------------------
// Базовый класс метаданных 1С
MetaBase = class
protected
  fname: string;
  fename: string;
public
  constructor Create(); overload;
  constructor Create(_name: string;_ename:string); overload;
  destructor Destroy;
  procedure setname(_name: string);
  procedure setename(_ename: string);
  property name : string read fname;
  property ename: string read fename;
  function getname(english: Boolean = False): string;

end;

MetaType = class;

//---------------------------------------------------------------------------
// Предопределенное значение метаданных
MetaValue = class(MetaBase)
protected
  owner: MetaType;
  fvalue: Integer;
  fvalueUID: TGUID;
public
  constructor Create(_owner: MetaType; _name: string; _ename: string; _value: Integer); overload;
  constructor Create(_owner: MetaType; tr: tree); overload;
  destructor Destroy;
  property value    : Integer read fvalue;
  property valueUID : TGUID   read fvalueUID;
  function getowner(): MetaType;
end;

MetaType = class

end;

//---------------------------------------------------------------------------
// Виды значений по умолчанию
DefaultValueType =
(
	dvt_novalue = 0, // Нет значения по умолчанию
	dvt_bool    = 1, // Булево
	dvt_number  = 2, // Число
	dvt_string  = 3, // Строка
	dvt_date    = 4, // Дата
	dvt_undef   = 5, // Неопределено
	dvt_null    = 6, // Null
	dvt_type    = 7, // Тип
	dvt_enum    = 8 // Значение системного перечисления
);

dv_val = record
  case _dv_val : 1..6 of
    1: (dv_bool   : Boolean);
    2: (dv_number : Integer);
    3: (dv_string : PAnsiChar);
    4: (dv_date   : array[0..6] of AnsiChar);
    5: (dv_type   : MetaType);
    6: (dv_enum   : MetaValue);
end;


T_Class = class;

//---------------------------------------------------------------------------
// Свойство метаданных
MetaProperty = class(MetaBase)
protected
  ftypes: TArray<MetaType>;
  fstypes: TArray<string>;
  owner: MetaType;
  fpredefined: Boolean;
  fexporttype : ExportType;
  f_class : T_Class;
public
  defaultvaluetype : DefaultValueType;
  _dv_val: dv_val;
  constructor Create(_owner: MetaType; _name: string; _ename: string); overload;
  constructor Create(_owner: MetaType; tr: tree); overload;
  destructor Destroy;
  procedure filltypes;
  property types: TArray<MetaType> read ftypes;
  property predefined: Boolean read fpredefined;
  property exporttype: ExportType read fexporttype;
  property _class: T_Class read f_class;
  function getowner(): MetaType;
end;

T_Class = class

end;


implementation



{ MetaBase }

constructor MetaBase.Create(_name, _ename: string);
begin
  _name := _name;
  _ename := _ename;
end;

constructor MetaBase.Create;
begin
  inherited;
end;

destructor MetaBase.Destroy;
begin
  inherited;
end;

function MetaBase.getname(english: Boolean): string;
begin
  if english then
    Result := fename
  else
    Result := fname;

end;

procedure MetaBase.setename(_ename: string);
begin
  fename := _ename;
end;

procedure MetaBase.setname(_name: string);
begin
  fname := _name;
end;

{ MetaValue }

constructor MetaValue.Create(_owner: MetaType; _name, _ename: string;
  _value: Integer);
begin
  inherited Create(_name, _ename);
  owner := _owner;
  fvalue := _value;
end;

constructor MetaValue.Create(_owner: MetaType; tr: tree);
var
  tt: tree;
begin
  tt := tr.get_first;
  fname := tt.get_value;

  tt := tt.get_next;
  fename := tt.get_value;

  tt := tt.get_next;
  fvalue := tt.get_value.ToInteger();

  tt := tt.get_next;
  // string_to_GUID(tt.get_value, fvalueUID); Надо доделать!!!!!!!!!!!!!!!

end;

destructor MetaValue.Destroy;
begin
  inherited;
end;

function MetaValue.getowner: MetaType;
begin
  Result := owner;
end;

{ MetaProperty }

constructor MetaProperty.Create(_owner: MetaType; _name, _ename: string);
begin
  inherited Create(_name, _ename);
  owner := _owner;
end;

constructor MetaProperty.Create(_owner: MetaType; tr: tree);
var
  tt, t : tree;
  num, i : Integer;
  guid : TGUID;
begin
  tt := tt.get_first;
  fname := tt.get_value;

  tt := tt.get_next;
  fename := tt.get_value;

  tt := tt.get_next;
  if tt.get_value.CompareTo('1') = 0 then
    fpredefined :=  True
  else
    fpredefined :=  False;

  tt := tt.get_next;
  // string_to_GUID(tt.get_value, guid); // Надо доделать!!!!!!!!!!!!
  // f_class := T_Class.getclass(guid);    // Надо доделать!!!!!!!!!!!!

  // Типы
  tt := tt.get_next;
  t := tt.get_first;
  num := t.get_value.ToInteger();
  SetLength(fstypes, num);
  for i := 0 to num do
  begin
    t := t.get_next;
    fstypes[i] := t.get_value;
  end;

  defaultvaluetype := dvt_novalue;
end;

destructor MetaProperty.Destroy;
begin
  inherited Destroy;
end;

procedure MetaProperty.filltypes;
var
   i : Integer;
begin
  SetLength(ftypes, Length(fstypes));
  for i := 0 to Length(fstypes) do
  begin
    //ftypes[i] := owner.TypeSet.getTypeByName(i)); // Надо доделать!!!!!!!!!!!!
  end;

end;

function MetaProperty.getowner: MetaType;
begin
  Result := owner;
end;

end.
