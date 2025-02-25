Skill_1121 = Skill_1121 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
���e�ؼгy��100%/120%/140%(params1)�ˮ`�A���H����ؼЩP����ΰϰ�(w:200(params2), h:180(params3))���ĤH�y��1/2/3��(params4)�ˮ`�A�C���ˮ`���20%(params5)
��ۨ���1123�ޯ�ɡALv1�ɴ��@40%(params1)�ˮ`�BLv2���q�g�Z���W�[(w:50(params2), h:50(params3))�BLv3��CD���4��(params4)
]]--
--[[ OLD
��Ĥ����y��50%/80%/120%(params1)�ˮ`�A�ýᤩ"�I�zI/�I�zI/�I�zII"(params2)5��(params3)
]]--
-------------------------------------------------------
function Skill_1121:castSkill(chaNode, skillType, skillId)
    --����skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
    -- �B�~�ĪG�ޯ�id
    local passiveId = nil
    if chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE] then
        for k, v in pairs(chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE]) do
            if math.floor(k / 10) == 1123 then  -- ��1123�ޯ��Ĳ�o�B�~�ĪG
                passiveId = k
            end
        end
    end
    if passiveId then
        local passiveLevel = passiveId % 10
        local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
        local params2 = common:split(skillCfg2.values, ",")
        chaNode.skillData[skillType][skillId]["CD"] = math.max(chaNode.skillData[skillType][skillId]["CD"] - tonumber(params2[4]), 0)
    end
end
-- ���e�p��ޯ�ؼХ� ���ϥήɦ^��nil
function Skill_1121:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1121:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
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
            if math.floor(k / 10) == 1123 then  -- ��1123�ޯ��Ĳ�o�B�~�ĪG
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

    local spDmg = 0
    local spTar = nil
    for i = 1, #allTarget do
        local target = allTarget[i]
        spTar = target
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
        local skillDmgRate = tonumber(params[1])
        if passiveId then
            local passiveLevel = passiveId % 10
            if passiveLevel >= 1 then
                local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
                local params2 = common:split(skillCfg2.values, ",")
                skillDmgRate = skillDmgRate + tonumber(params2[1])
            end
        end
        local baseDmg = atk * (1 - reduction) * elementRate * skillDmgRate / hitMaxNum * buffValue * auraValue * markValue

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
            spDmg = dmg
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
    -- �q�g�ؼ�
    local count = 0
    if spTar then
        local spTarget = self:getSkillTarget2(spTar, skillId, passiveId)
        if #spTarget > 0 then
            for i = 1, tonumber(params[4]) do
                local randIdx = math.random(1, #spTarget)
                local target = spTarget[randIdx]

                if NewBattleUtil:calIsHit(chaNode, target) then
                    count = count + 1
                    table.insert(dmgTable, math.floor(spDmg * (1 - tonumber(params[5]) * count) + 0.5))
                    table.insert(tarTable, target)
                    table.insert(criTable, false)
                    table.insert(weakTable, 0)
                end
            end
        end
    end

    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable

    return resultTable
end
function Skill_1121:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.SKILL1_TRIGGER_TYPE.NORMAL then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    return true
end

function Skill_1121:getSkillTarget(chaNode, skillId)
    return { chaNode.target }
    --local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    --aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
    --return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

function Skill_1121:getSkillTarget2(chaNode, skillId, passiveId)
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    if passiveId then
        local passiveLevel = passiveId % 10
        local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
        local params2 = common:split(skillCfg2.values, ",")

        return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ELLIPSE_2, 
                                        { x = tonumber(params[2]) + tonumber(params2[2]), y = tonumber(params[3]) + tonumber(params2[3]) }, true)
    end
    return SkillUtil:getSkillTarget(chaNode, friendList, aliveIdTable, SkillUtil.AREA_TYPE.ELLIPSE_2, { x = tonumber(params[2]), y = tonumber(params[3]) }, true)
end

return Skill_1121