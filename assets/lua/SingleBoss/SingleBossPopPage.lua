local CommItem = require("CommUnit.CommItem")
local InfoAccesser = require("Util.InfoAccesser")
local SingleBossDataMgr = require("SingleBoss.SingleBossDataMgr")
local Activity5_pb = require("Activity5_pb")

local thisPageName = "SingleBoss.SingleBossPopPage"

local opcodes = {
    ACTIVITY193_SINGLE_BOSS_S = HP_pb.ACTIVITY193_SINGLE_BOSS_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

local option = {
    ccbiFile = "SingleBoss_CommonPopup.ccbi",
    handlerMap =
    {
        onClose = "onClose",
    },
    opcode = opcodes
}

local SingleBossPopPage = { }

local missionCfg = ConfigManager.getSingleBossAchive()
local data = SingleBossDataMgr:getPageData()
local MISSION_BAR_WIDTH = 120
local MISSION_BAR_HEIGHT = 21
-----------------------------------
local ItemCCB = { }
function ItemCCB.onFunction(eventName, container)
    if eventName == "onHand1" then
        GameUtil:showTip(container:getVarNode("mPic1"), container.Reward)
    end
end
-------------------- scrollview item --------------------------------
local SingleBossMissionContent = {
    ccbiFile = "SingleBoss_MissionContent.ccbi",
}

function SingleBossMissionContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleBossMissionContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function SingleBossMissionContent:refresh(container)
    if container == nil then
        return
    end
    local serverData = self:getServerDataById(self.id)
    -- 顯示文字
    NodeHelper:setStringForLabel(container, {
        mName = self.cfg.name,
        mContent = self.cfg.content,
        mMissionCount = math.min(serverData.count, self.cfg.needCount) .. "/" .. self.cfg.needCount,
    })
    -- 按鈕狀態
    if self.cfg.needCount > serverData.count then  -- 未達成
        if self.cfg.isJump == 1 then    -- 跳轉
            NodeHelper:setStringForLabel(container, { mBtnTxt = common:getLanguageString("@ActDailyMissionBtn_Go") })
            NodeHelper:setMenuItemEnabled(container, "mBtn", true)
        else
            NodeHelper:setStringForLabel(container, { mBtnTxt = common:getLanguageString("@inProgress") })
            NodeHelper:setMenuItemEnabled(container, "mBtn", false)
        end
    else
        if serverData.isGot == 1 then   -- 已領取
            NodeHelper:setStringForLabel(container, { mBtnTxt = common:getLanguageString("@ActDailyMissionBtn_Finish") })
            NodeHelper:setMenuItemEnabled(container, "mBtn", false)
        else    --可領取
            NodeHelper:setStringForLabel(container, { mBtnTxt = common:getLanguageString("@ActDailyMissionBtn_Receive") })
            NodeHelper:setMenuItemEnabled(container, "mBtn", true)
        end
    end
    -- 進度條
    local bar = container:getVarScale9Sprite("mMissionBar")
    bar:setContentSize(CCSize(MISSION_BAR_WIDTH * math.min(1, math.max(0.14, serverData.count / self.cfg.needCount)), MISSION_BAR_HEIGHT))
    NodeHelper:setNodesVisible(container, { mMissionBar = (serverData.count > 0) })
    -- 獎勵道具
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.cfg.reward[1].type, self.cfg.reward[1].itemId, self.cfg.reward[1].count)
    local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
    local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
    NodeHelper:setMenuItemImage(container, { mHand1 = { normal = normalImage } })
    NodeHelper:setSpriteImage(container, { mPic1 = resInfo.icon, mFrameShade1 = iconBg })
    NodeHelper:setStringForLabel(container, { mNumber1_1 = self.cfg.reward[1].count })
    NodeHelper:setNodesVisible(container, { selectedNode = false, mPoint = false, nameBelowNode = false, mStarNode = false, mAncientStarNode = false })
end

function SingleBossMissionContent:onHand1(container)
    GameUtil:showTip(container:getVarNode('mPic1'), self.cfg.reward[1])
end

function SingleBossMissionContent:onBtn(container)
    local msg = Activity5_pb.SingleBossReq()
    msg.action = SingleBossDataMgr.ProtoAction.GET_MISSION_AWARD
    msg.choose = self:getQuestId(self.id)
    common:sendPacket(HP_pb.ACTIVITY193_SINGLE_BOSS_C, msg, true)
end

function SingleBossMissionContent:getServerDataById(id)
    if data == nil then
        return
    end
    for i = 1, #data.questData do
        if data.questData[i].id == id then
            return data.questData[i]
        end
    end
end

function SingleBossMissionContent:getQuestId(id)
    if data == nil then
        return
    end
    for i = 1, #data.questData do
        if data.questData[i].id == id then
            return data.questData[i].id
        end
    end
end

