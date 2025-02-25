----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'GoodsExchangePage_New'
local Activity2_pb = require("Activity2_pb");
local UserItemManager = require("Item.UserItemManager")
local UserMercenaryManager = require("UserMercenaryManager")
local HP_pb = require("HP_pb");
local Const_pb = require("Const_pb")
local ActivityData = require("ActivityData")
local ExchangeActivityCfg = { }
local ExchangeActivityItemId = { }-- 道具类型
local PriceIcon = { }    -- 兑换道具价格icon
local _TitleContainerCache = { }-- 保存标签对象
local _SelectItemId = nil-- 选择的道具道具类型
local _SelectIndex = nil-- 选择的道具索引
local _IsClickFlag = false-- 判断是否选择道具
local MercenaryCfg = nil
local _IsInitItem = false
local UserItemCountList = { }
local ExchangeActivityInfo = {
    timeLeft = - 1,
    exchangeIdList = { },
    exchangeTimes = { },
}

local GoodsExchangePage_New = {
    ccbiFile = "Act_TimeLimitExchangeContent.ccbi",
    timerName = "Act_TimeLimitExchangeTimer"
}

local opcodes = {
    EXCHANGE_SHOP_INFO_C = HP_pb.ACTIVITY142_EXCHANGE_SHOP_INFO_C,
    EXCHANGE_SHOP_INFO_S = HP_pb.ACTIVITY142_EXCHANGE_SHOP_INFO_S,
    DO_EXCHANGE_SHOP_C = HP_pb.ACTIVITY142_DO_EXCHANGE_SHOP_C,
    DO_EXCHANGE_SHOP_S = HP_pb.ACTIVITY142_DO_EXCHANGE_SHOP_S,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
}

function GoodsExchangePage_New.onFunction(eventName, container)
    if eventName == "onBuyAll" then
        GoodsExchangePage_New:onBuyAll();
    elseif eventName == "onOpenUi" then
        GoodsExchangePage_New:onPreview();
    elseif eventName == "onBrushSuit" then
        GoodsExchangePage_New:onBrushSuit();
    end
end
function GoodsExchangePage_New:onBuyAll()
    local titile = common:getLanguageString("@OnBuyTitle");
    local tipinfo = common:getLanguageString("@MarketBuyAll");

    PageManager.showConfirm(titile, tipinfo, function(isSure)
        if isSure then
            ShopDataManager.buyShopItemsRequest(ShopDataManager._buyType.BUY_ALL,
            ShopDataManager.getMainTypeByLocalType());
        end
    end );

end

function GoodsExchangePage_New:onEnter(ParentContainer, index)
    _IsClickFlag = false
    _IsInitItem = false
    self.container = ScriptContentBase:create(GoodsExchangePage_New.ccbiFile)
    self.container:registerFunctionHandler(GoodsExchangePage_New.onFunction)
    self:registerPacket(ParentContainer)
    NodeHelper:initScrollView(self.container, "mContent", 7)
    if self.container.mScrollView ~= nil then
        ParentContainer:autoAdjustResizeScrollview(self.container.mScrollView);
    end
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite2"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))

    GoodsExchangePage_New:getPageInfo(index)

    return self.container
end


function GoodsExchangePage_New:refreshPage()
    -- self:rebuildAllItem()
    GoodsExchangePage_New:rebuildAllTitleItem(self.container)
end

function GoodsExchangePage_New:onExecute(ParentContainer)
    self:onTimer();
end

function GoodsExchangePage_New:onTimer(container)
    if ExchangeActivityInfo.timeLeft < 0 then
        return;
    end
    local timerName = GoodsExchangePage_New.timerName;
    local timeStr = '00:00:00'
    if TimeCalculator:getInstance():hasKey(timerName) then
        ExchangeActivityInfo.timeLeft = TimeCalculator:getInstance():getTimeLeft(timerName)
        if ExchangeActivityInfo.timeLeft > 0 then
            timeStr = common:second2DateString(ExchangeActivityInfo.timeLeft, false)
        else
            timeStr = common:getLanguageString("@ActivityEnd");
            TimeCalculator:getInstance():removeTimeCalcultor(GoodsExchangePage_New.timerName);
        end
    elseif ExchangeActivityInfo.timeLeft <= 0 then
        ExchangeActivityInfo.timeLeft = -1
        timeStr = common:getLanguageString("@ActivityEnd");
    end
    NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
