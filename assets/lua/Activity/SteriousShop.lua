----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local thisPageName = "SteriousShop"
local HP = require("HP_pb");
require("Shop_pb");

local UserInfo = require("PlayerInfo.UserInfo");
local NewbieGuideManager = require("Guide.NewbieGuideManager")
------------local variable for system global api--------------------------------------
local tostring = tostring;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local mRebuildLock = true
local mRefreshCout = 0
local SteriousShopPage = {};
local SteriousIsClose = false;--活动
local MarketItem = 
{
	ccbiFile = "FairContentItem.ccbi",
};

local MarketItemSub = 
{
	ccbiFile = "FairContent.ccbi",
};

local opcodes = 
{
    OPCODE_SHOP_AUCTION_C = HP.SHOP_AUCTION_C,
	OPCODE_SHOP_AUCTION_S = HP.SHOP_AUCTION_S,
	OPCODE_SHOP_DROPS_C = HP.SHOP_STERIOUS_C,
	OPCODE_SHOP_DROPS_S = HP.SHOP_STERIOUS_S,
	OPCODE_PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
	OPCODE_PLAYER_CONSUME_S = HP_pb.PLAYER_CONSUME_S
}

--商店类型
local iConType = 
{
	type_Coins = 1,
	type_Gold = 2,
	type_Coins_Pic = "UI/MainScene/Common/u_CmnCoin.png",
	type_Gold_Pic = "UI/MainScene/Common/u_CmnGold.png"
}

local option = {
	ccbiFile = "BlackMarket.ccbi",
	handlerMap = {
		onGoblinmerchant		= "openDropsMarket",
		onBuyAll				= "onBuyAll",
        onBrush				= "onBuyCoinsOrRefreshDrops",
		onHelp			= "onHelp",
        onAution			= "onAution",
        onHand			= "onHand",
        onReturnButton			= "onReturnButton",
	},
	opcode = opcodes
};

--商店购买类型
local ShopInfoType = 
{
	TYPE_INIT_INFO = 1,
	TYPE_BUY_SINGLE = 2,
	TYPE_BUY_ALL = 3,
	TYPE_REFRESH = 4
}
--竞拍类型
local ShopAuctionType = 
{
	TYPE_INIT_INFO = 1,--初始化
	TYPE_TAKE_AUCTION = 2,--竞拍
}
local MainContainer = nil;

--商店商品List信息
local marketAdventureInfo = 
{
	dropsItems = {},
	coinReward = 0,
	coinCost = 0,
	coinCount = 0,
    refreshPrice = 0,
    mLeftTimes = 8888,
    mCDTimeKey = "DropsLeftTimes",
    mCloseTimes = 0,
    mCDCloseKey = "ActivityCloseTimes",
}
local mAuctionInfo = --黑色商人，竞拍相关信息
{   
    mDropInfo = {},
    mLeftTimes = 8888,
    mCurPrices = 0,
    mMyPrices = 0,
    mCDTimeKey = "AuctionLeftTimes",
};
local dropsItemsTeam = 
{
}

--折扣信息
local PercentItem = 
{
	eight_percent = 80,
	five_percent = 50,
	one_percent = 10
}

local ITEM_COUNT_PER_LINE = 5;

local VipConfig = ConfigManager.getVipCfg();
local RefreshCostCfg = ConfigManager.getRefreshMarketCostCfg();

-----------------注销，clear 商店list信息-----------------------------
function RESETINFO_MARKET()
	marketAdventureInfo = {}
	marketAdventureInfo.dropsItems = {};
	marketAdventureInfo.coinReward = 0;
	marketAdventureInfo.coinCost = 0;
	marketAdventureInfo.coinCount = 0;
    marketAdventureInfo.mLeftTimes = 0;
    marketAdventureInfo.mCDTimeKey = "DropsLeftTimes";
    marketAdventureInfo.mCloseTimes = 0;
    marketAdventureInfo.mCDCloseKey = "ActivityCloseTimes";

    mAuctionInfo = {}--黑色商人，竞拍相关信息 
    mAuctionInfo.mDropInfo = {};
    mAuctionInfo.mLeftTimes = 0;
    mAuctionInfo.mCurPrices = 0;
    mAuctionInfo.mMyPrices = 0;
    mAuctionInfo.mCDTimeKey = "AuctionLeftTimes";
