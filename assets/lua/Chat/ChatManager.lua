local ChatManager = {}

--��Ϣ����list
--msgBoxList
--key is player id, value is structure:
	--[[	
	{
		bool isOffline,
		FriendMsg chatMsg,	limit in 50 msg
		MsgBoxUnit chatUnit,
		bool hasNewMsg 
	}
	message MsgBoxUnit
{
	required int32  playerId = 1;
	required string name = 2;
	required int32  level = 3;
	required int32  roleItemId = 4;
}
//��Ϣ�����ṹ
message FriendMsg 
{
	required int32 senderId = 1;
	required int32 receiveId = 2;
	required string senderName = 3;
	required string receiveName = 4;
	required FriendChatMsgType msgType = 5;
	required string message = 6;
}
	--]]
ChatManager.msgBoxList = {}

ChatManager.shieldPlayerList = {}

ChatManager.curChatPerson = {}

ChatManager.closedPrivateChat = {} --�رյ�˽�ĶԻ����ݴ������ﱣ��

ChatManager.hasNewPrivateChatComing = false--个人新的消息红点提示
ChatManager.isChangePlayerNameFlag = false;--判断当前玩家是否更改名字
ChatManager.chatPrivatePersonList = {}--保存个人的聊天记录和顺序
--[[--
--****************特别提醒*****************
--1、因为所有的聊天记录都是保存在本地的，所有不同服务器之间的聊天记录都要用
--服务器的ID来标识，自己所在的每个服务器的聊天记录都是不一样的,否则可能会拿到其他服本地的聊天记录
--2、合服以后需要清除本地的所有聊天记录和文件，因为合服以后每个人的playId都可能会变
--3、同时考虑到转账号以后，PUID变了，自己的playId没变
--AUTHOR: Astor
--CREATED:2018.09.12
--******************************************
--]]--
ChatManager.allFriendChatRecordIdList = {}--所有好的聊天列表ID
ChatManager.isReadyChatRecordFlag = false--读取本地聊天记录
ChatManager.lastChatTime = 0;
--保存每次当前选中的这个人ID 和 之前的排序顺序
ChatManager.selectPlayerInfo = {
    id = 0,
    index = 0
}
--playerId is the unique key 
--chatUnit is the player info 
--chatMsg is the detailed chat msg
--isOffline is distinguish for the offline msg and online msg

--use case 1, add into msg box only, no msg and offline is true,used in recieve offline msg box info
--ChatManager.insertPrivateMsg(playerid,chatUnit,nil,true)

--use case 2, add into msg box only, no msg and offline is false, used in ViewPlayerInfoPage
--ChatManager.insertPrivateMsg(playerid,chatUnit,nil,false)

--use case 3, add unit and msg into msg box , used in recieve push msg online
--ChatManager.insertPrivateMsg(playerid,chatUnit,chatMsg,false)

--use case 4, send msglistinfo_c, got the HPMsgListInfo, add into msgBoxList withOut charUnit
--ChatManager.insertPrivateMsg(playerid,nil,chatMsg,false)

--use case 5, send one private, manually add into msgBoxList withOut charUnit
--ChatManager.insertPrivateMsg(ChatManager.curChatPerson.chatUnit.playerId,nil,friendMsg,false,false)

local function checkIdentify(key)
    if type(key) == "string" then
        local temp1 = common:split(key,"#")
        if temp1[2] then
            local temp2 = common:split(temp1[2],"*")
            local sId = temp2[1] or -1
            local pId = tonumber(temp2[2]) or -1
            local UserInfo = require("PlayerInfo.UserInfo")
            if tonumber(sId) == tonumber(UserInfo.serverId) and pId > 0 then
                return pId
            end
        end
    end
    return key
end

function ChatManager.getMsgBoxSize()
        local size = 0
        if ChatManager.msgBoxList ~= nil then
            size = common:table_count(ChatManager.msgBoxList)
        end
        return size
end

--获取是否有跨服ID
function ChatManager.getIdentifyIdAndPlayerId(uniquePlayerId)
    if ChatManager.msgBoxList[uniquePlayerId] == nil  then return end
    local info = ChatManager.msgBoxList[uniquePlayerId]
    return info.chatUnit.playerId,info.chatUnit.senderIdentify
end
--获取是否有聊天记录
function ChatManager.getChatRecordListFlag(uniquePlayerId)
    ChatManager.getChatPrivatePersonRecordContent(uniquePlayerId)
    if ChatManager.msgBoxList[uniquePlayerId] then
        if ChatManager.msgBoxList[uniquePlayerId].msgList and #ChatManager.msgBoxList[uniquePlayerId].msgList > 0 then
            return true--已经有聊天记录消息
        end
    end
    return false--没有聊天记录消息
end
--第一次跟玩家聊天弹出提示
function ChatManager.insertNewSystemOriTips(uniquePlayerId,id,name,identifyId)
    local Const_pb = require "Const_pb"
    local FriendMsg = {}
    FriendMsg.senderId = id;
    FriendMsg.receiveId = UserInfo.playerInfo.playerId;
    FriendMsg.senderName = name;
    FriendMsg.senderUniquePlayerId = uniquePlayerId;
    FriendMsg.receiveName = "";
    FriendMsg.msgType = Const_pb.MsgTypeSystemTips;
    FriendMsg.message = common:getLanguageString("@NewPlayerChatOriTips");
    FriendMsg.senderIdentify = identifyId;
    FriendMsg.msTime = GVGCrossManager.curServerTimeStamp;
    return FriendMsg
end

