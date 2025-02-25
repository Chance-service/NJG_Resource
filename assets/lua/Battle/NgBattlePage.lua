-- 戰鬥介面處理

local thisPageName = "NgBattlePage"
NgBattlePageInfo = { }
local selfContainer = nil       -- all ui information
gameStartTime = 0

local Formation_pb = require("Formation_pb")
local PageJumpMange = require("PageJumpMange")
local UserMercenaryManager = require("UserMercenaryManager")
local BuffManager = require("Battle.NewBuff.BuffManager")
local NgFightSceneHelper = require("Battle.NgFightSceneHelper")
local Const_pb = require("Const_pb")
local Quest_pb = require("Quest_pb")
require("Battle.NgBattleDataManager")
require("Battle.NgBattleResultManager")
local CONST = require("Battle.NewBattleConst")
require("Battle.NgBattleCharacterBase")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
local MissionManager = require("MissionManager")
require("Util.RedPointManager")
require("NgBattleDataManager")
require("Battle.NewBattleUtil")
local EventDataMgr = require("Event001DataMgr")

local mapCfg = ConfigManager.getNewMapCfg()

local awardTime = 0
local timeTxt = nil
local MAX_TIME = 60 * 60 * 12
local VIP_SPEED_POPUP_GOODID = 4004
NgBattlePageInfo.treasureTimeStr = nil
local nowTreasureState = -1
local treasureStateLimit = { 1800, 36000 }
local oTotalItemInfo = { }
local BATTLE_X2_SPEED = 2.3
local battleSpeedTable = { [1.5] = 1, [BATTLE_X2_SPEED] = 2--[[, [4] = 3]] }
local battleVipSpeed = 4
local groupedTables = {}

--任務列表
local _lineTaskPacket = nil
local _curShowTaskInfo = nil
--
local testLog = { }
--
local popupSaleTimeInterval = 0.5 -- ???隔
local popupSaleTimeIntervalKey = "popupSaleTimeIntervalKey" -- ??器的key
local GameId=1
local option = {
    ccbiFile = "BattlePage.ccbi",
    handlerMap = {
        onDekaronBoss = "onDekaronBoss",
        onTreasure = "onTreasure",
        onMap = "onMap",
        onAuto = "onAuto",
        onSpeed2 = "onSpeed2",
        onVipSpeed = "onVipSpeed",
        onSkip = "onSkip",
        onPause = "onPause",
        onExpress = "onExpress",
        onBossInfo = "onBossInfo",
        onTest = "onTest",
        onTask="onTask",
        onMiniGame="onMiniGame"
    },
    opcodes = {
        SYNC_LEVEL_INFO_C = HP_pb.SYNC_LEVEL_INFO_C,
        SYNC_LEVEL_INFO_S = HP_pb.SYNC_LEVEL_INFO_S,
        TAKE_FIGHT_AWARD_C = HP_pb.TAKE_FIGHT_AWARD_C,
        TAKE_FIGHT_AWARD_S = HP_pb.TAKE_FIGHT_AWARD_S,
        BATTLE_FORMATION_C = HP_pb.BATTLE_FORMATION_C,
        BATTLE_FORMATION_S = HP_pb.BATTLE_FORMATION_S,
        BATTLE_LOG_C = HP_pb.BATTLE_LOG_C,
        BATTLE_LOG_S = HP_pb.BATTLE_LOG_S,
        MULTI_BATTLE_LOG_C = HP_pb.MULTI_BATTLE_LOG_C,
        MULTI_BATTLE_LOG_S = HP_pb.MULTI_BATTLE_LOG_S,
        PVP_BATTLE_LOG_C = HP_pb.PVP_BATTLE_LOG_C,
        PVP_BATTLE_LOG_S = HP_pb.PVP_BATTLE_LOG_S,
        WORLD_BOSS_BATTLE_LOG_C = HP_pb.WORLD_BOSS_BATTLE_LOG_C,
        WORLD_BOSS_BATTLE_LOG_S = HP_pb.WORLD_BOSS_BATTLE_LOG_S,
        DUNGEON_BATTLE_LOG_C = HP_pb.DUNGEON_BATTLE_LOG_C,
        DUNGEON_BATTLE_LOG_S = HP_pb.DUNGEON_BATTLE_LOG_S,
        CYCLE_BATTLE_LOG_S = HP_pb.CYCLE_BATTLE_LOG_S,
        SINGLE_BOSS_BATTLE_LOG_S = HP_pb.SINGLE_BOSS_BATTLE_LOG_S,
        STATE_INFO_SYNC_S = HP_pb.STATE_INFO_SYNC_S,
        SEASON_TOWER_BATTLE_LOG_S = HP_pb.SEASON_TOWER_BATTLE_LOG_S,
        -- 取得編隊訊息
        GET_FORMATION_EDIT_INFO_C = HP_pb.GET_FORMATION_EDIT_INFO_C,
        -- 返回編隊訊息
        GET_FORMATION_EDIT_INFO_S = HP_pb.GET_FORMATION_EDIT_INFO_S,

        PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
        QUEST_GET_QUEST_LIST_S=HP_pb.QUEST_GET_QUEST_LIST_S,

        --失敗禮包
        ACTIVITY177_FAILED_GIFT_S = HP_pb.ACTIVITY177_FAILED_GIFT_S,
    }
}

local treasureSlotName = {
    "tc071808,gold01,gold02",
    "tc071807,tc071806,tc071803,gold03,tc071805,tc071804,gold05",
}

NewFightResult = {
    WIN = 0,
    LOSE = 1,
    ERROR = 2,
    NEXT_LOG = 3,
}

-------------------------------------------------------------------------
local TeamCard = {
	ccbiFile = "BattleTeamCardContent.ccbi",
}
function TeamCard:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function TeamCard:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    self.isPlayingEffect = false
end
function TeamCard:updateCardInfo(characterData, roleTable)
    if self.container == nil then
        return
    end
    self:setGrayCard(false)
    self.isPlayingEffect = false
    self.chaNode = characterData
    self.nowAniName = ""
    --self:resetEffect()
    if self.effectSpineFront then
        CCLuaLog("><<><<<><<>>>>>>>><<<<<<>TeamCard:updateCardInfo")
    end
    if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK then
        local spineNodeFront = self.container:getVarNode("mSpineFrontNode")
        if not self.effectSpineFront then
            spineNodeFront:removeAllChildrenWithCleanup(true)
            local spineFrontPath, spineFrontName = unpack(common:split(CONST.SceneSpinePath["CardSkill_Front"], ","))
            self.effectSpineFront = SpineContainer:create(spineFrontPath, spineFrontName)
            local effectSpineFrontNode = tolua.cast(self.effectSpineFront, "CCNode")
            spineNodeFront:addChild(effectSpineFrontNode)
        end
        local effectSpineFrontNode = tolua.cast(self.effectSpineFront, "CCNode")
        effectSpineFrontNode:setPositionY(0)
        effectSpineFrontNode:setVisible(true)
        self:setFrontEffect("animation", true)
        
        local spineNodeBack = self.container:getVarNode("mSpineBackNode")
        if not self.effectSpineBack then
            spineNodeBack:removeAllChildrenWithCleanup(true)
            local spineBackPath, spineBackName = unpack(common:split(CONST.SceneSpinePath["CardSkill_Back"], ","))
            self.effectSpineBack = SpineContainer:create(spineBackPath, spineBackName)
            local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
            spineNodeBack:addChild(effectSpineBackNode)
        end
        local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
        effectSpineBackNode:setVisible(false)
    end

    self.container:runAnimation("Default Timeline")

    local element = characterData.battleData[CONST.BATTLE_DATA.ELEMENT]
    local itemId = characterData.otherData[CONST.OTHER_DATA.ITEM_ID]
    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
    NodeHelper:setSpriteImage(self.container, { mRole = "UI/NewPlayeIcon/CardIcon/Role/RoleCard_" .. string.format("%02d", itemId) .. string.format("%03d", roleInfo and roleInfo.skinId or 0) .. ".png"  })
end
function TeamCard:updateShield(shield, maxHp)
    if self.container == nil then
        return
    end
    local shieldBar = self.container:getVarSprite("mShieldBar")
    local percent = math.min(1, math.max(tonumber(shield) / tonumber(maxHp), 0))
    shieldBar:setScaleX(percent)
end
function TeamCard:updateHp(hp, maxHp)
    if self.container == nil then
        return
    end
    local hpBar = self.container:getVarSprite("mHpBar")
    local percent = math.max(tonumber(hp) / tonumber(maxHp), 0)
    hpBar:setScaleX(percent)
    if percent == 0 then
        self:setGrayCard(true)
    else
        self:setGrayCard(false)
    end
end
function TeamCard:updateMp(mp, maxMp)
    if self.container == nil then
        return
    end
    local mpBar = self.container:getVarSprite("mMpBar")
    local percent = math.max(tonumber(mp) / tonumber(maxMp), 0)
    mpBar:setScaleX(percent)
    if self.effectSpineFront then
        local effectSpineFrontNode = tolua.cast(self.effectSpineFront, "CCNode")
        effectSpineFrontNode:stopAllActions()
        local array = CCArray:create()
        local time = mp == 0 and 0.1 or 0.5
        array:addObject(CCEaseIn:create(CCMoveTo:create(time, ccp(0, 0 + percent * 235)), 1))
        effectSpineFrontNode:runAction(CCSequence:create(array))
    end
    if self.effectSpineBack then
        local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
        effectSpineBackNode:setVisible(percent >= 1)
    end
    if percent >= 1 and not self.isPlayingEffect and self.effectSpineBack then
        self.isPlayingEffect = true
        self:setBackEffect("animation1", false)
    end
