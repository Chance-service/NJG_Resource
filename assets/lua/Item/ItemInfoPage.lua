
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local UserInfo = require("PlayerInfo.UserInfo");
--------------------------------------------------------------------------------
local gemExchangePage = "gemExchangePage";
registerScriptPage(gemExchangePage);

local thisPageName = "ItemInfoPage";
local thisUserItemId = 0;
local thisItemId = 0;
local IsFightTicketFlag = false
local thisItemType = Const_pb.NORMAL;
local PageType = {
    GemUpgrade = 1,
    SoulStoneUpgrade = 2,
}

local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
};

local option = {
    ccbiFile = "BackpackGoodsInfoPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onButtonMiddle = "onBtnMiddle",
        onButtonLeft = "onBtnLeft",
        onButtonRight = "onBtnRight"
    }
};

local ItemInfoPageBase = { };

local NodeHelper = require("NodeHelper");
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
local ItemOprHelper = require("Item.ItemOprHelper");

local ItemOpr_pb = require("ItemOpr_pb");

-- ²»Í¬µÀ¾ßÀàÐÍ¶ÔÓ¦°´Å¥µÄÎÄ±¾£¨¸öÊý¶ÔÓ¦°´Å¥¸öÊý£©
local type2BtnName = {
    [Const_pb.NORMAL] = { "@Cancel" },
    [Const_pb.FRAGMENT] = { "@MergeFragment" },
    [Const_pb.GEM] = { "@GemExchangeOldGemBtn" },
    [Const_pb.GIFT] = { "@OpenGiftBox" },
    [Const_pb.LUCK_TREASURE] = { "@OpenOne", "@OpenTen" },
    [Const_pb.GEM_PACKAGE] = { "@OpenOne", "@OpenTen" },
    [Const_pb.WORDS_EXCHANGE_NORMAL] = { "@Recycle", "@Exchange" },
    [Const_pb.WORDS_EXCHANGE_SPECIAL] = { "@Recycle", "@Exchange" },
    [Const_pb.BOSS_CHALLENGE_TIMES] = { "@OpenOne", "@OpenTen" },
    [Const_pb.ELITE_MAP_BOOK] = { "@OpenOne", "@OpenTen" },
    [Const_pb.ALLOANCE_VITALITY_PILL] = { "@Use" },
    -- [Const_pb.SOUL_STONE]               = {"@Compound"},
    [Const_pb.EXPEDITION_ARMORY] = { "@GoExpedition" },
    [Const_pb.SUIT_FRAGMENT] = { "@SuitExchangeBtn", "@MergeFragment" },
    [Const_pb.EQUIP_EXCHANGE] = { "@SuitExchange" },
    [Const_pb.FASTFIGHT_TIMES_BOOK] = { "@Use" },
    [Const_pb.GOODS_COMPOUND] = { "@Compound" },
    [Const_pb.TIME_LIMIT_PURCHASE] = { "@Use" },
    [Const_pb.ELEMENT_FRAGMENT] = { "@MergeFragment" },
    [Const_pb.RECYCLE_SEVEN_ITEM] = { "@Recycle" },
    [Const_pb.SUIT_DRAWING] = { "@Recycle" },
    [Const_pb.GEM_VOLUME] = { "@Cancel", "@Use" },
    [Const_pb.TREASURE_SELITEM] = { "@OpenGiftBox" },
    [Const_pb.MULTIELITE_CHALLENGE_TIMES] = { "@OpenOne", "@OpenTen" },
    [Const_pb.SOUL_STONE]= { "@Exchange" },
};

local lackInfo = { item = nil };
-----------------------------------------------
-- ItemInfoPageBase页面中的事件处理
----------------------------------------------
function ItemInfoPageBase:onEnter(container)
    self.container = container
    self.container.mScrollView = container:getVarScrollView("mContent");

    self:refreshPage(container);
    container:registerPacket(HP_pb.ITEM_USE_S);
    local relativeNode = container:getVarNode("S9_1")
    GameUtil:clickOtherClosePage(relativeNode, function()
        self:onClose(container)
    end , container)
end

function ItemInfoPageBase:onExit(container)
    container:removePacket(HP_pb.ITEM_USE_S);
