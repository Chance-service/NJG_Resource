
local BasePage = require("BasePage")
local NodeHelper = require("NodeHelper")
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")

local thisPageName = "WealthClubPage"
local opcodes = {
	GOLD_CLUB_INFO_C = HP_pb.GOLD_CLUB_INFO_C,
    GOLD_CLUB_INFO_S = HP_pb.GOLD_CLUB_INFO_S,
    WEALTH_STAGE_STATUS_S = HP_pb.WEALTH_STAGE_STATUS_S
}
local option = {
	ccbiFile = "Act_WealthClubPopUp.ccbi",
	handlerMap ={
		onReturnButton 	        = "onClose",
		onHelp 		            = "onHelp",
        onReceiveWelfare        = "onReceiveWelfare"
	},
}
--活动基本信息
local thisActivityInfo = {
	id				   = 41,
    totalGold          = 0,    ----总充值
    maxGift            = 0,    ----领取上限
    getGift            = 0,    ----可领取钻石
    remainTime         = 0,    --剩余时间
    --isGetGift          = 0,     --领取状态 0未充值 1今日已领取 2今日可领取
    rechargeIsValid = true,  --充值是否是否有效
    rechargePeople = 0,--充值人数
    proportion = 0,--当前返利比例
    recharge = 0,
};
thisActivityInfo.timerName = "Activity_WealthClubGift";
local timeInfo = 
{
    serverDateKey = "Activity_serverDateKey",
    serverTimes = 0,
    lastServerTime = 0
}
local showStr = {}

local WealthClubPage = {}
local fromAni = false
WealthClubPage = BasePage:new(option,thisPageName,nil,opcodes)

function WealthClubPage:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(thisActivityInfo.timerName) then
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(thisActivityInfo.timerName);

	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { mActivityDaysNum = timeStr});

    if remainTime <= 0 then
	    timeStr = common:getLanguageString("@ActivityEnd");
	    PageManager.popPage(thisPageName)
    end

    ------------------------------
    if TimeCalculator:getInstance():hasKey(timeInfo.serverDateKey) then
        local stime = TimeCalculator:getInstance():getTimeLeft(timeInfo.serverDateKey);
        if timeInfo.lastServerTime - stime >= 1 then
            timeInfo.lastServerTime = stime
            timeInfo.serverTimes = timeInfo.serverTimes + 1

            local serverDateTb = {};
            local timeOrginalStr = GameMaths:getTimeByTimeZone(timeInfo.serverTimes,GameConfig.SaveingTime)
            local timeTable = common:split(timeOrginalStr," ")
            local monthKeys = {Jan="01", Feb="02", Mar="03", Apr="04",May="05", Jun="06",Jul="07", Aug="08", Sep="09", Oct="10",Nov="11", Dec="12"}
            serverDateTb["year"] = os.date("%Y");
            serverDateTb["month"] = monthKeys[timeTable[1]];
            serverDateTb["day"] = timeTable[2]
            local SplitTb = common:split(timeTable[3],":")
            serverDateTb["hour"] = SplitTb[1];
            serverDateTb["min"] = SplitTb[2];
            serverDateTb["sec"] = SplitTb[3];
            serverDateTb["isdst"] = false;
            local severTimeStamp = os.time(serverDateTb)

            local TagDateTb = common:deepCopy(serverDateTb);
            TagDateTb["hour"] = "01"
            TagDateTb["min"] = "29";
            TagDateTb["sec"] = "00";
            local TagTimeStampBegin = os.time(TagDateTb)
            local TagTimeStampEnd = TagTimeStampBegin + 1*60;
            local boolValue = true
            if severTimeStamp>=TagTimeStampBegin and severTimeStamp < TagTimeStampEnd then
            --false
                boolValue = false
            end
            if boolValue ~= thisActivityInfo.rechargeIsValid then
                thisActivityInfo.rechargeIsValid = boolValue
                self:refreshPage(container);
            end
        end
    end
end

function WealthClubPage:onReceiveWelfare(container)
    if thisActivityInfo.rechargeIsValid then
        PageManager.pushPage("RechargePage");
    end
    --[[if thisActivityInfo.isGetGift==0 then
        MessageBoxPage:Msg_Box_Lan("@WealthClubNeedRecharge")
        return
    end
	 common:sendEmptyPacket(HP_pb.GET_GOLD_CLUB_WELFARE_C,false)
     self:refreshPage(container)]]--
end

function WealthClubPage:onExecute(container)  
	self:onTimer(container)
end

