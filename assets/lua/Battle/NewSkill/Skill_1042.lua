Skill_1042 = Skill_1042 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ͩR�C��50%/60%/70%(params1)�ɽᤩ�ۨ�"�Z�iI/�Z�iII/�Z�iIII"(params2)15��(params3)
]]--
-------------------------------------------------------
function Skill_1042:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1042:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1042:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
    table.insert(buffTable, tonumber(params[2]))
    table.insert(buffTarTable, chaNode)
    table.insert(buffTimeTable, tonumber(params[3] * 1000))
    table.insert(buffCountTable, 1)

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1042:isUsable(chaNode, skillType, skillId, triggerType)
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

return Skill_1042