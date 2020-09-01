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
	v1C_min     = 0,
	v1C_8_0     = 1,
	v1C_8_1     = 2,
	v1C_8_2     = 3,
	v1C_8_2_14  = 4,
	v1C_8_3_1   = 5,
	v1C_8_3_2   = 6,
	v1C_8_3_3   = 7,
	v1C_8_3_4   = 8,
	v1C_8_3_5   = 9,
	v1C_8_3_6   = 10,
	v1C_8_3_7   = 11,
	v1C_8_3_8   = 12,
	v1C_8_3_9   = 13,
	v1C_8_3_10  = 14,
	v1C_8_3_11  = 15,
	v1C_8_3_12  = 16,
	v1C_8_3_13  = 17,
	v1C_8_3_14  = 18,
	v1C_8_3_15  = 19,
	v1C_8_3_16  = 20,
	v1C_8_3_17  = 21,
	v1C_8_3_18  = 22

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

//T_Class = class
//
//end;


Value1C_metaobj = class;



//---------------------------------------------------------------------------
// Объект метаданных
MetaObject = class(MetaBase)
protected
  ffullname: String;
  fefullname: String;
  fuid: TGUID;
  fvalue: Value1C_metaobj;
public
  //static
  class var map: TDictionary<TGUID, MetaObject>;
  class var smap: TDictionary<String, MetaObject>;
  constructor Create(_uid: TGUID; _value: Value1C_metaobj); overload;
  constructor Create(_uid: TGUID; _value: Value1C_metaobj; _name: string; _ename : string); overload;
  procedure setfullname(_fullname: string);
  procedure setefullname(_efullname: string);

  property fullname : string read ffullname;
  property efullname: string read fefullname;
  property uid: TGUID read fuid;
  property value: Value1C_metaobj read fvalue;
  function getfullname(english: Boolean = False): string;
end;

Value1C_metaobj = class

end;

//---------------------------------------------------------------------------
// Генерируемый тип
MetaGeneratedType = class(MetaBase)
protected
  fwoprefix :Boolean;
public
  property woprefix :Boolean  read fwoprefix;
  constructor Create(_name: string; _ename: string); overload;
  constructor Create(tr: tree); overload;
end;

//---------------------------------------------------------------------------
// Право
MetaRight = class(MetaBase)
protected
  fuid: TGUID;
  fver1C: Version1C;
public
  class var map: TDictionary<TGUID, MetaRight>;
  class var smap: TDictionary<string, MetaRight>;
  constructor Create(tr: tree);
  class function getright(_uid: TGUID): MetaRight; overload; static;
  class function getright(_name: string): MetaRight; overload; static;
  property uid:TGUID  read fuid;
  property ver1C: Version1C read fver1C;
end;

//---------------------------------------------------------------------------
// Стандартный реквизит
MetaStandartAttribute = class(MetaBase)
protected
  fvalue: Integer;
  fcount: Boolean;
  fvaluemax: Integer;
  fuid: TGUID;
public
  constructor Create(tr: tree); overload;
  constructor Create(_name: string; _ename: string); overload;
  property value   : Integer  read fvalue;
  property valuemax: Integer  read fvaluemax;
  property count   : Boolean  read fcount;
  property uid     : TGUID    read fuid;
end;


//---------------------------------------------------------------------------
// Стандартная табличная часть
MetaStandartTabularSection = class(MetaBase)
protected
  fvalue: Integer;
  f_class : T_Class;
public
  class_uid: TGUID;
  class var list: TArray<MetaStandartTabularSection>;
  constructor Create(tr: tree); overload;
  constructor Create(_name: string; _ename: string); overload;
  property value   : Integer  read fvalue;
  property _class  : T_Class  read f_class write f_class;
end;

//---------------------------------------------------------------------------
// Параметры классов
ClassParameter = class
private
  fname: string;
  class var map: TDictionary<string, ClassParameter>;
public
  property name: string  read fname;
  constructor Create(tr: tree); overload;
  class function getparam(paramname: string): ClassParameter;
end;

//---------------------------------------------------------------------------
// Допустимое значение переменной дерева сериализации
//struct VarValidValue
//{
//	int value;
//	Version1C ver1C;
//	int globalvalue;
//};
VarValidValue = record
  value: Integer;
  ver1C: Version1C;
  globalvalue: Integer;
