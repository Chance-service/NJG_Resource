-- UR抽卡
local NodeHelper = require("NodeHelper")
local Activity2_pb = require("Activity2_pb")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActTimeLimit_121"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local ResManagerForLua = require("ResManagerForLua")
local _MercenaryInfo = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = { }
local COUNT_LIMIT = 10
local mConstCount = 0
local mDrawRewardTyep = 1  -- 抽奖类型 
local mIsAnimationInProgress = false    -- 是不是正在执行动画 如果是的话按钮不能点击了
local ActTimeLimit_121 = { }
local mMoveTime = 1
local mTargetRewardIndex = 0        -- 抽到的是第几个奖励 服务器发来的
local mCurrentRewardIndex = 0           -- 当前移动到的奖励  动画移动的
local mExcInfo = ""             -- 多余碎片的兑换信息
local mRewardPosition = { }

local mMoveSprite = nil

local mIsRunAction = false         -- 是不是可以执行动画

local mScorePoolItem = { }

local mRollItemRewardData = { }

local ONE_COUNT_SCORE_REWARD = 100     -- 多少积分抽一次奖
local mCurrentRoleNumber = -1
local mMaxRoleNumber = -1
local option = {
    ccbiFile = "Act_TimeLimit_121.ccbi",
    handlerMap =
    {
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",
        onBoxPreview = "onBoxPreview",
        onBtnClick_1 = "onBtnClick_1",
        onBtnClick_2 = "onBtnClick_2",
        onScoreClick = "onScoreClick",
        onResetClick = "onResetClick",
        -- onBtnClick_3 = "onBtnClick_3",
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
    NEW_TREASURE_RAIDER_INFO_S = HP_pb.NEW_TREASURE_RAIDER_INFO_S,
    NEW_TREASURE_RAIDER_SEARCH_S = HP_pb.NEW_TREASURE_RAIDER_SEARCH_S,
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
    RELEASE_UR_INFO3_C = HP_pb.RELEASE_UR_INFO3_C,
    RELEASE_UR_INFO3_S = HP_pb.RELEASE_UR_INFO3_S,
    RELEASE_UR_DRAW3_C = HP_pb.RELEASE_UR_DRAW3_C,
    RELEASE_UR_DRAW3_S = HP_pb.RELEASE_UR_DRAW3_S,


    RELEASE_UR_RESET3_C = HP_pb.RELEASE_UR_RESET3_C,
    -- 重置积分奖池请求
    RELEASE_UR_RESET3_S = HP_pb.RELEASE_UR_RESET3_S,
    -- 重置积分奖池返回
    RELEASE_UR_LOTTERY3_C = HP_pb.RELEASE_UR_LOTTERY3_C,
    -- 积分抽奖请求
    RELEASE_UR_LOTTERY3_S = HP_pb.RELEASE_UR_LOTTERY3_S,-- 积分抽奖返回
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
    lotteryindex = { },
    -- 积分奖池  已经抽取的奖品
    lastRewardTable = { },
    -- 积分奖池  还剩下的奖品
    comluckey = 0,-- 积分抽奖消耗的奖励
}

ActTimeLimit_121.timerName = "Activity_ActTimeLimit_121"
ActTimeLimit_121.timerLabel = "mTanabataCD"
ActTimeLimit_121.timerKeyBuff = "Activity_ActTimeLimit_121_Timer_Key_Buff"
ActTimeLimit_121.timerFreeCD = "Activity_ActTimeLimit_121_Timer_Free_CD"

function ActTimeLimit_121:onEnter(parentContainer)
    math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_ActTimeLimit_121(container)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    local scale = NodeHelper:getScaleProportion()
    if scale <= 1 then
        scale = scale - scale % 0.1
        local sp_1 = container:getVarSprite("mImage_1")
        sp_1:setScale(scale)

        local sp_2 = container:getVarSprite("mImage_2")
        sp_2:setScale(scale)
    end
    if scale < 1 then
        local mRollNode = container:getVarNode("mRollNode")
        NodeHelper:autoAdjustResetNodePosition(mRollNode, 0.5)
    end
    NodeHelper:setNodesVisible(self.container, { mBtmNode = false, mLuckDrawNode = false })

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    self:initUi(container)

    return container
end

function ActTimeLimit_121:initData()

    mScorePoolItem = { }

    mDrawRewardTyep = mDrawTyep.Type_1

    mRewardPosition = { }

    mCurrentRewardIndex = 1
    -- 副将信息
    MercenaryCfg = ConfigManager.getRoleCfg()
    -- 本期抽奖可以获得的副将
    _MercenaryInfo = ConfigManager.getReleaseURdrawMercenary121Cfg()[1]
    -- 本期抽奖可以获得的奖励
    TreasureRaiderDataHelper.TreasureRaiderConfig = ConfigManager.getReleaseURdrawReward121Cfg() or { }

    mRollItemRewardData = self:formatRollItemData()


    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

end

-- 用不用打乱积分奖池顺序？ 如果需要的话可能要服务器下发顺序
-- function funcname(args)
-- for k ,v in pairs(mRollItemRewardData) do
-- math.random(1 , #mRollItemRewardData)
-- end

-- end
function ActTimeLimit_121:initUi(container)


    mMoveSprite = container:getVarSprite("mMoveSprite")
    NodeHelper:setNodeVisible(mMoveSprite, false)

    for i = 1, 9 do
        local node = container:getVarNode("mRewardNode_" .. i)
        local x, y = node:getPosition()
        mRewardPosition[i] = ccp(x, y)
        node:removeAllChildren()

        local item = self:createRewardItem()
        node:addChild(item)

        mScorePoolItem[i] = item
    end

    for k, v in pairs(mScorePoolItem) do
        self:setRollItemData(v, self:getPoolRewardData(k))
    end

    self:initSpine(container)
    NodeHelper:setSpriteImage(container, { mNamePic = MercenaryCfg[_MercenaryInfo.itemId].namePic })

    NodeHelper:setSpriteImage(container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[_MercenaryInfo.itemId].quality] })
