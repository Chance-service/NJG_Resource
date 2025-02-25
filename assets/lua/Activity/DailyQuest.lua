local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "DailyQuest"
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require "Item.ItemManager"
local dailyQuest_pb = require("dailyQuest_pb")
local DailyQuestCfg = {}
local DailyQuestInfo = {}
local ButtonStatus = {}--按钮状态 1：领取奖励  0：前往完成
--[[
    DAILY_QUEST_INFO_C = 90011;
	DAILY_QUEST_INFO_S = 90012;
	
	//领取日常任务奖励
	TAKE_DAILY_QUEST_AWARD_C = 90013;
	TAKE_DAILY_QUEST_AWARD_S = 90014;

    message HPDailyQuestInfo
    {
    }
    // S -> C 所有任务信息反馈
    message HPDailyQuestInfoRet
    {
	    repeated QuestItem allDailyQuest = 1; //所有的任务信息
    }
    //C->S 请求领取任务奖励  ID
    message HPTakeDailyQuestAward
    {
	    required int32 questId = 1;//任务Id
    }

    message QuestItem 
    {
	    required int32 questId = 1;//任务Id
	    required int32 takeStatus = 2;//领取状态   0:未领取的任务 1:已经领取 
	    required int32 questStatus = 3;//任务状态   0:未完成 1:已经完成
	    required string taskRewards = 4;//任务奖励
	    required int32 questCompleteCount = 5;//完成目标数量

    }
]]--
local DailyQuest = {}
local opcodes = {
    DAILY_QUEST_INFO_C 	= HP_pb.DAILY_QUEST_INFO_C,
    DAILY_QUEST_INFO_S	= HP_pb.DAILY_QUEST_INFO_S,
    TAKE_DAILY_QUEST_AWARD_C    = HP_pb.TAKE_DAILY_QUEST_AWARD_C,
    TAKE_DAILY_QUEST_AWARD_S	= HP_pb.TAKE_DAILY_QUEST_AWARD_S,
}
local QuestContent = {
    ccbiFile = "Act_DailyMissionContent.ccbi"
}
local thisContainer = nil

function DailyQuest.onFunction(eventName, container)
    if eventName == "onWishing" then
		
    elseif eventName == "onStageReward" then
		
    elseif eventName == "onRankReward" then
	
    end
end

function DailyQuest:onEnter(ParentContainer)
    self.container = ScriptContentBase:create("Act_DailyMissionPage.ccbi")
    self.container:registerFunctionHandler(DailyQuest.onFunction)
    NodeHelper:initScrollView(self.container, "mContent", 3)
    DailyQuestCfg = ConfigManager.getDailyQuestCfg()
    thisContainer = self.container
    self:registerPacket(ParentContainer)
    self:getActivityInfo()
    --self:refreshPage()
    return self.container
end

function DailyQuest:onExecute(ParentContainer)
	
end

function DailyQuest:refreshPage()
    self:rebuildAllItem()
end

