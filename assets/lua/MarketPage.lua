----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local thisPageName = "MarketPage"
local HP = require("HP_pb")
local Const_pb = require("Const_pb")
local NodeHelper = require("NodeHelper")
require("Shop_pb")
require("CrystalShop_pb")

local EquipOpr_pb = require("EquipOpr_pb")
local EquipOprHelper = require("EquipOprHelper")
local ResManagerForLua = require("ResManagerForLua")
local ItemManager = require("Item.ItemManager")

local UserInfo = require("PlayerInfo.UserInfo")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
------------local variable for system global api--------------------------------------
local tostring = tostring
local string = string
local pairs = pairs
--------------------------------------------------------------------------------
local mRebuildLock = true
local mRefreshCout = 0

local MarketPageBase = {}

local MarketItem = 
{
	ccbiFile = "FairContentItem.ccbi",
}

local MarketItemSub = 
{
	ccbiFile = "FairContent.ccbi",
}

local opcodes = 
{
	OPCODE_SHOP_DROPS_C = HP.SHOP_C,
	OPCODE_SHOP_DROPS_S = HP.SHOP_S,
	OPCODE_SHOP_COINS_C = HP.SHOP_COIN_C,
	OPCODE_SHOP_COINS_S = HP.SHOP_COIN_S,
	EQUIP_STONE_BUY_C = HP.EQUIP_STONE_BUY_C,
	EQUIP_STONE_BUY_S = HP.EQUIP_STONE_BUY_S,
	OPCODE_PLAYER_AWARD_S = HP.PLAYER_AWARD_S,
	OPCODE_PLAYER_CONSUME_S = HP.PLAYER_CONSUME_S,
	OPCODE_CRYSTAL_SHOP_LIST_S = HP.CRYSTAL_SHOP_LIST_S,
	OPCODE_CRYSTAL_SHOP_BUY_S = HP.CRYSTAL_SHOP_LIST_S,
	OPCODE_CRYSTAL_SHOP_REFRESH_S = HP.CRYSTAL_SHOP_REFRESH_S,
}

--商店类型
local iConType = 
{
	type_Coins = 1,
	type_Gold = 2,
--	type_Coins_Pic = "UI/MainScene/Common/u_CmnCoin.png",
--	type_Gems_Pic = "UI/MainScene/Common/u_CmnGem.png",
--	type_Gold_Pic = "UI/MainScene/Common/u_CmnGold.png",
--	type_Crystal_Pic = "UI/MainScene/Common/u_CmnSuit.png",

    type_Coins_Pic = "common_ht_jinbi_img.png",
	type_Gems_Pic = "Icon_Gem_S.png",
	type_Gold_Pic = "common_ht_zuanshi_img.png",
	type_Crystal_Pic = "Icon_Suit_S.png",
}

local deviceHeight = CCDirector:sharedDirector():getWinSize().height
local isIpad = deviceHeight < 900
 
local option = {
	ccbiFile = isIpad and "FairPage_ipad.ccbi" or "FairPage.ccbi",
	handlerMap = {
		onGoblinmerchant		= "openDropsMarket",
		onBuyGold			= "openCoinsMarket",
		onBuyGem			= "openGemsMarket",
		onBuySuit			= "openSuitsMarket",
		onBuyAll				= "onBuyAll",
		onBrush				= "onBuyCoinsOrRefreshDrops",
		onHelp			= "onHelp",
		onReturn		= "onReturn",
		onOpenUi		= "onOpenUi",
		onBrushSuit		= "onBrushSuit",
	},
	opcode = opcodes
}

--商店购买类型
local ShopInfoType = 
{
	TYPE_INIT_INFO = 1,
	TYPE_BUY_SINGLE = 2,
	TYPE_BUY_ALL = 3,
	TYPE_REFRESH = 4
}

local MainContainer = nil

--商店被选择的类型
local ShopSelectedState = 
{
	STATE_DROPS = 1,
	STATE_COINS = 2,
	STATE_GEMS 	= 3,
	STATE_SUITS = 4
}
--商店商品List信息
marketAdventureInfo = 
{
	dropsItems = {},
	coinReward = 0,
	coinCost = 0,
	coinCount = 0,
    refreshPrice = 50
}

local dropsItemsTeam = 
{

}

local gemItems = {
	
}

local suitItems = {} --套装数据
--商店当前选择类型
SHOP_CURRENT_STATE = ShopSelectedState.STATE_DROPS

--折扣信息
local PercentItem = 
{
	eight_percent = 80,
	five_percent = 50,
	one_percent = 10
}

local ITEM_COUNT_PER_LINE = 3

local VipConfig = ConfigManager.getVipCfg()
local RefreshCostCfg = ConfigManager.getRefreshMarketCostCfg()

-----------------注销，clear 商店list信息-----------------------------
function RESETINFO_MARKET()
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_DROPS
	marketAdventureInfo = {}
	marketAdventureInfo.dropsItems = {}
	marketAdventureInfo.coinReward = 0
	marketAdventureInfo.coinCost = 0
	marketAdventureInfo.coinCount = 0
end

