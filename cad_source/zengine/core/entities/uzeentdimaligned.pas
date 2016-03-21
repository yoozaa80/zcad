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
unit uzeentdimaligned;
{$INCLUDE def.inc}

interface
uses uzgldrawcontext,uzeentityfactory,uzeentdimension,uzeentpoint,uzestylesdim,
     uzestyleslayers,uzedrawingdef,UGDBOpenArrayOfPObjects,strproc,
     UGDBOpenArrayOfByte,UGDBControlPointArray,geometry,uzeentline,gdbasetypes,
     uzeentcomplex,sysutils,UGDBSelectedObjArray,uzeentity,GDBase,uzeconsts,
     uzeffdxfsupport,memman,uzeentsubordinated;
(*
Alligned dimension structure in DXF

   (11,21,31)
|----X(text)-----X (10,20,30)
|                |
|                |
|                |
X (13,23,33)     X (14,24,34)

*)
type
{EXPORT+}
PGDBObjAlignedDimension=^GDBObjAlignedDimension;
GDBObjAlignedDimension={$IFNDEF DELPHI}packed{$ENDIF} object(GDBObjDimension)
                      constructor init(own:GDBPointer;layeraddres:PGDBLayerProp;LW:GDBSmallint);
                      constructor initnul(owner:PGDBObjGenericWithSubordinated);
                      procedure DrawExtensionLine(p1,p2:GDBVertex;LineNumber:GDBInteger;var drawing:TDrawingDef;var DC:TDrawContext; part:integer);



                      procedure FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext);virtual;
                      function Clone(own:GDBPointer):PGDBObjEntity;virtual;
                      //procedure DrawGeometry;

                      procedure addcontrolpoints(tdesc:GDBPointer);virtual;



                      function GetObjTypeName:GDBString;virtual;



                      procedure CalcDNVectors;virtual;
                      procedure CalcDefaultPlaceText(dlStart,dlEnd:Gdbvertex;var drawing:TDrawingDef);virtual;
                      function P10ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P11ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P12ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P13ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      function P14ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P15ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                      //function P16ChangeTo(tv:GDBVertex):GDBVertex;virtual;
                       procedure SaveToDXF(var handle:TDWGHandle;var outhandle:{GDBInteger}GDBOpenArrayOfByte;var drawing:TDrawingDef);virtual;
                       function GetDimStr(var drawing:TDrawingDef):GDBString;virtual;
                   end;
{EXPORT-}
function CorrectPointLine(q:GDBvertex;p1,p2:GDBvertex;out d:GDBDouble):GDBVertex;
function GetTFromDirNormalizedPoint(q:GDBvertex;var p1,dirNormalized:GDBvertex):double;
implementation
uses {log,}UGDBOpenArrayOfPV;
function GDBObjAlignedDimension.GetDimStr(var drawing:TDrawingDef):GDBString;
begin
     result:=GetLinearDimStr(abs(scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD)),drawing);
end;

function CorrectPointLine(q:GDBvertex;p1,p2:GDBvertex;out d:GDBDouble):GDBVertex;
var w,l:GDBVertex;
    dist,llength:GDBDouble;
begin
     //расстояние от точки до линии
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     llength:=scalardot(l,l);
     if llength<sqreps then
                           begin
                                d:=0;
                                result:=p2;
                                exit;
                           end;
     dist:=scalardot(w,l)/{scalardot(l,l)}llength;
     p1:=Vertexmorph(p1,p2,dist);
     d:=Vertexlength(q,p1);
     if d>eps then
                  begin
                       q:=geometry.Vertexmorphabs2(p1,q,d);
                       result:=VertexAdd(p2,VertexSub(q,p1));
                  end
              else
                  result:=p2;
end;
function SetPointLine(d:GDBDouble;q:GDBvertex;p1,p2:GDBvertex):GDBVertex;
var w,l:GDBVertex;
    dist:GDBDouble;
begin
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     dist:=scalardot(w,l)/scalardot(l,l);
     p1:=Vertexmorph(p1,p2,dist);
     result:=geometry.Vertexmorphabs2(p1,q,d);
     //result:=VertexAdd(p2,VertexSub(q,p1));
end;
function GetTFromLinePoint(q:GDBvertex;var p1,p2:GDBvertex):double;
var w,l:GDBVertex;
begin
     w:=VertexSub(q,p1);
     l:=VertexSub(p2,p1);
     result:=scalardot(w,l)/scalardot(l,l);
