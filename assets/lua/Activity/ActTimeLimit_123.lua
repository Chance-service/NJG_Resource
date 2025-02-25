-- 活动id = 123           ----a-sdfasdfasdfasdfasdfasdfasdfsdf
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActTimeLimit_123"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local ResManagerForLua = require("ResManagerForLua")
local mConstCount = 0
local mCurrentRoleNumber = -1
local mMaxRoleNumber = -1
local CAN_REWARD_INDEX = {
    [1] = { 1, 2, 3, 7 },
    [2] = { 4, 5, 6, 8 },
    [3] = { 7, 8, 9, 1 },
    [4] = { 1, 4, 7, 6 },
    [5] = { 2, 5, 8, 1 },
    [6] = { 3, 6, 9, 4 },
    [7] = { 1, 5, 9, 2 },
    [8] = { 3, 5, 7, 6 },
}

local NO_REWARD_INDEX = {
    [1] = { 1, 2, 4, 5 },
    [2] = { 2, 3, 4, 5 },
    [3] = { 2, 5, 6, 9 },
    [4] = { 4, 6, 7, 9 },
    [5] = { 1, 7, 9, 2 },
    [6] = { 1, 5, 8, 7 },
    [7] = { 2, 5, 6, 9 },
    [8] = { 1, 4, 5, 8 },
}


local _MercenaryInfo = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = { }

local mDrawRewardTyep = 1  -- 抽奖类型 
local mIsAnimationInProgress = false    -- 是不是正在执行动画 如果是的话按钮不能点击了
local ActTimeLimit_123 = { }
local mRewardPosition = { }
local mMoveSprite = nil
local mScorePoolItem = { }
local mPosIndexData = { }               -- 剩下可移动的位置
local mItemLastTimeIndexPos = { }   -- 奖励上一次的位置索引
local ONE_COUNT_SCORE_REWARD = 100     -- 多少积分抽一次奖
local mCurrentMoveIndex = 0 -- 当前移动的item
local mMoveTime = 0.2
local mMaxMoveCount = 5
local mCurretnMoveCount = 0
local mEndPosIndexData = { }     -- 结束的位置
local mLastMoveItem = { }
local option = {
    ccbiFile = "Act_TimeLimit_123.ccbi",
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
    ACTIVITY123_UR_INFO_C = HP_pb.ACTIVITY123_UR_INFO_C,
    -- 界面信息返回
    ACTIVITY123_UR_INFO_S = HP_pb.ACTIVITY123_UR_INFO_S,
    -- 抽奖请求
    ACTIVITY123_UR_DRAW_C = HP_pb.ACTIVITY123_UR_DRAW_C,
    -- 抽奖返回
    ACTIVITY123_UR_DRAW_S = HP_pb.ACTIVITY123_UR_DRAW_S,
    -- 积分抽奖请求
    ACTIVITY123_UR_LOTTERY_C = HP_pb.ACTIVITY123_UR_LOTTERY_C,
    -- 积分抽奖返回
    ACTIVITY123_UR_LOTTERY_S = HP_pb.ACTIVITY123_UR_LOTTERY_S,
    -- 副将信息请求
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    -- 副将信息返回
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
}

local TreasureRaiderDataHelper = {
    RemainTime = 0,
    -- 活动剩余时间
    showItems = { },
    -- 长度为0代表没有奇遇宝箱，有值代表有奇遇宝箱
    freeTreasureTimes = 0,
    -- 免费CD
    leftTreasureTimes = 0,
    --
    onceCostGold = 0,
    -- 一次消耗钻石
    tenCostGold = 0,
    -- 抽十次消耗钻石
    resetCostGold = 0,
    -- 重置积分奖池消耗钻石
    randCostGold = 0,
    -- 随机抽卡消耗钻石
    leftAwardTimes = 0,
    -- 必定获得奖励剩余次数
    reward = "",
    -- 获得的奖励
    TreasureRaiderConfig = nil,
    -- config数据
    lotterypoint = 0,
    -- 当前拥有的积分
    comluckey = 0,
    -- 积分抽奖消耗的奖励
    scoreRewardState = 0,
    -- 积分奖池是否中奖状态  1 中奖   0 没中奖

    excInfo = ""-- 积分奖池奖励  如果副将碎片已经够的话就显示这个奖励， 如果不够的话还显示奖池的奖励
}

