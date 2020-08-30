unit ConfigStorage;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions, System.Syncobjs, System.Generics.Collections, System.WideStrUtils, ZZlib, APIcfBase;

type
//---------------------------------------------------------------------------
// Структура открытого файла адаптера контейнера конфигурации
//struct CongigFile
//{
//	TStream* str;
//	void* addin;
//};

table_file_packed = (
  tfp_unknown,
  tfp_no,
  tfp_yes
);

//PConfigFile = ^ConfigFile;
ConfigFile = record
  str: TStream;
  addin : Pointer;
end;

//---------------------------------------------------------------------------
// Структура адреса файла таблицы-контейнера файлов
table_blob_file = record
  blob_start : Integer;
  blob_length : Integer;
end;

//---------------------------------------------------------------------------
// Структура записи таблицы контейнера файлов
table_rec = record
  name: string;
  addr: table_blob_file;
  partno: Integer;
  ft_create: FILETIME;
  ft_modify: FILETIME;
end;

table = class; // надо определить

//---------------------------------------------------------------------------
// Структура файла таблицы контейнера файлов
table_file = class
public
  t: table;
  name: string;
  maxpartno: Integer;
  addr: TArray<table_blob_file>;
  ft_create: FILETIME;
  ft_modify: FILETIME;
  constructor Create(_t: table; _name: string; _maxpartno: Integer);
  destructor Destroy;
end;

field = class

end;

table = class

end;

//---------------------------------------------------------------------------
// Базовый класс адаптеров контейнеров конфигурации
//class ConfigStorage
//{
//public:
//	__fastcall ConfigStorage(){};
//	virtual __fastcall ~ConfigStorage(){};
//	virtual CongigFile* __fastcall readfile(const String& path) = 0; // Если файл не существует, возвращается NULL
//	virtual bool __fastcall writefile(const String& path, TStream* str) = 0;
//	virtual String __fastcall presentation() = 0;
//	virtual void __fastcall close(CongigFile* cf) = 0;
//	virtual bool __fastcall fileexists(const String& path) = 0;
//};
ConfigStorageObject = class
public
  constructor Create;
  destructor Destroy;

  function readfile(const path: string): ConfigFile; virtual; // Если файл не существует, возвращается NULL
  function writefile(const path: string; str: TStream): Boolean; virtual;

  function presentation(): string; virtual;

  function fileexists(const path: string): Boolean; virtual;

  procedure close(cf: ConfigFile); virtual;

end;

//---------------------------------------------------------------------------
// Класс адаптера контейнера конфигурации - Директория
//class ConfigStorageDirectory : public ConfigStorage
//{
//private:
//	String fdir;
//public:
//	__fastcall ConfigStorageDirectory(const String& _dir);
//	__property String dir = {read = fdir};
//	virtual CongigFile* __fastcall readfile(const String& path);
//	virtual bool __fastcall writefile(const String& path, TStream* str);
//	virtual String __fastcall presentation();
//	virtual void __fastcall close(CongigFile* cf){delete cf->str; delete cf;};
//	virtual bool __fastcall fileexists(const String& path);
//};
ConfigStorageDirectory = class(ConfigStorageObject)
private
  fdir: string;
public

  constructor Create(_dir: string);
  destructor Destroy;

  property dir: string read fdir;
  function readfile(const path: string): ConfigFile; virtual; // Если файл не существует, возвращается NULL
  function writefile(const path: string; str: TStream): Boolean; virtual;

  function presentation(): string; virtual;

  function fileexists(const path: string): Boolean; virtual;

  procedure close(cf: ConfigFile); virtual;

end;

//---------------------------------------------------------------------------
// Класс адаптера контейнера конфигурации - cf (epf, erf, cfe) файл
//class ConfigStorageCFFile : public ConfigStorage
//{
//private:
//	String filename;
//	v8catalog* cat;
//public:
//	__fastcall ConfigStorageCFFile(const String& fname);
//	virtual __fastcall ~ConfigStorageCFFile();
//	virtual CongigFile* __fastcall readfile(const String& path);
//	virtual bool __fastcall writefile(const String& path, TStream* str);
//	virtual String __fastcall presentation();
//	virtual void __fastcall close(CongigFile* cf);
//	virtual bool __fastcall fileexists(const String& path);
//};
ConfigStorageCFFile = class(ConfigStorageObject)
private
  filename: string;
  cat: v8catalog;
