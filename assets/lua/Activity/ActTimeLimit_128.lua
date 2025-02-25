-- 癒し彼女   治愈彼女
local NodeHelper = require("NodeHelper")
local Activity4_pb = require("Activity4_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb");
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "ActTimeLimit_128"
local ConfigManager = require("ConfigManager")
local RoleOpr_pb = require("RoleOpr_pb")
local ResManagerForLua = require("ResManagerForLua")
local mConstCount = 0

local _MercenaryInfo = nil
local MercenaryCfg = nil
local MercenaryRoleInfos = { }
local mCurrentRankType = 1
local mDrawRewardTyep = 1  -- 抽奖类型 
local mIsAnimationInProgress = false    -- 是不是正在执行动画 如果是的话按钮不能点击了
local mBoxStateTabel = { }
local BaoXiangStage = {
    -- 不能领取
    Null = 0,
    -- 已经领取
    YiLingQu = 1,
    -- 可领取
    KeLingQu = 2,
}
local ActTimeLimit_128 = { }
local option = {
    ccbiFile = "Act_TimeLimit_128.ccbi",
    handlerMap =
    {
        onRewardPreview = "onRewardPreview",
        onIllustatedOpen = "onIllustatedOpen",
        onBtnClick_1 = "onBtnClick_1",
        onBtnClick_2 = "onBtnClick_2",
        onRankClick_1 = "onRankClick_1",
        onRankClick_2 = "onRankClick_2",

        onBaoXiangClick_1 = "onBaoXiangClick_1",
        onBaoXiangClick_2 = "onBaoXiangClick_2",
        onBaoXiangClick_3 = "onBaoXiangClick_3",
        onBaoXiangClick_4 = "onBaoXiangClick_4",

        onRefreshRankClick = "onRefreshRankClick",
        onRankHelpClick = "onRankHelpClick",
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
    ACTIVITY128_UR_RANK_INFO_C = HP_pb.ACTIVITY128_UR_RANK_INFO_C,
    -- 界面信息返回
    ACTIVITY128_UR_RANK_INFO_S = HP_pb.ACTIVITY128_UR_RANK_INFO_S,
    -- 抽奖请求
    ACTIVITY128_UR_RANK_LOTTERY_C = HP_pb.ACTIVITY128_UR_RANK_LOTTERY_C,
    -- 抽奖返回
    ACTIVITY128_UR_RANK_LOTTERY_S = HP_pb.ACTIVITY128_UR_RANK_LOTTERY_S,
    -- 排行榜请求
    ACTIVITY128_UR_RANK_RANK_C = HP_pb.ACTIVITY128_UR_RANK_RANK_C,
    -- 排行榜返回
    ACTIVITY128_UR_RANK_RANK_S = HP_pb.ACTIVITY128_UR_RANK_RANK_S,
    -- 领取宝箱
    ACTIVITY128_UR_RANK_BOX_C = HP_pb.ACTIVITY128_UR_RANK_BOX_C,
    -- 领取宝箱返回
    ACTIVITY128_UR_RANK_BOX_S = HP_pb.ACTIVITY128_UR_RANK_BOX_S,
    -- 副将信息请求
    ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    -- 副将信息返回
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
}
local mServerData = nil
local mRewardConfigData = nil
local mBoxRewardConfigData = nil
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

ActTimeLimit_128.timerName = "Activity_ActTimeLimit_128"
ActTimeLimit_128.timerLabel = "mTanabataCD"
ActTimeLimit_128.timerKeyBuff = "Activity_ActTimeLimit_128_Timer_Key_Buff"
ActTimeLimit_128.timerFreeCD = "Activity_ActTimeLimit_128_Timer_Free_CD"



-----------------------------------------------------------------
-- Item

local Item = {
    ccbiFile = "Act_TimeLimit_128_Item.ccbi",
}

function Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function Item:refresh()
    local selfRankData = self.data
    NodeHelper:setStringForLabel(self.container, { mItemName = selfRankData.name, mItemCurrentScore = selfRankData.score })

    ----
    if self.data.playerId == UserInfo.playerInfo.playerId then
        NodeHelper:setNodesVisible(self.container, { mItemSelfBg = true, mItemOtherBg = false })
    else
        NodeHelper:setNodesVisible(self.container, { mItemSelfBg = false, mItemOtherBg = true })
    end
    local icon, bgIcon = common:getPlayeIcon(selfRankData.prof, selfRankData.headerId)
    NodeHelper:setSpriteImage(self.container, { mItemIcon = icon, mItemIconBg = bgIcon })

    if selfRankData.rank <= 5 and selfRankData.rank > 0 then
        -- 显示奖励节点
        NodeHelper:setNodesVisible(self.container, { mItemRewardNode = true })
        local rewardData = ActTimeLimit_128.getItemReward(selfRankData.rank)
        local itemData = ResManagerForLua:getResInfoByTypeAndId(rewardData.type, rewardData.itemId, rewardData.count)
        NodeHelper:setSpriteImage(self.container, { mItemRewardIcon = itemData.icon })
        NodeHelper:setStringForLabel(self.container, { mItemRewardCount = "x" .. itemData.count })
    else
        -- 没有奖励
        NodeHelper:setNodesVisible(self.container, { mItemRewardNode = false })
    end

    if selfRankData.rank <= 3 and selfRankData.rank ~= 0 then
        NodeHelper:setSpriteImage(self.container, { mItemRankImage = GameConfig.ArenaRankingIcon[selfRankData.rank] })
        NodeHelper:setStringForLabel(self.container, { mItemRankText = selfRankData.rank })
        NodeHelper:setNodesVisible(self.container, { mItemRankText = false })
    else
        NodeHelper:setSpriteImage(self.container, { mItemRankImage = GameConfig.ArenaRankingIcon[4] })
        NodeHelper:setStringForLabel(self.container, { mItemRankText = selfRankData.rank })
        NodeHelper:setNodesVisible(self.container, { mItemRankText = true })
    end
end

-----------------------------------------------------------------

function ActTimeLimit_128:onEnter(parentContainer)
    math.randomseed(os.time())
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container


    luaCreat_ActTimeLimit_128(container)


    self.container.mScrollView = container:getVarScrollView("mContent")
    NodeHelper:initScrollView(self.container, "mContent", 3)

    local s9Bg = container:getVarScale9Sprite("m_S9_1")
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mMachineNode"), 0.5)
    --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mImage_2"))
    NodeHelper:autoAdjustResizeScale9Sprite(s9Bg)

    local scale = NodeHelper:getScaleProportion()
    if scale <= 1 then
        --scale = scale - scale % 0.1
        --local sp_1 = container:getVarSprite("mImage_1")
        --sp_1:setScale(scale)

        --local sp_2 = container:getVarSprite("mImage_2")
        --sp_2:setScale(scale)
    end
    if scale < 1 then
        --NodeHelper:setNodesVisible(container, { mImage_1 = true, mRoleQualitySprite = false })
        NodeHelper:setSpriteImage(container, { mQualityBg = "BG/Activity_128/UR_128_Image_12.png" })
        local mQualityBg = container:getVarSprite("mQualityBg")
        if mQualityBg then
            mQualityBg:setFlipX(false)
        end
    else
        --NodeHelper:setNodesVisible(container, { mImage_1 = true, mRoleQualitySprite = true })
        NodeHelper:setSpriteImage(container, { mQualityBg = "common_ht_diban_31_img.png" })
        local mQualityBg = container:getVarSprite("mQualityBg")
        if mQualityBg then
            mQualityBg:setFlipX(true)
            local mRoleQualitySprite = container:getVarSprite("mRoleQualitySprite")
            if mRoleQualitySprite then
                mRoleQualitySprite:setPosition(ccp(mQualityBg:getContentSize().width / 2, mQualityBg:getContentSize().height / 2))
            end
        end
    end


    NodeHelper:setNodesVisible(self.container, { mBtmNode = false, mLuckDrawNode = false })

    self:registerPacket(parentContainer)
    self:initData()
    self:getPageInfo()
    self:initUi(container)

    return container
end

function ActTimeLimit_128:initData()
    mServerData = { }
    mServerData.rankData = { }
    mDrawRewardTyep = mDrawTyep.Type_1
    mCurrentRankType = 1
    -- 副将信息
    MercenaryCfg = ConfigManager.getRoleCfg()
    -- 本期抽奖可以获得的副将
    _MercenaryInfo = ConfigManager.getReleaseURdrawMercenary128Cfg()[1]
    -- 本期抽奖可以获得的奖励
    mRewardConfigData = ConfigManager.getReleaseURdrawReward128Cfg() or { }
    for k, v in pairs(mRewardConfigData) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

    mBoxRewardConfigData = ConfigManager.getReleaseURdrawLotteryReward128Cfg() or { }
end

function ActTimeLimit_128:initUi(container)
    NodeHelper:setNodesVisible(container, { mMoveSprite = false })
    self:initSpine(container)
    NodeHelper:setSpriteImage(container, { mImage_1 = MercenaryCfg[_MercenaryInfo.itemId].namePic })
    NodeHelper:setSpriteImage(container, { mRoleQualitySprite = GameConfig.ActivityRoleQualityImage[MercenaryCfg[_MercenaryInfo.itemId].quality] })
end

function ActTimeLimit_128:getPageInfo(container)
    -- 请求界面信息
    common:sendEmptyPacket(HP_pb.ACTIVITY128_UR_RANK_INFO_C, false)
    --- 请求副将信息
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
    -- 请求排行榜    1 = 实时  2 = 前一天的
    self:requestRankData(1)
    self:requestRankData(2)
end

function ActTimeLimit_128:requestRankData(type)
    -- type == 1 请求实时
    -- type == 2 请求前一天
    local msg = Activity4_pb.Activity128RankReq()
    msg.type = type
    common:sendPacket(HP_pb.ACTIVITY128_UR_RANK_RANK_C, msg)
end

-- 刷新UR抽奖界面
function ActTimeLimit_128:refreshURPage(container)
    if mServerData.leftTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerName, mServerData.leftTime)
    end
    if mServerData.ownInfo.freeLeftTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(self.timerFreeCD, mServerData.ownInfo.freeLeftTime)
    end

    local label2Str = {
        -- 设置玩家金币数量
        mDiamondNum = UserInfo.playerInfo.gold,
        -- 多少次后必得什么奖励
        mTitle = common:getLanguageString("@NeedXTimesGet",mServerData.ownInfo.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name,mConstCount),
        --  一次价格
        mPrice_1 = mServerData.oneTimeCost,
        --  十次价格
        mPrice_2 = mServerData.tenTimesCost,
        --  随机价格
        -- mPrice_3 = TreasureRaiderDataHelper.randCostGold,

        -- m1Label_1 = common:getLanguageString("@RouletteLeftTimes",1),

        -- mLabel_1 = common:getLanguageString("@RouletteLeftTimes",1),

        -- mLabel_2 = common:getLanguageString("@RouletteLeftTimes",_MercenaryInfo.maxDrawCount),

        -- mLabel_3 = common:getLanguageString("@ReleaseURdrawMercenaryDesc",_MercenaryInfo.randmoDrawMinCount,_MercenaryInfo.maxDrawCount),

        mFreelabel = common:getLanguageString("@SuitShootFree1Text"),

        -- mScoreNumLable = TreasureRaiderDataHelper.lotterypoint .. " / " .. ONE_COUNT_SCORE_REWARD,
        -- 当前积分  /  抽一次的积分
    }

    NodeHelper:setStringForLabel(container, label2Str)

    -- 设置节点是否显示
    NodeHelper:setNodesVisible(container, {
        mBtnFreeNode_1 = mServerData.ownInfo.freeLeftTime <= 0,
        mBtnPriceNode_1 = mServerData.ownInfo.freeLeftTime > 0,
        mFreeTimeCDNode = mServerData.ownInfo.freeLeftTime > 0,
        mNormalBtn1TextNode = mServerData.ownInfo.freeLeftTime <= 0
    } )


    if mServerData.ownInfo.freeLeftTime > 0 then
        ActivityInfo.changeActivityNotice(GameConfig.NowSelctActivityId)
    end

