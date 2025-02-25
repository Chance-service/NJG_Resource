----------------------------------------------------------------------------------
--[[
    name: 商店主頁面
    desc: 主要頁面, 控制 共用UI 以及 管理 子頁面.
--]]
----------------------------------------------------------------------------------

-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

-- 定義
local thisPageName = "ShopControlPage"

-- 模塊工具
local NodeHelper = require("NodeHelper")
local NodeHelperUZ = require("Util.NodeHelperUZ")
local TimeDateUtil = require("Util.TimeDateUtil")
local Vals = require("Util.Vals")
local CommTabStorage = require("CommComp.CommTabStorage")

-- 資料工具
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Recharge_pb = require("Recharge_pb")
local Shop_pb = require("Shop_pb")

-- 其他模塊
local UserInfo = require("PlayerInfo.UserInfo")
local ShopDataMgr = require("Shop.ShopDataMgr")

-- 字典 (若有將Shop.lang轉寫入Language.lang中可移除此處與Shop.lang)
--Language:getInstance():addLanguageFile("Lang/Shop.lang")

-- 主體
local Inst = {}

-- 商店圖標 (於尾頁定義)
local ShopTypeContainer = {}

-- 頁面設定
local option = {
    ccbiFile = "FairPage.ccbi",
    handlerMap = {
        onRefreshBtn = "onManualRefreshBtn",
        onHelp = "onHelp"
    },
    opcodes = {
        SHOP_ITEM_C = HP_pb.SHOP_ITEM_C,
        SHOP_ITEM_S = HP_pb.SHOP_ITEM_S,
        SHOP_BUY_C = HP_pb.SHOP_BUY_C,
        SHOP_BUY_S = HP_pb.SHOP_BUY_S
    }
}

-- 本體 UI容器
local mContainerRef = {}
-- 子頁面 容器節點 (全覆蓋)
local mSubNode = nil
-- 子面板 容器節點 (下方面板)
local mPanelNode = nil
-- 子面板 容器節點 的 滾動視圖 (下方面板)
local mPanelScrollViewNode = nil
local mPanelScrollView = nil

local mCommTabStorage = nil

local mCurrentIndex = 0
local fOneItemWidth = 0
local fScrollViewWidth = 0

local curPagePacketInfo = nil

-- 商店圖標序號 : 商店類型 表
local avaliableShopTypes = {}

-- 更新 的 倒數幀數
local iTimeFrame = 0

-- 自動刷新 剩餘時間
local refreshAutoLeftTime = 0
-- 手動刷新 剩餘時間
local refreshManualLeftTime = 0

-- 自動刷新 下次時間
local refreshAutoNextTime = -1
-- 手動刷新 下次時間
local refreshManualNextTime = -1

local originRefreshPriceScale = nil

-- 自動刷新UI 顯示 多重數值
Inst.isRefreshAutoShowVals = nil
-- 手動刷新UI 顯示 多重數值
Inst.isRefreshManualShowVals = nil

-- 起始頁面
Inst.startPage = nil


-- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
--  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
--  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
--  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
--  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
--  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
-- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


--                        
--  #####    ##    ####  ###### 
--  #    #  #  #  #    # #      
--  #    # #    # #      #####  
--  #####  ###### #  ### #      
--  #      #    # #    # #      
--  #      #    #  ####  ###### 
--                               

