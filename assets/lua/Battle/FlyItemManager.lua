local CONST = require("Battle.NewBattleConst")
require("Battle.NewBattleUtil")
local NgBattleCharacterBase = require("Battle.NgBattleCharacterBase")
local BuffManager = require("Battle.NewBuff.BuffManager")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
local LOG_UTIL = require("Battle.NgBattleLogUtil")
-------------------------------------------------------
FlyItemManager = FlyItemManager or { }
-------------------------------------------------------

local flyItems = { }
FlyItemManager.flyItemFileData = { }

function FlyItemManager:init()
    flyItems = { }
    targetFlyItem = { }
    --flyItemFileData = { }
end

function FlyItemManager:clearData()
    flyItems = { }
    targetFlyItem = { }
    --flyItemFileData = { }
end

function FlyItemManager:update(dt, container)
    for i = #flyItems, 1, -1 do
        if flyItems[i] then
            if flyItems[i].isEnd then
                self:removeItem(flyItems[i])
                table.remove(flyItems, i)
            else
                self:move(dt, flyItems[i])
            end
        end
    end
end

function FlyItemManager:createFlyItem(attacker, target, resultTable, hit, aniName, isSkipCal, skillId, skillGroupId, targetPosX, targetPosY, flyItemType, allPassiveTable, skillTargetTable)
    local flyItem = require("FlyItem")
    local data = FlyItemManager.flyItemFileData[attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME]]
    if not data then
        data = { }
        data[1] = 
            NodeHelper:isFileExist(attacker.otherData[CONST.OTHER_DATA.SPINE_PATH_BULLET] .. "/" .. attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] .. "_bullet_1" .. ".skel")
        data[2] = 
            NodeHelper:isFileExist(attacker.otherData[CONST.OTHER_DATA.SPINE_PATH_BULLET] .. "/" .. attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] .. "_bullet_2" .. ".skel")
        FlyItemManager.flyItemFileData[attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME]] = data
    end
    local itemData = flyItem:initData(attacker, target, resultTable, hit, aniName, isSkipCal, skillId, skillGroupId, targetPosX, targetPosY, flyItemType, allPassiveTable, skillTargetTable)
    if itemData.flyItemType == CONST.FLYITEM_TYPE.TARGET then
        if itemData.spineFrontNode then
            itemData.spineFront:registerFunctionHandler("SELF_EVENT", self.onFunction)
            itemData.spineFrontNode:setTag(#targetFlyItem + 1)
        elseif itemData.spineBackNode then
            itemData.spineBack:registerFunctionHandler("SELF_EVENT", self.onFunction)
            itemData.spineBackNode:setTag(#targetFlyItem + 10001)
        end
        table.insert(targetFlyItem, itemData)
    else
        table.insert(flyItems, itemData)
    end
end

function FlyItemManager:removeItem(data)
    if data.spineFrontNode then
       data.spineFrontNode:removeFromParentAndCleanup(true)
    end
    if data.spineBackNode then
       data.spineBackNode:removeFromParentAndCleanup(true)  
    end
end

function FlyItemManager:move(dt, data)
    if data.isEnd then
        return
    end
    if data.spineFrontNode or data.spineBackNode then
        if data.flyItemType == CONST.FLYITEM_TYPE.SHOOT then
            local speed = 13 * 60
            self:calMove(speed * dt / 1000, data)
        end
    else
        self:onHit(data, true)
    end
end

function FlyItemManager:onHit(data, autoEnd)
    local actionResultTable = {}
    local allTargetTable = {}
    if data.aniName == CONST.ANI_ACT.ATTACK then    -- 命中時重新計算傷害(避免buff時間差)
        data.resultTable = CHAR_UTIL:createAttackResultTable(data.attacker, data.ATTACK_PARAMS)
    elseif data.aniName == CONST.ANI_ACT.SKILL0 or data.aniName == CONST.ANI_ACT.SKILL1 or data.aniName == CONST.ANI_ACT.SKILL2 then
        data.resultTable = NgBattleCharacterBase:onSkillWithTarget(data.attacker, data.skillId, { }, data.allPassiveTable, data.skillTargetTable, data.ATTACK_PARAMS)
    end
    if data.resultTable then
        LOG_UTIL:setPreLog(data.attacker, resultTable)   
        CCLuaLog("Attacker CharacterId : " .. data.attacker.idx)
        local buffEvent = CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK
        local logActionType = CONST.LogActionType.ATTACK
        if data.attacker.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME] == CONST.ANI_ACT.ATTACK then   -- 普通攻擊
            buffEvent = CONST.ADD_BUFF_COUNT_EVENT.NORMAL_ATTACK
            logActionType = CONST.LogActionType.ATTACK
        else
            buffEvent = CONST.ADD_BUFF_COUNT_EVENT.SKILL
            logActionType = CONST.LogActionType.SKILL
        end
        CHAR_UTIL:clearSkillTimer(data.attacker.skillData, buffEvent)      -- 清空特定skill計時
        BuffManager:clearBuffTimer(data.attacker, data.attacker.buffData, buffEvent)      -- 清空特定buff計時
        BuffManager:addBuffCount(data.attacker, data.attacker.buffData, buffEvent)        -- 增加buff層數
        local triggerBuffList = BuffManager:specialBuffEffect(data.attacker.buffData, buffEvent, data.attacker, nil, data.skillId)   -- 觸發buff效果
        CHAR_UTIL:calculateAllTable(data.attacker, data.resultTable, data.isSkipCal, actionResultTable, allTargetTable, data.skillId, data.allPassiveTable)   -- 全部傷害/治療/buff...處理
    end
    -- 檢查被動技能發動(需等log記錄完)
    CHAR_UTIL:checkPassiveSkill(data.attacker)
    data.isEnd = true
    if autoEnd then
        if data.spineFrontNode then
           data.spineFrontNode:setVisible(false) 
        end
        if data.spineBackNode then
           data.spineBackNode:setVisible(false)  
        end
    end
end

function FlyItemManager:onFunction(tag, eventName)
    if tag > 10000 then
        tag = tag - 10000
    end
    if not targetFlyItem or not targetFlyItem[tag] then
        return
    end
    if eventName == "hit" then
        FlyItemManager:onHit(targetFlyItem[tag], false)
    elseif eventName == "end" then
        if targetFlyItem[tag].spineFrontNode then
            targetFlyItem[tag].spineFrontNode:setVisible(false)
        end
        if targetFlyItem[tag].spineBackNode then
            targetFlyItem[tag].spineBackNode:setVisible(false)
        end
    end
end

function FlyItemManager:calMove(speed, data)
    local itemPosX = (data.spineFrontNode and data.spineFrontNode:getPositionX()) or 
                     (data.spineBackNode and data.spineBackNode:getPositionX()) or 
                     0
    local itemPosY = (data.spineFrontNode and data.spineFrontNode:getPositionY()) or 
                     (data.spineBackNode and data.spineBackNode:getPositionY()) or 
                     0
    local tarPosX = data.targetPosX
    local tarPosY = data.targetPosY
    local disX = tarPosX - itemPosX
    local disY = tarPosY - itemPosY
    local dis = math.pow(( math.pow(disX, 2) + math.pow(disY, 2) ), 0.5)
    local speedX = speed * (disX / dis)
    local speedY = speed * (disY / dis)

    if speed >= dis then
        --擊中目標
        if data.spineFrontNode then
           data.spineFrontNode:setPosition(ccp(tarPosX, tarPosY))  
        end
        if data.spineBackNode then
           data.spineBackNode:setPosition(ccp(tarPosX, tarPosY))  
        end
        self:onHit(data, true)
    else
        if data.spineFrontNode then
            data.spineFrontNode:setPosition(ccp(itemPosX + speedX, itemPosY + speedY))
            if data.initAction then
               data.spineFrontNode:stopAllActions()
               local array = CCArray:create()
               local degree = math.deg( math.acos(disX / dis) ) * (disY > 0 and -1 or 1)
               array:addObject(CCEaseIn:create(CCRotateTo:create(0.6, degree), 1))
               data.spineFrontNode:runAction(CCSequence:create(array))
            end
            --設定Z Order
            data.spineFrontNode:setZOrder(CONST.Z_ORDER_MASK - itemPosY)
        end
        if data.spineBackNode then
            data.spineBackNode:setPosition(ccp(itemPosX + speedX, itemPosY + speedY))  
            if data.initAction then
                data.spineBackNode:stopAllActions()
                local array = CCArray:create()
                local degree = math.deg( math.acos(disX / dis) ) * (disY > 0 and -1 or 1)
                array:addObject(CCEaseIn:create(CCRotateTo:create(0.6, degree), 1))
                data.spineBackNode:runAction(CCSequence:create(array))
            end
            --設定Z Order
            data.spineBackNode:setZOrder(CONST.Z_ORDER_MASK - itemPosY)
        end
        data.initAction = false
    end
end

function FlyItemManager:setSceneSpeed(sceneSpeed)
    for i = #flyItems, 1, -1 do
        if flyItems[i] then
            if not flyItems[i].isEnd then
                if flyItems[i].spineFront then
                   flyItems[i].spineFront:setTimeScale(sceneSpeed)
                end
                if flyItems[i].spineBack then
                   flyItems[i].spineBack:setTimeScale(sceneSpeed)  
                end
            end
        end
    end
end

--設定PRE HP, MP, SHIELD
function FlyItemManager:setPreLog(node, resultTable)
    node.battleData[CONST.BATTLE_DATA.PRE_HP] = node.battleData[CONST.BATTLE_DATA.HP]
    node.battleData[CONST.BATTLE_DATA.PRE_MP] = node.battleData[CONST.BATTLE_DATA.MP]
    node.battleData[CONST.BATTLE_DATA.PRE_SHIELD] = node.battleData[CONST.BATTLE_DATA.SHIELD]
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
    end
end

function FlyItemManager:addLog(actionType, attacker, targetList, skillId, skillGroupId, actionResultTable, allPassiveTable)
    local sceneHelper = require("Battle.NewFightSceneHelper")
    if sceneHelper:getSceneType() ~= NewBattleConst.SCENE_TYPE.AFK then
    end
end

return FlyItemManager