local thisPageName = "NewBattleMapPage2"
local NewBattleMapItem = require("NewBattleMapItem")
local AlbumIndivualPage=require("Album.AlbumSubPage_Indiviual")
local GuideManager = require("Guide.GuideManager")

 
local NewBattleMapPageBase = {
    container = nil
}

local option = {
    ccbiFile = "ChapterMapPage.ccbi",
    handlerMap = {
        onHelp = "onHelp",
        onLeftBtn="onLeftBtn",
        onRightBtn="onRightBtn",
        onCloseMap="onCloseMap"
    },
    opcodes = {

    }
}
local NewBattleMap = {
    ccbiFile = "ChapterMapContent.ccbi",
    container = nil,
    citys = { }
}
for i=1,24 do
    option.handlerMap["onMap"..i]="onMap"
end
for i=1,7 do
    option.handlerMap["onHeart"..i]="onHeart"
end
local mapId=1
local MapIndex=1

local FLAG_TYPE = {
    ["CLEAR"] = 1,
    ["NON_OPEN"] = 2,
    ["BATTLE"] = 3
}
local MAP_WIDTH, MAP_HEIGHT = 2500, 3500

local MAP_SCALE = 0.7

local isInAnimation = false
local isPushMathOverPage = false

local mapId = 1 

local isAnim=false
local leftSpine=nil
local RightSpine=nil

function NewBattleMapPageBase:onEnter(container)
    local scrollview = container:getVarScrollView("mContent")
    container.mScrollView = scrollview
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NewBattleMapPageBase.container = container
    GVGManager.initCityConfig()
    leftSpine=container:getVarNode("mSpineL")
    RightSpine=container:getVarNode("mSpineR")
    if not GuideManager.isInGuide then
       container:runAnimation("OpenAni")
    end
    --self:SetSpine(leftSpine)
    --self:SetSpine(RightSpine)
    local mWaitSuplyTime = GVGManager.getWaitSuplyTime()

    local mWaitTime = tonumber(mWaitSuplyTime)
    mWaitTime = mWaitTime / 1000

    TimeCalculator:getInstance():createTimeCalcultor('mWaitSuplyTime', mWaitTime)

    NodeHelper:setNodesVisible(container,{mPrepareTip = false})
    NodeHelper:setNodesVisible(container,{mBattleTip = false})
    
    local mapCfg = ConfigManager.getNewMapCfg()
    mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)

    local sprite2Img = {}
    for i = 1 , 6 do
        sprite2Img["mBgSprite" .. i] = "UI/Common/BGNew/worldmap_" .. i .. ".png"
        sprite2Img["road" .. i] = "UI/Common/BGNew/worldmap_road_" .. i .. ".png"
        NodeHelper:setNodesVisible(container,{["mMap"..i]=false})
        local ScreenW, ScreenH = GetScreenWidthAndHeight()
        local bg=container:getVarNode("mBgSprite"..i)
        if ScreenH/ScreenW==21/9 then
            bg:setScale(1)
        else
            bg:setScale(NodeHelper:getScaleProportion())
        end
    end

    NodeHelper:setSpriteImage(container, sprite2Img)

    for i = 1, 24 do
        local txt = common:getLanguageString("@MapFlag" .. i)
        NodeHelper:setStringForLabel(container, { ["mMapName"..i] = txt })
    end
    --self:initMap(container)
    self:initAllCity()
    NewBattleMapPageBase:MapSync(container)
end
function NewBattleMapPageBase:MapSync(container)
    isAnim=false
    local Chapter=ConfigManager.getNewMapCfg()[mapId].Chapter
    if Chapter<5 then
        MapIndex=1
         NodeHelper:setNodesVisible(container,{mLeftBtn=false,mSpineL=false})
    elseif Chapter<9 then
        MapIndex=2
    elseif Chapter<13 then
        MapIndex=3
    elseif Chapter<17 then
        MapIndex=4
    elseif Chapter<21 then
        MapIndex=5
    elseif Chapter<25 then
        MapIndex=6
        NodeHelper:setNodesVisible(container,{mRightBtn=false,mSpineR=false})
    end
    for i=1,6 do
       NodeHelper:setNodeVisible(container:getVarNode("mMap"..i),i==MapIndex)
    end
end
function NewBattleMapPageBase:SetSpine(node)
    local spinePath="Spine/NGUI"
    local spineName = "NGUI_75_WorldMapHeart" 
    local spine = SpineContainer:create(spinePath, spineName)
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    node:removeAllChildrenWithCleanup(true)
    node:addChild(spineNode)
    spine:runAnimation(1, "animation", -1)
end
function NewBattleMapPageBase:onMap(container,eventName)
    local index=0
    if string.len(eventName)==6 then
        index=tonumber(eventName:sub(-1))
    else
         index=tonumber(eventName:sub(-2))
    end
   
    local NewBattleMapPopUp = require("NewBattleMapPopUp")
    NewBattleMapPopUp:setCityId(index)
    PageManager.pushPage("NewBattleMapPopUp")
