-- 戰鬥畫面處理
NgFightSceneHelper = NgFightSceneHelper or { }

local NodeHelper = require("NodeHelper")
local BuffManager = require("Battle.NewBuff.BuffManager")
local NgCharacterManager = require("Battle.NgCharacterManager")
local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
local UserMercenaryManager = require("UserMercenaryManager")
local FlyItemManager = require("FlyItemManager")
local SpriteManager = require("SpriteManager")
local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local PBHelper = require("PBHelper")
--------------------------------------------------------------------------------
local fightNode = nil

local mapCfg = ConfigManager.getNewMapCfg()

local SHAKE_ACTION_TAG = 1000
local oTotalItemInfo = { }

local castSkillMask = nil       -- 施放大招遮罩

local skillIdCounter = 0
local sceneFxTimer = 0

local battleResultData = { }
local specialSpineItems = { }

function NgFightSceneHelper:onExit()
    FlyItemManager:clearData()
    NgBattleDataManager_clearBattleData()
    castSkillMask = nil
end
-- 進入狀態之後的處理
function NgFightSceneHelper:EnterState(container, state, isSkipInitChar, isEnterPage)
    CCLuaLog("NgFightSceneHelper:EnterState" .. state)
    NgBattleDataManager_setBattleState(state)
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.EDIT_TEAM then
        self:openEditTeamPage(container)
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.INIT then
        self.container = container
        NgBattleDataManager_setIsSkipInitChar(isSkipInitChar)
        NgBattleDataManager_setBattleTime(0)
        NgBattleDataManager_setPlayerLevel(UserInfo.roleInfo.level)
        SpriteManager:clearSpriteData()
        NgBattleDataManager_setCastSkillNode(nil)
        self:createFightNode(container)
        self:clearSceneVar()
        self:setGameBgm()
        self:createCastSkillMask()
        self:createBgParticle(container)
        self:clearSceneFx(container)
        self:clearSpecialSpine()  

        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide and GuideManager.currGuide[GuideManager.currGuideType] <= 10200 then
            NgBattleDataManager_setBattleMapId(9999)
        end

        NgBattlePageInfo_refreshPage()

        if isEnterPage then
            if NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP or 
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI or
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS or 
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON or
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER or
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM or
               NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER  then
                NgBattleDataManager_setBattleState(CONST.FIGHT_STATE.EDIT_TEAM) -- 避免非主線關卡編隊時倒數戰鬥時間
            end
        end  
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.START_CHALLANGE then
        self:playStartChallange(container)
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.BOSS_CUTIN then
        self:playBossCutin(container, mapCfg[NgBattleDataManager.battleMapId].Portrait)
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING then
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then 
            local currStepCfg = GuideManager.getCurrentCfg()
            if currStepCfg and (currStepCfg.showType == GameConfig.GUIDE_TYPE.OPEN_MASK_WAIT_BATTLE_INIT) then
                GuideManager.forceNextNewbieGuide()
            end
        else
            if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
                -- 關卡進度解鎖引導
                GuideManager.openOtherGuideFun(GuideManager.guideType.AUTO_SKILL, false)
            end
        end
        self:castStartBattleSkill()
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.SHOW_RESULT then
        if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.GUIDE then
            local resultData = battleResultData
            PageManager.popPage("NgBattlePausePage")
            local resultPage = require("NgBattleResultPage")
            resultPage:setAward(oTotalItemInfo)
            NgBattleResultManager.showReslut = true
            NgBattleResultManager.showLevelUp = UserInfo.checkLevelUp(true)

            local GameId = NgBattlePageInfo:MiniGameSync()
            local StoryTable=NgBattlePageInfo:GetTable()
            local stage
            for _,data in pairs (StoryTable) do
                local stagetype= string.sub(data[1].id,5,6)
                local mID=tonumber(string.format("%02d", stagetype))
                if mID == GameId then
                    stage = data[1].stage
                end
            end
            if (NgBattleDataManager.battleResult == CONST.FIGHT_RESULT.WIN and NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS) then
                NgBattleResultManager.showHStory = NgFightSceneHelper:StroyDisplay(stage)
                NgBattleResultManager.showMainStory = NgFightSceneHelper:StorySync(2)--1:戰鬥前 2:戰鬥後
            end
            NgBattleResultManager_playNextResult()
        end
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.RESTART_AFK then
        NgBattleDataManager_clearBattleData()
        SpriteManager:clearSpriteData()
        NgBattleDataManager_setCastSkillNode(nil)
        self:clearSceneVar()
        self:createFightNode(container)
        self:createCastSkillMask()
        self:createBgParticle(container)
        self:clearSceneFx(container)
        self:setSceneSpeed(CONST.AFK_BATTLE_SPEED)

        NgBattlePageInfo_refreshPage()

        --self:EnterState(container, CONST.FIGHT_STATE.MOVING)
        self:setGameBgm()
    elseif NgBattleDataManager.battleState == CONST.FIGHT_STATE.RESULT_ERROR then
        if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
            require("Battle.NgBattlePage")
            NgBattlePageInfo_restartAfk(NgBattleDataManager.battlePageContainer)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(48)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(21)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(45)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(49)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then        
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(51)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS then        
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(52)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then        
            local PageJumpMange = require("PageJumpMange")
            PageJumpMange.JumpPageById(53)
        else
            self:EnterState(container, CONST.FIGHT_STATE.FIGHTING)
        end
    end
