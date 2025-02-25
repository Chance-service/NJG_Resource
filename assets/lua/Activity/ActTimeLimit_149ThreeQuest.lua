local thisPageName = "ActTimeLimit_149ThreeQuest"
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb")
local ConfigManager = require("ConfigManager")
local UserItemManager = require("Item.UserItemManager")
local MissionManager = require("MissionManager")
local NewPlayerBasePage = require("NewPlayerBasePage")
local CONST = require("Battle.NewBattleConst")
require("Activity.ActivityInfo")

local ActTimeLimit_149ThreeQuest = {
    container = nil,
}
--活動相關參數
local QUEST_PARAS = {
    ITEM_NUM = 3,
    BG_SPINE_PATH = "Spine/Activity_143_sp_boxes",
    BG_SPINE_NAME = "Activity_143_sp_boxes",
    SHOW_ROLE_ID = 1,
}
-- 協定相關參數
local REQUEST_TYPE = {
    SYNC = 0, -- 0.同步
    OPEN = 1, -- 1.領獎
}
-- 遊戲狀態參數
local GAME_STATE = {
    ERROR = -1,
    SYNC_DATA = 0,
    STABLE = 1,
    REQUEST_REWARD = 2,
}
-- 玩家當前遊戲資料
local nowData = {
    taskInfo = { }, -- 任務資料
}

local option = {
    ccbiFile = "NewPlayer_3day.ccbi",
    handlerMap = {
        onClaim = "onClaim",
        onHelp = "onHelp",
        onHand = "onHand",
    },
    opcodes = {
        QUEST_SINGLE_UPDATE_S = HP_pb.QUEST_SINGLE_UPDATE_S,
        QUEST_GET_SINGLE_QUEST_REWARD_C = HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C,
        QUEST_GET_NEWBIE_LIST_C = HP_pb.QUEST_GET_NEWBIE_LIST_C,
        QUEST_GET_NEWBIE_LIST_S = HP_pb.QUEST_GET_NEWBIE_LIST_S,
    }
}

local questCfg = ConfigManager:getQuestCfg()
local nowState = GAME_STATE.SYNC_DATA
local items = { }
-------------------- reward item --------------------------------
local RewardItem = {
    ccbiFile = "DayLogin30Item.ccbi",
}
-----------------------------------------------------------------
function ActTimeLimit_149ThreeQuest:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function ActTimeLimit_149ThreeQuest:onEnter(container)
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(option.ccbiFile)
    end
    self.container:registerFunctionHandler(ActTimeLimit_149ThreeQuest.onFunction)
    NodeHelper:setNodesVisible(self.container, { mMessageNode = false })
    self:setGameState(container, GAME_STATE.SYNC_DATA)
    self:registerPacket(container)
    self:initRewardItem(self.container)
    self:initSpine(self.container)
    self:requestServerData(REQUEST_TYPE.SYNC)
    return self.container
end

function ActTimeLimit_149ThreeQuest:onExit(container)
    self:removePacket(container)
end
------------------------------------- 按鈕 ---------------------------------------------
-- 領取最終獎勵
function ActTimeLimit_149ThreeQuest:onClaim(container)
    if nowState ~= GAME_STATE.STABLE then
        return
    end
    if nowData.taskInfo[4].questState == Const_pb.FINISHED then -- 可領獎
        self:setGameState(container, GAME_STATE.REQUEST_REWARD)
        ActTimeLimit_149ThreeQuest:requestServerData(REQUEST_TYPE.OPEN, 4)
    end
end
-- 領取任務獎勵
function ActTimeLimit_149ThreeQuest:onClick(container)
    if nowState ~= GAME_STATE.STABLE then
        return
    end
    local index = container.id
    if nowData.taskInfo[index].questState == Const_pb.FINISHED then -- 可領獎
        self:setGameState(container, GAME_STATE.REQUEST_REWARD)
        ActTimeLimit_149ThreeQuest:requestServerData(REQUEST_TYPE.OPEN, index)
    else
        local itemType, id, itemCount = unpack(common:split(nowData.taskInfo[index].taskRewards, "_"))
        GameUtil:showTip(container:getVarNode("mItemNode"), { type = tonumber(itemType), itemId = tonumber(id), count = tonumber(itemCount) })
    end
end
-- 規則說明
function ActTimeLimit_149ThreeQuest:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_THREEQUEST)
end
-- 角色點擊
function ActTimeLimit_149ThreeQuest:onHand(container)
    local rolePage = require("NgArchivePage")
    PageManager.pushPage("NgArchivePage")
    rolePage:setMercenaryId(QUEST_PARAS.SHOW_ROLE_ID)
    --NgArchivePage_setToSkin(false, 1)
