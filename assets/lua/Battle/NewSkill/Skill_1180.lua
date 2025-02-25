Skill_1180 = Skill_1180 or { }

require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("Battle.NgBattleDataManager")
require("Battle.NewSkill.SkillUtil")
local aliveIdTable = { }
-------------------------------------------------------
--[[ NEW
對敵方全體造成130%/160%/190%(params1)傷害，並賦予目標"出血I/出血II/出血III"(params2)5/6/7秒(params3)
當自身有1183技能時，Lv1時額外回復自身20%(params1)生命、Lv2時額外獲得30MP(params2)、Lv3時額外賦予自身當前生命值25%(params3)的護盾
]]--
--[[ OLD
指定當前HP比例最低的1位(params1)友方，為其恢復魔法攻擊力500%/550%/600%(params2)的HP，Lv3時賦予"堅守I"(params3)5秒(params4)
]]--
-------------------------------------------------------
function Skill_1180:castSkill(chaNode, skillType, skillId)
    --紀錄skill data
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    chaNode.skillData[skillType][skillId]["COUNT"] = chaNode.skillData[skillType][skillId]["COUNT"] + 1
    chaNode.skillData[skillType][skillId]["CD"] = tonumber(skillCfg.cd)
end
-- 提前計算技能目標用 不使用時回傳nil
function Skill_1180:calSkillTarget(chaNode, skillId)
    return nil
end
function Skill_1180:runSkill(chaNode, skillId, resultTable, allPassiveTable, targetTable, attack_params)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local skillLevel = skillId % 10
    local params = common:split(skillCfg.values, ",")
    local attackParams = attack_params or chaNode.ATTACK_PARAMS
    local hitMaxNum = tonumber(attackParams["hit_num"]) or 1
    local hitNum = tonumber(attackParams["hit_count"]) or 1
    --初始化table
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getFriendList(chaNode))
    -- 額外效果技能id
    local passiveId = nil
    if chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE] then
        for k, v in pairs(chaNode.skillData[NewBattleConst.SKILL_DATA.PASSIVE]) do
            if math.floor(k / 10) == 1183 then  -- 有1183技能時觸發額外效果
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
    local healTable = { }
    local healTarTable = { }
    local healCriTable = { }
    local mpTable = { }
    local mpTarTable = { }
    local spClassTable = { }
    local spFuncTable = { }
    local spParamTable = { }
    local spTarTable = { }

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
        local baseDmg = atk * (1 - reduction) * elementRate * (tonumber(params[1]) / hitMaxNum) * buffValue * auraValue * markValue

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
            table.insert(buffTable, tonumber(params[2]))
            table.insert(buffTarTable, target)
            table.insert(buffTimeTable, tonumber(params[3]) * 1000)
            table.insert(buffCountTable, 0)
        else
            --最終結果
            table.insert(dmgTable, 0)
            table.insert(tarTable, target)
            table.insert(criTable, false)
            table.insert(weakTable, 0)
        end
    end
    -- 回復HP
    if passiveId then
        local passiveLevel = passiveId % 10
        local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
        local params2 = common:split(skillCfg2.values, ",")

        local target = chaNode
        --施法者造成治療buff
        local buffValue = BuffManager:checkHealBuffValue(chaNode.buffData)
        --目標受到治療buff
        local buffValue2 = BuffManager:checkBeHealBuffValue(target.buffData)
        --基礎傷害
        local baseDmg = target.battleData[NewBattleConst.BATTLE_DATA.HP] * (tonumber(params2[1]) / hitMaxNum) * buffValue * buffValue2

        local isCri = false
        --爆傷
        local criRate = 1
        isCri = NewBattleUtil:calIsCri(chaNode, target)
        if isCri then
            criRate = NewBattleUtil:calFinalCriDmgRate(chaNode, target)
        end
        --最終傷害(四捨五入)
        local dmg = math.floor(baseDmg * criRate + 0.5)
        --最終結果
        table.insert(healTable, dmg)
        table.insert(healTarTable, target)
        table.insert(healCriTable, isCri)
    end
    -- 回復MP
    if passiveId then
        local passiveLevel = passiveId % 10
        local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
        local params2 = common:split(skillCfg2.values, ",")
        if passiveLevel >= 2 then
            local target = chaNode
            table.insert(mpTable, tonumber(params2[2]))
            table.insert(mpTarTable, target)
        end
    end
    -- 護盾
    if passiveId then
        local passiveLevel = passiveId % 10
        local skillCfg2 = ConfigManager:getSkillCfg()[passiveId]
        local params2 = common:split(skillCfg2.values, ",")
        if passiveLevel >= 3 then
            local target = chaNode
            local hp = target.battleData[NewBattleConst.BATTLE_DATA.HP]
            table.insert(spClassTable, NewBattleConst.FunClassType.NG_BATTLE_CHARACTER_UTIL)
            table.insert(spFuncTable, "addShield")
            table.insert(spParamTable, { chaNode, target, math.floor(hp * tonumber(params2[3]) + 0.5) })
            table.insert(spTarTable, target)
        end
    end

    resultTable[NewBattleConst.LogDataType.DMG] = dmgTable
    resultTable[NewBattleConst.LogDataType.DMG_TAR] = tarTable
    resultTable[NewBattleConst.LogDataType.DMG_CRI] = criTable
    resultTable[NewBattleConst.LogDataType.DMG_WEAK] = weakTable
    resultTable[NewBattleConst.LogDataType.HEAL] = healTable
    resultTable[NewBattleConst.LogDataType.HEAL_TAR] = healTarTable
    resultTable[NewBattleConst.LogDataType.HEAL_CRI] = healCriTable
    resultTable[NewBattleConst.LogDataType.BUFF] = buffTable
    resultTable[NewBattleConst.LogDataType.BUFF_TAR] = buffTarTable
    resultTable[NewBattleConst.LogDataType.BUFF_TIME] = buffTimeTable
    resultTable[NewBattleConst.LogDataType.BUFF_COUNT] = buffCountTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP] = mpTable
    resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] = mpTarTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_CLASS] = spClassTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_NAME] = spFuncTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_PARAM] = spParamTable
    resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] = spTarTable

    return resultTable
end

function Skill_1180:getSkillTarget(chaNode, skillId)
    local enemyList = NgBattleDataManager_getEnemyList(chaNode)
    aliveIdTable = NewBattleUtil:initAliveTable(NgBattleDataManager_getEnemyList(chaNode))
    return SkillUtil:getSkillTarget(chaNode, enemyList, aliveIdTable, SkillUtil.AREA_TYPE.ALL, { })
end

return Skill_1180