SpriteManager = SpriteManager or { }

local PBHelper = require("PBHelper")
local CONST = require("Battle.NewBattleConst")
local CHAR_UTIL = require("Battle.NgBattleCharacterUtil")
require("Battle.NgBattleDataManager")
require("NodeHelper")
-------------------------------------------------------------------------------------------
-- SPRITE
-------------------------------------------------------------------------------------------
local haveSprite = false
local playerSpriteData = { }
local enemySpriteData = { }
-- UPDATE
function SpriteManager:updateSprite(dt)
    if not haveSprite then
        return
    end
    local playerTriggerIdx = nil
    local enemyTriggerIdx = nil
    for i = 1, CONST.SPRITE_COUNT do
        if playerSpriteData[i] then
            playerSpriteData[i]["CD"] = playerSpriteData[i]["CD"] - dt
            if not playerTriggerIdx and playerSpriteData[i]["CD"] <= 0 then
                playerTriggerIdx = i
            end
        end
        if enemySpriteData[i] then
            enemySpriteData[i]["CD"] = enemySpriteData[i]["CD"] - dt
            if not enemyTriggerIdx and enemySpriteData[i]["CD"] <= 0 then
                enemyTriggerIdx = i
            end
        end
    end
    if NgBattleDataManager.castSkillNode then
        return
    end
    local sprite = self:compareSprite(playerTriggerIdx, enemyTriggerIdx)
    if sprite then
        self:triggerSprite(sprite)
    end
end
-- idx前面的優先觸發 相同idx比較速度
function SpriteManager:compareSprite(playerIdx, enemyIdx)
    if not playerIdx and not enemyIdx then
        return nil
    elseif playerIdx and not enemyIdx then
        return playerSpriteData[playerIdx]
    elseif not playerIdx and enemyIdx then
        return enemySpriteData[enemyIdx]
    else
        if playerIdx < enemyIdx then
            return playerSpriteData[playerIdx]
        elseif enemyIdx < playerIdx then
            return enemySpriteData[enemyIdx]
        else
            local playerSpriteSpeed = PBHelper:getAttrById(playerSpriteData[playerIdx]["INFO"].attribute.attribute, Const_pb.AGILITY)
            local enemySpriteSpeed = PBHelper:getAttrById(enemySpriteData[enemyIdx]["INFO"].attribute.attribute, Const_pb.AGILITY)
            if playerSpriteSpeed > enemySpriteSpeed then
                return playerSpriteData[playerIdx]
            elseif enemySpriteSpeed > playerSpriteSpeed then
                return enemySpriteData[enemyIdx]
            else
                local rand = math.random(1, 2)
                return (rand == 1) and playerSpriteData[playerIdx] or enemySpriteData[enemyIdx]
            end
        end
    end
end
-- 觸發精靈效果
function SpriteManager:triggerSprite(sprite)
    local sceneHelper = require("Battle.NgFightSceneHelper")
    sceneHelper:setMaskLayerVisible(true)   -- 提前到創建spine前開啟黑幕 降低違和感
    if not sprite["CHANODE"] then   -- 還沒創建SPINE
        local NgCharacterManager = require("Battle.NgCharacterManager")
        local chaNode = NgCharacterManager:newSprite(sprite["INFO"], sprite["POS"])
        chaNode.heroNode.heroSpine:registerFunctionHandler("COMPLETE", self.onFunction)
        sprite["CHANODE"] = chaNode
        if sprite["POS"] < CONST.ENEMY_BASE_IDX then
            NgBattleDataManager.battleMineSprite[sprite["POS"]] = chaNode
        else
            NgBattleDataManager.battleEnemySprite[sprite["POS"] - CONST.ENEMY_BASE_IDX] = chaNode
        end
        --self:setSpriteFlip(chaNode)
    end
    self:playSpriteSpine(sprite["CHANODE"], sprite["POS"])

    sprite["CD"] = sprite["CD"] + CONST.SPRITE_PRIVATE_CD_TIME

    CCLuaLog("---------- triggerSprite ------------")
end
function SpriteManager:playSpriteSpine(chaNode, pos)
    SpriteManager:openMask(chaNode)
    local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
    sToNode:setTag(pos)
    chaNode.heroNode.heroSpine:setMix(CONST.ANI_ACT.WAIT, CONST.ANI_ACT.SKILL0, 0.1)
    chaNode.heroNode.heroSpine:setMix(CONST.ANI_ACT.SKILL0, CONST.ANI_ACT.WAIT, 0.1)
    CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
    chaNode.heroNode.chaCCB:stopAllActions()
    local array = CCArray:create()
    array:addObject(CCMoveTo:create(2 / NgBattleDataManager.battleSpeed, ccp(chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X], 
                                                                             chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y])))
    array:addObject(CCCallFunc:create(function()
        CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.SKILL0, false)
    end))
    chaNode.heroNode.chaCCB:runAction(CCSequence:create(array))