end

function NgFightSceneHelper:UpdateState(container, dt)
    if (NgBattleDataManager.battleState == CONST.FIGHT_STATE.INIT) then
        if not NgBattleDataManager.isSkipInitChar then
            self:initAllChaNode(container)
        else
            NgBattleDataManager_setIsInitCharEnd(true)
        end
        if NgBattleDataManager.isInitCharEnd then
            local PageJumpMange = require("PageJumpMange")
            if not PageJumpMange._IsPageJump then
                require("TransScenePopUp")
                TransScenePopUp_closePage()
            end
            --新手教學
            local GuideManager = require("Guide.GuideManager")
            if GuideManager.isInGuide then
                PageManager.pushPage("NewbieGuideForcedPage")
            end
            if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
                if self:isBossMapId(NgBattleDataManager.battleMapId) then
                    self:EnterState(container, CONST.FIGHT_STATE.BOSS_CUTIN)
                else
                    self:EnterState(container, CONST.FIGHT_STATE.START_CHALLANGE)
                end
            elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP or 
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.SEASON_TOWER then
                self:EnterState(container, CONST.FIGHT_STATE.START_CHALLANGE)
            else
                self:EnterState(container, CONST.FIGHT_STATE.MOVING)
            end 
        end
    elseif (NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING) then
        local heroList = NgBattleDataManager.battleMineCharacter
        local enemyList = NgBattleDataManager.battleEnemyCharacter
        local moveEnd = true
        for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
            if heroList[i] and CHAR_UTIL:getState(heroList[i]) == CONST.CHARACTER_STATE.INIT then
                moveEnd = false
                break
            end
            if enemyList[i] and CHAR_UTIL:getState(enemyList[i]) == CONST.CHARACTER_STATE.INIT then
                moveEnd = false
                break
            end
        end
        if moveEnd then
            self:EnterState(container, CONST.FIGHT_STATE.FIGHTING)
        end
    elseif (NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING) then
    elseif (NgBattleDataManager.battleState == CONST.FIGHT_STATE.RESTART_AFK) then
        if NgBattleDataManager.isInitCharEnd then
            require("TransScenePopUp")
            TransScenePopUp_closePage()
            self:EnterState(container, CONST.FIGHT_STATE.MOVING)
        else
            self:initAllChaNode(container)
        end
    end
end

function NgFightSceneHelper:openEditTeamPage(container)
    PageManager.pushPage("NgBattleEditTeamPage")
    local GuideManager = require("Guide.GuideManager")
    -- 關閉遮罩
    if GuideManager.isInGuide then 
        GuideManager.forceNextNewbieGuide()
    end
    -- 關卡進度解鎖引導
    GuideManager.openOtherGuideFun(GuideManager.guideType.EDIT_TEAM_17, false)
    -- 有戰前劇情->播放劇情 沒有劇情進行下一步教學
    if NgFightSceneHelper:StorySync(1) and NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.CYCLE_TOWER  then
        PageManager.pushPage("FetterGirlsDiary")
    else
        if GuideManager.isInGuide then 
            GuideManager.forceNextNewbieGuide()
        end
    end
end
function NgFightSceneHelper:StorySync(storyIdx)
    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
    if tonumber(closeR18) == 1 then
        return false
    end
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS or NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        local mapId = NgBattleDataManager.battleMapId
        local chapter = mapCfg[mapId].Chapter
        local level = mapCfg[mapId].Level
        local id = tonumber( string.format("%02d", chapter) .. string.format("%02d", level).. storyIdx .. "01")
        local fetterControlCfg = ConfigManager:getFetterBDSMControlCfg()
        if fetterControlCfg[id] then
            require("FetterGirlsDiary")
            FetterGirlsDiary_setPhotoRole(container, chapter, level,storyIdx)
            return true
            --PageManager.pushPage("FetterGirlsDiary")
        end
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        local mapId = NgBattleDataManager.TowerId
        local EventDataMgr = require("Event001DataMgr")
        local StoryCfg = EventDataMgr[EventDataMgr.nowActivityId].FETTER_CONTROL_CFG
        local StageCfg = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG
        local chapter = StageCfg[mapId].type
        local level = StageCfg[mapId].star
        local id = tonumber(chapter .. string.format("%02d", level).. storyIdx .. "01")
        if StoryCfg[id] then
            local Event001Page = require "Event001Page"
            local NowPassedId = Event001Page:getStageInfo().PassedId
            if mapId <= NowPassedId then return false end
            require("Event001AVG")
            Event001AVG_setPhotoRole(nil, chapter, level, storyIdx )
            PageManager.pushPage("Event001AVG")
            return true
        end
    end
    return false