end
function CHECKSTERIOUSSTATE()
    if SteriousIsClose then
        MessageBoxPage:Msg_Box("@ActivityCloseTex");
        return true;
     else
        return false;
    end
end
function CLOSESTERIOUSSHOP()
    SteriousIsClose = true;
    NodeHelper:setStringForLabel(SteriousShopPage.container, { mBlackMarketRefreshTimes = "0"})
    NodeHelper:setStringForLabel(SteriousShopPage.container, { mBlackMarketClostTime = common:getLanguageString('@ActivityCloseTex')})

end
local function sendMsgForDropsInfo( container, dType, itemId)
	local msg = Shop_pb.SteriousShopInfoMsg();
	msg.type = dType;
	msg.itemId = tostring(itemId);

	local pb_data = msg:SerializeToString();
	container:sendPakcet(opcodes.OPCODE_SHOP_DROPS_C, pb_data, #pb_data, true);
end
local function sendMsgForAuctionInfo( container, dType, prices)
	local msg = Shop_pb.AuctionInfoMsg();
	msg.type = dType;
	msg.auctionprices = prices;
	local pb_data = msg:SerializeToString();
	container:sendPakcet(opcodes.OPCODE_SHOP_AUCTION_C, pb_data, #pb_data, false);
end

function MarketItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		MarketItem.onRefreshItemView(container);
	end
end

function MarketItem.onSubFunction( eventName, container )
	if eventName == "onbuy" then
        if CHECKSTERIOUSSTATE() then
            return 
        end
		MarketItem.buySingleDrop(container);
	elseif eventName == "onHand" then
		MarketItem.showTip(container);
	end
end

function MarketItem.showTip(container)
	local index = container:getTag();
	local item = marketAdventureInfo.dropsItems[index];
	if item == nil then return; end
	
	local stepLevel = EquipManager:getEquipStepById(item.itemId)

	GameUtil:showTip(container:getVarNode('mHand'), {
		type 		= item.itemType, 
		itemId 		= item.itemId,
		buyTip		= true,
		starEquip	= stepLevel == GameConfig.ShowStepStar
	});
end

function MarketItem.onTipClick() 
    CCLuaLog("this is a on tip Click")
end

--刷新商店content,一个里面有三个物品
function MarketItem.onRefreshItemView(container)
    local ResManagerForLua = require("ResManagerForLua");
    local Const = require('Const_pb');
    local NodeHelper = require("NodeHelper");
	local contentId = container:getItemDate().mID;

	local currenTeamInfo = dropsItemsTeam[contentId];
	local infoSize = table.maxn(currenTeamInfo);

	for i = 1, infoSize, 1 do
		local itemInfo = currenTeamInfo[i];

		local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemInfo.itemType, itemInfo.itemId, itemInfo.itemCount);

		local tag = MarketItem.getMainInfoIndexById(itemInfo.id);
		local subContainer = ScriptContentBase:create(MarketItemSub.ccbiFile,tag);
        subContainer:registerFunctionHandler(MarketItem.onSubFunction);
		--label
		local dropStr = 
		{
			mNumber = "x"..itemInfo.itemCount,
			mCommodityName = tostring(resInfo.name),
			--mCommodityNum = tostring(itemInfo.buyPrice)

            mCommodityNum = GameUtil:formatNumber(itemInfo.buyPrice)
		};

		NodeHelper:setStringForLabel(subContainer, dropStr);

		--image
		NodeHelper:setSpriteImage(subContainer,{mPic = resInfo.icon});

		NodeHelper:setMenuItemQuality(subContainer, "mHand", resInfo.quality);
		NodeHelper:setQualityBMFontLabels(subContainer, {mCommodityName = resInfo.quality});

		local percentPic,percentStr = MarketItem.getPercentTextureStr(itemInfo.buyDiscont);
		if percentPic == nil then
			NodeHelper:setNodesVisible(subContainer,{mLabel = false});
			NodeHelper:setNodesVisible(subContainer,{mLabelContent = false});
		else
			NodeHelper:setNodesVisible(subContainer,{mLabel = true});
			NodeHelper:setNodesVisible(subContainer,{mLabelContent = true});
			NodeHelper:setSpriteImage(subContainer,{mLabel = percentPic});
			NodeHelper:setStringForLabel(subContainer,{mLabelContent = Language:getInstance():getString(percentStr)})
		end

		local mainType = ResManagerForLua:getResMainType(resInfo.itemType);

		if mainType == Const.TOOL then
			NodeHelper:setNodesVisible(subContainer,{mLv = false, mNumber = true});
		elseif mainType == Const.EQUIP then
			local equipLevel = EquipManager:getLevelById(itemInfo.itemId);
			NodeHelper:setStringForLabel(subContainer, {mLv = "Lv."..equipLevel});
			NodeHelper:setNodesVisible(subContainer,{mLv = true, mNumber = false});
		else
			NodeHelper:setNodesVisible(subContainer,{mLv = false, mNumber = false});
		end

		local iconPic = "";
		if itemInfo.buyType == iConType.type_Coins then
			iconPic = iConType.type_Coins_Pic;
		elseif itemInfo.buyType == iConType.type_Gold then
			iconPic = iConType.type_Gold_Pic;
		end
		NodeHelper:setSpriteImage(subContainer,{mConsumptionType = iconPic});

		if itemInfo.isAdd then
			NodeHelper:setNodesVisible(subContainer,{mPanel01 = true});
		else
			NodeHelper:setNodesVisible(subContainer,{mPanel01 = false});
		end

		--add node
		local mainNodeName = "mPosition"..tostring(i);
		local mainNode = container:getVarNode(mainNodeName);
		mainNode:removeAllChildren();
		mainNode:addChild(subContainer);
		subContainer:release();
	end

end

--根据物品信息，得到content id即index（list中）
function MarketItem.getMainInfoIndexById( id )
	local maxSize = table.maxn(marketAdventureInfo.dropsItems);
	for i = 1,maxSize,1 do
		local item = marketAdventureInfo.dropsItems[i];

		if item.id == id then
			return i;
		end
	end

	return nil;
end

--根据content id即index（list中）,得到物品信息
function MarketItem.getIdByMainInfoIndex( index )
	local item = marketAdventureInfo.dropsItems[index];

	if item ~= nil then
		return item.id;
	end

	return nil;
end

--得到折扣图片
function MarketItem.getPercentTextureStr( percentCount )
	if percentCount == PercentItem.eight_percent then
		return "ShopPage_DiscountRed1.png","@FairContentOnSale8"
	elseif percentCount == PercentItem.five_percent then
		return "ShopPage_DiscountRed2.png","@FairContentOnSale5"
	elseif percentCount == PercentItem.one_percent then
		return "ShopPage_DiscountYellow.png","@FairContentOnSale1"
	else
		return nil,nil
	end
end


----------------------------------------------------------------------------------
	
-----------------------------------------------

----------------------------------------------
function SteriousShopPage:onLoad( container )
    local NodeHelper = require("NodeHelper");
	container:loadCcbiFile(option.ccbiFile);
	NodeHelper:initScrollView(container, "mContent", 3);
	MainContainer = container;
end

function SteriousShopPage:onEnter(container)

    
    SteriousShopPage.container = container
    container.scrollview=container:getVarScrollView("mContent");
	if container.scrollview~=nil then
		container:autoAdjustResizeScrollview(container.scrollview);
	end

	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
    SteriousIsClose = false;
    NodeHelper:setStringForLabel(container, { mBlackMarketRefreshTimes = "0"})
    RESETINFO_MARKET();
	self:registerPacket(container)
	container:registerMessage(MSG_MAINFRAME_CHANGEPAGE)
	container:registerMessage(MSG_MAINFRAME_REFRESH);

	self:openDropsMarket(container);
	
	self:refreshBasicInfo( container );
    local visibleMap = 
	{
		mBuyGoldNum2 = false
	}

	NodeHelper:setNodesVisible(container, visibleMap);

	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_STERIOUS_SHOP)--help
    local sprite2Img = {
		mVip		= UserInfo.getVipImage()
	};
	NodeHelper:setSpriteImage(container, sprite2Img);--vip pic

    NodeHelper:setLabelOneByOne(container,"mBlackMarketRefreshTitle","mBlackMarketRefresh",5) -- 对齐
    NodeHelper:setLabelOneByOne(container,"BlackMarketRefreshTimesTitle","mBlackMarketRefreshTimes",5)
    --屏蔽掉竞拍
   -- NodeHelper:setMenuItemEnabled(container,"mAuctionBtn",false);
    local strTips = common:getLanguageString('@UnOpen');
    NodeHelper:setStringForLabel(container, { mAutionLeftTime = strTips})
    --屏蔽掉竞拍
    --[[mAuctionInfo.mLeftTimes = 60*60*24 + 20;
     if Golb_Platform_Info.is_win32_platform then
        if mAuctionInfo.mLeftTimes > 0 then 
            TimeCalculator:getInstance():createTimeCalcultor(mAuctionInfo.mCDTimeKey, mAuctionInfo.mLeftTimes)
        end
    ]]--
