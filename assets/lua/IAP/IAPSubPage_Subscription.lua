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

local SubscriptionPage = {}
local SubscriptionItem = {}

local SubscriptionCfg = ConfigManager.getSubscription()
local parentPage = nil
local requesting = false

-- 購買資料請求中
local requestingLastShop = false
local SeverData = {}
local opcodes = {
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    ACTIVITY168_SUBSCRIPTION_S=HP_pb.ACTIVITY168_SUBSCRIPTION_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    LAST_SHOP_ITEM_S = HP_pb.LAST_SHOP_ITEM_S
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local GotId={}

--------------------------------------------------------------------------------
local option = {
    ccbiFile = "Subscripton.ccbi",
    handlerMap =
    {
        onBtnClick="onBtnClick",
    },
}


function SubscriptionPage:createPage(_parentPage)
    
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

function SubscriptionPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


function SubscriptionPage:onEnter(ParentContainer)
    self.container = ParentContainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    requesting = false
    requestingLastShop = false
    --self:refresh(self.container)
    local scrollview = self.container:getVarScrollView("mContent")
    NodeHelper:autoAdjustResizeScrollview(scrollview)
    SubscriptionPage:ItemInfoRequest()
    --self:ListRequest()
end
function SubscriptionPage:ItemInfoRequest()
    local msg = Activity5_pb.SubScriptionReq()
    msg.action=0
    common:sendPacket(HP_pb.ACTIVITY168_SUBSCRIPTION_C, msg, true)
end
function SubscriptionPage:ListRequest()
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

function SubscriptionPage:refresh(container)
    parentPage:updateCurrency()
    local scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()
    scrollview:setAnchorPoint(ccp(0.5,1))
    local ContentSizeH=0
    local cfg={}
    for i=1,4 do
        table.insert(cfg,SubscriptionCfg[200+i])
    end
    table.sort(cfg, function(data1, data2)
        if data1 and data2 then
            return data1.id < data2.id
        else
            return false
        end
    end)
    for k, v in pairs(cfg) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("SubscriptonContent.ccbi")
        ContentSizeH=cell:getContentSize().height
        cell:setContentSize(CCSize(cell:getContentSize().width,ContentSizeH+10))
        cell:setPositionX(10)
        local panel = common:new({id = v.id}, SubscriptionItem)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)     
    end

    scrollview:setTouchEnabled(true)
    scrollview:setContentSize(CCSize(scrollview:getContentSize().width,(ContentSizeH+20)*#cfg))
    scrollview:orderCCBFileCells()
end

function SubscriptionPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        if requestingLastShop then
            return
        end
        CCLuaLog(">>>>>>onReceiveMessage SubscriptionItem")
       SubscriptionPage:ItemInfoRequest()
       common:sendEmptyPacket(HP_pb.LAST_SHOP_ITEM_C, true)
		--self:ListRequest()
	end
end

function SubscriptionItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local ItemInfo=SubscriptionCfg[self.id].OnBuy

    NodeHelper:setScale9SpriteImage2(container,{mIcon="Subscription_Bundle " .. string.format("%02d", self.id % 10) .. ".png"})
    local key=string.sub(self.id,-1)
    NodeHelper:setStringForLabel(container,{mTxt=common:getLanguageString("@SubscruptTips0"..key)})
    SubscriptionItem:fillContent(container,ItemInfo,#ItemInfo,self.id)
    NodeHelper:setStringForLabel(container,{mCost=self:getPrice(self.id)})
    if GotId.status[self.id]==1 then
       NodeHelper:setNodesVisible(container,{mCost=false,mCoin=false,mBtnTxt=true})
       NodeHelper:setStringForLabel(container,{mBtnTxt=common:getLanguageString("@HasBuy")})
       NodeHelper:setNodeIsGray(container, {mBtn = false})
       NodeHelper:setMenuItemsEnabled(container,{mBtn=false})
    end
end
function SubscriptionItem:fillContent(container,items,Size,id) 
     local maxSize = maxSize or 4;
    local nodesVisible = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    local colorMap = {}
    local HandMap = {}
    for i = 1, 4 do
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
                colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                nodesVisible["mMask"..i]=GotId.status[id]==1
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

function SubscriptionItem:onFrame1(container)
    SubscriptionItem:onShowItemInfo(container, self.id, 1)
end
function SubscriptionItem:onFrame2(container)
    SubscriptionItem:onShowItemInfo(container, self.id, 2)
end
function SubscriptionItem:onFrame3(container)
    SubscriptionItem:onShowItemInfo(container, self.id, 3)
end
function SubscriptionItem:onFrame4(container)
    SubscriptionItem:onShowItemInfo(container, self.id, 4)
end

function SubscriptionItem:onShowItemInfo(container, index, goodIndex)
    local packetItem = SubscriptionCfg[index].OnBuy
    GameUtil:showTip(container:getVarNode('mPic' .. goodIndex), packetItem[goodIndex])
end

function SubscriptionPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if packet.opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --if not ShopList[1] then
        --    ShopList=RechargeCfg
        --end
        --ItemInfoRequest()
        --
        --requesting = false
    end
    if opcode==HP_pb.ACTIVITY168_SUBSCRIPTION_S then
        local msg = Activity5_pb.SubScriptionResp()
        msg:ParseFromString(msgBuff)
        GotId.id=msg.activateId
        GotId.status={}
        self:StatusSync()
        self:refresh(self.container)
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
        if string.find(msg.Items,"@") then
            local title = common:getLanguageString("@Subscription168_title")
            local content = common:getLanguageString(msg.Items)
            PageManager.showConfirm(title, content, function(isSure)
                if isSure then
                    
                end
            end, true, nil, nil, false, 0.9);
        end
    end
end
function SubscriptionPage:StatusSync()
    for k,v in pairs(SubscriptionCfg) do
        GotId.status[k]=0
    end
    for k,v in pairs (GotId.id) do
        if GotId.status[v] then
            GotId.status[v]=1
        end
    end
end
function SubscriptionPage:onExecute(container)
end
function SubscriptionPage:onExit(ParentContainer)
    parentPage:removePacket(opcodes)
    GotId={}
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end
function SubscriptionItem:onBtnClick(container)
    BuyItem(self.id)
end
function SubscriptionItem:getPrice(id)
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

return SubscriptionPage