end
function NgFightSceneHelper:playStartChallange(container)
    local startChallange = require("BattleStartChallange")
    PageManager.pushPage("BattleStartChallange")
end

function NgFightSceneHelper:playBossCutin(container, id)
    local bossWarning = require("BattleBossWarning")
    bossWarning:setMonsterId(id)
    PageManager.pushPage("BattleBossWarning")
end

function NgFightSceneHelper:update(container, dt)
    if PageManager.getIsInSummonPage() or PageManager.getIsInGirlDiaryPage() or PageManager.getIsInLevelUpPage() then
        return
    end
    local GuideManager = require("Guide.GuideManager")
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        local currStepCfg = GuideManager.getCurrentCfg()
        if currStepCfg and ((currStepCfg.showType % 10) ~= GameConfig.GUIDE_TYPE.OPEN_MASK) then   -- 不在戰鬥演出中
            if not NgBattleDataManager.battleIsPause then
                NgBattleDataManager_setBattleIsPause(true)
                self:setSceneSpeed(0)
            end
            return
        elseif NgBattleDataManager.battleIsPause then
            NgBattleDataManager_setBattleIsPause(false)
            self:setSceneSpeed(CONST.GUIDE_BATTLE_SPEED)
        end
    elseif GuideManager.isInGuide then
        local currStepCfg = GuideManager.getCurrentCfg()
        if currStepCfg and currStepCfg.stopBattle == 1 and
           NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then   -- 不在戰鬥演出中
            if not NgBattleDataManager.battleIsPause then
                NgBattleDataManager_setBattleIsPause(true)
                self:setSceneSpeed(0)
            end
            return
        elseif NgBattleDataManager.battleIsPause then
            NgBattleDataManager_setBattleIsPause(false)
            self:setSceneSpeed(NgBattleDataManager.battleSpeed)
        end
    end
    if NgBattleDataManager.battleIsPause then
        self:setSceneSpeed(0)
        return
    end
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.MOVING and 
       NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then 
        self:setMaskLayerVisible(false) -- 非戰鬥中清除
    end
    if self:getMaskLayerVisible() then
        self:setSkillSceneSpeed(true)
        return
    end
    if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or 
       NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then 
       --NgBattleDataManager.battleState == CONST.FIGHT_STATE.SHOW_RESULT then
        if not NgBattleDataManager.battleIsPause and not self:getMaskLayerVisible() then
            -- 更新戰鬥時間
            NgBattleDataManager_setBattleTime(NgBattleDataManager.battleTime + dt * NgBattleDataManager.battleSpeed)
            -- 更新timer
            for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
                if NgBattleDataManager.battleMineCharacter[i] then
                    NgBattleCharacterBase:updateTimer(dt * NgBattleDataManager.battleSpeed, true, i)
                end
                if NgBattleDataManager.battleEnemyCharacter[i] then
                    NgBattleCharacterBase:updateTimer(dt * NgBattleDataManager.battleSpeed, false, i)
                end
            end
            -- 角色動作
            for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
                if NgBattleDataManager.battleMineCharacter[i] then
                    NgBattleCharacterBase:update(dt * NgBattleDataManager.battleSpeed, true, i)
                end
                if NgBattleDataManager.battleEnemyCharacter[i] then
                    NgBattleCharacterBase:update(dt * NgBattleDataManager.battleSpeed, false, i)
                end
            end
            -- 飛行道具
            FlyItemManager:update(dt * NgBattleDataManager.battleSpeed) 
            -- 場景特效時間
            sceneFxTimer = sceneFxTimer - dt * NgBattleDataManager.battleSpeed
            if sceneFxTimer <= 0 then
                self:clearSceneFx(self.container)
            end
            -- 戰鬥倒數計時顯示           
            if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK then
                local battleMaxTime = CONST.BATTLE_LIMIT_TIME
                if NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE then
                    battleMaxTime = NgBattleDataManager.testBatteTime
                end
                local time = math.max(battleMaxTime - NgBattleDataManager.battleTime, 0)
                local lastTime = math.floor(time / 1000)
                local m = math.floor(lastTime / 60)
                local s = math.floor(lastTime % 60)
                local timeStr = string.format("%02d", m) .. " : " .. string.format("%02d", s)
                NodeHelper:setStringForTTFLabel(self.container, { mTimer = timeStr })
                if lastTime <= 0 then
                    NgBattleDataManager_setBattleResult(CONST.FIGHT_RESULT.LOSE)
                    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
                        self:EnterState(container, CONST.FIGHT_STATE.SHOW_RESULT)
                    else
                        self:EnterState(container, CONST.FIGHT_STATE.SEND_RESULT)
                    
                        require("Battle.NgBattlePage")
                        NgBattlePageInfo_sendBattleResult()
                    end
                end
                NodeHelper:setNodesVisible(self.container, { mCountDownNode = (time <= CONST.BATTLE_COUNT_DOWN_ALART_TIME) })
            end
            -- 單人強敵分數
            if NgBattleDataManager.battleState == CONST.FIGHT_STATE.MOVING or 
               NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then
                if NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
                   NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM  then
                    NewBattleUtil:setSingleBossScoreBar(container)
                end
            end
            -- TODO 未開放精靈先關閉
            ---- 更新精靈卡牌顯示
            --NgBattlePageInfo_updateSpriteCard(NgBattleDataManager.battlePageContainer)
            ---- 觸發精靈行為   *先檢查戰鬥結束時間(90秒時不觸發)
            --SpriteManager:updateSprite(dt * NgBattleDataManager.battleSpeed)
        end
    end
