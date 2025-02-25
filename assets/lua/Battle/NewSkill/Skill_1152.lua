Skill_1152 = Skill_1152 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local Skill_1153 = { }
-------------------------------------------------------
--[[
賦予隨機1/2/3(parmas1)名友方"順風I/順風I/順風I"(params2)15秒(params3)
當自身有1153技能時，Lv1時額外獲得20MP(params1)、Lv2時"順風I"變為"順風II"(params2)
此技能只發動一次
]]--
-------------------------------------------------------
function Skill_1152:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1152:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1152:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
            if math.floor(k / 10) == 1153 then  -- 有1153技能時觸發額外效果
                passiveId = k
            end
        end
    end
    local allTarget = self:getSkillTarget(chaNode, skillId)

    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    local mpTable = { }
    local mpTarTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        buffId = tonumber(params[2])
        if passiveId then
            local passiveLevel = passiveId % 10
            local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
            local params2 = common:split(skillCfg2.values, ",")
            if passiveLevel >= 2 then
                buffId = tonumber(params2[2])
            end
            table.insert(mpTable, tonumber(params2[1]))
            table.insert(mpTarTable, target)
        end
        table.insert(buffTable, buffId)
        table.insert(buffTarTable, chaNode)
        table.insert(buffTimeTable, tonumber(params[3]) * 1000)
        table.insert(buffCountTable, 1)
    end

    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = mpTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = mpTarTable
    return resultTable
end

function Skill_1152:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1152:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    return SkillUtil:getRandomTarget(chaNode, friendList, tonumber(params[1]))
end

function Skill_1152:getSkillTarget2(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1152