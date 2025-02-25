--[[ 
    name: ShopDataMgr
    desc: 商店頁面 資料管理
    author: youzi
    update: 2023/8/1 14:51
    description: 

--]]

--[[ 引用 ]]

local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local HP_pb = require("HP_pb") --包含协议id文件
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local UserInfo = require("PlayerInfo.UserInfo")
local InfoAccesser = require("Util.InfoAccesser")
local EventDataMgr = require("Event001DataMgr")

--[[ 本體 ]]
local Inst = {}

--  ######   #######  ##    ##  ######  ######## 
-- ##    ## ##     ## ###   ## ##    ##    ##    
-- ##       ##     ## ####  ## ##          ##    
-- ##       ##     ## ## ## ##  ######     ##    
-- ##       ##     ## ##  ####       ##    ##    
-- ##    ## ##     ## ##   ### ##    ##    ##    
--  ######   #######  ##    ##  ######     ##    

--[[ 定義 商店類型 ]]
local shopTypeList = {
    {"NONE", 0},
    {"GODSEA", 15},
    {"GODSEA2", 17},
    {"DAILY", 10},
    {"MYSTERY", 11},
    {"RACE", 14},
    {"GUILD", 12},
    {"ARENA", 4},
    {"CROSS", 6},
    {"TEMPLE", 13},
}

--[[ 商店類型 ]]
Inst.ShopType = {}
-- 有序填入
for idx, val in ipairs(shopTypeList) do
    Inst.ShopType[val[1]] = val[2]
end

