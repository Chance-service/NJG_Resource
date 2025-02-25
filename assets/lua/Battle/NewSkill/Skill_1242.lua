Skill_1242 = Skill_1242 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
��԰��}�l�ɹ�Ĥ����ᤩ"�T��I/�T��I/�T��II"(params1)�A��ۨ��H�~�ڤ����ᤩ"�岽I/�岽II/�岽II"(params2)
]]--
-------------------------------------------------------
function Skill_1242:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1242:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1242:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    -- �Ĥ�
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)
    for i = 1, #allTarget do
        local target = allTarget[i]
        -- ���[Buff
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
            table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
        else
            resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
            resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
            resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
        end
    end
    -- �ͤ�
    local allTarget2 = self:getSkillTarget2(chaNode, skillId)
    for i = 1, #allTarget2 do
        local target = allTarget2[i]
        if target.idx ~= chaNode.idx then   -- �ۨ����~
            -- ���[Buff
            if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
                table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
            else
                resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
                resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
                resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
                resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
            end
        end
    end

    return resultTable
end
function Skill_1242:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.START_BATTLE then
        return true
    end
    return false
end

function Skill_1242:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    local aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

function Skill_1242:getSkillTarget2(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    local aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1242