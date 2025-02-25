Skill_71 = Skill_71 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
�ؼмh���|���ɮھڬI�k�̳Q�ʧޯ�ID�A�y��100%/150%/150%(skillcfg params3)�ˮ`�A�òM���h��(���bBuffManager)
*BUFF71 ����
]]--
-------------------------------------------------------
function Skill_71:castSkill(chaNode, skillType, skillId)
    -- �S��skillData
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_71:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_71:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
        local baseDmg = atk * (1 - reduction) * elementRate * self:getSkillRatio(chaNode, skillId) * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        local isHit = true and not (BuffManager:isInInvincible(target.buffData) or BuffManager:isInGhost(target.buffData) or BuffManager:isInDodge(target.buffData))
        if isHit then
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
        end
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable

    return resultTable
end
function Skill_71:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_71:getSkillTarget(chaNode, skillId)
    return { }
end

function Skill_71:getSkillRatio(chaNode, buffId)
    local buffCfg = ConfigManager.getNewBuffCfg()[buffId]
    local buffValues = common:split(buffCfg.values, ",")
    -- �ˬd�����̧ޯ�ID
    for skillType, skillTypeData in pairs(chaNode.skillData) do
        for skillId, skillIdData in pairs(skillTypeData) do
            if math.floor(skillId / 10) == tonumber(buffValues[1]) then -- �i�HĲ�o�������ޯ�ID
                local skillConfig = ConfigManager.getSkillCfg()
                local skillValues = common:split(skillConfig[skillId].values, ",")
                return tonumber(skillValues[3])
            end
        end
    end
    return 1
end

return Skill_71