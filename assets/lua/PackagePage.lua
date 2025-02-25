----------------------------------------------------------------------------------
--[[

--]]
----------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local ceil = math.ceil;
--------------------------------------------------------------------------------
local filterPage = "EquipFilterPage";
local batchSellPage = "BatchSellEquipPage";
local ItemManager = require("Item.ItemManager");
local NodeHelper = require("NodeHelper")
local MainScenePageInfo = require "MainScenePage"
local GuideManager = require("Guide.GuideManager")
require("GashaponPage")
local actId = nil --- 活动跳转

registerScriptPage(filterPage);
registerScriptPage(batchSellPage);

local thisPageName = "PackagePage"
local offsetY = nil
local myContain = nil

local opcodes = {
    --STATE_INFO_SYNC_S = HP_pb.STATE_INFO_SYNC_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
};

local option = {
    ccbiFile = "BackpackPage.ccbi",
    -- ccbiFile = "BackpackPage_WIN32.ccbi",
    -- ccbiFile_WIN32 = "BackpackPage_WIN32.ccbi",
    -- ccbiFile_WIN32 = "BackpackPage.ccbi",
    handlerMap =
    {
        onEquipment = "showEquipment",
        onGoods = "showGoods",
        onSuit = "showSuits",
        onPrivateEquipment = "onPrivateEquipment",
        onBatchSell = "batchSell",
        onEquipmentScreening = "filterEquip",
        onExpansionBackpack = "expandPackage",
        onGoMelt = "onGoMelt",
        onShopJump = "onShopJump",
        onNiuDanJump = "onNiuDanJump",
        onEquipDetailJump = "onEquipDetailJump",
        onReturn = "onReturn",
        onReset = "onReset",
        onShowGem = "onShowGem",
        onShowScroll = "onShowScroll",
    },
    opcode = opcodes
};

local PackagePageBase = { }

local EquipOprHelper = require("Equip.EquipOprHelper");
local UserItemManager = require("Item.UserItemManager");
local PBHelper = require("PBHelper");
local ItemManager = require("Item.ItemManager");
local HeroOrderItemManager = require("Item.HeroOrderItemManager")
local Const_pb = require("Const_pb")
local offsetContentSize = nil
local ITEM_COUNT_PER_LINE = 1;
local mRebuildLock = true -- 控制rebuild只刷新1次
local mRefreshCout = 0 -- 控制rebuild只刷新1次
local mLastItemCount = 0 -- 记录上次刷新的时候物品数量，如果当前物品数量和上次不同则rebuild否则只是刷新物品数量

local PageType = {
    EQUIPMENT = 1,
    GOODS = 2,
    SUITS = 3,
    FATES = 4,
    -- 宝石类型 = 2
    GOODSGEM = 2,
    -- 麒麟套装进化书类型= 36
    GOODSBOOK = 36,
    -- 显示所有
    GOODSALLINDEX = 1,
    -- 显示宝石
    GOODSGEMINDEX = 2,
    -- 显示麒麟套装进化书
    GOODSBOOKSINDEX = 3,
    -- 当前选择的页签
    SELECTINDEX = 0,
};

local _pageType = nil
local mFromRoleId = nil
local mInFatePage = false
local PageInfo = {
    pageType = PageType.EQUIPMENT,
    filter =
    {
        mainClass = "All",
        subClass = 0
    },
    fatesDatas = { },
    fateCount = 0,
    equipCount = 0,
    itemCount = 0,
    itemSuitCount = 0,
    equipIds = { },
    itemIds = { },
    -- 装备碎片
    itemSuitIds = { },
    gemIds = { },
    -- 所有宝石类型
    bookIds = { },-- 所有卷轴类型
};

local positionMenuNode = {
    firstPosition = nil,
    gemPosition = nil,
    booksPosition = nil,
}-- 装备里面按钮的初始位置保存

local editPosY = nil


local function sortEquip(id_1, id_2)
    local isAsc = true;

    if id_2 == nil then
        return isAsc;
    end
    if id_1 == nil then
        return not isAsc;
    end

    local userEquip_1 = UserEquipManager:getUserEquipById(id_1);
    local userEquip_2 = UserEquipManager:getUserEquipById(id_2);

    local isGodly_1 = UserEquipManager:isEquipGodly(userEquip_1);
    local isGodly_2 = UserEquipManager:isEquipGodly(userEquip_2);

    if isGodly_1 ~= isGodly_2 then
        if isGodly_1 then return isAsc; end
        return not isAsc;
    end

    local quality_1 = EquipManager:getQualityById(userEquip_1.equipId);
    local quality_2 = EquipManager:getQualityById(userEquip_2.equipId);

    if quality_1 ~= quality_2 then
        if quality_1 > quality_2 then
            return isAsc;
        else
            return not isAsc;
        end
    end

    local part_1 = EquipManager:getPartById(userEquip_1.equipId);
    local part_2 = EquipManager:getPartById(userEquip_2.equipId);

    if part_1 ~= part_2 then
        if GameConfig.PartOrder[part_1] > GameConfig.PartOrder[part_2] then
            return isAsc;
        end
        return not isAsc;
    end

    -- 強化等級
    if userEquip_1.strength and userEquip_2.strength and userEquip_1.strength ~= userEquip_2.strength then
        if userEquip_1.strength > userEquip_2.strength then
            return isAsc
        else
            return not isAsc;
        end
    end

    -- 裝備等級
    if userEquip_1.level and userEquip_2.level and userEquip_1.level ~= userEquip_2.level then
        if userEquip_1.level > userEquip_2.level then
            return isAsc
        else
            return not isAsc;
        end
    end

    if userEquip_1.score ~= userEquip_2.score then
        if userEquip_1.score > userEquip_2.score then
            return isAsc;
        else
            return not isAsc;
        end
    end
    -- 装备id
    if userEquip_1.equipId > userEquip_2.equipId then
        return isAsc
    end

    -- 服务器的装备id排序
    -- if id_1 > id_2 then
    -- 	return isAsc;
    -- end

    return not isAsc;
end


