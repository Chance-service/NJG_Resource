Skill_1090 = Skill_1090 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
��_HP�̧C�ͤ����ۨ������O300%/400%/500%(params1)��HP���X���t���ĪG
]]--
--[[ OLD
��_�ͤ�����]�k�����O150%/180%/200%(params1)��HP���X���t���ĪG�ALv3�ɽᤩ"�j��II"(params2)10��(params3)
]]--
-------------------------------------------------------
function Skill_1090:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1090:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1090:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }
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
        table.insert(spClassTable, NewBattleConst.FunClassType.BUFF_MANAGER)
        table.insert(spFuncTable, "clearAllDeBuff")
        table.insert(spParamTable, { chaNode, chaNode.buffData })
        table.insert(spTarTable, chaNode)
    end
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = spClassTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = spFuncTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = spParamTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = spTarTable

    return resultTable
end

function Skill_1090:getSkillTarget(chaNode, skillId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    return SkillUtil:getLowHpTarget(chaNode, friendList, 1)
end

return Skill_1090