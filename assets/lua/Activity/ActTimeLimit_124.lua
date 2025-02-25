-- Ã¨ï¿½ß¤ï¿½ï¿½ï¿½
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local thisPageName = "ActTimeLimit_124"
local ConfigManager = require("ConfigManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ActTimeLimit_124 = {
}

local option = {
    ccbiFile = "Act_124_Page.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onClose = "onClose",
        onClosePopNode = "onClosePopNode",
        onLuckDraw = "onLuckDraw",
        onRecharge = "onRecharge"
    },
}

local opcodes = {
    ACTIVITY124_RECHARGE_RETURN_INFO_C = HP_pb.ACTIVITY124_RECHARGE_RETURN_INFO_C,
    ACTIVITY124_RECHARGE_RETURN_INFO_S = HP_pb.ACTIVITY124_RECHARGE_RETURN_INFO_S,
    ACTIVITY124_RECHARGE_RETURN_LOTTERY_C = HP_pb.ACTIVITY124_RECHARGE_RETURN_LOTTERY_C,
    ACTIVITY124_RECHARGE_RETURN_LOTTERY_S = HP_pb.ACTIVITY124_RECHARGE_RETURN_LOTTERY_S
}

local mServerData = nil
-- local mConfigData = nil
local mIsRunAction = false
local mIsShowPopNode = false
local _currentPrice = 0
local _PriceConfigData = nil
ActTimeLimit_124.timerName = "Activity_ActTimeLimit_124"
ActTimeLimit_124.timerLabel = "mTanabataCD"
ActTimeLimit_124.timerKeyBuff = "Activity_ActTimeLimit_124_Timer_Key_Buff"
ActTimeLimit_124.timerFreeCD = "Activity_ActTimeLimit_124_Timer_Free_CD"


local mConfigData = {
    [1] = { id = 1, proportion = 50, probability = 3 },
    [2] = { id = 2, proportion = 55, probability = 3 },
    [3] = { id = 3, proportion = 60, probability = 32 },
    [4] = { id = 4, proportion = 65, probability = 32 },
    [5] = { id = 5, proportion = 70, probability = 10 },
    [6] = { id = 6, proportion = 75, probability = 10 },
    [7] = { id = 7, proportion = 80, probability = 5 },
    [8] = { id = 8, proportion = 90, probability = 5 }
}

function ActTimeLimit_124:onEnter(container)
    -- math.randomseed(os.time())
    -- local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    -- luaCreat_ActTimeLimit_124(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)

    self:initData()
    self:initUi(container)
    self:registerPacket(container)
    self:getPageInfo()
    CCUserDefault:sharedUserDefault():setStringForKey("OpenActTimeLimit124Page" .. UserInfo.playerInfo.playerId, tostring(GamePrecedure:getInstance():getServerTime()))
    -- return container
end

function ActTimeLimit_124:initData()
    mServerData = nil
    mIsShowPopNode = false
    mIsRunAction = false
    _PriceConfigData = ConfigManager.getAct124CostCfg()
    -- mConfigData = ConfigManager.getRechargeReturnLottery_124Cfg()
    -- local ccc = ConfigManager.getRechargeReturnLottery_124Cfg()
end

function ActTimeLimit_124:initUi(container)
    NodeHelper:setNodesVisible(self.container, { mMessageNode = false })
    NodeHelper:setNodesVisible(self.container, { mPopNode = false })
    NodeHelper:setNodesVisible(self.container, { mCardMessge = false })
    NodeHelper:setNodesVisible(self.container, { mCardImage = false })
    NodeHelper:setStringForLabel(self.container, { mEndTimeText = "" })
    NodeHelper:setNodesVisible(self.container, { mClockBtnNode = false })

    NodeHelper:setNodesVisible(self.container, { mLuckDrawBtnNode = false, mRechargeBtnNode = false })
end


function ActTimeLimit_124:getPageInfo(container)
    -- ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ï?
    common:sendEmptyPacket(HP_pb.ACTIVITY124_RECHARGE_RETURN_INFO_C)
end


