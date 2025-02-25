
-- 活动id = 26

local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'QiXiXianGou'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local ItemManager = require "Item.ItemManager"
local ActivityFunction = require("ActivityFunction")
require("SteriousShop");
require("Shop_pb");

local thisActivityId = 26

local QiXiXianGou = { }
local opcodes = {
    TIME_LIMIT_PURCHASE_INFO_C = HP_pb.TIME_LIMIT_PURCHASE_INFO_C,
    TIME_LIMIT_PURCHASE_INFO_S = HP_pb.TIME_LIMIT_PURCHASE_INFO_S,
    TIME_LIMIT_BUY_C = HP_pb.TIME_LIMIT_BUY_C
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1
local PageInfo = {
    timerName = "QiXiXianGou_TimeLimit",
    timeLeft = 0,
    timeLimitItems = { },
    curOffset = nil
}
local curCountIndex = 0
local curCountItem = { }
local TimeLimitPurchaseCfg = { }
function QiXiXianGou.onFunction(eventName, container)
    if eventName == "onWishing" then
        PageManager.pushPage("ExpeditionContributePage")
    elseif eventName == "onStageReward" then

    elseif eventName == "onRankReward" then
        PageManager.pushPage("ExpeditionRankPage")
    end
end

function QiXiXianGou:onEnter(ParentContainer)
    local container = ScriptContentBase:create("Act_TimeLimitPurchaseContent.ccbi")
    self.container = container
    self.container:registerFunctionHandler(QiXiXianGou.onFunction)
    NodeHelper:initScrollView(self.container, "mContent", 7)
    TimeLimitPurchaseCfg = ConfigManager.getTimeLimitPurcgaseItem()
    self:registerPacket(ParentContainer)
    self:getActivityInfo()

    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite ~= nil then
        ParentContainer:autoAdjustResizeScale9Sprite(mScale9Sprite)
    end
    if container.mScrollView ~= nil then
        ParentContainer:autoAdjustResizeScrollview(container.mScrollView)
    end
    ActivityFunction:removeActivityRedPoint(thisActivityId)
    ActivityInfo.changeActivityNotice(thisActivityId)
    -- 隐藏红点
    -- self:refreshPage()
    return self.container
end

function QiXiXianGou:refreshPage()
    self:rebuildAllItem()
end

function QiXiXianGou:onExecute(ParentContainer)
    local timeStr = ''
    if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
        PageInfo.timeLeft = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
        if PageInfo.timeLeft > 0 then
            timeStr = common:second2DateString(PageInfo.timeLeft, false)
        end
    end
    NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
end
----------------scrollview-------------------------
local PurchasingItem = {
    ccbiFile = "Act_TimeLimitPurchaseListContent.ccbi"
}
function PurchasingItem.onFunction(eventName, container)
    --    if eventName == "luaRefreshItemView" then
    --        PurchasingItem.onRefreshItemView(container);
    --    elseif eventName == "onBuyBtn" then
    --        QiXiXianGou:onBuyBtn(container)
    --    elseif eventName == "onBuyBtnCount" then
    --        QiXiXianGou:onBuyBtnCount(container)
    --    elseif eventName == "mFeet" then
    --        QiXiXianGou:onFeet(container)
    --    end
end

function PurchasingItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function PurchasingItem:onBuyBtn()
    local index = self.id

    local itemId = PageInfo.timeLimitItems[index].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]

    --    local msg = Activity_pb.HPTimeLimitBuy()
    --    msg.cfgId = PageInfo.timeLimitItems[index].id
    --    msg.count = 1
    --    common:sendPacket(opcodes.TIME_LIMIT_BUY_C, msg, false)
    --    PageInfo.curOffset = QiXiXianGou.container.mScrollView:getContentOffset()

    if UserInfo.roleInfo.level >= itemInfo.levelLimit then
        local msg = Activity_pb.HPTimeLimitBuy()
        msg.cfgId = PageInfo.timeLimitItems[index].id
        msg.count = 1
        common:sendPacket(opcodes.TIME_LIMIT_BUY_C, msg, false)
        PageInfo.curOffset = QiXiXianGou.container.mScrollView:getContentOffset()
    else
        MessageBoxPage:Msg_Box_Lan("@TLPurchaseTxt2")
    end
end

function PurchasingItem:onBuyBtnCount()
    local index = self.id
    curCountIndex = index
    local itemId = PageInfo.timeLimitItems[index].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]
    curCountItem = itemInfo
    QiXiXianGou_BuyTimes()
