

local thisPageName = "SuitExchangePage_100";
local SuitExchangePage_100Base = { };
local Const_pb = require("Const_pb");
local thisItemId = 0
local _itemCount = 1    -- 用户的道具数量
local _currenCount = 1 -- 当前数量
local _multiple = 1
local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
};
local option = {
    -- ccbiFile = "SuitExchangePage_100.ccbi",
    ccbiFile = "SuitExchangePage_100_New.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onUseClick = "onUseClick",

        -----------------------------------
        onAdd = "onIncrease",
        onAddTen = "onIncreaseTen",
        onReduction = "onDecrease",
        onReductionTen = "onDecreaseTen",
        -----------------------------------
    }
};
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
local ItemOprHelper = require("Item.ItemOprHelper");
local UserInfo = require("PlayerInfo.UserInfo");
local mItemObj = { }
local mCurrentSelect = 0
local mCurrentItemId = 0
local mItemInfo = nil
--------------------------------------------------------------
local Item = {
    ccbiFile = "SuitExchangePage_100Item.ccbi"
}
function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onOpenClick()

end

function Item:onHand(container)
    if self.data then
        GameUtil:showTip(self.container:getVarNode('mIconSprite'), self.data)
    end
end

function Item:onSelect(container)
    SuitExchangePage_100Base.onSelect(self.id, self.data.itemId)
end

