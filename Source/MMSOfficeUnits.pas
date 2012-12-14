unit MMSOfficeUnits;

interface
uses
  ComObj, ExtCtrls, Messages, SysUtils, Variants, Classes, Dialogs,
  Windows, Graphics, Controls, Forms, StdCtrls, Spin;
type
  ExcelArray = array of array of string;//�����ά����

  //����ʵ�ֲ��֣���Ҫ������ȡ��д��
  procedure ExcelWrite(Aarray : ExcelArray ; APath : string;
    const AStartRow : Integer = 1; const AStartCol : Integer = 1);
  function ExcelRead(APath : string;
    const AStartRow : Integer = 1; const AStartCol : Integer = 1) : ExcelArray;


implementation

//////////////////////////////////////////////////////////////////////
// ������Roube  13-05-2012
// ���棺Roube
// ���ܣ�ʵ�ֽ�����д��excel�ļ�
// ������д��Ķ�άstring���飬�Լ���ʼ���У����п�ʡ��
//////////////////////////////////////////////////////////////////////
procedure ExcelWrite(Aarray : ExcelArray ; APath : string;
    const AStartRow : Integer = 1; const AStartCol : Integer = 1);
var
  excelApp, WorkSheet: Variant; //����ΪOLE Automation ����
  lRow, lCol : Integer; //��������ѭ��д��
begin
    try
      //����OLE����Excel Application�� WorkBook
      excelApp := CreateOleObject('Excel.Application');
      WorkSheet := CreateOleobject('Excel.Sheet');
    except
      ShowMessage('���Ļ�����δ��װMicrosoft Excel��');
      Exit;
    end;
    try
      WorkSheet := excelApp.workBooks.Add;
      //ѭ��д�����д�1��ʼ
      for lRow := Low(Aarray) to High(Aarray) do
        for lCol := Low(Aarray[lRow]) to High(Aarray[lRow]) do
        begin
          excelApp.Cells[lRow + AStartRow, lCol + AStartCol].NumberFormatLocal:='@';//�����ı�Ϊ�ַ���
          excelApp.Cells[lRow + AStartRow, lCol + AStartCol] := Aarray[lRow][lCol];
        end;

      WorkSheet.SaveAs(APath);
      WorkSheet.Close;
      WorkSheet := excelApp.workBooks.Open(APath);
      WorkSheet.Save;

      WorkSheet.Close;
      excelApp.Quit;
      excelApp := Unassigned;
    except
      ShowMessage('������ȷ����Excel�ļ��������Ǹ��ļ��ѱ����������, ��ϵͳ����');
      WorkSheet.Close;
      excelApp.Quit;//�˳�Excel Application
      excelApp:=Unassigned;//�ͷ�VARIANT����
    end;
end;
//////////////////////////////////////////////////////////////////////
// ������Roube  13-05-2012
// ���棺Roube
// ���ܣ�ʵ�ֶ�ȡexcel�ļ������ض�ά����
// ������excel���ڵ�·�� d:\1.xls���Լ���ȡ��ʼ���У����п�ʡ�ԣ�ʡ���������1��ʼ
//////////////////////////////////////////////////////////////////////
function ExcelRead(APath : string;
  const AStartRow : Integer = 1; const AStartCol : Integer = 1) : ExcelArray;
var
  excelApp, WorkSheet: Variant; //����ΪOLE Automation ����
  lRow, lCol, lMaxRow, lMaxCol : Integer; //��������ѭ��д��
begin
  APath := trim(APath);
  try
    excelApp := CreateOLEObject('Excel.Application');
  except
    ShowMessage('���Ļ�����δ��װMicrosoft Excel��');
    Exit;
  end;
  try
    excelApp.Visible := false;
    excelApp.WorkBooks.Open(APath);
    //���Excel���С���
    lMaxRow :=excelApp.WorkSheets[1].UsedRange.Rows.Count;
    lMaxCol :=excelApp.WorkSheets[1].UsedRange.Columns.Count;

    SetLength(Result, lMaxRow + 1 - AStartRow);
    for lRow := Low(Result) to High(Result) do
    begin
      SetLength(Result[lRow], lMaxCol + 1 - AStartCol);
      for lCol := Low(Result[lRow]) to High(Result[lRow]) do
      begin
        Result[lRow][lCol] := trim(excelApp.WorkSheets[1].Cells[lRow + AStartRow,
          lCol + AStartCol].value)
      end;
    end;
    ExcelApp.WorkBooks.Close; //�رչ�����
    ExcelApp.Quit; //�˳� Excel
    ExcelApp:=Unassigned;//�ͷ�excel����
  except
    ShowMessage('������ȷ����Excel�ļ��������Ǹ��ļ��ѱ����������, ��ϵͳ����');
    WorkSheet.Close;
    excelApp.Quit;//�˳�Excel Application
    excelApp:=Unassigned;//�ͷ�VARIANT����
  end;
end;


end.