end
function TeamCard:onHead(container, isGuide)
    local GuideManager = require("Guide.GuideManager")
    if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE) and 
       (GuideManager.getCurrentCfg().showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_ANI) and
       (tonumber(GuideManager.getCurrentCfg().funcParam) ~= self.chaNode.idx) then  -- 新手必敗戰鬥 避免施放技能時點其他角色頭像
        return
    end
    if NgBattleDataManager.castSkillNode and NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK then
        return
    end
    if not self.chaNode then
        return
    end
    if NgBattleCharacterUtil:isCanSkill(self.chaNode, false) then
        --NgBattleDataManager_setCastSkillNode(self.chaNode)
          
        CHAR_UTIL:setSpineAnimation(self.chaNode, CONST.ANI_ACT.SKILL0, false)
        --NewBattleCharacter:setMp(self.chaNode, 0)

        if self.effectSpineBack then
            local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
            effectSpineBackNode:setVisible(false)
        end

        --self.effectSpine:setAttachmentForLua("KenseiA", "card071101/as053/hero" .. self.chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME])
        --self.effectSpine:setAttachmentForLua("KenseiB", "card071101/as052/hero" .. self.chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME])

        --self:setFrontEffect("animation", false)
        self.container:runAnimation("cardani Timeline")

        self.isPlayingEffect = false
    end
end
function TeamCard:setFrontEffect(aniName, isLoop)
    --self.effectSpine:setToSetupPose()
    self.effectSpineFront:runAnimation(1, aniName, isLoop and -1 or 0)
end
function TeamCard:setBackEffect(aniName, isLoop)
    self.effectSpineBack:setToSetupPose()
    self.effectSpineBack:runAnimation(1, aniName, isLoop and -1 or 0)
    if aniName == "animation1" then
        local hpBar = self.container:getVarSprite("mHpBar")
        local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
        effectSpineBackNode:setVisible(hpBar:getScaleX() ~= 0)
        self.effectSpineBack:addAnimation(1, "animation2", true)
    elseif aniName == "animation03" then
        self.isPlayingEffect = false
    end
end
function TeamCard:resetEffect()
    self.isPlayingEffect = false
    self.effectSpine:setToSetupPose()
end
function TeamCard:setGrayCard(isGray)
    local nodeName = { "mRole", "mMpBar" }
    if isGray then
        if self.effectSpineFront then
            local effectSpineFrontNode = tolua.cast(self.effectSpineFront, "CCNode")
            effectSpineFrontNode:setVisible(false)
        end
        if self.effectSpineBack then
            local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
            effectSpineBackNode:setVisible(false)
        end
        -- 卡片灰階
        --NodeHelper:setSpriteImage(self.container, { mBg = CONST.BLOOD_BG_PIC[0] })
        NodeHelper:setNodeIsGray(self.container, {  mRole = true, mMpBar = true })

    else
        if self.effectSpineFront then
            local effectSpineFrontNode = tolua.cast(self.effectSpineFront, "CCNode")
            effectSpineFrontNode:setVisible(true)
        end
        if self.effectSpineBack then
            local effectSpineBackNode = tolua.cast(self.effectSpineBack, "CCNode")
            effectSpineBackNode:setVisible(true)
        end
        NodeHelper:setNodeIsGray(self.container, { mRole = false, mMpBar = false })
    end
end
-------------------------------------------------------------------------
function NgBattlePageInfo:onEnter(container)
    container:registerLibOS()
    --if libOS:getInstance():getIsDebug() then
    --    battleSpeedTable = { [1.5] = 1, [2.5] = 2--[[, [4] = 3]] }
    --else
    --    battleSpeedTable = { [1.5] = 1, [2.5] = 2 }
    --end
    
    self:MiniGameSync(container)
    NgBattleDataManager_setBattlePageContainer(container) 
    NgBattleDataManager.battleMapId = UserInfo.stateInfo.curBattleMap
    --註冊訊息
    container:registerMessage(MSG_REFRESH_REDPOINT)
    --註冊協定
    self:registerPacket(container)
    --註冊時間
    TimeCalculator:getInstance():createTimeCalcultor(popupSaleTimeIntervalKey, popupSaleTimeInterval)
    --寶箱初始化
    common:sendEmptyPacket(HP_pb.SYNC_LEVEL_INFO_C, false) --同步寶箱時間
    nowTreasureState = -1
    self:createChallangeSpine(container)
    self:createTreasureSpine(container)
    timeTxt = container:getVarLabelBMFont("mTimeTxt")
    --設定最大掛機時間
    local vipCfg = ConfigManager.getVipCfg()
    local curVipInfo = vipCfg[UserInfo.playerInfo.vipLevel]
    MAX_TIME = curVipInfo and curVipInfo["idleTime"] or 60 * 60 * 12
    --倒數警告spine初始化
    self:createCountDownSpine(container)
    --Title初始化
    self:setTitle()
    --UI初始化
    self:setUIType(container, CONST.SCENE_TYPE.AFK)
    --按鈕動畫初始化
    local battleSpeed = CCUserDefault:sharedUserDefault():getFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId)
    if battleSpeed >= 2 then
        battleSpeed = BATTLE_X2_SPEED
    end 
    if not battleSpeedTable[battleSpeed] then
        battleSpeed = 1.5
    end
    NodeHelper:setMenuItemImage(container, { mSpeedBtnImg = { normal = "Battle_btn_speedx" .. math.floor(battleSpeed) .. ".png" } })
    local isVipSpeed = CCUserDefault:sharedUserDefault():getBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId)
    local x4ImgName = "Battle_btn_speedx4_grey.png"
    if isVipSpeed then
        battleSpeed = battleVipSpeed
        x4ImgName = "Battle_btn_speedx4.png"
    end
    local battleAuto = CCUserDefault:sharedUserDefault():getIntegerForKey("BATTLE_AUTO_" ..  UserInfo.playerInfo.playerId)
    NgBattleDataManager_setBattleIsAuto(battleAuto ~= 0)

    NodeHelper:setMenuItemImage(container, { mVipSpeedBtnImg = { normal = x4ImgName } })
    NodeHelper:setNodesVisible(container, { mAutoAni = (battleAuto ~= 0), 
                                            mSpeedAni = (battleSpeed > 1.5),
                                            mVipSpeedAni = isVipSpeed })  
    --背景圖初始化 
    self:setBattleBg()
    --取得第一隊資料
    self:sendEditInfoReq(container, 1)
    --初始化
    --self:initScene(container)
    --設定UI座標高度限制
    local topNode = container:getVarNode("mTopNode")
    local centerNode = container:getVarNode("mCenterNode")
    if topNode then
        topNode:setPositionY(math.min(topNode:getPositionY(), 1696))
    end
    if centerNode then
        centerNode:setPositionY(math.min(centerNode:getPositionY(), 848))
    end
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NgBattlePage"] = container
    if not GuideManager.isInGuide then
        container:runAnimation("OpenAni")
    else
        container:runAnimation("Default Timeline")
    end

    --測試按鈕
    NodeHelper:setNodesVisible(container, { mTestNode = libOS:getInstance():getIsDebug() })
    NodeHelper:setNodesVisible(container, { mTestSkip = (libOS:getInstance():getIsDebug() or (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.TEST_BATTLE)) })

    --跳轉設定
    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            local fun, param = unpack(common:split(PageJumpMange._CurJumpCfgInfo._SecondFunc, ","))
            if param and container then
                NgBattlePageInfo[fun](param, container)
            end
        end
        PageJumpMange._IsPageJump = false
    end

    self:refreshAllPoint(container)
end

function NgBattlePageInfo:onExit(container)
    local ALFManager = require("Util.AsyncLoadFileManager")
    for k, v in pairs(NgBattleDataManager.asyncLoadTasks) do 
        for k2, v2 in pairs(v) do 
            ALFManager:cancel(v2)
        end
    end
    NgBattleDataManager.asyncLoadTasks = { }
    NgFightSceneHelper:onExit()
    SoundManager:getInstance():playGeneralMusic()
    --SimpleAudioEngine:sharedEngine():stopAllEffects()
    
    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(true)

    TimeCalculator:getInstance():removeTimeCalcultor(popupSaleTimeIntervalKey)
    container:removeMessage(MSG_REFRESH_REDPOINT)
    GameUtil:purgeCachedData()
end

