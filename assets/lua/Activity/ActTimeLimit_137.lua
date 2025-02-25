----------------------------------------------------------------------------------
--[[
	137活动
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity4_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local thisPageName = "ActTimeLimit_137"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")


local opcodes = {
    ACTIVITY137_SLOT_RETURN_INFO_C = HP_pb.ACTIVITY137_SLOT_RETURN_INFO_C,
    ACTIVITY137_SLOT_RETURN_INFO_S = HP_pb.ACTIVITY137_SLOT_RETURN_INFO_S,
    ACTIVITY137_SLOT_RETURN_LOTTERY_C = HP_pb.ACTIVITY137_SLOT_RETURN_LOTTERY_C,
    ACTIVITY137_SLOT_RETURN_LOTTERY_S = HP_pb.ACTIVITY137_SLOT_RETURN_LOTTERY_S,
}
local mItemNode = { }
local mItemNodePosition = { }
local MOVE_TIME_MAX = 0.5
local MOVE_TIME_MIN = 0.1
local mMoveTime = { }
local mIsEnd = { }
local mCurrentConfigId = { }
local option = {
    ccbiFile = "Act_TimeLimit_137.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
        onLuckDraw = "onLuckDraw",
        onRecharge = "onRecharge"
    },
}
local mIsPopPage = false
local ActTimeLimit_137 = { }
ActTimeLimit_137.timerName = "Activity_137"
local mCDTimeStr = "00:00:0"

local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
    Mask = 5000,
}

