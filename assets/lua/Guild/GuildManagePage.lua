----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
registerScriptPage('GuildSetAnnouncementPage')
registerScriptPage('GuildSetRestrictionPage')

local alliance = require('Alliance_pb')
local Status_pb = require("Status_pb")
local GuildSetAnnouncementBase = require('GuildSetAnnouncementPage')
local hp = require('HP_pb')
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local thisPageName = 'GuildManagePage'
local GuildManageBase = {}

local option = {
	ccbiFile = "GuildAdministrationPopUp.ccbi",
	handlerMap = {
		onClose 		= 'onClose',
	}
}

-- 会长、副会长、普通成员
local PositionType = {
	Leader = 2,
	ViceLeader = 1,
	Normal = 0,
}

local manageItems = {
	{
		-- 设置战力限制
		itemType = 1,
	},

	{
		-- 设置公告
		itemType = 2,
	},
}

if Golb_Platform_Info.is_gNetop_platform then 
	manageItems[3] = {itemType = 3}-- 公会BOSS自动解禁时间
	manageItems[4] = {itemType = 4}-- 发邮件
end

function GuildManageBase:onEnter(container)
	self:registerPackets(container)
	NodeHelper:initScrollView(container, 'mContent', 3)
	--container.mScrollView:setTouchEnabled(false)
	NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString('@GuildManageTitle', joinLimit) })
	self:refreshPage(container)
end

function GuildManageBase:onExit(container)
	self:removePackets(container)
	NodeHelper:deleteScrollView(container)
end

function GuildManageBase:refreshPage(container)
	-- scrollview
	if manageItems then
		self:rebuildAllItem(container)
	end
end
----------------scrollview item-------------------------
local ManageItem = {
	ccbiFile = 'GuildAdministrationContent.ccbi'
}

function ManageItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		ManageItem.onRefreshItemView(container)
	elseif eventName == "onSetUp" then
		ManageItem.setJoinCondition(container)
	elseif eventName == "onEdit" then
		ManageItem.setAnnouncement(container)
	elseif eventName == "onMailEdit" then 
		ManageItem.sendMail(container)	
	elseif eventName == "onBossEdit" then
		ManageItem.BossEdit(container)	
	end
end

function ManageItem.onRefreshItemView(container)
	local index = container:getItemDate().mID
	local info = manageItems[index]
	if not info then return end
	
	if 1 == info.itemType then
		-- set condition
		NodeHelper:setNodeVisible(container:getVarNode('mGuildConditionsNode'), true)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildAnnouncementNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildMailNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildBoss'), false)	
		local joinLimit = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.battleLimit or 0
		local check = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.hasCheckButton or 0
		local limitStr = ""
		if check == 0 then
			limitStr = common:getLanguageString('@GuildJoinCondition', joinLimit)
		else
			limitStr = common:getLanguageString('@GuildJoinCondition', joinLimit) .. "\n" .. common:getLanguageString('@GildMailLimit')
		   NodeHelper:setNodeScale(container,"mConditionsExplain",0.8,0.8)
        end
		NodeHelper:setStringForLabel(container, { mConditionsExplain = limitStr })
	elseif 2 == info.itemType then
		-- set announcement
		NodeHelper:setNodeVisible(container:getVarNode('mGuildConditionsNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildAnnouncementNode'), true)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildMailNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildBoss'), false)	

        local announcement = common:getLanguageString('@Desc_100000')

        if GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.annoucement ~= "" then
             announcement = GuildData.allianceInfo.commonInfo.annoucement
        end
		
		--local announcement = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.annoucement and common:getLanguageString('@Desc_100000')
        
        
        -- 如果公告太长，取前15个字
		--local length = GameMaths:calculateStringCharacters(announcement)
		--if length > 13 then
			--announcement = GameMaths:getStringSubCharacters(announcement, 0, 20)
			--announcement = GameMaths:stringAutoReturnForLua(announcement, 15, 0)
		--end
		--NodeHelper:setStringForLabel(container, { mAnnouncementExplain = announcement })
		local length = GameMaths:calculateStringCharacters(announcement)
		local onLineMaxCount = 21
		local strSize = 20
		if length > 40 then
			strSize = 15
			onLineMaxCount = 28
		end

		local str = "<font color=\"#815509\" face = \"HelveticaBD20\" >" .. announcement .. "</font>"
		local labelNode = container:getVarLabelTTF("mAnnouncementExplain")
		local str =GameMaths:stringAutoReturnForLua(announcement, onLineMaxCount, 0)
		if labelNode then
			labelNode:setFontSize(strSize)
			labelNode:setString(str)
			--NodeHelper:setCCHTMLLabelAutoFixPosition(labelNode, CCSize(425,25),str )
			--labelNode:setVisible(false)
		end
	elseif 3 == info.itemType then
		NodeHelper:setNodeVisible(container:getVarNode('mGuildConditionsNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildAnnouncementNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildMailNode'), false)		
		NodeHelper:setNodeVisible(container:getVarNode('mGuildBoss'), true)	
		local openTimeList = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.openTimeList or {}
		local str = ""
		if #openTimeList  == 0 then
			str = common:getLanguageString("@GuildBossDefault")
		else	--"9:30 10:00 12:00"
			for k,v in ipairs(openTimeList) do
				str = str .. v
				if v ~= "" and k ~= #openTimeList then
					str = str .. "、"
				end
			end
		end
		if str == "" then str = common:getLanguageString("@GuildBossDefault") end
		NodeHelper:setStringForLabel(container,{mBossInfoExplain = str})
	elseif 4 == info.itemType then
		NodeHelper:setNodeVisible(container:getVarNode('mGuildConditionsNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildAnnouncementNode'), false)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildMailNode'), true)
		NodeHelper:setNodeVisible(container:getVarNode('mGuildBoss'), false)	
	else
		-- nothing
	end
