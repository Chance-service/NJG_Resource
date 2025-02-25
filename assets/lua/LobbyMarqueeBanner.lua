----------------------------------------------------------------------------------
--[[
    name: 大廳 跑馬燈橫幅
    desc: 
    author: youzi
    description:
        
--]]
----------------------------------------------------------------------------------

--  ######   #######  ##    ##  ######  ######## 
-- ##    ## ##     ## ###   ## ##    ##    ##    
-- ##       ##     ## ####  ## ##          ##    
-- ##       ##     ## ## ## ##  ######     ##    
-- ##       ##     ## ##  ####       ##    ##    
-- ##    ## ##     ## ##   ### ##    ##    ##    
--  ######   #######  ##    ##  ######     ##    

require("Util.LockManager")
local BANNER_WIDTH = 680


local Activity2BannerSetting = {
    -- 146 : 召喚招募 > 一般召喚
    [Const_pb.ACTIVITY146_CHOSEN_ONE] = {
        getEndTime = function () 
            -- 常駐
            return nil
        end,
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON))
            else
                require("Summon.SummonPage"):setEntrySubPage(1)
                PageManager.pushPage("Summon.SummonPage")
            end
        end,
    },

    -- 161 : 水晶商城 > 超值補給
    [Const_pb.ACTIVITY161_SUPPORT_CALENDER] = {
        getEndTime = function ()
            
        end,
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.CALENDAR) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.CALENDAR))
            else
                require("IAP.IAPPage"):setEntrySubPage("Calendar")
                PageManager.pushPage("IAP.IAPPage")
            end
        end,
    },

    -- 162 : 水晶商城 > 成長
    [Const_pb.ACTIVITY163_GROWTH_CH] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.GROWTH_BUNDLE) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.GROWTH_BUNDLE))
            else
                require("IAP.IAPPage"):setEntrySubPage("GrowFund")
                PageManager.pushPage("IAP.IAPPage")
            end
        end,
    },
   
    -- 159 : 每日返利
    [159] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_RECHARGE) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.DAILY_RECHARGE))
            else
                PageManager.pushPage("DailyBundlePage")
            end
        end,
    },
    -- 160 : 首儲
    [160] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.FIRST_RECHARGE) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.FIRST_RECHARGE))
            else
                local MainScenePage=require("MainScenePage")
                MainScenePage.onJumpFirstRecharge()
            end
        end,
    },
    -- 179 : 階段
    [179] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.STEPBUNDLE) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.STEPBUNDLE))
            else 
                local StepBundle =  require ("IAP.IAPSubPage_StepBundle")
                if StepBundle:isBuyAll() then
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_10000"))
                    return
                end
                require("IAP.IAPPage"):setEntrySubPage("StepBundle")
                PageManager.pushPage("IAP.IAPPage")
            end
        end,
    },
    -- 999 : 水晶商城 > 月卡
    [999] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.MONTHLY_CARD) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.MONTHLY_CARD))
            else
                require("IAP.IAPPage"):setEntrySubPage("MonthCard")
                PageManager.pushPage("IAP.IAPPage")
            end
        end,
    },
     [147] = {
        onEnter = function ()
            if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.WISHING_WELL) then
                MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.WISHING_WELL))
            else
                PageManager.pushPage("WishingWell.WishingWellPage")
            end
        end,
    },
     [172] = {
        onEnter = function ()
           MainFrame_onBackpackPageBtn("PickUp")
        end,
    },
    [173] = {
        onEnter = function ()
            MainFrame_onBackpackPageBtn("PickUp2")
        end,
    },
    [197] = {
        onEnter = function (_page)
             if type(_page) == "string" then
                require("Summon.SummonPage"):setEntrySubPage(_page)
             end
             MainFrame_onBackpackPageBtn()
        end,
    },
}


-- ##     ##    ###    ########  ####    ###    ########  ##       ######## 
-- ##     ##   ## ##   ##     ##  ##    ## ##   ##     ## ##       ##       
-- ##     ##  ##   ##  ##     ##  ##   ##   ##  ##     ## ##       ##       
-- ##     ## ##     ## ########   ##  ##     ## ########  ##       ######   
--  ##   ##  ######### ##   ##    ##  ######### ##     ## ##       ##       
--   ## ##   ##     ## ##    ##   ##  ##     ## ##     ## ##       ##       
--    ###    ##     ## ##     ## #### ##     ## ########  ######## ######## 


-- 模塊工具
local CommMarqueeBanner = require("CommComp.CommMarqueeBanner")
local NodeHelper = require("NodeHelper")
local TimeDateUtil = require("Util.TimeDateUtil")
require("Activity.ActivityInfo")

-- 主體
local LobbyMarqueeBanner = {}
local LobbyMarqueeBannerContent = {}

