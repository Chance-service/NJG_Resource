
----------------------------------------------------------------------------------
local Const_pb 		= require("Const_pb");
local HP_pb			= require("HP_pb");
local ItemOpr_pb		= require("ItemOpr_pb");
local UserInfo = require("PlayerInfo.UserInfo");
--------------------------------------------------------------------------------
local thisPageName 	= "SoulStoneUpgradePage";
local thisItemId	= 0;
local useCount      = 0;
local canUpgradeTen = false;

local opcodes = {
	ITEM_USE_S	= HP_pb.ITEM_USE_S
};

local option = {
	ccbiFile = "MercenarySynthesisBookPopUp.ccbi",
	handlerMap = {
		onSynthesis		 		= "onUpgrade",
		onClose					= "onClose",
        onAllSynthesis          = "onUpgradeAdd"
	},
};
for i=1, #GameConfig.SoulStoneIds do
	option.handlerMap["onHand" .. i] = "onBookHand"
end

local SoulStoneUpgradeBase = {};
local NodeHelper = require("NodeHelper");
local ItemOprHelper = require("Item.ItemOprHelper");
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
-----------------------------------------------
--SoulStoneUpgradeBase页面中的事件处理
----------------------------------------------
function SoulStoneUpgradeBase:onEnter(container)
	self:registerPacket(container);
	self:refreshPage(container);
end

function SoulStoneUpgradeBase:onExit(container)
--	PageManager.refreshPage("MercenaryUpStepPage")
	self:removePacket(container);
end
----------------------------------------------------------------
function SoulStoneUpgradeBase:refreshPage(container)
	thisItemId = ItemManager:getNowSelectItem()
	self:showSoulStoneInfo(container);
	self:showUpgradeInfo(container);
    self:refreshButton(container)
end

function SoulStoneUpgradeBase:showSoulStoneInfo(container)
	local lb2Str = {}
	local sprite2Img = {}
	local scaleMap = {}
	local handMap = {}
	local lb2StrColor = {}
	for i=1, #GameConfig.SoulStoneIds do
		local name	= ItemManager:getNameById(GameConfig.SoulStoneIds[i]);
		local stoneNum = UserItemManager:getCountByItemId(GameConfig.SoulStoneIds[i]);
		lb2Str["mNumber" .. i] = stoneNum
		lb2Str["mName" .. i] = name
		lb2StrColor["mName" .. i] = ItemManager:getQualityById(GameConfig.SoulStoneIds[i])
		sprite2Img["mPic"..i] = ItemManager:getIconById(GameConfig.SoulStoneIds[i])
		scaleMap["mPic"..i] = 1.0
		handMap["mHand"..i]	= ItemManager:getQualityById(GameConfig.SoulStoneIds[i])
		
		NodeHelper:setNodeVisible(container:getVarNode("mTexBG"..i),((thisItemId%10)-1 == i))
	end
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, handMap);
	NodeHelper:setQualityBMFontLabels(container,lb2StrColor)
end

function SoulStoneUpgradeBase:showUpgradeInfo(container)
	-- 是否是最后一本书
	NodeHelper:setNodesVisible(container, {mCanUpgradeBookNode = (thisItemId%10~=6)})
	NodeHelper:setNodesVisible(container, {mHighestBookExplain = (thisItemId%10==6)})
	NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mSoulStoneUpgradeUpBtn"),(thisItemId%10~=6))
    NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mAllSoulStoneUpgradeUpBtn"),(thisItemId%10~=6))

	local userItem = UserItemManager:getUserItemByItemId(thisItemId)
	local levelUpCost = ItemManager:getLevelUpCost(thisItemId);
	local costMax = ItemManager:getLevelUpCostMax(thisItemId);
	costMax = math.max(1, costMax);
	local costTb = {};
	local lineNumber = 1
	for _, costCfg in ipairs(levelUpCost) do
		local resInfo = ResManagerForLua:getResInfoByTypeAndId(costCfg.type, costCfg.id, costCfg.count);
		if resInfo ~= nil then
			local ownNum = 0;
			if resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.COIN then
				UserInfo.syncPlayerInfo();
				ownNum = UserInfo.playerInfo.coin;
			elseif resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.GOLD then
				UserInfo.syncPlayerInfo();
				ownNum = UserInfo.playerInfo.gold;
			else
				ownNum = UserItemManager:getCountByItemId(costCfg.id);
			end
			local strSplit = ""
			local titleStr = ""
			if Golb_Platform_Info.is_r2_platform then
				if  GamePrecedure:getInstance():getI18nSrcPath() == "French" then
					strSplit = " :"
				elseif GamePrecedure:getInstance():getI18nSrcPath() ~= "" then
					strSplit = ":"
				end
				titleStr = common:getLanguageString("@RequiredTitle")
				--2015-6-18 之前加上的这个，今天又让去掉了，简直好顶赞
				titleStr = ""
			end


			if lineNumber == 1 then
				NodeHelper:setStringForLabel(container ,{
					mDiamondsNum = titleStr .. resInfo.name .. strSplit .. common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum)
				})
			elseif lineNumber == 2 then
				NodeHelper:setStringForLabel(container, {
					mSynthesisBook 				= titleStr .. resInfo.name .. strSplit,
 					mSynthesisBookNum  			= common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum)
				})
				NodeHelper:setQualityBMFontLabels(container,{mSynthesisBook = ItemManager:getQualityById(thisItemId)})

				--修改数字位置
				if strSplit ~= "" then
					local nameWidth = container:getVarLabelBMFont("mSynthesisBook"):getContentSize().width
					local nameScaleX = container:getVarLabelBMFont("mSynthesisBook"):getScaleX()
					nameWidth = nameWidth * nameScaleX
					local nameX, nameY = container:getVarLabelBMFont("mSynthesisBook"):getPosition()
					container:getVarLabelBMFont("mSynthesisBookNum"):setPosition(CCPointMake(nameX + nameWidth, nameY))
				end
			end
			lineNumber = lineNumber + 1
		end
	end
	
	NodeHelper:setStringForLabel(container, {
		mTitle  				= common:getLanguageString("@SoulStoneUpgradeTitle"),
	})
	NodeHelper:setNodesVisible(container,{mGold = (thisItemId%10~=6)})
