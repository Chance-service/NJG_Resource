BuffManager = BuffManager or { }
local buffConfig = ConfigManager:getNewBuffCfg()
local CONST = require("Battle.NewBattleConst")
-------------------------------------------------------
--獲得BUFF
function BuffManager:getBuff(chaNode, target, buffId, buffTime, buffCount)
    if self:isInMalicious(target.buffData) then   --惡意狀態 不可上BUFF
        if buffConfig[buffId].gain == 1 then
            return false
        end
    end
    if self:isInImmunity(target.buffData) then   --免疫狀態 不可上DEBUFF(不可驅散的不能免疫)
        if buffConfig[buffId].gain == 0 and buffConfig[buffId].dispel == 1 then
            return false
        end
    end
    if self:isInConductor(target.buffData)then   --導電體狀態 不可上靜電
        local baseBuffId = math.floor(buffId / 100) % 1000
        if baseBuffId == CONST.BUFF.STATIC then
            return false
        end
    end
    if self:isInFrenzy(target.buffData) then   --狂亂狀態  不可上狂亂
        local baseBuffId = math.floor(buffId / 100) % 1000
        if baseBuffId == CONST.BUFF.FRENZY then
            return false
        end
    end
    if buffConfig[buffId].gain == 0 and buffConfig[buffId].dispel == 1 then -- 角色免疫屬性
        if NewBattleUtil:isTriggerDebuffImmunity(target, chaNode) then
            return false
        end
    end
    -- 檢查被動技能免疫特定Buff
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.IMMUNITY_BUFF]) do -- 免疫特定Buff
        if target.skillData[CONST.SKILL_DATA.PASSIVE] then
            for skillId, data in pairs(target.skillData[CONST.SKILL_DATA.PASSIVE]) do
                local mainSkillId = math.floor(skillId / 10)
                if mainSkillId == v then
                    local immunityId = SkillManager:calSkillSpecialParams(skillId)
                    for idx = 1, #immunityId do
                        local mainBuffId = math.floor(buffId / 100) % 1000
                        if mainBuffId == immunityId[idx] then
                            return false
                        end
                    end
                end
            end
        end
    end
    if target.buffData[buffId] then   --buff已存在
        if target.buffData[buffId][CONST.BUFF_DATA.TIME] < buffTime or     --剩餘時間較少
           buffId == CONST.BUFF.TAUNT then --嘲諷強制舊蓋新
            --刷新時間
            target.buffData[buffId][CONST.BUFF_DATA.TIME] = buffTime
            target.buffData[buffId][CONST.BUFF_DATA.UPDATE_TIME] = NgBattleDataManager.battleTime
        end
        --刷新層數
        local oldIsMaxCount = target.buffData[buffId][CONST.BUFF_DATA.COUNT] >= buffConfig[buffId].max_count
        local newCount = math.min(target.buffData[buffId][CONST.BUFF_DATA.COUNT] + buffCount, buffConfig[buffId].max_count)
        target.buffData[buffId][CONST.BUFF_DATA.COUNT] = newCount
        --設定施放者
        target.buffData[buffId][CONST.BUFF_DATA.CASTER] = chaNode
        -- 播放BUFF SPINE
        NewBattleUtil:playBuffSpine(target, buffId, target.buffData[buffId])
        -- 特定buff獲得處理
        self:getSpecialBuff(chaNode, target, target.buffData, buffId, oldIsMaxCount)
    else    --buff不存在
        local highLevelBuff = false
        local lowLevelBuffId = nil
        --檢查是否存在高/低階buff
        for fullBuffId, buffData in pairs(target.buffData) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if buffConfig[fullBuffId].group == buffConfig[buffId].group then
                if buffConfig[fullBuffId].priority > buffConfig[buffId].priority then    -- 已經有高階buff
                    highLevelBuff = true
                elseif buffConfig[fullBuffId].priority <= buffConfig[buffId].priority then   -- 已經有低階/相同階級buff
                    lowLevelBuffId = fullBuffId
                end
            end
        end
        if not highLevelBuff then   --不存在高階buff -> 新增該buff
            if not target.buffData[buffId] then
                table.insert(target.buffData, buffId, { })
            end
            local newCount = math.min(buffCount, buffConfig[buffId].max_count)
            target.buffData[buffId][CONST.BUFF_DATA.TIME] = buffTime
            target.buffData[buffId][CONST.BUFF_DATA.COUNT] = newCount
            target.buffData[buffId][CONST.BUFF_DATA.TIMER] = 0
            target.buffData[buffId][CONST.BUFF_DATA.TIMER2] = 0
            target.buffData[buffId][CONST.BUFF_DATA.UPDATE_TIME] = NgBattleDataManager.battleTime
            -- 設定施放者
            target.buffData[buffId][CONST.BUFF_DATA.CASTER] = chaNode
            -- 有低階buff > 移除低階buff
            if lowLevelBuffId then
                NewBattleUtil:removeBuff(target, lowLevelBuffId, true)
            end
            -- 顯示ICON
            NewBattleUtil:addBuffIcon(target, buffId)
            -- 播放BUFF SPINE
            NewBattleUtil:playBuffSpine(target, buffId, target.buffData[buffId])
            -- 特定buff獲得處理
            self:getSpecialBuff(chaNode, target, target.buffData, buffId, oldIsMaxCount)
        end
    end
    if buffConfig[buffId].buffType ~= 4 then
        local LOG_UTIL = require("Battle.NgBattleLogUtil")
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.GAIN_BUFF, chaNode, target, buffId, false, false, 0)
    end
    if buffConfig[buffId].gain == 0 then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.GET_DEBUFF]) do -- 獲得DeBuff
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.GET_DEBUFF, { }) then
                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                LOG_UTIL:setPreLog(target, resultTable)
                CHAR_UTIL:calculateAllTable(target, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
    end
    if buffConfig[buffId].gain == 1 then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.GET_BUFF]) do -- 獲得Buff
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.GET_BUFF, { }) then
                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                LOG_UTIL:setPreLog(target, resultTable)
                CHAR_UTIL:calculateAllTable(target, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
    end

    return true
end

-- 攻擊力加成(%數)
function BuffManager:checkAtkBuffValue(chaNode, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PETAL then  -- 開花
                    addValue = tonumber(buffValues[3]) and tonumber(buffValues[3]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.FORCE then  -- 強攻
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.PRECISION then  -- 精確
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.FURY then  -- 怒氣
                    local hpPer = chaNode.battleData[CONST.BATTLE_DATA.HP] / chaNode.battleData[CONST.BATTLE_DATA.MAX_HP]   -- 當前hp比例
                    local loseHpPer = 1 - hpPer
                    addValue = math.floor(loseHpPer / tonumber(buffValues[1])) * tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- 冰心
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.GHOST then  -- 鬼魅
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- 無雙
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_I then  -- 獵魔人I式
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.DEPENDENTS then -- 眷屬
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.FEAR then -- 恐懼
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if isPhy then
                    if mainBuffId == CONST.BUFF.OUROBOROS then  -- 銜尾蛇
                        addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.BRUTAL then    -- 蠻勇
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.ASSAULT_B then  -- 突擊
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.BOOST_B then  -- 鼓舞
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.INVINCIBLE then  -- 無敵
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.WEAK then -- 衰弱
                        addValue = tonumber(buffValues[1])
                    end
                else
                    if mainBuffId == CONST.BUFF.ENLIGHTENMENT then  -- 啟蒙
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- 魔力溢出
                        addValue = tonumber(buffValues[1]) and tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.ARCANE_B then  -- 奧術
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.MAGIC_LOCK then    -- 魔力鎖鏈
                        addValue = tonumber(buffValues[1])
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 攻擊力加成(數值)
function BuffManager:checkAtkBuffValue2(chaNode, isPhy, aniName)
    local buff = chaNode.buffData
    local addValue = 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.FALSE_GOD then -- 偽神
                end
            end
        end
    end
    return addValue
end
-- 防禦力加成(%數)
function BuffManager:checkDefBuffValue(target, buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    local buff = target.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.DEFENSE_CHAIN_B then  -- 防禦鎖鏈
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- 冰心
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.ICE_WALL then  -- 冰牆
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.MAGICIAN then  -- 御用魔導
                    -- 檢查目標血量
                    local hpPer = target.battleData[CONST.BATTLE_DATA.HP] / target.battleData[CONST.BATTLE_DATA.MAX_HP]
                    if hpPer >= tonumber(buffValues[1]) then
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- 無雙
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.DESTROY then  -- 防禦破壞
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.COLLAPSE then   -- 崩壞
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if isPhy then
                    if mainBuffId == CONST.BUFF.STABLE then   -- 堅守
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.DEFENSE_HEART_B then  -- 防守之心
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.BROKEN then  -- 破防
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == FRAGILE then  -- 脆弱
                        addValue = tonumber(buffValues[1])
                    end
                else
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- 魔力溢出
                        addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.ARCANE_B then  -- 奧術
                        addValue = tonumber(buffValues[2])
                    end
                    if mainBuffId == CONST.BUFF.MAGIC_SHIELD_B then  -- 禦魔盾甲
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.WITCHER_III then  -- 獵魔人III式
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.FORCE_FIELD then  -- 力場
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.EXHAUST then  -- 破魔
                        addValue = tonumber(buffValues[1])
                    end
                end
                --------------------------------------------------------------- 強制歸零
                if mainBuffId == CONST.BUFF.FREEZE then  -- 凍結
                    buffValue, auraValue, markValue = tonumber(buffValues[1]), tonumber(buffValues[1]), tonumber(buffValues[1])
                    break   -- 歸零後不處理後面的防禦buff
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 防禦力加成(數值)
function BuffManager:checkDefBuffValue2(target, buff, isPhy, aniName)
    local addValue = 0
    local buff = target.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.FALSE_GOD then -- 偽神
                end
            end
        end
    end
    return addValue
end
-- 防禦力穿透加成
function BuffManager:checkDefPenetrateBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if aniName == CONST.ANI_ACT.ATTACK then -- 普通攻擊時
                    if mainBuffId == CONST.BUFF.CONCENTRATION then  -- 專注
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- 冰心
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.WITCHER_I then  -- 獵魔人I式
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 傷害加成(自己增傷+敵方受傷加成)
function BuffManager:checkAllDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue, auraValue, markValue = self:checkDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue2, auraValue2, markValue2 = self:checkBeDmgBuffValue(attacker, target, isPhy, aniName)
    return math.max(0, buffValue + buffValue2 - 1), math.max(0, auraValue + auraValue2 - 1), math.max(0, markValue + markValue2 - 1)
end
-- 造成傷害加成
function BuffManager:checkDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    local buff = attacker.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.CHASE then  -- 追擊
                    -- 檢查目標血量
                    local hpPer = target.battleData[CONST.BATTLE_DATA.HP] / target.battleData[CONST.BATTLE_DATA.MAX_HP]
                    if hpPer < tonumber(buffValues[1]) then
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
                    addValue = tonumber(buffValues[1])
                end
                if aniName == CONST.ANI_ACT.ATTACK then -- 普通攻擊時
                    if mainBuffId == CONST.BUFF.PUNCTURE then  -- 穿刺
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.PIERCING_ICE then  -- 寒冰刺骨
                        if buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count then
                            addValue = tonumber(buffValues[1])
                        end
                    end
                    if mainBuffId == CONST.BUFF.DARK_THUNDER then  -- 暗雷引導
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.FRENZY then  -- 狂亂
                        addValue = tonumber(buffValues[1])
                    end
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_TODMG_FIRE1 or   -- 符石
                   mainBuffId == CONST.BUFF.RUNE_TODMG_WATER1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_LIGHT1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_DARK1 then
                    if target.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if mainBuffId == CONST.BUFF.RUNE_TODMG_FIRE_WATER1 or   -- 符石
                   mainBuffId == CONST.BUFF.RUNE_TODMG_WATER_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_FIRE_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_LIGHT_DARK1 then
                    if target.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) or 
                       target.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[3]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 受到傷害加成
function BuffManager:checkBeDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue, auraValue, markValue, skillValue = 1, 1, 1, 1
    local buff = target.buffData  -- 目標的Buff
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- 虔誠
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.PETAL then  -- 開花
                    addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.GUARD then  -- 守護
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.NATURE then   -- 自然印記
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.STONE then  -- 石化
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.TACTICAL_VISOR then -- 戰術鎖定
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.DEPENDENTS then -- 眷屬
                    -- 檢查攻擊者技能ID
                    for skillType, skillTypeData in pairs(attacker.skillData) do
                        for skillId, skillIdData in pairs(skillTypeData) do
                            if skillId == tonumber(buffValues[3]) then
                                addValue = tonumber(buffValues[2])
                            end
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.FREEZE then -- 凍結
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.INJURY then -- 受傷
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.CONDUCTOR then  -- 導電體
                    if aniName and aniName == CONST.ANI_ACT.SKILL0 then -- 大招時
                        local buffCount = 0
                        local fList = NgBattleDataManager_getFriendList(target)
                        local aliveIdTable = NewBattleUtil:initAliveTable(fList)
                        for i = 1, #aliveIdTable do -- 計算隊伍中導電體的數量
                            local friendNode = fList[aliveIdTable[i]]
                            for buffId, buffData in pairs(friendNode.buffData) do
                                local id = math.floor(buffId / 100) % 1000
                                if id == CONST.BUFF.CONDUCTOR then  -- 導電體
                                    buffCount = buffCount + 1
                                end
                            end
                        end
                        if buffCount <= 1 then  -- 沒有其他導電體
                            addValue = tonumber(buffValues[2])
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.OFFERINGS then -- 祭品
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then -- 血祭
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.BURN then -- 燃燒
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.TARGET_BUFF_ADD_DMG]) do -- 技能對特定Buff增傷
                        local skillType, fullSkillId = NewBattleUtil:checkSkill(v, attacker.skillData)
                        local baseSkillId = math.floor(fullSkillId / 10)
                        if baseSkillId == 1023 then
                            local skillCfg = ConfigManager:getSkillCfg()
                            if skillCfg[fullSkillId] then
                                local skillValues = common:split(skillCfg[fullSkillId].values, ",")
                                addValue = tonumber(skillValues[5])
                            end
                        end
                    end
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_BEDMG_FIRE1 or   -- 符石
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_WATER1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_LIGHT1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_DARK1 then
                    if attacker.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if mainBuffId == CONST.BUFF.RUNE_BEDMG_FIRE_WATER1 or   -- 符石
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_WATER_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_FIRE_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_LIGHT_DARK1 then
                    if attacker.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) or 
                       attacker.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[3]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    local buff = attacker.buffData  -- 攻擊者的Buff
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                -- 毒類型Buff
                if mainBuffId == CONST.BUFF.POSITION or
                   mainBuffId == CONST.BUFF.SOUL_OF_POSION or
                   mainBuffId == CONST.BUFF.TOXIN_OF_POSION or
                   mainBuffId == CONST.BUFF.SNAKE_OF_POSION then
                    -- 檢查受擊者技能ID
                    for skillType, skillTypeData in pairs(target.skillData) do
                        for skillId, skillIdData in pairs(skillTypeData) do
                            local baseSkillId = math.floor(skillId / 10)
                            if baseSkillId == 1133 then
                                local skillConfig = ConfigManager.getSkillCfg()
                                local skillValues = common:split(skillConfig[skillId].values, ",")
                                addValue = tonumber(skillValues[1])
                            end
                        end
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) * math.max(skillValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 爆擊率加成
function BuffManager:checkCriBuffValue(attacker, buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PRECISION then  -- 精確
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.EMBER then  -- 餘燼
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.STEALTH then  -- 隱身
                    addValue = tonumber(buffValues[1])
                    NewBattleUtil:removeBuff(attacker, fullBuffId, false)   -- 觸發後移除
                    -- 施放小招檢查
                    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                    if CHAR_UTIL:isCanLittleSkill(attacker, CONST.SKILL1_TRIGGER_TYPE.STEALTH_CLEAR) then
                        local skillId = CHAR_UTIL:getTriggerLittleSkill(attacker, CONST.SKILL1_TRIGGER_TYPE.STEALTH_CLEAR)  -- 檢查觸發的小招
                        if skillId then
                            local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
                            NgBattleCharacterBase:useLittleSkill(attacker, skillId)
                            return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
                        end
                    end
                end
                --------------------------------------------------------------- 強制爆擊
                if aniName == CONST.ANI_ACT.ATTACK then  -- 普通攻擊時
                    if mainBuffId == CONST.BUFF.RAGE or   -- 憤怒
                       mainBuffId == CONST.BUFF.SINISTER then   -- 惡毒
                        local value = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and 1 or 0
                        buffValue, auraValue, markValue = value, value, value
                        if value == 1 then
                            break   -- 必爆後不處理後面的buff
                        end
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 爆傷加成
function BuffManager:checkCriDmgBuffValue(chaNode, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    local buff = chaNode.buffData
    if buff then
        local removeInfernoId = nil
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                if aniName == CONST.ANI_ACT.ATTACK then
                    if mainBuffId == CONST.BUFF.RAGE then   -- 憤怒
                        addValue = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and tonumber(buffValues[1]) or nil
                    end
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.INFERNO then  -- 業火
                    addValue = tonumber(buffValues[1]) and tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    -- 觸發後移除
                    removeInfernoId = fullBuffId
                    -- 移除後觸發被動技能
                    local list = NgBattleDataManager_getFriendList(chaNode)
                    local aliveIdTable = NewBattleUtil:initAliveTable(list)
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE]) do -- 友方Buff移除時觸發被動
                        for i = 1, #aliveIdTable do
                            local resultTable = { }
                            local allPassiveTable = { }
                            local actionResultTable = { }
                            local allTargetTable = { }
                            if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE, { chaNode }) then
                                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                                LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                                CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                            end
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.SHADOW_HUNTER then   -- 暗影獵手
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.LIGHT_CHARGE then  -- 耀光充能
                    addValue = tonumber(buffValues[1])
                    NewBattleUtil:removeBuff(chaNode, fullBuffId, false)   -- 觸發後移除
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_CRI_DMG]) do -- 低血量額外爆傷
            local skillType, fullSkillId = NewBattleUtil:checkSkill(v, chaNode.skillData)
            local addValue = nil
            if skillType == CONST.SKILL_DATA.PASSIVE then
                local params = SkillManager:calSkillSpecialParams(fullSkillId, { chaNode })
                addValue = params
                if addValue then
                    buffValue = buffValue + addValue
                    addValue = nil
                end
            end
        end
        
        if removeInfernoId then
            self:forceClearBuff(chaNode, removeInfernoId)
        end
    end
    return buffValue, auraValue, markValue  -- 可以小於0