--删除只能删除第一个
function ChatManager.updatePersonalRecordListId(id)
   --保存当前选中的ID
    local index = nil
    for i, v in pairs(ChatManager.chatPrivatePersonList) do
        if v == id then
            index = i
            break
        end
    end
    if index ~= nil then
        table.remove(ChatManager.chatPrivatePersonList, index)--从列表中删除
        --插入之前的
        table.insert(ChatManager.chatPrivatePersonList, ChatManager.selectPlayerInfo.id)
        ChatManager.selectPlayerInfo.id = id--赋值当前选择的ID
    end
    --重新排序
    ChatManager.sortTimePersonalList()
end

--私人聊天列表排序,每个人的唯一ID,插入
function ChatManager.insertSortChatPrivate(puid,newMsgFlag)
    if puid == ChatManager.selectPlayerInfo.id then
        return
    end
    if ChatManager.selectPlayerInfo.id == 0 then--如果没有，放在第一个
        ChatManager.selectPlayerInfo.id = puid
        return true
    end
    local find = 0
    for i,v in ipairs(ChatManager.chatPrivatePersonList) do
        if v == puid then
            find = i
            break
        end
    end
    if newMsgFlag then--新消息过来
        if find == 0 then
            if #ChatManager.chatPrivatePersonList >= GameConfig.MsgBoxMaxSize then
                table.remove(ChatManager.chatPrivatePersonList)--默认移除最后一个
            end
            table.insert(ChatManager.chatPrivatePersonList,puid)
            --重新排序
            ChatManager.sortTimePersonalList()
            return true
        end
    elseif ChatManager.selectPlayerInfo.id and ChatManager.selectPlayerInfo.id ~= 0 then
        if ChatManager.selectPlayerInfo.id == puid then
            return
        else
            if find ~= 0 then
                --先保存之前的
                --删除，放在第一个去了
                table.remove(ChatManager.chatPrivatePersonList,find)
            end
            if #ChatManager.chatPrivatePersonList >= GameConfig.MsgBoxMaxSize then
                table.remove(ChatManager.chatPrivatePersonList)--默认移除最后一个
            end
            table.insert(ChatManager.chatPrivatePersonList,ChatManager.selectPlayerInfo.id)
            ChatManager.selectPlayerInfo.id = puid--更新
            --重新排序
            ChatManager.sortTimePersonalList()
        end
    else--赋值给当前第一个
        ChatManager.selectPlayerInfo.id = puid
    end
    return false
end
--删除第一个
function ChatManager.deletePersonalRecordListId()
    ChatManager.curChatPerson = {}
    ChatManager.selectPlayerInfo.id = 0
    ChatManager.selectPlayerInfo.index = 0
    if #ChatManager.chatPrivatePersonList > 0 then
        ChatManager.selectPlayerInfo.id = ChatManager.chatPrivatePersonList[1]
        ChatManager.selectPlayerInfo.index = 1
        table.remove(ChatManager.chatPrivatePersonList, 1)
    end
end

function ChatManager.getPersonalInfo(puid)
    ChatManager.getChatPrivatePersonRecordContent(puid)
    if ChatManager.msgBoxList[puid] then
        return ChatManager.msgBoxList[puid]
    end
    return nil
end

function ChatManager.closedChat(playerId)
        local t = { }
        for i, v in pairs(ChatManager.msgBoxList) do
            if v.chatUnit.playerId == playerId then
                if ChatManager.closedPrivateChat[playerId] == nil then
                    ChatManager.closedPrivateChat[playerId] = v
                end
            else
                t[v.chatUnit.playerId] = v
            end
        end

        ChatManager.msgBoxList = t

        ChatManager.curChatPerson = nil
         for i, v in pairs(ChatManager.msgBoxList) do
            ChatManager.curChatPerson = v
            break
        end

end

function ChatManager.getClosedChat(playerId)
    return ChatManager.closedPrivateChat[playerId]
end

function ChatManager.removeCloseChat(playerId)
        local t = { }
        for i, v in pairs(ChatManager.closedPrivateChat) do
            if v.chatUnit.playerId ~= playerId then
                t[v.chatUnit.playerId] = v
            end
        end

        ChatManager.msgBclosedPrivateChatoxList = t
end

