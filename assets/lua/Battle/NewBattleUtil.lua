NewBattleUtil = NewBattleUtil or {}

require("Battle.NgBattleDataManager")
local CONST = require("Battle.NewBattleConst")
local BuffManager = require("Battle.NewBuff.BuffManager")
local SkillManager = require("Battle.NewSkill.SkillManager")
-------------------------------------------------------
-- %�ƥ|�ˤ��J����p�ƲĤG�� �¼ƭȥ|�ˤ��J�����Ʀ�
-------------------------------------------------------

--�p���¦�ˮ`
function NewBattleUtil:calBaseDamage(attacker, target)
    local dmg = 0
    local weakResistType = 0
    if target then
        --���
        local reduction = self:calReduction(attacker, target)
        --�����O
        local atk = self:calAtk(attacker, target)
        --�ݩʥ[��
        local elementRate = self:calElementRate(attacker, target)
        --�̲׶ˮ`
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(attacker, target, 
                                                                                 attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                 attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
        dmg = atk * (1 - reduction) * elementRate * buffValue * auraValue * markValue
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_DMG]) do -- �C��q�B�~�W��
            local skillType, fullSkillId = self:checkSkill(v, attacker.skillData)
            if skillType == CONST.SKILL_DATA.PASSIVE then
                local params = SkillManager:calSkillSpecialParams(fullSkillId, { target })
                dmg = dmg * params
            end
        end
        local unReductDmg = 0
        for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ADD_UNREDUCT_DMG]) do -- �l�[�L����˶ˮ`
            local skillType, fullSkillId = self:checkSkill(v, attacker.skillData)
            if skillType == CONST.SKILL_DATA.PASSIVE then
                local params = SkillManager:calSkillSpecialParams(fullSkillId, { target })
                unReductDmg = unReductDmg + atk * params[1] * elementRate * buffValue * auraValue * markValue
            end
        end
        dmg = dmg + unReductDmg

        weakResistType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        -- testlog
        if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK then
            local formatStr = string.format("calBaseDamage dmg = %d,reduction = %f,atk = %f , elementRate = %f , buffValue = %f , auraValue = %f ,markValue = %f ",dmg,reduction,atk,elementRate,buffValue,auraValue,markValue)
            self:printLog(attacker,target,formatStr)
        end
    end

    return self:calRoundValue(dmg, 1), weakResistType
end

--�p�ⴶ�𵲪G
function NewBattleUtil:calNormalAtkResult(chaNode, target, hitNum)
    local dmgTable, tarTable, isCriTable, weakTable = { }, { }, { }, { }
    local healTable, healTarTable, healCriTable = { }, { }, { }
    local buffTable, buffTargetTable, buffTimeTable, buffCountTable = { }, { }, { }, { }
    local resultTable = { }
    local externTar = BuffManager:getExternNormalAtkTarget(chaNode, target)
    table.insert(externTar, target)
    for i = 1, #externTar do
        --�p���¦�ˮ`, �O�_�g��
        local baseDmg, weakType = NewBattleUtil:calBaseDamage(chaNode, externTar[i])
        local oneHitDmg = baseDmg / hitNum
        --chaNode.ATTACK_PARAMS["weak_type"] = weakType or 0
        if self:calIsHit(chaNode, externTar[i]) then
            -- �z��
            local criRate = 1
            local isCri = self:calIsCri(chaNode, externTar[i], false, true)
            if isCri then
                -- 1 + ��¦�z�� + �z�˼W�q - �z�˩�K
                criRate = self:calFinalCriDmgRate(chaNode, externTar[i])
            end
            -- �̲׶ˮ`(�|�ˤ��J)
            local dmg = self:calRoundValue(oneHitDmg * criRate, 1)
            table.insert(dmgTable, dmg)
            table.insert(tarTable, externTar[i])
            table.insert(isCriTable, isCri)
            table.insert(weakTable, weakType)
            -- �v��(����l��)
            local recoverHp = NewBattleUtil:calRecoverHp(chaNode, externTar[i], dmg)
            if recoverHp > 0 then
                table.insert(healTable, recoverHp)
                table.insert(healTarTable, chaNode)
                table.insert(healCriTable, false)
            end
            -- �B�~buff
            local externBuffData = BuffManager:getExternNormalAtkBuff(chaNode, externTar[i])
            if #externBuffData > 0 then
                for idx = 1, #externBuffData do
                    table.insert(buffTable, externBuffData[idx].buffId)
                    table.insert(buffTargetTable, externBuffData[idx].buffTar)
                    table.insert(buffTimeTable, externBuffData[idx].buffTime)
                    table.insert(buffCountTable, externBuffData[idx].buffCount)
                end
            end
        else
            table.insert(dmgTable, 0)
            table.insert(tarTable, externTar[i])
            table.insert(isCriTable, false)
            table.insert(weakTable, false)
        end
    end
    --����ĪGBUFF���Ӽh��
    BuffManager:minusBuffCount(chaNode, CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK)
    --����ˮ`���G����
    resultTable[CONST.LogDataType.DMG] = dmgTable
    resultTable[CONST.LogDataType.DMG_TAR] = tarTable
    resultTable[CONST.LogDataType.DMG_CRI] = isCriTable
    resultTable[CONST.LogDataType.DMG_WEAK] = weakTable
    --����l�嵲�G����
    resultTable[CONST.LogDataType.HEAL] = healTable
    resultTable[CONST.LogDataType.HEAL_TAR] = healTarTable
    resultTable[CONST.LogDataType.HEAL_CRI] = healCriTable
    --������obuff/debuff���G����
    resultTable[CONST.LogDataType.BUFF] = buffTable
    resultTable[CONST.LogDataType.BUFF_TAR] = buffTargetTable
    resultTable[CONST.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[CONST.LogDataType.BUFF_COUNT] = buffCountTable

    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.AE_ATK_HIT]) do -- �����q�g
        NewBattleUtil:castPassiveSkill(chaNode, v, resultTable, { }, CONST.PASSIVE_TRIGGER_TYPE.AE_ATK_HIT, { target })
    end

    return resultTable
end

