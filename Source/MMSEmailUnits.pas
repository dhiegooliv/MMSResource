unit MMSEmailUnits;

interface
uses
  SysUtils;
const
  CFailure = 'ʧ��';

  function IsConnected(const AURL: string): Boolean;//�����������״̬
  function CheckStrIsIP(const AValue: string) : Boolean;//���ip�Ƿ�Ϸ�
  function GetHostIP: string;//��ñ�����IP��ַ
  function GetSqlAddressFromEmail : string;//�������л�����ݿ�ĵ�ַ
  function SendSqlAddressToEmail : Boolean;//�ӱ���IP��ַ�ı������ʼ�������

implementation

uses
  IdPOP3, IdMessage, WinInet, Classes, IdSMTP, WinSock;

const
  CHost163 = 'http://www.163.com/';
  CPopHost = 'pop3.163.com';//�շ���������
  CSmtpHost = 'smtp.163.com';//�����ʼ�����������
  CUsername = 'mmslaeesqladdress@163.com';//��������
  CPassword = '!@#qwe123';//�����Ӧ������


{-----------------------------------------------------------------------------
  ����: bijy 2012-08-22
  ����: const AURL: string
  ����: Boolean
  ���ܣ������������״̬ 
-----------------------------------------------------------------------------}
function IsConnected(const AURL: string): Boolean;
begin
  try
    Result := InternetCheckConnection(Pchar(AURL), 1, 0);
  except
    Result := False;
  end;
end;

{-----------------------------------------------------------------------------
  ����: bijy 2012-08-22
  ����:
  ����: None
  ���ܣ���ñ�����IP��ַ
-----------------------------------------------------------------------------}
function GetHostIP: string;
var
  ch: array[1..32] of char;
  wsData: TWSAData;
  myHost: PHostEnt;
  i: integer;
begin
  Result := '';

  if not IsConnected(CHost163) then
  begin
    Result := '';
    Exit;
  end;

  if WSAstartup(2, wsData) <> 0 then Exit; // can��t start winsock
  try
    if GetHostName(@ch[1],32) <> 0 then Exit; // getHostName failed
  except
    Exit;
  end;
  myHost := GetHostByName(@ch[1]); // GetHostName error
  if myHost = nil then exit;
  for i := 1 to 4 do
  begin
    Result := Result + IntToStr(Ord(myHost.h_addr^[i - 1]));
    if i < 4 then
      Result := Result + '.';
  end;
end;

{-----------------------------------------------------------------------------
  ����: bijy 2012-08-22
  ����: 
  ����: None
  ���ܣ�����ַ��Ƿ�Ϊip��ַ
-----------------------------------------------------------------------------}
function CheckStrIsIP(const AValue: string) : Boolean;
var
  oList: TStringList;
  temp, I: Integer;
begin
  temp := -1;
  Result := False;
  oList := TStringList.Create;
  try
    oList.Delimiter := '.';
    oList.DelimitedText := Trim(AValue);
    for I := 0 to oList.Count- 1 do
    begin
      try
        temp := StrToInt(oList[i]);
      except
        Result := False;
        Break;
      end;
      Result := (temp >= 0) and (temp <= 255) and (oList.Count=4);
    end;
  finally
    oList.Free;
  end;
end;

{-----------------------------------------------------------------------------
  ����: bijy 2012-08-22
  ����: 
  ����: None
  ���ܣ������������л�õ�ַ
-----------------------------------------------------------------------------}
function GetSqlAddressFromEmail : string;
var
  oIdpop: TIdPOP3;
  oIdmessage: TIdMessage;
  mailcount: Integer;
begin
  Result := CFailure;
  if not IsConnected(CHost163) then Exit;
  
  oIdpop := TIdPOP3.Create(nil);
  oIdmessage := TIdMessage.Create(nil);
  try
    oIdpop.Host := CPopHost;
    oIdpop.Username := CUsername;
    oIdpop.Password := CPassword;
    while true do
    begin
      oIdpop.Connect();//���ӵ�POP3������
      if (oIdpop.Connected = true) then break;
    end;
    mailcount := oIdpop.CheckMessages;//�õ��������ʼ��ĸ���
    if mailcount = 0 then Exit;

    oIdmessage.Clear;
    oIdpop.retrieveHeader(mailcount, oIdmessage);  //�õ��ʼ���ͷ��Ϣ
    Result := oIdmessage.Subject;             //�õ��ʼ��ı���

    if not CheckStrIsIP(Result) then Exit;
  finally
    FreeAndNil(oIdmessage);
    FreeAndNil(oIdpop);
  end;
end;

{-----------------------------------------------------------------------------
  ����: bijy 2012-08-22
  ����: 
  ����: None
  ���ܣ��ӱ���IP��ַ�ı������ʼ�������
-----------------------------------------------------------------------------}
function SendSqlAddressToEmail : Boolean;
var
  oSmtp: TIdSMTP;
  oIdmessage: TIdMessage;
  sIP: string;
begin
  sIP := GetHostIP;
  if not CheckStrIsIP(sIP) then
  begin
    Result := False;
    Exit;
  end;  

  oSmtp := TIdSMTP.Create(nil);
  oIdmessage := TIdMessage.Create(nil);
  try
    try
      oSmtp.Host := CSmtpHost;//�����ʼ��ķ�������ַ
      oSmtp.Username := CUsername;//�����ʼ����û�
      oSmtp.Password := CPassword;//�����ʼ�������
      oSmtp.Port := 25;//�˿�
      oSmtp.Connect();//����
      oIdmessage.Recipients.EMailAddresses := CUsername;//�����ʼ��ĵ�ַ
      oIdmessage.From.Text := CUsername;//������
      oIdmessage.Subject := sIP;//�ʼ�����
      oSmtp.Authenticate;
      oSmtp.Send(oIdmessage); //�����ʼ�
      oSmtp.Disconnect;//�ر�����
      Result := True;
    except
      Result := False;
    end;
  finally
    FreeAndNil(oIdmessage);
    FreeAndNil(oSmtp);
  end;
end;

end.
