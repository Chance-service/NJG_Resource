
-- 兑换道具

local option = {
    ccbiFile = "ManyPeopleMapShopBuyPopUp.ccbi",
    handlerMap =
    {
        onClose = "onNo",
        onCancel = "onNo",
        onConfirmation = "onYes",
        onAdd = "onIncrease",
        onAddTen = "onIncreaseTen",
        onReduction = "onDecrease",
        onReductionTen = "onDecreaseTen",
    }
}
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "CountTimesWithIconPage";
local CommonPage = require("CommonPage");
local MultiEliteDataManger = require("Battle.MultiEliteDataManger")
local UserMercenaryManager = require("UserMercenaryManager")
-- define
local ConsumeMoneyType = {
    MONEY_GOLD = Const_pb.MONEY_GOLD,
    MONEY_COIN = Const_pb.MONEY_COIN,
    MONEY_COURAGE = 3,
    -- 物品兑换活动
    GOODS_EXCHANGE = 4,
    -- 竞技场兑换
    ARENA_EXCHANGE = 5,
    -- 联盟商店
    ALLIANCE_EXCHANGE = 6,
    -- 神器制造
    GODLYEQUIP_BUILD = 8,

    -- 引换券
    ITEM_106011 = 106011,
    -- 引换币
    ITEM_299992 = 299992,
}
local ItemType = {
    NORMAL = 0,
    SUIT_FRAGMENT = 19,
}


local resType = 0;
local resId = 0;
local itemType = ItemType.NORMAL
local decisionCB = nil;
local autoClose = true;
local maxCount = 100;
local priceGetter = nil;
local curCount = 1;
local priceType = ConsumeMoneyType.MONEY_GOLD
local resEnough = true;
local titleStr = nil;
local totalResNum = -1
local errorMessage = "@ERRORCODE_155"
local titleDesc = nil
local mMercenaryId = nil

local NodeHelper = require("NodeHelper");
local CountTimesWithIconPageBase = { }
----------------------------------------------------------------------------------
-- CountTimesWithIconPage页面中的事件处理
----------------------------------------------
function CountTimesWithIconPageBase:onEnter(container)
    curCount = 1;
    self:refreshPage(container);
    container:registerMessage(MSG_MAINFRAME_PUSHPAGE);
    local relativeNode = container:getVarNode("S9_1")
    GameUtil:clickOtherClosePage(relativeNode, function()
        self:onNo(container)
    end , container)
end


function CountTimesWithIconPageBase:setMercenaryId(obj)
    mMercenaryId = obj
end


function CountTimesWithIconPageBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_PUSHPAGE);
    mMercenaryId = nil
    onUnload(thisPageName, container)
end

function CountTimesWithIconPageBase:refreshPage(container)
    NodeHelper:setStringForLabel(container, {
        mTitle = common:getLanguageString(titleStr),
        -- mReduceNum      = "<<",
        -- mTopNum         = ">>"
    } )

    if mMercenaryId ~= nil then
        local str2Label = { }
        local obj = UserMercenaryManager:getMercenaryStatusByItemId(mMercenaryId.roleId)
        local roleConfig = ConfigManager.getRoleCfg()
        local name = roleConfig[mMercenaryId.roleId].name
        str2Label["mTotleNum"] = common:getLanguageString("@TurntableMercenaryNumber", name) .. obj.soulCount .. "/" .. obj.costSoulCount
        str2Label["mNowNum"] = ""
        NodeHelper:setNodesVisible(container, { mActNode = true, mDecisionTex = false })
        NodeHelper:setStringForLabel(container, str2Label)
    else
        NodeHelper:setNodesVisible(container, { mActNode = false, mDecisionTex = true })
    end

    self:refreshResNameIcon(container)
    self:refreshCountAndPrice(container, 0)
end