--�p�⪫/�]��
function NewBattleUtil:calAtk(attacker, target)
    local atk = 0
    local buffValue, auraValue, markValue = BuffManager:checkAtkBuffValue(attacker, attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                    attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
    local addValue = BuffManager:checkAtkBuffValue2(attacker, attacker.battleData[CONST.BATTLE_DATA.IS_PHY])
    if attacker.battleData[CONST.BATTLE_DATA.IS_PHY] then
        atk = (attacker.battleData[CONST.BATTLE_DATA.PHY_ATK] + addValue) * buffValue * auraValue * markValue
    else
        atk = (attacker.battleData[CONST.BATTLE_DATA.MAG_ATK] + addValue) * buffValue * auraValue * markValue
    end
    if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
        -- ���վ԰�
        if attacker.otherData[CONST.OTHER_DATA.IS_ENEMY] then
            atk = atk * NgBattleDataManager.testEnemyAttackRatio
        else
            atk = atk * NgBattleDataManager.testFriendAttackRatio
        end
    end
    return self:calRoundValue(atk, 1)
end
--�p�⪫��
function NewBattleUtil:calPhyAtk(attacker, target)
    local atk = 0
    local buffValue, auraValue, markValue = BuffManager:checkAtkBuffValue(attacker, true, attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
    local addValue = BuffManager:checkAtkBuffValue2(attacker, true)
    atk = (attacker.battleData[CONST.BATTLE_DATA.PHY_ATK] + addValue) * buffValue * auraValue * markValue
    if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
        -- ���վ԰�
        if attacker.otherData[CONST.OTHER_DATA.IS_ENEMY] then
            atk = atk * NgBattleDataManager.testEnemyAttackRatio
        else
            atk = atk * NgBattleDataManager.testFriendAttackRatio
        end
    end
    return self:calRoundValue(atk, 1)
end
--�p���]��
function NewBattleUtil:calMagAtk(attacker, target)
    local atk = 0
    local buffValue, auraValue, markValue = BuffManager:checkAtkBuffValue(attacker, false, attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
    local addValue = BuffManager:checkAtkBuffValue2(attacker, false)
    atk = (attacker.battleData[CONST.BATTLE_DATA.MAG_ATK] + addValue) * buffValue * auraValue * markValue
    if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
        -- ���վ԰�
        if attacker.otherData[CONST.OTHER_DATA.IS_ENEMY] then
            atk = atk * NgBattleDataManager.testEnemyAttackRatio
        else
            atk = atk * NgBattleDataManager.testFriendAttackRatio
        end
    end
    return self:calRoundValue(atk, 1)
end

--�p��(�ؼ�)��/�]��
function NewBattleUtil:calBaseDef(attacker, target, isPhy)
    local def = 0
    local buffValue, auraValue, markValue = BuffManager:checkDefBuffValue(target, target.buffData, target.battleData[CONST.BATTLE_DATA.IS_PHY])
    local addValue = BuffManager:checkDefBuffValue2(target, target.buffData, target.battleData[CONST.BATTLE_DATA.IS_PHY])
    local phy = isPhy or (attacker and attacker.battleData[CONST.BATTLE_DATA.IS_PHY])
    if phy then
        def = (target.battleData[CONST.BATTLE_DATA.PHY_DEF] + addValue) * buffValue * auraValue * markValue
    else
        def = (target.battleData[CONST.BATTLE_DATA.MAG_DEF] + addValue) * buffValue * auraValue * markValue
    end
    if (NgBattleDataManager.battleType == CONST.SCENE_TYPE.TEST_BATTLE) then
        -- ���վ԰�
        if target.otherData[CONST.OTHER_DATA.IS_ENEMY] then
            def = def * NgBattleDataManager.testEnemyDefenseRatio
        else
            def = def * NgBattleDataManager.testFriendDefenseRatio
        end
    end
    return self:calRoundValue(def, 1)
end
--�p��(�ؼ�)��/�]��(�p���z)
function NewBattleUtil:calDef(attacker, target, isPhy)
    local def = self:calBaseDef(attacker, target, isPhy) * (1 - self:calPenetrate(attacker, target))
    return self:calRoundValue(def, 1)
end
--�p��(�ؼ�)��/�]��(���p���z)
function NewBattleUtil:calDef2(attacker, target, isPhy)
    local def = self:calBaseDef(attacker, target, isPhy)
    return self:calRoundValue(def, 1)
end
--�p��(�ؼ�)��/�]���(%)
function NewBattleUtil:calReduction(attacker, target, isPhy)
    local level = target.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local def = self:calDef(attacker, target, isPhy)
    local reduction = def / (def + self:calRoundValue(1 + level / 3, 1) * (800 - level))
    reduction = math.max(reduction, 0)   -- ����t��
    reduction = math.min(reduction, CONST.MAX_DEF_PER)   -- 15%��ˤW��
    return self:calRoundValue(reduction, -4)
end
--�p��(�ؼ�)��/�]���(%)(���p���z)
function NewBattleUtil:calReduction2(attacker, target, isPhy)
    local level = target.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local def = self:calDef2(attacker, target, isPhy)
    local reduction = def / (def + self:calRoundValue(1 + level / 3, 1) * (800 - level))
    reduction = math.max(reduction, 0)   -- ����t��
    reduction = math.min(reduction, CONST.MAX_DEF_PER)   -- 15%��ˤW��
    return self:calRoundValue(reduction, -4)
end

--�p�⨤���ݩʦ�q
function NewBattleUtil:calAttrHp(sta)
    local attrHp = sta * 10
    return attrHp
end
--�p��̤j��q
function NewBattleUtil:calMaxHp(character)
    local maxHp = character.battleData[CONST.BATTLE_DATA.STA] * 10
    return self:calRoundValue(maxHp, 1)
end

--�p��(�ؼ�)�z���@�ʭ�
function NewBattleUtil:calCriResistValue(attacker, target)
    local criResistValue = target.battleData[CONST.BATTLE_DATA.CRI_RESIST]
    return self:calRoundValue(criResistValue, 1)
end
--�p��(�ؼ�)�z���@��(%)
function NewBattleUtil:calCriResist(attacker, target)
    local level = target.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local criResistValue = self:calCriResistValue(attacker, target)
    local criResistRate = criResistValue / (criResistValue + self:calRoundValue(1 + level / 3, 1) * (700 - level))
    criResistRate = math.max(criResistRate, 0)   -- ����t��
    return self:calRoundValue(criResistRate, -4)
end

--�p���z����
function NewBattleUtil:calCriValue(agi)
    local criValue = agi * 0.5
    return self:calRoundValue(criValue, 1) 
end
--�p���z���v(%)
function NewBattleUtil:calCri(attacker, target)
    local level = attacker.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local criValue = attacker.battleData[CONST.BATTLE_DATA.CRI]
    local criRate = criValue / (criValue + self:calRoundValue(1 + level / 3, 1) * (400 - level))
    criRate = math.max(criRate, 0)   -- ����t��
    -- �Q�ʧޯ��ˬd
    --local passiveValue = self:calPassiveSkillAttrPercent(attacker, Const_pb.CRITICAL)
    return self:calRoundValue(criRate, -4)
end

