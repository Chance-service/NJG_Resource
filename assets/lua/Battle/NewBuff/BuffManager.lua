BuffManager = BuffManager or { }
local buffConfig = ConfigManager:getNewBuffCfg()
local CONST = require("Battle.NewBattleConst")
-------------------------------------------------------
--��oBUFF
function BuffManager:getBuff(chaNode, target, buffId, buffTime, buffCount)
    if self:isInMalicious(target.buffData) then   --�c�N���A ���i�WBUFF
        if buffConfig[buffId].gain == 1 then
            return false
        end
    end
    if self:isInImmunity(target.buffData) then   --�K�̪��A ���i�WDEBUFF(���i�X��������K��)
        if buffConfig[buffId].gain == 0 and buffConfig[buffId].dispel == 1 then
            return false
        end
    end
    if self:isInConductor(target.buffData)then   --�ɹq�骬�A ���i�W�R�q
        local baseBuffId = math.floor(buffId / 100) % 1000
        if baseBuffId == CONST.BUFF.STATIC then
            return false
        end
    end
    if self:isInFrenzy(target.buffData) then   --�g�ê��A  ���i�W�g��
        local baseBuffId = math.floor(buffId / 100) % 1000
        if baseBuffId == CONST.BUFF.FRENZY then
            return false
        end
    end
    if buffConfig[buffId].gain == 0 and buffConfig[buffId].dispel == 1 then -- ����K���ݩ�
        if NewBattleUtil:isTriggerDebuffImmunity(target, chaNode) then
            return false
        end
    end
    -- �ˬd�Q�ʧޯ�K�̯S�wBuff
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.IMMUNITY_BUFF]) do -- �K�̯S�wBuff
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
    if target.buffData[buffId] then   --buff�w�s�b
        if target.buffData[buffId][CONST.BUFF_DATA.TIME] < buffTime or     --�Ѿl�ɶ�����
           buffId == CONST.BUFF.TAUNT then --�J�رj���»\�s
            --��s�ɶ�
            target.buffData[buffId][CONST.BUFF_DATA.TIME] = buffTime
            target.buffData[buffId][CONST.BUFF_DATA.UPDATE_TIME] = NgBattleDataManager.battleTime
        end
        --��s�h��
        local oldIsMaxCount = target.buffData[buffId][CONST.BUFF_DATA.COUNT] >= buffConfig[buffId].max_count
        local newCount = math.min(target.buffData[buffId][CONST.BUFF_DATA.COUNT] + buffCount, buffConfig[buffId].max_count)
        target.buffData[buffId][CONST.BUFF_DATA.COUNT] = newCount
        --�]�w�I���
        target.buffData[buffId][CONST.BUFF_DATA.CASTER] = chaNode
        -- ����BUFF SPINE
        NewBattleUtil:playBuffSpine(target, buffId, target.buffData[buffId])
        -- �S�wbuff��o�B�z
        self:getSpecialBuff(chaNode, target, target.buffData, buffId, oldIsMaxCount)
    else    --buff���s�b
        local highLevelBuff = false
        local lowLevelBuffId = nil
        --�ˬd�O�_�s�b��/�C��buff
        for fullBuffId, buffData in pairs(target.buffData) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if buffConfig[fullBuffId].group == buffConfig[buffId].group then
                if buffConfig[fullBuffId].priority > buffConfig[buffId].priority then    -- �w�g������buff
                    highLevelBuff = true
                elseif buffConfig[fullBuffId].priority <= buffConfig[buffId].priority then   -- �w�g���C��/�ۦP����buff
                    lowLevelBuffId = fullBuffId
                end
            end
        end
        if not highLevelBuff then   --���s�b����buff -> �s�W��buff
            if not target.buffData[buffId] then
                table.insert(target.buffData, buffId, { })
            end
            local newCount = math.min(buffCount, buffConfig[buffId].max_count)
            target.buffData[buffId][CONST.BUFF_DATA.TIME] = buffTime
            target.buffData[buffId][CONST.BUFF_DATA.COUNT] = newCount
            target.buffData[buffId][CONST.BUFF_DATA.TIMER] = 0
            target.buffData[buffId][CONST.BUFF_DATA.TIMER2] = 0
            target.buffData[buffId][CONST.BUFF_DATA.UPDATE_TIME] = NgBattleDataManager.battleTime
            -- �]�w�I���
            target.buffData[buffId][CONST.BUFF_DATA.CASTER] = chaNode
            -- ���C��buff > �����C��buff
            if lowLevelBuffId then
                NewBattleUtil:removeBuff(target, lowLevelBuffId, true)
            end
            -- ���ICON
            NewBattleUtil:addBuffIcon(target, buffId)
            -- ����BUFF SPINE
            NewBattleUtil:playBuffSpine(target, buffId, target.buffData[buffId])
            -- �S�wbuff��o�B�z
            self:getSpecialBuff(chaNode, target, target.buffData, buffId, oldIsMaxCount)
        end
    end
    if buffConfig[buffId].buffType ~= 4 then
        local LOG_UTIL = require("Battle.NgBattleLogUtil")
        LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.GAIN_BUFF, chaNode, target, buffId, false, false, 0)
    end
    if buffConfig[buffId].gain == 0 then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.GET_DEBUFF]) do -- ��oDeBuff
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.GET_DEBUFF, { }) then
                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                LOG_UTIL:setPreLog(target, resultTable)
                CHAR_UTIL:calculateAllTable(target, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
    end
    if buffConfig[buffId].gain == 1 then
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.GET_BUFF]) do -- ��oBuff
            local resultTable = { }
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            if NewBattleUtil:castPassiveSkill(target, v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.GET_BUFF, { }) then
                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                LOG_UTIL:setPreLog(target, resultTable)
                CHAR_UTIL:calculateAllTable(target, resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
    end

    return true
end

-- �����O�[��(%��)
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
                if mainBuffId == CONST.BUFF.PETAL then  -- �}��
                    addValue = tonumber(buffValues[3]) and tonumber(buffValues[3]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.FORCE then  -- �j��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.PRECISION then  -- ��T
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.FURY then  -- ���
                    local hpPer = chaNode.battleData[CONST.BATTLE_DATA.HP] / chaNode.battleData[CONST.BATTLE_DATA.MAX_HP]   -- ��ehp���
                    local loseHpPer = 1 - hpPer
                    addValue = math.floor(loseHpPer / tonumber(buffValues[1])) * tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- �B��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.GHOST then  -- ���y
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- �L��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_I then  -- �y�]�HI��
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.DEPENDENTS then -- ����
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.FEAR then -- ����
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if isPhy then
                    if mainBuffId == CONST.BUFF.OUROBOROS then  -- �Χ��D
                        addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.BRUTAL then    -- �Z�i
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.ASSAULT_B then  -- ����
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.BOOST_B then  -- ���R
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.INVINCIBLE then  -- �L��
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.WEAK then -- �I�z
                        addValue = tonumber(buffValues[1])
                    end
                else
                    if mainBuffId == CONST.BUFF.ENLIGHTENMENT then  -- �һX
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- �]�O���X
                        addValue = tonumber(buffValues[1]) and tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.ARCANE_B then  -- ���N
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.MAGIC_LOCK then    -- �]�O����
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
-- �����O�[��(�ƭ�)
function BuffManager:checkAtkBuffValue2(chaNode, isPhy, aniName)
    local buff = chaNode.buffData
    local addValue = 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.FALSE_GOD then -- ����
                end
            end
        end
    end
    return addValue
end
-- ���m�O�[��(%��)
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
                if mainBuffId == CONST.BUFF.DEFENSE_CHAIN_B then  -- ���m����
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- �B��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.ICE_WALL then  -- �B��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.MAGICIAN then  -- �s���]��
                    -- �ˬd�ؼЦ�q
                    local hpPer = target.battleData[CONST.BATTLE_DATA.HP] / target.battleData[CONST.BATTLE_DATA.MAX_HP]
                    if hpPer >= tonumber(buffValues[1]) then
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- �L��
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.DESTROY then  -- ���m�}�a
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.COLLAPSE then   -- �Y�a
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if isPhy then
                    if mainBuffId == CONST.BUFF.STABLE then   -- ��u
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.DEFENSE_HEART_B then  -- ���u����
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.BROKEN then  -- �}��
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == FRAGILE then  -- �ܮz
                        addValue = tonumber(buffValues[1])
                    end
                else
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- �]�O���X
                        addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.ARCANE_B then  -- ���N
                        addValue = tonumber(buffValues[2])
                    end
                    if mainBuffId == CONST.BUFF.MAGIC_SHIELD_B then  -- �m�]�ޥ�
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.WITCHER_III then  -- �y�]�HIII��
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.FORCE_FIELD then  -- �O��
                        addValue = tonumber(buffValues[1])
                    end
                    ---------------------------------------------------------------
                    if mainBuffId == CONST.BUFF.EXHAUST then  -- �}�]
                        addValue = tonumber(buffValues[1])
                    end
                end
                --------------------------------------------------------------- �j���k�s
                if mainBuffId == CONST.BUFF.FREEZE then  -- �ᵲ
                    buffValue, auraValue, markValue = tonumber(buffValues[1]), tonumber(buffValues[1]), tonumber(buffValues[1])
                    break   -- �k�s�ᤣ�B�z�᭱�����mbuff
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- ���m�O�[��(�ƭ�)
function BuffManager:checkDefBuffValue2(target, buff, isPhy, aniName)
    local addValue = 0
    local buff = target.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.FALSE_GOD then -- ����
                end
            end
        end
    end
    return addValue
end
-- ���m�O��z�[��
function BuffManager:checkDefPenetrateBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if aniName == CONST.ANI_ACT.ATTACK then -- ���q������
                    if mainBuffId == CONST.BUFF.CONCENTRATION then  -- �M�`
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.ICE_HEART then  -- �B��
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.WITCHER_I then  -- �y�]�HI��
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
-- �ˮ`�[��(�ۤv�W��+�Ĥ���˥[��)
function BuffManager:checkAllDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue, auraValue, markValue = self:checkDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue2, auraValue2, markValue2 = self:checkBeDmgBuffValue(attacker, target, isPhy, aniName)
    return math.max(0, buffValue + buffValue2 - 1), math.max(0, auraValue + auraValue2 - 1), math.max(0, markValue + markValue2 - 1)
end
-- �y���ˮ`�[��
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
                if mainBuffId == CONST.BUFF.CHASE then  -- �l��
                    -- �ˬd�ؼЦ�q
                    local hpPer = target.battleData[CONST.BATTLE_DATA.HP] / target.battleData[CONST.BATTLE_DATA.MAX_HP]
                    if hpPer < tonumber(buffValues[1]) then
                        addValue = tonumber(buffValues[2])
                    end
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
                    addValue = tonumber(buffValues[1])
                end
                if aniName == CONST.ANI_ACT.ATTACK then -- ���q������
                    if mainBuffId == CONST.BUFF.PUNCTURE then  -- ���
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.PIERCING_ICE then  -- �H�B�방
                        if buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count then
                            addValue = tonumber(buffValues[1])
                        end
                    end
                    if mainBuffId == CONST.BUFF.DARK_THUNDER then  -- �t�p�޾�
                        addValue = tonumber(buffValues[1])
                    end
                    if mainBuffId == CONST.BUFF.FRENZY then  -- �g��
                        addValue = tonumber(buffValues[1])
                    end
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_TODMG_FIRE1 or   -- �ť�
                   mainBuffId == CONST.BUFF.RUNE_TODMG_WATER1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_LIGHT1 or
                   mainBuffId == CONST.BUFF.RUNE_TODMG_DARK1 then
                    if target.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if mainBuffId == CONST.BUFF.RUNE_TODMG_FIRE_WATER1 or   -- �ť�
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
-- ����ˮ`�[��
function BuffManager:checkBeDmgBuffValue(attacker, target, isPhy, aniName)
    local buffValue, auraValue, markValue, skillValue = 1, 1, 1, 1
    local buff = target.buffData  -- �ؼЪ�Buff
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- �@��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.PETAL then  -- �}��
                    addValue = tonumber(buffValues[2]) and tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.GUARD then  -- �u�@
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.NATURE then   -- �۵M�L�O
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.STONE then  -- �ۤ�
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.TACTICAL_VISOR then -- �ԳN��w
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.DEPENDENTS then -- ����
                    -- �ˬd�����̧ޯ�ID
                    for skillType, skillTypeData in pairs(attacker.skillData) do
                        for skillId, skillIdData in pairs(skillTypeData) do
                            if skillId == tonumber(buffValues[3]) then
                                addValue = tonumber(buffValues[2])
                            end
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.FREEZE then -- �ᵲ
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.INJURY then -- ����
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.CONDUCTOR then  -- �ɹq��
                    if aniName and aniName == CONST.ANI_ACT.SKILL0 then -- �j�ۮ�
                        local buffCount = 0
                        local fList = NgBattleDataManager_getFriendList(target)
                        local aliveIdTable = NewBattleUtil:initAliveTable(fList)
                        for i = 1, #aliveIdTable do -- �p�ⶤ��ɹq�骺�ƶq
                            local friendNode = fList[aliveIdTable[i]]
                            for buffId, buffData in pairs(friendNode.buffData) do
                                local id = math.floor(buffId / 100) % 1000
                                if id == CONST.BUFF.CONDUCTOR then  -- �ɹq��
                                    buffCount = buffCount + 1
                                end
                            end
                        end
                        if buffCount <= 1 then  -- �S����L�ɹq��
                            addValue = tonumber(buffValues[2])
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.OFFERINGS then -- ���~
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then -- �岽
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.BURN then -- �U�N
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.TARGET_BUFF_ADD_DMG]) do -- �ޯ��S�wBuff�W��
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
                if mainBuffId == CONST.BUFF.RUNE_BEDMG_FIRE1 or   -- �ť�
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_WATER1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_WIND1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_LIGHT1 or
                   mainBuffId == CONST.BUFF.RUNE_BEDMG_DARK1 then
                    if attacker.battleData[CONST.BATTLE_DATA.ELEMENT] == tonumber(buffValues[2]) then
                        addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                end
                if mainBuffId == CONST.BUFF.RUNE_BEDMG_FIRE_WATER1 or   -- �ť�
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
    local buff = attacker.buffData  -- �����̪�Buff
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                -- �r����Buff
                if mainBuffId == CONST.BUFF.POSITION or
                   mainBuffId == CONST.BUFF.SOUL_OF_POSION or
                   mainBuffId == CONST.BUFF.TOXIN_OF_POSION or
                   mainBuffId == CONST.BUFF.SNAKE_OF_POSION then
                    -- �ˬd�����̧ޯ�ID
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
-- �z���v�[��
function BuffManager:checkCriBuffValue(attacker, buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PRECISION then  -- ��T
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.EMBER then  -- �l�u
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.STEALTH then  -- ����
                    addValue = tonumber(buffValues[1])
                    NewBattleUtil:removeBuff(attacker, fullBuffId, false)   -- Ĳ�o�Ჾ��
                    -- �I��p���ˬd
                    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                    if CHAR_UTIL:isCanLittleSkill(attacker, CONST.SKILL1_TRIGGER_TYPE.STEALTH_CLEAR) then
                        local skillId = CHAR_UTIL:getTriggerLittleSkill(attacker, CONST.SKILL1_TRIGGER_TYPE.STEALTH_CLEAR)  -- �ˬdĲ�o���p��
                        if skillId then
                            local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
                            NgBattleCharacterBase:useLittleSkill(attacker, skillId)
                            return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
                        end
                    end
                end
                --------------------------------------------------------------- �j���z��
                if aniName == CONST.ANI_ACT.ATTACK then  -- ���q������
                    if mainBuffId == CONST.BUFF.RAGE or   -- ����
                       mainBuffId == CONST.BUFF.SINISTER then   -- �c�r
                        local value = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and 1 or 0
                        buffValue, auraValue, markValue = value, value, value
                        if value == 1 then
                            break   -- ���z�ᤣ�B�z�᭱��buff
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
-- �z�˥[��
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
                    if mainBuffId == CONST.BUFF.RAGE then   -- ����
                        addValue = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and tonumber(buffValues[1]) or nil
                    end
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
                    addValue = tonumber(buffValues[3])
                end
                if mainBuffId == CONST.BUFF.INFERNO then  -- �~��
                    addValue = tonumber(buffValues[1]) and tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                    -- Ĳ�o�Ჾ��
                    removeInfernoId = fullBuffId
                    -- ������Ĳ�o�Q�ʧޯ�
                    local list = NgBattleDataManager_getFriendList(chaNode)
                    local aliveIdTable = NewBattleUtil:initAliveTable(list)
                    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE]) do -- �ͤ�Buff������Ĳ�o�Q��
                        for i = 1, #aliveIdTable do
                            local resultTable = { }
                            local allPassiveTable = { }
                            local actionResultTable = { }
                            local allTargetTable = { }
                            if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE, { chaNode }) then
                                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                                LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                                CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
                            end
                        end
                    end
                end
                if mainBuffId == CONST.BUFF.SHADOW_HUNTER then   -- �t�v�y��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.LIGHT_CHARGE then  -- ģ���R��
                    addValue = tonumber(buffValues[1])
                    NewBattleUtil:removeBuff(chaNode, fullBuffId, false)   -- Ĳ�o�Ჾ��
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_CRI_DMG]) do -- �C��q�B�~�z��
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
    return buffValue, auraValue, markValue  -- �i�H�p��0
