------------------------------------------------
-- author:zt
-- time:2015/03/02
------------------------------------------------
local BasePage = require("BasePage")
local RankGiftManager = require("Activity.RankGiftManager")
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")

local opcodes = {
    RANK_GIFT_INFO_S = HP_pb.RANK_GIFT_INFO_S
}
local option = {
	ccbiFile = "Act_RankingGiftPage.ccbi",
	handlerMap = {
		onReturnButton = "onReturn",
		onHelp = "onHelp",
		onArenaRanking = "onArenaRank",
		onLevelRanking = "onLevelRank",
	},
	DataHelper = RankGiftManager
}
local thisPageName = "RankGiftPage"
local RankGiftPage = BasePage:new(option,thisPageName,nil,opcodes)

--local data
local PageTabDefine = {
    ArenaRank = 1,
    LevelRank = 2,
}
local pageTabIndex = PageTabDefine.ArenaRank
local timerName = "RankGiftLeftTimes"
local hasReceivePacket = false
--content begin
local RankGiftContent = {
    ccbiFile = "Act_RankingGiftContent.ccbi"
}

function RankGiftContent.onFunction(eventName,container)
    if eventName=="luaRefreshItemView" then
        RankGiftContent.refreshContent(container)
    elseif eventName=="onPlayerBtn" then
        --show player info
        RankGiftContent.showPlayerInfo(container)
    elseif string.sub(eventName,1,7)=="onFrame" then
        --show tip
        local index = string.sub(eventName,8,-1)
        index = tonumber(index)
        RankGiftContent.showTip(container,index)
    end
end

function RankGiftContent.refreshContent(container)
    local index = container:getItemDate().mID
    
    local playerInfo=nil 
    local rewardCfg=nil
    local rankText=nil

    NodeHelper:setNodesVisible(container,{mNameNode1=false})
    NodeHelper:setNodesVisible(container,{mNameNode2=false})
    if pageTabIndex==PageTabDefine.ArenaRank then
        playerInfo = RankGiftManager:getArenaPlayerInfoByIndex(index)
        rewardCfg = RankGiftManager:getArenaRewardsByIndex(index)
        rankText = RankGiftManager:getArenaRankTextByIndex(index)

        -- 竞技排名只显示前三个排名玩家的名字
        if playerInfo~=nil and index <= 3 then 
            NodeHelper:setNodesVisible(container,{mNameNode1=true})
            NodeHelper:setStringForLabel(container,{mPlayerName1 = playerInfo.name})
        end
    elseif pageTabIndex==PageTabDefine.LevelRank then
        playerInfo = RankGiftManager:getLevelPlayerInfoByIndex(index)
        rewardCfg = RankGiftManager:getLevelRewardsByIndex(index)
        rankText = RankGiftManager:getLevelRankTextByIndex(index)

        if playerInfo~=nil and index <= 3 then 
            NodeHelper:setNodesVisible(container,{mNameNode2=true})
            NodeHelper:setStringForLabel(container,{mPlayerName2 = playerInfo.name})
            NodeHelper:setStringForLabel(container,{mExpNum = GameUtil:getTotalExpByLevelAndExp(playerInfo.level,playerInfo.exp)})
        end
    end
    --rank
    if rankText~=nil then
        NodeHelper:setStringForLabel(container,{mRankNum = rankText})
    end
    --player info
    
    --reward info
    if rewardCfg~=nil then
        NodeHelper:fillRewardItem(container, rewardCfg, 3)
    end
end

function RankGiftContent.showPlayerInfo(container)
    local index = container:getItemDate().mID
    local playerInfo = nil
    if pageTabIndex==PageTabDefine.ArenaRank then
        playerInfo = RankGiftManager:getArenaPlayerInfoByIndex(index)
    elseif pageTabIndex==PageTabDefine.LevelRank then
        playerInfo = RankGiftManager:getLevelPlayerInfoByIndex(index)
    end
    
    
    if playerInfo~=nil then
        if playerInfo.isNPC==0 then
            MessageBoxPage:Msg_Box('@CheckNPCErro')
            return
        end
        PageManager.viewPlayerInfo(playerInfo.playerId, true);
    end
