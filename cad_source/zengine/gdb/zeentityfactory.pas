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

unit zeentityfactory;
{$INCLUDE def.inc}


interface
uses GDBSubordinated,uabstractunit,usimplegenerics,UGDBDrawingdef,gdbobjectsconstdef,
    memman,zcadsysvars,GDBase,GDBasetypes,GDBGenericSubEntry,gdbEntity;
type
TAllocEntFunc=function:GDBPointer;
TAllocAndInitEntFunc=function (owner:PGDBObjGenericWithSubordinated): PGDBObjEntity;
TAllocAndInitAndSetGeomPropsFunc=function (owner:PGDBObjGenericWithSubordinated;args:array of const): PGDBObjEntity;
TSetGeomPropsFunc=procedure (ent:PGDBObjEntity;args:array of const);
TEntityUpgradeFunc=function (ptu:PTAbstractUnit;ent:PGDBObjEntity;const drawing:TDrawingDef): PGDBObjEntity;
TEntInfoData=packed record
                          DXFName,UserName:GDBString;
                          EntityID:TObjID;
                          AllocEntity:TAllocEntFunc;
                          AllocAndInitEntity:TAllocAndInitEntFunc;
                          SetGeomPropsFunc:TSetGeomPropsFunc;
                          AAllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc;
                     end;
TEntUpgradeData=record
                      EntityUpgradeFunc:TEntityUpgradeFunc;
                end;

TDXFName2EntInfoDataMap=GKey2DataMap<GDBString,TEntInfoData,LessGDBString>;
TObjID2EntInfoDataMap=GKey2DataMap<TObjID,TEntInfoData,LessObjID>;
TEntUpgradeDataMap=GKey2DataMap<TEntUpgradeKey,TEntUpgradeData,LessEntUpgradeKey>;

function CreateInitObjFree(t:TObjID;owner:PGDBObjGenericSubEntry):PGDBObjEntity;
function AllocEnt(t:TObjID): GDBPointer;

procedure RegisterDXFEntity(const _EntityID:TObjID;
                         const _DXFName,_UserName:GDBString;
                         const _AllocEntity:TAllocEntFunc;
                         const _AllocAndInitEntity:TAllocAndInitEntFunc;
                         const _SetGeomPropsFunc:TSetGeomPropsFunc=nil;
                         const _AllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc=nil);
procedure RegisterEntity(const _EntityID:TObjID;
                         const _UserName:GDBString;
                         const _AllocEntity:TAllocEntFunc;
                         const _AllocAndInitEntity:TAllocAndInitEntFunc;
                         const _SetGeomPropsFunc:TSetGeomPropsFunc=nil;
                         const _AllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc=nil);
procedure RegisterEntityUpgradeInfo(const _EntityID:TObjID;
                                    const _Upgrade:TEntUpgradeInfo;
                                    const _EntityUpgradeFunc:TEntityUpgradeFunc);
var
  DXFName2EntInfoData:TDXFName2EntInfoDataMap;
  ObjID2EntInfoData:TObjID2EntInfoDataMap;
  EntUpgradeKey2EntUpgradeData:TEntUpgradeDataMap;
  NeedInit:boolean=true;

  _StandartLineCreateProcedure:TAllocAndInitAndSetGeomPropsFunc=nil;
  _StandartCircleCreateProcedure:TAllocAndInitAndSetGeomPropsFunc=nil;
  _StandartBlockInsertCreateProcedure:TAllocAndInitAndSetGeomPropsFunc=nil;
  _StandartDeviceCreateProcedure:TAllocAndInitAndSetGeomPropsFunc=nil;
  _StandartSolidCreateProcedure:TAllocAndInitAndSetGeomPropsFunc=nil;
implementation
uses
    log;
procedure _RegisterEntity(const _EntityID:TObjID;
                         const _DXFName,_UserName:GDBString;
                         const _AllocEntity:TAllocEntFunc;
                         const _AllocAndInitEntity:TAllocAndInitEntFunc;
                         const _SetGeomPropsFunc:TSetGeomPropsFunc;
                         const _AllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc;
                         const dxfent:boolean);
var
   EntInfoData:TEntInfoData;
