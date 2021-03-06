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
{$MODE OBJFPC}
unit uzccommand_ondrawinged;
{$INCLUDE def.inc}

interface
uses
  uzccommandsabstract,
  uzccommandsmanager,
  uzccommandsimpl,
  uzedrawingabstract,uzedrawingdef,

  uzgldrawcontext,
  UGDBSelectedObjArray,

  uzeentwithlocalcs,uzeentity,uzeentgenericsubentry,
  uzbtypesbase,uzbtypes,
  uzcdrawings,
  uzglviewareadata,
  uzbgeomtypes,uzegeometry,
  uzeconsts,
  LazLogger;
type
  OnDrawingEd_com =object(CommandRTEdObject)
    t3dp: gdbvertex;
    constructor init(cn:GDBString;SA,DA:TCStartAttr);
    procedure CommandStart(Operands:TCommandOperands); virtual;
    procedure CommandCancel; virtual;
    function BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger; virtual;
    function AfterClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger; virtual;
  end;
var
   OnDrawingEd:OnDrawingEd_com;
   fixentities:boolean;
implementation
constructor OnDrawingEd_com.init(cn:GDBString;SA,DA:TCStartAttr);
begin
  inherited init(cn,sa,da);
  dyn:=false;
end;
procedure OnDrawingEd_com.CommandStart(Operands:TCommandOperands);
//var i: GDBInteger;
//  lastremove: GDBInteger;
//  findselected:GDBBoolean;
//  tv: pGDBObjEntity;
begin
  inherited commandstart('');
  drawings.GetCurrentDWG^.wa.SetMouseMode((MGet3DPoint) or (MMoveCamera) or (MRotateCamera));
  if drawings.GetCurrentDWG^.SelObjArray.SelectedCount=0 then CommandEnd;
  fixentities:=false;
end;
procedure OnDrawingEd_com.CommandCancel;
begin
    drawings.GetCurrentDWG^.wa.param.startgluepoint:=nil;
    fixentities:=false;
end;
function OnDrawingEd_com.BeforeClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger;
begin
  if (button and MZW_LBUTTON)<>0 then
                    t3dp := wc;
  result:=0;
end;

procedure modifyobj(dist,wc:gdbvertex;save:GDBBoolean;pconobj:pgdbobjEntity;var drawing:TDrawingDef;psa:PGDBSelectedObjArray);
var i: GDBInteger;
//  d: GDBDouble;
//  td:tcontrolpointdist;
  tdesc:pselectedobjdesc;
  dc:TDrawContext;

begin
  if psa^.count > 0 then
  begin
    tdesc:=psa^.GetParrayAsPointer;
    for i := 0 to psa^.count - 1 do
    begin
      if tdesc^.pcontrolpoint<>nil then
        if tdesc^.pcontrolpoint^.SelectedCount<>0 then
        begin
           {tdesc^.objaddr^}PTAbstractDrawing(@drawing)^{gdb.GetCurrentDWG}.rtmodify(tdesc^.objaddr,tdesc,dist,wc,save);
        end;
      inc(tdesc);
    end;
  end;
  if save then
              begin
                   dc:=drawing.CreateDrawingRC;
                   PGDBObjGenericSubEntry(drawing.GetCurrentRootSimple)^.FormatAfterEdit(drawing,dc);
              end;

end;

function OnDrawingEd_com.AfterClick(wc: GDBvertex; mc: GDBvertex2DI; var button: GDBByte;osp:pos_record): GDBInteger;
var //oldi, newi, i: GDBInteger;
  dist: gdbvertex;
  pobj: GDBPointer;
  xdir,ydir,tv:GDBVertex;
  rotmatr,dispmatr,dispmatr2:DMatrix4D;
  DC:TDrawContext;
