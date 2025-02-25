Skill_11701 = Skill_11701 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
敵方角色"狂亂"移除或被驅散時，恢復隨機2/2/2名(params1)友方自身攻擊力140%/160%/180%(params2)的HP
]]--
-------------------------------------------------------
function Skill_11701:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_11701:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_11701:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local allTarget = self:getSkillTarget(chaNode, skillId)
     for i = 1, #allTarget do
        local target = allTarget[i]
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode)
        --施法者造成治療buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --目標受到治療buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --基礎傷害
        local baseDmg = atk * tonumber(params[2]) * buffValue * buffValue2

        local isCri = false
        --爆傷
        local criRate = 1
        isCri = false--NewBattleUtil:calIsCri(target, target)
        if isCri then
            criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
        end
        --最終傷害(四捨五入)
        local dmg = math.floor(baseDmg * criRate + 0.5)
        -- 恢復HP
        if resultTable[NewBattleConst.LogDataType.HEAL_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.HEAL], dmg)
            table.insert(resultTable[NewBattleConst.LogDataType.HEAL_TAR], target)
            table.insert(resultTable[NewBattleConst.LogDataType.HEAL_CRI], isCri)
        else
            resultTable[NewBattleConst.LogDataType.HEAL] = { dmg }
            resultTable[NewBattleConst.LogDataType.HEAL_TAR] = { target }
            resultTable[NewBattleConst.LogDataType.HEAL_CRI] = { isCri }
        end
    end

    return resultTable
end
function Skill_11701:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.PASSIVE_TRIGGER_TYPE.ENEMY_FRENZY_REMOVE then
        return false
    end
    return true
end

function Skill_11701:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    return SkillUtil:getRandomTarget(chaNode, friendList, tonumber(params[1]))
end

return Skill_11701