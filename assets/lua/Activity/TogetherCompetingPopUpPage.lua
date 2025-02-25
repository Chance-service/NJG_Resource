
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local Activity2_pb = require("Activity2_pb")
local ActivityData = require("Activity.ActivityData")
local thisPageName = "TogetherCompetingPopUpPage"
local opcodes = {
     GIVE_RED_ENVELOPE_S = HP_pb.GIVE_RED_ENVELOPE_S,
}
local option = {
    ccbiFile = "Act_TogetherCompetingRedEnvelopesPopUp1.ccbi",
    handlerMap ={
        onClose         = "onClose",
        onSendTenRedEnvelop = "onSendTenEnvelop",
        onInput                = "onInput",
        luaInputboxEnter       = "onInputboxEnter"
    },
}
local thisPageInfo = ActivityData.TogetherCompetingRedPage
local TogetherCompetingPopUpPage = BasePage:new(option,thisPageName,nil,opcodes);
local inputContent = ""
-------------------------- logic method ------------------------------------------
function TogetherCompetingPopUpPage:refreshPage( container )
    -- 显示发10个还是发全部
    local btnLabelStr = ""
    if thisPageInfo.myRedEnvelope>=10 then
        btnLabelStr = common:getLanguageString("@TogetherRedGiveTenRed")
    else
        btnLabelStr = common:getLanguageString("@TogetherRedGiveAllRed")
    end
    NodeHelper:setStringForLabel(container, {
        mBtnLabel = btnLabelStr,
        mSurplusRedEnvelopNum = thisPageInfo.myRedEnvelope,
    })
end
-------------------------- state method -------------------------------------------
function TogetherCompetingPopUpPage:onExit(container)
    self:removePacket(container)
end
function TogetherCompetingPopUpPage:onEnter(container) 
    self:registerPacket(container)
    inputContent = "" 
    self:refreshPage(container)
end
function TogetherCompetingPopUpPage:onClose(container)
    PageManager.popPage(thisPageName)
end
----------------------------click method -------------------------------------------
function TogetherCompetingPopUpPage:onSendTenEnvelop(container)
    -- 如果没有红包,弹出失败页面
    if thisPageInfo.myRedEnvelope==0 then
        PageManager.pushPage("TogetherCompetingPopUpFail")
        self:onClose(container)
        return
    end
    if inputContent=="" then
        inputContent = common:getLanguageString("@TogetherRedDefaultWish")
    end
    local msg = Activity2_pb.HPGiveRedEnvelope();
    msg.wishes = inputContent;
    common:sendPacket(HP_pb.GIVE_RED_ENVELOPE_C, msg);
end
function TogetherCompetingPopUpPage:onInput(container)
    container:registerLibOS()
    libOS:getInstance():showInputbox(false ,"");
end
function TogetherCompetingPopUpPage:onInputboxEnter(container)
    inputContent = container:getInputboxContent()
    --检查祝福语合法性
    local nameOK = true
    if GameMaths:isStringHasUTF8mb4(inputContent) then
        nameOK = false
    end
    if not nameOK then
        MessageBoxPage:Msg_Box(common:getLanguageString("@NameHaveForbbidenChar"))
        inputContent = ""
        return
    end
    inputContent = RestrictedWord:getInstance():filterWordSentence(inputContent)
    local length = GameMaths:calculateStringCharacters(inputContent);
    inputContent = common:stringAutoReturn(inputContent,15)
	if  length > 30  then
		inputContent = GameMaths:getStringSubCharacters(inputContent,0,30)
	end
    NodeHelper:setStringForLabel(container, {mDecisionTex = inputContent})
    container:removeLibOS()
end

----------------------------packet method -------------------------------------------
function TogetherCompetingPopUpPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.GIVE_RED_ENVELOPE_S then
        local msg = Activity2_pb.HPGiveRedEnvelopeRet()
        msg:ParseFromString(msgBuff)
        thisPageInfo.myRedEnvelope     = msg.myRedEnvelope
        thisPageInfo.serverRedEnvelope    = msg.serverRedEnvelope
        thisPageInfo.leftTimes     = msg.leftTimes
    end
    self:refreshPage(container)
    PageManager.refreshPage("TogetherCompetingRedPage")
end