local SingleBossStageRewardContent = {
    ccbiFile = "SingleBoss_RewardContent.ccbi",
}

function SingleBossStageRewardContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleBossStageRewardContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function SingleBossStageRewardContent:refresh(container)
    if container == nil then
        return
    end
    NodeHelper:setStringForLabel(container, {
        mTitleTxt = common:getLanguageString("@SingleBossReward" .. string.format("%02d", self.id)) 
    })
    local reward = common:split(self.Reward, ",")
    for i = 1, 4 do
        local parentNode = container:getVarNode("mPosition" .. i)
        parentNode:removeAllChildrenWithCleanup(true)
        if reward[i] then
            local _type, _id, _num = unpack(common:split(reward[i], "_"))
            local itemInfo = InfoAccesser:getItemInfo(tonumber(_type), tonumber(_id), tonumber(_num))

            local ItemNode = ScriptContentBase:create("CommItem")
            ItemNode:setScale(0.8)
            ItemNode:registerFunctionHandler(ItemCCB.onFunction)
            ItemNode.Reward = itemInfo

            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_num))
            local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
            local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setMenuItemImage(ItemNode, { mHand1 = { normal = normalImage } })
            NodeHelper:setSpriteImage(ItemNode, { mPic1 = resInfo.icon, mFrameShade1 = iconBg })
            NodeHelper:setStringForLabel(ItemNode, { mNumber1_1 = tonumber(_num) })
            NodeHelper:setNodesVisible(ItemNode, { selectedNode = false, mPoint = false, nameBelowNode = false, mStarNode = false, mAncientStarNode = false })
            parentNode:addChild(ItemNode)
        end
    end
end

local SingleBossRankRewardContent = {
    ccbiFile = "SingleBoss_RewardContent.ccbi",
}

function SingleBossRankRewardContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleBossRankRewardContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function SingleBossRankRewardContent:refresh(container)
    if container == nil or not self.cfg then
        return
    end
    local rankTxt = ""
    if not self.preCfg then
        if self.cfg.minRank > 1 then
            rankTxt = "1-" .. self.cfg.minRank
        else
            rankTxt = common:getLanguageString("@GVGRankingTxt", self.cfg.minRank)
        end
    else
        local rankDiff = self.cfg.minRank - self.preCfg.minRank
        if rankDiff > 1 then
            rankTxt = (self.preCfg.minRank + 1) .. "-" .. self.cfg.minRank
        else
            rankTxt = common:getLanguageString("@GVGRankingTxt", self.cfg.minRank)
        end
    end
    NodeHelper:setStringForLabel(container, {
        mTitleTxt = rankTxt
    })
    local reward = common:split(self.cfg.reward, ",")
    for i = 1, 4 do
        local parentNode = container:getVarNode("mPosition" .. i)
        parentNode:removeAllChildrenWithCleanup(true)
        if reward[i] then
            local _type, _id, _num = unpack(common:split(reward[i], "_"))
            local itemInfo = InfoAccesser:getItemInfo(tonumber(_type), tonumber(_id), tonumber(_num))

            local ItemNode = ScriptContentBase:create("CommItem")
            ItemNode:setScale(0.8)
            ItemNode:registerFunctionHandler(ItemCCB.onFunction)
            ItemNode.Reward = itemInfo

            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_num))
            local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
            local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setMenuItemImage(ItemNode, { mHand1 = { normal = normalImage } })
            NodeHelper:setSpriteImage(ItemNode, { mPic1 = resInfo.icon, mFrameShade1 = iconBg })
            NodeHelper:setStringForLabel(ItemNode, { mNumber1_1 = tonumber(_num) })
            NodeHelper:setNodesVisible(ItemNode, { selectedNode = false, mPoint = false, nameBelowNode = false, mStarNode = false, mAncientStarNode = false })
            parentNode:addChild(ItemNode)
        end
    end
end
-----------------------------------
function SingleBossPopPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function SingleBossPopPage.onFunction(eventName, container)
    if eventName == "luaLoad" then
        SingleBossPopPage:onLoad(container)
    elseif eventName == "luaEnter" then
        SingleBossPopPage:onEnter(container)
    elseif eventName =="onClose" then
        SingleBossPopPage:onClose(container)
    elseif eventName =="luaReceivePacket" then
        SingleBossPopPage:onReceivePacket(container)
    end
end

function SingleBossPopPage:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function SingleBossPopPage:onEnter(container)
    if SingleBossData.popType == SingleBossDataMgr.PopPageType.MISSION then
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@TaskTitle") })
    elseif SingleBossData.popType == SingleBossDataMgr.PopPageType.STAGE_REWARD then
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@SingleBossStageReward") })
    elseif SingleBossData.popType == SingleBossDataMgr.PopPageType.RANK_REWARD then
        NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@MineRankPrize") })
    end
    container:registerFunctionHandler(SingleBossPopPage.onFunction)
    self.container = container
    self:registerPacket(container)
    self:refreshScrollView(container)