end

function ActTimeLimit_121:getPoolRewardData(index)
    return mRollItemRewardData[index]
end

function ActTimeLimit_121:setRollItemData(item, data)
    local iconBgSprite = tolua.cast(item:getChildByTag(mItemTag.IconBgSprite), "CCSprite")
    local iconSprite = tolua.cast(item:getChildByTag(mItemTag.IconSprite), "CCSprite")
    local qualitySprite = tolua.cast(item:getChildByTag(mItemTag.QualitySprite), "CCSprite")
    local numLabel = tolua.cast(item:getChildByTag(mItemTag.NumLabel), "CCLabelBMFont")
    local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")

    iconSprite:setTexture(data.icon)
    numLabel:setString("x" .. GameUtil:formatNumber(data.count))

    local colorStr = ConfigManager.getQualityColor()[data.quality].textColor
    local color3B = NodeHelper:_getColorFromSetting(colorStr)
    -- numLabel:setColor(color3B)

    local qualityImage = NodeHelper:getImageByQuality(data.quality)
    qualitySprite:setTexture(qualityImage)

    local iconBgImage = NodeHelper:getImageBgByQuality(data.quality)
    iconBgSprite:setTexture(iconBgImage)
end


-- 能不能更新积分奖池
function ActTimeLimit_121:getIsCanRefreshScoreRewardPool()
    local bl = false
    if common:getTableLen(TreasureRaiderDataHelper.lotteryindex) ~= 0 then
        bl = true
    end
    return bl
end

function ActTimeLimit_121:formatRollItemData()
    local t = { }
    for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        local data = ResManagerForLua:getResInfoByTypeAndId(v.needRewardValue.type, v.needRewardValue.itemId, v.needRewardValue.count)
        table.insert(t, data)
    end
    return t
end

function ActTimeLimit_121:formatRewardData(data)
    local _type, _id, _count = unpack(common:split(data, "_"))

    local data = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count))
    return data
end


function ActTimeLimit_121:formatRewardPopUpData(str)

    local t = { }
    for _, item in ipairs(common:split(str, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"));
        table.insert(t, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        } );
    end
    return t
end

function ActTimeLimit_121:getTableLen(t)
    local index = 0
    for k, v in pairs(t) do
        index = index + 1
    end
    return index
end


function ActTimeLimit_121:getPageInfo(container)

    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.RELEASE_UR_INFO3_C)
    --- 请求副将信息
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end

