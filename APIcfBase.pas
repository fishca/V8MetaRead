unit APIcfBase;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions, System.Syncobjs, System.Generics.Collections, System.WideStrUtils, ZZlib;

const
  str_cfu = '.cfu';
  str_cfe = '.cfe';
  str_cf  = '.cf';
  str_epf = '.epf';
  str_erf = '.erf';
  str_backslash = '\';



//const
  _empty_catalog_template = AnsiString('#$FF#$FF#$FF#$7F#$00#$02#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00');
  _block_header_template  = AnsiString('#$13#$10#$0#$0#$0#$0#$0#$0#$0#$0#$20#$0#$0#$0#$0#$0#$0#$0#$0#$20#$0#$0#$0#$0#$0#$0#$0#$0#$20#$13#$10');

  _bufhex = AnsiString('0123456789abcdef');
type

v8header_struct = record
  time_create: Int64;
  time_modify: Int64;
  zero: Integer;
end;

fat_item = record
  header_start: Integer;
  data_start: Integer;
  ff: Integer;
end;

catalog_header = record
  start_empty: Integer;
  page_size: Integer;
  version: Integer;
  zero: Integer;
end;

v8catalog = class;
TV8FileStream = class;

FileIsCatalog = (
	iscatalog_unknown,
	iscatalog_true,
	iscatalog_false
);

v8file = class
private
  name: string;
  time_create: Int64;
  time_modify: Int64;
  Lock: TCriticalSection;
  data: TStream;
  parent: v8catalog;
  is_catalog: FileIsCatalog;
  _self: v8catalog;
  next: v8file;
  previous: v8file;
  is_opened: Boolean;
  start_data: Integer;
  start_header: Integer;
  is_datamofified: Boolean;
  is_headermofified: Boolean;
  is_destructed: Boolean;
  flushed: Boolean;
  selfzipped: Boolean;
  //streams: TList<TV8FileStream>;
  streams: TObjectList<TV8FileStream>;
public
  constructor Create(_parent: v8catalog; _name: string; _previous: v8file; _start_data: Integer; _start_header: Integer; _time_create: Int64; _time_modify: Int64);
  destructor Destroy;
  function IsCatalog(): Boolean;
  function GetCatalog: v8catalog;
  function GetFileLength: Integer;
  function Read(var Buffer; Start: Integer; Lenght: Integer): Integer;
  function Write(var Buffer; Start: Integer; Lenght: Integer): Integer; overload;
  function Write(var Buffer; Lenght: Integer): Integer; overload;
  function Write(Stream: TStream; Start: Integer; Lenght: Integer): Integer; overload;
  function Write(Stream: TStream): Integer; overload;
  function GetFileName(): string;
  function GetFullName(): string;
  procedure SetFileName(_name: string);
  function GetParentCatalog: v8catalog;
  procedure DeleteFile;
  function GetNext(): v8file;
  function Open(): Boolean;
  procedure Close();
  function WriteAndClose(Stream: TStream; Lenght: Integer = -1): Integer;
  procedure GetTimeCreate(ft: FIlETIME);
  procedure GetTimeModify(ft: FIlETIME);
  procedure SetTimeCreate(ft: FIlETIME);
  procedure SetTimeModify(ft: FIlETIME);
  procedure SaveToFile(FileName: string);
  procedure SaveToStream(Stream: TStream);
  function get_data(): TStream;
  procedure Flush();
end;


v8catalog = class
private
  Lock: TCriticalSection;
  _file : v8file;
  data: TStream;
  cfu: TStream;
  first : v8file;
  last  : v8file;

  files: TDictionary<string, v8file>;
  start_empty: Integer;
  page_size: Integer;
  version: Integer;
  zipped: Boolean;
  is_cfu: Boolean;
  is_catalog: Boolean;
  iscatalogdefined: Boolean;

  is_fatmodified: Boolean;
  is_emptymodified: Boolean;
  is_modified: Boolean;

  is_destructed: Boolean;
  flushed: Boolean;
  leave_data: Boolean;

  procedure initialize;
  procedure free_block(start: Integer);
  function write_block(block: TStream; start: Integer; use_page_size: Boolean; len: Integer = -1): Integer;
  function write_datablock(block: TStream; start: Integer; _zipped: Boolean = False; len: Integer = -1): Integer;
  function read_datablock(start: Integer): TStream;
  function get_nextblock(start: Integer): Integer;
public
  constructor Create(f: v8file); overload;
  constructor Create(name: string); overload;
  constructor Create(name: string; _zipped: Boolean); overload;
  constructor Create(Stream: TStream; _zipped: Boolean; leave_stream: Boolean = False); overload;
  destructor Destroy;
  function GetFile(FileName: string): v8file;
  function GetFirst(): v8file;
  function Create_File(FileName: string; _sefzipped: Boolean = False ): v8file;
  function Create_Catalog(FileName: string; _sefzipped: Boolean = False ): v8catalog;
  procedure DeleteFile(FileName: string);
  function GetParentCatalog(): v8catalog;
  function GetSelfFile(): v8file;
  procedure SaveToDir(DirName: string);
  function IsOpen(): Boolean;
  procedure Flush();
  procedure HalfClose();
  procedure HalfOpen(name: string);

  function IsCatalog(): Boolean;

end;

TV8FileStream = class(TStream)
protected
  _file: v8file;
  own: Boolean;
  _pos: Int64;
public
  constructor Create(f: v8file; ownfile: Boolean = False);
  destructor Destroy;
  function Read(var Buffer, Count : Integer): Integer; overload; virtual;
  function Read(var Buffer: TArray<Byte>; Offset, Count : Integer): Integer; overload; virtual;
  function Write(var Buffer, Count : Integer): Integer; overload; virtual;
  function Write(var Buffer: TArray<Byte>; Offset, Count : Integer): Integer; overload; virtual;
  function Seek(Offset : Integer; Origin: Word): Integer; overload; virtual;
  function Seek(Offset : Int64; Origin: TSeekOrigin): Integer; overload; virtual;
end;


//function read_block(stream_from: TStream; start :Integer; stream_to: TStream = nil) : TStream;
procedure V8timeToFileTime(v8t : Int64; var ft : FILETIME);

function HEXToDec(S: AnsiString): Integer;

function hex_to_int(hexstr: AnsiString): Integer;
function int_to_hex(hexstr: AnsiString; dec: Integer): AnsiString;

implementation

{ v8file }

procedure v8file.Close;
var
  _t : Integer;
  hs: TMemoryStream;
