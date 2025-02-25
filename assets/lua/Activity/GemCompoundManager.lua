
local Const_pb = require("Const_pb")
local UserItemManager = require("UserItemManager")
local GemCompoundManager = {
	nowSelectGem = 0
}
local GemCompoundCfg = ConfigManager.getGemCompoundCfg()

function GemCompoundManager:getPageData(oriGemId)
	if oriGemId==nil or #GemCompoundCfg==0 then return end
	local GemNowCfg = {}
	table.foreach(GemCompoundCfg, function(i, v)
		if v.oriGem == oriGemId and UserItemManager:getCountByItemId(oriGemId)>0 then
		    GemNowCfg = GemCompoundCfg[i]
		end
	end)
	return GemNowCfg
end

function GemCompoundManager:isHighest(oriGemId)
	if oriGemId==nil then return end
	local highestFlag = 0
	table.foreach(GemCompoundCfg, function( i, v )
		if v.isHighest==1 and v.oriGem==oriGemId then
		    highestFlag=1
		end
	end)
	return highestFlag==1
end

function GemCompoundManager:getLevelThrToNineGem()
	local allGemList = UserItemManager:getItemIdsByType(Const_pb.GEM)
	local thrToNine = {}
	table.foreach(allGemList, function( i,v )
		if v%100>=GameConfig.GemUpgradeLevelLimit.lowLevelLimit 
			and v%100<=GameConfig.GemUpgradeLevelLimit.highLevelLimit then
			table.insert(thrToNine, v)
		end
	end)
	return thrToNine
end


return GemCompoundManager
