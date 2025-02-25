
--[[ 
    name: RechargeSubPage_Diamond
    desc: 充值頁面
    author: youzi
    update: 2023/6/5 11:31
    description: 
--]]

local HP_pb = require("HP_pb") -- 包含协议id文件
require "Recharge_pb"

local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local RechargeDataMgr = require("Recharge.RechargeDataMgr")
local PathAccesser = require("Util.PathAccesser")
local InfoAccesser = require("Util.InfoAccesser")
local BuyManager = require("BuyManager")

-- 每行 商品數量 (需對應 商品列ccbi檔)
local ITEM_COUNT_PER_ROW = 3


----这里是协议的id
local opcodes = {
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
}

local option = {
    
    ccbiFile = "RechargeDiamondPage.ccbi",

    handlerMap = {
        onVIPHelpBtn = "onVIPHelpBtn",
    },

    opcode = opcodes
}

local RechargeDiamondItem = {}

--[[ 
    text
    
    var 
        specialLabelText : 左上 特別標籤 文字 (用於首儲 或 可能的其他用途)
        specialLabelNode : 左上 特別標籤 容器
        itemImg : 商品 圖片
        rewardUnitIcon : 獎品單位 圖標
        rewardCountText : 獎品數量 文字
        bonusNode : 額外數量 容器
        bonusCountText : 額外數量 文字
        priceText : 價格 文字

    event
        onItemFrame : 當物品框按下
        onBuyBtn : 當購買按下
--]]
 
local RechargeSubPage_Diamond = {}

--[[ 
    text
        @RechargeVIP_Title : 主標題
        @RechargeVIP_RechargeBtn : 充值按鈕
        @RechargeVIP_VIPBundleBtn : VIP禮包按鈕
    
    var 
        levelIconImg : VIP等級圖標
        expBarNode : 經驗進度條容器
        expBar : 經驗進度條
        expNumText : 經驗進度數字
        contentNode : 內容容器
        contentScrollView : 內容滾動視圖

    event
        onVIPHelpBtn : 當VIP說明按鈕 按下
--]]


