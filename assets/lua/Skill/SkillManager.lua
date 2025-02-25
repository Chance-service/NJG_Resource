local skillPb = require("Skill_pb")
local ConfigManager = require("ConfigManager")
local SkillManager = {}

--主角上阵SkillList
local SkillList = {
	fightSkillList = {},
	arenaSkillList = {},
	defenseSkillList = {}
}

--佣兵的上阵的SkillList
SkillManager.MerSkillList = {}
--佣兵的光环
SkillManager.MerRingList = {}

--开放的技能列表，包括主角和佣兵
SkillManager.OpenSkillList = {}

SkillManager.MerAllSkillList = {}
--佣兵被动技能列表
SkillManager.MerAllPassiveSkill= {}

local skillCfg = ConfigManager.getSkillCfg()
-------------------------------------------------------------------------

function SkillManager:getOpenSkillSizeByRoleId(roleId)
	if roleId ~= nil then
        if SkillManager.OpenSkillList[roleId] ~= nil then
            return #SkillManager.OpenSkillList[roleId] 
        else
            return 0
        end
    end
end

function SkillManager:getOpenSkillListByRoleId(roleId)
  if SkillManager.SkillCount==0 then
    SkillManager:classifyOpenSkillDataFromC()
  end
	if SkillManager.OpenSkillList[roleId] ~= nil then
		return SkillManager.OpenSkillList[roleId] 
	else
	--	assert(false,"SkillManager.OpenSkillList[roleId] error")
	--	return nil
		SkillManager:classifyOpenSkillDataFromC()
		return {}
	end
end

function SkillManager:classifyOpenSkillDataFromC()
	local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
  SkillManager.SkillCount = count
	SkillManager.OpenSkillList = {}
	for i=0, count-1 do
		local skillStr = ServerDateManager:getInstance():getSkillInfoByIndexForLua(i)
		local skillInfo = skillPb.SkillInfo()
		skillInfo:ParseFromString(skillStr)
		
		if skillInfo then
			local roleId = skillInfo.roleId
			if SkillManager.OpenSkillList[roleId] == nil then
				SkillManager.OpenSkillList[roleId] = {}
				table.insert(SkillManager.OpenSkillList[roleId],skillInfo);
			else
				table.insert(SkillManager.OpenSkillList[roleId],skillInfo);
			end								
		end
	end
end

function SkillManager:getEquipSkillListByRoleIdAndBagId(roleId,bagId)
		--主角
    local UserInfo = require("PlayerInfo.UserInfo");
	if roleId == UserInfo.roleInfo.roleId then
		if bagId == 1 then
			return SkillManager:getFightSkillList()
		elseif bagId == 2 then
			return SkillManager:getArenaSkillList()
		elseif bagId == 3 then
			return SkillManager:getDefenseSkillList()
		end
	else
		--佣兵相关
		return SkillManager:getMerEquipSkillListByMerId(roleId)
	end
end


--刷图技能
function SkillManager:getFightSkillList()
	return SkillList.fightSkillList
end

--单挑技能
function SkillManager:getArenaSkillList()
	return SkillList.arenaSkillList
end

--防守技能
function SkillManager:getDefenseSkillList()
	return SkillList.defenseSkillList
end	

--获取技能itemId
function SkillManager:getSkillItemIdUsingId( skillId )
    if skillId ==nil then return nil end
	if skillId <= 0 then return 0 end
	local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
	if count <= 0 then return 0 end
	local skillStr = ServerDateManager:getInstance():getSkillInfoByIdForLua(skillId)
	local skillInfo = skillPb.SkillInfo()
	skillInfo:ParseFromString(skillStr)
	if skillInfo then
		return skillInfo.itemId
	else
		return 0
	end
end

--获得技能服务端id
function SkillManager:getSkillIdByItemId( itemId )
	if itemId <= 0 then return 0 end

    local size = ServerDateManager:getInstance():getSkillInfoTotalSize()

    for i=0,size-1 do
        local skillStr = ServerDateManager:getInstance():getSkillInfoByIndexForLua(i)
	    local skillInfo = skillPb.SkillInfo()
	    skillInfo:ParseFromString(skillStr)
	    if skillInfo and skillInfo.itemId==itemId then
		    return skillInfo.id
	    end
    end
    return 0
end

--获取技能等级
function SkillManager:getSkillLevelUsingId( skillId )
	if skillId <= 0 then return 0 end
	local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
	if count <= 0 then return 0 end
	local skillStr = ServerDateManager:getInstance():getSkillInfoByIdForLua(skillId)
	local skillInfo = skillPb.SkillInfo()
	skillInfo:ParseFromString(skillStr)
	if skillInfo then
		return skillInfo.skillLevel
	else
		return 0
	end
end
--计算技能专精等级
function SkillManager:getSpecalSkillLevelByProfession( itemId )
	local UserInfo = require("PlayerInfo.UserInfo");
	return UserInfo.roleInfo.skillSpecializeLevel
