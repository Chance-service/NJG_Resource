----------------------------------------------------------------------------------
-- 新手打折 学割XXX
----------------------------------------------------------------------------------


---------临时更新

------------------------------------local variable--------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Activity_pb = require("Activity_pb")
local Const_pb = require("Const_pb")
local Recharge_pb = require "Recharge_pb"
local NewbieGuideManager = require("NewbieGuideManager")
local json = require('json')
local thisPageName = 'RechargeDiscountPage'
local RechargeDiscountPage = { }
local mSalePacketContainerRef = { };-- 存储折扣礼包 Container

local mServerData = { }      -- 服务器返回的数据
local SaleContent = {
    ccbiFile = "Act_TimeLimitNewDiscountListContent.ccbi",
    alreadyBuytList = { },
    receiveTimes = { },
    curOffset = nil,
}

local SalepacketCfg = { }
local option = {
    ccbiFile = "Act_TimeLimitNewDiscountContent.ccbi",
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
local timerName = "Activity_" .. thisActivityInfo.id -- 充值返利倒计时的key
--------------------------------page show--------------------------------------
function RechargeDiscountPage:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)

    self.container = container

    local s9Bg = container:getVarScale9Sprite("mS9_1")
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    NodeHelper:autoAdjustResizeScrollview(container:getVarScrollView("mContent"))

    NodeHelper:initScrollView(container, "mContent", 5);
    SalepacketCfg = ConfigManager.getSalepacketCfg()
    self:registerPacket(parentContainer)

    if self.container.mScrollView ~= nil then
        -- parentContainer:autoAdjustResizeScrollview(self.container.mScrollView);
    end
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mScale9Sprite2"))

    common:sendEmptyPacket(HP_pb.SALE_PACKET_INFO_C, true)

    local LLL = 0

    return container
end



function RechargeDiscountPage:onExit(parentContainer)
    self:removePacket(parentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(timerName);
    NodeHelper:deleteScrollView(self.container);
    self.container = nil
end

function RechargeDiscountPage:onRefreshPage(container)
    if thisActivityInfo.remainTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(timerName, thisActivityInfo.remainTime);
    end
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

function RechargeDiscountPage:onExecute(parentContainer)
    self:onTimer(self.container)
end
-- 130345687
function RechargeDiscountPage:onTimer(container)
    -- 倒计时为0的时候显示已结束
    if (thisActivityInfo.remainTime ~= nil and thisActivityInfo.remainTime <= 0)
        or(TimeCalculator:getInstance():hasKey(timerName)
        and TimeCalculator:getInstance():getTimeLeft(timerName) <= 0) then

        NodeHelper:setStringForLabel(container, { mCD = common:getLanguageString("@ActivityRebateClose") })
        return
    end
    if not TimeCalculator:getInstance():hasKey(timerName) then return end
    local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName)
    thisActivityInfo.remainTime = math.max(remainTime, 0)
    -- -- 如果倒计时为0，重新请求
    -- if thisActivityInfo.remainTime == 0 then
    -- 	common:sendEmptyPacket(HP_pb.RECHARGE_REBATE_INFO_C,false)
    -- end
    local timeStr = common:second2DateString(thisActivityInfo.remainTime, false)
    NodeHelper:setStringForLabel(container, { mTanabataCD = timeStr })
end

function RechargeDiscountPage:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "RechargeRebate_enter_rechargePage")
    PageManager.pushPage("RechargePage");
end

function RechargeDiscountPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_RECHARGEREBATE)
end

function RechargeDiscountPage:onReceive(container)
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

function RechargeDiscountPage:onBack(container)
    PageManager.changePage("ActivityPage")
end
-------------------------------page data handler-------------------------------
function RechargeDiscountPage:onReceiveRebateInfo(container, msg)
    thisActivityInfo.remainTime = msg.surplusTime or 0
    thisActivityInfo.accRechargeDiamond = msg.accRechargeDiamond or 0
    thisActivityInfo.canReceiveDiamond = msg.canReceiveDiamond or 0
    -- 如果有剩余天数，说明活动结束状态
    if msg:HasField("leftDays") then
        NodeHelper:setStringForLabel(container, { mSurplusDays = common:getLanguageString("@RebateLeftDays", msg.leftDays) })
    else
        NodeHelper:setStringForLabel(container, { mSurplusDays = "" })
    end
    -- 领取状态，1领取，0未领取
    if msg:HasField("receiveAward") then
        NodeHelper:setMenuItemEnabled(container, "mBtn", msg.receiveAward == 0)
    else
        NodeHelper:setNodeVisible(container:getVarMenuItemImage("mBtn"), false)
    end
end

--------------------------------packet handler----------------------------------
function RechargeDiscountPage:registerPacket(container)
    container:registerPacket(HP_pb.SALE_PACKET_INFO_S)
    container:registerPacket(HP_pb.SALE_PACKET_GET_AWARD_S)


end

