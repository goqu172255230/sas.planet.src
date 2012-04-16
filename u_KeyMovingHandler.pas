{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_KeyMovingHandler;

interface

uses
  Windows,
  Classes,
  Forms,
  GR32_Image,
  t_GeoTypes,
  i_ViewPortState,
  i_KeyMovingConfig,
  i_MessageHandler;

type
  TKeyMovingHandler = class(TInterfacedObject, IMessageHandler)
  private
    FConfig: IKeyMovingConfig;
    FMap: TImage32;
    FViewPortState: IViewPortState;
    FKeyMovingLastTick: Int64;
    FTimeFromFirstToLast: Double;
    FWasSecondKeyPress: Boolean;
    FMapMoveAnimtion: Boolean;
    FMoveVector: TPoint;
  protected
    procedure MapMoveAnimate;
    procedure DoMessageEvent(var Msg: TMsg; var Handled: Boolean);
  public
    constructor Create(
      AMap: TImage32;
      const AViewPortState: IViewPortState;
      const AConfig: IKeyMovingConfig
    );
  end;


implementation

uses
  Messages;

{ TKeyMovingHandler }

constructor TKeyMovingHandler.Create(
  AMap: TImage32;
  const AViewPortState: IViewPortState;
  const AConfig: IKeyMovingConfig
);
begin
  FConfig := AConfig;
  FMap := AMap;
  FViewPortState := AViewPortState;
end;

procedure TKeyMovingHandler.DoMessageEvent(var Msg: TMsg; var Handled: Boolean);
var
  VMoveByDelta: Boolean;
begin
  case Msg.message of
    WM_KEYFIRST: begin
      VMoveByDelta := False;
      case Msg.wParam of
        VK_RIGHT,
        VK_LEFT,
        VK_DOWN,
        VK_UP: VMoveByDelta := True;
      end;
      if VMoveByDelta then begin
        case Msg.wParam of
          VK_RIGHT: FMoveVector.x := 1;
          VK_LEFT: FMoveVector.x := -1;
          VK_DOWN: FMoveVector.y := 1;
          VK_UP: FMoveVector.y := -1;
        end;
        MapMoveAnimate;
      end;
    end;
    WM_KEYUP: begin
        case Msg.wParam of
          VK_RIGHT: FMoveVector.x := 0;
          VK_LEFT: FMoveVector.x := 0;
          VK_DOWN: FMoveVector.y := 0;
          VK_UP: FMoveVector.y := 0;
        end;
    end;
  end;

end;

procedure TKeyMovingHandler.MapMoveAnimate;
var
  VPointDelta: TDoublePoint;
  VCurrTick, VFr: Int64;
  VTimeFromLast: Double;
  VDrawTimeFromLast: Double;
  VStep: Double;
  VStartSpeed: Double;
  VAcelerateTime: Double;
  VMaxSpeed: Double;
  VAcelerate: Double;
  VAllKeyUp: Boolean;
  VZoom: byte;
begin
  if not(FMapMoveAnimtion) then begin
    FMapMoveAnimtion:=True;
    try
      QueryPerformanceCounter(VCurrTick);
      QueryPerformanceFrequency(VFr);
      FWasSecondKeyPress := True;
      FKeyMovingLastTick := VCurrTick;
      FTimeFromFirstToLast := 0;
      VTimeFromLast := 0;
      VZoom:=FViewPortState.GetCurrentZoom;
      FConfig.LockRead;
      try
        VStartSpeed := FConfig.MinPixelPerSecond;
        VMaxSpeed := FConfig.MaxPixelPerSecond;
        VAcelerateTime := FConfig.SpeedChangeTime;
      finally
        FConfig.UnlockRead;
      end;

      repeat
        VDrawTimeFromLast := (VCurrTick - FKeyMovingLastTick) / VFr;
        VTimeFromLast := VTimeFromLast+ 0.3*(VDrawTimeFromLast-VTimeFromLast);
        if (FTimeFromFirstToLast >= VAcelerateTime) or (VAcelerateTime < 0.01) then begin
          VStep := VMaxSpeed * VTimeFromLast;
        end else begin
          VAcelerate := (VMaxSpeed - VStartSpeed) / VAcelerateTime;
          VStep := (VStartSpeed + VAcelerate * (FTimeFromFirstToLast + VTimeFromLast/2)) * VTimeFromLast;
        end;
        FKeyMovingLastTick := VCurrTick;
        FTimeFromFirstToLast := FTimeFromFirstToLast + VTimeFromLast;

        VPointDelta.x:=FMoveVector.x*VStep;
        VPointDelta.y:=FMoveVector.y*VStep;

        FMap.BeginUpdate;
        try
          FViewPortState.ChangeMapPixelByDelta(VPointDelta);
        finally
          FMap.EndUpdate;
          FMap.Changed;
        end;

        application.ProcessMessages;
        QueryPerformanceCounter(VCurrTick);
        QueryPerformanceFrequency(VFr);

        VAllKeyUp:=(GetAsyncKeyState(VK_RIGHT) = 0)and
                   (GetAsyncKeyState(VK_LEFT) = 0)and
                   (GetAsyncKeyState(VK_DOWN) = 0)and
                   (GetAsyncKeyState(VK_UP) = 0);
        if VAllKeyUp then begin
          FMoveVector:=Point(0,0);
        end;
      until ((FMoveVector.x=0)and(FMoveVector.y=0))or(VZoom<>FViewPortState.GetCurrentZoom);
    finally
      FMapMoveAnimtion:=false;
    end;
  end;
end;

end.
