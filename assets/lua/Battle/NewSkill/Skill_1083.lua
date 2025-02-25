Skill_1083 = Skill_1083 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
開戰時賦予我方全體角色自身生命值15%/25%/30%(params1)的護盾
]]--
--[[ OLD
每次造成傷害時，有10%/20%/20%(params1)機率賦予該目標"沉默"(params2)2/2/3秒(params3)
]]--
-------------------------------------------------------
function Skill_1083:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1083:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1083:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)
    for i = 1, #allTarget do
        local target = allTarget[i]
        --生命
        local maxHp = chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
        -- 附加Buff
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS], NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_NAME], "addShield")
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM], { chaNode, target, math.floor(maxHp * tonumber(params[1]) + 0.5) })
            table.insert(resultTable[NewBattleConst.LogDataType.SP_FUN_TAR], target)
        else
            resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = { NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL }
            resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = { "addShield" }
            resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = { { chaNode, target, math.floor(maxHp * tonumber(params[1]) + 0.5) } }
            resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = { target }
        end
    end

    return resultTable
end
function Skill_1083:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    return true
end

function Skill_1083:getSkillTarget(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1083