
--[[ 本體 ]]
local Inst = {}

SingleBossData = SingleBossData or { 
    questData = { },
    rankData = { },
    maxStage = 0,
    maxScore = 0,
    activityEndTime = 0,
    challangeTime = 0,
    --
    popType = 0,
    popStage = 0,
    challangeType = 0,
    --
    dataDirtyBase = true,
}

Inst.PopPageType = {
    MISSION = 1, STAGE_REWARD = 2, RANK_REWARD = 3
}

Inst.ProtoAction = {
    SYNC_INFO = 0, GET_MISSION_AWARD = 1, SYNC_RANKING = 2
}

--[[ 子頁面 配置 ]]
Inst.SubPageCfgs = {
    {
        -- 子頁面名稱 : 單人強敵主畫面
        subPageName = "SingleBossMain",
        
        -- 分頁 相關
        scriptName = "SingleBoss.SingleBossSubPage_Main",
        iconImg_normal = "SubBtn_SingleBoss.png",
        iconImg_selected = "SubBtn_SingleBoss_On.png",
        
        -- 標題
        title = common:getLanguageString("@SingleBoss"),
        
        -- 貨幣資訊
        currencyInfos = { },
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,
    },
    {
        -- 子頁面名稱 : 單人強敵排名
        subPageName = "SingleBossRanking",
        
        -- 分頁 相關
        scriptName = "SingleBoss.SingleBossSubPage_Ranking",
        iconImg_normal = "SubBtn_Ranking.png",
        iconImg_selected = "SubBtn_Ranking_On.png",
        
        -- 標題
        title = common:getLanguageString("@SingleBossRank"),
        
        -- 貨幣資訊
        currencyInfos = { },
        
        -- 其他子頁資訊 ----------
        TopisVisible = false,
    },
}

--[[ 取得 子頁面 配置 ]]
function Inst:getSubPageCfg(subPageName)
    for idx, cfg in ipairs(Inst.SubPageCfgs) do
        if cfg.subPageName == subPageName then return cfg end
    end
    return nil
end

--[[ 紀錄 頁面 資料 ]]
function Inst:setPageData(data)
    
end

--[[ 取得 頁面 資料 ]]
function Inst:getPageData()
    return SingleBossData
end


return Inst
