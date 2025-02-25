-- 每日累計チャージ  常驻限定活动 不需要活动剩余时间
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local thisPageName = "AccumulativeRecharge"

local opcodes = {
    ACC_RECHARGE_INFO_C = HP_pb.ACC_RECHARGE_INFO_C,
    ACC_RECHARGE_INFO_S = HP_pb.ACC_RECHARGE_INFO_S,
    GET_ACC_RECHARGE_AWARD_C = HP_pb.GET_ACC_RECHARGE_AWARD_C,
    GET_ACC_RECHARGE_AWARD_S = HP_pb.GET_ACC_RECHARGE_AWARD_S
}
local option = {
    ccbiFile = "Act_TimeLimitRechargeRebateContent.ccbi",
    handlerMap = {
        onReturnButton = "onBack",
        onRecharge = "onRecharge",
        onHelp = "onHelp"
    },
    opcode = opcodes
}

local ItemType = {
    CanReceive = 1,
    --  可领取
    Ing = 2,
    -- 进行中  未达成
    Complete = 3,
    -- 已完成
}

-- 活动基本信息
local thisActivityInfo = {
    id = 2,
    remainTime = 0,
    hasRecharged = 0,
    rewardCfg = {},
    gotAwardCfgId = {}
}
thisActivityInfo.timerName = "Activity_" .. thisActivityInfo.id
thisActivityInfo.itemCfg = ActivityConfig[thisActivityInfo.id]["items"] or {}

----------------- local data -----------------
local AccumulativeRechargeBase = {}

local RechargeItem = {
    ccbiFile = "Act_TimeLimitRechargeRebateListContent.ccbi"
}

function RechargeItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RechargeItem:onFrame1(container)
    -- local index = self.id
    local itemInfo = self.configData
    -- local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 1)
end

function RechargeItem:onFrame2(container)
    -- local index = self.id
    local itemInfo = self.configData
    -- local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 2)
end

function RechargeItem:onFrame3(container)
    -- local index = self.id
    local itemInfo = self.configData
    -- local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 3)
end

function RechargeItem:onFrame4(container)
    -- local index = self.id
    local itemInfo = self.configData
    -- local itemInfo = thisActivityInfo.rewardCfg[index]
    self:onShowItemInfo(container, itemInfo, 4)
end

function RechargeItem:onShowItemInfo(container, itemInfo, rewardIndex)
    local rewardItems = {}
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"))
            table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                })
        end
    end

    GameUtil:showTip(container:getVarNode("mFrame" .. rewardIndex), rewardItems[rewardIndex])
end

function RechargeItem:onRefreshContent(ccbRoot)
    -- local cfg = thisActivityInfo.rewardCfg[self.id]

    local cfg = self.configData
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    if cfg == nil then
        return
    end

    local rewardItems = {}
    for _, item in ipairs(common:split(cfg.reward, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"))
        table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
            })
    end
    NodeHelper:fillRewardItem(container, rewardItems, 4)
    NodeHelper:setStringForLabel(container, {
            mRechargerebateName = common:getLanguageString("@AccumulativeRechargeItem", cfg.needGold)
        })
    if (Golb_Platform_Info.is_r18) then -- R18
        NodeHelper:setStringForLabel(container, {
            mRechargerebateName = common:getLanguageString("@AccumulativeRechargeItem54647", cfg.needGold * GameConfig.eroPriceRatio)
	})
    elseif Golb_Platform_Info.is_jgg then --jgg
        NodeHelper:setStringForLabel(container, {
            mRechargerebateName = common:getLanguageString("@AccumulativeRechargeItemJGG", GameUtil:CNYToPlatformPrice(cfg.needGold, "JGG"))
        })
    end
    local btnTextStr = "@Receive"
    local fntPath = GameConfig.FntPath.Bule
    local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage

    local isEnabled = false
    if self.type == ItemType.CanReceive then
        -- 可以领取
        btnTextStr = "@Receive"
        isEnabled = true
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    elseif self.type == ItemType.Complete then
        -- 已完成
        btnTextStr = "@ReceiveDone"
        fntPath = GameConfig.FntPath.Bule
        btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    else
        -- 进行中 未达成条件
        isEnabled = true
        btnTextStr = "@MissionDay7_GoTo"
        fntPath = GameConfig.FntPath.Green
        btnNormalImage = GameConfig.CommonButtonImage.Green.NormalImage
    end

    NodeHelper:setMenuItemImage(self.container, { mRewardBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(self.container, { mReceiveText = fntPath })

    NodeHelper:setMenuItemsEnabled(self.container, { mRewardBtn = isEnabled })
    NodeHelper:setNodeIsGray(self.container, { mReceiveText = not isEnabled })

    NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString(btnTextStr) })
    --    local canReceive = cfg.needGold <= thisActivityInfo.hasRecharged;
    --    if canReceive then
    --        if not thisActivityInfo.gotAwardCfgId[self.id] then
    --            NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@Receive") })
    --        else
    --            canReceive = false
    --            NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@ReceiveDone") })
    --        end
    --    else
    --        NodeHelper:setStringForLabel(container, { mReceiveText = common:getLanguageString("@UnReceiveDone") })
    --    end
    --    NodeHelper:setMenuItemEnabled(container, "mRewardBtn", canReceive);
