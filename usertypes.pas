unit UserTypes;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TBackData = record
    Voltage : Word;
    Current : Word;
    Status  : Byte;
  end;

  TMinMax = record
    Min: Double;
    Max: Double;
  end;

implementation

end.

