local thisPageName = "BattleLogDpsPage"
local NodeHelper = require("NodeHelper")
local pageManager = require("PageManager")
local common = require("common")
local CONST = require("Battle.NewBattleConst")
local LOG_UTIL = require("Battle.NgBattleLogUtil")
require("Battle.NewBattleUtil")
local UserMercenaryManager = require("UserMercenaryManager")
local buffConfig = ConfigManager:getNewBuffCfg()
require("Battle.NgBattleDataManager")

BattleLogDpsPage = BattleLogDpsPage or { }
local option = {
    ccbiFile = "BattleDpsPage.ccbi",
    handlerMap =
    {
        onTab1 = "onTab1",
        onTab2 = "onTab2",
        onClose = "onClose",
    }
}
for i = 1, 10 do
    option.handlerMap["onChar" .. i] = "onChar"
    option.handlerMap["onDmg" .. i] = "onDmg"
end

BattleLogDpsPage.SELECT_TYPE = { DAMAGE = 1, HEALTH = 2 }
BattleLogDpsPage.CHAR_MINE_BAR_COLOR = { startColor = ccc3(58, 117, 255), endColor = ccc3(110, 214, 255) }
BattleLogDpsPage.CHAR_ENEMY_BAR_COLOR = { startColor = ccc3(255, 34, 11), endColor = ccc3(255, 109, 132) }
BattleLogDpsPage.DMG_ATTACK_BAR_COLOR = { startColor = ccc3(90, 190, 37), endColor = ccc3(137, 255, 157) }
BattleLogDpsPage.DMG_SKILL_BAR_COLOR = { startColor = ccc3(255, 121, 18), endColor = ccc3(255, 224, 128) }
BattleLogDpsPage.DMG_BUFF_BAR_COLOR = { startColor = ccc3(144, 18, 197), endColor = ccc3(238, 140, 251) }

BattleLogDpsPage.analyzeLog = { log = { }, dmgMaxValue = 0, healthMaxValue = 0 }
BattleLogDpsPage.selectTab = nil
BattleLogDpsPage.selectChar = 0
BattleLogDpsPage.selectDmg = 0
------------------------------------------------

function BattleLogDpsPage:onEnter(container)
    self:clearData(container)
    self:analyzeBattleLog(container)
    self:onTab1(container)
end

function BattleLogDpsPage:clearData(container)
    for i = 1, 10 do
        NodeHelper:setNodesVisible(container, { ["mCharNode" .. i] = false, ["mCharSelect" .. i] = false, 
                                                ["mDmgNode" .. i] = false, ["mDmgSelect" .. i] = false,
                                                ["mDetailNode" .. i] = false })
    end
    BattleLogDpsPage.analyzeLog = { log = { }, dmgMaxValue = 0, healthMaxValue = 0 }
    BattleLogDpsPage.selectTab = nil
    BattleLogDpsPage.selectChar = 0
    BattleLogDpsPage.selectDmg = 0
end