--[[ 商店類型 序號列表 ]]
Inst.ShopTypeIndexes = {}
-- 有序填入
for idx, val in ipairs(shopTypeList) do
    if val[2] ~= 0 then
        Inst.ShopTypeIndexes[#Inst.ShopTypeIndexes+1] = val[2]
    end
end
-- table.sort(Inst.ShopTypeIndexes)

--[[ 商店類型數量 ]]
Inst.ShopCount = #Inst.ShopTypeIndexes

--[[ 購買類型 ]]
Inst.BuyMethodType = {
    SINGLE = 1, 
    ALL = 2,
}

--[[ 商店 子頁面 資訊 ]] -- ("_"開頭為必備資訊, 其餘 各商店可自由定義)
local createSubPageInfo = function (shopType, overrideInfo)
    local subPageInfo = {    
        -- 類型
        _type = shopType, 
        -- 當圖標被點選時, 要呼叫的Function名稱
        _onIconClickFuncName = "onBtnSelect",
        -- 貨幣資訊 (多個貨幣)
        _currencyInfos = {},
        -- 開放條件
        _avaliableConditions = {},
        -- 商品架上 每列 多少商品 (與UI中設計有關, 目前應該是1~2個或固定2個)
        _itemCount_perLine = 2,
        -- 幫助 (目前不知道用途)
        _helpFile = GameConfig.HelpKey.HELP_MARKET_ITEM,
    }
    for k, v in pairs(overrideInfo) do
        subPageInfo[k] = v
    end
    return subPageInfo
end

--[[ 各 商店子頁面 資訊 ]]
Inst.Type2SubPageInfo = {
    -- 神海
   [Inst.ShopType.GODSEA] = {
       -- 腳本檔名
       _scriptName = "Shop.ShopSubPage_Weekly",
       -- 標題
       _title = "@GodSeaShopTitle",
       -- 圖標
       _iconImg_normal = "SubBtn_GodseaShop.png",
       _iconImg_selected = "SubBtn_GodseaShop_On.png",
       -- 圖標名稱
       _iconName = "@Goods",
       -- 貨幣資訊 
       _currencyInfos = {
           { priceStr = "30000_" .. EventDataMgr[Const_pb.ACTIVITY191_CycleStage].TOKEN_ID .. "_0" },
       },
       _avaliableConditions = {
           deactive = not ActivityInfo:getActivityIsOpenById(Const_pb.ACTIVITY191_CycleStage),
       },
       -- 關閉道具+號按鈕
       _closePlusBtn = true,
   },
   -- 神海2
   [Inst.ShopType.GODSEA2] = {
       -- 腳本檔名
       _scriptName = "Shop.ShopSubPage_Weekly",
       -- 標題
       _title = "@GodSeaShopTitle",
       -- 圖標
       _iconImg_normal = "SubBtn_GodseaShop.png",
       _iconImg_selected = "SubBtn_GodseaShop_On.png",
       -- 圖標名稱
       _iconName = "@Goods",
       -- 貨幣資訊 
       _currencyInfos = {
           { priceStr = "30000_" .. EventDataMgr[Const_pb.ACTIVITY196_CycleStage_Part2].TOKEN_ID .. "_0" },
       },
       _avaliableConditions = {
           deactive = not ActivityInfo:getActivityIsOpenById(Const_pb.ACTIVITY196_CycleStage_Part2),
       },
       -- 關閉道具+號按鈕
       _closePlusBtn = true,
   },
    -- 每日
    [Inst.ShopType.DAILY] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Daily",
        -- 標題
        _title = "@DailyShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_DailyShop.png",
        _iconImg_selected = "SubBtn_DailyShop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        -- 開放條件
        _avaliableConditions = {
        },
        -- 解鎖條件KEY
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SHOP_DAILY,
    },
    -- 神秘
    [Inst.ShopType.MYSTERY] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Mystery",
        -- 標題
        _title = "@MysteryShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_SecretShop.png",
        _iconImg_selected = "SubBtn_SecretShop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        -- 刷新貨幣
        refreshCurrency = "10000_1001_0",
        -- 開放條件
        _avaliableConditions = {
        },
        -- 解鎖條件KEY
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SHOP_MYSTERY,

        isRedOn = function() return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.SHOP_MYSTERY_TAB) end,
    },
    -- 英雄
    -- 種族
   [Inst.ShopType.RACE] = {
       -- 腳本檔名
       _scriptName = "Shop.ShopSubPage_Daily",
       -- 標題
       _title = "@RaceShopTitle",
       -- 圖標
       _iconImg_normal = "SubBtn_RaceShop.png",
       _iconImg_selected = "SubBtn_RaceShop_On.png",
       -- 圖標名稱
       _iconName = "@Goods",
       -- 貨幣資訊 
       _currencyInfos = {
           { priceStr = "30000_6010_0" },
       },
       -- 開放條件
       _avaliableConditions = {
            deactive = true,
       },
       -- 解鎖條件KEY
       LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SHOP_RACE,
   },
    -- 公會
    [Inst.ShopType.GUILD] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Weekly",
        -- 標題
        _title = "@GuildShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_GuildShop.png",
        _iconImg_selected = "SubBtn_GuildShop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        -- 開放條件
        _avaliableConditions = {
            deactive = true,
        },
    },
    -- 角鬥
    [Inst.ShopType.ARENA] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Daily",
        -- 標題
        _title = "@ArenaShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_ArenaShop.png",
        _iconImg_selected = "SubBtn_ArenaShop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "30000_6009_0" },
        },
        _avaliableConditions = {
        },
        -- 解鎖條件KEY
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SHOP_ARENA,
    },
    -- 跨服
    [Inst.ShopType.CROSS] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Weekly",
        -- 標題
        _title = "@CrossShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_CrossShop.png",
        _iconImg_selected = "SubBtn_CrossShop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        _avaliableConditions = {
            deactive = true,
        },
    },
    -- 殿堂
    [Inst.ShopType.TEMPLE] = {
        -- 腳本檔名
        _scriptName = "Shop.ShopSubPage_Daily",
        -- 標題
        _title = "@TempleShopTitle",
        -- 圖標
        _iconImg_normal = "SubBtn_Arena2Shop.png",
        _iconImg_selected = "SubBtn_Arena2Shop_On.png",
        -- 圖標名稱
        _iconName = "@Goods",
        -- 貨幣資訊 
        _currencyInfos = {
            { priceStr = "10000_1002_0" },
            { priceStr = "10000_1001_0" },
        },
        _avaliableConditions = {
            deactive = true,
        },
    },
}
-- 以 基礎子頁面資訊 與 子頁面資訊 重新建立 子頁面資訊
for typ, pageInfo in pairs(Inst.Type2SubPageInfo) do
    Inst.Type2SubPageInfo[typ] = createSubPageInfo(typ, pageInfo)
end

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

--[[ 商店類型:子頁面 資料 ]]
Inst.type2SubPageData = {}
for key, val in pairs(Inst.ShopType) do
    local typ = val
    Inst.type2SubPageData[typ] = {}
end

