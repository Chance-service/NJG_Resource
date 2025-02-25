Skill_1201 = Skill_1201 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
local scriptData = { }
-------------------------------------------------------
--[[ NEW
自身受到傷害後，下一次爆擊傷害提高100%/150%/200%(params1)
]]--
--[[ OLD
對自身中心橢圓形區域(w:240(params1), h:150(params2))內敵人造成150%/180%/210%(params3)傷害，
每擊中一名敵人額外回復5/5/10(params4)點MP
]]--
-------------------------------------------------------
function Skill_1201:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1201:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1201:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    
    local target = self:getSkillTarget(chaNode, skillId)

    -- 附加Buff
    if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF], tonumber(params[1]))
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TAR], target)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_TIME], 999000 * 1000)
        table.insert(resultTable[NewBattleConst.LogDataType.BUFF_COUNT], 0)
    else
        resultTable[NewBattleConst.LogDataType.BUFF] = { tonumber(params[1]) }
        resultTable[NewBattleConst.LogDataType.BUFF_TAR] = { target }
        resultTable[NewBattleConst.LogDataType.BUFF_TIME] = { 999000 * 1000 }
        resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = { 0 }
    end

    return resultTable
end
function Skill_1201:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1201:getSkillTarget(chaNode, skillId)
    return chaNode
end

return Skill_1201