end

--刷新页面基本信息，lv,vip等
function SteriousShopPage:refreshBasicInfo( container )
    local NodeHelper = require("NodeHelper");
	UserInfo.syncPlayerInfo();
	local pageInfo = 
	{
		mMailPromptTex = mailNoticeStr,
		mLV = common:getR2LVL() .. UserInfo.roleInfo.level,
		mVip = "VIP " .. UserInfo.playerInfo.vipLevel,
		mCoin = UserInfo.playerInfo.coin,
		mGold = UserInfo.playerInfo.gold
	}

	NodeHelper:setStringForLabel(container, pageInfo);
end

function SteriousShopPage:onExecute(container)
    local cdString = '00:00:00'
    
    if TimeCalculator:getInstance():hasKey(marketAdventureInfo.mCDCloseKey) then --活动剩余时间
		local timeleft = TimeCalculator:getInstance():getTimeLeft(marketAdventureInfo.mCDCloseKey)
		if timeleft > 60*60*24 then
			 cdString = common:second2DateString(timeleft, false);
             NodeHelper:setStringForLabel(container, { mBlackMarketClostTime = cdString})
        elseif timeleft > 0 then
              cdString = GameMaths:formatSecondsToTime(timeleft)
              NodeHelper:setStringForLabel(container, { mBlackMarketClostTime = cdString})
        elseif timeleft == 0 then
               self:clearAllItem(container);
               CLOSESTERIOUSSHOP()--关闭活动
               TimeCalculator:getInstance():removeTimeCalcultor(marketAdventureInfo.mCDCloseKey);
		end

	end
	cdString = '00:00:00'
	if TimeCalculator:getInstance():hasKey(mAuctionInfo.mCDTimeKey) then --竞拍自动刷新剩余时间
		local timeleft = TimeCalculator:getInstance():getTimeLeft(mAuctionInfo.mCDTimeKey)
		if timeleft > 60*60*24 then
			 cdString = common:second2DateString(timeleft, false);
        elseif timeleft > 0 then
              cdString = GameMaths:formatSecondsToTime(timeleft)
		end
         NodeHelper:setStringForLabel(container, { mAutionLeftTime = cdString})
	end
    cdString = '00:00:00'
    if TimeCalculator:getInstance():hasKey(marketAdventureInfo.mCDTimeKey) then --自动刷新剩余时间
		local timeleft = TimeCalculator:getInstance():getTimeLeft(marketAdventureInfo.mCDTimeKey)
		if timeleft >= 0 then
			 cdString = GameMaths:formatSecondsToTime(timeleft)
             NodeHelper:setStringForLabel(container, { mBlackMarketRefresh = cdString})
             NodeHelper:setLabelOneByOne(container,"mBlackMarketRefreshTitle","mBlackMarketRefresh",5)
             if timeleft == 0  then
                TimeCalculator:getInstance():createTimeCalcultor("DelayRefresh", 1)--延时N秒 自动刷新
                TimeCalculator:getInstance():removeTimeCalcultor(marketAdventureInfo.mCDTimeKey);
            end
		end
	end
    if TimeCalculator:getInstance():hasKey("DelayRefresh") then --00:00:00后 延时N秒自动刷新商品
		local timeleft = TimeCalculator:getInstance():getTimeLeft("DelayRefresh")
        if timeleft == 0 then
              TimeCalculator:getInstance():removeTimeCalcultor("DelayRefresh");
              if SteriousIsClose then
                    return 
              end
              sendMsgForDropsInfo(container,ShopInfoType.TYPE_INIT_INFO,0);
        end
	end


