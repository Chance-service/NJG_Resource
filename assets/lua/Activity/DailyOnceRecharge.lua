-- 充值领好礼    单笔充值
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local ActivityBasePage = require("Activity.ActivityBasePage")
local NodeHelper = require("NodeHelper")
local thisPageName = "DailyOnceRecharge"

local opcodes = {
    DAILY_RECHARGE_INFO_C = HP_pb.SINGLE_RECHARGE_INFO_C,
    DAILY_RECHARGE_INFO_S = HP_pb.SINGLE_RECHARGE_INFO_S,
    GET_DAILY_RECHARGE_AWARD_C = HP_pb.SINGLE_RECHARGE_AWARD_C,
    GET_DAILY_RECHARGE_AWARD_S = HP_pb.SINGLE_RECHARGE_AWARD_S
}

-- 活动基本信息
local thisActivityInfo = {
    id = 21,
    remainTime = 0,
    rewardCfg = { },
    SingleRechargeInfo = { },
}

local option = {
    ccbiFile = "Act_TimeLimitSingleRechargeContent.ccbi",
    timerName = "Activity_" .. thisActivityInfo.id,
    opcode = opcodes
}

----------------- local data -----------------
local DailyOnceRechargeBase = ActivityBasePage:new(option, thisPageName, opcodes)


local RechargeItem = {
    ccbiFile = "Act_TimeLimitSingleRechargeListContent.ccbi",
}

function RechargeItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function RechargeItem:onRefreshContent(ccbRoot)
    local rewardItem = thisActivityInfo.rewardCfg[self.id]
    local container = ccbRoot:getCCBFileNode()
    if rewardItem == nil then
        return
    end
    local infoCfg = nil
    local itemCfgId = rewardItem.id
    local rewardItems = { }
    for _, item in ipairs(common:split(rewardItem.reward, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(rewardItems, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count),
        } )
    end
    NodeHelper:fillRewardItem(container, rewardItems, 4)

    local amount = rewardItem.needGold
    local price = rewardItem.price
    NodeHelper:setColorForLabel(container, { mContinuousLandingReward = "255 90 81" })
    NodeHelper:setStringForLabel(container, {
        mContinuousLandingReward = common:getLanguageString("@DailyOnceRechargeItem" , amount),
    } )

    local canReceive = true
    local btnText = common:getLanguageString("@Goto")

    local fntPath = GameConfig.FntPath.Golden
    local btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
    for i = 1, #thisActivityInfo.SingleRechargeInfo do
        if itemCfgId == thisActivityInfo.SingleRechargeInfo[i].id then
            infoCfg = thisActivityInfo.SingleRechargeInfo[i]
            if infoCfg.getTimes >= infoCfg.maxRechargeTimes then
                -- 上限
                canReceive = false
                btnText = common:getLanguageString("@ReceiveDone")
            elseif infoCfg.rechargeTimes > infoCfg.getTimes then
                -- 可以领取
                canReceive = true
                btnText = common:getLanguageString("@Receive")
                btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
                fntPath = GameConfig.FntPath.Bule
            else
                -- 否则确认，跳转充值界面
                canReceive = true
                btnText = common:getLanguageString("@Goto")
                btnNormalImage = GameConfig.CommonButtonImage.Golden.NormalImage
                fntPath = GameConfig.FntPath.Golden
                -- 默认确认
            end
            break
        end
    end

    NodeHelper:setMenuItemImage(container, { mRewardDayBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(container, { mReceiveText = fntPath })

    NodeHelper:setStringForLabel(container, {
        mReceiveText = btnText,

        mReceiveNum = common:getLanguageString("@SingleCostOrderTxt",infoCfg.maxRechargeTimes - infoCfg.getTimes),

        --mReceiveNum = common:getLanguageString("@SingleCostOrderTxt",infoCfg.getTimes .. "/" .. infoCfg.maxRechargeTimes),
    } );

    NodeHelper:setMenuItemEnabled(container, "mRewardDayBtn", canReceive)

    NodeHelper:setNodeIsGray(container, { mReceiveText = not canReceive })
end

function RechargeItem:onRewardBtn(container)
    local rewardItem = thisActivityInfo.rewardCfg[self.id]
    if rewardItem == nil then
        return
    end
    local itemCfgId = rewardItem.id
    local canReceive = false
    for i = 1, #thisActivityInfo.SingleRechargeInfo do
        if itemCfgId == thisActivityInfo.SingleRechargeInfo[i].id then
            -- 已经领取
            if thisActivityInfo.SingleRechargeInfo[i].getTimes >= thisActivityInfo.SingleRechargeInfo[i].maxRechargeTimes then
                canReceive = false
            elseif thisActivityInfo.SingleRechargeInfo[i].rechargeTimes > thisActivityInfo.SingleRechargeInfo[i].getTimes then
                -- 可以领取
                canReceive = true
            else
                -- 否则确认，跳转充值界面
                canReceive = false
            end
            break
        end
    end
    if canReceive then
        local msg = Activity_pb.HPSingleRechargeAwards()
        msg.awardCfgId = tonumber(itemCfgId)
        common:sendPacket(opcodes.GET_DAILY_RECHARGE_AWARD_C, msg, false)
    else
        local PageJumpMange = require("PageJumpMange")
        PageJumpMange.JumpPageById(24)
    end
end

function RechargeItem:onFrame1(container)
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 1)
end

function RechargeItem:onFrame2(container)
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 2)
end

