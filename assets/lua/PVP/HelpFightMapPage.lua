
local HelpFightMapPage = {
}

local NewbieGuideManager = require("Guide.NewbieGuideManager")
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local EighteenPrinces_pb = require("EighteenPrinces_pb")
local HP_pb = require "HP_pb"
local startSweepCountKey = "STARTSWEEPCOUNTKEY"
local startSweepCountTime = 0
local thisPageName = "HelpFightMapPage"
local option = {
    ccbiFile = "HelpFightMapPage.ccbi",
    handlerMap = {
        onReturnBtn = "onClose",
        onHelp  = "onHelp",
        onReward = "onReward",
        onRank = "onRank",
        onReset = "onReset",
        onComplete = "onComplete",
        onWipe = "onWipe", --扫荡

    },
    opcodes = {
        EIGHTEENPRINCES_LAYER_INFO_S = HP_pb.EIGHTEENPRINCES_LAYER_INFO_S,
    },
}
local mapIndexTex = {"一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八"}
local myMapData = nil
local myMapServerData = nil
local mapItems = nil
local mapHeight = 294
local clickCount = 0
local mapContentSpritePosition1 = {
    leftPositionX = -83,
    leftPositionY = 45,
}
local mapContentSpritePosition2 = {
    leftPositionX = 150,
    leftPositionY = 45,
}
local MapListItem = {
    ccbiFile = "HelpFightMapContent.ccbi",
}
function MapListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        MapListItem:onRefreshContent(container)
    end
end

function MapListItem:onRefreshContent( ccbRoot )

    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    local libStr = {}
    myMapServerData = myMapServerData or {}
    myMapServerData.layerId = myMapServerData.layerId or 0
    local mapIndex = 18 - index + 1

    libStr.mCheckPointRoleName = common:getLanguageString("@Eighteen"..mapIndex)
    libStr.mCheckPointName =  common:getLanguageString(myMapData[mapIndex].mapname)
    libStr.mCheckPointNum = mapIndex
    myMapServerData.fightvalue[mapIndex] = myMapServerData.fightvalue[mapIndex] or 0
    myMapServerData.fightvalue [mapIndex] = yuan3(myMapServerData.fightvalue [mapIndex] == nil ,0,myMapServerData.fightvalue [mapIndex])
    libStr.mMapFightTxt = common:getLanguageString("@FightingCapacity")..":" ..myMapServerData.fightvalue[mapIndex]

    local spriteIcon = {}
    spriteIcon.mRoleSprite1 = myMapData[mapIndex].iconpath
    spriteIcon.mRoleSprite2 = "Imagesetfile/HelpFight/Kingdom_RoleName_Left.png"
    spriteIcon.mRoleSprite3 = myMapData[mapIndex].rolename
    spriteIcon.mRoleSprite4 = "Imagesetfile/HelpFight/Kingdom_RoleName_Right.png"
    spriteIcon.mBg = myMapData[mapIndex].map
    NodeHelper:setStringForLabel(container,libStr)
    NodeHelper:setSpriteImage(container,spriteIcon)
    local mRoleNameSprite1 = container:getVarNode("mRoleSprite1")
    local mRoleNameSprite2 = container:getVarNode("mRoleSprite2")
    local mRoleNameSprite3 = container:getVarNode("mRoleSprite3")
    local mRoleNameSprite4 = container:getVarNode("mRoleSprite4")
    local mMapFightTxt = container:getVarNode("mMapFightTxt")
    local mRoleNameSprite1PositionX,mRoleNameSprite1PositionY = nil
    local mRoleNameSprite3PositionX,mRoleNameSprite3PositionY = nil
    local mRoleNameSprite3ContenSize = nil
    if mapIndex %2 == 0 then
        mRoleNameSprite1:setPosition(ccp(mapContentSpritePosition2.leftPositionX,mapContentSpritePosition2.leftPositionY))
        mRoleNameSprite1PositionX,mRoleNameSprite1PositionY  = mRoleNameSprite1:getPosition()
        mRoleNameSprite4:setPosition(ccp(mRoleNameSprite1PositionX - 40,mRoleNameSprite1PositionY - 50))
        mRoleNameSprite3ContenSize = mRoleNameSprite3:getContentSize()
        mRoleNameSprite3:setPosition(ccp(mRoleNameSprite1PositionX - mRoleNameSprite3ContenSize.width - 40 - 10 ,mRoleNameSprite1PositionY))
        mRoleNameSprite3PositionX,mRoleNameSprite3PositionY = mRoleNameSprite3:getPosition()
        mRoleNameSprite2:setPosition(ccp(mRoleNameSprite3PositionX - 20 - 10,mRoleNameSprite3PositionY + 30))
        mMapFightTxt:setPosition(ccp(mRoleNameSprite3PositionX + mRoleNameSprite3ContenSize.width/2 ,mRoleNameSprite3PositionY-40 ))
    else
        mRoleNameSprite1:setPosition(ccp(mapContentSpritePosition1.leftPositionX,mapContentSpritePosition1.leftPositionY))
        mRoleNameSprite1PositionX,mRoleNameSprite1PositionY  = mRoleNameSprite1:getPosition()
        mRoleNameSprite2:setPosition(ccp(mRoleNameSprite1PositionX + 100 ,mRoleNameSprite1PositionY + 30))
        mRoleNameSprite3:setPosition(ccp(mRoleNameSprite1PositionX + 120 + 10,mRoleNameSprite1PositionY))
        mRoleNameSprite3PositionX,mRoleNameSprite3PositionY = mRoleNameSprite3:getPosition()
        mRoleNameSprite3ContenSize = mRoleNameSprite3:getContentSize() --height width
        mRoleNameSprite4:setPosition(ccp(mRoleNameSprite3PositionX + mRoleNameSprite3ContenSize.width + 10  ,mRoleNameSprite3PositionY -50 ))
        mMapFightTxt:setPosition(ccp(mRoleNameSprite3PositionX + mRoleNameSprite3ContenSize.width /2,mRoleNameSprite3PositionY-40))
    end

    local menuItem = container:getVarMenuItemImage("mChallengeBtn")

    if menuItem then
        local sprite = nil
        if mapIndex < myMapServerData.layerId + 1 then
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_Challenged.png")
        elseif mapIndex > myMapServerData.layerId + 1 then
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_NoOpen.png")
        else
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_CanChallenge.png")
        end
        menuItem:setNormalImage(sprite)
    end