end


-- 刷新排行榜
function ActTimeLimit_128:refreshRank()
    NodeHelper:setNodesVisible(self.container, { mLuckDrawNode = true })
    self:setRankBtnState()
    self.container.mScrollView:removeAllCell()
    if mServerData.rankData[mCurrentRankType] == nil then
        return
    end
    NodeHelper:setNodesVisible(self.container, { mPageBtnNode_1 = mServerData.rankData[1] ~= nil })
    NodeHelper:setNodesVisible(self.container, { mPageBtnNode_2 = mServerData.rankData[2] ~= nil })

    if #mServerData.rankData[mCurrentRankType].item == 0 then
        NodeHelper:setStringForLabel(self.container, { mNullRank = common:getLanguageString("@GuildBossWaitToOpen") })
    else
        NodeHelper:setStringForLabel(self.container, { mNullRank = "" })
    end

    local rankData = mServerData.rankData[mCurrentRankType]
    -----------------
    -- 自己的
    local selfRankData = rankData.ownItem
    local icon, bgIcon = common:getPlayeIcon(selfRankData.prof, selfRankData.headerId)
    NodeHelper:setSpriteImage(self.container, { mSelfIcon = icon, mSelfIconBg = bgIcon })
    NodeHelper:setStringForLabel(self.container, { mSelfName = selfRankData.name, mSelfCurrentScore = selfRankData.score })
    if selfRankData.rank <= 5 and selfRankData.rank > 0 then
        -- 显示奖励节点
        NodeHelper:setNodesVisible(self.container, { mSelfRewardNode = true })
        local rewardData = ActTimeLimit_128.getItemReward(selfRankData.rank)
        local itemData = ResManagerForLua:getResInfoByTypeAndId(rewardData.type, rewardData.itemId, rewardData.count)
        NodeHelper:setSpriteImage(self.container, { mSelfRewardIcon = itemData.icon })
        NodeHelper:setStringForLabel(self.container, { mSelfRewardCount = "x" .. itemData.count })
    else
        -- 没有奖励
        NodeHelper:setNodesVisible(self.container, { mSelfRewardNode = false })
    end


    if selfRankData.score <= 0 then
        -- NodeHelper:setSpriteImage(self.container, { mSelfRankImage = GameConfig.ArenaRankingIcon[selfRankData.rank] })
        NodeHelper:setNodesVisible(self.container, { mSelfRankImage = false, mSelfRankTextTTF = true })
        NodeHelper:setStringForLabel(self.container, { mSelfRankText = "", mSelfRankTextTTF = common:getLanguageString("@Null") })
        NodeHelper:setNodesVisible(self.container, { mSelfRankText = false })
    else
        if selfRankData.rank <= 3 and selfRankData.rank > 0 then
            NodeHelper:setSpriteImage(self.container, { mSelfRankImage = GameConfig.ArenaRankingIcon[selfRankData.rank] })
            NodeHelper:setNodesVisible(self.container, { mSelfRankImage = true, mSelfRankTextTTF = false })
            NodeHelper:setStringForLabel(self.container, { mSelfRankText = selfRankData.rank })
            NodeHelper:setNodesVisible(self.container, { mSelfRankText = false })
        elseif selfRankData.rank == 0 then
            NodeHelper:setSpriteImage(self.container, { mSelfRankImage = GameConfig.ArenaRankingIcon[selfRankData.rank] })
            NodeHelper:setNodesVisible(self.container, { mSelfRankImage = false, mSelfRankTextTTF = true })
            NodeHelper:setStringForLabel(self.container, { mSelfRankText = "", mSelfRankTextTTF = ">100" })
            NodeHelper:setNodesVisible(self.container, { mSelfRankText = false })
        else
            NodeHelper:setSpriteImage(self.container, { mSelfRankImage = GameConfig.ArenaRankingIcon[4] })
            NodeHelper:setNodesVisible(self.container, { mSelfRankImage = true, mSelfRankTextTTF = false })
            NodeHelper:setStringForLabel(self.container, { mSelfRankText = selfRankData.rank })
            NodeHelper:setNodesVisible(self.container, { mSelfRankText = true })
        end
    end


    -----------------

    --------------------------------------
    -- 其他人的
    -- self.container.mScrollView:removeAllCell()
    local itemRankData = rankData.item
    local t = { }
    for i = 1, #itemRankData do
        table.insert(t, itemRankData[i])
    end
    table.sort(t, function(itemData_1, itemData_2)
        if itemData_1 and itemData_2 then
            return itemData_1.rank < itemData_2.rank
        else
            return false
        end
    end )

    for i, v in pairs(t) do
        local titleCell = CCBFileCell:create()
        local panel = Item:new( { data = v })
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(Item.ccbiFile)
        self.container.mScrollView:addCellBack(titleCell)
    end
    self.container.mScrollView:orderCCBFileCells()
    --------------------------------------