end
-- 攻速加成
function BuffManager:checkAtkSpeedBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.CONCENTRATION then  -- 專注
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.RAPID_B then  -- 急速
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
                    addValue = tonumber(buffValues[4])
                end
                if mainBuffId == CONST.BUFF.STORM then  -- 暴風
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.EMBER then  -- 餘燼
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- 無雙
                    addValue = tonumber(buffValues[3])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.min(buffValue, 1), math.min(auraValue, 1), math.min(markValue, 1)
end
function BuffManager:checkAtkSpeedDeBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.FROSTBITE then -- 凍傷
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.SNAKE_OF_POSION then  -- 蛇毒
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- 勢不可擋(不會降攻速)
                    buffValue, auraValue, markValue = 0, 0, 0
                    break
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.min(buffValue, 1), math.min(auraValue, 1), math.min(markValue, 1)
end
-- 移動速度加成
function BuffManager:checkMoveSpeedBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        local isUnstoppable = false
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- 勢不可擋(不會降跑速)
                    isUnstoppable = true
                    break
                end
            end
        end
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                if mainBuffId == CONST.BUFF.TAILWIND then  -- 順風
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if not isUnstoppable then
                    if mainBuffId == CONST.BUFF.FROSTBITE then -- 凍傷
                        addValue = tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.HEADWIND then -- 凍傷
                        addValue = tonumber(buffValues[2])
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 命中加成
function BuffManager:checkHitBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.KEEN_B then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.ACCURACY_B then  -- 精準
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- 獵魔人II式
                    addValue = tonumber(buffValues[3])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.BLIND then  -- 致盲
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return buffValue, auraValue, markValue  -- 可以小於0
end
-- 閃避加成
function BuffManager:checkDodgeBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.SHADOW_B then  -- 暗影
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- 獵魔人II式
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.SHADOW_HUNTER then   -- 暗影獵手
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.AVOID then   -- 風體
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.TWINE then  -- 纏繞
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return buffValue, auraValue, markValue  -- 可以小於0
end
-- 吸血加成(普攻)
function BuffManager:checkRecoverHpBuffValue(attacker, buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.OUROBOROS then  -- 銜尾蛇
                    addValue = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and tonumber(buffValues[3]) or nil
                end
                if mainBuffId == CONST.BUFF.ASSAULT_B then  -- 突擊
                    addValue = tonumber(buffValues[2])
                end
                if buff[CONST.BUFF.KEEN_B] then  -- 敏銳
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- 獵魔人II式
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.DARK_THUNDER then  -- 暗雷引導
                    addValue = tonumber(buffValues[2])
                    NewBattleUtil:removeBuff(attacker, fullBuffId, false)   -- 觸發後移除
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 造成治療加成
function BuffManager:checkHealBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- 虔誠
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.APOLLO then -- 太陽神
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_HEALTH then  -- 符石
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) * math.max(auraValue, 0) * math.max(markValue, 0)
end
-- 受到治療加成
function BuffManager:checkBeHealBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- 虔誠
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.APOLLO then -- 太陽神
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.ANTI_HEAL then  -- 禁療
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.SNAKE_OF_POSION then  -- 蛇毒
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_BEHEALTH then  -- 符石
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) * math.max(auraValue, 0) * math.max(markValue, 0)
end
-- 額外MP獲得
function BuffManager:checkMpGainValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if aniName == CONST.ANI_ACT.ATTACK then -- 普通攻擊時
                    if mainBuffId == CONST.BUFF.MOONLIGHT then  -- 月光
                        addValue = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and tonumber(buffValues[1]) or nil
                    end
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) + math.max(auraValue, 0) + math.max(markValue, 0)
end
-- MP獲得倍率
function BuffManager:checkMpGainRatio(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.TAILWIND then  -- 順風
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.HEADWIND then  -- 逆風
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.SEAL then  -- 封印
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) * math.max(auraValue, 0) * math.max(markValue, 0)
end
-- 攻擊距離
function BuffManager:checkAtkRangeValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_ATK_RANGE_1 then  -- 符石
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0) + math.max(auraValue, 0) + math.max(markValue, 0)
end
-- 免疫Debuff機率加成
function BuffManager:checkImmunityBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.RESIST_B then  -- 抵抗
                    addValue = tonumber(buffValues[1]) * 1000
                end
                if mainBuffId == CONST.BUFF.BRILLIANCE then  -- 光輝
                    addValue = tonumber(buffValues[1]) * 1000
                end
                if mainBuffId == CONST.BUFF.HOLY_B then  -- 聖潔
                    addValue = tonumber(buffValues[3]) * 1000
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- 檢查復生BUFF
function BuffManager:checkRebirth(target)
    local buff = target.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.REBIRTH then  -- 迴光
                    local hp = math.floor(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[1]) + 0.5)
                    local mp = math.floor(target.battleData[CONST.BATTLE_DATA.MAX_MP] * tonumber(buffValues[2]) + 0.5)
                    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                    CHAR_UTIL:setHp(target, hp, true)
                    CHAR_UTIL:setMp(target, mp)
                    NewBattleUtil:playRemoveSpine(target, fullBuffId)
                    target.buffData[fullBuffId] = nil
                    NewBattleUtil:removeBuffIcon(target, fullBuffId)
                    return true
                end
            end
        end
    end
    return false
