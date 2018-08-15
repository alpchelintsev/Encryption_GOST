{$apptype console}
program decoder;
uses Forms, Dialogs;

const
  H: array[0..7,0..15] of Byte = (
    (0,1,2,3,4,5,4,7,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,5,5,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,2,6,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,1,9,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,6,8,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,6,8,8,9,10,11,12,13,14,15),
    (0,1,2,3,4,5,1,7,8,9,10,11,12,13,14,15)
  ); // Таблица замен

var
  K: array[0..7] of LongWord; // Ключ

function GetValue(m: Byte; S: LongWord): Byte;
var
  n: Byte;
begin
  n:=28-4*m;
  Result:=($F shl n) and S shr n
end;

procedure SetValue(V,m: Byte; var S: LongWord);
var
  n: Byte;
begin
  n:=28-4*m;
  S:=not($F shl n) and S or V shl n
end;

// Основной шаг криптопреобразования
procedure MainStep(X: LongWord;   // Элемент ключа
                   var N: Int64); // 64-х битный блок данных
var
  N_: record
    N2,N1: LongWord
  end absolute N;
  S: LongWord;
  i: Byte;
begin
  with N_ do
  begin
    S:=N1 xor X;
    for i:=0 to 7 do
      SetValue(H[i,GetValue(i,S)],i,S);
    asm
      rol S,11
    end;
    S:=S xor N2;
    N2:=N1;
    N1:=S
  end
end;

// Базовые циклы

function _32r(N: Int64): Int64; // 32-Р
var
  i,j: Byte;
  N_: record
    N2,N1: LongWord
  end absolute Result;
  S: LongWord;
begin
  Result:=N;
  for j:=0 to 7 do
    MainStep(K[j],Result);
  for i:=1 to 3 do
    for j:=7 downto 0 do
      MainStep(K[j],Result);
  with N_ do
  begin
    S:=N1;
    N1:=N2;
    N2:=S
  end
end;

function _16z(N: Int64): Int64; // 16-З
var
  i,j: Byte;
begin
  Result:=N;
  for i:=1 to 2 do
    for j:=0 to 7 do
      MainStep(K[j],Result)
end;

var
  T: Int64;
  rec: record
    L: LongInt;    // Число дописываемых байт
    I: LongInt     // Имитовставка
  end absolute T;
  InFile,OutFile1: File of Int64;
  OutFile2: File of Byte;

procedure _Decoder; // Дешифрование и проверка имитовставки
var
  S: Int64;
begin
  S:=0;
  while true do
  begin
    if FilePos(InFile)=FileSize(InFile)-1 then break;
    Read(InFile,T);
    T:=_32r(T);
    Write(OutFile1,T);
    S:=_16z(S xor T)
  end;
  Read(InFile,T);
  with rec do
  begin
    if I<>LongInt(S) then
      MessageDlg('Ошибка в расшифрованном файле',mtError,[mbOk],0);
    L:=L shr 5
  end
end;

procedure Saw; // Отрезать от выходного файла байты
begin
  Seek(OutFile2,FileSize(OutFile2)-rec.L);
  Truncate(OutFile2)
end;

var
  i: Byte;
  FileName: String;

begin
  WriteLn('Режим простой замены (дешифратор) и проверка имитовставки'#13#10);
  WriteLn('Введите ключ: '#13#10);
  for i:=0 to 7 do
  begin
    Write('Элемент с номером ',i,' > ');
    ReadLn(K[i])
  end;
  Write(#13#10'Введите имя входного файла > ');
  ReadLn(FileName);
  AssignFile(InFile,FileName);
  {$I-}Reset(InFile);{$I+}
  if IOResult<>0 then
  begin
    WriteLn('Ошибка при открытии файла');
    exit
  end;
  Write('Введите имя выходного файла > ');
  ReadLn(FileName);
  AssignFile(OutFile1,FileName);
  {$I-}Rewrite(OutFile1);{$I+}
  if IOResult<>0 then
  begin
    WriteLn('Ошибка при создании файла');
    CloseFile(InFile);
    exit
  end;
  _Decoder;
  CloseFile(InFile);
  CloseFile(OutFile1);
  AssignFile(OutFile2,FileName);
  Reset(OutFile2);
  Saw;
  CloseFile(OutFile2);
  WriteLn(#13#10'Файл расшифрован!!!')
end.