end


function ActTimeLimit_128.getItemReward(rank)
    local reward = mBoxRewardConfigData[rank].reward
    return ConfigManager.parseItemOnlyWithUnderline(reward)
end

function ActTimeLimit_128.getBoxReward()
    -- local reward = mBoxRewardConfigData[rank].reward
    local t = { }
    for k, v in pairs(mBoxRewardConfigData) do
        if v.id >= 1000 then
            table.insert(t, { point = v.id - 1000, reward = v.reward })
        end
    end

    return t
end

function ActTimeLimit_128:setRankBtnState()
    NodeHelper:setMenuItemEnabled(self.container, "mRankBtn_1", mCurrentRankType == 2)
    NodeHelper:setMenuItemEnabled(self.container, "mRankBtn_2", mCurrentRankType == 1)
end

-- 设置箱子领取状态
function ActTimeLimit_128:setBoxState()
    local boxData = ActTimeLimit_128.getBoxReward()

    local t = { }
    for i = 1, #mServerData.ownInfo.boxId do
        table.insert(t, mServerData.ownInfo.boxId[i])
    end

    for i = 1, #boxData do
        local data = boxData[i]
        NodeHelper:setStringForLabel(self.container, { ["mBaoXiangText_" .. i] = data.point })
        if mServerData.ownInfo.totalScore >= data.point then
            if self:isContainNum(t, i) then
                -- 已领取
                mBoxStateTabel[i] = BaoXiangStage.YiLingQu
            else
                -- 可领取
                mBoxStateTabel[i] = BaoXiangStage.KeLingQu
            end
            --            if mServerData.ownInfo.boxCount >= i then

            --            else

            --            end
        else
            -- 不能领取
            mBoxStateTabel[i] = BaoXiangStage.Null
        end
        self:refreshBoxState(i, mBoxStateTabel[i])
    end

    local mBoxBar = self.container:getVarSprite("mBoxBar")
    mBoxBar:setScaleX(self:getBarScaleX())
