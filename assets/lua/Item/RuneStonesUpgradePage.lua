
----------------------------------------------------------------------------------
local Const_pb = require("Const_pb");
local HP_pb = require("HP_pb");
local ItemOpr_pb = require("ItemOpr_pb");
local UserInfo = require("PlayerInfo.UserInfo");
--------------------------------------------------------------------------------
local thisPageName = "RuneStonesUpgradePage";
local thisItemId = 0;
local useCount = 0;
local canUpgradeTen = false;

local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
};

local option = {
    ccbiFile = "SpecializationRuneAdvance.ccbi",
    handlerMap =
    {
        onCompounds = "onUpgrade",
        onClose = "onClose",
        onAllCompounds = "onUpgradeAdd"
    },
};
for i = 1, #GameConfig.RuneStonesIds do
    option.handlerMap["onHand" .. i] = "onBookHand"
end

local RuneStonesUpgradeBase = { };
local NodeHelper = require("NodeHelper");
local ItemOprHelper = require("Item.ItemOprHelper");
local ItemManager = require("Item.ItemManager");
local UserItemManager = require("Item.UserItemManager");
-----------------------------------------------
-- SoulStoneUpgradeBase页面中的事件处理
----------------------------------------------
function RuneStonesUpgradeBase:onEnter(container)
    self:registerPacket(container);
    self:refreshPage(container);
end

function RuneStonesUpgradeBase:onExit(container)
    self:removePacket(container);
end
----------------------------------------------------------------
function RuneStonesUpgradeBase:refreshPage(container)
    thisItemId = ItemManager:getNowSelectItem()
    self:showRuneStoneInfo(container);
    self:showUpgradeInfo(container);
    self:refreshButton(container)
end

function RuneStonesUpgradeBase:showRuneStoneInfo(container)
    local lb2Str = { }
    local sprite2Img = { }
    local scaleMap = { }
    local handMap = { }
    local lb2StrColor = { }
    local colorMap = { }
    for i = 1, #GameConfig.RuneStonesIds do
        local name = ItemManager:getNameById(GameConfig.RuneStonesIds[i]);
        local stoneNum = UserItemManager:getCountByItemId(GameConfig.RuneStonesIds[i]);
        lb2Str["mNumber" .. i] = stoneNum
        lb2Str["mName" .. i] = name
        -- NodeHelper:setCCHTMLLabel(container,"mName" .. i,CCSize(GameConfig.LineWidth.ItemNameLength,96),name,true)
        -- lb2StrColor["mName" .. i] = ItemManager:getQualityById(GameConfig.RuneStonesIds[i])
        colorMap["mName" .. i] = ConfigManager.getQualityColor()[ItemManager:getQualityById(GameConfig.RuneStonesIds[i])].textColor
        sprite2Img["mPic" .. i] = ItemManager:getIconById(GameConfig.RuneStonesIds[i])
        scaleMap["mPic" .. i] = 1.0
        handMap["mHand" .. i] = ItemManager:getQualityById(GameConfig.RuneStonesIds[i])

        NodeHelper:setNodeVisible(container:getVarNode("mTexBG" .. i), thisItemId == GameConfig.RuneStonesIds[i])

        local selectSprite = container:getVarSprite("mTexBG" .. i)
        if selectSprite then
            selectSprite:setScale(1)
            local action1 = CCScaleTo:create(0.3, 1.05)
            local action2 = CCScaleTo:create(0.3, 1)
            if thisItemId == GameConfig.RuneStonesIds[i] then
                selectSprite:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(action1, action2)))
            else
                selectSprite:stopAllActions()
            end
        end
    end

    NodeHelper:setColorForLabel(container, colorMap)
    NodeHelper:setStringForLabel(container, lb2Str);
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap);
    NodeHelper:setQualityFrames(container, handMap);
    NodeHelper:setQualityBMFontLabels(container, lb2StrColor)
end

