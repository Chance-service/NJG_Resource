


local ClimbingTowerPage = {
}


local NewbieGuideManager = require("Guide.NewbieGuideManager")
local HP_pb = require "HP_pb"
local ClimbingTower_pb = require("ClimbingTower_pb")
local ClimbingDataManager = require("PVP.ClimbingDataManager")
local startSweepCountKey = "STARTSWEEPCOUNTKEY"
local startSweepCountTime = 0
local thisPageName = "ClimbingTowerPage"
local option = {
    ccbiFile = "ClimbingTower.ccbi",
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
        CLIMBINGTOWER_INFO_S = HP_pb.CLIMBINGTOWER_INFO_S,
        CLIMBINGTOWER_SWEEP_S = HP_pb.CLIMBINGTOWER_SWEEP_S,
        CLIMBINGTOWER_RESET_S = HP_pb.CLIMBINGTOWER_RESET_S,
        CLIMBINGTOWER_RANK_S = HP_pb.CLIMBINGTOWER_RANK_S,
    },
}
local myMapData = nil
local playerInfo = nil
 local MapListItem = {
    ccbiFile = "ClimbingTowerMapContent.ccbi",
}
function MapListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        MapListItem:onRefreshContent(container)
    end
end

function MapListItem:onRefreshContent( ccbRoot )

    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    local playerInfo = ClimbingDataManager:getClimbingTowerInfo()
    local maxLayer = 0
    if playerInfo ~= nil then
        maxLayer = playerInfo.curLayer.layerId
    end
    NodeHelper:setStringForLabel(container, {mMapName ="当前关卡:".. #myMapData - index + 1 ,mTeamNum =  "通关最高层数：".. maxLayer,mFightNum = "当前所在关卡："..playerInfo.curLayer.layerId })
--[[    local mapData = MultiEliteDataManger:getMapInfo().multiEliteInfo[index]
    local mapid = mapData.multiEliteMapId
    local chapInfo = multiChapterCfg[mapid]
    assert(multiChapterCfg[mapid], "no such chapter info")
    local mapInfo = MultiEliteDataManger:getMapInfo()
    local roomNum = 0
    for i,v in ipairs(mapInfo.multiEliteMapInfo) do
        if chapInfo.id == v.mapId then
            roomNum = v.curRoomCount
        end
    end

    local difficulty = chapInfo.difficulty
    local visibles = {}
    -- visibles.mRewardBtn = mapInfo.firstBattleTimes <= 0
    for i = 1, 9 do
        visibles["mYellowStar0"..i] = i <= difficulty
    end
    visibles["mYellowStar10"] = 10 <= difficulty

    NodeHelper:setNodesVisible(container,visibles)
    local powerStr = common:getLanguageString("@RaidMapFightingNumTxt",chapInfo.powerLimit)
    local teamNum = common:getLanguageString("@RaidMapTeamNumTxt",roomNum)
    NodeHelper:setStringForLabel(container, {
        mMapName 	= chapInfo.name,
        -- mDifficulty = difficulty,
        mFightNum 	= powerStr, --common:getLanguageString("@RaidMapFightingNumTxt",chapInfo.powerLimit),
        mTeamNum 	= teamNum
    })
    local bgNode = CCSprite:create(chapInfo.bgImg)
    local vipTitleBg = tolua.cast(container:getVarNode("mMapPic"), "CCScale9Sprite")
    if vipTitleBg then
        local vipTitleBgSize = vipTitleBg:getContentSize()
        vipTitleBg:setSpriteFrame(bgNode:displayFrame())
        vipTitleBg:setContentSize(vipTitleBgSize)
    end
    NodeHelper:setSpriteImage(container, {
        --mMapPic 	= chapInfo.bgImg,
        mBossPic 	=  multiMonsterCfg[tonumber(chapInfo.monsterId)].icon,
    })
    NodeHelper:setQualityFrames(container, {mHand = chapInfo.quality});]]

end


function MapListItem:onHand( container )
    local index = self.id
--[[    local mapInfo = MultiEliteDataManger:getMapInfo()
    local mapid = mapInfo.multiEliteInfo[index].multiEliteMapId
    local chapInfo = multiChapterCfg[mapid]
    local str = FreeTypeConfig[tonumber(chapInfo.freeTypeId)].content
    local roleCfg = ConfigManager.getRoleCfg()
    if mapInfo.multiEliteLuckRoleInfo[1] then
        local roleInfo = roleCfg[mapInfo.multiEliteLuckRoleInfo[1].roleItemId]
        if roleInfo then
            str = common:fill(str, roleInfo.name, common:getLanguageString(mapInfo.multiEliteLuckRoleInfo[1].textInfo))
        end
    end
    GameUtil:showTipStr(container:getVarNode('mHand'), str)]]
end


function MapListItem:onReward( container )
    local index = self.id
--[[    local mapInfo = MultiEliteDataManger:getMapInfo()
    local mapid = MultiEliteDataManger:getMapInfo().multiEliteInfo[index].multiEliteMapId
    local chapInfo = multiChapterCfg[mapid]
    require("NewSnowPreviewRewardPage")
    NewSnowPreviewRewardPage_SetConfig(chapInfo.reward , chapInfo.leftReward,"@RaidViewRewardTxt1", "@RaidViewRewardTxt2")
    PageManager.pushPage("NewSnowPreviewRewardPage");]]
end

function MapListItem:onMap( container )
    local index = self.id
    local selectMapId = myMapData[#myMapData - index + 1].id
    RegisterLuaPage("ClimbingTowerMapDetailPopUp")
    ClimbingTowerMapDetailPopUp_setMapId(selectMapId)
    PageManager.pushPage("ClimbingTowerMapDetailPopUp")

end

function ClimbingTowerPage:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    container.mScrollView = container:getVarScrollView("mContent")
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_CLIMBINGTOWER)

    ClimbingDataManager:sendInfoReq()
end

function ClimbingTowerPage:showFightState( container )
    TimeCalculator:getInstance():createTimeCalcultor(startSweepCountKey, startSweepCountTime)
    TimeCalculator:getInstance():removeTimeCalcultor(startSweepCountKey)
end

function ClimbingTowerPage:onExecute( container )
--[[    if TimeCalculator:getInstance():hasKey(startSweepCountKey) then
        local fightTimeLeftStr = ""
        if tonumber(TimeCalculator:getInstance():getTimeLeft(startSweepCountKey)) > 0 then
            fightTimeLeftStr = common:getLanguageString("@MultiEliteFightTimeCount",
                tostring(TimeCalculator:getInstance():getTimeLeft(startSweepCountKey)))
        -- NodeHelper:setNodesVisible(container, {mPasswordNode = false, mCountdownNode = true})
            NodeHelper:setStringForLabel(container, { mCountdownLabel = fightTimeLeftStr })
        end
    end]]
end

function ClimbingTowerPage:GetFastFinishCost(second)
    -- floor(剩余分钟^0.75*0.5+0.5）  剩余分钟如果不足1分钟，按照一分钟计算
    local minute = math.ceil(second / 60)
    local Cost = math.floor(math.pow(minute, 0.75) * 0.5 + 0.5)
    return Cost
end




function ClimbingTowerPage:refreshPage( container )
    -- 剩余boss次数
    self:rebuildAllItem(container)
end

function ClimbingTowerPage:rebuildAllItem(container)
    playerInfo = ClimbingDataManager:getClimbingTowerInfo()
    container.mScrollView:removeAllCell()
    local count = 0
    playerInfo.curLayer.layerId = playerInfo.curLayer.layerId or 1
    count,myMapData = ClimbingDataManager:getClimbingTowerShowMapData(playerInfo.curLayer.layerId)
    NodeHelper:buildCellScrollView(container.mScrollView, count,MapListItem.ccbiFile, MapListItem)
    container.mScrollView:setContentOffset(ccp(0,0))

end

function ClimbingTowerPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ClimbingTowerPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


function ClimbingTowerPage:onReward(container)
    PageManager.pushPage("ClimbingTowerRewardPopUp")
end

function ClimbingTowerPage:onRank(container)
    --ClimbingDataManager:sendClimbingRankReq()
    PageManager.pushPage("ClimbingTowerRankPopUp")
end

function  ClimbingTowerPage:onReset(container)
    ClimbingDataManager:sendClimbingResetReq()
end

function  ClimbingTowerPage:onComplete(container)
    local title = "测试"
    local msg =  "测试"
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then

        else

        end
    end , true, "@MercenaryExpeditionFinishButton", "@MercenaryExpeditionGiveUpBtn", true);
end


function  ClimbingTowerPage:onWipe(container)
   ClimbingDataManager:sendClimbingSweepReq()
end

function ClimbingTowerPage:onClose(container)
    PageManager.changePage("PVPActivityPage")
end


function ClimbingTowerPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_CLIMBINGTOWER)
end

function ClimbingTowerPage:onExit(container)
    self:removePacket(container)
end

function ClimbingTowerPage:onReceiveMessage(container)

end


function ClimbingTowerPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.CLIMBINGTOWER_INFO_S then
        local msg = ClimbingTower_pb.ClimbingTowerPlayerInfo()
        msg:ParseFromString(msgBuff)
        ClimbingDataManager:setClimbingTowerInfo(msg)
        self:refreshPage(container)
    elseif opcode == HP_pb.CLIMBINGTOWER_SWEEP_S then
        local msg = ClimbingTower_pb.HPClimbingTowerSweepSyncS()
        msg:ParseFromString(msgBuff)
        ClimbingDataManager:setClibingTowerSweepData(msg)
    elseif opcode == HP_pb.CLIMBINGTOWER_RESET_S then
--[[        local msg = ClimbingTower_pb.ClimbingTowerPlayerInfo()
        msg:ParseFromString(msgBuff)]]

    end
end


local CommonPage  = require('CommonPage')
ClimbingTowerPage = CommonPage.newSub(ClimbingTowerPage, thisPageName, option)

return ClimbingTowerPage