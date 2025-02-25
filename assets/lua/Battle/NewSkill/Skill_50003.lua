Skill_50003 = Skill_50003 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
普攻時有50%(params4)機率對目標中心橢圓形區域(w:30(params1), h:30(params2))內敵人造成相同傷害，最多額外傷害2名(params3)目標
]]--
-------------------------------------------------------
function Skill_50003:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_50003:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_50003:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")

    if not targetTable[1] then
        return resultTable
    end
    
    local allTarget = self:getSkillTarget(targetTable[1], skillId)

    local dmg = 0
    for i = 1, #resultTable[NewBattleConst.LogDataType.DMG_TAR] do
        if targetTable[1] == resultTable[NewBattleConst.LogDataType.DMG_TAR][i] then
            dmg = resultTable[NewBattleConst.LogDataType.DMG][i]
            break
        end
    end

    -- 附加傷害
    local maxCount = tonumber(params[3])
    local counter = 0
    for i = 1, #allTarget do
        if counter >= maxCount then
            break
        end
        local target = allTarget[i]
        if not target then
            break
        end
        if target ~= targetTable[1] then
            if resultTable[NewBattleConst.LogDataType.DMG_TAR] then
                table.insert(resultTable[NewBattleConst.LogDataType.DMG], dmg)
                table.insert(resultTable[NewBattleConst.LogDataType.DMG_TAR], target)
                table.insert(resultTable[NewBattleConst.LogDataType.DMG_CRI], false)
                table.insert(resultTable[NewBattleConst.LogDataType.DMG_WEAK], -1)
            end
            counter = counter + 1
        end
    end

    return resultTable
end

function Skill_50003:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType == NewBattleConst.PASSIVE_TRIGGER_TYPE.AE_ATK_HIT then
        local skillCfg = ConfigManager:getSkillCfg()[skillId]
        local params = common:split(skillCfg.values, ",")
        local rand = math.random(1, 100)
        if rand > tonumber(params[4]) * 100 then
            return false
        end
        return true
    end
    return false
end

function Skill_50003:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))

    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ELLIPSE_2, { x = tonumber(params[1]), y = tonumber(params[2]) })
end

return Skill_50003