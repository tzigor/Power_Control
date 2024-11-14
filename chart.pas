unit Chart;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  TAGraph, TASeries, TAIntervalSources, TATools, DateUtils, TAChartUtils;

type

  { TProgramForm }

  TProgramForm = class(TForm)
    AddPointBtn: TButton;
    ResetBtn: TButton;
    AddDynamicBtn: TButton;
    ChartToolset1: TChartToolset;
    ChartToolset1DataPointDragTool1: TDataPointDragTool;
    ChartToolset1ZoomMouseWheelTool1: TZoomMouseWheelTool;
    DateTimeIntervalChartSource1: TDateTimeIntervalChartSource;
    SetInitVoltBtn: TButton;
    Chart1: TChart;
    InitialVoltage: TFloatSpinEdit;
    Label10: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label9: TLabel;
    VoltageSerie: TLineSeries;
    Duration: TSpinEdit;
    EndVoltage: TFloatSpinEdit;
    Interval: TSpinEdit;
    procedure AddDynamicBtnClick(Sender: TObject);
    procedure AddPointBtnClick(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SetInitVoltBtnClick(Sender: TObject);
  private

  public

  end;

var
  ProgramForm: TProgramForm;

implementation

{$R *.lfm}

{ TProgramForm }

procedure TProgramForm.FormCreate(Sender: TObject);
begin
  VoltageSerie.LineType:= ltStepXY;
end;

procedure TProgramForm.ResetBtnClick(Sender: TObject);
begin
  VoltageSerie.Clear;
end;

procedure TProgramForm.AddDynamicBtnClick(Sender: TObject);
var LastValue   : Double;
    LastTime    : TDateTime;
    NumSteps, i : Integer;
    StepInc     : Double;
begin
  if VoltageSerie.Count = 0 then VoltageSerie.AddXY(0, InitialVoltage.Value);
  LastValue:= VoltageSerie.GetYValue(VoltageSerie.Count - 1);
  LastTime:= VoltageSerie.GetXValue(VoltageSerie.Count - 1);
  //ShowMessage(FloatToStr(LastValue));
  NumSteps:= Round(Duration.Value * 1000 / Interval.Value);
  if EndVoltage.Value >= LastValue then begin
     StepInc:= (EndVoltage.Value - LastValue) / NumSteps;
     for i:=1 to NumSteps do begin
       LastValue += StepInc;
       LastTime:= IncMilliSecond(LastTime, Interval.Value);
       VoltageSerie.AddXY(LastTime, LastValue);
     end;
  end
  else begin
     StepInc:= (LastValue - EndVoltage.Value) / NumSteps;
     for i:=1 to NumSteps do begin
       LastValue -= StepInc;
       LastTime:= IncMilliSecond(LastTime, Interval.Value);
       VoltageSerie.AddXY(LastTime, LastValue);
     end;
  end;
end;

procedure TProgramForm.AddPointBtnClick(Sender: TObject);
var LastValue   : Double;
    LastTime    : TDateTime;
begin
  if VoltageSerie.Count = 0 then VoltageSerie.AddXY(0, InitialVoltage.Value);
  LastTime:= VoltageSerie.GetXValue(VoltageSerie.Count - 1);
  LastTime:= IncMilliSecond(LastTime, Interval.Value);
  VoltageSerie.AddXY(LastTime, EndVoltage.Value);
end;

procedure TProgramForm.SetInitVoltBtnClick(Sender: TObject);
begin
  VoltageSerie.Clear;
  VoltageSerie.AddXY(0, InitialVoltage.Value);
end;

end.

