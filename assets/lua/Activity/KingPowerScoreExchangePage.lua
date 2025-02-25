----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------
local HP_pb = require "HP_pb"
local Activity2_pb = require("Activity2_pb")
local thisPageName = "KingPowerScoreExchangePage"
local KingPowerScoreExchangePage = { }
local CatchFish_pb = require("CatchFish_pb")
local areadyGetIds = { }
local UserItemManager = require("Item.UserItemManager")
local FishInfoCfg = nil
local ConstExchaneItemId = 106011
local mNum = nil
local exchaneConfig = ConfigManager.getHaremExchangeCfg()
local option = {
    ccbiFile = "Act_TimeLimitKingPalaceScoreContent.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onConfirmation = "onConfirmation",
    },
    opcodes =
    {
        HAREM_PANEL_INFO_C = HP_pb.HAREM_PANEL_INFO_C,
        HAREM_PANEL_INFO_S = HP_pb.HAREM_PANEL_INFO_S,
        HAREM_EXCHANGE_C = HP_pb.HAREM_EXCHANGE_C,
        HAREM_EXCHANGE_S = HP_pb.HAREM_EXCHANGE_S,
        ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
        ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    }
};

local KingExchangePageInfo =
{
    goodsInfos = { },
    surplusScore = 0,
    leftTime = 0,
    lastScrollViewOffset = nil,
    activityTimerName = "NewSnowScoreExchange",
    thisContainer = nil,
}
local KingExchangeContent =
{
    ccbiFile = "Act_TimeLimitKingPalaceScoreListContent.ccbi"
}
-----------------KingExchangeContent-----------------------------
local splitTiem = function(itemInfo)
    local items = { }
    local _type, _id, _count = unpack(common:split(itemInfo, "_"));
    items = {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count)
    }
    return items;
end

function KingExchangeContent_onReceive()
    local index = 1
    local ItemInfo = KingExchangePageInfo.haremScoreInfo[index];
    local rewards = splitTiem(ItemInfo.exchangeItems)

    local exchangeItems = 10001
    -- 占位
    local totalNum = -1
    local costNum = 1
    if ItemInfo:HasField("costCredits") then
        totalNum = KingExchangePageInfo.score
        costNum = ItemInfo.costCredits
    end

    if ItemInfo:HasField("costItems") then
        exchangeItems = splitTiem(ItemInfo.costItems)
        costNum = exchangeItems.count
    end

    local msg = Activity2_pb.HPHaremExchangeReq();
    msg.times = 1;
    msg.id = ItemInfo.id
    common:sendPacket(HP_pb.HAREM_EXCHANGE_C, msg, false);
    KingExchangePageInfo.lastScrollViewOffset = KingExchangePageInfo.thisContainer.mScrollView:getContentOffset()
    PageManager.refreshPage("KingPowerPage", tostring(KingExchangePageInfo.score))
    PageManager.popPage(thisPageName)

end

function KingExchangeContent:onReceive(container)
    local index = self.id
    local ItemInfo = KingExchangePageInfo.haremScoreInfo[index];
    local rewards = splitTiem(ItemInfo.exchangeItems)

    local exchangeItems = 10001
    -- 占位
    local totalNum = -1
    local costNum = 1
    if ItemInfo:HasField("costCredits") then
        totalNum = KingExchangePageInfo.score
        costNum = ItemInfo.costCredits
    end

    if ItemInfo:HasField("costItems") then
        exchangeItems = splitTiem(ItemInfo.costItems)
        costNum = exchangeItems.count
    end

    PageManager.showCountTimesWithIconPage(rewards.type, rewards.itemId, exchangeItems,
    function(count)
        return count * costNum
    end ,
    function(isBuy, count)
        if isBuy then
            local msg = Activity2_pb.HPHaremExchangeReq();
            msg.times = count;
            msg.id = ItemInfo.id
            common:sendPacket(HP_pb.HAREM_EXCHANGE_C, msg, false);
            KingExchangePageInfo.lastScrollViewOffset = KingExchangePageInfo.thisContainer.mScrollView:getContentOffset()

        end
    end , true, ItemInfo.limitTimes - ItemInfo.exchangeTimes, "@LoadTreasureTableTitle", "@pointNotEnough", totalNum)
end

function KingExchangeContent:onFeet1(container)
    local index = self.id
    local ItemInfo = KingExchangePageInfo.haremScoreInfo[index];
    local rewards = splitTiem(ItemInfo.exchangeItems)
    GameUtil:showTip(container:getVarNode('mRewardPic1'), rewards)
end


function KingExchangeContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local lb2Str = { };
    local color = { };
    local index = self.id
    local ItemInfo = KingExchangePageInfo.haremScoreInfo[index];
    local sprite2Img = { }
    local scaleMap = { }
    local visible = { }
    local menu2Quality = { }
    local colorMap = { }
    local rewards = splitTiem(ItemInfo.exchangeItems)
    local rewardResInfo = ResManagerForLua:getResInfoByTypeAndId(rewards.type, rewards.itemId, rewards.count);
    -- NodeHelper:fillRewardItem(container,{rewards},1)
    sprite2Img["mRewardPic1"] = rewardResInfo.icon;
    sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(rewardResInfo.quality);
    lb2Str["mNum1"] = "x" .. GameUtil:formatNumber(rewards.count);
    lb2Str["mName1"] = rewardResInfo.name;
    menu2Quality["mFeet1"] = rewardResInfo.quality
    --colorMap["mNum1"] = "32 29 0"
    -- colorMap["mNum1"] = ConfigManager.getQualityColor()[rewardResInfo.quality].textColor
    colorMap["mName1"] = ConfigManager.getQualityColor()[rewardResInfo.quality].textColor

    lb2Str["mLimitNum"] = common:getLanguageString("@KingPowerExchangeLeftTimes", ItemInfo.exchangeTimes, ItemInfo.limitTimes)
    if rewardResInfo.iconScale then
        scaleMap["mRewardPic1"] = 1
        -- scaleMap["mRewardPic1"] = rewardResInfo.iconScale
    end

    -- KingExchangePageInfo.score.. "/" ..ItemInfo.costCredits
    if ItemInfo:HasField("costCredits") then
        --lb2Str["mScoreNum"] = ItemInfo.costCredits .. "/" .. KingExchangePageInfo.score
        lb2Str["mScoreNum"] = KingExchangePageInfo.score .. "/" .. ItemInfo.costCredits
        visible["mScoreNode"] = true
        visible["mIconNode"] = false
        lb2Str["mFragmentCount"] = ""
        if KingExchangePageInfo.score >= ItemInfo.costCredits then
            color["mScoreNum"] = GameConfig.ColorMap.COLOR_GREEN
        else
            color["mScoreNum"] = GameConfig.ColorMap.COLOR_RED
        end
    end
    if ItemInfo:HasField("costItems") then
        local UserMercenaryManager = require("UserMercenaryManager")
        local mercenaryInfo = UserMercenaryManager:getMercenaryStatusByItemId(rewards.itemId)
        if mercenaryInfo then
            lb2Str["mFragmentCount"] = common:getLanguageString("@HalloweenFragmentNumberTxt") .. " " .. mercenaryInfo.soulCount .. " / " .. mercenaryInfo.costSoulCount
            color["mFragmentCount"] = GameConfig.ColorMap.COLOR_GREEN
        else
            lb2Str["mFragmentCount"] = ""
        end
        local itemInfo = splitTiem(ItemInfo.costItems)
        visible["mScoreNode"] = false
        visible["mIconNode"] = true
        local res = ResManagerForLua:getResInfoByTypeAndId(tonumber(itemInfo.type), tonumber(itemInfo.itemId), tonumber(itemInfo.count), true)
        -- sprite2Img["mIcon1"] = res.icon
        visible["mIcon1"] = true
        --   res.count.. "/" ..itemInfo.count
       -- lb2Str["mIntegralNum"] = itemInfo.count .. "/" .. res.count

        lb2Str["mIntegralNum"] = res.count .. "/" .. itemInfo.count
        if res.count >= itemInfo.count then
            color["mIntegralNum"] = GameConfig.ColorMap.COLOR_GREEN
        else
            color["mIntegralNum"] = GameConfig.ColorMap.COLOR_RED
        end
    end
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setColorForLabel(container, color)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setNodesVisible(container, visible)

    NodeHelper:setColorForLabel(container, colorMap)
    if index == 1 then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["KingPowerScoreExchangePage"] = container
        if GuideManager.IsNeedShowPage == true and GuideManager.getCurrentStep() == 31 then
            PageManager.pushPage("NewbieGuideForcedPage")
            PageManager.popPage("NewGuideEmptyPage")
            GuideManager.IsNeedShowPage = false
        end
    end
end



-----------------KingExchangeContent-----------------------------

function KingPowerScoreExchangePage:onEnter(container)


    container.mScrollView = container:getVarScrollView("mContent")
    KingExchangePageInfo.lastScrollViewOffset = nil
    KingExchangePageInfo.thisContainer = container
    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@KingPalaceExchange") })

    NodeHelper:setStringForLabel(container, { mScoreNum = "", mCurrentIntegral = "" })

    self:registerPacket(container);
    self:getActivityInfo();
    local relativeNode = container:getVarNode("mContentBg")
    GameUtil:clickOtherClosePage(relativeNode, function()
        self:onClose()
    end , container)
end

----------------------------------------------------------------
function KingPowerScoreExchangePage:refreshPage(container)

    -- if KingExchangePageInfo.leftTime > 0 and not TimeCalculator:getInstance():hasKey(KingExchangePageInfo.activityTimerName) then
    --     NodeHelper:setNodesVisible(container,{mMasterNode = true})
    --     TimeCalculator:getInstance():createTimeCalcultor(KingExchangePageInfo.activityTimerName, KingExchangePageInfo.leftTime)
    -- end

    local num3 = UserItemManager:getCountByItemId(ConstExchaneItemId)
    NodeHelper:setStringForLabel(container, { mScoreNum = num3, mCurrentIntegral = KingExchangePageInfo.score })
    self:rebuildAllItem(container)