local function sendMsgForDropsInfo(container, dType, itemId)
	local msg = Shop_pb.OPShopInfo()
	msg.type = dType
	msg.itemId = tostring(itemId)

	local pb_data = msg:SerializeToString()
	container:sendPakcet(opcodes.OPCODE_SHOP_DROPS_C, pb_data, #pb_data, true)
end
function MarketItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		MarketItem.onRefreshItemView(container)
	end
end

function MarketItem.onSubFunction(eventName, container)
	xpcall(function()			
		if eventName == "onbuy" then
			if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
				MarketItem.buySingleDrop(container)
			elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
				MarketItem.buySingleGem(container)
			elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then 
				MarketItem.buySingleSuit(container)
			end
		elseif eventName == "onHand" then
			if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
				MarketItem.showTip(container)
			elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
				MarketItem.showGemTip(container)
			elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then
				MarketItem.showSuitTip(container)
			end			
			
		end
	end, CocoLog)				

end

function MarketItem.showGemTip(container)
	local index = container:getTag()
	if index > #gemItems then
		index = index - #gemItems
	end

	local item = gemItems[index]
	if item == nil then return end

	GameUtil:showTip(container:getVarNode("mHand"), {
		type 		= 30000, 
		itemId 		= item.itemId,
		buyTip		= true
	})
end

function MarketItem.showTip(container)
	local index = container:getTag()
	local item = marketAdventureInfo.dropsItems[index]
	if item == nil then return end
	
	local stepLevel = EquipManager:getEquipStepById(item.itemId)

	GameUtil:showTip(container:getVarNode("mHand"), {
		type 		= item.itemType, 
		itemId 		= item.itemId,
		buyTip		= true,
		starEquip	= stepLevel == GameConfig.ShowStepStar
	})
end

function MarketItem.showSuitTip(container)
	local index = container:getTag()
	local item = suitItems[index]
	if item == nil then return end
	local stepLevel = EquipManager:getEquipStepById(item.itemId)

	GameUtil:showTip(container:getVarNode("mHand"), {
		type 		= item.itemType, 
		itemId 		= item.itemId,
		buyTip		= true,
		starEquip	= stepLevel == GameConfig.ShowStepStar
	})
end

function MarketItem.onTipClick() 
    CCLuaLog("this is a on tip Click")
end

--刷新商店content,一个里面有三个物品
function MarketItem.onRefreshItemView(container)
	local Const = require("Const_pb")
	local contentId = container:getItemDate().mID

	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		local currenTeamInfo = dropsItemsTeam[contentId]
		local infoSize = table.maxn(currenTeamInfo)

		for i = 1, infoSize, 1 do
			local itemInfo = currenTeamInfo[i]

			local resInfo = ResManagerForLua:getResInfoByTypeAndId(itemInfo.itemType, itemInfo.itemId, itemInfo.itemCount)

			local tag = MarketItem.getMainInfoIndexById(itemInfo.id)
			local subContainer = ScriptContentBase:create(MarketItemSub.ccbiFile, tag)
			subContainer:registerFunctionHandler(MarketItem.onSubFunction)

			--label
			local dropStr = 
			{
				mNumber = "x" .. itemInfo.itemCount,
				mCommodityName = tostring(resInfo.name),
				--mCommodityNum = tostring(itemInfo.buyPrice)
                mCommodityNum = GameUtil:formatNumber(itemInfo.buyPrice)
			}

			NodeHelper:setStringForLabel(subContainer, dropStr)

			--image
			NodeHelper:setSpriteImage(subContainer, { mPic = resInfo.icon })

			NodeHelper:setMenuItemQuality(subContainer, "mHand", resInfo.quality)
			NodeHelper:setQualityBMFontLabels(subContainer, {mCommodityName = resInfo.quality})

			NodeHelper:setNodesVisible(subContainer, { mDrawBtn = false })
			-- NodeHelper:setNodesVisible(subContainer, { mExceptDrawBtn = true })

			local percentPic, percentStr = MarketItem.getPercentTextureStr(itemInfo.buyDiscont)
			if percentPic == nil then
				NodeHelper:setNodesVisible(subContainer, { mLabel = false })
				NodeHelper:setNodesVisible(subContainer, { mLabelContent = false })
			else
				NodeHelper:setNodesVisible(subContainer, { mLabel = true })
				NodeHelper:setNodesVisible(subContainer, { mLabelContent = true })
				NodeHelper:setSpriteImage(subContainer, { mLabel = percentPic })
				NodeHelper:setStringForLabel(subContainer, { mLabelContent = Language:getInstance():getString(percentStr) })
			end

			local mainType = ResManagerForLua:getResMainType(resInfo.itemType)

			if mainType == Const.TOOL then
				NodeHelper:setNodesVisible(subContainer, { mLv = false, mNumber = true })
			elseif mainType == Const.EQUIP then
				local equipLevel = EquipManager:getLevelById(itemInfo.itemId)
				NodeHelper:setStringForLabel(subContainer, { mLv = "Lv." .. equipLevel })
				NodeHelper:setNodesVisible(subContainer, { mLv = true, mNumber = false })
			else
				NodeHelper:setNodesVisible(subContainer, { mLv = false, mNumber = false })
			end

			local iconPic = ""
			if itemInfo.buyType == iConType.type_Coins then
				iconPic = iConType.type_Coins_Pic
			elseif itemInfo.buyType == iConType.type_Gold then
				iconPic = iConType.type_Gold_Pic
			end
			NodeHelper:setSpriteImage(subContainer, { mConsumptionType = iconPic })

			if itemInfo.isAdd then
				NodeHelper:setNodesVisible(subContainer, { mPanel01 = true })
			else
				NodeHelper:setNodesVisible(subContainer,{ mPanel01 = false })
			end

			--add node
			local mainNodeName = "mPosition" .. tostring(i)
			local mainNode = container:getVarNode(mainNodeName)
			mainNode:removeAllChildren()
			mainNode:addChild(subContainer)
			subContainer:release()
		end
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
		for i = 1, ITEM_COUNT_PER_LINE do
			local mainNodeName = "mPosition" .. tostring(i)
			local mainNode = container:getVarNode(mainNodeName)
			mainNode:removeAllChildren()
			local dataIndex = (contentId - 1) * ITEM_COUNT_PER_LINE + i
			local gemInfo = gemItems[dataIndex]
			if gemInfo ~= nil then
				local ttype = gemInfo.costType

				local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, gemInfo.itemId, 0)
				-- dump(resInfo)
				local costItem = ConfigManager.parseItemOnlyWithUnderline(gemInfo.costItems)
				local costResInfo = ResManagerForLua:getResInfoByTypeAndId(costItem.type, costItem.itemId, costItem.count)
				local subContainer = ScriptContentBase:create(MarketItemSub.ccbiFile, dataIndex)
				subContainer:registerFunctionHandler(MarketItem.onSubFunction)
				local countStr = ttype == 1 and tostring(gemInfo.costGold) or tostring(costResInfo.count)
				print("countStr", countStr)
				local dropStr = 
				{
					mNumber = "",
					mCommodityName = tostring(resInfo.name),
					--mCommodityNum = countStr;
					mCommodityNum = GameUtil:formatNumber(countStr)
					
				};

				NodeHelper:setStringForLabel(subContainer, dropStr)

				local iconPic = ""
				if ttype == 2 then
					iconPic = iConType.type_Gems_Pic
				else
					iconPic = iConType.type_Gold_Pic
				end
				NodeHelper:setSpriteImage(subContainer, { mConsumptionType = iconPic })
				--image
				NodeHelper:setSpriteImage(subContainer, { mPic = resInfo.icon })

				NodeHelper:setMenuItemQuality(subContainer, "mHand", resInfo.quality)
				NodeHelper:setQualityBMFontLabels(subContainer, { mCommodityName = resInfo.quality })

				NodeHelper:setNodesVisible(subContainer, { mLabel = false })
				NodeHelper:setNodesVisible(subContainer, { mDrawBtn = false })
				-- NodeHelper:setNodesVisible(subContainer, { mExceptDrawBtn = false })
				NodeHelper:setNodesVisible(subContainer, { mLabelContent = false })	

				NodeHelper:setNodesVisible(subContainer, { mLv = false })

				-- NodeHelper:setSpriteImage(subContainer, { mConsumptionType = iConType.type_Gold_Pic })	

				mainNode:addChild(subContainer)
				subContainer:release()
			end
		end
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then
		MarketItem.onRefreshSuitItemView(container, contentId)
	end
