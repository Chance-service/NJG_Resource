Skill_1053 = Skill_1053 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
�ͩR�C��50%(params1)�ɽᤩ�ۨ�"�A��I/�A��II/�A��III"(params2)30/30/30��(params3)�A�ë�_�����O150%/180%/240%(params4)��HP
���ޯ�u�o�ʤ@��
]]--
--[[ OLD
�}���ɽᤩ�ۨ�"���I/���II/���III"(params1)
]]--
-------------------------------------------------------
function Skill_1053:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1053:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1053:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    -- heal
    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local target = chaNode
    --�����O
    local atk = NewBattleUtil:calAtk(chaNode, target)
    --�I�k�̳y���v��buff
    local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
    --�ؼШ���v��buff
    local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
    --��¦�ˮ`
    local baseDmg = atk * tonumber(params[4]) * buffValue * buffValue2

    local isCri = false
    --�z��
    local criRate = 1
    isCri = NewBattleUtil:calIsCri(chaNode, target)
    if isCri then
        criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
    end
    --�̲׶ˮ`(�|�ˤ��J)
    local dmg = math.floor(baseDmg * criRate + 0.5)

    table.insert(healTable, dmg)
    table.insert(healTarTable, target)
    table.insert(healCriTable, isCri)
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    --Get Buff
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    table.insert(buffTable, tonumber(params[2]))
    table.insert(buffTarTable, chaNode)
    table.insert(buffTimeTable, tonumber(params[3] * 1000))
    table.insert(buffCountTable, 1)
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    return resultTable
end

function Skill_1053:isUsable(chaNode, skillType, skillId, triggerType)
    if not chaNode.skillData[skillType][skillId]["COUNT"] or chaNode.skillData[skillType][skillId]["COUNT"] > 0 then
        return false
    end
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local hpPercent = chaNode.battleData[NewBattleConst.BATTLE_DATA.HP] / chaNode.battleData[NewBattleConst.BATTLE_DATA.MAX_HP]
    local params = common:split(skillCfg.values, ",")
    if hpPercent >= tonumber(params[1]) then
        return false
    end
    return true
end

return Skill_1053