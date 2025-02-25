----------------------------------------------------------------------------------
local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local ItemOpr_pb = require("ItemOpr_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
------------local variable for system api--------------------------------------
local tostring = tostring
local tonumber = tonumber
local string = string
local pairs = pairs
local table = table
local math = math
--------------------------------------------------------------------------------
local PageType = {
    GemUpgrade = 1,
    SoulStoneUpgrade = 2,
}
local thisPageName = "gemNewCompoundPage"
local thisItemId = 0
local thisExp = 0

local opcodes = {
    ITEM_USE_S = HP_pb.ITEM_USE_S
}

local option = {
    ccbiFile = "BackpackGemCompoundPopUp.ccbi",
    handlerMap = {
        onAllGemCompound = "onAllGemCompound",
        onGemCompound = "onGemCompound",
        onHelp = "onHelp",
        onClose = "onClose"
    },
    opcode = opcodes
}

local gemNewCompoundPageBase = { }

local NodeHelper = require("NodeHelper")
local ItemOprHelper = require("Item.ItemOprHelper")
local ItemManager = require("Item.ItemManager")
local UserItemManager = require("Item.UserItemManager")

local originalExpScaleX = nil

-----------------------------------------------
-- gemNewCompoundPageBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function gemNewCompoundPageBase:onEnter(container)
    -- self:setAllNodeVisible(container, false)
    local userLevel = UserInfo.roleInfo.level
    -- 一键合成等级限制
    if userLevel < GameConfig.GemCompoundLevelLimit then
        NodeHelper:setStringForLabel(container, { mUpgradeLabe = common:getLanguageString("@SoulStoneUpgradeBtnLabel") })
    else
        NodeHelper:setNodesVisible(container, { mAllNode = true })
        NodeHelper:setNodesVisible(container, { mOnceNode = false })
        NodeHelper:setStringForLabel(container, { mAllUpgradeLabe = common:getLanguageString("@SoulStoneUpgradeBtnLabel") })
        NodeHelper:setStringForLabel(container, { mOneKeyUpgradeLabel = common:getLanguageString("@oneKeyCompoundBtn") })
    end
    self:registerPacket(container)
    self:refreshPage(container)
end

function gemNewCompoundPageBase:onExit(container)
    self:removePacket(container)
end
----------------------------------------------------------------
function gemNewCompoundPageBase:setAllNodeVisible(container, visible)
    NodeHelper:setNodesVisible(container, {
        mTitle = visible,
        mGemUpgradeUpExplain = visible,
        mExpNode = visible,
        mUpgradeLabel = visible,
        mUpgradeCostLabel = visible,
    } )
end

function gemNewCompoundPageBase:refreshPage(container)
    self:showGemInfo(container)
    -- self:showUpgradeInfo(container)
end

function gemNewCompoundPageBase:showGemInfo(container)
    local name = ItemManager:getNameById(thisItemId)
    local targetId = ItemManager:getLevelUpTarget(thisItemId)
    local costInfo = ConfigManager.parseItemWithComma(ItemManager:getStoneLevelUpCost(thisItemId))
    local coinStr, resNum, costTips
    if costInfo[2].itemId == Const_pb.COIN then
        resNum = UserInfo.playerInfo.coin
        coinStr = GameUtil:formatNumber(resNum)
        costTips = common:getLanguageString("@FairCoinContentTxt1")
    else
        resNum = UserInfo.playerInfo.gold
        coinStr = tostring(resNum)
        costTips = common:getLanguageString("@PossessGold")
    end
    local lb2Str = {
        mNumber = UserItemManager:getCountByItemId(costInfo[1].itemId),
        mNumber1 = "1",
        mName = "",
        mName1 = "",
        mGemUpgradeUpName1 = name,
        mGemUpgradeUpName2 = ItemManager:getNameById(targetId),
        mGold = costTips .. " " .. coinStr .. "/" .. costInfo[2].count,
        -- mCostTxt            = costTips

    };
    NodeHelper:setNodesVisible(container, {
        mCoin = costInfo[2].itemId == Const_pb.COIN,
        mDiamond = costInfo[2].itemId == Const_pb.GOLD
    } )
    local sprite2Img = {
        mPic = ItemManager:getIconById(thisItemId),
        mPic1 = ItemManager:getIconById(targetId),
        mFrameShade = NodeHelper:getImageBgByQuality(ItemManager:getQualityById(thisItemId)),
        mFrameShade1 = NodeHelper:getImageBgByQuality(ItemManager:getQualityById(targetId)),
    }

    local itemImg2Qulity = {
        mHand = ItemManager:getQualityById(thisItemId),
        mHand1 = ItemManager:getQualityById(targetId)
    }

    local scaleMap = { mPic = 1.0 }
    --[[
	local priceColor = GameConfig.ColorMap.COLOR_WHITE
	if resNum < costInfo[2].count then
		priceColor = GameConfig.ColorMap.COLOR_RED
	end
	NodeHelper:setColorForLabel(container,{mGold=priceColor})

	priceColor = GameConfig.ColorMap.COLOR_WHITE
	if UserItemManager:getCountByItemId(costInfo[1].itemId) < costInfo[1].count then
		priceColor = GameConfig.ColorMap.COLOR_RED
	end
	NodeHelper:setColorForLabel(container,{mNumber=priceColor})--]]
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img, scaleMap)
    NodeHelper:setQualityFrames(container, itemImg2Qulity)