begin
  _t := 0;
  if parent = nil then
    Exit;
  Lock.Acquire;
  if not is_opened then
    Exit;

  if _self <> nil then
    if not _self.is_destructed then
      _self.Free;

  _self := nil;

  if parent.data <> nil then
  begin
    if (is_datamofified or is_headermofified) then
    begin
      parent.Lock.Acquire;
      if is_datamofified then
      begin
        start_data := parent.write_datablock(data, start_data, selfzipped);
      end;
      if is_headermofified then
      begin
        hs := TMemoryStream.Create;
        hs.Write(time_create, 8);
        hs.Write(time_modify, 8);
        hs.Write(_t, 4);
        hs.Write(name, name.Length * 2);
        hs.Write(_t, 4);

        start_header := parent.write_block(hs, start_header, False);
        hs.Free;
      end;
      parent.Lock.Release;
    end;
  end;

  data.Free;
  data := nil;
  is_catalog := iscatalog_unknown;
  is_opened := False;
  is_datamofified := False;
  is_headermofified := False;
  Lock.Release;
end;

constructor v8file.Create(_parent: v8catalog; _name: string; _previous: v8file; _start_data: Integer; _start_header: Integer; _time_create: Int64; _time_modify: Int64);
begin
  inherited Create;
  Lock := TCriticalSection.Create;
  is_destructed := False;
  flushed := False;
  parent := _parent;
  name := _name;
  previous := _previous;
  next := nil;
  data := nil;
  start_data := _start_data;
  start_header := _start_header;
  is_datamofified := False; //is_datamofified := not (start_data = nil);
  is_headermofified := False; //is_headermofified := not (start_header = nil);
  if previous <> nil then
    previous.next := Self
  else
    parent.first := Self;
  is_catalog := iscatalog_unknown;
  _self := nil;
  is_opened := False;
  time_create := _time_create;
  time_modify := _time_modify;
  selfzipped := False;
  if parent <> nil then
    begin
      parent.files := TDictionary<string,v8file>.Create();
      parent.files.AddOrSetValue(name.ToUpper, Self);
    end;


end;

procedure v8file.DeleteFile;
begin
  Lock.Acquire;
  if (parent <> nil) then
  begin
    parent.Lock.Acquire;
    if next <> nil then
    begin
      next.Lock.Acquire;
      next.previous := previous;
      next.Lock.Release;
    end
    else
      parent.last := previous;

    if previous <> nil then
    begin
      previous.Lock.Acquire;
      previous.next := next;
      previous.Lock.Release;
    end
    else
      parent.first := next;

    parent.is_fatmodified := True;
    parent.free_block(start_data);
    parent.free_block(start_header);
    parent.files.Remove(name.UpperCase(name));
    parent.Lock.Release;
    parent := nil;
  end;

  data.Free;
  data := nil;
  if _self <> nil then
  begin
    _self.data := nil;
    _self.Free;
    _self := nil;
  end;

  is_catalog := iscatalog_false;
  next := nil;
  previous := nil;
  is_opened := False;
  start_data := 0;
  start_header := 0;
  is_datamofified := False;
  is_headermofified := False;
end;

destructor v8file.Destroy;
begin

  Lock.Acquire;
  is_destructed := True;
  Close;

  if parent <> nil then
  begin
    if (next <> nil) then
      begin
        next.Lock.Acquire;
        next.previous := previous;
        next.Lock.Release;
      end
    else
      begin
        parent.Lock.Acquire;
        parent.last := previous;
        parent.Lock.Release;
      end;
    if (previous <> nil) then
      begin
        previous.Lock.Acquire;
        previous.next := next;
        previous.Lock.Release;
      end
    else
      begin
        parent.Lock.Acquire;
        parent.first := next;
        parent.Lock.Release;
      end;

  end;

  Lock.Free;

  inherited Destroy;

end;

procedure v8file.Flush;
var
  _t: Integer;
  hs: TMemoryStream;
begin

  _t := 0;
  Lock.Acquire;
  if flushed then
  begin
    Lock.Release;
    Exit;
  end;

  if parent = nil then
  begin
    Lock.Release;
    Exit;
  end;

  if not is_opened then
  begin
    Lock.Release;
    Exit;
  end;

  flushed := True;
  if _self <> nil then
    _self.Flush;

  if parent.data <> nil then
  begin
    if (is_datamofified or is_headermofified) then
    begin
      parent.Lock.Acquire;
      if is_datamofified then
      begin
        start_data := parent.write_datablock(data, start_data, selfzipped);
        is_datamofified := False;
      end;
      if is_headermofified then
      begin
        hs := TMemoryStream.Create;
        hs.Write(time_create, 8);
        hs.Write(time_modify, 8);
        hs.Write(_t, 4);
        hs.Write(name, name.Length * 2);
        hs.Write(_t, 4);

        start_header := parent.write_block(hs, start_header, False);
        hs.Free;
        is_headermofified := False;
      end;
      parent.Lock.Release;
    end;
  end;
  flushed := False;
  Lock.Release;

end;

function v8file.GetCatalog: v8catalog;
var
  ret: v8catalog;
begin
  Lock.Acquire;
  if IsCatalog then
  begin
    if _self = nil then
      _self := v8catalog.Create(Self);
    ret := _self;
  end
  else
    ret := nil;
  Lock.Release;
  Result := ret;
end;

function v8file.GetFileLength: Integer;
var
  ret: Integer;
begin
  Lock.Acquire;
  if not is_opened then
    if not Open() then
      Result := 0;

  ret := data.Size;
  Lock.Release;
  Result := ret;
end;

function v8file.GetFileName: string;
begin
  Result := name;
end;

function v8file.GetFullName: string;
var
  fulln: string;
begin
  if parent <> nil then
  begin
    if parent._file <> nil then
    begin
      fulln := parent._file.GetFullName;
      if not fulln.IsEmpty then
      begin
        fulln := fulln + '\';
        fulln := fulln + name;
        Result := fulln;
      end;
    end;
  end;
  Result := name;
end;

function v8file.GetNext: v8file;
begin
  Result := next;
end;

function v8file.GetParentCatalog: v8catalog;
begin
  Result := parent;
end;

procedure V8timeToFileTime(v8t : Int64; var ft : FILETIME);
var
  lft: FILETIME;
  t : Int64;
begin
  t := v8t;
  t := t - 504911232000000;  //504911232000000 = ((365 * 4 + 1) * 100 - 3) * 4 * 24 * 60 * 60 * 10000
  t := t * 1000;
  Int64(lft) := t;
  LocalFileTimeToFileTime(lft, ft);