end
----------------------------------------------------------------

function ItemInfoPageBase:refreshPage(container)
    self:showItemInfo(container);
    self:showButtons(container);
end

function ItemInfoPageBase:showItemInfo(container)
    local userItem = UserItemManager:getUserItemById(thisUserItemId);
    local itemInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, 1);
    local lb2Str = {
        -- mName 			= common:stringAutoReturn(itemInfo.name or "", 5),
        mNumber = "",
        -- mGoodsInfoTex 	= common:stringAutoReturn(itemInfo.describe or "", GameConfig.LineWidth.ItemDescribe)
        mGoodsInfoTex = ""
    };

    local mGoodsInfoTex = container:getVarNode("mGoodsInfoTex")
    mGoodsInfoTex:setScale(0.8)

    local htmlLabel = NodeHelper:setCCHTMLLabel(container, "mName", CCSize(GameConfig.LineWidth.ItemNameLength + 40, 96), itemInfo.name, true)

    htmlLabel:setScaleX(0.65)
    htmlLabel:setScaleY(0.65)
    -- NodeHelper:setCCHTMLLabel(container,"mGoodsInfoTex",CCSize(440,96),itemInfo.describe,true)
    local sprite2Img = {
        mPic = itemInfo.icon
    };
    local itemImg2Qulity = {
        mHand = itemInfo.quality
    };
    local scaleMap = { mPic = 1.0 };

    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, itemImg2Qulity);
    NodeHelper:setNodesVisible(container, { mStarNode = false, mNFT = false })

    lackInfo.item = userItem.count < GameConfig.Count.PieceToMerge;

    ------------------------------------------------------
    local offsetY = 0
    self.container.mScrollView:getContainer():removeAllChildren()
    local ActivityData = require("ActivityData")
    local desc = itemInfo.describe

    local desc = "<font color=\"#6f2f00\" face = \"Helvetica\" >" .. desc .. "</font>"

    if itemInfo.describe2 then
        if itemInfo.describe2 ~= "" then
            local strTb = { }
            local str = desc
            table.insert(strTb, str)
            table.insert(strTb, common:fillHtmlStr('ItemProduce', itemInfo.describe2))
            desc = table.concat(strTb, '<br/>')
        end
    end

    local label = CCHTMLLabel:createWithString(desc, CCSize(self.container.mScrollView:getViewSize().width, 96), "Helvetica")
    -- label:setAnchorPoint(ccp(0, 1))
    label:setPosition(ccp(0, 0));
    self.container.mScrollView:getContainer():addChild(label)
    self.container.mScrollView:getContainer():setContentSize(label:getContentSize())
    local sHieght = self.container.mScrollView:getViewSize().height
    local lHeight = label:getContentSize().height
    if lHeight <= sHieght then
        offsetY =(sHieght - lHeight) / 2
    else
        offsetY = sHieght - lHeight
    end
    self.container.mScrollView:setContentOffset(ccp(0, offsetY))
    if lHeight <= sHieght then
        self.container.mScrollView:setTouchEnabled(false)
    else
        self.container.mScrollView:setTouchEnabled(true)
    end
end


