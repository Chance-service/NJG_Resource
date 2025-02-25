-------------------------------------------------------------
-- 角色行為邏輯處理
-------------------------------------------------------------
local CONST = require("Battle.NewBattleConst")
local BuffManager = require("Battle.NewBuff.BuffManager")
require("Battle.NewBattleUtil")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
local LOG_UTIL = require("Battle.NgBattleLogUtil")
local SKILL_UTIL = require("Battle.NewSkill.SkillUtil")

local NgBattleCharacterBase = {}

function NgBattleCharacterBase.onSubFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        local str = container:getCurAnimationDoneName()
        container:setVisible(false)
        container.isDone = true
        container:unregisterFunctionHandler()
    end
end
-------------------------------------------------------------
-- Update
function NgBattleCharacterBase:updateTimer(dt, isMine, idx)
    local chaNode = isMine and NgBattleDataManager.battleMineCharacter[idx] or NgBattleDataManager.battleEnemyCharacter[idx]
    if chaNode.nowState ~= CONST.CHARACTER_STATE.DYING and chaNode.nowState ~= CONST.CHARACTER_STATE.DEATH then    --角色未死亡
        --更新普攻CD
        chaNode.atkCD = chaNode.atkCD + dt
        --更新BUFF狀態
        self:updateBuff(dt, chaNode)
        --更新SKILL CD
        self:updateSkillCD(dt, chaNode)
        if NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then
            --更新SKILL TIMER
            self:updateSkillTimer(dt, chaNode)
            --檢查被動技能發動
            self:checkPassiveTrigger(dt, chaNode)
        end
    end
end
-- 角色行為Update
function NgBattleCharacterBase:update(dt, isMine, idx)
    local chaNode = isMine and NgBattleDataManager.battleMineCharacter[idx] or NgBattleDataManager.battleEnemyCharacter[idx]
    if chaNode.nowState ~= CONST.CHARACTER_STATE.DYING and chaNode.nowState ~= CONST.CHARACTER_STATE.DEATH then    --角色未死亡
        -- 測試戰鬥
        if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
            if isMine and NgBattleDataManager.testFriendUpdate then
                self:castCdPassiveSkill(chaNode)
            elseif (not isMine) and NgBattleDataManager.testEnemyUpdate then
                self:castCdPassiveSkill(chaNode)
            end
        else
            self:castCdPassiveSkill(chaNode)
        end
        if chaNode.nowState == CONST.CHARACTER_STATE.INIT then    --初始化中 > 移動至定位
            self:onInit(dt, chaNode)
        elseif chaNode.nowState == CONST.CHARACTER_STATE.WAIT then    --待機狀態 > 尋找敵人
            if chaNode.target then  --有目標
                CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.MOVE)
                self:setMoveAction(chaNode)
            else
                self:searchTarget(chaNode)
            end
        elseif chaNode.nowState == CONST.CHARACTER_STATE.MOVE then    --移動狀態 > 往目標前進/檢查敵人狀態
            -- 測試戰鬥
            if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
                if isMine and (not NgBattleDataManager.testFriendUpdate) then
                    if not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WAIT, 1) and
                       not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) then
                        NgBattleCharacterUtil:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
                    end
                    return
                elseif (not isMine) and (not NgBattleDataManager.testEnemyUpdate) then
                    if not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WAIT, 1) and
                       not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) then
                        NgBattleCharacterUtil:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
                    end
                    return
                end
            end
            self:onMove(dt, chaNode)
        elseif chaNode.nowState == CONST.CHARACTER_STATE.ATTACK then    --攻擊狀態 > 對目標攻擊/檢查敵人狀態
            -- 測試戰鬥
            if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
                if isMine and (not NgBattleDataManager.testFriendUpdate) then
                    if not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WAIT, 1) and
                       not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) then
                        NgBattleCharacterUtil:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
                    end
                    return
                elseif (not isMine) and (not NgBattleDataManager.testEnemyUpdate) then
                    if not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WAIT, 1) and
                       not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) then
                        NgBattleCharacterUtil:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
                    end
                    return
                end
            end
            self:onAttack(chaNode)
        elseif chaNode.nowState == CONST.CHARACTER_STATE.HURT then    --受擊狀態
            self:onHurt(chaNode)
        elseif chaNode.nowState == CONST.CHARACTER_STATE.REBIRTH then --重生中
            chaNode.rebirthTimer = chaNode.rebirthTimer + dt
            if chaNode.rebirthTimer >= CONST.REBIRTH_TIME then
                chaNode.rebirthTimer = 0
                self:onReBirth(chaNode, idx)
            end
        end
    end
end
-- Buff Update
function NgBattleCharacterBase:updateBuff(dt, chaNode)
    local isInCrowdControlOld = BuffManager:isInCrowdControl(chaNode.buffData)
    local isClearFrenzy = false
    for k, v in pairs(chaNode.buffData) do
        local regDt = NgBattleDataManager.battleTime - chaNode.buffData[k][CONST.BUFF_DATA.UPDATE_TIME]
        chaNode.buffData[k][CONST.BUFF_DATA.UPDATE_TIME] = NgBattleDataManager.battleTime
        if k ~= CONST.BUFF.UNDEAD or 
           (k == CONST.BUFF.UNDEAD and v[CONST.BUFF_DATA.COUNT] == 0) then -- 不屈的time為觸發後的持續時間, count=0時開始計算剩餘時間
            v[CONST.BUFF_DATA.TIME] = v[CONST.BUFF_DATA.TIME] - regDt--dt
        end
        v[CONST.BUFF_DATA.TIMER] = v[CONST.BUFF_DATA.TIMER] + regDt--dt
        v[CONST.BUFF_DATA.TIMER2] = v[CONST.BUFF_DATA.TIMER2] + regDt--dt
        if v[CONST.BUFF_DATA.TIME] <= 0 then    --buff持續時間結束
            BuffManager:castEndBuffEffect(chaNode, k)   -- 持續時間結束才會發動的效果
            NewBattleUtil:removeBuff(chaNode, k, true)
            if k == CONST.BUFF.FRENZY then
                isClearFrenzy = true
            end
            local buffCfg = ConfigManager:getNewBuffCfg()
            if buffCfg[k].buffType == CONST.BUFF_TYPE.AURA then
                -- 清除光環產生的buff
                BuffManager:clearAuraBuff(k, NgBattleDataManager_getFriendList(chaNode), NgBattleDataManager_getEnemyList(chaNode))
            end
        end
        BuffManager:checkBuffTimer(chaNode, k)
    end
    local isInCrowdControlNew = BuffManager:isInCrowdControl(chaNode.buffData)
    if isInCrowdControlOld and not isInCrowdControlNew then --解除控場 --> 重設timeScale
        CHAR_UTIL:resetTimeScale(chaNode)
    end
    if isClearFrenzy then   --解除狂亂
        --強制切換目標
        BuffManager:setFrenzyTarget(chaNode, nil)
    end
    if not chaNode.buffData then
        chaNode.buffData = {}
    end
end
-- 技能CD Update
function NgBattleCharacterBase:updateSkillCD(dt, chaNode)
    for skillType, oneTypeSkill in pairs(chaNode.skillData) do
        for skillId, skillData in pairs(oneTypeSkill) do
            if skillData["CD"] > 0 then
                skillData["CD"] = math.max(skillData["CD"] - dt, 0)
            end
        end
    end
end
-- 技能計時器 Update
function NgBattleCharacterBase:updateSkillTimer(dt, chaNode)
    for skillType, oneTypeSkill in pairs(chaNode.skillData) do
        for skillId, skillData in pairs(oneTypeSkill) do
            if skillData["TIMER"] then
                skillData["TIMER"] = math.max(skillData["TIMER"] + dt, 0)
            end
        end
    end
end
-- HP, MP條件被動檢查
function NgBattleCharacterBase:checkPassiveTrigger(dt, chaNode)
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.HP]) do -- HP觸發
        local resultTable = { }
        local allPassiveTable = { }
        local actionResultTable = { }
        local allTargetTable = { }
        if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.HP) then
            LOG_UTIL:setPreLog(chaNode, resultTable)
            CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
        end
    end
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.MP]) do -- MP觸發
        local resultTable = { }
        local allPassiveTable = { }
        local actionResultTable = { }
        local allTargetTable = { }
        if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.MP) then
            LOG_UTIL:setPreLog(chaNode, resultTable)
            CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
        end
    end
end
-------------------------------------------------------------
-- 主動行為function
-------------------------------------------------------------
-- 角色初始設定 (CHARACTER_STATE.INIT)
function NgBattleCharacterBase:onInit(dt, chaNode)
    if chaNode.nowState == CONST.CHARACTER_STATE.INIT then
        -- 設定Animation
        if not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.RUN, 1) then
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.RUN, true)
        end
        --設定面相
        local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
        --翻轉特定BOSS
        if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 1 then
            if chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] < CHAR_UTIL:getPos(chaNode).x and sToNode:getScaleX() < 0 then
                CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
            elseif chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] > CHAR_UTIL:getPos(chaNode).x and sToNode:getScaleX() > 0 then
                CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
            end
        else
            if chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] < CHAR_UTIL:getPos(chaNode).x and sToNode:getScaleX() > 0 then
                CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
            elseif chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] > CHAR_UTIL:getPos(chaNode).x and sToNode:getScaleX() < 0 then
                CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
            end
        end
        --位移
        local dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x, CHAR_UTIL:getPos(chaNode).y), 
                    ccp(chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X], chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y]))

        if dis <= 10 and CHAR_UTIL:isInBattleField(chaNode) then    --到定點
            CHAR_UTIL:moveToTargetPos(chaNode, chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X], chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y])
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
            return
        end
        local buffValue, auraValue, markValue = BuffManager:checkMoveSpeedBuffValue(chaNode.buffData)   -- 移動速度buff
        local dx = 3--[[chaNode.battleData[CONST.BATTLE_DATA.RUN_SPD]] * ((chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] - CHAR_UTIL:getPos(chaNode).x) / dis) 
                   * buffValue * auraValue * markValue * NgBattleDataManager.battleSpeed--* math.min(dt * 0.06, 3)
        local dy = 3--[[chaNode.battleData[CONST.BATTLE_DATA.RUN_SPD]] * ((chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y] - CHAR_UTIL:getPos(chaNode).y) / dis) 
                   * buffValue * auraValue * markValue * NgBattleDataManager.battleSpeed--* math.min(dt * 0.06, 3)
        CHAR_UTIL:moveToTargetPos(chaNode, chaNode.heroNode.chaCCB:getPositionX() + dx, chaNode.heroNode.chaCCB:getPositionY() + dy)
        dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x, CHAR_UTIL:getPos(chaNode).y), 
              ccp(chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X], chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y]))
        if dis <= 10 then    --到定點
            CHAR_UTIL:moveToTargetPos(chaNode, chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X], chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y])
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        end
    end