end
-- 特殊BUFF獲得處理
function BuffManager:getSpecialBuff(chaNode, target, buff, fullBuffId, oldIsMaxCount)
    if buff and fullBuffId then
        if buffConfig[fullBuffId] then
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            local buffValues = common:split(buffConfig[fullBuffId].values, ",")
            ---------------------------------------------------------------
            if mainBuffId == CONST.BUFF.IMMUNITY or -- 免疫
               mainBuffId == CONST.BUFF.BERSERKER or  -- 狂戰士
               mainBuffId == CONST.BUFF.SHADOW_HUNTER then -- 暗影獵手
                --清空debuff
                self:clearAllDeBuff(target, buff)
            end
            if mainBuffId == CONST.BUFF.POWER then  -- 權能
                --獲得護盾
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                local shield = math.floor(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[3]) + 0.5)
                CHAR_UTIL:addShield(target, target, shield)   --增加護盾
            end
            if mainBuffId == CONST.BUFF.FRENZY then  -- 狂亂
                -- 滿層時進入狂亂狀態
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    --強制切換目標
                    self:setFrenzyTarget(target, self:createFrenzyTarget(target))
                end
            end
            if mainBuffId == CONST.BUFF.TAUNT then -- 嘲諷
                --強制切換目標
                self:setTauntTarget(target, chaNode)
            end
            if mainBuffId == CONST.BUFF.STONE or -- 石化
               mainBuffId == CONST.BUFF.FREEZE or -- 凍結
               mainBuffId == CONST.BUFF.DIZZY then -- 暈眩
                for fullBuffId, buffData in pairs(buff) do
                    if buffConfig[fullBuffId] then
                        local mainBuffId = math.floor(fullBuffId / 100) % 1000
                        ---------------------------------------------------------------
                        if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- 勢不可擋(不會被控場)
                            isUnstoppable = true
                            break
                        end
                    end
                end
                if not isUnstoppable then
                    -- 設定timescale
                    --target.heroNode.heroSpine:setTimeScale(0)
                    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                    CHAR_UTIL:setTimeScale(target, 0)
                end
            end
            if mainBuffId == CONST.BUFF.JEALOUS then -- 妒火
                -- 滿層時造成傷害並移除
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    local attacker = target.buffData[fullBuffId][CONST.BUFF_DATA.CASTER]
                    self:castDotDamage(attacker, target, fullBuffId, false, true)
                    self:forceClearBuff(target, fullBuffId)
                end
            end
            if mainBuffId == CONST.BUFF.STATIC then -- 靜電
                -- 滿層時轉變為導電體
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    -- 檢查攻擊者技能ID
                    for skillType, skillTypeData in pairs(chaNode.skillData) do
                        for skillId, skillIdData in pairs(skillTypeData) do
                            if math.floor(skillId / 10) == tonumber(buffValues[1]) then -- 可把靜電轉變成導電體的技能ID
                                local skillConfig = ConfigManager.getSkillCfg()
                                local skillValues = common:split(skillConfig[skillId].values, ",")
                                local buffId = tonumber(skillValues[2])
                                self:getBuff(target.buffData[fullBuffId][CONST.BUFF_DATA.CASTER], target, buffId, 999000 * 1000, 1)
                            end
                        end
                    end
                    -- 清除靜電
                    self:forceClearBuff(target, fullBuffId)
                end
            end
        end
    end
