unit FileFormat;

interface

uses System.Classes, System.IOUtils, System.SysUtils, Winapi.Windows, NodeTypes,
     System.RegularExpressions;

const
  SIG_GIF87   = 'GIF87a'; // версия 87 года
  SIG_GIF89   = 'GIF89a';
  SIG_UTF8    = '#$EF#$BB#$BF';
  SIG_PCX25   = '#$0A#$00#$01';
  SIG_PCX28P  = '#$0A#$02#$01';
  SIG_PCX28   = '#$0A#$03#$01';
  SIG_PCX30   = '#$0A#$05#$01';
  SIG_BMP     = '#$42#$4d';
  SIG_JPG     = '#$FF#$D8#$FF';
  SIG_PNG     = '#$89#$50#$4E#$47#$0D#$0A#$1A#$0A#$00#$00#$00#$0D#$49#$48#$44#$52';



  SIG_BIGTIFF = '#$4D#$4D#$00#$2B';
  SIG_TIFFBE  = '#$4D#$4D#$00#$2A';
  SIG_TIFFLE  = '#$49#$49#$2A#$00';
  SIG_ICO     = '#$00#$00#$01#$00';
  SIG_WMFOLD  = '#$01#$00#$09#$00#$00#$03';
  SIG_WMF     = '#$D7#$CD#$C6#$9A#$00#$00';
  SIG_EMF     = '#$01#$00#$00#$00';
  SIG_ZIP     = 'PK';


type
  file_format = (
      ff_unknown, // неизвестный
      ff_gif,     // GIF
      ff_utf8,    // UTF-8
      ff_pcx,     // PCX
      ff_bmp,
      ff_jpg,
      ff_png,
      ff_tiff,
      ff_ico,
      ff_wmf,
      ff_emf,
      ff_zip
  );

  function get_file_format(s: TStream) : file_format;


var
  //SIG_PNG_ARR : array[0..15] of Integer = ($89,$50,$4E,$47,$0D,$0A,$1A,$0A,$00,$00,$00,$0D,$49,$48,$44,$52);
  SIG_PNG_ARR : TBytes = ($89,$50,$4E,$47,$0D,$0A,$1A,$0A,$00,$00,$00,$0D,$49,$48,$44,$52);

implementation

  function get_file_format(s: TStream) : file_format;
  var
    len: Integer;
    //buffer: array[1..32] of AnsiChar;
    buffer: TBytes;
    res : Boolean;
  begin
    s.Seek(0, soFromBeginning);
    SetLength(buffer, 16);
    len := s.Read(buffer, 16);

    res := CompareMem(@SIG_PNG_ARR[0], buffer, 16);

    if len < 2 then
      Result := ff_unknown
    else
      Result := ff_unknown;


  end;
end.
