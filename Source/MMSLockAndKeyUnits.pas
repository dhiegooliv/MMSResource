unit MMSLockAndKeyUnits;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

  function Lock(ASource, AKey : string): string;
  function Key(ASource, AKey : string): string;

  function En(Source, Key: string): string;
  function Un(Source, Key: string): string;
  // ���ܷ���һ(ͨ����Կ���ܽ���)
  function EnKey(Source, Key: string): string;
  function UnKey(Source, Key: string): string;
  //���ܷ������������ܽ��ܣ�
  function EnXor(str: string): string;
  function UnXor(str: string): string;

var
  XorKey: array[0..7] of Byte = ($B2, $09, $AA, $55, $93, $6D, $84, $47);

implementation

function Lock(ASource, AKey : string): string;
begin
  Result := En(ASource, AKey);
end;
function Key(ASource, AKey : string): string;
begin
  Result := Un(ASource, AKey);
end;

function En(Source, Key: string): string;
begin
  Result := EnXor(EnKey(Source, Key));
end;
function Un(Source, Key: string): string;
begin
  Result := UnKey(UnXor(Source), Key);
end;
//////////////////////////////////////////////////////////////////////
// ������Roube  22-05-2012
// ���棺Roube
// ���ܣ�������Կ����
// ������Src:Դ Key:�ܳ�
//////////////////////////////////////////////////////////////////////
function EnKey(Source, Key: string): string;
var
  KeyLen: integer;
  KeyPos: integer;
  Offset: integer;
  Dest: string;
  SrcPos: integer;
  SrcAsc: integer;
  Range: integer;
begin
  KeyLen := Length(Key);
  if KeyLen = 0 then
    Key := 'Roube';
  KeyPos := 0;
  Range := 256;
  randomize;
  Offset := random(Range);
  Dest := format('%1.2x', [Offset]);
  for SrcPos := 1 to Length(Source) do
  begin
    SrcAsc := (Ord(Source[SrcPos]) + Offset) mod 255;
    if KeyPos < KeyLen then
      KeyPos := KeyPos + 1
    else
      KeyPos := 1;
    SrcAsc := SrcAsc xor Ord(Key[KeyPos]);
    Dest := Dest + format('%1.2x', [SrcAsc]);
    Offset := SrcAsc;
  end;
  Result := Dest;
end;
//////////////////////////////////////////////////////////////////////
// ������Roube  22-05-2012
// ���棺Roube
// ���ܣ�������Կ����
// ������Src:Դ Key:�ܳ�
//////////////////////////////////////////////////////////////////////
function UnKey(Source, Key: string): string;
var
  KeyLen: integer;
  KeyPos: integer;
  Offset: integer;
  Dest: string;
  SrcPos: integer;
  SrcAsc: integer;
  TmpSrcAsc: integer;
begin
  KeyLen := Length(Key);
  if KeyLen = 0 then
    Key := 'Roube';
  KeyPos := 0;
  Offset := strtoint('$' + copy(Source, 1, 2));
  SrcPos := 3;
  repeat
    SrcAsc := strtoint('$' + copy(Source, SrcPos, 2));
    if KeyPos < KeyLen then
      KeyPos := KeyPos + 1
    else
      KeyPos := 1;
    TmpSrcAsc := SrcAsc xor Ord(Key[KeyPos]);
    if TmpSrcAsc <= Offset then
      TmpSrcAsc := 255 + TmpSrcAsc - Offset
    else
      TmpSrcAsc := TmpSrcAsc - Offset;
    Dest := Dest + chr(TmpSrcAsc);
    Offset := SrcAsc;
    SrcPos := SrcPos + 2;
  until SrcPos >= Length(Source);
  Result := Dest;
end;
//////////////////////////////////////////////////////////////////////
// ������Roube  22-05-2012
// ���棺Roube
// ���ܣ�����������
// ������Ҫ���м��ܵ��ַ���
//////////////////////////////////////////////////////////////////////
function EnXor(str: string): string;
var
  i, j: Integer;
begin
  Result := '';
  j := 0;
  for i := 1 to Length(str) do
  begin
    Result := Result + IntToHex(Byte(str[i]) xor XorKey[j], 2);
    j := (j + 1) mod 8;
  end;
end;
//////////////////////////////////////////////////////////////////////
// ������Roube  22-05-2012
// ���棺Roube
// ���ܣ�����������
// ������Ҫ���н��ܵ��ַ���
//////////////////////////////////////////////////////////////////////
function UnXor(str: string): string;
var
  i, j: Integer;
begin
  Result := '';
  j := 0;
  for i := 1 to Length(str) div 2 do
  begin
    Result := Result + Char(StrToInt('$' + Copy(str, i * 2 - 1, 2)) xor XorKey[j]);
    j := (j + 1) mod 8;
  end;
end;

end.