end
-- 特定事件增加BUFF層數(固定1層)
function BuffManager:addBuffCount(chaNode, buff, eventType)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if eventType == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
                    if mainBuffId == CONST.BUFF.OUROBOROS or  -- 銜尾蛇
                       mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- 魔力溢出
                        -- 滿層後觸發會繼續維持滿層
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                    if mainBuffId == CONST.BUFF.RAGE or   -- 憤怒
                       mainBuffId == CONST.BUFF.MOONLIGHT or  -- 月光
                       mainBuffId == CONST.BUFF.PIERCING_ICE then  -- 寒冰刺骨
                        -- 滿層後觸發效果會清空層數
                        if buffData[CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                            --self:clearBuffCount(chaNode, fullBuffId)
                            chaNode.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] = 0
                        else
                            buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                            NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                        end
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
                    if mainBuffId == CONST.BUFF.PETAL then  -- 開花
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.SKILL then
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- 魔力溢出
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                end
            end
        end
    end
end
-- 特定事件減少BUFF層數
function BuffManager:minusBuffCount(chaNode, eventType)
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if eventType == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
                    if mainBuffId == CONST.BUFF.PUNCTURE then   -- 穿刺
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        end
                    end
                    if mainBuffId == CONST.BUFF.DARK_THUNDER then   -- 暗雷引導
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        end
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.DODGE then
                    if mainBuffId == CONST.BUFF.DODGE then  -- 必閃
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        else
                            -- 播放BUFF SPINE
                            NewBattleUtil:playBuffSpine(chaNode, fullBuffId, chaNode.buffData[fullBuffId])
                        end
                    end
                    if mainBuffId == CONST.BUFF.AVOID then  -- 風體
                        NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                    end
                end
            end
        end
    end
