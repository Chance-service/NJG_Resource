local ItemManager = {};
--------------------------------------------------------------------------------
local ConfigManager = require("ConfigManager")
local ItemCfg = ConfigManager.getItemCfg();
local nowSelectItemId = nil
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local Item_pb = require("Item_pb");
local Const_pb = require("Const_pb");
--------------------------------------------------------------------------------
--从item.txt获取道具配置
function ItemManager:getItemCfgById(itemId, attrName)
	return ItemCfg[itemId] or {};
end

function ItemManager:getAttrById(itemId, attrName)
	local config = ItemCfg[itemId];
	if config then
		return config[attrName];
	end
	return "";
end

function ItemManager:getExchangeById(itemId)
	return self:getAttrById(itemId, "exchange");
end

function ItemManager:getSortTypeById(itemId)
	return self:getAttrById(itemId, "sortType");
end

function ItemManager:getSortIdById(itemId)
	return self:getAttrById(itemId, "sortId");
end


function ItemManager:getTypeById(itemId)
	return self:getAttrById(itemId, "type");
end

function ItemManager:getQualityById(itemId)
	return self:getAttrById(itemId, "quality");
end

function ItemManager:getIconById(itemId)
	return self:getAttrById(itemId, "icon");
end

function ItemManager:getNameById(itemId)
	return self:getAttrById(itemId, "name");
end

function ItemManager:getShowNameById( itemId, showName)
	local cfg = self:getItemCfgById(itemId)
	if cfg.type == Const_pb.SUIT_DRAWING then
		local charLevel = cfg.suitLevel;
		local displayLevel
	    if tonumber(charLevel) > 100 then
	        displayLevel = common:getLanguageString("@NewLevelStr", math.floor(charLevel/100), tonumber(charLevel) - 100)
	    else 
	        displayLevel = common:getLanguageString("@LevelStr", charLevel)
	    end
		if showName then
			return displayLevel .." ".. showName
		else
			return displayLevel
		end
	else
		local charLevel = cfg.suitLevel;
		if charLevel and charLevel > 0 then
		    if tonumber(charLevel) > 100 then
		        displayLevel = common:getLanguageString("@NewLevelStr", math.floor(charLevel/100), tonumber(charLevel) - 100)
		    else 
		        displayLevel = common:getLanguageString("@LevelStr", charLevel)
		    end			
			if showName then
				return displayLevel .." ".. showName
			else
				return displayLevel
			end
		else
			return cfg.name or ""
		end
		
	end
end

function ItemManager:getLevelUpCost(itemId)
	return self:getAttrById(itemId, "levelUpCost");
end
		
function ItemManager:getLevelUpTarget(itemId)
	return self:getAttrById(itemId, "levelUpItem");
end

function ItemManager:getLevelUpCostMax(itemId)
	return self:getAttrById(itemId, "levelUpCostMax");
end


function ItemManager:getStoneLevelUpCost(itemId)
	return self:getAttrById(itemId, "stoneLevelUpCost");
end

function ItemManager:getStoneType(itemId)
	return self:getAttrById(itemId, "stoneType");
end


--获取宝石的小icon,根据属性区分
function ItemManager:getGemSmallIcon(itemId)
	local cfg = self:getItemCfgById(itemId)
	if cfg.isNewStone == 1 then
		local attr2Id = {
			strength	= Const_pb.STRENGHT,
			agility		= Const_pb.AGILITY,
			intellect	= Const_pb.INTELLECT,
			stamina		= Const_pb.STAMINA
		};
		for attr, attrId in pairs(attr2Id) do
			local attrVal = self:getAttrById(itemId, attr) or 0;
			if tonumber(attrVal) > 0 then
				return GameConfig.Image.GemIcon[attrId];
			end
		end
		return GameConfig.Image.GemIcon[1];
	else
		return GameConfig.Image.newGemIcon[cfg.stoneType]; 
	end
end

--获取宝石加成属性
function ItemManager:getGemAttrString(itemId)
	local retStr = "";
	local attr2Id = {
		strength	= Const_pb.STRENGHT,
		agility		= Const_pb.AGILITY,
		intellect	= Const_pb.INTELLECT,
		stamina		= Const_pb.STAMINA
	};
	for attr, attrId in pairs(attr2Id) do
		local attrVal = self:getAttrById(itemId, attr) or 0;
		if tonumber(attrVal) > 0 then
			retStr = common:getLanguageString("@AttrName_" .. attrId) .. " +" .. attrVal;
			return retStr;
		end
	end
	return retStr;
