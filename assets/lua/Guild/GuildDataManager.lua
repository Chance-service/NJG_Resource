----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local GuildData = require("Guild.GuildData")
local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local player = require('Player_pb')
local OSPVPManager = require("OSPVPManager")

local GuildDataManager = {}

-- 初始化页面数据
function GuildDataManager:initData()

end

-- 按时间顺序请求公会商店、公会排名、boss排行、成员列表数据
function GuildDataManager:requestData(enterPageTime)
	if enterPageTime > 100 then
		if not GuildData.memberInfoInited  then
			if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.hasAlliance then
				self:getMemberList(GuildData.mainContainer)
                GuildData.memberInfoInited = true
			end
		end
	end

    --等级排行榜
	if enterPageTime > 500 then
		if not GuildData.rankInfoInited then
			self:requestRankingList(GuildData.mainContainer)
			GuildData.rankInfoInited = true
		end
	end

    --战力排行榜
    if enterPageTime > 600 then
		if not GuildData.rankFightingInfoInited then
			self:requestRankingFightingList(GuildData.mainContainer)
			GuildData.rankFightingInfoInited = true
		end
	end


	if enterPageTime > 800 then
		if not GuildData.bossRankInited then
			if GuildData.MyAllianceInfo and GuildData.MyAllianceInfo.hasAlliance and GuildData.allianceInfo.commonInfo
				and GuildData.allianceInfo.commonInfo.bossState ~= GuildData.BossPage.BossNotOpen then
				self:getHarmRank(GuildData.mainContainer)
				GuildData.bossRankInited = true
			end
		end
	end
end

