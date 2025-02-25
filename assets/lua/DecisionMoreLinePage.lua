-----------------------------------------------------------------------------

local option = {
	--ccbiFile = "GeneralDecisionPopUp6.ccbi",
	ccbiFile = "GuildSupportPopUp.ccbi",
	handlerMap = {
		onCancel		= "onNo",
		onConfirmation 	= "onYes",
		onClose 		= "onNo"
	}
};

local thisPageName = "DecisionMoreLinePage";
local CommonPage = require("CommonPage");
local ABManager = require("Guild.ABManager");
local DecisionMoreLinePage = CommonPage.new("DecisionMoreLinePage", option);
local decisionTitle = "";
local decisionMsg = "";
local decisionCB = nil;
local autoClose = true;
local isShowCost = true

local NodeHelper = require("NodeHelper");
----------------------------------------------------------------------------------
--DecisionMoreLinePage页面中的事件处理
----------------------------------------------
function DecisionMoreLinePage.onEnter(container)
	DecisionMoreLinePage.refreshPage(container);
	container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:setNodesVisible(container, {mButtonMiddleNode = false})
end

function DecisionMoreLinePage.onExit(container)
	DecisionMoreLinePage_setDecision("", "", nil);
	container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
    container:removeMessage(MSG_MAINFRAME_REFRESH);
end

function DecisionMoreLinePage.refreshPage(container)
	NodeHelper:setStringForLabel(container, {
		mTitle 			= decisionTitle,
		mDecisionTex 	= common:stringAutoReturn(decisionMsg, 20),		--20: char per line
		mCost			= 20,
	});
	if not isShowCost then 
		NodeHelper:setNodesVisible(container, {mCost = false, mCoinIcon = false})
	end
end

function DecisionMoreLinePage.onNo(container)
	if decisionCB then
		decisionCB(false);
	end
	PageManager.popPage(thisPageName)
end

function DecisionMoreLinePage.onYes(container)
	if decisionCB then
		decisionCB(true);
	end
	if autoClose then
		PageManager.popPage(thisPageName)
	end
end	

function DecisionMoreLinePage.onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_MAINFRAME_PUSHPAGE then
		local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			DecisionMoreLinePage.refreshPage(container);
		end
	end
    if typeId == MSG_MAINFRAME_REFRESH then
        
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            decisionMsg = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
            isShowCost = true
            if string.sub(decisionMsg, -1, -1) == "1" then
            	isShowCost = false
            	decisionMsg = string.sub(decisionMsg, 1, -2)
            end
            DecisionMoreLinePage.refreshPage(container);
        end
    end
end

-------------------------------------------------------------------------------
function DecisionMoreLinePage_setDecision(title, msg, callback, auto)
	decisionTitle	= title;
	decisionMsg 	= msg;
	isShowCost = true
	if string.sub(decisionMsg, -1, -1) == "1" then
    	isShowCost = false
    	decisionMsg = string.sub(decisionMsg, 1, -2)
    end
	decisionCB		= callback;
	autoClose		= (auto or auto == nil) and true or false;
end

function DecisionMoreLinePage_setAutoClose( auto)
	autoClose		= (auto or auto == nil) and true or false;
end