function NgBattlePageInfo:onExecute(container)
    local dt = GamePrecedure:getInstance():getFrameTime() * 1000
    gameStartTime = gameStartTime + dt

    NgFightSceneHelper:update(container, dt)
    --戰鬥狀態update
    NgFightSceneHelper:UpdateState(container, dt)

    --更新領獎時間
    local GuideManager = require("Guide.GuideManager")
    local time = 0
    if GuideManager.isInGuide and GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] ~= 0 and GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] <= 11800 then
        -- 新手教學強制設為30分鐘
        time = 60 * 60 * 0.5
    elseif awardTime > 0 then
        time = os.time() - awardTime
        if time > MAX_TIME then
            time = MAX_TIME
        end
    end
    RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.BATTLE_TREASURE_BTN, 1, { time = time })
    NgBattlePageInfo.treasureTimeStr = common:dateFormat2String2(time, true)
    timeTxt:setString(NgBattlePageInfo.treasureTimeStr)
    --設定寶箱動畫
    self:setTreasureSpine(container, time)
    --更新領獎頁面顯示時間
    local CommonRewardPageNewBase = require("CommonRewardPageNew")
    CommonRewardPageNewBase:updateTimeStr(NgBattlePageInfo.treasureTimeStr)

    local GuideManager = require("Guide.GuideManager")
    -- popup sale
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.POPUP_SALE) then
            if TimeCalculator:getInstance():hasKey(popupSaleTimeIntervalKey) and
                tonumber(TimeCalculator:getInstance():getTimeLeft(popupSaleTimeIntervalKey)) <= 0 then
                TimeCalculator:getInstance():createTimeCalcultor(popupSaleTimeIntervalKey, popupSaleTimeInterval)
                if not GuideManager.isInGuide and not PageManager.getIsInSummonPage() and not PageManager.getIsInPopSalePage() then
                    local cfg = ConfigManager.getPopUpCfg()
                    local spicalTable = {132,177}
                    for i = 1, #spicalTable do
                        if NgBattlePageInfo:showPopUpSale(spicalTable[i]) then
                            break
                        end
                    end
                end
            end
        end
    end
    if TimeCalculator:getInstance():hasKey(popupSaleTimeIntervalKey) and
        tonumber(TimeCalculator:getInstance():getTimeLeft(popupSaleTimeIntervalKey)) <= 0 then
        -- 更新主Banner鎖頭
        MainFrame:getInstance():setChildVisible("mSummonLock", LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON))
    end
    -- 教學遮罩
    if GuideManager.isInGuide then
        if GuideManager.getCurrentCfg() and (GuideManager.getCurrentCfg().openMask == 1) then
            MainFrame_setGuideMask(true)
        else
            MainFrame_setGuideMask(false)
        end
    else
        MainFrame_setGuideMask(false)
    end
end
---------------------------------------------------------------------
-- UI按鈕回應
function NgBattlePageInfo:onTest(container)
    --self:sendBattleResult(container, 1)
    require("SpineTouchEdit")
    PageManager.pushPage("SpineTouchEdit")
end

function NgBattlePageInfo:onMultiBoss(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.MULTI)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.battleMapId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    --NodeHelper:setNodesVisible(container, { mTopInfo = false })
    NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end

function NgBattlePageInfo:onPvpChallange(container, resultInfo, battleId, battleType, rankId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.PVP)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.battleMapId = rankId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end

function NgBattlePageInfo:onWorldBoss(container, resultInfo, battleId, battleType)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.WORLD_BOSS)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.battleMapId = nil
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end

function NgBattlePageInfo:onDungeon(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.DUNGEON)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.battleMapId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end

function NgBattlePageInfo:onCycle(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.CYCLE_TOWER)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.TowerId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    --NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end
function NgBattlePageInfo:onSeasonTower(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.SEASON_TOWER)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.TowerId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
    --NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
end

function NgBattlePageInfo:onSingleBoss(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.SINGLE_BOSS)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.SingleBossId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
end

function NgBattlePageInfo:onSingleBossSim(container, resultInfo, battleId, battleType, mapId)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.SINGLE_BOSS_SIM)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.SingleBossId = mapId
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
end

function NgBattlePageInfo_onRestartBoss(container)
    NgBattleDataManager_clearBattleData()
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        if mapCfg[UserInfo.stateInfo.curBattleMap] then
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = NgBattleDataManager.battleType
            msg.mapId = tostring(NgBattleDataManager.battleMapId)
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
        else
            MessageBoxPage:Msg_Box(common:getLanguageString("@WaitNew"))
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local multiMapCfg = ConfigManager:getMultiEliteCfg()
        if multiMapCfg[NgBattleDataManager.dungeonId] then
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = NgBattleDataManager.battleType
            msg.mapId = tostring(NgBattleDataManager.dungeonId)
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        local msg = Battle_pb.NewBattleFormation()
        msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
        msg.battleType = NgBattleDataManager.battleType
        msg.defenderRank = NgBattleDataManager.defenderRank
        common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        local msg = Battle_pb.NewBattleFormation()
        msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
        msg.battleType = NgBattleDataManager.battleType
        common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local dungeonCfg = ConfigManager:getMultiElite2Cfg()
        if dungeonCfg[NgBattleDataManager.dungeonId] then
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = NgBattleDataManager.battleType
            msg.mapId = tostring(NgBattleDataManager.dungeonId)
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local dungeonCfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        if dungeonCfg[NgBattleDataManager.dungeonId] then
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = NgBattleDataManager.battleType
            msg.mapId = tostring(NgBattleDataManager.dungeonId)
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local msg = Battle_pb.NewBattleFormation()
        msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
        msg.battleType = NgBattleDataManager.battleType
        msg.mapId = tostring(NgBattleDataManager.SingleBossId)
        common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        local msg = Battle_pb.NewBattleFormation()
        msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
        msg.battleType = NgBattleDataManager.battleType
        common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local dungeonCfg = ConfigManager:getTowerData()
        if dungeonCfg[NgBattleDataManager.dungeonId] then
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = NgBattleDataManager.battleType
            msg.mapId = tostring(NgBattleDataManager.dungeonId)
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, false)
        end
    end
end
--------------------------------------------------------
-- AFK Btn
-- Boss挑戰
function NgBattlePageInfo:onDekaronBoss(container)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        if mapCfg[UserInfo.stateInfo.curBattleMap].NextID ~= 0 then
            if mapCfg[UserInfo.stateInfo.curBattleMap].Unlock > UserInfo.roleInfo.level then
                MessageBoxPage:Msg_Box(common:getLanguageString("@OpenLevel", mapCfg[UserInfo.stateInfo.curBattleMap].Unlock))
                return
            end
            NgBattleDataManager.battleMapId = UserInfo.stateInfo.curBattleMap
            local msg = Battle_pb.NewBattleFormation()
            msg.type = CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY
            msg.battleType = CONST.SCENE_TYPE.BOSS
            msg.mapId = tostring(UserInfo.stateInfo.curBattleMap)
            local GuideManager = require("Guide.GuideManager")
            if GuideManager.isInGuide then
                GuideManager.tempMsg[HP_pb.BATTLE_FORMATION_C] = msg
            end
            common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, GuideManager.isInGuide or false)
        else
            MessageBoxPage:Msg_Box(common:getLanguageString("@WaitNew"))
        end
    end
end
function NgBattlePageInfo:onMiniGame(container)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        --local AlbumSideStory=require("Album.AlbumHCGPage")
        --AlbumSideStory:onBtn(GameId)
        --local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
        --local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
        --mainButtons:setVisible(false)
        require("FetterGirlsDiary")
        local StoryTable=NgBattlePageInfo:GetTable()
        local stage
        for _,data in pairs (StoryTable) do
            local stagetype= string.sub(data[1].id,5,6)
            local mID=tonumber(string.format("%02d", stagetype))
            if mID == GameId then
                stage = data[1].stage
            end
        end
        local chapter=mapCfg[stage].Chapter
        local level=mapCfg[stage].Level
        local storyIdx=1
        local fetterCfgId = tonumber(string.format("%02d", chapter) .. string.format("%02d", level) .. storyIdx .. "01")
        local fetterControlCfg = ConfigManager:getFetterBDSMControlCfg()
        if not fetterControlCfg[fetterCfgId] then
            storyIdx=2
            fetterCfgId = tonumber(string.format("%02d", chapter) .. string.format("%02d", level) .. storyIdx .. "01")
            if not fetterControlCfg[fetterCfgId] then
                return
            end
        end
        FetterGirlsDiary_setPhotoRole(nil, chapter, level, storyIdx)
        PageManager.pushPage("FetterGirlsDiary")
        NgBattleResultManager.showHStory = NgFightSceneHelper:StroyDisplay(stage)
    end
end
-- 測試戰鬥
function NgBattlePageInfo:onTestBattle(container, resultInfo, battleId, battleType)
    NgBattleDataManager.serverEnemyInfo = resultInfo
    NgBattleDataManager.battleId = battleId
    NgBattleDataManager.battleMapId = nil

    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
end
-- 開啟快速戰鬥UI
function NgBattlePageInfo:onExpress(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.FAST_BATTLE) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.FAST_BATTLE))
    else
        PageManager.pushPage("NgBattleExpressPage")
    end
end
-- 開啟關卡Boss資訊
function NgBattlePageInfo:onBossInfo(container)
    PageManager.pushPage("NewBattleBossInfo")
end
-- 開啟關卡地圖
function NgBattlePageInfo:onMap(container)
    PageManager.changePage("NewBattleMapPage2")
end
-- 領取掛機獎勵
function NgBattlePageInfo:onTreasure(container)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        if os.time() - awardTime < 60 then
            local CommonRewardPageNewBase = require("CommonRewardPageNew")
            CommonRewardPageNewBase:setSTR(NgBattlePageInfo.treasureTimeStr)
            CommonRewardPageNewBase:ClearItem()
            PageManager.pushPage("CommonRewardPageNew")
        else
            common:sendEmptyPacket(HP_pb.TAKE_FIGHT_AWARD_C)
            local CommonRewardPageNewBase = require("CommonRewardPageNew")
            CommonRewardPageNewBase:setSTR(NgBattlePageInfo.treasureTimeStr)
        end
    end