function WealthClubPage:refreshPage(container)
    if thisActivityInfo.remainTime > 0 then
		TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime);
	end
    thisActivityInfo.maxGift = GameConfig.wealthClubMaxNum
    --NodeHelper:setMenuItemEnabled(container,"mReceiveWelfareBtn",thisActivityInfo.isGetGift~=1)
	--NodeHelper:setNodeVisible(container:getVarNode("mReceiveWelfareEmptyBtn"),thisActivityInfo.isGetGift~=1)
    --if thisActivityInfo.isGetGift == 1 then
    --   container:runAnimation("DefaultWaitAni")
    --else 
    --    container:runAnimation("DefaultBagAni")
    --end
    --NodeHelper:setNodesVisible(container,{mAniNode = true})
    --local upperLimitStr = common:getLanguageString("@UpperLimitNum",thisActivityInfo.maxGift)
    --local totalGoldStr = common:getLanguageString("@TodayRechargeTotalNum",thisActivityInfo.totalGold)
   
	local label2Str = {
       mTodayRechargeTotalNum = thisActivityInfo.rechargePeople,
       mActClubNum1 =   thisActivityInfo.recharge,
       mActClubNum2 =   thisActivityInfo.getGift,
       mActClubNum3 =   thisActivityInfo.proportion.."%",
       mActClubNum4 =   thisActivityInfo.maxGift
	}
	NodeHelper:setStringForLabel(container,label2Str)
    --NodeHelper:setLabelOneByOne(container,"mCanReceiveDiamondDes", "mCanReceiveDiamondNum", 0)
	--NodeHelper:setLabelOneByOne(container,"mCanReceiveDiamondNum", "mUpperLimitNum", 5)
    --取消红点
    --if thisActivityInfo.isGetGift == 1  then
	--    ActivityInfo:decreaseReward(thisActivityInfo.id)
    --end
    ----处理服务器时间问题
    --[[local currentServerTime = GamePrecedure:getInstance():getServerTime()
    if currentServerTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(timeInfo.serverDateKey, currentServerTime);
        timeInfo.lastServerTime = currentServerTime;
        timeInfo.serverTimes = currentServerTime
    end]]--
    if thisActivityInfo.rechargeIsValid then
        container:runAnimation("DefaultBagAni")
    else
        container:runAnimation("DefaultWaitAni")
    end
    
    --if thisActivityInfo.isGetGift == 1 then
    --   container:runAnimation("DefaultWaitAni")
    --else 
    --    container:runAnimation("DefaultBagAni")
    --end
    ----处理服务器时间问题
end
function WealthClubPage:onAnimationDone(container)
    if fromAni then
        fromAni=false
        self:refreshPage(container)
    end
    MainFrame:getInstance():hideNoTouch()
end

--收包
function WealthClubPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.GOLD_CLUB_INFO_S then
	    local msg = Activity2_pb.HPGoldClubInfoRet()
	    msg:ParseFromString(msgBuff)
        thisActivityInfo.rechargePeople = msg.rechargePeople or 0
        thisActivityInfo.recharge = msg.recharge or 0
        thisActivityInfo.proportion = msg.proportion or 0
        thisActivityInfo.remainTime = msg.leftTimes or 0 
        thisActivityInfo.rechargeIsValid = (msg.stageStatus == 0)
        thisActivityInfo.getGift = math.floor(math.min(msg.recharge * (thisActivityInfo.proportion/100),GameConfig.wealthClubMaxNum))
        self:refreshPage(container)
    --[[elseif opcode == HP_pb.GET_GOLD_CLUB_WELFARE_S then
        local msg = Activity2_pb.HPGoldClubGetWelfareRet()
	    msg:ParseFromString(msgBuff)
        thisActivityInfo.isGetGift = msg.todayGetStatus or 0
        thisActivityInfo.remainTime = msg.leftTimes or 0
        container:runAnimation("AchieveRewardAni")
        MainFrame:getInstance():showNoTouch()
        fromAni = true]]--
    elseif opcode == HP_pb.WEALTH_STAGE_STATUS_S then
         local msg = Activity2_pb.HPGoldClubStatusRet()
	     msg:ParseFromString(msgBuff)
         thisActivityInfo.rechargeIsValid = (msg.stageStatus == 0)
         self:refreshPage(container)
	end
end


function WealthClubPage:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.GOLD_CLUB_INFO_C,false)
end

function WealthClubPage:onClose( container )
	--TimeCalculator:getInstance():removeTimeCalcultor(timeInfo.serverDateKey)
    PageManager.refreshPage("ActivityPage")
	PageManager.popPage(thisPageName)
end
function WealthClubPage:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_WealthClubGIFT);
end
