----------------------------------------------------------------------------------
--[[
	140活动
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local thisPageName = "ActTimeLimit_140"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")


local opcodes = {
    ACTIVITY140_DISHWHEEL_INFO_C = HP_pb.ACTIVITY140_DISHWHEEL_INFO_C,
    ACTIVITY140_DISHWHEEL_INFO_S = HP_pb.ACTIVITY140_DISHWHEEL_INFO_S,
    ACTIVITY140_DISHWHEEL_LOTTERY_C = HP_pb.ACTIVITY140_DISHWHEEL_LOTTERY_C,
    ACTIVITY140_DISHWHEEL_LOTTERY_S = HP_pb.ACTIVITY140_DISHWHEEL_LOTTERY_S,
}
local option = {
    ccbiFile = "Act_TimeLimit_140.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onHelp = "onHelp",
        onLuckDraw = "onLuckDraw",
        onRecharge = "onRecharge"
    },
}
local mIsPopPage = false
local ActTimeLimit_140 = { }
ActTimeLimit_140.timerName = "Activity_140"
local mCDTimeStr = "00:00:0"

-- 滚动时间
local CONST_TIME = 6
-- 最小圈数
local CONST_ROUND_COUNT_MIN = 10
-- 最大圈数
local CONST_ROUND_COUNT_MAX = 15
-- 偏移量
local CONST_OFFSET_ANGLE = 10
-- 转动一次消耗的钻石
local CONST_PRICE = 30
--外圈偏移量
local offset_1 = 0
--内圈偏移量
local offset_2 = 0
--外圈上一次的旋转
local currentRotation_1 = nil
--内圈上一次的旋转
local currentRotation_2 = nil

local mConfigData = nil
local mServerData = nil
local mIsMove_1 = false
local mIsMove_2 = false
local mStopId = { In = { }, Out = { } }
-------------------------- logic method ------------------------------------------
function ActTimeLimit_140:onTimer(container)
    --.. common:getLanguageString("@ResetAtZero") 
    local timeStr, timer = ActTimeLimit_140_getCDTime()
    if timer > 0 then
        NodeHelper:setStringForLabel(container, { mEndTimeText = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
    else
        mServerData = nil
        PageManager.refreshPage("MainScenePage", "isShowActivity140Icon")
        self:onClose(self.container)
    end
end

-------------------------- state method -------------------------------------------
function ActTimeLimit_140:getPageInfo(container)
    -- ActTimeLimit_140_getPageInFo()
end

function ActTimeLimit_140:onEnter(container)
    math.randomseed(os.time())
    self.container = container

    luaCreat_ActTimeLimit_140(container)
    self:registerPacket(container)
    self:initData(container)

    if mServerData then
        self:refreshPage(self.container)

    else
        --         self:getPageInfo(container)
        --                local sp1 = container:getVarSprite("mTurnImage_1")
        --                sp1:setRotation(currentRotation_1 == nil and 0 or 0)
        --                local sp2 = container:getVarSprite("mTurnImage_2")
        --                sp2:setRotation(currentRotation_2 == nil and 0 or 0)
    end

end

function ActTimeLimit_140:initData(container)
    mConfigData = ConfigManager.getActivity140Cfg()
    mStopId.In = { }
    mStopId.Out = { }
    for k, v in pairs(mConfigData) do
        if v.type == 1 then
            -- 内圈
            mStopId.In[v.index] = v.proportion
        elseif v.type == 2 then
            -- 外圈
            mStopId.Out[v.index] = v.proportion
        end
    end
end

function ActTimeLimit_140:getIsRunAction()
    if mIsMove_1 == false and mIsMove_2 == false then
        return false
    end
    return true
end

function ActTimeLimit_140:refreshPage(container)

    if mServerData.lotteryTimes == 0 then
        local sp1 = container:getVarSprite("mTurnImage_1")
        sp1:setRotation(0)
        local sp2 = container:getVarSprite("mTurnImage_2")
        sp2:setRotation(0)
    else
        if currentRotation_1 == nil or currentRotation_2 == nil then
            -- 重新进入游戏
            self:turn(self.container, true)
        elseif currentRotation_1 and currentRotation_2 then
            -- 上一次的旋转
            local sp1 = container:getVarSprite("mTurnImage_1")
            sp1:setRotation(currentRotation_1)
            local sp2 = container:getVarSprite("mTurnImage_2")
            sp2:setRotation(currentRotation_2)
        end
    end



    if mServerData ~= nil and mServerData.leftTime > 0 then
        if not TimeCalculator:getInstance():hasKey(ActTimeLimit_140_getCDName()) then
            TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_140_getCDName(), mServerData.leftTime)
        end
    end

    -- NodeHelper:setNodesVisible(self.container, { mBtnTextImage = mServerData.lotteryTimes == 0 })
    -- NodeHelper:setNodesVisible(self.container, { mBtnPriceNode = mServerData.lotteryTimes > 0 })
    NodeHelper:setStringForLabel(container, { mPrice = CONST_PRICE .. "" })
    self:setProportion(self.container)
end

function ActTimeLimit_140:setProportion(container)
    NodeHelper:setStringForLabel(self.container, { mCurrentProportion = ActTimeLimit_140_getProportion() .. "%" })
    NodeHelper:setNodesVisible(self.container, { mBtnTextImage = mServerData.lotteryTimes == 0 })
    NodeHelper:setNodesVisible(self.container, { mBtnPriceNode = mServerData.lotteryTimes > 0 })
end

-- function ActTimeLimit_140:checkItemMoveStage(colIndex)
--    local bl = true

--    for k, v in pairs(mItemMoveState[colIndex]) do
--        if not v then
--            bl = v
--            break
--        end
--    end
--    return bl
-- end

-- function ActTimeLimit_140:recoveryItemMoveStage(colIndex)
--    mItemMoveState[colIndex] = { }
--    for i = 1, 4 do
--        table.insert(mItemMoveState[colIndex], false)
--    end
-- end

--------------------------------------
-- 按钮事件
function ActTimeLimit_140:onClose(container)
    if self:getIsRunAction() then
        return
    end
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_140:onHelp(container)
    if self:getIsRunAction() then
        --return
    end
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACT_140)
end

function ActTimeLimit_140:onRecharge(container)
    if self:getIsRunAction() then
        return
    end
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "ActTimeLimit_140_rechargePage")
    PageManager.pushPage("RechargePage")
    self:onClose()