end
--任務頁面
function NgBattlePageInfo:onTask(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.QUEST) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.QUEST))
    else
        require("Mission.MissionMainPage")
        MissionMainPage_setIsBattleView(false, 1)
        PageManager.pushPage("MissionMainPage")
    end
end
--------------------------------------------------------
-- Battle Btn
-- 自動開關
function NgBattlePageInfo:onAuto(container)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.AUTO_BATTLE) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.AUTO_BATTLE))
    else
        NodeHelper:setNodesVisible(container, { mAutoAni = not NgBattleDataManager.battleIsAuto })
        NgBattleDataManager_setBattleIsAuto(not NgBattleDataManager.battleIsAuto)
        CCUserDefault:sharedUserDefault():setIntegerForKey("BATTLE_AUTO_" ..  UserInfo.playerInfo.playerId, NgBattleDataManager.battleIsAuto and 1 or 0)
    end
end
-- 1/2/4倍速
function NgBattlePageInfo:onSpeed2(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide and (GuideManager.getCurrentCfg().showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_INIT) then
        return
    end
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING or
       NgBattleDataManager.battleState == CONST.FIGHT_STATE.PLAY_SKILL then
        local newSpeed = 1
        local isVipSpeed = CCUserDefault:sharedUserDefault():getBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId)
        local battleSpeed = NgBattleDataManager.battleSpeed
        if isVipSpeed then
            battleSpeed = CCUserDefault:sharedUserDefault():getFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId)
            if battleSpeed >= 2 then
                battleSpeed = BATTLE_X2_SPEED
            end 
        end
        local nowIdx = battleSpeedTable[battleSpeed] or 1
        for k, v in pairs(battleSpeedTable) do
            if v == (nowIdx + 1) then
                newSpeed = k
            end
        end
        if not isVipSpeed then
            NgFightSceneHelper:setSceneSpeed(newSpeed)
        end
        NodeHelper:setNodesVisible(container, { mSpeedAni = ((newSpeed >= 2) and true or false) })
        CCUserDefault:sharedUserDefault():setFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId, newSpeed)
        NodeHelper:setMenuItemImage(container, { mSpeedBtnImg = { normal = "Battle_btn_speedx" .. math.floor(newSpeed) .. ".png" } })
    end
end
-- 課金4倍速
function NgBattlePageInfo:onVipSpeed(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide and (GuideManager.getCurrentCfg().showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_INIT) then
        return
    end
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING or
       NgBattleDataManager.battleState == CONST.FIGHT_STATE.PLAY_SKILL then
        local flagDataBase = require("FlagData")
        local NgBattlePausePage = require("NgBattlePausePage")
        if FlagDataBase_GetData()[flagDataBase.FlagId.BATTLE_SPEED_X4] ~= 1 then
            NgBattlePageInfo:onPause(container)
            PageManager.showConfirm(common:getLanguageString("@GoBuyQuickGiftTitle"), common:getLanguageString("@GoBuyQuickGift"), function(isSure)
                if isSure then
                    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.POPUP_SALE) then
                        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.POPUP_SALE))
                        NgBattlePausePage:onContinue(container)
                    else
                        local actPopupSalePage = require("ActPopUpSale.ActPopUpSalePage")
                        actPopupSalePage:setEntryTab(tostring(VIP_SPEED_POPUP_GOODID))
                        PageManager.pushPage("ActPopUpSale.ActPopUpSalePage")
                    end
                else
                    NgBattlePausePage:onContinue(container)
                end
            end, true, nil, nil, nil, 0.9, true, function() NgBattlePausePage:onContinue(container) end)
            return
        end
        local battleSpeed = CCUserDefault:sharedUserDefault():getFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId)
        if battleSpeed >= 2 then
            battleSpeed = BATTLE_X2_SPEED
        end 
        if not battleSpeedTable[battleSpeed] then
            battleSpeed = 1.5
        end
        local isVipSpeed = CCUserDefault:sharedUserDefault():getBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId)
        isVipSpeed = not isVipSpeed
        CCUserDefault:sharedUserDefault():setBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId, isVipSpeed)
        local newSpeed = isVipSpeed and battleVipSpeed or battleSpeed
        NgFightSceneHelper:setSceneSpeed(newSpeed)
        local x4ImgName = isVipSpeed and "Battle_btn_speedx4.png" or "Battle_btn_speedx4_grey.png"
        NodeHelper:setMenuItemImage(container, { mVipSpeedBtnImg = { normal = x4ImgName } })
        NodeHelper:setNodesVisible(container, { mVipSpeedAni = isVipSpeed })
    end
end
-- 10倍速
function NgBattlePageInfo:onSkip(container)
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING or
       NgBattleDataManager.battleState == CONST.FIGHT_STATE.PLAY_SKILL then
        NgFightSceneHelper:setSceneSpeed(10)
    end
end