end;
function GetTFromDirNormalizedPoint(q:GDBvertex;var p1,dirNormalized:GDBvertex):double;
var w:GDBVertex;
begin
     w:=VertexSub(q,p1);
     result:=scalardot(w,dirNormalized);
end;
procedure GDBObjAlignedDimension.SaveToDXF;
begin
  SaveToDXFObjPrefix(handle,outhandle,'DIMENSION','AcDbDimension');
  dxfvertexout(outhandle,10,DimData.P10InWCS);
  dxfvertexout(outhandle,11,DimData.P11InOCS);
  if DimData.TextMoved then
                           dxfGDBIntegerout(outhandle,70,1+128)
                       else
                           dxfGDBIntegerout(outhandle,70,1);
  dxfGDBStringout(outhandle,3,PDimStyle^.Name);
  dxfGDBStringout(outhandle,100,'AcDbAlignedDimension');
  dxfvertexout(outhandle,13,DimData.P13InWCS);
  dxfvertexout(outhandle,14,DimData.P14InWCS);
end;
procedure GDBObjAlignedDimension.CalcDefaultPlaceText(dlStart,dlEnd:Gdbvertex;var drawing:TDrawingDef);
begin
  //case PDimStyle.Text.DIMJUST;
  //end;{case}
  DimData.P11InOCS:=VertexMulOnSc({vertexadd(DimData.P13InWCS,DimData.P14InWCS)}vertexadd(dlStart,dlEnd),0.5);
  //DimData.P11InOCS:=VertexAdd(DimData.P11InOCS,vertexsub(DimData.P10InWCS,DimData.P14InWCS));
  DimData.P11InOCS:=VertexAdd(DimData.P11InOCS,getTextOffset(drawing));
end;
function GDBObjAlignedDimension.P10ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,tl:GDBDouble;
    temp:GDBVertex;
begin
     if geometry.sqrVertexlength(tv,DimData.P14InWCS)>sqreps then
     begin
           tl:=scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD);
           temp:=VertexDmorph(DimData.P13InWCS,self.vectorD,tl);
           tv:=CorrectPointLine(tv,DimData.P13InWCS,temp,t);
     end
     else
           tv:=DimData.P14InWCS;
     result:=tv;
     DimData.P10InWCS:=tv;
     self.CalcDNVectors;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   DimData.P11InOCS:=SetPointLine(t,DimData.P11InOCS,DimData.P13InWCS,temp)
                               {else
                                   CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);}
end;
function GDBObjAlignedDimension.P11ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,tl:GDBDouble;
    tvertex,temp:GDBVERTEX;
begin
     result:=tv;
     DimData.TextMoved:=true;
     if PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine then
     begin
     tl:=scalardot(vertexsub(DimData.P14InWCS,DimData.P13InWCS),vectorD);
     temp:=VertexDmorph(DimData.P13InWCS,self.vectorD,tl);

     t:=GettFromLinePoint(tv,DimData.P13InWCS,{DimData.P14InWCS}temp);
     tvertex:=geometry.Vertexmorph(DimData.P13InWCS,{DimData.P14InWCS}temp,t);
     tvertex:=vertexsub(tv,tvertex);
     DimData.P10InWCS:=VertexAdd({DimData.P14InWCS}temp,tvertex);
     end;
end;
(*
Alligned dimension structure in DXF

   (11,21,31)
|----X(text)-----X (10,20,30)
|                |
|                |
|                |
X (13,23,33)     X (14,24,34)

*)
function GDBObjAlignedDimension.P13ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,dir:GDBDouble;
    tvertex:GDBVERTEX;
begin
     result:=tv;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   begin
                                       t:=GettFromLinePoint(DimData.P11InOCS,tv,DimData.P14InWCS);
                                       tvertex:=geometry.Vertexmorph(tv,DimData.P14InWCS,t);
                                       tvertex:=vertexsub(DimData.P11InOCS,tvertex);
                                       DimData.P10InWCS:=VertexAdd(DimData.P14InWCS,tvertex);
                                   end
                               else
                                   begin
                                        t:=vertexlength(DimData.P10InWCS,DimData.P14InWCS);
                                        dir:=-1;
                                        if GetCSDirFrom0x0y2D(vertexsub(DimData.P13InWCS,DimData.P14InWCS),vertexsub(DimData.P10InWCS,DimData.P14InWCS))=TCSDRight then
                                                                      begin
                                                                           t:=-t;
                                                                           dir:=-dir;
                                                                      end;
                                        //if vertexlength(tv,DimData.P14InWCS)>eps then
                                                  begin
                                                  tvertex:=vertexsub(DimData.P14InWCS,tv);
                                                  tvertex:=geometry.vectordot(tvertex,self.Local.Basis.oz);
                                                  tvertex:=normalizevertex(tvertex);
                                                  end
                                           //else
                                           //    tvertex:=geometry.VertexMulOnSc(geometry.x_Y_zVertex,dir);

                                       ;tvertex:=VertexMulOnSc(tvertex,t);
                                       DimData.P10InWCS:=VertexAdd(DimData.P14InWCS,tvertex);
                                       DimData.P13InWCS:=tv;
                                       //CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);
                                   end
