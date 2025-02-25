
local AchievementManager = {}
local HP_pb = require("HP_pb")
local Quest_pb = require("Quest_pb")
local Const_pb = require("Const_pb")
local achievementCfg = ConfigManager.getAchievementCfg()
local achievementSkipCfg = ConfigManager.getAchievementSkipCfg()

AchievementManager.AchievementState = 0     -- 当前任务阶段
AchievementManager.QuestList = {}       -- 当前阶段任务列表
AchievementManager.CompleteList = {}    -- 已完成任务列表

function AchievementManager:getAchievementInfo(id)
    return achievementCfg[id] or {}
end

-- 根据任务类型，跳转到相应页面 Const_pb中定义enum QuestEventType
-- achievementSkip.txt技术同学维护
-- id字段表示Const_pb中任务类型
-- questTypeName字段没有用到，为了对应任务类型和页面
-- pageName字段表示跳转的页面名字，其中“nil”代表不能通过change或push跳转，例如战斗和聊天页面 须根据pageType特殊处理
-- pageType字段表示跳转页面方式，其中:0:change; 1:push; 2:战斗页面 3：聊天页面
-- LevelLimit字段表示有些功能根据等级开放，加一次判断
function AchievementManager:changePageByType(achievementType)
    local UserInfo = require("PlayerInfo.UserInfo")
    local skipInfo = achievementSkipCfg[achievementType]
    if skipInfo == nil or skipInfo == {} then return end

    -- 判断等级限制
    local levelLimit = skipInfo.LevelLimit
    UserInfo.sync()
    if UserInfo.roleInfo.level < levelLimit then
        MessageBoxPage:Msg_Box(common:getLanguageString("@LevelLimitText",levelLimit))
        return
    end

    if skipInfo.pageType == 0 then
        PageManager.changePage(skipInfo.pageName)
    elseif skipInfo.pageType == 1 then
        PageManager.popPage("AchievementPage")
        PageManager.pushPage(skipInfo.pageName)
    elseif skipInfo.pageType == 2 then  -- 战斗
        PageManager.popPage("AchievementPage")
		PageManager.showFightPage()
        PageManager.refreshPage("BattlePage", "Battle")
    elseif skipInfo.pageType == 3 then  -- 聊天
        PageManager.popPage("AchievementPage")
        PageManager.showFightPage();
        PageManager.refreshPage("BattlePage", "WorldChat")
    end

end

-- 当前任务列表中，已完成并领奖的任务数量
function AchievementManager:calCurFinishedNum()
    local count = 0
    for i = 1, #AchievementManager.QuestList do 
        if AchievementManager.QuestList[i].questState == Const_pb.REWARD then
            count = count + 1
        end
    end
    return count
end

function AchievementManager:finishedNumToPercentStr()
    local num = AchievementManager:calCurFinishedNum()
    local progressStr = string.sub(tostring(num / #AchievementManager.QuestList * 100), 1, 2) .. "%"
    if num == #AchievementManager.QuestList then
        progressStr = "100%"
    end
    return progressStr
end

-- 筛选已完成列表
function AchievementManager:filterFinishedList(completeList)
    local nameList = {}
    for i = 1, #completeList do
        local info = AchievementManager:getAchievementInfo(completeList[i])
        if not common:table_hasValue(nameList, info.name) then 
            table.insert(nameList, info.name)
        end
    end

    local finishedList = {}
    for i = 1, #nameList do
        local idTemp = {}
        for j = 1, #completeList do
            local info = AchievementManager:getAchievementInfo(completeList[j])
            if info.name == nameList[i] then
                table.insert(idTemp, info.id)
            end
        end
        table.insert(finishedList, idTemp[#idTemp])
    end

    return finishedList
end

-- 筛选成就列表，已完成的排到后面
function AchievementManager:filterQuestList(questList)
    local list ={}
    for i = 1,#questList do 
        if questList[i].questState == 2 then
            table.insert(list,questList[i])
        end
    end
    for i = 1,#questList do 
        if questList[i].questState == 1 then
            table.insert(list,questList[i])
        end
    end
    for i = 1,#questList do 
        if questList[i].questState == 3 then
            table.insert(list,questList[i])
        end
    end
    return list
end
-------------------------------------------------------------------
-- 请求任务数据
function AchievementManager:requestAchievementInfo()
    common:sendEmptyPacket(HP_pb.QUEST_GET_QUEST_LIST_C)
end

-- 返回任务数据 
function AchievementManager:receiveAchievementInfo(msg)
    AchievementManager.QuestList = AchievementManager:filterQuestList(msg.questList)
    AchievementManager.CompleteList = AchievementManager:filterFinishedList(msg.finishedQuestList)
end

-- 单个任务领取奖励
function AchievementManager:singleReward(id)
    local msg = Quest_pb.HPGetSingeQuestReward()
    msg.questId = id
    common:sendPacket(HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C, msg, false)
end

-- 更新任务
function AchievementManager:updateQuest(questInfo)
    for i = 1, #AchievementManager.QuestList do
        if AchievementManager.QuestList[i].id == questInfo.id then
            AchievementManager.QuestList[i].questState = questInfo.questState
            AchievementManager.QuestList[i].finishedCount = questInfo.finishedCount
            break
        end
    end
    self:updateRedPoint()
end
-- 判断是否取消外面的红点
function AchievementManager:updateRedPoint()
    -- 取消外面的红点 
    local finishState = false
    for i=1,#AchievementManager.QuestList do
        if AchievementManager.QuestList[i].questState == 2 then
            finishState = true
            break
        end
    end
    local  progressNum = AchievementManager:calCurFinishedNum() / #AchievementManager.QuestList
    if progressNum == 1 then
        finishState = true;
    end
    if finishState==false then
        local message = MsgMainFrameGetNewInfo:new()
        NoticePointState.ACHIEVEMENT_POINT = GameConfig.NewPointType.ACHIEVEMENT_POINT_CLOSE
        message.type = GameConfig.NewPointType.ACHIEVEMENT_POINT_CLOSE
        MessageManager:getInstance():sendMessageForScript(message)
    else
        local message = MsgMainFrameGetNewInfo:new()
        NoticePointState.ACHIEVEMENT_POINT = Const_pb.ACHIEVEMENT_POINT
        message.type = Const_pb.ACHIEVEMENT_POINT
        MessageManager:getInstance():sendMessageForScript(message)
    end
end

-- 阶段任务完成领取奖励
function AchievementManager:stepReward()
    common:sendEmptyPacket(HP_pb.QUEST_GET_STEP_QUEST_REWARD_C,false)
end

function AchievementManager:reset()
    AchievementManager.AchievementState = 0     -- 当前任务阶段
    AchievementManager.QuestList = {}       -- 当前阶段任务列表
    AchievementManager.CompleteList = {}    -- 已完成任务列表
end


return AchievementManager