end;


TArray_MetaStandartAttribute      = TArray<MetaStandartAttribute>;
TArray_MetaStandartTabularSection = TArray<MetaStandartTabularSection>;
//---------------------------------------------------------------------------
// Классы
T_Class = class
private
  fuid : TGUID;
  fvervalidvalues: TArray<VarValidValue>;
  fparamvalues: TDictionary<ClassParameter, Integer>;
  class var map: TDictionary<TGUID, T_Class>;
  fstandartattributes: TArray_MetaStandartAttribute;
  fstandarttabularsections: TArray_MetaStandartTabularSection;
public
  constructor Create(tr: tree);
  destructor Destroy;

  function GetStandartAttributes: TArray_MetaStandartAttribute;
  function GetStandartTabularSection: TArray_MetaStandartTabularSection;
  function getparamvalue(p: ClassParameter): Integer;
  class function getclass(id: TGUID): T_Class;

  property uid : TGUID  read fuid;
  property vervalidvalues: TArray<VarValidValue>  read fvervalidvalues;
  property paramvalues: TDictionary<ClassParameter, Integer>  read fparamvalues;

  property standartattributes: TArray_MetaStandartAttribute  read GetStandartAttributes;
  property standarttabularsections: TArray_MetaStandartTabularSection read GetStandartTabularSection;
end;

//---------------------------------------------------------------------------
// Экземпляр класса
ClassItem = class
private
  fcl: T_Class;
  fversionisset: Boolean;
  fversion: Integer;
  procedure setversion(value: Integer);
  function getversion(): Integer;
public
  constructor Create(_cl: T_Class);
  property cl : T_Class  read fcl;
  property version: Integer  read getversion write setversion;
end;

//---------------------------------------------------------------------------
// Переменная дерева сериализации
SerializationTreeVar = class
private
  fname: string;
  fcolcount: Boolean;
  fisglobal: Boolean;
  fisfix: Boolean;
  ffixvalue: Integer;
  fvalidvalues: TArray<VarValidValue>;
public
  constructor Create(tr: tree);

  property name : string read fname;
  property colcount: Boolean  read fcolcount;
  property isglobal: Boolean  read fisglobal;
  property isfix   : Boolean  read fisfix;
  property fixvalue: Integer  read ffixvalue;
  property validvalues: TArray<VarValidValue>  read fvalidvalues;

end;




//////////////////////////////////////////////////////////////////////////
// Процедуры и функции
//////////////////////////////////////////////////////////////////////////
function stringtover1C(s: string): Version1C;



implementation

function stringtover1C(s: string): Version1C;
begin
  if s.IsEmpty then
  begin
    Result := v1C_min;
    Exit;
  end;
  if s = '8.0' then
  begin
    Result := v1C_8_0;
    Exit;
  end;
  if s = '8.1' then
  begin
    Result := v1C_8_1;
    Exit;
  end;
  if s = '8.2' then
  begin
    Result := v1C_8_2;
    Exit;
  end;
  if s = '8.2.14' then
  begin
    Result := v1C_8_2_14;
    Exit;
  end;
  if s = '8.3.1' then
  begin
    Result := v1C_8_3_1;
    Exit;
  end;
  if s = '8.3.2' then
  begin
    Result := v1C_8_3_2;
    Exit;
  end;
  if s = '8.3.3' then
  begin
    Result := v1C_8_3_3;
    Exit;
  end;
  if s = '8.3.4' then
  begin
    Result := v1C_8_3_4;
    Exit;
  end;
  if s = '8.3.5' then
  begin
    Result := v1C_8_3_5;
    Exit;
  end;
  if s = '8.3.6' then
  begin
    Result := v1C_8_3_6;
    Exit
  end;
  Result := v1C_min;

end;



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
  fvalueUID := StringToGUID(tt.get_value);
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
  guid := StringToGUID(tt.get_value);
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

{ MetaObject }

constructor MetaObject.Create(_uid: TGUID; _value: Value1C_metaobj);
begin
  fuid := _uid;
  fvalue := _value;
end;