begin
     if needinit then
     begin
       DXFName2EntInfoData:=TDXFName2EntInfoDataMap.create;
       ObjID2EntInfoData:=TObjID2EntInfoDataMap.create;
       EntUpgradeKey2EntUpgradeData:=TEntUpgradeDataMap.Create;
       NeedInit:=false;
     end;
     EntInfoData.DXFName:=_DXFName;
     EntInfoData.UserName:=_UserName;
     EntInfoData.EntityID:=_EntityID;
     EntInfoData.AllocEntity:=_AllocEntity;
     EntInfoData.AllocAndInitEntity:=_AllocAndInitEntity;
     EntInfoData.AAllocAndCreateEntFunc:=_AllocAndCreateEntFunc;

     case _EntityID of
             GDBlineID:_StandartLineCreateProcedure:=_AllocAndCreateEntFunc;
           GDBCircleID:_StandartCircleCreateProcedure:=_AllocAndCreateEntFunc;
      GDBBlockInsertID:_StandartBlockInsertCreateProcedure:=_AllocAndCreateEntFunc;
           GDBDeviceID:_StandartDeviceCreateProcedure:=_AllocAndCreateEntFunc;
            GDBSolidID:_StandartSolidCreateProcedure:=_AllocAndCreateEntFunc;
     end;

     if dxfent then
       DXFName2EntInfoData.RegisterKey(_DXFName,EntInfoData);
     ObjID2EntInfoData.RegisterKey(_EntityID,EntInfoData);
end;

procedure RegisterDXFEntity(const _EntityID:TObjID;
                         const _DXFName,_UserName:GDBString;
                         const _AllocEntity:TAllocEntFunc;
                         const _AllocAndInitEntity:TAllocAndInitEntFunc;
                         const _SetGeomPropsFunc:TSetGeomPropsFunc=nil;
                         const _AllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc=nil);
var
   EntInfoData:TEntInfoData;
begin
     _RegisterEntity(_EntityID,_DXFName,_UserName,_AllocEntity,_AllocAndInitEntity,_SetGeomPropsFunc,_AllocAndCreateEntFunc,true);
end;
procedure RegisterEntity(const _EntityID:TObjID;
                         const _UserName:GDBString;
                         const _AllocEntity:TAllocEntFunc;
                         const _AllocAndInitEntity:TAllocAndInitEntFunc;
                         const _SetGeomPropsFunc:TSetGeomPropsFunc=nil;
                         const _AllocAndCreateEntFunc:TAllocAndInitAndSetGeomPropsFunc=nil);
var
   EntInfoData:TEntInfoData;
begin
     _RegisterEntity(_EntityID,'',_UserName,_AllocEntity,_AllocAndInitEntity,_SetGeomPropsFunc,_AllocAndCreateEntFunc,false);
end;
procedure _RegisterEntityUpgradeInfo(const _EntityID:TObjID;
                                    const _Upgrade:TEntUpgradeInfo;
                                    const _EntityUpgradeFunc:TEntityUpgradeFunc);
var
   EntUpgradeKey:TEntUpgradeKey;
   EntUpgradeData:TEntUpgradeData;
begin
     EntUpgradeKey.EntityID:=_EntityID;
     EntUpgradeKey.UprradeInfo:=_Upgrade;
     EntUpgradeData.EntityUpgradeFunc:=_EntityUpgradeFunc;
     EntUpgradeKey2EntUpgradeData.RegisterKey(EntUpgradeKey,EntUpgradeData);
end;

procedure RegisterEntityUpgradeInfo(const _EntityID:TObjID;
                                    const _Upgrade:TEntUpgradeInfo;
                                    const _EntityUpgradeFunc:TEntityUpgradeFunc);
begin
     if needinit then
     begin
       DXFName2EntInfoData:=TDXFName2EntInfoDataMap.create;
       ObjID2EntInfoData:=TObjID2EntInfoDataMap.create;
       EntUpgradeKey2EntUpgradeData:=TEntUpgradeDataMap.Create;
       NeedInit:=false;
     end;
     _RegisterEntityUpgradeInfo(_EntityID,_Upgrade,_EntityUpgradeFunc);
end;


function CreateInitObjFree(t:TObjID;owner:PGDBObjGenericSubEntry): PGDBObjEntity;export;
var temp: PGDBObjEntity;
   EntInfoData:TEntInfoData;
begin
  if ObjID2EntInfoData.MyGetValue(t,EntInfoData) then
    result:=EntInfoData.AllocAndInitEntity(owner)
  else
    result:=nil;

end;
function AllocEnt(t:TObjID): GDBPointer;export;
var temp: PGDBObjEntity;
   EntInfoData:TEntInfoData;
begin
  if ObjID2EntInfoData.MyGetValue(t,EntInfoData) then
    result:=EntInfoData.AllocEntity
  else
    result := nil;
end;
initialization
  {$IFDEF DEBUGINITSECTION}LogOut('gdbentityfactory.initialization');{$ENDIF}
  if needinit then
  begin
    DXFName2EntInfoData:=TDXFName2EntInfoDataMap.create;
    ObjID2EntInfoData:=TObjID2EntInfoDataMap.create;
    EntUpgradeKey2EntUpgradeData:=TEntUpgradeDataMap.Create;
    NeedInit:=false;
  end;
finalization
  DXFName2EntInfoData.Destroy;
  ObjID2EntInfoData.Destroy;
  EntUpgradeKey2EntUpgradeData.Destroy;
end.