end
-- 特殊buff事件處理
function BuffManager:specialBuffEffect(buff, eventType, chaNode, target, skillId, dmg)
    local triggerBuffList = { }
    if buff then
        if eventType == CONST.ADD_BUFF_COUNT_EVENT.CAST_ATTACK then
            for fullBuffId, buffData in pairs(chaNode.buffData) do
                if buffConfig[fullBuffId] then
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.PARALYSIS then  -- 麻痺
                        local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                        if tonumber(buffValues[1]) * 100 >= math.random(1, 100) then    -- 觸發麻痺
                            BuffManager:getBuff(buffData[CONST.BUFF_DATA.CASTER], chaNode, tonumber(buffValues[2]), tonumber(buffValues[3]) * 1000, 1)

                            triggerBuffList[mainBuffId] = fullBuffId
                        end
                    end
                    if mainBuffId == CONST.BUFF.TOXIN_OF_POSION then  -- 烈毒
                        local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                        buffData[CONST.BUFF_DATA.COUNTER] = buffData[CONST.BUFF_DATA.COUNTER] and buffData[CONST.BUFF_DATA.COUNTER] + 1 or 1
                        if buffData[CONST.BUFF_DATA.COUNTER] >= tonumber(buffValues[1]) then    -- 觸發烈毒
                            -- dot傷害
                            local attacker = buffData[CONST.BUFF_DATA.CASTER]
                            self:castDotDamage(attacker, chaNode, fullBuffId, (not target.otherData[CONST.OTHER_DATA.IS_ENEMY] and NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK))

                            triggerBuffList[mainBuffId] = fullBuffId
                            buffData[CONST.BUFF_DATA.COUNTER] = 0
                        end
                    end
                end
            end
        end
        if eventType == CONST.ADD_BUFF_COUNT_EVENT.CAST_SKILL then
            local fList = NgBattleDataManager_getFriendList(chaNode)
            local eList = NgBattleDataManager_getEnemyList(chaNode)
            for k, v in pairs(fList) do
                for fullBuffId, buffData in pairs(v.buffData) do
                    -- 友方有風怒Buff
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.WINDFURY then  -- 風怒
                        local triggerId = { 600201, 600202 }    -- 引爆風怒的技能ID
                        for i = 1, #triggerId do
                            if skillId == triggerId[i] then
                                local resultTable = self:runBuff(fullBuffId, v, target, fList, eList, 1, allPassiveTable)
                                self:castBuffDamage(v, resultTable, fullBuffId)
                                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                                CHAR_UTIL:forceClearTargetBuff(v, fList, eList, CONST.BUFF.WINDFURY, true) 
                                triggerBuffList[mainBuffId] = fullBuffId
                                break 
                            end
                        end
                        break
                    end
                end
            end
            for k, v in pairs(eList) do
                for fullBuffId, buffData in pairs(v.buffData) do
                    -- 敵方有風怒Buff
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.WINDFURY then  -- 風怒
                        if chaNode and chaNode.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.FIRE and   -- 火屬性
                           chaNode.skillData[CONST.SKILL_DATA.SKILL][skillId] then    -- 大招
                            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                            CHAR_UTIL:forceClearTargetBuff(target, fList, eList, CONST.BUFF.WINDFURY, true)  
                            triggerBuffList[mainBuffId] = fullBuffId
                        end
                        break
                    end
                end
            end
        end
        if eventType == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
            for fullBuffId, buffData in pairs(target.buffData) do
                if buffConfig[fullBuffId] then
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.CONDUCTOR then  -- 導電體
                        local skillConfig = ConfigManager.getSkillCfg()
                        if skillId and skillConfig[skillId] and skillConfig[skillId].actionName == CONST.ANI_ACT.SKILL0 then -- 大招時
                            local fList = NgBattleDataManager_getFriendList(target)
                            local aliveIdTable = NewBattleUtil:initAliveTable(fList)
                            for i = 1, #aliveIdTable do
                                local friendNode = fList[aliveIdTable[i]]
                                if friendNode.idx ~= target.idx then   -- 對自己以外的導電體傳遞傷害
                                    self:castDotDamage(friendNode, friendNode, fullBuffId, false, true, dmg)
                                end
                            end
                            buffData[CONST.BUFF_DATA.TIME] = 0  -- 時間設為0 > 下一tick再清除
                        end
                    end
                    if mainBuffId == CONST.BUFF.THORNS then  -- 荊棘
                        if chaNode.idx ~= target.idx then   -- 對攻擊者反射傷害
                            self:castDotDamage(target, chaNode, fullBuffId, false, true, dmg)
                        end
                    end
                end
            end
        end
    end
    return triggerBuffList
end
-- 強制移除目標buff
function BuffManager:forceClearBuff(chaNode, buffId)
    if chaNode.buffData and chaNode.buffData[buffId] then
        NewBattleUtil:removeBuff(chaNode, buffId, false)
    end
end
-- 清空目標buff層數
function BuffManager:clearBuffCount(chaNode, buffId)
    if chaNode.buffData and chaNode.buffData[buffId] then
        chaNode.buffData[buffId][CONST.BUFF_DATA.COUNT] = 0
        --chaNode.buffData[buffId] = nil
        NewBattleUtil:removeBuffIcon(chaNode, buffId)
        NewBattleUtil:removeBuffSpine(chaNode, buffId, false)
    end
end
-- 清空目標buff計時器
function BuffManager:clearBuffTimer(chaNode, buff, event)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if event == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
                    if mainBuffId == CONST.BUFF.OUROBOROS then  -- 銜尾蛇
                        buffData[CONST.BUFF_DATA.TIMER] = 0
                    end
                    if mainBuffId == CONST.BUFF.FRENZY then  -- 狂亂
                        if BuffManager:isInFrenzy(buff) then
                            --解除狂亂 強制切換目標
                            buffData[CONST.BUFF_DATA.TIME] = 0
                        end
                    end
                elseif event == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
                    if mainBuffId == CONST.BUFF.PETAL or  -- 開花
                       mainBuffId == CONST.BUFF.POWER then  -- 權能
                        buffData[CONST.BUFF_DATA.TIMER] = 0
                    end
                elseif event == CONST.ADD_BUFF_COUNT_EVENT.CAST_ATTACK then

                elseif event == CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR then
                    if buff[CONST.BUFF.POWER] then  -- 權能
                        buffData[CONST.BUFF_DATA.TIMER2] = 0
                    end
                end
            end
        end
    end
