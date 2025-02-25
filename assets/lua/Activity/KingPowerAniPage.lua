----------------------------------------------------------------------------------
--[[
	百花美人奖励
--]]
----------------------------------------------------------------------------------
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local MercenaryCfg = nil
local thisPageName = "KingPowerAniPage"
local UserItemManager = require("Item.UserItemManager")
local opcodes = {
    SYNC_HAREM_C = HP_pb.SYNC_HAREM_C,
    SYNC_HAREM_S = HP_pb.SYNC_HAREM_S,
    HAREM_PANEL_INFO_C = HP_pb.HAREM_PANEL_INFO_C,
    HAREM_PANEL_INFO_S = HP_pb.HAREM_PANEL_INFO_S,
    HAREM_DRAW_S = HP_pb.HAREM_DRAW_S,
    HAREM_DRAW_C = HP_pb.HAREM_DRAW_C,
};

local option = {
    ccbiFile = "Act_TimeLimitKingPalaceRewardAniNew.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onFree = "onFree",
        onFree = "onFree",
        onDiamond = "onDiamond"
    },
}
local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
}

for i = 1, 11 do
    option.handlerMap["onHand" .. i] = "onHand";
end


local itemImageTable = {
    [1] = { propIcon = "common_ht_jinbi_img.png" },
    -- 普通
    [2] = { propIcon = "Activity_common_quan_1.png" },
    -- 中级
    [3] = { propIcon = "Activity_common_quan_2.png" },
    -- 高级
    [4] = { propIcon = "Activity_common_quan_1.png" },
    [5] = { propIcon = "Activity_common_quan_2.png" }-- 新手扭蛋用高级抽奖券
}


local mRewardItemMoveEndPos = { }
local mCurrentShowIndex = 1
----------------- local data -----------------
local KingPowerAniBase = { }

local thisActivityInfo = {
    exChangeItemId = { 0, },
    times = 0,
    rewardItems = { },
    inAni = false,
    score = 1
}

local isPop = false
-----------------------------------------------
--------------------------Content--------------
local RewardPropItem = {
    ccbiFile = "GoodsItem.ccbi",
}

function RewardPropItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function RewardPropItem:onHand(container)

end

function RewardPropItem:refresh()

end

-------------------------------------------------------
function KingPowerAniBase:onHand(container, eventName)
    local index = tonumber(string.sub(eventName, 7, string.len(eventName)))
    local dataIndex = index
    if index > 10 then dataIndex = index % 10 end
    if thisActivityInfo.rewardItems[dataIndex] then
        GameUtil:showTip(container:getVarNode('mPic' .. index), thisActivityInfo.rewardItems[dataIndex])
    end
end

function KingPowerAniBase:onFree(container)
    if thisActivityInfo.inAni then return end
    local haremData = thisActivityInfo.haremData
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
    local num = 0;
    local itemId = haremCfg.items.itemId
    if itemId ~= 0 then
        num = UserItemManager:getCountByItemId(itemId)
    end

    if haremData.haremType == 1 then
        if UserInfo.playerInfo.coin < haremCfg.onceGold and not isFree then
            PageManager.notifyLackCoin()
        else
            local msg = Activity2_pb.HPHaremDraw();
            msg.type = thisActivityInfo.haremData.haremType;
            msg.times = 1
            common:sendPacket(opcodes.HAREM_DRAW_C, msg);
        end
    else
        if num < 1 and not isFree and UserInfo.playerInfo.gold < haremCfg.onceGold then
            common:rechargePageFlag("KingPowerAniBase")
        else
            local msg = Activity2_pb.HPHaremDraw();
            msg.type = thisActivityInfo.haremData.haremType;
            msg.times = 1
            common:sendPacket(opcodes.HAREM_DRAW_C, msg);
        end
    end

end

function KingPowerAniBase:onDiamond(container)
    if thisActivityInfo.inAni then return end
    local haremData = thisActivityInfo.haremData
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]
    local num = 0;
    local itemId = haremCfg.items.itemId
    if itemId ~= 0 then
        num = UserItemManager:getCountByItemId(itemId)
    end

    if haremData.haremType == 1 then
        if haremData.dayLeftTimes >= 10 then
            -- 剩余次数大于10次的情况
            if UserInfo.playerInfo.coin < haremCfg.tenGold then
                PageManager.notifyLackCoin()
            else
                local msg = Activity2_pb.HPHaremDraw();
                msg.type = haremData.haremType
                msg.times = 10
                common:sendPacket(opcodes.HAREM_DRAW_C, msg);
            end
        else
            -- 剩余次数小于10次的情况
            if UserInfo.playerInfo.coin < haremCfg.onceGold * haremData.dayLeftTimes then
                PageManager.notifyLackCoin()
            else
                local msg = Activity2_pb.HPHaremDraw();
                msg.type = haremData.haremType
                msg.times = haremData.dayLeftTimes
                common:sendPacket(opcodes.HAREM_DRAW_C, msg);
            end
        end
    else
        if num < 10 and UserInfo.playerInfo.gold < haremCfg.tenGold then
            common:rechargePageFlag("KingPowerAniBase")
        else
            local msg = Activity2_pb.HPHaremDraw()
            dump(thisActivityInfo.haremData)
            msg.type = thisActivityInfo.haremData.haremType
            msg.times = 10
            print("msg.type = ", msg.type)
            common:sendPacket(opcodes.HAREM_DRAW_C, msg)
        end
    end
