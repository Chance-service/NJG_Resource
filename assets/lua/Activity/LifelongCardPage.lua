
local thisPageName = "LifelongCardPage"
local Activity_pb = require("Activity2_pb")
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local LifelongCardPageBase = {}

local isHelpStatus = 0
local UnActivateIsRun = false;--是否正常播放未激活终生卡的动画

local option = {
    ccbiFile = "Act_LifelongCardPage.ccbi",
    handlerMap = {
        onRechargeButton  = "onRecharge",
        onActivateButton    = "onOrder",
        onReceiveButton   = "onReward",
        onReverseSide       = "onReverseSide",
        onReturnButton	    = "onBack",
        onHelp              = "onHelp"
    }
}

local cardStatus = 0
local canActivateNeedGold = ""
local activateGold = ""
local activateConsumGold = 0

function LifelongCardPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:registerPacket(container)
    self:requireBasicInfo(container)
    self:refreshPage(container)
end

function LifelongCardPageBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH);
end

function LifelongCardPageBase:refreshPage(container)
    local nodesVisiable = {}
    local ReceivingDailyNum,CustomConsumptionNum,HintText
    local EveryDayNeedGold = VaribleManager:getInstance():getSetting("DailyGoldAward")  --钻石
   --[[ if cardStatus == 3 or cardStatus == 4 then     --状态3为领取福利阶段
        CustomConsumptionNum = common:getLanguageString("@LifelongCardDailyWelfare",EveryDayNeedGold);
        ReceivingDailyNum = common:getLanguageString("@EffectiveDate")..common:getLanguageString("@LifelongEfect");
    else
        CustomConsumptionNum = common:getLanguageString("@ReceivingDailyNum",EveryDayNeedGold);
        ReceivingDailyNum = common:getLanguageString("@CustomConsumptionNum",activateGold);
    end]]--
    
    -- 玩家终身卡状态(1:未开启,无资格 2: 未开启,有资格 3:已开启,今日未领取 4:已开启,今日已领取)
    local mUnActivatedNode = container:getVarNode("mUnActivatedNode")
    local mActivatedNode = container:getVarNode("mActivatedNode")
    local gemccbi = container:getVarNode("mGemccb");
    local GoldDisappear = container:getVarNode("mGoldDisappear");
    local needgold = canActivateNeedGold;
    local HintActivateInfo = "";
    if cardStatus == 1 then
      mUnActivatedNode:setVisible(true);
      mActivatedNode:setVisible(false);
      NodeHelper:setMenuItemEnabled(container, "mActivateBtn", false)
       if Golb_Platform_Info.is_r2_platform and tonumber(needgold) == 0 then
          HintActivateInfo = common:getLanguageString("@NeedConsumGold",activateConsumGold);
      end
    elseif cardStatus == 2 then
      mUnActivatedNode:setVisible(true);
      mActivatedNode:setVisible(false);
      NodeHelper:setMenuItemEnabled(container, "mActivateBtn", true)
      needgold = 0;
    elseif cardStatus == 3 then
      mActivatedNode:setVisible(true);
      gemccbi:setVisible(true);
      NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", true)
    else 
      mActivatedNode:setVisible(true);
      gemccbi:setVisible(false);
      NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", false)
    end
    if cardStatus == 3 or cardStatus == 4 then
        mUnActivatedNode:setVisible(false);
        if UnActivateIsRun == false then
            container:runAnimation("Activated");
        end
        
    end
   
    local HintGetGems = common:getLanguageString("@LongLifeCardReceiveInfo",GameConfig.LifelongCardGems);
    local strmap = 
    {
        mReceiveInfo = HintGetGems,
        mLFCneedgold = needgold,
        mLongLifeCardActivateInfo = HintActivateInfo
    };
    NodeHelper:setStringForLabel(container,strmap);
    GoldDisappear:setVisible(false);

end

function LifelongCardPageBase:requireBasicInfo(container)
    common:sendEmptyPacket(HP_pb.FOREVER_CARD_INFO_C,false)
end

function LifelongCardPageBase:onBack(container)
    --PageManager.changePage("ActivityPage")
	PageManager.refreshPage("ActivityPage")
    PageManager.popPage(thisPageName)
end

function LifelongCardPageBase:onReverseSide(container)
    local nodesVisiable = {}
    local mCardFront = container:getVarNode("mCardFront")
    local mCardBack = container:getVarNode("mCardBack")
    if isHelpStatus == 0 then
        if mCardFront and  mCardBack then
            mCardFront:setVisible(false)
            mCardBack:setVisible(true)
            isHelpStatus = 1
        end
    else
        if mCardFront and  mCardBack then
            mCardFront:setVisible(true)
            mCardBack:setVisible(false)
            isHelpStatus = 0
        end 
    end
