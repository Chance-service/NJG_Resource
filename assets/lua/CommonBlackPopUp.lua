local thisPageName = "CommonBlackPopUp"

local CommonBlackPopUpBase = {}
 
local option = {
    ccbiFile = "ScenesTurn.ccbi",
    handlerMap = {
        
    },
    opcodes = {
        
    }
}

function CommonBlackPopUpBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function CommonBlackPopUpBase:onEnter(container)

end

function CommonBlackPopUpBase:onExecute(container)
    
end

function CommonBlackPopUpBase:onExit(container)
    
end

function CommonBlackPopUpBase:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName == "Born" then
        PageManager.popPage(thisPageName)
	end
end

function CommonBlackPopUpBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function CommonBlackPopUpBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		
	end
end

function CommonBlackPopUpBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CommonBlackPopUpBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CommonBlackPopUp = CommonPage.newSub(CommonBlackPopUpBase, thisPageName, option);