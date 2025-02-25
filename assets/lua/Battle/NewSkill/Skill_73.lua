Skill_73 = Skill_73 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
��ۨ����߾��ΰϰ�(w:240(params1), h:150(params2))���ĤH�C1��(params3)�y��20%/40%/60%(params4)�ˮ`�A�ؼЦ��@�ޭȮɶˮ`�[��(params5)
*BUFF73 �q��ϳ�
]]--
-------------------------------------------------------
function Skill_73:castSkill(chaNode, skillType, skillId)
    -- �S��skillData
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_73:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_73:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local buffCfg = ConfigManager.getNewBuffCfg()[skillId]
    local params = common:split(buffCfg.values, ",")
    --��l��table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
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
                                                                                 nil)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[4]) * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --�z��
            local criRate = 1
            isCri = NewBattleUtil:calIsCri(chaNode, target)
            if isCri then
                criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
            end
            local spRate = 1
            if target.battleData[NewBattleConst.BATTLE_DATA.SHIELD] >= 0 then
                spRate = tonumber(params[5])
            end
            --�̲׶ˮ`(�|�ˤ��J)
            local dmg = math.floor(baseDmg * criRate * spRate + 0.5)
            --�̲׵��G
            table.insert(dmgTable, dmg)
            table.insert(tarTable, target)
            table.insert(criTable, isCri)
            table.insert(weakTable, weakType)
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

    return resultTable
end
function Skill_73:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_73:getSkillTarget(chaNode, skillId)
    local buffCfg = ConfigManager.getNewBuffCfg()[skillId]
    local params = common:split(buffCfg.values, ",")
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)

    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ELLIPSE_2, { x = tonumber(params[1]), y = tonumber(params[2]) })
end

return Skill_73