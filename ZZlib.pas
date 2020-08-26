unit ZZlib;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions, System.Syncobjs, System.Generics.Collections, System.WideStrUtils, System.ZLib;


procedure ZInflateStream(stream1, stream2 : TStream);
procedure ZDeflateStream(stream1, stream2 : TStream);


implementation

// ����������
procedure ZInflateStream(stream1, stream2 : TStream);
begin
  ZDecompressStream(stream1, stream2);
end;

// ������
procedure ZDeflateStream(stream1, stream2 : TStream);
begin
  ZCompressStream(stream1, stream2);
end;

end.
