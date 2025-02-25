

local HP_pb			  = require("HP_pb");
local ItemOpr_pb      = require("ItemOpr_pb");
local UserInfo        = require("PlayerInfo.UserInfo");
local NodeHelper      = require("NodeHelper");
local ItemOprHelper   = require("Item.ItemOprHelper");
local ItemManager     = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
local HeroOrderItemManager = require("Item.HeroOrderItemManager")
--------------------------------------------------------------------------------
local thisPageName 	= "HeroOrderUpgradePage";
local thisItemId	= 0;
local useCount      = 0;
local canUpgradeTen = false;

local opcodes = {
	ITEM_USE_S	= HP_pb.ITEM_USE_S
};

local option = {
	ccbiFile = "BackpackHeroPopUp4.ccbi",
	handlerMap = {
		onSynthesis		 		= "onUpgrade",
		onClose					= "onClose",
        onAllSynthesis          = "onUpgradeAdd"
	},
};
for i=1, #GameConfig.SoulStoneIds do
	option.handlerMap["onHand" .. i] = "onHeroOrderHand"
end

local HeroOrderUpgradeBase = {};
local mCurItemCfg          = nil;
local mCount               = 0
-----------------------------------------------
--HeroOrderUpgradeBase页面中的事件处理
----------------------------------------------
function HeroOrderUpgradeBase:onEnter(container)
	self:registerPacket(container);
	self:refreshPage(container);
end

function HeroOrderUpgradeBase:onExit(container)
	--PageManager.refreshPage("MercenaryUpStepPage")
	self:removePacket(container);
end
----------------------------------------------------------------
function HeroOrderUpgradeBase:refreshPage(container)
	thisItemId = ItemManager:getNowSelectItem()
    mCurItemCfg = ItemManager:getItemCfgById(thisItemId)
    mCount = #GameConfig.HeroOrderBaseIds
	self:showHeroOrdersInfo(container);
	self:showUpgradeInfo(container);
    self:refreshButton(container)
end

function HeroOrderUpgradeBase:showHeroOrdersInfo(container)
	local lb2Str = {}
	local sprite2Img = {}
	local scaleMap = {}
	local handMap = {}
	local lb2StrColor = {}
	for i=1, #GameConfig.HeroOrderBaseIds do
		local name	= ItemManager:getNameById(GameConfig.HeroOrderBaseIds[i] + mCurItemCfg.levelLimit);
		local stoneNum = UserItemManager:getCountByItemId(GameConfig.HeroOrderBaseIds[i] + mCurItemCfg.levelLimit);
		lb2Str["mNumber" .. i] = stoneNum
		lb2Str["mName" .. i] = common:getLanguageString("@HeroOrderName")
		--lb2StrColor["mName" .. i] = ItemManager:getQualityById(GameConfig.HeroOrderBaseIds[i] + mCurItemCfg.levelLimit)
		sprite2Img["mPic"..i] = ItemManager:getIconById(GameConfig.HeroOrderBaseIds[i] + mCurItemCfg.levelLimit)
		scaleMap["mPic"..i] = 1.0
		handMap["mHand"..i]	= ItemManager:getQualityById(GameConfig.HeroOrderBaseIds[i] + mCurItemCfg.levelLimit)
		NodeHelper:setNodeVisible(container:getVarNode("mTexBG"..i),((((thisItemId - mCurItemCfg.levelLimit) /1000) % 10 ) == i))

        local htmlNode = container:getVarLabelBMFont("mName" .. i)
        local str = common:getLanguageString("@HeroOrderName")
        if htmlNode then
		    local htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(96,64),str)
		    htmlLabel:setScale(htmlNode:getScale())
		    htmlNode:setVisible(false)
	    end
	end
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, handMap);
	NodeHelper:setQualityBMFontLabels(container,lb2StrColor)
end

