Skill_1140 = Skill_1140 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
���e�ؼгy��280%/340%/400%(params1)�ˮ`�A����o10/20/30MP(params2)
��ۨ���1143�ޯ�ɡA�B�~��o10/20/30MP(params1)
]]--
--[[ OLD
�L���ؼЪ��z�P�]�k���m�A���e�ؼгy��400%/450%/500%(params1)���z�ˮ`�A
�Y�ؼгQ���ޯ������A�^�_50%/50%/100%MP(�ӮĪG�P�_�g�b�ؼ�beAttack)
]]--
-------------------------------------------------------
function Skill_1140:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1140:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1140:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
            if math.floor(k / 10) == 1143 then  -- ��1143�ޯ��Ĳ�o�B�~�ĪG
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
    local mpTable = { }
    local mpTarTable = { }
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
        local baseDmg = atk * (1 - reduction) * elementRate * (tonumber(params[1])) / hitMaxNum * buffValue * auraValue * markValue
        -- �ɶ��Ҷq�u�[�b1140�ޯऺ�P�_
        for k, v in pairs(NewBattleConst.PASSIVE_TYPE_ID[NewBattleConst.PASSIVE_TRIGGER_TYPE.ADD_EXECUTE_DMG]) do -- �C��q�B�~�W��
            local skillType, fullSkillId = NewBattleUtil:checkSkill(v, chaNode.skillData)
            if skillType == NewBattleConst.SKILL_DATA.PASSIVE then
                local SkillManager = require("Battle.NewSkill.SkillManager")
                local passiveParams = SkillManager:calSkillSpecialParams(fullSkillId, { target })
                baseDmg = baseDmg * passiveParams
            end
        end
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
        else
            --�̲׵��G
            table.insert(dmgTable, 0)
            table.insert(tarTable, target)
            table.insert(criTable, false)
            table.insert(weakTable, 0)
        end
    end
    if hitMaxNum == hitNum then
        local passiveMp = 0
        if passiveId then
            local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
            local params2 = common:split(skillCfg2.values, ",")
            passiveMp = tonumber(params2[1])
        end
        table.insert(mpTable, tonumber(params[2]) + passiveMp)
        table.insert(mpTarTable, chaNode)
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = mpTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = mpTarTable

    return resultTable
end

function Skill_1140:getSkillTarget(chaNode, skillId)
    return { chaNode.target }
end

return Skill_1140