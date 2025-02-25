SkillUtil = SkillUtil or {}

local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
require("NodeHelper")
-------------------------------------------------------------------------------------------
SkillUtil.AREA_TYPE = {
    ALL       = 0,  -- �Ҧ��Ĥ�
    ELLIPSE_1 = 1,  -- �ۨ��e����ϰ�(params: x, y)
    ELLIPSE_2 = 2,  -- �ۨ����߾��ϰ�(params: x, y)
    AHEAD     = 3,  -- �ۨ��e��
}
-- �o�ʧޯ�ĪG(�L�k�g�b�ޯ�}����)
function SkillUtil:triggerSkillSpecialEffect(chaNode, target, skillId)
    if (not skillId) or (not ConfigManager:getSkillCfg()[skillId]) then
        return
    end
    local baseSkillId = math.floor(skillId / 10)
    local skillCfg = ConfigManager:getSkillCfg()[skillId]
    local params = common:split(skillCfg.values, ",")
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
end
-- ���o�S�w�d�򤺥ؼ�
function SkillUtil:getSkillTarget(chaNode, list, aliveIds, areaType, params, excludeSelf)
    local t = { }
    local heroToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    -- �ۨ��}���y��
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
    -- ����I���P�w�d��(���)
    local tarW, tarH = target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetX, target.otherData[CONST.OTHER_DATA.CFG].CenterOffsetY
    -- ���⤤�߮y��
    local tarX, tarY = target.heroNode.chaCCB:getPositionX(), target.heroNode.chaCCB:getPositionY() + tarH * 0.5
    local result = (((tarX - centerX) * (tarX - centerX)) / ((w + tarW) * (w + tarW))) + (((tarY - centerY) * (tarY - centerY)) / ((h + tarH) * (h + tarH)))
    return result <= 1
end
-- ���oMp��ҳ̰��ؼ�
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
-- ���o�����O�̰��ؼ�
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
-- ���o���m�O�̧C�ؼ�
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
-- ���ohp��Ұ��ؼ�n�W
function SkillUtil:getHighHpTarget(attacker, list, num, addCond)
    local lowHpPerData = { }
    for i = 1, num do
        lowHpPerData[i] = { ["PER"] = 0, ["IDX"] = 0 }
    end
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
-- ���ohp��ҳ̧C�ؼ�n�W
function SkillUtil:getLowHpTarget(attacker, list, num, addCond)
    local lowHpPerData = { }
    for i = 1, num do
        lowHpPerData[i] = { ["PER"] = 999, ["IDX"] = 0 }
    end
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
-- ���ohp�C��S�w��ҥؼ�
function SkillUtil:getLowHpPerTarget(attacker, list, per, includeSelf)
    local targetTable = { }
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
-- ���o�Z���̪�ؼ�n�W
function SkillUtil:getLowDistanceTarget(attacker, list, num)
    local lowDisData = { }
    for i = 1, num do
        lowDisData[i] = { ["DIS"] = 999999, ["IDX"] = 0 }
    end
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
-- ���o�S�w�ݩʳ̰��ؼ�n�W
function SkillUtil:getHighAttrTarget(attacker, list, num, attr)
    local highAttrData = { }
    for i = 1, num do
        highAttrData[i] = { ["ATTR"] = 0, ["IDX"] = 0 }
    end
    local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
-- ���o�H���ؼ�n�W
function SkillUtil:getRandomTarget(attacker, list, num, addCond)
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
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
            -- ����: ���J��/�S�J��
            for i = 1, #aliveIdTable do
                if not list[aliveIdTable[i]].buffData[200001 + CONST.BUFF.TAUNT * 100] then
                    table.insert(condIdTable, aliveIdTable[i])
                else
                    table.insert(notCondIdTable, aliveIdTable[i])
                end
            end 
            -- �S�J�ت�id�H���Ƨ�
            for i = 1, #condIdTable do
                local rand = math.random(1, #condIdTable)
                local temp = condIdTable[i]
                condIdTable[i] = condIdTable[rand]
                condIdTable[rand] = temp
            end
            -- �u����J�S�J�ت�id
            for i = 1, num do
                if condIdTable[i] then
                    table.insert(targetTable, list[condIdTable[i]])
                end
            end
            -- �ƶq�����ɩ�J���J�ت�id
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
-- �S�w�ؼЬO�_�s��
function SkillUtil:isTargetAlive(target, list)
    local aliveIdTable = NewBattleUtil:initAliveTable(list)   -- �s����idx�C��
    for i = 1, #aliveIdTable do
        if list[aliveIdTable[i]].idx == target.idx then
            return true
        end
    end
    return false
end

return SkillUtil