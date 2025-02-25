--[[
  查看其他玩家信息
]]

local Const_pb = require("Const_pb");
local HP_pb = require("HP_pb");
local Snapshot_pb = require("Snapshot_pb");
local Friend_pb = require("Friend_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
------------local variable for system api--------------------------------------
local titleManager = require("PlayerInfo.TitleManager")
local GameConfig   = require("GameConfig")
local FetterManager = require("FetterManager")
local OSPVPManager = require("OSPVPManager")
-------------------------------------------
local thisPageName = "ViewPlayMenuPage"
local thisPlayerId = 0;
local thisPlayerName = ""
local playerInfo = {};
local thisFlagShowButton = false
local isKakaoFriend = false

----这里是协议的id
local opcodes = {
    FRIEND_ADD_S = HP_pb.FRIEND_ADD_S,
    FRIEND_DELETE_S = HP_pb.FRIEND_DELETE_S,
    MESSAGE_CANCEL_SHIELD_S = HP_pb.MESSAGE_CANCEL_SHIELD_S,
    MESSAGE_SHIELD_S = HP_pb.MESSAGE_SHIELD_S
};

local option = {
    ccbiFile = "EquipmentLookOverOtherPopUp.ccbi",
    handlerMap = { --按钮点击事件
        onClose     = "onClose",
        onBtn1		= "lookPlayerInfo", --查看其它玩家
        onBtn2      = "onSendMessage",
        onBtn3      = "onShieldMessage",
        onBtn4      = "onAddFriend",
    },
    opcode = opcodes
}

local ViewPlayMenuPageBase = {}
function ViewPlayMenuPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:showFunctionButtonInfo(container)
    if not ViewPlayerInfo:getIsCs() then
        FetterManager.clear()
        FetterManager.reqFetterInfo(ViewPlayerInfo:getPlayerInfo().playerId)
    end

    NodeHelper:setMenuItemEnabled(container,"mBtn3",not ViewPlayerInfo:getIsCs())
    NodeHelper:setMenuItemEnabled(container,"mBtn4",not ViewPlayerInfo:getIsCs())
    NodeHelper:setMenuItemEnabled(container,"mBtn5",not ViewPlayerInfo:getIsCs())
    --OSPVPManager.reqLocalPlayerInfo({ViewPlayerInfo:getPlayerInfo().playerId})

    local itemInfo = ViewPlayerInfo:getRoleInfo();
    if itemInfo.cspvpRank and itemInfo.cspvpRank > 0 then
        local stage = OSPVPManager.checkStage(itemInfo.cspvpScore, itemInfo.cspvpRank)
        --NodeHelper:setNormalImages(container, {mHand = stage.stageIcon})
    else
       -- NodeHelper:setNormalImages(container, {mHand = GameConfig.QualityImage[1]})
    end


    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mBtnNode1 = false , mBtnNode2 = false ,mBtnNode3 = false ,mBtnNode4 = false ,mBtnNode5 = false })
    end
end

function ViewPlayMenuPageBase:onExecute(container)

end

function ViewPlayMenuPageBase:onExit(container)
    self:removePacket(container)
end

function ViewPlayMenuPageBase:onClose(container)
    PageManager.popPage(thisPageName)
    --PageManager.changePage("MainScenePage") 
    --PageManager.pushPage("PlayerInfoPage")
end

function ViewPlayMenuPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == FetterManager.moduleName then
            if extraParam == FetterManager.onFetterInfo then
                local cur,total = FetterManager.getIllCollectRate()
                NodeHelper:setStringForLabel(container,{
                    mFetterNum = common:getLanguageString("@FetterOtherNumTxt") .. string.format("%d/%d",cur,total)
                })
            end
        elseif pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                
            end
        end
	end
end

function ViewPlayMenuPageBase:onReceivePacket(container)
        local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    if opcode == opcodes.FRIEND_ADD_S then
        ViewPlayerInfo:setIsFriend(true)
        MessageBoxPage:Msg_Box("@AddFriendSuccess")
        self:showFunctionButtonInfo(container)
        PageManager.refreshPage("FriendPage");
    end
    
    if opcode == opcodes.FRIEND_DELETE_S then
        ViewPlayerInfo:setIsFriend(false)
        --MessageBoxPage:Msg_Box("@DelFriendSuccess")
        self:showFunctionButtonInfo(container)
        PageManager.refreshPage("FriendPage");
    end
    
    if opcode == opcodes.MESSAGE_SHIELD_S then
        ViewPlayerInfo:setIsShield(true)
        MessageBoxPage:Msg_Box("@SheMsgSuccess")
        self:showFunctionButtonInfo(container)
        local ChatManager = require("Chat.ChatManager")
        ChatManager.addShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
    end
    
    if opcode == opcodes.MESSAGE_CANCEL_SHIELD_S then
        ViewPlayerInfo:setIsShield(false)
        MessageBoxPage:Msg_Box("@UnSheMsgSuccess")
        self:showFunctionButtonInfo(container)
        local ChatManager = require("Chat.ChatManager")
        ChatManager.removeShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
    end    
