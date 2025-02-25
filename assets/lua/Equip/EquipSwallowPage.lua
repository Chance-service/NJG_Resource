
local HP_pb = require("HP_pb");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
local math = math;
--------------------------------------------------------------------------------

local thisPageName = "EquipSwallowPage";
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager")
local ItemManager = require("Item.ItemManager")
local opcodes = {
	EQUIP_SWALLOW_S = HP_pb.EQUIP_SWALLOW_S,
	ERROR_CODE_S	= HP_pb.ERROR_CODE
};

local COUNT_EQUIPMENT_SOURCE_MAX = 6;

local option = {
	ccbiFile = "EquipmentGobbleUpPopUp.ccbi",
	handlerMap = {
		onHelp					= "showHelp",
		onClose					= "onClose",
		onAutomaticScreening	= "onAutoSelect",
		onGobbleUp				= "onSwallow"
	},
	opcode = opcodes
};
local Order = {"A", "B", "C", "D", "E", "F"};
for i = 1, COUNT_EQUIPMENT_SOURCE_MAX do
	option.handlerMap["on" .. Order[i] .. "Hand"] = "goSelectEquip";
end

local EquipSwallowPageBase = {};

local NodeHelper = require("NodeHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local NewbieGuideManager = require("NewbieGuideManager")
local thisEquipId = 0;
local currentSlotId = 1;
local selectedIds = {};
local selectedMap = {}
local originalExpScaleX = nil;
local originalExpScaleX2 = nil;
local btnLock = false;
local lackInfo = {item = false, coin = false};
local GodEquipLevel = {startLevel1 = 1,startLevel2 = 1,endLevel1 = 1,endLevel2 =1}
local isSwallow = false
-----------------------------------------------
--EquipSwallowPageBaseҳ���е��¼�����
----------------------------------------------
function EquipSwallowPageBase:onEnter(container)
	btnLock = false;
	self:registerPacket(container)
	container:registerMessage(MSG_SEVERINFO_UPDATE)
	self:initData(container)
	self:refreshPage(container);
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_SWALLOW)
end

function EquipSwallowPageBase:initData(container)
	isSwallow = false
end

function EquipSwallowPageBase:onExecute(container)
end

function EquipSwallowPageBase:onExit(container)
	selectedIds = {};
    selectedMap = {}
	self:removePacket(container)
	container:removeMessage(MSG_SEVERINFO_UPDATE)	
end
----------------------------------------------------------------

function EquipSwallowPageBase:refreshPage(container)
	self:showEquipInfo(container);
	self:showGodlyInfo(container);
	self:showCondition(container);
	self:showSourceEquips(container);
end

function EquipSwallowPageBase:showAttrList(userEquip)
	local strList = {}
	local colorList = {}
	if GodEquipLevel.endLevel1 > GodEquipLevel.startLevel1 then
		--196
		local tmpStr=  UserEquipManager:getGodlyAttrAddStr(userEquip,1,GodEquipLevel.startLevel1,GodEquipLevel.endLevel1)
		table.insert(strList,tmpStr)
		table.insert(colorList,GameConfig.ColorMap.COLOR_GREEN)
	end
	if GodEquipLevel.endLevel2 > GodEquipLevel.startLevel2 then
		local tmpStr=  UserEquipManager:getGodlyAttrAddStr(userEquip,2,GodEquipLevel.startLevel2,GodEquipLevel.endLevel2)
		table.insert(strList,tmpStr)
		table.insert(colorList,GameConfig.ColorMap.COLOR_GREEN)
	end
	GodEquipLevel.startLevel1 = GodEquipLevel.endLevel1
	GodEquipLevel.startLevel2 = GodEquipLevel.endLevel2
	insertMessageFlow(strList,colorList)
end

