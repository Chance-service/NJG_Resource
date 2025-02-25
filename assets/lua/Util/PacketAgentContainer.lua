--------------------------------------------------------------------------------
--  FILE:			PacketAgentContainer.lua
--  DESCRIPTION:	
--
--
--------------------------------------------------------------------------------
local PacketAgentContainer = {}

function luaCreat_PacketAgentContainer(container)
	container:registerFunctionHandler(PacketAgentContainer.onFunction)
end	

function PacketAgentContainer.onFunction(eventName,container)
	if eventName == "luaInit" then
		PacketAgentContainer.onInit(container)
	elseif eventName == "luaEnter" then
		PacketAgentContainer.onEnter(container)
	elseif eventName == "luaExit" then
		PacketAgentContainer.onExit(container)
	elseif eventName == "luaExecute" then
		PacketAgentContainer.onExecute(container)
	elseif eventName == "luaLoad" then
		PacketAgentContainer.onLoad(container)
	elseif eventName == "luaUnLoad" then
		PacketAgentContainer.onUnLoad(container)	
	elseif eventName == "luaGameMessage" then
		PacketAgentContainer.onGameMessage(container)
	elseif eventName == "luaReceivePacket" then
		PacketAgentContainer.onReceivePacket(container)		
	elseif eventName =="luaOnAnimationDone" then
		PacketAgentContainer.onAnimationDone(container)		
	end
end

function PacketAgentContainer.onAnimationDone(container)
	local animationName=tostring(container:getCurAnimationDoneName())
	if animationName=="win" or animationName=="lose" then
	end
end

function PacketAgentContainer.onLoad(container)
end

function PacketAgentContainer.onInit(container)
	container:loadCcbiFile("empty.ccbi",false)
end

function PacketAgentContainer.onEnter(container)	
end

function PacketAgentContainer.onExit(container)
end

function PacketAgentContainer.onExecute(container)
end

function PacketAgentContainer.onUnLoad(container)
end

function PacketAgentContainer.onGameMessage(container)
end



