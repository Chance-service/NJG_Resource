
----------------------------------------------------------------------------------
local Const_pb     = require("Const_pb");
local UserInfo     = require("PlayerInfo.UserInfo");
local thisPageName = "FullAttributePage"
local GameConfig   = require("GameConfig") 

local HelpConfg = {}
local option = {
	ccbiFile = "GeneralHelpPopUp4.ccbi",
	handlerMap = {
		onClose 		= "onClose"
	},
	opcode = opcodes
};

local FullAttributePageBase = {}

local NodeHelper = require("NodeHelper");
--------------------------------------------------------------
local function getBasicInfo()
	local level = UserInfo.roleInfo.level;
	local prof = common
	local tb = {
		--common:fillHtmlStr("LvNameProf", level, UserInfo.roleInfo.name, UserInfo.getProfessionName()),
		common:fill(FreeTypeConfig[23].content, UserInfo.roleInfo.fight, level)
	};
	return table.concat(tb, "<br/>");
end

local function getBasicAttr()
	local basicAttrs = {
        Const_pb.HP,
		Const_pb.MP,
		Const_pb.STRENGHT,
		Const_pb.AGILITY,
		Const_pb.INTELLECT,
		Const_pb.STAMINA,

	};
	local prof2MainAttr = {
		[Const_pb.WARRIOR] 	= Const_pb.STRENGHT,
		[Const_pb.HUNTER]	= Const_pb.AGILITY,
		[Const_pb.MAGIC]	= Const_pb.INTELLECT
	};
	local tb = {
		FreeTypeConfig[24].content,
	};
	local mainAttrId = prof2MainAttr[UserInfo.roleInfo.prof];
	
	local contentIdBase = 26;
	for i, attrId in ipairs(basicAttrs) do
		local contentId = i + contentIdBase;
		local val = UserInfo.getRoleAttrById(attrId);
		local str = FreeTypeConfig[contentId].content;
		local dmgStr = "";
		if attrId == mainAttrId then
			local minRatio, maxRatio = 0.5, 1.0;
			if attrId == Const_pb.INTELLECT then
				minRatio, maxRatio = 0.6, 1.2;
			end
			dmgStr = common:fill(FreeTypeConfig[42].content, math.floor(val * minRatio), math.floor(val * maxRatio));
		end
		if attrId == Const_pb.STRENGHT then
			str = common:fill(str, val, val, math.floor(0.6 * val), dmgStr);
		elseif attrId == Const_pb.AGILITY then
			str = common:fill(str, val, val, math.floor(0.2 * val), dmgStr);
		elseif attrId == Const_pb.INTELLECT then
			str = common:fill(str, val, val, math.floor(math.sqrt(val)), dmgStr);
		elseif attrId == Const_pb.STAMINA then
			str = common:fill(str, val, val * 10, val);
		else
			str = common:fill(str, val);
		end
		table.insert(tb, str);
	end
	return table.concat(tb, "<br/>");	
end

local function getFightAttr()
	local fightAttrs = {
		Const_pb.MINDMG,
		Const_pb.MAXDMG,
		Const_pb.ARMOR,
		Const_pb.PHYDEF,
		Const_pb.MAGDEF,
		Const_pb.CRITICAL,
		Const_pb.HIT,
		Const_pb.DODGE,
		Const_pb.RESILIENCE
	};

	
	local tb = {
		FreeTypeConfig[25].content
	};
	local contentIdBase = 32;
	if IsFrenchLanguage() then
         for i, attrId in ipairs(fightAttrs) do
		local contentId = i + contentIdBase;
		local val = UserInfo.getRoleAttrById(attrId);
		local str = FreeTypeConfig[contentId].content;
		if attrId == Const_pb.ARMOR 
			or attrId == Const_pb.PHYDEF 
			or attrId == Const_pb.MAGDEF
		then
			str = common:fill(str, val, ProcessFrancNum(EquipManager:getBattleAttrEffect(attrId, val)));
		elseif attrId == Const_pb.CRITICAL then
			local dmg = UserInfo.getRoleAttrById(Const_pb.BUFF_CRITICAL_DAMAGE);
			local dmgStr = string.format("%.1f", (180.0 + dmg * 0.01));
			str = common:fill(str, val, ProcessFrancNum(EquipManager:getBattleAttrEffect(attrId, val)), ProcessFrancNum(dmgStr));
		else
			str = common:fill(str, val);
		end
		table.insert(tb, str);
	    end
    else
        for i, attrId in ipairs(fightAttrs) do
		local contentId = i + contentIdBase;
		local val = UserInfo.getRoleAttrById(attrId);
		local str = FreeTypeConfig[contentId].content;
		if attrId == Const_pb.ARMOR 
			or attrId == Const_pb.PHYDEF 
			or attrId == Const_pb.MAGDEF
		then
			str = common:fill(str, val, EquipManager:getBattleAttrEffect(attrId, val));
		elseif attrId == Const_pb.CRITICAL then
			local dmg = UserInfo.getRoleAttrById(Const_pb.BUFF_CRITICAL_DAMAGE);
			local dmgStr = string.format("%.1f", (180.0 + dmg * 0.01));
			str = common:fill(str, val, EquipManager:getBattleAttrEffect(attrId, val), dmgStr);
		else
			str = common:fill(str, val);
		end
		table.insert(tb, str);
	    end
    end
	return table.concat(tb, "<br/>");	
end

