ActivityData = { }

ActivityData.TogetherCompetingRedPage = {
    id = 42,
    myRedEnvelope = 0,
    -- 我的红包数量
    serverRedPackNum = 0,
    -- 全服红包数量
    todayAlreadyGetRed = 0,
    -- 今天已抢几个红包
    isGetEveryDayReward = 0,
    -- 是否领取每日奖励
    remainTime = 0,
    timerName = "Activity_TogetherCompetingRedPage",
    todaySysRedEnvelopeStatus = 0,
    -- 今日系统红包状态,0未领,1已领
    freeReward = "",-- 免费领取奖励
}

-- 静态数据
ActivityData.SysBasic = {
    -- 累计充值奖励活动，每天充值的元宝
    dailyAccRechargeGold = 600,
    ----神力石id
    ForgedStoneItemId = 299993,
    ----上限个数请求限制
    limitCount = 99,
    ----是否查看他人的阵营
    isViewPlayerOtherFlag = false,
    ----万圣节活动道具消耗
    HalloweenPartyPropConsumption133 = "30000_299805_1",
    -- 宝箱幸运值显示道具
    treasureBoxLuckList = { 211148, 211144 },
    -- 周年庆拼图位置默认开放位置
    jigsawPuzzlePos = 8,
    -- 周年庆拼图等活动道具展示
    jigsawPuzzleItems = "30000_106105_1",
}

ActivityData.SevenDayData = nil -- 七天登录数据

return ActivityData