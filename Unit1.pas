unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, Vcl.ExtCtrls,
  Vcl.StdCtrls,System.JSON,system.Threading,vcl.Clipbrd,Vcl.Menus,translator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Memo2: TMemo;
    Button1: TButton;
    TrayIcon1: TTrayIcon;
    NetHTTPClient1: TNetHTTPClient;
    Label1: TLabel;
    Label2: TLabel;
    Button2: TButton;
    Label3: TLabel;
    Button3: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TrayIcon1DblClick(Sender: TObject);
  private
   FHotKeyRegistered: Boolean;
   FCurrentDirection: Integer; // 1 - en->ru, 2 - ru->en
   FMinimized: Boolean;
   procedure WMHotKey(var Message: TWMHotKey); message WM_HOTKEY;
   procedure ShowAppClick(Sender: TObject);
   procedure CloseAppClick(Sender: TObject);
   { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  CurrentDirection: Integer; // 1 = en->ru, 2 = ru->en

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if Trim(Memo1.Text) = '' then
  begin
    ShowMessage('Введите текст для перевода');
    Exit;
  end;

  Memo2.Text := 'Переводим...';
  Application.ProcessMessages;

  try
    if CurrentDirection = 1 then
      Memo2.Text := TranslateText(Memo1.Text, 'en', 'ru')
    else
      Memo2.Text := TranslateText(Memo1.Text, 'ru', 'en');
  except
    on E: Exception do
      Memo2.Text := 'Ошибка: ' + E.Message;
  end;
end;





procedure TForm1.Button2Click(Sender: TObject);
var
  TempText: string;
begin
  // Меняем местами тексты в мемо
  TempText := Memo1.Text;
  Memo1.Text := Memo2.Text;
  Memo2.Text := TempText;

  // Меняем направление перевода
  if CurrentDirection = 1 then
  begin
    CurrentDirection := 2;
    Label1.Caption := 'Russian';
    Label2.Caption := 'English';
    Label3.Caption := 'Текущее направление: ru→en';
  end
  else
  begin
    CurrentDirection := 1;
    Label1.Caption := 'English';
    Label2.Caption := 'Russian';
    Label3.Caption := 'Текущее направление: en→ru';
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if Trim(Memo1.Text) <> '' then
  begin
    Clipboard.AsText := Memo1.Text;
  end
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if Trim(Memo2.Text) <> '' then
  begin
    Clipboard.AsText := Memo2.Text;
  end
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not Application.Terminated then
  begin
    Hide;
    CanClose := False;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
    CurrentDirection := 1; // Начинаем с en->ru
  Label1.Caption := 'English';
  Label2.Caption := 'Russian';
  Label3.Caption := 'Текущее направление: en→ru';
  TrayIcon1.Visible := True;
  TrayIcon1.Hint := 'LatorC7';
  FMinimized := False;

  if RegisterHotKey(Handle, 1, MOD_CONTROL or MOD_SHIFT, Ord('T')) then
  begin
    FHotKeyRegistered := True;
  end;
  end;


procedure TForm1.WMHotKey(var Message: TWMHotKey);
begin
  case Message.HotKey of
    1: // Ctrl+Shift+T
    begin
      // Если форма видима, сворачиваем в трей
      if Visible then
      begin
        Hide;
      end
      else
      begin
        // Если форма скрыта, показываем её
        Show;
        WindowState := wsNormal;
        BringToFront;
        SetForegroundWindow(Handle);
      end;
    end;
  end;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
var
  MenuItem: TMenuItem;
  PopupMenu: TPopupMenu;
begin
  // Создаем меню для трей-иконки
  TrayIcon1.PopupMenu := TPopupMenu.Create(Self);
  TrayIcon1.PopupMenu.Items.Add(TMenuItem.Create(TrayIcon1.PopupMenu));
  TrayIcon1.PopupMenu.Items[0].Caption := 'Показать приложение';
  TrayIcon1.PopupMenu.Items[0].OnClick := ShowAppClick;

  TrayIcon1.PopupMenu.Items.Add(TMenuItem.Create(TrayIcon1.PopupMenu));
  TrayIcon1.PopupMenu.Items[1].Caption := 'Закрыть';
  TrayIcon1.PopupMenu.Items[1].OnClick := CloseAppClick;
end;

procedure TForm1.TrayIcon1DblClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
end;

// Для выхода из приложения через трей

procedure TForm1.ShowAppClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
end;


procedure TForm1.CloseAppClick(Sender: TObject);
begin
  Application.Terminate;
end;


end.
