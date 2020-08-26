unit MetaRead;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, AdvEdit, AdvEdBtn,
  AdvFileNameEdit, Parse_tree, MessageRegistration, Vcl.ComCtrls, System.Syncobjs, System.Ioutils, FileFormat, APIcfBase;

type
  Messager = class;

  TForm1 = class(TForm)
    Button1: TButton;
    PageControlMain: TPageControl;
    TabSheetConfig: TTabSheet;
    TabSheetLog: TTabSheet;
    MemoLog: TMemo;
    mess: Messager;
    Memo1: TMemo;
    AdvFileNameEdit1: TAdvFileNameEdit;
    TabSheet1: TTabSheet;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Button2: TButton;
    procedure FormActivate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  Messager = class(MessageRegistrator)
  private
    logfile : string;
    _s: string;
    FormatSettings: TFormatSettings;
    MemoLog : TMemo;
    Lock : TCriticalSection;
    procedure initFormatSettings;
  public
    procedure setlogfile(_logfile: string);
    procedure AddMessage(_message_ : string; mstate: MessageState; param: TStringList = nil); virtual;
    procedure Status(_message_ : string); virtual;
    procedure mainthreadAddMessage;
    procedure mainthreadStatus;
    constructor Create; overload;
    constructor Create(_logfile: string; _MemoLog: TMemo); overload;
    destructor Destroy;
  end;

var
  Form1: TForm1;
  cur_thread : TThread;


implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  fs: TFileStream;
  scobcotree: tree;
  s: string;
  res: Boolean;
  ff : file_format;
begin
  if AdvFileNameEdit1.Text.Length <> 0 then
    begin
      fs := TFileStream.Create(AdvFileNameEdit1.Text, fmOpenRead);
      ff := get_file_format(fs);
//      //scobcotree := parse_1Cstream(fs)
//      //scobcotree := parse_1Cstream(fs, mess, '');
//      mess.AddMessage('Начало тестирования скобочного дерева.', msInfo);
//      res := test_parse_1Ctext(fs,mess,'');
//      mess.AddMessage('Успешное окончание тестирования скобочного дерева.', msInfo);
//      //scobcotree.outtext(s);
//      //s := outtext(scobcotree);
//      Memo1.Lines.Clear;
//      Memo1.Lines.Add(s);
      fs.Free;
    end;

end;

procedure TForm1.Button2Click(Sender: TObject);
var
  pr: Integer;

begin
  // Edit1.Text - hex значение
  // Edit2.Text - dec значение
  pr := pr.MaxValue;

  //pr := HEXToDec(AnsiString(Edit1.Text));
  // pr := hex_to_int(AnsiString(Edit1.Text));


  //Edit2.Text := int_to_hex(Edit2.Text, StrToInt(Edit1.Text));
  Edit2.Text := IntToStr(hex_to_int(Edit1.Text));
end;

procedure TForm1.FormActivate(Sender: TObject);
begin
  Update;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  //mess = new Messager(L"", MemoLog);
  mess := Messager.Create('', MemoLog);
end;

{ Messager }

constructor Messager.Create;
begin
  inherited Create;
  initFormatSettings;
  Lock := TCriticalSection.Create;
end;

procedure Messager.AddMessage(_message_: string; mstate: MessageState;
  param: TStringList);
var
  s: string;
  i: Integer;

begin
  s := DateTimeToStr(Now(), FormatSettings);
  s := s + ' ';
  case mstate of
    msEmpty: s := s + '<>';
    msSuccesfull: s := s + '<ok>';
    msWarning: s := s + '<warning>';
    msInfo: s := s + '<info>';
    msError: s := s + '<error>';
    msWait: s := s + '<wait>';
    msHint: s := s + '<hint>';
    else
      s := s + '<>';
  end;
  s := s + ' ';
  s := s + _message_;
  if param <> nil then
  begin
    for i := 0 to param.Count do
      begin
        s := s + #10#13#9;
        s := s + param[i];
      end;
  end;

  s := s + #10#13;
  Lock.Acquire;
  _s := s;
  if cur_thread <> nil then
    TThread.Synchronize(cur_thread, mainthreadAddMessage)
  else
    mainthreadAddMessage;
  Lock.Release;
end;

constructor Messager.Create(_logfile: string; _MemoLog: TMemo);
begin
  initFormatSettings;
  setlogfile(_logfile);
  MemoLog := _MemoLog;
  Lock := TCriticalSection.Create;
end;

destructor Messager.Destroy;
begin
  Lock.Free;
  inherited Destroy;
end;

procedure Messager.initFormatSettings;
begin
  FormatSettings.DateSeparator   := '.';
  FormatSettings.TimeSeparator   := ':';
  FormatSettings.ShortDateFormat := 'dd.mm.yyyy';
  FormatSettings.LongTimeFormat  := 'hh:mm:ss:zzz';
end;

procedure Messager.mainthreadAddMessage;
var
  log : TFileStream;
  sw: TStreamWriter;
  s: string;
begin
  if MemoLog <> nil then
    MemoLog.Lines.Add(_s);

  if logfile.Length > 0 then
  begin
    if FileExists(logfile) then
      begin
        log := TFileStream.Create(logfile, fmOpenReadWrite or fmShareDenyNone);
        log.Seek(0, soFromEnd);
      end
    else
      begin
        log := TFileStream.Create(logfile, fmCreate or fmShareDenyNone);
        log.Write(TEncoding.UTF8.GetPreamble, Length(TEncoding.UTF8.GetPreamble));
      end;
    sw := TStreamWriter.Create(log, TEncoding.UTF8, 4096);
    s := _s + #13#10;
    sw.Write(s);

    sw.Free;
    log.Free;
  end;
end;

procedure Messager.mainthreadStatus;
begin
//	FormMain->PanelСurConfPath->Caption = *_s;
//	FormMain->PanelСurConfPath->Update();
end;

procedure Messager.setlogfile(_logfile: string);
begin
  if _logfile.Length > 0 then
    begin
      logfile := TPath.GetFullPath(_logfile);
      if FileExists(logfile) then
        DeleteFile(logfile);
    end
  else
    logfile := _logfile;
end;

procedure Messager.Status(_message_: string);
begin
  Lock.Acquire;
  _s := _message_;
  if cur_thread <> nil then
    TThread.Synchronize(cur_thread, mainthreadStatus)
  else
    mainthreadStatus;
  Lock.Release;
end;

end.
