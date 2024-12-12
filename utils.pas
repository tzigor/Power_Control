unit Utils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, UserTypes, Dialogs, Port, StrUtils, Graphics, TASeries,
  TAChartUtils;

procedure OutputControlSet();

function DataToStr(Order           : Byte;
                   SetVoltage      : Word;
                   SetCurrent      : Word;
                   SetOVP          : Word;
                   SetOCP          : Word;
                   ReadBackVoltage : Word;
                   ReadBackCurrent : Word;
                   OutputControl   : Byte;
                   WorkingStatus   : Byte): String;

function ParseBackData(Data : String): TBackData;
procedure SendReceiveData();
procedure SendRequest();
function SendRequestThr(parameter: pointer): ptrint;
procedure SetIndicators();
procedure StandardPacket();
function GetSticker(x, y: Double): String;
function GetParamValue(ParamNum: Integer; TextLine: String): String;

implementation
uses Main;

function FillWord(H, L: Byte): Word;
var lW: Word;
    lWBytes: array[1..2] of Byte absolute lW;
begin
   lW:= 0;
   lWBytes[1]:= L;
   lWBytes[2]:= H;
   Result:= lW;
end;

procedure OutputControlSet();
begin
   OutputControl:= %01000000;
   if App.OutputSw.Checked then OutputControl:= OutputControl or %10000000
   else OutputControl:= OutputControl and %01111111;
   if App.LockSw.Checked then OutputControl:= OutputControl or %00000001
   else OutputControl:= OutputControl and %11111110;
   if App.AlarmSw.Checked then OutputControl:= OutputControl or %00000010
   else OutputControl:= OutputControl and %11111101;
end;

function DataToStr(Order           : Byte;
                   SetVoltage      : Word;
                   SetCurrent      : Word;
                   SetOVP          : Word;
                   SetOCP          : Word;
                   ReadBackVoltage : Word;
                   ReadBackCurrent : Word;
                   OutputControl   : Byte;
                   WorkingStatus   : Byte): String;
var ControlSum: Word;
begin
   ControlSum:= $AA + Order +
            hi(SetVoltage) + lo(SetVoltage) +
            hi(SetCurrent) + lo(SetCurrent) +
            hi(SetOVP) + lo(SetOVP) +
            hi(SetOCP) + lo(SetOCP) +
            hi(ReadBackVoltage) + lo(ReadBackVoltage) +
            hi(ReadBackCurrent) + lo(ReadBackCurrent) +
            OutputControl + WorkingStatus;

   Result:= #$AA + chr(Order) +
            chr(hi(SetVoltage)) + chr(lo(SetVoltage)) +
            chr(hi(SetCurrent)) + chr(lo(SetCurrent)) +
            chr(hi(SetOVP)) + chr(lo(SetOVP)) +
            chr(hi(SetOCP)) + chr(lo(SetOCP)) +
            chr(hi(ReadBackVoltage)) + chr(lo(ReadBackVoltage)) +
            chr(hi(ReadBackCurrent)) + chr(lo(ReadBackCurrent)) +
            chr(OutputControl) + chr(WorkingStatus) +
            chr(hi(ControlSum)) + chr(lo(ControlSum));
end;

function ParseBackData(Data : String): TBackData;
var res: TBackData;
begin
  if Data <> '' then begin
    res.Voltage:= FillWord(Ord(Data[11]), Ord(Data[12]));
    res.Current:= FillWord(Ord(Data[13]), Ord(Data[14]));
    res.Status:= Ord(Data[16]);
  end
  else begin
    res.Voltage:= 0;
    res.Current:= 0;
    res.Status:= 0;
  end;
  Result:= res;
end;

procedure SendReceiveData();
var StrToSend, receivedData : String;
begin
  if ConnectionStatus = True then begin
     StrToSend:= DataToStr(1,
                           Round(App.SetVoltage.Value * 100),  // 0.01 V
                           Round(App.SetCurrent.Value * 1000),  // mA
                           Round(App.SetOVP.Value * 100),
                           Round(App.SetOCP.Value * 1000),
                           0,
                           0,
                           OutputControl,
                           0);
     receivedData:= GetResponse(StrToSend);
     if receivedData <> 'Time out' then begin
        BackData:= ParseBackData(receivedData);
        SetIndicators();
     end;
  end;
end;

procedure SendRequest();
var StrToSend, receivedData : String;
begin
  if ConnectionStatus = True then begin
     StrToSend:= DataToStr(2,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0);
     receivedData:= GetResponse(StrToSend);
     if receivedData <> 'Time out' then begin
        BackData:= ParseBackData(receivedData);
        SetIndicators();
        resError:= False;
     end
     else resError:= True;
  end;
end;

function SendRequestThr(parameter: pointer): ptrint;
var StrToSend, Data : String;
    res: TBackData;
begin
     StrToSend:= DataToStr(2,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0,
                           0);
     Data:= GetResponse(StrToSend);
     if Data <> 'Time out' then begin
         if Data <> '' then begin
            res.Voltage:= FillWord(Ord(Data[11]), Ord(Data[12]));
            res.Current:= FillWord(Ord(Data[13]), Ord(Data[14]));
            res.Status:= Ord(Data[16]);
         end
         else begin
            res.Voltage:= 0;
            res.Current:= 0;
            res.Status:= 0;
            resError:= True;
            Exit;
         end;
         BackData:= res;

         SetIndicators();
         resError:= False;
     end
     else resError:= True;
end;

procedure SetIndicators();
begin
  App.Voltage.Caption:= FloatToStrf(BackData.Voltage / 100, ffFixed, 10, 2);
  App.Current.Caption:= FloatToStrf(BackData.Current / 1000, ffFixed, 10, 2);
  App.PowerStatus.Caption:= Dec2Numb(BackData.Status, 1, 2);

  if (BackData.Status and %10000000) > 0 then App.CVInd.Brush.Color:= clRed
  else App.CVInd.Brush.Color:= clWhite;

  if (BackData.Status and %01000000) > 0 then App.CCInd.Brush.Color:= clRed
  else App.CCInd.Brush.Color:= clWhite;

  if (BackData.Status and %00111000) > 0 then App.AlarmInd.Brush.Color:= clRed
  else App.AlarmInd.Brush.Color:= clWhite;
end;

procedure StandardPacket();
begin
  OutputControlSet();
  SendReceiveData();
  SetIndicators();
end;

function GetSticker(x, y: Double): String;
var AfterDot: Byte;
begin
  GetSticker:= FloatToStrF(y, ffFixed, 10, 2) + #13#10 + DateTimeToStr(x);
end;

function GetParamValue(ParamNum: Integer; TextLine: String): String;
var LineLength, i, Counter, ParamStart: Integer;
    SubStr: String;
begin
  if ParamNum > 0 then begin
      LineLength:= Length(TextLine);
      Counter:= 1;
      SubStr:= '';
      ParamStart:= 0;
      for i:= 1 to LineLength do begin
         if ParamNum = Counter then begin
            ParamStart:= i;
            break;
         end;
         if (TextLine[i] = ';') Or (TextLine[i] = ',') then Inc(Counter);
      end;
      if ParamStart > 0 then begin
        repeat
          SubStr:= SubStr + TextLine[ParamStart];
          Inc(ParamStart);
        until ( TextLine[ParamStart] = ';' ) Or ( TextLine[ParamStart] = ',' ) Or ( ParamStart > LineLength );
        Result:= Trim(SubStr);
      end;
  end
  else Result:= '';
end;

end.

