----------------------------------------------------------------------------------
--[[
	星占师
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity2_pb = require("Activity2_pb")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "TreasureRaiderPageNew"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local alreadyShowReward = { }-- 界面上已经显示的奖励
local alreadyShowReward_multiple = { }-- 界面上已经显示的奖励
local _MercenaryInfo = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = { }
local COUNT_LIMIT = 10
local mConstCount = 0       -- 必中多少碎片
local ReqAnim =
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = { }
}

local opcodes = {
    NEW_TREASURE_RAIDER_INFO_S = HP_pb.NEW_TREASURE_RAIDER_INFO_S,
    NEW_TREASURE_RAIDER_SEARCH_S = HP_pb.NEW_TREASURE_RAIDER_SEARCH_S,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    RELEASE_UR_INFO_C = HP_pb.RELEASE_UR_INFO_C,
    RELEASE_UR_INFO_S = HP_pb.RELEASE_UR_INFO_S,
    RELEASE_UR_DRAW_C = HP_pb.RELEASE_UR_DRAW_C,
    RELEASE_UR_DRAW_S = HP_pb.RELEASE_UR_DRAW_S,
}

local option = {
    ccbiFile = "Act_TimeLimitGachaContent.ccbi",
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

local TreasureRaiderBaseNew = { }
TreasureRaiderBaseNew.timerName = "Activity_New_TreasureRaider"
TreasureRaiderBaseNew.timerLabel = "mTanabataCD"
TreasureRaiderBaseNew.timerKeyBuff = "Activity_Timer_Key_Buff"
TreasureRaiderBaseNew.timerFreeCD = "Activity_Timer_Free_CD"

local multiple_x2 = 2;
local multiple_x5 = 5;
local TreasureRaiderDataHelper = {
    RemainTime = 0,
    showItems = { },
    freeTreasureTimes = 0,
    leftTreasureTimes = 0,
    onceCostGold = 0,
    tenCostGold = 0,
    TreasureRaiderConfig = nil,
}
local bIsSearchBtn = false -- 点击按钮触发的动画,还是协议遇到宝箱触发的动画
local bIsMeetBox = false -- 是否遇到奇遇宝箱
local nSearchTimes = 1 -- 寻宝次数

local mOnceDiscount = 1
local mTheDiscount = 1
-------------------------- logic method ------------------------------------------
function TreasureRaiderBaseNew:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if TreasureRaiderDataHelper.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd");
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr });
            NodeHelper:setNodesVisible(container, {
                mFreeNodeVar = false,
                mCostNodeVar = true,
                mSuitFreeTime = false,
                mNoBuf = false
            } );
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
    NodeHelper:setStringForLabel(container, { [self.timerLabel] = common:getLanguageString("@SurplusTimeFishing") .. timeStr });
    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd");
        PageManager.popPage(thisPageName)
    end

    if TimeCalculator:getInstance():hasKey(self.timerFreeCD) then
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.timerFreeCD);
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false);
            NodeHelper:setStringForLabel(container, { mSuitFreeTime = common:getLanguageString("@SuitShootFreeOneTime", timeStr) });
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
            NodeHelper:setNodesVisible(container, {
                mFreeNodeVar = true,
                mCostNodeVar = false,
                mSuitFreeTime = false,
            } )
        end
    end

    if TimeCalculator:getInstance():hasKey(self.timerKeyBuff) then
        local timerKeyBuff = TimeCalculator:getInstance():getTimeLeft(self.timerKeyBuff);
        if timerKeyBuff > 0 then
            timeStr = common:second2DateString(timerKeyBuff, false);
            NodeHelper:setStringForLabel(container, { mBuffCD = common:getLanguageString("@ActivityDays") .. timeStr });

        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff);
            NodeHelper:setStringForLabel(container, { mBuffCD = "" });
            -- NodeHelper:setNodesVisible(container, { mNoBuff = false ,mNoBuffTips = true})

            NodeHelper:setNodesVisible(container, { mNoBuff = false, mNoBuffTips = false })
            -- 去掉buff
        end
    end
end

-------------------------- state method -------------------------------------------
function TreasureRaiderBaseNew:getPageInfo(container)
    alreadyShowReward = { }
    -- 界面上已经显示的奖励
    alreadyShowReward_multiple = { }
    -- 界面上已经显示的奖励
    MercenaryCfg = ConfigManager.getRoleCfg()
    if GameConfig.NowSelctActivityId == Const_pb.NEW_TREASURE_RAIDER then
        _MercenaryInfo = ConfigManager.getSummerMercenaryCfg()  --6/16新增為三隻角色
        TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getNewTresureRaiderRewardCfg() or { }
        common:sendEmptyPacket(HP_pb.NEW_TREASURE_RAIDER_INFO_C)
    elseif GameConfig.NowSelctActivityId == Const_pb.RELEASE_UR then
        _MercenaryInfo = ConfigManager.getReleaseURdrawMercenaryCfg()[1]
        TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getReleaseURdrawRewardCfg() or { }
        common:sendEmptyPacket(HP_pb.RELEASE_UR_INFO_C)
    end
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end

