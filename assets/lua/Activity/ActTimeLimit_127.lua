-- 活动id = 127      武器召唤师
local NodeHelper = require("NodeHelper")
local Activity4_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local thisPageName = "ActTimeLimit_127"
local ConfigManager = require("ConfigManager")

-- 十次必中数据
local mMustBeItemData = nil
local mConfigData = nil
local mDrawRewardTyep = 1  -- 抽奖类型 
local mIsAnimationInProgress = false    -- 是不是正在执行动画 如果是的话按钮不能点击了
local ActTimeLimit_127 = { }
local option = {
    ccbiFile = "Act_TimeLimit_127.ccbi",
    handlerMap =
    {
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",
        onBtnClick_1 = "onBtnClick_1",
        onBtnClick_2 = "onBtnClick_2",
        onScoreClick = "onScoreClick",
    },
}

local mItemTag = {
    IconBgSprite = 1000,
    IconSprite = 2000,
    QualitySprite = 3000,
    NumLabel = 4000,
    Mask = 5000,
}

-- 抽奖类型
local mDrawTyep = {
    Type_1 = 1,
    Type_10 = 10,
    Type_Randmo = - 1
}

local opcodes = {
    -- 请求界面信息
    ACTIVITY127_UR_INFO_C = HP_pb.ACTIVITY127_UR_INFO_C,
    -- 界面信息返回
    ACTIVITY127_UR_INFO_S = HP_pb.ACTIVITY127_UR_INFO_S,
    -- 抽奖请求
    ACTIVITY127_UR_DRAW_C = HP_pb.ACTIVITY127_UR_DRAW_C,
    -- 抽奖返回
    ACTIVITY127_UR_DRAW_S = HP_pb.ACTIVITY127_UR_DRAW_S,
}
-- 111308 = 麒麟の聖櫃(紫) 111307 = 麒麟の聖櫃(赤)
local iconPath = { [111308] = "BG/Activity_127/Act_127_Image_2.png", [111307] = "BG/Activity_127/Act_127_Image_3.png" }

local mServerData = nil


ActTimeLimit_127.timerName = "Activity_ActTimeLimit_127"
ActTimeLimit_127.timerLabel = "mTanabataCD"
ActTimeLimit_127.timerKeyBuff = "Activity_ActTimeLimit_127_Timer_Key_Buff"
ActTimeLimit_127.timerFreeCD = "Activity_ActTimeLimit_127_Timer_Free_CD"

function ActTimeLimit_127:onEnter(parentContainer)
    math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_ActTimeLimit_127(container)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))
    local scale = NodeHelper:getScaleProportion()
    --    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    --    if s9Bg then
    --        s9Bg:setScaleY(scale)
    --    end
    if scale > 1 then

    end

    NodeHelper:setNodesVisible(self.container, { mBtmNode = false, mLuckDrawNode = false })

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    self:initUi(container)

    return container
end

function ActTimeLimit_127:initData()
    mServerData = { }
    mDrawRewardTyep = mDrawTyep.Type_1
    -- 本期抽奖可以获得的奖励
    mConfigData = ConfigManager.getReleaseURdrawReward127Cfg() or { }
    for k, v in pairs(mConfigData) do
        if v.type == 1 then
            mMustBeItemData = v.needRewardValue
            break
        end
    end

end

function ActTimeLimit_127:initUi(container)
    self:initSpine(container)
    NodeHelper:setSpriteImage(container, { mIconImage = iconPath[mMustBeItemData.itemId] }, { mIconImage = 1 })
end

function ActTimeLimit_127:getPageInfo(container)
    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.ACTIVITY127_UR_INFO_C)
end

-- 刷新UR抽奖界面
function ActTimeLimit_127:refreshURPage(container)
    if mServerData.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerName, mServerData.RemainTime)
    end
    if mServerData.freeTreasureTimes > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerFreeCD, mServerData.freeTreasureTimes)
    end
    if mServerData.leftBuffTimes > 0 then

        NodeHelper:setNodesVisible(container, {
            mTimes2 = mServerData.buf_multiple == multiple_x2,
            mTimes5 = mServerData.buf_multiple == multiple_x5,
        } )
        TimeCalculator:getInstance():createTimeCalcultor(self.timerKeyBuff, mServerData.leftBuffTimes)
    else

    end

    local label2Str = {
        -- 设置玩家金币数量
        mDiamondNum = UserInfo.playerInfo.gold,
        -- 多少次后必得什么奖励
        mActDouble = common:getLanguageString("@KingPalacePoolTimeLimitTxt6",mServerData.leftAwardTimes,common:getLanguageString(ConfigManager.getItemCfg()[mMustBeItemData.itemId].name),mMustBeItemData.count),
        --  一次价格
        mPrice_1 = mServerData.onceCostGold,
        --  十次价格
        mPrice_2 = mServerData.tenCostGold,
        --  随机价格
        mPrice_3 = mServerData.randCostGold,

        m1Label_1 = common:getLanguageString("@RouletteLeftTimes",1),

        mLabel_1 = common:getLanguageString("@RouletteLeftTimes",1),

        -- mLabel_2 = common:getLanguageString("@RouletteLeftTimes",_MercenaryInfo.maxDrawCount),

        -- mLabel_3 = common:getLanguageString("@ReleaseURdrawMercenaryDesc",_MercenaryInfo.randmoDrawMinCount,_MercenaryInfo.maxDrawCount),

        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),
    }

    NodeHelper:setStringForLabel(container, label2Str)

    -- 设置节点是否显示
    NodeHelper:setNodesVisible(container, {
        mFreelabel = mServerData.freeTreasureTimes <= 0,
        mBtnPriceNode_1 = mServerData.freeTreasureTimes > 0,
        mFreeTimeCDNode = mServerData.freeTreasureTimes > 0,
        mNormalBtn1TextNode = mServerData.freeTreasureTimes <= 0
    } )