end
-- 尋找目標 (CHARACTER_STATE.WAIT 沒有目標時)
function NgBattleCharacterBase:searchTarget(chaNode)
    if BuffManager:isInFrenzy(chaNode.buffData) then    -- 在狂亂狀態
        BuffManager:setFrenzyTarget(chaNode, BuffManager:createFrenzyTarget(chaNode))
    elseif BuffManager:isInTaunt(chaNode.buffData) then    -- 在嘲諷狀態
        BuffManager:setTauntTarget(chaNode, chaNode.tarArray[NewBattleConst.TARGET_TYPE.TAUNT_TARGET])
    else
        local friendList = NgBattleDataManager_getFriendList(chaNode)
        local enemyList = NgBattleDataManager_getEnemyList(chaNode)

        local minDis = nil
        local enemyIdx = nil
        for i = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
            local enemy = enemyList[i]
            if enemy and CHAR_UTIL:getState(enemy) ~= CONST.CHARACTER_STATE.DYING and CHAR_UTIL:getState(enemyList[i]) ~= CONST.CHARACTER_STATE.DEATH 
                and CHAR_UTIL:getState(enemy) ~= CONST.CHARACTER_STATE.REBIRTH and enemy ~= attacker then
                local inField = CHAR_UTIL:isInBattleField(enemy)
                if inField then
                    local disX = math.abs(CHAR_UTIL:getPos(chaNode).x - CHAR_UTIL:getPos(enemy).x) / 1.7
                    local disY = math.abs(CHAR_UTIL:getPos(chaNode).y - CHAR_UTIL:getPos(enemy).y)
                    local dis = disX + disY
                    --local dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x, CHAR_UTIL:getPos(chaNode).y), 
                    --                                       ccp(CHAR_UTIL:getPos(enemy).x, CHAR_UTIL:getPos(enemy).y))
                    --for j = 1, math.max(CONST.HERO_COUNT, CONST.ENEMY_COUNT) do
                    --    local friend = friendList[j]
                    --    if friend and friend.target == enemy and friend ~= chaNode then
                    --        dis = dis + 300
                    --    end
                    --end
                    --if enemy.target == chaNode then
                    --    dis = dis - 300
                    --end
                    if not BuffManager:isInStealth(enemy.buffData) then   -- 不在隱身狀態
                        if (not minDis or minDis > dis) and (chaNode ~= enemyList[enemyIdx]) then
                            minDis = dis
                            enemyIdx = i
                        end
                    end
                end
            end
        end
        if minDis and enemyIdx then
            chaNode.target = enemyList[enemyIdx]
        end
    end
end
-- 設定移動動畫 (CHARACTER_STATE.WAIT 有目標時)
function NgBattleCharacterBase:setMoveAction(chaNode)
    if CHAR_UTIL:isInAttackAni(chaNode) then
        return
    end
    if chaNode.target then
        local dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x, CHAR_UTIL:getPos(chaNode).y), 
                                               ccp(CHAR_UTIL:getPos(chaNode.target).x, CHAR_UTIL:getPos(chaNode.target).y))
        if dis > chaNode.battleData[CONST.BATTLE_DATA.RANGE] then
            if dis > chaNode.battleData[CONST.BATTLE_DATA.NEED_RUN] then
                CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.RUN, true)
                chaNode.battleData[CONST.BATTLE_DATA.MOVE_SPD] = chaNode.battleData[CONST.BATTLE_DATA.RUN_SPD]
            else
                CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WALK, true)
                chaNode.battleData[CONST.BATTLE_DATA.MOVE_SPD] = chaNode.battleData[CONST.BATTLE_DATA.RUN_SPD] --chaNode.battleData[CONST.BATTLE_DATA.WALK_SPD]
            end
        end
    else
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    end
end
-- 角色移動 (CHARACTER_STATE.MOVE)
function NgBattleCharacterBase:onMove(dt, chaNode)
    if chaNode.target and CHAR_UTIL:getState(chaNode.target) ~= CONST.CHARACTER_STATE.DYING and CHAR_UTIL:getState(chaNode.target) ~= CONST.CHARACTER_STATE.DEATH 
        and CHAR_UTIL:getState(chaNode.target) ~= CONST.CHARACTER_STATE.REBIRTH then
        if BuffManager:isInCrowdControl(chaNode.buffData) then   -- 在控場狀態
            return
        end
        if CHAR_UTIL:isInAttackAni(chaNode) then    -- 在攻擊動作
            return
        end
        if not CHAR_UTIL:isInMoveAni(chaNode) then    -- 不在移動動作
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.RUN, true)
        end
        --設定面相
        CHAR_UTIL:setChaDir(chaNode, chaNode.target)
        --位移
        local chaOffsetX = chaNode.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX
        local chaOffsetY = chaNode.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
        local tarOffsetX = chaNode.target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX
        local tarOffsetY = chaNode.target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
        local dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x + chaOffsetX, CHAR_UTIL:getPos(chaNode).y + chaOffsetY),    -- 兩隻角色距離
                                               ccp(CHAR_UTIL:getPos(chaNode.target).x - tarOffsetX, CHAR_UTIL:getPos(chaNode.target).y))
        if CHAR_UTIL:getPos(chaNode).x > CHAR_UTIL:getPos(chaNode.target).x then
            dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(chaNode).x - chaOffsetX, CHAR_UTIL:getPos(chaNode).y + chaOffsetY),    -- 兩隻角色距離
                                             ccp(CHAR_UTIL:getPos(chaNode.target).x + tarOffsetX, CHAR_UTIL:getPos(chaNode.target).y))
        end

        if CHAR_UTIL:isTargetInAttackRange(chaNode) and CHAR_UTIL:isInBattleField(chaNode) then    --攻擊距離內&自己在場內
            CHAR_UTIL:moveToTargetPos(chaNode, chaNode.heroNode.chaCCB:getPositionX(), chaNode.heroNode.chaCCB:getPositionY())
            self:startAttack(chaNode)
            return
        end
        local buffValue, auraValue, markValue = BuffManager:checkMoveSpeedBuffValue(chaNode.buffData)   -- 移動速度buff
        local dx = chaNode.battleData[CONST.BATTLE_DATA.MOVE_SPD] * (((CHAR_UTIL:getPos(chaNode.target).x - CHAR_UTIL:getPos(chaNode).x) --[[- (chaOffsetX + tarOffsetX)]]) / dis) * 
                   buffValue * auraValue * markValue --[[* dt * 0.06]] * NgBattleDataManager.battleSpeed
        local dy = chaNode.battleData[CONST.BATTLE_DATA.MOVE_SPD] * (((CHAR_UTIL:getPos(chaNode.target).y) - (CHAR_UTIL:getPos(chaNode).y)) / dis) * 
                   buffValue * auraValue * markValue --[[* dt * 0.06]] * NgBattleDataManager.battleSpeed
        
        CHAR_UTIL:moveToTargetPos(chaNode, chaNode.heroNode.chaCCB:getPositionX() + dx, chaNode.heroNode.chaCCB:getPositionY() + dy)
        if CHAR_UTIL:isTargetInAttackRange(chaNode) and CHAR_UTIL:isInBattleField(chaNode) then    --攻擊距離內&自己在場內
            self:startAttack(chaNode)
        else    -- 每次移動後重新鎖敵
            self:searchTarget(chaNode)
        end
    else    --沒有目標/目標已死亡
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        chaNode.target = nil
    end
end
-- 角色開始攻擊 (CHARACTER_STATE.MOVE 切換至 CHARACTER_STATE.ATTACK 時)
function NgBattleCharacterBase:startAttack(chaNode)
    --local canAttack = (chaNode.atkCD >= NewBattleUtil:calAttackCD(chaNode, chaNode.target))--self.battleData[CONST.BATTLE_DATA.COLD_DOWN])
    --local tarState = CHAR_UTIL:getState(chaNode.target)
    --if canAttack or tarState ~= CONST.CHARACTER_STATE.MOVE then
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.ATTACK)
    --end
end
-- 角色攻擊 (CHARACTER_STATE.ATTACK)
function NgBattleCharacterBase:onAttack(chaNode)
    if chaNode.target and BuffManager:isInStealth(chaNode.target.buffData) then   -- 目標在隱身狀態
        chaNode.target = nil
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        return
    end
    if CHAR_UTIL:isTargetCanAttackState(chaNode) then
        local isAuto = NgBattleDataManager.battleIsAuto or NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK
        -- 施放大招檢查
        if CHAR_UTIL:isCanSkill(chaNode, true) and
           (chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] or isAuto) and    -- 怪物 or Auto開啟時自動施放技能
           (not (NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE)) then    -- 新手教學時不自動施放技能
            self:useSkill(chaNode)
            return
        end
        -- 施放小招檢查
        if CHAR_UTIL:isCanLittleSkill(chaNode, CONST.SKILL1_TRIGGER_TYPE.NORMAL) then
            local skillId = CHAR_UTIL:getTriggerLittleSkill(chaNode, CONST.SKILL1_TRIGGER_TYPE.NORMAL)  -- 檢查觸發的小招
            if skillId then
                self:useLittleSkill(chaNode, skillId)
                return
            end
        end
        -- 普攻檢查
        if CHAR_UTIL:isCanNormalAttack(chaNode) then
            chaNode.atkCD = 0  
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.ATTACK, false)
            -- 攻擊音效(TEST)
            local sceneHelper = require("Battle.NgFightSceneHelper")
            if math.random(1, 10) == 1 then
                sceneHelper:playSoundEffect(chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] .. "_" .. string.format("%02d", math.random(1, 3)) .. ".mp3", chaNode)
            end          
            LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.CAST_ATTACK, chaNode, nil, nil, false, false, 0)
            return
        end
        if not CHAR_UTIL:isInAttackAni(chaNode) and 
               not chaNode.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) then   -- 不可以普攻/放大招, 不在攻擊/受擊動作中
            if not CHAR_UTIL:isTargetInAttackRange(chaNode) then   -- 攻擊距離外 -> 切換移動狀態
                CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WALK, true)
                CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.MOVE)
            elseif not CHAR_UTIL:isAttackCdEnd(chaNode) then     -- 等待攻擊CD中 -> 切換等待狀態
                CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
            end
            return
        end
    else    -- 沒有目標 or 目標不可攻擊 -> 重新尋找目標
        if not CHAR_UTIL:isInAttackAni(chaNode) and                 -- 不在攻擊動作中
           not BuffManager:isInCrowdControl(chaNode.buffData) then  -- 不在控場狀態
            chaNode.target = nil
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        end
        return
    end