function GuildDataManager:getMemberList(container)
	local msg = alliance.HPAllianceMemberC()
	local pb = msg:SerializeToString()
	container:sendPakcet(hp.ALLIANCE_MEMBER_C, pb, #pb, false)
end

function GuildDataManager:requestRankingList(container)
	local msg = alliance.HPAllianceRankingC()
	local pb = msg:SerializeToString()
    container:sendPakcet(hp.ALLIANCE_RANKING_C, pb, #pb, false)
end

--请求战力排行榜数据
function GuildDataManager:requestRankingFightingList(container)
	local msg = alliance.AllianceScoreRankingC()
	local pb = msg:SerializeToString()
    container:sendPakcet(hp.ALLIANCE_SCORE_RANK_C, pb, #pb, false)
end

function GuildDataManager:getHarmRank(container)
	local msg = alliance.HPAllianceHarmSortC()
	local pb = msg:SerializeToString()
	container:sendPakcet(hp.ALLIANCE_HARMSORT_C, pb, #pb, false)
end

function GuildDataManager:requestBasicInfo()
	local msg = alliance.HPAllianceEnterC()
	local pb = msg:SerializeToString()
	GuildData.mainContainer:sendPakcet(hp.ALLIANCE_ENTER_C, pb, #pb, true)
end

--------------------------------- 主页操作 ---------------------------------------
-- 重置页面数据
function GuildDataManager:resetBossPage()
	GuildData.BossPage.bossBloodLeft = 0
	GuildData.BossPage.bossJoinFlag = false
end

function GuildDataManager:resetGuildPage()
	GuildData.enterPageTime = 0
	GuildData.rankInfoInited = false
    GuildData.rankFightingInfoInited = false
	GuildData.bossRankInited = false
	GuildData.memberInfoInited = false

	GuildData.allianceInfo.commonInfo = nil
	GuildData.allianceInfo.joinList = nil
	GuildData.allianceInfo.allianceState = nil
	GuildData.MyAllianceInfo = {}
	
	GuildData.mainContainer = {}
	GuildData.joinListContainer = {}
	GuildData.allianceContainer = {}
	GuildData.bossContainer = {}
	GuildData.bossHitContainer = {}
end

function GuildDataManager:resetTwoPage()
	self:resetBossPage()
	self:resetGuildPage()
end

-- 通知主页面去掉红点
function GuildDataManager:notifyMainPageRedPoint()
	local message = MsgMainFrameGetNewInfo:new()
	message.type = GameConfig.NewPointType.TYPE_ALLIANCE_NEW_CLOSE
	MessageManager:getInstance():sendMessageForScript(message)
end

-- 加入公会
function GuildDataManager:sendJoinAlliancePacket(id)
	local msg = alliance.HPAllianceOperC()
	msg.operType = GuildData.OperType.JoinAlliance
	msg.targetId = id
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.ALLIANCE_OPER_C, pb, #pb, false)
end
-- 申请加入公会
function GuildDataManager:sendApplyAlliancePacket(id)
	local msg = alliance.HPApplyIntoAllianceC()
	msg.allianceId = id
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.APPLY_INTO_ALLIANCE_C, pb, #pb, false)
end
-- 刷新公会列表
function GuildDataManager:sendRefreshGuildListPacket()
	--add
	if GuildData ~= nil and GuildData.nowRefreshPageNum ~= nil and GuildData.allianceInfo ~= nil and GuildData.allianceInfo.maxPage ~= nil then
		GuildData.nowRefreshPageNum = math.max((GuildData.nowRefreshPageNum+1)%(GuildData.allianceInfo.maxPage+1), 1)
	end
	self:getGuildListPacket()
end

-- 获取公会推荐列表
function GuildDataManager:getGuildListPacket()
	--local msg = alliance.HPAllianceJoinListC()
	--msg.reqPage = GuildData.nowRefreshPageNum
	--common:sendPacket(hp.ALLIANCE_JOIN_LIST_C, msg)
    common:sendEmptyPacket(hp.ALLIANCE_JOIN_LIST_C, false)
end

function GuildDataManager:onReceiveJoinList(msg)
	if msg.showTag then
		GuildData.allianceInfo.joinList = msg.rankings
		GuildData.allianceInfo.curPage = msg.curPage or 1
		GuildData.allianceInfo.maxPage = msg.maxPage or 1
		GuildData.allianceInfo.allianceState = msg.allianceState
	else
		MessageBoxPage:Msg_Box('@GuildNoJoinList')
		GuildData.allianceInfo.curPage = 1
		GuildData.allianceInfo.maxPage = 1
		GuildData.allianceInfo.joinList = nil
		GuildData.allianceInfo.allianceState = nil
	end
end

-- 搜索公会
function GuildDataManager:sendSearchGuildPacket(allianceId)
	-- allianceId is a number
	allianceId = allianceId or 0
	local msg = alliance.HPAllianceFindC()
	msg.id = allianceId
	local pb = msg:SerializeToString()
	-- no FIND_S, so set arg-4 to false, don't wait return
	GuildData.mainContainer:sendPakcet(hp.ALLIANCE_FIND_C, pb, #pb, false)
end

-- 公会排名
function GuildDataManager:setRankInfo(rankInfo)
	GuildData.rankingList = rankInfo
end

-- 公会战力排名
function GuildDataManager:setRankFightingInfo(rankFightingInfo)
	GuildData.rankingFightingList = rankFightingInfo
end

-- 公会成员
function GuildDataManager:setGuildMemberList(memberList)
	GuildData.memberList = memberList
	table.sort(GuildData.memberList, function (m1, m2)
		if m1.postion ~= m2.postion then
			return m1.postion+0 > m2.postion+0
		elseif m1.battlePoint ~= m2.battlePoint then
			return m1.battlePoint+0 > m2.battlePoint+0
		end
	end)

    local playerIds = {}
    for i = 1, #memberList do
        table.insert(playerIds, memberList[i].id)
    end
    if #playerIds > 0 then
        OSPVPManager.reqLocalPlayerInfo(playerIds)
    end
end

-- 商店列表
function GuildDataManager:setShopList(shopList)
	GuildData.shopList = shopList
end

-- 伤害排行列表
function GuildDataManager:setHarmRank( harmList )
	GuildData.harmRankList = harmList
end
------------------------------- boss页面操作 --------------------------------------
-- boss页面开启boss
function GuildDataManager:openBoss(container, eventName)
	if not GuildData.allianceInfo.commonInfo then
		MessageBoxPage:Msg_Box('@GuildDataError')
		return
	end

	local bossState = GuildData.allianceInfo.commonInfo.bossState
	if GuildData.BossPage.BossNotOpen == bossState then
		-- check if you are leader 
		if GuildData.MyAllianceInfo.myInfo.postion == GuildData.PositionType.Normal then
			if Golb_Platform_Info.is_r2_platform then
				MessageBoxPage:Msg_Box('@GuildBossWaitToOpen')
			else
				MessageBoxPage:Msg_Box('@GuildOnlyLeaderCanDo')				
			end
			return 
		end
		
		-- pop open boss page
		local message = ''
		local info = GuildData.allianceInfo.commonInfo
		local needGold = 0;

		-- listening this packet in pop page
		-- recover listening in onReceiveMessage
		GuildData.mainContainer:removePacket(hp.ALLIANCE_CREATE_S)
		
		-- give up PageManager.showConfirm because the GUAJI-156 bug
		if info then
			PageManager.pushPage('GuildOpenBossConfirmPage')
		end
	elseif GuildData.BossPage.BossCanJoin == bossState then
		self:doJoinBoss()
	else
		MessageBoxPage:Msg_Box('@GuildDataError')
	end
end

-- 发送加入boss协议
function GuildDataManager:doJoinBoss()
	local msg = alliance.HPAllianceBossFunOpenC()
	msg.operType = GuildData.BossPage.BossOperJoin
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.ALLIANCE_BOSSFUNOPEN_C, pb, #pb, false)
	GuildData.BossPage.bossJoinFlag = true
end

-- 鼓舞
function GuildDataManager:doInspire()
	local msg = alliance.HPAllianceBossFunOpenC()
	msg.operType = GuildData.BossPage.BossOperInspire
	local pb = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(hp.ALLIANCE_BOSSFUNOPEN_C, pb, #pb, false)
end

function GuildDataManager:getBossCfgByBossId(target)
	for k, v in pairs(GuildData.BossPage.bossCfg) do
		if tonumber(v.bossId) == tonumber(target) then
			return v
		end
	end
	return nil
end

function GuildDataManager:createAlliance(guildName)
	local name = tostring(guildName)
	if common:trim(name) == '' then
		MessageBoxPage:Msg_Box('@GuildNameEmpty')
		return
	end

	local msg = alliance.HPAllianceCreateC()
	msg.name = name
	local pb = msg:SerializeToString()
	GuildData.mainContainer:sendPakcet(hp.ALLIANCE_CREATE_C, pb, #pb, true)
end

function GuildDataManager:changeAllianceName(guildName)
	local name = tostring(guildName)
	if common:trim(name) == '' then
		MessageBoxPage:Msg_Box('@GuildNameEmpty')
		return
	end

	local msg = alliance.HPChangeAllianceName()
	msg.newName = name
	local pb = msg:SerializeToString()
	GuildData.mainContainer:sendPakcet(hp.ALLIANCE_CHANGE_NAME_C, pb, #pb, false)
end

-- 签到
function GuildDataManager:onSignIn()
	if GuildData.MyAllianceInfo.myInfo.hasReported then
		MessageBoxPage:Msg_Box('@GuildSignInAlready')
		return
	end
	local msg = alliance.HPAllianceReportC()
	local pb = msg:SerializeToString()
	-- don't wait ALLIANCE_REPORT_S , no this packet.
	GuildData.mainContainer:sendPakcet(hp.ALLIANCE_REPORT_C, pb, #pb, false)
	GuildData.allianceInfo.signInFlag = true
end
-------------------------------------- 消息操作 ----------------------------------
-- 注册，移除消息
function GuildDataManager:registerPackets()
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_CREATE_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_OPER_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_JOIN_LIST_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_ENTER_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_BOSSHARM_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_RANKING_S)
    GuildData.mainContainer:registerPacket(hp.ALLIANCE_SCORE_RANK_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_HARMSORT_S)
	GuildData.mainContainer:registerPacket(hp.ALLIANCE_MEMBER_S)
	GuildData.mainContainer:registerPacket(hp.APPLY_INTO_ALLIANCE_S)
	GuildData.mainContainer:registerPacket(hp.FETCH_WORLD_BOSS_BANNER_S)
	GuildData.mainContainer:registerPacket(hp.FETCH_WORLD_BOSS_INFO_S)
	
	
end

function GuildDataManager:removePackets()
	GuildData.mainContainer:removePacket(hp.ALLIANCE_CREATE_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_OPER_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_JOIN_LIST_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_ENTER_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_BOSSHARM_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_RANKING_S)
    GuildData.mainContainer:removePacket(hp.ALLIANCE_SCORE_RANK_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_HARMSORT_S)
	GuildData.mainContainer:removePacket(hp.ALLIANCE_MEMBER_S)
	GuildData.mainContainer:removePacket(hp.APPLY_INTO_ALLIANCE_S)
	GuildData.mainContainer:removePacket(hp.FETCH_WORLD_BOSS_BANNER_S)
	GuildData.mainContainer:removePacket(hp.FETCH_WORLD_BOSS_INFO_S)
end

function GuildDataManager:removeOnePacket(opcode)
	GuildData.mainContainer:removePacket(opcode)
end

function GuildDataManager:getGuildId()
    if GuildData.allianceInfo==nil 
        or GuildData.allianceInfo.commonInfo == nil 
            or AllianceOpen==false then
            return nil;
    end
    
    return GuildData.allianceInfo.commonInfo.id
end



	
function GuildDataManager:isNormalMember()
	if GuildData.MyAllianceInfo.myInfo and GuildData.MyAllianceInfo.myInfo.postion ~= GuildData.PositionType.Normal then	
		return false
	else
		return true
	end
end	

function GuildDataManager:getGuildMemberSize()
	return GuildData.allianceInfo.commonInfo.currentPop or 0
end



function GuildDataManager:registerMessages()
	GuildData.mainContainer:registerMessage(MSG_MAINFRAME_POPPAGE)
	GuildData.mainContainer:registerMessage(MSG_MAINFRAME_REFRESH)
end

function GuildDataManager:removeMessages()
	GuildData.mainContainer:removeMessage(MSG_MAINFRAME_POPPAGE)
	GuildData.mainContainer:removeMessage(MSG_MAINFRAME_REFRESH)
end

return GuildDataManager