----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local Const_pb = require("Const_pb")
function onReceivePacket(opcode)
	local HP_pb = require("HP_pb")
	local UserInfo = require("PlayerInfo.UserInfo")
	if opcode == HP_pb.PLAYER_INFO_SYNC_S then
		UserInfo.syncPlayerInfo()
		if PageManger then
			PageManger.refreshPage("MainScenePage")
		end
	elseif opcode == HP_pb.ROLE_INFO_SYNC_S then
		UserInfo.sync()
		--UserEquipManager:check()
	end
end

function onRefreshNoticePoint(nType)
	if nType == Const_pb.NEW_MAIL then
		--邮件红点开启ARENARECORD_POINT
        require("Util.RedPointManager")
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_MAIL_BTN, 1, true)
		NoticePointState.MAIL_POINT_OPEN = true
        	NoticePointState.PULLDOWN_POINT = true
        	PageManager.refreshPage("MainScenePage")
	elseif nType == GameConfig.NewPointType.TYPE_MAIL_CLOSE then
		--邮件红点关闭
        RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_MAIL_BTN, 1, false)
		NoticePointState.MAIL_POINT_OPEN = false
        	NoticePointState.PULLDOWN_POINT = false
        	PageManager.refreshPage("MainScenePage")
		-- 礼包红点
	elseif nType == Const_pb.GIFT_NEW_MSG then
		NoticePointState.GIFT_NEW_MSG = true
	elseif nType == GameConfig.NewPointType.TYPE_GIFT_NEW_CLOSE then
		NoticePointState.GIFT_NEW_MSG = false
		-- 公会boss开启红点
	elseif nType == Const_pb.ALLIANCE_BOSS_OPEN then
		NoticePointState.ALLIANCE_BOSS_OPEN = true
	elseif nType == GameConfig.NewPointType.TYPE_ALLIANCE_NEW_CLOSE then
		NoticePointState.ALLIANCE_BOSS_OPEN = false
	elseif nType == Const_pb.NEW_MSG then
	
	elseif nType == GameConfig.NewPointType.TYPE_CHAT_MESSAGE_CLOSE then
	
	elseif nType == Const_pb.TEAM_BATTLE_SIGNUP then	
		NoticePointState.REGINMENTWAR_POINT = true
	elseif nType == GameConfig.NewPointType.TYPE_RegimentWar_NEW_CLOSE then
		NoticePointState.REGINMENTWAR_POINT = false
	elseif nType == Const_pb.ARENA_ALL_SIGNUP then
		NoticePointState.ARENARECORD_POINT = true
        	PageManager.refreshPage("ArenaRecordPageRedPoint")
	elseif nType == GameConfig.NewPointType.TYPE_ARENA_RECORD_CLOSE then
		NoticePointState.ARENARECORD_POINT = false
        	PageManager.refreshPage("ArenaRecordPageRedPoint")
	elseif nType == Const_pb.MULTI_ELITE_AVALIABLE then
		NoticePointState.MULTI_ELITE_AVALIABLE = true
	elseif nType == GameConfig.NewPointType.MULTI_ELITE_CLOSE then
		NoticePointState.MULTI_ELITE_AVALIABLE = false
	elseif nType == Const_pb.ACHIEVEMENT_POINT then
		NoticePointState.ACHIEVEMENT_POINT = true
	elseif nType == GameConfig.NewPointType.ACHIEVEMENT_POINT_CLOSE then
		NoticePointState.ACHIEVEMENT_POINT = false
	end

	NoticePointState.isChange = true
end

--消息处理
function onListenMsg(eventName, gameMsg)
	local typeId = gameMsg:getTypeId()

	if typeId == MSG_SEVERINFO_UPDATE then
		local opcode = MsgSeverInfoUpdate:getTrueType(gameMsg).opcode
		onReceivePacket(opcode)
	elseif typeId == MSG_GET_NEW_INFO then
		local nType = MsgMainFrameGetNewInfo:getTrueType(gameMsg).type
		onRefreshNoticePoint(nType)
		if nType == Const_pb.ALLIANCE_BOSS_OPEN then
			local msg = MsgMainFrameRefreshPage:new()
			msg.pageName = "GuildPage"
			MessageManager:getInstance():sendMessageForScript(msg)
        	elseif nType == GameConfig.ShopEventType.JumpSubPage_2 then --跳到商店第二个页面  ， 购买金币
			ShopTypeContainer_JupmToSubPageByIndex(2)
		end
	elseif typeId == MSG_MAINFRAME_PUSHPAGE then
		GameUtil:hideTip()
	end
end

msgHandler = MessageScriptHandler:new(onListenMsg)

function validateAndRegisterMsgHandler()
	CCLuaLog("validateAndRegisterMsgHandler()")
	msgHandler:registerFunctionHandler(onListenMsg)
end

MessageManager:getInstance():regisiterMessageHandler(MSG_SEVERINFO_UPDATE, msgHandler)
MessageManager:getInstance():regisiterMessageHandler(MSG_GET_NEW_INFO, msgHandler)
MessageManager:getInstance():regisiterMessageHandler(MSG_MAINFRAME_PUSHPAGE, msgHandler)
