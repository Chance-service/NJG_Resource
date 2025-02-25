Skill_1063 = Skill_1063 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
友方角色"業火"移除後，賦予該角色"餘燼I/餘燼II/餘燼III"(params1)8秒(params2)
]]--
--[[ OLD
每次爆擊後，自身獲得"業火I/業火II/業火III"(params1)1層(params2)
]]--
-------------------------------------------------------
function Skill_1063:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1063:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1063:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = targetTable[1]
    if not target then
        return resultTable
    end
    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[2]) * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[2]) * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
    end

    return resultTable
end
function Skill_1063:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_INFERNO_REMOVE then
        return false
    end
    return true
end

function Skill_1063:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1063