function RechargeDiscountPage:removePacket(container)
    container:removePacket(HP_pb.SALE_PACKET_INFO_S)
    container:removePacket(HP_pb.SALE_PACKET_GET_AWARD_S)
end

function RechargeDiscountPage:onReceivePacket(parentContainer)
    --
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    if opcode == HP_pb.SALE_PACKET_INFO_S then
        local msg = Activity_pb.HPSalePacketInfoRet()
        msg:ParseFromString(msgBuff)

        mServerData = { }

        for i = 1, #msg.salePacketLst do
            mServerData[msg.salePacketLst[i].goodid] = msg.salePacketLst[i]
        end

        thisActivityInfo.remainTime = tonumber(msg.leftTime)
        if thisActivityInfo.remainTime > 0 then
            TimeCalculator:getInstance():createTimeCalcultor(timerName, thisActivityInfo.remainTime)
        end
        self:clearAndReBuildAllItem(self.container)
    end

    if opcode == HP_pb.SALE_PACKET_GET_AWARD_S then
        local msg = Activity_pb.HPGetSalePacketAward()
        msg:ParseFromString(msgBuff)
        local packetId = msg.packetId
        mServerData[packetId].state = msg.state
        SaleContent.onRefreshItemView(mSalePacketContainerRef[packetId])
        -- NodeHelper:setStringForLabel(mSalePacketContainerRef[packetId],{mCostNum = common:getLanguageString('@AlreadyReceive')});
        -- NodeHelper:setMenuItemEnabled(mSalePacketContainerRef[packetId],"mBtn",false);
        RechargeDiscountPage:clearNotice()
    end

end

function RechargeDiscountPage:clearNotice()
    -- 红点消除
    local hasNotice = false
    local alreadyBuy, alreadyReceive
    for id, itemInfo in ipairs(SalepacketCfg) do
        alreadyBuy, alreadyReceive = SaleContent.parsePacketState(id);
        if alreadyBuy and not alreadyReceive then
            hasNotice = true
            break
        end

    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.HERO_TOKEN_SHOP);
    end
end

function SaleContent.parsePacketState(id)
    local alreadyBuy = false;
    local alreadyReceive = false;

    --    if mServerData[id].buytime >= SalepacketCfg[id].limitCount then
    --        mServerData[id].state = -1
    --    end

    if mServerData[id].state == 0 then
        -- 还没购买   不能领取
        alreadyBuy = false
        alreadyReceive = false
    elseif mServerData[id].state == 1 then
        -- 已经购买   还没领取
        alreadyBuy = true
        alreadyReceive = false
        --    elseif mServerData[id].state == -1 then
        --        -- 已经购买   还没领取
        --        alreadyBuy = true
        --        alreadyReceive = true
    end

    return alreadyBuy, alreadyReceive

end

