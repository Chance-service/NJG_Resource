----------------------------------------------------------------------------------
--[[
月卡
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'IAPSubPage_MonthlyCard'
local Activity_pb = require("Activity_pb");
local Activity4_pb = require("Activity4_pb");
local HP_pb = require("HP_pb");
local Recharge_pb = require("Recharge_pb")
local json = require('json')
local BuyManager = require("BuyManager")

local MonthCardPage_130 = {}
local MonthCardItem = {}

local MonthCardCfg = ConfigManager.getMonthCard_130CfgNew()
local mConfigManager = nil

local SMALL_CARD = 73
local LARGE_CARD = 74

local parentPage = nil

local requesting = false

local SeverData = {}

-- 購買資料請求中
local requestingLastShop = false

local opcodes = {
    MONTHCARD_INFO_S = HP_pb.CONSUME_MONTHCARD_INFO_S,
    -- 月卡信息返回
    MONTHCARD_AWARD_S = HP_pb.CONSUME_MONTHCARD_AWARD_S,
    -- 月卡领奖返回
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    -- 商店列表返回
    WEEK_CARD_INFO_S = HP_pb.CONSUME_WEEK_CARD_INFO_S,
    -- 周卡信息返回
    WEEK_CARD_REWARD_S = HP_pb.CONSUME_WEEK_CARD_REWARD_S, -- 周卡领取返回
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    LAST_SHOP_ITEM_S = HP_pb.LAST_SHOP_ITEM_S 
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1

--------------------------------------------------------------------------------
local option = {
    ccbiFile = "MonthlyCards.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onSmall = "onSmall",
        onLarge = "onLarge"
    },
}


function MonthCardPage_130:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end

function MonthCardPage_130:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


function MonthCardPage_130.onFunction(eventName, container)
    if eventName == "onReceive" then
        MonthCardPage_130:onReceive(container)
    elseif eventName == "onFrame4" then
        MonthCardPage_130:onClickItemFrame(container, eventName)
    elseif eventName == "onFrame5" then
        MonthCardPage_130:onClickItemFrame(container, eventName)
    end
end


function MonthCardPage_130:onEnter(ParentContainer)
    self.container = ParentContainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    
    local bg = ParentContainer:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    ----小月卡
    common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_INFO_C, false)
    ----大月卡
    common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, false)
    requesting = false
    requestingLastShop = false
    self:ListRequest()
end

function MonthCardPage_130:ListRequest()
    --CCLuaLog("..............ListRequest")
      ----小月卡
    common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_INFO_C, false)
    ----大月卡
    common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, false)
    if not requesting then
        --requesting = true
        --local msg = Recharge_pb.HPFetchShopList()
        --msg.platform = GameConfig.win32Platform
        --CCLuaLog("PlatformName2:" .. msg.platform)
        --pb_data = msg:SerializeToString()
        --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    end
end

