
local CommonPage = require("CommonPage")
local NodeHelper = require("NodeHelper")
local TribeAwardsDataManager = require("Activity.TribeAwardsDataManager")
local ResManagerForLua = require("ResManagerForLua")

local thisPageName = "TribeAwardsRewardPage"

local option = {
	ccbiFile = "Act_TribeAwardsRewardPopUp.ccbi",
	handlerMap = {
		onClose 		= "onClose", 
		onCancel 		= "onClose", 
        onConfirm       = "onConfirm"
	}
};
local TribeAwardsRewardPage = {}

function TribeAwardsRewardPage:buildItem(container)
    local rewardShowTable = {}
    local rewardCfg = TribeAwardsDataManager.rewardIds
    local nodesVisible = {};
	local lb2Str = {};
	local sprite2Img = {};
	local menu2Quality = {};
	
	for i = 1,3 do
		local cfg = ConfigManager.parseItemOnlyWithUnderline(rewardCfg[i]);
		nodesVisible["mRewardNode"..i] = cfg ~= nil;
		
		if cfg ~= nil then
			local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
			if resInfo ~= nil then
				sprite2Img["mRewardPic" .. i] 		= resInfo.icon;
				lb2Str["mReward" .. i]				= "x" .. cfg.count;
                lb2Str["mRewardName" .. i]				= resInfo.name;
                menu2Quality["mMaterialFrame" .. i]		= resInfo.quality;
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
function TribeAwardsRewardPage:onEnter(container)
    self:buildItem(container)
end
function TribeAwardsRewardPage:onClose(container)
	PageManager.popPage(thisPageName);
end
function TribeAwardsRewardPage:onConfirm(container)
	PageManager.popPage(thisPageName);
end

local TribeAwardsRewardPage = CommonPage.newSub(TribeAwardsRewardPage, thisPageName, option)