end

function SteriousShopPage:onExit(container)
	self:removePacket(container)
    local NodeHelper = require("NodeHelper");
	container:removeMessage(MSG_MAINFRAME_CHANGEPAGE)	
	container:removeMessage(MSG_MAINFRAME_REFRESH);
	NodeHelper:deleteScrollView(container);
    TimeCalculator:getInstance():removeTimeCalcultor(marketAdventureInfo.mCDTimeKey);
    TimeCalculator:getInstance():removeTimeCalcultor(mAuctionInfo.mCDTimeKey);
	mRebuildLock = true;
end
----------------------------------------------------------------

function SteriousShopPage:refreshPage(container)

	self:openDropsMarket(container);
	

	self:refreshBasicInfo( container );
end
--刷新物品商店页面
function SteriousShopPage:rebuildAllItem(container)
     --预防同一时间刷新多次
    if mRebuildLock then
        mRebuildLock = false
        self:clearAllItem(container);
        self:buildItem(container);
        
        --延迟1s
        container:runAction(
			CCSequence:createWithTwoActions(
				CCDelayTime:create(0.3),
				CCCallFunc:create(function()
					mRebuildLock = true;
					--判断是否有未被刷新的情况存在，无论未被刷新多少次都只重新刷新一次
					if mRefreshCout > 0 then
					    mRefreshCout = 0
					    self:rebuildAllItem(container)
					end
				end)
			)
		);
	else
	--记录下未被刷新的次数
	    mRefreshCout = mRefreshCout + 1;
	end