constructor MetaObject.Create(_uid: TGUID; _value: Value1C_metaobj; _name,
  _ename: string);
begin
  inherited Create(_name, ename);
  fuid := _uid;
  fvalue := _value;
end;

function MetaObject.getfullname(english: Boolean): string;
begin
  if english then
    Result := fefullname
  else
    Result := ffullname;
end;

procedure MetaObject.setefullname(_efullname: string);
begin
  fefullname := _efullname;
end;

procedure MetaObject.setfullname(_fullname: string);
begin
  ffullname := _fullname;
end;

{ MetaGeneratedType }

constructor MetaGeneratedType.Create(tr: tree);
var
  tt: tree;
begin
  tt := tt.get_first;
  fname := tt.get_value;
  tt := tt.get_next;
  fename := tt.get_value;
  tt := tt.get_next;
  //fwoprefix := tt.get_value.CompareTo()
  if tt.get_value.CompareTo('1') = 0 then
    fwoprefix := True
  else
    fwoprefix := False;
end;

constructor MetaGeneratedType.Create(_name, _ename: string);
begin
  inherited Create(_name, _ename);
end;

{ MetaRight }

constructor MetaRight.Create(tr: tree);
var
  tt: tree;
begin
  tt := tr.get_first;
  fname := tt.get_value;
  tt := tt.get_next;
  fename := tt.get_value;
  tt := tt.get_next;
  // string_to_GUID(tt.get_value, fuid); Надо доделать!!!!!!!!!!!!
  fuid := StringToGUID(tt.get_value);
  tt := tt.get_next;
  fver1C := stringtover1C(tt.get_value); //Надо доделать!!!!!!!!!!!!
  if fver1C = v1C_min then
  begin
      //		error(L"Ошибка загрузки статических типов. Некорректное значение версии 1C в описании права"
      //			, L"Право", fname
      //			, L"Значение", tt->get_value());
  end;
  map[fuid] := Self;
  smap[fname] := Self;
  smap[fename] := Self;
end;

class function MetaRight.getright(_uid: TGUID): MetaRight;
begin
  if not map.TryGetValue(_uid, Result) then
    Result := nil;
end;

class function MetaRight.getright(_name: string): MetaRight;
begin
  if not smap.TryGetValue(_name, Result) then
    Result := nil;
end;

{ MetaStandartAttribute }

constructor MetaStandartAttribute.Create(_name, _ename: string);
begin
  inherited Create(_name,_ename);
  fcount := False;
end;

constructor MetaStandartAttribute.Create(tr: tree);
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
  if tt.get_value.CompareTo('1') = 0 then
    fcount := True
  else
    fcount := False;

  tt := tt.get_next;
  fvaluemax := tt.get_value.ToInteger();

  tt := tt.get_next;
  fuid := StringToGUID(tt.get_value);

end;

{ MetaStandartTabularSection }

constructor MetaStandartTabularSection.Create(_name, _ename: string);
begin
  inherited Create(_name, _ename);
  f_class   := nil;
  class_uid := TGUID.Empty;
end;

constructor MetaStandartTabularSection.Create(tr: tree);
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
  class_uid := StringToGUID(tt.get_value);

  SetLength(list, 1);
  list[0] := Self;

end;

{ ClassParameter }

constructor ClassParameter.Create(tr: tree);
var
  tt: tree;
begin
  tt := tr.get_first;
  fname := tt.get_value;

  map[fname] := Self;
end;

class function ClassParameter.getparam(paramname: string): ClassParameter;
begin
  if not map.TryGetValue(paramname, Result) then
    Result := nil;
end;

{ T_Class }

procedure LoadValidValues(tr: tree; validvalues: TArray<VarValidValue>; haveglobal: Boolean = False);
var
  tt: tree;
  i,count: Integer;
  s: string;
  vvv: VarValidValue;
