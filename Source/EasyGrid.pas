// *****************************************************************************
//
// Note: This free package of source code can only be used for reference and
//       learning purpose, you can distribute it freely, but please do not use
//       it for profit sake.
//
//       Special thanks to: RICHBBS (www.delphibbs.com)
//
//                                                         Huang Qian, Feb 2002
//                                                         Wuhan University
//
// *****************************************************************************

unit EasyGrid;
{$R *.RES}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, Mask, Menus, Dialogs, ClipBrd, Printers,
  PreviewBox, CellProp, Preview, PageSetup;

const
  MaxCustomExtents = MaxListSize;
  MaxShortInt = High(ShortInt);
  CellFixedPartSize = 72;   // Cell �̶�����(�� string ���Ͳ���)��С
  ReservedSpace = 4096;
  crExcel = 1001;
  crZoomIn = 1002;
  crZoomOut = 1003;
  SegmentFlagValue = $FF;
  
resourcestring
  VersionInfo = 'Discovery EasyGrid Version 1.0' + #26;
  PrintJobName = 'EasyGrid �����ӡ����';
  PleaseInputCorrectData = '��������ȷ��ʽ�����ݡ�';
  NoPrinterInstalled = '����û�а�װ��ӡ����';
  NoMoreThan256Columns = '�����������ܳ���256��';
  InvalidNumber = '���ݲ��Ϸ�,��д����ȷ����ֵ��';
  InvalidDate = '���ݲ��Ϸ�,��д����ȷ�����ڡ�';
  InvalidTime = '���ݲ��Ϸ�,��д����ȷ��ʱ�䡣';
  CannotCutReadOnlyCells = '���ܶԺ���ֻ����Ԫ���������м��в�����';
  CannotPasteCells = '�޷�ճ����Ϣ,��������������ԭ��,��������ٴγ��ԡ�'+#13+#10+#13+#10+
                     '* Ŀ����������еĺϲ���Ԫ���ͻ��'+#13+#10+
                     '* Ŀ��������ֻ���ĵ�Ԫ��'+#13+#10+
                     '* Ŀ�����򳬹��˱������߽硣';
  CannotChangeMergedCells = '���ܶԺϲ���Ԫ�������ָĶ���';
  CannotOverlayReadOnlyCells = '���ܸ���Ŀ�������ڵ�ֻ����Ԫ��';
  MergedCellsMustBeSameSize = '�˲���Ҫ��ϲ���Ԫ�񶼾�����ͬ��С��';
  CannotRemoveRightMostCells = 'Ϊ�˷�ֹ���ݶ�ʧ,��������Ҳ�ķǿհ׵�Ԫ���ܱ���ȥ��'+#13+#10+#13+#10+
            '������÷ǿհ׵�Ԫ�������,�������Ƶ��µ�λ�ú��ٳ��ԡ�';
  CannotRemoveBottomMostCells = 'Ϊ�˷�ֹ���ݶ�ʧ,�������ײ��ķǿհ׵�Ԫ���ܱ���ȥ��'+#13+#10+#13+#10+
            '������÷ǿհ׵�Ԫ�������,�������Ƶ��µ�λ�ú��ٳ��ԡ�';
  DoYouWantDeleteMergedCells = '�˲������ᵼ��һЩ�ϲ���Ԫ�񱻲�ɢ,�Ƿ����?';
  DiscardMultipleCellValues = 'ѡ���������������ֵ���ϲ���һ����Ԫ���ֻ�ܱ��������Ͻǵ����ݡ�';
  DoYouWantReplace = '�Ƿ��滻Ŀ������ĵ�Ԫ������?';
  TitleTooBig = '����������,�����µ����������ٴγ��ԡ�';
  BadFileInfo = '�޷����ļ�, ���ļ������Ѿ��𻵡�';
  NotAEasyGridFile = '���ļ�����һ���Ϸ��ı����ļ���';

var
  CF_EASYGRID: Word;         // ������ע���ʽ

type
  EInvalidGridOperation = class(Exception);

  { Internal grid types }
  TGetExtentsFunc = function(Index: Longint): Integer of object;

  // EasyGrid �Ĳ���
  TEasyGridAxisDrawInfo = record
    EffectiveLineWidth: Integer; // ��(��)�߿�
    TitleBoundary: Integer;      // (����)�������߽�(���ص�λ)
    FixedBoundary: Integer;      // �̶�(����)�߽�(���ص�λ)
    GridBoundary: Integer;       // ������Ĳ��ֵ���(��)�߽�(���ص�λ)
    GridExtent: Integer;         // Grid �ͻ�����С(���ص�λ)
    LastFullVisibleCell: Longint;// ���һ����������Cell(Cell��λ)
    FullVisBoundary: Integer;    // ���һ����������Cell�߽�(���ص�λ)
    FixedCellCount: Integer;     // �̶���(��)����
    FirstGridCell: Integer;      // ��һ���ǹ̶�Cell��
    GridCellCount: Integer;      // һ��(��)Cell����
    GetExtent: TGetExtentsFunc;  // ��ĳ��(��)ĳ��ֵ(ͨ�ú���)
  end;

  // ˮƽ�봹ֱ����
  TEasyGridDrawInfo = record
    Horz, Vert: TEasyGridAxisDrawInfo;
  end;

  TCustomEasyGrid = class;

  // ���ݸ�ʽ
  TDataStyle = (dsText,dsNumber,dsDate,dsTime,dsFormula);

  PPointer = ^Pointer;

  // EasyGrid ��״̬
  TEasyGridState = (gsNormal, gsSelecting, gsRowSizing, gsColSizing,
    gsMoving, gsCopying, gsFilling);

  // EasyGrid �Ŀ�ѡ��
  TEasyGridOption = (goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
    goRangeSelect, goDrawFocusSelected, goRowSizing, goColSizing, goEditing,
    goTabs, goRowSelect, goAlwaysShowEditor, goThumbTracking);
  TEasyGridOptions = set of TEasyGridOption;
  TEasyGridDrawState = set of (gdSelected, gdFocused, gdFixed, gdTitled);
  TEasyGridScrollDirection = set of (sdLeft, sdRight, sdUp, sdDown);

  // Cell ������
  TPropertyName = (pnDataStyle, pnAlignMode, pnReadOnly,pnAutoWordBreak,
                   pnShowForeText, pnDrawTop, pnDrawLeft, pnDrawRight, pnDrawBottom,
                   pnAllowNegative, pnTrailingZero, pnZeroNull, pnThousandSep, pnMaxLength,
                   pnIntLength, pnDecLength, pnLineWidth, pnPenStyle, pnNumber, pnColor,
                   pnFontSize, pnFontColor, pnFontStyle, pnFontName,
                   pnForeText, pnBackText);

  // ��䷽ʽ
  TFillStyle = (fsNone, fsHorzFill, fsVertFill);

  // ���߷�ʽ
  TLineStyle = (lsSolid, lsDashed);

  // ���뷽ʽ
  TAlignMode = (taTopLeft, taTop, taTopRight,
                taLeft, taCenter, taRight,
                taBottomLeft, taBottom, taBottomRight);

  // �����˵��ı�ʶ
  TMenuItemTag = (mtCut, mtCopy, mtPaste,
                  mtInsertCellRight, mtInsertCellDown, mtInsertRow, mtInsertCol,
                  mtDeleteCellRight, mtDeleteCellDown, mtDeleteRow, mtDeleteCol,
                  mtClearCells, mtSetCellProp);

  TIntArray = array[0..MaxCustomExtents] of Integer;
  PIntArray = ^TIntArray;
  TCharArray = array of Char;
  PCharArray = ^TCharArray;
  TDynaIntArray = array of Integer;
  PDynaIntArray = ^TDynaIntArray;

  // �������ݽṹ
  TCellInfo = record
    // *************************************************************************
    DataStyle : TDataStyle;  // ���ݸ�ʽ
    AlignMode : TAlignMode;  // ���뷽ʽ
    Merge : TRect;           // �ϲ�������(Grid ����)

    ReadOnly : Boolean;      // ��Ԫ���Ƿ�ɱ༭
    AutoWordBreak : Boolean; // �����Զ�����
    ShowForeText : Boolean;  // ��ʾ����(Default True)
    DrawTop : Boolean;       // ������
    DrawLeft : Boolean;      // ������
    DrawBottom : Boolean;    // ������
    DrawRight : Boolean;     // ������

    AllowNegative : Boolean; // �Ƿ��������븺��
    TrailingZero : Boolean;  // �Ƿ���С�����油 0
    ZeroNull : Boolean;      // ������ֵ 0 ʱ�Ƿ����մ�����
    ThousandSep : Boolean;   // �Ƿ���ǧ�ֺ�
    MaxLength : Integer;     // ���༭����
    IntLength : Integer;     // ����������󳤶�
    DecLength : Integer;     // С��������󳤶�

    LineWidth : Integer;     // �߿�
    PenStyle : TPenStyle;    // ����
    Number : Integer;        // �洢��ֵ
    Color : TColor;          // ������ɫ

    FontSize: Integer;       // �����С
    FontColor: TColor;       // ������ɫ
    FontStyle: TFontStyles;  // ������
    // �������ݹ��� 72 ���ֽ�(���ǵ� Delphi �����ֽڶ��뷽ʽ)
    // *************************************************************************
    FontName : string;       // ��������
    ForeText : string;       // ǰ̨ Text
    BackText : string;       // ��̨ Text
  end;
  PCellInfo = ^TCellInfo;

  // �� TList �����һ�е�Ԫ����Ϣ
  TColCellInfoList = class(TList)
  public
    constructor Create(AGrid:TCustomEasyGrid;ACol,ARowCount:Integer);
    procedure Clear; override;
  end;

  // �� TList ��������е�Ԫ����Ϣ(��һ�� TList �����е��д�����)
  TCells = class(TList)
  private
    FGrid : TCustomEasyGrid;
  public
    constructor Create(AGrid:TCustomEasyGrid;AColCount,ARowCount:Integer);
    procedure Clear; override;
  end;

  TGridCoord = record
    X: Longint;
    Y: Longint;
  end;

  TGridRect = record
    case Integer of
      0: (Left, Top, Right, Bottom: Longint);
      1: (TopLeft, BottomRight: TGridCoord);
  end;
  PGridRect = ^TGridRect;

  // EasyGrid ҳ����Ϣ
  TEasyGridDetailPageInfo = record
    MonoColored: Boolean;                                  // ��ɫ/��ɫ��ӡ
    HorzCenter, VertCenter: Boolean;                       // ˮƽ����ֱ����
    HorzSplit: Boolean;                                    // ����/�����ҳ
    PrintGridLine: Boolean;                                // �Ƿ��ӡ������
    PrintColTitle, PrintRowTitle: Boolean;                 // �Ƿ��ӡ�к��б�
    PrintFixedCols, PrintFixedRows: Boolean;               // �Ƿ���ÿҳ��ӡ�̶�����
    PrintConjunction: Boolean;                             // �Ƿ��ӡ�нӴ�(��: ��ǰҳ������ҳ)
    TopConjunctionText, BottomConjunctionText: string[10]; // �нӴ�����
    Reserved: array [0..255] of Char;                      // �����ռ�     
  end;

  // �����ȫ����ӡ��Ϣ
  TEasyGridPageInfo = class(TObject)
  public
    DetailPageInfo: TEasyGridDetailPageInfo;
    CommonPageInfo: TCommonPageInfo;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromStream(AFileStream: TFileStream);
    procedure SaveToStream(AFileStream: TFileStream);
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
  end;

  TPageSectionDrawInfo = record
    StartPos: TPoint;
    Size: TSize;
    Range: TGridRect;
    Included: Boolean;
  end;
  TPageDrawInfo = record
    Index: Integer;
    SplitCoord: TPoint;
    Section: array[1..9] of TPageSectionDrawInfo;
    TopConjunction, BottomConjunction: TPageSectionDrawInfo;
  end;
  TPageDrawInfoList = array of TPageDrawInfo;
  PPageDrawInfoList = ^TPageDrawInfoList;

  TSelectCellEvent = procedure (Sender: TObject; ACol, ARow: Longint;
    var CanSelect: Boolean) of object;
  TDrawCellEvent = procedure (Sender: TObject; ACol, ARow: Longint;
    Rect: TRect; State: TEasyGridDrawState) of object;
  TGetEditEvent = procedure (Sender: TObject; ACol, ARow: Longint; var Value: string) of object;
  TSetEditEvent = procedure (Sender: TObject; ACol, ARow: Longint; const Value: string) of object;
  TSetCellTextEvent = procedure (Sender: TObject; ACol, ARow: Longint; var Value: string) of object;
  TBeforeSetCellPropEvent = procedure (Sender: TObject; Range: TRect; var CanSetCellProp: Boolean) of object;  
  TAfterSetCellPropEvent = procedure (Sender: TObject; Range: TRect) of object;
  TInsertColEvent = procedure (Sender: TObject; InsertRect: TRect) of object;
  TInsertRowEvent = procedure (Sender: TObject; InsertRect: TRect) of object;
  TDeleteColEvent = procedure (Sender: TObject; DeleteRect: TRect) of object;
  TDeleteRowEvent = procedure (Sender: TObject; DeleteRect: TRect) of object;
  TInsertCellRightEvent = procedure (Sender: TObject; InsertRect: TRect) of object;
  TInsertCellDownEvent  = procedure (Sender: TObject; InsertRect: TRect) of object;
  TDeleteCellRightEvent = procedure (Sender: TObject; DeleteRect: TRect) of object;
  TDeleteCellDownEvent  = procedure (Sender: TObject; DeleteRect: TRect) of object;
  TPasteCellsEvent = procedure (Sender: TObject; SrcTopLeft, SrcSize: TPoint; DestRect: TRect) of object;
  TCutCellsEvent = procedure (Sender: TObject; DestRect: TRect) of object;
  TCopyMoveCellsEvent = procedure (Sender: TObject; SrcRect, DestRect: TRect) of object;
  TFillCellsEvent = procedure (Sender: TObject; SrcRect, DestRect: TRect) of object;


  // TInplaceEdit �� EasyGrid ��Ƕ�ı༭��,���ڱ༭��Ԫ������
  TInplaceEdit = class(TCustomMaskEdit)
  private
    FGrid: TCustomEasyGrid;
    FCell: PCellInfo;
    FClickTime: Longint;
    FTempText: String;
    function CanAcceptKey(var S: string; var CharPos: Integer): Boolean;
    procedure InternalMove(const Loc: TRect; Redraw: Boolean);
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMPaste(var Message); message WM_PASTE;
    procedure WMCut(var Message); message WM_CUT;
    procedure WMClear(var Message); message WM_CLEAR;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function EditCanModify: Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure ValidateError; override;
    procedure BoundsChanged; virtual;
    procedure UpdateContents; virtual;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Deselect;
    procedure Hide;
    procedure Invalidate; reintroduce;
    procedure Move(const Loc: TRect);
    function PosEqual(const Rect: TRect): Boolean;
    procedure SetFocus; reintroduce;
    procedure UpdateLoc(const Loc: TRect);
    function Visible: Boolean;
    property ParentGrid: TCustomEasyGrid read FGrid write FGrid;
    property Grid: TCustomEasyGrid read FGrid;
    property Cell: PCellInfo read FCell write FCell;
  end;

  TCustomEasyGrid = class(TCustomControl)
  private
    FAnchor: TGridCoord;            // ����ͷ�����
    FSelStart, FSelEnd: TGridCoord; // ѡ��������ֹ����
    FBorderStyle: TBorderStyle;     // �߿���
    FCanEditModify: Boolean;
    FColCount: Longint;
    FColWidths: Pointer;
    FTabStops: Pointer;
    FColCanSizes: Pointer;
    FRowCanSizes: Pointer;
    FCurrent: TGridCoord;            // ��ǰ��������
    FDefaultColWidth: Integer;
    FDefaultRowHeight: Integer;
    FFixedCols: Integer;
    FFixedRows: Integer;
    FFixedLineColor: TColor;         // �̶���������ɫ
    FClientLineColor: TColor;        // ���������ɫ
    FGridLineWidth: Integer;
    FOptions: TEasyGridOptions;
    FRowCount: Longint;
    FRowHeights: Pointer;
    FScrollBars: TScrollStyle;
    FTopLeft: TGridCoord;             // ��ǰ���Ͻ���������
    FSizingIndex: Longint;            // �� Sizing ����(��)��
    FSizingPos, FSizingOfs: Integer;  // Sizingǰ���λ����ƫ����
    FHitTest: TPoint;                 // �����λ��
    FInplaceEdit: TInplaceEdit;
    FInplaceCol, FInplaceRow: Longint;// InplaceEditor ��������( -1 ����)
    FColOffset: Integer;              // ֻ��һ�����ʱ,������߱����ز��ֵĿ��
    FDefaultDrawing: Boolean;
    FEditorMode: Boolean;             // InplaceEditor �Ƿ�ɼ�

    //User Define
    FCells: TCells;                   // TList(TList1,TList2,...)
    FShowColTitle: Boolean;           // �Ƿ���ʾ���б���
    FShowRowTitle: Boolean;
    FTitleColor: TColor;              // ��������ɫ
    FHighLightColor: TColor;          // �����ȱ�����ɫ
    FHighLightTextColor: TColor;      // �������ı���ɫ
    FFocusedTitleColor: TColor;       // ��ǰ�������ı���ɫ

    FDataStyle : TDataStyle;
    FAlignMode : TAlignMode;
    FShowForeText : Boolean;
    FReadOnly : Boolean;
    FAutoWordBreak : Boolean;
    FCellLineWidth : Integer;
    FCellPenStyle : TPenStyle; 
    FAllowNegative : Boolean;
    FTrailingZero : Boolean;
    FZeroNull : Boolean;
    FThousandSep : Boolean;
    FMaxLength : Integer;
    FIntLength : Integer;
    FDecLength : Integer;
    FColor : TColor;

    FFontName  : string;
    FFontSize  : Integer;
    FFontColor : TColor;
    FFontStyle : TFontStyles;

    FEditUpdate: Integer;
    FAlwaysDrawFocus: Boolean;        // �Ƿ�������ʾ�ֽ����
    FClientSizeable: Boolean;         // ������ܷ� Size
    FCopyMoveRect: TGridRect;         // CopyMove �ķ�Χ
    FCopyMoveCell: TGridCoord;        // CopyMove ��ʼ Cell
    FCopyMoveOffset: TGridCoord;      // CopyMove ƫ����
    FFillStyle: TFillStyle;           // Fill �ķ�ʽ
    FFillRect: TGridRect;             // Fill �ķ�Χ
    FFillCell: TGridCoord;            // Fill ��ʼ Cell
    FFillOffset: TGridCoord;          // Fill ƫ����

    FGridCanCopyMove: Boolean;        // �����Ƿ�����϶�
    FGridCanFill: Boolean;            // �����Ƿ�������
    FShowPopup: Boolean;              // �Ƿ���ʾ�Ҽ��˵�
    FAutoUpdate: Boolean;             // �޸�����ʱ�Ƿ��Զ�����
    FCellPropPageIndex: Integer;      // �������ô��ڵ�ҳ��
    FPageSetupPageIndex: Integer;     // ҳ�����ô��ڵ�ҳ��
    FPreviewZoomIndex: Integer;       // Ԥ�����ڵ����ű������

    // *************************************************************************
    NewRgn, OldRgn: HRGN;             // ��������
    HaveClip: Integer;                // ���ñ�־
    MainBuffer: array of Char;        // ����������
    // *************************************************************************

    FOnDrawCell: TDrawCellEvent;
    FOnGetEditMask: TGetEditEvent;
    FOnGetEditText: TGetEditEvent;
    FOnSelectCell: TSelectCellEvent;
    FOnSetEditText: TSetEditEvent;
    FOnHideEdit: TSetEditEvent;
    FOnSetForeText: TSetCellTextEvent;
    FOnSetBackText: TSetCellTextEvent;
    FBeforeSetCellProp: TBeforeSetCellPropEvent;
    FAfterSetCellProp: TAfterSetCellPropEvent;
    FOnTopLeftChanged: TNotifyEvent;
    FOnInsertCol: TInsertColEvent;
    FOnInsertRow: TInsertRowEvent;
    FOnDeleteCol: TDeleteColEvent;
    FOnDeleteRow: TDeleteRowEvent;
    FOnInsertCellRight: TInsertCellRightEvent;
    FOnInsertCellDown: TInsertCellDownEvent;
    FOnDeleteCellRight: TDeleteCellRightEvent;
    FOnDeleteCellDown: TDeleteCellDownEvent;
    FOnPasteCells: TPasteCellsEvent;
    FOnCutCells: TCutCellsEvent;
    FOnCopyMoveCells: TCopyMoveCellsEvent;
    FOnFillCells: TFillCellsEvent;

    // ת����Ļ�������굽 Cell ����
    function CalcCoordFromPoint(X, Y: Integer;
      const DrawInfo: TEasyGridDrawInfo): TGridCoord;
    // ���� DrawInfo ���ݽṹ(���� CalcDrawInfoXY )
    procedure CalcDrawInfo(var DrawInfo: TEasyGridDrawInfo);
    // ���� DrawInfo ���ݽṹ
    procedure CalcDrawInfoXY(var DrawInfo: TEasyGridDrawInfo;
      UseWidth, UseHeight: Integer);
    // ����̶���(��)��Ϣ
    procedure CalcFixedInfo(var DrawInfo: TEasyGridDrawInfo);
    // ����ҳ��滭��Ϣ
    procedure CalcPageDrawInfo(var APageDrawInfoList: TPageDrawInfoList);
    // �����Ӧĳһ Cell ���� TopLeft ֵ(Fixed ����)
    function CalcMaxTopLeft(const Coord: TGridCoord;
      const DrawInfo: TEasyGridDrawInfo): TGridCoord;
    // �����µ�ѡ��Χ
    function CalcMaxRange(StartCell, EnteredCell: TGridCoord) : TGridRect;
    // �ָ� Grid ģʽ�� gsNormal
    procedure CancelMode;
    // �ж��ܷ� Sizing ��
    function CanDrawSizingLine(AAxisDrawInfo:TEasyGridAxisDrawInfo;
             SizingPos: Integer; State: TEasyGridState): Boolean;
    // �޸� Grid ���и���
    procedure ChangeSize(NewColCount, NewRowCount: Longint);
    // �ѵ�ǰѡ�е� Cell ��ȫ�����ӿ���
    procedure ClampInView(const Coord: TGridCoord; IsMouseMove: Boolean);
    // �� Sizing ����
    procedure DrawSizingLine(const DrawInfo: TEasyGridDrawInfo);
    // �� CopyMove ���
    procedure DrawCopyMoveRect(const DrawInfo: TEasyGridDrawInfo);
    // �� Fill ���
    procedure DrawFillRect(const DrawInfo: TEasyGridDrawInfo);
    // ʹĳ�� Cell ��Ϊ��ǰ Cell
    procedure FocusCell(ACol, ARow: Longint; MoveAnchor: Boolean);
    // ת�� Grid ���굽 Screen ����
    procedure GridRectToScreenRect(GridRect: TGridRect;
      var ScreenRect: TRect; IncludeLine: Boolean);
    // ���� InplaceEditor ��ֵ������֮
    procedure HideEdit;
    // �޸� TopLeft ֵ�����¹�����λ��
    procedure ModifyScrollBar(ScrollBar, ScrollCode, Pos: Cardinal;
      UseRightToLeft: Boolean);
    // �ƶ� Anchor
    procedure MoveAnchor(const NewAnchor: TGridCoord; MoveSel: Boolean = True);
    // ����ǰ Cell �����ƶ����µ�λ��
    procedure MoveCurrent(ACol, ARow: Longint; MoveAnchor, Show, TopLeftChange: Boolean);
    // �����µ� TopLeft
    procedure MoveTopLeft(ALeft, ATop: Longint);
    // ����ˢ�µ� Index ���ұߵ���������(�п�ı�ʱ������)
    procedure ResizeCol(Index: Longint; OldSize, NewSize: Integer);
    // ����ˢ�µ� Index ���������������(�и߸ı�ʱ������)
    procedure ResizeRow(Index: Longint; OldSize, NewSize: Integer);
    // ѡ�������ƶ���(�϶��߿�),�ػ���ص�����
    procedure SelectionMoved(OldSel: TGridRect);
    // ƽ����������
    procedure ScrollDataInfo(DX, DY: Integer; var DrawInfo: TEasyGridDrawInfo);
    // �� TopLeft �ı��Դ������ƽ������,��Ҫʱˢ�������ͻ���
    procedure TopLeftMoved(const OldTopLeft: TGridCoord);
    // �޸Ĺ�����λ��
    procedure UpdateScrollPos;
    // �޸Ĺ�������Χ
    procedure UpdateScrollRange;
    // �жϹ������Ƿ�ɼ�
    function ScrollBarVisible(Code: Word): Boolean;
    // ȡ���п�( Index �� 1 ��ʼ)
    function GetColWidths(Index: Longint): Integer;
    // ȡ���и�( Index �� 1 ��ʼ)
    function GetRowHeights(Index: Longint): Integer;
    // ȡ��ѡ������(Grid ����)
    function GetSelection: TGridRect;
    // ȡ�� ColCanSizes ( Index �� 1 ��ʼ)
    function GetColCanSizes(Index: Longint): Boolean;
    // ȡ�� RowCanSizes ( Index �� 1 ��ʼ)
    function GetRowCanSizes(Index: Longint): Boolean;
    // ȡ�� TabStop ( Index �� 1 ��ʼ)
    function GetTabStops(Index: Longint): Boolean;
    // ȡ�ÿ�������ʾ�ķǹ̶����� ( Index �� 1 ��ʼ)
    function GetVisibleColCount: Integer;
    // ȡ�ÿ�������ʾ�ķǹ̶����� ( Index �� 1 ��ʼ)
    function GetVisibleRowCount: Integer;
    // �ж� Grid �Ƿ�Ϊ��ǰ�Ļ�ؼ�(ӵ�н���)
    function IsActiveControl: Boolean;
    procedure ReadColWidths(Reader: TReader);
    procedure ReadRowHeights(Reader: TReader);
    // ���� BorderStyle �����´����ؼ�����
    procedure SetBorderStyle(Value: TBorderStyle);
    // ���õ�ǰ Cell ������,���� Click �¼�
    procedure SetCol(Value: Longint);
    // ��������
    procedure SetColCount(Value: Longint);
    // �����п�ˢ�� Index ���ұߵĴ��ڲ���
    procedure SetColWidths(Index: Longint; Value: Integer);
    // ����ȱʡ�п�ˢ����������
    procedure SetDefaultColWidth(Value: Integer);
    // ����ȱʡ�и߲�ˢ����������
    procedure SetDefaultRowHeight(Value: Integer);
    // ����/��ʾ InplaceEditor
    procedure SetEditorMode(Value: Boolean);
    // ���ù̶���(��)��ɫ��ˢ�´���
    procedure SetFixedLineColor(Value: TColor);
    // ���ù̶���(��)��ɫ��ˢ�´���
    procedure SetClientLineColor(Value: TColor);
    // ���ñ�������ɫ��ˢ�´���
    procedure SetTitleColor(Value: TColor);
    // ���ø����ȱ�����ɫ��ˢ�´���
    procedure SetHighLightColor(Value: TColor);
    // ���ø������ı���ɫ��ˢ�´���
    procedure SetHighLightTextColor(Value: TColor);
    // ���ý�������ı���ɫ��ˢ�´���
    procedure SetFocusedTitleColor(Value: TColor);
    // ���ù̶��и�����ˢ�´���
    procedure SetFixedCols(Value: Integer);
    // ���ù̶��и�����ˢ�´���
    procedure SetFixedRows(Value: Integer);
    // �����߿�ˢ�´���
    procedure SetGridLineWidth(Value: Integer);
    // ���õ�ǰ���Ͻ�����������
    procedure SetLeftCol(Value: Longint);
    // ���� GridOptions
    procedure SetOptions(Value: TEasyGridOptions);
    // ���õ�ǰ Cell ������,���� Click �¼�
    procedure SetRow(Value: Longint);
    // ��������
    procedure SetRowCount(Value: Longint);
    // �����и߲�ˢ�� Index ������Ĵ��ڲ���
    procedure SetRowHeights(Index: Longint; Value: Integer);
    // ���� Grid ����������
    procedure SetScrollBars(Value: TScrollStyle);
    // ����ѡ������
    procedure SetSelection(Value: TGridRect);
    // ���� ColCanSizes ����
    procedure SetColCanSizes(Index: Longint; Value: Boolean);
    // ���� RowCanSizes ����
    procedure SetRowCanSizes(Index: Longint; Value: Boolean);
    // ���� TabStops ����
    procedure SetTabStops(Index: Longint; Value: Boolean);
    // ���õ�ǰ���Ͻ�����������
    procedure SetTopRow(Value: Longint);
    // �����Ƿ���ʾ��ǰ����� Editor
    procedure UpdateEdit;
    // ���� SetEditText �� Cell �ش� Editor ������
    procedure UpdateText;
    procedure InitializeGrid;
    procedure DisableEditUpdate;
    procedure EnableEditUpdate;

    procedure WriteColWidths(Writer: TWriter);
    procedure WriteRowHeights(Writer: TWriter);

    procedure CMCancelMode(var Msg: TMessage); message CM_CANCELMODE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure CMDesignHitTest(var Msg: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMWantSpecialKey(var Msg: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure CMShowingChanged(var Message: TMessage); message CM_SHOWINGCHANGED;
    procedure WMChar(var Msg: TWMChar); message WM_CHAR;
    procedure WMCancelMode(var Msg: TWMCancelMode); message WM_CANCELMODE;
    procedure WMCommand(var Message: TWMCommand); message WM_COMMAND;
    procedure WMEraseBkGnd(var Message: TWMCommand); message WM_ERASEBKGND;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMKillFocus(var Msg: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMLButtonDown(var Message: TMessage); message WM_LBUTTONDOWN;
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMSetCursor(var Msg: TWMSetCursor); message WM_SETCURSOR;
    procedure WMSetFocus(var Msg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMTimer(var Msg: TWMTimer); message WM_TIMER;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;

    function MouseCoord(X, Y: Integer): TGridCoord;
    procedure SetAutoUpdate(Value: Boolean);
    procedure DrawLine(ACanvas: TCanvas; X1, Y1, X2, Y2: Integer);
    function  GetColors(ACol, ARow: Integer): TColor;
    procedure SetColors(ACol, ARow: Integer; Value: TColor);
    function  GetMerges(ACol, ARow: Integer): PGridRect;
    procedure SetColTitle(Value: Boolean);
    procedure SetRowTitle(Value: Boolean);
    function  GetAlignMode(ACol, ARow: Integer): TAlignMode;
    procedure SetAlignMode(ACol, ARow: Integer; AlignMode: TAlignMode);
    function  GetForeText(ACol, ARow: Integer): string;
    procedure SetForeText(ACol, ARow: Integer; Value: string);
    function  GetBackText(ACol, ARow: Integer): string;
    procedure SetBackText(ACol, ARow: Integer; Value: string);
    procedure SetCellDataStyle(Value: TDataStyle);
    procedure SetCellAlignMode(Value: TAlignMode);
    procedure SetCellShowForeText(Value: Boolean);
    procedure SetCellReadOnly(Value: Boolean);
    procedure SetCellAutoWordBreak(Value: Boolean);
    procedure SetCellLineWidth(Value: Integer);
    procedure SetCellPenStyle(Value: TPenStyle);
    procedure SetCellAllowNegative(Value: Boolean);
    procedure SetCellTrailingZero(Value: Boolean);
    procedure SetCellZeroNull(Value: Boolean);
    procedure SetCellThousandSep(Value: Boolean);
    procedure SetCellMaxLength(Value: Integer);
    procedure SetCellIntLength(Value: Integer);
    procedure SetCellDecLength(Value: Integer);
    procedure SetCellColor(Value: TColor);
    procedure SetCellFontSize(Value: Integer);
    procedure SetCellFontColor(Value: TColor);
    procedure SetCellFontStyle(Value: TFontStyles);

    function  RegularRange(ASel: TGridRect) : Boolean;
    // �ж�һ����Χ���Ƿ�����кϲ�����
    function HaveMerge(ARect: PGridRect): Boolean;
    // �ж�һ�� Cell �Ƿ��ںϲ�������
    function CellInMerge(ACol, ARow: Integer): Boolean;
    // �ж�Ŀ�������Ƿ������кϲ������ͻ
    function MergeRectIntersects(DestRect: TGridRect): Boolean;
    // �ж�Ŀ�������Ƿ���ֻ����Ԫ��
    function RectReadOnly(DestRect: TGridRect): Boolean;
    // �ж��ܷ� CopyMove ��Ŀ������
    function CanCopyMove: Boolean;
    // �ж��ܷ� Fill Ŀ������
    function CanFill(SrcRect: TRect; Offset: Integer; FillStyle: TFillStyle): Boolean;
    // �ж��ܷ� Paste ��Ŀ������
    function CanPaste(DestRect: TGridRect): Boolean;
    // ������չ״̬( Copying, Filling, Moving )
    procedure CalcExtendedState(X, Y: Integer; var State: TEasyGridState;
          DrawInfo: TEasyGridDrawInfo);
    // ���� ColSizing, RowSizing ״̬
    procedure CalcSizingState(X, Y: Integer; var State: TEasyGridState;
      var Index: Longint; var SizingPos, SizingOfs: Integer;
      var DrawInfo: TEasyGridDrawInfo); virtual;
    // ���� Cell ����ʵ��ռ�õĿռ�(���������ʽ)
    function CalcCellSize(ACell: PCellInfo): Integer;
    // �õ������������ݵ���ʼ��������
    procedure GetClipBoardInfo(var StartCoord, Size: TGridCoord);
    // �ӻ�������(�ַ���)����һ�� Cell ����(���������ʽ)
    procedure ReadCellFromBuffer(SrcBuffer: PCharArray; DestCell: PCellInfo);
    // ��һ�� Cell ����д����������(�ַ���)(���������ʽ)
    procedure WriteCellToBuffer(SrcCell: PCellInfo; DestBuffer: PCharArray);
    // ����һ����Χ�ڵ� Cells ���ݵ���������(���������ʽ)
    procedure CopyCellsToBuffer(Range: TGridRect);
    // �ӻ�������ճ�� Cells ����
    procedure PasteCellsFromBuffer(DestRect: TGridRect);
    // ��������建����
    procedure ClearClipBoardBuffer;
    // ��һ�� Cell �ָ���ȱʡ״̬
    procedure InitCell(AGrid:TCustomEasyGrid;ACell:PCellInfo;ACol,ARow:Integer);
    procedure InitPopupMenu;
    procedure MenuItemClick(Sender: TObject);
    procedure SetClipRect(ACanvas: TCanvas; ClipR: TRect);
    procedure RestoreClipRect(ACanvas: TCanvas);
    procedure ColCountChange(Value: Integer);
    procedure RowCountChange(Value: Integer);
    function FindNextVisibleCell(Start: Integer; AAxisDrawInfo: TEasyGridAxisDrawInfo): Integer;
    function FindLastVisibleCell(Start: Integer; AAxisDrawInfo: TEasyGridAxisDrawInfo): Integer;
  protected
    FGridState: TEasyGridState; // Grid ��ǰ������״̬
    FSaveCellExtents: Boolean;
    DesignOptionsBoost: TEasyGridOptions;
    VirtualView: Boolean;

    function CreateEditor: TInplaceEdit; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    // ȡ��������Ϣ(��ַ)
    function GetCell(ACol, ARow: Integer): PCellInfo;
    // ������̰���
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    // ��������ɿ�
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    // ����س�����ʾ������ InplaceEditor
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    // û�д�������Ҽ�
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure AdjustSize(Index, Amount: Longint; Rows: Boolean); reintroduce; dynamic;
    function BoxRect(ALeft, ATop, ARight, ABottom: Longint): TRect;
    procedure DoExit; override;
    function CanEditAcceptKey(Key: Char): Boolean; dynamic;
    function CanGridAcceptKey(Key: Word; Shift: TShiftState): Boolean; dynamic;
    function CanEditModify: Boolean; dynamic;
    function CanEditShow: Boolean; virtual;
    function DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function GetEditText(ACol, ARow: Longint): string; dynamic;
    // �� InplaceEditor �����ݻش��� Cell
    procedure SetEditText(ACol, ARow: Longint; Value: string); dynamic;
    function GetEditMask(ACol, ARow: Longint): string; dynamic;
    function GetEditLimit: Integer; dynamic;
    function GetGridWidth: Integer;
    function GetGridHeight: Integer;
    procedure HideEditor;
    procedure ShowEditor;
    // ��ʾ InplaceEditor ���� Char ���͸� InplaceEditor
    procedure ShowEditorChar(Ch: Char);
    procedure InvalidateEditor;
    // �� Cell ������߿�(����б߿�)
    procedure DrawCell(ACol, ARow: Longint; TextRect, ClipR: TRect;
      AState: TEasyGridDrawState); virtual;
    procedure DefineProperties(Filer: TFiler); override;
    procedure MoveColRow(ACol, ARow: Longint; MoveAnchor, Show: Boolean);
    function SelectCell(ACol, ARow: Longint): Boolean; virtual;
    procedure SizeChanged(OldColCount, OldRowCount: Longint); dynamic;
    // ���ݵ�ǰ���λ���ж��ܷ��� Sizing ״̬
    function Sizing(X, Y: Integer): Boolean;
    procedure ScrollData(DX, DY: Integer);
    procedure TopLeftChanged; dynamic;
    procedure TimedScroll(Direction: TEasyGridScrollDirection); dynamic;
    procedure Paint; override;
    procedure ColWidthsChanged; dynamic;
    procedure RowHeightsChanged; dynamic;
    procedure UpdateDesigner;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle;
    property Col: Longint read FCurrent.X write SetCol;
    property Color default clWindow;
    property ColCount: Longint read FColCount write SetColCount default 5;
    property ColWidths[Index: Longint]: Integer read GetColWidths write SetColWidths;
    property DefaultColWidth: Integer read FDefaultColWidth write SetDefaultColWidth default 80;
    property DefaultDrawing: Boolean read FDefaultDrawing write FDefaultDrawing default True;
    property DefaultRowHeight: Integer read FDefaultRowHeight write SetDefaultRowHeight default 30;
    property EditorMode: Boolean read FEditorMode write SetEditorMode;
    property FixedLineColor: TColor read FFixedLineColor write SetFixedLineColor default clBlack;
    property ClientLineColor: TColor read FClientLineColor write SetClientLineColor default clSilver;
    property FixedCols: Integer read FFixedCols write SetFixedCols default 0;
    property FixedRows: Integer read FFixedRows write SetFixedRows default 0;
    property GridHeight: Integer read GetGridHeight;
    property GridLineWidth: Integer read FGridLineWidth write SetGridLineWidth default 1;
    property GridWidth: Integer read GetGridWidth;
    property HitTest: TPoint read FHitTest;
    property InplaceEditor: TInplaceEdit read FInplaceEdit;
    property LeftCol: Longint read FTopLeft.X write SetLeftCol;
    property Options: TEasyGridOptions read FOptions write SetOptions
      default [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
      goRangeSelect];
    property ParentColor default False;
    property Row: Longint read FCurrent.Y write SetRow;
    property RowCount: Longint read FRowCount write SetRowCount default 5;
    property RowHeights[Index: Longint]: Integer read GetRowHeights write SetRowHeights;
    property ScrollBars: TScrollStyle read FScrollBars write SetScrollBars default ssBoth;
    property Selection: TGridRect read GetSelection write SetSelection;
    property ColCanSizes[Index: Longint]: Boolean read GetColCanSizes write SetColCanSizes;
    property RowCanSizes[Index: Longint]: Boolean read GetRowCanSizes write SetRowCanSizes;
    property TabStops[Index: Longint]: Boolean read GetTabStops write SetTabStops;
    property TopRow: Longint read FTopLeft.Y write SetTopRow;
    property VisibleColCount: Integer read GetVisibleColCount;
    property VisibleRowCount: Integer read GetVisibleRowCount;
    property TabStop default True;

    property GridCanCopyMove: Boolean read FGridCanCopyMove write FGridCanCopyMove default True;
    property GridCanFill: Boolean read FGridCanFill write FGridCanFill default True;
    property ShowPopup: Boolean read FShowPopup write FShowPopup default True;
    property AutoUpdate: Boolean read FAutoUpdate write SetAutoUpdate default True;
    property AlwaysDrawFocus: Boolean read FAlwaysDrawFocus write FAlwaysDrawFocus default False;
    property ClientSizeable: Boolean read FClientSizeable write FClientSizeable default False;
    property ShowColTitle: Boolean read FShowColTitle write SetColTitle default True;
    property ShowRowTitle: Boolean read FShowRowTitle write SetRowTitle default True;
    property TitleColor: TColor read FTitleColor write SetTitleColor default clBtnFace;
    property HighLightColor: TColor read FHighLightColor write SetHighLightColor default clBlack;
    property HighLightTextColor: TColor read FHighLightTextColor write SetHighLightTextColor default clWhite;
    property FocusedTitleColor: TColor read FFocusedTitleColor write SetFocusedTitleColor default clBlack;

    property Aligns[ACol, ARow: Integer]: TAlignMode read GetAlignMode write SetAlignMode;
    property ForeTexts[ACol, ARow: Integer]: string read GetForeText write SetForeText;
    property BackTexts[ACol, ARow: Integer]: string read GetBackText write SetBackText;
    property Colors[ACol, ARow: Integer]: TColor read GetColors write SetColors;
    property Merges[ACol, ARow: Integer]: PGridRect read GetMerges;
    property Cells[ACol,ARow:Integer]:PCellInfo read GetCell;

    property CellDataStyle: TDataStyle read FDataStyle write SetCellDataStyle default dsText;
    property CellAlignMode: TAlignMode read FAlignMode write SetCellAlignMode default taTopLeft;
    property CellShowForeText: Boolean read FShowForeText write SetCellShowForeText default True;
    property CellReadOnly: Boolean read FReadOnly write SetCellReadOnly default False;
    property CellAutoWordBreak: Boolean read FAutoWordBreak write SetCellAutoWordBreak default True;
    property CellLineWidth: Integer read FCellLineWidth write SetCellLineWidth default 1;
    property CellPenStyle: TPenStyle read FCellPenStyle write SetCellPenStyle default psSolid;
    property CellAllowNegative: Boolean read FAllowNegative write SetCellAllowNegative default True;
    property CellTrailingZero: Boolean read FTrailingZero write SetCellTrailingZero default False;
    property CellZeroNull: Boolean read FZeroNull write SetCellZeroNull default True;
    property CellThousandSep: Boolean read FThousandSep write SetCellThousandSep default True;
    property CellMaxLength: Integer read FMaxLength write SetCellMaxLength default 255;
    property CellIntLength: Integer read FIntLength write SetCellIntLength default 3;
    property CellDecLength: Integer read FDecLength write SetCellDecLength default 2;
    property CellColor: TColor read FColor write SetCellColor default clWhite;
    property CellFontSize: Integer read FFontSize write SetCellFontSize default 9;
    property CellFontColor: TColor read FFontColor write SetCellFontColor default clBlack;
    property CellFontStyle: TFontStyles read FFontStyle write SetCellFontStyle default [];

  public
    EasyGridPopup: TPopupMenu;           // ����ʽ�˵�
    EasyGridPageInfo: TEasyGridPageInfo; // ҳ��������Ϣ
    PageDrawInfoList: TPageDrawInfoList; // ҳ���ӡ�滭��Ϣ
    FormCellProp: TFormCellProp;         // ��Ԫ���������ô���ָ��
    FormPreview: TFormPreview;           // ��ӡԤ������ָ��
    FormPageSetup: TFormPageSetup;       // ��ӡҳ�����ô���ָ��

    // ���캯��
    constructor Create(AOwner: TComponent); override;
    // ��������
    destructor Destroy; override;
    // �����������������(����� Grid �����Ͻ�)
    function CellRect(ACol, ARow: Longint): TRect;
    // �������������Ӧ�����������
    procedure MouseToCell(X, Y: Integer; var ACol, ARow: Longint);
    // ǿ�Ƹ��� ARect ����(Grid ����)
    procedure InvalidateRect(ARect: TGridRect);
    // �������� Grid
    procedure InvalidateGrid;
    // ˢ��һ�� Cell ( Grid ���굥λ)
    procedure InvalidateCell(ACol, ARow: Longint);
    // ˢ��һ�� ( Grid ���굥λ)
    procedure InvalidateCol(ACol: Longint);
    // ˢ��һ�� ( Grid ���굥λ)
    procedure InvalidateRow(ARow: Longint);
    // �ϲ�����
    procedure SetMerges(AMergeRect: TRect; WantPrompt: Boolean = False);
    // �������
    procedure DeleteMerges(AMergeRect: TRect);
    // ��һ����Χ�ڵ� Cells �ָ���ȱʡ״̬
    procedure RestoreCells(DestRestoreRect: TRect);
    // ���һ����Χ�ڵ� Cells ���ı�
    procedure ClearCells(DestClearRect: TRect);
    // ����һ����Χ�ڵ� Cells ���ݵ���������
    procedure CopyCells(DestCopyRect: TRect);
    // ����һ����Χ�ڵ� Cells ���ݵ��������в���� Cells ����
    procedure CutCells(DestCutRect: TRect);
    // �����������
    procedure FillCells(SrcRect: TRect; Offset: Integer; FillStyle: TFillStyle);
    // �Ӽ�������ճ�� Cells ���ݵ�һ����Χ��
    procedure PasteCells(DestPasteCoord: TPoint);
    // ����ĳһ�е� Cell ����ֵ
    procedure SetColProperty(ColIndex: Integer; PropertyName: TPropertyName; Value: Pointer);
    // ����ĳһ�е� Cell ����ֵ
    procedure SetRowProperty(RowIndex: Integer; PropertyName: TPropertyName; Value: Pointer);
    // ����ĳ����Χ�ڵ� Cell ����ֵ
    procedure SetRangeProperty(Range: TRect; PropertyName: TPropertyName; Value: Pointer);
    // �������� Grid �� Cell ����ֵ
    procedure SetGridProperty(PropertyName: TPropertyName; Value: Pointer);
    // ��ռ���������
    procedure ClearClipBoard;
    // �򿪼�����
    procedure OpenClipBoard;
    // �رռ�����
    procedure CloseClipBoard;
    // �жϼ������Ƿ����
    function ClipBoardAvailable: Boolean;
    // ���Ҳ���һ������
    procedure InsertCellRight(InsertRect: TRect);
    // ���²���һ������
    procedure InsertCellDown(InsertRect: TRect);
    // ����һ��
    procedure InsertRow(InsertRect: TRect);
    // ����һ��
    procedure InsertCol(InsertRect: TRect);
    // ����ɾ��һ������
    procedure DeleteCellRight(DeleteRect: TRect);
    // ����ɾ��һ������
    procedure DeleteCellDown(DeleteRect: TRect);
    // ɾ��һ��
    procedure DeleteRow(DeleteRect: TRect);
    // ɾ��һ��
    procedure DeleteCol(DeleteRect: TRect);
    // ��ʾ���õ�Ԫ�����Դ���
    procedure SetCellProp(DefaultPage: Integer = -1);
    // �� Grid ���浽�ļ���
    procedure SaveToFile(FileName: string);
    // �� Grid ���浽�ļ�����
    procedure SaveToStream(FileStream: TFileStream);
    // ���ļ��ж��� Grid ����
    procedure LoadFromFile(FileName: string);
    // ���ļ����ж��� Grid ����
    procedure LoadFromStream(FileStream: TFileStream);
    // ��ӡ Grid
    procedure Print;
    // ��ӡ Grid ҳ
    procedure PrintPage(DrawCanvas: TCanvas; DrawRect: TRect; PageIndex: Integer;
                        Printing: Boolean);
    // ��ʾ��ӡ�Ի���
    procedure PrintDialog;
    // ��ʾ��ӡԤ������
    procedure Preview;
    // ��ʾ��ӡ�����öԻ���
    function PrinterSetup: Boolean;
    // ��ʾҳ�����öԻ���
    procedure PageSetup;
  end;

  TEasyGrid = class(TCustomEasyGrid)
  public
    property Canvas;
    property Col;
    property ColWidths;
    property Aligns;
    property ForeTexts;
    property BackTexts;
    property Colors;
    property Merges;
    property Cells;
    property EditorMode;
    property GridHeight;
    property GridWidth;
    property LeftCol;
    property Selection;
    property Row;
    property RowHeights;
    property ColCanSizes;
    property RowCanSizes;
    property TabStops;
    property TopRow;
    { Public declarations }
  published
    property Align;
    property AlwaysDrawFocus;
    property Anchors;
    property AutoUpdate;
    property BiDiMode;
    property BorderStyle;
    property ClientSizeable;
    property CellDataStyle;
    property CellAlignMode;
    property CellShowForeText;
    property CellReadOnly;
    property CellAutoWordBreak;
    property CellLineWidth;
    property CellPenStyle;
    property CellAllowNegative;
    property CellTrailingZero;
    property CellZeroNull;
    property CellThousandSep;
    property CellMaxLength;
    property CellIntLength;
    property CellDecLength;
    property CellColor;
    property CellFontSize;
    property CellFontColor;
    property CellFontStyle;
    property Color;
    property ColCount;
    property Constraints;
    property Ctl3D;
    property DefaultColWidth;
    property DefaultRowHeight;
    property DefaultDrawing;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property FixedLineColor;
    property ClientLineColor;
    property FixedCols;
    property RowCount;
    property FixedRows;
    property Font;
    property GridLineWidth;
    property Options;
    property ParentBiDiMode;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property GridCanCopyMove;
    property GridCanFill;
    property ScrollBars;
    property ShowHint;
    property ShowPopup;
    property TabOrder;
    property TabStop;
    property Visible;
    property VisibleColCount;
    property VisibleRowCount;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDrawCell: TDrawCellEvent read FOnDrawCell write FOnDrawCell;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetEditMask: TGetEditEvent read FOnGetEditMask write FOnGetEditMask;
    property OnGetEditText: TGetEditEvent read FOnGetEditText write FOnGetEditText;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnSelectCell: TSelectCellEvent read FOnSelectCell write FOnSelectCell;
    property OnSetEditText: TSetEditEvent read FOnSetEditText write FOnSetEditText;
    property OnHideEdit: TSetEditEvent read FOnHideEdit write FOnHideEdit;
    property OnSetForeText: TSetCellTextEvent read FOnSetForeText write FOnSetForeText;
    property OnSetBackText: TSetCellTextEvent read FOnSetBackText write FOnSetBackText;
    property BeforeSetCellProp: TBeforeSetCellPropEvent read FBeforeSetCellProp write FBeforeSetCellProp;
    property AfterSetCellProp: TAfterSetCellPropEvent read FAfterSetCellProp write FAfterSetCellProp;
    property OnStartDock;
    property OnStartDrag;
    property OnTopLeftChanged: TNotifyEvent read FOnTopLeftChanged write FOnTopLeftChanged;
    property OnInsertCol: TInsertColEvent read FOnInsertCol write FOnInsertCol;
    property OnInsertRow: TInsertRowEvent read FOnInsertRow write FOnInsertRow;
    property OnDeleteCol: TDeleteColEvent read FOnDeleteCol write FOnDeleteCol;
    property OnDeleteRow: TDeleteRowEvent read FOnDeleteRow write FOnDeleteRow;
    property OnInsertCellRight: TInsertCellRightEvent read FOnInsertCellRight write FOnInsertCellRight;
    property OnInsertCellDown: TInsertCellDownEvent read FOnInsertCellDown write FOnInsertCellDown;
    property OnDeleteCellRight: TDeleteCellRightEvent read FOnDeleteCellRight write FOnDeleteCellRight;
    property OnDeleteCellDown: TDeleteCellDownEvent read FOnDeleteCellDown write FOnDeleteCellDown;
    property OnPasteCells: TPasteCellsEvent read FOnPasteCells write FOnPasteCells;
    property OnCutCells: TCutCellsEvent read FOnCutCells write FOnCutCells;
    property OnCopyMoveCells: TCopyMoveCellsEvent read FOnCopyMoveCells write FOnCopyMoveCells;
    property OnFillCells: TFillCellsEvent read FOnFillCells write FOnFillCells;

    //User Define
    property HighLightColor;
    property TitleColor;
    property ShowColTitle;
    property ShowRowTitle;
    property FocusedTitleColor;
    property HighLightTextColor;
  end;
  
procedure Register;

implementation
uses Math, Consts;

procedure Register;
begin
  RegisterComponents('BaKuBaKu', [TEasyGrid]);
end;

function ColTitle(Index: Integer) : string;
var
  Hi,Lo : Integer;
begin
  Result := '';
  if (Index < 0) or (Index > 255) then Exit;
  Hi := Index div 26;
  Lo := Index mod 26;
  if Index<=25 then
     Result := Chr(Ord('A')+Lo)
  else
     Result := Chr(Ord('A')+Hi-1) + Chr(Ord('A')+Lo);
end;

procedure InvalidOp(const id: string);
begin
  raise EInvalidGridOperation.Create(id);
end;

function GridCoord(X, Y: Integer): TGridCoord;
begin
  Result.X := X;
  Result.Y := Y;
end;

function GridRect(Coord1, Coord2: TGridCoord): TGridRect;
begin
  with Result do
  begin
    Left := Coord2.X;
    if Coord1.X < Coord2.X then Left := Coord1.X;
    Right := Coord1.X;
    if Coord1.X < Coord2.X then Right := Coord2.X;
    Top := Coord2.Y;
    if Coord1.Y < Coord2.Y then Top := Coord1.Y;
    Bottom := Coord1.Y;
    if Coord1.Y < Coord2.Y then Bottom := Coord2.Y;
  end;
end;

function PointInGridRect(Col, Row: Longint; const Rect: TGridRect): Boolean;
begin
  Result := (Col >= Rect.Left) and (Col <= Rect.Right) and (Row >= Rect.Top)
    and (Row <= Rect.Bottom);
end;

function GridRectInterSects(GridRect1, GridRect2: TGridRect): Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i:=GridRect1.Left to GridRect1.Right do
    for j:=GridRect1.Top to GridRect1.Bottom do
      if PointInGridRect(i, j, GridRect2) then
         Exit;
  Result := False;
end;

type
  TXorRects = array[0..3] of TRect;

procedure XorRects(const R1, R2: TRect; var XorRects: TXorRects);
var
  Intersect, Union: TRect;

  function PtInRect(X, Y: Integer; const Rect: TRect): Boolean;
  begin
    with Rect do Result := (X >= Left) and (X <= Right) and (Y >= Top) and
      (Y <= Bottom);
  end;

  function Includes(const P1: TPoint; var P2: TPoint): Boolean;
  begin
    with P1 do
    begin
      Result := PtInRect(X, Y, R1) or PtInRect(X, Y, R2);
      if Result then P2 := P1;
    end;
  end;

  function Build(var R: TRect; const P1, P2, P3: TPoint): Boolean;
  begin
    Build := True;
    with R do
      if Includes(P1, TopLeft) then
      begin
        if not Includes(P3, BottomRight) then BottomRight := P2;
      end
      else if Includes(P2, TopLeft) then BottomRight := P3
      else Build := False;
  end;

begin
  FillChar(XorRects, SizeOf(XorRects), 0);
  if not Bool(IntersectRect(Intersect, R1, R2)) then
  begin
    { Don't intersect so its simple }
    XorRects[0] := R1;
    XorRects[1] := R2;
  end
  else
  begin
    UnionRect(Union, R1, R2);
    if Build(XorRects[0],
      Point(Union.Left, Union.Top),
      Point(Union.Left, Intersect.Top),
      Point(Union.Left, Intersect.Bottom)) then
      XorRects[0].Right := Intersect.Left;
    if Build(XorRects[1],
      Point(Intersect.Left, Union.Top),
      Point(Intersect.Right, Union.Top),
      Point(Union.Right, Union.Top)) then
      XorRects[1].Bottom := Intersect.Top;
    if Build(XorRects[2],
      Point(Union.Right, Intersect.Top),
      Point(Union.Right, Intersect.Bottom),
      Point(Union.Right, Union.Bottom)) then
      XorRects[2].Left := Intersect.Right;
    if Build(XorRects[3],
      Point(Union.Left, Union.Bottom),
      Point(Intersect.Left, Union.Bottom),
      Point(Intersect.Right, Union.Bottom)) then
      XorRects[3].Top := Intersect.Bottom;
  end;
end;

procedure ModifyExtents(var Extents: Pointer; Index, Amount: Longint;
  Default: Integer);
var
  LongSize, OldSize: LongInt;
  NewSize: Integer;
  I: Integer;
begin
  // Index Ϊ���һԪ�ص����
  // Amount Ϊ��Ԫ������ȥ��Ԫ����(����С��0)
  if Amount <> 0 then
  begin
    // OldSize ��Ϊԭ��Ԫ����,���� 0 ��Ԫ��
    if not Assigned(Extents) then OldSize := 0
    else OldSize := PIntArray(Extents)^[0];
    // ���һԪ�ص���Ų���С��0, OldSize Ӧ�õ��� Index
    if (Index < 0) or (OldSize < Index) then InvalidOp(SIndexOutOfRange);
    // LongSize Ϊ�µ�Ԫ����,����С�� 0 ��Խ��
    LongSize := OldSize + Amount;
    if LongSize < 0 then InvalidOp(STooManyDeleted)
    else if LongSize >= MaxListSize - 1 then InvalidOp(SGridTooLarge);
    // NewSize Ϊ�µ�Ԫ����+1
    NewSize := Cardinal(LongSize);
    if NewSize > 0 then Inc(NewSize);
    // Ϊ��������ڴ�
    ReallocMem(Extents, NewSize * SizeOf(Integer));
    // ����Ԫ�ظ�Ϊ Default
    if Assigned(Extents) then
    begin
      I := Index + 1;
      while I < NewSize do
      begin
        PIntArray(Extents)^[I] := Default;
        Inc(I);
      end;
      // �� 0 ��Ԫ�ظ�Ϊ�µ�Ԫ�ظ���
      PIntArray(Extents)^[0] := NewSize-1;
    end;
  end;
end;

// ���� NewSize �޸Ķ�Ӧ����(ָ��),��:FColWidth,FTabStops
procedure UpdateExtents(var Extents: Pointer; NewSize: Longint;
  Default: Integer);
var
  OldSize: Integer;
begin
  // OldSize ��Ϊԭ����(��)��,���� 0 ��Ԫ��
  OldSize := 0;
  if Assigned(Extents) then OldSize := PIntArray(Extents)^[0];
  // Default Ϊȱʡֵ
  ModifyExtents(Extents, OldSize, NewSize - OldSize, Default);
end;
{
procedure MoveExtent(var Extents: Pointer; FromIndex, ToIndex: Longint);
var
  Extent: Integer;
begin
  if Assigned(Extents) then
  begin
    Extent := PIntArray(Extents)^[FromIndex];
    if FromIndex < ToIndex then
      Move(PIntArray(Extents)^[FromIndex + 1], PIntArray(Extents)^[FromIndex],
        (ToIndex - FromIndex) * SizeOf(Integer))
    else if FromIndex > ToIndex then
      Move(PIntArray(Extents)^[ToIndex], PIntArray(Extents)^[ToIndex + 1],
        (FromIndex - ToIndex) * SizeOf(Integer));
    PIntArray(Extents)^[ToIndex] := Extent;
  end;
end;
}
// �Ƚ������п�(�и�)�����ֵ
function CompareExtents(E1, E2: Pointer): Boolean;
var
  I: Integer;
begin
  Result := False;
  if E1 <> nil then
  begin
    if E2 <> nil then
    begin
      for I := 0 to PIntArray(E1)^[0] do
        if PIntArray(E1)^[I] <> PIntArray(E2)^[I] then Exit;
      Result := True;
    end
  end
  else Result := E2 = nil;
end;

{ Private. LongMulDiv multiplys the first two arguments and then
  divides by the third.  This is used so that real number
  (floating point) arithmetic is not necessary.  This routine saves
  the possible 64-bit value in a temp before doing the divide.  Does
  not do error checking like divide by zero.  Also assumes that the
  result is in the 32-bit range (Actually 31-bit, since this algorithm
  is for unsigned). }

function LongMulDiv(Mult1, Mult2, Div1: Longint): Longint; stdcall;
  external 'kernel32.dll' name 'MulDiv';

type
  TSelection = record
    StartPos, EndPos: Integer;
  end;

// ���� Cell ����(�������ϲ���Ϣ)
procedure CellToCell(SrcCell,DestCell : PCellInfo);
begin
  with DestCell^ do
    begin
      DataStyle    := SrcCell.DataStyle;
      AlignMode    := SrcCell.AlignMode;

      ReadOnly     := SrcCell.ReadOnly;
      AutoWordBreak := SrcCell.AutoWordBreak;
      ShowForeText := SrcCell.ShowForeText;
      DrawTop      := SrcCell.DrawTop;
      DrawLeft     := SrcCell.DrawLeft;
      DrawBottom   := SrcCell.DrawBottom;
      DrawRight    := SrcCell.DrawRight;

      AllowNegative := SrcCell.AllowNegative;
      TrailingZero  := SrcCell.TrailingZero;
      ZeroNull     := SrcCell.ZeroNull;
      ThousandSep  := SrcCell.ThousandSep;
      MaxLength    := SrcCell.MaxLength;
      IntLength    := SrcCell.IntLength;
      DecLength    := SrcCell.DecLength;

      LineWidth    := SrcCell.LineWidth;
      PenStyle     := SrcCell.PenStyle;
      Number       := SrcCell.Number;
      Color        := SrcCell.Color;

      FontSize     := SrcCell.FontSize;
      FontColor    := SrcCell.FontColor;
      FontStyle    := SrcCell.FontStyle;

      FontName     := SrcCell.FontName;
      ForeText     := SrcCell.ForeText;
      BackText     := SrcCell.BackText;
    end;
end;

procedure Restrict(var Coord: TGridCoord; MinX, MinY, MaxX, MaxY: Longint);
begin
  with Coord do
  begin
    if X > MaxX then X := MaxX
    else if X < MinX then X := MinX;
    if Y > MaxY then Y := MaxY
    else if Y < MinY then Y := MinY;
  end;
end;

// ��ʾ��ʾ��Ϣ
procedure Say(SayString: string);
begin
  Application.MessageBox(PChar(SayString),'��ʾ',
                         MB_OK + MB_ICONINFORMATION);
end;

// ��ʾ������Ϣ
procedure SayStop(SayString: string);
begin
  Application.MessageBox(PChar(SayString),'��ʾ',
                         MB_OK + MB_ICONSTOP);
end;

// ѯ����Ϣ
function Ask(AskString:string;DefaultButton:Byte = 1) : Boolean;
var
   Flag : Integer;
begin
     Result := False;
     Flag := MB_DEFBUTTON1;
     if DefaultButton = 2 then
        Flag := MB_DEFBUTTON2;
     if (Application.MessageBox(PChar(AskString),'ѯ��',MB_OKCANCEL + MB_ICONQUESTION + Flag) = IDOK) then
        Result := True;
end;

function MoneyToStr(S: string): string;
var
  Len, i: Integer;
begin
  i:=1;
  Len := Length(S);
  while i<=Len do
  begin
    if S[i] = ThousandSeparator then
    begin
      Delete(S, i ,1);
      Dec(Len);
    end;
    Inc(i);
  end;
  Result := Trim(S);
end;

function StrToMoney(S: string; IntLen, DecLen: Integer;
         HasTrailingZero: Boolean = True; IsZeroNull: Boolean = True;
         HasThousandSep: Boolean = True): string;
var
  TempResult, fmtStr: string;
  Len, DotPos, i: Integer;
begin
  Result := '';
  S := MoneyToStr(S);
  if (S = '') or (S = '-') or (S = '0.') or (S = '0') or ((StrToFloat(S) = 0) and IsZeroNull) then Exit;
  fmtStr := '%'+IntToStr(IntLen)+'.'+IntToStr(DecLen)+'f';
  TempResult := Format(fmtStr, [StrToFloat(S)]);
  if HasThousandSep then
  begin
    fmtStr := '%'+IntToStr(IntLen)+'.'+IntToStr(DecLen)+'n';
    TempResult := Format(fmtStr, [StrToFloat(S)]);
  end;
  DotPos := Pos('.', TempResult);
  if (not HasTrailingZero) and (DotPos > 0) then
  begin
    i := Length(TempResult);
    while (i > 0) and (TempResult[i] = '0') do
    begin
      Delete(TempResult, i, 1);
      Dec(i);
    end;
  end;
  Len := Length(TempResult);
  if TempResult[Len] = '.' then
    Delete(TempResult, Len, 1);
  Result := Trim(TempResult);
end;

// ******************************************************************
// SetClipRect : �� OldRgn ���浱ǰ������,Ȼ��� ClipR ��Ϊ�µļ�����
// RestoreClipRect : �ָ�ԭ���ļ�����(�ϴα����� OldRgn ��)
procedure TCustomEasyGrid.SetClipRect(ACanvas: TCanvas; ClipR: TRect);
begin
  OldRgn := 0;
  OldRgn := CreateRectRgn(0,0,0,0);
  HaveClip := GetClipRgn(ACanvas.Handle, OldRgn);

  NewRgn := CreateRectRgnIndirect(ClipR);
  SelectClipRgn(ACanvas.Handle, NewRgn);
  DeleteObject(NewRgn);
end;

procedure TCustomEasyGrid.RestoreClipRect(ACanvas: TCanvas);
begin
  if HaveClip > 0 then
    SelectClipRgn(ACanvas.Handle, OldRgn)
  else
    SelectClipRgn(ACanvas.Handle, 0);
  DeleteObject(OldRgn);
end;
// ע��: SetClipRect �� RestoreClipRect �����ͬһ�� Canvas ���ʹ��
// ******************************************************************

function TCustomEasyGrid.FindLastVisibleCell(Start: Integer; AAxisDrawInfo: TEasyGridAxisDrawInfo): Integer;
begin
  Result := Start;
  with AAxisDrawInfo do
  begin
    while (Result > FixedCellCount) and (GetExtent(Result) < 0) do
      Dec(Result);
    if Result <= FixedCellCount then
      Result := Start + 1;
  end;
end;

function TCustomEasyGrid.FindNextVisibleCell(Start: Integer; AAxisDrawInfo: TEasyGridAxisDrawInfo): Integer;
begin
  Result := Start;
  with AAxisDrawInfo do
  begin
    while (Result < GridCellCount) and (GetExtent(Result) < 0) do
      Inc(Result);
    if Result >= GridCellCount then
      Result := Start - 1;
  end;
end;

// ����ʽ�˵������Ӧ�¼�
procedure TCustomEasyGrid.MenuItemClick(Sender: TObject);
begin
  case TMenuItemTag(TMenuItem(Sender).Tag) of
    mtCut :
      CutCells(TRect(Selection));
    mtCopy :
      CopyCells(TRect(Selection));
    mtPaste :
      PasteCells(TPoint(FCurrent));
    mtInsertCellRight :
      InsertCellRight(TRect(Selection));
    mtInsertCellDown :
      InsertCellDown(TRect(Selection));
    mtInsertCol :
      InsertCol(TRect(Selection));
    mtInsertRow :
      InsertRow(TRect(Selection));
    mtDeleteCellRight :
      DeleteCellRight(TRect(Selection));
    mtDeleteCellDown :
      DeleteCellDown(TRect(Selection));
    mtDeleteCol :
      DeleteCol(TRect(Selection));
    mtDeleteRow :
      DeleteRow(TRect(Selection));
    mtClearCells :
      ClearCells(TRect(Selection));
    mtSetCellProp :
      SetCellProp;
  end;
end;

procedure TCustomEasyGrid.SetCellProp(DefaultPage: Integer = -1);
var
  Index: Integer;
begin
  FormCellProp := TFormCellProp.Create(Self);
  Index := DefaultPage;
  if (DefaultPage < 0) then Index := FCellPropPageIndex;
  if (Index >= FormCellProp.PageCtlCellProp.PageCount) then
    Index := FormCellProp.PageCtlCellProp.PageCount - 1;
  with FormCellProp do
  begin
    ParentGrid := TEasyGrid(Self);
    PageCtlCellProp.ActivePage := PageCtlCellProp.Pages[Index];
    ShowModal;
    FCellPropPageIndex := PageCtlCellProp.ActivePage.PageIndex;
    if ModalResult = mrOk then
      if Assigned(FAfterSetCellProp) then FAfterSetCellProp(Self, TRect(Selection));
  end;
  FormCellProp.Release;
end;

// ��ʼ������ʽ�˵�
procedure TCustomEasyGrid.InitPopupMenu;
var
  AMenuItem, BMenuItem: TMenuItem;
begin
  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '����(&T)';
  AMenuItem.Tag := Ord(mtCut);
  AMenuItem.OnClick := MenuItemClick;
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '����(&C)';
  AMenuItem.Tag := Ord(mtCopy);
  AMenuItem.OnClick := MenuItemClick;
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := 'ճ��(&P)';
  AMenuItem.Tag := Ord(mtPaste);
  AMenuItem.OnClick := MenuItemClick;
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '-';
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '����(&I)...';
  EasyGridPopup.Items.Add(AMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '������뵥Ԫ��';
    BMenuItem.Tag := Ord(mtInsertCellRight);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '������뵥Ԫ��';
    BMenuItem.Tag := Ord(mtInsertCellDown);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '��������';
    BMenuItem.Tag := Ord(mtInsertRow);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '��������';
    BMenuItem.Tag := Ord(mtInsertCol);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := 'ɾ��(&D)...';
  EasyGridPopup.Items.Add(AMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '����ɾ����Ԫ��';
    BMenuItem.Tag := Ord(mtDeleteCellRight);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := '����ɾ����Ԫ��';
    BMenuItem.Tag := Ord(mtDeleteCellDown);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := 'ɾ������';
    BMenuItem.Tag := Ord(mtDeleteRow);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

    BMenuItem := TMenuItem.Create(AMenuItem);
    BMenuItem.Caption := 'ɾ������';
    BMenuItem.Tag := Ord(mtDeleteCol);
    BMenuItem.OnClick := MenuItemClick;
    AMenuItem.Add(BMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '�����Ԫ������(&N)';
  AMenuItem.Tag := Ord(mtClearCells);
  AMenuItem.OnClick := MenuItemClick;
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '-';
  EasyGridPopup.Items.Add(AMenuItem);

  AMenuItem := TMenuItem.Create(EasyGridPopup);
  AMenuItem.Caption := '���õ�Ԫ���ʽ(&F)...';
  AMenuItem.Tag := Ord(mtSetCellProp);
  AMenuItem.OnClick := MenuItemClick;
  EasyGridPopup.Items.Add(AMenuItem);
end;

constructor TInplaceEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ParentCtl3D := False;
  Ctl3D := False;
  TabStop := False;
  BorderStyle := bsNone;
  DoubleBuffered := False;
end;

procedure TInplaceEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and not ES_AUTOHSCROLL or ES_MULTILINE;
end;

procedure TInplaceEdit.CMShowingChanged(var Message: TMessage);
begin
  { Ignore showing using the Visible property }
end;

procedure TInplaceEdit.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  if goTabs in Grid.Options then
    Message.Result := Message.Result or DLGC_WANTTAB;
end;

procedure TInplaceEdit.WMClear(var Message);
begin
  if not EditCanModify then Exit;
  inherited;
end;

procedure TInplaceEdit.WMCut(var Message);
begin
  if not EditCanModify then Exit;
  inherited;
end;

procedure TInplaceEdit.DblClick;
begin
  Grid.DblClick;
end;

function TInplaceEdit.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := Grid.DoMouseWheel(Shift, WheelDelta, MousePos);
end;

function TInplaceEdit.EditCanModify: Boolean;
begin
  Result := Grid.CanEditModify;
end;

procedure TInplaceEdit.ValidateError;
begin
  Say(PleaseInputCorrectData);
end;

procedure TInplaceEdit.KeyDown(var Key: Word; Shift: TShiftState);

  procedure SendToParent;
  begin
    Grid.KeyDown(Key, Shift);
    Key := 0;
  end;

  procedure ParentEvent;
  var
    GridKeyDown: TKeyEvent;
  begin
    GridKeyDown := Grid.OnKeyDown;
    if Assigned(GridKeyDown) then GridKeyDown(Grid, Key, Shift);
  end;

  function Ctrl: Boolean;
  begin
    Result := ssCtrl in Shift;
  end;

  function Selection: TSelection;
  begin
    SendMessage(Handle, EM_GETSEL, Longint(@Result.StartPos), Longint(@Result.EndPos));
  end;

  function RightSide: Boolean;
  begin
    with Selection do
      Result := ((StartPos = 0) or (EndPos = StartPos)) and
        (EndPos = GetTextLen);
   end;

  function LeftSide: Boolean;
  begin
    with Selection do
      Result := (StartPos = 0) and ((EndPos = 0) or (EndPos = GetTextLen));
  end;

begin
  case Key of
    VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT: SendToParent;
    VK_ESCAPE:
      begin
        Text := FTempText;
        SendToParent;
      end;
    VK_INSERT:
      if Shift = [] then SendToParent
      else if (Shift = [ssShift]) and not Grid.CanEditModify then Key := 0;
    VK_LEFT: if not Ctrl and LeftSide then SendToParent;
    VK_RIGHT: if not Ctrl and RightSide then SendToParent;
    VK_HOME: if not Ctrl and LeftSide then
             begin
               Key := VK_LEFT;
               SendToParent;
             end;
    VK_END: if not Ctrl and RightSide then
            begin
              Key := VK_RIGHT;
              SendToParent;
            end;
    VK_F2:
      begin
        ParentEvent;
        if Key = VK_F2 then
        begin
          Deselect;
          Exit;
        end;
      end;
    VK_TAB: if not (ssAlt in Shift) then SendToParent;
  end;
  if (Key = VK_DELETE) and not Grid.CanEditModify then Key := 0;
  if Key <> 0 then
  begin
    ParentEvent;
    inherited KeyDown(Key, Shift);
  end;
end;

procedure TInplaceEdit.KeyPress(var Key: Char);
var
  Selection: TSelection;
  CurPos: Integer;
  S1: string;
begin
  Grid.KeyPress(Key);
  if (Key in [#32..#255]) and not Grid.CanEditAcceptKey(Key) then
  begin
    Key := #0;
    MessageBeep(0);
  end;
  case Key of
    #9, #27: Key := #0;
    #13:
      begin
        SendMessage(Handle, EM_GETSEL, Longint(@Selection.StartPos), Longint(@Selection.EndPos));
        if (Selection.StartPos = 0) and (Selection.EndPos = GetTextLen) then
          Deselect else
          SelectAll;
        Key := #0;
      end;
    ^H, ^V, ^X, #32..#255:
      if not Grid.CanEditModify then Key := #0;
  end;
  if (FCell.DataStyle = dsText) or (FCell.DataStyle = dsTime) or (FCell.DataStyle = dsDate) then
    begin Inherited; Exit; end;
  //if (FCell.DataStyle = dsText) or (Key in [^C, #8, #9, #13, ^V, ^X, ^Z, #27]) then Exit;
  if (FCell.DataStyle = dsNumber) then
  begin
    if (Key in [^C, #8, #9, #13, ^V, ^X, ^Z, #27]) then Exit;
    CurPos := GetSelStart + 1;
    S1 := Text;
    Insert(Key, S1, CurPos);
    if CanAcceptKey(S1, CurPos) then
    begin
      Text := S1;
      SetSelStart(CurPos);
    end;
    Key := #0;
  end;
end;

procedure TInplaceEdit.KeyUp(var Key: Word; Shift: TShiftState);
begin
  Grid.KeyUp(Key, Shift);
end;

procedure TInplaceEdit.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_SETFOCUS:
      begin
        if (GetParentForm(Self) = nil) or GetParentForm(Self).SetFocusedControl(Grid) then Dispatch(Message);
        Exit;
      end;
    WM_LBUTTONDOWN:
      begin
        if UINT(GetMessageTime - FClickTime) < GetDoubleClickTime then
          Message.Msg := WM_LBUTTONDBLCLK;
        FClickTime := 0;
      end;
  end;
  inherited WndProc(Message);
end;

procedure TInplaceEdit.WMPaste(var Message);
var
  S1, S2: String;
  StartPos, EndPos: Integer;
begin
  if not EditCanModify then Exit;
  if FCell.DataStyle = dsText then
  begin
    inherited;
    Exit;
  end;
  if not Clipboard.HasFormat(CF_TEXT) then Exit;
  S2 := Clipboard.AsText;
  StartPos := GetSelStart;
  EndPos := StartPos + GetSelLength;
  S1 := Text;
  S1 := Copy(S1, 1, StartPos) + S2 + Copy(S1, EndPos, Length(S1) - EndPos + 1);
  Inc(StartPos, Length(S2));
  if CanAcceptKey(S1, StartPos) then
  begin
    Text := S1;
    SetSelStart(StartPos);
  end;
end;

procedure TInplaceEdit.Deselect;
begin
  SendMessage(Handle, EM_SETSEL, $7FFFFFFF, Longint($FFFFFFFF));
end;

procedure TInplaceEdit.Invalidate;
var
  Cur: TRect;
begin
  ValidateRect(Handle, nil);
  InvalidateRect(Handle, nil, True);
  Windows.GetClientRect(Handle, Cur);
  MapWindowPoints(Handle, Grid.Handle, Cur, 2);
  ValidateRect(Grid.Handle, @Cur);
  InvalidateRect(Grid.Handle, @Cur, False);
end;

procedure TInplaceEdit.Hide;
begin
  if HandleAllocated and IsWindowVisible(Handle) then
  begin
    Invalidate;
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_HIDEWINDOW or SWP_NOZORDER or
      SWP_NOREDRAW);
    if Focused then Windows.SetFocus(Grid.Handle);
  end;
end;

function TInplaceEdit.PosEqual(const Rect: TRect): Boolean;
var
  Cur: TRect;
begin
  GetWindowRect(Handle, Cur);
  MapWindowPoints(HWND_DESKTOP, Grid.Handle, Cur, 2);
  Result := EqualRect(Rect, Cur);
end;

procedure TInplaceEdit.InternalMove(const Loc: TRect; Redraw: Boolean);
begin
  if IsRectEmpty(Loc) then Hide
  else
  begin
    CreateHandle;
    Redraw := Redraw or not IsWindowVisible(Handle);
    Invalidate;
    with Loc do
      SetWindowPos(Handle, HWND_TOP, Left, Top, Right - Left, Bottom - Top,
        SWP_SHOWWINDOW or SWP_NOREDRAW);
    BoundsChanged;
    if Redraw then Invalidate;
    if Grid.Focused then
      Windows.SetFocus(Handle);
  end;
end;

function TInplaceEdit.CanAcceptKey(var S: String; var CharPos: Integer): Boolean;
var
  S1: String;
  IsNegative: Boolean;
  i, DotPos: Integer;
begin
  Result := False;
  S1 := S;
  IsNegative := False;
  with FCell^ do
    case DataStyle of
      dsNumber :
        begin
          // ������󳤶�
          if Length(S1) > MaxLength then Exit;
          // ����ֻ�����������ַ�
          for i := 1 to Length(S1) do
            if not (S1[i] in ['-', '.', '0'..'9']) then Exit;
          // ������������븺��,���������븺��
          if (not AllowNegative) and (Pos('-', S1) > 0) then Exit;
          // �������������С��
          if (DecLength = 0) then
            begin
              // ������С����
              DotPos := Pos('.', S1);
              if DotPos > 0 then Exit;
              // ����������븺��
              if AllowNegative then
              begin
                // ���������м���븺��
                if (S1[1] = '-') then Delete(S1, 1, 1);
                if Pos('-', S1) > 0 then Exit;
                // �����������ֳ���
                if (Length(S1) > IntLength + 1) then Exit;
              end;
              // ����������߲������������������ 0
              if (Length(S1) >= 2) and (S1[1] = '0') and (S1[2] = '0') then Exit;
            end
          // ��������С��
          else
            begin
              // ����������븺��
              if AllowNegative and (S1[1] = '-') then
              begin
                // ��ȥ����
                Delete(S1, 1, 1);
                IsNegative := True;
                // �������뵥���ĸ���
                if S1 = '' then
                begin
                  Result := True;
                  Exit;
                end;
              end;
              DotPos := Pos('.', S1);
              // ���� MaxIntLength �� MaxDecLength
              if ((DotPos > 0) and ((Length(S1) - DotPos) > DecLength)) or
                 ((DotPos = 0) and ((Length(S1) > IntLength))) or
                 ((DotPos > 0) and (DotPos > IntLength + 1)) then Exit;
              // ����������߲������������������ 0
              if (Length(S1) >= 2) and (S1[1] = '0') and (S1[2] = '0') then Exit;
              // �ڵ�����С����ǰ�����һ�� 0 (��: 0. , -0.)
              if S1[1] = '.' then
              begin
                if IsNegative then Insert('0', S, 2) else Insert('0', S, 1);
                Inc(CharPos);
                Delete(S1, 1, 1);
              end
              else
              begin
                DotPos := Pos('.', S1);
                if DotPos > 0 then Delete(S1, DotPos, 1);
              end;
              if Pos('-', S1) > 0 then Exit;
              if Pos('.', S1) > 0 then Exit;
            end;
        end;// of dsNumber begin
    end;// of case
  Result := True;
end;

procedure TInplaceEdit.BoundsChanged;
var
  R: TRect;
begin
  R := Rect(2, 2, Width - 2, Height);
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@R));
  SendMessage(Handle, EM_SCROLLCARET, 0, 0);
end;

procedure TInplaceEdit.UpdateLoc(const Loc: TRect);
begin
  InternalMove(Loc, False);
end;

function TInplaceEdit.Visible: Boolean;
begin
  Result := IsWindowVisible(Handle);
end;

procedure TInplaceEdit.Move(const Loc: TRect);
begin
  InternalMove(Loc, True);
end;

procedure TInplaceEdit.SetFocus;
begin
  if IsWindowVisible(Handle) then
    Windows.SetFocus(Handle);
end;

procedure TInplaceEdit.UpdateContents;
begin
  Text := '';
  Cell := Grid.Cells[Grid.Col, Grid.Row];
  if Cell.ShowForeText then
    begin
      case Cell.DataStyle of
        dsText : EditMask := Grid.GetEditMask(Grid.Col, Grid.Row);
        dsFormula, dsNumber : EditMask := '';
        dsDate : EditMask := '9999/99/99;1; ';
        dsTime : EditMask := '00:00:00;1; ';
      end;
      Text := Grid.GetEditText(Grid.Col, Grid.Row);
      if (Cell.DataStyle = dsNumber) and (Cell.ThousandSep) then
        Text := MoneyToStr(Text);
      MaxLength := Grid.GetEditLimit;
    end
  else
    begin
      EditMask := '';
      Text := Grid.GetEditText(Grid.Col, Grid.Row);
      MaxLength := 0;
    end;
  FTempText := Text;
  Color := Cell.Color;
  with Cell^, Self.Font do
  begin
    Name := FontName;
    Size := FontSize;
    Style := FontStyle;
    Color := FontColor;
  end;
end;

constructor TCells.Create(AGrid:TCustomEasyGrid;AColCount,ARowCount : Integer);
var
   i : Integer;
   AColCellInfoList : TColCellInfoList;
begin
  inherited Create;
  FGrid := AGrid;
  for i:=0 to AColCount-1 do
    begin
      AColCellInfoList := TColCellInfoList.Create(AGrid,i,ARowCount);
      Add(AColCellInfoList);
    end;
end;

procedure TCells.Clear;
var
  i : Integer;
begin
  for i := 0 to Count - 1 do
    TColCellInfoList(Items[i]).Free;
  inherited;
end;

procedure TColCellInfoList.Clear;
var
  i : Integer;
begin
  for i := 0 to Count - 1 do
    Dispose(PCellInfo(Items[i]));
  inherited;
end;

constructor TColCellInfoList.Create(AGrid:TCustomEasyGrid;ACol,ARowCount : Integer);
var
  i : Integer;
  ACellInfo : PCellInfo;
begin
  inherited Create;
  for i := 0 to ARowCount - 1 do
  begin
    New(ACellInfo);
    AGrid.InitCell(AGrid,ACellInfo,ACol,i);
    Add(ACellInfo);
  end;
end;

{ TCustomEasyGrid }

constructor TCustomEasyGrid.Create(AOwner: TComponent);
const
  GridStyle = [csCaptureMouse, csOpaque, csDoubleClicks];
begin
  inherited Create(AOwner);
  if NewStyleControls then
    ControlStyle := GridStyle else
    ControlStyle := GridStyle + [csFramed];

  FCanEditModify := True;
  FAutoUpdate := True;
  FCellPropPageIndex := 0;
  DesignOptionsBoost := [goColSizing, goRowSizing];
  
  FGridCanCopyMove := True;
  FGridCanFill := True;
  FShowPopup := True;
  FColCount := 5;
  FRowCount := 5;
  FFixedCols := 0;
  FFixedRows := 0;
  FGridLineWidth := 1;
  FOptions := [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine,
    goRangeSelect];
  FFixedLineColor := clBlack;
  FClientLineColor := clSilver;
  FScrollBars := ssBoth;
  FBorderStyle := bsSingle;
  FDefaultColWidth := 80;
  FDefaultRowHeight := 30;
  FDefaultDrawing := True;
  FSaveCellExtents := True;
  FEditorMode := False;
  Color := clWindow;
  ParentColor := False;
  TabStop := True;
  FShowColTitle := True;
  FShowRowTitle := True;
  FTitleColor := clBtnFace;
  FHighLightColor := clBlack;
  FHighLightTextColor := clWhite;
  FFocusedTitleColor := clBlack;
  FDataStyle := dsText;
  FAlignMode := taTopLeft;
  FShowForeText := True;
  FReadOnly := False;
  FAutoWordBreak := True;
  FCellLineWidth := 1;
  FCellPenStyle := psSolid;
  FAllowNegative := True; 
  FTrailingZero := False;
  FZeroNull := True;
  FThousandSep := True;
  FMaxLength := 255;
  FIntLength := 3;
  FDecLength := 2;
  FColor := clWhite;
  FFontName  := '����';
  FFontSize  := 9;
  FFontColor := clBlack;
  FFontStyle := [];

  SetBounds(Left, Top, FColCount * FDefaultColWidth,
    FRowCount * FDefaultRowHeight);
  FillChar(FCopyMoveRect, SizeOf(FCopyMoveRect), 0);
  FillChar(FCopyMoveCell, SizeOf(FCopyMoveCell), 0);
  FillChar(FCopyMoveOffset, SizeOf(FCopyMoveOffset), 0);

  FFillStyle := fsNone;
  FillChar(FFillRect, SizeOf(FFillRect), 0);
  FillChar(FFillCell, SizeOf(FFillCell), 0);
  FillChar(FFillOffset, SizeOf(FFillOffset), 0);

  InitializeGrid;
  Screen.Cursors[crExcel] := LoadCursor(HInstance, 'EXCEL');
  Screen.Cursors[crZoomIn] := LoadCursor(HInstance, 'ZOOMIN');
  Screen.Cursors[crZoomOut] := LoadCursor(HInstance, 'ZOOMOUT');
  FCells := TCells.Create(Self,FColCount,FRowCount);

  EasyGridPopup := TPopupMenu.Create(nil);
  InitPopupMenu;
  EasyGridPageInfo := TEasyGridPageInfo.Create;
  SetLength(PageDrawInfoList, 1);
  FPageSetupPageIndex := 0;
  FPreviewZoomIndex := 6;  // 50%
  DoubleBuffered := True;
end;

destructor TCustomEasyGrid.Destroy;
begin
  FInplaceEdit.Free;
  FCells.Free;
  EasyGridPopup.Free;
  EasyGridPageInfo.Free;
  Finalize(PageDrawInfoList);
  inherited Destroy;
  FreeMem(FColWidths);
  FreeMem(FRowHeights);
  FreeMem(FColCanSizes);
  FreeMem(FRowCanSizes);
  FreeMem(FTabStops);
end;

procedure TCustomEasyGrid.InitializeGrid;
begin
  FTopLeft.X := FixedCols+1;
  FTopLeft.Y := FixedRows+1;
  FCurrent := FTopLeft;
  FAnchor := FCurrent;
  if goRowSelect in Options then FAnchor.X := ColCount - 1;
  FSelStart := GridRect(FCurrent, FAnchor).TopLeft;
  FSelEnd := GridRect(FCurrent, FAnchor).BottomRight;
  if goRowSelect in Options then
  begin
    FSelStart.X := FixedCols + 1;
    FSelEnd.X := ColCount - 1;
  end;
end;

procedure TCustomEasyGrid.AdjustSize(Index, Amount: Longint; Rows: Boolean);
var
  NewCur: TGridCoord;
  OldRows, OldCols: Longint;
  MovementX, MovementY: Longint;
  MoveRect: TGridRect;
  ScrollArea: TRect;
  AbsAmount: Longint;

  function DoSizeAdjust(var Count: Longint; var Extents: Pointer;
    DefaultExtent: Integer; var Current: Longint): Longint;
  var
    I: Integer;
    NewCount: Longint;
  begin
    NewCount := Count + Amount;
    if NewCount < Index then InvalidOp(STooManyDeleted);
    if (Amount < 0) and Assigned(Extents) then
    begin
      Result := 0;
      for I := Index to Index - Amount - 1 do
        Inc(Result, PIntArray(Extents)^[I]);
    end
    else
      Result := Amount * DefaultExtent;
    if Extents <> nil then
      ModifyExtents(Extents, Index, Amount, DefaultExtent);
    Count := NewCount;
    if Current >= Index then
      if (Amount < 0) and (Current < Index - Amount) then Current := Index
      else Inc(Current, Amount);
  end;

begin
  if Amount = 0 then Exit;
  NewCur := FCurrent;
  OldCols := ColCount;
  OldRows := RowCount;
  MoveRect.Left := FixedCols+1;
  MoveRect.Right := ColCount - 1;
  MoveRect.Top := FixedRows+1;
  MoveRect.Bottom := RowCount - 1;
  MovementX := 0;
  MovementY := 0;
  AbsAmount := Amount;
  if AbsAmount < 0 then AbsAmount := -AbsAmount;
  if Rows then
  begin
    MovementY := DoSizeAdjust(FRowCount, FRowHeights, DefaultRowHeight, NewCur.Y);
    MoveRect.Top := Index;
    if Index + AbsAmount <= TopRow then MoveRect.Bottom := TopRow - 1;
  end
  else
  begin
    MovementX := DoSizeAdjust(FColCount, FColWidths, DefaultColWidth, NewCur.X);
    MoveRect.Left := Index;
    if Index + AbsAmount <= LeftCol then MoveRect.Right := LeftCol - 1;
  end;
  GridRectToScreenRect(MoveRect, ScrollArea, True);
  if not IsRectEmpty(ScrollArea) then
  begin
    ScrollWindow(Handle, MovementX, MovementY, @ScrollArea, @ScrollArea);
    UpdateWindow(Handle);
  end;
  SizeChanged(OldCols, OldRows);
  if (NewCur.X <> FCurrent.X) or (NewCur.Y <> FCurrent.Y) then
    MoveCurrent(NewCur.X, NewCur.Y, True, True, True);
end;

function TCustomEasyGrid.BoxRect(ALeft, ATop, ARight, ABottom: Longint): TRect;
var
  GridRect: TGridRect;
begin
  GridRect.Left := Min(ALeft,ARight);
  GridRect.Right := Max(ALeft,ARight);
  GridRect.Top := Min(ATop,ABottom);
  GridRect.Bottom := Max(ATop,ABottom);
  GridRectToScreenRect(GridRect, Result, False);
end;

procedure TCustomEasyGrid.DoExit;
begin
  inherited DoExit;
  if not (goAlwaysShowEditor in Options) then HideEditor;
end;

function TCustomEasyGrid.CellRect(ACol, ARow: Longint): TRect;
begin
  Result := BoxRect(ACol, ARow, ACol, ARow);
end;

function TCustomEasyGrid.CanEditAcceptKey(Key: Char): Boolean;
begin
  Result := True;
end;

function TCustomEasyGrid.CanGridAcceptKey(Key: Word; Shift: TShiftState): Boolean;
begin
  Result := True;
end;

function TCustomEasyGrid.CanEditModify: Boolean;
begin
  Result := FCanEditModify;
end;

function TCustomEasyGrid.CanEditShow: Boolean;
begin
  Result := ([goRowSelect, goEditing] * Options = [goEditing]) and
    FEditorMode and not (csDesigning in ComponentState) and HandleAllocated and
    ((goAlwaysShowEditor in Options) or IsActiveControl) and (not Cells[Col, Row].ReadOnly);
end;

function TCustomEasyGrid.IsActiveControl: Boolean;
var
  H: Hwnd;
  ParentForm: TCustomForm;
begin
  Result := False;
  ParentForm := GetParentForm(Self);
  // ����и�����
  if Assigned(ParentForm) then
  begin
    // �Ҹ����ڵ� ActiveControl �����Լ�
    if (ParentForm.ActiveControl = Self) then
      Result := True
  end
  // ��������������Լ���ĳһ�� Child ��
  else
  begin
    H := GetFocus;
    while IsWindow(H) and (Result = False) do
    begin
      if H = WindowHandle then
        Result := True
      else
        H := GetParent(H);
    end;
  end;
end;

function TCustomEasyGrid.GetEditMask(ACol, ARow: Longint): string;
begin
  Result := '';
  if Assigned(FOnGetEditMask) then FOnGetEditMask(Self, ACol, ARow, Result);
end;

function TCustomEasyGrid.GetEditLimit: Integer;
begin
  Result := 0;
end;

procedure TCustomEasyGrid.HideEditor;
begin
  FEditorMode := False;
  HideEdit;
end;

procedure TCustomEasyGrid.ShowEditor;
var
  NewTopLeft, MaxTopLeft: TGridCoord;
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  MaxTopLeft.X := ColCount - 1;
  MaxTopLeft.Y := RowCount - 1;
  MaxTopLeft := CalcMaxTopLeft(MaxTopLeft, DrawInfo);
  NewTopLeft.X := Min(FCurrent.X, MaxTopLeft.X);
  NewTopLeft.Y := Min(FCurrent.Y, MaxTopLeft.Y);
  if ((FCurrent.X < LeftCol) or (FCurrent.Y < TopRow) or
      (FCurrent.X < LeftCol) or (FCurrent.Y < TopRow)) and
     ((NewTopLeft.X <> FTopLeft.X) or (NewTopLeft.Y <> FTopLeft.Y)) then
    MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
  FEditorMode := True;
  UpdateEdit;
end;

procedure TCustomEasyGrid.ShowEditorChar(Ch: Char);
begin
  ShowEditor;
  if FInplaceEdit <> nil then
    PostMessage(FInplaceEdit.Handle, WM_CHAR, Word(Ch), 0);
end;

procedure TCustomEasyGrid.InvalidateEditor;
begin
  FInplaceCol := -1;
  FInplaceRow := -1;
  UpdateEdit;
end;

procedure TCustomEasyGrid.ReadColWidths(Reader: TReader);
var
  I: Integer;
begin
  with Reader do
  begin
    ReadListBegin;
    for I := 0 to ColCount - 1 do ColWidths[I] := ReadInteger;
    ReadListEnd;
  end;
end;

procedure TCustomEasyGrid.ReadRowHeights(Reader: TReader);
var
  I: Integer;
begin
  with Reader do
  begin
    ReadListBegin;
    for I := 0 to RowCount - 1 do RowHeights[I] := ReadInteger;
    ReadListEnd;
  end;
end;

procedure TCustomEasyGrid.WriteColWidths(Writer: TWriter);
var
  I: Integer;
begin
  with Writer do
  begin
    WriteListBegin;
    for I := 0 to ColCount - 1 do WriteInteger(ColWidths[I]);
    WriteListEnd;
  end;
end;

procedure TCustomEasyGrid.WriteRowHeights(Writer: TWriter);
var
  I: Integer;
begin
  with Writer do
  begin
    WriteListBegin;
    for I := 0 to RowCount - 1 do WriteInteger(RowHeights[I]);
    WriteListEnd;
  end;
end;

procedure TCustomEasyGrid.DefineProperties(Filer: TFiler);

  function DoColWidths: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not CompareExtents(TCustomEasyGrid(Filer.Ancestor).FColWidths, FColWidths)
    else
      Result := FColWidths <> nil;
  end;

  function DoRowHeights: Boolean;
  begin
    if Filer.Ancestor <> nil then
      Result := not CompareExtents(TCustomEasyGrid(Filer.Ancestor).FRowHeights, FRowHeights)
    else
      Result := FRowHeights <> nil;
  end;


begin
  inherited DefineProperties(Filer);
  if FSaveCellExtents then
    with Filer do
    begin
      DefineProperty('ColWidths', ReadColWidths, WriteColWidths, DoColWidths);
      DefineProperty('RowHeights', ReadRowHeights, WriteRowHeights, DoRowHeights);
    end;
end;

// ���� ClipR ������� DrawCells( DrawCell �ĸ�����) �еļ�������
procedure TCustomEasyGrid.DrawCell(ACol, ARow: Longint; TextRect, ClipR: TRect;
          AState: TEasyGridDrawState);
var
  TextAlignMode: Cardinal;
  TextToDraw: PChar;
  BorderRect, TestRect: TRect;    // �߿�Χ���ı��������Χ
  TestWidth, TestHeight: Integer;            // ʵ�ʿ��
  DrawWidth, DrawHeight: Integer;            // �滭�����

  // �����ı������ʵ�ʿ��
  procedure CalcTestRect;
  var
    CalcMode: Cardinal;
  begin
    TestRect := TextRect;
    with TestRect do
    begin
      Dec(Right, Left);
      Dec(Bottom, Top);
      Left := 0;
      Top := 0;
    end;
    CalcMode := DT_CALCRECT;
    if Cells[ACol, ARow].AutoWordBreak then
      CalcMode := CalcMode or DT_WORDBREAK;
    DrawText(Canvas.Handle, TextToDraw, -1, TestRect, CalcMode);
    TestWidth :=  TestRect.Right  - TestRect.Left;
    TestHeight := TestRect.Bottom - TestRect.Top;
    DrawWidth :=  TextRect.Right  - TextRect.Left;
    DrawHeight := TextRect.Bottom - TextRect.Top;
    TestRect.Left := (DrawWidth - TestWidth) div 2;
    TestRect.Right := TestRect.Left + TestWidth;
    TestRect.Top := (DrawHeight - TestHeight) div 2;
    TestRect.Bottom := TestRect.Top + TestHeight;
  end;

begin
  with Cells[ACol,ARow]^ do
    if DrawTop or DrawLeft or DrawRight or DrawBottom then
    begin
      // ���߿�
      Canvas.Pen.Color := clBlack;
      Canvas.Pen.Width := LineWidth;
      Canvas.Pen.Style := PenStyle;
      BorderRect := TextRect;
      Inc(BorderRect.Top, LineWidth div 2 - 1);
      Inc(BorderRect.Left, LineWidth div 2 - 1);
      Dec(BorderRect.Right, LineWidth div 2);
      Dec(BorderRect.Bottom, LineWidth div 2);
      if DrawTop then
         DrawLine(Canvas, BorderRect.Left, BorderRect.Top, BorderRect.Right, BorderRect.Top);
      if DrawLeft then
         DrawLine(Canvas, BorderRect.Left, BorderRect.Top, BorderRect.Left, BorderRect.Bottom);
      if DrawBottom then
         DrawLine(Canvas, BorderRect.Left, BorderRect.Bottom, BorderRect.Right, BorderRect.Bottom);
      if DrawRight then
         DrawLine(Canvas, BorderRect.Right, BorderRect.Top, BorderRect.Right, BorderRect.Bottom);
    end;
  // ����ǻ��б�����(���б���������������Ҫ����ı�)
  if (ARow = 0) and (ACol <> 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := '����';
    Canvas.Font.Size := 10;
    Canvas.Font.Color := clBlack;
    Canvas.Font.Style := [];
    if (ACol >= FSelStart.x) and (ACol <= FSelEnd.X) and not (csDesigning in ComponentState) then
    begin
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := FFocusedTitleColor;
    end;
    DrawText(Canvas.Handle, PChar(ColTitle(ACol - 1)), -1, TextRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE)
  end
  // ����ǻ��б�����(���б���������������Ҫ����ı�)
  else if (ACol = 0) and (ARow <> 0) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := '����';
    Canvas.Font.Size := 10;
    Canvas.Font.Color := clBlack;
    Canvas.Font.Style := [];
    if (ARow >= FSelStart.y) and (ARow <= FSelEnd.y) and not (csDesigning in ComponentState) then
    begin
      Canvas.Font.Style := [fsBold];
      Canvas.Font.Color := FFocusedTitleColor;
    end;
    DrawText(Canvas.Handle, PChar(IntToStr(ARow)), -1, TextRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE)
  end
  // ����ǻ���������
  else
  begin
    InflateRect(TextRect, -4, -4);
    // �ѵ�ǰ�� Cell ���÷�Χ����
    IntersectClipRect(Canvas.Handle, TextRect.Left, TextRect.Top,
                      TextRect.Right, TextRect.Bottom);
    with Cells[ACol,ARow]^ do
    if ((ShowForeText) and (ForeText <> '')) or
       ((not ShowForeText) and (BackText <> '')) then
      begin
        // ʵ��������ı�
        if ShowForeText then
          TextToDraw := PChar(ForeText)
        else
          TextToDraw := PChar(BackText);
        // ��������
        Canvas.Font.Name := FontName;
        Canvas.Font.Size := FontSize;
        if (gdSelected in AState) and
           ((goRowSelect in Options) or (ACol <> FCurrent.X) or (ARow <> FCurrent.Y)) then
          Canvas.Font.Color := HighLightTextColor
        else
          Canvas.Font.Color := FontColor;
        Canvas.Font.Style := FontStyle;
        // �����ı������ʵ�ʿ��
        CalcTestRect;
        // �ı���������(��ֱ���к͵ײ�������Ҫ�ֹ�����)
        TextAlignMode := 0;
        case AlignMode of
          taTopLeft :    // �ı���������
            TextAlignMode := DT_TOP or DT_LEFT;
          taTop :        // �ı����ڶ�������
            TextAlignMode := DT_TOP or DT_CENTER;
          taTopRight :   // �ı���������
            TextAlignMode := DT_TOP or DT_RIGHT;
          taLeft :       // �ı�����������
            begin
              TextAlignMode := DT_LEFT;
              Inc(TextRect.Top, TestRect.Top);
            end;
          taCenter :     // �ı���������
            begin
              TextAlignMode := DT_CENTER;
              Inc(TextRect.Top, TestRect.Top);
            end;
          taRight :      // �ı������Ҳ�����
            begin
              TextAlignMode := DT_RIGHT;
              Inc(TextRect.Top, TestRect.Top);
            end;
          taBottomLeft :  // �ı���������
            begin
              TextAlignMode := DT_LEFT;
              TextRect.Top := TextRect.Bottom - TestHeight;
            end;
          taBottom :      // �ı����ڵײ�����
            begin
              TextAlignMode := DT_CENTER;
              TextRect.Top := TextRect.Bottom - TestHeight;
            end;
          taBottomRight : // �ı���������
            begin
              TextAlignMode := DT_RIGHT;
              TextRect.Top := TextRect.Bottom - TestHeight;
            end;
        end;
        if AutoWordBreak then
          TextAlignMode := TextAlignMode or DT_WORDBREAK;
        DrawText(Canvas.Handle, TextToDraw, -1, TextRect, TextAlignMode)
      end;
      // �ָ��� DrawCells �ļ���״̬
      RestoreClipRect(Canvas);
      SetClipRect(Canvas, ClipR);
    end;
  if Assigned(FOnDrawCell) then
  begin
    FOnDrawCell(Self, ACol, ARow, TextRect, AState);
  end;
end;

function TCustomEasyGrid.MouseCoord(X, Y: Integer): TGridCoord;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  Result := CalcCoordFromPoint(X, Y, DrawInfo);
  if Result.X < 0 then Result.Y := -1
  else if Result.Y < 0 then Result.X := -1;
end;

procedure TCustomEasyGrid.MoveColRow(ACol, ARow: Longint; MoveAnchor,
  Show: Boolean);
begin
  MoveCurrent(ACol, ARow, MoveAnchor, Show, True);
end;

function TCustomEasyGrid.SelectCell(ACol, ARow: Longint): Boolean;
begin
  Result := True;
  if Assigned(FOnSelectCell) then FOnSelectCell(Self, ACol, ARow, Result);
end;

procedure TCustomEasyGrid.SizeChanged(OldColCount, OldRowCount: Longint);
begin
end;

function TCustomEasyGrid.Sizing(X, Y: Integer): Boolean;
var
  DrawInfo: TEasyGridDrawInfo;
  State: TEasyGridState;
  Index: Longint;
  Pos, Ofs: Integer;
begin
  State := FGridState;
  if State = gsNormal then
  begin
    CalcDrawInfo(DrawInfo);
    CalcSizingState(X, Y, State, Index, Pos, Ofs, DrawInfo);
  end;
  Result := State <> gsNormal;
end;

procedure TCustomEasyGrid.TopLeftChanged;
begin
  if FEditorMode and (FInplaceEdit <> nil) then FInplaceEdit.UpdateLoc(CellRect(Col, Row));
  if Assigned(FOnTopLeftChanged) then FOnTopLeftChanged(Self);
end;

procedure FillDWord(var Dest; Count, Value: Integer); register;
asm
  XCHG  EDX, ECX
  PUSH  EDI
  MOV   EDI, EAX
  MOV   EAX, EDX
  REP   STOSD
  POP   EDI
end;

{ StackAlloc allocates a 'small' block of memory from the stack by
  decrementing SP.  This provides the allocation speed of a local variable,
  but the runtime size flexibility of heap allocated memory.  }
function StackAlloc(Size: Integer): Pointer; register;
asm
  POP   ECX          { return address }
  MOV   EDX, ESP
  ADD   EAX, 3
  AND   EAX, not 3   // round up to keep ESP dword aligned
  CMP   EAX, 4092
  JLE   @@2
@@1:
  SUB   ESP, 4092
  PUSH  EAX          { make sure we touch guard page, to grow stack }
  SUB   EAX, 4096
  JNS   @@1
  ADD   EAX, 4096
@@2:
  SUB   ESP, EAX
  MOV   EAX, ESP     { function result = low memory address of block }
  PUSH  EDX          { save original SP, for cleanup }
  MOV   EDX, ESP
  SUB   EDX, 4
  PUSH  EDX          { save current SP, for sanity check  (sp = [sp]) }
  PUSH  ECX          { return to caller }
end;

{ StackFree pops the memory allocated by StackAlloc off the stack.
- Calling StackFree is optional - SP will be restored when the calling routine
  exits, but it's a good idea to free the stack allocated memory ASAP anyway.
- StackFree must be called in the same stack context as StackAlloc - not in
  a subroutine or finally block.
- Multiple StackFree calls must occur in reverse order of their corresponding
  StackAlloc calls.
- Built-in sanity checks guarantee that an improper call to StackFree will not
  corrupt the stack. Worst case is that the stack block is not released until
  the calling routine exits. }
procedure StackFree(P: Pointer); register;
asm
  POP   ECX                     { return address }
  MOV   EDX, DWORD PTR [ESP]
  SUB   EAX, 8
  CMP   EDX, ESP                { sanity check #1 (SP = [SP]) }
  JNE   @@1
  CMP   EDX, EAX                { sanity check #2 (P = this stack block) }
  JNE   @@1
  MOV   ESP, DWORD PTR [ESP+4]  { restore previous SP  }
@@1:
  PUSH  ECX                     { return to caller }
end;

procedure TCustomEasyGrid.DrawLine(ACanvas: TCanvas; X1, Y1, X2, Y2: Integer);
begin
  ACanvas.MoveTo(X1, Y1);
  ACanvas.LineTo(X2, Y2);
end;

procedure TCustomEasyGrid.Paint;
var
  DrawInfo: TEasyGridDrawInfo;
  Sel: TGridRect;
  MergeRect: TGridRect;
  DrawRect, ClipR, IRect, FocusRect: TRect;
  PointsList, StrokeList: PIntArray;
  MaxStroke: Integer;
  MaxHorzExtent, MaxVertExtent: Integer;
  MaxHorzCell, MaxVertCell: Integer;
  MinHorzCell, MinVertCell: Integer;
  FrameFlags1, FrameFlags2: DWORD;

  procedure DrawLines(DoHorz, DoVert: Boolean; StartCol, StartRow, EndCol, EndRow: Longint;
    const CellBounds: array of Integer; OnColor, OffColor: TColor);
  // ************************************************************
  // ����˵��
  // DoHorz,DoVert                    ��ʾ�Ƿ�ˮƽ������ֱ��
  // StartCol,StartRow,EndCol,EndRow  ��ʾ���ߵķ�Χ( Grid ���� )
  // CellBounds                       ��ʾ���߷�Χ( �������� )
  // OnColor,OffColor                 ������ɫ
  // ************************************************************
  const
    FlatPenStyle = PS_Geometric or PS_Solid or PS_EndCap_Flat or PS_Join_Miter;

    procedure DrawAxisLines(const AxisInfo: TEasyGridAxisDrawInfo;
      MajorIndex: Integer; UseOnColor: Boolean);
    // ************************************************************
    // Horizontal lines:  MajorIndex = 1
    // Vertical lines:    MajorIndex = 0
    // ************************************************************
    var
      LogBrush: TLOGBRUSH;
      Cell, Index: Integer;
      Points: PIntArray;
      StartMajor, StopMajor, StartMinor, StopMinor: Integer;
      MayHaveMerge : Boolean;
      TopIndex: Integer;
      MergePoint: TPoint;

      function FindHorzMerge(ARow, StartIndex : Integer): TPoint;
      var
        I: Integer;
        AMergeRect: PGridRect;
      begin
        Result.x := -1;
        Result.y := -1;
        for i := StartIndex to EndCol do
        begin
          AMergeRect := Merges[i, ARow];
          if CellInMerge(i, ARow) and (ARow <> AMergeRect.Bottom) then
          begin
            Result.x := AMergeRect.Left;
            Result.y := AMergeRect.Right;
            Exit;
          end;
        end;
      end;

      function FindVertMerge(ACol, StartIndex : Integer): TPoint;
      var
        i: Integer;
        AMergeRect: PGridRect;
      begin
        Result.x := -1;
        Result.y := -1;
        for i := StartIndex to EndRow do
        begin
          AMergeRect := Merges[ACol, i];
          if CellInMerge(ACol, i) and (ACol <> AMergeRect.Right) then
            begin
              Result.x := AMergeRect.Top;
              Result.y := AMergeRect.Bottom;
              Exit;
            end;
        end;
      end;

    begin
      with Canvas, AxisInfo do
      begin
        Pen.Style := psSolid;
        Pen.Mode := pmCopy;
        if EffectiveLineWidth <> 0 then
        begin
          Pen.Width := FGridLineWidth;
          if UseOnColor then
            Pen.Color := OnColor
          else
            Pen.Color := OffColor;
          if Pen.Width > 1 then
          begin
            LogBrush.lbStyle := BS_Solid;
            LogBrush.lbColor := Pen.Color;
            LogBrush.lbHatch := 0;
            Pen.Handle := ExtCreatePen(FlatPenStyle, Pen.Width, LogBrush, 0, nil);
          end;
          if MajorIndex = 0 then
             Cell := StartCol   // ������
          else
             Cell := StartRow; // ������
          // ��һ���ߵ�λ��
          StartMajor := CellBounds[MajorIndex] + EffectiveLineWidth shr 1 +
            GetExtent(Cell);
          // ���һ���ߵ�λ��
          StopMajor := CellBounds[2 + MajorIndex] + EffectiveLineWidth;
          // �������
          StartMinor := CellBounds[MajorIndex xor 1];
          // �����յ�
          StopMinor := CellBounds[2 + (MajorIndex xor 1)];
          MayHaveMerge := False;
          // �����Ƿ���ܴ��ںϲ�����
          if ((StartMinor > DrawInfo.Vert.TitleBoundary) and (StartMajor > DrawInfo.Horz.TitleBoundary) or
              (StartMinor > DrawInfo.Horz.TitleBoundary) and (StartMajor > DrawInfo.Vert.TitleBoundary)) then
            MayHaveMerge := True;
          Points := PointsList;
          Index := 0;
          repeat
            if ((MajorIndex = 0) and (ColWidths[Cell] >= 0)) or
               ((MajorIndex = 1) and (RowHeights[Cell] >= 0)) then
            begin
              // �������
              Points^[Index + MajorIndex] := StartMajor;         { MoveTo }
              Points^[Index + (MajorIndex xor 1)] := StartMinor;
              Inc(Index, 2);
              // ������ܴ��ںϲ�����
              if MayHaveMerge then
              begin
                // ������
                if MajorIndex = 0 then
                begin
                  TopIndex := StartRow;
                  while TopIndex <= EndRow do
                    begin
                      MergePoint := FindVertMerge(Cell,TopIndex);
                      if MergePoint.x > 0 then   //Have Merge
                        begin
                          Points^[Index + MajorIndex] := StartMajor;         // LineTo
                          Points^[Index + (MajorIndex xor 1)] := CellRect(Cell, MergePoint.x).Top;
                          Inc(Index, 2);
                          Points^[Index + MajorIndex] := StartMajor;         // MoveTo
                          Points^[Index + (MajorIndex xor 1)] := CellRect(Cell, MergePoint.y).Bottom;
                          Inc(Index, 2);
                          TopIndex := MergePoint.y + 1;
                        end
                      else
                        Inc(TopIndex);
                    end;
                end
                // ������
                else
                begin
                  TopIndex := StartCol;
                  while TopIndex <= EndCol do
                    begin
                      MergePoint := FindHorzMerge(Cell,TopIndex);
                      if MergePoint.x > 0 then
                        begin
                          Points^[Index + MajorIndex] := StartMajor;         // LineTo
                          Points^[Index + (MajorIndex xor 1)] := CellRect(MergePoint.x, Cell).Left;
                          Inc(Index, 2);
                          Points^[Index + MajorIndex] := StartMajor;         // MoveTo
                          Points^[Index + (MajorIndex xor 1)] := CellRect(MergePoint.y, Cell).Right;
                          Inc(Index, 2);
                          TopIndex := MergePoint.y + 1;
                        end
                      else
                        Inc(TopIndex);
                    end;
                end;
              end;
              // �����յ�
              Points^[Index + MajorIndex] := StartMajor;         { LineTo }
              Points^[Index + (MajorIndex xor 1)] := StopMinor;
              Inc(Index, 2);
            end;
            Inc(Cell);
            Inc(StartMajor, GetExtent(Cell) + EffectiveLineWidth);
          until StartMajor > StopMajor;
          PolyPolyLine(Canvas.Handle, Points^, StrokeList^, Index shr 2);
        end;
      end;
    end;

  begin
    // ������յ���ͬ,����Ҫ����
    if (CellBounds[0] = CellBounds[2]) or (CellBounds[1] = CellBounds[3]) then Exit;
    // �ж��Ƿ���Ҫ�����ߵ�Ŀ����ʹ����������
    if not DoHorz then
    begin
      DrawAxisLines(DrawInfo.Vert, 1, DoHorz); // ��ˮƽ��
      DrawAxisLines(DrawInfo.Horz, 0, DoVert); // ����ֱ��
    end
    else
    begin
      DrawAxisLines(DrawInfo.Horz, 0, DoVert); // ����ֱ��
      DrawAxisLines(DrawInfo.Vert, 1, DoHorz); // ��ˮƽ��
    end;
  end;

  procedure DrawCells(DrawRegion: Integer; StartCol, StartRow, EndCol, EndRow: Longint;
    IncludeDrawState: TEasyGridDrawState);
  // ************************************************************
  // ����˵��
  // ACol,ARow                    ��ʼ�� Cell ��λ��( Grid ����)
  // StartX,StartY,StopX,StopY    �滭����ķ�Χ( �������� )
  // IncludeDrawState             ��ʾ�Ƿ��ڻ��ƹ̶���
  // ************************************************************
  var
    CurCol, CurRow: Longint;
    Where, Ctl3DRect: TRect;
    DrawState: TEasyGridDrawState;
    Focused: Boolean;

    // ���� DrawRegion ������÷�Χ�ͻ滭��Χ
    procedure CalcRegion;
    var
      i : Integer;
    begin
      With DrawInfo do
        case DrawRegion of
          1: // ������������
            begin
              ClipR := Rect(0, 0, Horz.TitleBoundary, Vert.TitleBoundary);
              DrawRect := ClipR;
            end;
          2: // �̶����б�����
            begin
              ClipR := Rect(Horz.TitleBoundary, 0, Horz.FixedBoundary,
                            Vert.TitleBoundary);
              DrawRect := ClipR;
            end;
          3: // �̶����б�����
            begin
              ClipR := Rect(0, Vert.TitleBoundary, Horz.TitleBoundary,
                            Vert.FixedBoundary);
              DrawRect := ClipR;
            end;
          4: // ����б�����
            begin
              ClipR := Rect(Horz.FixedBoundary, 0, MaxHorzExtent,
                            Vert.TitleBoundary);
              DrawRect := ClipR;
              Dec(DrawRect.Left, FColOffset);
              for i:=StartCol to LeftCol-1 do
                Dec(DrawRect.Left, Horz.GetExtent(i)+Horz.EffectiveLineWidth);
            end;
          5: // ����б�����
            begin
              ClipR := Rect(0, Vert.FixedBoundary, Horz.TitleBoundary,
                            MaxVertExtent);
              DrawRect := ClipR;
              for i:=StartRow to TopRow-1 do
                Dec(DrawRect.Top, Vert.GetExtent(i)+Vert.EffectiveLineWidth);
            end;
          6: // �̶���������
            begin
              ClipR := Rect(Horz.TitleBoundary, Vert.TitleBoundary,
                            Horz.FixedBoundary, Vert.FixedBoundary);
              DrawRect := ClipR;
            end;
          7: // �����̶���
            begin
              ClipR := Rect(Horz.FixedBoundary, Vert.TitleBoundary,
                            MaxHorzExtent,Vert.FixedBoundary);
              DrawRect := ClipR;
              Dec(DrawRect.Left, FColOffset);
              for i:=StartCol to LeftCol-1 do
                Dec(DrawRect.Left, Horz.GetExtent(i)+Horz.EffectiveLineWidth);
            end;
          8: // �󲿹̶���
            begin
              ClipR := Rect(Horz.TitleBoundary, Vert.FixedBoundary,
                            Horz.FixedBoundary,MaxVertExtent);
              DrawRect := ClipR;
              for i:=StartRow to TopRow-1 do
                Dec(DrawRect.Top, Vert.GetExtent(i)+Vert.EffectiveLineWidth);
            end;
          9: // �����
            begin
              ClipR := Rect(Horz.FixedBoundary, Vert.FixedBoundary,
                            MaxHorzExtent, MaxVertExtent);
              DrawRect := ClipR;
              Dec(DrawRect.Left, FColOffset);
              for i:=StartCol to LeftCol-1 do
                Dec(DrawRect.Left, Horz.GetExtent(i)+Horz.EffectiveLineWidth);
              for i:=StartRow to TopRow-1 do
                Dec(DrawRect.Top, Vert.GetExtent(i)+Vert.EffectiveLineWidth);
            end;
        end;
    end;

    function MergedExtent(AAxisDrawInfo: TEasyGridAxisDrawInfo; StartIndex, EndIndex : Integer) : Integer;
    var
      i : Integer;
    begin
      Result := 0;
      with AAxisDrawInfo do
      for i:=StartIndex to EndIndex do
        Inc(Result,GetExtent(i)+EffectiveLineWidth);
      Dec(Result,AAxisDrawInfo.EffectiveLineWidth);
    end;

  begin
    CalcRegion; // ������÷�Χ�ͻ滭��Χ
    SetClipRect(Canvas, ClipR);
    CurRow := StartRow;
    Where.Top := DrawRect.Top;
    // ˫������ѭ��(���к���)
    while (Where.Top < DrawRect.Bottom) and (CurRow <= EndRow) do
    begin
      CurCol := StartCol;
      Where.Left := DrawRect.Left;
      while (Where.Left < DrawRect.Right) and (CurCol <= EndCol) do
      begin
        MergeRect := Merges[CurCol,CurRow]^;
        Where.Right := Where.Left + MergedExtent(DrawInfo.Horz, CurCol, MergeRect.Right);
        Where.Bottom := Where.Top + MergedExtent(DrawInfo.Vert, CurRow, MergeRect.Bottom);
        // ������� Cell
        if (Where.Right > Where.Left) and (Where.Bottom > Where.Top) and
           (CurCol = MergeRect.Left) and
           (CurRow = MergeRect.Top) and
           InterSectRect(IRect,Where,ClipR) then
        begin
          DrawState := IncludeDrawState;
          // �����(�ֺ���)
          Focused := IsActiveControl;
          if Focused and (CurRow = Row) and (CurCol = Col)  then
             Include(DrawState, gdFocused);
          // ѡ���(����)
          if GridRectInterSects(MergeRect,Sel) then
             Include(DrawState, gdSelected);
          // �����������ڱ༭ Cell ʱ�������ػ�(���������һ����Ҫ�ػ�)
          if not (gdFocused in DrawState) or not (goEditing in Options) or
             not FEditorMode or (csDesigning in ComponentState) then
          begin
            // ********************************************************
            // �� Cell ����(�����Ҫ�Ļ�)
            if (DefaultDrawing or (csDesigning in ComponentState)) then
              with Canvas do
              begin
                // �жϻ�����ʹ�õ���ɫ
                if (gdSelected in DrawState) and
                   (([goDrawFocusSelected, goRowSelect] * Options <> [])) then
                begin
                  Brush.Color := FHighLightColor;
                  Font.Color  := FHighlightTextColor;
                end
                else if (CurCol = 0) or (CurRow = 0) then
                   Brush.Color := FTitleColor
                else if (gdSelected in DrawState) and
                        ((CurCol <> FCurrent.X) or (CurRow <> FCurrent.Y)) then
                   Brush.Color := FHighLightColor
                else
                   Brush.Color := Colors[CurCol, CurRow];
                FillRect(Where);
              end;

            // ********************************************************
            // �� Cell ����
            DrawCell(CurCol, CurRow, Where, ClipR, DrawState);

            // ********************************************************
            // �� Ctl3D Ч��
            FrameFlags1 := BF_BOTTOM or BF_RIGHT;
            FrameFlags2 := BF_TOP or BF_LEFT;
            if DefaultDrawing and (gdTitled in DrawState) and Ctl3D then
            begin
              Ctl3DRect := Where;
              DrawEdge(Canvas.Handle, Ctl3DRect, BDR_RAISEDINNER, FrameFlags1);
              DrawEdge(Canvas.Handle, Ctl3DRect, BDR_RAISEDINNER, FrameFlags2);
            end;
          end;
        end;
        Inc(Where.Left, ColWidths[CurCol]+DrawInfo.Horz.EffectiveLineWidth);
        Inc(CurCol);
      end;
      Inc(Where.Top, RowHeights[CurRow]+DrawInfo.Vert.EffectiveLineWidth);
      Inc(CurRow);
    end;
    RestoreClipRect(Canvas);
  end;

  function CalcMaxStroke : Integer;
  var
    i,j,HorzStroke,VertStroke : Integer;
  begin
    Result := Max(DrawInfo.Horz.LastFullVisibleCell - 1 ,
                  DrawInfo.Vert.LastFullVisibleCell - 1) + 4;
    i := MinHorzCell;
    VertStroke := 0;
    while i <= MaxHorzCell do
    begin
      j := MinVertCell;
      while j <= MaxVertCell do
        if i <> Merges[i,j].Right then
           begin
             Inc(VertStroke);
             j := Merges[i,j].Bottom + 1;
           end
        else
           Inc(j);
      Inc(i);
    end;
    j := MinVertCell;
    HorzStroke := 0;
    while j <= MaxVertCell do
    begin
      i := MinHorzCell;
      while i <= MaxHorzCell do
      if j <> Merges[i,j].Bottom then
         begin
           Inc(HorzStroke);
           i := Merges[i,j].Right + 1;
         end
      else
         Inc(i);
      Inc(j);
    end;
    Result := Result + Max(HorzStroke,VertStroke);
  end;

  function CalcMinHorzCell: Integer;
  var
    i: Integer;
  begin
    Result := Merges[LeftCol, TopRow].Left;
    for i:= 1 to MaxVertCell do
      Result := Min(Result, Merges[LeftCol, i].Left);
  end;

  function CalcMinVertCell: Integer;
  var
    i: Integer;
  begin
    Result := Merges[LeftCol, TopRow].Top;
    for i:= 1 to MaxHorzCell do
      Result := Min(Result, Merges[i, TopRow].Top);
  end;

  procedure DrawFocus;
  begin
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Mode := pmCopy;
    GridRectToScreenRect(Sel,FocusRect,True);
    ClipR := Rect(DrawInfo.Horz.FixedBoundary, DrawInfo.Vert.FixedBoundary,
                  DrawInfo.Horz.GridBoundary, DrawInfo.Vert.GridBoundary);
    SetClipRect(Canvas, ClipR);
    // �����Ҫ���ֽ����
    if (IsActiveControl or AlwaysDrawFocus) and (FGridCanCopyMove or FGridCanFill) then
    begin
      // ����ǹ����ѡ������
      if RegularRange(Selection) then
        begin
          Canvas.Pen.Width := 3;
          Canvas.Pen.Color := clBlack;
          with FocusRect do
          begin
            DrawLine(Canvas, Left, Top, Right - 3, Top);
            DrawLine(Canvas, Left, Top, Left, Bottom - 3);
            if Right - 6 > Left then
              DrawLine(Canvas, Left, Bottom - 2, Right - 7, Bottom - 2);
            if Bottom - 6 > Top then
              DrawLine(Canvas, Right - 2, Top, Right - 2, Bottom - 6);
            with Canvas do
            begin
              Pen.Width := 3;
              Pen.Color := clBlack;
              Rectangle(Right - 3, Bottom - 3, Right, Bottom);
              Pen.Width := 1;
              Pen.Color := clWhite;
            end;
            DrawLine(Canvas, Left+2,Top+2,Right-4,Top+2);
            DrawLine(Canvas, Left+2,Top+2,Left+2,Bottom-4);
            DrawLine(Canvas, Left+2,Bottom-4,Right+1,Bottom-4);
            DrawLine(Canvas, Right-4,Top+2,Right-4,Bottom+1);
          end;
        end
      else
        begin
          Canvas.Pen.Width := 1;
          Canvas.Pen.Color := clBlack;
          GridRectToScreenRect(Merges[FCurrent.X,FCurrent.Y]^, FocusRect, True);
          with FocusRect do
          begin
            Dec(FocusRect.Bottom,2);
            Dec(FocusRect.Right,2);
            DrawLine(Canvas, Left, Top, Right , Top);
            DrawLine(Canvas, Left, Top, Left, Bottom );
            DrawLine(Canvas, Left, Bottom, Right, Bottom);
            DrawLine(Canvas, Right, Top, Right, Bottom);
          end;
        end
    end
    else if RegularRange(Selection) then
    begin
      Dec(FocusRect.Bottom);
      Dec(FocusRect.Right);
      DrawFocusRect(Canvas.Handle, FocusRect);
    end;
  RestoreClipRect(Canvas);
  end;

begin
  CalcDrawInfo(DrawInfo);
  // ��������
  with DrawInfo do
  begin
    if (Horz.EffectiveLineWidth > 0) or (Vert.EffectiveLineWidth > 0) then
    begin
      // �������ʻ���
      MaxHorzExtent := Min(Width, Horz.GridBoundary);
      MaxVertExtent := Min(Height, Vert.GridBoundary);
      MaxHorzCell := Min(Horz.GridCellCount - 1, Horz.LastFullVisibleCell + 1);
      MaxVertCell := Min(Vert.GridCellCount - 1, Vert.LastFullVisibleCell + 1);
      MinHorzCell := CalcMinHorzCell;
      MinVertCell := CalcMinVertCell;
      MaxStroke := CalcMaxStroke;
      PointsList := StackAlloc(MaxStroke * sizeof(TPoint) * 2);
      StrokeList := StackAlloc(MaxStroke * sizeof(Integer));
      FillDWord(StrokeList^, MaxStroke, 2);

      // *****************************************************************
      // �����¾Ÿ������� :
      //     ���������������б������͹̶��н��������б������͹̶��н�������
      //     �б��������б�����������̶������й̶������й̶����������
      // *****************************************************************
      DrawLines(True, True, 0, 0, 0, 0, // ������������
        [0, 0, Horz.TitleBoundary, Vert.TitleBoundary], clBlack, clBlack);
      DrawLines(True, True, 1, 0, Horz.FixedCellCount, 0,               // �̶����б�����
        [Horz.TitleBoundary, 0, Horz.FixedBoundary, Vert.TitleBoundary], clBlack, clBlack);
      DrawLines(True, True, 0, 1, 0, Vert.FixedCellCount,               // �̶����б�����
        [0, Vert.TitleBoundary, Horz.TitleBoundary, Vert.FixedBoundary], clBlack, clBlack);
      DrawLines(True, True, Horz.FirstGridCell, 0, MaxHorzCell, 0,      // ����б�����
        [Horz.FixedBoundary, 0, MaxHorzExtent, Vert.TitleBoundary], clBlack, clBlack);
      DrawLines(True, True, 0, Vert.FirstGridCell, 0, MaxVertCell,      // ����б�����
        [0, Vert.FixedBoundary, Horz.TitleBoundary, MaxVertExtent], clBlack, clBlack);
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options, // �̶���������
        1, 1, Horz.FixedCellCount, Vert.FixedCellCount,
        [Horz.TitleBoundary, Vert.TitleBoundary, Horz.FixedBoundary, Vert.FixedBoundary], FixedLineColor, Color);
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options, // �����̶���
        LeftCol, 1, MaxHorzCell, Vert.FixedCellCount,
        [Horz.FixedBoundary, Vert.TitleBoundary, MaxHorzExtent,
        Vert.FixedBoundary], FixedLineColor, Color);
      DrawLines(goFixedHorzLine in Options, goFixedVertLine in Options, // �󲿹̶���
        1, TopRow, Horz.FixedCellCount, MaxVertCell,
        [Horz.TitleBoundary, Vert.FixedBoundary, Horz.FixedBoundary,
        MaxVertExtent], FixedLineColor, Color);
      DrawLines(goHorzLine in Options, goVertLine in Options,           // �����
        LeftCol, TopRow, MaxHorzCell, MaxVertCell,
        [Horz.FixedBoundary, Vert.FixedBoundary, MaxHorzExtent,
        MaxVertExtent], ClientLineColor, Color);

      StackFree(StrokeList);
      StackFree(PointsList);
    end;

    // *****************************************************************
    // �����¾Ÿ��������� :
    //     ���������������б������͹̶��н��������б������͹̶��н�������
    //     �б��������б�����������̶������й̶������й̶����������
    // *****************************************************************
    Sel := Selection;
    DrawCells(1, 0, 0, 0, 0,                             [gdTitled]); // ������������
    DrawCells(2, 1, 0, FixedCols, 0,                     [gdTitled]); // �̶����б�����
    DrawCells(3, 0, 1, 0, FixedRows,                     [gdTitled]); // �̶����б�����
    DrawCells(4, MinHorzCell, 0, MaxHorzCell, 0,         [gdTitled]); // ����б�����
    DrawCells(5, 0, MinVertCell, 0, MaxVertCell,         [gdTitled]); // ����б�����
    DrawCells(6, 1, 1, FixedCols, FixedRows,             [gdFixed] ); // �̶���������
    DrawCells(7, MinHorzCell, 1, MaxHorzCell, FixedRows, [gdFixed] ); // �����̶���
    DrawCells(8, 1, MinVertCell, FixedCols, MaxVertCell, [gdFixed] ); // �󲿹̶���
    DrawCells(9, MinHorzCell, MinVertCell, MaxHorzCell, MaxVertCell, []); // �����

    // �������
    if DefaultDrawing and not (csDesigning in ComponentState) and
      ([goEditing, goAlwaysShowEditor] * Options <>
      [goEditing, goAlwaysShowEditor]) and
      not (goRowSelect in Options) then DrawFocus;

    // ���հ���
    if Horz.GridBoundary < Horz.GridExtent then
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(Rect(Horz.GridBoundary, 0, Horz.GridExtent, Vert.GridBoundary));
    end;
    if Vert.GridBoundary < Vert.GridExtent then
    begin
      Canvas.Brush.Color := Color;
      Canvas.FillRect(Rect(0, Vert.GridBoundary, Horz.GridExtent, Vert.GridExtent));
    end;
  end;
end;

// ת����Ļ�������굽 Cell ����
function TCustomEasyGrid.CalcCoordFromPoint(X, Y: Integer;
  const DrawInfo: TEasyGridDrawInfo): TGridCoord;

  function DoCalc(const AxisInfo: TEasyGridAxisDrawInfo; N: Integer): Integer;
  var
    I, Start, Stop: Longint;
    Line: Integer;              // ��������
  begin
    with AxisInfo do
    begin
      if N < TitleBoundary then
      begin
        Start := 0;
        Stop :=  0;
        Line := 0;
      end
      else
      if N < FixedBoundary then // ����� Fixed ����
      begin
        Start := 1;
        Stop :=  FixedCellCount;
        Line := TitleBoundary;
      end
      else                      // �� Fixed ����
      begin
        Start := FirstGridCell;
        Stop := GridCellCount - 1;
        Line := FixedBoundary;
      end;
      for I := Start to Stop do // ����Ѱ��
      begin
        Inc(Line, GetExtent(I) + EffectiveLineWidth);
        if N < Line then
        begin
          Result := I;
          Exit;
        end;
      end;
      Result := Stop;
    end;
  end;

begin
  Result.X := DoCalc(DrawInfo.Horz, X);
  Result.Y := DoCalc(DrawInfo.Vert, Y);
end;

procedure TCustomEasyGrid.CalcDrawInfo(var DrawInfo: TEasyGridDrawInfo);
var
  NewWidth, NewHeight: Integer;
begin
  NewWidth := ClientWidth;
  NewHeight := ClientHeight;
  CalcDrawInfoXY(DrawInfo, NewWidth, NewHeight);
end;

procedure TCustomEasyGrid.CalcDrawInfoXY(var DrawInfo: TEasyGridDrawInfo;
  UseWidth, UseHeight: Integer);

  procedure CalcAxis(var AxisInfo: TEasyGridAxisDrawInfo; UseExtent: Integer;
                     StartCell : Integer);
  var
    i: Integer;
  begin
    with AxisInfo do
    begin
      GridExtent := UseExtent;
      GridBoundary := FixedBoundary;
      FullVisBoundary := FixedBoundary;
      LastFullVisibleCell := StartCell;
      for i := StartCell to GridCellCount - 1 do
      begin
        Inc(GridBoundary, GetExtent(i) + EffectiveLineWidth);
        if GridBoundary > (GridExtent + EffectiveLineWidth) then
        begin
          GridBoundary := GridExtent;
          Break;
        end;
        LastFullVisibleCell := i;
        FullVisBoundary := GridBoundary;
      end;
    end;
  end;

begin
  // ����̶���(��)��Ϣ
  CalcFixedInfo(DrawInfo);
  CalcAxis(DrawInfo.Horz, UseWidth,  LeftCol);
  CalcAxis(DrawInfo.Vert, UseHeight, TopRow);
end;

// ����̶���(��)��Ϣ
// ���� FixedBoundary, FixedCellCount, FirstGridCell, GridCellCount, GetExtent,
// ���� FixedBoundary ͨ���ۼӼ������, ����ͨ��������ڲ����õ�
procedure TCustomEasyGrid.CalcFixedInfo(var DrawInfo: TEasyGridDrawInfo);

  procedure CalcFixedAxis(var Axis: TEasyGridAxisDrawInfo; LineOptions: TEasyGridOptions;
    HaveTitle: Boolean; FixedCount, FirstCell, CellCount: Integer;
    GetExtentFunc: TGetExtentsFunc);
  var
    I: Integer;
  begin
    with Axis do
    begin
      if LineOptions * Options = [] then
        EffectiveLineWidth := 0
      else
        EffectiveLineWidth := GridLineWidth;

      if HaveTitle then
         TitleBoundary := GetExtentFunc(0) + EffectiveLineWidth
      else
         TitleBoundary := 0;

      FixedBoundary := TitleBoundary;
      for I := 1 to FixedCount do
        Inc(FixedBoundary, GetExtentFunc(I) + EffectiveLineWidth);

      FixedCellCount := FixedCount;
      FirstGridCell := FirstCell;
      GridCellCount := CellCount;
      GetExtent := GetExtentFunc;
    end;
  end;

begin
  CalcFixedAxis(DrawInfo.Horz, [goFixedVertLine, goVertLine],
                ShowRowTitle,FixedCols,LeftCol, ColCount, GetColWidths);
  CalcFixedAxis(DrawInfo.Vert, [goFixedHorzLine, goHorzLine],
                ShowColTitle,FixedRows,TopRow, RowCount, GetRowHeights);
end;

// �����Ӧĳһ Cell ���� TopLeft ֵ
function TCustomEasyGrid.CalcMaxTopLeft(const Coord: TGridCoord;
  const DrawInfo: TEasyGridDrawInfo): TGridCoord;

  function CalcMaxCell(const Axis: TEasyGridAxisDrawInfo; Start: Integer): Integer;
  var
    Line: Integer;
    I, Extent: Longint;
  begin
    Result := Start;
    with Axis do
    begin
      Line := GridExtent + EffectiveLineWidth;
      for I := Start downto FixedCellCount+1 do
      begin
        Extent := GetExtent(I);
        Dec(Line, Extent);
        Dec(Line, EffectiveLineWidth);
        if Line < FixedBoundary then Break;
        if Extent > 0 then Result := I;
      end;
    end;
  end;

begin
  Result.X := CalcMaxCell(DrawInfo.Horz, Coord.X);
  Result.Y := CalcMaxCell(DrawInfo.Vert, Coord.Y);
end;

// *************************************************
// �������ѡ��Χ
function TCustomEasyGrid.CalcMaxRange(StartCell,EnteredCell: TGridCoord) : TGridRect;
var
  i: Integer;
  EnteredRange, OldRange: TGridRect;
  MergeRect: PGridRect;
begin
  // ��ǰ���������������Χ
  EnteredRange := TGridRect(Merges[EnteredCell.X,EnteredCell.Y]^);
  // �����״η�Χ
  FillChar(OldRange, SizeOf(OldRange), 0);
  MergeRect := Merges[StartCell.X,StartCell.Y];
  Result.Top  :=   Min(MergeRect.Top, EnteredRange.Top);
  Result.Left :=   Min(MergeRect.Left, EnteredRange.Left);
  Result.Bottom := Max(MergeRect.Bottom, EnteredRange.Bottom);
  Result.Right  := Max(MergeRect.Right, EnteredRange.Right);
  // ���β���ÿ��Cell,�õ����Χ,ֱ����Χ��������
  while ((Result.Top <> OldRange.Top) or
         (Result.Left <> OldRange.Left) or
         (Result.Bottom <> OldRange.Bottom) or
         (Result.Right <> OldRange.Right)) do
  begin
    OldRange := Result;
    for i:=OldRange.Left to OldRange.Right do
    begin
      Result.Top  :=   Min(Result.Top,Merges[i,OldRange.Top].Top);
      Result.Bottom := Max(Result.Bottom, Merges[i,OldRange.Bottom].Bottom);
    end;
    for i:=OldRange.Top to OldRange.Bottom do
    begin
      Result.Left  := Min(Result.Left,Merges[OldRange.Left, i].Left);
      Result.Right := Max(Result.Right, Merges[OldRange.Right, i].Right);
    end;
  end;
end;
// *************************************************



// ���� ColSizing,RowSizing ״̬�� Sizing ��Ϣ
// SizingIndex : ��ǰ�� Sizing ����(��)��
// SizingPos   : ��ǰ�� Sizing ����(��)�ı߽�����
// SizingOfs   : ��ǰ�� Sizing ����(��)�ı߽�����������λ�ò�

procedure TCustomEasyGrid.CalcSizingState(X, Y: Integer; var State: TEasyGridState;
  var Index: Longint; var SizingPos, SizingOfs: Integer;
  var DrawInfo: TEasyGridDrawInfo);
var
  EffectiveOptions: TEasyGridOptions;
  CellHit: TGridCoord;
  AMergeRect: PGridRect;
  ScreenRect: TRect;

  // �� Index ��ʼѰ�ҵ�һ����������(��)
  function GetLastZeroExtent(AxisInfo:TEasyGridAxisDrawInfo;
           index,LastCell: Integer): Integer;
  var
    i : Integer;
  begin
    Result := index;
    for i := index to LastCell do
    with AxisInfo do
      if GetExtent(i)>=0 then
         begin
           Result := i - 1;
           Exit;
         end;
  end;

  procedure CalcAxisState(const AxisInfo: TEasyGridAxisDrawInfo; Pos: Integer;
    NewState: TEasyGridState);
  var
    I, Line, Back, Range : Integer;
  begin
    with AxisInfo do
    begin
      Range := EffectiveLineWidth; // ���� Sizing �ķ�Χ
      Back := 0;
      // ����߿�С�� 7 ,��������չ,ʹ���� Sizing �ķ�Χ��С�� 7
      if Range < 7 then
         begin
           Range := 7;
           Back := (Range - EffectiveLineWidth) shr 1;
         end;

      // ���ƺϲ�������ڲ����� Sizing ,���Ǳ߿���� Sizing
      if (NewState = gsColSizing) and
         (CellInMerge(CellHit.X, CellHit.Y)) and
         (AMergeRect.Left <> AMergeRect.Right) and
         (((CellHit.X > AMergeRect.Left) and (CellHit.X < AMergeRect.Right)) or
          (CellHit.X = AMergeRect.Left) and (X-ScreenRect.Left > Back) or
          (CellHit.X = AMergeRect.Right) and (ScreenRect.Right-X > Back)) then Exit;
      if (NewState = gsRowSizing) and
         (CellInMerge(CellHit.X, CellHit.Y)) and
         (AMergeRect.Top <> AMergeRect.Bottom) and
         (((CellHit.Y > AMergeRect.Top) and (CellHit.Y < AMergeRect.Bottom)) or
          (CellHit.Y = AMergeRect.Top) and (Y-ScreenRect.Top > Back) or
          (CellHit.Y = AMergeRect.Bottom) and (ScreenRect.Bottom-Y > Back)) then Exit;

      Line := TitleBoundary;
      i := 1;
      while i < GridCellCount do
      begin
        if (i > FixedCellCount) and
           (i < FirstGridCell) then i := FirstGridCell;
        Inc(Line, GetExtent(i));
        if Line > GridBoundary then Break;
        // ��� Pos ���� Range ��Χ��
        if (Pos >= Line - Back) and (Pos <= Line - Back + Range) then
        begin
          Index := i;
          // �������� Line �ұ�,����ܴ���������
          if (Pos > Line) and (GetExtent(i+1)<0) then
             Index:=GetLastZeroExtent(AxisInfo,i+1,GridCellCount-1);
          // ������ Sizing
          if (NewState = gsColSizing) and (not ColCanSizes[Index]) or
             (NewState = gsRowSizing) and (not RowCanSizes[Index]) then
             Exit;
          // ���� Sizing
          SizingPos := Line;
          SizingOfs := Line - Pos;
          State := NewState;
          Exit;
        end;
        // ��� Pos û������ Range ��Χ��,�������һ��(��)
        Inc(Line, EffectiveLineWidth);
        Inc(i);
      end;

      if (GridBoundary = GridExtent) and (Pos >= GridExtent - Back)
        and (Pos <= GridExtent) then
      begin
        SizingPos := GridExtent;
        SizingOfs := GridExtent - Pos;
        Index := LastFullVisibleCell + 1;
        if NewState = gsColSizing then
           if not ColCanSizes[Index] then Exit
        else
           if not RowCanSizes[Index] then Exit;
        State := NewState;
      end;
    end;
  end;

begin
  State := gsNormal;
  if (X < 0) or (Y < 0) then Exit;
  Index := -1;
  EffectiveOptions := Options;
  if csDesigning in ComponentState then
    EffectiveOptions := EffectiveOptions + DesignOptionsBoost;
  // ������� ColSizing �� RowSizing
  if [goColSizing, goRowSizing] * EffectiveOptions <> [] then
    with DrawInfo do
    begin
      Vert.GridExtent := ClientHeight;
      Horz.GridExtent := ClientWidth;
      CellHit := CalcCoordFromPoint(X, Y, DrawInfo);
      Restrict(CellHit, 0, 0, ColCount - 1, RowCount - 1);
      // ��ѡ�����ڻ��ںϲ��������� Size
      AMergeRect := Merges[CellHit.X,CellHit.Y];
      GridRectToScreenRect(AMergeRect^, ScreenRect, True);
      if PointInGridRect(CellHit.X,CellHit.Y,Selection) then Exit;
      if (X >= Horz.TitleBoundary) and (goColSizing in EffectiveOptions) then
      begin
        // �����곬���̶������� Sizing
        if (ClientSizeable) or (Y <= Vert.Fixedboundary) then
          CalcAxisState(Horz, X, gsColSizing);
      end;
      if (Y >= Vert.TitleBoundary) and (goRowSizing in EffectiveOptions) then
      begin
        // �����곬���̶������� Sizing
        if (ClientSizeable) or (X <= Horz.Fixedboundary) then
          CalcAxisState(Vert, Y, gsRowSizing);
      end;
    end;
end;

procedure TCustomEasyGrid.ChangeSize(NewColCount, NewRowCount: Longint);
var
  OldColCount, OldRowCount: Longint;
  OldDrawInfo: TEasyGridDrawInfo;
  NewTopLeft: TGridCoord;

  procedure MinRedraw(const OldInfo, NewInfo: TEasyGridAxisDrawInfo; Axis: Integer);
  var
    R: TRect;
    First: Integer;
  begin
    First := Min(OldInfo.LastFullVisibleCell, NewInfo.LastFullVisibleCell);
    R := CellRect(First and not Axis, First and Axis);
    R.Bottom := Height;
    R.Right := Width;
    if AutoUpdate then
      Windows.InvalidateRect(Handle, @R, False);
  end;

  procedure DoChange;
  var
    Coord: TGridCoord;
    NewDrawInfo: TEasyGridDrawInfo;
  begin
    if FColWidths <> nil then
    begin
      // �����µ� ColCount �޸� FColWidth,FTabStops ����(ָ��)
      UpdateExtents(FColWidths, ColCount, DefaultColWidth);
      UpdateExtents(FColCanSizes, ColCount, Integer(True));
      UpdateExtents(FTabStops, ColCount, Integer(True));
    end;
    if FRowHeights <> nil then
    begin
      UpdateExtents(FRowCanSizes, RowCount, Integer(True));
      UpdateExtents(FRowHeights, RowCount, DefaultRowHeight);
    end;
    Coord := FCurrent;
    // �����С���к�,��ǰѡ�е� Cell �����˱߽�,���ƶ������һ��(��)
    if Row >= FRowCount then Coord.Y := FRowCount - 1;
    if Col >= FColCount then Coord.X := FColCount - 1;
    if (FCurrent.X <> Coord.X) or (FCurrent.Y <> Coord.Y) then
      MoveCurrent(Coord.X, Coord.Y, True, True, True);
    if (FAnchor.X <> Coord.X) or (FAnchor.Y <> Coord.Y) then
      MoveAnchor(Coord);
    if (goRowSelect in Options) then
    begin
      FSelStart.X := FFixedCols + 1;
      FSelEnd.X := FColCount - 1;
    end;
    if VirtualView or
      (LeftCol <> OldDrawInfo.Horz.FirstGridCell) or
      (TopRow <> OldDrawInfo.Vert.FirstGridCell) then
      InvalidateGrid
    else if HandleAllocated then
    begin
      CalcDrawInfo(NewDrawInfo);
      MinRedraw(OldDrawInfo.Horz, NewDrawInfo.Horz, 0);
      MinRedraw(OldDrawInfo.Vert, NewDrawInfo.Vert, -1);
    end;
    UpdateScrollRange;
    SizeChanged(OldColCount, OldRowCount);
  end;

begin
  if HandleAllocated then
    CalcDrawInfo(OldDrawInfo);
  OldColCount := FColCount;
  OldRowCount := FRowCount;
  FColCount := NewColCount;
  FRowCount := NewRowCount;
  // ����ָ��������(��)ȫΪ Fixed
  if FixedCols+1 >= NewColCount then FFixedCols := NewColCount - 2;
  if FixedRows+1 >= NewRowCount then FFixedRows := NewRowCount - 2;
  // ��ֹ TopLeft ����
  if (NewRowCount < OldRowCount) or (NewColCount < OldColCount) then
  begin
    CalcDrawInfo(OldDrawInfo);
    NewTopLeft := CalcMaxTopLeft(GridCoord(FColCount-1, FRowCount-1), OldDrawInfo);
    FTopLeft.X := Min(NewTopLeft.X, FTopLeft.X);
    FTopLeft.Y := Min(NewTopLeft.Y, FTopLeft.Y);
  end;
  try
    DoChange;
  except
    { Could not change size so try to clean up by setting the size back }
    FColCount := OldColCount;
    FRowCount := OldRowCount;
    DoChange;
    raise;
  end;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.ClampInView(const Coord: TGridCoord; IsMouseMove: Boolean);
var
  DrawInfo: TEasyGridDrawInfo;
  MaxTopLeft: TGridCoord;
  OldTopLeft: TGridCoord;
begin
  if not HandleAllocated then Exit;
  CalcDrawInfo(DrawInfo);
  with DrawInfo, Coord do
  begin
    if not IsMouseMove then
    begin
      // �������δ��ȫ��ʾ����ʾ�������������,������ȫ��ʾ
      if (X > Horz.LastFullVisibleCell) or
         (Y > Vert.LastFullVisibleCell) or
         ((X < LeftCol) and (LeftCol <> FixedCols+1)) or
         ((Y < TopRow) and (TopRow <> FixedRows+1)) then
      begin
        OldTopLeft := FTopLeft;
        MaxTopLeft := CalcMaxTopLeft(Coord, DrawInfo);
        Update;
        if (X < LeftCol) and (LeftCol <> FixedCols+1) then FTopLeft.X := X
        else if X > Horz.LastFullVisibleCell then FTopLeft.X := MaxTopLeft.X;
        if (Y < TopRow) and (TopRow <> FixedRows+1) then FTopLeft.Y := Y
        else if Y > Vert.LastFullVisibleCell then FTopLeft.Y := MaxTopLeft.Y;
        TopLeftMoved(OldTopLeft);
      end;
    end
    else
    begin
      if (X > Horz.LastFullVisibleCell) or (Y > Vert.LastFullVisibleCell) then
      begin
        OldTopLeft := FTopLeft;
        MaxTopLeft := CalcMaxTopLeft(Coord, DrawInfo);
        Update;
        if X > Horz.LastFullVisibleCell then FTopLeft.X := MaxTopLeft.X;
        if Y > Vert.LastFullVisibleCell then FTopLeft.Y := MaxTopLeft.Y;
        TopLeftMoved(OldTopLeft);
      end;
    end;
  end;
end;

procedure TCustomEasyGrid.DrawCopyMoveRect(const DrawInfo: TEasyGridDrawInfo);
var
  ClipR, CopyMoveRect: TRect;
  CopyMoveGridRect: TGridRect;
begin
  CopyMoveGridRect := FCopyMoveRect;
  OffsetRect(TRect(CopyMoveGridRect), FCopyMoveOffset.X, FCopyMoveOffset.Y);
  GridRectToScreenRect(CopyMoveGridRect,CopyMoveRect,True);
  Dec(CopyMoveRect.Right);
  Dec(CopyMoveRect.Bottom);
  ClipR := Rect(DrawInfo.Horz.FixedBoundary,
                DrawInfo.Vert.FixedBoundary,
                Width, Height);
  SetClipRect(Canvas, ClipR);
  Canvas.DrawFocusRect(CopyMoveRect);
  RestoreClipRect(Canvas);
end;

procedure TCustomEasyGrid.DrawFillRect(const DrawInfo: TEasyGridDrawInfo);
var
  ClipR, ARect: TRect;
  AGridRect: TGridRect;
begin
  AGridRect := FFillRect;
  if FFillOffset.X < 0 then  // �������
    Inc(AGridRect.Left, FFillOffset.X)
  else
    Inc(AGridRect.Right, FFillOffset.X);
  if FFillOffset.Y < 0 then  // �������
    Inc(AGridRect.Top, FFillOffset.Y)
  else
    Inc(AGridRect.Bottom, FFillOffset.Y);
  AGridRect := GridRect(AGridRect.TopLeft, AGridRect.BottomRight);
  GridRectToScreenRect(AGridRect,ARect,True);
  Dec(ARect.Right);
  Dec(ARect.Bottom);
  ClipR := Rect(DrawInfo.Horz.FixedBoundary,
                DrawInfo.Vert.FixedBoundary,
                Width, Height);
  SetClipRect(Canvas, ClipR);
  Canvas.DrawFocusRect(ARect);
  RestoreClipRect(Canvas);
end;

procedure TCustomEasyGrid.DrawSizingLine(const DrawInfo: TEasyGridDrawInfo);
var
  OldPen: TPen;
begin
  OldPen := TPen.Create;
  try
    with Canvas, DrawInfo do
    begin
      OldPen.Assign(Pen); // ����ԭ���Ļ���
      Pen.Style := psDot;
      Pen.Mode := pmXor;
      Pen.Width := 1;
      Pen.Color := clBlack;
      try
        if FGridState = gsRowSizing then
           DrawLine(Canvas, 0,FSizingPos,Horz.GridBoundary,FSizingPos)
        else
           DrawLine(Canvas, FSizingPos,0,FSizingPos,Vert.GridBoundary);
      finally
        Pen := OldPen;
      end;
    end;
  finally
    OldPen.Free;
  end;
end;

procedure TCustomEasyGrid.FocusCell(ACol, ARow: Longint; MoveAnchor: Boolean);
begin
  if (ACol = FCurrent.X) and (ARow = FCurrent.Y) then Exit;
  MoveCurrent(ACol, ARow, MoveAnchor, True, True);
  UpdateEdit;
  Click;
end;

procedure TCustomEasyGrid.GridRectToScreenRect(GridRect: TGridRect;
  var ScreenRect: TRect; IncludeLine: Boolean);

  function LinePos(const Flag: Integer;
           const AxisInfo: TEasyGridAxisDrawInfo; Line: Integer): Integer;
  var
    Start, i: Longint;
  begin
    with AxisInfo do
    begin
      Result := 0;
      if Line < 1 then
        Start := 0
      else if Line <= FixedCellCount then
        begin
          Result := TitleBoundary;
          Start := 1;
        end
      else
        begin
          Result := FixedBoundary;
          if (Flag = 0) then
            Dec(Result, FColOffset);
          Start := FirstGridCell;
          if (FirstGridCell > FixedCellCount + 1) then
          begin
            Dec(Start, FirstGridCell - (FixedCellCount + 1));
            for i:=Start to FirstGridCell-1 do
              Dec(Result, GetExtent(i)+EffectiveLineWidth);
          end;
        end;
      i := Start;
      while i < Line do
      begin
        Inc(Result, GetExtent(i) + EffectiveLineWidth);
        {
        if Result > GridExtent then
        begin
          Result := 0;
          Exit;
        end;
        }
        Inc(i);
      end;
    end;
  end;

  procedure CalcAxis(const Flag: Integer; const AxisInfo: TEasyGridAxisDrawInfo;
    GridRectMin, GridRectMax: Integer;
    var ScreenRectMin, ScreenRectMax: Integer);
  begin
    with AxisInfo do
    begin
    {
      // ����ұ�(�±�)���������ӱ߽�
      if GridRectMax > LastFullVisibleCell then
      begin
        // ���ұ�(�±�)���������ӱ߽�
        GridRectMax := LastFullVisibleCell;
        // ��������ӱ߽�֮�⻹�� Cell
        if GridRectMax < GridCellCount - 1 then Inc(GridRectMax);
        if LinePos(Flag, AxisInfo, GridRectMax) = 0 then
          Dec(GridRectMax);
      end;
    }
      ScreenRectMin := LinePos(Flag, AxisInfo, GridRectMin);
      ScreenRectMax := LinePos(Flag, AxisInfo, GridRectMax);
      Inc(ScreenRectMax, GetExtent(GridRectMax));
    {
      if ScreenRectMax = 0 then
        ScreenRectMax := ScreenRectMin + GetExtent(GridRectMin)
      else
        Inc(ScreenRectMax, GetExtent(GridRectMax));
      if ScreenRectMax > GridExtent then
        ScreenRectMax := GridExtent;
    }
      if IncludeLine then Inc(ScreenRectMax, EffectiveLineWidth);
    end;
  end;

var
  DrawInfo: TEasyGridDrawInfo;
begin
  FillChar(ScreenRect, SizeOf(ScreenRect), 0);
  if (GridRect.Left > GridRect.Right) or (GridRect.Top > GridRect.Bottom) then
    Exit;
  CalcDrawInfo(DrawInfo);
  with DrawInfo do
  begin
    //if GridRect.Left > Horz.LastFullVisibleCell + 1 then Exit;
    //if GridRect.Top  > Vert.LastFullVisibleCell + 1 then Exit;

    CalcAxis(0, Horz, GridRect.Left, GridRect.Right, ScreenRect.Left, ScreenRect.Right);
    CalcAxis(1, Vert, GridRect.Top, GridRect.Bottom, ScreenRect.Top,  ScreenRect.Bottom);
  end;
end;

procedure TCustomEasyGrid.InvalidateCell(ACol, ARow: Longint);
var
  Rect: TGridRect;
begin
  Rect.Top := ARow;
  Rect.Left := ACol;
  Rect.Bottom := ARow;
  Rect.Right := ACol;
  InvalidateRect(Rect);
end;

procedure TCustomEasyGrid.InvalidateCol(ACol: Longint);
var
  Rect: TGridRect;
begin
  if not HandleAllocated then Exit;
  Rect.Top := 0;
  Rect.Left := ACol;
  Rect.Bottom := VisibleRowCount+1;
  Rect.Right := ACol;
  InvalidateRect(Rect);
end;

procedure TCustomEasyGrid.InvalidateRow(ARow: Longint);
var
  Rect: TGridRect;
begin
  if not HandleAllocated then Exit;
  Rect.Top := ARow;
  Rect.Left := 0;
  Rect.Bottom := ARow;
  Rect.Right := VisibleColCount + 1;
  InvalidateRect(Rect);
end;

procedure TCustomEasyGrid.InvalidateGrid;
begin
  if AutoUpdate then
    Invalidate;
end;

procedure TCustomEasyGrid.InvalidateRect(ARect: TGridRect);
var
  InvalidRect: TRect;
begin
  if not HandleAllocated then Exit;
  GridRectToScreenRect(ARect, InvalidRect, True);
  InflateRect(InvalidRect,3,3);
  Windows.InvalidateRect(Handle, @InvalidRect, False);
  if AutoUpdate then
    UpdateWindow(Handle);
end;

procedure TCustomEasyGrid.ModifyScrollBar(ScrollBar, ScrollCode, Pos: Cardinal;
  UseRightToLeft: Boolean);
var
  NewTopLeft, MaxTopLeft: TGridCoord;
  DrawInfo: TEasyGridDrawInfo;
  RTLFactor: Integer;

  function Min: Longint;
  begin
    if ScrollBar = SB_HORZ then Result := FixedCols + 1
    else Result := FixedRows + 1;
  end;

  function Max: Longint;
  begin
    if ScrollBar = SB_HORZ then Result := MaxTopLeft.X
    else Result := MaxTopLeft.Y;
  end;

  function PageUp: Longint;
  var
    MaxTopLeft: TGridCoord;
  begin
    MaxTopLeft := CalcMaxTopLeft(FTopLeft, DrawInfo);
    if ScrollBar = SB_HORZ then
      Result := FTopLeft.X - MaxTopLeft.X else
      Result := FTopLeft.Y - MaxTopLeft.Y;
    if Result < 1 then Result := 1;
  end;

  function PageDown: Longint;
  var
    DrawInfo: TEasyGridDrawInfo;
  begin
    CalcDrawInfo(DrawInfo);
    with DrawInfo do
      if ScrollBar = SB_HORZ then
        Result := Horz.LastFullVisibleCell - FTopLeft.X else
        Result := Vert.LastFullVisibleCell - FTopLeft.Y;
    if Result < 1 then Result := 1;
  end;

  function CalcScrollBar(Value, ARTLFactor: Longint): Longint;
  begin
    Result := Value;
    case ScrollCode of
      SB_LINEUP:
        Dec(Result, ARTLFactor);
      SB_LINEDOWN:
        Inc(Result, ARTLFactor);
      SB_PAGEUP:
        Dec(Result, PageUp * ARTLFactor);
      SB_PAGEDOWN:
        Inc(Result, PageDown * ARTLFactor);
      SB_THUMBPOSITION, SB_THUMBTRACK:
        if (goThumbTracking in Options) or (ScrollCode = SB_THUMBPOSITION) then
        begin
          Result := Min + LongMulDiv(Pos, Max - Min, MaxShortInt);
        end;
      SB_BOTTOM:
        Result := Max;
      SB_TOP:
        Result := Min;
    end;
  end;

  // ��ֻ��һ��ʱ,��һ�еķ�Χ��������Ϊ��λ����(ͨ���� Cell Ϊ��λ)
  procedure ModifyPixelScrollBar(Code, Pos: Cardinal);
  var
    NewOffset: Integer;
    OldOffset: Integer;
    R: TGridRect;
    GridSpace, ColWidth: Integer;
  begin
    NewOffset := FColOffset;
    ColWidth := ColWidths[DrawInfo.Horz.FirstGridCell];
    GridSpace := ClientWidth - DrawInfo.Horz.FixedBoundary;
    case Code of
      SB_LINEUP: Dec(NewOffset, Canvas.TextWidth('0') * RTLFactor);
      SB_LINEDOWN: Inc(NewOffset, Canvas.TextWidth('0') * RTLFactor);
      SB_PAGEUP: Dec(NewOffset, GridSpace * RTLFactor);
      SB_PAGEDOWN: Inc(NewOffset, GridSpace * RTLFactor);
      SB_THUMBPOSITION,
      SB_THUMBTRACK:
        if (goThumbTracking in Options) or (Code = SB_THUMBPOSITION) then
        begin
          NewOffset := Pos
        end;
      SB_BOTTOM: NewOffset := 0;
      SB_TOP: NewOffset := ColWidth - GridSpace;
    end;
    if NewOffset < 0 then
      NewOffset := 0
    else if NewOffset >= ColWidth - GridSpace then
      NewOffset := ColWidth - GridSpace;
    if NewOffset <> FColOffset then
    begin
      OldOffset := FColOffset;
      FColOffset := NewOffset;
      ScrollData(OldOffset - NewOffset, 0);
      FillChar(R, SizeOf(R), 0);
      R.Left := 1;
      R.Right := 1;
      R.Bottom := FixedRows;
      InvalidateRect(R);
      Update;
      UpdateScrollPos;
    end;
  end;

begin
  RTLFactor := 1;
  HideEditor;
  // ���ý���
  if Visible and CanFocus and TabStop and not (csDesigning in ComponentState) then
    SetFocus;
  CalcDrawInfo(DrawInfo);
  // ��������Ϊ 1 �����(�� Title ��)
  if (ScrollBar = SB_HORZ) and (ColCount = 2) then
  begin
    ModifyPixelScrollBar(ScrollCode, Pos);
    Exit;
  end;
  // ������ܵ�������Ͻ� Cell ����
  MaxTopLeft.X := ColCount - 1;
  MaxTopLeft.Y := RowCount - 1;
  MaxTopLeft := CalcMaxTopLeft(MaxTopLeft, DrawInfo);
  // �����µ����Ͻ� Cell ����
  NewTopLeft := FTopLeft;
  if ScrollBar = SB_HORZ then
    repeat
      NewTopLeft.X := CalcScrollBar(NewTopLeft.X, RTLFactor);
    until (NewTopLeft.X <= FixedCols+1) or (NewTopLeft.X >= MaxTopLeft.X)
      or (ColWidths[NewTopLeft.X] > 0)  // �������߽粢�������ص���
  else
    repeat
      NewTopLeft.Y := CalcScrollBar(NewTopLeft.Y, 1);
    until (NewTopLeft.Y <= FixedRows+1) or (NewTopLeft.Y >= MaxTopLeft.Y)
      or (RowHeights[NewTopLeft.Y] > 0);// �������߽粢�������ص���
  // ������� TopLeft
  NewTopLeft.X := Math.Max(FixedCols+1, Math.Min(MaxTopLeft.X, NewTopLeft.X));
  NewTopLeft.Y := Math.Max(FixedRows+1, Math.Min(MaxTopLeft.Y, NewTopLeft.Y));
  // �����µ����Ͻ� Cell ����
  if (NewTopLeft.X <> FTopLeft.X) or (NewTopLeft.Y <> FTopLeft.Y) then
    MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
end;

procedure TCustomEasyGrid.MoveAnchor(const NewAnchor: TGridCoord; MoveSel: Boolean = True);
begin
  if [goRangeSelect] * Options = [goRangeSelect] then
  begin
    FAnchor := NewAnchor;
    if goRowSelect in Options then FAnchor.X := ColCount - 1;
    if MoveSel then
    begin
      FSelStart := GridRect(FCurrent, FAnchor).TopLeft;
      FSelEnd := GridRect(FCurrent, FAnchor).BottomRight;
    end;
  end
  else
    MoveCurrent(NewAnchor.X, NewAnchor.Y, True, True, True);
end;

procedure TCustomEasyGrid.MoveCurrent(ACol, ARow: Longint; MoveAnchor,
  Show, TopLeftChange: Boolean);

  function IsNewTopLeft: Boolean;
  begin
    Result := False;
    if ((FCurrent.X < LeftCol) and (LeftCol <> FixedCols)) or
       ((FCurrent.Y < TopRow) and (TopRow <> FixedRows)) then
      Result := True;
  end;

var
  SaveAutoUpdate: Boolean;
  NewSelStart: TGridCoord;
begin
  // ���������
  if (ACol < 0) or (ARow < 0) or (ACol >= ColCount) or (ARow >= RowCount) then
    InvalidOp(SIndexOutOfRange);
  // �������ѡ�� Cell
  if SelectCell(ACol, ARow) then
  begin
    FCurrent.X := ACol;
    FCurrent.Y := ARow;
    if not (goAlwaysShowEditor in Options) then HideEditor;
    if MoveAnchor or not (goRangeSelect in Options) then
    begin
      FAnchor.X := Merges[FCurrent.X,FCurrent.Y].Right;
      FAnchor.Y := Merges[FCurrent.X,FCurrent.Y].Bottom;
      if goRowSelect in Options then FAnchor.X := ColCount - 1;
    end;
    if Show and TopLeftChange then
       ClampInView(FCurrent, False);
    SaveAutoUpdate := FAutoUpdate;
    FAutoUpdate := False;
    InvalidateRect(GridRect(FCurrent, FAnchor));
    FAutoUpdate := SaveAutoUpdate;
    NewSelStart := FCurrent;
    if goRowSelect in Options then NewSelStart.X := FixedCols+1;
    Selection := GridRect(NewSelStart, FAnchor);
  end;
end;

procedure TCustomEasyGrid.MoveTopLeft(ALeft, ATop: Longint);
var
  OldTopLeft: TGridCoord;
begin
  if (ALeft = FTopLeft.X) and (ATop = FTopLeft.Y) then Exit;
  OldTopLeft := FTopLeft;
  FTopLeft.X := ALeft;
  FTopLeft.Y := ATop;
  TopLeftMoved(OldTopLeft);
  if AutoUpdate then
    Update;
end;

procedure TCustomEasyGrid.ResizeCol(Index: Longint; OldSize, NewSize: Integer);

  function MinLeft : Integer;
  var
    i : Integer;
  begin
    Result := Index;
    for i:=1 to RowCount-1 do
      Result := Min(Merges[Index,i].Left,Result);
  end;

var
  ARect: TRect;
begin
  ARect.Left := CellRect(MinLeft, 0).Left;
  ARect.Top := 0;
  ARect.Bottom := Height;
  ARect.Right := Width;
  Windows.InvalidateRect(Handle, @ARect, False);
  if AutoUpdate then
    UpdateWindow(Handle);
end;

procedure TCustomEasyGrid.InitCell(AGrid:TCustomEasyGrid;ACell:PCellInfo;
          ACol,ARow:Integer);
begin
  with ACell^ do
    begin
      DataStyle := AGrid.FDataStyle;
      AlignMode := AGrid.FAlignMode;
      ReadOnly := AGrid.FReadOnly;
      AutoWordBreak := AGrid.FAutoWordBreak;
      ShowForeText := AGrid.FShowForeText;
      ForeText := '';
      BackText := '';
      DrawTop := False;
      DrawLeft := False;
      DrawBottom := False;
      DrawRight := False;
      LineWidth := AGrid.FCellLineWidth;
      PenStyle := AGrid.FCellPenStyle;
      AllowNegative := True;
      TrailingZero := False;
      ZeroNull := False;
      ThousandSep := False;
      MaxLength := AGrid.FMaxLength;
      IntLength := AGrid.FIntLength;
      DecLength := AGrid.FDecLength;
      Number := 0;
      FontName  := AGrid.FFontName;
      FontSize  := AGrid.FFontSize;
      FontColor := AGrid.FFontColor;
      FontStyle := [];
      if (ACol = 0) or (ARow = 0) then
         Color := AGrid.FTitleColor
      else
         Color := AGrid.FColor;
      with Merge do
      begin
        Left := ACol;
        Right := ACol;
        Top := ARow;
        Bottom := ARow;
      end;
    end;
end;

procedure TCustomEasyGrid.ColCountChange(Value: Integer);
var
  i : Integer;
begin
  // �������������
  if (FCells = nil) or (Value < 2) then
     Exit;
  if Value > ColCount then
  begin
    for i := ColCount to Value - 1 do
    begin
      FCells.Add(TColCellInfoList.Create(FCells.FGrid,i,FRowCount));
    end;
  end
  else
  begin
    for i := ColCount - 1 downto Value do
    begin
      TColCellInfoList(FCells.Items[i]).Free;
      FCells.Delete(i);
    end;
  end;
end;

procedure TCustomEasyGrid.RowCountChange(Value: Integer);
var
  i,j: Integer;
  ACellInfo: PCellInfo;
begin
  if FCells = nil then Exit;
  if Value > RowCount then
  begin
    for i := 0 to ColCount - 1 do
      for j := RowCount to Value - 1 do
      begin
        New(ACellInfo);
        InitCell(Self,ACellInfo,i,j);
        TColCellInfoList(FCells.Items[i]).Add(ACellInfo);
      end;
  end
  else
  begin
    for I := 0 to ColCount - 1 do
      for J := RowCount - 1 downto Value do
      begin
        Dispose(PCellInfo(TColCellInfoList(FCells.Items[I]).Items[J]));
        TColCellInfoList(FCells.Items[I]).Delete(J);
      end;
  end;
end;

procedure TCustomEasyGrid.ResizeRow(Index: Longint; OldSize, NewSize: Integer);

  function MinTop : Integer;
  var
    i : Integer;
  begin
    Result := Index;
    for i:=1 to ColCount-1 do
      Result := Min(Merges[i,Index].Top,Result);
  end;

var
  ARect: TRect;
begin
  ARect.Top := CellRect(Index, MinTop).Top;
  ARect.Left := 0;
  ARect.Bottom := Height;
  ARect.Right := Width;
  Windows.InvalidateRect(Handle, @ARect, False);
  if AutoUpdate then
    UpdateWindow(Handle);
end;

procedure TCustomEasyGrid.SelectionMoved(OldSel: TGridRect);
var
  TitleRect, OldRect, NewRect, ExtNewRect, ExtOldRect: TRect;
  TitleCoord1, TitleCoord2: TGridCoord;
  NewSel, ExtNewSel, ExtOldSel: TGridRect;
  AXorRects: TXorRects;
  I: Integer;

  procedure InvalidateColTitle(ASel: TGridRect);
  begin
    TitleCoord1.X := ASel.Left;
    TitleCoord1.Y := 0;
    TitleCoord2.X := ASel.Right;
    TitleCoord2.Y := 0;
    GridRectToScreenRect(GridRect(TitleCoord1, TitleCoord2), TitleRect, True);
    Windows.InvalidateRect(Handle, @TitleRect, False);
  end;

  procedure InvalidateRowTitle(ASel: TGridRect);
  begin
    TitleCoord1.X := 0;
    TitleCoord1.Y := ASel.Top;
    TitleCoord2.X := 0;
    TitleCoord2.Y := ASel.Bottom;
    GridRectToScreenRect(GridRect(TitleCoord1, TitleCoord2), TitleRect, True);
    Windows.InvalidateRect(Handle, @TitleRect, False);
  end;

begin
  if not HandleAllocated then Exit;
  NewSel := Selection;
  InvalidateColTitle(OldSel);
  InvalidateColTitle(NewSel);
  InvalidateRowTitle(OldSel);
  InvalidateRowTitle(NewSel);
  GridRectToScreenRect(OldSel, OldRect, True);
  GridRectToScreenRect(NewSel, NewRect, True);
  // ������ѡ�������ˢ��(�ɵ�����)
  if not RegularRange(OldSel) then
  begin
    ExtOldSel := CalcMaxRange(OldSel.TopLeft, OldSel.BottomRight);
    GridRectToScreenRect(ExtOldSel, ExtOldRect, True);
    XorRects(OldRect, ExtOldRect, AXorRects);
    for I := Low(AXorRects) to High(AXorRects) do
    begin
      InflateRect(AXorRects[i], 4, 4);
      Windows.InvalidateRect(Handle, @AXorRects[I], False);
    end;
  end;
  // ������ѡ�������ˢ��(�µ�����)
  if not RegularRange(NewSel) then
  begin
    ExtNewSel := CalcMaxRange(NewSel.TopLeft, NewSel.BottomRight);
    GridRectToScreenRect(ExtNewSel, ExtNewRect, True);
    XorRects(NewRect, ExtNewRect, AXorRects);
    for I := Low(AXorRects) to High(AXorRects) do
    begin
      InflateRect(AXorRects[i], 4, 4);
      Windows.InvalidateRect(Handle, @AXorRects[I], False);
    end;
  end;
  // ����ѡ�������ˢ��
  XorRects(OldRect, NewRect, AXorRects);
  for I := Low(AXorRects) to High(AXorRects) do
  begin
    InflateRect(AXorRects[i], 4, 4);
    Windows.InvalidateRect(Handle, @AXorRects[I], False);
  end;
end;

procedure TCustomEasyGrid.ScrollDataInfo(DX, DY: Integer;
  var DrawInfo: TEasyGridDrawInfo);
var
  ScrollArea: TRect;
  ScrollFlags: Integer;
begin
  //ƽ������
  {���Ĵ���ɣ�ScrollWindowEx DX or DY}
  with DrawInfo do
  begin
    ScrollFlags := SW_INVALIDATE;
    if not DefaultDrawing then
      ScrollFlags := ScrollFlags or SW_ERASE;
    { Scroll the area }
    // ˮƽ����
    if DY = 0 then
    begin
      { Scroll both the column titles and data area at the same time }
      ScrollArea := Rect(Horz.FixedBoundary, 0, Horz.GridExtent, Vert.GridExtent);
      ScrollWindowEx(Handle, DX, 0, @ScrollArea, @ScrollArea, 0, nil, ScrollFlags);
    end
    // ��ֱ����
    else if DX = 0 then
    begin
      { Scroll both the row titles and data area at the same time }
      ScrollArea := Rect(0, Vert.FixedBoundary, Horz.GridExtent, Vert.GridExtent);
      ScrollWindowEx(Handle, 0, DY, @ScrollArea, @ScrollArea, 0, nil, ScrollFlags);
    end
    else
    begin
      { Scroll titles and data area separately }
      { Column titles }
      // �����ǹ̶��е��б���
      ScrollArea := Rect(Horz.FixedBoundary, 0, Horz.GridExtent, Vert.FixedBoundary);
      ScrollWindowEx(Handle, DX, 0, @ScrollArea, @ScrollArea, 0, nil, ScrollFlags);
      { Row titles }
      // �����ǹ̶��е��б���
      ScrollArea := Rect(0, Vert.FixedBoundary + 1, Horz.FixedBoundary, Vert.GridExtent);
      ScrollWindowEx(Handle, 0, DY, @ScrollArea, @ScrollArea, 0, nil, ScrollFlags);
      { Data area }
      // ����������
      ScrollArea := Rect(Horz.FixedBoundary, Vert.FixedBoundary + 1, Horz.GridExtent,
        Vert.GridExtent);
      ScrollWindowEx(Handle, DX, DY, @ScrollArea, @ScrollArea, 0, nil, ScrollFlags);
    end;
  end;
  // ���������ѡ��,��ˢ��ѡ������(ѡ��������ܳ�����Ļ)
  if goRowSelect in Options then
    InvalidateRect(Selection);
end;

procedure TCustomEasyGrid.ScrollData(DX, DY: Integer);
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  ScrollDataInfo(DX, DY, DrawInfo);
end;

procedure TCustomEasyGrid.TopLeftMoved(const OldTopLeft: TGridCoord);

  function CalcScroll(const AxisInfo: TEasyGridAxisDrawInfo;
    OldPos, CurrentPos: Integer; var Amount: Longint): Boolean;
  var
    Start, Stop: Longint;
    I: Longint;
  begin
    Result := False;
    with AxisInfo do
    begin
      if OldPos < CurrentPos then
      begin
        Start := OldPos;
        Stop := CurrentPos;
      end
      else
      begin
        Start := CurrentPos;
        Stop := OldPos;
      end;
      Amount := 0;
      for I := Start to Stop - 1 do
      begin
        Inc(Amount, GetExtent(I) + EffectiveLineWidth);
        if Amount > (GridBoundary - FixedBoundary) then
        begin
          { Scroll amount too big, redraw the whole thing }
          InvalidateGrid;
          Exit;
        end;
      end;
      if OldPos < CurrentPos then Amount := -Amount;
    end;
    Result := True;
  end;

var
  DrawInfo: TEasyGridDrawInfo;
  Delta: TGridCoord;
begin
  UpdateScrollPos;
  CalcDrawInfo(DrawInfo);
  // ���� TopLeft �ı��Ӧ�ù��������� (Delta.X,Delta.Y)
  if CalcScroll(DrawInfo.Horz, OldTopLeft.X, FTopLeft.X, Delta.X) and
     CalcScroll(DrawInfo.Vert, OldTopLeft.Y, FTopLeft.Y, Delta.Y) then
     // ƽ����������
     ScrollDataInfo(Delta.X, Delta.Y, DrawInfo);
  TopLeftChanged;
end;

procedure TCustomEasyGrid.UpdateScrollPos;
var
  DrawInfo: TEasyGridDrawInfo;
  MaxTopLeft: TGridCoord;
  GridSpace, ColWidth: Integer;

  procedure SetScroll(Code: Word; Value: Integer);
  begin
    if GetScrollPos(Handle, Code) <> Value then
      SetScrollPos(Handle, Code, Value, True);
  end;

begin
  if (not HandleAllocated) or (ScrollBars = ssNone) then Exit;
  CalcDrawInfo(DrawInfo);
  // ������� TopLeft
  MaxTopLeft.X := ColCount - 1;
  MaxTopLeft.Y := RowCount - 1;
  MaxTopLeft := CalcMaxTopLeft(MaxTopLeft, DrawInfo);
  // �޸�ˮƽ������
  if ScrollBars in [ssHorizontal, ssBoth] then
    if ColCount = 2 then // ֻ��һ�е����(����������)
    begin
      ColWidth := ColWidths[DrawInfo.Horz.FirstGridCell];
      GridSpace := ClientWidth - DrawInfo.Horz.FixedBoundary;
      // ���󲿱����ص�������������ʾ�е��Ұ벿��
      if (FColOffset > 0) and (GridSpace > (ColWidth - FColOffset)) then
        ModifyScrollbar(SB_HORZ, SB_THUMBPOSITION, ColWidth - GridSpace, True)
      // ����û�б�����(�����е��Ұ벿���ܷ�������ʾ)
      else
        SetScroll(SB_HORZ, FColOffset)
    end
    // ���ڶ���
    else
      SetScroll(SB_HORZ, LongMulDiv(FTopLeft.X - (FixedCols + 1), MaxShortInt,
        MaxTopLeft.X - (FixedCols + 1)));
  // �޸Ĵ�ֱ������
  if ScrollBars in [ssVertical, ssBoth] then
    SetScroll(SB_VERT, LongMulDiv(FTopLeft.Y - (FixedRows + 1), MaxShortInt,
      MaxTopLeft.Y - (FixedRows + 1)));
end;

function TCustomEasyGrid.ScrollBarVisible(Code: Word): Boolean;
var
  Min, Max: Integer;
begin
  Result := False;
  if (ScrollBars = ssBoth) or
    ((Code = SB_HORZ) and (ScrollBars = ssHorizontal)) or
    ((Code = SB_VERT) and (ScrollBars = ssVertical)) then
  begin
    GetScrollRange(Handle, Code, Min, Max);
    Result := Min <> Max;
  end;
end;

procedure TCustomEasyGrid.UpdateScrollRange;
var
  MaxTopLeft, OldTopLeft: TGridCoord;
  DrawInfo: TEasyGridDrawInfo;
  OldScrollBars: TScrollStyle;
  Range : Integer;
  Updated: Boolean;

  procedure DoUpdate;
  begin
    if (not Updated) and FAutoUpdate then
    begin
      Update;
      Updated := True;
    end;
  end;

  procedure CalcSizeInfo;
  begin
    CalcDrawInfoXY(DrawInfo, DrawInfo.Horz.GridExtent, DrawInfo.Vert.GridExtent);
    MaxTopLeft.X := ColCount - 1;
    MaxTopLeft.Y := RowCount - 1;
    MaxTopLeft := CalcMaxTopLeft(MaxTopLeft, DrawInfo);
  end;

  procedure SetAxisRange(var Max, Old, Current: Longint; Code: Word;
    Fixeds: Integer);
  begin
    CalcSizeInfo;
    // ���������Χ��������Ļ
    if Fixeds + 1 < Max then
      SetScrollRange(Handle, Code, 0, MaxShortInt, True)
    // �����������
    else
      SetScrollRange(Handle, Code, 0, 0, True);
    // ������� TopLeft
    if Old > Max then
    begin
      DoUpdate;
      Current := Max;
    end;
  end;

  procedure SetHorzRange;
  var
    Range: Integer;
  begin
    if OldScrollBars in [ssHorizontal, ssBoth] then
      if ColCount = 2 then // ֻ��һ�е����(����������)
      begin
        Range := ColWidths[1] - ClientWidth;
        if Range < 0 then Range := 0;
        SetScrollRange(Handle, SB_HORZ, 0, Range, True);
      end
      else
        SetAxisRange(MaxTopLeft.X, OldTopLeft.X, FTopLeft.X, SB_HORZ, FixedCols);
  end;

  procedure SetVertRange;
  begin
    if OldScrollBars in [ssVertical, ssBoth] then
      if RowCount = 2 then // ֻ��һ�е����(����������)
      begin
        Range := RowHeights[1] - ClientHeight;
        if Range < 0 then Range := 0;
        SetScrollRange(Handle, SB_VERT, 0, Range, True);
      end
      else
        SetAxisRange(MaxTopLeft.Y, OldTopLeft.Y, FTopLeft.Y, SB_VERT, FixedRows);
  end;

begin
  if (ScrollBars = ssNone) or not HandleAllocated or not Showing then Exit;
  with DrawInfo do
  begin
    Horz.GridExtent := ClientWidth;
    Vert.GridExtent := ClientHeight;
    // ���Ⱥ��Թ������Ĵ�С(�ѹ������Ĵ�С���� ClientWidth,ClientHeight)
    if ScrollBarVisible(SB_HORZ) then
      Inc(Vert.GridExtent, GetSystemMetrics(SM_CYHSCROLL));
    if ScrollBarVisible(SB_VERT) then
      Inc(Horz.GridExtent, GetSystemMetrics(SM_CXVSCROLL));
  end;
  OldTopLeft := FTopLeft;
  { Temporarily mark us as not having scroll bars to avoid recursion }
  OldScrollBars := FScrollBars;
  FScrollBars := ssNone;
  Updated := False;
  try
    { Update scrollbars }
    SetHorzRange;
    DrawInfo.Vert.GridExtent := ClientHeight;
    SetVertRange;
    if DrawInfo.Horz.GridExtent <> ClientWidth then
    begin
      DrawInfo.Horz.GridExtent := ClientWidth;
      SetHorzRange;
    end;
  finally
    FScrollBars := OldScrollBars;
  end;
  UpdateScrollPos;
  if (FTopLeft.X <> OldTopLeft.X) or (FTopLeft.Y <> OldTopLeft.Y) then
     TopLeftMoved(OldTopLeft);
end;

function TCustomEasyGrid.CreateEditor: TInplaceEdit;
begin
  Result := TInplaceEdit.Create(Self);
end;

procedure TCustomEasyGrid.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do
  begin
    Style := Style or WS_TABSTOP;
    if FScrollBars in [ssVertical, ssBoth] then Style := Style or WS_VSCROLL;
    if FScrollBars in [ssHorizontal, ssBoth] then Style := Style or WS_HSCROLL;
    WindowClass.style := CS_DBLCLKS;
    if FBorderStyle = bsSingle then
      if NewStyleControls and Ctl3D then
      begin
        Style := Style and not WS_BORDER;
        ExStyle := ExStyle or WS_EX_CLIENTEDGE;
      end
      else
        Style := Style or WS_BORDER;
  end;
end;

procedure TCustomEasyGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  NewTopLeft, NewCurrent, MaxTopLeft: TGridCoord;
  DrawInfo: TEasyGridDrawInfo;
  PageWidth, PageHeight: Integer;
  NewSelect: TGridRect;
  SimMousePos: TPoint;

  procedure CalcPageExtents;
  begin
    PageWidth := DrawInfo.Horz.LastFullVisibleCell - LeftCol;
    if PageWidth < 1 then PageWidth := 1;
    PageHeight := DrawInfo.Vert.LastFullVisibleCell - TopRow;
    if PageHeight < 1 then PageHeight := 1;
  end;

  procedure CalcSimMousePos(ACellCoord: TGridCoord);
  var
    ARect: TRect;
  begin
    ARect := CellRect(ACellCoord.X, ACellCoord.Y);
    SimMousePos.x := ARect.Left + (ARect.Right - ARect.Left) shr 1;
    SimMousePos.Y := ARect.Top + (ARect.Bottom - ARect.Top) shr 1;
  end;

begin
  inherited KeyDown(Key, Shift);
  CalcDrawInfo(DrawInfo);
  // ȥ�������� Alt,Shift,Ctrl,Pause,CapsLock
  if (Key >= 16) and (Key <= 20) then
    Exit;
  // ����������� CanGridAcceptKey �����Ծ����ܷ���� Key
  if not CanGridAcceptKey(Key, Shift) then Key := 0;
  NewTopLeft := FTopLeft;
  NewCurrent := FCurrent;
  if ssShift in Shift then
    NewCurrent := FAnchor;
  CalcPageExtents; // ����ҳ�Ŀ�� PageWidth, PageHeight( Grid ����)
  // Ctrl ������
  if ssCtrl in Shift then
    case Key of
      // �����¹�,�����ı䵱ǰ Cell
      VK_UP:
        NewTopLeft.Y := FindLastVisibleCell(NewTopLeft.Y - 1, DrawInfo.Vert);
      // �����Ϲ�,�����ı䵱ǰ Cell
      VK_DOWN:
        NewTopLeft.Y := FindNextVisibleCell(NewTopLeft.Y + 1, DrawInfo.Vert);
      // �������,�����ı䵱ǰ Cell
      VK_LEFT:
        NewTopLeft.X := FindLastVisibleCell(NewTopLeft.X - 1, DrawInfo.Horz);
      // �����ҹ�,�����ı䵱ǰ Cell
      VK_RIGHT:
        NewTopLeft.X := FindNextVisibleCell(NewTopLeft.X + 1, DrawInfo.Horz);
      // �ƶ�����ǰ��Ļ���
      VK_PRIOR:
        NewCurrent.Y := FindNextVisibleCell(TopRow, DrawInfo.Vert);
      // �ƶ�����ǰ��Ļ�����
      VK_NEXT:
        NewCurrent.Y := FindLastVisibleCell(DrawInfo.Vert.LastFullVisibleCell, DrawInfo.Vert);
      // �ƶ������� Grid �ĵ�һ�� Cell
      VK_HOME:
        begin
          NewCurrent.X := FindNextVisibleCell(FixedCols + 1, DrawInfo.Horz);
          NewCurrent.Y := FindNextVisibleCell(FixedRows + 1, DrawInfo.Vert);
        end;
      // �ƶ������� Grid �����һ�� Cell
      VK_END:
        begin
          NewCurrent.X := FindLastVisibleCell(ColCount - 1, DrawInfo.Horz);
          NewCurrent.Y := FindLastVisibleCell(RowCount - 1, DrawInfo.Vert);
        end;
    end
  // û�а��� Ctrl ��
  else
    case Key of
      VK_UP:
        begin
          NewCurrent.Y := FindLastVisibleCell(NewCurrent.Y - 1, DrawInfo.Vert);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_DOWN:
        begin
          NewCurrent.Y := FindNextVisibleCell(Merges[NewCurrent.X, NewCurrent.Y].Bottom + 1, DrawInfo.Vert);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_LEFT:
        begin
          if (goRowSelect in Options) then
            NewCurrent.X := LeftCol - 1
          else
            NewCurrent.X := FindLastVisibleCell(NewCurrent.X - 1, DrawInfo.Horz);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_RIGHT:
        begin
          if (goRowSelect in Options) then
            NewCurrent.X := DrawInfo.Horz.LastFullVisibleCell + 1
          else
            NewCurrent.X := FindNextVisibleCell(Merges[NewCurrent.X, NewCurrent.Y].Right + 1, DrawInfo.Horz);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_NEXT:  // �·�һ��
        begin
          NewCurrent.Y := FindNextVisibleCell(NewCurrent.Y + PageHeight, DrawInfo.Vert);
          NewTopLeft.Y := FindNextVisibleCell(NewTopLeft.Y + PageHeight, DrawInfo.Vert);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_PRIOR: // �Ϸ�һ��
        begin
          NewCurrent.Y := FindLastVisibleCell(NewCurrent.Y - PageHeight, DrawInfo.Vert);
          NewTopLeft.Y := FindLastVisibleCell(NewTopLeft.Y - PageHeight, DrawInfo.Vert);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_HOME:
        begin
          if goRowSelect in Options then
            NewCurrent.Y := FindNextVisibleCell(FixedRows + 1, DrawInfo.Vert)
          else
            NewCurrent.X := FindNextVisibleCell(FixedCols + 1, DrawInfo.Horz);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_END:
        begin
          if goRowSelect in Options then
            NewCurrent.Y := FindLastVisibleCell(RowCount - 1, DrawInfo.Vert)
          else
            NewCurrent.X := FindLastVisibleCell(ColCount - 1, DrawInfo.Horz);
          if ssShift in Shift then
          begin
            FGridState := gsSelecting;
            CalcSimMousePos(NewCurrent);
            MouseMove([], SimMousePos.X, SimMousePos.Y);
            FGridState := gsNormal;
            Exit;
          end;
        end;
      VK_TAB:
        begin
          if not (ssAlt in Shift) then
          repeat
            if ssShift in Shift then
            begin
              NewCurrent.X := FindLastVisibleCell(NewCurrent.X - 1, DrawInfo.Horz);
              if NewCurrent.X = FixedCols + 1 then
              begin
                Shift := [];
                break;
              end;
            end
            else
            begin
              NewCurrent.X := FindNextVisibleCell(NewCurrent.X + 1, DrawInfo.Horz);
              if NewCurrent.X = ColCount - 1 then
                 break;
            end;
          until TabStops[NewCurrent.X];
        end;
      VK_F2: EditorMode := True;
      VK_ESCAPE: HideEditor;
      VK_DELETE:
        begin
          if (goEditing in Options) then
          begin
            ClearCells(TRect(Selection));
            InvalidateRect(Selection);
          end;
        end;
    end;
  // ���� MaxTopLeft
  MaxTopLeft.X := ColCount - 1;
  MaxTopLeft.Y := RowCount - 1;
  MaxTopLeft := CalcMaxTopLeft(MaxTopLeft, DrawInfo);
  // ������� TopLeft
  Restrict(NewTopLeft, FixedCols+1, FixedRows+1, MaxTopLeft.X, MaxTopLeft.Y);
  // ������� NewCurrent
  Restrict(NewCurrent, FixedCols+1, FixedRows+1, ColCount - 1, RowCount - 1);
  // ����ϲ������,�� Top �� Left ��Ϊ�ϲ���������Ͻ�
  NewSelect.TopLeft := Merges[NewCurrent.X, NewCurrent.Y].TopLeft;
  NewSelect.BottomRight := Merges[NewCurrent.X, NewCurrent.Y].BottomRight;
  if (NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow) then
     MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
  // �ƶ����µ�����
  if (NewSelect.Left <> FCurrent.X) or (NewSelect.Top <> FCurrent.Y) then
     FocusCell(NewSelect.Left, NewSelect.Top, True);
end;

procedure TCustomEasyGrid.KeyUp(var Key: Word; Shift: TShiftState); 
begin
  inherited KeyUp(Key, Shift);
{
  if Key = VK_CONTROL then
    if (HitTest.x > 0) and (HitTest.y > 0) and
       (HitTest.x < Width) and (HitTest.Y < Height) then
      Perform(WM_SETCURSOR, 0, 1)
    else
      Perform(WM_SETCURSOR, 0, 0);
}
end;

procedure TCustomEasyGrid.KeyPress(var Key: Char);
begin
  inherited KeyPress(Key);
  if not (goAlwaysShowEditor in Options) and (Key = #13) then
  begin
    if FEditorMode then
      HideEditor else
      ShowEditor;
    Key := #0;
  end;
end;

procedure TCustomEasyGrid.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  NewAnchor, NewCurrent, NewTopLeft, CellHit, Coord1, Coord2: TGridCoord;
  DrawInfo: TEasyGridDrawInfo;
  NewSelect, OldSel: TGridRect;
  ClientPoint: TPoint;
  i: Integer;

  // ���δ��ȫ��ʾ������ʱ��Ҫ����
  function IsTopLeftMove: Boolean;
  begin
    Result := (CellHit.X > DrawInfo.Horz.LastFullVisibleCell) or (CellHit.Y > DrawInfo.Vert.LastFullVisibleCell);
  end;

begin
  HideEditor;
  // ������ʱ�õ�����,������׽����¼�
  if not (csDesigning in ComponentState) and
    (CanFocus or (GetParentForm(Self) = nil)) then
  begin
    SetFocus;
    if not IsActiveControl then
    begin
      MouseCapture := False;
      Exit;
    end;
  end;
  CalcDrawInfo(DrawInfo);
  CellHit := CalcCoordFromPoint(X, Y, DrawInfo);
  // ���������Ҽ��򵯳��˵�
  if (Button = mbRight) and (FGridState = gsNormal) then
  begin
    NewCurrent := Merges[CellHit.X, CellHit.Y].TopLeft;
    Restrict(NewCurrent, FixedCols+1, FixedRows+1, ColCount-1, RowCount-1);
    if not PointInGridRect(NewCurrent.X, NewCurrent.Y, Selection) then
      FocusCell(NewCurrent.X, NewCurrent.Y, True);
    if not ShowPopup then Exit; 
    ClientPoint := ClientToScreen(Point(X, Y));
    with EasyGridPopup do
    begin
      for i:=0 to Items.Count-1 do
        Items[i].Enabled := True;
    end;
    EasyGridPopup.Items[2].Enabled := ClipBoardAvailable;
    if not (goEditing in Options) then
      with EasyGridPopup do
      begin
        for i:=0 to Items.Count-1 do
          Items[i].Enabled := False;
        Items[1].Enabled := True;
      end;
    if not RegularRange(Selection) then
      with EasyGridPopup do
      begin
        for i:=0 to Items.Count-1 do
          Items[i].Enabled := False;
      end;
    EasyGridPopup.Popup(ClientPoint.X, ClientPoint.Y);
    Exit;
  end;
  // ��������˫��
  if (Button = mbLeft) and (ssDouble in Shift) then
  begin
    // ���û�����˫��
    DblClick;
    // ���˫����ǰѡ�е�����,����ʾ InplaceEditor
    if not ((CellHit.X < LeftCol) or (CellHit.Y < TopRow)) and
       (Merges[CellHit.X, CellHit.Y].Left = Merges[FCurrent.X, FCurrent.Y].Left) and
       (Merges[CellHit.X, CellHit.Y].Top = Merges[FCurrent.X, FCurrent.Y].Top) then
       ShowEditor;
  end
  // ������������
  else if Button = mbLeft then
  begin
    // �����ܷ� Sizing (������� Sizing �����ϻ� SizingLine)
    CalcSizingState(X, Y, FGridState, FSizingIndex, FSizingPos, FSizingOfs,
      DrawInfo);
    if FGridState <> gsNormal then
      begin
        DrawSizingLine(DrawInfo);
        Exit;
      end;
    // ���� Copy, Move, Fill ״̬
    CalcExtendedState(X, Y, FGridState, DrawInfo);
    if (FGridState = gsCopying) or (FGridState = gsMoving) then
      begin
        FCopyMoveRect := Selection;
        Restrict(CellHit,FCopyMoveRect.Left,FCopyMoveRect.Top,
                 FCopyMoveRect.Right,FCopyMoveRect.Bottom);
        FCopyMoveCell := CellHit;
        FillChar(FCopyMoveOffset, SizeOf(FCopyMoveOffset), 0);
        DrawCopyMoveRect(DrawInfo);
        Exit;
      end;
    if (FGridState = gsFilling) then
      begin
        FFillRect := Selection;
        Restrict(CellHit,FFillRect.Left,FFillRect.Top,
                 FFillRect.Right,FFillRect.Bottom);
        FFillCell := CellHit;
        FFillStyle := fsNone;
        FillChar(FFillOffset, SizeOf(FFillOffset), 0);
        DrawFillRect(DrawInfo);
        Exit;
      end;
    // *************************************************
    // ������л������
    if ((CellHit.X = 0) and ((CellHit.Y = 0) or (CellHit.Y > FixedRows))) or
       ((CellHit.Y = 0) and ((CellHit.X = 0) or (CellHit.X > FixedCols))) then
    begin
      OldSel := Selection;
      // ������Ͻǵı���������,��ѡ����������
      if ((CellHit.X = 0) and (CellHit.Y = 0)) then
        begin
          if goRangeSelect in Options then
            begin
              NewSelect.Left := FixedCols + 1;
              NewSelect.Top := FixedRows + 1;
              NewSelect.Right := ColCount - 1;
              NewSelect.Bottom := RowCount - 1;
            end
          else
            NewSelect := Merges[FixedCols+1,FixedRows+1]^;
          NewCurrent := NewSelect.TopLeft;
          NewAnchor := NewSelect.BottomRight;
        end
      // �����б���,��ѡ��������
      else if CellHit.X > FixedCols then
        if (ssShift in Shift) then  // Shift ������
          begin
            if goRangeSelect in Options then
              begin
                Coord1.X := FCurrent.X;
                Coord1.Y := FixedRows + 1;
                Coord2.X := CellHit.X;
                Coord2.Y := RowCount - 1;
              end
            else
              begin
                Coord1.X := CellHit.X;
                Coord1.Y := FixedRows + 1;
                Coord2 := Coord1;
              end;
            NewSelect := CalcMaxRange(Coord1, Coord2);
            NewCurrent := FCurrent;
            NewAnchor := NewSelect.BottomRight;
          end
        else                        // Shift ��δ����
          begin
            if goRangeSelect in Options then
              begin
                NewSelect.Left := CellHit.X;
                NewSelect.Right := NewSelect.Left;
                NewSelect.Top := FixedRows + 1;
                NewSelect.Bottom := RowCount - 1;
              end
            else
              NewSelect := Merges[CellHit.X, FixedRows+1]^;
            NewCurrent.X := Merges[NewSelect.Left, NewSelect.Top].Left;
            NewCurrent.Y := NewSelect.Top;
            NewAnchor := NewSelect.BottomRight;
          end
      // �����б���,��ѡ��������
      else if CellHit.Y > FixedRows then
        if (ssShift in Shift) then  // Shift ������
          begin
            if goRangeSelect in Options then
              begin
                Coord1.X := FixedCols + 1;
                Coord1.Y := FCurrent.Y;
                Coord2.X := ColCount - 1;
                Coord2.Y := CellHit.Y;
              end
            else
              begin
                Coord1.X := FixedCols + 1;
                Coord1.Y := CellHit.Y;
                Coord2 := Coord1;
              end;
            NewSelect := CalcMaxRange(Coord1, Coord2);
            NewCurrent := FCurrent;
            NewAnchor := NewSelect.BottomRight;
          end
        else                        // Shift ��δ����
          begin
            if goRangeSelect in Options then
              begin
                NewSelect.Top := CellHit.Y;
                NewSelect.Bottom := NewSelect.Top;
                NewSelect.Left := FixedCols + 1;
                NewSelect.Right := ColCount-1;
              end
            else
              NewSelect := Merges[FixedCols+1, CellHit.Y]^;
            NewCurrent.X := NewSelect.Left;
            NewCurrent.Y := Merges[NewSelect.Left, NewSelect.Top].Top;
            NewAnchor := NewSelect.BottomRight;
          end;
      if (Selection.Left = NewSelect.Left) and
         (Selection.Right = NewSelect.Right) and
         (Selection.Bottom = NewSelect.Bottom) and
         (Selection.Top = NewSelect.Top) then Exit;
    end
    // *************************************************
    // ��������
    else if ((CellHit.Y >= TopRow) and (CellHit.X >= LeftCol)) then
    begin
      FGridState := gsSelecting;
      //SetTimer(Handle, 1, 60, nil);
      // Shift ������������ѡȡ��Χ,���ʾѡȡ��Χ
      if (ssShift in Shift) and (goRangeSelect in Options) then
        begin
          NewSelect := CalcMaxRange(FCurrent, CellHit);
          NewCurrent := FCurrent;
          NewAnchor := NewSelect.BottomRight;
        end
      // Shift ��δ����(��ʾѡȡ��������)
      else
        begin
          NewSelect.TopLeft := Merges[CellHit.X, CellHit.Y].TopLeft;
          NewSelect.BottomRight := Merges[CellHit.X, CellHit.Y].BottomRight;
          NewTopLeft := CalcMaxTopLeft(NewSelect.TopLeft, DrawInfo);
          NewCurrent := NewSelect.TopLeft;
          NewAnchor := NewSelect.BottomRight;
          // �������δ��ȫ��ʾ�ĺϲ�����(�󲿱�����)
          {
          if ((NewSelect.Left < LeftCol) or (NewSelect.Top < TopRow) or
              (NewSelect.Right > DrawInfo.Horz.LastFullVisibleCell) or
              (NewSelect.Bottom > DrawInfo.Vert.LastFullVisibleCell)) and
             ((NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow)) and
             (not (goRowSelect in Options)) then
             MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);}
        end;
    end
    else Exit;
    // �ƶ����µ����������µĵ�ѡ������
    FocusCell(NewCurrent.X, NewCurrent.Y, True);
    if goRowSelect in Options then
    begin
      NewSelect.Left := FixedCols + 1;
      NewSelect.Right := ColCount - 1;
    end;
    Selection := NewSelect;
  end;
  inherited MouseDown(Button, Shift, X, Y);
end;

// �����Ƿ�ɻ� Sizing ��,���ƶ���Χ�����������Сλ�����ܻ�
function TCustomEasyGrid.CanDrawSizingLine(AAxisDrawInfo:TEasyGridAxisDrawInfo;
         SizingPos: Integer; State: TEasyGridState): Boolean;
begin
  Result := True;
  with AAxisDrawInfo do
  if ((State = gsColSizing) and (SizingPos < CellRect(FSizingIndex,0).Left-EffectiveLineWidth)) or
     ((State = gsRowSizing) and (SizingPos < CellRect(0,FSizingIndex).Top-EffectiveLineWidth)) then
     Result := False;
end;

procedure TCustomEasyGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  DrawInfo: TEasyGridDrawInfo;
  NewCurrent, NewTopLeft,NewAnchor,CellHit,NewCopyMoveOffset,NewFillOffset: TGridCoord;
  NewSel, OldSel: TGridRect;
  FillWidth, FillHeight: Integer;
begin
  CalcDrawInfo(DrawInfo);
  CellHit := CalcCoordFromPoint(X, Y, DrawInfo);
  case FGridState of
    gsSelecting :
      begin
        // �����Ϸ��϶�ѡ�񲢳�����ʾ��Χ
        if (CellHit.X < LeftCol) and (LeftCol > FixedCols + 1) then
           CellHit.X := FindLastVisibleCell(LeftCol-1, DrawInfo.Horz);
        if (CellHit.Y < TopRow) and (TopRow > FixedRows + 1) then
           CellHit.Y := FindLastVisibleCell(TopRow-1, DrawInfo.Vert);
        Restrict(CellHit, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
        // ���λ�Ƴ���һ�� Cell ��Χ
        if ((Merges[CellHit.X, CellHit.Y].Left   <> Merges[FAnchor.X, FAnchor.Y].Left) or
            (Merges[CellHit.X, CellHit.Y].Top    <> Merges[FAnchor.X, FAnchor.Y].Top) or
            (Merges[CellHit.X, CellHit.Y].Right  <> Merges[FAnchor.X, FAnchor.Y].Right) or
            (Merges[CellHit.X, CellHit.Y].Bottom <> Merges[FAnchor.X, FAnchor.Y].Bottom)) then
           begin
             // ����������϶�ѡ��,�������ƶ���Ŀ�� Cell ����
             if not (goRangeSelect in Options) then
             begin
               NewSel.TopLeft := Merges[CellHit.X, CellHit.Y].TopLeft;
               NewSel.BottomRight := Merges[CellHit.X, CellHit.Y].BottomRight;
               NewTopLeft := CalcMaxTopLeft(NewSel.TopLeft, DrawInfo);
               NewCurrent := NewSel.TopLeft;
               // �������δ��ȫ��ʾ�ĺϲ�����(�󲿱�����)
               if ((NewSel.Left < LeftCol) or (NewSel.Top < TopRow) or
                   (NewSel.Right > DrawInfo.Horz.LastFullVisibleCell) or
                   (NewSel.Bottom > DrawInfo.Vert.LastFullVisibleCell)) and
                  ((NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow)) then
                  MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
               // �ƶ����µ����������µĵ�ѡ������
               FocusCell(NewCurrent.X, NewCurrent.Y, True);
               if goRowSelect in Options then
               begin
                 NewSel.Left := FixedCols + 1;
                 NewSel.Right := ColCount - 1;
               end;
               Selection := NewSel;
               inherited MouseMove(Shift, X, Y);
               Exit;
             end;
             // �����϶�ѡ��
             OldSel := Selection;
             NewSel := CalcMaxRange(FCurrent, CellHit);
             NewAnchor := CellHit;
             NewTopLeft := FTopLeft;
             // ���ѡ�����������Ϸ����󲢳�����ʾ��Χ
             if (NewAnchor.X < LeftCol) or
                (NewAnchor.Y < TopRow) then
               NewTopLeft := CalcMaxTopLeft(NewAnchor, DrawInfo)
             // ���ѡ�����������·����󲢳�����ʾ��Χ
             else if (NewAnchor.X > DrawInfo.Horz.LastFullVisibleCell) or
                (NewAnchor.Y > DrawInfo.Vert.LastFullVisibleCell) then
               NewTopLeft := CalcMaxTopLeft(NewAnchor, DrawInfo);
             // TopLeft ���е�һ�����ܲ���Ҫ�ı�
             if (NewAnchor.X > LeftCol) and (NewAnchor.X <= DrawInfo.Horz.LastFullVisibleCell) then
               NewTopLeft.X := FTopLeft.X;
             if (NewAnchor.Y > TopRow) and (NewAnchor.Y <= DrawInfo.Vert.LastFullVisibleCell) then
               NewTopLeft.Y := FTopLeft.Y;
             if ((NewSel.Left < LeftCol) or (NewSel.Top < TopRow) or
                 (NewSel.Right > DrawInfo.Horz.LastFullVisibleCell) or
                 (NewSel.Bottom > DrawInfo.Vert.LastFullVisibleCell)) and
                ((NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow)) then
                MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
             MoveAnchor(NewAnchor,False);
             // ˢ���µĵ�ѡ������
             if goRowSelect in Options then
             begin
               NewSel.Left := FixedCols + 1;
               NewSel.Right := ColCount - 1;
             end;
             Selection := NewSel;
          end;
      end;
    gsRowSizing:
      begin
        // ����ϴλ�����
        if CanDrawSizingLine(DrawInfo.Vert,FSizingPos, gsRowSizing) then
           DrawSizingLine(DrawInfo);
        // ���µ�λ�û���
        FSizingPos := Y + FSizingOfs;
        if FSizingPos < 0 then
          FSizingPos := 0;
        if FSizingPos > Height then
          FSizingPos := Height;
        if CanDrawSizingLine(DrawInfo.Vert,FSizingPos, gsRowSizing) then
           DrawSizingLine(DrawInfo);
      end;
    gsColSizing:
      begin
        // ����ϴλ�����
        if CanDrawSizingLine(DrawInfo.Horz,FSizingPos, gsColSizing) then
           DrawSizingLine(DrawInfo);
        FSizingPos := X + FSizingOfs;
        if FSizingPos < 0 then
          FSizingPos := 0;
        if FSizingPos > Width then
          FSizingPos := Width;
        // ���µ�λ�û���
        if CanDrawSizingLine(DrawInfo.Horz,FSizingPos, gsColSizing) then
           DrawSizingLine(DrawInfo);
      end;
    gsFilling:
      begin
        // ��������Ϸ��϶�ѡ�񲢳�����ʾ��Χ
        if (CellHit.X < LeftCol) and (LeftCol > FixedCols + 1) then
           CellHit.X := LeftCol - 1;
        if (CellHit.Y < TopRow) and (TopRow > FixedRows + 1) then
           CellHit.Y := TopRow - 1;
        Restrict(CellHit, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
        // �����µ� TopLeft
        NewTopLeft := FTopLeft;
        if (CellHit.X < LeftCol) or (CellHit.Y < TopRow) or
           (CellHit.X > DrawInfo.Horz.LastFullVisibleCell) or
           (CellHit.Y > DrawInfo.Vert.LastFullVisibleCell) then
          NewTopLeft := CalcMaxTopLeft(CellHit, DrawInfo);
        // TopLeft ���е�һ�����ܲ���Ҫ�ı�
        if (CellHit.X > LeftCol) and (CellHit.X <= DrawInfo.Horz.LastFullVisibleCell) then
          NewTopLeft.X := FTopLeft.X;
        if (CellHit.Y > TopRow) and (CellHit.Y <= DrawInfo.Vert.LastFullVisibleCell) then
          NewTopLeft.Y := FTopLeft.Y;
        // ���� FillStyle
        FFillStyle := fsHorzFill;
        if PointInGridRect(CellHit.X, CellHit.Y, FFillRect) then
          FFillStyle := fsNone
        else if ((CellHit.X < FFillRect.Left) or (CellHit.X > FFillRect.Right)) and
           ((CellHit.Y >= FFillRect.Top) and (CellHit.Y <= FFillRect.Bottom)) then
          FFillStyle := fsHorzFill
        else if ((CellHit.Y < FFillRect.Top) or (CellHit.Y > FFillRect.Bottom)) and
           ((CellHit.X >= FFillRect.Left) and (CellHit.X <= FFillRect.Right)) then
          FFillStyle := fsVertFill;
        // ���� FillOffset
        FillWidth := FFillRect.Right - FFillRect.Left + 1;
        FillHeight := FFillRect.Bottom - FFillRect.Top + 1;
        NewFillOffset.X := CellHit.X - FFillRect.Left;
        NewFillOffset.Y := CellHit.Y - FFillRect.Top;
        // ע��: ��� Fill ��Χ�ں��кϲ�����,�� Fill ��ΧӦ����һ������
        case FFillStyle of
          fsNone :     // û�� Fill
            FillChar(NewFillOffset, SizeOf(NewFillOffset), 0);
          fsHorzFill : // ���� Fill
            begin
              NewFillOffset.Y := 0;
              if NewFillOffset.X > 0 then Dec(NewFillOffset.X, FillWidth - 1);
              if HaveMerge(@FFillRect) then // Fill ��Χ�ں��кϲ���������
                if NewFillOffset.X > 0 then
                  NewFillOffset.X := ((NewFillOffset.X - 1) Div FillWidth + 1) * FillWidth
                else
                  NewFillOffset.X := ((NewFillOffset.X + 1) Div FillWidth - 1) * FillWidth;
            end;
          fsVertFill : // ���� Fill
            begin
              NewFillOffset.X := 0;
              if NewFillOffset.Y > 0 then Dec(NewFillOffset.Y, FillHeight - 1);
              if HaveMerge(@FFillRect) then // Fill ��Χ�ں��кϲ���������
                if NewFillOffset.Y > 0 then
                  NewFillOffset.Y := ((NewFillOffset.Y - 1) Div FillHeight + 1) * FillHeight
                else
                  NewFillOffset.Y := ((NewFillOffset.Y + 1) Div FillHeight - 1) * FillHeight
            end;
        end;
        if (FFillRect.Left + NewFillOffset.X > FixedCols) and
           (FFillRect.Right + NewFillOffset.X < ColCount) and
           (FFillRect.Top + NewFillOffset.Y > FixedRows) and
           (FFillRect.Bottom + NewFillOffset.Y < RowCount) then
        begin
          DrawFillRect(DrawInfo); // ����ϴλ��Ŀ�
          if ((NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow)) then
             MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
          FFillOffset := NewFillOffset;
          DrawFillRect(DrawInfo); // ���µ�λ�û���
        end;
      end;
    gsCopying,gsMoving:
      begin
        // �����Ϸ��϶�ѡ�񲢳�����ʾ��Χ
        if (CellHit.X < LeftCol) and (LeftCol > FixedCols + 1) then
           CellHit.X := LeftCol - 1;
        if (CellHit.Y < TopRow) and (TopRow > FixedRows + 1) then
           CellHit.Y := TopRow - 1;
        Restrict(CellHit, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
        // �����µ� TopLeft
        NewTopLeft := FTopLeft;
        if (CellHit.X < LeftCol) or (CellHit.Y < TopRow) or
           (CellHit.X > DrawInfo.Horz.LastFullVisibleCell) or
           (CellHit.Y > DrawInfo.Vert.LastFullVisibleCell) then
          NewTopLeft := CalcMaxTopLeft(CellHit, DrawInfo);
        // TopLeft ���е�һ�����ܲ���Ҫ�ı�
        if (CellHit.X > LeftCol) and (CellHit.X <= DrawInfo.Horz.LastFullVisibleCell) then
          NewTopLeft.X := FTopLeft.X;
        if (CellHit.Y > TopRow) and (CellHit.Y <= DrawInfo.Vert.LastFullVisibleCell) then
          NewTopLeft.Y := FTopLeft.Y;
        // �����µ� CopyMoveOffset
        NewCopyMoveOffset.X := CellHit.X - FCopyMoveCell.X;
        NewCopyMoveOffset.Y := CellHit.Y - FCopyMoveCell.Y;
        if (FCopyMoveRect.Left + NewCopyMoveOffset.X > FixedCols) and
           (FCopyMoveRect.Right + NewCopyMoveOffset.X < ColCount) and
           (FCopyMoveRect.Top + NewCopyMoveOffset.Y > FixedRows) and
           (FCopyMoveRect.Bottom + NewCopyMoveOffset.Y < RowCount) then
        begin
          DrawCopyMoveRect(DrawInfo); // ����ϴλ��Ŀ�
          if ((NewTopLeft.X <> LeftCol) or (NewTopLeft.Y <> TopRow)) then
             MoveTopLeft(NewTopLeft.X, NewTopLeft.Y);
          FCopyMoveOffset.X := CellHit.X - FCopyMoveCell.X;
          FCopyMoveOffset.Y := CellHit.Y - FCopyMoveCell.Y;
          DrawCopyMoveRect(DrawInfo); // ���µ�λ�û���
        end;
      end;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TCustomEasyGrid.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  DrawInfo: TEasyGridDrawInfo;
  Offset: Integer;
  NewSize: Integer;
  NewCurrent: TGridCoord;
  OldCopyMoveRect, NewSel: TGridRect;

  // ���� Sizing �������п��
  function ResizeLine(const AxisInfo: TEasyGridAxisDrawInfo): Integer;
  var
    Start, i : Integer;
  begin
    with AxisInfo do
    begin
      Result := TitleBoundary;
      Start := 1;
      if FSizingIndex > FixedCellCount then
      begin
        Start := FirstGridCell;
        Result := FixedBoundary;
      end;
      i := Start;
      while i < FSizingIndex do
      begin
        Inc(Result, GetExtent(i) + EffectiveLineWidth);
        Inc(i);
      end;
      if FSizingPos > Result then
         Result := FSizingPos - Result
      else
         Result := -1;
    end;
  end;

begin
  if Button = mbRight then Exit;
  try
    case FGridState of
      gsSelecting:
        begin
          MouseMove(Shift, X, Y);
          KillTimer(Handle, 1);
          UpdateEdit;
          Click;
        end;
      gsRowSizing, gsColSizing:
        begin
          CalcDrawInfo(DrawInfo);
          if (FGridState = gsColSizing) and CanDrawSizingLine(DrawInfo.Horz,FSizingPos, FGridState) or
             (FGridState = gsRowSizing) and CanDrawSizingLine(DrawInfo.Vert,FSizingPos, FGridState) then
             DrawSizingLine(DrawInfo);
          if FGridState = gsColSizing then
             begin
               NewSize := ResizeLine(DrawInfo.Horz);
               ColWidths[FSizingIndex] := NewSize;
               UpdateDesigner;
             end
          else
             begin
               NewSize := ResizeLine(DrawInfo.Vert);
               RowHeights[FSizingIndex] := NewSize;
               UpdateDesigner;
             end;
        end;
      gsFilling:
        begin
          if FFillStyle = fsHorzFill then Offset := FFillOffset.X
          else Offset := FFillOffset.Y;
          CalcDrawInfo(DrawInfo);
          DrawFillRect(DrawInfo);       // ��� Fill ���
          FillCells(TRect(FFillRect),Offset,FFillStyle);
        end;
      gsCopying,gsMoving:
        begin
          CalcDrawInfo(DrawInfo);
          DrawCopyMoveRect(DrawInfo); // ��� CopyMove ���
          // �ж��ܷ� CopyMove ��Ŀ������
          if not CanCopyMove then Exit;
          // ���ȷʵ��Ҫ CopyMove
          if (FCopyMoveOffset.X <> 0) or (FCopyMoveOffset.Y <> 0) then
          begin
            CopyCellsToBuffer(FCopyMoveRect);
            OldCopyMoveRect := FCopyMoveRect;
            // ����� Move ����Ҫ�ָ�ԭ��λ�õ� Cells
            if FGridState = gsMoving then
              RestoreCells(TRect(FCopyMoveRect));
            Inc(FCopyMoveRect.Left,   FCopyMoveOffset.X);
            Inc(FCopyMoveRect.Top,    FCopyMoveOffset.Y);
            Inc(FCopyMoveRect.Right,  FCopyMoveOffset.X);
            Inc(FCopyMoveRect.Bottom, FCopyMoveOffset.Y);
            PasteCellsFromBuffer(FCopyMoveRect);
            ClearClipBoardBuffer;
            NewSel := Selection;
            NewCurrent := FCurrent;
            Inc(NewCurrent.X,  FCopyMoveOffset.X);
            Inc(NewCurrent.Y,  FCopyMoveOffset.Y);
            Inc(NewSel.Left,   FCopyMoveOffset.X);
            Inc(NewSel.Right,  FCopyMoveOffset.X);
            Inc(NewSel.Top,    FCopyMoveOffset.Y);
            Inc(NewSel.Bottom, FCopyMoveOffset.Y);
            FocusCell(NewCurrent.X, NewCurrent.Y, True);
            Selection := NewSel;
            if Assigned(FOnCopyMoveCells) then
              FOnCopyMoveCells(Self, TRect(OldCopyMoveRect), TRect(FCopyMoveRect));
          end;
        end
    else
      UpdateEdit;
    end;
    inherited MouseUp(Button, Shift, X, Y);
  finally
    FGridState := gsNormal;
  end;
end;

function TCustomEasyGrid.GetColWidths(Index: Longint): Integer;
begin
  if (FColWidths = nil) or (Index < 0) or (Index >= ColCount) then
    Result := DefaultColWidth
  else
    Result := PIntArray(FColWidths)^[Index + 1];
end;

function TCustomEasyGrid.GetRowHeights(Index: Longint): Integer;
begin
  if (FRowHeights = nil) or (Index < 0) or (Index >= RowCount) then
    Result := DefaultRowHeight
  else
    Result := PIntArray(FRowHeights)^[Index + 1];
end;

function TCustomEasyGrid.GetGridWidth: Integer;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  Result := DrawInfo.Horz.GridBoundary;
end;

function TCustomEasyGrid.GetGridHeight: Integer;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  Result := DrawInfo.Vert.GridBoundary;
end;

function TCustomEasyGrid.GetSelection: TGridRect;
begin
  Result := GridRect(FSelStart, FSelEnd);
end;

function TCustomEasyGrid.GetColCanSizes(Index: Longint): Boolean;
begin
  if FColCanSizes = nil then Result := True
  else Result := Boolean(PIntArray(FColCanSizes)^[Index + 1]);
  if Index = 0 then Result := False; 
end;

function TCustomEasyGrid.GetRowCanSizes(Index: Longint): Boolean;
begin
  if FRowCanSizes = nil then Result := True
  else Result := Boolean(PIntArray(FRowCanSizes)^[Index + 1]);
  if Index = 0 then Result := False;
end;

function TCustomEasyGrid.GetTabStops(Index: Longint): Boolean;
begin
  if (FTabStops=nil) or (Index < 0) or (Index >= ColCount) then Result := True
  else Result := Boolean(PIntArray(FTabStops)^[Index + 1]);
end;

function TCustomEasyGrid.GetVisibleColCount: Integer;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  Result := DrawInfo.Horz.LastFullVisibleCell - LeftCol + 1;
end;

function TCustomEasyGrid.GetVisibleRowCount: Integer;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  CalcDrawInfo(DrawInfo);
  Result := DrawInfo.Vert.LastFullVisibleCell - TopRow + 1;
end;

procedure TCustomEasyGrid.SetBorderStyle(Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TCustomEasyGrid.SetCol(Value: Longint);
begin
  if Col <> Value then FocusCell(Value, Row, True);
end;

procedure TCustomEasyGrid.SetColCount(Value: Longint);
var
  i, j: Integer;
begin
  if (Value > 256) then
  begin
    if csDesigning in ComponentState then
       SayStop(NoMoreThan256Columns);
    Value := 256;
  end;
  if (Value < ColCount) then
    for i:=Value to ColCount-1 do
      for j:=1 to RowCount-1 do
        if CellInMerge(i, j) then Exit;
  if FColCount <> Value then
  begin
    if Value < 2 then Value := 2;// ����������(Title�к�������)
    if (Value-1) <= FixedCols then FixedCols := Value - 2;
    ColCountChange(Value);
    ChangeSize(Value, RowCount);
  end;
end;

procedure TCustomEasyGrid.SetColWidths(Index: Longint; Value: Integer);
begin
  // ���� ColWidths ����
  if FColWidths = nil then
    UpdateExtents(FColWidths, ColCount, DefaultColWidth);
  if (Index < 0) or (Index >= ColCount) then
     InvalidOp(SIndexOutOfRange);
  // �����п�ˢ����Ļ
  if Value <> PIntArray(FColWidths)^[Index + 1] then
  begin
    PIntArray(FColWidths)^[Index + 1] := Value;
    ResizeCol(Index, PIntArray(FColWidths)^[Index + 1], Value);
    ColWidthsChanged;
  end;
end;

procedure TCustomEasyGrid.SetDefaultColWidth(Value: Integer);
begin
  if FColWidths <> nil then UpdateExtents(FColWidths, ColCount, Value);
  FDefaultColWidth := Value;
  ColWidthsChanged;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.SetDefaultRowHeight(Value: Integer);
begin
  if FRowHeights <> nil then UpdateExtents(FRowHeights, RowCount, Value);
  FDefaultRowHeight := Value;
  RowHeightsChanged;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.SetFixedLineColor(Value: TColor);
begin
  if FFixedLineColor <> Value then
  begin
    FFixedLineColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetClientLineColor(Value: TColor);
begin
  if FClientLineColor <> Value then
  begin
    FClientLineColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetTitleColor(Value: TColor);
begin
  if FTitleColor <> Value then
  begin
    FTitleColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetHighLightColor(Value: TColor);
begin
  if FHighLightColor <> Value then
  begin
    FHighLightColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetHighLightTextColor(Value: TColor);
begin
  if FHighLightTextColor <> Value then
  begin
    FHighLightTextColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetFocusedTitleColor(Value: TColor);
begin
  if FFocusedTitleColor <> Value then
  begin
    FFocusedTitleColor := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetFixedCols(Value: Integer);
begin
  if (FFixedCols <> Value) and (Value < ColCount - 1) then
  begin
    if Value < 0 then InvalidOp(SIndexOutOfRange);
    if Value >= ColCount then InvalidOp(SFixedColTooBig);
    FFixedCols := Value;
    InitializeGrid;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetFixedRows(Value: Integer);
begin
  if (FFixedRows <> Value) and (Value < RowCount - 1) then
  begin
    if Value < 0 then InvalidOp(SIndexOutOfRange);
    if Value >= RowCount then InvalidOp(SFixedRowTooBig);
    FFixedRows := Value;
    InitializeGrid;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetEditorMode(Value: Boolean);
begin
  if not Value then
    HideEditor
  else
  begin
    ShowEditor;
    if FInplaceEdit <> nil then FInplaceEdit.Deselect;
  end;
end;

procedure TCustomEasyGrid.SetGridLineWidth(Value: Integer);
begin
  if FGridLineWidth <> Value then
  begin
    FGridLineWidth := Value;
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetLeftCol(Value: Longint);
begin
  if FTopLeft.X <> Value then MoveTopLeft(Value, TopRow);
end;

procedure TCustomEasyGrid.SetOptions(Value: TEasyGridOptions);
begin
  if FOptions <> Value then
  begin
    if goRowSelect in Value then
       Exclude(Value, goAlwaysShowEditor);
    FOptions := Value;
    if not FEditorMode then
       if goAlwaysShowEditor in Value then
          ShowEditor
       else
          HideEditor;
    if goRowSelect in Value then
       MoveCurrent(Col, Row,  True, False, True);
    InvalidateGrid;
  end;
end;

procedure TCustomEasyGrid.SetRow(Value: Longint);
begin
  if Row <> Value then FocusCell(Col, Value, True);
end;

procedure TCustomEasyGrid.SetRowCount(Value: Longint);
var
  i, j: Integer;
begin
  if (Value < RowCount) then
  for i:=1 to ColCount-1 do
    for j:=Value to RowCount-1 do
        if CellInMerge(i, j) then Exit;
  if FRowCount <> Value then
  begin
    if Value < 2 then Value := 2;
    if (Value-1) <= FixedRows then FixedRows := Value - 2;
    RowCountChange(Value);
    ChangeSize(ColCount, Value);
  end;
end;

procedure TCustomEasyGrid.SetRowHeights(Index: Longint; Value: Integer);
var
  OldValue: Integer;
begin
  // ���� RowHeights ����
  if FRowHeights = nil then
    UpdateExtents(FRowHeights, RowCount, DefaultRowHeight);
  if (Index < 0) or (Index >= RowCount) then
     InvalidOp(SIndexOutOfRange);
  // �����и߲�ˢ����Ļ
  if Value <> PIntArray(FRowHeights)^[Index + 1] then
  begin
    OldValue := PIntArray(FRowHeights)^[Index + 1];
    PIntArray(FRowHeights)^[Index + 1] := Value;
    ResizeRow(Index, OldValue, Value);
    RowHeightsChanged;
  end;
end;

procedure TCustomEasyGrid.SetScrollBars(Value: TScrollStyle);
begin
  if FScrollBars <> Value then
  begin
    FScrollBars := Value;
    RecreateWnd;
  end;
end;

function TCustomEasyGrid.RegularRange(ASel: TGridRect): Boolean;
var
  i: Integer;
begin
  Result := False;
  with ASel do
  begin
    for i:=Left to Right do
      if (Merges[i, Top].Top <> Top) or (Merges[i, Bottom].Bottom <> Bottom) then
         Exit;
    for i:=Top to Bottom do
      if (Merges[Left, i].Left <> Left) or (Merges[Right, i].Right <> Right) then
         Exit;
  end;
  Result := True;
end;

procedure TCustomEasyGrid.SetSelection(Value: TGridRect);
var
  OldSel: TGridRect;
begin
  OldSel := Selection;
  if (OldSel.Left = Value.Left) and (OldSel.Right = Value.Right) and
     (OldSel.Top = Value.Top) and (OldSel.Bottom = Value.Bottom) then Exit;
  Restrict(Value.TopLeft, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
  Restrict(Value.BottomRight, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
  Restrict(OldSel.TopLeft, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
  Restrict(OldSel.BottomRight, FixedCols + 1, FixedRows + 1, ColCount - 1, RowCount - 1);
  FSelStart := Value.TopLeft;
  FSelEnd := Value.BottomRight;
  SelectionMoved(OldSel);
end;

procedure TCustomEasyGrid.SetColCanSizes(Index: Longint; Value: Boolean);
begin
  if FColCanSizes = nil then
    UpdateExtents(FColCanSizes, ColCount, Integer(True));
  if (Index < 0) or (Index >= ColCount) then
     InvalidOp(SIndexOutOfRange);
  PIntArray(FColCanSizes)^[Index + 1] := Integer(Value);
end;

procedure TCustomEasyGrid.SetRowCanSizes(Index: Longint; Value: Boolean);
begin
  if FRowCanSizes = nil then
    UpdateExtents(FRowCanSizes, RowCount, Integer(True));
  if (Index < 0) or (Index >= RowCount) then
     InvalidOp(SIndexOutOfRange);
  PIntArray(FRowCanSizes)^[Index + 1] := Integer(Value);
end;

procedure TCustomEasyGrid.SetTabStops(Index: Longint; Value: Boolean);
begin
  if FTabStops = nil then
     UpdateExtents(FTabStops, ColCount, Integer(True));
  if (Index < 0) or (Index >= ColCount) then
     InvalidOp(SIndexOutOfRange);
  PIntArray(FTabStops)^[Index + 1] := Integer(Value);
end;

procedure TCustomEasyGrid.SetTopRow(Value: Longint);
begin
  if FTopLeft.Y <> Value then MoveTopLeft(LeftCol, Value);
end;

procedure TCustomEasyGrid.HideEdit;
begin
  if FInplaceEdit <> nil then
    try
      UpdateText;
      if (FInplaceCol <> -1) and (FInplaceRow <> -1) and Assigned(FOnHideEdit) then
        FOnHideEdit(Self, FInplaceCol, FInplaceRow, FInplaceEdit.Text);
    finally
      FInplaceCol := -1;
      FInplaceRow := -1;
      FInplaceEdit.Hide;
    end;
end;

procedure TCustomEasyGrid.UpdateEdit;
var
  MoveRect: TRect;

  procedure UpdateEditor;
  begin
    FInplaceCol := Col;
    FInplaceRow := Row;
    FInplaceEdit.UpdateContents;
    if FInplaceEdit.MaxLength = -1 then FCanEditModify := False
    else FCanEditModify := True;
    if FInplaceEdit.Text <> '' then
      SendMessage(FInplaceEdit.Handle, EM_SETSEL, Length(FInplaceEdit.Text), Length(FInplaceEdit.Text));
  end;

begin
  // ������ʾ Editor
  if CanEditShow then
  begin
    if FInplaceEdit = nil then
    begin
      FInplaceEdit := CreateEditor;
      FInplaceEdit.ParentGrid := Self;
      FInplaceEdit.Parent := Self;
      UpdateEditor;
    end
    else
    begin
      if (Col <> FInplaceCol) or (Row <> FInplaceRow) then
      begin
        HideEdit;
        UpdateEditor;
      end;
    end;
    if CanEditShow then
       begin
         MoveRect.Left := CellRect(Merges[Col, Row].Left, Merges[Col, Row].Top).Left;
         MoveRect.Top := CellRect(Merges[Col, Row].Left, Merges[Col, Row].Top).Top;
         MoveRect.Right := CellRect(Merges[Col, Row].Right, Merges[Col, Row].Bottom).Right;
         MoveRect.Bottom := CellRect(Merges[Col, Row].Right, Merges[Col, Row].Bottom).Bottom;
         InflateRect(MoveRect, -2, -2);
         FInplaceEdit.Move(MoveRect);
       end;
  end;
end;

procedure TCustomEasyGrid.UpdateText;
begin
  if (FInplaceCol <> -1) and (FInplaceRow <> -1) then
    SetEditText(FInplaceCol, FInplaceRow, FInplaceEdit.Text);
end;

procedure TCustomEasyGrid.WMChar(var Msg: TWMChar);
begin
  if (goEditing in Options) and (Char(Msg.CharCode) in [^H, #32..#255]) then
    ShowEditorChar(Char(Msg.CharCode))
  else
    inherited;
end;

procedure TCustomEasyGrid.WMCommand(var Message: TWMCommand);
begin
  with Message do
  begin
    {
    if (FInplaceEdit <> nil) and (Ctl = FInplaceEdit.Handle) then
      case NotifyCode of
        EN_CHANGE: UpdateText;
      end;
    }
  end;
end;

procedure TCustomEasyGrid.WMEraseBkGnd(var Message: TWMCommand);
begin
  Message.Result := 1;
end;

procedure TCustomEasyGrid.WMGetDlgCode(var Msg: TWMGetDlgCode);
begin
  Msg.Result := DLGC_WANTARROWS;
  if goRowSelect in Options then Exit;
  if goTabs in Options then Msg.Result := Msg.Result or DLGC_WANTTAB;
  if goEditing in Options then Msg.Result := Msg.Result or DLGC_WANTCHARS;
end;

procedure TCustomEasyGrid.WMKillFocus(var Msg: TWMKillFocus);
begin
  inherited;
  InvalidateRect(Selection);
  if (FInplaceEdit <> nil) and (Msg.FocusedWnd <> FInplaceEdit.Handle) then
    HideEditor;
end;

procedure TCustomEasyGrid.WMLButtonDown(var Message: TMessage);
begin
  inherited;
  if FInplaceEdit <> nil then FInplaceEdit.FClickTime := GetMessageTime;
end;

procedure TCustomEasyGrid.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  DefaultHandler(Msg);
  FHitTest := ScreenToClient(SmallPointToPoint(Msg.Pos));
end;

// ������չ״̬( Copying, Filling, Moving )
procedure TCustomEasyGrid.CalcExtendedState(X, Y: Integer;
          var State: TEasyGridState; DrawInfo: TEasyGridDrawInfo);
var
  CellHit: TGridCoord;
  Sel: TGridRect;
  ExtSelRect, SelRect: TRect;
  CtrlDown: Boolean;
begin
  State := gsNormal;
  if (X < 0) or (Y < 0) or (not FGridCanCopyMove and not FGridCanFill) then Exit;
  Sel := Selection;
  if (not RegularRange(Sel)) then Exit;
  CtrlDown := False;
  if GetKeyState(VK_CONTROL) < 0 then
    CtrlDown := True;
  CellHit := CalcCoordFromPoint(X, Y, DrawInfo);
  GridRectToScreenRect(Sel, SelRect, True);
  ExtSelRect := SelRect;
  InflateRect(ExtSelRect, 3, 3);
  // ��������ǰ Cell �ĺ�ɫ�ֱ�(�������ؿ�),���ʾ�����ƶ�״̬
  if ((X > ExtSelRect.Left) and (X < ExtSelRect.Right) and
      (Y > ExtSelRect.Top)  and (Y < ExtSelRect.Bottom)) and
     (((Abs(X - SelRect.Left) < 3) or (Abs(X - SelRect.Right) < 4) or
       (Abs(Y - SelRect.Top) < 3)  or (Abs(Y - SelRect.Bottom) < 4))) then
     State := gsMoving;
  if (State = gsMoving) then
    // ��� Ctrl ������,���ʾ���ڿ���״̬
    if CtrlDown then
      State := gsCopying
    // ��������ǰ Cell �ĺ�ɫ�ֱߵ����½�,���ʾ�������״̬
    else if (Abs(X - SelRect.Right) <= 4) and (Abs(Y - SelRect.Bottom) <= 5) then
      State := gsFilling;
  if (((State = gsMoving) or (State = gsCopying)) and (not FGridCanCopyMove)) or
      ((State = gsFilling) and (not FGridCanFill)) then State := gsNormal;
end;

procedure TCustomEasyGrid.WMSetCursor(var Msg: TWMSetCursor);
var
  DrawInfo: TEasyGridDrawInfo;
  State: TEasyGridState;
  Index: Longint;
  Pos, Ofs: Integer;
  Cur: HCURSOR;
begin
  Cur := Screen.Cursors[crArrow];
  CalcDrawInfo(DrawInfo);
  with Msg do
  begin
    if HitTest = HTCLIENT then
    begin
      State := FGridState;
      if State = gsNormal then
      begin
        Cur := Screen.Cursors[crExcel];
        CalcSizingState(FHitTest.X, FHitTest.Y, State, Index, Pos, Ofs,
          DrawInfo);
        if State = gsNormal then
          CalcExtendedState(FHitTest.X, FHitTest.Y, State, DrawInfo);
      end;
      case State of
        gsRowSizing :
          Cur := Screen.Cursors[crVSplit];
        gsColSizing :
          Cur := Screen.Cursors[crHSplit];
        gsCopying :
          Cur := Screen.Cursors[crDrag];
        gsFilling :
          Cur := Screen.Cursors[crMultiDrag];
        gsMoving :
          Cur := Screen.Cursors[crHandPoint];
      end;
      if Cur <> 0 then SetCursor(Cur)
      else inherited;
    end;
  end;
end;

procedure TCustomEasyGrid.WMSetFocus(var Msg: TWMSetFocus);
begin
  inherited;
  if (FInplaceEdit = nil) or (Msg.FocusedWnd <> FInplaceEdit.Handle) then
  begin
    InvalidateRect(Selection);
    UpdateEdit;
  end;
end;

procedure TCustomEasyGrid.WMSize(var Msg: TWMSize);
begin
  inherited;
  UpdateScrollRange;
end;

procedure TCustomEasyGrid.WMVScroll(var Msg: TWMVScroll);
begin
  ModifyScrollBar(SB_VERT, Msg.ScrollCode, Msg.Pos, True);
end;

procedure TCustomEasyGrid.WMHScroll(var Msg: TWMHScroll);
begin
  ModifyScrollBar(SB_HORZ, Msg.ScrollCode, Msg.Pos, True);
end;

procedure TCustomEasyGrid.CancelMode;
var
  DrawInfo: TEasyGridDrawInfo;
begin
  try
    case FGridState of
      gsSelecting:
        KillTimer(Handle, 1);
      gsRowSizing, gsColSizing:
        begin
          CalcDrawInfo(DrawInfo);
          DrawSizingLine(DrawInfo);
        end;
    end;
  finally
    FGridState := gsNormal;
  end;
end;

procedure TCustomEasyGrid.WMCancelMode(var Msg: TWMCancelMode);
begin
  inherited;
  CancelMode;
end;

procedure TCustomEasyGrid.CMCancelMode(var Msg: TMessage);
begin
  if Assigned(FInplaceEdit) then FInplaceEdit.WndProc(Msg);
  inherited;
  CancelMode;
end;

procedure TCustomEasyGrid.CMFontChanged(var Message: TMessage);
begin
  if FInplaceEdit <> nil then FInplaceEdit.Font := Font;
  inherited;
end;

procedure TCustomEasyGrid.CMCtl3DChanged(var Message: TMessage);
begin
  inherited;
  RecreateWnd;
end;

procedure TCustomEasyGrid.CMDesignHitTest(var Msg: TCMDesignHitTest);
begin
  Msg.Result := Longint(BOOL(Sizing(Msg.Pos.X, Msg.Pos.Y)));
end;

procedure TCustomEasyGrid.CMWantSpecialKey(var Msg: TCMWantSpecialKey);
begin
  inherited;
  if (goEditing in Options) and (Char(Msg.CharCode) = #13) then Msg.Result := 1;
end;

procedure TCustomEasyGrid.TimedScroll(Direction: TEasyGridScrollDirection);
var
  MaxAnchor, NewAnchor: TGridCoord;
  NewSel: TGridRect;
begin
  NewAnchor := FAnchor;
  NewSel := Selection;
  MaxAnchor.X := ColCount - 1;
  MaxAnchor.Y := RowCount - 1;
  if (sdLeft in Direction) and (FAnchor.X > FixedCols+1) then
     Dec(NewAnchor.X);
  if (sdRight in Direction) and (FAnchor.X < MaxAnchor.X) then
     Inc(NewAnchor.X);
  if (sdUp in Direction) and (FAnchor.Y > FixedRows+1) then
     Dec(NewAnchor.Y);
  if (sdDown in Direction) and (FAnchor.Y < MaxAnchor.Y) then
     Inc(NewAnchor.Y);
  if (FAnchor.X <> NewAnchor.X) or (FAnchor.Y <> NewAnchor.Y) then
     MoveAnchor(NewAnchor, False);
  NewSel := CalcMaxRange(FCurrent, NewAnchor);
  Selection := NewSel;
end;

procedure TCustomEasyGrid.WMTimer(var Msg: TWMTimer);
var
  Point: TPoint;
  DrawInfo: TEasyGridDrawInfo;
  ScrollDirection: TEasyGridScrollDirection;
  CellHit: TGridCoord;
begin
  if not (FGridState in [gsSelecting]) then Exit;
  GetCursorPos(Point);
  Point := ScreenToClient(Point);
  CalcDrawInfo(DrawInfo);
  ScrollDirection := [];
  with DrawInfo do
  begin
    CellHit := CalcCoordFromPoint(Point.X, Point.Y, DrawInfo);
    case FGridState of
      gsSelecting:
      begin
        if Point.X < Horz.FixedBoundary then Include(ScrollDirection, sdLeft)
        else if Point.X > Horz.FullVisBoundary then Include(ScrollDirection, sdRight);
        if Point.Y < Vert.FixedBoundary then Include(ScrollDirection, sdUp)
        else if Point.Y > Vert.FullVisBoundary then Include(ScrollDirection, sdDown);
        if ScrollDirection <> [] then TimedScroll(ScrollDirection);
      end;
    end;
  end;
end;

procedure TCustomEasyGrid.SetColTitle(Value: Boolean);
begin
  if FShowColTitle <> Value then
  begin
    FShowColTitle := Value;
    Invalidate;
  end;
end;

procedure TCustomEasyGrid.SetRowTitle(Value: Boolean);
begin
  if FShowRowTitle <> Value then
  begin
    FShowRowTitle := Value;
    Invalidate;
  end;
end;

procedure TCustomEasyGrid.SetAutoUpdate(Value: Boolean);
begin
  FAutoUpdate := Value;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.ColWidthsChanged;
begin
  UpdateScrollRange;
  UpdateEdit;
end;

procedure TCustomEasyGrid.RowHeightsChanged;
begin
  UpdateScrollRange;
  UpdateEdit;
end;

procedure TCustomEasyGrid.UpdateDesigner;
var
  ParentForm: TCustomForm;
begin
  if (csDesigning in ComponentState) and HandleAllocated and
    not (csUpdating in ComponentState) then
  begin
    ParentForm := GetParentForm(Self);
    if Assigned(ParentForm) and Assigned(ParentForm.Designer) then
      ParentForm.Designer.Modified;
  end;
end;

function TCustomEasyGrid.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelDown(Shift, MousePos);
  if not Result then
  begin
    if Row < RowCount - 1 then Row := Row + 1;
    Result := True;
  end;
end;

function TCustomEasyGrid.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheelUp(Shift, MousePos);
  if not Result then
  begin
    if Row > FixedRows+1 then Row := Row - 1;
    Result := True;
  end;
end;

procedure TCustomEasyGrid.CMShowingChanged(var Message: TMessage);
begin
  inherited;
  if Showing then UpdateScrollRange;
end;

{TCustomEasyGrid User Define}
function TCustomEasyGrid.GetColors(ACol, ARow: Integer): TColor;
begin
  Result := Cells[ACol,ARow].Color;
end;

procedure TCustomEasyGrid.SetColors(ACol, ARow: Integer; Value: TColor);
var
  ARect: TRect;
begin
  Cells[ACol,ARow].Color := Value;
  ARect := CellRect(ACol, ARow);
  Dec(ARect.Left);
  Dec(ARect.Top);
  Inc(ARect.Right);
  Inc(ARect.Bottom);
  if AutoUpdate then
  begin
    Windows.InvalidateRect(Handle, @ARect, False);
    UpdateWindow(Handle);
  end;
end;

function TCustomEasyGrid.GetMerges(ACol, ARow: Integer): PGridRect;
begin
  Result := @Cells[ACol,ARow].Merge;
end;

function TCustomEasyGrid.GetCell(ACol, ARow: Integer): PCellInfo;
begin
  Result := PCellInfo(TColCellInfoList(FCells.Items[ACol]).Items[ARow]);
end;

procedure TCustomEasyGrid.SetMerges(AMergeRect: TRect; WantPrompt: Boolean = False);
var
  i, j, ValueCellCount: Integer;
  ValueCell: TGridCoord;
  ValueCellInfo: TCellInfo;
begin
  with AMergeRect do
  // �ж��ܷ�ϲ�
  if ((Left = 0) or (Right = 0) or (Top = 0) or (Bottom = 0) or // ���ܺϲ�������
      (Left > Right) or (Top > Bottom) or                       // �߽�ֵ���ܴ�λ
      ((Left = Right) and (Top = Bottom)) or                    // û�б�Ҫ�ϲ�
      ((Left <= FixedCols) and (Right > FixedCols) and (Top > FixedRows)) or // ���ܿ����ϲ�
      ((Top <= FixedRows) and (Bottom > FixedRows) and (Left > FixedCols))) then Exit;
  // ��������кϲ������ͻ���ܺϲ�
  if MergeRectIntersects(TGridRect(AMergeRect)) then Exit;
  // ���������Ͻǵķǿ� Cell
  ValueCell := TGridCoord(AMergeRect.TopLeft);
  ValueCellCount := 0;
  for j := AMergeRect.Bottom downto AMergeRect.Top do
    for i := AMergeRect.Right downto AMergeRect.Left do
    if (Cells[i, j].ForeText <> '') or (Cells[i, j].BackText <> '') then
    begin
      Inc(ValueCellCount);
      ValueCell.X := i;
      ValueCell.Y := j;
    end;
  if WantPrompt and (ValueCellCount > 1) and
     (not Ask(DiscardMultipleCellValues, 2))then Exit;
  ValueCellInfo := Cells[ValueCell.X, ValueCell.Y]^;
  for i := AMergeRect.Left to AMergeRect.Right do
    for j := AMergeRect.Top to AMergeRect.Bottom do
    begin
      Cells[i,j].Merge := AMergeRect;
      CellToCell(@ValueCellInfo, Cells[i, j]);
      if (i <> AMergeRect.Left) or (j <> AMergeRect.Top) then
      begin
        Cells[i,j].ForeText := '';
        Cells[i,j].BackText := '';
      end;
    end;
  if PointInGridRect(FCurrent.X, FCurrent.Y, TGridRect(AMergeRect)) and
     not (goRowSelect in Options) then
  begin
    FSelStart := TGridCoord(AMergeRect.TopLeft);
    FSelEnd := TGridCoord(AMergeRect.BottomRight);
  end;
  InvalidateRect(TGridRect(AMergeRect));
end;

procedure TCustomEasyGrid.DeleteMerges(AMergeRect: TRect);
var
  i, j: Integer;
begin                
  Restrict(TGridCoord(AMergeRect.TopLeft), 1, 1, ColCount - 1, RowCount - 1);
  Restrict(TGridCoord(AMergeRect.BottomRight), 1, 1, ColCount - 1, RowCount - 1);
  if (AMergeRect.Left = AMergeRect.Right) and (AMergeRect.Top = AMergeRect.Bottom) then Exit;
  // ��������кϲ������ͻ����ɾ��
  if MergeRectIntersects(TGridRect(AMergeRect)) then Exit;
  for i := AMergeRect.Left to AMergeRect.Right do
    for j := AMergeRect.Top to AMergeRect.Bottom do
    begin
      Cells[i,j].Merge.Left := i;
      Cells[i,j].Merge.Right := i;
      Cells[i,j].Merge.Top := j;
      Cells[i,j].Merge.Bottom := j;
    end;
  InvalidateRect(TGridRect(AMergeRect));
end;

procedure TCustomEasyGrid.LoadFromFile(FileName: string);
var
  FileStream: TFileStream;
  SaveAutoUpdate: Boolean;
begin
  SaveAutoUpdate := FAutoUpdate;
  AutoUpdate := False;
  FileStream := TFileStream.Create(FileName,fmOpenRead);
  try
    LoadFromStream(FileStream);
  finally
    FileStream.Free;
  end;
  AutoUpdate := True;
  FAutoUpdate := SaveAutoUpdate;
end;

procedure TCustomEasyGrid.LoadFromStream(FileStream: TFileStream);

  procedure ReadSegmentFlag;
  var
    SegmentFlag: Byte;
  begin
    FileStream.Read(SegmentFlag, SizeOf(SegmentFlag));
    if (SegmentFlag <> SegmentFlagValue) then Raise Exception.Create(BadFileInfo);
  end;

var
  GridColCount, GridRowCount, i, j, CellSize: Integer;
  IntValue: Integer;
  BoolValue: Boolean;
  ColorValue: TColor;
  ABorderStyle: TBorderStyle;
  AScrollBars: TScrollStyle;
  AOptions: TEasyGridOptions;
  ADataStyle: TDataStyle;
  AAlignMode: TAlignMode;
  APenStyle: TPenStyle;
  AFontStyle: TFontStyles;
  AFontName, FileHeader: string;
  CellBuffer: array of Char;
begin
  // �����ʶ����
  SetLength(FileHeader, Length(VersionInfo));
  FileStream.Read(FileHeader[1], Length(VersionInfo));
  if (FileHeader <> VersionInfo) then Raise Exception.Create(NotAEasyGridFile);
  FileStream.Seek(ReservedSpace * SizeOf(Integer) - Length(VersionInfo), soFromCurrent);
  ReadSegmentFlag;
  RestoreCells(Rect(1,1,ColCount-1,RowCount-1));

  FileStream.Read(GridColCount, SizeOf(Integer));
  ColCount := GridColCount;
  FileStream.Read(GridRowCount, SizeOf(Integer));
  RowCount := GridRowCount;
  FileStream.Read(IntValue, SizeOf(Integer));
  DefaultColWidth := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  DefaultRowHeight := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  FixedCols := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  FixedRows := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  GridLineWidth := IntValue;

  FileStream.Read(BoolValue, SizeOf(Boolean));
  GridCanCopyMove := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  GridCanFill := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  ShowPopup := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  ShowColTitle := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  ShowRowTitle := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  DefaultDrawing := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  AlwaysDrawFocus := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  ClientSizeable := BoolValue;

  FileStream.Read(ColorValue, SizeOf(TColor));
  FixedLineColor := ColorValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  ClientLineColor := ColorValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  TitleColor := ColorValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  HighLightColor := ColorValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  HighLightTextColor := ColorValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  FocusedTitleColor := ColorValue;

  FileStream.Read(ABorderStyle, SizeOf(TBorderStyle));
  BorderStyle := ABorderStyle;
  FileStream.Read(AScrollBars, SizeOf(TScrollStyle));
  ScrollBars := AScrollBars;
  FileStream.Read(AOptions, SizeOf(TEasyGridOptions));
  Options := AOptions;

  FileStream.Read(ADataStyle, SizeOf(TDataStyle));
  CellDataStyle := ADataStyle;
  FileStream.Read(AAlignMode, SizeOf(TAlignMode));
  CellAlignMode := AAlignMode;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellShowForeText := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellReadOnly := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellAutoWordBreak := BoolValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  CellLineWidth := IntValue;
  FileStream.Read(APenStyle, SizeOf(TPenStyle));
  CellPenStyle := APenStyle;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellAllowNegative := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellTrailingZero := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellZeroNull := BoolValue;
  FileStream.Read(BoolValue, SizeOf(Boolean));
  CellThousandSep := BoolValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  CellMaxLength := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  CellIntLength := IntValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  CellDecLength := IntValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  CellColor := ColorValue;
  FileStream.Read(IntValue, SizeOf(Integer));
  CellFontSize := IntValue;
  FileStream.Read(ColorValue, SizeOf(TColor));
  CellFontColor := ColorValue;
  FileStream.Read(AFontStyle, SizeOf(TFontStyles));
  CellFontStyle := AFontStyle;
  FileStream.Read(IntValue, SizeOf(Integer));
  SetLength(AFontName, IntValue);
  FileStream.Read(AFontName[1],IntValue);
  FFontName := AFontName;
  ReadSegmentFlag;
  for i:=0 to GridColCount-1 do
  begin
    FileStream.Read(IntValue, SizeOf(Integer));
    ColWidths[i] := IntValue;
  end;
  ReadSegmentFlag;
  for i:=0 to GridColCount-1 do
  begin
    FileStream.Read(IntValue, SizeOf(Integer));
    TabStops[i] := Boolean(IntValue);
  end;
  ReadSegmentFlag;
  for i:=0 to GridColCount-1 do
  begin
    FileStream.Read(IntValue, SizeOf(Integer));
    ColCanSizes[i] := Boolean(IntValue);
  end;
  ReadSegmentFlag;
  for i:=0 to GridRowCount-1 do
  begin
    FileStream.Read(IntValue, SizeOf(Integer));
    RowHeights[i] := IntValue;
  end;
  ReadSegmentFlag;
  for i:=0 to GridRowCount-1 do
  begin
    FileStream.Read(IntValue, SizeOf(Integer));
    RowCanSizes[i] := Boolean(IntValue);
  end;
  ReadSegmentFlag;
  EasyGridPageInfo.LoadFromStream(FileStream);

  for i:=0 to GridColCount-1 do
    for j:=0 to GridRowCount-1 do
    begin
      FileStream.Read(CellSize, SizeOf(Integer));
      SetLength(CellBuffer, CellSize);
      FileStream.Seek(-SizeOf(Integer), soFromCurrent);
      FileStream.Read(CellBuffer[0], CellSize);
      ReadCellFromBuffer(@CellBuffer,Cells[i, j]);
      ReadSegmentFlag;
    end;
  Finalize(CellBuffer);
  InitializeGrid;
end;

procedure TCustomEasyGrid.SaveToFile(FileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TCustomEasyGrid.SaveToStream(FileStream: TFileStream);
var
  i, j, CellSize, StrLen: Integer;
  CellBuffer: array of Char;
  SegmentFlag: Byte;
begin
  SegmentFlag := SegmentFlagValue;
  // д�뱣������
  SetLength(CellBuffer, ReservedSpace * SizeOf(Integer));
  Move(VersionInfo[1], CellBuffer[0], Length(VersionInfo));
  FileStream.Write(CellBuffer[0], ReservedSpace * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  Finalize(CellBuffer);

  FileStream.Write(FColCount,SizeOf(Integer));
  FileStream.Write(FRowCount,SizeOf(Integer));
  FileStream.Write(FDefaultColWidth,SizeOf(Integer));
  FileStream.Write(FDefaultRowHeight,SizeOf(Integer));
  FileStream.Write(FFixedCols,SizeOf(Integer));
  FileStream.Write(FFixedRows,SizeOf(Integer));
  FileStream.Write(FGridLineWidth,SizeOf(Integer));

  FileStream.Write(FGridCanCopyMove,SizeOf(Boolean));
  FileStream.Write(FGridCanFill,SizeOf(Boolean));
  FileStream.Write(FShowPopup,SizeOf(Boolean));
  FileStream.Write(FShowColTitle,SizeOf(Boolean));
  FileStream.Write(FShowRowTitle,SizeOf(Boolean));
  FileStream.Write(FDefaultDrawing,SizeOf(Boolean));
  FileStream.Write(FAlwaysDrawFocus,SizeOf(Boolean));
  FileStream.Write(FClientSizeable,SizeOf(Boolean));

  FileStream.Write(FFixedLineColor,SizeOf(TColor));
  FileStream.Write(FClientLineColor,SizeOf(TColor));
  FileStream.Write(FTitleColor,SizeOf(TColor));
  FileStream.Write(FHighLightColor,SizeOf(TColor));
  FileStream.Write(FHighLightTextColor,SizeOf(TColor));
  FileStream.Write(FFocusedTitleColor,SizeOf(TColor));

  FileStream.Write(FBorderStyle,SizeOf(TBorderStyle));
  FileStream.Write(FScrollBars,SizeOf(TScrollStyle));
  FileStream.Write(FOptions,SizeOf(TEasyGridOptions));

  FileStream.Write(FDataStyle,SizeOf(TDataStyle));
  FileStream.Write(FAlignMode,SizeOf(TAlignMode));
  FileStream.Write(FShowForeText,SizeOf(Boolean));
  FileStream.Write(FReadOnly,SizeOf(Boolean));
  FileStream.Write(FAutoWordBreak,SizeOf(Boolean));
  FileStream.Write(FCellLineWidth,SizeOf(Integer));
  FileStream.Write(FCellPenStyle,SizeOf(TPenStyle));
  FileStream.Write(FAllowNegative,SizeOf(Boolean));
  FileStream.Write(FTrailingZero,SizeOf(Boolean));
  FileStream.Write(FZeroNull,SizeOf(Boolean));
  FileStream.Write(FThousandSep,SizeOf(Boolean));
  FileStream.Write(FMaxLength,SizeOf(Integer));
  FileStream.Write(FIntLength,SizeOf(Integer));
  FileStream.Write(FDecLength,SizeOf(Integer));
  FileStream.Write(FColor,SizeOf(TColor));
  FileStream.Write(FFontSize,SizeOf(Integer));
  FileStream.Write(FFontColor,SizeOf(TColor));
  FileStream.Write(FFontStyle,SizeOf(TFontStyles));
  StrLen := Length(FFontName);
  FileStream.Write(StrLen,SizeOf(Integer));
  FileStream.Write(FFontName[1],StrLen);

  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  if FColWidths = nil then
    UpdateExtents(FColWidths, ColCount, DefaultColWidth);
  FileStream.Write(PIntArray(FColWidths)^[1],  ColCount * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  if FTabStops = nil then
    UpdateExtents(FTabStops, ColCount, Integer(True));
  FileStream.Write(PIntArray(FTabStops)^[1],   ColCount * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  if FColCanSizes = nil then
    UpdateExtents(FColCanSizes, ColCount, Integer(True));
  FileStream.Write(PIntArray(FColCanSizes)^[1],ColCount * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  if FRowHeights = nil then
    UpdateExtents(FRowHeights, RowCount, DefaultRowHeight);
  FileStream.Write(PIntArray(FRowHeights)^[1], RowCount * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  if FRowCanSizes = nil then
    UpdateExtents(FRowCanSizes, RowCount, Integer(True));
  FileStream.Write(PIntArray(FRowCanSizes)^[1],RowCount * SizeOf(Integer));
  FileStream.Write(SegmentFlag, SizeOf(SegmentFlag)); // �����־
  EasyGridPageInfo.SaveToStream(FileStream);

  for i:=0 to ColCount-1 do
    for j:=0 to RowCount-1 do
    begin
      CellSize := CalcCellSize(Cells[i, j]);
      WriteCellToBuffer(Cells[i, j],@CellBuffer);
      FileStream.Write(PChar(CellBuffer)^, CellSize);
      FileStream.Write(SegmentFlag, SizeOf(SegmentFlag));
    end;
  Finalize(CellBuffer);
end;

procedure TCustomEasyGrid.MouseToCell(X, Y: Integer; var ACol, ARow: Longint);
var
  Coord: TGridCoord;
begin
  Coord := MouseCoord(X, Y);
  ACol := Coord.X;
  ARow := Coord.Y;
end;

function TCustomEasyGrid.GetEditText(ACol, ARow: Longint): string;
begin
  if Cells[ACol, ARow].ShowForeText then
    Result := ForeTexts[Merges[ACol, ARow].Left, Merges[ACol, ARow].Top]
  else
    Result := BackTexts[Merges[ACol, ARow].Left, Merges[ACol, ARow].Top];
  if Assigned(FOnGetEditText) then FOnGetEditText(Self, ACol, ARow, Result);
end;

procedure TCustomEasyGrid.SetEditText(ACol, ARow: Longint; Value: string);
begin
  DisableEditUpdate;
  try
    with Cells[FInplaceCol, FInplaceRow]^ do
    begin
      if ShowForeText and (Value <> ForeText) then
        ForeTexts[FInplaceCol, FInplaceRow] := Value
      else if (not ShowForeText) and (Value <> BackText) then
        BackTexts[FInplaceCol, FInplaceRow] := Value;
    end;
  finally
    EnableEditUpdate;
  end;
  if Assigned(FOnSetEditText) then FOnSetEditText(Self, ACol, ARow, Value);
end;

function TCustomEasyGrid.GetAlignMode(ACol, ARow: Integer): TAlignMode;
begin
  Result := Cells[ACol,ARow].AlignMode;
end;

procedure TCustomEasyGrid.SetAlignMode(ACol, ARow: Integer; AlignMode: TAlignMode);
var
  ARect: TRect;
begin
  Cells[ACol,ARow].AlignMode := AlignMode;
  ARect := CellRect(ACol, ARow);
  Dec(ARect.Left);
  Dec(ARect.Top);
  Inc(ARect.Right);
  Inc(ARect.Bottom);
  if AutoUpdate then
  begin
    Windows.InvalidateRect(Handle, @ARect, False);
    UpdateWindow(Handle);
  end;
end;

function TCustomEasyGrid.GetForeText(ACol, ARow: Integer): String;
begin
  Result := Cells[ACol,ARow].ForeText;
end;

procedure TCustomEasyGrid.SetForeText(ACol, ARow: Integer; Value: String);
begin
  if ForeTexts[ACol, ARow] <> Value then 
  with Cells[ACol, ARow]^ do
  begin
    if (DataStyle = dsNumber) then
    begin
      try
        Value := StrToMoney(Value, IntLength, DecLength, TrailingZero, ZeroNull, ThousandSep);
      except
        SayStop('��Ԫ��'+'['+IntToStr(ACol)+','+IntToStr(ARow)+']'+InvalidNumber);
        Exit;
      end;
    end;
    if (DataStyle = dsDate) and (Value <> '') then
    begin
      try
        Value := FormatDateTime('yyyy-mm-dd',StrToDate(Value));
      except
        SayStop('��Ԫ��'+'['+IntToStr(ACol)+','+IntToStr(ARow)+']'+InvalidDate);
        Exit;
      end;
    end;
    if (DataStyle = dsTime) and (Value <> '')  then
    begin
      try
        Value := FormatDateTime('hh:nn:ss',StrToTime(Value));
      except
        SayStop('��Ԫ��'+'['+IntToStr(ACol)+','+IntToStr(ARow)+']'+InvalidTime);
        Exit;
      end;
    end;
    ForeText := Value;
    if ShowForeText then
      InvalidateRect(TGridRect(Merge));
  end;
  if Assigned(FOnSetForeText) then
    FOnSetForeText(Self, ACol, ARow, Cells[ACol, ARow].ForeText);
end;

function TCustomEasyGrid.GetBackText(ACol, ARow: Integer): String;
begin
  Result := Cells[ACol,ARow].BackText;
end;

procedure TCustomEasyGrid.SetBackText(ACol, ARow: Integer; Value: String);
begin
  if BackTexts[ACol, ARow] <> Value then 
  with Cells[ACol,ARow]^ do
  begin
    BackText := Value;
    if not ShowForeText then
      InvalidateRect(TGridRect(Merge));
  end;
  if Assigned(FOnSetBackText) then
    FOnSetBackText(Self, ACol, ARow, Cells[ACol,ARow].BackText);
end;

procedure TCustomEasyGrid.DisableEditUpdate;
begin
  Inc(FEditUpdate);
end;

procedure TCustomEasyGrid.EnableEditUpdate;
begin
  Dec(FEditUpdate);
end;

function TCustomEasyGrid.CalcCellSize(ACell: PCellInfo): Integer;
begin
  // �̶����ֳ���
  Result := CellFixedPartSize;
  // string ����(����� 4 λ���� string ���ֽ���)
  with ACell^ do
  begin
    Inc(Result, Length(FontName) + SizeOf(Integer));
    Inc(Result, Length(ForeText) + SizeOf(Integer));
    Inc(Result, Length(BackText) + SizeOf(Integer));
  end;
  Inc(Result, SizeOf(Integer));
end;

procedure TCustomEasyGrid.ReadCellFromBuffer(SrcBuffer: PCharArray; DestCell: PCellInfo);
var
  Pos: Integer; // Pos Ϊָ�򻺳�����ƫ����

  procedure ReadString(var Str: string);
  var
    Len: Integer;
  begin
    MoveMemory(@Len, @SrcBuffer^[Pos], SizeOf(Integer)); // ȡ����
    SetLength(Str, Len);
    Inc(Pos, SizeOf(Integer));                           // ȡ����ʼ
    MoveMemory(Pointer(Str), @SrcBuffer^[Pos], Len);
    Inc(Pos, Len);
  end;

begin
  // ����ǰ CellFixedPartSize �ֽڵĹ̶�����
  MoveMemory(DestCell, @SrcBuffer^[SizeOf(Integer)], CellFixedPartSize);
  Pos := CellFixedPartSize + SizeOf(Integer);

  ReadString(DestCell.FontName); // ������һ����
  ReadString(DestCell.ForeText); // �����ڶ�����
  ReadString(DestCell.BackText); // ������������
end;

procedure TCustomEasyGrid.WriteCellToBuffer(SrcCell: PCellInfo; DestBuffer: PCharArray);
var
  Pos, CellSize: Integer; // Pos Ϊָ�򻺳�����ƫ����

  procedure WriteString(StrAddr: Pointer);
  var
    Len : Integer;
  begin
    Len := Length(string(StrAddr));
    MoveMemory(@DestBuffer^[Pos], @Len, SizeOf(Integer));
    Inc(Pos, SizeOf(Integer));
    MoveMemory(@DestBuffer^[Pos], StrAddr, Len);
    Inc(Pos, Len);
  end;

begin
  // ����Ŀ�껺������С
  CellSize := CalcCellSize(SrcCell);
  SetLength(DestBuffer^, CellSize);

  Pos := 0;
  // ���� CellSize
  MoveMemory(DestBuffer^, @CellSize, SizeOf(Integer));
  Inc(Pos, SizeOf(Integer));
  // ����ǰ CellFixedPartSize �ֽڵĹ̶�����
  MoveMemory(@DestBuffer^[Pos], SrcCell, CellFixedPartSize);
  Inc(Pos, CellFixedPartSize);

  WriteString(Pointer(SrcCell.FontName)); // ������һ����
  WriteString(Pointer(SrcCell.ForeText)); // �����ڶ�����
  WriteString(Pointer(SrcCell.BackText)); // ������������
end;

procedure TCustomEasyGrid.ClearCells(DestClearRect: TRect);
var
  ACol, ARow, i, j: Integer;
  Range: TGridRect;
  MergeRect: PGridRect;
  SaveAutoUpdate: Boolean;
begin
  SaveAutoUpdate := FAutoUpdate; 
  FAutoUpdate := False;
  Range := TGridRect(DestClearRect);
  Restrict(Range.TopLeft, 1, 1, ColCount - 1, RowCount - 1);
  Restrict(Range.BottomRight, 1, 1, ColCount - 1, RowCount - 1);
  for i:=Range.Left to Range.Right do
    for j:=Range.Top to Range.Bottom do
      begin
        MergeRect := Merges[i, j];
        ACol := MergeRect.Left;
        ARow := MergeRect.Top;
        if not Cells[ACol, ARow].ReadOnly then
        begin
          ForeTexts[ACol, ARow] := '';
          BackTexts[ACol, ARow] := '';
        end;
      end;
  Range := CalcMaxRange(Range.TopLeft, Range.BottomRight);
  FAutoUpdate := SaveAutoUpdate;
  InvalidateRect(Range);
end;

procedure TCustomEasyGrid.CopyCellsToBuffer(Range: TGridRect);
var
  CellBuffer: array of Char;
  RangeWidth, RangeHeight, ACol, ARow, TotalSize, CellSize, Pos: Integer;
begin
  Restrict(Range.TopLeft, 1, 1, ColCount-1, RowCount-1);
  Restrict(Range.BottomRight, 1, 1, ColCount-1, RowCount-1);
  TotalSize := 0;
  // Ϊ�����Ч��,���ȵ�������һ���ܳ���һ�������ڴ�,����������
  for ACol:=Range.Left to Range.Right do
    for ARow:=Range.Top to Range.Bottom do
      Inc(TotalSize,CalcCellSize(Cells[ACol,ARow]));
  Inc(TotalSize, SizeOf(Range.TopLeft) + SizeOf(Integer)*2);
  SetLength(MainBuffer, TotalSize);
  // ������ʼ����Ϳ����Ϣ�� MainBuffer ��
  Pos := 0;
  RangeWidth := Range.Right - Range.Left + 1;
  RangeHeight := Range.Bottom - Range.Top + 1;
  Move(Range.TopLeft, MainBuffer[Pos], SizeOf(Range.TopLeft));
  Inc(Pos, SizeOf(Range.TopLeft));
  Move(RangeWidth, MainBuffer[Pos], SizeOf(Integer));
  Inc(Pos, SizeOf(Integer));
  Move(RangeHeight, MainBuffer[Pos], SizeOf(Integer));
  Inc(Pos, SizeOf(Integer));
  // �����ݶ��� MainBuffer ��
  for ACol:=Range.Left to Range.Right do
    for ARow:=Range.Top to Range.Bottom do
    begin
      WriteCellToBuffer(Cells[ACol,ARow],@CellBuffer);
      CellSize := CalcCellSize(Cells[ACol,ARow]);
      MoveMemory(@MainBuffer[Pos], CellBuffer, CellSize);
      Inc(Pos, CellSize);
    end;
  Finalize(CellBuffer);
end;

procedure TCustomEasyGrid.PasteCellsFromBuffer(DestRect: TGridRect);
var
  XOffset, YOffset, RangeWidth, RangeHeight, ACol, ARow, CellSize, Pos: Integer;
  StartCell: TGridCoord;
  ACell: TCellInfo;
  CellBuffer: array of Char;

  procedure FillDestCell;
  var
    DestX, DestY: Integer;
  begin
    DestX := ACol + XOffset;
    DestY := ARow + YOffset;
    if not PointInGridRect(DestX, DestY, DestRect) then Exit;
    CellToCell(@ACell, Cells[DestX, DestY]);
    Cells[DestX, DestY].Merge.Left := ACell.Merge.Left + XOffset;
    Cells[DestX, DestY].Merge.Right := ACell.Merge.Right + XOffset;
    Cells[DestX, DestY].Merge.Top := ACell.Merge.Top + YOffset;
    Cells[DestX, DestY].Merge.Bottom := ACell.Merge.Bottom + YOffset;
  end;

begin
  Restrict(DestRect.TopLeft, 1, 1, ColCount-1, RowCount-1);
  Restrict(DestRect.BottomRight, 1, 1, ColCount-1, RowCount-1);
  // ����ʼ����������Ϣ
  Pos := 0;
  MoveMemory(@StartCell, @MainBuffer[Pos], SizeOf(StartCell));
  Inc(Pos, SizeOf(StartCell));
  MoveMemory(@RangeWidth, @MainBuffer[Pos], SizeOf(Integer));
  Inc(Pos, SizeOf(Integer));
  MoveMemory(@RangeHeight, @MainBuffer[Pos], SizeOf(Integer));
  Inc(Pos, SizeOf(Integer));
  // ��ÿ�� Cell ��Ϣ��д����Ӧ�� Cell ��
  XOffset := DestRect.Left - StartCell.X;
  YOffset := DestRect.Top - StartCell.Y;
  ACol := StartCell.X;
  ARow := StartCell.Y;
  for ACol := StartCell.X to (StartCell.X + RangeWidth - 1) do
    for ARow := StartCell.Y to (StartCell.Y + RangeHeight - 1) do
    begin
      MoveMemory(@CellSize, @MainBuffer[Pos], SizeOf(Integer));
      SetLength(CellBuffer, CellSize);
      MoveMemory(CellBuffer, @MainBuffer[Pos], CellSize);
      ReadCellFromBuffer(@CellBuffer,@ACell);
      FillDestCell;
      Inc(Pos, CellSize);
    end;
  Finalize(CellBuffer);
end;

procedure TCustomEasyGrid.CopyCells(DestCopyRect: TRect);
var
  BufferSize: Integer;
  DataPtr: Pointer;
  Data: THandle;
begin
  CopyCellsToBuffer(TGridRect(DestCopyRect));
  // ���ü�����
  BufferSize := High(MainBuffer) + 1;
  ClearClipBoard;
  OpenClipBoard;
  try
    Data := GlobalAlloc(GMEM_MOVEABLE+GMEM_DDESHARE, BufferSize);
    try
      DataPtr := GlobalLock(Data);
      try
        MoveMemory(DataPtr, Pointer(MainBuffer), BufferSize);
        SetClipboardData(CF_EASYGRID, Data);
      finally
        GlobalUnlock(Data);
      end;
    except
      GlobalFree(Data);
      raise;
    end;
  finally
    CloseClipBoard;
  end;
 ClearClipBoardBuffer;
end;

procedure TCustomEasyGrid.CutCells(DestCutRect: TRect);
begin
  if RectReadOnly(TGridRect(DestCutRect)) then
  begin
    SayStop(CannotCutReadOnlyCells);
    Exit;
  end;
  CopyCells(DestCutRect);
  RestoreCells(DestCutRect);
  if Assigned(FOnCutCells) then
    FOnCutCells(Self, DestCutRect);
end;

procedure TCustomEasyGrid.FillCells(SrcRect: TRect; Offset: Integer; FillStyle: TFillStyle);
var
  i, FillWidth, FillHeight, FillCount, FillTail: Integer;
  SrcFillRect, DestFillRect, RefreshRect, TailRect: TGridRect;
  DrawInfo: TEasyGridDrawInfo;
begin
  FillWidth := SrcRect.Right - SrcRect.Left + 1;
  FillHeight := SrcRect.Bottom - SrcRect.Top + 1;
  if HaveMerge(@TGridRect(SrcRect)) then
  begin
    if (FillStyle = fsHorzFill) and (Offset mod FillWidth <> 0) or
       (FillStyle = fsVertFill) and (Offset mod FillHeight <> 0) then Exit;
  end;
  CalcDrawInfo(DrawInfo);
  // �ж��ܷ� Fill Ŀ������
  SrcFillRect := TGridRect(SrcRect);
  if not CanFill(TRect(SrcFillRect), Offset, FillStyle) then Exit;
  if FillStyle <> fsNone then  // ���ȷʵ��Ҫ Fill
  begin
    DestFillRect := SrcFillRect;
    RefreshRect := SrcFillRect;
    CopyCellsToBuffer(SrcFillRect);
    // Fill ��Χ�ں��кϲ���������
    if HaveMerge(@SrcFillRect) then
      begin
        // ���� Fill
        if (FillStyle = fsHorzFill) then
          begin
            FillCount := Abs(Offset div FillWidth);
            if Offset < 0 then
              begin
                Inc(DestFillRect.Left,  Offset);
                Inc(DestFillRect.Right, Offset);
                Inc(RefreshRect.Left, Offset);
              end
            else
              begin
                Inc(DestFillRect.Left,  FillWidth);
                Inc(DestFillRect.Right, FillWidth);
                Inc(RefreshRect.Right, Offset);
              end;
            for i:=1 to FillCount do
              begin
                PasteCellsFromBuffer(DestFillRect);
                Inc(DestFillRect.Left, FillWidth);
                Inc(DestFillRect.Right, FillWidth);
              end;
          end
        // ���� Fill
        else
          begin
            FillCount := Abs(Offset div FillHeight);
            if Offset < 0 then
              begin
                Inc(DestFillRect.Top,  Offset);
                Inc(DestFillRect.Bottom, Offset);
                Inc(RefreshRect.Top, Offset);
              end
            else
              begin
                Inc(DestFillRect.Top,  FillHeight);
                Inc(DestFillRect.Bottom, FillHeight);
                Inc(RefreshRect.Bottom, Offset);
              end;
            for i:=1 to FillCount do
              begin
                PasteCellsFromBuffer(DestFillRect);
                Inc(DestFillRect.Top,  FillHeight);
                Inc(DestFillRect.Bottom, FillHeight);
              end;
          end;
      end
    // Fill ��Χ��û�кϲ���������
    else
      begin
        // ���� Fill
        if FillStyle = fsHorzFill then
          begin
            if Offset < 0 then
              begin
                FillCount := Abs(Offset div FillWidth);
                FillTail := Abs(Offset mod FillWidth);
                Inc(DestFillRect.Left,  Offset + FillTail);
                Inc(DestFillRect.Right, Offset + FillTail);
                Inc(RefreshRect.Left, Offset);
              end
            else
              begin
                FillCount := Offset div FillWidth;
                FillTail :=  Offset mod FillWidth;
                Inc(DestFillRect.Left,  FillWidth);
                Inc(DestFillRect.Right, FillWidth);
                Inc(RefreshRect.Right, Offset);
              end;
            for i:=1 to FillCount do
              begin
                PasteCellsFromBuffer(DestFillRect);
                Inc(DestFillRect.Left, FillWidth);
                Inc(DestFillRect.Right, FillWidth);
              end;
            if FillTail <> 0 then
              begin
                TailRect := SrcFillRect;
                if Offset < 0 then
                  begin
                    DestFillRect.Left := SrcFillRect.Left + Offset;
                    DestFillRect.Right := DestFillRect.Left + FillTail - 1;
                    TailRect.Left := TailRect.Right - FillTail + 1;
                  end
                else
                  begin
                    DestFillRect.Right := DestFillRect.Left + FillTail - 1;
                    TailRect.Right := SrcFillRect.Left + FillTail - 1;
                  end;
                CopyCellsToBuffer(TailRect);
                PasteCellsFromBuffer(DestFillRect);
              end;
          end
        // ���� Fill
        else
          begin
            if Offset < 0 then
              begin
                FillCount := Abs(Offset div FillHeight);
                FillTail := Abs(Offset mod FillHeight);
                Inc(DestFillRect.Top,  Offset + FillTail);
                Inc(DestFillRect.Bottom, Offset + FillTail);
                Inc(RefreshRect.Top, Offset);
              end
            else
              begin
                FillCount := Offset div FillHeight;
                FillTail :=  Offset mod FillHeight;
                Inc(DestFillRect.Top, FillHeight);
                Inc(DestFillRect.Bottom, FillHeight);
                Inc(RefreshRect.Bottom, Offset);
              end;
            for i:=1 to FillCount do
              begin
                PasteCellsFromBuffer(DestFillRect);
                Inc(DestFillRect.Top,  FillHeight);
                Inc(DestFillRect.Bottom, FillHeight);
              end;
            if FillTail <> 0 then
              begin
                TailRect := SrcFillRect;
                if Offset < 0 then
                  begin
                    DestFillRect.Top := SrcFillRect.Top + Offset;
                    DestFillRect.Bottom := DestFillRect.Top + FillTail - 1;
                    TailRect.Top := TailRect.Bottom - FillTail + 1;
                  end
                else
                  begin
                    DestFillRect.Bottom := DestFillRect.Top + FillTail - 1;
                    TailRect.Bottom := SrcFillRect.Top + FillTail - 1;
                  end;
                CopyCellsToBuffer(TailRect);
                PasteCellsFromBuffer(DestFillRect);
              end;
          end
      end;
    ClearClipBoardBuffer;
    Selection := RefreshRect;
    if Assigned(FOnFillCells) then
      FOnFillCells(Self, TRect(SrcFillRect), TRect(RefreshRect));
  end;
end;

procedure TCustomEasyGrid.PasteCells(DestPasteCoord: TPoint);
var
  Data: THandle;
  PasteRect: TGridRect;
  StartCell, Size: TGridCoord;
begin
  // �Ѽ��������ݶ��� MainBuffer ��
  if not ClipBoardAvailable then Exit;
  OpenClipBoard;
  Data := GetClipboardData(CF_EASYGRID);
  if Data = 0 then Exit;
  SetLength(MainBuffer, GlobalSize(Data));
  MoveMemory(Pointer(MainBuffer), GlobalLock(Data), GlobalSize(Data));
  GlobalUnlock(Data);
  CloseClipBoard;

  GetClipBoardInfo(StartCell, Size);
  PasteRect.TopLeft := TGridCoord(DestPasteCoord);
  PasteRect.Right := PasteRect.Left + Size.X - 1;
  PasteRect.Bottom := PasteRect.Top + Size.Y - 1;
  if not CanPaste(PasteRect) then
    begin
      SayStop(CannotPasteCells);
      Exit;
    end;
  PasteCellsFromBuffer(PasteRect);
  ClearClipBoardBuffer;
  Selection := PasteRect;
  InvalidateRect(Selection);
  if Assigned(FOnPasteCells) then
    FOnPasteCells(Self, TPoint(StartCell), TPoint(Size), TRect(PasteRect));
end;

procedure TCustomEasyGrid.ClearClipBoard;
begin
  OpenClipBoard;
  try
    EmptyClipboard;
  finally
    CloseClipBoard;
  end;
end;

procedure TCustomEasyGrid.ClearClipBoardBuffer;
begin
  Finalize(MainBuffer);
end;

procedure TCustomEasyGrid.OpenClipBoard;
begin
  if not Windows.OpenClipboard(Application.Handle) then
    raise Exception.Create(SCannotOpenClipboard);
end;

procedure TCustomEasyGrid.CloseClipBoard;
begin
  Windows.CloseClipboard;
end;

function TCustomEasyGrid.ClipBoardAvailable: Boolean;
var
  Data: THandle;
begin
  OpenClipBoard;
  Data := GetClipboardData(CF_EASYGRID);
  CloseClipBoard;
  Result := False;
  if (Data = 0) or (GlobalSize(Data) = 0) then Exit;
  Result := True;
end;

procedure TCustomEasyGrid.GetClipBoardInfo(var StartCoord, Size: TGridCoord);
var
  Data: THandle;
  DataPtr: Pointer;
  AGridRect: TGridRect;
begin
  FillChar(StartCoord, SizeOf(StartCoord), 0);
  FillChar(Size, SizeOf(StartCoord), 0);
  OpenClipBoard;
  Data := GetClipboardData(CF_EASYGRID);
  DataPtr := GlobalLock(Data);
  MoveMemory(@AGridRect, DataPtr, SizeOf(AGridRect));
  GlobalUnlock(Data);
  CloseClipBoard;
  StartCoord := AGridRect.TopLeft;
  Size := AGridRect.BottomRight;
end;

procedure TCustomEasyGrid.RestoreCells(DestRestoreRect: TRect);
var
  i, j: Integer;
begin
  Restrict(TGridCoord(DestRestoreRect.TopLeft), 1, 1, ColCount - 1, RowCount - 1);
  Restrict(TGridCoord(DestRestoreRect.BottomRight), 1, 1, ColCount - 1, RowCount - 1);
  for i:=DestRestoreRect.Left to DestRestoreRect.Right do
    for j:=DestRestoreRect.Top to DestRestoreRect.Bottom do
      InitCell(Self, Cells[i, j], i, j);
  InvalidateRect(TGridRect(DestRestoreRect));
end;

function TCustomEasyGrid.CellInMerge(ACol, ARow: Integer): Boolean;
begin
  Result := False;
  if ((Merges[ACol, ARow].Left <> Merges[ACol, ARow].Right) or
      (Merges[ACol, ARow].Top  <> Merges[ACol, ARow].Bottom)) then
    Result := True;
end;
                                     
function TCustomEasyGrid.HaveMerge(ARect: PGridRect): Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i:=ARect.Left to ARect.Right do
    for j:=ARect.Top to ARect.Bottom do
      if ((Merges[i, j].Left <> Merges[i, j].Right) or
          (Merges[i, j].Top <> Merges[i, j].Bottom)) then Exit;
  Result := False;
end;

function TCustomEasyGrid.MergeRectIntersects(DestRect: TGridRect): Boolean;
var
  MaxRange: TGridRect;
begin
  Result := False;
  MaxRange := CalcMaxRange(DestRect.TopLeft, DestRect.BottomRight);
  if (MaxRange.Left < DestRect.Left) or
     (MaxRange.Top  < DestRect.Top) or
     (MaxRange.Right  > DestRect.Right) or
     (MaxRange.Bottom > DestRect.Bottom) then
    Result := True;
end;

function TCustomEasyGrid.RectReadOnly(DestRect: TGridRect): Boolean;
var
  i, j: Integer;
begin
  Result := True;
  for i:=DestRect.Left to DestRect.Right do
    for j:=DestRect.Top to DestRect.Bottom do
      if Cells[i, j].ReadOnly then Exit;
  Result := False;
end;

function TCustomEasyGrid.CanCopyMove: Boolean;
label
  CanReplace;
var
  DestRect: TGridRect;
  i, j: Integer;
begin
  Result := False;
  DestRect := FCopyMoveRect;
  Inc(DestRect.Left,   FCopyMoveOffset.X);
  Inc(DestRect.Top,    FCopyMoveOffset.Y);
  Inc(DestRect.Right,  FCopyMoveOffset.X);
  Inc(DestRect.Bottom, FCopyMoveOffset.Y);
  for i:=DestRect.Left to DestRect.Right do
    for j:=DestRect.Top to DestRect.Bottom do
      if (not PointInGridRect(i, j, FCopyMoveRect)) and
         ((Cells[i, j].ForeText <> '') or (Cells[i, j].BackText <> '')) then
        if Ask(DoYouWantReplace, 2) then Goto CanReplace
        else Exit;
CanReplace:
  if MergeRectIntersects(DestRect) then
  begin
    SayStop(CannotChangeMergedCells);
    Exit;
  end;
  if RectReadOnly(DestRect) then
  begin
    SayStop(CannotOverlayReadOnlyCells);
    Exit;
  end;
  Result := True;
end;

function TCustomEasyGrid.CanFill(SrcRect: TRect; Offset: Integer; FillStyle: TFillStyle): Boolean;
var
  SrcFillRect, DestFillRect: TGridRect;
begin
  Result := False;
  SrcFillRect := TGridRect(SrcRect);
  DestFillRect := SrcFillRect;
  if FillStyle = fsHorzFill then
    if Offset > 0 then
      begin
        DestFillRect.Left := SrcFillRect.Right + 1;
        DestFillRect.Right := SrcFillRect.Right + Offset;
      end
    else
      begin
        DestFillRect.Left := SrcFillRect.Left + Offset;
        DestFillRect.Right := SrcFillRect.Left - 1;
      end
  else if FillStyle = fsVertFill then
    if Offset > 0 then
      begin
        DestFillRect.Top := SrcFillRect.Bottom + 1;
        DestFillRect.Bottom := SrcFillRect.Bottom + Offset;
      end
    else
      begin
        DestFillRect.Top := SrcFillRect.Top + Offset;
        DestFillRect.Bottom := SrcFillRect.Top - 1;
      end;
  if MergeRectIntersects(DestFillRect) then
  begin
    SayStop(MergedCellsMustBeSameSize);
    Exit;
  end;
  if RectReadOnly(DestFillRect) then
  begin
    SayStop(CannotOverlayReadOnlyCells);
    Exit;
  end;
  Result := True;
end;

function TCustomEasyGrid.CanPaste(DestRect: TGridRect): Boolean;
begin
  Result := True;
  if (DestRect.Left <= FixedCols) or
     (DestRect.Top  <= FixedRows) or
     (DestRect.Right  >= ColCount) or
     (DestRect.Bottom >= RowCount) or
     MergeRectIntersects(DestRect) or
     RectReadOnly(DestRect) then Result := False;
end;

procedure TCustomEasyGrid.SetColProperty(ColIndex: Integer;
          PropertyName: TPropertyName; Value: Pointer);
var
  ARow: Integer;
begin
  if (ColIndex < 1) or (ColIndex >= ColCount) then Exit;
  for ARow:=1 to RowCount - 1 do
    case PropertyName of
      pnDataStyle :
        Cells[ColIndex, ARow].DataStyle := TDataStyle(Value);
      pnAlignMode :
        Cells[ColIndex, ARow].AlignMode := TAlignMode(Value);
      pnReadOnly :
        Cells[ColIndex, ARow].ReadOnly := Boolean(Value);
      pnAutoWordBreak :
        Cells[ColIndex, ARow].AutoWordBreak := Boolean(Value);
      pnShowForeText :
        Cells[ColIndex, ARow].ShowForeText := Boolean(Value);
      pnDrawTop :
        Cells[ColIndex, ARow].DrawTop := Boolean(Value);
      pnDrawLeft :
        Cells[ColIndex, ARow].DrawLeft := Boolean(Value);
      pnDrawRight :
        Cells[ColIndex, ARow].DrawRight := Boolean(Value);
      pnDrawBottom :
        Cells[ColIndex, ARow].DrawBottom := Boolean(Value);
      pnAllowNegative :
        Cells[ColIndex, ARow].AllowNegative := Boolean(Value);
      pnTrailingZero :
        Cells[ColIndex, ARow].TrailingZero := Boolean(Value);
      pnZeroNull :
        Cells[ColIndex, ARow].ZeroNull := Boolean(Value);
      pnThousandSep :
        Cells[ColIndex, ARow].ThousandSep := Boolean(Value);
      pnMaxLength :
        Cells[ColIndex, ARow].MaxLength := Integer(Value);
      pnIntLength :
        Cells[ColIndex, ARow].IntLength := Integer(Value);
      pnDecLength :
        Cells[ColIndex, ARow].DecLength := Integer(Value);
      pnLineWidth :
        Cells[ColIndex, ARow].LineWidth := Integer(Value);
      pnPenStyle :
        Cells[ColIndex, ARow].PenStyle := TPenStyle(Value);
      pnNumber :
        Cells[ColIndex, ARow].Number := Integer(Value);
      pnColor :
        Cells[ColIndex, ARow].Color := TColor(Value);
      pnFontSize :
        Cells[ColIndex, ARow].FontSize := Integer(Value);
      pnFontColor :
        Cells[ColIndex, ARow].FontColor := TColor(Value);
      pnFontStyle :
        Cells[ColIndex, ARow].FontStyle := TFontStyles(Value^);
      pnFontName :
        Cells[ColIndex, ARow].FontName := PChar(Value);
      pnForeText :
        ForeTexts[ColIndex, ARow] := PChar(Value);
      pnBackText :
        BackTexts[ColIndex, ARow] := PChar(Value);
    end;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.SetRowProperty(RowIndex: Integer;
          PropertyName: TPropertyName; Value: Pointer);
var
  ACol: Integer;
begin
  if (RowIndex < 1) or (RowIndex >= RowCount) then Exit;
  for ACol:=1 to ColCount - 1 do
    case PropertyName of
      pnDataStyle :
        Cells[ACol, RowIndex].DataStyle := TDataStyle(Value);
      pnAlignMode :
        Cells[ACol, RowIndex].AlignMode := TAlignMode(Value);
      pnReadOnly :
        Cells[ACol, RowIndex].ReadOnly := Boolean(Value);
      pnAutoWordBreak :
        Cells[ACol, RowIndex].AutoWordBreak := Boolean(Value);
      pnShowForeText :
        Cells[ACol, RowIndex].ShowForeText := Boolean(Value);
      pnDrawTop :
        Cells[ACol, RowIndex].DrawTop := Boolean(Value);
      pnDrawLeft :
        Cells[ACol, RowIndex].DrawLeft := Boolean(Value);
      pnDrawRight :
        Cells[ACol, RowIndex].DrawRight := Boolean(Value);
      pnDrawBottom :
        Cells[ACol, RowIndex].DrawBottom := Boolean(Value);
      pnAllowNegative :
        Cells[ACol, RowIndex].AllowNegative := Boolean(Value);
      pnTrailingZero :
        Cells[ACol, RowIndex].TrailingZero := Boolean(Value);
      pnZeroNull :
        Cells[ACol, RowIndex].ZeroNull := Boolean(Value);
      pnThousandSep :
        Cells[ACol, RowIndex].ThousandSep := Boolean(Value);
      pnMaxLength :
        Cells[ACol, RowIndex].MaxLength := Integer(Value);
      pnIntLength :
        Cells[ACol, RowIndex].IntLength := Integer(Value);
      pnDecLength :
        Cells[ACol, RowIndex].DecLength := Integer(Value);
      pnLineWidth :
        Cells[ACol, RowIndex].LineWidth := Integer(Value);
      pnPenStyle :
        Cells[ACol, RowIndex].PenStyle := TPenStyle(Value);
      pnNumber :
        Cells[ACol, RowIndex].Number := Integer(Value);
      pnColor :
        Cells[ACol, RowIndex].Color := TColor(Value);
      pnFontSize :
        Cells[ACol, RowIndex].FontSize := Integer(Value);
      pnFontColor :
        Cells[ACol, RowIndex].FontColor := TColor(Value);
      pnFontStyle :
        Cells[ACol, RowIndex].FontStyle := TFontStyles(Value^);
      pnFontName :
        Cells[ACol, RowIndex].FontName := PChar(Value);
      pnForeText :
        ForeTexts[ACol, RowIndex] := PChar(Value);
      pnBackText :
        BackTexts[ACol, RowIndex] := PChar(Value);
    end;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.SetRangeProperty(Range: TRect; PropertyName: TPropertyName;
          Value: Pointer);
var
  ACol, ARow: Integer;
begin
  Restrict(TGridCoord(Range.TopLeft), 1, 1, ColCount - 1, RowCount - 1);
  Restrict(TGridCoord(Range.BottomRight), 1, 1, ColCount - 1, RowCount - 1);
  for ACol:=Range.Left to Range.Right do
    for ARow:=Range.Top to Range.Bottom do
    case PropertyName of
      pnDataStyle :
        Cells[ACol, ARow].DataStyle := TDataStyle(Value);
      pnAlignMode :
        Cells[ACol, ARow].AlignMode := TAlignMode(Value);
      pnReadOnly :
        Cells[ACol, ARow].ReadOnly := Boolean(Value);
      pnAutoWordBreak :
        Cells[ACol, ARow].AutoWordBreak := Boolean(Value);
      pnShowForeText :
        Cells[ACol, ARow].ShowForeText := Boolean(Value);
      pnDrawTop :
        Cells[ACol, ARow].DrawTop := Boolean(Value);
      pnDrawLeft :
        Cells[ACol, ARow].DrawLeft := Boolean(Value);
      pnDrawRight :
        Cells[ACol, ARow].DrawRight := Boolean(Value);
      pnDrawBottom :
        Cells[ACol, ARow].DrawBottom := Boolean(Value);
      pnAllowNegative :
        Cells[ACol, ARow].AllowNegative := Boolean(Value);
      pnTrailingZero :
        Cells[ACol, ARow].TrailingZero := Boolean(Value);
      pnZeroNull :
        Cells[ACol, ARow].ZeroNull := Boolean(Value);
      pnThousandSep :
        Cells[ACol, ARow].ThousandSep := Boolean(Value);
      pnMaxLength :
        Cells[ACol, ARow].MaxLength := Integer(Value);
      pnIntLength :
        Cells[ACol, ARow].IntLength := Integer(Value);
      pnDecLength :
        Cells[ACol, ARow].DecLength := Integer(Value);
      pnLineWidth :
        Cells[ACol, ARow].LineWidth := Integer(Value);
      pnPenStyle :
        Cells[ACol, ARow].PenStyle := TPenStyle(Value);
      pnNumber :
        Cells[ACol, ARow].Number := Integer(Value);
      pnColor :
        Cells[ACol, ARow].Color := TColor(Value);
      pnFontSize :
        Cells[ACol, ARow].FontSize := Integer(Value);
      pnFontColor :
        Cells[ACol, ARow].FontColor := TColor(Value);
      pnFontStyle :
        Cells[ACol, ARow].FontStyle := TFontStyles(Value^);
      pnFontName :
        Cells[ACol, ARow].FontName := PChar(Value);
      pnForeText :
        ForeTexts[ACol, ARow] := PChar(Value);
      pnBackText :
        BackTexts[ACol, ARow] := PChar(Value);
    end;
  InvalidateRect(TGridRect(Range));
end;

procedure TCustomEasyGrid.SetGridProperty(PropertyName: TPropertyName;
          Value: Pointer);
var
  ACol, ARow: Integer;
begin
  for ACol:=1 to ColCount - 1 do
    for ARow:=1 to RowCount - 1 do
    case PropertyName of
      pnDataStyle :
        Cells[ACol, ARow].DataStyle := TDataStyle(Value);
      pnAlignMode :
        Cells[ACol, ARow].AlignMode := TAlignMode(Value);
      pnReadOnly :
        Cells[ACol, ARow].ReadOnly := Boolean(Value);
      pnAutoWordBreak :
        Cells[ACol, ARow].AutoWordBreak := Boolean(Value);
      pnShowForeText :
        Cells[ACol, ARow].ShowForeText := Boolean(Value);
      pnDrawTop :
        Cells[ACol, ARow].DrawTop := Boolean(Value);
      pnDrawLeft :
        Cells[ACol, ARow].DrawLeft := Boolean(Value);
      pnDrawRight :
        Cells[ACol, ARow].DrawRight := Boolean(Value);
      pnDrawBottom :
        Cells[ACol, ARow].DrawBottom := Boolean(Value);
      pnAllowNegative :
        Cells[ACol, ARow].AllowNegative := Boolean(Value);
      pnTrailingZero :
        Cells[ACol, ARow].TrailingZero := Boolean(Value);
      pnZeroNull :
        Cells[ACol, ARow].ZeroNull := Boolean(Value);
      pnThousandSep :
        Cells[ACol, ARow].ThousandSep := Boolean(Value);
      pnMaxLength :
        Cells[ACol, ARow].MaxLength := Integer(Value);
      pnIntLength :
        Cells[ACol, ARow].IntLength := Integer(Value);
      pnDecLength :
        Cells[ACol, ARow].DecLength := Integer(Value);
      pnLineWidth :
        Cells[ACol, ARow].LineWidth := Integer(Value);
      pnPenStyle :
        Cells[ACol, ARow].PenStyle := TPenStyle(Value);
      pnNumber :
        Cells[ACol, ARow].Number := Integer(Value);
      pnColor :
        Cells[ACol, ARow].Color := TColor(Value);
      pnFontSize :
        Cells[ACol, ARow].FontSize := Integer(Value);
      pnFontColor :
        Cells[ACol, ARow].FontColor := TColor(Value);
      pnFontStyle :
        Cells[ACol, ARow].FontStyle := TFontStyles(Value^);
      pnFontName :
        Cells[ACol, ARow].FontName := PChar(Value);
      pnForeText :
        ForeTexts[ACol, ARow] := PChar(Value);
      pnBackText :
        BackTexts[ACol, ARow] := PChar(Value);
    end;
  InvalidateGrid;
end;

procedure TCustomEasyGrid.SetCellDataStyle(Value: TDataStyle);
begin
  SetGridProperty(pnDataStyle, Pointer(Value));
  FDataStyle := Value;
end;

procedure TCustomEasyGrid.SetCellAlignMode(Value: TAlignMode);
begin
  SetGridProperty(pnAlignMode, Pointer(Value));
  FAlignMode := Value;
end;

procedure TCustomEasyGrid.SetCellShowForeText(Value: Boolean);
begin
  SetGridProperty(pnShowForeText, Pointer(Value));
  FShowForeText := Value;
end;

procedure TCustomEasyGrid.SetCellReadOnly(Value: Boolean);
begin
  SetGridProperty(pnReadOnly, Pointer(Value));
  FReadOnly := Value;
end;

procedure TCustomEasyGrid.SetCellAutoWordBreak(Value: Boolean);
begin
  SetGridProperty(pnAutoWordBreak, Pointer(Value));
  FAutoWordBreak := Value;
end;

procedure TCustomEasyGrid.SetCellLineWidth(Value: Integer);
begin
  SetGridProperty(pnLineWidth, Pointer(Value));
  FCellLineWidth := Value;
end;

procedure TCustomEasyGrid.SetCellPenStyle(Value: TPenStyle);
begin
  SetGridProperty(pnPenStyle, Pointer(Value));
  FCellPenStyle := Value;
end;

procedure TCustomEasyGrid.SetCellAllowNegative(Value: Boolean);
begin
  SetGridProperty(pnAllowNegative, Pointer(Value));
  FAllowNegative := Value;
end;

procedure TCustomEasyGrid.SetCellTrailingZero(Value: Boolean);
begin
  SetGridProperty(pnTrailingZero, Pointer(Value));
  FTrailingZero := Value;
end;

procedure TCustomEasyGrid.SetCellZeroNull(Value: Boolean);
begin
  SetGridProperty(pnZeroNull, Pointer(Value));
  FZeroNull := Value;
end;

procedure TCustomEasyGrid.SetCellThousandSep(Value: Boolean);
begin
  SetGridProperty(pnThousandSep, Pointer(Value));
  FThousandSep := Value;
end;

procedure TCustomEasyGrid.SetCellMaxLength(Value: Integer);
begin
  SetGridProperty(pnMaxLength, Pointer(Value));
  FMaxLength := Value;
end;

procedure TCustomEasyGrid.SetCellIntLength(Value: Integer);
begin
  SetGridProperty(pnIntLength, Pointer(Value));
  FIntLength := Value;
end;

procedure TCustomEasyGrid.SetCellDecLength(Value: Integer);
begin
  SetGridProperty(pnDecLength, Pointer(Value));
  FDecLength := Value;
end;

procedure TCustomEasyGrid.SetCellColor(Value: TColor);
begin
  SetGridProperty(pnColor, Pointer(Value));
  FColor := Value;
end;

procedure TCustomEasyGrid.SetCellFontSize(Value: Integer);
begin
  SetGridProperty(pnFontSize, Pointer(Value));
  FFontSize := Value;
end;

procedure TCustomEasyGrid.SetCellFontColor(Value: TColor);
begin
  SetGridProperty(pnFontColor, Pointer(Value));
  FFontColor := Value;
end;

procedure TCustomEasyGrid.SetCellFontStyle(Value: TFontStyles);
begin
  SetGridProperty(pnFontStyle, @Value);
  FFontStyle := Value;
end;

procedure TCustomEasyGrid.InsertCellRight(InsertRect: TRect);
var
  MergeFounded: Boolean;
  InsertWidth: Integer;
  ARect: TGridRect;

  // �����Ҫ�������������ݲ�Ϊ��,���ߴ��ںϲ�����,���ܲ���
  function CanInsert: Boolean;
  var
    i, j: Integer;
  begin
    Result := False;
    for i:=ColCount-InsertWidth to ColCount-1 do
      for j:=InsertRect.Top to InsertRect.Bottom do
        if (Cells[i, j].ForeText <> '') or
           (Cells[i, j].BackText <> '') or
           (CellInMerge(i, j)) then Exit;
    Result := True;
  end;

  // ���Ҳ��ҳ�����Χ�ĺϲ�����
  procedure FindMerge;
  var
    i: Integer;
  begin
    MergeFounded := False;
    for i:=InsertRect.Right+1 to ColCount-1 do
      if (Merges[i, InsertRect.Top].Top < InsertRect.Top) or
         (Merges[i, InsertRect.Bottom].Bottom > InsertRect.Bottom) then
        begin
          MergeFounded := True;
          Exit;
        end;
  end;

  // ��������κγ�����Χ�ĺϲ�����,�����ɢ
  procedure DeleteAnyMerges;
  var
    i: Integer;
    MergeRect: TGridRect;
  begin
    // ��ɢ����������Χ�ĺϲ�����
    i := InsertRect.Right + 1;
    while i < ColCount do
    begin
      MergeRect := Merges[i, InsertRect.Top]^;
      if (MergeRect.Top < InsertRect.Top) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Right;
      end;
      Inc(i);
    end;
    // ��ɢ�ײ�������Χ�ĺϲ�����
    i := InsertRect.Right + 1;
    while i < ColCount do
    begin
      MergeRect := Merges[i, InsertRect.Bottom]^;
      if (MergeRect.Bottom > InsertRect.Bottom) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Right;
      end;
      Inc(i);
    end;
  end;

begin
  InsertWidth  := InsertRect.Right - InsertRect.Left + 1;
  // �ж��ܷ����
  if not CanInsert then
  begin
    SayStop(CannotRemoveRightMostCells);
    Exit;
  end;
  FindMerge;
  if MergeFounded then
    if Ask(DoYouWantDeleteMergedCells,2) then
      DeleteAnyMerges
    else
      Exit;
  // ��������
  ARect := TGridRect(InsertRect);
  ARect.Right := ColCount - InsertWidth - 1;
  CopyCellsToBuffer(ARect);
  Inc(ARect.Left, InsertWidth);
  Inc(ARect.Right,InsertWidth);
  PasteCellsFromBuffer(ARect);
  // ��ԭλ������� Cells
  RestoreCells(InsertRect);
  ClearClipBoardBuffer;
  // ˢ������
  ARect := TGridRect(InsertRect);
  ARect.Right := ColCount - 1;
  InvalidateRect(ARect);
  if Assigned(FOnInsertCellRight) then
    FOnInsertCellRight(Self, InsertRect);
end;

procedure TCustomEasyGrid.InsertCellDown(InsertRect: TRect);
var
  MergeFounded: Boolean;
  InsertHeight: Integer;
  ARect: TGridRect;

  // �����Ҫ�������������ݲ�Ϊ��,���ߴ��ںϲ�����,���ܲ���
  function CanInsert: Boolean;
  var
    i, j: Integer;
  begin
    Result := False;
    for i:=InsertRect.Left to InsertRect.Right do
      for j:=RowCount-InsertHeight to RowCount-1 do
        if (Cells[i, j].ForeText <> '') or
           (Cells[i, j].BackText <> '') or
           (CellInMerge(i, j)) then Exit;
    Result := True;
  end;

  // ���²��ҳ�����Χ�ĺϲ�����
  procedure FindMerge;
  var
    i: Integer;
  begin
    MergeFounded := False;
    for i:=InsertRect.Bottom+1 to RowCount-1 do
      if (Merges[InsertRect.Left, i].Left < InsertRect.Left) or
         (Merges[InsertRect.Right, i].Right > InsertRect.Right) then
        begin
          MergeFounded := True;
          Exit;
        end;
  end;

  // ��������κγ�����Χ�ĺϲ�����,�����ɢ
  procedure DeleteAnyMerges;
  var
    i: Integer;
    MergeRect: TGridRect;
  begin
    // ��ɢ��߳�����Χ�ĺϲ�����
    i := InsertRect.Bottom + 1;
    while i < RowCount do
    begin
      MergeRect := Merges[InsertRect.Left, i]^;
      if (MergeRect.Left < InsertRect.Left) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Bottom;
      end;
      Inc(i);
    end;
    // ��ɢ�ұ߳�����Χ�ĺϲ�����
    i := InsertRect.Bottom + 1;
    while i < RowCount do
    begin
      MergeRect := Merges[InsertRect.Right, i]^;
      if (MergeRect.Right > InsertRect.Right) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Bottom;
      end;
      Inc(i);
    end;
  end;

begin
  InsertHeight := InsertRect.Bottom - InsertRect.Top + 1;
  // �ж��ܷ����
  if not CanInsert then
  begin
    SayStop(CannotRemoveBottomMostCells);
    Exit;
  end;
  FindMerge;
  if MergeFounded then
    if Ask(DoYouWantDeleteMergedCells,2) then
      DeleteAnyMerges
    else
      Exit;
  // ��������
  ARect := TGridRect(InsertRect);
  ARect.Bottom := RowCount - InsertHeight - 1;
  CopyCellsToBuffer(ARect);
  Inc(ARect.Top, InsertHeight);
  Inc(ARect.Bottom,InsertHeight);
  PasteCellsFromBuffer(ARect);
  // ��ԭλ������� Cells
  RestoreCells(InsertRect);
  ClearClipBoardBuffer;
  // ˢ������
  ARect := TGridRect(InsertRect);
  ARect.Bottom := RowCount - 1;
  InvalidateRect(ARect);
  if Assigned(FOnInsertCellDown) then
    FOnInsertCellDown(Self, InsertRect);
end;

// *****************************************************************************
// �������еĳ���������������:
//
//   ������: InsertCol
//     . ������Ӧ��Ŀ����
//     . �ѵ�ǰѡ��Χ�ڵ��б��浽������
//     . �ѴӲ���㿪ʼ���ұ�������(ָ��)����,����з�����ѭ���Ƶ����뷶Χ��
//       ����ֻ�ƶ�ָ��,���Բ��ܶ��������
//     . �Ѹղű������ճ������,�Իָ�������ǰ��״̬
//     . ���ݲ���ǰ��״̬��չ�ϲ�����
//   ������: InsertRow ����������
// *****************************************************************************
procedure TCustomEasyGrid.InsertCol(InsertRect: TRect);
var
  InsertWidth: Integer;
  OldSel, ARect: TGridRect;

  // �������������256,�ҽ�Ҫ�������������ݲ�Ϊ��,���ߴ��ںϲ�����,���ܲ���
  function CanInsert: Boolean;
  var
    i, j: Integer;
  begin
    Result := False;
    if (ColCount + InsertWidth) > 256 then
      for i:=ColCount-InsertWidth to ColCount-1 do
        for j:=FixedRows+1 to RowCount-1 do
          if (Cells[i, j].ForeText <> '') or
             (Cells[i, j].BackText <> '') or
             (CellInMerge(i, j)) then Exit;
    Result := True;
  end;

  // ѭ������һ����Χ�ڵ� Cells ����(�ƶ�ָ��)
  procedure MoveColsR(StartCol, EndCol, XOffset: Integer);
  var
    HoleList: TList;
    ACol: Integer;
    // �ƶ�һ����ָ�벢�����ϲ�����
    procedure MoveACol(AColCellInfoList: TColCellInfoList; DestCol: Integer; AdjustMerge: Boolean);
    var
      ARow: Integer;
    begin
      // ��ָ�����
      FCells.Items[DestCol] := AColCellInfoList;
      // �����ϲ�����
      for ARow:=0 to RowCount-1 do
        if AdjustMerge then
          begin
            Inc(Cells[DestCol, ARow].Merge.Left, XOffset);
            Inc(Cells[DestCol, ARow].Merge.Right, XOffset);
          end
        else
          begin
            Cells[DestCol, ARow].Merge.Left := DestCol;
            Cells[DestCol, ARow].Merge.Right := DestCol;
          end
    end;
    // **************************************************
  begin
    if (StartCol <= FixedCols) or
       (EndCol >= ColCount) or
       (StartCol > EndCol) then Exit;
    // �� HoleList ������� XOffset ����ָ��(����)
    HoleList := TList.Create;
    for ACol:=EndCol downto (EndCol-XOffset+1) do
      HoleList.Add(FCells.Items[ACol]);
    // �����������Ұ��� XOffset ��λ��(��������� XOffset ����)
    for ACol:=EndCol-XOffset downto StartCol do
      MoveACol(FCells.Items[ACol], ACol+XOffset, True);
    // �� HoleList �а���� XOffset ���а�ز�������
    for ACol:=0 to XOffset-1 do
      MoveACol(HoleList.Items[ACol], StartCol+ACol, False);
    HoleList.Free;
  end;

  // ��չ�����еĵĺϲ�����
  procedure ExpandAnyMerges;
  var
    ACol, ARow, i, j: Integer;
    ACellRect, MergeRect: TGridRect;
  begin
    for ACol:=InsertRect.Left to InsertRect.Right do
    begin
      // �ӵ�һ�����²���
      ARow := 1;
      while ARow < RowCount do
      begin
        MergeRect := Merges[ACol, ARow]^;
        ACellRect := GridRect(GridCoord(ACol, ARow), GridCoord(ACol, ARow));
        // ����ҵ��ϲ�������ȷʵ��Ҫ��չ
        if (MergeRect.Left <> MergeRect.Right) and (MergeRect.Left < InsertRect.Left) then
          begin
            // ֻ��չ����������ཻ�ĺϲ�����
            if (ACol = InsertRect.Left) then
            begin
              for i:=MergeRect.Left to (MergeRect.Right + InsertWidth) do
                for j:=MergeRect.Top to MergeRect.Bottom do
                begin
                  Cells[i, j].Merge.Left := MergeRect.Left;
                  Cells[i, j].Merge.Right := MergeRect.Right + InsertWidth;
                  Cells[i, j].Merge.Top := MergeRect.Top;
                  Cells[i, j].Merge.Bottom := MergeRect.Bottom;
                end;
              ARow := MergeRect.Bottom;
            end;
          end
        // ���Ǻϲ�������ָ���ȱʡ״̬
        else
          RestoreCells(TRect(ACellRect));
        Inc(ARow);
      end;
    end;
  end;

begin
  InsertWidth  := InsertRect.Right - InsertRect.Left + 1;
  // �ж��ܷ����
  if not CanInsert then
  begin
    SayStop(CannotRemoveRightMostCells);
    Exit;
  end;
  AutoUpdate := False;
  OldSel := Selection;
  ColCount := ColCount + InsertWidth;
  // �ѵ�ǰ���뷶Χ�ڵ��б��浽������
  ARect.Left := InsertRect.Left;
  ARect.Right := InsertRect.Right;
  ARect.Top := 1;
  ARect.Bottom := RowCount - 1;
  CopyCellsToBuffer(ARect);
  // ����ѭ������(��󼸸����б��������Ƶ��˲��뷶Χ��)
  MoveColsR(InsertRect.Left, ColCount-1, InsertWidth);
  // �ָ��ɲ���ǰ��״̬
  PasteCellsFromBuffer(ARect);
  // ���ݲ���ǰ��״̬��չ�����еĵĺϲ�����
  ExpandAnyMerges;
  ClearClipBoardBuffer;
  // ˢ������
  FSelStart := OldSel.TopLeft;
  FSelEnd := OldSel.BottomRight;
  AutoUpdate := True;
  if Assigned(FOnInsertCol) then
    FOnInsertCol(Self, InsertRect);
end;

procedure TCustomEasyGrid.InsertRow(InsertRect: TRect);
var
  InsertHeight: Integer;
  OldSel, ARect: TGridRect;

  // ѭ������һ����Χ�ڵ� Cells ����(�ƶ�ָ��)
  procedure MoveRowsR(StartRow, EndRow, YOffset: Integer);
  var
    HoleList: TList;
    ACol, ARow: Integer;
    // �ƶ�һ������ָ�벢�����ϲ�����
    procedure MoveACell(ACellInfo: PCellInfo; DestCol, DestRow: Integer; AdjustMerge: Boolean);
    begin
      // �ƶ�����ָ��
      TColCellInfoList(FCells.Items[DestCol]).Items[DestRow] := ACellInfo;
      // �����ϲ�����
      if AdjustMerge then
        begin
          Inc(Cells[DestCol, DestRow].Merge.Top, YOffset);
          Inc(Cells[DestCol, DestRow].Merge.Bottom, YOffset);
        end
      else
        begin
          Cells[DestCol, DestRow].Merge.Top := DestRow;
          Cells[DestCol, DestRow].Merge.Bottom := DestRow;
        end;
    end;
    // **************************************************
  begin
    if (StartRow <= FixedRows) or
       (EndRow >= RowCount) or
       (StartRow > EndRow) then Exit;
    HoleList := TList.Create;
    // ���ΰ���ÿ���е�����ָ��
    for ACol:=1 to ColCount-1 do
    begin
      HoleList.Clear;
      // �� HoleList ������� YOffset ������ָ��(����)
      for ARow:=EndRow downto (EndRow-YOffset+1) do
        HoleList.Add(Cells[ACol,ARow]);
      // �Ѹ�����������ָ�����°��� YOffset ��λ��(��������� YOffset ��)
      for ARow:=EndRow-YOffset downto StartRow do
        MoveACell(Cells[ACol, ARow], ACol, ARow+YOffset, True);
      // �� HoleList �а���� YOffset ������ָ���ز�������
      for ARow:=0 to YOffset-1 do
        MoveACell(HoleList.Items[ARow], ACol, StartRow+ARow, False);
    end;
    HoleList.Free;
  end;

  // ��չ�����еĵĺϲ�����
  procedure ExpandAnyMerges;
  var
    ACol, ARow, i, j: Integer;
    ACellRect, MergeRect: TGridRect;
  begin
    for ARow:=InsertRect.Top to InsertRect.Bottom do
    begin
      // �ӵ�һ�����Ҳ���
      ACol := 1;
      while ACol < ColCount do
      begin
        MergeRect := Merges[ACol, ARow]^;
        ACellRect := GridRect(GridCoord(ACol, ARow), GridCoord(ACol, ARow));
        // ����ҵ��ϲ�������ȷʵ��Ҫ��չ
        if (MergeRect.Top <> MergeRect.Bottom) and (MergeRect.Top < InsertRect.Top) then
          begin
            // ֻ��չ������������ཻ�ĺϲ�����
            if (ARow = InsertRect.Top) then
            begin
              for i:=MergeRect.Left to MergeRect.Right do
                for j:=MergeRect.Top to (MergeRect.Bottom + InsertHeight) do
                begin
                  Cells[i, j].Merge.Left := MergeRect.Left;
                  Cells[i, j].Merge.Right := MergeRect.Right;
                  Cells[i, j].Merge.Top := MergeRect.Top;
                  Cells[i, j].Merge.Bottom := MergeRect.Bottom + InsertHeight;
                end;
              ACol := MergeRect.Right;
            end;
          end
        // ���Ǻϲ�������ָ���ȱʡ״̬
        else
          RestoreCells(TRect(ACellRect));
        Inc(ACol);
      end;
    end;
  end;

begin
  AutoUpdate := False;
  InsertHeight  := InsertRect.Bottom - InsertRect.Top + 1;
  OldSel := Selection;
  RowCount := RowCount + InsertHeight;
  // �ѵ�ǰ���뷶Χ�ڵ��б��浽������
  ARect.Left := 1;
  ARect.Right := ColCount - 1;
  ARect.Top := InsertRect.Top;
  ARect.Bottom := InsertRect.Bottom;
  CopyCellsToBuffer(ARect);
  // ����ѭ������(��󼸸����б��������Ƶ��˲��뷶Χ��)
  MoveRowsR(InsertRect.Top, RowCount-1, InsertHeight);
  // �ָ��ɲ���ǰ��״̬
  PasteCellsFromBuffer(ARect);
  // ���ݲ���ǰ��״̬��չ�����еĵĺϲ�����
  ExpandAnyMerges;
  ClearClipBoardBuffer;
  // ˢ������
  FSelStart := OldSel.TopLeft;
  FSelEnd := OldSel.BottomRight;
  AutoUpdate := True;
  if Assigned(FOnInsertRow) then
    FOnInsertRow(Self, InsertRect);
end;

procedure TCustomEasyGrid.DeleteCellRight(DeleteRect: TRect);
var
  MergeFounded: Boolean;
  DeleteWidth: Integer;
  ARect: TGridRect;

  // ���Ҳ��ҳ�����Χ�ĺϲ�����
  procedure FindMerge;
  var
    i: Integer;
  begin
    MergeFounded := False;
    for i:=DeleteRect.Right+1 to ColCount-1 do
      if (Merges[i, DeleteRect.Top].Top < DeleteRect.Top) or
         (Merges[i, DeleteRect.Bottom].Bottom > DeleteRect.Bottom) then
        begin
          MergeFounded := True;
          Exit;
        end;
  end;

  // ��������κγ�����Χ�ĺϲ�����,�����ɢ
  procedure DeleteAnyMerges;
  var
    i: Integer;
    MergeRect: TGridRect;
  begin
    // ��ɢ����������Χ�ĺϲ�����
    i := DeleteRect.Right + 1;
    while i < ColCount do
    begin
      MergeRect := Merges[i, DeleteRect.Top]^;
      if (MergeRect.Top < DeleteRect.Top) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Right;
      end;
      Inc(i);
    end;
    // ��ɢ�ײ�������Χ�ĺϲ�����
    i := DeleteRect.Right + 1;
    while i < ColCount do
    begin
      MergeRect := Merges[i, DeleteRect.Bottom]^;
      if (MergeRect.Bottom > DeleteRect.Bottom) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Right;
      end;
      Inc(i);
    end;
  end;

begin
  DeleteWidth  := DeleteRect.Right - DeleteRect.Left + 1;
  FindMerge;
  if MergeFounded then
    if Ask(DoYouWantDeleteMergedCells,2) then
      DeleteAnyMerges
    else
      Exit;
  // ��������
  ARect := TGridRect(DeleteRect);
  ARect.Left := ARect.Right + 1;
  ARect.Right := ColCount - 1;
  CopyCellsToBuffer(ARect);
  Dec(ARect.Left, DeleteWidth);
  Dec(ARect.Right,DeleteWidth);
  PasteCellsFromBuffer(ARect);
  // ���������� Cells
  ARect.Left := ColCount - DeleteWidth + 1;
  ARect.Right := ColCount - 1;
  RestoreCells(TRect(ARect));
  ClearClipBoardBuffer;
  // ˢ������
  ARect := TGridRect(DeleteRect);
  ARect.Right := ColCount - 1;
  InvalidateRect(ARect);
  if Assigned(FOnDeleteCellRight) then
    FOnDeleteCellRight(Self, DeleteRect);
end;

procedure TCustomEasyGrid.DeleteCellDown(DeleteRect: TRect);
var
  MergeFounded: Boolean;
  DeleteHeight: Integer;
  ARect: TGridRect;

  // ���²��ҳ�����Χ�ĺϲ�����
  procedure FindMerge;
  var
    i: Integer;
  begin
    MergeFounded := False;
    for i:=DeleteRect.Bottom+1 to RowCount-1 do
      if (Merges[DeleteRect.Left, i].Left < DeleteRect.Left) or
         (Merges[DeleteRect.Right, i].Right > DeleteRect.Right) then
        begin
          MergeFounded := True;
          Exit;
        end;
  end;

  // ��������κγ�����Χ�ĺϲ�����,�����ɢ
  procedure DeleteAnyMerges;
  var
    i: Integer;
    MergeRect: TGridRect;
  begin
    // ��ɢ��߳�����Χ�ĺϲ�����
    i := DeleteRect.Bottom + 1;
    while i < RowCount do
    begin
      MergeRect := Merges[DeleteRect.Left, i]^;
      if (MergeRect.Left < DeleteRect.Left) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Bottom;
      end;
      Inc(i);
    end;
    // ��ɢ�ұ߳�����Χ�ĺϲ�����
    i := DeleteRect.Bottom + 1;
    while i < RowCount do
    begin
      MergeRect := Merges[DeleteRect.Right, i]^;
      if (MergeRect.Right > DeleteRect.Right) then
      begin
        DeleteMerges(TRect(MergeRect));
        i := MergeRect.Bottom;
      end;
      Inc(i);
    end;
  end;

begin
  DeleteHeight := DeleteRect.Bottom - DeleteRect.Top + 1;
  FindMerge;
  if MergeFounded then
    if Ask(DoYouWantDeleteMergedCells,2) then
      DeleteAnyMerges
    else
      Exit;
  // ��������
  ARect := TGridRect(DeleteRect);
  ARect.Top := DeleteRect.Bottom + 1;
  ARect.Bottom := RowCount - 1;
  CopyCellsToBuffer(ARect);
  Dec(ARect.Top, DeleteHeight);
  Dec(ARect.Bottom,DeleteHeight);
  PasteCellsFromBuffer(ARect);
  // ������������ Cells
  ARect.Top := RowCount - DeleteHeight + 1;
  ARect.Bottom := RowCount - 1;
  RestoreCells(TRect(ARect));
  ClearClipBoardBuffer;
  // ˢ������
  ARect := TGridRect(DeleteRect);
  ARect.Bottom := RowCount - 1;
  InvalidateRect(ARect);
  if Assigned(FOnDeleteCellDown) then
    FOnDeleteCellDown(Self, DeleteRect);
end;

procedure TCustomEasyGrid.DeleteCol(DeleteRect: TRect);
var
  DeleteWidth: Integer;
  ARect, OldSel: TGridRect;

  // ѭ������һ����Χ�ڵ� Cells ����(�ƶ�ָ��)
  procedure MoveColsR(StartCol, EndCol, XOffset: Integer);
  var
    HoleList: TList;
    ACol: Integer;
    // �ƶ�һ����ָ�벢�����ϲ�����
    procedure MoveACol(AColCellInfoList: TColCellInfoList; DestCol: Integer; AdjustMerge: Boolean);
    var
      ARow: Integer;
    begin
      // ��ָ�����
      FCells.Items[DestCol] := AColCellInfoList;
      // �����ϲ�����
      if AdjustMerge then
        for ARow:=0 to RowCount-1 do
          begin
            Dec(Cells[DestCol, ARow].Merge.Left, XOffset);
            Dec(Cells[DestCol, ARow].Merge.Right, XOffset);
          end;
    end;
    // **************************************************
  begin
    if (StartCol <= FixedCols) or
       (EndCol >= ColCount) or
       (StartCol > EndCol) then Exit;
    // �� HoleList ����ǰ�� XOffset ����ָ��(����)
    HoleList := TList.Create;
    for ACol:=StartCol to StartCol+XOffset-1 do
      HoleList.Add(FCells.Items[ACol]);
    // ��������������� XOffset ��λ��(������ǰ�� XOffset ����)
    for ACol:=StartCol+XOffset to EndCol do
      MoveACol(FCells.Items[ACol], ACol-XOffset, True);
    // �� HoleList �а�ǰ�� XOffset ���аᵽ���
    for ACol:=0 to XOffset-1 do
      MoveACol(HoleList.Items[ACol], EndCol-XOffset+1+ACol, False);
    HoleList.Free;
  end;

  // ���������еĵĺϲ�����
  procedure ReduceAnyMerges;
  var
    ARow, i: Integer;
    MergeRect: TGridRect;
  begin
    // �ӵ�һ�����²���
    ARow := 1;
    while ARow < RowCount do
    begin
      // ������߳���ĺϲ�����
      MergeRect := Merges[DeleteRect.Left, ARow]^;
      if (MergeRect.Left < DeleteRect.Left) then
        for i:=MergeRect.Left to DeleteRect.Left-1 do
          if (MergeRect.Right <= DeleteRect.Right) then
            Cells[i, ARow].Merge.Right := DeleteRect.Left-1
          else
            Dec(Cells[i, ARow].Merge.Right, DeleteWidth);
      // �����ұ߳���ĺϲ�����
      MergeRect := Merges[DeleteRect.Right, ARow]^;
      if (MergeRect.Right > DeleteRect.Right) then
        for i:=DeleteRect.Right+1 to MergeRect.Right do
          if (MergeRect.Left >= DeleteRect.Left) then
            Cells[i, ARow].Merge.Left := DeleteRect.Left+DeleteWidth
          else
            Inc(Cells[i, ARow].Merge.Left, DeleteWidth);
      Inc(ARow);
    end;
  end;

begin
  DeleteWidth  := DeleteRect.Right - DeleteRect.Left + 1;
  OldSel := Selection;
  // ����ɾ����Χ���еĵĺϲ�����
  ReduceAnyMerges;
  // ��ɾ����Χ�ڵ��лָ��ɳ�ʼ״̬
  ARect := TGridRect(DeleteRect);
  ARect.Top := 1;
  ARect.Bottom := RowCount-1;
  RestoreCells(TRect(ARect));
  // ����ѭ������(ɾ����Χ�ڵļ����б��Ƶ������)
  MoveColsR(DeleteRect.Left, ColCount-1, DeleteWidth);
  // ������󼸸���(�ı� ColCount ʱ���Զ�ˢ����Ļ)
  ARect.Left := ColCount - DeleteWidth;
  ARect.Right := ColCount - 1;
  RestoreCells(TRect(ARect));
  ColCount := ColCount - DeleteWidth;
  Restrict(OldSel.TopLeft, FixedCols+1, FixedRows+1, ColCount-1, RowCount-1);
  Restrict(OldSel.BottomRight, FixedCols+1, FixedRows+1, ColCount-1, RowCount-1);
  Selection := OldSel;
  if Assigned(FOnDeleteCol) then
    FOnDeleteCol(Self, DeleteRect);
end;

procedure TCustomEasyGrid.DeleteRow(DeleteRect: TRect);
var
  DeleteHeight: Integer;
  ARect, OldSel: TGridRect;

  // ѭ������һ����Χ�ڵ� Cells ����(�ƶ�ָ��)
  procedure MoveRowsR(StartRow, EndRow, YOffset: Integer);
  var
    HoleList: TList;
    ACol, ARow: Integer;
    // �ƶ�һ������ָ�벢�����ϲ�����
    procedure MoveACell(ACellInfo: PCellInfo; DestCol, DestRow: Integer; AdjustMerge: Boolean);
    begin
      // �ƶ�����ָ��
      TColCellInfoList(FCells.Items[DestCol]).Items[DestRow] := ACellInfo;
      // �����ϲ�����
      if AdjustMerge then
        begin
          Dec(Cells[DestCol, DestRow].Merge.Top, YOffset);
          Dec(Cells[DestCol, DestRow].Merge.Bottom, YOffset);
        end
      else
        begin
          Cells[DestCol, DestRow].Merge.Top := DestRow;
          Cells[DestCol, DestRow].Merge.Bottom := DestRow;
        end;
    end;
    // **************************************************
  begin
    if (StartRow <= FixedRows) or
       (EndRow >= RowCount) or
       (StartRow > EndRow) then Exit;
    HoleList := TList.Create;
    // ���ΰ���ÿ���е�����ָ��
    for ACol:=1 to ColCount-1 do
    begin
      HoleList.Clear;
      // �� HoleList ����ǰ�� YOffset ������ָ��(����)
      for ARow:=StartRow to (StartRow+YOffset-1) do
        HoleList.Add(Cells[ACol,ARow]);
      // �Ѹ�����������ָ�����ϰ��� YOffset ��λ��(������ǰ�� YOffset ��)
      for ARow:=StartRow+YOffset to EndRow do
        MoveACell(Cells[ACol, ARow], ACol, ARow-YOffset, True);
      // �� HoleList �а�ǰ�� YOffset ������ָ��ᵽ���
      for ARow:=0 to YOffset-1 do
        MoveACell(HoleList.Items[ARow], ACol, EndRow-YOffset+1+ARow, False);
    end;
    HoleList.Free;
  end;

  // ���������еĵĺϲ�����
  procedure ReduceAnyMerges;
  var
    ACol, i: Integer;
    MergeRect: TGridRect;
  begin
    // �ӵ�һ�����Ҳ���
    ACol := 1;
    while ACol < ColCount do
    begin
      // ������������ĺϲ�����
      MergeRect := Merges[ACol, DeleteRect.Top]^;
      if (MergeRect.Top < DeleteRect.Top) then
        for i:=MergeRect.Top to DeleteRect.Top-1 do
          if (MergeRect.Bottom <= DeleteRect.Bottom) then
            Cells[ACol, i].Merge.Bottom := DeleteRect.Top-1
          else
            Dec(Cells[ACol, i].Merge.Bottom, DeleteHeight);
      // �����ײ�����ĺϲ�����
      MergeRect := Merges[ACol, DeleteRect.Bottom]^;
      if (MergeRect.Bottom > DeleteRect.Bottom) then
        for i:=DeleteRect.Bottom+1 to MergeRect.Bottom do
          if (MergeRect.Top >= DeleteRect.Top) then
            Cells[ACol, i].Merge.Top := DeleteRect.Top+DeleteHeight
          else
            Inc(Cells[ACol, i].Merge.Top, DeleteHeight);
      Inc(ACol);
    end;
  end;

begin
  DeleteHeight  := DeleteRect.Bottom - DeleteRect.Top + 1;
  OldSel := Selection;
  // ����ɾ����Χ���еĵĺϲ�����
  ReduceAnyMerges;
  // ��ɾ����Χ�ڵ��лָ��ɳ�ʼ״̬
  ARect := TGridRect(DeleteRect);
  ARect.Left := 1;
  ARect.Right := ColCount-1;
  RestoreCells(TRect(ARect));
  // ����ѭ������(ɾ����Χ�ڵļ����б��Ƶ������)
  MoveRowsR(DeleteRect.Top, RowCount-1, DeleteHeight);
  // ������󼸸���(�ı� RowCount ʱ���Զ�ˢ����Ļ)
  RowCount := RowCount - DeleteHeight;
  Restrict(OldSel.TopLeft, FixedCols+1, FixedRows+1, ColCount-1, RowCount-1);
  Restrict(OldSel.BottomRight, FixedCols+1, FixedRows+1, ColCount-1, RowCount-1);
  Selection := OldSel;
  if Assigned(FOnDeleteRow) then
    FOnDeleteRow(Self, DeleteRect);
end;

procedure TCustomEasyGrid.Preview;
var
  Box: TPreviewBox;
begin
  if not HasPrinter then
  begin
    Say(NoPrinterInstalled);
    Exit;
  end;
  if FormPreview = nil then FormPreview := TFormPreview.Create(Self);
  FormPreview.CbxZoom.ItemIndex := FPreviewZoomIndex;
  FormPreview.CbxZoomChange(Self);
  Box := FormPreview.PreviewBoxEasyGrid;
  FormPreview.ParentGrid := Self;
  Box.CommonPageInfo := EasyGridPageInfo.CommonPageInfo;
  Try
    CalcPageDrawInfo(PageDrawInfoList);
  Except
    FormPreview.Release; FormPreview := nil;
    Raise; Exit;
  end;
  Box.PageCount := High(PageDrawInfoList) + 1;
  FormPreview.ShowModal;
  FPreviewZoomIndex := FormPreview.CbxZoom.ItemIndex;
  FormPreview.Release; FormPreview := nil;
end;

function TCustomEasyGrid.PrinterSetup: Boolean;
begin
  Result := False;
  if not HasPrinter then
  begin
    Say(NoPrinterInstalled);
    Exit;
  end;
  with TPrinterSetupDialog.Create(Self) do
    begin Result:=Execute; Free; end;
end;

procedure TCustomEasyGrid.PrintDialog;
begin
  if not HasPrinter then
  begin
    Say(NoPrinterInstalled);
    Exit;
  end;
  with TPrintDialog.Create(Self) do
    begin if Execute then Print; Free; end;
end;

procedure TCustomEasyGrid.PageSetup;
begin
  if not HasPrinter then
  begin
    Say(NoPrinterInstalled);
    Exit;
  end;
  FormPageSetup := TFormPageSetup.Create(Self);
  with FormPageSetup do
  begin
    PageCtlPageSetup.ActivePage := PageCtlPageSetup.Pages[FPageSetupPageIndex];
    ParentGrid := TEasyGrid(Self);
    ShowModal;
    if ModalResult = mrOk then
    begin
      // �����ҳ��Ϣ
      Try
        CalcPageDrawInfo(PageDrawInfoList);
      Except
        FPageSetupPageIndex := PageCtlPageSetup.ActivePage.PageIndex;
        FormPageSetup.Release;
        Raise; Exit;
      end;
      if FormPreview <> nil then
      begin
        FormPreview.PreviewBoxEasyGrid.CommonPageInfo := EasyGridPageInfo.CommonPageInfo;
        FormPreview.PreviewBoxEasyGrid.PageCount := High(PageDrawInfoList) + 1;
      end;
    end;
    FPageSetupPageIndex := PageCtlPageSetup.ActivePage.PageIndex;
  end;
  FormPageSetup.Release;
end;

procedure TCustomEasyGrid.Print;
var
  OldWindowExtent, OldViewPortExtent: TSize;
  OldMapMode, i: Integer;
  Zoom: TPoint;
  DrawRect: TRect;
  Box: TPreviewBox;
begin
  if not HasPrinter then
  begin
    Say(NoPrinterInstalled);
    Exit;
  end;
  if FormPreview = nil then FormPreview := TFormPreview.Create(Self);
  Box := FormPreview.PreviewBoxEasyGrid;
  FormPreview.ParentGrid := Self;
  Box.CommonPageInfo := EasyGridPageInfo.CommonPageInfo;
  // �����ҳ��Ϣ
  Try
    CalcPageDrawInfo(PageDrawInfoList);
  Except
    FormPreview.Release; FormPreview := nil;
    Raise; Exit;
  end;
  Box.PageCount := High(PageDrawInfoList) + 1;
  Printer.Orientation := Box.CommonPageInfo.Orientation;
  Printer.Title := PrintJobName;
  // ���ô�ӡ��ֽ������
  SetPaperSize(Box.CommonPageInfo.PaperSize,
               Round(Box.CommonPageInfo.PageHeight / ScreenToPrinterY * 10 / PrinterPixelsPerMmY),
               Round(Box.CommonPageInfo.PageWidth / ScreenToPrinterX * 10 / PrinterPixelsPerMmX));
  // ��ʼ��ӡ
  Printer.BeginDoc;
  for i:=0 to Box.PageCount-1 do
    with Printer.Canvas do
    begin
      with Box.CommonPageInfo do
        if (not PrintAllPages) and ((i < StartPage) or (i > EndPage)) then Continue;
      with Box.CommonPageInfo do
        DrawRect := Rect(Margin.Left, Margin.Top,
                         PageWidth - Margin.Right + 1,
                         PageHeight - Margin.Bottom + 1);

      // ����ӳ��ģʽ  MM_ANISOTROPIC ( ���� Scale ���� )
      Zoom.x := Round(100 / ScreenToPrinterX);
      Zoom.y := Round(100 / ScreenToPrinterY);
      OldMapMode := SetMapMode(Handle, MM_ANISOTROPIC);
      SetWindowExtEx(Handle,100,100,@OldWindowExtent);
      SetViewPortExtEx(Handle, Zoom.x, Zoom.y, @OldViewPortExtent);
      // ��ҳü��ҳ�š����⡢��β��Ϣ
      Box.DrawPage(Printer.Canvas, DrawRect, i, True);
      // �ָ�ӳ��ģʽ
      SetViewPortExtEx(Handle,OldViewPortExtent.cx,OldViewPortExtent.cy,nil);
      SetWindowExtEx(Handle,OldWindowExtent.cx,OldWindowExtent.cy,nil);
      SetMapMode(Handle, OldMapMode);

      // ����ӳ��ģʽ  MM_ANISOTROPIC ( ���� Scale ���� )
      Zoom.x := Round(Box.CommonPageInfo.Scale / ScreenToPrinterX);
      Zoom.y := Round(Box.CommonPageInfo.Scale / ScreenToPrinterY);
      OldMapMode := SetMapMode(Handle, MM_ANISOTROPIC);
      SetWindowExtEx(Handle,100,100,@OldWindowExtent);
      SetViewPortExtEx(Handle, Zoom.x, Zoom.y, @OldViewPortExtent);
      // ִ���Զ���滭����
      PrintPage(Printer.Canvas, DrawRect, i, True);
      // �ָ�ӳ��ģʽ
      SetViewPortExtEx(Handle,OldViewPortExtent.cx,OldViewPortExtent.cy,nil);
      SetWindowExtEx(Handle,OldWindowExtent.cx,OldWindowExtent.cy,nil);
      SetMapMode(Handle, OldMapMode);
      if (i < Box.PageCount-1) then Printer.NewPage;
    end;
  Printer.EndDoc;
end;

procedure TCustomEasyGrid.PrintPage(DrawCanvas: TCanvas; DrawRect: TRect;
  PageIndex: Integer; Printing: Boolean);
var
  i, SectionIndex: Integer;
  SectionLineColor: TColor;
  GridStartPos: TPoint;
  NewMajorOrigin, OldMajorOrigin: TSize;
  RangeRect: TRect;
  ConjunctionText: string;
  Box: TPreviewBox;
  DrawInfo: TEasyGridDrawInfo;

  function RangeExtent(AAxisDrawInfo: TEasyGridAxisDrawInfo; StartIndex, EndIndex : Integer) : Integer;
  var
    i : Integer;
  begin
    Result := 0;
    if StartIndex > EndIndex then Exit;
    with AAxisDrawInfo do
    for i := StartIndex to EndIndex do
      Inc(Result, GetExtent(i) + EffectiveLineWidth);
    Dec(Result, AAxisDrawInfo.EffectiveLineWidth);
  end;

  procedure PrintLines(SectionIndex: Integer; LineStartPos: TPoint; LineRange: TGridRect;
                       LineRangeRect: TRect; LineColor: TColor);
  var
    PointsList, StrokeList: PIntArray;
    MaxStroke: Integer;

    function CalcMaxStroke : Integer;
    var
      i,j,HorzStroke,VertStroke : Integer;
    begin
      Result := Max(LineRange.Right - LineRange.Left,
                    LineRange.Bottom - LineRange.Top) + 4;
      i := LineRange.Left;
      VertStroke := 0;
      while i <= LineRange.Right do
      begin
        j := LineRange.Top;
        while j <= LineRange.Bottom do
          if i <> Merges[i,j].Right then
             begin
               Inc(VertStroke);
               j := Merges[i,j].Bottom + 1;
             end
          else
             Inc(j);
        Inc(i);
      end;
      j := LineRange.Top;
      HorzStroke := 0;
      while j <= LineRange.Bottom do
      begin
        i := LineRange.Left;
        while i <= LineRange.Right do
        if j <> Merges[i,j].Bottom then
           begin
             Inc(HorzStroke);
             i := Merges[i,j].Right + 1;
           end
        else
           Inc(i);
        Inc(j);
      end;
      Result := Result + Max(HorzStroke,VertStroke);
    end;

    procedure DrawLines(DoHorz, DoVert: Boolean; StartCol, StartRow, EndCol, EndRow: Longint;
      const CellBounds: array of Integer; OnColor, OffColor: TColor);
    // ************************************************************
    // ����˵��
    // DoHorz,DoVert                    ��ʾ�Ƿ�ˮƽ������ֱ��
    // StartCol,StartRow,EndCol,EndRow  ��ʾ���ߵķ�Χ( Grid ���� )
    // CellBounds                       ��ʾ���߷�Χ( �������� )
    // OnColor,OffColor                 ������ɫ
    // ************************************************************
    const
      FlatPenStyle = PS_Geometric or PS_Solid or PS_EndCap_Flat or PS_Join_Miter;

      procedure DrawAxisLines(const AxisInfo: TEasyGridAxisDrawInfo;
        MajorIndex: Integer; UseOnColor: Boolean);
      // ************************************************************
      // Horizontal lines:  MajorIndex = 1
      // Vertical lines:    MajorIndex = 0
      // ************************************************************
      var
        LogBrush: TLOGBRUSH;
        Cell, Index: Integer;
        Points: PIntArray;
        StartMajor, StopMajor, StartMinor, StopMinor: Integer;
        MayHaveMerge : Boolean;
        AxisPoint, TopIndex: Integer;
        MergePoint: TPoint;

        function FindHorzMerge(ARow, StartIndex : Integer): TPoint;
        var
          I: Integer;
          AMergeRect: PGridRect;
        begin
          Result.x := -1;
          Result.y := -1;
          for i := StartIndex to EndCol do
          begin
            AMergeRect := Merges[i, ARow];
            if CellInMerge(i, ARow) and (ARow <> AMergeRect.Bottom) then
            begin
              Result.x := Max(StartIndex, AMergeRect.Left);
              Result.y := AMergeRect.Right;
              Exit;
            end;
          end;
        end;

        function FindVertMerge(ACol, StartIndex : Integer): TPoint;
        var
          i: Integer;
          AMergeRect: PGridRect;
        begin
          Result.x := -1;
          Result.y := -1;
          for i := StartIndex to EndRow do
          begin
            AMergeRect := Merges[ACol, i];
            if CellInMerge(ACol, i) and (ACol <> AMergeRect.Right) then
              begin
                Result.x := Max(StartIndex, AMergeRect.Top);
                Result.y := AMergeRect.Bottom;
                Exit;
              end;
          end;
        end;

      begin
        with DrawCanvas, AxisInfo do
        begin
          Pen.Style := psSolid;
          Pen.Mode := pmCopy;
          if EffectiveLineWidth <> 0 then
          begin
            Pen.Width := FGridLineWidth;
            if UseOnColor or (SectionIndex < 9) then
              Pen.Color := OnColor
            else
              Pen.Color := OffColor;
            if Pen.Width > 1 then
            begin
              LogBrush.lbStyle := BS_Solid;
              LogBrush.lbColor := Pen.Color;
              LogBrush.lbHatch := 0;
              Pen.Handle := ExtCreatePen(FlatPenStyle, Pen.Width, LogBrush, 0, nil);
            end;
            if MajorIndex = 0 then
               Cell := StartCol   // ������
            else
               Cell := StartRow; // ������
            // ��һ���ߵ�λ��
            StartMajor := CellBounds[MajorIndex] + EffectiveLineWidth shr 1 +
              GetExtent(Cell);
            // ���һ���ߵ�λ��
            StopMajor := CellBounds[2 + MajorIndex] + EffectiveLineWidth;
            // �������
            StartMinor := CellBounds[MajorIndex xor 1];
            // �����յ�
            StopMinor := CellBounds[2 + (MajorIndex xor 1)];
            MayHaveMerge := False;
            // �����Ƿ���ܴ��ںϲ�����
            if (SectionIndex >= 6) then MayHaveMerge := True;
            Points := PointsList;
            Index := 0;
            repeat
              if ((MajorIndex = 0) and (ColWidths[Cell] >= 0)) or
                 ((MajorIndex = 1) and (RowHeights[Cell] >= 0)) then
              begin
                // �������
                Points^[Index + MajorIndex] := StartMajor;         { MoveTo }
                Points^[Index + (MajorIndex xor 1)] := StartMinor;
                Inc(Index, 2);
                // ������ܴ��ںϲ�����
                if MayHaveMerge then
                begin
                  // ������
                  if (MajorIndex = 0) and (Cell <> EndCol) then
                  begin
                    TopIndex := StartRow;
                    AxisPoint := LineRangeRect.Top;
                    while (TopIndex <= EndRow) do
                      begin
                        MergePoint := FindVertMerge(Cell,TopIndex);
                        if (MergePoint.x > 0) then   //Have Merge
                          begin
                            Inc(AxisPoint, RangeExtent(DrawInfo.Vert, TopIndex, MergePoint.x - 1));
                            Points^[Index + MajorIndex] := StartMajor;         // LineTo
                            Points^[Index + (MajorIndex xor 1)] := Min(AxisPoint, LineRangeRect.Bottom);
                            Inc(Index, 2);
                            Inc(AxisPoint, EffectiveLineWidth);
                            if (Index >= 4) and (Points^[Index-1] = Points^[Index-3]) and
                               (Points^[Index-2] = Points^[Index-4]) then Dec(Index, 4);
                            Inc(AxisPoint, RangeExtent(DrawInfo.Vert, MergePoint.x, MergePoint.y));
                            Points^[Index + MajorIndex] := StartMajor;         // MoveTo
                            Points^[Index + (MajorIndex xor 1)] := Min(AxisPoint, LineRangeRect.Bottom);
                            Inc(Index, 2);
                            //Inc(AxisPoint, EffectiveLineWidth);
                            TopIndex := MergePoint.y + 1;
                          end
                        else
                          Inc(TopIndex);
                      end;
                  end
                  // ������
                  else if (MajorIndex = 1) and (Cell <> EndRow) then
                  begin
                    TopIndex := StartCol;
                    AxisPoint := LineRangeRect.Left;
                    while (TopIndex <= EndCol) do
                      begin
                        MergePoint := FindHorzMerge(Cell,TopIndex);
                        if MergePoint.x > 0 then
                          begin
                            Inc(AxisPoint, RangeExtent(DrawInfo.Horz, TopIndex, MergePoint.x - 1));
                            Points^[Index + MajorIndex] := StartMajor;         // LineTo
                            Points^[Index + (MajorIndex xor 1)] := Min(AxisPoint, LineRangeRect.Right);
                            Inc(Index, 2);
                            Inc(AxisPoint, EffectiveLineWidth);
                            if (Index >= 4) and (Points^[Index-1] = Points^[Index-3]) and
                               (Points^[Index-2] = Points^[Index-4]) then Dec(Index, 4);
                            Inc(AxisPoint, RangeExtent(DrawInfo.Horz, MergePoint.x, MergePoint.y));
                            Points^[Index + MajorIndex] := StartMajor;         // MoveTo
                            Points^[Index + (MajorIndex xor 1)] := Min(AxisPoint, LineRangeRect.Right);
                            Inc(Index, 2);
                            //Inc(AxisPoint, EffectiveLineWidth);
                            TopIndex := MergePoint.y + 1;
                          end
                        else
                          Inc(TopIndex);
                      end;
                  end;
                end;
                // �����յ�
                Points^[Index + MajorIndex] := StartMajor;         { LineTo }
                Points^[Index + (MajorIndex xor 1)] := StopMinor;
                Inc(Index, 2);
              end;
              Inc(Cell);
              Inc(StartMajor, GetExtent(Cell) + EffectiveLineWidth);
            until StartMajor > StopMajor;
            if ((SectionIndex = 4) or (SectionIndex = 7)) and (MajorIndex = 0) or
               ((SectionIndex = 5) or (SectionIndex = 8)) and (MajorIndex = 1) or
               (SectionIndex = 9) then Dec(Index, 4);
            if Index < 0 then Index := 0;
            PolyPolyLine(DrawCanvas.Handle, Points^, StrokeList^, Index shr 2);
          end;
        end;
      end;

    begin
      // ������յ���ͬ,����Ҫ����
      if (CellBounds[0] = CellBounds[2]) or (CellBounds[1] = CellBounds[3]) then Exit;
      // �ж��Ƿ���Ҫ�����ߵ�Ŀ����ʹ����������
      if not DoHorz then
      begin
        DrawAxisLines(DrawInfo.Vert, 1, DoHorz); // ��ˮƽ��
        DrawAxisLines(DrawInfo.Horz, 0, DoVert); // ����ֱ��
      end
      else
      begin
        DrawAxisLines(DrawInfo.Horz, 0, DoVert); // ����ֱ��
        DrawAxisLines(DrawInfo.Vert, 1, DoHorz); // ��ˮƽ��
      end;
    end;

  begin
    with DrawInfo do
    begin
      if (Horz.EffectiveLineWidth > 0) or (Vert.EffectiveLineWidth > 0) then
      begin
        // �������ʻ���
        MaxStroke := CalcMaxStroke;
        PointsList := StackAlloc(MaxStroke * sizeof(TPoint) * 2);
        StrokeList := StackAlloc(MaxStroke * sizeof(Integer));
        FillDWord(StrokeList^, MaxStroke, 2);

        DrawLines(goHorzLine in Options, goVertLine in Options,
          LineRange.Left, LineRange.Top, LineRange.Right, LineRange.Bottom,
          [LineRangeRect.Left, LineRangeRect.Top, LineRangeRect.Right, LineRangeRect.Bottom],
          LineColor, Color);

        StackFree(StrokeList);
        StackFree(PointsList);
      end;
    end;
  end;

  procedure PrintCells(Flag: Integer; CellStartPos: TPoint; CellRange: TGridRect; CellRangeRect: TRect);
  var
    CurCol, CurRow: Integer;
    NewPrintRgn, OldPrintRgn: HRgn;
    PrintHaveClip: Integer;
    MinHorzCell, MinVertCell: Integer;
    Where, IRect, CellDrawRect: TRect;
    MergeRect: TGridRect;

    procedure SetPrintClipRect(ClipR: TRect);
      // ���ڼ��������Ǿ�������,��ӳ��ģʽ������ԭ���޹�,����Ҫ�����ֹ��任
      procedure Convert(var Value: Integer; OrgOffset: Integer; ScreenToPrinter: Double);
      var
        NewZoom: Integer;
      begin
        if (Printing) or (Box.State = pbZoomIn) then NewZoom := 100
        else NewZoom := Box.Zoom;
        if not Printing then ScreenToPrinter := 1;
        Value := Round((Value + OrgOffset) * NewZoom / 100 * EasyGridPageInfo.CommonPageInfo.Scale / 100 / ScreenToPrinter);
      end;
    begin
      OldPrintRgn := 0;
      OldPrintRgn := CreateRectRgn(0,0,0,0);
      PrintHaveClip := GetClipRgn(DrawCanvas.Handle, OldRgn);
      Convert(ClipR.Left, NewMajorOrigin.cx, ScreenToPrinterX);
      Convert(ClipR.Right, NewMajorOrigin.cx, ScreenToPrinterX);
      Convert(ClipR.Top, NewMajorOrigin.cy, ScreenToPrinterY);
      Convert(ClipR.Bottom, NewMajorOrigin.cy, ScreenToPrinterY);
      NewPrintRgn := CreateRectRgnIndirect(ClipR);
      SelectClipRgn(DrawCanvas.Handle, NewPrintRgn);
      DeleteObject(NewPrintRgn);
    end;

    procedure RestorePrintClipRect;
    begin
      if PrintHaveClip > 0 then
        SelectClipRgn(DrawCanvas.Handle, OldPrintRgn)
      else
        SelectClipRgn(DrawCanvas.Handle, 0);
      DeleteObject(OldPrintRgn);
      PrintHaveClip := 0;
    end;

    function GetMinHorzCell: Integer;
    var
      i: Integer;
    begin
      Result := Merges[CellRange.Left, CellRange.Top].Left;
      for i:= CellRange.Top to CellRange.Bottom do
        Result := Min(Result, Merges[CellRange.Left, i].Left);
    end;

    function GetMinVertCell: Integer;
    var
      i: Integer;
    begin
      Result := Merges[CellRange.Left, CellRange.Top].Top;
      for i:= CellRange.Left to CellRange.Right do
        Result := Min(Result, Merges[i, CellRange.Top].Top);
    end;

    procedure PrintCell(ACol, ARow: Integer; TextRect, ClipR: TRect);
    var
      TextAlignMode: Cardinal;
      TextToDraw: PChar;
      BorderRect, ExpandRect, TestRect: TRect;    // �߿�Χ���ı��������Χ
      TestWidth, TestHeight: Integer;             // ʵ�ʿ��
      DrawWidth, DrawHeight: Integer;             // �滭�����

      // �����ı������ʵ�ʿ��
      procedure CalcTestRect;
      var
        CalcMode: Cardinal;
      begin
        TestRect := TextRect;
        with TestRect do
        begin
          Dec(Right, Left);
          Dec(Bottom, Top);
          Left := 0;
          Top := 0;
        end;
        CalcMode := DT_CALCRECT;
        if Cells[ACol, ARow].AutoWordBreak then
          CalcMode := CalcMode or DT_WORDBREAK;
        DrawText(DrawCanvas.Handle, TextToDraw, -1, TestRect, CalcMode);
        TestWidth :=  TestRect.Right  - TestRect.Left;
        TestHeight := TestRect.Bottom - TestRect.Top;
        DrawWidth :=  TextRect.Right  - TextRect.Left;
        DrawHeight := TextRect.Bottom - TextRect.Top;
        TestRect.Left := (DrawWidth - TestWidth) div 2;
        TestRect.Right := TestRect.Left + TestWidth;
        TestRect.Top := (DrawHeight - TestHeight) div 2;
        TestRect.Bottom := TestRect.Top + TestHeight;
      end;

    begin
      with Cells[ACol,ARow]^ do
        if DrawTop or DrawLeft or DrawRight or DrawBottom then
        begin
          // ���߿�
          with DrawCanvas do
          begin
            Pen.Color := clBlack;
            Pen.Width := LineWidth;
            Pen.Style := PenStyle;
          end;
          BorderRect := TextRect;
          // �ѱ߿���չ���߽���
          Inc(BorderRect.Top, LineWidth div 2 - 1);
          Inc(BorderRect.Left, LineWidth div 2 - 1);
          Dec(BorderRect.Right, LineWidth div 2);
          Dec(BorderRect.Bottom, LineWidth div 2);
          // �Ѽ��÷�Χ�������ɵ㣬�����ɱ߿�( ��ֹ���Ź����еľ��ȶ�ʧ )
          RestorePrintClipRect;
          ExpandRect := ClipR; InflateRect(ExpandRect, 5, 5);
          SetPrintClipRect(ExpandRect);
          if DrawTop then
             DrawLine(DrawCanvas, BorderRect.Left, BorderRect.Top, BorderRect.Right, BorderRect.Top);
          if DrawLeft then
             DrawLine(DrawCanvas, BorderRect.Left, BorderRect.Top, BorderRect.Left, BorderRect.Bottom);
          if DrawBottom then
             DrawLine(DrawCanvas, BorderRect.Left, BorderRect.Bottom, BorderRect.Right, BorderRect.Bottom);
          if DrawRight then
             DrawLine(DrawCanvas, BorderRect.Right, BorderRect.Top, BorderRect.Right, BorderRect.Bottom);
          // �ָ��ղŵļ��÷�Χ
          RestorePrintClipRect;
          SetPrintClipRect(ClipR);
        end;
      // ����ǻ��б�����(���б���������������Ҫ����ı�)
      if (ARow = 0) and (ACol <> 0) then
      begin
        with DrawCanvas do
        begin
          Font.Size := 10;
          if Printing then Font.Size := Round(Font.Size * ScreenToPrinterX);
          Font.Style := [];
          Font.Name := '����';
          Font.Color := clBlack;
        end;
        DrawText(DrawCanvas.Handle, PChar(ColTitle(ACol - 1)), -1, TextRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE)
      end
      // ����ǻ��б�����(���б���������������Ҫ����ı�)
      else if (ACol = 0) and (ARow <> 0) then
      begin
        with DrawCanvas do
        begin
          Font.Size := 10;
          if Printing then Font.Size := Round(Font.Size * ScreenToPrinterX);
          Font.Style := [];
          Font.Name := '����';
          Font.Color := clBlack;
        end;
        DrawText(DrawCanvas.Handle, PChar(IntToStr(ARow)), -1, TextRect, DT_CENTER or DT_VCENTER or DT_SINGLELINE)
      end
      // ����ǻ���������
      else
      begin
        InflateRect(TextRect, -2, -2);
        // �ѵ�ǰ�� Cell ���÷�Χ����

        IntersectClipRect(DrawCanvas.Handle, TextRect.Left, TextRect.Top,
                          TextRect.Right, TextRect.Bottom);
        with Cells[ACol,ARow]^ do
        if ((ShowForeText) and (ForeText <> '')) or
           ((not ShowForeText) and (BackText <> '')) then
          begin
            // ʵ��������ı�
            if ShowForeText then
              TextToDraw := PChar(ForeText)
            else
              TextToDraw := PChar(BackText);
            // ��������
            with DrawCanvas do
            begin
              Font.Name := FontName;
              Font.Size := FontSize;
              if Printing then Font.Size := Round(Font.Size * ScreenToPrinterX);
              if EasyGridPageInfo.DetailPageInfo.MonoColored then
                Font.Color := clBlack
              else
                Font.Color := FontColor;
              Font.Style := FontStyle;
            end;
            // �����ı������ʵ�ʿ��
            CalcTestRect;
            // �ı���������(��ֱ���к͵ײ�������Ҫ�ֹ�����)
            TextAlignMode := 0;
            case AlignMode of
              taTopLeft :    // �ı���������
                TextAlignMode := DT_TOP or DT_LEFT;
              taTop :        // �ı����ڶ�������
                TextAlignMode := DT_TOP or DT_CENTER;
              taTopRight :   // �ı���������
                TextAlignMode := DT_TOP or DT_RIGHT;
              taLeft :       // �ı�����������
                begin
                  TextAlignMode := DT_LEFT;
                  Inc(TextRect.Top, TestRect.Top);
                end;
              taCenter :     // �ı���������
                begin
                  TextAlignMode := DT_CENTER;
                  Inc(TextRect.Top, TestRect.Top);
                end;
              taRight :      // �ı������Ҳ�����
                begin
                  TextAlignMode := DT_RIGHT;
                  Inc(TextRect.Top, TestRect.Top);
                end;
              taBottomLeft :  // �ı���������
                begin
                  TextAlignMode := DT_LEFT;
                  TextRect.Top := TextRect.Bottom - TestHeight;
                end;
              taBottom :      // �ı����ڵײ�����
                begin
                  TextAlignMode := DT_CENTER;
                  TextRect.Top := TextRect.Bottom - TestHeight;
                end;
              taBottomRight : // �ı���������
                begin
                  TextAlignMode := DT_RIGHT;
                  TextRect.Top := TextRect.Bottom - TestHeight;
                end;
            end;
            if AutoWordBreak then
              TextAlignMode := TextAlignMode or DT_WORDBREAK;
            DrawText(DrawCanvas.Handle, TextToDraw, -1, TextRect, TextAlignMode);
          end;
          // �ָ��� PrintCell ֮ǰ�ļ���״̬
          RestorePrintClipRect;
          SetPrintClipRect(ClipR);
        end;
    end;

  begin
    SetPrintClipRect(CellRangeRect);
    MinHorzCell := GetMinHorzCell;
    MinVertCell := GetMinVertCell;
    CellDrawRect := CellRangeRect;
    Dec(CellDrawRect.Left, RangeExtent(DrawInfo.Horz, MinHorzCell, CellRange.Left-1));
    Dec(CellDrawRect.Top,  RangeExtent(DrawInfo.Vert, MinVertCell, CellRange.Top-1));
    if MinHorzCell <> CellRange.Left then Dec(CellDrawRect.Left);
    if MinVertCell <> CellRange.Top  then Dec(CellDrawRect.Top);
    Where.Top := CellDrawRect.Top;
    for CurRow := MinVertCell to CellRange.Bottom do
    begin
      Where.Left := CellDrawRect.Left;
      for CurCol := MinHorzCell to CellRange.Right do
      begin
        MergeRect := Merges[CurCol,CurRow]^;
        Where.Right := Where.Left + RangeExtent(DrawInfo.Horz, CurCol, MergeRect.Right);
        Where.Bottom := Where.Top + RangeExtent(DrawInfo.Vert, CurRow, MergeRect.Bottom);
        // ������� Cell
        if (Where.Right > Where.Left) and (Where.Bottom > Where.Top) and
           (CurCol = MergeRect.Left) and
           (CurRow = MergeRect.Top) and
           InterSectRect(IRect,Where,CellRangeRect) then
        begin
          // ********************************************************
          // �� Cell ����(�����Ҫ�Ļ�)
          with DrawCanvas do
          begin
            // �жϻ�����ʹ�õ���ɫ
            Brush.Style := bsSolid;
            Brush.Color := clWhite;
            if not EasyGridPageInfo.DetailPageInfo.MonoColored then // ����ǲ�ɫ��ӡ
            begin
              if ((CurCol = 0) or (CurRow = 0)) then
                 Brush.Color := FTitleColor
              else
                 Brush.Color := Colors[CurCol, CurRow];
            end;
            FillRect(Where);
          end;

          // ********************************************************
          // �� Cell ����
          Brush.Style := bsClear;
          PrintCell(CurCol, CurRow, Where, CellRangeRect);
        end;
        Inc(Where.Left, ColWidths[CurCol] + DrawInfo.Horz.EffectiveLineWidth);
      end;
      Inc(Where.Top, RowHeights[CurRow] + DrawInfo.Vert.EffectiveLineWidth);
    end;
    RestorePrintClipRect;
  end;

begin
  CalcDrawInfo(DrawInfo);
  Box := FormPreview.PreviewBoxEasyGrid;
  i := 0;
  while (i <= High(PageDrawInfoList)) do
  begin
    if PageDrawInfoList[i].Index = PageIndex then Break;
    Inc(i);
  end;
  with DrawCanvas do
  begin
    Pen.Color := clBlack;
    Pen.Width := FGridLineWidth;
    Pen.Mode := pmCopy;
  end;
  with PageDrawInfoList[i], EasyGridPageInfo.DetailPageInfo, EasyGridPageInfo.CommonPageInfo do
  begin
    // ���ñ������ԭ��
    NewMajorOrigin.cx := Margin.Left;
    if (SplitCoord.y = 0) then
      NewMajorOrigin.cy := Margin.Top + HeaderExtent + ExtraHeaderExtent +
                           TitleExtent + ExtraTitleExtent
    else
      NewMajorOrigin.cy := Margin.Top + HeaderExtent + ExtraHeaderExtent;
    NewMajorOrigin.cx := Round(NewMajorOrigin.cx * 100 / Scale);
    NewMajorOrigin.cy := Round(NewMajorOrigin.cy * 100 / Scale);
    if (not Printing) and (PageIndex = Box.PageIndex) then
      begin Inc(NewMajorOrigin.cx, 2); Inc(NewMajorOrigin.cy, 2); end;
    SetWindowOrgEx(DrawCanvas.Handle, -NewMajorOrigin.cx, -NewMajorOrigin.cy, @OldMajorOrigin);

    // ������������ʼλ��
    for SectionIndex := 9 downto 1 do
      if Section[SectionIndex].Included then GridStartPos := Section[SectionIndex].StartPos;

    // ��ӡ�������ݲ���
    for SectionIndex := 1 to 9 do
      with Section[SectionIndex] do
        if Included then
        begin
          RangeRect := Rect(StartPos.x, StartPos.y, StartPos.x + Size.cx + FGridLineWidth,
                            StartPos.y + Size.cy + FGridLineWidth);
          PrintCells(SectionIndex, StartPos, Range, RangeRect);
        end;
    // ��ӡ���˳нӴʲ���
    with TopConjunction do
    if Included then
    begin
      RangeRect := Rect(StartPos.x, StartPos.y, StartPos.x + Size.cx + FGridLineWidth,
                        StartPos.y + Size.cy + FGridLineWidth);
      with DrawCanvas do
      begin
        Brush.Color := clWhite;
        Pen.Color := clBlack;
        Pen.Width := FGridLineWidth;
        Pen.Mode := pmCopy;
        Pen.Style := psSolid;
        Font.Name := '����';
        Font.Size := 9;
        if Printing then Font.Size := Round(Font.Size * ScreenToPrinterX);
        Font.Color := clBlack;
        Font.Style := [fsBold];
      end;
      ConjunctionText := TopConjunctionText;
      InflateRect(RangeRect, -1, -1);
      DrawText(DrawCanvas.Handle, PChar(ConjunctionText), 10, RangeRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;
    // ��ӡ�����
    for SectionIndex := 9 downto 1 do
      with Section[SectionIndex] do
        if Included then
        if {(SectionIndex < 6) or }PrintGridLine then
        begin
          RangeRect := Rect(StartPos.x, StartPos.y, StartPos.x + Size.cx,
                            StartPos.y + Size.cy);
          if (SectionIndex = 9) then SectionLineColor := clSilver else
            SectionLineColor := clBlack;
          PrintLines(SectionIndex, StartPos, Range, RangeRect, SectionLineColor)
        end;
    // ��ӡ�׶˳нӴʲ���
    with BottomConjunction do
    if Included then
    begin
      RangeRect := Rect(StartPos.x, StartPos.y, StartPos.x + Size.cx + FGridLineWidth,
                        StartPos.y + Size.cy + FGridLineWidth);
      with DrawCanvas do
      begin
        Brush.Color := clWhite;
        Pen.Color := clBlack;
        Pen.Width := FGridLineWidth;
        Pen.Mode := pmCopy;
        Pen.Style := psSolid;
        Font.Name := '����';
        Font.Size := 9;
        if Printing then Font.Size := Round(Font.Size * ScreenToPrinterX);
        Font.Color := clBlack;
        Font.Style := [fsBold];
      end;
      ConjunctionText := BottomConjunctionText;
      InflateRect(RangeRect, -1, -1);
      DrawText(DrawCanvas.Handle, PChar(ConjunctionText), 10, RangeRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE);
    end;

    // ��ӡ���ı߿�
    with DrawCanvas do
    begin
      Brush.Color := clWhite;
      Brush.Style := bsClear;
      Pen.Color := clBlack;
      Pen.Style := psSolid;
      Pen.Width := FGridLineWidth;
      Pen.Mode := pmCopy;
      // ���㶥�˳нӴʱ߿�
      with TopConjunction do
      if Included then
        Rectangle(StartPos.x, StartPos.y,
                 StartPos.x + Size.cx + FGridLineWidth, StartPos.y + Size.cy + FGridLineWidth);
      // ������߿�
      with Section[9] do
      if Included and PrintGridLine then
      Rectangle(GridStartPos.x, GridStartPos.y - FGridLineWidth,
                StartPos.x + Size.cx + FGridLineWidth,
                StartPos.y + Size.cy + FGridLineWidth);
      // ����׶˳нӴʱ߿�
      with BottomConjunction do
      if Included then
        Rectangle(StartPos.x, StartPos.y,
                 StartPos.x + Size.cx + FGridLineWidth, StartPos.y + Size.cy);
    end;
    // �ָ��������ԭ��
    SetWindowOrgEx(DrawCanvas.Handle, OldMajorOrigin.cx, OldMajorOrigin.cy, nil);
  end;
end;

procedure TCustomEasyGrid.CalcPageDrawInfo(var APageDrawInfoList: TPageDrawInfoList);
var
  DrawInfo: TEasyGridDrawInfo;
  AvgPageWidth, AvgPageHeight, FirstPageHeight, LastPageHeight: Integer;

  function GetRangeExtent(AAxisDrawInfo: TEasyGridAxisDrawInfo; StartCell, EndCell: Integer; UseScale: Boolean = False): Integer;
  var
    i: Integer;
  begin
    Result := 0;
    if (StartCell > EndCell) then Exit;
    with AAxisDrawInfo do
    for i:=StartCell To EndCell do
      Inc(Result,GetExtent(i)+EffectiveLineWidth);
    if StartCell <= EndCell then
    Dec(Result, AAxisDrawInfo.EffectiveLineWidth);
    if UseScale then
      Result := Round(Result * EasyGridPageInfo.CommonPageInfo.Scale / 100);
  end;

  // ����ˮƽ�봹ֱ��ҳ��
  function CalcSplitPoints(AAxisDrawInfo: TEasyGridAxisDrawInfo; PointsList: PDynaIntArray; IsHorz: Boolean): Integer;
  var
    AxisIndex, CurCell, PageExtent, RangeExtent: Integer;
    IncludeTitle, IncludeFixed, IncludeConjunction: Boolean;
  begin
    with EasyGridPageInfo.CommonPageInfo, EasyGridPageInfo.DetailPageInfo do
    begin
      IncludeTitle := False; IncludeFixed := False; IncludeConjunction := False;
      if IsHorz then
        begin
          if PrintRowTitle then IncludeTitle := True;
          if PrintFixedCols then IncludeFixed := True;
        end
      else
        begin
          if PrintColTitle then IncludeTitle := True;
          if PrintFixedRows then IncludeFixed := True;
          if PrintConjunction then IncludeConjunction := True;
        end
    end;
    CurCell := AAxisDrawInfo.FixedCellCount + 1;
    AxisIndex := 1;
    while True do
    begin
      if IsHorz then PageExtent := AvgPageWidth
      else
        begin
          if AxisIndex = 1 then
            begin
              PageExtent := FirstPageHeight;
              if IncludeConjunction then
                Dec(PageExtent, Round((DefaultRowHeight+FGridLineWidth) * 1 * EasyGridPageInfo.CommonPageInfo.Scale / 100));
            end
          else
            begin
              PageExtent := AvgPageHeight;
              if IncludeConjunction
                then Dec(PageExtent, Round((DefaultRowHeight+FGridLineWidth) * 2 * EasyGridPageInfo.CommonPageInfo.Scale / 100));
            end;
        end;
      with AAxisDrawInfo do
      begin
        RangeExtent := 0;
        if IncludeTitle then Inc(RangeExtent, GetRangeExtent(AAxisDrawInfo,0,0,True)+EffectiveLineWidth);
        if IncludeFixed or (AxisIndex = 1) then
          Inc(RangeExtent, GetRangeExtent(AAxisDrawInfo,1,FixedCellCount,True)+EffectiveLineWidth);
        if (RangeExtent >= PageExtent) then
          Raise Exception.Create(TitleTooBig);
        if (Round((GetExtent(CurCell)+EffectiveLineWidth) * EasyGridPageInfo.CommonPageInfo.Scale / 100) <= PageExtent) then
          while (CurCell < GridCellCount) do
          begin
            Inc(RangeExtent, Round((GetExtent(CurCell)+EffectiveLineWidth) * EasyGridPageInfo.CommonPageInfo.Scale / 100));
            if (RangeExtent > PageExtent) then Break;
            Inc(CurCell);
          end
        else
          Inc(CurCell);
      end;
      SetLength(PointsList^, AxisIndex);
      PointsList^[AxisIndex-1] := CurCell - 1;
      Inc(AxisIndex);
      if CurCell >= AAxisDrawInfo.GridCellCount then Break;
    end;
  Dec(AxisIndex);
  Result := AxisIndex;
  end;

  procedure CalcPageDrawInfoList;
  var
    i, j, TotalPageCount, HorzPageCount, VertPageCount: Integer;
    HorzIndex, VertIndex, GridWidth, GridHeight: Integer;
    RealPageHeight, HorzAlign, VertAlign: Integer;
    HorzSplitPoints, VertSplitPoints: array of Integer;
    StartPoint: TPoint;
  begin
    with EasyGridPageInfo.CommonPageInfo, EasyGridPageInfo.DetailPageInfo do
    begin
      // ҳ��ƽ�����
      AvgPageWidth := PageWidth - (Margin.Left + Margin.Right);
      AvgPageHeight := PageHeight - (Margin.Top + Margin.Bottom +
                       HeaderExtent + FooterExtent + ExtraHeaderExtent + ExtraFooterExtent);
      // ��ҳ��ĩҳ�߶�
      FirstPageHeight := AvgPageHeight - (TitleExtent + ExtraTitleExtent);
      LastPageHeight := AvgPageHeight - TailExtent;
      // ˮƽ��ҳ������ֱ��ҳ������ҳ��
      HorzPageCount := CalcSplitPoints(DrawInfo.Horz, @HorzSplitPoints, True);
      VertPageCount := CalcSplitPoints(DrawInfo.Vert, @VertSplitPoints, False);
      if VertPageCount = 1 then
        Dec(LastPageHeight, TitleExtent + ExtraTitleExtent);
      TotalPageCount := HorzPageCount * VertPageCount;
      SetLength(APageDrawInfoList, TotalPageCount);
      for i := 0 to TotalPageCount - 1 do
      begin
        with APageDrawInfoList[i] do
        begin
          HorzIndex := i mod HorzPageCount;     // ˮƽҳ��
          VertIndex := i div HorzPageCount;     // ��ֱҳ��
          if HorzSplit then Index := i else     // ���ݷ�ҳ��ʽ����ҳ��
            Index := HorzIndex * VertPageCount + VertIndex;
          StartPoint.x := 0; StartPoint.y := 0; // ��ʼ����
          // �����һ����: ������������
          with Section[1], DrawInfo do
            if (not PrintColTitle) or (not PrintRowTitle) then Included := False
            else
              begin
                Included := True;
                StartPos := StartPoint;
                Range := TGridRect(Rect(0,0,0,0));
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ����ڶ�����: �б�������̶��н�����
          with Section[2], DrawInfo do
            if (not PrintColTitle) or ((HorzIndex > 0) and (not PrintFixedCols)) then
              Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                if Section[1].Included then
                  Inc(StartPos.x, Section[1].Size.cx);
                StartPos.y := StartPoint.y;
                Range := TGridRect(Rect(1,0,Horz.FixedCellCount,0));
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ������Ĳ���: �б��������н�����
          with Section[4], DrawInfo do
            if (not PrintColTitle) then Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                if Section[1].Included then
                  Inc(StartPos.x, Section[1].Size.cx);
                if Section[2].Included then
                  Inc(StartPos.x, Section[2].Size.cx);
                StartPos.y := StartPoint.y;
                if (HorzIndex = 0) then
                  Range.Left := Horz.FixedCellCount + 1
                else
                  Range.Left := HorzSplitPoints[HorzIndex-1]+1;
                Range.Right := HorzSplitPoints[HorzIndex];
                Range.Top := 0; Range.Bottom := 0;
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // �����������: �б�������̶��н�����
          with Section[3], DrawInfo do
            if (not PrintRowTitle) or ((VertIndex > 0) and (not PrintFixedRows)) then
              Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                StartPos.y := StartPoint.y;
                if Section[1].Included then
                  Inc(StartPos.y, Section[1].Size.cy);
                Range := TGridRect(Rect(0,1,0,Vert.FixedCellCount));
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // �����������: �̶���������
          with Section[6], DrawInfo do
            if (HorzIndex > 0) and (not PrintFixedCols) or
               (VertIndex > 0) and (not PrintFixedRows) then Included := False
            else
              begin
                Included := True;
                StartPos := StartPoint;
                if Section[3].Included then
                  Inc(StartPos.x, Section[3].Size.cx);
                if Section[2].Included then
                  Inc(StartPos.y, Section[2].Size.cy);
                Range := TGridRect(Rect(1,1,Horz.FixedCellCount,Vert.FixedCellCount));
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ������߲���: �̶������н�����
          with Section[7], DrawInfo do
            if (VertIndex > 0) and (not PrintFixedRows) then
              Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                if Section[3].Included then
                  Inc(StartPos.x, Section[3].Size.cx);
                if Section[6].Included then
                  Inc(StartPos.x, Section[6].Size.cx);
                StartPos.y := StartPoint.y;
                if Section[4].Included then
                  Inc(StartPos.y, Section[4].Size.cy);
                if (HorzIndex = 0) then
                  Range.Left := Horz.FixedCellCount + 1
                else
                  Range.Left := HorzSplitPoints[HorzIndex-1]+1;
                Range.Right := HorzSplitPoints[HorzIndex];
                Range.Top := 1; Range.Bottom := Vert.FixedCellCount;
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ���㶥�˳нӴʲ���
          with TopConjunction, DrawInfo do
            if (not PrintConjunction) or
               (VertIndex = 0) then Included := False
            else
              begin
                Included := True;
                StartPos := StartPoint;
                if Section[4].Included then
                  Inc(StartPos.y, Section[4].Size.cy);
                if Section[7].Included then
                  Inc(StartPos.y, Section[7].Size.cy);
                Range := TGridRect(Rect(0,0,0,0));
                Size.cx := AvgPageWidth;
                Size.cy := DefaultRowHeight;
                Inc(StartPoint.y, Size.cy + FGridLineWidth);
              end;
          // ������岿��: �б��������н�����
          with Section[5], DrawInfo do
            if (not PrintRowTitle) then Included := False
            else
              begin
                Included := True;
                StartPos := StartPoint;
                if Section[1].Included then
                  Inc(StartPos.y, Section[1].Size.cy);
                if Section[3].Included then
                  Inc(StartPos.y, Section[3].Size.cy);
                if (VertIndex = 0) then
                  Range.Top := Vert.FixedCellCount + 1
                else
                  Range.Top := VertSplitPoints[VertIndex-1]+1;
                Range.Bottom := VertSplitPoints[VertIndex];
                Range.Left := 0; Range.Right := 0;
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ����ڰ˲���: �̶������н�����
          with Section[8], DrawInfo do
            if (HorzIndex > 0) and (not PrintFixedCols) then
              Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                if Section[5].Included then
                  Inc(StartPos.x, Section[5].Size.cx);
                StartPos.y := StartPoint.y;
                if Section[2].Included then
                  Inc(StartPos.y, Section[2].Size.cy);
                if Section[6].Included then
                  Inc(StartPos.y, Section[6].Size.cy);
                if (VertIndex = 0) then
                  Range.Top := Vert.FixedCellCount + 1
                else
                  Range.Top := VertSplitPoints[VertIndex-1]+1;
                Range.Bottom := VertSplitPoints[VertIndex];
                Range.Left := 1; Range.Right := Horz.FixedCellCount;
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ����ھŲ���: ���
          with Section[9], DrawInfo do
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                if Section[5].Included then
                  Inc(StartPos.x, Section[5].Size.cx);
                if Section[8].Included then
                  Inc(StartPos.x, Section[8].Size.cx);
                StartPos.y := StartPoint.y;
                if Section[4].Included then
                  Inc(StartPos.y, Section[4].Size.cy);
                if Section[7].Included then
                  Inc(StartPos.y, Section[7].Size.cy);
                if (HorzIndex = 0) then
                  Range.Left := Horz.FixedCellCount + 1
                else
                  Range.Left := HorzSplitPoints[HorzIndex-1]+1;
                Range.Right := HorzSplitPoints[HorzIndex];
                if (VertIndex = 0) then
                  Range.Top := Vert.FixedCellCount + 1
                else
                  Range.Top := VertSplitPoints[VertIndex-1]+1;
                Range.Bottom := VertSplitPoints[VertIndex];
                Size.cx := GetRangeExtent(Horz, Range.Left, Range.Right);
                Size.cy := GetRangeExtent(Vert, Range.Top, Range.Bottom);
              end;
          // ����׶˳нӴʲ���
          with BottomConjunction, DrawInfo do
            if (not PrintConjunction) or
               ((HorzIndex = HorzPageCount-1) and (VertIndex = VertPageCount-1)) then
                 Included := False
            else
              begin
                Included := True;
                StartPos.x := StartPoint.x;
                StartPos.y := Section[9].StartPos.y + Section[9].Size.cy;
                Range := TGridRect(Rect(0,0,0,0));
                Size.cx := AvgPageWidth;
                Size.cy := DefaultRowHeight;
              end;
          SplitCoord.x := HorzIndex; SplitCoord.y := VertIndex;
          // �������ʵ�ʿ��
          GridWidth := 0; GridHeight := 0;
          if Section[5].Included then Inc(GridWidth, Section[5].Size.cx);
          if Section[8].Included then Inc(GridWidth, Section[8].Size.cx);
          if Section[9].Included then Inc(GridWidth, Section[9].Size.cx);
          if TopConjunction.Included then Inc(GridHeight, TopConjunction.Size.cy);
          if Section[4].Included then Inc(GridHeight, Section[4].Size.cy);
          if Section[7].Included then Inc(GridHeight, Section[7].Size.cy);
          if Section[9].Included then Inc(GridHeight, Section[9].Size.cy);
          if BottomConjunction.Included then Inc(GridHeight, BottomConjunction.Size.cy);
          // ����ˮƽ����ʱ�ĺ�����
          if HorzCenter then
          begin
            HorzAlign := Round((AvgPageWidth - GridWidth * Scale / 100) * 100 / Scale) div 2;
            Inc(Section[1].StartPos.x, HorzAlign);
            Inc(Section[2].StartPos.x, HorzAlign);
            Inc(Section[3].StartPos.x, HorzAlign);
            Inc(Section[4].StartPos.x, HorzAlign);
            Inc(Section[5].StartPos.x, HorzAlign);
            Inc(Section[6].StartPos.x, HorzAlign);
            Inc(Section[7].StartPos.x, HorzAlign);
            Inc(Section[8].StartPos.x, HorzAlign);
            Inc(Section[9].StartPos.x, HorzAlign);
            if TopConjunction.Included then
              begin
                Inc(TopConjunction.StartPos.x, HorzAlign);
                BottomConjunction.StartPos.x := TopConjunction.StartPos.x;
              end
            else
              Inc(BottomConjunction.StartPos.x, HorzAlign);
          end;
          TopConjunction.Size.cx := GridWidth;
          BottomConjunction.Size.cx := GridWidth;
          // ���㴹ֱ����ʱ��������
          VertAlign := 0;
          if VertCenter then
          begin
            RealPageHeight := AvgPageHeight;
            if VertIndex = 0 then RealPageHeight := FirstPageHeight;
            VertAlign := Round((RealPageHeight - GridHeight * Scale / 100) * 100 / Scale) div 2;
            Inc(TopConjunction.StartPos.y, VertAlign);
            Inc(Section[1].StartPos.y, VertAlign);
            Inc(Section[2].StartPos.y, VertAlign);
            Inc(Section[3].StartPos.y, VertAlign);
            Inc(Section[4].StartPos.y, VertAlign);
            Inc(Section[5].StartPos.y, VertAlign);
            Inc(Section[6].StartPos.y, VertAlign);
            Inc(Section[7].StartPos.y, VertAlign);
            Inc(Section[8].StartPos.y, VertAlign);
            Inc(Section[9].StartPos.y, VertAlign);
            Inc(BottomConjunction.StartPos.y, VertAlign);
          end;
        end;
        // ������һҳ��񸲸��˱�β����, ������һҳ��ӡ��β����
        if (i = TotalPageCount - 1) and (Round((GridHeight + VertAlign) * Scale / 100) > LastPageHeight) then
        begin
          SetLength(APageDrawInfoList, TotalPageCount + 1);
          with APageDrawInfoList[TotalPageCount] do
          begin
            TopConjunction.Included := False;
            BottomConjunction.Included := False;
            for j := 1 to 9 do Section[j].Included := False;
            Index := TotalPageCount;
          end;
        end;
      end;
    end;
  end;

begin
  CalcDrawInfo(DrawInfo);
  CalcPageDrawInfoList;
end;

{ TEasyGridPageInfo }

constructor TEasyGridPageInfo.Create;
begin
  Inherited Create;
  CommonPageInfo := TCommonPageInfo.Create;
  with Self.DetailPageInfo do
  begin
    MonoColored := True;
    HorzCenter := True;
    VertCenter := False;
    HorzSplit := True;
    PrintGridLine := True;
    PrintColTitle := False;
    PrintRowTitle := False;
    PrintFixedCols := False;
    PrintFixedRows := True;
    PrintConjunction := False;
    TopConjunctionText := '  ��ǰҳ  ';
    BottomConjunctionText := '  ����ҳ  ';
  end;
end;

destructor TEasyGridPageInfo.Destroy;
begin
  CommonPageInfo.Free;
  Inherited Destroy;
end;

procedure TEasyGridPageInfo.LoadFromFile(FileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName,fmOpenRead);
  try
    LoadFromStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TEasyGridPageInfo.LoadFromStream(AFileStream: TFileStream);
begin
  AFileStream.Read(DetailPageInfo, SizeOf(DetailPageInfo));
  CommonPageInfo.LoadFromStream(AFileStream);
end;

procedure TEasyGridPageInfo.SaveToFile(FileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName,fmCreate);
  try
    SaveToStream(FileStream);
  finally
    FileStream.Free;
  end;
end;

procedure TEasyGridPageInfo.SaveToStream(AFileStream: TFileStream);
begin
  AFileStream.Write(DetailPageInfo, SizeOf(DetailPageInfo));
  CommonPageInfo.SaveToStream(AFileStream);
end;


initialization
  CF_EASYGRID := RegisterClipboardFormat('Discovery EasyGrid');
finalization
end.
