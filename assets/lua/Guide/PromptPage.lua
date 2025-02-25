local thisPageName = "PromptPage"

local HelpConfg = {}
local option = {
	ccbiFile = "GeneralHelpPopUp2.ccbi",
	handlerMap = {
		onClose 		= "onClose"
	},
	opcode = opcodes
};

local HelpPageBase = {}

local TodoStr = "99";
local TodoImage = "UI/MainScene/UI/u_ico000.png";
local TodoPoster = "person/poster_char_Boss.png";
local helpTitle = ""

--------------------------------------------------------------
local HelpItem = {}

function HelpItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		HelpItem.onRefreshItemView(container)		
	end
end

function HelpItem.onRefreshItemView(container)
end


function HelpItem.showEnergyCoreInfo(container, resIndex)
	
end

function HelpPageBase:onEnter(container)
    local NodeHelper = require("NodeHelper");
	if  HelpConfg == nil or #HelpConfg == 0 then
		self:onClose(container)
		return
	end
	if helpTitle == nil or helpTitle == "" then
	    helpTitle = Language:getInstance():getString("@HintTitle")
	end
	NodeHelper:initScrollView(container, "mContent", 1);
	self:refreshPage(container);
	self:rebuildAllItem(container);
	
	container:getVarLabelBMFont("mTitle"):setString(helpTitle)
end

function HelpPageBase:onExecute(container)
end

function HelpPageBase:onExit(container)
    local NodeHelper = require("NodeHelper");
	NodeHelper:deleteScrollView(container)
	HelpConfg = {}
end
----------------------------------------------------------------

function HelpPageBase:refreshPage(container)
    local NodeHelper = require("NodeHelper");
	local noticeStr = common:getLanguageString("@MailNotice", "");
	NodeHelper:setStringForLabel(container, {mMailPromptTex = noticeStr});
end
----------------scrollview-------------------------
function HelpPageBase:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function HelpPageBase:clearAllItem(container)
    local NodeHelper = require("NodeHelper");
	NodeHelper:clearScrollView(container);
end

function HelpPageBase:buildItem(container)
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0

	for i=#HelpConfg, 1, -1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create("GeneralHelpContent.ccbi")
            pItem.id = iCount
			pItem:registerFunctionHandler(HelpItem.onFunction)
			
			local itemHeight = 0
			
			local nameNode = pItem:getVarLabelBMFont("mLabel")
			CCLuaLog("html -------star")
			local cSize = NodeHelper:setCCHTMLLabelDefaultPos( nameNode , CCSize(600,200) , HelpConfg[i].content  ):getContentSize()
			if fOneItemHeight < cSize.height then
				fOneItemHeight = cSize.height 
			end
        
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end

	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount )
	container.mScrollView:setContentSize(size)
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end
function Prompt_SetConfig( key ,title )
	HelpConfg = ConfigManager.getHelpCfg( key )
	helpTitle = title
end	
----------------click event------------------------
function HelpPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local HelpPage = CommonPage.newSub(HelpPageBase, thisPageName, option);