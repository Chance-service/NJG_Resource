----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local EquipOpr_pb = require("EquipOpr_pb");
local HP_pb = require("HP_pb");
local UserInfo = require("PlayerInfo.UserInfo");
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
local table = table;
--------------------------------------------------------------------------------

local thisPageName = "EquipExtendPage";
local thisEquipId = 0;
local targetEquipId = 0;

local opcodes = {
    EQUIP_EXTEND_S = HP_pb.EQUIP_EXTEND_S
};

local option = {
    ccbiFile = "EquipmentInheritPopUp.ccbi",
    handlerMap =
    {
        onInherit = "onExtend",
        onAnotherHand = "onSelect",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
};

local EquipExtendPageBase = { };

local NodeHelper = require("NodeHelper");
local EquipOprHelper = require("Equip.EquipOprHelper");
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local NewbieGuideManager = require("NewbieGuideManager")

local hasExtended = false;
local lackInfo = { coin = false };
-----------------------------------------------
-- EquipExtendPageBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function EquipExtendPageBase:onEnter(container)

    self.container = container
    self.container.mScrollView = container:getVarScrollView("mContent")

    hasExtended = false;

    NodeHelper:setNodesVisible(container, { mExtendBtnNode = true, mDetermineBtnNode = false })

    self:registerPacket(container);
    self:refreshPage(container);
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_EXTEND)
end

function EquipExtendPageBase:onExit(container)
    hasExtended = false;
    targetEquipId = 0;
    self:removePacket(container);
end
----------------------------------------------------------------

function EquipExtendPageBase:refreshPage(container)
    self:showEquipInfo(container);
    self:showTargetEquipInfo(container);
    self:showExtendInfo(container);
    self:showConsumeInfo(container);
end

function EquipExtendPageBase:showEquipInfo(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    if userEquip == nil or userEquip.id == nil then
        return;
    end

    local equipId = userEquip.equipId;
    local level = EquipManager:getLevelById(equipId);
    local name = EquipManager:getNameById(equipId);
    local quality = EquipManager:getQualityById(equipId)
    local lb2Str = {
        mLv = "",
        -- common:getR2LVL() .. level,
        mLv1 = common:getR2LVL() .. level,
        mLvNum = userEquip.strength == 0 and "" or "+" .. userEquip.strength,
        mName1 = name
    };
    local sprite2Img = {
        mPic = EquipManager:getIconById(equipId)
    };
    local itemImg2Qulity = {
        mHand = EquipManager:getQualityById(equipId)
    };
    local scaleMap = { mPic = GameConfig.EquipmentIconScale };

    local nodesVisible = { };
    local gemVisible = false;
    local aniVisible = UserEquipManager:isEquipGodly(userEquip);
    local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
    for i = 1, 4 do
        nodesVisible["mGemBG" .. i] = gemId ~= nil;
        local gemSprite = "mGem0" .. i;
        nodesVisible[gemSprite] = false;
		scaleMap[gemSprite] = 1
    end

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
					scaleMap[gemSprite] = 1
                end
            end
        end
    end
    nodesVisible["mAni"] = aniVisible;
    nodesVisible["mGemNode"] = gemVisible;
    NodeHelper:setNodesVisible(container, nodesVisible);

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);
    NodeHelper:setQualityBMFontLabels(container, { mLv2 = quality, mName2 = quality })

    NodeHelper:addEquipAni(container, "mAni", aniVisible, thisEquipId);
end

function EquipExtendPageBase:showTargetEquipInfo(container)
    local lb2Str = {
        mAnotherLv = "",
        mAnotherLvNum = "",
        mName2 = "",
        mLv2 = ""
    };
    local sprite2Img = {
        mAnotherPic = GameConfig.Image.ClickToSelect,
        mAnotherFrameShade = GameConfig.Image.BackQualityImg
    };
    local itemImg2Qulity = {
        mAnotherHand = GameConfig.Default.Quality
    };
    local scaleMap = { mAnotherPic = GameConfig.EquipmentIconScale };
    local aniVisible = false;

    if targetEquipId and targetEquipId > 0 then
        local userEquip = UserEquipManager:getUserEquipById(targetEquipId);
        if userEquip == nil or userEquip.id == nil then
            return;
        end

        local equipId = userEquip.equipId;
        local level = EquipManager:getLevelById(equipId);
        local name = EquipManager:getNameById(equipId);
        local quality = EquipManager:getQualityById(equipId)
        lb2Str = {
            mAnotherLv = "",
            -- common:getR2LVL() .. level,
            mAnotherLvNum = userEquip.strength == 0 and "" or "+" .. userEquip.strength,
            mLv2 = common:getR2LVL() .. level,
            mName2 = name
        };
        sprite2Img = {
            mAnotherPic = EquipManager:getIconById(equipId),
            mAnotherFrameShade = NodeHelper:getImageBgByQuality(quality)
        };
        itemImg2Qulity = {
            mAnotherHand = EquipManager:getQualityById(equipId)
        };

        local nodesVisible = { };
        local gemVisible = false;
        aniVisible = UserEquipManager:isEquipGodly(userEquip);
        local gemInfo = PBHelper:getGemInfo(userEquip.gemInfos);
        if table.maxn(gemInfo) > 0 then
            gemVisible = true;
            for i = 1, 4 do
                local gemId = gemInfo[i];
                nodesVisible["mAnotherGemBG" .. i] = gemId ~= nil;
                local gemSprite = "mAnotherGem0" .. i;
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
        nodesVisible["mAnotherAni"] = aniVisible;
        nodesVisible["mAnotherGemNode"] = gemVisible;
        NodeHelper:setNodesVisible(container, nodesVisible);
        NodeHelper:setQualityBMFontLabels(container, { mLv2 = quality, mName2 = quality })
    end

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity, nil, true);

    NodeHelper:addEquipAni(container, "mAnotherAni", aniVisible, targetEquipId);