end

function PurchasingItem:mFeet()
    local container = self.container
    local itemId = PageInfo.timeLimitItems[self.id].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]

    local rewardCfg = { };
    if itemInfo.goodsId ~= nil then
        for _, item in ipairs(common:split(itemInfo.goodsId, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardCfg, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end

    local thisItemId = rewardCfg[1].itemId
    local thisItemType = ItemManager:getTypeById(thisItemId)
    print("thisItemType = ", thisItemType)
    if thisItemType == Const_pb.GIFT then
        PageManager.showGiftPackage(thisItemId, nil)
    elseif thisItemType == Const_pb.EQUIP then
        local stepLevel = EquipManager:getEquipStepById(thisItemId)
        GameUtil:showTip(container:getVarNode('mFeet01'), {
            type = ConfigManager.getRewardById(itemInfo.goodsId)[1].type,
            itemId = thisItemId,
            buyTip = true,
            starEquip = stepLevel == GameConfig.ShowStepStar
        } )
    else
        GameUtil:showTip(container:getVarNode('mFeet01'), {
            type = rewardCfg[1].type,
            itemId = thisItemId,
            buyTip = false,
            starEquip = false
        } )
    end
end

function PurchasingItem:fillRewardItem(container, rewardCfg, params)
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    local btnSprite = { };
    local colorMap = { }

    local mainNode = params.mainNode
    local countNode = params.countNode
    local nameNode = params.nameNode
    local frameNode = params.frameNode
    local mFrameShade = params.mFrameShade
    local picNode = params.picNode

    local cfg = rewardCfg[1];
    -- nodesVisible[mainNode] = cfg ~= nil;
    if cfg ~= nil then
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
        if resInfo ~= nil then
            sprite2Img[picNode] = resInfo.icon;
            sprite2Img[mFrameShade] = NodeHelper:getImageBgByQuality(resInfo.quality)
            -- lb2Str[countNode] = "x" .. cfg.count;
            lb2Str[nameNode] = resInfo.name;
            menu2Quality[frameNode] = resInfo.quality;
            colorMap[nameNode] = ConfigManager.getQualityColor()[resInfo.quality].textColor
        else
            CCLuaLog("Error::***reward item not found!!");
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorMap)
end

function PurchasingItem:onPreLoad(ccbRoot)

end

function PurchasingItem:onUnLoad(ccbRoot)

end


function PurchasingItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    if self.container == nil then
        return
    end
    local container = self.container
    local index = self.id
    local itemId = PageInfo.timeLimitItems[index].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]

    -- local rewardCfg = {ConfigManager.getRewardById(itemInfo.goodsId)[1]}

    local rewardCfg = { };
    if itemInfo.goodsId ~= nil then
        for _, item in ipairs(common:split(itemInfo.goodsId, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardCfg, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end

    local params = {
        mainNode = "mItemName",
        countNode = "mNum",
        nameNode = "mName1",
        frameNode = "mFeet01",
        picNode = "mPic1",
        mFrameShade = "mFrameShade",
        startIndex = 1,
    }

    NodeHelper:setStringForLabel(container, { mTextNum01 = "x" .. rewardCfg[1].count });
    self:fillRewardItem(container, rewardCfg, params)

    -- container:getVarSprite("mPic"):setTexture( goodsItem.icon )
    -- NodeHelper:setMenuItemQuality( container , "mFeet01" ,goodsItem.quality  )
    NodeHelper:setNodesVisible(container, { mCanBuyNumLabel = false })
    local buyStr = ""
    if itemInfo.buyType == "1" or itemInfo.buyType == "2" then
        buyStr = common:getLanguageString("@BuyStr" .. itemInfo.buyType, PageInfo.timeLimitItems[index].buyTimes, itemInfo.maxBuyTimes)
        NodeHelper:setNodesVisible(container, { mBtnNode = true, mBtnCountNode = false })
    end

    if itemInfo.buyType == "3" then
        buyStr = common:getLanguageString("@BuyStr" .. itemInfo.buyType, PageInfo.timeLimitItems[index].buyTimes)
        NodeHelper:setNodesVisible(container, { mBtnNode = false, mBtnCountNode = true })
        container:getVarNode("mBtnCountNode"):setTag(index);
        NodeHelper:setMenuItemEnabled(container, "mBuyBtnCount", true)
        NodeHelper:setNodeIsGray(container, { mChatBtnCountTxt2 = false })

        if PageInfo.timeLimitItems[index].leftBuyTimes == 0 then
            NodeHelper:setMenuItemEnabled(container, "mBuyBtnCount", false)
            NodeHelper:setNodeIsGray(container, { mChatBtnCountTxt2 = true })
        end
    end


    NodeHelper:setStringForLabel(container, { mActCanBuyLabel = buyStr })
    NodeHelper:setStringForLabel(container, { mRemainingQuantity = PageInfo.timeLimitItems[index].leftBuyTimes })

    -- container:getVarLabelTTF("mActCanBuyLabel"):setString(buyStr)
    -- container:getVarLabelTTF("mRemainingQuantity"):setString(PageInfo.timeLimitItems[index].leftBuyTimes)
    -- container:getVarLabelTTF("mOriginalPrice"):setString(common:getLanguageString("@OriginalPrice", itemInfo.originalPrice))
    -- container:getVarLabelTTF("mSpecialOffer"):setString(common:getLanguageString("@SalePrice", itemInfo.salePrice))


    NodeHelper:setStringForLabel(container, { mOriginalPrice = common:getLanguageString("@OriginalPrice", itemInfo.originalPrice) })
    NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString("@SalePrice", itemInfo.salePrice) })

    -- container:getVarLabelTTF("mOriginalPrice"):setString(common:getLanguageString("@OriginalPrice" , itemInfo.originalPrice))  --原价
    -- container:getVarLabelBMFont("mChatBtnTxt2"):setString(common:getLanguageString("@SalePrice" , itemInfo.salePrice))           --现价

    if tonumber(itemInfo.vipLimit) == 0 then
        NodeHelper:setNodesVisible(container, { mCanBuyVip = false })
        -- container:getVarLabelTTF("mCanBuyVip"):setVisible(false)
    else
        NodeHelper:setNodesVisible(container, { mCanBuyVip = true })
        NodeHelper:setStringForLabel(container, { mCanBuyVip = common:getLanguageString("@PurchasingVipLimit", itemInfo.vipLimit) })
        -- container:getVarLabelTTF("mCanBuyVip"):setVisible(true)
        -- container:getVarLabelTTF("mCanBuyVip"):setString(common:getLanguageString("@PurchasingVipLimit", itemInfo.vipLimit))
    end

    if tonumber(itemInfo.levelLimit) == 0 then
        NodeHelper:setNodesVisible(container, { mCanBuyLv = false })
        -- container:getVarLabelTTF("mCanBuyLv"):setVisible(false)
    else
        NodeHelper:setNodesVisible(container, { mCanBuyLv = false })
        NodeHelper:setStringForLabel(container, { mCanBuyLv = common:getLanguageString("@PurchasingLvLimit", itemInfo.levelLimit) })
        -- container:getVarLabelTTF("mCanBuyLv"):setVisible(true)
        -- container:getVarLabelTTF("mCanBuyLv"):setString(common:getLanguageString("@PurchasingLvLimit", itemInfo.levelLimit))
    end

    -- and UserInfo.roleInfo.level >= itemInfo.levelLimit
    if UserInfo.roleInfo
        and UserInfo.playerInfo and UserInfo.playerInfo.vipLevel >= itemInfo.vipLimit
        and(tonumber(itemInfo.maxBuyTimes) == 0 or PageInfo.timeLimitItems[index].buyTimes < tonumber(itemInfo.maxBuyTimes)) then
        -- and PageInfo.timeLimitItems[index].buyTimes > 0 then
        -- 可以买
        NodeHelper:setMenuItemEnabled(container, "mBuyBtn", true)
        NodeHelper:setNodeIsGray(container, { mHasBuy = false })
        NodeHelper:setStringForLabel(container, { mHasBuy = common:getLanguageString("@Buy") })
        -- NodeHelper:setNodeIsGray(container, { mChatBtnTxt2 = false })
        -- NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString("@Buy") })
        -- NodeHelper:setNodesVisible(container, { mBuyBtnTextNode = true, mHasBuyBtnTextNode = false })
    else
        -- 不能购买
        NodeHelper:setMenuItemEnabled(container, "mBuyBtn", false)
        NodeHelper:setNodeIsGray(container, { mHasBuy = true })
        NodeHelper:setStringForLabel(container, { mHasBuy = common:getLanguageString("@HasBuy") })
        -- NodeHelper:setNodeIsGray(container, { mChatBtnTxt2 = true })
        -- NodeHelper:setNodesVisible(container, { mBuyBtnTextNode = false, mHasBuyBtnTextNode = true })
        if PageInfo.timeLimitItems[index].buyTimes >= tonumber(itemInfo.maxBuyTimes) then
            -- NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString("@HasBuy") })
            -- NodeHelper:setNodesVisible(container, { mBuyBtnTextNode = false, mHasBuyBtnTextNode = true })
        else
            -- NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString("@Buy") })
            -- NodeHelper:setNodesVisible(container, { mBuyBtnTextNode = true, mHasBuyBtnTextNode = false })
        end
    end
    container:getVarNode("mAllSurplus"):setVisible(PageInfo.timeLimitItems[index].leftBuyTimes ~= -1)


    if itemInfo.id == 1 then
        --        if itemInfo.message_1 == nil or itemInfo.message_2 == nil then
        --            return
        --        end
        --        local sp = container:getVarSprite("mBG")

        --        if sp then
        --            sp:setTexture("BG/Activity/Activity_bg_22.png")
        --        end
    else
        --        if itemInfo.message_1 == nil then
        --            return
        --        end
        --        local sp = container:getVarSprite("mBG")
        --        if sp then
        --            sp:setTexture("BG/Activity/Activity_bg_22.png")
        --        end
        --        NodeHelper:setStringForLabel(container, { mMessage_2 = common:getLanguageString(itemInfo.message_1) })
    end

    NodeHelper:setNodesVisible(container, { mMessageNode = false })

    NodeHelper:setNodesVisible(container, { mS9_1 = false, mS9_2 = true })