end
function SingleBossPopPage:onClose(container)
    PageManager.popPage(thisPageName)
end
-- 刷新滾動層內容
function SingleBossPopPage:refreshScrollView(container)
    local Scrollview = container:getVarScrollView("mContent")
    Scrollview:removeAllCell()
    -----------------------------------------
    if SingleBossData.popType == SingleBossDataMgr.PopPageType.MISSION then
        local canGetTable = { }
        local normalTable = { }
        local isGetTable = { }
        local missionCfg = ConfigManager.getSingleBossAchive()
        for i = 1, #missionCfg do
            if data.questData[missionCfg[i].id].isGot == 1 then
                table.insert(isGetTable, missionCfg[i])
            elseif missionCfg[i].needCount <= data.questData[missionCfg[i].id].count then
                table.insert(canGetTable, missionCfg[i])
            else
                table.insert(normalTable, missionCfg[i])
            end
        end
        local sortFn = function(data1, data2)
            if not data1 or not data2 then
                return false
            end
            if data1 == data2 then
                return false
            end
            if data1.sort < data2.sort then
                return true
            end
            if data1.sort > data2.sort then
                return false
            end
            if data1.id < data2.id then
                return true
            end
            return false
        end
        table.sort(canGetTable, sortFn)
        table.sort(normalTable, sortFn)
        table.sort(isGetTable, sortFn)
        for i = 1, #canGetTable do
            local cell = CCBFileCell:create()
            local handler = common:new({ id = canGetTable[i].id, cfg = canGetTable[i] }, SingleBossMissionContent)
            cell:registerFunctionHandler(handler)
            cell:setCCBFile(SingleBossMissionContent.ccbiFile)
            Scrollview:addCellBack(cell)
        end
        for i = 1, #normalTable do
            local cell = CCBFileCell:create()
            local handler = common:new({ id = normalTable[i].id, cfg = normalTable[i] }, SingleBossMissionContent)
            cell:registerFunctionHandler(handler)
            cell:setCCBFile(SingleBossMissionContent.ccbiFile)
            Scrollview:addCellBack(cell)
        end
        for i = 1, #isGetTable do
            local cell = CCBFileCell:create()
            local handler = common:new({ id = isGetTable[i].id, cfg = isGetTable[i] }, SingleBossMissionContent)
            cell:registerFunctionHandler(handler)
            cell:setCCBFile(SingleBossMissionContent.ccbiFile)
            Scrollview:addCellBack(cell)
        end
    elseif SingleBossData.popType == SingleBossDataMgr.PopPageType.STAGE_REWARD then
        local singleBossCfg = ConfigManager.getSingleBoss()
        if singleBossCfg[SingleBossData.popStage] then
            for i = 1, 99 do
                local reward = singleBossCfg[SingleBossData.popStage]["stageReward" .. i]
                if not reward then
                    break
                end
                local cell = CCBFileCell:create()
                local handler = common:new({ id = i, Reward = reward }, SingleBossStageRewardContent)
                cell:registerFunctionHandler(handler)
                cell:setCCBFile(SingleBossStageRewardContent.ccbiFile)
                Scrollview:addCellBack(cell)
            end
        end
    elseif SingleBossData.popType == SingleBossDataMgr.PopPageType.RANK_REWARD then
        local awardCfg = ConfigManager.getSingleBossRankAward()
        for i = 1, #awardCfg do
            local cell = CCBFileCell:create()
            local handler = common:new({ id = i, cfg = awardCfg[i], preCfg = awardCfg[i - 1] }, SingleBossRankRewardContent)
            cell:registerFunctionHandler(handler)
            cell:setCCBFile(SingleBossRankRewardContent.ccbiFile)
            Scrollview:addCellBack(cell)
        end
    end
    -----------------------------------------
    Scrollview:orderCCBFileCells()
    Scrollview:setTouchEnabled(true)
end

function SingleBossPopPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.ACTIVITY193_SINGLE_BOSS_S then
        local msg = Activity5_pb.SingleBossResp()
        msg:ParseFromString(msgBuff)
        if msg.action == SingleBossDataMgr.ProtoAction.GET_MISSION_AWARD then
            local baseInfo = msg.baseInfo
            if baseInfo then
                data.maxStage = baseInfo.maxClearStage
                data.maxScore = baseInfo.maxScore
                data.activityEndTime = baseInfo.endTime / 1000
                data.challangeTime = baseInfo.count
            end
            data.questData = msg.questInfo
            SingleBossPopPage:refreshScrollView(container)
        end
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)    
    end
end

local CommonPage = require('CommonPage')
local SingleBossPopPage = CommonPage.newSub(SingleBossPopPage, thisPageName, option)
