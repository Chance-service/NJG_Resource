Skill_1183 = Skill_1183 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
施放"羽翼紛飛"(skill_1180)目標不是自身時，如果自身血量低於30%/50%/50%(params1)，自身也能獲得相同治療量，
Lv3時額外獲得自身血量30%(params2)護盾
]]--
-------------------------------------------------------
function Skill_1183:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1183:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1183:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = self:getSkillTarget(chaNode, skillId)

    -- 附加治療
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    if resultTable[NewBattleConst.LogDataType.HEAL_TAR] and 
       hpPercent <= tonumber(params[1]) and -- HP條件
       resultTable[NewBattleConst.LogDataType.HEAL_TAR][1].idx ~= target.idx then   -- 不是自己
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL], resultTable[NewBattleConst.LogDataType.HEAL][1])
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_CRI], resultTable[NewBattleConst.LogDataType.HEAL_CRI][1])
    end
    -- 附加效果
    if skillLevel >= 3 then
        local shield = math.floor(tonumber(params[2]) * chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] + 0.5)
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "addShield")
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { chaNode, chaNode, shield })
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], chaNode)
        else
            resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL }
            resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "addShield" }
            resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { chaNode, chaNode, shield } }
            resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { chaNode }
        end
    end
    return resultTable
end

function Skill_1183:isUsable(chaNode, skillType, skillId, triggerType)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    if hpPercent > tonumber(params[1]) and skillLevel < 3 then
        return false
    end

    return true
end

function Skill_1183:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1183