end
----------------------------------------------------------------------------------
function ActTimeLimit_149ThreeQuest:onExecute(container)
    local remainTime = NewPlayerBasePage:getActivityTime()
    local timeStr = common:second2DateString5(remainTime, false)
    NodeHelper:setStringForLabel(self.container, { mTimerTxt = timeStr })
end
----------------------------------------------------------------------------------
-- 獎勵ccb初始化
function ActTimeLimit_149ThreeQuest:initRewardItem(container)
    items = { }
    for i = 1, QUEST_PARAS.ITEM_NUM do
        local itemParentNode = container:getVarNode("mTaskNode" .. i)
        itemParentNode:removeAllChildren()

        local itemCCB = ScriptContentBase:create(RewardItem.ccbiFile)
        if itemCCB then
            itemCCB.id = i
            itemCCB:setAnchorPoint(ccp(0.5, 0.5))
            itemCCB:registerFunctionHandler(ActTimeLimit_149ThreeQuest.onFunction)
            itemParentNode:addChild(itemCCB)
            table.insert(items, itemCCB)
        end
    end
end
-- spine初始化
function ActTimeLimit_149ThreeQuest:initSpine(container)
    local heroCfg = ConfigManager.getNewHeroCfg()[QUEST_PARAS.SHOW_ROLE_ID]
    if heroCfg then
        local parentNode = container:getVarNode("mSpineNode")
        parentNode:removeAllChildrenWithCleanup(true)
        local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
        if not NodeHelper:isFileExist(spineFolder .. "/" .. spineName .. "000.skel") then
            return
        end
        local spine = SpineContainer:create(spineFolder, spineName .. "000")
        local spineNode = tolua.cast(spine, "CCNode")
        spine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
        parentNode:addChild(spineNode)
    end
    -- BG
    local bg = self.container:getVarNode("mBg")
    local spineBg = SpineContainer:create("NG2D", "NG2D_01")
    local spineNodeBg = tolua.cast(spineBg, "CCNode")
    spineNodeBg:setScale(NodeHelper:getScaleProportion())
    spineBg:runAnimation(1, "animation", -1)
    bg:addChild(spineNodeBg)
end
-- 獲得獎勵演出
function ActTimeLimit_149ThreeQuest:playShowReward(container)
    local CommonRewardPage = require("CommPop.CommItemReceivePage")
    CommonRewardPage:setData(ConfigManager.parseItemOnlyWithUnderline("30000_104001_10"), common:getLanguageString("@ItemObtainded"), nil)
    PageManager.pushPage("CommPop.CommItemReceivePage")
    self:setGameState(container, GAME_STATE.STABLE)
    self:refreshItem(container)
    self:refreshUI(self.container)
end
-- 設定狀態
function ActTimeLimit_149ThreeQuest:setGameState(container, state)
    nowState = state
