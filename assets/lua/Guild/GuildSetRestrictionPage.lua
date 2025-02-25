----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local thisPageName = 'GuildSetRestrictionPage'
local GuildSetRestrictionBase = {}

-- 最大输入战力限制
local GuildBattlePointLimit = 9999999

GuildSetRestrictionCallback = nil

local option = {
	ccbiFile = "GuildSetRestriction.ccbi",
	handlerMap = {
		onCancel 			= 'onClose',
		onClose				= 'onClose',
		onConfirmation 	= 'onChange',
		onInput 		= 'onInputName',
		luaInputboxEnter 	= 'onInputboxEnter',
        luaonCloseKeyboard = "luaonCloseKeyboard",
		onChoicePosition		= 'onChoicePosition'
	}
}

local contentInput = ''
local isSetMail = false	--是否邮件通知加入公会
local checkButton = 0

function GuildSetRestrictionBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildSetRestrictionBase:onEnter(container)
	container:registerLibOS()
    contentInput = ""
	local joinLimit = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.battleLimit or 0
	local check = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.hasCheckButton or 0
	contentInput = joinLimit
	checkButton = check
	self:refreshPage(container)
	if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
		--local color = container:getVarNode("mRestriction"):getColor()
		GuildSetRestrictionBase.editBox = NodeHelper:addEditBox(CCSize(500,50),container:getVarNode("mRestriction"),function(eventType)
				if eventType == "began" then
					--NodeHelper:cursorNode(container,"mRestriction",true)
                    NodeHelper:setStringForLabel(container, { mRestrictionHint = ""})
				 -- triggered when an edit box gains focus after keyboard is shown
				elseif eventType == "ended" then
					GuildSetRestrictionBase.onEditBoxReturn(container,GuildSetRestrictionBase.editBox,GuildSetRestrictionBase.editBox:getText())
					--NodeHelper:cursorNode(container,"mRestriction",false)
				 -- triggered when an edit box loses focus after keyboard is hidden.
				elseif eventType == "changed" then
					GuildSetRestrictionBase.onEditBoxReturn(container,GuildSetRestrictionBase.editBox,GuildSetRestrictionBase.editBox:getText(),true)
					--NodeHelper:cursorNode(container,"mRestriction",true)
				 -- triggered when the edit box text was changed.
				elseif eventType == "return" then
					GuildSetRestrictionBase.onEditBoxReturn(container,GuildSetRestrictionBase.editBox,GuildSetRestrictionBase.editBox:getText())
				 -- triggered when the return button was pressed or the outside area of keyboard was touched.
				end
			end,ccp(-235,0),common:getLanguageString('@InputRestriction'))
		local color = StringConverter:parseColor3B("135 54 38")
        GuildSetRestrictionBase.editBox:setFontColor(color)
		--GuildSetRestrictionBase.editBox:setFontColor(color)
		--GuildSetRestrictionBase.editBox:setPlaceholderFontColor(color)
		--GuildSetRestrictionBase.editBox:setMaxLength(70)
		GuildSetRestrictionBase.editBox:setMaxLength(7)
		--container:getVarNode("mRestriction"):setPosition(ccp(0,-170))
		--container:getVarNode("mRestriction"):setAnchorPoint(ccp(0.5,0.5))
		--container:getVarNode("mRestriction"):setVisible(false)
		NodeHelper:setNodesVisible(container, {mRestrictionHint = false,mRestriction = false})
		if contentInput ~= 0 then
			GuildSetRestrictionBase.editBox:setText(contentInput)
			NodeHelper:setStringForLabel(container, { mRestriction = contentInput })
			NodeHelper:setStringForLabel(container, { mRestrictionHint = ""})
		else
			NodeHelper:setStringForLabel(container, { mRestriction = "" })
			NodeHelper:setStringForLabel(container, { mRestrictionHint = common:getLanguageString('@InputRestriction')})
		end
		NodeHelper:setMenuItemEnabled(container,"mInput",false)
		--container:getVarNode("mRestrictionHint"):setPosition(ccp(0,-170))
		--container:getVarNode("mRestrictionHint"):setAnchorPoint(ccp(0.5,0.5))
       
	end
end

function GuildSetRestrictionBase:onExit(container)
	container:removeLibOS()
	GuildSetRestrictionCallback = nil
