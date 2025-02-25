
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local Activity2_pb = require("Activity2_pb")
local ActivityData = require("Activity.ActivityData")
local thisPageName = "TogetherCompetingRedPage"
local opcodes = {
    RED_ENVELOPE_INFO_S = HP_pb.RED_ENVELOPE_INFO_S,
    GIVE_RED_ENVELOPE_S = HP_pb.GIVE_RED_ENVELOPE_S,
    GRAB_RED_ENVELOPE_S = HP_pb.GRAB_RED_ENVELOPE_S,
    GRAB_FREE_RED_ENVELOPE_S = HP_pb.GRAB_FREE_RED_ENVELOPE_S,
}
local option = {
    ccbiFile = "Act_TogetherCompetingRedEnvelopesPopUp.ccbi",
    handlerMap ={
        onClose                 = "onClose",
        onReturnButton          = "onClose",
        onHelp                  = "onHelp",
        onSend                  = "onGive",
        onRedEnvelop            = "onGift",
        onChallenge             = "onGrapRed",
    },
}
local thisPageInfo = ActivityData.TogetherCompetingRedPage
local TogetherCompetingRedPage = BasePage:new(option,thisPageName,nil,opcodes)
local isFromFreeRed = false
local isFromGrapRed = false

-------------------------- logic method ------------------------------------------
function TogetherCompetingRedPage:refreshPage(container)
    if thisPageInfo.remainTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(thisPageInfo.timerName, thisPageInfo.remainTime);
    end
    --发字的红点
    if thisPageInfo.myRedEnvelope >0 then
        NodeHelper:setNodesVisible(container,{mSendRedPointNode = true})
    else
        NodeHelper:setNodesVisible(container,{mSendRedPointNode = false})
    end
    -- local leftRedStr = common:getLanguageString("@TogetherCompetingServerLeftRed",thisPageInfo.serverRedEnvelope)
    local alreadyGetRedStr = common:getLanguageString("@TogetherCompetingAlreadyGetRed",thisPageInfo.todayGrabRedEnvelope)
    local label2Str = {
        mTotalRecharge       = thisPageInfo.personalRechargeNum,
        mLeftRed             = thisPageInfo.serverRedEnvelope,
        mAlreadyGetRed       = alreadyGetRedStr,
    }   
    NodeHelper:setStringForLabel(container,label2Str)
    --取消红点
    if thisPageInfo.todaySysRedEnvelopeStatus == 1 and thisPageInfo.myRedEnvelope<=0 then
        ActivityInfo:decreaseReward(thisPageInfo.id)
    end
end

function TogetherCompetingRedPage:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.RED_ENVELOPE_INFO_C,false)
end
-------------------------- state method -------------------------------------------
function TogetherCompetingRedPage:onEnter( container )
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:getPageInfo(container)
end
function TogetherCompetingRedPage:onExit( container )
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end
function TogetherCompetingRedPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:getPageInfo(container)
        end
    end
end
function TogetherCompetingRedPage:onExecute(container)  
    self:onTimer(container)
end
function TogetherCompetingRedPage:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(thisPageInfo.timerName) then
        return; 
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(thisPageInfo.timerName);

    local timeStr = common:second2DateString(remainTime, false);
    NodeHelper:setStringForLabel(container, { mActivityDaysNum = timeStr});

    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd");
        PageManager.popPage(thisPageName)
    end
end
function TogetherCompetingRedPage:onAnimationDone( contanier )
    if isFromFreeRed==true and thisPageInfo.freeReward~="" then
        local tbReward = {}
        table.insert(tbReward,ConfigManager.parseItemOnlyWithUnderline(thisPageInfo.freeReward))
        common:popRewardString(tbReward)
        isFromFreeRed = false
        MainFrame:getInstance():hideNoTouch()
    elseif isFromGrapRed==true then
        PageManager.pushPage("TogetherCompetingGrabPage")
        isFromGrapRed = false
        MainFrame:getInstance():hideNoTouch()
    end 
