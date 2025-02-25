Skill_1102 = Skill_1102 or {}

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
§K¬Ì"¿U¿N"/"¿U¿N"¡B"¨IÀq/"¿U¿N"¡B"¨IÀq"¡B"®£Äß"(params1)
]]--
-------------------------------------------------------
function Skill_1102:castSkill(chaNode, skillType, skillId)
    --¬ö¿ýskill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
function Skill_1102:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    return { }
end
function Skill_1102:calSkillSpecialParams(skillId, option)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local idTable = {}
    for i = 1, #params do
        table.insert(idTable, tonumber(params[i]))
    end
    return idTable
end

function Skill_1102:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

return Skill_1102