function ChatManager.insertPrivateMsg(playerId,chatUnit,chatMsg,isOffline,hasNewMsg)

    --私聊聊天记录修改
    if isSaveChatHistory then
        ChatManager.getChatPrivatePersonListRecord()--离线消息先过来
        hasNewMsg = hasNewMsg == nil and true or false
        if chatUnit and chatUnit:HasField("headIcon") then
            ChatManager.updatePersonalHeadIcon(playerId,chatUnit.headId)
        end
        if chatUnit and chatUnit:HasField("avatarId") then
            ChatManager.updatePersonalHeadIcon(playerId,nil,chatUnit.avatarId)
        end
        --add by lyj 15-3-23 增加内容是否需要国际化的判断
        if chatMsg ~= nil and chatMsg.jsonType ~= nil and chatMsg.jsonType == 1 then
            chatMsg.message = common:getI18nChatMsg(chatMsg.message)
            chatMsg.jsonType = 0
        end

        --[[	if ChatManager.isInShield(playerId) then
                return
            end--]]
        ChatManager.updateAllChatRecordListId(playerId)
        local maxSize = GameConfig.ChatMsgMaxSize;
        ChatManager.getChatPrivatePersonRecordContent(playerId)
        if ChatManager.msgBoxList[playerId] == nil then
            --if is nil
            if chatUnit==nil then
                CCLuaLog("Error in ChatManager.insertPrivateMsg chatUnit == nil")
                return
            end
            local value = {}
            value.uniquePlayerId = playerId
            value.newMsgSaveFlag = true
            value.chatTime = common:getServerTimeByUpdate()
            value.chatUnit = chatUnit
            value.msgList = {}
            if isOffline then
                value.isOffline = isOffline
            end
            value.hasNewMsg = hasNewMsg
            if chatMsg ~= nil then
                table.insert(value.msgList,chatMsg);
            end

            ChatManager.msgBoxList[playerId] = value
        else
            --if has data in it, judge currentSize is exceed limit
            local value = ChatManager.msgBoxList[playerId]
            if isOffline then
                value.isOffline = isOffline
            end
            value.uniquePlayerId = playerId
            value.newMsgSaveFlag = true
            if value.chatUnit == nil  then
                CCLuaLog("Error in ChatManager.insertPrivateMsg, value.chatUnit == nil or playerId ~= value.chatUnit.playerId")
                return
            end
            if chatUnit then
                value.chatUnit = chatUnit
            end
            value.hasNewMsg = hasNewMsg
            value.chatTime = common:getServerTimeByUpdate()
            if chatMsg ~= nil then
                ChatManager.updatePlayerLocalInfo(value,chatMsg)
                if #value.msgList > maxSize then
                    table.remove(value.msgList,1)
                end
                table.insert(value.msgList,chatMsg);
            end
        end
        ChatManager.saveAllPrivatePersonChatRecord()
        return
    end

    -----------------------------
    local chatPersonSize = GameConfig.MsgBoxMaxSize
    local currentBoxSize = common:table_count(ChatManager.msgBoxList)
    if currentBoxSize > chatPersonSize then
        table.remove(ChatManager.msgBoxList, 1)
    end		
	
    hasNewMsg = hasNewMsg == nil and true or false
    local key = playerId
    
    if chatUnit and chatUnit.senderIdentify and chatUnit.senderIdentify ~= "" then
        key = chatUnit.senderIdentify
    end

    key = checkIdentify(key)
    if type(key) == "number" then
        if chatUnit then
            chatUnit.senderIdentify = ""
        end
    end
	
    --add  增加内容是否需要国际化的判断
    if chatMsg ~= nil and chatMsg.jsonType ~= nil and chatMsg.jsonType == 1 then
        chatMsg.message = common:getI18nChatMsg(chatMsg.message)
        chatMsg.jsonType = 0
    end

    --[[	if ChatManager.isInShield(playerId) then
			    return
		    end--]]
    local maxSize = GameConfig.ChatMsgMaxSize

    if ChatManager.msgBoxList[key] == nil and ChatManager.getClosedChat(key) == nil then
            --���������Ѿ��رյ����춼û��  
            --��һ���µĶԻ�
            local value = { }
            if chatUnit == nil then
                CCLuaLog("Error in ChatManager.insertPrivateMsg chatUnit == nil")
                return
            end
            value.chatUnit = chatUnit
            value.msgList = { }
            value.isOffline = isOffline
            value.hasNewMsg = hasNewMsg
            if chatMsg ~= nil then
                table.insert(value.msgList, chatMsg);
            end

            ChatManager.msgBoxList[key] = value
       
    elseif ChatManager.msgBoxList[key] == nil and ChatManager.getClosedChat(key) then
           --�������û�У� �Ѿ��رյ�������
           --������������Ϣ�ϲ���Ȼ��ӹر�������ɾ��
            local value = ChatManager.closedPrivateChat[key]
            value.isOffline = isOffline

            value.hasNewMsg = hasNewMsg
            if chatMsg ~= nil then
                if #value.msgList > maxSize then
                    table.remove(value.msgList, 1)
                end
                table.insert(value.msgList, chatMsg);
            end
            ChatManager.msgBoxList[key] = value
            ChatManager.removeCloseChat(key)
    else
        local value = ChatManager.msgBoxList[key]
        value.isOffline = isOffline
        if value.chatUnit == nil then
            CCLuaLog("Error in ChatManager.insertPrivateMsg, value.chatUnit == nil or playerId ~= value.chatUnit.playerId")
            return
        end
        value.hasNewMsg = hasNewMsg
        if chatMsg ~= nil then
            if #value.msgList > maxSize then
                table.remove(value.msgList, 1)
            end
            table.insert(value.msgList, chatMsg);
        end
    end
	
end	

function ChatManager.getMsgBoxSize()
	local currentBoxSize = common:table_count(ChatManager.msgBoxList)
	return currentBoxSize
end

function ChatManager.getCurrentChatId()
    --私聊聊天记录修改
    if isSaveChatHistory then
        if ChatManager.curChatPerson then
            return ChatManager.curChatPerson.uniquePlayerId
        end
        return nil
    end
	local playerId = ChatManager.curChatPerson.chatUnit == nil and 0 or ChatManager.curChatPerson.chatUnit.playerId
    local senderIdentify = ChatManager.curChatPerson.chatUnit == nil and 0 or ChatManager.curChatPerson.chatUnit.senderIdentify
    if senderIdentify and senderIdentify ~= "" then
        return senderIdentify
    else
	    return playerId
    end
end
----跨服私聊时传入identify
function ChatManager.setCurrentChatPerson(playerId)
    --playerId = checkIdentify(playerId)
	local msgBox = ChatManager.msgBoxList[playerId]
	if msgBox~=nil then
		ChatManager.curChatPerson = msgBox
	else
		CCLuaLog("ERROR in setCurrentChatPerson playerId"..playerId)
	end
end

---------offline related---------------

function ChatManager.isOfflineMsg(playerId)
    playerId = checkIdentify(playerId)
	local msgBox = ChatManager.msgBoxList[playerId]
	if msgBox~=nil then
		local flag = false
		if msgBox.isOffline == nil then
			flag = false
		else 
			flag = msgBox.isOffline
		end
		return flag
	else
		return false
	end
end

---------new msg related---------------

