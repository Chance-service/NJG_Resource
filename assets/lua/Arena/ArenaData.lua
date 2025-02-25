require "HP_pb"
require "Arena_pb"

local ArenaData = {}

ArenaDataPageInfo = nil

function onReceiveArenaDataPageInfo(eventName,handler)
	if eventName == "luaReceivePacket" then
		local msg = Arena_pb.HPArenaDefenderListSyncS()
		local msgbuff = handler:getRecPacketBuffer()
		msg:ParseFromString(msgbuff)				
		if msg ~= nil then
			ArenaDataPageInfo = msg
			table.sort(ArenaDataPageInfo.defender,
				function (e1, e2)
				if not e2 then return true end
				if not e1 then return false end
		
				return e1.rank < e2.rank
			end
			)
			--ˢ����Ҫ��ʾ��ҳ����Ϣ�������л�������ҳ���ж��ݲ�һ������
			if  ArenaRankCacheInfo then
				ArenaRankCacheInfo.self.rank = msg.self.rank
				ArenaRankCacheInfo.self.fightValue = msg.self.fightValue
				ArenaRankCacheInfo.self.rankAwardsStr = msg.self.rankAwardsStr
		--buyed times
            	require("ArenaPage")
            	ArenaAlreadyBuyTimes = msg.self.alreadyBuyTimes
            	--
						
				local msg = MsgMainFrameRefreshPage:new()
				msg.pageName = "ArenaPage"
				MessageManager:getInstance():sendMessageForScript(msg)
			end
		else
			CCLuaLog("@onReceiveArenaDataPageInfo -- error in data")
		end
	end 
end

ArenaDataPageHandler = PacketScriptHandler:new(HP_pb.ARENA_DEFENDER_LIST_SYNC_S, onReceiveArenaDataPageInfo)

function ArenaData.validateAndRegister()
	
	ArenaDataPageHandler:registerFunctionHandler(onReceiveArenaDataPageInfo) 
end

function ArenaData.setArenaLastTimes( lastTime )
	ArenaDataPageInfo.self.surplusChallengeTimes = lastTime
end

function ArenaData.getArenaChallengeTimes()
    if ArenaDataPageInfo then
        return ArenaDataPageInfo.self.surplusChallengeTimes
    else
        return 0
    end
end

function ArenaData.notifyArenaRecordCancelRedPoint()
	local message = MsgMainFrameGetNewInfo:new()
	NoticePointState.ARENARECORD_POINT = GameConfig.NewPointType.TYPE_ARENA_RECORD_CLOSE
	message.type = GameConfig.NewPointType.TYPE_ARENA_RECORD_CLOSE
	MessageManager:getInstance():sendMessageForScript(message)
end

return ArenaData