----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local GuildDataManager = require("Guild.GuildDataManager")
local thisPageName = 'GuildSearchPopPage'
local GuildSearchBase = {}

-- 搜索id最大值，与后端一致
local GuildSearchIdMax = 100000000

local option = {
	ccbiFile = "CDKeyPopUp.ccbi",
	handlerMap = {
		onCancel 		= 'onClose',
		onConfirmation 	= 'onGuildSearch',
		onInput 		= 'onInput',
		luaInputboxEnter = 'onInputboxEnter',
		luaonCloseKeyboard   = "luaonCloseKeyboard",
        onClose             = "onClose",
	}
}

local idInput = ''

function GuildSearchBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildSearchBase:onEnter(container)
	container:registerLibOS()
	
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		GuildSearchBase.editBox = NodeHelper:addEditBox(CCSize(470,200),container:getVarNode("mCDKey"),function(eventType)
				if eventType == "began" then
					--NodeHelper:cursorNode(container,"mCDKey",true)
					NodeHelper:setStringForLabel(container, { mCDKeyHint = ""})
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
					GuildSearchBase.onEditBoxReturn(container,GuildSearchBase.editBox,GuildSearchBase.editBox:getText())
					--NodeHelper:cursorNode(container,"mCDKey",false)
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
					GuildSearchBase.onEditBoxReturn(container,GuildSearchBase.editBox,GuildSearchBase.editBox:getText(),true)
					--NodeHelper:cursorNode(container,"mCDKey",true)
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					GuildSearchBase.onEditBoxReturn(container,GuildSearchBase.editBox,GuildSearchBase.editBox:getText())
					--GuildSearchBase.onEditBoxReturn(GuildSearchBase.editBox,GuildSearchBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-235,0),common:getLanguageString('@GuildInputSearchContent'))
		GuildSearchBase.editBox:setMaxLength(10)
		--container:getVarNode("mCDKey"):setPosition(ccp(0,36))
		--container:getVarNode("mCDKey"):setAnchorPoint(ccp(0.5,0.5))
        --container:getVarNode("mCDKey"):setAnchorPoint(ccp(0.5, 0.5))
        container:getVarNode("mCDKey"):setVisible(false)
        local color = StringConverter:parseColor3B("135 54 38")
        GuildSearchBase.editBox:setFontColor(color)
		--container:getVarNode("mCDKey"):setVisible(true)
		NodeHelper:setMenuItemEnabled(container,"mInput",false)
		--container:getVarNode("mCDKeyHint"):setPosition(ccp(0,36))
		--container:getVarNode("mCDKeyHint"):setAnchorPoint(ccp(0.5,0.5))
        container:getVarLabelTTF("mCDKeyHint"):setVisible(false)
	end
	self:refreshPage(container)
end

function GuildSearchBase:onExit(container)
	container:removeLibOS()
end

function GuildSearchBase:refreshPage(container)
	local lb2Str = {
		mTitle = common:getLanguageString('@GuildSearch'),
		mSearchTex = common:getLanguageString('@GuildSearchExplain'),
		mYes = common:getLanguageString('@GuildSearch'),
	}
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setStringForLabel(container, { mCDKeyHint = common:getLanguageString('@GuildInputSearchContent')})
end

function GuildSearchBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function GuildSearchBase:onGuildSearch(container)
	if common:trim(idInput) == '' then
		MessageBoxPage:Msg_Box('@GuildSearchNoContent')
		return
	end
	GuildDataManager:sendSearchGuildPacket(tonumber(idInput))
	PageManager.popPage(thisPageName)
end
function GuildSearchBase.onEditBoxReturn(container,editBox,content,isChange)
    NodeHelper:setStringForLabel(container, { mCDKey = content })
	if (not tonumber(content)) then
		return
	end
	local inputNumber = math.floor(tonumber(content))
	-- 检查id合法性
	if common:trim(content) == '' then
		MessageBoxPage:Msg_Box('@GuildSearchNoContent')
		return
	elseif (not inputNumber) or (inputNumber >= GuildSearchIdMax) then
		MessageBoxPage:Msg_Box('@GuildInputSearchNumber')
		return 
	end

	idInput = content
	if editBox and not isChange then
		editBox:setText(idInput)
	end
	NodeHelper:setStringForLabel(container, { mCDKey = idInput })
	NodeHelper:setStringForLabel(container, { mCDKeyHint = ""})
end
function GuildSearchBase:onInput(container)
	--libOS:getInstance():showInputbox(false,"")
    libOS:getInstance():showInputbox(false,2,"")--2 数字键盘
    NodeHelper:cursorNode(container,"mCDKey",true)
end
function GuildSearchBase:luaonCloseKeyboard(container)
     NodeHelper:cursorNode(container,"mCDKey",false)
end
function GuildSearchBase:onInputboxEnter(container)
	local content = container:getInputboxContent()

	if (not tonumber(content)) then
       if idInput then 
            --libOS:getInstance():setEditBoxText(idInput);
            idInput = ""
            NodeHelper:setStringForLabel(container, { mCDKey = "",mCDKeyHint = "" })
            NodeHelper:cursorNode(container,"mCDKey",true)
        end
		return
	end
	local inputNumber = math.floor(tonumber(content))

	-- 检查id合法性
	if common:trim(content) == '' then
        NodeHelper:setStringForLabel(container, { mCDKey = "",mCDKeyHint = "" })
        NodeHelper:cursorNode(container,"mCDKey",true)
		MessageBoxPage:Msg_Box('@GuildSearchNoContent')
		return
	elseif (not inputNumber) or (inputNumber >= GuildSearchIdMax) then
        libOS:getInstance():setEditBoxText(idInput);
		MessageBoxPage:Msg_Box('@GuildInputSearchNumber')
		return 
	end

	idInput = tostring(inputNumber)
	NodeHelper:setStringForLabel(container, { mCDKey = idInput,mCDKeyHint = "" })
    NodeHelper:cursorNode(container,"mCDKey",true)
end


local CommonPage = require('CommonPage')
local GuildSearchPopPage= CommonPage.newSub(GuildSearchBase, thisPageName, option)
