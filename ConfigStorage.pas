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

//PConfigFile = ^ConfigFile;
ConfigFile = record
  str: TStream;
  addin : Pointer;
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
begin

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
begin

end;

function ConfigStorageCFFile.presentation: string;
begin

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
begin

end;

end.
