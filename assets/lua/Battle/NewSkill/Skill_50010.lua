Skill_50010 = Skill_50010 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
���e�Ĥ����y��150%(params1)�ˮ`�A���������w�z��
]]--
-------------------------------------------------------
function Skill_50010:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_50010:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50010:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    local fList = NgBattleDataManager_getFriendList(chaNode)
    local eList = NgBattleDataManager_getEnemyList(chaNode)

    resultTable = { }
    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(eList)
    local allTarget = self:getSkillTarget(chaNode, skillId)

    --Get Buff
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
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) / hitMaxNum * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --�z��
            local criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
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

function Skill_50010:isUsable(chaNode, skillType, skillId, triggerType)
    return (chaNode.target ~= nil)
end

function Skill_50010:getSkillTarget(chaNode, skillId)
    return { chaNode.target }
end

return Skill_50010