end


function ActTimeLimit_140:onLuckDraw(container)

    if self:getIsRunAction() then
        return
    end

    -- self:turn(container)
    UserInfo.syncPlayerInfo()
    local isFree = mServerData.lotteryTimes == 0
    if isFree or UserInfo.playerInfo.gold >= CONST_PRICE then
        common:sendEmptyPacket(HP_pb.ACTIVITY140_DISHWHEEL_LOTTERY_C)
    else
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. 140)
    end
end

function ActTimeLimit_140:turn(container, isFirstEnterGame)
    local sp1 = container:getVarSprite("mTurnImage_1")
    -- local stop1 = math.random(1, 4)
    local stop1 = mServerData.outIndex
    self:turnOutside(sp1, stop1, isFirstEnterGame)
    CCLuaLog("11111111111111111111 ==== >> " .. stop1)


    local sp2 = container:getVarSprite("mTurnImage_2")
    -- local stop2 = math.random(1, 6)
    local stop2 = mServerData.inIndex
    self:turnInside(sp2, stop2, isFirstEnterGame)
    CCLuaLog("22222222222222222222 ==== >> " .. stop2)


    self:runProportionAction(container)
end

-- 外圈转动  逆时针
function ActTimeLimit_140:turnOutside(sprRound, stopId, isFirstEnterGame)


    local totalCount = 4
    local roundCountMin = CONST_ROUND_COUNT_MIN
    local roundCountMax = CONST_ROUND_COUNT_MAX
    local singleAngle = 360 / totalCount
    local offsetAngle = CONST_OFFSET_ANGLE
    local angleMin =(stopId - 1) * singleAngle
    local roundCount = math.random(roundCountMin, roundCountMax)
    local x = -1
    if math.random(0, 1) == 1 then
        x = 1
    end
    local tempOffset = math.random(10, 40) * x
    local angleTotal = 360 * roundCount - angleMin + tempOffset + offset_1
    offset_1 = angleMin - tempOffset

    if isFirstEnterGame then
        currentRotation_1 = -angleTotal
        sprRound:setRotation(currentRotation_1)
        mIsMove_1 = false
    else
        mIsMove_1 = true
        local rotateBy = CCRotateBy:create(CONST_TIME, - angleTotal)
        local func = CCCallFunc:create( function()
            currentRotation_1 = sprRound:getRotation()
            mIsMove_1 = false
        end )

        local Array = CCArray:create()
        Array:addObject(CCEaseInOut:create(rotateBy, 3))
        Array:addObject(func)
        local Sequence = CCSequence:create(Array)
        sprRound:runAction(Sequence)
    end

end

-- 内圈转动  顺时针
function ActTimeLimit_140:turnInside(sprRound, stopId, isFirstEnterGame)
    local totalCount = 6
    local roundCountMin = CONST_ROUND_COUNT_MIN
    local roundCountMax = CONST_ROUND_COUNT_MAX
    local singleAngle = 360 / totalCount
    local offsetAngle = CONST_OFFSET_ANGLE
    local angleMin =(stopId - 1) * singleAngle
    local roundCount = math.random(roundCountMin, roundCountMax)
    local x = -1
    if math.random(0, 1) == 1 then
        x = 1
    end
    local tempOffset = math.random(5, 25) * x
    local angleTotal = 360 * roundCount - angleMin + tempOffset + offset_2
    offset_2 = angleMin - tempOffset

    if isFirstEnterGame then
        currentRotation_2 = angleTotal
        sprRound:setRotation(currentRotation_2)
        mIsMove_2 = false
    else
        mIsMove_2 = true
        local rotateBy = CCRotateBy:create(CONST_TIME, angleTotal)
        local func = CCCallFunc:create( function()
            currentRotation_2 = sprRound:getRotation()
            mIsMove_2 = false
        end )

        local Array = CCArray:create()
        Array:addObject(CCEaseInOut:create(rotateBy, 3))
        Array:addObject(func)
        local Sequence = CCSequence:create(Array)
        sprRound:runAction(Sequence)
    end