--�p���z���W��(%)
function NewBattleUtil:calCriDmgRate(attacker, target)
    local criDmgRate = 0
    local buffValue, auraValue, markValue = BuffManager:checkCriDmgBuffValue(attacker, attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                             attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
    criDmgRate = attacker.battleData[CONST.BATTLE_DATA.CRI_DMG] + buffValue + auraValue + markValue
    return self:calRoundValue(criDmgRate, -4)
end

--�p��̲��z���W��
function NewBattleUtil:calFinalCriDmgRate(attacker, target, isSkipResist)
    --local targetResist = isSkipResist and 1 or (1 - self:calCriResist(attacker, target))
    local oriDmgRate = self:calCriDmgRate(attacker, target)
    local criRate = 1 + oriDmgRate-- * targetResist
    return self:calRoundValue(criRate, -4)
end

--�p��R����
function NewBattleUtil:calHitValue(str, int, agi)
    local hitValue = str * 0.2 + int * 0.2 + agi * 0.3
    return self:calRoundValue(hitValue, 1)
end
--�p��R���v(%)
function NewBattleUtil:calHit(attacker, target)
    local level = attacker.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local buffValue, auraValue, markValue = BuffManager:checkHitBuffValue(attacker.buffData)
    local hitValue = attacker.battleData[CONST.BATTLE_DATA.HIT]
    local hitRate = hitValue / (hitValue + self:calRoundValue(1 + level / 3, 1) * (900 - level))
    hitRate = math.max(hitRate, 0)   -- ����t��
    hitRate = hitRate + buffValue + auraValue + markValue
    return self:calRoundValue(hitRate, -4)
end

--�p��(�ؼ�)�{�׭�
function NewBattleUtil:calDodgeValue(str, int, agi, sta)
    local dodgeValue = str * 0.15 + int * 0.15 + agi * 0.3 - sta * 0.05
    return self:calRoundValue(dodgeValue, 1)
end
--�p��(�ؼ�)�{�ײv(%)
function NewBattleUtil:calDodge(attacker, target)
    local level = target.otherData[CONST.OTHER_DATA.CHARACTER_LEVEL]
    local buffValue, auraValue, markValue = BuffManager:checkDodgeBuffValue(target.buffData)
    local dodgeValue = target.battleData[CONST.BATTLE_DATA.DODGE]
    local dodgeRate = dodgeValue / (dodgeValue + self:calRoundValue(1 + level / 2, 1) * (700 - level))
    dodgeRate = math.max(dodgeRate, 0)   -- ����t��
    dodgeRate = dodgeRate + buffValue + auraValue + markValue
    return self:calRoundValue(dodgeRate, -4)
end

--�p���z�v(%)
function NewBattleUtil:calPenetrate(attacker, target)
    local penetrateRate = 0
    local buffValue, auraValue, markValue = BuffManager:checkDefPenetrateBuffValue(attacker.buffData, attacker.battleData[CONST.BATTLE_DATA.IS_PHY], 
                                                                                   attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME])
    if attacker.battleData[CONST.BATTLE_DATA.IS_PHY] then
        penetrateRate = attacker.battleData[CONST.BATTLE_DATA.PHY_PENETRATE] + buffValue + auraValue + markValue
    else
        penetrateRate = attacker.battleData[CONST.BATTLE_DATA.MAG_PENETRATE] + buffValue + auraValue + markValue
    end
    return math.min(self:calRoundValue(penetrateRate, -4), 1)
end

--�p��^�_�v(%)
function NewBattleUtil:calRecover(attacker, target)
    local recoverRate = 0
    recoverRate = attacker.battleData[CONST.BATTLE_DATA.RECOVER_HP] --+ buff
    return self:calRoundValue(recoverRate, -4)
end

--�p��O�_�R��
function NewBattleUtil:calIsHit(attacker, target)
    local rand = math.random(1, 10000)
    -- 80%��¦�R��
    local hitRate = (CONST.BASE_HIT + self:calHit(attacker, target) - self:calDodge(attacker, target))
    hitRate = math.min(hitRate, CONST.MAX_HIT_PER)   -- 95%�R���v�W��
    hitRate = math.max(hitRate, CONST.MIN_HIT_PER)   -- 5%�R���v�U��
    if hitRate * 10000 >= rand then
        -- ���Ӷ���: �L�� > ���y > ���{ 
        if BuffManager:isInInvincible(target.buffData) or BuffManager:isInGhost(target.buffData) or BuffManager:isInDodge(target.buffData) then
            return false
        else
            return true
        end
    else
        return false
    end
end

--�p��O�_�z��
function NewBattleUtil:calIsCri(attacker, target, isSkipResist, isNormalAttack, addCriPer)
    local rand = math.random(1, 10000)
    local buffValue, auraValue, markValue = BuffManager:checkCriBuffValue(attacker, attacker.buffData, nil, isNormalAttack and CONST.ANI_ACT.ATTACK)
    -- 10%��¦�z��
    local criRate = CONST.BASE_CRI + self:calCri(attacker, target) - (isSkipResist and 0 or self:calCriResist(attacker, target)) + buffValue + auraValue + markValue + (addCriPer or 0)
    criRate = math.min(criRate, CONST.MAX_CRI_PER)   -- 95%�z���v�W��
    criRate = math.max(criRate, CONST.MIN_CRI_PER)   -- 5%�z���v�U��
    if criRate * 10000 >= rand then
        return true
    else
        return false
    end
end

function NewBattleUtil:calRecoverHp(attacker, target, dmg)
    local buffValue, auraValue, markValue = BuffManager:checkRecoverHpBuffValue(attacker, attacker.buffData)
    local heal = dmg * (attacker.battleData[CONST.BATTLE_DATA.RECOVER_HP] + buffValue + auraValue + markValue)
    return self:calRoundValue(heal, 1)
end

--�p�������o�]�O
function NewBattleUtil:calAtkGainMp(attacker, target, skillId)
    if skillId then
        local idx = math.floor(skillId / 10) % 10
        if attacker.battleData[CONST.BATTLE_DATA.SKILL_MP][idx] then
            local baseMp = tonumber(attacker.battleData[CONST.BATTLE_DATA.SKILL_MP][idx])
            return self:calRoundValue(attacker.battleData[CONST.BATTLE_DATA.SKILL_MP][idx] * target.battleData[CONST.BATTLE_DATA.CLASS_CORRECTION], 1)
        else
            return self:calRoundValue(attacker.battleData[CONST.BATTLE_DATA.ATK_MP] * target.battleData[CONST.BATTLE_DATA.CLASS_CORRECTION], 1)
        end
    else
        return self:calRoundValue(attacker.battleData[CONST.BATTLE_DATA.ATK_MP] * target.battleData[CONST.BATTLE_DATA.CLASS_CORRECTION], 1)
    end
end

--�p�������o�]�O
function NewBattleUtil:calBeAtkGainMp(attacker, target)
    return self:calRoundValue(target.battleData[CONST.BATTLE_DATA.DEF_MP], 1)
end

--�p���t(attack cd)
function NewBattleUtil:calAttackCD(attacker, target)
    local oriCD = attacker.battleData[CONST.BATTLE_DATA.COLD_DOWN]
    local buffValue, auraValue, markValue = BuffManager:checkAtkSpeedBuffValue(attacker.buffData)
    local debuffValue, deauraValue, demarkValue = BuffManager:checkAtkSpeedDeBuffValue(attacker.buffData)
    local newCD = oriCD * ((1 + math.max(debuffValue + deauraValue + demarkValue, 0)) / (1 + math.max(buffValue + auraValue + markValue, 0)))
    return newCD
end

--�O�_Ĳ�oBuff�K��
function NewBattleUtil:isTriggerDebuffImmunity(target, attacker)
    local per = target.battleData[CONST.BATTLE_DATA.IMMUNITY]
    local buffValue, auraValue, markValue = BuffManager:checkImmunityBuffValue(target.buffData)
    local rand = math.random(1, 100)
    return per >= rand
end

--�p��Z��
function NewBattleUtil:calTargetDis(selfPos, tarPos)
    local dis = ccpDistance(selfPos, tarPos)
    return dis
end

--�p���ݩʥ[��
function NewBattleUtil:calElementRate(attacker, target)
    local atkElement = { attacker.battleData[CONST.BATTLE_DATA.ELEMENT] }
    local atkElementNew = BuffManager:forceChangeElement(attacker.buffData)
    local tarElement = { target.battleData[CONST.BATTLE_DATA.ELEMENT] }
    local tarElementNew = BuffManager:forceChangeElement(target.buffData)
    local elementRate = 1
    if #atkElementNew > 0 then
        atkElement = atkElementNew
    end
    if #tarElementNew > 0 then
        tarElement = tarElementNew
    end
    for atk = 1, #atkElement do
        for tar = 1, #tarElement do
            if atkElement[atk] == CONST.ELEMENT.FIRE then
                if tarElement[tar] == CONST.ELEMENT.NATURE then
                    elementRate = elementRate + 0.3
                elseif tarElement[tar] == CONST.ELEMENT.WATER then
                    elementRate = elementRate - 0.3
                end
            elseif atkElement[atk] == CONST.ELEMENT.WATER then
                if tarElement[tar] == CONST.ELEMENT.FIRE then
                    elementRate = elementRate + 0.3
                elseif tarElement[tar] == CONST.ELEMENT.NATURE then
                    elementRate = elementRate - 0.3
                end
            elseif atkElement[atk] == CONST.ELEMENT.NATURE then
                if tarElement[tar] == CONST.ELEMENT.WATER then
                    elementRate = elementRate + 0.3
                elseif tarElement[tar] == CONST.ELEMENT.FIRE then
                    elementRate = elementRate - 0.3
                end
            elseif atkElement[atk] == CONST.ELEMENT.LIGHT then
                if tarElement[tar] == CONST.ELEMENT.DARK then
                    elementRate = elementRate + 0.3
                end
            elseif atkElement[atk] == CONST.ELEMENT.DARK then
                if tarElement[tar] == CONST.ELEMENT.LIGHT then
                    elementRate = elementRate + 0.3
                end
            end
        end
    end
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ELEMENT_RATIO]) do -- �ݩʥ[��
        local skillType, fullSkillId = self:checkSkill(v, attacker.skillData)
        if skillType == CONST.SKILL_DATA.PASSIVE then
            local params = SkillManager:calSkillSpecialParams(fullSkillId, { tarElement })
            elementRate = elementRate + params[1]
        end
    end
    return elementRate
end

--�p���z���ʵe�Ʀr��m
function NewBattleUtil:setCriDmgAni(ccb, dmg)
    local len = 0
    local dmgTable = {}
    local dmgTxt =  GameUtil:formatNumber(dmg)
    --while dmg > 0 do
    --    local tempNum = dmg % 10
    --    dmg = math.floor(dmg / 10)
    --    len = len + 1
    --    dmgTable[len] = tempNum
    --end
    len = string.len(dmgTxt)
    local count = 1
    for i = len, 1, -1 do
        local tempTxt = string.sub(dmgTxt, i, i)
        dmgTable[count] = tempTxt
        count = count + 1
    end
    for i = 1, 9 do
        local txt = ccb:getVarLabelBMFont("mNumLabel" .. i)
        txt:setString("")
    end
    local startPos = (#dmgTable == 1 and 3) or (#dmgTable == 2 and 7) or (#dmgTable == 3 and 2) or (#dmgTable == 4 and 6) or (#dmgTable == 5 and 1) or 1
    if startPos <= 0 then
        return
    end
    for i = 1, #dmgTable do
        ccb:getVarLabelBMFont("mNumLabel" .. (startPos + i - 1)):setString(dmgTable[i])
    end
    if startPos >= 5 then
        ccb:runAnimation("showNum_cri02")
    else
        ccb:runAnimation("showNum_cri01")
    end
end

--�p��|�ˤ��J�ƭ�
--digit < 0 ==> ����p�Ʀ�
function NewBattleUtil:calRoundValue(value, digit)
    if digit > 0 then
        return math.floor(value / math.pow(10, digit - 1) + 0.5) * math.pow(10, digit - 1)
    elseif digit < 0 then
        local strNum = string.format(value / math.pow(10, digit - 1))
        local result = math.floor((tonumber(strNum) + 5) * 0.1) * math.pow(10, digit)
        return result
        --return math.floor(value / math.pow(10, digit) + 0.5) * math.pow(10, digit)
    else
        return value
    end
end

--�^�Ǧs����������idx table(�䤤�@��)
function NewBattleUtil:initAliveTable(list)
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    aliveIdTable = {}
    for k, v in pairs(list) do
        if v and (CHAR_UTIL:getState(v) == CONST.CHARACTER_STATE.WAIT or CHAR_UTIL:getState(v) == CONST.CHARACTER_STATE.MOVE 
             or CHAR_UTIL:getState(v) == CONST.CHARACTER_STATE.ATTACK or CHAR_UTIL:getState(v) == CONST.CHARACTER_STATE.HURT)
             and CHAR_UTIL:isInBattleField(v) then
            table.insert(aliveIdTable, k)
        end
    end
    return aliveIdTable
end

--�ˬd�O�_���Q�ʧޯ�(���]�t�رڦ��)
function NewBattleUtil:checkSkill(skillId, skillData)
    if skillData[CONST.SKILL_DATA.PASSIVE]  then
        for k, v in pairs(skillData[CONST.SKILL_DATA.PASSIVE]) do
            if tonumber(skillId .. v.LEVEL) == k then
                return CONST.SKILL_DATA.PASSIVE, k
            end
        end
    end
    return 0, 0
end
--�ˬd�O�_���ťۧޯ�
function NewBattleUtil:checkRuneSkill(skillId, skillData)
    if skillData[CONST.SKILL_DATA.PASSIVE]  then
        for k, v in pairs(skillData[CONST.SKILL_DATA.PASSIVE]) do
            if tonumber(skillId) == k then
                return CONST.SKILL_DATA.PASSIVE, tonumber(skillId .. v.LEVEL), v.NUM
            end
        end
    end
    return 0, 0, 0
end
--�I��Q�ʧޯ�(�S��spine�ʵe���ޯ�)
function NewBattleUtil:castPassiveSkill(chaNode, skillId, resultTable, allPassiveTable, triggerType, targetTable)
    if not chaNode or not chaNode.heroNode.heroSpine then
        return false
    end
    local skillType, fullSkillId = self:checkSkill(skillId, chaNode.skillData)
    if skillType ~= CONST.SKILL_DATA.PASSIVE then  -- ����S���ӧޯ�/���O�Q�ʧޯ�
        return false
    end
    if not SkillManager:isSkillUsable(chaNode, skillType, fullSkillId, triggerType, targetTable) then
        return false    -- �ޯ�S���F��o�ʱ���
    end
    SkillManager:castSkill(chaNode, skillType, fullSkillId)
    SkillManager:runSkill(chaNode, fullSkillId, resultTable, allPassiveTable, targetTable)
    allPassiveTable[chaNode.idx] = allPassiveTable[chaNode.idx] or { }
    table.insert(allPassiveTable[chaNode.idx], CONST.PassiveLogType.SKILL .. "_" .. fullSkillId)
    return true
end
--�I��ť۳Q�ʧޯ�(�S��spine�ʵe���ޯ�)
function NewBattleUtil:castRunePassiveSkill(chaNode, skillId, resultTable, allPassiveTable, triggerType, targetTable)
    if not chaNode or not chaNode.heroNode.heroSpine then
        return false
    end
    local skillType, fullSkillId, num = self:checkRuneSkill(skillId, chaNode.runeData)
    if skillType ~= CONST.SKILL_DATA.PASSIVE then  -- ����S���ӧޯ�/���O�Q�ʧޯ�
        return false
    end
    if not SkillManager:isSkillUsable(chaNode, skillType, fullSkillId, triggerType) then
        return false    -- �ޯ�S���F��o�ʱ���
    end
    for i = 1, num do
        SkillManager:castSkill(chaNode, skillType, fullSkillId)
        SkillManager:runSkill(chaNode, fullSkillId, resultTable, allPassiveTable, targetTable)
        allPassiveTable[chaNode.idx] = allPassiveTable[chaNode.idx] or { }
        table.insert(allPassiveTable[chaNode.idx], CONST.PassiveLogType.SKILL .. "_" .. fullSkillId)
    end
    return true
end

--�I��Buff�ޯ�(�I�����bbuffmanager�ˬd)
function NewBattleUtil:castBuffSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable)
    if not chaNode or not chaNode.heroNode.heroSpine then
        return nil
    end
    return SkillManager:runBuff(chaNode, skillId, resultTable, allPassiveTable, targetTable)
