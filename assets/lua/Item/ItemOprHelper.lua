local ItemOprHelper = {};
--------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local ItemOpr_pb 	= require("ItemOpr_pb");
local HP_pb		= require("HP_pb");
local ItemManager = require("Item.ItemManager")
local UserInfo = require("PlayerInfo.UserInfo");
--------------------------------------------------------------------------------
--使用
function ItemOprHelper:useItem(itemId, count,profId, typeId)
    local levelLimit = tonumber(ItemManager:getAttrById(itemId, "levelLimit"))
    if UserInfo.level < levelLimit then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@ItemLevelLimitContext", levelLimit))
        return
    end
    local itemType = ItemManager:getTypeById(itemId)
    if itemType==28 then
        local ItemCfg = ConfigManager.getItemCfg();
        local Contain= common:parseItemWithComma(ItemCfg[itemId].containItem)
            local ChoosePage=require ("CommPop.TreasureChoosePage")
            ChoosePage:setData(count,Contain,itemId)
            PageManager.pushPage("CommPop.TreasureChoosePage")
        return
    end

	local msg = ItemOpr_pb.HPItemUse();
	msg.itemId = itemId;
	msg.itemCount = count or 1;
    if profId  then 
        msg.profId = profId;
    end
    if typeId then
        msg.msgType = typeId
    end
	common:sendPacket(HP_pb.ITEM_USE_C, msg);
end	

--打开10个
function ItemOprHelper:useTenItem(itemId)
    local UserItemManager = require("Item.UserItemManager")
    local item = UserItemManager:getUserItemByItemId(itemId)
    if item~=nil and item.count<10 then
        self:useItem(itemId, item.count);
        return;
    end
	self:useItem(itemId, 10);
end

--出售
function ItemOprHelper:sellItem(itemId, count)
	local msg = ItemOpr_pb.HPItemSell();
	msg.itemId = itemId;
	msg.count = count or 1;
	
	common:sendPacket(HP_pb.ITEM_SELL_C, msg, false);
end

function ItemOprHelper:useHeroOrderItem(itemId, count)
	local msg = ItemOpr_pb.HPItemUse();
	msg.itemId = itemId;
	msg.itemCount = count or 1;
    if profId  then 
        msg.profId = profId;
    end
    msg.msgType = Const_pb.CONSUME_ITEM
	common:sendPacket(HP_pb.ITEM_USE_C, msg);
end

function ItemOprHelper:onceCompoundItem(itemId)
    local levelLimit = tonumber(ItemManager:getAttrById(itemId, "levelLimit"))
    if UserInfo.level < levelLimit then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@ItemLevelLimitContext", levelLimit))
        return
    end
    local msg = ItemOpr_pb.HPItemUse();
    msg.itemId = itemId;
    msg.itemCount = 1;
    if profId  then 
        msg.profId = profId;
    end
    msg.msgType = Const_pb.GEM_COMPOUND_ONCE
    common:sendPacket(HP_pb.ITEM_USE_C, msg);
end

function ItemOprHelper:getHeroOrderTask(itemId)
    local msg = ItemOpr_pb.HPItemUse();
	msg.itemId = itemId;
	msg.itemCount = 1;
    if profId  then 
        msg.profId = profId;
    end
    msg.msgType = Const_pb.GET_TASK
	common:sendPacket(HP_pb.ITEM_USE_C, msg)
end

--回收
function ItemOprHelper:recycleItem(itemId)
	local msg = ItemOpr_pb.HPGongceWordCycle();
	msg.itemId = itemId;
	common:sendPacket(HP_pb.WORDS_EXHCNAGE_CYCLE_C, msg, false);
end
--------------------------------------------------------------------------------
return ItemOprHelper;