end

function NgFightSceneHelper:initAllChaNode(container)
    --self.container = container
    -- 初始化角色
    NgCharacterManager:initAllChaNode()
    NgBattleDataManager_setIsInitCharEnd(true)
    --NgCharacterManager:initTarChaNode(NgBattleDataManager.nowInitCharPos)
    --if NgBattleDataManager.nowInitCharPos > NewBattleConst.ENEMY_BASE_IDX * 2 then
    --    NgBattleDataManager_setIsInitCharEnd(true)
        -- 初始化戰鬥速度 需等角色初始化完畢(掛機=1.5, 不會低於1)
        local battleSpeed = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and CONST.AFK_BATTLE_SPEED or
                            CCUserDefault:sharedUserDefault():getFloatForKey("NEW_BATTLE_SPEED_" ..  UserInfo.playerInfo.playerId)
        local isVipSpeed = CCUserDefault:sharedUserDefault():getBoolForKey("NEW_BATTLE_VIP_SPEED_" ..  UserInfo.playerInfo.playerId)
        battleSpeed = isVipSpeed and 4 or battleSpeed
        self:setSceneSpeed(math.max(1.5, battleSpeed))
    --end
end

function NgFightSceneHelper:setSceneSpeed(speed)
    -- 紀錄戰場速度資料
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then  -- 掛機戰鬥強制設為1.5倍速
        NgBattleDataManager_setBattleSpeed(CONST.AFK_BATTLE_SPEED)
    elseif speed ~= 0 then  -- 時停時不更改manager資料
        NgBattleDataManager_setBattleSpeed(speed)
    end

    for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do -- 設定各角色速度(判斷控場/施放技能..)
        local chaSpeed = speed
        local buffSpeed = speed
        if NgBattleDataManager.battleMineCharacter[i] then  -- 我方角色
            if BuffManager:isInCrowdControl(NgBattleDataManager.battleMineCharacter[i].buffData) then   -- 被控場中
                chaSpeed = 0
            elseif NgBattleDataManager.castSkillNode and NgBattleDataManager.castSkillNode ~= NgBattleDataManager.battleMineCharacter[i] then -- 施放技能中&不是自己
                chaSpeed = 0
                buffSpeed = 0
            elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then  -- 掛機=1.5倍速
                chaSpeed = CONST.AFK_BATTLE_SPEED
                buffSpeed = CONST.AFK_BATTLE_SPEED
            end
            if NgBattleDataManager.battleIsPause then
                chaSpeed = 0
                buffSpeed = 0
            end
            -- 對該角色全部spine重設timeScale
            for k, v in pairs(NgBattleDataManager.battleMineCharacter[i].allSpineTable) do
                if string.find(k, "FX") or k < CONST.BUFF_ID_FX1_OFFSET then    -- 角色spine
                    v:setTimeScale(chaSpeed)
                else    -- Buff spine
                    v:setTimeScale(buffSpeed)
                end
            end
        end
        chaSpeed = speed
        buffSpeed = speed
        if NgBattleDataManager.battleEnemyCharacter[i] then -- 敵方角色
            if BuffManager:isInCrowdControl(NgBattleDataManager.battleEnemyCharacter[i].buffData) then   -- 被控場中
                chaSpeed = 0
            elseif NgBattleDataManager.castSkillNode and NgBattleDataManager.castSkillNode ~= NgBattleDataManager.battleEnemyCharacter[i] then -- 施放技能中&不是自己
                chaSpeed = 0
                buffSpeed = 0
            elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then  -- 掛機=1.5倍速
                chaSpeed = CONST.AFK_BATTLE_SPEED
                buffSpeed = CONST.AFK_BATTLE_SPEED
            end
            if NgBattleDataManager.battleIsPause then
                chaSpeed = 0
                buffSpeed = 0
            end
            -- 對該角色全部spine設定timeScale
            for k, v in pairs(NgBattleDataManager.battleEnemyCharacter[i].allSpineTable) do
                if string.find(k, "FX") or k < CONST.BUFF_ID_FX1_OFFSET then    -- 角色spine
                    v:setTimeScale(chaSpeed)
                else    -- Buff spine
                    v:setTimeScale(buffSpeed)
                end
            end
        end
    end
    for i = 1 + CONST.HERO_COUNT, CONST.HERO_COUNT + CONST.SPRITE_COUNT do -- 設定各精靈速度
        local chaSpeed = speed
        if NgBattleDataManager.battleMineSprite[i] then  -- 我方精靈
            if NgBattleDataManager.castSkillNode and NgBattleDataManager.castSkillNode ~= NgBattleDataManager.battleMineSprite[i] then -- 施放技能中&不是自己
                chaSpeed = 0
            end
            -- 對該精靈全部spine重設timeScale
            for k, v in pairs(NgBattleDataManager.battleMineSprite[i].allSpineTable) do
                v:setTimeScale(speed)
            end
        end
        chaSpeed = speed
        if NgBattleDataManager.battleEnemySprite[i] then -- 敵方精靈
            if NgBattleDataManager.castSkillNode and NgBattleDataManager.castSkillNode ~= NgBattleDataManager.battleEnemySprite[i] then -- 施放技能中&不是自己
                chaSpeed = 0
            end
            -- 對該精靈全部spine設定timeScale
            for k, v in pairs(NgBattleDataManager.battleEnemySprite[i].allSpineTable) do
                v:setTimeScale(speed)
            end
        end
    end
    -- 對全部飛行道具設定timeScale
    FlyItemManager:setSceneSpeed(speed)