end

-- 充值
function LifelongCardPageBase:onRecharge(container)
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","LifelongCard_enter_rechargePage")
    PageManager.pushPage("RechargePage")
end 

-- 订制
function LifelongCardPageBase:onOrder(container)
    local UserInfo = require("PlayerInfo.UserInfo")
    local title = Language:getInstance():getString("@LifelongCardTitle")
    local finalMsg = common:getLanguageString("@LifelongCardBuyContent",activateGold);   
    PageManager.showConfirm(title,finalMsg, function(isSure)
            if isSure and UserInfo.isGoldEnough(activateGold,"LifelongCard_enter_rechargePage") then
                common:sendEmptyPacket(HP_pb.FOREVER_CARD_ACTIVATE_C,true)   
            end
    end,true);
end

-- 领取奖励
function LifelongCardPageBase:onReward(container)
    common:sendEmptyPacket(HP_pb.FOREVER_CARD_GET_AWARD_C,true)
    local GoldDisappear = container:getVarNode("mGoldDisappear");
    GoldDisappear:setVisible(true);
    local ccbi = CCBManager:getInstance():createAndLoad2("A_disappear.ccbi")
    GoldDisappear:removeAllChildren()
    if ccbi then
        ccbi:setAnchorPoint(ccp(0.5,0.5))
        GoldDisappear:addChild(ccbi,1,1)
    end
end

function LifelongCardPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_LIFELONGCARD)
end

function LifelongCardPageBase:registerPacket(container)
    container:registerPacket(HP_pb.FOREVER_CARD_INFO_S)
    container:registerPacket(HP_pb.FOREVER_CARD_GET_AWARD_S)
    container:registerPacket(HP_pb.FOREVER_CARD_ACTIVATE_S)
end

function LifelongCardPageBase:removePacket(container)
    container:removePacket(HP_pb.FOREVER_CARD_INFO_S)
    container:removePacket(HP_pb.FOREVER_CARD_GET_AWARD_S)
    container:removePacket(HP_pb.FOREVER_CARD_ACTIVATE_S)
end

function LifelongCardPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();

    if opcode == HP_pb.FOREVER_CARD_INFO_S or opcode == HP_pb.FOREVER_CARD_ACTIVATE_S or opcode == HP_pb.FOREVER_CARD_GET_AWARD_S then
        local msg = Activity_pb.HPForeverCardRet()
		msg:ParseFromString(msgBuff)
        cardStatus = msg.cardStatus
        if msg:HasField("canActivateNeedGold") then
            canActivateNeedGold = msg.canActivateNeedGold
        end
        if msg:HasField("activateGold") then
            activateGold = msg.activateGold
        end
        if msg:HasField("activateConsumGold") then
            activateConsumGold = msg.activateConsumGold
        end
         if opcode == HP_pb.FOREVER_CARD_ACTIVATE_S then

            local animationNode = container:getVarNode("mUnActivatedAnimation")
            if animationNode~=nil then
                animationNode:setVisible(true);
            end
            container:runAnimation("unActivated")
            UnActivateIsRun = true;--是否正常播放未激活终生卡的动画
         end
        self:refreshPage(container)
    end
end
function LifelongCardPageBase:onAnimationDone(container)
	local animationName=tostring(container:getCurAnimationDoneName())
    local animationNode = container:getVarNode("mUnActivatedAnimation")
    if animationNode~=nil then
        animationNode:setVisible(false);
    end
	if animationName=="unActivated" then
		container:runAnimation("Activated")
	end
end
function LifelongCardPageBase:onReceiveMessage(container)
    local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			self:requireBasicInfo(container)
		end
	end
end

-------------------------------------------------------------------
local CommonPage = require("CommonPage")
local LifelongCardPage = CommonPage.newSub(LifelongCardPageBase, thisPageName, option);

function LifelongCardPage_receivePacket(msg)
    if msg==nil then return end
    cardStatus = msg.cardStatus
    if msg:HasField("canActivateNeedGold") then
        canActivateNeedGold = msg.canActivateNeedGold
    end
    if msg:HasField("activateGold") then
        activateGold = msg.activateGold
    end
    if msg:HasField("activateConsumGold") then
            activateConsumGold = msg.activateConsumGold
    end
end