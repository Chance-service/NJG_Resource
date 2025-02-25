----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb") --包含协议id文件
local Quest_pb = require("Quest_pb")
local MissionManager = {}--商店类型

MissionManager._missionType = {
	MISSION_MAIN_TASK = 1,--主线任务
	MISSION_DAILY_TASK = 2,--每日任务
	MISSION_ACHIEVEMENT_TASK 	= 3,
}

MissionManager._curMissionType = MissionManager._missionType.MISSION_MAIN_TASK;
MissionManager._redPointStatus = {
    mainQuestStatus = 0;
    dailyQuestStatus = 0;
    achievementQuestStatus = 0;
}
MissionManager._missionInfo = {
	[MissionManager._missionType.MISSION_MAIN_TASK] = {
        _scriptName = "MissionWeeklyTask ",
        _helpFile = GameConfig.HelpKey.HELP_ACHIEVEMENT,
        _ccbi = "TaskDailyContent.ccbi",
    },--主线任务
	[MissionManager._missionType.MISSION_DAILY_TASK] = {
        _scriptName = "MissionDailyTask",
        _helpFile = GameConfig.HelpKey.HELP_ACHIEVEMENT,
        _ccbi = "TaskDailyContent.ccbi",
    },--每日任务
	[MissionManager._missionType.MISSION_ACHIEVEMENT_TASK] 	= {
        _scriptName = "MissionLineTask",
        _helpFile = GameConfig.HelpKey.HELP_ACHIEVEMENT,
        _ccbi = "TaskAgencyContent.ccbi",
    },--成就任务
}
function MissionManager.AnalysisPacket(msg)
    local questCfg = ConfigManager.getQuestCfg()
    local allPacket = {}
    local showTaskInfo = {}
    for i = 1,#msg.questList do
        local tempQuest = msg.questList[i]
        if allPacket[questCfg[tempQuest.id].team] == nil then
            allPacket[questCfg[tempQuest.id].team] = {}
        end --按照team分组
        table.insert(allPacket[questCfg[tempQuest.id].team], tempQuest)
    end
    for key, value in pairs( allPacket) do
        --对每一组进行排序
        table.sort(value, function (task1, task2)
            if not task1 then return true end
            if not task2 then return false end
            return task1.id < task2.id
        end);
    end
    --取第一个显示
    for key, value in pairs(allPacket) do
        if #value > 0 then
            table.insert(showTaskInfo, value[1])
            table.remove(value, 1)
        end
    end
    MissionManager.sortData(showTaskInfo)
    return allPacket, showTaskInfo
end
function MissionManager.sortData(_dataTable)
    --排序
    local questCfg = ConfigManager.getQuestCfg();
    table.sort( _dataTable,function (task1,task2)
        if task1.questState > task2.questState then
            return true
        elseif task1.questState < task2.questState then
            return false
        else
            return questCfg[task1.id].sortId < questCfg[task2.id].sortId
        end
        
    end);
end
function  MissionManager.getMissionInfo(missionType)
    local _type = missionType or MissionManager._curMissionType
    return MissionManager._missionInfo[_type]
end
function  MissionManager.getRedPointStatus()
    local msg = Quest_pb.HPGetQuestRedPointStatus()
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.QUEST_GET_QUEST_REDPOINT_C, pb, #pb, false)
end
function  MissionManager.setRedPointStatus(msg)
    MissionManager._redPointStatus.mainQuestStatus = msg.mainQuestStatus;
    MissionManager._redPointStatus.dailyQuestStatus = msg.dailyQuestStatus;
    MissionManager._redPointStatus.achievementQuestStatus = msg.achievementQuestStatus;
    require("Util.RedPointManager")
    RedPointManager_setShowRedPoint("MissionMainPage", 1, msg.mainQuestStatus == 1)
    RedPointManager_setShowRedPoint("MissionMainPage", 2, msg.dailyQuestStatus == 1)
    RedPointManager_setShowRedPoint("MissionMainPage", 3, msg.achievementQuestStatus == 1)
end
----------packet msg--------------------------
return MissionManager