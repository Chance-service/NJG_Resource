local thisPageName = "Lobby2Page"

require("Util.RedPointManager")
local LockManager = require("Util.LockManager")
local RankRewardData=require("Ranking.ProfessionRankingRewardData")
local GuideManager = require("Guide.GuideManager")

local opcodes =
    {
        DUNGEON_LIST_INFO_S = HP_pb.DUNGEON_LIST_INFO_S,
    }
local option = {
    ccbiFile = "Lobby2.ccbi",
    handlerMap = {
        onBounty = "onBounty",
        onHollyGrail="onHollyGrail",
        onArena="onArena",
        onEvent="onEvent",
        onTower="onTower",
        onWorldBoss="onWorldBoss",
        onGoldMine="onGoldMine",
        onRank="onRank"

    },
    opcode = opcodes,
};
local Lobby2Page = {}
local mainContainer = nil
function Lobby2Page:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = ParentContainer
    self:registerPacket(self.container)
    self:InfoReq()
    mainContainer = container
    local mainFrame = tolua.cast(MainFrame:getInstance(), "CCBScriptContainer")
    local PageJumpMange = require("PageJumpMange")
    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            Lobby2Page[PageJumpMange._CurJumpCfgInfo._SecondFunc](self, container);
        end
        if PageJumpMange._CurJumpCfgInfo._ThirdFunc == "" then
            PageJumpMange._IsPageJump = false
        end
    else
        require("TransScenePopUp")
        TransScenePopUp_closePage()
    end
   

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["Lobby2Page"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
    --RankReward
     --local msg =Activity4_pb.RankGiftReq()
     --msg.action=0
     --common:sendPacket(HP_pb.ACTIVITY153_C, msg, true)
     -- Arena
     ParentContainer:registerMessage(MSG_REFRESH_REDPOINT)
     self:getArenaInfo(container)
     self:refreshRedPoint(self.container)
end

function Lobby2Page:onExecute(container)
    --self:refreshRedPoint(container)
    self:refreshLockImg(container)
end
function Lobby2Page:onExit(container)
    container:removeMessage(MSG_REFRESH_REDPOINT)
end
function Lobby2Page:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshRedPoint(container)
    end
end
-- 刷新各建築物紅點
function Lobby2Page:refreshRedPoint(container)
    NodeHelper:setNodesVisible(container, { mDungeonPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.LOBBY2_DUNGEON_ENTRY) })
    NodeHelper:setNodesVisible(container, { RankingRed = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.LOBBY2_RANKING_ENTRY) })
    NodeHelper:setNodesVisible(container, { mHolyGrailPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.LOBBY2_GRAIL_ENTRY) })
    
end

-- 刷新各建築物上鎖圖示
function Lobby2Page:refreshLockImg(container)
    NodeHelper:setNodesVisible(container, { 
        mGuildLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.TOWER) or 
                    not ActivityInfo:getActivityIsOpenById(194),
        mMineLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.GOLD_MINE),
        mEventLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.EVENT),
        mWorldBossLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.WORLD_BOSS),
        mDungeonLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DUNGEON),
        mArenaLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ARENA),
        mHolyGrailLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.HOLY_GRAIL),
        mRankingLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.RANKING),
    })
end
function Lobby2Page:PlayAni_DelayEnter(ani, time, page)
    local container = self.container
    local initialY = nil -- 用於記錄按鈕的初始Y座標

    -- 設定按鈕移動效果
    local function moveButtons(isVisible)
        local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
        local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")

        -- 如果尚未記錄初始位置，則進行記錄
        if not initialY then
            initialY = mainButtons:getPositionY()
        end

        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local contentHeight = 159
        local targetY = isVisible and initialY or initialY - contentHeight
        local moveAction = CCMoveTo:create(0.2, ccp(0, targetY)) -- 移動動作
        mainButtons:runAction(moveAction)
    end

    -- 動作序列
    local array = CCArray:create()
    array:addObject(CCCallFunc:create(function()
        if not GuideManager.isInGuide then
            moveButtons(false) -- 按鈕移動到負-Y座標
            container:runAnimation(ani)
        end

    end))
    array:addObject(CCDelayTime:create(0.1))
    array:addObject(CCCallFunc:create(function()
        PageManager.pushPage("TransScenePopUp")
    end))
    array:addObject(CCDelayTime:create(time))
    array:addObject(CCCallFunc:create(function()
        if page then
            PageManager.pushPage(page) -- 切換頁面
        end
    end))
    array:addObject(CCDelayTime:create(1)) -- 延遲1秒
    array:addObject(CCCallFunc:create(function()
        moveButtons(true) -- 按鈕移回初始位置
        container:runAnimation("Default Timeline")
    end))

    -- 執行序列
    container:runAction(CCSequence:create(array))
