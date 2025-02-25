----------------------------------------------------------------------------------
--[[
	咏花吟月  福袋
--]]
----------------------------------------------------------------------------------

------------------------------------local variable--------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Activity_pb = require("Activity_pb")
local Const_pb = require("Const_pb")
local json = require('json')
local Recharge_pb = require "Recharge_pb"
local NewbieGuideManager = require("NewbieGuideManager")
local ActivityFunction = require("ActivityFunction")
local thisPageName = 'DiscountGiftPage'
local DiscountGiftPage = { }
local DiscountGiftRequestData = false-- 向服务器发送请求，防止不断发包
local mSalePacketContainerRef = { };-- 存储折扣礼包 Container
local mSalePacketListContentTimeName = { };-- 保存每个Item的倒计时名字GiftItemCountdownName+id
local SaleContent = {
    ccbiFile = "Act_FixedTimeGiftDiscountListContent.ccbi",
    giftInfos = { },
    receiveTimes = { },
    salePacketLastTime = 0,
    curOffset = nil,
}

local GiftDataStatus =
{
    -- 不可购买，也不可领取（达到购买次数，并且已领取）
    AlreadyReceive = 0,
    -- 可购买
    CanBuy = 1,
    -- 可领取
    CanReceive = 2,
}

local mItemData = { }

function SaleContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

local SalepacketCfg = { }
local option = {
    ccbiFile = "Act_FixedTimeGiftDiscountContent.ccbi",
    handlerMap =
    {
        onRecharge = "onRecharge",
        -- 果断充值
        onReceive = "onReceive",
        -- 领取奖励
        onReturnButton = "onBack",
        -- 返回
        onHelp = "onHelp",-- 帮助
    },
}
-- 活动基本信息
local thisActivityInfo = {
    id = 22,
    remainTime = 0,
    accRechargeDiamond = 0,
    -- 累计充值钻石
    canReceiveDiamond = 0,-- 可领取钻石
}
--------------------------------page show--------------------------------------
function DiscountGiftPage:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)

    self.container = container
    container.mScrollView = container:getVarScrollView("mContent")
    SalepacketCfg = ConfigManager.getRechargeDiscountCfg()
    self:registerPacket(parentContainer)

    -- if self.container.mScrollView~=nil then
    --     parentContainer:autoAdjustResizeScrollview(self.container.mScrollView);
    -- end
    -- NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite1"))
    -- NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite2"))

    local msg = Activity2_pb.DiscountInfoReq()
    msg.actId = Const_pb.DISCOUNT_GIFT
    common:sendPacket(HP_pb.DISCOUNT_GIFT_INFO_C, msg, true)
    ActivityFunction:removeActivityRedPoint(94)
    ActivityInfo.changeActivityNotice(94)
    -- 隐藏红点
    return container
end



function DiscountGiftPage:onExit(parentContainer)
    self:removePacket(parentContainer)
    NodeHelper:deleteScrollView(self.container);

    SaleContent.curOffset = nil
    for i, v in pairs(mSalePacketListContentTimeName) do
        TimeCalculator:getInstance():removeTimeCalcultor(v);
    end
    mSalePacketContainerRef = { }
    mSalePacketListContentTimeName = { }
    SaleContent.giftInfos = { }
    self.container = nil
end

function DiscountGiftPage:onRefreshPage(container)
    local lb2Str = {
        mCurrentDiamondsNum = common:getLanguageString("@RebateCurrentDiamondsNum",thisActivityInfo.accRechargeDiamond),
        mReceiveDiamondsNum = common:getLanguageString("@RebateReceiveDiamondsNum",thisActivityInfo.canReceiveDiamond),
        mCumulativeDiamondsNum = common:getLanguageString("@RebateCumulativeDiamondsNum",thisActivityInfo.accRechargeDiamond),
        mReceiveDiamondsTodayNum = common:getLanguageString("@RebateReveiveDiamondsTodayNum",thisActivityInfo.canReceiveDiamond),
    }
    NodeHelper:setStringForLabel(container, lb2Str)

    -- 如果活动开启，并且累计充值大于等于0
    if thisActivityInfo.accRechargeDiamond >= 0 and thisActivityInfo.remainTime > 0 then
        local progressBar = container:getVarScale9Sprite("mBar")
        local accPercent = thisActivityInfo.accRechargeDiamond / 10000
        if progressBar ~= nil and accPercent >= 0 then
            progressBar:setScaleX(math.min(accPercent, 1.0))
        end
    end