function ChatManager.readMsg(playerId)
    --私聊聊天记录修改
    if isSaveChatHistory then
        local msgBox = ChatManager.msgBoxList[playerId]
        if msgBox~=nil and msgBox.hasNewMsg then
            msgBox.hasNewMsg = false
            msgBox.newMsgSaveFlag = true--有改变，重新保存
            ChatManager.saveAllPrivatePersonChatRecord()
        end
        return
    end
    playerId = checkIdentify(playerId)
	local msgBox = ChatManager.msgBoxList[playerId]
	if msgBox~=nil then
		msgBox.hasNewMsg = false
	end
end

function ChatManager.hasNewMsgInBoxById(playerId)
    playerId = checkIdentify(playerId)
	local msgBox = ChatManager.msgBoxList[playerId]
	if msgBox~=nil and msgBox.hasNewMsg ~=nil then
		local currentPlayerId = ChatManager.curChatPerson.chatUnit == nil and 0 or ChatManager.curChatPerson.chatUnit.playerId
		if playerId ~= currentPlayerId and msgBox.hasNewMsg == true then
			return true
		else
			return false
		end			
	else
		return false
	end
end

function ChatManager.hasNewMsgInBox()
    --私聊聊天记录修改
    if isSaveChatHistory then
        if ChatManager.msgBoxList == nil  then return false end
        for k,v in pairs(ChatManager.msgBoxList) do
            if v.hasNewMsg == true  then
                return true,v.uniquePlayerId
            end
        end
        return false,0
    end
	if ChatManager.msgBoxList == nil  then return false end
	for k,v in pairs(ChatManager.msgBoxList) do		
		local currentPlayerId = ChatManager.curChatPerson.chatUnit == nil and 0 or ChatManager.curChatPerson.chatUnit.playerId
        local currentIdentify = ChatManager.curChatPerson.chatUnit == nil and 0 or ChatManager.curChatPerson.chatUnit.senderIdentify
		local id = v.chatUnit.playerId 
        local identify = v.chatUnit.senderIdentify
        if v.hasNewMsg == true  then
            if identify ~= currentIdentify then
                if identify ~= "" then
                    return true,id,identify
                else
                    return true,id
                end
            end
            
		    if id ~= currentPlayerId then
			    return true,id
		    end
        end
	end	
	return false,0
end

function ChatManager.hasNewMsgWithoutCur()
	if ChatManager.msgBoxList == nil  then return false end
	for k,v in pairs(ChatManager.msgBoxList) do			
		if v.hasNewMsg == true then
			return true
		end
	end	
	return false
end


---------shield related---------------

function ChatManager.addShieldList(playerId)
	ChatManager.shieldPlayerList[playerId] = true
end

function ChatManager.removeShieldList(playerId)
	ChatManager.shieldPlayerList[playerId] = false
end

function ChatManager.recieveShieldList(list)
	ChatManager.shieldPlayerList = {}
	if #list <=0 then
		return 
	end
	for i=1,#list do
		local playerId = list[i]
		ChatManager.shieldPlayerList[playerId] = true
	end				
end

function ChatManager.isInShield(playerId)
	
	if playerId == nil then return false end
	if ChatManager.shieldPlayerList == nil or common:table_count(ChatManager.shieldPlayerList) == 0 then return false end
	if ChatManager.shieldPlayerList[playerId] ~=nil then
		if ChatManager.shieldPlayerList[playerId] ==true then
			return true
		else
			return false
		end
	else
		return false
	end
end

--保存聊天文件路径
function ChatManager.getChatWritablePath()
    local path = ""
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
        path = CCFileUtils:sharedFileUtils():getWritablePath().."version/"
    elseif CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_ANDROID then
        --local version = common:getGameVersion()
--[[        if version > 44 then--版本问题
            path = CCFileUtils:sharedFileUtils():getWritablePath().."/assets/lua/Chat/"
        else
            path = CCFileUtils:sharedFileUtils():getWritablePath().."/assets/lua/Chat/"
        end]]
        path = CCFileUtils:sharedFileUtils():getWritablePath().."/assets/lua/Chat/"
    else
        path = CCFileUtils:sharedFileUtils():getWritablePath().."/lua/Chat/"
    end
    CCLuaLog("path_____"..path)
    return path
end

--获取个人的聊天记录人物列表
function ChatManager.getChatPrivatePersonListRecord()
    if ChatManager.isReadyChatRecordFlag then
        return--如果已经读取过了，以缓存为准
    end
    local path = ChatManager.getChatWritablePath().."SaveChatRecordIdList.lua"
    CCLuaLog("SaveChatRecordIdList***Path"..path)
    if not CCFileUtils:sharedFileUtils():isFileExist(path) then--文件不存在返回
        return--分开写的好处是如果前面已经不满足，那么不需要读取这个路径
    end
    local isHave,err = loadfile(path)
    if not isHave or type(isHave) ~= "function" then
        ChatManager.sendChatRecordFilesErrLog(err,path)
        ChatManager.removeOneByOneChatRecordFiles("SaveChatRecordIdList.lua")
        return
    end
    ChatManager.isReadyChatRecordFlag = true
    ChatManager.getAllChatRecordListId()--获取所有的聊天记录
    local SaveChatRecord = ChatManager.checkLuaTable(isHave)
    local puid = libPlatformManager:getPlatform():loginUin()
    UserInfo.syncPlayerInfo()
    local getChatPrivatePersonList = "getChatPlayerIdList"..UserInfo.playerInfo.playerId
    ChatManager.chatPrivatePersonList = {}
    ChatManager.selectPlayerInfo.id = 0
    local tab = {}--去掉重复的值
    if SaveChatRecord and type(SaveChatRecord) == "table"  then
        if SaveChatRecord[getChatPrivatePersonList] and type(SaveChatRecord[getChatPrivatePersonList]) == "table" then
            for k,v in pairs (SaveChatRecord[getChatPrivatePersonList]) do
                ChatManager.getChatPrivatePersonRecordContent(v)
                if ChatManager.getPersonalInfo(v) then--聊天记录不存在了
                    if ChatManager.selectPlayerInfo.id == 0 then
                        ChatManager.selectPlayerInfo.id = v
                        ChatManager.selectPlayerInfo.index = 1
                    elseif ChatManager.selectPlayerInfo.id ~= v then--之后的与选中的都不一样
                        if tab[v] == nil then--筛选出重复的
                            tab[v] = v
                            table.insert(ChatManager.chatPrivatePersonList,v)
                        end
                    end
                end
            end
        else--没有聊天列表记录
        end
    else
        ChatManager.removeOneByOneChatRecordFiles("SaveChatRecordIdList.lua")
    end
