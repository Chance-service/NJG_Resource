
----------------------------------------------------------------------------------

local NodeHelper = require("NodeHelper")
local thisPageName = 'GuildSetBossTimePage'
local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local GuildData = require("Guild.GuildData")
local GuildSetBossTimeBase = {
	openTimeList = {},
}

local option = {
	ccbiFile = "GuildAdministrationBossPopUp.ccbi",
	handlerMap = {
		onCloseTimeSet1 	= 'onCloseTimeSet',
		onCloseTimeSet2 	= 'onCloseTimeSet',
		onCloseTimeSet3 	= 'onCloseTimeSet',
		onOpenTimeSet1		= 'onOpenTimeSet',
		onOpenTimeSet2		= 'onOpenTimeSet',
		onOpenTimeSet3		= 'onOpenTimeSet',
		onAddHour1 			= 'onAddHour',
		onReduceHour1		= 'onReduceHour',
		onAddMin1			= 'onAddMin',
		onReduceMin1		= 'onReduceMin',
		onAddHour2 			= 'onAddHour',
		onReduceHour2		= 'onReduceHour',
		onAddMin2			= 'onAddMin',
		onReduceMin2		= 'onReduceMin',
		onAddHour3 			= 'onAddHour',
		onReduceHour3		= 'onReduceHour',
		onAddMin3			= 'onAddMin',
		onReduceMin3		= 'onReduceMin',
        onClose 			= 'onClose',
		onHelp				= 'onHelp',
		onSave				= 'onSave',
	}
}

local contentInput = ''

function GuildSetBossTimeBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildSetBossTimeBase:onEnter(container)
	self:parseTimeList()
	self:refreshPage(container)
end

function GuildSetBossTimeBase:parseTimeList()
	local openTimeList = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.openTimeList or {}
	GuildSetBossTimeBase.openTimeList = {}
	for k,v in ipairs(openTimeList) do
		if v and v ~= "" then
			local timeInfo = {}
			local timeStr = Split(v,":")
			timeInfo.hour =  tonumber(timeStr[1])
			timeInfo.min = tonumber(timeStr[2])
			GuildSetBossTimeBase.openTimeList[k] = timeInfo
		else
			GuildSetBossTimeBase.openTimeList[k] = nil
		end
	end
end

function GuildSetBossTimeBase:onExit(container)
	GuildSetBossTimeBase.openTimeList = {}
end

function GuildSetBossTimeBase:refreshPage(container)
	local node = {}
	for i = 1, 3 do
		local timeInfo = GuildSetBossTimeBase.openTimeList[i]
		local closeNode = "mClose" .. i
		local openNode = "mOpen" .. i
		if timeInfo then
			node[closeNode] = false
			node[openNode] = true
			local hour = timeInfo.hour
			local min = timeInfo.min
			hour = string.format("%02d",hour)
			min = string.format("%02d",min)
			self:setTimeLabel(container,i,hour,min)
		else
			node[closeNode] = true
			node[openNode] = false
		end
	end
	NodeHelper:setNodesVisible(container,node)
end