end;
function GDBObjAlignedDimension.P14ChangeTo(tv:GDBVertex):GDBVertex;
var
    t,dir:GDBDouble;
    tvertex:GDBVERTEX;
begin
     result:=tv;
     if (self.DimData.TextMoved)and(PDimStyle.Placing.DIMTMOVE=DTMMoveDimLine) then
                                   begin
                                         t:=GettFromLinePoint(DimData.P11InOCS,DimData.P13InWCS,tv);
                                         tvertex:=geometry.Vertexmorph(DimData.P13InWCS,tv,t);
                                         tvertex:=vertexsub(DimData.P11InOCS,tvertex);
                                         DimData.P10InWCS:=VertexAdd(tv,tvertex);
                                   end
                                else
                                    begin
                                         t:=vertexlength(DimData.P10InWCS,DimData.P14InWCS);
                                         dir:=-1;
                                         if GetCSDirFrom0x0y2D(vertexsub(DimData.P13InWCS,DimData.P14InWCS),vertexsub(DimData.P10InWCS,DimData.P14InWCS))=TCSDRight then
                                                                       begin
                                                                            t:=-t;
                                                                            dir:=-dir;
                                                                       end;
                                         //if vertexlength(DimData.P13InWCS,tv)>eps then
                                                 begin
                                                       tvertex:=vertexsub(tv,DimData.P13InWCS);
                                                       tvertex:=geometry.vectordot(tvertex,self.Local.Basis.oz);
                                                       tvertex:=normalizevertex(tvertex);
                                                 end
                                            //else
                                                //tvertex:=geometry.VertexMulOnSc(geometry.x_Y_zVertex,dir);

                                          ;tvertex:=VertexMulOnSc(tvertex,t);
                                          DimData.P10InWCS:=VertexAdd(tv,tvertex);
                                          DimData.P14InWCS:=tv;
                                          //CalcDefaultPlaceText(DimData.P13InWCS,DimData.P14InWCS);
                                    end
end;
function GDBObjAlignedDimension.GetObjTypeName;
begin
     result:=ObjN_ObjAlignedDimension;
end;
procedure GDBObjAlignedDimension.addcontrolpoints(tdesc:GDBPointer);
var pdesc:controlpointdesc;
begin
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.init({$IFDEF DEBUGBUILD}'{4CBC9A73-A88D-443B-B925-2F0611D82AB0}',{$ENDIF}4);

          pdesc.selected:=false;
          pdesc.pobject:=nil;

          pdesc.pointtype:=os_p10;
          pdesc.worldcoord:=DimData.P10InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p11;
          pdesc.worldcoord:=DimData.P11InOCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p13;
          pdesc.worldcoord:=DimData.P13InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);

          pdesc.pointtype:=os_p14;
          pdesc.worldcoord:=DimData.P14InWCS;
          PSelectedObjDesc(tdesc)^.pcontrolpoint^.add(@pdesc);
end;

function GDBObjAlignedDimension.Clone;
var tvo: PGDBObjAlignedDimension;
begin
  GDBGetMem({$IFDEF DEBUGBUILD}'GDBObjAlignedDimension.Clone',{$ENDIF}GDBPointer(tvo), sizeof(GDBObjAlignedDimension));
  tvo^.init(bp.ListPos.owner,vp.Layer, vp.LineWeight);
  CopyVPto(tvo^);
  tvo^.DimData := DimData;
  tvo^.bp.ListPos.Owner:=own;
  tvo^.PDimStyle:=PDimStyle;
  result := tvo;
end;

constructor GDBObjAlignedDimension.initnul;
begin
  inherited initnul;
  PProjPoint:=nil;
  bp.ListPos.Owner:=owner;
  vp.ID := GDBAlignedDimensionID;
  DimData.P13InWCS := createvertex(1,1,0);
  DimData.P14InWCS:= createvertex(300,1,0);
