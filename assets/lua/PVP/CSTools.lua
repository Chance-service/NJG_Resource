----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--require "IncPbCommon"

local CSTools = {}

--------------------------------------------------------------
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local time = os.time
local pow = math.pow

local CS_Battle_Stage = {
	NOTSTART	 = 0,	--未开启
	SIGNUP 		 = 2,	--报名阶段
	SIGNUP_END	 = 3,	--报名结束
	LS_KNOCKOUT  = 4, 	--本服淘汰赛阶段
	LS_16TO8	 = 6, 	--本服16进8阶段
	LS_8TO4		 = 8, 	--本服8进4阶段
	LS_4TO2		 = 10, 	--本服4进2阶段
	LS_2TO1		 = 12, 	--本服2进1阶段
	CS_KNOCKOUT	 = 14, 	--跨服淘汰赛阶段
	CS_16TO8	 = 16, 	--跨服16进8阶段
	CS_8TO4		 = 18, 	--跨服8进4阶段
	CS_4TO2		 = 20,	--跨服4进2阶段
	CS_2TO1		 = 22, 	--跨服2进1阶段
	FINAL_REVIEW = 24, 	--决赛回顾阶段
	FINISHED	 = 26 	--比赛结束
}

local Stage2Attr = {
	[CS_Battle_Stage.NOTSTART]		= "signUpStartTime",
	[CS_Battle_Stage.SIGNUP]		= "signUpStartTime",
	[CS_Battle_Stage.SIGNUP_END]	= "signUpEndTime",
	[CS_Battle_Stage.LS_KNOCKOUT] 	= "perKonckoutStartTime",
	[CS_Battle_Stage.LS_16TO8]		= "per16To8StartTime",
	[CS_Battle_Stage.LS_8TO4]		= "per8To4StartTime",
	[CS_Battle_Stage.LS_4TO2]		= "per4To2StartTime",
	[CS_Battle_Stage.LS_2TO1]		= "per2To1StartTime",
	[CS_Battle_Stage.CS_KNOCKOUT]	= "croKonckoutStartTime",
	[CS_Battle_Stage.CS_16TO8]		= "cro16To8StartTime",
	[CS_Battle_Stage.CS_8TO4]		= "cro8To4StartTime",
	[CS_Battle_Stage.CS_4TO2]		= "cro4To2StartTime",
	[CS_Battle_Stage.CS_2TO1]		= "cro2To1StartTime",
	[CS_Battle_Stage.FINAL_REVIEW] 	= "reviewTime"		--reviewTime是结束时间,代码有些怪TO FIX
}

--0.未开启 1.报名阶段 2.本服淘汰赛阶段 
--3.本服16进8押注阶段 4.本服16进8比赛中阶段 5.本服16进8回放阶段
--6.本服8进4押注阶段 7.本服8进4比赛中阶段 8.本服8进4回放阶段
--9.本服4进2押注阶段 10.本服4进2比赛中阶段 11.本服4进2回放阶段
--12.本服2进1押注阶段 13.本服2进1比赛中阶段 14.本服2进1回放阶段
--15.跨服淘汰赛阶段
--16.跨服16进8押注阶段 17.跨服16进8比赛中阶段 18.跨服16进8回放阶段
--19.跨服8进4押注阶段 20.跨服8进4比赛中阶段 21.跨服8进4回放阶段
--22.跨服4进2押注阶段 23.跨服4进2比赛中阶段 24.跨服4进2回放阶段
--25.跨服2进1押注阶段 26.跨服2进1比赛中阶段 27.跨服2进1回放阶段
--28.回顾决赛阶段 29.已完成 30.本服决赛完成即将跨服淘汰赛阶段
local CS_Battle_Detail_Stage = {
	NOTSTART			= 0,
	SIGNUP				= 1,
	LS_KNOCKOUT			= 2,
	LS_16TO8_BET		= 3,
	LS_16TO8_BATTLE		= 4,
	LS_16TO8_PLAYBACK	= 5,
	LS_8TO4_BET			= 6,
	LS_8TO4_BATTLE		= 7,
	LS_8TO4_PLAYBACK	= 8,
	LS_4TO2_BET			= 9,
	LS_4TO2_BATTLE		= 10,
	LS_4TO2_PLAYBACK	= 11,
	LS_2TO1_BET			= 12,
	LS_2TO1_BATTLE		= 13,
	LS_2TO1_PLAYBACK	= 14,
	CS_KNOCKOUT			= 15,
	CS_16TO8_BET		= 16,
	CS_16TO8_BATTLE		= 17,
	CS_16TO8_PLAYBACK	= 18,
	CS_8TO4_BET			= 19,
	CS_8TO4_BATTLE		= 20,
	CS_8TO4_PLAYBACK	= 21,
	CS_4TO2_BET			= 22,
	CS_4TO2_BATTLE		= 23,
	CS_4TO2_PLAYBACK	= 24,
	CS_2TO1_BET			= 25,
	CS_2TO1_BATTLE		= 26,
	CS_2TO1_PLAYBACK	= 27,
	FINAL_REVIEW		= 28,
	FINISHED			= 29
}

