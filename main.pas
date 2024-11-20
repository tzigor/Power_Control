unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ComCtrls, ExtCtrls, IniPropStorage, synaser, jwawinbase, jwawinnt, Utils,
  Chart, UserTypes, LCLTranslator, DateUtils, Port;

type

  { TApp }

  TApp = class(TForm)
    ConnectionStatusLbl: TLabel;
    Label1: TLabel;
    Label13: TLabel;
    Panel7: TPanel;
    PowerStatus: TLabel;
    TurnOfOnOver: TCheckBox;
    IniPropStorage1: TIniPropStorage;
    ProgramBtn: TButton;
    CVInd: TShape;
    CloseBtn: TButton;
    COMselectCB: TComboBox;
    ConnectBtn: TButton;
    CCInd: TShape;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LockInd: TShape;
    AlarmInd: TShape;
    AlarmSw: TToggleBox;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    SetOCP: TFloatSpinEdit;
    SetVoltage: TFloatSpinEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    SetCurrent: TFloatSpinEdit;
    SetOVP: TFloatSpinEdit;
    SetVoltageBar: TTrackBar;
    SetOVPBar: TTrackBar;
    SetCurrentBar: TTrackBar;
    SetOCPBar: TTrackBar;
    OutputInd: TShape;
    OutputSw: TToggleBox;
    LockSw: TToggleBox;
    Timer1: TTimer;
    Voltage: TLabel;
    Current: TLabel;
    procedure AlarmSwChange(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ConnectBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LockSwChange(Sender: TObject);
    procedure OutputSwChange(Sender: TObject);
    procedure ProgramBtnClick(Sender: TObject);
    procedure SetCurrentBarChange(Sender: TObject);
    procedure SetCurrentChange(Sender: TObject);
    procedure SetOCPBarChange(Sender: TObject);
    procedure SetOCPChange(Sender: TObject);
    procedure SetOVPBarChange(Sender: TObject);
    procedure SetOVPChange(Sender: TObject);
    procedure SetVoltageBarChange(Sender: TObject);
    procedure SetVoltageChange(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  App: TApp;

  OutputControl : Byte;
  BackData      : TBackData;

Const
  NewLine     = #13#10;
  TIME_OUT    = 3000;  { 3 sec }

var
  ser                 : TBlockSerial; { current serial port }
  mon                 : Boolean;      { port monitoring enable }
  FreePortsAvailable  : Boolean;
  ConnectionStatus    : Boolean = False;

implementation

{$R *.lfm}

{ TApp }

procedure TApp.FormCreate(Sender: TObject);
var
  i         : Integer;
  Phandle   : Thandle;
  sUserPath : string;
begin
  DecimalSeparator:= '.';
  SetDefaultLang('en');
  GetLocaleFormatSettings($409, DefaultFormatSettings);
  sUserPath:= SysUtils.GetEnvironmentVariable('USERPROFILE');
  SetCurrentDir(sUserPath);
  IniPropStorage1.IniFileName:= sUserPath + '\Power_control.ini';
  FreePortsAvailable:= False;
   for i:=1 to 30 do
   begin
      { try connect to porn i }
      Phandle:= CreateFile(Pchar('COM'+intToStr(i)), Generic_Read or Generic_Write, 0, nil, open_existing,file_flag_overlapped, 0);
      if Phandle <> invalid_handle_value then { if port enable }
      begin
         App.COMselectCB.Items.Add('COM'+ IntToStr(i));
         CloseHandle(Phandle);
         FreePortsAvailable:= True;
         App.COMselectCB.ItemIndex:= 0;
      end;
   end;
   //SetOVP.Value:= 75;
   //SetOCP.Value:= 10;
   OutputSw.Enabled:= False;
   LockSw.Enabled:= False;
   AlarmSw.Enabled:= False;
   Timer1.Enabled:= False;
end;

procedure TApp.LockSwChange(Sender: TObject);
begin
  if LockSw.Checked then LockInd.Brush.Color:= clRed
  else LockInd.Brush.Color:= clWhite;
  OutputControlSet();
  SendReceiveData();
end;

procedure TApp.OutputSwChange(Sender: TObject);
begin
  StandardPacket();
  Sleep(100);
  if OutputSw.Checked then begin
    OutputInd.Brush.Color:= clRed;
    Timer1.Enabled:= True;
  end
  else begin
    OutputInd.Brush.Color:= clWhite;
    Timer1.Enabled:= False;
  end;
  if Not OutputSw.Checked then begin
    App.CVInd.Brush.Color:= clWhite;
    App.CCInd.Brush.Color:= clWhite;
  end
end;

procedure TApp.AlarmSwChange(Sender: TObject);
begin
  OutputControlSet();
  SendReceiveData();
end;

procedure TApp.ProgramBtnClick(Sender: TObject);
begin
  ProgramForm.Show;
end;

procedure TApp.SetCurrentBarChange(Sender: TObject);
begin
  SetCurrent.Value:= SetCurrentBar.Position / 10;
end;

procedure TApp.SetCurrentChange(Sender: TObject);
begin
  SetCurrentBar.Position:= Round(SetCurrent.Value * 10);
  StandardPacket();
end;

procedure TApp.SetOCPBarChange(Sender: TObject);
begin
  SetOCP.Value:= SetOCPBar.Position / 10;
end;

procedure TApp.SetOCPChange(Sender: TObject);
begin
  SetOCPBar.Position:= Round(SetOCP.Value * 10);
  StandardPacket();
end;

procedure TApp.SetOVPBarChange(Sender: TObject);
begin
  SetOVP.Value:= SetOVPBar.Position;
end;

procedure TApp.SetOVPChange(Sender: TObject);
begin
  SetOVPBar.Position:= Round(SetOVP.Value);
  StandardPacket();
end;

procedure TApp.SetVoltageBarChange(Sender: TObject);
begin
  SetVoltage.Value:= SetVoltageBar.Position;
end;

procedure TApp.SetVoltageChange(Sender: TObject);
begin
  SetVoltageBar.Position:= Round(SetVoltage.Value);
  StandardPacket();
end;

procedure TApp.Timer1Timer(Sender: TObject);
begin
  SendRequest();
  if ((BackData.Status and %00111000) > 0) And TurnOfOnOver.Checked then OutputSw.Checked:= False;
  SetIndicators();
end;

procedure TApp.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TApp.ConnectBtnClick(Sender: TObject);
begin
  if FreePortsAvailable then begin
    if ser <> nil then ser.Destroy;
    ser := TBlockSerial.Create;
    Sleep(25); //250
    ser.Connect(App.COMselectCB.Text);
    Sleep(25);  //250
    ser.Config(9600, 8, 'N', SB1, False, False);
    ser.RTS := false; // comment this if needed
    ser.DTR := false; // comment this if needed
    ConnectionStatusLbl.Caption:= 'Connected';
    ConnectionStatus:= True;
    OutputSw.Enabled:= True;
    LockSw.Enabled:= True;
    AlarmSw.Enabled:= True;
    OutputSw.Checked:= False;
    StandardPacket();
    App.CCInd.Brush.Color:= clWhite;
    App.CVInd.Brush.Color:= clWhite;
  end;
end;

end.

