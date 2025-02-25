Skill_1041 = Skill_1041 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
獲得失去生命值50%/60%/80%(params1)護盾
]]--
--[[
獲得最大生命20%/25%/30%(params1)護盾，且"嘲諷"(params2)敵方全體5/5/7秒(params3)
]]--
-------------------------------------------------------
function Skill_1041:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1041:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1041:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    --aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    --local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }

    table.insert(spClassTable, NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
    table.insert(spFuncTable, "addShield")
    local loseHp = chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] - chaNode.battleData[NewBattleConst.BATTLE_DATA.HP]
    table.insert(spParamTable, { chaNode, chaNode, math.floor(loseHp * tonumber(params[1]) + 0.5) })
    table.insert(spTarTable, chaNode)
    resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = spClassTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = spFuncTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = spParamTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = spTarTable

    return resultTable
end
function Skill_1041:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.SKILL1_TRIGGER_TYPE.NORMAL then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1041:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    local tar = { }
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            table.insert(tar, enemyList[aliveIdTable[i]])
        end
    end
    
    return tar
end

return Skill_1041