end

function QiXiXianGou:rebuildAllItem()
    self:clearAllItem()
    self:buildItem()
end

function QiXiXianGou:clearAllItem()
    -- NodeHelper:clearScrollView(self.container)
    self.container.mScrollView:removeAllCell()
end

function QiXiXianGou:buildItem()
    local maxSize = table.maxn(PageInfo.timeLimitItems)
    -- NodeHelper:buildScrollView(self.container, maxSize, PurchasingItem.ccbiFile, PurchasingItem.onFunction);

    self.container.mScrollView:removeAllCell()
    for i = 1, maxSize do
        local titleCell = CCBFileCell:create()
        local panel = PurchasingItem:new( { id = i })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(PurchasingItem.ccbiFile)
        self.container.mScrollView:addCellBack(titleCell)
    end
    self.container.mScrollView:orderCCBFileCells()

end

function QiXiXianGou:onBuyBtn(container)
    local index = container:getItemDate().mID
    local msg = Activity_pb.HPTimeLimitBuy()
    msg.cfgId = PageInfo.timeLimitItems[index].id
    msg.count = 1
    common:sendPacket(opcodes.TIME_LIMIT_BUY_C, msg, false)
    PageInfo.curOffset = QiXiXianGou.container.mScrollView:getContentOffset()