end

function ActTimeLimit_128:isContainNum(t, n)
    for k, v in pairs(t) do
        if tonumber(v) == n then
            return true, k
        end
    end
    return false, k
end

function ActTimeLimit_128:refreshBoxState(index, state)
    local i = index
    -- NodeHelper:setStringForLabel(self.container, { ["mBaoXiangText_" .. i] = data.point })
    if state == BaoXiangStage.YiLingQu then
        NodeHelper:setNodesVisible(self.container, { ["mBoxEffect" .. i] = false, ["mBoxSprite" .. i] = true })
        NodeHelper:setSpriteImage(self.container, { ["mBoxSprite" .. i] = "common_box_open_" .. i .. ".png" })
        -- NodeHelper:setMenuItemEnabled(self.container, "mBaoXiangBtn_" .. i, true)
    elseif state == BaoXiangStage.KeLingQu then
        NodeHelper:setNodesVisible(self.container, { ["mBoxEffect" .. i] = true, ["mBoxSprite" .. i] = false })
    elseif state == BaoXiangStage.Null then
        NodeHelper:setNodesVisible(self.container, { ["mBoxEffect" .. i] = false, ["mBoxSprite" .. i] = true })
        NodeHelper:setSpriteImage(self.container, { ["mBoxSprite" .. i] = "common_box_close_" .. i .. ".png" })
        -- NodeHelper:setMenuItemEnabled(self.container, "mBaoXiangBtn_" .. i, false)
    end
