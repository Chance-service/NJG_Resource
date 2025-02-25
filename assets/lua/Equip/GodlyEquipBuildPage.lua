----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local ceil = math.ceil;
--------------------------------------------------------------------------------
local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = "GodlyEquipBuildPage"
local NewbieGuideManager = require("NewbieGuideManager")
local NodeHelper = require("NodeHelper");
local opcodes = {
    EQUIP_SPECIAL_CREATE_S = HP_pb.EQUIP_SPECIAL_CREATE_S
}

local option = {
    ccbiFile = "RefiningCreateGodPopUp_1.ccbi",
    handlerMap =
    {
        onGodEquipmentFusion = "onCompound",
        onClose = "onClose",
        onHelp = "onHelp"
    },
    opcode = opcodes
};

local GodlyEquipBuildPageBase = { }

local EquipOprHelper = require("Equip.EquipOprHelper");

local PageInfo = {
    optionEquips = { },
    userLv = 0
};
local thisScrollView = nil;
local thisScrollViewOffset = nil;

--------------------------------------------------------------
local EquipItem = {
    ccbiFile = "RefiningCreateGodContent.ccbi",
    initTexHeight = nil,
    initSize =
    {
        container = nil
    },
    top = nil
};

function EquipItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        EquipItem.onRefreshItemView(container);
    elseif eventName == "onCreate" then
        EquipItem.onBuild(container);
    end
end

function EquipItem.dressEquip(container)
    local contentId = container:getTag();
    local userEquipId = PageInfo.optionEquips[contentId];
    EquipOprHelper:dressEquip(userEquipId, PageInfo.roleId, PageInfo.dressType);
end

function EquipItem_onBuild(container)
    local contentId = container:getItemDate().mID;
    local equipCfg = PageInfo.optionEquips[contentId];
    if UserInfo.playerInfo.reputationValue < 1000 then
        PageManager.pushPage("NewbieGuideForcedPage")
        return;
    elseif UserInfo.playerInfo.smeltValue < 8000 then
        PageManager.pushPage("NewbieGuideForcedPage")
        return;
    end
    EquipOprHelper:buildGodlyEquip(equipCfg["id"]);
end

function EquipItem.onBuild(container)
    --    local contentId = container:getItemDate().mID;
    --    local equipCfg = PageInfo.optionEquips[contentId];

    --    local needReputation, needSmeltValue = tonumber(equipCfg["reputation"]), equipCfg["smeltValue"];
    --    local title = common:getLanguageString("@SpecialBuildEquip_Title");
    --    local msg = common:getLanguageString("@SpecialBuildEquip_Msg", needReputation, needSmeltValue);
    --    PageManager.showConfirm(title, msg, function(isSure)
    --        if isSure then
    --            if needReputation > UserInfo.playerInfo.reputationValue then
    --                MessageBoxPage:Msg_Box_Lan("@ReputationNotEnough");
    --                return;
    --            elseif needSmeltValue > UserInfo.playerInfo.smeltValue then
    --                MessageBoxPage:Msg_Box_Lan("@SmeltValueNotEnough");
    --                return;
    --            end
    --            EquipOprHelper:buildGodlyEquip(equipCfg["id"]);
    --        end
    --    end );




    local contentId = container:getItemDate().mID;
    -- local contentId = self.id;
    local equipCfg = PageInfo.optionEquips[contentId];
    local needReputation, needSmeltValue = tonumber(equipCfg["reputation"]), equipCfg["smeltValue"];
    local title = common:getLanguageString("@SpecialBuildEquip_Title");
    -- local msg = common:getLanguageString("@SpecialBuildEquip_Msg", needReputation, needSmeltValue);


    --    if needReputation > UserInfo.playerInfo.reputationValue then
    --        -- 威名不足
    --        errorMessage = "@ReputationNotEnough"
    --        MessageBoxPage:Msg_Box_Lan(errorMessage)
    --        return
    --    elseif needSmeltValue > UserInfo.playerInfo.smeltValue then
    --        -- 融合经验值不足
    --        errorMessage = "@SmeltValueNotEnough"
    --        MessageBoxPage:Msg_Box_Lan(errorMessage)
    --        return
    --    end

    local maxCount = 0
    local count_1 = math.modf(UserInfo.playerInfo.reputationValue / needReputation)
    local count_2 = math.modf(UserInfo.playerInfo.smeltValue / needSmeltValue)

    maxCount = count_1
    if count_1 > count_2 then
        maxCount = count_2
    end

    if maxCount <= 0 then
        maxCount = 1
    elseif maxCount > 99 then
        maxCount = 99
    end

    PageManager.showCountTimesWithIconPage(Const_pb.EQUIP, equipCfg.equipId, 8,
    function(count)
        return count * needReputation, count * needSmeltValue
    end ,
    function(isBuy, count)
        if isBuy then
            EquipOprHelper:buildGodlyEquip(equipCfg["id"], count);
        end
    end , true, maxCount, title, "@MakeGodlyEquipNoEnoughMaterial")
