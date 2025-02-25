local ViewMercenaryInfo = {
	mercenaryInfo = {},
    ringInfos = {},
    equipInfo = {}
};
--------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local HP_pb = require("HP_pb");
local Snapshot_pb = require("Snapshot_pb");

local PBHelper = require("PBHelper");

------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
function ViewMercenaryInfo:getInfo(playerId,mercenaryId)
	local msg = Snapshot_pb.HPSeeMercenaryInfo();
	msg.playerId = playerId;   
    msg.mercenaryId = mercenaryId;
	common:sendPacket(HP_pb.SEE_MERCENARY_INFO_C, msg,false);
end

function ViewMercenaryInfo:setInfo(msgBuff)
	local msg = Snapshot_pb.HPSeeMercenaryInfoRet();
	msg:ParseFromString(msgBuff);
	self.mercenaryInfo = msg.mercenaryInfo;
	self.ringInfos = msg.ringInfos
	self.equipInfo = msg.equipInfo
end

function ViewMercenaryInfo:checkRingActive(itemId)
    for _,value in pairs(self.ringInfos) do	
		local oneInfo = value
		if oneInfo.itemId == itemId then
			return true
		end
	end
	return false
end


function ViewMercenaryInfo:clearInfo()
	self.mercenaryInfo = {}
    self.ringInfos = {}
    self.equipInfo = {}
end	
--------------------------------------------------------------------------------
function ViewMercenaryInfo:getRoleAttrById(attrId)
	return PBHelper:getAttrById(self:getRoleInfo().attribute.attribute, attrId);
end


function ViewMercenaryInfo:getDamageString()
	return (self:getRoleAttrById(Const_pb.MINDMG) .. "-"
		 .. self:getRoleAttrById(Const_pb.MAXDMG));
end

function ViewMercenaryInfo:getStarLevel()
	return self.mercenaryInfo.starLevel or 0;
end

function ViewMercenaryInfo:getRoleInfo()
	return self.mercenaryInfo;
end

function ViewMercenaryInfo:getProfessionName()
	return common:getLanguageString("@ProfessionName_" .. self:getRoleInfo().prof);
end

function ViewMercenaryInfo:getRoleEquipByPart(part)
	return PBHelper:getRoleEquipByPart(self:getRoleInfo().equips, part);
end	

function ViewMercenaryInfo:getEquipById(equipId)
	for _, equipInfo in pairs(self.equipInfo) do
		if equipInfo.id == equipId then
			return equipInfo;
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
return ViewMercenaryInfo;