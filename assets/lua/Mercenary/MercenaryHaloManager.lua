local MercenaryHaloManager = {
    curLvlUpTime = 0;

}

MercenaryHaloManager.HaloMap = {}

MercenaryHaloMinStarLvl = 3
MercenaryHaloManager.WGroup = {}
MercenaryHaloManager.HGroup = {}
MercenaryHaloManager.MGroup = {}


--judge whether the ring is actived and return the ringInfo
function MercenaryHaloManager:getRingInfoByItemIdNRoleId(itemId,roleId)
    if MercenaryHaloManager.HaloMap[roleId] == nil then
		return false,nil
	end
	for _,value in pairs(MercenaryHaloManager.HaloMap[roleId]) do	
		local oneInfo = value
		if oneInfo.itemId == itemId then
			return true,oneInfo
		end
	end
	return false,nil
end

function MercenaryHaloManager:getCurLvlUpTime() 
    MercenaryHaloManager.curLvlUpTime = 0
    for _,value in pairs(MercenaryHaloManager.HaloMap) do	
        local oneMap = value
        for k,v in pairs(oneMap) do 
            local oneInfo = v
            MercenaryHaloManager.curLvlUpTime = MercenaryHaloManager.curLvlUpTime + oneInfo.lvlUpTimes    
        end
		
	end
    return MercenaryHaloManager.curLvlUpTime
end

function MercenaryHaloManager:checkMerHasRingById(roleId)  
	if MercenaryHaloManager.HaloMap[roleId] == nil then
		return false
	else
		return true
	end
end

--检测是否有已经达到星级却没有激活的光环，用来红点显示
function MercenaryHaloManager:checkHasActivedHaloByMercenary(selectedMercenary)  
	local groupMap = {}
	if selectedMercenary.itemId == 7 then
		groupMap = MercenaryHaloManager.WGroup
	elseif selectedMercenary.itemId == 8 then
		groupMap = MercenaryHaloManager.HGroup
	elseif selectedMercenary.itemId == 9 then
		groupMap = MercenaryHaloManager.MGroup
	end	
	local UserEquipManager = require("Equip.UserEquipManager")
	local starLevel = tonumber(selectedMercenary.starLevel)
	for i=1,#groupMap do
		local oneRing = groupMap[i]
		local ringItemId = oneRing["ringId"]	
		if starLevel>= tonumber(MercenaryHaloManager:getStarLimitByRingId(ringItemId)) then			
			if MercenaryHaloManager:checkActivedByItemId(selectedMercenary.roleId,ringItemId) == false then			
				return true
			else
				UserEquipManager:setRedPointNotice(selectedMercenary.roleId, true)
			end		
		end
	end
	return false
end

function MercenaryHaloManager:checkActivedByItemId(roleId,itemId)  
	if MercenaryHaloManager.HaloMap[roleId] == nil then
		return false
	end
	for _,value in pairs(MercenaryHaloManager.HaloMap[roleId]) do	
		local oneInfo = value
		if oneInfo.itemId == itemId then
			return true
		end
	end
	return false
end


function MercenaryHaloManager:onRecieveSyncMsg(msg) 
    local UserEquipManager = require("Equip.UserEquipManager")
	if msg~=nil and msg.ringInfos ~=nil then
		local size = #msg.ringInfos
        
		for i=1,size do
			local oneInfo = msg.ringInfos[i]
			local roleId = oneInfo.roleId
            local itemId = oneInfo.itemId
            CCLuaLog("oneInfo###############"..tostring(oneInfo))
			if MercenaryHaloManager.HaloMap[roleId] == nil then
				MercenaryHaloManager.HaloMap[roleId] = {}
				table.insert(MercenaryHaloManager.HaloMap[roleId],oneInfo)
			else
                --replace or insert the data into map
                local isReplace = false
                for k,value in pairs(MercenaryHaloManager.HaloMap[roleId]) do	
		            local oneData = value
		            if oneData.itemId == itemId then
			            MercenaryHaloManager.HaloMap[roleId][k] = oneInfo
                         CCLuaLog("MercenaryHaloManager.HaloMap[roleId][k]"..tostring(MercenaryHaloManager.HaloMap[roleId][k]))
                        isReplace = true
		            end
	            end
                if not isReplace then 
                    table.insert(MercenaryHaloManager.HaloMap[roleId],oneInfo)
                end
				
			end	

            local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
            local starLevel = mercenaryInfo.starLevel
            if starLevel>= tonumber(self:getStarLimitByRingId(itemId)) then			
		        if not self:checkActivedByItemId(roleId,itemId) then
                    UserEquipManager:setRedPointNotice(roleId, true)
                --else
                    --UserEquipManager:setRedPointNotice(roleId, false)
                end
            end
		end
	end

    
    PageManager.setAllMercenaryNotice()
    --UserMercenaryManager:updateMercenaryRedPoint()
    --PageManager.refreshPage("EquipMercenaryPage")
end


function MercenaryHaloManager:getAttrByRingId(id, attrName)
	local ringCfg = ConfigManager.getMercenaryRingCfg();
	local config = ringCfg[id];
	if config then
		return config[attrName];
	end
	return "";
end

function MercenaryHaloManager:getNameByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "name")
end

function MercenaryHaloManager:getIconByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "icon")
end

function MercenaryHaloManager:getStarLimitByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "starLimit")
end

function MercenaryHaloManager:getConsumeByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "consume")
end

function MercenaryHaloManager:getDiscribeByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "discribe")
end

function MercenaryHaloManager:getConditionByRingId(id)
	return MercenaryHaloManager:getAttrByRingId(id, "condition")
end
--光环相关end


--光环升级相关 begin
function MercenaryHaloManager:getLevelAttrByItemIdNLevel(itemId,level,attName)
    local ringLevelCfg = ConfigManager.getRingLevelConfig();
    --assert(level>0 and itemId > 0,"level>0 and itemId > 0")
	if level == 0 then
		level = 1
	end
    local index = itemId * 100 + level
	local config = ringLevelCfg[index];
	if config then
		return common:getLanguageString(config[attName],config["param1"])
	end
	return "";
end

function MercenaryHaloManager:getDiscribeByItemItNLevel(itemId,level)
	return MercenaryHaloManager:getLevelAttrByItemIdNLevel(itemId,level,"discribe")
end

function MercenaryHaloManager:getExpByItemItNLevel(itemId,level)
	return MercenaryHaloManager:getLevelAttrByItemIdNLevel(itemId,level,"exp")
end
--光环升级相关 end

function MercenaryHaloManager:classifyGroup(cfg)  
	local size = #cfg
	
	if #MercenaryHaloManager.WGroup > 0 then
		return 
	end
	for key, value in pairs(cfg) do	
		local ringId = value["ringId"]
		local merId = value["merId"]
		if merId == 7 then
			table.insert(MercenaryHaloManager.WGroup,value)
		elseif merId == 8 then
			table.insert(MercenaryHaloManager.HGroup,value)
		elseif merId == 9 then
			table.insert(MercenaryHaloManager.MGroup,value)
		end

        if value.starLimit < MercenaryHaloMinStarLvl then
            MercenaryHaloMinStarLvl = value.starLimit
        end
	end
end

function MercenaryHaloManager:resetData()
    MercenaryHaloManager.HaloMap = {}
    MercenaryHaloManager.curLvlUpTime = 0
end


return MercenaryHaloManager;