function TreasureRaiderBaseNew:onHand(container, eventName)
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

function TreasureRaiderBaseNew:onEnter(parentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    --local GuideManager = require("Guide.GuideManager")
    --GuideManager.PageContainerRef["TreasureRaiderBaseNew"] = container

    NodeHelper:setStringForLabel(container, { mSuitFreeTime = "", mActDouble = "" })

    --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineParentNode"), -1)
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    local rootNode = container:getVarNode("mRootNode")
    NodeHelper:autoAdjustResetNodePosition(rootNode, 0.5)
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mTopNode"), -0.5)
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"), 0.5)

    NodeHelper:setNodesVisible(container, { mBtmNode = true })
    luaCreat_TreasureRaiderPageNew(container)
    self:registerPacket(parentContainer)
    self:getPageInfo(parentContainer)
    -- TreasureRaiderDataHelper.TreasureRaiderConfig =  ConfigManager.getNewTresureRaiderRewardCfg()
    NodeHelper:setNodesVisible(container, { mDoubleNode = true })

    -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
    local scale = NodeHelper:getAdjustBgScale(1)
    if scale < 1 then
        -- NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    end

    NodeHelper:setStringForLabel(container, {
        mCostTxt1 = common:getLanguageString("@TROneTime"),
        mCostTxt2 = common:getLanguageString("@TRTenTimes")
    } )
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = { }
    }
    self:ClearALreadyShowReward()
    self:HideRewardNode(parentContainer)
    for i = 1, #_MercenaryInfo do
        local varName = "mSpineNode" .. i
        local spineNode = container:getVarNode(varName);
        local spinePosOffset = _MercenaryInfo[i].offset
        local spineScale = _MercenaryInfo[i].scale

        -- local spinePosOffset = "-50,400"
        -- local spineScale = 1.2

        local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo[i].itemId]
    	-- if spineNode and roldData then
    	--     spineNode:removeAllChildren();
    	--     local dataSpine = common:split((roldData.spine), ",")
    	--     local spinePath, spineName = dataSpine[1], dataSpine[2]
    	--     local spine = SpineContainer:create(spinePath, spineName)
    	--     local spineToNode = tolua.cast(spine, "CCNode");
    	--     spineToNode:setScale(spineScale)
    	--     spineNode:addChild(spineToNode);
   	 --     spine:runAnimation(1, "Stand", -1);
   	 --
   	 --     local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
   	 --     NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
   	 --
   	 --     local scale = NodeHelper:getScaleProportion()
   	 --     if scale > 1 then
    	--         --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineBg"), 0.5)
    	--     elseif scale < 1 then
    	--         NodeHelper:setNodeScale(self.container, "mSpineNode" .. i, scale, scale)
    	--         --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"))
    	--     end
    	--
    	--
    	-- end
        NodeHelper:setSpriteImage(container, { mNamePic = MercenaryCfg[_MercenaryInfo[i].itemId].namePic })

        NodeHelper:setSpriteImage(container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[_MercenaryInfo[i].itemId].quality] })
    end


    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

    --關閉顯示剩餘時間
    NodeHelper:setNodeVisible(container:getVarNode("mTanabataCD"), false)

    --開啟背景顯示
    GashaponPage_setBgVisible(true)

    return container
end

function TreasureRaiderBaseNew:onIllustatedOpen(container)
    --    require("SuitDisplayPage")
    --    SuitDisplayPageBase_setMercenaryEquip(3)
    --    PageManager.pushPage("SuitDisplayPage");
    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(_MercenaryInfo[1].itemId)
end
function TreasureRaiderBaseNew:HideRewardNode(container)
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

function TreasureRaiderBaseNew:refreshRewardNode(container, index)
    local visibleMap = { }
    visibleMap["mRewardNode" .. index] = true

    local reward = alreadyShowReward[index];
    local multiple = alreadyShowReward_multiple[index];
    local rewardItems = { }
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type = tonumber(_type),
        itemId = tonumber(_id),
        count = tonumber(_count),
    } );
    visibleMap["m2Time" .. index] = multiple == multiple_x2
    visibleMap["m5Time" .. index] = multiple == multiple_x5
    NodeHelper:fillRewardItemWithParams(container, rewardItems, 1, { startIndex = index, frameNode = "mHand", countNode = "mNumber" })
    NodeHelper:setNodesVisible(container, visibleMap)
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0" .. Aniname
    end

    container:runAnimation("ItemAni_" .. Aniname)
