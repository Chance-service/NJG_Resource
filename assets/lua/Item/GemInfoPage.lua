----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
--------------------------------------------------------------------------------
local gemNewCompoundPage = "gemNewCompoundPage"
registerScriptPage(gemNewCompoundPage)

local thisPageName = "GemInfoPage"
local thisUserItemId = 0
local thisItemId = 0
local thisItemType = Const_pb.NORMAL
local PageType = {
    GemUpgrade = 1,
    SoulStoneUpgrade = 2,
}

local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
}

local option = {
    ccbiFile = "BackpackGemInfoPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onButtonMiddle = "onBtnMiddle",
        onButtonLeft = "onButtonLeft",
        onButtonRight = "onButtonRight",
    }
}

local GemInfoPageBase = { }

local NodeHelper = require("NodeHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")
local ItemOprHelper = require("Item.ItemOprHelper")

local ItemOpr_pb = require("ItemOpr_pb")
local GemItemsNewCfgData = {}

-----------------------------------------------
-- GemInfoPageBase页面中的事件处理
----------------------------------------------
function GemInfoPageBase:onEnter(container)
    GemItemsNewCfgData = ItemManager:getNewGemMarketItems(UserInfo.playerInfo.vipLevel)
    self:refreshPage(container)

    local relativeNode = container:getVarNode("S9_1")
    GameUtil:clickOtherClosePage(relativeNode, function ()
        self:onClose(container)
    end, container)
end

function GemInfoPageBase:onExit(container)

end
----------------------------------------------------------------

function GemInfoPageBase:refreshPage(container)
    self:showItemInfo(container)
    self:showButtons(container)
end

function GemInfoPageBase:showItemInfo(container)
    local userItem = UserItemManager:getUserItemById(thisUserItemId)
    local itemInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, 1)

    local goodsInfoStr = itemInfo.describe
    if itemInfo.describe == nil then
        goodsInfoStr = ""
    else
        local node, height, maxWidth, labelHeight, line, returnStr = NodeHelper:horizontalSpacingAndVerticalSpacing_LLLL(itemInfo.describe, "Barlow-SemiBold.ttf", 19, 0, 0, container:getVarScale9Sprite("S9_3"):getContentSize().width - 20, "0 0 0")
        goodsInfoStr = returnStr
    end
    local lb2Str = {
        mGoodsName = itemInfo.name,
        mGoodsAttribute = ItemManager:getNewGemAttrString(userItem.itemId),
        mNumber = "",
        -- mGoodsInfoTex 	= common:stringAutoReturn(itemInfo.describe or "", GameConfig.LineWidth.ItemDescribe)
        mGoodsInfoTex = goodsInfoStr
        -- mGoodsInfoTex 	= common:stringAutoReturn(itemInfo.describe or "")
    }
    -- NodeHelper:setCCHTMLLabel(container,"mName",CCSize(GameConfig.LineWidth.ItemNameLength,96),itemInfo.name,true)
    -- NodeHelper:setCCHTMLLabel(container,"mGoodsInfoTex",CCSize(480,96),itemInfo.describe,true)
    local sprite2Img = {
        mPic = itemInfo.icon
    }
    local itemImg2Qulity = {
        mHand = itemInfo.quality
    }
    local scaleMap = { mPic = 1.0 }

    NodeHelper:setNodesVisible(container, { mName = false })
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, itemImg2Qulity)
end


function GemInfoPageBase:showButtons(container)
    local userItem = UserItemManager:getUserItemById(thisUserItemId);
    thisItemId = userItem.itemId;
    thisItemType = ItemManager:getTypeById(thisItemId);

    local btnName = "@BackpackGemCompoundTitle";

    local btnVisible = {
        mButtonMiddleNode = true,
        mButtonDoubleNode = false
    };
    local btnTex = { };
    --添加宝石快速购买
    if thisItemType == 2 then
        btnVisible.mButtonMiddleNode = false
        btnVisible.mButtonDoubleNode = true
        btnTex["mButtonLeft"]  = common:getLanguageString("@FastBuyBtn")
        btnTex["mButtonRight"]  = common:getLanguageString(btnName)
    end

    btnTex["mButtonMiddle"] = common:getLanguageString(btnName);

    NodeHelper:setStringForLabel(container, btnTex);
    NodeHelper:setNodesVisible(container, btnVisible);
