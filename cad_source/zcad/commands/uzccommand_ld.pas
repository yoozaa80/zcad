{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>)
}
{$mode delphi}
unit uzccommand_ld;

{$INCLUDE def.inc}

interface
uses
  LazLogger,
  uzccommandsabstract,uzccommandsimpl,
  uzbtypes,uzcenitiesvariablesextender,
  uzccommandsmanager,uzeentity,
  uzcinterface;

resourcestring
  rscmSelectEntityWithMainFunction='Select entity with main function';
  rscmSelectLinkedEntity='Select linked entity';

implementation

function LinkDevices_com(operands:TCommandOperands):TCommandResult;
var
    pobj: pGDBObjEntity;
    pmainobj: pGDBObjEntity;

    pCentralVarext,pVarext:PTVariablesExtender;
begin
  pmainobj:=nil;
  repeat
    if pmainobj=nil then
      if not commandmanager.getentity(rscmSelectEntityWithMainFunction,pmainobj) then
        exit(cmd_ok);
    pCentralVarext:=pmainobj^.GetExtension(typeof(TVariablesExtender));
    if pCentralVarext=nil then begin
      pmainobj:=nil;
      ZCMsgCallBackInterface.TextMessage('Please select device with variables',TMWOSilentShowError);
    end;
  until pCentralVarext<>nil;

  repeat
    if not commandmanager.getentity(rscmSelectLinkedEntity,pobj) then
      exit(cmd_ok);
    pVarext:=pobj^.GetExtension(typeof(TVariablesExtender));
    if pVarext=nil then begin
      ZCMsgCallBackInterface.TextMessage('Please select device with variables',TMWOSilentShowError);
    end else begin
      pCentralVarext^.addDelegate({pmainobj,}pobj,pVarext);
    end;
  until false;

  result:=cmd_ok;
end;



initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
  CreateCommandFastObjectPlugin(@LinkDevices_com,'LD',   CADWG,0);
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
end.
