
----------------------------------------------------------------------------------

local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");

local thisPageName = "LanguageSwitchPopUp"

local option = {
	ccbiFile = "LanguageSwitchPopUp.ccbi",
	handlerMap = {
		onClose 		= "onClose" 
	},
	opcode = opcodes
};

local LanguageSwitchPopUpBase = {}

local PageInfo = {
	ONE_LINE_COUNT = 3,
	LanguageSupportList = {}
}

local i18nPlatformCfg = ConfigManager.getI18nPlatformCfg()
local i18nCfg = ConfigManager.getI18nTxtCfg()

--RechargePlatformNames = {}
--------------------------------------------------------------
local LanguageSwitchContentItem = {
	ccbiFile 	= "LanguageSwitchContentItem.ccbi"
}

function LanguageSwitchContentItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		LanguageSwitchContentItem.onRefreshItemView(container)
	end
end

function LanguageSwitchContentItem.onRefreshItemView(container)
	local contentId = container:getItemDate().mID
	local baseIndex = (contentId - 1) * PageInfo.ONE_LINE_COUNT
	--local baseIndex = contentId * PageInfo.ONE_LINE_COUNT
	for i = 1, PageInfo.ONE_LINE_COUNT do
		local nodeContainer = container:getVarNode("mPositionNode" .. i)
		NodeHelper:setNodeVisible(nodeContainer, false)
		nodeContainer:removeAllChildren()
		
		local itemNode = nil
		local index = baseIndex + i
		--#PageInfo.personList
		if index <= #PageInfo.LanguageSupportList then
			itemNode = LanguageSwitchContentItem.newLineItem(index)
		end	
		
		if itemNode then
			nodeContainer:addChild(itemNode)
			NodeHelper:setNodeVisible(nodeContainer, true)
		end
	end
end

function LanguageSwitchContentItem.newLineItem( index )
	local itemNode = ScriptContentBase:create("LanguageSwitchContent.ccbi", index)
	itemNode:registerFunctionHandler(LanguageSwitchContentItem.onInit)	
	
	local languageType = PageInfo.LanguageSupportList[index]
	local langTitle = ConfigManager.getI18nAttrByType(languageType, "languageTitle") or ""
	if langTitle ~= "" then
		langTitle = common:getLanguageString(langTitle)
	end

	local isNow = false
	if languageType == common:getSelfI18nLanguageType() then
		isNow = true
	end

	NodeHelper:setNodesVisible(itemNode, {mBtnUseNode = not isNow, mUsing = isNow})
	NodeHelper:setStringForLabel(itemNode, {mCommodityName = langTitle})

	local langPic = ConfigManager.getI18nAttrByType(languageType, "icon") or ""
	if langPic ~= "" then
		langPic = "UI/Program/Icon/"..langPic
		NodeHelper:setSpriteImage(itemNode, {mPic = langPic})
	end

	itemNode:release()
	
	return itemNode
end

function LanguageSwitchContentItem.onInit(eventName , container)
	if eventName == "onbuy" then
		local index = container:getTag()
		CCLuaLog("on use language"..index)
		local languageType = PageInfo.LanguageSupportList[index]
		local langTitle = ConfigManager.getI18nAttrByType(languageType, "languageTitle") or ""
		if langTitle ~= "" then
			langTitle = common:getLanguageString(langTitle)
		end
		local titile = ""
		local tipinfo = common:getLanguageString("@LanguageSwitchConfirm", langTitle);
		PageManager.showConfirm(titile,tipinfo, function(isSure)
			if isSure then
				CCLuaLog("begin to switch language to "..langTitle.." languageType = "..languageType)
				GamePrecedure:getInstance():setUserDefaultI18nSrcPath(languageType)
				libOS:getInstance():requestRestart();
			end
		end);
	end
end

----------------------------------------------------------------------------------
	
-----------------------------------------------
--LanguageSwitchPopUpBase页面中的事件处理
----------------------------------------------
function LanguageSwitchPopUpBase:onEnter(container)
	NodeHelper:initScrollView(container, "mContent", 3)
	
	local platformName = GamePrecedure:getInstance():getPlatformName()
	for k,v in pairs(i18nPlatformCfg) do
		if v.LanguageTypeList ~= nil and v.PlatformName == platformName then
			PageInfo.LanguageSupportList = v.LanguageTypeList
		end
	end

	self:refreshPage( container )
end

function LanguageSwitchPopUpBase:refreshPage( container )	
	self:rebuildAllItem(container)
end

function LanguageSwitchPopUpBase:onExit(container)
	NodeHelper:deleteScrollView(container);
end

----------------------------------------------------------------

----------------scrollview-------------------------
function LanguageSwitchPopUpBase:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function LanguageSwitchPopUpBase:clearAllItem(container)
	NodeHelper:clearScrollView(container);
end

function LanguageSwitchPopUpBase:buildItem(container)
    local size = math.ceil(#PageInfo.LanguageSupportList / PageInfo.ONE_LINE_COUNT)
	NodeHelper:buildScrollView(container,size, LanguageSwitchContentItem.ccbiFile, LanguageSwitchContentItem.onFunction);
end
	
----------------click event------------------------
function LanguageSwitchPopUpBase:onClose(container)
	PageManager.popPage(thisPageName);
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local LanguageSwitchPopUpBase = CommonPage.newSub(LanguageSwitchPopUpBase, thisPageName, option)
LanguageSwitchPopUpBase = nil
