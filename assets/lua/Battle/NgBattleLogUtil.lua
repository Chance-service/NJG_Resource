NgBattleLogUtil = NgBattleLogUtil or {}

local CONST = require("Battle.NewBattleConst")
require("Battle.NgBattleDataManager")

NgBattleLogUtil.TestLogType = {
    CAST_ATTACK = 1, CAST_SKILL = 2, NORMAL_ATTACK = 3, SKILL_ATTACK = 4, BUFF_ATTACK = 5, LEECH_HEALTH = 6, SKILL_HEALTH = 7, BUFF_HEALTH = 8, GAIN_BUFF = 9,
    REMOVE_BUFF = 10, ADD_SHIELD = 11, ATTACK_MISS = 12, SKILL_MISS = 13, ATTACK_ADD_MP = 14, SKILL_ADD_MP = 15, BEATTACK_ADD_MP = 16, LOSE_MP = 17, DEAD = 18,
}
NgBattleLogUtil.TestLogResult = {
    NORMAL = 1, CRI = 2, MISS = 3
}
-------------------------------------------------------
-- 紀錄log2
function NgBattleLogUtil:addTestLog(actionType, attacker, target, skillId, weak, cri, value)
    if NgBattleDataManager.battleType ~= CONST.SCENE_TYPE.AFK and NgBattleDataManager.battleState ~= CONST.FIGHT_STATE.EDIT_TEAM then
        NgBattleDataManager.battleLog = NgBattleDataManager.battleLog or { }
        local log = { }
        -------------------------------------------------------------------------------
        log.idx = #NgBattleDataManager.battleTestLog + 1
        log.action = actionType
        log.attacker = GameUtil:deepCopy(attacker)
        log.attackerIdx = attacker and attacker.idx
        log.target = GameUtil:deepCopy(target)
        log.targetIdx = target and target.idx
        log.skillId = skillId
        log.cri = cri
        log.value = value
        log.time = tonumber(math.floor(NgBattleDataManager.battleTime))   -- 毫秒
        -------------------------------------------------------------------------------
        table.insert(NgBattleDataManager.battleTestLog, log)
    end
end
-- 紀錄log
-- Action 1: 攻擊 2: 回血 3: 回魔
function NgBattleLogUtil:addLog(actionType, attacker, targetList, skillId, skillGroupId, actionResultTable, passiveTable, logTime)

end

function NgBattleLogUtil:addBuffLog(chaNode, buffId)

end

function NgBattleLogUtil:addAttackLog(chaNode, skillId, skillGroupId)
    chaNode.attackLogData.skillId = skillId
    chaNode.attackLogData.skillGroupId = skillGroupId
end

