

-------------------------------------------------------------------------------
require("YaYa_pb")
require("MainScenePage")
local CommonPage = require("CommonPage");
local videoManager = require("Chat.VideoOnliveManager")
local UserInfo = require("PlayerInfo.UserInfo")

local thisPageName = "GirlRechargePage";
local mExchangeNum = nil
local mAddNum = nil
local canUseGoldToday = 0
local canUseGoldAll = 0
local count = 0

local option = {
    ccbiFile = "GirlLiveRechargePopUp",
    handlerMap = {
        onCancel = "onNo",
        onClose  = "onNo",
        onConfirmation = "onYes",
        onAddNum  = "onAddGold",
        onRecharge = "onRecharge"
    }
}
local GirlRechargePage = CommonPage.new(thisPageName, option);

function GirlRechargePage.onEnter(container)
    container:registerLibOS()
    canUseGoldToday = videoManager.rechargeInfo.todayRechargeGold - videoManager.rechargeInfo.todayExchangeCostGold
    local nextStr = common:fillHtmlStr("GirlRechargeLabel" ,tostring(videoManager.rechargeInfo.todayRechargeGold), tostring(canUseGoldToday))
    local mDecisionTex = container:getVarLabelBMFont("mDecisionTex") 
    NodeHelper:addHtmlLable(mDecisionTex, nextStr, GameConfig.Tag.HtmlLable,CCSizeMake(700,100));
    mExchangeNum = container:getVarLabelBMFont("mExchangeNum")
    local mPossessGoldNum = container:getVarLabelBMFont("mPossessGoldNum")
    mPossessGoldNum:setString(tostring(UserInfo.playerInfo.gold))
    mAddNum = container:getVarLabelBMFont("mAddNum")
 
    local mRechargeNode = container:getVarNode("mRechargeNode")
    if videoManager.rechargeInfo.todayRechargeGold == 0 or UserInfo.playerInfo.gold == 0  then
        GirlRechargePage.updateGoldNum(0)
        mRechargeNode:setVisible(true)
        return
    end

    if UserInfo.playerInfo.gold >= canUseGoldToday then
        canUseGoldAll = canUseGoldToday
    else
        canUseGoldAll = UserInfo.playerInfo.gold
    end
    GirlRechargePage.updateGoldNum(canUseGoldAll)
end

function GirlRechargePage.updateGoldNum(exchangeGold)
     count = exchangeGold
     mAddNum:setString(tostring(exchangeGold))
     mExchangeNum:setString(tostring((exchangeGold * 10)))
end

function GirlRechargePage.onExit(container)
    container:removeLibOS()
end

function GirlRechargePage.onNo()
   PageManager.popPage(thisPageName)
end

function GirlRechargePage.onAddGold(container)
	libOS:getInstance():showInputbox( false,"" )
end

function GirlRechargePage.onRecharge(container)
    PageManager.pushPage("RechargePage");
    PageManager.popPage(thisPageName)
end

function GirlRechargePage.onInputboxEnter(container)
    local content = container:getInputboxContent();
    if content == "" then
       return
    end
    if content then
      local addNum = tonumber(content)
      --{"k":"@GirlLiveExchangeInputMoreInUse","v":"输入数量超过可兑换数量"},
      --{"k":"@GirlLiveExchangeInputMoreinAll","v":"现有钻石不足"}
      if addNum and GirlRechargePage.isInt(addNum) and addNum > 0 then
         if UserInfo.playerInfo.gold >= canUseGoldToday then
            if addNum > canUseGoldToday then
               MessageBoxPage:Msg_Box("@GirlLiveExchangeInputMoreInUse")
               GirlRechargePage.updateGoldNum(canUseGoldToday)
               return
            end
         elseif UserInfo.playerInfo.gold < canUseGoldToday then
            if addNum > UserInfo.playerInfo.gold then
               MessageBoxPage:Msg_Box("@GirlLiveExchangeInputMoreinAll")
               GirlRechargePage.updateGoldNum(UserInfo.playerInfo.gold) 
               return 
            end
        end
        if addNum == 0 then
            MessageBoxPage:Msg_Box("@GirlLiveExchangeInputNoZero")
            return
        end
        GirlRechargePage.updateGoldNum(addNum) 
      else
         MessageBoxPage:Msg_Box("@GirlLiveExchangePrompt")
         content = nil
         return
      end
    end 
end

function GirlRechargePage.isInt(number)
     if math.ceil(number) == math.floor(number) then
        return true
     end
     return false
end

function GirlRechargePage.onYes()
   if count == 0 then
      return
   end
   local msg = YaYa_pb.HPExchangeGoldBean()
   msg.count = count * 10
   pb_data = msg:SerializeToString()
   PacketManager:getInstance():sendPakcet(HP_pb.YAYA_EXCHANGE_GOLD_BEAN_C, pb_data, #pb_data, false)
   PageManager.popPage(thisPageName)
end 
 

--endregion