--[[ 當 進入頁面 ]]
function Inst:onEnter(container)
    mContainerRef = container
    
    -- 重設所有資料
    ShopDataMgr:resetAllPacketInfo()

    avaliableShopTypes = ShopDataMgr:getAvaliableShopTypes()

    -- 註冊 訊息
    container:registerMessage(MSG_MAINFRAME_REFRESH)

    -- 取得 節點
    mSubNode = container:getVarNode("mContentNode")
    mPanelNode = container:getVarNode("mScale9Sprite1")
    mPanelScrollViewNode = container:getVarNode("panelScrollViewRoot")

    originRefreshPriceScale = container:getVarNode("refreshManualPriceImg"):getScale()

    -- 註冊 當 自動刷新UI 顯示值 更新
    self.isRefreshAutoShowVals = Vals:new(false)
    table.insert(self.isRefreshAutoShowVals.on_update, function(newVal)
        NodeHelper:setNodesVisible(container, {
            refreshAuto = newVal
        })
    end)
    self.isRefreshAutoShowVals:update(false)
    
    -- 註冊 當 手動刷新UI 顯示值 更新
    self.isRefreshManualShowVals = Vals:new(false)
    table.insert(self.isRefreshManualShowVals.on_update, function(newVal)
        -- 改變顯示
        NodeHelper:setNodesVisible(container, {
            refreshManual = newVal
        })
    end)
    self.isRefreshManualShowVals:update(false)

    -- 綁定 子頁面ccb 的 節點 --------
    if mSubNode then
        mSubNode:removeAllChildren()
    end

    -- 建立 分頁UI ----------------------------


    -- 準備分頁資訊
    local tabInfos = {}
    for idx, typ in ipairs(avaliableShopTypes) do
        local shopInfo = ShopDataMgr:getSubPageInfo(typ)
        tabInfos[idx] = {
            iconType = "image",
            icon_selected = shopInfo._iconImg_selected,
            icon_normal = shopInfo._iconImg_normal,
            icon_lock = (shopInfo.LOCK_KEY and LockManager_getShowLockByPageName(shopInfo.LOCK_KEY) or false),
            redpoint = (shopInfo.isRedOn and shopInfo.isRedOn or function() return false end),
            closePlus = shopInfo._closePlusBtn
        }
    end

    -- 初始化
    mCommTabStorage = CommTabStorage:new()
    mCommTabStorage:setScrollViewOverrideOptions({
        interval = 20
    })
    local CommTabStorageContainer = mCommTabStorage:init(tabInfos)
    mCommTabStorage.CommTabStorageContainer = CommTabStorageContainer

    -- 當前 商店資訊
    local selectIdx = 1
    ShopDataMgr.currentShopType = avaliableShopTypes[1]
    --for i = 1, #ShopDataMgr.ShopTypeIndexes do
    --    if ShopDataMgr.Type2SubPageInfo[ShopDataMgr.ShopTypeIndexes[i]].LOCK_KEY then
    --        if not LockManager_getShowLockByPageName(ShopDataMgr.Type2SubPageInfo[ShopDataMgr.ShopTypeIndexes[i]].LOCK_KEY) then
    --            ShopDataMgr.currentShopType = ShopDataMgr.ShopTypeIndexes[i]
    --            selectIdx = i
    --            break
    --        end
    --    else
    --        ShopDataMgr.currentShopType = ShopDataMgr.ShopTypeIndexes[i]
    --        selectIdx = i
    --    end
    --end
    
    -- 預設 選中第一項
    mCommTabStorage:selectTab(selectIdx)
    
    -- 設置 當 選中分頁
    mCommTabStorage.onTabSelect_fn = function (nextTabIdx, lastTabIdx)

        local shopType = avaliableShopTypes[nextTabIdx]
        local shopInfo = ShopDataMgr:getSubPageInfo(shopType)
        
        if shopInfo.LOCK_KEY then
            if LockManager_getShowLockByPageName(shopInfo.LOCK_KEY) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(shopInfo.LOCK_KEY))
                return false
            end
        end

        local func = Inst[shopInfo._onIconClickFuncName] -- 通常是 onBtnSelect
        func(--[[ self ]]Inst, mContainerRef, shopType)

    end

    -- 設置 當 關閉
    mCommTabStorage.onClose_fn = function ()
        PageManager.popPage(thisPageName)
    end

    -- 暫時的, 之後應該整個ShopPage要改在CommTabStorage基礎下實現
    mCommTabStorage.onCurrencyBtn_fn = function (idx, itemInfo)
        local CommTabStoragePage = require("Comm.CommTabStoragePage")
        CommTabStoragePage:onCurrencyBtn(idx, itemInfo)
    end

    -- 加入UI
    mContainerRef:addChild(CommTabStorageContainer)
    
    -- 完成 分頁UI ----------------------------
    if self.startPage ~= nil then
        
        local tabIdx = 0
        for idx, each in ipairs(avaliableShopTypes) do
            if each == self.startPage then
                tabIdx = idx
            end
        end
        mCommTabStorage:selectTab(tabIdx)

        self.startPage = nil
    end
    
    -- 註冊 協定
    self:registerPacket(container)

    -- 更新頁面 (包含子頁面建立)
    self:refreshPage(container)
    
    -- 更新 貨幣資訊
    self:refreshCurrencyInfo(container)

    -- 更新 自動刷新 時間
    self:updateRefreshAutoTime()
    
    -- (待處理) 應該是 特規處理 只在 商店類型 為 3 的情況 不顯示help
    -- if mContainerRef then
    --     NodeHelper:setNodesVisible(mContainerRef, {
    --         mHelpNode = ShopDataMgr.currentShopType ~= 3
    --     })
    -- end
