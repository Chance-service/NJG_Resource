SkillUtil = SkillUtil or {}

local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("NodeHelper")
-------------------------------------------------------------------------------------------
SkillUtil.AREA_TYPE = {
    ALL       = 0,  -- 所有敵方
    ELLIPSE_1 = 1,  -- 自身前方橢圓區域(params: x, y)
    ELLIPSE_2 = 2,  -- 自身中心橢圓區域(params: x, y)
    AHEAD     = 3,  -- 自身前方
}
-- 發動技能效果(無法寫在技能腳本內)
function SkillUtil:triggerSkillSpecialEffect(chaNode, target, skillId)
    if (not skillId) or (not ConfigManager:getSkillCfg()[skillId]) then
        return
    end
    local baseSkillId = math.floor(skillId / 10)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
end
-- 取得特定範圍內目標
function SkillUtil:getSkillTarget(chaNode, list, aliveIds, areaType, params, excludeSelf)
    local t = { }
    local heroToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    -- 自身腳底座標
    local selfX, selfY = chaNode.heroNode.chaCCB:getPositionX(), chaNode.heroNode.chaCCB:getPositionY()
    if #aliveIds > 0 then
        for i = 1, #aliveIdTable do
            if not excludeSelf or list[aliveIdTable[i]].idx ~= chaNode.idx then
                local isTarget = false
                if areaType == SkillUtil.AREA_TYPE.ALL then
                    isTarget = true
                elseif areaType == SkillUtil.AREA_TYPE.ELLIPSE_1 then
                    if heroToNode:getScaleX() > 0 and self:isInEllipse(selfX + params.x, selfY, list[aliveIdTable[i]], params.x, params.y) then
                        isTarget = true
                    elseif heroToNode:getScaleX() < 0 and self:isInEllipse(selfX - params.x, selfY, list[aliveIdTable[i]], params.x, params.y) then
                        isTarget = true
                    end
                elseif areaType == SkillUtil.AREA_TYPE.ELLIPSE_2 then
                    if self:isInEllipse(selfX, selfY, list[aliveIdTable[i]], params.x, params.y) then
                        isTarget = true
                    end
                elseif areaType == SkillUtil.AREA_TYPE.AHEAD then
                    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
                    local isFlip = chaNode.otherData[CONST.OTHER_DATA.IS_FLIP]
                    if (sToNode:getScaleX() > 0 and isFlip == 0) or (sToNode:getScaleX() < 0 and isFlip == 1) then
                        isTarget = selfX < list[aliveIdTable[i]].heroNode.chaCCB:getPositionX()
                    elseif (sToNode:getScaleX() < 0 and isFlip == 0) or (sToNode:getScaleX() > 0 and isFlip == 1) then
                        isTarget = selfX > list[aliveIdTable[i]].heroNode.chaCCB:getPositionX()
                    end
                end
                if isTarget then
                    table.insert(t, list[aliveIdTable[i]])
                end
            end
        end
    end
    return t
end
function SkillUtil:isInEllipse(centerX, centerY, target, w, h)
    -- 角色碰撞判定範圍(橢圓)
    local tarW, tarH = target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX, target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
    -- 角色中心座標
    local tarX, tarY = target.heroNode.chaCCB:getPositionX(), target.heroNode.chaCCB:getPositionY() + tarH * 0.5
    local result = (((tarX - centerX) * (tarX - centerX)) / ((w + tarW) * (w + tarW))) + (((tarY - centerY) * (tarY - centerY)) / ((h + tarH) * (h + tarH)))
    return result <= 1