end


function ActTimeLimit_140:runProportionAction(container)
    local mCurrentProportion = self.container:getVarLabelBMFont("mCurrentProportion")
    local delayTime = CCDelayTime:create(0.1)
    local CallFunc = CCCallFuncN:create( function()
        if self:getIsRunAction() then
            local randNum = math.random(50, 300)
            NodeHelper:setStringForLabel(self.container, { mCurrentProportion = randNum .. "%" })
            self:runProportionAction(self.container)
        else

            self:setProportion(self.container)
        end
    end )
    local Array = CCArray:create()
    Array:addObject(delayTime)
    Array:addObject(CallFunc)
    local Sequence = CCSequence:create(Array)
    mCurrentProportion:runAction(Sequence)
end
---------------------------------------------------------------------------------------------------------

function ActTimeLimit_140:onExecute(container)
    self:onTimer(self.container)
end

-- 收包
function ActTimeLimit_140:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ACTIVITY140_DISHWHEEL_INFO_S then
        msg = Activity3_pb.Activity140InfoRep()
        msg:ParseFromString(msgBuff)
        mServerData = msg
    elseif opcode == HP_pb.ACTIVITY140_DISHWHEEL_LOTTERY_S then
        msg = Activity3_pb.Activity140LotteryRep()
        msg:ParseFromString(msgBuff)
        mServerData.lotteryTimes = mServerData.lotteryTimes + 1
        mServerData.inIndex = msg.inIndex
        mServerData.outIndex = msg.outIndex
        self:turn(container, false)
        ActivityInfo.changeActivityNotice(Const_pb.RUSSIADISHWHEEL)
    end
end

function ActTimeLimit_140:onExit(container)

end


function ActTimeLimit_140:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_140:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


function ActTimeLimit_140:getProportion()
    if not mServerData then
        return 0
    end
    return mStopId.In[mServerData.inIndex] * mStopId.Out[mServerData.outIndex]
end

--------------------------------------------------------

function ActTimeLimit_140_isShowIcon()
    if mServerData == nil then
        return false
    end

    if mServerData.isUsed then
        return false
    end

    if mServerData.leftTime <= 0 then
        return false
    end

    return true
end

function ActTimeLimit_140_getServerData()
    return mServerData
end
function ActTimeLimit_140_getProportion()
    if not mServerData then
        return 0
    end
    return mStopId.In[mServerData.inIndex] * mStopId.Out[mServerData.outIndex]
end

function ActTimeLimit_140_getCDName()
    return "Activity_140CDName"
end

function ActTimeLimit_140_getPageInFo()
    mServerData = nil
    common:sendEmptyPacket(HP_pb.ACTIVITY140_DISHWHEEL_INFO_C)
end

function ActTimeLimit_140_setServerData(msg)
    mServerData = msg
    if mServerData then
        if mServerData ~= nil and mServerData.leftTime > 0 then
            TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_140_getCDName(), mServerData.leftTime)
            if not TimeCalculator:getInstance():hasKey(ActTimeLimit_140_getCDName()) then
                -- TimeCalculator:getInstance():createTimeCalcultor(ActTimeLimit_140_getCDName(), mServerData.leftTime)
            end
        else
            TimeCalculator:getInstance():removeTimeCalcultor(ActTimeLimit_140_getCDName())
        end
    else
        -- 活动结束
        if TimeCalculator:getInstance():hasKey(ActTimeLimit_140_getCDName()) then
            TimeCalculator:getInstance():removeTimeCalcultor(ActTimeLimit_140_getCDName())
        end
    end
end

function ActTimeLimit_140_isPopPage()
        if mServerData then
            if mServerData.todayLoginCount == mServerData.loginTimes then
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

function ActTimeLimit_140_getCDTime()
    if mServerData then
        local timeStr = ""
        if not TimeCalculator:getInstance():hasKey(ActTimeLimit_140_getCDName()) then
            if mServerData.leftTime <= 0 then
                return timeStr, 0
            end
        end
        mServerData.leftTime = TimeCalculator:getInstance():getTimeLeft(ActTimeLimit_140_getCDName())
        if mServerData.leftTime > 0 then
            timeStr = GameMaths:formatSecondsToTime(mServerData.leftTime)
        end
        return timeStr, mServerData.leftTime
    else
        return "", 0
    end
end

--------------------------------------------------------

local CommonPage = require('CommonPage')
Act_140 = CommonPage.newSub(ActTimeLimit_140, thisPageName, option)

return ActTimeLimit_140