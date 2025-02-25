--[[
	语音聊天
--]]

local UserInfo = require("PlayerInfo.UserInfo")
local GuildDataManager = require("Guild.GuildDataManager")

local VoiceChatManager = {}
local voiceMenuRect = nil
local voiceBtn = nil

VoiceChatManager.playerArea = ""

VoiceChatManager.guildChatCount = -1
VoiceChatManager.worldChatCount = -1
VoiceChatManager.crossChatCount = -1

local titleManager = require("PlayerInfo.TitleManager")
VoiceChatManager.currChatType = Const_pb.CHAT_WORLD

VoiceChatManager.guildChatMessageList = {
	
}

VoiceChatManager.worldChatMessageList = {

}

VoiceChatManager.crossChatMessageList = {

}

VoiceChatManager.guildChatMessageTmpList = {}
VoiceChatManager.worldChatMessageTmpList = {}
VoiceChatManager.crossChatMessageTmpList = {}

local chatMessage = {
	chatType = 0, --0 文字，1语音
	chatState = 0, --0 失败 ， 1上传中 ，2失败
	troopsId = "",
	voicePath = "",
	voiceTime = 0,
	chatMsg = "",
	voiceInfo = {
		[1] = 0, 	-- playerId
		[2] = "",	--name
		[3] = 0,	--level
		[4] = 0,	--roleItemId
		[5] = "",	--chatMsg
		[6] = "",	--area
		[7] = 0,	--titleId
		[8] = 0,	--playerType
		[9] = 0,	--rebirthStage
	}
}
-------------------------------------------------------------------------------------
function VoiceChatManager.fillPlayerInfo()
	
	UserInfo.sync()
	
	chatMessage.voiceInfo[1] = UserInfo.playerInfo.playerId
	chatMessage.voiceInfo[2] = UserInfo.roleInfo.name
	chatMessage.voiceInfo[3] = UserInfo.roleInfo.level
	chatMessage.voiceInfo[4] = UserInfo.roleInfo.itemId	
	if UserInfo.stateInfo.showArea == 1 then
		chatMessage.voiceInfo[6] = VoiceChatManager.playerArea
	else
		chatMessage.voiceInfo[6] = ""
	end
	
	chatMessage.voiceInfo[7] = titleManager.myNowTitleId
	chatMessage.voiceInfo[8] = 0	
	CCLuaLog("VoiceChatManager:" .. titleManager.myNowTitleId)
end

