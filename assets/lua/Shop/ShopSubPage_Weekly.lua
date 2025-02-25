----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local TimeDateUtil = require("Util.TimeDateUtil")

local ShopSubPage_Base = require("Shop.ShopSubPage_Base")

-- 主體
local ShopSubPage_Weekly = {}

-- 建立
function ShopSubPage_Weekly.new()

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

        if self.refreshAutoNextTime and self.refreshAutoNextTime > 0 then
            if clientTime > self.refreshAutoNextTime then

                -- 若 已結束冷卻
                if self.requestCooldownLeft <= 0 then

                    -- 請求 被動刷新
                    --self:requestPassiveRefreshShop()
                    
                    -- 開始冷卻
                    self.requestCooldownLeft = self.requestCooldownFrame
                end
            end
        end
    end

    --[[ 當 接收 子頁面 封包 ]]
    Inst.SubPage_Base.onReceiveSubPagePacket = Inst.onReceiveSubPagePacket
    function Inst:onReceiveSubPagePacket(packetInfo)
        self.SubPage_Base.onReceiveSubPagePacket(self, packetInfo)
        
        -- 更新 自動刷新 下次時間
        self:updateRefreshAutoTime(packetInfo.refreshTime)
    end

    --[[ 模板 ]]
    -- Inst.SubPage_Base.someFunc = Inst.someFunc
    -- function Inst:someFunc(arg1)
    --     self.SubPage_Base.someFunc(self, arg1)

    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 更新 自動刷新 時間 ]]
    function Inst:updateRefreshAutoTime(lastRefreshTime)
        local Event001Page = require "Event001Page"
        local leftTime = Event001Page:getStageInfo().leftTime
        local nextTime

        -- 若 存在 上次刷新時間 則
        if lastRefreshTime ~= nil and lastRefreshTime > 0 then
            
            nextTime = lastRefreshTime + 604800 --[[ 7天 ]]

        -- 否則 以目前時間推算
        else
            -- Client安全時間 (不差Server時間太多)
            local clientSafeTime = TimeDateUtil:getClientSafeTime()

            -- 刷新日期 先設為 本地日期
            local nextDate = TimeDateUtil:utcTime2LocalDate(clientSafeTime)
            
            -- 週首日偏移 (1:週日 2:週一 ...)
            local weekFirstDayOffset = 2

            -- 與下週首日的差距
            local diffToNextWeek = math.fmod(weekFirstDayOffset - nextDate.wday + 7, 7)
            if diffToNextWeek == 0 then diffToNextWeek = 7 end

            -- 調整 刷新日期 為 以UTC+8而言 的 下週首日00h:00m
            nextDate.day = nextDate.day + diffToNextWeek
            nextDate.hour = 0
            nextDate.min = 0
            nextDate.sec = 0
          
            nextTime = TimeDateUtil:utcDate2Time(nextDate)

        end

        -- 設置 自動刷新 下次時間
        self.refreshAutoNextTime = leftTime

        -- 設置 自動刷新 下次時間
        self.controlPage:setRefreshAutoNextTime(leftTime)
    end

    return Inst
end

return ShopSubPage_Weekly
