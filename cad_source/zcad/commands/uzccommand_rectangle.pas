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
@author()
}
{$mode delphi}
unit uzccommand_rectangle;

{$INCLUDE def.inc}

interface
uses
  LazLogger,
  SysUtils,
  uzccommandsabstract,uzccommandsimpl,
  uzccominteractivemanipulators,
  uzcstrconsts,
  uzbgeomtypes,
  uzccommandsmanager,
  uzeentlwpolyline,uzeentpolyline,uzeentityfactory,
  uzcdrawings,
  uzcutils,
  uzbtypes,
  uzegeometry,
  uzccommand_polygon,
  URecordDescriptor,typedescriptors,Varman;

type
  //** Тип данных для отображения в инспекторе опций команды Rectangle
  TRectangParam=record
                     ET:TRectangEntType;(*'Entity type'*)      //**< Выбор типа примитива, которым будет создан прямоугольник - 3Dolyline или LWPolyline
                     //VNum:GDBInteger;(*'Number of vertices'*)  //**< Определение количества вершин
                     PolyWidth:Double;(*'Polyline width'*)  //**< Ширина полилинии (если в качестве примитива выбран RET_LWPoly)
               end;

implementation

var
  RectangParam:TRectangParam;     //**< Переменная содержащая опции команды Rectangle

  function DrawRectangle_com(operands:TCommandOperands):TCommandResult;    //< Чертим прямоугольник
  var
      vertexLWObj:GDBvertex2D;               //переменная для добавления вершин в полилинию
      vertexObj:GDBvertex;
      widthObj:GLLWWidth;                    //переменная для добавления веса линии в начале и конце пути
      polyLWObj:PGDBObjLWPolyline;
      polyObj:PGDBObjPolyline;
      pe:T3PointPentity;
      PInternalRTTITypeDesk:PRecordDescriptor; //**< Доступ к панели упр в инспекторе
      pf:PfieldDescriptor;  //**< Управление нашей панелью в инспекторе

  begin
     PInternalRTTITypeDesk:=pointer(SysUnit^.TypeName2PTD('TRectangParam'));//находим описание типа TRectangParam, мы сразу знаем что это описание записи, поэтому нужно привести тип
     pf:=PInternalRTTITypeDesk^.FindField('ET'); //находим описание поля ET
     pf^.base.Attributes:=pf^.base.Attributes and (not FA_READONLY);//сбрасываем ему флаг ридонли
     pf:=PInternalRTTITypeDesk^.FindField('PolyWidth'); //находим описание поля ET
     //pf^.base.Attributes:=pf^.base.Attributes and (not FA_READONLY);//сбрасываем ему флаг ридонли
     //pf:=PInternalRTTITypeDesk^.FindField('VNum');//находим описание поля VNum
     //pf^.base.Attributes:=pf^.base.Attributes or FA_HIDDEN_IN_OBJ_INSP;//устанавливаем ему флаг cкрытности
     //pf^.base.Attributes:=pf^.base.Attributes and (not FA_READONLY);//сбрасываем ему флаг ридонли
     zcShowCommandParams(PInternalRTTITypeDesk,@RectangParam);

     if commandmanager.get3dpoint(rscmSpecifyFirstPoint,pe.p1) then
     begin
        pf:=PInternalRTTITypeDesk^.FindField('ET');//находим описание поля ET
        pf^.base.Attributes:=pf^.base.Attributes or FA_READONLY;//устанавливаем ему флаг ридонли
        pf:=PInternalRTTITypeDesk^.FindField('PolyWidth');//находим описание поля ET
        pf^.base.Attributes:=pf^.base.Attributes or FA_READONLY;//устанавливаем ему флаг ридонли

       //Создаем сразу 4-е точки прямоугольника, что бы в манипуляторе только управльть их координатами
        widthObj.endw:=RectangParam.PolyWidth;
        widthObj.startw:=RectangParam.PolyWidth;
        if RectangParam.ET = RET_LWPoly then
          begin
               polyLWObj:=GDBObjLWPolyline.CreateInstance;
               polyLWObj^.Closed:=true;
               //drawings.GetCurrentDWG^.ConstructObjRoot.AddMi(@polyLWObj);//было, теперь стало, не @указатель, а просто указатель
               zcAddEntToCurrentDrawingConstructRoot(polyLWObj);
               vertexLWObj.x:=pe.p1.x;
               vertexLWObj.y:=pe.p1.y;
               polyLWObj^.Vertex2D_in_OCS_Array.PushBackData(vertexLWObj);
               polyLWObj^.Width2D_in_OCS_Array.PushBackData(widthObj);

               polyLWObj^.Vertex2D_in_OCS_Array.PushBackData(vertexLWObj);
               polyLWObj^.Width2D_in_OCS_Array.PushBackData(widthObj);

               polyLWObj^.Vertex2D_in_OCS_Array.PushBackData(vertexLWObj);
               polyLWObj^.Width2D_in_OCS_Array.PushBackData(widthObj);

               polyLWObj^.Vertex2D_in_OCS_Array.PushBackData(vertexLWObj);
               polyLWObj^.Width2D_in_OCS_Array.PushBackData(widthObj);

               InteractiveLWRectangleManipulator(polyLWObj,pe.p1,false);
               if commandmanager.Get3DPointInteractive(rscmSpecifySecondPoint,pe.p2,@InteractiveLWRectangleManipulator,polyLWObj) then
               begin
                  zcAddEntToCurrentDrawingWithUndo(polyLWObj); //Добавить объект из конструкторской области в чертеж через ундо//
                  {так как сейчас у нас объект находится и в чертеже и в конструируемой области,
                  нужно почистить список примитивов конструируемой области, без физического удаления примитивов}
                  //drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.Clear;
                  zcClearCurrentDrawingConstructRoot;
               end
          end
          else begin
               polyObj:=GDBObjPolyline.CreateInstance;
               polyObj^.Closed:=true;
               //drawings.GetCurrentDWG^.ConstructObjRoot.AddMi(@polyObj);
               zcAddEntToCurrentDrawingConstructRoot(polyObj);
               vertexObj:=pe.p1;
               polyObj^.VertexArrayInOCS.PushBackData(vertexObj);
               polyObj^.VertexArrayInOCS.PushBackData(vertexObj);
               polyObj^.VertexArrayInOCS.PushBackData(vertexObj);
               polyObj^.VertexArrayInOCS.PushBackData(vertexObj);
               InteractiveRectangleManipulator(polyObj,pe.p1,false);
               if commandmanager.Get3DPointInteractive(rscmSpecifySecondPoint,pe.p2,@InteractiveRectangleManipulator,polyObj) then
               begin
                  zcAddEntToCurrentDrawingWithUndo(polyObj); //Добавить объект из конструкторской области в чертеж через ундо//
                  {так как сейчас у нас объект находится и в чертеже и в конструируемой области,
                  нужно почистить список примитивов конструируемой области, без физического удаления примитивов}
                  //drawings.GetCurrentDWG^.ConstructObjRoot.ObjArray.Clear;
                  zcClearCurrentDrawingConstructRoot;
               end
          end;
      end;
      zcHideCommandParams; //< Возвращает инспектор в значение по умолчанию
      result:=cmd_ok;
  end;

initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');

  SysUnit.RegisterType(TypeInfo(TRectangParam));//регистрируем тип данных в зкадном RTTI
  SysUnit.SetTypeDesk(TypeInfo(TRectangParam),['ET','PolyWidth'],[FNProgram]);//Даем програмные имена параметрам, по идее это должно быть в ртти, но ненашел
  SysUnit.SetTypeDesk(TypeInfo(TRectangParam),['Entity type','Polyline width'],[FNUser]);//Даем человечьи имена параметрам

  CreateCommandFastObjectPlugin(@DrawRectangle_com,'Rectangle',CADWG,0);
  RectangParam.ET:=RET_3DPoly;
  RectangParam.PolyWidth:=0;
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
end.
