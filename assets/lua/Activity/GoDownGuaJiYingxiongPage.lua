----------------------------------------------------------------------------------
--[[
    
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local thisPageName = "GoDownGuaJiYingxiongPage"
opcodes={}
local option = {
    ccbiFile = "GeneralDecisionPopUp.ccbi",
    handlerMap = {
        onCancel        = "onNo",
        onConfirmation  = "onYes",
        onClose         = "onNo"
    }
}
local GoDownGuaJiYingxiongPage = BasePage:new(option,thisPageName,nil,opcodes)

-------------------------- logic method ------------------------------------------

-------------------------- state method -------------------------------------------
function GoDownGuaJiYingxiongPage:onEnter(container)
    local title = common:getLanguageString("GoDownGuaJiYingxiongTitle")
    local message = common:getLanguageString("GoDownGuaJiYingxiongMsg")
    NodeHelper:setStringForLabel(container, {
        mTitle          = title,
        mDecisionTex    = common:stringAutoReturn(message, 20)      --20: char per line
    });
end
function GoDownGuaJiYingxiongPage:onNo(container)
    PageManager.popPage(thisPageName)
end

function GoDownGuaJiYingxiongPage:onYes(container)
    libOS:getInstance():openURL("baidu.com")
end