end

----------------click event------------------------
function gemNewCompoundPageBase:onAllGemCompound(container)
    print("onAllGemCompound ~~~~~~~~~~~~~~~~~~~~~")
    local costInfo = ConfigManager.parseItemWithComma(ItemManager:getStoneLevelUpCost(thisItemId))
    local stoneNum = UserItemManager:getCountByItemId(costInfo[1].itemId)
    if stoneNum < costInfo[1].count then
        MessageBoxPage:Msg_Box(ItemManager:getNameById(costInfo[1].itemId) .. common:getLanguageString("@NotEnough"))
    else
        if (costInfo[2].itemId == Const_pb.COIN and UserInfo.isCoinEnough(costInfo[2].count)) or (costInfo[2].itemId == Const_pb.GOLD and UserInfo.isGoldEnough(costInfo[2].count)) then
            local costNum = costInfo[2].count
            PageManager.showCountTimesWithIconPage(costInfo[1].type, costInfo[1].itemId, costInfo[2].itemId % 1000,
            function(count)
                return count * costNum
            end ,
            function(isBuy, count)
                if isBuy then
                    ItemOprHelper:useItem(thisItemId, count)
                end
            end , true, --[[math.floor(stoneNum / costInfo[1].count)]]50, "@GemExchangeTitle", "@GemSynLimit")
        end
    end
end