function RechargeSubPage_Diamond:new ()

    local inst = {}

    --[[ 容器 ]]
    inst.container = nil

    --[[ 當 關閉 行為 ]]
    inst.onceClose_fn = nil

    --[[ 充值資料 ]]
    inst.rechargeListInfo = {}

    --[[ 當 收到訊息 ]]
    function inst:onReceiveMessage(container)
        local message = container:getMessage();
        local typeId = message:getTypeId();
        -- if typeId == XXXXXXXXXX then
        --     local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        --     if opcode == HP_pb.XXXXXXX then
        --         
        --     end
        -- end
    end

    --[[ 當 收到封包 ]]
    function inst:onReceivePacket(parentPage, packet)

        if packet.opcode == HP_pb.FETCH_SHOP_LIST_S then
            local msg = Recharge_pb.HPShopListSync()
            msg:ParseFromString(packet.msgBuff)
            -- CCLuaLog("Recharge ShopItemNum :" .. #packet.msg.shopItems)
            
            -- 接收 商品列表
            inst:receiveShopList(msg)
        else
            BuyManager:onReceiveBuyPacket(packet.opcode, packet.msgBuff)
        end
    end
    
    --[[ 當 呼叫 ]]
    function inst:onFunction (eventName, container)
        local fnName = option.handlerMap[eventName]
        if fnName ~= nil then
            local fn = inst[fnName]
            if fn ~= nil then
                fn(inst, container)
            end
        end
    end

    --[[ 建立 頁面 ]]
    function inst:createPage (parentPage)
        inst.container = ScriptContentBase:create(option.ccbiFile)
        return inst.container
    end

    --[[ 當 頁面 進入 ]]
    function inst:onEnter (parentPage)

        -- 註冊 呼叫行為
        inst.container:registerFunctionHandler(function (eventName, container)
            inst:onFunction(eventName, container)
        end)
        
        -- 發送 請求商店列表
       -- inst:sendShopListRequest()

        -- TODO 設置 分頁列 貨幣
        -- parentPage.tabStorage:setCurrencyDatas({})

        -- 設置 VIP等級
        local levelInfo = InfoAccesser:getVIPLevelInfo()
        inst:setVIPLevelInfo(levelInfo)

        -- 初始化 文字內容滾動視圖
        NodeHelper:initScrollView(inst.container, "contentScrollView", 9);

    end

    --[[ 當 頁面 離開 ]]
    function inst:onExit(inst)
        -- 清理列表
        NodeHelper:clearScrollView(inst.container)
    end

    --[[ 設置 VIP資訊 ]]
    function inst:setVIPLevelInfo (vipLevelInfo)
        
        NodeHelper:setSpriteImage(inst.container, {
            -- TODO : 可能之後改從GameConfig或其他ImagePath工具去找圖路徑
            levelIconImg = PathAccesser:getVIPIconPath(vipLevelInfo.level)
        })

        NodeHelper:setStringForLabel(inst.container, {
            expNumText = tostring(vipLevelInfo.exp).."/"..tostring(vipLevelInfo.expMax)
        })
        
        local expBarParentNode = inst.container:getVarNode("expBarNode")
        local expBar = inst.container:getVarScale9Sprite("expBar")
        
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

    --[[ 當 VIPHelp按下 ]]
    function inst:onVIPHelpBtn ()
        PageManager.pushPage("Recharge.RechargeVIPPage")
    end


    --[[ 刷新頁面 ]]
    function inst:refreshPage () 
        inst:rebuildAllItem();
    end

    --[[ 送出 請求 商品列表 ]]
    function inst:sendShopListRequest ()
       -- local msg = Recharge_pb.HPFetchShopList()
       --msg.platform = libPlatformManager:getPlatform():getClientChannel()
       --if Golb_Platform_Info.is_win32_platform then
       --     msg.platform = GameConfig.win32Platform
       -- end
       -- CCLuaLog("PlatformName2:" .. msg.platform)
       -- pb_data = msg:SerializeToString()
       --
       -- PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    end

    --[[ 接收 商品列表 ]]
    function inst:receiveShopList (msg)
        local monthCard = {}
        local normalCard = {}
        for k, v in ipairs(msg.shopItems) do
            -- if v.productPrice < 960 then
            if v.productType == 0 then
                table.insert(normalCard, v)
            else
                table.insert(monthCard, v)
            end
            -- else
            -- table.insert(inst.largeRechargeListInfo , v)
            -- end
        end
        if Golb_Platform_Info.is_entermate_platform then
            table.sort(normalCard, function(e1, e2)
                return e1.productPrice > e2.productPrice
            end )
        end
        --[[
        for k,v in ipairs(normalCard) do
            monthCard[#monthCard + 1] = v
        end--]]
        inst.rechargeListInfo = normalCard
        -- dump(inst.rechargeListInfo, "inst.rechargeListInfo")
        -- monthCard
        inst:rebuildAllItem();
    end

    --[[ 重建 商品項目 ]]
    function inst:rebuildAllItem()
        inst:clearAllItem();
        inst:buildItem();
    end
    
    --[[ 清空 商品項目 ]]
    function inst:clearAllItem()
        NodeHelper:clearScrollView(inst.container);
    end
    
    --[[ 建立 商品項目 ]]
    function inst:buildItem()
        -- #PageInfo.rechargeListInfo
        local size = math.ceil(#inst.rechargeListInfo / ITEM_COUNT_PER_ROW)
        -- RechargeContentItem
        NodeHelperUZ:buildScrollViewVertical(inst.container, size, "RechargeDiamondContentItem.ccbi", 
            function (eventName, container)
                RechargeDiamondItem.onFunction(inst, eventName, container)
            end, 
            {
                originScrollViewSize = CCSizeMake(700, 700),
                -- isDisableTouchWhenNotFull = true,
            }
        );
        
    end

    return inst
end


-- 充值項目相關 ---------------------------
-- 頗亂，所以大致上依照原本的寫法不改

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
    local baseIndex =(contentId - 1) * ITEM_COUNT_PER_ROW
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
    --[[
        --  {
            "productDec" : "You recharged, and should have received 600 Gems. If not, let us know.",
            "productTitle" : "Pile of Gems",
            "productPrice" : 9.99,
            "productLocalId" : "en_MY@currency=USD",
            "productId" : "794"
          }
    -- ]]

    -- 物品資訊
    local itemInfo = inst.rechargeListInfo[index]

    -- 建立 物品UI
    local itemNode = ScriptContentBase:create(RechargeDiamondItem.ccbiFile, index)
    -- 註冊 行為
    itemNode:registerFunctionHandler(function (eventName, container)
      RechargeDiamondItem.onRecharge(inst, eventName, container)
    end)
    
    -- 設置 內容數量
    NodeHelper:setStringForLabel(itemNode, {
        rewardCountText = tostring(itemInfo.gold)
    })

    -- itemNode:getVarLabelBMFont("mmItemRMB"):setVisible(Golb_Platform_Info.is_h365)
    -- itemNode:getVarNode("mHoneyPNode"):setVisible(Golb_Platform_Info.is_r18)
    -- itemNode:getVarNode("mJggNode"):setVisible(Golb_Platform_Info.is_jgg)

    -- NodeHelper:setSpriteImage(itemNode, { 
    --     mGiveNode = "Recharge_giveCount_" .. index .. ".png",
    --     mCountimage = "Recharge_count_" .. index .. ".png",
    --     mBg = "Recharge_itemBg_" .. index .. ".png" 
    -- })

    -- 若有 額外贈送
    local isBonusExist = itemInfo:HasField("showAddGold") ~= nil

    -- 顯示/隱藏
    NodeHelper:setNodesVisible(itemNode, {
        bonusNode = isBonusExist
    })
    -- 若 存在 則 設置 額外數量
    if isBonusExist then
        NodeHelper:setStringForLabel(itemNode, {
            bonusCountText = "+"..tostring(itemInfo.showAddGold)
        })
    end

    -- 價格相關 ---------------------

    local productPriceText = "$"..tostring(itemInfo.productPrice)

    -- TODO : 依照平台改變顯示的價格

    -- 依照商品類型 -----------------

    -- 商品類型 : 普通
    if itemInfo.productType == 0 then
        
        -- 覆蓋 商品圖片 為 鑽石
        NodeHelper:setSpriteImage(itemNode, {
            itemImg = RechargeDataMgr:getDiamondImgPath(1)
        })

        -- TODO : 好像要依照鑽石數量有不同的商品圖?

        -- 設 是否為首次儲值 為 比率是否存在(???)
        local isFirstBuy = itemInfo:HasField("ratio") ~= nil

        -- 顯示/隱藏 首儲相關
        NodeHelper:setNodesVisible(itemNode, { specialLabelNode = isFirstBuy })
        if isFirstBuy then
            NodeHelper:setStringForLabel(itemNode, {
                specialLabelText = common:getLanguageString("@Recharge.FirstTimeBuy")
            })
        end
        
    
    -- 商品類型 : 月卡
    elseif itemInfo.productType == 1 then
        -- 覆蓋 商品圖片 為 月卡
        NodeHelper:setSpriteImage(itemNode, { itemImg = GameConfig.Image.MonthCard })

        -- 關閉 特殊標籤
        NodeHelper:setNodesVisible(itemNode, { mFirstNode = false })
        -- itemNode:getVarLabelTTF("mItemGold"):setString( common:getLanguageString("@MonthCard") )
        -- itemNode:getVarLabelTTF("mLabelContent"):setVisible(false)

        -- 若 某些條件下 設置 價格文字 為 已購買
        if Golb_Platform_Info.is_entermate_platform and UserInfo.playerInfo.monthCardLeftDay and UserInfo.playerInfo.monthCardLeftDay > 0 then
            productPriceText = common:getLanguageString("@AlreadyBuy")
        end
    end

    -- 設置 價格 文字
    NodeHelper:setStringForLabel(itemNode, {
        priceText = productPriceText
    })

    itemNode:release()

    return itemNode
end

-- 展示奖励描述信息
function RechargeDiamondItem.onRecharge(inst, eventName, container)
    if eventName ~= "onBuyBtn" then
        return
    end

    local index = container:getTag()
    local itemInfo = inst.rechargeListInfo[index]

    if itemInfo.productType == 1 and Golb_Platform_Info.is_entermate_platform then
        monthCardLeftDay = UserInfo.playerInfo.monthCardLeftDay
        if monthCardLeftDay and monthCardLeftDay > 0 then
            MessageBoxPage:Msg_Box("@AlreadyHaveMonthCard");
            return
        end
    end

    if itemInfo.productType == 1 then
        PacketManager:getInstance():sendPakcet(HP_pb.MONTHCARD_PREPARE_BUY, "", 0, false)
    end

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

    --local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)

    -- 日本平台
    -- if Golb_Platform_Info.is_gNetop_platform then end
    -- if Golb_Platform_Info.is_r2_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then end
end

return RechargeSubPage_Diamond