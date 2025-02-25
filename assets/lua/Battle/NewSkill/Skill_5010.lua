Skill_5010 = Skill_5010 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ᤩ�Ĥ����"�z���ؤl/�z���ؤl/�z���ؤl/�z���ؤl/�z���ؤl"(params1)3��(params2)�A
�ýᤩ�ڤ����"��TI/��TI/��TI/��TI/��TI"(params3)5��(params4)
]]--
-------------------------------------------------------
function Skill_5010:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_5010:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_5010:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    local eList = NgBattleDataManager_getEnemyList(chaNode)

    resultTable = { }
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(eList)
    --Get Buff
    for i = 1, #aliveIdTable do
        local target = eList[aliveIdTable[i]]
        --if NewBattleUtil:calIsHit(chaNode, target) then
            table.insert(buffTable, tonumber(params[1]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, tonumber(params[2]) * 1000)
            table.insert(buffCountTable, 1)
        --end
    end
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    --Get Buff
    for i = 1, #aliveIdTable do
        table.insert(buffTable, tonumber(params[3]))
        table.insert(buffTarTable, fList[aliveIdTable[i]])
        table.insert(buffTimeTable, tonumber(params[4]) * 1000)
        table.insert(buffCountTable, 1)
    end

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_5010:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

return Skill_5010