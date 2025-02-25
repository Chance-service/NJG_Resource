Skill_50012 = Skill_50012 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�H������2/2/2/2/3/3/�Ĥ����(params1)���W���N1/1/2/2/2/2/2(params2)�ӼW�q�ĪG�B
�ýᤩ�ڤ����"�@��II"(params3)8��(params4)
]]--
-------------------------------------------------------
function Skill_50012:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_50012:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50012:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local buffTarget = self:getSkillTarget2(chaNode, skillId)
    local clearTarget = self:getSkillTarget(chaNode, skillId)

    for i = 1, #buffTarget do
        local target = buffTarget[i]
        -- ���[Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[3]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[4]) * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[3]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[4]) * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
        end
    end
    for i = 1, #clearTarget do
        local target = clearTarget[i]
        -- ����Buff
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.BUFF_MANAGER)
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "clearRandomBuffByNum")
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { target, target.buffData, tonumber(params[2]) })
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
        else
            resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.BUFF_MANAGER }
            resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "clearRandomBuffByNum" }
            resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { target, target.buffData, tonumber(params[2]) } }
            resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { target }
        end
    end

    return resultTable
end

function Skill_50012:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_50012:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")

    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getRandomTarget(chaNode, enemyList, tonumber(params[1]))
end

function Skill_50012:getSkillTarget2(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_50012