ActTimeLimit_123.timerName = "Activity_ActTimeLimit_123"
ActTimeLimit_123.timerLabel = "mTanabataCD"
ActTimeLimit_123.timerKeyBuff = "Activity_ActTimeLimit_123_Timer_Key_Buff"
ActTimeLimit_123.timerFreeCD = "Activity_ActTimeLimit_123_Timer_Free_CD"

function ActTimeLimit_123:onEnter(parentContainer)
    math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_ActTimeLimit_123(container)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    local scale = NodeHelper:getScaleProportion()
    if scale <= 1 then
        scale = scale - scale % 0.1
        local sp_1 = container:getVarSprite("mImage_1")
        sp_1:setScale(scale)

        --local sp_2 = container:getVarSprite("mImage_2")
        --sp_2:setScale(scale)
    end
    if scale < 1 then
        local mRollNode = container:getVarNode("mRollNode")
        NodeHelper:autoAdjustResetNodePosition(mRollNode, -0.5)
    end
    NodeHelper:setNodesVisible(self.container, { mBtmNode = false, mLuckDrawNode = false })

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    self:initUi(container)

    return container
end

function ActTimeLimit_123:initData()
    mCurrentMoveIndex = 1

    mScorePoolItem = { }

    mDrawRewardTyep = mDrawTyep.Type_1

    mRewardPosition = { }

    if mItemLastTimeIndexPos == nil or #mItemLastTimeIndexPos == 0 then
        mItemLastTimeIndexPos = NO_REWARD_INDEX[math.random(1, #NO_REWARD_INDEX)]
        -- 从mPosIndexData删除mItemLastTimeIndexPos
    end

    self:initPosIndexData()

    -- 副将信息
    MercenaryCfg = ConfigManager.getRoleCfg()
    -- 本期抽奖可以获得的副将
    _MercenaryInfo = ConfigManager.getReleaseURdrawMercenary123Cfg()[1]
    -- 本期抽奖可以获得的奖励
    TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getReleaseURdrawReward123Cfg() or { }


    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

end

function ActTimeLimit_123:initPosIndexData()
    mPosIndexData = { }
    for i = 1, 9 do
        local bl = self:isContain(mItemLastTimeIndexPos, i)
        if not bl then
            self:addPosIndex(i)
        end
    end
end

function ActTimeLimit_123:initUi(container)
    NodeHelper:setNodesVisible(container, { mMoveSprite = false })
    for i = 1, 9 do
        local node = container:getVarNode("mRewardNode_" .. i)
        local x, y = node:getPosition()
        mRewardPosition[i] = ccp(x, y)
        -- 9个格子的位置
        node:removeAllChildren()
        local bgSprite = CCSprite:create("Activity_common_diban_6.png")
        node:addChild(bgSprite)
        -- 先加个底背景进来
    end
    self:initScoreRewardItemPosition()
    self:initSpine(container)
    NodeHelper:setSpriteImage(container, { mImage_1 = MercenaryCfg[_MercenaryInfo.itemId].namePic })
    NodeHelper:setSpriteImage(container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[_MercenaryInfo.itemId].quality] })
end

-- 得到下一个移动到的位置索引
function ActTimeLimit_123:getPosIndex(index)
    local randNum = index or math.random(1, #mPosIndexData)
    return table.remove(mPosIndexData, randNum)

end

-- 添加移动位置索引
function ActTimeLimit_123:addPosIndex(index)
    table.insert(mPosIndexData, index)
end

function ActTimeLimit_123:setRollItemData(item, data, index)
    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")
    -- local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")

    iconSprite:setTexture(data.icon)
    numLabel:setString("x" .. GameUtil:formatNumber(data.count))
    -- numLabel:setString("" .. index)
    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)