end

--�s�Wbuff icon
function NewBattleUtil:addBuffIcon(node, buffId)
    local mainBuffId = math.floor(buffId / 100) % 100
    local buffIcon = CCSprite:create("Buff_" .. buffId .. ".png")
    if buffIcon then
        local buffCfg = ConfigManager:getNewBuffCfg()
        if buffCfg[buffId].gain == 1 then
            buffIcon:setTag(buffId)
            node.heroNode.buffNode:addChild(buffIcon)
        else
            buffIcon:setTag(buffId)
            node.heroNode.debuffNode:addChild(buffIcon)
        end
    end
    self:sortBuffIcon(node)
end
--���� buff icon
function NewBattleUtil:removeBuffIcon(node, buffId)
    if node.heroNode.buffNode:getChildByTag(buffId) then
        node.heroNode.buffNode:removeChildByTag(buffId, true)
    end
    if node.heroNode.debuffNode:getChildByTag(buffId) then
        node.heroNode.debuffNode:removeChildByTag(buffId, true)
    end
    self:sortBuffIcon(node)
end
--���s��zbuff icon��m
function NewBattleUtil:sortBuffIcon(node)
    local buff = node.heroNode.buffNode:getChildren()
    local isEnemy = (node.idx >= 10)
    local count = 0
    if buff then
        local children = node.heroNode.buffNode:getChildren()
        count = node.heroNode.buffNode:getChildrenCount()
        for i = 1, count do
            local child = children:objectAtIndex(i - 1)
            child:setPositionX(CONST.BUFF_ICON_SIZE * (i - 1) * (isEnemy and -1 or 1))
        end
    end
    debuff = node.heroNode.debuffNode:getChildren()
    if debuff then
        local children = node.heroNode.debuffNode:getChildren()
        count = node.heroNode.debuffNode:getChildrenCount()
        for i = 1, count do
            local child = children:objectAtIndex(i - 1)
            child:setPositionX(CONST.BUFF_ICON_SIZE * (i - 1) * (isEnemy and -1 or 1))
        end
    end
