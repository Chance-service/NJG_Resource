----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
require 'common'


local alliance = require('Alliance_pb')
local hp = require("HP_pb")
local NodeHelper = require("NodeHelper")
local GuildData = require("Guild.GuildData")
local GuildDataManager = require("Guild.GuildDataManager")


local thisPageName = "GuildRankManage"
local GuildRankManage = {}



GuildRankManage._rankType = {
    GUILD_FIGHT_RANK = 1,--战力排行
	GUILD_LEVEL_RANK = 2,--等级排行
}

GuildRankManage._curRankType = GuildRankManage._rankType.GUILD_FIGHT_RANK;


GuildRankManage._rankInfo = {
    [GuildRankManage._rankType.GUILD_FIGHT_RANK] = {
        _scriptName = "GuildRankingFightPage",
        _ccbi = "GuildRankingContentNew.ccbi",
    },--战力排行
	[GuildRankManage._rankType.GUILD_LEVEL_RANK] = {
        _scriptName = "GuildRankingPage",
        _ccbi = "GuildRankingContentNew.ccbi",
    },--等级排行
	
	
}



local mRankNode = nil
local mCurrentIndex = 0;



local option = {
	ccbiFile = "GuildRankingPopUp.ccbi",
	handlerMap = {
		onCancel 		= "onClose",
		onClose 		= "onClose",
        onRankLevel     = "onRankLevel",
        onRankFight     = "onRankFight",
	}
}



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
    
    if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK  then 
       info = GuildData.rankingFightingList[index]
    else
       info = GuildData.rankingList[index]
    end

	if not info then return end

    local lb2Str = { }
     if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK  then --战力
           lb2Str = {
		    mRanking 		= index,
		    mID 			= info.id,
		    mGuildLv 		= info.score,
		    mGuildName 		= info.name,
		    mLeadersName 	= info.handName,
	        }
    else--等级
            lb2Str = {
		    mRanking 		= index,
		    mID 			= info.id,
		    mGuildLv 		= info.level,
		    mGuildName 		= info.name,
		    mLeadersName 	= info.handName,
	        }
    end

	
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

function GuildRankManage:onLoad(container)
	container:loadCcbiFile(option.ccbiFile)
end


function GuildRankManage:onEnter(container)
	mRankNode = container:getVarNode("mContentNode")	--绑定子页面ccb的节点
	if mRankNode then
        mRankNode:removeAllChildren()
    end
    NodeHelper:initScrollView(container, 'mContent', 10)
    self:registerPackets(container)
    self:refreshPage(container);
    GuildDataManager:requestRankingFightingList(container)
    GuildDataManager:requestRankingList(container)
end

function GuildRankManage:setBtnStatus( container )
    NodeHelper:setMenuItemSelected(container, 
        {
            mFightBtn = GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK,
            mLevelBtn = GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_LEVEL_RANK,
          
        }
    )
end
function GuildRankManage:setRankType(_type)
    GuildRankManage._curRankType = _type
end

function GuildRankManage:onRankFight( container )
    GuildRankManage:setRankType(GuildRankManage._rankType.GUILD_FIGHT_RANK)
    if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK then 
		self:setBtnStatus(container)

        local _labelLevelName = container:getVarLabelTTF("mLevelShow")
        local _labelFightName = container:getVarLabelTTF("mFightShow")
        _labelLevelName:setVisible(false)
        _labelFightName:setVisible(true)

        --return 
    end
    --GuildRankManage:setRankType(GuildRankManage._rankType.GUILD_FIGHT_RANK)
    self:refreshPage(container);
end
function GuildRankManage:onRankLevel( container )
    GuildRankManage:setRankType(GuildRankManage._rankType.GUILD_LEVEL_RANK)
    if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_LEVEL_RANK then 
		self:setBtnStatus(container)

        local _labelLevelName = container:getVarLabelTTF("mLevelShow")
        local _labelFightName = container:getVarLabelTTF("mFightShow")
        _labelLevelName:setVisible(true)
        _labelFightName:setVisible(false)
		--return 
    end
    
    self:refreshPage(container);
end

function GuildRankManage:onClose(container)
	PageManager.popPage(thisPageName)
end


function  GuildRankManage.getRankInfo(rankType)
    local _type = rankType or GuildRankManage._curRankType
    return GuildRankManage._rankInfo[_type]
