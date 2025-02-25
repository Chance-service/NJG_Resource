local BaseDataHelper = require("BaseDataHelper")
local HP_pb = require("HP_pb")
local Activity2_pb = require("Activity2_pb")
local RankGiftManager = BaseDataHelper:new(nil) 
local RankGiftCfg = ConfigManager.getRankGiftCfg()
--config
local MAX_RANK_COUNT = 50
--init data
RankGiftManager.RankGiftLeftTimes = 0

function RankGiftManager:onReceivePacket(container,page)
    local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == HP_pb.RANK_GIFT_INFO_S then
        local msg = Activity2_pb.HPRankGiftRet();
		msg:ParseFromString(msgBuff);
        self.totalTime = msg.totalTime/1000
        self.RankGiftLeftTimes = msg.leftTimes/1000
        self.arenaRankInfo = msg.arenaRankInfo
        self.levelRankInfo = msg.expRankInfo
        page:refreshPage(container)
	end
end
--common
function RankGiftManager:getActivityTotalTime()
    if self.totalTime~=nil then
        return common:second2DateString2(self.totalTime,false)
    end
end

function RankGiftManager:getMaxRankCount()
    return MAX_RANK_COUNT
end
--arena
function RankGiftManager:getArenaPlayerInfoByIndex(index)
    return self.arenaRankInfo.rankList[index]
end

function RankGiftManager:getArenaRewardsByIndex(index)
    return RankGiftCfg.arena[index].rewards
end

function RankGiftManager:getArenaRankTextByIndex(index)
    return RankGiftCfg.arena[index].rank
end

function RankGiftManager:getSelfArenaRank()
    if self.arenaRankInfo.selfRank~=-1 then
        return self.arenaRankInfo.selfRank
    else
        return common:getLanguageString("@RankGiftNotInList")
    end
end

function RankGiftManager:getArenaRankListCfg()
    return RankGiftCfg.arena
end
--level
function RankGiftManager:getLevelPlayerInfoByIndex(index)
    return self.levelRankInfo.rankList[index]
end

function RankGiftManager:getLevelRewardsByIndex(index)
    return RankGiftCfg.level[index].rewards
end

function RankGiftManager:getLevelRankTextByIndex(index)
    return RankGiftCfg.level[index].rank
end

function RankGiftManager:getSelfLevelRank()
    if self.levelRankInfo.selfRank~=-1 then
        return self.levelRankInfo.selfRank
    else
        return common:getLanguageString("@RankGiftNotInList")
    end
end

function RankGiftManager:getLevelRankListCfg()
    return RankGiftCfg.level
end

return RankGiftManager