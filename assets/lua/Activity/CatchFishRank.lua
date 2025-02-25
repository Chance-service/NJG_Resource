
local HP_pb = require "HP_pb"
local thisPageName = "CatchFishRank"
local CatchFishRank = {}
local CatchFish_pb = require("CatchFish_pb")
local RankRewards = nil
local PlayerRank = nil
local UserInfo = require("PlayerInfo.UserInfo");
local option = {
	ccbiFile = "Act_FishingRankingPopUp.ccbi",
	handlerMap = {
        onReturnButton = "onClose",
        onClose = "onClose",
		onConfirmation = "onConfirmation",
        onRankingNow = "onRank",
        onRankingReward = "onRankReward",
	},
    opcodes = {
	    FISHING_RANK_C = HP_pb.FISHING_RANK_C,
	    FISHING_RANK_S = HP_pb.FISHING_RANK_S
    }
};
PageType = 
{
    RANK = 1,
    RANK_REWARD = 2
}
local RankContent = {
    ccbiRank = "Act_FishingRankingList.ccbi",
    ccbiReward = "Act_FishingRankingRewardList.ccbi",
}
local curPageType = 1;
local MyScore = 0;
-----------------RankContent&Reward-----------------------------
function RankContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        if curPageType == PageType.RANK then
            RankContent.onRefreshItemView_Rank(container);
        elseif curPageType == PageType.RANK_REWARD then
            RankContent.onRefreshItemView_reward(container);
        end
    elseif string.sub(eventName,1,6) == "onFeet" then
        local Itemindex = tonumber(string.sub(eventName,-1))
        local index = container:getItemDate().mID
        local rankInfo = RankRewards[index].rewards
        local reward = splitTiem(rankInfo)[Itemindex];
        GameUtil:showTip(container:getVarNode('mPic' .. Itemindex), reward)
    elseif eventName == "onSee" then
		RankContent.onSee(container)
	end	
end
function RankContent.onSee(container)
    local index = container:getItemDate().mID;
    local rankInfo = PlayerRank[index]
    if rankInfo~=nil then
        PageManager.viewPlayerInfo(rankInfo.playerId, true);
    end
end
function RankContent.onRefreshItemView_Rank(container)
    local index = container:getItemDate().mID
    local FishItemInfo = PlayerRank[index];
    local TextLabel = {}
    if FishItemInfo~=nil then
        TextLabel["mName"] = FishItemInfo.name
        TextLabel["mContribution"] = FishItemInfo.score
        TextLabel["mRanking"] = FishItemInfo.rank
    end
    if tonumber(UserInfo.playerInfo.playerId) == tonumber(FishItemInfo.playerId) then
        NodeHelper:setNodesVisible(container,{
            mScale9Sprite2 = true
        })
    else
        NodeHelper:setNodesVisible(container,{
            mScale9Sprite2 = false
        })
    end
    

    NodeHelper:setNodesVisible(container, {mRankingNum1 = false, mRankingNum2 = false, mRankingNum3 = false, mRankingNum4 = false})    
    if tonumber(index) == 1 then 
        NodeHelper:setNodesVisible(container, {mRankingNum1 = true})
        TextLabel["mRanking"] = ""
    elseif tonumber(index) == 2 then 
        NodeHelper:setNodesVisible(container, {mRankingNum2 = true})
        TextLabel["mRanking"] = ""
    elseif tonumber(index) == 3 then
        NodeHelper:setNodesVisible(container, {mRankingNum3 = true})
        TextLabel["mRanking"] = ""
    elseif tonumber(index)%2 == 0 then 
        NodeHelper:setNodesVisible(container, {mRankingNum4 = false})
    elseif tonumber(index)%2 == 1 then 
        NodeHelper:setNodesVisible(container, {mRankingNum4 = true})
    end

    NodeHelper:setStringForLabel(container,TextLabel);
end
function splitTiem(itemInfo)
	local items = {}
	for _, item in ipairs(common:split(itemInfo, ",")) do
		local _type, _id, _count = unpack(common:split(item, "_"));
		table.insert(items, {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		});
	end
	return items;