function ItemInfoPageBase:showButtons(container)

    --------------------------------------------------
    if IsFightTicketFlag then
        NodeHelper:setNodesVisible(container, { mFastFightingLastCount = false })
        --NodeHelper:setStringForLabel(container, { mFastFightingLastCount = common:getLanguageString("@TodaySurplusTimes") .. " " .. GameConfig.FastFightingTicketMaxCount - UserInfo.stateInfo.hourCardUseCountOneDay .. " / " .. GameConfig.FastFightingTicketMaxCount })
    else
        NodeHelper:setNodesVisible(container, { mFastFightingLastCount = false })
    end
    --------------------------------------------------

    local userItem = UserItemManager:getUserItemById(thisUserItemId);
    local itemInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, 1);
    thisItemId = userItem.itemId;
    thisItemType = ItemManager:getTypeById(thisItemId);

    local btnName = type2BtnName[thisItemType] or { "@Cancel" };
    if thisItemType == Const_pb.GOODS_COMPOUND and itemInfo.quality == 5 then
        btnName = type2BtnName[0]
    end
    if thisItemType == Const_pb.GEM_VOLUME and(itemInfo.itemId ~= 106001 and itemInfo.itemId ~= 106011 and itemInfo.itemId ~= 106102 and itemInfo.itemId ~= 106101 and itemInfo.itemId ~= 299992 and itemInfo.itemId ~= 106103) then
        btnName = type2BtnName[0]
    end
    if thisItemId == GameConfig.ChangeNameCardId then
        btnName = { "@Use" }
    end
    local btnCount = #btnName;

    local btnVisible = {
        mButtonMiddleNode = btnCount == 1,
        mButtonDoubleNode = btnCount == 2
    };
    local btnTex = { };
    if btnCount == 1 then
        btnTex["mButtonMiddle"] = common:getLanguageString(btnName[1]);
    elseif btnCount == 2 then
        btnTex["mButtonLeft"] = common:getLanguageString(btnName[1]);

        local item = UserItemManager:getUserItemByItemId(thisItemId)
        if item ~= nil and item.count < 10 and btnName[2] == "@OpenTen" then
            btnTex["mButtonRight"] = common:getLanguageString("@OpenAll");
        elseif item ~= nil and item.count < 10 and btnName[2] == "@UseTen" then
            btnTex["mButtonRight"] = common:getLanguageString("@UseAll");
        else
            btnTex["mButtonRight"] = common:getLanguageString(btnName[2]);
        end
    end

    NodeHelper:setStringForLabel(container, btnTex);
    NodeHelper:setNodesVisible(container, btnVisible);
end
----------------click event------------------------
function ItemInfoPageBase:onClose(container)
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName);
end

function ItemInfoPageBase:onBtnMiddle(container)
    if thisItemType == Const_pb.GEM then
        gemExchangePage_setItemId(thisItemId);
        PageManager.pushPage(gemExchangePage);
    elseif thisItemType == Const_pb.FRAGMENT or thisItemType == Const_pb.SUIT_FRAGMENT or thisItemType == Const_pb.ELEMENT_FRAGMENT then
        if lackInfo.item then
            MessageBoxPage:Msg_Box_Lan("@GodlyPieceNotEnough");
        else
            ItemOprHelper:useItem(thisItemId);
        end
    elseif thisItemType == Const_pb.GIFT then
        PageManager.showGiftPackage(thisItemId, function()
            ItemOprHelper:useItem(thisItemId);
        end );
    elseif thisItemType == Const_pb.BOSS_CHALLENGE_TIMES or thisItemType == Const_pb.ELITE_MAP_BOOK or thisItemType == Const_pb.ALLOANCE_VITALITY_PILL
        or thisItemType == Const_pb.FASTFIGHT_TIMES_BOOK or thisItemType == Const_pb.MULTIELITE_CHALLENGE_TIMES then
        ItemOprHelper:useItem(thisItemId);
    elseif thisItemType == Const_pb.EXPEDITION_ARMORY then
        self:jumpPage();
        -- elseif thisItemType == Const_pb.SOUL_STONE then
        -- ItemOprHelper:useItem(thisItemId)
        -- ItemManager:setNowSelectItem(thisItemId )
        -- PageManager.pushPage("SoulStoneUpgradePage");
    elseif thisItemType == Const_pb.GOODS_COMPOUND then
        local itemInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, thisItemId, 1);
        if itemInfo.quality < 5 then
            ItemManager:setNowSelectItem(thisItemId)
            PageManager.pushPage("RuneStonesUpgradePage")
        end
    elseif thisItemType == Const_pb.EQUIP_EXCHANGE then
        RegisterLuaPage("SuitExchangePage");
        SuitExchangePage_setItemId(thisItemId);
        PageManager.pushPage("SuitExchangePage");
    elseif thisItemType == Const_pb.CHANGE_NAME then
        -- ItemManager:setNowSelectItem(thisItemId )

        isUseItemChangeNmaeCard = true;
        PageManager.pushPage("ChangeNamePage");
    elseif thisItemType == Const_pb.CHANGE_ALLIANCE_NAME then
        -- ItemManager:setNowSelectItem(thisItemId )

        IsChangeGuildName = true;
        isUseItemChangeGuildCard = true
        PageManager.pushPage("GuildCreatePage");
    elseif thisItemType == Const_pb.TIME_LIMIT_PURCHASE then
        self:useItem();
        return
    elseif thisItemType == Const_pb.SUIT_DRAWING then
        local title = common:getLanguageString("@RecycleTitle");
        local allItem = ConfigManager.getItemCfg();
        local userItem = UserItemManager:getUserItemById(thisUserItemId);
        local cfg = allItem[userItem.itemId];
        local msg = common:getLanguageString("@RecycleMsg", cfg.price);
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                ItemOprHelper:recycleItem(thisItemId);
            end
        end );
    elseif thisItemType == Const_pb.RECYCLE_SEVEN_ITEM then
    -- TODO 調整為可設定販賣量
        local item = UserItemManager:getUserItemByItemId(thisItemId)
        local maxCount = item.count
        PageManager.showCountTimesWithIconPage(Const_pb.TOOL, thisItemId, thisItemId,
            function(count)
                return count * 1
            end ,
            function(isBuy, count, thisItemId)
                if isBuy then
                    local ItemOprHelper = require("Item.ItemOprHelper")
                    ItemOprHelper:sellItem(thisItemId, count)
                end
            end , true, maxCount, "@BatchSell", "@ERRORCODE_3002", nil, item.name)
    elseif thisItemType == Const_pb.ELITE then
        if thisItemId == GameConfig.ChangeNameCardId then
            PageManager.pushPage("ChangeNamePage")
        end
    elseif thisItemType == Const_pb.TREASURE_SELITEM then
        -- 开100级套装宝箱
        require("SuitExchangePage_100")
        SuitExchangePage_100_setItemId(thisItemId)
        PageManager.pushPage("SuitExchangePage_100")
    elseif thisItemType== Const_pb.SOUL_STONE then
        PageManager.pushPage("ShopGemFilterPopPage");
        ShopGemFilterPopPage_setItemInfo(thisItemId)
    end
    self:onClose();