function RechargeItem:onFrame3(container)
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 3)
end

function RechargeItem:onFrame4(container)
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 4)
end

function RechargeItem:onShowItemInfo(container, itemInfo, rewardIndex)
    local rewardItems = { }
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } )
        end
    end

    GameUtil:showTip(container:getVarNode("mFrame" .. rewardIndex), rewardItems[rewardIndex])
end

function RechargeItem:onPreLoad(ccbRoot)
end

function RechargeItem:onUnLoad(ccbRoot)

end

-----------------------------------------------
-- DailyOnceRechargeBase页面中的事件处理
----------------------------------------------
function DailyOnceRechargeBase:getPageInfo(container)
    thisActivityInfo.rewardCfg = ConfigManager.getSingleRecharge()

    NodeHelper:autoAdjustResizeScrollview(container:getVarScrollView("mContnet"))
    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    self.container = container

    NodeHelper:setNodesVisible(self.container, { mTxtNode = false })

    -- NodeHelper:setNodesVisible(self.container, { mLastTimeText = false, mTanabataCD = false })

    self:getActivityInfo(container)
end
----------------------------------------------------------------
function DailyOnceRechargeBase:onExecute(container)
    self:onTimer(container)
end

function DailyOnceRechargeBase:onTimer(container)
    local timerName = option.timerName
    if not TimeCalculator:getInstance():hasKey(timerName) then
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = common:getLanguageString("@ActivityEnd") })
        return
    end
    local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName)
    if remainTime + 1 > thisActivityInfo.remainTime then
        -- return
    end

    thisActivityInfo.remainTime = math.max(remainTime, 0)
    local timeStr = common:second2DateString(thisActivityInfo.remainTime, false)
    if thisActivityInfo.remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd")
    end
    NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr })
end

function DailyOnceRechargeBase:clearPage(container)
    NodeHelper:setStringForLabel(container, {
        mActivityDaysNum = ""
    } )
end

function DailyOnceRechargeBase:getActivityInfo(container)
    local msg = Activity_pb.HPSingleRechargeInfo()
    common:sendPacket(opcodes.DAILY_RECHARGE_INFO_C, msg)
end

