


-- 模塊工具
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local InfoAccesser = require("Util.InfoAccesser")
local TimeDateUtil = require("Util.TimeDateUtil")

-- 資料工具
local Const_pb = require("Const_pb")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local Shop_pb = require("Shop_pb")

-- 模塊
local UserInfo = require("PlayerInfo.UserInfo")
local ShopDataMgr = require("Shop.ShopDataMgr")
local ItemManager = require("Item.ItemManager")
local ConfigManager = require("ConfigManager")
local ItemLineContent = require("Shop.ItemLineContent")


local ShopSubPage_Base = {}

-- 建立
function ShopSubPage_Base.new ()
    
    -- 本體
    local Inst = {}

    -- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
    -- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
    -- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
    -- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
    --  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
    --   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
    --    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

    --[[ 設置 ]]

    -- 商店類型
    Inst.shopType = ShopDataMgr.ShopType.NONE

    -- UI檔
    Inst.ccbiFile = "empty.ccbi"

    -- 頁面設定
    Inst.itemCount_perLine = 2

    -- 滾動容器 大小
    Inst.scrollViewContainerSize = 7

    --[[ 變數 ]]

    -- 商店 主頁面
    Inst.controlPage = nil

    -- 父容器
    Inst.parentContainer = nil
    -- 容器
    Inst.container = nil

    -- 滾動視圖 容器
    Inst.scrollViewContainer = nil

    -- 當前 協定封包資訊
    Inst.curPagePacketInfo = nil


    -- 每行道具 行為
    Inst.ItemLineContent = nil

    -- #### ##    ## #### ######## 
    --  ##  ###   ##  ##     ##    
    --  ##  ####  ##  ##     ##    
    --  ##  ## ## ##  ##     ##    
    --  ##  ##  ####  ##     ##    
    --  ##  ##   ###  ##     ##    
    -- #### ##    ## ####    ##    

    --[[ 初始化 ]]
    function Inst:init(subPageInfo)
            
        self:setShopTypeCfg(subPageInfo._type)

        -- 設置 每行道具 行為
        self.ItemLineContent = ItemLineContent.new()

        -- 設置 取得 道具 資訊 行為
        self.ItemLineContent.getItemInfoIndexById_fn = function (id)
            local maxSize = table.maxn(self.curPagePacketInfo.allItemInfo)
            for i = 1, maxSize, 1 do
                local item = self.curPagePacketInfo.allItemInfo[i]
                if item.id == id then
                    return i
                end
            end
            return nil
        end
        -- 設置 當 購買道具 行為
        self.ItemLineContent.onBuy_fn = function (itemInfo, itemData)
            self:onBuyItem(itemInfo, itemData)
        end

        -- 設置 取得 道具 資訊資料 行為
        self.ItemLineContent.getItemInfoAndData_fn = function (idx)
            local info = self.curPagePacketInfo.allItemInfo[idx]
            if info == nil then return nil end
            local data = self.curPagePacketInfo.allItemData[idx]
            if data == nil then return nil end
            return {
                info = info,
                data = data,
                shopType = self.curPagePacketInfo.currentShopType,
            }
        end
        
    end


    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 

    --[[ 當 呼叫 (接收UI呼叫) ]]
    function Inst:onFunction(eventName, container)
    
    end

    --[[ 當 頁面 進入 ]]
    function Inst:onEnter(parentContainer, controlPage)
        -- 設置 父容器, 主頁面
        self.parentContainer = parentContainer
        self.controlPage = controlPage

        -- 以 ui檔 建立 並 設置 為 容器
        self.container = ScriptContentBase:create(self.ccbiFile)
        
        -- 註冊 呼叫 行為
        self.container:registerFunctionHandler(function (eventName, container)
            self:onFunction(eventName, container)
        end)

        -- 請求 主頁面 滾動視圖
        self.scrollViewContainer = self.controlPage:requestPanelScrollView(true, {
            size = self.scrollViewContainerSize,
        })

        return self.container
    end

    --[[ 當 頁面 每幀 ]]
    function Inst:onExecute(parentContainer)
        
    end

    --[[ 當 頁面 離開 ]]
    function Inst:onExit(parentContainer)
        --新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
            if guideCfg and guideCfg.showType == 8 then
                GuideManager.forceNextNewbieGuide()
            end
        end
    end

    --[[ 當 接收 子頁面 封包 ]]
    function Inst:onReceiveSubPagePacket(packetInfo)
        
    end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 設置 商店類型 ]]
    function Inst:setShopTypeCfg(shopType)
        self.shopType = shopType

        local subPageInfo = ShopDataMgr:getSubPageInfo(self.shopType)
        if subPageInfo == nil then return end
        
        self.itemCount_perLine = subPageInfo._itemCount_perLine
    end

    --[[ 取得 協定封包資訊 ]]
    function Inst:getPacketInfo()
        local shopPacketInfo = ShopDataMgr:getPacketInfo(self.shopType)

        if not shopPacketInfo.isInit then
            ShopDataMgr:sendShopItemInfoInitRequest(self.shopType)
        else
            self:onReceivePacket(nil)
        end
    end

    --[[ 當 接收協定封包 ]]
    function Inst:onReceivePacket(parentContainer)
        -- 設置 當前頁面 封包
        self.curPagePacketInfo = ShopDataMgr:getPacketInfo(self.shopType)

        if self.onReceiveSubPagePacket then
            self:onReceiveSubPagePacket(self.curPagePacketInfo)
        end
        
        -- 刷新頁面
        self:refreshPage()
    end


    --[[ 取得 貨幣資訊 ]]
    function Inst:getCurrencyDatas()
        local shopInfo = ShopDataMgr:getSubPageInfo(self.shopType)
        local itemCfg = ConfigManager.getUserPropertyCfg()

        local datas = {}
        
        for idx, info in ipairs(shopInfo._currencyInfos) do
            local currencyInfo = InfoAccesser:getItemInfoByStr(info.priceStr)
            local currencyIconCfg = InfoAccesser:getItemIconCfg(currencyInfo.type, currencyInfo.id, "CommTabStorage.currency")
            
            local data = {
                icon = currencyInfo.icon,
                count = InfoAccesser:getUserItemCountByStr(info.priceStr),
                type = currencyInfo.type,
                id = currencyInfo.id,
            }

            if currencyIconCfg ~= nil then 
                data.iconScale = currencyIconCfg.scale
            end

            datas[idx] = data
        end

        return datas
    end

    --[[ 刷新頁面 ]]
    function Inst:refreshPage()
        local brushText = "@Brush" --刷新
        
        self:rebuildAllItem()
    end

    --[[ 重建 所有商品 ]]
    function Inst:rebuildAllItem()
        self:clearAllItem()
        self:buildItem()
    end

    --[[ 清除 所有商品 ]]
    function Inst:clearAllItem()
        NodeHelper:clearScrollView(self.scrollViewContainer)
    end

    --[[ 組建 所有商品 ]]
    function Inst:buildItem()
        
        -- 計算所需尺寸
        local maxLineSize = math.ceil(#self.curPagePacketInfo.allItemInfo / self.itemCount_perLine)

        local options = {
            isBounceable = true,
            interval = 20,
            paddingTop = 30, --magic number
            paddingBottom = 30,
            startOffsetAtItemIdx = 1,
        }
        options.startOffset = ccp(0, -options.paddingTop)

        -- 在container上 以ItemLineContent為子元素 相關 ui(ccbi) 與 行為 設置 來 建立 滾動視圖ScrollView3
        NodeHelperUZ:buildScrollViewVertical(
            self.scrollViewContainer, maxLineSize,
            self.ItemLineContent.ccbiFile, 
            function (eventName, container)
                self.ItemLineContent:onFunction(eventName, container)
            end,
            options
        )
    end


    -- ########  ########  #### ##     ##    ###    ######## ######## 
    -- ##     ## ##     ##  ##  ##     ##   ## ##      ##    ##       
    -- ##     ## ##     ##  ##  ##     ##  ##   ##     ##    ##       
    -- ########  ########   ##  ##     ## ##     ##    ##    ######   
    -- ##        ##   ##    ##   ##   ##  #########    ##    ##       
    -- ##        ##    ##   ##    ## ##   ##     ##    ##    ##       
    -- ##        ##     ## ####    ###    ##     ##    ##    ######## 
    
    --[[ 請求 資料刷新 ]]
    function Inst:requestPassiveRefreshShop()
        -- 送訊息給server 要求 商品資料
        -- 因為 一般被動類(e.g.定期)刷新 不需要Client呼叫 就會 由Server更新資料
        -- Client 只要 重新取得商店資料就是最新的了
        ShopDataMgr:sendShopItemInfoInitRequest(self.shopType)
    end

    --[[ 請求 手動資料刷新 ]]
    function Inst:requestManualRefreshShop(refreshType)
        -- 送訊息給server 要求 商品資料 刷新
        ShopDataMgr:sendShopItemInfoRefreshRequest(self.shopType, refreshType)
    end

    --[[ 當 購買道具 ]]
    function Inst:onBuyItem(itemInfo, itemData)

        -- 檢查 購買條件

        -- 剩餘數量
        local isLeftCountEnough = itemData.leftCount > 0 or itemInfo.totalCount == 0
        if not isLeftCountEnough then 
            return
        end

        -- 等級
        if itemData.levelRequire ~= nil then
            UserInfo.syncRoleInfo()
            -- 若 等級未到
            if UserInfo.roleInfo.level < itemData.levelRequire then
                MessageBoxPage:Msg_Box_Lan("@NoPrivateChatLevelLimit")
                return
            end
        end

        -- 解析 價格資訊
        local priceInfo = ConfigManager.parseItemOnlyWithUnderline(itemInfo.priceStr)

        -- TODO 選擇組數
        local requireCount = 1

        -- 價格數量 * 需要組數
        priceInfo.count = priceInfo.count * requireCount

        -- 呼叫 檢查 此貨幣 是否足夠該價格
        if not ShopDataMgr:isEnoughToPrice(priceInfo) then
            print("[ShopSubPage_Base] : not enough price")
            MessageBoxPage:Msg_Box(common:getLanguageString("@LackItem"))
            return
        end
        
        -- print("[ShopSubPage_Base] : send buy request")
        PageManager.showConfirm(common:getLanguageString("@ShopComfirmTitle"), common:getLanguageString("@ShopComfirm"), function(isSure)
            if isSure then
                ShopDataMgr:sendBuyShopItemsRequest(ShopDataMgr.BuyMethodType.SINGLE, self.shopType, itemInfo.id, requireCount)
            end
        end, true)
    end

    return Inst
end

return ShopSubPage_Base