function BattleLogDpsPage:analyzeBattleLog(container)
    local log = NgBattleDataManager.battleTestLog
    for i = 1, #log do
        BattleLogDpsPage.analyzeLog.log[log[i].attackerIdx] = BattleLogDpsPage.analyzeLog.log[log[i].attackerIdx] or { }
        local charLog = BattleLogDpsPage.analyzeLog.log[log[i].attackerIdx]
        charLog.attacker = log[i].attacker
        charLog.dmgMaxValue = charLog.dmgMaxValue or 0
        charLog.healthMaxValue = charLog.healthMaxValue or 0
        charLog.totalDmg = charLog.totalDmg or 0
        charLog.totalHealth = charLog.totalHealth or 0
        if log[i].action == LOG_UTIL.TestLogType.CAST_SKILL or
           log[i].action == LOG_UTIL.TestLogType.CAST_ATTACK then
            local skillId = (log[i].action == LOG_UTIL.TestLogType.CAST_ATTACK) and 0 or log[i].skillId
            charLog[skillId] = charLog[skillId] or { }
            charLog[skillId].cast = charLog[skillId].cast and charLog[skillId].cast + 1 or 1
        elseif log[i].action == LOG_UTIL.TestLogType.NORMAL_ATTACK or
               log[i].action == LOG_UTIL.TestLogType.SKILL_ATTACK or
               log[i].action == LOG_UTIL.TestLogType.BUFF_ATTACK then
            local skillId = (log[i].action == LOG_UTIL.TestLogType.NORMAL_ATTACK) and 0 or log[i].skillId
            charLog[skillId] = charLog[skillId] or { }
            -- 角色(全部)總傷害
            charLog.totalDmg = charLog.totalDmg and charLog.totalDmg + log[i].value or log[i].value
            -- 角色(該技能)總命中(+Miss)次數
            charLog[skillId].dmgCount = charLog[skillId].dmgCount and charLog[skillId].dmgCount + 1 or 1
            -- 角色(該技能)總傷害
            charLog[skillId].dmg = charLog[skillId].dmg and charLog[skillId].dmg + log[i].value or log[i].value
            if log[i].cri then
                -- 角色(該技能)爆擊次數
                charLog[skillId].dmgCriCount = charLog[skillId].dmgCriCount and charLog[skillId].dmgCriCount + 1 or 1
                -- 角色(該技能)爆擊傷害
                charLog[skillId].dmgCri = charLog[skillId].dmgCri and charLog[skillId].dmgCri + log[i].value or log[i].value
                charLog[skillId].dmgCriMin = charLog[skillId].dmgCriMin and math.min(charLog[skillId].dmgCriMin, log[i].value) or log[i].value
                charLog[skillId].dmgCriMax = charLog[skillId].dmgCriMax and math.max(charLog[skillId].dmgCriMax, log[i].value) or log[i].value
            else
                -- 角色(該技能)一般命中次數
                charLog[skillId].dmgHitCount = charLog[skillId].dmgHitCount and charLog[skillId].dmgHitCount + 1 or 1
                -- 角色(該技能)一般命中傷害
                charLog[skillId].dmgHit = charLog[skillId].dmgHit and charLog[skillId].dmgHit + log[i].value or log[i].value
                charLog[skillId].dmgHitMin = charLog[skillId].dmgHitMin and math.min(charLog[skillId].dmgHitMin, log[i].value) or log[i].value
                charLog[skillId].dmgHitMax = charLog[skillId].dmgHitMax and math.max(charLog[skillId].dmgHitMax, log[i].value) or log[i].value
            end
            charLog.dmgMaxValue = math.max(charLog.dmgMaxValue, charLog[skillId].dmg)
            charLog[skillId].dmgMin = charLog[skillId].dmgMin and math.min(charLog[skillId].dmgMin, log[i].value) or log[i].value
            charLog[skillId].dmgMax = charLog[skillId].dmgMax and math.max(charLog[skillId].dmgMax, log[i].value) or log[i].value
            BattleLogDpsPage.analyzeLog.dmgMaxValue = math.max(BattleLogDpsPage.analyzeLog.dmgMaxValue, charLog.totalDmg)
        elseif log[i].action == LOG_UTIL.TestLogType.LEECH_HEALTH or
               log[i].action == LOG_UTIL.TestLogType.SKILL_HEALTH or
               log[i].action == LOG_UTIL.TestLogType.BUFF_HEALTH or
               log[i].action == LOG_UTIL.TestLogType.ADD_SHIELD then
            local skillId = (log[i].action == LOG_UTIL.TestLogType.LEECH_HEALTH) and 0 or log[i].skillId
            charLog[skillId] = charLog[skillId] or { }
            -- 角色(全部)總治療
            charLog.totalHealth = charLog.totalHealth and charLog.totalHealth + log[i].value or log[i].value
            -- 角色(該技能)總命中(+Miss)次數
            charLog[skillId].healthCount = charLog[skillId].healthCount and charLog[skillId].healthCount + 1 or 1
            -- 角色(該技能)總治療
            charLog[skillId].health = charLog[skillId].health and charLog[skillId].health + log[i].value or log[i].value
            if log[i].cri then
                -- 角色(該技能)爆擊次數
                charLog[skillId].healthCriCount = charLog[skillId].healthCriCount and charLog[skillId].healthCriCount + 1 or 1
                -- 角色(該技能)爆擊治療
                charLog[skillId].healthCri = charLog[skillId].healthCri and charLog[skillId].healthCri + log[i].value or log[i].value
                charLog[skillId].healthCriMin = charLog[skillId].healthCriMin and math.min(charLog[skillId].healthCriMin, log[i].value) or log[i].value
                charLog[skillId].healthCriMax = charLog[skillId].healthCriMax and math.max(charLog[skillId].healthCriMax, log[i].value) or log[i].value
            else
                -- 角色(該技能)一般命中次數
                charLog[skillId].healthHitCount = charLog[skillId].healthHitCount and charLog[skillId].healthHitCount + 1 or 1
                -- 角色(該技能)一般命中治療
                charLog[skillId].healthHit = charLog[skillId].healthHit and charLog[skillId].healthHit + log[i].value or log[i].value
                charLog[skillId].healthHitMin = charLog[skillId].healthHitMin and math.min(charLog[skillId].healthHitMin, log[i].value) or log[i].value
                charLog[skillId].healthHitMax = charLog[skillId].healthHitMax and math.max(charLog[skillId].healthHitMax, log[i].value) or log[i].value
            end
            charLog.healthMaxValue = math.max(charLog.healthMaxValue, charLog[skillId].health)
            charLog[skillId].healthMin = charLog[skillId].healthMin and math.min(charLog[skillId].healthMin, log[i].value) or log[i].value
            charLog[skillId].healthMax = charLog[skillId].healthMax and math.max(charLog[skillId].healthMax, log[i].value) or log[i].value
            BattleLogDpsPage.analyzeLog.healthMaxValue = math.max(BattleLogDpsPage.analyzeLog.healthMaxValue, charLog.totalHealth)
        elseif log[i].action == LOG_UTIL.TestLogType.ATTACK_MISS or
               log[i].action == LOG_UTIL.TestLogType.SKILL_MISS then
            local skillId = (log[i].action == LOG_UTIL.TestLogType.ATTACK_MISS) and 0 or log[i].skillId
            charLog[skillId] = charLog[skillId] or { }
            -- 角色(該技能)總命中(+Miss)次數
            charLog[skillId].dmgCount = charLog[skillId].dmgCount and charLog[skillId].dmgCount + 1 or 1
            -- 角色(該技能)Miss次數
            charLog[skillId].dmgMissCount = charLog[skillId].dmgMissCount and charLog[skillId].dmgMissCount + 1 or 1
            charLog[skillId].dmgMin = charLog[skillId].dmgMin and math.min(charLog[skillId].dmgMin, 0) or 0
            charLog[skillId].dmgMax = charLog[skillId].dmgMax and math.max(charLog[skillId].dmgMax, 0) or 0
        end
    end
