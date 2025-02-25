
local HP_pb = require "HP_pb"
local thisPageName = "CatchFishPreview"
local CatchFishPreview = {}
local CatchFish_pb = require("CatchFish_pb")
local areadyGetIds = {}
local FishInfoCfg = nil
local option = {
	ccbiFile = "Act_FishingPreviewPopUp.ccbi",
	handlerMap = {
        onClose = "onClose",
		onConfirmation = "onConfirmation",
	},
    opcodes = {
	    FISH_PREVIEW_C = HP_pb.FISH_PREVIEW_C,
	    FISH_PREVIEW_S = HP_pb.FISH_PREVIEW_S
    }
};

FishContent = 
{
    ccbiFile = "Act_FishingPreviewContent.ccbi"
}
-----------------FishContent-----------------------------
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
function FishContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        FishContent.onRefreshItemView(container);
     elseif string.sub(eventName,1,7) == "onFrame" then
        local index = tonumber(string.sub(eventName,-1))
        local contentId = container:getItemDate().mID;
        local allrewards = FishInfoCfg[contentId].rewards
        local reward = splitTiem(allrewards)[index];
        GameUtil:showTip(container:getVarNode('mPic' .. index), reward)
    elseif eventName == "onGoodsFrame" then
        local contentId = container:getItemDate().mID;
        local allrewards = FishInfoCfg[contentId].itemId
        --屏蔽稀有鱼的展示
        --[[if common:table_hasValue(areadyGetIds,FishInfoCfg[contentId].id) then
            if FishInfoCfg[contentId].id == 9 then
                PageManager.pushPage("ShowRarelyFish");
                return 
            end
        end]]--

        local reward = splitTiem(allrewards)[1];
        GameUtil:showTip(container:getVarNode("mGoodsPic"), reward)
	end	
end
function FishContent.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local FishItemInfo = FishInfoCfg[index];
    local sprite2Img = {}
    local itemId = FishItemInfo.itemId
    local fishItem = splitTiem(FishItemInfo.itemId)
    local rewards = splitTiem(FishItemInfo.rewards)
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(fishItem[1].type, fishItem[1].itemId, fishItem[1].count);
    if common:table_hasValue(areadyGetIds,FishItemInfo.id) then
        sprite2Img["mGoodsPic"] = FishItemInfo.picLight
        NodeHelper:setQualityFrames(container, {mGoodsFrame = resInfo.quality});
    else
        sprite2Img["mGoodsPic"] = FishItemInfo.picGrey
    end
    NodeHelper:setQualityBMFontLabels(container, {mFishingReward = resInfo.quality})

     NodeHelper:setStringForLabel(container, { 
        mFishingReward = common:getLanguageString(FishItemInfo.name),
        mFishingRewardPoint = common:getLanguageString("@FishingReward_1",FishItemInfo.score)
    })
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:fillRewardItemWithParams(container, rewards,3,{ showHtml = false })
end

-----------------FishContent-----------------------------

function CatchFishPreview:onEnter(container)

    NodeHelper:initScrollView(container, "mContent", 12);
    FishInfoCfg = ConfigManager.getCatchFishCfg()
    table.sort(FishInfoCfg, function(fish1, fish2)
                if fish1.id > fish2.id then
                    return true;
                else
                    return false;
                end
		end);
    self:registerPacket(container);
    self:getActivityInfo();
end

----------------------------------------------------------------
function CatchFishPreview:refreshPage(container)

    self:rebuildAllItem(container)
end
function CatchFishPreview:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function CatchFishPreview:buildItem(container)
    NodeHelper:buildScrollView(container,#FishInfoCfg, FishContent.ccbiFile, FishContent.onFunction);
end

function CatchFishPreview:clearAllItem(container)
	container.m_pScrollViewFacade:clearAllItems();
	container.mScrollViewRootNode:removeAllChildren();
end
----------------click event------------------------
function CatchFishPreview:onClose(container)
	PageManager.popPage(thisPageName)
end

function CatchFishPreview:onConfirmation(container)
     PageManager.popPage(thisPageName)
end

function CatchFishPreview:getActivityInfo()
    common:sendEmptyPacket(HP_pb.FISH_PREVIEW_C , true)
end

function CatchFishPreview:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FISH_PREVIEW_S then
        local msg = CatchFish_pb.FishPreviewResponse()
		msg:ParseFromString(msgBuff)
        areadyGetIds = msg.fishId;
        self:refreshPage(container);
    end
end

function CatchFishPreview:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CatchFishPreview:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function CatchFishPreview:onExit(container)
	self:removePacket(container)
    NodeHelper:deleteScrollView(container);
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CatchFishPreview = CommonPage.newSub(CatchFishPreview, thisPageName, option);