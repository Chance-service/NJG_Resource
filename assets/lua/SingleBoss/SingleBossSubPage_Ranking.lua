local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "SingleBossSubPage_Main"
local HP_pb = require("HP_pb")
local SingleBossDataMgr = require("SingleBoss.SingleBossDataMgr")

local SingleBossRankingBase = { }

local RewardItems = { }

local option = {
    ccbiFile = "SingleBoss_Ranking.ccbi",
    handlerMap = {
        onHelp = "onHelp",
        onRankingReward = "onRankingReward",
    }
}

local parentPage = nil
local data = SingleBossDataMgr:getPageData()

local opcodes = {
    ACTIVITY193_SINGLE_BOSS_S = HP_pb.ACTIVITY193_SINGLE_BOSS_S,
}
-------------------- scrollview item --------------------------------
local SingleBossRankContent = {
    ccbiFile = "SingleBoss_RankingContent.ccbi",
}

function SingleBossRankContent:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleBossRankContent:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh(self.container)
end

function SingleBossRankContent:refresh(container)
    local visible = { }
    local str = { }
    --
    str["mPlayerName"] = self.rankData.name
    str["mPlayerScore"] = GameUtil:formatDotNumber(self.rankData.score)
    str["mRankText"] = (not self.rankData.rank or self.rankData.rank < 1) and "-" or self.rankData.rank

    local showRankImg = (self.rankData.rank and self.rankData.rank >= 1 and self.rankData.rank <= 3) and true or false
    visible["mRankText"] = (not showRankImg)
    visible["mRankSprite"] = showRankImg
    if showRankImg then
        NodeHelper:setSpriteImage(container, { mRankSprite = GameConfig.ArenaRankingIcon[self.rankData.rank] })
    end
    --
    local headIcon = self.rankData.headIcon
    local roleIcon = ConfigManager.getRoleIconCfg()
    if not roleIcon[headIcon] then
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[0].MainPageIcon })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[headIcon].MainPageIcon })
    end
    visible["mSelectTxt"] = false
    visible["mSelectFrame"] = false
    visible["mLvNode"] = false
    --
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, str)
end
--------------------

function SingleBossRankingBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function SingleBossRankingBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container,eventName)
        end
    end)
    
    return container
end

function SingleBossRankingBase:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    -- 背景Spine
    local bgParent = self.container:getVarNode("mBgNode")
    bgParent:removeAllChildrenWithCleanup(true)
    local bgSpine = SpineContainer:create("Spine/NGUI", "NGUI_94_soloenemy")
    local bgSpineNode = tolua.cast(bgSpine, "CCNode")
    bgParent:addChild(bgSpineNode)
    bgSpine:setToSetupPose()
    bgSpine:runAnimation(1, "animation2", -1)
    bgSpineNode:setScale(NodeHelper:getTargetScaleProportion(1600, 720))

    local scrollView = container:getVarScrollView("mContent")

    NodeHelper:setNodesVisible(container, { mTopFrame = false })
    self:InfoReq()
end

function SingleBossRankingBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SINGLE_BOSS)
end	

function SingleBossRankingBase:onExit(container)

end
function SingleBossRankingBase:onExecute(container)

end

function SingleBossRankingBase:onRankingReward(container)
    data.popType = SingleBossDataMgr.PopPageType.RANK_REWARD
    data.popStage = nowStage
    PageManager.pushPage("SingleBoss.SingleBossPopPage")
end	

function SingleBossRankingBase:InfoReq()
    local msg = Activity5_pb.SingleBossReq()
    msg.action = SingleBossDataMgr.ProtoAction.SYNC_RANKING
    common:sendPacket(HP_pb.ACTIVITY193_SINGLE_BOSS_C, msg, true)
end

function SingleBossRankingBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACTIVITY193_SINGLE_BOSS_S then
        local msg = Activity5_pb.SingleBossResp()
        msg:ParseFromString(msgBuff)
        if msg.action == SingleBossDataMgr.ProtoAction.SYNC_RANKING then
            data.rankData = msg.rankingInfo
            self:refreshPage(self.container)
        end
    end
end

function SingleBossRankingBase:refreshPage(container)
    if not data.rankData.selfRankItem then
        return
    end
    local selfData = data.rankData.selfRankItem
    local visible = { }
    local str = { }
    --
    str["mPlayerName"] = selfData.name
    str["mPlayerScore"] = GameUtil:formatDotNumber(selfData.score)
    str["mRankText"] = (not selfData.rank or selfData.rank < 1) and "-" or selfData.rank

    local showRankImg = (selfData.rank and selfData.rank >= 1 and selfData.rank <= 3) and true or false
    visible["mRankText"] = (not showRankImg)
    visible["mRankSprite"] = showRankImg
    if showRankImg then
        NodeHelper:setSpriteImage(container, { mRankSprite = GameConfig.ArenaRankingIcon[selfData.rank] })
    end
    --
    local headIcon = selfData.headIcon
    local roleIcon = ConfigManager.getRoleIconCfg()
    if not roleIcon[headIcon] then
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[0].MainPageIcon })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[headIcon].MainPageIcon })
    end
    visible["mSelectTxt"] = false
    visible["mSelectFrame"] = false
    visible["mLvNode"] = false
    --
    visible["mTopFrame"] = true
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, str)
    --
    local Scrollview = container:getVarScrollView("mContent")
    Scrollview:removeAllCell()
    local rankData = data.rankData.otherRankItem
    for i = 1, #rankData do
        local cell = CCBFileCell:create()
        local handler = common:new({ id = i, rankData = rankData[i] }, SingleBossRankContent)
        cell:registerFunctionHandler(handler)
        cell:setCCBFile(SingleBossRankContent.ccbiFile)
        Scrollview:addCellBack(cell)
    end
    Scrollview:orderCCBFileCells()
    Scrollview:setTouchEnabled(true)
end

function SingleBossRankingBase:onReceiveMessage(message)
    local typeId = message:getTypeId()
end

return SingleBossRankingBase
