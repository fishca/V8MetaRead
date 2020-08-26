program V8MetaRead;

uses
  Vcl.Forms,
  MetaRead in 'MetaRead.pas' {Form1},
  APIcfBase in 'APIcfBase.pas',
  Base64 in 'Base64.pas',
  Class_1CD in 'Class_1CD.pas',
  Common in 'Common.pas',
  ConfigStorage in 'ConfigStorage.pas',
  CRC32 in 'CRC32.pas',
  FileFormat in 'FileFormat.pas',
  MessageRegistration in 'MessageRegistration.pas',
  MetaData in 'MetaData.pas',
  NodeTypes in 'NodeTypes.pas',
  Parse_tree in 'Parse_tree.pas',
  TempStream in 'TempStream.pas',
  ZZlib in 'ZZlib.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