end
function SpriteManager:onFunction(tag, eventName)
    if eventName == "COMPLETE" then
        local chaNode = (tag < CONST.ENEMY_BASE_IDX) and NgBattleDataManager.battleMineSprite[tag] or 
                                                         NgBattleDataManager.battleEnemySprite[tag - CONST.ENEMY_BASE_IDX]
        local ani = chaNode.otherData[CONST.OTHER_DATA.PLAYING_ANI_NAME]
        if ani == CONST.ANI_ACT.SKILL0 then
            CHAR_UTIL:setSpineAnimation(chaNode, CONST.ANI_ACT.WAIT, true)
            chaNode.heroNode.chaCCB:stopAllActions()
            local dir = chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] and -1 or 1
            local array = CCArray:create()
            array:addObject(CCMoveTo:create(2 / NgBattleDataManager.battleSpeed, 
                                            ccp(chaNode.otherData[CONST.OTHER_DATA.INIT_POS_X] - CONST.BATTLE_ENEMY_INIT_DIS * dir, 
                                                chaNode.otherData[CONST.OTHER_DATA.INIT_POS_Y])))
            array:addObject(CCCallFunc:create(function()
                SpriteManager:closeMask(chaNode)
            end))
            chaNode.heroNode.chaCCB:runAction(CCSequence:create(array))
        end
    end
end
-- 翻轉面相
function SpriteManager:setSpriteFlip(chaNode)
    --翻轉特定BOSS
    if chaNode.otherData[CONST.OTHER_DATA.IS_FLIP] == 1 then
        if not chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] then    -- 翻轉我方
            local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
            CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        end
    else
        if chaNode.otherData[CONST.OTHER_DATA.IS_ENEMY] then    -- 翻轉敵方
            local sToNode = tolua.cast(chaNode.heroNode.heroSpine, "CCNode")
            CHAR_UTIL:setSpineScaleX(chaNode, sToNode:getScaleX() * -1)
        end
    end
end
-- 開啟黑幕
function SpriteManager:openMask(chaNode)
    NgBattleDataManager_setCastSkillNode(chaNode)   -- 設定當前施放大招的角色
    local sceneHelper = require("Battle.NgFightSceneHelper")
    --sceneHelper:setMaskLayerVisible(true)           -- 開啟黑幕
    sceneHelper:setSkillSceneSpeed(true)            -- 設定Spine Timescale
    sceneHelper:setSkillSpineOrder(true)            -- 設定角色ZOrder
end
-- 關閉黑幕
function SpriteManager:closeMask(chaNode)
    local sceneHelper = require("Battle.NgFightSceneHelper")
    sceneHelper:setMaskLayerVisible(false)      -- 關閉黑幕
    NgBattleDataManager_setCastSkillNode(nil)   -- 解除當前施放大招的角色
    if not NgBattleDataManager.battleIsPause then
        sceneHelper:setSkillSceneSpeed(false)       -- 還原Spine Timescale
    end
end
-- 初始化
function SpriteManager:initSpriteData(battleType, playerInfo, enemyInfo)
    haveSprite = false
    if battleType == CONST.SCENE_TYPE.AFK then
        return
    end
    if not playerInfo or not enemyInfo then
        return
    end
    for i = 1, CONST.SPRITE_COUNT do
        if playerInfo[i + CONST.HERO_COUNT] then
            playerSpriteData[i] = { ["INFO"] = playerInfo[i + CONST.HERO_COUNT], ["CD"] = CONST.SPRITE_PUBLIC_CD_TIME * i, 
                                    ["POS"] = i + CONST.HERO_COUNT }
            haveSprite = true
        end
    end
    for i = 1, #enemyInfo do
        if enemyInfo[i] and enemyInfo[i].posId then
            local pos = enemyInfo[i].posId % 10
            if pos > CONST.ENEMY_COUNT then
                enemySpriteData[i] = { ["INFO"] = enemyInfo[i], ["CD"] = CONST.SPRITE_PUBLIC_CD_TIME * i, 
                                       ["POS"] = enemyInfo[i].posId }
                haveSprite = true
            end
        end
    end
end
function SpriteManager:initTarSpriteData(battleType, playerInfo, enemyInfo)
    haveSprite = haveSprite or false
    if battleType == CONST.SCENE_TYPE.AFK then
        return
    end
    if not playerInfo or not enemyInfo then
        return
    end
    if NgBattleDataManager.nowInitCharPos < CONST.ENEMY_BASE_IDX then
    --for i = 1, CONST.SPRITE_COUNT do
        if NgBattleDataManager.nowInitCharPos > CONST.HERO_COUNT then
            if playerInfo[NgBattleDataManager.nowInitCharPos] then
                local spriteIdx = NgBattleDataManager.nowInitCharPos - CONST.HERO_COUNT
                playerSpriteData[spriteIdx] = { ["INFO"] = playerInfo[NgBattleDataManager.nowInitCharPos], 
                                                ["CD"] = CONST.SPRITE_PUBLIC_CD_TIME * spriteIdx, 
                                                ["POS"] = NgBattleDataManager.nowInitCharPos }
                haveSprite = true
            end
        end
    else
        for i = 1, #enemyInfo do
            if enemyInfo[i] and enemyInfo[i].posId then
                local spriteIdx = (NgBattleDataManager.nowInitCharPos - CONST.ENEMY_BASE_IDX - CONST.ENEMY_COUNT)
                if enemyInfo[i].posId == NgBattleDataManager.nowInitCharPos and spriteIdx > 0 then
                    enemySpriteData[spriteIdx] = { ["INFO"] = enemyInfo[i], 
                                                   ["CD"] = CONST.SPRITE_PUBLIC_CD_TIME * spriteIdx, 
                                                   ["POS"] = NgBattleDataManager.nowInitCharPos }
                    haveSprite = true
                end
            end
        end
    end
    
end
-- 清除資料
function SpriteManager:clearSpriteData()
    haveSprite = false
    playerSpriteData = { }
    enemySpriteData = { }
end

function SpriteManager:getPlayerSpriteData()
    return playerSpriteData
end

function SpriteManager:getEnemySpriteData()
    return enemySpriteData
end
return SpriteManager