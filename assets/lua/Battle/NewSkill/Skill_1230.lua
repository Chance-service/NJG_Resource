Skill_1230 = Skill_1230 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�磌�z���m�O�̧C�Ĥ����y��250%/350%/450%(params1)�ˮ`�A�ۨ���"����"(params2)�ɥ��w�z��
]]--
--[[ OLD
���q�̧C�Ĥ����y���C�U250%/300%/350%(params1)�ˮ`�A�̫�@�U�ˮ`���w�����A
Lv3�ɨC��������50%(params2)���v�ˮ`�ܬ�2��(params3)
]]--
-------------------------------------------------------
function Skill_1230:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1230:calSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
    local allTarget = self:getSkillTarget(chaNode, skillId)
    return allTarget
end
function Skill_1230:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --���
        local reduction = NewBattleUtil:calReduction(chaNode, target)
        --�����O
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --�ݩʥ[��
        local elementRate = NewBattleUtil:calElementRate(chaNode, target)
        --��¦�ˮ`
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(chaNode, target, 
                                                                                 chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY], 
                                                                                 skillCfg.actionName)
        --�S��[��
        local isStealth = self:getisStealth(chaNode, skillId)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) / hitMaxNum * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --�z��
            local criRate = 1
            isCri = NewBattleUtil:calIsCri(chaNode, target)
            if isStealth or isCri then
                criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
            end
            
            --�̲׶ˮ`(�|�ˤ��J)
            local dmg = math.floor(baseDmg * criRate + 0.5)
            --�̲׵��G
            table.insert(dmgTable, dmg)
            table.insert(tarTable, target)
            table.insert(criTable, isCri)
            table.insert(weakTable, weakType)
        else
            --�̲׵��G
            table.insert(dmgTable, 0)
            table.insert(tarTable, target)
            table.insert(criTable, false)
            table.insert(weakTable, 0)
        end
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable

    return resultTable
end

function Skill_1230:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    local aliveIds = NewBattleUtil:initAliveTable(enemyList)
        
    return SkillUtil:getLowestDefEnemy(chaNode, enemyList, aliveIds, true)
end

function Skill_1230:getisStealth(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    for fullBuffId, buffData in pairs(chaNode.buffData) do
        local mainBuffId = math.floor(fullBuffId / 100) % 1000
        if mainBuffId == tonumber(params[2]) then  -- ����
            return true
        end
    end
    return false
end

return Skill_1230