----------------------------------------------------------------------------------
require "HP_pb"
local Battle_pb = require "Battle_pb"
local option = {
	ccbiFile = "FacebookShare.ccbi",
	handlerMap = {
		onClose = "onCancel",
		onCancel = "onCancel",
		onConfirmation = "onConfirmation",
		onFaceBookInput = "onFaceBookInput",
		luaInputboxEnter = "onInputboxEnter",
        luaonCloseKeyboard = "luaonCloseKeyboard"
	}
};
local thisPageName = "FacebookSharePage"
local CommonPage = require("CommonPage");
local FacebookSharePage = CommonPage.new(thisPageName, option);


local sharePicture = ""
local shareTypeTab = {inputeState = 1,successState = 2,errorState = 3,successEmailRewardState = 4}
local shareType = shareTypeTab.inputeState
local shareContent = ""
local shareErrorMsg = ""
local shareCallBack = nil
local ShareInfo = {} --分享信息
-----------------------------------------------
--OfflineAccountPageBase页面中的事件处理
----------------------------------------------
function FacebookSharePage.onCancel(container)
	PageManager.popPage(thisPageName)
end
function FacebookSharePage.onConfirmation(container)
	if shareType == shareTypeTab.inputeState then
		shareCallBack(sharePicture,shareContent)
	elseif shareType == shareTypeTab.successState or shareType == shareTypeTab.successEmailRewardState then
		shareCallBack()
	elseif shareType == shareTypeTab.errorState then--再次分享
		shareCallBack(sharePicture,shareContent)		
	end
	PageManager.popPage(thisPageName)
end
function FacebookSharePage.onFaceBookInput(container)
	container:registerLibOS()
	libOS:getInstance():showInputbox(false,shareContent)
end

function FacebookSharePage.luaonCloseKeyboard(container)
    NodeHelper:cursorNode(container,"mInputText",false)
end
function FacebookSharePage.InputDone(container)
    local content = container:getInputboxContent()
	local contentLabel = container:getVarLabelTTF("mInputText")
	shareContent = content
    local strMap = 
    {
        mInputText = ""
    }
    if content == "" then
        strMap.mInputText = ""
        NodeHelper:setStringForLabel(container, {mInputTextHint = common:getLanguageString("@shareInputprompt")})
    else
        strMap.mInputText = content
        NodeHelper:setStringForLabel(container, {mInputTextHint = ""})
    end
	NodeHelper:setStringForLabel(container, strMap)
end
function FacebookSharePage.onInputboxEnter(container)
    FacebookSharePage.InputDone(container);
    NodeHelper:cursorNode(container,"mInputText",true)
end
function FacebookSharePage.onEditBoxReturn(editBox,content)
	shareContent = content
	editBox:setText(shareContent)
end
function FacebookSharePage.onEnter(container)
	NodeHelper:setNodesVisible(container,{mTitle = false})
	if shareType == shareTypeTab.inputeState then
		container:getVarNode("mContent1"):setVisible(true)
		container:getVarNode("mContent2"):setVisible(false)
		container:getVarNode("mContent3"):setVisible(false)
		container:getVarNode("mCancelNode"):setVisible(true)
		container:getVarNode("mConfirmationNode2"):setVisible(false)
		NodeHelper:setStringForLabel(container,{mConfirm = common:getLanguageString("@Confirmation")})
		container:getVarNode("mConfirmationNode1"):setVisible(true)
	elseif shareType == shareTypeTab.successState or shareType == shareTypeTab.successEmailRewardState then
		container:getVarNode("mContent1"):setVisible(false)
		container:getVarNode("mContent2"):setVisible(true)
		container:getVarNode("mContent3"):setVisible(false)
		container:getVarNode("mCancelNode"):setVisible(false)
		container:getVarNode("mConfirmationNode2"):setVisible(true)
		NodeHelper:setStringForLabel(container,{mConfirm = common:getLanguageString("@Confirmation")})
		container:getVarNode("mConfirmationNode1"):setVisible(false)
		container:getVarNode("mSuccessText"):setVisible(true)
		if shareType == shareTypeTab.successEmailRewardState then
			NodeHelper:setStringForLabel(container,{mSuccessText = common:getLanguageString("@shareSuccess")})
		else
			NodeHelper:setStringForLabel(container,{mSuccessText = common:getLanguageString("@shareSuccess")})
		end
	elseif shareType == shareTypeTab.errorState then
		if shareErrorMsg == "loginError" then
			NodeHelper:setStringForLabel(container,{mErrorText = common:getLanguageString("@loginError")})
		elseif shareErrorMsg == "shareError" then	
			NodeHelper:setStringForLabel(container,{mErrorText = common:getLanguageString("@shareError")})
		end
		container:getVarNode("mContent1"):setVisible(false)
		container:getVarNode("mContent2"):setVisible(false)
		container:getVarNode("mContent3"):setVisible(true)
		container:getVarNode("mCancelNode"):setVisible(true)
		container:getVarNode("mConfirmationNode2"):setVisible(false)
		NodeHelper:setStringForLabel(container,{mConfirm = common:getLanguageString("@reShare")})
		container:getVarNode("mConfirmationNode1"):setVisible(true)
	end
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		FacebookSharePage.editBox = NodeHelper:addEditBox(CCSize(500,50),container:getVarNode("mInputText"),function(eventType)
				if eventType == "began" then
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					FacebookSharePage.onEditBoxReturn(FacebookSharePage.editBox,FacebookSharePage.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-250,-125),common:getLanguageString("@shareInputprompt"))
		--FacebookSharePage.editBox:setMaxLength(70)
		NodeHelper:setMenuItemEnabled(container,"mFaceBookInput",false)
        NodeHelper:setNodesVisible(container, {mInputTextHint = false})
    else
       -- local contentLabel = container:getVarLabelTTF("mInputText")
	   -- contentLabel:setString(common:getLanguageString("@shareInputprompt"))
        NodeHelper:setStringForLabel(container, {mInputText = ""})
        NodeHelper:setStringForLabel(container, {mInputTextHint = common:getLanguageString("@shareInputprompt")})
	end
end

function FacebookSharePage.onExecute(container)
end

function FacebookSharePage.onExit(container)
	container:removeLibOS()
end
----------------------------------------------------------------

function FacebookSharePage.refreshPage(value)
	--[[	local noticeStr = common:getLanguageString("@MailNotice", TodoStr);
	NodeHelper:setStringForLabel(container, {mMailPromptTex = noticeStr});--]]
end

----------------click event------------------------
function FacebookSharePage.onClose(container)
	PageManager.popPage(thisPageName);
end

function FacebookSharePage_Show(picture,content,type,callBack,errorMsg)
    sharePicture = picture
    shareContent = content
    shareType = type
	shareCallBack = callBack
	shareErrorMsg = errorMsg
--BlackBoard:getInstance():hasVarible(key)
end
-------------------------------------------------------------------------
