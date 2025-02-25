----------------------------------------------------------------------------------
--[[
	特典里面消耗型周卡和月卡
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'MonthCardPage_130'
local Activity_pb = require("Activity_pb");
local Activity4_pb = require("Activity4_pb");
local HP_pb = require("HP_pb");
local Recharge_pb = require("Recharge_pb")
local json = require('json')

local MonthCardPage_130 = { }

local MonthCardCfg = { }
local mConfigManager = nil

local mActivieyType = {
    --消耗型月卡活动id
    MonthCard = 130,
    --消耗型周卡活动id
    WeekCard = 129
}

local mShopId = {
    MonthCard = 32,
    WeekCard = 74
}

-- 月卡信息
local tMonthCardInfo = {
    leftDays = 0,
    isTodayRewardGot = false,
    isMonthCardUser = false,
}

local opcodes = {
    MONTHCARD_INFO_S = HP_pb.CONSUME_MONTHCARD_INFO_S,
    -- 月卡信息返回
    MONTHCARD_AWARD_S = HP_pb.CONSUME_MONTHCARD_AWARD_S,
    -- 月卡领奖返回

    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    -- 商店列表返回

    WEEK_CARD_INFO_S = HP_pb.CONSUME_WEEK_CARD_INFO_S,
    -- 周卡信息返回
    WEEK_CARD_REWARD_S = HP_pb.CONSUME_WEEK_CARD_REWARD_S-- 周卡领取返回
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1

--------------------------------------------------------------------------------
UsingStatute = {
    ccbiFile = "UsingStatute.ccbi",
    ccbiFile_Android = "UsingStatute_Android.ccbi"
}

function UsingStatute:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function UsingStatute:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
end

function UsingStatute:onOpenUrl(container)
    local url = "http://www.crossmagic.co.jp/privacy/"

    if Golb_Platform_Info.is_Android then
        url = "http://www.crossmagic.co.jp/privacy/"
    end

    common:openURL(url)
end

function UsingStatute:onOpenIosUrl(container)
    local url = "http://school.crossmagic.co.jp/terms.html"

    common:openURL(url)
end
--------------------------------------------------------------------------------


function MonthCardPage_130.onFunction(eventName, container)
    if eventName == "onReceive" then
        MonthCardPage_130:onReceive(container)
    elseif eventName == "onFrame4" then
        MonthCardPage_130:onClickItemFrame(container, eventName)
    elseif eventName == "onFrame5" then
        MonthCardPage_130:onClickItemFrame(container, eventName)
    end
end

function MonthCardPage_130:getConfigData()
    local data = nil
    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        data = MonthCardCfg[mShopId.MonthCard]
    else
        -- 周卡
        data = MonthCardCfg[mShopId.WeekCard]
    end
    return data
end

function MonthCardPage_130:getShopID()
    local id = nil
    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        id = mShopId.MonthCard
    else
        -- 周卡
        id = mShopId.WeekCard
    end
    return id
end

function MonthCardPage_130:onEnter(ParentContainer)

    local container = self.container
    if tolua.isnull(self.container) then
        container = ScriptContentBase:create("Act_FixedTimeMonthCardContent_130.ccbi")
        self.container = container
    end
    self.container:registerFunctionHandler(MonthCardPage_130.onFunction)
    self:registerPacket(ParentContainer)

    self:getActivityInfo()

    MonthCardCfg = ConfigManager.getMonthCard_130Cfg()

    local itemInfo = self:getConfigData()

    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
            } );
        end
    end
    NodeHelper:fillRewardItemWithParams(container, rewardItems, 3, { startIndex = 4, showHtml = false })
    local TextMap =
    {
        mMonthCardText1 = common:getLanguageString("@MonthCardTips1",itemInfo.expAdd),
        mMonthCardText2 = common:getLanguageString("@MonthCardTips2",itemInfo.fastbattletimes),
        mMonthCardText3 = common:getLanguageString("@MonthCardTips3",itemInfo.refreshtimes),
        mMonthCardText4 = common:getLanguageString("@MonthCardTips4",itemInfo.buildtimes)

    }
    NodeHelper:setStringForLabel(container, TextMap);
    NodeHelper:setMenuItemEnabled(container, "mReceive", false);
    NodeHelper:setNodeIsGray(container, { mReceiveText = true ,mmItemHNP = true })

    --NodeHelper:setNodesVisible(container, { mRebateLeftDays = false })
     NodeHelper:setNodesVisible(container, { mRebateLeftDaysNode = false })
    ------------------------------------------------------------------------
    --NodeHelper:initScrollView(container, "mContent", 3)
    -- self.mScrollView = container:getVarScrollView("mContent")
    self:initUi(container)

    return self.container
end

function MonthCardPage_130:initUi(container)

    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        NodeHelper:setSpriteImage(container, { mBG = "BG/Activity/Activity_bg_29.png" }, { mBG = 1 })
        --月卡说明
         NodeHelper:setStringForLabel(container,{mMessageText = common:getLanguageString("@ConsumeMonCardRuleTip") })
        --NodeHelper:setStringForLabel(container, { mMessageText = common:getLanguageString('@CanReceive') })
    else
        -- 周卡
        NodeHelper:setSpriteImage(container, { mBG = "BG/Activity/Activity_bg_28.png" }, { mBG = 1 })
        --周卡说明
        NodeHelper:setStringForLabel(container,{mMessageText = common:getLanguageString("@ConsumeWeekCardRuleTip") })
        --NodeHelper:setStringForLabel(container, { mMessageText = common:getLanguageString('@CanReceive') })
    end

    NodeHelper:setNodesVisible(container, { mTextNode = false })

end

function MonthCardPage_130:getRewardCount()
    local data = self:getConfigData()
    return #common:split(data.giftpack, ",")
end

-- 点击物品显示tips
function MonthCardPage_130:onClickItemFrame(container, eventName)
    local rewardIndex = tonumber(eventName:sub(8))
    -- 数字
    local nodeIndex = rewardIndex;
    local itemInfo = nil;
    if rewardIndex > 3 then
        rewardIndex = rewardIndex - 3;
        itemInfo = self:getConfigData()
    else
        itemInfo = tGiftInfo.itemInfo
    end
    if not itemInfo then return end
    local rewardItems = { }
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[rewardIndex])


    --    local rewardIndex = tonumber(eventName:sub(8))--数字
    --    local nodeIndex  = rewardIndex;
    --    local itemInfo = nil;
    --    if rewardIndex > 3 then
    --        rewardIndex = rewardIndex-3;
    --        itemInfo = MonthCardCfg[30]
    --    else
    --        itemInfo = tGiftInfo.itemInfo
    --    end
    --    if not itemInfo then return end
    --    local rewardItems = {}
    --    if itemInfo.giftpack ~= nil then
    --        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
    --            local _type, _id, _count = unpack(common:split(item, "_"));
    --            table.insert(rewardItems, {
    --                type 	= tonumber(_type),
    --                itemId	= tonumber(_id),
    --                count 	= tonumber(_count)
    --            });
    --        end
    --    end
    --    GameUtil:showTip(container:getVarNode('mPic' .. nodeIndex), rewardItems[rewardIndex])