end

function ActTimeLimit_123:getPageInfo(container)
    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.ACTIVITY123_UR_INFO_C)
    --- 请求副将信息
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end

-- 刷新UR抽奖界面
function ActTimeLimit_123:refreshURPage(container)
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

    local label2Str = {
        -- 设置玩家金币数量
        mDiamondNum = UserInfo.playerInfo.gold,
        -- 多少次后必得什么奖励
        mTitle = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount),
        --  一次价格
        mPrice_1 = TreasureRaiderDataHelper.onceCostGold,
        --  十次价格
        mPrice_2 = TreasureRaiderDataHelper.tenCostGold,
        --  随机价格
        mPrice_3 = TreasureRaiderDataHelper.randCostGold,

        m1Label_1 = common:getLanguageString("@RouletteLeftTimes",1),

        mLabel_1 = common:getLanguageString("@RouletteLeftTimes",1),

        mLabel_2 = common:getLanguageString("@RouletteLeftTimes",_MercenaryInfo.maxDrawCount),

        mLabel_3 = common:getLanguageString("@ReleaseURdrawMercenaryDesc",_MercenaryInfo.randmoDrawMinCount,_MercenaryInfo.maxDrawCount),

        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),

        mScoreNumLable = TreasureRaiderDataHelper.lotterypoint .. " / " .. ONE_COUNT_SCORE_REWARD,
        -- 当前积分  /  抽一次的积分
    }

    NodeHelper:setStringForLabel(container, label2Str)

    -- 设置节点是否显示
    NodeHelper:setNodesVisible(container, {
        mFreelabel = TreasureRaiderDataHelper.freeTreasureTimes == 0,
        mBtnPriceNode_1 = TreasureRaiderDataHelper.freeTreasureTimes ~= 0,
        mFreeTimeCDNode = TreasureRaiderDataHelper.freeTreasureTimes ~= 0,
        mNormalBtn1TextNode = TreasureRaiderDataHelper.freeTreasureTimes == 0
    } )

    self:refreshScoreBtn(container)
end

function ActTimeLimit_123:initScoreRewardItemPosition()
    if mScorePoolItem == nil or #mScorePoolItem == 0 then
        for i = 1, 4 do
            local indexPos = mItemLastTimeIndexPos[i]
            local item = self:createRewardItem()
            local node = self.container:getVarNode("mRewardNode")
            node:addChild(item)
            item:setPosition(mRewardPosition[indexPos])
            item:setTag(tonumber(i .. indexPos))
            mScorePoolItem[i] = item
            local data = ResManagerForLua:getResInfoByTypeAndId(_MercenaryInfo.scorePoolReward.type, _MercenaryInfo.scorePoolReward.itemId, _MercenaryInfo.scorePoolReward.count)
            self:setRollItemData(item, data, i)
        end
    end
end

-- 刷新积分抽奖按钮状态
function ActTimeLimit_123:refreshScoreBtn(container)
    local bl = true
    if TreasureRaiderDataHelper.lotterypoint < ONE_COUNT_SCORE_REWARD then
        bl = false
    end
    local item = self.container:getVarMenuItemImage("mScoreBtn")
    item:setEnabled(bl)
    NodeHelper:setNodeIsGray(self.container, { mScoreBtnLabel = not bl, mScoreNumLable = not bl })
end

-- 刷新页面
function ActTimeLimit_123:refreshPage(container)
    self:refreshURPage(container)
end