end;
constructor GDBObjAlignedDimension.init;
begin
  inherited init(own,layeraddres, lw);
  PProjPoint:=nil;
  vp.ID := GDBAlignedDimensionID;
  DimData.P13InWCS := createvertex(1,1,0);
  DimData.P14InWCS:= createvertex(300,1,0);
end;

procedure GDBObjAlignedDimension.DrawExtensionLine(p1,p2:GDBVertex;LineNumber:GDBInteger;var drawing:TDrawingDef;var DC:TDrawContext; part:integer);
var
   pl:pgdbobjline;
   pp:pgdbobjpoint;
begin
  pp:=pointer(ConstObjArray.CreateInitObj(GDBpointID,@self));
  pp.vp.Layer:=vp.Layer;
  pp.vp.LineType:=vp.LineType;
  pp.P_insertInOCS:=p1;
  pp.FormatEntity(drawing,dc);

  if vertexeq(p1,p2) then
                         pl:=DrawExtensionLineLinePart(p1,p2,drawing,part)
                     else
                         pl:=DrawExtensionLineLinePart(Vertexmorphabs2(p1,p2,PDimStyle.Lines.DIMEXO),Vertexmorphabs(p1,p2,PDimStyle.Lines.DIMEXE),drawing,part);
  //pl:=DrawExtensionLineLinePart(Vertexmorphabs2(p1,p2,PDimStyle.Lines.DIMEXO),Vertexmorphabs(p1,p2,PDimStyle.Lines.DIMEXE),drawing,part);
  pl.FormatEntity(drawing,dc);
end;
procedure GDBObjAlignedDimension.CalcDNVectors;
begin
     vectorD:=vertexsub(DimData.P14InWCS,DimData.P13InWCS);
     vectorD:=normalizevertex(vectorD);

     if geometry.sqrVertexlength(DimData.P10InWCS,DimData.P14InWCS)>sqreps then
                                                  begin
                                                  vectorN:=vertexsub(DimData.P10InWCS,DimData.P14InWCS);
                                                  end
                                              else
                                                  begin
                                                       vectorN.x:=-vectorD.y;
                                                       vectorN.y:=vectorD.x;
                                                       vectorN.z:=0;
                                                  end;
     vectorN:=normalizevertex(vectorN)
end;

procedure GDBObjAlignedDimension.FormatEntity(var drawing:TDrawingDef;var DC:TDrawContext);
var
  tv:GDBVertex;
  l:double;
begin
          ConstObjArray.cleareraseobj;
          CalcDNVectors;

          l:=GetTFromDirNormalizedPoint(DimData.P10InWCS,DimData.P14InWCS,vectorN);
          //DrawExtensionLine(DimData.P14InWCS,DimData.P10InWCS,0,drawing);
          DrawExtensionLine(DimData.P14InWCS,VertexDmorph(DimData.P14InWCS,self.vectorN,l),0,drawing,dc,1);

          //tv:=geometry.VertexSub(DimData.P10InWCS,DimData.P14InWCS);
          //tv:=geometry.VertexAdd(DimData.P13InWCS,tv);
          //DrawExtensionLine(DimData.P13InWCS,tv,1,drawing);
          l:=GetTFromDirNormalizedPoint(DimData.P10InWCS,DimData.P13InWCS,vectorN);
          tv:=VertexDmorph(DimData.P13InWCS,self.vectorN,l);
          DrawExtensionLine(DimData.P13InWCS,tv,0,drawing,dc,2);

          //CalcTextAngle;
          CalcTextParam(tv,DimData.P10InWCS);
          if not self.DimData.TextMoved then
                                            CalcDefaultPlaceText(tv,DimData.P10InWCS,drawing);

          DrawDimensionText(DimData.P11InOCS,drawing,dc);

          DrawDimensionLine(tv,DimData.P10InWCS,false,false,true,drawing,dc);
   inherited;
end;
{procedure GDBObjAlignedDimension.DrawGeometry;
begin
     geom.DrawGeometry;
end;}
function AllocAlignedDimension:PGDBObjAlignedDimension;
begin
  GDBGetMem({$IFDEF DEBUGBUILD}'{AllocAlignedDimension}',{$ENDIF}result,sizeof(GDBObjAlignedDimension));
end;
function AllocAndInitAlignedDimension(owner:PGDBObjGenericWithSubordinated):PGDBObjAlignedDimension;
begin
  result:=AllocAlignedDimension;
  result.initnul(owner);
  result.bp.ListPos.Owner:=owner;
end;
begin
  RegisterEntity(GDBAlignedDimensionID,'AlignedDimension',@AllocAlignedDimension,@AllocAndInitAlignedDimension);
end.
