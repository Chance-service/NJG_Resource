local UserInfo = require("PlayerInfo.UserInfo")
local ViewPlayerInfo = {
	snapshot = {};
	isFriend = false;
	isShield = false;
	isSendAllow = false;
    isSeeSelfInfoFlag = false;--是否查看自己
};
--------------------------------------------------------------------------------






------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
function ViewPlayerInfo:getInfo(playerId,playerName)
	local HP_pb = require("HP_pb");
    local Snapshot_pb = require("Snapshot_pb");
	local msg = Snapshot_pb.HPSeeOtherPlayerInfo();
	--如果是自己返回
	if playerId and playerId == UserInfo.playerInfo.playerId then 
		return
	elseif playerId and playerId ~= 0 then
		msg.type = 1
		msg.playerId = playerId;
	elseif playerName and playerName ~= "" then
		msg.type = 2
		msg.playerName = playerName;
	else
		return
	end
	common:sendPacket(HP_pb.SEE_OTHER_PLAYER_INFO_C, msg,false);
end

function ViewPlayerInfo:setInfo(msg)
	self.snapshot = msg.playerInfo;
	self.isFriend = msg.isFriend
	self.isShield = msg.isShield
	self.isSendAllow = msg.isSendAllow

    self.isCs = false
end

function ViewPlayerInfo:setCSInfo(playerInfo, identify)
	self.snapshot = playerInfo;
    self.csIdentify = identify
	self.isFriend = false
	self.isShield = false
	self.isSendAllow = true

    self.isCs = true
end

function ViewPlayerInfo:clearInfo()
	self.snapshot = {};
    self.csIdentify = nil
end	
--------------------------------------------------------------------------------
function ViewPlayerInfo:getRoleAttrById(attrId)
    local PBHelper = require("PBHelper");
	return PBHelper:getAttrById(self:getRoleInfo().attribute.attribute, attrId);
end

function ViewPlayerInfo:getIsCs()
    return self.isCs
end

function ViewPlayerInfo:getDamageString()
    local Const_pb = require("Const_pb");
	return (self:getRoleAttrById(Const_pb.MINDMG) .. "-"
		 .. self:getRoleAttrById(Const_pb.MAXDMG));
end

function ViewPlayerInfo:getRoleInfo()
	return self.snapshot.mainRoleInfo;
end

function ViewPlayerInfo:getAllianceInfo()
	return self.snapshot.allianceInfo;
end

function ViewPlayerInfo:getPlayerInfo()
	return self.snapshot.playerInfo;
end
function ViewPlayerInfo:getElementInfo()
	return self.snapshot.elementInfo;
end

function ViewPlayerInfo:getTittleInfo()
	return self.snapshot.titleInfo;
end

function ViewPlayerInfo:getSKillInfo()
	return self.snapshot.mainRoleInfo.skills;
end

function ViewPlayerInfo:getMercenaryInfo()
--	local roleInfos = {}
--	for _,v in pairs(self.snapshot.mercenaryInfo) do
--		if v.status == Const_pb.FIGHTING  then
--			roleInfos[#roleInfos+1] = v
--		end
--	end
	return self.snapshot.mercenaryInfo
end

function ViewPlayerInfo:getMercenaryFightingId()
	return self.snapshot.fightingRoleId
end

function ViewPlayerInfo:setIsFriend(flag)
	self.isFriend = flag
end

function ViewPlayerInfo:setIsShield(flag)
	self.isShield = flag
end

function ViewPlayerInfo:setIsSendAllow(flag)
	self.isSendAllow = flag
end


function ViewPlayerInfo:isFriendLabelStr()
	if self.isFriend then
		return common:getLanguageString("@DeleteFriend");
	else
		return common:getLanguageString("@AddFriend");
	end
end

function ViewPlayerInfo:isShieldLabelStr()
	if self.isShield then
		return common:getLanguageString("@UnshieldMsg");
	else
		return common:getLanguageString("@ShieldMsg");
	end
end

function ViewPlayerInfo:isSendAllowLabelStr()
	if self.isSendAllow then
		return common:getLanguageString("@PrivateChat");
	else
		return common:getLanguageString("@DisablePrivateChat");
	end
end

function ViewPlayerInfo:getProfessionName()
    if self:getRoleInfo().rebirthStage > 0 then
        return common:getLanguageString("@NewProfessionName_" .. self:getRoleInfo().prof)
    else 
	    return common:getLanguageString("@ProfessionName_" .. self:getRoleInfo().prof);
    end
end

function ViewPlayerInfo:getRoleEquipByPart(part)
    local PBHelper = require("PBHelper");
	return PBHelper:getRoleEquipByPart(self:getRoleInfo().equips, part);
end	

function ViewPlayerInfo:getMercenaryEquipByPart(part, mercenaryInfo)
    local PBHelper = require("PBHelper");
	return PBHelper:getRoleEquipByPart(mercenaryInfo.equips, part);
end	


function ViewPlayerInfo:getEquipById(equipId)
	for _, equipInfo in pairs(self.snapshot.equipInfo) do	
		if equipInfo.id == equipId then
			return equipInfo;
		end
	end
	return nil;
end

function ViewPlayerInfo:getMercenaryEquipById(equipId, mercenaryInfo)
	for k,v in pairs(mercenaryInfo.equips) do
		print(k,v)
	end
	for _, equipInfo in pairs(mercenaryInfo.equips) do
		if equipInfo.equipId == equipId then
			return equipInfo;
		end
	end
	return nil;
end
--------------------------------------------------------------------------------
return ViewPlayerInfo;