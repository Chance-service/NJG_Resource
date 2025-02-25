----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")
local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local GuildDataManager = require("Guild.GuildDataManager")
local thisPageName = 'GuildShopPage'
local ShopDataManager = require("ShopDataManager")
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local GuildShopBase = { }
local _shopPacketInfo = { }
local ITEM_COUNT_PER_LINE = 3
local isRecevieData = false
local option = {
    ccbiFile = "GuildShopPopUp.ccbi",
    handlerMap =
    {
        onCancel = 'onRefresh',
        onClose = 'onClose',
    },
    opcodes =
    {
        SHOP_ITEM_C = HP_pb.SHOP_ITEM_C,
        SHOP_ITEM_S = HP_pb.SHOP_ITEM_S,
        SHOP_BUY_C = HP_pb.SHOP_BUY_C,
        SHOP_BUY_S = HP_pb.SHOP_BUY_S,
    }
}
function GuildShopBase:registerPackets(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function GuildShopBase:removePackets(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
function GuildShopBase:onEnter(container)
    self:registerPackets(container)
    isRecevieData = false
    NodeHelper:initScrollView(container, 'mContent', 10)
    ShopDataManager.sendShopItemInfoRequest(Const_pb.INIT_TYPE, Const_pb.ALLIANCE_MARKET)
end

function GuildShopBase:onExit(container)
    self:removePackets(container)
    isRecevieData = false
    NodeHelper:deleteScrollView(container)
end

function GuildShopBase:refreshPage(container)
    -- title
    local lb2Str = {
        mYourContribution = _shopPacketInfo.contribution,
        mLuckyShopNum = _shopPacketInfo.luckyScore
    }
    -- scrollview
    if #_shopPacketInfo.shopList ~= 0 then
        self:rebuildAllItem(container)
    end

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setLabelOneByOne(container, "mLuckShop", "mLuckyShopNum")


end

function GuildShopBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GuildShopBase:onRefresh(container)
    local title = Language:getInstance():getString("@GuildShopRefreshtitle")
    local costNum = tonumber(_shopPacketInfo.refreshCost);
    local contribution = tonumber(_shopPacketInfo.contribution)
    local finalMsg = common:getLanguageString("@GuildShopRefreshContent", costNum);
    PageManager.showConfirm(title, finalMsg, function(isSure)
        if isSure then
            ShopDataManager.sendShopItemInfoRequest(Const_pb.REFRESH_TYPE, Const_pb.ALLIANCE_MARKET)
        end
    end , true);
end
----------------scrollview item-------------------------
local ShopItem = {
    ccbiFile = 'GuildShopContentItem.ccbi',
}

local ShopItemSub = {
    ccbiFile = 'GuildShopContent.ccbi',
}

function ShopItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ShopItem.onRefreshItemView(container)
    end
end

function ShopItemSub.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ShopItemSub.onRefreshItemView(container)
    elseif eventName == 'onbuy' then
        ShopItemSub.buy(container)
    elseif eventName == 'onHand' then
        ShopItemSub.showTip(container)
    end
end

function ShopItemSub.onRefreshItemView(container)
    MessageBoxPage:Msg_Box('@refresh sub shop item')
end

function ShopItemSub.buy(container)
    local itemIndex = container:getTag()
    local info = _shopPacketInfo.shopList[itemIndex]
    if not info then
        MessageBoxPage:Msg_Box('@GuildBuyItemEmpty')
        return
    end

    if _shopPacketInfo.contribution < info.price then
       MessageBoxPage:Msg_Box('@ERRORCODE_9012')
       return
    end

    local itemConfig = ConfigManager.getItemCfg()[info.itemId]
    local itemName = ""
    if itemConfig then
        itemName = common:getLanguageString(itemConfig.name)
    end
    local maxCount = math.modf(_shopPacketInfo.contribution / info.price)
    if maxCount > 99 then
        maxCount = 99
    end
    local costNum = info.price
    PageManager.showCountTimesWithIconPage(info.itemType, info.itemId, 6,
    function(count)
        return count * costNum
    end ,
    function(isBuy, count)
        if isBuy then
            ShopDataManager.buyShopItemsRequest(ShopDataManager._buyType.BUY_SINGLE,
            Const_pb.ALLIANCE_MARKET, info.id, count)
        end
    end , true, maxCount, "@SuitPatchNumberTitle", nil, nil, itemName)

    --ShopDataManager.buyShopItemsRequest(1, Const_pb.ALLIANCE_MARKET, info.id, 1)
end

function ShopItemSub.showTip(container)
    local index = container:getTag();
    local item = _shopPacketInfo.shopList[index];
    if item == nil then return; end

    local stepLevel = EquipManager:getEquipStepById(item.itemId)

    GameUtil:showTip(container:getVarNode('mHand'), {
        type = item.itemType,
        itemId = item.itemId,
        buyTip = true,
        starEquip = stepLevel == GameConfig.ShowStepStar
    } );
end

function ShopItem.onRefreshItemView(container)
    local shopItemId = container:getItemDate().mID
    local subContent
    local contentContainer
    for i = 1, ITEM_COUNT_PER_LINE do

        local subItemIndex =(shopItemId - 1) * ITEM_COUNT_PER_LINE + i

        if subItemIndex > #_shopPacketInfo.shopList then return end

        local shopInfo = _shopPacketInfo.shopList[subItemIndex]
        if not shopInfo then return end

        local resInfo = ResManagerForLua:getResInfoByTypeAndId(shopInfo.itemType, shopInfo.itemId)
        if not resInfo then return end

        subContent = container:getVarNode('mPosition' .. tostring(i))

        if subContent then
            -- clear old subItems
            subContent:removeAllChildren();

            -- create subItem
            contentContainer = ScriptContentBase:create(ShopItemSub.ccbiFile, subItemIndex)
            contentContainer:registerFunctionHandler(ShopItemSub.onFunction)

            -- set sub item's view
            local lb2Str = {
                mNumber = shopInfo.count,
                mCommodityName = resInfo.name,
                mContributionNum = shopInfo.price
            }
            -- NodeHelper:setColorForLabel(contentContainer,{mNumber = "32 29 0"})
            NodeHelper:setStringForLabel(contentContainer, lb2Str)

            -- image
            NodeHelper:setSpriteImage(contentContainer, { mPic = resInfo.icon })
            NodeHelper:setMenuItemQuality(contentContainer, "mHand", resInfo.quality);
            NodeHelper:setQualityBMFontLabels(contentContainer, { mCommodityName = resInfo.quality });
            -- add subItem into item
            subContent:addChild(contentContainer)
            contentContainer:release()
        end
    end
end	

----------------scrollview-------------------------
function GuildShopBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function GuildShopBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function GuildShopBase:buildItem(container)
    local needItemCount = math.ceil(#_shopPacketInfo.shopList / ITEM_COUNT_PER_LINE)
    NodeHelper:buildScrollView(container, needItemCount, ShopItem.ccbiFile, ShopItem.onFunction, isRecevieData);
    isRecevieData = true
end

---------------------------- packet function ------------------------------------

function GuildShopBase:onReceiveShopList(container, msg)
    _shopPacketInfo.shopList = msg.itemInfo
    _shopPacketInfo.refreshCost = msg.refreshPrice
    for i = 1, #msg.data do
        if msg.data[i].dataType == Const_pb.CONTRIBUTION_VALUE then
            -- 公会贡献值
            _shopPacketInfo.contribution = msg.data[i].amount
        end
        if msg.data[i].dataType == Const_pb.LUCK_SCORE then
            -- 幸运值
            _shopPacketInfo.luckyScore = msg.data[i].amount .. "%"
        end
    end
end
function GuildShopBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.SHOP_ITEM_S then
        local msg = Shop_pb.ShopItemInfoResponse()
        msg:ParseFromString(msgBuff)
        self:onReceiveShopList(container, msg)
        self:refreshPage(container)
        return
    end
end

local CommonPage = require('CommonPage')
local GuildShopPage = CommonPage.newSub(GuildShopBase, thisPageName, option)