end
-- ��t�[��
function BuffManager:checkAtkSpeedBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.CONCENTRATION then  -- �M�`
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.RAPID_B then  -- ��t
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
                    addValue = tonumber(buffValues[4])
                end
                if mainBuffId == CONST.BUFF.STORM then  -- �ɭ�
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.EMBER then  -- �l�u
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.UNRIVALED then  -- �L��
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
                if mainBuffId == CONST.BUFF.FROSTBITE then -- ���
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                if mainBuffId == CONST.BUFF.SNAKE_OF_POSION then  -- �D�r
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- �դ��i��(���|����t)
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
-- ���ʳt�ץ[��
function BuffManager:checkMoveSpeedBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        local isUnstoppable = false
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- �դ��i��(���|���]�t)
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
                if mainBuffId == CONST.BUFF.TAILWIND then  -- ����
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if not isUnstoppable then
                    if mainBuffId == CONST.BUFF.FROSTBITE then -- ���
                        addValue = tonumber(buffValues[2]) * buffData[CONST.BUFF_DATA.COUNT]
                    end
                    if mainBuffId == CONST.BUFF.HEADWIND then -- ���
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
-- �R���[��
function BuffManager:checkHitBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.KEEN_B then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.ACCURACY_B then  -- ���
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- �y�]�HII��
                    addValue = tonumber(buffValues[3])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.BLIND then  -- �P��
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return buffValue, auraValue, markValue  -- �i�H�p��0
end
-- �{�ץ[��
function BuffManager:checkDodgeBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.SHADOW_B then  -- �t�v
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.KEEN_B then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- �y�]�HII��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.SHADOW_HUNTER then   -- �t�v�y��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.AVOID then   -- ����
                    addValue = tonumber(buffValues[1]) * buffData[CONST.BUFF_DATA.COUNT]
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.TWINE then  -- ��¶
                    addValue = tonumber(buffValues[1])
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return buffValue, auraValue, markValue  -- �i�H�p��0
end
-- �l��[��(����)
function BuffManager:checkRecoverHpBuffValue(attacker, buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.OUROBOROS then  -- �Χ��D
                    addValue = buffData[CONST.BUFF_DATA.COUNT] == buffConfig[fullBuffId].max_count and tonumber(buffValues[3]) or nil
                end
                if mainBuffId == CONST.BUFF.ASSAULT_B then  -- ����
                    addValue = tonumber(buffValues[2])
                end
                if buff[CONST.BUFF.KEEN_B] then  -- �ӾU
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.WITCHER_II then  -- �y�]�HII��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.DARK_THUNDER then  -- �t�p�޾�
                    addValue = tonumber(buffValues[2])
                    NewBattleUtil:removeBuff(attacker, fullBuffId, false)   -- Ĳ�o�Ჾ��
                end
                if addValue then
                    buffValue, auraValue, markValue = self:addBuffValue(fullBuffId, addValue, buffValue, auraValue, markValue)
                end
            end
        end
    end
    return math.max(buffValue, 0), math.max(auraValue, 0), math.max(markValue, 0)
end
-- �y���v���[��
function BuffManager:checkHealBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- �@��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.APOLLO then -- �Ӷ���
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_HEALTH then  -- �ť�
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
-- ����v���[��
function BuffManager:checkBeHealBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.PIOUS then  -- �@��
                    addValue = tonumber(buffValues[2])
                end
                if mainBuffId == CONST.BUFF.APOLLO then -- �Ӷ���
                    addValue = tonumber(buffValues[2])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.ANTI_HEAL then  -- �T��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.SNAKE_OF_POSION then  -- �D�r
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                mainBuffId = math.floor(fullBuffId / 10)
                if mainBuffId == CONST.BUFF.RUNE_BEHEALTH then  -- �ť�
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
-- �B�~MP��o
function BuffManager:checkMpGainValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if aniName == CONST.ANI_ACT.ATTACK then -- ���q������
                    if mainBuffId == CONST.BUFF.MOONLIGHT then  -- ���
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
-- MP��o���v
function BuffManager:checkMpGainRatio(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 1, 1, 1
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.TAILWIND then  -- ����
                    addValue = tonumber(buffValues[1])
                end
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.HEADWIND then  -- �f��
                    addValue = tonumber(buffValues[1])
                end
                if mainBuffId == CONST.BUFF.SEAL then  -- �ʦL
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
-- �����Z��
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
                if mainBuffId == CONST.BUFF.RUNE_ATK_RANGE_1 then  -- �ť�
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
-- �K��Debuff���v�[��
function BuffManager:checkImmunityBuffValue(buff, isPhy, aniName)
    local buffValue, auraValue, markValue = 0, 0, 0
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.RESIST_B then  -- ���
                    addValue = tonumber(buffValues[1]) * 1000
                end
                if mainBuffId == CONST.BUFF.BRILLIANCE then  -- ����
                    addValue = tonumber(buffValues[1]) * 1000
                end
                if mainBuffId == CONST.BUFF.HOLY_B then  -- �t��
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
-- �ˬd�_��BUFF
function BuffManager:checkRebirth(target)
    local buff = target.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if mainBuffId == CONST.BUFF.REBIRTH then  -- �j��
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
-- �S��BUFF��o�B�z
function BuffManager:getSpecialBuff(chaNode, target, buff, fullBuffId, oldIsMaxCount)
    if buff and fullBuffId then
        if buffConfig[fullBuffId] then
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            local buffValues = common:split(buffConfig[fullBuffId].values, ",")
            ---------------------------------------------------------------
            if mainBuffId == CONST.BUFF.IMMUNITY or -- �K��
               mainBuffId == CONST.BUFF.BERSERKER or  -- �g�Ԥh
               mainBuffId == CONST.BUFF.SHADOW_HUNTER then -- �t�v�y��
                --�M��debuff
                self:clearAllDeBuff(target, buff)
            end
            if mainBuffId == CONST.BUFF.POWER then  -- �v��
                --��o�@��
                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                local shield = math.floor(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[3]) + 0.5)
                CHAR_UTIL:addShield(target, target, shield)   --�W�[�@��
            end
            if mainBuffId == CONST.BUFF.FRENZY then  -- �g��
                -- ���h�ɶi�J�g�ê��A
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    --�j������ؼ�
                    self:setFrenzyTarget(target, self:createFrenzyTarget(target))
                end
            end
            if mainBuffId == CONST.BUFF.TAUNT then -- �J��
                --�j������ؼ�
                self:setTauntTarget(target, chaNode)
            end
            if mainBuffId == CONST.BUFF.STONE or -- �ۤ�
               mainBuffId == CONST.BUFF.FREEZE or -- �ᵲ
               mainBuffId == CONST.BUFF.DIZZY then -- �w�t
                for fullBuffId, buffData in pairs(buff) do
                    if buffConfig[fullBuffId] then
                        local mainBuffId = math.floor(fullBuffId / 100) % 1000
                        ---------------------------------------------------------------
                        if mainBuffId == CONST.BUFF.UNSTOPPABLE then  -- �դ��i��(���|�Q����)
                            isUnstoppable = true
                            break
                        end
                    end
                end
                if not isUnstoppable then
                    -- �]�wtimescale
                    --target.heroNode.heroSpine:setTimeScale(0)
                    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                    CHAR_UTIL:setTimeScale(target, 0)
                end
            end
            if mainBuffId == CONST.BUFF.JEALOUS then -- ����
                -- ���h�ɳy���ˮ`�ò���
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    local attacker = target.buffData[fullBuffId][CONST.BUFF_DATA.CASTER]
                    self:castDotDamage(attacker, target, fullBuffId, false, true)
                    self:forceClearBuff(target, fullBuffId)
                end
            end
            if mainBuffId == CONST.BUFF.STATIC then -- �R�q
                -- ���h�����ܬ��ɹq��
                if target.buffData[fullBuffId] and target.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                    -- �ˬd�����̧ޯ�ID
                    for skillType, skillTypeData in pairs(chaNode.skillData) do
                        for skillId, skillIdData in pairs(skillTypeData) do
                            if math.floor(skillId / 10) == tonumber(buffValues[1]) then -- �i���R�q���ܦ��ɹq�骺�ޯ�ID
                                local skillConfig = ConfigManager.getSkillCfg()
                                local skillValues = common:split(skillConfig[skillId].values, ",")
                                local buffId = tonumber(skillValues[2])
                                self:getBuff(target.buffData[fullBuffId][CONST.BUFF_DATA.CASTER], target, buffId, 999000 * 1000, 1)
                            end
                        end
                    end
                    -- �M���R�q
                    self:forceClearBuff(target, fullBuffId)
                end
            end
        end
    end
end
-- �S�w�ƥ�W�[BUFF�h��(�T�w1�h)
function BuffManager:addBuffCount(chaNode, buff, eventType)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if eventType == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
                    if mainBuffId == CONST.BUFF.OUROBOROS or  -- �Χ��D
                       mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- �]�O���X
                        -- ���h��Ĳ�o�|�~��������h
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                    if mainBuffId == CONST.BUFF.RAGE or   -- ����
                       mainBuffId == CONST.BUFF.MOONLIGHT or  -- ���
                       mainBuffId == CONST.BUFF.PIERCING_ICE then  -- �H�B�방
                        -- ���h��Ĳ�o�ĪG�|�M�żh��
                        if buffData[CONST.BUFF_DATA.COUNT] >= buffConfig[fullBuffId].max_count then
                            --self:clearBuffCount(chaNode, fullBuffId)
                            chaNode.buffData[fullBuffId][CONST.BUFF_DATA.COUNT] = 0
                        else
                            buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                            NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                        end
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
                    if mainBuffId == CONST.BUFF.PETAL then  -- �}��
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.SKILL then
                    if mainBuffId == CONST.BUFF.MANA_OVERFLOW then  -- �]�O���X
                        buffData[CONST.BUFF_DATA.COUNT] = math.min(buffData[CONST.BUFF_DATA.COUNT] + 1, buffConfig[fullBuffId].max_count)
                        NewBattleUtil:playBuffSpine(chaNode, fullBuffId, buffData)
                    end
                end
            end
        end
    end