end


function QiXiXianGou:onBuyBtnCount(container)
    local index = container:getVarNode("mBtnCountNode"):getTag();
    curCountIndex = index
    local itemId = PageInfo.timeLimitItems[index].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]
    curCountItem = itemInfo
    QiXiXianGou_BuyTimes()
    -- local index = container:getItemDate().mID
    -- local msg = Activity_pb.HPTimeLimitBuy()
    -- msg.cfgId = PageInfo.timeLimitItems[index].id
    -- msg.count = 5
    -- common:sendPacket(opcodes.TIME_LIMIT_BUY_C , msg ,false)
    -- PageInfo.curOffset = QiXiXianGou.container.mScrollView:getContentOffset()
end

local function toPurchaseTimes(boo, times)
    if boo then
        local index = curCountIndex
        local msg = Activity_pb.HPTimeLimitBuy()
        msg.cfgId = PageInfo.timeLimitItems[index].id
        msg.count = times
        common:sendPacket(opcodes.TIME_LIMIT_BUY_C, msg, false)
        PageInfo.curOffset = QiXiXianGou.container.mScrollView:getContentOffset()
    end
end

function QiXiXianGou_BuyTimes()
    -- 根据vip等级,判断剩余购买次数
    UserInfo.syncPlayerInfo()
    local itemInfo = curCountItem
    local vipLevel = UserInfo.playerInfo.vipLevel

    local leftTime = PageInfo.timeLimitItems[curCountIndex].leftBuyTimes
    -- 999
    local title = common:getLanguageString("@ManyPeopleShopGiftTitle")
    local message = common:getLanguageString("@ManyPeopleShopGiftInfoTxt")
    local buyedTimes = 1
    -- ArenaAlreadyBuyTimes or 0

    PageManager.showCountTimesPage(title, message, leftTime,
    function(times)
        local totalPrice = itemInfo.salePrice * times

        return totalPrice
    end
    , Const_pb.MONEY_GOLD, toPurchaseTimes, nil, nil, "@ManyPeopleShopGiftInfoTxtMax")