end

function DiscountGiftPage:onExecute(parentContainer)
    -- self:onTimer(self.container)
end

function DiscountGiftPage:onTimer(container)
    for i, v in ipairs(SaleContent.giftInfos) do
        if v.goodsId ~= nil and TimeCalculator:getInstance():hasKey(mSalePacketListContentTimeName[v.goodsId]) then
            remainTime = TimeCalculator:getInstance():getTimeLeft(mSalePacketListContentTimeName[v.goodsId])
            v.countdownTime = remainTime
            if remainTime <= 0 then
                TimeCalculator:getInstance():removeTimeCalcultor(mSalePacketListContentTimeName[v.goodsId]);
                if mSalePacketContainerRef[v.goodsId] then
                    NodeHelper:setStringForLabel(mSalePacketContainerRef[v.goodsId], { mChatBtnTxt2 = "" })
                end

                if DiscountGiftRequestData == false then
                    DiscountGiftRequestData = true
                    local msg = Activity2_pb.DiscountInfoReq()
                    msg.actId = Const_pb.DISCOUNT_GIFT
                    common:sendPacket(HP_pb.DISCOUNT_GIFT_INFO_C, msg, true)
                end
            else
                if mSalePacketContainerRef[v.goodsId] then
                    local dateDay = common:getDayNumber(remainTime);
                    if dateDay < 2 then
                        -- 倒计时小于两天开始显示
                        timeStr = common:second2DateString(remainTime, false);
                        NodeHelper:setStringForLabel(mSalePacketContainerRef[v.goodsId], { mChatBtnTxt2 = common:getLanguageString('@ActFTGiftDiscountTimeTxt', timeStr) })
                    else
                        NodeHelper:setStringForLabel(mSalePacketContainerRef[v.goodsId], { mChatBtnTxt2 = "" })
                    end
                end
            end
        end
    end

end

function DiscountGiftPage:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "RechargeRebate_enter_rechargePage")
    PageManager.pushPage("RechargePage");
end

function DiscountGiftPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_RECHARGEREBATE)
end

function DiscountGiftPage:onReceive(container)
    if GlobalData.nowActivityId ~= nil and GlobalData.nowActivityId == 28 then
        local msg = Activity_pb.HPRebateAward()
        msg.activityId = GlobalData.nowActivityId
        common:sendPacket(HP_pb.RECHARGE_REBATE_AWARD_C, msg);
    else
        local msg = Activity_pb.HPRebateAward()
        msg.activityId = thisActivityInfo.id
        common:sendPacket(HP_pb.RECHARGE_REBATE_AWARD_C, msg)
    end
end

function DiscountGiftPage:onBack(container)
    PageManager.changePage("ActivityPage")
end


--------------------------------packet handler----------------------------------
function DiscountGiftPage:registerPacket(container)
    container:registerPacket(HP_pb.DISCOUNT_GIFT_INFO_S)
    container:registerPacket(HP_pb.DISCOUNT_GIFT_BUY_SUCC_S)
    container:registerPacket(HP_pb.DISCOUNT_GIFT_GET_REWARD_S)
end

function DiscountGiftPage:removePacket(container)
    container:removePacket(HP_pb.DISCOUNT_GIFT_INFO_S)
    container:removePacket(HP_pb.DISCOUNT_GIFT_BUY_SUCC_S)
    container:removePacket(HP_pb.DISCOUNT_GIFT_GET_REWARD_S)
end