end
-- �S�w�ƥ���BUFF�h��
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
                    if mainBuffId == CONST.BUFF.PUNCTURE then   -- ���
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        end
                    end
                    if mainBuffId == CONST.BUFF.DARK_THUNDER then   -- �t�p�޾�
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        end
                    end
                elseif eventType == CONST.ADD_BUFF_COUNT_EVENT.DODGE then
                    if mainBuffId == CONST.BUFF.DODGE then  -- ���{
                        buffData[CONST.BUFF_DATA.COUNT] = math.max(buffData[CONST.BUFF_DATA.COUNT] - 1, 0)
                        if buffData[CONST.BUFF_DATA.COUNT] <= 0 then
                            NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                        else
                            -- ����BUFF SPINE
                            NewBattleUtil:playBuffSpine(chaNode, fullBuffId, chaNode.buffData[fullBuffId])
                        end
                    end
                    if mainBuffId == CONST.BUFF.AVOID then  -- ����
                        NewBattleUtil:removeBuff(chaNode, fullBuffId, false)
                    end
                end
            end
        end
    end
end
-- �S��buff�ƥ�B�z
function BuffManager:specialBuffEffect(buff, eventType, chaNode, target, skillId, dmg)
    local triggerBuffList = { }
    if buff then
        if eventType == CONST.ADD_BUFF_COUNT_EVENT.CAST_ATTACK then
            for fullBuffId, buffData in pairs(chaNode.buffData) do
                if buffConfig[fullBuffId] then
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.PARALYSIS then  -- �·�
                        local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                        if tonumber(buffValues[1]) * 100 >= math.random(1, 100) then    -- Ĳ�o�·�
                            BuffManager:getBuff(buffData[CONST.BUFF_DATA.CASTER], chaNode, tonumber(buffValues[2]), tonumber(buffValues[3]) * 1000, 1)

                            triggerBuffList[mainBuffId] = fullBuffId
                        end
                    end
                    if mainBuffId == CONST.BUFF.TOXIN_OF_POSION then  -- �P�r
                        local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                        buffData[CONST.BUFF_DATA.COUNTER] = buffData[CONST.BUFF_DATA.COUNTER] and buffData[CONST.BUFF_DATA.COUNTER] + 1 or 1
                        if buffData[CONST.BUFF_DATA.COUNTER] >= tonumber(buffValues[1]) then    -- Ĳ�o�P�r
                            -- dot�ˮ`
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
                    -- �ͤ観����Buff
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.WINDFURY then  -- ����
                        local triggerId = { 600201, 600202 }    -- ���z���㪺�ޯ�ID
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
                    -- �Ĥ観����Buff
                    local mainBuffId = math.floor(fullBuffId / 100) % 1000
                    if mainBuffId == CONST.BUFF.WINDFURY then  -- ����
                        if chaNode and chaNode.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.FIRE and   -- ���ݩ�
                           chaNode.skillData[CONST.SKILL_DATA.SKILL][skillId] then    -- �j��
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
                    if mainBuffId == CONST.BUFF.CONDUCTOR then  -- �ɹq��
                        local skillConfig = ConfigManager.getSkillCfg()
                        if skillId and skillConfig[skillId] and skillConfig[skillId].actionName == CONST.ANI_ACT.SKILL0 then -- �j�ۮ�
                            local fList = NgBattleDataManager_getFriendList(target)
                            local aliveIdTable = NewBattleUtil:initAliveTable(fList)
                            for i = 1, #aliveIdTable do
                                local friendNode = fList[aliveIdTable[i]]
                                if friendNode.idx ~= target.idx then   -- ��ۤv�H�~���ɹq��ǻ��ˮ`
                                    self:castDotDamage(friendNode, friendNode, fullBuffId, false, true, dmg)
                                end
                            end
                            buffData[CONST.BUFF_DATA.TIME] = 0  -- �ɶ��]��0 > �U�@tick�A�M��
                        end
                    end
                    if mainBuffId == CONST.BUFF.THORNS then  -- ���
                        if chaNode.idx ~= target.idx then   -- ������̤Ϯg�ˮ`
                            self:castDotDamage(target, chaNode, fullBuffId, false, true, dmg)
                        end
                    end
                end
            end
        end
    end
    return triggerBuffList
end
-- �j����ؼ�buff
function BuffManager:forceClearBuff(chaNode, buffId)
    if chaNode.buffData and chaNode.buffData[buffId] then
        NewBattleUtil:removeBuff(chaNode, buffId, false)
    end
end
-- �M�ťؼ�buff�h��
function BuffManager:clearBuffCount(chaNode, buffId)
    if chaNode.buffData and chaNode.buffData[buffId] then
        chaNode.buffData[buffId][CONST.BUFF_DATA.COUNT] = 0
        --chaNode.buffData[buffId] = nil
        NewBattleUtil:removeBuffIcon(chaNode, buffId)
        NewBattleUtil:removeBuffSpine(chaNode, buffId, false)
    end
end
-- �M�ťؼ�buff�p�ɾ�
function BuffManager:clearBuffTimer(chaNode, buff, event)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            if buffConfig[fullBuffId] then
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                local buffValues = common:split(buffConfig[fullBuffId].values, ",")
                local addValue = nil
                ---------------------------------------------------------------
                if event == CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK then
                    if mainBuffId == CONST.BUFF.OUROBOROS then  -- �Χ��D
                        buffData[CONST.BUFF_DATA.TIMER] = 0
                    end
                    if mainBuffId == CONST.BUFF.FRENZY then  -- �g��
                        if BuffManager:isInFrenzy(buff) then
                            --�Ѱ��g�� �j������ؼ�
                            buffData[CONST.BUFF_DATA.TIME] = 0
                        end
                    end
                elseif event == CONST.ADD_BUFF_COUNT_EVENT.BEDAMAGE then
                    if mainBuffId == CONST.BUFF.PETAL or  -- �}��
                       mainBuffId == CONST.BUFF.POWER then  -- �v��
                        buffData[CONST.BUFF_DATA.TIMER] = 0
                    end
                elseif event == CONST.ADD_BUFF_COUNT_EVENT.CAST_ATTACK then

                elseif event == CONST.ADD_BUFF_COUNT_EVENT.SHIELD_CLEAR then
                    if buff[CONST.BUFF.POWER] then  -- �v��
                        buffData[CONST.BUFF_DATA.TIMER2] = 0
                    end
                end
            end
        end
    end
end
-- �O�_�J�ت��A(�u�i�����S�w�ؼ�)
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
-- �O�_�g�ê��A(�u�i����)
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
-- �O�_�I�q���A(���i�I��ޯ�)
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
-- �O�_�w�����A(���i���)
function BuffManager:isInCrowdControl(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STONE or -- �ۤ�
               mainBuffId == CONST.BUFF.FREEZE or -- �ᵲ
               mainBuffId == CONST.BUFF.DIZZY then -- �w�t
                return true
            end
        end
    end
    return false
end
-- �O�_�ݤO���A(�^�����%��, Ĳ�o��BuffId)
function BuffManager:isInUnDead(buff)
    local lockHp = 0
    local triggerBuffId = nil
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.UNDEAD then -- ���}
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
-- Ĳ�o�ݤO���A
function BuffManager:castInUnDead(chaNode, buff, buffId)
    if buff and buff[buffId] then
        local mainBuffId = math.floor(buffId / 100) % 1000
        if mainBuffId == CONST.BUFF.UNDEAD then -- ���}
            if buff[buffId][CONST.BUFF_DATA.COUNT] > 0 then  -- �٦��ϥΦ���
                buff[buffId][CONST.BUFF_DATA.COUNT] = buff[buffId][CONST.BUFF_DATA.COUNT] - 1
                if buff[buffId][CONST.BUFF_DATA.COUNT] <= 0 then
                    NewBattleUtil:removeBuff(chaNode, buffId, false)
                end
            end
        end
    end
end
-- �O�_�c�N���A(���|��oBuff)
function BuffManager:isInMalicious(buff)
    if buff then -- �c�N
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.MALICIOUS then -- �c�N
                return true
            end
        end
    end
    return false
end
-- �O�_�K�̪��A(���|��oDebuff)
function BuffManager:isInImmunity(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.IMMUNITY or -- �K��
               mainBuffId == CONST.BUFF.BERSERKER or  -- �g�Ԥh
               mainBuffId == CONST.BUFF.SHADOW_HUNTER then -- �t�v�y��
                return true
            end
        end
    end
    return false
end
-- �O�_�ɹq�骬�A(���|��o�R�q)
function BuffManager:isInConductor(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.CONDUCTOR then  -- �ɹq��
                return true
            end
        end
    end
    return false
end
-- �O�_���y(���|����(���PMISS�����Ʀr) ���]�ADOT)
function BuffManager:isInGhost(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.GHOST and not buffData[CONST.BUFF_DATA.USING] then  -- ���y
                buffData[CONST.BUFF_DATA.USING] = true
                return true
            end
        end
    end
    return false
end
-- �ˬd���y�O�_Ĳ�o�� �pĲ�o������buff
function BuffManager:closeGhost(chaNode, buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.GHOST and buffData[CONST.BUFF_DATA.USING] then  -- ���y
                NewBattleUtil:removeBuff(chaNode, fullBuffId, true)
                return true
            end
        end
    end
    return false
end
-- �O�_���{(���PMISS ���]�ADOT)
function BuffManager:isInDodge(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.DODGE then  -- ���{
                return true
            end
        end
    end
    return false
end
-- �O�_����
function BuffManager:isInStealth(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STEALTH then  -- ����
                return true
            end
        end
    end
    return false
end
-- �O�_�L��
function BuffManager:isInInvincible(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.INVINCIBLE then  -- �L��
                return true
            end
        end
    end
    return false
end
-- �O�_�g�Ԥh
function BuffManager:isInBerserker(buff)
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
                return true
            end
        end
    end
    return false
end
-- �j���ഫ�ݩ�(�i��|���h�ݩ�)
function BuffManager:forceChangeElement(buff)
    local newElement = { }
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.STONE then -- �ۤ�
                table.insert(newElement, CONST.ELEMENT.NONE)
            end
        end
    end
    return newElement
end
-- �H���X���S�w�ƶqBUFF
function BuffManager:clearRandomBuffByNum(target, buff, num)
    if buff then
        local dispelBuffTable = { }
        for k, v in pairs(buff) do  -- �O���Ҧ��i�X����buff
            local cfg = buffConfig[k]
            if cfg.gain == 1 and cfg.dispel == 1 then   --buff&�i�X��
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
                -- �M���������ͪ�buff
                local fList = NgBattleDataManager_getFriendList(target)
                local eList = NgBattleDataManager_getEnemyList(target)
                self:clearAuraBuff(k, fList, eList)
            end
            -- �X����Ĳ�o�Q�ʧޯ�
            local mainBuffId = math.floor(k / 100) % 1000
            if mainBuffId == CONST.BUFF.INFERNO then  -- �~��
                local list = NgBattleDataManager_getFriendList(target)
                local aliveIdTable = NewBattleUtil:initAliveTable(list)
                for k2, v2 in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR]) do -- �ͤ�Buff������Ĳ�o�Q��
                    for i = 1, #aliveIdTable do
                        local resultTable = { }
                        local allPassiveTable = { }
                        local actionResultTable = { }
                        local allTargetTable = { }
                        if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v2, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR, { target }) then
                            local LOG_UTIL = require("Battle.NgBattleLogUtil")
                            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                            LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                            CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v2 * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
                        end
                    end
                end
            end
        end
    end
end
-- �X������BUFF
function BuffManager:clearAllBuff(target, buff)
    if buff then
        for k, v in pairs(buff) do
            local cfg = buffConfig[k]
            if cfg.gain == 1 and cfg.dispel == 1 then   --buff&�i�X��
                NewBattleUtil:removeBuff(target, k, false)
                if cfg.buffType == CONST.BUFF_TYPE.AURA then
                    -- �M���������ͪ�buff
                    local fList = NgBattleDataManager_getFriendList(target)
                    local eList = NgBattleDataManager_getEnemyList(target)
                    self:clearAuraBuff(k, fList, eList)
                end
                -- �X����Ĳ�o�Q�ʧޯ�
                local mainBuffId = math.floor(k / 100) % 1000
                if mainBuffId == CONST.BUFF.INFERNO then  -- �~��
                    local list = NgBattleDataManager_getFriendList(target)
                    local aliveIdTable = NewBattleUtil:initAliveTable(list)
                    for k2, v2 in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR]) do -- �ͤ�Buff������Ĳ�o�Q��
                        for i = 1, #aliveIdTable do
                            local resultTable = { }
                            local allPassiveTable = { }
                            local actionResultTable = { }
                            local allTargetTable = { }
                            if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v2, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR, { target }) then
                                local LOG_UTIL = require("Battle.NgBattleLogUtil")
                                local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                                LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                                CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v2 * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
                            end
                        end
                    end
                end
            end
        end
    end
end
-- �X������DEBUFF
function BuffManager:clearAllDeBuff(target, buff)
    if buff then
        for k, v in pairs(buff) do
            local cfg = buffConfig[k]
            local mainBuffId = math.floor(k / 100) % 1000
            if cfg.gain == 0 and cfg.dispel == 1 then   -- debuff&�i�X��
                NewBattleUtil:removeBuff(target, k, false)
            end
        end
    end
end
-- �����Ѱ�(�M�������ᤩ��buff/debuff)
function BuffManager:clearAuraBuff(buffId, fList, eList)
    local buffData = buffConfig[buffId]
    if buffData then
        local checkId = tonumber(buffData.values)
        for k, v in pairs(fList) do
            if v.buffData[buffId] then
                -- �٦����⦳�ӥ���
                return
            end
        end
        for k, v in pairs(fList) do
            if v.buffData[checkId] then
                -- ����������buff
                NewBattleUtil:removeBuff(v, checkId, false)
            end
        end
    end
end
-- (���⦺�`��)Buff/Debuff�ಾ
function BuffManager:transferBuff(node, fList, eList)
    local buff = node.buffData
    local fList = NgBattleDataManager_getFriendList(node)
    local aliveIdTable = NewBattleUtil:initAliveTable(fList)
    local transNode = nil
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.TACTICAL_VISOR or -- �ԳN��w
               mainBuffId == CONST.BUFF.DEPENDENTS then -- ����
                if #aliveIdTable > 0 then
                    transNode = fList[math.random(1, #aliveIdTable)]  -- �H�����idx
                end
            end
            --if mainBuffId == CONST.BUFF.OFFERINGS then -- ���~
            --    local SKILL_UTIL = require("Battle.NewSkill.SkillUtil")
            --    local targetTable = SKILL_UTIL:getLowestDefEnemy(node.buffData[fullBuffId][CONST.BUFF_DATA.CASTER], fList, aliveIdTable, CONST.SKILL_TARGET_CONDITION.LOWEST_HP)  -- ��ܨ��m�̧Cidx
            --    if #targetTable > 0 then
            --        transNode = targetTable[1]
            --    end
            --end
            if transNode then
                transNode.buffData = transNode.buffData or { }
                transNode.buffData[fullBuffId] = { }
                for k, v in pairs(node.buffData[fullBuffId]) do  
                    transNode.buffData[fullBuffId][k] = v  -- �ಾbuff���
                end
                -- ���ICON
                NewBattleUtil:addBuffIcon(transNode, fullBuffId)
                NewBattleUtil:sortBuffIcon(transNode)
                -- ����BUFF SPINE
                NewBattleUtil:playBuffSpine(transNode, fullBuffId, transNode.buffData[fullBuffId])
                transNode = nil
            end
        end
    end
end
-- �B�zhot�v��
function BuffManager:castHotHealth(node, buffId, isSkipPre, isSkipAdd)
    local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
    local mainBuffId = math.floor(buffId / 100) % 1000
    if node.buffData[buffId] then
        local buffValues = common:split(buffConfig[buffId].values, ",")
        --�I�k�̧����O
        local atk = NewBattleUtil:calAtk(node.buffData[buffId][CONST.BUFF_DATA.CASTER], nil)
        --�I�k�̳y���v��buff
        local buffValue = self:checkHealBuffValue(node.buffData[buffId][CONST.BUFF_DATA.CASTER].buffData)
        --�ؼШ���v��buff
        local buffValue2 = self:checkBeHealBuffValue(node.buffData)
        if mainBuffId == CONST.BUFF.RECOVERY then  -- �A��
            -- �I�k�̳̤jHP
            local maxHp = node.buffData[buffId][CONST.BUFF_DATA.CASTER].battleData[CONST.BATTLE_DATA.MAX_HP]
            --��¦�v��
            local dmg = maxHp * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.WIND_WHISPER then  -- ���y
            local dmg = node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.HOLY_B then  -- �t��
            local dmg = node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * buffValue * buffValue2
            NgBattleCharacterBase:beHot(node, math.abs( math.floor(dmg + 0.5) ), buffId, isSkipPre, isSkipAdd)
        end
    end
end
-- �B�zbuff�v��
function BuffManager:castBuffHealth(chaNode, target, buffId)
    local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
    local mainBuffId = math.floor(buffId / 100) % 1000

end
-- �B�zdot�ˮ`
function BuffManager:castDotDamage(chaNode, target, buffId, isSkipPre, isSkipAdd, baseDmg)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if target and target.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.EROSION then  -- �I�k
            -- �W��buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, false,  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- �̤j��q * %�� * (1 - �]�k���)
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * (1 - NewBattleUtil:calReduction2(nil, target, false)))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.POSITION then  -- ���r
            -- �W��buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, true,  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- �̤j��q * %�� * (1 - ���z���)
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]) * (1 - NewBattleUtil:calReduction2(nil, target, true)))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BLEED then  -- �X��
            -- �W��buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- ��e��q * %��
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- �H�ͺؤl
            local attacker = chaNode
            --�����O
            local atk = NewBattleUtil:calAtk(attacker, target)
            --�ݩʥ[��
            local elementRate = NewBattleUtil:calElementRate(attacker, target)
            --��¦�ˮ`
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(attacker, target, 
                                                                                     attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                     nil)
            --���ݩʮ��B�~�W��
            local addRate = (target.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER) and 1 + target.battleData[CONST.BATTLE_DATA.MP] / 100 or 1
            local dmg = math.abs(atk * elementRate * tonumber(buffValues[2]) * buffValue * auraValue * markValue * addRate)
            NgBattleCharacterBase:beDot(chaNode, target, math.floor(dmg + 0.5), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.EXPLODE_SEED then  -- �z���ؤl
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable, { target })
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
        if mainBuffId == CONST.BUFF.JEALOUS then  -- ����
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable, { target })
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
        if mainBuffId == CONST.BUFF.OFFERINGS or   -- ���~
           mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then  -- �岽
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- �̤j��q * %��
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg + 0.5))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BURN then  -- �U�N
            local attacker = chaNode
            --�����O
            local atk = NewBattleUtil:calAtk(attacker, target)
            --��¦�ˮ`
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(attacker, target, 
                                                                                     attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                     nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            --�h��
            local count = target.buffData[buffId][CONST.BUFF_DATA.COUNT]
            local dmg = math.min(maxDmg, math.abs(atk * tonumber(buffValues[2]) * count * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, math.floor(dmg + 0.5), buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.TOXIN_OF_POSION then  -- �P�r
            -- �W��buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- �̤j��q * %��
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.SOUL_OF_POSION then  -- �r�r
            -- �W��buff
            local buffValue, auraValue, markValue = self:checkAllDmgBuffValue(chaNode, target, chaNode.battleData[CONST.BATTLE_DATA.IS_PHY],  nil)
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            -- �̤j��q * %��
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(buffValues[2]))
            dmg = math.min(maxDmg, math.floor(dmg * buffValue * auraValue * markValue))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
            -- �������`
            local dmg = math.abs(target.battleData[CONST.BATTLE_DATA.HP] + math.abs(target.battleData[CONST.BATTLE_DATA.SHIELD]))
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
        if mainBuffId == CONST.BUFF.THORNS then  -- ���
            local dmg = baseDmg * tonumber(buffValues[1])
            local maxDmg = NewBattleUtil:calAtk(chaNode, nil) * CONST.PERCENT_DMG_MAX_RATIO
            dmg = math.min(maxDmg, dmg)
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
    end
    -- �ˬd�I��̨��WBuff
    if chaNode and chaNode.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.ELECTROMAGNETIC_FIELD then  -- �q��ϳ�
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local allPassiveTable = { }
            local actionResultTable = { }
            local allTargetTable = { }
            local resultTable = NewBattleUtil:castBuffSkill(chaNode, buffId, { }, allPassiveTable)
            if resultTable then
                LOG_UTIL:setPreLog(chaNode, resultTable)
                CHAR_UTIL:calculateAllTable(chaNode, resultTable, false, actionResultTable, allTargetTable, buffId, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
            end
        end
        if mainBuffId == CONST.BUFF.THORNS then  -- ���
            local dmg = NewBattleUtil:calRoundValue(baseDmg * tonumber(buffValues[1]), 1)
            NgBattleCharacterBase:beDot(chaNode, target, dmg, buffId, isSkipPre, isSkipAdd)
        end
    end
    -- �ɹq��ݿW���ˬdBuffId
    if mainBuffId == CONST.BUFF.CONDUCTOR then  -- ���ͪ��ɹq��
        for fullBuffId, buffData in pairs(target.buffData) do -- �ˬd�ۤv��Buff
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.CONDUCTOR then  -- �ۤv���ɹq��
                local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
                local buffValues = common:split(buffConfig[buffId].values, ",")
                -- �ǻ��ˮ`
                local buffDmg = math.floor(baseDmg * tonumber(buffValues[1]) + 0.5)
                NgBattleCharacterBase:beDot(chaNode, target, math.abs(buffDmg), buffId, isSkipPre, isSkipAdd)
                buffData[CONST.BUFF_DATA.TIME] = 0  -- �ɶ��]��0 > �U�@tick�A�M��
            end
        end
    end
end
-- �B�z�l���]�O
function BuffManager:castDrainMana(node, buffId, isSkipPre, isSkipAdd)
    if node.buffData[buffId] then
        local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
        local mainBuffId = math.floor(buffId / 100) % 1000
        local buffValues = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- �H�ͺؤl
            local mana = tonumber(buffValues[1])
            if node.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER then    --���ݩʮɧl���ؼХ����]�O
                mana = node.battleData[CONST.BATTLE_DATA.MP]
            end
            NgBattleCharacterBase:beDrainMana(node, node, mana, false, buffId, { }, { })
        end
    end
end
-- �B�zBuff�����ɮĪG(����ɶ������~�|�o�ʪ��ĪG)
function BuffManager:castEndBuffEffect(node, buffId, isSkipPre, isSkipAdd)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if mainBuffId == CONST.BUFF.LEECH_SEED then  -- �H�ͺؤl
        -- �����ɧl�]+�z���ˮ`
        local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
        self:castDotDamage(attacker, node, buffId, false, true)
        self:castDrainMana(node, buffId, true, false)
    end
    if mainBuffId == CONST.BUFF.EXPLODE_SEED then  -- �H�ͺؤl
        -- �����ɧl�]+�z���ˮ`
        local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
        self:castDotDamage(attacker, node, buffId, false, true)
        self:castDrainMana(node, buffId, true, false)
    end
    if mainBuffId == CONST.BUFF.BERSERKER then  -- �g�Ԥh
        -- �����ɦ��`
        self:castDotDamage(attacker, node, buffId, false, true)
    end
