local ABTeamInfoManager = {}

local AB_pb = require("AllianceBattle_pb")
local Hp_pb = require("HP_pb")
local GuildDataManager = require("Guild.GuildDataManager")

ABTeamInfoManager.teamLists = {
	[1] = {
		teamList = {},
		teamSize = 0
	},
	[2] = {
		teamList = {},
		teamSize = 0
	},
	[3] = {
		teamList = {},
		teamSize = 0
	}
}	

--该公会的信息
ABTeamInfoManager.allianceItemInfo = {}

function ABTeamInfoManager:getTeamListByIndex(index)
	local teamList = ABTeamInfoManager.teamLists[index].teamList
	return teamList or nil
end

function ABTeamInfoManager:getTeamSizeByIndex(index)
	local teamSize = ABTeamInfoManager.teamLists[index].teamSize
	return teamSize or 0
end


function ABTeamInfoManager:sendPacketByAllianceId(allianceId)
	local msg = AB_pb.HPAllianceTeamDetail();
	msg.allianceId = tonumber(allianceId);
	common:sendPacket(Hp_pb.ALLIANCE_TEAM_DETAIL_INFO_C, msg);
end		

--receive the enter packet
function ABTeamInfoManager:onReceivePacket(msg)  
	local teamList = msg.teamList
    if msg:HasField("allianceItemInfo") then
        ABTeamInfoManager.allianceItemInfo = msg.allianceItemInfo
    end
    
	local size = #teamList
	local flagPos = 0
	ABTeamInfoManager.teamLists = {
        [1] = {
            teamList = {},
            teamSize = 0
        },
        [2] = {
            teamList = {},
            teamSize = 0
        },
        [3] = {
            teamList = {},
            teamSize = 0
        }
    }	
	for i=1,size do
		local oneInfo = teamList[i]
		local teamNode = {}
		if oneInfo.index == 1 then
			teamNode = ABTeamInfoManager.teamLists[1]
			--flagPos = 1
		elseif oneInfo.index == 2 then
			teamNode = ABTeamInfoManager.teamLists[2]
			--flagPos = 1
		elseif oneInfo.index == 3 then
			teamNode = ABTeamInfoManager.teamLists[3]
			--flagPos = 1
		end
		local pos = oneInfo.pos
		--assert(pos == flagPos,"Error in onReceivePacket where pos == flagPos")
		table.insert(teamNode.teamList,oneInfo)
		--[pos] = oneInfo
		teamNode.teamSize = teamNode.teamSize + 1
		--flagPos = flagPos + 1
	end
	if size == 0  then
		MessageBoxPage:Msg_Box_Lan("@ABTeamInfoNoMemberRightNow")
		return 
	end
	--弹框，或者刷新页面 
	return PageManager.pushPage("ABTeamInfoPage");
end

function ABTeamInfoManager:getPlayerId(index,pos) 
	return ABTeamInfoManager.teamLists[index].teamList[pos].id or nil
end
function ABTeamInfoManager:getPlayerFlag(index,pos) 
    if ABTeamInfoManager.teamLists[index].teamList[pos]:HasField("flag") then
        return ABTeamInfoManager.teamLists[index].teamList[pos].flag
    end
	return 0
end

function ABTeamInfoManager:getPlayerName(index,pos) 
	return ABTeamInfoManager.teamLists[index].teamList[pos].name or nil
end

function ABTeamInfoManager:getInspireNum(index,pos) 
    if ABTeamInfoManager.teamLists[index].teamList[pos]:HasField("inspireNum") then
	return ABTeamInfoManager.teamLists[index].teamList[pos].inspireNum or nil
    end
    return 0
end

function ABTeamInfoManager:getTotalInspireNum(index,pos) 
    if ABTeamInfoManager.teamLists[index].teamList[pos]:HasField("totalInspireNum") then
	return ABTeamInfoManager.teamLists[index].teamList[pos].totalInspireNum or nil
    end
    return 0
end

function ABTeamInfoManager:getPlayerLevel(index,pos) 
    if ABTeamInfoManager.teamLists[index].teamList[pos]:HasField("level") then
	    return ABTeamInfoManager.teamLists[index].teamList[pos].level or nil
    end
    return 0
end

function ABTeamInfoManager:getRebirthStage(index, pos)
    if ABTeamInfoManager.teamLists[index].teamList[pos]:HasField("rebirthStage") then
	    return ABTeamInfoManager.teamLists[index].teamList[pos].rebirthStage or nil
    end
    return 0
end

function ABTeamInfoManager:getPlayerItemId(index,pos) 
	return ABTeamInfoManager.teamLists[index].teamList[pos].itemId or nil
end