end
--����Buff spine
function NewBattleUtil:playBuffSpine(node, buffId, buffData)
    if (not NgBattleDataManager_getTestOpenBuff()) then
        return
    end
    local buffCfg = ConfigManager:getNewBuffCfg()
    local spineNameAndPos = buffCfg and common:split(buffCfg[buffId].spineName, ",") or { }
    local posType = buffCfg and common:split(buffCfg[buffId].posType, ",") or { }
    local fx4Count = 0
    for i = 1, #spineNameAndPos do
        local spineName, pos = unpack(common:split(spineNameAndPos[i], "-"))
        if spineName ~= "" then
            local offsetId = buffId
            if string.find(spineName, "FX1") or string.find(spineName, "FX_1") then
                offsetId = buffId + CONST.BUFF_ID_FX1_OFFSET
            elseif string.find(spineName, "FX2") or string.find(spineName, "FX_2") then
                offsetId = buffId + CONST.BUFF_ID_FX2_OFFSET
            elseif string.find(spineName, "FX3") or string.find(spineName, "FX_3") then
                offsetId = buffId + CONST.BUFF_ID_FX3_OFFSET
            elseif string.find(spineName, "FX4") or string.find(spineName, "FX_4") then
                -- fx4�S��B�z > �i��|���_�ƭӤ��P��m�S��
                fx4Count = fx4Count + 1
                offsetId = buffId + CONST.BUFF_ID_FX4_OFFSET + CONST.BUFF_ID_FX4_COUNT_OFFSET * fx4Count
            else
                offsetId = buffId + CONST.BUFF_ID_FX1_OFFSET
            end
            if not node.allSpineTable[offsetId] then
                local buffSpine = SpineContainer:create(CONST.BUFF_SPINE_PATH, spineName)
                local sToNode = tolua.cast(buffSpine, "CCNode")
                local spineNode = nil
                if string.find(spineName, "FX1") or string.find(spineName, "FX_1") then
                    spineNode = node.heroNode.chaCCB:getVarNode("mFrontFX")
                elseif string.find(spineName, "FX2") or string.find(spineName, "FX_2") then
                    spineNode = node.heroNode.chaCCB:getVarNode("mBackFX")
                elseif string.find(spineName, "FX3") or string.find(spineName, "FX_3") then
                    spineNode = node.floorNode
                elseif string.find(spineName, "FX4") or string.find(spineName, "FX_4") then
                    local fightNode = node.heroNode.chaCCB:getParent()
                    pos = pos or 1
                    spineNode = fightNode:getChildByTag(CONST.FX4_NODE_TAG_VALUE + tonumber(pos))
                else
                    spineNode = node.heroNode.chaCCB:getVarNode("mFrontFX")
                end
                local heroNode = tolua.cast(node.heroNode.heroSpine, "CCNode")
                sToNode:setScaleX(heroNode:getScaleX())
                spineNode:addChild(sToNode)
                node.allSpineTable[offsetId] = buffSpine
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                local offsetY = 0
                local buffCfg = ConfigManager:getNewBuffCfg()
                if tonumber(posType[i]) == CONST.BUFF_POSITION_TYPE.CENTER then
                    offsetY = node.otherData[CONST.OTHER_DATA.CFG] and node.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY or 0
                elseif tonumber(posType[i]) == CONST.BUFF_POSITION_TYPE.HEAD then
                    offsetY = node.otherData[CONST.OTHER_DATA.CFG] and node.otherData[CONST.OTHER_DATA.CFG].HeadOffsetY or 0
                end
                buffNode:setPositionY(offsetY)
            else
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                buffNode:setVisible(true)
            end
            local mainBuffId = math.floor(buffId / 100) % 1000
            if CONST.BUFF_SPINE_TYPE_DATA[mainBuffId] then
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                if CONST.BUFF_SPINE_TYPE_DATA[mainBuffId] == CONST.BUFF_SPINE_TYPE.FULL then    -- �h�ƺ��~���
                    if buffData[CONST.BUFF_DATA.COUNT] == buffCfg[buffId].max_count then
                        if not node.allSpineTable[offsetId]:isPlayingAnimation(CONST.BUFF_SPINE_ANI_NAME.WAIT, 1) then
                            node.allSpineTable[offsetId]:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
                        end
                    else
                        buffNode:setVisible(false)
                    end
                elseif CONST.BUFF_SPINE_TYPE_DATA[mainBuffId] == CONST.BUFF_SPINE_TYPE.LAYER then   -- �H�h���ܤ�
                    if buffData[CONST.BUFF_DATA.COUNT] <= buffCfg[buffId].max_count and buffData[CONST.BUFF_DATA.COUNT] > 0 then
                        local aniName = CONST.BUFF_SPINE_ANI_NAME.WAIT .. buffData[CONST.BUFF_DATA.COUNT]
                        if not node.allSpineTable[offsetId]:isPlayingAnimation(aniName, 1) then
                            node.allSpineTable[offsetId]:runAnimation(1, aniName, -1)
                        end
                    else
                        buffNode:setVisible(false)
                    end
                elseif CONST.BUFF_SPINE_TYPE_DATA[mainBuffId] == CONST.BUFF_SPINE_TYPE.REMOVE then   -- ������~����
                    buffNode:setVisible(false)
                end
            else
                if not node.allSpineTable[offsetId]:isPlayingAnimation(CONST.BUFF_SPINE_ANI_NAME.WAIT, 1) then
                    node.allSpineTable[offsetId]:setToSetupPose()
                    node.allSpineTable[offsetId]:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.BEGIN, 0)
                    node.allSpineTable[offsetId]:addAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, true)
                end
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                buffNode:setVisible(true)
            end
        end
    end
    self:playBuffColor(node, buffId)
