local NodeHelper         = require("NodeHelper")
local HP_pb              = require("HP_pb")
local UserInfo           = require("PlayerInfo.UserInfo")
local Activity_pb        = require("Activity_pb")
local Const_pb           = require("Const_pb")
local ActivityFunction   = require("ActivityFunction")
local TimeDateUtil       = require("Util.TimeDateUtil")
local CommTabStorage     = require("CommComp.CommTabStorage")
local Recharge_pb        = require("Recharge_pb")
local BuyManager         = require("BuyManager")
local json               = require("json")
local common             = require("common")
local ConfigManager      = require("ConfigManager")
local PageManager        = require("PageManager")
local ResManagerForLua   = require("ResManagerForLua")
local Activity2_pb       = require("Activity2_pb") 

--------------------------------------------------------------------------------
--【輔助函式區】（相似邏輯統一處理）
--------------------------------------------------------------------------------
local function parseServerData(buff)
    local serverData = {}
    local msg = Activity2_pb.HPDiscountInfoRet()
    msg:ParseFromString(buff)
    for _, info in ipairs(msg.info) do
        table.insert(serverData, {
            id          = info.goodsId,
            boughtTimes = info.buyTimes,
            status      = info.status,
            countDown   = info.countdownTime,
            refreshTime = info.refreshTime,
        })
    end
    return serverData
end

local function parseSalePacket(packet)
    local rewards = {}
    for _, s in ipairs(common:split(packet, ",")) do
        local parts = common:split(s, "_")
        table.insert(rewards, { type = tonumber(parts[1]), itemId = tonumber(parts[2]), count = tonumber(parts[3]) })
    end
    return rewards
end

local function getBoughtTimes(packageId, state)
    if not state then return 0 end
    for _, sItem in ipairs(state.serverData) do
        if sItem.id == packageId then
            return sItem.boughtTimes or 0
        end
    end
    return 0
end

-- 檢查指定禮包中是否有未購買完畢的項目（用於紅點判斷）
local function checkBundleRedPoint(bundle, state)
    for _, item in ipairs(bundle) do
        local bought = getBoughtTimes(item.id, state)
        if tonumber(SaleContent:getPrice(item.id)) <= 0 and (item.limitNum - bought) > 0 then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
--【DiscountGiftPage 模塊】（頁面數據與邏輯處理）
--------------------------------------------------------------------------------
local DiscountGiftPage = {}
DiscountGiftPage.__index = DiscountGiftPage

-- 定義網路封包 opcode 對應
local opcodes = {
    DISCOUNT_GIFT_INFO_S      = HP_pb.DISCOUNT_GIFT_INFO_S,
    DISCOUNT_GIFT_BUY_SUCC_S   = HP_pb.DISCOUNT_GIFT_BUY_SUCC_S,
    DISCOUNT_GIFT_GET_REWARD_S = HP_pb.DISCOUNT_GIFT_GET_REWARD_S,
    FETCH_SHOP_LIST_S         = HP_pb.FETCH_SHOP_LIST_S,
    PLAYER_AWARD_S            = HP_pb.PLAYER_AWARD_S,
}

-- 用 state 表集中管理所有狀態資料
local state = {
    cfg           = ConfigManager.getRechargeDiscountCfg(),
    currentBundle = nil,
    dailyBundle   = {},
    weeklyBundle  = {},
    monthlyBundle = {},
    serverData    = {},
    timeStr       = "",
    parentPage    = nil,
    container     = nil,
    saleItems     = {},
    scrollOffset  = nil,
    requesting    = false,
}

local rechargeCfg = RechargeCfg  -- 充值配置（下發時填充）

-- ccbi 設定與回呼對應關係
local option = {
    ccbiFile = "DailyBundleShop.ccbi",
    handlerMap = {
        onHelp  = "onHelp",
        onDay   = "onDay",
        onWeek  = "onWeek",
        onMonth = "onMonth",
    },
}

