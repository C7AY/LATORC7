unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.Net.URLClient,
  System.Net.HttpClient, System.Net.HttpClientComponent, Vcl.ExtCtrls,
  Vcl.StdCtrls,System.JSON,system.Threading,vcl.Clipbrd,Vcl.Menus;

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
   FCurrentDirection: Integer; // 1 - en->ru, 2 - ru->en
   FMinimized: Boolean;
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
var
  HttpClient: TNetHTTPClient;
  URL: string;
  Response: IHTTPResponse;
  RawResponse: string;
begin
  // Проверка на пустой ввод
  if Trim(Memo1.Text) = '' then
  begin
    ShowMessage('Введите текст для перевода');
    Exit;
  end;

  Memo2.Text := 'Переводим...';
  Application.ProcessMessages;

  try
    HttpClient := TNetHTTPClient.Create(nil);

    // Используем Google Translate с правильным направлением
    if CurrentDirection = 1 then
    begin
      // en->ru
      URL := 'https://translate.google.com/m?hl=en&sl=en&tl=ru&ie=UTF-8&prev=_m&q=' +
             StringReplace(Memo1.Text, ' ', '+', [rfReplaceAll]);
    end
    else
    begin
      // ru->en
      URL := 'https://translate.google.com/m?hl=en&sl=ru&tl=en&ie=UTF-8&prev=_m&q=' +
             StringReplace(Memo1.Text, ' ', '+', [rfReplaceAll]);
    end;

    Response := HttpClient.Get(URL);
    if Response <> nil then
    begin
      RawResponse := Response.ContentAsString;

      // Парсим результат из HTML
      var StartPos := Pos('class="result-container">', RawResponse);
      if StartPos > 0 then
      begin
        StartPos := StartPos + Length('class="result-container">');
        var EndPos := Pos('</div>', RawResponse, StartPos);
        if EndPos > StartPos then
        begin
          Memo2.Text := Copy(RawResponse, StartPos, EndPos - StartPos);
        end
        else
        begin
          Memo2.Text := 'Не удалось извлечь перевод';
        end;
      end
      else
      begin
        // Альтернативный поиск
        var Pos1 := Pos('<span class="t0">', RawResponse);
        if Pos1 > 0 then
        begin
          Pos1 := Pos1 + Length('<span class="t0">');
          var Pos2 := Pos('</span>', RawResponse, Pos1);
          if Pos2 > Pos1 then
          begin
            Memo2.Text := Copy(RawResponse, Pos1, Pos2 - Pos1);
          end;
        end
        else
        begin
          Memo2.Text := 'Не удалось найти перевод в ответе';
        end;
      end;
    end
    else
    begin
      Memo2.Text := 'Ошибка соединения с сервером';
    end;

  except
    on E: Exception do
    begin
      Memo2.Text := 'Ошибка: ' + E.Message;
    end;
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
   // Регистрируем горячую клавишу Ctrl+Shift+T
  RegisterHotKey(Handle, 1, MOD_CONTROL or MOD_SHIFT, Ord('T'));
    CurrentDirection := 1; // Начинаем с en->ru
  Label1.Caption := 'English';
  Label2.Caption := 'Russian';
  Label3.Caption := 'Текущее направление: en→ru';
  TrayIcon1.Visible := True;
  TrayIcon1.Hint := 'LatorC7';
  FMinimized := False;
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
