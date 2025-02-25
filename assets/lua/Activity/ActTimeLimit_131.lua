----------------------------------------------------------------------------------
-- 累计连续充值活动
----------------------------------------------------------------------------------
local Activity4_pb = require("Activity4_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local thisPageName = "ActTimeLimit_131"

local opcodes = {
    CONTINUE_RECHARGE131_INFO_C = HP_pb.CONTINUE_RECHARGE131_INFO_C,
    CONTINUE_RECHARGE131_INFO_S = HP_pb.CONTINUE_RECHARGE131_INFO_S,
    GET_CONTINUE_RECHARGE131_AWARD_C = HP_pb.GET_CONTINUE_RECHARGE131_AWARD_C,
    GET_CONTINUE_RECHARGE131_AWARD_S = HP_pb.GET_CONTINUE_RECHARGE131_AWARD_S
};
local option = {
    -- Act_TimeLimit_131
    ccbiFile = "Act_TimeLimit_131.ccbi",
    handlerMap =
    {
        onReturnButton = "onBack",
        onRecharge = "onRecharge",
        onHelp = "onHelp"
    },
    opcode = opcodes
};

local thisActivityInfo = {
    id = 131,
    remainTime = 0,
    hasRecharged = 0,
    rewardCfg = { },
    rewardIds = { }
};
thisActivityInfo.timerName = "Activity_" .. thisActivityInfo.id;
thisActivityInfo.itemCfg = ActivityConfig[thisActivityInfo.id]["items"] or { }

local ItemType = {
    CanReceive = 1,
    --  可领取
    Ing = 2,
    -- 进行中  未达成
    Complete = 3,-- 已完成

}
----------------- local data -----------------
local ActTimeLimit_131Base = { }


local RechargeItem = {
    -- Act_TimeLimit_131_ListContent
    ccbiFile = "Act_TimeLimit_131_ListContent.ccbi",
}


function RechargeItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function RechargeItem:onBtn(container)

    if self.type == ItemType.CanReceive then
        local msg = Activity4_pb.HPGetContinueRecharge131Award()
        msg.awardCfgId = self.configData.r
        common:sendPacket(HP_pb.GET_CONTINUE_RECHARGE131_AWARD_C, msg, true)
    elseif self.type == ItemType.Ing then
        -- 跳转到充值
        require("Recharge.RechargePage")
        RechargePageBase_SetCloseFunc( function()
            local msg = Activity4_pb.HPContinueRecharge131Info();
            common:sendPacket(opcodes.CONTINUE_RECHARGE131_INFO_C, msg);
        end )
        PageManager.pushPage("RechargePage")
    end

end

function RechargeItem:onFrame1(container)
    self:showItemInfo(container, 1)
end

function RechargeItem:onFrame2(container)
    self:showItemInfo(container, 2)
end

function RechargeItem:onFrame3(container)
    self:showItemInfo(container, 3)
end

function RechargeItem:onFrame4(container)
    self:showItemInfo(container, 4)
end

function RechargeItem:showItemInfo(container, rewardIndex)
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), common:table_merge(self.reward[rewardIndex], { buyTip = true, hideBuyNum = true }));
end

function RechargeItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    if container == nil then return; end
    self.container = container
    self.reward = ConfigManager.getRewardById(self.configData.r)
    self.day = self.configData.d

    NodeHelper:fillRewardItem(container, self.reward)
    NodeHelper:setStringForLabel(container, { mChatBtnTxt1 = common:getLanguageString("@ActTLCRContentInfoTxt", self.day) });

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


    NodeHelper:setMenuItemImage(self.container, { mBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(self.container, { mChatBtnTxt2 = fntPath })

    NodeHelper:setMenuItemsEnabled(self.container, { mBtn = isEnabled })
    NodeHelper:setNodeIsGray(self.container, { mChatBtnTxt2 = not isEnabled })

    NodeHelper:setStringForLabel(container, { mChatBtnTxt2 = common:getLanguageString(btnTextStr) })
end

-----------------------------------------------
-- ActTimeLimit_131Base页面中的事件处理
----------------------------------------------
function ActTimeLimit_131Base:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    NodeHelper:initScrollView(container, "mContent", 3)

    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    if container.mScrollView ~= nil then
        ParentContainer:autoAdjustResizeScrollview(container.mScrollView);
    end
    self:clearPage(container);
    self:registerPacket(ParentContainer);
    self:getActivityInfo(container);

    NodeHelper:setStringForLabel(container, { mTxt1 = common:getLanguageString("@accRechargeDesc") })
    NodeHelper:setStringForLabel(container, { mTxt2 = "" })

    return self.container
end

function ActTimeLimit_131Base:onExecute(ParentContainer)
    self:onTimer(self.container);
end

function ActTimeLimit_131Base:onExit(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(thisActivityInfo.timerName);
    NodeHelper:deleteScrollView(self.container);
    self:removePacket(ParentContainer);
    self.container = nil
end
----------------------------------------------------------------
function ActTimeLimit_131Base:onTimer(container)
    local timerName = thisActivityInfo.timerName;
    if not TimeCalculator:getInstance():hasKey(timerName) then return; end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
    if remainTime + 1 > thisActivityInfo.remainTime then
        return;
    end

    thisActivityInfo.remainTime = math.max(remainTime, 0);
    local timeStr = common:second2DateString(thisActivityInfo.remainTime, false);
    NodeHelper:setStringForLabel(container, { mTanabataCD = timeStr });
end

function ActTimeLimit_131Base:clearPage(container)
    NodeHelper:setStringForLabel(container, {
        mActivityDaysNum = "",
        mRechargeDaysNum = ""
    } );
end

function ActTimeLimit_131Base:getActivityInfo(container)
    local msg = Activity4_pb.HPContinueRecharge131Info();
    common:sendPacket(opcodes.CONTINUE_RECHARGE131_INFO_C, msg);
end

function ActTimeLimit_131Base:refreshPage(container)
    -- local dayStr = thisActivityInfo.hasRecharged .. common:getLanguageString("@Days");
    -- NodeHelper:setStringForLabel(container, {mChatBtn = dayStr});
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime);
    end
    self:rebuildAllItem(container)
end
----------------scrollview-------------------------
function ActTimeLimit_131Base:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function ActTimeLimit_131Base:clearAllItem(container)
    NodeHelper:clearScrollView(container);
end

function ActTimeLimit_131Base:buildItem(container)
    container.mScrollView:removeAllCell()


    local t = { }
    -- 可领取
    local t1 = { }
    -- 未达成
    local t2 = { }
    -- 已领取


  

    for k, v in pairs(thisActivityInfo.itemCfg) do
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

      table.sort(t , function (data1 , data2)
    return data1.configData.d < data2.configData.d
end)

      table.sort(t1 , function (data1 , data2)
    return data1.configData.d < data2.configData.d
end)

      table.sort(t2 , function (data1 , data2)
    return data1.configData.d < data2.configData.d
end)

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

    container.mScrollView:orderCCBFileCells()

    -- NodeHelper:buildScrollView(container, #thisActivityInfo.rewardIds, RechargeItem.ccbiFile, RechargeItem.onFunction);
end	

function ActTimeLimit_131Base:getItemType(data)
    local itemType = ItemType.Complete
    if thisActivityInfo.hasRecharged >= data.d and not self:isContainId(data.r) then
        -- 可领取
        itemType = ItemType.CanReceive
    elseif thisActivityInfo.hasRecharged < data.d then
        -- 未达成
        itemType = ItemType.Ing
    else
        -- 已经领取  已完成
        itemType = ItemType.Complete
    end

    return itemType
end

function ActTimeLimit_131Base:isContainId(id)
    local bl = false
    for i = 1, #thisActivityInfo.gotAwardCfgId do
        if thisActivityInfo.gotAwardCfgId[i] == id then
            bl = true
            break
        end
    end
    return bl
end

function ActTimeLimit_131Base:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "ContinueRecharge_enter_rechargePage")
    PageManager.pushPage("RechargePage");
end

function ActTimeLimit_131Base:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.CONTINUE_RECHARGE131_INFO_S then
        local msg = Activity4_pb.HPContinueRecharge131InfoRet();
        msg:ParseFromString(msgBuff);

        thisActivityInfo.hasRecharged = msg.continueRechargedays;
        thisActivityInfo.remainTime = msg.surplusTime;
        local rewardIds = common:table_keys(thisActivityInfo.itemCfg);
        table.sort(rewardIds)
        thisActivityInfo.gotAwardCfgId = { }
        for i = 1, #msg.gotAwardCfgId do
            table.insert(thisActivityInfo.gotAwardCfgId, msg.gotAwardCfgId[i])
        end

--        for _, id in ipairs(msg.gotAwardCfgId) do
--            rewardIds = common:table_removeFromArray(rewardIds, id);
--        end
        thisActivityInfo.rewardIds = rewardIds;
        self:refreshPage(self.container);
        return
    end

    if opcode == opcodes.GET_CONTINUE_RECHARGE131_AWARD_S then
        local msg = Activity4_pb.HPGetContinueRecharge131AwardRet();
        msg:ParseFromString(msgBuff);
        table.insert(thisActivityInfo.gotAwardCfgId, msg.gotAwardCfgId)
        -- thisActivityInfo.gotAwardCfgId = msg.gotAwardCfgId
        -- thisActivityInfo.rewardIds = common:table_removeFromArray(thisActivityInfo.rewardIds, msg.gotAwardCfgId);
        thisActivityInfo.remainTime = msg.surplusTime;
        self:refreshPage(self.container);
        ActTimeLimit_131Base:clearNotice()
    end
end

function ActTimeLimit_131Base:clearNotice()
    -- 红点消除
    local hasNotice = false
    for k, v in pairs(thisActivityInfo.itemCfg) do
        local itemType = self:getItemType(v)
        if itemType == ItemType.CanReceive then
            -- 可领取
            hasNotice = true
        elseif itemType == ItemType.Ing then
            -- 未达成
        else
            -- 已经领取
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.CONTINUE_RECHARGE131)
    end


    --    local hasNotice = false
    --    local rewardItem

    --    for i, itemCfgId in ipairs(thisActivityInfo.rewardIds) do
    --        rewardItem = thisActivityInfo.itemCfg[itemCfgId];
    --        if rewardItem.d <= thisActivityInfo.hasRecharged then
    --            hasNotice = true
    --            break
    --        end
    --    end
    --    if not hasNotice then
    --        ActivityInfo.changeActivityNotice(Const_pb.CONTINUE_RECHARGE131)
    --    end
end

function ActTimeLimit_131Base:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_131Base:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
ActTimeLimit_131 = CommonPage.newSub(ActTimeLimit_131Base, thisPageName, option);
return ActTimeLimit_131