end

function GoodsExchangePage_New:onHandTileClick(container)
    _IsClickFlag = true
    local index = container:getItemDate().mID;
    GoodsExchangePage_New:selectTileHand(index)
end
function GoodsExchangePage_New:selectTileHand(index)
    if _IsClickFlag and index == _SelectIndex then
        return
    end

    for i = 1, #ExchangeActivityItemId do
        if _TitleContainerCache[i] then
            if index == i then
                _SelectItemId = ExchangeActivityItemId[i]
                NodeHelper:setNodesVisible(_TitleContainerCache[i], { mChoose = true })

            else
                NodeHelper:setNodesVisible(_TitleContainerCache[i], { mChoose = false })
            end
        end
    end

    if _IsInitItem and index == _SelectIndex then
        return
    end
    _SelectIndex = index
    self:rebuildAllItem()
    _IsInitItem = true
    --    for i = 1, #ExchangeActivityItemId do
    --        if _TitleContainerCache[i] then
    --            if index == i then
    --                _SelectItemId = ExchangeActivityItemId[i]
    --                NodeHelper:setNodesVisible(_TitleContainerCache[i], { mChoose = true })
    --                self:rebuildAllItem()
    --            else
    --                NodeHelper:setNodesVisible(_TitleContainerCache[i], { mChoose = false })
    --            end
    --        end
    --    end
end

----------------scrollview 创建标签页-------------------------
local ItemTitleContent = {
    ccbiFileCost = "Act_TimeLimitExchangeCostListContent.ccbi",-- 标签页node
}


function ItemTitleContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ItemTitleContent:onRefreshContent(container);
    elseif eventName == "onHand" then
        GoodsExchangePage_New:onHandTileClick(container)
    end
end

function ItemTitleContent:onRefreshContent(container)
    local index = container:getItemDate().mID;
    _TitleContainerCache[index] = container
    local itemInfo = ExchangeActivityCfg["type_" .. ExchangeActivityItemId[index]][1]
    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    local colorMap = { }
    local consumeCfg = GoodsExchangePage_New:splitTiem(itemInfo.consumeInfo)
    -- local UserItemInfo = UserItemManager:getUserItemByItemId(consumeCfg[1].itemId)
    local itemCount = UserItemCountList[consumeCfg[1].itemId]
    if consumeCfg[1]["type"] == 10000 and consumeCfg[1].itemId == 1001 then
        itemCount = UserInfo.playerInfo.gold
    end
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(consumeCfg[1].type, consumeCfg[1].itemId, consumeCfg[1].count);
    sprite2Img["mPic"] = resInfo.icon;
    sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
    lb2Str["mName"] = resInfo.name;
    colorMap["mName"] = ConfigManager.getQualityColor()[resInfo.quality].textColor
    menu2Quality["mHand"] = resInfo.quality;
    if itemCount then
        lb2Str["mNumber"] = itemCount;
    else
        lb2Str["mNumber"] = 0;
    end

    --    if UserItemInfo then
    --        -- lb2Str["mNumber"] = UserItemInfo.count;
    --        lb2Str["mNumber"] = itemCount;
    --    else
    --        lb2Str["mNumber"] = 0;
    --    end

    NodeHelper:setColorForLabel(container, colorMap)
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);

    if index == common:getTableLen(ExchangeActivityItemId) then
        if _SelectIndex == 0 then
            GoodsExchangePage_New:selectTileHand(1)
        else
            GoodsExchangePage_New:selectTileHand(_SelectIndex)
        end

    end
end

