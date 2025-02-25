Skill_1110 = Skill_1110 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
��Ĥ����y��120%/180%/220%(params1)�ˮ`�A�ýᤩ�ؼ�"�I�zI/�I�zII/�I�zIII"(params2)8/10/12��(params3)�B"�P��I/�P��II/�P��III"(params4)8/10/12��(params5)
��ۨ���1113�ޯ�ɡA�B�~�ᤩ�ؼ�"�]�O����I/�]�O����II/�]�O����III"(params2)8/10/12��(params3)�B"��¶I/��¶II/��¶III"(params4)8/10/12��(params5)
]]--
--[[ OLD
��Ĥ����y��150%/170%/190%(params1)�ˮ`�A�ýᤩ�ؼ�"�P��I/�P��I/�P��II"(params2)5��(params3)
]]--
-------------------------------------------------------
function Skill_1110:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1110:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1110:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    -- �B�~�ĪG�ޯ�id
    local passiveId = nil
    if chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE] then
        for k, v in pairs(chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE]) do
            if math.floor(k / 10) == 1113 then  -- ��1113�ޯ��Ĳ�o�B�~�ĪG
                passiveId = k
            end
        end
    end
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    local buffTable = { }
    local buffTarTable = { }
    local buffTimeTable = { }
    local buffCountTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --���
        local reduction = NewBattleUtil:calReduction(chaNode, target)
        --�����O
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --�ݩʥ[��
        local elementRate = NewBattleUtil:calElementRate(chaNode, target)
        --��¦�ˮ`
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(chaNode, target, 
                                                                                 chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY], 
                                                                                 skillCfg.actionName)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) / hitMaxNum * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --�z��
            local criRate = 1
            isCri = NewBattleUtil:calIsCri(chaNode, target)
            if isCri then
                criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
            end
            --�̲׶ˮ`(�|�ˤ��J)
            local dmg = math.floor(baseDmg * criRate + 0.5)
            --�̲׵��G
            table.insert(dmgTable, dmg)
            table.insert(tarTable, target)
            table.insert(criTable, isCri)
            table.insert(weakTable, weakType)
            table.insert(buffTable, tonumber(params[2]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, tonumber(params[3]) * 1000)
            table.insert(buffCountTable, 1)
            table.insert(buffTable, tonumber(params[4]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, tonumber(params[5]) * 1000)
            table.insert(buffCountTable, 1)
            if passiveId then
                local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
                local params2 = common:split(skillCfg2.values, ",")
                table.insert(buffTable, tonumber(params2[1]))
                table.insert(buffTarTable, target)
                table.insert(buffTimeTable, tonumber(params2[2]) * 1000)
                table.insert(buffCountTable, 1)
                table.insert(buffTable, tonumber(params2[3]))
                table.insert(buffTarTable, target)
                table.insert(buffTimeTable, tonumber(params2[4]) * 1000)
                table.insert(buffCountTable, 1)
            end
        else
            --�̲׵��G
            table.insert(dmgTable, 0)
            table.insert(tarTable, target)
            table.insert(criTable, false)
            table.insert(weakTable, 0)
        end
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable

    return resultTable
end

function Skill_1110:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1110