function Item:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    self:setSelectState(mCurrentSelect)
    local itemInfo = ResManagerForLua:getResInfoByTypeAndId(self.data.type, self.data.itemId, self.data.count)
    local sprite2Img = { }
    local scaleMap = { }
    local menu2Quality = { }
    local lb2Str = { }
    local visibleMap = { }
    local colorMap = { }

    if itemInfo then
        sprite2Img["mIconSprite"] = itemInfo.icon
        sprite2Img["mBgSprite"] = NodeHelper:getImageBgByQuality(itemInfo.quality)
        menu2Quality["mQuality"] = itemInfo.quality
        colorMap["mNameLabel"] = ConfigManager.getQualityColor()[itemInfo.quality].textColor
        lb2Str["mNameLabel"] = common:stringAutoReturn(itemInfo.name, 4)
        lb2Str["mCountLabel"] = self.data.count
    end

    NodeHelper:setNodesVisible(self.container, visibleMap)
    NodeHelper:setStringForLabel(self.container, lb2Str)
    NodeHelper:setSpriteImage(self.container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(self.container, menu2Quality)
    NodeHelper:setColorForLabel(self.container, colorMap)
end

function Item:setSelectState(currentId)
    local isSelect = false
    if currentId == self.id then
        isSelect = true
    end
    NodeHelper:setNodesVisible(self.container, { mSelectSprite = isSelect })
    NodeHelper:setMenuItemEnabled(self.container, "mSelectBtn", not isSelect)
end
--------------------------------------------------------------


-----------------------------------------------
-- SuitExchangeItemDetailsPageBase页面中的事件处理
----------------------------------------------
function SuitExchangePage_100Base.onFunction(eventName, container)
    --    if eventName =="onFrame1" then
    --        SuitExchangePage_100Base.onSelectItem(container,1)
    --    elseif eventName =="onFrame2" then
    --        SuitExchangePage_100Base.onSelectItem(container,2)
    --    elseif eventName =="onFrame3" then
    --        SuitExchangePage_100Base.onSelectItem(container,3)
    --    end
end

function SuitExchangePage_100Base.onSelect(id, itemId)
    mCurrentSelect = id
    mCurrentItemId = itemId
    for k, v in pairs(mItemObj) do
        v:setSelectState(mCurrentSelect)
    end
end

function SuitExchangePage_100Base:onEnter(container)
    self.container = container
    self:initData()
    NodeHelper:initScrollView(container, "mContent", 3)
    self:refreshPage(container)
    container:registerPacket(HP_pb.ITEM_USE_S)
end

function SuitExchangePage_100Base:initData()
    mItemObj = { }
    mCurrentSelect = 0
    mCurrentItemId = 0
end

function SuitExchangePage_100Base:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    mItemObj = { }
    if mItemInfo == nil then
        return
    end
    local data = ConfigManager.parseItemWithComma(mItemInfo.containItem)
    -- local data = common:split(mItemInfo.containItem, ",")
    for i = 1, #data do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { id = i, data = data[i] })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
        mItemObj[i] = panel
    end
    container.mScrollView:orderCCBFileCells()
end

function SuitExchangePage_100Base:onExit(container)
    mItemInfo = nil
    container:removePacket(HP_pb.ITEM_USE_S);
end
----------------------------------------------------------------

function SuitExchangePage_100Base:refreshPage(container)
    self:clearAndReBuildAllItem(container)
    self:refreshCount(container)
    --    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    --    local count = 0;
    --    if userItem then
    --        count = userItem.count
    --    end
    --    mItemInfo = ItemManager:getItemCfgById(thisItemId);

    --    UserItemManager:getUserItemByItemId(itemId)

    --    for i = 1, 3 do
    --        local suitInfo = { }
    --        if tonumber(itemInfo[i].type) == 30000 then
    --            suitInfo = ItemManager:getItemCfgById(itemInfo[i].itemId)
    --        elseif tonumber(itemInfo[i].type) == 40000 then
    --            suitInfo = EquipManager:getEquipCfgById(itemInfo[i].itemId)
    --        end
    --        local lb2Str = {
    --            ["mName" .. i] = suitInfo.name,
    --            ["mNum" .. i] = suitInfo.count,
    --            ["mOccupationname" .. i] = common:getLanguageString("@ProfessionName_" .. i),
    --        }
    --        local sprite2Img = {
    --            ["mPic" .. i] = suitInfo.icon
    --        };
    --        local itemImg2Qulity = {
    --            ["mFrame" .. i] = suitInfo.quality
    --        };
    --        NodeHelper:setStringForLabel(container, lb2Str);
    --        NodeHelper:setSpriteImage(container, sprite2Img);
    --        NodeHelper:setQualityFrames(container, itemImg2Qulity);
    --    end
    --    local strConsumptionTex = userItemInfo.name .. "  1 " .. common:fill(common:getLanguageString("@NowOwened"), count)
    --    NodeHelper:setStringForLabel(container, { mConsumptionTex = strConsumptionTex });
end

function SuitExchangePage_100Base:onClose(container)
    PageManager.popPage(thisPageName);
end


function SuitExchangePage_100Base:onUseClick(container)

    if mCurrentSelect <= 0 then
        -- 用一个提示么？
        MessageBoxPage:Msg_Box_Lan("@SuitExchangeTex")
        return
    end
    if mCurrentItemId <= 0 then
        return
    end

    if thisItemId <= 0 then
        return
    end
    if _currenCount <= 0 then
        return
    end
    -- ItemOprHelper:useItem(thisItemId, 1, mCurrentItemId)
    ItemOprHelper:useItem(thisItemId, _currenCount, mCurrentItemId)
    PageManager.popPage(thisPageName)
end

function SuitExchangePage_100Base:exchange(container, count)
    local userItem = UserItemManager:getUserItemByItemId(thisItemId);
    if not userItem then
        MessageBoxPage:Msg_Box_Lan("@GodlyPieceNotEnough");
        return;
    end
    local mCount = count;
    local userItem = UserItemManager:getUserItemByItemId(thisItemId);
    ItemOprHelper:useItem(userItem.itemId, 0, profId);
    PageManager.popPage(thisPageName);
end
-- 回包处理
function SuitExchangePage_100Base:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ITEM_USE_S then
        -- SuitExchangePage_100Base:refreshPage(container);
    end
end
-------------------------------------------------------------------------
-- 加1
function SuitExchangePage_100Base:onIncrease(container)
    if _currenCount == _itemCount then
        MessageBoxPage:Msg_Box_Lan("@NotEnoughExchangeItem")
        return
    end
    _currenCount = _currenCount + 1 * _multiple
    self:refreshCount(container)
end

-- 减1
function SuitExchangePage_100Base:onDecrease(container)
    if _currenCount <= 1 then
        return
    end
    _currenCount = _currenCount - 1 * _multiple
    self:refreshCount(container)
end

-- 加10
function SuitExchangePage_100Base:onIncreaseTen(container)
    if _currenCount >(_itemCount - 10 * _multiple) then
        _currenCount = _itemCount
        MessageBoxPage:Msg_Box_Lan("@NotEnoughExchangeItem")
    elseif _currenCount == 1 then
        _currenCount = 10 * _multiple
    else
        _currenCount = _currenCount + 10 * _multiple
    end
    self:refreshCount(container)
end

-- 减10
function SuitExchangePage_100Base:onDecreaseTen(container)
    if _currenCount < 10 * _multiple then
        _currenCount = 1 * _multiple
    else
        _currenCount = _currenCount - 10 * _multiple
    end

    if _currenCount == 0 then _currenCount = 1 end
    self:refreshCount(container)
end

function SuitExchangePage_100Base:refreshCount(container)
    NodeHelper:setStringForLabel(container, { mAddNum = _currenCount })
end

-------------------------------------------------------------------------

local CommonPage = require("CommonPage");
SuitExchangePage_100 = CommonPage.newSub(SuitExchangePage_100Base, thisPageName, option);

function SuitExchangePage_100_setItemId(itemId)
    thisItemId = itemId
    mItemInfo = ItemManager:getItemCfgById(thisItemId)
    _currenCount = 1
    local userItem = UserItemManager:getUserItemByItemId(thisItemId);
    _itemCount = 0
    if userItem then
        _itemCount = userItem.count
    end
end
-- endregion
