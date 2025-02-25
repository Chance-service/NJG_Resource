----------------------------------------------------------------------------------
-- 连续充值
----------------------------------------------------------------------------------
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper");
local thisPageName = "ContinueRecharge"

local opcodes = {
    CONTINUE_RECHARGE_INFO_C = HP_pb.CONTINUE_RECHARGE_INFO_C,
    CONTINUE_RECHARGE_INFO_S = HP_pb.CONTINUE_RECHARGE_INFO_S,
    GET_CONTINUE_RECHARGE_AWARD_C = HP_pb.GET_CONTINUE_RECHARGE_AWARD_C,
    GET_CONTINUE_RECHARGE_AWARD_S = HP_pb.GET_CONTINUE_RECHARGE_AWARD_S
};
local option = {
    ccbiFile = "Act_TimeLimitContinuousRechargeContent.ccbi",
    handlerMap =
    {
        onReturnButton = "onBack",
        onRecharge = "onRecharge",
        onHelp = "onHelp"
    },
    opcode = opcodes
};



local thisActivityInfo = {
    id = 3,
    remainTime = 0,
    hasRecharged = 0,
    rewardCfg = { },
    rewardIds = { }
};
thisActivityInfo.timerName = "Activity_" .. thisActivityInfo.id;
thisActivityInfo.itemCfg = ActivityConfig[thisActivityInfo.id]["items"] or { };

----------------- local data -----------------
local ContinueRechargeBase = { }


local RechargeItem = {
    ccbiFile = "Act_TimeLimitContinuousRechargeListContent.ccbi",
}

function RechargeItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        RechargeItem.onRefreshItemView(container);
    elseif eventName == "onBtn" then
        RechargeItem.onReceiveReward(container);
    elseif eventName:sub(1, 7) == "onFrame" then
        RechargeItem.showItemInfo(container, eventName);
    end
end

function RechargeItem.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    local itemCfgId = thisActivityInfo.rewardIds[index];
    local rewardItem = thisActivityInfo.itemCfg[itemCfgId];
    if rewardItem == nil then return; end

    local cfg = thisActivityInfo.rewardCfg[itemCfgId];
    if cfg == nil then
        cfg = ConfigManager.getRewardById(rewardItem.r);
        thisActivityInfo.rewardCfg[itemCfgId] = cfg;
    end
    local day = rewardItem.d;
    NodeHelper:fillRewardItem(container, cfg);
    NodeHelper:setStringForLabel(container, { mChatBtnTxt1 = common:getLanguageString("@ActTLCRContentInfoTxt", day) });
    local canReceive = day <= thisActivityInfo.hasRecharged;

    local btnNormalImage = GameConfig.CommonButtonImage.Bule.NormalImage
    local fntPath = GameConfig.FntPath.Bule

    NodeHelper:setMenuItemImage(container, { mBtn = { normal = btnNormalImage } })
    NodeHelper:setBMFontFile(container, { mChatBtnTxt2 = fntPath })


    NodeHelper:setMenuItemEnabled(container, "mBtn", canReceive);

    NodeHelper:setNodeIsGray(container, { mChatBtnTxt2 = not canReceive })
end

function RechargeItem.onReceiveReward(container)
    local index = container:getItemDate().mID;
    local itemCfgId = thisActivityInfo.rewardIds[index];
    local rewardItem = thisActivityInfo.itemCfg[itemCfgId];
    if rewardItem == nil then return; end

    local msg = Activity_pb.HPGetContinueRechargeAward();
    msg.awardCfgId = tonumber(itemCfgId);
    common:sendPacket(opcodes.GET_CONTINUE_RECHARGE_AWARD_C, msg);
end

