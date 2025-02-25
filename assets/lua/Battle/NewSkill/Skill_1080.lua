Skill_1080 = Skill_1080 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
對生命最高的敵方單體造成120/140/160%(params1)傷害，隊伍中每有一名存活的水屬性隊友，額外追加1次100%/100%/100%(params2)傷害，最多追加2/3/4次(params3)
]]--
--[[ OLD
對敵方全體造成每下80%/100%/120%(params1)傷害，對有Debuff的目標傷害加倍，Lv3時第一下傷害賦予目標"防禦破壞II"(params2)3秒(params3)
]]--
-------------------------------------------------------
function Skill_1080:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1080:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1080:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    local allTarget = targetTable or self:getSkillTarget(chaNode, skillId)

    resultTable = { }

    local dmgTable = { }
    local tarTable = { }
    local criTable = { }
    local weakTable = { }

    local addDmgNum = math.min(self:getWaterElementNum(chaNode, skillId), tonumber(params[3]))

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
        local isCri = false
        local weakType = (elementRate > 1 and 1) or (elementRate < 1 and -1) or 0

        local baseDmg = atk * (1 - reduction) * elementRate * tonumber(params[1]) * buffValue * auraValue * markValue
        -- 時間考量只加在1080技能內判斷
        local unReductDmg = 0
        local unReductDmg2 = 0
        for k, v in pairs(NewBattleConst.PASSIVE_TYPE_ID[NewBattleConst.PASSIVE_TRIGGER_TYPE.ADD_UNREDUCT_DMG]) do -- 追加無視減傷傷害
            local skillType, fullSkillId = NewBattleUtil:checkSkill(v, chaNode.skillData)
            if skillType == NewBattleConst.SKILL_DATA.PASSIVE then
                local SkillManager = require("Battle.NewSkill.SkillManager")
                local passiveParams = SkillManager:calSkillSpecialParams(fullSkillId, { target })
                unReductDmg = unReductDmg + atk * passiveParams[1] * elementRate * tonumber(params[1]) * buffValue * auraValue * markValue
                unReductDmg2 = unReductDmg2 + atk * passiveParams[1] * elementRate * tonumber(params[2]) * buffValue * auraValue * markValue
            end
        end
        baseDmg = baseDmg + unReductDmg
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
        local addDmg = atk * (1 - reduction) * elementRate * tonumber(params[2]) * buffValue * auraValue * markValue
        addDmg = addDmg + unReductDmg2
        for i = 1, addDmgNum do
            if NewBattleUtil:calIsHit(chaNode, target) then
                --爆傷
                local criRate = 1
                isCri = NewBattleUtil:calIsCri(chaNode, target)
                if isCri then
                    criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
                end
                --最終傷害(四捨五入)
                local dmg = math.floor(addDmg * criRate + 0.5)
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
    end
    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable

    return resultTable
end

function Skill_1080:getSkillTarget(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    return SkillUtil:getHighHpTarget(chaNode, enemyList, 1)
end

function Skill_1080:getWaterElementNum(chaNode, skillId)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local friendList = NgBattleDataManager_getFriendList(chaNode)
    local aliveIdTable = NewBattleUtil:initAliveTable(friendList)
    local num = 0
    for i = 1, #aliveIdTable do
        if friendList[aliveIdTable[i]].battleData[NewBattleConst.BATTLE_DATA.ELEMENT] == NewBattleConst.ELEMENT.WATER then
            num = num + 1
        end
    end
    return num
end

return Skill_1080