end


-- 刷新页面
function ActTimeLimit_127:refreshPage(container)
    self:refreshURPage(container)
end

-- 收包
function ActTimeLimit_127:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ACTIVITY127_UR_INFO_S or opcode == HP_pb.ACTIVITY127_UR_DRAW_S then
        -- 界面信息返回
        msg = Activity4_pb.Activity127Info()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    end
end


function ActTimeLimit_127:updateData(parentContainer, opcode, msg)

    NodeHelper:setNodesVisible(self.container, { mBtmNode = true, mLuckDrawNode = true })

    mServerData.RemainTime = msg.leftTime or 0
    mServerData.showItems = msg.items or { }
    mServerData.freeTreasureTimes = msg.freeCD or 0
    mServerData.onceCostGold = msg.onceCostGold or 0
    mServerData.tenCostGold = msg.tenCostGold or 0
    mServerData.randCostGold = msg.randCostGold or 0
    mServerData.buf_multiple = msg.buf_multiple or 1
    mServerData.leftBuffTimes = msg.leftBuffTimes or 0
    mServerData.leftAwardTimes = msg.leftAwardTimes or 10
    mServerData.reward = { }
    mServerData.lotterypoint = msg.lotterypoint or 0
    -- 当前的ur抽卡积分
    mServerData.resetCostGold = msg.lotteryCost or 100

    for i = 1, #msg.reward do
        -- 抽一次   抽十次获得的奖励
        mServerData.reward[i] = msg.reward[i]
    end
    if opcode == HP_pb.ACTIVITY127_UR_INFO_S then

    elseif opcode == HP_pb.ACTIVITY127_UR_DRAW_S then
        local rewardItems = { }
        for k, v in pairs(mServerData.reward) do
            local _type, _id, _count = unpack(common:split(v, "_"))
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } )
        end

        self:pushRewardPage()
    end
    if mServerData.freeTreasureTimes > 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end
    self:refreshPage(self.container)
end

function ActTimeLimit_127:pushRewardPage()
    local data = { }
    data.freeCd = mServerData.freeTreasureTimes
    data.onceGold = mServerData.onceCostGold
    data.tenGold = mServerData.tenCostGold
    data.itemId = nil
    data.rewards = mServerData.reward
    local isFree = data.freeCd <= 0
    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", false, ActTimeLimit_127.onBtnClick_1, ActTimeLimit_127.onBtnClick_2, function()
            if #mServerData.reward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end )
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", true, ActTimeLimit_127.onBtnClick_1, ActTimeLimit_127.onBtnClick_2)
    end
end


function ActTimeLimit_127:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_127:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_127:onExecute(parentContainer)
    self:onTimer(self.container)
end

function ActTimeLimit_127:onTimer(container)
    if mServerData.RemainTime == nil then
        return
    end
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if mServerData.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr, mFreeTimeCDLabel = endStr })
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = false,
                mNoBuf = false
            } );
        elseif mServerData.RemainTime < 0 then
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = "" })
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    if remainTime + 1 > mServerData.RemainTime then
        return;
    end
    local timeStr = common:second2DateString(remainTime, false)
    NodeHelper:setStringForLabel(container, { [self.timerLabel] = common:getLanguageString("@SurplusTimeFishing") .. timeStr })
    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd")
        PageManager.popPage(thisPageName)
    end

    if TimeCalculator:getInstance():hasKey(self.timerFreeCD) then
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.timerFreeCD)
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false);
            NodeHelper:setStringForLabel(container, { mFreeTimeCDLabel = common:getLanguageString("@SuitShootFreeOneTime", timeStr) })
            NodeHelper:setNodesVisible(container, { mFreeTimeCDLabel = true })
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
            NodeHelper:setNodesVisible(container, {
                mFreeText = true,
                mCostNodeVar = false,
                mFreeTimeCDLabel = false,
            } )
            NodeHelper:setStringForLabel(container, { mFreeTimeCDLabel = common:getLanguageString("@ActivityEnd") })
        end
    end

    if TimeCalculator:getInstance():hasKey(self.timerKeyBuff) then
        local timerKeyBuff = TimeCalculator:getInstance():getTimeLeft(self.timerKeyBuff)
        if timerKeyBuff > 0 then
            timeStr = common:second2DateString(timerKeyBuff, false);
            NodeHelper:setStringForLabel(container, { mBuffCD = common:getLanguageString("@ActivityDays") .. timeStr })

        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
        end
    end
