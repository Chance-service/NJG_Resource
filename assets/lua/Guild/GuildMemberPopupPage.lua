----------------------------------------------------------------------------------

----------------------------------------------------------------------------------

local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local thisPageName = 'GuildMemberPopupPage'
local GuildMemberPopBase = {}

local memberInfo = {}

GuildMemberPop = {
	setMemberInfo = function (info)
		memberInfo = info
	end
}

local PositionType = {
	Leader = 2,
	ViceLeader = 1,
	Normal = 0,
}

-- 公会操作
local OperType = {
	ChangeLeader = 1, 				-- 转让公会
	ChangeViceLeader = 2, 			-- 提升为副会长
	JoinAlliance = 3, 				-- 加入公会
	QuitAlliance = 4, 				-- 退出公会
	DemoteViceLeader = 5, 			-- 解除副会长
	KickOut = 6, 					-- 提出公会
}

local option = {
	ccbiFile = "GuildMemberOperation.ccbi",
	handlerMap = {
		onNormalClose 			= 'onClose',
		onClose 				= 'onClose',
		onPromoteClose 			= 'onClose',
		onDemoteClose 			= 'onClose',

		-- demote node
		onViewDetail 			= 'onViewDetail',
		onDemote 				= 'onDemote',
		onPromote 				= 'onPromote',
		onDemoteKick			= 'onKickOut',
		onPromoteKick			= 'onKickOut',
	}
}

function GuildMemberPopBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildMemberPopBase:onEnter(container)
	self:refreshPage(container)
end

function GuildMemberPopBase:onExit(container)
end

function GuildMemberPopBase:refreshPage(container)

	if not memberInfo.postion then
		return
	end
	local myPosition = GuildData.MyAllianceInfo.myInfo.postion
	local hisPosition = memberInfo.postion
	-- i am leader
	if PositionType.Leader == myPosition then
		if hisPosition == PositionType.Leader then
			self:showNormalNode(container)
		elseif hisPosition == PositionType.ViceLeader then
			self:showDemoteNode(container)
		elseif hisPosition == PositionType.Normal then
			self:showPromoteNode(container)
		else
			self:showNormalNode(container)
		end
	elseif PositionType.ViceLeader == myPosition then
		-- i am vice leader
		self:showNormalNode(container)
	elseif PositionType.Normal == myPosition then
		-- i am normal
		self:showNormalNode(container)
	end
--[[	local RoleManager = require("PlayerInfo.RoleManager");
	local icon = RoleManager:getIconById(memberInfo.roleItemId)
	NodeHelper:setSpriteImage(container, {mPic = icon})]]
	local roleConfig = ConfigManager.getRoleCfg()
	local prof =  roleConfig[memberInfo.roleItemId].profession
	local icon,bgIcon = common:getPlayeIcon(prof,memberInfo.headIcon)
	NodeHelper:setSpriteImage(container, {mPic = icon,mFrameShade = bgIcon} , {mPic = 0.84,mFrameShade = 0.84})

	lb2Str = {
		mLv 				= memberInfo.level and memberInfo.level or 0,
		mPosition 			= memberInfo.postion and common:getLanguageString('@GuildPosition' .. tostring(memberInfo.postion)) or '',
		mFightingCapacity   = memberInfo.battlePoint and memberInfo.battlePoint or 0,
		mContribution 		= memberInfo.contribution and memberInfo.contribution or 0,
	}
	NodeHelper:setStringForLabel(container, lb2Str) 

	lb2StrTtf = {
		mName = memberInfo.name and memberInfo.name or ''
	}
	NodeHelper:setStringForTTFLabel(container, lb2StrTtf)

	--add 
	if Golb_Platform_Info.is_r2_platform then
		local mLvTitle = container:getVarLabelBMFont("mLvTitle")
		local mLv = container:getVarLabelBMFont("mLV")
		if mLvTitle ~= nil and mLv ~= nil then
			NodeHelper:setNodeVisible(mLvTitle, false)
			mLv:setPosition(mLvTitle:getPosition())
			local lvl = memberInfo.level and memberInfo.level or 0
			mLv:setString(common:getR2LVL() .. lvl)
		end

		NodeHelper:setStringForLabel(container, {mTitle2 = common:getLanguageString("@Position_r2")})
		NodeHelper:setStringForLabel(container, {mTitle4 = common:getLanguageString("@Contribution_r2")})		
	end
	NodeHelper:setLabelOneByOne(container, "mLvTitle", "mLV", 5, true)
	NodeHelper:setLabelOneByOne(container, "mTitle2", "mPosition")
	NodeHelper:setLabelOneByOne(container, "mTitle3", "mFightingCapacity")
	NodeHelper:setLabelOneByOne(container, "mTitle4", "mContribution")
end

function GuildMemberPopBase:showNormalNode(container)
	NodeHelper:setNodeVisible(container:getVarNode('mNormalNode'), true)
	NodeHelper:setNodeVisible(container:getVarNode('mDemoteNode'), false)
	NodeHelper:setNodeVisible(container:getVarNode('onPromoteNode'), false)
end

