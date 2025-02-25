----------------------------------------------------------------------------------
--[[
	西施的祝福
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local TreasureRaiderDataHelper = require("Activity.TreasureRaiderDataHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "TreasureRaiderPage"

local alreadyShowReward = { }-- 界面上已经显示的奖励

local activitiId = 36;

local COUNT_LIMIT = 10

local ReqAnim =
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = { }
}

local opcodes = {
    TREASURE_RAIDER_INFO_S = HP_pb.TREASURE_RAIDER_INFO_S,
    TREASURE_RAIDER_SEARCH_S = HP_pb.TREASURE_RAIDER_SEARCH_S,
}

local option = {
    ccbiFile = "Act_TimeLimitTreasureRaiderContent.ccbi",
    handlerMap =
    {
        onReturnButton = "onClose",
        onHelp = "onHelp",
        onSearchOnce = "onOnceSearch",
        onSearchTen = "onTenSearch",
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",
        onBoxPreview = "onBoxPreview",
    },
}
for i = 1, 10 do
    option.handlerMap["onHand" .. i] = "onHand";
end

local TreasureRaiderBase = { }
TreasureRaiderBase.timerName = "Activity_TreasureRaider"
TreasureRaiderBase.timerLabel = "mTanabataCD"
TreasureRaiderBase.mTimeDownImage = nil
local bIsSearchBtn = false -- 点击按钮触发的动画,还是协议遇到宝箱触发的动画
local bIsMeetBox = false -- 是否遇到奇遇宝箱
local nSearchTimes = 1 -- 寻宝次数
-------------------------- logic method ------------------------------------------
function TreasureRaiderBase:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if TreasureRaiderDataHelper.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd");
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr });
        elseif TreasureRaiderDataHelper.RemainTime < 0 then
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = "" });
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);

    if remainTime + 1 > TreasureRaiderDataHelper.RemainTime then
        return;
    end

    local timeStr = common:second2DateString(remainTime, false);

    -- common:getLanguageString("@SurplusTimeFishing") ..
    NodeHelper:setStringForLabel(container, { [self.timerLabel] = timeStr });

    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd");
        PageManager.popPage(thisPageName)
    end

end

-------------------------- state method -------------------------------------------
function TreasureRaiderBase:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.TREASURE_RAIDER_INFO_C)
end

function TreasureRaiderBase:onHand(container, eventName)
    local index = tonumber(string.sub(eventName, 7, string.len(eventName)))
    local _type, _id, _count = unpack(common:split(alreadyShowReward[index], "_"));
    local items = { }
    table.insert(items, {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count)
    } );
    GameUtil:showTip(container:getVarNode('mPic' .. index), items[1])

end

function TreasureRaiderBase:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    local s9Bg = container:getVarScale9Sprite("mS9_1")
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    local spriteBg = container:getVarNode("mSpriteBgNode")
    NodeHelper:autoAdjustResetNodePosition(spriteBg, 0.5)

    luaCreat_TreasureRaiderPage(container)
    self:registerPacket(parentContainer)
    self:getPageInfo(parentContainer)

    NodeHelper:setNodesVisible(container, { mDoubleNode = true })

    -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),-0.5)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mSpineNode")) 	
    NodeHelper:setStringForLabel(container, {
        mCostTxt1 = common:getLanguageString("@TROneTime"),
        mCostTxt2 = common:getLanguageString("@TRTenTimes")
    } )

    NodeHelper:setNodesVisible(self.container, { mCDNode = false })
    NodeHelper:setNodesVisible(self.container, { mBtmNode = false })
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = { }
    }
    self:ClearALreadyShowReward()
    self:HideRewardNode(parentContainer)
    self:initSpine(self.container)
    local bgScale = NodeHelper:getAdjustBgScale(1)
    if bgScale < 1 then bgScale = 1 end
    NodeHelper:setNodeScale(container, "mBG", bgScale + 0.2, bgScale + 0.2)
    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mIllustatedbtn = false })
    end

    TreasureRaiderBase.mTimeDownImage = container:getVarSprite("mTimeDownImage")

    return container
