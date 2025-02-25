require "Const_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local ResManagerForLua = {
}
--------------------------------------------------------------------------------
local roleCfg = ConfigManager.getRoleCfg()
local equipCfg = ConfigManager.getEquipCfg()
local fateCfg = ConfigManager.getFateDressCfg()
local itemCfg = ConfigManager.getItemCfg()
local resPropCfg = ConfigManager.getResPropertyCfg()
local userProCfg = ConfigManager.getUserPropertyCfg()
local elementProCfg = ConfigManager.getElementCfg()
local avatarCfg = ConfigManager.getLeaderAvatarCfg()
local musciCfg = ConfigManager.getBGMusicCfg() -- 获取背景音乐

local UserItemManager = require("Item.UserItemManager")
--------------------------------------------------------------------------------

-- 添加背景音乐
function ResManagerForLua:playBGMusic(musicName)
    for k, v in pairs(musciCfg) do
        if tostring(v.englishName) == tostring(musicName) then
            SoundManager:getInstance():playMusic(tostring(v.musicPath))
        end
    end
end

function ResManagerForLua:getResInfoByTypeAndId(resType, resId, resCount, getUserItemCount)
    local resMainType = self:getResMainType(resType)
    if resMainType == nil then
        CCLuaLog("@ResManagerForLua:getResInfoByTypeAndId -- type is error.")
        return nil
    end

    return self:getResInfoByMainTypeAndId(resMainType, resId, resCount, resType, getUserItemCount)
end

