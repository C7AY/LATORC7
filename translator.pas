unit translator;

interface

uses
  System.Classes, System.SysUtils, System.Net.HttpClient, System.Net.HttpClientComponent,
  Vcl.Dialogs, System.Net.URLClient;

function TranslateText(const TextToTranslate: string; FromLang, ToLang: string): string;

implementation

function URLEncode(const S: string): string;
var
  I: Integer;
  C: WideChar;
  Bytes: TBytes;
  Hex: string;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if (C >= 'A') and (C <= 'Z') or (C >= 'a') and (C <= 'z') or (C >= '0') and (C <= '9') then
      Result := Result + C
    else if C = ' ' then
      Result := Result + '+'
    else
    begin
      // Кодируем символ как UTF-8 байты и преобразуем в %XX формат
      Bytes := TEncoding.UTF8.GetBytes(C);
      for var B in Bytes do
      begin
        Hex := IntToHex(B, 2);
        Result := Result + '%' + UpperCase(Hex);
      end;
    end;
  end;
end;

function TranslateText(const TextToTranslate: string; FromLang, ToLang: string): string;
var
  HttpClient: TNetHTTPClient;
  URL: string;
  Response: string;
  StartPos, EndPos: Integer;
  TempResult: string;
  EncodedText: string;
begin
  Result := '';

  try
    // Ограничиваем длину текста для предотвращения проблем
    var ProcessText := TextToTranslate;
    if Length(ProcessText) > 1000 then
      ProcessText := Copy(ProcessText, 1, 1000);

    HttpClient := TNetHTTPClient.Create(nil);
    try
      // Используем правильное кодирование UTF-8 для кириллических символов
      EncodedText := URLEncode(ProcessText);

      // Используем URL для перевода с правильными параметрами
      URL := 'https://translate.google.com/m?sl=' + FromLang + '&tl=' + ToLang +
             '&hl=en&q=' + EncodedText;

      Response := HttpClient.Get(URL).ContentAsString;

      // Извлекаем текст из result-container (это и есть перевод)
      StartPos := Pos('class="result-container">', Response);
      if StartPos > 0 then
      begin
        StartPos := StartPos + Length('class="result-container">');
        EndPos := Pos('</div>', Response, StartPos);
        if EndPos > StartPos then
        begin
          TempResult := Copy(Response, StartPos, EndPos - StartPos);

          // Очищаем HTML теги из результата
          TempResult := StringReplace(TempResult, '<br>', #13#10, [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '</span>', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '<span class="t0">', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '<b>', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '</b>', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '<i>', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '</i>', '', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '&nbsp;', ' ', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '&#39;', '''', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '&quot;', '"', [rfReplaceAll]);
          TempResult := StringReplace(TempResult, '&amp;', '&', [rfReplaceAll]);

          // Убираем все оставшиеся HTML теги
          while Pos('<', TempResult) > 0 do
          begin
            StartPos := Pos('<', TempResult);
            EndPos := Pos('>', TempResult, StartPos);
            if EndPos > StartPos then
            begin
              TempResult := Copy(TempResult, 1, StartPos - 1) + Copy(TempResult, EndPos + 1);
            end
            else
              Break;
          end;

          Result := Trim(TempResult);
        end;
      end;

      // Если не нашли через result-container, пробуем другие способы
      if Trim(Result) = '' then
      begin
        // Попробуем найти через span.t0
        StartPos := Pos('<span class="t0">', Response);
        if StartPos > 0 then
        begin
          StartPos := StartPos + Length('<span class="t0">');
          EndPos := Pos('</span>', Response, StartPos);
          if EndPos > StartPos then
          begin
            TempResult := Copy(Response, StartPos, EndPos - StartPos);
            Result := Trim(TempResult);
          end;
        end;
      end;

      // Если всё равно не удалось, возвращаем сообщение об ошибке
      if Trim(Result) = '' then
      begin
        Result := 'Не удалось извлечь перевод. Попробуйте упростить текст.';
      end;

    finally
      HttpClient.Free;
    end;

  except
    on E: Exception do
      Result := 'Ошибка: ' + E.Message;
  end;
end;

end.