-- 收包
function ActTimeLimit_123:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        -- 副将信息返回
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber()
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S then
        --
        -- msg = Activity2_pb.HPNewTreasureRaiderInfoSync()
        -- msg:ParseFromString(msgBuff)
        -- self:updateData(parentContainer, opcode, msg)
    elseif opcode == HP_pb.ACTIVITY123_UR_INFO_S or opcode == HP_pb.ACTIVITY123_UR_DRAW_S then
        -- 界面信息返回
        msg = Activity3_pb.Activity123Info()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)

    elseif opcode == HP_pb.ACTIVITY123_UR_LOTTERY_S then
        -- 积分抽奖返回
        msg = Activity3_pb.Activity123LotteryRep()
        msg:ParseFromString(msgBuff)

        -- 记录上一次碎片数量
        mCurrentRoleNumber = self:getCurrentRoleNumber()

        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        TreasureRaiderDataHelper.scoreRewardState = msg.status
        TreasureRaiderDataHelper.excInfo = msg.excInfo
        TreasureRaiderDataHelper.lotterypoint = TreasureRaiderDataHelper.lotterypoint - ONE_COUNT_SCORE_REWARD
        -- 刷新积分
        self:refreshScore(TreasureRaiderDataHelper.lotterypoint)
        -- 刷新积分按钮状态
        self:refreshScoreBtn(self.container)

        mEndPosIndexData = { }
        if TreasureRaiderDataHelper.scoreRewardState == 1 then
            local index = math.random(1, #CAN_REWARD_INDEX)
            mEndPosIndexData = CAN_REWARD_INDEX[index]
            CCLuaLog("------------------------AAAAAAAAAAAAA   " .. index)
        else
            local index = math.random(1, #NO_REWARD_INDEX)
            mEndPosIndexData = NO_REWARD_INDEX[index]
            CCLuaLog("------------------------BBBBBBBBBBBBBBB   " .. index)
        end

        self:showScoreAnimation()
    end
end

-- 显示积分抽奖过程
function ActTimeLimit_123:showScoreAnimation()
    mIsAnimationInProgress = true
    mMaxMoveCount = math.random(2, 4)
    -- 积分抽奖过程
    mCurrentMoveIndex = 1
    mCurretnMoveCount = 0
    -- self:popUpRewardPage()
    self:showAnimation()
end

-- 正常动画
function ActTimeLimit_123:showAnimation()

    local itemNode = mScorePoolItem[mCurrentMoveIndex]
    local itemTag = itemNode:getTag()
    local itemIndex = math.modf(itemTag / 10)
    local itemCurPosIndex = itemTag % 10

    -- 得到下一个位置索引
    local nextPosIndex = self:getPosIndex()
    -- 把当前位置索引放回去
    self:addPosIndex(itemCurPosIndex)

    CCLuaLog("====>> mCurrentMoveIndex =  " .. mCurrentMoveIndex .. "   =====>>  itemCurPosIndex = " .. itemCurPosIndex .. "   ===>>  nextPosIndex =  " .. nextPosIndex)

    itemNode:setTag(tonumber(itemIndex .. nextPosIndex))
    local moveTo = CCMoveTo:create(mMoveTime, mRewardPosition[nextPosIndex])
    local CallFuncN = CCCallFuncN:create( function(node)
        local itemTag = node:getTag()
        local itemCurPosIndex = itemTag % 10
        node:setPosition(mRewardPosition[itemCurPosIndex])

        mCurrentMoveIndex = mCurrentMoveIndex + 1
        if mCurrentMoveIndex > 4 then
            mCurrentMoveIndex = 1
            mCurretnMoveCount = mCurretnMoveCount + 1
        end

        if mCurretnMoveCount == mMaxMoveCount then
            mCurrentMoveIndex = 1
            mLastMoveItem = self:AAAAAA()
            self:endAnimation()
        else
            self:showAnimation()
        end
    end )
    local Array = CCArray:create()
    Array:addObject(moveTo)
    Array:addObject(CallFuncN)
    local Sequence = CCSequence:create(Array)
    itemNode:runAction(Sequence)
end

-- 结束动作
function ActTimeLimit_123:endAnimation()
    if #mLastMoveItem == 0 then
        self:resultAnimation()
    end

    local itemNode = mLastMoveItem[mCurrentMoveIndex]
    local itemTag = itemNode.item:getTag()
    local itemIndex = math.modf(itemTag / 10)
    local itemCurPosIndex = itemTag % 10
    local nextPosIndex = itemNode.posIndex
    self:addPosIndex(itemCurPosIndex)
    if itemNode then
        itemNode.item:setTag(tonumber(itemIndex .. nextPosIndex))
    end

    local moveTo = CCMoveTo:create(mMoveTime, mRewardPosition[nextPosIndex])
    local CallFuncN = CCCallFuncN:create( function(node)
        local itemTag = node:getTag()
        local itemCurPosIndex = itemTag % 10
        node:setPosition(mRewardPosition[itemCurPosIndex])
        mCurrentMoveIndex = mCurrentMoveIndex + 1
        if mCurrentMoveIndex > #mLastMoveItem then
            -- 显示奖励
            self:resultAnimation()
        else
            self:endAnimation()
        end
    end )
    local Array = CCArray:create()
    Array:addObject(moveTo)
    Array:addObject(CallFuncN)
    local Sequence = CCSequence:create(Array)
    if itemNode then
        itemNode.item:runAction(Sequence)
    end
end

-- 结果动作
function ActTimeLimit_123:resultAnimation()
    -- TODO   重置当前的位置信息
    mItemLastTimeIndexPos = { }
    for k, v in pairs(mScorePoolItem) do
        local itemTag = v:getTag()
        local itemCurPosIndex = itemTag % 10
        table.insert(mItemLastTimeIndexPos, itemCurPosIndex)
    end
    self:initPosIndexData()

    if TreasureRaiderDataHelper.scoreRewardState == 1 then
        local node = self.container:getVarNode("mRewardNode")
        for i = 1, 3 do
            local sp = CCSprite:create("common_Image_4.png")
            sp:setTag(10000 + i)
            node:addChild(sp)
            sp:setZOrder(100)
            sp:setPosition(mRewardPosition[mEndPosIndexData[i]])
            local fadeOut = CCFadeOut:create(0.3)
            local fadeIn = CCFadeIn:create(0.3)
            sp:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(fadeOut, fadeIn)))
        end

        local delayTime = CCDelayTime:create(2)
        local CallFunc = CCCallFuncN:create( function()
            self:popUpRewardPage()
            local node = self.container:getVarNode("mRewardNode")
            for i = 1, 9 do
                local child = node:getChildByTag(10000 + i)
                if child then
                    node:removeChild(child, true)
                end
            end
        end )
        local Array = CCArray:create()
        Array:addObject(delayTime)
        Array:addObject(CallFunc)
        local Sequence = CCSequence:create(Array)
        self.container:runAction(Sequence)
    else
        self:popUpRewardPage()
    end
    -- self:popUpRewardPage()
