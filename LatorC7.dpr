program LatorC7;

{$R *.dres}

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles,
  translator in 'translator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Glossy');
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