function EquipSwallowPageBase:showEquipInfo(container)
	local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
	if userEquip == nil or userEquip.id == nil then
		return;
	end
	
	local equipId = userEquip.equipId;
	local level = EquipManager:getLevelById(equipId);
	local name	= EquipManager:getNameById(equipId);
	local lb2Str = {
		mLv 				= common:getR2LVL() .. level,
		mLvNum				= userEquip.strength == 0 and "" or "+" .. userEquip.strength,
		mEquipmentName		= common:getLanguageString("@LevelName",  name)
	};
	local sprite2Img = {
		mPic = EquipManager:getIconById(equipId)
	};
	local itemImg2Qulity = {
		mHand = EquipManager:getQualityById(equipId)
	};
	local scaleMap = {mPic = 1.0};	
	
	local nodesVisible = {};
	local gemVisible = false;
	local aniVisible = UserEquipManager:isEquipGodly(userEquip);			
	local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
	if table.maxn(gemInfo) > 0 then
		gemVisible = true;
		for i = 1, 4 do
			local gemId = gemInfo[i];
			nodesVisible["mGemBG" .. i] = gemId ~= nil;
			local gemSprite = "mGem0" .. i;
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
	nodesVisible["mAni"]	= aniVisible;
	nodesVisible["mGemNode"]	= gemVisible;
	NodeHelper:setNodesVisible(container, nodesVisible);
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity);
	
	NodeHelper:addEquipAni(container, "mAni", aniVisible, thisEquipId);
end

function EquipSwallowPageBase:showGodlyInfo(container)
	local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
	local expNeed =  EquipManager:getExpNeedForLevelUp(userEquip.starLevel);
	expNeed = math.max(1, expNeed);
    local validIds = self:getValidIds(selectedIds);
	local allExp1,allExp2 = UserEquipManager:getAllEquipTotalExp(validIds) --��ȡ�������о���

	local starLevel2, starExp2 = 0, 0;
	if userEquip:HasField("godlyAttrId2") and userEquip.godlyAttrId2 > 0 then
		starLevel2, starExp2 = userEquip.starLevel2, userEquip.starExp2;
	end
	local expNeed2 =  EquipManager:getExpNeedForLevelUp(starLevel2, true);
	expNeed2 = math.max(1, expNeed2);
	
    local expNum1 = ""
    local expNum2 = ""

    local mExpSprite = container:getVarScale9Sprite("mExp");
    local mExpNextSprite = container:getVarScale9Sprite("mExpNex");
	if originalExpScaleX == nil then
		originalExpScaleX = mExpSprite:getScaleX();
	end

    if userEquip.starLevel >= GameConfig.LevelLimit.GodlyLevelMax then
        mExpSprite:setScaleX(originalExpScaleX * 1)
        expNum1 = "--"
    else
        mExpSprite:setScaleX(originalExpScaleX * (userEquip.starExp / expNeed));
        expNum1 = userEquip.starExp .. "/" .. expNeed
        local nextRatio = (allExp1+userEquip.starExp)/expNeed
        if nextRatio > 1 then nextRatio = 1;end
        mExpNextSprite:setScaleX(nextRatio);
        mExpNextSprite:setVisible(true)
    end
    	
    local mExpSprite2 = container:getVarScale9Sprite("mExp01");
    local mExpNextSprite2 = container:getVarScale9Sprite("mExpNext01");
	if originalExpScaleX2 == nil then
		originalExpScaleX2 = mExpSprite2:getScaleX();
	end

    if userEquip.starLevel2 >= GameConfig.LevelLimit.GodlyLevelMax then
        mExpSprite2:setScaleX(originalExpScaleX * 1)
        expNum2 = "--"
    else
        mExpSprite2:setScaleX(originalExpScaleX2 * (starExp2 / expNeed2));
        expNum2 = starExp2 .. "/" .. expNeed2
        local nextRatio = (allExp2+starExp2)/expNeed2
        if nextRatio > 1 then nextRatio = 1;end
        mExpNextSprite2:setScaleX(nextRatio);
        mExpNextSprite2:setVisible(true)
    end

	local lb2Str = {
        --��˫
		mGodEquipmentLevel 		= common:getLanguageString("@GodEquipmentLevel1") .. userEquip.starLevel,
		mGodEquipmentExp		= common:getLanguageString("@Exp") .. expNum1,
        --����
		mGodEquipmentLevel01 	= common:getLanguageString("@GodEquipmentLevel2") .. starLevel2,
		mGodEquipmentExp01		= common:getLanguageString("@Exp") .. expNum2
	};


	
	if Golb_Platform_Info.is_r2_platform then
		lb2Str.mGodEquipmentLevel = userEquip.starLevel
		lb2Str.mGodEquipmentLevel01 = starLevel2	
	end
	NodeHelper:setStringForLabel(container, lb2Str);

	NodeHelper:setLabelOneByOne(container,"mGodEquipmentLevelTex1","mGodEquipmentLevel")
	NodeHelper:setLabelOneByOne(container,"mGodEquipmentLevelTex2","mGodEquipmentLevel01")
	if isSwallow == false then
		GodEquipLevel.startLevel1 = userEquip.starLevel
		GodEquipLevel.endLevel1 = userEquip.starLevel
		GodEquipLevel.startLevel2 = starLevel2
		GodEquipLevel.endLevel2 = starLevel2
	else
		isSwallow = false
		GodEquipLevel.endLevel1 = userEquip.starLevel
		GodEquipLevel.endLevel2 = starLevel2
		self:showAttrList(userEquip)
	end
