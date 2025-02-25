Skill_1070 = Skill_1070 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
我方全體角色賦予施法者生命值15%/20%/25%(params1)的護盾，並賦予"堅守I/堅守II/堅守III"(params2)6/8/10秒(params3)
]]--
--[[ OLD
對敵方全體造成130%/150%/170%(params1)傷害，並賦予我方角色造成傷害總和50%/50%/50%(params2)的護盾，
Lv2以上時賦予敵方角色"嘲諷"(params3)3/6秒(params4)
]]--
-------------------------------------------------------
function Skill_1070:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1070:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1070:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)
    resultTable = { }

    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }

    local maxHp = chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    for i = 1, #allTarget do
        local target = allTarget[i]

        table.insert(buffTable, tonumber(params[2]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, tonumber(params[3]) * 1000)
        table.insert(buffCountTable, 1)
        table.insert(spClassTable, NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
        table.insert(spFuncTable, "addShield")
        table.insert(spParamTable, { chaNode, target, math.floor(maxHp * tonumber(params[1]) + 0.5) })
        table.insert(spTarTable, target)
    end

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = spClassTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = spFuncTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = spParamTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = spTarTable

    return resultTable
end

function Skill_1070:getSkillTarget(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1070