end	

function EquipItem.onRefreshItemView(container)
    local contentId = container:getItemDate().mID;
    local equipCfg = PageInfo.optionEquips[contentId];
    local equipId = equipCfg["equipId"];

    local level = EquipManager:getLevelById(equipId);
    local name = EquipManager:getNameById(equipId);
    local quality = EquipManager:getQualityById(equipId);
    local attrStr = common:split(common:stringAutoReturn(EquipManager:getInitAttr(equipId,"\n"), 200), "\n")
    if attrStr[2] == nil then
        attrStr[2] = ""
    end
    
    local lb2Str = {
        mEquipmentName = "Lv." .. level .. " " .. common:getLanguageString("@LevelName",name),
        -- mAttribute = common:stringAutoReturn(EquipManager:getInitAttr(equipId,"\n"), 200),
        mAttribute1 = attrStr[1],
        mAttribute2 = attrStr[2],
        mGodAttribute = EquipManager:getGodlyAttr(equipId,equipCfg["attrCount"],"\n"),
        -- mPrestigeUnlockNum	= common:getLanguageString("@OpenWithReputation", equipCfg["reputation"]),
        mEquipmentPosition = EquipManager:getPartNameById(equipId)
    }



    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId)
    }
    local itemImg2Qulity = {
        mHand = quality
    }
    local scaleMap = { mPic = GameConfig.EquipmentIconScale };

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);

    -- getVarLabelTTF
    --[[
    local node_1 = container:getVarNode("mEquipmentName")
    local node_2 = container:getVarNode("mAttribute")
    local node_3 = container:getVarNode("mGodAttribute")
    if node_1 and node_2 and node_3 then
        node_2:setPosition(ccp(node_1:getPositionX(), node_1:getPositionY() - node_1:getContentSize().height - 3))
        node_3:setPosition(ccp(node_2:getPositionX(), node_2:getPositionY() - node_2:getContentSize().height - 3))
    end
    ]]--
    local aniNode = container:getVarNode("mEquipmentAni");
    if aniNode then
        aniNode:removeAllChildren();
        local ccbiFile = EquipManager:getGodlyAni(equipCfg["attrCount"]);
        local ani = CCBManager:getInstance():createAndLoad2(ccbiFile);
        ani:unregisterFunctionHandler();
        aniNode:addChild(ani);
    end
    local GuideManager = require("Guide.GuideManager")
    if EquipManager:getProfession(equipId) then
        GuideManager.PageContainerRef["CreateEquipPage"] = container
    end
    if contentId == 1 and GuideManager.getCurrentStep() == 20 and GuideManager.IsNeedShowPage then
        PageManager.popPage("NewGuideEmptyPage")
        PageManager.pushPage("NewbieGuideForcedPage")
        GuideManager.IsNeedShowPage = false
    end
end	
----------------------------------------------------------------------------------

-----------------------------------------------
-- GodlyEquipBuildPageBaseҳ���е��¼�����
----------------------------------------------
-- function GodlyEquipBuildPageBase:onEnter(container)
-- NodeHelper:setStringForLabel(container, {
-- 	mMeltingNum 	= common:getLanguageString("@BuildGodlyCost"),
-- 	mSmeltingNum	= common:getLanguageString("@SmeltValueTip")
-- });
-- self:registerPacket(container)
-- self:setOptionEquips();