end
	
function ItemInfoPageBase:onBtnLeft(container)
    if thisItemType == Const_pb.GEM_PACKAGE
        or thisItemType == Const_pb.LUCK_TREASURE
        or thisItemType == Const_pb.BOSS_CHALLENGE_TIMES
        or thisItemType == Const_pb.ELITE_MAP_BOOK
        or thisItemType == Const_pb.TIME_LIMIT_PURCHASE
        or thisItemType == Const_pb.MULTIELITE_CHALLENGE_TIMES 
    then
        self:useItem();
        return;
    elseif thisItemType == Const_pb.WORDS_EXCHANGE_NORMAL then
        self:sellItem();
    elseif thisItemType == Const_pb.SUIT_FRAGMENT then
        CCLuaLog("##### 交换水晶##########")
        if UserInfo.level >= GameConfig.SuitShopLevelLimit then
            -- RegisterLuaPage("EquipSuitExchangeCrystal");
            -- PageManager.pushPage("EquipSuitExchangeCrystal");
            PageManager.pushPage("SuitPatchExchangePopPage");
            SuitPatchExchangePopPage_setSellInfo(thisUserItemId);
        else
            MessageBoxPage:Msg_Box("@UseSuitNotEnough5");
            return
        end
    elseif thisItemType == Const_pb.WORDS_EXCHANGE_SPECIAL then
        local title = common:getLanguageString("@RecycleTitle");
        local cfg = ConfigManager.getRewardById(GameConfig.WordRecycleRewardId);
        local msg = common:getLanguageString("@RecycleMsg", ResManagerForLua:getResStr(cfg));
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                ItemOprHelper:recycleItem(thisItemId);
            end
        end );
    end
    self:onClose();
end