local BattleStage_CanBet = {
	[CS_Battle_Stage.LS_16TO8] = CS_Battle_Detail_Stage.LS_16TO8_BET,
	[CS_Battle_Stage.LS_8TO4]  = CS_Battle_Detail_Stage.LS_8TO4_BET,
	[CS_Battle_Stage.LS_4TO2]  = CS_Battle_Detail_Stage.LS_4TO2_BET,
	[CS_Battle_Stage.LS_2TO1]  = CS_Battle_Detail_Stage.LS_2TO1_BET,
	[CS_Battle_Stage.CS_16TO8] = CS_Battle_Detail_Stage.CS_16TO8_BET,
	[CS_Battle_Stage.CS_8TO4]  = CS_Battle_Detail_Stage.CS_8TO4_BET,
	[CS_Battle_Stage.CS_4TO2]  = CS_Battle_Detail_Stage.CS_4TO2_BET,
	[CS_Battle_Stage.CS_2TO1]  = CS_Battle_Detail_Stage.CS_2TO1_BET
}

local BattleStage_CannotBet = {
	[CS_Battle_Stage.NOTSTART] 	   = CS_Battle_Detail_Stage.NOTSTART,
	[CS_Battle_Stage.SIGNUP] 	   = CS_Battle_Detail_Stage.SIGNUP,
	[CS_Battle_Stage.LS_KNOCKOUT]  = CS_Battle_Detail_Stage.LS_KNOCKOUT,
	[CS_Battle_Stage.CS_KNOCKOUT]  = CS_Battle_Detail_Stage.CS_KNOCKOUT,
	[CS_Battle_Stage.FINAL_REVIEW] = CS_Battle_Detail_Stage.FINAL_REVIEW,
	[CS_Battle_Stage.FINISHED] 	   = CS_Battle_Detail_Stage.FINISHED
}

--各小阶段持续时间(单位:秒)
local CSBattle_Duration = {
	Period 	 = tonumber(common:getSettingVar("CSBattleDuration_Period")),
    Knockout 	 = tonumber(common:getSettingVar("CSBattleDuration_KNOCKOUT_Period")),
	Bet		 = tonumber(common:getSettingVar("CSBattleDuration_Bet")),
	Battle	 = tonumber(common:getSettingVar("CSBattleDuration_Battle")),
	Playback = tonumber(common:getSettingVar("CSBattleDuration_Playback"))
}

local SecPerHour = 3600
--local ServerOffset_UTCTime = -9 * SecPerHour	--东九区时间偏移
local LocalOffset_UTCTime = (function ()
	for i = 0, 12 do
		local locStartTime = time({
			year = 1970,
			month = 1,
			day = 1,
			hour = i,
			min = 0,
			sec = 0,
            isdst = false--取非夏令时，默认isdst=true ，如果当前时区存在夏令时时间，
                         --而夏令时时间还未开启，则会获取时间失败，判断时区失败
		})
		if locStartTime then
			return locStartTime - i * SecPerHour
		end
	end
	return 0
end)()