local function sortFates(fateData_1, fateData_2)
    local conf_1 = fateData_1:getConf()
    local conf_2 = fateData_2:getConf()
    if conf_1.quality ~= conf_2.quality then
        return conf_1.quality > conf_2.quality
    elseif conf_1.starLevel ~= conf_2.starLevel then
        return conf_1.starLevel > conf_2.starLevel
    elseif fateData_1.level ~= fateData_2.level then
        return fateData_1.level > fateData_2.level
    else
        return fateData_1.exp > fateData_2.exp
    end
end

--------------------------------------------------------------
local PackageItem = {
    ccbiFile = { "BackpackItem.ccbi", "BackpackItem.ccbi", "BackpackItem.ccbi", "BackpackItem.ccbi" },
};	

local function EquipmentItemOnFunction(eventName, container)
    if eventName == "onHand" then
        local index = container:getTag();
        local userEquipId = PageInfo.equipIds[index];
        PageManager.showEquipInfo(userEquipId);
    end
end

local function GoodsItemOnFunction(eventName, container)
    if eventName == "onHand" then
        local index = container:getTag();
        local itemId = PageInfo.itemIds[index];
        local userItem = UserItemManager:getUserItemByItemId(itemId);
        PageManager.showItemInfo(userItem.id);
    end
end

-- 高速扫荡卷引导
function PackageItem_onHand()
    local index = 1
    local itemId = PageInfo.itemIds[index];
    local userItem = UserItemManager:getUserItemByItemId(itemId);
    PageManager.showItemInfo(userItem.id);
end

function PackageItem:onHand(content, id, index)
    local contentId = id;
    local baseIndex =(contentId - 1) * ITEM_COUNT_PER_LINE;
    index = index + baseIndex;

    if PageInfo.pageType == PageType.EQUIPMENT then
        local userEquipId = PageInfo.equipIds[index];
        PageManager.showEquipInfo(userEquipId);
    elseif PageInfo.pageType == PageType.GOODS then
        offsetY = PackagePageBase.container.scrollview:getContentOffset();
        local size = PackagePageBase.container.scrollview:getContentSize();
        offsetContentSize = { width = size.width, height = size.height }
        -- local itemId = PageInfo.itemIds[index];
        local itemId = nil;

        if PageType.SELECTINDEX == PageType.GOODSGEMINDEX then
            itemId = PageInfo.gemIds[index];
        elseif PageType.SELECTINDEX == PageType.GOODSBOOKSINDEX then
            itemId = PageInfo.bookIds[index];
        else
            itemId = PageInfo.itemIds[index];
        end


        local userItem = UserItemManager:getUserItemByItemId(itemId);
        local itemType = ItemManager:getTypeById(userItem.itemId);
        local cfg = ItemManager:getItemCfgById(userItem.itemId);
        local UserInfo = require("PlayerInfo.UserInfo");
        -- 如果道具是英雄令的话
        if itemType == 22 then
            HeroOrderItemManager:showHeroOrderItemInfo(itemId);
        elseif cfg.isNewStone == 2 then
            PageManager.showGemInfo(userItem.id);
        elseif itemType == Const_pb.AVATAR_GIFT then
            local LeaderAvatarManager = require("LeaderAvatarManager");
            LeaderAvatarManager:setPreviewItem(userItem);
            PageManager.pushPage("LeaderAvatarShowPage");
        else
            PageManager.showItemInfo(userItem.id);
        end
    elseif PageInfo.pageType == PageType.FATES then
        local fateData = PageInfo.fatesDatas[index];
        require("FateDetailInfoPage");
        FateDetailInfoPage_setFate( { isOthers = false, fateData = fateData });
        PageManager.pushPage("FateDetailInfoPage");
    else
        local itemId = PageInfo.itemSuitIds[index];
        local userItem = UserItemManager:getUserItemByItemId(itemId);
        local itemType = ItemManager:getTypeById(userItem.itemId);
        local cfg = ItemManager:getItemCfgById(userItem.itemId);
        local UserInfo = require("PlayerInfo.UserInfo");
        -- 如果道具是英雄令的话
        if itemType == 22 then
            HeroOrderItemManager:showHeroOrderItemInfo(itemId);
        elseif cfg.isNewStone == 2 then
            PageManager.showGemInfo(userItem.id);
        else
            PageManager.showItemInfo(userItem.id);
        end
    end
end


-- function PackageItem:onUnLoad(content)
-- 	local container = content:getCCBFileNode()
-- 	-- if container then
-- 	-- 	local nodeContainer
--  --        for i = 1,5 do
--  --        	nodeContainer = container:getVarNode("mPosition"..i)
--  --        	nodeContainer:removeChildByTag(10086, true)
--  --        end
-- 	-- end
-- end

function PackageItem:onPreLoad(content)

end

function PackageItem:onUnLoad(content)

end

function PackageItem:onHand1(content)
    PackageItem:onHand(content, self.id, 1);
end

function PackageItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local contentId = self.id
    local baseIndex =(contentId - 1) * ITEM_COUNT_PER_LINE;

    for i = 1, ITEM_COUNT_PER_LINE do
        local index = baseIndex + i;
        local nodeContainer = container:getVarNode("mPosition" .. i)
        nodeContainer:setVisible(true)
        if PageInfo.pageType == PageType.EQUIPMENT then
            if PageInfo.equipIds[index] then
                PackageItem.newEquipmentItem(container, i, index);
            else
                nodeContainer:setVisible(false)
            end
        elseif PageInfo.pageType == PageType.GOODS then
            if index <= PageInfo.itemCount then
                PackageItem.newGoodsItem(container, i, index);
            else
                nodeContainer:setVisible(false)
            end
        elseif PageInfo.pageType == PageType.FATES then
            if PageInfo.fatesDatas[index] then
                PackageItem.newPrivateEquipmentItem(container, i, index);
            else
                nodeContainer:setVisible(false)
            end
        else
            if index <= PageInfo.itemSuitCount then
                PackageItem.newGoodsItem(container, i, index);
            else
                nodeContainer:setVisible(false)
            end
        end

    end
    -- 高速战斗引导
    if contentId == 1 and PageInfo.pageType == PageType.GOODS then
        if GuideManager.IsNeedShowPage then
            GuideManager.PageContainerRef["BackPackItemPage"] = container
            GuideManager.IsNeedShowPage = false
            PageManager.pushPage("NewbieGuideForcedPage")
            PageManager.popPage("NewGuideEmptyPage")
        end
    end
    --調整排版
    if editPosY then
        container:getVarNode("mPosition1"):setPositionY(editPosY)
    else
        container:getVarNode("mPosition1"):setPositionY(container:getVarNode("mPosition1"):getPositionY() - 12)
        editPosY = container:getVarNode("mPosition1"):getPositionY()
    end
