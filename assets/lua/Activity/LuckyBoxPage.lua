

----------------------------- local data -----------------------------------------
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local Activity_pb = require("Activity_pb")
local PageName = "LuckyBoxPage"
local option = {
	ccbiFile = "Act_LuckyTreasurePage.ccbi",
	handlerMap = {
		onReturnButton 		= "onBack",
		onHelp 				= "onHelp",
		onClose 			= "onClose",
	},
	opcode = {
		LUCKBOX_INFO_S = HP_pb.LUCKBOX_INFO_S;
		LUCKBOX_EXCHANGE_S = HP_pb.LUCKBOX_EXCHANGE_S;
	},
}
for i=1,3 do
	option.handlerMap["onGiftFrame" .. i] = "onFrame"
	option.handlerMap["onGiftReceive"..i] = "onExchange"
end
local pageInfo = {
	itemsCfg 			= ConfigManager.getLuckyBoxCfg(),
	itemsCfgShow 		= {}, -- 用来展示的物品
	canExhangeCfgId 	= 0,
	rewardParams = {
        mainNode = "mGiftNode",
        countNode = "mGiftNum",
        nameNode = "mName",
        frameNode = "mGiftFrame",
        picNode = "mGiftPic",
        startIndex = 1,
	},
}
local thisActivityInfo = {
	id = 31,
	remainTime = 0,
}
thisActivityInfo.timeKey = "Activity_" .. thisActivityInfo.id 
local LuckyBoxPage = CommonPage.new(PageName, option)
--------------------------- logic methods -------------------------------------------
function LuckyBoxPage.onTimer( container )
	if container==nil then return end
	if (thisActivityInfo.remainTime~=nil and thisActivityInfo.remainTime<= 0)
		or (TimeCalculator:getInstance():hasKey(thisActivityInfo.timeKey) 
		and TimeCalculator:getInstance():getTimeLeft(thisActivityInfo.timeKey)<=0) then
		NodeHelper:setStringForLabel(container, {mCD = common:getLanguageString("@ActivityRebateClose")})
		return
	end
	if not TimeCalculator:getInstance():hasKey(thisActivityInfo.timeKey) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(thisActivityInfo.timeKey);

	remainTime = math.max(remainTime, 0);
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, {mCD = timeStr})
end

function LuckyBoxPage.refreshPage( container )
	if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(thisActivityInfo.timeKey) then
		TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timeKey, thisActivityInfo.remainTime)
	end
	if not common:table_isEmpty(pageInfo.itemsCfgShow) then
		NodeHelper:fillRewardItemWithParams(container, pageInfo.itemsCfgShow, #pageInfo.itemsCfgShow, pageInfo.rewardParams)
	end
	if pageInfo.canExhangeCfgId~=nil and tonumber(pageInfo.canExhangeCfgId)==0 then
	    ActivityInfo:decreaseReward(thisActivityInfo.id)
    end
	for i=1,3 do
		if pageInfo.canExhangeCfgId~=0 then
			NodeHelper:setMenuItemEnabled(container, "mRewardBtn"..i, pageInfo.canExhangeCfgId==i)	
		else
			NodeHelper:setMenuItemEnabled(container, "mRewardBtn"..i, false)	
		end
	end
end

function LuckyBoxPage.setShowCfg(itemCfgId)
	assert(itemCfgId~=nil, "LuckyBoxPage.setShowCfg itemCfgId is nil")
	pageInfo.itemsCfgShow = {}
	for i=1,#itemCfgId do
		local index = itemCfgId[i]
		assert(pageInfo.itemsCfg[index]~=nil, "LuckyBoxPage.setShowCfg itemsCfg"..index.."is nil")
		table.insert(pageInfo.itemsCfgShow,pageInfo.itemsCfg[index].items)
	end
end
--------------------------- state methods -------------------------------------------
function LuckyBoxPage.onEnter( container )
	NodeHelper:setLabelOneByOne(container,"mGoldChestExplain","mGoldChestReward",5)
	NodeHelper:setLabelOneByOne(container,"mSilverChestExplain","mSilverChestReward",5)
	NodeHelper:setLabelOneByOne(container,"mCopperChestExplain","mCopperChestReward",5)
	NodeHelper:setLabelOneByOne(container,"mActivityDays","mCD",5)
    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
       NodeHelper:MoveAndScaleNode(container,{mLuckyTreasureTitle = common:getLanguageString("@LuckyTreasureTitle1")},0,0.8);
    end
	LuckyBoxPage.registerPacket(container)
	common:sendEmptyPacket(HP_pb.LUCKBOX_INFO_C)
end

function LuckyBoxPage.onExit( container )
	LuckyBoxPage.removePacket(container)
end

function LuckyBoxPage.onExecute( container )
	LuckyBoxPage.onTimer( container )
end
---------------------------- click methods -------------------------------------------
function LuckyBoxPage.onBack( container )
	PageManager.changePage("ActivityPage")
end

function LuckyBoxPage.onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_LUCKYBOX)
end

function LuckyBoxPage.onFrame( container, eventName )
	local index = tonumber(eventName:sub(12))
	GameUtil:showTip(container:getVarNode('mGiftFrame' .. index), pageInfo.itemsCfgShow[index])
end

function LuckyBoxPage.onExchange( container,eventName )
	local index = tonumber(eventName:sub(14))
	local msg = Activity_pb.HPLuckBoxExchange()
	msg.cfgId = tonumber(index);
	common:sendPacket(HP_pb.LUCKBOX_EXCHANGE_C, msg)
end

function LuckyBoxPage.onClose( container )
    PageManager.refreshPage("ActivityPage")
	PageManager.popPage(PageName)
end
---------------------------- packet methods --------------------------------------------
function LuckyBoxPage.onReceivePacket( container )
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.LUCKBOX_INFO_S then
    	local msg = Activity_pb.HPLuckyBoxRet()
		msg:ParseFromString(msgBuff)
		thisActivityInfo.remainTime = msg.leftTime or 0
		pageInfo.canExhangeCfgId 	= msg.cfgId
		local achieveRewardsCfg = msg.itemCfgId
		if achieveRewardsCfg[3]~=nil then
			achieveRewardsCfg[3] = 3
		end
		LuckyBoxPage.setShowCfg(achieveRewardsCfg)
		LuckyBoxPage.refreshPage(container)
	elseif opcode == HP_pb.LUCKBOX_EXCHANGE_S then
		local msg = Activity_pb.HPLuckBoxExchangeRet()
		msg:ParseFromString(msgBuff)
		thisActivityInfo.remainTime = msg.leftTime or 0
		pageInfo.canExhangeCfgId = 0
		LuckyBoxPage.refreshPage(container)
	end
end
    	