function DiscountGiftPage.SortGiftOrder(left, right)
    if left.status ~= right.status then
        if left.status == GiftDataStatus.CanReceive then
            return true
        elseif right.status == GiftDataStatus.CanReceive then
            return false
        elseif left.status == GiftDataStatus.CanBuy then
            return true
        elseif right.status == GiftDataStatus.CanBuy then
            return false
        end
    end
    return SalepacketCfg[left.goodsId].index < SalepacketCfg[right.goodsId].index
    --    local shopItem_1 = DiscountGiftPage:getRechargeDataByGoodsId(left.goodsId)
    --    local shopItem_2 = DiscountGiftPage:getRechargeDataByGoodsId(right.goodsId)
    --    if shopItem_1 == nil or  shopItem_2 == nil then
    --      return false
    --    end
    --    return shopItem_1.productPrice < shopItem_2.productPrice
end


function DiscountGiftPage:getRechargeDataByGoodsId(goodsId)
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == tonumber(goodsId) then
            return RechargeCfg[i]
        end
    end
end

function DiscountGiftPage:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()

    if opcode == HP_pb.DISCOUNT_GIFT_INFO_S then
        DiscountGiftRequestData = false
        mSalePacketListContentTimeName = { }
        mSalePacketContainerRef = { }
        local msg = Activity2_pb.HPDiscountInfoRet()
        msg:ParseFromString(msgBuff)
        SaleContent.giftInfos = msg.info;
        table.sort(SaleContent.giftInfos, self.SortGiftOrder)
        self:clearAndReBuildAllItem(self.container)
    end
    if opcode == HP_pb.DISCOUNT_GIFT_BUY_SUCC_S then
        local msg = Activity2_pb.HPDiscountBuySuccRet()
        msg:ParseFromString(msgBuff)
        for i, v in ipairs(SaleContent.giftInfos) do
            if v.goodsId == msg.goodsId then
                v.status = GiftDataStatus.CanReceive
                v.buyTimes = v.buyTimes + 1
            end
        end
        table.sort(SaleContent.giftInfos, self.SortGiftOrder)
        self:clearAndReBuildAllItem(self.container)
    end

    if opcode == HP_pb.DISCOUNT_GIFT_GET_REWARD_S then
        local msg = Activity2_pb.HPDiscountGetRewardRes()
        msg:ParseFromString(msgBuff)
        for i, v in ipairs(SaleContent.giftInfos) do
            if v.goodsId == msg.goodsId then
                local id = msg.goodsId
                --                if v.buyTimes >= SalepacketCfg[v.goodsId].limitNum then
                --                    v.status = GiftDataStatus.AlreadyReceive
                --                else
                --                    v.status = GiftDataStatus.CanBuy
                --                end

                --if SalepacketCfg[id].limitType == 3 then
                --    v.status = GiftDataStatus.CanBuy
                --else
                    if v.buyTimes >= SalepacketCfg[v.goodsId].limitNum then
                        v.status = GiftDataStatus.AlreadyReceive
                    else
                        v.status = GiftDataStatus.CanBuy
                    end
                --end
            end
        end
        table.sort(SaleContent.giftInfos, self.SortGiftOrder)
        self:clearAndReBuildAllItem(self.container)
        DiscountGiftPage:clearNotice()
    end
end

function DiscountGiftPage:clearNotice()
    -- 红点消除
    local hasNotice = false
    for i, v in ipairs(SaleContent.giftInfos) do
        if v.status == GiftDataStatus.CanReceive then
            hasNotice = true
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.DISCOUNT_GIFT);
    end
end

function SaleContent.parsePacketState(id)
    local alreadyBuy = false;
    local alreadyReceive = false;
    for i = 1, #SaleContent.alreadyBuytList do
        if SaleContent.alreadyBuytList[i] == id then
            alreadyBuy = true;
            if SaleContent.receiveTimes[i] ~= 0 then
                alreadyReceive = true;
            end
            break
        end
    end
    return alreadyBuy, alreadyReceive
end


function SaleContent:onPreLoad(ccbRoot)

end


