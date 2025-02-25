----------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local ceil = math.ceil
--------------------------------------------------------------------------------
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local thisPageName = "ResListPage"

local ITEM_COUNT_PER_LINE = 5

local option = {
    ccbiFile = "GeneralDecisionPopUp3.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onClose = "onClose",
        onConfirmation = "onConfirm"
    }
}

local ResListPageBase = { }

local NodeHelper = require("NodeHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local EquipOprHelper = require("Equip.EquipOprHelper")

local thisResList = {}
local thisTitle = "@PackageTitle"
local thisCallback = nil

--------------------------------------------------------------
local ResItem = {
    ccbiFile = "GeneralDecisionPopUp3Item.ccbi",
    itemCcbi = "GoodsItem.ccbi"
}
local ResSubItem = {

}
function ResItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ResItem.onRefreshItemView(container)
    end
end	

function ResItem.onRefreshItemView(container)
    local contentId = container:getItemDate().mID
    local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE

    for i = 1, ITEM_COUNT_PER_LINE do
        local nodeContainer = container:getVarNode(string.format("mPositionNode%d", i))
        NodeHelper:setNodeVisible(nodeContainer, false)
        nodeContainer:removeAllChildren()
        local index = baseIndex + i
        if thisResList[index] then
            local itemNode = ResItem.newItem(index)
            nodeContainer:addChild(itemNode)
            itemNode:setPosition(CCPointMake(0, 0))
            NodeHelper:setNodeVisible(nodeContainer, true)
        end
    end
end

function ResItem.newItem(index)
    local resCfg = thisResList[index]
    local itemNode = ScriptContentBase:create(ResItem.itemCcbi, index)
    itemNode:registerFunctionHandler(ResSubItem.onFunction)
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(resCfg.type, resCfg.itemId, resCfg.count)
    local colorMap = { }
    local lb2Str = {
        mName = resInfo.name,
        mNumber = "x" .. resInfo.count
    }
    --    local htmlNode = itemNode:getVarNode("mName")
    -- if htmlNode then
    -- 	local htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(GameConfig.LineWidth.ItemNameLength,64),resInfo.name )
    -- 	htmlLabel:setScaleX(htmlNode:getScaleX()-0.2)
    --        htmlLabel:setScaleY(htmlNode:getScaleY()-0.2)
    -- 	htmlNode:setVisible(false)
    -- end
    NodeHelper:setStringForLabel(itemNode, lb2Str)
    NodeHelper:setSpriteImage(itemNode, { mPic = resInfo.icon })
    if string.sub(resInfo.icon, 1, 7) == "UI/Role" then
        --NodeHelper:setNodeScale(itemNode, "mPic", 0.84, 0.84)
    else
        --NodeHelper:setNodeScale(itemNode, "mPic", 1, 1)
    end

    NodeHelper:setQualityFrames(itemNode, { mHand = resInfo.quality })
    NodeHelper:setColor3BForLabel(itemNode, { mName = common:getColorFromConfig("Own") })

    colorMap["mName"] = ConfigManager.getQualityColor()[resInfo.quality].textColor
    NodeHelper:setColorForLabel(itemNode, colorMap)

    itemNode:release()
    return itemNode
end	

function ResSubItem.onFunction(eventName, container)
    if eventName == "onHand" then
        ResSubItem.onHand(container)
    end
end
function ResSubItem.onHand(container)
    local index = container:getTag()
    local resCfg = thisResList[index]
    if resCfg then
        GameUtil:showTip(container:getVarMenuItemImage("mHand"), resCfg)
    end
end
----------------------------------------------------------------------------------

-----------------------------------------------
-- ResListPageBase页面中的事件处理
----------------------------------------------
function ResListPageBase:onEnter(container)
    thisTitle = thisTitle or "@PackageTitle"
    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString(thisTitle) })

    NodeHelper:initScrollView(container, "mContent", 3)

    self:rebuildAllItem(container)
end

function ResListPageBase:onExit(container)
    NodeHelper:deleteScrollView(container)
    self:clearCache()
end

----------------------------------------------------------------
function ResListPageBase:clearCache()
    thisResList = { }
    thisTitle = nil
end

----------------scrollview-------------------------
function ResListPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    if #thisResList > 0 then
        self:buildItem(container)
    end
end

function ResListPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function ResListPageBase:buildItem(container)
    local size = math.ceil(#thisResList / ITEM_COUNT_PER_LINE)
    NodeHelper:buildScrollView(container, size, ResItem.ccbiFile, ResItem.onFunction)
end
	
----------------click event------------------------
function ResListPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function ResListPageBase:onConfirm(container)
    if thisCallback then
        thisCallback()
    end
    self:onClose()
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
ResListPage = CommonPage.newSub(ResListPageBase, thisPageName, option)

function ResListPage_setList(list, callback, title)
    thisResList = list
    thisTitle = title or "@PackageTitle"
    thisCallback = callback
end
