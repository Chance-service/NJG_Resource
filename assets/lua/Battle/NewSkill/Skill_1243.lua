Skill_1243 = Skill_1243 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
��ͤ�ؼЦ��`�A�ۨ��^�_30%/40%/50%(params1)HP�A����o"�L��I/�L��II/�L��III"(params2)5/6/7��(params3)
]]--
--[[ OLD
��԰��}�l�ɿ�ܼĤ訾�m�̧C���ؼнᤩ"���~I/���~I/���~II"(params1)�A�ۨ���o"�岽I/�岽II/�岽II"(params2)
]]--
-------------------------------------------------------
function Skill_1243:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1243:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1243:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    -- ���[�v��
    --�I�k�̳y���v��buff
    local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
    --�ؼШ���v��buff
    local buffValue2 = BuffManager:checkBeHealBuffValue(chaNode.buffData)
    --�v��
    local heal = chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] * tonumber(params[1]) * buffValue * buffValue2
    heal = math.floor(heal + 0.5)
    if resultTable[NewBattleConst.LogDataType.HEAL_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL], heal)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_CRI], false)
    else
        resultTable[NewBattleConst.LogDataType.HEAL] = { heal }
        resultTable[NewBattleConst.LogDataType.HEAL_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.HEAL_CRI] = { false }
    end
    -- ���[Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
    end

    return resultTable
end
function Skill_1243:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD then
        return true
    end
    return false
end

function Skill_1243:getSkillTarget(chaNode, skillId)
    return { chaNode }
end

return Skill_1243