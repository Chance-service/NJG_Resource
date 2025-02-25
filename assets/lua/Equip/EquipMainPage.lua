
----------------------------------------------------------------------------------

local TalentManager = require("PlayerInfo.TalentManager")
local ElementManager = require("Element.ElementManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo")
local ElementConfig = require("Element.ElementConfig")
local itemContainerMap = { }
local nowUserInfo = { }
local NodeHelper = require("NodeHelper");
local Player_pb = require("Player_pb");
local Const_pb = require("Const_pb");
local EquipMainPage = { }
local option = {
    ccbiFile = "FairPage.ccbi",
    handlerMap =
    {
        onReturn = "onClose",
        onHelp = "onHelp",
    },
}
local EquipPartNames = {
    ["Helmet"] = Const_pb.HELMET,
    ["Neck"] = Const_pb.NECKLACE,
    ["Finger"] = Const_pb.RING,
    ["Wrist"] = Const_pb.GLOVE,
    ["Waist"] = Const_pb.BELT,
    ["Feet"] = Const_pb.SHOES,
    ["Chest"] = Const_pb.CUIRASS,
    ["Legs"] = Const_pb.LEGGUARD,
    ["MainHand"] = Const_pb.WEAPON1,
    ["OffHand"] = Const_pb.WEAPON2
};
local mSubNode = nil
local fOneItemWidth = 0
local fScrollViewWidth = 0
local mercenaryHeadContent = {
    -- 佣兵数据
    ccbiFile = "EquipmentPageMercenaryPortraitContent.ccbi"
} 
function EquipMainPage:onEnter(container)

    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:initScrollView(container, "mPortrait", 4)
    mSubNode = container:getVarNode("mContentNode")
    -- 绑定子页面ccb的节点
    if mSubNode then
        mSubNode:removeAllChildren()
    end
    self:registerPacket(container)
    self:refreshPage(container);
    self:rebuildAllItem(container)
end
function EquipMainPage:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildScrollView(container)
end
function EquipMainPage:clearAllItem(container)
    NodeHelper:clearScrollView(container);
end
function EquipMainPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function EquipMainPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------------------------------------------------------------------------------
-- 标签页
function mercenaryHeadContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        mercenaryHeadContent.onRefreshItemView(container);
    elseif eventName == "onBtn" then

    end
end
function mercenaryHeadContent.onRefreshItemView(container)
    local index = tonumber(container:getItemDate().mID)

end
function mercenaryHeadContent.onHand(container)

end
-- 构建标签页
function EquipMainPage:buildScrollView(container)
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local currentPos = 0;
    local interval = 15;
    for i = 1, #5 do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp((fOneItemWidth + interval) * iCount, 0)

        if iCount < iMaxNode then
            ccbiFile = mercenaryHeadContent.ccbiFile
            local pItem = ScriptContentBase:create(ccbiFile);
            -- pItem:release();
            pItem.id = iCount
            pItem:registerFunctionHandler(mercenaryHeadContent.onFunction)
            fOneItemHeight = pItem:getContentSize().height

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            currentPos = currentPos + fOneItemWidth
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end
    local size = CCSizeMake(fOneItemWidth * iCount + interval *(iCount - 1), fOneItemHeight)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
    container.mScrollView:forceRecaculateChildren();
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end
-- 标签页
---------------------------------------------------------------------------------
function EquipMainPage:refreshPage(container)

    local shopInfo = ShopDataManager._childContainerInfo[ShopDataManager._curShopIndex]
    if shopInfo then
        local page = shopInfo._scriptName
        if page and page ~= "" and mSubNode then
            if EquipMainPage.subPage then
                EquipMainPage.subPage:onExit(container)
                EquipMainPage.subPage = nil
            end
            mSubNode:removeAllChildren()
            EquipMainPage.subPage = require(page)
            EquipMainPage.sunCCB = EquipMainPage.subPage:onEnter(container)
            mSubNode:addChild(EquipMainPage.sunCCB)
            -- EquipMainPage.sunCCB:setAnchorPoint(ccp(0,0))
            if EquipMainPage.subPage["getPacketInfo"] then
                EquipMainPage.subPage:getPacketInfo()
            end
            EquipMainPage.sunCCB:release()
        end
    end
end
function EquipMainPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            self:refreshCurrencyInfo(container);
        end
    end
end
function EquipMainPage:refreshCurrencyInfo(container)
    UserInfo.syncPlayerInfo();
    local UserItemManager = require("Item.UserItemManager")
    local count = UserItemManager:getCountByItemId(11151)
    local nodeVisble = {
        mSuitFrame = (ShopDataManager._curShopIndex == ShopDataManager._shopType.STATE_DROPS),
        mGemFrame = (ShopDataManager._curShopIndex == ShopDataManager._shopType.STATE_GEMS),
        mCoinFrame = (ShopDataManager._curShopIndex == ShopDataManager._shopType.STATE_DROPS)
        or(ShopDataManager._curShopIndex == ShopDataManager._shopType.STATE_COINS),
    }
    local nodeText = {
        mSuitShard = UserInfo.playerInfo.crystal,
        mDraw = tostring(count),
        mCoin = GameUtil:formatNumber(UserInfo.playerInfo.coin),
        mGold = UserInfo.playerInfo.gold
    }
    NodeHelper:setNodesVisible(container, nodeVisble);
    NodeHelper:setStringForLabel(container, nodeText);
end
function EquipMainPage:onBtnSelect(container, index)
    if ShopDataManager._curShopIndex == ShopDataManager._childContainerInfo[index]._type then
        return
    end
    ShopDataManager._curShopIndex = ShopDataManager._childContainerInfo[index]._type
    self:refreshPage(container);
    for i = 1, #ShopDataManager._childContainerInfo do
        NodeHelper:setMenuItemSelected(ShopDataManager._childContainerInfo[i]._container,
        { mBtn = ShopDataManager._childContainerInfo[i]._type == ShopDataManager._curShopIndex })
    end
    self:refreshCurrencyInfo(container)
end
-- 接收服务器回包
function EquipMainPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msgPacket = {
        [HP_pb.SHOP_ITEM_S] = Shop_pb.ShopItemInfoResponse(),
        [HP_pb.SHOP_BUY_S] = Shop_pb.BuyShopItemsResponse(),
    }
    if opcode == HP_pb.SHOP_ITEM_S or opcode == HP_pb.SHOP_BUY_S then
        local msg = msgPacket[opcode]
        msg:ParseFromString(msgBuff)
        ShopDataManager.setPacketDataInfo(msg);
        self:refreshCurrencyInfo(container)
        if EquipMainPage.subPage then
            EquipMainPage.subPage:onReceivePacket(container)
        end

    end
end
function EquipMainPage:onExecute(container)
    if EquipMainPage.subPage then
        EquipMainPage.subPage:onExecute(container)
    end

end
function EquipMainPage:onClose(container)
    PageManager.changePage("MainScenePage")
end
function EquipMainPage:onExit(container)
    if EquipMainPage.subPage then
        EquipMainPage.subPage:onExit(container)
        EquipMainPage.subPage = nil
    end
    self:removePacket(container)
end
function EquipMainPage:onHelp(container)
    local info = ShopDataManager.getChildContainerInfo()
    PageManager.showHelp(info._helpFile)
end
local CommonPage = require('CommonPage')
EquipMainPage = CommonPage.newSub(EquipMainPage, thisPageName, option)