end

-- 领取月卡
function MonthCardPage_130:onReceive(container)

    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        if tMonthCardInfo.isMonthCardUser then
            -- 领取月卡
            common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_AWARD_C, false)

            ActivityInfo.changeActivityNotice(mActivieyType.MonthCard)
        else
            -- 内购购买月卡
            MonthCardPage_130:buyGoods(container, mShopId.MonthCard);
        end
    else
        -- 周卡
        if tMonthCardInfo.isMonthCardUser then
            -- 领取周卡
            common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_REWARD_C, false)
            ActivityInfo.changeActivityNotice(mActivieyType.WeekCard)
        else
            -- 内购购买周卡
            MonthCardPage_130:buyGoods(container, mShopId.WeekCard);
        end
    end
end

function MonthCardPage_130:buyGoods(container, id)
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

function MonthCardPage_130:onExit()

end

function MonthCardPage_130:onExecute(ParentContainer)

end


function MonthCardPage_130:getActivityInfo()

    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_INFO_C, true)
    else
        -- 周卡
        common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, true)
    end

    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --if Golb_Platform_Info.is_win32_platform then
    --    msg.platform = GameConfig.win32Platform
    --end
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --pb_data = msg:SerializeToString()
    --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
end

function MonthCardPage_130:refreshMonthCardNode(container)
    local visible = true;
    local textVisible = true
    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
    NodeHelper:setNodesVisible(container, { mReceiveText = Golb_Platform_Info.is_h365, mHoneyPNode = Golb_Platform_Info.is_r18, 
                                            mJggNode = Golb_Platform_Info.is_jgg })

    if tMonthCardInfo.isMonthCardUser and tMonthCardInfo.isTodayRewardGot == false then
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
        fntPath = GameConfig.FntPath.Bule
        NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString('@CanReceive') });
        NodeHelper:setNodesVisible(container, { mReceiveText = true, mHoneyPNode = false, 
                                            mJggNode = false })
    elseif tMonthCardInfo.isMonthCardUser and tMonthCardInfo.isTodayRewardGot then
        btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
        fntPath = GameConfig.FntPath.Golden
        NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString('@AlreadyReceive') });
        NodeHelper:setNodesVisible(container, { mReceiveText = true, mHoneyPNode = false, 
                                            mJggNode = false })
        visible = false;
    elseif tMonthCardInfo.isMonthCardUser == false then
        -- 不是周卡或者月卡用户
        if (Golb_Platform_Info.is_r18) or (Golb_Platform_Info.is_jgg) then --R18/jgg
            btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
        else
            btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
        end
        fntPath = GameConfig.FntPath.Golden
        local rechargeInfo = nil
        local id = self:getShopID()
        for i = 1, #RechargeCfg do
            if tonumber(RechargeCfg[i].productId) == id then
                rechargeInfo = RechargeCfg[i];
                break
            end
        end
        if rechargeInfo then
            local str = ""
            if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
                -- 月卡
                str = common:getLanguageString("@MonthCardTex2")
            else
                -- 周卡
                str = common:getLanguageString("@MonthCardTex1")
            end

            -- NodeHelper:setStringForLabel(container,{mReceiveText = common:getLanguageString("@MonthCardPrice" , rechargeInfo.productPrice) .. "/"  .. str});
            -- "¥ " ..
            NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@MonthCardPrice", rechargeInfo.productPrice)
                                        , mmItemHNP = tostring(rechargeInfo.productPrice), mItemJgg = tostring(GameUtil:CNYToPlatformPrice(rechargeInfo.productPrice, "JGG"))})
        end
        textVisible = false
    end

    NodeHelper:setMenuItemImage(container, { mReceive = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(container, { mReceiveText = fntPath, mmItemHNP =  fntPath, mItemJgg =  fntPath })

    NodeHelper:setNodesVisible(container, { mRebateLeftDaysNode = textVisible })
    NodeHelper:setStringForLabel(container, { mRebateLeftDays = common:getLanguageString('@RebateLeftDays', tMonthCardInfo.leftDays) });
    NodeHelper:setMenuItemEnabled(container, "mReceive", visible);

    NodeHelper:setNodeIsGray(container, { mReceiveText = not visible, mmItemHNP = not visible, mItemJgg = not visible })
end


function MonthCardPage_130:updateInfoData(msgBuff)

    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        local msg = Activity4_pb.ConsumeMonthCardInfoRet()
        msg:ParseFromString(msgBuff)
        tMonthCardInfo.leftDays = msg.leftDays
        if tMonthCardInfo.leftDays <= 0 then
            tMonthCardInfo.leftDays = 0
        end
        tMonthCardInfo.isTodayRewardGot = msg.isTodayRewardGot

        tMonthCardInfo.isMonthCardUser =(tMonthCardInfo.leftDays > 0)
    else
        -- 周卡
        local msg = Activity4_pb.ConsumeWeekCardInfoRet()
        msg:ParseFromString(msgBuff)
        tMonthCardInfo.leftDays = msg.leftDays
        if tMonthCardInfo.leftDays <= 0 then
            tMonthCardInfo.leftDays = 0
        end

        if msg.isTodayReward == 0 then
            tMonthCardInfo.isTodayRewardGot = false
        else
            tMonthCardInfo.isTodayRewardGot = true
        end
        tMonthCardInfo.isMonthCardUser =(tMonthCardInfo.leftDays > 0)
    end

    self:refreshMonthCardNode(self.container);
end

function MonthCardPage_130:updateAwardData(msgBuff)
    if GameConfig.NowSelctActivityId == mActivieyType.MonthCard then
        -- 月卡
        local msg = Activity4_pb.ConsumeMonthCardInfoRet()
        msg:ParseFromString(msgBuff)
        tMonthCardInfo.isTodayRewardGot = true
        ActivityInfo.changeActivityNotice(Const_pb.CONSUME_MONTH_CARD);
    else
        -- 周卡
        local msg = Activity4_pb.ConsumeWeekCardInfoRet()
        msg:ParseFromString(msgBuff)
        tMonthCardInfo.isTodayRewardGot = true
        ActivityInfo.changeActivityNotice(Const_pb.CONSUME_WEEK_CARD)
    end
    self:refreshMonthCardNode(self.container);
end

-- 收包
function MonthCardPage_130:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.CONSUME_MONTHCARD_INFO_S or opcode == HP_pb.CONSUME_WEEK_CARD_INFO_S then
        self:updateInfoData(msgBuff)
        return
    end
    if opcode == HP_pb.CONSUME_MONTHCARD_AWARD_S or opcode == HP_pb.CONSUME_WEEK_CARD_REWARD_S then
        self:updateAwardData(msgBuff)
        return
    end
    if opcode == HP_pb.FETCH_SHOP_LIST_S then
       --local msg = Recharge_pb.HPShopListSync()
       --msg:ParseFromString(msgBuff)
       --RechargeCfg = msg.shopItems
       --CCLuaLog("Recharge ShopItemNum :" .. #msg.shopItems)
       --return
    end
end
function MonthCardPage_130:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function MonthCardPage_130:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function MonthCardPage_130:onExit(ParentContainer)
    local timerName = ExpeditionDataHelper.getPageTimerName()
    TimeCalculator:getInstance():removeTimeCalcultor(timerName)
    self:removePacket(ParentContainer)
end

function MonthCardPage_130:refreshPage()
    local timerName = ExpeditionDataHelper.getPageTimerName()
    local remainTime = ExpeditionDataHelper.getActivityRemainTime()
    if remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(timerName, remainTime);
    end
    if CurrentStageId < 1 then
        CurrentStageId = 1
    elseif CurrentStageId > ExpeditionDataHelper.getMaxStageId() then
        CurrentStageId = ExpeditionDataHelper.getMaxStageId()
    end

    local mStageInfo = ExpeditionDataHelper.getStageInfoByStageId(CurrentStageId)
    if mStageInfo ~= nil then
        local str = ""
        if mStageInfo.needExp == 0 then
            str = tostring(mStageInfo.curExp) .. "/" .. common:getLanguageString("@ExpeditionFinalStage")
        else
            str = tostring(mStageInfo.curExp) .. "/" .. tostring(mStageInfo.needExp)
        end
        NodeHelper:setStringForLabel(self.container, { mSeepNum = str })
    end

    NodeHelper:setStringForLabel(self.container, { mExpeditionNowSeep = common:getLanguageString("@ExpeditionNowSeep" .. CurrentStageId) })

    self.container:runAnimation("Anim" .. CurrentStageId)
end

return MonthCardPage_130
