Skill_1053 = Skill_1053 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
生命低於50%(params1)時賦予自身"再生I/再生II/再生III"(params2)30/30/30秒(params3)，並恢復攻擊力150%/180%/240%(params4)的HP
此技能只發動一次
]]--
--[[ OLD
開場時賦予自身"怒氣I/怒氣II/怒氣III"(params1)
]]--
-------------------------------------------------------
function Skill_1053:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1053:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1053:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    -- heal
    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local target = chaNode
    --攻擊力
    local atk = NewBattleUtil:calAtk(chaNode, target)
    --施法者造成治療buff
    local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
    --目標受到治療buff
    local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
    --基礎傷害
    local baseDmg = atk * tonumber(params[4]) * buffValue * buffValue2

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
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    table.insert(buffTable, tonumber(params[2]))
    table.insert(buffTarTable, chaNode)
    table.insert(buffTimeTable, tonumber(params[3] * 1000))
    table.insert(buffCountTable, 1)
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_1053:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    local params = common:split(skillCfg.values, ",")
    if hpPercent >= tonumber(params[1]) then
        return false
    end
    return true
end

return Skill_1053