end
-- 是否嘲諷狀態(只可攻擊特定目標)
function BuffManager:isInTaunt(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.TAUNT then
                return true
            end
        end
    end
    return false
end
-- 是否狂亂狀態(只可普攻)
function BuffManager:isInFrenzy(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.FRENZY then
                if buffData[CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    return true
                end
            end
        end
    end
    return false
end
-- 是否沉默狀態(不可施放技能)
function BuffManager:isInSilene(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.SILENCE then
                return true
            end
        end
    end
    return false
end
-- 是否定身狀態(不可行動)
function BuffManager:isInCrowdControl(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STONE or -- 石化
               mainBuffId == CONST.BUFF.FREEZE or -- 凍結
               mainBuffId == CONST.BUFF.DIZZY then -- 暈眩
                return true
            end
        end
    end
    return false
end
-- 是否毅力狀態(回傳鎖血%數, 觸發的BuffId)
function BuffManager:isInUnDead(buff)
    local lockHp = 0
    local triggerBuffId = nil
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.UNDEAD then -- 不屈
                local value = tonumber(buffConfig[fullBuffId].values)
                if value > lockHp then
                    lockHp = value
                    triggerBuffId = fullBuffId
                end
                return value, triggerBuffId
            end
        end
    end
    return lockHp, triggerBuffId
end
-- 觸發毅力狀態
function BuffManager:castInUnDead(chaNode, buff, buffId)
    if buff and buff[buffId] then
        local mainBuffId = math.floor(buffId / 100) % 1000
        if mainBuffId == CONST.BUFF.UNDEAD then -- 不屈
            if buff[buffId][CONST.BUFF_DATA.COUNT] > 0 then  -- 還有使用次數
                buff[buffId][CONST.BUFF_DATA.COUNT] = buff[buffId][CONST.BUFF_DATA.COUNT] - 1
                if buff[buffId][CONST.BUFF_DATA.COUNT] <= 0 then
                    NewBattleUtil:removeBuff(chaNode, buffId, false)
                end
            end
        end
    end
end
-- 是否惡意狀態(不會獲得Buff)
function BuffManager:isInMalicious(buff)
    if buff then -- 惡意
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.MALICIOUS then -- 惡意
                return true
            end
        end
    end
    return false
end
-- 是否免疫狀態(不會獲得Debuff)
function BuffManager:isInImmunity(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.IMMUNITY or -- 免疫
               mainBuffId == CONST.BUFF.BERSERKER or  -- 狂戰士
               mainBuffId == CONST.BUFF.SHADOW_HUNTER then -- 暗影獵手
                return true
            end
        end
    end
    return false
end
-- 是否導電體狀態(不會獲得靜電)
function BuffManager:isInConductor(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.CONDUCTOR then  -- 導電體
                return true
            end
        end
    end
    return false
end
-- 是否鬼魅(不會受傷(視同MISS不跳數字) 不包括DOT)
function BuffManager:isInGhost(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.GHOST and not buffData[CONST.BUFF_DATA.USING] then  -- 鬼魅
                buffData[CONST.BUFF_DATA.USING] = true
                return true
            end
        end
    end
    return false
end
-- 檢查鬼魅是否觸發中 如觸發中移除buff
function BuffManager:closeGhost(chaNode, buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.GHOST and buffData[CONST.BUFF_DATA.USING] then  -- 鬼魅
                NewBattleUtil:removeBuff(chaNode, fullBuffId, true)
                return true
            end
        end
    end
    return false
end
-- 是否必閃(視同MISS 不包括DOT)
function BuffManager:isInDodge(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.DODGE then  -- 必閃
                return true
            end
        end
    end
    return false
end
-- 是否隱身
function BuffManager:isInStealth(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STEALTH then  -- 隱身
                return true
            end
        end
    end
    return false
end
-- 是否無敵
function BuffManager:isInInvincible(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.INVINCIBLE then  -- 無敵
                return true
            end
        end
    end
    return false
end
-- 是否狂戰士
function BuffManager:isInBerserker(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
                return true
            end
        end
    end
    return false
end
-- 強制轉換屬性(可能會有多屬性)
function BuffManager:forceChangeElement(buff)
    local newElement = { }
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STONE then -- 石化
                table.insert(newElement, CONST.ELEMENT.NONE)
            end
        end
    end
    return newElement
end
-- 隨機驅散特定數量BUFF
function BuffManager:clearRandomBuffByNum(target, buff, num)
    if buff then
        local dispelBuffTable = { }
        for k, v in pairs(buff) do  -- 記錄所有可驅散的buff
            local cfg = buffConfig[k]
            if cfg.gain == 1 and cfg.dispel == 1 then   --buff&可驅散
                table.insert(dispelBuffTable, k)
            end
        end
        local shuffleTable = GameUtil:shuffleTable(dispelBuffTable)
        for i = 1, num do
            local k = shuffleTable[i]
            if not k then
                break
            end
            local cfg = buffConfig[k]
            NewBattleUtil:removeBuff(target, k, false)
            if cfg.buffType == CONST.BUFF_TYPE.AURA then
                -- 清除光環產生的buff
                local fList = NgBattleDataManager_getFriendList(target)
                local eList = NgBattleDataManager_getEnemyList(target)
                self:clearAuraBuff(k, fList, eList)
            end
            -- 驅散後觸發被動技能
            local mainBuffId = math.floor(k / 100) % 1000
            if mainBuffId == CONST.BUFF.INFERNO then  -- 業火
                local list = NgBattleDataManager_getFriendList(target)
                local aliveIdTable = NewBattleUtil:initAliveTable(list)
                for k2, v2 in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR]) do -- 友方Buff移除時觸發被動
                    for i = 1, #aliveIdTable do
                        local resultTable = { }
                        local allPassiveTable = { }
                        local actionResultTable = { }
                        local allTargetTable = { }
                        if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v2, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR, { target }) then
                            local LOG_UTIL = require("Battle.NgBattleLogUtil")
                            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                            LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                            CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v2 * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                        end
                    end
                end
            end
        end
    end
end
-- 驅散全部BUFF
function BuffManager:clearAllBuff(target, buff)
    if buff then
        for k, v in pairs(buff) do
            local cfg = buffConfig[k]
            if cfg.gain == 1 and cfg.dispel == 1 then   --buff&可驅散
                NewBattleUtil:removeBuff(target, k, false)
                if cfg.buffType == CONST.BUFF_TYPE.AURA then
                    -- 清除光環產生的buff
                    local fList = NgBattleDataManager_getFriendList(target)
                    local eList = NgBattleDataManager_getEnemyList(target)
                    self:clearAuraBuff(k, fList, eList)
                end
                -- 驅散後觸發被動技能
                local mainBuffId = math.floor(k / 100) % 1000
                if mainBuffId == CONST.BUFF.INFERNO then  -- 業火
                    local list = NgBattleDataManager_getFriendList(target)
                    local aliveIdTable = NewBattleUtil:initAliveTable(list)
                    for k2, v2 in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR]) do -- 友方Buff移除時觸發被動
                        for i = 1, #aliveIdTable do
                            local resultTable = { }
                            local allPassiveTable = { }
                            local actionResultTable = { }
                            local allTargetTable = { }
                            if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v2, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR, { target }) then
                                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                                LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                                CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v2 * 10, allPassiveTable)   -- 全部傷害/治療/buff...處理
                            end
                        end
                    end
                end
            end
        end
    end
end
-- 驅散全部DEBUFF
function BuffManager:clearAllDeBuff(target, buff)
    if buff then
        for k, v in pairs(buff) do
            local cfg = buffConfig[k]
            local mainBuffId = math.floor(k / 100) % 1000
            if cfg.gain == 0 and cfg.dispel == 1 then   -- debuff&可驅散
                NewBattleUtil:removeBuff(target, k, false)
            end
        end
    end
end
-- 光環解除(清除光環賦予的buff/debuff)
function BuffManager:clearAuraBuff(buffId, fList, eList)
    local buffData = buffConfig[buffId]
    if buffData then
        local checkId = tonumber(buffData.values)
        for k, v in pairs(fList) do
            if v.buffData[buffId] then
                -- 還有角色有該光環
                return
            end
        end
        for k, v in pairs(fList) do
            if v.buffData[checkId] then
                -- 取消光環的buff
                NewBattleUtil:removeBuff(v, checkId, false)
            end
        end
    end
end
-- (角色死亡時)Buff/Debuff轉移
function BuffManager:transferBuff(node, fList, eList)
    local buff = node.buffData
    local fList = NgBattleDataManager_getFriendList(node)
    local aliveIdTable = NewBattleUtil:initAliveTable(fList)
    local transNode = nil
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.TACTICAL_VISOR or -- 戰術鎖定
               mainBuffId == CONST.BUFF.DEPENDENTS then -- 眷屬
                if #aliveIdTable > 0 then
                    transNode = fList[math.random(1, #aliveIdTable)]  -- 隨機選擇idx
                end
            end
            --if mainBuffId == CONST.BUFF.OFFERINGS then -- 祭品
            --    local SKILL_UTIL = require("Battle.NewSkill.SkillUtil")
            --    local targetTable = SKILL_UTIL:getLowestDefEnemy(node.buffData[fullBuffId][CONST.BUFF_DATA.CASTER], fList, aliveIdTable, CONST.SKILL_TARGET_CONDITION.LOWEST_HP)  -- 選擇防禦最低idx
            --    if #targetTable > 0 then
            --        transNode = targetTable[1]
            --    end
            --end
            if transNode then
                transNode.buffData = transNode.buffData or { }
                transNode.buffData[fullBuffId] = { }
                for k, v in pairs(node.buffData[fullBuffId]) do  
                    transNode.buffData[fullBuffId][k] = v  -- 轉移buff資料
                end
                -- 顯示ICON
                NewBattleUtil:addBuffIcon(transNode, fullBuffId)
                NewBattleUtil:sortBuffIcon(transNode)
                -- 播放BUFF SPINE
                NewBattleUtil:playBuffSpine(transNode, fullBuffId, transNode.buffData[fullBuffId])
                transNode = nil
            end
        end
    end
end
-- 處理hot治療
function BuffManager:castHotHealth(node, buffId, isSkipPre, isSkipAdd)
    local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
    local mainBuffId = math.floor(buffId / 100) % 1000
    if node.buffData[buffId] then
        local buffValues = common:split(buffConfig[buffId].values, ",")
        --施法者攻擊力
        local atk = NewBattleUtil:calAtk(node.buffData[buffId][CONST.BUFF_DATA.CASTER], nil)
        --施法者造成治療buff
        local buffValue = self:checkHealBuffValue(node.buffData[buffId][CONST.BUFF_DATA.CASTER].buffData)
        --目標受到治療buff
        local buffValue2 = self:checkBeHealBuffValue(node.buffData)
        if mainBuffId == CONST.BUFF.RECOVERY then  -- 再生
            -- 施法者最大HP
            local maxHp = node.buffData[buffId][CONST.BUFF_DATA.CASTER].battleData[CONST.BATTLE_DATA.MAX_HP]
            --基礎治療
            local dmg = maxHp * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.WIND_WHISPER then  -- 風語
            local dmg = node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.HOLY_B then  -- 聖潔
            local dmg = node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
    end
end
-- 處理buff治療
function BuffManager:castBuffHealth(chaNode, target, buffId)
    local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
    local mainBuffId = math.floor(buffId / 100) % 1000

end
-- 處理dot傷害
function BuffManager:castDotDamage(chaNode, target, buffId, isSkipPre, isSkipAdd, baseDmg)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if target and target.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.EROSION then  -- 侵蝕
            -- 增傷buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, false,  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 最大血量 * %數 * (1 - 魔法減傷)
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * (1 - NewBattleUtil:calReduction2(nil, target, false)))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.POSITION then  -- 中毒
            -- 增傷buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, true,  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 最大血量 * %數 * (1 - 物理減傷)
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * (1 - NewBattleUtil:calReduction2(nil, target, true)))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BLEED then  -- 出血
            -- 增傷buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 當前血量 * %數
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- 寄生種子
            local attacker = chaNode
            --攻擊力
            local atk = NewBattleUtil:calAtk(attacker, target)
            --屬性加成
            local elementRate = NewBattleUtil:calElementRate(attacker, target)
            --基礎傷害
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(attacker, target, 
                                                                                     attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                     nil)
            --水屬性時額外增傷
            local addRate = (target.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER) and 1 + target.battleData[CONST.BATTLE_DATA.MP] / 100 or 1
            local dmg = math.abs(atk * elementRate * tonumber(buffValues[2]) * buffValue * auraValue * markValue * addRate)
            NgBattleCharacterBase:beDot(chaNode, target, math.floor(dmg + 0.5), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.EXPLODE_SEED then  -- 爆炸種子
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable, { target })
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
        if mainBuffId == CONST.BUFF.JEALOUS then  -- 妒火
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable, { target })
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
        if mainBuffId == CONST.BUFF.OFFERINGS or   -- 祭品
           mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then  -- 血祭
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 最大血量 * %數
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BURN then  -- 燃燒
            local attacker = chaNode
            --攻擊力
            local atk = NewBattleUtil:calAtk(attacker, target)
            --基礎傷害
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(attacker, target, 
                                                                                     attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                     nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            --層數
            local count = target.buffData[buffId][CONST.BUFF_DATA.COUNT]
            local dmg = math.min(maxDmg, math.abs(atk * tonumber(buffValues[2]) * count * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, math.floor(dmg + 0.5), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.TOXIN_OF_POSION then  -- 烈毒
            -- 增傷buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 最大血量 * %數
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.SOUL_OF_POSION then  -- 猛毒
            -- 增傷buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- 最大血量 * %數
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
            -- 直接死亡
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.HP] + math.abs(target.battleData[CONST.BATTLE_DATA.SHIELD]))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.THORNS then  -- 荊棘
            local dmg = baseDmg * tonumber(buffValues[1])
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            dmg = math.min(maxDmg, dmg)
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
    end
    -- 檢查施放者身上Buff
    if chaNode and chaNode.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.ELECTROMAGNETIC_FIELD then  -- 電氣磁場
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable)
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- 全部傷害/治療/buff...處理
            end
        end
        if mainBuffId == CONST.BUFF.THORNS then  -- 荊棘
            local dmg = NewBattleUtil:calRoundValue(baseDmg * tonumber(buffValues[1]), 1)
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
    end
    -- 導電體需獨立檢查BuffId
    if mainBuffId == CONST.BUFF.CONDUCTOR then  -- 隊友的導電體
        for fullBuffId, buffData in pairs(target.buffData) do -- 檢查自己的Buff
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.CONDUCTOR then  -- 自己的導電體
                local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
                local buffValues = common:split(buffConfig[buffId].values, ",")
                -- 傳遞傷害
                local buffDmg = math.floor(baseDmg * tonumber(buffValues[1]) + 0.5)
                NgBattleCharacterBase:beDot(chaNode, target, math.abs(buffDmg), buffId, isSkipPre, isSkipAdd)
                buffData[CONST.BUFF_DATA.TIME] = 0  -- 時間設為0 > 下一tick再清除
            end
        end
    end
end
-- 處理吸取魔力
function BuffManager:castDrainMana(node, buffId, isSkipPre, isSkipAdd)
    if node.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local mainBuffId = math.floor(buffId / 100) % 1000
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- 寄生種子
            local mana = tonumber(buffValues[1])
            if node.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER then    --水屬性時吸取目標全部魔力
                mana = node.battleData[CONST.BATTLE_DATA.MP]
            end
            NgBattleCharacterBase:beDrainMana(node, node, mana, false, buffId, { }, { })
        end
    end
end
-- 處理Buff結束時效果(持續時間結束才會發動的效果)
function BuffManager:castEndBuffEffect(node, buffId, isSkipPre, isSkipAdd)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if mainBuffId == CONST.BUFF.LEECH_SEED then  -- 寄生種子
        -- 結束時吸魔+爆炸傷害
        local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
        self:castDotDamage(attacker, node, buffId, false, true)
        self:castDrainMana(node, buffId, true, false)
    end
    if mainBuffId == CONST.BUFF.EXPLODE_SEED then  -- 寄生種子
        -- 結束時吸魔+爆炸傷害
        local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
        self:castDotDamage(attacker, node, buffId, false, true)
        self:castDrainMana(node, buffId, true, false)
    end
    if mainBuffId == CONST.BUFF.BERSERKER then  -- 狂戰士
        -- 結束時死亡
        self:castDotDamage(attacker, node, buffId, false, true)
    end
end
-- 檢查Buff計時器(觸發hot, dot, 消層數...)
function BuffManager:checkBuffTimer(node, buffId)
    if node.buffData[buffId] then
        local mainBuffId = math.floor(buffId / 100) % 1000
        local valueArr = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.POWER then  -- 權能
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local beAtkTime = tonumber(valueArr[2]) * 1000   -- 未受到攻擊秒數
            local recoverTime = tonumber(valueArr[4]) * 1000   -- 回血頻率
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > beAtkTime then
                -- timer超過beAtkTime後 回復護盾
                if node.buffData[buffId][CONST.BUFF_DATA.TIMER] >= beAtkTime + recoverTime then
                    local maxRecoverShield = math.floor(node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(valueArr[3]) + 0.5)  -- 護盾回復上限
                    if maxRecoverShield < node.battleData[CONST.BATTLE_DATA.SHIELD] then    -- 未回復至上限
                        local recoverShield = math.floor(maxRecoverShield * tonumber(valueArr[5]) + 0.5)   -- 回復量
                        local trueRecoverShield = math.min(maxRecoverShield - node.battleData[CONST.BATTLE_DATA.SHIELD], recoverShield)
                        if trueRecoverShield > 0 then   -- 可以回復護盾
                            LOG_UTIL:setPreLog(node)
                            CHAR_UTIL:addShield(node, node, recoverShield)   --回復護盾
                            LOG_UTIL:addBuffLog(node, buffId)
                        end
                    end
                    -- 不管有沒有回復 計時器都要計算
                    node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - recoverTime, 0)
                end
            end
            if node.battleData[CONST.BATTLE_DATA.SHIELD] <= 0 then  -- 沒有護盾
                local rebirthTime = valueArr[1] * 1000   -- 護盾重生秒數
                if node.buffData[buffId][CONST.BUFF_DATA.TIMER2] > rebirthTime then  -- timer2 > 護盾重生秒數 護盾重生
                    local rebirthShield = math.floor(node.battleData[CONST.BATTLE_DATA.MAX_HP] * valueArr[3] + 0.5)
                    LOG_UTIL:setPreLog(node)
                    CHAR_UTIL:setShield(node, rebirthShield)   --回復護盾
                    LOG_UTIL:addBuffLog(node, buffId)
                end
            else
                node.buffData[buffId][CONST.BUFF_DATA.TIMER2] = 0   -- 還有護盾不計時
            end
        end
        if mainBuffId == CONST.BUFF.PETAL or  -- 開花
           mainBuffId == CONST.BUFF.OUROBOROS then  -- 銜尾蛇
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local time = tonumber(valueArr[1]) * 1000
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- 重置層數
                LOG_UTIL:setPreLog(node)
                self:clearBuffCount(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = 0
                LOG_UTIL:addBuffLog(node, buffId)
            end
        end
        if mainBuffId == CONST.BUFF.EROSION or  -- 侵蝕
           mainBuffId == CONST.BUFF.POSITION or  -- 中毒
           mainBuffId == CONST.BUFF.BLEED or  -- 出血
           mainBuffId == CONST.BUFF.BURN or  -- 燃燒
           mainBuffId == CONST.BUFF.SOUL_OF_POSION or  -- 猛毒
           mainBuffId == CONST.BUFF.OFFERINGS then  -- 祭品
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50毫秒避免作用次數誤差
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot傷害
                local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
                self:castDotDamage(attacker, node, buffId, (not node.otherData[CONST.OTHER_DATA.IS_ENEMY] and NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK))
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)  
            end
        end
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- 寄生種子
            if node.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER then    --水屬性時立即引爆
                node.buffData[buffId][CONST.BUFF_DATA.TIME] = 0
            end
        end
        if mainBuffId == CONST.BUFF.RECOVERY or -- 再生
           mainBuffId == CONST.BUFF.WIND_WHISPER or -- 風語
           mainBuffId == CONST.BUFF.HOLY_B then -- 聖潔
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50毫秒避免作用次數誤差
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- hot治療
                self:castHotHealth(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)      
            end
        end
        if mainBuffId == CONST.BUFF.ELECTROMAGNETIC_FIELD  then -- 電氣磁場
            local time = tonumber(valueArr[3]) * 1000 - 50   -- -50毫秒避免作用次數誤差
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot傷害
                local SKILL_UTIL = require("Battle.NewSkill.SkillUtil")
                self:castDotDamage(node, nil, buffId, false)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)     
            end
        end
        if mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then -- 血祭
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50毫秒避免作用次數誤差
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot傷害
                local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
                self:castDotDamage(attacker, node, buffId)
                -- hot治療
                self:castHotHealth(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)      
            end
        end
        if mainBuffId == CONST.BUFF.ICE_WALL then  -- 冰牆
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local time = tonumber(valueArr[1]) * 1000
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- 減少層數
                node.buffData[buffId][CONST.BUFF_DATA.COUNT] = math.max(node.buffData[buffId][CONST.BUFF_DATA.COUNT] - 1, 0)
                if node.buffData[buffId][CONST.BUFF_DATA.COUNT] <= 0 then
                    NewBattleUtil:removeBuff(node, buffId, false)
                end
            end
        end
    end
end
-- 產生狂亂目標
function BuffManager:createFrenzyTarget(chaNode)
    local fList = NgBattleDataManager_getFriendList(chaNode)
    local aliveTable = NewBattleUtil:initAliveTable(fList)
    for i = 1, #aliveTable do
        if fList[aliveTable[i]] == chaNode then
            table.remove(aliveTable, i)
        end
    end
    if #aliveTable > 0 then
        local randIdx = math.random(1, #aliveTable)
        return fList[aliveTable[randIdx]]
    else
        return chaNode.target
    end
end
-- 設定狂亂目標
function BuffManager:setFrenzyTarget(chaNode, target)
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    if not target then	-- 清除狂亂目標
        chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] = nil
        if self:isInTaunt(chaNode.buffData) then    -- 有嘲諷狀態
            chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET]
        else
    	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = nil
        end
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    elseif target then   -- 切換目標
        if not chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] then  -- 沒有原始目標才設定 避免被其他目標蓋過
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = chaNode.target
        end
        chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] = target
	    chaNode.target = target
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    end
end
-- 設定嘲諷目標
function BuffManager:setTauntTarget(chaNode, target)
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    if not target and chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] then	-- 清除嘲諷目標
        chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] = nil
        if self:isInFrenzy(chaNode.buffData) then    -- 有狂亂狀態
            chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET]
        else
    	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = nil
        end
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    elseif target then
        if not chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] then  -- 沒有原始目標才設定 避免被其他目標蓋過
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = chaNode.target
        end
        chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] = target  -- 設定嘲諷目標
        if not self:isInFrenzy(chaNode.buffData) then   -- 不在狂亂中才切換目標
	        chaNode.target = target
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        end
    end