end
--�]�wBuff color
function NewBattleUtil:playBuffColor(node, buffId)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if CONST.BUFF_COLOR[mainBuffId] then
        local rgbNode = tolua.cast(node.heroNode.heroSpine, "CCNodeRGBA")
        local color = CONST.BUFF_COLOR[mainBuffId]
        rgbNode:setColor(ccc3(color["RED"], color["GREEN"], color["BLUE"]))
        rgbNode:setOpacity(color["ALPHA"])
    end
end
--����Buff
function NewBattleUtil:removeBuff(node, buffId, isPlayEnd)
    node.buffData[buffId] = nil
    NewBattleUtil:removeBuffIcon(node, buffId)
    NewBattleUtil:removeBuffSpine(node, buffId, isPlayEnd)
    NewBattleUtil:refreshBuffEffect(node, buffId)
    NewBattleUtil:checkRemoveBuffPassive(node, buffId)

    local LOG_UTIL = require("Battle.NgBattleLogUtil")
    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.REMOVE_BUFF, node, nil, buffId, false, false, 0)
end
--����BuffĲ�o�Q�ʧޯ�
function NewBattleUtil:checkRemoveBuffPassive(node, buffId)
     -- ������Ĳ�o�Q�ʧޯ�
     local mainBuffId = math.floor(buffId / 100) % 1000
     if mainBuffId == CONST.BUFF.FRENZY then  -- �g��
         local list = NgBattleDataManager_getEnemyList(node)
         local aliveIdTable = NewBattleUtil:initAliveTable(list)
         for k2, v2 in pairs(CONST.PASSIVE_TYPE_ID[CONST.PASSIVE_TRIGGER_TYPE.ENEMY_FRENZY_REMOVE]) do -- �Ĥ�Buff������Ĳ�o�Q��
             for i = 1, #aliveIdTable do
                 local resultTable = { }
                 local allPassiveTable = { }
                 local actionResultTable = { }
                 local allTargetTable = { }
                 if NewBattleUtil:castPassiveSkill(list[aliveIdTable[i]], v2, resultTable, allPassiveTable, CONST.PASSIVE_TRIGGER_TYPE.ENEMY_FRENZY_REMOVE, { node }) then
                     local LOG_UTIL = require("Battle.NgBattleLogUtil")
                     local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
                     LOG_UTIL:setPreLog(list[aliveIdTable[i]], resultTable)
                     CHAR_UTIL:calculateAllTable(list[aliveIdTable[i]], resultTable, isSkipCal, actionResultTable, allTargetTable, v2 * 10, allPassiveTable)   -- �����ˮ`/�v��/buff...�B�z
                 end
             end
         end
     end
end
--�����S�wBuff���s�ѾlBuff�ĪG
function NewBattleUtil:refreshBuffEffect(chaNode, buffId)
    local mainBuffId = math.floor(buffId / 100) % 1000
    -- �ݭn���s�M��ؼ�
    if mainBuffId == CONST.BUFF.FRENZY then -- �g��
        --�j������ؼ�
        local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
        chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] = nil
	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] or chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    end
    if mainBuffId == CONST.BUFF.TAUNT then -- �J��
        --�j������ؼ�
        local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
        chaNode.tarArray[CONST.TARGET_TYPE.TAUNT_TARGET] = nil
	    chaNode.target = chaNode.tarArray[CONST.TARGET_TYPE.FRENZY_TARGET] or chaNode.tarArray[CONST.TARGET_TYPE.ORI_TARGET]
	    CHAR_UTIL:setState(chaNode, CONST.CHARACTER_STATE.WAIT)
    end
    if mainBuffId == CONST.BUFF.STONE or -- �ۤ�
       mainBuffId == CONST.BUFF.FREEZE or -- �ᵲ
       mainBuffId == CONST.BUFF.DIZZY then -- �w�t
        if not BuffManager:isInCrowdControl(chaNode.buffData) then -- �S���w���ĪG
            local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
            CHAR_UTIL:resetTimeScale(chaNode)
        end
    end
    if mainBuffId == CONST.BUFF.UNSTOPPABLE then -- �դ��i��
        if BuffManager:isInCrowdControl(chaNode.buffData) then -- ���w���ĪG
            -- �]�wtimescale
            --chaNode.heroNode.heroSpine:setTimeScale(0)
            CHAR_UTIL:setTimeScale(chaNode, 0)
        end
    end
end
--���񲾰�Buff�ɪ�spine
function NewBattleUtil:playRemoveSpine(chaNode, buffId)
    local mainBuffId = math.floor(buffId / 100) % 1000
    if mainBuffId == CONST.BUFF.REBIRTH then -- �j��
        -- TODO ����S��
        for i = 1, 4 do
            local offsetId = CONST.BUFF_ID_FX1_OFFSET * i + buffId
            if chaNode.allSpineTable[offsetId] then
                local buffNode = tolua.cast(chaNode.allSpineTable[offsetId], "CCNode")
                buffNode:setVisible(true)
                chaNode.allSpineTable[offsetId]:setToSetupPose()
                chaNode.allSpineTable[offsetId]:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.BEGIN, 0)
                chaNode.allSpineTable[offsetId]:addAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, false)
            end
        end
    end
end
--����Buff spine
function NewBattleUtil:removeBuffSpine(node, buffId, isPlayEnd)
    local offsetId = buffId
    for i = 1, 3 do
        if i == 1 then
            offsetId = buffId + CONST.BUFF_ID_FX1_OFFSET
        elseif i == 2 then
            offsetId = buffId + CONST.BUFF_ID_FX2_OFFSET
        elseif i == 3 then
            offsetId = buffId + CONST.BUFF_ID_FX3_OFFSET
        end
        if node.allSpineTable[offsetId] then
            if isPlayEnd then
                node.allSpineTable[offsetId]:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.END, 0)
                if not node.allSpineTable[offsetId]:isPlayingAnimation(CONST.BUFF_SPINE_ANI_NAME.END, 1) then   -- �S��END�ʵe
                    local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                    if buffNode then
                        buffNode:setVisible(false)
                        node.allSpineTable[offsetId]:setToSetupPose()
                        --buffNode:removeFromParentAndCleanup(true)
                    end
                    --node.allSpineTable[offsetId] = nil
                end
            else
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                if buffNode then
                    buffNode:setVisible(false)
                    node.allSpineTable[offsetId]:setToSetupPose()
                    --buffNode:removeFromParentAndCleanup(true)
                end
                --node.allSpineTable[offsetId] = nil
            end
        end
    end
    for i = 1, 9 do
        offsetId = buffId + CONST.BUFF_ID_FX4_OFFSET + CONST.BUFF_ID_FX4_COUNT_OFFSET * i
        if node.allSpineTable[offsetId] then
            if isPlayEnd then
                node.allSpineTable[offsetId]:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.END, 0)
                --node.allSpineTable[offsetId] = nil
                if not node.allSpineTable[offsetId]:isPlayingAnimation(CONST.BUFF_SPINE_ANI_NAME.END, 1) then   -- �S��END�ʵe
                    local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                    if buffNode then
                        buffNode:setVisible(false)
                        node.allSpineTable[offsetId]:setToSetupPose()
                        --buffNode:removeFromParentAndCleanup(true)
                    end
                    --node.allSpineTable[offsetId] = nil
                end
            else
                local buffNode = tolua.cast(node.allSpineTable[offsetId], "CCNode")
                if buffNode then
                    buffNode:setVisible(false)
                    node.allSpineTable[offsetId]:setToSetupPose()
                    --buffNode:removeFromParentAndCleanup(true)
                end
                --node.allSpineTable[offsetId] = nil
            end
        end
    end
    self:clearBuffColor(node)
end
--�٭�Buff color
function NewBattleUtil:clearBuffColor(node)
    for k, v in pairs(node.buffData) do
        local mainBuffId = math.floor(k / 100) % 1000
        if node.buffData[k] and CONST.BUFF_COLOR[mainBuffId] then
            -- �٦���Lbuff
            self:playBuffColor(node, k)
            return
        end
    end
    local rgbNode = tolua.cast(node.heroNode.heroSpine, "CCNodeRGBA")
    rgbNode:setColor(ccc3(255, 255, 255))
    rgbNode:setOpacity(255)
end
-- ������H�j�Ĥ���
function NewBattleUtil:addSingleBossScore(dmg)
    local singleBossCfg = ConfigManager.getSingleBoss()[NgBattleDataManager.SingleBossId]
    if not singleBossCfg then
        return
    end
    local ratio = singleBossCfg.rate
    NgBattleDataManager.SingleBossScore = NgBattleDataManager.SingleBossScore + dmg-- * ratio
end
-- ���o��H�j�ķ�e����
function NewBattleUtil:getSingleBossScore()
    local singleBossCfg = ConfigManager.getSingleBoss()[NgBattleDataManager.SingleBossId]
    if not singleBossCfg then
        return 0
    end
    local ratio = singleBossCfg.rate
    return math.floor(NgBattleDataManager.SingleBossScore * ratio + 0.5)
end
-- �]�w��H�j�Ĥ��Ʊ�
function NewBattleUtil:setSingleBossScoreBar(container)
    local BAR_DIS = 50
    local BAR_WIDTH = 846
    local BAR_HEIGHT = 7
    local BAR_STAGE_START_POS = { 22, 116, 210, 304, 398, 492, 586, 680, 774 }
    local STAGE_START_POS = 35
    local STAGE_DIS = 94
    local STAGE_CENTER_POS = 255
    local STAGE_MAX_MOVE = 1000 - STAGE_CENTER_POS * 2 - STAGE_START_POS
    --
    local singleBossCfg = ConfigManager.getSingleBoss()[NgBattleDataManager.SingleBossId]
    if not singleBossCfg then
        return
    end
    local ratio = singleBossCfg.rate
    local stagePoint = common:split(singleBossCfg.stagePoint, ",")
    local nextPoint = 0
    local nowPoint = math.floor(NgBattleDataManager.SingleBossScore * ratio + 0.5)
    local nowStage = 0
    for i = 1, #stagePoint do
        nextPoint = tonumber(stagePoint[i])
        if tonumber(stagePoint[i]) > nowPoint then
            break
        end
        nowStage = i
    end
    if NgBattleDataManager.SingleBossId == 999 then    -- 999 > �L����q
        NodeHelper:setStringForLabel(container, { mRewardPointTxt = GameUtil:formatDotNumber(nowPoint) })
    else
        NodeHelper:setStringForLabel(container, { mRewardPointTxt = GameUtil:formatDotNumber(nowPoint) .. "/" .. GameUtil:formatDotNumber(nextPoint) })
    end
    --
    for i = 1, #stagePoint do
        NodeHelper:setNodesVisible(container, { ["mRewardNode" .. i] = nowStage >= i })
    end
    --
    local bar = container:getVarScale9Sprite("mRewardBar")
    if nowStage >= #stagePoint then
        bar:setContentSize(CCSize(BAR_WIDTH, BAR_HEIGHT))
    elseif nowStage == 0 then
        bar:setContentSize(CCSize(0, BAR_HEIGHT))
    else
        local thisStageDis = tonumber(nextPoint) - tonumber(stagePoint[nowStage])
        local thisStageScore = nowPoint - tonumber(stagePoint[nowStage])
        local thisStagPer = thisStageScore / thisStageDis
        bar:setContentSize(CCSize(BAR_STAGE_START_POS[nowStage] + (BAR_DIS * thisStagPer), BAR_HEIGHT))
    end
    NodeHelper:setNodesVisible(container, { mRewardBar = (nowStage > 0) })
    --
    local moveNode = container:getVarNode("mMoveNode")
    if STAGE_START_POS + STAGE_DIS * (nowStage - 1) < STAGE_CENTER_POS then
        NgBattleDataManager.SingleBossBarPos = 0
        moveNode:setPositionX(0)
    elseif nowStage > 7 then
        local newPos = (STAGE_START_POS + STAGE_DIS * 7 - STAGE_CENTER_POS) * -1
        if NgBattleDataManager.SingleBossBarPos ~= newPos then
            NgBattleDataManager.SingleBossBarPos = newPos
            moveNode:stopAllActions()
            local array = CCArray:create()
            array:addObject(CCMoveTo:create(0.2, ccp(newPos, moveNode:getPositionY())))
            moveNode:runAction(CCSequence:create(array))
        end
    else
        local newPos = (STAGE_START_POS + STAGE_DIS * (nowStage - 1) - STAGE_CENTER_POS) * -1
        if NgBattleDataManager.SingleBossBarPos ~= newPos then
            NgBattleDataManager.SingleBossBarPos = newPos
            moveNode:stopAllActions()
            local array = CCArray:create()
            array:addObject(CCMoveTo:create(0.2, ccp(newPos, moveNode:getPositionY())))
            moveNode:runAction(CCSequence:create(array))
        end
    end
    --
    local bossNode = NgBattleDataManager.battleEnemyCharacter[NgBattleDataManager.SingleBossBarIdx]
    if bossNode then
        local bar = container:getVarScale9Sprite("mBossHpBar")
        if NgBattleDataManager.SingleBossId == 999 then    -- 999 > �L����q
            NodeHelper:setStringForLabel(container, { mBossHpPerTxt = "100.0%" })
            bar:setInsetLeft(5)
            bar:setInsetRight(5)
            bar:setContentSize(CCSize(400, 14))
            NodeHelper:setNodesVisible(container, { mBossHpBar = true })
        else
            local hpStr = GameUtil:formatDotNumber(math.max(0, bossNode.battleData[CONST.BATTLE_DATA.HP]))
            local maxHpStr = GameUtil:formatDotNumber(bossNode.battleData[CONST.BATTLE_DATA.MAX_HP])
            local per = math.max(0, bossNode.battleData[CONST.BATTLE_DATA.HP] / bossNode.battleData[CONST.BATTLE_DATA.MAX_HP])
            NodeHelper:setStringForLabel(container, { mBossHpPerTxt = string.format("%.1f", math.floor(per * 1000 + 0.5) / 10) .. "%" })
            
            bar:setInsetLeft((per * 400 > 5 * 2) and 5 or (per * 400 / 2))
            bar:setInsetRight((per * 400 > 5 * 2) and 5 or (per * 400 / 2))
            bar:setContentSize(CCSize(400 * math.min(1, per), 14))
            NodeHelper:setNodesVisible(container, { mBossHpBar = (per > 0) })
        end
        --NodeHelper:setStringForLabel(container, { mRewardPointTxt = hpStr .. "/" .. maxHpStr })
    end
end
local logs = {}
--�M��log
function NewBattleUtil:clearLog()
    logs = {}
end
--���olog
function NewBattleUtil:getLog()
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        local str = self:dump(logs, 1)
        --CCLuaLog(str)
        -- �H���[���覡��?�u?���
        local testFile = io.open("TEST.txt", "w")
        -- �b���̦Z�@��K�[ Lua �`?
        testFile:write(str)
    end
    return logs