begin
  if fixentities then
  drawings.GetCurrentDWG^.SelObjArray.freeclones;
  drawings.GetCurrentDWG^.wa.CalcOptimalMatrix;
  fixentities:=false;
  if drawings.GetCurrentDWG^.wa.param.startgluepoint<>nil then
  if drawings.GetCurrentDWG^.wa.param.startgluepoint^.pobject<>nil then
  if osp<>nil then
  if osp^.PGDBObject<>nil then
  //if pgdbobjentity(osp^.PGDBObject).GetObjType=GDBlwPolylineID then
    fixentities:=true;
  dist.x := wc.x - t3dp.x;
  dist.y := wc.y - t3dp.y;
  dist.z := wc.z - t3dp.z;
  if osp<> nil then pobj:=osp^.PGDBObject
               else pobj:=nil;
  if (button and MZW_LBUTTON)<>0 then
  begin
    begin
      dc:=drawings.GetCurrentDWG^.CreateDrawingRC;
      drawings.GetCurrentDWG^{.UndoStack}.PushStartMarker('On drawing edit');
      modifyobj(dist,wc,true,pobj,drawings.GetCurrentDWG^,@drawings.GetCurrentDWG^.SelObjArray);
      drawings.GetCurrentDWG^{.UndoStack}.PushEndMarker;
      drawings.GetCurrentDWG^.SelObjArray.resprojparam(drawings.GetCurrentDWG^.pcamera^.POSCOUNT,drawings.GetCurrentDWG^.pcamera^,@drawings.GetCurrentDWG^.myGluProject2,dc);


      if fixentities then
      begin

           //xdir:=GetDirInPoint(pgdbobjlwPolyline(osp^.PGDBObject).Vertex3D_in_WCS_Array,wc,pgdbobjlwPolyline(osp^.PGDBObject).closed);
           xdir:=pgdbobjentity(osp^.PGDBObject)^.GetTangentInPoint(wc);// GetDirInPoint(pgdbobjlwPolyline(osp^.PGDBObject).Vertex3D_in_WCS_Array,wc,pgdbobjlwPolyline(osp^.PGDBObject).closed);
           if not uzegeometry.IsVectorNul(xdir) then
           begin
           if pgdbobjentity(osp^.PGDBObject)^.IsHaveLCS then
                                                           ydir:=normalizevertex(uzegeometry.vectordot(PGDBObjWithLocalCS(osp^.PGDBObject)^.Local.basis.OZ,xdir))
                                                       else
                                                           ydir:=normalizevertex(uzegeometry.vectordot(ZWCS,xdir));
           tv:=wc;
           //tv:=vertexadd(wc,drawings.GetCurrentDWG^.OGLwindow1.param.startgluepoint.dcoord);
           dispmatr:=uzegeometry.CreateTranslationMatrix(createvertex(-tv.x,-tv.y,-tv.z));

           rotmatr:=onematrix;
           PGDBVertex(@rotmatr[0])^:=xdir;
           PGDBVertex(@rotmatr[1])^:=ydir;
           if pgdbobjentity(osp^.PGDBObject)^.IsHaveLCS then
                                                           PGDBVertex(@rotmatr[2])^:=PGDBObjWithLocalCS(osp^.PGDBObject)^.Local.basis.OZ
                                                       else
                                                           PGDBVertex(@rotmatr[2])^:={ZWCS}normalizevertex(uzegeometry.vectordot(ydir,xdir));
           //rotmatr:=uzegeometry.MatrixMultiply(dispmatr,rotmatr);
           dispmatr2:=uzegeometry.CreateTranslationMatrix(createvertex(tv.x,tv.y,tv.z));
           //dispmatr:=uzegeometry.MatrixMultiply(rotmatr,dispmatr2);

           //drawings.GetCurrentDWG^.SelObjArray.TransformObj(dispmatr);
           drawings.GetCurrentDWG^.SelObjArray.SetRotateObj(dispmatr,dispmatr2,rotmatr,PGDBVertex(@rotmatr[0])^,PGDBVertex(@rotmatr[1])^,PGDBVertex(@rotmatr[2])^);
           end;

           fixentities:=true;
      end;


      drawings.GetCurrentDWG^.wa.SetMouseMode(savemousemode);
      commandmanager.executecommandend;
      //if pobj<>nil then halt(0);
      //redrawoglwnd;
    end;
  end
  else
  begin
    if mouseclic = 1 then
    begin
      if fixentities then
      begin
           modifyobj(dist,wc,false,pobj,drawings.GetCurrentDWG^,@drawings.GetCurrentDWG^.SelObjArray);

           //xdir:=GetDirInPoint(pgdbobjlwPolyline(osp^.PGDBObject).Vertex3D_in_WCS_Array,wc,pgdbobjlwPolyline(osp^.PGDBObject).closed);
           xdir:=pgdbobjentity(osp^.PGDBObject)^.GetTangentInPoint(wc);// GetDirInPoint(pgdbobjlwPolyline(osp^.PGDBObject).Vertex3D_in_WCS_Array,wc,pgdbobjlwPolyline(osp^.PGDBObject).closed);
           if not uzegeometry.IsVectorNul(xdir) then
           begin
           if pgdbobjentity(osp^.PGDBObject)^.IsHaveLCS then
                                                           ydir:=normalizevertex(uzegeometry.vectordot(PGDBObjWithLocalCS(osp^.PGDBObject)^.Local.basis.OZ,xdir))
                                                       else
                                                           ydir:=normalizevertex(uzegeometry.vectordot(ZWCS,xdir));

           tv:=wc;
           //tv:=vertexadd(wc,drawings.GetCurrentDWG^.OGLwindow1.param.startgluepoint.dcoord);
           dispmatr:=uzegeometry.CreateTranslationMatrix(createvertex(-tv.x,-tv.y,-tv.z));

           rotmatr:=onematrix;
           PGDBVertex(@rotmatr[0])^:=xdir;
           PGDBVertex(@rotmatr[1])^:=ydir;
           if pgdbobjentity(osp^.PGDBObject)^.IsHaveLCS then
                                                           PGDBVertex(@rotmatr[2])^:=PGDBObjWithLocalCS(osp^.PGDBObject)^.Local.basis.OZ
                                                       else
                                                           PGDBVertex(@rotmatr[2])^:={ZWCS}normalizevertex(uzegeometry.vectordot(ydir,xdir));;
           {xdir:=normalizevertex(xdir);
           ydir:=uzegeometry.vectordot(pgdbobjlwPolyline(osp^.PGDBObject).Local.OZ,xdir);


           dispmatr:=uzegeometry.CreateTranslationMatrix(createvertex(-wc.x,-wc.y,-wc.z));

           rotmatr:=onematrix;
           PGDBVertex(@rotmatr[0])^:=xdir;
           PGDBVertex(@rotmatr[1])^:=ydir;
           PGDBVertex(@rotmatr[2])^:=pgdbobjlwPolyline(osp^.PGDBObject).Local.OZ;}

           //rotmatr:=uzegeometry.MatrixMultiply(dispmatr,rotmatr);
           dispmatr2:=uzegeometry.CreateTranslationMatrix(createvertex(tv.x,tv.y,tv.z));
           //dispmatr:=uzegeometry.MatrixMultiply(rotmatr,dispmatr2);


           //drawings.GetCurrentDWG^.SelObjArray.Transform(dispmatr);
           drawings.GetCurrentDWG^.SelObjArray.SetRotate(dispmatr,dispmatr2,rotmatr,PGDBVertex(@rotmatr[0])^,PGDBVertex(@rotmatr[1])^,PGDBVertex(@rotmatr[2])^);

           fixentities:=true;
           end;
      end
      else
      modifyobj(dist,wc,false,pobj,drawings.GetCurrentDWG^,@drawings.GetCurrentDWG^.SelObjArray);
    end
  end;
  result:=cmd_ok;
end;
procedure startup;
begin
  OnDrawingEd.init('OnDrawingEd',0,0);
  OnDrawingEd.CEndActionAttr:=0;
end;
procedure Finalize;
begin
end;
initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
  startup;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
  finalize;
end.
