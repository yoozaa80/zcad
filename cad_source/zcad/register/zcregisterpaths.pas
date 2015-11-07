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

unit zcregisterpaths;
{$INCLUDE def.inc}
interface
uses zcadsysvars,paths,intftranslations,UUnitManager,TypeDescriptors;
implementation

initialization
{$IFDEF DEBUGINITSECTION}LogOut('zcregisterzscript.initialization');{$ENDIF}
//units.CreateExtenalSystemVariable(SupportPath,expandpath('*rtl/system.pas'),InterfaceTranslate,'PATH_Program_Run','GDBString',@ProgramPath);
units.CreateExtenalSystemVariable(SupportPath,expandpath('*rtl/system.pas'),InterfaceTranslate,'PATH_Support_Path','GDBString',@SupportPath);
sysvar.PATH.Program_Run:=@ProgramPath;
sysvar.PATH.Support_Path:=@SupportPath;
sysvar.PATH.Temp_files:=@TempPath;
finalization
end.
