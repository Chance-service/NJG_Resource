local NgHeroPageManager = {}

--------------------------------------------------------------------------------
local Equip_pb = require("Equip_pb")
local Const_pb = require("Const_pb")
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local UserMercenaryManager = require("UserMercenaryManager")
local UserEquipManager = require("Equip.UserEquipManager")
--------------------------------------------------------------------------------
local FetterData = {
    activeData = { },
    canUnlockFetter = { },
    openFetter = { },
    fetterLevel = { },
}
--------------------------------------------------------------------------------
-- Hero
function NgHeroPageManager_getIsShowHeroRedPoint(roleId)
    local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
    -- 只檢查出戰中(掛機隊伍)
    if mercenaryInfo.status == Const_pb.FIGHTING or mercenaryInfo.status == Const_pb.MIXTASK then
        -- 有裝備可更換 / 可升級 / 可升星
        return UserEquipManager:getEquipMercenaryCount(roleId) > 0 or UserMercenaryManager:getRoleCanLevelUp(roleId) or UserMercenaryManager:getRoleCanUpgrade(roleId)
    else
        return false
    end
end
function NgHeroPageManager_getIsShowHeroTabRedPoint()
    local mercenaryInfos = UserMercenaryManager:getUserMercenaryInfos()
    if mercenaryInfos then
        for roleId, data in pairs(mercenaryInfos) do
            if NgHeroPageManager_getIsShowHeroRedPoint(roleId) == true then
                return true
            end
        end
    end
    return false
end
-- Gallery
function NgHeroPageManager_getIsShowGalleryRedPoint(itemId)
    require("HeroBioPage")
    return HeroBioPage_checkCanRewardByRoleId(itemId)
end
function NgHeroPageManager_getIsShowGalleryTabRedPoint()
    local heroCfg = ConfigManager.getNewHeroCfg()
    for id, data in pairs(heroCfg) do
        if id < 500 then
            if NgHeroPageManager_getIsShowGalleryRedPoint(id) == true then
                return true
            end
        end
    end
    return false
end
-- Fetter
function NgHeroPageManager_getIsUnlockFetter(fetterId)
    return FetterData.openFetter[fetterId]
end
function NgHeroPageManager_getIsShowFetterRedPoint(fetterId)
    return RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_FETTER_BTN, fetterId)
end
function NgHeroPageManager_getIsShowFetterTabRedPoint()
    local fetterCfg = ConfigManager.getRelationshipCfg()
    for i = 1, #fetterCfg do
        if NgHeroPageManager_getIsShowFetterRedPoint(i) == true then
            return true
        end
    end
    return false
end
function NgHeroPageManager_openFetter(msg)
    local fetterId = msg.fetterId
    FetterData.canUnlockFetter[fetterId] = false
    FetterData.openFetter[fetterId] = true
end
function NgHeroPageManager_setServerFetterData(msg)
    for i = 1, #msg.items do
        local item = msg.items[i]
        FetterData.activeData[item.roleId] = item.activated
    end
    FetterData.openFetter = { }
    for i = 1, #msg.openFetters do
        local id = msg.openFetters[i]
        FetterData.openFetter[id] = 1
        FetterData.fetterLevel[id] = msg.star[i]
    end
    NgHeroPageManager:calCanUnlockFetter()
end
function NgHeroPageManager:calCanUnlockFetter()
    local fetterCfg = ConfigManager.getRelationshipCfg()
    for i = 1, #fetterCfg do
        local itemIds = fetterCfg[i].team
        FetterData.canUnlockFetter[i] = false
        for idx = 1, #itemIds do
            if idx == #itemIds and FetterData.activeData[itemIds[idx]] == true and not FetterData.openFetter[i] then
                FetterData.canUnlockFetter[i] = true
            elseif FetterData.activeData[itemIds[idx]] == false then
                break
            end
        end
    end
end
function NgHeroPageManager_calIsShowRedPoint(group)
    return FetterData.canUnlockFetter[group]
end
function NgHeroPageManager_getFetterShowLevel(fetterId)
    local fetterLevel = FetterData.fetterLevel[fetterId]
    if not FetterData.fetterLevel[fetterId] then
        local fetterCfg = ConfigManager.getRelationshipCfg()
        local minLv = 999
        for i = 1, #fetterCfg[fetterId].team do
            local merStatus = UserMercenaryManager:getMercenaryStatusByItemId(fetterCfg[fetterId].team[i])
            if merStatus.roleStage == Const_pb.IS_ACTIVITE then
                local info = UserMercenaryManager:getUserMercenaryById(merStatus.roleId)
                minLv = math.min(minLv, info.starLevel)
            else
                minLv = fetterCfg[fetterId].star
                break
            end
        end
        fetterLevel = minLv
    end
    return fetterLevel
end
function NgHeroPageManager_calFetterAttrValue(formulaType, attrType, value, fetterId)
    local baseValue = tonumber(value)
    local finalValue = tonumber(baseValue)
    local fetterLevel = NgHeroPageManager_getFetterShowLevel(fetterId)

    if tonumber(attrType) == 1 then   -- %數
        baseValue = baseValue / 100
    elseif tonumber(attrType) == 2 then   -- 數值
        baseValue = baseValue
    end
    if tonumber(formulaType) == 1 then
        finalValue = baseValue + baseValue * (fetterLevel - 1)
    elseif tonumber(formulaType) == 2 then
        finalValue = baseValue + baseValue * 3 * (fetterLevel - 6) + (baseValue * fetterLevel / 4)
    elseif tonumber(formulaType) == 3 then
        finalValue = baseValue + baseValue * ((fetterLevel - 1) * 2)
    elseif tonumber(formulaType) == 4 then
        finalValue = baseValue + baseValue * ((fetterLevel - 1) + (fetterLevel * 2 - 2))
    end
    return finalValue
end
--------------------------------------------------------------------------------
return NgHeroPageManager