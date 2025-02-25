--[[ 
    name: RewardDataMgr
    desc: 獎勵頁面 資料管理
    author: youzi
    update: 2023/7/11 16:31
    description: 
--]]

--[[ 本體 ]]
local Inst = {}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {

        {
        --是否關閉
        isClose=false,
        -- 子頁面名稱 : 免費召喚
        subPageName = "Free Summons",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_FreeSummon2",
        iconImg_normal = "SubBtn_300Summons.png",
        iconImg_selected = "SubBtn_300Summons_On.png",
        
        -- 標題
        title = "@FreeSummon900",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------
         activityID=180
    },
    --{
    --    --是否關閉
    --    isClose=false,
    --    -- 子頁面名稱 : 付費召喚
    --    subPageName = "Free Summons",
    --
    --    -- 分頁 相關
    --    scriptName = "Reward.RewardSubPage_FreeSummon",
    --    iconImg_normal = "SubBtn_900Summons.png",
    --    iconImg_selected = "SubBtn_900Summons_On.png",
    --    
    --    -- 標題
    --    title = "@FreeSummonTitle",
    --
    --    -- 貨幣資訊 
    --    currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },
    --
    --    -- 其他子頁資訊 ----------
    --     activityID=167
    --},
        {
        --是否關閉
        isClose=true,
        -- 子頁面名稱 : 付費召喚
        subPageName = "Cost Summons",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_CostSummon1",
        iconImg_normal = "SubBtn_300Summons_2.png",
        iconImg_selected = "SubBtn_300Summons_2_On.png",
        
        -- 標題
        title = "@Recharge300Summon",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------
         SummonReward = 1901
    },
    {
        --是否關閉
        isClose=false,
        -- 子頁面名稱 : 付費召喚
        subPageName = "Cost Summons",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_CostSummon2",
        iconImg_normal = "SubBtn_300Summons_3.png",
        iconImg_selected = "SubBtn_300Summons_3_On.png",
        
        -- 標題
        title = "@Recharge330Summon",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------
         SummonReward=1902
    },
    {
        --是否關閉
        isClose=true,
        -- 子頁面名稱 : 付費召喚
        subPageName = "Cost Summons",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_CostSummon3",
        iconImg_normal = "SubBtn_300Summons_4.png",
        iconImg_selected = "SubBtn_300Summons_4_On.png",
        
        -- 標題
        title = "@Recharge360Summon",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------
         SummonReward=1903
    },
   
   
    {
        --是否關閉
        isClose=false,  
        -- 子頁面名稱 : 每日登入30
        subPageName = "DayLogin30",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_DayLogin30",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_LoginReward.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_LoginReward_On.png",
        
        -- 標題
        title = "@DailyLogin",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------

    },

    {
        --是否關閉
        isClose=true,  
        -- 子頁面名稱 : 等級成就
        subPageName = "LevelAchv",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_Achv_Level",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_LevelGift.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_LevelGift_On.png",
        
        -- 標題
        title = "@Reward.LevelAchv.title",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------

        -- 活動ID
        activityID = 155,

    },
    
    {
        --是否關閉
        isClose=true,  
        -- 子頁面名稱 : 戰力成就
        subPageName = "PowerAchv",

        -- 分頁 相關
        scriptName = "Reward.RewardSubPage_Achv_Power",
        iconImg_normal = "Imagesetfile/i18n_Button/SubBtn_PowerGift.png",
        iconImg_selected = "Imagesetfile/i18n_Button/SubBtn_PowerGift_On.png",
        
        -- 標題
        title = "@Reward.PowerAchv.title",

        -- 貨幣資訊 
        currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },

        -- 其他子頁資訊 ----------

        -- 活動ID
        activityID = 156,

    },
   {

       --是否關閉
       isClose=true,  
       -- 子頁面名稱 : SkinShop
       subPageName = "SkinShop",
   
       -- 分頁 相關
       scriptName = "Reward.RewardSubPage_SkinShop",
       iconImg_normal = "SubBtn_Skinshop.png",
       iconImg_selected = "SubBtn_Skinshop_On.png",
       
       -- 標題
       title ="",
   
       -- 貨幣資訊 
       currencyInfos = { { priceStr = "10000_1002_0" }, { priceStr = "10000_1001_0" } },
   
       -- 其他子頁資訊 ----------
        TopisVisible=false,
   
        LOCK_KEY = GameConfig.LOCK_PAGE_KEY.SKIN_SHOP,
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