end

--删除单个人的聊天记录文件
function ChatManager.removeOneByOneChatRecordFiles(luaName)
    local path = ChatManager.getChatWritablePath()
    path = path..luaName
    local rm_file = os.remove(path);
end


function ChatManager.sendChatRecordFilesErrLog(err,fileName)
    -- local file,errInfo = io.open(fileName, "r")
    if true then--file,暂时去掉文件读取内容上传，不支持
        if not err then
            err = ""
        end
        -- local content = file:read("*a")handlerChatFace
        --上传删除的聊天记录文件到log服务器
        local puid = CCUserDefault:sharedUserDefault():getStringForKey("JapanPuid");
        local severId = GamePrecedure:getInstance():getServerID()
        local info = "severId = "..severId.." puid = "..puid.." playerId = "..UserInfo.playerInfo.playerId
        local debugStr = info.." errInfo:"..err--" errorChatRecordFileContent:" .. tostring(content)
        --common:sendMessageG2P_CUSTOM_LOGEVENT(25,debugStr);
    end
end

--删除所有的聊天记录文件
function ChatManager.removeAllChatRecordFiles(  value,filename, name )
    local luaName
    for k,v in pairs(ChatManager.allFriendChatRecordIdList) do
        luaName = "ChatRecord"..v..".lua"
        ChatManager.removeOneByOneChatRecordFiles(luaName)
    end
end
--获取所有聊天过的人物ID
function ChatManager.getAllChatRecordListId()
    local path = ChatManager.getChatWritablePath().."AllChatRecordListIdFiles.lua"
    if CCFileUtils:sharedFileUtils():isFileExist(path) then
        local isHave,err = loadfile(path)
        if not isHave then
            ChatManager.sendChatRecordFilesErrLog(err,path)
            ChatManager.removeOneByOneChatRecordFiles("AllChatRecordListIdFiles.lua")
            return
        end
        if type(isHave) == "function" then
            local ChatRecordListIdFiles = ChatManager.checkLuaTable(isHave)
            if ChatRecordListIdFiles and type(ChatRecordListIdFiles) == "table" then
                ChatManager.allFriendChatRecordIdList = ChatRecordListIdFiles
            else
                ChatManager.removeOneByOneChatRecordFiles("AllChatRecordListIdFiles.lua")
            end
        else
            ChatManager.allFriendChatRecordIdList = {}
        end
    end
end


--更新头像
function ChatManager.updatePersonalHeadIcon(uniquePlayerId,headId,avatarId)
    local a =  ChatManager.msgBoxList[uniquePlayerId]
--[[    if ChatManager.msgBoxList[uniquePlayerId] == nil then
        if headId then
            if VoiceChatManager.playerId2HeadIcon[uniquePlayerId] ~= nil and
                    VoiceChatManager.playerId2HeadIcon[uniquePlayerId] ~= headId then
                PageManager.refreshPage("ChatPage", "headIconChange")
            end
            VoiceChatManager.playerId2HeadIcon[uniquePlayerId] = headId
        end

        if avatarId then
            if VoiceChatManager.playerId2AvatarId[uniquePlayerId] ~= nil and
                    VoiceChatManager.playerId2AvatarId[uniquePlayerId] ~= avatarId then
                PageManager.refreshPage("ChatPage", "headIconChange")
            end
            VoiceChatManager.playerId2AvatarId[uniquePlayerId] = avatarId
        end
    else
        if headId then
            if (VoiceChatManager.playerId2HeadIcon[uniquePlayerId] ~= nil and
                    VoiceChatManager.playerId2HeadIcon[uniquePlayerId] ~= headId) or
                    ChatManager.msgBoxList[uniquePlayerId].chatUnit.headId ~= headId then
                PageManager.refreshPage("ChatPage", "headIconChange")
            end
            VoiceChatManager.playerId2HeadIcon[uniquePlayerId] = headId
            ChatManager.msgBoxList[uniquePlayerId].chatUnit.headId = headId
        end
        if avatarId then
            if (VoiceChatManager.playerId2AvatarId[uniquePlayerId] ~= nil and
                    VoiceChatManager.playerId2AvatarId[uniquePlayerId] ~= avatarId) or
                    ChatManager.msgBoxList[uniquePlayerId].chatUnit.avatarId ~= avatarId then
                PageManager.refreshPage("ChatPage", "headIconChange")
            end
            VoiceChatManager.playerId2AvatarId[uniquePlayerId] = avatarId
            ChatManager.msgBoxList[uniquePlayerId].chatUnit.avatarId = avatarId
        end
    end]]