end
-- 角色受擊 (CHARACTER_STATE.HURT)
function NgBattleCharacterBase:onHurt()
end
-- 重生 (CHARACTER_STATE.REBIRTH) * 目前只有判斷掛機怪物
function NgBattleCharacterBase:onReBirth(chaNode, idx)
    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    chaNode.hurtEffect = {}
    chaNode.allSpineTable = {}
    sToNode:removeFromParentAndCleanup(true)
    CHAR_UTIL:resetMonsterInfo(chaNode)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    --local avgX = 260
    --local totalX = 0
    --for i = 1, #friendList do 
    --    totalX = totalX + CHAR_UTIL:getPos(friendList[i]).x
    --end
    --avgX = totalX / #friendList
    local dir = (idx > 2) and 1 or -1
    chaNode.heroNode.chaCCB:setPosition(ccp(260 + 460 * dir, chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y]))
    self:searchTarget(chaNode)
    local tar = chaNode.target
    if not tar then
        local enemyList = NgBattleDataManager_getEnemyList(chaNode)
        local aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
        tar = enemyList[aliveIdTable[1]]
    end
    if CHAR_UTIL:getPos(tar).x < 260 then
        dir = -1
        chaNode.heroNode.chaCCB:setPosition(ccp(720, CHAR_UTIL:getPos(chaNode).y))
    else
        dir = 1
        chaNode.heroNode.chaCCB:setPosition(ccp(-200, CHAR_UTIL:getPos(chaNode).y))
    end
    if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 1 then
           dir = dir * -1
    end
    chaNode.floorNode:setPosition(chaNode.heroNode.chaCCB:getPosition())    --地板特效點位
    chaNode.heroNode.heroSpine = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME])
    -- 角色skin(怪物用)
    if chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN] and chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] then
        chaNode.heroNode.heroSpine:setSkin("skin" .. string.format("%02d", chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN]))
    end
    CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
    sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    local spineNode = chaNode.heroNode.chaCCB:getVarNode("mMainSpine")
    sToNode:setScaleX(dir)
    spineNode:removeAllChildren()
    spineNode:addChild(sToNode)
    if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX] .. ".skel") then
        chaNode.heroNode.heroBackFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_BACK_FX])
        table.insert(chaNode.allSpineTable, 1002, chaNode.heroNode.heroBackFx)
    else
        chaNode.heroNode.heroBackFx = nil
    end
    if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX] .. ".skel") then
        chaNode.heroNode.heroFrontFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FRONT_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FRONT_FX])
        table.insert(chaNode.allSpineTable, 1003, chaNode.heroNode.heroFrontFx)
    else
        chaNode.heroNode.heroFrontFx = nil
    end
    if NodeHelper:isFileExist(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX] .. "/" .. chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX] .. ".skel") then
        chaNode.heroNode.heroFloorFx = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_FLOOR_FX], chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME_FLOOR_FX])
        table.insert(chaNode.allSpineTable, 1004, chaNode.heroNode.heroFloorFx)
    else
        chaNode.heroNode.heroFloorFx = nil
    end
    if chaNode.heroNode.heroBackFx then
        local sToNodeBack = tolua.cast(chaNode.heroNode.heroBackFx, "CCNode")
        local spineNodeBack = chaNode.heroNode.chaCCB:getVarNode("mBackFX")
        spineNodeBack:removeAllChildren()
        sToNodeBack:setScaleX(sToNode:getScaleX()) 
        spineNodeBack:addChild(sToNodeBack)
    end
    if chaNode.heroNode.heroFrontFx then
        local sToNodeFront = tolua.cast(chaNode.heroNode.heroFrontFx, "CCNode")
        local spineNodeFront = chaNode.heroNode.chaCCB:getVarNode("mFrontFX")
        spineNodeFront:removeAllChildren()
        sToNodeFront:setScaleX(sToNode:getScaleX()) 
        spineNodeFront:addChild(sToNodeFront)
    end
    if chaNode.heroNode.heroFloorFx then
        local sToNodeFloor = tolua.cast(chaNode.heroNode.heroFloorFx, "CCNode")
        chaNode.floorNode:addChild(sToNodeFloor)
    end

    self:setMoveAction(chaNode)
    --self.nowState = CONST.CHARACTER_STATE.MOVE
    sToNode:setTag(chaNode.heroNode.id)
    chaNode.heroNode.heroSpine:registerFunctionHandler("SELF_EVENT", self.onFunction)
    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    CHAR_UTIL:resetTimeScale(chaNode)
end
-- 施放技能
function NgBattleCharacterBase:useSkill(chaNode)
    if NgBattleDataManager.castSkillNode then
        return
    end
    NgBattlePageInfo_useCardSkill(chaNode.idx)
end
-- 施放小招
function NgBattleCharacterBase:useLittleSkill(chaNode, skillId)
    CHAR_UTIL:setSpineAnimation(chaNode, ConfigManager.getSkillCfg()[skillId].actionName, false) 
    --return SkillManager:castSkill(chaNode, CONST.SKILL_DATA.AUTO_SKILL, skillId)
end
-- 施放特殊被動(根據特殊條件觸發的技能, attacker跟target可能都不是自己)
function NgBattleCharacterBase:castSpecialBattlePassive(chaNode, fList, eList, skillId)
    if chaNode.nowState == CONST.CHARACTER_STATE.DYING and chaNode.nowState == CONST.CHARACTER_STATE.DEATH 
        and chaNode.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    local skillType = NewBattleUtil:checkSkill(skillId, chaNode.skillData)
    if skillType ~= 0 then

    end
end
-------------------------------------------------------------
-- 註冊的Callback function
-------------------------------------------------------------
-- 被攻擊
function NgBattleCharacterBase:beAttack(chaNode, target, dmg, isCri, isSkipCalHp, weakType, skillId, resultTable, allPassiveTable)
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then
        return
    end
    if target.nowState == CONST.CHARACTER_STATE.DYING and target.nowState == CONST.CHARACTER_STATE.DEATH 
        and target.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    if BuffManager:isInInvincible(target.buffData) or BuffManager:isInBerserker(target.buffData) then
        -- 無敵時也會獲得mp
        local mp = NewBattleUtil:calBeAtkGainMp(chaNode, target)
        CHAR_UTIL:setMp(target, math.min(target.battleData[CONST.BATTLE_DATA.MP] + mp, target.battleData[CONST.BATTLE_DATA.MAX_MP]))
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.BEATTACK_ADD_MP, target, nil, nil, false, false, mp)
        return
    end
    local sceneHelper = require("Battle.NgFightSceneHelper")
    local newDmg = 0
    local hpDmg = 0
    local shieldDmg = 0
    if chaNode.idx ~= target.idx then
        if target.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.HURT, 1) or target.heroNode.heroSpine:isPlayingAnimation(CONST.ANI_ACT.WAIT, 1) then
            target.heroNode.heroSpine:runAnimation(1, CONST.ANI_ACT.HURT, 0)
            --SHAKE
            if skillId then
                sceneHelper:playSceneShake()
            end
        end
        -- 受擊音效(TEST)
        if dmg > 0 and NgBattleDataManager_getTestOpenSound() then
            if not target.HURT_EFF_ID or not SimpleAudioEngine:sharedEngine():getEffectIsPlaying(target.HURT_EFF_ID) then
                target.HURT_EFF_ID = sceneHelper:playSoundEffect(target.otherData[CONST.OTHER_DATA.ITEM_ID] .. "_" .. string.format("%02d", math.random(11, 13)) .. ".mp3", chaNode)
            end
        end
        -- 受擊特效(TEST)
        local cfg = target.otherData[CONST.OTHER_DATA.CFG]
        local skillCfg = nil
        if dmg > 0 and NgBattleDataManager_getTestOpenHit() then
            local fileNames = ""
            if skillId then --技能
                skillCfg = ConfigManager.getSkillCfg()
                if skillCfg[skillId] then
                    if skillCfg[skillId].HitEffectPath ~= "" then
                        fileNames = common:split(skillCfg[skillId].HitEffectPath, ",")
                    end
                end
            else    --普攻
                local isHero = (chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.LEADER or 
                                chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO or 
                                chaNode.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.SPRITE)
                if isHero then   --Hero
                    local heroCfg = ConfigManager.getNewHeroCfg()
                    local effectCfg = ConfigManager.getHeroEffectPathCfg()
                    local idx = tonumber(chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] .. string.format("%03d", chaNode.otherData[CONST.OTHER_DATA.SPINE_SKIN]))
                    if effectCfg[idx] then
                        if effectCfg[idx].AttackHit then
                            fileNames = common:split(effectCfg[idx].AttackHit, ",")
                        end
                    end
                else    --Monster
                    local monsterCfg = chaNode.otherData[CONST.OTHER_DATA.CFG]--ConfigManager.getNewMonsterCfg()
                    if monsterCfg then
                        if monsterCfg.HitEffectPath then
                            fileNames = common:split(monsterCfg.HitEffectPath, ",")
                        end
                    end
                end
            end

            for i = 1, #fileNames do 
                local fileName = fileNames[i]
                local randName = "animation"
                local isFlip = CHAR_UTIL:calIsFlipHitEffect(chaNode, target)
                local effectKey = fileName.. "_" .. randName .. "_" .. (isFlip and "1" or "0")
                if target.hurtEffect[effectKey] then
                    if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                        local sceneSpeed = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and CONST.AFK_BATTLE_SPEED or NgBattleDataManager.battleSpeed
                        target.hurtEffect[effectKey]:setTimeScale(sceneSpeed)
                        target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                    end
                else
                    target.hurtEffect[effectKey] = SpineContainer:create("Spine/hit", fileName)
                    local effectNode = tolua.cast(target.hurtEffect[effectKey], "CCNode")
                    local hitNode = target.heroNode.chaCCB:getVarNode("mHitFrontNode")
                    if string.find(fileName, "FX2") then
                        hitNode = target.heroNode.chaCCB:getVarNode("mHitBackNode")
                    elseif string.find(fileName, "FX3") then
                        hitNode = target.floorNode
                    end
                    hitNode:addChild(effectNode)
                    local sToNode = tolua.cast(target.heroNode.heroSpine, "CCNode")
                    if skillCfg and skillCfg[skillId] and skillCfg[skillId].effectType == 1 then
                        effectNode:setPositionY(0)
                    else
                        effectNode:setPositionY(cfg and cfg.CenterOffsetY or 0)
                    end
                    effectNode:setScale(sToNode:getScaleY())
                    effectNode:setScaleX(isFlip and -1 or 1)
                    if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                        target.hurtEffect[effectKey]:setTimeScale(NgBattleDataManager.battleSpeed)
                        target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                    end
                end
            end
            
        end
        -- 被動技能發動檢查
        if dmg > 0 then
            if skillId then
                if isCri then
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_SKILL_HIT]) do -- 被技能暴擊命中
                        NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_SKILL_HIT, { chaNode })
                    end
                end
                for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_SKILL_HIT]) do -- 被技能命中
                    NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_SKILL_HIT, { chaNode })
                end
            else
                if isCri then
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_ATK_HIT]) do -- 被普攻暴擊命中
                        NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_ATK_HIT, { chaNode })
                    end
                end
                for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_ATK_HIT]) do -- 被普攻命中
                    NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_ATK_HIT, { chaNode })
                end
            end
            if isCri then
                for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_HIT]) do -- 被普攻/技能暴擊命中
                    NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_CRI_HIT, { chaNode })
                end
            end
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.BE_HIT]) do -- 被普攻/技能命中
                NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.BE_HIT, { chaNode })
            end
        end
        -- 受擊震動(TEST)
        --target.heroNode.chaCCB:runAnimation("Hurt")
        shieldDmg = math.min(dmg, target.battleData[CONST.BATTLE_DATA.SHIELD])
        hpDmg = math.max(dmg - shieldDmg, 0)
        newDmg = shieldDmg + hpDmg
        if newDmg > 0 then
            -- 毅力buff檢查
            local limitPer, buffId = BuffManager:isInUnDead(target.buffData)
            if limitPer > 0 then
                local newPer = (target.battleData[CONST.BATTLE_DATA.HP] - hpDmg) / target.battleData[CONST.BATTLE_DATA.MAX_HP]
                if limitPer > newPer then   -- 觸發鎖血
                    allPassiveTable[target.idx] = allPassiveTable[target.idx] or {}
                    table.insert(allPassiveTable[target.idx], CONST.PassiveLogType.BUFF .. "_" .. CONST.BUFF.UNDEAD)
                    BuffManager:castInUnDead(target, target.buffData, buffId)
                    local limitHp = math.ceil(target.battleData[CONST.BATTLE_DATA.MAX_HP] * limitPer)  -- 無條件進位
                    hpDmg = math.max(target.battleData[CONST.BATTLE_DATA.HP] - limitHp, 0)
                    newDmg = shieldDmg + hpDmg
                end
            end
        else
            -- 施放小招檢查
            if CHAR_UTIL:isCanLittleSkill(target, CONST.SKILL1_TRIGGER_TYPE.DODGE) then
                local skillId = CHAR_UTIL:getTriggerLittleSkill(target, CONST.SKILL1_TRIGGER_TYPE.DODGE)  -- 檢查觸發的小招
                if skillId then
                    self:useLittleSkill(target, skillId)
                    SkillManager:setSkillTarget(skillId, target, { chaNode })
                    return
                end
            end
        end
    else
        shieldDmg = math.min(dmg, target.battleData[CONST.BATTLE_DATA.SHIELD])
        hpDmg = math.max(dmg - shieldDmg, 0)
        newDmg = shieldDmg + hpDmg
    end
    -- 單人強敵分數
    if hpDmg > 0 and (not CHAR_UTIL:isMineCharacter(target)) and
       (NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM) then
        NewBattleUtil:addSingleBossScore(math.max(math.min(target.battleData[CONST.BATTLE_DATA.HP], hpDmg), 0))
    end
    -- 受擊數字
    self:showBattleNum(chaNode, target, newDmg, isCri, weakType, CONST.HURT_TYPE.BEATTACK)

    local isSkipCal = CHAR_UTIL:isMineCharacter(target) and (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)  -- 掛機時不計算敵方傷害數字
    local isSkipCal2 = not CHAR_UTIL:isMineCharacter(target) and -- 單人強敵無限難度不計算傷害數字
                       ((NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS) or (NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM)) and
                       (NgBattleDataManager.SingleBossId == 999)
    isSkipCal = isSkipCal or isSkipCal2
    if not isSkipCal then
        CHAR_UTIL:setHp(target, math.min(target.battleData[CONST.BATTLE_DATA.HP] - hpDmg, target.battleData[CONST.BATTLE_DATA.MAX_HP]))
        CHAR_UTIL:setShield(target, math.min(target.battleData[CONST.BATTLE_DATA.SHIELD] - shieldDmg))
    end

    SKILL_UTIL:triggerSkillSpecialEffect(chaNode, target, skillId)

    if target.battleData[CONST.BATTLE_DATA.HP] <= 0 then --死亡
        CHAR_UTIL:setMp(target, math.min(target.battleData[CONST.BATTLE_DATA.MP], target.battleData[CONST.BATTLE_DATA.MAX_MP])) 
        local triggerBuffList = BuffManager:specialBuffEffect(target.buffData, CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE, chaNode, target, skillId, dmg)   --受擊時觸發buff效果
        local list = NgBattleDataManager_getEnemyList(target)
        local aliveIdTable = NewBattleUtil:initAliveTable(list)
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ENEMY_DEAD]) do -- 敵方死亡觸發被動(不限擊殺的角色)
            for i = 1, #aliveIdTable do
                NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.ENEMY_DEAD, { target })
            end
        end
        local flist = NgBattleDataManager_getFriendList(target)
        aliveIdTable = NewBattleUtil:initAliveTable(flist)
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD]) do -- 友方死亡觸發被動(不限擊殺的角色)
            for i = 1, #aliveIdTable do
                NewBattleUtil:castPassiveSkill(flist[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD, { target })
            end
        end
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.KILL_ENEMY]) do -- 自身擊殺敵方觸發被動
            NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.KILL_ENEMY, { target })
        end
        -- TODO 清空BUFF&DEBUFF?
        if not BuffManager:checkRebirth(target) then    -- 檢查&觸發復生buff
            self:onDead(target)
        end
    else    --獲得MP
        if chaNode.idx ~= target.idx then
            local mp = NewBattleUtil:calBeAtkGainMp(chaNode, target)
            CHAR_UTIL:setMp(target, math.min(target.battleData[CONST.BATTLE_DATA.MP] + mp, target.battleData[CONST.BATTLE_DATA.MAX_MP]))
            if dmg > 0 then
                CHAR_UTIL:clearSkillTimer(target.skillData, CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE)    --受擊時清空特定skill計時
                BuffManager:clearBuffTimer(target, target.buffData, CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE)    --受擊時清空特定buff計時
                BuffManager:addBuffCount(target, target.buffData, CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE)   --受擊時增加buff層數
                local triggerBuffList = BuffManager:specialBuffEffect(target.buffData, CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE, chaNode, target, skillId, dmg)   --受擊時觸發buff效果
            else
                CHAR_UTIL:clearSkillTimer(target.skillData, CONST.ADD_BUFF_COUNT_EVENT.DODGE)    --閃避時清空特定skill計時
                BuffManager:clearBuffTimer(target, target.buffData, CONST.ADD_BUFF_COUNT_EVENT.DODGE)    --閃避時清空特定buff計時
                BuffManager:addBuffCount(target, target.buffData, CONST.ADD_BUFF_COUNT_EVENT.DODGE)   --閃避時增加buff層數
                BuffManager:minusBuffCount(target, CONST.ADD_BUFF_COUNT_EVENT.DODGE)   --閃避時減少buff層數
                local triggerBuffList = BuffManager:specialBuffEffect(target.buffData, CONST.ADD_BUFF_COUNT_EVENT.DODGE, chaNode, target, skillId, dmg)   --閃避時觸發buff效果
            end
            LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.BEATTACK_ADD_MP, target, nil, nil, false, false, mp)
        end
    end
    if chaNode.idx ~= target.idx then
        local sceneHelper = require("Battle.NgFightSceneHelper")
        sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.DAMAGE, chaNode.idx, newDmg, skillId, isCri, dmg)
        sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.BEDAMAGE, target.idx, newDmg, skillId, isCri, dmg)
    end
    return newDmg