end;

procedure FileTimeToV8time(ft : FILETIME; var v8t: Int64);
var
  lft : FILETIME;
  t : Int64;
begin
  FileTimeToLocalFileTime(ft, lft);
  t := Int64(lft);
  t := t div 1000;
  t := t + 504911232000000;
  v8t := t;
end;

procedure setCurrentTime(v8t: int64);
var
  st: SYSTEMTIME;
  ft: FILETIME;
begin
  GetSystemTime(st);
  SystemTimeToFileTime(st, ft);
  FileTimeToV8time(ft, v8t);
end;

function FileTimeToLocalSystemTime(ft : FILETIME) : TSystemTime;
var
 t:FILETIME;
begin
 FileTimeToLocalFileTime(ft,t);
 FileTimeToSystemTime(t,result);
end;

function FileTime2DateTime(FT:_FileTime) : TDateTime;
var
  FileTime:_SystemTime;
begin
  FileTimeToLocalFileTime(FT, FT);
  FileTimeToSystemTime(FT,FileTime);
  Result := EncodeDate(FileTime.wYear, FileTime.wMonth, FileTime.wDay) +
            EncodeTime(FileTime.wHour, FileTime.wMinute, FileTime.wSecond, FileTime.wMilliseconds);
end;

function FileTimeToDateTime(FileTime: TFileTime): TDateTime;
var
  ModifiedTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := 0;
  if (FileTime.dwLowDateTime = 0) and (FileTime.dwHighDateTime = 0) then
    Exit;
  try
    FileTimeToLocalFileTime(FileTime, ModifiedTime);
    FileTimeToSystemTime(ModifiedTime, SystemTime);
    Result := SystemTimeToDateTime(SystemTime);
  except
    Result := Now;  // Something to return in case of error
  end;
end;

function DateTimeToFileTime(FileTime: TDateTime): TFileTime;
var
  LocalFileTime, Ft: TFileTime;
  SystemTime: TSystemTime;
begin
  Result.dwLowDateTime := 0;
  Result.dwHighDateTime := 0;
  DateTimeToSystemTime(FileTime, SystemTime);
  SystemTimeToFileTime(SystemTime, LocalFileTime);
  LocalFileTimeToFileTime(LocalFileTime, Ft);
  Result := Ft;
end;

function SysDateToStr(ST : TSystemTime) : AnsiString;
begin
 SetLength(Result, 255);
 GetDateFormat(LOCALE_USER_DEFAULT, DATE_LONGDATE, @ST, nil, @result[1], 255);
 SetLength(Result, LStrLen(@result[1]));
end;

function SysTimeToStr(ST : TSystemTime) : AnsiString;
begin
// SetLength(result, 15);
// GetTimeFormat(LOCALE_USER_DEFAULT,0,@st,nil,@result[1],15);
// //SetLength(result, StrLen(@result[1]));
// SetLength(result, Length(@result[1]));
end;

function SysDateTimeToStr(ST:TSystemTime) : AnsiString;
begin
 Result := SysDateToStr(ST) + ' ' + SysTimeToStr(ST);
end;

procedure v8file.GetTimeCreate(ft: FIlETIME);
begin
  V8timeToFileTime(time_create, ft);
end;

procedure v8file.GetTimeModify(ft: FIlETIME);
begin
  V8timeToFileTime(time_modify, ft);
end;

function v8file.get_data: TStream;
begin
  Result := data;
end;

function ArrayToString(const a: array of AnsiChar): AnsiString;
begin
  if Length(a) > 0 then
    SetString(Result, PAnsiChar(@a[0]), Length(a))
  else
    Result := '';
end;

function v8file.IsCatalog: Boolean;
var
  _filelen : Integer;
  _startempty: Integer;
  _t: array[1..32] of AnsiChar;
  _t2: array[1..32] of AnsiChar;
  at1: AnsiString;
  at2: AnsiString;
  P1: Pointer;
  P2: Pointer;