end


function KingPowerScoreExchangePage:onExecute(container)
    self:onActivityTimer(container)
end

function KingPowerScoreExchangePage:onActivityTimer(container)
    local timerName = KingExchangePageInfo.activityTimerName
    -- print("timerName = ",timerName)
    if TimeCalculator:getInstance():hasKey(timerName) then
        local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
        if remainTime + 1 > KingExchangePageInfo.leftTime then
            return;
        end
        KingExchangePageInfo.leftTime = math.max(remainTime, 0)
        local timeStr = common:second2DateString(KingExchangePageInfo.leftTime, false)
        NodeHelper:setStringForLabel(container, { mLoginDaysNum = timeStr })
    end

end


function KingPowerScoreExchangePage:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function KingPowerScoreExchangePage:buildItem(container)
    if KingExchangePageInfo == nil or KingExchangePageInfo.haremScoreInfo == nil then
       return
    end
    --新添加的ssr兑换

    table.sort(KingExchangePageInfo.haremScoreInfo, function(v1,v2)
        if exchaneConfig[v1.id] and exchaneConfig[v2.id] then
            return exchaneConfig[v1.id].order < exchaneConfig[v2.id].order
        end
        return false
    end)

    NodeHelper:buildCellScrollView(container.mScrollView, #KingExchangePageInfo.haremScoreInfo, KingExchangeContent.ccbiFile, KingExchangeContent);
end

function KingPowerScoreExchangePage:clearAllItem(container)
    container.mScrollView:removeAllCell()
end
----------------click event------------------------
function KingPowerScoreExchangePage:onClose(container)
    PageManager.refreshPage("KingPowerPage", tostring(KingExchangePageInfo.score))
    PageManager.popPage(thisPageName)

end

function KingPowerScoreExchangePage:onConfirmation(container)
    PageManager.popPage(thisPageName)
end

function KingPowerScoreExchangePage:getActivityInfo()
    common:sendEmptyPacket(HP_pb.HAREM_PANEL_INFO_C, true)


end

function KingPowerScoreExchangePage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.HAREM_PANEL_INFO_S or opcode == HP_pb.HAREM_EXCHANGE_S then
        local msg = Activity2_pb.HPHaremScorePanelRes()
        msg:ParseFromString(msgBuff)
        KingExchangePageInfo.haremScoreInfo = msg.haremScoreInfo
        self:isShowEquipmentPoint(KingExchangePageInfo.haremScoreInfo)
        KingExchangePageInfo.score = msg.score
        -- self:refreshPage(container);
        if KingExchangePageInfo.thisContainer and KingExchangePageInfo.lastScrollViewOffset then
            KingExchangePageInfo.thisContainer.mScrollView:setContentOffset(KingExchangePageInfo.lastScrollViewOffset)
        end
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local RoleOpr_pb = require("RoleOpr_pb")
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        local mercenaryInfos = msg.roleInfos
        if mercenaryInfos then
            local UserMercenaryManager = require("UserMercenaryManager")
            UserMercenaryManager:setMercenaryStatusInfos(mercenaryInfos)
            self:refreshPage(container);
        end
    end
end

function KingPowerScoreExchangePage:isShowEquipmentPoint(haremScoreInfo)
    local UserMercenaryManager = require("UserMercenaryManager")
    local itemInfo = nil
    local mercerInfo = nil
    if haremScoreInfo ~= nil then
        for i = 1, #haremScoreInfo do
            if haremScoreInfo[i].costItems ~= nil then
                if haremScoreInfo[i].exchangeTimes >= haremScoreInfo[i].limitTimes then
                    itemInfo = splitTiem(haremScoreInfo[i].exchangeItems)
                    mercerInfo = UserMercenaryManager:getUserMercenaryByItemId(itemInfo.itemId)
                    if mercerInfo == nil then
                        PageManager.showRedNotice("Equipment", true)
                        break
                    end
                    itemInfo = nil
                    mercerInfo = nil
                end
            end
        end
    end
end

function KingPowerScoreExchangePage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function KingPowerScoreExchangePage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function KingPowerScoreExchangePage:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container);
    TimeCalculator:getInstance():removeTimeCalcultor(KingExchangePageInfo.activityTimerName)
end

function KingPowerScoreExchangePage:onloadCcbiFile(num)
    if num == nil or num == 1 then
        -- 没有字描述
        option.ccbiFile = "Act_TimeLimitKingPalaceScoreContent.ccbi"
    else
        -- 多一行字的描述
        option.ccbiFile = "Act_TimeLimitKingPalaceScoreNewContent.ccbi"
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local KingPowerScoreExchangePage = CommonPage.newSub(KingPowerScoreExchangePage, thisPageName, option);
return KingPowerScoreExchangePage