end	

function ManageItem.setJoinCondition(container)
	-- not the leader
	if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.postion ~= PositionType.Leader then
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
		return 
	end
	
	GuildSetRestrictionCallback = function (newBattlePoint,checkButton)
		local msg = alliance.HPAllianceJoinSetC()
		msg.battlePoint = newBattlePoint
		msg.checkButton = checkButton
		local pb = msg:SerializeToString()
		PacketManager:getInstance():sendPakcet(hp.ALLIANCE_JOINSET_C, pb, #pb, false)
	end
	PageManager.pushPage('GuildSetRestrictionPage')
end

function ManageItem.setAnnouncement(container)
	-- not the leader
	if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.postion ~= PositionType.Leader then
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
		return 
	end
	if Golb_Platform_Info.is_gNetop_platform then
		local index = container:getItemDate().mID
		local itemType = manageItems[index].itemType
		local announcement = GuildData.allianceInfo.commonInfo and GuildData.allianceInfo.commonInfo.annoucement or ''
		GuildSetAnnouncementBase:setItemType(itemType,announcement)
	end
	GuildSetAnnouncementCallback = function (newAnnouncement)
		local msg = alliance.HPAllianceNoticeC()
		msg.notice = newAnnouncement
		local pb = msg:SerializeToString()
		PacketManager:getInstance():sendPakcet(hp.ALLIANCE_NOTICE_C, pb, #pb, false)
	end
	PageManager.pushPage('GuildSetAnnouncementPage')
end

function ManageItem.sendMail(container)
	-- not the leader
	if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.postion ~= PositionType.Leader then
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
		return 
	end
	local index = container:getItemDate().mID
	local itemType = manageItems[index].itemType
	GuildSetAnnouncementBase:setItemType(itemType)
	GuildSetMailCallback = function (emailContent)
		local msg = alliance.HPAllianceEmailC()
		msg.emailContent = emailContent
		local pb = msg:SerializeToString()
		PacketManager:getInstance():sendPakcet(hp.ALLIANCE_MAIL_C, pb, #pb, false)
	end
	PageManager.pushPage('GuildSetAnnouncementPage')
end

function ManageItem.BossEdit(container)
	if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.postion ~= PositionType.Leader then
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
		return 
	end
	PageManager.pushPage('GuildSetBossTimePage')
end
----------------scrollview-------------------------
function GuildManageBase:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function GuildManageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function GuildManageBase:buildItem(container)
	NodeHelper:buildScrollView(container, #manageItems, ManageItem.ccbiFile, ManageItem.onFunction);
end

---------------------------- packet function ------------------------------------
function GuildManageBase:registerPackets(container)
	container:registerPacket(hp.ALLIANCE_CREATE_S)
	if Golb_Platform_Info.is_gNetop_platform then
		container:registerPacket(hp.ALLIANCE_MAIL_S)
	end
end

function GuildManageBase:removePackets(container)
	container:removePacket(hp.ALLIANCE_CREATE_S)
	if Golb_Platform_Info.is_gNetop_platform then
		container:removePacket(hp.ALLIANCE_MAIL_S)
	end
end

function GuildManageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == hp.ALLIANCE_CREATE_S then
		local msg = alliance.HPAllianceInfoS()
		msg:ParseFromString(msgBuff)
		GuildData.allianceInfo.commonInfo = msg
		self:refreshPage(container)

        if UserInfo.hasAlliance ~= nil and not UserInfo.hasAlliance  then
           PageManager.showComment()   --评价提示
        end
		return
	elseif  opcode == hp.ALLIANCE_MAIL_S then
		local msg = alliance.HPAllianceEmailS()
		msg:ParseFromString(msgBuff)
		local resultNum = tonumber(msg.emailSendResult)
		if resultNum == Status_pb.MAIL_NOT_FOUND then 
			MessageBoxPage:Msg_Box("@MailNotFound")
		elseif resultNum == Status_pb.MAIL_CANNOT_READ then 
			MessageBoxPage:Msg_Box("@MailNotRead")
		elseif resultNum == Status_pb.MAIL_SEND_SUCCESS then 
			MessageBoxPage:Msg_Box("@MailSuccess")
		end
	end
end

function GuildManageBase:onClose(container)
	PageManager.popPage(thisPageName)
end

local CommonPage = require('CommonPage')
local GuildManagePage = CommonPage.newSub(GuildManageBase, thisPageName, option)
