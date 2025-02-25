----------------------------------------------------------------------------------
--[[
	ssr抽卡   活动id 120
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity2_pb = require("Activity2_pb")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActTimeLimit_120"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local _MercenaryInfo = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = { }
local mConstCount = 0       -- 必中多少碎片
local ReqAnim =
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = { }
}

local opcodes = {
    NEW_TREASURE_RAIDER_INFO3_S = HP_pb.NEW_TREASURE_RAIDER_INFO3_S,
    NEW_TREASURE_RAIDER_SEARCH3_S = HP_pb.NEW_TREASURE_RAIDER_SEARCH3_S,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    RELEASE_UR_INFO_C = HP_pb.RELEASE_UR_INFO_C,
    RELEASE_UR_INFO_S = HP_pb.RELEASE_UR_INFO_S,
    RELEASE_UR_DRAW_C = HP_pb.RELEASE_UR_DRAW_C,
    RELEASE_UR_DRAW_S = HP_pb.RELEASE_UR_DRAW_S,
}
local mItemNode = { }
local mItemNodePosition = { }
local mStartPosition = nil
local MOVE_TIME_MAX = 0.5
local MOVE_TIME_MIN = 0.1
local mMoveTime = 1.5
local option = {
    ccbiFile = "Act_TimeLimit_120.ccbi",
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

local ActTimeLimit_120 = { }
ActTimeLimit_120.timerName = "Activity_120_TreasureRaider"
ActTimeLimit_120.timerLabel = "mTanabataCD"
ActTimeLimit_120.timerKeyBuff = "Activity_Timer_Key_Buff_120"
ActTimeLimit_120.timerFreeCD = "Activity_Timer_Free_CD_120"

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



local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
    Mask = 5000,
}

local mRoundNum = 8
local mCurrentRoundNum
local mMoveSpeedStage = {
    addStage = 0,
    reduceStage = 1,
    endStage = 2
}
local mMoveStage = mMoveSpeedStage.addStage

local mRollItemRewardData = nil
local mCurrentRoundNum = 0
local mItemMoveState = { }
local mIsCanStop = false
local mIsRunAction = false
local mIsActionProcess = false
local mLightingSprite = nil
local mLightingSpriteIndex = 0
local mAniMoveNodeInitPosition = nil
local mAniMoveNode = nil
-------------------------- logic method ------------------------------------------
function ActTimeLimit_120:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if TreasureRaiderDataHelper.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd");
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr });
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
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
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.timerFreeCD)
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false)
            NodeHelper:setStringForLabel(container, { mSuitFreeTime = common:getLanguageString("@SuitShootFreeOneTime", timeStr) })
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
            NodeHelper:setNodesVisible(container, {
                mFreeText = true,
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
function ActTimeLimit_120:getPageInfo(container)
    MercenaryCfg = ConfigManager.getRoleCfg()
    _MercenaryInfo = ConfigManager.getSummerMercenary120Cfg()[1]
    TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getNewTresureRaiderReward120Cfg() or { }
    common:sendEmptyPacket(HP_pb.NEW_TREASURE_RAIDER_INFO3_C)
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end

function ActTimeLimit_120:onEnter(parentContainer)
    math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container

    NodeHelper:setStringForLabel(container, { mSuitFreeTime = "", mActDouble = "" })

    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mAniNode"))
    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    NodeHelper:setNodesVisible(container, { mBtmNode = false })
    NodeHelper:setNodesVisible(container, { mAniNode = false })
    luaCreat_ActTimeLimit_120(container)
    self:registerPacket(parentContainer)
    self:getPageInfo(parentContainer)
    -- TreasureRaiderDataHelper.TreasureRaiderConfig =  ConfigManager.getNewTresureRaiderRewardCfg()
    NodeHelper:setNodesVisible(container, { mDoubleNode = true })

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

    local spineNode = container:getVarNode("mSpineNode");
    local spinePosOffset = _MercenaryInfo.offset
    local spineScale = _MercenaryInfo.scale

    -- local spinePosOffset = "30,-50"
    -- local spineScale = 0.6

    local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo.itemId]
    if spineNode and roldData then
        spineNode:removeAllChildren();
        local dataSpine = common:split((roldData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");
        spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);

        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

--        local scale = NodeHelper:getScaleProportion()
--        if scale > 1 then
--            -- 适配动画
--            NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
--            local mSpineBg = container:getVarSprite("mSpineBg")
--            if mSpineBg then
--                NodeHelper:autoAdjustResetNodePosition(mSpineBg, 0.5)
--            end
--        end


        local scale = NodeHelper:getScaleProportion()
        if scale > 1 then
            NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
            NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mSpineBg"), 0.5)
        elseif scale < 1 then
            NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
            -- NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"))
        end

    end


    NodeHelper:setSpriteImage(container, { mNamePic = MercenaryCfg[_MercenaryInfo.itemId].namePic })

    NodeHelper:setSpriteImage(container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[_MercenaryInfo.itemId].quality] })

    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

    mRollItemRewardData = self:formatRollItemData()
    mCurrentRoundNum = 0
    -- 移动节点
    mItemNode = { }
    mItemNodePosition = { }
    for i = 1, 4 do
        local node = container:getVarNode("mRewardNode_" .. i)
        node:removeAllChildren()
        if i == 3 then
            mStartPosition = node:getPosition()
        end
        local x, y = node:getPosition()
        table.insert(mItemNodePosition, ccp(x, y))
        local itemNode = self:createRewardItem()
        itemNode:setTag(tonumber(i .. i))
        local parent = node:getParent()
        parent:addChild(itemNode)
        local itemDataIndex = math.random(1, #mRollItemRewardData)
        ActTimeLimit_120:setRollItemData(itemNode, mRollItemRewardData[itemDataIndex])
        itemNode:setPosition(ccp(x, y))
        table.insert(mItemNode, itemNode)
        table.insert(mItemMoveState, false)
    end

    mRoundNum = math.random(12, 16)

    mLightingSpriteIndex = 0
    mLightingSprite = self.container:getVarSprite("mLightingSprite")
    self:runLightingSpriteAction()

    mAniMoveNode = self.container:getVarNode("mAniMoveNode")
    local x, y = mAniMoveNode:getPosition()
    mAniMoveNodeInitPosition = ccp(x, y)

    return container
end

function ActTimeLimit_120:runLightingSpriteAction()
    --
    if mLightingSprite == nil then
        return
    end

    local spritePath = ""
    if mLightingSpriteIndex % 2 == 0 then
        spritePath = "BG/ActivitySSR_120/AcivitySSR_120_Image_3.png"
    else
        spritePath = "BG/ActivitySSR_120/AcivitySSR_120_Image_4.png"
    end

    mLightingSprite:setTexture(spritePath)
    local delayTime = CCDelayTime:create(0.5)
    local CallFunc = CCCallFuncN:create( function()
        mLightingSpriteIndex = mLightingSpriteIndex + 1
        if mLightingSpriteIndex >= 1000000 then
            mLightingSpriteIndex = 0
        end
        self:runLightingSpriteAction()
    end )
    local Array = CCArray:create()
    Array:addObject(delayTime)
    Array:addObject(CallFunc)
    local Sequence = CCSequence:create(Array)
    mLightingSprite:runAction(Sequence)
end


function ActTimeLimit_120:formatRollItemData()
    local t = { }
    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        local data = ResManagerForLua:getResInfoByTypeAndId(v.needRewardValue.type, v.needRewardValue.itemId, v.needRewardValue.count)
        table.insert(t, data)
    end
    return t
end

function ActTimeLimit_120:checkItemMoveStage()
    local bl = true
    for k, v in pairs(mItemMoveState) do
        if not v then
            bl = v
            break
        end
    end
    return bl
end

function ActTimeLimit_120:recoveryItemMoveStage()
    mItemMoveState = { }
    for i = 1, 4 do
        table.insert(mItemMoveState, false)
    end

end

---------------------------------------------------------------------------------------------------------
function ActTimeLimit_120:tenAnimJumpAction()
    local targetNode = self.container:getVarNode("mMoveNodeTargetPosition")
    local x, y = targetNode:getPosition()
    mAniMoveNode:setPosition(mAniMoveNodeInitPosition)

    local Array = CCArray:create()

    local jumpTo = CCJumpTo:create(0.8, ccp(x, y), 400, 1)
    Array:addObject(jumpTo)

    local callFuncN = CCCallFuncN:create( function(node)
        self:tenAnimShakeAction()
    end )

    Array:addObject(callFuncN)
    local Sequence = CCSequence:create(Array)
    mAniMoveNode:runAction(Sequence)

end

function ActTimeLimit_120:tenAnimShakeAction()
    mAniMoveNode:stopAllActions()

    local SequenceArray = CCArray:create()

    for i = 1, 20 do
        if i % 2 == 0 then
            SequenceArray:addObject(CCMoveBy:create(0.05, ccp(20, 0)))
        else
            SequenceArray:addObject(CCMoveBy:create(0.05, ccp(-20, 0)))
        end
    end
    local sequence = CCSequence:create(SequenceArray)

    -- local moveBy_1 = CCMoveBy:create(0.05, ccp(20, 0))
    -- local moveBy_2 = CCMoveBy:create(0.05, ccp(-20, 0))
    -- local repeatAction = CCRepeatForever:create(CCSequence:createWithTwoActions(moveBy_1, moveBy_2))

    local callFuncN = CCCallFuncN:create( function(node)
        local mRandRewardNode = self.container:getVarNode("mRandRewardNode")
        mRandRewardNode:removeAllChildren()
        -- mRandRewardNode:removeAllChildrenWithCleanup(true)
        for i = 1, 20 do
            local itemNode = self:createRewardItem()
            mRandRewardNode:addChild(itemNode)
            local itemDataIndex = math.random(1, #mRollItemRewardData)
            ActTimeLimit_120:setRollItemData(itemNode, mRollItemRewardData[itemDataIndex])
            local x = 0
            local y = 0
            if i % 2 == 0 then
                x = math.random(-500, -100)
            else
                x = math.random(100, 500)
            end
            y = -300

            itemNode:setVisible(false)
            local delayTime = CCDelayTime:create((i - 1) * 0.05)
            local callFuncN = CCCallFuncN:create( function(node)
                if node then
                    node:setVisible(true)
                end
            end )
            local itemNodeJumpTo = CCJumpTo:create(0.5, ccp(x, y), math.random(150, 300), 1)
            local callFuncN_1 = CCCallFuncN:create( function(node)
                if node then
                    node:removeFromParentAndCleanup(true)
                end
            end )

            local array = CCArray:create()
            array:addObject(delayTime)
            array:addObject(callFuncN)
            array:addObject(itemNodeJumpTo)
            array:addObject(callFuncN_1)
            local sequence = CCSequence:create(array)
            itemNode:runAction(sequence)
        end
    end )

    local SpawnArray = CCArray:create()
    SpawnArray:addObject(sequence)
    SpawnArray:addObject(callFuncN)
    local SpawnAction = CCSpawn:create(SpawnArray)

    local array_1 = CCArray:create()
    array_1:addObject(SpawnAction)
    array_1:addObject(CCDelayTime:create(0.5))

    local callFuncN_1 = CCCallFuncN:create( function(node)
        local mRandRewardNode = self.container:getVarNode("mRandRewardNode")
        mRandRewardNode:removeAllChildren()
        -- mRandRewardNode:removeAllChildrenWithCleanup(true)
        self:pushRewardPage()
        mAniMoveNode:setPosition(mAniMoveNodeInitPosition)
    end )

    array_1:addObject(callFuncN_1)
    local Sequence = CCSequence:create(array_1)

    mAniMoveNode:runAction(Sequence)
end

---------------------------------------------------------------------------------------------------------


function ActTimeLimit_120:itemMoveBy()

    for k, v in pairs(mItemNode) do
        local tag = v:getTag()

        local itemTag = math.modf(tag / 10)
        local currentPosIndex = tag % 10
        local nextPosInde = currentPosIndex - 1
        if nextPosInde <= 0 then
            nextPosInde = 4
        end
        v:setTag(tonumber(itemTag .. nextPosInde))
        local moveBy = CCMoveBy:create(mMoveTime, ccp(-110, 0))
        local callFuncN = CCCallFuncN:create( function(itemNode)
            local tag = itemNode:getTag()

            local itemTag = math.modf(tag / 10)
            local currentPosIndex = tag % 10
            itemNode:setPosition(ccp(mItemNodePosition[currentPosIndex].x, mItemNodePosition[currentPosIndex].y))

            mItemMoveState[itemTag] = true

            if self:checkItemMoveStage() then
                -- 一圈
                self:recoveryItemMoveStage()
                mCurrentRoundNum = mCurrentRoundNum + 1
                if mCurrentRoundNum == mRoundNum then
                    mCurrentRoundNum = 0
                    mMoveStage = mMoveStage + 1
                end
                if mMoveStage == mMoveSpeedStage.addStage then
                    mMoveTime = mMoveTime - 0.1
                    if mMoveTime <= MOVE_TIME_MIN then
                        mMoveTime = MOVE_TIME_MIN
                    end
                elseif mMoveStage == mMoveSpeedStage.reduceStage then
                    mMoveTime = mMoveTime + 0.1
                    if mMoveTime >= MOVE_TIME_MAX then
                        mMoveTime = MOVE_TIME_MAX
                    end
                    mRoundNum = 4
                elseif mMoveStage == mMoveSpeedStage.endStage then
                    mMoveTime = MOVE_TIME_MAX
                end
                if mMoveStage == mMoveSpeedStage.endStage then
                    self:itemMoveEnd()
                else
                    for k, v in pairs(mItemNode) do
                        local tag = v:getTag()
                        local itemTag = math.modf(tag / 10)
                        local currentPosIndex = tag % 10
                        if currentPosIndex == 3 then
                            local itemDataIndex = math.random(1, #mRollItemRewardData)
                            ActTimeLimit_120:setRollItemData(v, mRollItemRewardData[itemDataIndex])
                        end
                    end
                    self:itemMoveBy(mMoveTime, mMoveStage)
                end
            end
        end )

        local Array = CCArray:create()
        Array:addObject(moveBy)
        Array:addObject(callFuncN)
        local Sequence = CCSequence:create(Array)
        v:runAction(Sequence)
    end
end



function ActTimeLimit_120:itemMoveEnd()
    for k, v in pairs(mItemNode) do
        local tag = v:getTag()

        local itemTag = math.modf(tag / 10)
        local currentPosIndex = tag % 10
        local nextPosInde = currentPosIndex - 1
        if nextPosInde <= 0 then
            nextPosInde = 4
        end
        v:setTag(tonumber(itemTag .. nextPosInde))
        local moveBy = CCMoveBy:create(mMoveTime, ccp(-110, 0))
        local callFuncN = CCCallFuncN:create( function(itemNode)
            local tag = itemNode:getTag()
            local itemTag = math.modf(tag / 10)
            local currentPosIndex = tag % 10
            mItemMoveState[itemTag] = true
            itemNode:setPosition(ccp(mItemNodePosition[currentPosIndex].x, mItemNodePosition[currentPosIndex].y))
            if self:checkItemMoveStage() then
                self:recoveryItemMoveStage()

                for k, v in pairs(mItemNode) do
                    local tag = v:getTag()
                    local itemTag = math.modf(tag / 10)
                    local currentPosIndex = tag % 10
                    if currentPosIndex == 3 then
                        if itemTag == 1 then
                            local info = ConfigManager.parseItemOnlyWithUnderline(ReqAnim.showNewReward[1])
                            local data = ResManagerForLua:getResInfoByTypeAndId(info.type, info.itemId, info.count)
                            ActTimeLimit_120:setRollItemData(v, data)
                            mIsCanStop = true
                        else
                            local itemDataIndex = math.random(1, #mRollItemRewardData)
                            ActTimeLimit_120:setRollItemData(v, mRollItemRewardData[itemDataIndex])
                        end
                    end

                end
                if mIsCanStop then
                    local tNode = mItemNode[1]
                    local tag = tNode:getTag()

                    local itemTag = math.modf(tag / 10)
                    local currentPosIndex = tag % 10
                    if itemTag == 1 and currentPosIndex == 1 then
                        self:pushRewardPage()
                    else
                        self:itemMoveEnd()
                    end
                else
                    self:itemMoveEnd()
                end
            end
        end )

        local Array = CCArray:create()
        Array:addObject(moveBy)
        Array:addObject(callFuncN)
        local Sequence = CCSequence:create(Array)
        v:runAction(Sequence)
    end
end



function ActTimeLimit_120:setRollItemData(item, data)
    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")
    local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")

    iconSprite:setTexture(data.icon)
    numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)
end


function ActTimeLimit_120:createRewardItem()
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    node:addChild(bgSprite, 0, 1000)

    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    node:addChild(iconSprite, 1, mItemTag.IconSprite)
    local qualitySprite = CCSprite:create("common_ht_propK_bai.png")
    node:addChild(qualitySprite, 3, mItemTag.QualitySprite)
    local numTTFLabel = CCLabelBMFont:create("x", "Lang/Font-HT-Button-White.fnt")
    numTTFLabel:setScale(0.55)
    numTTFLabel:setAnchorPoint(ccp(1, 0))
    numTTFLabel:setPosition(ccp(38, -38))
    node:addChild(numTTFLabel, 3, mItemTag.NumLabel)
    return node
end


function ActTimeLimit_120:onIllustatedOpen(container)
    if mIsRunAction then
        return
    end
    --    require("SuitDisplayPage")
    --    SuitDisplayPageBase_setMercenaryEquip(3)
    --    PageManager.pushPage("SuitDisplayPage");

    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(_MercenaryInfo.itemId)

end

function ActTimeLimit_120:refreshPage(container)
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
        mCostNum = TreasureRaiderDataHelper.onceCostGold,
        mDiamondText = TreasureRaiderDataHelper.tenCostGold,
        -- mSuitFreeTime 			= freeTimesStr,
        mDiamondNum = UserInfo.playerInfo.gold,
        mActDouble = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount)
    }
    NodeHelper:setStringForLabel(container, label2Str)


    NodeHelper:setLabelOneByOne(container, "mSearchTimesTitle", "mSearchTimes")
    NodeHelper:setLabelOneByOne(container, "mFreeNumTitle", "mFreeNum")

    NodeHelper:setNodesVisible(container, {
        mFreeText = TreasureRaiderDataHelper.freeTreasureTimes <= 0,
        mCostNodeVar = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        mSuitFreeTime = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        -- mNoBuff = TreasureRaiderDataHelper.leftBuffTimes > 0,
        mNoBuff = false,
        -- 去掉buff
        -- mNoBuffTips = TreasureRaiderDataHelper.leftBuffTimes <= 0,
        mNoBuffTips = false-- 去掉buff

    } )
end

function ActTimeLimit_120:onExecute(parentContainer)
    self:onTimer(self.container)
end

-- 更新佣兵碎片数量
function ActTimeLimit_120:updateMercenaryNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt", MercenaryCfg[_MercenaryInfo.itemId].name) .. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount });
            break;
        end
    end
end

-- 收包
function ActTimeLimit_120:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
        msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber();
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_INFO3_S or opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH3_S then
        msg = Activity2_pb.HPNewTreasureRaiderInfoSync()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    elseif opcode == HP_pb.RELEASE_UR_INFO_S or opcode == HP_pb.RELEASE_UR_DRAW_S then
        msg = Activity3_pb.ReleaseURInfo()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    end
end

function ActTimeLimit_120:updateData(parentContainer, opcode, msg)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    NodeHelper:setNodesVisible(self.container, { mAniNode = true })
    TreasureRaiderDataHelper.RemainTime = msg.leftTime or 0
    TreasureRaiderDataHelper.showItems = msg.items or { }
    TreasureRaiderDataHelper.freeTreasureTimes = msg.freeCD or 0
    TreasureRaiderDataHelper.onceCostGold = msg.onceCostGold or 0
    TreasureRaiderDataHelper.tenCostGold = msg.tenCostGold or 0
    TreasureRaiderDataHelper.buf_multiple = msg.buf_multiple or 1
    TreasureRaiderDataHelper.leftBuffTimes = msg.leftBuffTimes or 0
    TreasureRaiderDataHelper.leftAwardTimes = msg.leftAwardTimes or 10
    if opcode == HP_pb.NEW_TREASURE_RAIDER_INFO3_S or opcode == HP_pb.RELEASE_UR_INFO_S then
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
        end
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH3_S or opcode == HP_pb.RELEASE_UR_DRAW_S then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then
        end
        ReqAnim.showNewReward = { }
        ReqAnim.showNewReward = msg.reward

        ------------------------------------------
        if mIsActionProcess then
            mIsRunAction = true
            if #ReqAnim.showNewReward == 10 then
                -- TODO十连抽动画
                -- self:pushRewardPage()
                self:tenAnimJumpAction()
            elseif
                #ReqAnim.showNewReward == 1 then
                -- TODO普通动画
                mMoveTime = MOVE_TIME_MAX
                mMoveStage = mMoveSpeedStage.addStage
                mCurrentRoundNum = 0
                mIsCanStop = false
                mRoundNum = math.random(16, 20)
                self:recoveryItemMoveStage()
                self:itemMoveBy()
            end
        else
            self:pushRewardPage()
        end
        -- self:pushRewardPage()
        ------------------------------------------

    end
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end
    self:refreshPage(self.container)
end


function ActTimeLimit_120:pushRewardPage()
    mIsRunAction = false
    local onceGold = TreasureRaiderDataHelper.onceCostGold
    local tenGold = TreasureRaiderDataHelper.tenCostGold
    local reward = ReqAnim.showNewReward
    local isFree = TreasureRaiderDataHelper.freeTreasureTimes <= 0
    local freeCount = 0
    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", false, ActTimeLimit_120.onOnceSearch_1, ActTimeLimit_120.onTenSearch_1, function()
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

        end )
    else
        CommonRewardAni:setFirstDataNew(onceGold, tenGold, reward, isFree, freeCount, "", true, ActTimeLimit_120.onOnceSearch_1, ActTimeLimit_120.onTenSearch_1, nil)
    end