end
function SkillManager:getSkillLevelByItemId( itemId )
	if itemId <= 0 then return 0 end

    local size = ServerDateManager:getInstance():getSkillInfoTotalSize()

    for i=0,size-1 do
        local skillStr = ServerDateManager:getInstance():getSkillInfoByIndexForLua(i)
	    local skillInfo = skillPb.SkillInfo()
	    skillInfo:ParseFromString(skillStr)
	    if skillInfo and skillInfo.itemId==itemId then
		    return skillInfo.skillLevel
	    end
    end
    return 0
end

--获取技能经验
function SkillManager:getSkillExpUsingId( skillId )
	if skillId <= 0 then return 0 end
	local count = ServerDateManager:getInstance():getSkillInfoTotalSize()
	if count <= 0 then return 0 end
	local skillStr = ServerDateManager:getInstance():getSkillInfoByIdForLua(skillId)
	local skillInfo = skillPb.SkillInfo()
	skillInfo:ParseFromString(skillStr)
	if skillInfo and skillInfo:HasField("exp") then
		return skillInfo.exp
	else
		return 0
	end
end

function SkillManager:getSkillExpByItemId( itemId )
	if itemId <= 0 then return 0 end

    local size = ServerDateManager:getInstance():getSkillInfoTotalSize()

    for i=0,size-1 do
        local skillStr = ServerDateManager:getInstance():getSkillInfoByIndexForLua(i)
	    local skillInfo = skillPb.SkillInfo()
	    skillInfo:ParseFromString(skillStr)
	    if skillInfo and skillInfo.itemId==itemId and skillInfo:HasField("exp") then
		    return skillInfo.exp
	    end
    end
    return 0
end

--获取技能信息
function SkillManager:getSkillInfoBySkillId( skillId )
	local itemId = self:getSkillItemIdUsingId(skillId)
	if itemId > 0 then
		return self:getSkillInfoByItemId( itemId )
	else
		return {}
	end
end	

--获取技能信息EX
function SkillManager:getSkillInfoBySkillIdEx( skillId )
	local itemId = self:getSkillItemIdUsingId(skillId)
    local level = self:getSkillLevelByItemId(itemId)
    if itemId~=0 then
        level = level~=0 and level or 1
    end
    local skillItemId = tonumber(string.format(tostring(itemId).."%0004d",level))
	if skillItemId > 0 then
		return self:getSkillInfoByItemIdEx( skillItemId )
	else
		return {}
	end
end	

function SkillManager:getSkillInfoByItemIdEx( itemId )
    local skillEnhanceCfg = ConfigManager.getSkillEnhanceCfg()
    if skillEnhanceCfg[itemId]~=nil then
        return skillEnhanceCfg[itemId]
    end
    return {}