end
-- 清除嘲諷目標
function BuffManager:clearTauntTarget(chaNode)
    self:setTauntTarget(chaNode, nil)
end
-- 獲得普攻額外目標
function BuffManager:getExternNormalAtkTarget(chaNode, target)
    local externTar = { }
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.PUNCTURE then   -- 穿刺
                local externMaxNum = 1
                local enemyList = NgBattleDataManager_getEnemyList(chaNode)
                aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
                for i = 1, #aliveIdTable do
                    if enemyList[aliveIdTable[i]] ~= target then
                        table.insert(externTar, enemyList[aliveIdTable[i]])
                    end
                    if #externTar >= externMaxNum then
                        break
                    end
                end
            end
        end
    end
    return externTar
end
-- 獲得普攻額外Buff
function BuffManager:getExternNormalAtkBuff(chaNode, target)
    local externData = { }
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.PUNCTURE then   -- 穿刺
                local data = { }
                local buffValue = common:split(buffConfig[fullBuffId].values, ",")
                if tonumber(buffValue[2]) then
                    data.buffId = tonumber(buffValue[2])
                    data.buffCount = 1
                    data.buffTime = tonumber(buffValue[3]) * 1000
                    data.buffTar = target
                    table.insert(externData, data)
                end
            end
            if mainBuffId == CONST.BUFF.PIERCING_ICE then   -- 寒冰刺骨
                if buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count then
                    local data = { }
                    local buffValue = common:split(buffConfig[fullBuffId].values, ",")
                    if tonumber(buffValue[2]) then
                        data.buffId = tonumber(buffValue[2])
                        data.buffCount = tonumber(buffValue[4])
                        data.buffTime = tonumber(buffValue[3]) * 1000
                        data.buffTar = target
                        table.insert(externData, data)
                    end
                end
            end
        end
    end
    return externData