end
function NewBattleUtil:getMsg(aMsg)
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        --local str = self:dump(logs, 1)
        --CCLuaLog(str)
        -- �H���[���覡��?�u?���
        --local testFile = io.open("TESTMsg.txt", "a+")
        -- �b���̦Z�@��K�[ Lua �`?
        --testFile:write(aMsg)
    end
end
--Print log
function NewBattleUtil:dump(o, layer)
    local tabStr = ""
    local tabStr2 = ""
    for i = 1, layer do
        tabStr = tabStr .. "\t"
        if i > 1 then
            tabStr2 = tabStr2 .. "\t"
        end
    end
    if type(o) == 'table' then
        local s = '{ \n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. tabStr .. '['..k..'] = ' .. self:dump(v, layer + 1) .. ',\n'
        end
        return s .. tabStr2 .. '}'
    else
        return tostring(o)
    end
end
--���Jlog target(�����ƴ��J) �^��target�O�_����
function NewBattleUtil:insertLogTarget(targetTable, target)
    for i = 1, #targetTable do
        if targetTable[i] == target then
            return true
        end
    end
    table.insert(targetTable, target)
    return false
end
--����log
--Action 1: ���� 2: �^�� 3: �^�]
function NewBattleUtil:addLog(actionType, attacker, targetList, skillId, skillGroupId, markTime, actionResultTable, passiveTable)
    --local log = {}
    ---------------------------------------------------------------------------------
    --local roleInfo = {}
    --roleInfo.posId = tonumber(attacker.idx)
    --roleInfo.action = tonumber(actionType)
    --roleInfo.skillGroupId = tonumber(skillGroupId)
    --roleInfo.skillId = skillId and tonumber(skillId) or nil
    --roleInfo.buff = {}
    --for k, v in pairs(attacker.buffData) do
    --    table.insert(roleInfo.buff, k)
    --end
    --roleInfo.nowShield = tonumber(attacker.battleData[CONST.BATTLE_DATA.PRE_SHIELD])
    --roleInfo.newShield = tonumber(attacker.battleData[CONST.BATTLE_DATA.SHIELD])
    --roleInfo.nowHp = tonumber(attacker.battleData[CONST.BATTLE_DATA.PRE_HP])
    --roleInfo.newHp = tonumber(attacker.battleData[CONST.BATTLE_DATA.HP])
    --roleInfo.nowMp = tonumber(attacker.battleData[CONST.BATTLE_DATA.PRE_MP])
    --roleInfo.newMp = tonumber(attacker.battleData[CONST.BATTLE_DATA.MP])
    --roleInfo.status = nil
    --roleInfo.passive = {}
    --if passiveTable and passiveTable[attacker.idx] then
    --    for k, v in pairs(passiveTable[attacker.idx]) do
    --        table.insert(roleInfo.passive, v)
    --    end
    --end
    --log.roleInfo = roleInfo
    ---------------------------------------------------------------------------------
    --local allTarget = {}
    --if targetList then
    --    for i = 1, #targetList do
    --        local target = {}
    --        target.posId = tonumber(targetList[i].idx)
    --        target.action = nil
    --        target.skillGroupId = nil
    --        target.skillId = nil
    --        target.buff = {}
    --        for k, v in pairs(targetList[i].buffData) do
    --            table.insert(target.buff, k)
    --        end
    --        target.nowShield = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.PRE_SHIELD])
    --        target.newShield = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.SHIELD])
    --        target.nowHp = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.PRE_HP])
    --        target.newHp = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.HP])
    --        target.nowMp = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.PRE_MP])
    --        target.newMp = tonumber(targetList[i].battleData[CONST.BATTLE_DATA.MP])
    --        target.status = tonumber(actionResultTable[i])
    --        target.passive = {}
    --        if passiveTable and passiveTable[targetList[i].idx] then
    --            for k, v in pairs(passiveTable[targetList[i].idx]) do
    --                table.insert(target.passive, v)
    --            end
    --        end
    --        table.insert(allTarget, target)
    --    end
    --end
    --log.targetRoleInfo = allTarget
    ---------------------------------------------------------------------------------
    --log.markTime = tonumber(math.floor(markTime))   -- �@��
    ---------------------------------------------------------------------------------
    --table.insert(logs, log)
end

function NewBattleUtil:printLog(attacker, target, formatStr)
    local id = #logs + 1
    local buffIdStr = ""
    for k, v in pairs(attacker.buffData) do
        buffIdStr = buffIdStr .. k .. ","
    end
    local buffIdStr2 = ""
    for k, v in pairs(target.buffData) do
        buffIdStr2 = buffIdStr2 .. k .. ","
    end
    local logStr = string.format("logId = %d,attackidx = %d ,targetidx = %d,attackBuff = %s targetBuff = %s Infor:{%s} \n",id,attacker.idx,target.idx,buffIdStr,buffIdStr2,formatStr)
    self:getMsg(logStr)
    CCLuaLog(logStr)
end
-- �p�⨤��Q�ʧޯ�W�[�ݩ�%��
function NewBattleUtil:calPassiveSkillAttrPercent(attacker, attr)
    if not attacker or not attacker.skillData[CONST.SKILL_DATA.PASSIVE_VALUE] then
        return 0
    end
    local skillCfg = ConfigManager:getSkillCfg()
    for id, data in pairs(attacker.skillData[CONST.SKILL_DATA.PASSIVE_VALUE]) do
        if skillCfg[id] then
            local addStrs = common:split(skillCfg[id].values, ",")
            for i = 1, #addStrs do
                local _attr, _type, _value = unpack(common:split(addStrs[i], "_"))
                if tonumber(_attr) == attr then
                    return _value / 10000 -- �ഫ��%
                end
            end
        end
    end
end
-- �p������ޯ�v�T���v
function NewBattleUtil:calAuraSkillRatio(chaNode, auraType)
    if not CONST.PASSIVE_TYPE_ID[auraType] then
        return 1
    end
    local ratio = 1
    local flist = NgBattleDataManager_getFriendList(chaNode)
    local elist = NgBattleDataManager_getEnemyList(chaNode)
    local aliveIdTableF = self:initAliveTable(flist)
    local aliveIdTableE = self:initAliveTable(elist)
    for k, v in pairs(CONST.PASSIVE_TYPE_ID[auraType]) do
        for i = 1, #aliveIdTableF do
            local skillType, fullSkillId = self:checkSkill(v, flist[aliveIdTableF[i]].skillData)
            if skillType == CONST.SKILL_DATA.PASSIVE then
                local params = SkillManager:calSkillSpecialParams(fullSkillId, { auraType })
                ratio = ratio + params[1]
            end
        end
        for i = 1, #aliveIdTableE do
            local skillType, fullSkillId = self:checkSkill(v, elist[aliveIdTableE[i]].skillData)
            if skillType == CONST.SKILL_DATA.PASSIVE then
                local params = SkillManager:calSkillSpecialParams(fullSkillId, { auraType })
                ratio = ratio + params[1]
            end
        end
    end
    ratio = math.max(0, ratio)
    return ratio
end