end
----------------click event------------------------
function GemInfoPageBase:onClose(container)
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName);
end

function GemInfoPageBase:onBtnMiddle(container)
    local cfg = ItemManager:getItemCfgById(thisItemId);
    local UserInfo = require("PlayerInfo.UserInfo");
    if cfg.levelUpItem == 0 then
        MessageBoxPage:Msg_Box_Lan("@isMaxLevel");
        -- elseif cfg.levelLimit > UserInfo.roleInfo.level then
        -- 	local str = common:getLanguageString("@gemCompoundLimit");
        -- 	str = common:formatString(str,ItemManager:getNameById(cfg.levelUpItem), tostring(cfg.levelLimit))
        -- 	MessageBoxPage:Msg_Box(str);
    else
        gemNewCompoundPage_setItemId(thisItemId);
        PageManager.pushPage(gemNewCompoundPage);
        self:onClose();
    end
end

function GemInfoPageBase:onButtonRight(container)
    local cfg = ItemManager:getItemCfgById(thisItemId);
    local UserInfo = require("PlayerInfo.UserInfo");
    if cfg.levelUpItem == 0 then
        MessageBoxPage:Msg_Box_Lan("@isMaxLevel");
        -- elseif cfg.levelLimit > UserInfo.roleInfo.level then
        -- 	local str = common:getLanguageString("@gemCompoundLimit");
        -- 	str = common:formatString(str,ItemManager:getNameById(cfg.levelUpItem), tostring(cfg.levelLimit))
        -- 	MessageBoxPage:Msg_Box(str);
    else
        gemNewCompoundPage_setItemId(thisItemId);
        PageManager.pushPage(gemNewCompoundPage);
        self:onClose();
    end
end

function GemInfoPageBase:onBtnMiddle(container)
    local cfg = ItemManager:getItemCfgById(thisItemId);
    local UserInfo = require("PlayerInfo.UserInfo");
    if cfg.levelUpItem == 0 then
        MessageBoxPage:Msg_Box_Lan("@isMaxLevel");
        -- elseif cfg.levelLimit > UserInfo.roleInfo.level then
        -- 	local str = common:getLanguageString("@gemCompoundLimit");
        -- 	str = common:formatString(str,ItemManager:getNameById(cfg.levelUpItem), tostring(cfg.levelLimit))
        -- 	MessageBoxPage:Msg_Box(str);
    else
        gemNewCompoundPage_setItemId(thisItemId);
        PageManager.pushPage(gemNewCompoundPage);
        self:onClose();
    end
end

function GemInfoPageBase:onButtonLeft(container)
    local index = 1
    local itemIndex = 1
    if thisItemType == 2 then
        index = tonumber(string.sub(tostring(thisItemId),2,3))
        itemIndex = tonumber(string.sub(tostring(thisItemId),-2))
    end
    if index < 1 or index > 15 or index == nil  then
        index = 1
    end
    if itemIndex < 1  or itemIndex == nil then
        itemIndex = 1
    elseif itemIndex > 9 then
        itemIndex = 9
    end
    local itemsCfg = GemItemsNewCfgData[index]
    if itemsCfg == nil then return; end
    PageManager.pushPage("ShopGemFilterPopPage");
    ShopGemFilterPopPage_setItemInfo(itemsCfg);
    ShopGemFilterPopPage_setItemIndex(itemIndex)
    self:onClose();
end

function GemInfoPageBase:jumpPage()
    local itemCfg = ItemManager:getItemCfgById(thisItemId);
    if itemCfg.jumpPage ~= "0" then
        PageManager.showActivity(tonumber(itemCfg.jumpPage));
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
GemInfoPage = CommonPage.newSub(GemInfoPageBase, thisPageName, option);

function GemInfoPage_setItemId(itemId)
    thisUserItemId = itemId;
end