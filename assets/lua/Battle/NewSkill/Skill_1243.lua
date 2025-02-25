Skill_1243 = Skill_1243 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
當友方目標死亡，自身回復30%/40%/50%(params1)HP，並獲得"無雙I/無雙II/無雙III"(params2)5/6/7秒(params3)
]]--
--[[ OLD
當戰鬥開始時選擇敵方防禦最低的目標賦予"祭品I/祭品I/祭品II"(params1)，自身獲得"血祭I/血祭II/血祭II"(params2)
]]--
-------------------------------------------------------
function Skill_1243:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1243:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1243:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    -- 附加治療
    --施法者造成治療buff
    local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
    --目標受到治療buff
    local buffValue2 = BuffManager:checkBeHealBuffValue(chaNode.buffData)
    --治療
    local heal = chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] * tonumber(params[1]) * buffValue * buffValue2
    heal = math.floor(heal + 0.5)
    if resultTable[NewBattleConst.LogDataType.HEAL_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL], heal)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.HEAL_CRI], false)
    else
        resultTable[NewBattleConst.LogDataType.HEAL] = { heal }
        resultTable[NewBattleConst.LogDataType.HEAL_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.HEAL_CRI] = { false }
    end
    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[2]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], chaNode)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], tonumber(params[3]) * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 1)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[2]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { chaNode }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { tonumber(params[3]) * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 1 }
    end

    return resultTable
end
function Skill_1243:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.FRIEND_DEAD then
        return true
    end
    return false
end

function Skill_1243:getSkillTarget(chaNode, skillId)
    return { chaNode }
end

return Skill_1243