public

  constructor Create(fname: string);
  destructor Destroy;

  function readfile(const path: string): ConfigFile; virtual; // Если файл не существует, возвращается NULL
  function writefile(const path: string; str: TStream): Boolean; virtual;

  function presentation(): string; virtual;

  function fileexists(const path: string): Boolean; virtual;

  procedure close(cf: ConfigFile); virtual;

end;

//---------------------------------------------------------------------------
// Класс таблицы контейнера файлов (CONFIG, CONFIGSAVE, PARAMS, FILES, CONFICAS, CONFICASSAVE)
TableFiles = class
private
  tab: table;
  allfiles: TDictionary<string,table_file>;
  rec: Char;
  ready: Boolean;
  function test_table(): Boolean;
public
  constructor Create(t: table);
  destructor Destroy();
  function getready(): Boolean;
  function getfile(name: string): table_file;
  function gettable(): table;
  property files: TDictionary<string,table_file> read allfiles;
end;

//---------------------------------------------------------------------------
// Структура файла контейнера файлов
container_file = class
public
  _file : table_file;
  name: string;      // Приведенное имя (очищенное от динамического обновления)
  stream,
  rstream: TStream;  // raw stream (нераспакованный поток)
  fname: string;     // Имя временого файла, содержащего stream
  rfname: string;    // Имя временого файла, содержащего rstream
  cat: v8catalog;
  _packed: table_file_packed;

  // Номер (индекс) динамического обновления (0, 1 и т.д.).
  // Если без динамического обновления, то -1, если UID динамического обновления
  // не найден, то -2. Для пропускаемых файлов -3.
  dynno: Integer;
  temppath : string;
  constructor Create(_f: table_file; _name: string);
  destructor Destroy;
  function open(): Boolean;
  function ropen(): Boolean;
  procedure close();
  function isPacked(): Boolean;
end;

implementation



{ ConfigStorageObject }

procedure ConfigStorageObject.close(cf: ConfigFile);
begin

end;

constructor ConfigStorageObject.Create;
begin
  inherited Create;
end;

destructor ConfigStorageObject.Destroy;
begin
  inherited Destroy;
end;

function ConfigStorageObject.fileexists(const path: string): Boolean;
begin

end;

function ConfigStorageObject.presentation: string;
begin

end;

function ConfigStorageObject.readfile(const path: string): ConfigFile;
begin

end;

function ConfigStorageObject.writefile(const path: string;
  str: TStream): Boolean;
begin

end;

{ ConfigStorageDirectory }

procedure ConfigStorageDirectory.close(cf: ConfigFile);
begin
  inherited close(cf);
end;

constructor ConfigStorageDirectory.Create(_dir: string);
begin
  fdir := dir;
  //if not fdir[Length(fdir)] = '\' then
  //  fdir := fdir + '\';

end;

destructor ConfigStorageDirectory.Destroy;
begin
  inherited Destroy;
end;

function ConfigStorageDirectory.fileexists(const path: string): Boolean;
var
  filename: string;
