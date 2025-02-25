
local WishingWellDataMgr = {}

--[[ 許願輪頁面 子頁面資訊 ]]
WishingWellDataMgr.SubPageCfgs = {
    --{
    --    -- 子頁面名稱 : 許願3
    --    subPageName = "Wish3",
    --    
    --    -- 分頁 相關
    --    scriptName = "WishingWell.WishingWellSubPage_Base",
    --    iconImg_normal = "SubBtn_wish_3.png",
    --    iconImg_selected = "SubBtn_wish_3_On.png",
    --    
    --    -- 標題
    --    title = "@WishingWell.title",
    --
    --    -- 貨幣資訊 
    --    currencyInfos = {
    --        { priceStr = "30000_6007_0" },
    --    },
    --    
    --    -- 輪類型
    --    type = 3,
    --
    --
    --    -- 背景動畫Spine 路徑 與 檔名 與 動畫名稱
    --    bgSpine = {"Spine/NGUI", "NGUI_74_WishWheelidle", "animation2"},
    --    -- 抽取動畫Spine 路徑 與 檔名
    --    gachaSpine = {"Spine/NGUI", "NGUI_73_WishWheel3"},
    --
    --    -- 刷新價格
    --    refreshPriceStr = "10000_1001_30",
    --    -- 單抽價格
    --    summonPriceStr = "30000_6007_1",
    --
    --    -- 免費抽次數
    --    refreshFreeQuota = 3,
    --
    --    -- 免費刷新 冷卻 (<0:關閉)
    --    refreshFreeCooldown_sec = 10800,
    --
    --    -- 物品列序號:泡泡稀有度樣式 (1:已抽/關閉, 2~4:樣式) ]]
    --    itemIdx2bubbleRare = {4, 3, 3, 3, 2, 2, 2, 2},
    --    -- 進度條 標註
    --    progressDesc = "ProgressTest",
    --    --Help內容
    --    Help="HELP_WISHINGWHELL",
    --    
    --    summonBgm = "wishing_well_gacha.mp3",
    --},
    --{
    --    -- 子頁面名稱 : 許願2
    --    subPageName = "Wish2",
    --    
    --    -- 分頁 相關
    --    scriptName = "WishingWell.WishingWellSubPage_Base",
    --    iconImg_normal = "SubBtn_wish_2.png",
    --    iconImg_selected = "SubBtn_wish_2_On.png",
    --    
    --    -- 標題
    --    title = "@WishingWell.title",
    --
    --    -- 貨幣資訊 
    --    currencyInfos = {
    --        { priceStr = "30000_6006_0" },
    --    },
    --
    --    -- 輪類型
    --    type = 2,
    --
    --
    --    -- 背景動畫Spine 路徑 與 檔名 與 動畫名稱
    --    bgSpine = {"Spine/NGUI", "NGUI_74_WishWheelidle", "animation1"},
    --    -- 抽取動畫Spine 路徑 與 檔名
    --    gachaSpine = {"Spine/NGUI", "NGUI_72_WishWheel2"},
    --
    --    -- 刷新價格
    --    refreshPriceStr = "10000_1001_30",
    --    -- 單抽價格
    --    summonPriceStr = "30000_6006_1",
    --
    --    -- 免費抽次數
    --    refreshFreeQuota = 0,
    --
    --    -- 免費刷新 冷卻 (<0:關閉)
    --    refreshFreeCooldown_sec = 10800,
    --
    --    -- 物品列序號:泡泡稀有度樣式 (1:已抽/關閉, 2~4:樣式) ]]
    --    itemIdx2bubbleRare = {4, 3, 3, 3, 2, 2, 2, 2},
    --    -- 進度條 標註
    --    progressDesc = "ProgressTest",
    --    --Help內容
    --    Help="HELP_WISHINGWHELL",
    --
    --    summonBgm = "wishing_well_gacha.mp3",
    --},
    {
        -- 子頁面名稱 : 許願1
        subPageName = "Wish1",
        
        -- 分頁 相關
        scriptName = "WishingWell.WishingWellSubPage_Base",
        iconImg_normal = "SubBtn_wish_1.png",
        iconImg_selected = "SubBtn_wish_1_On.png",
        
        -- 標題
        title = "@WishingWell.title",
    
        -- 貨幣資訊 
        currencyInfos = {
            { priceStr = "30000_6005_0" },
        },
    
        -- 輪類型
        type = 1,
    
    
        -- 背景動畫Spine 路徑 與 檔名 與 動畫名稱
        bgSpine = {"Spine/NGUI", "NGUI_74_WishWheelidle", "animation3"},
        -- 抽取動畫Spine 路徑 與 檔名
        gachaSpine = {"Spine/NGUI", "NGUI_71_WishWheel1"},
    
        -- 刷新價格
        refreshPriceStr = "10000_1001_30",
        -- 單抽價格
        summonPriceStr = "30000_6005_1",
    
        -- 免費抽次數
        refreshFreeQuota = 0,
    
        -- 免費刷新 冷卻 (<0:關閉)
        refreshFreeCooldown_sec = 10800,
    
        -- 物品列序號:泡泡稀有度樣式 (1:已抽/關閉, 2~4:樣式) ]]
        itemIdx2bubbleRare = {4, 3, 3, 3, 2, 2, 2, 2},
        -- 進度條 標註
        progressDesc = "ProgressTest",
    
        --Help內容
        Help="HELP_WISHINGWHELL",
    
        summonBgm = "wishing_well_gacha.mp3",
        -- 關閉道具+號按鈕
        _closePlusBtn = true,
    },
}

--[[ 許願輪頁面 子頁面 配置 ]]
function WishingWellDataMgr:getSubPageCfg (subPageNameOrType)
    for idx, cfg in ipairs(WishingWellDataMgr.SubPageCfgs) do
        if cfg.subPageName == subPageNameOrType then return cfg end
        if cfg.type == subPageNameOrType then return cfg end
    end
    return nil
end

--[[ 取得 里程相關資訊 ]]
function WishingWellDataMgr:getProgressInfo (subPageType)
    local subPageCfg = self:getSubPageCfg(subPageType)

    -- 許願輪 配置
    local wishingWellMilestoneCfg = nil
    local wishingWellMilestoneCfgs = ConfigManager.getWishingWellMilestoneCfg()
    -- 從中找尋符合類型的 配置
    for id, cfg in pairs(wishingWellMilestoneCfgs) do
        if id == subPageType then
            wishingWellMilestoneCfg = cfg
            break
        end
    end

    -- 進度資訊
    local info = {
        -- 進度描述
        progressDesc = subPageCfg.progressDesc,
        -- 進度最大值
        progressMax = wishingWellMilestoneCfg.points[#wishingWellMilestoneCfg.points],
    }


    -- 獎勵列表
    local rewards = {}
    -- 取得 最少的數量
    local rewardCount = #wishingWellMilestoneCfg.reward
    local pointCount = #wishingWellMilestoneCfg.points
    
    local count = rewardCount
    if pointCount < count then count = pointCount end

    -- 在數量內
    for idx = 1, count do
        -- 每個里程獎勵
        local reward = {
            -- 進度
            progress = wishingWellMilestoneCfg.points[idx],
            -- 物品資訊
            itemInfo = wishingWellMilestoneCfg.reward[idx],
        }
        rewards[idx] = reward
    end
    -- 進度獎勵
    info.progressRewards = rewards

    return info
end


return WishingWellDataMgr