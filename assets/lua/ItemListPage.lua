
----------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local ceil = math.ceil;
--------------------------------------------------------------------------------
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb");
local GemCompoundManager = require("Activity.GemCompoundManager")

local thisPageName = "ItemListPage";

local ITEM_COUNT_PER_LINE = 5;

local option = {
	ccbiFile = "Act_GemworkShopPopUp.ccbi",
	handlerMap = {
		onHelp			= "onHelp",
		onClose			= "onClose",
		onConfirmation	= "onConfirm"
	}
};

local ItemListPageBase = {}

local NodeHelper = require("NodeHelper");
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
local EquipOprHelper = require("Equip.EquipOprHelper");

local thisResList = {};
--------------------------------------------------------------
local ResItem = {
	ccbiFile = "GeneralDecisionPopUp3Item.ccbi",
};
local ResItemSub = {
	ccbiFile = "GoodsItem.ccbi",
}

function ResItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		ResItem.onRefreshItemView(container);
	end
end	

function ResItemSub.onFunction( eventName, container )
	if eventName == "onHand" then
		ResItemSub.onHand(container)
	end
end

function ResItem.onRefreshItemView(container)
	local contentId = container:getItemDate().mID;
	local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;

	for i = 1, ITEM_COUNT_PER_LINE do
		local nodeContainer = container:getVarNode(string.format("mPositionNode%d", i));
		NodeHelper:setNodeVisible(nodeContainer, false);
		nodeContainer:removeAllChildren();
		
		local index = baseIndex + i;
		if thisResList[index] then
			local itemNode = ResItem.newItem(index);
			nodeContainer:addChild(itemNode);
			itemNode:setPosition(CCPointMake(0, 0));
			NodeHelper:setNodeVisible(nodeContainer, true);
		end
	end
end

function ResItem.newItem(index)
	local resCfg = thisResList[index];
	local itemNode = ScriptContentBase:create(ResItemSub.ccbiFile, index);
	itemNode:registerFunctionHandler(ResItemSub.onFunction)
	resCfg = UserItemManager:getUserItemByItemId(resCfg)
	local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, resCfg.itemId, resCfg.count);
	local lb2Str = {
		mName 	= resInfo.name,
		mNumber	= "x" .. resInfo.count
	};
	NodeHelper:setStringForLabel(itemNode, lb2Str);
	NodeHelper:setSpriteImage(itemNode, {mPic = resInfo.icon});
	NodeHelper:setQualityFrames(itemNode, {mHand = resInfo.quality});
	NodeHelper:setColor3BForLabel(itemNode, {mName = common:getColorFromConfig("Own")});

	itemNode:release();
	return itemNode;
end	

function ResItemSub.onHand(container)
	local itemIndex = container:getTag()
	GemCompoundManager.nowSelectGem = thisResList[itemIndex]
	CCLuaLog("***************** gem itemId is " .. thisResList[itemIndex])
	PageManager.refreshPage("GemCompoundPage")
	PageManager.popPage(thisPageName);
end
----------------------------------------------------------------------------------
	
-----------------------------------------------
--ItemListPageBase页面中的事件处理
----------------------------------------------
function ItemListPageBase:onEnter(container)
	thisResList = GemCompoundManager:getLevelThrToNineGem()
	NodeHelper:initScrollView(container, "mContent", 3);
	
	self:rebuildAllItem(container);
end

function ItemListPageBase:onExit(container)
	NodeHelper:deleteScrollView(container);
	self:clearCache();
end

----------------------------------------------------------------
function ItemListPageBase:clearCache()
	thisResList = {};
end

----------------scrollview-------------------------
function ItemListPageBase:rebuildAllItem(container)
	self:clearAllItem(container);
	if #thisResList > 0 then
		self:buildItem(container);
	end
end

function ItemListPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container);
end

function ItemListPageBase:buildItem(container)
	local size = math.ceil(#thisResList / ITEM_COUNT_PER_LINE);
	NodeHelper:buildScrollView(container, size, ResItem.ccbiFile, ResItem.onFunction);
end
	
----------------click event------------------------
function ItemListPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

function ItemListPageBase:onConfirm(container)
	if thisCallback then
		thisCallback();
	end
	self:onClose();
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
ItemListPage = CommonPage.newSub(ItemListPageBase, thisPageName, option)