end

--檢查戰鬥結果
function NgFightSceneHelper:checkBattleResult()
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        return
    end
    local isWin = true
    local isLose = true
    local heroList = NgBattleDataManager.battleMineCharacter
    local enemyList = NgBattleDataManager.battleEnemyCharacter
    for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
        if heroList[i] then
            if CHAR_UTIL:getState(heroList[i]) ~= CONST.CHARACTER_STATE.DEATH then
                isLose = false
                break
            end 
        end
    end
    for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
        if enemyList[i] then
            if CHAR_UTIL:getState(enemyList[i]) ~= CONST.CHARACTER_STATE.DEATH then
                isWin = false
                break
            end 
        end
    end
    if isWin or isLose then
        -- 清空角色身上action
        for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
            if heroList[i] then
                heroList[i].heroNode.chaCCB:stopAllActions()
            end
            if enemyList[i] then
                enemyList[i].heroNode.chaCCB:stopAllActions()
            end
        end
        NgBattleDataManager_setBattleResult(isLose and CONST.FIGHT_RESULT.LOSE or CONST.FIGHT_RESULT.WIN)
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide and NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
            self:EnterState(container, CONST.FIGHT_STATE.SHOW_RESULT)
        elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM then
            self:EnterState(container, CONST.FIGHT_STATE.SHOW_RESULT)
        else
            self:EnterState(container, CONST.FIGHT_STATE.SEND_RESULT)
            NgBattlePageInfo_sendBattleResult()
        end
    else
        NgBattleDataManager_setBattleResult(CONST.FIGHT_RESULT.LOSE)
    end
end

function NgFightSceneHelper:playSceneShake()
    for i = 1, 2 do
        local shakeNode = self.container:getVarNode(i == 1 and "mShakeNode" or "mBg")
        if not shakeNode:getActionByTag(SHAKE_ACTION_TAG + i) then
            shakeNode:stopActionByTag(SHAKE_ACTION_TAG + i)
            local array = CCArray:create()
            array:addObject(CCMoveBy:create(0.05, ccp(10 * math.tan(math.deg(18)), -10)))
            array:addObject(CCMoveBy:create(0.05, ccp(10 * math.atan(math.deg(54)), 10)))
            array:addObject(CCMoveTo:create(0.05, ccp(-360, (i == 1 and 0 or -64))))
            local action = CCSequence:create(array)
            action:setTag(SHAKE_ACTION_TAG + i)
            shakeNode:runAction(action)
        end
    end