end


function ActTimeLimit_128:getBarScaleX()
    local scale = 1
    local boxData = ActTimeLimit_128.getBoxReward()
    if mServerData.ownInfo.totalScore >= boxData[#boxData].point then
        return scale
    end

    -- local scaleXTable = { { 140, 0.25 / 140 }, { 280, 0.25 / 140 }, { 780, 0.25 / 500 }, { 1480, 0.25 / 700 }}
    local scaleXTable = { { 140, 0.25 / 140 }, { 280, 0.25 / 140 }, { 780, 0.25 / 500 }, { 1480, 0.25 / 700 } }
    local scaleX = 0
    for i = 1, #scaleXTable do
        if mServerData.ownInfo.totalScore < scaleXTable[i][1] then
            if i == 1 then
                scaleX = scaleX + mServerData.ownInfo.totalScore * scaleXTable[i][2]
            else
                scaleX = scaleX +(i - 1) * 0.25 +((mServerData.ownInfo.totalScore - scaleXTable[i - 1][1]) * scaleXTable[i][2])
            end
            break
        elseif mServerData.ownInfo.totalScore == scaleXTable[i][1] then
            scaleX = scaleX + i * 0.25
            break
        end
    end
    return scaleX
end


-- 刷新页面
function ActTimeLimit_128:refreshPage(container)
    -- NodeHelper:setNodesVisible(self.container, { mBtmNode = true, mLuckDrawNode = true })
    NodeHelper:setNodesVisible(self.container, { mBtmNode = true })
    self:refreshURPage(container)
end

-- 收包
function ActTimeLimit_128:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
    local msgBuff = parentContainer:getRecPacketBuffer()
    local msg = nil
    if opcode == HP_pb.ACTIVITY128_UR_RANK_INFO_S then
        -- 界面信息返回
        msg = Activity4_pb.Activity128InfoRes()
        msg:ParseFromString(msgBuff)
        mServerData.ownInfo = msg.ownInfo
        mServerData.leftTime = msg.leftTime
        mServerData.oneTimeCost = msg.oneTimeCost
        mServerData.tenTimesCost = msg.tenTimesCost
        self:refreshScore()
        self:refreshPage(self.container)
        self:setBoxState()
    elseif opcode == HP_pb.ACTIVITY128_UR_RANK_LOTTERY_S then
        -- 抽奖返回
        msg = Activity4_pb.Activity128LotteryRes()
        msg:ParseFromString(msgBuff)
        -- 奖励返回
        mServerData.reward = msg.reward
        mServerData.ownInfo = msg.ownInfo
        -- 请求碎片数量
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        self:requestRankData(1)
        self:refreshPage(self.container)
        self:setBoxState()
        self:refreshScore()
        self:pushRewardPage()
    elseif opcode == HP_pb.ACTIVITY128_UR_RANK_RANK_S then
        -- 排行榜返回
        msg = Activity4_pb.Activity128RankRes()
        msg:ParseFromString(msgBuff)
        local t = { ownItem = msg.ownItem, item = msg.item }
        mServerData.rankData[msg.type] = t
        if msg.type == 2 then
            --            if #mServerData.rankData[msg.type].item == 0 then
            --                mServerData.rankData[msg.type] = nil
            --            end
        end
        self:refreshRank()
    elseif opcode == HP_pb.ACTIVITY128_UR_RANK_BOX_S then
        -- 领取宝箱返回
        msg = Activity4_pb.Activity128BoxRes()
        msg:ParseFromString(msgBuff)
        mServerData.ownInfo = msg.ownInfo
        self:setBoxState()
    elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes()
        msg:ParseFromString(msgBuff)
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber()
    end
end


function ActTimeLimit_128:popUpRewardPage()
    mIsAnimationInProgress = false
    if TreasureRaiderDataHelper.scoreRewardState == 1 then
        -- 请求碎片数量
        common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
        local changeData = ConfigManager.parseItemOnlyWithUnderline(TreasureRaiderDataHelper.excInfo)
        local roleChipCount = _MercenaryInfo.scorePoolReward.count
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

-- 刷新玩家当前的积分
function ActTimeLimit_128:refreshScore()
    NodeHelper:setStringForLabel(self.container, { mTotalScore = mServerData.ownInfo.totalScore })
end

function ActTimeLimit_128:pushRewardPage()

    local data = { }
    data.freeCd = mServerData.ownInfo.freeLeftTime
    data.onceGold = mServerData.oneTimeCost
    data.tenGold = mServerData.tenTimesCost
    data.itemId = nil
    data.rewards = mServerData.reward
    local isFree = data.freeCd <= 0
    local CommonRewardAni = require("CommonRewardAniPage")
    if not CommonRewardAni:isPop() then
        PageManager.pushPage("CommonRewardAniPage")
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", false, ActTimeLimit_128.onBtnClick_1, ActTimeLimit_128.onBtnClick_2, function()
            if #TreasureRaiderDataHelper.reward == 10 then
                PageManager.showComment(true)
                -- 评价提示
            end
        end )
    else
        CommonRewardAni:setFirstDataNew(data.onceGold, data.tenGold, data.rewards, isFree, 0, "", true, ActTimeLimit_128.onBtnClick_1, ActTimeLimit_128.onBtnClick_2)
    end
