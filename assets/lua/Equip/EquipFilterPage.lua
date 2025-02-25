----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");

------------local variable for system api--------------------------------------
local pairs = pairs;
--------------------------------------------------------------------------------

local thisPageName = "EquipFilterPage";

local EquipPartNames = {
	["Helmet"] 		= Const_pb.HELMET,
	["Neck"]		= Const_pb.NECKLACE,
	["Finger"]		= Const_pb.RING,
	["Wrist"]		= Const_pb.GLOVE,	
	["Waist"]		= Const_pb.BELT,	
	["Feet"]		= Const_pb.SHOES,
	["Chest"]		= Const_pb.CUIRASS,
	["Legs"]		= Const_pb.LEGGUARD,
	["MainHand"]	= Const_pb.WEAPON1,
	["OffHand"]		= Const_pb.WEAPON2
};

local ColorNames = {
	["White"] 		= Const_pb.WHITE,
	["Green"]		= Const_pb.GREEN,
	["Blue"]		= Const_pb.BLUE,
	["Purple"]		= Const_pb.PURPLE,	
	["Orange"]		= Const_pb.ORANGE
};

local option = {
	ccbiFile = "BackpackEquipmentFilteringPopUp.ccbi",
	handlerMap = {
		onClose			= "onClose",
		onGodEquipment	= "filterGodEquip",
		onAllEquipment	= "filterAllEquip"
	}
};

for equipName, _ in pairs(EquipPartNames) do
	option.handlerMap["on" .. equipName] = "filterEquipPart";
end
for colorName, _ in pairs(ColorNames) do
	option.handlerMap["on" .. colorName .. "Equipment"] = "filterEquipColor";
end

local EquipFilterPageBase = {};

local NodeHelper = require("NodeHelper");
	
-----------------------------------------------
--EquipFilterPageBaseҳ���е��¼�����
----------------------------------------------
function EquipFilterPageBase:onEnter(container)
	self:refreshPage(container);
	local relativeNode = container:getVarNode("S9_1")
	GameUtil:clickOtherClosePage(relativeNode, function ()
		self:onClose(container)
	end,container)
end

----------------------------------------------------------------

function EquipFilterPageBase:refreshPage(container)
	self:showCountInfo(container);
end

function EquipFilterPageBase:showCountInfo(container)
	--UserEquipManager:classify();
	
	local lb2Str = {};
	
	for equipName, part in pairs(EquipPartNames) do
		local name = common:getLanguageString("@EquipPart_" .. part);
		local count = UserEquipManager:countEquipWithPart(part);
		lb2Str["m" .. equipName] = common:getLanguageString("@EquipCount", name, count);
		
        local strTable = {["m" .. equipName] = common:getLanguageString(name) .. "(" .. count .. ")"}
        NodeHelper:setStringForLabel(container ,strTable)
		--NodeHelper:setCCHTMLLabel(container,"m" .. equipName,CCSize(190,96),lb2Str["m" .. equipName],true)
	end
	
	for colorName, quality in pairs(ColorNames) do
		local name = common:getLanguageString("@QualityName_" .. quality);
		local count = UserEquipManager:countEquipWithQuality(quality);
		lb2Str["m" .. colorName .. "Equipment"] = common:getLanguageString("@EquipColorCount", name, count);

         local strTable = {["m" .. colorName .. "Equipment"] =  common:getLanguageString(name) .. "(" .. count .. ")"}

         NodeHelper:setStringForLabel(container , strTable)

		--NodeHelper:setCCHTMLLabel(container,"m" .. colorName .. "Equipment",CCSize(190,96),lb2Str["m" .. colorName .. "Equipment"],true)
	end
	
	local name = common:getLanguageString("@GodlyEquip");
	local count = UserEquipManager:countEquipGodly();
	lb2Str["mGodEquipment"] = common:getLanguageString("@EquipCount", name, count)

      local strTable = {["mGodEquipment"] =   common:getLanguageString(name) .. "(" .. count .. ")" }

         NodeHelper:setStringForLabel(container , strTable)
    --NodeHelper:setCCHTMLLabel(container,"mGodEquipment",CCSize(190,96),lb2Str["mGodEquipment"],true)
	
	local name = common:getLanguageString("@AllEquip");
	local count = UserEquipManager:countEquipAll();
	lb2Str["mAllEquipment"] = common:getLanguageString("@EquipCount", name, count);
	--NodeHelper:setCCHTMLLabel(container,"mAllEquipment",CCSize(190,96),lb2Str["mAllEquipment"],true)
	

     local strTable = {["mAllEquipment"] =   common:getLanguageString(name) }--.. "(" .. count .. ")" }

         NodeHelper:setStringForLabel(container , strTable)

	--NodeHelper:setStringForLabel(container, lb2Str);
end
	
----------------click event------------------------
function EquipFilterPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

function EquipFilterPageBase:filterEquipPart(container, eventName)
	local part = EquipPartNames[string.sub(eventName, 3)];
	PackagePage_setFilter("Part", part);
	self:onClose();
end

function EquipFilterPageBase:filterEquipColor(container, eventName)
	local quality = ColorNames[eventName:sub(3):sub(1, -10)];
	PackagePage_setFilter("Quality", quality);
	self:onClose();	
end	

function EquipFilterPageBase:filterGodEquip(container)
	PackagePage_setFilter("Godly");
	self:onClose();
end	

function EquipFilterPageBase:filterAllEquip(container)
	PackagePage_setFilter("All");
	self:onClose();
end	

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipFilterPage = CommonPage.newSub(EquipFilterPageBase, thisPageName, option);