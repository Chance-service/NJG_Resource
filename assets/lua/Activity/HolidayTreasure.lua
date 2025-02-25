
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NewbieGuideManager = require("NewbieGuideManager")
local NodeHelper = require("NodeHelper");
local thisPageName = "HolidayTreasure"

local COUNT_TREASURE_MAX = 10;

local opcodes = {
	HOLIDAY_TREASURE_C	= HP_pb.HOLIDAY_TREASURE_C,
	HOLIDAY_TREASURE_S	= HP_pb.HOLIDAY_TREASURE_S
};
local TreasureId = {
	Luxury 		= 1,
	Celebrate 	= 2
};

local ActivityItem = {
	ccbiFile = "Act_TimeLimitMasterTreasureListContent.ccbi"
}

local thisActivityInfo = {
	id				= 10,
	remainTime 		= 0,
	rewardCfg		= {}
};
thisActivityInfo.itemCfg = ActivityConfig[thisActivityInfo.id]["items"] or {};



function ActivityItem:onRefreshContent(ccbRoot)
    local id = self.id
    local container = ccbRoot:getCCBFileNode()
	local rewardId = thisActivityInfo.itemCfg[id];

	if rewardId then
		local rewardCfg = ConfigManager.getRewardById(rewardId);
		NodeHelper:fillRewardItem(container,rewardCfg,1)
	end

	NodeHelper:setStringForLabel(container, {mHolidayHighExchange = common:getLanguageString("@Holiday"..(id*2 - 1)),
											mHighPackageContent = common:getLanguageString("@Holiday"..(id*2))})	
end


function ActivityItem:onFrame1( container )
    local rewardId = thisActivityInfo.itemCfg[self.id];
	if rewardId then
		local rewardCfg = ConfigManager.getRewardById(rewardId);
		GameUtil:showTip(container:getVarNode('mFrame1'), rewardCfg[1])	
	end    
	
end


function ActivityItem:onBtn( container )
	PageManager.changePage("ShopControlPage");
end


local option = {
	ccbiFile = "Act_TimeLimitMasterTreasureContent.ccbi",
	timerName = "Activity_" .. thisActivityInfo.id,
};



----------------- local data -----------------
local ActivityBasePage = require("Activity.ActivityBasePage")
local HolidayTreasureBase = ActivityBasePage:new(option,thisPageName,opcodes)

-----------------------------------------------
--HolidayTreasureBase页面中的事件处理
----------------------------------------------
function HolidayTreasureBase:getPageInfo(ParentContainer)
	self:getActivityInfo(ParentContainer);
	self:rebuildAllItem()
end
----------------------------------------------------------------
function HolidayTreasureBase:onTimer(container)
	local timerName = option.timerName;
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
	if remainTime + 1 > thisActivityInfo.remainTime then
		return;
	end

	thisActivityInfo.remainTime = math.max(remainTime, 0);
	local timeStr = common:second2DateString(thisActivityInfo.remainTime, false);
	NodeHelper:setStringForLabel(container, {mTanabataCD = timeStr});
end

function HolidayTreasureBase:clearPage(container)
	NodeHelper:setStringForLabel(container, {
		mCD	= ""
	});
end

function HolidayTreasureBase:getActivityInfo(container)
	local msg = Activity_pb.HPHolidayTreasure();
	common:sendPacket(opcodes.HOLIDAY_TREASURE_C, msg);
end

function HolidayTreasureBase:rebuildAllItem()
    self:clearAllItem();
	self:buildItem();
end

function HolidayTreasureBase:clearAllItem()
	self.container.mScrollView:removeAllCell()
end

function HolidayTreasureBase:buildItem()
    NodeHelper:buildCellScrollView(self.container.mScrollView, 2 , ActivityItem.ccbiFile, ActivityItem);
end

function HolidayTreasureBase:refreshPage(container)
	if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(option.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(option.timerName, thisActivityInfo.remainTime);
	end
end

function HolidayTreasureBase:showMenuSelected(container)
	local menu2TreasureId = {
		mLuxuryChest 	= TreasureId.Luxury,
		mCelebrateChest	= TreasureId.Celebrate
	};
	local selectedTb = {};
	for name, treasureId in pairs(menu2TreasureId) do
		selectedTb[name] = treasureId == thisActivityInfo.treasureId;
	end
	NodeHelper:setMenuItemSelected(container, selectedTb);
end

function HolidayTreasureBase:viewPackage()
	PackagePage_showItems();
end

function HolidayTreasureBase:goBattle()
	PageManager.showFightPage();
end

function HolidayTreasureBase:goShop()
	PageManager.changePage("MarketPage");
end

function HolidayTreasureBase:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();

	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			self:showExchangeItem(container);
		end
	end
end

--回包处理
function HolidayTreasureBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.HOLIDAY_TREASURE_S then
		local msg = Activity_pb.HPHolidayTreasureRet();
		msg:ParseFromString(msgBuff);
		
		thisActivityInfo.remainTime = msg.leftTimes;

		self:refreshPage(container);
		return;
	end
end

-------------------------------------------------------------------------
-- local CommonPage = require("CommonPage");
-- HolidayTreasure = CommonPage.newSub(HolidayTreasureBase, thisPageName, option);
return HolidayTreasureBase