function RechargeItem.showItemInfo(container, eventName)
    local index = container:getItemDate().mID;
    local itemCfgId = thisActivityInfo.rewardIds[index];
    local cfg = thisActivityInfo.rewardCfg[itemCfgId];
    local rewardIndex = tonumber(eventName:sub(8));
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), common:table_merge(cfg[rewardIndex], { buyTip = true, hideBuyNum = true }));
end
-----------------------------------------------
-- ContinueRechargeBase页面中的事件处理
----------------------------------------------
function ContinueRechargeBase:onEnter(ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    NodeHelper:initScrollView(container, "mContent", 3);

    NodeHelper:autoAdjustResizeScale9Sprite(self.container:getVarScale9Sprite("mS9_1"))

    if container.mScrollView ~= nil then
        ParentContainer:autoAdjustResizeScrollview(container.mScrollView);
    end
    self:clearPage(container);
    self:registerPacket(ParentContainer);
    self:getActivityInfo(container);


    return self.container
end

function ContinueRechargeBase:onExecute(ParentContainer)
    self:onTimer(self.container);
end

function ContinueRechargeBase:onExit(ParentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(thisActivityInfo.timerName);
    NodeHelper:deleteScrollView(self.container);
    self:removePacket(ParentContainer);
    self.container = nil
end
----------------------------------------------------------------
function ContinueRechargeBase:onTimer(container)
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

function ContinueRechargeBase:clearPage(container)
    NodeHelper:setStringForLabel(container, {
        mActivityDaysNum = "",
        mRechargeDaysNum = ""
    } );
end

function ContinueRechargeBase:getActivityInfo(container)
    local msg = Activity_pb.HPContinueRechargeInfo();
    common:sendPacket(opcodes.CONTINUE_RECHARGE_INFO_C, msg);
end

function ContinueRechargeBase:refreshPage(container)
    -- local dayStr = thisActivityInfo.hasRecharged .. common:getLanguageString("@Days");
    -- NodeHelper:setStringForLabel(container, {mChatBtn = dayStr});
    if thisActivityInfo.remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(thisActivityInfo.timerName, thisActivityInfo.remainTime);
    end
    self:rebuildAllItem(container)
end
----------------scrollview-------------------------
function ContinueRechargeBase:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function ContinueRechargeBase:clearAllItem(container)
    NodeHelper:clearScrollView(container);
end

function ContinueRechargeBase:buildItem(container)
    NodeHelper:buildScrollView(container, #thisActivityInfo.rewardIds, RechargeItem.ccbiFile, RechargeItem.onFunction);
end	

function ContinueRechargeBase:onRecharge(container)
    libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "ContinueRecharge_enter_rechargePage")
    PageManager.pushPage("RechargePage");
end

function ContinueRechargeBase:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.CONTINUE_RECHARGE_INFO_S then
        local msg = Activity_pb.HPContinueRechargeInfoRet();
        msg:ParseFromString(msgBuff);

        thisActivityInfo.hasRecharged = msg.continueRechargedays;
        thisActivityInfo.remainTime = msg.surplusTime;
        local rewardIds = common:table_keys(thisActivityInfo.itemCfg);
        table.sort(rewardIds);
        for _, id in ipairs(msg.gotAwardCfgId) do
            rewardIds = common:table_removeFromArray(rewardIds, id);
        end
        thisActivityInfo.rewardIds = rewardIds;
        self:refreshPage(self.container);
        return;
    end

    if opcode == opcodes.GET_CONTINUE_RECHARGE_AWARD_S then
        local msg = Activity_pb.HPGetContinueRechargeAwardRet();
        msg:ParseFromString(msgBuff);

        thisActivityInfo.rewardIds = common:table_removeFromArray(thisActivityInfo.rewardIds, msg.gotAwardCfgId);
        thisActivityInfo.remainTime = msg.surplusTime;
        self:refreshPage(self.container);
        ContinueRechargeBase:clearNotice()
    end
end

function ContinueRechargeBase:clearNotice()
    -- 红点消除
    local hasNotice = false
    local rewardItem

    for i, itemCfgId in ipairs(thisActivityInfo.rewardIds) do
        rewardItem = thisActivityInfo.itemCfg[itemCfgId];
        if rewardItem.d <= thisActivityInfo.hasRecharged then
            hasNotice = true
            break
        end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.CONTINUE_RECHARGE);
    end
end

function ContinueRechargeBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ContinueRechargeBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
ContinueRecharge = CommonPage.newSub(ContinueRechargeBase, thisPageName, option);
return ContinueRecharge