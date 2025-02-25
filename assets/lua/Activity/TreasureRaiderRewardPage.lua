

local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper");
local ResManagerForLua = require("ResManagerForLua");
local TreasureRaiderDataHelper = require ("Activity.TreasureRaiderDataHelper");
local thisPageName = "TreasureRaiderRewardPage"
local ITEM_PER_LINE = 4;
local option = {
	ccbiFile = "Act_TreasureRaidersRewardPopUp.ccbi",
	handlerMap = {
		onClose 		= "onClose", 
		onCancel 		= "onClose", 
	}
};

local RewardItem = {
	ccbiFile = "Act_TreasureRaidersRewardContent.ccbi",
}

local PageInfo = {
	rewardInfo = {},
};


function RewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
		RewardItem.onRefreshItemView(container);
	elseif eventName:sub(1, 6) == "onFeet" then
		RewardItem.showItemInfo( container , eventName )
	end
end

function RewardItem.onRefreshItemView(container)
	local index = container:getItemDate().mID;
    local rewardShowTable = {}
    for i =1,ITEM_PER_LINE do
        if PageInfo.rewardInfo[(index-1)*4+i]~=nil then
            local rewardCfg = PageInfo.rewardInfo[(index-1)*4+i].items
            table.insert(rewardShowTable, rewardCfg)
        end
    end
    RewardItem:fillRewardItem(container, rewardShowTable)
end

function RewardItem:fillRewardItem(container, rewardCfg)	
	local nodesVisible = {};
	local lb2Str = {};
	local sprite2Img = {};
	local menu2Quality = {};
	
	for i = 1, ITEM_PER_LINE do
		local cfg = rewardCfg[i];
		nodesVisible["mTreasureHuntRewardNode"..i] = cfg ~= nil;
		
		if cfg ~= nil then
			local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
			if resInfo ~= nil then
				sprite2Img["mTextPic" .. i] 		= resInfo.icon;
				lb2Str["mNum" .. i]				= "x" .. cfg.count;
				menu2Quality["mFeet" .. i]		= resInfo.quality;
			else
				CCLuaLog("Error::***reward item not found!!");
			end
		end
	end
	
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img);
	NodeHelper:setQualityFrames(container, menu2Quality);
end


function RewardItem.showItemInfo(container, eventName)
	local index = container:getItemDate().mID
	local rewardIndex = tonumber(eventName:sub(7)) + ITEM_PER_LINE*(index-1)
	GameUtil:showTip(container:getVarNode('mFeet' .. tonumber(eventName:sub(7))), PageInfo.rewardInfo[rewardIndex].items)
end

local RewardPreviewPageBase = {}
function RewardPreviewPageBase:buildItem(container)
	local size = 0;
	size = math.ceil(#PageInfo.rewardInfo/ITEM_PER_LINE);
	NodeHelper:buildScrollView(container, size, RewardItem.ccbiFile, RewardItem.onFunction);
end

function RewardPreviewPageBase:onEnter( container )
    NodeHelper:initScrollView(container, "mContent", 4);
    local showType = TreasureRaiderDataHelper:getBoxOrReward();
    local boxTitleStr = common:getLanguageString("@BoxPreviewTitle")
    local rewardTitleStr = common:getLanguageString("@RewardPreviewTitle")
    local boxTextStr = common:getLanguageString("@BoxPreviewText");
    local rewardTextStr = common:getLanguageString("@RewardPreviewText");
    if showType ==1 then
        NodeHelper:setStringForLabel(container, { mRewardTitle= rewardTitleStr});  
	    NodeHelper:setStringForLabel(container, { mRewardPreviewText= rewardTextStr});  
        PageInfo.rewardInfo = TreasureRaiderDataHelper.TreasureRaiderConfig.rewardCfg;
    else
        NodeHelper:setStringForLabel(container, { mRewardTitle= boxTitleStr});  
        NodeHelper:setStringForLabel(container, { mRewardPreviewText= boxTextStr});  
        PageInfo.rewardInfo = TreasureRaiderDataHelper.TreasureRaiderConfig.boxCfg;
    end
	--PageInfo.rewardInfo = ConfigManager.getTresureRaiderCfg() 
    self:buildItem( container )
end	
function RewardPreviewPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end


local RechargePage = CommonPage.newSub(RewardPreviewPageBase, thisPageName, option)