end

function SteriousShopPage:clearAllItem(container)
    local NodeHelper = require("NodeHelper");
	NodeHelper:clearScrollView(container);
end

function SteriousShopPage:buildItem(container)
	self:cutDropsInfoForTeam(container);
    local NodeHelper = require("NodeHelper");
	local contentsSize = table.maxn(dropsItemsTeam);
	NodeHelper:buildScrollView(container, contentsSize, MarketItem.ccbiFile, MarketItem.onFunction);
end

local function sortFunc( m1, m2 )
	if not m1 then return true end
	if not m2 then return false end

	if m1.isAdd and not m2.isAdd then
		return true;
	elseif (not m2.isAdd and m1.isAdd) then
		return false;
	else 
		return m1.id > m2.id;
	end

end

--物品按3个3个一组进行分割
function SteriousShopPage:cutDropsInfoForTeam( container )

	local maxSize = table.maxn(marketAdventureInfo.dropsItems);
	--服务器来排序，客户端省去排序操作
	--table.sort(marketAdventureInfo.dropsItems, sortFunc);
	MAIL_ISSORTED = true;

	local teamId = 1;
	dropsItemsTeam = {};
	dropsItemsTeam[teamId] = {};
	local count = 1;
	local currentTeam = {};

	for i = 1, maxSize, 1 do
		if count < 4 then
			currentTeam[count] = marketAdventureInfo.dropsItems[i];
			count = count + 1;
		else
			dropsItemsTeam[teamId] = {};
			self:copyItems( teamId, currentTeam )
			currentTeam = {};
			count = 1;
			teamId = teamId + 1;

			currentTeam[count] = marketAdventureInfo.dropsItems[i];
			count = count + 1;
		end

		if i + 1 > maxSize then
			if table.maxn(currentTeam) > 0 then
				self:copyItems( teamId, currentTeam );
			end
		end
	end
end

function SteriousShopPage:copyItems( index, currentTeam )
	local maxSize = table.maxn(currentTeam);
	dropsItemsTeam[index] = {};
	for i = 1, maxSize, 1 do
		local item = currentTeam[i];
		dropsItemsTeam[index][i] = {};
		dropsItemsTeam[index][i].id = item.id;
		dropsItemsTeam[index][i].itemId = item.itemId;
		dropsItemsTeam[index][i].itemType = item.itemType;
		dropsItemsTeam[index][i].itemCount = item.itemCount;
		dropsItemsTeam[index][i].buyType = item.buyType;
		dropsItemsTeam[index][i].buyPrice = item.buyPrice;
		dropsItemsTeam[index][i].buyDiscont = item.buyDiscont;
		dropsItemsTeam[index][i].level = item.level;
		dropsItemsTeam[index][i].isAdd = item.isAdd;
	end
end

-------------------------------------------------------------------------
function SteriousShopPage:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function SteriousShopPage:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode);
		end
	end
end	