function SaleContent:onUnLoad(container)
    local giftData = SaleContent.giftInfos[self.id]
    if not giftData then return end
    local id = giftData.goodsId
    mSalePacketContainerRef[id] = nil
    -- mSalePacketListContentTimeName[id] = "GiftItemCountdownName"..id
    -- TimeCalculator:getInstance():removeTimeCalcultor(mSalePacketListContentTimeName[id]);
end

function SaleContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local giftData = SaleContent.giftInfos[self.id]
    local id = giftData.goodsId
    local packetItem = SalepacketCfg[id].salepacket;
    mSalePacketContainerRef[id] = container;
    -- NodeHelper:setStringForLabel(container,{mDiscountTxt = common:getLanguageString(SalepacketCfg[id].name)})
    -------------------------------------------------
    -- TODO
    --    mSalePacketListContentTimeName[id] = "GiftItemCountdownName" .. id
    --    if giftData.countdownTime > 0 then
    --        TimeCalculator:getInstance():createTimeCalcultor(mSalePacketListContentTimeName[id], giftData.countdownTime);
    --    end
    -----------------------------------------------
    if packetItem ~= nil then
        -- 显示物品SaleContent.alreadyBuytList receiveTimes
        -- local alreadyBuy = false;--是否已购买
        -- local alreadyReceive = false;--是否已领取
        -- alreadyBuy,alreadyReceive = SaleContent.parsePacketState(id);
        local rewardItems = { }
        local nNum = 0;
        local SalePrice = 0
        -- 折扣后商品价格
        for _, item in ipairs(common:split(packetItem, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
                isgold = SalepacketCfg[id].isgold
            } );
            nNum = nNum + 1;
        end
        for i = 1, #RechargeCfg do
            if tonumber(RechargeCfg[i].productId) == tonumber(id) then
                SalePrice = RechargeCfg[i].productPrice;
                break
            end
        end
        local price = GameUtil:CNYToPlatformPrice(SalepacketCfg[id].formerPrice, "H365")
        if Golb_Platform_Info.is_r18 then
            price = GameUtil:CNYToPlatformPrice(SalepacketCfg[id].formerPrice, "EROR18")
        elseif Golb_Platform_Info.is_jgg then
            price = GameUtil:CNYToPlatformPrice(SalepacketCfg[id].formerPrice, "JGG")
        end
        local lb2Str =
        {
            mValueNum = common:getLanguageString("@RMB") .. price,-- 原始商品价格
            mOriginalHNP = price,-- 原始商品价格HNP
            mOriginalJgg = price-- 原始商品价格JGG
        }
        SaleContent:fillRewardItem(container, rewardItems, 3)
        NodeHelper:setStringForLabel(container, lb2Str);
        NodeHelper:setNodesVisible(container, { mCostNum = true , mValueNum = Golb_Platform_Info.is_h365
                                , mHoneyPNode = Golb_Platform_Info.is_r18, mJggNode = Golb_Platform_Info.is_jgg
                                , mOriginalNode = Golb_Platform_Info.is_r18, mOriginalJggNode = Golb_Platform_Info.is_jgg })

        -- RechargeCfg formerPrice
        local enabledBtn = true;
        local ShowText = "";
        local fntPath = GameConfig.FntPath.Bule
        local btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
        NodeHelper:setNodesVisible(container, { mCostNum = true, mHoneyPNode = false, mJggNode = false })
        if giftData.status == GiftDataStatus.AlreadyReceive then
            enabledBtn = false
            ShowText = common:getLanguageString('@AlreadyReceive')
        elseif giftData.status == GiftDataStatus.CanReceive then
            ShowText = common:getLanguageString('@CanReceive')
            btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
            fntPath = GameConfig.FntPath.Bule
        elseif giftData.status == GiftDataStatus.CanBuy then
            ShowText = common:getLanguageString("@RMB") .. tostring(SalePrice)
            btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
            fntPath = GameConfig.FntPath.Golden
            NodeHelper:setNodesVisible(container, { mCostNum = Golb_Platform_Info.is_h365, mHoneyPNode = Golb_Platform_Info.is_r18, mJggNode = Golb_Platform_Info.is_jgg })
            if (Golb_Platform_Info.is_r18)  then--R18 
                ShowText = tostring(SalePrice)
                btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
                fntPath = GameConfig.FntPath.Golden
            elseif (Golb_Platform_Info.is_jgg) then --jgg
                ShowText = tostring(GameUtil:CNYToPlatformPrice(SalePrice, "JGG"))
                btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
                fntPath = GameConfig.FntPath.Golden
            end
        end

        NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
        NodeHelper:setBMFontFile(container, { mCostNum = fntPath , mmItemHNP = fntPath , mItemJgg = fntPath })
        local limitStr = ""
        if SalepacketCfg[id].limitType == 1 then
            limitStr = common:getLanguageString("@dayLimit", SalepacketCfg[id].limitNum - giftData.buyTimes)
        elseif SalepacketCfg[id].limitType == 2 then
            limitStr = common:getLanguageString("@weekLimit", SalepacketCfg[id].limitNum - giftData.buyTimes)
        else
            -- limitStr = common:getLanguageString("@noLimit", SalepacketCfg[id].limitNum - giftData.buyTimes)
            limitStr = common:getLanguageString("@noLimit", SalepacketCfg[id].limitNum - giftData.buyTimes)
        end


        NodeHelper:setStringForLabel(container, { mChatBtnTxt1 = limitStr });
        NodeHelper:setStringForLabel(container, {
            mCostNum = ShowText,
            mmItemHNP = ShowText,
            mItemJgg = ShowText,
            mDiscountTxt = common:getLanguageString(SalepacketCfg[id].name)
        } );
        NodeHelper:setMenuItemEnabled(container, "mBtn", enabledBtn);
        NodeHelper:setNodeIsGray(container, { mCostNum = not enabledBtn , mmItemHNP = not enabledBtn, mItemJgg = not enabledBtn })
        CCLuaLog("mCostNum " .. ShowText)

    end
