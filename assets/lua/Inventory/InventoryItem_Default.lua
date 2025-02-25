
local CommItem = require("CommUnit.CommItem")

local UserItemManager = require("Item.UserItemManager")
local ItemManager = require("Item.ItemManager")

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
    commItem:autoSetByItemInfo(cellData.itemInfo)
    commItem:setShowType(CommItem.ShowType.NORMAL)
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        if cellData.itemInfo.id == 10101 then
            GuideManager.PageContainerRef["CommItemAW1"] = commItem.container
        end
    end
end

--[[ 當 點擊 ]]
function Inst:onClick (inventoryPage, cellData)
    local itemInfo = cellData.itemInfo
    local itemId = itemInfo.itemId
    local userItem = UserItemManager:getUserItemByItemId(itemId)
    local itemType = ItemManager:getTypeById(userItem.itemId)
    local cfg = ItemManager:getItemCfgById(userItem.itemId)
    local UserInfo = require("PlayerInfo.UserInfo")

    
    PageManager.showItemInfo(userItem.id, {
        onItemAction_fn = function()
            inventoryPage:refreshPage()
        end
    })

    -- -- 如果道具是英雄令的话
    -- if itemType == 22 then
    --     HeroOrderItemManager:showHeroOrderItemInfo(itemId)
    -- elseif cfg.isNewStone == 2 then
    --     PageManager.showGemInfo(userItem.id)
    -- else
    -- end
end

--[[ 排序資料 ]]
function Inst.sort (a, b)
    return ItemManager:getSortIdById(a) < ItemManager:getSortIdById(b)
end

return Inst