function SteriousShopPage:onReceivePacket(container)
    local Consume_pb = require("Consume_pb")
    local Reward_pb = require "Reward_pb"
	local opcode = container:getRecPacketOpcode()

	local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.OPCODE_SHOP_AUCTION_S then
		local msg = Shop_pb.AuctionInfoMsgRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveAuctionInfo(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_SHOP_DROPS_S then
		local msg = Shop_pb.SteriousShopInfoMsgRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveDropsInfo(container, msg)
		return
	end
	
	if opcode == opcodes.OPCODE_PLAYER_AWARD_S then
	    local msg = Reward_pb.HPPlayerReward();
	    msg:ParseFromString(msgBuff)
	    if msg:HasField("rewards") then
            if msg.rewards:HasField("gold")
                    or msg.rewards:HasField("coin")
                    or msg.rewards:HasField("level")
                    or msg.rewards:HasField("exp")
                    or msg.rewards:HasField("vipLevel")
                    then				
                    self:refreshBasicInfo( container )
            end
	    end
	    return
	end
	
	if opcode == opcodes.OPCODE_PLAYER_CONSUME_S then 
	    local msg = Consume_pb.HPConsumeInfo();
		msg:ParseFromString(msgBuff);
	    if msg:HasField("attrInfo") then
			if msg.attrInfo:HasField("gold")
				or msg.attrInfo:HasField("coin")
				or msg.attrInfo:HasField("level")
				or msg.attrInfo:HasField("exp")
				or msg.attrInfo:HasField("vipLevel")
				then
				self:refreshBasicInfo( container )
			end
	    end
	    return 
	end
end

function SteriousShopPage:onReceiveAuctionInfo( container, msg )

    local ResManagerForLua = require("ResManagerForLua");

	mAuctionInfo.mDropInfo = msg.drop;
    mAuctionInfo.mLeftTimes = msg.lefttimes;
    mAuctionInfo.mCurPrices = msg.curprices;
    mAuctionInfo.mMyPrices = msg.myprices

    --收包后显示剩余刷新时间
    if mAuctionInfo.mLeftTimes >= 0 then 
        TimeCalculator:getInstance():createTimeCalcultor(mAuctionInfo.mCDTimeKey, mAuctionInfo.mLeftTimes)
    end
  --收包后显示剩余刷新时间
  self:InitAuctionDropsInfo(container);

end
function SteriousShopPage:InitAuctionDropsInfo(container)--初始化竞拍物品信息
     --构建竞猜物品信息
    local ResManagerForLua = require("ResManagerForLua");
    local Const = require('Const_pb');
    local NodeHelper = require("NodeHelper");
	
	local itemInfo = mAuctionInfo.mDropInfo;

	local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemInfo.itemType, itemInfo.itemId, itemInfo.itemCount);

	local subContainer = ScriptContentBase:create(MarketItemSub.ccbiFile,10);
	subContainer:registerFunctionHandler(SteriousShopPage.onHand);

	--label
	local dropStr = 
	{
		mNumber = "X"..itemInfo.itemCount,
		mCommodityName = tostring(resInfo.name),
		mCommodityNum = "123"
	};

	NodeHelper:setStringForLabel(subContainer, dropStr);

	--image
	NodeHelper:setSpriteImage(subContainer,{mPic = resInfo.icon});

	NodeHelper:setMenuItemQuality(subContainer, "mHand", resInfo.quality);
	NodeHelper:setQualityBMFontLabels(subContainer, {mCommodityName = resInfo.quality});


	local mainType = ResManagerForLua:getResMainType(resInfo.itemType);

	if mainType == Const.TOOL then
		NodeHelper:setNodesVisible(subContainer,{mLv = false, mNumber = true});
	elseif mainType == Const.EQUIP then
		local equipLevel = EquipManager:getLevelById(itemInfo.itemId);
		NodeHelper:setStringForLabel(subContainer, {mLv = "Lv."..equipLevel});
		NodeHelper:setNodesVisible(subContainer,{mLv = true, mNumber = false});
	else
		NodeHelper:setNodesVisible(subContainer,{mLv = false, mNumber = false});
	end

	local iconPic = "";
	if itemInfo.buyType == iConType.type_Coins then
		iconPic = iConType.type_Coins_Pic;
	elseif itemInfo.buyType == iConType.type_Gold then
		iconPic = iConType.type_Gold_Pic;
	end
	NodeHelper:setSpriteImage(subContainer,{mConsumptionType = iconPic});

	--add node
	local mainNodeName = "mPic"
	local mainNode = container:getVarNode(mainNodeName);
	mainNode:removeAllChildren();
	mainNode:addChild(subContainer);
	subContainer:release();
	
