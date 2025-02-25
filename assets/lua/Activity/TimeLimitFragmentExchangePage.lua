
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity2_pb = require("Activity2_pb")
local UserItemManager = require("Item.UserItemManager")
local HP_pb = require("HP_pb");
local thisPageName = 'TimeLimitFragmentExchangePage'
local TimeLimitFragmentExchangePage = {}
local SaveSelectObject = nil
local SaveSelectDataCfg = nil
local ConstExchaneItemId = 106011
local NeedConsumeGold = 0--需要消耗的元宝
----------------scrollview-------------------------
local ExchangeChipItems = {
	ccbiFile = "Act_TimeLimitMercenaryChipListContent.ccbi"
}
local thisActivityInfo = {
	selectType = 0,
	gotAwardCfgId = {}
}

local baseScaleHeight = 0
local baseScrollHeight = 0

local fragmentType = {
	common = 1,--普通
	high = 2--高级
}

local opcodes = {
	SYNC_FRAGMENT_EXCHANGE_C = HP_pb.SYNC_FRAGMENT_EXCHANGE_C,
	SYNC_FRAGMENT_EXCHANGE_S = HP_pb.SYNC_FRAGMENT_EXCHANGE_S,
	FRAGMENT_EXCHANGE_C 	 = HP_pb.FRAGMENT_EXCHANGE_C,
	FRAGMENT_EXCHANGE_S		 = HP_pb.FRAGMENT_EXCHANGE_S,
};

local clientToSeverInfo = {
	id = nil,--配表ID
	fragmentId = nil,--碎片ID
	multiple = nil--奖励的倍数
}

TimeLimitFragmentExchangePage.timerName = "syncServerTimes";
TimeLimitFragmentExchangePage.RemainTime = -1;

function ExchangeChipItems.onFunction(eventName, container)
	if eventName == "onBtn" then
		TimeLimitFragmentExchangePage:onBtn(container);
	elseif eventName == "onFrame1" then
		TimeLimitFragmentExchangePage:onFrame1(container);
	elseif eventName == "onFrame2" then
		TimeLimitFragmentExchangePage:onFrame2(container);
	elseif eventName == "onFrame3" then
		TimeLimitFragmentExchangePage:onFrame3(container);
	elseif eventName == "luaRefreshItemView" then
		ExchangeChipItems.onRefreshItemView(container);
	end
end

function ExchangeChipItems.onRefreshItemView(container)
	local index = container:getItemDate().mID;
	-- NodeHelper:setStringForLabel(container,{mDiscountTxt = thisActivityInfo.activityCfg[index].id})  --@ActTLNewDiscountTitleTxt1
	if fragmentType.common == thisActivityInfo.activityCfg[index].type then
		NodeHelper:setStringForLabel(container,{mDiscountTxt = common:getLanguageString("@ActTLNewDiscountTitleTxt"..fragmentType.common)})
	else
		NodeHelper:setStringForLabel(container,{mDiscountTxt = common:getLanguageString("@ActTLNewDiscountTitleTxt"..fragmentType.high)})
	end
	
	local cfg = thisActivityInfo.activityCfg[index].costItem[1]
	local lb2Str = {};
    local sprite2Img = {};
    local scaleMap = {}
    local menu2Quality = {};
    --设置元宝的信息
    TimeLimitFragmentExchangePage:onChangeUIData(container,2,cfg)

    --设置道具的信息
    cfg = thisActivityInfo.activityCfg[index].rewardFragement[1]
    TimeLimitFragmentExchangePage:onChangeUIData(container,3,cfg)
    NodeHelper:setMenuItemEnabled( container, "mBtn", false )
end

--修改item的信息  index 1代表 第一个按钮  2 第二个按钮   3  第三个按钮
function TimeLimitFragmentExchangePage:onChangeUIData(container,index,cfg)
	local lb2Str = {};
    local sprite2Img = {};
    local scaleMap = {}
    local menu2Quality = {};
	local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
    sprite2Img["mPic" .. index]         = resInfo.icon;
    sprite2Img["mFrameShade" .. index]   = NodeHelper:getImageBgByQuality(resInfo.quality);
    lb2Str["mNum" .. index]          = "x" .. GameUtil:formatNumber( cfg.count );
    menu2Quality["mFrame" .. index]     = resInfo.quality
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setStringForLabel(container, lb2Str);
    if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
        NodeHelper:setNodeScale(container, "mPic" .. index, 0.84, 0.84)
    else
        NodeHelper:setNodeScale(container, "mPic" .. index, 1, 1)
    end
