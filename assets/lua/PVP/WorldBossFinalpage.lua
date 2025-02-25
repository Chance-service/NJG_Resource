----------------------------------------------------------------------------------
--[[
    世界boss奖励
--]]
----------------------------------------------------------------------------------

local thisPageName = "WorldBossFinalpage"
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local HP = require("HP_pb")
local WorldBoss_pb = require("WorldBoss_pb")
local WorldBossManager = require("PVP.WorldBossManager")
local roleCfg = { }

local opcodes = {
    FETCH_WORLD_BOSS_INFO_C = HP.FETCH_WORLD_BOSS_INFO_C,
    FETCH_WORLD_BOSS_INFO_S = HP.FETCH_WORLD_BOSS_INFO_S,
    BATTLE_FORMATION_C = HP.BATTLE_FORMATION_C,
    BATTLE_FORMATION_S = HP.BATTLE_FORMATION_S,
}

local option = {
    ccbiFile = "GVERewardPage.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onReturnBtn = "onReturn",
        onFrame1 = "onFrame1",
        onFrame2 = "onFrame2",
        onFrame3 = "onFrame3",
        onFrame4 = "onFrame4",
        onArena = "onArena",
        onRanking = "onRanking",
        onJoin = "onJoin",
    }
}

local tabSelect = 1 -- 1是个人 2是联盟
local myRank = nil

local WorldBossFinalpageBase = { }
----------------------------------------------------------
function WorldBossFinalpageBase:onEnter(container)
    self:registerPacket(container)
    container.mScrollView = container:getVarScrollView("mExchangeContent")
    roleCfg = ConfigManager.getRoleCfg()
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())

    local lb2Str = {
        mName = UserInfo.roleInfo.name,
        mSelfRanking = "-",--common:getLanguageString("@GVEMyRank", "-"),
        mDamage = 0
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setNodesVisible(container, { mRewardNode = false })

    NodeHelper:setNodesVisible(container, { mNoKIllMessageNode = false })
    self:sendMsgForWorldBossinfo(container)

    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)
end

function WorldBossFinalpageBase:onExecute(container)
end

function WorldBossFinalpageBase:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container)
end

function WorldBossFinalpageBase:refreshWorldBossSpine(container)
    local info = WorldBossManager.WorldBossAttrInfo
    if not info then return end

    local monsterCfg = ConfigManager.getNewMonsterCfg()
    local bossInfo = monsterCfg[info.npcId]
    if not bossInfo then return end

    local parent = container:getVarNode("mSpineNode")
    if not parent then return end

    parent:removeAllChildrenWithCleanup(true)
    local spinePath, spineName = unpack(common:split(bossInfo.Spine, ","))
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    spineNode:setScale(NodeHelper:getScaleProportion())
    spine:runAnimation(1, "wait_0", -1)
    parent:addChild(spineNode)
end

function WorldBossFinalpageBase:refreshFinalkill(container)
    if WorldBossManager.lastKingInfo == nil then
        -- PageManager.changePage("PVPActivityPage")
        -- MessageBoxPage:Msg_Box("@NoWorldBossInfo")
        return
    end

    local info = WorldBossManager.lastKingInfo
    if not info then return end

    local roleId = WorldBossManager.WorldBossAttrInfo.roleItemId
    local roleInfo = roleCfg[WorldBossManager.WorldBossAttrInfo.roleItemId]
    local lb2Str = {
        mKillTxt = common:getLanguageString("@GVEKillDesc", info.allianceName, info.playerName, roleInfo.name)
    }
    NodeHelper:setStringForLabel(container, lb2Str)
end