end

function BattleLogDpsPage:onTab1(container)
    if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
        return
    end
    BattleLogDpsPage.selectTab = BattleLogDpsPage.SELECT_TYPE.DAMAGE
    NodeHelper:setNodesVisible(container, { mTabOn1 = true, mTabOn2 = false })
    BattleLogDpsPage.selectChar = 0
    BattleLogDpsPage.selectDmg = 0
    for i = 1, 10 do
        NodeHelper:setNodesVisible(container, { ["mCharNode" .. i] = false, ["mCharSelect" .. i] = false, 
                                                ["mDmgNode" .. i] = false, ["mDmgSelect" .. i] = false,
                                                ["mDetailNode" .. i] = false })
    end
    self:refreshUI(container)
end

function BattleLogDpsPage:onTab2(container)
    if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.HEALTH then
        return
    end
    BattleLogDpsPage.selectTab = BattleLogDpsPage.SELECT_TYPE.HEALTH
    NodeHelper:setNodesVisible(container, { mTabOn1 = false, mTabOn2 = true })
    BattleLogDpsPage.selectChar = 0
    BattleLogDpsPage.selectDmg = 0
    for i = 1, 10 do
        NodeHelper:setNodesVisible(container, { ["mCharNode" .. i] = false, ["mCharSelect" .. i] = false, 
                                                ["mDmgNode" .. i] = false, ["mDmgSelect" .. i] = false,
                                                ["mDetailNode" .. i] = false })
    end
    self:refreshUI(container)
end

function BattleLogDpsPage:onChar(container, eventName)
    local idx = tonumber(eventName:sub(7))
    BattleLogDpsPage.selectChar = idx
    BattleLogDpsPage.selectDmg = 0
    for i = 1, 10 do
        NodeHelper:setNodesVisible(container, { ["mCharSelect" .. i] = (i == idx) })
        NodeHelper:setNodesVisible(container, { ["mDmgSelect" .. i] = false })
    end
    self:refreshUI(container)