end
	
function SoulStoneUpgradeBase:calculateCount(ownNum, costNum)
    local flag = false
    local count = 0
    if costNum ~= 0 then 
        local temp = ownNum % costNum
        count = (ownNum - temp)/costNum
        if count >= 10  then 
            flag = true 
        else 
            flag = false 
        end
    end
    return count, flag
end

function SoulStoneUpgradeBase:judgeCount(container)
	local levelUpCost = ItemManager:getLevelUpCost(thisItemId); 
    local countByCoin = 0
    local canUpgradeTenByCoin = false
    local countByGold = 0
    local canUpgradeTenByGold = false
    local countByItem = 0
    local canUpgradeTenByItem = false

    for _, costCfg in ipairs(levelUpCost) do
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(costCfg.type, costCfg.id, costCfg.count);
        if resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.COIN then
            UserInfo.syncPlayerInfo();
            countByCoin, canUpgradeTenByCoin = self:calculateCount(UserInfo.playerInfo.coin, costCfg.count)
            useCount        = countByCoin
            canUpgradeTen   = canUpgradeTenByCoin
        elseif resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.GOLD then 
            UserInfo.syncPlayerInfo();
            countByGold, canUpgradeTenByGold = self:calculateCount(UserInfo.playerInfo.gold, costCfg.count)
            useCount        = countByGold
            canUpgradeTen   = canUpgradeTenByGold
        else 
            countByItem, canUpgradeTenByItem = self:calculateCount(UserItemManager:getCountByItemId(costCfg.id), costCfg.count)
        end
    end
    useCount = math.min(useCount, countByItem)
    if canUpgradeTen and canUpgradeTenByItem then
        canUpgradeTen = true
    else 
        canUpgradeTen = false 
    end
end

function SoulStoneUpgradeBase:refreshButton(container)
    self:judgeCount(container) 
    if canUpgradeTen then 
        NodeHelper:setStringForLabel(container, {
		mAllSynthesis  				= common:getLanguageString("@TenSoulStoneUpgradeBtnLabel"),
	    })
    else 
        NodeHelper:setStringForLabel(container, {
		mAllSynthesis  				= common:getLanguageString("@AllSoulStoneUpgradeBtnLabel"),
	    })
    end 
end


----------------click event------------------------
function SoulStoneUpgradeBase:onBookHand( container, eventName )
	local index = tonumber(eventName:sub(-1))
	ItemManager:setNowSelectItem(GameConfig.SoulStoneIds[index])
	self:refreshPage(container)
end

function SoulStoneUpgradeBase:onUpgrade(container)
	ItemOprHelper:useItem(thisItemId,1);
end

function SoulStoneUpgradeBase:onUpgradeAdd(container)
    if useCount >= 10 then 
        ItemOprHelper:useItem(thisItemId, 10);
    elseif  useCount < 10 and useCount > 0 then 
        ItemOprHelper:useItem(thisItemId, useCount);
    else
        ItemOprHelper:useItem(thisItemId,1)
    end
end

function SoulStoneUpgradeBase:onClose(container)
	PageManager.popPage(thisPageName);
end


--回包处理
function SoulStoneUpgradeBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.ITEM_USE_S then
		-- local msg = ItemOpr_pb.HPItemUseRet();
		-- msg:ParseFromString(msgBuff);
		local tipKey = "@SoulStoneUpgradeSuccess";
		local colorKey = "COLOR_GREEN";

		common:popString(common:getLanguageString(tipKey), colorKey);
		self:refreshPage(container);
	end
end

function SoulStoneUpgradeBase:registerPacket(container)
	container:registerPacket(opcodes.ITEM_USE_S)
end

function SoulStoneUpgradeBase:removePacket(container)
	container:removePacket(opcodes.ITEM_USE_S)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
SoulStoneUpgradePage = CommonPage.newSub(SoulStoneUpgradeBase, thisPageName, option);