end

function MarketItem.onRefreshSuitItemView(container, contentId)
	for i = 1, ITEM_COUNT_PER_LINE do
		local mainNodeName = "mPosition" .. tostring(i)
		local mainNode = container:getVarNode(mainNodeName)
		mainNode:removeAllChildren()
		local dataIndex = (contentId - 1) * ITEM_COUNT_PER_LINE + i
		local data = suitItems[dataIndex]
		if not data then break end
		local resInfo = ResManagerForLua:getResInfoByTypeAndId(data.itemType, data.itemId, 0)
		local subContainer = ScriptContentBase:create(MarketItemSub.ccbiFile, dataIndex)
		subContainer:registerFunctionHandler(MarketItem.onSubFunction)
	    local dropStr = 
		{
			mNumber = "x"..data.itemCount,
			mCommodityName = tostring(resInfo.name),
			--mCommodityNum = data.costCount;
            mCommodityNum = GameUtil:formatNumber(data.costCount)
		}

		NodeHelper:setStringForLabel(subContainer, dropStr)

		local iconPic = iConType.type_Gold_Pic
		if data.costType == 20 then 
			iconPic = iConType.type_Crystal_Pic
		end

		NodeHelper:setSpriteImage(subContainer, { mConsumptionType = iconPic })
		--image
		NodeHelper:setSpriteImage(subContainer, { mPic = resInfo.icon })

		NodeHelper:setMenuItemQuality(subContainer, "mHand", resInfo.quality)
		NodeHelper:setQualityBMFontLabels(subContainer, { mCommodityName = resInfo.quality })

		NodeHelper:setNodesVisible(subContainer, { mLabel = false })
		NodeHelper:setNodesVisible(subContainer, { mDrawBtn = false })
		-- NodeHelper:setNodesVisible(subContainer,{mExceptDrawBtn = false})
		NodeHelper:setNodesVisible(subContainer, { mLabelContent = false })

		NodeHelper:setNodesVisible(subContainer, { mLv = false })

		-- NodeHelper:setSpriteImage(subContainer,{ mConsumptionType = iConType.type_Gold_Pic })	

		mainNode:addChild(subContainer)
		subContainer:release()
	end
end

--根据物品信息，得到content id即index（list中）
function MarketItem.getMainInfoIndexById(id)
	local maxSize = table.maxn(marketAdventureInfo.dropsItems)
	for i = 1, maxSize, 1 do
		local item = marketAdventureInfo.dropsItems[i]

		if item.id == id then
			return i
		end
	end

	return nil
end

--根据content id即index（list中）,得到物品信息
function MarketItem.getIdByMainInfoIndex(index)
	local item = marketAdventureInfo.dropsItems[index]

	if item ~= nil then
		return item.id
	end

	return nil
end

--得到折扣图片
function MarketItem.getPercentTextureStr(percentCount)
	if percentCount == PercentItem.eight_percent then
		return "ShopPage_DiscountRed1.png", "@FairContentOnSale8"
	elseif percentCount == PercentItem.five_percent then
		return "ShopPage_DiscountRed2.png", "@FairContentOnSale5"
	elseif percentCount == PercentItem.one_percent then
		return "ShopPage_DiscountYellow.png", "@FairContentOnSale1"
	else
		return nil, nil
	end
