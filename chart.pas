unit Chart;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ExtCtrls, Menus, TAGraph, TASeries, TAIntervalSources, TATools, DateUtils,
  TAChartUtils, TATransformations, TAChartLiveView, Types, Utils, Port;

type

  { TProgramForm }

  TProgramForm = class(TForm)
    AddPointBtn: TButton;
    ChartLiveView1: TChartLiveView;
    ChartToolset1DataPointClickTool2: TDataPointClickTool;
    Interval: TFloatSpinEdit;
    DeletePoint: TMenuItem;
    InsertBefore: TMenuItem;
    InserAfter: TMenuItem;
    PopupMenu1: TPopupMenu;
    StartProgramBtn: TButton;
    Chart2: TChart;
    ChartAxisTransformations1: TChartAxisTransformations;
    ChartAxisTransformations1AutoScaleAxisTransform1: TAutoScaleAxisTransform;
    ChartAxisTransformations2: TChartAxisTransformations;
    ChartAxisTransformations2AutoScaleAxisTransform1: TAutoScaleAxisTransform;
    ChartToolset1DataPointClickTool1: TDataPointClickTool;
    ChartToolset1DataPointHintTool1: TDataPointHintTool;
    CurrentSerie: TLineSeries;
    MonCurrentSerie: TLineSeries;
    IntervalMin: TSpinEdit;
    Label5: TLabel;
    TestLabel: TLabel;
    SetCurrent: TFloatSpinEdit;
    Label11: TLabel;
    Label12: TLabel;
    ResetBtn: TButton;
    AddDynamicBtn: TButton;
    ChartToolset1: TChartToolset;
    ChartToolset1DataPointDragTool1: TDataPointDragTool;
    ChartToolset1ZoomMouseWheelTool1: TZoomMouseWheelTool;
    DateTimeIntervalChartSource1: TDateTimeIntervalChartSource;
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
    MonVoltageSerie: TLineSeries;
    procedure AddDynamicBtnClick(Sender: TObject);
    procedure AddPointBtnClick(Sender: TObject);
    procedure ChartToolset1DataPointClickTool1PointClick(ATool: TChartTool;
      APoint: TPoint);
    procedure ChartToolset1DataPointClickTool2PointClick(ATool: TChartTool;
      APoint: TPoint);
    procedure ChartToolset1DataPointDragTool1AfterMouseUp(ATool: TChartTool;
      APoint: TPoint);
    procedure ChartToolset1DataPointDragTool1Drag(ASender: TDataPointDragTool;
      var AGraphPoint: TDoublePoint);
    procedure ChartToolset1DataPointHintTool1AfterMouseMove(ATool: TChartTool;
      APoint: TPoint);
    procedure ChartToolset1DataPointHintTool1Hint(ATool: TDataPointHintTool;
      const APoint: TPoint; var AHint: String);
    procedure FormActivate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure DeletePointClick(Sender: TObject);
    procedure InsertBeforeClick(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure StartProgramBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  ProgramForm: TProgramForm;

  { Variables are initialized if OnHint event occur  }
  isOnHint           : Boolean = False;
  OnHintSerie        : TLineSeries;
  OnHintSerieIndex   : Integer;
  OnHintPointIndex   : LongWord;
  OnHintXPoint       : Double;
  OnHintYPoint       : Double;
  MousePosition      : TPoint;

implementation

uses Main;

{$R *.lfm}

{ TProgramForm }

procedure TProgramForm.FormCreate(Sender: TObject);
begin
  VoltageSerie.LineType:= ltStepXY;
  CurrentSerie.LineType:= ltStepXY;
end;

procedure TProgramForm.StartProgramBtnClick(Sender: TObject);
var i, j, n        : Integer;
    StrToSend      : String;
    TimeInterval   : Int64;
    StartCycle     : TDateTime;
    DiffMillis     : Int64;
    InitDiffMillis : Int64;
begin
  if VoltageSerie.Count > 0 then begin
     App.OutputSw.Checked:= True;
     App.Timer1.Enabled:= False;
     Sleep(300);
     StrToSend:= DataToStr(1,
                           Round(VoltageSerie.GetYValue(0) * 100),
                           Round(CurrentSerie.GetYValue(0) * 1000),
                           Round(App.SetOVP.Value * 100),
                           Round(App.SetOCP.Value * 1000),
                           0,
                           0,
                           OutputControl,
                           0);
     GetResponse(StrToSend);
     Sleep(3000);
     MonVoltageSerie.Clear;
     MonCurrentSerie.Clear;
     for i:= 0 to VoltageSerie.Count - 1 do begin
         StartCycle:= Now();
         if i < VoltageSerie.Count - 1 then TimeInterval:= MilliSecondsBetween(VoltageSerie.GetXValue(i + 1), VoltageSerie.GetXValue(i))
         else TimeInterval:= 0;
         n:= Round(TimeInterval / 500);
         StrToSend:= DataToStr(1,
                               Round(VoltageSerie.GetYValue(i) * 100),
                               Round(CurrentSerie.GetYValue(i) * 1000),
                               Round(App.SetOVP.Value * 100),
                               Round(App.SetOCP.Value * 1000),
                               0,
                               0,
                               OutputControl,
                               0);
         GetResponse(StrToSend);
         InitDiffMillis:= MilliSecondsBetween(Now(), StartCycle);
         for j:=1 to n do begin
            StartCycle:= Now();
            if SendRequest() then begin
               MonVoltageSerie.AddXY(Now(), BackData.Voltage / 100);
               MonCurrentSerie.AddXY(Now(), BackData.Current / 1000);
            end;
            DiffMillis:= MilliSecondsBetween(Now(), StartCycle);
            Sleep(500 - InitDiffMillis - DiffMillis);
         end;

       end;
     App.Timer1.Enabled:= True;
  end;
  ShowMessage('Cycle completed');
end;

procedure TProgramForm.Timer1Timer(Sender: TObject);
begin
  SendRequest();
  MonVoltageSerie.AddXY(Now(), BackData.Voltage / 100);
  MonCurrentSerie.AddXY(Now(), BackData.Current / 1000);
end;

procedure TProgramForm.ResetBtnClick(Sender: TObject);
begin
  VoltageSerie.Clear;
  CurrentSerie.Clear;
end;

procedure TProgramForm.AddDynamicBtnClick(Sender: TObject);
var LastValue   : Double;
    LastTime    : TDateTime;
    NumSteps, i : Integer;
    StepInc     : Double;
begin
  if VoltageSerie.Count = 0 then begin
     VoltageSerie.AddXY(0, InitialVoltage.Value);
     CurrentSerie.AddXY(0, SetCurrent.Value);
  end;
  LastValue:= VoltageSerie.GetYValue(VoltageSerie.Count - 1);
  LastTime:= VoltageSerie.GetXValue(VoltageSerie.Count - 1);
  //ShowMessage(FloatToStr(LastValue));
  NumSteps:= Round(Duration.Value / Interval.Value);
  if EndVoltage.Value >= LastValue then begin
     StepInc:= (EndVoltage.Value - LastValue) / NumSteps;
     for i:=1 to NumSteps do begin
       LastValue += StepInc;
       LastTime:= IncMinute(LastTime, IntervalMin.Value);
       LastTime:= IncMilliSecond(LastTime, Round(Interval.Value * 1000));
       VoltageSerie.AddXY(LastTime, LastValue);
       CurrentSerie.AddXY(LastTime, SetCurrent.Value);
     end;
  end
  else begin
     StepInc:= (LastValue - EndVoltage.Value) / NumSteps;
     for i:=1 to NumSteps do begin
       LastValue -= StepInc;
       LastTime:= IncMilliSecond(LastTime, Round(Interval.Value * 1000));
       VoltageSerie.AddXY(LastTime, LastValue);
       CurrentSerie.AddXY(LastTime, SetCurrent.Value);
     end;
  end;
  Chart1.ZoomFull();
end;

procedure TProgramForm.AddPointBtnClick(Sender: TObject);
var LastTime    : TDateTime;
begin
  if VoltageSerie.Count = 0 then begin
     VoltageSerie.AddXY(0, InitialVoltage.Value);
     CurrentSerie.AddXY(0, SetCurrent.Value);
  end;
  LastTime:= VoltageSerie.GetXValue(VoltageSerie.Count - 1);
  LastTime:= IncMinute(LastTime, IntervalMin.Value);
  LastTime:= IncMilliSecond(LastTime, Round(Interval.Value * 1000));
  VoltageSerie.AddXY(LastTime, EndVoltage.Value);
  CurrentSerie.AddXY(LastTime, SetCurrent.Value);
end;

procedure TProgramForm.ChartToolset1DataPointClickTool1PointClick(
  ATool: TChartTool; APoint: TPoint);
begin
  with ATool as TDatapointClickTool do begin
    //ShowMessage(IntToStr(PointIndex));
    VoltageSerie.Delete(PointIndex);
    CurrentSerie.Delete(PointIndex);
  end;
end;

procedure TProgramForm.ChartToolset1DataPointClickTool2PointClick(
  ATool: TChartTool; APoint: TPoint);
begin
  PopupMenu1.PopUp;
end;

var DragYValue     : Double;
    DragPointIndex : LongInt;
    DragSerieName  : String;
    DragSerie      : TLineSeries;

procedure TProgramForm.ChartToolset1DataPointDragTool1Drag(
  ASender: TDataPointDragTool; var AGraphPoint: TDoublePoint);
var y:Double;
begin
   DragSerie:= TLineSeries(ASender.Series);
   DragSerieName:= TLineSeries(ASender.Series).Name;
   DragYValue:= TLineSeries(ASender.Series).GetYValue(ASender.PointIndex);
   DragPointIndex:= ASender.PointIndex;
end;

procedure TProgramForm.ChartToolset1DataPointHintTool1AfterMouseMove(
  ATool: TChartTool; APoint: TPoint);
var wM : TPoint;
begin
  wM:= Mouse.CursorPos;
  if isOnHint then
     if (Abs(Abs(MousePosition.X) - Abs(wM.X)) > 5) Or
        (Abs(Abs(MousePosition.Y) - Abs(wM.Y)) > 5) then begin
        isOnHint:= False;
        OnHintSerie:= Nil;
     end;
end;

procedure TProgramForm.ChartToolset1DataPointDragTool1AfterMouseUp(
  ATool: TChartTool; APoint: TPoint);
begin
   if DragSerieName = 'VoltageSerie' then begin
      if DragYValue >= 75 then DragSerie.SetYValue(DragPointIndex, 75);
   end
   else
      if DragYValue >= 10 then DragSerie.SetYValue(DragPointIndex, 10);
end;

procedure TProgramForm.ChartToolset1DataPointHintTool1Hint(
  ATool: TDataPointHintTool; const APoint: TPoint; var AHint: String);
var y : Double;
    x : TDateTime;
begin
   isOnHint:= True;
   MousePosition:= Mouse.CursorPos;
   OnHintSerie:= TLineSeries(ATool.Series);
   OnHintPointIndex:= ATool.PointIndex;
   OnHintXPoint:= TLineSeries(ATool.Series).GetXValue(ATool.PointIndex);
   OnHintYPoint:= TLineSeries(ATool.Series).GetYValue(ATool.PointIndex);
   x:= TLineSeries(ATool.Series).GetXValue(ATool.PointIndex);
   y:= TLineSeries(ATool.Series).GetYValue(ATool.PointIndex);
   AHint:= GetSticker(x, y);
end;

procedure TProgramForm.FormActivate(Sender: TObject);
begin
  if ConnectionStatus = True then StartProgramBtn.Enabled:= True
  else StartProgramBtn.Enabled:= False;
end;

procedure TProgramForm.FormResize(Sender: TObject);
begin
  Chart1.Height:= Round((ProgramForm.Height - 100) / 2);
  Chart2.Height:= Round((ProgramForm.Height - 100) / 2);
end;

procedure TProgramForm.DeletePointClick(Sender: TObject);
begin
  if isOnHint then begin
    VoltageSerie.Delete(OnHintPointIndex);
    CurrentSerie.Delete(OnHintPointIndex);
  end;
end;

procedure TProgramForm.InsertBeforeClick(Sender: TObject);
var prevPoint : Double;
begin
  if isOnHint And (OnHintPointIndex  > 0) then begin
    prevPoint:= VoltageSerie.GetXValue(OnHintPointIndex - 1);
    VoltageSerie.AddXY((OnHintXPoint - prevPoint) / 2, OnHintYPoint);
  end;
end;

//isOnHint           : Boolean = False;
//OnHintSerie        : TLineSeries;
//OnHintSerieIndex   : Integer;
//OnHintPointIndex   : LongWord;
//OnHintXPoint       : Double;
//OnHintYPoint       : Double;

end.

