Skill_1141 = Skill_1141 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
普通攻擊命中3/3/2次(params1)後，賦予自身"順風I/順風II/順風III"(params2)5秒(params3)"X/暴風II/暴風III"(params4)5秒(params5)
]]--
--[[ OLD
對當前目標造成每下50%/60%/70%(params1)傷害，最後一擊時無視防禦
Lv3時每一擊都無視防禦
]]--
-------------------------------------------------------
function Skill_1141:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1141:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1141:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local allTarget = { chaNode }
    for i = 1, #allTarget do
        local target = allTarget[i]
        -- 附加Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            if params[4] then
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[4]))
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[5]) * 1000)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            end
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
            if params[4] then
                resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[4]) }
                resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
                resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[5]) * 1000 }
                resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
            end
        end
    end

    return resultTable
end
function Skill_1141:isUsable(chaNode, skillType, skillId, triggerType)
    chaNode.skillData[skillType][skillId]["COUNTER"] = chaNode.skillData[skillType][skillId]["COUNTER"] and chaNode.skillData[skillType][skillId]["COUNTER"] + 1 or 1
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if chaNode.skillData[skillType][skillId]["COUNTER"] < tonumber(params[1]) then
        return false
    end
    chaNode.skillData[skillType][skillId]["COUNTER"] = 0
    return true
end

return Skill_1141