-- 刷新UR抽奖界面
function ActTimeLimit_121:refreshURPage(container)
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
        mActDouble = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount),
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

        mResetPriceLable = TreasureRaiderDataHelper.resetCostGold-- 重置一次消耗的钻石
    }

    NodeHelper:setStringForLabel(container, label2Str)

    -- 设置节点是否显示
    NodeHelper:setNodesVisible(container, {
        mFreelabel = TreasureRaiderDataHelper.freeTreasureTimes <= 0,
        mBtnPriceNode_1 = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        mFreeTimeCDNode = TreasureRaiderDataHelper.freeTreasureTimes > 0,
        mNormalBtn1TextNode = TreasureRaiderDataHelper.freeTreasureTimes <= 0
    } )


    for k, v in pairs(TreasureRaiderDataHelper.lotteryindex) do
        self:setItemIsReceive(mScorePoolItem[v], true)
    end

    for k, v in pairs(TreasureRaiderDataHelper.lastRewardTable) do
        self:setItemIsReceive(mScorePoolItem[v], false)
    end

    self:refreshResetBtn(container)
    self:refreshScoreBtn(container)
end

-- 刷新积分抽奖按钮状态
function ActTimeLimit_121:refreshScoreBtn(container)
    local bl = true
    if TreasureRaiderDataHelper.lotterypoint < ONE_COUNT_SCORE_REWARD then
        bl = false
    end
    local item = self.container:getVarMenuItemImage("mScoreBtn")
    item:setEnabled(bl)
    NodeHelper:setNodeIsGray(self.container, { mScoreBtnLabel = not bl, mScoreNumLable = not bl })
end

-- 刷新重置按钮状态
function ActTimeLimit_121:refreshResetBtn(container)
    local bl = self:getIsCanRefreshScoreRewardPool()
    local item = self.container:getVarMenuItemImage("mResetBtn")
    item:setEnabled(bl)
    NodeHelper:setNodeIsGray(self.container, { mResetBtnLabel = not bl, mResetBtnDimImage = not bl, mResetPriceLable = not bl })
end

-- 刷新页面
function ActTimeLimit_121:refreshPage(container)
    self:refreshURPage(container)
end

-- 重置积分奖池
function ActTimeLimit_121:resetScorePool()
    TreasureRaiderDataHelper.lotteryindex = { }
    TreasureRaiderDataHelper.lastRewardTable = self:getLastScorePool(TreasureRaiderDataHelper.lotteryindex)
    -- 刷新积分奖池界面 积分奖池item设置为未领取状态
    for k, v in pairs(mScorePoolItem) do
        self:setItemIsReceive(v, false)
    end
    self:refreshResetBtn(self.container)
end

-- 收包
function ActTimeLimit_121:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber()
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S then
        msg = Activity2_pb.HPNewTreasureRaiderInfoSync()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    elseif opcode == HP_pb.RELEASE_UR_INFO3_S or opcode == HP_pb.RELEASE_UR_DRAW3_S then
        msg = Activity3_pb.ReleaseURInfo()
        msg:ParseFromString(msgBuff)
        self:updateData(parentContainer, opcode, msg)
    elseif opcode == HP_pb.RELEASE_UR_RESET3_S then
        -- 重置积分奖池返回
        msg = Activity3_pb.ReleaseURResetRep()
        msg:ParseFromString(msgBuff)
        if msg.status == 1 then
            self:resetScorePool()
            -- 刷新玩家钻石数量
            NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold })
        end
    elseif opcode == HP_pb.RELEASE_UR_LOTTERY3_S then
        -- 积分抽奖返回
        msg = Activity3_pb.ReleaseURLotteryRep()
        msg:ParseFromString(msgBuff)

        -- 记录上一次碎片数量
        mCurrentRoleNumber = self:getCurrentRoleNumber()
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        self:showScoreAnimation(msg)
    end
end