---------------------------------------------------------
--------------public functions
--------------------------------------------------------
--判断当前心跳包时间是否属于某个战争某阶段
function CSTools.timeAtStage(cBattle, timeType)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	if timeType == CS_Battle_Stage.NOTSTART then
		return not CSTools.isPeriodStart(timeItem, timeType)
	elseif timeType == CS_Battle_Stage.SIGNUP then
		return ( CSTools.isPeriodStart(timeItem, timeType)
			and not CSTools.isPeriodEnd(timeItem, CS_Battle_Stage.SIGNUP_END) )
	elseif timeType == CS_Battle_Stage.SIGNUP_END then
			return false
	elseif timeType == CS_Battle_Stage.FINISHED then
		return CSTools.isPeriodStart(timeItem, CS_Battle_Stage.FINAL_REVIEW)
	elseif timeType == CS_Battle_Stage.LS_KNOCKOUT then
		return ( CSTools.isPeriodStart(timeItem, CS_Battle_Stage.SIGNUP_END)
			and not CSTools.isPeriodStart(timeItem, CSTools.getNextBigStage(timeType)) )
	elseif timeType == CS_Battle_Stage.CS_KNOCKOUT then
		return ( CSTools.isPeriodEnd(timeItem, CS_Battle_Stage.LS_2TO1)
			and not CSTools.isPeriodStart(timeItem, CSTools.getNextBigStage(timeType)) )
	elseif timeType == CS_Battle_Stage.FINAL_REVIEW then
		return ( CSTools.isPeriodEnd(timeItem, CSTools.getPrevBigStage(timeType))
			and not CSTools.isPeriodStart(timeItem, timeType) )
	else
		return ( CSTools.isPeriodStart(timeItem, timeType)
			and not CSTools.isPeriodEnd(timeItem, timeType) )
	end
end

