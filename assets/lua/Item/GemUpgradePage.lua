local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local ItemOpr_pb = require("ItemOpr_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
------------local variable for system api--------------------------------------
local tostring = tostring
local tonumber = tonumber
local string = string
local pairs = pairs
local table = table
local math = math
--------------------------------------------------------------------------------
local PageType = {
	GemUpgrade = 1,
	SoulStoneUpgrade = 2,
}
local thisPageName = "GemUpgradePage"
local thisItemId = 0
local thisExp = 0
local thisPageType = PageType.GemUpgrade

local opcodes = {
	ITEM_USE_S = HP_pb.ITEM_USE_S
}

local option = {
	ccbiFile = "BackpackGemUpgradeUpPopUp.ccbi",
	handlerMap = {
		onGemUpgradeUp = "onUpgrade",
		onAKeyToUpGrade = "onAKeyToUpGrade",
		onHelp = "onHelp",
		onClose = "onClose"
	},
	opcode = opcodes
}

local GemUpgradePageBase = {}

local NodeHelper = require("NodeHelper")
local ItemOprHelper = require("Item.ItemOprHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")

local originalExpScaleX = nil

-----------------------------------------------
--GemUpgradePageBase页面中的事件处理
----------------------------------------------
function GemUpgradePageBase:onEnter(container)
	self:setAllNodeVisible(container, false)
	self:registerPacket(container)
	self:refreshPage(container)
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_GEM_UPGRADE)
end

function GemUpgradePageBase:onExit(container)
	self:removePacket(container)
end
----------------------------------------------------------------
function GemUpgradePageBase:setAllNodeVisible(container, visible)
	NodeHelper:setNodesVisible(container, {
		mTitle  				= visible,
		mGemUpgradeUpExplain  	= visible,
		mExpNode 				= visible,
		mUpgradeLabel 			= visible,
		mUpgradeCostLabel 		= visible,
		})
end

function GemUpgradePageBase:refreshPage(container)
	self:showGemInfo(container)
	self:showUpgradeInfo(container)
end

function GemUpgradePageBase:showGemInfo(container)
	local name = ItemManager:getNameById(thisItemId)
	local lb2Str = {
		mNumber = "",
		mName = "",
		mGemUpgradeUpName = name
	}
	local sprite2Img = {
		mPic = ItemManager:getIconById(thisItemId)
	}
	local itemImg2Qulity = {
		mHand = GameConfig.Default.Quality
	}
	local scaleMap = { mPic = 1.0 }

	NodeHelper:setQualityBMFontLabels(container, { mGemUpgradeUpName = ItemManager:getQualityById(thisItemId) })
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
	NodeHelper:setQualityFrames(container, itemImg2Qulity)
	if thisPageType == PageType.SoulStoneUpgrade then
		NodeHelper:setQualityFrames(container, { mHand = ItemManager:getQualityById(thisItemId) })
	end
end

function GemUpgradePageBase:showUpgradeInfo(container)
	local userItem = UserItemManager:getUserItemByItemId(thisItemId)
	local levelUpCost = ItemManager:getLevelUpCost(thisItemId)
	local costMax = ItemManager:getLevelUpCostMax(thisItemId)
	costMax = math.max(1, costMax)
	local costTb = {}
	for _, costCfg in ipairs(levelUpCost) do
		local resInfo = ResManagerForLua:getResInfoByTypeAndId(costCfg.type, costCfg.id, costCfg.count)
		if resInfo ~= nil then
			local ownNum = 0
			if resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.COIN then
				UserInfo.syncPlayerInfo()
				ownNum = UserInfo.playerInfo.coin
			elseif resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.GOLD then
				UserInfo.syncPlayerInfo()
				ownNum = UserInfo.playerInfo.gold
			else
				ownNum = UserItemManager:getCountByItemId(costCfg.id)
			end

			if Golb_Platform_Info.is_r2_platform then
				local splitStrTag = " x"
				if GamePrecedure:getInstance():getI18nSrcPath() == "Portuguese" then
					splitStrTag = ":"
				end
                		table.insert(costTb, resInfo.name .. splitStrTag .. common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum))
			elseif Golb_Platform_Info.is_gNetop_platform then
				table.insert(costTb, resInfo.name .. "*" .. common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum))
			else
				table.insert(costTb, resInfo.name .. common:getLanguageString("@CurrentOwnInfo", costCfg.count, ownNum))
			end
		end
	end
	-- 为了魂石升级加的
	local lb2Str = {}
	if thisPageType == PageType.SoulStoneUpgrade then
		lb2Str = {
			mGold = table.concat(costTb, "\n")
		};
		NodeHelper:setStringForLabel(container, {
			mTitle = common:getLanguageString("@SoulStoneUpgradeTitle"),
			mGemUpgradeUpExplain = common:getLanguageString("@SoulStoneUpgradeExplain"),
			mUpgradeLabel = common:getLanguageString("@SoulStoneUpgradeBtnLabel"),
			mUpgradeCostLabel = common:getLanguageString("@SoulStoneUpgradeCostLabel"),
		})
	else 
		local showExp = tonumber(userItem.exp)>tonumber(costMax) and tonumber(costMax) or tonumber(userItem.exp)
		lb2Str = {
			LuckyNum = showExp .. "/" .. costMax,
			mGold = table.concat(costTb, "\n")
		}
		local mExpSprite = container:getVarScale9Sprite("mExp")
		if originalExpScaleX == nil then
			originalExpScaleX = mExpSprite:getScaleX()
		end
		mExpSprite:setScaleX(originalExpScaleX * (showExp / costMax))
		thisExp = showExp
	end
	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setNodesVisible(container, { mGold = (costTb ~= nil) })
	self:setAllNodeVisible(container, true)
	if thisPageType == PageType.SoulStoneUpgrade then
		NodeHelper:setNodesVisible(container, { mExpNode = false })
	end
end
	
----------------click event------------------------
function GemUpgradePageBase:onUpgrade(container)
	ItemOprHelper:useItem(thisItemId, 1)
end

function GemUpgradePageBase:onAKeyToUpGrade(container)
	ItemOprHelper:useItem(thisItemId, 10)
end

function GemUpgradePageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GEM_UPGRADE)
end

function GemUpgradePageBase:onClose(container)
	PageManager.popPage(thisPageName)
end

--回包处理
function GemUpgradePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.ITEM_USE_S then
		local msg = ItemOpr_pb.HPItemUseRet()
		msg:ParseFromString(msgBuff)
		local tipKey = "@UpgradeGemSuccess"
		local colorKey = "COLOR_GREEN"
		if msg.targetItemId == 0 then
			tipKey = "@UpgradeGemFail"
			colorKey = "COLOR_YELLOW"
		else
			thisItemId = msg.targetItemId
		end
		if thisPageType == PageType.GemUpgrade then
			-- common:popString(common:getLanguageString(tipKey), colorKey)
		end
		self:refreshPage(container)
	end
end

function GemUpgradePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GemUpgradePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
GemUpgradePage = CommonPage.newSub(GemUpgradePageBase, thisPageName, option)

function GemUpgradePage_setItemId(itemId, pageType)
	thisItemId = itemId
	thisPageType = pageType or PageType.GemUpgrade
end