function ResManagerForLua:getResInfoByMainTypeAndId(resMainType, resId, resCount, resType, getUserItemCount)
    local ResInfoLua = {
        name,
        describe,
        quality,
        icon,
        count,
        itemId,
        itemType,
        mainType,
        typeName,
        describe2,
        star
    }
    ResInfoLua.itemId = resId
    ResInfoLua.itemType = resType
    ResInfoLua.count = resCount
    ResInfoLua.mainType = resMainType
    ResInfoLua.iconScale = 1
    ResInfoLua.star = 1
    -- CCLuaLog("ResManagerForLua :"..tostring(resMainType).."     "..tostring(Const_pb.EQUIP))
    -- CCLuaLog("ResManagerForLua :".."Const_pb.ROLE:"..tostring(Const_pb.TOOL))
    -- CCLuaLog("ResManagerForLua :".."Const_pb.TOOL:"..tostring(Const_pb.TOOL))
    -- CCLuaLog("ResManagerForLua :".."Const_pb.PLAYER_ATTR:"..tostring(Const_pb.PLAYER_ATTR))
    -- CCLuaLog("ResManagerForLua :".."Const_pb.ELEMENT:"..tostring(Const_pb.ELEMENT))
    -- CCLuaLog("ResManagerForLua :".."Const_pb.AVATAR:"..tostring(Const_pb.AVATAR))
    local newType = resMainType
    if resMainType < 10 then
        newType = resMainType * 10000
    end
    ResInfoLua.typeName = resPropCfg[newType]["name"]

    if resMainType == Const_pb.ROLE then
        if (roleCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! role.txt nil id = " .. resId)
        end
        ResInfoLua.name = roleCfg[resId]["name"]
        -- describe 暂时为name，需要策划配置
        ResInfoLua.describe = roleCfg[resId]["name"]
        ResInfoLua.icon = roleCfg[resId]["icon"]
        -- 暂时定为4
        ResInfoLua.quality = 4
    elseif resMainType == Const_pb.TOOL then
        if (itemCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! item.txt nil id = " .. resId)
        end
        ResInfoLua.name = itemCfg[resId]["name"]
        ResInfoLua.describe = itemCfg[resId]["description"]
        ResInfoLua.icon = itemCfg[resId]["icon"]
        ResInfoLua.describe2 = itemCfg[resId]["description2"]
        ResInfoLua.iconScale = 1
        ResInfoLua.afkHour = itemCfg[resId]["AFKhour"]
        local _type = itemCfg[resId]["type"]
        if _type == Const_pb.AVATAR_GIFT then
            local insideItem = common:parseItemWithComma(itemCfg[resId].containItem)[1]
            local insideInfo = self:getResInfoByTypeAndId(insideItem.type, insideItem.itemId, insideItem.count)
            ResInfoLua.icon = insideInfo.icon
            ResInfoLua.iconScale = 0.84
        end
        ResInfoLua.quality = itemCfg[resId]["quality"]
        ResInfoLua.type = _type
        if getUserItemCount then
            ResInfoLua.count = UserItemManager:getCountByItemId(resId)
        end
    elseif resMainType == Const_pb.EQUIP then
        if (equipCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! equip.txt nil id = " .. resId)
        end
        ResInfoLua.name = equipCfg[resId]["name"]
        -- describe 暂时为name，需要策划配置
        ResInfoLua.describe = equipCfg[resId]["name"]
        ResInfoLua.icon = equipCfg[resId]["icon"]
        ResInfoLua.quality = equipCfg[resId]["quality"]
        ResInfoLua.star = equipCfg[resId]["stepLevel"]
    elseif resMainType == Const_pb.BADGE then
        if (fateCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! dress.txt nil id = " .. resId)
            resId = 110
        end
        ResInfoLua.name = fateCfg[resId]["name"] .. common:getLanguageString("@Rune")
        ResInfoLua.describe = fateCfg[resId]["name"]
        ResInfoLua.icon = fateCfg[resId]["icon"]
        ResInfoLua.quality = fateCfg[resId]["rare"]
        ResInfoLua.star = fateCfg[resId]["star"]
    elseif resMainType == Const_pb.PLAYER_ATTR or resMainType == 7 then
        -- 7 佣兵魂魄
        if (userProCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! UserProperty.txt nil id = " .. resId)
        end
        if resMainType == 7 then
            ResInfoLua.iconScale = 0.84
        end
        ResInfoLua.name = userProCfg[resId]["name"]
        ResInfoLua.describe = userProCfg[resId]["discribe"]
        ResInfoLua.icon = userProCfg[resId]["icon"]
        ResInfoLua.quality = userProCfg[resId]["quality"]
    elseif resMainType == Const_pb.ELEMENT then
        if (elementProCfg[resId] == nil) then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! element.txt nil id = " .. resId)
        end
        ResInfoLua.name = elementProCfg[resId]["name"]
        ResInfoLua.quality = elementProCfg[resId]["quality"]
        ResInfoLua.icon = elementProCfg[resId]["icon"]
        ResInfoLua.describe = elementProCfg[resId]["desc"]
    elseif resMainType == Const_pb.AVATAR then
        if not avatarCfg[resId] then
            CCLuaLog("!!!!!!!!!!!!!!!!!!!!! fashion.txt nil id = " .. resId)
        end
        ResInfoLua.name = avatarCfg[resId]["name"]
        ResInfoLua.quality = avatarCfg[resId]["quality"]
        local iconCfg = GameConfig.LeaderAvatarInfo[resId]
        ResInfoLua.icon = iconCfg.icon[UserInfo.roleInfo.prof]
        ResInfoLua.describe = avatarCfg[resId]["desc"]
    end

    return ResInfoLua
end

function ResManagerForLua:getResMainType(type)
    local MainType = nil
    MainType = type
    if type >= 10000 then
        MainType = math.floor(type / 10000)
    end
    return MainType
end

function ResManagerForLua:canConsume(consumeId)
    local consumeCfg = ConfigManager.getConsumeById(consumeId)
    local isOptional = consumeCfg["type"] == 2
    for _, cfg in ipairs(consumeCfg["items"]) do
        local ownCount = 0
        local mainType = self:getResMainType(cfg.type)
        if mainType == Const_pb.TOOL then
            ownCount = UserItemManager:getCountByItemId(cfg.itemId)
        end
        local isEnough = ownCount >= cfg.count
        if isEnough and isOptional then return true end
        if not isEnough and not isOptional then return false end
    end
    return not isOptional
end

function ResManagerForLua:getResStr(cfg)
    local strTb = { }
    for _, subCfg in ipairs(cfg) do
        local resInfo = self:getResInfoByTypeAndId(subCfg.type, subCfg.itemId, subCfg.count)
        table.insert(strTb, resInfo.name .. " x" .. resInfo.count)
    end
    local strSplit = ", "
    if GamePrecedure:getInstance():getI18nSrcPath() == "French" then
        strSplit = ", "
    end
    return table.concat(strTb, strSplit)
end

function ResManagerForLua:checkConsume(typeId, itemId, count)
    local mainType = self:getResMainType(typeId)
    if mainType == Const_pb.PLAYER_ATTR then
        if itemId == Const_pb.COIN then
            return UserInfo.isCoinEnough(count)
        elseif itemId == Const_pb.GOLD then
            return UserInfo.isGoldEnough(count)
        end
    elseif mainType == Const_pb.TOOL then
        if count > UserItemManager:getCountByItemId(itemId) then
            MessageBoxPage:Msg_Box_Lan("@LackItem")
            return false
        end
        return true
    end
    return true
end
--
function ResManagerForLua:getAttributeString(attrId, attrValue)
    require("Const_pb")
    if attrId < Const_pb.BUFF_COIN_DROP then
        return self:getAttributeStringForValue(attrId, attrValue)
    elseif attrId >= Const_pb.BUFF_COIN_DROP and attrId < Const_pb.BUFF_PHYDEF_ADD then
        return self:getAttributeStringForRadio(attrId, attrValue)
    elseif attrId >= Const_pb.BUFF_PHYDEF_ADD and attrId < Const_pb.BUFF_WARRIOR then
        return self:getAttributeStringForValue(attrId, attrValue)
    elseif attrId >= Const_pb.BUFF_WARRIOR and attrId < Const_pb.ICE_ATTACK then
        return self:getAttributeStringForRadio(attrId, attrValue)
    elseif attrId >= Const_pb.ICE_ATTACK and attrId < Const_pb.ICE_ATTACK_RATIO then
        return self:getAttributeStringForValue(attrId, attrValue)
    elseif attrId >= Const_pb.ICE_ATTACK_RATIO then
        return self:getAttributeStringForRadio(attrId, attrValue)
    end
end

function ResManagerForLua:getAttributeStringForValue(attrId, attrValue)
    local attrName = common:getLanguageString("@AttrName_" .. attrId)
    return attrName, attrValue
end

function ResManagerForLua:getAttributeStringForRadio(attrId, attrValue)
    local attrName = common:getLanguageString("@AttrName_" .. attrId)
    attrValue = string.format("%.1f%%", attrValue / 100)
    return attrName, attrValue
end

--------------------------------------------------------------------------------
return ResManagerForLua