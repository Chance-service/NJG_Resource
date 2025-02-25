Skill_5990 = Skill_5990 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
��Ĥ�D1����ؼгy��100%�̤j�ͩR�ˮ`�A
��Ĥ�1����ؼгy��99%�̤j�ͩR�ˮ`
]]--
-------------------------------------------------------
function Skill_5990:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_5990:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_5990:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    local eList = NgBattleDataManager_getEnemyList(chaNode)

    resultTable = { }
    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(eList)
    for i = 1, #aliveIdTable do
        local target = eList[aliveIdTable[i]]
        local baseDmg = 0
        if aliveIdTable[i] == 1 then
            baseDmg = target.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] / hitMaxNum * 0.99
        else
            baseDmg = target.battleData[NewBattleConst.BATTLE_DATA.MAX_HP] / hitMaxNum
        end
        local weakType = 0
        local criRate = 1
        --�̲׶ˮ`(�|�ˤ��J)
        local dmg = math.floor(baseDmg * criRate + 0.5)
        --�̲׵��G
        table.insert(dmgTable, dmg)
        table.insert(tarTable, target)
        table.insert(criTable, isCri)
        table.insert(weakTable, weakType)
    end

    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    return resultTable
end

function Skill_5990:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

return Skill_5990