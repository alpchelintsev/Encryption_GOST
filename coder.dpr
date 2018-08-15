{$apptype console}
program coder;
uses Forms;

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
  ); // ������ �����

var
  K: array[0..7] of LongWord; // ����

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

// �᭮���� 蠣 �ਯ⮯८�ࠧ������
procedure MainStep(X: LongWord;   // ������� ����
                   var N: Int64); // 64-� ���� ���� ������
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

// ������ 横��

function _32z(N: Int64): Int64; // 32-�
var
  i,j: Byte;
  N_: record
    N2,N1: LongWord
  end absolute Result;
  S: LongWord;
begin
  Result:=N;
  for i:=1 to 3 do
    for j:=0 to 7 do
      MainStep(K[j],Result);
  for j:=7 downto 0 do
    MainStep(K[j],Result);
  with N_ do
  begin
    S:=N1;
    N1:=N2;
    N2:=S
  end
end;

function _16z(N: Int64): Int64; // 16-�
var
  i,j: Byte;
begin
  Result:=N;
  for i:=1 to 2 do
    for j:=0 to 7 do
      MainStep(K[j],Result)
end;

var
  v: Byte;
  vr: Int64;
  rec: record
    L: LongInt;    // ��᫮ �����뢠���� ����
    I: LongInt     // ���⮢�⠢��
  end absolute vr;
  sz: LongInt;     // ������ �室���� 䠩��
  InFile1: File of Byte;
  InFile2: File of Int64;

procedure Equalization;
// ��ࠢ������� �室���� 䠩�� �� �����, ��⭮� 8 ����

var
  j: LongInt;

begin
  sz:=FileSize(InFile1);
  with rec do
  begin
    L:=((sz div 8+1)*8-sz) mod 8;
    Seek(InFile1,sz);
    Randomize;
    for j:=1 to L do
    begin
      v:=Random(256);
      Write(InFile1,v)
    end;
    L:=L shl 5
  end
end;

var
  OutFile: File of Int64;

procedure _Coder; // ���஢���� � ��ࠡ�⪠ ���⮢�⠢��
var
  S,T: Int64;
begin
  S:=0;
  while not Eof(InFile2) do
  begin
    Read(InFile2,T);
    S:=_16z(S xor T);
    T:=_32z(T);
    Write(OutFile,T)
  end;
  rec.I:=S;
  Write(OutFile,vr)
end;

procedure Saw; // ��१��� �� �室���� 䠩�� �ਯ�ᠭ�� �����
begin
  Seek(InFile1,sz);
  Truncate(InFile1)
end;

var
  FileName: String;

begin
  WriteLn('����� ���⮩ ������ (�����) � ��ࠡ�⪠ ���⮢�⠢��'#13#10);
  WriteLn('������ ����: '#13#10);
  for v:=0 to 7 do
  begin
    Write('������� � ����஬ ',v,' > ');
    ReadLn(K[v])
  end;
  Write(#13#10'������ ��� ���㥬��� 䠩�� > ');
  ReadLn(FileName);
  AssignFile(InFile1,FileName);
  {$I-}Reset(InFile1);{$I+}
  if IOResult<>0 then
  begin
    WriteLn('�訡�� �� ����⨨ 䠩��');
    exit
  end;
  Equalization;
  CloseFile(InFile1);
  AssignFile(InFile2,FileName);
  Reset(InFile2);
  Write('������ ��� ��室���� 䠩�� > ');
  ReadLn(FileName);
  AssignFile(OutFile,FileName);
  {$I-}Rewrite(OutFile);{$I+}
  if IOResult<>0 then
  begin
    WriteLn('�訡�� �� ᮧ����� 䠩��');
    CloseFile(InFile2);
    exit
  end;
  _Coder;
  CloseFile(OutFile);
  CloseFile(InFile2);
  Reset(InFile1);
  Saw;
  CloseFile(InFile1);
  WriteLn(#13#10'���� ����஢��!!!')
end.
