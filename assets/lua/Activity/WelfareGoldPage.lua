----------------------------------------------------------------------------------
-- 天降元宝  心愿成就
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb");
local thisPageName = 'WelfareGoldPage'
local WelfareGoldPage = { }
local _NeedGold = 0;-- 需要消耗的钱
local _MyGold = 0;-- 我现在的金币
local changeIdx = 0;-- 数字
local _CountTimer = 0;-- 记录时间
local _CountNum = 6;-- 记录个数
local showTime = 15552000-- 180天，如果小于不显示
local SaveServerData = { }
local SaveAnimationStar = { }
local handler = 0;
local opcodes = {
    WELFARE_REWARD_C = HP_pb.WELFARE_REWARD_C,
    WELFARE_REWARD_S = HP_pb.WELFARE_REWARD_S,
};
local RequestNumber = {
    syncInfo = 0,
    -- 0:同步
    requestData = 1-- 1：抽奖
};


WelfareGoldPage.timerName = "syncServerActivityTimes";
WelfareGoldPage.RemainTime = -1;

-- 重置数据
function WelfareGoldPage:resetData()
    WelfareGoldPage.RemainTime = -1;
    SaveAnimationStar = { };
    SaveServerData = { };
    _NeedGold = 0;
    _MyGold = 0;
    handler = 0;
    for index = 1, 6 do
        --self:addAniChild(index);
    end
    NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
    NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = true, mSuitTenTimes = true, mDiamondText = true })
end

function WelfareGoldPage:onEnter(ParentContainer)
    local container = ScriptContentBase:create("Act_TimeLimitWelfareContent.ccbi")
    self.container = container
    self:resetData();
    self.container:registerFunctionHandler(WelfareGoldPage.onFunction)
    self:registerPacket(ParentContainer);
    local scale = NodeHelper:getScaleProportion()
    if scale > 1 then
        local mBG = self.container:getVarNode("mBG")
        if mBG then
           mBG:setScale(scale)
        end
    end
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mAniNode"))
    --self:showRoleSpine();
    self:requestServerData(RequestNumber.syncInfo);
    WelfareGoldPage:updateGold()
    return self.container
end

function WelfareGoldPage.onFunction(eventName, container)
    if eventName == "onDiamond" then
        WelfareGoldPage:onDiamond();
    elseif eventName == "luaOnAnimationDone" then
        WelfareGoldPage:onAnimationDone(container);
    end
end

-- 添加SPINE动画
function WelfareGoldPage:showRoleSpine()
    local heroNode = self.container:getVarNode("mSpineNode")
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width, height = visibleSize.width, visibleSize.height
        local rate = visibleSize.height / visibleSize.width
        local desighRate = 1280 / 720
        rate = rate / desighRate
        heroNode:removeAllChildren()

        local roldData = ConfigManager.getRoleCfg()[4]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        local m_NowSpine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(m_NowSpine, "CCNode")
        heroNode:addChild(spineToNode)

        local spinePosOffset = "0,0"
        local spineScale = 0.5
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineToNode:setScale(spineScale)
        m_NowSpine:runAnimation(1, "Stand", -1)
    end
end

function WelfareGoldPage:refreshPage()
    NodeHelper:setStringForLabel(self.container, { mDiamondText = SaveServerData.needGold });
end

-- 更新金币
function WelfareGoldPage:updateGold()
    UserInfo.sync()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

-- 点击的回调
function WelfareGoldPage:onDiamond()
    if not SaveServerData.canPlay then
        -- 已经完成
        NodeHelper:setNodesVisible(self.container, { mCanUseNode = SaveServerData.canPlay, mCannotUseNode = not SaveServerData.canPlay })
    elseif UserInfo.playerInfo.gold < SaveServerData.needGold then
        -- 充值
        self:rechargePageFlag('@HintTitle', '@LackGold');
    elseif UserInfo.playerInfo.gold >= SaveServerData.needGold and SaveServerData.canPlay then
        _NeedGold = SaveServerData.needGold
        _MyGold = UserInfo.playerInfo.gold;
        self:requestServerData(RequestNumber.requestData);
    end
end

function WelfareGoldPage:rechargePageFlag(titleDic, descDic)
    local title = common:getLanguageString(titleDic)
    local message = common:getLanguageString(descDic)
    PageManager.showConfirm(title, message,
    function(agree)
        if agree then
            -- 钻石不足充值
            libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "ActivityWelfareGoldPage_enter_rechargePage")
            PageManager.pushPage("RechargePage");
        end
    end
    )