end

--function ViewPlayMenuPageBase:onReceiveMessage(container)
--    local opcode = container:getRecPacketOpcode()
--    local msgBuff = container:getRecPacketBuffer()

--    if opcode == opcodes.FRIEND_ADD_S then
--        ViewPlayerInfo:setIsFriend(true)
--        MessageBoxPage:Msg_Box("@AddFriendSuccess")
--        self:showFunctionButtonInfo(container)
--        PageManager.refreshPage("FriendPage");
--    end

--    if opcode == opcodes.FRIEND_DELETE_S then
--        ViewPlayerInfo:setIsFriend(false)
--        MessageBoxPage:Msg_Box("@DelFriendSuccess")
--        self:showFunctionButtonInfo(container)
--        PageManager.refreshPage("FriendPage");
--    end

--    if opcode == opcodes.MESSAGE_SHIELD_S then
--        ViewPlayerInfo:setIsShield(true)
--        MessageBoxPage:Msg_Box("@SheMsgSuccess")
--        self:showFunctionButtonInfo(container)
--        local ChatManager = require("Chat.ChatManager")
--        ChatManager.addShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
--    end

--    if opcode == opcodes.MESSAGE_CANCEL_SHIELD_S then
--        ViewPlayerInfo:setIsShield(false)
--        MessageBoxPage:Msg_Box("@UnSheMsgSuccess")
--        self:showFunctionButtonInfo(container)
--        local ChatManager = require("Chat.ChatManager")
--        ChatManager.removeShieldList(ViewPlayerInfo:getPlayerInfo().playerId)
--    end
--end

function ViewPlayMenuPageBase:showFunctionButtonInfo(container)
    local lb2Str = {
    mShieldMessage          = ViewPlayerInfo:isShieldLabelStr(),
    mSendMessage                = ViewPlayerInfo:isSendAllowLabelStr(),
    mAddFriend          = ViewPlayerInfo:isFriendLabelStr(),    
    };
    if GameConfig.IsInAppCheck then
        NodeHelper:setNodesVisible(container, { mBtnNode4 = false})
    end

    if GameConfig.isIOSAuditVersion then
         NodeHelper:setNodesVisible(container, { mBtnNode4 = false})
    end

    NodeHelper:setStringForLabel(container, lb2Str);
    local roleInfo = ViewPlayerInfo:getRoleInfo();
    local playerInfo = ViewPlayerInfo:getPlayerInfo()
    local allianceInfo = ViewPlayerInfo:getAllianceInfo();
    if not allianceInfo.allianceName or allianceInfo.allianceName == "" or allianceInfo.allianceName == " " then
        allianceInfo.allianceName =  common:getLanguageString("@NoAlliance")
    end
   
    local roleInfoStr = {mLv = "LV."..roleInfo.level,mArenaName = roleInfo.name,mFightingNum = common:getLanguageString("@Fighting") .. roleInfo.marsterFight ,mGuildName = common:getLanguageString("@GuildLabel") .. allianceInfo.allianceName};
    NodeHelper:setStringForLabel(container, roleInfoStr);
--[[    local roleCfg = ConfigManager.getRoleCfg()
    local showCfg = LeaderAvatarManager.getOthersShowCfg(roleInfo.avatarId)
	local icon = showCfg.icon[roleInfo.prof]
    NodeHelper:setSpriteImage(container, {mPic = icon} , {mPic = 1});]]
    local icon ,bgIcon = common:getPlayeIcon(roleInfo.prof,playerInfo.headIcon)
    NodeHelper:setSpriteImage(container, { mPic = icon ,mFrameShade = bgIcon });
    NodeHelper:setStringForLabel(container, lb2Str);
end

function ViewPlayMenuPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
            container:registerPacket(opcode)
    end
end

function ViewPlayMenuPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

