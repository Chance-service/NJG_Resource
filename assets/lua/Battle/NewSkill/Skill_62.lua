Skill_62 = Skill_62 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[
無視目標物理與魔法防禦，造成180%/180%/180%/180%/180%(params1)傷害，並竊取5/5/5/5/5點(params2)MP
*BUFF62 爆炸種子
]]--
-------------------------------------------------------
function Skill_62:castSkill(chaNode, skillType, skillId)
    -- 沒有skillData
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_62:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_62:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local buffCfg = ConfigManager.getNewBuffCfg()[skillId]
    local params = common:split(buffCfg.values, ",")
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
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
        --減傷
        local reduction = 0
        --攻擊力
        local atk = NewBattleUtil:calAtk(chaNode, target)
        --屬性加成
        local elementRate = NewBattleUtil:calElementRate(chaNode, target)
        --基礎傷害
        local buffValue, auraValue, markValue = BuffManager:checkAllDmgBuffValue(chaNode, target, 
                                                                                 chaNode.battleData[NewBattleConst.BATTLE_DATA.IS_PHY], 
                                                                                 nil)
        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) * buffValue * auraValue * markValue

        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0
        local isHit = true and not (BuffManager:isInInvincible(target.buffData) or BuffManager:isInGhost(target.buffData) or BuffManager:isInDodge(target.buffData))
        if isHit then
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
            table.insert(mpTable, tonumber(params[2] * -1))
            table.insert(mpTarTable, target)
        end
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = mpTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = mpTarTable

    return resultTable
end
function Skill_62:isUsable(chaNode, skillType, skillId, triggerType)
    return true
end

function Skill_62:getSkillTarget(chaNode, skillId)
    return { }
end

return Skill_62