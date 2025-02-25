Skill_1242 = Skill_1242 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
當戰鬥開始時對敵方全體賦予"禁療I/禁療I/禁療II"(params1)，對自身以外我方全體賦予"血祭I/血祭II/血祭II"(params2)
]]--
-------------------------------------------------------
function Skill_1242:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1242:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1242:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    -- 敵方
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)
    for i = 1, #allTarget do
        local target = allTarget[i]
        -- 附加Buff
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
    -- 友方
    local allTarget2 = self:getSkillTarget2(chaNode, skillId)
    for i = 1, #allTarget2 do
        local target = allTarget2[i]
        if target.idx ~= chaNode.idx then   -- 自身除外
            -- 附加Buff
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