function HeroOrderUpgradeBase:showUpgradeInfo(container)
	-- 是否是最后一本书
	NodeHelper:setNodesVisible(container, {mCanUpgradeBookNode = (thisItemId - mCurItemCfg.levelLimit ~= GameConfig.HeroOrderBaseIds[mCount])})
	NodeHelper:setNodesVisible(container, {mHighestBookExplain = (thisItemId - mCurItemCfg.levelLimit == GameConfig.HeroOrderBaseIds[mCount])})
	NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mSoulStoneUpgradeUpBtn"),(thisItemId - mCurItemCfg.levelLimit ~= GameConfig.HeroOrderBaseIds[mCount]))
    NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mAllSoulStoneUpgradeUpBtn"),(thisItemId - mCurItemCfg.levelLimit ~= GameConfig.HeroOrderBaseIds[mCount]))

    local nTaskId = ((thisItemId - mCurItemCfg.levelLimit) / 1000) % 10 + 400
    local nTaskConfig = HeroOrderItemManager:getTaskCfgByTaskId( nTaskId )
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

            --[[{"k":"@Topup","v":"果断充值"},
		        {"k":"@Customize","v":"定制"},
		        {"k":"@HeroTokenLimit","v":"英雄令40级开启"},
		        {"k":"@HeroTokenGold","v":"钻 石"},
		        {"k":"@HeroTokenCoin","v":"金 币"},
		        {"k":"@HeroTokenReward","v":"奖 励"},
		     {"k":"@HeroTokenRewardContent","v":"羽毛*#v1#"}--]]
            local strName = nil
            if costCfg.id == Const_pb.COIN then
                strName = common:getLanguageString("@HeroTokenCoin")
            elseif costCfg.id == Const_pb.GOLD then
                strName = common:getLanguageString("@HeroTokenGold")
            else
                strName = resInfo.name
            end
			if lineNumber == 1 then
				NodeHelper:setStringForLabel(container ,{
					mDiamondsNum = common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum),
                    mDiamonds    = strName,
                    mReward      = common:getLanguageString("@HeroTokenReward"),
                    mRewardFeather = common:getLanguageString("@HeroTokenRewardContent", nTaskConfig.rewardItem.count)
				})
			elseif lineNumber == 2 then
				NodeHelper:setStringForLabel(container, {
					mSynthesisBook 	  = resInfo.name,
 					mSynthesisBookNum = common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum),
                    mReward           = common:getLanguageString("@HeroTokenReward"),
                    mRewardFeather    = common:getLanguageString("@HeroTokenRewardContent", nTaskConfig.rewardItem.count)
				})
				NodeHelper:setQualityBMFontLabels(container,{mSynthesisBook = ItemManager:getQualityById(thisItemId)})
			end
			lineNumber = lineNumber + 1
		end
	end
	
	NodeHelper:setStringForLabel(container, {
		mTitle  				= common:getLanguageString("@HeroOrderUpgradeTitle"),
        mHighestBookExplain     = common:getLanguageString("@HeroOrderHighesExplain")
	})
    local lb2StrNode = {
		mReward 			= "mRewardFeather",
		mSynthesisBook 				= "mSynthesisBookNum",
        mDiamonds = "mDiamondsNum"
	};
    NodeHelper:setLabelMapOneByOne(container,lb2StrNode,20,true)
	NodeHelper:setNodesVisible(container,{mGold = (thisItemId - mCurItemCfg.levelLimit ~= GameConfig.HeroOrderBaseIds[mCount])})
end
	
function HeroOrderUpgradeBase:calculateCount(ownNum, costNum)
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

function HeroOrderUpgradeBase:judgeCount(container)
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

function HeroOrderUpgradeBase:refreshButton(container)
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
function HeroOrderUpgradeBase:onHeroOrderHand( container, eventName )
	local index = tonumber(eventName:sub(-1))
	ItemManager:setNowSelectItem(GameConfig.HeroOrderBaseIds[index] + mCurItemCfg.levelLimit)
	self:refreshPage(container)
end

function HeroOrderUpgradeBase:onUpgrade(container)
	ItemOprHelper:useHeroOrderItem(thisItemId,1);
end

function HeroOrderUpgradeBase:onUpgradeAdd(container)
    if useCount >= 10 then 
        ItemOprHelper:useHeroOrderItem(thisItemId, 10);
    elseif  useCount < 10 and useCount > 0 then 
        ItemOprHelper:useHeroOrderItem(thisItemId, useCount);
    else
        ItemOprHelper:useHeroOrderItem(thisItemId,1)
    end
end

function HeroOrderUpgradeBase:onClose(container)
	PageManager.popPage(thisPageName);
end


--回包处理
function HeroOrderUpgradeBase:onReceivePacket(container)
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

function HeroOrderUpgradeBase:registerPacket(container)
	container:registerPacket(opcodes.ITEM_USE_S)
end

function HeroOrderUpgradeBase:removePacket(container)
	container:removePacket(opcodes.ITEM_USE_S)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
HeroOrderUpgradePage = CommonPage.newSub(HeroOrderUpgradeBase, thisPageName, option);



--endregion