local mRoundNum = 8
local mMoveSpeedStage = {
    addStage = 0,
    reduceStage = 1,
    endStage = 2
}
local mMoveStage = mMoveSpeedStage.addStage
local mConfigData = ConfigManager.getActivity137Cfg()
local mServerData = nil
local mCurrentRoundNum = { }
local mItemMoveState = { }
local mIsCanStop = { }
local mStopItemTag = { }
local mIsRunAction = false
local mIsActionProcess = true
local mLightingSpriteIndex = 0
local mLineList = { }
-------------------------- logic method ------------------------------------------
function ActTimeLimit_137:onTimer(container)
    --    if mServerData == nil then
    --        return
    --    end
    --    if not TimeCalculator:getInstance():hasKey(ActTimeLimit_137_getCDName()) then
    --        if mServerData.lefttime <= 0 then
    --            local endStr = common:getLanguageString("@ActivityEnd")
    --            NodeHelper:setStringForLabel(container, { mEndTimeText = endStr })
    --            return
    --        end
    --    end

    --    -- mCDTimeStr = "00:00:0"
    --    local timeStr = '00:00:0'
    --    mServerData.lefttime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_137_getCDName())
    --    if mServerData.lefttime > 0 then
    --        timeStr = GameMaths:formatSecondsToTime(mServerData.lefttime)
    --        NodeHelper:setStringForLabel(container, { mEndTimeText = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
    --    else
    --        mServerData = nil
    --        PageManager.refreshPage("MainScenePage", "isShowActivity137Icon")
    --        self:onClose(self.container)
    --    end

    local timeStr, timer = ActTimeLimit_137_getCDTime()
    if timer > 0 then
        NodeHelper:setStringForLabel(container, { mEndTimeText = common:getLanguageString("@SurplusTimeFishing") .. timeStr .. common:getLanguageString("@ResetAtZero") })


    else
        mServerData = nil
        PageManager.refreshPage("MainScenePage", "isShowActivity137Icon")
        self:onClose(self.container)
    end
end

-------------------------- state method -------------------------------------------
function ActTimeLimit_137:getPageInfo(container)
    ActTimeLimit_137_getPageInFo()
end

function ActTimeLimit_137:onEnter(container)
    math.randomseed(os.time())
    self.container = container

    luaCreat_ActTimeLimit_137(container)
    self:registerPacket(container)
    self:initData(container)

    if mServerData then
        self:initItemDefaultValues(self.container, mLineList)
        self:refreshPage(self.container)
    else
        -- self:getPageInfo(container)
    end

    self:runLightingSpriteAction()
end


function ActTimeLimit_137:runLightingSpriteAction()
    --
    if mServerData == nil then
        return
    end
    local mLighting_1 = self.container:getVarSprite("mLighting_1")
    local mLighting_2 = self.container:getVarSprite("mLighting_2")
    local mLighting_3 = self.container:getVarSprite("mLighting_3")
    local mLighting_4 = self.container:getVarSprite("mLighting_4")

    if mLightingSpriteIndex % 2 == 0 then
        mLighting_1:setTexture("BG/Activity_137/Activity_137_Image_11.png")
        mLighting_2:setTexture("BG/Activity_137/Activity_137_Image_12.png")
        mLighting_3:setTexture("BG/Activity_137/Activity_137_Image_13.png")
        mLighting_4:setTexture("BG/Activity_137/Activity_137_Image_14.png")
    else
        mLighting_1:setTexture("BG/Activity_137/Activity_137_Image_12.png")
        mLighting_2:setTexture("BG/Activity_137/Activity_137_Image_11.png")
        mLighting_3:setTexture("BG/Activity_137/Activity_137_Image_14.png")
        mLighting_4:setTexture("BG/Activity_137/Activity_137_Image_13.png")
    end

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
    self.container:runAction(Sequence)
end

function ActTimeLimit_137:initData(container)
    -- mServerData = nil
    mLightingSpriteIndex_1 = 0
    mLightingSpriteIndex_2 = 0
    mConfigData = ConfigManager.getActivity137Cfg()
    -- 移动节点
    mIsRunAction = false
    mItemNode = { }
    mItemNodePosition = { }
    mCurrentRoundNum = { }
    mItemMoveState = { }
    mIsCanStop = { }
    mMoveTime = { }
    mMoveStage = { }
    mRoundNum = { }
    mIsEnd = { }
    mNextConfigId = { }
    mStopItemTag = { }
    for colIndex = 1, 3 do
        mCurrentRoundNum[colIndex] = 0
        mItemNode[colIndex] = { }
        mItemNodePosition[colIndex] = { }
        mItemMoveState[colIndex] = { }
        mIsCanStop[colIndex] = { }
        mMoveTime[colIndex] = 5
        mMoveStage[colIndex] = mMoveSpeedStage.addStage
        mRoundNum[colIndex] = math.random(100, 200)
        mIsEnd[colIndex] = false
        mNextConfigId[colIndex] = 1
        mStopItemTag[colIndex] = 0
        for i = 1, 4 do
            local node = container:getVarNode("mRewardNode_" .. colIndex .. "_" .. i)
            node:removeAllChildren()
            local x, y = node:getPosition()
            table.insert(mItemNodePosition[colIndex], ccp(x, y))
            local itemNode = self:createRewardItem()
            itemNode:setTag(tonumber(i .. i))
            local parent = node:getParent()
            parent:addChild(itemNode)
            -- local itemDataIndex = math.random(1, #mRollItemRewardData)
            -- ActTimeLimit_137:setRollItemData(itemNode, mRollItemRewardData[itemDataIndex])
            itemNode:setPosition(ccp(x, y))
            table.insert(mItemNode[colIndex], itemNode)
            table.insert(mItemMoveState[colIndex], false)
        end
    end


end

function ActTimeLimit_137:refreshPage(container)
    if mServerData ~= nil and mServerData.lefttime > 0 then
        if not TimeCalculator:getInstance():hasKey(ActTimeLimit_137_getCDName()) then
            TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_137_getCDName(), mServerData.lefttime)
        end
    end

    NodeHelper:setNodesVisible(self.container, { mFreeTextNode = mServerData.count == 0 })
    NodeHelper:setNodesVisible(self.container, { mDiamondsTextNode = mServerData.count > 0 })
    self:setProportion(self.container)
end

function ActTimeLimit_137:setProportion(container)
    NodeHelper:setStringForLabel(self.container, { mCurrentProportion = ActTimeLimit_137_getProportion() .. "%" })
end

function ActTimeLimit_137:initItemDefaultValues(container, list)
    local defaultIndex = list
    for colIndex = 1, 3 do
        for i = #mItemNode[colIndex], 1, -1 do
            local id = defaultIndex[colIndex]
            if i == #mItemNode[colIndex] then
                -- 4
                id = id - 1
                if id <= 0 then
                    id = mConfigData[#mConfigData].id
                end
                mCurrentConfigId[colIndex] = id
            elseif i == #mItemNode[colIndex] -1 then
                -- 3
                id = mCurrentConfigId[colIndex] -1
                if id <= 0 then
                    id = mConfigData[#mConfigData].id
                end
                mCurrentConfigId[colIndex] = id
            else
                --  1   2
                id = id + i - 1
                if id > #mConfigData then
                    id = i - 1
                end
            end
            ActTimeLimit_137:setRollItemData(colIndex, mItemNode[colIndex][i], mConfigData[id])
        end

    end
end

function ActTimeLimit_137:checkItemMoveStage(colIndex)
    local bl = true

    for k, v in pairs(mItemMoveState[colIndex]) do
        if not v then
            bl = v
            break
        end
    end
    return bl
end

function ActTimeLimit_137:recoveryItemMoveStage(colIndex)
    mItemMoveState[colIndex] = { }
    for i = 1, 4 do
        table.insert(mItemMoveState[colIndex], false)
    end
end

--------------------------------------
-- 按钮事件
function ActTimeLimit_137:onClose(container)
    if mIsRunAction then
        -- return
    end
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_137:onHelp(container)
    if mIsRunAction then
        --return
    end
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACT_137)
end

function ActTimeLimit_137:onLuckDraw(container)
    if mIsRunAction then
        return
    end
    UserInfo.syncPlayerInfo()
    local isFree = mServerData.count == 0
    if isFree or UserInfo.playerInfo.gold >= 30 then
        common:sendEmptyPacket(HP_pb.ACTIVITY137_SLOT_RETURN_LOTTERY_C)
    else
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. 137)
    end
end

function ActTimeLimit_137:onRecharge(container)
    if mIsRunAction then
        return
    end
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "ActTimeLimit_137_rechargePage")
    PageManager.pushPage("RechargePage")
    self:onClose()
end

---------------------------------------------------------------------------------------------------------


function ActTimeLimit_137:itemMoveBy(colIndex)

    for k, v in pairs(mItemNode[colIndex]) do
        local tag = v:getTag()

        local itemTag = math.modf(tag / 10)
        local currentPosIndex = tag % 10
        local nextPosInde = currentPosIndex + 1
        if nextPosInde > #mItemNode[colIndex] then
            nextPosInde = 1
        end
        v:setTag(tonumber(itemTag .. nextPosInde))
        local moveBy = CCMoveBy:create(mMoveTime[colIndex], ccp(0, -160))
        local callFuncN = CCCallFuncN:create( function(itemNode)
            local tag = itemNode:getTag()

            local itemTag = math.modf(tag / 10)
            local currentPosIndex = tag % 10
            itemNode:setPosition(ccp(mItemNodePosition[colIndex][currentPosIndex].x, mItemNodePosition[colIndex][currentPosIndex].y))

            mItemMoveState[colIndex][itemTag] = true

            if self:checkItemMoveStage(colIndex) then
                -- 一次
                self:recoveryItemMoveStage(colIndex)
                mCurrentRoundNum[colIndex] = mCurrentRoundNum[colIndex] + 1
                if mCurrentRoundNum[colIndex] == mRoundNum[colIndex] then
                    mCurrentRoundNum[colIndex] = 0
                    mMoveStage[colIndex] = mMoveStage[colIndex] + 1
                    -- mMoveStage[colIndex] = mMoveSpeedStage.endStage
                end
                if mMoveStage[colIndex] == mMoveSpeedStage.addStage then
                    mMoveTime[colIndex] = mMoveTime[colIndex] -0.1
                    if mMoveTime[colIndex] <= MOVE_TIME_MIN then
                        mMoveTime[colIndex] = MOVE_TIME_MIN
                    end
                elseif mMoveStage[colIndex] == mMoveSpeedStage.reduceStage then
                    mMoveTime[colIndex] = mMoveTime[colIndex] + 0.1
                    if mMoveTime[colIndex] >= MOVE_TIME_MAX then
                        mMoveTime[colIndex] = MOVE_TIME_MAX
                        mMoveStage[colIndex] = mMoveSpeedStage.endStage
                    end
                    -- mRoundNum = 4
                elseif mMoveStage[colIndex] == mMoveSpeedStage.endStage then
                    mMoveTime[colIndex] = MOVE_TIME_MAX
                end
                if mMoveStage[colIndex] == mMoveSpeedStage.endStage then
                    self:itemMoveEnd(colIndex)
                else
                    for k, v in pairs(mItemNode[colIndex]) do
                        local tag = v:getTag()
                        local itemTag = math.modf(tag / 10)
                        local currentPosIndex = tag % 10
                        if currentPosIndex == 3 then
                            ActTimeLimit_137:setRollItemData(colIndex, v, ActTimeLimit_137:getCurrentConfigData(colIndex))
                        end
                    end
                    self:itemMoveBy(colIndex)
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



function ActTimeLimit_137:itemMoveEnd(colIndex)
    for k, v in pairs(mItemNode[colIndex]) do
        local tag = v:getTag()

        local itemTag = math.modf(tag / 10)
        local currentPosIndex = tag % 10
        local nextPosInde = currentPosIndex + 1
        if nextPosInde > #mItemNode[colIndex] then
            nextPosInde = 1
        end
        v:setTag(tonumber(itemTag .. nextPosInde))
        local moveBy = CCMoveBy:create(mMoveTime[colIndex], ccp(0, -160))
        local callFuncN = CCCallFuncN:create( function(itemNode)
            local tag = itemNode:getTag()
            local itemTag = math.modf(tag / 10)
            local currentPosIndex = tag % 10
            mItemMoveState[colIndex][itemTag] = true
            itemNode:setPosition(ccp(mItemNodePosition[colIndex][currentPosIndex].x, mItemNodePosition[colIndex][currentPosIndex].y))
            if self:checkItemMoveStage(colIndex) then
                self:recoveryItemMoveStage(colIndex)

                for k, v in pairs(mItemNode[colIndex]) do
                    local tag = v:getTag()
                    local itemTag = math.modf(tag / 10)
                    local currentPosIndex = tag % 10
                    if currentPosIndex == 3 then
                        local data = ActTimeLimit_137:getCurrentConfigData(colIndex)
                        ActTimeLimit_137:setRollItemData(colIndex, v, data)
                        if data.id == mLineList[colIndex] then
                            mStopItemTag[colIndex] = itemTag
                            mIsCanStop[colIndex] = true
                        end
                    end
                end

                if mStopItemTag[colIndex] ~= 0 then
                    local tNode = mItemNode[colIndex][mStopItemTag[colIndex]]
                    local tag = tNode:getTag()
                    local itemTag = math.modf(tag / 10)
                    local currentPosIndex = tag % 10
                    if itemTag == mStopItemTag[colIndex] and currentPosIndex == 1 then
                        mIsEnd[colIndex] = true
                        -- 是不是所有都结束了
                        local bl = false
                        for k, v in pairs(mIsEnd) do
                            if not v then
                                bl = true
                                break
                            end
                        end
                        mIsRunAction = bl

                        if not mIsRunAction then
                            -- 都结束了
                            self:actionEnd(self.container)
                        end
                    else
                        self:itemMoveEnd(colIndex)
                    end
                else
                    self:itemMoveEnd(colIndex)
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

function ActTimeLimit_137:actionEnd(container)
    local mCurrentProportion = self.container:getVarLabelBMFont("mCurrentProportion")
    if mCurrentProportion then
        mCurrentProportion:stopAllActions()
    end
    NodeHelper:setNodesVisible(self.container, { mFreeTextNode = mServerData.count == 0 })
    NodeHelper:setNodesVisible(self.container, { mDiamondsTextNode = mServerData.count > 0 })
    self:setProportion(self.container)
end

function ActTimeLimit_137:getCurrentConfigData(colIndex)
    mCurrentConfigId[colIndex] = mCurrentConfigId[colIndex] -1
    if mCurrentConfigId[colIndex] <= 0 then
        mCurrentConfigId[colIndex] = #mConfigData
    end
    -- CCLuaLog("------------------------------" .. mCurrentConfigId[colIndex])
    return mConfigData[mCurrentConfigId[colIndex]]
end

function ActTimeLimit_137:setRollItemData(colIndex, item, data)
    --    mNextConfigId[colIndex] = mNextConfigId[colIndex] -1
    --    if mNextConfigId[colIndex] <= 0 then
    --        mNextConfigId[colIndex] = #mConfigData
    --    end
    --    local itemConfigData = mConfigData[mNextConfigId[colIndex]]

    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    -- local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    -- local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    -- local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")

    -- local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")

    -- iconSprite:setTexture(data.icon)
    -- numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    -- local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    -- local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    -- local qualityImage = NodeHelper:getImageByQuality(data.quality)
    -- qualitySprite:setTexture(qualityImage)

    -- local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture("BG/Activity_137/Activity_137_Image_" .. data.pciId .. ".png")

    -- numLabel:setString(data.proportion .. "")
end


function ActTimeLimit_137:createRewardItem()
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    node:addChild(bgSprite, 0, 1000)

    --    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    --    node:addChild(iconSprite, 1, mItemTag.IconSprite)
    --    local qualitySprite = CCSprite:create("common_ht_propK_bai.png")
    --    node:addChild(qualitySprite, 3, mItemTag.QualitySprite)
    --    local numTTFLabel = CCLabelBMFont:create("x", "Lang/Font-HT-Button-White.fnt")
    --    numTTFLabel:setScale(0.55)
    --    numTTFLabel:setAnchorPoint(ccp(1, 0))
    --    numTTFLabel:setPosition(ccp(38, -38))
    --    node:addChild(numTTFLabel, 3, mItemTag.NumLabel)

    return node
end


function ActTimeLimit_137:onExecute(container)
    self:onTimer(self.container)
end

-- 收包
function ActTimeLimit_137:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ACTIVITY137_SLOT_RETURN_INFO_S then
        -- info返回
        local msg = Activity4_pb.Activity137InfoRep();
        msg:ParseFromString(msgBuff);
        mServerData = msg
        mLineList = { }
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.firstLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.secondLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.thirdLine))
        -- self:initItemDefaultValues(self.container, mLineList)
        -- self:refreshPage(self.container)
    elseif opcode == HP_pb.ACTIVITY137_SLOT_RETURN_LOTTERY_S then
        -- 抽奖返回
        msg = Activity4_pb.Activity137LotteryRep()
        msg:ParseFromString(msgBuff)
        mServerData.count = msg.count

        mLineList = { }
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.firstLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.secondLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.thirdLine))

        if mIsActionProcess then
            mIsRunAction = true
            for colIndex = 1, 3 do
                mIsEnd[colIndex] = false
                mRoundNum[colIndex] = math.random(15, 20)
                mMoveTime[colIndex] = MOVE_TIME_MAX
                -- mMoveTime[colIndex] = 0.2
                mMoveStage[colIndex] = mMoveSpeedStage.addStage
                mCurrentRoundNum[colIndex] = 0
                mIsCanStop[colIndex] = false
                mStopItemTag[colIndex] = 0
                self:recoveryItemMoveStage(colIndex)
                -- self:itemMoveBy(colIndex)
            end


            local delayTime = 0.3
            local CallFunc1 = CCCallFunc:create( function()
                self:itemMoveBy(1)
            end )
            local CallFunc2 = CCCallFunc:create( function()
                self:itemMoveBy(2)
            end )
            local CallFunc3 = CCCallFunc:create( function()
                self:itemMoveBy(3)
            end )
            local Array = CCArray:create()
            Array:addObject(CCDelayTime:create(delayTime))
            Array:addObject(CallFunc1)
            Array:addObject(CCDelayTime:create(delayTime))
            Array:addObject(CallFunc2)
            Array:addObject(CCDelayTime:create(delayTime))
            Array:addObject(CallFunc3)
            local Sequence = CCSequence:create(Array)
            container:runAction(Sequence)
            -- mIsCanStop = false
            -- mRoundNum = math.random(16, 20)
        end
        ActivityInfo.changeActivityNotice(Const_pb.ACTIVITY137_RECHARGE_RETURN)
        -- TODO
        local mCurrentProportion = self.container:getVarLabelBMFont("mCurrentProportion")
        if mCurrentProportion then
            mCurrentProportion:stopAllActions()
        end

        self:runProportionAction(self.container)
    end
