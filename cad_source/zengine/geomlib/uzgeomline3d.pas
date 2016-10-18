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

unit uzgeomline3d;
{$INCLUDE def.inc}
interface
uses
     sysutils,uzbtypes,uzbmemman,uzegeometry,
     uzgeomentity,uzgeomentity3d,uzbgeomtypes;
type
{Export+}
TGeomLine3D={$IFNDEF DELPHI}packed{$ENDIF} object(TGeomEntity3D)
                                           LineData:GDBLineProp;
                                           constructor init(const p1,p2:GDBvertex);
                                           function GetBB:TBoundingBox;virtual;
                                           end;
{Export-}
implementation
constructor TGeomLine3D.init(const p1,p2:GDBvertex);
begin
  LineData.lBegin:=p1;
  LineData.lEnd:=p2;
end;
function TGeomLine3D.GetBB:TBoundingBox;
begin
  result:=CreateBBFrom2Point(LineData.lBegin,LineData.lEnd);
end;
begin
end.