function RuneStonesUpgradeBase:showUpgradeInfo(container)
    -- 是否是最后一本书
    local isLargeLevel =(thisItemId == GameConfig.RuneStonesIds[#GameConfig.RuneStonesIds])
    NodeHelper:setNodesVisible(container, { mCanUpgradeBookNode = (not isLargeLevel) })
    NodeHelper:setNodesVisible(container, { mCompoundUnAdvance = (isLargeLevel) })
    NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mSpcializationCompoundBtn"),(not isLargeLevel))
    NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mCompondUpgradeUpBtn"),(not isLargeLevel))

    NodeHelper:setNodeIsGray(container, { mCompoundBtnText = isLargeLevel, mCompoundsUpgrade = isLargeLevel })


    local userItem = UserItemManager:getUserItemByItemId(thisItemId)
    local levelUpCost = ItemManager:getLevelUpCost(thisItemId);
    local costMax = ItemManager:getLevelUpCostMax(thisItemId);
    costMax = math.max(1, costMax);
    local costTb = { };
    local lineNumber = 1
    for _, costCfg in ipairs(levelUpCost) do
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(costCfg.type, costCfg.id, costCfg.count);
        if resInfo ~= nil then
            local ownNum = 0;
            if resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.COIN then
                UserInfo.syncPlayerInfo();
                ownNum = UserInfo.playerInfo.coin;
            elseif resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.GOLD then
                UserInfo.syncPlayerInfo();
                ownNum = UserInfo.playerInfo.gold;
            else
                ownNum = UserItemManager:getCountByItemId(costCfg.id);
            end
            if lineNumber == 1 then
                NodeHelper:setStringForLabel(container, {
                    mCompoundDiamondsNum = resInfo.name .. " x " .. common:getLanguageString("@CurrentOwnInfo",costCfg.count,ownNum)
                } )
            elseif lineNumber == 2 then
                NodeHelper:setStringForLabel(container, {
                    mCompoundBook = resInfo.name .. " x " .. common:getLanguageString("@CurrentOwnInfo",costCfg.count,ownNum)
                } )
                NodeHelper:setQualityBMFontLabels(container, { mCompoundBook = ItemManager:getQualityById(thisItemId) })
            end
            lineNumber = lineNumber + 1
        end
    end

    NodeHelper:setStringForLabel(container, {
        mTitle = common:getLanguageString("@RuneStoneUpgradeTitle"),
    } )
    NodeHelper:setNodesVisible(container, { mGold = (not isLargeLevel) })
    if thisItemId % 10 == 9 then
        local htmlNode = container:getVarLabelBMFont("mCompoundUnAdvanceTips")
        local str = common:getLanguageString("@CompoundUnAdvance")
        if htmlNode then
            local htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(500, 96), str)
            htmlLabel:setScale(htmlNode:getScale())
            htmlNode:setVisible(false)
        end
    end

end
	
function RuneStonesUpgradeBase:calculateCount(ownNum, costNum)
    local flag = false
    local count = 0
    if costNum ~= 0 then
        local temp = ownNum % costNum
        count =(ownNum - temp) / costNum
        if count >= 10 then
            flag = true
        else
            flag = false
        end
    end
    return count, flag
end

function RuneStonesUpgradeBase:judgeCount(container)
    local levelUpCost = ItemManager:getLevelUpCost(thisItemId);
    local countByCoin = 0
    local canUpgradeTenByCoin = false
    local countByGold = 0
    local canUpgradeTenByGold = false
    local countByItem = 0
    local canUpgradeTenByItem = false

    for _, costCfg in ipairs(levelUpCost) do
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(costCfg.type, costCfg.id, costCfg.count);
        if resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.COIN then
            UserInfo.syncPlayerInfo();
            countByCoin, canUpgradeTenByCoin = self:calculateCount(UserInfo.playerInfo.coin, costCfg.count)
            useCount = countByCoin
            canUpgradeTen = canUpgradeTenByCoin
        elseif resInfo.mainType == Const_pb.PLAYER_ATTR and costCfg.id == Const_pb.GOLD then
            UserInfo.syncPlayerInfo();
            countByGold, canUpgradeTenByGold = self:calculateCount(UserInfo.playerInfo.gold, costCfg.count)
            useCount = countByGold
            canUpgradeTen = canUpgradeTenByGold
        else
            countByItem, canUpgradeTenByItem = self:calculateCount(UserItemManager:getCountByItemId(costCfg.id), costCfg.count)
        end
    end
    useCount = math.min(useCount, countByItem)
    if canUpgradeTen and canUpgradeTenByItem then
        canUpgradeTen = true
    else
        canUpgradeTen = false
    end
end

function RuneStonesUpgradeBase:refreshButton(container)
    self:judgeCount(container)
    if canUpgradeTen then
        NodeHelper:setStringForLabel(container, {
            mCompoundsUpgrade = common:getLanguageString("@TenSoulStoneUpgradeBtnLabel"),
        } )
    else
        NodeHelper:setStringForLabel(container, {
            mCompoundsUpgrade = common:getLanguageString("@AllSoulStoneUpgradeBtnLabel"),
        } )
    end
end


----------------click event------------------------
function RuneStonesUpgradeBase:onBookHand(container, eventName)
    local index = tonumber(eventName:sub(-1))
    ItemManager:setNowSelectItem(GameConfig.RuneStonesIds[index])
    self:refreshPage(container)
end

function RuneStonesUpgradeBase:onUpgrade(container)
    ItemOprHelper:useItem(thisItemId, 1);
end

function RuneStonesUpgradeBase:onUpgradeAdd(container)
    if useCount >= 10 then
        ItemOprHelper:useItem(thisItemId, 10);
    elseif useCount < 10 and useCount > 0 then
        ItemOprHelper:useItem(thisItemId, useCount);
    else
        ItemOprHelper:useItem(thisItemId, 1)
    end
end

function RuneStonesUpgradeBase:onClose(container)
    PageManager.popPage(thisPageName);
end


-- 回包处理
function RuneStonesUpgradeBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.ITEM_USE_S then
        -- local msg = ItemOpr_pb.HPItemUseRet();
        -- msg:ParseFromString(msgBuff);
        local tipKey = "@SoulStoneUpgradeSuccess";
        local colorKey = "COLOR_GREEN";

        common:popString(common:getLanguageString(tipKey), colorKey);
        self:refreshPage(container);
    end
end

function RuneStonesUpgradeBase:registerPacket(container)
    container:registerPacket(opcodes.ITEM_USE_S)
end

function RuneStonesUpgradeBase:removePacket(container)
    container:removePacket(opcodes.ITEM_USE_S)
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local RuneStonesUpgradePage = CommonPage.newSub(RuneStonesUpgradeBase, thisPageName, option);