-- Ë¢ï¿½ï¿½Ò³ï¿½ï¿½
function ActTimeLimit_124:refreshPage(container)
    NodeHelper:setNodesVisible(self.container, { mMessageNode = true })
    NodeHelper:setNodesVisible(self.container, { mCardImage = false })

    if mServerData.count > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        -- TimeCalculator:getInstance():createTimeCalcultor(self.timerName, mServerData.lefttime)
    end

    if mServerData.lefttime > 0 then
        if not TimeCalculator:getInstance():hasKey(self.timerName) then
            TimeCalculator:getInstance():createTimeCalcultor(self.timerName, mServerData.lefttime)
        end
    end

    if mServerData.count <= 0 then
        -- Ã»³é¹ý
        -- NodeHelper:setSpriteImage(self.container, { mBtnTextImage = "UI/Effect/MeiRiShouChong/First_Choujiang.png" })
        NodeHelper:setNodesVisible(self.container, { mBtnTextImage = true, mBtnPriceNode = false })
        NodeHelper:setNodesVisible(self.container, { mCardMessge = false })
    else
        -- ³é¹ý
        -- NodeHelper:setSpriteImage(self.container, { mBtnTextImage = "UI/Effect/MeiRiShouChong/First_Buy.png" })
        NodeHelper:setNodesVisible(self.container, { mBtnTextImage = false, mBtnPriceNode = true })
        NodeHelper:setNodesVisible(self.container, { mCardMessge = true })
        NodeHelper:setStringForLabel(self.container, { mNumber_Min_Text = "+" .. mConfigData[mServerData.type].proportion .. "%" })
    end

    self:updatePrice(container)

    -- NodeHelper:setStringForLabel(self.container, { mRechargeBtnText = common:getLanguageString("@GoToRecharge") })

    if self:getIsCanLuckDraw() then
        NodeHelper:setSpriteImage(container, { mCatBg = "UI/Effect/MeiRiShouChong/First_BG_01.png" })
        NodeHelper:setNodesVisible(self.container, { mFreeBtnNode = false, mLuckDrawBtnNode = true, mRechargeBtnNode = true })
    else
        NodeHelper:setSpriteImage(container, { mCatBg = "UI/Effect/MeiRiShouChong/First_BG_03.png" })
        NodeHelper:setNodesVisible(self.container, { mFreeBtnNode = true, mLuckDrawBtnNode = false, mRechargeBtnNode = false })
    end

    if mServerData.isUsed then
        NodeHelper:setNodesVisible(self.container, { mFreeBtnNode = false, mLuckDrawBtnNode = false, mRechargeBtnNode = false })
    else
        -- NodeHelper:setNodesVisible(self.container, { mLuckDrawBtnNode = true, mRechargeBtnNode = true })
    end
end

function ActTimeLimit_124:updatePrice(container)
    local price = 0

    local count = mServerData.count + 1
    if count >= #_PriceConfigData then
        price = _PriceConfigData[#_PriceConfigData].price
    else
        price = _PriceConfigData[count].price
    end
    _currentPrice = price
    NodeHelper:setStringForLabel(container, { mPrice = price .. "" })
end


function ActTimeLimit_124:getIsCanLuckDraw()
    local bl = false
    if mServerData then
        bl = mServerData.count > 0
    end
    return bl
end

-- ï¿½Õ°ï¿½
function ActTimeLimit_124:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ACTIVITY124_RECHARGE_RETURN_INFO_S then
        local msg = Activity3_pb.Activity124InfoRep()
        msg:ParseFromString(msgBuff)
        mServerData = msg
        -- UserInfo.isUseLottery = msg.isUsed
        self:refreshPage(self.container)

    elseif opcode == HP_pb.ACTIVITY124_RECHARGE_RETURN_LOTTERY_S then
        local msg = Activity3_pb.Activity124LotteryRep()
        msg:ParseFromString(msgBuff)
        mServerData.count = msg.count
        mServerData.type = msg.type

        self:runAction()
        ActivityInfo.changeActivityNotice(124)
        -- self:refreshPage(self.container)
    end
end

function ActTimeLimit_124:runAction()
    --    mIsRunAction = true
    --    local mCardImage = self.container:getVarSprite("mCardImage")
    --    if mCardImage == nil then
    --        mIsRunAction = false
    --        return
    --    end

    --    mCardImage:stopAllActions()
    --    mCardImage:setPosition(ccp(11.5, 75))
    --    mCardImage:setScale(0.6)
    --    NodeHelper:setNodeVisible(mCardImage, true)
    --    local moveBy = CCMoveTo:create(1, ccp(11.5, -5))
    --    local scaleTo = CCScaleTo:create(1, 1)

    --    local SpawnArray = CCArray:create()
    --    SpawnArray:addObject(moveBy)
    --    SpawnArray:addObject(scaleTo)
    --    local SpawnAction = CCSpawn:create(SpawnArray)


    --    local callFuncN = CCCallFuncN:create( function(node)
    --        self:showPopNode()
    --        self:refreshPage(self.container)
    --    end )

    --    local array = CCArray:create()
    --    array:addObject(SpawnAction)
    --    array:addObject(callFuncN)
    --    local sequence = CCSequence:create(array)
    --    mCardImage:runAction(sequence)




    mIsRunAction = true
    local mCardImage = self.container:getVarSprite("mCardImage")
    if mCardImage == nil then
        mIsRunAction = false
        return
    end

    mCardImage:stopAllActions()
    mCardImage:setPosition(ccp(11.5, 75))
    mCardImage:setScale(0.6)
    NodeHelper:setNodeVisible(mCardImage, true)
    local moveBy = CCMoveTo:create(1, ccp(11.5, -5))
    local scaleTo = CCScaleTo:create(1, 1)

    local SpawnArray = CCArray:create()
    SpawnArray:addObject(moveBy)
    SpawnArray:addObject(scaleTo)
    local SpawnAction = CCSpawn:create(SpawnArray)

    mCardImage:runAction(SpawnAction)



    local delayTime = CCDelayTime:create(1.2)
    local callFuncN = CCCallFuncN:create( function(node)
        self:showPopNode()
        self:refreshPage(self.container)
    end )

    self.container:stopAllActions()
    local array = CCArray:create()
    array:addObject(delayTime)
    array:addObject(callFuncN)
    local sequence = CCSequence:create(array)
    self.container:runAction(sequence)
end


function ActTimeLimit_124:showPopNode()
    self.container:stopAllActions()
    -- mConfigData
    NodeHelper:setStringForLabel(self.container, { mPopNodeNumText = "+" .. mConfigData[mServerData.type].proportion .. "%" })
    NodeHelper:setNodesVisible(self.container, { mPopNode = true })
    -- NodeHelper:setNodesVisible(self.container, { mClockBtnNode = false })
    mIsShowPopNode = true
    mIsRunAction = false
end

function ActTimeLimit_124:pushRewardPage()
    local data = { }
    data.freeCd = TreasureRaiderDataHelper.freeTreasureTimes
    data.onceGold = TreasureRaiderDataHelper.onceCostGold
    data.tenGold = TreasureRaiderDataHelper.tenCostGold
    data.itemId = nil
    data.rewards = TreasureRaiderDataHelper.reward

    local isFree = data.freeCd <= 0

    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", false, ActTimeLimit_124.onBtnClick_1, ActTimeLimit_124.onBtnClick_2, function()
            if #TreasureRaiderDataHelper.reward == 10 then
                PageManager.showComment(true)
                -- ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½Ê¾
            end
        end )
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", true, ActTimeLimit_124.onBtnClick_1, ActTimeLimit_124.onBtnClick_2)
    end