end

function TimeLimitFragmentExchangePage:onEnter(ParentContainer)
	thisActivityInfo.activityCfg = ConfigManager.getFragmentExchangeCfg()
	local container = ScriptContentBase:create("Act_TimeLimitMercenaryChipContent.ccbi")
	self.container = container
	self:registerPacket(ParentContainer);
	NodeHelper:initScrollView(self.container, "mContent", 7)
	self.container:registerFunctionHandler(TimeLimitFragmentExchangePage.onFunction)
	NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	NodeHelper:autoAdjustResizeScale9Sprite(mScale9Sprite)
	if mScale9Sprite then
		baseScaleHeight = mScale9Sprite:getContentSize().height
	end
	if container.mScrollView then
		NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
	end
	if container.mScrollView then
		baseScrollHeight = container.mScrollView:getViewSize().height
	end

	local maxHeight = #thisActivityInfo.activityCfg * 170 + 200
	if baseScaleHeight > 0 and baseScaleHeight > maxHeight then
		baseScaleHeight = maxHeight
		local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
		local size = mScale9Sprite:getContentSize()
		size.height = baseScaleHeight
		mScale9Sprite:setContentSize(size)
		container.mScrollView:setTouchEnabled(false)
		container.mScrollView:setBounceable(false)		
	end
	local maxScrollHeight = #thisActivityInfo.activityCfg * 170 + 30
	if baseScrollHeight > 0 and baseScrollHeight > maxScrollHeight then
		baseScrollHeight = maxScrollHeight
		local size = container.mScrollView:getViewSize()
		size.height = baseScrollHeight
		container.mScrollView:setViewSize(size)
	end	

	common:sendEmptyPacket(opcodes.SYNC_FRAGMENT_EXCHANGE_C , true)
	ActivityInfo.changeActivityNotice(102)--隐藏红点
	self:refreshPage()
	return self.container
end

function TimeLimitFragmentExchangePage.onFunction(eventName,container)
	if eventName == "onChange" then
		TimeLimitFragmentExchangePage:onChange(container)
	elseif eventName == "luaRefreshItemView" then
		TimeLimitFragmentExchangePage.onRefreshItemView(container);
	end
end

function TimeLimitFragmentExchangePage:refreshPage()	
	self:rebuildAllItem()
end

function TimeLimitFragmentExchangePage:onExecute(ParentContainer)
	self:onTimer(self.container)
end

--计算倒计时
function TimeLimitFragmentExchangePage:onTimer(container)
	if not TimeCalculator:getInstance():hasKey(self.timerName) then
	    if TimeLimitFragmentExchangePage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif TimeLimitFragmentExchangePage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime + 1 > TimeLimitFragmentExchangePage.RemainTime then
		return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { mTanabataCD = timeStr});
end

function TimeLimitFragmentExchangePage.onRefreshItemView(container)
	
end

function TimeLimitFragmentExchangePage:rebuildAllItem()
	self:clearAllItem();
	self:buildItem();
end

function TimeLimitFragmentExchangePage:clearAllItem()
	NodeHelper:clearScrollView(self.container)
end

function TimeLimitFragmentExchangePage:buildItem()
    local maxSize = #thisActivityInfo.activityCfg	
    NodeHelper:buildScrollView(self.container,maxSize, ExchangeChipItems.ccbiFile, ExchangeChipItems.onFunction);
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
    
    local num3 = UserItemManager:getCountByItemId(ConstExchaneItemId)
    NodeHelper:setStringForLabel(self.container,{mNum3 = num3})	
end

--向服务器请求兑换
function TimeLimitFragmentExchangePage:onBtn(container)
	self:getActivityInfo();
end

function TimeLimitFragmentExchangePage:onFrame1(container)
	local index = container:getItemDate().mID;
	SaveSelectObject = container
	PageManager.pushPage("FragmentDetailedListPage");
	FragmentDetailedListPage_setAlreadySelItem(thisActivityInfo.activityCfg[index]);
end

function TimeLimitFragmentExchangePage:onFrame2(container)
	CCLuaLog("-----------click pic onFrame2 ------------");
end

function TimeLimitFragmentExchangePage:onFrame3(container)
	local index = container:getItemDate().mID;
	 GameUtil:showTip(container, thisActivityInfo.activityCfg[index].rewardFragement[1])
end

function TimeLimitFragmentExchangePage:onChange(container)
	local KingPowerScoreExchangePage = require("KingPowerScoreExchangePage")
    KingPowerScoreExchangePage:onloadCcbiFile(2)
	PageManager.pushPage("KingPowerScoreExchangePage")
