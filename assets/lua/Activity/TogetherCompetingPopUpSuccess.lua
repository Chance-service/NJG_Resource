
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local Activity2_pb = require("Activity2_pb")
local thisPageName = "TogetherCompetingPopUpSuccess"
local opcodes = {
     RED_ENVELOPE_INFO_C = HP_pb.RED_ENVELOPE_INFO_C,
     RED_ENVELOPE_INFO_S = HP_pb.RED_ENVELOPE_INFO_S,
     GIVE_RED_ENVELOPE_C = HP_pb.GIVE_RED_ENVELOPE_C,
     GIVE_RED_ENVELOPE_S = HP_pb.GIVE_RED_ENVELOPE_S,
}
local option = {
    ccbiFile = "Act_TogetherCompetingRedEnvelopesPopUp1.ccbi",
    handlerMap ={
        onReturnButton         = "onClose",
        onHelp                 = "onHelp",
        onIssuanceRedEnvelopes = "onIssuanceRedEnvelopes",
        onInput                = "onInput",
        luaInputboxEnter       = "onInputboxEnter"
    },
}
local thisActivityInfo = {
    myRedPackNum = 0
}
local TogetherCompetingPopUpSuccess = BasePage:new(option,thisPageName,nil,opcodes);

-------------------------- logic method ------------------------------------------

-------------------------- state method -------------------------------------------
function TogetherCompetingPopUpSuccess:onExit(container)
    self:removePacket(container)
end
function TogetherCompetingPopUpSuccess:onEnter(container)  

    if number <10 then
        NodeHelper:setNodesVisible(container,{m1=false})
        NodeHelper:setNodesVisible(container,{m2=true})       
    else
        NodeHelper:setNodesVisible(container,{m1=true})
        NodeHelper:setNodesVisible(container,{m2=false})      
    end
end

----------------------------click method -------------------------------------------

local inputContent = ""
function TogetherCompetingPopUpSuccess:onIssuanceRedEnvelopes(container)
    local message = Activity2_pb.HPGiveRedEnvelope();
    if message ~= nil then
       message.wishes = inputContent;
     
    end
    common:sendPacket(HP_pb.GIVE_RED_ENVELOPE_C, message,false);
    PageManager.popPage(thisPageName)
end
function TogetherCompetingPopUpSuccess:onInput(container)
    container:registerLibOS()
    libOS:getInstance():showInputbox(false ,"" );
end
function TogetherCompetingPopUpSuccess:onInputboxEnter(container)
    inputContent = container:getInputboxContent();
    local length = GameMaths:calculateStringCharacters(inputContent);
	if  length > 20  then
		inputContent = GameMaths:getStringSubCharacters(inputContent,0,20)
	end
    NodeHelper:setStringForLabel(container, { mDecisionTex = inputContent })
end

----------------------------packet method -------------------------------------------
function TogetherCompetingRedPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.RED_ENVELOPE_INFO_S then
        local msg = Activity2_pb.HPRedEnvelopeInfoRet()
        msg:ParseFromString(msgBuff)
        thisActivityInfo.myRedPackNum     = msg.myRedEnvelope or 0
    end
    self:refreshPage(container)
end