end

function WelfareGoldPage:onReceiveMessage(eventName, container)

end

function WelfareGoldPage:onExecute(ParentContainer)
    self:onTimer();
end

-- 奖励获得的金币奖励动画
function WelfareGoldPage:createScheduler(num)
    changeIdx = 0;
    _CountTimer = 0;
    _CountNum = 1;
    handler = 0;
    local mTimer = 15;
    local gold = tostring(num);
    local isFirstFlag = true;
    local length = string.len(gold);
    local reward = { };
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = (_MyGold - _NeedGold) });
    for j = 1, 6 do
        -- 计算获得金币的数量位数
        if j <= length then
            reward[j] = string.sub(gold, length - j + 1, length - j + 1);
        else
            -- 如果没有则为0
            reward[j] = 0;
        end
    end
    NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
    NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = true, mSuitTenTimes = true, mDiamondText = true })
    handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( function()
        -- UI\Common\Activity\Act_TL_Welfare
        local sprite2Img = { };
        for i = _CountNum, 6 do
            sprite2Img["mNumPic" .. i] = "Activity_NumImage_" .. changeIdx .. ".png";
        end
        NodeHelper:setSpriteImage(self.container, sprite2Img);
        changeIdx = changeIdx + 1;
        _CountTimer = _CountTimer + 1;
        if changeIdx > 9 then
            changeIdx = 0;
        end
        if (_CountTimer >(mTimer * 2) and isFirstFlag) or(not isFirstFlag and _CountTimer >= mTimer) then
            -- 两秒钟
            if isFirstFlag then
                -- 区分第一次
                isFirstFlag = false;
            end
            _CountTimer = 0;
            isFirstFlag = false;
            self:addAniChild(_CountNum);
            NodeHelper:setSpriteImage(self.container, { ["mNumPic" .. _CountNum] = "Activity_NumImage_" .. reward[_CountNum] .. ".png" });
            _CountNum = _CountNum + 1;
            self.container:runAnimation("Get")
        end
        if _CountNum > length or _CountNum > 6 then
            -- 动画结束
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handler)
            local sprite2Img = { }
            for i = _CountNum, 6 do
                -- 其他的设置为0
                sprite2Img["mNumPic" .. i] = "Activity_NumImage_0.png";
            end
            NodeHelper:setSpriteImage(self.container, sprite2Img);
            WelfareGoldPage:updateGold()
            self.container:runAnimation("End")

            CCLuaLog("SaveServerData.canPlay 1:" .. tostring(SaveServerData.canPlay))

            if not SaveServerData.canPlay then
                -- 已经完成
                NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
                NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = true, mSuitTenTimes = true, mDiamondText = true })
            else
                NodeHelper:setMenuItemEnabled(self.container, "mDiamond", true)
                NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = false, mSuitTenTimes = false, mDiamondText = false })
            end
            NodeHelper:setNodesVisible(self.container, { mCanUseNode = SaveServerData.canPlay, mCannotUseNode = not SaveServerData.canPlay })
            handler = 0;
        end
    end , 0.01, false);
end

function WelfareGoldPage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "End" then
        WelfareGoldPage:pushRewardPage()
    end
end

-- 弹出奖励
function WelfareGoldPage:pushRewardPage()
    if SaveServerData.getGold > 0 then
        local rewardItems = common:parseItemWithComma(SaveServerData.rewards)
        local CommonRewardPage = require("CommonRewardPage")
        CommonRewardPageBase_setPageParm(rewardItems, true)
        -- , msg.rewardType
        PageManager.pushPage("CommonRewardPage")
    end
end

-- 添加两个动画节点
function WelfareGoldPage:addAniChild(index)
    if SaveAnimationStar["aniStar_" .. index] == nil then
        -- 星星动画节点
        SaveAnimationStar["aniStar_" .. index] = ScriptContentBase:create("Act_TimeLimitWelfareContentEffect.ccbi")
        local rightNode = self.container:getVarNode("mNumber" .. index)
        rightNode:addChild(SaveAnimationStar["aniStar_" .. index])
        -- SaveAnimationStar["aniStar_"..index]:runAnimation("Get")
        SaveAnimationStar["aniStar_" .. index]:release();
    else
        SaveAnimationStar["aniStar_" .. index]:runAnimation("Get")
    end