end

function NgFightSceneHelper:playSpecialSpine(tag)
    --local spine = SpineContainer:create("Spine/NGUI", "NGUI_53_Gacha1Summon_BG")
    --spine:registerFunctionHandler("END", self.onFunction)
    --local sToNode = tolua.cast(spine, "CCNode")
    --local parentNode = self.container:getVarNode("mSkillSpineNode")
    --sToNode:setTag(tag)
    --parentNode:addChild(sToNode)
    --specialSpineItems[tag] = sToNode
    --spine:setToSetupPose()
    --spine:setTimeScale(NgBattleDataManager.battleSpeed)
    --spine:runAnimation(1, "sunmmon", 0)
end

function NgFightSceneHelper:clearSpecialSpine()
    for k, v in pairs(specialSpineItems) do
        specialSpineItems[k]:removeFromParentAndCleanup(true)
        specialSpineItems[k] = nil
        NgFightSceneHelper:setMaskLayerVisible(false)      -- 關閉黑幕
        NgBattleDataManager_setCastSkillNode(nil)   -- 解除當前施放大招的角色
        NgFightSceneHelper:setSkillSceneSpeed(false)       -- 還原Spine Timescale
    end
end

function NgFightSceneHelper:onFunction(tag, eventName)
    if eventName == "END" then
        specialSpineItems[tag]:removeFromParentAndCleanup(true)
        specialSpineItems[tag] = nil
        NgFightSceneHelper:setMaskLayerVisible(false)      -- 關閉黑幕
        NgBattleDataManager_setCastSkillNode(nil)   -- 解除當前施放大招的角色
        NgFightSceneHelper:setSkillSceneSpeed(false)       -- 還原Spine Timescale
    end
end

function NgFightSceneHelper:setAward(awardInfo)
    oTotalItemInfo = awardInfo
end

function NgFightSceneHelper:getFlyItemManager()
    return FlyItemManager
end

function NgFightSceneHelper:setMaskLayerVisible(visible)
    if castSkillMask then
        castSkillMask:setVisible(visible)
    end
end

function NgFightSceneHelper:getMaskLayerVisible()
    return castSkillMask and castSkillMask:isVisible() or false
end

function NgFightSceneHelper:addBattleResult(dataType, pos, num, skillId, isCri, trueNum)
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        return
    end
    NgBattleDataManager.battleDetailData[pos] = NgBattleDataManager.battleDetailData[pos] or { }
    NgBattleDataManager.battleDetailData[pos][dataType] = NgBattleDataManager.battleDetailData[pos][dataType] and 
                                                          NgBattleDataManager.battleDetailData[pos][dataType] + tonumber(num) or tonumber(num) or 0
    -- 測試用
    NgBattleDataManager.battleDetailDataTest[pos] = NgBattleDataManager.battleDetailDataTest[pos] or { }
    NgBattleDataManager.battleDetailDataTest[pos][dataType] = NgBattleDataManager.battleDetailDataTest[pos][dataType] or { }
    NgBattleDataManager.battleDetailDataTest[pos][dataType][skillId or 0] = NgBattleDataManager.battleDetailDataTest[pos][dataType][skillId or 0] or { }
    local data = NgBattleDataManager.battleDetailDataTest[pos][dataType][skillId or 0]
    if trueNum == 0 then
        data["MISS"] = data["MISS"] or { ["COUNT"] = 0 }
        data["MISS"]["COUNT"] = data["MISS"]["COUNT"] + 1
    elseif isCri then
        data["CRI"] = data["CRI"] or { ["COUNT"] = 0, ["DMG"] = 0, ["TRUE_DMG"] = 0 }
        data["CRI"]["COUNT"] = data["CRI"]["COUNT"] + 1
        data["CRI"]["DMG"] = data["CRI"]["DMG"] + num
        data["CRI"]["TRUE_DMG"] = data["CRI"]["TRUE_DMG"] + trueNum
    else
        data["NORMAL"] = data["NORMAL"] or { ["COUNT"] = 0, ["DMG"] = 0, ["TRUE_DMG"] = 0 }
        data["NORMAL"]["COUNT"] = data["NORMAL"]["COUNT"] + 1
        data["NORMAL"]["DMG"] = data["NORMAL"]["DMG"] + num
        data["NORMAL"]["TRUE_DMG"] = data["NORMAL"]["TRUE_DMG"] + trueNum
    end
    data["TOTAL"] = data["TOTAL"] or { ["COUNT"] = 0 }
    data["TOTAL"]["COUNT"] = data["TOTAL"]["COUNT"] + 1
end