end
--按聊天的最近时间排序
function ChatManager.sortTimePersonalList()
    table.sort(ChatManager.chatPrivatePersonList,function ( a,b )
        if not ChatManager.msgBoxList[a] or not ChatManager.msgBoxList[b] then
            return false
        elseif ChatManager.msgBoxList[a].chatTime == ChatManager.msgBoxList[b].chatTime then
            return false
        end
        return ChatManager.msgBoxList[a].chatTime > ChatManager.msgBoxList[b].chatTime
    end);
end

--保存所有聊天过的人物ID
function ChatManager.updateAllChatRecordListId(id)
    UserInfo.syncPlayerInfo()
    ChatManager.allFriendChatRecordIdList["id_"..UserInfo.playerInfo.playerId..id]= UserInfo.playerInfo.playerId..id
end

--[[--获取单个人的聊天记录人物列表
--每个人的唯一ID
--]]--
function ChatManager.getChatPrivatePersonRecordContent(id)
    if ChatManager.msgBoxList[id] ~= nil or not id then
        return--已经有了 读取缓存中的
    end
    local luaName = "ChatRecord"..UserInfo.playerInfo.playerId..id..".lua"
    local path = ChatManager.getChatWritablePath()..luaName
    if not CCFileUtils:sharedFileUtils():isFileExist(path) then
        return--没有于这个玩家的聊天记录
    end
    local isHave,err = loadfile(path)
    if not isHave or type(isHave) ~= "function" then
        ChatManager.sendChatRecordFilesErrLog(err,path)
        ChatManager.removeOneByOneChatRecordFiles(luaName)
        return
    end
    local ChatRecordValue = ChatManager.checkLuaTable(isHave)
    if ChatRecordValue and type(ChatRecordValue) == "table" and ChatRecordValue.msgList then--文件内容正确
        ChatManager.msgBoxList[id] = ChatRecordValue
        --每次上线以后更新一下自己的playerId，因为合服以后可能会变
        for i,v in ipairs(ChatManager.msgBoxList[id].msgList) do
            if v.senderId == UserInfo.playerInfo.playerId then--玩家自己的消息
                v.senderId = UserInfo.playerInfo.playerId
            end
        end
    else--文件不对删除，不知道什么原因有时候LUA文件会写坏
        ChatManager.removeOneByOneChatRecordFiles(luaName)
    end
end

function ChatManager.checkLuaTable(isHave)
    local result = nil
    xpcall(function()
        result = isHave()
    end,function ( err )
        local puid = CCUserDefault:sharedUserDefault():getStringForKey("JapanPuid");
        local severId = GamePrecedure:getInstance():getServerID()
        local info = "severId = "..severId.." puid = "..puid
        local debugStr = info.." checkLuaTable ERROR: " .. tostring(err) .. "\n" .. debug.traceback()
        --common:sendMessageG2P_CUSTOM_LOGEVENT(25,debugStr);
    end)
    return result
end
--更新本地保存的ID和名字
function ChatManager.updatePlayerLocalInfo(value,chatMsg)
    if chatMsg.senderId == UserInfo.playerInfo.playerId then
        return--自己发的消息不用更新
    end
    for i,v in ipairs(value.msgList) do--每次都要更新之前的数据，不知道什么时候对面就更名或更其他
        if v.senderId == UserInfo.playerInfo.playerId then--玩家自己的消息
            v.senderId = UserInfo.playerInfo.playerId
        else
            if v.senderName ~= tostring(chatMsg.senderName) or
                    v.receiveName ~= chatMsg.receiveName then--一般情况正在私聊的时候对方突然改名，需要重新刷新
                ChatManager.isChangePlayerNameFlag = true
            end
            v.headIcon = chatMsg.headIcon;
            v.senderId = chatMsg.senderId;
            v.receiveId = chatMsg.receiveId;
            v.senderName = tostring(chatMsg.senderName);
            v.receiveName = chatMsg.receiveName;
        end
    end
end