function NgBattlePageInfo:onPause(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING or
       NgBattleDataManager.battleState == CONST.FIGHT_STATE.PLAY_SKILL or NgBattleDataManager.battleState == CONST.FIGHT_STATE.RESULT_ERROR or
       NodeHelper:isDebug() then
        NgBattleDataManager_setBattleIsPause(true)
        NgFightSceneHelper:setSceneSpeed(0)
        PageManager.pushPage("NgBattlePausePage")
    end
end
---------------------------------------------------------------------
-- 角色卡牌UI初始化
function NgBattlePageInfo:initTeamCard(container)
    local scrollview = container:getVarScrollView("mCardScrollView") 
    NgBattleDataManager.battlePageContainer.teamCards = { }
    for i = 1, 5 do
        local cell = CCBFileCell:create()
        local panel = TeamCard:new( { id = i, ccbiFile = cell })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(TeamCard.ccbiFile)
        scrollview:addCellBack(cell)
        NgBattleDataManager.battlePageContainer.teamCards[i] = panel

        local sprite = CCSprite:create("card_none.png")
        local parent = container:getVarNode("mRoleCard" .. i) 
        parent:setVisible(false)
        parent:removeAllChildrenWithCleanup(true)
        parent:addChild(sprite)
        sprite:setAnchorPoint(ccp(0.5, 0.5))
        sprite:setPosition(ccp(0, 0))
    end
    scrollview:orderCCBFileCells()
    for i = 1, 5 do
        NgBattleDataManager.battlePageContainer.teamCards[i].ccbiFile:setPosition(ccp(-382 + 139 * (i - 1), 117))
    end
    return NgBattleDataManager.battlePageContainer.teamCards
end
-- 精靈卡牌UI初始化
function NgBattlePageInfo_initSpriteCard(container)
    local SpriteManager = require("SpriteManager")
    local playerData = SpriteManager:getPlayerSpriteData()
    local enemyData = SpriteManager:getEnemySpriteData()
    for i = 1, CONST.SPRITE_COUNT do
        if playerData[i] then
            NodeHelper:setSpriteImage(container, { ["mPlayerSprite" .. i] = "UI/RoleShowCards/spirits_" .. playerData[i]["INFO"].itemId .. ".png" })
            NodeHelper:setNodeIsGray(container, {  ["mPlayerSprite" .. i] = true })
            playerData[i]["GRAY"] = true
        else
            NodeHelper:setSpriteImage(container, { ["mPlayerSprite" .. i] = "UI/Mask/Image_Empty.png" })
        end
        if enemyData[i] then
            NodeHelper:setSpriteImage(container, { ["mEnemySprite" .. i] = "UI/RoleShowCards/spirits_" .. enemyData[i]["INFO"].itemId .. ".png" })
            NodeHelper:setNodeIsGray(container, {  ["mEnemySprite" .. i] = true })
            enemyData[i]["GRAY"] = true
        else
            NodeHelper:setSpriteImage(container, { ["mEnemySprite" .. i] = "UI/Mask/Image_Empty.png" })
        end
    end
end
-- 精靈卡牌UI顯示更新
function NgBattlePageInfo_updateSpriteCard(container)
    local SpriteManager = require("SpriteManager")
    local playerData = SpriteManager:getPlayerSpriteData()
    local enemyData = SpriteManager:getEnemySpriteData()
    for i = 1, CONST.SPRITE_COUNT do
        if playerData[i] then
            local newGray = (playerData[i]["CD"] > 10 * 1000)
            if playerData[i]["GRAY"] == true and newGray == false then
                NodeHelper:setNodeIsGray(container, {  ["mPlayerSprite" .. i] = newGray })
            elseif playerData[i]["GRAY"] == false and newGray == true then
                NodeHelper:setNodeIsGray(container, {  ["mPlayerSprite" .. i] = newGray })
            end
            playerData[i]["GRAY"] = (playerData[i]["CD"] > 10 * 1000)
        end
        if enemyData[i] then
            local newGray = (enemyData[i]["CD"] > 10 * 1000)
            if enemyData[i]["GRAY"] == true and newGray == false then
                NodeHelper:setNodeIsGray(container, {  ["mEnemySprite" .. i] = newGray })
            elseif enemyData[i]["GRAY"] == false and newGray == true then
                NodeHelper:setNodeIsGray(container, {  ["mEnemySprite" .. i] = newGray })
            end
            enemyData[i]["GRAY"] = (enemyData[i]["CD"] > 10 * 1000)
        end
    end
end
-- 挑戰spine初始化
function NgBattlePageInfo:createChallangeSpine(container)
    local spinePath, spineName = unpack(common:split(CONST.SceneSpinePath["Challange"], ","))
    container.challangeSpine = SpineContainer:create(spinePath, spineName)
    
    local challangeNode = tolua.cast(container.challangeSpine, "CCNode")
    local parentNode = container:getVarNode("mChallangeNode")
    parentNode:addChild(challangeNode)
    
    container.challangeSpine:runAnimation(1, "animation", -1)
    --小遊戲spine
    local spinePath, spineName = unpack(common:split(CONST.SceneSpinePath["MiniGame"], ","))
    container.MiniGame = SpineContainer:create(spinePath, spineName)
    
    local GameNode = tolua.cast(container.MiniGame, "CCNode")
    local parentNode = container:getVarNode("mGameSpine")
    parentNode:addChild(GameNode)
    
    container.MiniGame:runAnimation(1, "animation", -1)
end
-- 寶箱spine初始化
function NgBattlePageInfo:createTreasureSpine(container)
    local spinePath, spineName = unpack(common:split(CONST.SceneSpinePath["Treasure"], ","))
    container.treasureSpine = SpineContainer:create(spinePath, spineName)
    
    local treasureNode = tolua.cast(container.treasureSpine, "CCNode")
    local parentNode = container:getVarNode("mTreasureNode")
    parentNode:addChild(treasureNode)
    
    container.treasureSpine:runAnimation(1, "animation02", -1)
end
-- 倒數警告spine初始化
function NgBattlePageInfo:createCountDownSpine(container)
    local spinePath, spineName = unpack(common:split(CONST.SceneSpinePath["COUNT_DOWN"], ","))
    container.countDownSpine = SpineContainer:create(spinePath, spineName)
    
    local countDownNode = tolua.cast(container.countDownSpine, "CCNode")
    local parentNode = container:getVarNode("mCountDownNode")
    parentNode:addChild(countDownNode)
    
    container.countDownSpine:runAnimation(1, "animation", -1)
    parentNode:setVisible(false)
end

function NgBattlePageInfo_playTreasureAni(aniName)
    if NgBattleDataManager.battlePageContainer.treasureSpine and not NgBattleDataManager.battlePageContainer.treasureSpine:isPlayingAnimation(aniName, 1) then
        NgBattleDataManager.battlePageContainer.treasureSpine:runAnimation(1, aniName, 0)
        NgBattleDataManager.battlePageContainer.treasureSpine:addAnimation(1, "animation02", true)
    end
end
-- 設定UI顯示
function NgBattlePageInfo:setUIType(container)
    if not NgBattleDataManager.battlePageContainer then
        return
    end
    local isAfk = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)
    local isGuide = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE)
    local isPvp = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP)
    local isDungeon = (NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON)
    local GuideManager = require("Guide.GuideManager")

    local mainContainer = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    local mainButtons = mainContainer:getCCNodeFromCCB("mMainFrameButtons")
    mainButtons:setVisible(isAfk)

    local teamCard = NgBattleDataManager.battlePageContainer:getVarScrollView("mCardScrollView")
    teamCard:setTouchEnabled(false)
    teamCard:setVisible(not isAfk)

    local battleSpeed = CCUserDefault:sharedUserDefault():getFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId)
    if battleSpeed >= 2 then
        battleSpeed = BATTLE_X2_SPEED
    end 
    if not battleSpeedTable[battleSpeed] then
        battleSpeed = 1
    end
    local isVipSpeed = CCUserDefault:sharedUserDefault():getBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId)
    local battleAuto = CCUserDefault:sharedUserDefault():getIntegerForKey("BATTLE_AUTO_" ..  UserInfo.playerInfo.playerId)
    local flagDataBase = require("FlagData")
    NodeHelper:setNodesVisible(NgBattleDataManager.battlePageContainer, {    -- 新手教學&pvp不顯示自動/暫停按鈕
        mAfkBtn = isAfk, mAfkTitle = isAfk, 
        mBattleBtn = not isAfk, mBattleTitle = not isAfk and not isGuide,
        mSpeedBtn = not isGuide,
        mSpeedAni = (not isGuide) and (battleSpeed >= 2),
        mVipSpeedBtn = not isGuide,
        mVipSpeedAni = (not isGuide) and (isVipSpeed),
        mAutoBtn = not isGuide,
        mAutoAni = (not isGuide) and (battleAuto ~= 0),   -- 0: 關閉, 1: 開啟
        mPauseBtn = (not isGuide and not isPvp and not isDungeon and not GuideManager.isInGuide),
        mExpressLock = LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.FAST_BATTLE),
        mAutoLock = (not isGuide) and (LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.AUTO_BATTLE)),
        mVipSpeedLock = (not isGuide) and (FlagDataBase_GetData()[flagDataBase.FlagId.BATTLE_SPEED_X4] ~= 1),
        mSingleBossNode = (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.SINGLE_BOSS) or
                          (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.SINGLE_BOSS_SIM)
    })
    NodeHelper:setMenuItemEnabled(NgBattleDataManager.battlePageContainer, "InfoBtn", true)
    NodeHelper:setMenuItemImage(container, { mSpeedBtnImg = { normal = "Battle_btn_speedx" .. math.floor(battleSpeed) .. ".png" } })
    local x4ImgName = isVipSpeed and "Battle_btn_speedx4.png" or "Battle_btn_speedx4_grey.png"
    NodeHelper:setMenuItemImage(container, { mVipSpeedBtnImg = { normal = x4ImgName } })

    NodeHelper:setNodesVisible(container, { mQuestNode = not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.QUEST) })

    NodeHelper:setNodesVisible(container, { mTestSkip = (Golb_Platform_Info.is_win32_platform or NodeHelper:isDebug() or (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.TEST_BATTLE)) })
end
-- 設定寶箱顯示狀態
function NgBattlePageInfo:setTreasureSpine(container, time)
    local closeStr1 = nil
    local closeStr2 = nil
    local isChangeState = false
    if time < treasureStateLimit[1] then
        closeStr1 = "goldXX"
        closeStr2 = "goldXX"
        nowTreasureState = 0
        isChangeState = true
    elseif time >= treasureStateLimit[1] and time < treasureStateLimit[2] then
        closeStr2 = "goldXX"
        nowTreasureState = 1
        isChangeState = true
    elseif time >= treasureStateLimit[2] then
        nowTreasureState = 2
        isChangeState = true
    end
    
    container.treasureSpine:setToSetupPose()
    local gold1 = common:split(treasureSlotName[1], ",")
    for i = 1, #gold1 do
        local attachName = closeStr1 or gold1[i]
        container.treasureSpine:setAttachmentForLua(gold1[i], attachName)
    end
    local gold2 = common:split(treasureSlotName[2], ",")
    for i = 1, #gold2 do
        container.treasureSpine:setAttachmentForLua(gold2[i], closeStr2 or gold2[i])
    end
end
-- 設定背景圖
function NgBattlePageInfo:setBattleBg()
    local mapId = NgBattleDataManager.battleMapId
    local bgPath = ""
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local chapter = mapCfg[mapId].Chapter
        local mainCh, childCh = unpack(common:split(chapter, "-"))
        bgPath = "BG/Battle/battle_bg_" .. string.format("%03d", mainCh) .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local cfg = ConfigManager:getMultiEliteCfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].bgFileName
        bgPath = "BG/Battle/" .. fileName .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        bgPath = "BG/Battle/role_bg_mul01.png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        bgPath = "BG/Battle/TutorialMap_1.png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        bgPath = "BG/Battle/role_bg_mul01.png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local cfg = ConfigManager:getMultiElite2Cfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].bgFileName
        bgPath = "BG/Battle/" .. fileName .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        local fileName = cfg[NgBattleDataManager.dungeonId].battleBg
        bgPath = "BG/Battle/" .. fileName .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local cfg = ConfigManager.getSingleBoss()[tonumber(NgBattleDataManager.SingleBossId)]
        local fileName = cfg.BattleBg
        bgPath = "BG/Battle/"..fileName..".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local cfg = ConfigManager:get191StageCfg()
        local fileName = cfg[NgBattleDataManager.dungeonId].battleBg
        bgPath = "BG/Battle/" .. fileName .. ".png"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        bgPath = "BG/Battle/worldboss_02_2.png"
    end
    NodeHelper:setSpriteImage(NgBattleDataManager.battlePageContainer, { mBg = bgPath })
end
-- 設定標題文字
function NgBattlePageInfo:setTitle()
    local mapId = NgBattleDataManager.battleMapId
    local titleTxt = NgBattleDataManager.battlePageContainer:getVarLabelTTF("mBattleLockTxt")
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local chapter = mapCfg[mapId].Chapter
        local level = mapCfg[mapId].Level
       -- local mainCh, childCh = unpack(common:split(chapter, "-"))
        local txt = common:getLanguageString("@MapFlag" .. chapter) .. level
        local UnlockTxt = mapCfg[mapId].GirlTxt
        titleTxt:setString(txt)
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = txt, mUnLockTxt = UnlockTxt})   
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        local cfg = ConfigManager:getMultiEliteCfg()
        titleTxt:setString(common:getLanguageString("@RaidTitle"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = cfg[NgBattleDataManager.dungeonId].name })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        titleTxt:setString(common:getLanguageString("@ArenaTitle"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = NgBattleDataManager.arenaName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        titleTxt:setString(common:getLanguageString("@WorldBoss"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = common:getLanguageString("@WorldBoss") })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        local cfg = ConfigManager:getMultiElite2Cfg()
        titleTxt:setString(common:getLanguageString("@RaidTitle"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = cfg[NgBattleDataManager.dungeonId].name })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local cfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        titleTxt:setString(common:getLanguageString("@RaidTitle"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = cfg[NgBattleDataManager.dungeonId].StageName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        local cfg = ConfigManager.getSingleBoss()[tonumber(NgBattleDataManager.SingleBossId)]
        titleTxt:setString(cfg.BossName)
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = cfg.BossName })
     elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        local cfg = ConfigManager:getTowerData()
        titleTxt:setString(common:getLanguageString("@RaidTitle"))
        NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mMonsterTitle = cfg[NgBattleDataManager.dungeonId].StageName })
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
        titleTxt:setString("TEST BATTLE")
    end
    NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { mPlayerTitle = UserInfo.roleInfo.name })
