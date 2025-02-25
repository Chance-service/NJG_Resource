Skill_1073 = Skill_1073 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
生命低於50%(params1)時賦予自身"荊棘I/荊棘II/荊棘III"(params2)15/20/30秒(params3)
]]--
--[[ OLD
受到攻擊時有20%(params1)機率回復生命值最低的1位友方，為其恢復攻擊力200%/250%/250%(params2)的HP，並賦予"堅守I/堅守II/堅守II"(params3)5/5/10秒(params4)
]]--
-------------------------------------------------------
function Skill_1073:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1073:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1073:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    local allTarget = self:getSkillTarget(chaNode, skillId)

    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --最終結果
        table.insert(buffTable, tonumber(params[2]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, tonumber(params[3]) * 1000)
        table.insert(buffCountTable, 1)
    end
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1073:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local prePer = chaNode.battleData[NewBattleConst.BATTLE_DATA.PRE_HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    local params = common:split(skillCfg.values, ",")
    if prePer > tonumber(params[1]) and hpPercent <= tonumber(params[1]) then
        return true
    end
    return false
end

function Skill_1073:getSkillTarget(chaNode, skillId)
    return { chaNode }
end

return Skill_1073