end

function ActTimeLimit_123:AAAAAA()
    local t = { }
    for k, v in pairs(mScorePoolItem) do
        local itemTag = v:getTag()
        local itemIndex = math.modf(itemTag / 10)
        local itemCurPosIndex = itemTag % 10
        if not self:isContain(mEndPosIndexData, itemCurPosIndex) then
            -- 不在目标位置数据里面
            -- 从mEndPosIndexData里面找到没有被占用的位置
            local targetIndex = self:getTargetPosIndex()
            if targetIndex ~= 0 then
                table.insert(t, { posIndex = self:getPosIndex(targetIndex), item = v })
            else
                return t
            end
        end
    end
    return t
end

function ActTimeLimit_123:getTargetPosIndex()
    for i = 1, #mPosIndexData do
        for k = 1, #mEndPosIndexData do
            if mPosIndexData[i] == mEndPosIndexData[k] then
                return i
            end
        end
    end
    return 0
end


function ActTimeLimit_123:getEndPosIndex(index)

    if #mEndPosIndexData == 0 then
        return nil
    end
    local n = table.remove(mEndPosIndexData, 1)
    local index = 0
    for i = 1, #mPosIndexData do
        if mPosIndexData[i] == n then
            index = i
        end
    end
    if index == 0 then
        return self:getEndPosIndex()
    else
        return self:getPosIndex(index)
    end
