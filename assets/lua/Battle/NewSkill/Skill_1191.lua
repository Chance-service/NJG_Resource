Skill_1191 = Skill_1191 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
賦予自身"電氣磁場I/電氣磁場II/電氣磁場III"(params1)6/7/8秒(params2)
]]--
--[[ OLD
獲得攻擊力500%/500%/1000%(params1)護盾，並賦予自身"雷電之力I/雷電之力II/雷電之力III"(params2)5秒(params3)
]]--
-------------------------------------------------------
function Skill_1191:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1191:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1191:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local target = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }

    -- 獲得Buff
    table.insert(buffTable, tonumber(params[1]))
    table.insert(buffTarTable, target)
    table.insert(buffTimeTable, tonumber(params[2]) * 1000)
    table.insert(buffCountTable, 1)

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end
function Skill_1191:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.SKILL1_TRIGGER_TYPE.NORMAL then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1191:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1191