end

---------------------------------------------------------------

function KingPowerAniBase:onEnter(container)
    self.container = container
    isPop = true
    MercenaryCfg = ConfigManager.getRoleCfg()
    thisActivityInfo.activityCfg = ConfigManager.getKingPowerCfg()
    thisActivityInfo.inAni = false
    mCurrentShowIndex = 1
    self:registerPacket(container)
    self:refreshPage(container)


    for i = 1, 10 do
        local node = container:getVarNode("mRewardNode" .. i)
        node:removeAllChildren()
        local x = node:getPositionX()
        local y = node:getPositionY()
        mRewardItemMoveEndPos[i] = ccp(x, y)
    end

    local node = container:getVarNode("mRewardNode")
    node:removeAllChildren()
    local x = node:getPositionX()
    local y = node:getPositionY()
    mRewardItemMoveEndPos[11] = ccp(x, y)
    self:removeRewardNodeAllChildren()


    if #thisActivityInfo.reward > 0 then
        self:refreshRewardNode(container)
    end
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["KingPowerAniPage"] = container
    if GuideManager.getCurrentStep() == 29 then
        PageManager.pushPage("NewbieGuideForcedPage")
        PageManager.popPage("NewGuideEmptyPage")
    end
end

function KingPowerAniBase:removeRewardNodeAllChildren()
    local mAllRewardNode = self.container:getVarNode("mAllRewardNode")
    mAllRewardNode:removeAllChildren()
end


function KingPowerAniBase:createAction(time, scale, rotate, endPosition, fun)
    local scaleTo = CCScaleTo:create(time, scale)
    -- local rotateTo = CCRotateTo:create(time, rotate)
    local rotateBy = CCRotateBy:create(time, rotate)
    local moveTo = CCMoveTo:create(time, endPosition)
    local callFunc = CCCallFunc:create( function()
        if fun ~= nil then
            -- fun()
            mCurrentShowIndex = mCurrentShowIndex + 1
            self:refreshRewardNode()
        else
            thisActivityInfo.inAni = false
            mCurrentShowIndex = 1
        end
    end )

    local array = CCArray:create()
    array:addObject(scaleTo)
    array:addObject(rotateBy)
    -- array:addObject(rotateTo)
    array:addObject(moveTo)
    local spawn = CCSpawn:create(array)

    local array1 = CCArray:create();
    array1:addObject(spawn)
    array1:addObject(callFunc)
    local sequence = CCSequence:create(array1)

    return sequence
end


function KingPowerAniBase:refreshRewardNode(container)
    thisActivityInfo.inAni = true
    local mAllRewardNode = self.container:getVarNode("mAllRewardNode")
    if #thisActivityInfo.reward == 1 then
        local node = self:createRewardItem(1)
        mAllRewardNode:addChild(node)
        node:setPosition(ccp(0, 200))
        node:setScale(0.1)
        node:runAction(self:createAction(0.2, 1, 360, mRewardItemMoveEndPos[11], nil))
        self:setRollItemData(node, self:formatRollItemData(thisActivityInfo.reward[1]), ConfigManager.parseItemOnlyWithUnderline(thisActivityInfo.reward[1]))
    else

        local data = thisActivityInfo.reward[mCurrentShowIndex]
        -- local data, index = self:deQueue()
        if data ~= nil then
            local node = self:createRewardItem(1)
            mAllRewardNode:addChild(node)
            node:setPosition(ccp(0, 200))
            node:setScale(0.1)
            -- node:setRotation(0)
            node:runAction(self:createAction(0.2, 1, 360, mRewardItemMoveEndPos[mCurrentShowIndex], 1))
            self:setRollItemData(node, self:formatRollItemData(data), ConfigManager.parseItemOnlyWithUnderline(data))
        else
            -- 动画结束
            thisActivityInfo.inAni = false
            mCurrentShowIndex = 1
            if #thisActivityInfo.reward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end
    end
end

function KingPowerAniBase:formatRollItemData(dataStr)
    local _type, _id, _count = unpack(common:split(dataStr, "_"))

    local data = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))
    return data
end

