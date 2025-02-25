Skill_1072 = Skill_1072 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
自身獲得生命值10%/15%/20%(params1)護盾
]]--
-------------------------------------------------------
function Skill_1072:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1072:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1072:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }
    
    local target = self:getSkillTarget(chaNode, skillId)
    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
        table.insert(spClassTable, NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
        table.insert(spFuncTable, "addShield")
        table.insert(spParamTable, { chaNode, chaNode, math.floor(chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] * tonumber(params[1]) + 0.5) })
        table.insert(spTarTable, chaNode)
    else
        resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL }
        resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "addShield" }
        resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { chaNode, chaNode, math.floor(chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] * tonumber(params[1]) + 0.5) } }
        resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { chaNode }
    end

    return resultTable
end
function Skill_1072:isUsable(chaNode, skillType, skillId, triggerType)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1072:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1072