

--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 聖所
        subPageName = "HolyGrail",

        -- 分頁 相關
        scriptName = "Leader.LeaderSubPage_HolyGrail",
        iconImg_normal = "SubBtn_Sanctuary.png",
        iconImg_selected = "SubBtn_Sanctuary_On.png",
        
        -- 標題
        title = common:getLanguageString("BundleShopTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible = false,

        saveData = nil,
        isRedOn = function() return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.GRAIL_HOLY_TAB) end,
    },
    --{
    --    -- 子頁面名稱 : 成長
    --    subPageName = "SoulStar",
    --
    --    -- 分頁 相關
    --    scriptName = "Leader.LeaderSubPage_SoulStar",
    --    iconImg_normal = "SubBtn_LeaderUpgrade.png",
    --    iconImg_selected = "SubBtn_LeaderUpgrade_On.png",
    --    
    --    -- 標題
    --    title = common:getLanguageString("GrowthPassTitle"),
    --
    --    -- 貨幣資訊 
    --    currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },
    --
    --    -- 其他子頁資訊 ----------
    --    TopisVisible=false,
    --},
    {
        -- 子頁面名稱 : 屬性
        subPageName = "Element",

        -- 分頁 相關
        scriptName = "Leader.LeaderSubPage_Element",
        iconImg_normal = "SubBtn_ElementUpgrade.png",
        iconImg_selected = "SubBtn_ElementUpgrade_On.png",
        
        -- 標題
        title =common:getLanguageString("GrowthPassTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible = false,

        saveData = nil,
        isRedOn = function() return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.GRAIL_ELEMENT_TAB) end,
    },
    {
        -- 子頁面名稱 : 職業/屬性
        subPageName = "Class",

        -- 分頁 相關
        scriptName = "Leader.LeaderSubPage_Class",
        iconImg_normal = "SubBtn_ClassUpgrade.png",
        iconImg_selected = "SubBtn_ClassUpgrade_On.png",
        
        -- 標題
        title =common:getLanguageString("GrowthPassTitle"),

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1001_0" }, { priceStr = "10000_1002_0" } },

        -- 其他子頁資訊 ----------
        TopisVisible = false,

        saveData = nil,
        isRedOn = function() return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.GRAIL_CLASS_TAB) end,
    },
}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg (subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end


return Inst