unit ULogo;

interface

uses
  Forms, jpeg, StdCtrls, ExtCtrls, Controls, Classes;

type
  TFLogo = class(TForm)
    Label1: TLabel;
    Image1: TImage;
    Timer1: TTimer;
    Label2: TLabel;
    procedure Image1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
  public
  end;

var
  FLogo: TFLogo;

implementation
{$R *.dfm}

procedure TFLogo.Image1Click(Sender: TObject);
begin
// if timer1.Enabled then
//  begin
   FLogo.Close;
   timer1.Enabled:=false;
//  end;
end;

procedure TFLogo.Timer1Timer(Sender: TObject);
begin
 timer1.Enabled:=false;
 FLogo.Close;
end;

end.
