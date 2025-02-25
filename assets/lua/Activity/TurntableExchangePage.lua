
----------------------------------------------------------------------------------
local HP_pb = require "HP_pb"
local Activity3_pb = require("Activity3_pb")
local thisPageName = "TurntableExchangePage"
local TurntableExchangePage = {}
local ExchangeListCfg = {}
local areadyGetIds = {}
local isTurntableSyncFlag = false
local option = {
	ccbiFile = "Act_LoadTreasureTablePopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
		onConfirmation = "onConfirmation",
	},
    opcodes = {
	    SYNC_TURNTABLE_EXCHANGE_C = HP_pb.SYNC_TURNTABLE_EXCHANGE_C,
	    TURNTABLE_EXCHANGE_C = HP_pb.TURNTABLE_EXCHANGE_C,
        TURNTABLE_EXCHANGE_S = HP_pb.TURNTABLE_EXCHANGE_S,
        TURNTABLE_C = HP_pb.TURNTABLE_C
    }
};
local ScoreExchangePageInfo =
{
    goodsInfos = {},
    surplusScore = 0,
    leftTime = 0,
    lastScrollViewOffset = nil,
    activityTimerName = "NewSnowScoreExchange",
    thisContainer = nil,
}
local ExchangeContent = 
{
    ccbiFile = "Act_LoadTreasureTableContent.ccbi"
}
-----------------ExchangeContent-----------------------------
local splitTiem = function (itemInfo)
	local items = {}
	local _type, _id, _count = unpack(common:split(itemInfo, "_"));
	table.insert(items, {
		type 	= tonumber(_type),
		itemId	= tonumber(_id),
		count 	= tonumber(_count)
	});
	return items;
end
function ExchangeContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ExchangeContent.onRefreshItemView(container);
     elseif eventName == "onFeet1" then
        local contentId = container:getItemDate().mID;
        local ItemInfo = ExchangeListCfg[contentId];
        local reward = ItemInfo.rewards[1]
        GameUtil:showTip(container:getVarNode("mRewardPic1"), reward)
    elseif eventName == "onReceive" then
        local contentId = container:getItemDate().mID;
        local ItemInfo = ExchangeListCfg[contentId];
        local max = ItemInfo.times - ScoreExchangePageInfo.goodsInfos[ItemInfo.id]
        if max <= 0 then
            MessageBoxPage:Msg_Box_Lan("@CountNotEnough")
            return 
        end
        ExchangeContent:onBuyTimes(container,ItemInfo,max)
	end	
end

function ExchangeContent.onSelectCallback()
end

function ExchangeContent:onBuyTimes(container,ItemInfo,max)
    -- local max = ScoreExchangePageInfo.surplusScore
    local title = common:getLanguageString("@LoadTreasureTableTitle")
    local message = common:getLanguageString("@ManyPeopleShopGiftInfoTxt")
    local consume = ItemInfo.consume--倍数限制
    local rewards = ItemInfo.rewards[1]--奖励

    PageManager.showCountTimesWithIconPage(rewards.type,rewards.itemId,rewards.itemId,
    function(count) 
        return count*consume
    end,
    function ( isBuy, count  )
        if isBuy then
            isTurntableSyncFlag = true
            local msg = Activity3_pb.TurntableExchangeReq()
            msg.id = ItemInfo.id
            msg.times = count
            common:sendPacket(HP_pb.TURNTABLE_EXCHANGE_C, msg, false);
        end
    end,true,max, "@TLExchangeTitle","@TLExchangeNotEnough", ScoreExchangePageInfo.surplusScore)
end

function ExchangeContent.onRefreshItemView(container)
    local lb2Str = {};
    local index = container:getItemDate().mID
    -- local ItemInfo = ScoreExchangePageInfo.goodsInfos[index];
    local ItemInfo = ExchangeListCfg[index];
    local sprite2Img = {}
    local rewards = ItemInfo.rewards[1]
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewards.type, rewards.itemId, rewards.count);

    lb2Str["mIntegralNum"] = ItemInfo.consume
    lb2Str["mName1"] = resInfo.name
    lb2Str["mLimitNum"] = ScoreExchangePageInfo.goodsInfos[ItemInfo.id].."/"..ItemInfo.times--ScoreExchangePageInfo.goodsInfos[ItemInfo.id]
    lb2Str["mNum1"] = rewards.count
    NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, { mRewardPic1 = resInfo.icon}, {mRewardPic1 = resInfo.iconScale});
	NodeHelper:setQualityFrames(container, { mFeet1 = resInfo.quality});
    if ScoreExchangePageInfo.goodsInfos[ItemInfo.id] >= ItemInfo.times then
        NodeHelper:setMenuItemEnabled( container, "mReceive", false);
    else
        NodeHelper:setMenuItemEnabled( container, "mReceive", true);
    end
