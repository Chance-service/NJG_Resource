
--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 禮包
        subPageName = "Recharge",
        
        -- 分頁 相關
        scriptName = "Dungeon.DungeonSubPage_Event",
        iconImg_normal = "SubBtn_DailyBundle.png",
        iconImg_selected = "SubBtn_DailyBundle_On.png",
        
        -- 標題
        title = common:getLanguageString("@BundleShopTitle"),
        
        -- 貨幣資訊
        currencyInfos = {{priceStr = "10000_1002_0"}, {priceStr = "10000_1001_0"}},
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,
        isHide = true,  -- 關閉按鈕顯示
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
