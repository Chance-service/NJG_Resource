--鑽石商城
local HP_pb = require("HP_pb")-- 包含协议id文件
require "Recharge_pb"

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local RechargeDataMgr = require("Recharge.RechargeDataMgr")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")
local BuyManager = require("BuyManager")

-- 每行 商品數量 (需對應 商品列ccbi檔)
local ITEM_COUNT_PER_ROW = 3

local opcodes = {
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    DISCOUNT_GIFT_BUY_SUCC_S = HP_pb.DISCOUNT_GIFT_BUY_SUCC_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    LAST_SHOP_ITEM_S = HP_pb.LAST_SHOP_ITEM_S
}

local option = {
    ccbiFile = "RechargeDiamondPage.ccbi",
    
    handlerMap = {
        onVIPHelpBtn = "onVIPHelpBtn",
    },
}

local RechargeDiamondItem = {}
local RechargeSubPage_Diamond = {}
local requesting = false

-- 購買資料請求中
local requestingLastShop = false

local TmpReward = {}

function RechargeSubPage_Diamond:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end
function RechargeSubPage_Diamond:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function RechargeSubPage_Diamond:onEnter(Parentcontainer)
    self.container = Parentcontainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)

    requesting = false
    requestingLastShop = false
    self:ItemInfoRequest()
    
    self:setVIPLevelInfo(InfoAccesser:getVIPLevelInfo())
    
    NodeHelper:initScrollView(self.container, "contentScrollView", 9);
end
function RechargeSubPage_Diamond:ItemInfoRequest()
    if not requesting then
        requesting = true
        
        local msg = Recharge_pb.HPFetchShopList()
        msg.platform = GameConfig.win32Platform
        CCLuaLog("PlatformName2:" .. msg.platform)
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    end
end
function RechargeSubPage_Diamond:setVIPLevelInfo(vipLevelInfo)
    NodeHelper:setSpriteImage(self.container, {
        levelIconImg = PathAccesser:getVIPIconPath(vipLevelInfo.level)
    })
    
    NodeHelper:setStringForLabel(self.container, {
        expNumText = tostring(vipLevelInfo.exp) .. "/" .. tostring(vipLevelInfo.expMax)
    })
    
    local expBarParentNode = self.container:getVarNode("expBarNode")
    local expBar = self.container:getVarScale9Sprite("expBar")
    
    local size = expBarParentNode:getContentSize()
    local minWidth = expBar:getInsetLeft() + expBar:getInsetRight()
    local scaleX = 1
    size.width = size.width * (vipLevelInfo.exp / vipLevelInfo.expMax)
    if size.width < minWidth then
        scaleX = size.width / minWidth
    end
    expBar:setContentSize(size)
    expBar:setScaleX(scaleX)
end
function RechargeSubPage_Diamond:onExit(container)
    parentPage:removePacket(opcodes)
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end
function RechargeSubPage_Diamond:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if packet.opcode == HP_pb.FETCH_SHOP_LIST_S then
        local msg = Recharge_pb.HPShopListSync()
        msg:ParseFromString(msgBuff)
        RechargeCfg = msg.shopItems
        self:receiveShopList(RechargeCfg)
        
        requesting = false
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    else
        self:refresh(self.container)
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
    self:setVIPLevelInfo(InfoAccesser:getVIPLevelInfo())
end
function RechargeSubPage_Diamond:onVIPHelpBtn()
    PageManager.pushPage("Recharge.RechargeVIPPage")
