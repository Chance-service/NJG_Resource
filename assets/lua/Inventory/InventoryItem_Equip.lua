
local CommItem = require("CommUnit.CommItem")

--[[ 本體 ]]
local Inst = {}
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 當 設置道具UI ]]
function Inst:setUI (commItem, cellData)
    commItem:autoSetByEquipID(cellData.id)
    if commItem.showType == CommItem.ShowType.ANCIENT_EQUIPMENT then
        commItem:setShowType(CommItem.ShowType.ANCIENT_EQUIPMENT_NUM)
    else
        commItem:setShowType(CommItem.ShowType.EQUIPMENT_NUM)
    end
    commItem:setCount(cellData.count)
    --commItem:setShowType(CommItem.ShowType.EQUIPMENT)
end

--[[ 當 點擊 ]]
function Inst:onClick (inventoryPage, cellData)
    -- 取得 裝備ID
    local userEquipId = cellData.id
    local userEquip = UserEquipManager:getUserEquipById(userEquipId)
    local equipItemId = userEquip.equipId
    -- 一般裝備
    if equipItemId < 10000 then
        -- 顯示 裝備資訊
        PageManager.showEquipInfo(userEquipId)
    else
        -- 專武
        -- 專武資訊
        local AWDetail = require("AncientWeapon.AncientWeaponDetail")
        local detail = AWDetail:new():init(inventoryPage.container)
        detail:setShowType(AncientWeaponDetail_showType.INVENTORY)
        detail:loadUserEquip(userEquipId)
        detail:show()
        inventoryPage.awDetailPage = detail
        
        -- 專武升級升星羈絆
        --require("AncientWeapon.AncientWeaponPage"):prepare(userEquipId)
        --PageManager.pushPage("AncientWeapon.AncientWeaponPage")
    end
end


--[[ 排序資料 ]]
function Inst.sort (info1, info2)
    if info1 == nil or info2 == nil then
        return false
    end
    if info1.itemId >= 10000 and info2.itemId < 10000 then
        return true
    end
    if info1.itemId < 10000 and info2.itemId >= 10000 then
        return false
    end
    if info1.itemId >= 10000 and info2.itemId >= 10000 then
        return info1.itemId < info2.itemId
    end
    if info1.itemId < 10000 and info2.itemId < 10000 then
        local type1, type2 = math.floor(info1.itemId / 1000), math.floor(info2.itemId / 1000)
        local level1, level2 = info1.itemId % 100, info2.itemId % 100
        if level1 > level2 then
            return true
        end
        if level1 < level2 then
            return false
        end
        if type1 < type2 then
            return true
        end
        if type1 > type2 then
            return false
        end
    end
    return false
end
--function Inst.sort (a, b)
--    local isAsc = true
--    local id_1 = a
--    local id_2 = b
--
--    if id_2 == nil then
--        return isAsc
--    end
--    if id_1 == nil then
--        return not isAsc
--    end
--
--    local userEquip_1 = UserEquipManager:getUserEquipById(id_1)
--    local userEquip_2 = UserEquipManager:getUserEquipById(id_2)
--
--    local isGodly_1 = UserEquipManager:isEquipGodly(userEquip_1)
--    local isGodly_2 = UserEquipManager:isEquipGodly(userEquip_2)
--
--    if isGodly_1 ~= isGodly_2 then
--        if isGodly_1 then return isAsc end
--        return not isAsc
--    end
--
--    local quality_1 = EquipManager:getQualityById(userEquip_1.equipId)
--    local quality_2 = EquipManager:getQualityById(userEquip_2.equipId)
--
--    if quality_1 ~= quality_2 then
--        if quality_1 > quality_2 then
--            return isAsc
--        else
--            return not isAsc
--        end
--    end
--
--    local part_1 = EquipManager:getPartById(userEquip_1.equipId)
--    local part_2 = EquipManager:getPartById(userEquip_2.equipId)
--
--    if part_1 ~= part_2 then
--        if GameConfig.PartOrder[part_1] > GameConfig.PartOrder[part_2] then
--            return isAsc
--        end
--        return not isAsc
--    end
--
--    -- 強化等級
--    if userEquip_1.strength and userEquip_2.strength and userEquip_1.strength ~= userEquip_2.strength then
--        if userEquip_1.strength > userEquip_2.strength then
--            return isAsc
--        else
--            return not isAsc
--        end
--    end
--
--    -- 裝備等級
--    if userEquip_1.level and userEquip_2.level and userEquip_1.level ~= userEquip_2.level then
--        if userEquip_1.level > userEquip_2.level then
--            return isAsc
--        else
--            return not isAsc
--        end
--    end
--
--    if userEquip_1.score ~= userEquip_2.score then
--        if userEquip_1.score > userEquip_2.score then
--            return isAsc
--        else
--            return not isAsc
--        end
--    end
--    -- 装备id
--    if userEquip_1.equipId > userEquip_2.equipId then
--        return isAsc
--    end
--
--    -- 服务器的装备id排序
--    -- if id_1 > id_2 then
--    -- 	return isAsc
--    -- end
--
--    return not isAsc
--end

return Inst