end

function RankGiftContent.showTip(container,index)
    local id = container:getItemDate().mID
    local rewardInfo = nil
    if pageTabIndex==PageTabDefine.ArenaRank then
        rewardInfo = RankGiftManager:getArenaRewardsByIndex(id) 
    elseif pageTabIndex==PageTabDefine.LevelRank then
        rewardInfo = RankGiftManager:getLevelRewardsByIndex(id) 
    end
    rewardInfo = rewardInfo and rewardInfo[index]

    if rewardInfo~=nil then
        GameUtil:showTip(container:getVarNode('mFrame'..index),rewardInfo);
    end
end
--content end
function RankGiftPage:getPageInfo(container)
    --require page data 
    local Activity2_pb = require("Activity2_pb")
    local msg = Activity2_pb.HPRankGift();
	common:sendPacket(HP_pb.RANK_GIFT_INFO_C, msg);
end

function RankGiftPage:onExecute(container)  
    if hasReceivePacket then
        self:onTimer(container,timerName,"mActivityDaysNum")
    else
        NodeHelper:setStringForLabel(container,{mActivityDaysNum = ""})
    end
end

function RankGiftPage:refreshPage(container)
    hasReceivePacket = true;
    self:refreshTotalTime(container)
    self:refreshSelfRank(container)
    self:rebuildAllItem(container)
end

function RankGiftPage:refreshTotalTime(container)
    local totalTime = RankGiftManager:getActivityTotalTime()
    if totalTime~=nil then
        if pageTabIndex==PageTabDefine.ArenaRank then
            NodeHelper:setStringForLabel(container,{mArenaRankingLab = common:getLanguageString("@RankGiftTitle1")})
        elseif pageTabIndex==PageTabDefine.LevelRank then
            NodeHelper:setStringForLabel(container,{mArenaRankingLab = common:getLanguageString("@RankGiftTitle2")})
        end
        NodeHelper:setStringForLabel(container,{mTexLab2 = totalTime})
    end
end

function RankGiftPage:refreshSelfRank(container)
    local selfRank = nil
    if pageTabIndex==PageTabDefine.ArenaRank then
        selfRank = RankGiftManager:getSelfArenaRank()
    elseif pageTabIndex==PageTabDefine.LevelRank then
        selfRank = RankGiftManager:getSelfLevelRank()
    end
    
    if selfRank~=nil then
        NodeHelper:setStringForLabel(container,{mCurrentRankNum = selfRank})
    end
end

function RankGiftPage:buildItem(container)
    local rankInfoCfg = nil 
    if pageTabIndex==PageTabDefine.ArenaRank then
        rankInfoCfg = RankGiftManager:getArenaRankListCfg()
    elseif pageTabIndex==PageTabDefine.LevelRank then
        rankInfoCfg = RankGiftManager:getLevelRankListCfg()
    end
    if rankInfoCfg~=nil then
        NodeHelper:buildScrollView(container,#rankInfoCfg,RankGiftContent.ccbiFile, RankGiftContent.onFunction)
    end
end

function RankGiftPage:onExit(container)
    hasReceivePacket = false;
    self.super.onExit(self,container)
end

--event handler
function RankGiftPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_RANKGIFT)
end

function RankGiftPage:onReturn(container)
    PageManager.changePage("ActivityPage")
end

function RankGiftPage:onArenaRank(container)
    if pageTabIndex~=PageTabDefine.ArenaRank then
        pageTabIndex = PageTabDefine.ArenaRank
        self:refreshPage(container)
    end
end

function RankGiftPage:onLevelRank(container)
    if pageTabIndex~=PageTabDefine.LevelRank then
        pageTabIndex = PageTabDefine.LevelRank
        self:refreshPage(container)
    end
end