--[[
--保存个人与所有人的私聊记录--
--每个人的对话最多条数，GameConfig.ChatMsgMaxSize
--列表好友的条数限制，GameConfig.MsgBoxMaxSize
--个人的所有聊天记录都不删除
--]]--
function ChatManager.saveAllPrivatePersonChatRecord()
    -- local ActivityFunc = require("ActivityFunction")
    --[[
    --保存单个人所有的聊天记录----------
    --这样保存的好处是不需要读取所有人的聊天记录，需要谁读取谁的
    --有利于减少缓存和计算量
    --]]--
    local puid = libPlatformManager:getPlatform():loginUin()
    local serverid = GamePrecedure:getInstance():getServerID()
    for k,v in pairs(ChatManager.msgBoxList) do
        if v ~= nil and v.newMsgSaveFlag then--有值并且是没有保存过的信息保存
            --需要加上自己的PUID来做唯一标识，
            --有转账号的时候,两个账号都跟同一个人聊过就有问题
            v.newMsgSaveFlag = false
            local value = {}
            value.uniquePlayerId = v.uniquePlayerId
            value.newMsgSaveFlag = v.newMsgSaveFlag
            value.chatTime = v.chatTime
            value.chatUnit = {}
            value.msgList = {}
            value.chatUnit.playerId = v.chatUnit.playerId;
            value.chatUnit.name = tostring(v.chatUnit.name);
            value.chatUnit.level = v.chatUnit.level;
            value.chatUnit.roleItemId = v.chatUnit.roleItemId;
            --写了这么多，是因为PROTOBUF有很多乱七八糟的数据--
            if v.chatUnit.rebirthStage then--主角avatar ID
                value.chatUnit.rebirthStage = v.chatUnit.rebirthStage;
            end
            if v.chatUnit.avatarId then--
                value.chatUnit.avatarId = v.chatUnit.avatarId;
            end
            if v.chatUnit.cspvpRank then--跨服PVP排名
                value.chatUnit.cspvpRank = v.chatUnit.cspvpRank;
            end
            if v.chatUnit.cspvpScore then--跨服PVP积分
                value.chatUnit.cspvpScore = v.chatUnit.cspvpScore;
            end
            if v.chatUnit.senderIdentify then--发送者玩家标识
                value.chatUnit.senderIdentify = v.chatUnit.senderIdentify;
            end
            if v.chatUnit.headIcon then--发送者玩家标识
                value.chatUnit.headIcon = v.chatUnit.headIcon;
            end
            for i,val in ipairs(v.msgList) do
                local FriendMsg = {}
                FriendMsg.senderId = val.senderId;
                FriendMsg.receiveId = val.receiveId;
                FriendMsg.senderName = tostring(val.senderName);
                FriendMsg.receiveName = val.receiveName;
                FriendMsg.msgType = val.msgType;
                FriendMsg.message = val.message;
                ---FriendMsg.senderUniquePlayerId = val.senderUniquePlayerId;
                if val.area then
                    FriendMsg.area = val.area;
                end
                if val.titleId then
                    FriendMsg.titleId = val.titleId;
                end
                if val.jsonType then
                    FriendMsg.jsonType = val.jsonType;
                end
                if val.msTime then
                    FriendMsg.msTime = val.msTime;
                end
                if val.skinId then
                    FriendMsg.skinId = val.skinId;--聊天框皮肤Id
                end
                if val.senderIdentify then--发送者玩家标识
                    FriendMsg.senderIdentify = val.senderIdentify;
                end
                if val.headIcon then
                    FriendMsg.headIcon = val.headIcon;--聊天框皮肤Id
                end
                table.insert(value.msgList,FriendMsg);
            end
                ------------------------------------------------------------
                value.isOffline = v.isOffline
                value.hasNewMsg = v.hasNewMsg
            ChatManager.saveAllChatRecordFiles(value,k)
        end
        -- CCUserDefault:sharedUserDefault():setStringForKey(onlyId, ChatContent);
    end
    ---------------------------------------
    local chatRecord = {}
    local chatRecordListName = "SaveChatRecordIdList.lua"
    local path = ChatManager.getChatWritablePath()..chatRecordListName
    ----保存个人的聊天记录人物列表，有顺序---------
    if CCFileUtils:sharedFileUtils():isFileExist(path) then--文件存在
        local isHave,err = loadfile(path)
        if isHave and type(isHave) == "function" then
            local SaveChatRecord = ChatManager.checkLuaTable(isHave)
            if SaveChatRecord and type(SaveChatRecord) == "table" then
                chatRecord = SaveChatRecord
            end
        else
            ChatManager.sendChatRecordFilesErrLog(err,path)
            ChatManager.removeOneByOneChatRecordFiles("SaveChatRecordIdList.lua")
        end
    end
    local getChatPrivatePersonList = "getChatPlayerIdList"..UserInfo.playerInfo.playerId
    chatRecord[getChatPrivatePersonList] = ChatManager.saveTimePersonalIdList()
    ChatManager.save(chatRecord,path,"SaveChatRecordIdList")
    ChatManager.saveAllChatRecordListId()
end
--修改细线消息状态
function ChatManager.setOfflineMsgFlag(uniquePlayerId,flag)
    if uniquePlayerId and ChatManager.msgBoxList[uniquePlayerId] then
        ChatManager.msgBoxList[uniquePlayerId].isOffline = flag
    end
end

--保存所有的聊天记录文件
function ChatManager.saveAllChatRecordFiles(value,id)
    local luaName = "ChatRecord"..UserInfo.playerInfo.playerId..id..".lua"
    local path = ChatManager.getChatWritablePath()
    path = path..luaName
    ChatManager.save(value,path,"GetAllChatRecordFiles")
end
--保存所有聊天过的人物ID
function ChatManager.saveAllChatRecordListId()
    local path = ChatManager.getChatWritablePath()
    path = path.."AllChatRecordListIdFiles.lua"
    local allFilesName = {}
    local name = ""
    for k,v in pairs(ChatManager.allFriendChatRecordIdList) do
        name = "[\""..k.."\"]"
        allFilesName[name] = v
    end
    ChatManager.save(allFilesName,path,"AllChatRecordListIdFiles")
end