end

function BuffManager:addBuffValue(buffId, addValue, buffValue, auraValue, markValue)
    if buffConfig[buffId].buffType == CONST.BUFF_TYPE.NORMAL_BUFF then
        buffValue = buffValue + addValue
    elseif buffConfig[buffId].buffType == CONST.BUFF_TYPE.AURA_BUFF then
        auraValue = auraValue + addValue
    elseif buffConfig[buffId].buffType == CONST.BUFF_TYPE.MARK then
        markValue = markValue + addValue
    else
        buffValue = buffValue + addValue
    end
    return buffValue, auraValue, markValue
end

-- 
function BuffManager:runBuff(buffId, attacker, target, fList, eList, hitNum, allPassiveTable)
    if not buffId then
        return { }
    end
    if not NodeHelper:isFileExist("lua/Battle/NewSkill/Buff_" .. buffId .. ".lua") then
        local resultTable = { }
        for i = 1, hitNum do
            table.insert(resultTable, {
                [CONST.LogDataType.DMG] = { 0 },
                [CONST.LogDataType.DMG_TAR] = { target },
                [CONST.LogDataType.DMG_CRI] = { false },
                [CONST.LogDataType.DMG_WEAK] = { 0 },
            })
        end
        return resultTable
    end
    local scripe = require("Battle.NewSkill.Buff_" .. buffId)
    return scripe:runBuff(attacker, target, fList, eList, allPassiveTable)
end

return BuffManager