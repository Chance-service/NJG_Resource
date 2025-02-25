Skill_50013 = Skill_50013 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
自身同時有4(params1)個不同debuff時，移除我方和敵方全體全部buff&debuff
]]--
-------------------------------------------------------
function Skill_50013:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_50013:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50013:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local enemyTarget = self:getSkillTarget(chaNode, skillId)
    for i = 1, #enemyTarget do
        local target = enemyTarget[i]
        -- 移除Buff&DeBuff
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.BUFF_MANAGER)
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "clearAllBuff")
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { target, target.buffData })
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
        else
            resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.BUFF_MANAGER }
            resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "clearAllBuff" }
            resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { target, target.buffData } }
            resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { target }
        end
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.BUFF_MANAGER)
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "clearAllDeBuff")
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { target, target.buffData })
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
    end
    local friendTarget = self:getSkillTarget2(chaNode, skillId)
    for i = 1, #friendTarget do
        local target = friendTarget[i]
        -- 移除Buff&DeBuff
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.BUFF_MANAGER)
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "clearAllBuff")
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { target, target.buffData })
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
        else
            resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.BUFF_MANAGER }
            resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "clearAllBuff" }
            resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { target, target.buffData } }
            resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { target }
        end
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.BUFF_MANAGER)
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "clearAllDeBuff")
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { target, target.buffData })
        table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
    end

    return resultTable
end

function Skill_50013:isUsable(chaNode, skillType, skillId, triggerType)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local buffConfig = ConfigManager:getNewBuffCfg()
    local params = common:split(skillCfg.values, ",")
    local targetNum = tonumber(params[1])
    local counter = 0
    for k, v in pairs(chaNode.buffData) do  -- 記錄所有可驅散的buff
        local cfg = buffConfig[k]
        if cfg.gain == 0 and cfg.visible == 1 then   -- debuff&可見
            counter = counter + 1
        end
    end
    return counter >= targetNum
end

function Skill_50013:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

function Skill_50013:getSkillTarget2(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_50013