end

function EquipSwallowPageBase:showCondition(container)	
	local coinCostStr, itemCostStr = '--', '--';
	lackInfo.coin = false;
	lackInfo.item = false;
	
	NodeHelper:setNodesVisible(container, {mGold = false, mIcon1 = false})

	local validIds = self:getValidIds(selectedIds);
	if #validIds > 0 then
		NodeHelper:setNodesVisible(container, {mGold = true, mIcon1 = true})
		local coinCost, itemCost = UserEquipManager:getSwallowCost(validIds, thisEquipId);
        
		UserInfo.syncPlayerInfo();
		--coinCostStr = common:getLanguageString("@CurrentOwnInfo", coinCost, UserInfo.playerInfo.coin);
		lackInfo.coin = coinCost > UserInfo.playerInfo.coin;
		NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, "mGold", coinCost, UserInfo.playerInfo.coin, GameConfig.Tag.HtmlLable)
    else
        NodeHelper:addItemIsEnoughHtmlLabNotShowHas(container, "mGold", 0, UserInfo.playerInfo.coin, GameConfig.Tag.HtmlLable)
	end
	
	local lb2Str = {
		--mGold 		= coinCostStr,
		mMaterial 	= itemCostStr
	};
	NodeHelper:setStringForLabel(container, lb2Str);
	
	local colorMap = {
		--mGold 		= common:getColorFromConfig(lackInfo.coin and "Lack" or "Own"),
		mMaterial	= common:getColorFromConfig(lackInfo.item and "Lack" or "Own")
	};
	NodeHelper:setColor3BForLabel(container, colorMap);

	NodeHelper:setLabelOneByOne(container,"mGoldTex","mGold")	
end

