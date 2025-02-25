Skill_1090 = Skill_1090 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
恢復HP最低友方單體自身攻擊力300%/400%/500%(params1)的HP並驅散負面效果
]]--
--[[ OLD
恢復友方全體魔法攻擊力150%/180%/200%(params1)的HP並驅散負面效果，Lv3時賦予"迴光II"(params2)10秒(params3)
]]--
-------------------------------------------------------
function Skill_1090:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1090:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1090:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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

    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --施法者造成治療buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --目標受到治療buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --基礎傷害
        local baseDmg = atk * tonumber(params[1]) / hitMaxNum * buffValue * buffValue2

        local isCri = false
        --爆傷
        local criRate = 1
        isCri = NewBattleUtil:calIsCri(chaNode, target)
        if isCri then
            criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
        end
        --最終傷害(四捨五入)
        local dmg = math.floor(baseDmg * criRate + 0.5)
        --最終結果
        table.insert(healTable, dmg)
        table.insert(healTarTable, target)
        table.insert(healCriTable, isCri)
        table.insert(spClassTable, NewBattleConst.FunClassType.BUFF_MANAGER)
        table.insert(spFuncTable, "clearAllDeBuff")
        table.insert(spParamTable, { chaNode, chaNode.buffData })
        table.insert(spTarTable, chaNode)
    end
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = spClassTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = spFuncTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = spParamTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = spTarTable

    return resultTable
end

function Skill_1090:getSkillTarget(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    return SkillUtil:getLowHpTarget(chaNode, friendList, 1)
end

return Skill_1090