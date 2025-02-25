
local TribeAwardsDataManager= {
	rewardIds           = {},
    currentIndex        = 1, --预览级别
    currentLuckyValue   = 0, --预览幸运值
    currentState        = 1, --当前级别
    totalConsume        = 0,  --共消耗多少钻石
    leftTimes           = 0,  --剩余次数
    totalConsume        = 0,   --总消耗
    consumeScore        = {},    --消耗积分
    rewardInfo          = ConfigManager.getTribeAwardCfg(),
    maxLuckyValue       = {},   --最大幸运值
    trueLuckyValue      = 0,   --真实幸运值
    remainTime          = 0,
    fScrollViewWidth    = 0,
    totalSize           = 0
}
return TribeAwardsDataManager