function MonthCardPage_130:refresh(container)
    local currencyDatas = parentPage:updateCurrency()
    NodeHelper:setStringForLabel(container, {SmallCost = self:getPrice(SMALL_CARD), LargeCost = self:getPrice(LARGE_CARD)})
    local scrollview_1 = container:getVarScrollView("mContent1")
    local scrollview_2 = container:getVarScrollView("mContent2")
    local scrollview_3 = container:getVarScrollView("mContent3")
    local scrollview_4 = container:getVarScrollView("mContent4")
    local cellScale = 0
    local WidthOffset = 0
    local HeighOffset = 0
    scrollview_1:removeAllCell()
    scrollview_2:removeAllCell()
    scrollview_3:removeAllCell()
    scrollview_4:removeAllCell()
    for k, v in pairs(MonthCardCfg) do
        local OnBuyInfo = v.OnBuy
        local DailyInfo = v.DailyGift
        for t = 1, #OnBuyInfo do
            if (k == SMALL_CARD) then
                self:CreateItem(t, scrollview_1, OnBuyInfo[t], SeverData.isMonthCardUser_Small or false,#OnBuyInfo)
            elseif (k == LARGE_CARD) then
                self:CreateItem(t, scrollview_3, OnBuyInfo[t], SeverData.isMonthCardUser_Large or false,#OnBuyInfo)
            end
        end
        for a = 1, #DailyInfo do
            if (k == SMALL_CARD) then
                self:CreateItem(a, scrollview_2, DailyInfo[a], SeverData.isTodayRewardGot_Small or false,#DailyInfo)
            elseif (k == LARGE_CARD) then
                self:CreateItem(a, scrollview_4, DailyInfo[a], SeverData.isTodayRewardGot_Large or false,#DailyInfo)
            end
        end
    end
    
    --小月卡
    if SeverData.isMonthCardUser_Small then
        if SeverData.isTodayRewardGot_Small then
            NodeHelper:setMenuItemsEnabled(container, {mSmallBtn = false})
            NodeHelper:setStringForLabel(container, {SmallCost = common:getLanguageString("@ReceiveDone")})
            NodeHelper:setNodesVisible(container,{mCoin1=false})
        else
            NodeHelper:setStringForLabel(container, {SmallCost = common:getLanguageString("@Receive")})
            NodeHelper:setNodesVisible(container,{mCoin1=false})
            NodeHelper:setMenuItemsEnabled(container, {mSmallBtn = true})
        end
    else
        NodeHelper:setStringForLabel(container, {SmallCost = self:getPrice(SMALL_CARD)})
        NodeHelper:setMenuItemsEnabled(container, {mSmallBtn = true})
    end
    --大月卡
    if SeverData.isMonthCardUser_Large then
        if SeverData.isTodayRewardGot_Large then
            NodeHelper:setMenuItemsEnabled(container, {mLargeBtn = false})
            NodeHelper:setStringForLabel(container, {LargeCost = common:getLanguageString("@ReceiveDone")})
            NodeHelper:setNodesVisible(container,{mCoin2=false})
        else
            NodeHelper:setStringForLabel(container, {LargeCost = common:getLanguageString("@Receive")})
            NodeHelper:setNodesVisible(container,{mCoin2=false})
            NodeHelper:setMenuItemsEnabled(container, {mLargeBtn = true})
        end
    else
        NodeHelper:setStringForLabel(container, {LargeCost = self:getPrice(LARGE_CARD)})
        NodeHelper:setMenuItemsEnabled(container, {mLargeBtn = true})
    end
end
function MonthCardItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.itemType, self.id, self.num)
    local lb2Str = {}
    
    lb2Str["mNumber1"] = self.num
    
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, {["mPic1"] = resInfo.icon})
    NodeHelper:setQualityFrames(container, {["mHand1"] = resInfo.quality})
    NodeHelper:setImgBgQualityFrames(container, {["mFrameShade1"] = resInfo.quality})
    NodeHelper:setNodesVisible(container, {mShader = false, mName1 = false, mNumber1 = false, mMask = self.isbuy})
    local contentWidth = content:getContentSize().width
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, {["mStar" .. i] = false})
    end
    -- for i =1,resInfo.quality do
    --     NodeHelper:setNodesVisible(container, {["mStar" .. i] = false})
    -- end
    NodeHelper:setNodesVisible(container, {mEquipLv = false})
    container:getVarLabelTTF("mNumber1_1"):setString(self.num)
end
function MonthCardItem:onHand1(container)
    
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(tonumber(self.itemType), tonumber(self.id), tonumber(self.num))
    local items = {
        type = tonumber(self.itemType),
        itemId = tonumber(self.id),
        count = tonumber(self.num)
    };
    GameUtil:showTip(container:getVarNode("mHand1"), items)
end
function MonthCardPage_130:CreateItem(i, scrollview, items, Reward,Count)
    local itemData, itemId, itemNum = items.type, items.itemId, items.count
    cell = CCBFileCell:create()
    cell:setCCBFile("BackpackItem.ccbi")
    local panel = common:new({itemType = itemData, id = itemId, num = itemNum, isbuy = Reward}, MonthCardItem)
    cell:registerFunctionHandler(panel)
    cell:setContentSize(CCSize(cell:getContentSize().width-30, cell:getContentSize().height))
    cell:setAnchorPoint(ccp(0.5, 1))
    local PosX=scrollview:getPositionY()+cell:getContentSize().width/2
    if Count==1 then
        scrollview:setPositionX(PosX)
    end
    cell:setScale(0.6)
    scrollview:addCell(cell)
    if Count>2 then
        scrollview:setTouchEnabled(true)
    else
        scrollview:setTouchEnabled(false)
    end
    scrollview:orderCCBFileCells()
    scrollview:setContentOffset(ccp(-10, 0))
end
function MonthCardPage_130:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    --小月卡
    if opcode == HP_pb.CONSUME_MONTHCARD_INFO_S then
        local msg = Activity4_pb.ConsumeMonthCardInfoRet()
        msg:ParseFromString(msgBuff)
        SeverData.leftDays_Small = msg.leftDays
        if SeverData.leftDays_Small <= 0 then
            SeverData.leftDays_Small = 0
        end
        SeverData.isTodayRewardGot_Small = msg.isTodayRewardGot
        SeverData.isMonthCardUser_Small = (SeverData.leftDays_Small > 0)
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:SmallMonthCardRedPointSync(msg)
        self:refresh(self.container)
    end
    if opcode == HP_pb.CONSUME_MONTHCARD_AWARD_S then
        common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_INFO_C, true)
    end
    --大月卡
    if opcode == HP_pb.CONSUME_WEEK_CARD_INFO_S then
        local msg = Activity4_pb.ConsumeWeekCardInfoRet()
        msg:ParseFromString(msgBuff)
        SeverData.leftDays_Large = msg.leftDays
        if SeverData.leftDays_Large <= 0 then
            SeverData.leftDays_Large = 0
        end
        SeverData.isMonthCardUser_Large = (SeverData.leftDays_Large > 0)
        if SeverData.isMonthCardUser_Large then
            SeverData.isTodayRewardGot_Large = (msg.isTodayReward==1)
        else
            SeverData.isTodayRewardGot_Large = false
        end
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:LargeMonthCardRedPointSync(msg)
        self:refresh(self.container)
    end
    if opcode == HP_pb.CONSUME_WEEK_CARD_REWARD_S then
        common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, true)
    end
    if packet.opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        
        --小月卡
        common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_INFO_C, false)
        --大月卡
        common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_INFO_C, false)

        requesting = false
    end
    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
     if opcode == HP_pb.LAST_SHOP_ITEM_S then
        requestingLastShop = false
        local Recharge_pb = require("Recharge_pb")
        local msg = Recharge_pb.LastGoodsItem()
        msg:ParseFromString(msgBuff)
        if msg.Items == "" then return end
        local Items = common:parseItemWithComma(msg.Items)
        if next(Items) then
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(Items, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
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
    parentPage:removePacket(opcodes)
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end
function MonthCardPage_130:onExecute(container)

end

function MonthCardPage_130:onSmall(container)
    if SeverData.isMonthCardUser_Small then
        common:sendEmptyPacket(HP_pb.CONSUME_MONTHCARD_AWARD_C, false)
    else
        BuyItem(SMALL_CARD)
    end
end
function MonthCardPage_130:onLarge(container)
    if SeverData.isMonthCardUser_Large then
        common:sendEmptyPacket(HP_pb.CONSUME_WEEK_CARD_REWARD_C, false)
    else
        BuyItem(LARGE_CARD)
    end
end
function MonthCardPage_130:getPrice(id)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            itemInfo = RechargeCfg[i]
            break
        end
    end
    
    return itemInfo.productPrice
end
function BuyItem(id)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            itemInfo = RechargeCfg[i]
            break
        end
    end
    local buyInfo = BUYINFO:new()
    buyInfo.productType = itemInfo.productType
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
    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = {productType = _type, name = itemInfo.name, ratio = _ratio}
    buyInfo.extras = json.encode(extrasTable)
    
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end

function MonthCardPage_130:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        if requestingLastShop then
            return
        end
        CCLuaLog(">>>>>>onReceiveMessage MonthCardPage_130")
		self:ListRequest()
        common:sendEmptyPacket(HP_pb.LAST_SHOP_ITEM_C, true)
	end
end

return MonthCardPage_130
