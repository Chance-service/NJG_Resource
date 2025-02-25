Skill_1120 = Skill_1120 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
恢復生命最低的1/2/3名(params1)友方目標自身攻擊力180%/220%/260%(params2)的HP，並賦予"冰牆"(params3)3層(params4)
]]--
--[[ OLD
恢復自身最大生命值10%(params1)的HP，並賦予全部友方目標"再生II/再生III/再生IV"(params2)5秒(params3)
]]--
-------------------------------------------------------
function Skill_1120:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1120:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1120:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --施法者造成治療buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --目標受到治療buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --基礎傷害
        local baseDmg = atk * tonumber(params[2]) / hitMaxNum * buffValue * buffValue2

        local isCri = false
        --爆傷
        local criRate = 1
        isCri = NewBattleUtil:calIsCri(chaNode, target)
        if isCri then
            criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
        end
        --最終傷害(四捨五入)
        local dmg = math.floor(baseDmg * criRate + 0.5)

        table.insert(healTable, dmg)
        table.insert(healTarTable, target)
        table.insert(healCriTable, isCri)
        table.insert(buffTable, tonumber(params[3]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, 999 * 1000)
        table.insert(buffCountTable, tonumber(params[4]))
    end
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1120:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    return SkillUtil:getLowHpTarget(chaNode, NgBattleDataManager_getFriendList(chaNode), tonumber(params[1]))
end

return Skill_1120