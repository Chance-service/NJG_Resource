Skill_1062 = Skill_1062 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ͤ訤��"�~��"�����γQ�X���ɡA�ӥؼЫ�_�ۨ������O100%/150%/200%(params1)��HP
]]--
-------------------------------------------------------
function Skill_1062:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1062:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1062:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = targetTable[1]
    if not target then
        return resultTable
    end
    --�����O
    local atk = NewBattleUtil:calAtk(target)
    --�I�k�̳y���v��buff
    local buffValue = BuffManager:checkHealBuffValue(target.buffData)
    --�ؼШ���v��buff
    local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
    --��¦�ˮ`
    local baseDmg = atk * tonumber(params[1]) * buffValue * buffValue2

    local isCri = false
    --�z��
    local criRate = 1
    isCri = false--NewBattleUtil:calIsCri(target, target)
    if isCri then
        criRate = NewBattleUtil:calFinalCriDmgRate(target, target)
    end
    --�̲׶ˮ`(�|�ˤ��J)
    local dmg = math.floor(baseDmg * criRate + 0.5)
    -- ��_HP
    if resultTable[NewBattleConst.LogDataType.HEAL_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL], dmg)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_CRI], isCri)
    else
        resultTable[NewBattleConst.LogDataType.HEAL] = { dmg }
        resultTable[NewBattleConst.LogDataType.HEAL_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.HEAL_CRI] = { isCri }
    end

    return resultTable
end
function Skill_1062:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE and 
       triggerType ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_CLEAR then
        return false
    end
    return true
end

function Skill_1062:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1062