function ABTeamInfoManager:switchPersonByIndexAndPos(index1,pos1,index2,pos2) 
    if (not ABTeamInfoManager.teamLists[index2].teamList[pos2]) or (not ABTeamInfoManager.teamLists[index1].teamList[pos1]) then 
        return 
    end
	assert(ABTeamInfoManager.teamLists[index2].teamList[pos2] ~= nil,"Error in ABTeamInfoManager.teamLists[index2].teamList[pos2]")
	assert(ABTeamInfoManager.teamLists[index1].teamList[pos1] ~= nil,"Error in ABTeamInfoManager.teamLists[index1].teamList[pos1] == nil")
    --step.1 switch two value
    ABTeamInfoManager.teamLists[index1].teamList[pos1],ABTeamInfoManager.teamLists[index2].teamList[pos2]  = ABTeamInfoManager.teamLists[index2].teamList[pos2],ABTeamInfoManager.teamLists[index1].teamList[pos1]
    --step.2 rearange the pos and index
    ABTeamInfoManager.teamLists[index1].teamList[pos1].pos = pos1
    ABTeamInfoManager.teamLists[index2].teamList[pos2].pos = pos2
    ABTeamInfoManager.teamLists[index1].teamList[pos1].index = index1
    ABTeamInfoManager.teamLists[index2].teamList[pos2].index = index2
	return index2,pos2
end

function ABTeamInfoManager:onUpstair(index,pos) 
	local upPos = pos - 1
	if upPos == 0 then
		upPos = ABTeamInfoManager.teamLists[index].teamSize
	end
	return self:switchPersonByIndexAndPos(index,pos,index,upPos)
	
end

function ABTeamInfoManager:onDownstair(index,pos) 
	local downPos = pos + 1
	if downPos > ABTeamInfoManager.teamLists[index].teamSize then
		downPos = 1
	end
	return self:switchPersonByIndexAndPos(index,pos,index,downPos)
end

--如果下一个队列有空位，挪到最后一位，如果满了，与对应Index交换
function ABTeamInfoManager:changeTeamIndex(index,pos) 
	local totalSize = GuildDataManager:getGuildMemberSize()
	if totalSize>0 then
		local everyTeamSize = math.ceil(totalSize/3)
		local newIndex = index+1		
		if newIndex>3 then
			newIndex = 1
		end
		local newIndexTeamSize = ABTeamInfoManager.teamLists[newIndex].teamSize
		--如果有空位，挪到最后一个
		if newIndexTeamSize<everyTeamSize then
            --step.1 remove the original item from pos and cause the size minus 1
			local removedItem = table.remove(ABTeamInfoManager.teamLists[index].teamList,pos)
			ABTeamInfoManager.teamLists[index].teamSize = ABTeamInfoManager.teamLists[index].teamSize - 1
            --step.2 iterate all the child and rearange the pos of the data
			assert(removedItem.pos == pos,"Error in removedItem.pos == pos")
            for i=1,ABTeamInfoManager.teamLists[index].teamSize do
                ABTeamInfoManager.teamLists[index].teamList[i].pos = i
            end
            --step.3 add 1 for the size of new index list
			ABTeamInfoManager.teamLists[newIndex].teamSize = ABTeamInfoManager.teamLists[newIndex].teamSize + 1
            --step.4 set the removed item's new pos and new index
			removedItem.pos = ABTeamInfoManager.teamLists[newIndex].teamSize
            removedItem.index = newIndex
            --step.5 insert the removed item into the new index list
			table.insert(ABTeamInfoManager.teamLists[newIndex].teamList,removedItem)
			return true,newIndex,ABTeamInfoManager.teamLists[newIndex].teamSize
		else
			return false,self:switchPersonByIndexAndPos(index,pos,newIndex,pos)
		end
		
	end
end

function ABTeamInfoManager:viewDetail(index,pos) 
	local playerId = self:getPlayerId(index,pos)
	return PageManager.viewPlayerInfo(playerId)
end

function ABTeamInfoManager:assemblyTeamInfo() 
	local msg = AB_pb.HPAllianceTeamSave()
	for i=1,3 do
		local teamSize = ABTeamInfoManager.teamLists[i].teamSize
		assert(teamSize == #ABTeamInfoManager.teamLists[i].teamList, "Error in assemblyTeamInfo: teamSize == #ABTeamInfoManager.teamLists[i].teamSize" )
		for j = 1, teamSize do
			local oneInfo = ABTeamInfoManager.teamLists[i].teamList[j]
			assert(oneInfo.pos == j, "Error in assemblyTeamInfo: pos == j"..oneInfo.pos..".."..j )
            msg.idList:append(oneInfo.id);
            msg.posList:append(oneInfo.pos);
            msg.indexList:append(oneInfo.index);
            CCLuaLog("oneInfo.id is "..oneInfo.id.."oneInfo.pos is "..oneInfo.pos.."oneInfo.index is "..oneInfo.index)
		end
	end
	return msg	
end

function ABTeamInfoManager:saveChanges() 
	local sendMsg = ABTeamInfoManager:assemblyTeamInfo() 
	common:sendPacket(Hp_pb.ALLIANCE_TEAM_SAVE_C, sendMsg,false);
end

return ABTeamInfoManager