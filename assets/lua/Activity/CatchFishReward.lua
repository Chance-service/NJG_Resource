
local HP_pb = require "HP_pb"
local thisPageName = "CatchFishReward"
local CatchFish = require("CatchFish")
local CatchFishReward = {}
local CatchFish_pb = require("CatchFish_pb")
local FishInfoCfg = nil
local showRewards = nil;
local showScore = nil
local ITEM_COUNT_PER_LINE = 5
local RewardContent = {}
local option = {
	ccbiFile = "Act_FishingRewardPopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
		onConfirmation = "onConfirmation",
	},
    opcodes = {
    }
};
local SCORE_ITEM = "30000_29999_"
----------------------------------------------

-----------------&Reward-----------------------------
function RewardContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        RewardContent.onRefreshItemView(container)
    elseif string.sub(eventName,1,6) == "onFeet" then
        local index = tonumber(string.sub(eventName,-1))
        local contentId = container:getItemDate().mID;
	    local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;
        local rewardIndex = baseIndex + index;
        local items = {}
        local _type, _id, _count = unpack(common:split(showRewards[rewardIndex], "_"));
		table.insert(items, {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		});
        GameUtil:showTip(container:getVarNode('mTextPic' .. index), items[1])

	end	
end
function RewardContent.onRefreshItemView(container)
	local contentId = container:getItemDate().mID;
	local baseIndex = (contentId - 1) * ITEM_COUNT_PER_LINE;

    local nodesVisible = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
	for i = 1, ITEM_COUNT_PER_LINE do
		local index = baseIndex + i;
        local item = showRewards[index]
        nodesVisible["mFishingRewardNode" .. i] = item ~= nil;
        if item ~= nil then
		    local _type, _id, _count = unpack(common:split(item, "_"))
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count));
            sprite2Img["mTextPic" .. i] 		= resInfo.icon;
            lb2Str["mNum" .. i]				= "x" .. _count;
            lb2Str["mName" .. i]			= resInfo.name;
            menu2Quality["mFeet" .. i]		= resInfo.quality;
        end
    end
    NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img);
	NodeHelper:setQualityFrames(container, menu2Quality);
end
-----------------&Reward-----------------------------

function CatchFishReward:onEnter(container)
    showRewards = {};
    showScore = 0
    local FishingRewards = getFishingPackageInfo();
    local bNeedShowRarelyFish = false;
    --收集所需信息
    for i = 1,#FishingRewards do
        showScore = showScore + tonumber(FishingRewards[i].score)
        if FishingRewards[i].fishId == 1 then--稀有鱼
            bNeedShowRarelyFish = true
        end
        if FishingRewards[i].reward ~=nil and FishingRewards[i].reward ~="" then
            table.insert(showRewards,FishingRewards[i].reward)
        else
            table.insert(showRewards,SCORE_ITEM..FishingRewards[i].score)
        end
    end
    --PageManager.pushPage("ShowRarelyFish");
    
    NodeHelper:initScrollView(container, "mContent", 12);
    self:refreshPage(container);
end

----------------------------------------------------------------

function CatchFishReward:refreshPage(container)
    if showRewards == nil or #showRewards <= 0 then
        return;
    end
    self:rebuildAllItem(container)
    NodeHelper:setStringForLabel(container, { mMyPoints = common:getLanguageString("@FishingRewardPointsTxt",showScore)});
end
function CatchFishReward:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function CatchFishReward:buildItem(container)
    local size = math.ceil(#showRewards / ITEM_COUNT_PER_LINE);
    NodeHelper:buildScrollView(container,size,"Act_FishingRewardContent.ccbi", RewardContent.onFunction);
end

function CatchFishReward:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end
----------------click event------------------------
function CatchFishReward:onClose(container)
    --奖励飘字
    local items = {}
    for i = 1,#showRewards do
        local _type, _id, _count = unpack(common:split(showRewards[i], "_"));
		table.insert(items, {
			itemType 	= tonumber(_type),
			itemId	= tonumber(_id),
			itemCount 	= tonumber(_count)
		});
    end
    NodeHelper:showRewardText(container, items)
    --奖励飘字
	PageManager.popPage(thisPageName)
end

function CatchFishReward:onConfirmation(container)
     PageManager.popPage(thisPageName)
end

function CatchFishReward:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FISH_PREVIEW_S then
        
        self:refreshPage(container);
    end
end

function CatchFishReward:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CatchFishReward:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function CatchFishReward:onExit(container)
    NodeHelper:deleteScrollView(container);
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CatchFishReward = CommonPage.newSub(CatchFishReward, thisPageName, option);