--// The Save Function
function ChatManager.save(  value,filename, name )
    local file,err = io.open( filename, "wb" )
    if err then return err end
    local nesting = 10
    local lookupTable = {}
    local result = {}
    local function _v(v)
        if type(v) == "string" then
            v = string.gsub(v,"%[","<")
            v = string.gsub(v,"%]",">")
            v = "a([[" .. v .. "]])"
        end
        return tostring(v)
    end
    local function _k(v)
        if type(v) == "number" then
            v = "[" .. v .. "]"
        end
        return tostring(v)
    end
    local function _dump(value, desciption, indent, nest, isLast,ipairsFlag)
        desciption = desciption or "<var>"
        if type(value) ~= "table" then
            result[#result +1 ] = string.format(isLast and "%s=%s" or "%s=%s,",_k(desciption), _v(value))
        elseif lookupTable[value] then
            result[#result +1 ] = string.format("%s=*REF*",desciption)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s=*MAX NESTING*", desciption)
            else
                result[#result +1 ] = string.format("%s={", _k(desciption))
                local keys = {}
                local values = {}
                if ipairsFlag then
                    for k, v in ipairs(value) do
                        keys[#keys + 1] = k
                        local vk = _v(k)
                        values[k] = v
                    end
                else
                    for k, v in pairs(value) do
                        keys[#keys + 1] = k
                        local vk = _v(k)
                        values[k] = v
                    end
                end
                for i, k in ipairs(keys) do
                    if k == "msgList" then--聊天记录按顺序来
                        _dump(values[k], k, indent, nest + 1, i == #keys,true)
                    elseif name == "SaveChatRecordIdList" then--个人聊天记录，按顺序保存
                        _dump(values[k], k, indent, nest + 1, i == #keys,true)
                    else
                        _dump(values[k], k, indent, nest + 1, i == #keys,false)
                    end
                end
                if nest == 1 then
                    result[#result +1] = "}\n"
                elseif nest == 2 then
                    result[#result +1] = "},\n"
                else
                    if isLast then
                        result[#result +1] = "}"
                    else
                        result[#result +1] = "},"
                    end
                end
            end
        end
    end
    _dump(value, name, "", 1)

    ----------转换字符-------
    file:write('local function a(str) ')
    file:write('str = string.gsub(str,"%<","[") ')
    file:write('str = string.gsub(str,"%>","]") ')
    file:write('return str ')
    file:write('end \n')
    -------------------------

    result[1] = "local " .. name .. " = {\n"
    for i, line in ipairs(result) do
        file:write(line)
    end
    file:write("return "..name)
    file:close()
end

--根据最后的聊天信息时间来保存信息
function ChatManager.saveTimePersonalIdList()
    local list = {}
    if ChatManager.selectPlayerInfo.id ~= 0 then
        table.insert(list,ChatManager.selectPlayerInfo.id)
    end
    for i=1,#ChatManager.chatPrivatePersonList do
        table.insert(list,ChatManager.chatPrivatePersonList[i])
    end
    table.sort(list,function ( a,b )--按时间重新排序
        if not ChatManager.msgBoxList[a] or not ChatManager.msgBoxList[b] then
            return false
        elseif ChatManager.msgBoxList[a].chatTime == ChatManager.msgBoxList[b].chatTime then
            return false
        end
        return ChatManager.msgBoxList[a].chatTime > ChatManager.msgBoxList[b].chatTime
    end);
    return list
end

--每次进入界面重置时间顺序
function ChatManager.resetChatRecordList()
    if not ChatManager.isReadyChatRecordFlag then
        --如果第一次进入聊天记录，不需要重置,读取本地为准
        return
    end
    --缓存以后重新进入界面都需要重新根据聊天时间排序
    local list = {}
    local find = false
    for i=1,#ChatManager.chatPrivatePersonList do
        if ChatManager.selectPlayerInfo.id == ChatManager.chatPrivatePersonList[i] then
            find = true
        end
        table.insert(list,ChatManager.chatPrivatePersonList[i])
    end
    --如果没有找到，并且有值
    if not find and ChatManager.selectPlayerInfo.id ~= 0 then
        table.insert(list,ChatManager.selectPlayerInfo.id)
    end
    table.sort(list,function ( a,b )--按时间重新排序
        if not ChatManager.msgBoxList[a] or not ChatManager.msgBoxList[b] then
            return false
        elseif ChatManager.msgBoxList[a].chatTime == ChatManager.msgBoxList[b].chatTime then
            return false
        end
        return ChatManager.msgBoxList[a].chatTime > ChatManager.msgBoxList[b].chatTime
    end);
    ChatManager.chatPrivatePersonList = {}
    --重置个人聊天列表
    for i,v in ipairs(list) do
        if i == 1 then
            ChatManager.selectPlayerInfo.id = v
        else
            table.insert(ChatManager.chatPrivatePersonList,v)
        end
    end
    if ChatManager.selectPlayerInfo.id ~= 0 then
        ChatManager.setCurrentChatPerson(ChatManager.selectPlayerInfo.id)
    end
end

---从右侧遍历字符串，取指定字符的前后字符串
-- @param strurl  待解取字符串；
--        strchar 指定字符串；
--        bafter= true 取指定字符后字符串
-- @return 截取后的字符串
-- end --
function ChatManager.getUrlFileName( strurl, strchar, bafter)
    local ts = string.reverse(strurl)
    local param1, param2 = string.find(ts, strchar)  -- 这里以"/"为例
    if not param1 then return "" end
    local m = string.len(strurl) - param2 + 1
    local result
    if (bafter == true) then
        result = string.sub(strurl, m+1, string.len(strurl))
    else
        result = string.sub(strurl, 1, m)
    end
    return result
end

-- 判断是否在同一个跨服务或者同一个服务器 add by DuanGuangxiang 2018 09 10
function ChatManager.isSameServer(playerId)
    local tmp = common:split(playerId, "#")
    local serverId;
    if #tmp == 2 then
        local serverIdAndPlayerID = common:split(tmp[2], "*");
        serverId = tonumber(serverIdAndPlayerID[1])
    else
        return true;
    end

    local csCfg = ConfigManager.getOSPVPServerCfg();
    for k, v in pairs(csCfg) do
        if common:table_hasValue(v.servers, UserInfo.serverId) and common:table_hasValue(v.servers, serverId) then
            return true;
        end
    end

    return false;
end
function ChatManager.refreshMainNewChatPointTips()
    NodeHelper:mainFrameSetPointVisible(
            {
                mChatPoint = ((ChatManager.hasNewMsgWithoutCur() == true) or (hasNewMemberChatComing == true and AllianceOpen) or hasNewChatSkin == true or hasNewWorldChatComing == true),
            }
    )
end

function ChatManager_reset()
	--ChatManager.shieldPlayerList = {}
	--ChatManager.msgBoxList = {}
	--ChatManager.curChatPerson = {}
end
--[[
function ChatManager_little_reset()
    ChatManager.shieldPlayerList = {}
	ChatManager.msgBoxList = {}
	ChatManager.curChatPerson = {}
end
]]--
return ChatManager;