end

function BattleLogDpsPage:onDmg(container, eventName)
    local idx = tonumber(eventName:sub(6))
    BattleLogDpsPage.selectDmg = idx
    for i = 1, 10 do
        NodeHelper:setNodesVisible(container, { ["mDmgSelect" .. i] = (i == idx) })
    end
    self:refreshUI(container)
end

function BattleLogDpsPage:refreshUI(container)
    local sortCharLog = { }
    local sortDmgLog = { }
    for k, v in pairs(BattleLogDpsPage.analyzeLog.log) do
        table.insert(sortCharLog, { idx = k, log = v })
    end
    -- 對角色總傷害/治療排序
    if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
        table.sort(sortCharLog, function(data1, data2)
            if not data1 or not data2 then
                return false
            end
            if data1 == data2 then
                return false
            end
            if data1.log.totalDmg > data2.log.totalDmg then
                return true
            end
            if data1.log.totalDmg < data2.log.totalDmg then
                return false
            end
            if data1.idx < data2.idx then
                return true
            end
            return false
        end)
    else
        table.sort(sortCharLog, function(data1, data2)
            if not data1 or not data2 then
                return false
            end
            if data1 == data2 then
                return false
            end
            if data1.log.totalHealth > data2.log.totalHealth then
                return true
            end
            if data1.log.totalHealth < data2.log.totalHealth then
                return false
            end
            if data1.idx < data2.idx then
                return true
            end
            return false
        end)
    end
    -- 對選擇的角色技能傷害/治療排序
    if BattleLogDpsPage.selectChar > 0 then
        for k, v in pairs(sortCharLog[BattleLogDpsPage.selectChar].log) do
            if tonumber(k) then
                if (BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE) and v.dmg then
                    table.insert(sortDmgLog, { skillId = k, log = v })
                elseif (BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.HEALTH) and v.health then
                    table.insert(sortDmgLog, { skillId = k, log = v })
                end
            end
        end
        if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
            table.sort(sortDmgLog, function(data1, data2)
                if not data1 or not data2 then
                    return false
                end
                if data1 == data2 then
                    return false
                end
                if data1.log.dmg > data2.log.dmg then
                    return true
                end
                if data1.log.dmg < data2.log.dmg then
                    return false
                end
                return false
            end)
        else
            table.sort(sortDmgLog, function(data1, data2)
                if not data1 or not data2 then
                    return false
                end
                if data1 == data2 then
                    return false
                end
                if data1.log.health > data2.log.health then
                    return true
                end
                if data1.log.health < data2.log.health then
                    return false
                end
                return false
            end)
        end
    end
    -- 設定角色傷害/治療圖表顯示
    for i = 1, 10 do
        if sortCharLog[i] then
            local bar = container:getVarNode("mCharBar" .. i)
            local barLayer = tolua.cast(bar, "CCLayerGradient")
            if sortCharLog[i].idx < 10 then
                barLayer:setStartColor(BattleLogDpsPage.CHAR_MINE_BAR_COLOR.startColor)
                barLayer:setEndColor(BattleLogDpsPage.CHAR_MINE_BAR_COLOR.endColor)
            else
                barLayer:setStartColor(BattleLogDpsPage.CHAR_ENEMY_BAR_COLOR.startColor)
                barLayer:setEndColor(BattleLogDpsPage.CHAR_ENEMY_BAR_COLOR.endColor)
            end
            if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
                local per = (sortCharLog[1].log.totalDmg == 0) and 0 or (sortCharLog[i].log.totalDmg / sortCharLog[1].log.totalDmg)
                bar:setScaleX(math.max(0, math.min(1, per)))
                NodeHelper:setStringForLabel(container, { ["mCharName" .. i] = self:getCharName(sortCharLog[i].log.attacker, sortCharLog[i].idx), 
                                                          ["mCharDmg" .. i] = sortCharLog[i].log.totalDmg, 
                                                          ["mCharDps" .. i] = NewBattleUtil:calRoundValue(sortCharLog[i].log.totalDmg / (NgBattleDataManager.battleTime / 1000), -2) })
            else
                local per = (sortCharLog[1].log.totalHealth == 0) and 0 or (sortCharLog[i].log.totalHealth / sortCharLog[1].log.totalHealth)
                bar:setScaleX(math.max(0, math.min(1, per)))
                NodeHelper:setStringForLabel(container, { ["mCharName" .. i] = self:getCharName(sortCharLog[i].log.attacker, sortCharLog[i].idx), 
                                                          ["mCharDmg" .. i] = sortCharLog[i].log.totalHealth, 
                                                          ["mCharDps" .. i] = NewBattleUtil:calRoundValue(sortCharLog[i].log.totalHealth / (NgBattleDataManager.battleTime / 1000), -2) })
            end
            -- 頭像設定
            local itemId = sortCharLog[i].log.attacker.otherData[CONST.OTHER_DATA.ITEM_ID]
            local roleType = sortCharLog[i].log.attacker.otherData[CONST.OTHER_DATA.CHARACTER_TYPE]
            if roleType == CONST.CHARACTER_TYPE.HERO then
                if sortCharLog[i].idx < 10 then
                    local roleInfo = UserMercenaryManager:getUserMercenaryByItemId(itemId)
                    NodeHelper:setSpriteImage(container, { ["mCharIcon" .. i] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", roleInfo.skinId) .. ".png" })
                else
                    local skinId = eData.otherData[CONST.OTHER_DATA.SPINE_SKIN]
                    NodeHelper:setSpriteImage(container, { ["mCharIcon" .. i] = "UI/RoleIcon/Icon_" .. string.format("%02d", itemId) .. string.format("%03d", skinId) .. ".png" })
                end
            elseif roleType == CONST.CHARACTER_TYPE.MONSTER or roleType == CONST.CHARACTER_TYPE.WORLDBOSS then
                local cfg = ConfigManager.getNewMonsterCfg()[itemId]
                NodeHelper:setSpriteImage(container, { ["mCharIcon" .. i] = cfg.Icon })
            end
        end
        NodeHelper:setNodesVisible(container, { ["mCharNode" .. i] = (sortCharLog[i] and true or false) })
    end
    -- 設定選擇的角色技能傷害/治療圖表顯示
    for i = 1, 10 do
        if sortDmgLog[i] then
            local bar = container:getVarNode("mDmgBar" .. i)
            local barLayer = tolua.cast(bar, "CCLayerGradient")
            if sortDmgLog[i].skillId == 0 then  -- 普攻
                barLayer:setStartColor(BattleLogDpsPage.DMG_ATTACK_BAR_COLOR.startColor)
                barLayer:setEndColor(BattleLogDpsPage.DMG_ATTACK_BAR_COLOR.endColor)
                NodeHelper:setStringForLabel(container, { ["mDmgName" .. i] = "普攻" })
            elseif buffConfig[sortDmgLog[i].skillId] then  -- buff
                barLayer:setStartColor(BattleLogDpsPage.DMG_BUFF_BAR_COLOR.startColor)
                barLayer:setEndColor(BattleLogDpsPage.DMG_BUFF_BAR_COLOR.endColor)
                NodeHelper:setStringForLabel(container, { ["mDmgName" .. i] = common:getLanguageString("@Buff_" .. sortDmgLog[i].skillId) })
            else    -- 技能
                barLayer:setStartColor(BattleLogDpsPage.DMG_SKILL_BAR_COLOR.startColor)
                barLayer:setEndColor(BattleLogDpsPage.DMG_SKILL_BAR_COLOR.endColor)
                if sortDmgLog[i].skillId == 500101 then
                    NodeHelper:setStringForLabel(container, { ["mDmgName" .. i] = common:getLanguageString("小怪技能") })
                else
                    NodeHelper:setStringForLabel(container, { ["mDmgName" .. i] = common:getLanguageString("@Skill_Name_" .. math.floor(sortDmgLog[i].skillId / 10)) })
                end
            end
            if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
                local per = math.max(0, math.min(1, sortDmgLog[i].log.dmg / sortDmgLog[1].log.dmg))
                local per2 = math.max(0, math.min(1, sortDmgLog[i].log.dmg / sortCharLog[BattleLogDpsPage.selectChar].log.totalDmg))
                bar:setScaleX(per)
                NodeHelper:setStringForLabel(container, { ["mDmgDmg" .. i] = sortDmgLog[i].log.dmg, 
                                                          ["mDmgDps" .. i] = NewBattleUtil:calRoundValue(sortDmgLog[i].log.dmg / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDmgPer" .. i] = NewBattleUtil:calRoundValue(per2 * 100, -2) .. "%" })
            else
                local per = math.max(0, math.min(1, sortDmgLog[i].log.health / sortDmgLog[1].log.health))
                local per2 = math.max(0, math.min(1, sortDmgLog[i].log.health / sortCharLog[BattleLogDpsPage.selectChar].log.totalHealth))
                bar:setScaleX(per)
                NodeHelper:setStringForLabel(container, { ["mDmgDmg" .. i] = sortDmgLog[i].log.health, 
                                                          ["mDmgDps" .. i] = NewBattleUtil:calRoundValue(sortDmgLog[i].log.health / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDmgPer" .. i] = NewBattleUtil:calRoundValue(per2 * 100, -2) .. "%" })
            end
        end
        NodeHelper:setNodesVisible(container, { ["mDmgNode" .. i] = (sortDmgLog[i] and true or false) })
    end
    -- 設定選擇的角色技能詳細資訊顯示
    for i = 1, 4 do
        if sortDmgLog[BattleLogDpsPage.selectDmg] then
            local log = sortDmgLog[BattleLogDpsPage.selectDmg].log
            if BattleLogDpsPage.selectTab == BattleLogDpsPage.SELECT_TYPE.DAMAGE then
                local per1 = log.dmgHitCount and (log.dmgHitCount / log.dmgCount) or 0
                local per2 = log.dmgCriCount and (log.dmgCriCount / log.dmgCount) or 0
                local per3 = log.dmgMissCount and (log.dmgMissCount / log.dmgCount) or 0
                NodeHelper:setStringForLabel(container, { ["mDetail1Txt1"] = "施放 : " .. (log.cast or log.dmgCount),
                                                          ["mDetail1Txt2"] = "總次數 : " .. log.dmgCount .. "[100%]",
                                                          ["mDetail1Txt3"] = "傷害 : " .. (log.dmg or 0),
                                                          ["mDetail1Txt4"] = "Dps : " .. NewBattleUtil:calRoundValue(log.dmg / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail1Txt5"] = "Min : " .. (log.dmgMin or 0), ["mDetail1Txt6"] = "Max : " .. (log.dmgMax or 0),
                                                          ["mDetail1Txt7"] = "Avg : " .. NewBattleUtil:calRoundValue(log.dmg / log.dmgCount, -2) })
                NodeHelper:setStringForLabel(container, { ["mDetail2Txt2"] = "總次數 : " .. (log.dmgHitCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per1 * 100, -2) .. "%]",
                                                          ["mDetail2Txt3"] = "傷害 : " .. (log.dmgHit or 0),
                                                          ["mDetail2Txt4"] = "Dps : " .. NewBattleUtil:calRoundValue((log.dmgHit or 0) / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail2Txt5"] = "Min : " .. (log.dmgHitMin or 0), ["mDetail2Txt6"] = "Max : " .. (log.dmgHitMax or 0),
                                                          ["mDetail2Txt7"] = "Avg : " .. (log.dmgHitCount and NewBattleUtil:calRoundValue((log.dmgHit or 0) / (log.dmgHitCount or 0), -2) or 0) })
                NodeHelper:setStringForLabel(container, { ["mDetail3Txt2"] = "總次數 : " .. (log.dmgCriCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per2 * 100, -2) .. "%]",
                                                          ["mDetail3Txt3"] = "傷害 : " .. (log.dmgCri or 0),
                                                          ["mDetail3Txt4"] = "Dps : " .. NewBattleUtil:calRoundValue((log.dmgCri or 0) / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail3Txt5"] = "Min : " .. (log.dmgCriMin or 0), ["mDetail3Txt6"] = "Max : " .. (log.dmgCriMax or 0),
                                                          ["mDetail3Txt7"] = "Avg : " .. (log.dmgCriCount and NewBattleUtil:calRoundValue((log.dmgCri or 0) / (log.dmgCriCount or 0), -2) or 0) })
                NodeHelper:setStringForLabel(container, { ["mDetail4Txt2"] = "總次數 : " .. (log.dmgMissCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per3 * 100, -2) .. "%]" })
                local bar1 = container:getVarNode("mDetailBar" .. 2)
                local bar2 = container:getVarNode("mDetailBar" .. 3)
                local bar3 = container:getVarNode("mDetailBar" .. 4)
                bar1:setScaleX(per1)
                bar2:setScaleX(per2)
                bar3:setScaleX(per3)
            else
                local per1 = log.healthHitCount and (log.healthHitCount / log.healthCount) or 0
                local per2 = log.healthCriCount and (log.healthCriCount / log.healthCount) or 0
                local per3 = log.healthMissCount and (log.healthgMissCount / log.healthCount) or 0
                NodeHelper:setStringForLabel(container, { ["mDetail1Txt1"] = "施放 : " .. (log.cast or log.healthCount),
                                                          ["mDetail1Txt2"] = "總次數 : " .. log.healthCount .. "[100%]",
                                                          ["mDetail1Txt3"] = "治療 : " .. (log.health or 0),
                                                          ["mDetail1Txt4"] = "Hps : " .. NewBattleUtil:calRoundValue(log.health / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail1Txt5"] = "Min : " .. (log.healthMin or 0), ["mDetail1Txt6"] = "Max : " .. (log.healthMax or 0),
                                                          ["mDetail1Txt7"] = "Avg : " .. NewBattleUtil:calRoundValue(log.health / log.healthCount, -2) })
                NodeHelper:setStringForLabel(container, { ["mDetail2Txt2"] = "總次數 : " .. (log.healthHitCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per1 * 100, -2) .. "%]",
                                                          ["mDetail2Txt3"] = "治療 : " .. (log.healthHit or 0),
                                                          ["mDetail2Txt4"] = "Hps : " .. NewBattleUtil:calRoundValue((log.healthHit or 0) / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail2Txt5"] = "Min : " .. (log.healthHitMin or 0), ["mDetail2Txt6"] = "Max : " .. (log.healthHitMax or 0),
                                                          ["mDetail2Txt7"] = "Avg : " .. (log.healthHitCount and NewBattleUtil:calRoundValue((log.healthHit or 0) / (log.healthHitCount or 0), -2) or 0) })
                NodeHelper:setStringForLabel(container, { ["mDetail3Txt2"] = "總次數 : " .. (log.healthCriCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per2 * 100, -2) .. "%]",
                                                          ["mDetail3Txt3"] = "治療 : " .. (log.healthCri or 0),
                                                          ["mDetail3Txt4"] = "Hps : " .. NewBattleUtil:calRoundValue((log.healthCri or 0) / (NgBattleDataManager.battleTime / 1000), -2),
                                                          ["mDetail3Txt5"] = "Min : " .. (log.healthCriMin or 0), ["mDetail3Txt6"] = "Max : " .. (log.healthCriMax or 0),
                                                          ["mDetail3Txt7"] = "Avg : " .. (log.healthCriCount and NewBattleUtil:calRoundValue((log.healthCri or 0) / (log.healthCriCount or 0), -2) or 0) })
                NodeHelper:setStringForLabel(container, { ["mDetail4Txt2"] = "總次數 : " .. (log.healthMissCount or 0) .. " [" .. NewBattleUtil:calRoundValue(per3 * 100, -2) .. "%]" })
                local bar1 = container:getVarNode("mDetailBar" .. 2)
                local bar2 = container:getVarNode("mDetailBar" .. 3)
                local bar3 = container:getVarNode("mDetailBar" .. 4)
                bar1:setScaleX(per1)
                bar2:setScaleX(per2)
                bar3:setScaleX(per3)
            end
        end 
        NodeHelper:setNodesVisible(container, { ["mDetailNode" .. i] = (sortDmgLog[BattleLogDpsPage.selectDmg] and true or false) })
    end
end

function BattleLogDpsPage:getCharName(char, idx)
    if not char then
        return ""
    end
    if char.otherData[CONST.OTHER_DATA.CHARACTER_TYPE] == CONST.CHARACTER_TYPE.HERO then
        return common:getLanguageString("@HeroName_" .. char.otherData[CONST.OTHER_DATA.ITEM_ID])
    else
        return char.otherData[CONST.OTHER_DATA.ITEM_ID]
    end
end

function BattleLogDpsPage:onClose(container)
    self:clearData(container)
    PageManager.popPage(thisPageName)
end

local CommonPage = require("CommonPage")
BattleLogDpsPage = CommonPage.newSub(BattleLogDpsPage, thisPageName, option)

return BattleLogDpsPage