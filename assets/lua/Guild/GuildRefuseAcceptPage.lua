
----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")
local thisPageName = 'GuildRefuseAcceptPage'
local GuildRefuseAcceptBase = {
	callBack = nil,
}
local Type = {
	Announcement = 2,
	Mail         = 3,
}

-- 公告字数限制
local GuildRefuseLengthLimit = 20--0
local onLineMaxCount = 29 --公告一行显示的文字上限

GuildSetAnnouncementCallback = nil

local option = {
	ccbiFile = "GuildSetAnnouncement.ccbi",
	handlerMap = {
		onClose 			= 'onClose',
		onCancel 			= 'onClose',
		onConfirmation 	= 'onConfirmation',
		onInput 		= 'onInputName',
		luaInputboxEnter 	= 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard"
	}
}

local contentInput = ''

function GuildRefuseAcceptBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildRefuseAcceptBase:onEnter(container)
	container:registerLibOS()
    contentInput = ""

	NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString('@RefuseApplicationTitle')})
	NodeHelper:setStringForLabel(container, { mIntro = common:getLanguageString('@PleaseSetRefuse')})
	NodeHelper:setStringForLabel(container, { mSwitchAnnToMail = common:getLanguageString('@Confirmation')})
    NodeHelper:setStringForLabel(container, { mAnnouncementHint = common:getLanguageString('@DataHint')})

	self:refreshPage(container)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		--local color = container:getVarNode("mAnnouncement"):getColor()
		GuildRefuseAcceptBase.editBox = NodeHelper:addEditBox(CCSize(580,130),container:getVarNode("mAnnouncement"),function(eventType)
				if eventType == "began" then
                    NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
					GuildRefuseAcceptBase.onEditBoxReturn(container,GuildRefuseAcceptBase.editBox,GuildRefuseAcceptBase.editBox:getText())
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
                    NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
					GuildRefuseAcceptBase.onEditBoxReturn(container,GuildRefuseAcceptBase.editBox,GuildRefuseAcceptBase.editBox:getText(),true)
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					GuildRefuseAcceptBase.onEditBoxReturn(container,GuildRefuseAcceptBase.editBox,GuildRefuseAcceptBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-290,75),common:getLanguageString('@DataHint'))
		 container:getVarNode("mAnnouncement"):setVisible(true)
         local color = StringConverter:parseColor3B("135 54 38")
         GuildRefuseAcceptBase.editBox:setFontColor(color)
         GuildRefuseAcceptBase.editBox:setFontSize(24)
         --GuildRefuseAcceptBase.editBox:setText(self.announcementStr)
         NodeHelper:setNodesVisible(container, {mAnnouncement = false})
         NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
		--local posX, posY = container:getVarNode("mAnnouncement"):getPosition()
		--GuildRefuseAcceptBase.editBox:setPosition(ccp(-1000, -130))
		GuildRefuseAcceptBase.editBox:setMaxLength(20)
		NodeHelper:setMenuItemEnabled(container,"mInput",false)
--        local length = GameMaths:calculateStringCharacters(self.announcementStr)
--        if length > 0 then
--            NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
--        end
       
	end
end

function GuildRefuseAcceptBase:onExit(container)
	container:removeLibOS()
	GuildSetAnnouncementCallback = nil
	if Golb_Platform_Info.is_gNetop_platform then
		GuildSetMailCallback  = nil 
		self.itemType = nil
		contentInput = ''
	end
end

function GuildRefuseAcceptBase:refreshPage(container)
	if Golb_Platform_Info.is_gNetop_platform then
		NodeHelper:setStringForTTFLabel(container, { mAnnouncement = ""})
        NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = ""})
	end
end

function GuildRefuseAcceptBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function GuildRefuseAcceptBase:onConfirmation(container)
	if self.callBack then
		if contentInput == "" then
			contentInput = common:getLanguageString("@RefuseForNoReason")
		end
        
        contentInput = contentInput:gsub("&", "*")
        contentInput = contentInput:gsub("#", "*")
        contentInput = contentInput:gsub("<", "*")
        contentInput = contentInput:gsub(">", "*")

		self.callBack(contentInput)
	end
	PageManager.popPage(thisPageName)
end
function GuildRefuseAcceptBase.onEditBoxReturn(container,editBox,content,isChange)
	local length = GameMaths:calculateStringCharacters(content)
	if length > GuildRefuseLengthLimit then
		--editBox:setText("")
        MessageBoxPage:Msg_Box("@RefuseTooLong")
		return
	elseif GameMaths:isStringHasUTF8mb4(content) then
		editBox:setText("")
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
    end

	contentInput = RestrictedWord:getInstance():filterWordSentence(content);

	local str =GameMaths:stringAutoReturnForLua(contentInput, onLineMaxCount, 0)
	if not isChange then
        editBox:setText(contentInput)
    end
	NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str })
end
function GuildRefuseAcceptBase:onInputName(container)
	libOS:getInstance():showInputbox(false,contentInput)
end
function GuildRefuseAcceptBase:InputDone(container)
    local content = container:getInputboxContent()
    --[[if content == "" then 
        
        NodeHelper:setStringForTTFLabel(container, { mAnnouncement = "" })
        NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@GuildInputName')})
        return 
    end--]]
	local length = GameMaths:calculateStringCharacters(content)
	if length > GuildRefuseLengthLimit then
        MessageBoxPage:Msg_Box("@RefuseTooLong")
		return
	elseif GameMaths:isStringHasUTF8mb4(content) then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
    end

	contentInput = RestrictedWord:getInstance():filterWordSentence(content);

	local str =GameMaths:stringAutoReturnForLua(contentInput, onLineMaxCount, 0)
	
	NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = ""})
	NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str })
    NodeHelper:cursorNode(container,"mAnnouncement",true)
end

function GuildRefuseAcceptBase:luaonCloseKeyboard(container)
    NodeHelper:cursorNode(container,"mAnnouncement",false)
end
function GuildRefuseAcceptBase:onInputboxEnter(container)
	self:InputDone(container)
    NodeHelper:cursorNode(container,"mAnnouncement",true)
end
function GuildRefuseAcceptBase:setcallBack(_callBack)
	self.callBack = _callBack
end

local CommonPage = require('CommonPage')
local GuildSetAnnouncementPage = CommonPage.newSub(GuildRefuseAcceptBase, thisPageName, option)

return GuildRefuseAcceptBase