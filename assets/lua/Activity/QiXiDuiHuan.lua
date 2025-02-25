
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'QiXiDuiHuan'
local Activity2_pb = require("Activity2_pb");
local HP_pb = require("HP_pb");
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require "Item.ItemManager"
local ActivityBasePage = require("Activity.ActivityBasePage")
require("SteriousShop");
require("Shop_pb");


local opcodes = {
	EXCHANGE_INFO_C 	= HP_pb.EXCHANGE_INFO_C,
	EXCHANGE_INFO_S		= HP_pb.EXCHANGE_INFO_S,
	DO_EXCHANGE_C		= HP_pb.DO_EXCHANGE_C,
	DO_EXCHANGE_S		= HP_pb.DO_EXCHANGE_S,
}
local thisContainer = nil
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1
local PageInfo = {
	timeLeft = 0,
	exchangeIdList = {},
	exchangeTimes = {},
}
local ExchangeActivityCfg = {}

local option = {
	ccbiFile = "Act_TimeLimitExchangeContent.ccbi",
	timerName = "QiXiDuiHuan_TimeLimit",
};


local QiXiDuiHuan = ActivityBasePage:new(option,thisPageName,opcodes)

function QiXiDuiHuan.onFunction(eventName,container)
	if eventName == "onWishing" then
		PageManager.pushPage("ExpeditionContributePage")
	elseif eventName == "onStageReward" then
		
	elseif eventName == "onRankReward" then
		PageManager.pushPage("ExpeditionRankPage")
	end
end

function QiXiDuiHuan:getPageInfo(ParentContainer)
	ExchangeActivityCfg = ConfigManager.getExchangeActivityItem()
	self:getActivityInfo()
end

function QiXiDuiHuan:onTimer(container)
	local timerName = option.timerName;
	local timeStr = '00:00:00'
	if TimeCalculator:getInstance():hasKey(timerName) then
		PageInfo.timeLeft = TimeCalculator:getInstance():getTimeLeft(timerName)
		if PageInfo.timeLeft > 0 then
			 timeStr = common:second2DateString(PageInfo.timeLeft , false)
		end
	end
	NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr})
end

function QiXiDuiHuan:refreshPage()
    self:rebuildAllItem();
end

function splitTiem(itemInfo)
	local items = {}
	for _, item in ipairs(common:split(itemInfo, ",")) do
		local _type, _id, _count = unpack(common:split(item, "_"));
		table.insert(items, {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		});
	end
	return items;
end

----------------scrollview-------------------------
local ExchangeItem = {
	ccbiFile = "Act_TimeLimitExchangeListContent.ccbi"
}


function ExchangeItem:onExchangeBtn(container)
    local itemInfo = ExchangeActivityCfg[self.id]
	local consumeCfg = splitTiem(itemInfo.consumeInfo)
	local awardCfg = splitTiem(itemInfo.awardInfo)
	local function check(info)
		local isCanBuy = false
		local resInfo = ResManagerForLua:getResInfoByTypeAndId(info.type, info.itemId, info.count)
		if resInfo then
			local itemInfo = UserItemManager:getUserItemByItemId(info.itemId)
			if itemInfo then
				if itemInfo.count >= info.count then
					isCanBuy = true
				end
			end
		end
		return isCanBuy
	end
	local isCanBuy = false
	if #consumeCfg >1 then
		isCanBuy = check(consumeCfg[1])
		if isCanBuy then
			isCanBuy = check(consumeCfg[2])
		end
	else
		isCanBuy = check(consumeCfg[1])
	end
	if isCanBuy then
        local costNum = consumeCfg[1].count
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(consumeCfg[1].type, consumeCfg[1].itemId, consumeCfg[1].count, true)
        local rewards = awardCfg[1]
		local exchangeCount = QiXiDuiHuan:getExchangeCount(self.id)	
		local remainTime = itemInfo.maxExchangeTime - exchangeCount
         PageManager.showCountTimesWithIconPage(rewards.type,rewards.itemId,consumeCfg[1].itemId,
	        function(count) 
	            return count*costNum
	        end,
	        function ( isBuy, count  )
	    	    if isBuy then
	    	    	print("count = ",count)
					local msg = Activity2_pb.DoExchange()
					msg.exchangeId = tostring(self.id)
					print("self.id = ",self.id)
					msg.exchangeTimes = count
					common:sendPacket(opcodes.DO_EXCHANGE_C , msg ,false)
	    	    end
	        end,true,remainTime, "@TLExchangeTitle","@TLExchangeNotEnough", resInfo.count)
	else
		MessageBoxPage:Msg_Box(common:getLanguageString('@NotEnoughExchangeItem'))
	end
end

function ExchangeItem:onFrame1( container ) 
    local itemInfo = ExchangeActivityCfg[self.id]
	local consumeCfg = splitTiem(itemInfo.consumeInfo)
    self:onShowItemInfo(container, consumeCfg[1], 1)
end

function ExchangeItem:onFrame2( container )
    local itemInfo = ExchangeActivityCfg[self.id]
	local consumeCfg = splitTiem(itemInfo.consumeInfo)
    self:onShowItemInfo(container, consumeCfg[2], 2)
end