end
-- 角色死亡
function NgBattleCharacterBase:onDead(chaNode)
    -- 清空非同步任務
    local ALFManager = require("Util.AsyncLoadFileManager")
    if NgBattleDataManager.asyncLoadTasks[chaNode.idx] then
        for k, v in pairs(NgBattleDataManager.asyncLoadTasks[chaNode.idx]) do 
            ALFManager:cancel(v)
        end
        NgBattleDataManager.asyncLoadTasks[chaNode.idx] = nil
    end
    CHAR_UTIL:setMp(chaNode, 0)
    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.DYING)
    chaNode.heroNode.heroSpine:setToSetupPose()
    chaNode.heroNode.heroSpine:unregisterFunctionHandler("SELF_EVENT")
    chaNode.heroNode.chaCCB:stopAllActions()
    if chaNode.heroNode.chaCCB == NgBattleDataManager.castSkillNode then
        self:onFunction(chaNode, chaNode.target, "mask_close", isSkipCal)
    end
    local array = CCArray:create()
    array:addObject(CCCallFunc:create(function()
        BuffManager:transferBuff(chaNode, NgBattleDataManager_getFriendList(chaNode), NgBattleDataManager_getEnemyList(chaNode))
        self:forceClearAllBuff(chaNode, NgBattleDataManager_getFriendList(chaNode), NgBattleDataManager_getEnemyList(chaNode))
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.DEATH, false)
    end))
    array:addObject(CCFadeOut:create(1.2 / NgBattleDataManager.battleSpeed))
    array:addObject(CCCallFunc:create(function()
        NodeHelper:setNodeVisible(chaNode.heroNode.chaCCB:getVarNode("mHpmpbar"), false)
        self:clearData(chaNode)
    end))
    if NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] then
        array:addObject(CCCallFunc:create(function()
            chaNode.heroNode.chaCCB:setZOrder(CONST.Z_ORDER_MASK)
        end))
        array:addObject(CCCallFunc:create(function()
            CHAR_UTIL:playAwardAction(chaNode)
        end))
        array:addObject(CCDelayTime:create(3 / NgBattleDataManager.battleSpeed))
        array:addObject(CCCallFunc:create(function()
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.REBIRTH)
        end))
    else
        array:addObject(CCCallFunc:create(function()
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.DEATH)
            -- 檢查戰鬥結果
            local sceneHelper = require("Battle.NgFightSceneHelper")
            sceneHelper:checkBattleResult()
        end))
    end
    chaNode.heroNode.chaCCB:runAction(CCSequence:create(array))

    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.DEAD, chaNode, nil, nil, false, false, 0)
end
-- 角色攻擊命中
function NgBattleCharacterBase:onHit(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
    if chaNode and target then
        local isGainMp = (not skillId) or (ConfigManager.getSkillCfg()[skillId] and ConfigManager.getSkillCfg()[skillId].skillType ~= 1)
        local mp = isGainMp and NewBattleUtil:calAtkGainMp(chaNode, target, skillId) or 0
        -- 被動技能發動檢查
        if skillId then
            if isCri then
                for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.CRI_SKILL_HIT]) do -- 技能暴擊命中
                    NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.CRI_SKILL_HIT, { target })
                end
            end
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.SKILL_HIT]) do -- 技能命中
                NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.SKILL_HIT, { target })
            end
            CHAR_UTIL:clearSkillTimer(chaNode.skillData, CONST.ADD_BUFF_COUNT_EVENT.SKILL)      -- 清空特定skill計時
            BuffManager:clearBuffTimer(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.SKILL)      -- 清空特定buff計時
            BuffManager:addBuffCount(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.SKILL)        -- 增加buff層數
        else
            if isCri then
                for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.CRI_ATK_HIT]) do -- 普攻暴擊命中
                    NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.CRI_ATK_HIT, { target })
                end
            end
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ATK_HIT]) do -- 普攻命中
                NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.ATK_HIT, { target })
            end
            CHAR_UTIL:clearSkillTimer(chaNode.skillData, CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK)      -- 清空特定skill計時
            BuffManager:clearBuffTimer(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK)      -- 清空特定buff計時
            BuffManager:addBuffCount(chaNode, chaNode.buffData, CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK)        -- 增加buff層數
        end
        if isCri then
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.CRI_HIT]) do -- 普攻/技能暴擊命中
                NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.CRI_HIT, { target })
            end
            local list = NgBattleDataManager_getFriendList(chaNode)
            local aliveIdTable = NewBattleUtil:initAliveTable(list)
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_CRI_HIT]) do -- 友方普攻/傷害技能暴擊時觸發
                for i = 1, #aliveIdTable do
                    NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_CRI_HIT, { list[aliveIdTable[i]] })
                end
            end
        end
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.HIT]) do -- 普攻/技能命中
            NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.HIT, { target })
        end
        -- buff檢查
        local buffMp = BuffManager:checkMpGainValue(buff, nil, not skillId and CONST.ANI_ACT.ATTACK)
        if buffMp > 0 then
            mp = mp + buffMp
        end
        local buffRatio = BuffManager:checkMpGainRatio(buff, nil, not skillId and CONST.ANI_ACT.ATTACK)
        mp = math.max(math.floor(mp * buffRatio + 0.5), 1)
        CHAR_UTIL:setMp(chaNode, math.min(chaNode.battleData[CONST.BATTLE_DATA.MP] + mp, chaNode.battleData[CONST.BATTLE_DATA.MAX_MP]))

        if isGainMp then
            if skillId then
                LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_ADD_MP, chaNode, nil, skillId, false, false, mp)
            else
                LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.ATTACK_ADD_MP, chaNode, nil, nil, false, false, mp)
            end
        end
    end
end
-- 角色攻擊未命中
function NgBattleCharacterBase:onMiss(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
    if chaNode and target then
        local isGainMp = (not skillId) or (ConfigManager.getSkillCfg()[skillId] and ConfigManager.getSkillCfg()[skillId].skillType ~= 1)
        local mp = isGainMp and NewBattleUtil:calAtkGainMp(chaNode, target, skillId) or 0
        -- buff檢查
        local buffMp = BuffManager:checkMpGainValue(buff, nil, not skillId and CONST.ANI_ACT.ATTACK)
        if buffMp > 0 then
            mp = mp + buffMp
        end
        local buffRatio = BuffManager:checkMpGainRatio(buff, nil, not skillId and CONST.ANI_ACT.ATTACK)
        mp = math.max(math.floor(mp * buffRatio + 0.5), 1)
        CHAR_UTIL:setMp(chaNode, math.min(chaNode.battleData[CONST.BATTLE_DATA.MP] + mp, chaNode.battleData[CONST.BATTLE_DATA.MAX_MP]))

        if isGainMp then
            if skillId then
                LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_ADD_MP, chaNode, nil, skillId, false, false, mp)
            else
                LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.ATTACK_ADD_MP, chaNode, nil, nil, false, false, mp)
            end
        end
    end