end

function PackageItem.newEquipmentItem(container, index, dataIndex)
    local NodeHelper = require("NodeHelper");

    if PageInfo.equipIds[dataIndex] == nil or PageInfo.equipIds[dataIndex] == 0 then
        NodeHelper:setNodesVisible(container, { ["mPosition" .. index] = false })
        return
    end


    local userEquip = UserEquipManager:getUserEquipById(PageInfo.equipIds[dataIndex]);
    local equipId = userEquip.equipId;
    local displayLevel, strengthLevel
    local level = EquipManager:getLevelById(equipId) --裝備等級
    local strength = userEquip.strength + 1; --強化等級(初始是0, 顯示要為1, 故需+1)
    if tonumber(level) > 100 then
        displayLevel = common:getLanguageString("@NewLevelStr", math.floor(level / 100), tonumber(level) -100)       
    else
        displayLevel = common:getLanguageString("@LevelStr", level)       
    end

    if tonumber(strength) > 100 then      
        strengthLevel = common:getLanguageString("@NewLevelStr", math.floor(strength / 100), tonumber(strength) -100)
    else       
        strengthLevel = common:getLanguageString("@LevelStr", strength)
    end

    NodeHelper:setStringForLabel(container, { ["mEquipLv"] = strengthLevel }); --NodeHelper:setStringForLabel(container, { ["mEquipLv"] = displayLevel });

    local lb2Str = {
        ["mName" .. index] = common:getLanguageString(EquipManager:getNameById(equipId)),
        --["mLvNUm" .. index] = userEquip.strength == 0 and "" or "+" .. userEquip.strength
    }
    local nodesVisible = { }
    local sprite2Img = { ["mPic" .. index] = EquipManager:getIconById(equipId) }
    local scaleMap = { }
    local quality = EquipManager:getQualityById(equipId)
    local aniVisible = UserEquipManager:isGodly(userEquip.id)

    nodesVisible["mAni" .. index] = aniVisible
    nodesVisible["mNumber" .. index] = false
    nodesVisible["mNFT"] = EquipManager:getEquipCfgById(userEquip.equipId).isNFT == 1

    NodeHelper:setStringForLabel(container, lb2Str)

    scaleMap["mPic" .. index] = GameConfig.EquipmentIconScale
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);

    NodeHelper:setQualityFrames(container, { ["mHand" .. index] = EquipManager:getQualityById(equipId) })
    NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. index] = EquipManager:getQualityById(equipId) })
    NodeHelper:setNodesVisible(container, nodesVisible)

    local quality = EquipManager:getQualityById(equipId)
    local textColor = ConfigManager.getQualityColor()[quality].textColor
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == quality) })
    end
    NodeHelper:setColorForLabel(container, { ["mName" .. index] = textColor })

    NodeHelper:addEquipAni(container, "mAni" .. index, aniVisible, nil, userEquip)

    NodeHelper:setNodesVisible(container, { ["mEquipLv"] = true });
    NodeHelper:setNodesVisible(container, { ["mShader"] = true });
    NodeHelper:setNodesVisible(container, { ["mName" .. index] = false });
    NodeHelper:setNodesVisible(container, { ["mNumber" .. index .. "_1"] = false });
end


function PackageItem.newPrivateEquipmentItem(container, nodeIndex, dataIndex)
    local fateData = PageInfo.fatesDatas[dataIndex]
    if not fateData then
        return
    end
    local conf = fateData:getConf()
    local str = conf.name
    NodeHelper:setBlurryString(container, "mName" .. nodeIndex, str, GameConfig.BlurryLineWidth, 5)
    NodeHelper:setStringForLabel(container, { ["mNumber" .. nodeIndex] = "Lv." .. fateData.level });
    NodeHelper:setSpriteImage(container, { ["mPic" .. nodeIndex] = conf.icon });
    NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. nodeIndex] = conf.quality });
    NodeHelper:setQualityFrames(container, { ["mHand" .. nodeIndex] = conf.quality });
    NodeHelper:setNodesVisible(container, { ["mAni" .. nodeIndex] = false, ["mNumber" .. nodeIndex] = true })

    local textColor = ConfigManager.getQualityColor()[conf.quality].textColor
    NodeHelper:setColorForLabel(container, { ["mName" .. nodeIndex] = textColor })

    local visibleMap = { }

    NodeHelper:setNodesVisible(container, visibleMap)

    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == conf.quality) })
    end

    NodeHelper:setNodesVisible(container, { ["mEquipLv"] = true });
    NodeHelper:setNodesVisible(container, { ["mShader"] = true });
    NodeHelper:setNodesVisible(container, { ["mName" .. nodeIndex] = false });
    NodeHelper:setNodesVisible(container, { ["mNumber" .. nodeIndex .. "_1"] = false });
end


