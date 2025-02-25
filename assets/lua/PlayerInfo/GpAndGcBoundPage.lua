
local thisPageName = "GpAndGcBoundPage"
local AccountBound_pb = require("AccountBound_pb");
local NodeHelper = require("NodeHelper");
require('MainScenePage')
local HP_pb = require("HP_pb");
local pagecontainer = nil;
local opcodes = {
}
local option = {
	ccbiFile = "AccountBoundPopUp.ccbi",
	handlerMap = {
		onClose	= "onClose",
        onGooglePlay = "onBoundGcGp",
        onGameCenter = "onBoundGcGp",
	},
	opcode = opcodes
};
local GpAndGcBoundBase = {}

function GpAndGcBoundBase:onBoundGcGp(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_BIND_GC_GP","G2P_BIND_GC_GP")
end
function GpAndGcBoundBase:onEnter(container)
    pagecontainer = container;
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:refreshPage(container);
end

function GpAndGcBoundBase:refreshPage(container)


    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
        NodeHelper:setNodesVisible(container, {mGooglePlayNode = false})
        NodeHelper:setNodesVisible(container, {mGpTips = false})
    else
        NodeHelper:setNodesVisible(container, {mGameCenterNode = false})
        NodeHelper:setNodesVisible(container, {mGcTips = false})
    end
    NodeHelper:setMenuItemEnabled(container,"mGameCenterBtn",false)
    NodeHelper:setMenuItemEnabled(container,"mGooglePlayBtn",false)
    if GCAndGPBoundStatu then
        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
            NodeHelper:setStringForLabel(container,{mGCText = common:getLanguageString("@wasBoundGC")})
        else
            NodeHelper:setStringForLabel(container,{mGPText = common:getLanguageString("@wasBoundGP")})
        end
        NodeHelper:setMenuItemEnabled(container,"mGameCenterBtn",false)
        NodeHelper:setMenuItemEnabled(container,"mGooglePlayBtn",false)
        NodeHelper:setStringForLabel(container,{mAccountState = common:getLanguageString("@wasBound")})
    else
        if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
            NodeHelper:setStringForLabel(container,{mGCText = common:getLanguageString("@GameCenterBound")})
            NodeHelper:setMenuItemEnabled(container,"mGameCenterBtn",true)
        else
            NodeHelper:setStringForLabel(container,{mGPText = common:getLanguageString("@GooglePlayBound")})
            NodeHelper:setMenuItemEnabled(container,"mGooglePlayBtn",true)
        end
        NodeHelper:setStringForLabel(container,{mAccountState = common:getLanguageString("@notBound")})
    end
end
function GpAndGcBoundBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end
function GpAndGcBoundBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:refreshPage(container);
		end
	end
end
function GpAndGcBoundBase:onClose(container)
    --AccountBoundReward = 0;
    PageManager.popPage(thisPageName)
end

local CommonPage = require("CommonPage");
GpAndGcBoundPage = CommonPage.newSub(GpAndGcBoundBase, thisPageName, option);