end

function RechargeItem:onRewardBtn(container)
    if self.type == ItemType.CanReceive then
        local msg = Activity_pb.HPGetAccRechargeAward()
        msg.awardCfgId = self.configData.id
        common:sendPacket(HP_pb.GET_ACC_RECHARGE_AWARD_C, msg, true)
    elseif self.type == ItemType.Ing then
        -- 跳转到充值
        require("Recharge.RechargePage")
        RechargePageBase_SetCloseFunc( function()
                local msg = Activity_pb.HPAccRechargeInfo()
                common:sendPacket(opcodes.ACC_RECHARGE_INFO_C, msg)
            end )
        PageManager.pushPage("RechargePage")
    end

    --    local itemCfgId = self.id;
    --    -- local rewardItem = thisActivityInfo.itemCfg[itemCfgId];
    --    -- if rewardItem == nil then return; end

    --    local msg = Activity_pb.HPGetAccRechargeAward();
    --    msg.awardCfgId = tonumber(itemCfgId);
    --    common:sendPacket(opcodes.GET_ACC_RECHARGE_AWARD_C, msg);
end

function RechargeItem.showItemInfo(container, eventName)
    local index = container:getItemDate().mID
    local itemCfgId = thisActivityInfo.rewardIds[index]
    local cfg = thisActivityInfo.rewardCfg[itemCfgId]
    local rewardIndex = tonumber(eventName:sub(8))
    GameUtil:showTip(container:getVarNode("mFrame" .. rewardIndex), cfg[rewardIndex])
end
-----------------------------------------------
-- AccumulativeRechargeBaseÒ³ÃæÖÐµÄÊÂ¼þ´¦Àí
----------------------------------------------
function AccumulativeRechargeBase:onEnter(ParentContainer)
    local container = ScriptContentBase:create("Act_TimeLimitRechargeRebateContent.ccbi")
    self.container = container
    -- self.container:registerFunctionHandler(QiXiXianGou.onFunction)
    container.mScrollView = container:getVarScrollView("mContent")

    self:registerPacket(ParentContainer)

    thisActivityInfo.rewardCfg = ConfigManager:getAccumulativeRechargeItem()
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    if mScale9Sprite ~= nil then
        container:autoAdjustResizeScale9Sprite(mScale9Sprite)
    end
    if container.mScrollView ~= nil then
        ParentContainer:autoAdjustResizeScrollview(container.mScrollView)
    end
    self:clearPage(container)
    self:getActivityInfo(container)
    return self.container
end

function AccumulativeRechargeBase:onExecute(ParentContainer)
    self:onTimer(self.container)
end

function AccumulativeRechargeBase:onExit(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(thisActivityInfo.timerName)
    self.container.mScrollView:removeAllCell()
    self:removePacket(ParentContainer)
    onUnload(thisPageName, self.container)
end
----------------------------------------------------------------
function AccumulativeRechargeBase:onTimer(container)
    local timerName = thisActivityInfo.timerName
    if not TimeCalculator:getInstance():hasKey(timerName) then
        return
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName)
    if remainTime + 1 > thisActivityInfo.remainTime then
        return
    end

    thisActivityInfo.remainTime = math.max(remainTime, 0)
    local timeStr = common:second2DateString(thisActivityInfo.remainTime, false)
    NodeHelper:setStringForLabel(container, {mTanabataCD = timeStr})
end

function AccumulativeRechargeBase:clearPage(container)
    NodeHelper:setStringForLabel(container, {
            mActivityDaysNum = "",
            mRechargeDaysNum = ""
        })
end

function AccumulativeRechargeBase:getActivityInfo()
    local msg = Activity_pb.HPAccRechargeInfo()
    common:sendPacket(opcodes.ACC_RECHARGE_INFO_C, msg)
end

function AccumulativeRechargeBase:refreshPage(container)
    local goldStr = thisActivityInfo.hasRecharged
    local langKey = "@continueRechargeMoneyDesc"

    if (Golb_Platform_Info.is_r18) then -- R18
        goldStr = thisActivityInfo.hasRecharged * GameConfig.eroPriceRatio
        langKey = "@continueRechargeMoneyDesc54647"
    elseif Golb_Platform_Info.is_jgg then -- jgg
        goldStr = GameUtil:CNYToPlatformPrice(thisActivityInfo.hasRecharged, "JGG")
        langKey = "@continueRechargeMoneyDescJGG"
    end
    NodeHelper:setStringForLabel(container, { mRechargeDaysNum = common:getLanguageString(langKey, goldStr) })
    
    -- NodeHelper:setStringForLabel(container, { mRechargeDaysNum = goldStr });
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime)
    end
    -- NodeHelper:setLabelOneByOne(container, "mRechargeDaysNum", "mDiamondsWhite", 5);
    self:rebuildAllItem(container)