end
function NgBattlePageInfo:setQuestBtn(Info)
    if not NgBattleDataManager.battlePageContainer then
        return
    end
    local cfg=ConfigManager.getQuestCfg()
    local Tasks={}
    for k,v in pairs (cfg) do
        if v.team==13 then
            Tasks[k]=v
        end
    end
    --mTaskTxt mTaskIcon
    for i=1,#Info do
        local id=Info[i].id
        if Tasks[id] then
            if Info[i].questState==Const_pb.FINISHED then
                NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer,{mTaskTxt=common:getLanguageString("@CanClaim")})
                NodeHelper:setSpriteImage(NgBattleDataManager.battlePageContainer,{mTaskIcon=Tasks[id].icon})
            elseif Info[i].questState==Const_pb.ING then
                local count=Tasks[id].targetCount-UserInfo.stateInfo.passMapId
                NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer,{mTaskTxt=common:getLanguageString("@StageLeft",count)})
                NodeHelper:setSpriteImage(NgBattleDataManager.battlePageContainer,{mTaskIcon=Tasks[id].icon})
            end
        end
    end
end
-- 設定屬性加成圖示 (TODO 敵方顯示)
function NgBattlePageInfo:setElementIcon()
    for i = 1, 2 do
        local info = nil
        if i == 1 then info = NgBattleDataManager.serverPlayerInfo end  -- 玩家
        if i == 2 then info = NgBattleDataManager.serverEnemyInfo end  -- 敵方
        local sideStr = (i == 1) and "Player" or "Enemy"
        if info then
            local elementTable = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
            local buffTable = { }
            local teamBuffCfg = ConfigManager.getTeamBuffCfg()
            for idx = 1, CONST.HERO_COUNT do
                if info[idx] then
                    if i == 1 then  -- 玩家
                        local roleInfo = UserMercenaryManager:getUserMercenaryById(info[idx].roleId)
                        if roleInfo then
                            local heroCfg = ConfigManager.getNewHeroCfg()[roleInfo.itemId]
                            local element = heroCfg.Element
                            elementTable[element] = elementTable[element] + 1
                        end
                    elseif i == 2 then  -- 敵方
                        local pos = info[idx].posId % 10
                        if pos <= CONST.HERO_COUNT then
                            local element = info[idx].elements
                            elementTable[element] = elementTable[element] + 1
                        end
                    end
                end
            end
            local imgStr = "TeamBuff_"
            local bonusCount = 0
            NodeHelper:setNodesVisible(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "BonusTxt1"] = false, ["m" .. sideStr .. "BonusTxt2"] = false,
                                                                                  ["m" .. sideStr .. "BonusBg1"] = false, ["m" .. sideStr .. "BonusBg2"] = false })
            for idx = 1, #elementTable do
                if elementTable[idx] > 1 then          
                    imgStr = imgStr .. idx
                    bonusCount = bonusCount + 1
                    NodeHelper:setStringForLabel(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "BonusTxt" .. bonusCount] = elementTable[idx] })
                    NodeHelper:setNodesVisible(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "BonusTxt" .. bonusCount] = true, 
                                                                                          ["m" .. sideStr .. "BonusBg" .. bonusCount] = true })
                end
            end
            if bonusCount > 0 then
                imgStr = imgStr .. ".png"
                NodeHelper:setNodesVisible(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "Bonus"] = true })
                NodeHelper:setSpriteImage(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "BonusImg"] = imgStr })
            else
                NodeHelper:setNodesVisible(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "Bonus"] = true })
                NodeHelper:setSpriteImage(NgBattleDataManager.battlePageContainer, { ["m" .. sideStr .. "BonusImg"] = "TeamBuff_6.png" })
            end
        end
    end
end

function NgBattlePageInfo:initScene(container)
    --角色卡片初始化
    self:initTeamCard(container)

    local GuideManager = require("Guide.GuideManager")
    local sceneType = (GuideManager.isInGuide and GuideManager.currGuide[GuideManager.currGuideType] <= 10200) -- 101xx為教學用戰鬥
                      and NewBattleConst.SCENE_TYPE.GUIDE or NewBattleConst.SCENE_TYPE.AFK
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.INIT, 
                                  NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK and NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.GUIDE,
                                  true)
end
-- 刷新頁面
function NgBattlePageInfo_refreshPage()
    NgBattleDataManager.battleMapId = UserInfo.stateInfo.curBattleMap
    NgBattlePageInfo:setUIType(NgBattleDataManager.battlePageContainer)
    NgBattlePageInfo:setTitle()
    NgBattlePageInfo:setBattleBg()
    NgBattlePageInfo:setElementIcon()
    common:sendEmptyPacket(HP_pb.QUEST_GET_QUEST_LIST_C, false)--獲得任務列表
end
--  設定卡牌座標
function NgBattlePageInfo_resetCardPos(container)
    local orderId = 1
    for i = 1, 5 do 
        local cardMask = container:getVarNode("mRoleCard" .. i)
        cardMask:setVisible(true and NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK)
    end
    for i = 1, #NgBattleDataManager.battlePageContainer.teamCards do
        
        if NgBattleDataManager.battlePageContainer.teamCards[i].ccbiFile:isVisible() then
            NgBattleDataManager.battlePageContainer.teamCards[i].ccbiFile:setPosition(ccp(-382 + 139 * (orderId - 1), 117))
            local cardMask = container:getVarNode("mRoleCard" .. orderId)
            cardMask:setVisible(false)
            orderId = orderId + 1
        end
    end
end
-- 更新卡牌全部資訊
function NgBattlePageInfo_updateTargetCardInfo(index, character)
    if NgBattleDataManager.battlePageContainer.teamCards[index] then
        if character then
            NgBattleDataManager.battlePageContainer.teamCards[index]:updateCardInfo(character)
            NgBattleDataManager.battlePageContainer.teamCards[index].ccbiFile:setVisible(true)
        else
            NgBattleDataManager.battlePageContainer.teamCards[index].ccbiFile:setVisible(false)
        end
    end
end
-- 更新卡牌護盾資訊
function NgBattlePageInfo_updateTargetCardShieldInfo(index, shield, maxHp)
    if NgBattleDataManager.battlePageContainer.teamCards[index] then
        NgBattleDataManager.battlePageContainer.teamCards[index]:updateShield(shield, maxHp)
    end
end
-- 更新卡牌HP資訊
function NgBattlePageInfo_updateTargetCardHpInfo(index, hp, maxHp)
    if NgBattleDataManager.battlePageContainer.teamCards[index] then
        NgBattleDataManager.battlePageContainer.teamCards[index]:updateHp(hp, maxHp)
    end
end
-- 更新卡牌MP資訊
function NgBattlePageInfo_updateTargetCardMpInfo(index, mp, maxMp)
    if NgBattleDataManager.battlePageContainer.teamCards[index] then
        NgBattleDataManager.battlePageContainer.teamCards[index]:updateMp(mp, maxMp)
    end
end
-- 施放技能卡牌演出
function NgBattlePageInfo_useCardSkill(index)
    if NgBattleDataManager.battlePageContainer.teamCards[index] then
        -- 我方
        NgBattleDataManager.battlePageContainer.teamCards[index]:onHead()
    else
        -- 敵方
        local cha = NgBattleDataManager.battleEnemyCharacter[index - CONST.ENEMY_BASE_IDX]
        CHAR_UTIL:setSpineAnimation(cha, CONST.ANI_ACT.SKILL0, false)
    end
end
-- 重啟掛機戰鬥
function NgBattlePageInfo_restartAfk(container)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.AFK)
    NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.RESTART_AFK, CONST.SCENE_TYPE.AFK)
end
-- 挑戰下一關
function NgBattlePageInfo_testNextStage(container)
    NgBattleDataManager_setBattleType(CONST.SCENE_TYPE.AFK)
    NgBattlePageInfo:onDekaronBoss(container)
end
---------------------------------------------------------------------
-- 訊息處理
function NgBattlePageInfo:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        -- 刷新紅點顯示
        self:refreshAllPoint(container)
    end