function PackageItem.newGoodsItem(container, nodeIndex, dataIndex)
    local Const_pb = require("Const_pb")
    local NodeHelper = require("NodeHelper")
    local index = nodeIndex

    local itemId = 0
    if PageInfo.pageType == PageType.SUITS then
        itemId = PageInfo.itemSuitIds[dataIndex]
    else
        if PageType.SELECTINDEX == PageType.GOODSGEMINDEX then
            itemId = PageInfo.gemIds[dataIndex]
        elseif PageType.SELECTINDEX == PageType.GOODSBOOKSINDEX then
            itemId = PageInfo.bookIds[dataIndex]
        else
            itemId = PageInfo.itemIds[dataIndex]
        end
    end

    if itemId == nil or itemId == 0 then
        NodeHelper:setNodesVisible(container, { ["mPosition" .. index] = false })
        return
    end

    local userItem = UserItemManager:getUserItemByItemId(itemId)
    local resInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, userItem.itemId, userItem.count)
    local lb2Str = { }

    lb2Str["mNumber" .. nodeIndex .. "_1"] = "x" .. userItem.count; -- lb2Str["mNumber" .. nodeIndex] = userItem.count; 換成右下角的美術labeltext 

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, { ["mPic" .. nodeIndex] = resInfo.icon }, { ["mPic" .. nodeIndex] = resInfo.iconScale })
    NodeHelper:setQualityFrames(container, { ["mHand" .. nodeIndex] = resInfo.quality })
    NodeHelper:setImgBgQualityFrames(container, { ["mFrameShade" .. nodeIndex] = resInfo.quality })

    local htmlNode = container:getVarLabelBMFont("mName" .. nodeIndex)

    local str = ItemManager:getShowNameById(itemId)
    NodeHelper:setBlurryString(container, "mName" .. nodeIndex, str, GameConfig.BlurryLineWidth, 5)

    --local textColor = ConfigManager.getQualityColor()[resInfo.quality].textColor
    --NodeHelper:setColorForLabel(container, { ["mName" .. nodeIndex] = textColor })
    NodeHelper:setNodesVisible(container, { ["mAni" .. nodeIndex] = false, ["mNumber" .. index] = false, ["mNFT"] = false });

    local quality = resInfo.quality
    if quality > 10 then
        quality = quality - 7
    end
    for i = 1, 6 do
        NodeHelper:setNodesVisible(container, { ["mStar" .. i] = false }); --NodeHelper:setNodesVisible(container, { ["mStar" .. i] = (i == quality) })
    end

    NodeHelper:setNodesVisible(container, { ["mEquipLv"] = false });
    NodeHelper:setNodesVisible(container, { ["mShader"] = false });
    NodeHelper:setNodesVisible(container, { ["mName" .. nodeIndex] = false });
    NodeHelper:setNodesVisible(container, { ["mNumber" .. nodeIndex .. "_1"] = true });
end

----------------------------------------------------------------------------------

