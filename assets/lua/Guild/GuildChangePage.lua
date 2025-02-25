
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local GuildDataManager = require("Guild.GuildDataManager")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'GuildChangePage'

local GuildCreateBase = {}

-- 公会名称字数
local GuildNameLeast = 2
local GuildNameMost = 6

local option = {
	ccbiFile = "ChangeNamePopUp.ccbi",
	handlerMap = {
		onCancel 			= 'onClose',
		onClose             = "onClose",
		onConfirmation 	= 'onCreateAlliance',
		onInPutBtn 		= 'onInputName',
		luaInputboxEnter 	= 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard"
	}
}

local nameInput = ''

function GuildCreateBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildCreateBase:onEnter(container)
	container:registerLibOS()
	self:refreshPage(container)
    nameInput = ""
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		GuildCreateBase.editBox = NodeHelper:addEditBox(CCSize(470,40),container:getVarNode("mDecisionTex"),function(eventType)
				if eventType == "began" then
					NodeHelper:cursorNode(container,"mDecisionTex",true)
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
					GuildCreateBase.onEditBoxReturn(container,GuildCreateBase.editBox,GuildCreateBase.editBox:getText())
                    NodeHelper:cursorNode(container,"mDecisionTex",false)
                    NodeHelper:setNodesVisible(container, {mDecisionTexHint = false})
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
					GuildCreateBase.onEditBoxReturn(container,GuildCreateBase.editBox,GuildCreateBase.editBox:getText(),true)
					NodeHelper:setNodesVisible(container, {mDecisionTexHint = false})
                    --NodeHelper:cursorNode(container,"mDecisionTex",true)
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					GuildCreateBase.onEditBoxReturn(container,GuildCreateBase.editBox,GuildCreateBase.editBox:getText())
					--GuildCreateBase.onEditBoxReturn(GuildCreateBase.editBox,GuildCreateBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-235,0),common:getLanguageString('@GuildInputName'))
		container:getVarNode("mDecisionTex"):setVisible(false)
		container:getVarNode("mDecisionTex"):setPosition(ccp(0,-340))
		container:getVarNode("mDecisionTex"):setAnchorPoint(ccp(0.5,0.5))
		
		NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })
        local color = StringConverter:parseColor3B("135 54 38")
        GuildCreateBase.editBox:setFontColor(color)

		GuildCreateBase.editBox:setMaxLength(GuildNameMost)
		GuildCreateBase.editBox:setText("")
		NodeHelper:setMenuItemEnabled(container,"mInputBtn",false)
        NodeHelper:setNodesVisible(container, {mDecisionTexHint = false})
	end
end

function GuildCreateBase:onExit(container)
	container:removeLibOS()
end

function GuildCreateBase:refreshPage(container)
	local lb2Str = {
		mDecisionTex = common:getLanguageString(''),
		mDecisionTexHint = common:getLanguageString('@GuildInputName'),
		mDes = common:getLanguageString('@GuildChangeNameDesc'),
		mTitle = common:getLanguageString("@GuildChangeNameTitle")
	}
	NodeHelper:setStringForLabel(container, lb2Str)

    local visibleMap = {
        mChangeNameNode = false
    }
    NodeHelper:setNodesVisible(container, visibleMap)
end

function GuildCreateBase:onClose(container)
	PageManager.popPage(thisPageName)
end

-- 创建按钮响应：使用输入的nameInput来调用回调函数，发送协议包
function GuildCreateBase:onCreateAlliance(container)
	if common:trim(nameInput) == '' then
		MessageBoxPage:Msg_Box('@GuildNameEmpty')
		return
	end
    PageManager.showConfirm(common:getLanguageString('@HintTitle'),
							common:getLanguageString('@ChangeGuildNameConfirm'),
							function (confirm)
								if confirm then
                                    GuildDataManager:changeAllianceName(nameInput)
	                                PageManager.popPage(thisPageName)
								end
							end
	)
	
end
function GuildCreateBase.onEditBoxReturn(container,editBox,content,isChange)
	if common:trim(content) == '' then
        --g_UserName = ""
        NodeHelper:setStringForLabel(container, { mDecisionTex = "" })
        if editBox and not isChange then
            editBox:setText("")
        end
        return
    end
	local length = GameMaths:calculateStringCharacters(content)
	if  length > GuildNameMost then
		MessageBoxPage:Msg_Box(common:getLanguageString('@GuildNamLengthError', GuildNameLeast, GuildNameMost))
		return
	elseif GameMaths:isStringHasUTF8mb4(content) then
		MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
	elseif (not RestrictedWord:getInstance():isStringOK(content)) then
		MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
	end
	nameInput = content
	if editBox ~= nil and not isChange then		
		editBox:setText(nameInput)
	end
	NodeHelper:setStringForTTFLabel(container, { mDecisionTex = tostring(nameInput) })
end
function GuildCreateBase:onInputName(container)
    if nameInput == "" then
        NodeHelper:setStringForLabel(container, {mDecisionTexHint = common:getLanguageString("@GuildInputName")})
    else
        NodeHelper:setStringForLabel(container, {mDecisionTexHint = ""})
    end
	libOS:getInstance():showInputbox(false,nameInput)
end
function GuildCreateBase:luaonCloseKeyboard(container)
     NodeHelper:cursorNode(container,"mDecisionTex",false)
end
function GuildCreateBase:InputDone(container)
    local content = container:getInputboxContent()
    if content == "" then 
        nameInput = ""
        NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })
        NodeHelper:setStringForTTFLabel(container, { mDecisionTexHint = common:getLanguageString('@GuildInputName')})
        return 
    end
	local length = GameMaths:calculateStringCharacters(content)
	if  length < GuildNameLeast or length > GuildNameMost then
		MessageBoxPage:Msg_Box(common:getLanguageString('@GuildNamLengthError', GuildNameLeast, GuildNameMost))
        if length > GuildNameMost then
            content = GameMaths:getStringSubCharacters(content,0,GuildNameMost)
        end
	elseif GameMaths:isStringHasUTF8mb4(content) then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
	elseif (not RestrictedWord:getInstance():isStringOK(content)) then
        MessageBoxPage:Msg_Box("@NameHaveForbbidenChar")
		return
	end
	nameInput = content
	NodeHelper:setStringForTTFLabel(container, { mDecisionTex = nameInput })
    NodeHelper:setStringForTTFLabel(container, { mDecisionTexHint = ""})
end
function GuildCreateBase:onInputboxEnter(container)
	self:InputDone(container);
    NodeHelper:cursorNode(container,"mDecisionTex",true)
end

local CommonPage = require('CommonPage')
local GuildChangePage = CommonPage.newSub(GuildCreateBase, thisPageName, option)
