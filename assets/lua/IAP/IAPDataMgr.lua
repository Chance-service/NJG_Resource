
--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 累儲
        subPageName = "RechargeBonus",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_RechargeBonus",
        iconImg_normal = "SubBtn_RechargeBounce.png",
        iconImg_selected = "SubBtn_RechargeBounce_On.png",
        
        -- 標題
        title = "@RechargeBounce_title",
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE,
    
        activityID = 192
    },
    {
        -- 子頁面名稱 : 禮包
        subPageName = "Recharge",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_Recharge",
        iconImg_normal = "SubBtn_DailyBundle.png",
        iconImg_selected = "SubBtn_DailyBundle_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE,

        isRedOn = function() return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.PACKAGE_GOODS_TAB) end,
    },
        {
        -- 子頁面名稱 : 特權
        subPageName = "StepBundle",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_StepBundle",
        iconImg_normal = "SubBtn_StepBundle.png",
        iconImg_selected = "SubBtn_StepBundle_On.png",
        
        -- 標題
        title = "@PLAYER_179",
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        -- 活動ID
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.STEPBUNDLE,

        activityID = 179
    },
    {
        -- 子頁面名稱 : 成長
        subPageName = "GrowFund",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_GrowthFund",
        iconImg_normal = "SubBtn_Growpass.png",
        iconImg_selected = "SubBtn_Growpass_On.png",
        
        -- 標題
        title = common:getLanguageString("@GrowthPassTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.GROWTH_BUNDLE,
    },
    
    {
        -- 子頁面名稱 : 月卡
        subPageName = "MonthCard",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_MonthlyCard",
        iconImg_normal = "SubBtn_MonthCard.png",
        iconImg_selected = "SubBtn_MonthCard_On.png",
        
        -- 標題
        title = common:getLanguageString("@MonthCardInfoTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        -- 活動ID
        activityID = 155,
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.MONTHLY_CARD,
    },
    {
        -- 子頁面名稱 : 特權
        subPageName = "Subscription",
        
        -- 分頁 相關
        scriptName = "IAP.IAPSubPage_Subscription",
        iconImg_normal = "SubBtn_Privilege.png",
        iconImg_selected = "SubBtn_Privilege_On.png",
        
        -- 標題
        title = "@SubscrupTitle",
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = true,
        -- 活動ID
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SUBSCIPTON,
    },
    {

        subPageName="Diamond",
        -- Diamond
        scriptName = "IAP.IAPSubPage_Diamond",
        -- 圖標
        iconImg_normal = "SubBtn_Diamond.png",
        iconImg_selected = "SubBtn_Diamond_On.png",

         title = "@DimondShopTitle",

        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
    },
    --{
    --    -- 子頁面名稱 : Calendar
    --    subPageName = "Calendar",
    --    
    --    -- 分頁 相關
    --    scriptName = "IAP.IAPSubPage_Calendar",
    --    iconImg_normal = "SubBtn_Calendar.png",
    --    iconImg_selected = "SubBtn_Calendar_On.png",
    --    
    --    -- 標題
    --    title = "@SupperCalander",
    --    
    --    -- 貨幣資訊
    --    currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
    --    
    --    -- 其他子頁資訊 ----------
    --    TopisVisible = true,
    --    
    --    -- 活動ID
    --    activityID = 155,
    --    LOCK_KEY = GameConfig.LOCK_PAGE_KEY.CALENDAR,
    --},


}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg(subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end


return Inst
