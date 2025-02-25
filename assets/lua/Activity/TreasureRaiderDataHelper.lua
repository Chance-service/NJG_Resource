----------------------------------------------------------------------------------
--[[
	西施祝福数据
--]]
----------------------------------------------------------------------------------

local ConfigManager = require("ConfigManager")
local showType = {
    reward = 0,
    box = 1
}
local boxOrReward
local TreasureRaiderDataHelper = {
    RemainTime = 0,
    showItems = { },
    freeTreasureTimes = 0,
    leftTreasureTimes = 0,
    onceCostGold = 0,
    tenCostGold = 0,
    totalTimes = 0,       --总抽奖次数
    TreasureRaiderConfig = ConfigManager.getTresureRaiderRewardCfg() or { },
}

return TreasureRaiderDataHelper