end

function EquipExtendPageBase:showExtendInfo(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    local texNode = container:getVarNode("mInheritAttributeTex");
    texNode:setScale(0.9)
    texNode:setVisible(false);
    local str = UserEquipManager:getInheritAttr(userEquip)
    --NodeHelper:addHtmlLable(texNode, str, GameConfig.Tag.HtmlLable, CCSizeMake(550, 80));
    

     ------------------------------------------------------
     NodeHelper:setStringForLabel(container, {mInheritAttributeTex = ""});
     local offsetY = 0
    self.container.mScrollView:getContainer():removeAllChildren()
    local label = CCHTMLLabel:createWithString(str,CCSize(self.container.mScrollView:getViewSize().width,96) , "Helvetica")
    label:setPosition(ccp(0,0));
    self.container.mScrollView:getContainer():addChild(label)
    self.container.mScrollView:getContainer():setContentSize(label:getContentSize())
    local sHieght = self.container.mScrollView:getViewSize().height
    local lHeight = label:getContentSize().height
    if lHeight <= sHieght then
        offsetY = (sHieght - lHeight)/2
    else
        offsetY = sHieght - lHeight
    end
    self.container.mScrollView:setContentOffset(ccp(0,offsetY))
    if lHeight <= sHieght then
        self.container.mScrollView:setTouchEnabled(false)
    else
        self.container.mScrollView:setTouchEnabled(true)
    end
end
 	
function EquipExtendPageBase:showConsumeInfo(container)
    local userEquip = UserEquipManager:getUserEquipById(thisEquipId);
    local coinCost = "0";
    lackInfo.coin = false;
    UserInfo.syncPlayerInfo();
    if not hasExtended and targetEquipId and targetEquipId > 0 then
        coinCost = UserEquipManager:getExtendCoinCost(thisEquipId, targetEquipId);
        lackInfo.coin = coinCost > UserInfo.playerInfo.coin;
    end

    local lb2Str = {
        mGold = common:getLanguageString("@CurrentOwnInfo",coinCost,UserInfo.playerInfo.coin)
    };

    NodeHelper:setStringForLabel(container, lb2Str);

    local colorMap = {
        mGold = common:getColorFromConfig(lackInfo.coin and "Lack" or "Own")
    };
    NodeHelper:setColor3BForLabel(container, colorMap);
end
----------------click event------------------------
function EquipExtendPageBase:onSelect(container)
    if hasExtended then return; end
    local selectedIds = targetEquipId and targetEquipId > 0 and { targetEquipId } or { };
    EquipSelectPage_multiSelect(selectedIds, 1, function(ids)
        for k, v in pairs(ids) do
            targetEquipId = k
            break
        end
        self:showTargetEquipInfo(container);
        self:showConsumeInfo(container);
    end , thisEquipId, EquipFilterType.Extend);
    PageManager.pushPage("EquipSelectPage");
end

function EquipExtendPageBase:onExtend(container)
    if targetEquipId and targetEquipId > 0 then
        if hasExtended then return; end
        --[[银币消耗判断，先屏蔽
		if lackInfo.coin then
			PageManager.notifyLackCoin();
			return;
		end
        ]]
        --
        EquipOprHelper:extendEquip(thisEquipId, targetEquipId);

    else
        MessageBoxPage:Msg_Box("@PlzSelectExtendTarget");
    end
end

function EquipExtendPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_EXTEND);
end	

function EquipExtendPageBase:onClose(container)
    PageManager.popPage(thisPageName);
end

-- »Ø°ü´¦Àí
function EquipExtendPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.EQUIP_EXTEND_S then
        self:refreshPage(container);
        hasExtended = true;
        PageManager.refreshPage("EquipLeadPage")
        PageManager.refreshPage("EquipMercenaryPage")
        common:popString(common:getLanguageString('@ExtendSuccess'), 'COLOR_GREEN')
        NodeHelper:setNodesVisible(container, { mExtendBtnNode = false, mDetermineBtnNode = true })
        return
    end
end

function EquipExtendPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function EquipExtendPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
EquipExtendPage = CommonPage.newSub(EquipExtendPageBase, thisPageName, option);


function EquipExtendPage_setEquipId(equipId)
    thisEquipId = equipId;
end