end

--[[ 更新 自動刷新 時間 ]]
function Inst:updateRefreshAutoTime()

    local clientTime = os.time()

    if not refreshAutoNextTime or refreshAutoNextTime < 0 then
        return
    end


    -- print(string.format("refreshAutoLeftTime[%d] refreshAutoNextTime[%d] clientTime[%d]", refreshAutoLeftTime, refreshAutoNextTime, clientTime))

    local text
    if refreshAutoNextTime < 0 then
        --text = common:getLanguageString("@Shop.Syncing")
    else
        -- 剩餘時間 轉至 日期格式
        local leftTimeDate = TimeDateUtil:utcTime2Date(refreshAutoNextTime)
        -- 欲設置字串
        local min = leftTimeDate.min
        -- 因為不顯示秒, 所以有秒數時要多顯示1分鐘
        if leftTimeDate.sec > 0 then min = min + 1 end
        text = common:getLanguageString("@CountdownTime1", leftTimeDate.day-1, leftTimeDate.hour, min)
    end

    -- 設置 到 標籤
    NodeHelper:setStringForLabel(mContainerRef, { refreshAutoCountdownText = text })

end

--[[ 更新 手動刷新 時間 ]]
function Inst:updateRefreshManualTime()

    local clientTime = os.time()

    
    local refreshManualNextTimeExist = refreshManualNextTime > 0
    NodeHelper:setNodesVisible(mContainerRef, { refreshManualCountdownText = refreshManualNextTimeExist})
    
    if not refreshManualNextTimeExist then return end

    -- 更新 剩餘時間
    refreshManualLeftTime = refreshManualNextTime - clientTime

    local text
    if refreshManualLeftTime < 0 then
        --text = common:getLanguageString("@syncing")
    else
        -- 剩餘時間 轉至 日期格式
        local leftTimeDate = TimeDateUtil:utcTime2Date(refreshManualLeftTime)
        -- 欲設置字串
        text = string.format(common:getLanguageString("@Shop.RefreshManual.countdown"), leftTimeDate.hour, leftTimeDate.min, leftTimeDate.sec)
    end

    -- 設置 到 標籤
    NodeHelper:setStringForLabel(mContainerRef, { refreshManualCountdownText = text })

end

--[[ 當 每幀 ]]
function Inst:onExecute(container)

    if self.subPage then
        self.subPage:onExecute(container)
    end

    -- 假設 fps = 60 
    iTimeFrame = iTimeFrame + 1
    -- 每60幀 (不一定為1秒)
    if (iTimeFrame >= 60) then
        iTimeFrame = 0

        --print("========================================倒數計時========================================");

        -- print("refreshAutoLeftTime : "..tostring(refreshAutoLeftTime))
        
        -- 更新 自動刷新 時間
        if self.isRefreshAutoShowVals.get_current() == true then
            self:updateRefreshAutoTime()
        end

        -- 更新 手動刷新 時間
        if self.isRefreshManualShowVals.get_current() == true then
            self:updateRefreshManualTime()
        end

        if (refreshAutoLeftTime < 0) then
            -- 送訊息給server要商品資料
            ShopDataMgr:sendShopItemInfoInitRequest(self.shopType)
        end
    end
end

