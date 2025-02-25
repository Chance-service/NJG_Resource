SkillManager = SkillManager or { }

local CONST = require("Battle.NewBattleConst")
local LOG_UTIL = require("Battle.NgBattleLogUtil")
require("NodeHelper")
-------------------------------------------------------------------------------------------
-- SKILL
-------------------------------------------------------------------------------------------
function SkillManager:isSkillUsable(chaNode, skillType, skillId, triggerType, targetTable)
    if not skillId then
        return false
    end
    local baseSkillId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseSkillId .. ".lua") then
    --    return false
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseSkillId)
    return scripe["isUsable"] and scripe:isUsable(chaNode, skillType, skillId, triggerType, targetTable)
end
function SkillManager:castSkill(chaNode, skillType, skillId)
    if not skillId then
        return
    end
    local baseSkillId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseSkillId .. ".lua") then
    --    return
    --end

    LOG_UTIL:addTestLog(LOG_UTIL.TestLogType.CAST_SKILL, chaNode, nil, skillId, false, false, 0)
    local scripe = require("Battle.NewSkill.Skill_" .. baseSkillId)
    return scripe["castSkill"] and scripe:castSkill(chaNode, skillType, skillId)
end
function SkillManager:runBuff(chaNode, fullBuffId, resultTable, allPassiveTable, targetTable)
    if not fullBuffId then
        return { }
    end
    local baseBuffId = math.floor(fullBuffId / 100) % 100
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseBuffId .. ".lua") then
    --    local resultTable = { }
    --    table.insert(resultTable, {
    --        [NewBattleConst.LogDataType.DMG] = { 100 },
    --        [NewBattleConst.LogDataType.DMG_TAR] = { chaNode.target },
    --        [NewBattleConst.LogDataType.DMG_CRI] = { false },
    --        [NewBattleConst.LogDataType.DMG_WEAK] = { 0 },
    --    })
    --    return resultTable
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseBuffId)
    return scripe:runSkill(chaNode, fullBuffId, resultTable, allPassiveTable, targetTable)
end
function SkillManager:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, params)
    if not skillId then
        return { }
    end
    local baseSkillId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseSkillId .. ".lua") then
    --    local resultTable = {}
    --    table.insert(resultTable, {
    --        [NewBattleConst.LogDataType.DMG] = { 100 },
    --        [NewBattleConst.LogDataType.DMG_TAR] = { chaNode.target },
    --        [NewBattleConst.LogDataType.DMG_CRI] = { false },
    --        [NewBattleConst.LogDataType.DMG_WEAK] = { 0 },
    --    })
    --    return resultTable
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseSkillId)
    return scripe:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, params)
end
function SkillManager:calSkillTarget(skillId, chaNode)
    if not skillId then
        return { }
    end
    local baseId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseId .. ".lua") then
    --    return { }
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseId)
    return scripe:calSkillTarget(chaNode, skillId)
end
function SkillManager:setSkillTarget(skillId, chaNode, targetTable)
    if not skillId then
        return
    end
    local baseId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseId .. ".lua") then
    --    return
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseId)
    return scripe["setSkillTarget"] and scripe:setSkillTarget(chaNode, skillId, targetTable)
end
function SkillManager:calSkillSpecialParams(skillId, option)
    if not skillId then
        return { 0 }
    end
    local baseId = math.floor(skillId / 10)
    --if not NodeHelper:isFileExist("lua/Battle/NewSkill/Skill_" .. baseId .. ".lua") then
    --    return { 0 }
    --end
    local scripe = require("Battle.NewSkill.Skill_" .. baseId)
    return scripe:calSkillSpecialParams(skillId, option)
end

return SkillManager