end

function SaleContent:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4;
    isShowNum = isShowNum or false
    local nodesVisible = { };
    local lb2Str = { };
    local sprite2Img = { };
    local menu2Quality = { };
    local colorMap = { }

    for i = 1, maxSize do
        local cfg = rewardCfg[i];
        nodesVisible["mRewardNode" .. i] = cfg ~= nil;

        if cfg ~= nil then
            -- dump(cfg)
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon;
                lb2Str["mNum" .. i] = GameUtil:formatNumber(cfg.count)
                lb2Str["mName" .. i] = resInfo.name;
                menu2Quality["mFrame" .. i] = resInfo.quality
                -- colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count;
                end
                if cfg.type == 40000 then
                    -- 装备根据配置增加金装特效
                    local aniNode = container:getVarNode("mAni" .. i);
                    if aniNode then
                        aniNode:removeAllChildren();
                        local ccbiFile = GameConfig.GodlyEquipAni[cfg.isgold];
                        aniNode:setVisible(false);
                        if ccbiFile ~= nil then
                            local ani = ScriptContentBase:create(ccbiFile);
                            ani:release()
                            ani:unregisterFunctionHandler();
                            aniNode:addChild(ani);
                            aniNode:setVisible(true);
                        end
                    end
                    -- 装备根据配置增加金装特效
                end
                -- html
                local htmlNode = container:getVarLabelBMFont("mName" .. i)
                if not htmlNode then htmlNode = container:getVarLabelTTF("mName" .. i) end
                if htmlNode then
                    local htmlLabel;
                    -- 泰语太长 修改htmlLabel的大小
                    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
                        htmlNode:setVisible(false)
                        htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(110, 32), resInfo.name)
                        htmlLabel:setScaleX(htmlNode:getScaleX())
                        htmlLabel:setScaleY(htmlNode:getScaleY())
                    end
                end
            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end

    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setColorForLabel(container, colorMap)
end

