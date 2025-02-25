
local UserItemManager = require("Item.UserItemManager");
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local Const_pb = require("Const_pb");
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")

local thisPageName = "ExpeditionMaterialsRewardPage"
local opcodes = {
	
};
local RewardParams = {
    mainNode = "mGemNode",
    countNode = "mNum",
    nameNode = "mName",
    frameNode = "mFeet0",
    picNode = "mGemPic",
    startIndex = 1
}
local option = {
	ccbiFile = "Act_ExpeditionMaterialsRewardPopUp.ccbi",
	handlerMap = {
		onClose	        = "onClose",
	},
	opcode = opcodes
};
----------------- local data -----------------
local ExpeditionMaterialsRewardPageBase = {}

local MaterialsRewardItem = {
	ccbiFile = "Act_ExpeditionMaterialsRewardContent.ccbi"
}

function MaterialsRewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
		MaterialsRewardItem.onRefreshItemView(container);
	elseif eventName == "onDonation" then
		MaterialsRewardItem.onDonationOne(container);
	elseif eventName == "onDonationTen" then
		MaterialsRewardItem.onDonationTen(container);
    elseif eventName:sub(1, 6) == "onFeet" then
		MaterialsRewardItem.showItemInfo(container, eventName);
	end	
end

function MaterialsRewardItem.onRefreshItemView(container)
	local index = container:getItemDate().mID;
	local stageRewardInfo = ExpeditionDataHelper.getStageRewardInfoByStageId(index)
	if stageRewardInfo~=nil then
	    local cfg = ConfigManager.getRewardById(stageRewardInfo.r);
        NodeHelper:fillRewardItemWithParams(container, cfg, 3,RewardParams)
		local mStageInfo = ExpeditionDataHelper.getStageInfoByStageId(index)
		if mStageInfo then
			NodeHelper:setStringForLabel(container, {mStageCompleteReward = common:getLanguageString("@StageCompleteReward" .. index)})
			NodeHelper:setStringForLabel(container, {mQiXiStageNum = mStageInfo.personalStageExp .. "/" .. stageRewardInfo.q})
		end
	end
end

function MaterialsRewardItem.showItemInfo(container,eventName)
	local index = container:getItemDate().mID;
	local stageRewardInfo = ExpeditionDataHelper.getStageRewardInfoByStageId(index)
	if stageRewardInfo~=nil then
	    local cfg = ConfigManager.getRewardById(stageRewardInfo.r); 
	    local rewardIndex = tonumber(eventName:sub(8));
	    if cfg[rewardIndex] ~= nil then
	        GameUtil:showTip(container:getVarNode('mFeet0' .. rewardIndex), common:table_merge(cfg[rewardIndex],{buyTip=true,hideBuyNum=true}));
	    end
	end
end

-----------------------------------------------
--ExpeditionMaterialsRewardPageBase页面中的事件处理
----------------------------------------------
function ExpeditionMaterialsRewardPageBase:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 4);
    
    self:registerPacket(container)
    ExpeditionMaterialsRewardPageBase:refreshPage(container)
end

function ExpeditionMaterialsRewardPageBase:onExecute(container)

end

function ExpeditionMaterialsRewardPageBase:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container);
end


function ExpeditionMaterialsRewardPageBase:refreshPage(container)
    self:rebuildAllItem(container);
end

----------------scrollview-------------------------
function ExpeditionMaterialsRewardPageBase:rebuildAllItem(container)
    self:clearAllItem(container);
	self:buildItem(container);
end

function ExpeditionMaterialsRewardPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container);
end

function ExpeditionMaterialsRewardPageBase:buildItem(container)
    local size = ExpeditionDataHelper.getMaxStageId()
    NodeHelper:buildScrollView(container,size, MaterialsRewardItem.ccbiFile, MaterialsRewardItem.onFunction);
end
----------------click event------------------------	
function ExpeditionMaterialsRewardPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end	
-------------------------------------------------------------------------
function ExpeditionMaterialsRewardPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode();
	local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.PLAYER_CONSUME_S then
		self:refreshPage(container);
	end
end

function ExpeditionMaterialsRewardPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ExpeditionMaterialsRewardPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
----------------------------------------------------------------------------
local CommonPage = require("CommonPage");
ExpeditionMaterialsRewardPage = CommonPage.newSub(ExpeditionMaterialsRewardPageBase, thisPageName, option);