end
-- 跳DOT傷害
function NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then
        return
    end
    if target.nowState == CONST.CHARACTER_STATE.DYING and target.nowState == CONST.CHARACTER_STATE.DEATH 
        and target.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    local mainBuffId = math.floor(buffId / 100) % 1000
    if (mainBuffId ~= CONST.BUFF.BERSERKER) and (BuffManager:isInInvincible(target.buffData) or BuffManager:isInBerserker(target.buffData)) then
        return
    end
    local mainBuffId = math.floor(buffId / 100) % 1000
    if not isSkipPre then
        if mainBuffId == CONST.BUFF.THORNS then  -- 荊棘
            LOG_UTIL:setPreLog(chaNode)
        else
            LOG_UTIL:setPreLog(target.buffData[buffId][CONST.BUFF_DATA.CASTER])
        end
        LOG_UTIL:setPreLog(target)
    end
    local shieldDmg = math.min(dmg, target.battleData[CONST.BATTLE_DATA.SHIELD])
    local hpDmg = math.max(dmg - shieldDmg, 0)
    local newDmg = shieldDmg + hpDmg
    if newDmg >= 0 then
        -- 毅力buff檢查
        local limitPer, buffId = BuffManager:isInUnDead(target.buffData)
        if limitPer > 0 then
            local newPer = (target.battleData[CONST.BATTLE_DATA.HP] - hpDmg) / target.battleData[CONST.BATTLE_DATA.MAX_HP]
            if limitPer > newPer then   -- 觸發鎖血
                allPassiveTable = allPassiveTable or { }
                allPassiveTable[target.idx] = allPassiveTable[target.idx] or { }
                table.insert(allPassiveTable[target.idx], CONST.PassiveLogType.BUFF .. "_" .. CONST.BUFF.UNDEAD)
                BuffManager:castInUnDead(target, target.buffData, buffId)
                local limitHp = math.ceil(target.battleData[CONST.BATTLE_DATA.MAX_HP] * limitPer)  -- 無條件進位
                hpDmg = math.max(target.battleData[CONST.BATTLE_DATA.HP] - limitHp, 0)
                newDmg = shieldDmg + hpDmg
            end
        end
    end
    -- 單人強敵分數
    if hpDmg > 0 and (not CHAR_UTIL:isMineCharacter(target)) and
       (NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS or
       NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM) then
        NewBattleUtil:addSingleBossScore(math.max(math.min(target.battleData[CONST.BATTLE_DATA.HP], hpDmg), 0))
    end
    -- 受擊數字
    if math.floor(buffId / 100) % 1000 == CONST.BUFF.CONDUCTOR then -- 導電體傷害使用一般攻擊數字
        self:showBattleNum(chaNode, target, newDmg, false, 0, CONST.HURT_TYPE.BEATTACK)
    else
        self:showBattleNum(nil, target, newDmg, false, 0, CONST.HURT_TYPE.DOT)
    end

    local isSkipCal = CHAR_UTIL:isMineCharacter(target) and (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)  -- 掛機時不計算敵方傷害數字
    local isSkipCal2 = not CHAR_UTIL:isMineCharacter(target) and -- 單人強敵無限難度不計算傷害數字
                       ((NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS) or (NgBattleDataManager.battleType == CONST.SCENE_TYPE.SINGLE_BOSS_SIM)) and
                       (NgBattleDataManager.SingleBossId == 999)
    isSkipCal = isSkipCal or isSkipCal2
    if not isSkipCal then
        CHAR_UTIL:setHp(target, math.min(target.battleData[CONST.BATTLE_DATA.HP] - hpDmg, target.battleData[CONST.BATTLE_DATA.MAX_HP]))
        CHAR_UTIL:setShield(target, math.min(target.battleData[CONST.BATTLE_DATA.SHIELD] - shieldDmg))
    end
    if target.battleData[CONST.BATTLE_DATA.HP] <= 0 then --死亡
        CHAR_UTIL:setMp(target, math.min(target.battleData[CONST.BATTLE_DATA.MP], target.battleData[CONST.BATTLE_DATA.MAX_MP]))
        local list = NgBattleDataManager_getEnemyList(target)
        local aliveIdTable = NewBattleUtil:initAliveTable(list)
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ENEMY_DEAD]) do -- 敵方死亡觸發被動
            for i = 1, #aliveIdTable do
                local resultTable, allPassiveTable, actionResultTable, allTargetTable = { }, { }, { }, { }
                if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.ENEMY_DEAD, { target }) then
                    LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                    CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                end
            end
        end
        local flist = NgBattleDataManager_getFriendList(target)
        aliveIdTable = NewBattleUtil:initAliveTable(flist)
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD]) do -- 友方死亡觸發被動
            for i = 1, #aliveIdTable do
                local resultTable, allPassiveTable, actionResultTable, allTargetTable = { }, { }, { }, { }
                if NewBattleUtil:castPassiveSkill(flist[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD, { target }) then
                    LOG_UTIL:setPreLog(flist[aliveIdTable[i]], resultTable)
                    CHAR_UTIL:calculateAllTable(flist[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                end
            end
        end
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.KILL_ENEMY]) do -- 自身擊殺敵方觸發被動
            local resultTable, allPassiveTable, actionResultTable, allTargetTable = { }, { }, { }, { }
            if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.KILL_ENEMY, { target }) then
                LOG_UTIL:setPreLog(target, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
        -- TODO 清空BUFF&DEBUFF?
        if not BuffManager:checkRebirth(target) then    -- 檢查&觸發復生buff
            self:onDead(target)
        end
    end
    local sceneHelper = require("Battle.NgFightSceneHelper")
    if not isSkipAdd then
        if buffId == CONST.BUFF.LEECH_SEED then
             target.buffData[buffId] = nil
        end
    end
    if buffId then
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.BUFF_ATTACK, chaNode, target, buffId, false, false, newDmg)
    end

    if mainBuffId == CONST.BUFF.THORNS then  -- 荊棘
        sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.DAMAGE, chaNode.idx, newDmg, buffId, false, dmg)
    else
        sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.DAMAGE, target.buffData[buffId][CONST.BUFF_DATA.CASTER].idx, newDmg, buffId, false, dmg)
    end
    sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.BEDAMAGE, target.idx, newDmg, buffId, false, dmg)

    return newDmg
end
-- 跳HOT治療
function NgBattleCharacterBase:beHot(target, dmg, buffId, isSkipPre, isSkipAdd)
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then
        return
    end
    if target.nowState == CONST.CHARACTER_STATE.DYING and target.nowState == CONST.CHARACTER_STATE.DEATH 
        and target.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    -- 受擊特效(TEST)
    local fileNames = {  }
    
    if buffId then -- BUFF
        local buffCfg = ConfigManager:getNewBuffCfg()
        if buffCfg[buffId] then
            fileNames = { "heal01_FX1" }--common:split(buffCfg[buffId].HitEffectPath, ",")
        end
    end

    local cfg = target.otherData[CONST.OTHER_DATA.CFG]
    if NgBattleDataManager_getTestOpenHit() then
        for i = 1, #fileNames do 
            local fileName = fileNames[i]
            local randName = "animation"
            local isFlip = false --CHAR_UTIL:calIsFlipHitEffect(target.buffData[buffId][CONST.BUFF_DATA.CASTER], target)
            local effectKey = fileName.. "_" .. randName .. "_" .. (isFlip and "1" or "0")
            if target.hurtEffect[effectKey] then
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    local sceneSpeed = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and CONST.AFK_BATTLE_SPEED or NgBattleDataManager.battleSpeed
                    target.hurtEffect[effectKey]:setTimeScale(sceneSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            else
                target.hurtEffect[effectKey] = SpineContainer:create("Spine/hit", fileName)
                local effectNode = tolua.cast(target.hurtEffect[effectKey], "CCNode")
                local hitNode = target.heroNode.chaCCB:getVarNode("mHitFrontNode")
                if string.find(fileName, "FX2") then
                    hitNode = target.heroNode.chaCCB:getVarNode("mHitBackNode")
                elseif string.find(fileName, "FX3") then
                    hitNode = target.floorNode
                end
                hitNode:addChild(effectNode)
                local sToNode = tolua.cast(target.heroNode.heroSpine, "CCNode")
                if skillCfg and skillCfg[skillId] and skillCfg[skillId].effectType == 1 then
                    effectNode:setPositionY(0)
                else
                    effectNode:setPositionY(cfg and cfg.CenterOffsetY or 0)
                end
                effectNode:setScale(sToNode:getScaleY())
                effectNode:setScaleX(isFlip and -1 or 1)
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    target.hurtEffect[effectKey]:setTimeScale(NgBattleDataManager.battleSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            end
        end
    end
    -- 受擊數字
    self:showBattleNum(nil, target, dmg, false, 0, CONST.HURT_TYPE.HOT)

    local trueHeal = 0
    if not isSkipCalHp then
        trueHeal = math.min(dmg, target.battleData[CONST.BATTLE_DATA.MAX_HP] - target.battleData[CONST.BATTLE_DATA.HP])
        CHAR_UTIL:setHp(target, math.min(target.battleData[CONST.BATTLE_DATA.HP] + dmg, target.battleData[CONST.BATTLE_DATA.MAX_HP]))
    end
    local sceneHelper = require("Battle.NgFightSceneHelper")
    sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.HEALTH, target.buffData[buffId][CONST.BUFF_DATA.CASTER].idx, trueHeal, buffId, false, dmg)   -- 不計算溢補

    if buffId then
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.BUFF_HEALTH, target.buffData[buffId][CONST.BUFF_DATA.CASTER], target, buffId, false, false, dmg)
    end

    return dmg
