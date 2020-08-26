unit Common;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions;
const
  hexdecode = '0123456789abcdef';

//procedure time1CD_to_FileTime(ft : FILETIME; time1CD : AnsiChar);
//function reverse_byte_order(value: Integer): Integer;
//function GUIDas1C(fr: string): string;
//function GUIDasMS(fr: string): string;
//function GUID_to_string(guid: TGUID): string;
//function string_to_GUID(str: string; guid: TGUID): Boolean;
//function GUID_to_string_flat(guid: TGUID): string;
//function string_to_GUID_flat(str: string; guid: TGUID): Boolean;
//function two_hex_digits_to_byte(hi: Char; lo: Char; res: Char): Boolean;
//function string1C_to_date(str: string; bytedate: string): Boolean;
//function string_to_date(str: string; bytedate: string): Boolean;
//function date_to_string1C(bytedate: string): string;
//function date_to_string(bytedate: string): string;
function tohex(n: Integer): string;
//function tohex64(n: Int64): string;
//function hexstring(buf: string; n: Integer): string; overload;
//function hexstring(str: TStream): string; overload;

implementation

function tohex(n: Integer): string;
begin
  Result := '$' + IntToHex(n, 0);
end;

end.