end


function ActTimeLimit_123:popUpRewardPage()
    mIsAnimationInProgress = false
    if TreasureRaiderDataHelper.scoreRewardState == 1 then
        -- TODO这里请求碎片数量

        local changeData = ConfigManager.parseItemOnlyWithUnderline(TreasureRaiderDataHelper.excInfo)
        local roleChipCount = _MercenaryInfo.scorePoolReward.count
        local n = mMaxRoleNumber - mCurrentRoleNumber - roleChipCount
        local rewardData = nil
        if n >= 0 then
            -- 显示碎片
            rewardData = _MercenaryInfo.scorePoolReward
        else
            n = math.abs(n)
            local type = changeData.type
            local itemId = changeData.itemId
            local count = changeData.count * roleChipCount
            local str = type .. "_" .. itemId .. "_" .. count
            rewardData = ConfigManager.parseItemOnlyWithUnderline(str)
        end
        if rewardData then
            -- 中奖了 显示奖励面板
            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm( { rewardData }, true, nil, nil)
            PageManager.pushPage("CommonRewardPage")
        end
    end
end

-- 刷新积分
function ActTimeLimit_123:refreshScore(comluckey)
    if comluckey < 0 then
        comluckey = 0
    end
    local label2Str = {
        mScoreNumLable = comluckey .. " / " .. ONE_COUNT_SCORE_REWARD,-- 当前积分  /  抽一次的积分
    }
    NodeHelper:setStringForLabel(self.container, label2Str)
end

function ActTimeLimit_123:updateData(parentContainer, opcode, msg)
    NodeHelper:setNodesVisible(self.container, { mBtmNode = true, mLuckDrawNode = true })

    TreasureRaiderDataHelper.RemainTime = msg.leftTime or 0
    TreasureRaiderDataHelper.showItems = msg.items or { }
    TreasureRaiderDataHelper.freeTreasureTimes = msg.freeCD or 0
    TreasureRaiderDataHelper.onceCostGold = msg.onceCostGold or 0
    TreasureRaiderDataHelper.tenCostGold = msg.tenCostGold or 0
    TreasureRaiderDataHelper.randCostGold = msg.randCostGold or 0
    TreasureRaiderDataHelper.buf_multiple = msg.buf_multiple or 1
    TreasureRaiderDataHelper.leftBuffTimes = msg.leftBuffTimes or 0
    TreasureRaiderDataHelper.leftAwardTimes = msg.leftAwardTimes or 10
    TreasureRaiderDataHelper.reward = { }
    TreasureRaiderDataHelper.lotterypoint = msg.lotterypoint or 0
    -- 当前的ur抽卡积分
    TreasureRaiderDataHelper.resetCostGold = msg.lotteryCost or 100

    for i = 1, #msg.reward do
        -- 抽一次   抽十次获得的奖励
        TreasureRaiderDataHelper.reward[i] = msg.reward[i]
    end
    if opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.ACTIVITY123_UR_INFO_S then

    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S or opcode == HP_pb.ACTIVITY123_UR_DRAW_S then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)

        local rewardItems = { }
        for k, v in pairs(TreasureRaiderDataHelper.reward) do
            local _type, _id, _count = unpack(common:split(v, "_"))
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } )
        end

        self:pushRewardPage()
    end
    if TreasureRaiderDataHelper.freeTreasureTimes ~= 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end
    self:refreshPage(self.container)
end


function ActTimeLimit_123:pushRewardPage()
    local data = { }
    data.freeCd = TreasureRaiderDataHelper.freeTreasureTimes
    data.onceGold = TreasureRaiderDataHelper.onceCostGold
    data.tenGold = TreasureRaiderDataHelper.tenCostGold
    data.itemId = nil
    data.rewards = TreasureRaiderDataHelper.reward

    local isFree = data.freeCd == 0

    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", false, ActTimeLimit_123.onBtnClick_1, ActTimeLimit_123.onBtnClick_2, function()
            if #TreasureRaiderDataHelper.reward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end, nil, nil, 1, nil )
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", true, ActTimeLimit_123.onBtnClick_1, ActTimeLimit_123.onBtnClick_2, nil, nil, nil, 1, nil)
    end