end


function ActTimeLimit_128:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ActTimeLimit_128:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ActTimeLimit_128:onExecute(parentContainer)
    if mServerData.ownInfo == nil or mServerData.leftTime == nil then
        return
    end
    self:onTimer(self.container)
end

function ActTimeLimit_128:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        if mServerData.leftTime == 0 then
            local endStr = common:getLanguageString("@ActivityEnd")
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = endStr, mFreeTimeCDLabel = endStr })
            NodeHelper:setNodesVisible(container, {
                mFreeText = false,
                mCostNodeVar = true,
                mFreeTimeCDLabel = false,
                mNoBuf = false
            } );
        elseif mServerData.leftTime < 0 then
            NodeHelper:setStringForLabel(container, { [self.timerLabel] = "" })
        end
        return;
    end

    local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
    if remainTime + 1 > mServerData.leftTime then
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

function ActTimeLimit_128:onExit(parentContainer)
    local node = self.container:getVarNode("mRewardNode")
    if node then
        node:removeAllChildren()
    end
    self.container:stopAllActions()

    mIsAnimationInProgress = false
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD)
    local spineNode = self.container:getVarNode("mSpineNode")
    if spineNode then
        spineNode:removeAllChildren()
    end
    self:removePacket(parentContainer)
    MercenaryCfg = nil
    onUnload(thisPageName, self.container)