end


function ActTimeLimit_120:onExit(parentContainer)
    local mRandRewardNode = self.container:getVarNode("mRandRewardNode")
    mRandRewardNode:removeAllChildren()
    -- mRandRewardNode:removeAllChildrenWithCleanup(true)
    mIsRunAction = false
    mLightingSprite:stopAllActions()
    mAniMoveNode:stopAllActions()
    mAniMoveNode:setPosition(mAniMoveNodeInitPosition)
    for k, v in pairs(mItemNode) do
        v:removeFromParentAndCleanup(true)
    end
    mItemNode = { }

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
end

----------------------------click client -------------------------------------------
function ActTimeLimit_120:onOnceSearch(container)
    if mIsRunAction then
        return
    end
    mIsActionProcess = true
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
        common:rechargePageFlag("ActTimeLimit_120ActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    local msg = Activity2_pb.HPNewTreasureRaiderSearch()
    msg.searchTimes = 1
    common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH3_C, msg)
end

function ActTimeLimit_120:onTenSearch(container)
    if mIsRunAction then
        return
    end
    mIsActionProcess = true
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("ActTimeLimit_120ActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    local msg = Activity2_pb.HPNewTreasureRaiderSearch()
    msg.searchTimes = 10
    common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH3_C, msg)
end

function ActTimeLimit_120:onOnceSearch_1(container)
    if mIsRunAction then
        return
    end
    mIsActionProcess = false
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
        common:rechargePageFlag("ActTimeLimit_120ActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    local msg = Activity2_pb.HPNewTreasureRaiderSearch()
    msg.searchTimes = 1
    common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH3_C, msg)
end

function ActTimeLimit_120:onTenSearch_1(container)
    if mIsRunAction then
        return
    end
    mIsActionProcess = false
    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("ActTimeLimit_120ActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    local msg = Activity2_pb.HPNewTreasureRaiderSearch()
    msg.searchTimes = 10
    common:sendPacket(HP_pb.NEW_TREASURE_RAIDER_SEARCH3_C, msg)
end

function ActTimeLimit_120:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_120:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_120:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEW_TREASURERAIDER);
end

function ActTimeLimit_120:onRewardPreview(container)
    if mIsRunAction then
        return
    end

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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_ACT_120)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end

function ActTimeLimit_120:onBoxPreview(container)
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
ActTimeLimit_120 = CommonPage.newSub(ActTimeLimit_120, thisPageName, option)

return ActTimeLimit_120