function GuildMemberPopBase:showPromoteNode(container)
	NodeHelper:setNodeVisible(container:getVarNode('mNormalNode'), false)
	NodeHelper:setNodeVisible(container:getVarNode('mDemoteNode'), false)
	NodeHelper:setNodeVisible(container:getVarNode('onPromoteNode'), true)
end

function GuildMemberPopBase:showDemoteNode(container)
	NodeHelper:setNodeVisible(container:getVarNode('mNormalNode'), false)
	NodeHelper:setNodeVisible(container:getVarNode('mDemoteNode'), true)
	NodeHelper:setNodeVisible(container:getVarNode('onPromoteNode'), false)
end

-- 提升副会长
function GuildMemberPopBase:onPromote(container)
	if GuildData.MyAllianceInfo.myInfo == nil or memberInfo.id == nil then 
		MessageBoxPage:Msg_Box('@GuildDataError')
		return
	end

	local myPosition = GuildData.MyAllianceInfo.myInfo.postion
	if myPosition == PositionType.Leader then
		self:doOperation(container, OperType.ChangeViceLeader, memberInfo.id,memberInfo.name)
	else
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
	end
end

-- 解除副会长
function GuildMemberPopBase:onDemote(container)
	if GuildData.MyAllianceInfo.myInfo == nil or memberInfo.id == nil then 
		MessageBoxPage:Msg_Box('@GuildDataError')
		return
	end

	local myPosition = GuildData.MyAllianceInfo.myInfo.postion
	if myPosition == PositionType.Leader then
		self:doOperation(container, OperType.DemoteViceLeader, memberInfo.id,memberInfo.name)
	else
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
	end
end

-- 踢出公会
function GuildMemberPopBase:onKickOut(container)
	if GuildData.MyAllianceInfo.myInfo == nil or memberInfo == nil or memberInfo.id == nil or memberInfo.postion == nil then 
		MessageBoxPage:Msg_Box('@GuildDataError')
		return
	end

	local hisPosition = memberInfo.postion
	local myPosition = GuildData.MyAllianceInfo.myInfo.postion
	if myPosition == PositionType.Leader then
		if PositionType.ViceLeader == hisPosition then
			--self:doGiveOutAlliance(container, OperType.KickOut, memberInfo.id)
			self:doOperation(container, OperType.ChangeLeader, memberInfo.id,memberInfo.name)
		else
			self:doOperation(container, OperType.KickOut, memberInfo.id,memberInfo.name)
		end
	else
		MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')
	end
end

-- 查看人物详情
function GuildMemberPopBase:onViewDetail( container )
	PageManager.viewPlayerInfo(memberInfo.id, true)
	PageManager.popPage(thisPageName)
end

function GuildMemberPopBase:doOperation(container, operType, targetId,targetName)	
	-- 如果是会长踢人则弹窗确认
	if operType == OperType.KickOut then
		local title = common:getLanguageString('@GuildMemberKickOutTitle')
		local kickNeedCost = VaribleManager:getInstance():getSetting("kickNeedCost")
		local message = common:getLanguageString('@GuildMemberKickOutMessage', tostring(kickNeedCost))
		PageManager.showConfirm(title, message,
		   function (agree)
			   if agree then
			    	GuildMemberPopBase.sendKickOut(container, operType, targetId)
			   end
		   end
		)
	elseif operType == OperType.ChangeLeader then
            local title = common:getLanguageString('@ChangeLeaderTitle')
		    local message = common:getLanguageString('@ChangeLeaderTip',targetName)
		    PageManager.showConfirm(title, message,
		       function (agree)
			       if agree then
			    	    GuildMemberPopBase.sendKickOut(container, operType, targetId)
			       end
		       end
		    )
--        if Golb_Platform_Info.is_entermate_platform or Golb_Platform_Info.is_r2_platform then
--            local title = common:getLanguageString('@ChangeLeaderTitle')
--		    local message = common:getLanguageString('@ChangeLeaderTip',targetName)
--		    PageManager.showConfirm(title, message,
--		       function (agree)
--			       if agree then
--			    	    GuildMemberPopBase.sendKickOut(container, operType, targetId)
--			       end
--		       end
--		    )
--         else
--             GuildMemberPopBase.sendKickOut(container, operType, targetId)
--        end
    else
        GuildMemberPopBase.sendKickOut(container, operType, targetId)
	end
end

function GuildMemberPopBase.sendKickOut(container, operType, targetId)
	targetId = targetId or 0
	local msg = alliance.HPAllianceOperC()
	msg.operType = operType
	msg.targetId = targetId
	local pb = msg:SerializeToString()
	container:sendPakcet(hp.ALLIANCE_OPER_C, pb, #pb, false)
	PageManager.popPage(thisPageName)
	-- -- notify refresh members page
	-- local msg = MsgMainFrameRefreshPage:new()
	-- msg.pageName = 'GuildMembersPage'
	-- MessageManager:getInstance():sendMessageForScript(msg)
end

function GuildMemberPopBase:onClose(container)
	PageManager.popPage(thisPageName)
end

local CommonPage = require('CommonPage')
local GuildMemberPopupPage = CommonPage.newSub(GuildMemberPopBase, thisPageName, option)
