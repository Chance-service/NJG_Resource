Skill_1141 = Skill_1141 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
���q�����R��3/3/2��(params1)��A�ᤩ�ۨ�"����I/����II/����III"(params2)5��(params3)"X/�ɭ�II/�ɭ�III"(params4)5��(params5)
]]--
--[[ OLD
���e�ؼгy���C�U50%/60%/70%(params1)�ˮ`�A�̫�@���ɵL�����m
Lv3�ɨC�@�����L�����m
]]--
-------------------------------------------------------
function Skill_1141:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1141:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1141:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local allTarget = { chaNode }
    for i = 1, #allTarget do
        local target = allTarget[i]
        -- ���[Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            if params[4] then
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[4]))
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[5]) * 1000)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            end
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
            if params[4] then
                resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[4]) }
                resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
                resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[5]) * 1000 }
                resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
            end
        end
    end

    return resultTable
end
function Skill_1141:isUsable(chaNode, skillType, skillId, triggerType)
    chaNode.skillData[skillType][skillId]["COUNTER"] = chaNode.skillData[skillType][skillId]["COUNTER"] and chaNode.skillData[skillType][skillId]["COUNTER"] + 1 or 1
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if chaNode.skillData[skillType][skillId]["COUNTER"] < tonumber(params[1]) then
        return false
    end
    chaNode.skillData[skillType][skillId]["COUNTER"] = 0
    return true
end

return Skill_1141