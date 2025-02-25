local UserItemManager = {
	nowSelectItemListType = 2,
    -- contentSelectIds = {} --¨ª¨¬¨º¨¦¨¦??¡Â?-?¨¦¨º¡¥????¡Á¡ä¨¬?
};
--------------------------------------------------------------------------------

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
local math = math;
--------------------------------------------------------------------------------
local Item_pb = require("Item_pb");
local Const_pb = require("Const_pb")
local ItemManager = require("Item.ItemManager");
--------------------------------------------------------------------------------



function UserItemManager:getUserItemByIndex(index)
	local ItemStr = ServerDateManager:getInstance():getItemInfoByIndexForLua(index);
	local userItem = Item_pb.ItemInfo();
	userItem:ParseFromString(ItemStr);
	return userItem;
end

function UserItemManager:getUserItemById(userItemId)
	local ItemStr = ServerDateManager:getInstance():getItemInfoByIdForLua(userItemId);
	local userItem = Item_pb.ItemInfo();
	userItem:ParseFromString(ItemStr);
	return userItem;
end

function UserItemManager:getUserItemByItemId(itemId)
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	for i = 0, size - 1 do
		local userItem = self:getUserItemByIndex(i);
		if userItem and userItem.itemId == itemId then
			return userItem;
		end
	end
	return nil;
end

function UserItemManager:getUserItemIds()
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	local ids = {};
	for i = 0, size - 1 do
		local userItem = self:getUserItemByIndex(i);
        local itemType = ItemManager:getTypeById(userItem.itemId)
		if userItem and itemType ~= Const_pb.FAKE_ITEMS then
			table.insert(ids, userItem.itemId);
		end
	end
	return ids;
end

--取套装碎片 id 大於 10000
function UserItemManager:getUserItemSuitFragIds()
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	local ids = {};
	for i = 0, size - 1 do
		local userItem = self:getUserItemByIndex(i);
		if userItem and (10000 < userItem.itemId) then
			table.insert(ids, userItem.itemId);
		end
	end
	return ids;
end

--判断是否有高速扫荡卷
function UserItemManager:isHaveHighSpeedSweet()
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	for i = 0, size - 1 do
		local userItem = self:getUserItemByIndex(i);
		if userItem and ((userItem.itemId >=103102 and (userItem.itemId <= 103105))) then
			return true
		end
	end
	return false
end

--高速战斗红点
function UserItemManager:isHaveHighSpeedPoint()
	if ((self:isHaveHighSpeedSweet() and (GameConfig.FastFightingTicketMaxCount - UserInfo.stateInfo.hourCardUseCountOneDay > 0)) or tonumber(UserInfo.stateInfo.leftFreeFastFightTimes) > 0)  then
		return true
	else
		return false
	end
end

--取不是套装碎片的item id 不大於 10000
function UserItemManager:getUserItemNotSuitFragIds()
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	local ids = {};
	for i = 0, size - 1 do
		local userItem = self:getUserItemByIndex(i);
        local itemType = ItemManager:getTypeById(userItem.itemId)
		if userItem and (10000 >= userItem.itemId) and itemType ~= Const_pb.FAKE_ITEMS then
			table.insert(ids, userItem.itemId);
		end
	end
	return ids;
end

--取得 道具 僅限ID範圍
function UserItemManager:getUserItemIdsInclude(includeRanges)
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	local ids = {}
	for idx = 0, size - 1 do

		local userItem = self:getUserItemByIndex(idx);
		dump(userItem, "userItem["..tostring(userItem.itemId).."]")


		if userItem ~= nil then 

			local isInclude = false

			for rangeIdx = 1, #includeRanges do
				local eachRange = includeRanges[rangeIdx]
				if (eachRange[1] <= userItem.itemId) and (userItem.itemId <= eachRange[2]) then
					isInclude = true
					break
				end
			end

			if isInclude then
				table.insert(ids, userItem.itemId)
			end
		end
	end

	return ids
end

--取得 道具 排除ID範圍
function UserItemManager:getUserItemIdsExclude(excludeRanges)
	local size = ServerDateManager:getInstance():getItemInfoTotalSize();
	local ids = {}
	for idx = 0, size - 1 do

		local userItem = self:getUserItemByIndex(idx);

		if userItem ~= nil then 

			local isExclude = false

			for rangeIdx = 1, #excludeRanges do
				local eachRange = excludeRanges[rangeIdx]
				if (userItem.itemId < eachRange[1]) or (eachRange[2] < userItem.itemId) then
					isExclude = true
					break
				end
			end

			if not isExclude then
				table.insert(ids, userItem.itemId)
			end
		end
	end

	return ids
end

function UserItemManager:getItemIdsByType(toolType)
	local ids = {};
	local maxIndex = ServerDateManager:getInstance():getItemInfoTotalSize() - 1;
	for i = 0, maxIndex do
		local userItem = self:getUserItemByIndex(i);
		local itemType = ItemManager:getTypeById(userItem.itemId);
		if itemType == toolType then
			table.insert(ids, userItem.itemId);
		end
	end
	return ids;
end

function UserItemManager:getItemsByType(toolType)
	local items = {};
	local maxIndex = ServerDateManager:getInstance():getItemInfoTotalSize() - 1;
	for i = 0, maxIndex do
		local userItem = self:getUserItemByIndex(i);
		-- print("userItem.itemId = "..userItem.itemId)
		local itemType = ItemManager:getTypeById(userItem.itemId);
		-- print("itemType = "..itemType)
		if itemType == toolType then
			table.insert(items, userItem);
		end
	end
	return items;
end

function UserItemManager:getCountByItemId(itemId)
	local userItem = self:getUserItemByItemId(itemId)
	return userItem and math.max(userItem.count, 0) or 0
end

--------------------------------------------------------------------------------
return UserItemManager;