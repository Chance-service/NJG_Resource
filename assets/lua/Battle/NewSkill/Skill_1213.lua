Skill_1213 = Skill_1213 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�԰��}�l�ɡA�ᤩ�ۨ�"�t��I/�t��II/�t��III"����(params1)
]]--
--[[ OLD
�C���y���ˮ`�ɽᤩ�ӥؼ�"�ʦLI/�ʦLII/�ʦLIII"(params1)�A
��԰��}�l�ɶ������3�A�ۨ���o"����"(params2)
]]--
-------------------------------------------------------
function Skill_1213:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1213:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1213:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --��l��table
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
function Skill_1213:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

return Skill_1213