function GuildSetBossTimeBase:onCloseTimeSet(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local node = {}
	local closeNode = "mClose" .. index
	local openNode = "mOpen" .. index
	node[closeNode] = true
	node[openNode] = false
	NodeHelper:setNodesVisible(container,node)
	GuildSetBossTimeBase.openTimeList[index] = nil
end

function GuildSetBossTimeBase:onOpenTimeSet(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local node = {}
	local closeNode = "mClose" .. index
	local openNode = "mOpen" .. index
	node[closeNode] = false
	node[openNode] = true
	NodeHelper:setNodesVisible(container,node)
	
	local timeInfo = GuildSetBossTimeBase.openTimeList[index]
	local hour = 0
	local min = 0
	if timeInfo then
		hour = timeInfo.hour
		min = timeInfo.min
		self:setTimeLabel(container,index,hour,min)
	else
		local timeInfo = {}
		timeInfo.hour =  hour
		timeInfo.min = min
		GuildSetBossTimeBase.openTimeList[index] = timeInfo
	end
	hour = string.format("%02d",hour)
	min = string.format("%02d",min)
	self:setTimeLabel(container,index,hour,min)
end

function GuildSetBossTimeBase:setTimeLabel(container,index,hour,min)
	local str = {}
	local hourStr = "mHour" .. index
	local minStr = "mMin" .. index
	if hour then str[hourStr] = hour end
	if min then str[minStr] = min end
	NodeHelper:setStringForLabel(container,str)
end

function GuildSetBossTimeBase:getHour(index)
	local timeInfo = GuildSetBossTimeBase.openTimeList[index]
	if timeInfo then
		return timeInfo.hour
	else
		return 0
	end
end

function GuildSetBossTimeBase:getMin(index)
	local timeInfo = GuildSetBossTimeBase.openTimeList[index]
	if timeInfo then
		return timeInfo.min
	else
		return 0
	end
end

function GuildSetBossTimeBase:setHour(index,hour) 
	local timeInfo = GuildSetBossTimeBase.openTimeList[index]
	if timeInfo then
		GuildSetBossTimeBase.openTimeList[index].hour = hour
	else
		local timeInfo = {}
		timeInfo.hour =  hour
		timeInfo.min = 0
		GuildSetBossTimeBase.openTimeList[index] = timeInfo
	end
end

function GuildSetBossTimeBase:setMin(index,min) 
	local timeInfo = GuildSetBossTimeBase.openTimeList[index]
	if timeInfo then
		GuildSetBossTimeBase.openTimeList[index].min = min
	else
		local timeInfo = {}
		timeInfo.hour =  0
		timeInfo.min = min
		GuildSetBossTimeBase.openTimeList[index] = timeInfo
	end
end

function GuildSetBossTimeBase:onAddHour(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local hour = self:getHour(index)
	if hour == 23 then
		hour = 0
	else
		hour = hour + 1
	end
	self:setHour(index,hour) 
	hour = string.format("%02d",hour)
	self:setTimeLabel(container,index,hour)
end

function GuildSetBossTimeBase:onReduceHour(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local hour = self:getHour(index)
	if hour == 0 then
		hour = 23
	else
		hour = hour - 1
	end
	self:setHour(index,hour) 
	hour = string.format("%02d",hour)
	self:setTimeLabel(container,index,hour)
end

function GuildSetBossTimeBase:onAddMin(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local min = self:getMin(index)
	if min == 59 then
		min = 0
	else
		min = min + 1
	end
	self:setMin(index,min) 
	min = string.format("%02d",min)
	self:setTimeLabel(container,index,nil,min)
end

function GuildSetBossTimeBase:onReduceMin(container,eventName)
	local index = tonumber(string.sub(eventName,-1))
	local min = self:getMin(index)
	if min == 0 then
		min = 59
	else
		min = min - 1
	end
	self:setMin(index,min) 
	min = string.format("%02d",min)
	self:setTimeLabel(container,index,nil,min)
end

function GuildSetBossTimeBase:onHelp(container)
	--PageManager.showHelp(GameConfig.HelpKey.HELP_ALLIANCE)
end

function GuildSetBossTimeBase:onClose(container)
	PageManager.popPage(thisPageName)
end

function GuildSetBossTimeBase:onSave(container)
	--GuildSetBossTimeBase.openTimeList
	local msg = alliance.OpenBossTimeRequest()
	
	for i=1,3 do
		local timeInfo = GuildSetBossTimeBase.openTimeList[i]
		local timeStr = ""
		if timeInfo then
			local hour = timeInfo.hour
			local min = timeInfo.min
			timeStr = string.format("%02d:%02d",hour,min)
		end
		msg.openTimeList:append(timeStr)
	end
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.ALLIANCE_SET_OPEN_BOSS_C, pb, #pb, false)
	self:onClose(container)
end

function GuildSetBossTimeBase:registerPackets(container)

end

function GuildSetBossTimeBase:removePackets(container)

end

function GuildSetBossTimeBase:onReceivePacket(container)

end
local CommonPage = require('CommonPage')
local GuildSetBossTimePage = CommonPage.newSub(GuildSetBossTimeBase, thisPageName, option)

return GuildSetBossTimeBase