end


function Lobby2Page:onHollyGrail(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.HOLY_GRAIL) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.HOLY_GRAIL))
    else
        self:PlayAni_DelayEnter("Exit03",0.6,"Leader.LeaderPage")
    end
end
function Lobby2Page:onBounty()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DUNGEON) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.DUNGEON))
    else
        self:PlayAni_DelayEnter("Exit01",0.6,"Dungeon.DungeonPage")
    end
end
function Lobby2Page:onArena()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ARENA) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.ARENA))
    else
        self:PlayAni_DelayEnter("Exit02",0.6,"ArenaPage")
       -- PageManager.pushPage("ArenaPage")
    end
end
function Lobby2Page:onEvent()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.EVENT) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.EVENT))
    else
        self:PlayAni_DelayEnter("Exit04",0.6,"Dungeon2.Dungeon2Page")
    end
end
function Lobby2Page:onTower()
   if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.TOWER) or 
      not ActivityInfo:getActivityIsOpenById(194) then
       MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.TOWER))
   else
      --MessageBoxPage:Msg_Box(common:getLanguageString("@WaitingOpen"))

       self:PlayAni_DelayEnter("Exit07",0.6,"Tower.TowerPage")
    end
end
function Lobby2Page:onWorldBoss()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.WORLD_BOSS) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.WORLD_BOSS))
    else
        self:PlayAni_DelayEnter("Exit05",0.6,"WorldBossFinalpage")
    end
end
function Lobby2Page:onGoldMine()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.GOLD_MINE) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.GOLD_MINE))
    else
        --MessageBoxPage:Msg_Box(common:getLanguageString("@WaitingOpen"))
        --self:PlayAni_DelayEnter("Exit06",0.6,"PageName")
    end
end
function Lobby2Page:onRank()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.RANKING) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.RANKING))
    else
        PageManager.pushPage("Ranking.ProfessionRankingLobby")
    end
end


function Lobby2Page:getArenaInfo(container)
    if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.ARENA) then
        local Arena_pb = require("Arena_pb")
        local msg = Arena_pb.HPArenaDefenderList()
        msg.playerId = UserInfo.playerInfo.playerId
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.ARENA_DEFENDER_LIST_C, pb_data, #pb_data, false)
    end
end
function Lobby2Page:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode==HP_pb.DUNGEON_LIST_INFO_S then
        local Dungeon_pb= require("Dungeon_pb")
        local msg = Dungeon_pb.HPDungeonListInfoRet()
        msg:ParseFromString(msgBuff)
        require ("Dungeon2.Dungeon2SubPage_Event")
        DungeonPageBase_setData(msg)
    elseif opcode == HP_pb.MULTIELITE_LIST_INFO_S then
        local msgbuff = handler:getRecPacketBuffer()
        require("Dungeon.DungeonSubPage_Event")
        DungeonPageBase_setDungeonData(msgbuff)
    end

end
function Lobby2Page:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function Lobby2Page:InfoReq()
    --ActDungeon
    if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.DUNGEON) then
        common:sendEmptyPacket(HP_pb.MULTIELITE_LIST_INFO_C, false)
    end
    if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.EVENT) then
        common:sendEmptyPacket(HP_pb.DUNGEON_LIST_INFO_C, false)
    end
    --Tower
    if ActivityInfo:getActivityIsOpenById(194) then
        local Activity6_pb = require("Activity6_pb")
        local msg = Activity6_pb.SeasonTowerReq()
        msg.action = 0
        common:sendPacket(HP_pb.ACTIVITY194_SEASON_TOWER_C, msg, true)
    end

end

local CommonPage = require('CommonPage')
Lobby2Page = CommonPage.newSub(Lobby2Page, thisPageName, option)

return Lobby2Page
