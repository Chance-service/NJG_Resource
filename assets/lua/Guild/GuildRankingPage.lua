
----------------------------------------------------------------------------------
require 'common'

local alliance = require('Alliance_pb')
local hp = require('HP_pb')
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local GuildDataManager = require("Guild.GuildDataManager")
local GuildRankManage = require('GuildRankManage')

local thisPageName = 'GuildRankingPage'
local GuildRankingBase = {}

local option = {
	ccbiFile = "GuildRankingContentNew.ccbi",
}

function GuildRankingBase:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end

function GuildRankingBase:onEnter(container)

    local rankInfo = GuildRankManage.getRankInfo()
    selfContainer = ScriptContentBase:create(rankInfo._ccbi)


    local _labelLevelName = selfContainer:getVarLabelBMFont("mLevelShow")
    local _labelFightName = selfContainer:getVarLabelBMFont("mFightShow")
    _labelLevelName:setVisible(true)
    _labelFightName:setVisible(false)


	self:registerPackets(container)
	NodeHelper:initScrollView(selfContainer, 'mContent', 10)
	self:refreshPage(selfContainer)
    GuildDataManager:requestRankingList(container)

    return selfContainer
end

function GuildRankingBase:onExit(container)
	self:removePackets(container)
	NodeHelper:deleteScrollView(container)
end

function GuildRankingBase:refreshPage(container)
	self:rebuildAllItem(container)
end

function GuildRankingBase:onClose(container)
	PageManager.popPage(thisPageName)
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
	local info = GuildData.rankingList[index]
    --local info = GuildData.rankingFightingList[index]
    
	if not info then return end
	local lb2Str = {
		mRanking 		= index,
		mID 			= info.id,
		--mGuildLv 		= common:getLanguageString('@LevelDesc', info.level),
        mGuildLv 		= info.level,
		mGuildName 		= info.name,
		mLeadersName 	= info.handName,
	}
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setNodesVisible(container,{mRankingNum1 = false,mRankingNum2 = false,mRankingNum3 = false,
		mRankingNum4 = false,mRanking = false})
	if index > 3 then
		NodeHelper:setNodesVisible(container,{mRankingNum4 = true ,mRanking = true})
	else
		NodeHelper:setNodesVisible(container,{[string.format("mRankingNum%d",index)] = true,mRanking = false})
	end
end	

----------------scrollview-------------------------
function GuildRankingBase:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function GuildRankingBase:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end

function GuildRankingBase:buildItem(container)
	NodeHelper:buildScrollView(container, #GuildData.rankingList, RankListItem.ccbiFile, RankListItem.onFunction);
    --NodeHelper:buildScrollView(container, #GuildData.rankingFightingList, RankListItem.ccbiFile, RankListItem.onFunction);
end


 ------------------ packet function -----------------------------------
function GuildRankingBase:registerPackets(container)
	container:registerPacket(hp.ALLIANCE_RANKING_S)
end

function GuildRankingBase:removePackets(container)
	container:removePacket(hp.ALLIANCE_RANKING_S)
end

function GuildRankingBase:onReceiveRankingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankInfo(msg.rankings)
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankInfo({})
	end
end

--接收服务器回包
function GuildRankingBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	
	if opcode == hp.ALLIANCE_RANKING_S then
		-- alliance enter
		local msg = alliance.HPAllianceRankingS()
		msg:ParseFromString(msgBuff)
		self:onReceiveRankingList(container, msg)
        if GuildRankManage.subPage then
		    GuildRankManage.subPage:refreshPage(container)
        end
		return
	end

end

--接收战力排行榜数据 存储
function GuildRankingBase:onReceiveRankingFightingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankFightingInfo(msg.rankings)
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankFightingInfo({})
	end
end

return  GuildRankingBase
--local CommonPage = require('CommonPage')
--local GuildRankingPage = CommonPage.newSub(GuildRankingBase, thisPageName, option)