end

----------------------------------------------------------------------------------

-----------------------------------------------

----------------------------------------------
function MarketPageBase:onLoad(container)
	local NodeHelper = require("NodeHelper")
	container:loadCcbiFile(option.ccbiFile)
	NodeHelper:initScrollView(container, "mContent", 3)
	MainContainer = container
end

function MarketPageBase:onEnter(container)
    container.scrollview=container:getVarScrollView("mContent")
	if container.scrollview ~= nil then
		container:autoAdjustResizeScrollview(container.scrollview)
	end

	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite(mScale9Sprite)
	end

	self:registerPacket(container)
	container:registerMessage(MSG_MAINFRAME_CHANGEPAGE)
	container:registerMessage(MSG_MAINFRAME_REFRESH)

	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_COINS then
		self:openCoinsMarket(container)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		self:openDropsMarket(container)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
		self:openGemsMarket(container)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then
		self:openSuitsMarket(container)
	end

	self:refreshBasicInfo(container)

	self:rebuildCoinsInfo(container)

	--self:refreshPage(container)
	--self:rebuildAllItem(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_MARKET_ITEM)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
		NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_MARKET_GOLD)
	else
		NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_MARKET_GEM)
	end

	---水晶商店开启45级限制
	NodeHelper:setNodesVisible(container, {buySuitNode = false})
	if UserInfo.level >= GameConfig.SuitShopLevelLimit then
		NodeHelper:setNodesVisible(container, {buySuitNode = true})
	end
end

--刷新页面基本信息，lv,vip等
function MarketPageBase:refreshBasicInfo(container)
	local NodeHelper = require("NodeHelper")
	local coinStr = GameUtil:formatNumber(UserInfo.playerInfo.coin)

	local costCount = 1
	if gemItems and gemItems[1] then
		local costInfo = ConfigManager.parseItemOnlyWithUnderline(gemItems[1].costItems)
		local priRes = ResManagerForLua:getResInfoByTypeAndId(costInfo.type, costInfo.itemId, costInfo.count, true)
		costCount = priRes.count
	end
	UserInfo.syncPlayerInfo()
	local pageInfo = 
	{
		mMailPromptTex = mailNoticeStr,
		mLV = UserInfo.getStageAndLevelStr(),
		mVip = "VIP " .. UserInfo.playerInfo.vipLevel,
		mCoin = coinStr, --UserInfo.playerInfo.coin,
		mGold = UserInfo.playerInfo.gold,
		mDraw = tostring(costCount),
		mGold1 = UserInfo.playerInfo.gold,
		mVip1 = "VIP " .. UserInfo.playerInfo.vipLevel,
		mSuitShard = UserInfo.playerInfo.crystal,
		mGold2 = UserInfo.playerInfo.gold,
		mVip2 = "VIP " .. UserInfo.playerInfo.vipLevel,
	}

	NodeHelper:setStringForLabel(container, pageInfo)
end

function MarketPageBase:onExecute(container)
end

function MarketPageBase:onExit(container)
	self:removePacket(container)
    local NodeHelper = require("NodeHelper")
	container:removeMessage(MSG_MAINFRAME_CHANGEPAGE)
	container:removeMessage(MSG_MAINFRAME_REFRESH)
	NodeHelper:deleteScrollView(container)
	mRebuildLock = true
end

function MarketPageBase:onReturn(container)
	PageManager.changePage("MainScenePage")
end

function MarketPageBase:onOpenUi(container)
	PageManager.pushPage("SuitDisplayPage")
end

function MarketPageBase:onBrushSuit(container)
	local suitRefreshCostCrystal = self.suitRefreshCostCrystal
	local refreshFunc = function(isOK)
		if isOK then
            if  UserInfo.isGoldEnough(suitRefreshCostCrystal, "ShopRefresh_enter_rechargePage") then
                 common:sendEmptyPacket(HP.CRYSTAL_SHOP_REFRESH_C, false)
            end
		end
	end
    UserInfo.sync()
	local title = common:getLanguageString("@ShopRefreshTitle");
    local msg = ""
    CCLuaLog("leftFreeRefreshShopTimes ====================================== :"..UserInfo.stateInfo.leftFreeRefreshShopTimes)
	msg = common:getLanguageString("@ShopRefreshContent", suitRefreshCostCrystal)

	PageManager.showConfirm(title, msg, refreshFunc)
end
----------------------------------------------------------------

