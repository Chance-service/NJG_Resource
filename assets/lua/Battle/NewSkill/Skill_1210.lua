Skill_1210 = Skill_1210 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�ͤ�����_�����O225%/285%/345%(params1)��HP�A�ýᤩ"����I/����II/����III"(params2)5/6/7��(params3)
]]--
--[[ OLD
�ͤ�����_�����O130%/150%/170%(params1)��HP�A�ýᤩ"����I/����I/����II"(params2)10��(params3)
]]--
-------------------------------------------------------
function Skill_1210:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1210:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1210:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --�����O
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --�I�k�̳y���v��buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --�ؼШ���v��buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --��¦�ˮ`
        local baseDmg = atk * tonumber(params[1]) / hitMaxNum * buffValue * buffValue2

        local isCri = false
        --�z��
        local criRate = 1
        isCri = NewBattleUtil:calIsCri(chaNode, target)
        if isCri then
            criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
        end
        --�̲׶ˮ`(�|�ˤ��J)
        local dmg = math.floor(baseDmg * criRate + 0.5)
        --�̲׵��G
        table.insert(healTable, dmg)
        table.insert(healTarTable, target)
        table.insert(healCriTable, isCri)
        table.insert(buffTable, tonumber(params[2]))
        table.insert(buffTarTable, target)
        table.insert(buffTimeTable, tonumber(params[3]) * 1000)
        table.insert(buffCountTable, 1)
    end
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1210:getSkillTarget(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1210