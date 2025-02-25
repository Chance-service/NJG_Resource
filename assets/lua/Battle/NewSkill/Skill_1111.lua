Skill_1111 = Skill_1111 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
對當前目標造成50/60/80%(params1)傷害，並額外造成其身上Debuff數量 * 50/60/80%(params1)傷害
]]--
--[[ OLD
對MP最高的敵方周圍橢圓形區域(w:240(params1), h:150(params2))內目標造成150%/170%/200%(params3)傷害，
Lv3時賦予"暈眩"(params4)2秒(params5)
]]--
-------------------------------------------------------
function Skill_1111:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil  *這邊計算技能移動目標
function Skill_1111:calSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(enemyList)
    local allTarget = self:getMoveTarget(chaNode)
    return allTarget
end
function Skill_1111:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    if not targetTable[1] then
        targetTable[1] = aliveIdTable[1]
    end
    if not targetTable[1] then
        return { }
    end
    local allTarget = self:getSkillTarget(chaNode, targetTable[1], skillId) -- targetTable為移動目標

    resultTable = { }

    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }
    for i = 1, #allTarget do
        local target = allTarget[i]
        --減傷
        local reduction = NewBattleUtil:calReduction(chaNode, target)
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --屬性加成
        local elementRate = NewBattleUtil:calElementRate(chaNode, target)
        --基礎傷害
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(chaNode, target, 
                                                                                 chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY], 
                                                                                 skillCfg.actionName)
        local addRatio = self:getSpRate(target, skillId)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) * (1 + addRatio) / hitMaxNum * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        if NewBattleUtil:calIsHit(chaNode, target) then
            --爆傷
            local criRate = 1
            isCri = NewBattleUtil:calIsCri(chaNode, target)
            if isCri then
                criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
            end
            --最終傷害(四捨五入)
            local dmg = math.floor(baseDmg * criRate + 0.5)
            --最終結果
            table.insert(dmgTable, dmg)
            table.insert(tarTable, target)
            table.insert(criTable, isCri)
            table.insert(weakTable, weakType)
        else
            --最終結果
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
function Skill_1111:isUsable(chaNode, skillType, skillId, triggerType)
    if triggerType ~= NewBattleConst.SKILL1_TRIGGER_TYPE.NORMAL then
        return false
    end
    if not chaNode.skillData[skillType][skillId]["CD"] or chaNode.skillData[skillType][skillId]["CD"] > 0 then
        return false
    end
    if not chaNode.target then
        return false
    end
    return true
end

function Skill_1111:getSkillTarget(chaNode, target, skillId)
    return { chaNode.target }
end

function Skill_1111:getMoveTarget(chaNode, skillId)
    return { chaNode.target }
end

function Skill_1111:getSpRate(chaNode, skillId)
    if not chaNode then
        return 0
    end
    local num = 0
    local cfg = ConfigManager:getNewBuffCfg()
    for k, v in pairs(chaNode.buffData) do
        if cfg[k] and cfg[k].gain == 0 and cfg[k].visible == 1 then -- 可見的debuff才計算
            num = num + 1
        end
    end
    return num
end

return Skill_1111