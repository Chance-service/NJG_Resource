Skill_1171 = Skill_1171 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�C�����q�����R����A��ӥؼнᤩ"�g��"(params1)1/2/3�h(params2)
]]--
--[[ OLD
������O�̰����Ĥ����y��160%/190%/220%(params1)�ˮ`�A�ýᤩ"�g��"(params2)5��(params3)�A
Lv3���B�~�ᤩ�ӥؼ�"�j��II"(params4)5��(params3)
]]--
-------------------------------------------------------
function Skill_1171:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1171:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1171:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = targetTable[1]

    -- ���[Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], tonumber(params[2]))
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { tonumber(params[2]) }
    end

    return resultTable
end
function Skill_1171:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_1171:getSkillTarget(chaNode, skillId)
    return nil
end

return Skill_1171