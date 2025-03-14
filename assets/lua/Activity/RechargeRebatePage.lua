

------------------------------------local variable--------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Activity_pb = require("Activity_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local thisPageName = 'RechargeRebatePage'
local RebateBase = {}

local option = {
	ccbiFile = "Act_TimeLimitRechargeReturnContent.ccbi",
	handlerMap = {
		onRecharge 	= "onRecharge",   -- 果断充值
	},
}
--活动基本信息
local thisActivityInfo = {
	id						= 22,
	remainTime 				= 0,
	accRechargeDiamond		= 0, -- 累计充值钻石
	canReceiveDiamond 		= 0, -- 可领取钻石
}
local timerName = "Activity_" .. thisActivityInfo.id --充值返利倒计时的key
--------------------------------page show--------------------------------------
function RebateBase:onEnter(parentContainer)

	local container = ScriptContentBase:create(option.ccbiFile)
	self.container = container
	luaCreat_RechargeRebatePage(container)	
	self:pageReset(container)
	self:registerPacket(parentContainer)
	if GlobalData.nowActivityId ~= nil and GlobalData.nowActivityId == 28 then
		local msg = Activity_pb.HPRebateInfo()
		msg.activityId = GlobalData.nowActivityId
		common:sendPacket(HP_pb.RECHARGE_REBATE_INFO_C, msg);
	else
		local msg = Activity_pb.HPRebateInfo()
		msg.activityId = thisActivityInfo.id
		common:sendPacket(HP_pb.RECHARGE_REBATE_INFO_C, msg)
	end
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_RECHARGEREBATE)

	-- NodeHelper:setLabelOneByOne(container, "mCDTtitle", "mCD")

	return container
end

function RebateBase:pageReset( container )
	NodeHelper:setNodeVisible(container:getVarNode("mRechargeNode"), false)
	NodeHelper:setNodeVisible(container:getVarNode("mReceiveNode"), false)
end

function RebateBase:onExit( container)
	self:removePacket(container)
	TimeCalculator:getInstance():removeTimeCalcultor(timerName);
	self.container = nil
end

function RebateBase:onRefreshPage( container )
	if thisActivityInfo.remainTime > 0 then
		TimeCalculator:getInstance():createTimeCalcultor(timerName, thisActivityInfo.remainTime);
	end
	dump(thisActivityInfo)
	-- 剩余时间不为0，活动开启状态
	NodeHelper:setNodeVisible(container:getVarNode("mRechargeNode"), thisActivityInfo.remainTime>0)
	NodeHelper:setNodeVisible(container:getVarNode("mReceiveNode"), thisActivityInfo.remainTime<=0)
	local lb2Str = {
		mCurrentDiamondsNum		 	=  thisActivityInfo.accRechargeDiamond,
		mReceiveDiamondsNum 		=  thisActivityInfo.canReceiveDiamond,
		mCumulativeDiamondsNum 		=  thisActivityInfo.accRechargeDiamond,
		mReceiveDiamondsTodayNum	=  thisActivityInfo.canReceiveDiamond,
	}
	NodeHelper:setStringForLabel(container, lb2Str)

	-- 如果活动开启，并且累计充值大于等于0
	if thisActivityInfo.accRechargeDiamond>=0 and thisActivityInfo.remainTime>0 then
		local progressBar = container:getVarScale9Sprite("mBar")
		local accPercent = thisActivityInfo.accRechargeDiamond/10000
		if progressBar~=nil and accPercent>=0 then
			progressBar:setScaleX(math.min(accPercent,1.0))
		end
	end
end

function RebateBase:onExecute( container )
	self:onTimer(container)
end

function RebateBase:onTimer( container )
	-- 倒计时为0的时候显示已结束
	if (thisActivityInfo.remainTime~=nil and thisActivityInfo.remainTime<= 0)
		or (TimeCalculator:getInstance():hasKey(timerName) 
		and TimeCalculator:getInstance():getTimeLeft(timerName)<=0) then

		NodeHelper:setStringForLabel(container, {mCD = common:getLanguageString("@ActivityRebateClose")})
		return
	end
	if not TimeCalculator:getInstance():hasKey(timerName) then return end
	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName)
	thisActivityInfo.remainTime = math.max(remainTime, 0)
	-- -- 如果倒计时为0，重新请求
	-- if thisActivityInfo.remainTime == 0 then
	-- 	common:sendEmptyPacket(HP_pb.RECHARGE_REBATE_INFO_C,false)
	-- end
	local timeStr = common:second2DateString(thisActivityInfo.remainTime, false)
	NodeHelper:setStringForLabel(container, {mCD = timeStr})
