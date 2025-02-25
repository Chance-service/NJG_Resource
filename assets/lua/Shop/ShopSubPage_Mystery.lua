----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local Async = require("Util.Async")
local TimeDateUtil = require("Util.TimeDateUtil")
local InfoAccesser = require("Util.InfoAccesser")
local ShopDataMgr = require("Shop.ShopDataMgr")

local ShopSubPage_Base = require("Shop.ShopSubPage_Base")

--[[ 主體 ]]
local ShopSubPage_Mestrey = {}


--[[ 免費刷新 最大次數 ]]
local MAX_FREE_REFRESH_MANUAL = 1

--[[ 付費刷新 最大次數 ]]
local MAX_COST_REFRESH_MANUAL = 100

--[[ 建立 ]]
function ShopSubPage_Mestrey.new()

    -- 繼承自 基礎頁面
    Inst = ShopSubPage_Base.new()

    -- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
    -- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
    -- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
    -- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
    --  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
    --   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
    --    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 

    -- 手動 紀錄 原腳本 相關
    Inst.SubPage_Base = {}

    -- overwrite ----

    -- new ----------

    -- 自動刷新 下次時間
    Inst.refreshAutoNextTime = -1

    -- 手動刷新 免費次數
    Inst.refreshManualFreeQuota = 0
    -- 手動刷新 付費次數
    Inst.refreshManualCostQuota = 0
    -- 手動刷新 下次補充時間
    Inst.refreshManualNextChargeTime = -1
    -- 手動刷新 付費價格
    Inst.refreshManualPrice = -1

    -- 請求 冷卻時間 (幀)
    Inst.requestCooldownFrame = 180
    Inst.requestCooldownLeft = Inst.requestCooldownFrame

    Inst.lastCostRefreshQuota = nil

    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 

    --[[ 初始化 ]]
    -- Inst.SubPage_Base.init = Inst.init
    -- function Inst:init(shopInfo)
    --     Inst.SubPage_Base.init(self, shopInfo)
    -- end

    --[[ 當 進入頁面 ]]
    Inst.SubPage_Base.onEnter = Inst.onEnter
    function Inst:onEnter(parentContainer, controlPage)
        
        self.SubPage_Base.onEnter(self, parentContainer, controlPage)

        -- 更新 刷新時間
        self:updateRefreshAutoTime()

        -- 設值 手動刷新UI 顯示
        self.controlPage.isRefreshManualShowVals:set(true, self, 0)
        -- 設值 自動刷新UI 隱藏
        self.controlPage.isRefreshAutoShowVals:set(false, self, 0)

        --self.controlPage:setRefreshManualStatusText(common:getLanguageString("@Shop.Syncing"))

        return self.container
    end

    --[[ 當 離開頁面 ]]
    Inst.SubPage_Base.onExit = Inst.onExit
    function Inst:onExit(parentContainer)

        -- 取消設值 手動刷新UI
        self.controlPage.isRefreshManualShowVals:set(nil, self)
        -- 取消設值 自動刷新UI
        self.controlPage.isRefreshAutoShowVals:set(nil, self)

        self.SubPage_Base.onExit(self, parentContainer)

        return self.container
    end

    --[[ 當 每幀 ]]
    Inst.SubPage_Base.onExecute = Inst.onExecute
    function Inst:onExecute(parentContainer)
        self.SubPage_Base.onExecute(self, parentContainer)

        local clientTime = os.time()

        local isNeedPassiveRefreshShop = false

        -- 若 自動刷新 下次時間 存在
        if self.refreshAutoNextTime > 0 then
            -- 若 當前時間 超過 自動刷新 下次時間
            if clientTime > self.refreshAutoNextTime then
                -- 需要請求新資料
                isNeedPassiveRefreshShop = true
                print("NEED REFRESH AUTO")
            end
        end

        -- 若 手動刷新 下次充填 時間 存在
        if self.refreshManualNextChargeTime > 0 then
            -- 若 當前時間 超過 下次充填時間
            if clientTime > self.refreshManualNextChargeTime then
                -- 需要請求新資料
                isNeedPassiveRefreshShop = true
                print("NEED REFRESH MANUAL CHARGE")
            end
        end

        if self.requestCooldownLeft > 0 then
            self.requestCooldownLeft = self.requestCooldownLeft - 1
        end

        if isNeedPassiveRefreshShop then
            if self.requestCooldownLeft <= 0 then
                
                self.requestCooldownLeft = self.requestCooldownFrame

                self:requestPassiveRefreshShop()
            end
            
        end

    end

    --[[ 當 手動刷新 按下 ]]
    function Inst:onManualRefreshBtn(parentContainer)

        local refreshType

        -- 檢查 或 確認 使用 付費或免費 手動刷新
        if self.refreshManualFreeQuota > 0 then
            refreshType = 0
        elseif self.refreshManualCostQuota > 0 then
            
            -- 檢查 貨幣是否足以付費
            
            UserInfo.syncPlayerInfo()

            -- 若 不足
            if UserInfo.playerInfo.gold < self.refreshManualPrice then
                -- TODO 顯示 貨幣不足
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_30001"))
                return
            end

            refreshType = 1
        
        -- 若 無可用次數
        else
            -- TODO 顯示 無可用次數
            return
        end

        
        if refreshType == nil then
            return
        end

        Async:waterfall({
            -- 確認
            function (nxt)
                if refreshType ~= 1 then nxt() return end

                -- TODO 確認視窗

                nxt()
            end,
            function (nxt)
                self:requestManualRefreshShop(refreshType)
            end,
        })

    end

    --[[ 當 接收 子頁面 封包 ]]
    function Inst:onReceiveSubPagePacket(packetInfo)

        -- dump(packetInfo, "Mystery packetInfo ")
        
        local shopInfo = ShopDataMgr:getSubPageInfo(self.shopType)

        self.refreshManualFreeQuota = packetInfo.freeRefresh
        self.refreshManualCostQuota = packetInfo.costRefresh
        self.refreshManualPrice = packetInfo.refreshPrice
        self.refreshManualNextChargeTime = packetInfo.refreshTime
        if packetInfo.refreshTime > 0 then
            self.refreshManualNextChargeTime = packetInfo.refreshTime + 86400 
        end
        -- 是否 自動刷新(付費刷新次數) 已更新
        local isRefreshAutoUpdated = true

        -- 若 前次 付費刷新 次數 存在 且 已經小於 最大付費刷新次數
        if self.lastCostRefreshQuota ~= nil and self.lastCostRefreshQuota < MAX_COST_REFRESH_MANUAL then
            -- 若 當前收到的付費刷新次數 仍等於少於 前次 付費刷新次數
            if packetInfo.costRefresh <= self.lastCostRefreshQuota then
                -- 代表 還沒成功更新 
                isRefreshAutoUpdated = false
            end
        end
        
        -- 若 已更新
        if isRefreshAutoUpdated then
            -- 更新 前次付費刷新次數
            self.lastCostRefreshQuota = packetInfo.costRefresh
            -- 對應更新 下次自動刷新時間
            self:updateRefreshAutoTime()
        end
        

        -- 設置 手動刷新 價格標示
        local icon = nil
        local price = -1
        if shopInfo.refreshCurrency then
            icon = InfoAccesser:getItemInfoByStr(shopInfo.refreshCurrency).icon
            if packetInfo.freeRefresh > 0 then
                price = 0
            else
                price = packetInfo.refreshPrice
            end
        end
        self.controlPage:setRefreshPrice(price, icon)

        -- 設置 手動刷新 狀況 文字
        local statusStr
        -- 若 下期時間 存在
        if self.refreshManualNextChargeTime > 0 then
            -- 若 當前時間 已超過 下期時間 則 暫時改為 同步中
            if os.time() > self.refreshManualNextChargeTime then
                --statusStr = common:getLanguageString("@Shop.Syncing")
            end
        end

        -- 若 尚未更新成功 自動刷新
        if not isRefreshAutoUpdated then
            --statusStr = common:getLanguageString("@Shop.Syncing")
        end

        -- 若 沒有狀況 則 顯示次數相關
        if statusStr == nil then
            if self.refreshManualFreeQuota > 0 then
                statusStr = common:getLanguageString("@Shop.RefreshManual.FreeTimes", self.refreshManualFreeQuota, MAX_FREE_REFRESH_MANUAL)
                -- statusStr = string.format("Free Times : %d/%d", self.refreshManualFreeQuota, 5)
            else 
                statusStr = common:getLanguageString("@Shop.RefreshManual.CostTimes", self.refreshManualCostQuota, MAX_COST_REFRESH_MANUAL)
                -- statusStr = string.format("Refresh Times : %d/%d", self.refreshManualCostQuota, 100)
            end
        end

        self.controlPage:setRefreshManualStatusText(statusStr)



        -- 設置 手動刷新 倒數
        self.controlPage:setRefreshManualNextTime(self.refreshManualNextChargeTime)

        -- 刷新紅點設定
        local pageIds = {
            RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN, RedPointManager.PAGE_IDS.MYSTERY_FREE_BTN
        }
        for k, pageId in pairs(pageIds) do
            local RedPointCfg = ConfigManager.getRedPointSetting()
            local groupNum = RedPointCfg[pageId].groupNum
            for i = 1, groupNum do
                RedPointManager_refreshPageShowPoint(pageId, i, packetInfo)
            end
        end
        self:refreshAllPoint(container)
    end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 更新 自動刷新 時間 ]]
    function Inst:updateRefreshAutoTime()
        print("[ShopSubPage_Mystery] : updateRefreshAutoTime")
        local nextTime

        -- print("[ShopSubPage_Mystery] : lastRefreshTime : "..tostring(lastRefreshTime))
        -- 若 存在 上次刷新時間 則
        -- if lastRefreshTime ~= nil and lastRefreshTime > 0 then
            
        --     nextTime = lastRefreshTime + 86400 --[[ 1天 ]]

        -- 否則 以目前時間推算
        -- else

            -- Client安全時間 (不差Server時間太多)
            local clientSafeTime = TimeDateUtil:getClientSafeTime()

            -- 刷新日期 先設為 本地日期
            local nextDate = TimeDateUtil:utcTime2LocalDate(clientSafeTime)
            
            -- 調整 刷新日期 為 以UTC+8而言 的 明天00h:00m
            nextDate.day = nextDate.day + 1
            nextDate.hour = 0
            nextDate.min = 0
            nextDate.sec = 0
            -- 調整 刷新日期 校正回UTC+0
            nextDate.hour = nextDate.hour - 8

            nextTime = TimeDateUtil:utcDate2Time(nextDate)

        -- end

        -- 設置 自動刷新 下次時間
        self.refreshAutoNextTime = nextTime
        print("[ShopSubPage_Mystery] : set refreshAutoNextTime : "..tostring(nextTime))

        -- 設置 自動刷新 下次時間
        self.controlPage:setRefreshAutoNextTime(nextTime)
    end

    function Inst:refreshAllPoint(container)
        NodeHelper:setNodesVisible(container, { mExpressRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.MYSTERY_FREE_BTN) })
        NodeHelper:setNodesVisible(container, { mExpressRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN) })
    end

    return Inst
end

function ShopSubPage_Mestrey_calIsShowRedPoint(pageId, msgBuff)
    local msg = Shop_pb.ShopItemInfoResponse()
    msg:ParseFromString(msgBuff)
    if pageId == RedPointManager.PAGE_IDS.MYSTERY_REFRESH_BTN then
        return (msg.freeRefresh > 0)
    elseif pageId == RedPointManager.PAGE_IDS.MYSTERY_FREE_BTN then
        return false
    end
    return false
end

return ShopSubPage_Mestrey
