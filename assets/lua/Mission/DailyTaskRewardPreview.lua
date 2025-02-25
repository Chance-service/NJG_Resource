
local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper");
local ResManagerForLua = require("ResManagerForLua");
local thisPageName = "DailyTaskRewardPreview"
local ItemManager      = require("Item.ItemManager")
local ITEM_PER_LINE = 5;
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

local RewardPreviewCfg = {}
local boxTextStr = ""
local rewardTextStr = ""
local BG=""

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
        if RewardPreviewCfg[(index-1)*4+i]~=nil then
            local rewardCfg = RewardPreviewCfg[(index-1)*4+i]
            if rewardCfg.type then
            	table.insert(rewardShowTable,rewardCfg)
            elseif rewardCfg.items then
	            local items = {}
			    local _type, _id, _count = unpack(common:split(rewardCfg.items, "_"));
			    table.insert(rewardShowTable, {
				    type 	= tonumber(_type),
				    itemId	= tonumber(_id),
				    count 	= tonumber(_count)
			    });
            end

        end
    end
    RewardItem:fillRewardItem(container, rewardShowTable)
end

function RewardItem:fillRewardItem(container, rewardCfg)	
	local nodesVisible = {};
	local lb2Str = {};
	local sprite2Img = {};
	local menu2Quality = {};
	local scaleMap = {}
	local colorMap = {}
	for i = 1, ITEM_PER_LINE do
		local cfg = rewardCfg[i];
		nodesVisible["mTreasureHuntRewardNode"..i] = cfg ~= nil;
		
		if cfg ~= nil then
			local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
			if resInfo ~= nil then
				sprite2Img["mTextPic" .. i] = resInfo.icon;
				scaleMap["mTextPic" .. i]   = resInfo.iconScale
				lb2Str["mNum" .. i]		    = cfg.count > 0 and cfg.count or "";
				lb2Str["mName"..i] = resInfo.name
				menu2Quality["mFeet" .. i]  = resInfo.quality;
                sprite2Img["mBg_" .. i] = NodeHelper:getImageBgByQuality(resInfo.quality)

                --colorMap["mNum" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                colorMap["mName" .. i] = ConfigManager.getQualityColor()[resInfo.quality].textColor
			else
				CCLuaLog("Error::***reward item not found!!");
			end
		end
	end
	
   
    NodeHelper:setColorForLabel(container , colorMap)
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, menu2Quality);
end


function RewardItem.showItemInfo(container, eventName)
	local index = container:getItemDate().mID
	local rewardIndex = tonumber(eventName:sub(7)) + ITEM_PER_LINE*(index-1)
	local items = {}
	if RewardPreviewCfg[rewardIndex].type then
		items = RewardPreviewCfg[rewardIndex]
	elseif RewardPreviewCfg[rewardIndex].items then

	    local _type, _id, _count = unpack(common:split(RewardPreviewCfg[rewardIndex].items, "_"));
	    items = {
			type 	= tonumber(_type),
			itemId	= tonumber(_id),
			count 	= tonumber(_count)
		};
	end
	GameUtil:showTip(container:getVarNode('mFeet' .. tonumber(eventName:sub(7))),items)
end

local DailyTaskRewardPreviewBase = {}
function DailyTaskRewardPreviewBase:buildItem(container)
	local size = 0;
	size = math.ceil(#RewardPreviewCfg/ITEM_PER_LINE);
	NodeHelper:buildScrollView(container, size, RewardItem.ccbiFile, RewardItem.onFunction);
end

function DailyTaskRewardPreviewBase:onEnter( container )
    NodeHelper:initScrollView(container, "mContent", 4);
    --local boxTextStr = common:getLanguageString("@RewardPreviewTitle");
    --local rewardTextStr = common:getLanguageString("@ForgingPoolShowMsg");
    NodeHelper:setStringForLabel(container, { mRewardTitle= boxTextStr});  
    NodeHelper:setStringForLabel(container, { mRewardPreviewText= rewardTextStr});  

    NodeHelper:setNodesVisible(container, {mHelpNode = false})
    
    if BG~="" then
        NodeHelper:setScale9SpriteImage2(container, {mBackGround=BG})
        NodeHelper:setMenuItemImage(container,{mBtn={normal = "GloryHole_btn05_N.png", press = "GloryHole_btn05_S.png", disabled= "GloryHole_btn05_G.png" }})
        container:getVarNode("mBtn"):setScale(0.8)
    end

    self:buildItem( container )

    container.mScrollView:setTouchEnabled(false)
end	
function DailyTaskRewardPreviewBase:onClose(container)
    BG=""
	PageManager.popPage(thisPageName);
end
function DailyTaskRewardPreviewBase:onExit( container )
     BG=""
	NodeHelper:deleteScrollView(container)
end

local DailyTaskRewardPreview = CommonPage.newSub(DailyTaskRewardPreviewBase, thisPageName, option)

function ShowRewardPreview(previewData,titleText,previewText,bg)
    BG=""
	RewardPreviewCfg = previewData
	boxTextStr = titleText
	rewardTextStr = previewText
	--if #RewardPreviewCfg > 4 then
	--	option.ccbiFile = "Act_TreasureRaidersRewardPopUp.ccbi"
	--	RewardItem.ccbiFile = "Act_TreasureRaidersRewardContent.ccbi"
	--else
		option.ccbiFile = "MapLevelMaxRewardPopUp.ccbi"
		RewardItem.ccbiFile = "MapLevelMaxRewardContent.ccbi"
        if bg then
            BG=bg
        end
	--end
end