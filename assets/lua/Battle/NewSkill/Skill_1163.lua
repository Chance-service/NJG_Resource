Skill_1163 = Skill_1163 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
戰鬥開始時，賦予自身"急速I/急速II/急速III"光環(params1)
]]--
--[[
提高包含自身以及隊伍中所有英雄物理攻擊5%/7%/10%、攻擊回復10%/12%/15%(params1)
**突擊I/突擊II/突擊III
]]--
-------------------------------------------------------
function Skill_1163:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1163:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1163:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    --Get Buff
    local auraId = tonumber(params[1])
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    local buffConfig = ConfigManager:getNewBuffCfg()
    local buffId = tonumber(buffConfig[auraId].values)
    table.insert(buffTable, auraId)
    table.insert(buffTarTable, chaNode)
    table.insert(buffTimeTable, 999000 * 1000)
    table.insert(buffCountTable, 1)
    for i = 1, #aliveIdTable do
        table.insert(buffTable, buffId)
        table.insert(buffTarTable, fList[aliveIdTable[i]])
        table.insert(buffTimeTable, 999000 * 1000)
        table.insert(buffCountTable, 1)
    end
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_1163:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    return true
end

return Skill_1163