end

function RebateBase:onRecharge( container )
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","RechargeRebate_enter_rechargePage")
	PageManager.pushPage("RechargePage");
end

function RebateBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_RECHARGEREBATE)
end

function RebateBase:onReceive( container )
	if GlobalData.nowActivityId ~= nil and GlobalData.nowActivityId == 28 then
		local msg = Activity_pb.HPRebateAward()
		msg.activityId = GlobalData.nowActivityId
		common:sendPacket(HP_pb.RECHARGE_REBATE_AWARD_C, msg);
	else	
		local msg = Activity_pb.HPRebateAward()
		msg.activityId = thisActivityInfo.id
		common:sendPacket(HP_pb.RECHARGE_REBATE_AWARD_C, msg)
	end
end

function RebateBase:onBack( container )
	PageManager.changePage("ActivityPage")
end
-------------------------------page data handler-------------------------------
function RebateBase:onReceiveRebateInfo( container,msg )
	thisActivityInfo.remainTime				 = msg.surplusTime or 0
	thisActivityInfo.accRechargeDiamond 	 = msg.accRechargeDiamond or 0
	thisActivityInfo.canReceiveDiamond 		 = msg.canReceiveDiamond or 0
	-- 如果有剩余天数，说明活动结束状态
	if msg:HasField("leftDays") then
		NodeHelper:setStringForLabel(container, {mSurplusDays = common:getLanguageString("@RebateLeftDays", msg.leftDays)})
	else
		NodeHelper:setStringForLabel(container, {mSurplusDays = ""})
	end
	-- 领取状态，1领取，0未领取
	if msg:HasField("receiveAward") then
		NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", msg.receiveAward==0)
	else
		NodeHelper:setNodeVisible(container:getVarMenuItemImage("mReceiveBtn"), false)
	end
end

--------------------------------packet handler----------------------------------
function RebateBase:registerPacket( parentContainer )
	parentContainer:registerPacket(HP_pb.RECHARGE_REBATE_INFO_S)
	parentContainer:registerPacket(HP_pb.RECHARGE_REBATE_AWARD_S)
end

function RebateBase:removePacket( parentContainer )
	parentContainer:removePacket(HP_pb.RECHARGE_REBATE_INFO_S)
	parentContainer:removePacket(HP_pb.RECHARGE_REBATE_AWARD_S)
end

function RebateBase:onReceivePacket( parentContainer )
	local opcode = parentContainer:getRecPacketOpcode()
	local msgBuff = parentContainer:getRecPacketBuffer()
    
	if opcode == HP_pb.RECHARGE_REBATE_INFO_S then
		local msg = Activity_pb.HPRebateInfoRet()
		msg:ParseFromString(msgBuff)

		-- -- 倒计时间为零，充值小于1000，关闭活动
		-- if msg.remainTime<=0 and msg.accRechargeDiamond<VaribleManager:getInstance():getSetting("rebateLimitDiamondNums") then
		-- 	common:table_removeFromArray(ActivityInfo.ids, thisActivityInfo.id)
		-- 	MessageBoxPage:Msg_Box_Lan("@ActivityRebateClose")
		-- 	PageManager.changePage("MainScenePage")
		-- end

		self:onReceiveRebateInfo(self.container, msg)
		self:onRefreshPage(self.container)
	end

	if opcode == HP_pb.RECHARGE_REBATE_AWARD_S then
		local msg = Activity_pb.HPRebateAwardRet()
		msg:ParseFromString(msgBuff)
		NodeHelper:setMenuItemEnabled(self.container, "mReceiveBtn", msg.receiveAward==0)
		
		RebateBase:clearNotice( msg.receiveAward==0 )
	end
end

function RebateBase:clearNotice( hasNotice )
    --红点消除
    if not hasNotice then
		ActivityInfo.changeActivityNotice(Const_pb.RECHARGE_REBATE);
	end
end

local CommonPage = require('CommonPage')
local RechargeRebatePage= CommonPage.newSub(RebateBase, thisPageName, option)
return RechargeRebatePage