end

--选择完以后改变信息
function TimeLimitFragmentExchangePage:onChangeContainerInfo(curcount)
	local index = SaveSelectObject:getItemDate().mID;
	local mCount = thisActivityInfo.activityCfg[index].costItem[1].count
	NeedConsumeGold = (curcount / SaveSelectDataCfg.needCount) * mCount
	local rCount = thisActivityInfo.activityCfg[index].rewardFragement[1].count

	--赋值选择的信息
	clientToSeverInfo.id = thisActivityInfo.activityCfg[index].id
	clientToSeverInfo.fragmentId = SaveSelectDataCfg.itemId
	local rewardNum = (curcount / SaveSelectDataCfg.needCount) * rCount
	clientToSeverInfo.multiple = curcount

	TimeLimitFragmentExchangePage:onChangeUIData(SaveSelectObject,1,SaveSelectDataCfg)
	--改变数量
	NodeHelper:setStringForLabel(SaveSelectObject, { mNum1 = "x" .. curcount });
	NodeHelper:setStringForLabel(SaveSelectObject, { mNum2 = "x" .. NeedConsumeGold });
	NodeHelper:setStringForLabel(SaveSelectObject, { mNum3 = "x" .. rewardNum });
	-- if UserInfo.playerInfo.gold >= money then
		NodeHelper:setMenuItemEnabled(SaveSelectObject, "mBtn", true )
	-- else
		-- NodeHelper:setMenuItemEnabled(SaveSelectObject, "mBtn", false )
	-- end 
end

function TimeLimitFragmentExchangePage_onCallbackCurCount(flag, curcount)
    if curcount then
        TimeLimitFragmentExchangePage:onChangeContainerInfo(curcount);
        PageManager.popPage("FragmentDetailedListPage")
    end
end

function TimeLimitFragmentExchangePage_onSelectData(cfg)
    SaveSelectDataCfg = cfg
end

function TimeLimitFragmentExchangePage:getActivityInfo()
	if NeedConsumeGold > UserInfo.playerInfo.gold then
		MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14")
		return
	end
	local index = SaveSelectObject:getItemDate().mID;
	local fragmentList = thisActivityInfo.activityCfg[index].costFragment;
	local fragment = "";
	for i = 1, #fragmentList do
		if fragmentList[i].itemId == clientToSeverInfo.fragmentId then
			fragment = fragmentList[i].type.."_"..fragmentList[i].itemId.."_"..fragmentList[i].count;
			break;
		end
	end
	local msg = Activity2_pb.FragmentExchangeReq();
	msg.id = tonumber(clientToSeverInfo.id);--配表ID
	msg.fragment = fragment;--碎片信息
	msg.multiple = tonumber(clientToSeverInfo.multiple);--最后兑换的个数
	common:sendPacket(opcodes.FRAGMENT_EXCHANGE_C, msg, true);
end

function TimeLimitFragmentExchangePage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.FRAGMENT_EXCHANGE_S then
		-- local msg = Activity2_pb.FragmentExchangeRes();
		-- msg:ParseFromString(msgBuff);
		self:refreshPage();
        -- self:pushRewardPage(msg.rewardFragment);
    elseif opcode == HP_pb.SYNC_FRAGMENT_EXCHANGE_S then
    	local msg = Activity2_pb.SyncFragmentExchangeRes();
		msg:ParseFromString(msgBuff);
    	self:onChangeTimes(msg.surplusTime);
    end
end

function TimeLimitFragmentExchangePage:onChangeTimes(times)
	TimeLimitFragmentExchangePage.RemainTime = times;
	if TimeLimitFragmentExchangePage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TimeLimitFragmentExchangePage.RemainTime)
	end
end

function TimeLimitFragmentExchangePage:pushRewardPage(rewardItem)
	local rewardItems = common:parseItemWithComma(rewardItem)    
	local CommonRewardPage = require("CommonRewardPage")
    CommonRewardPageBase_setPageParm(rewardItems, true) --, msg.rewardType
    PageManager.pushPage("CommonRewardPage")
end

function TimeLimitFragmentExchangePage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function TimeLimitFragmentExchangePage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function TimeLimitFragmentExchangePage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	SaveSelectObject = nil;
 	SaveSelectDataCfg = nil;
 	self:removePacket(ParentContainer);
 	NodeHelper:deleteScrollView(self.container);
	onUnload(thisPageName, self.container);
end

return TimeLimitFragmentExchangePage
