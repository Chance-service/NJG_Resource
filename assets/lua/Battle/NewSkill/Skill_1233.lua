Skill_1233 = Skill_1233 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
local scriptData = { }
-------------------------------------------------------
--[[
自身血量低於50%(params1)時，爆擊傷害提升50%/100%/150%(params2)
]]--
-------------------------------------------------------
function Skill_1233:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1233:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1233:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    return { }
end

function Skill_1233:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_1233:calSkillSpecialParams(skillId, option)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if not option or not option[1] or not option[1].battleData then
        return 0
    end
    local hpPercent = option[1].battleData[NewBattleConst.BATTLE_DATA.HP] / option[1].battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    if hpPercent <= tonumber(params[1]) then
        return tonumber(params[2])
    end
    return 0
end

return Skill_1233