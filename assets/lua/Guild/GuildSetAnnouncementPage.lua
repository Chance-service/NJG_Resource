----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")
local thisPageName = 'GuildSetAnnouncementPage'
local GuildSetAnnouncementBase = {
	itemType = nil,
	announcementStr = "",
}
local Type = {
	Announcement = 2,
	Mail         = 4,
}

-- 公告字数限制
local GuildAnnouncementLengthLimit = 80--0
local onLineMaxCount = 20 --公告一行显示的文字上限

GuildSetAnnouncementCallback = nil

local option = {
	ccbiFile = "GuildSetAnnouncement.ccbi",
	handlerMap = {
		onCancel 			= 'onClose',
		onClose				= 'onClose',
		onConfirmation 	= 'onChange',
		onInput 		= 'onInputName',
		luaInputboxEnter 	= 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard"
	}
}

local contentInput = ''

function GuildSetAnnouncementBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildSetAnnouncementBase:onEnter(container)
	container:registerLibOS()
    contentInput = ""
	if Golb_Platform_Info.is_gNetop_platform then
		if self.itemType == Type.Announcement then 
			GuildAnnouncementLengthLimit = 80
			NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString('@SetAnnouncement')})
			NodeHelper:setStringForLabel(container, { mIntro = common:getLanguageString('@PleaseSetAnnouncement')})
			NodeHelper:setStringForLabel(container, { mSwitchAnnToMail = common:getLanguageString('@GuildAnnouncementSave')})
		elseif self.itemType == Type.Mail then 
			GuildAnnouncementLengthLimit = 40
			NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString('@SetMail')})
            NodeHelper:setNodeScale(container,"mTitle", 0.7, 0.7)
			NodeHelper:setStringForLabel(container, { mIntro = common:getLanguageString('@PleaseSetMail')})
			NodeHelper:setStringForLabel(container, { mSwitchAnnToMail = common:getLanguageString('@GuildMailSend')})
		end
	end
	self:refreshPage(container)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		local mAnnouncementTTF = container:getVarNode("mAnnouncement")
		--local color = container:getVarNode("mAnnouncement"):getColor()
        local inputTip = common:getLanguageString('@GuildNewAnnouncement')
        if self.itemType == Type.Announcement then 
            inputTip  = common:getLanguageString('@GuildNewAnnouncement')
        elseif self.itemType == Type.Mail then 
            inputTip  = common:getLanguageString('@MailExplain')
        end
		GuildSetAnnouncementBase.editBox = NodeHelper:addEditBox(CCSize(580,130),container:getVarNode("mAnnouncement"),function(eventType)
				if eventType == "began" then
                    NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
					GuildSetAnnouncementBase.onEditBoxReturn(container,GuildSetAnnouncementBase.editBox,GuildSetAnnouncementBase.editBox:getText())
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
                    NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
					GuildSetAnnouncementBase.onEditBoxReturn(container,GuildSetAnnouncementBase.editBox,GuildSetAnnouncementBase.editBox:getText(),true)
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					GuildSetAnnouncementBase.onEditBoxReturn(container,GuildSetAnnouncementBase.editBox,GuildSetAnnouncementBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-290,75),inputTip)
		--container:getVarNode("mAnnouncement"):setVisible(true)
		--local posX, posY = container:getVarNode("mAnnouncement"):getPosition()
		--GuildSetAnnouncementBase.editBox:setPosition(ccp(15*posX, posY + 120))
		GuildSetAnnouncementBase.editBox:setMaxLength(GuildAnnouncementLengthLimit)
        local color = StringConverter:parseColor3B("135 54 38")
        GuildSetAnnouncementBase.editBox:setFontColor(color)
        GuildSetAnnouncementBase.editBox:setFontSize(24)
        NodeHelper:setNodesVisible(container, {mAnnouncement = false})
        NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
		GuildSetAnnouncementBase.editBox:setText(self.announcementStr)
        local length = GameMaths:calculateStringCharacters(self.announcementStr)
        if length > 0 then
            NodeHelper:setNodesVisible(container, {mAnnouncementHint = false})
            --NodeHelper:setNodesVisible(container, {mAnnouncement = true})
        end
        --NodeHelper:setNodesVisible(container, {mAnnouncement = true})
		NodeHelper:setStringForTTFLabel(container, { mAnnouncement = GameMaths:stringAutoReturnForLua(self.announcementStr, onLineMaxCount, 0)})
		NodeHelper:setMenuItemEnabled(container,"mInput",false)
        
	else
        local  mAnnouncementTTF = container:getVarNode("mAnnouncement")
		if mAnnouncementTTF  then 
        	mAnnouncementTTF:setAnchorPoint(ccp(0,0.5))
        	mAnnouncementTTF:setPositionY(mAnnouncementTTF:getPositionY()-7)
        end
	end
end

function GuildSetAnnouncementBase:onExit(container)
	container:removeLibOS()
	GuildSetAnnouncementCallback = nil
	if Golb_Platform_Info.is_gNetop_platform then
		GuildSetMailCallback  = nil 
		self.itemType = nil
		contentInput = ''
	end
end