end



function ActTimeLimit_123:isContain(t, n)
    for k, v in pairs(t) do
        if v == n then
            return true, k
        end
    end
    return false, k
end


function ActTimeLimit_123:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_123:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_123:onExecute(parentContainer)
    self:onTimer(self.container)
end

function ActTimeLimit_123:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if TreasureRaiderDataHelper.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr, mFreeTimeCDLabel = endStr })
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = false,
                mNoBuf = false
            } );
        elseif TreasureRaiderDataHelper.RemainTime < 0 then
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = "" })
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    if remainTime + 1 > TreasureRaiderDataHelper.RemainTime then
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
        elseif timerFreeCD == -1 then
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
            NodeHelper:setStringForLabel(container, { mFreeTimeCDLabel = "" })
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = true,
            } )
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

function ActTimeLimit_123:onExit(parentContainer)
    local node = self.container:getVarNode("mRewardNode")
    if node then
        node:removeAllChildren()
    end
    self.container:stopAllActions()

    mIsAnimationInProgress = false
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
    local spineNode = self.container:getVarNode("mSpine")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    MercenaryCfg = nil
    onUnload(thisPageName, self.container)
end

function ActTimeLimit_123:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode");
    -- local spinePosOffset = "-120,20"
    -- local spineScale = 0.7
    local spinePosOffset = _MercenaryInfo.offset
    local spineScale = _MercenaryInfo.scale

    local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo.itemId]
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
            NodeHelper:autoAdjustResetNodePosition(spineNode, -0.5)
            --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"), 0.5)
        elseif scale < 1 then
           NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
        end
    end
end


-- 更新佣兵碎片数量
function ActTimeLimit_123:updateMercenaryNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt", MercenaryCfg[_MercenaryInfo.itemId].name) .. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount });
            -- mCurrentRoleNumber = MercenaryRoleInfos[i].soulCount
            mMaxRoleNumber = MercenaryRoleInfos[i].costSoulCount
            break;
        end
    end
end

function ActTimeLimit_123:getCurrentRoleNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            return MercenaryRoleInfos[i].soulCount
        end
    end
end


function ActTimeLimit_123:onBtnClick_1(container)
    if mIsAnimationInProgress then return end
    if TreasureRaiderDataHelper.onceCostGold == 0 then return end


    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes ~= 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_1
    local msg = Activity3_pb.Activity123Draw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY123_UR_DRAW_C, msg)
end

function ActTimeLimit_123:onBtnClick_2(container)

    if mIsAnimationInProgress then return end

    if TreasureRaiderDataHelper.tenCostGold == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_10
    local msg = Activity3_pb.Activity123Draw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY123_UR_DRAW_C, msg)
end


-- 积分抽奖事件
function ActTimeLimit_123:onScoreClick(container)
    if TreasureRaiderDataHelper.lotterypoint < 10 then
        -- TODO提示积分不够
        -- MessageBoxPage:Msg_Box_Lan("@bindsuccess")
        return
    end

    if mIsAnimationInProgress then return end
    local msg = Activity3_pb.ReleaseURLotteryReq()
    common:sendPacket(HP_pb.ACTIVITY123_UR_LOTTERY_C, msg)
end

function ActTimeLimit_123:onIllustatedOpen(container)
    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(_MercenaryInfo.itemId)
end

function ActTimeLimit_123:onRewardPreview(container)

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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_ACT_123)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end


function ActTimeLimit_123:createRewardItem(index)
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
TreasureRaiderPageNew = CommonPage.newSub(ActTimeLimit_123, thisPageName, option)

return ActTimeLimit_123