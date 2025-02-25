
--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 主頁
        subPageName = "MainScene",
        
        -- 分頁 相關
        scriptName = "GloryHole.GloryHoleSubPage_MainScene",
        iconImg_normal = "SubBtn_ Event.png",
        iconImg_selected = "SubBtn_ Event_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,

    },
       {
        -- 子頁面名稱 : 主頁
        subPageName = "Team",
        
        -- 分頁 相關
        scriptName = "GloryHole.GloryHoleSubPage_TeamRank",
        iconImg_normal = "SubBtn_EvTeamRank.png",
        iconImg_selected = "SubBtn_EvTeamRank_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,

        activityID = 175
    },
    {
        -- 子頁面名稱 : 主頁
        subPageName = "Daily",
        
        -- 分頁 相關
        scriptName = "GloryHole.GloryHoleSubPage_DailyRank",
        iconImg_normal = "SubBtn_EvMyRank.png",
        iconImg_selected = "SubBtn_EvMyRank_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,

        activityID = 175
    },
    {
        isClose = true,
        -- 子頁面名稱 : 主頁
        subPageName = "History",
        
        -- 分頁 相關
        scriptName = "GloryHole.GloryHoleSubPage_HistoryRank",
        iconImg_normal = "SubBtn_EvMyRank.png",
        iconImg_selected = "SubBtn_EvMyRank_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,

        activityID = 175
    },
    

}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg(subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end


return Inst