function NgFightSceneHelper:setSkillSpineOrder(visible)
    if NgBattleDataManager.castSkillNode then
        NgBattleDataManager.castSkillNode.heroNode.chaCCB:setZOrder(visible and CONST.SPINE_USE_SKILL_Z_ORDER or 
                                                                                CONST.Z_ORDER_MASK - NgBattleDataManager.castSkillNode.heroNode.chaCCB:getPositionY())
    end
end

function NgFightSceneHelper:setSkillSceneSpeed(visible)
    self:setSceneSpeed(NgBattleDataManager.battleSpeed)
end

function NgFightSceneHelper:clearSceneVar()
    oTotalItemInfo = { }
    specialSpineItems = { }
    battleResultData = { }
    FlyItemManager:init()
    skillIdCounter = 0
    NewBattleUtil:clearLog()
    local ALFManager = require("Util.AsyncLoadFileManager")
    for k, v in pairs(NgBattleDataManager.asyncLoadTasks) do 
        for k2, v2 in pairs(v) do 
            ALFManager:cancel(v2)
        end
    end
    NgBattleDataManager.asyncLoadTasks = { }
end

function NgFightSceneHelper:getNewSkillGroupId()
    skillIdCounter = skillIdCounter + 1
    return skillIdCounter
end

function NgFightSceneHelper:createFightNode(container)
    fightNode = container:getVarNode("mContent")
    fightNode:removeAllChildrenWithCleanup(true)
    self:createFX4Node(container, fightNode)
end
--[[-----7(最底層,低於fx3)--
    ------7------
    |     6     |
    |     5     |
    |     4     |
    |     3     |
    |     2     |
    ------1------
--]]
function NgFightSceneHelper:createFX4Node(container, fightNode)
    for i = 0, 6 do
        local node = CCNode:create()
        node:setTag(CONST.FX4_NODE_TAG_VALUE + (i + 1))
        fightNode:addChild(node)
        if i < 6 then
            node:setPosition(ccp(CONST.BATTLE_FIELD_WIDTH / 2, CONST.BATTLE_FIELD_HEIGHT / 7 * (i + 1)))
        end
        if i == 6 then
            node:setZOrder(-1 * CONST.FLOOR_Z_ORDER_MASK)
        else
            node:setZOrder(CONST.Z_ORDER_MASK - node:getPositionY())
        end
        CCLuaLog(">>>FX4 Node Pos : x = " .. node:getPositionX() .. ", y = " .. node:getPositionY())
        CCLuaLog(">>>FX4 Node ZOrder = " .. node:getZOrder())
    end
end

function NgFightSceneHelper:clearSceneFx(container)
    if container then
        local parent = container:getVarNode("mSceneFxNode")
        if parent:getChildrenCount() > 0 then
            parent:removeAllChildrenWithCleanup(true)
            parent:setVisible(false)
            sceneFxTimer = 0
        end
    end
end
function NgFightSceneHelper:createSceneFx(ccbiFileName, time)
    if self.container then
        local parent = self.container:getVarNode("mSceneFxNode")
        parent:removeAllChildrenWithCleanup(true)
        parent:setVisible(true)
        local spriteContainter = ScriptContentBase:create(ccbiFileName)
        parent:addChild(spriteContainter)
        spriteContainter:release()

        sceneFxTimer = time
    end
end

function NgFightSceneHelper:createCastSkillMask()
    castSkillMask = CCLayerColor:create(ccc4(0, 0, 0, 180))
    fightNode:addChild(castSkillMask)
    castSkillMask:setZOrder(CONST.SKILL_MASK_Z_ORDER)
    castSkillMask:setContentSize(CCSize(1500, 2000))
    castSkillMask:setAnchorPoint(ccp(0, 0))
    castSkillMask:setPosition(ccp(CONST.BATTLE_FIELD_WIDTH / 2 - 750, -1 * fightNode:getPositionY()))
    castSkillMask:setVisible(false)
end

function NgFightSceneHelper:createBgParticle(container)
    --local fileName = ""
    --if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK or 
    --   NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
    --    fileName = "BattlePageBg" .. string.format("%02d", math.ceil(NgBattleDataManager.battleMapId / 10))
    --elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP or 
    --       NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
    --    fileName = "BattlePageBgArena01"
    --else
    --    return
    --end
    ---- set bg particle
    --local particleNode = CCNode:create()
    --fightNode:addChild(particleNode)
    --particleNode:setPosition(ccp(fightNode:getPositionX() * -1, fightNode:getPositionY() * -1))
    --if NodeHelper:isFileExist(fileName .. ".ccbi") then
    --    local spriteContainter = ScriptContentBase:create(fileName .. ".ccbi")
    --    particleNode:addChild(spriteContainter)
    --    spriteContainter:release()
    --end
    ---- set bg back particle
    --local particleBackNode = container:getVarNode("mBgBackParticle")
    --particleBackNode:removeAllChildrenWithCleanup(true)
    --if NodeHelper:isFileExist(fileName .. "_2.ccbi") then
    --    local spriteBackContainter = ScriptContentBase:create(fileName .. "_2.ccbi")
    --    particleBackNode:addChild(spriteBackContainter)
    --    spriteBackContainter:release()
    --end