function gemNewCompoundPageBase:onGemCompound(container)
    local name = ItemManager:getNameById(thisItemId)
    local costName = common:split(name, "L")
    local targetId = ItemManager:getLevelUpTarget(thisItemId)
    local costInfo = ConfigManager.parseItemWithComma(ItemManager:getStoneLevelUpCost(thisItemId))
    local itemType = ItemManager:getTypeById(thisItemId)
    local itemStone = ItemManager:getStoneType(thisItemId)
    local totalNumber = UserItemManager:getItemIdsByType(itemType)
    local a = 0
    -- 每种宝石的数量
    local b = 0
    -- 每种宝石换算成一级宝石的数量
    local goal = 0
    -- 总共一级宝石的数量
    local minusMoney = 0
    local tableItem = { }
    local tempcostCopper = 0
    local tempcostGold = 0
    local costCopper = 0
    local costGold = 0
    self.firstCopperCost = nil
    self.firstGoldCost = nil
    for k, v in pairs(totalNumber) do
        if (ItemManager:getStoneType(v) == itemStone) then
            local tempTable = { }
            table.insert(tempTable, v)
            local m = string.sub(tostring(v), -2)
            table.insert(tempTable, tonumber(m))
            a = UserItemManager:getCountByItemId(v)
            table.insert(tempTable, a)
            local tempMoney = ItemManager:getStoneLevelUpCost(v)
            table.insert(tempTable, tempMoney)
            local costMoney = common:split(tempMoney, "_")
            table.insert(tempTable, costMoney[5])
            b = a *(2 ^(m - 1))
            table.insert(tempTable, b)
            table.insert(tableItem, tempTable)
            table.sort(tableItem, function(m1, m2)
                return m1[1] < m2[1]
            end )
            goal = goal + b
        end
    end

    local getItemId = string.sub(tostring(thisItemId), 1, 4)
    local tatalId = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    local tempNums = 0
    local copperTemp = { }
    local goldTemp = { }
    for i = 1, table.getn(tableItem) do
        if tableItem[i][2] then
            tatalId[tableItem[i][2]] = tableItem[i][3]
        end
        if tableItem[table.getn(tableItem)][2] ~= 15 then
            if tableItem[i][3] == 1 then
                tempNums = tempNums + 1
            end
            if tempNums == table.getn(tableItem) then
                MessageBoxPage:Msg_Box(costName[1] .. common:getLanguageString("@NotEnough"))
                return
            end
        else
            if i < table.getn(tableItem) then
                if tableItem[i][3] == 1 then
                    tempNums = tempNums + 1
                end
                if tempNums == table.getn(tableItem) -1 then
                    MessageBoxPage:Msg_Box(costName[1] .. common:getLanguageString("@NotEnough"))
                    return
                end
            end
        end
        if tableItem[i][3] > 1 then
            if tonumber(tableItem[i][5]) > 10000 then
                table.insert(copperTemp, tonumber(tableItem[i][5]))
            else
                table.insert(goldTemp, tonumber(tableItem[i][5]))
            end
        end
    end
    if copperTemp[1] ~= nil then
        self.firstCopperCost = copperTemp[1]
    end
    if goldTemp[1] ~= nil then
        self.firstGoldCost = goldTemp[1]
    end

    local finalCopperCost = 0
    local finalGoldCost = 0
    local eachCost = { }
    for i = 1, 15 do
        local tempId
        local itemCost
        local costItemMoney
        local costtemp = { }
        if i < 10 then
            tempId = getItemId .. "0" .. tostring(i)
            itemCost = ItemManager:getStoneLevelUpCost(tonumber(tempId))
            costItemMoney = common:split(itemCost, "_")
        else
            tempId = getItemId .. tostring(i)
            itemCost = ItemManager:getStoneLevelUpCost(tonumber(tempId))
            costItemMoney = common:split(itemCost, "_")
        end
        table.insert(costtemp, costItemMoney[5])
        table.insert(costtemp, i)
        table.insert(eachCost, costtemp)
        if i < 15 then
            if tatalId[i] ~= 0 then
                tatalId[i + 1] = math.floor(tatalId[i] / 2) + tatalId[i + 1]
                if tonumber(eachCost[i][1]) > 10000 then
                    finalCopperCost = finalCopperCost + math.floor(tatalId[i] / 2) * tonumber(eachCost[i][1])
                else
                    finalGoldCost = finalGoldCost + math.floor(tatalId[i] / 2) * tonumber(eachCost[i][1])
                end
                tatalId[i] = tatalId[i] % 2
            end
        end
    end
    --    dump(eachCost)
    --    dump(tatalId)
    -- dump(tableItem)
    -- dump(finalCopperCost)
    -- dump(finalGoldCost)
    local userGold = UserInfo.playerInfo.gold
    local userCoin = UserInfo.playerInfo.coin
    self.userGold = userGold
    self.userCoin = userCoin
    self.finalCopperCost = finalCopperCost
    self.finalGoldCost = finalGoldCost
    local msg

    --    if finalCopperCost <= userCoin and finalGoldCost <= userGold then
    --        msg = common:fillHtmlStr('gemCompoundTip1', costName[1], GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalGoldCost), GameUtil:formatNumber(userGold));
    --    elseif finalCopperCost <= userCoin and finalGoldCost > userGold then
    --        msg = common:fillHtmlStr('gemCompoundTip3', costName[1], GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalGoldCost), GameUtil:formatNumber(userGold));
    --    elseif finalCopperCost > userCoin and finalGoldCost <= userGold then
    --        msg = common:fillHtmlStr('gemCompoundTip2', costName[1], GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalGoldCost), GameUtil:formatNumber(userGold));
    --    elseif finalCopperCost > userCoin and finalGoldCost > userGold then
    --        msg = common:fillHtmlStr('gemCompoundTip4', costName[1], GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalGoldCost), GameUtil:formatNumber(userGold));
    --    end

    if finalCopperCost <= userCoin and finalGoldCost <= userGold then
        msg = common:fillHtmlStr("gemCompoundTip1", costName[1], GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userGold), GameUtil:formatNumber(finalGoldCost))
    elseif finalCopperCost <= userCoin and finalGoldCost > userGold then
        msg = common:fillHtmlStr("gemCompoundTip3", costName[1], GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userGold), GameUtil:formatNumber(finalGoldCost))
    elseif finalCopperCost > userCoin and finalGoldCost <= userGold then
        msg = common:fillHtmlStr("gemCompoundTip2", costName[1], GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userGold), GameUtil:formatNumber(finalGoldCost))
    elseif finalCopperCost > userCoin and finalGoldCost > userGold then
        msg = common:fillHtmlStr("gemCompoundTip4", costName[1], GameUtil:formatNumber(userCoin), GameUtil:formatNumber(finalCopperCost), GameUtil:formatNumber(userGold), GameUtil:formatNumber(finalGoldCost))
    end

    local title = common:getLanguageString("@oneKeyCompoundBtn")
    PageManager.showHtmlConfirm(title, msg, function(isSure)
        if isSure then
            ItemOprHelper:onceCompoundItem(thisItemId)
            PageManager.popPage("DecisionPage")
        end
    end )