begin
  filename := fdir + TStringBuilder(path).Replace('/', '\').ToString;
  Result := System.SysUtils.FileExists(filename);
end;

function ConfigStorageDirectory.presentation: string;
begin
  Result := fdir.SubString(1, fdir.Length - 1);
end;

function ConfigStorageDirectory.readfile(const path: string): ConfigFile;
var
  cf: ConfigFile;
  filename: string;
  
begin
  filename := fdir + TStringBuilder(path).Replace('/', '\').ToString;
  if FileExists(filename) then
  begin
    //cf := ConfigFile;
    
    try
      cf.str := TFileStream.Create(filename, fmOpenRead);
      cf.addin := nil;
      Result := cf;
    except
      //Result := nil;
    end;
  end
  else
    Result := cf;
  
end;

function ConfigStorageDirectory.writefile(const path: string;
  str: TStream): Boolean;
var
  filename: string;
  f: TFileStream;  
begin
  filename := fdir+TStringBuilder(path).Replace('/', '\').ToString;
  f := TFileStream.Create(filename, fmCreate);
  f.CopyFrom(str, 0);
  f.Free;

  Result := True;
end;

{ ConfigStorageCFFile }

procedure ConfigStorageCFFile.close(cf: ConfigFile);
var
  f : v8file;
begin
  f := v8file(cf.addin);
  f.Close;
end;

constructor ConfigStorageCFFile.Create(fname: string);
begin
  inherited Create();
  filename := fname;
  cat := v8catalog.Create(filename);
end;

destructor ConfigStorageCFFile.Destroy;
begin
  cat.Free;
  inherited Destroy;
end;

function ConfigStorageCFFile.fileexists(const path: string): Boolean;
var
  f : v8file;
  i: Integer;
  fname: string;
begin
	// По сути, проверяется существование только каталога (файла верхнего уровня)
	// Это неправильно для формата 8.0 с файлом каталогом metadata. Но метод fileexists используется только для внешних файлов,
	// поэтому такой проверки достаточно

  if not cat.IsOpen then
  begin
    Result := False;
    Exit;
  end;

  fname := TStringBuilder(path).Replace('/', '\').ToString;
  i := Pos('\', fname);
  if i <> 0 then
    fname := fname.Substring(1, i - 1);
  f := cat.GetFile(fname);
  if not Assigned(f) then
  begin
    Result := False;
    Exit;
  end;
  Result := True;
end;

function ConfigStorageCFFile.presentation: string;
begin
  Result := filename;
end;

function ConfigStorageCFFile.readfile(const path: string): ConfigFile;
var
  c : v8catalog;
  f : v8file;
  i,j,k : Integer;
  cf : ConfigFile;
  fname : string;
begin
  if not cat.IsOpen then
    begin
      Exit;
    end;
  fname := TStringBuilder(path).Replace('/', '\').ToString;
  c := cat;

  j := Pos('\', fname);
  k := Pos('\', fname);
  for i := j to k do
  begin
    f := c.GetFile(fname.Substring(1, i - 1));
    if not Assigned(f) then
      Exit;
    c := f.GetCatalog;
    if not Assigned(c) then
      Exit;
    fname := fname.Substring(i + 1, fname.Length - i);
  end;

  f := c.GetFile(fname);
  if not Assigned(f) then
    Exit;
  if not f.Open then
      Exit;
  cf.str := f.get_data;
  cf.str.Seek(0, soBeginning);
  cf.addin := f;

  Result := cf;
end;

function ConfigStorageCFFile.writefile(const path: string;
  str: TStream): Boolean;
var
  f: v8file;
  c: v8catalog;
  i, j,k: Integer;
  fname: string;
begin

  if not cat.IsOpen then
  begin
    Result := False;
    Exit;
  end;

  fname := TStringBuilder(path).Replace('/', '\').ToString;
  c := cat;

  j := Pos('\', fname);
  k := Pos('\', fname);
  for i := j to k do
  begin
    c := c.Create_Catalog(fname.Substring(1, i - 1));
    fname := fname.Substring(i + 1, fname.Length - i);
  end;
  f := c.Create_File(fname);
  f.Write(str);

  Result := True;

end;

{ table_file }

constructor table_file.Create(_t: table; _name: string; _maxpartno: Integer);
var
  i: Integer;
begin
  t := _t;
  name := _name;
  maxpartno := _maxpartno;
  SetLength(addr, maxpartno);
  for i := 0 to maxpartno do
  begin
    addr[i].blob_start := 0;
    addr[i].blob_length := 0;
  end;
  ft_create.dwLowDateTime  := 0;
  ft_create.dwHighDateTime := 0;

  ft_modify.dwLowDateTime  := 0;
  ft_modify.dwHighDateTime := 0;
end;

destructor table_file.Destroy;
begin

  inherited Destroy;
end;

{ TableFiles }

constructor TableFiles.Create(t: table);
var
  filename, f, partno: field;
  start: ^Integer;
  length: ^Integer;
  create: ^AnsiChar;
  modify: ^AnsiChar;
  i,j : Integer;
  s: string;
  tr: table_rec;
  ptr: ^table_rec;
  allrec: TArray<table_rec>;
  maxpartnos: TDictionary<string,Integer>;
  tf: table_file;

begin
  tab := t;
  ready := test_table;
  if not ready then
    Exit;

end;

destructor TableFiles.Destroy;
begin
  allfiles.Free;
end;

function TableFiles.getfile(name: string): table_file;

begin
  if not allfiles.TryGetValue(name.UpperCase(name), Result) then
    Result := nil;
end;

function TableFiles.getready: Boolean;
begin
  Result := ready;
end;

function TableFiles.gettable: table;
begin
  Result := tab;
end;

function TableFiles.test_table: Boolean;
begin

end;

{ container_file }

procedure container_file.close;
begin
  cat.Free;
  cat := nil;
  if stream <> rstream then
  begin
    stream.Free;
    rstream.Free;
  end
  else
    stream.Free;

  if not fname.IsEmpty then
    DeleteFile(PWideChar(fname));
  if not rfname.IsEmpty then
    DeleteFile(PWideChar(rfname));

  fname := '';
  rfname := '';

end;

constructor container_file.Create(_f: table_file; _name: string);
begin
  _file := _f;
  name := _name;
  stream := nil;
  rstream := nil;
  fname := '';
  rfname := '';
  cat := nil;
  _packed := tfp_unknown;
  dynno := -3;
end;

destructor container_file.Destroy;
begin
  close;
end;

function container_file.isPacked: Boolean;
begin
//	int i;
//	String ext;
//
//	if(name.CompareIC(L"DynamicallyUpdated") == 0) return false;
//	if(name.CompareIC(L"SprScndInfo") == 0) return false;
//	if(name.CompareIC(L"DBNamesVersion") == 0) return false;
//	if(name.CompareIC(L"siVersions") == 0) return false;
//	if(name.UpperCase().Pos(L"FO_VERSION") > 0) return false;
//	if(name[1] == L'{') return false;
//	i = name.LastDelimiter(spoint);
//	if(i)
//	{
//		ext = name.SubString(i + 1, name.Length() - i).UpperCase();
//		if(ext.Compare(L"INF") == 0) return false;
//		if(ext.Compare(L"PFL") == 0) return false;
//	}
//	return true;
  Result := True;
end;

function container_file.open: Boolean;
var
  ts: TStream;
  tn: string;
  tempfile: string;
  i, maxpartno: Integer;
  t: table;
  addr: TArray<table_blob_file>;
begin
  if Assigned(stream) then
  begin
    stream.Seek(0, soBeginning);
    Result := True;
    Exit;
  end;
  t := _file.t;
  addr := _file.addr;
  maxpartno := _file.maxpartno;
  if maxpartno > 0 then
  begin
    GetTempFileName(PWideChar(temppath), 'awa', 0, PWideChar(tempfile));
    tn := tempfile;
    stream := TFileStream.Create(tn, fmCreate);
    fname := tn;
  end
  else
    stream := TMemoryStream.Create;
  if _packed = tfp_unknown then
  begin
    if isPacked then
      _packed := tfp_yes
    else
      _packed := tfp_no;
  end;

  if Assigned(rstream) then
  begin
    if _packed = tfp_yes then
      ts := rstream
    else
      begin
        stream := rstream;
        stream.Seek(0, soBeginning);
        Result := True;
        Exit;
      end;

  end
  else
  begin
    if _packed = tfp_yes then
    begin
      if maxpartno > 0 then
      begin
        GetTempFileName(PWideChar(temppath), 'awa', 0, PWideChar(tempfile));
        tn := tempfile;
        ts := TFileStream.Create(tn, fmCreate);
      end
      else
        ts := TMemoryStream.Create;
    end
    else
      ts := stream;
    for i := 0 to maxpartno do
    begin
      // t.readBlob(ts, addr[i].blob_start, addr[i].blob_length, false); // Надо доделать!!!!!!!!
    end;
  end;

  if _packed = tfp_yes then
  begin
    ts.Seek(0, soBeginning);
    ZInflateStream(ts, stream);
    if not Assigned(rstream) then
    begin
      ts.Free;
      DeleteFile(PWideChar(tn));
    end;
  end;

  stream.Seek(0, soBeginning);
  Result := True;

end;

function container_file.ropen: Boolean;
var
  //ts: TStream;
  //tn: string;
  tempfile: string;
  i, maxpartno: Integer;
  t: table;
  addr: TArray<table_blob_file>;
begin
  if Assigned(rstream) then
  begin
    rstream.Seek(0, soBeginning);
    Result := True;
    Exit;
  end;

  t := _file.t;
  addr := _file.addr;

  maxpartno := _file.maxpartno;
  if _packed = tfp_unknown then
  begin
    if isPacked then
      _packed := tfp_yes
    else
      _packed := tfp_no;
  end;

  if (_packed = tfp_no) and Assigned(stream) then
  begin
    rstream := stream;
    rstream.Seek(0, soFromBeginning);
    Result := True;
    Exit;
  end;

  if maxpartno > 0 then
  begin
    GetTempFileName(PWideChar(temppath), 'awa', 0, PWideChar(tempfile));
    rfname := tempfile;
    rstream := TFileStream.Create(rfname, fmCreate);
  end
  else
    rstream := TMemoryStream.Create;

  for i := 0 to maxpartno do
  begin
      // t.readBlob(ts, addr[i].blob_start, addr[i].blob_length, false); // Надо доделать!!!!!!!!
  end;

  rstream.Seek(0, soBeginning);

  Result := True;

end;

end.