--[[ 當 離開頁面 ]]
function Inst:onExit(container)
    
    -- 重置時間
    iTimeFrame = 0
    refreshAutoLeftTime = 0

    -- 若 都沒有需要付費的刷新 則 
    local is_can_refresh_with_pay = false
    for typ, info in pairs(ShopDataMgr.type2PacketInfo) do
        -- 若 有要付費的 則 跳出
        if info.refreshPrice ~= 0 then
            is_can_refresh_with_pay = true
            break
        end
    end
        
    -- 若 沒有可以付費 則 關閉紅點
    if not is_can_refresh_with_pay then
        GameConfig.shopRedPoint = false
    end

    -- 處理子頁面 離開 清空
    if self.subPage then
        self.subPage:onExit(container)
        self.subPage = nil
    end
    
    -- 註銷 協定相關
    self:removePacket(container)

    -- 重設 序號 為 首個頁面
    ShopDataMgr:setCurrentShop(ShopDataMgr:getAvaliableShopTypes()[1])
end

--  #     # ####### ####### 
--  ##    # #          #    
--  # #   # #          #    
--  #  #  # #####      #    
--  #   # # #          #    
--  #    ## #          #    
--  #     # #######    #    
--                             

--[[ 註冊 協定 ]]
function Inst:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

--[[ 註銷 協定 ]]
function Inst:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


--[[ 當 接收協定封包 ]]
function Inst:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msgPacket = {
        [HP_pb.SHOP_ITEM_S] = Shop_pb.ShopItemInfoResponse(),
        [HP_pb.SHOP_BUY_S] = Shop_pb.BuyShopItemsResponse()
    }

    -- 若 為 指定協定
    if opcode == HP_pb.SHOP_ITEM_S or opcode == HP_pb.SHOP_BUY_S then
        
        -- 取得 封包
        local msg = msgPacket[opcode]
        msg:ParseFromString(msgBuff)
        
        -- 轉 設置 封包 至 管理
        ShopDataMgr:setPacketInfo(msg)

        -- 刷新 貨幣資訊
        self:refreshCurrencyInfo(container)

        -- 若 為 購買回傳
        if opcode == HP_pb.SHOP_BUY_S then
            -- 訊息 預設為 獲得道具
            local txt = common:getLanguageString("@RewardItem2")
            -- 若有錯誤代碼 則 設置錯誤訊息
            if msg.errCode ~= nil then
                txt = common:getLanguageString("@ERRORCODE_"..tostring(msg.errCode))
            end
            -- 顯示訊息
            --MessageBoxPage:Msg_Box(txt)
        end
        
        -- 取得當前子頁面 封包資料
        curPagePacketInfo = ShopDataMgr:getPacketInfo(ShopDataMgr.currentShopType)
        curPagePacketInfo.currentShopType = ShopDataMgr.currentShopType
        -- 刷新 圖標
        for idx, typ in ipairs(avaliableShopTypes) do
            if typ == ShopDataMgr.currentShopType then
                mCommTabStorage:refreshTab(idx)
                break
            end
        end

        -- 呼叫 子頁面 當 接收協定封包
        if Inst.subPage then
            Inst.subPage:onReceivePacket(container)
        end
    end
end

--[[ 當 接收到訊息 ]]
function Inst:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName then
            self:refreshCurrencyInfo(container)
        end
    end
end

--  #     # ### 
--  #     #  #  
--  #     #  #  
--  #     #  #  
--  #     #  #  
--  #     #  #  
--   #####  ### 
--              


--[[ 當 手動刷新 被按下 ]]
function Inst:onManualRefreshBtn(container)
    if self.subPage then
        self.subPage:onManualRefreshBtn(container)
    end
end

--[[ 當 按鈕選中 ]]
function Inst:onBtnSelect(container, shopType)
    
    if ShopDataMgr.currentShopType ~= shopType then
        
        ShopDataMgr.currentShopType = shopType

        self:refreshPage(container)
        self:refreshCurrencyInfo(container)
    end
end

--[[ 當 說明 ]]
function Inst:onHelp(container)
    local info = ShopDataMgr:getSubPageInfo()
    PageManager.showHelp(info._helpFile)
end

-- ########  ##     ## ########  ##       ####  ######  
-- ##     ## ##     ## ##     ## ##        ##  ##    ## 
-- ##     ## ##     ## ##     ## ##        ##  ##       
-- ########  ##     ## ########  ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##       
-- ##        ##     ## ##     ## ##        ##  ##    ## 
-- ##         #######  ########  ######## ####  ######  