end
-- 被治療
function NgBattleCharacterBase:beHealth(chaNode, target, dmg, isCri, isSkipCal, skillId, resultTable, allPassiveTable)
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then
        return
    end
    if target.nowState == CONST.CHARACTER_STATE.DYING and target.nowState == CONST.CHARACTER_STATE.DEATH 
        and target.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    local sceneHelper = require("Battle.NgFightSceneHelper")
    -- 受擊特效(TEST)
    local fileNames = { }
    local skillCfg = ConfigManager.getSkillCfg()
    if skillId then --技能
        skillCfg = ConfigManager.getSkillCfg()
        if skillCfg[skillId] then
            fileNames = common:split(skillCfg[skillId].HitEffectPath, ",")
        end
    else    --普攻(吸血)
        if tonumber(chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME]) then   --Hero
        else    --Monster
        end
    end

    local cfg = target.otherData[CONST.OTHER_DATA.CFG]
    if NgBattleDataManager_getTestOpenHit() then
        for i = 1, #fileNames do 
            local fileName = fileNames[i]
            local randName = "animation"
            local isFlip = CHAR_UTIL:calIsFlipHitEffect(chaNode, target)
            local effectKey = fileName.. "_" .. randName .. "_" .. (isFlip and "1" or "0")
            if target.hurtEffect[effectKey] then
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    local sceneSpeed = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and CONST.AFK_BATTLE_SPEED or NgBattleDataManager.battleSpeed
                    target.hurtEffect[effectKey]:setTimeScale(sceneSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            else
                target.hurtEffect[effectKey] = SpineContainer:create("Spine/hit", fileName)
                local effectNode = tolua.cast(target.hurtEffect[effectKey], "CCNode")
                local hitNode = target.heroNode.chaCCB:getVarNode("mHitFrontNode")
                if string.find(fileName, "FX2") then
                    hitNode = target.heroNode.chaCCB:getVarNode("mHitBackNode")
                elseif string.find(fileName, "FX3") then
                    hitNode = target.floorNode
                end
                hitNode:addChild(effectNode)
                local sToNode = tolua.cast(target.heroNode.heroSpine, "CCNode")
                if skillCfg and skillCfg[skillId] and skillCfg[skillId].effectType == 1 then
                    effectNode:setPositionY(0)
                else
                    effectNode:setPositionY(cfg and cfg.CenterOffsetY or 0)
                end
                effectNode:setScale(sToNode:getScaleY())
                effectNode:setScaleX(isFlip and -1 or 1)
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    target.hurtEffect[effectKey]:setTimeScale(NgBattleDataManager.battleSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            end
        end
    end
    -- 受擊數字
    self:showBattleNum(chaNode, target, dmg, false, 0, CONST.HURT_TYPE.BEHEALTH)

    local trueHeal = 0
    if not isSkipCalHp then
        trueHeal = math.min(dmg, target.battleData[CONST.BATTLE_DATA.MAX_HP] - target.battleData[CONST.BATTLE_DATA.HP])
        CHAR_UTIL:setHp(target, math.min(target.battleData[CONST.BATTLE_DATA.HP] + dmg, target.battleData[CONST.BATTLE_DATA.MAX_HP]))
    end
    sceneHelper:addBattleResult(CONST.DETAIL_DATA_TYPE.HEALTH, chaNode.idx, trueHeal, skillId, isCri, dmg)   -- 不計算溢補

    return dmg
end
-- (被)吸收魔力
function NgBattleCharacterBase:beDrainMana(chaNode, target, dmg, isSkipCal, skillId, resultTable, allPassiveTable)
    if NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.FIGHTING then
        return
    end
    if target.nowState == CONST.CHARACTER_STATE.DYING and target.nowState == CONST.CHARACTER_STATE.DEATH 
        and target.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end

    -- 受擊特效(TEST)
    if dmg > 0 and NgBattleDataManager_getTestOpenHit() then
        local fileNames = { "heal01_FX1" }
        local cfg = target.otherData[CONST.OTHER_DATA.CFG]
        for i = 1, #fileNames do 
            local fileName = fileNames[i]
            local randName = "animation"
            local isFlip = CHAR_UTIL:calIsFlipHitEffect(chaNode, target)
            local effectKey = fileName.. "_" .. randName .. "_" .. (isFlip and "1" or "0")
            if target.hurtEffect[effectKey] then
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    local sceneSpeed = NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK and CONST.AFK_BATTLE_SPEED or NgBattleDataManager.battleSpeed
                    target.hurtEffect[effectKey]:setTimeScale(sceneSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            else
                target.hurtEffect[effectKey] = SpineContainer:create("Spine/hit", fileName)
                local effectNode = tolua.cast(target.hurtEffect[effectKey], "CCNode")
                local hitNode = target.heroNode.chaCCB:getVarNode("mHitFrontNode")
                if string.find(fileName, "FX2") then
                    hitNode = target.heroNode.chaCCB:getVarNode("mHitBackNode")
                elseif string.find(fileName, "FX3") then
                    hitNode = target.floorNode
                end
                hitNode:addChild(effectNode)
                local sToNode = tolua.cast(target.heroNode.heroSpine, "CCNode")
                if skillCfg and skillCfg[skillId] and skillCfg[skillId].effectType == 1 then
                    effectNode:setPositionY(0)
                else
                    effectNode:setPositionY(cfg and cfg.CenterOffsetY or 0)
                end
                effectNode:setScale(sToNode:getScaleY())
                effectNode:setScaleX(isFlip and -1 or 1)
                if not target.hurtEffect[effectKey]:isPlayingAnimation(randName, 1) then
                    target.hurtEffect[effectKey]:setTimeScale(NgBattleDataManager.battleSpeed)
                    target.hurtEffect[effectKey]:runAnimation(1, randName, 0)
                end
            end
        end
    end
    -- 受擊數字
    self:showBattleNum(chaNode, target, dmg .. ".", false, 0, CONST.HURT_TYPE.MANA)

    CHAR_UTIL:setMp(target, math.max(0, math.min(target.battleData[CONST.BATTLE_DATA.MP] + dmg, target.battleData[CONST.BATTLE_DATA.MAX_MP])), true) -- onHit時已記錄MP

    if dmg > 0 then
        local buffConfig = ConfigManager:getNewBuffCfg()
        if skillId < 10000 then
            skillId = skillId * 10
        end
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.SKILL_ADD_MP, target, nil, skillId, false, false, math.abs(dmg))
    else
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.LOSE_MP, target, nil, nil, false, false, math.abs(dmg))
    end

    return dmg
end

-- 播放spine animation時處理
function NgBattleCharacterBase:setOnAnimationFunction(chaNode)
    chaNode.onPlaySpineAnimation = function()
        local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
        --全部行動目標table
        local allTargetTable = { }
        --觸發的被動table
        local allPassiveTable = { }
        --初始化攻擊參數
        local skillId = nil
        local resultTable = { }
        local sceneHelper = require("Battle.NgFightSceneHelper")
        local skillGroupId = sceneHelper:getNewSkillGroupId()
        local playAniName = chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME]
        --紀錄施放技能log
        LOG_UTIL:setPreLog(chaNode)
        if playAniName == CONST.ANI_ACT.ATTACK then   -- 普通攻擊
            LOG_UTIL:addAttackLog(chaNode, skillId, skillGroupId)
        elseif playAniName == CONST.ANI_ACT.SKILL0 then   -- 角色大招
            -- 清空MP
            CHAR_UTIL:setMp(chaNode, 0)

            skillId = self:getSkillIdByAction(chaNode, CONST.ANI_ACT.SKILL0, CONST.SKILL_DATA.SKILL)
            self:castSkill(chaNode, CONST.SKILL_DATA.SKILL, skillId)
            local skillBaseId = math.floor(skillId / 10)
            -- 技能語音音效  
            sceneHelper:playSoundEffect(chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] .. "_" .. skillBaseId .. ".mp3", chaNode)

            local elist = NgBattleDataManager_getEnemyList(chaNode)
            local aliveIdTable = NewBattleUtil:initAliveTable(elist)
            for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ENEMY_CAST_ACTIVE_SKILL]) do -- 敵方施放主動技能時觸發
                for i = 1, #aliveIdTable do
                    local actionResultTable = { }
                    if NewBattleUtil:castPassiveSkill(elist[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.ENEMY_CAST_ACTIVE_SKILL, { chaNode }) then
                        LOG_UTIL:setPreLog(elist[aliveIdTable[i]], resultTable)
                        CHAR_UTIL:calculateAllTable(elist[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                    end
                end
            end

            LOG_UTIL:addAttackLog(chaNode, skillId, skillGroupId)
        elseif playAniName == CONST.ANI_ACT.SKILL1 or
               playAniName == CONST.ANI_ACT.SKILL2 then   -- 角色小招
            skillId = self:getSkillIdByAction(chaNode, chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME], CONST.SKILL_DATA.AUTO_SKILL)
            self:castSkill(chaNode, CONST.SKILL_DATA.AUTO_SKILL, skillId)
            local skillBaseId = math.floor(skillId / 10)
            -- 技能語音音效  
            sceneHelper:playSoundEffect(chaNode.otherData[CONST.OTHER_DATA.ITEM_ID] .. "_" .. skillBaseId .. ".mp3", chaNode)
            LOG_UTIL:addAttackLog(chaNode, skillId, skillGroupId)
        end
    end
end
-- 強制清空角色身上所有buff/debuff
function NgBattleCharacterBase:forceClearAllBuff(chaNode, fList, eList)  
    for k, v in pairs(chaNode.buffData) do
        CHAR_UTIL:forceClearTargetBuff(chaNode, fList, eList, k)  
    end
end

--清除資料
function NgBattleCharacterBase:clearData(chaNode)
    chaNode.target = nil
end
---------------------------------------------------------------------------
function NgBattleCharacterBase:registSpineEventFunction(character)
    -- 註冊spine事件callback
    if not character.heroNode.heroSpine then return end
    character.heroNode.heroSpine:registerFunctionHandler("SELF_EVENT", self.onFunction)
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide and NgBattleDataManager.battleType == CONST.SCENE_TYPE.GUIDE then
        character.heroNode.heroSpine:registerFunctionHandler("COMPLETE", self.onGuide)
    end
end

function NgBattleCharacterBase:registCallBackFunction(character)
    -- 註冊其他callback
    character.beAttack = function(chaNode, target, dmg, isCri, isSkipCal, weakType, skillId, resultTable, allPassiveTable) 
        NgBattleCharacterBase:beAttack(chaNode, target, dmg, isCri, isSkipCal, weakType, skillId, resultTable, allPassiveTable) 
    end
    character.onHit = function(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
        NgBattleCharacterBase:onHit(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
    end
    character.onMiss = function(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
        NgBattleCharacterBase:onMiss(chaNode, skillId, resultTable, allPassiveTable, target, isCri)
    end
    character.onDead = function(chaNode)
        NgBattleCharacterBase:onDead(chaNode)
    end
    character.beHealth = function(chaNode, target, dmg, isCri, isSkipCal, skillId, resultTable, allPassiveTable) 
        NgBattleCharacterBase:beHealth(chaNode, target, dmg, isCri, isSkipCal, skillId, resultTable, allPassiveTable) 
    end
    character.beDrainMana = function(chaNode, target, dmg, isSkipCal, skillId, resultTable, allPassiveTable) 
        NgBattleCharacterBase:beDrainMana(chaNode, target, dmg, isSkipCal, skillId, resultTable, allPassiveTable) 
    end
end

-- Spine事件處理
function NgBattleCharacterBase:onFunction(tag, eventName)
    local isMine = (tag < CONST.ENEMY_BASE_IDX)
    local friendList = isMine and NgBattleDataManager.battleMineCharacter or NgBattleDataManager.battleEnemyCharacter
    local spriteList = isMine and NgBattleDataManager.battleMineSprite or NgBattleDataManager.battleEnemySprite
    local isSkipCal = not isMine and (NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK)  -- 掛機時不計算敵方傷害數字
    if (not friendList or not friendList[isMine and tag or tag - 10]) and (not spriteList or not spriteList[isMine and tag or tag - 10]) then
        return
    end
    -- 玩家掛機+中狂亂(會打隊友)時不造成傷害
    local chaNode = isMine and (friendList[tag] or spriteList[tag]) or (friendList[tag - 10] or spriteList[tag - 10])
    if not chaNode then
        return
    end
    if string.find(eventName, "_hit") and BuffManager:isInCrowdControl(chaNode.buffData) then  -- 播放第一幀時檢查到被控場 > 中斷動作
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        return
    end
    -- 攻擊計算起點(hit數, 基礎傷害...計算) *所有攻擊動作都必須要有這個事件 (攻擊, 技能施放)
    if string.find(eventName, "_hit") then  
        local triggerBuffList = { }
        local buffEvent = CONST.ADD_BUFF_COUNT_EVENT.CAST_ATTACK
        local attackLog = chaNode.attackLogData
        local skillId = attackLog.skillId
        if skillId then
            triggerBuffList = BuffManager:specialBuffEffect(chaNode.buffData, buffEvent, chaNode, chaNode.target, skillId)    -- 觸發buff效果
        end
        -- 特殊buff觸發處理
        if triggerBuffList[CONST.BUFF.PARALYSIS] or triggerBuffList[CONST.BUFF.TOXIN_OF_POSION] then  -- 麻痺, 烈毒
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
        else
            --紀錄hit數
            local hit_num = unpack(common:split(eventName, "_hit"))
            chaNode.ATTACK_PARAMS["hit_num"] = hit_num 
            --設定面相
            CHAR_UTIL:setChaDir(chaNode, chaNode.target) 
            if skillId then
                buffEvent = CONST.ADD_BUFF_COUNT_EVENT.CAST_SKILL
                chaNode.ATTACK_PARAMS["skill_target"] = NgBattleCharacterBase:onCalSkillTarget(chaNode, CONST.SKILL_DATA.SKILL, attackLog.skillId)
                if chaNode.ATTACK_PARAMS["skill_target"] and chaNode.ATTACK_PARAMS["skill_target"][1] then
                    CHAR_UTIL:setChaDir(chaNode, chaNode.ATTACK_PARAMS["skill_target"][1])
                end
            end
            BuffManager:clearBuffTimer(chaNode, chaNode.buffData, buffEvent)                                         -- 清空特定buff計時
            BuffManager:addBuffCount(chaNode, chaNode.buffData, buffEvent)                                           -- 增加buff層數
        end
    --攻擊(治療)命中 (非飛行道具)(技能實際作用)
	elseif eventName == "hit" then      
        local attackLog = chaNode.attackLogData
        --取得當前是第幾hit
        chaNode.ATTACK_PARAMS["hit_count"] = chaNode.ATTACK_PARAMS["hit_count"] + 1
        local hit = chaNode.ATTACK_PARAMS["hit_count"]
        --全部行動結果table(ex. hit, cri, miss)
        local actionResultTable = { }
        --全部行動目標table
        local allTargetTable = { }
        --觸發的被動table(資料格式: 類型_ID)
        local allPassiveTable = { }
        --技能id
        local skillId = attackLog.skillId
        local resultTable = nil
        if chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] == CONST.ANI_ACT.ATTACK then   -- 普通攻擊
            resultTable = CHAR_UTIL:createAttackResultTable(chaNode)
        elseif chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] == CONST.ANI_ACT.SKILL0 then   -- 角色大招
            resultTable = NgBattleCharacterBase:onSkill(chaNode, skillId, resultTable, allPassiveTable)
        else   -- 角色小招
            resultTable = NgBattleCharacterBase:onSkill(chaNode, skillId, resultTable, allPassiveTable)
        end
        if resultTable then
            LOG_UTIL:setPreLog(chaNode, resultTable)   
            CCLuaLog("Attacker CharacterId : " .. chaNode.idx)
            local logActionType = CONST.LogActionType.ATTACK
            if chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] == CONST.ANI_ACT.ATTACK then   -- 普通攻擊
                logActionType = CONST.LogActionType.ATTACK
            else
                logActionType = CONST.LogActionType.SKILL
            end
            local triggerBuffList = BuffManager:specialBuffEffect(chaNode.buffData, buffEvent, chaNode, nil, skillId)   -- 觸發buff效果
            CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, skillId, allPassiveTable)   -- 全部傷害/治療/buff...處理   
        end
        -- 檢查被動技能發動(需等log記錄完)
        CHAR_UTIL:checkPassiveSkill(chaNode)
        for i = 1, #allTargetTable do
            CHAR_UTIL:checkPassiveSkill(allTargetTable[i])
        end
        if #allTargetTable ~= #actionResultTable then
            --異常
            local eeeeeeeeeerror = 1
        end       
    -- 產生飛行道具(位移型) & 產生飛行道具(定點型)
    elseif string.find(eventName, "shoot") or string.find(eventName, "target") then
        local item_num = unpack(common:split(eventName, "_")) or 1
        local aniName = chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] or CONST.ANI_ACT.ATTACK
        local attackLog = chaNode.attackLogData
        local resultTable = { }
        local skillTargetTable = { }
        if aniName == CONST.ANI_ACT.ATTACK then
            resultTable = CHAR_UTIL:createAttackResultTable(chaNode)
        else
            skillTargetTable = chaNode.ATTACK_PARAMS["skill_target"] or NgBattleCharacterBase:onCalSkillTarget(chaNode, CONST.SKILL_DATA.SKILL, attackLog.skillId)
        end
        for i = 1, tonumber(item_num) do
            -- 觸發的被動table
            local allPassiveTable = { }
            -- 取得當前是第幾hit
            chaNode.ATTACK_PARAMS["hit_count"] = chaNode.ATTACK_PARAMS["hit_count"] + 1
            local hit = chaNode.ATTACK_PARAMS["hit_count"]
            if aniName == CONST.ANI_ACT.ATTACK and resultTable then
                local targetPosX, targetPosY = resultTable[CONST.LogDataType.DMG_TAR][i].heroNode.chaCCB:getPosition()
                targetPosY = targetPosY + resultTable[CONST.LogDataType.DMG_TAR][i].otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
                local flyItemType = string.find(eventName, "shoot") and CONST.FLYITEM_TYPE.SHOOT or 
                                    ( string.find(eventName, "target") and CONST.FLYITEM_TYPE.TARGET ) or CONST.FLYITEM_TYPE.SHOOT
                FlyItemManager:createFlyItem(chaNode, target, resultTable, hit, aniName, isSkipCal, 
                                             attackLog.skillId, attackLog.skillGroupId, targetPosX, targetPosY,
                                             flyItemType, allPassiveTable, skillTargetTable)
            elseif (aniName == CONST.ANI_ACT.SKILL0 or aniName == CONST.ANI_ACT.SKILL1 or aniName == CONST.ANI_ACT.SKILL2) and 
                   skillTargetTable[hit] then
                local targetPosX, targetPosY = skillTargetTable[hit].heroNode.chaCCB:getPosition()
                if attackLog.skillId == 21 then
                    targetPosX = CONST.BATTLE_FIELD_WIDTH / 2
                    targetPosY = CONST.BATTLE_FIELD_HEIGHT / 2
                else
                    if string.find(eventName, "floor") then
                        targetPosY = targetPosY
                    else
                        targetPosY = targetPosY + skillTargetTable[hit].otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
                    end
                end
                local flyItemType = string.find(eventName, "shoot") and CONST.FLYITEM_TYPE.SHOOT or 
                                    ( string.find(eventName, "target") and CONST.FLYITEM_TYPE.TARGET ) or CONST.FLYITEM_TYPE.SHOOT
                FlyItemManager:createFlyItem(chaNode, target, resultTable, hit, aniName, isSkipCal, 
                                             attackLog.skillId, attackLog.skillGroupId, targetPosX, targetPosY,
                                             flyItemType, allPassiveTable, skillTargetTable)
            end
        end
    --技能施放遮罩開啟
    elseif eventName == "mask_open" then
        if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK and NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then
            local sceneHelper = require("Battle.NgFightSceneHelper")
            if BuffManager:isInCrowdControl(chaNode.buffData) then
                return
            end
            -- 先把全部角色時停
            sceneHelper:setSceneSpeed(0)
            -- function順序不能變動
            NgBattleDataManager_setCastSkillNode(chaNode)   -- 設定當前施放大招的角色
            sceneHelper:setMaskLayerVisible(true)           -- 開啟黑幕
            sceneHelper:setSkillSceneSpeed(true)            -- 設定Spine Timescale
            sceneHelper:setSkillSpineOrder(true)            -- 設定角色ZOrder
        end
    --技能施放遮罩關閉
    elseif eventName == "mask_close" then
        local sceneHelper = require("Battle.NgFightSceneHelper")
        if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK and NgBattleDataManager.battleState == CONST.FIGHT_STATE.FIGHTING then
            sceneHelper:setSkillSpineOrder(false)       -- 還原角色ZOrder
            --NgBattleDataManager_setCastSkillNode({ })   -- 解除當前施放大招的角色
            --sceneHelper:setSkillSceneSpeed(true)        -- 還原Spine Timescale
            --sceneHelper:playSpecialSpine(tag)
            NgFightSceneHelper:setMaskLayerVisible(false)      -- 關閉黑幕
            NgBattleDataManager_setCastSkillNode(nil)   -- 解除當前施放大招的角色
            NgFightSceneHelper:setSkillSceneSpeed(false)       -- 還原Spine Timescale
        end
    --強制位移
    elseif eventName == "move" then 
        local itemId = chaNode.otherData[CONST.OTHER_DATA.ITEM_ID]
        local attackLog = chaNode.attackLogData
        local skillTarget = chaNode.ATTACK_PARAMS["skill_target"] or NgBattleCharacterBase:onCalSkillTarget(CONST.SKILL_DATA.SKILL, attackLog.skillId)
        if skillTarget and skillTarget[1] then
            if itemId == 5 or itemId == 16 then
                local selfPosX = chaNode.heroNode.chaCCB:getPositionX()
                local posX = skillTarget[1].heroNode.chaCCB:getPositionX()
                local posY = skillTarget[1].heroNode.chaCCB:getPositionY()
                local tarPosX = ((selfPosX > posX) and (posX + skillTarget[1].otherData[CONST.OTHER_DATA.CFG].CenterOffsetY)) or 
                                ((selfPosX < posX) and (posX - skillTarget[1].otherData[CONST.OTHER_DATA.CFG].CenterOffsetY)) or selfPosX
                if ((selfPosX > posX) and (selfPosX < tarPosX)) or ((selfPosX < posX) and (selfPosX > tarPosX)) then
                    tarPosX = selfPosX
                end
                local array = CCArray:create()
                array:addObject(CCMoveTo:create(3 / 30, ccp(tarPosX, posY)))
                array:addObject(CCCallFunc:create(function()
                    NgBattleCharacterUtil:moveToTargetPos(chaNode, chaNode.heroNode.chaCCB:getPositionX(), chaNode.heroNode.chaCCB:getPositionY())
                end))
                chaNode.heroNode.chaCCB:stopAllActions()
                chaNode.heroNode.chaCCB:runAction(CCSequence:create(array))
            elseif itemId == 11 or itemId == 23 then
                -- 計算位置
                local sToNodeTarget = tolua.cast(skillTarget[1].heroNode.heroSpine, "CCNode")
                local paramFlip = (skillTarget[1].otherData[CONST.OTHER_DATA.IS_FLIP] == 1) and -1 or 1
                local paramScaleX = (sToNodeTarget:getScaleX() > 0) and 1 or -1
                local offsetX = (chaNode.battleData[CONST.BATTLE_DATA.RANGE] + skillTarget[1].otherData[CONST.OTHER_DATA.CFG].CenterOffsetX) * paramFlip * paramScaleX
                CHAR_UTIL:moveToTargetPos(chaNode, skillTarget[1].heroNode.chaCCB:getPositionX() + offsetX, skillTarget[1].heroNode.chaCCB:getPositionY())
                --設定面相
                CHAR_UTIL:setChaDir(chaNode, skillTarget[1])
            end
        end
    --關閉角色顯示
    elseif eventName == "hideAll" then 
        local sToNode = tolua.cast(attacker.heroNode.heroSpine, "CCNode")
        sToNode:setVisible(false)
    --開啟角色顯示
    elseif eventName == "showAll" then
        local sToNode = tolua.cast(attacker.heroNode.heroSpine, "CCNode")
        sToNode:setVisible(true)
    --播放FX4特效
    elseif string.find(eventName, "play_fx4") then
        local params = common:split(eventName, "_") -- play_fx4_parent點位_動作名稱_shift點位
        -- "角色名稱_動作名稱_FX4"
        local heroToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
        local spineName = chaNode.otherData[CONST.OTHER_DATA.SPINE_NAME] .. "_FX4"
        if string.find(spineName, "Boss") then
            spineName = chaNode.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] .. "_FX4"
        end
        local spine = nil
        local sToNode = nil
        local spineTable = chaNode.allSpineTable
        if spineTable[spineName .. "_" .. params[4]] then
            spine = spineTable[spineName .. "_" .. params[4]]
            sToNode = tolua.cast(spine, "CCNode")
        else
            spine = SpineContainer:create(chaNode.otherData[CONST.OTHER_DATA.SPINE_PATH_BACK_FX], spineName)
            sToNode = tolua.cast(spine, "CCNode")
            local fightNode = chaNode.heroNode.chaCCB:getParent()
            local parentNode = fightNode:getChildByTag(CONST.FX4_NODE_TAG_VALUE + tonumber(params[3])) -- 層級
            CCLuaLog(">>>FX4 Tag = " .. CONST.FX4_NODE_TAG_VALUE + tonumber(params[3]))
            local shiftNode = params[5] and fightNode:getChildByTag(CONST.FX4_NODE_TAG_VALUE + tonumber(params[5]))    -- 實際位置
            parentNode:addChild(sToNode)
            spineTable[spineName .. "_" .. params[4]] = spine
            local shiftX = shiftNode and shiftNode:getPositionX() or 0
            local shiftY = shiftNode and shiftNode:getPositionY() or 0
            if shiftNode then
                sToNode:setPositionX(sToNode:getPositionX() + (shiftX - parentNode:getPositionX()))
                sToNode:setPositionY(sToNode:getPositionY() + (shiftY - parentNode:getPositionY()))
            end
            CCLuaLog(">>>FX4 Parent Pos : x = " .. parentNode:getPositionX() .. ", y = " .. parentNode:getPositionY())
        end
        local sToNode = tolua.cast(spine, "CCNode")
        sToNode:setScaleX(heroToNode:getScaleX() > 0 and 1 or -1)
        local sceneType = NgBattleDataManager.battleType
        local sceneSpeed = NgBattleDataManager.battleSpeed
        spine:setTimeScale(sceneSpeed)
        spine:runAnimation(1, params[4], 0)
    --播放場景特效
    elseif string.find(eventName, "sceneFX") then
        local params = common:split(eventName, "_") -- sceneFX_編號_持續時間
        local sceneHelper = require("Battle.NgFightSceneHelper")
        sceneHelper:createSceneFx("BattlePageScenesFX" .. params[2] .. ".ccbi", tonumber(params[3]) * 1000)
    end