function ExchangeItem:onFrame3( container )
    local itemInfo = ExchangeActivityCfg[self.id]
	local awardCfg = splitTiem(itemInfo.awardInfo)
    self:onShowItemInfo(container, awardCfg[1], 3)
end


function ExchangeItem:onShowItemInfo( container , itemInfo, rewardIndex )
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), itemInfo)
end


function ExchangeItem:onRefreshContent(ccbRoot)
    local itemInfo = ExchangeActivityCfg[self.id]
    local container = ccbRoot:getCCBFileNode()

	local consumeCfg = splitTiem(itemInfo.consumeInfo)
	local awardCfg = splitTiem(itemInfo.awardInfo)
	local canExchange = false
	local function fillItem(container,index,info)
		local canExchange = false
		local resInfo = ResManagerForLua:getResInfoByTypeAndId(info.type, info.itemId, info.count)
		if resInfo then
			local pic = {}
			local scale = {}
			local name = {}
			local frame = {}
			pic["mPic" .. index] = resInfo.icon
			scale["mPic" .. index] = resInfo.iconScale or 1
			NodeHelper:setSpriteImage(container, pic, scale)
			frame["mFrame" .. index] = resInfo.quality
			NodeHelper:setQualityFrames(container, frame)
			if index < 3 then
				local itemInfo = UserItemManager:getUserItemByItemId(info.itemId)
				if itemInfo then
					name["mName" .. index] = itemInfo.count .. '/' .. info.count
					NodeHelper:setStringForLabel(container, name)
					if itemInfo.count >= info.count then
						name["mName" .. index] = GameConfig.ColorMap.COLOR_WHITE
						NodeHelper:setColorForLabel(container,name)
						canExchange = true
					else
						name["mName" .. index] = GameConfig.ColorMap.COLOR_RED
						NodeHelper:setColorForLabel(container,name)
					end
				else
					name["mName" .. index] = 0 .. '/' .. info.count
					NodeHelper:setStringForLabel(container, name)
					name["mName" .. index] = GameConfig.ColorMap.COLOR_RED
					NodeHelper:setColorForLabel(container,name)
				end
			else
				NodeHelper:setSpriteImage(container, {mPic3 = resInfo.icon})
				NodeHelper:setStringForLabel(container, {mName3 = resInfo.name})
				NodeHelper:setStringForLabel(container, {mNum3 = "x" .. resInfo.count})
			end
		end
		return canExchange
	end
	if #consumeCfg >1 then
		NodeHelper:setNodesVisible(container,{mRewardNode1 = true,mRewardNode2 = true})
		canExchange = fillItem(container,1,consumeCfg[1])
		if canExchange then
			canExchange = fillItem(container,2,consumeCfg[2])
		else
			fillItem(container,2,consumeCfg[2])
		end
		fillItem(container,3,awardCfg[1])
	else
		NodeHelper:setNodesVisible(container,{mRewardNode1 = true,mRewardNode2 = false})
		canExchange = fillItem(container,1,consumeCfg[1])
		fillItem(container,3,awardCfg[1])
	end

	local exchangeCount = QiXiDuiHuan:getExchangeCount(self.id)	
	local remainTime = itemInfo.maxExchangeTime - exchangeCount
	NodeHelper:setStringForLabel(container, {mRemainingNum = remainTime})
	if remainTime == 0 then
		canExchange = false
	end
	NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mExchangeBtn"),canExchange)
end

function QiXiDuiHuan:getExchangeCount(index)
	local exchangeCount = 0
	if #PageInfo.exchangeTimes > 0 then
		for k,v in ipairs(PageInfo.exchangeIdList) do
			if v == tostring(index) then
				exchangeCount = PageInfo.exchangeTimes[k]
			end
		end
	end
	if not exchangeCount then exchangeCount = 0 end
	return exchangeCount
end

function QiXiDuiHuan:rebuildAllItem()
    self:clearAllItem();
	self:buildItem();
end

function QiXiDuiHuan:clearAllItem()
	self.container.mScrollView:removeAllCell()
end

function QiXiDuiHuan:buildItem()
    local size = #ExchangeActivityCfg
    NodeHelper:buildCellScrollView(self.container.mScrollView,size, ExchangeItem.ccbiFile, ExchangeItem);
end

function QiXiDuiHuan:getActivityInfo()
	common:sendEmptyPacket(opcodes.EXCHANGE_INFO_C, msg)
end
function QiXiDuiHuan:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.EXCHANGE_INFO_S then
		local msg = Activity2_pb.HPExchangeInfoRet()
		msg:ParseFromString(msgBuff)
		self:handleAcitivityInfo( msg )
	end
end
function QiXiDuiHuan:handleAcitivityInfo(msg)
	PageInfo.timeLeft = msg.lastCount
	if PageInfo.timeLeft > 0 and not TimeCalculator:getInstance():hasKey(option.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(option.timerName, PageInfo.timeLeft);
	end
	PageInfo.exchangeIdList = msg.exchangeIdList
	PageInfo.exchangeTimes = msg.exchangeTimes
	self:refreshPage()
	-- if PageInfo.curOffset ~= nil and thisContainer then
		-- thisContainer.mScrollView:setContentOffset(	PageInfo.curOffset ) 
	-- end
end
function QiXiDuiHuan:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function QiXiDuiHuan:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

return QiXiDuiHuan