end

function ActTimeLimit_128:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode");
    -- local spinePosOffset = "-130,30"
    -- local spineScale = 1.1

    local spinePosOffset = _MercenaryInfo.offset
    local spineScale = _MercenaryInfo.scale

    local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo.itemId]
    if spineNode and roldData then
        local dataSpine = common:split((roldData.spine), ",")
        local spinePath, spineName = dataSpine[1], dataSpine[2]
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");

        --支持镜像
        local spineScale_X, spineScale_Y = unpack(common:split((spineScale), ","))

        spineToNode:setScaleX(tonumber(spineScale_X))
        spineToNode:setScaleY(tonumber(spineScale_Y))
        --spineToNode:setScale(spineScale)
        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);


        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))

        local scale = NodeHelper:getScaleProportion()
        if scale > 1 then
            --            local mBoxNode = container:getVarNode("mBoxNode")
            --            mBoxNode:setPositionX(204)
            --            mBoxNode:setPositionY(230)
            --NodeHelper:autoAdjustResetNodePosition(spineToNode, 0.5)
            --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"), 0.5)
        elseif scale < 1 then
            --            local mBoxNode = container:getVarNode("mBoxNode")
            --            mBoxNode:setPositionX(-200)
            --            mBoxNode:setPositionY(330)

            --NodeHelper:setNodeScale(self.container, "mSpineNode", scale, scale)
            --NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mLuckDrawNode"))
        end
    end
end


-- 更新佣兵碎片数量
function ActTimeLimit_128:updateMercenaryNumber()
    for i = 1, #MercenaryRoleInfos do
        if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
            NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt", MercenaryCfg[_MercenaryInfo.itemId].name) .. MercenaryRoleInfos[i].soulCount .. "/" .. MercenaryRoleInfos[i].costSoulCount });
            break;
        end
    end
end

