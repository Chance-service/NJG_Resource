Skill_1022 = Skill_1022 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
友方英雄有八重螢火(params1)時，每4/3/2秒獲得5/5/5MP(params2)
]]--
-------------------------------------------------------
function Skill_1022:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1022:calSkillTarget(chaNode, skillId)
    return { chaNode }
end
function Skill_1022:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    --初始化table
    local allTarget = self:getSkillTarget(chaNode, skillId)

    for i = 1, #allTarget do
        local target = allTarget[i]

        if resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] then
            table.insert(resultTable[NewBattleConst.LogDataType.SP_GAIN_MP], tonumber(params[2]))
            table.insert(resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR], target)
        else
            resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = { tonumber(params[2]) }
            resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = { target }
        end
    end

    return resultTable
end
function Skill_1022:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    for k, v in pairs(fList) do
        if v.otherData[NewBattleConst.OTHER_DATA.ITEM_ID] == tonumber(params[1]) then
            return true
        end
    end
    return false
end

function Skill_1022:getSkillTarget(chaNode, skillId)
    return { chaNode }
end

return Skill_1022