begin
  Lock.Acquire;
  if is_catalog = iscatalog_unknown then
  begin
    if not is_opened then
      if not Open() then
        begin
          Lock.Release;
          Result := False;
          Exit;
        end;
    _filelen := data.Size;
    if _filelen = 16 then
    begin
      data.Seek(0, soFromBeginning);
      data.Read(_t, 16);

      at1 := ArrayToString(_t);
      at2 := _empty_catalog_template;
      if AnsiCompareStr(at1, at2) <> 0 then
        begin
          is_catalog := iscatalog_false;
          Lock.Release;
          Result := False;
          Exit;
        end
      else
        begin
          is_catalog := iscatalog_true;
          Lock.Release;
          Result := True;
          Exit;
        end;
    end;
    data.Seek(0, soFromBeginning);
    data.Read(_startempty, 4);
    if _startempty <> $7fffffff then
    begin
      if _startempty + 31 >= _filelen then
      begin
        is_catalog := iscatalog_false;
        Lock.Release;
        Result := False;
        Exit;
      end;
      data.Seek(_startempty, soFromBeginning);
      data.Read(_t, 31);
      if (_t[1] <> #$0D) or (_t[1] <> #$0A) or (_t[10] <> #$20) or (_t[19] <> #$20) or (_t[28] <> #$20) or (_t[29] <> #$0D) or (_t[30] <> #$0A) then
      begin
        is_catalog := iscatalog_false;
        Lock.Release;
        Result := False;
        Exit;
      end;
    end;
    if _filelen < 31 + 16 then
    begin
      is_catalog := iscatalog_false;
      Lock.Release;
      Result := False;
      Exit;
    end;
    data.Seek(16, soFromBeginning);
    data.Read(_t, 31);
    if (_t[1] <> #$0D) or (_t[1] <> #$0A) or (_t[10] <> #$20) or (_t[19] <> #$20) or (_t[28] <> #$20) or (_t[29] <> #$0D) or (_t[30] <> #$0A) then
    begin
      is_catalog := iscatalog_false;
      Lock.Release;
      Result := False;
      Exit;
    end;
    is_catalog := iscatalog_true;
    Lock.Release;
    Result := True;
    Exit;
  end;
  Lock.Release;
  Result := (is_catalog = iscatalog_true);
end;

function v8file.Open: Boolean;
begin
  if parent = nil then
  begin
    Result := False;
    Exit;
  end;
  Lock.Acquire;
  if is_opened then
  begin
    Lock.Release;
    Result := True;
    Exit;
  end;
  data := parent.read_datablock(start_data);
  is_opened := True;
  Lock.Release;
  Result := True;
end;

function v8file.Read(var Buffer; Start, Lenght: Integer): Integer;
var
  ret: Integer;
begin
  Lock.Acquire;
  if not is_opened then
  begin
    if not Open() then
    begin
      Result := 0;
      Exit;
    end;

  end;
  data.Seek(Start, soFromBeginning);
  ret := data.Read(Buffer, Lenght);
  Lock.Release;
  Result := ret;
end;

procedure v8file.SaveToFile(FileName: string);
var
  _create: FILETIME;
  _modify: FILETIME;
  fs: TFileStream;
begin
  if not is_opened then
  begin
    if not Open() then
    begin
     Exit;
    end;
  end;

  fs := TFileStream.Create(FileName, fmCreate);
  Lock.Acquire;
  fs.CopyFrom(data, 0);
  Lock.Release;
  GetTimeCreate(_create);
  GetTimeModify(_modify);
  SetFileTime(fs.Handle, @_create, @_modify, @_modify);
  fs.Free;
end;

procedure v8file.SaveToStream(Stream: TStream);
begin
  Lock.Acquire;
  if not is_opened then
    if not Open() then
      Exit;
  Stream.CopyFrom(data, 0);
  Lock.Release;
end;

procedure v8file.SetFileName(_name: string);
begin
  name := _name;
  is_headermofified := True;
end;

procedure v8file.SetTimeCreate(ft: FIlETIME);
begin
  FileTimeToV8time(ft, time_create);
end;

procedure v8file.SetTimeModify(ft: FIlETIME);
begin
  FileTimeToV8time(ft, time_modify);
end;

function v8file.Write(Stream: TStream): Integer;
var
  ret : Integer;
begin

  Lock.Acquire;

  if not is_opened then
    if not Open() then
      begin
        Result := 0;
        Exit;
      end;

  setCurrentTime(time_modify);
  is_headermofified := True;
  is_datamofified := True;

  if data.Size > Stream.Size then
    data.Size := Stream.Size;

  data.Seek(0, soFromBeginning);
  ret := data.CopyFrom(Stream, 0);
  Lock.Release;

  Result := ret;

end;

function v8file.Write(Stream: TStream; Start, Lenght: Integer): Integer;
var
  ret : Integer;
begin
  Lock.Acquire;

  if not is_opened then
    if not Open() then
      begin
        Result := 0;
        Exit;
      end;

  setCurrentTime(time_modify);
  is_headermofified := True;
  is_datamofified := True;

//  if data.Size > Stream.Size then
//    data.Size := Stream.Size;

  data.Seek(Start, soFromBeginning);
  ret := data.CopyFrom(Stream, Lenght);
  Lock.Release;

  Result := ret;

end;

function v8file.Write(var Buffer; Lenght: Integer): Integer;
var
  ret : Integer;
begin
  Lock.Acquire;

  if not is_opened then
    if not Open() then
      begin
        Result := 0;
        Exit;
      end;

  setCurrentTime(time_modify);
  is_headermofified := True;
  is_datamofified := True;

  if data.Size > Lenght then
    data.Size := Lenght;

  data.Seek(0, soFromBeginning);
  ret := data.Write(Buffer, Lenght);
  Lock.Release;

  Result := ret;

end;

function v8file.Write(var Buffer; Start, Lenght: Integer): Integer;
var
  ret : Integer;
begin
  Lock.Acquire;

  if not is_opened then
    if not Open() then
      begin
        Result := 0;
        Exit;
      end;

  setCurrentTime(time_modify);
  is_headermofified := True;
  is_datamofified := True;

//  if data.Size > Lenght then
//    data.Size := Lenght;

  data.Seek(Start, soFromBeginning);
  ret := data.Write(Buffer, Lenght);
  Lock.Release;

  Result := ret;

end;

function v8file.WriteAndClose(Stream: TStream; Lenght: Integer): Integer;
var
  _t : Integer;
  hs: TMemoryStream;
begin
  _t := 0;
  Lock.Acquire;
  if not is_opened then
    if not Open() then
      begin
        Lock.Release;
        Result := 0;
        Exit;
      end;

  if parent = nil then
  begin
    Lock.Release;
    Result := 0;
    Exit;
  end;

  if _self <> nil then
    _self.Free;

  _self := nil;

  data.Free;
  data := nil;

  if parent.data <> nil then
  begin
    parent.Lock.Acquire;
    start_data := parent.write_datablock(Stream, start_data, selfzipped, Lenght);
    hs := TMemoryStream.Create;
    hs.Write(time_create, 8);
    hs.Write(time_modify, 8);
    hs.Write(_t, 4);
    hs.Write(name, name.Length * 2);
    hs.Write(_t, 4);
    start_header := parent.write_block(hs, start_header, False);
    parent.Lock.Release;
    hs.Free;
  end;
  is_catalog := iscatalog_unknown;
  is_opened := False;
  is_datamofified := False;
  is_headermofified := False;
  Lock.Release;

  if Lenght = -1 then
  begin
    Result := Stream.Size;
    Exit;
  end;

  Result:= Lenght;
end;

{ v8catalog }

constructor v8catalog.Create(f: v8file);
begin
  is_cfu := False;
  iscatalogdefined := False;
  _file := f;
  Lock.Acquire;
  _file.Open();
  data := _file.data;
  zipped := False;
  if IsCatalog() then
    initialize
  else
    begin
      first := nil;
      last := nil;
      start_empty := 0;
      page_size := 0;
      version := 0;
      zipped := False;

      is_fatmodified := False;
      is_emptymodified := False;
      is_modified := False;
      is_destructed := False;
      flushed := False;
      leave_data := False;
    end;
  Lock.Release;
end;

constructor v8catalog.Create(name: string);
var
  ext: string;
begin
  Lock := TCriticalSection.Create;
  iscatalogdefined := False;
  ext := ExtractFileExt(name).LowerCase(name);
  if ext = str_cfu then
    begin
      is_cfu := True;
      zipped := False;
      data := TMemoryStream.Create;
      if not FileExists(name) then
        begin
          data.WriteBuffer(_empty_catalog_template, 16);
          cfu := TFileStream.Create(name, fmCreate);
        end
      else
        begin
          cfu := TFileStream.Create(name, fmOpenReadWrite);
          ZInflateStream(cfu, data); // Надо обязательно доделать
        end;
    end
  else
    begin
      zipped := ((ext = str_cf) or (ext = str_epf) or (ext = str_erf) or (ext = str_cfe));
      is_cfu := False;
      if not FileExists(name) then
      begin
        data := TFileStream.Create(name, fmCreate);
        data.WriteBuffer(_empty_catalog_template, 16);
        data.Free;
      end;
      data := TFileStream.Create(name, fmOpenReadWrite);
    end;
  _file := nil;
  if IsCatalog() then
    initialize()
  else
    begin
      first := nil;
      last := nil;
      start_empty := 0;
      page_size := 0;
      version := 0;
      zipped := False;

      is_fatmodified := False;
      is_emptymodified := False;
      is_modified := False;
      is_destructed := False;
      flushed := False;
      leave_data := False;
    end;
end;

constructor v8catalog.Create(Stream: TStream; _zipped, leave_stream: Boolean);
begin
  Lock := TCriticalSection.Create;
  is_cfu := False;
  iscatalogdefined := False;
  zipped := _zipped;
  data := Stream;
  _file := nil;
  if data.Size = 0 then
  begin
    data.WriteBuffer(_empty_catalog_template, 16);
  end;
  if IsCatalog then
    initialize
  else
    begin
      first := nil;
      last := nil;
      start_empty := 0;
      page_size := 0;
      version := 0;
      zipped := False;

      is_fatmodified := False;
      is_emptymodified := False;
      is_modified := False;
      is_destructed := False;
      flushed := False;

    end;
  leave_data := leave_stream;
end;

constructor v8catalog.Create(name: string; _zipped: Boolean);
begin
  Lock := TCriticalSection.Create;
  is_cfu := False;
  iscatalogdefined := False;
  zipped := _zipped;
  if not FileExists(name) then
  begin
    data := TFileStream.Create(name, fmCreate);
    data.WriteBuffer(_empty_catalog_template, 16);
    data.Free;
  end;
  data := TFileStream.Create(name, fmOpenReadWrite);
  _file := nil;
  if IsCatalog then
    initialize
  else
    begin
      first := nil;
      last := nil;
      start_empty := 0;
      page_size := 0;
      version := 0;
      zipped := False;

      is_fatmodified := False;
      is_emptymodified := False;
      is_modified := False;
      is_destructed := False;
      flushed := False;
      leave_data := False;
    end;
end;

function v8catalog.Create_Catalog(FileName: string;
  _sefzipped: Boolean): v8catalog;
var
  ret: v8catalog;
  f: v8file;
begin
  Lock.Acquire;
  f := Create_File(FileName, _sefzipped);
  if f.GetFileLength <> 0 then
    begin
      if f.IsCatalog then
        ret := f.GetCatalog
      else
        ret := nil;
    end
  else
    begin
      // f.Write(Pointer(_empty_catalog_template)^, 16); Надо доделать!!!!!!!!!!!!!!!!!
      ret := f.GetCatalog;
    end;

  Lock.Release;
  Result := ret;
end;

function v8catalog.Create_File(FileName: string; _sefzipped: Boolean): v8file;
var
  v8t: Int64;
  f: v8file;
begin
  Lock.Acquire;
  f := GetFile(FileName);
  if f = nil then
  begin
    setCurrentTime(v8t);
    f := v8file.Create(Self, FileName, last, 0, 0, v8t, v8t);
    f.selfzipped := _sefzipped;
    last := f;
    is_fatmodified := True;
  end;
  Lock.Release;
end;

procedure v8catalog.DeleteFile(FileName: string);
var
  f : v8file;
begin
  Lock.Acquire;
  f := first;
  while f <> nil do
  begin
    if not (f.name.CompareTo(FileName) = 0) then
    begin
      f.DeleteFile;
      f.Free;
    end;
    f := f.next;
  end;
  Lock.Release;
end;

destructor v8catalog.Destroy;
var
  fi: fat_item;
  f: v8file;
  fat : TMemoryStream;
begin
  Lock.Acquire;
  is_destructed := True;
  f := first;
  while f <> nil do
  begin
    f.Close;
    f := f.next;
  end;
  if data <> nil then
  begin
    if is_fatmodified then
    begin
      fat := TMemoryStream.Create;
      fi.ff := $7fffffff;
      f := first;
      while f <> nil do
      begin
        fi.header_start := f.start_header;
        fi.data_start := f.start_data;
        fat.WriteBuffer(fi, 12);
        f := f.next;
      end;
      write_block(fat, 16, True);
    end;
  end;

  while data <> nil do
  begin
    first.Free;
  end;

  if data <> nil then
  begin
    if is_emptymodified then
    begin
      data.Seek(0, soFromBeginning);
      data.WriteBuffer(start_empty, 4);
    end;
    if is_modified then
    begin
      Inc(version);
      data.Seek(8, soFromBeginning);
      data.WriteBuffer(version, 4);
    end;
  end;

  if _file <> nil then
    begin
      if is_modified then
        _file.is_datamofified := True;
      if not _file.is_destructed then
        _file.Close;
    end
  else
    begin
      if is_cfu then
      begin
        if (data <> nil) and (cfu <> nil) and is_modified then
          begin
            data.Seek(0, soFromBeginning);
            cfu.Seek(0, soFromBeginning);
            ZDeflateStream(data, cfu); // Надо доделать обязательно
          end;
        data.Free;
        data := nil;
        if (cfu <> nil) and not leave_data then
        begin
          cfu.Free;
          cfu := nil;
        end;
      end;
      if (data <> nil) and not leave_data then
      begin
        data.Free;
        data := nil;
      end;
    end;

    if _file = nil then
      Lock.Release;
end;

procedure v8catalog.Flush;
var
  fi: fat_item;
  f: v8file;
  fat: TMemoryStream;
begin
  Lock.Acquire;
  if flushed then
  begin
    Lock.Release;
    Exit;
  end;
  flushed := True;

  f := first;
  while f <> nil do
  begin
    f.Flush;
    f := f.next;
  end;

  if data <> nil then
  begin
    if is_fatmodified then
    begin
      fat := TMemoryStream.Create;
      fi.ff := $7FFFFFFF;
      f := first;
      while f <> nil do
      begin
        fi.header_start := f.start_header;
        fi.data_start := f.start_data;
        fat.WriteBuffer(fi, 12);
        f := f.next;
      end;
      write_block(fat, 16, True);
      is_fatmodified := True;
    end;

    if is_emptymodified then
    begin
      data.Seek(0, soFromBeginning);
      data.WriteBuffer(start_empty, 4);
      is_emptymodified := False;
    end;

    if is_modified then
    begin
      Inc(version);
      data.Seek(0, soFromBeginning);
      data.WriteBuffer(version, 4);
    end;
  end;

  if _file <> nil then
    begin
      if is_modified then
      begin
        _file.is_datamofified := True;
      end;
      _file.Flush;
    end
  else
    begin
      if is_cfu then
      begin
        if ( data <> nil) and (cfu <> nil) and is_modified then
        begin
          data.Seek(0, soFromBeginning);
          cfu.Seek(0, soFromBeginning);
          ZDeflateStream(data, cfu); // Надо доделать обязательно
        end;

      end;
    end;
  is_modified := False;
  flushed := False;
  Lock.Release;
end;

function HEXToDec(S: AnsiString): Integer;
var
  Otv, Step, I, II: LongInt;
  Chislo: LongInt;
begin
  Otv := 0;
  II := Length(S);
  Step := -1;
  Result := 0;
  for I := II downto 1 do
  begin
    Inc(Step);
    case S[I] of
      AnsiChar('A'), AnsiChar('a'): Chislo := 10;
      AnsiChar('B'), AnsiChar('b'): Chislo := 11;
      AnsiChar('C'), AnsiChar('c'): Chislo := 12;
      AnsiChar('D'), AnsiChar('d'): Chislo := 13;
      AnsiChar('E'), AnsiChar('e'): Chislo := 14;
      AnsiChar('F'), AnsiChar('f'): Chislo := 15;
      AnsiChar('0')..AnsiChar('9'): Chislo := StrToInt(S[I]);
    end;
    Otv := Otv + Round(Chislo * Exp(Step * Ln(16)));
  end;
  Result := Otv;
end;

function hex_to_int(hexstr: AnsiString): Integer;
begin
  Result := HEXToDec(hexstr);
end;

//function hex_to_int(hexstr: AnsiString): Integer;
//var
//  res, sym, i : Integer;
//begin
//  for i := 0 to 8 do
//  begin
//    sym := Ord(hexstr[i]);
//    if Chr(sym) >= AnsiChar('a') then
//      begin
//        sym := sym - Ord(AnsiChar('a')) - Ord(AnsiChar('9')) - 1;
//      end
//    else if Chr(sym) >= '9' then
//      begin
//        sym := sym - Ord(AnsiChar('A')) - Ord(AnsiChar('9')) - 1;
//      end;
//    sym := sym - Ord(AnsiChar('0'));
//    res := (res shl 4) or (sym and $f);
//  end;
//  Result := res;
//end;

function int_to_hex(hexstr: AnsiString; dec: Integer): AnsiString;
begin
  Result := dec.ToHexString;
end;


//function int_to_hex(hexstr: AnsiString; dec: Integer): AnsiString;
//var
//  _t1, _t2, i : Integer;
//begin
//  for i := 7 downto 0 do
//  begin
//    _t2 := _t1 and $f;
//    hexstr[i] := _bufhex[_t2];
//    _t1 := _t1 shr 4;
//  end;
//  Result := hexstr;
//end;

procedure v8catalog.free_block(start: Integer);
var
  temp_buf: array[1..32] of AnsiChar;
  nextstart: Integer;
  prevempty: Integer;
begin
  if start = 0 then
    Exit;
  if start = $7FFFFFFF then
    Exit;

  Lock.Acquire;
  prevempty := start_empty;
  start_empty := start;

  repeat

    data.Seek(0, soFromBeginning);
    data.ReadBuffer(temp_buf, 31);
    nextstart := hex_to_int(temp_buf[20]);
    int_to_hex(temp_buf[2], $7FFFFFFF);
    if nextstart = $7FFFFFFF then
    begin
      int_to_hex(temp_buf[20], prevempty);
    end;
    data.Seek(start, soFromBeginning);
    data.WriteBuffer(temp_buf, 31);
    start := nextstart;

  until not start = $7FFFFFFF;

  is_emptymodified := True;
  is_modified := True;
  Lock.Release;

end;

function v8catalog.GetFile(FileName: string): v8file;
var
  ret: v8file;
begin
  Lock.Acquire;
  if files.TryGetValue(string.UpperCase(FileName), ret) then
    begin
      Result := ret;
    end
  else
    begin
      Result := nil;
    end;
  Lock.Release;
  Result := ret;
end;

function v8catalog.GetFirst: v8file;
begin
  Result := first;
end;

function v8catalog.GetParentCatalog: v8catalog;
begin
  if _file = nil then
    Result := nil;
  Result := _file.parent;
end;

function v8catalog.GetSelfFile: v8file;
begin
  Result := _file;
end;

function v8catalog.get_nextblock(start: Integer): Integer;
var
  ret : Integer;
begin
  Lock.Acquire;
  if (start = 0) or (start = $7FFFFFFF) then
  begin
    start := start_empty;
    if start = $7FFFFFFF then
      start := data.Size;
  end;
  ret := start;
  Lock.Release;
  Result := ret;
end;

procedure v8catalog.HalfClose;
begin
  Lock.Acquire;
  Flush;
  if is_cfu then
    begin
      cfu.Free;
      cfu := nil;
    end
  else
    begin
      data.Free;
      data := nil;
    end;
  Lock.Release;
end;

procedure v8catalog.HalfOpen(name: string);
begin
  Lock.Acquire;
  if is_cfu then
    cfu := TFileStream.Create(name, fmOpenReadWrite)
  else
    data := TFileStream.Create(name, fmOpenReadWrite);
  Lock.Release;
end;

function max(value1: Integer; value2: Integer): Integer;
begin
  if value1 > value2 then
    Result := value1
  else
    Result := value2;
end;

function min(value1: Integer; value2: Integer): Integer;
begin
  if value1 < value2 then
    Result := value1
  else
    Result := value2;
end;


function read_block(stream_from: TStream; start :Integer; stream_to: TStream = nil) : TStream;
var
  temp_buf: TArray<AnsiChar>;
  len: Integer;
  curlen: Integer;
  pos: Integer;
  readlen: Integer;
begin
  if stream_to = nil then
    stream_to := TMemoryStream.Create;
  stream_to.Seek(0, soFromBeginning);
  stream_to.Size := 0;

  if (start < 0) or (start = $7FFFFFFF) or (start > stream_from.Size) then
    begin
      Result := stream_to;
      Exit;
    end;

  stream_from.Seek(start, soFromBeginning);
  stream_from.Read(temp_buf, 31);

  len := hex_to_int(temp_buf[2]);
  if len = 0 then
  begin
    Result := stream_to;
    Exit;
  end;

  curlen := hex_to_int(temp_buf[11]);
  start  := hex_to_int(temp_buf[20]);

  readlen := min(len, curlen);
  stream_to.CopyFrom(stream_from, readlen);

  pos := readlen;

  while not start = $7FFFFFFF do
  begin
    stream_from.Seek(start, soFromBeginning);
    stream_from.Read(temp_buf, 31);

    curlen := hex_to_int(temp_buf[11]);
    start  := hex_to_int(temp_buf[20]);

    readlen := min(len - pos, curlen);
    stream_to.CopyFrom(stream_from, readlen);
    Inc(pos);
  end;

  Result := stream_to;


end;

procedure v8catalog.initialize;
var
  _ch : catalog_header;
  _temp: Integer;
  _name: string;
  _fi: fat_item;
  _temp_buf: TArray<AnsiChar>;
  _file_header: TMemoryStream;
  _fat: TStream;
  _prev: v8file;
  _file_: v8file;
  f: v8file;
  _countfiles, i: Integer;
begin
  is_destructed := False;
  data.Seek(0, soFromBeginning);
  data.ReadBuffer(_ch, 16);
  start_empty := _ch.start_empty;
  page_size := _ch.page_size;
  version := _ch.version;

  first := nil;

  _file_header := TMemoryStream.Create;
  _prev := nil;


  try
    if data.Size > 16 then
    begin
      _fat := read_block(data, 16);
      _fat.Seek(0, soFromBeginning);
      _countfiles := _fat.Size div 12;
      for i := 0 to _countfiles do
      begin
        _fat.Read(_fi, 12);
        read_block(data, _fi.header_start, _file_header);
        _file_header.Seek(0, soFromBeginning);
        //_temp_buf := TArray<AnsiChar>
        _file_header.Read(_temp_buf, _file_header.Size);
        _name := _temp_buf[20];
        _file_ := v8file.Create(Self, _name, _prev, _fi.data_start, _fi.header_start, Int64(0), Int64(0));
        if _prev = nil then
          first := _file_;
        _prev := _file_;
      end;
      _file_header.Free;
      _fat.Free;
    end;
  finally
    f := first;
    while f <> nil do
    begin
      f.Close;
      f := f.next;
    end;

    while first <> nil do
      first.Free;

    is_catalog := False;
    iscatalogdefined := True;

    first := nil;
    last := nil;
    start_empty := 0;
    page_size := 0;
    version := 0;
    zipped := False;
  end;

  last := _prev;
  is_fatmodified := False;
  is_emptymodified := False;
  is_modified := False;
  is_destructed := False;
  flushed := False;
  leave_data := False;

end;

function v8catalog.IsCatalog: Boolean;
var
  _filelen: Integer;
  _startempty: Integer;
  _t: array[1..32] of AnsiChar;
  _t2: array[1..32] of AnsiChar;
  at1: AnsiString;
  at2: AnsiString;
  P1: Pointer;
  P2: Pointer;
begin
  _startempty := -1;
  Lock.Acquire;
  if iscatalogdefined then
  begin
    Lock.Release;
    Result := is_catalog;
    Exit;
  end;

  iscatalogdefined := True;
  is_catalog := False;

  _filelen := data.Size;
  if _filelen = 16 then
  begin
    data.Seek(0, soFromBeginning);
    data.Read(_t, 16);

    at1 := ArrayToString(_t);
    at2 := _empty_catalog_template;
    if AnsiCompareStr(at1, at2) <> 0 then
    begin
      Lock.Release;
      Result := False;
      Exit;
    end
    else
    begin
      is_catalog := True;
      Lock.Release;
      Result := True;
      Exit;
    end;
  end;

  data.Seek(0, soFromBeginning);
  data.Read(_startempty, 4);
  if _startempty <> $7fffffff then
  begin
    if _startempty + 31 >= _filelen then
    begin
      Lock.Release;
      Result := False;
      Exit;
    end;
    data.Seek(_startempty, soFromBeginning);
    data.Read(_t, 31);
    if (_t[1] <> #$0D) or (_t[1] <> #$0A) or (_t[10] <> #$20) or (_t[19] <> #$20) or (_t[28] <> #$20) or (_t[29] <> #$0D) or (_t[30] <> #$0A) then
    begin
      Lock.Release;
      Result := False;
      Exit;
    end;
  end;
  if _filelen < 31 + 16 then
  begin
    Lock.Release;
    Result := False;
    Exit;
  end;
  data.Seek(16, soFromBeginning);
  data.Read(_t, 31);
  if (_t[1] <> #$0D) or (_t[1] <> #$0A) or (_t[10] <> #$20) or (_t[19] <> #$20) or (_t[28] <> #$20) or (_t[29] <> #$0D) or (_t[30] <> #$0A) then
  begin
    Lock.Release;
    Result := False;
    Exit;
  end;
  is_catalog := True;
  Lock.Release;
  Result := True;
end;

function v8catalog.IsOpen: Boolean;
begin
  Result := IsCatalog();
end;

function v8catalog.read_datablock(start: Integer): TStream;
var
  stream, stream2 : TStream;
begin
  if start = 0 then
    Result := TMemoryStream.Create;

  Lock.Acquire;
  stream := read_block(data, start);
  Lock.Release;

  if zipped then
  begin
    stream2 := TMemoryStream.Create;
    stream.Seek(0, soFromBeginning);
    ZInflateStream(stream, stream2); // Надо доделать !!!!!!!!!!!!!!
    stream.Free;
  end
  else
  begin
    stream2 := stream;
  end;
  Result := stream2;
end;

procedure v8catalog.SaveToDir(DirName: string);
var
  f: v8file;
begin
  CreateDir(DirName);
  if DirName.Substring(DirName.Length, 1) <> str_backslash then
    DirName := DirName + str_backslash;
  Lock.Acquire;
  f := first;
  while first <> nil do
  begin
    if f.IsCatalog then
      f.GetCatalog.SaveToDir(DirName + f.name)
    else
      f.SaveToFile(DirName + f.name);
    f.Close;
    f := f.next;
  end;
  Lock.Release;
end;

function v8catalog.write_block(block: TStream; start: Integer;
  use_page_size: Boolean; len: Integer): Integer;
var
  temp_buf: TArray<AnsiChar>;
  _t: TArray<AnsiChar>;
  firststart, nextstart, blocklen, curlen: Integer;
  isfirstblock, addwrite : Boolean;
  _ts: TMemoryStream;
  len1, len2 : Integer;

begin
  Lock.Acquire;
  if (data.Size = 16) and (start <> 16) then
  begin
    _ts:= TMemoryStream.Create;
    write_block(_ts, 16, True);

  end;

  if len = -1 then
  begin
    len := block.Size;
    block.Seek(0, soFromBeginning);
  end;

  start := get_nextblock(start);

  repeat

    if start = start_empty then
      begin
        data.Seek(start, soFromBeginning);
        data.ReadBuffer(temp_buf, 31);
        blocklen := hex_to_int(temp_buf[11]);
        nextstart := hex_to_int(temp_buf[20]);

        start_empty := nextstart;
        is_emptymodified := True;
      end
    else if start = data.Size then
      begin
        // memcpy(temp_buf, _block_header_template, 31);
        // CopyMemory(temp_buf, _block_header_template, 31); Надо доделать!!!!!!!!!!!!

        if use_page_size then
        begin
          if len > page_size then
          begin
            blocklen := len;
          end
          else
          begin
            blocklen := page_size;
          end;
        end
        else
        begin
            blocklen := len;
        end;

        int_to_hex(temp_buf[11], blocklen);
        nextstart := 0;
        if blocklen > len then
          addwrite := True;

      end
    else
      begin
        data.Seek(start, soFromBeginning);
        data.ReadBuffer(temp_buf, 31);
        blocklen := hex_to_int(temp_buf[11]);
        nextstart := hex_to_int(temp_buf[20]);
      end;

    if isfirstblock then
      len1 := len
    else
      len1 := 0;
    int_to_hex(temp_buf[2], len1);
    curlen := min(blocklen, len);
    if nextstart = 0 then
    begin
      nextstart := data.Size + 31 + blocklen;
    end
    else
    begin
      nextstart := get_nextblock(nextstart);
    end;

    if len <= blocklen then
    begin
      len2 := $7fffffff;
    end
    else
    begin
      len2 := nextstart;
    end;

    int_to_hex(temp_buf[20], len2);

		data.Seek(start, soFromBeginning);
		data.WriteBuffer(temp_buf, 31);
		data.CopyFrom(block, curlen);

    if addwrite then
    begin
//			_t = new char [blocklen - len];
//			memset(_t, 0, blocklen - len);

      data.WriteBuffer(_t, blocklen - len);
      addwrite := False;
    end;

    Dec(len, curlen);

    if isfirstblock then
    begin
      firststart := start;
      isfirstblock := False;
    end;

    start := nextstart;

  until (len > 0);

  if (start < data.Size) and (start <> start_empty) then
    free_block(start);

  is_modified := True;
  Lock.Release;
  Result := firststart;
end;

function v8catalog.write_datablock(block: TStream; start: Integer;
  _zipped: Boolean; len: Integer): Integer;
var
  stream, stream2 : TMemoryStream;
  ret: Integer;
begin
  if zipped or _zipped then
    begin
      if len = -1 then
        begin
          stream2 := TMemoryStream.Create;
          block.Seek(0, soFromBeginning);
          ZDeflateStream(block, stream2); // Нужно доделать!!!!!!!!!!!!
          Lock.Acquire;
          start := write_block(stream2, start, False);
          ret := start;
          Lock.Release;
          stream2.Free;
        end
      else
        begin
          stream := TMemoryStream.Create;
          stream.CopyFrom(block, len);
          stream2 := TMemoryStream.Create;
          stream.Seek(0, soFromBeginning);
          ZDeflateStream(stream, stream2); // Нужно доделать!!!!!!!!!!!!
          stream.Free;
          Lock.Acquire;
          start := write_block(stream2, start, False);
          ret := start;
          Lock.Release;
          stream2.Free;
        end;
    end
  else
    begin
      Lock.Acquire;
      start := write_block(block, start, False, len);
      ret := start;
      Lock.Release;
    end;

  Result := ret;

end;

{ TV8FileStream }

constructor TV8FileStream.Create(f: v8file; ownfile: Boolean);
begin
  _pos := 0;
  _file.streams.Add(Self);
end;

destructor TV8FileStream.Destroy;
begin
  if own then
    _file.Free
  else
    _file.streams.Clear;
end;

function TV8FileStream.Read(var Buffer: TArray<Byte>; Offset,
  Count: Integer): Integer;
var
  r: Integer;
begin
  r := _file.Read(Buffer, _pos, Count);
  Inc(_pos, r);
  Result := r;
end;

function TV8FileStream.Read(var Buffer, Count: Integer): Integer;
var
  r: Integer;
begin
  r := _file.Read(Buffer, _pos, Count);
  Inc(_pos, r);
  Result := r;
end;

function TV8FileStream.Seek(Offset: Integer; Origin: Word): Integer;
var
  l : Integer;
begin
  l := _file.GetFileLength();
  case Origin of
    soFromBeginning:
      begin
        if Offset >= 0 then
        begin
          if (Offset <= l) then
            _pos := Offset
          else
            _pos := l;
        end;
      end;
    soFromCurrent:
      begin
        if (_pos + Offset < l) then
          _pos := _pos + Offset
        else
          _pos := l;
      end;
    soFromEnd:
      begin
        if (Offset <= 0) then
        begin
          if Offset <= l then
            _pos := l - Offset
          else
            _pos := 0;
        end;
      end;
  end;
  Result := _pos;
end;

function TV8FileStream.Seek(Offset: Int64; Origin: TSeekOrigin): Integer;
var
  l : Int64;
begin
  l := _file.GetFileLength();
  case Origin of
    soBeginning:
      begin
        if Offset >= 0 then
        begin
          if (Offset <= l) then
            _pos := Offset
          else
            _pos := l;
        end;
      end;
    soCurrent:
      begin
        if (_pos + Offset < l) then
          _pos := _pos + Offset
        else
          _pos := l;
      end;
    soEnd:
      begin
        if (Offset <= 0) then
        begin
          if Offset <= l then
            _pos := l - Offset
          else
            _pos := 0;
        end;
      end;
  end;
  Result := _pos;
end;

function TV8FileStream.Write(var Buffer: TArray<Byte>; Offset,
  Count: Integer): Integer;
var
  r: Integer;
begin
  r := _file.Write(Buffer, _pos, Count);
  Inc(_pos, r);
  Result := r;
end;

function TV8FileStream.Write(var Buffer, Count: Integer): Integer;
var
  r: Integer;
begin
  r := _file.Write(Buffer, _pos, Count);
  Inc(_pos, r);
  Result := r;
end;

end.