function CountTimesWithIconPageBase:refreshResNameIcon(container)
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(resType * 10000, resId)
    NodeHelper:setStringForLabel(container, { mItemName = resInfo.name })
    -- img
    NodeHelper:setSpriteImage(container, { mPic = resInfo.icon })
    NodeHelper:setQualityFrames(container, { mFrame = resInfo.quality })
    -- count
    if resType == Const_pb.TOOL then
        local UserItemManager = require("Item.UserItemManager")
        local userItemInfo = UserItemManager:getUserItemByItemId(resId)
        local countStr = "--"
        if userItemInfo ~= nil then
            countStr = userItemInfo.count
        end
        local itemCfg = ConfigManager.getItemCfg()
        local itemInfo = itemCfg[resId]
        itemType = itemInfo and itemInfo.type or 0
        -- if suit fragment,show composing needed num
        if itemType == ItemType.SUIT_FRAGMENT then
            if itemInfo ~= nil then
                local equipMsg = parseItemWithOutCount(itemInfo.containItem)
                if equipMsg ~= nil and #equipMsg ~= 0 then
                    local composeCount = equipMsg[1].type
                    countStr = countStr == "--" and 0 or countStr
                    countStr = countStr .. "/" .. composeCount
                end
            end
            NodeHelper:setNodesVisible(container, { mCurrentHaveNum = true })
            NodeHelper:setStringForLabel(container, { mCurrentHaveNum = countStr })
        else
            NodeHelper:setStringForLabel(container, { mCurrentHaveNum = "", mCurrentHaveLab = "" })
        end
    else
        NodeHelper:setStringForLabel(container, { mCurrentHaveNum = "", mCurrentHaveLab = "" })
    end
end