function KingPowerAniBase:deQueue()
    local data = nil
    local index = 1
    local t = { }
    local x = 0

    if common:getTableLen(thisActivityInfo.reward) > 0 then
        for k, v in pairs(thisActivityInfo.reward) do
            if x == 0 then
                data = v
                index = k
            else
                table.insert(t, k, v)
            end
            x = x + 1
        end
    end
    thisActivityInfo.reward = t
    return data, index
end

function KingPowerAniBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function KingPowerAniBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function KingPowerAniBase:refreshPage(container)
    local haremData = thisActivityInfo.haremData
    local haremCfg = thisActivityInfo.activityCfg[haremData.haremType]

    if haremData ~= nil and haremCfg ~= nil then
        -- TODO
        NodeHelper:setStringForLabel(container, { mCostTxt1 = common:getLanguageString("@SilverMoonTenTimes", 1), mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
        local itemImageData = itemImageTable[haremData.haremType]
        local mPriceType_1 = container:getVarSprite("mPriceType_1")
        local mPriceType_2 = container:getVarSprite("mPriceType_2")

        if haremData.haremType == 1 then
            -- 这个是用铜钱抽奖的
            mPriceType_1:setTexture("common_ht_jinbi_img.png")
            mPriceType_2:setTexture("common_ht_jinbi_img.png")

            mPriceType_1:setScale(0.8)
            mPriceType_2:setScale(0.8)
        else
            -- 找个是用钻石抽奖
            mPriceType_1:setTexture("common_ht_zuanshi_img.png")
            mPriceType_2:setTexture("common_ht_zuanshi_img.png")

            mPriceType_1:setScale(0.8)
            mPriceType_2:setScale(0.8)
        end
        NodeHelper:setStringForLabel(container, { mRewardTxt = "" })
        if haremData.haremType == 1 then
            -- 初级
            -- 是否还有次数
            NodeHelper:setMenuItemEnabled(container, "mFree", true)
            NodeHelper:setMenuItemEnabled(container, "mDiamond", true)
            NodeHelper:setNodeIsGray(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false })
            NodeHelper:setStringForLabel(container, { mDiamondText = haremCfg.onceGold * 10, mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
            if haremData.dayLeftTimes > 0 then
                NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mCostNodeVar = true, mTenNodeVar = true, mFreeText = true })
                -- 是否可以免费
                local isFree = haremData.freeChance > 0 and haremData.freeCd == 0
                if isFree then
                    NodeHelper:setNodesVisible(container, { mCostNodeVar = false, mTenNodeVar = true, mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mFreeText = true })
                else
                    NodeHelper:setNodesVisible(container, { mCostNodeVar = true, mTenNodeVar = true, mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mFreeText = false })

                    NodeHelper:setStringForLabel(container, { mCostNum = haremCfg.onceGold })
                    if haremData.dayLeftTimes > 10 then
                        NodeHelper:setStringForLabel(container, { mDiamondText = haremCfg.onceGold * 10, mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", 10) })
                    else
                        NodeHelper:setStringForLabel(container, { mDiamondText = haremCfg.onceGold * haremData.dayLeftTimes, mSuitTenTimes = common:getLanguageString("@SilverMoonTenTimes", haremData.dayLeftTimes) })
                    end
                end
            else
                NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = true, mHuiShuBuZu_2 = true, mCostNodeVar = false, mTenNodeVar = false, mFreeText = false })
                NodeHelper:setMenuItemEnabled(container, "mFree", false)
                NodeHelper:setMenuItemEnabled(container, "mDiamond", false)
                NodeHelper:setNodeIsGray(container, { mHuiShuBuZu_1 = true, mHuiShuBuZu_2 = true })
            end
        else
            NodeHelper:setNodesVisible(container, { mHuiShuBuZu_1 = false, mHuiShuBuZu_2 = false, mCostNodeVar = true, mTenNodeVar = true, mFreeText = false })


            local price1 = haremCfg.onceGold
            local price2 = haremCfg.tenGold
            local itemId = haremCfg.items.itemId
            if itemId ~= 0 then
                local num = UserItemManager:getCountByItemId(itemId)
                if num > 0 then
                    price1 = 1
                    -- 显示道具图标
                    mPriceType_1:setTexture(itemImageData.propIcon)
                    mPriceType_1:setScale(0.6)
                end
                if num >= 10 then
                    price2 = 10
                    -- 显示道具图标
                    mPriceType_2:setTexture(itemImageData.propIcon)
                    mPriceType_2:setScale(0.6)

                end
            end

            NodeHelper:setStringForLabel(container, { mCostNum = price1, mDiamondText = price2 })



            NodeHelper:setStringForLabel(container, { mRewardTxt = "" })
            if haremCfg.LuckDesc ~= "0" then
                local str = common:getLanguageString(haremCfg.LuckDesc, haremData.luckyTime, MercenaryCfg[haremCfg.spineId].name)
                str = string.gsub(str, "\n", "")
                NodeHelper:setStringForLabel(container, { mRewardTxt = str })
                -- NodeHelper:setStringForLabel(container, { mRewardTxt = common:getLanguageString(haremCfg.LuckDesc, haremData.luckyTime, MercenaryCfg[haremCfg.spineId].name) })
            end
        end
    end
end


function KingPowerAniBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.HAREM_DRAW_S then
        local msg = Activity2_pb.HPHaremDrawRet()
        msg:ParseFromString(msgBuff);
        -- thisActivityInfo.reward = msg.reward
        thisActivityInfo.reward = { }
        for i = 1, #msg.reward do
            table.insert(thisActivityInfo.reward, msg.reward[i])
        end
        self:removeRewardNodeAllChildren()
        self:refreshRewardNode(container)
        self:refreshPage(container)
        return
    end
    if opcode == opcodes.SYNC_HAREM_S then
        local msg = Activity2_pb.HPSyncHaremRet();
        msg:ParseFromString(msgBuff);

        thisActivityInfo.score = msg.score
        thisActivityInfo.haremData = msg.haremInfo[1]
        self:refreshPage(container)
    end

end

function KingPowerAniBase:clearNotice()
    -- 红点消除
    local hasNotice = false

    for i, v in ipairs(thisActivityInfo.activityCfg) do
        if v.day <= thisActivityInfo.CumulativeLoginDays and not thisActivityInfo.gotAwardCfgId[i] then
            hasNotice = true
            break
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.ACCUMULATIVE_LOGIN);
    end