function splitTiem(itemInfo)
    local items = {}
    for _, item in ipairs(common:split(itemInfo, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"))
        table.insert(items, {
            type 	= tonumber(_type),
            itemId	= tonumber(_id),
            count 	= tonumber(_count)
        })
    end
    return items
end
--点击物品显示tips
function QuestContent:onClickItemFrame(container,eventName)
    local rewardIndex = tonumber(eventName:sub(8))--数字
    local index = container:getItemDate().mID
    local itemInfo = DailyQuestInfo[index]
    if not itemInfo then
        return
    end
    local rewardItems = splitTiem(itemInfo.taskRewards)
    GameUtil:showTip(container:getVarNode("mPic" .. rewardIndex), rewardItems[rewardIndex])
end
----------------scrollview-------------------------

function QuestContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        QuestContent.onRefreshItemView(container)
    elseif eventName == "onRewardBtn" then --按钮状态 1：领取奖励  0：前往完成 2:已领取
        local index = container:getItemDate().mID
        local ItemInfo = DailyQuestInfo[index]
        local ItemCfg = DailyQuestCfg[ItemInfo.questId]
        if ButtonStatus[index] == 1 then --
            QuestContent.getRewards(ItemInfo.questId)
        elseif ButtonStatus[index] == 0 then --前往完成--页面跳转
            --[[
            1.每日签到	
            2.每日充值（无限额）	
            3.每日充值（有限额）	
            4.快速战斗	
            5.Facebook分享	
            ]]--
            if ItemCfg.typeid == 2 or ItemCfg.typeid == 3 then
                PageManager.pushPage("RechargePage")
            elseif ItemCfg.typeid == 4 then
                PageManager.refreshPage("MainScenePage","DailyQuest")
                --PageManager.popPage("WelfarePage")
                --MainFrame:getInstance():onMenuItemAction("onBattlePageBtn" , nil)

            elseif ItemCfg.typeid == 5 then
                MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn", nil)
                PageManager.changePage("EquipmentPage")
            end
        end
    elseif eventName:sub(1, 7) == "onFrame" then
        QuestContent:onClickItemFrame(container, eventName)
    end
end
function QuestContent.getRewards(id)
    local msg = dailyQuest_pb.HPTakeDailyQuestAward()
    msg.questId = id
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.TAKE_DAILY_QUEST_AWARD_C, pb, #pb, true)
end
function QuestContent.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local ItemInfo = DailyQuestInfo[index]
    local ItemCfg = DailyQuestCfg[ItemInfo.questId]
    local DailyMissionName = ""
    local TextTable = {}
    if ItemCfg.targetcount == 0 then
        DailyMissionName = common:getLanguageString(ItemCfg.detail)
    else
        DailyMissionName = common:getLanguageString(ItemCfg.detail,ItemInfo.questCompleteCount.."/"..ItemCfg.targetcount)
    end
    TextTable["mActDailyMissionName"] = DailyMissionName
    local rewards = splitTiem(ItemInfo.taskRewards)
    NodeHelper:fillRewardItemWithParams(container, rewards, 4, { showHtml = false })
    
    --[[
        message QuestItem 
        {
	        required int32 questId = 1;//任务Id
	        required int32 takeStatus = 2;//领取状态   0:未领取的任务 1:已经领取 
	        required int32 questStatus = 3;//任务状态   0:未完成 1:已经完成
	        required string taskRewards = 4;//任务奖励
	        required int32 questCompleteCount = 5;//完成目标数量

        }
    ]]--
    --按钮状态 1：领取奖励  0：前往完成 2:已领取
    local BtnEnabled = false
    local BtnText = ""
    if ItemInfo.questStatus == 0 then --0:未完成
        ButtonStatus[index] = 0
        BtnText = "@ActDailyMissionBtn_Go"
        BtnEnabled = true
    elseif ItemInfo.questStatus == 1 then --1:已经完成
        if ItemInfo.takeStatus == 0 then --未领取
            ButtonStatus[index] = 1
            BtnText = "@ActDailyMissionBtn_Receive"
            BtnEnabled = true
        elseif ItemInfo.takeStatus == 1 then --已领取 按钮置灰
            --mRewardDayBtn
            ButtonStatus[index] = 2
            BtnEnabled = false
            BtnText = "@ActDailyMissionBtn_Finish"
        end
    end
    TextTable["mReceiveText"] = common:getLanguageString(BtnText)
    container:getVarMenuItemImage("mRewardDayBtn"):setEnabled(BtnEnabled)
    NodeHelper:setStringForLabel(container, TextTable)
end

function DailyQuest:rebuildAllItem()
    self:clearAllItem()
    self:buildItem()
end

function DailyQuest:clearAllItem()
    NodeHelper:clearScrollView(self.container)
end

function DailyQuest:buildItem()
    local size = #DailyQuestInfo
    NodeHelper:buildScrollView(self.container, size, QuestContent.ccbiFile, QuestContent.onFunction)
end

function DailyQuest:getActivityInfo()
    common:sendEmptyPacket(opcodes.DAILY_QUEST_INFO_C, true)
end
local function sortInfoList(info)
    table.sort(info, function ( e1, e2 )
        if not e2 then return true end
        if not e1 then return false end				

        if e1.questId < e2.questId then
            return true
        else
            return false
        end
    end)
end
local function sortQuestInfo(info)
    sortInfoList(info)
    local finshList = {}
    local othersList = {}
    DailyQuestInfo = {}
    for i = 1, #info do
        if info[i].questStatus == 1 and info[i].takeStatus == 1 then
            table.insert(finshList, info[i])
        else
            table.insert(othersList, info[i])
        end
    end
    for i = 1, #othersList do
        table.insert(DailyQuestInfo, othersList[i])
    end
    for i = 1, #finshList do
        table.insert(DailyQuestInfo, finshList[i])
    end
end
function DailyQuest:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.DAILY_QUEST_INFO_S or opcode == opcodes.TAKE_DAILY_QUEST_AWARD_S then
        local msg = dailyQuest_pb.HPDailyQuestInfoRet()
        msg:ParseFromString(msgBuff)
        --DailyQuestInfo = msg.allDailyQuest;
        sortQuestInfo(msg.allDailyQuest)
        self:refreshPage()
    elseif opcode == opcodes.TAKE_DAILY_QUEST_AWARD_S then

    end
end
function DailyQuest:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function DailyQuest:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function DailyQuest:onExit(ParentContainer)
    NodeHelper:deleteScrollView(thisContainer)
    self:removePacket(ParentContainer)
end
return DailyQuest