-- 显示积分抽奖动画
function ActTimeLimit_121:showScoreAnimation(msg)
    mTargetRewardIndex = msg.index + 1
    mExcInfo = msg.excInfo
    if common:getTableLen(TreasureRaiderDataHelper.lastRewardTable) == 1 then
        -- 如果积分奖池还剩下最后一个了   那就直接显示奖励
        self:popUpRewardPage( { TreasureRaiderDataHelper.TreasureRaiderConfig[mTargetRewardIndex].needRewardValue })
        self:resetScorePool()
    else
        mIsAnimationInProgress = true
        mMoveSprite = self.container:getVarSprite("mMoveSprite")
        NodeHelper:setNodeVisible(mMoveSprite, true)
        mMoveSprite:setPosition(mRewardPosition[TreasureRaiderDataHelper.lastRewardTable[self:getMoveToIndex(0)]])
        self:RunActionSpeedAdd(mMoveSprite, 0.5, self:getMoveToIndex(0 + 1))
        local delayTime = CCDelayTime:create(5)
        local callFunc = CCCallFunc:create( function()
            mMoveSprite:stopAllActions()
            self:RunActionSpeedReduce(mMoveSprite, 0.1, self:getMoveToIndex(mCurrentRewardIndex))
        end )
        local array = CCArray:create()
        array:addObject(delayTime)
        array:addObject(callFunc)
        local sequence = CCSequence:create(array)
        self.container:runAction(sequence)
    end
    self:refreshScore(msg.comluckey)
    -- 刷新积分
    self:refreshScoreBtn(self.container)
    -- 刷新积分按钮状态
end

-- 刷新积分
function ActTimeLimit_121:refreshScore(comluckey)
    TreasureRaiderDataHelper.lotterypoint = TreasureRaiderDataHelper.lotterypoint - comluckey
    if TreasureRaiderDataHelper.lotterypoint < 0 then
        -- 避免负数情况  ，如果逻辑正常的话应该不会有这种情况出现
        TreasureRaiderDataHelper.lotterypoint = 0
    end

    local label2Str = {
        mScoreNumLable = TreasureRaiderDataHelper.lotterypoint .. " / " .. ONE_COUNT_SCORE_REWARD,-- 当前积分  /  抽一次的积分
    }
    NodeHelper:setStringForLabel(self.container, label2Str)
end

function ActTimeLimit_121:updateData(parentContainer, opcode, msg)
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
    TreasureRaiderDataHelper.lotteryindex = { }
    -- 已经抽取的奖励
    TreasureRaiderDataHelper.lastRewardTable = { }
    -- 还剩下的奖励
    TreasureRaiderDataHelper.resetCostGold = msg.lotteryCost or 100

    for i = 1, #msg.reward do
        -- 抽一次   抽十次获得的奖励
        TreasureRaiderDataHelper.reward[i] = msg.reward[i]
    end

    if msg.lotteryindex then
        for i = 1, #msg.lotteryindex do
            -- 积分抽奖已经抽取的奖励
            local n = msg.lotteryindex[i] + 1
            TreasureRaiderDataHelper.lotteryindex[i] = n
        end
    end

    -- 得到剩下的积分奖池  参数是已经抽过的
    TreasureRaiderDataHelper.lastRewardTable = self:getLastScorePool(TreasureRaiderDataHelper.lotteryindex)

    if opcode == HP_pb.NEW_TREASURE_RAIDER_INFO_S or opcode == HP_pb.RELEASE_UR_INFO3_S then
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then

        end
    elseif opcode == HP_pb.NEW_TREASURE_RAIDER_SEARCH_S or opcode == HP_pb.RELEASE_UR_DRAW3_S then
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        -- 有奇遇宝箱播放动画，弹出窗口
        if TreasureRaiderDataHelper.showItems ~= nil and TreasureRaiderDataHelper.showItems ~= "" then

        end

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
        -- self:popUpRewardPage(rewardItems)   --显示抽到的奖励

    end
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end
    self:refreshPage(self.container)
end


function ActTimeLimit_121:pushRewardPage()
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
        --        CommonRewardAni:setFirstData(data, data.rewards, ActTimeLimit_121.onBtnClick_1, ActTimeLimit_121.onBtnClick_2, false, function()
        --            if #TreasureRaiderDataHelper.reward == 10 then
        --                PageManager.showComment(true)
        --                -- 评价提示
        --            end
        --        end )

        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", false, ActTimeLimit_121.onBtnClick_1, ActTimeLimit_121.onBtnClick_2, function()
            if #TreasureRaiderDataHelper.reward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end )
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", true, ActTimeLimit_121.onBtnClick_1, ActTimeLimit_121.onBtnClick_2)
        -- CommonRewardAni:setFirstData(data, data.rewards, ActTimeLimit_121.onBtnClick_1, ActTimeLimit_121.onBtnClick_2, true)
    end
end

function ActTimeLimit_121:isContain(t, n)
    for k, v in pairs(t) do
        if v == n then
            return true
        end
    end
    return false
end