end
----------------scrollview-------------------------
function AccumulativeRechargeBase:rebuildAllItem(container)
    container.mScrollView:removeAllCell()

    local t = { }
    -- 可领取
    local t1 = { }
    -- 未达成
    local t2 = { }
    -- 已领取

    for k, v in pairs(thisActivityInfo.rewardCfg) do
        local itemType = self:getItemType(v)
        if itemType == ItemType.CanReceive then
            -- 可领取
            table.insert(t, { type = itemType, configData = v })
        elseif itemType == ItemType.Ing then
            -- 未达成
            table.insert(t1, { type = itemType, configData = v })
        else
            -- 已经领取
            table.insert(t2, { type = itemType, configData = v })
        end
    end

    for i, v in pairs(t) do
        local titleCell = CCBFileCell:create()
        local panel = RechargeItem:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(RechargeItem.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    for i, v in pairs(t1) do
        local titleCell = CCBFileCell:create()
        local panel = RechargeItem:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(RechargeItem.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    for i, v in pairs(t2) do
        local titleCell = CCBFileCell:create()
        local panel = RechargeItem:new( { type = v.type, configData = v.configData })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(RechargeItem.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end

    --    for i, v in ipairs(thisActivityInfo.rewardCfg) do
    --        local titleCell = CCBFileCell:create()
    --        local panel = RechargeItem:new( { id = i })
    --        titleCell:registerFunctionHandler(panel)
    --        titleCell:setCCBFile(RechargeItem.ccbiFile)
    --        container.mScrollView:addCellBack(titleCell)
    --    end
    container.mScrollView:orderCCBFileCells()
end

function AccumulativeRechargeBase:getItemType(data)
    local itemType = ItemType.Complete
    if thisActivityInfo.hasRecharged >= data.needGold and not self:isContainId(data.id) then
        -- 可领取
        itemType = ItemType.CanReceive
    elseif thisActivityInfo.hasRecharged < data.needGold and not self:isContainId(data.id) then
        -- 未达成
        itemType = ItemType.Ing
    else
        -- 已经领取  已完成
        itemType = ItemType.Complete
    end

    return itemType
end

function AccumulativeRechargeBase:isContainId(id)
    if thisActivityInfo.gotAwardCfgId[id] then
        return true
    else
        return false
    end
    --    local bl = false
    --    for i = 1, #_ServerData.gotAwardCfgId do
    --        if _ServerData.gotAwardCfgId[i] == id then
    --            bl = true
    --        end
    --    end

    --    return bl
end

function AccumulativeRechargeBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function AccumulativeRechargeBase:buildItem(container)
    NodeHelper:buildScrollView(container, #thisActivityInfo.rewardIds, RechargeItem.ccbiFile, RechargeItem.onFunction)
end

----------------click event------------------------
function AccumulativeRechargeBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function AccumulativeRechargeBase:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "AccumulativeRecharge_enter_recharge")
    PageManager.pushPage("RechargePage")
end

function AccumulativeRechargeBase:onBack()
    PageManager.changePage("ActivityPage")
end

-- »Ø°ü´¦Àí
function AccumulativeRechargeBase:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == opcodes.ACC_RECHARGE_INFO_S then
        local msg = Activity_pb.HPAccRechargeInfoRet()
        msg:ParseFromString(msgBuff)

        thisActivityInfo.hasRecharged = msg.accRechargeGold
        thisActivityInfo.remainTime = msg.surplusTime
        thisActivityInfo.gotAwardCfgId = { }
        for i = 1, #msg.gotAwardCfgId do
            thisActivityInfo.gotAwardCfgId[msg.gotAwardCfgId[i]] = true
        end

        self:refreshPage(self.container)
        return
    end

    if opcode == opcodes.GET_ACC_RECHARGE_AWARD_S then
        local msg = Activity_pb.HPGetAccRechargeAwardRet()
        msg:ParseFromString(msgBuff)
        thisActivityInfo.gotAwardCfgId[msg.gotAwardCfgId] = true
        thisActivityInfo.remainTime = msg.surplusTime

        self:rebuildAllItem(self.container)

        -- self.container.mScrollView:refreshAllCell()
        self:clearNotice()
    end
end

function AccumulativeRechargeBase:clearNotice()
    -- 红点消除
    local hasNotice = false

    for i, v in ipairs(thisActivityInfo.rewardCfg) do
        if v.needGold <= thisActivityInfo.hasRecharged and not thisActivityInfo.gotAwardCfgId[i] then
            hasNotice = true
            break
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.ACCUMULATIVE_RECHARGE)
    end
end

function AccumulativeRechargeBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function AccumulativeRechargeBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
-- local CommonPage = require("CommonPage");
-- AccumulativeRecharge = CommonPage.newSub(AccumulativeRechargeBase, thisPageName, option);
return AccumulativeRechargeBase