end

function TreasureRaiderBaseNew:ClearALreadyShowReward()
    alreadyShowReward = { }
    alreadyShowReward_multiple = { }
end

function TreasureRaiderBaseNew:refreshPage(container)
    if TreasureRaiderDataHelper.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TreasureRaiderDataHelper.RemainTime)
    end
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerFreeCD, TreasureRaiderDataHelper.freeTreasureTimes)
    end
    if TreasureRaiderDataHelper.leftBuffTimes > 0 then

        NodeHelper:setNodesVisible(container, {
            mTimes2 = TreasureRaiderDataHelper.buf_multiple == multiple_x2,
            mTimes5 = TreasureRaiderDataHelper.buf_multiple == multiple_x5,
        } )
        TimeCalculator:getInstance():createTimeCalcultor(self.timerKeyBuff, TreasureRaiderDataHelper.leftBuffTimes)
    else

    end
    -- local freeTimesStr = common:getLanguageString("@TreasureRaiderFreeOneTime", TreasureRaiderDataHelper.freeTreasureTimes)
    UserInfo.syncPlayerInfo()
    local label2Str = {
        mCostNum = TreasureRaiderDataHelper.onceCostGold * mOnceDiscount,
        mDiamondText = TreasureRaiderDataHelper.tenCostGold * mTheDiscount,
        -- mSuitFreeTime 			= freeTimesStr,
        mDiamondNum = UserInfo.playerInfo.gold,
        mSuitTenTime = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes--[[,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount]]) --拿掉角色&碎片數量
    }
    NodeHelper:setStringForLabel(container, label2Str)


    NodeHelper:setLabelOneByOne(container, "mSearchTimesTitle", "mSearchTimes")
    NodeHelper:setLabelOneByOne(container, "mFreeNumTitle", "mFreeNum")

    NodeHelper:setNodesVisible(container, {
        mFreeNodeVar = TreasureRaiderDataHelper.freeTreasureTimes <= 0,
        mCostNodeVar = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        mSuitFreeTime = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        -- mNoBuff = TreasureRaiderDataHelper.leftBuffTimes > 0,
        mNoBuff = false,
        -- 去掉buff
        -- mNoBuffTips = TreasureRaiderDataHelper.leftBuffTimes <= 0,
        mNoBuffTips = false-- 去掉buff

    } )

    ---------------------------------------------
    NodeHelper:setNodesVisible(container, { mOnceDiscountImage = mOnceDiscount < 1 })
    NodeHelper:setNodesVisible(container, { mTenDiscountImage = mTheDiscount < 1 })
    if TreasureRaiderDataHelper.freeTreasureTimes <= 0 then
        NodeHelper:setNodesVisible(container, { mOnceDiscountImage = false })
    end
    ---------------------------------------------
end

function TreasureRaiderBaseNew:onExecute(parentContainer)
    self:onTimer(self.container)
end

-- 更新佣兵碎片数量
function TreasureRaiderBaseNew:updateMercenaryNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt"--[[, MercenaryCfg[_MercenaryInfo.itemId].name]]) --[[.. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount]] });   --拿掉角色&碎片數量
            break;
        end
    end
end

-- 收包
function TreasureRaiderBaseNew:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber();
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S then
        msg = Activity2_pb.HPNewTreasureRaiderInfoSync()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    elseif opcode == HP_pb.RELEASE_UR_INFO_S or opcode == HP_pb.RELEASE_UR_DRAW_S then
        msg = Activity3_pb.ReleaseURInfo()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    end
end

