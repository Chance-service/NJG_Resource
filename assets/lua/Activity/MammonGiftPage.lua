
local BasePage = require("BasePage")
local NodeHelper = require("NodeHelper")
local ActivityBasePage = require("Activity.ActivityBasePage")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")

local thisPageName = "MammonGiftPage"
local opcodes = {
	FORTUNE_INFO_C = HP_pb.FORTUNE_INFO_C,
    FORTUNE_INFO_S = HP_pb.FORTUNE_INFO_S,
    FORTUNE_REWARD_C = HP_pb.FORTUNE_REWARD_C,
    FORTUNE_REWARD_S = HP_pb.FORTUNE_REWARD_S
}
local option = {
	ccbiFile = "Act_MammonGiftPopUp.ccbi",
	handlerMap ={
		onReturnButton 	        = "onClose",
		onHelp 		            = "onHelp",
        onDecisiveRecharge      = "onDecisiveRecharge",
        onOpenGift              = "onOpenGift"
	},
}
--活动基本信息
local thisActivityInfo = {
	id				   = 38,
    needGold           = 0,     --还需多少钻石
    currentStateValue  = 0,     --当前阶段
    totalGold          = 0,      --累计充值
    getGold            = 0,      --获得钻石
    remainTime         = 0,       --剩余时间
    imagePath          = {"UI/Activities/MammonGift/u_TextPic1.png",
                          "UI/Activities/MammonGift/u_TextPic2.png",
                          "UI/Activities/MammonGift/u_TextPic3.png"}
};
thisActivityInfo.timerName = "Activity_MammonGift";

local showStr = {}

local MammonGiftPage = nil

MammonGiftPage = BasePage:new(option,thisPageName,nil,opcodes)

function MammonGiftPage:onDecisiveRecharge(container)
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","MammonGift_enter_rechargePage")
     PageManager.pushPage("RechargePage");
     self:refreshPage(container)
end

function MammonGiftPage:onOpenGift(container)
    if thisActivityInfo.needGold == -1 then
        MessageBoxPage:Msg_Box_Lan("@CountLimited");
        return;
    elseif thisActivityInfo.needGold >0 then
        MessageBoxPage:Msg_Box_Lan("@GoldLimited");
        return;
    end
    MainFrame:getInstance():showNoTouch()
    container:runAnimation("OpenGift")
    common:sendEmptyPacket(HP_pb.FORTUNE_REWARD_C,false);
    self:refreshPage(container)
end
function MammonGiftPage:onAnimationDone(container)
    MainFrame:getInstance():hideNoTouch()
end
function MammonGiftPage:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(thisActivityInfo.timerName) then
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(thisActivityInfo.timerName);
	if remainTime + 1 > thisActivityInfo.remainTime then
        local localTimeStr = common:second2DateString(remainTime, false);
	    NodeHelper:setStringForLabel(container, { mActivityDaysNum = localTimeStr});
		return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { mActivityDaysNum = timeStr});

    if remainTime <= 0 then
	    timeStr = common:getLanguageString("@ActivityEnd");
	    PageManager.popPage(thisPageName)
    end
end
function MammonGiftPage:onExecute(container)  
	self:onTimer(container)
end
function MammonGiftPage:onExit(container)
    MainFrame:getInstance():hideNoTouch()
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    self:removePacket(container)
end
function MammonGiftPage:refreshPage(container)
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(thisActivityInfo.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime);
	end
    --NodeHelper:setNodesVisible(container,{mTextPic   = true})
 
    if thisActivityInfo.needGold>0 then
        --NodeHelper:setNodesVisible(container,{mRechargeNumLab = true})
        --NodeHelper:setSpriteImage(container,{mTextPic = thisActivityInfo.imagePath[1]})
        showStr = common:getLanguageString("@MammonGiftText1",thisActivityInfo.needGold)  	
	elseif thisActivityInfo.needGold == -1 then
        --NodeHelper:setNodesVisible(container,{mRechargeNumLab = false})  
        --NodeHelper:setSpriteImage(container,{mTextPic = thisActivityInfo.imagePath[3]})
        showStr = common:getLanguageString("@MammonGiftText3")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    elseif thisActivityInfo.needGold == 0 then
        --NodeHelper:setNodesVisible(container,{mRechargeNumLab = false})
        --NodeHelper:setSpriteImage(container,{mTextPic = thisActivityInfo.imagePath[2]})
        showStr = common:getLanguageString("@MammonGiftText2")
    end 
    local totalGoldStr = common:getLanguageString("@TotalGold",thisActivityInfo.totalGold)

	local label2Str = {
        mRechargeLab     = showStr,
        mRechargeNum        = totalGoldStr
	}
    
	NodeHelper:setStringForLabel(container,label2Str)

    --取消红点
    if thisActivityInfo.needGold ~= 0  then
	    ActivityInfo:decreaseReward(thisActivityInfo.id)
    end
    NodeHelper:setLabelOneByOne(container, "mActivityDaysNumTitle", "mActivityDaysNum")
end

--收包
function MammonGiftPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FORTUNE_INFO_S then
	    local msg = Activity_pb.HPFortuneInfo()
		    msg:ParseFromString(msgBuff)
		    thisActivityInfo.totalGold = msg.rechargeValue or 0
            thisActivityInfo.currentStateValue = msg.curGiftValue or 0
            thisActivityInfo.needGold  = msg.leftRechargeValue or 0
            thisActivityInfo.remainTime = msg.leftTime or 0
    elseif opcode == HP_pb.FORTUNE_REWARD_S then
        local msg = Activity_pb.HPFortuneDraw()
		    msg:ParseFromString(msgBuff)
            thisActivityInfo.getGold = msg.getGold or 0
	end
	self:refreshPage(container)
end


function MammonGiftPage:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.FORTUNE_INFO_C,false)
end

function MammonGiftPage:onClose( container )
    PageManager.refreshPage("ActivityPage")
	PageManager.popPage(thisPageName)
end

function MammonGiftPage:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_MAMMONGIFT);
end