function DailyOnceRechargeBase:refreshPage(container)
    NodeHelper:setNodesVisible(self.container, { mTxtNode = true })
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(option.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(option.timerName, thisActivityInfo.remainTime)
    end
    self:rebuildAllItem(container)
end
----------------scrollview-------------------------
function DailyOnceRechargeBase:rebuildAllItem(container)
    local t1 = { }
    local t2 = { }
    local t3 = { }

    for i = 1, #thisActivityInfo.SingleRechargeInfo do
        local v = thisActivityInfo.SingleRechargeInfo[i]
        if v.getTimes >= v.maxRechargeTimes then
            -- 上限
            table.insert(t3, v)
        elseif v.rechargeTimes > v.getTimes then
            -- 可以领取
            table.insert(t1, v)
        else
            -- 跳转充值界面
            table.insert(t2, v)
        end
    end

    table.sort(t2, function(a, b)
        return a.id < b.id
    end )

    container.mScrollView:removeAllCell()
    for k, v in pairs(t1) do
        DailyOnceRechargeBase:createItem(container, v.id)
    end

    for k, v in pairs(t2) do
        DailyOnceRechargeBase:createItem(container, v.id)
    end

    for k, v in pairs(t3) do
        DailyOnceRechargeBase:createItem(container, v.id)
    end
    container.mScrollView:orderCCBFileCells()
    -- TODO排序  可领的  条件不够的  已经达到上限的
    --    if Golb_Platform_Info.is_win32_platform then

    --    else
    --        container.mScrollView:removeAllCell()
    --        for i, v in ipairs(thisActivityInfo.rewardCfg) do
    --            local titleCell = CCBFileCell:create()
    --            local panel = RechargeItem:new( { id = i })
    --            titleCell:registerFunctionHandler(panel)
    --            titleCell:setCCBFile(RechargeItem.ccbiFile)
    --            container.mScrollView:addCellBack(titleCell)
    --        end
    --        container.mScrollView:orderCCBFileCells()
    --    end
end

function DailyOnceRechargeBase:createItem(container, itemId)
    local titleCell = CCBFileCell:create()
    local panel = RechargeItem:new( { id = itemId })
    titleCell:registerFunctionHandler(panel)
    titleCell:setCCBFile(RechargeItem.ccbiFile)
    container.mScrollView:addCellBack(titleCell)
end

function DailyOnceRechargeBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

----------------click event------------------------
function DailyOnceRechargeBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function DailyOnceRechargeBase:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "DailyOnceRecharge_enter_rechargePage")
    PageManager.pushPage("RechargePage")
end

function DailyOnceRechargeBase:onBack()
    PageManager.changePage("ActivityPage")
end

function DailyOnceRechargeBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_DAILYONCERECHARGE)
end

-- 回包处理
function DailyOnceRechargeBase:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.DAILY_RECHARGE_INFO_S then
        -- info返回
        local msg = Activity_pb.HPSingleRechargeInfoRet()
        msg:ParseFromString(msgBuff)
        thisActivityInfo.remainTime = msg.surplusTime
        thisActivityInfo.SingleRechargeInfo = msg.info
        self:refreshPage(self.container)
        DailyOnceRechargeBase:clearNotice()
    elseif opcode == opcodes.GET_DAILY_RECHARGE_AWARD_S then
        -- 领取返回
    end
end

function DailyOnceRechargeBase:clearNotice()
    -- 红点消除
    local hasNotice = false
    for i, v in ipairs(thisActivityInfo.SingleRechargeInfo) do
        if v.rechargeTimes > v.getTimes and v.getTimes < v.maxRechargeTimes then
            hasNotice = true
            -- 有可以领取的奖励
            break
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.SINGLE_RECHARGE)
    end
end

function DailyOnceRechargeBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function DailyOnceRechargeBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
-- local CommonPage = require("CommonPage");
-- DailyOnceRecharge = CommonPage.newSub(DailyOnceRechargeBase, thisPageName, option);
return DailyOnceRechargeBase