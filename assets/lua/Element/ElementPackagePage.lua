
--元素神符背包



--endregion

local thisPageName = "ElementPackagePage"
local HP_pb = require("HP_pb")
local Element_pb = require("Element_pb")
local ElementManager = require("Element.ElementManager")
local BasePage = require("BasePage")
local ElementConfig = require("Element.ElementConfig")
local userElementMap = {}
local option = {
    ccbiFile = "ElementBackpackPage.ccbi",
    handlerMap = {
        onElementDecomposition  = "onElementDecomposition",
        onExpansionBackpack = "onExpansionBackpack",
        onReturn = "onReturn",
        onTabElement    = "onTabElement"
    }
}

local opcodes = {
    ELEMENT_BAG_EXTEND_C = HP_pb.ELEMENT_BAG_EXTEND_C,
    ELEMENT_BAG_EXTEND_S = HP_pb.ELEMENT_BAG_EXTEND_S
}
function onFunctionEx(eventName,container)
    
end
local ElementPackagePage = BasePage:new(option,thisPageName,onFunctionEx,opcodes)

local ITEM_COUNT_PER_LINE = 5;

--function ElementPackagePage:onEnter(container)
--    self:registerPacket(container)
--    self:refreshPage(container)
--end

local PageType = {
    ELEMENT = 1
}
local pageInfoType = 1
----------------------- scrollview --------------------------
local ElementPackageItem = {
    ccbiFile = "BackpackItem.ccbi"
}

function ElementPackageItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		ElementPackageItem.onRefreshItemView(container);
	elseif string.sub(eventName,1,6)=="onHand" then
        local index = string.sub(eventName,7,-1)
        index = tonumber(index)
        local contentId = container:getItemDate().mID;
	    local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;
        index = index + baseIndex 

        local itemInfo = userElementMap[index]
        ElementManager:setSelectedElement(itemInfo.id)
        require("ElementInfoPage")
        ElementInfoPage_setShowType(ElementManager.showType.package)
    end
end

function ElementPackageItem.onRefreshItemView(container)
    local NodeHelper = require("NodeHelper")
    local contentId = container:getItemDate().mID
	local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;

	for i = 1, ITEM_COUNT_PER_LINE do
		local index = baseIndex + i;
        NodeHelper:setNodesVisible(container,{["mPosition"..i]=true}) 
        if index <= #userElementMap then
            ElementPackageItem.newElementItem(container,i,index);
        else
            NodeHelper:setNodesVisible(container,{["mPosition"..i]=false}) 
        end
    end
end

function ElementPackageItem.newElementItem(container,position,nodeIndex)
    local Const_pb = require("Const_pb");
    local NodeHelper = require("NodeHelper");
	local index = nodeIndex;
	
	local elementItem = userElementMap[index]
    if elementItem == nil then return end
    local name = ElementManager:getNameById(elementItem.id)
    local lb2Str = {
        ["mName"..position] 	= common:getLanguageString("@MyLevel", elementItem.level)
    }
    NodeHelper:setStringForLabel(container, {["mNumber"..position]=""});
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, {["mPic"..position] = ElementManager:getIconById(elementItem.id)});
    NodeHelper:setQualityFrames(container, {["mHand"..position] = elementItem.quality});
    NodeHelper:setColor3BForLabel(container, {["mName"..position] = common:getColorFromConfig("Own")});
end

function ElementPackagePage:getPageInfo(container)
    
    self:refreshPage(container)
end

function ElementPackagePage:refreshPage(container)
    userElementMap =  ElementManager:getUnDressAndDressElementsMap()
    ElementManager:setSortOrder(false)
    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@ElementBackpack")});
    table.sort(userElementMap,ElementManager.sortByQualityScore)
    if IsThaiLanguage() then
        NodeHelper:MoveAndScaleNode(container,{mElementDecompositionTxt = common:getLanguageString("@ElementDecomposition")},0,0.65);
    end
    self:setTabSelected(container)
    self:refreshBagSize(container)
    
    self:rebuildAllItem(container)
end

function ElementPackagePage:refreshBagSize(container)
    local UserInfo = require("PlayerInfo.UserInfo")
    NodeHelper:setStringForLabel(container, {mBackpackCapacity = #userElementMap .. "/" .. UserInfo.stateInfo.elementBagSize})
    NodeHelper:setMenuItemEnabled( container,"mExpansionBut", true)
end

function ElementPackagePage:setTabSelected(container)
    local NodeHelper = require("NodeHelper");
	local isElementSelected = pageInfoType == PageType.ELEMENT;
	NodeHelper:setMenuItemSelected(container, {
		mTabElement	= isElementSelected,
	})
end;

function ElementPackagePage:onTabElement(container)
    self:changePageType(container, PageType.ELEMENT);
end

function ElementPackagePage:changePageType(container, targetType)
    if targetType ~= pageInfoType then
		pageInfoType = targetType;
		self:refreshPage(container);
		self:rebuildAllItem(container);
	else
		self:setTabSelected(container);
	end
end

function ElementPackagePage:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ElementPackagePage:clearAllItem(container)
    local NodeHelper = require("NodeHelper")
    NodeHelper:clearScrollView(container);
end

function ElementPackagePage:buildItem(container)
    local NodeHelper = require("NodeHelper")
    local count = #userElementMap
    local size = math.ceil(count / ITEM_COUNT_PER_LINE)

    NodeHelper:buildScrollView(container, size, ElementPackageItem.ccbiFile, ElementPackageItem.onFunction)
end

----click event
function ElementPackagePage:onElementDecomposition(container)
    PageManager.pushPage("ElementDecomposePage")
end

-- 扩展背包
function ElementPackagePage:onExpansionBackpack(container)
    local UserInfo = require("PlayerInfo.UserInfo");
	local title = common:getLanguageString("@BuyPackageTitle");
	local count = ElementManager:getConfigDataByKey("BuyPackageCount")
	local cost = ElementManager:getConfigDataByKey("BuyPackageCost")
	local timesCanBuy = (ElementConfig.BuyPackageMaxSize - UserInfo.stateInfo.elementBagSize) / 10
	local msg = common:getLanguageString("@BuyPackageMsg", count, cost, timesCanBuy);
	
	if timesCanBuy <= 0 then
		MessageBoxPage:Msg_Box_Lan("@PackageCannotExpand");
		return;
	end
	
	PageManager.showConfirm(title, msg, function(isSure)
		if isSure and UserInfo.isGoldEnough(cost,"ExpansionBackpack_enter_rechargePage") then
            NodeHelper:setMenuItemEnabled( container,"mExpansionBut", false)
            PageManager.popPage("DecisionPage")
			ElementManager:expandPackage();
		end
	end);
end

function ElementPackagePage:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == thisPageName then
            if extraParam == "refreshBagSize" then
			    self:refreshBagSize(container);
            end
            self:refreshPage(container)
		end
	end
end

function ElementPackagePage:onReturn(container)
    PageManager.changePage("EquipmentPage")
end