end
--
function SkillManager:checkNewSkill(isInit)
    local UserInfo = require("PlayerInfo.UserInfo");
	local level = UserInfo.roleInfo.level or 0;
	local skillCount = #(UserInfo.roleInfo.skills or {});
	if (UserInfo.level > 0 or isInit)
		and UserInfo.level < level 
		and skillCount > #SkillList.fightSkillList 
		and skillCount > #SkillList.arenaSkillList
		and skillCount > #SkillList.defenseSkillList 
	then
		local skillOpenCfg = ConfigManager.getSkillOpenCfg();
		local unLockLevel = 0;
		local openCount = 0;
		for _, cfg in ipairs(skillOpenCfg) do
			local openLevel = cfg.openLevel;
			if openLevel > unLockLevel and openLevel <= level then
				unLockLevel = cfg.openLevel;
				openCount = tonumber(cfg.id);
			end
		end
		if unLockLevel > 0 and unLockLevel > UserInfo.skillUnlock.level then
			local key = string.format("Skill_%d_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId, unLockLevel);
			local hasTip = CCUserDefault:sharedUserDefault():getBoolForKey(key);
			if not hasTip then
				PageManager.showRedNotice("Skill", true);
				UserInfo.skillUnlock.hasNew = true;
			end
			UserInfo.skillUnlock.level = unLockLevel;
		end
	end
end

function SkillManager:unlockSkillListener()
	--UserInfo.sync()
    local UserInfo = require("PlayerInfo.UserInfo");
	if #UserInfo.roleInfo.skills > #SkillList.fightSkillList or #UserInfo.roleInfo.skills > #SkillList.arenaSkillList or #UserInfo.roleInfo.skills > #SkillList.defenseSkillList then
		local openCount = #UserInfo.roleInfo.skills - #SkillList.fightSkillList
		for i = 1, openCount ,1 do
		    table.insert(SkillList.fightSkillList,0)
		    table.insert(SkillList.arenaSkillList,0)
			table.insert(SkillList.defenseSkillList,0)
		end
	end
	
	
	local msg = MsgMainFrameRefreshPage:new()
	msg.pageName = "SkillPage"
	MessageManager:getInstance():sendMessageForScript(msg)
	
end		

function SkillManager:classifyMerSkill(cfg)
	SkillManager.MerAllSkillList = {}

	for k,v in pairs( cfg ) do
		if v.roleId > 0 then
			
			if SkillManager.MerAllSkillList[v.roleId] == nil then
				SkillManager.MerAllSkillList[v.roleId] = {}
				SkillManager.MerAllSkillList[v.roleId][1] = v
			else				
				local len = #SkillManager.MerAllSkillList[v.roleId] + 1
				SkillManager.MerAllSkillList[v.roleId][len] = v
			end				
		end
	end
	--[[
	for k,v in pairs( cfg ) do
		if v.roleId == 7 then
			
			if SkillManager.MerAllSkillList[v.roleId] == nil then
				SkillManager.MerAllSkillList[v.roleId] = {}
			end
			SkillManager.MerAllSkillList[v.roleId][count] = v
			count = count + 1
		elseif v.roleId == 8 then
			local count = 1
			if SkillManager.MerAllSkillList[v.roleId] == nil then
				SkillManager.MerAllSkillList[v.roleId] = {}
			end
			SkillManager.MerAllSkillList[v.roleId][count] = v
			count = count + 1
		elseif v.roleId == 9 then
			local count = 1
			if SkillManager.MerAllSkillList[v.roleId] == nil then
				SkillManager.MerAllSkillList[v.roleId] = {}
			end
			SkillManager.MerAllSkillList[v.roleId][count] = v
			count = count + 1
		end
	end
	]]
end

function SkillManager:getMerAllSkillByRoleId( roleId )
    if #SkillManager.MerAllSkillList == 0 then
        local skillCfg = ConfigManager.getSkillCfg()
        SkillManager:classifyMerSkill( skillCfg )
    end
	local list = SkillManager.MerAllSkillList[roleId]
    if not list then return {} end;
	table.sort(list, function (c1, c2)
		return c1.openLevel < c2.openLevel
	end)
	return list
end
--光环分类
function SkillManager:classifyMerPassiveSkill(cfg)
	SkillManager.MerAllPassiveSkill = {}
	for k,v in pairs( cfg ) do
        if SkillManager.MerAllPassiveSkill[v.merId] == nil then
            SkillManager.MerAllPassiveSkill[v.merId] = {}
            SkillManager.MerAllPassiveSkill[v.merId][1] = v
        else				
            local len = #SkillManager.MerAllPassiveSkill[v.merId] + 1
            SkillManager.MerAllPassiveSkill[v.merId][len] = v
        end	
    end
end
--获取佣兵被动技能
 function SkillManager:getMerPassiveSkillByRoleId( roleId )
    if #SkillManager.MerAllPassiveSkill == 0 then
        local ringCfg = ConfigManager.getMercenaryRingCfg()
        SkillManager:classifyMerPassiveSkill(ringCfg)
    end
	local list = SkillManager.MerAllPassiveSkill[roleId]
    if not list then return {} end;
	table.sort(list, function (c1, c2)
		return c1.ringId < c2.ringId
	end)
	return list
end
 
-------------------------------------------------------------------------

function SkillManager:getSkillInfoByItemId( itemId )
	if skillCfg[itemId] ~= nil then
		return skillCfg[itemId]
	else
		return {}
	end
end



function SkillManager:setSkillListInfo(msg)
	SkillList.fightSkillList = msg.skillId1
	SkillList.arenaSkillList = msg.skillId2
	SkillList.defenseSkillList = msg.skillId3
	SkillManager:checkNewSkill(true);
end

function SkillManager:onRecieveMerSkillList(msg)
	local merId = msg.roleId	
	SkillManager.MerSkillList[merId] = msg.skillId1
	
end

function SkillManager:refreshMerSkillListBy( merId ,starLevel )
	local cfg = ConfigManager.getMercenarySkillOpenCfg()
	local count = 0
	for _,v in ipairs(cfg) do
		if v.openLevel <= starLevel then
			count = count + 1
		end
	end
	
	local newCount = count - #SkillManager.MerSkillList[merId]
	if newCount > 0 then
		for i = 1,newCount,1 do
			table.insert( SkillManager.MerSkillList[merId] , 0 )
		end
	end
	
end

function SkillManager:getMerEquipSkillListByMerId(merId)
	if SkillManager.MerSkillList[merId]~=nil  then
		return SkillManager.MerSkillList[merId]
	else
		assert(false,"error in getMerSkillIdByMerId")
		return nil
	end
end

function SkillManager_Reset()
	SkillList.fightSkillList = {}
	SkillList.arenaSkillList = {}
	SkillList.defenseSkillList = {}
end

-----------------------------------------------------------------------------------------
return SkillManager