function ActTimeLimit_121:getLastScorePool(lotteryindex)

    local t = { }
    if lotteryindex == nil or common:getTableLen(lotteryindex) == 0 then
        for i = 1, 9 do
            table.insert(t, i)
        end
    else
        for i = 1, 9 do
            if not self:isContain(lotteryindex, i) then
                table.insert(t, i)
            end
        end
    end


    return t
end

function ActTimeLimit_121:popUpRewardPage(rewardItems)
    if rewardItems and #rewardItems > 0 then
        -- TODO这里请求碎片数量

        local data = rewardItems[1]
        if data.type ~= 70000 then
            -- 普通道具
            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm(rewardItems, true, nil, nil)
            PageManager.pushPage("CommonRewardPage")
        else

            -- 副将碎片
            local changeData = ConfigManager.parseItemOnlyWithUnderline(mExcInfo)
            local roleChipCount = data.count
            local n = mMaxRoleNumber - mCurrentRoleNumber - roleChipCount
            local rewardData = nil
            if n >= 0 then
                -- 显示碎片
                rewardData = rewardItems[1]
            else
                n = math.abs(n)
                local type = changeData.type
                local itemId = changeData.itemId
                local count = changeData.count * n
                local str = type .. "_" .. itemId .. "_" .. count
                rewardData = ConfigManager.parseItemOnlyWithUnderline(str)
            end

            local CommonRewardPage = require("CommonRewardPage")
            CommonRewardPageBase_setPageParm( { rewardData }, true, nil, nil)
            PageManager.pushPage("CommonRewardPage")
        end
    end
end

function ActTimeLimit_121:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_121:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_121:onExecute(parentContainer)
    self:onTimer(self.container)
end

function ActTimeLimit_121:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if TreasureRaiderDataHelper.RemainTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd");
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr, mFreeTimeCDLabel = endStr });
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = false,
                mNoBuf = false
            } );
        elseif TreasureRaiderDataHelper.RemainTime < 0 then
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = "" });
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
    if remainTime + 1 > TreasureRaiderDataHelper.RemainTime then
        return;
    end
    local timeStr = common:second2DateString(remainTime, false);
    NodeHelper:setStringForLabel(container, { [self.timerLabel] = common:getLanguageString("@SurplusTimeFishing") .. timeStr });
    if remainTime <= 0 then
        timeStr = common:getLanguageString("@ActivityEnd");
        PageManager.popPage(thisPageName)
    end

    if TimeCalculator:getInstance():hasKey(self.timerFreeCD) then
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.timerFreeCD);
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false);
            NodeHelper:setStringForLabel(container, { mFreeTimeCDLabel = common:getLanguageString("@SuitShootFreeOneTime", timeStr) });
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

function ActTimeLimit_121:onExit(parentContainer)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
    --    local s9Sprite = self.container:getVarScale9Sprite("m_S9_1")
    --    if s9Sprite then
    --        s9Sprite:removeAllChildren()
    --    end
    mIsAnimationInProgress = false
    local spineNode = self.container:getVarNode("mSpine")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    MercenaryCfg = nil
    onUnload(thisPageName, self.container)

    mIsRoll = false
end

function ActTimeLimit_121:initSpine(container)

    local spineNode = container:getVarNode("mSpineNode");
    -- local s9Sprite = self.container:getVarScale9Sprite("m_S9_1")
     local spinePosOffset = _MercenaryInfo.offset
     local spineScale = _MercenaryInfo.scale
    --local spinePosOffset = "-100,0"
    --local spineScale = 0.8

    local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo.itemId]
    if spineNode and roldData then
        -- spineNode:removeAllChildren();
        local dataSpine = common:split((roldData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");
        spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);

        -- spineToNode:setPosition(ccp(s9Sprite:getContentSize().width / 2, s9Sprite:getContentSize().height / 2))
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
    end
end


-- 更新佣兵碎片数量
function ActTimeLimit_121:updateMercenaryNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt", MercenaryCfg[_MercenaryInfo.itemId].name) .. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount });
            mMaxRoleNumber = MercenaryRoleInfos[i].costSoulCount
            -- mCurrentRoleNumber = MercenaryRoleInfos[i].soulCount
            break;
        end
    end
end


function ActTimeLimit_121:getCurrentRoleNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            return MercenaryRoleInfos[i].soulCount
        end
    end
end


function ActTimeLimit_121:onBtnClick_1(container)
    if mIsAnimationInProgress then return end
    if TreasureRaiderDataHelper.onceCostGold == 0 then return end


    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 and
        UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_1
    local msg = Activity3_pb.ReleaseURDraw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.RELEASE_UR_DRAW3_C, msg)