--根据当前届battleId，得到当届开始时间
function CSTools.getWarStartTime(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return ""
	end
	local dateObj = Split(common:trim(timeItem.signUpStartTime), '[\\-#]')
	return common:getLanguageString("@CSBeginTime", dateObj[1], dateObj[2], dateObj[3])
end

--根据当前届battleId,判断是否是处于开战中
function CSTools.openWarState(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	return ( CSTools.isPeriodStart(timeItem, CS_Battle_Stage.SIGNUP_END)
		and not CSTools.isPeriodStart(timeItem, CS_Battle_Stage.FINAL_REVIEW) )
end

function CSTools.getCurrentStage(cBattle)
	for _, stage in pairs(CS_Battle_Stage) do
		if CSTools.timeAtStage(cBattle, stage) then
            if stage == nil then
                return 0
            else
                return tonumber(stage)
            end
		end
	end
	return CS_Battle_Stage.NOTSTART
end

function CSTools.getOngoingStages(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return nil
	end

	local going1 = nil
	local going2 = nil

	local curStage = CSTools.getCurrentStage(cBattle)
	local nextStage = CSTools.getNextBigStage(curStage)

	for stage, detailStage in pairs(BattleStage_CannotBet) do
		if curStage == stage then
			going1 = detailStage
			if nextStage and BattleStage_CanBet[nextStage] then
				going2 = detailStage + 1
			end
			break;
		end
	end
	
	if not going1 then
		for stage, detailStage in pairs(BattleStage_CanBet) do
			if stage == curStage then
				if CSTools.isStageInBet(timeItem, stage) then
					going1 = detailStage
					break;
				end
				
				if CSTools.isStageInBattle(timeItem, stage) then
					going1 = detailStage + 1
				elseif CSTools.isStageInPlayback(timeItem, stage) then
					going1 =  detailStage + 2
				end

				if going1 then
					if nextStage and BattleStage_CanBet[nextStage] then
						going2 = BattleStage_CanBet[nextStage]
					end
					break;
				end
			end
		end
	end

	return going2 and string.format("%d#%d", going1, going2) or going1
end

function CSTools.getNextStage(cBattle)
	local curStage = CSTools.getCurrentStage(cBattle)
	if CSTools.checkBetStage(cBattle) then
		return curStage
	end
	local nextStage = CSTools.getNextBigStage(curStage)
	if nextStage == CS_Battle_Stage.FINISHED then
		nextStage = nil
	end
	return nextStage
end

function CSTools.getStageRemainTime(cBattle, stage)
	local startTime = CSTools.getStageStartTime(cBattle, stage)
	if not startTime then
		return 0
	end

	local remain = startTime - CSTools.GetserverTimes();
	return remain < 0 and 0 or remain
end

--是否是押注阶段
function CSTools.checkBetStage(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	local stage = CSTools.getCurrentStage(cBattle)
	if not BattleStage_CanBet[stage] then
		return false
	end
	return CSTools.isStageInBet(timeItem, stage)
end

--是否是比赛阶段
function CSTools.checkBattleStage(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	local stage = CSTools.getCurrentStage(cBattle)
	if not BattleStage_CanBet[stage] then
		return false
	end
	return CSTools.isStageInBattle(timeItem, stage)
end

--是否是回放阶段
function CSTools.checkReviewStage(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	local stage = CSTools.getCurrentStage(cBattle)
	if stage == CS_Battle_Stage.FINAL_REVIEW then
		return true
	end
	if not BattleStage_CanBet[stage] then
		return false
	end
	return CSTools.isStageInPlayback(timeItem, stage)
end

--返回当前时间段的对战时间（争霸赛之外返回nil）
function CSTools.getCurrentStageBattleTime(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return nil
	end
	local stage = CSTools.getCurrentStage(cBattle)
	if not BattleStage_CanBet[stage] then
		return nil
	end
	local battleStartTime = CSTools.getPeriodStartTime(timeItem, stage) + CSBattle_Duration.Bet
	local battleEndTime = battleStartTime + CSBattle_Duration.Battle
	local startDate = GameMaths:formatTimeToDate(battleStartTime)
	local endDate = GameMaths:formatTimeToDate(battleEndTime)
	endDate = Split(endDate, " ")[2]
	return common:getLanguageString("@CSBattleFightDuration", startDate, endDate)
end

function CSTools.battleReviewEnded(cBattle)
	local stage = CSTools.getCurrentStage(cBattle)
	if stage == CS_Battle_Stage.CS_KNOCKOUT or stage == CS_Battle_Stage.FINISHED then
		return true
	end
	return false
end
----------------------------------------------------------------------
function CSTools.getBetConfig(battleId)
	local betRewardCfg = ConfigManager.getBetCfg()
	local rewardsItem = betRewardCfg[battleId]
	if not rewardsItem then
		--common:log("Error: no bet item config for battle %d", battleId)
		return {}
	end
	return {
		[CS_Battle_Stage.LS_16TO8] = {
			bet	   = rewardsItem.per16To8BetCost,
			reward = rewardsItem.per16To8BetReward
		},
		[CS_Battle_Stage.LS_8TO4] = {
			bet	   = rewardsItem.per8To4BetCost,
			reward = rewardsItem.per8To4BetReward
		},
		[CS_Battle_Stage.LS_4TO2] = {
			bet	   = rewardsItem.per4To2BetCost,
			reward = rewardsItem.per4To2BetReward
		},
		[CS_Battle_Stage.LS_2TO1] = {
			bet	   = rewardsItem.per2To1BetCost,
			reward = rewardsItem.per2To1BetReward
		},
		[CS_Battle_Stage.CS_16TO8] = {
			bet	   = rewardsItem.cro16To8BetCost,
			reward = rewardsItem.cro16To8BetReward
		},
		[CS_Battle_Stage.CS_8TO4] = {
			bet	   = rewardsItem.cro8To4BetCost,
			reward = rewardsItem.cro8To4BetReward
		},
		[CS_Battle_Stage.CS_4TO2] = {
			bet	   = rewardsItem.cro4To2BetCost,
			reward = rewardsItem.cro4To2BetReward
		},
		[CS_Battle_Stage.CS_2TO1] = {
			bet	   = rewardsItem.cro2To1BetCost,
			reward = rewardsItem.cro2To1BetReward
		}
	}
end

function CSTools.getPlayerInfo(csPlayerInfo)
	local playerInfo = {
		discipleId = csPlayerInfo.playerItemId,
		name = csPlayerInfo.playerName,
		id = csPlayerInfo.playerIdentify
	}
	if csPlayerInfo.serverName then
		playerInfo.serverName = csPlayerInfo.serverName
	end
	return playerInfo
end

function CSTools.isBetGoingOn(cBattle, stage)
	local curStage = CSTools.getCurrentStage(cBattle)
	if curStage ~= stage then
		return false
	end

	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	return not CSTools.isStageInPlayback(timeItem, stage)
end

function CSTools.isKnockOutEnd(cBattle)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return false
	end
	local curStage = CSTools.getCurrentStage(cBattle)
	if ( curStage == CS_Battle_Stage.LS_KNOCKOUT 
		or curStage == CS_Battle_Stage.CS_KNOCKOUT )
		and CSTools.isPeriodEnd(timeItem, curStage)
	then
		return true
	end
	return false
end

function CSTools.getStartDateStr(cBattle, detailStage)
	local startTime = CSTools.getStageStartTime(cBattle, detailStage)
	if not startTime then
		return ""
	end
	return CSTools.timeToDateStr(startTime)
end

function CSTools.getBigStageStartDateStr(cBattle, bigStage)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return ""
	end
	if bigStage == CS_Battle_Stage.FINAL_REVIEW then
		local startTime = CSTools.getStageStartTime(cBattle, CS_Battle_Detail_Stage.FINAL_REVIEW)
		return CSTools.timeToDateStr(startTime)
	end

	local attr = Stage2Attr[bigStage]
	if not attr or not timeItem[attr] then
		CCLuaLog("CSTools.isPeriodEnd::no such attr")
		return ""
	end

	local dateObj = Split(common:trim(timeItem[attr]), '[\\-#]')
	local _, month, day = unpack(dateObj)
	return common:getLanguageString("@MonthDay", tonumber(month), tonumber(day))
end

function CSTools.getCurrentBetCost(cBattle)
	local curStage = CSTools.getCurrentStage(cBattle)
	if not BattleStage_CanBet[curStage] then
		return 0
	end
	local betConfig = CSTools.getBetConfig(cBattle)[curStage]
	if betConfig then
		local _, _, count = unpack(Split(betConfig.bet, "_"))
		return tonumber(count)
	end
	return 0
end

--@param stage: the final stage where player lose and stop
--@special: stage for champion is (LS_2To 1 + 1 = 13) or (CS_2T01 + 1 = 23)
function CSTools.stageToRank(stage, isLocal)
	local base = isLocal and CS_Battle_Stage.LS_KNOCKOUT or CS_Battle_Stage.CS_KNOCKOUT
	local rank = tonumber(stage) - base
	local maxRank = CS_Battle_Stage.LS_2TO1 - CS_Battle_Stage.LS_KNOCKOUT
	if rank == maxRank + 1 then --champion
		return 1
	end
	if rank <= 0 or rank > maxRank  or rank % 2 ~= 0 then
		return 0
	end
	local index = (maxRank - rank) / 2 + 1
	return pow(2, index)
end

function CSTools.getKnockoutBattleName(isCsKnockout)
	local stage = isCsKnockout and CS_Battle_Stage.CS_KNOCKOUT or CS_Battle_Stage.LS_KNOCKOUT
	return common:getLanguageString("@CSBattleName_" .. stage)
end

function CSTools.isCrossBattleBegin(cBattle)
	return CSTools.getCurrentStage(cBattle) >= CS_Battle_Stage.CS_KNOCKOUT
end

function CSTools.isLCBattleEnd(cBattle)
	return CSTools.getCurrentStage(cBattle) >= CS_Battle_Stage.CS_KNOCKOUT 
end

function CSTools.isBeforeTheFinal(cBattle, isCs)
	local stage = CSTools.getCurrentStage(cBattle)
	local finalStage = isCs and CS_Battle_Stage.CS_2TO1 or CS_Battle_Stage.LS_2TO1
	if stage == finalStage then
		local timeItem = CSTools.getTimeItem(cBattle)
		return CSTools.isStageInBet(timeItem, stage)
	end
	return stage < finalStage
end
------------------------------------------------------
------------private functions--------
-----------------------------------------------------
function CSTools.getStageStartTime(cBattle, stage)
	local timeItem = CSTools.getTimeItem(cBattle)
	if not timeItem then
		return 0
	end
	
	local stage = tonumber(stage)
	local startTime = nil
	for bigStage, detailStage in pairs(BattleStage_CanBet) do
		local gap = stage - detailStage
		if gap >= 0 and gap <= 2 then
			startTime = CSTools.getPeriodStartTime(timeItem, bigStage)
			if gap > 0 then
				startTime = startTime + CSBattle_Duration.Bet
				if gap == 2 then
					startTime = startTime + CSBattle_Duration.Battle
				end
			end
			break;
		end
	end

	if not startTime then
		for bigStage, detailStage in pairs(BattleStage_CannotBet) do
			if stage == detailStage then
				if bigStage == CS_Battle_Stage.FINAL_REVIEW then
					startTime = CSTools.getPeriodStartTime(timeItem, CS_Battle_Stage.CS_2TO1) + CSBattle_Duration.Period
				else
					startTime = CSTools.getPeriodStartTime(timeItem, bigStage)
				end
				break;
			end
		end
	end

	return startTime
end

function CSTools.timeToDateStr(time)
	local date = GameMaths:formatTimeToDate(time)
	local dateObj = Split(date, '[\\-%s]')
	local _, month, day = unpack(dateObj)
	return common:getLanguageString("@MonthDay", tonumber(month), tonumber(day))
end

function CSTools.isPeriodStart(timeItem, state)
	return ( CSTools.getPeriodStartTime(timeItem, state)
		< CSTools.GetserverTimes() )
end

function CSTools.isPeriodEnd(timeItem, state)
    local dTime = 0
    if state == CS_Battle_Stage.LS_KNOCKOUT or state == CS_Battle_Stage.CS_KNOCKOUT then
        dTime = CSBattle_Duration.Knockout
    else
        dTime = CSBattle_Duration.Period
    end
	local endTime = CSTools.getPeriodStartTime(timeItem, state) + dTime
	return endTime < CSTools.GetserverTimes()
end

function CSTools.getPeriodStartTime(timeItem, state)
	local attr = Stage2Attr[state]
	if not attr or not timeItem[attr] then
		CCLuaLog("CSTools.isPeriodEnd::no such attr")
		return 0
	end
	return CSTools.strToTime(timeItem[attr])
end

function CSTools.getNextBigStage(stage)
	return stage and stage + 2 or nil
end

function CSTools.getPrevBigStage(stage)
	return stage and stage - 2 or nil
end

function CSTools.isStageInBet(timeItem, stage)
	local betEndTime = CSTools.getPeriodStartTime(timeItem, stage) + CSBattle_Duration.Bet
	return (CSTools.GetserverTimes() <= betEndTime)
end

function CSTools.isStageInBattle(timeItem, stage)
	local battleStartTime = CSTools.getPeriodStartTime(timeItem, stage) + CSBattle_Duration.Bet
	local battleEndTime = battleStartTime + CSBattle_Duration.Battle
	local serverTime = CSTools.GetserverTimes()
	return (serverTime >= battleStartTime and serverTime <= battleEndTime)
end

function CSTools.isStageInPlayback(timeItem, stage)
	local playbackStartTime = CSTools.getPeriodStartTime(timeItem, stage) + CSBattle_Duration.Bet + CSBattle_Duration.Battle
	local playbackEndTime = playbackStartTime + CSBattle_Duration.Playback
	local serverTime = CSTools.GetserverTimes()
	return (serverTime >= playbackStartTime and serverTime <= playbackEndTime)
end

function CSTools.getTimeItem(cBattle)
	local CSTimeListCfg = ConfigManager.getCSTimeListCfg() 
	local timeItem = CSTimeListCfg[cBattle]
	if not timeItem then
		MessageBoxPage:Msg_Box("Error: no cs time item of related battleId " .. cBattle)
	end
	return timeItem
end

function CSTools.strToTime(dateStr)
	if not dateStr or dateStr == ' ' then return end
	local keys = {"year", "month", "day", "hour", "min", "sec"}
    tabletime = common:table_combine(keys, Split(common:trim(dateStr), '[\\-:#]'))
    tabletime["isdst"] = false;
    --取非夏令时，默认isdst=true ，如果当前时区存在夏令时时间，
    --而夏令时时间还未开启，则会获取时间失败，判断时区失败
	local locTime = time(tabletime)
    --return locTime - (LocalOffset_UTCTime - ServerOffset_UTCTime)
	return locTime
end
function CSTools.GetServerDate()
    tb = {};
    local stime = GamePrecedure:getInstance():getServerTime();
    local timeOrginalStr = GameMaths:getTimeByTimeZone(stime,GameConfig.SaveingTime)--美国东部时间 夏令时“EST”
	local timeTable = common:split(timeOrginalStr," ")
    local monthKeys = {Jan="01", Feb="02", Mar="03", Apr="04",May="05", Jun="06",Jul="07", Aug="08", Sep="09", Oct="10",Nov="11", Dec="12"}
    tb["year"] = os.date("%Y");
    tb["month"] = monthKeys[timeTable[1]];
    tb["day"] = timeTable[2]
    tb["hour"] = common:split(timeTable[3],":")[1];
    tb["min"] = common:split(timeTable[3],":")[2];
    tb["sec"] = common:split(timeTable[3],":")[3];
    tb["isdst"] = false;
    return tb
end
function CSTools.GetserverTimes()
	local  locTime 
    if Golb_Platform_Info.is_r2_platform then
        locTime = time(CSTools.GetServerDate())
        --locTime  = GamePrecedure:getInstance():getServerTime()+(LocalOffset_UTCTime - ServerOffset_UTCTime + 3600)--3600夏令时一小时时差
    else
        locTime  = GamePrecedure:getInstance():getServerTime()+(LocalOffset_UTCTime - ServerOffset_UTCTime)
    end
   
    
   -- local  locTime = GamePrecedure:getInstance():getServerTime()
	return locTime
end

--------------------------------------------------------------
return CSTools