end
-- �ˬdBuff�p�ɾ�(Ĳ�ohot, dot, ���h��...)
function BuffManager:checkBuffTimer(node, buffId)
    if node.buffData[buffId] then
        local mainBuffId = math.floor(buffId / 100) % 1000
        local valueArr = common:split(buffConfig[buffId].values, ",")
        if mainBuffId == CONST.BUFF.POWER then  -- �v��
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local beAtkTime = tonumber(valueArr[2]) * 1000   -- ������������
            local recoverTime = tonumber(valueArr[4]) * 1000   -- �^���W�v
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > beAtkTime then
                -- timer�W�LbeAtkTime�� �^�_�@��
                if node.buffData[buffId][CONST.BUFF_DATA.TIMER] >= beAtkTime + recoverTime then
                    local maxRecoverShield = math.floor(node.battleData[CONST.BATTLE_DATA.MAX_HP] * tonumber(valueArr[3]) + 0.5)  -- �@�ަ^�_�W��
                    if maxRecoverShield < node.battleData[CONST.BATTLE_DATA.SHIELD] then    -- ���^�_�ܤW��
                        local recoverShield = math.floor(maxRecoverShield * tonumber(valueArr[5]) + 0.5)   -- �^�_�q
                        local trueRecoverShield = math.min(maxRecoverShield - node.battleData[CONST.BATTLE_DATA.SHIELD], recoverShield)
                        if trueRecoverShield > 0 then   -- �i�H�^�_�@��
                            LOG_UTIL:setPreLog(node)
                            CHAR_UTIL:addShield(node, node, recoverShield)   --�^�_�@��
                            LOG_UTIL:addBuffLog(node, buffId)
                        end
                    end
                    -- ���ަ��S���^�_ �p�ɾ����n�p��
                    node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - recoverTime, 0)
                end
            end
            if node.battleData[CONST.BATTLE_DATA.SHIELD] <= 0 then  -- �S���@��
                local rebirthTime = valueArr[1] * 1000   -- �@�ޭ��ͬ��
                if node.buffData[buffId][CONST.BUFF_DATA.TIMER2] > rebirthTime then  -- timer2 > �@�ޭ��ͬ�� �@�ޭ���
                    local rebirthShield = math.floor(node.battleData[CONST.BATTLE_DATA.MAX_HP] * valueArr[3] + 0.5)
                    LOG_UTIL:setPreLog(node)
                    CHAR_UTIL:setShield(node, rebirthShield)   --�^�_�@��
                    LOG_UTIL:addBuffLog(node, buffId)
                end
            else
                node.buffData[buffId][CONST.BUFF_DATA.TIMER2] = 0   -- �٦��@�ޤ��p��
            end
        end
        if mainBuffId == CONST.BUFF.PETAL or  -- �}��
           mainBuffId == CONST.BUFF.OUROBOROS then  -- �Χ��D
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local time = tonumber(valueArr[1]) * 1000
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- ���m�h��
                LOG_UTIL:setPreLog(node)
                self:clearBuffCount(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = 0
                LOG_UTIL:addBuffLog(node, buffId)
            end
        end
        if mainBuffId == CONST.BUFF.EROSION or  -- �I�k
           mainBuffId == CONST.BUFF.POSITION or  -- ���r
           mainBuffId == CONST.BUFF.BLEED or  -- �X��
           mainBuffId == CONST.BUFF.BURN or  -- �U�N
           mainBuffId == CONST.BUFF.SOUL_OF_POSION or  -- �r�r
           mainBuffId == CONST.BUFF.OFFERINGS then  -- ���~
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50�@���קK�@�Φ��ƻ~�t
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot�ˮ`
                local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
                self:castDotDamage(attacker, node, buffId, (not node.otherData[CONST.OTHER_DATA.IS_ENEMY] and NgBattleDataManager.battleType == CONST.SCENE_TYPE.AFK))
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)  
            end
        end
        if mainBuffId == CONST.BUFF.LEECH_SEED then  -- �H�ͺؤl
            if node.battleData[CONST.BATTLE_DATA.ELEMENT] == CONST.ELEMENT.WATER then    --���ݩʮɥߧY���z
                node.buffData[buffId][CONST.BUFF_DATA.TIME] = 0
            end
        end
        if mainBuffId == CONST.BUFF.RECOVERY or -- �A��
           mainBuffId == CONST.BUFF.WIND_WHISPER or -- ���y
           mainBuffId == CONST.BUFF.HOLY_B then -- �t��
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50�@���קK�@�Φ��ƻ~�t
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- hot�v��
                self:castHotHealth(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)      
            end
        end
        if mainBuffId == CONST.BUFF.ELECTROMAGNETIC_FIELD  then -- �q��ϳ�
            local time = tonumber(valueArr[3]) * 1000 - 50   -- -50�@���קK�@�Φ��ƻ~�t
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot�ˮ`
                local SKILL_UTIL = require("Battle.NewSkill.SkillUtil")
                self:castDotDamage(node, nil, buffId, false)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)     
            end
        end
        if mainBuffId == CONST.BUFF.BLOOD_SACRIFICE then -- �岽
            local time = tonumber(valueArr[1]) * 1000 - 50   -- -50�@���קK�@�Φ��ƻ~�t
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- dot�ˮ`
                local attacker = node.buffData[buffId][CONST.BUFF_DATA.CASTER]
                self:castDotDamage(attacker, node, buffId)
                -- hot�v��
                self:castHotHealth(node, buffId)
                node.buffData[buffId][CONST.BUFF_DATA.TIMER] = math.max(node.buffData[buffId][CONST.BUFF_DATA.TIMER] - time, 0)      
            end
        end
        if mainBuffId == CONST.BUFF.ICE_WALL then  -- �B��
            local LOG_UTIL = require("Battle.NgBattleLogUtil")
            local time = tonumber(valueArr[1]) * 1000
            if node.buffData[buffId][CONST.BUFF_DATA.TIMER] > time then
                -- ��ּh��
                node.buffData[buffId][CONST.BUFF_DATA.COUNT] = math.max(node.buffData[buffId][CONST.BUFF_DATA.COUNT] - 1, 0)
                if node.buffData[buffId][CONST.BUFF_DATA.COUNT] <= 0 then
                    NewBattleUtil:removeBuff(node, buffId, false)
                end
            end
        end
    end
end
-- ���ͨg�åؼ�
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
-- �]�w�g�åؼ�
function BuffManager:setFrenzyTarget(chaNode, target)
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    if not target then	-- �M���g�åؼ�
        chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] = nil
        if self:isInTaunt(chaNode.buffData) then    -- ���J�ت��A
            chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET]
        else
    	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = nil
        end
        CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    elseif target then   -- �����ؼ�
        if not chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] then  -- �S����l�ؼФ~�]�w �קK�Q��L�ؼл\�L
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = chaNode.target
        end
        chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] = target
	    chaNode.target = target
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    end
end
-- �]�w�J�إؼ�
function BuffManager:setTauntTarget(chaNode, target)
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    if not target and chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] then	-- �M���J�إؼ�
        chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] = nil
        if self:isInFrenzy(chaNode.buffData) then    -- ���g�ê��A
            chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET]
        else
    	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = nil
        end
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    elseif target then
        if not chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] then  -- �S����l�ؼФ~�]�w �קK�Q��L�ؼл\�L
            chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET] = chaNode.target
        end
        chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] = target  -- �]�w�J�إؼ�
        if not self:isInFrenzy(chaNode.buffData) then   -- ���b�g�ä��~�����ؼ�
	        chaNode.target = target
            CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
        end
    end
end
-- �M���J�إؼ�
function BuffManager:clearTauntTarget(chaNode)
    self:setTauntTarget(chaNode, nil)
end
-- ��o�����B�~�ؼ�
function BuffManager:getExternNormalAtkTarget(chaNode, target)
    local externTar = { }
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.PUNCTURE then   -- ���
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
-- ��o�����B�~Buff
function BuffManager:getExternNormalAtkBuff(chaNode, target)
    local externData = { }
    local buff = chaNode.buffData
    if buff then
        for fullBuffId, buffData in pairs(buff) do
            local mainBuffId = math.floor(fullBuffId / 100) % 1000
            if mainBuffId == CONST.BUFF.PUNCTURE then   -- ���
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
            if mainBuffId == CONST.BUFF.PIERCING_ICE then   -- �H�B�방
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