end

function QiXiXianGou:onFeet(container)
    local index = container:getItemDate().mID;
    local itemId = PageInfo.timeLimitItems[index].id
    local itemInfo = TimeLimitPurchaseCfg[itemId]

    local rewardCfg = { };
    if itemInfo.goodsId ~= nil then
        for _, item in ipairs(common:split(itemInfo.goodsId, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardCfg, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end

    local thisItemId = rewardCfg[1].itemId
    local thisItemType = ItemManager:getTypeById(thisItemId)
    print("thisItemType = ", thisItemType)
    if thisItemType == Const_pb.GIFT then
        PageManager.showGiftPackage(thisItemId, nil)
    elseif thisItemType == Const_pb.EQUIP then
        local stepLevel = EquipManager:getEquipStepById(thisItemId)
        GameUtil:showTip(container:getVarNode('mFeet01'), {
            type = ConfigManager.getRewardById(itemInfo.goodsId)[1].type,
            itemId = thisItemId,
            buyTip = true,
            starEquip = stepLevel == GameConfig.ShowStepStar
        } )
    else
        GameUtil:showTip(container:getVarNode('mFeet01'), {
            type = rewardCfg[1].type,
            itemId = thisItemId,
            buyTip = false,
            starEquip = false
        } )
    end
end

function QiXiXianGou:getActivityInfo()
    common:sendEmptyPacket(opcodes.TIME_LIMIT_PURCHASE_INFO_C, true)
end
function QiXiXianGou:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.TIME_LIMIT_PURCHASE_INFO_S then
        local msg = Activity_pb.TimeLimitPurchase()
        msg:ParseFromString(msgBuff)
        self:handleAcitivityInfo(msg)
    end
end

function QiXiXianGou:sortGiftOrder(tablename)
    -- 排序
    -- 已领取时显示顺序放到最后，多个已领取时再根据ID顺序排序，放到最后的逻辑在领取时即时生效即可
    local function sortfunction(left, right)
        local leftItemInfo = TimeLimitPurchaseCfg[left.id]
        local rightItemInfo = TimeLimitPurchaseCfg[right.id]

        if UserInfo.roleInfo and UserInfo.playerInfo then
            local isLeftFlag =
            -- UserInfo.roleInfo.level >= leftItemInfo.levelLimit and
            UserInfo.playerInfo.vipLevel >= leftItemInfo.vipLimit
            and(tonumber(leftItemInfo.maxBuyTimes) == 0
            or left.buyTimes < tonumber(leftItemInfo.maxBuyTimes));

            local isRightFlag =
            -- UserInfo.roleInfo.level >= rightItemInfo.levelLimit and
            UserInfo.playerInfo.vipLevel >= rightItemInfo.vipLimit
            and(tonumber(rightItemInfo.maxBuyTimes) == 0
            or right.buyTimes < tonumber(rightItemInfo.maxBuyTimes));
            if isLeftFlag ~= isRightFlag then
                return isLeftFlag;
            end
        end
        return left.id < right.id
    end
    table.sort(PageInfo.timeLimitItems, sortfunction)
end

function QiXiXianGou:handleAcitivityInfo(msg)
    PageInfo.timeLeft = msg.leftTime
    if PageInfo.timeLeft > 0 and not TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(PageInfo.timerName, PageInfo.timeLeft);
    end

    PageInfo.timeLimitItems = msg.timeLimitItems
    self:sortGiftOrder();
    self:rebuildAllItem(self.container)
    if PageInfo.curOffset ~= nil then
        self.container.mScrollView:setContentOffset(PageInfo.curOffset)
    end
end	
function QiXiXianGou:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function QiXiXianGou:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function QiXiXianGou:onExit(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
    self:removePacket(ParentContainer)
    onUnload(thisPageName, self.container)
end

return QiXiXianGou