end

function SteriousShopPage:onReceiveDropsInfo( container, msg )
    local ResManagerForLua = require("ResManagerForLua");
	if msg.type == ShopInfoType.TYPE_BUY_SINGLE then
		if msg.item ~= nil then
			--local resInfo = ResManagerForLua:getResInfoByTypeAndId(msg.item.itemType, msg.item.itemId, msg.item.itemCount);
			--local str = resInfo.name .."X" ..resInfo.count;
			--local messageStr = common:getLanguageString("@BuySuccess", str);
			--MessageBoxPage:Msg_Box(messageStr);
		end
	elseif msg.type == ShopInfoType.TYPE_BUY_ALL then
		--MessageBoxPage:Msg_Box("@BuyAllSuccess");
	elseif msg.type == ShopInfoType.TYPE_INIT_INFO then

	end

    marketAdventureInfo.mCloseTimes = msg.activitylefttimes;
    if marketAdventureInfo.mCloseTimes == 0 then
        TimeCalculator:getInstance():createTimeCalcultor(marketAdventureInfo.mCDCloseKey, 0)
        return
    end
	marketAdventureInfo.dropsItems = msg.shopItems;
	marketAdventureInfo.refreshCount = msg.refreshCount;
    marketAdventureInfo.refreshPrice = msg.refreshPrice
    marketAdventureInfo.mLeftTimes = msg.lefttimes
    marketAdventureInfo.mCloseTimes = msg.activitylefttimes + 1;--服务器 强行让我+1秒。msg.lefttimes 和 activitylefttimes相差一秒
	self:refreshBasicInfo( container )
	self:rebuildAllItem(container);
    --收包后显示剩余刷新时间
    if marketAdventureInfo.mLeftTimes >= 0 then 
        TimeCalculator:getInstance():createTimeCalcultor(marketAdventureInfo.mCDTimeKey, marketAdventureInfo.mLeftTimes)
    end
    if marketAdventureInfo.mCloseTimes >= 0 then 
        TimeCalculator:getInstance():createTimeCalcultor(marketAdventureInfo.mCDCloseKey, marketAdventureInfo.mCloseTimes)
        --TimeCalculator:getInstance():createTimeCalcultor(marketAdventureInfo.mCDCloseKey, 5)
    end
    NodeHelper:setStringForLabel(container, { mBlackMarketRefreshTimes = tostring(marketAdventureInfo.refreshCount)})
    NodeHelper:setLabelOneByOne(container,"BlackMarketRefreshTimesTitle","mBlackMarketRefreshTimes",5)

    --收包后显示剩余刷新时间
   -- mAuctionInfo.mDropInfo = marketAdventureInfo.dropsItems[1];
   --self:InitAuctionDropsInfo(container);
end

function SteriousShopPage:refreshItemsData(newItems)
	-- body
end

-----------------------切换到物品商店页面-------------------------------------
function SteriousShopPage:openDropsMarket( container )
	if marketAdventureInfo.dropsItems ~= nil then
		self:rebuildAllItem(container);
	end
	sendMsgForDropsInfo( container, ShopInfoType.TYPE_INIT_INFO, 0);
    --sendMsgForAuctionInfo( container, ShopAuctionType.TYPE_INIT_INFO, 0);
end
function SteriousShopPage:onAution( container )
    local strTips = common:getLanguageString('@UnOpen');
    MessageBoxPage:Msg_Box(strTips);
    --PageManager.pushPage("SteriousAuctionPage");
end
function SteriousShopPage:onReturnButton( container )
    PageManager.changePage("ActivityPage");
    --PageManager.pushPage("SteriousAuctionPage");
end

function SteriousShopPage:onHand( container )

	--[[local item = mAuctionInfo.mDropInfo;
	if item == nil then return; end
	
	local stepLevel = EquipManager:getEquipStepById(item.itemId)

	GameUtil:showTip(container:getVarNode('mHand'), {
		type 		= item.itemType, 
		itemId 		= item.itemId,
		buyTip		= true,
		starEquip	= stepLevel == GameConfig.ShowStepStar
	});]]--
end