end

function GuildSetRestrictionBase:refreshPage(container)
	NodeHelper:setStringForLabel(container, { mRestrictionHint = common:getLanguageString('@InputRestriction')})
    --NodeHelper:setStringForLabel(container, { mRestriction = common:getLanguageString("")})
	NodeHelper:setStringForLabel(container, { mRestriction = contentInput })
	self:setChoicePosition(container,checkButton)
end

function GuildSetRestrictionBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function GuildSetRestrictionBase:setChoicePosition(container,isCheck)
	local selectPic = container:getVarSprite("mAutoFightSprite")
	if selectPic then
		if isCheck == 1 then
			selectPic:setVisible(true)
		else
			selectPic:setVisible(false)
		end
	end
end
function GuildSetRestrictionBase:onChoicePosition(container)
	checkButton = 1 - checkButton
	self:setChoicePosition(container,checkButton)
end

function GuildSetRestrictionBase:onChange(container)
	if common:trim(contentInput) == '' then
		--MessageBoxPage:Msg_Box('@RestrictionEmpty')
		contentInput = 0
	--	return
	end
	GuildSetRestrictionCallback(tonumber(contentInput),tonumber(checkButton))
	PageManager.popPage(thisPageName)
end
function GuildSetRestrictionBase.onEditBoxReturn(container,editBox,content,isChange)
    if common:trim(content) == '' then
        contentInput = ""
        --NodeHelper:setStringForLabel(container, { mRestrictionHint = common:getLanguageString('@InputRestriction')})
        NodeHelper:setStringForLabel(container, { mRestriction = "" })
        if editBox and not isChange then
            editBox:setText("")
        end
        return
    end
	if not tonumber(content) then return end
	local inputNumber = math.floor(tonumber(content))
	if inputNumber < 0 then return end
	if common:trim(content) == '' then
		MessageBoxPage:Msg_Box('@RestrictionEmpty')
		NodeHelper:setStringForLabel(container, { mRestrictionHint = common:getLanguageString('@InputRestriction')})
		--return
	elseif (not inputNumber) or (inputNumber > GuildBattlePointLimit) then
		MessageBoxPage:Msg_Box(common:getLanguageString('@GuildRestrictTooLarge', GuildBattlePointLimit))
		return
	end

	contentInput = content
	if editBox and not isChange then
		editBox:setText(contentInput)
	end
	NodeHelper:setStringForLabel(container, { mRestriction = contentInput })
	NodeHelper:setStringForLabel(container, { mRestrictionHint = ""})
end
function GuildSetRestrictionBase:onInputName(container)
	libOS:getInstance():showInputbox(false,contentInput)
end

function GuildSetRestrictionBase:onInputboxEnter(container)
	self:InputDone(container);
    NodeHelper:cursorNode(container,"mRestriction",true)
end
function GuildSetRestrictionBase:luaonCloseKeyboard(container)
     NodeHelper:cursorNode(container,"mRestriction",false)
end
function GuildSetRestrictionBase:InputDone(container)
    local content = container:getInputboxContent()
    
    if content == "" then
        contentInput = ""
        NodeHelper:setStringForLabel(container, { mRestrictionHint = common:getLanguageString('@InputRestriction')})
        NodeHelper:setStringForLabel(container, { mRestriction = common:getLanguageString("")})
        return 
    end
	if not tonumber(content) then return end
	local inputNumber = math.floor(tonumber(content))
  
	if common:trim(content) == '' then
		MessageBoxPage:Msg_Box('@RestrictionEmpty')
		return
	elseif (not inputNumber) or (inputNumber > GuildBattlePointLimit) then
		MessageBoxPage:Msg_Box(common:getLanguageString('@GuildRestrictTooLarge', GuildBattlePointLimit))
		return
	end

	contentInput = content
    NodeHelper:setNodesVisible(container, {mRestrictionHint = false})
	NodeHelper:setStringForLabel(container, { mRestriction = contentInput })
    NodeHelper:setStringForLabel(container, { mRestrictionHint = ""})
    
end

local CommonPage = require('CommonPage')
local GuildSetRestrictionPage = CommonPage.newSub(GuildSetRestrictionBase, thisPageName, option)
