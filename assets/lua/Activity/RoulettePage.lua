

----------------------------- local data -----------------------------------------
local NodeHelper = require("NodeHelper")
local CommonPage = require("CommonPage")
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local Activity_pb = require("Activity_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local PageName = "RoulettePage"
local option = {
	ccbiFile = "Act_InsaneTurnTable.ccbi",
	handlerMap = {
		onDecisiveRecharge = "onRecharge",
		onOneTime = "onOneTime",
		onTenTimes = "onTenTimes",
		onIntegralMall = "onScoreShop",
		onReturnButton = "onBack",
		onHelp = "onHelp",
	},
	opcode = {
		ROULETTE_INFO_S = HP_pb.ROULETTE_INFO_S,
		ROULETTE_ROTATE_S =HP_pb.ROULETTE_ROTATE_S,
	},
}
for i=1,8 do
	option.handlerMap["onFrame"..i] = "onFrame"
end
local RoulettePage = CommonPage.new(PageName, option)

--活动基本信息
local thisActivityInfo = {
	id				= 30,
	remainTime 		= 0,
}
local pageInfo = {
	lotteryRewards	= ConfigManager.getRouletteCfg(), 		-- 转盘物品
	rechargeGolds 	= 0, 									-- 当前充值钻石数
	leftTimes 		= 0, 									-- 抽奖剩余次数
	curCredits  	= 0, 									-- 当前积分
	oriId 			= 1,									-- 转盘起始角度
	toId 			= 1, 									-- 转盘最终角度
	mAniNode 		= nil, 									-- 一直旋转的动画node
}
local rouletteItems = {} 									-- 整合后的转盘物品
thisActivityInfo.timerName = "Activity_" .. thisActivityInfo.id
-------------------------------- logic methods ------------------------------------
function RoulettePage.runAnimation(container, oriId, toId)
	local unitAngle = 360/(#pageInfo.lotteryRewards)
	local oriAngle = ((oriId-1)%(#pageInfo.lotteryRewards))*unitAngle
	local toAngle = ((toId-1)%(#pageInfo.lotteryRewards))*unitAngle+360*8

	container:getVarNode("mPointer"):setRotation(oriAngle)
	local rotateAction = CCRotateTo:create(GameConfig.Act_RouletteVariable.delayTime-0.5,toAngle)
	local rotateAni = CCEaseInOut:create(rotateAction, GameConfig.Act_RouletteVariable.rotateRate)
	container:getVarNode("mPointer"):runAction(rotateAni)
end

function RoulettePage.refreshPage( container )
	-- 消除红点
	--[[if pageInfo.curCredits==0 and pageInfo.leftTimes==0 then
		ActivityInfo:decreaseReward(thisActivityInfo.id) 
	end]]--
	-- 剩余时间
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime)
	end
	-- 充值次数文字
	local canPlayTimes = math.min(math.floor(pageInfo.rechargeGolds/GameConfig.Act_RouletteVariable.goldForOnceLottery)
		,GameConfig.Act_RouletteVariable.lotteryTimes)
	local str = common:fillHtmlStr('ActRoulette', pageInfo.rechargeGolds, canPlayTimes, GameConfig.Act_RouletteVariable.lotteryTimes);
	local label = NodeHelper:addHtmlLable(container:getVarNode('mTodayRechargeTex'), str, GameConfig.Tag.HtmlLable)
	if Golb_Platform_Info.is_entermate_platform then
		label:setScale(0.8)
	end
	-- 剩余次数，积分
	local leftTimesStr = common:getLanguageString("@RouletteLeftTimes", pageInfo.leftTimes)
	NodeHelper:setStringForLabel(container, {
			mActTextLab2 = leftTimesStr,
			mIntegralNum = tostring(pageInfo.curCredits)
		})

	
	NodeHelper:setLabelOneByOne(container,"mActTextLab2Title","mActTextLab2")
	NodeHelper:setLabelOneByOne(container,"mCurrentIntegral","mIntegralNum")
end
function RoulettePage.onFrame( container,eventName )
	local index = tonumber(eventName:sub(-1))
	GameUtil:showTip(container:getVarNode('mPic' .. index), pageInfo.lotteryRewards[index].items[1])
end
function RoulettePage.onTimer( container )
	local timerName = thisActivityInfo.timerName;
	-- 倒计时为0的时候显示已结束
	if (thisActivityInfo.remainTime~=nil and thisActivityInfo.remainTime<= 0)
		or (TimeCalculator:getInstance():hasKey(timerName) 
		and TimeCalculator:getInstance():getTimeLeft(timerName)<=0) then
		NodeHelper:setStringForLabel(container, {mCD = common:getLanguageString("@ActivityRebateClose")})
		
  --   	NodeHelper:setLabelOneByOne(container, "mCDTitle", "mCD")
		return
	end
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);

	thisActivityInfo.remainTime = math.max(remainTime, 0);
	local timeStr = common:second2DateString(thisActivityInfo.remainTime, false);
	NodeHelper:setStringForLabel(container, {mCD = timeStr})
	
 --    NodeHelper:setLabelOneByOne(container, "mCDTitle", "mCD")
end

function RoulettePage.resetData( container )
	pageInfo.mAniNode= nil
	pageInfo.oriId = 1
	pageInfo.toId = 1
end
-------------------------------- state methods ------------------------------------
function RoulettePage.onEnter(container)
	NodeHelper:setStringForLabel(container, {mIntegralNum = ""})
	RoulettePage.registerPacket(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	container:getVarNode("mPointer"):setRotation(0)

	pageInfo.mAniNode = CCBManager:getInstance():createAndLoad2("Act_InsaneTurnAni.ccbi")
	container:getVarNode("mAniNode"):addChild(pageInfo.mAniNode)

	-- 填充转盘物品
	if #rouletteItems == 0 then
		for i=1,#pageInfo.lotteryRewards do
			table.insert(rouletteItems, pageInfo.lotteryRewards[i].items[1])
		end
	end
	NodeHelper:fillRewardItem(container, rouletteItems, 8)
	common:sendEmptyPacket(HP_pb.ROULETTE_INFO_C)
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_ROULETTE)
end

function RoulettePage.onExit(container)
	RoulettePage.removePacket(container)
	RoulettePage.resetData(container)
	container:getVarNode("mAniNode"):removeAllChildren()
end

function RoulettePage.onExecute( container )
	RoulettePage.onTimer(container)
end

function RoulettePage.onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == PageName then
			common:sendEmptyPacket(HP_pb.ROULETTE_INFO_C)
			RoulettePage.refreshPage(container)
		end
	end
end
-------------------------------- click methods -------------------------------------
function RoulettePage.onBack( container )
	PageManager.popPage(PageName)
    PageManager.refreshPage("ActivityPage")
end

function RoulettePage.onOneTime( container )
	if pageInfo.leftTimes<1 then
		MessageBoxPage:Msg_Box_Lan("@RouletteTimesNotEnough")
	else
		local msg = Activity_pb.HPRouletteRotate();
		msg.times = 1
		common:sendPacket(HP_pb.ROULETTE_ROTATE_C, msg)
	end
end

function RoulettePage.onTenTimes( container )
	if pageInfo.leftTimes<10 then
		MessageBoxPage:Msg_Box_Lan("@RouletteTimesNotEnough")
	else
		local msg = Activity_pb.HPRouletteRotate();
		msg.times = 10
		common:sendPacket(HP_pb.ROULETTE_ROTATE_C, msg)
	end
end

function RoulettePage.onScoreShop( container )
	PageManager.pushPage("RouletteScoreMallPage")
end

function RoulettePage.onRecharge( container )
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","Roulette_enter_rechargePage")
	PageManager.pushPage("RechargePage")
end

function RoulettePage.onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_ROULETTE)
end
-------------------------------- packet handler ------------------------------------
function RoulettePage.onReceivePacket( container )
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.ROULETTE_INFO_S then
    	local msg = Activity_pb.HPRouletteInfoRet();
		msg:ParseFromString(msgBuff)
    	thisActivityInfo.remainTime = msg.leftTime
    	pageInfo.leftTimes = msg.rouletteLeftTimes
    	pageInfo.curCredits = msg.curCredits
    	pageInfo.rechargeGolds = msg.todayAccRechargeNum
    	RoulettePage.refreshPage(container)
    elseif opcode == HP_pb.ROULETTE_ROTATE_S then
    	local msg = Activity_pb.HPRouletteRotateRet();
		msg:ParseFromString(msgBuff)
		pageInfo.toId = msg.awardsCfgId[1]
		pageInfo.leftTimes = msg.rouletteLeftTimes
    	pageInfo.curCredits = msg.curCredits
    	-- 飘字内容
    	local popRewards = {}
    	table.foreach(msg.awardsCfgId, function( i,v )
    		table.foreach(rouletteItems, function( v1,v2 )
    			if v==v1 then
    				table.insert(popRewards, v2)
    			end
    		end)
    	end)
    	-- 播放动画，动画结束刷新页面，飘字
    	local array = CCArray:create()
    	array:addObject(CCCallFunc:create(function()
    		RoulettePage.runAnimation(container, pageInfo.oriId, pageInfo.toId)
		end))
		array:addObject(CCCallFunc:create(function()
			pageInfo.mAniNode:runAnimation("TurnAniTimeLine2")
		end))
    	array:addObject(CCCallFunc:create(function()
	    	MainFrame:getInstance():showNoTouch()
    	end)) -- 播放动画过程，无法点击屏幕
    	array:addObject(CCDelayTime:create(GameConfig.Act_RouletteVariable.delayTime))
    	array:addObject(CCCallFunc:create(function()
    		common:popRewardString(popRewards)
    	end)) -- 飘字
    	array:addObject(CCCallFunc:create(function()
	    	MainFrame:getInstance():hideNoTouch()
    	end))
    	array:addObject(CCCallFunc:create(function()
    		pageInfo.oriId = pageInfo.toId
    	end))
    	container:runAction(CCSequence:create(array))
        if pageInfo.curCredits==0 and pageInfo.leftTimes==0 then
		    ActivityInfo:decreaseReward(thisActivityInfo.id) 
	    end
		RoulettePage.refreshPage(container)
    end
end