function MarketPageBase:refreshPage(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_COINS then
		self:openCoinsMarket(container)
	else
		self:openDropsMarket(container)
	end

	self:refreshBasicInfo(container)
end

----------------刷新金币商店页面-------------------------
function MarketPageBase:rebuildCoinsInfo(container)
	local NodeHelper = require("NodeHelper")
	UserInfo.syncPlayerInfo()

	local pageInfo = 
	{
		mMailPromptTex = mailNoticeStr,

	}

	NodeHelper:setStringForLabel(container, pageInfo)

	local vipLevel = UserInfo.playerInfo.vipLevel
	local vipCount = VipConfig[vipLevel].buyCoinTime
	local vipKey = common:getLanguageString("@ShopVip", vipLevel, vipCount)

	local coinStr = GameUtil:formatNumber(UserInfo.playerInfo.coin)
	local coinMarketStr = 
	{
		mLV = UserInfo.getStageAndLevelStr(),
		mCoin = coinStr,
		mGold = UserInfo.playerInfo.gold,
		mCoinNum = common:getLanguageString("@ShopCoins", tostring(marketAdventureInfo.coinReward)),
		mGoldNum = common:getLanguageString("@ShopCost", tostring(marketAdventureInfo.coinCost)),
		mPurchaseTimesNum = common:getLanguageString("@ShopCount", tostring(marketAdventureInfo.coinCount)),
		mVipTex = common:getLanguageString(vipKey)
	}

	-- local sprite2Img = {
		-- mVip		= UserInfo.getVipImage()
	-- }
	-- NodeHelper:setSpriteImage(container, sprite2Img)
	
	NodeHelper:setStringForLabel(container, coinMarketStr)

	-- ToDo
	if tonumber(marketAdventureInfo.coinCount) <= 0 then
		NodeHelper:setMenuItemEnabled(container, "mBrush", false)
	else
		NodeHelper:setMenuItemEnabled(container, "mBrush", true)
	end
end

--刷新物品商店页面
function MarketPageBase:rebuildAllItem(container)
     --预防同一时间刷新多次
    if mRebuildLock then
        mRebuildLock = false
        self:clearAllItem(container)
        self:buildItem(container)
        
        --延迟1s
        container:runAction(
			CCSequence:createWithTwoActions(
				CCDelayTime:create(0.3),
				CCCallFunc:create(function()
					mRebuildLock = true
					--判断是否有未被刷新的情况存在，无论未被刷新多少次都只重新刷新一次
					if mRefreshCout > 0 then
					    mRefreshCout = 0
					    self:rebuildAllItem(container)
					end
				end)
			)
		)
	else
	--记录下未被刷新的次数
	    mRefreshCout = mRefreshCout + 1
	end
end

function MarketPageBase:clearAllItem(container)
	local NodeHelper = require("NodeHelper")
	NodeHelper:clearScrollView(container)
end

function MarketPageBase:buildItem(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		self:cutDropsInfoForTeam(container)
	end
	local NodeHelper = require("NodeHelper")
	local contentsSize = 0
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		contentsSize = table.maxn(dropsItemsTeam)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then
		contentsSize = math.ceil(#gemItems / 3)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then
		contentsSize = math.ceil(#suitItems / 3)
	end

	NodeHelper:buildScrollView(container, contentsSize, MarketItem.ccbiFile, MarketItem.onFunction)
end

local function sortFunc(m1, m2)
	if not m1 then return true end
	if not m2 then return false end

	if m1.isAdd and not m2.isAdd then
		return true
	elseif (not m2.isAdd and m1.isAdd) then
		return false
	else
		return m1.id > m2.id
	end
end

--物品按3个3个一组进行分割
function MarketPageBase:cutDropsInfoForTeam(container)
	local maxSize = table.maxn(marketAdventureInfo.dropsItems)
	--服务器来排序，客户端省去排序操作,-
	--table.sort(marketAdventureInfo.dropsItems, sortFunc)
	MAIL_ISSORTED = true

	local teamId = 1
	dropsItemsTeam = {}
	dropsItemsTeam[teamId] = {}
	local count = 1
	local currentTeam = {}

	for i = 1, maxSize, 1 do
		if count < 4 then
			currentTeam[count] = marketAdventureInfo.dropsItems[i]
			count = count + 1
		else
			dropsItemsTeam[teamId] = {}
			self:copyItems(teamId, currentTeam)
			currentTeam = {}
			count = 1
			teamId = teamId + 1

			currentTeam[count] = marketAdventureInfo.dropsItems[i]
			count = count + 1
		end

		if i + 1 > maxSize then
			if table.maxn(currentTeam) > 0 then
				self:copyItems(teamId, currentTeam)
			end
		end
	end
end

function MarketPageBase:copyItems(index, currentTeam)
	local maxSize = table.maxn(currentTeam)
	dropsItemsTeam[index] = {}
	for i = 1, maxSize, 1 do
		local item = currentTeam[i]
		dropsItemsTeam[index][i] = {}
		dropsItemsTeam[index][i].id = item.id
		dropsItemsTeam[index][i].itemId = item.itemId
		dropsItemsTeam[index][i].itemType = item.itemType
		dropsItemsTeam[index][i].itemCount = item.itemCount
		dropsItemsTeam[index][i].buyType = item.buyType
		dropsItemsTeam[index][i].buyPrice = item.buyPrice
		dropsItemsTeam[index][i].buyDiscont = item.buyDiscont
		dropsItemsTeam[index][i].level = item.level
		dropsItemsTeam[index][i].isAdd = item.isAdd
	end
end

-------------------------------------------------------------------------
function MarketPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function MarketPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function MarketPageBase:sendMsgForCoinsInfo(container, dType)
	local msg = Shop_pb.OPBuyCoin()
	msg.type = dType

	local pb_data = msg:SerializeToString()
	container:sendPakcet(opcodes.OPCODE_SHOP_COINS_C, pb_data, #pb_data, true)
end

function MarketPageBase:onReceivePacket(container)
    local Consume_pb = require("Consume_pb")
    local Reward_pb = require "Reward_pb"
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.OPCODE_SHOP_DROPS_S then
		local msg = Shop_pb.OPShopInfoRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveDropsInfo(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_SHOP_COINS_S then
		local msg = Shop_pb.OPBuyCoinRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveCoinsInfo(container, msg)
		return
	end

	if opcode == opcodes.EQUIP_STONE_BUY_S then
		print("EQUIP_STONE_BUY_S")
		local msg = EquipOpr_pb.HPNewGemBuyRet()
		msg:ParseFromString(msgBuff)
		-- dump(msg)
		self:onReceiveGemInfo(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_PLAYER_AWARD_S then
	    local msg = Reward_pb.HPPlayerReward()
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
	    local msg = Consume_pb.HPConsumeInfo()
		msg:ParseFromString(msgBuff)
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

	if opcode == opcodes.OPCODE_CRYSTAL_SHOP_LIST_S or opcode == opcodes.OPCODE_CRYSTAL_SHOP_REFRESH_S then
		CCLuaLog("###opcode == opcodes.CRYSTAL_SHOP_REFRESH_S###")
		local msg = CrystalShop_pb.HPCrystalShopListRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveSuitsInfo(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_CRYSTAL_SHOP_BUY_S then 
		CCLuaLog("###opcode == opcodes.OPCODE_CRYSTAL_SHOP_BUY_S###")
		CCLuaLog("###opcode == opcodes.OPCODE_CRYSTAL_SHOP_BUY_S###")
		return
	end
end

function MarketPageBase:onReceiveDropsInfo( container, msg )
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

	marketAdventureInfo.dropsItems = msg.shopItems
	marketAdventureInfo.refreshCount = msg.refreshCount
    marketAdventureInfo.refreshPrice = msg.refreshPrice
	self:refreshBasicInfo(container)
	self:rebuildAllItem(container)
end

function MarketPageBase:refreshItemsData(newItems)
	-- body
end

function MarketPageBase:onReceiveCoinsInfo(container, msg)
	if msg.type == ShopInfoType.TYPE_BUY_SINGLE then
		local messageStr = common:getLanguageString("@BuyCoinSuccess", msg.coinNums);
		--MessageBoxPage:Msg_Box(messageStr);
	elseif msg.type == ShopInfoType.TYPE_BUY_ALL then
		--MessageBoxPage:Msg_Box("@BuyAllSuccess")
	end

	marketAdventureInfo.coinReward = msg.coin
	marketAdventureInfo.coinCost = msg.coinPrice
	marketAdventureInfo.coinCount = msg.canBuyNums

	self:refreshBasicInfo(container)
	self:rebuildCoinsInfo(container)
end

function MarketPageBase:onReceiveGemInfo(container, msg)
	--print("msg.gemBuyCount =",msg.gemBuyCount)
	-- UserInfo.stateInfo.gemShopBuyCount = msg.gemBuyCount
	self:refreshBasicInfo(container)
	self:rebuildGemInfo(container)
end

function MarketPageBase:onReceiveSuitsInfo(container, msg)
	CCLuaLog("###MarketPageBase:onReceiveSuitsInfo(container, msg)###")
	suitItems = msg.shopItems
	self:refreshBasicInfo(container)
	self:rebuildAllItem(container)
	self.suitRefreshCostCrystal = msg.refreshCostCrystal --水晶商店刷新消耗的钻石数
end

function MarketPageBase:rebuildGemInfo(container)
	local vipCfg = ConfigManager.getVipCfg()
	local vipLevel = UserInfo.playerInfo.vipLevel
    -- local leftBuyTime = vipCfg[vipLevel].gemBuy - UserInfo.stateInfo.gemShopBuyCount

	-- NodeHelper:setStringForLabel(container, {
	-- 	mDrawSellTxt = common:getLanguageString("@ShopCount", tostring(leftBuyTime))}
	-- 	);
end

-----------------------切换到物品商店页面-------------------------------------
function MarketPageBase:openDropsMarket(container)
	if marketAdventureInfo.dropsItems ~= nil then
		self:rebuildAllItem(container)
	end
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_DROPS
	self:switchPageType(container, 1)
	sendMsgForDropsInfo(container, ShopInfoType.TYPE_INIT_INFO, 0)
end

-----------------------切换到金币商店页面-------------------------------------
function MarketPageBase:openCoinsMarket(container)
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_COINS
	self:switchPageType(container, 2)
	self:sendMsgForCoinsInfo(container, ShopInfoType.TYPE_INIT_INFO)
end

function MarketPageBase:openGemsMarket(container)
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_GEMS
	self:switchPageType(container, 3)
	gemItems = ItemManager:getGemMarketItems(UserInfo.playerInfo.vipLevel)
	self:rebuildAllItem(container)
	self:refreshBasicInfo(container)
end

function MarketPageBase:openSuitsMarket(container)
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_SUITS
	self:switchPageType(container, 4)
	common:sendEmptyPacket(HP.CRYSTAL_SHOP_LIST_C, false)
	--gemItems = ConfigManager.getGemMarketCfg();
	--self:rebuildAllItem(container);
end

--node切换控制显示哪个商店，金币商店分成两个node是用于屏幕适配
function MarketPageBase:switchPageType(container, typeFlag)
	local NodeHelper = require("NodeHelper")
	local gemShopFlag = CCUserDefault:sharedUserDefault():getBoolForKey("gemShopFlag")
	if typeFlag == 3 and not gemShopFlag then
		CCUserDefault:sharedUserDefault():setBoolForKey("gemShopFlag", true)
		CCUserDefault:sharedUserDefault():flush()
	end
	local suitShopKey = string.format("suitShopFlag_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId)
	local suitShopFlag = UserInfo.roleInfo.level >= GameConfig.SuitShopLevelLimit and not CCUserDefault:sharedUserDefault():getBoolForKey( suitShopKey )
	if typeFlag == 4 and suitShopFlag then
		CCUserDefault:sharedUserDefault():setBoolForKey(suitShopKey, true)
		CCUserDefault:sharedUserDefault():flush()
	end
	--visible
	local visibleMap = 
	{
		mExceptGoldNode = typeFlag ~= 2,
		mGoblinmerchantNode = typeFlag == 1,
		mBuyGoldNum = typeFlag == 2,
		mBuyGoldNum2 = typeFlag == 2,
		mBuyGemNum = typeFlag == 3,
		mDrawSellTxt = false,
		mExceptDraw = typeFlag ~= 3,
		mTopBanner1 = (typeFlag ~= 3 and typeFlag ~= 4),
		mTopBanner2 = typeFlag == 3,
		mShopNewPoint = not gemShopFlag and typeFlag ~= 3,
		mTopBanner3 = typeFlag == 4,
		mBuySuitNum = typeFlag == 4,
		mSuitBuy = typeFlag == 4,
		mShopNewSiuitPoint = suitShopFlag and typeFlag ~= 4,
	}

	NodeHelper:setNodesVisible(container, visibleMap)

	--selected
	local selectedMap =
	{
		mGoblinmerchant = typeFlag == 1,
		mBuyGold = typeFlag == 2,
		mBuyGem = typeFlag == 3,
		mBuySuit = typeFlag == 4
	}

	NodeHelper:setMenuItemSelected(container, selectedMap)

	local iconPic = ""
	if typeFlag == 3 then
		iconPic = "UI/MainScene/Button/u_DecorationButton.png"
	else
		iconPic = "UI/MainScene/Button/u_HelpButton02.png"
	end

	NodeHelper:setMenuItemImage(container, { mHelpIcon = { normal = iconPic } })

	--name
	local btnStr = ""
	if typeFlag ~= 2 then
		btnStr = common:getLanguageString("@Brush")
	else
		btnStr = common:getLanguageString("@Buy")
	end

	if typeFlag == 3 then
		NodeHelper:setStringForLabel(container, {mGemTxt1 = common:stringAutoReturn(common:getLanguageString("@BuyGemTex1"), 22)})
	end
    if common:table_hasValue(ActivityInfo.allIds, Const_pb.SHOP_REFRESH_PRICE_RATIO) and typeFlag then
        --显示 mRefreshRatio
       NodeHelper:setNodesVisible(container,{ mRefreshRatio = true })
    else
        --隐藏
       NodeHelper:setNodesVisible(container,{ mRefreshRatio = false })
    end
    local vipCfg = ConfigManager.getVipCfg()
    local vipLevel = UserInfo.playerInfo.vipLevel
    local leftBuyTime = vipCfg[vipLevel].gemBuy - UserInfo.stateInfo.gemShopBuyCount

	 NodeHelper:setStringForLabel(container, { mBrush = btnStr,
	  mDrawSellTxt = common:getLanguageString("@ShopCount", tostring(leftBuyTime)) })
end

--购买所有物品
function MarketPageBase:onBuyAll(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		--if Golb_Platform_Info.is_entermate_platform or Golb_Platform_Info.is_r2_platform then
			local titile = common:getLanguageString("@OnBuyTitle")
			local tipinfo = common:getLanguageString("@MarketBuyAll")
			PageManager.showConfirm(titile, tipinfo, function(isSure)
			if isSure then
					sendMsgForDropsInfo( container, ShopInfoType.TYPE_BUY_ALL, 0);
				end
			end)
		--else
		--	sendMsgForDropsInfo( container, ShopInfoType.TYPE_BUY_ALL, 0);
		--end
		
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_COINS then
		if marketAdventureInfo.coinCount <= 0 then
			MessageBoxPage:Msg_Box("@ShopCountLimit")
			libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "BuyCoin_enter_rechargePage")
			PageManager.pushPage("RechargePage")
		else
            if Golb_Platform_Info.is_entermate_platform or Golb_Platform_Info.is_r2_platform then
			    local titile = common:getLanguageString("@OnBuyTitle")
			    local tipinfo = common:getLanguageString("@OnBuyTips")
			    PageManager.showConfirm(titile, tipinfo, function(isSure)
			    if isSure then
				    self:sendMsgForCoinsInfo( container, ShopInfoType.TYPE_BUY_ALL)
				    end
			    end)
	        else
		           self:sendMsgForCoinsInfo(container, ShopInfoType.TYPE_BUY_ALL)
	        end
		 end
	 end
end

--购买单个金币，或者刷新物品商店
function MarketPageBase:onBuyCoinsOrRefreshDrops(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		self:popRefreshBox(container)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_COINS then

		if marketAdventureInfo.coinCount <= 0 then
			MessageBoxPage:Msg_Box("@ShopCountLimit")
			libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","BuyCoin_enter_rechargePage")
			PageManager.pushPage("RechargePage")
		elseif UserInfo.isGoldEnough(marketAdventureInfo.coinCost,"BuyCoin_enter_rechargePage") then
        --20150421
         if Golb_Platform_Info.is_entermate_platform then
			local titile = common:getLanguageString("@OnBuyTitle")
			local tipinfo = common:getLanguageString("@OnBuyTips")
			PageManager.showConfirm(titile, tipinfo, function(isSure)
			if isSure then
					self:sendMsgForCoinsInfo(container, ShopInfoType.TYPE_BUY_SINGLE)
				end
			end)
	      else
		       self:sendMsgForCoinsInfo(container, ShopInfoType.TYPE_BUY_SINGLE)
	      end
		end
	end
end

--弹出刷新页面
function MarketPageBase:popRefreshBox( container )
    --刷新钻石数改为后端发
    --[[
	local max = table.maxn(RefreshCostCfg);
	local cost = 0;
	if marketAdventureInfo.refreshCount <= max then
		cost = RefreshCostCfg[marketAdventureInfo.refreshCount].cost;
	else
		cost = RefreshCostCfg[max].cost;
	end

    ]]
	local refreshFunc = function(isOK)
		if isOK then
            if UserInfo.stateInfo.leftFreeRefreshShopTimes > 0 then
                 sendMsgForDropsInfo(container, ShopInfoType.TYPE_REFRESH, 0)
            elseif  UserInfo.isGoldEnough(marketAdventureInfo.refreshPrice, "ShopRefresh_enter_rechargePage") then
                 sendMsgForDropsInfo(container, ShopInfoType.TYPE_REFRESH, 0)
            end
			
		end
	end
    UserInfo.sync()
	local title = common:getLanguageString("@ShopRefreshTitle")
    local msg = ""
    CCLuaLog("leftFreeRefreshShopTimes ====================================== :"..UserInfo.stateInfo.leftFreeRefreshShopTimes)
    if UserInfo.stateInfo.leftFreeRefreshShopTimes > 0 then--月卡免费次数
        msg = common:getLanguageString("@MothcardFreeShopRefreshTime")
    else
        msg = common:getLanguageString("@ShopRefreshContent",marketAdventureInfo.refreshPrice)
    end

	PageManager.showConfirm(title, msg, refreshFunc)
end

--帮助页面
function MarketPageBase:onHelp(container)
	if SHOP_CURRENT_STATE == ShopSelectedState.STATE_DROPS then
		PageManager.showHelp(GameConfig.HelpKey.HELP_MARKET_ITEM)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_GEMS then 
		-- PageManager.showHelp(GameConfig.HelpKey.HELP_GEMSHOP)
	elseif SHOP_CURRENT_STATE == ShopSelectedState.STATE_SUITS then
		PageManager.showHelp(GameConfig.HelpKey.HELP_SUITSHOP)
	else
		PageManager.showHelp(GameConfig.HelpKey.HELP_MARKET_GOLD)
	end
end

--购买单个道具
function MarketItem.buySingleDrop(container)
	local index = container:getTag()

	local item = marketAdventureInfo.dropsItems[index]
	if item == nil then return end
	
	--local id = MarketItem.getIdByMainInfoIndex(index)
	if ( item.buyType == iConType.type_Coins and not UserInfo.isCoinEnough(item.buyPrice) )
		or ( item.buyType == iConType.type_Gold and not UserInfo.isGoldEnough(item.buyPrice,"BuySingleDrop_enter_rechargePage") )
	then
		return
	end

     if Golb_Platform_Info.is_entermate_platform then
			local titile = common:getLanguageString("@OnBuyTitle")
			local tipinfo = common:getLanguageString("@OnBuyTips")
			PageManager.showConfirm(titile, tipinfo, function(isSure)
			if isSure then
					sendMsgForDropsInfo(MainContainer, ShopInfoType.TYPE_BUY_SINGLE, item.id)
				end
			end)
	else
		sendMsgForDropsInfo(MainContainer, ShopInfoType.TYPE_BUY_SINGLE, item.id)
	end
end

function MarketItem.buySingleGem(container)
	local index = container:getTag()
	local item = gemItems[index]
	if item == nil then return end
	local ttype = item.costType
    local vipCfg = ConfigManager.getVipCfg()
    local vipLevel = UserInfo.playerInfo.vipLevel
    -- local leftBuyTime = vipCfg[vipLevel].gemBuy - UserInfo.stateInfo.gemShopBuyCount
    local costInfo = 1
    local costNum = item.costGold
    if ttype == 2 then
    	costInfo = ConfigManager.parseItemOnlyWithUnderline(item.costItems)
    	costNum = costInfo.count
    	-- leftBuyTime = nil
    end
    -- print("ttype =", ttype)
    -- print("costNum =", costNum)
    -- dump(costInfo)
    if leftBuyTime == nil or leftBuyTime > 0 then
	    PageManager.showCountTimesWithIconPage(Const_pb.TOOL, item.itemId, costInfo,
	    function(count) 
	        return count * costNum
	    end,
	    function (isBuy, count)
	    	if isBuy then
				local msg = EquipOpr_pb.HPNewGemBuy()
				msg.shopId = item.id
				msg.type = ttype or 1
				msg.number = count
				common:sendPacket(opcodes.EQUIP_STONE_BUY_C, msg, true)
	    	end
	    end, true, leftBuyTime, "@BuyGem")	
	else
		MessageBoxPage:Msg_Box_Lan("@NoGemBuyCount")
	end	
end

function MarketItem.buySingleSuit(container)
	local index = container:getTag()
	local item = suitItems[index]
	if item == nil then return end
	local msg = CrystalShop_pb.HPCrystalBuy()
    msg.id = item.id
    common:sendPacket(HP.CRYSTAL_SHOP_BUY_C, msg, false)
end

function MarketPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == thisPageName then
			--self:refreshBasicInfo(container)
			if extraParam == "TopMsgUpdate" then
			    MarketPageBase:refreshBasicInfo( container )
			    return
			end
			self:refreshPage(container)
		end
	elseif typeId == MSG_MAINFRAME_CHANGEPAGE then
		local pageName = MsgMainFrameChangePage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:refreshPage(container)
		end
	end
end

-------------------------------------------------------------------------

local CommonPage = require("CommonPage")
local MarketPage = CommonPage.newSub(MarketPageBase, thisPageName, option)

function MarketPage_showBuyCoin()
	SHOP_CURRENT_STATE = ShopSelectedState.STATE_COINS
	if MainFrame:getInstance():getCurShowPageName() == thisPageName then
		PageManager.refreshPage(thisPageName)
	else
		PageManager.changePage(thisPageName)
	end
end