-- UI 狀態配置（按鈕、Banner 顯示）
local bundleUIConfig = {
    day = {
        mDayChosen = true,  mWeekChosen = false, mMonthChosen = false,
        DayBanner  = true,  WeekBanner  = false, MonthBanner  = false,
        DayTitle   = true,  WeekTitle   = false, MonthTitle   = false,
    },
    week = {
        mDayChosen = false, mWeekChosen = true,  mMonthChosen = false,
        DayBanner  = false, WeekBanner  = true,  MonthBanner  = false,
        DayTitle   = false, WeekTitle   = true,  MonthTitle   = false,
    },
    month = {
        mDayChosen = false, mWeekChosen = false, mMonthChosen = true,
        DayBanner  = false, WeekBanner  = false, MonthBanner  = true,
        DayTitle   = false, WeekTitle   = false, MonthTitle   = true,
    },
}

--------------------------------------------------------------------------------
--【DiscountGiftPage 方法】
--------------------------------------------------------------------------------
function DiscountGiftPage:new(o)
    o = o or {}
    setmetatable(o, self)
    return o
end

function DiscountGiftPage:createPage(_parentPage)
    state.parentPage = _parentPage
    local container = ScriptContentBase:create(option.ccbiFile)
    state.container = container
    container:registerFunctionHandler(function(eventName, container)
        local func = self[option.handlerMap[eventName]]
        if func then func(self, container) end
    end)
    return container
end

-- 註冊訊息與封包，並發起第一次請求
function DiscountGiftPage:onEnter(parentContainer)
    self.container = parentContainer
    state.parentPage:registerPacket(opcodes)
    state.parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    state.parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    state.parentPage:registerMessage(MSG_REFRESH_REDPOINT)
    NodeHelper:setStringForLabel(parentContainer, {
        mDayTxt   = common:getLanguageString("@DailyBundleText1"),
        mWeekTxt  = common:getLanguageString("@DailyBundleText2"),
        mMonthTxt = common:getLanguageString("@DailyBundleText3"),
    })
    self:refreshAllPoint(state.container)
    state.requesting = false
    self:ItemInfoRequest()
end

function DiscountGiftPage:ItemInfoRequest()
    if not state.requesting then
        state.requesting = true
        local msg = Activity2_pb.DiscountInfoReq()
        msg.actId = Const_pb.DISCOUNT_GIFT
        common:sendPacket(HP_pb.DISCOUNT_GIFT_INFO_C, msg, true)
    end
end

-- 根據服務器數據與配置構建日／週／月禮包
function DiscountGiftPage:SetItemInfo()
    state.dailyBundle, state.weeklyBundle, state.monthlyBundle = {}, {}, {}
    for _, data in ipairs(state.serverData) do
        local cfgItem = state.cfg[data.id]
        if cfgItem then
            if cfgItem.limitType == 1 then
                table.insert(state.dailyBundle, cfgItem)
            elseif cfgItem.limitType == 2 then
                table.insert(state.weeklyBundle, cfgItem)
            elseif cfgItem.limitType == 4 then
                table.insert(state.monthlyBundle, cfgItem)
            end
        end
    end
end

-- 收到封包後的處理（包含數據解析與紅點更新）
function DiscountGiftPage:onReceivePacket(packet)
    local opcode, buff = packet.opcode, packet.msgBuff
    if opcode == HP_pb.DISCOUNT_GIFT_INFO_S then
        state.serverData = parseServerData(buff)
        self:SetItemInfo()
        if not state.currentBundle then
            self:onDay(state.container)
        else
            self:refresh(state.container)
        end
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.GOODS_DAILY_TAB, 1, buff)
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.GOODS_WEEKLY_TAB, 1, buff)
        RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.GOODS_MONTHLY_TAB, 1, buff)
        self:refreshAllPoint(state.container)
        state.requesting = false

    elseif opcode == HP_pb.DISCOUNT_GIFT_BUY_SUCC_S then
        CCLuaLog("BuySuccessful")
        self:ItemInfoRequest()

    elseif opcode == HP_pb.DISCOUNT_GIFT_GET_REWARD_S then
        self:ItemInfoRequest()

    elseif opcode == HP_pb.PLAYER_AWARD_S then
        require("PackageLogicForLua").PopUpReward(buff)
    end
end