end

function TreasureRaiderBase:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode")

    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[181]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
       --local spine = SpineContainer:create(spinePath, spineName)
       --local spineToNode = tolua.cast(spine, "CCNode")
       --spineNode:addChild(spineToNode)
       --spineToNode:setTag(10086)
       --spine:runAnimation(1, "Stand", -1)

       --local spinePosOffset = "0,0"
       --local spineScale = 1.3
       --local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
       --NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
       --spineToNode:setScale(spineScale)
        -- NodeHelper:autoAdjustResetNodePosition(spineNode:getParent())
    end
end

function TreasureRaiderBase:onIllustatedOpen(container)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setMercenaryEquip(3)
    PageManager.pushPage("SuitDisplayPage");
end
function TreasureRaiderBase:HideRewardNode(container)
    local visibleMap = { }
    for i = 1, 10 do
        visibleMap["mRewardNode" .. i] = false
    end

    local aniShadeVisible = false
    if #alreadyShowReward > 0 then
        for i = 1, #alreadyShowReward do
            visibleMap["mRewardNode" .. i] = true
            local reward = alreadyShowReward[i];
            local rewardItems = { }
            local _type, _id, _count = unpack(common:split(reward, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
            } );
            NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = i, frameNode = "mHand", countNode = "mNumber" })
        end
        aniShadeVisible = true
        -- container:runAnimation("ShowItem")
    end
    NodeHelper:setNodesVisible(container, visibleMap)
end

function TreasureRaiderBase:refreshRewardNode(container, index)
    local visibleMap = { }
    visibleMap["mRewardNode" .. index] = true
    local reward = alreadyShowReward[index];
    local rewardItems = { }
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count),
    } );
    NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = index, frameNode = "mHand", countNode = "mNumber" })
    NodeHelper:setNodesVisible(container, visibleMap)
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0" .. Aniname
    end

    container:runAnimation("ItemAni_" .. Aniname)
end

function TreasureRaiderBase:ClearALreadyShowReward()
    alreadyShowReward = { }
end

function TreasureRaiderBase:refreshPage(container)
    if TreasureRaiderDataHelper.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TreasureRaiderDataHelper.RemainTime)
    end

    local freeTimesStr = common:getLanguageString("@TreasureRaiderFreeOneTime", TreasureRaiderDataHelper.freeTreasureTimes)
    UserInfo.syncPlayerInfo()
    local label2Str = {
        mCostNum = TreasureRaiderDataHelper.onceCostGold,
        mDiamondText = TreasureRaiderDataHelper.tenCostGold,
        mSuitFreeTime = freeTimesStr,
        mDiamondNum = UserInfo.playerInfo.gold,
        mLastMustText = common:getLanguageString("@NeedXTimesGetShenlishi" , 10 - (TreasureRaiderDataHelper.totalTimes % 10))
    }
    NodeHelper:setStringForLabel(container, label2Str)

    NodeHelper:setLabelOneByOne(container, "mSearchTimesTitle", "mSearchTimes")
    NodeHelper:setLabelOneByOne(container, "mFreeNumTitle", "mFreeNum")

    NodeHelper:setNodesVisible(container, { mFreeText = TreasureRaiderDataHelper.freeTreasureTimes > 0, mCostNodeVar = TreasureRaiderDataHelper.freeTreasureTimes <= 0 })

    NodeHelper:setStringForLabel(container, { mFreeText = common:getLanguageString("@TreasureRaiderFreeText") })

end

function TreasureRaiderBase:onExecute(parentContainer)
    self:onTimer(self.container)
end