end

function NewBattleMapPageBase:onHeart(container,eventName)
    --local idx=tonumber(eventName:sub(-1))
    --local txt="@memoriestitle9900"..idx.."_error"
    --local Chapter=ConfigManager.getNewMapCfg()[mapId].Chapter
    --if Chapter>1 and idx==1 or 
    --   Chapter>5 and idx==2 or 
    --   Chapter>9 and idx==3 or 
    --   Chapter>13 and idx==4 or
    --   Chapter>17 and idx==5 or 
    --   Chapter>21 and idx==6 or
    --   Chapter==24 and idx==7 then
    --    AlbumIndivualPage:SetId(990)
    --    PageManager.pushPage("Album.AlbumPage")
    --else
    --    MessageBoxPage:Msg_Box(common:getLanguageString(txt))
    --end
end

function NewBattleMapPageBase:initAllCity()
    for i = 1, 24 do
        local baseNode = self.container:getVarNode("mCityPosition" .. i)
        self:initCity(baseNode, i)
    end
end

function NewBattleMapPageBase:initCity(base, cityId)
    
        local city = NewBattleMapItem:create(cityId, base)
        city:registerClick(NewBattleMapPageBase.onCityClick)
        NewBattleMap.citys[cityId] = city
end

function NewBattleMapPageBase.onFunction(eventName, container)
    if NewBattleMap[eventName] and type(NewBattleMap[eventName]) == "function" then
        NewBattleMap[eventName](container)
    end
end
function NewBattleMapPageBase.onCityClick(eventName, container)
    if eventName ~= "onFlag" then return end
    local cityItem
    for k,v in pairs(NewBattleMap.citys) do
        if v.node == container then
            cityItem = v
            break
        end
    end
    if not cityItem then return end
    cityItem:onFlag()
end
function NewBattleMapPageBase:onRightBtn(container)
    if isAnim then return end
    isAnim=true
    if MapIndex<7 then
        MapIndex=MapIndex+1 
         PlayAnim(container,-1)      
    end
    if MapIndex==6 then
        NodeHelper:setNodesVisible(container,{mRightBtn=false,mSpineR=false})
    elseif MapIndex~=1 then
        NodeHelper:setNodesVisible(container,{mLeftBtn=true,mSpineL=true})
    end
end
function NewBattleMapPageBase:onLeftBtn(container)
     if isAnim then return end
     isAnim=true
    if MapIndex>1 then
        MapIndex=MapIndex-1
        PlayAnim(container,1)
    end
    if MapIndex==1 then
        NodeHelper:setNodesVisible(container,{mLeftBtn=false,mSpineL=false})
    elseif MapIndex~=6 then
         NodeHelper:setNodesVisible(container,{mRightBtn=true,mSpineR=true})
    end
end
function NewBattleMapPageBase:onCloseMap(container)
    local array = CCArray:create()
    array:addObject(CCCallFunc:create(function()
        if not GuideManager.isInGuide then
            container:runAnimation("CloseAni")
        end
    end))
    array:addObject(CCDelayTime:create(0.6))
    array:addObject(CCCallFunc:create(function()
         MainFrame_onBattlePageBtn()
    end))

    -- ¢Xo|a¡±C|C
    container:runAction(CCSequence:create(array))
end
function PlayAnim(container,scale)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_17_WorldMapTran"
    local spine = SpineContainer:create(spinePath, spineName)
    local spine2 = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local spineNode2 = tolua.cast(spine2, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    local parentNode2 = container:getVarNode("mSpine")
    parentNode:setPositionX((scale > 0) and 834 or -114)
    parentNode:setScaleX(scale)
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode2:removeAllChildrenWithCleanup(true)
    local Ani01 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1, "animation", 0)
    end)
    local Ani02 = CCCallFunc:create(function()
        parentNode2:addChild(spineNode2)
        spine2:runAnimation(1, "animation2", 0)
    end)
    local clear = CCCallFunc:create(function()
        parentNode:removeAllChildrenWithCleanup(true)
    end)
    local switchMap = CCCallFunc:create(function()
        for i=1,6 do
            NodeHelper:setNodeVisible(container:getVarNode("mMap"..i),i==MapIndex)
        end
    end)
    local CanClick = CCCallFunc:create(function()
        isAnim=false
    end)
    local array = CCArray:create()
    
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(Ani01)
    array:addObject(CCDelayTime:create(0.25))
    array:addObject(Ani02)
    array:addObject(CCDelayTime:create(0.25))
    array:addObject(switchMap)
    array:addObject(CCDelayTime:create(1))
    array:addObject(CanClick)
    
    parentNode:runAction(CCSequence:create(array))
    
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local NewBattleMapPage = CommonPage.newSub(NewBattleMapPageBase, thisPageName, option)