function Inst:prepareStartPage (page)
    self.startPage = page
end

--[[ 設置 自動刷新 下次時間 ]]
function Inst:setRefreshAutoNextTime(nextTime_utcTimestamp)
    
    refreshAutoNextTime = nextTime_utcTimestamp
    
    -- 更新 自動刷新 時間
    self:updateRefreshAutoTime()
end

--[[ 設置 手動刷新 下次時間 ]]
function Inst:setRefreshManualNextTime(nextTime_utcTimestamp)
    
    if nextTime_utcTimestamp > 0 then
        refreshManualNextTime = nextTime_utcTimestamp
    else
        refreshManualNextTime = -1
    end
    
    -- 更新 手動刷新 時間
    self:updateRefreshManualTime()
end

--[[ 設置 手動刷新 價格 ]]
function Inst:setRefreshPrice(price, icon)

    -- NodeHelper:setNodesVisible(mContainerRef, {
    --     refreshManualPrice = (price >= 0)
    -- })

    NodeHelper:setSpriteImage(mContainerRef, 
        {
            refreshManualPriceImg = icon
        },
        {
            refreshManualPriceImg = originRefreshPriceScale
        }
    )
    NodeHelper:setStringForLabel(mContainerRef, {
        refreshManualPriceNum = tostring(price)
    })
end

--[[ 設置 手動刷新 狀態 文字 ]]
function Inst:setRefreshManualStatusText(text)
    NodeHelper:setStringForLabel(mContainerRef, {
        refreshManualStatusText = text
    })
end

--[[ 設置 面板內容 ]]
function Inst:requestPanelScrollView(isReload, reloadSetting)
    if isReload == nil then isReload = false end

    -- 若 不需重讀 且 有現成的 則 直接取用
    if not isReload and mPanelScrollView ~= nil then
        return mPanelScrollView
    end
        
    
    mPanelScrollViewNode:removeAllChildren()
    
    if mPanelScrollView ~= nil then
        -- mPanelScrollView.facade:release()
        mPanelScrollView:release()
    end

    mPanelScrollView = ScriptContentBase:create("FairPage_panelScrollView.ccbi")
    mPanelScrollViewNode:addChild(mPanelScrollView)
     
    -- debug
    -- mPanelScrollView:getVarNode("debugCheck"):setVisible(true)
    -- mCommTabStorage.CommTabStorageContainer:setVisible(false)

    local scrollViewRef = mContainerRef:getVarNode("scrollviewRef")

    
    local size = scrollViewRef:getContentSize()
    mPanelScrollView:setContentSize(size)
    mPanelScrollView:getVarNode("debugCheck"):setContentSize(size)
    mPanelScrollView:getVarNode("root"):setContentSize(size)
    mPanelScrollView:getVarScrollView("scrollview"):setViewSize(size)
    mPanelScrollView:getVarNode("scrollview"):setContentSize(size)
    
    -- print("mPanelScrollView:getVarScrollView(\"scrollView\") ~= nil == " .. tostring(mPanelScrollView:getVarScrollView("scrollview") ~= nil))
    NodeHelperUZ:initScrollView(mPanelScrollView, "scrollview", 
        reloadSetting["size"], reloadSetting["boundcedItemFlag"])

    -- debug
    -- print(string.format("mPanel size[%s, %s] ap[%s, %s] pos[%s, %s]", 
    --     mPanelScrollView:getContentSize().width,
    --     mPanelScrollView:getContentSize().height,
    --     mPanelScrollView:getAnchorPoint().x,
    --     mPanelScrollView:getAnchorPoint().y,
    --     mPanelScrollView:getPositionX(),
    --     mPanelScrollView:getPositionY()
    -- ))

    -- print(string.format("root size[%s, %s] ap[%s, %s] pos[%s, %s]", 
    --     mPanelScrollView:getVarNode("root"):getContentSize().width,
    --     mPanelScrollView:getVarNode("root"):getContentSize().height,
    --     mPanelScrollView:getVarNode("root"):getAnchorPoint().x,
    --     mPanelScrollView:getVarNode("root"):getAnchorPoint().y,
    --     mPanelScrollView:getVarNode("root"):getPositionX(),
    --     mPanelScrollView:getVarNode("root"):getPositionY()
    -- ))

    -- print(string.format("scrollview size[%s, %s] ap[%s, %s] pos[%s, %s]", 
    --     mPanelScrollView:getVarNode("scrollview"):getContentSize().width,
    --     mPanelScrollView:getVarNode("scrollview"):getContentSize().height,
    --     mPanelScrollView:getVarNode("scrollview"):getAnchorPoint().x,
    --     mPanelScrollView:getVarNode("scrollview"):getAnchorPoint().y,
    --     mPanelScrollView:getVarNode("scrollview"):getPositionX(),
    --     mPanelScrollView:getVarNode("scrollview"):getPositionY()
    -- ))

    -- mPanelScrollView.facade = CCReViScrollViewFacade:new_local(mPanelScrollView)
    -- mPanelScrollView.facade:init()

    return mPanelScrollView