end

function ActTimeLimit_137:runProportionAction(container)
    local mCurrentProportion = self.container:getVarLabelBMFont("mCurrentProportion")
    local delayTime = CCDelayTime:create(0.1)
    local CallFunc = CCCallFuncN:create( function()
        if mIsRunAction then
            local randNum = math.random(90, 270)
            NodeHelper:setStringForLabel(self.container, { mCurrentProportion = randNum .. "%" })
            self:runProportionAction(self.container)
        end
    end )
    local Array = CCArray:create()
    Array:addObject(delayTime)
    Array:addObject(CallFunc)
    local Sequence = CCSequence:create(Array)
    mCurrentProportion:runAction(Sequence)
    if mIsRunAction then

    else
        -- mCurrentProportion:stopAllActions()
    end
end

function ActTimeLimit_137:onExit(container)
    self.container:stopAllActions()
    mIsRunAction = false
    for colIndex = 1, 3 do
        for k, v in pairs(mItemNode[colIndex]) do
            v:removeFromParentAndCleanup(true)
        end
    end
    mItemNode = { }
    -- TimeCalculator:getInstance():removeTimeCalcultor(ActTimeLimit_137_getCDName())
    self:removePacket(container)
    onUnload(thisPageName, self.container)
end


function ActTimeLimit_137:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_137:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


