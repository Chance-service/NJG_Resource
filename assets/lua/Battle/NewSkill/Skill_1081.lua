Skill_1081 = Skill_1081 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
對"凍傷"狀態的目標，額外造成60%/80%/100無視防禦傷害
]]--
--[[ OLD
對當前目標造成200%/220%/240%(params1)傷害，並賦予目標"受傷I/受傷I/受傷II"(params2)5秒(params3)
]]--
-------------------------------------------------------
function Skill_1081:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1081:calSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
    local allTarget = self:getSkillTarget(chaNode, skillId)
    return allTarget
end
function Skill_1081:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    return { }
end
function Skill_1081:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_1081:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    return { chaNode.target }
end

function Skill_1081:calSkillSpecialParams(skillId, option)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if not option or not option[1] or not option[1].buffData then
        return { 0 }
    end
    for k, v in pairs(option[1].buffData) do
        local mainBuffId = math.floor(k / 100) % 1000
        if mainBuffId == tonumber(params[1]) then
            return { tonumber(params[2]) }
        end
    end
    return { 0 }
end

return Skill_1081