end

--获取宝石加成属性
function ItemManager:getNewGemAttrString(itemId)
	local retStr = "";
	local attrs = self:getAttrById(itemId, "attr")
	print("itemId",itemId)
	if attrs then
		for i, attr in ipairs(attrs) do
			retStr = retStr..common:getLanguageString("@AttrName_" .. attr[1]) .. " +" .. attr[2].." ";
		end
	end
	return retStr;
end

--获取打所需熔炼值(装备打造可以打造部分道具)
function ItemManager:getSmeltNeedById(itemId)
	return tonumber(self:getAttrById(itemId, "smeltCost")) or 0;
end

--获取礼包等包含物品配置
function ItemManager:getContainCfg(itemId)
	local cfgStr = self:getAttrById(itemId, "containItem");
	if cfgStr == "" or cfgStr == "0" then return nil; end
	
	local cfg = {};
	for _, item in ipairs(common:split(cfgStr, ",")) do
		local _type, _id, _count= unpack(common:split(item, "_"));
		table.insert(cfg, {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		});
	end
	
	return cfg;
end
--获取套装兑换道具的包含物品配置
function ItemManager:getSuitContainCfg(itemId)
	local cfgStr = self:getAttrById(itemId, "containItem");
	if cfgStr == "" or cfgStr == "0" then return nil; end
	
	local cfg = {};
	for _, item in ipairs(common:split(cfgStr, ",")) do
		local _type, _id, _count,_protId= unpack(common:split(item, "_"));
		table.insert(cfg, {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count),
            protId 	= tonumber(_protId)
		});
	end
	
	return cfg;
end

-- 当前选择的物品是什么
function ItemManager:setNowSelectItem(itemId)
	assert(itemId, "no Item Selected")
	nowSelectItemId = itemId
end

function ItemManager:getNowSelectItem()
	return nowSelectItemId
end

function ItemManager:getPriceById(itemId)
	return tonumber(self:getAttrById(itemId, "price")) or 0;
end

function ItemManager:getGemMarketItems( vipLevel )
	vipLevel = vipLevel or 0;
	local gemMarketItems = {}
	local cfg = ConfigManager.getGemMarketCfg()
	local tmp
	for i,v in ipairs(cfg) do
		if v.vipLimit <= vipLevel then
			if v.isExchangeByItem == 1 or v.isExchangeByItem == 3 then
				tmp = common:deepCopy(v);
				tmp.costType = 1;
				table.insert(gemMarketItems, tmp)			
			end
			if v.isExchangeByItem == 2 or v.isExchangeByItem == 3 then
				tmp = common:deepCopy(v);
				tmp.costType = 2;
				table.insert(gemMarketItems, tmp)			
			end			
		end
	end

	table.sort(gemMarketItems, function ( left, right )
		if left.vipLimit == right.vipLimit then
			if left.costType == right.costType then
				return left.id < right.id
			end
			return left.costType < right.costType
		end
		return left.vipLimit > right.vipLimit
	end)

	return gemMarketItems
end

function ItemManager:getNewGemMarketItems( vipLevel )
	vipLevel = vipLevel or 0;
	local gemMarketItems = {}
	local cfg = ConfigManager.getNewGemMarketCfg()
	local tmp
	for i,v in ipairs(cfg) do
		if v.vipLimit <= vipLevel then
			if v.isExchangeByItem == 1 or v.isExchangeByItem == 3 then
				tmp = common:deepCopy(v);
				tmp.costType = 1;
				if not gemMarketItems[v.group] then
					gemMarketItems[v.group] = {}
				end
				table.insert(gemMarketItems[v.group], tmp)
			end
			if v.isExchangeByItem == 2 or v.isExchangeByItem == 3 then
				tmp = common:deepCopy(v);
				tmp.costType = 2;
				if not gemMarketItems[v.group] then
					gemMarketItems[v.group] = {}
				end
				table.insert(gemMarketItems[v.group], tmp)
			end
		end
	end

	for k, v in pairs(gemMarketItems) do
		table.sort(gemMarketItems[k], function ( left, right )
			if left.vipLimit == right.vipLimit then
				if left.costType == right.costType then
					return left.id < right.id
				end
				return left.costType < right.costType
			end
			return left.vipLimit > right.vipLimit
		end)
	end

	return gemMarketItems
end

--------------------------------------------------------------------------------
return ItemManager;