Skill_50004 = Skill_50004 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
local triggerTable = { }
-------------------------------------------------------
--[[
�ͤ訤���z���ɡA�ᤩ�Ө���"�~��I/�~��I/�~��I/�~��II/�~��II/�~��II/�~��III"(params1)1�h(parmas2)
�԰��}�l�ɡA�ᤩ�Ĥ�Ҧ����ݩ�(parmas4)����"�T��I/�T��I/�T��I/�T��II/�T��II/�T��II/�T��III"(params3)
]]--
-------------------------------------------------------
function Skill_50004:castSkill(chaNode, skillType, skillId)
    --����skill data
    if not triggerTable[chaNode.idx] or triggerTable[chaNode.idx] ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        local skillCfg = ConfigManager:getSkillCfg()[skillId]
        chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
        chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
    end
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_50004:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50004:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local eList = NgBattleDataManager_getEnemyList(chaNode)
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    if triggerTable[chaNode.idx] == NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        for i = 1, #allTarget do
            local target = allTarget[i]
            if target.battleData[NewBattleConst.BATTLE_DATA.ELEMENT] == tonumber(params[4]) then
                table.insert(buffTable, tonumber(params[3]))
                table.insert(buffTarTable, target)
                table.insert(buffTimeTable, 999000 * 1000)
                table.insert(buffCountTable, 1)
            end
        end
    elseif triggerTable[chaNode.idx] == NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_CRI_HIT then
        local target = targetTable[1]
        if target then
            table.insert(buffTable, tonumber(params[1]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, 999000 * 1000)
            table.insert(buffCountTable, tonumber(params[2]))
        end
    end

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_50004:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        triggerTable[chaNode.idx] = triggerType
        return true
    end
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_CRI_HIT then
        triggerTable[chaNode.idx] = triggerType
        return true
    end
    return false
end

function Skill_50004:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_50004