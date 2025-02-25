Skill_50014 = Skill_50014 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
local triggerTable = { }
-------------------------------------------------------
--[[
�ۨ��s���ɡA�ħ������@����o�q���20/30/40/50/60/70/80%(params1)�B�v���q�W��20/25/30/35/40/50/60%(params2)
]]--
-------------------------------------------------------
function Skill_50014:castSkill(chaNode, skillType, skillId)
    --����skill data
    if not triggerTable[chaNode.idx] or triggerTable[chaNode.idx] ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        local skillCfg = ConfigManager:getSkillCfg()[skillId]
        chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
        chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
    end
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_50014:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50014:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    return resultTable
end

function Skill_50014:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_50014:calSkillSpecialParams(skillId, option)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if not option then
        return { 0 }
    end
    if option[1] == NewBattleConst.PASSIVE_TRIGGER_TYPE.AURA_SHIELD then
        return { tonumber(params[1]) }
    elseif option[1] == NewBattleConst.PASSIVE_TRIGGER_TYPE.AURA_HEALTH then
        return { tonumber(params[2]) }
    end
    return { 0 }
end

return Skill_50014