function ActTimeLimit_137:getProportion()
    if not mServerData then
        return 0
    end
    if #mLineList ~= 3 then
        return 0
    end
    local isEqual = false
    local maxProportion = 0
    local t = mLineList
    table.sort(t, function(data1, data2)
        return data1 > data2
    end )
    maxProportion = mConfigData[t[1]].proportion

    if t[1] == t[#t] then
        isEqual = true
    end
    if isEqual then
        return maxProportion * 3
    else
        return maxProportion
    end
end

--------------------------------------------------------

function ActTimeLimit_137_isShowIcon()
    if mServerData == nil then
        return false
    end

    if mServerData.isUsed then
        return false
    end

    if mServerData.lefttime <= 0 then
        return false
    end

    return true
end

function ActTimeLimit_137_getServerData()
    return mServerData
end
function ActTimeLimit_137_getProportion()
    if not mServerData then
        return 0
    end
    if #mLineList ~= 3 then
        return 0
    end
    local isEqual = false
    local maxProportion = 0
    local t = mLineList
    table.sort(t, function(data1, data2)
        return data1 > data2
    end )
    maxProportion = mConfigData[t[1]].proportion

    if t[1] == t[#t] then
        isEqual = true
    end
    if isEqual then
        return maxProportion * 3
    else
        return maxProportion
    end
end

function ActTimeLimit_137_getCDName()
    return "Activity_137CDName"
end

function ActTimeLimit_137_getPageInFo()
    mServerData = nil
    common:sendEmptyPacket(HP_pb.ACTIVITY137_SLOT_RETURN_INFO_C)
end

function ActTimeLimit_137_proportionToid(proportion)
    local data = ConfigManager.getActivity137Cfg()
    for i = 1, #data do
        local data = data[i]
        if proportion == data.proportion then
            return data.id
        end
    end
    return 1
end

function ActTimeLimit_137_setServerData(msg)
    mServerData = msg
    if mServerData then
        mLineList = { }

        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.firstLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.secondLine))
        table.insert(mLineList, ActTimeLimit_137_proportionToid(msg.thirdLine))
        if mServerData ~= nil and mServerData.lefttime > 0 then
            TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_137_getCDName(), mServerData.lefttime)
            if not TimeCalculator:getInstance():hasKey(ActTimeLimit_137_getCDName()) then
                -- TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_137_getCDName(), mServerData.lefttime)
            end
        else
            TimeCalculator:getInstance():removeTimeCalcultor(ActTimeLimit_137_getCDName())
        end
    else
        -- 活动结束
        if TimeCalculator:getInstance():hasKey(ActTimeLimit_137_getCDName()) then
            TimeCalculator:getInstance():removeTimeCalcultor(ActTimeLimit_137_getCDName())
        end
    end
end

function ActTimeLimit_137_isPopPage()
    if mServerData then
        if mServerData.loginCount == mServerData.loginTimes then
            if not mIsPopPage then
                mIsPopPage = true
                return true
            else
                return false
            end
            -- return true
        end
        return false
    else
        return false
    end
end

function ActTimeLimit_137_getCDTime()
    if mServerData then
        local timeStr = ""
        if not TimeCalculator:getInstance():hasKey(ActTimeLimit_137_getCDName()) then
            if mServerData.lefttime <= 0 then
                return timeStr, 0
            end
        end
        mServerData.lefttime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_137_getCDName())
        if mServerData.lefttime > 0 then
            timeStr = GameMaths:formatSecondsToTime(mServerData.lefttime)
        end
        return timeStr, mServerData.lefttime
    else
        return "", 0
    end
end

--------------------------------------------------------

local CommonPage = require('CommonPage')
Act_137 = CommonPage.newSub(ActTimeLimit_137, thisPageName, option)

return ActTimeLimit_137