end
-- 刷新獎勵顯示
function ActTimeLimit_149ThreeQuest:refreshItem(container)
    for i = 1, QUEST_PARAS.ITEM_NUM do
        if nowData.taskInfo[i] then
            local reward = nowData.taskInfo[i].taskRewards
            local rewardType, rewardId, rewardCount = unpack(common:split(reward, "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(rewardType), tonumber(rewardId), tonumber(rewardCount))
            local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setSpriteImage(items[i], { mIconSprite = resInfo.icon, mDiBan = iconBgSprite })
            NodeHelper:setQualityFrames(items[i], { mQuality = resInfo.quality })

            NodeHelper:setStringForLabel(items[i], { mNumLabel = rewardCount })
            --local labelNode = self.container:getVarLabelTTF("mTaskTxt" .. i)
            --local htmlLabel = NodeHelper:addHtmlLable(labelNode, 
            --                  '<p style="text-align:center"><font color="#7F6C66">' .. 
            --                  common:getLanguageString(questCfg[nowData.taskInfo[i].id].content, questCfg[nowData.taskInfo[i].id].targetCount) .. 
            --                  '</font></p>', 
            --                  0, CCSize(200, 150), nil)
            local isGet = self:isGetReward(i)
            local isCanGet = self:isCanGetReward(i)
            NodeHelper:setNodesVisible(items[i], { mTodayNode = false, mMask = isGet, mGetSprite = isGet })
            local mDayLabel = items[i]:getVarLabelTTF("mDayLabel")
            if isGet then
                mDayLabel:setString(common:getLanguageString("@Receive"))
                mDayLabel:setColor(ccc3(248, 205, 127))
            elseif isCanGet then
                mDayLabel:setString(common:getLanguageString("@Receive"))
                mDayLabel:setColor(ccc3(56, 50, 53))
            else
                mDayLabel:setString(common:getLanguageString(questCfg[nowData.taskInfo[i].id].content, questCfg[nowData.taskInfo[i].id].targetCount))
                mDayLabel:setColor(ccc3(56, 50, 53))
            end
            for star = 1, 6 do
                NodeHelper:setNodesVisible(items[i], { ["mStar" .. star] = (star == resInfo.quality) and (tonumber(rewardType) == Const_pb.EQUIP * 10000) })
            end
        end
    end
end
-- 刷新介面顯示
function ActTimeLimit_149ThreeQuest:refreshUI(container)
    NodeHelper:setNodesVisible(self.container, { mMessageNode = true })
    self:refreshFinalQuestState()
    local isEnable = self:isCanGetFinalReward()
    NodeHelper:setMenuItemEnabled(container, "mClaimBtn", isEnable)
    NodeHelper:setStringForLabel(self.container, { mTaskProgressTxt = self:getCompleteNum() .. " / " .. QUEST_PARAS.ITEM_NUM })
end
-- 檢查獎勵是否已獲得
function ActTimeLimit_149ThreeQuest:isGetReward(index)
    return nowData.taskInfo[index].questState == Const_pb.REWARD
end
-- 檢查獎勵是否可獲得
function ActTimeLimit_149ThreeQuest:isCanGetReward(index)
    return nowData.taskInfo[index].questState == Const_pb.FINISHED
end
-- 檢查是否可領最終獎勵
function ActTimeLimit_149ThreeQuest:isCanGetFinalReward()
    return nowData.taskInfo[4].questState == Const_pb.FINISHED
end
-- 刷新最終任務狀態
function ActTimeLimit_149ThreeQuest:refreshFinalQuestState()
    if nowData.taskInfo[4].questState == Const_pb.ING then
        if self:isGetReward(1) and self:isGetReward(2) and self:isGetReward(3) then
            nowData.taskInfo[4].questState = Const_pb.FINISHED
        end 
    end
end
-- 已完成任務數量
function ActTimeLimit_149ThreeQuest:getCompleteNum()
    local count = 0
    for i = 1, QUEST_PARAS.ITEM_NUM do
        count = self:isGetReward(i) and count + 1 or count
    end
    return count
end
----------------------------------------------------------------------------------

-------------------------------------協定相關--------------------------------------
function ActTimeLimit_149ThreeQuest:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.QUEST_GET_NEWBIE_LIST_S then
        local msg = Quest_pb.HPGetQuestListRet()
		msg:ParseFromString(msgBuff)
		_lineTaskPacket, nowData.taskInfo = MissionManager.AnalysisPacket(msg)
        self:setGameState(container, GAME_STATE.STABLE)
        self:refreshItem(container)
        self:refreshUI(self.container)
    elseif opcode == HP_pb.QUEST_SINGLE_UPDATE_S then
        local msg = Quest_pb.HPQuestUpdate()
        msg:ParseFromString(msgBuff)
        local index = 1
        for i = 1, #nowData.taskInfo do
            if nowData.taskInfo[i].id == msg.quest.id then
                nowData.taskInfo[i] = msg.quest
                index = i
            end
        end
        local CommonRewardPage = require("CommonRewardPage")
        local rewards = common:split(nowData.taskInfo[index].taskRewards, ",")
        local parseReward = { }
        for i = 1, #rewards do
            table.insert(parseReward, ConfigManager.parseItemOnlyWithUnderline(rewards[i]))
        end
        local CommonRewardPage = require("CommPop.CommItemReceivePage")
        CommonRewardPage:setData(parseReward, common:getLanguageString("@ItemObtainded"), nil)
        PageManager.pushPage("CommPop.CommItemReceivePage")
        self:setGameState(container, GAME_STATE.STABLE)
        self:refreshItem(container)
        self:refreshUI(self.container)
    end
end
function ActTimeLimit_149ThreeQuest:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function ActTimeLimit_149ThreeQuest:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function ActTimeLimit_149ThreeQuest:requestServerData(type, index)
    if type == REQUEST_TYPE.SYNC then
        common:sendEmptyPacket(HP_pb.QUEST_GET_NEWBIE_LIST_C, true)
    elseif type == REQUEST_TYPE.OPEN then
        local msg = Quest_pb.HPGetSingeQuestReward()
        msg.questId = nowData.taskInfo[index].id
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C, pb, #pb, true) 
    end
end

function ActTimeLimit_149ThreeQuest.onFunction(eventName, container)
    if eventName == option.handlerMap.onClaim then
        ActTimeLimit_149ThreeQuest:onClaim(container)
    elseif eventName == option.handlerMap.onHelp then
        ActTimeLimit_149ThreeQuest:onHelp(container)
    elseif eventName == "onClick" then
        ActTimeLimit_149ThreeQuest:onClick(container)
    elseif eventName == option.handlerMap.onHand then
        ActTimeLimit_149ThreeQuest:onHand(container)
    end
end
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local ActPage = CommonPage.newSub(ActTimeLimit_149ThreeQuest, thisPageName, option)

return ActTimeLimit_149ThreeQuest