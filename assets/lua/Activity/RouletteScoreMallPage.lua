
----------------------------- local data -----------------------------------------
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local Activity_pb = require("Activity_pb")
local PageName = "RouletteScoreMallPage"
local menuItemBtns = {} --存储按钮
local scores = {} --存储按钮对应的状态
local updateMark = false --刷新状态
local option = {
	ccbiFile = "Act_InsaneTurnTablePopUp.ccbi",
	handlerMap = {
		onClose = "onClose"
	},
	opcode = {
		ROULETTE_INFO_S = HP_pb.ROULETTE_INFO_S,
		ROULETTE_CREDITS_EXCHANGE_S = HP_pb.ROULETTE_CREDITS_EXCHANGE_S,
	},
}
local pageInfo = {
	curCredits  	= 0, 									-- 当前积分
	shopRewards    	= ConfigManager.getRouletteShopCfg(),   -- 积分商城物品
}
local RouletteScoreMallPage = CommonPage.new(PageName, option)

-------------------------------- logic methods ------------------------------------
function RouletteScoreMallPage.refreshPage( container )
	NodeHelper:setStringForLabel(container, {mIntegralNum = pageInfo.curCredits})
	NodeHelper:setLabelOneByOne(container,"mCurrentIntegral","mIntegralNum")
	RouletteScoreMallPage.rebuildAllItem(container)
end

-------------------------------- state methods ------------------------------------
function RouletteScoreMallPage.onEnter(container)
	RouletteScoreMallPage.registerPacket(container)
	NodeHelper:initScrollView(container, "mContent", 3)
	RouletteScoreMallPage.rebuildAllItem(container)
	common:sendEmptyPacket(HP_pb.ROULETTE_INFO_C)
end

function RouletteScoreMallPage.onExit(container)
	RouletteScoreMallPage.removePacket(container)
end

----------------------scrollview item-----------------------------
local RouletteItem = {
	ccbiFile = "Act_InsaneTurnTableContent.ccbi",
	params = {
		mainNode = "mRewardNode",
        countNode = "mNum",
        nameNode = "mName",
        frameNode = "mFeet",
        picNode = "mRewardPic",
        startIndex = 1,
	}
}

function RouletteItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		RouletteItem.onRefreshItemView(container)
	elseif eventName == "onReceive" then
		RouletteItem.onReceive(container)
	elseif eventName:sub(1,6) == "onFeet" then 
		RouletteItem.showTips(container,eventName)
	end		
end

function RouletteItem.onRefreshItemView(container)
	local index = container:getItemDate().mID
	local itemCfg = pageInfo.shopRewards[index].items
	-- 是否可兑换
	NodeHelper:setMenuItemEnabled(container, "mReceive", pageInfo.curCredits>=pageInfo.shopRewards[index].score)
	local item = container:getVarMenuItemImage("mReceive");
	menuItemBtns[#menuItemBtns+1] = item
	scores[#scores+1] = pageInfo.shopRewards[index].score

	NodeHelper:fillRewardItemWithParams(container, itemCfg, 3, RouletteItem.params)
	NodeHelper:setStringForLabel(container, {mIntegralNum = pageInfo.shopRewards[index].score})
end

function RouletteItem.updateItemButtonState(container)
	NodeHelper:setStringForLabel(container, {mIntegralNum = pageInfo.curCredits})
	NodeHelper:setLabelOneByOne(container,"mCurrentIntegral","mIntegralNum")
	for i=1, #pageInfo.shopRewards do
		local btn = menuItemBtns[i]--container:getChildByTag(tonumber(i))
		local score = scores[i]
		if btn then
			btn:setEnabled(false)
			if pageInfo.curCredits>=score then
				btn:setEnabled(true)
			end
		end
	end
end

function RouletteItem.onReceive( container )
	local index = container:getItemDate().mID
	local msg = Activity_pb.HPRouletteCreditsExchange();
	msg.cfgId = tonumber(index)
	common:sendPacket(HP_pb.ROULETTE_CREDITS_EXCHANGE_C, msg)
end

function RouletteItem.showTips( container,eventName )
	local index = container:getItemDate().mID
	local itemCfg = pageInfo.shopRewards[index].items
	local rewardIndex = tonumber(eventName:sub(7));
	GameUtil:showTip(container:getVarNode('mFeet' .. rewardIndex), itemCfg[rewardIndex])
end

----------------scrollview-------------------------
function RouletteScoreMallPage.rebuildAllItem(container)
	RouletteScoreMallPage.clearAllItem(container);
	RouletteScoreMallPage.buildItem(container);
end

function RouletteScoreMallPage.clearAllItem(container)
	menuItemBtns = {}
	NodeHelper:clearScrollView(container);
end

function RouletteScoreMallPage.buildItem(container)
	NodeHelper:buildScrollView(container, #pageInfo.shopRewards, RouletteItem.ccbiFile, RouletteItem.onFunction);
end

-------------------------------- click methods -------------------------------------
function RouletteScoreMallPage.onClose(container )
	updateMark = false
	PageManager.popPage(PageName)
end

-------------------------------- packet handler ------------------------------------
function RouletteScoreMallPage.onReceivePacket( container )
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.ROULETTE_INFO_S then
    	if updateMark then return end ---只有进入创建一次
		updateMark = true

    	local msg = Activity_pb.HPRouletteInfoRet();
		msg:ParseFromString(msgBuff)
    	pageInfo.curCredits = msg.curCredits
    	RouletteScoreMallPage.refreshPage(container)
    elseif opcode == HP_pb.ROULETTE_CREDITS_EXCHANGE_S then
    	local msg = Activity_pb.HPRouletteCreditsExchangeRet();
		msg:ParseFromString(msgBuff)
		pageInfo.curCredits = msg.curCredits
		PageManager.refreshPage("RoulettePage")
		RouletteItem.updateItemButtonState(container)
		--RouletteScoreMallPage.refreshPage(container)
    end
end