function GuildSetAnnouncementBase:refreshPage(container)
	if Golb_Platform_Info.is_gNetop_platform then
		if self.itemType == Type.Announcement then 
			NodeHelper:setStringForTTFLabel(container, { mAnnouncement = common:getLanguageString('@GuildNewAnnouncement')})
			NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@GuildNewAnnouncement')})
		elseif self.itemType == Type.Mail then 
			NodeHelper:setStringForTTFLabel(container, { mAnnouncement = common:getLanguageString('@GuildNewMail')})
			NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@MailExplain')})
            --NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@GuildNewAnnouncement')})
		end
		NodeHelper:setStringForTTFLabel(container, { mAnnouncement = ""})
	end
end

function GuildSetAnnouncementBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function GuildSetAnnouncementBase:onChange(container)
	if Golb_Platform_Info.is_gNetop_platform then
		if self.itemType == Type.Announcement then 
			GuildSetAnnouncementCallback(contentInput)
		elseif self.itemType == Type.Mail then
			GuildSetMailCallback(contentInput) 
		end
	else
		GuildSetAnnouncementCallback(contentInput)
	end
	PageManager.popPage(thisPageName)
end
function GuildSetAnnouncementBase.onEditBoxReturn(container,editBox,content,isChange)
	local length = GameMaths:calculateStringCharacters(content)
	if length > GuildAnnouncementLengthLimit then
		--editBox:setText("")
        MessageBoxPage:Msg_Box("@GuildAnnouncementTooLong")
		return
	elseif GameMaths:isStringHasUTF8mb4(content) then
		---editBox:setText("")
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
    end
    --邮件类型替换这几个字 不然解析出错
    if GuildSetAnnouncementBase.itemType == Type.Mail then
        content = content:gsub("&", "*")
        content = content:gsub("#", "*")
        content = content:gsub("<", "*")
        content = content:gsub(">", "*")
    end

	contentInput = RestrictedWord:getInstance():filterWordSentence(content);

	local str =GameMaths:stringAutoReturnForLua(contentInput, onLineMaxCount, 0)
	if not isChange then
        if Golb_Platform_Info.is_gNetop_platform then
            if GuildSetAnnouncementBase.itemType == Type.Mail then
                --str = contentInput
                --editBox:setText(contentInput)
            else
                --editBox:setText(contentInput)
            end
        else
            --editBox:setText(contentInput)
        end
    end
	NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str })
end
function GuildSetAnnouncementBase:onInputName(container)
    NodeHelper:setStringForLabel(container, {mAnnouncementHint = ""})
	libOS:getInstance():showInputbox(false,contentInput)
end
function GuildSetAnnouncementBase:InputDone(container)
    local content = container:getInputboxContent()
     if content == "" then 
        contentInput = ""
        NodeHelper:setStringForTTFLabel(container, { mAnnouncement = "" })
		if self.itemType == Type.Announcement then 
        	--NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@GuildNewAnnouncement')})
        else
            --NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = common:getLanguageString('@MailExplain')})
        end
        return 
    end
	local length = GameMaths:calculateStringCharacters(content)
	if length > GuildAnnouncementLengthLimit then
        MessageBoxPage:Msg_Box("@GuildAnnouncementTooLong")
		return
	elseif GameMaths:isStringHasUTF8mb4(content) then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
    end
	--[[
	if not RestrictedWord:getInstance():isStringOK(content) then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
	end
	--]]
     --邮件类型替换这几个字 不然解析出错
    if GuildSetAnnouncementBase.itemType == Type.Mail then
        content = content:gsub("&", "*")
        content = content:gsub("#", "*")
        content = content:gsub("<", "*")
        content = content:gsub(">", "*")
    end
	contentInput = RestrictedWord:getInstance():filterWordSentence(content);

	local str =GameMaths:stringAutoReturnForLua(contentInput, onLineMaxCount, 0)
	
	if Golb_Platform_Info.is_gNetop_platform then
		if self.itemType == Type.Mail then 
			--str = contentInput
			NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str})
			NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = "" })
			--NodeHelper:setCCHTMLLabelAutoFixPosition(container:getVarLabelTTF("mAnnouncement"), CCSize(520,48),str )
		else
            NodeHelper:setStringForTTFLabel(container, { mAnnouncementHint = ""})
			NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str })
            --NodeHelper:setStringForTTFLabel(container, { mAnnouncement = GameMaths:stringAutoReturnForLua(str, onLineMaxCount, 0)})
		end
	else
		NodeHelper:setStringForTTFLabel(container, { mAnnouncement = str})
	end
end

function GuildSetAnnouncementBase:luaonCloseKeyboard(container)
    --NodeHelper:cursorNode(container,"mAnnouncement",false)
end
function GuildSetAnnouncementBase:onInputboxEnter(container)
	self:InputDone(container)
    --NodeHelper:cursorNode(container,"mAnnouncement",true)
end
function GuildSetAnnouncementBase:setItemType(_itemType,_announcementStr)
	self.itemType = _itemType
	self.announcementStr = _announcementStr
end

local CommonPage = require('CommonPage')
local GuildSetAnnouncementPage = CommonPage.newSub(GuildSetAnnouncementBase, thisPageName, option)

return GuildSetAnnouncementBase