function WorldBossFinalpageBase:refreshMyRank(container)
    if tabSelect == 1 then
        myRank = WorldBossManager.curRank
    else
        myRank = WorldBossManager.curAllianceRank
    end
    local pSprite = container:getVarSprite("mRankImage")
    if myRank and myRank.rankIndex > 0 and myRank.rankIndex <= 3 then
        --pSprite:setTexture(GameConfig.ArenaRankingIcon[myRank.rankIndex])
        NodeHelper:setNodesVisible(container, { mSelfRanking = false })
        NodeHelper:setNodesVisible(container, { mRewardNode = true })
    else
        --pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
        NodeHelper:setNodesVisible(container, { mSelfRanking = true })
        local RankNode = container:getVarNode("mSelfRanking")
        RankNode:setPositionY(60)
        NodeHelper:setNodesVisible(container, { mRewardNode = false })
    end
    if not myRank or myRank.harm <= 0 then
        local lb2Str = {
            mName = UserInfo.roleInfo.name,
            mSelfRanking = "-",--common:getLanguageString("@GVEMyRank", "-"),
            mDamage = 0
        }
        NodeHelper:setStringForLabel(container, lb2Str)
    else
        local lb2Str = {
            mName = myRank.playerName,
            mSelfRanking = myRank.rankIndex,--common:getLanguageString("@GVEMyRank", myRank.rankIndex),
            mDamage = GameUtil:formatDotNumber(myRank.harm)
        }
        local myRewardCfg = ConfigManager.getRewardByString(myRank.rewardInfo)
        NodeHelper:fillRewardItemWithParams(container, myRewardCfg, 4, { picNode = "mPic", countNode = "mNumber" })
        NodeHelper:setStringForLabel(container, lb2Str)
    end
end

function WorldBossFinalpageBase:refreshPage(container)
    --if WorldBossManager.lastKingInfo == nil then
    if (WorldBossManager.BossState == 3 and #WorldBossManager.curRankList <= 0) or 
       ((WorldBossManager.BossState == 1 or WorldBossManager.BossState == 2) and #WorldBossManager.lastRankList <= 0) then
        self:refreshNoKill(container)
    end
    self:refreshWorldBossSpine(container)
    self:refreshFinalkill(container)
    self:refreshMyRank(container)
    self:rebuildAllItem(container)
    self:setSelectButton(container)
    self:setJoinButton(container)
    self:setBossHp(container)
end

function WorldBossFinalpageBase:refreshNoKill(container)
    -- boss没被击杀的情况
end

function WorldBossFinalpageBase:setJoinButton(container)
    local isEnable = WorldBossManager.BossState == 3
    NodeHelper:setMenuItemEnabled(container, "mJoinBtn", isEnable)
end

function WorldBossFinalpageBase:setBossHp(container)
    local curHp = WorldBossManager.WorldBossAttrInfo.currBossHp
    local maxHp = WorldBossManager.WorldBossAttrInfo.maxHp
    NodeHelper:setStringForLabel(container, { mHpTxt = curHp .. "/" .. maxHp })
    local hpBar = container:getVarScale9Sprite("mHpBar")
    local per = curHp / maxHp
    hpBar:setScaleX( math.max(0, math.min(1, per)) )
end

function WorldBossFinalpageBase:setSelectButton(container)
    NodeHelper:setMenuItemEnabled(container, "mRanking", false)
end
----------------click event------------------------

function WorldBossFinalpageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVE)
end

function WorldBossFinalpageBase:onReturn(container)
    PageManager.popPage(thisPageName)
end

function WorldBossFinalpageBase:onArena(container)
    if tabSelect == 2 then
        tabSelect = 1
        self:refreshMyRank(container)
        self:setSelectButton(container)
        self:rebuildAllItem(container)
    end
end

function WorldBossFinalpageBase:onRanking(container)
    if tabSelect == 1 then
        tabSelect = 2
        self:refreshMyRank(container)
        self:setSelectButton(container)
        self:rebuildAllItem(container)
    end
end

function WorldBossFinalpageBase:onJoin(container)
    require("NewBattleConst")

    local msg = Battle_pb.NewBattleFormation()
    msg.type = NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY
    msg.battleType = NewBattleConst.SCENE_TYPE.WORLD_BOSS
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, true)
end

function WorldBossFinalpageBase:onFrame1(container)
    if myRank then
        local rewardCfg = ConfigManager.getRewardByString(myRank.rewardInfo)
        GameUtil:showTip(container:getVarNode('mFrame1'), rewardCfg[1])
    end
end

function WorldBossFinalpageBase:onFrame2(container)
    if myRank then
        local rewardCfg = ConfigManager.getRewardByString(myRank.rewardInfo)
        GameUtil:showTip(container:getVarNode('mFrame2'), rewardCfg[2])
    end
