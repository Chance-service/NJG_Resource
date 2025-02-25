
----------------------------------------------------------------------------------
require 'common'

local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local GuildDataManager = require("Guild.GuildDataManager")
local GuildRankManage = require('GuildRankManage')

local thisPageName = 'GuildRankingFightPage'
local GuildRankingFightPage = {}

local option = {
	ccbiFile = "GuildRankingContentNew.ccbi",
}

function GuildRankingFightPage:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildRankingFightPage:onEnter(container)

    local rankInfo = GuildRankManage.getRankInfo()
    selfContainer = ScriptContentBase:create(rankInfo._ccbi)

    local _labelLevelName = selfContainer:getVarLabelBMFont("mLevelShow")
    local _labelFightName = selfContainer:getVarLabelBMFont("mFightShow")
    _labelLevelName:setVisible(false)
    _labelFightName:setVisible(true)

	self:registerPackets(container)
	NodeHelper:initScrollView(selfContainer, 'mContent', 10)
	self:refreshPage(selfContainer)
    GuildDataManager:requestRankingFightingList(container)

     
    return selfContainer
end

function GuildRankingFightPage:onExit(container)
	self:removePackets(container)
	NodeHelper:deleteScrollView(container)
end

function GuildRankingFightPage:refreshPage(container)
	self:rebuildAllItem(container)
end

function GuildRankingFightPage:onRankFight(container)
	--PageManager.popPage(thisPageName)
end

----------------scrollview item-------------------------
local RankListItem = {
	ccbiFile = 'GuildRankingContent.ccbi'
}

function RankListItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		RankListItem.onRefreshItemView(container)
	end
end

function RankListItem.onRefreshItemView(container)
	local index = container:getItemDate().mID
	--local info = GuildData.rankingList[index]
    local info = GuildData.rankingFightingList[index]
    
	if not info then return end
	local lb2Str = {
		mRanking 		= index,
		mID 			= info.id,
		mGuildLv 		= info.score,
		mGuildName 		= info.name,
		mLeadersName 	= info.handName,
	}
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setNodesVisible(container,{mRankingNum1 = false,mRankingNum2 = false,mRankingNum3 = false,
		mRankingNum4 = false,mRanking = false})
        --math.mod(index,2) == 1
	if index > 3 then
		NodeHelper:setNodesVisible(container,{mRankingNum4 = true,mRanking = true})
	else
		NodeHelper:setNodesVisible(container,{[string.format("mRankingNum%d",index)] = true,mRanking = false})
	end
end	

----------------scrollview-------------------------
function GuildRankingFightPage:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function GuildRankingFightPage:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function GuildRankingFightPage:buildItem(container)
	--NodeHelper:buildScrollView(container, #GuildData.rankingList, RankListItem.ccbiFile, RankListItem.onFunction);
    NodeHelper:buildScrollView(container, #GuildData.rankingFightingList, RankListItem.ccbiFile, RankListItem.onFunction);
end


 ------------------ packet function -----------------------------------
function GuildRankingFightPage:registerPackets(container)
	container:registerPacket(hp.ALLIANCE_SCORE_RANK_S)
end

function GuildRankingFightPage:removePackets(container)
	container:removePacket(hp.ALLIANCE_SCORE_RANK_S)
end

function GuildRankingFightPage:onReceiveRankingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankFightingInfo(msg.rankings)
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankFightingInfo({})
	end
end

--接收战力排行榜数据 存储
function GuildRankingFightPage:onReceiveRankingFightingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankFightingInfo(msg.rankings)
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankFightingInfo({})
	end
end

--接收服务器回包
function GuildRankingFightPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	

	if opcode == hp.ALLIANCE_SCORE_RANK_S then
		-- alliance enter
		local msg = alliance.AllianceScoreRankingS()
		msg:ParseFromString(msgBuff)
		self:onReceiveRankingFightingList(container, msg)
         if GuildRankManage.subPage then
		    GuildRankManage.subPage:refreshPage(container)
         end
		return
	end

end

return  GuildRankingFightPage
--local CommonPage = require('CommonPage')
--local GuildRankingPage = CommonPage.newSub(GuildRankingBase, thisPageName, option)