end
-- 取得Mp比例最高目標
function SkillUtil:getHighestMpEnemy(eList, aliveIds, secondCond)
    local highestMp = -999
    local target = { }
    if #aliveIds > 0 then
        for i = 1, #aliveIds do
            local idx = aliveIds[i]
            if eList[idx] then
                local mp = eList[idx].battleData[CONST.BATTLE_DATA.MP]
                if highestMp < mp then
                    target = {}
                    highestMp = mp
                    table.insert(target, eList[idx])
                elseif highestMp == mp then
                    table.insert(target, eList[idx])
                end
            end
        end
    end
    if #target == 0 then
        return { }
    elseif #target == 1 then
        return { target[1] }
    else
        if secondCond then
            if secondCond == CONST.SKILL_TARGET_CONDITION.LOWEST_HP then
                for i = 1, #target - 1 do
                    local hp1 = target[i].battleData[CONST.BATTLE_DATA.HP]
                    local hp2 = target[i + 1].battleData[CONST.BATTLE_DATA.HP]
                    if hp1 >= hp2 then
                        local temp = target[i]
                        target[i] = target[i + 1]
                        target[i + 1] = temp
                    end
                end
            end
        end
        local randIdx = math.random(1, #target)
        return { target[randIdx] }
    end
end
-- 取得攻擊力最高目標
function SkillUtil:getHighestAtkEnemy(eList, aliveIds, secondCond)
    local highestAtk = 0
    local target = { }
    if #aliveIds > 0 then
        for i = 1, #aliveIds do
            local idx = aliveIds[i]
            if eList[idx] then
                local atk = NewBattleUtil:calAtk(eList[idx], nil)
                if highestAtk < atk then
                    target = {}
                    highestAtk = atk
                    table.insert(target, eList[idx])
                elseif highestAtk == atk then
                    table.insert(target, eList[idx])
                end
            end
        end
    end
    if #target == 0 then
        return { }
    elseif #target == 1 then
        return { target[1] }
    else
        if secondCond then
            if secondCond == CONST.SKILL_TARGET_CONDITION.LOWEST_HP then
                for i = 1, #target - 1 do
                    local hp1 = target[i].battleData[CONST.BATTLE_DATA.HP]
                    local hp2 = target[i + 1].battleData[CONST.BATTLE_DATA.HP]
                    if hp1 >= hp2 then
                        local temp = target[i]
                        target[i] = target[i + 1]
                        target[i + 1] = temp
                    end
                end
            end
        end
        local randIdx = math.random(1, #target)
        return { target[randIdx] }
    end
end
-- 取得防禦力最低目標
function SkillUtil:getLowestDefEnemy(chaNode, eList, aliveIds, isPhy, secondCond)
    local lowestDef = 999999999
    local target = { }
    if #aliveIds > 0 then
        for i = 1, #aliveIds do
            local idx = aliveIds[i]
            if eList[idx] then
                local def = NewBattleUtil:calDef(chaNode, eList[idx], isPhy)
                if lowestDef > def then
                    target = {}
                    lowestDef = def
                    table.insert(target, eList[idx])
                elseif lowestDef == def then
                    table.insert(target, eList[idx])
                end
            end
        end
    end
    if #target == 0 then
        return { }
    elseif #target == 1 then
        return { target[1] }
    else
        if secondCond then
            if secondCond == CONST.SKILL_TARGET_CONDITION.LOWEST_HP then
                for i = 1, #target - 1 do
                    local hp1 = target[i].battleData[CONST.BATTLE_DATA.HP]
                    local hp2 = target[i + 1].battleData[CONST.BATTLE_DATA.HP]
                    if hp1 >= hp2 then
                        local temp = target[i]
                        target[i] = target[i + 1]
                        target[i + 1] = temp
                    end
                end
            end
        end
        local randIdx = math.random(1, #target)
        return { target[randIdx] }
    end
end
-- 取得hp比例高目標n名
function SkillUtil:getHighHpTarget(attacker, list, num, addCond)
    local lowHpPerData = { }
    for i = 1, num do
        lowHpPerData[i] = { ["PER"] = 0, ["IDX"] = 0 }
    end
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            local idx = aliveIdTable[i]
            local isJump = false
            if addCond and (addCond == NewBattleConst.SKILL_TARGET_CONDITION.WITHOUT_SELF) then
                if list[idx] == attacker then
                    isJump = true
                end
            end
            if list[idx] and not isJump then
                local hpPer = list[idx].battleData[CONST.BATTLE_DATA.HP] / list[idx].battleData[CONST.BATTLE_DATA.MAX_HP]
                for n = 1, num do
                    if lowHpPerData[n]["PER"] < hpPer then
                        for m = num, n, -1 do
                            if m == n then
                                lowHpPerData[n]["PER"] = hpPer
                                lowHpPerData[n]["IDX"] = idx
                            else
                                lowHpPerData[m]["PER"] = lowHpPerData[m - 1]["PER"]
                                lowHpPerData[m]["IDX"] = lowHpPerData[m - 1]["IDX"]
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    local targetTable = { }
    for i = 1, num do
        if lowHpPerData[i]["IDX"] > 0 then
            table.insert(targetTable, list[lowHpPerData[i]["IDX"]])
        else
            break
        end
    end
    return targetTable
end
-- 取得hp比例最低目標n名
function SkillUtil:getLowHpTarget(attacker, list, num, addCond)
    local lowHpPerData = { }
    for i = 1, num do
        lowHpPerData[i] = { ["PER"] = 999, ["IDX"] = 0 }
    end
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            local idx = aliveIdTable[i]
            local isJump = false
            if addCond and (addCond == NewBattleConst.SKILL_TARGET_CONDITION.WITHOUT_SELF) then
                if list[idx] == attacker then
                    isJump = true
                end
            end
            if list[idx] and not isJump then
                local hpPer = list[idx].battleData[CONST.BATTLE_DATA.HP] / list[idx].battleData[CONST.BATTLE_DATA.MAX_HP]
                for n = 1, num do
                    if lowHpPerData[n]["PER"] > hpPer then
                        for m = num, n, -1 do
                            if m == n then
                                lowHpPerData[n]["PER"] = hpPer
                                lowHpPerData[n]["IDX"] = idx
                            else
                                lowHpPerData[m]["PER"] = lowHpPerData[m - 1]["PER"]
                                lowHpPerData[m]["IDX"] = lowHpPerData[m - 1]["IDX"]
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    local targetTable = { }
    for i = 1, num do
        if lowHpPerData[i]["IDX"] > 0 then
            table.insert(targetTable, list[lowHpPerData[i]["IDX"]])
        else
            break
        end
    end
    return targetTable
end
-- 取得hp低於特定比例目標
function SkillUtil:getLowHpPerTarget(attacker, list, per, includeSelf)
    local targetTable = { }
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            local idx = aliveIdTable[i]
            if list[idx] then
                local hpPer = list[idx].battleData[CONST.BATTLE_DATA.HP] / list[idx].battleData[CONST.BATTLE_DATA.MAX_HP]
                if hpPer <= per then
                    if includeSelf or (list[idx] ~= attacker) then
                        table.insert(targetTable, list[idx])
                    end
                end
            end
        end
    end
    return targetTable
end
-- 取得距離最近目標n名
function SkillUtil:getLowDistanceTarget(attacker, list, num)
    local lowDisData = { }
    for i = 1, num do
        lowDisData[i] = { ["DIS"] = 999999, ["IDX"] = 0 }
    end
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            local idx = aliveIdTable[i]
            if list[idx] then
                local dis = NewBattleUtil:calTargetDis(ccp(CHAR_UTIL:getPos(attacker).x, CHAR_UTIL:getPos(attacker).y), 
                                                       ccp(CHAR_UTIL:getPos(list[idx]).x, CHAR_UTIL:getPos(list[idx]).y))
                for n = 1, num do
                    if lowDisData[n]["DIS"] > dis then
                        for m = num, n, -1 do
                            if m == n then
                                lowDisData[n]["DIS"] = dis
                                lowDisData[n]["IDX"] = idx
                            else
                                lowDisData[m]["DIS"] = lowDisData[m - 1]["DIS"]
                                lowDisData[m]["IDX"] = lowDisData[m - 1]["IDX"]
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    local targetTable = { }
    for i = 1, num do
        if lowDisData[i]["IDX"] > 0 then
            table.insert(targetTable, list[lowDisData[i]["IDX"]])
        else
            break
        end
    end
    return targetTable
end
-- 取得特定屬性最高目標n名
function SkillUtil:getHighAttrTarget(attacker, list, num, attr)
    local highAttrData = { }
    for i = 1, num do
        highAttrData[i] = { ["ATTR"] = 0, ["IDX"] = 0 }
    end
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    if #aliveIdTable > 0 then
        for i = 1, #aliveIdTable do
            local idx = aliveIdTable[i]
            if list[idx] then
                local value = list[idx].battleData[attr]
                for n = 1, num do
                    if highAttrData[n]["ATTR"] < value then
                        for m = num, n, -1 do
                            if m == n then
                                highAttrData[n]["ATTR"] = value
                                highAttrData[n]["IDX"] = idx
                            else
                                highAttrData[m]["ATTR"] = highAttrData[m - 1]["ATTR"]
                                highAttrData[m]["IDX"] = highAttrData[m - 1]["IDX"]
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    local targetTable = { }
    for i = 1, num do
        if highAttrData[i]["IDX"] > 0 then
            table.insert(targetTable, list[highAttrData[i]["IDX"]])
        else
            break
        end
    end
    return targetTable
end
-- 取得隨機目標n名
function SkillUtil:getRandomTarget(attacker, list, num, addCond)
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    local targetTable = { }
    if #aliveIdTable == 0 then
        targetTable = { }
    elseif #aliveIdTable <= num then
        for i = 1, #aliveIdTable do
            table.insert(targetTable, list[aliveIdTable[i]])
        end
    else
        if addCond and addCond == CONST.SKILL_TARGET_CONDITION.WITHOUT_BUFF_TAUNT then
            local condIdTable = { }
            local notCondIdTable = { }
            -- 分類: 有嘲諷/沒嘲諷
            for i = 1, #aliveIdTable do
                if not list[aliveIdTable[i]].buffData[200001 + CONST.BUFF.TAUNT * 100] then
                    table.insert(condIdTable, aliveIdTable[i])
                else
                    table.insert(notCondIdTable, aliveIdTable[i])
                end
            end 
            -- 沒嘲諷的id隨機排序
            for i = 1, #condIdTable do
                local rand = math.random(1, #condIdTable)
                local temp = condIdTable[i]
                condIdTable[i] = condIdTable[rand]
                condIdTable[rand] = temp
            end
            -- 優先塞入沒嘲諷的id
            for i = 1, num do
                if condIdTable[i] then
                    table.insert(targetTable, list[condIdTable[i]])
                end
            end
            -- 數量不足時放入有嘲諷的id
            if #targetTable < num then
                for i = 1, num - #targetTable do
                    if notCondIdTable[i] then
                        table.insert(targetTable, list[notCondIdTable[i]])
                    end
                end
            end
        elseif addCond and addCond == CONST.SKILL_TARGET_CONDITION.WITHOUT_SELF then
            local condIdTable = { }
            for i = 1, #aliveIdTable do
                if list[aliveIdTable[i]].idx ~= attacker.idx then
                    table.insert(condIdTable, aliveIdTable[i])
                end
            end 
            for i = 1, #condIdTable do
                local rand = math.random(1, #condIdTable)
                local temp = condIdTable[i]
                condIdTable[i] = condIdTable[rand]
                condIdTable[rand] = temp
            end
            for i = 1, num do
                if condIdTable[i] then
                    table.insert(targetTable, list[condIdTable[i]])
                end
            end
        else
            for i = 1, #aliveIdTable do
                local rand = math.random(1, #aliveIdTable)
                local temp = aliveIdTable[i]
                aliveIdTable[i] = aliveIdTable[rand]
                aliveIdTable[rand] = temp
            end
            for i = 1, num do
                table.insert(targetTable, list[aliveIdTable[i]])
            end
        end
    end

    return targetTable
end
-- 特定目標是否存活
function SkillUtil:isTargetAlive(target, list)
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- 存活的idx列表
    for i = 1, #aliveIdTable do
        if list[aliveIdTable[i]].idx == target.idx then
            return true
        end
    end
    return false
end

return SkillUtil