end
-- 協定處理
function NgBattlePageInfo:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function NgBattlePageInfo:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function NgBattlePageInfo:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.SYNC_LEVEL_INFO_S then
        local msg = Battle_pb.NewBattleLevelInfo()
        msg:ParseFromString(msgBuff)
        local takeTime = msg.TakeTime or os.time()
        awardTime = takeTime
    elseif opcode == HP_pb.TAKE_FIGHT_AWARD_S then
        awardTime = os.time()
        timeTxt:setString("00:00:00")
        local msg = Battle_pb.NewBattleAward()
        msg:ParseFromString(msgBuff)
        local item = {}
        local drop = msg.drop
        local exp = msg.exp
        local coin = msg.SkyCoin

        if #drop > 0 then
            for i = 1, #drop do
                table.insert(item, {
                        type    = tonumber(drop[i].itemType),
                        itemId  = tonumber(drop[i].itemId),
                        count   = tonumber(drop[i].itemCount),
                })
            end
        end
        if #item > 0 then
            local CommonRewardPage = require("CommonRewardPageNew")
            CommonRewardPageNewBase_setPageParm(item, true)
            PageManager.pushPage("CommonRewardPageNew")
        end
        local GuideManager = require("Guide.GuideManager")
        local currStepCfg = GuideManager.getCurrentCfg()
        if currStepCfg and (currStepCfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK) then
            GuideManager.forceNextNewbieGuide()
        end
        PageManager.showRedNotice("Battle", false)
        common:sendEmptyPacket(HP_pb.SYNC_LEVEL_INFO_C)
    elseif opcode == HP_pb.BATTLE_FORMATION_S then
        local msg = Battle_pb.NewBattleFormation()
        msg:ParseFromString(msgBuff)
        if msg.type == CONST.FORMATION_PROTO_TYPE.REQUEST_ENEMY then
            NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.EDIT_TEAM)
            NgBattleDataManager_setServerEnemyInfo(msg.resultInfo)
            NgBattleDataManager_setBattleId(msg.battleId)
            NgBattleDataManager_setBattleType(msg.battleType)
            SimpleAudioEngine:sharedEngine():pauseAllEffects()
            --NodeHelper:setNodesVisible(container, { mAutoAni = NgBattleDataManager.battleIsAuto, mSpeedAni = NgBattleDataManager.battleSpeed == 2 })
            --NodeHelper:setNodesVisible(container, { mTopInfo = false })
            NodeHelper:setMenuItemEnabled(container, "InfoBtn", false)
        elseif msg.type == CONST.FORMATION_PROTO_TYPE.RESPONSE_PLAYER then
            NgBattleDataManager_setServerPlayerInfo(msg.resultInfo)
            NgBattleDataManager_setBattleType(msg.battleType)
            NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.INIT)
            PageManager.popPage("NgBattleEditTeamPage")
            ----新手教學
            --local GuideManager = require("Guide.GuideManager")
            --if GuideManager.isInGuide then
            --    PageManager.pushPage("NewbieGuideForcedPage")
            --end
        end
    elseif opcode == HP_pb.BATTLE_LOG_S or
           opcode == HP_pb.MULTI_BATTLE_LOG_S or
           opcode == HP_pb.PVP_BATTLE_LOG_S or
           opcode == HP_pb.WORLD_BOSS_BATTLE_LOG_S or
           opcode == HP_pb.DUNGEON_BATTLE_LOG_S or
           opcode == HP_pb.CYCLE_BATTLE_LOG_S or
           opcode == HP_pb.SINGLE_BOSS_BATTLE_LOG_S or
           opcode == HP_pb. SEASON_TOWER_BATTLE_LOG_S then
        local msg = Battle_pb.NewBattleLog()
        msg:ParseFromString(msgBuff)
        local result = msg.resault
        if result == NewFightResult.NEXT_LOG then
            NgBattleDataManager.serverLogId = NgBattleDataManager.serverLogId + 1
            NgBattlePageInfo_sendBattleResult()
        elseif result == NewFightResult.ERROR then
            MessageBoxPage:Msg_Box("ERRORCODE: " .. msg.errorCode)
            NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.RESULT_ERROR)
        else
            if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.POPUP_SALE) then
                local MainScenePageInfo = require("MainScenePage")
                MainScenePageInfo.RequestData()
            end
            NgFightSceneHelper:EnterState(container, CONST.FIGHT_STATE.SHOW_RESULT)
            if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
                common:sendEmptyPacket(HP_pb.SYNC_LEVEL_INFO_C)
            end
            RedPointManager_initSyncAllPageData()
        end
    elseif opcode == HP_pb.STATE_INFO_SYNC_S then
        local msg = Player_pb.HPPlayerStateSync()
        msg:ParseFromString(msgBuff)
        CCLuaLog("@onReceivePlayerStates -- BattlePageInfo")
        if msg ~= nil then
            UserInfo.stateInfo = msg
        end
    elseif opcode == HP_pb.GET_FORMATION_EDIT_INFO_S then
        local msg = Formation_pb.HPFormationEditInfoRes()
        msg:ParseFromString(msgBuff)
        self:parseAllGroupInfosMsg_New(container, msg)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local msg = Reward_pb.HPPlayerReward()
        msg:ParseFromString(msgBuff)
        CCLuaLog("@onReceivePlayerAward -- ")
        oTotalItemInfo = {}
        if msg ~= nil then
            if msg:HasField("rewards") then
                UserInfo.syncPlayerInfo()
            end
            local flag = msg.flag
            if flag == 1 or (NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP) then
                local wordList = { }
                local colorList = { }
                local rewards = msg.rewards.showItems
                for i = 1, #rewards do
                    local oneReward = rewards[i]
                    if oneReward.itemCount > 0 then
                        local ResManager = require "ResManagerForLua"
                        local resInfo = ResManagerForLua:getResInfoByTypeAndId(oneReward.itemType, oneReward.itemId, oneReward.itemCount)
                        table.insert(oTotalItemInfo, { type = oneReward.itemType, itemId = oneReward.itemId, count = oneReward.itemCount, info = resInfo })
                    end
                end
            end
            NgFightSceneHelper:setAward(oTotalItemInfo)
        else
            CCLuaLog("@onReceivePlayerAward -- error in data")
        end
    end
    if  opcode == HP_pb.QUEST_GET_QUEST_LIST_S then
		local msg = Quest_pb.HPGetQuestListRet()
		msg:ParseFromString(msgBuff)
		_lineTaskPacket,_curShowTaskInfo = MissionManager.AnalysisPacket(msg)
        NgBattlePageInfo:setQuestBtn(_curShowTaskInfo)
    end
    --if opcode == HP_pb.ACTIVITY177_FAILED_GIFT_S then
    --    local msg =Activity4_pb.Activity132LevelGiftBuyRes()
    --    msg:ParseFromString(msgBuff)
    --    local Page177=require('ActPopUpSale.ActPopUpSaleSubPage_177')
    --    Page177:BuySucc(msg)
    --end
end
-- 同步編隊資訊
function NgBattlePageInfo_sendTeamInfoToServer(teamInfo)
    local GuideManager = require("Guide.GuideManager")
    local msg = Battle_pb.NewBattleFormation()
    msg.type = CONST.FORMATION_PROTO_TYPE.RESPONSE_PLAYER
    msg.battleType = NgBattleDataManager.battleType
    for i = 1, #teamInfo do
        msg.rolePos:append(teamInfo[i])
    end
    msg.battleId = NgBattleDataManager.battleId
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        msg.mapId = tostring(NgBattleDataManager.battleMapId)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        msg.mapId = tostring(NgBattleDataManager.dungeonId)
        require("Dungeon.DungeonSubPage_Event")
        DungeonPageBase_setDungeonDataDirty(true)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        msg.defenderRank = NgBattleDataManager.defenderRank
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        msg.mapId = tostring(NgBattleDataManager.dungeonId)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        msg.mapId = tostring(NgBattleDataManager.dungeonId)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or 
           NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
        msg.mapId = tostring(NgBattleDataManager.SingleBossId)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
        msg.mapId = tostring(NgBattleDataManager.dungeonId)
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_FIGHT_TEAM then
        local EditMercenaryTeam = require("EditMercenaryTeamPage")
        local Ids = {}
        for i = 1 , 9 do
            Ids[i] = 0
        end 
        for _,val in pairs (teamInfo) do
            local id,index = unpack(common:split(val,"_"))
            Ids[tonumber(index)] = tonumber(id)
        end
        EditMercenaryTeam:sendEditTeamFormation(1, Ids)
        return
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.EDIT_DEFEND_TEAM then
        local EditMercenaryTeam = require("EditMercenaryTeamPage")
        local Ids = {}
        for i = 1 , 9 do
            Ids[i] = 0
        end 
        for _,val in pairs (teamInfo) do
            local id,index = unpack(common:split(val,"_"))
            Ids[tonumber(index)] = tonumber(id)
        end
        EditMercenaryTeam:sendEditTeamFormation(8, Ids)
        return
    end
    --MessageBoxPage:Msg_Box("MapId: " .. NgBattleDataManager.battleMapId .. ", BattleId: " .. NgBattleDataManager.battleId)
    if GuideManager.isInGuide then
        GuideManager.tempMsg[HP_pb.BATTLE_FORMATION_C] = msg
    end
    common:sendPacket(HP_pb.BATTLE_FORMATION_C, msg, GuideManager.isInGuide or false)
end
-- 取得隊伍資料
function NgBattlePageInfo:sendEditInfoReq(container, index)
    local groupStr = CCUserDefault:sharedUserDefault():getStringForKey("GROUP_INFOS_" .. index .. "_" .. UserInfo.playerInfo.playerId)
    if not groupStr or groupStr == "" then
        local msg = Formation_pb.HPFormationEditInfoReq()
        msg.index = index
        common:sendPacket(HP_pb.GET_FORMATION_EDIT_INFO_C, msg, false)
    else
        local groupInfo = common:split(groupStr, "_")
        local mAllGroupInfos = {}
        mAllGroupInfos[index] = { roleIds = { } }
        mAllGroupInfos[index].name = groupInfo[1]
        for i = 2, #groupInfo do
            table.insert(mAllGroupInfos[index].roleIds, tonumber(groupInfo[i]))
        end
        NgBattleDataManager_setServerGroupInfo(mAllGroupInfos[index])
        --初始化
        self:initScene(container)
    end
