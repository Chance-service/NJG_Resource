Skill_1112 = Skill_1112 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
友方英雄有水野Shizuku(params1)時，賦予隨機目標"破防I/破防II/破防III"(params2)8/10/12秒(params3)、"破魔I/破魔II/破魔III"(params4)8/10/12秒(params5)
]]--
-------------------------------------------------------
function Skill_1112:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1112:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1112:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    --初始化table
    local allTarget = self:getSkillTarget(chaNode, skillId)

    for i = 1, #allTarget do
        local target = allTarget[i]

        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[4]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[5]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]), tonumber(params[4]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target, target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000, tonumber(params[5]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1, 1 }
        end
    end

    return resultTable
end
function Skill_1112:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    for k, v in pairs(fList) do
        if v.otherData[NewBattleConst.OTHER_DATA.ITEM_ID] == tonumber(params[1]) then
            return true
        end
    end
    return false
end

function Skill_1112:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    return SkillUtil:getRandomTarget(chaNode, enemyList, 1)
end

return Skill_1112