end

-- Spine事件處理(新手教學用)
function NgBattleCharacterBase:onGuide(tag, eventName)
    if eventName == "COMPLETE" then
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.checkGuideBattleCanNextStep(tag) then
            GuideManager.forceNextNewbieGuide()
        end
    end
end

function NgBattleCharacterBase:getSkillIdByAction(chaNode, action, skillType)
    for k, v in pairs(chaNode.skillData[skillType]) do
        if v["ACTION"] == action then
            return k
        end
    end
    return nil
end
function NgBattleCharacterBase:getNowSkillId()
    return self.skillData.nowSkillId
end
function NgBattleCharacterBase:setNowSkillId(id)
    self.skillData.nowSkillId = id
end
function NgBattleCharacterBase:castSkill(chaNode, skillType, skillId)
    local skillManager = require("Battle.NewSkill.SkillManager")
    return skillManager:castSkill(chaNode, skillType, skillId)
end
function NgBattleCharacterBase:onSkill(chaNode, id, resultTable, allPassiveTable)
    local skillManager = require("Battle.NewSkill.SkillManager")
    return skillManager:runSkill(chaNode, id, resultTable, allPassiveTable, chaNode.ATTACK_PARAMS["skill_target"])
end
function NgBattleCharacterBase:onSkillWithTarget(chaNode, id, resultTable, allPassiveTable, targetTable, params)
    local skillManager = require("Battle.NewSkill.SkillManager")
    return skillManager:runSkill(chaNode, id, resultTable, allPassiveTable, targetTable, params)
