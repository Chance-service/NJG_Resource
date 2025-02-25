Skill_1043 = Skill_1043 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
local triggerTable = { }
-------------------------------------------------------
--[[ NEW
�}���ɽᤩ�ۨ�"���}"(params1)�A�ͩR�C��15%/10%/5%(params2)�ɽᤩ�ۨ�"�L��"(params3)5/7/9��(params4)�A
���ޯ�u�o�ʤ@��
]]--
--[[ OLD
�ͩR�C��50%(params1)�ɽᤩ�ۨ�"��uII/��uIII/��uIII"(params2)10��(params3)�ALv3���X���ۨ�����Debuff�A
���ޯ�u�o�ʤ@��
]]--
-------------------------------------------------------
function Skill_1043:castSkill(chaNode, skillType, skillId)
    --����skill data
    if not triggerTable[chaNode.idx] or triggerTable[chaNode.idx] ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        local skillCfg = ConfigManager:getSkillCfg()[skillId]
        chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
        chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
    end
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1043:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1043:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    if triggerTable[chaNode.idx] == NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        table.insert(buffTable, tonumber(params[1]))
        table.insert(buffTarTable, chaNode)
        table.insert(buffTimeTable, 999000 * 1000)
        table.insert(buffCountTable, 1)
    else
        table.insert(buffTable, tonumber(params[3]))
        table.insert(buffTarTable, chaNode)
        table.insert(buffTimeTable, tonumber(params[4] * 1000))
        table.insert(buffCountTable, 1)
    end

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1043:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        triggerTable[chaNode.idx] = triggerType
        return true
    end
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    local params = common:split(skillCfg.values, ",")
    if hpPercent >= tonumber(params[2]) then
        return false
    end
    triggerTable[chaNode.idx] = triggerType
    return true
end

return Skill_1043