end


function GuildRankManage:rebuildAllItem(container)
	self:clearAllItem(container)
	self:buildItem(container)
end

function GuildRankManage:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end
function GuildRankManage:buildItem(container)
     if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_LEVEL_RANK  then 
       if #GuildData.rankingList > 0 then 
	        NodeHelper:buildScrollView(container, #GuildData.rankingList, RankListItem.ccbiFile, RankListItem.onFunction);
       end
    else
        if #GuildData.rankingFightingList > 0 then 
	       NodeHelper:buildScrollView(container, #GuildData.rankingFightingList, RankListItem.ccbiFile, RankListItem.onFunction);
        end
    end
end
function GuildRankManage:refreshPage(container)


    self:rebuildAllItem(container)


--    local rankInfo = GuildRankManage.getRankInfo()
--	if rankInfo then
--		local page = rankInfo._scriptName
--		if page and page ~= "" and mRankNode then
--            if GuildRankManage.subPage then
--                GuildRankManage.subPage:onExit(container)
--                GuildRankManage.subPage = nil
--            end
--	        mRankNode:removeAllChildren()
--	        GuildRankManage.subPage = require(page)
--	        GuildRankManage.sunCCB = GuildRankManage.subPage:onEnter(container)
--	        mRankNode:addChild(GuildRankManage.sunCCB)
--	        GuildRankManage.sunCCB:setAnchorPoint(ccp(0.5,0.5))
----            if GuildRankManage.subPage["getPacketInfo"] then
----                GuildRankManage.subPage:getPacketInfo(MissionManager._curMissionType)
----            end
--	        GuildRankManage.sunCCB:release()
--            self:setBtnStatus(container);
--		end
--	end
end

--接收服务器回包
function GuildRankManage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	
	if opcode == hp.ALLIANCE_RANKING_S then
		-- alliance enter
		local msg = alliance.HPAllianceRankingS()
		msg:ParseFromString(msgBuff)
		self:onReceiveRankingList(container, msg)
        if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_LEVEL_RANK  then
             self:onRankLevel(container)
        end
        --self:refreshPage()
--       if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_LEVEL_RANK then 
--             if GuildRankManage.subPage then
--		        GuildRankManage.subPage:refreshPage(container)
--                return
--             end		
--        end
	end

	if opcode == hp.ALLIANCE_SCORE_RANK_S then
		-- alliance enter
		local msg = alliance.AllianceScoreRankingS()
		msg:ParseFromString(msgBuff)
		self:onReceiveRankingFightingList(container, msg)
        if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK  then
             self:onRankFight(container)
        end
--        if GuildRankManage._curRankType == GuildRankManage._rankType.GUILD_FIGHT_RANK then 
--             if GuildRankManage.subPage then
--		        GuildRankManage.subPage:refreshPage(container)
--                return
--             end
--        end
	end

end

function GuildRankManage:onReceiveRankingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankInfo(msg.rankings)
        --GuildData.rankingList = msg.rankings
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankInfo({})
	end
end

--接收战力排行榜数据 存储
function GuildRankManage:onReceiveRankingFightingList(container, msg)
	if msg.showTag then
		GuildDataManager:setRankFightingInfo(msg.rankings)
	else
		MessageBoxPage:Msg_Box('@GuildNoRankList')
		GuildDataManager:setRankFightingInfo({})
	end
end

function GuildRankManage:onExecute(container)
	if GuildRankManage.subPage then
		--GuildRankManage.subPage:onExecute(container)
	end

end
function GuildRankManage:onExit(container)
	if GuildRankManage.subPage then
		GuildRankManage.subPage:onExit(container)
		GuildRankManage.subPage = nil
	end
    self:removePackets(container)


end

function GuildRankManage:registerPackets(container)
	container:registerPacket(hp.ALLIANCE_RANKING_S)
    container:registerPacket(hp.ALLIANCE_SCORE_RANK_S)
end

function GuildRankManage:removePackets(container)
	container:removePacket(hp.ALLIANCE_RANKING_S)
    container:registerPacket(hp.ALLIANCE_SCORE_RANK_S)
end


local CommonPage = require('CommonPage')
GuildRankManage= CommonPage.newSub(GuildRankManage, thisPageName, option)

return GuildRankManage