end

function WorldBossFinalpageBase:onFrame3(container)
    if myRank then
        local rewardCfg = ConfigManager.getRewardByString(myRank.rewardInfo)
        GameUtil:showTip(container:getVarNode('mFrame3'), rewardCfg[3])
    end
end

function WorldBossFinalpageBase:onFrame4(container)
    if myRank then
        local rewardCfg = ConfigManager.getRewardByString(myRank.rewardInfo)
        GameUtil:showTip(container:getVarNode('mFrame4'), rewardCfg[4])
    end
end

----------------scrollview item-------------------------

local RankListItem = {
    ccbiFile = 'GVERewardContent.ccbi'
}

function RankListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        RankListItem.onRefreshItemView(container)
    end
end

function RankListItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    local info
    if tabSelect == 1 then
        local list = WorldBossManager.BossState == 3 and WorldBossManager.curRankList or WorldBossManager.lastRankList
        info = list[index]
    else
        info = WorldBossManager.lastAllianceRankList[index]
    end
    rewardCfg = ConfigManager.getRewardByString(info.rewardInfo)
    if not info then return end


    NodeHelper:setNodesVisible(container, { mTrophyBossBG01 = info.rankIndex == 1, mTrophyBossBG02 = info.rankIndex == 2, mTrophyBossBG03 = info.rankIndex == 3, })
    --
    local lb2Str = {
        mGuildName = info.playerName,
        mDamage = GameUtil:formatDotNumber(info.harm),
        mRankLabel = tostring(index)
    }

    local visible = { }
    visible.mRankLabel = index >= 4
    --visible.mRankImage = index < 4

    local pSprite = container:getVarSprite("mRankImage")
    if index > 0 and index < 4 then
        NodeHelper:setSpriteImage(container, { mRankImage = GameConfig.ArenaRankingIcon[index] })
    else
        NodeHelper:setSpriteImage(container, { mRankImage = GameConfig.ArenaRankingIcon[4] })
    end

    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setLabelOneByOne(container, "mHurt", "mHurtNum")
end	

----------------scrollview-------------------------
function WorldBossFinalpageBase:rebuildAllItem(container)
    container.mScrollView:removeAllCell()
    local size = 0
    if tabSelect == 1 then
        local list = WorldBossManager.BossState == 3 and WorldBossManager.curRankList or WorldBossManager.lastRankList
        size = #list
    else
        size = #WorldBossManager.lastAllianceRankList
    end

    NodeHelper:buildCellScrollView(container.mScrollView, size, RankListItem.ccbiFile, RankListItem)
end

function WorldBossFinalpageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function WorldBossFinalpageBase:buildItem(container)
    local list = WorldBossManager.BossState == 3 and WorldBossManager.curRankList or WorldBossManager.lastRankList
    NodeHelper:buildScrollView(container, list - 1, RankListItem.ccbiFile, RankListItem.onFunction)
end

----------------------------------------------------------------
function WorldBossFinalpageBase:sendMsgForWorldBossinfo(container)
    common:sendEmptyPacket(opcodes.FETCH_WORLD_BOSS_INFO_C, true)
end

function WorldBossFinalpageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.FETCH_WORLD_BOSS_INFO_S then
        local msg = WorldBoss_pb.HPWorldBossInfo()
        msg:ParseFromString(msgBuff)

        WorldBossManager.ReceiveHPWorldBossInfo(msg)
        self:refreshPage(container)
        return
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == NewBattleConst.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            local battlePage = require("NgBattlePage")
            resetMenu("mBattlePageBtn", true)
            require("NewBattleConst")
            --require("NgBattleDataManager")
            NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.WORLD_BOSS)
            PageManager.changePage("NgBattlePage")
	        --battlePage:requestTeamInfo(container)
            battlePage:onWorldBoss(container, msg.resultInfo, msg.battleId, msg.battleType)
        end
    end
end

function WorldBossFinalpageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function WorldBossFinalpageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local WorldBossFinalpage = CommonPage.newSub(WorldBossFinalpageBase, thisPageName, option)