begin
  tt := tr.get_first;
  count := tt.get_value.ToInteger();
  for i := 0 to count do
  begin
    tt := tt.get_next;
    vvv.value := tt.get_value.ToInteger();
    tt := tt.get_next;
    s := tt.get_value;
    if s.IsEmpty then
      vvv.ver1C := v1C_min
    else
    begin
      vvv.ver1C := stringtover1C(s);
      if vvv.ver1C = v1C_min then
      begin
        //				error(L"Ошибка загрузки статических типов. Некорректное значение версии 1C в допустимых значениях переменной дерева сериализации"
        //					//, L"Переменная", fname
        //					, L"Значение", s);
      end;
    end;
    if haveglobal then
    begin
      tt := tt.get_next;
      vvv.globalvalue := tt.get_value.ToInteger();
    end;
    SetLength(validvalues, i);
    validvalues[i] := vvv;
  end;
end;

constructor T_Class.Create(tr: tree);
var
  tt, t: tree;
  i,j,count: Integer;
  s: string;
  p: ClassParameter;
begin
  tt := tr.get_first;
  fuid := StringToGUID(tt.get_value);

  tt := tt.get_next;
  LoadValidValues(tt, fvervalidvalues); // Надо доделать!

  tt := tt.get_next;
  t := tt.get_first;
  count := t.get_value.ToInteger();
  for i := 0 to count do
  begin
    t := t.get_next;
    s := t.get_value;
    t := t.get_next;
    p := ClassParameter.getparam(s);
    if not Assigned(p) then
    begin
      //			error(L"Ошибка загрузки статических типов. Некорректное имя параметра класса"
      //				, L"Параметр", s);
    end
    else
    begin
      j := t.get_value.ToInteger();
      fparamvalues[p] := j;
    end;
  end;

  // Стандартные реквизиты
  tt := tt.get_next;
  t := tt.get_first;
  count := t.get_value.ToInteger();
  for i := 0 to count do
  begin
    t := t.get_next;
    SetLength(fstandartattributes, i);
    fstandartattributes[i] := MetaStandartAttribute.Create(t);
  end;

  // Стандартные табличные части
  tt := tt.get_next;
  t := tt.get_first;
  count := t.get_value.ToInteger();
  for i := 0 to count do
  begin
    t := t.get_next;
    SetLength(fstandarttabularsections, i);
    //fstandartattributes[i] := MetaStandartAttribute.Create(t);
    fstandarttabularsections[i] := MetaStandartTabularSection.Create(t);
  end;

end;

destructor T_Class.Destroy;
var
  j: Integer;
begin

  for j := 0 to Length(fstandartattributes) do
  begin
    fstandartattributes[j].Free;
  end;

end;

class function T_Class.getclass(id: TGUID): T_Class;
begin
  if not map.TryGetValue(id, Result) then
    Result := nil;
end;

function T_Class.getparamvalue(p: ClassParameter): Integer;
begin
  if not fparamvalues.TryGetValue(p, Result) then
    Result := -1;
end;

function T_Class.GetStandartAttributes: TArray_MetaStandartAttribute;
begin
  Result := fstandartattributes;
end;

function T_Class.GetStandartTabularSection: TArray_MetaStandartTabularSection;
begin
  Result := fstandarttabularsections;
end;

{ ClassItem }

constructor ClassItem.Create(_cl: T_Class);
begin
  fcl := _cl;
  fversionisset := False;
end;

function ClassItem.getversion: Integer;
begin
  if fversionisset then
  begin
    Result := fversion;
    Exit;
  end;

  //error(L"Ошибка формата потока 117. Ошибка получения значения переменной ВерсияКласса. Значение не установлено.");
  Result := -1;
end;

procedure ClassItem.setversion(value: Integer);
begin
  fversion := value;
  fversionisset := True;
  //Result := value;
end;

{ SerializationTreeVar }

constructor SerializationTreeVar.Create(tr: tree);
var
  tt: tree;
begin
  tt := tr.get_first;
  fname := tt.get_value;

  tt := tt.get_next;
  if tt.get_value.CompareTo('1') = 0 then
    fcolcount := True
  else
    fcolcount := False;

  tt := tt.get_next;
  if tt.get_value.CompareTo('1') = 0 then
    fisglobal := True
  else
    fisglobal := False;

  tt := tt.get_next;
  if tt.get_value.CompareTo('1') = 0 then
    fisfix := True
  else
    fisfix := False;

  tt := tt.get_next;
  ffixvalue := tt.get_value.ToInteger();
  tt := tt.get_next;
  LoadValidValues(tt, fvalidvalues, True);
end;

end.