function EquipSwallowPageBase:showSourceEquips(container)
	local lb2Str = {};
	local sprite2Img = {};
	local itemImg2Qulity = {};
	local scaleMap = {};
	local nodesVisible = {};
   
    --selectedMap = {}
	for index = 1, COUNT_EQUIPMENT_SOURCE_MAX do
        local userEquipId = selectedMap[index]
        if userEquipId then
            local v = selectedIds[userEquipId]
		    local levelStr = "";
		    local enhanceLvStr = "";
		    local icon = GameConfig.Image.ClickToSelect;
		    local quality = GameConfig.Default.Quality;
		    local qualityBackImg = GameConfig.Image.BackQualityImg
		    local aniVisible = false;
		    local gemVisible = false
		    local name= "m" .. Order[index];
            if v.isEquip then
			    local userEquip = UserEquipManager:getUserEquipById(userEquipId);
			    local equipId = userEquip.equipId;
			    levelStr = common:getR2LVL() .. EquipManager:getLevelById(equipId);
			    enhanceLvStr = userEquip.strength == 0 and "" or "+" .. userEquip.strength;
			    icon = EquipManager:getIconById(equipId);
			    scaleMap[name .. "Pic"]			= 1.0;
			    quality = EquipManager:getQualityById(equipId);
			    qualityBackImg	= NodeHelper:getImageBgByQuality(quality);
			    aniVisible = UserEquipManager:isEquipGodly(userEquip);			
			    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
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

                lb2Str[name .. "Lv"] 			= levelStr;
		        lb2Str[name .. "LvNum"]			= enhanceLvStr;
		        sprite2Img[name .. "Pic"] 		= icon;
		        sprite2Img[name .. "FrameShade"] = qualityBackImg
		        itemImg2Qulity[name .. "Hand"] 	= quality;
		        scaleMap[name .. "Pic"] 		= 1.0;
		        nodesVisible[name .. "Ani"]		= aniVisible;
		        nodesVisible[name .. "GemNode"]	= gemVisible;
		
		        NodeHelper:addEquipAni(container, name .. "Ani", aniVisible, userEquipId);
                index = index + 1
            else
                local userItem = UserItemManager:getUserItemById(userEquipId)
                local itemInfo = ItemManager:getItemCfgById( userItem.itemId )
                levelStr = ""
                enhanceLvStr = ""
                icon = itemInfo.icon
                quality = itemInfo.quality
                qualityBackImg	= NodeHelper:getImageBgByQuality(quality)

                lb2Str[name .. "Lv"] 			= levelStr;
		        lb2Str[name .. "LvNum"]			= enhanceLvStr;
		        sprite2Img[name .. "Pic"] 		= icon;
		        sprite2Img[name .. "FrameShade"] = qualityBackImg
		        itemImg2Qulity[name .. "Hand"] 	= quality;
		        scaleMap[name .. "Pic"] 		= 1.0;
		        nodesVisible[name .. "Ani"]		= aniVisible;
		        nodesVisible[name .. "GemNode"]	= gemVisible;
		
		        NodeHelper:addEquipAni(container, name .. "Ani", aniVisible, userEquipId);
            end
        else
            local name= "m" .. Order[index];
            local levelStr = "";
		    local enhanceLvStr = "";
		    local icon = GameConfig.Image.ClickToSelect;
		    local quality = GameConfig.Default.Quality;
		    local qualityBackImg = GameConfig.Image.BackQualityImg
		    local aniVisible = false;
		    local gemVisible = false

            lb2Str[name .. "Lv"] 			= levelStr;
		    lb2Str[name .. "LvNum"]			= enhanceLvStr;
		    sprite2Img[name .. "Pic"] 		= icon;
		    sprite2Img[name .. "FrameShade"] = qualityBackImg
		    itemImg2Qulity[name .. "Hand"] 	= quality;
		    scaleMap[name .. "Pic"] 		= 1.0;
		    nodesVisible[name .. "Ani"]		= aniVisible;
		    nodesVisible[name .. "GemNode"]	= gemVisible;
        end
	end
	
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
	NodeHelper:setQualityFrames(container, itemImg2Qulity, nil, true);
end
	
----------------click event------------------------
function EquipSwallowPageBase:showHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_SWALLOW);
end

function EquipSwallowPageBase:onClose(container)
	PageManager.popPage(thisPageName);
end	

function EquipSwallowPageBase:onSwallow(container)
	if btnLock then return; end
	
	if not (UserEquipManager:canSwallow(thisEquipId)) then
		MessageBoxPage:Msg_Box_Lan("@EquipmentStarLevelHighest");
		return;
	end	
	
	local validIds = self:getValidIds(selectedIds);
	if #validIds > 0 then
		for _, id in ipairs(validIds) do
			if UserEquipManager:hasGem(id) then
				MessageBoxPage:Msg_Box_Lan("@SelectedEquipHasGem");
				return;
			end
		end
		
		if lackInfo.item then
			MessageBoxPage:Msg_Box_Lan("@GodlyEquipStoneNotEnough");
			return;
		elseif lackInfo.coin then
			PageManager.notifyLackCoin();
			return;
		end
		
		local callback = function(isSure)
			if isSure then
				EquipOprHelper:swallowEquip(thisEquipId, validIds);
				btnLock = true;
			end
		end
		--��������ȼ����ޣ�������ʾ
		local title = common:getLanguageString("@Artifacttitle")
		local overflowExp1,overflowExp2 = self:getOverflowExp(validIds)
		if overflowExp1 and overflowExp1 >0 and overflowExp2 and overflowExp2 > 0 then
			PageManager.showConfirm(title, common:getLanguageString("@Artifacttxt3"), callback);
		elseif overflowExp1 and overflowExp1 >0 then
			PageManager.showConfirm(title, common:getLanguageString("@Artifacttxt1"), callback);
		elseif overflowExp2 and overflowExp2 > 0 then
			PageManager.showConfirm(title, common:getLanguageString("@Artifacttxt2"), callback);
		else
			callback(true)
		end
	else
		MessageBoxPage:Msg_Box_Lan("@PlzSelectGodlyEquip");
	end