-- 收包
function TreasureRaiderBase:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    if opcode ~= HP_pb.TREASURE_RAIDER_INFO_S and opcode ~= HP_pb.TREASURE_RAIDER_SEARCH_S then
        return
    end
    local msg = Activity_pb.HPTreasureRaiderInfoSync()
    msg:ParseFromString(msgBuff)

    TreasureRaiderDataHelper.RemainTime = msg.leftTime or 0
    TreasureRaiderDataHelper.showItems = msg.items or { }
    TreasureRaiderDataHelper.freeTreasureTimes = msg.freeTreasureTimes or 0
    TreasureRaiderDataHelper.onceCostGold = msg.onceCostGold or 0
    TreasureRaiderDataHelper.tenCostGold = msg.tenCostGold or 0
    TreasureRaiderDataHelper.totalTimes = msg.totalTimes or 0
    dump(TreasureRaiderDataHelper)
    if opcode == HP_pb.TREASURE_RAIDER_INFO_S then

        NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
            -- bIsMeetBox = true
            -- container:runAnimation("OpenChest")
        end
    elseif opcode == HP_pb.TREASURE_RAIDER_SEARCH_S then
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
            bIsMeetBox = true
        end
        ReqAnim.showNewReward = { }
        ReqAnim.showNewReward = msg.reward
        local reward = msg.reward


        ------------------------------------------
        self:pushRewardPage()
        ------------------------------------------

        --        local beginIndex = 1;
        --        if (#alreadyShowReward + #reward) > COUNT_LIMIT then
        --            self:HideRewardNode(self.container);
        --            self:ClearALreadyShowReward()
        --        else
        --            beginIndex = #alreadyShowReward + 1;
        --        end
        --        for i = 1, #reward do
        --            alreadyShowReward[#alreadyShowReward + 1] = reward[i]
        --        end
        --        NodeHelper:setNodesVisible(self.container, { mRewardBtn = false, mIllustatedOpen = false })
        --        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false);
        --        NodeHelper:setMenuItemEnabled(self.container, "mFree", false);
        --        ReqAnim.isAnimationRuning = true
        --        self:refreshRewardNode(self.container, beginIndex);
    end
    if TreasureRaiderDataHelper.freeTreasureTimes <= 0 then
        ActivityInfo.changeActivityNotice(Const_pb.TREASURE_RAIDER)
    end
    self:refreshPage(self.container)
end

function TreasureRaiderBase:pushRewardPage()
    local onceGold = TreasureRaiderDataHelper.onceCostGold
    local tenGold = TreasureRaiderDataHelper.tenCostGold
    local reward = ReqAnim.showNewReward
    local isFree = TreasureRaiderDataHelper.freeTreasureTimes > 0
    local freeCount = TreasureRaiderDataHelper.freeTreasureTimes

    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", false, TreasureRaiderBase.onOnceSearch, TreasureRaiderBase.onTenSearch, TreasureRaiderBase.rewardAniEndCallFunc)
    else
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", true, TreasureRaiderBase.onOnceSearch, TreasureRaiderBase.onTenSearch, TreasureRaiderBase.rewardAniEndCallFunc)
    end
end

function TreasureRaiderBase:rewardAniEndCallFunc()
    if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
        local rewardItems = common:parseItemWithComma(TreasureRaiderDataHelper.showItems)
        if rewardItems and #rewardItems > 0 then
            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm(rewardItems, true, 2, function()
                if #ReqAnim.showNewReward == 10 then
                    PageManager.showComment(true)
                    -- 评价提示
                end
            end )
            PageManager.pushPage("CommonRewardPage")
        end
    else
        if #ReqAnim.showNewReward == 10 then
            PageManager.showComment(true)
            -- 评价提示
        end
    end
end

function TreasureRaiderBase:onExit(parentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    self:removePacket(parentContainer)
    onUnload(thisPageName, self.container)


    TreasureRaiderBase.mTimeDownImage = nil

end

function TreasureRaiderBase:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if string.sub(animationName, 1, 8) == "ItemAni_" then
        local index = tonumber(string.sub(animationName, -2))
        if index < #alreadyShowReward then
            self:refreshRewardNode(container, index + 1)
        else
            -- 播放完毕
            NodeHelper:setNodesVisible(self.container, { mRewardBtn = true, mIllustatedOpen = true })
            NodeHelper:setMenuItemEnabled(self.container, "mDiamond", true);
            NodeHelper:setMenuItemEnabled(self.container, "mFree", true);
            --
            ReqAnim.isAnimationRuning = false;
            if bIsMeetBox then
                bIsMeetBox = false
                local rewardItems = common:parseItemWithComma(TreasureRaiderDataHelper.showItems)
                if rewardItems and #rewardItems > 0 then
                    local CommonRewardPage = require("CommonRewardPage")
                    CommonRewardPageBase_setPageParm(rewardItems, true, 2)
                    PageManager.pushPage("CommonRewardPage")
                end
            end

            if #ReqAnim.showNewReward == 10 then
                PageManager.showComment(true)
            end
        end
    end
end
----------------------------click client -------------------------------------------
function TreasureRaiderBase:onOnceSearch(container)
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes <= 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
        common:rechargePageFlag("TreasureRaiderBase")
        return
    end
    local msg = Activity_pb.HPTreasureRaiderSearch()
    msg.searchTimes = 1
    common:sendPacket(HP_pb.TREASURE_RAIDER_SEARCH_C, msg)
end

function TreasureRaiderBase:onTenSearch(container)
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold - TreasureRaiderDataHelper.freeTreasureTimes * TreasureRaiderDataHelper.onceCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBase")
        return
    end
    local msg = Activity_pb.HPTreasureRaiderSearch()
    msg.searchTimes = 10
    common:sendPacket(HP_pb.TREASURE_RAIDER_SEARCH_C, msg)
end

function TreasureRaiderBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function TreasureRaiderBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function TreasureRaiderBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_TREASURERAIDER);
end

function TreasureRaiderBase:onRewardPreview(container)
    require("NewSnowPreviewRewardPage")
    local TreasureCfg = TreasureRaiderDataHelper.TreasureRaiderConfig
    local commonRewardItems = { }
    local luckyRewardItems = { }
    if TreasureCfg ~= nil then
        for _, item in ipairs(TreasureCfg) do
            if item.type == 1 then
                table.insert(commonRewardItems, {
                    type = tonumber(item.needRewardValue.type),
                    itemId = tonumber(item.needRewardValue.itemId),
                    count = tonumber(item.needRewardValue.count)
                } );
            else
                table.insert(luckyRewardItems, {
                    type = tonumber(item.needRewardValue.type),
                    itemId = tonumber(item.needRewardValue.itemId),
                    count = tonumber(item.needRewardValue.count)
                } );
            end
        end
    end
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLTreasureRaiderInfoTxt1", "@ACTTLTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_QIFUSHEN_REWARD)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

function TreasureRaiderBase:onBoxPreview(container)
    require("NewSnowPreviewRewardPage")
    local TreasureCfg = TreasureRaiderDataHelper.TreasureRaiderConfig
    local commonRewardItems = { }
    local luckyRewardItems = { }
    if TreasureCfg ~= nil then
        for _, item in ipairs(TreasureCfg) do
            if item.type == 1 then
                table.insert(commonRewardItems, {
                    type = tonumber(item.needRewardValue.type),
                    itemId = tonumber(item.needRewardValue.itemId),
                    count = tonumber(item.needRewardValue.count)
                } );
            else
                table.insert(luckyRewardItems, {
                    type = tonumber(item.needRewardValue.type),
                    itemId = tonumber(item.needRewardValue.itemId),
                    count = tonumber(item.needRewardValue.count)
                } );
            end
        end
    end
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "", "", GameConfig.HelpKey.HELP_QIFUSHEN_REWARD)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

local CommonPage = require('CommonPage')
TreasureRaiderPage = CommonPage.newSub(TreasureRaiderBase, thisPageName, option)

return TreasureRaiderPage