end

function MapListItem:onRefreshAllItem()
    for i = 1, #mapItems do
        local item = mapItems[i];
        if item then
            local item = mapItems[i];
            if item then
                item.cls:onRefreshItem(item.node:getCCBFileNode());
            end
        end
    end
end

function MapListItem:onRefreshItem(container)
    if container == nil then
        return
    end
    local index = self.id
    local mapIndex = 18 - index + 1
    local menuItem = container:getVarMenuItemImage("mChallengeBtn")
    myMapServerData = myMapServerData or {}
    myMapServerData.layerId = myMapServerData.layerId or 0
    if menuItem then
        local sprite = nil
        if mapIndex < myMapServerData.layerId + 1 then
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_Challenged.png")
        elseif mapIndex > myMapServerData.layerId + 1 then
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_NoOpen.png")
        else
            sprite = CCSprite:create("Imagesetfile/HelpFight/Kingdom_CanChallenge.png")
        end
        menuItem:setNormalImage(sprite)
    end
end

function MapListItem:onChallenge(container)
    local index = self.id
    myMapServerData = myMapServerData or {}
    myMapServerData.layerId = myMapServerData.layerId or 0
    local mapIndex = 18 - index + 1
    if mapIndex < myMapServerData.layerId + 1 then
        MessageBoxPage:Msg_Box_Lan("@Eighteentip5")
        return
    elseif mapIndex > myMapServerData.layerId + 1 then
        MessageBoxPage:Msg_Box_Lan("@Eighteentip5")
        return
    else
--[[        if clickCount %2 == 0 then
        PageManager.pushPage("HelpFightSelectRolePopUp")
    else
        PageManager.pushPage("HelpFightChangeReadyPopUp")
    end
        clickCount = clickCount + 1]]

            if HelpFightDataManager.LayerInfo.isFirstBattle == 0 then

                PageManager.pushPage("HelpFightSelectRolePopUp")
            else
                PageManager.pushPage("HelpFightChangeReadyPopUp")
            end
    end
end



function MapListItem:onHand( container )
    local index = self.id
   PageManager.pushPage("HelpFightChangeReadyPopUp")
end


function MapListItem:onReward( container )
    local index = self.id
end

function MapListItem:onMap( container )
    local index = self.id
    if CCUserDefault:sharedUserDefault():getIntegerForKey("HelpFightMapPage"..UserInfo.serverId..UserInfo.playerInfo.playerId..registDay) == 0 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("HelpFightMapPage"..UserInfo.serverId..UserInfo.playerInfo.playerId..registDay,1)
        PageManager.pushPage("HelpFightSelectRolePopUp")
    else
        PageManager.pushPage("HelpFightChangeReadyPopUp")
    end

end