function VoiceChatManager.sendMessage( message,channelType )
    local msg = Chat_pb.HPSendChat();
	if msg~=nil and channelType ~= nil then
		msg.chatMsg = message
		msg.chatType = 	channelType
		local pb_data = msg:SerializeToString();
		PacketManager:getInstance():sendPakcet(HP_pb.SEND_CHAT_C,pb_data,#pb_data,false);
	end
end

function VoiceChatManager.clearChatMessage()
	chatMessage.chatType = 0 
	chatMessage.chatState = 0
	chatMessage.troopsId = ""
	chatMessage.voicePath = ""
	chatMessage.voiceTime = 0
	chatMessage.voiceInfo[1] = 0
	chatMessage.voiceInfo[2] = ""
	chatMessage.voiceInfo[3] = 0
	chatMessage.voiceInfo[4] = 0
	chatMessage.voiceInfo[5] = ""	
	chatMessage.voiceInfo[6] = ""
	chatMessage.voiceInfo[7] = 0
	chatMessage.voiceInfo[8] = 0

end
------------------------------------------------------------------------------

function VoiceChatManager.isOnVoiceChatMenuItem( pTouch )
    local point = pTouch:getLocation()
    point = voiceBtn:convertToNodeSpace(point)
	return GameConst:getInstance():isContainsPoint( voiceMenuRect , point )
end	

function VoiceChatManager.receiveMessage( tab ,chatType )
   
    VoiceChatManager.clearChatMessage()
    
    chatMessage.chatType = 0
    chatMessage.msgTime  = tab.msTime
    chatMessage.chatMsg = tab.chatMsg
    chatMessage.voiceInfo[1] = tab.playerId
    chatMessage.voiceInfo[2] = tab.name
    chatMessage.voiceInfo[3] = tab.level
    chatMessage.voiceInfo[4] = tab.roleItemId
    chatMessage.voiceInfo[5] = "" --tab.chatMsg
    chatMessage.skinId = tab.skinId
	chatMessage.headIcon = tab.headIcon
    chatMessage.avatarId = tab.avatarId
    chatMessage.cspvpRank = tab.cspvpRank
    chatMessage.cspvpScore = tab.cspvpScore

--[[   if tab:HasField("senderIdentify") then
        chatMessage.senderIdentify = tab.senderIdentify
        local temp1 = common:split(tab.senderIdentify,"#")
        if temp1[2] then
            local temp2 = common:split(temp1[2],"*")
            local sId = tonumber(temp2[1]) or -1
            if sId > 0 then
                chatMessage.voiceInfo[2] = common:getLanguageString("@PVPServerName",GamePrecedure:getInstance():getServerNameById(tonumber(sId))) .. tab.name
            end
        end
    end]]
    if tab:HasField("area") and not Golb_Platform_Info.is_gNetop_platform then
        chatMessage.voiceInfo[6] = tab.area
    end

    if tab:HasField("titleId") then
        chatMessage.voiceInfo[7] = tonumber(tab.titleId) 
    end

    if tab:HasField("playerType") then
        chatMessage.voiceInfo[8] = tonumber(tab.playerType) 
    end
	if tab:HasField("i18nTag") then
		chatMessage.voiceInfo["i18"] = tonumber(tab.i18nTag)
	end
    VoiceChatManager.insertTable( common:deepCopy(chatMessage) ,chatType)

    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "MainScenePage" then
        local MainScenePage = require("MainScenePage")
        MainScenePage:setChat(chatMessage)
        VoiceChatManager.clearChatMessage()
    end
end

function VoiceChatManager.insertTable( tab , chatType)
    if chatType == nil then
        chatType = VoiceChatManager.currChatType
    end
    if chatType == Const_pb.CHAT_ALLIANCE then
	    --if #VoiceChatManager.guildChatMessageList >= 40 then
		--    table.remove( VoiceChatManager.guildChatMessageList , 1 )
	    --end
        table.insert( VoiceChatManager.guildChatMessageList , tab )
    elseif chatType == Const_pb.CHAT_CROSS_PVP then
        --if #VoiceChatManager.worldChatMessageList >= 30 then
		--    table.remove( VoiceChatManager.worldChatMessageList , 1 )
	    --end
        table.insert( VoiceChatManager.crossChatMessageList , tab )
    else
        table.insert( VoiceChatManager.worldChatMessageList , tab )
    end
end

function  VoiceChatManager.getChatName( playerInfo )
	local htmlLabelStr = ""
	local tmpName = playerInfo[2] or ""
	local tmpTitle = ""
	local tmpTitleColor = ""
	if playerInfo[7]~=nil and tonumber(playerInfo[7]) > 0 then
		tmpTitleColor = GameConfig.titleColor[titleManager:getTitleTypeById(tonumber(playerInfo[7]))]
		tmpTitle = "[" .. titleManager:getTitleStrById(tonumber(playerInfo[7])) .. "]"
	end
	local tmpArea = ""
	if playerInfo[6] ~= "" then
		tmpArea = "(" .. playerInfo[6] .. ")"
	end
	if playerInfo[1] ~= GameConfig.SystemId then	--非系统发言
		htmlLabelStr = common:fillHtmlStr("VoiceChatMan",
		 tostring(tmpName),tostring(tmpTitle),tostring(tmpArea),tostring(tmpTitleColor))
	else	--系统发言
		tmpTitle = ""
		tmpArea = ""
		htmlLabelStr = common:fillHtmlStr("VoiceChatWoman",
		 tostring(tmpName),tostring(tmpTitle),tostring(tmpArea),tostring(tmpTitleColor))
	end
	return htmlLabelStr
end
function VoiceChatManager.getIsOneFace(str , sex)
	local isOneFace = false
	local relaPath = nil
	local ret = string.format("%s" , str)
	if string.find(ret , GameConfig.VoiceChat.faceSign) ~= nil then
		local f = string.sub( ret , string.find(ret , GameConfig.VoiceChat.faceSign) )
		relaPath = GameConfig.ChatBigFace[tonumber(string.sub(f,string.find(f , "%d+")))]
		if relaPath ~= nil then
			ret = string.gsub( ret , f, "")
			if ret == "" then
				isOneFace = true
			end
		end
	end
	return isOneFace,relaPath
end

function VoiceChatManager.handlerChatFace(str , sex)
	local tempPic =  FreeTypeConfig[700].content
	local ret = string.format("%s" , str)
	local tab = {}
	local faceNum = 0
    local facePage = nil
	local isOneFace = false
	while string.find(ret , GameConfig.VoiceChat.faceSign) ~= nil do
		local f = string.sub( ret , string.find(ret , GameConfig.VoiceChat.faceSign) )
		local relaPath = GameConfig.ChatFace[tonumber(string.sub(f,string.find(f , "%d+")))]
		if relaPath ~= nil then
            facePage  = relaPath
		    local picPath = CCFileUtils:sharedFileUtils():fullPathForFilename(relaPath) 
			picPath = string.gsub(tempPic , "#v1#" , picPath)
			ret = string.gsub( ret , f, " "..picPath )
			
			local num = string.sub( f , string.find(f , "%d+") )
			if tonumber(num) > 0 then
				--faceNum = faceNum + 2
				--else
				faceNum = faceNum + 1			
			end
			
		else
			local key = "#v" .. (#tab + 1) .. "#"
			table.insert(tab, f )
			ret = string.gsub(ret , f, key)
		end
	end
	if #tab ~= 0 then
		ret = common:getGsubStr( tab , ret )
	else
	end
	
	return ret,faceNum
end

function VoiceChatManager_resetData()
    VoiceChatManager.guildChatCount = -1
	VoiceChatManager.guildChatMessageList = {}
    VoiceChatManager.worldChatCount = -1
    VoiceChatManager.worldChatMessageList = {}
	VoiceChatManager.crossChatCount = -1
    VoiceChatManager.crossChatMessageList = {}

	VoiceChatManager.worldChatMessageTmpList = {}
	VoiceChatManager.guildChatMessageTmpList = {}
    VoiceChatManager.crossChatMessageTmpList = {}
end

return VoiceChatManager