function ViewPlayMenuPageBase:lookPlayerInfo(container)
    --ViewPlayerInfo:getInfo(playerId,playerName);
    PageManager.pushPage("ViewPlayerEquipmentPage");
end

--屏蔽消息
function ViewPlayMenuPageBase:onShieldMessage(container)
    if ViewPlayerInfo.isShield then
        --解除屏蔽 1 屏蔽 2 取消屏蔽
        local msg = Friend_pb.HPMsgShield();
        msg.playerId = ViewPlayerInfo:getPlayerInfo().playerId;
        msg.type = 2
        common:sendPacket(HP_pb.MESSAGE_CANCEL_SHIELD_C, msg);
    else
        --屏蔽
        local msg = Friend_pb.HPMsgShield();
        msg.playerId = ViewPlayerInfo:getPlayerInfo().playerId;
        msg.type = 1
        common:sendPacket(HP_pb.MESSAGE_SHIELD_C, msg);
    end
end

--发送消息
function ViewPlayMenuPageBase:onSendMessage(container)
    if ViewPlayerInfo.isSendAllow then
        if UserInfo.roleInfo.level < 9 then
            MessageBoxPage:Msg_Box_Lan("@NoPrivateChatLevelLimit")
            return
        end
        --跳转到个人聊天页面
        local ChatManager = require("Chat.ChatManager")
        local Friend_pb = require("Friend_pb")
        --add playerinfo into msgbox
        local chatUnit = Friend_pb.MsgBoxUnit()
        --PageManager.changePage("ChatPage")
        resetMenu("mChatBtn",true)
        chatUnit.playerId = ViewPlayerInfo:getPlayerInfo().playerId
        chatUnit.name = ViewPlayerInfo:getRoleInfo().name
        chatUnit.level = ViewPlayerInfo:getRoleInfo().level
        chatUnit.roleItemId = ViewPlayerInfo:getRoleInfo().itemId
        chatUnit.avatarId = ViewPlayerInfo:getRoleInfo().avatarId
        chatUnit.headIcon = ViewPlayerInfo:getPlayerInfo().headIcon
        --私聊聊天记录修改
        if isSaveChatHistory then
            ChatManager.insertSortChatPrivate(chatUnit.playerId)
        end
        if ViewPlayerInfo.isCs and ViewPlayerInfo.csIdentify and ViewPlayerInfo.csIdentify ~= "" then
            chatUnit.senderIdentify = ViewPlayerInfo.csIdentify
            ChatManager.insertPrivateMsg(ViewPlayerInfo.csIdentify,chatUnit,nil, false,false)
            ChatManager.setCurrentChatPerson(ViewPlayerInfo.csIdentify)
        else
            ChatManager.insertPrivateMsg(ViewPlayerInfo:getPlayerInfo().playerId,chatUnit,nil, false,false)
            ChatManager.setCurrentChatPerson(ViewPlayerInfo:getPlayerInfo().playerId)
        end
        if MainFrame:getInstance():getCurShowPageName() == "ChatPage" then
			PageManager.popAllPage()
        else
			-- PageManager.popAllPage()
			BlackBoard:getInstance():delVarible("PrivateChat")
			BlackBoard:getInstance():addVarible("PrivateChat","PrivateChat")
			PageManager.pushPage("ChatPage")
        end
        PageManager.refreshPage("ChatPage","PrivateChat")
    else
        MessageBoxPage:Msg_Box("@PrivateChatLimitInvoke")
    end
end

--添加或删除消息
function ViewPlayMenuPageBase:onAddFriend(container)
    if Golb_Platform_Info.is_entermate_platform and isKakaoFriend then
    
    else
        local targetId = ViewPlayerInfo:getPlayerInfo().playerId;
        local FriendManager = require("FriendManager")
        if ViewPlayerInfo.isFriend then
            FriendManager.deleteById(targetId)
        else
            FriendManager.sendApplyById(targetId)
        end
    end
end

function ViewPlayMenuPageBase_setPlayerId(playerId, flagShowButton,flagKakaoFriend,playerName)
	thisPlayerId = tonumber(playerId)
	if flagShowButton == nil then
		thisFlagShowButton = true
	else
		thisFlagShowButton = flagShowButton
	end
	isKakaoFriend = flagKakaoFriend
	thisPlayerName =tostring( playerName)
end

local CommonPage = require('CommonPage')
local ViewPlayMenuPage= CommonPage.newSub(ViewPlayMenuPageBase, thisPageName, option)