end

function EquipSwallowPageBase:onAutoSelect(container)
	if not (UserEquipManager:canSwallow(thisEquipId)) then
		MessageBoxPage:Msg_Box_Lan("@EquipmentStarLevelHighest");
		return;
	end
	local ids = UserEquipManager:getEquipIdsForSwallow(thisEquipId, true) or {};
	if #ids <= 0 then
		MessageBoxPage:Msg_Box_Lan("@NoGodlyEquipToSelect");
		return;
	end
    selectedIds = {}
    selectedMap = {}
    local index = 1
    for i = 1, #ids do
        local userEquipId = ids[i];
	    local userEquip   = UserEquipManager:getUserEquipById(userEquipId);
	    local equipId     = userEquip.equipId;
        if not selectedIds[userEquipId] then
        	local validIds = self:getValidIds(selectedIds)
        	if self:CheckCanSelectEquip(validIds,userEquipId) then
            	selectedIds[userEquipId] = {
            	    isEquip = equipId ~= nil,
            	    num = 1
            	}
            	selectedMap[index] = userEquipId
            	index = index + 1
            end
        else
            if not equipId then
            	local validIds = self:getValidIds(selectedIds)
            	if self:CheckCanSelectEquip(validIds,userEquipId) then
                	selectedIds[userEquipId].num = selectedIds[userEquipId].num + 1
                	selectedMap[index] = userEquipId
                	index = index + 1
                end
            end
        end
    end
	self:refreshPage(container)
end

function EquipSwallowPageBase:getOverflowExp(validIds)
	local enable, limitPos = UserEquipManager:canSwallow(thisEquipId)
	local overflowExp1, overflowExp2 = UserEquipManager:getAllEquipTotalExp(validIds)
	if not enable then
		return overflowExp1, overflowExp2
	end
	local userEquip = UserEquipManager:getUserEquipById(thisEquipId)
	if limitPos == 1 or limitPos == nil and overflowExp1 > 0 then
		local lv = userEquip.starLevel
		local lvExp = EquipManager:getExpNeedForLevelUp(lv)
		local exp = userEquip.starExp + overflowExp1
		while exp >= lvExp do
			exp = exp - lvExp
			lv = lv + 1
			lvExp = EquipManager:getExpNeedForLevelUp(lv)
			if lv >= GameConfig.LevelLimit.GodlyLevelMax then
				break
			end
		end
		if lv >= GameConfig.LevelLimit.GodlyLevelMax then
			overflowExp1 = exp
		else
			overflowExp1 = nil
		end
	end

	if limitPos == 2 or limitPos == nil and overflowExp2 > 0 then
		local lv = userEquip.starLevel2
		local lvExp = EquipManager:getExpNeedForLevelUp(lv,true)
		local exp = userEquip.starExp2 + overflowExp2
		while exp >= lvExp do
			exp = exp - lvExp
			lv = lv + 1
			lvExp = EquipManager:getExpNeedForLevelUp(lv,true)
			if lv >= GameConfig.LevelLimit.GodlyLevelMax then
				break
			end
		end
		if lv >= GameConfig.LevelLimit.GodlyLevelMax then
			overflowExp2 = exp
		else
			overflowExp2 = nil
		end
	end
	return overflowExp1, overflowExp2
end