function GoodsExchangePage_New:rebuildAllTitleItem(container)
    -- table.sort( thisActivityInfo.haremInfo, function (left, right )
    --     return left.haremType > right.haremType
    -- end )
    container.mCostScrollView = container:getVarScrollView("mCostContent")
    container.mCostScrollView:setTouchEnabled(#ExchangeActivityItemId > 5)

    container.mCostScrollViewRootNode = container.mCostScrollView:getContainer();
    container.m_pCostScrollViewFacade = CCReViScrollViewFacade:new_local(container.mCostScrollView);
    container.m_pCostScrollViewFacade:init(4, 3);
    -- 用于让每个item都有弹性，详见CCReViScrollViewFacade by zhenhui
    container.m_pCostScrollViewFacade:setBouncedFlag(false);
    GoodsExchangePage_New:clearAllTitleItem(container)
    local maxSize = #ExchangeActivityItemId
    GoodsExchangePage_New:buildScrollViewHorizontal(self.container, maxSize, ItemTitleContent.ccbiFileCost, ItemTitleContent.onFunction);
end

function GoodsExchangePage_New:buildScrollViewHorizontal(container, size, ccbiFile, funcCallback, interval)
    if size == 0 or ccbiFile == nil or ccbiFile == '' or funcCallback == nil then return end
    local iMaxNode = container.m_pCostScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local fOneItemWidth = 0
    interval = interval or 30
    if size == 5 then
        interval = 8
    elseif size > 5 then
        interval = 0
    end
    for i = 1, size do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp((fOneItemWidth + interval) * iCount, 0)

        if iCount < iMaxNode then
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem.id = iCount
            pItem:registerFunctionHandler(funcCallback)
            if fOneItemHeight < pItem:getContentSize().height then
                fOneItemHeight = pItem:getContentSize().height
            end

            if fOneItemWidth < pItem:getContentSize().width then
                fOneItemWidth = pItem:getContentSize().width
            end
            container.m_pCostScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pCostScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end

    local size = CCSizeMake(fOneItemWidth * iCount + interval *(iCount - 1), fOneItemHeight)
    container.mCostScrollView:setContentSize(size)
    container.mCostScrollView:setContentOffset(ccp(0, 0))
    container.m_pCostScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
    container.mCostScrollView:forceRecaculateChildren();
    ScriptMathToLua:setSwallowsTouches(container.mCostScrollView)
end

function GoodsExchangePage_New:splitTiem(itemInfo)
    local items = { }
    for _, item in ipairs(common:split(itemInfo, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(items, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        } );
    end
    return items;
end

function GoodsExchangePage_New:getExchangeCount(index)
    local exchangeCount = 0
    if #ExchangeActivityInfo.exchangeTimes > 0 then
        for k, v in ipairs(ExchangeActivityInfo.exchangeIdList) do
            if v == tostring(index) then
                exchangeCount = ExchangeActivityInfo.exchangeTimes[k]
            end
        end
    end
    if not exchangeCount then exchangeCount = 0 end
    return exchangeCount
end
----------------scrollview 创建兑换内容-------------------------
local ItemContent = {
    ccbiFile = "Act_TimeLimitExchangeListContent.ccbi",-- 每一个node
}

function ItemContent:onPreLoad(ccbRoot)

end

function ItemContent:onUnLoad(ccbRoot)

end

function ItemContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local list = ExchangeActivityCfg["type_" .. _SelectItemId]
    local idx = self.id;
    -- 当前显示的ID
    local canExchange = true
    local itemInfo = list[idx]
    if itemInfo then
        local consumeCfg = GoodsExchangePage_New:splitTiem(itemInfo.consumeInfo)
        local awardCfg = GoodsExchangePage_New:splitTiem(itemInfo.awardInfo)
        local lb2Str = { };
        local sprite2Img = { };
        local menu2Quality = { };
        local colorMap = { };
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(awardCfg[1].type, awardCfg[1].itemId, awardCfg[1].count);
        sprite2Img["mPic"] = resInfo.icon;
        sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
        -- TODO
        sprite2Img["mConsumptionType"] = PriceIcon[_SelectItemId]
        -- sprite2Img["mConsumptionType"] = "UI/Common/Activity/Act_TL_Exchange/Act_TL_Exchange_Icon_".._SelectItemId..".png"
        menu2Quality["mHand"] = resInfo.quality;
        lb2Str["mNumber"] = "x" .. awardCfg[1].count;
        lb2Str["mName"] = resInfo.name;
        colorMap["mName"] = ConfigManager.getQualityColor()[resInfo.quality].textColor
        lb2Str["mCommodityNum"] = consumeCfg[1].count;

        if itemInfo.roleId ~= 0 then
            lb2Str["mWeapon"] = common:getLanguageString("@ExchangeExclusiveTxt", MercenaryCfg[itemInfo.roleId].name)
        elseif awardCfg[1].type == GameConfig.MercenaryTypeId then
            local obj = UserMercenaryManager:getMercenaryStatusByItemId(awardCfg[1].itemId)
            if obj then
                lb2Str["mWeapon"] = common:getLanguageString("@RoleFragmentNumberTxt") .. obj.soulCount .. "/" .. obj.costSoulCount
            end
        else
            lb2Str["mWeapon"] = "";
        end

        local exchangeCount = GoodsExchangePage_New:getExchangeCount(itemInfo.id)
        local remainTime = itemInfo.maxExchangeTime - exchangeCount
        if ActivityData.SysBasic.ForgedStoneItemId ~= _SelectItemId then
            -- 锻造石没有次数限制了
            -- lb2Str["mLimitNum"] = common:getLanguageString("@ExchangeSurplusTxt", remainTime);
            lb2Str["mLimitNumMsg"] = common:getLanguageString("@RemainingNum")
            lb2Str["mLimitNum"] = remainTime;
            --
        else
            lb2Str["mLimitNumMsg"] = ""
            lb2Str["mLimitNum"] = ""
            -- lb2Str["mLimitNum"] = ""
        end

        colorMap["mCommodityNum"] = GameConfig.ColorMap.COLOR_WHITE
        --        local UserItemInfo = UserItemManager:getUserItemByItemId(consumeCfg[1].itemId)
        --        if (not UserItemInfo or remainTime == 0) and-- or UserItemInfo.count < consumeCfg[1].count
        --            ActivityData.SysBasic.ForgedStoneItemId ~= _SelectItemId then
        --            canExchange = false
        --            -- colorMap["mCommodityNum"] = GameConfig.ColorMap.COLOR_RED
        --        end

        if (remainTime == 0) and-- or UserItemInfo.count < consumeCfg[1].count
            ActivityData.SysBasic.ForgedStoneItemId ~= _SelectItemId then
            canExchange = false
            -- colorMap["mCommodityNum"] = GameConfig.ColorMap.COLOR_RED
        end
        local itemCount = UserItemCountList[consumeCfg[1].itemId]
        if consumeCfg[1]["type"] == 10000 and consumeCfg[1].itemId == 1001 then
            itemCount = UserInfo.playerInfo.gold
        end
        -- local UserItemInfo = UserItemManager:getUserItemByItemId(consumeCfg[1].itemId)
        if itemCount < consumeCfg[1].count then
            -- colorMap["mCommodityNum"] = GameConfig.ColorMap.COLOR_RED
        end

        NodeHelper:setStringForLabel(container, lb2Str);
        NodeHelper:setSpriteImage(container, sprite2Img);
        NodeHelper:setQualityFrames(container, menu2Quality);
        NodeHelper:setColorForLabel(container, colorMap)
        -- NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mBuyBtn"), canExchange)

        -- NodeHelper:setNodeIsGray(container, { mConsumptionType = not canExchange, mCommodityNum = not canExchange })
        -- NodeHelper:setNodeScale(container, "mPic", 1, 1)
        --        if string.sub(resInfo.icon, 1, 7) == "UI/Role" then
        --            NodeHelper:setNodeScale(container, "mPic", 1, 1)
        --        else
        --            NodeHelper:setNodeScale(container, "mPic", 1, 1)
        --        end
    end
end

function ItemContent:onBuy(container)
    _IsClickFlag = false
    local index = self.id;
    local list = ExchangeActivityCfg["type_" .. _SelectItemId]
    if ActivityData.SysBasic.ForgedStoneItemId == _SelectItemId and list[index].roleId ~= 0 then
        --        local ExclusiveEquipment = require("ExclusiveEquipmentPurchasePage")
        --        ExclusiveEquipment:setDataInfo(list[index].roleId,GoodsExchangePage_New.updateCallback)
        --        PageManager.pushPage("ExclusiveEquipmentPurchasePage")
        return
    end

    local itemInfo = list[index]
    -- 消耗道具
    local consumeCfg = GoodsExchangePage_New:splitTiem(itemInfo.consumeInfo)
    -- 兑换的道具
    local awardCfg = GoodsExchangePage_New:splitTiem(list[index].awardInfo)
    -- 已兑换次数
    local exchangeCount = GoodsExchangePage_New:getExchangeCount(itemInfo.id)
    -- 剩余兑换次数
    local remainTime = itemInfo.maxExchangeTime - exchangeCount
    -- 玩家的道具数据
    local UserItemInfo = UserItemManager:getUserItemByItemId(consumeCfg[1].itemId)
    if consumeCfg[1]["type"] == 10000 then
        if consumeCfg[1]["itemId"] == 1001 then
            UserItemInfo = {}
            UserItemInfo.count = UserInfo.playerInfo.gold
        end
    end 
    local rewards = awardCfg[1]
    if remainTime <= 0 then
        -- 兑换达到上限
        MessageBoxPage:Msg_Box_Lan("@ERRORCODE_155")
        return
    end
    if UserItemInfo == nil or UserItemInfo.count < consumeCfg[1].count then
        -- 道具数量不足
        -- MessageBoxPage:Msg_Box_Lan("11111")
        -- return
    end

    local id = list[index].id
    -- 消耗道具
    local consumeCfg = GoodsExchangePage_New:splitTiem(list[index].consumeInfo)
    local awardCfg = GoodsExchangePage_New:splitTiem(list[index].awardInfo)
    local costNum = consumeCfg[1].count
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(consumeCfg[1].type, consumeCfg[1].itemId, consumeCfg[1].count, true)
    local name = ""
    if list[index].roleId == 0 then
        local getGoodsInfo = ResManagerForLua:getResInfoByTypeAndId(awardCfg[1].type, awardCfg[1].itemId, awardCfg[1].count);
        name = getGoodsInfo.name
    else
        name = common:getLanguageString("@ExchangeExclusiveTxt", MercenaryCfg[list[index].roleId].name)
    end

    local itemCount = 0
    if UserItemInfo then
        itemCount = UserItemInfo.count
    end
    -- itemCount = math.modf(itemCount / consumeCfg[1].count)

    local exchangeCount = GoodsExchangePage_New:getExchangeCount(id)
    local remainTime = list[index].maxExchangeTime - exchangeCount


    local maxCount = math.modf(itemCount / consumeCfg[1].count)
    -- local maxCount = math.modf(itemCount / rewards.count)
    -- local maxCount = math.modf(consumeCfg.count / rewards.count)
    if maxCount > 99 then
        maxCount = 99
    end

    if maxCount > remainTime then
        maxCount = remainTime
    end

    if maxCount <= 0 then
        -- 兑换副将道具不足跳转至魔法召唤界面
        local title = Language:getInstance():getString("@EquipGodMerge")
        local msg = Language:getInstance():getString("@NotEnoughExchangeCoin")
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                --GoodsExchangePage_New.jumpToActivity_101()
            end
        end )
        return
    end

    --    if rewards.type == GameConfig.MercenaryTypeId then
    --        if maxCount <= 0 then
    --            -- 兑换副将道具不足跳转至魔法召唤界面
    --            local title = Language:getInstance():getString("@FastBuyTimeTitle")
    --            local msg = Language:getInstance():getString("@MothcardFreeFastBattleTime")
    --            PageManager.showConfirm(title, msg, function(isSure)
    --                if isSure then
    --                    GoodsExchangePage_New.jumpToActivity_101()
    --                end
    --            end )
    --            return
    --        end
    --    else
    --        -- 道具数量不足
    --        if maxCount <= 0 then
    --            MessageBoxPage:Msg_Box_Lan("@NotEnoughExchangeItem")
    --            return
    --        end
    --    end

    local exchangeType = _SelectItemId
    if exchangeType == 1001 then
        exchangeType = nil
    end
    if rewards.type == GameConfig.MercenaryTypeId then
        require("CountTimesWithIconPage")
        local obj = { }
        obj.num = rewards.count
        obj.roleId = rewards.itemId
        CountTimesWithIconPageBase_setMercenaryData(obj)
        -- exchangeType = 20
    end

    PageManager.showCountTimesWithIconPage(rewards.type, rewards.itemId, exchangeType,
    function(count)
        return count * costNum
    end ,
    function(isBuy, count)
        if isBuy then
            print("count = ", count)
            local msg = Activity2_pb.DoExchange()
            msg.exchangeId = tostring(id)
            print("self.id = ", id)
            msg.exchangeTimes = count
            common:sendPacket(opcodes.DO_EXCHANGE_SHOP_C, msg, false)
        end
    end , true, maxCount, "@TLExchangeTitle", "@ERRORCODE_155", nil, name)
    if rewards.type == GameConfig.MercenaryTypeId then
        --        -- 佣兵
        --        local CountTimesWithIconPageBase = require("CountTimesWithIconPage")
        --        local obj = { }
        --        obj.num = rewards.count
        --        obj.roleId = rewards.itemId
        --        CountTimesWithIconPageBase.setMercenaryId(obj)
        --        PageManager.pushPage("CountTimesWithIconPage");
    end

    ----------------------------------------------------------------------------------------------------
    --    PageManager.showCountTimesWithIconPage(rewards.type, rewards.itemId, 4,
    --    function(count)
    --        return count * costNum
    --    end ,
    --    function(isBuy, count)
    --        if isBuy then
    --            print("count = ", count)
    --            local msg = Activity2_pb.DoExchange()
    --            msg.exchangeId = tostring(id)
    --            print("self.id = ", id)
    --            msg.exchangeTimes = count
    --            common:sendPacket(opcodes.DO_EXCHANGE_SHOP_C, msg, false)
    --        end
    --    end , true, remainTime, "@TLExchangeTitle", "@TLExchangeNotEnough", resInfo.count, name)
    --    if rewards.type == GameConfig.MercenaryTypeId then
    --        -- 佣兵
    --        local CountTimesWithIconPage = require("CountTimesWithIconPage")
    --        local obj = { }
    --        obj.num = rewards.count
    --        obj.roleId = rewards.itemId
    --        CountTimesWithIconPage:setMercenaryId(obj)
    --        PageManager.pushPage("CountTimesWithIconPage");
    --    end
end

function ItemContent:onHand(container)
    local index = self.id;
    local list = ExchangeActivityCfg["type_" .. _SelectItemId]
    local awardCfg = GoodsExchangePage_New:splitTiem(list[index].awardInfo)
    if awardCfg[1].type == 9 * 10000 then
        require("FateDetailInfoPage")
        local FateDataInfo = require("FateDataInfo")
        FateDetailInfoPage_setFate( {
            isOthers = true,
            fateData = FateDataInfo.new( { id = 0, equipId = awardCfg[1].itemId, level = 1, exp = 0 }),
            locPos = nil,
        } )
        PageManager.pushPage("FateDetailInfoPage")
    else
        GameUtil:showTip(container:getVarNode("mPic"), awardCfg[1])
    end
end

------------------------------------------------------------------

function GoodsExchangePage_New.jumpToActivity_101()
    require("GashaponPage")
    GashaponPage_setPart(101)
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")
    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)
