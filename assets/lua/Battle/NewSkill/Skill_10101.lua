Skill_10101 = Skill_10101 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
普通攻擊"燃燒"(params2)中的目標命中後，有12%/18%/24%(params1)機率賦予自身"蠻勇III"(params3)12秒(params4)
]]--
-------------------------------------------------------
function Skill_10101:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_10101:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_10101:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[3]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[4]) * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[3]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[4]) * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
    end

    return resultTable
end
function Skill_10101:isUsable(chaNode, skillType, skillId, triggerType, targetTable)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local rand = math.random(1, 100)
    if rand > tonumber(params[1]) * 100 then
        return false
    end
    for i = 1, #targetTable do
        local target = targetTable[i]
        local buff = target.buffData  -- 目標的Buff
        if buff then
            for fullBuffId, buffData in pairs(buff) do
                local mainBuffId = math.floor(fullBuffId / 100) % 1000
                if mainBuffId == tonumber(params[2]) then  -- 燃燒
                    return true
                end
            end
        end
    end
    return false
end

return Skill_10101