local function getGodlyAttr()
	local tb = {
		FreeTypeConfig[26].content
	};
	for i = 1, 2 do
		for _, attrId in ipairs(GameConfig['Part2GodlyAttr_' .. i]) do
			local name = common:getLanguageString("@AttrName_" .. attrId);
			local val = UserInfo.getRoleAttrById(attrId);
			if val > 0 then
				local valStr = EquipManager:getGodlyAttrString(attrId, val, "%.1f%%");
				local strSplit = ": "
   				if  GamePrecedure:getInstance():getI18nSrcPath() == "French" then
		     		strSplit = " : "
		     	end
				local str = string.format("%s%s%s", name, strSplit, valStr);
				if EquipManager:isGodlyAttrPureNum(attrId) then
					local battleAttr = EquipManager:getBattleAttrEffect(attrId, val);
					local avoidStr = common:getLanguageString("@AttrAvoid_" .. attrId);
					table.insert(tb, common:fillHtmlStr("FullGodlyAttr_1", str, battleAttr, avoidStr));
				else
					table.insert(tb, common:fillHtmlStr("FullGodlyAttr", str));
				end
			end
		end
	end
	return table.concat(tb, "<br/>");
end

local function getElementAttr()
    local elementAttrs = {
		Const_pb.ICE_ATTACK,
		Const_pb.FIRE_ATTACK,
		Const_pb.THUNDER_ATTACK,
		Const_pb.ICE_DEFENCE,
		Const_pb.FIRE_DEFENCE,
		Const_pb.THUNDER_DENFENCE
	};
	local elementAttrsRatio = {
		Const_pb.ICE_ATTACK_RATIO,
		Const_pb.FIRE_ATTACK_RATIO,
		Const_pb.THUNDER_ATTACK_RATIO,
		Const_pb.ICE_DEFENCE_RATIO,
		Const_pb.FIRE_DEFENCE_RATIO,
		Const_pb.THUNDER_DENFENCE_RATIO
	}
    local tb = {
        FreeTypeConfig[250].content
    }
    local contentIdBase = 250
    for i, attrId in pairs(elementAttrs) do 
        local contentId = contentIdBase + i
        local val = UserInfo.getRoleAttrById(attrId);
        if val ~= 0 then
            local str = FreeTypeConfig[contentId].content;
           
        	local valRaito = UserInfo.getRoleAttrById(elementAttrsRatio[i])
            if valRaito~=0 then
            	local valRatioStr = "(+"..(valRaito/100).."%"..")"
            	str = common:fill(str, val, valRatioStr)
            else
            	str = common:fill(str, val, "")
            end
            table.insert(tb, str);
        end
    end
    return table.concat(tb, "<br/>");
end
-----------------------------------------------
--FullAttributePageBase页面中的事件处理
----------------------------------------------
function FullAttributePageBase:onEnter(container)
	self:refreshPage(container);
end

function FullAttributePageBase:onExit(container)
	local mContent = container:getVarScrollView("mContent");
	if mContent then
		mContent:removeAllChildren();
	end
end
----------------------------------------------------------------

function FullAttributePageBase:refreshPage(container)
	NodeHelper:setStringForLabel(container, {mTitle = common:getLanguageString("@MoreAttrTitle")});

    --屏蔽name、职业显示
    --[[local strTitle = common:fillHtmlStr("LvNameProf", UserInfo.getStageAndLevelStr(), UserInfo.roleInfo.name, UserInfo.getProfessionName())
    local mTitle = container:getVarLabelBMFont("mAttributeLevel") 
    NodeHelper:addHtmlLable(mTitle, strTitle, GameConfig.Tag.HtmlLable,CCSizeMake(700,100));]]--
	
	local mContent = container:getVarScrollView("mContent");
	local width = mContent:getContentSize().width;--没有内容，这个一直是0 要用viewsize
	local attrTb = {
    	--getElementAttr(),
        getGodlyAttr(),
        getFightAttr(),
        getBasicAttr(),
		--getBasicInfo()
	};
	local lineWidth = GameConfig.LineWidth.MoreAttribute
    local label      = nil
    local nodeParent = nil
    local fPoxY      = 0
    local fDistence  = 20
    for i = 1, #attrTb do
        label = CCHTMLLabel:createWithString(attrTb[i], CCSizeMake(lineWidth - 45, 600))
        label:setAnchorPoint(ccp(0, 0.5))
        local fParentHeight = label:getContentSize().height + fDistence * 2
		local sprite = CCSprite:createWithSpriteFrameName(GameConfig.Scale9SpriteImage[1])
		nodeParent= CCScale9Sprite:createWithSpriteFrame(sprite:displayFrame())
        nodeParent:setContentSize(CCSizeMake(GameConfig.LineWidth.MoreAttribute, fParentHeight))
        --nodeParent:setAnchorPoint(ccp(0.5, 0.5)) --误导人的代码 addChild 会把锚点设置为0，0
        label:setPosition(ccp(20, fParentHeight / 2))
        nodeParent:addChild(label)
        nodeParent:setPosition(ccp(0, fPoxY))
        mContent:addChild(nodeParent)
        fPoxY = fPoxY + fParentHeight + fDistence
    end
	mContent:setContentSize(CCSizeMake(width, fPoxY));
	mContent:setContentOffset(ccp(0, mContent:getViewSize().height - fPoxY));
end

----------------click event------------------------
function FullAttributePageBase:onClose(container)
	PageManager.popPage(thisPageName);
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
FullAttributePage = CommonPage.newSub(FullAttributePageBase, thisPageName, option);