function SaleContent:onBtn(container)
    local giftData = SaleContent.giftInfos[self.id]
    local id = giftData.goodsId
    -- giftData.status = 2
    if giftData.status == GiftDataStatus.CanReceive then
        -- 领取
        local msg = Activity2_pb.HPDiscountGetRewardReq()
        msg.goodsId = id;
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.DISCOUNT_GIFT_GET_REWARD_C, pb, #pb, true)
        if mContainerRef and mContainerRef.mScrollView2 then
            SaleContent.curOffset = mContainerRef.mScrollView2:getContentOffset()
        end
    elseif giftData.status == GiftDataStatus.CanBuy then
        UserInfo.sync()
        local userLevel = UserInfo.roleInfo.level
        if userLevel > tonumber(SalepacketCfg[id].minLevel) and userLevel <= tonumber(SalepacketCfg[id].maxLevel) then
            DiscountGiftPage:buyGoods(container, id);
            if mContainerRef and mContainerRef.mScrollView2 then
                SaleContent.curOffset = mContainerRef.mScrollView2:getContentOffset()
            end
        else
            MessageBoxPage:Msg_Box_Lan("@LevelLimit")
        end

    end
end

function SaleContent:onFrame1(container)
    SaleContent:onShowItemInfo(container, self.id, 1)
end

function SaleContent:onFrame2(container)
    SaleContent:onShowItemInfo(container, self.id, 2)
end

function SaleContent:onFrame3(container)
    SaleContent:onShowItemInfo(container, self.id, 3)
end

function SaleContent:onShowItemInfo(container, index, goodIndex)
    local giftData = SaleContent.giftInfos[index]
    local id = giftData.goodsId
    local packetItem = SalepacketCfg[id].salepacket;
    local rewardItems = { }
    for _, item in ipairs(common:split(packetItem, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(rewardItems, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        } );
    end
    GameUtil:showTip(container:getVarNode('mPic' .. goodIndex), rewardItems[goodIndex])
end


function DiscountGiftPage:buyGoods(container, id)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        CCLuaLog('buyGoods: productName=' .. RechargeCfg[i].productName .. "id=" .. id)
        if tonumber(RechargeCfg[i].productId) == tonumber(id) then
            itemInfo = RechargeCfg[i];
            break
        end
    end
    if itemInfo == nil then return end
    CCLuaLog('buyGoods: productId=' .. itemInfo.productId .. "id=" .. id)
    local buyInfo = BUYINFO:new()
    buyInfo.productType = itemInfo.productType;
    buyInfo.name = itemInfo.name;
    buyInfo.productCount = 1
    buyInfo.productName = itemInfo.productName
    buyInfo.productId = itemInfo.productId
    buyInfo.productPrice = itemInfo.productPrice
    buyInfo.productOrignalPrice = itemInfo.gold
    buyInfo.description = ""
    if itemInfo:HasField("description") then
        buyInfo.description = itemInfo.description
    end
    buyInfo.serverTime = GamePrecedure:getInstance():getServerTime()

    local _type = tostring(itemInfo.productType)
--    if Golb_Platform_Info.is_yougu_platform then
--        -- 悠谷平台需要转换 productType
--        local rechargeTypeCfg = ConfigManager.getRecharageTypeCfg()
--        if rechargeTypeCfg[itemInfo.productType] then
--            _type = tostring(rechargeTypeCfg[itemInfo.productType].type)
--        end
--    end

    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = { productType = _type, name = itemInfo.name, ratio = _ratio }
    buyInfo.extras = json.encode(extrasTable)

    -- libPlatformManager:getPlatform():buyGoods(buyInfo)
    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end

function DiscountGiftPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    for i, v in ipairs(SaleContent.giftInfos) do
        local titleCell = CCBFileCell:create()
        local panel = SaleContent:new( { id = i })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(SaleContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
    if SaleContent.curOffset then
        container.mScrollView:setContentOffset(SaleContent.curOffset)
    end
end

-- local CommonPage = require('CommonPage')
-- local DiscountGiftPage= CommonPage.newSub(DiscountGiftPage, thisPageName, option)

return DiscountGiftPage
