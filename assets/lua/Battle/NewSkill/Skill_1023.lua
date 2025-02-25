Skill_1023 = Skill_1023 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
���q�����R����A��30%/50%/100%(params1)���v�ᤩ"�U�N"(params2)5��(params3)1/2/3�h(params4)�A��"�U�N"�����ؼ��B�~�y��30%(params5)�ˮ`
]]--
--[[ OLD
�ޯ�y���ˮ`���ؼ��B�~�ᤩ"�ۤ�"(params1)3/5/5��(params2)�ALv3�B�~�ᤩ"�w�t"(params3)5��(params4)
]]--
-------------------------------------------------------
function Skill_1023:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1023:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1023:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local allTarget = targetTable
    for i = 1, #allTarget do
        local target = allTarget[i]
        -- ���[Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], tonumber(params[4]))
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { tonumber(params[4]) }
        end
    end

    return resultTable
end
function Skill_1023:isUsable(chaNode, skillType, skillId, triggerType)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local rand = math.random(1, 100)
    if rand > tonumber(params[1]) * 100 then
        return false
    end
    return true
end

return Skill_1023