end

function ActTimeLimit_121:onBtnClick_2(container)

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
    local msg = Activity3_pb.ReleaseURDraw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.RELEASE_UR_DRAW3_C, msg)
end


-- 积分抽奖事件
function ActTimeLimit_121:onScoreClick(container)
    if TreasureRaiderDataHelper.lotterypoint < 10 then
        -- TODO提示积分不够
        -- MessageBoxPage:Msg_Box_Lan("@bindsuccess")
        return
    end

    if mIsAnimationInProgress then return end
    local msg = Activity3_pb.ReleaseURLotteryReq()
    common:sendPacket(HP_pb.RELEASE_UR_LOTTERY3_C, msg)
end

-- 重置积分奖池事件  如果当前积分奖池没有被抽出去的  这个按钮是置灰
function ActTimeLimit_121:onResetClick(container)
    if mIsAnimationInProgress then return end

    if UserInfo.playerInfo.gold < TreasureRaiderDataHelper.resetCostGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end
    if mIsAnimationInProgress then return end
    local msg = Activity3_pb.ReleaseURResetReq()
    msg.times = 1
    common:sendPacket(HP_pb.RELEASE_UR_RESET3_C, msg)
end

-- 抽奖次数随机 现在不用了
function ActTimeLimit_121:onBtnClick_3(container)
    if LLL == nil then
        return
    end

    if mIsAnimationInProgress then return end

    if TreasureRaiderDataHelper.randCostGold == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = TreasureRaiderDataHelper.tenCostGold
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_Randmo
    local msg = Activity3_pb.ReleaseURDraw()
    msg.times = mDrawRewardTyep
    common:sendPacket(HP_pb.RELEASE_UR_DRAW3_C, msg)
end


function ActTimeLimit_121:onIllustatedOpen(container)
    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(_MercenaryInfo.itemId)
end

function ActTimeLimit_121:onRewardPreview(container)

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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_ACT_121)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end


-- 得到奖励节点的开始位置   世界坐标 
function ActTimeLimit_121:getRewardItemStratWorldPosition()
    if mRewardItemStartPosition == nil then
        mRewardItemStartPosition = self.container:getVarNode("mSp_2"):getPosition()
    end
    return mRewardItemStartPosition
end


function ActTimeLimit_121:convertToWorldSpace(node)
    if node then
        local x, y = node:getPosition()
        return node:getParent():convertToWorldSpace(ccp(x, y))
    end
end

-- 设置积分奖池已领取图片显隐
function ActTimeLimit_121:setItemIsReceive(item, bl)
    local maskSprite = tolua.cast(item:getChildByTag(mItemTag.Mask), "CCSprite")
    NodeHelper:setNodeVisible(maskSprite, bl)
end

function ActTimeLimit_121:createRewardItem(index)
    local node = CCNode:create()
    local bgSprite = CCSprite:create("common_ht_propK_diban.png")
    -- bg
    node:addChild(bgSprite, 0, 1000)

    local iconSprite = CCSprite:create("UI/Mask/Image_Empty.png")
    -- icon
    node:addChild(iconSprite, 1, mItemTag.IconSprite)

    local maskSprite = CCSprite:create("common_Image_3.png")
    -- 已领取遮罩
    node:addChild(maskSprite, 2, mItemTag.Mask)
    NodeHelper:setNodeVisible(maskSprite, false)

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

function ActTimeLimit_121:RunActionSpeedAdd(node, time, index)
    local delayTime = CCDelayTime:create(time)
    local callFunc = CCCallFunc:create( function()
        time = time - 0.1
        node:setPosition(mRewardPosition[TreasureRaiderDataHelper.lastRewardTable[index]])
        -- node:setPosition(mRewardPosition[index])
        local nextIndex = self:getMoveToIndex(index)
        if time <= 0.1 then
            time = 0.1
        end
        self:RunActionSpeedAdd(node, time, nextIndex)
    end )
    local array = CCArray:create()
    array:addObject(delayTime)
    array:addObject(callFunc)
    local sequence = CCSequence:create(array)
    node:runAction(sequence)
end