end


function ActTimeLimit_124:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_124:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

--------------click
function ActTimeLimit_124:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACT_124)
end

function ActTimeLimit_124:onClose(container)
    if mIsShowPopNode then
        -- return
    end
    PageManager.popPage(thisPageName)
end


function ActTimeLimit_124:onClosePopNode(container)
    NodeHelper:setNodesVisible(self.container, { mPopNode = false })
    -- NodeHelper:setNodesVisible(self.container, { mClockBtnNode = true })
    mIsShowPopNode = false
end

function ActTimeLimit_124:onRecharge(container)
    if mServerData == nil then
        return
    end

    if mIsRunAction then
        return
    end

    if not self:getIsCanLuckDraw() then
        -- TODO Ã»³é¹ý ²»ÄÜÖ±½Ó³äÖµ  ÌáÊ¾
        -- return
    end

    PageManager.pushPage("RechargePage")
    PageManager.popPage(thisPageName)
end

function ActTimeLimit_124:onLuckDraw(container)
    if mServerData == nil then
        return
    end

    if mIsRunAction then
        return
    end

    UserInfo.syncPlayerInfo()
    if mServerData.count > 0 and UserInfo.playerInfo.gold < _currentPrice then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. Const_pb.ACTIVITY134_WEEKEND_GIFT)
        return
    end

    common:sendEmptyPacket(HP_pb.ACTIVITY124_RECHARGE_RETURN_LOTTERY_C, true)

    --    if self:getIsCanLuckDraw() then
    --        -- ï¿½é½±
    --        common:sendEmptyPacket(HP_pb.ACTIVITY124_RECHARGE_RETURN_LOTTERY_C)
    --    else
    --        -- Ö±ï¿½ï¿½ï¿½ï¿½×ªï¿½ï¿½ï¿½Ìµï¿½
    --        -- libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "MainScene_enter_rechargePage")
    --        PageManager.pushPage("RechargePage")
    --        PageManager.popPage(thisPageName)
    --    end
end

-----------------

function ActTimeLimit_124:onExecute(container)
    self:onTimer(self.container)
end

function ActTimeLimit_124:onTimer(container)

    --    local timerName = option.timerName;
    -- local timeStr = '00:00:00'
    -- if TimeCalculator:getInstance():hasKey(timerName) then
    -- 	PageInfo.timeLeft = TimeCalculator:getInstance():getTimeLeft(timerName)
    -- 	if PageInfo.timeLeft > 0 then
    -- 		 timeStr = common:second2DateString(PageInfo.timeLeft , false)
    -- 	end
    -- end
    -- NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr})

    if mServerData == nil then
        return
    end

    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if mServerData.lefttime <= 0 then
            local endStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setStringForLabel(container, { mEndTimeText = endStr })
            return
        end

    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    if remainTime + 1 > mServerData.lefttime then
        return;
    end
    local timeStr = common:second2DateString(remainTime, false)
    NodeHelper:setStringForLabel(container, { mEndTimeText = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd")
        PageManager.popPage(thisPageName)
    end
end

function ActTimeLimit_124:onExit(container)
    mServerData = nil
    mIsRunAction = false
    self.container:stopAllActions()

    local mCardImage = self.container:getVarSprite("mCardImage")
    if mCardImage == nil then
        mCardImage:stopAllActions()
    end

    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
    self:removePacket(container)
    onUnload(thisPageName, self.container)
end


local CommonPage = require('CommonPage')
Act_124 = CommonPage.newSub(ActTimeLimit_124, thisPageName, option)

return ActTimeLimit_124