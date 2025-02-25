----------------------------------------------------------------------------------
--[[
專屬特權
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local thisPageName = 'IAPSubPage_Subscription'
local Activity_pb = require("Activity_pb");
local Activity4_pb = require("Activity4_pb");
local Activity5_pb=require("Activity5_pb")
local HP_pb = require("HP_pb");
local Recharge_pb = require("Recharge_pb")
local json = require('json')
local BuyManager = require("BuyManager")

local StepBunlePage = {}
local StepBunleItem = {}

local StepBundleCfg = ConfigManager.getStepBundleCfg()
local parentPage = nil
local requesting = false

-- 購買資料請求中
local requestingLastShop = false
local SeverData = {}
local opcodes = {
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    ACTIVITY179_STEP_GIFT_S=HP_pb.ACTIVITY179_STEP_GIFT_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    LAST_SHOP_ITEM_S = HP_pb.LAST_SHOP_ITEM_S

}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local ShopList={}
local GotId={id = 0 , status = { } }
local TmpReward = { }
--------------------------------------------------------------------------------
local option = {
    ccbiFile = "StepBundle.ccbi",
    handlerMap =
    {
        onBtnClick="onBtnClick",
    },
}


function StepBunlePage:createPage(_parentPage)
    
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

function StepBunlePage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


function StepBunlePage:onEnter(ParentContainer)
    self.container = ParentContainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    requesting = false
    requestingLastShop = false
    --self:refresh(self.container)
    local scrollview = self.container:getVarScrollView("mContent")
    --NodeHelper:autoAdjustResizeScrollview(scrollview)
    StepBunlePage:ItemInfoRequest()
    --self:ListRequest()
end
function StepBunlePage:ItemInfoRequest()
    local msg = Activity5_pb.GiftReq()
    msg.action=0
    common:sendPacket(HP_pb.ACTIVITY179_STEP_GIFT_C, msg, false)
end
function StepBunlePage:ListRequest()
    if not requesting then
        --requesting = true
        --
        --local msg = Recharge_pb.HPFetchShopList()
        --msg.platform = GameConfig.win32Platform
        --CCLuaLog("PlatformName2:" .. msg.platform)
        --pb_data = msg:SerializeToString()
        --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    end
end

function StepBunlePage:refresh(container)
    parentPage:updateCurrency()
    local scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()
    scrollview:setAnchorPoint(ccp(0.5,1))
    local ContentSizeH=0
    local cfg=StepBunlePage:getSortedTable(StepBundleCfg)
    for k, v in pairs(cfg) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("StepBundleItem.ccbi")
        ContentSizeH=cell:getContentSize().height
        cell:setContentSize(CCSize(cell:getContentSize().width,ContentSizeH))
        local panel = common:new({id = v.id,idx=k}, StepBunleItem)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)  
    end

    scrollview:setTouchEnabled(true)
    scrollview:setContentSize(CCSize(scrollview:getContentSize().width,(ContentSizeH)*#cfg))
    scrollview:orderCCBFileCells()
end

function StepBunlePage:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        if requestingLastShop then
            return
        end
        CCLuaLog(">>>>>>onReceiveMessage StepBunleItem")
        StepBunlePage:ItemInfoRequest()
        common:sendEmptyPacket(HP_pb.LAST_SHOP_ITEM_C, true)
        --local rewards = TmpReward
        --if not next(rewards) then return end
        --local showReward = { }
        --for i = 1, #rewards do
        --    local oneReward = rewards[i]
        --    if oneReward.count > 0 then
        --        local resInfo = { }
        --        resInfo["type"] = oneReward.type
        --        resInfo["itemId"] = oneReward.itemId
        --        resInfo["count"] = oneReward.count
        --        showReward[#showReward + 1] = resInfo
        --    end
        --end
        --local CommonRewardPage = require("CommPop.CommItemReceivePage")
        --CommonRewardPage:setData(showReward, common:getLanguageString("@ItemObtainded"), nil)
        --PageManager.pushPage("CommPop.CommItemReceivePage")
        --
        --TmpReward = { }
	end
end
function StepBunlePage:getSortedTable(Config)
    local cfg={}
    for k, v  in pairs (Config) do
        table.insert(cfg,v)
    end
    table.sort(cfg, function(data1, data2)
        if data1 and data2 then
            return data1.id < data2.id
        else
            return false
        end
    end)
    return cfg
end
function StepBunleItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local ItemInfo = StepBundleCfg[self.id].reward
    local visibleMap = {}
    local isSold = (GotId.status[self.id] == 1)  -- 檢查當前包是否已售出
    local cfg = StepBunlePage:getSortedTable(StepBundleCfg)
    local LINE_HEIGHT = 70

    -- 設置 Scale9Sprite 高度的函數
    local function setScale9SpriteHeight(container, NodeName, idx)
        local Bar = tolua.cast(container:getVarNode(NodeName), "CCScale9Sprite")
        Bar:setContentSize(CCSize(Bar:getContentSize().width, idx))
    end

    -- 設置上下邊線的可見性和高度
    --if self.idx == 1 then
    --    visibleMap["mUpperLine"] = false
    --    --setScale9SpriteHeight(container, "mLowerLine", LINE_HEIGHT)
    --elseif self.idx == #cfg then
    --    visibleMap["mLowerLine"] = false
    --    --setScale9SpriteHeight(container, "mUpperLine", LINE_HEIGHT)
    --else
    --    visibleMap["mUpperLine"] = true
    --    visibleMap["mLowerLine"] = true
    --    --setScale9SpriteHeight(container, "mUpperLine", LINE_HEIGHT)
    --    --setScale9SpriteHeight(container, "mLowerLine", LINE_HEIGHT)
    --end

    -- 設置文本
    local txt = common:getLanguageString("@PLAYER_STEP" .. self.idx)
    NodeHelper:setStringForLabel(container, { mStepTxt = txt })

    -- 填充內容
    StepBunleItem:fillContent(container, ItemInfo, #ItemInfo, self.id)

    -- 設置剩餘數量文本
    local leftcont = common:getLanguageString("@Shop.Item.leftAmount", (0 and isSold or 1), 1)
    NodeHelper:setStringForLabel(container, { 
        mBtnLabel = self:getPrice(self.id), 
        mLv = self.idx, 
        mLeftCount = leftcont 
    })

    -- 控制節點可見性
    visibleMap["mSoldNode"] = isSold
    visibleMap["mLv"] = not isSold
    visibleMap["mGotCheck"] = isSold

    -- 檢查是否能啟用按鈕的邏輯
    local function canEnableButton()
        -- 如果是第一包，直接啟用（未售出情況下）
        if self.idx == 1 then
            return not isSold
        end

        -- 檢查當前包之前的所有包是否已購買
        for k, v in pairs(cfg) do
            if v.id < self.id and GotId.status[v.id] == 0 or isSold then
                return false  -- 如果有前置包未購買，則按鈕不可用
            end
        end
        return true
    end

    -- 設置按鈕狀態：如果已售出則禁用，否則根據邏輯判斷是否啟用
    local enableButton = canEnableButton()
    NodeHelper:setMenuItemsEnabled(container, { mBtn = enableButton })

    -- 設置節點可見性
    NodeHelper:setNodesVisible(container, visibleMap)
end

function StepBunleItem:fillContent(container,items,Size,id) 
     local maxSize = maxSize or 5;
    local nodesVisible = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    local colorMap = {}
    local HandMap = {}
    for i = 1, 5 do
        nodesVisible["mRewardNode" .. i] = false
    end
    
    for i = 1, maxSize do
        local cfg = items[i];
        nodesVisible["mRewardNode" .. i] = cfg ~= nil;
        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon
                lb2Str["mNum" .. i] = GameUtil:formatNumber(cfg.count)
                lb2Str["mName" .. i] = resInfo.name;
                menu2Quality["mFrame" .. i] = resInfo.quality
                HandMap["mHand" .. i] = resInfo.quality
                --colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                nodesVisible["mReceived"..i]=GotId.status[id]==1
                nodesVisible["mName"..i]=false
            else
                CCLuaLog("Error::***reward item not found!!");
            end
        end
    end
    NodeHelper:setNodesVisible(container, nodesVisible);
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setImgBgQualityFrames(container, menu2Quality);
    NodeHelper:setQualityFrames(container, HandMap)
    NodeHelper:setColorForLabel(container, colorMap)
end

function StepBunleItem:onFrame1(container)
    StepBunleItem:onShowItemInfo(container, self.id, 1)
end
function StepBunleItem:onFrame2(container)
    StepBunleItem:onShowItemInfo(container, self.id, 2)
end
function StepBunleItem:onFrame3(container)
    StepBunleItem:onShowItemInfo(container, self.id, 3)
end
function StepBunleItem:onFrame4(container)
    StepBunleItem:onShowItemInfo(container, self.id, 4)
end
function StepBunleItem:onFrame5(container)
    StepBunleItem:onShowItemInfo(container, self.id, 5)
end

function StepBunleItem:onShowItemInfo(container, index, goodIndex)
    local packetItem = StepBundleCfg[index].reward
    GameUtil:showTip(container:getVarNode('mPic' .. goodIndex), packetItem[goodIndex])
end
function StepBunlePage:setData(msg)
     GotId.id=msg.takeId or 0
     GotId.status={}
     self:StatusSync() 
     if self.container then
        self:refresh(self.container)
     end
end
function StepBunlePage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if packet.opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --if not ShopList[1] then
        --    ShopList=RechargeCfg
        --end
        --requesting = false
    end
    if opcode==HP_pb.ACTIVITY179_STEP_GIFT_S then
       local msg = Activity5_pb.GiftResp()
       msg:ParseFromString(msgBuff)     
       self:setData(msg)
          --if self.container then self:refresh(self.container) end
    end
    --if opcode == HP_pb.PLAYER_AWARD_S then
    --    local PackageLogicForLua = require("PackageLogicForLua")
    --    PackageLogicForLua.PopUpReward(msgBuff)
    --end
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
function StepBunlePage:isBuyAll()
    local cfg = StepBunlePage:getSortedTable(StepBundleCfg)
    local lastId = cfg[#cfg].id
    return GotId.status[lastId]==1
end
function StepBunlePage:StatusSync()
    for k, _ in pairs(StepBundleCfg) do
        -- 确保 status[k] 是一个有效的键值并初始化为 0
        GotId.status[k] =  0
    
        -- 如果 k 小于或等于 GotId.id，则标记为 1，否则为 0
        if k <= tonumber(GotId.id) then
            GotId.status[k] = 1
        else
            GotId.status[k] = 0
        end
    end
end
function StepBunlePage:onExecute(container)
end
function StepBunlePage:onExit(ParentContainer)
    parentPage:removePacket(opcodes)
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end
function StepBunleItem:onBtnClick(container)
    TmpReward = StepBundleCfg[self.id].reward 
    BuyItem(self.id)
end
function StepBunleItem:getPrice(id)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            itemInfo = RechargeCfg[i]
            break
        end
    end
    if not itemInfo then return 999999999999 end
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

return StepBunlePage
