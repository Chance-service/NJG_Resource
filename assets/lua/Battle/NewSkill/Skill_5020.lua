Skill_5020 = Skill_5020 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
對敵方全體造成250%/250%/250%/250%/250%(params1)傷害，並賦予"暈眩"(params2)2秒(params3)，
恢復友方全體攻擊力100%/100%/100%/100%/100%(params4)的HP，並賦予"守護I"(params5)5秒(params6)
]]--
-------------------------------------------------------
function Skill_5020:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_5020:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_5020:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    local fList = NgBattleDataManager_getFriendList(chaNode)
    local eList = NgBattleDataManager_getEnemyList(chaNode)

    resultTable = { }
    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(eList)
    --Get Buff
    for i = 1, #aliveIdTable do
        local target = eList[aliveIdTable[i]]
        --減傷
        local reduction = NewBattleUtil:calReduction(chaNode, target)
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --屬性加成
        local elementRate = NewBattleUtil:calElementRate(chaNode, target)
        --基礎傷害
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(chaNode, target, 
                                                                                 chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY], 
                                                                                 skillCfg.actionName)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) / hitMaxNum * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --爆傷
            local criRate = 1
            isCri = NewBattleUtil:calIsCri(chaNode, target)
            if isCri then
                criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
            end
            --最終傷害(四捨五入)
            local dmg = math.floor(baseDmg * criRate + 0.5)
            --最終結果
            table.insert(dmgTable, dmg)
            table.insert(tarTable, target)
            table.insert(criTable, isCri)
            table.insert(weakTable, weakType)
            table.insert(buffTable, tonumber(params[2]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, tonumber(params[3]) * 1000)
            table.insert(buffCountTable, 1)
        else
            --最終結果
            table.insert(dmgTable, 0)
            table.insert(tarTable, target)
            table.insert(criTable, false)
            table.insert(weakTable, 0)
        end
    end
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    --Get Buff
    for i = 1, #aliveIdTable do
        local target = fList[aliveIdTable[i]]
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --施法者造成治療buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --目標受到治療buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --基礎傷害
        local baseDmg = atk * tonumber(params[4]) / hitMaxNum * buffValue * buffValue2

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
        table.insert(buffTable, tonumber(params[5]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, tonumber(params[6]) * 1000)
        table.insert(buffCountTable, 1)
    end

    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_5020:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

return Skill_5020