function LobbyMarqueeBanner:new ()
    local Inst = {}

    Inst._isInited = false

    Inst.commMarqueeBanner = nil

    -- #### ##    ## ######## ######## ########  ########    ###     ######  ######## 
    --  ##  ###   ##    ##    ##       ##     ## ##         ## ##   ##    ## ##       
    --  ##  ####  ##    ##    ##       ##     ## ##        ##   ##  ##       ##       
    --  ##  ## ## ##    ##    ######   ########  ######   ##     ## ##       ######   
    --  ##  ##  ####    ##    ##       ##   ##   ##       ######### ##       ##       
    --  ##  ##   ###    ##    ##       ##    ##  ##       ##     ## ##    ## ##       
    -- #### ##    ##    ##    ######## ##     ## ##       ##     ##  ######  ######## 


    -- ########  ##     ## ########  ##       ####  ######  
    -- ##     ## ##     ## ##     ## ##        ##  ##    ## 
    -- ##     ## ##     ## ##     ## ##        ##  ##       
    -- ########  ##     ## ########  ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##       
    -- ##        ##     ## ##     ## ##        ##  ##    ## 
    -- ##         #######  ########  ######## ####  ######  

    --[[ 初始化 ]]
    function Inst:init (data) 
        if self._isInited then return self end

        local slf = self

        local bannerCfgs = ConfigManager:getBannerCfg()
        local cfg={}
        for k,v in pairs (bannerCfgs) do
            if v.group==0 then
                table.insert(cfg,v)
            end
        end
        self.commMarqueeBanner = CommMarqueeBanner:new():init({
            contentScript = LobbyMarqueeBannerContent,
            objPoolSize = #cfg*2,
            displayCount = #cfg*2,
        })

        self:updateBanners()

        -- 註冊當事件更新時
        ActivityInfo.onUpdate:on(function (ctrlr)
            slf:updateBanners()
        end)
        
        self._isInited = true

        return self
    end

    function Inst:updateBanners()
    
        local bannerInfos = {}
        
        local bannerCfgs = ConfigManager:getBannerCfg()
        for idx, cfg in ipairs(bannerCfgs) do while true do
            -- 若 沒有開啟 則 忽略
           local isOpen = (cfg.startTime and os.time() >= cfg.startTime and os.time() <= cfg.endTime) or (cfg.endTime and cfg.endTime == 0)
           if cfg.activityId  == 159 then
                local DailyBundleData = require ("Activity.DailyBundleData")
                if DailyBundleData:isGetAll() then isOpen =false end
           elseif cfg.activityId == 179 then
                local StepBundle =  require ("IAP.IAPSubPage_StepBundle")
                if StepBundle:isBuyAll() then isOpen =false end
           --待新增
           end
           if cfg.group == 0 and isOpen then
               local bannerInfo = {}
               local bannerSetting = Activity2BannerSetting[cfg.activityId]
               if bannerSetting == nil then break end -- continue
               
               bannerInfo.pos = #bannerInfos * BANNER_WIDTH
               bannerInfo.bg = cfg.Image .. ".png"

               if cfg.activityId == 197 then
                    bannerInfo.PageName = "PickUp"..cfg.Page
               end
               
               local endTime
               if bannerSetting.getEndTime ~= nil then
                   endTime = bannerSetting.getEndTime()
               end
               if endTime ~= nil then
                   bannerInfo.counter = {
                       endTime = endTime,
                       offset = bannerSetting.counterOffset,
                   }
               end
               bannerInfo.onEnter = bannerSetting.onEnter
               bannerInfos[#bannerInfos + 1] = bannerInfo
           end
           break
        end
    end
    
        self.commMarqueeBanner:setBannerInfos(bannerInfos, #bannerInfos * BANNER_WIDTH)
    end

    --[[ 取得 UI ]]
    function Inst:getContainer ()
        return self.commMarqueeBanner.container
    end

    --[[ 離開 ]]
    function Inst:exit () 
        if self.commMarqueeBanner then
            self.commMarqueeBanner:clear()
        end
    end

    return Inst
end


---------------------------------------------------------------------------------


function LobbyMarqueeBannerContent:new ()
    local inst = {}

    inst.container = nil

    inst.counterEndTime = nil
    
    inst.timeNode = nil

    --[[ 初始化 ]]
    function inst:init () 
        self.container = ScriptContentBase:create("CommMarqueeBannerContent.ccbi")
        self.timeNode = self.container:getVarNode("timeNode")
        return self
    end

    --[[ 每幀更新 ]]
    function inst:execute (dt)
        if self.counterEndTime == nil then return end
        local leftTime = self.counterEndTime - os.time()
        local date = TimeDateUtil:utcTime2Date(leftTime)
        date.day = date.day - 1
        local str = string.format("%02dD:%02dH:%02dM", date.day, date.hour, date.min)
        NodeHelper:setStringForLabel(self.container, {
            timeTxt = str
        })
    end

    --[[ 取得 UI ]]
    function inst:getContainer ()
        return self.container
    end

    --[[ 設置 資料 ]]
    function inst:setData (data)
        if data == nil then data = {} end
        
        self:setCounter(data.counter)

        local node2Img = {}

        if data.bg ~= nil then
            node2Img.bgImg = data.bg
        else
            node2Img.bgImg = "Image_Empty.png"
        end

        NodeHelper:setSpriteImage(self.container, node2Img)
    end

    --[[ 設置 倒數計時 ]]
    function inst:setCounter (counterData)
        
        local isShow = true

        if counterData == nil then

            isShow = false

        else
            
            if counterData.endTime ~= nil then
                self.counterEndTime = counterData.endTime
            end

            if counterData.offset ~= nil then
                self.timeNode:setPosition(ccp(counterData.offset.x, counterData.offset.y))
            end
        end

        if self.counterEndTime == nil then
            isShow = false
        end
        
        self.timeNode:setVisible(isShow)
    end

    return inst
end

return LobbyMarqueeBanner