end
function RankContent.onRefreshItemView_reward(container)
    local index = container:getItemDate().mID
    local rankInfo = RankRewards[index];

    if rankInfo ~= nil then
        NodeHelper:setStringForLabel(container,{ mReceiveRanking = rankInfo.rankText});
        local rewards = splitTiem(rankInfo.rewards);
        NodeHelper:fillRewardItemWithParams(container, rewards,3,{ showHtml = false })
    end
    if rankInfo.id == 1 then
        NodeHelper:setNodesVisible(container,{
            mReceiveRanking = false,
            mReceiveRanking01 = true
        })
    else
        NodeHelper:setNodesVisible(container,{
            mReceiveRanking = true,
            mReceiveRanking01 = false
        })
    end
end
-----------------RankContent&Reward-----------------------------
----------------------------------------------

function CatchFishRank:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 12);
    curPageType = 1;
    RankRewards = ConfigManager.getCatchFishRankRewardsCfg()
    self:registerPacket(container);
    self:SelectPage(container);
    self:setBtnStatus( container )
end

function CatchFishRank:setBtnStatus( container )
    NodeHelper:setMenuItemSelected(container, 
        {
            mRankingNowBtn = curPageType == PageType.RANK,
            mRankingRewardBtn = curPageType == PageType.RANK_REWARD,
        }
    )
end

----------------------------------------------------------------
function CatchFishRank:SelectPage(container)
    self:setBtnStatus( container )
    if curPageType == PageType.RANK then
        --隐藏 other node
        NodeHelper:setNodesVisible(container,{ mRankNameNode = true });
        NodeHelper:setNodesVisible(container,{ mRankingRewardNode = false });
        -- container:getVarMenuItem("mRankingNowBtn"):selected()
        -- container:getVarMenuItem("mRankingNowBtn"):setEnabled(false)
        -- container:getVarMenuItem("mRankingRewardBtn"):unselected()
        -- container:getVarMenuItem("mRankingRewardBtn"):setEnabled(true) 
        self:getActivityInfo();
    elseif curPageType == PageType.RANK_REWARD then
        NodeHelper:setNodesVisible(container,{ mRankingRewardNode = true });
        NodeHelper:setNodesVisible(container,{ mRankNameNode = false });
        -- container:getVarMenuItem("mRankingRewardBtn"):selected()
        -- container:getVarMenuItem("mRankingRewardBtn"):setEnabled(false)
        -- container:getVarMenuItem("mRankingNowBtn"):unselected()
        -- container:getVarMenuItem("mRankingNowBtn"):setEnabled(true) 
        self:refreshPage(container);
    end
end
function CatchFishRank:onRank(container)
    curPageType = PageType.RANK
    self:SelectPage(container);
end
function CatchFishRank:onRankReward(container)
    curPageType = PageType.RANK_REWARD
    self:SelectPage(container);
end

function CatchFishRank:refreshPage(container)
    self:rebuildAllItem(container);
    NodeHelper:setStringForLabel(container, { mMyPoints = MyScore });
end

function CatchFishRank:refreshRankNode(container)

end

function CatchFishRank:refreshRankRewardNode(container)

end

function CatchFishRank:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end
function CatchFishRank:buildItem(container)
    local size = 0;
    local ccbiFile = ""
    if curPageType == PageType.RANK then
        self:refreshRankNode();
        ccbiFile = RankContent.ccbiRank;
        size = #PlayerRank
    elseif curPageType == PageType.RANK_REWARD then
        self:refreshRankRewardNode();
        ccbiFile = RankContent.ccbiReward;
        size = #RankRewards
    end
    NodeHelper:buildScrollView(container,size,ccbiFile, RankContent.onFunction);
end

function CatchFishRank:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end
----------------click event------------------------
function CatchFishRank:onClose(container)
	PageManager.popPage(thisPageName)
end

function CatchFishRank:onConfirmation(container)
     PageManager.popPage(thisPageName)
end

function CatchFishRank:getActivityInfo()
    common:sendEmptyPacket(HP_pb.FISHING_RANK_C , true)
end

function CatchFishRank:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FISHING_RANK_S then
        local msg = CatchFish_pb.FishingRankResponse()
        msg:ParseFromString(msgBuff)
        PlayerRank = msg.rankMessage;
        self:refreshPage(container);
    end
end

function CatchFishRank:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CatchFishRank:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function CatchFishRank:onExit(container)
	self:removePacket(container)
    NodeHelper:deleteScrollView(container);
end
function CatchFishRank_setScoreInfo(score)
    MyScore = score
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CatchFishRank = CommonPage.newSub(CatchFishRank, thisPageName, option);