end
function NgBattleCharacterBase:onCalSkillTarget(chaNode, skillType, id)
    local skillManager = require("Battle.NewSkill.SkillManager")
    return skillManager:calSkillTarget(id, chaNode)
end
function NgBattleCharacterBase:castStartBattleSkill(chaNode)
    if chaNode.nowState == CONST.CHARACTER_STATE.DYING and chaNode.nowState == CONST.CHARACTER_STATE.DEATH 
        and chaNode.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.START_BATTLE]) do -- 開場觸發
        local resultTable = { }
        local allPassiveTable = { }
        local actionResultTable = { }
        local allTargetTable = { }
        if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.START_BATTLE) then
            LOG_UTIL:setPreLog(chaNode, resultTable)
            CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
        end
    end
    for k, v in pairs(CONST.RUNE_PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.START_BATTLE]) do -- 開場觸發
        local resultTable = { }
        local allPassiveTable = { }
        local actionResultTable = { }
        local allTargetTable = { }
        if NewBattleUtil:castRunePassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.START_BATTLE) then
            LOG_UTIL:setPreLog(chaNode, resultTable)
            CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
        end
    end
end
function NgBattleCharacterBase:castCdPassiveSkill(chaNode)
    if chaNode.nowState == CONST.CHARACTER_STATE.DYING and chaNode.nowState == CONST.CHARACTER_STATE.DEATH 
        and chaNode.nowState ~= CONST.CHARACTER_STATE.REBIRTH then
        return
    end
    if chaNode.nowState == CONST.CHARACTER_STATE.WAIT or chaNode.nowState == CONST.CHARACTER_STATE.MOVE or 
       chaNode.nowState == CONST.CHARACTER_STATE.ATTACK or chaNode.nowState == CONST.CHARACTER_STATE.REBIRTH then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.CD]) do -- CD觸發
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.CD) then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
    end
end

function NgBattleCharacterBase:showBattleNum(chaNode, target, dmg, isCri, weakType, hurtType)
    if (not NgBattleDataManager_getTestOpenNum()) then
        return
    end
    local numType = nil
    if hurtType == CONST.HURT_TYPE.BEATTACK then
        if BuffManager:isInInvincible(target.buffData) or BuffManager:closeGhost(target, target.buffData) then   -- 沒有觸發鬼魅/無敵才跳數字
            return
        end
        if dmg > 0 then
            if isCri then
                if target.otherData[CONST.OTHER_DATA.IS_ENEMY] then
                    numType = CONST.SHOW_NUM_TYPE.ENEMY_CRI_ATTACK  -- 爆擊
                else
                    numType = CONST.SHOW_NUM_TYPE.CRI_ATTACK  -- 爆擊
                end
            else
                if target.otherData[CONST.OTHER_DATA.IS_ENEMY] then
                    if chaNode.battleData[CONST.BATTLE_DATA.IS_PHY] then
                        numType = CONST.SHOW_NUM_TYPE.ENEMY_PHY_ATTACK  -- 物理攻擊
                    else
                        numType = CONST.SHOW_NUM_TYPE.ENEMY_MAG_ATTACK  -- 魔法攻擊
                    end
                else
                    numType = CONST.SHOW_NUM_TYPE.PHY_ATTACK  -- 物理/魔法攻擊
                end
            end
        else
            numType = CONST.SHOW_NUM_TYPE.MISS  -- 未命中
        end
    elseif hurtType == CONST.HURT_TYPE.DOT then
        if BuffManager:isInInvincible(target.buffData) then   -- 沒有無敵才跳DOT數字
            return
        end
        numType = CONST.SHOW_NUM_TYPE.DOT  -- DOT
    elseif hurtType == CONST.HURT_TYPE.HOT or hurtType == CONST.HURT_TYPE.BEHEALTH then
        numType = CONST.SHOW_NUM_TYPE.HEALTH  -- HEAL
    elseif hurtType == CONST.HURT_TYPE.MANA then
        numType = CONST.SHOW_NUM_TYPE.MANA  -- MANA
    end
    -- 受擊數字
    local addAniCCB = nil
    local numNode = target.heroNode.chaCCB:getVarNode("mNumNode")
    target.HIT_NUM_POOL = target.HIT_NUM_POOL or { } 
    target.HIT_NUM_POOL[numType] = target.HIT_NUM_POOL[numType] or { } 
    for i = 1, #target.HIT_NUM_POOL[numType] do
        if target.HIT_NUM_POOL[numType][i].isDone == true then
            target.HIT_NUM_POOL[numType][i].isDone = false
            target.HIT_NUM_POOL[numType][i]:setVisible(true)
            addAniCCB = target.HIT_NUM_POOL[numType][i]
            break
        end
    end
    if not addAniCCB then
        if numType == CONST.SHOW_NUM_TYPE.ENEMY_CRI_ATTACK then
            addAniCCB = ScriptContentBase:create("BattleCritsNum01")
        elseif numType == CONST.SHOW_NUM_TYPE.CRI_ATTACK then
            addAniCCB = ScriptContentBase:create("BattleCritsNum02")
        elseif numType == CONST.SHOW_NUM_TYPE.ENEMY_PHY_ATTACK then
            addAniCCB = ScriptContentBase:create("BattleNormalNum01")
        elseif numType == CONST.SHOW_NUM_TYPE.ENEMY_MAG_ATTACK then
            addAniCCB = ScriptContentBase:create("BattleNormalNum02")
        elseif numType == CONST.SHOW_NUM_TYPE.PHY_ATTACK then
            addAniCCB = ScriptContentBase:create("BattleNormalNum03")
        elseif numType == CONST.SHOW_NUM_TYPE.MISS then
            addAniCCB = ScriptContentBase:create("BattleDodgeNum")
        elseif numType == CONST.SHOW_NUM_TYPE.DOT then
            addAniCCB = ScriptContentBase:create("BattleHealNum02")
        elseif numType == CONST.SHOW_NUM_TYPE.HEALTH then
            addAniCCB = ScriptContentBase:create("BattleHealNum")
        elseif numType == CONST.SHOW_NUM_TYPE.MANA then
            addAniCCB = ScriptContentBase:create("BattleHealNum04")
        end

        addAniCCB.isDone = false
        table.insert(target.HIT_NUM_POOL[numType], addAniCCB)
        
        numNode:addChild(addAniCCB)
        addAniCCB:release() 
    end
    local dmgTxt = addAniCCB:getVarLabelBMFont("mNumLabel")
    if dmgTxt then
        dmgTxt:setString(GameUtil:formatNumber(dmg))
    end
    if hurtType == CONST.HURT_TYPE.BEATTACK and dmg > 0 then
        if isCri then
            NewBattleUtil:setCriDmgAni(addAniCCB, dmg)
        else
            if weakType == 1 then   --剋屬
                addAniCCB:runAnimation("showNum_atk01")
            elseif weakType == -1 then  --逆屬
                addAniCCB:runAnimation("showNum_atk03")
            else
                addAniCCB:runAnimation("showNum_atk02")
            end
        end
    else
        addAniCCB:runAnimation("showNum")
    end
    local cfg = target.otherData[CONST.OTHER_DATA.CFG]
    addAniCCB:setVisible(true)
    addAniCCB:setPositionY((cfg and cfg.HeadOffsetY / numNode:getScaleY() or 250))
    addAniCCB:registerFunctionHandler(self.onSubFunction)
end

return NgBattleCharacterBase