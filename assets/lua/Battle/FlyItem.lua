local CONST = require("Battle.NewBattleConst")
-------------------------------------------------------
local BULLET_POS_SETTING = {
    [0] = { ["attack_0"] = { ["INIT_POS"] = { 80, 130 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 100, 90 }, ["LENGTH"] = 110 } },
    [3] = { ["attack_0"] = { ["INIT_POS"] = { 80, 130 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 100, 90 }, ["LENGTH"] = 110 } },
    [6] = { ["attack_0"] = { ["INIT_POS"] = { -65, 175 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 0, 300 }, ["LENGTH"] = 110 } },
    [8] = { ["attack_0"] = { ["INIT_POS"] = { -65, 175 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 40, 300 }, ["LENGTH"] = 110 } },
    [9] = { ["attack_0"] = { ["INIT_POS"] = { 110, 100 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 100, 60 }, ["LENGTH"] = 110 } },
    [17] = { ["attack_0"] = { ["INIT_POS"] = { -65, 175 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 0, 300 }, ["LENGTH"] = 110 } },
    [18] = { ["attack_0"] = { ["INIT_POS"] = { 80, 130 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 100, 90 }, ["LENGTH"] = 110 } },
    [24] = { ["attack_0"] = { ["INIT_POS"] = { -65, 175 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 0, 300 }, ["LENGTH"] = 110 } },
    [5999] = { ["attack_0"] = { ["INIT_POS"] = { 150, 150 }, ["LENGTH"] = 90 }, ["skill_1"] = { ["INIT_POS"] = { 150, 150 }, ["LENGTH"] = 110 } },
}
-------------------------------------------------------
local FlyItem = { }

function FlyItem:initData(attacker, target, resultTable, hit, aniName, isSkipCal, skillId, skillGroupId, targetPosX, targetPosY, flyItemType, allPassiveTable, skillTargetTable)
    local itemData = { }

    itemData.isEnd = false
    itemData.isClose = false
    itemData.attacker = attacker
    itemData.target = target
    itemData.resultTable = resultTable
    itemData.hit = hit
    itemData.aniName = aniName
    itemData.isSkipCal = isSkipCal
    itemData.skillId = skillId
    itemData.skillGroupId = skillGroupId
    itemData.targetPosX = targetPosX
    itemData.targetPosY = targetPosY
    itemData.flyItemType = flyItemType
    itemData.allPassiveTable = allPassiveTable
    itemData.skillTargetTable = skillTargetTable
    local close, initPos, initDeg
    local loop = itemData.flyItemType == CONST.FLYITEM_TYPE.SHOOT and -1 or 0
    if itemData.flyItemType == CONST.FLYITEM_TYPE.SHOOT then
        if itemData.aniName == CONST.ANI_ACT.ATTACK then
            close, initPos, initDeg = self:calItemPosRotate(attacker, resultTable[CONST.LogDataType.DMG_TAR][1], itemData)
        elseif itemData.aniName == CONST.ANI_ACT.SKILL0 or itemData.aniName == CONST.ANI_ACT.SKILL1 or itemData.aniName == CONST.ANI_ACT.SKILL2 then
            close, initPos, initDeg = self:calItemPosRotate(attacker, skillTargetTable[itemData.hit], itemData)
        end
    else
        close, initPos, initDeg = false, ccp(itemData.targetPosX, itemData.targetPosY - 90), 0
    end
    itemData.isClose = close
    local FlyItemManager = require("FlyItemManager")
    local data = FlyItemManager.flyItemFileData[attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME]]
    if data and data[1] and not close then    
        itemData.spineFront = SpineContainer:create(attacker.otherData[CONST.OTHER_DATA.SPINE_PATH_BULLET], attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] .. "_bullet_1")
        itemData.spineFront:runAnimation(1, aniName, loop)
        local toNode = tolua.cast(itemData.spineFront, "CCNode")
        toNode:setPosition(initPos)
        toNode:setRotation(initDeg)
        itemData.spineFrontNode = toNode
        attacker.parent:addChild(toNode)
        if itemData.flyItemType == CONST.FLYITEM_TYPE.TARGET then
            toNode:setZOrder(CONST.Z_ORDER_MASK - initPos.y)
        end
    end
    if data and data[2] and not close then
        itemData.spineBack = SpineContainer:create(attacker.otherData[CONST.OTHER_DATA.SPINE_PATH_BULLET], attacker.otherData[CONST.OTHER_DATA.BULLET_SPINE_NAME] .. "_bullet_2")
        itemData.spineBack:runAnimation(1, aniName, loop)
        local toNode = tolua.cast(itemData.spineBack, "CCNode")
        toNode:setPosition(initPos)
        toNode:setRotation(initDeg)
        itemData.spineBackNode = toNode
        attacker.parent:addChild(toNode)
        if itemData.flyItemType == CONST.FLYITEM_TYPE.TARGET then
            toNode:setZOrder(CONST.Z_ORDER_MASK - initPos.y)
        end
    end

    itemData.initAction = true

    itemData.ATTACK_PARAMS = attacker.ATTACK_PARAMS

    return itemData
end

function FlyItem:calItemPosRotate(attacker, target, itemData)
    local itemId = attacker.otherData[CONST.OTHER_DATA.ITEM_ID]
    local setting = BULLET_POS_SETTING[itemId] or BULLET_POS_SETTING[0]
    local bulletInitPosX = attacker.heroNode.chaCCB:getPositionX() + setting[itemData.aniName]["INIT_POS"][1]
    local bulletInitPosY = attacker.heroNode.chaCCB:getPositionY() + setting[itemData.aniName]["INIT_POS"][2]
    local radius = setting[itemData.aniName]["LENGTH"]
    local dis = ccpDistance(ccp(bulletInitPosX, bulletInitPosY), ccp(itemData.targetPosX, itemData.targetPosY))

    if radius >= dis then   --¶ZÂ÷¹Lªñ
        return true, nil, nil
    else
        local cos = (itemData.targetPosX - bulletInitPosX) / dis
        local sin = (itemData.targetPosY - bulletInitPosY) / dis
        local initPos = ccp(bulletInitPosX + cos * radius,
                            bulletInitPosY + sin * radius)
        local rad = math.asin(sin)
        local deg = (cos >= 0 and math.deg(rad) or 180 - math.deg(rad)) * -1
        return false, initPos, deg
    end
end

return FlyItem