end
function RechargeSubPage_Diamond:refresh(container)
    NodeHelper:clearScrollView(self.container)
    local currencyDatas = parentPage:updateCurrency()
    local size = math.ceil(#self.rechargeListInfo / ITEM_COUNT_PER_ROW)
    NodeHelperUZ:buildScrollViewVertical(self.container, size, "RechargeDiamondContentItem.ccbi",
        function(eventName, container)
            RechargeDiamondItem.onFunction(self, eventName, container)
        end,
        {
            originScrollViewSize = CCSizeMake(700, 700),
            startOffset = ccp(0, math.min(700, math.max(0, size * 350 - 700))),
        });
end
function RechargeSubPage_Diamond:receiveShopList(list)
    local monthCard = {}
    local normalCard = {}
    for k, v in ipairs(list) do
        if v.productType == 0 then
            table.insert(normalCard, v)
        else
            table.insert(monthCard, v)
        end
    end
    if Golb_Platform_Info.is_entermate_platform then
        table.sort(normalCard, function(e1, e2)
            return e1.productPrice > e2.productPrice
        end)
    end
    self.rechargeListInfo = normalCard
    self:refresh(self.container)
end
function RechargeSubPage_Diamond:onExecute(container)

end
RechargeDiamondItem = {
    ccbiFile = "RechargeDiamondContent.ccbi"
}
function RechargeDiamondItem.onFunction(inst, eventName, container)
    if eventName == "luaRefreshItemView" then
        RechargeDiamondItem.onRefreshItemView(inst, container)
    end
end

function RechargeDiamondItem.onRefreshItemView(inst, container)
    local contentId = container:getItemDate().mID
    local baseIndex = (contentId - 1) * ITEM_COUNT_PER_ROW
    -- local baseIndex = contentId * ITEM_COUNT_PER_ROW
    for i = 1, ITEM_COUNT_PER_ROW do
        local nodeContainer = container:getVarNode("mPositionNode" .. i)
        NodeHelper:setNodeVisible(nodeContainer, false)
        nodeContainer:removeAllChildren()
        
        local itemNode = nil
        local index = baseIndex + i
        
        if index <= #inst.rechargeListInfo then
            itemNode = RechargeDiamondItem.newLineItem(inst, index)
        end
        
        if itemNode then
            nodeContainer:addChild(itemNode)
            NodeHelper:setNodeVisible(nodeContainer, true)
        end
    end
end
function RechargeDiamondItem.newLineItem(inst, index)
    
    local itemInfo = inst.rechargeListInfo[index]
    
    -- 建立 物品UI
    local itemNode = ScriptContentBase:create(RechargeDiamondItem.ccbiFile, index)
    -- 註冊 行為
    itemNode:registerFunctionHandler(function(eventName, container)
        RechargeDiamondItem.onRecharge(inst, eventName, container)
    end)
    
    -- 設置 內容數量
    NodeHelper:setStringForLabel(itemNode, {
        rewardCountText = tostring(itemInfo.gold)
    })
    -- 價格相關 ---------------------
    local productPriceText = tostring(itemInfo.productPrice)
    
    -- TODO : 依照平台改變顯示的價格
    -- 依照商品類型 -----------------
    -- 商品類型 : 普通
    if itemInfo.productType == 0 then
        
        -- 覆蓋 商品圖片 為 鑽石
        NodeHelper:setSpriteImage(itemNode, {
            itemImg = RechargeDataMgr:getDiamondImgPath(index)
        })
        
        local vipPoint = ConfigManager.getDiamondVIPCfg()[index].count
        NodeHelper:setStringForLabel(itemNode,{ VIPCount = vipPoint})

        local isBonusExist = itemInfo:HasField("showAddGold") ~= nil
        
        if isBonusExist then
            NodeHelper:setStringForLabel(itemNode, {
                bonusCountText = "+" .. tostring(itemInfo.showAddGold)
            })
        end
        
        -- 設 是否為首次儲值 為 比率是否存在(???)
        local isFirstBuy = itemInfo:HasField("ratio") ~= nil
        
        -- 顯示/隱藏 首儲相關
        NodeHelper:setNodesVisible(itemNode, {specialLabelNode = isFirstBuy})
        if isFirstBuy then
            -- 首儲時 額外數量 = 基礎數量
            CCLuaLog(itemInfo.gold.."isfist")
            NodeHelper:setStringForLabel(itemNode, {
                specialLabelText = common:getLanguageString("@Recharge.FirstTimeBuy")
            })
            NodeHelper:setStringForLabel(itemNode, {
                bonusCountText = "+" .. tostring(itemInfo.gold)
            })
        elseif isBonusExist then
            -- 額外數量 若 存在 則 設置
            NodeHelper:setStringForLabel(itemNode, {
                bonusCountText = "+" .. tostring(itemInfo.showAddGold)
            })
        end
        -- 顯示/隱藏
        NodeHelper:setNodesVisible(itemNode, {
            bonusNode = false--(isBonusExist or isFirstBuy)
        })
    end
    
    -- 設置 價格 文字
    NodeHelper:setStringForLabel(itemNode, {
        priceText = productPriceText
    })
    
    itemNode:release()
    
    return itemNode
end
function RechargeDiamondItem.onRecharge(inst, eventName, container)
    if eventName ~= "onBuyBtn" then return end
    local index = container:getTag()
    local itemInfo = inst.rechargeListInfo[index]
    local isFirstBuy = itemInfo:HasField("ratio") ~= nil
    local isBonusExist = itemInfo:HasField("showAddGold") ~= nil
    local itemCount = itemInfo.gold
    if isFirstBuy then
        itemCount = itemCount*2
    end
    if isBonusExist then
        itemCount = itemCount + tonumber (itemInfo.showAddGold )
    end
    --TmpReward[1] = {type = 10000,itemId = 1001,count = itemCount }
    --local VIPcount =  ConfigManager.getDiamondVIPCfg()[index].count
    --TmpReward[2] = {type = 10000,itemId = 1026, count = VIPcount }
    BuyItem(tonumber(itemInfo.productId))
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
function RechargeSubPage_Diamond:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        if requestingLastShop then
            return
        end
        CCLuaLog(">>>>>>onReceiveMessage RechargeSubPage_Diamond")

        self:ItemInfoRequest()
        common:sendEmptyPacket(HP_pb.LAST_SHOP_ITEM_C, true)
       --local rewards = TmpReward or { }
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

return RechargeSubPage_Diamond
