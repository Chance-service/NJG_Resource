Skill_1032 = Skill_1032 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = {}
-------------------------------------------------------
--[[ NEW
開場時施放"精準II/精準II柳影II/精準II柳影II鼓舞II"光環(params1)，
當自身有1033技能時，lv1提升精準II至精準III、lv2額外提升柳影II至柳影III、lv3額外提升鼓舞II至鼓舞III
]]--
--[[ OLD
提高包含自身以及隊伍中所有英雄攻擊、防禦、爆擊、命中、閃避、攻擊回復5%/7%/10%(params1)
**敏銳I/敏銳II/敏銳III
]]--
-------------------------------------------------------
function Skill_1032:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1032:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1032:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local fList = NgBattleDataManager_getFriendList(chaNode)
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(fList)
    -- 額外效果技能id
    local passiveId = nil
    if chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE] then
        for k, v in pairs(chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE]) do
            if math.floor(k / 10) == 1033 then  -- 有1033技能時觸發額外效果
                passiveId = k
            end
        end
    end
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #params do
        local auraId = tonumber(params[i])
        if passiveId then
            local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
            local params2 = common:split(skillCfg2.values, ",")
            auraId = tonumber(params2[i]) or auraId
        end
        local buffConfig = ConfigManager:getNewBuffCfg()
        local buffId = tonumber(buffConfig[auraId].values)
        table.insert(buffTable, auraId)
        table.insert(buffTarTable, chaNode)
        table.insert(buffTimeTable, 999000 * 1000)
        table.insert(buffCountTable, 1)
        for i = 1, #aliveIdTable do
            table.insert(buffTable, buffId)
            table.insert(buffTarTable, fList[aliveIdTable[i]])
            table.insert(buffTimeTable, 999000 * 1000)
            table.insert(buffCountTable, 1)
        end
    end
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_1032:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    return true
end

return Skill_1032