
----------------------------------------------------------------------------------
local  CSMatchData = {
	battleInfos = {}, 			-- 战斗结束信息
	rankLists = {},				-- 排行榜信息
	battleRecords = {}, 		-- 战斗录像
	revengeRecords = {}, 		-- 复仇记录
	isFromCSMatch = false, 		-- 战斗结算是跨服的
}
function CSMatchData.setBattleResult( msg )
	assert(msg,"CSMatchData.battleInfo is nil")
	CSMatchData.battleInfos = msg
end
function CSMatchData.getBattleResult()
	assert(CSMatchData.battleInfos,"CSMatchData.battleInfo is nil")
	return CSMatchData.battleInfos
end

function CSMatchData.setRankLists( msg )
	assert(msg,"CSMatchData.rankLists is nil")
	CSMatchData.rankLists = msg
end
function CSMatchData.getRankLists()
	assert(CSMatchData.rankLists,"CSMatchData.rankLists is nil")
	return CSMatchData.rankLists
end

function CSMatchData.setBattleRecords( msg )
	assert(msg,"CSMatchData.battleRecords is nil")
	CSMatchData.battleRecords = msg
end
function CSMatchData.getBattleRecords()
	assert(CSMatchData.battleRecords,"CSMatchData.battleRecords is nil")
	return CSMatchData.battleRecords
end

function CSMatchData.setRevengeRecords( msg )
	CSMatchData.revengeRecords = msg
end
function CSMatchData.getRevengeRecords()
	return CSMatchData.revengeRecords or nil
end

return CSMatchData