function ActTimeLimit_128:onBtnClick_1(container)
    if mServerData == nil then return end
    if mIsAnimationInProgress then return end
    if mServerData.oneTimeCost == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    if mServerData.ownInfo.freeLeftTime > 0 and
        UserInfo.playerInfo.gold < mServerData.oneTimeCost then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end
    local isFree = false
    if mServerData.ownInfo.freeLeftTime <= 0 then
        isFree = true
    end

    mDrawRewardTyep = mDrawTyep.Type_1
    local msg = Activity4_pb.Activity128LotteryReq()
    msg.freeLottery = isFree
    msg.count = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY128_UR_RANK_LOTTERY_C, msg)
end

function ActTimeLimit_128:onBtnClick_2(container)
    if mServerData == nil then return end
    if mIsAnimationInProgress then return end

    if mServerData.tenTimesCost == 0 then return end

    UserInfo.syncPlayerInfo()
    -- 当前拥有钻石小于消耗钻石
    local needGold = mServerData.tenTimesCost
    if needGold <= 0 then needGold = 0 end
    if UserInfo.playerInfo.gold < needGold then
        common:rechargePageFlag("TreasureRaiderBaseNewActvityId_" .. GameConfig.NowSelctActivityId)
        return
    end

    mDrawRewardTyep = mDrawTyep.Type_10
    local msg = Activity4_pb.Activity128LotteryReq()
    msg.freeLottery = false
    msg.count = mDrawRewardTyep
    common:sendPacket(HP_pb.ACTIVITY128_UR_RANK_LOTTERY_C, msg)
end

function ActTimeLimit_128:onRankClick_1(container)
    -- 实时排行
    mCurrentRankType = 1
    self:refreshRank()
    -- local rankData = mServerData.rankData[mCurrentRankType]
end

function ActTimeLimit_128:onRankClick_2(container)
    -- 昨日排行
    mCurrentRankType = 2
    self:refreshRank()

    -- local rankData = mServerData.rankData[mCurrentRankType]
end

function ActTimeLimit_128:onRefreshRankClick(container)
    if mCurrentRankType == 2 then
        return
    end
    self:requestRankData(1)
end

function ActTimeLimit_128:onRankHelpClick(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACT_128_RANK)
end

function ActTimeLimit_128:onBaoXiangClick_1(container)
    self:sendGetBoxAwardsMessage(1)
end

function ActTimeLimit_128:onBaoXiangClick_2(container)
    self:sendGetBoxAwardsMessage(2)
end

function ActTimeLimit_128:onBaoXiangClick_3(container)
    self:sendGetBoxAwardsMessage(3)
end

function ActTimeLimit_128:onBaoXiangClick_4(container)
    self:sendGetBoxAwardsMessage(4)
end

function ActTimeLimit_128:sendGetBoxAwardsMessage(index)
    if mBoxStateTabel[index] == BaoXiangStage.KeLingQu then
        -- 领取宝箱奖励
        local msg = Activity4_pb.Activity128BoxReq()
        msg.boxId = index
        common:sendPacket(HP_pb.ACTIVITY128_UR_RANK_BOX_C, msg)
    else
        -- 查看宝箱奖励内容
        local boxData = ActTimeLimit_128.getBoxReward()
        local rewardStr = boxData[index].reward
        local rewardItems = { }
        if rewardStr ~= nil then
            for _, item in ipairs(common:split(rewardStr, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"));
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                } );
            end
        end

        RegisterLuaPage("GodEquipPreview")
        ShowEquipPreviewPage(rewardItems, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@RewardPreviewTitleTxt"))
        PageManager.pushPage("GodEquipPreview")
    end
end

function ActTimeLimit_128:onIllustatedOpen(container)
    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(_MercenaryInfo.itemId)
end

function ActTimeLimit_128:onRewardPreview(container)

    require("NewSnowPreviewRewardPage")
    local TreasureCfg = mRewardConfigData
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
    NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2", GameConfig.HelpKey.HELP_ACT_128)
    PageManager.pushPage("NewSnowPreviewRewardPage")
end


function ActTimeLimit_128:createRewardItem(index)
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
TreasureRaiderPageNew = CommonPage.newSub(ActTimeLimit_128, thisPageName, option)

return ActTimeLimit_128