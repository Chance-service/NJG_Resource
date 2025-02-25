require "Activity_pb"
local HP_pb = require("HP_pb")
local CommonPage = require("CommonPage")
local NodeHelper = require("NodeHelper")
local opcodes = {
    YAYA_RANK_INFO_C = HP_pb.YAYA_RANK_INFO_C,
    YAYA_RANK_INFO_S = HP_pb.YAYA_RANK_INFO_S
}
local option = {
    ccbiFile = "Act_GirlAnchorMoneyExchangePage.ccbi",
    handlerMap = {
        onReturnButton = "onBack",
        onHelp = "onHelp"
    }
}

local BeautyAnchorRankingPageBase = {
    
}
BeautyAnchorRankingPageBase.timerName = "Activity_BeautyAnchorRanking"
local BeautyAnchorRankingItem = {
    ccbiFile = "Act_GirlAnchorMoneyExchangeContent.ccbi",
}
local thisPageName = "BeautyAnchorRankingPage"

local PageInfo = {
    activityId = 46,
    leftTime = 0,
    selfRank = 0,
    rankList = {
    }
}
----------------------------------------------------------------------------
function BeautyAnchorRankingItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        BeautyAnchorRankingItem.onRefreshItemView(container)
    elseif eventName == "onGirlAnchorBtn" then
        BeautyAnchorRankingItem.onGirlAnchorBtn(container)
    elseif eventName:sub(1, 7) == "onFrame" then
        BeautyAnchorRankingItem.onFrame(container, eventName)
    end
end

function BeautyAnchorRankingItem.onFrame(container, eventName)
    local index = container:getItemDate().mID
    local itemInfo = PageInfo.rankList[index]
    local rewardId = ActivityConfig[PageInfo.activityId].reward[index]
    local rewardIndex = tonumber(string.sub(eventName, -1))
    if rewardId ~= nil then
        local cfg = ConfigManager.getRewardById(rewardId)
        GameUtil:showTip(container:getVarNode("mFrame" .. rewardIndex), cfg[rewardIndex])
    end
end

function BeautyAnchorRankingItem.onGirlAnchorBtn(container)
    local index = container:getItemDate().mID
    local itemInfo = PageInfo.rankList[index]
    PageManager.viewPlayerInfo(itemInfo.playerId, false)
end

function BeautyAnchorRankingItem.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local itemInfo = PageInfo.rankList[index]

    local rankStr = ""
    local name = ""
    local exchangeCount = ""
    if itemInfo ~= nil then
        rankStr = common:getLanguageString("@GirlAnchorRank", itemInfo.rank)
        name = itemInfo.name
        exchangeCount = itemInfo.exchangeCount
    else
        rankStr = common:getLanguageString("@GirlAnchorRank", index)
        name = "--"
        exchangeCount = "--"
    end

    local lb2Str = {
        mRanking = rankStr,
        mName = name,
        mGirlAnchorMoney = exchangeCount
    }
    NodeHelper:setStringForLabel(container, lb2Str)

    local rewardId = ActivityConfig[PageInfo.activityId].reward[index]

    if rewardId ~= nil then
        local cfg = ConfigManager.getRewardById(rewardId)
        NodeHelper:fillRewardItem(container, cfg, 4)
    end
end

function BeautyAnchorRankingPageBase:onEnter(container)
    self:registerPacket(container)
    NodeHelper:initScrollView(container, "mContent", 4)
    if container.mScrollView ~= nil then
        container:autoAdjustResizeScrollview(container.mScrollView)
    end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    if mScale9Sprite ~= nil then
        container:autoAdjustResizeScale9Sprite(mScale9Sprite)
    end
    common:sendEmptyPacket(opcodes.YAYA_RANK_INFO_C)
end

function BeautyAnchorRankingPageBase:onExecute(container)
    self:onTimer(container)
end

function BeautyAnchorRankingPageBase:onExit(container)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    NodeHelper:deleteScrollView(container)
end

function BeautyAnchorRankingPageBase:onBack(container)
    PageManager.changePage("ActivityPage")
end

function BeautyAnchorRankingPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_BEAUTYANCHOR)
end

function BeautyAnchorRankingPageBase:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        return
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    if remainTime + 1 > PageInfo.leftTime then
        return
    end
    PageInfo.leftTime = remainTime
    local timeStr = common:second2DateString(remainTime, false)
	NodeHelper:setStringForLabel(container, { mTime = timeStr})

    if remainTime <= 0 then
        TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
        common:sendEmptyPacket(opcodes.YAYA_RANK_INFO_C)
    end
end

function BeautyAnchorRankingPageBase:refreshPage(container)
    local selfRankStr = ""
    if PageInfo.selfRank < 0 then
        selfRankStr = common:getLanguageString("@RankGiftNotInList")
    else
        selfRankStr = PageInfo.selfRank
    end
    NodeHelper:setStringForLabel( container , { mMyRankingNum = selfRankStr } )
    if PageInfo.leftTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerName, PageInfo.leftTime)
    end
    self:rebuildItem(container)
end

function BeautyAnchorRankingPageBase:rebuildItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function BeautyAnchorRankingPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function BeautyAnchorRankingPageBase:buildItem(container)
    local size = #ActivityConfig[PageInfo.activityId].reward --table.maxn(PageInfo.rankList)--math.ceil(#PageInfo.rankList)
    NodeHelper:buildScrollView(container, size, BeautyAnchorRankingItem.ccbiFile, BeautyAnchorRankingItem.onFunction)
end

function BeautyAnchorRankingPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.YAYA_RANK_INFO_S then
        local msg = Activity2_pb.HPYaYaRankGiftRet()
        msg:ParseFromString(msgBuff)
        PageInfo.leftTime = msg.leftTimes / 1000 + 2 --倒计时结束时延迟一秒刷新界面
        PageInfo.selfRank = msg.selfRank
        PageInfo.rankList = msg.rankList
        self:refreshPage(container)
        return
    end
end

function BeautyAnchorRankingPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function BeautyAnchorRankingPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
----------------------------------------------------------------------------
BeautyAnchorRankingPage = CommonPage.newSub(BeautyAnchorRankingPageBase, thisPageName, option)