-- self:initScrollview(container);

-- self:refreshPage(container);
-- self:rebuildAllItem(container);
-- thisScrollView = container.mScrollView;
-- NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FORGEGODLY)
-- end
local mParentContainer = nil
function GodlyEquipBuildPageBase:onEnter(ParentContainer)

    mParentContainer = ParentContainer
    self.container = ScriptContentBase:create(option.ccbiFile)


    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))
    NodeHelper:autoAdjustResizeScrollview(self.container:getVarScrollView("mContent"))

    NodeHelper:setStringForLabel(self.container, {
        mMeltingNum = common:getLanguageString("@BuildGodlyCost"),
        mSmeltingNum = common:getLanguageString("@SmeltValueTip")
    } );
    self:registerPacket(mParentContainer)
    self:setOptionEquips();

    self:initScrollview(self.container);

    self:refreshPage(self.container);
    self:rebuildAllItem(self.container);
    thisScrollView = self.container.mScrollView;
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FORGEGODLY)
    return self.container
end

function GodlyEquipBuildPageBase:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(self.container);
    thisScrollView = nil;
    thisScrollViewOffset = nil;
end
----------------------------------------------------------------

function GodlyEquipBuildPageBase:setOptionEquips()
    local userLevel = UserInfo.roleInfo.level;
    if PageInfo.userLv ~= userLevel or common:table_isEmpty(PageInfo.optionEquips) then
        PageInfo.optionEquips = { };
        for _, cfg in ipairs(ConfigManager.getGodlyEquipCanBuild() or { }) do
            if cfg["minLv"] <= userLevel and cfg["maxLv"] >= userLevel then
                table.insert(PageInfo.optionEquips, cfg);
            end
        end
        PageInfo.userLv = userLevel;
    end
end

function GodlyEquipBuildPageBase:refreshPage(container)
    self:showMyRP(container);
end	

function GodlyEquipBuildPageBase:showMyRP(container)
    local rpStr = common:getLanguageString("@MyReputation", UserInfo.playerInfo.reputationValue);
    local smeltStr = common:getLanguageString('@MySmelting', UserInfo.playerInfo.smeltValue);
    NodeHelper:setStringForLabel(container, {
        mMyReputationNum = rpStr,
        mMySmeltingNum = smeltStr
    } );
end
----------------scrollview-------------------------
function GodlyEquipBuildPageBase:initScrollview(container)
    NodeHelper:initScrollView(container, "mContent", 10);
end

function GodlyEquipBuildPageBase:rebuildAllItem(container)
    self:clearAllItem(container);
    if #PageInfo.optionEquips > 0 then
        self:buildItem(container);
    end
end

function GodlyEquipBuildPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container);
end

function GodlyEquipBuildPageBase:buildItem(container)
    local size = #PageInfo.optionEquips;
    NodeHelper:buildScrollView(container, size, EquipItem.ccbiFile, EquipItem.onFunction)
    -- container.mScrollView:setContentOffset(ccp(0, 0))
    -- self.mScrollView:orderCCBFileCells()
    if thisScrollView and thisScrollViewOffset then
        thisScrollView:setContentOffset(thisScrollViewOffset);
    end
end
	
----------------click event------------------------
-- �����ں�
function GodlyEquipBuildPageBase:onCompound(container)
    local compoundPage = "EquipCompoundPage";
    PageManager.pushPage(compoundPage);
end

function GodlyEquipBuildPageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

function GodlyEquipBuildPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_FORGEGODLY);
end

-- �ذ�����
function GodlyEquipBuildPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()

    if opcode == opcodes.EQUIP_SPECIAL_CREATE_S then
        self:refreshPage(self.container)
        PageManager.refreshPage("ArenaPage");
        PageManager.refreshPage("MeltPage");
        return
    end
end

function GodlyEquipBuildPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:registerPacket(opcode)
        end
    end
end

function GodlyEquipBuildPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            mParentContainer:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
return GodlyEquipBuildPageBase

-- local CommonPage = require("CommonPage");
-- GodlyEquipBuildPage = CommonPage.newSub(GodlyEquipBuildPageBase, thisPageName, option);	