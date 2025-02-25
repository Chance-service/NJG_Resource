Skill_1011 = Skill_1011 or {}

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = {}
-------------------------------------------------------
--[[ NEW
對自身中心橢圓形區域(w:240(params1), h:150(params2))內敵人賦予"燃燒"(params3)1/2/3層(params4)5秒(params5)，並回復自身15/20/25MP(params6)
]]--
--[[ OLD
對自身中心橢圓形區域(w:240(params1), h:150(params2))內敵人造成200%/250%/300%(params3)傷害，
Lv3時賦予"暈眩"(params4)2秒(params5)
]]--
-------------------------------------------------------
function Skill_1011:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1011:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1011:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    local mpTable = { }
    local mpTarTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        table.insert(buffTable, tonumber(params[3]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, tonumber(params[5]) * 1000)
        table.insert(buffCountTable, tonumber(params[4]))
    end
    table.insert(mpTable, tonumber(params[6]))
    table.insert(mpTarTable, chaNode)
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = mpTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = mpTarTable

    return resultTable
end
function Skill_1011:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.SKILL1_TRIGGER_TYPE.NORMAL then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1011:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)

    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ELLIPSE_2, { x = tonumber(params[1]), y = tonumber(params[2]) })
end

return Skill_1011