-----------------------------------------------
-- PackagePageBase页面中的事件处理
----------------------------------------------
function PackagePageBase:onEnter(container)
    PackagePage_reset()
    PageInfo.pageType = _pageType or PageInfo.pageType
    self.container = container
    PackagePageBase.container = container
    myContain = container
    local NodeHelper = require("NodeHelper");
    PackagePageBase.container = container
    container:registerMessage(MSG_SEVERINFO_UPDATE);
    container:registerMessage(MSG_MAINFRAME_POPPAGE);
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    container.scrollview = container:getVarScrollView("mContent")

    --NodeHelper:autoAdjustResizeScrollview(container.scrollview)
    --NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    --NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mBGS9"))
    local UserInfo = require("PlayerInfo.UserInfo");
    PageInfo.itemSuitIds = UserItemManager:getUserItemSuitFragIds()
    -- UserItemManager:getUserItemIds();
    NodeHelper:setNodesVisible(container, { mSuitBtnNode = false--[[#PageInfo.itemSuitIds ~= 0 or UserInfo.roleInfo.level >= GameConfig.SuitEquipLevelLimit]] })

    self:registerPacket(container)


    -- 徽章系统开启等级
    local HelpFightDataManager = require("PVP.HelpFightDataManager")
    NodeHelper:setNodesVisible(container, { mPrivateEquipmentBtnNode = false--[[UserInfo.roleInfo.level >= GameConfig.BadgeLevelLimit and HelpFightDataManager:isOpen()]] })
--    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
--    else
--        NodeHelper:setNodesVisible(container, { mPrivateEquipmentBtnNode = false })
--    end

    self:refreshPage(container)
    self:rebuildAllItem(container)
    -- 防止第一次进入不刷新，要rebuild之后在赋值
    mLastItemCount = PageInfo.itemCount
    local PageJumpMange = require("PageJumpMange")
    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            PackagePageBase[PageJumpMange._CurJumpCfgInfo._SecondFunc](self, container);
        end
        if PageJumpMange._CurJumpCfgInfo._ThirdFunc == "" then
            PageJumpMange._IsPageJump = false
        end
    end
    GuideManager.PageContainerRef["BackPackPage"] = container
    -- container:getVarNode("mHelpNode"):setVisible(false)
end

--- 添加背包装备碎片的显示隐藏机制
function IsOpenSuitPackge(container)
    NodeHelper:setNodesVisible(container, { suit_Node = false })
    local suitPackagePageFlag = CCUserDefault:sharedUserDefault():getBoolForKey("suitPackagePageFlag")
    if not suitPackagePageFlag then
        local suitFragIds = UserItemManager:getUserItemSuitFragIds()
        if #suitFragIds ~= 0 then
            CCUserDefault:sharedUserDefault():setBoolForKey("suitPackagePageFlag", true)
            CCUserDefault:sharedUserDefault():flush()
            NodeHelper:setNodesVisible(container, { suit_Node = true })
        end
    else
        NodeHelper:setNodesVisible(container, { suit_Node = true })
    end
end

function PackagePageBase:onExit(container)
    _pageType = nil
    mFromRoleId = nil
    offsetY = nil
    PackagePageBase.container = nil
    local NodeHelper = require("NodeHelper");
    container:removeMessage(MSG_SEVERINFO_UPDATE);
    container:removeMessage(MSG_MAINFRAME_POPPAGE);
    container:removeMessage(MSG_MAINFRAME_REFRESH);
    self:clearAllItem(container)
    PackagePage_reset()
    mRebuildLock = true
    mLastItemCount = 0
    actId = nil
    GameUtil:purgeCachedData()
    self:removePacket(container)
end
----------------------------------------------------------------

function PackagePageBase:updateAllData(container)
    local flag = true
    PageInfo.itemIds = UserItemManager:getUserItemNotSuitFragIds()
    -- UserItemManager:getUserItemIds();
    -- table.sort(PageInfo.itemIds);
    PageInfo.gemIds = { }
    PageInfo.bookIds = { }
    local itemType = nil
    -- local sortId = ItemManager:getSortIdById(itemId)
    for i, v in ipairs(PageInfo.itemIds) do
        itemType = ItemManager:getSortTypeById(v)
        if itemType == PageType.GOODSGEM then
            table.insert(PageInfo.gemIds, v)
        elseif itemType == PageType.GOODSBOOK then
            table.insert(PageInfo.bookIds, v)
        end
    end
    if positionMenuNode.firstPosition == nil then
        positionMenuNode.firstPosition = self.container:getVarNode("mResetNode"):getPositionX()
        positionMenuNode.gemPosition = self.container:getVarNode("mShowGemNode"):getPositionX()
        positionMenuNode.booksPosition = self.container:getVarNode("mShowScrollNode"):getPositionX()
    end
    -- table.sort(PageInfo.itemIds)
    -- table.sort(PageInfo.gemIds)
    -- table.sort(PageInfo.bookIds)
    self:sortAllId(PageInfo.itemIds)
    self:sortAllId(PageInfo.gemIds)
    self:sortAllId(PageInfo.bookIds)
    if PageType.SELECTINDEX == PageType.GOODSGEMINDEX then
        PageInfo.itemCount = #PageInfo.gemIds;
    elseif PageType.SELECTINDEX == PageType.GOODSBOOKSINDEX then
        PageInfo.itemCount = #PageInfo.bookIds;
    else
        PageInfo.itemCount = #PageInfo.itemIds;
    end
    if #PageInfo.gemIds > 0 and #PageInfo.bookIds > 0 then
        NodeHelper:setNodesVisible(self.container, { mResetNode = true })
        NodeHelper:setNodesVisible(self.container, { mShowGemNode = true })
        NodeHelper:setNodesVisible(self.container, { mShowScrollNode = true })

        self.container:getVarNode("mResetNode"):setPositionX(positionMenuNode.firstPosition)
        self.container:getVarNode("mShowGemNode"):setPositionX(positionMenuNode.gemPosition)
        self.container:getVarNode("mShowScrollNode"):setPositionX(positionMenuNode.booksPosition)
    elseif #PageInfo.gemIds > 0 then
        NodeHelper:setNodesVisible(self.container, { mResetNode = true })
        NodeHelper:setNodesVisible(self.container, { mShowGemNode = true })
        NodeHelper:setNodesVisible(self.container, { mShowScrollNode = false })
        self.container:getVarNode("mResetNode"):setPositionX(-80)
        self.container:getVarNode("mShowGemNode"):setPositionX(80)
        -- self.container:getVarNode("mShowScrollNode"):setPositionX()
    elseif #PageInfo.bookIds > 0 then
        NodeHelper:setNodesVisible(self.container, { mResetNode = true })
        NodeHelper:setNodesVisible(self.container, { mShowGemNode = false })
        NodeHelper:setNodesVisible(self.container, { mShowScrollNode = true })
        self.container:getVarNode("mResetNode"):setPositionX(-80)
        -- self.container:getVarNode("mShowGemNode"):setPositionX()
        self.container:getVarNode("mShowScrollNode"):setPositionX(80)
    else
        flag = false
    end
    return flag
end

-- 按照sortId排序
function PackagePageBase:sortAllId(mTable)
    if #mTable <= 1 then
        return
        -- 小于2个不用排序
    end
    table.sort(mTable, function(a, b)
        return ItemManager:getSortIdById(a) < ItemManager:getSortIdById(b)
    end )
end


function PackagePageBase:refreshPage(container)
    local NodeHelper = require("NodeHelper");
    local backpackSizeNodeVisible = false
    local equipOprVisible = false
    local mIsShowShopBtn = false
    local itemNodeFlag = false
    local mPrivateFlag = false
    if PageInfo.pageType == PageType.EQUIPMENT then

        PageInfo.equipIds = UserEquipManager:getEquipIdsByClass(PageInfo.filter.mainClass, PageInfo.filter.subClass);
        PageInfo.equipCount = #PageInfo.equipIds;
        table.sort(PageInfo.equipIds, sortEquip);
        self:showCapacityInfo(container);
        self:showTypeInfo(container);
        equipOprVisible = true;
        backpackSizeNodeVisible = true
    elseif PageInfo.pageType == PageType.GOODS then
        itemNodeFlag = self:updateAllData()
        -- PageInfo.itemIds = UserItemManager:getUserItemNotSuitFragIds()
        -- table.sort(PageInfo.itemIds);
        -- PageInfo.itemCount = #PageInfo.itemIds;
        NodeHelper:setStringForLabel(container, { mEquipmentTitle = common:getLanguageString("@AllGoods") });
    elseif PageInfo.pageType == PageType.FATES then
        local FateDataManager = require("FateDataManager")
        local temp = FateDataManager:getNotWearFateList()
        PageInfo.fatesDatas = { }
        for k, v in pairs(temp) do
            PageInfo.fatesDatas[#PageInfo.fatesDatas + 1] = v
        end
        PageInfo.fateCount = #PageInfo.fatesDatas
        table.sort(PageInfo.fatesDatas, sortFates);
        self:showCapacityInfo(container);
        backpackSizeNodeVisible = true
        -- equipOprVisible = true;
        -- NodeHelper:setNodesVisible(container, { mPrivateEquipmentBtnNode = UserInfo.roleInfo.level >= GameConfig.BadgeLevelLimit })
        -- capacityVisible = true
        --        if UserInfo.roleInfo.level >= GameConfig.BadgeLevelLimit then
        --            -- 判断开启等级
        --            mPrivateFlag = true
        --        end
    else
        mIsShowShopBtn = true
        PageInfo.itemSuitIds = UserItemManager:getUserItemSuitFragIds()
        table.sort(PageInfo.itemSuitIds);
        PageInfo.itemSuitCount = #PageInfo.itemSuitIds;
    end
    NodeHelper:setNodesVisible(container, {
        mEquipmentBtnNode = backpackSizeNodeVisible,
        mEquipmentBtnNode02 = false,--equipOprVisible,
        mEquipmentBtnNode03 = false,--mIsShowShopBtn,
        mItemNode = false,--itemNodeFlag,
        -- mPrivateEquipmentBtnNode = mPrivateFlag
    } );
    self:setTabSelected(container);
    self:setSelectedGoodsMenu(container)
end

function PackagePageBase:setTabSelected(container)
    local NodeHelper = require("NodeHelper");
    local isEquipSelected = PageInfo.pageType == PageType.EQUIPMENT;
    NodeHelper:setMenuItemSelected(container, {
        mAgencyBtn = PageInfo.pageType == PageType.EQUIPMENT,
        mTabGoods = PageInfo.pageType == PageType.GOODS,
        mSuitGoods = PageInfo.pageType == PageType.SUITS,
        mPrivateEquipmentBtn = PageInfo.pageType == PageType.FATES,
    } )
    NodeHelper:setMenuItemsEnabled(container, {
        mAgencyBtn = PageInfo.pageType ~= PageType.EQUIPMENT,
        mTabGoods = PageInfo.pageType ~= PageType.GOODS,
        mSuitGoods = PageInfo.pageType ~= PageType.SUITS,
        mPrivateEquipmentBtn = PageInfo.pageType ~= PageType.FATES,
    } )
    NodeHelper:setBMFontFile(container, {
        mTabEquipment = PageInfo.pageType == PageType.EQUIPMENT and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
        mDailyName = PageInfo.pageType == PageType.GOODS and "Lang/Font-HT-TabPage.fnt" or "Lang/Font-HT-TabPage2.fnt",
    } )
end;

function PackagePageBase:showCapacityInfo(container)
    local UserInfo = require("PlayerInfo.UserInfo");
    local NodeHelper = require("NodeHelper");
    UserInfo.syncStateInfo();
    local isMax = false
    if PageInfo.pageType == PageType.EQUIPMENT then
        local bagSize = UserInfo.stateInfo.currentEquipBagSize;
        local capacityStr = PageInfo.equipCount .. "/" .. bagSize;
        NodeHelper:setStringForLabel(container, { mBackpackCapacity = capacityStr });
    elseif PageInfo.pageType == PageType.FATES then
        local bagSize = GameConfig.BuyDressBagCost.DefaultDressBagSize
        if UserInfo.stateInfo:HasField("currentBadgeBagSize") then
            bagSize = UserInfo.stateInfo.currentBadgeBagSize
        end
        local capacityStr = PageInfo.fateCount .. "/" .. bagSize;
        NodeHelper:setStringForLabel(container, { mBackpackCapacity = capacityStr });
    end

    --    local bagSize = UserInfo.stateInfo.currentEquipBagSize;
    --    local capacityStr = PageInfo.equipCount .. "/" .. bagSize;
    --    NodeHelper:setStringForLabel(container, { mBackpackCapacity = capacityStr });

end

function PackagePageBase:showTypeInfo(container)
    local NodeHelper = require("NodeHelper");
    local typeStr = "";
    local mainClass = PageInfo.filter.mainClass;
    local subClass = PageInfo.filter.subClass;
    if mainClass == "All" then
        typeStr = common:getLanguageString("@AllEquip");
    elseif mainClass == "Part" then
        typeStr = common:getLanguageString("@EquipPart_" .. subClass);
    elseif mainClass == "Quality" then
        typeStr = common:getLanguageString("@QualityName_" .. subClass)
        .. common:getLanguageString("@Equipment");
    elseif mainClass == "Godly" then
        typeStr = common:getLanguageString("@GodlyEquip");
    end
    NodeHelper:setStringForLabel(container, { mEquipmentTitle = typeStr });
end

----------------scrollview-------------------------
function PackagePageBase:rebuildAllItem(container)
    IsOpenSuitPackge(container)
    if mLastItemCount ~= 0 and PageInfo.pageType == PageType.GOODS and PageInfo.itemCount == mLastItemCount then
        -- 预防同一时间刷新多次
        if mRebuildLock then
            mRebuildLock = false
            self:clearAllItem(container);
            self:buildItem(container);
            -- 延迟1s
            container:runAction(
            CCSequence:createWithTwoActions(
            CCDelayTime:create(0.5),
            CCCallFunc:create( function()
                mRebuildLock = true;
                -- 判断是否有未被刷新的情况存在，无论未被刷新多少次都只重新刷新一次
                if mRefreshCout > 0 then
                    mRefreshCout = 0
                    self:clearAllItem(container);
                    self:buildItem(container);
                end
            end )
            )
            );
        else
            -- 记录下未被刷新的次数
            mRefreshCout = mRefreshCout + 1;
        end
    else
        if PageInfo.pageType == PageType.GOODS then
            mLastItemCount = PageInfo.itemCount
        end
        -- 预防同一时间刷新多次
        if mRebuildLock then
            mRebuildLock = false
            self:clearAllItem(container);
            self:buildItem(container);

            -- 延迟1s
            container:runAction(
            CCSequence:createWithTwoActions(
            CCDelayTime:create(0.5),
            CCCallFunc:create( function()
                mRebuildLock = true;
                -- 判断是否有未被刷新的情况存在，无论未被刷新多少次都只重新刷新一次
                if mRefreshCout > 0 then
                    mRefreshCout = 0
                    self:clearAllItem(container)
                    self:buildItem(container)
                end
            end )
            )
            );
        else
            -- 记录下未被刷新的次数
            mRefreshCout = mRefreshCout + 1;
        end
    end
end

function PackagePageBase:clearAllItem(container)
    container.scrollview:removeAllCell()
end

function PackagePageBase:buildItem(container)
    local scrollview = container.scrollview
    local totalSize = 0;
    if PageInfo.pageType == PageType.EQUIPMENT then
        totalSize = PageInfo.equipCount;
    elseif PageInfo.pageType == PageType.GOODS then
        totalSize = PageInfo.itemCount;
        mLastItemCount = totalSize;
    elseif PageInfo.pageType == PageType.FATES then
        totalSize = PageInfo.fateCount
    else
        totalSize = PageInfo.itemSuitCount
    end
    NodeHelper:setNodesVisible(container, { mNoItemTxt = totalSize == 0 })
    if totalSize == 0 then
        return
    end
    totalSize = ceil(totalSize / ITEM_COUNT_PER_LINE);
    -- NodeHelper:buildScrollView(container, size, PackageItem.ccbiFile[PageInfo.pageType], PackageItem.onFunction);
    local cell = nil
    local ccbiFile = PackageItem.ccbiFile[PageInfo.pageType]

    for i = totalSize, 1, -1 do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local panel = common:new( { id = totalSize - i + 1 }, PackageItem)
        cell:registerFunctionHandler(panel)
        cell:setScale(1.4)
        cell:setContentSize(CCSize(cell:getContentSize().width * 1.15, cell:getContentSize().height * 1.037))
        scrollview:addCell(cell)
        -- local pos = ccp(0,cell:getContentSize().height*(i-1))
        -- cell:setPosition(pos)	
    end
    scrollview:orderCCBFileCells()
    if offsetY then
        local contentSize = scrollview:getContentSize()
        -- offsetContentSize
        if contentSize.height > scrollview:getViewSize().height then
            local offset = ccp(offsetY.x, 0)
            if contentSize.height < offsetContentSize.height then
                offset.y = offsetY.y - contentSize.height + offsetContentSize.height
            else
                local offsety = contentSize.height - offsetContentSize.height
                offset.y = offsetY.y - offsety
            end
            scrollview:setContentOffset(offset)
        end
        -- scrollview:setContentOffset(offsetY)
    end

end


-------------------------------------
function PackagePageBase:setSelectedGoodsMenu(container)
    local NodeHelper = require("NodeHelper");
    NodeHelper:setMenuItemSelected(container, {
        mReset = PageType.SELECTINDEX == PageType.GOODSALLINDEX,
        mShowGem = PageType.SELECTINDEX == PageType.GOODSGEMINDEX,
        mShowScroll = PageType.SELECTINDEX == PageType.GOODSBOOKSINDEX,

    } )
    NodeHelper:setNodesVisible(container, {
        mResetSprite = PageType.SELECTINDEX == PageType.GOODSALLINDEX,
        mShowGemSprite = PageType.SELECTINDEX == PageType.GOODSGEMINDEX,
        mShowScrollSprite = PageType.SELECTINDEX == PageType.GOODSBOOKSINDEX,
    } )

end

function PackagePageBase:onReset(container)
    if PageType.SELECTINDEX ~= PageType.GOODSALLINDEX then
        offsetY = nil
        PageType.SELECTINDEX = PageType.GOODSALLINDEX
        PageInfo.itemCount = #PageInfo.itemIds;
        self:clearAllItem(container);
        self:buildItem(container);
    end
    self:setSelectedGoodsMenu(container)
end

function PackagePageBase:onShowGem(container)
    if PageType.SELECTINDEX ~= PageType.GOODSGEMINDEX then
        offsetY = nil
        PageType.SELECTINDEX = PageType.GOODSGEMINDEX
        PageInfo.itemCount = #PageInfo.gemIds;
        self:clearAllItem(container);
        self:buildItem(container);
    end
    self:setSelectedGoodsMenu(container)
end

function PackagePageBase:onShowScroll(container)
    if PageType.SELECTINDEX ~= PageType.GOODSBOOKSINDEX then
        offsetY = nil
        PageType.SELECTINDEX = PageType.GOODSBOOKSINDEX
        PageInfo.itemCount = #PageInfo.bookIds;
        self:clearAllItem(container);
        self:buildItem(container);
    end
    self:setSelectedGoodsMenu(container)
end


----------------click event------------------------
function PackagePageBase:showEquipment(container)
    self:changePageType(container, PageType.EQUIPMENT)
end

-- 私装背包
function PackagePageBase:onPrivateEquipment(container)
    self:changePageType(container, PageType.FATES)
end

function PackagePageBase_showGoods()
    PageType.SELECTINDEX = PageType.GOODSALLINDEX
    PackagePageBase:changePageType(myContain, PageType.GOODS)
end

function PackagePageBase:showGoods(container)
    PageType.SELECTINDEX = PageType.GOODSALLINDEX
    self:changePageType(container, PageType.GOODS)
end

function PackagePageBase:showSuits(container)
    self:changePageType(container, PageType.SUITS);
end

function PackagePageBase:changePageType(container, targetType)
    offsetY = nil
    if targetType ~= PageInfo.pageType then
        PageInfo.pageType = targetType;
        self:refreshPage(container);
        -- self:rebuildAllItem(container);
        self:clearAllItem(container);
        self:buildItem(container);
    else
        self:setTabSelected(container);
    end
end

function PackagePageBase:batchSell(container)
    PageManager.pushPage(batchSellPage);
end

function PackagePageBase:filterEquip(container)
    PageManager.pushPage(filterPage);
end	
function PackagePageBase:onGoMelt(container)

    -- PageManager.pushPage("EquipIntegrationPage")
    PageManager.changePage("EquipIntegrationPage")
    -- PageManager.pushPage("MeltPage");
end	

function PackagePageBase:onShopJump(container)
    PageManager.changePage("ShopControlPage");
end	
function PackagePageBase:onNiuDanJump(container)
    GashaponPage_setPart(90)
    -- 活动id页签
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")
    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)

end	
function PackagePageBase:onEquipDetailJump(container)
    PageManager.pushPage("SuitDisplayPage")
end	

function PackagePageBase:expandPackage(container)
    local UserInfo = require("PlayerInfo.UserInfo");
    if PageInfo.pageType == PageType.EQUIPMENT then
        local title = common:getLanguageString("@BuyPackageTitle");
        local timesCanBuy = UserInfo.stateInfo.leftEquipBagExtendTimes;
        if timesCanBuy <= 0 then
            MessageBoxPage:Msg_Box_Lan("@PackageCannotExpand");
            return;
        end
        local count = GameConfig.BuyPackage.Count;
        local cost = GameConfig.BuyPackage.Cost[11 - timesCanBuy] or 300;

        local msg = common:getLanguageString("@BuyPackageMsg", count, cost, timesCanBuy);

        PageManager.showConfirm(title, msg, function(isSure)
            if isSure and UserInfo.isGoldEnough(cost, "ExpansionBackpack_enter_rechargePage") then
                EquipOprHelper:expandPackage();
            end
        end );
    elseif UserInfo.stateInfo:HasField("leftBadgeBagExtendTimes") then
        -- TODO扩展背包
        local timesCanBuy = UserInfo.stateInfo.leftBadgeBagExtendTimes;
        if timesCanBuy <= 0 then
            MessageBoxPage:Msg_Box_Lan("@PackageCannotExpand");
            return;
        end
        local info = GameConfig.BuyDressBagCost[timesCanBuy]
        local title = common:getLanguageString("@BuyBadgeBagTitle");
        local msg = common:getLanguageString("@BuyPackageMsg", info.num, info.cost, timesCanBuy);
        -- local msg = common:getLanguageString("@DressTips_6", info.num, info.cost, timesCanBuy);
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure and UserInfo.isGoldEnough(info.cost, "ExpansionBackpack_enter_rechargePage") then
                -- TODO发送扩展私装背包消息
                common:sendEmptyPacket(HP_pb.BADGE_BAG_EXTEND_C, false);
            end
        end )
    end


end

-- 回包处理
function PackagePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

	if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end

-- 继承此类的活动如果同时开，消息监听不能同时存在,通过tag来区分
function PackagePageBase:onReceiveMessage(container)
    local HP_pb = require("HP_pb");
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;
        local opcodes = {
            HP_pb.EQUIP_INFO_SYNC_S,
            HP_pb.ITEM_INFO_SYNC_S,
            HP_pb.EQUIP_SELL_S
        };

        if common:table_hasValue(opcodes, opcode) then
            if opcode == HP_pb.ITEM_INFO_SYNC_S then
                PageInfo.itemSuitIds = UserItemManager:getUserItemSuitFragIds()
                NodeHelper:setNodesVisible(container, { mSuitBtnNode = false }) --#PageInfo.itemSuitIds ~= 0 or UserInfo.roleInfo.level >= GameConfig.SuitEquipLevelLimit
            end

            self:refreshPage(container);
            self:rebuildAllItem(container);
        elseif opcode == HP_pb.STATE_INFO_SYNC_S then
            self:showCapacityInfo(container);
        end
    elseif typeId == MSG_MAINFRAME_POPPAGE then
        local pageName = MsgMainFramePopPage:getTrueType(message).pageName;
        if pageName == filterPage then
            self:refreshPage(container);
            self:rebuildAllItem(container);
        end
    elseif typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
        if pageName == thisPageName then
            self:refreshPage(container);
            if extraParam ~= "refreshBagSize" then
                self:rebuildAllItem(container);
            end
        end
    end
end

function PackagePageBase:getActivityType(activityId)

    local activityType = 0

    for k, v in ipairs(ActivityInfo.NovicePageIds) do
        -- 新手
        if v == activityId then
            return 1
        end
    end

    for k, v in ipairs(ActivityInfo.NiuDanPageIds) do
        -- 扭蛋
        if v == activityId then
            return 2
        end
    end

    for k, v in ipairs(ActivityInfo.LimitPageIds) do
        -- 限定
        if v == activityId then
            return 3
        end
    end

end

function PackagePageBase:onReturn(container)

    if mFromRoleId ~= nil then
        EquipPageBase_selectMercenary(mFromRoleId)
        PageManager.changePage("EquipmentPage");
        resetMenu("mEquipmentPageBtn", true)
        PageManager.refreshPage("EquipmentPage", "FirstShowFatePage")
        if mInFatePage then
            PageManager.pushPage("FateFindPage")
        end
        return
    end

    --- 从活动跳转 返回活动
    if actId then
        local index = actId
        -- 检查index是属于哪个活动里面的

        if PackagePageBase:getActivityType(index) == 1 then
            -- 新手

        elseif PackagePageBase:getActivityType(index) == 2 then
            -- 扭蛋

            CCLuaLog("扭蛋事件")
            require("GashaponPage")
            -- require("LimitActivityPage")
            local ActionLog_pb = require("ActionLog_pb")
            local message = ActionLog_pb.HPActionRecord()
            if message ~= nil then
                message.activityId = index;
                message.actionType = Const_pb.RED_POINT_INTO;
                local pb_data = message:SerializeToString();
                PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false);
            end

            GashaponPage_setPart(index)
            GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
            GashaponPage_setTitleStr("@NiuDanTitle")
            PageManager.changePage("GashaponPage")
            resetMenu("mGuildPageBtn", true)
        elseif PackagePageBase:getActivityType(index) == 3 then
            -- 限定
            require("LimitActivityPage")
            --MainScenePageInfo.onActionRecord(container, index, Const_pb.MAIN_BANNER_INTO)
            LimitActivityPage_setPart(index)
            -- PageManager.changePage("LimitActivityPage");
            PageManager.changePage("LimitActivityPage");
        end
    else
        MainFrame_onMainPageBtn()
    end
end
function PackagePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function PackagePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
------------------------------------------页面开关

--------------------------------------------------
local CommonPage = require("CommonPage");

PackagePage = CommonPage.newSub(PackagePageBase, thisPageName, option);
function PackagePage_setFilter(mainClass, subClass)
    PageInfo.filter = {
        mainClass = mainClass or "All",
        subClass = subClass or 0
    };
end

function PackagePage_reset()
    PageInfo = {
        pageType = PageType.EQUIPMENT,
        filter =
        {
            mainClass = "All",
            subClass = 0
        },
        equipCount = 0,
        fateCount = 0,
        itemCount = 0,
        itemSuitCount = 0,
        equipIds = { },
        itemSuitIds = { },
        gemIds = { },
        fatesDatas = { },
        -- 所有宝石类型
        bookIds = { },-- 所有卷轴类型
    };
end

function PackagePage_showItems()
    PageInfo.pageType = PageType.GOODS;
    PageManager.changePage(thisPageName);
end
-- 首充礼包界面直接跳转到该装备
function PackagePage_showEquipItems()
    PageInfo.pageType = PageType.EQUIPMENT;
    PageManager.changePage(thisPageName);
end

--
function PackagePage_showFateItems(roleId, inFatePage)
    if roleId == GameConfig.FatePackageJumpFlag then
        -- 特殊处理
        PackagePageBase:changePageType(PackagePageBase.container, PageType.FATES)
        return
    end
    PageInfo.pageType = PageType.FATES
    mFromRoleId = roleId
    mInFatePage = inFatePage
    _pageType = PageType.FATES
    MainFrame_onBackpackPageBtn()
end
function PackagePage_refreshPage()
    if PackagePageBase.container then
        PackagePageBase:refreshPage(PackagePageBase.container);
        PackagePageBase:clearAllItem(PackagePageBase.container);
        PackagePageBase:buildItem(PackagePageBase.container);
    end
end
function PackagePage_setAct(_actId)
    actId = _actId
end