end

function GoodsExchangePage_New.updateCallback()
    if _TitleContainerCache[1] then
        local count = 0
        local UserItemInfo = UserItemManager:getUserItemByItemId(ActivityData.SysBasic.ForgedStoneItemId)
        if UserItemInfo then
            count = UserItemInfo.count
        end
        NodeHelper:setStringForLabel(_TitleContainerCache[1], { mNumber = count });
    end
end

function GoodsExchangePage_New:rebuildAllItem()
    self:clearAllItem();
    self:buildItem();
end

function GoodsExchangePage_New:clearAllItem()
    NodeHelper:clearScrollView(self.container)
    if self.container and self.container.mScrollView then
        self.container.mScrollView:removeAllCell()
    end
end

function GoodsExchangePage_New:buildItem()
    local maxSize = math.ceil(#ExchangeActivityCfg["type_" .. _SelectItemId])
    local oneSize = nil
    local num = math.ceil(maxSize / 2) * 2
    self.container.mScrollView:removeAllCell()
    for i = 1, maxSize do
        local cell = CCBFileCell:create()
        cell:setCCBFile(ItemContent.ccbiFile)
        local panel = common:new( { id = i }, ItemContent)
        cell:registerFunctionHandler(panel)
        self.container.mScrollView:addCell(cell)
        if not oneSize then
            oneSize = cell:getContentSize()
        end
        local pos = ccp(oneSize.width *((i - 1) % 2), oneSize.height * math.floor((num - i) / 2))
        cell:setPosition(pos)
        panel.cell = cell
    end
    local viewSize = self.container.mScrollView:getViewSize()
    local size = CCSizeMake(viewSize.width, oneSize.height * math.ceil(maxSize / 2))
    self.container.mScrollView:setContentSize(size)
    self.container.mScrollView:setContentOffset(ccp(0, viewSize.height - size.height));
    self.container.mScrollView:forceRecaculateChildren()
end

function GoodsExchangePage_New:getPageInfo(index)
    ExchangeActivityCfg = { }
    ExchangeActivityCfg.cfg = ConfigManager.getExchangeActivityItem_142()
    MercenaryCfg = ConfigManager.getRoleCfg()
    ExchangeActivityItemId = { }

    local keyTest ={}
    for i in pairs(ExchangeActivityCfg.cfg) do
        table.insert(keyTest,i)  
    end
    table.sort(keyTest, function(a,b) 
        return a < b 
        end
    ) 
    -- 道具类型
    for k, v in pairs(keyTest) do
        local itemInfo = ExchangeActivityCfg.cfg[v]
        local consumeCfg = GoodsExchangePage_New:splitTiem(itemInfo.consumeInfo)[1]
        if consumeCfg.itemId ~= ActivityData.SysBasic.ForgedStoneItemId then
            if ExchangeActivityCfg["type_" .. consumeCfg.itemId] == nil then
                ExchangeActivityCfg["type_" .. consumeCfg.itemId] = { }
                table.insert(ExchangeActivityItemId, consumeCfg.itemId);
            end
            table.insert(ExchangeActivityCfg["type_" .. consumeCfg.itemId], itemInfo);
            if PriceIcon[consumeCfg.itemId] == nil then
                local data = ResManagerForLua:getResInfoByTypeAndId(consumeCfg.type, consumeCfg.itemId, consumeCfg.count)
                if data then
                    PriceIcon[consumeCfg.itemId] = data.icon
                end
            end
        end
    end

    --table.sort(ExchangeActivityItemId)
    --    for i = 1, #ExchangeActivityCfg.cfg do
    --        local itemInfo = ExchangeActivityCfg.cfg[i]
    --        local consumeCfg = GoodsExchangePage_New:splitTiem(itemInfo.consumeInfo)[1]
    --        if consumeCfg.itemId ~= ActivityData.SysBasic.ForgedStoneItemId then
    --            if ExchangeActivityCfg["type_" .. consumeCfg.itemId] == nil then
    --                ExchangeActivityCfg["type_" .. consumeCfg.itemId] = { }
    --                table.insert(ExchangeActivityItemId, consumeCfg.itemId);
    --            end
    --            table.insert(ExchangeActivityCfg["type_" .. consumeCfg.itemId], itemInfo);
    --        end
    --    end
    for i = 1, #ExchangeActivityItemId do
        -- 排序
        table.sort(ExchangeActivityItemId, function(a, b)
           return ExchangeActivityCfg["type_" .. a][1].sortId < ExchangeActivityCfg["type_" .. b][1].sortId;
            -- return false
        end );
    end
    for i = 1, #ExchangeActivityItemId do
        -- 排序
        table.sort(ExchangeActivityCfg["type_" .. ExchangeActivityItemId[i]], function(a, b)
           return a.sortId < b.sortId;
            -- return false
        end );
    end
    _SelectItemId = ExchangeActivityItemId[1]
    _SelectIndex = 0;
    if index and index > 0 then
        _SelectIndex = index;
    end




    self:getActivityInfo()
end

function GoodsExchangePage_New:refreshUserItemCount()
    for i = 1, #ExchangeActivityItemId do
        UserItemCountList[ExchangeActivityItemId[i]] = 0
        local itemInfo = UserItemManager:getUserItemByItemId(ExchangeActivityItemId[i])
        if itemInfo then
            UserItemCountList[ExchangeActivityItemId[i]] = itemInfo.count
        else
            if ExchangeActivityItemId[i] == 1001 then
                UserItemCountList[ExchangeActivityItemId[i]] = UserInfo.playerInfo.gold
            end
        end
    end
end

function GoodsExchangePage_New:getActivityInfo()
    common:sendEmptyPacket(opcodes.EXCHANGE_SHOP_INFO_C, false)
end

function GoodsExchangePage_New:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.EXCHANGE_SHOP_INFO_S then
        local msg = Activity2_pb.HPExchangeInfoRet()
        msg:ParseFromString(msgBuff)
        self:refreshUserItemCount()
        self:handleAcitivityInfo(msg)
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        UserMercenaryManager:setMercenaryStatusInfos(msg.roleInfos)
        self:refreshUserItemCount()
        self.container.mScrollView:refreshAllCell()
        local c = 0
    end
end

function GoodsExchangePage_New:handleAcitivityInfo(msg)
    ExchangeActivityInfo.timeLeft = msg.lastCount
    if ExchangeActivityInfo.timeLeft > 0 and not TimeCalculator:getInstance():hasKey(GoodsExchangePage_New.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(GoodsExchangePage_New.timerName, ExchangeActivityInfo.timeLeft);
    end
    ExchangeActivityInfo.exchangeIdList = msg.exchangeIdList
    ExchangeActivityInfo.exchangeTimes = msg.exchangeTimes
    self:refreshPage()
end

function GoodsExchangePage_New:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function GoodsExchangePage_New:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function GoodsExchangePage_New:clearAllTitleItem(container)
    if container.m_pCostScrollViewFacade then
        container.m_pCostScrollViewFacade:clearAllItems();
    end
    if container.mCostScrollViewRootNode then
        container.mCostScrollViewRootNode:removeAllChildren();
    end
end

function GoodsExchangePage_New:deleteAllTitleItem(container)
    if container.mCostScrollView then
        container.mCostScrollView:removeAllCell();
    end
    GoodsExchangePage_New:clearAllTitleItem(container)
    if container.m_pCostScrollViewFacade then
        container.m_pCostScrollViewFacade:delete();
        container.m_pScrollViewFacade = nil;
    end
    container.mScrollViewRootNode = nil;
    container.mScrollView = nil;
end

function GoodsExchangePage_New:onExit(ParentContainer)
    self:clearAllItem();
    NodeHelper:deleteScrollView(self.container)
    TimeCalculator:getInstance():removeTimeCalcultor(GoodsExchangePage_New.timerName);
    self:removePacket(ParentContainer);
    GoodsExchangePage_New:deleteAllTitleItem(self.container)
    UserItemCountList = { }
    ExchangeActivityCfg = { }
    _TitleContainerCache = { }
    MercenaryCfg = nil
    _SelectIndex = 0
    onUnload(thisPageName, self.container);
end

return GoodsExchangePage_New

