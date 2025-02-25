local thisPageName = "SuitExchangePage"
local SuitExchangePageBase = {}
local Const_pb = require("Const_pb")
local thisItemId = 0
local thisItemId = 0
local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
}
local option = {
    ccbiFile = "SuitExchangePopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onConfirmation = "onClose",
        onExchange1 = "onExchange",
        onExchange2 = "onExchange",
        onExchange3 = "onExchange",
        onAllExchange = "onAllExchange"
    }
}
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local ItemOprHelper = require("Item.ItemOprHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local profId
-----------------------------------------------
-- SuitExchangeItemDetailsPageBase页面中的事件处理
----------------------------------------------
function SuitExchangePageBase.onFunction(eventName, container)
    if eventName == "onFrame1" then
        SuitExchangePageBase.onSelectItem(container, 1)
    elseif eventName == "onFrame2" then
        SuitExchangePageBase.onSelectItem(container, 2)
    elseif eventName == "onFrame3" then
        SuitExchangePageBase.onSelectItem(container, 3)
    end
end

function SuitExchangePageBase.onSelectItem(container, mProfId)
    profId = mProfId
    local itemsSelected = { }
    for i = 1, 3 do
        itemsSelected["mSelected" .. i] = i == mProfId
    end
    -- NodeHelper:setNodesVisible(container,itemsSelected);
end
function SuitExchangePageBase:onEnter(container)
    SuitExchangePageBase.onSelectItem(container, UserInfo.roleInfo.prof)
    self:refreshPage(container)
    container:registerPacket(HP_pb.ITEM_USE_S)
end

function SuitExchangePageBase:onExit(container)
    container:removePacket(HP_pb.ITEM_USE_S)
end
----------------------------------------------------------------

function SuitExchangePageBase:refreshPage(container)
    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    local count = 0
    if userItem then
        count = userItem.count
    end
    local userItemInfo = ItemManager:getItemCfgById(thisItemId)

    UserItemManager:getUserItemByItemId(itemId)
    local mAllExchangeStr
    if count > 10 then
        NodeHelper:setStringForLabel(container, { mAllExchange = common:getLanguageString("@TenExchange") })
    else
        NodeHelper:setStringForLabel(container, { mAllExchange = common:getLanguageString("@AllExchange") })
    end
    local itemInfo = ItemManager:getSuitContainCfg(thisItemId)

    for i = 1, 3 do
        local suitInfo = { }
        if tonumber(itemInfo[i].type) == 30000 then
            suitInfo = ItemManager:getItemCfgById(itemInfo[i].itemId)
        elseif tonumber(itemInfo[i].type) == 40000 then
            suitInfo = EquipManager:getEquipCfgById(itemInfo[i].itemId)
        end
        local lb2Str = {
            ["mName" .. i] = suitInfo.name,
            ["mNum" .. i] = suitInfo.count,
            ["mOccupationname" .. i] = common:getLanguageString("@ProfessionName_" .. i),
        }
        local sprite2Img = {
            ["mPic" .. i] = suitInfo.icon
        }
        local itemImg2Qulity = {
            ["mFrame" .. i] = suitInfo.quality
        }
        NodeHelper:setStringForLabel(container, lb2Str)
        NodeHelper:setSpriteImage(container, sprite2Img)
        NodeHelper:setQualityFrames(container, itemImg2Qulity)
    end
    local strConsumptionTex = userItemInfo.name .. "  1 " .. common:fill(common:getLanguageString("@NowOwened"), count)
    NodeHelper:setStringForLabel(container, { mConsumptionTex = strConsumptionTex })
end

function SuitExchangePageBase:onClose(container)
    PageManager.popPage(thisPageName)
end
function SuitExchangePageBase:onExchange(container, eventName)
    profId = tonumber(string.sub(eventName, -1))
    SuitExchangePageBase:exchange(container, 1)
end

function SuitExchangePageBase:onAllExchange(container)
    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    local count = 0
    if userItem then
        count = userItem.count
    end

    if count < 0 then
        return
    end
    if count > 10 then
        SuitExchangePageBase:exchange(container, 10)
    else
        SuitExchangePageBase:exchange(container, count)
    end
end

function SuitExchangePageBase:exchange(container, count)
    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    if not userItem then
        MessageBoxPage:Msg_Box_Lan("@GodlyPieceNotEnough")
        return
    end
    local mCount = count
    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    ItemOprHelper:useItem(userItem.itemId, mCount, profId)
    PageManager.popPage(thisPageName)
end
-- 回包处理
function SuitExchangePageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.ITEM_USE_S then
        SuitExchangePageBase:refreshPage(container)
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
SuitExchangePage = CommonPage.newSub(SuitExchangePageBase, thisPageName, option, SuitExchangePageBase.onFunction)

function SuitExchangePage_setItemId(itemId)
    thisItemId = itemId
end
-- endregion
