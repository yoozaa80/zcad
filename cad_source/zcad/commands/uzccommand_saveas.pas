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

unit uzccommand_saveas;
{$INCLUDE def.inc}

interface
uses
  LazUTF8,LCLProc,
  uzcdialogsfiles,
  sysutils,
  uzbtypes,uzbpaths,

  uzeffmanager,
  uzccommand_newdwg,
  uzccommandsimpl,uzccommandsabstract,
  uzcsysvars,
  uzcstrconsts,
  uzcdrawings,
  uzcinterface,
  uzeffdxf;

function SaveAs_com(operands:TCommandOperands):TCommandResult;
function SaveDXFDPAS(s:ansistring):Integer;

implementation

function SaveDXFDPAS(s:ansistring):Integer;
begin
     result:=dwgSaveDXFDPAS(s, drawings.GetCurrentDWG);
     if assigned(ProcessFilehistoryProc) then
                                             ProcessFilehistoryProc(s);
end;

function SaveAs_com(operands:TCommandOperands):TCommandResult;
var
   s:AnsiString;
   fileext:AnsiString;
begin
  ZCMsgCallBackInterface.Do_BeforeShowModal(nil);
  s:=drawings.GetCurrentDWG.GetFileName;
  if SaveFileDialog(s,'dxf',ProjectFileFilter,'',rsSaveFile) then begin
    fileext:=uppercase(ExtractFileEXT(s));
    if fileext='.ZCP' then
      saveZCP(s, drawings.GetCurrentDWG^)
    else if fileext='.DXF' then begin
      SaveDXFDPAS(s);
      drawings.GetCurrentDWG.SetFileName(s);
      drawings.GetCurrentDWG.ChangeStampt(false);
      ZCMsgCallBackInterface.Do_GUIaction(nil,ZMsgID_GUIActionRedraw);
    end else begin
      ZCMsgCallBackInterface.TextMessage(Format(rsunknownFileExt, [fileext]),TMWOShowError);
    end;
  end;
  result:=cmd_ok;
  ZCMsgCallBackInterface.Do_AfterShowModal(nil);
end;

procedure startup;
begin
  CreateCommandFastObjectPlugin(@SaveAs_com,'SaveAs',CADWG,0);
end;
procedure finalize;
begin
end;
initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
  startup;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
  finalize;
end.