function NgBattleLogUtil:setPreLog(chaNode, resultTable, isHit)
    chaNode.battleData[CONST.BATTLE_DATA.PRE_HP] = chaNode.battleData[CONST.BATTLE_DATA.HP]
    chaNode.battleData[CONST.BATTLE_DATA.PRE_MP] = chaNode.battleData[CONST.BATTLE_DATA.MP]
    chaNode.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = chaNode.battleData[CONST.BATTLE_DATA.SHIELD]
    if resultTable then
        if resultTable[NewBattleConst.LogDataType.DMG_TAR] then
            for dmgTar = 1, #resultTable[NewBattleConst.LogDataType.DMG_TAR] do
                local tar = resultTable[NewBattleConst.LogDataType.DMG_TAR][dmgTar]
                tar.battleData[CONST.BATTLE_DATA.PRE_HP] = tar.battleData[CONST.BATTLE_DATA.HP]
                tar.battleData[CONST.BATTLE_DATA.PRE_MP] = tar.battleData[CONST.BATTLE_DATA.MP]
                tar.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = tar.battleData[CONST.BATTLE_DATA.SHIELD]
            end
        end
        if resultTable[NewBattleConst.LogDataType.HEAL_TAR] then
            for healTar = 1, #resultTable[NewBattleConst.LogDataType.HEAL_TAR] do
                local tar = resultTable[NewBattleConst.LogDataType.HEAL_TAR][healTar]
                tar.battleData[CONST.BATTLE_DATA.PRE_HP] = tar.battleData[CONST.BATTLE_DATA.HP]
                tar.battleData[CONST.BATTLE_DATA.PRE_MP] = tar.battleData[CONST.BATTLE_DATA.MP]
                tar.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = tar.battleData[CONST.BATTLE_DATA.SHIELD]
            end
        end
        if resultTable[NewBattleConst.LogDataType.BUFF_TAR] then
            for buffTar = 1, #resultTable[NewBattleConst.LogDataType.BUFF_TAR] do
                local tar = resultTable[NewBattleConst.LogDataType.BUFF_TAR][buffTar]
                tar.battleData[CONST.BATTLE_DATA.PRE_HP] = tar.battleData[CONST.BATTLE_DATA.HP]
                tar.battleData[CONST.BATTLE_DATA.PRE_MP] = tar.battleData[CONST.BATTLE_DATA.MP]
                tar.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = tar.battleData[CONST.BATTLE_DATA.SHIELD]
            end
        end
        if resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] then
            for mpTar = 1, #resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR] do
                local tar = resultTable[NewBattleConst.LogDataType.SP_GAIN_MP_TAR][mpTar]
                tar.battleData[CONST.BATTLE_DATA.PRE_HP] = tar.battleData[CONST.BATTLE_DATA.HP]
                tar.battleData[CONST.BATTLE_DATA.PRE_MP] = tar.battleData[CONST.BATTLE_DATA.MP]
                tar.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = tar.battleData[CONST.BATTLE_DATA.SHIELD]
            end
        end
        if resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] then
            for spTar = 1, #resultTable[NewBattleConst.LogDataType.SP_FUN_TAR] do
                local tar = resultTable[NewBattleConst.LogDataType.SP_FUN_TAR][spTar]
                tar.battleData[CONST.BATTLE_DATA.PRE_HP] = tar.battleData[CONST.BATTLE_DATA.HP]
                tar.battleData[CONST.BATTLE_DATA.PRE_MP] = tar.battleData[CONST.BATTLE_DATA.MP]
                tar.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = tar.battleData[CONST.BATTLE_DATA.SHIELD]
            end
        end
    end
end

function NgBattleLogUtil:printLog(attacker, target, formatStr)
    local id = #NgBattleDataManager.battleLog + 1
    local buffIdStr = ""
    for k, v in pairs(attacker.buffData) do
        buffIdStr = buffIdStr .. k .. ","
    end
    local buffIdStr2 = ""
    for k, v in pairs(target.buffData) do
        buffIdStr2 = buffIdStr2 .. k .. ","
    end
    local logStr = string.format("logId = %d,attackidx = %d ,targetidx = %d,attackBuff = %s targetBuff = %s Infor:{%s} \n",id,attacker.idx,target.idx,buffIdStr,buffIdStr2,formatStr)
    self:getMsg(logStr)
    CCLuaLog(logStr)
end

--清除log
function NgBattleLogUtil:clearLog()
    NgBattleDataManager.battleLog = nil
end
--取得log
function NgBattleLogUtil:getLog()
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        local str = self:dump(NgBattleDataManager.battleLog, 1)
        --CCLuaLog(str)
        -- 以附加的方式打?只?文件
        local testFile = io.open("TEST.txt", "w")
        -- 在文件最后一行添加 Lua 注?
        testFile:write(str)
    end
    return NgBattleDataManager.battleLog
end
function NgBattleLogUtil:getMsg(aMsg)
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        --local str = self:dump(NgBattleDataManager.battleLog, 1)
        --CCLuaLog(str)
        -- 以附加的方式打?只?文件
        --local testFile = io.open("TESTMsg.txt", "a+")
        -- 在文件最后一行添加 Lua 注?
        --testFile:write(aMsg)
    end
end
--Print log
function NgBattleLogUtil:dump(o, layer)
    local tabStr = ""
    local tabStr2 = ""
    for i = 1, layer do
        tabStr = tabStr .. "\t"
        if i > 1 then
            tabStr2 = tabStr2 .. "\t"
        end
    end
    if type(o) == 'table' then
        local s = '{ \n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. tabStr .. '['..k..'] = ' .. self:dump(v, layer + 1) .. ',\n'
        end
        return s .. tabStr2 .. '}'
    else
        return tostring(o)
    end
end
--插入log target(不重複插入) 回傳target是否重複
function NgBattleLogUtil:insertLogTarget(targetTable, target)
    for i = 1, #targetTable do
        if targetTable[i] == target then
            return true
        end
    end
    table.insert(targetTable, target)
    return false
end

return NgBattleLogUtil