--[[ 商店類型:數據包資訊 ]]
local createPacketInfo = function ()
    return {
        allItemInfo = {},
        allItemData = {},
        refreshPrice = 0,
        isInit = false,
    }
end
Inst.type2PacketInfo = {}
for idx, typeIdx in ipairs(Inst.ShopTypeIndexes) do
    Inst.type2PacketInfo[typeIdx] = createPacketInfo()
end


-- 當前商店類型 預設
Inst.currentShopType = -1

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

--[[ 取得 可使用的商店 ]]
function Inst:getAvaliableShopTypes()
    local avaliableShopTypes = {}

    UserInfo.syncRoleInfo()
    local userLevel = UserInfo.roleInfo.level

    for idx, shopType in ipairs(Inst.ShopTypeIndexes) do while true do

        local info = self.Type2SubPageInfo[shopType]

        -- 若 有 開放條件
        if info._avaliableConditions then

            -- 指定關閉
            if info._avaliableConditions.deactive then
                break --continue
            end

            -- 等級條件
            if info._avaliableConditions.aboveLevel then
                if userLevel < info._avaliableConditions.aboveLevel then
                    break -- continue
                end
            end

        end

        avaliableShopTypes[#avaliableShopTypes+1] = shopType
    
    break end end

    return avaliableShopTypes
end

--[[ 取得 類型 ]]
function Inst:getShopTypeByIndex(shopIdx)
    return self.ShopTypeIndexes[shopIdx]
end

--[[ 設置 當前商店 ]]
function Inst:setCurrentShop(shopType)
    self.currentShopType = shopType
end

--[[ 取得 子頁面 資訊 ]]
function Inst:getSubPageInfo(shopType)
    local _type = shopType or self.currentShopType
    return self.Type2SubPageInfo[_type]
end

--[[ 取得 子頁面 資料 ]]
function Inst:getSubPageData(shopType)
    local _type = shopType or self.currentShopType
    return self.type2SubPageData[_type]
end

--[[ 取得 子頁面 封包資訊 ]]
function Inst:getPacketInfo(shopType)
    local _type = shopType or self.currentShopType
    -- print("self.getPacketInfo _type = "..tostring(_type))
    return self.type2PacketInfo[_type]
end


--[[ 重設 所有子頁面 協定封包 ]]
function Inst:resetAllPacketInfo(shopType)
    for key, val in pairs(self.type2PacketInfo) do
        val.isInit = false
    end
end

--[[ 重設 子頁面 協定封包 ]]
function Inst:resetPacketInfo(shopType)
    if shopType == nil then
        shopType = self.currentShopType    
    end

    local packetInfo = self.type2PacketInfo[shopType]

    if packetInfo == nil then return end

    packetInfo.isInit = false

end

--[[ 設置 子頁面 封包資訊 ]]
function Inst:setPacketInfo(msg)
    -- print(string.format("[Inst] setPacketInfo : shopType[%d]", msg.shopType))

    -- 檢查

    if msg == nil then return end
    
    local shopType = msg.shopType
    if shopType <= 0 then return end

    -- 取得 或 建立 封包資訊
    local packetInfo = self.type2PacketInfo[shopType]
    if packetInfo == nil then 
        packetInfo = {}
        self.type2PacketInfo[shopType] = packetInfo
    end
    packetInfo.isInit = true

    -- 依照不同類型 設置
    
    if shopType == self.ShopType.NONE then

    else
        -- dump(msg.itemInfo, "packetInfo.allItemInfo")
        
        -- 建立 商品資料 空資料
        packetInfo.allItemInfo = {}
        packetInfo.allItemData = {}
        for idx, info in ipairs(msg.itemInfo) do
            packetInfo.allItemInfo[idx] = info
            packetInfo.allItemData[idx] = {
                leftCount = 0
            }
        end

        -- 資料類型 與 計數
        local type2Count = {}
        for idx, data in ipairs(msg.data) do
            
            -- if data.dataType == Const_pb. 
            -- 暫時找不到可從定義取int的地方, 只能直接以 type作為key

            -- 計數 (取得 或 建立)
            local count = 0
            if type2Count[data.dataType] ~= nil then
                count = type2Count[data.dataType]
            end
            count = count + 1
            type2Count[data.dataType] = count

            -- 取得 商品資料
            local itemData = packetInfo.allItemData[count]


            -- 依照 資料類型 設置 商品資料[資料欄位]
            if data.dataType == 13 then -- Const.proto/DataType.ITEM_LEFT
                itemData.leftCount = data.amount
            elseif data.dataType == 14 then -- Const.proto/DataType.LEVEL_LIMIT
                itemData.levelRequire = data.amount

            -- elseif data.dataType == XX then
            
            -- elseif data.dataType == XX then

            else
                itemData[data.dataType] = data.amount
            end
        end

        -- Test
        -- local _test_multi = 3
        -- local _test_total = #packetInfo.allItemInfo
        -- for multiIdx = 1, (_test_multi-1) do
        --     local baseIdx = _test_total * multiIdx
        --     for idx = 1, _test_total do
        --         local nxt = baseIdx + idx 
        --         print(string.format("nxt[%s] idx[%s]", nxt, idx))
        --         packetInfo.allItemInfo[nxt] = packetInfo.allItemInfo[idx]
        --         packetInfo.allItemData[nxt] = packetInfo.allItemData[idx]
        --     end
        -- end

        -- 若 刷新價格 存在
        if msg.refreshPrice then
            -- 設置 刷新價格
            packetInfo.refreshPrice = msg.refreshPrice
        end

        -- 免費刷新次數
        if msg.freeRefresh then
            packetInfo.freeRefresh = msg.freeRefresh
        end
        -- 付費刷新次數
        if msg.costRefresh then
            packetInfo.costRefresh = msg.costRefresh
        end
        -- 上次補充刷新次數時間
        if msg.refreshTime then
            packetInfo.refreshTime = msg.refreshTime
        end
    end
end

--[[ 是否足夠該價格 ]]
function Inst:isEnoughToPrice(priceInfo_or_str)
    local priceInfo = priceInfo_or_str
    if type(priceInfo_or_str) ~= "table" then
        priceInfo = InfoAccesser:getItemInfoByStr(priceInfo_or_str)
    end
    return InfoAccesser:getUserItemCount(priceInfo.type, priceInfo.itemId) >= priceInfo.count
end


----------packet msg--------------------------

--[[ 送出 請求商品資料 初始化 ]]
-- @params shopType 商店類型 (e.g. 1:每日 2:xx ....)
function Inst:sendShopItemInfoInitRequest(shopType)
    local msg = Shop_pb.ShopItemInfoRequest()
    msg.type = Const_pb.INIT_TYPE
    msg.shopType = shopType or self.currentShopType
    dump({
        ["type"] = Const_pb.INIT_TYPE,
        ["shopType"] = shopType or self.currentShopType,
    }, "Inst:sendShopItemInfoInitRequest")
    
    common:sendPacket(HP_pb.SHOP_ITEM_C, msg, true)
end

--[[ 送出 請求商品資料 刷新 ]]
-- @params shopType 商店類型 (e.g. 1:每日 2:xx ....)
-- @params refreshType 刷新類型 (e.g. 0:免費 1:付費)
function Inst:sendShopItemInfoRefreshRequest(shopType, refreshType)
    local msg = Shop_pb.ShopItemInfoRequest()
    msg.type = Const_pb.REFRESH_TYPE
    msg.shopType = shopType or self.currentShopType
    msg.refreshType = refreshType
    if refreshType == nil then
        msg.refreshType = 0
    end
    dump({
        ["type"] = Const_pb.REFRESH_TYPE,
        ["shopType"] = shopType or self.currentShopType,
        ["refreshType"] = refreshType,
    }, "Inst:sendShopItemInfoRefreshRequest")
    common:sendPacket(HP_pb.SHOP_ITEM_C, msg, true)
end

--[[ 送出 購買商品 ]]
function Inst:sendBuyShopItemsRequest(buyType, shopType, itemId, itemCount, currencyType)
    local msg = Shop_pb.BuyShopItemsRequest()
    msg.type = buyType --1.单个购买 2.全部购买
    msg.shopType = shopType
    if itemId then
        msg.id = itemId --商城唯一ID
    end

    if itemCount then
        msg.amount = itemCount
     --购买数量
    end
    if currencyType then
        msg.buyType = currencyType
     --货币類型
    end
    --common:sendPacket(HP_pb.SHOP_BUY_C, msg, true)
    common:sendPacket(HP_pb.SHOP_BUY_C, msg, false)
end
----------packet msg--------------------------
return Inst