function TreasureRaiderBaseNew:updateData(parentContainer, opcode, msg)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })

    TreasureRaiderDataHelper.RemainTime = msg.leftTime or 0
    TreasureRaiderDataHelper.showItems = msg.items or { }
    TreasureRaiderDataHelper.freeTreasureTimes = msg.freeCD or 0
    TreasureRaiderDataHelper.onceCostGold = msg.onceCostGold or 0
    TreasureRaiderDataHelper.tenCostGold = msg.tenCostGold or 0
    TreasureRaiderDataHelper.buf_multiple = msg.buf_multiple or 1
    TreasureRaiderDataHelper.leftBuffTimes = msg.leftBuffTimes or 0
    TreasureRaiderDataHelper.leftAwardTimes = msg.leftAwardTimes or 10
    if opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.RELEASE_UR_INFO_S then
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
            -- bIsMeetBox = true
            -- container:runAnimation("OpenChest")
        end
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S or opcode == HP_pb.RELEASE_UR_DRAW_S then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
            bIsMeetBox = true
        end
        ReqAnim.showNewReward = { }
        ReqAnim.showNewReward = msg.reward

        ------------------------------------------
        self:pushRewardPage()
        ------------------------------------------

        --        local reward = msg.reward
        --        local beginIndex = 1;
        --        if (#alreadyShowReward + #reward) > COUNT_LIMIT then
        --            self:HideRewardNode(self.container);
        --            self:ClearALreadyShowReward()
        --        else
        --            beginIndex = #alreadyShowReward + 1;
        --        end
        --        for i = 1, #reward do
        --            alreadyShowReward[#alreadyShowReward + 1] = reward[i]
        --            alreadyShowReward_multiple[#alreadyShowReward_multiple + 1] = msg.reward_multiple[i]
        --        end
        --        NodeHelper:setNodesVisible(self.container, { mRewardBtn = false, mIllustatedOpen = false })
        --        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false);
        --        NodeHelper:setMenuItemEnabled(self.container, "mFree", false);
        --        ReqAnim.isAnimationRuning = true
        --        self:refreshRewardNode(self.container, beginIndex);
    end
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end
    self:refreshPage(self.container)
end


function TreasureRaiderBaseNew:pushRewardPage()

    local onceGold = TreasureRaiderDataHelper.onceCostGold
    local tenGold = TreasureRaiderDataHelper.tenCostGold
    local reward = ReqAnim.showNewReward
    local isFree = TreasureRaiderDataHelper.freeTreasureTimes <= 0
    local freeCount = 0
    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", false, TreasureRaiderBaseNew.onOnceSearch, TreasureRaiderBaseNew.onTenSearch, function()
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

        end , mOnceDiscount, mTheDiscount)
    else
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", true, TreasureRaiderBaseNew.onOnceSearch, TreasureRaiderBaseNew.onTenSearch, nil, mOnceDiscount, mTheDiscount)
    end
end


function TreasureRaiderBaseNew:onExit(parentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff);
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
    local spineNode = self.container:getVarNode("mSpine");
    if spineNode then
        spineNode:removeAllChildren();
    end
    self:removePacket(parentContainer)
    MercenaryCfg = nil
    onUnload(thisPageName, self.container)

    --關閉背景顯示
    GashaponPage_setBgVisible(false)
end

function TreasureRaiderBaseNew:onAnimationDone(container)
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
                -- 评价提示
            end

        end
    end
end
----------------------------click client -------------------------------------------
function TreasureRaiderBaseNew:onOnceSearch(container)
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold * mOnceDiscount then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    if GameConfig.NowSelctActivityId == Const_pb.NEW_TREASURE_RAIDER then
        local msg = Activity2_pb.HPNewTreasureRaiderSearch()
        msg.searchTimes = 1
        common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH_C, msg)
    elseif GameConfig.NowSelctActivityId == Const_pb.RELEASE_UR then
        local msg = Activity3_pb.ReleaseURDraw()
        msg.times = 1
        common:sendPacket(HP_pb.RELEASE_UR_DRAW_C, msg)
    end
end

function TreasureRaiderBaseNew:onTenSearch(container)
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold * mTheDiscount
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end
    if GameConfig.NowSelctActivityId == Const_pb.NEW_TREASURE_RAIDER then
        local msg = Activity2_pb.HPNewTreasureRaiderSearch()
        msg.searchTimes = 10
        common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH_C, msg)
    elseif GameConfig.NowSelctActivityId == Const_pb.RELEASE_UR then
        local msg = Activity3_pb.ReleaseURDraw()
        msg.times = 10
        common:sendPacket(HP_pb.RELEASE_UR_DRAW_C, msg)
    end
end

function TreasureRaiderBaseNew:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function TreasureRaiderBaseNew:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function TreasureRaiderBaseNew:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEW_TREASURERAIDER);
end

function TreasureRaiderBaseNew:onRewardPreview(container)
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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_SSR_CHOUKA)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

function TreasureRaiderBaseNew:onBoxPreview(container)
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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "", "", GameConfig.HelpKey.HELP_SSR_CHOUKA)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

local CommonPage = require('CommonPage')
TreasureRaiderPageNew = CommonPage.newSub(TreasureRaiderBaseNew, thisPageName, option)

return TreasureRaiderPageNew