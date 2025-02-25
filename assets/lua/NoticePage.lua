----------------------------------------------------------------------------------

local option = {
	ccbiFile = "GeneralDecisionPopUp2.ccbi",
	handlerMap = {
		onConfirmation = "onClose"
	}
}

local thisPageName = "NoticePage"
local CommonPage = require("CommonPage")
local NoticePage = CommonPage.new("NoticePage", option)
local noticeTitle = ""
local noticeMsg = ""
local noticeCallBack = nil
local autoClose = true
local NodeHelper = require("NodeHelper")
----------------------------------------------------------------------------------
--NoticePage页面中的事件处理
----------------------------------------------
function NoticePage.onEnter(container)
	NodeHelper:setStringForLabel(container, {
		mTitle 			= noticeTitle
		-- mDecisionTex 	= common:stringAutoReturn(noticeMsg, 20)		--20: char per line
	})

	local htmlNode = container:getVarLabelBMFont("mDecisionTex")
	if htmlNode then
		local str = noticeMsg or ""
		NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(550, 96), str)
		htmlNode:setVisible(false)
	end
end

function NoticePage.onClose(container)
	if noticeCallBack then
		noticeCallBack()
	end
	if autoClose then
		PageManager.popPage(thisPageName)
	end
end	

-------------------------------------------------------------------------------
function NoticePage_setNotice(title, msg, callBack, auto)
	noticeTitle = title
	noticeMsg = msg
	noticeCallBack = callBack
	autoClose = (auto or auto == nil) and true or false
end