function SaleContent.onRefreshItemView(container)
    local id = tonumber(container:getItemDate().mID)
    local packetItem = SalepacketCfg[id].salepacket
    mSalePacketContainerRef[id] = container;

    if packetItem ~= nil then
        -- 显示物品SaleContent.alreadyBuytList receiveTimes
        local alreadyBuy = false;
        -- 是否已购买
        local alreadyReceive = false;
        -- 是否已领取
        alreadyBuy, alreadyReceive = SaleContent.parsePacketState(id);
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
        NodeHelper:setStringForLabel(container,lb2Str)
        SaleContent:fillRewardItem(container, rewardItems, 4)

        -- RechargeCfg formerPrice
        local ShowText = "";

        local fntPath = GameConfig.FntPath.Bule
        local btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage

        NodeHelper:setBMFontFile(container, { mCostNum = fntPath })
        NodeHelper:setNodesVisible(container, { mCostNum = true , mValueNum = Golb_Platform_Info.is_h365
                                , mHoneyPNode = Golb_Platform_Info.is_r18, mJggNode = Golb_Platform_Info.is_jgg
                                , mOriginalNode = Golb_Platform_Info.is_r18, mOriginalJggNode = Golb_Platform_Info.is_jgg })

        if alreadyBuy and alreadyReceive then
            NodeHelper:setNodesVisible(container, { mCostNum = true, mHoneyPNode = false, mJggNode = false })
            ShowText = common:getLanguageString('@AlreadyReceive')
        elseif alreadyBuy and alreadyReceive == false then
            NodeHelper:setNodesVisible(container, { mCostNum = true, mHoneyPNode = false, mJggNode = false })
            ShowText = common:getLanguageString('@CanReceive')
            btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
            fntPath = GameConfig.FntPath.Bule
        elseif alreadyBuy == false then
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

        local isMaxCount = false
        if mServerData[id].buytime >= SalepacketCfg[id].limitCount and mServerData[id].state == 0 then
            -- 购买次数已达到上限
            isMaxCount = true
        end
        NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
        NodeHelper:setNodesVisible(container, {mChatBtnTxt1 = false})   --等级限制说明 日本人让去掉

        NodeHelper:setStringForLabel(container, { mCostNum = ShowText })
        NodeHelper:setStringForLabel(container, { mmItemHNP = ShowText })
        NodeHelper:setStringForLabel(container, { mItemJgg = ShowText })
        NodeHelper:setMenuItemEnabled(container, "mBtn", not isMaxCount)
        NodeHelper:setNodeIsGray(container, { mCostNum = isMaxCount })
        NodeHelper:setStringForLabel(container, { mDiscountTxt = common:getLanguageString(SalepacketCfg[id].desc) })
        NodeHelper:setStringForLabel(container, { mChatBtnTxt1 = common:getLanguageString('@RechargeLimit', SalepacketCfg[id].minLevel, SalepacketCfg[id].maxLevel) });
        NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString('@RechargeLimit1', SalepacketCfg[id].limitCount - mServerData[id].buytime) })
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
                lb2Str["mNum" .. i] = "x" .. cfg.count;
                lb2Str["mName" .. i] = resInfo.name;
                menu2Quality["mFrame" .. i] = resInfo.quality
                --colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
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

    NodeHelper:setColorForLabel(container, colorMap)
    NodeHelper:setNodesVisible(container, nodesVisible)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function SaleContent.onBuy(container)
    local id = tonumber(container:getItemDate().mID)
    local packetItem = SalepacketCfg[id].salepacket;
    local alreadyBuy = false;
    -- 是否已购买
    local alreadyReceive = false;
    -- 是否已领取
    alreadyBuy, alreadyReceive = SaleContent.parsePacketState(id);
    if alreadyBuy and alreadyReceive == false then
        -- 领取
        local msg = Activity_pb.GetSalePacketAward()
        msg.packetId = id;
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.SALE_PACKET_GET_AWARD_C, pb, #pb, true)
        if mContainerRef and mContainerRef.mScrollView2 then
            SaleContent.curOffset = mContainerRef.mScrollView2:getContentOffset()
        end
    elseif alreadyBuy == false then
        UserInfo.sync()
        local userLevel = UserInfo.roleInfo.level
        if userLevel > tonumber(SalepacketCfg[id].minLevel) and userLevel <= tonumber(SalepacketCfg[id].maxLevel) then
            RechargeDiscountPage:buyGoods(container, id);
            if mContainerRef and mContainerRef.mScrollView2 then
                SaleContent.curOffset = mContainerRef.mScrollView2:getContentOffset()
            end
        else
            MessageBoxPage:Msg_Box_Lan("@LevelLimit")
        end

    end
end

function SaleContent.onShowItemInfo(container, eventName)
    local index = tonumber(eventName:sub(-1))
    local id = tonumber(container:getItemDate().mID)
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
    GameUtil:showTip(container:getVarNode('mPic' .. index), rewardItems[index])
end
function SaleContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        SaleContent.onRefreshItemView(container);
    elseif eventName == "onBtn" then
        SaleContent.onBuy(container);
    elseif string.sub(eventName, 1, 7) == "onFrame" then
        -- 显示tips
        SaleContent.onShowItemInfo(container, eventName)
    end
end


function RechargeDiscountPage:buyGoods(container, id)
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

function RechargeDiscountPage:clearAndReBuildAllItem(container)
    -- clear
    if container.m_pScrollViewFacade then
        container.m_pScrollViewFacade:clearAllItems();
    end
    -- build
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight2 = 0
    local fOneItemWidth = 0
    local cfg = { }
    local MaxIndex = 1
    for i, v in pairs(SalepacketCfg) do
        cfg[v.index] = v
        if v.index > MaxIndex then
            MaxIndex = v.index
        end
    end
    for i = MaxIndex, 1, -1 do
        if cfg[i] then
            local pItemData = CCReViSvItemData:new_local()
            pItemData.mID = cfg[i].id
            pItemData.m_iIdx = i
            pItemData.m_ptPosition = ccp(0, fOneItemHeight2 * iCount)

            if iCount < iMaxNode then
                local pItem = ScriptContentBase:create(SaleContent.ccbiFile)
                pItem.id = iCount
                pItem:registerFunctionHandler(SaleContent.onFunction)
                if fOneItemHeight2 < pItem:getContentSize().height then
                    fOneItemHeight2 = pItem:getContentSize().height
                end

                if fOneItemWidth < pItem:getContentSize().width then
                    fOneItemWidth = pItem:getContentSize().width
                end
                container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
            else
                container.m_pScrollViewFacade:addItem(pItemData)
            end
            iCount = iCount + 1
        end
    end

    local size = CCSizeMake(fOneItemWidth, fOneItemHeight2 * iCount)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
    container.mScrollView:forceRecaculateChildren();
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)
    if SaleContent.curOffset then
        container.mScrollView:setContentOffset(SaleContent.curOffset)
    end
end

-- local CommonPage = require('CommonPage')
-- local RechargeDiscountPage= CommonPage.newSub(RechargeDiscountPage, thisPageName, option)

return RechargeDiscountPage