-- 更新倒數計時（根據當前 bundle 第一項的 refreshTime）
function DiscountGiftPage:onTimer(container)
    for _, item in ipairs(state.currentBundle or {}) do
        for _, sData in ipairs(state.serverData) do
            if item.id == sData.id then
                state.timeStr = common:second2DateString2(sData.refreshTime, false)
                NodeHelper:setStringForLabel(container, { refreshAutoCountdownText = state.timeStr })
                return
            end
        end
    end
end

-- 刷新列表內容（依據當前選中 bundle）
function DiscountGiftPage:refresh(container)
    if not state.currentBundle then return end
    self:onTimer(container)
    state.parentPage:updateCurrency()

    if state.currentBundle == state.dailyBundle then
        NodeHelper:setMenuItemsEnabled(container, { mDay = false, mWeek = true, mMonth = true })
    elseif state.currentBundle == state.weeklyBundle then
        NodeHelper:setMenuItemsEnabled(container, { mDay = true, mWeek = false, mMonth = true })
    else
        NodeHelper:setMenuItemsEnabled(container, { mDay = true, mWeek = true, mMonth = false })
    end

    local scroll = container:getVarScrollView("mContent")
    scroll:removeAllCell()
    state.saleItems = {}
    table.sort(state.currentBundle, function(a, b) return a.Sort < b.Sort end)

    local cellHeight = 0
    for i, item in ipairs(state.currentBundle) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("DailyBundleShopContent.ccbi")
        local size = cell:getContentSize()
        cell:setContentSize(CCSize(size.width, size.height - 10))
        local panel = common:new({ id = i }, SaleContent)
        cellHeight = cell:getContentSize().height
        cell:registerFunctionHandler(panel)
        scroll:addCell(cell)
        cell:setPosition(ccp(0, cellHeight * (#state.currentBundle - i)))
        table.insert(state.saleItems, cell)
    end

    local lastSize = state.saleItems[#state.saleItems] and state.saleItems[#state.saleItems]:getContentSize() or CCSizeMake(0, 0)
    scroll:setContentSize(CCSizeMake(lastSize.width, lastSize.height * #state.currentBundle))
    if not state.scrollOffset then
        scroll:setContentOffset(ccp(0, scroll:getViewSize().height - cellHeight * #state.currentBundle - 10))
    else
        scroll:setContentOffset(state.scrollOffset)
    end
    scroll:forceRecaculateChildren()
end

-- 通用禮包切換函式（根據配置設定按鈕與 Banner 狀態）
local function selectBundle(self, bundle, configKey, container)
    state.currentBundle = bundle
    state.scrollOffset = nil
    NodeHelper:setNodesVisible(container, bundleUIConfig[configKey])
    self:onTimer(container)
    self:refresh(state.container)
end

function DiscountGiftPage:onDay(container)
    if state.dailyBundle then
        selectBundle(self, state.dailyBundle, "day", container)
    end
end

function DiscountGiftPage:onWeek(container)
    if state.weeklyBundle then
        selectBundle(self, state.weeklyBundle, "week", container)
    end
end

function DiscountGiftPage:onMonth(container)
    if state.monthlyBundle then
        selectBundle(self, state.monthlyBundle, "month", container)
    end
end

function DiscountGiftPage:onExecute(container)
    -- 可根據需要加入週期性任務
end
function DiscountGiftPage:onExit(container)
    
end

function DiscountGiftPage:onReceiveMessage(message)
    local typeId = message:getTypeId()
    if typeId == MSG_RECHARGE_SUCCESS then
        CCLuaLog("DiscountGiftPage received recharge success")
        self:ItemInfoRequest()
    elseif typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(state.container)
    end
end

-- 更新所有紅點顯示（包含 tab 與 cell 紅點）
function DiscountGiftPage:refreshAllPoint(container)
    for i, cell in ipairs(state.saleItems) do
        SaleContent:refreshPoint(cell, i)
    end
    NodeHelper:setNodesVisible(state.container, { 
        mTabPoint1 = checkBundleRedPoint(state.dailyBundle, state)
    })
    NodeHelper:setNodesVisible(state.container, { 
        mTabPoint2 = checkBundleRedPoint(state.weeklyBundle, state)
    })
    NodeHelper:setNodesVisible(state.container, { 
        mTabPoint3 = checkBundleRedPoint(state.monthlyBundle, state)
    })
end

-- 根據頁籤與 msgBuff 判斷是否顯示紅點（此函式亦可供外部調用）
function DiscountGiftPage_calIsShowRedPoint(pageId, msgBuff)
    local msg = Activity2_pb.HPDiscountInfoRet()
    msg:ParseFromString(msgBuff)
    state.serverData = {}
    for _, info in ipairs(msg.info) do
        table.insert(state.serverData, {
            id = info.goodsId,
            boughtTimes = info.buyTimes,
            status = info.status,
            countDown = info.countdownTime,
            refreshTime = info.refreshTime,
        })
    end
    DiscountGiftPage:SetItemInfo()
    local bundle = (pageId == RedPointManager.PAGE_IDS.DAILY_REWARD_BTN) and state.dailyBundle or
                   (pageId == RedPointManager.PAGE_IDS.WEEKLY_REWARD_BTN) and state.weeklyBundle or
                   state.monthlyBundle
    if bundle then
        return checkBundleRedPoint(bundle, state)
    end
    return false
end

--------------------------------------------------------------------------------
--【SaleContent 模塊】（單個 cell 操作，與頁面邏輯分離）
--------------------------------------------------------------------------------
SaleContent = {}

-- 刷新 cell 紅點（同時更新對應 tab 紅點狀態）
function SaleContent:refreshPoint(cell, index)
    if not state.currentBundle then return end
    local container = cell:getCCBFileNode()
    local item = state.currentBundle[index]
    local packageId = item.id
    if tonumber(SaleContent:getPrice(packageId)) <= 0 then
        local bought = getBoughtTimes(packageId, state)
        local show = (item.limitNum - bought) > 0
        NodeHelper:setNodesVisible(container, { mPoint = show })
        if state.currentBundle == state.dailyBundle then
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.DAILY_REWARD_BTN, 1, show)
        elseif state.currentBundle == state.weeklyBundle then
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.WEEKLY_REWARD_BTN, 1, show)
        else
            RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.MONTHLY_REWARD_BTN, 1, show)
        end
    end
end

-- 刷新 cell 內容
function SaleContent:onRefreshContent(cell)
    local container = cell:getCCBFileNode()
    local item = state.currentBundle[self.id]
    local packageId = item.id
    if item.salepacket then
        local rewards = parseSalePacket(item.salepacket)
        SaleContent:fillRewardItem(container, rewards, #rewards)
    end
    for _, sItem in ipairs(state.serverData) do
        if sItem.id == packageId then
            if sItem.status == 0 then
                NodeHelper:setNodeVisible(container:getVarNode("mSold"), true)
            elseif sItem.status == 1 then
                NodeHelper:setNodesVisible(container, { mCoin = true, mCost = true, mReceive = false })
                NodeHelper:setNodeVisible(container:getVarNode("mSold"), false)
            elseif sItem.status == 2 then
                NodeHelper:setNodesVisible(container, { mCoin = false, mCost = false, mReceive = true })
                NodeHelper:setNodeVisible(container:getVarNode("mSold"), false)
            end
            local show = ((item.limitNum - sItem.boughtTimes) > 0) and (SaleContent:getPrice(packageId) == 0)
            NodeHelper:setNodesVisible(container, { mPoint = show })
            break
        end
    end
    local leftAmount = item.limitNum - getBoughtTimes(packageId, state)
    local leftStr = common:getLanguageString("@Shop.Item.leftAmount", leftAmount, item.limitNum)
    NodeHelper:setStringForLabel(container, { mTitle = item.name, mCount = leftStr, mCost = tonumber(SaleContent:getPrice(packageId)) })
end

-- 填充 cell 中的獎勵圖示
function SaleContent:fillRewardItem(container, items, maxSize, isShowNum)
    maxSize = maxSize or 4
    isShowNum = isShowNum or false
    local nodes, labels, sprites, qualities, colors, hands = {}, {}, {}, {}, {}, {}
    for i = 1, 4 do nodes["mRewardNode" .. i] = false end
    for i = 1, maxSize do
        local cfg = items[i]
        nodes["mRewardNode" .. i] = (cfg ~= nil)
        if cfg then
            local res = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            if res then
                sprites["mPic" .. i] = res.icon
                labels["mNum" .. i]   = GameUtil:formatNumber(cfg.count)
                labels["mName" .. i]  = res.name
                qualities["mFrame" .. i] = res.quality
                hands["mHand" .. i]      = res.quality
                colors["mName" .. i]     = ConfigManager.getQualityColor()[res.quality].textColor
                if isShowNum then 
                    labels["mNum" .. i] = (res.count or 0) .. "/" .. cfg.count 
                end
            end
        end
    end
    NodeHelper:setNodesVisible(container, nodes)
    NodeHelper:setStringForLabel(container, labels)
    NodeHelper:setSpriteImage(container, sprites)
    NodeHelper:setImgBgQualityFrames(container, qualities)
    NodeHelper:setQualityFrames(container, hands)
    NodeHelper:setColorForLabel(container, colors)
end

-- cell 點擊邏輯（依據服務器返回狀態決定動作）
function SaleContent:onBtn(cell)
    local scroll = state.container:getVarScrollView("mContent")
    state.scrollOffset = scroll:getContentOffset()
    local item = state.currentBundle[self.id]
    local packageId = item.id
    for _, sItem in ipairs(state.serverData) do
        if sItem.id == packageId then
            if sItem.status == 2 then
                local msg = Activity2_pb.HPDiscountGetRewardReq()
                msg.goodsId = packageId
                common:sendPacket(HP_pb.DISCOUNT_GIFT_GET_REWARD_C, msg, true)
                return
            elseif sItem.status == 0 then
                return
            else
                DiscountGiftPage.buyItem(packageId)
            end
        end
    end
end

-- 根據充值配置取得價格
function SaleContent:getPrice(id)
    for _, item in ipairs(rechargeCfg) do
        if tonumber(item.productId) == id then
            return item.productPrice or 0
        end
    end
    return 0
end

-- 購買物品（從充值配置中查找後調用 BuyManager）
function DiscountGiftPage.buyItem(id)
    local itemInfo
    for _, item in ipairs(rechargeCfg) do
        if tonumber(item.productId) == id then
            itemInfo = item
            break
        end
    end
    if not itemInfo then return end
    local buyInfo = BUYINFO:new()
    buyInfo.productType         = itemInfo.productType
    buyInfo.name                = itemInfo.name
    buyInfo.productCount        = 1
    buyInfo.productName         = itemInfo.productName
    buyInfo.productId           = itemInfo.productId
    buyInfo.productPrice        = itemInfo.productPrice
    buyInfo.productOrignalPrice = itemInfo.gold
    buyInfo.description         = itemInfo.description or ""
    buyInfo.serverTime          = GamePrecedure:getInstance():getServerTime()
    local extras = { productType = tostring(itemInfo.productType), name = itemInfo.name, ratio = tostring(itemInfo.ratio) }
    buyInfo.extras = json.encode(extras)
    BuyManager.Buy(UserInfo.playerInfo.playerId, buyInfo)
end

-- 點擊 cell 中獎勵圖示顯示詳情（對應 4 個獎勵框）
function SaleContent:onFrame1(cell) SaleContent:onShowItemInfo(cell, self.id, 1) end
function SaleContent:onFrame2(cell) SaleContent:onShowItemInfo(cell, self.id, 2) end
function SaleContent:onFrame3(cell) SaleContent:onShowItemInfo(cell, self.id, 3) end
function SaleContent:onFrame4(cell) SaleContent:onShowItemInfo(cell, self.id, 4) end

function SaleContent:onShowItemInfo(cell, index, goodIndex)
    local packet = state.currentBundle[index].salepacket
    local rewards = parseSalePacket(packet)
    GameUtil:showTip(cell:getVarNode('mPic' .. goodIndex), rewards[goodIndex])
end

--------------------------------------------------------------------------------
-- 返回模塊
--------------------------------------------------------------------------------
return DiscountGiftPage