function CountTimesWithIconPageBase:refreshCountAndPrice(container, num)
    if curCount > maxCount then
        curCount = maxCount
    end
    resEnough = true
    if priceGetter == nil then
        NodeHelper:setNodesVisible(container, { mCostGoldLab = false, mCostGoldNum = false })
        NodeHelper:setStringForLabel(container, { mAddNum = curCount })
        return
    end
    NodeHelper:setStringForLabel(container, { mCostGoldLab = common:getLanguageString("@GemCostGold") })
    local totalPrice = priceGetter(curCount)
    local priceMsg = ""
    local sprite2Img = { }
    -- local iconScale = { }
    local visible = { }
    local priceColor = GameConfig.ColorMap.COLOR_GREEN
    local mExchangePer = totalPrice / curCount
    if priceType == ConsumeMoneyType.MONEY_GOLD then
        -- priceMsg = common:getLanguageString("@CostGold1")
        if totalPrice > UserInfo.playerInfo.gold then
            priceColor = GameConfig.ColorMap.COLOR_RED
            resEnough = false;
            errorMessage = "@ERRORCODE_14"
        end
        sprite2Img["mIconPic"] = GameConfig.DiamondImage
        -- errorMessage = "@ERRORCODE_14"
    elseif priceType == ConsumeMoneyType.MONEY_COIN then
        -- priceMsg = common:getLanguageString("@CostCoin1")
        if totalPrice > UserInfo.playerInfo.coin then
            priceColor = GameConfig.ColorMap.COLOR_RED
            resEnough = false;
            errorMessage = "@ERRORCODE_13"
        end
        sprite2Img["mIconPic"] = GameConfig.GoldImage
        -- errorMessage = "@ERRORCODE_13"
    elseif priceType == ConsumeMoneyType.MONEY_COURAGE then
        priceMsg = common:getLanguageString("@Courage")
        if totalPrice > MultiEliteDataManger:getMyScore() then
            priceColor = GameConfig.ColorMap.COLOR_RED
            resEnough = false;
        end
    elseif priceType == ConsumeMoneyType.GOODS_EXCHANGE then
        visible["mIconPic"] = false
        if totalPrice > tonumber(totalResNum) then
            priceColor = GameConfig.ColorMap.COLOR_RED
            resEnough = false;
        end
    elseif priceType == ConsumeMoneyType.ARENA_EXCHANGE then
        -- 竞技场兑换 TODO
        sprite2Img["mIconPic"] = GameConfig.ArenaRecordImage
        if curCount == maxCount then
            -- resEnough = false
            -- errMsg = "@ERRORCODE_155"
        end
        --       if totalPrice > UserInfo.playerInfo.honorValue then
        --            resEnough = false
        --            errMsg = "@HonorExchangeHonorValueNotEnough"
        --        end
    elseif priceType == ConsumeMoneyType.ALLIANCE_EXCHANGE then
        sprite2Img["mIconPic"] = GameConfig.ALLIANCEImage
        NodeHelper:setNodeScale(container, "mIconPic", 0.9, 0.9)
        -- 联盟商店
    elseif priceType == ConsumeMoneyType.GODLYEQUIP_BUILD then
        local needReputation, needSmeltValue = priceGetter(curCount)
        visible["mIconPic"] = false
        if needSmeltValue > UserInfo.playerInfo.smeltValue then
            resEnough = false;
            priceColor = GameConfig.ColorMap.COLOR_RED
            errorMessage = "@SmeltValueNotEnough"
        elseif needReputation > UserInfo.playerInfo.reputationValue then
            resEnough = false;
            priceColor = GameConfig.ColorMap.COLOR_RED
            errorMessage = "@ReputationNotEnough"
        end
        totalPrice = common:getLanguageString("@MyReputation", needReputation) .. "  " .. common:getLanguageString('@MySmelting', needSmeltValue)

    elseif priceType == ConsumeMoneyType.ITEM_106011 then
        -- 副将碎片兑换
        visible["mIconPic"] = false
        priceMsg = common:getLanguageString("@Item_106011")
    elseif priceType == ConsumeMoneyType.ITEM_299992 then
        visible["mIconPic"] = false
        priceMsg = common:getLanguageString("@Item_299992")
    elseif type(priceType) == "table" then
        if priceType.type and priceType.itemId then
            local priRes = ResManagerForLua:getResInfoByTypeAndId(priceType.type, priceType.itemId, priceType.count, true);
            priceMsg = priRes.name;
            if totalPrice > priRes.count then
                -- priceColor = GameConfig.ColorMap.COLOR_RED
                resEnough = false;
                local tmp2 = 0
                if num == 10 then
                    curCount, tmp2 = math.modf(priRes.count / mExchangePer)
                else
                    curCount = curCount - num
                end

                totalPrice = priceGetter(curCount)
            end
            sprite2Img["mIconPic"] = "UI/Mask/Image_Empty.png"
            errorMessage = "@resNotEnough"
            if not resEnough then
                resEnough = true
                MessageBoxPage:Msg_Box_Lan(errorMessage)
            end

        end
    elseif totalResNum ~= -1 then
        visible["mIconPic"] = false
        if totalPrice > tonumber(totalResNum) then
            -- priceColor = GameConfig.ColorMap.COLOR_RED
            resEnough = false;
            local tmp2 = 0
            if num == 10 then
                curCount, tmp2 = math.modf(totalResNum / mExchangePer)
            else
                curCount = curCount - num
            end
            totalPrice = priceGetter(curCount)
            errorMessage = "@resNotEnough"
            if not resEnough then
                resEnough = true
                MessageBoxPage:Msg_Box_Lan(errorMessage)
            end
        end
    else --if priceType > 100000 and priceType < 520000 then
        visible["mIconPic"] = false
        priceMsg = common:getLanguageString("@Item_" .. priceType)
    end
    NodeHelper:setNodesVisible(container, visible)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setStringForLabel(container, { mCostGoldNum = totalPrice .. priceMsg, mAddNum = curCount, mDecisionTex = titleDesc })
    NodeHelper:setColorForLabel(container, { mCostGoldNum = priceColor })


    if mMercenaryId ~= nil then
        local obj = UserMercenaryManager:getMercenaryStatusByItemId(mMercenaryId.roleId)
        if obj.soulCount >= obj.costSoulCount or(curCount * mMercenaryId.num + obj.soulCount) > obj.costSoulCount then
            -- mercenaryColor = GameConfig.ColorMap.COLOR_RED
        end
        local str2Label = { }
        str2Label["mNowNum"] = common:getLanguageString("@AlreadySelectNumber") .. mMercenaryId.num * curCount
        NodeHelper:setStringForLabel(container, str2Label)
    end