function ItemInfoPageBase:onBtnRight(container)
    if thisItemType == Const_pb.GEM_PACKAGE
        or thisItemType == Const_pb.LUCK_TREASURE
        or thisItemType == Const_pb.BOSS_CHALLENGE_TIMES
        or thisItemType == Const_pb.ELITE_MAP_BOOK
        or thisItemType == Const_pb.TIME_LIMIT_PURCHASE
        or thisItemType == Const_pb.MULTIELITE_CHALLENGE_TIMES 
    then
        ItemOprHelper:useTenItem(thisItemId);
        return;
    elseif thisItemType == Const_pb.WORDS_EXCHANGE_NORMAL then
        self:jumpPage();
    elseif thisItemType == Const_pb.WORDS_EXCHANGE_SPECIAL then
        RegisterLuaPage("WordExchangeRewardPage");
        WordExchangeRewardPage_setItemId(thisItemId);

        PageManager.pushPage("WordExchangeRewardPage");
    elseif thisItemType == Const_pb.SUIT_FRAGMENT then
        self:useItem();
    elseif thisItemType == Const_pb.GEM_VOLUME then

        if thisItemId == 106001 then
            -- 宝石交换卷
            require("ShopControlPage")
            ShopTypeContainer_SetSubPageIndex(3)
            PageManager.changePage("ShopControlPage");
        elseif thisItemId == 106102 or thisItemId == 106101 then
            -- 生徒交换卷
            GashaponPage_setPart(101)
            -- 活动id页签
            GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
            GashaponPage_setTitleStr("@NiuDanTitle")
            PageManager.changePage("GashaponPage")
            resetMenu("mGuildPageBtn", true)
        elseif thisItemId == 106103 then
            ActivityInfo.jumpToActivityById(Const_pb.NEW_TREASURE_RAIDER139)
        elseif thisItemId == 299992 then
            ActivityInfo.jumpToActivityById(136 , 2)
        elseif thisItemId == 106011 then
            -- 生徒兑换券跳到兑换所
            ActivityInfo.jumpToActivityById(136 , 1)

--            require("LimitActivityPage")
--            LimitActivityPage_setPart(86)
--            LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
--            LimitActivityPage_setTitleStr("@FixedTimeActTitle")
--            PageManager.changePage("LimitActivityPage")

--            local KingPowerScoreExchangePage = require("KingPowerScoreExchangePage")
--            KingPowerScoreExchangePage:onloadCcbiFile(1)
--            PageManager.pushPage("KingPowerScoreExchangePage")
        end
    end
    self:onClose();
end

function ItemInfoPageBase:useItem()
    ItemOprHelper:useItem(thisItemId);
end

function ItemInfoPageBase:jumpPage()
    local itemCfg = ItemManager:getItemCfgById(thisItemId);
    if itemCfg.jumpPage ~= "0" then
        PageManager.showActivity(tonumber(itemCfg.jumpPage));
    end
end

function ItemInfoPageBase:sellItem()
    local title = common:getLanguageString("@SellItemTitle");
    local cfg = {
        {
            type = Const_pb.PLAYER_ATTR * 10000,
            itemId = Const_pb.COIN,
            count = ItemManager:getPriceById(thisItemId)
        }
    };
    local msg = common:getLanguageString("@SellItemMsg", ResManagerForLua:getResStr(cfg));
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            ItemOprHelper:recycleItem(thisItemId);
        end
    end );
end

-- 回包处理
function ItemInfoPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode();
    local msgBuff = container:getRecPacketBuffer();
    if opcode == opcodes.ITEM_USE_S then
        if UserItemManager:getCountByItemId(thisItemId) <= 0 then
            self:onClose();
        else
            self:showButtons(container)
        end

        if thisItemType == Const_pb.TIME_LIMIT_PURCHASE then
            local msg = ItemOpr_pb.HPItemUseRet();
            msg:ParseFromString(msgBuff);
            if msg ~= nil then
            else
            end
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
ItemInfoPage = CommonPage.newSub(ItemInfoPageBase, thisPageName, option);

function ItemInfoPage_setItemId(itemId)
    thisUserItemId = itemId
    IsFightTicketFlag = false
    local userItem = UserItemManager:getUserItemById(thisUserItemId)
    for k, v in pairs(GameConfig.BackpackFightTicket) do
        if userItem.itemId == v then
            IsFightTicketFlag = true
            break
        end
    end
end