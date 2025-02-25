
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");

------------local variable for system api--------------------------------------
local pairs = pairs;
--------------------------------------------------------------------------------

local thisPageName = "BatchSellEquipPage";

local ColorNames = {
	["White"] 		= Const_pb.WHITE,
	["Green"]		= Const_pb.GREEN,
	["Blue"]		= Const_pb.BLUE,
	["Purple"]		= Const_pb.PURPLE,	
	["Orange"]		= Const_pb.ORANGE
};

local option = {
	ccbiFile = "BackpackBatchSellOutPopUp.ccbi",
	handlerMap = {
		onClose			= "onClose"
	}
};

for colorName, _ in pairs(ColorNames) do
	option.handlerMap["on" .. colorName .. "SellOut"] = "sellEquip";
end

local BatchSellEquipPageBase = {};

local NodeHelper = require("NodeHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
	
-----------------------------------------------
--BatchSellEquipPageBaseҳ���е��¼�����
----------------------------------------------
function BatchSellEquipPageBase:onEnter(container)
	self:refreshPage(container);
	local relativeNode = container:getVarNode("S9_1")
	GameUtil:clickOtherClosePage(relativeNode, function ()
		self:onClose(container)
	end,container)
end
----------------------------------------------------------------

function BatchSellEquipPageBase:refreshPage(container)
	self:showCountInfo(container);
end

function BatchSellEquipPageBase:showCountInfo(container)
	--UserEquipManager:classify();
	
	local lb2Str = {};
	
	for colorName, quality in pairs(ColorNames) do
		local name = common:getLanguageString("@QualityName_" .. quality);
		local count = UserEquipManager:countEquipForBatchSell(quality);
		lb2Str["m" .. colorName .. "Equipment"] = common:getLanguageString("@EquipColorCount", name, count);
	end
	
	NodeHelper:setStringForLabel(container, lb2Str);
end
	
----------------click event------------------------
function BatchSellEquipPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

function BatchSellEquipPageBase:sellEquip(container, eventName)
	local qualityName = eventName:sub(3):sub(1, -8);
	local quality = ColorNames[qualityName];
	if Golb_Platform_Info.is_gNetop_platform then
		local count = UserEquipManager:countEquipForBatchSell(quality);
		if tonumber(count) > 0 then 
			local sellEvent = function (isSure)
			if isSure then
				EquipOprHelper:sellEquipsWithQuality(quality);
				BatchSellEquipPageBase:onClose();
			end
			end
			local title = Language:getInstance():getString("@HintTitle")
			local message = Language:getInstance():getString("@SellEquipDes")
			PageManager.showConfirm(title,message,sellEvent)
		end
	else
		EquipOprHelper:sellEquipsWithQuality(quality);
		self:onClose();
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
BatchSellEquipPage = CommonPage.newSub(BatchSellEquipPageBase, thisPageName, option);