end


--[[ 刷新頁面 ]]
function Inst:refreshPage(container)
    
    local shopInfo = ShopDataMgr:getSubPageInfo(ShopDataMgr.currentShopType)
    -- dump(shopInfo, "shopInfo of "..tostring(ShopDataMgr.currentShopType))
    if shopInfo == nil then return end
    
    local scriptName = shopInfo._scriptName
    if scriptName and scriptName ~= "" and mSubNode then

        -- 若 舊的子頁面 存在
        if self.subPage then
            -- 呼叫 "當 頁面離開" 並 清空
            self.subPage:onExit(container)
            self.subPage = nil
        end
        -- 移除 舊的 子頁面節點
        mSubNode:removeAllChildren()
        -- mPanelNode:removeAllChildren()

        -- 讀取 子頁面 腳本
        self.subPage = require(scriptName).new()
        -- print("self.subPage create")
        self.subPage:init(shopInfo)
        -- 進入 子頁面 並 回傳 子頁面的UI
        self.subPageContainer = self.subPage:onEnter(container, self)
        -- 加入 子頁面 到 裝子頁面的容器節點
        mSubNode:addChild(self.subPageContainer)

        -- 設置 標題
        mCommTabStorage:setTitle(shopInfo._title)

        self.subPageContainer:setAnchorPoint(ccp(0,0))

        -- 若 子頁面 有 "取得 封包資訊" 可呼叫 則 呼叫
        if self.subPage["getPacketInfo"] then
            self.subPage:getPacketInfo()
        end

        -- 釋放?
        self.subPageContainer:release()
    end
end


--[[ 刷新 貨幣資訊 ]]
function Inst:refreshCurrencyInfo(container)
    -- 同步玩家 資訊
    UserInfo.syncPlayerInfo()

    local UserItemManager = require("Item.UserItemManager")
    
    -- 向 子頁面 要求 貨幣資訊 (類型, 數量)
    local subCurrencyDatas = self.subPage:getCurrencyDatas()

    -- 設置 貨幣資訊
    mCommTabStorage:setCurrencyDatas(subCurrencyDatas,true)

end

function Inst:_getRevertIdx (idx, count) 
    return (count+1) - idx
end

---------------------------------------------------------------------------------

-- 舊有 外部呼叫介面 ------------------------
ShopTypeContainer = {}

--[[ 設置 當前商店 ]]
function ShopTypeContainer_SetSubPageIndex(index)
    local shopType = ShopDataMgr:getShopTypeByIndex(index)
    ShopDataMgr.currentShopType = shopType
end

--[[ Jupm 至 指定序號的子頁面 ]]
function ShopTypeContainer_JupmToSubPageByIndex(index)
    local shopType = ShopDataMgr:getShopTypeByIndex(index)
    
    local subPageInfo = ShopDataMgr:getSubPageInfo(shopType)

    local func = Inst[subPageInfo._clickFun]
    if func ~= nil then
        func(Inst, mContainerRef, index)
    end
end

----------------------------------------------


---------------------------------------------------------------------------------


local CommonPage = require("CommonPage")
Inst = CommonPage.newSub(Inst, thisPageName, option)


return Inst