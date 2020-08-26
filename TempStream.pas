unit TempStream;


interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows;

type

TTempStreamStaticInit = class
public
  constructor Create();
  destructor Destroy();

end;


TTempStream = class(THandleStream)
public
  class var
    tempcat : string;
    tempname : string;
    tempno : Integer;
    constructor Create();
    destructor Destroy();
end;





implementation

{ TTempStreamStaticInit }

constructor TTempStreamStaticInit.Create;
var
  temppath: string;
  tempfile: string;
begin
  inherited Create;
  if Length(TTempStream.tempcat) = 0 then
  begin
    temppath := TPath.GetTempPath();
    tempfile := TPath.GetTempFileName();

    TTempStream.tempcat := tempfile;
    DeleteFile(PWideChar(TTempStream.tempcat));
    CreateDir(TTempStream.tempcat);
    TTempStream.tempname := TTempStream.tempcat + '\\t';
  end;

end;

destructor TTempStreamStaticInit.Destroy;
begin
  RemoveDir(TTempStream.tempcat);
end;

{ TTempStream }

constructor TTempStream.Create;
var
  sn: string;
begin
  inherited Create(0);
  sn := tempname;
  FHandle := CreateFile(PWideChar(sn), GENERIC_READ or GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_DELETE_ON_CLOSE, 0);
end;

destructor TTempStream.Destroy;
begin
  CloseHandle(FHandle);
end;

end.