end

function KingPowerAniBase:onTimer(container)
    local timerName = option.timerName;

    if not TimeCalculator:getInstance():hasKey(timerName) then return; end

    local RemainTime = TimeCalculator:getInstance():getTimeLeft(timerName);

    if RemainTime + 1 > thisActivityInfo.RemainTime then
        return;
    end

    thisActivityInfo.RemainTime = math.max(RemainTime, 0);
    local timeStr = common:second2DateString(thisActivityInfo.RemainTime, false);
    NodeHelper:setStringForLabel(container, { mActivityDaysNum = timeStr });
end


function KingPowerAniBase:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Gacha1" or animationName == "Gacha10" then
        thisActivityInfo.inAni = false
    end
end

function KingPowerAniBase_onClose()
    KingPowerAniBase:onClose()
end
function KingPowerAniBase:onClose(container)
    if thisActivityInfo.inAni then return end
    PageManager.popPage(thisPageName);
    local GuideManager = require("Guide.GuideManager")
end

function KingPowerAniBase:onExit(container)
    self:removePacket(container)
    thisActivityInfo.rewardItems = { }
    isPop = false
    MercenaryCfg = nil
    onUnload(thisPageName, container)
end

function KingPowerAniBase:isPop()
    return isPop
end

function KingPowerAniBase:setRollItemData(item, data, tipsData)

    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")


    iconSprite:setTexture(data.icon)
    numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)

    self:addRewardClick(item, iconSprite, tipsData)

end

function KingPowerAniBase:createRewardItem(index)
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    node:addChild(bgSprite, 0, 1000)

    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    node:addChild(iconSprite, 1, mItemTag.IconSprite)

    local qualitySprite = CCSprite:create("common_ht_propK_bai.png")
    node:addChild(qualitySprite, 2, mItemTag.QualitySprite)

    -- local numTTFLabel = CCLabelTTF:create("x", "Barlow-SemiBold.ttf", 16)
    local numTTFLabel = CCLabelBMFont:create("x", "Lang/Font-HT-Button-White.fnt")
    numTTFLabel:setScale(0.55)
    numTTFLabel:setAnchorPoint(ccp(1, 0))
    numTTFLabel:setPosition(ccp(37, -38))
    node:addChild(numTTFLabel, 3, mItemTag.NumLabel)

    return node
end


------------------------------------------------------------------
function KingPowerAniBase:addRewardClick(parentNode, node, tipsData)
    local menu = CCMenu:create()
    local function itemSelector()
        GameUtil:showTip(node, tipsData)
    end
    local item = CCMenuItemImage:create("common_ht_propK_bai.png", "common_ht_propK_bai.png")
    item:registerScriptTapHandler(itemSelector)
    menu:addChild(item)
    item:setPosition(ccp(0, 0))
    parentNode:addChild(menu)
    menu:setPosition(ccp(0, 0))
end 

------------------------------------------------------------------


function KingPowerAniPage_setFirst(score, reward, haremData)
    thisActivityInfo.score = score or 1
    thisActivityInfo.reward = reward or { }
    thisActivityInfo.haremData = haremData or { }
end

local CommonPage = require("CommonPage");
local KingPowerAniPage = CommonPage.newSub(KingPowerAniBase, thisPageName, option)
return KingPowerAniPage
