
local HP_pb = require "HP_pb"
local Activity2_pb = require("Activity2_pb")
local thisPageName = "NewSnowScoreExchangePage"
local NewSnowScoreExchangePage = {}
local CatchFish_pb = require("CatchFish_pb")
local areadyGetIds = {}
local FishInfoCfg = nil
local option = {
	ccbiFile = "Act_LoadTreasureTablePopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
		onConfirmation = "onConfirmation",
	},
    opcodes = {
	    PRINCE_DEVILS_SCORE_EXCHANGE_C = HP_pb.PRINCE_DEVILS_SCORE_EXCHANGE_C,
	    PRINCE_DEVILS_SCORE_EXCHANGE_S = HP_pb.PRINCE_DEVILS_SCORE_EXCHANGE_S,
        PRINCE_DEVILS_SCORE_PANEL_C = HP_pb.PRINCE_DEVILS_SCORE_PANEL_C,
        PRINCE_DEVILS_SCORE_PANEL_S = HP_pb.PRINCE_DEVILS_SCORE_PANEL_S,
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
        local ItemInfo = ScoreExchangePageInfo.goodsInfos[contentId];
        local reward = splitTiem(ItemInfo.goodsId)[1];
        GameUtil:showTip(container:getVarNode("mRewardPic1"), reward)
    elseif eventName == "onReceive" then
        local contentId = container:getItemDate().mID;
        local ItemInfo = ScoreExchangePageInfo.goodsInfos[contentId];
        if ItemInfo.sumCount-ItemInfo.exchangeCount < 1 then
            MessageBoxPage:Msg_Box_Lan("@CountNotEnough")
            return 
        end
        local rewards = splitTiem(ItemInfo.goodsId)[1]
        local costNum = ItemInfo.singleCostScore
         PageManager.showCountTimesWithIconPage(rewards.type,rewards.itemId,10001,
	        function(count) 
	            return count*costNum,ScoreExchangePageInfo.surplusScore >= count*costNum
	        end,
	        function ( isBuy, count  )
	    	    if isBuy then
				    local msg = Activity2_pb.HPPrinceDevilsScoreExchangeReq();
				    msg.count = count;
				    msg.id = ItemInfo.id
				    common:sendPacket(HP_pb.PRINCE_DEVILS_SCORE_EXCHANGE_C, msg, false);
                    ScoreExchangePageInfo.lastScrollViewOffset = ScoreExchangePageInfo.thisContainer.mScrollView:getContentOffset()

	    	    end
	        end,true,ItemInfo.sumCount-ItemInfo.exchangeCount, "@LoadTreasureTableTitle","@pointNotEnough", ScoreExchangePageInfo.surplusScore)	
	end	
end
function ExchangeContent.onRefreshItemView(container)
    local lb2Str = {};
    local index = container:getItemDate().mID
    local ItemInfo = ScoreExchangePageInfo.goodsInfos[index];
    local sprite2Img = {}
    local rewards = splitTiem(ItemInfo.goodsId)[1]
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewards.type, rewards.itemId, rewards.count);

    lb2Str["mIntegralNum"] = ItemInfo.singleCostScore
    lb2Str["mName1"] = resInfo.name
    lb2Str["mLimitNum"] = ItemInfo.exchangeCount.."/"..ItemInfo.sumCount
    lb2Str["mNum1"] = rewards.count
    NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, { mRewardPic1 = resInfo.icon}, {mRewardPic1 = resInfo.iconScale});
	NodeHelper:setQualityFrames(container, { mFeet1 = resInfo.quality});
end

-----------------ExchangeContent-----------------------------

function NewSnowScoreExchangePage:onEnter(container)

    NodeHelper:initScrollView(container, "mContent", 12);
    ScoreExchangePageInfo.lastScrollViewOffset = nil
    ScoreExchangePageInfo.thisContainer = container
    self:registerPacket(container);
    self:getActivityInfo();
end

----------------------------------------------------------------
function NewSnowScoreExchangePage:refreshPage(container)

    if ScoreExchangePageInfo.leftTime > 0 and not TimeCalculator:getInstance():hasKey(ScoreExchangePageInfo.activityTimerName) then
        NodeHelper:setNodesVisible(container,{mMasterNode = true})
        TimeCalculator:getInstance():createTimeCalcultor(ScoreExchangePageInfo.activityTimerName, ScoreExchangePageInfo.leftTime)
    end

    NodeHelper:setStringForLabel( container, { mIntegralNum= ScoreExchangePageInfo.surplusScore} )
    self:rebuildAllItem(container)
end


function NewSnowScoreExchangePage:onExecute( container )
    self:onActivityTimer( container )
end

function NewSnowScoreExchangePage:onActivityTimer( container )
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


function NewSnowScoreExchangePage:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function NewSnowScoreExchangePage:buildItem(container)
    NodeHelper:buildScrollView(container,#ScoreExchangePageInfo.goodsInfos, ExchangeContent.ccbiFile, ExchangeContent.onFunction);
end

function NewSnowScoreExchangePage:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end
----------------click event------------------------
function NewSnowScoreExchangePage:onClose(container)
    PageManager.refreshPage("NewSnowTreasurePage", tostring(ScoreExchangePageInfo.surplusScore))
	PageManager.popPage(thisPageName)
end

function NewSnowScoreExchangePage:onConfirmation(container)
     PageManager.popPage(thisPageName)
end

function NewSnowScoreExchangePage:getActivityInfo()
    common:sendEmptyPacket(HP_pb.PRINCE_DEVILS_SCORE_PANEL_C , true)
end

function NewSnowScoreExchangePage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.PRINCE_DEVILS_SCORE_PANEL_S then
        local msg = Activity2_pb.HPPrinceDevilsScoreExchangeRes()
		msg:ParseFromString(msgBuff)
        ScoreExchangePageInfo.goodsInfos = msg.goodsInfos
        ScoreExchangePageInfo.surplusScore = msg.surplusScore
        ScoreExchangePageInfo.leftTime = msg.panelCloseTime
        print("ScoreExchangePageInfo.leftTime =",ScoreExchangePageInfo.leftTime)
        self:refreshPage(container);
        if ScoreExchangePageInfo.thisContainer and ScoreExchangePageInfo.lastScrollViewOffset then
            ScoreExchangePageInfo.thisContainer.mScrollView:setContentOffset(ScoreExchangePageInfo.lastScrollViewOffset ) 
        end
        
    end
end

function NewSnowScoreExchangePage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function NewSnowScoreExchangePage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function NewSnowScoreExchangePage:onExit(container)
	self:removePacket(container)
    NodeHelper:deleteScrollView(container);
    TimeCalculator:getInstance():removeTimeCalcultor(ScoreExchangePageInfo.activityTimerName)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local NewSnowScoreExchangePage = CommonPage.newSub(NewSnowScoreExchangePage, thisPageName, option);