end

function ActTimeLimit_127:onExit(parentContainer)
    mIsAnimationInProgress = false
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
    local spineNode = self.container:getVarNode("mSpineNode")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    onUnload(thisPageName, self.container)
end

function ActTimeLimit_127:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode");
    local spinePosOffset = "-20,100"
    local spineScale = 1.05

    local roldData = ConfigManager.getRoleCfg()[175]
    if spineNode and roldData then
        local dataSpine = common:split((roldData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");
        spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

        local scale = NodeHelper:getScaleProportion()
        if scale > 1 then
            NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
            NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mEffectNode_1"), 0.5)
            NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mEffectNode_2"), 0.5)
        elseif scale < 1 then
            NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
            NodeHelper:setNodeScale(self.container, "mEffectNode_1", scale, scale)
            NodeHelper:setNodeScale(self.container, "mEffectNode_2", scale, scale)
        end
        -- NodeHelper:setNodesVisible(self.container, { mEffectNode_2 = false})
    end
end

function ActTimeLimit_127:onBtnClick_1(container)
    if mServerData == nil then return end
    if mIsAnimationInProgress then return end
    if mServerData.onceCostGold == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if mServerData.freeTreasureTimes > 0 and
        UserInfo.playerInfo.gold < mServerData.onceCostGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_1
    local msg = Activity4_pb.Activity127Draw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY127_UR_DRAW_C, msg)
end

function ActTimeLimit_127:onBtnClick_2(container)
    if mServerData == nil then return end
    if mIsAnimationInProgress then return end

    if mServerData.tenCostGold == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = mServerData.tenCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_10
    local msg = Activity4_pb.Activity127Draw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY127_UR_DRAW_C, msg)
end


-- 积分抽奖事件
function ActTimeLimit_127:onScoreClick(container)
    if mServerData == nil then return end
    if mServerData.lotterypoint < 10 then
        -- TODO提示积分不够
        -- MessageBoxPage:Msg_Box_Lan("@bindsuccess")
        return
    end

    --    if mIsAnimationInProgress then return end
    --    local msg = Activity4_pb.ReleaseURLotteryReq()
    --    common:sendPacket(HP_pb.ACTIVITY123_UR_LOTTERY_C, msg)
end

function ActTimeLimit_127:onIllustatedOpen(container)
    -- local FetterManager = require("FetterManager")
    -- FetterManager.showFetterPage(_MercenaryInfo.itemId)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setEquipLv(100, 4, 1, false, false)
    PageManager.pushPage("SuitDisplayPage");
end

function ActTimeLimit_127:onRewardPreview(container)
    require("NewSnowPreviewRewardPage")
    local TreasureCfg = mConfigData
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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_ACT_127)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end


function ActTimeLimit_127:createRewardItem(index)
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    -- bg
    node:addChild(bgSprite, 0, 1000)

    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    -- icon
    node:addChild(iconSprite, 1, mItemTag.IconSprite)

    --    local maskSprite = CCSprite:create("common_Image_3.png")
    --    -- 已领取遮罩
    --    node:addChild(maskSprite, 2, mItemTag.Mask)
    --    NodeHelper:setNodeVisible(maskSprite, false)

    local qualitySprite = CCSprite:create("common_ht_propK_bai.png")
    -- 品质框
    node:addChild(qualitySprite, 3, mItemTag.QualitySprite)

    -- local numTTFLabel = CCLabelTTF:create("x", "Barlow-SemiBold.ttf", 16)
    local numTTFLabel = CCLabelBMFont:create("x", "Lang/Font-HT-Button-White.fnt")
    numTTFLabel:setScale(0.55)
    -- 数量标签
    numTTFLabel:setAnchorPoint(ccp(1, 0))
    numTTFLabel:setPosition(ccp(38, -38))
    node:addChild(numTTFLabel, 3, mItemTag.NumLabel)

    -- node:setTag(10000 + index)
    return node
end

local CommonPage = require('CommonPage')
TreasureRaiderPageNew = CommonPage.newSub(ActTimeLimit_127, thisPageName, option)

return ActTimeLimit_127