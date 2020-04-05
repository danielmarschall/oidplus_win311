program OIDPLUS;

uses
  Forms,
  SortStr in 'SortStr.pas',
  Main in 'Main.pas' {Form1};

{$R *.RES}

begin
  { Application.Initialize; }
  Application.Title := 'OIDPlus';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
