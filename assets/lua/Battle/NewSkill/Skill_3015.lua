Skill_3015 = Skill_3015 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
開場時賦予自身該符石Buff
]]--
-------------------------------------------------------
function Skill_3015:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillBaseId = math.floor(skillId / 10)
    chaNode.runeData[skillType][skillBaseId]["COUNT"] = chaNode.runeData[skillType][skillBaseId]["COUNT"] + 1
    chaNode.runeData[skillType][skillBaseId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_3015:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_3015:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    --Get Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], tonumber(params[2]))
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { tonumber(params[2]) }
    end
    return resultTable
end

function Skill_3015:isUsable(chaNode, skillType, skillId, triggerType)
    local skillBaseId = math.floor(skillId / 10)
    if not chaNode.runeData[skillType][skillBaseId]["COUNT"] or chaNode.runeData[skillType][skillBaseId]["COUNT"] > 0 then
        return false
    end
    return true
end

return Skill_3015