end

-----------------ExchangeContent-----------------------------

function TurntableExchangePage:onEnter(container)
    isTurntableSyncFlag = false
    NodeHelper:initScrollView(container, "mContent", 12);
    ScoreExchangePageInfo.lastScrollViewOffset = nil
    ScoreExchangePageInfo.thisContainer = container
    self:registerPacket(container);
    self:getActivityInfo(container);
end

----------------------------------------------------------------
function TurntableExchangePage:refreshPage(container)

    if ScoreExchangePageInfo.leftTime > 0 and not TimeCalculator:getInstance():hasKey(ScoreExchangePageInfo.activityTimerName) then
        NodeHelper:setNodesVisible(container,{mMasterNode = true})
        TimeCalculator:getInstance():createTimeCalcultor(ScoreExchangePageInfo.activityTimerName, ScoreExchangePageInfo.leftTime)
    end

    NodeHelper:setStringForLabel( container, { mIntegralNum= ScoreExchangePageInfo.surplusScore} )
    self:rebuildAllItem(container)
end


function TurntableExchangePage:onExecute( container )
    self:onActivityTimer( container )
end

function TurntableExchangePage:onActivityTimer( container )
    local timerName = ScoreExchangePageInfo.activityTimerName
    -- print("timerName = ",timerName)
    if TimeCalculator:getInstance():hasKey(timerName) then
        local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
        if remainTime + 1 > ScoreExchangePageInfo.leftTime then
            return;
        end
        ScoreExchangePageInfo.leftTime = math.max(remainTime, 0)
        local timeStr = common:second2DateString(ScoreExchangePageInfo.leftTime, false)
        NodeHelper:setStringForLabel(container, { mLoginDaysNum = timeStr } )
    end

end


function TurntableExchangePage:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function TurntableExchangePage:buildItem(container)
    NodeHelper:buildScrollView(container,#ExchangeListCfg, ExchangeContent.ccbiFile, ExchangeContent.onFunction);
end

function TurntableExchangePage:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end
----------------click event------------------------
function TurntableExchangePage:onClose(container)
    PageManager.refreshPage("NewSnowTreasurePage", tostring(ScoreExchangePageInfo.surplusScore))
	PageManager.popPage(thisPageName)
end

function TurntableExchangePage:onConfirmation(container)
     PageManager.popPage(thisPageName)
end

function TurntableExchangePage:getActivityInfo(container)
    common:sendEmptyPacket(HP_pb.SYNC_TURNTABLE_EXCHANGE_C , false)
    ExchangeListCfg = ConfigManager.getTurntableExchangeDisplayCfg()
    -- ScoreExchangePageInfo.leftTime = 13444
    -- ScoreExchangePageInfo.surplusScore = 1000
    -- self:refreshPage(container);
end

function TurntableExchangePage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.TURNTABLE_EXCHANGE_S then
        local msg = Activity3_pb.TurntableExchangeRes()
		msg:ParseFromString(msgBuff)
        ScoreExchangePageInfo.goodsInfos = {}

        for i = 1, #msg.info do
            ScoreExchangePageInfo.goodsInfos[msg.info[i].id] = msg.info[i].exchangeTimes
        end

        ScoreExchangePageInfo.surplusScore = msg.credits
        ScoreExchangePageInfo.leftTime = msg.leftTime

        self:refreshPage(container);
        if ScoreExchangePageInfo.thisContainer and ScoreExchangePageInfo.lastScrollViewOffset then
            ScoreExchangePageInfo.thisContainer.mScrollView:setContentOffset(ScoreExchangePageInfo.lastScrollViewOffset ) 
        end
        if isTurntableSyncFlag then
           isTurntableSyncFlag = false
           TurntableExchangePage:requestServerData()
        end
    end
end

--同步转盘页面信息
function TurntableExchangePage:requestServerData()
    local msg = Activity3_pb.TurntableReq();
    msg.type = 0;
    common:sendPacket(HP_pb.TURNTABLE_C, msg, false);
end

function TurntableExchangePage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function TurntableExchangePage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function TurntableExchangePage:onExit(container)
	self:removePacket(container)
    NodeHelper:deleteScrollView(container);
    TimeCalculator:getInstance():removeTimeCalcultor(ScoreExchangePageInfo.activityTimerName)
    onUnload(thisPageName, container);
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local TurntableExchangePage = CommonPage.newSub(TurntableExchangePage, thisPageName, option);