--购买所有物品
function SteriousShopPage:onBuyAll( container )
    if CHECKSTERIOUSSTATE() then
            return 
    end
    if Golb_Platform_Info.is_entermate_platform then
        if #marketAdventureInfo.dropsItems > 0 then
            local  allGold = 0;
            for i=1, #marketAdventureInfo.dropsItems do  
                allGold = allGold + marketAdventureInfo.dropsItems[i].buyPrice;
            end
            
            if UserInfo.isGoldEnough(allGold) then
                local titile = common:getLanguageString("@OnBuyTitle");
	            local tipinfo = common:getLanguageString("@MarketBuyAll");
	            PageManager.showConfirm(titile,tipinfo, function(isSure)
	            if isSure then
                    if CHECKSTERIOUSSTATE() then
                            return 
                    end
			        sendMsgForDropsInfo( container, ShopInfoType.TYPE_BUY_ALL, 0);
		        end
	            end);
            end
        else
             local strTips = common:getLanguageString('@NoItemInfo');
             MessageBoxPage:Msg_Box(strTips);
        end
	    
    else
	    sendMsgForDropsInfo( container, ShopInfoType.TYPE_BUY_ALL, 0);
    end
	
end

--购买单个金币，或者刷新物品商店
function SteriousShopPage:onBuyCoinsOrRefreshDrops( container )
    if CHECKSTERIOUSSTATE() then
            return 
    end
	self:popRefreshBox(container);
	
end

--弹出刷新页面
function SteriousShopPage:popRefreshBox( container )
   
    --[[
	local max = table.maxn(RefreshCostCfg);
	local cost = 0;
	if marketAdventureInfo.refreshCount <= max then
		cost = RefreshCostCfg[marketAdventureInfo.refreshCount].cost;
	else
		cost = RefreshCostCfg[max].cost;
	end

    ]]
    if marketAdventureInfo.refreshCount == 0 then
         local strTips = common:getLanguageString("@NoRefreshTimes");
         MessageBoxPage:Msg_Box(strTips);
    else
	    local refreshFunc = function ( isOK )
		    if isOK and UserInfo.isCoinEnough( marketAdventureInfo.refreshPrice ) then
                if CHECKSTERIOUSSTATE() then
                            return 
                    end
			    sendMsgForDropsInfo(container, ShopInfoType.TYPE_REFRESH, 0);
		    end
	    end

	    local title = common:getLanguageString("@ShopRefreshTitle");
	    local msg = common:getLanguageString("@RefreshCoinPrices",marketAdventureInfo.refreshPrice);

	    PageManager.showConfirm(title, msg, refreshFunc);
    end
end

--帮助页面
function SteriousShopPage:onHelp( container )

	PageManager.showHelp(GameConfig.HelpKey.HELP_STERIOUS_SHOP)

end

--购买单个道具
function MarketItem.buySingleDrop(container)
	local index = container:getTag();
	local item = marketAdventureInfo.dropsItems[index];
	if item == nil then return; end
	
	--local id = MarketItem.getIdByMainInfoIndex(index);
	if ( item.buyType == iConType.type_Coins and not UserInfo.isCoinEnough(item.buyPrice) )
		or ( item.buyType == iConType.type_Gold and not UserInfo.isGoldEnough(item.buyPrice) )
	then
		return;
	end

     if Golb_Platform_Info.is_entermate_platform then
			local titile = common:getLanguageString("@OnBuyTitle");
			local tipinfo = common:getLanguageString("@OnBuyTips");
			PageManager.showConfirm(titile,tipinfo, function(isSure)
			if isSure then
                    if CHECKSTERIOUSSTATE() then
                            return 
                    end
					sendMsgForDropsInfo(MainContainer, ShopInfoType.TYPE_BUY_SINGLE, item.id);
				end
			end);
	else
		sendMsgForDropsInfo(MainContainer, ShopInfoType.TYPE_BUY_SINGLE, item.id);
	end
end

function SteriousShopPage:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
		if pageName == thisPageName then
			--self:refreshBasicInfo(container);
			if extraParam == "TopMsgUpdate" then
			    SteriousShopPage:refreshBasicInfo( container )
			    return
			end
			self:refreshPage(container);
		end
	elseif typeId == MSG_MAINFRAME_CHANGEPAGE then
		local pageName = MsgMainFrameChangePage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:refreshPage(container);
		end
	end
end

-------------------------------------------------------------------------


local CommonPage = require("CommonPage");
local MarketPage = CommonPage.newSub(SteriousShopPage, thisPageName, option);