end

function WelfareGoldPage:analysisServerData(msg)
    SaveServerData = { };
    SaveServerData.needGold = msg.cost;
    SaveServerData.canPlay = msg.canPlay;
    SaveServerData.getGold = msg.gold;
    WelfareGoldPage.RemainTime = msg.leftTime;
    SaveServerData.rewards = "10000_1001_" .. msg.gold;


    CCLuaLog("SaveServerData.canPlay 2:" .. tostring(SaveServerData.canPlay))
    CCLuaLog("SaveServerData.canPlay 3:" .. tostring(SaveServerData.canPlay))
    CCLuaLog("SaveServerData.getGold 3:" .. tostring(SaveServerData.getGold))
    CCLuaLog("SaveServerData.showTime 3:" .. tostring(showTime) .. "   RemainTime:" .. tostring(WelfareGoldPage.RemainTime))

    if SaveServerData.getGold > 0 then
        -- self:createScheduler(SaveServerData.getGold);
        WelfareGoldPage:pushRewardPage()
        --self:updateGold()
        if not SaveServerData.canPlay then
            -- 已经完成
            NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
            NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = true, mSuitTenTimes = true, mDiamondText = true })
        else
            NodeHelper:setMenuItemEnabled(self.container, "mDiamond", true)
            NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = false, mSuitTenTimes = false, mDiamondText = false })
        end

    elseif not SaveServerData.canPlay then
        -- 已经完成
        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", false)
        NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = true, mSuitTenTimes = true, mDiamondText = true })
    elseif SaveServerData.canPlay then
        NodeHelper:setMenuItemEnabled(self.container, "mDiamond", true)
        NodeHelper:setNodeIsGray(self.container, { mDiamondIcon = false, mSuitTenTimes = false, mDiamondText = false })
    end
    if showTime < WelfareGoldPage.RemainTime then
        WelfareGoldPage.RemainTime = -1;
        NodeHelper:setNodesVisible(self.container, { mTimeNode = false });
    end

    NodeHelper:setNodesVisible(self.container, { mCanUseNode = SaveServerData.canPlay, mCannotUseNode = not SaveServerData.canPlay })

    -- 如果当钱不够或者最后阶段的时候不显示红点
    if not SaveServerData.canPlay or UserInfo.playerInfo.gold < SaveServerData.needGold then
        ActivityInfo.changeActivityNotice(106)
        -- 隐藏红点
    end
    self:refreshPage();
end

-- 计算倒计时
function WelfareGoldPage:onTimer()
    if WelfareGoldPage.RemainTime == -1 then
        -- 活动剩余时间
        return;
    end
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if WelfareGoldPage.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd");
            NodeHelper:setStringForLabel(self.container, { mTanabataCD = endStr })
        elseif WelfareGoldPage.RemainTime < 0 then
            NodeHelper:setStringForLabel(self.container, { mTanabataCD = "" })
        else
            TimeCalculator:getInstance():createTimeCalcultor(self.timerName, WelfareGoldPage.RemainTime)
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
    if remainTime <= 0 then
        -- 倒计时完毕重新请求
        WelfareGoldPage.RemainTime = -1;
        local endStr = common:getLanguageString("@ActivityEnd");
        TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = endStr });
    else
        local timeStr = common:second2DateString(remainTime, false);
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = common:getLanguageString("@SurplusTimeFishing") .. timeStr });
    end

end

function WelfareGoldPage:requestServerData(type)
    local msg = Activity3_pb.WelfareRewardReq();
    msg.type = type;
    common:sendPacket(opcodes.WELFARE_REWARD_C, msg, true);
end


function WelfareGoldPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode()
    local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.WELFARE_REWARD_S then
        local msg = Activity3_pb.WelfareRewardRes();
        msg:ParseFromString(msgBuff);
        self:analysisServerData(msg);
        self:updateGold()
    end
end

function WelfareGoldPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end

function WelfareGoldPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end

function WelfareGoldPage:onExit(ParentContainer)
    if handler ~= 0 then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(handler);
        handler = 0;
    end
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    self:removePacket(ParentContainer);
    onUnload(thisPageName, self.container);
end

return WelfareGoldPage
