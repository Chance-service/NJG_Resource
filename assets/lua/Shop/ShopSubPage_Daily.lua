----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local TimeDateUtil = require("Util.TimeDateUtil")

local ShopSubPage_Base = require("Shop.ShopSubPage_Base")

-- 主體
local ShopSubPage_Daily = {}

-- 建立
function ShopSubPage_Daily.new()

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
    
    -- 請求 冷卻時間 (幀)
    Inst.requestCooldownFrame = 60
    Inst.requestCooldownLeft = Inst.requestCooldownFrame

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

        -- 設值 自動刷新UI 顯示
        self.controlPage.isRefreshAutoShowVals:set(true, self, 0)

        return self.container
    end

    --[[ 當 離開頁面 ]]
    Inst.SubPage_Base.onExit = Inst.onExit
    function Inst:onExit(parentContainer)

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

        -- 若 仍在冷卻 則 冷卻
        if self.requestCooldownLeft > 0 then
            self.requestCooldownLeft = self.requestCooldownLeft - 1
        end

        if self.refreshAutoNextTime ~= -1 then
            -- print(string.format("clientTime:%s > self.refreshAutoNextTime:%s ?", os.date("%X", clientTime), os.date("%X", self.refreshAutoNextTime)))
            if clientTime > self.refreshAutoNextTime then
                -- 若 已結束冷卻
                if self.requestCooldownLeft <= 0 then
                    -- 開始冷卻
                    self.requestCooldownLeft = self.requestCooldownFrame
                    -- print("requestPassiveRefreshShop")
                    -- 請求 被動刷新
                    self:requestPassiveRefreshShop()
                    
                end
            end
        end
    end

    
    --[[ 當 接收 子頁面 封包 ]]
    Inst.SubPage_Base.onReceiveSubPagePacket = Inst.onReceiveSubPagePacket
    function Inst:onReceiveSubPagePacket(packetInfo)
        self.SubPage_Base.onReceiveSubPagePacket(self, packetInfo)
        print("Daily refreshTime : "..tostring(packetInfo.refreshTime))
        print(os.date(packetInfo.refreshTime))
        -- 更新 自動刷新 下次時間
        self:updateRefreshAutoTime(packetInfo.refreshTime)
    end

    --[[ 模板 ]]
    -- Inst.SubPage_Base.someFunc = Inst.someFunc
    -- function Inst:someFunc(arg1)
    --     self.SubPage_Base.someFunc(self, arg1)

    -- end

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 更新 自動刷新 時間 ]]
    function Inst:updateRefreshAutoTime(lastRefreshTime)

        local nextTime

        -- 若 存在 上次刷新時間 則
        if lastRefreshTime ~= nil and lastRefreshTime > 0 then
            
            nextTime = lastRefreshTime + 86400 --[[ 1天 ]]

        -- 否則 以目前時間推算
        else
            -- Client安全時間 (不差Server時間太多)
            local clientSafeTime = TimeDateUtil:getClientSafeTime()

            -- 刷新日期 先設為 本地日期
            local nextDate = TimeDateUtil:utcTime2LocalDate(clientSafeTime)
            
            -- 調整 刷新日期 為 以UTC+8而言 的 明天00h:00m
            nextDate.day = nextDate.day + 1
            nextDate.hour = 0
            -- nextDate.min = nextDate.min + 1 -- test
            nextDate.min = 0
            nextDate.sec = 0
            -- 調整 刷新日期 校正回UTC+0
            nextDate.hour = nextDate.hour - 8

            nextTime = TimeDateUtil:utcDate2Time(nextDate)

        end

        -- 設置 自動刷新 下次時間
        self.refreshAutoNextTime = nextTime
        print("set self.refreshAutoNextTime to "..os.date("%X", nextTime))

        -- 設置 自動刷新 下次時間
        self.controlPage:setRefreshAutoNextTime(nextTime - os.time())
    end

    return Inst
end

return ShopSubPage_Daily