end
----------------------------click method -------------------------------------------
-- 点击红包 每日奖励
function TogetherCompetingRedPage:onGift( container )
    if thisPageInfo.todaySysRedEnvelopeStatus == 1 then
        MessageBoxPage:Msg_Box_Lan("@TogetherRedAlreadyGetFree")
        return
    end
    common:sendEmptyPacket(HP_pb.GRAB_FREE_RED_ENVELOPE_C)
end
-- 点击抢字
function TogetherCompetingRedPage:onGrapRed(container)
    common:sendEmptyPacket(HP_pb.GRAB_RED_ENVELOPE_C)
end
-- 发红包
function TogetherCompetingRedPage:onGive(container)
    PageManager.pushPage("TogetherCompetingPopUpPage")
end
function TogetherCompetingRedPage:onClose( container )
    PageManager.refreshPage("ActivityPage")
    PageManager.popPage(thisPageName)
end

function TogetherCompetingRedPage:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_TogetherCompetingRedGIFT);
end
----------------------------packet method -------------------------------------------
function TogetherCompetingRedPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.RED_ENVELOPE_INFO_S then
        local msg = Activity2_pb.HPRedEnvelopeInfoRet()
        msg:ParseFromString(msgBuff)
        thisPageInfo.myRedEnvelope     = msg.myRedEnvelope or 0
        thisPageInfo.todayGrabRedEnvelope = msg.todayGrabRedEnvelope or 0
        thisPageInfo.serverRedEnvelope = msg.serverRedEnvelope or 0
        thisPageInfo.personalRechargeNum = msg.personalRechargeNum or 0
        thisPageInfo.remainTime       = msg.leftTimes or 0 
        thisPageInfo.todaySysRedEnvelopeStatus = msg.todaySysRedEnvelopeStatus or 0   
    elseif opcode == HP_pb.GIVE_RED_ENVELOPE_S then
	    local msg = Activity2_pb.HPGiveRedEnvelopeRet()
        msg:ParseFromString(msgBuff)
        thisPageInfo.myRedEnvelope     = msg.myRedEnvelope or 0
        thisPageInfo.serverRedPackNum = msg.serverRedEnvelope or 0
        thisPageInfo.remainTime       = msg.leftTimes or 0
    elseif opcode == HP_pb.GRAB_RED_ENVELOPE_S then
        local msg = Activity2_pb.HPGrabRedEnvelopeRet()
        msg:ParseFromString(msgBuff)
        thisPageInfo.playerId         = msg.playerId or 0
        if msg:HasField("playerName") then
            thisPageInfo.playerName = msg.playerName
        else
            thisPageInfo.playerName = ""
        end
        thisPageInfo.roleItemId       = msg.roleItemId or 0
        thisPageInfo.roleLevel       = msg.roleLevel or 0
        thisPageInfo.wishes           = msg.wishes
        thisPageInfo.gold             = msg.gold
        thisPageInfo.serverRedEnvelope   = msg.serverRedEnvelope
        thisPageInfo.todayGrabRedEnvelope = msg.todayGrabRedEnvelope or 0
        thisPageInfo.remainTime      = msg.leftTimes
        isFromGrapRed = true
        container:runAnimation("SendRedEnvelop")
        MainFrame:getInstance():showNoTouch()
    elseif opcode == HP_pb.GRAB_FREE_RED_ENVELOPE_S then
        local msg = Activity2_pb.HPGrabFreeRedEnvelopeRet()
        msg:ParseFromString(msgBuff)
        thisPageInfo.freeReward = msg.itemCfg
        thisPageInfo.todaySysRedEnvelopeStatus = msg.todaySysRedEnvelopeStatus  
        isFromFreeRed = true
        container:runAnimation("SendRedEnvelop")
        MainFrame:getInstance():showNoTouch()
    end
    self:refreshPage(container)
end
---------------------------- end  ----------------------------------------------------