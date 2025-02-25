
----------------------------------------------------------------------------------
local Const_pb 		= require("Const_pb");
local HP_pb			= require("HP_pb");
local EquipOpr_pb = require("EquipOpr_pb");
local NewbieGuideManager = require("NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
local math = math;
--------------------------------------------------------------------------------
local PageType = {
	GemUpgrade 				= 1,
	SoulStoneUpgrade  		= 2,
}
local thisPageName 	= "gemExchangePage";
local thisItemId	= 0;
local thisExp = 0;
local thisPageType = PageType.GemUpgrade

local opcodes = {
	EQUIP_STONE_EXCHANGE_C	= HP_pb.EQUIP_STONE_EXCHANGE_C,
	EQUIP_STONE_EXCHANGE_S  = HP_pb.EQUIP_STONE_EXCHANGE_S
};

local option = {
	ccbiFile = "BackpackGemExchangePopUp.ccbi",
	handlerMap = {
		onGemExchange		 	= "onGemExchange",
		onHelp					= "onHelp",
		onClose					= "onClose"
	},
	opcode = opcodes
};

local gemExchangePageBase = {};

local NodeHelper = require("NodeHelper");
local ItemOprHelper = require("Item.ItemOprHelper");
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");

local originalExpScaleX = nil;

-----------------------------------------------
--gemExchangePageBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function gemExchangePageBase:onEnter(container)
	self:registerPacket(container);
	self:refreshPage(container);
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_GEM_UPGRADE)
end

function gemExchangePageBase:onExit(container)
	self:removePacket(container);
end

function gemExchangePageBase:refreshPage(container)
	self:showGemInfo(container);
	-- self:showUpgradeInfo(container);
end

function gemExchangePageBase:showGemInfo(container)
	local name	= ItemManager:getNameById(thisItemId);

	local exchangeInfo = ConfigManager.parseItemOnlyWithUnderline(ItemManager:getExchangeById(thisItemId))

	local resInfo = ResManagerForLua:getResInfoByTypeAndId(exchangeInfo.type, exchangeInfo.itemId, exchangeInfo.count);

	local ownNum = UserItemManager:getCountByItemId(thisItemId);

	local lb2Str = {
		mNumber				= "x"..ownNum,
		mNumber1			= "x"..(exchangeInfo.count*ownNum),
		mGemUpgradeUpName1  = name,
		mGemUpgradeUpName2  = resInfo.name,
		mName				= "",
		mName1				= "",

	};
	local sprite2Img = {
		mPic = ItemManager:getIconById(thisItemId),
		mPic1 = resInfo.icon
	};
	local itemImg2Qulity = {
		mHand = ItemManager:getQualityById(thisItemId),
		mHand1= resInfo.quality
	};
	local scaleMap = {mPic = 1.0};	

	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
end

----------------click event------------------------
function gemExchangePageBase:onGemExchange(container)
	local msg = EquipOpr_pb.HPEquipStoneExchange();
	msg.stoneId = thisItemId;
	msg.number = UserItemManager:getCountByItemId(thisItemId);
	common:sendPacket(HP_pb.EQUIP_STONE_EXCHANGE_C, msg);
end

function gemExchangePageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GEMEXCHANGE);
end	

function gemExchangePageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

function gemExchangePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	print("opcode = ",opcode)
	if opcode == opcodes.EQUIP_STONE_EXCHANGE_S then
		local msg = EquipOpr_pb.HPEquipStoneExchangeRet();
		msg:ParseFromString(msgBuff);
		if msg.targetItemId == 0 then
			common:popString(common:getLanguageString("@gemExchangeFail"), "COLOR_YELLOW");
		end		
		PageManager.popPage(thisPageName);
	end
end
function gemExchangePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function gemExchangePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
gemExchangePage = CommonPage.newSub(gemExchangePageBase, thisPageName, option);

function gemExchangePage_setItemId(itemId, pageType)
	thisItemId = itemId;
end