end

function CountTimesWithIconPageBase:onNo(container)
    if decisionCB then
        decisionCB(false);
    end
    GameUtil:hideClickOtherPage()
    PageManager.popPage(thisPageName)
end

function CountTimesWithIconPageBase:onYes(container)
    if decisionCB then
        if curCount > 0 then
            if resEnough then
                --                if mMercenaryId ~= nil then
                --                    local obj = UserMercenaryManager:getMercenaryStatusByItemId(mMercenaryId.roleId)
                --                    if obj.soulCount >= obj.costSoulCount or (curCount*mMercenaryId.num + obj.soulCount) > obj.costSoulCount then--如果佣兵碎片已满，提示
                --                        local title = common:getLanguageString("@AlreadySelectNumber2")
                --                        local message = common:getLanguageString("@AlreadySelectNumber1")
                --                        PageManager.showConfirm(title, message,
                --                        function (agree)
                --                            if agree then
                --                                decisionCB(true,curCount);
                --                                if autoClose then
                --                                    PageManager.popPage(thisPageName)
                --                                end
                --                            end
                --                        end)
                --                        return
                --                    else
                --                        decisionCB(true,curCount);
                --                    end
                decisionCB(true, curCount, priceType);
            else
                MessageBoxPage:Msg_Box_Lan(errorMessage)
            end
        end
    end
    if autoClose then
        PageManager.popPage(thisPageName)
    end
end	


function CountTimesWithIconPageBase:onIncrease(container)
    if curCount > 0 then
        if curCount == maxCount then
            -- MessageBoxPage:Msg_Box_Lan("@ERRORCODE_155")
            MessageBoxPage:Msg_Box_Lan(errorMessage)
            return
        end
        curCount = curCount + 1
        self:refreshCountAndPrice(container, 1)
    end
end


function CountTimesWithIconPageBase:onDecrease(container)
    if curCount <= 1 then
        return
    end
    curCount = curCount - 1
    self:refreshCountAndPrice(container, -1)
end


function CountTimesWithIconPageBase:onIncreaseTen(container)
    if curCount > 0 then
        if curCount >(maxCount - 10) then
            MessageBoxPage:Msg_Box_Lan(errorMessage)

            -- MessageBoxPage:Msg_Box_Lan("@ERRORCODE_155")
            curCount = maxCount
        else
            curCount = curCount + 10
        end
        self:refreshCountAndPrice(container, 10)
        --        if  not resEnough then
        -- 	    MessageBoxPage:Msg_Box_Lan(errorMessage)
        --        end
    end
end


function CountTimesWithIconPageBase:onDecreaseTen(container)
    if curCount < 10 then
        curCount = 1
    else
        curCount = curCount - 10
    end
    self:refreshCountAndPrice(container, -10)
end



function CountTimesWithIconPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_MAINFRAME_PUSHPAGE then
        local pageName = MsgMainFramePushPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:refreshPage(container);
        end
    end
end
-------------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local CountTimesWithIconPage = CommonPage.newSub(CountTimesWithIconPageBase, thisPageName, option);
-------------------------------------------------------------------------------



function CountTimesWithIconPageBase_setMercenaryData(obj)
    mMercenaryId = obj
end

function CountTimesWithIconPage_show(type, id, currencyType, priceFunc, callback, auto, max, title, notEnoughStr, totalRes, desc)
    resType = type >= 10000 and math.floor(type / 10000) or type
    resId = id
    priceType = currencyType or ConsumeMoneyType.MONEY_GOLD
    priceGetter = priceFunc or nil
    decisionCB = callback
    autoClose = auto or true
    maxCount = max or 999
    itemType = 0
    totalResNum = totalRes or -1
    titleStr = title or "@ExchangeCountTitle";
    errorMessage = notEnoughStr or "@ERRORCODE_155"
    titleDesc = desc or common:getLanguageString("@DecisionTex")
    PageManager.pushPage(thisPageName);
end

