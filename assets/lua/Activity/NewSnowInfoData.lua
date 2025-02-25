
-- 页面信息基本数据
local NewSnowInfoData = {
    activityId  =  50,                              --活动ID
    consumeGold = 50,                               --消耗钻石
    COUNT_TREASURE_MAX = 12,                        --12个雪地
    activityLeftTime = 0,                           -- 活动剩余时间
    freeTime = 0,                                  -- 剩余次数
    score = 0,                                      -- 积分
    devilsIndexInfo = {},                             -- 已经领取信息
    luck    = false,                                -- 是否有幸运奖励
    luckAward   = {},                               -- 幸运奖励
    snowRankCfg = ConfigManager.getNewSnowRankRewardCfg(), -- 排名奖励
    newSnowTreasureCfg = ConfigManager.getNewSnowTreasureCfg(), -- 奖励预览
    nowInStage = 1, -- 玩家当前所在阶段
    consumeGold = 0,--
}

-- 当前排名页面还是排名奖励页面
NewSnowInfoData.RankPageType = {
    RankPage = 1,
    RewardPage = 2,
}

NewSnowInfoData.OpacityValue = {
    255,
    225,
    200,
    185,
    165,
    140,
    120,
    100,
    80,
    50,
    10,
    0
}
return NewSnowInfoData