function EquipSwallowPageBase:CheckCanSelectEquip(validIds,equipId,isShowMsg)
	local enable, limitPos = UserEquipManager:canSwallow(thisEquipId)
	if not enable then return false end
	if #validIds >= COUNT_EQUIPMENT_SOURCE_MAX then return false end

	local userEquip = UserEquipManager:getUserEquipById(thisEquipId)
	local addExp1,addExp2 = UserEquipManager:getAllEquipTotalExp(validIds)
	local exp1,exp2 = UserEquipManager:getAllEquipTotalExp({[1] = equipId})
	if limitPos == 1 or limitPos == nil and exp1 > 0 then
		local lv = userEquip.starLevel
		local lvExp = EquipManager:getExpNeedForLevelUp(lv)
		local exp = userEquip.starExp + addExp1
		while exp >= lvExp do
			exp = exp - lvExp
			lv = lv + 1
			lvExp = EquipManager:getExpNeedForLevelUp(lv)
			if lv >= GameConfig.LevelLimit.GodlyLevelMax then
				if isShowMsg then 
            		MessageBoxPage:Msg_Box_Lan("@Artifacttips1");
				end
				return false
			end
		end
		return true
	end

	if limitPos == 2 or limitPos == nil and exp2 > 0 then
		local lv = userEquip.starLevel2
		local lvExp = EquipManager:getExpNeedForLevelUp(lv,true)
		local exp = userEquip.starExp2 + addExp2
		while exp >= lvExp do
			exp = exp - lvExp
			lv = lv + 1
			lvExp = EquipManager:getExpNeedForLevelUp(lv,true)
			if lv >= GameConfig.LevelLimit.GodlyLevelMax then
				if isShowMsg then 
            		MessageBoxPage:Msg_Box_Lan("@Artifacttips2");
				end
				return false
			end
		end
		return true
	end
	return false
end

function EquipSwallowPageBase:goSelectEquip(container, eventName)
	local pos = common:table_arrayIndex(Order, eventName:sub(3):sub(1, -5));

    -- if UserItemManager.contentSelectIds[pos] then
    --     UserItemManager.contentSelectIds[pos] = nil
    -- end
    local selectedId = selectedMap[pos]
	if selectedId then
        selectedMap[pos] = nil
        local item = selectedIds[selectedId]
        if item then
            if item.isEquip then
                selectedIds[selectedId] = nil
            else
                if item.num > 1 then
                    item.num = item.num - 1
                else
                    selectedIds[selectedId] = nil
                end
            end
		    self:refreshPage(container);
		    return;
        end
	end
	
	if not (UserEquipManager:canSwallow(thisEquipId)) then
		MessageBoxPage:Msg_Box_Lan("@EquipmentStarLevelHighest");
		return;
	end

	local checkCanSelectCallback = function(ids,userEquipId)
		local validIds = self:getValidIds(ids)
        local canSelect = self:CheckCanSelectEquip(validIds,userEquipId,true)
        return canSelect
	end
    require("EquipSelectPage")
	EquipSelectPage_multiSelect(selectedIds or {}, COUNT_EQUIPMENT_SOURCE_MAX, function(ids)
		--if not common:table_isSame(validIds, ids) then
            local index = 1
            selectedMap = {}
            for k,v in pairs(ids) do
                if v.isEquip then
                    selectedMap[index] = k
                    index = index + 1
                else
                    local totalNum = math.min(index + v.num - 1,COUNT_EQUIPMENT_SOURCE_MAX)
                    for i = index, totalNum do
                        selectedMap[index] = k
                        index = index + 1
                    end
                end
            end
			selectedIds = ids
		--end
		self:refreshPage(container);
	end, thisEquipId, EquipFilterType.Swallow,checkCanSelectCallback);
	PageManager.pushPage("EquipSelectPage");
end

function EquipSwallowPageBase:getValidIds(sourceIds)
    local ids = {}
    for k,v in pairs(sourceIds or {}) do
        if v.isEquip then
            table.insert(ids,k)
        else
            for i = 1, v.num do
                table.insert(ids, k)
            end
        end
    end
	return ids
end

--�ذ�����
function EquipSwallowPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	--local msgBuff = container:getRecPacketBuffer()

	if opcode == opcodes.EQUIP_SWALLOW_S then
		selectedIds = {};
        selectedMap = {}
		isSwallow = true
		self:refreshPage(container);
		btnLock = false;
	elseif opcode == opcodes.ERROR_CODE_S then
		btnLock = false;
	end
end

function EquipSwallowPageBase:onPacketError(container)
	btnLock = false;
end

function EquipSwallowPageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function EquipSwallowPageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipSwallowPage = CommonPage.newSub(EquipSwallowPageBase, thisPageName, option);

function EquipSwallowPage_setEquipId(equipId)
	thisEquipId = equipId;
end	

