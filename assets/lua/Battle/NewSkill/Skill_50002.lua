Skill_50002 = Skill_50002 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ۨ������z����A�ᤩ�ؼ�"�I�zI/�I�zI/�I�zI/�I�zII/�I�zII/�I�zII/�I�zIII"(params1)8��(params2)�A
�ýᤩ�ۨ�"���I/���I/���I/���II/���II/���II/���III"(params3)8/8/8/12/12/12/16��(params4)
]]--
-------------------------------------------------------
function Skill_50002:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_50002:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50002:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = targetTable[1]

    -- ���[Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[2]) * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[2]) * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
    end
    table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[3]))
    table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], chaNode)
    table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[4]) * 1000)
    table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)

    return resultTable
end

function Skill_50002:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_50002:getSkillTarget(chaNode, skillId)
    return nil
end

return Skill_50002