end


function NgFightSceneHelper:castStartBattleSkill()
    for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
        if NgBattleDataManager.battleIsPause or self:getMaskLayerVisible() then
            break
        end
        local heroList = NgBattleDataManager.battleMineCharacter
        local enemyList = NgBattleDataManager.battleEnemyCharacter
        if heroList[i] then
            NgBattleCharacterBase:castStartBattleSkill(heroList[i])
        end
        if enemyList[i] then
            NgBattleCharacterBase:castStartBattleSkill(enemyList[i])
        end
    end
end

function NgFightSceneHelper:playSoundEffect(effectName, chaNode)
    if PageManager.getIsInSummonPage() or PageManager.getIsInGirlDiaryPage() or PageManager.getIsInLevelUpPage() then
        return
    end
    if not effectName then
        return nil
    end
    if not chaNode or (not chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO) then
        return nil
    end
    if (not string.find(effectName, "Weapon_") and not string.find(effectName, "skill_")) and NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK then
        --return nil
    end
    if NgBattleDataManager.audioData[effectName] == nil then
        NgBattleDataManager.audioData[effectName] = NodeHelper:isFileExist("audio/" .. effectName)
    end
    if NgBattleDataManager.audioData[effectName] then
        if NgBattleDataManager.audioIds[chaNode.idx] and NgBattleDataManager.audioIds[chaNode.idx][effectName] then
            --SimpleAudioEngine:sharedEngine():stopEffect(NgBattleDataManager.audioIds[chaNode.idx][effectName])
            NgBattleDataManager.audioIds[chaNode.idx][effectName] = nil
        end
        local effectId = NodeHelper:playEffect(effectName, true)
        NgBattleDataManager.audioIds[chaNode.idx] = NgBattleDataManager.audioIds[chaNode.idx] or { }
        NgBattleDataManager.audioIds[chaNode.idx][effectName] = effectId
        return effectId
    else
        return nil
    end
end

function NgFightSceneHelper:setGameBgm()
    local bgmName = ""
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.BOSS then
        local mapId = NgBattleDataManager.battleMapId
        local chapter = mapCfg[mapId].Chapter
        bgmName = "Battle_" .. string.format("%02d", chapter) .. ".mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        bgmName = "Tutorial_Boss.mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.MULTI then
        bgmName = "Dungeon.mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.PVP then
        bgmName = "Arena.mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.WORLD_BOSS then
        bgmName = "WorldBoss_Bg.mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.DUNGEON then
        bgmName = "Dungeon.mp3"
    elseif NgBattleDataManager.battleType == CONST.SCENE_TYPE.CYCLE_TOWER then
        bgmName = "Dungeon.mp3"
    else
        bgmName = "Idle.mp3"
    end
    SoundManager:getInstance():playMusic(bgmName)
    CCLuaLog("setGameBgm : " .. bgmName)
end

function NgFightSceneHelper:isBossMapId(mapId)
     if mapCfg[mapId + 1] == nil then
        return true
     end
     if mapCfg[mapId] == nil then
        return false
     end
     local nowChapter = unpack(common:split(mapCfg[mapId].Chapter, "-"))
     local nextChapter = unpack(common:split(mapCfg[mapId + 1].Chapter, "-"))

     return (tonumber(nowChapter) ~= tonumber(nextChapter))
end

function NgFightSceneHelper:StroyDisplay(stage)
    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
    if tonumber(closeR18) == 1 then
        return false
    end
    local StoryCfg = ConfigManager.getStoryData()
    local mapCfg = ConfigManager.getNewMapCfg()
    local mapId = mapCfg[UserInfo.stateInfo.curBattleMap] and UserInfo.stateInfo.curBattleMap or 
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
       local stage=v.stage
       if not groupedTables[stage] then
             groupedTables[stage] = {}
       end
       table.insert(groupedTables[stage], v)
    end
    if groupedTables[stage] and mapId >= groupedTables[stage][1].stage then
        local AlbumStoryDisplayPage=require('AlbumStoryDisplayPage')
        AlbumStoryDisplayPage:setData(groupedTables[stage],false)
        --PageManager.pushPage("AlbumStoryDisplayPage")
        return true
    end
    return false
end

return NgFightSceneHelper
