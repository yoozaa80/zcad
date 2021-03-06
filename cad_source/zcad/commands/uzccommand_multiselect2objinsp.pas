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
unit uzccommand_multiselect2objinsp;

{$INCLUDE def.inc}

interface
uses
  LazLogger,
  uzccommandsabstract,uzccommandsimpl,
  uzcoimultiobjects,
  uzcdrawings,
  uzcinterface,
  Varman;

implementation

var
  ms2objinsp:PCommandObjectDef;

function MultiSelect2ObjIbsp_com(operands:TCommandOperands):TCommandResult;
{$IFDEF DEBUGBUILD}
var
   membuf:GDBOpenArrayOfByte;
{$ENDIF}
begin
  MSEditor.CreateUnit(drawings.GetUnitsFormat);
  if {MSEditor.SelCount>0}true then begin
    {$IFDEF DEBUGBUILD}
    membuf.init({$IFDEF DEBUGBUILD}'{6F6386AC-95B5-4B6D-AEC3-7EE5DD53F8A3}',{$ENDIF}10000);
    MSEditor.VariablesUnit.SaveToMem(membuf);
    membuf.SaveToFile(expandpath('*log\lms.pas'));
    {$ENDIF}
    ZCMsgCallBackInterface.Do_PrepareObject(drawings.GetUndoStack,drawings.GetUnitsFormat,SysUnit.TypeName2PTD('TMSEditor'),@MSEditor,drawings.GetCurrentDWG);
  end {else
    commandmanager.executecommandend};
  result:=cmd_ok;
end;

initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
  ms2objinsp:=CreateCommandFastObjectPlugin(@MultiSelect2ObjIbsp_com,'MultiSelect2ObjIbsp',CADWG,0);
  ms2objinsp.CEndActionAttr:=0;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
end.
