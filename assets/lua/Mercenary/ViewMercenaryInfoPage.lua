
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local HP_pb = require("HP_pb");
local Snapshot_pb = require("Snapshot_pb");
local Friend_pb = require("Friend_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local NodeHelper = require("NodeHelper");
local ViewMercenaryInfo = require("Mercenary.ViewMercenaryInfo")
local MercenaryHaloManager = require("Mercenary.MercenaryHaloManager")
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------

local thisPageName = "ViewMercenaryInfoPage";

local opcodes = {

};

local EquipPartNames = {
["Chest"]		= Const_pb.CUIRASS,
["Legs"]		= Const_pb.LEGGUARD,
["MainHand"]	= Const_pb.WEAPON1,
["OffHand"]		= Const_pb.WEAPON2
};

local option = {
ccbiFile = "ArenaViewMercenaryPopUp.ccbi",
handlerMap = {
onClose			= "onClose",
onShieldMessage = "onShieldMessage",
onSendMessage = "onSendMessage",
onAddFriend = "onAddFriend"
},
opcode = opcodes
};
for equipName, _ in pairs(EquipPartNames) do
	option.handlerMap["on" .. equipName] = "showEquipDetail";
end

local ViewMercenaryInfoPageBase = {};

local PBHelper	= require("PBHelper");

local ItemManager = require("Item.ItemManager");

local playerInfo = {};
local thisFlagShowButton = false
-----------------------------------------------
--EquipPageBase页面中的事件处理
----------------------------------------------

function ViewMercenaryInfoPageBase:onLoad(container)
	local height = CCDirector:sharedDirector():getWinSize().height
	container:loadCcbiFile(option.ccbiFile);
end

function ViewMercenaryInfoPageBase:onEnter(container)
    MercenaryHaloManager:classifyGroup(ConfigManager.getMercenaryRingCfg())
	self:setSelectTxtDisappear(container)
	
	UserInfo.sync()
	self:refreshPage(container);
	self:registerPacket(container);
	--self:getPlayerInfo();
end

function ViewMercenaryInfoPageBase:setSelectTxtDisappear( container )
--	container:getVarSprite("mHelmetPic"):setVisible(false)

--	container:getVarSprite("mFingerPic"):setVisible(false)
--	container:getVarSprite("mWaistPic"):setVisible(false)
--	container:getVarSprite("mChestPic"):setVisible(false)
--	container:getVarSprite("mMainHandPic"):setVisible(false)
--	container:getVarSprite("mOffHandPic"):setVisible(false)
--	container:getVarSprite("mLegsPic"):setVisible(false)
--	container:getVarSprite("mFeetPic"):setVisible(false)
--	container:getVarSprite("mWristPic"):setVisible(false)
--	container:getVarSprite("mNeckPic"):setVisible(false)
end

function ViewMercenaryInfoPageBase:onExit(container)
	self:removePacket(container);
	ViewMercenaryInfo:clearInfo();
	--清除纹理缓存
	GameUtil:purgeCachedData();
end
----------------------------------------------------------------

function ViewMercenaryInfoPageBase:refreshPage(container)
	self:showPlayerInfo(container);
	self:showFightAttrInfo(container);
	self:showEquipInfo(container);
    self:showStarLevelInfo(container);
    self:showHaloInfo(container);
end

function ViewMercenaryInfoPageBase:showHaloInfo(container)
    local selectedMercenary = ViewMercenaryInfo:getRoleInfo()
    local groupMap = {}
    if selectedMercenary.itemId == 7 then
		groupMap = MercenaryHaloManager.WGroup
	elseif selectedMercenary.itemId == 8 then
		groupMap = MercenaryHaloManager.HGroup
	elseif selectedMercenary.itemId == 9 then
		groupMap = MercenaryHaloManager.MGroup
	end		
	local UserEquipManager = require("Equip.UserEquipManager")
	local starLevel = tonumber(selectedMercenary.starLevel)
	local picMap, nameMap,colorMap = {},{},{}	
	for i=1,#groupMap do
		local oneRing = groupMap[i]
		local ringId = oneRing["ringId"]			
		nameMap[string.format("mNum%d", i)]	= MercenaryHaloManager:getNameByRingId(ringId)
		picMap[string.format("mTextPic%02d", i)] = MercenaryHaloManager:getIconByRingId(ringId)	
		
		--判断是否被激活
		if starLevel>= tonumber(MercenaryHaloManager:getStarLimitByRingId(ringId)) then			
			if ViewMercenaryInfo:checkRingActive(ringId) then
				UserEquipManager:setRedPointNotice(selectedMercenary.roleId, true)
				self:showHaloAni(container,i,true)
			else
				self:showHaloAni(container,i,false)		
			end	
		else
			self:showHaloAni(container,i,false)			
		end
	end
	NodeHelper:setStringForLabel(container, nameMap);	
	NodeHelper:setSpriteImage(container, picMap);
end

function ViewMercenaryInfoPageBase:showHaloAni(container,index,aniVisible)
	local aniNode = container:getVarNode("mAniNode"..index);
	if aniNode then
		aniNode:removeAllChildren();
		if aniVisible then
			local ccbiFile = GameConfig.GodlyEquipAni["Second"];
			local ani = CCBManager:getInstance():createAndLoad2(ccbiFile);
			ani:unregisterFunctionHandler();
			aniNode:addChild(ani);
		end
		aniNode:setVisible(aniVisible);
	end
end

function ViewMercenaryInfoPageBase:showStarLevelInfo(container)
    local step = ViewMercenaryInfo:getStarLevel()
	for i = 1,10,1 do
	    if i == 10 then
	        container:getVarSprite("mYellowStar" .. i ):setVisible( i <= step )
	    else
	        container:getVarSprite("mYellowStar0" .. i ):setVisible( i <= step )
	    end
	end
end

function ViewMercenaryInfoPageBase:showPlayerInfo(container)
	local level = ViewMercenaryInfo:getRoleInfo().level;
	local lb2Str = {
	mHpNum 					= ViewMercenaryInfo:getRoleAttrById(Const_pb.HP),
	mMpNum 					= ViewMercenaryInfo:getRoleAttrById(Const_pb.MP),
	mLV						= common:getR2LVL() .. ViewMercenaryInfo:getRoleInfo().level,
	mMercenaryName		 	= UserInfo.getOtherLevelStr(ViewMercenaryInfo:getRoleInfo().rebirthStage, ViewMercenaryInfo:getRoleInfo().level) .. " " ..  Language:getInstance():getString(ViewMercenaryInfo:getRoleInfo().name),
	mFightingCapacityNum 	= ViewMercenaryInfo:getRoleInfo().fight,
	mOccupationName			= ViewMercenaryInfo:getProfessionName()
	};
	NodeHelper:setStringForLabel(container, lb2Str);

	local roleId = ViewMercenaryInfo:getRoleInfo().itemId;
	local RoleManager = require("PlayerInfo.RoleManager");
	NodeHelper:setSpriteImage(container, {
		mOccupation = RoleManager:getOccupationIconById(roleId)
	});
			
    local backgroundPic = GameConfig.MercenaryBackgroundPic[roleId]
    NodeHelper:setSpriteImage(container, {
		mMercenaryPic 	= backgroundPic
	});
end

function ViewMercenaryInfoPageBase:showFightAttrInfo(container)
	local lb2Str = {
	mStrengthNum 			= ViewMercenaryInfo:getRoleAttrById(Const_pb.STRENGHT),
	mDamageNum 				= ViewMercenaryInfo:getDamageString(),
	mDexterityNum			= ViewMercenaryInfo:getRoleAttrById(Const_pb.AGILITY),
	mArmorNum				= ViewMercenaryInfo:getRoleAttrById(Const_pb.ARMOR),
	mCritRatingNum			= ViewMercenaryInfo:getRoleAttrById(Const_pb.CRITICAL),
	mIntelligenceNum	 	= ViewMercenaryInfo:getRoleAttrById(Const_pb.INTELLECT),
	mCreateRoleNum			= ViewMercenaryInfo:getRoleAttrById(Const_pb.MAGDEF),
	mDodgeNum				= ViewMercenaryInfo:getRoleAttrById(Const_pb.DODGE),
	mStaminaNum				= ViewMercenaryInfo:getRoleAttrById(Const_pb.STAMINA),
	mHitRatingNum			= ViewMercenaryInfo:getRoleAttrById(Const_pb.HIT),
	mTenacityNum 			= ViewMercenaryInfo:getRoleAttrById(Const_pb.RESILIENCE)
	};
	NodeHelper:setStringForLabel(container, lb2Str);
end

function ViewMercenaryInfoPageBase:showEquipInfo(container)
	local lb2Str = {};
	local sprite2Img = {};
	local itemImg2Qulity = {};
	local scaleMap = {};
	local nodesVisible = {};
	
	for equipName, part in pairs(EquipPartNames) do
		local levelStr = "";
		local enhanceLvStr = "";
		local icon = GameConfig.Image.FullEmpty;
		local quality = GameConfig.Default.Quality;
		local aniVisible = false;
		local gemVisible = false;
		
		local name 	= "m" .. equipName;
		local roleEquip = ViewMercenaryInfo:getRoleEquipByPart(part);
		local userEquip = nil;
		if roleEquip then
			local equipId = roleEquip.equipItemId;
			levelStr = "Lv" .. EquipManager:getLevelById(equipId);
			enhanceLvStr = "+" .. roleEquip.strength;
			icon = EquipManager:getIconById(equipId);
			quality = EquipManager:getQualityById(equipId);
			container:getVarSprite("m" .. equipName .. "Pic"):setVisible(true)
			
			userEquip = ViewMercenaryInfo:getEquipById(roleEquip.equipId);
			aniVisible = UserEquipManager:isEquipGodly(userEquip);
			local gemInfo = PBHelper:getGemInfo(roleEquip.gemInfo);
			if table.maxn(gemInfo) > 0 then
				gemVisible = true;
				for i = 1, 4 do
					local gemId = gemInfo[i];
					nodesVisible[name .. "GemBG" .. i] = gemId ~= nil;
					local gemSprite = name .. "Gem0" .. i;
					nodesVisible[gemSprite] = false;
					if gemId ~= nil and gemId > 0 then
						local icon = ItemManager:getGemSmallIcon(gemId);
						if icon then
							nodesVisible[gemSprite] = true;
							sprite2Img[gemSprite] = icon;
						end
					end
				end
			end
		end
		
		lb2Str[name .. "Lv"] 			= levelStr;
		lb2Str[name .. "LvNum"]			= enhanceLvStr;
		sprite2Img[name .. "Pic"] 		= icon;
		itemImg2Qulity[name] 			= quality;
		scaleMap[name .. "Pic"] 		= 1.0;
		nodesVisible[name .. "Ani"]		= aniVisible;
		nodesVisible[name .. "GemNode"]	= gemVisible;
		nodesVisible[name .. "Point"] 	= false;
		
		NodeHelper:addEquipAni(container, name .. "Ani", aniVisible, nil, userEquip);
	end
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
	NodeHelper:setNodesVisible(container, nodesVisible);
end

----------------click event------------------------
function ViewMercenaryInfoPageBase:showEquipDetail(container, eventName)
	local part = EquipPartNames[string.sub(eventName, 3)];
	local roleEquip = ViewMercenaryInfo:getRoleEquipByPart(part);
	if roleEquip then
		PageManager.viewEquipInfo(roleEquip.equipId,true);
	end
end

function ViewMercenaryInfoPageBase:onClose()
	PageManager.popPage(thisPageName);
end

--------------------------------------------------------

--回包处理

function ViewMercenaryInfoPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function ViewMercenaryInfoPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local ViewMercenaryInfoPage = CommonPage.newSub(ViewMercenaryInfoPageBase, thisPageName, option);