function ActTimeLimit_121:RunActionSpeedReduce(node, time, index)
    local delayTime = CCDelayTime:create(time)
    local callFunc = CCCallFunc:create( function()
        time = time + 0.1
        node:setPosition(mRewardPosition[TreasureRaiderDataHelper.lastRewardTable[index]])
        -- node:setPosition(mRewardPosition[index])
        local nextIndex = self:getMoveToIndex(index)
        if time >= 0.5 then
            time = 0.5
            self:RunActionSpeedUniformity(node, time, nextIndex)
        else
            self:RunActionSpeedReduce(node, time, nextIndex)
        end

    end )
    local array = CCArray:create()
    array:addObject(delayTime)
    array:addObject(callFunc)
    local sequence = CCSequence:create(array)
    node:runAction(sequence)
end

function ActTimeLimit_121:RunActionSpeedUniformity(node, time, index)
    local delayTime = CCDelayTime:create(time)
    local callFunc = CCCallFunc:create( function()
        node:setPosition(mRewardPosition[TreasureRaiderDataHelper.lastRewardTable[index]])
        -- node:setPosition(mRewardPosition[index])
        local nextIndex = self:getMoveToIndex(index)
        if mTargetRewardIndex == TreasureRaiderDataHelper.lastRewardTable[index] then
            local DelayTime = CCDelayTime:create(1)
            -- 抽奖结束了  延迟1秒显示结果
            local CallFunc = CCCallFunc:create( function()
                mMoveSprite = self.container:getVarSprite("mMoveSprite")
                NodeHelper:setNodeVisible(mMoveSprite, false)
                mIsAnimationInProgress = false
                self:setItemIsReceive(mScorePoolItem[mTargetRewardIndex], true)
                -- 添加到已经抽到的奖励
                local t = { }
                for k, v in pairs(TreasureRaiderDataHelper.lastRewardTable) do
                    if v == mTargetRewardIndex then
                        table.insert(TreasureRaiderDataHelper.lotteryindex, v)
                    else
                        table.insert(t, v)
                    end
                end
                TreasureRaiderDataHelper.lastRewardTable = t
                self:refreshResetBtn(self.container)
                self:popUpRewardPage( { TreasureRaiderDataHelper.TreasureRaiderConfig[mTargetRewardIndex].needRewardValue })
            end )

            local Array = CCArray:create()
            Array:addObject(DelayTime)
            Array:addObject(CallFunc)
            local Sequence = CCSequence:create(Array)
            node:runAction(Sequence)

            --                NodeHelper:setNodeVisible(node , false)
            --                mIsAnimationInProgress = false
            --                self:setItemIsReceive(mScorePoolItem[mTargetRewardIndex], true)
            --                -- 添加到已经抽到的奖励
            --                local t = { }
            --                for k, v in pairs(TreasureRaiderDataHelper.lastRewardTable) do
            --                    if v == mTargetRewardIndex then
            --                        table.insert(TreasureRaiderDataHelper.lotteryindex, v)
            --                    else
            --                        table.insert(t, v)
            --                    end
            --                end
            --                TreasureRaiderDataHelper.lastRewardTable = t
            --                self:refreshResetBtn(self.container)
            --                self:popUpRewardPage( { TreasureRaiderDataHelper.TreasureRaiderConfig[mTargetRewardIndex].needRewardValue })
        else
            self:RunActionSpeedUniformity(node, time, nextIndex)
        end
    end )
    local array = CCArray:create()
    array:addObject(delayTime)
    array:addObject(callFunc)
    local sequence = CCSequence:create(array)
    node:runAction(sequence)
end

function ActTimeLimit_121:removeLastRewardTable(index)
    local t = { }
    for k, v in pairs(TreasureRaiderDataHelper.lastRewardTable) do
        if v == index then
            table.insert(TreasureRaiderDataHelper.lotteryindex, k, v)
        else
            table.insert(t, k, v)
        end
    end
    TreasureRaiderDataHelper.lastRewardTable = t
end

function ActTimeLimit_121:getMoveToIndex(currentIndex)
    local t = TreasureRaiderDataHelper.lastRewardTable
    -- 剩下的奖励
    currentIndex = currentIndex + 1
    if currentIndex > common:getTableLen(t) then
        currentIndex = 1
    end
    mCurrentRewardIndex = currentIndex
    return currentIndex
end


local CommonPage = require('CommonPage')
TreasureRaiderPage_121 = CommonPage.newSub(ActTimeLimit_121, thisPageName, option)

return ActTimeLimit_121