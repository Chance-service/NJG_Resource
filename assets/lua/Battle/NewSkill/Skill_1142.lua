Skill_1142 = Skill_1142 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
攻擊生命低於35%/45%/55%(params1)以下的目標時，額外造成50%/60%/70%傷害
]]--
-------------------------------------------------------
function Skill_1142:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1142:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1142:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    return { }
end
function Skill_1142:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_1142:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    return { chaNode.target }
end

function Skill_1142:calSkillSpecialParams(skillId, option)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if not option or not option[1] or not option[1].battleData then
        return 1
    end
    local hpPercent = option[1].battleData[NewBattleConst.BATTLE_DATA.HP] / option[1].battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    if hpPercent <= tonumber(params[1]) then
        return 1 + tonumber(params[2])
    end
    return 1
end

return Skill_1142