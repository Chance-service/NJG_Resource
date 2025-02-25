Skill_1171 = Skill_1171 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
每次普通攻擊命中後，對該目標賦予"狂亂"(params1)1/2/3層(params2)
]]--
--[[ OLD
對攻擊力最高的敵方單體造成160%/190%/220%(params1)傷害，並賦予"狂亂"(params2)5秒(params3)，
Lv3時額外賦予該目標"強攻II"(params4)5秒(params3)
]]--
-------------------------------------------------------
function Skill_1171:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1171:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1171:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = targetTable[1]

    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], tonumber(params[2]))
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { tonumber(params[2]) }
    end

    return resultTable
end
function Skill_1171:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_1171:getSkillTarget(chaNode, skillId)
    return nil
end

return Skill_1171