end

function gemNewCompoundPageBase:onAKeyToUpGrade(container)
    ItemOprHelper:useItem(thisItemId, 10)
end

function gemNewCompoundPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEWGEMCOMPOUND)
end	

function gemNewCompoundPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

-- »Ø°ü´¦Àí
function gemNewCompoundPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.ITEM_USE_S then
        local msg = ItemOpr_pb.HPItemUseRet()
        msg:ParseFromString(msgBuff)
        if msg.msgType == Const_pb.GEM_COMPOUND_ONCE then
            if self.firstGoldCost == nil and self.firstCopperCost ~= nil then
                if self.userCoin < self.firstCopperCost then
                    MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
                end
            elseif self.firstGoldCost ~= nil and self.firstCopperCost == nil then
                if self.userGold < self.firstGoldCost then
                    MessageBoxPage:Msg_Box_Lan("@ERRORCODE_14")
                end
            elseif self.firstGoldCost ~= nil and self.firstCopperCost ~= nil then
                if self.userGold < self.firstGoldCost and self.userCoin < self.firstCopperCost then
                    MessageBoxPage:Msg_Box_Lan("@ERRORCODE_25")
                end
            end
        end
        if msg.targetItemId == 0 then
            -- common:popString(common:getLanguageString("@UpgradeGemFail"), "COLOR_YELLOW");
        end
        self:refreshPage(container)
        PageManager.popPage(thisPageName)
    end
end

function gemNewCompoundPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function gemNewCompoundPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
gemNewCompoundPage = CommonPage.newSub(gemNewCompoundPageBase, thisPageName, option)

function gemNewCompoundPage_setItemId(itemId, pageType)
    thisItemId = itemId
end