function HelpFightMapPage:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    container.mScrollView = container:getVarScrollView("mContent")
    if container.mScrollView~=nil then
        container:autoAdjustResizeScrollview(container.mScrollView);
    end
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_HELPFIGHTMAP)
    self:initData(container)
    self:initUI(container)
    --self:refreshPage(container)
    --先手剧情引导
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.currGuide[GuideManager.guideType.HELPFIGHT_GUIDE_1] ~= 0 then
        if GuideManager.isInGuide == false then
            GuideManager.currGuideType = GuideManager.guideType.HELPFIGHT_GUIDE_1
            GuideManager.newbieGuide()
        end
    end
    HelpFightDataManager:sendEighteenPrincesLayerInfoReq()
end

function HelpFightMapPage:initData(container)
    clickCount = 0
    myMapServerData = nil
    myMapData =  HelpFightDataManager:getHelpFightMapConfig()
end

function HelpFightMapPage:initUI(container)
    local a  = common:getLanguageString("@Eighteentitle1")
    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@Eighteentitle1") })
end

function HelpFightMapPage:showFightState( container )
    TimeCalculator:getInstance():createTimeCalcultor(startSweepCountKey, startSweepCountTime)
    TimeCalculator:getInstance():removeTimeCalcultor(startSweepCountKey)
end

function HelpFightMapPage:onExecute( container )

end

function HelpFightMapPage:GetFastFinishCost(second)
    -- floor(剩余分钟^0.75*0.5+0.5）  剩余分钟如果不足1分钟，按照一分钟计算
    local minute = math.ceil(second / 60)
    local Cost = math.floor(math.pow(minute, 0.75) * 0.5 + 0.5)
    return Cost
end




function HelpFightMapPage:refreshPage( container )
    -- 剩余boss次数
    self:rebuildAllItem(container)
end

function HelpFightMapPage:rebuildAllItem(container)
    local viewSize = container.mScrollView:getViewSize()
    if mapItems then
        myMapServerData = myMapServerData or {}
        myMapServerData.layerId = myMapServerData.layerId or 0
        --local offsetY = yuan3(-mapHeight * myMapServerData.layerId >= - )
        local contentSize = container.mScrollView:getContentSize()
        local maxOffsetY = viewSize.height - contentSize.height
        local offsetY = yuan3(-mapHeight * myMapServerData.layerId <= maxOffsetY ,maxOffsetY,-mapHeight * myMapServerData.layerId)
        MapListItem:onRefreshAllItem()
        container.mScrollView:setContentOffset(ccp(0,offsetY ))
    else
        container.mScrollView:removeAllCell()
        local count = 18
        --[[    playerInfo.curLayer.layerId = playerInfo.curLayer.layerId or 1
            count,myMapData = ClimbingDataManager:getClimbingTowerShowMapData(playerInfo.curLayer.layerId)]]
        mapItems = NodeHelper:buildCellScrollView(container.mScrollView, count,MapListItem.ccbiFile, MapListItem)
        myMapServerData = myMapServerData or {}
        myMapServerData.layerId = myMapServerData.layerId or 0
        local contentSize = container.mScrollView:getContentSize()
        local maxOffsetY = viewSize.height - contentSize.height
        local offsetY = yuan3(-mapHeight * myMapServerData.layerId <= maxOffsetY ,maxOffsetY,-mapHeight * myMapServerData.layerId)
        container.mScrollView:setContentOffset(ccp(0,offsetY ))
    end


end

function HelpFightMapPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HelpFightMapPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


function HelpFightMapPage:onReward(container)
    PageManager.pushPage("ClimbingTowerRewardPopUp")
end

function HelpFightMapPage:onRank(container)
    --ClimbingDataManager:sendClimbingRankReq()
    PageManager.pushPage("ClimbingTowerRankPopUp")
end

function  HelpFightMapPage:onReset(container)
    ClimbingDataManager:sendClimbingResetReq()
end


function  HelpFightMapPage:onWipe(container)
    ClimbingDataManager:sendClimbingSweepReq()
end

function HelpFightMapPage:onClose(container)
    PageManager.changePage("PVPActivityPage")
end


function HelpFightMapPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_HELPFIGHTMAP)
end

function HelpFightMapPage:onExit(container)
    mapItems = nil
    self:removePacket(container)
end

function HelpFightMapPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName and extraParam == "refresh" then
            myMapServerData = HelpFightDataManager.LayerInfo
            self:refreshPage(container)
        end
    end
end


function HelpFightMapPage:onReceivePacket(container)


    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.EIGHTEENPRINCES_LAYER_INFO_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesLayerInfoRet()
        msg:ParseFromString(msgBuff)
        myMapServerData =  HelpFightDataManager:EighteenPrincesLayerInfoFun(msg)
        self:refreshPage(container)
    end
end


local CommonPage  = require('CommonPage')
HelpFightMapPage = CommonPage.newSub(HelpFightMapPage, thisPageName, option)

return HelpFightMapPage