
----------------------------------------------------------------------------------
local thisPageName = "DebugPage"
local NodeHelper = require("NodeHelper")

local DebugPage = {}
local debugMsg = ""

local option = {
	ccbiFile = "DebugPage.ccbi",
	handlerMap = {
	    onClose = "onClose"
	},
}

function DebugPage:onEnter(container)
    self:createDebugMsg(container)
end

function DebugPage:createDebugMsg(container)
    local _scrollviewContent = container:getVarScrollView("mDebugContent")
    local size = _scrollviewContent:getViewSize()

    local text, height = NodeHelper:horizontalSpacingAndVerticalSpacing(debugMsg, "Barlow-SemiBold.ttf", 20, 0, 0, size.width, "255 50 50")
    text:setPosition(ccp(0, 350))
    text:setAnchorPoint(ccp(0, 1))
    _scrollviewContent:addChild(text)
    _scrollviewContent:setContentSize(CCSizeMake(_scrollviewContent:getContentSize().width, height))
    _scrollviewContent:setContentOffset(ccp(0, size.height - height))    
    container:autoAdjustResizeScrollview(_scrollviewContent)
end

function DebugPage:onExit(container)
    local _scrollviewContent = container:getVarScrollView("mDebugContent")
    _scrollviewContent:removeAllChildren()
end

function DebugPage:onClose(container)
    debugMsg = ""
	PageManager.popPage(thisPageName)
end

function DebugPage:setMessage(msg)
    debugMsg = msg
end

local CommonPage = require("CommonPage")
local DebugPageInfo = CommonPage.newSub(DebugPage, thisPageName, option);

return DebugPageInfo