end
-- 接收編隊資訊
function NgBattlePageInfo:parseAllGroupInfosMsg_New(container, msg)
    local formation = msg.formations
    local mAllGroupInfos = {}
    mAllGroupInfos[formation.index] = { roleIds = { } }
    mAllGroupInfos[formation.index].name = formation.name
    local groupStr = formation.name .. "_"
    for i = 1, #formation.roleIds do
        table.insert(mAllGroupInfos[formation.index].roleIds, formation.roleIds[i])
        groupStr = groupStr .. formation.roleIds[i] .. "_"
    end
    CCUserDefault:sharedUserDefault():setStringForKey("GROUP_INFOS_" .. formation.index .. "_" .. UserInfo.playerInfo.playerId, groupStr) 
    NgBattleDataManager_setServerGroupInfo(mAllGroupInfos[formation.index])
    --初始化
    self:initScene(container)
end
-- 傳送戰鬥結果
function NgBattlePageInfo_sendBattleResult()
    require("Battle.NgBattleDataManager")
    -- 1-6必敗戰TEST
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        NgBattleDataManager.battleResult = math.floor((GuideManager.getCurrentStep() % 10000) / 100) == 10 and NewBattleConst.FIGHT_RESULT.LOSE or NgBattleDataManager.battleResult
    end
    -- 世界boss強制送勝利
    local resultType = (NgBattleDataManager.battleType == NewBattleConst.SCENE_TYPE.WORLD_BOSS) and NewBattleConst.FIGHT_RESULT.WIN or NgBattleDataManager.battleResult
    if not NgBattleDataManager.isSendResault or NgBattleDataManager.sendingLogId ~= NgBattleDataManager.serverLogId then
        NgBattleDataManager.isSendResault = true
        NgBattleDataManager.sendingLogId = NgBattleDataManager.serverLogId
        local msg = Battle_pb.NewBattleLog()
        msg.resault = tonumber(resultType)  --戰鬥結果
        ---------------------------------------------------------
        msg.battleId = NgBattleDataManager.battleId  --戰鬥id
        ---------------------------------------------------------
        -- log id
        msg.totleLogId = 1
        msg.logId = NgBattleDataManager.serverLogId
        ---------------------------------------------------------
        require("Battle.NgBattleDetailPage")
        local str = NgBattleDetailPage_formatLogString(resultType + 1)
        msg.tapdbjstr = str
        ---------------------------------------------------------
        if NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS then
            msg.battleScore = NewBattleUtil:getSingleBossScore()
        end
        ---------------------------------------------------------
        local GuideManager = require("Guide.GuideManager")
        local opcode = nil
        if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS or NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
            opcode = HP_pb.BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
            opcode = HP_pb.MULTI_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
            opcode = HP_pb.PVP_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
            opcode = HP_pb.WORLD_BOSS_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
            opcode = HP_pb.DUNGEON_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
            opcode = HP_pb.CYCLE_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
            opcode = HP_pb.SEASON_TOWER_BATTLE_LOG_C
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS then
            opcode = HP_pb.SINGLE_BOSS_BATTLE_LOG_C
        end
        if opcode then
            common:sendPacket(opcode, msg, true)
            if GuideManager.isInGuide then
                GuideManager.tempMsg[opcode] = msg
            end
        end
        PageManager.popPage("NgBattlePausePage")
        PageManager.popPage("DecisionPage")
    end
end

function NgBattlePageInfo:MiniGameSync(container)
    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
    if tonumber(closeR18) == 1 then
        NodeHelper:setNodesVisible(container,{mGameNode=false,mFightNode=true})
        return
    end
    require("FlagData")
    local data=FlagDataBase_GetData()
    local StoryTable=NgBattlePageInfo:GetTable()
    for key,value in pairs (StoryTable) do
        local stagetype= string.sub(value[1].id,5,6)
        local mID=tonumber(string.format("%02d", stagetype))
        GameId = mID
        if data[mID]==nil and UserInfo.stateInfo.curBattleMap>value[1].stage  then
            NodeHelper:setNodesVisible(container,{mGameNode=true,mFightNode=false})
            return GameId
        else
            NodeHelper:setNodesVisible(container,{mGameNode=false,mFightNode=true})
        end
    end
end
function NgBattlePageInfo:GetTable()
    local StoryCfg=ConfigManager.getStoryData()
    mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
                  (mapCfg[UserInfo.stateInfo.passMapId] and UserInfo.stateInfo.passMapId or UserInfo.stateInfo.curBattleMap - 1)
    --取story的key
    groupedTables = {}
    local keys = {}
    for k, _ in pairs(StoryCfg) do
        table.insert(keys, k)
    end
    --key排序
    table.sort(keys)
    --用key賦值
    local sortedStoryCfg = {}
    for k, v in ipairs(keys) do
        sortedStoryCfg[k] = StoryCfg[v]
    end
    --用關卡分類
    for k,v in pairs (sortedStoryCfg) do
       local stagetype=string.sub(v.id,4,5)
       local formated=tonumber(string.format("%d", stagetype))
       if not groupedTables[formated] then
             groupedTables[formated] = {}
       end
       table.insert(groupedTables[formated], v)
    end
    return groupedTables
end
-- 刷新minigame按鈕
function NgBattlePageInfo_refreshMinigame()
    NgBattlePageInfo:MiniGameSync(NgBattleDataManager.battlePageContainer)
end
-- 計算寶箱紅點
function NgBattlePageInfo_calIsShowRedPoint(option)
    local vipCfg = ConfigManager.getVipCfg()
    local curVipInfo = vipCfg[UserInfo.playerInfo.vipLevel]
    local maxTime = curVipInfo and curVipInfo["idleTime"] or 60 * 60 * 12
    return option.time >= maxTime
end
-- 刷新紅點
function NgBattlePageInfo:refreshAllPoint(container)
    NodeHelper:setNodesVisible(container, { mTreasurePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_TREASURE_BTN, 1) })
    NodeHelper:setNodesVisible(container, { mExpressPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_FAST_ENTRY, 1) })
    NodeHelper:setNodesVisible(container, { mQuestPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_QUEST_ENTRY, 1) })
end
---------------------------------------------------------------------

function NgBattlePageInfo:getRewardItemInfo()
    return oTotalItemInfo
end
function NgBattlePageInfo:showPopUpSale(id)
    local actData = self:getActData(id)
    if actData and actData.isShowIcon then
        local giftId = actData.id
        local popActStr = self:getPopActStr(id, giftId)
        --local activityCfg = ActivityConfig[id]

        local dayString = self:getCurrentDayString()
        if not dayString then
            print("Error: 無法取得有效的日期字串")
            return false
        end
        if popActStr ~= dayString then
            self:updatePopActStrForAll(dayString)
            self:pushPopUpPage(id)
            return true
        end
        --if not activityCfg.isResident then
        --   
        --elseif popActStr == "" then
        --    self:updatePopActStrForAll(id)
        --    self:pushPopUpPage(id)
        --    return true
        --end
    end
    return false
end

function NgBattlePageInfo:getActData(id)
    if id == 132 or id == 177 then
        return _G["ActPopUpSaleSubPage_" .. id .. "_getIsShowMainSceneIcon"]()
    else
        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
        return ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(id)
    end
end

function NgBattlePageInfo:getPopActStr(id, giftId)
    return CCUserDefault:sharedUserDefault():getStringForKey(
        "POP_ACT_" .. id .. "_" .. giftId .. "_" .. UserInfo.playerInfo.playerId
    )
end

function NgBattlePageInfo:getCurrentDayString()
    local TimeDateUtil = require("Util.TimeDateUtil")
    local clientSafeTime = TimeDateUtil:getClientSafeTime()
    if not clientSafeTime then return nil end  -- 處理 clientSafeTime 可能為 nil 的情況

    local nextDate = TimeDateUtil:utcTime2LocalDate(clientSafeTime)
    if nextDate then
        return nextDate.year .. "_" .. string.format("%02d", nextDate.month) .. "_" .. string.format("%02d", nextDate.day)
    else
        return nil  -- 日期轉換失敗時返回 nil
    end
end

function NgBattlePageInfo:updatePopActStrForAll(value)
    for _, otherId in pairs(ActivityInfo.PopUpSaleIds) do
        local otherActData = self:getActData(otherId)
        if otherActData and otherActData.isShowIcon then
            local otherGiftId = otherActData.id
            CCUserDefault:sharedUserDefault():setStringForKey(
                "POP_ACT_" .. otherId .. "_" .. otherGiftId .. "_" .. UserInfo.playerInfo.playerId,
                value
            )
        end
    end
end

function NgBattlePageInfo:pushPopUpPage(id)
    local actPopupSalePage = require("ActPopUpSale.ActPopUpSalePage")
    actPopupSalePage:setEntryTab(tostring(id))
    PageManager.pushPage("ActPopUpSale.ActPopUpSalePage")
end
---------------------------------------------------------------------

local CommonPage = require("CommonPage")
local NgBattlePageInfo = CommonPage.newSub(NgBattlePageInfo, thisPageName, option)

return NgBattlePageInfo