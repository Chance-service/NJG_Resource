local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "FreeSummon"
local HP_pb = require("HP_pb")
local Activity5_pb = require("Activity5_pb")
require("Util.LockManager")

require("MainScenePage")

local CostLoginPage = {
}
local configData = nil
local mIsInitScrollView = false
local mSigninCount = 0
local mItemList = { }
local mBoxList = { }
local currentDay = 0
local serverData = nil
local mBoxBar = nil
local mItemHeight = 0
local option = {
    ccbiFile = "Free888Summons.ccbi",
    handlerMap = {
        onReturn = "onReturn",
        onClick = "onClick",
    },
}
local parentPage = nil


local opcodes = {
    ACTIVITY190_STEP_SUMMOM_S=HP_pb.ACTIVITY190_STEP_SUMMOM_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S
}

local GetBoxDay = { }
local ItemCount = 30
local RewardCount = 0
-----------------------------------
-- Item
local DayLogin30ItemState = {
    Null = 0,
    HaveReceived = 1,
    CanGet = 3,
}

local BaoXiangStage = {
    Null = 0, -- 不能领取
    YiLingQu = 1, -- 已经领取
    KeLingQu = 2, -- 可领取
}

local DayLogin30Item = {
    ccbiFile = "DayLogin30Item.ccbi",
}

local selfContainer = nil

local DATA_TYPE = 1

function DayLogin30Item:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function DayLogin30Item:onRefreshContent(ccbRoot)
    self:refresh(ccbRoot:getCCBFileNode())
end

function DayLogin30Item:initUi()
end

function DayLogin30Item:setState(state)
    self.mState = state
end

function DayLogin30Item:getStage()
    return self.mState
end

function DayLogin30Item:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function DayLogin30Item:refresh(container)
    if container == nil then
        return
    end

    if self.rewardData == nil then
        local rewardItems = { }
        local mID = DATA_TYPE*10000 + self.id
        local itemInfo = configData[mID]
        rewardItems=itemInfo.Rewards
        self.rewardData = rewardItems
    end
    local mGetSprite = container:getVarSprite("mGetSprite")
    local mDayLabel = container:getVarLabelTTF("mDayLabel")
    local mItemNode = container:getVarNode("mItemNode")
    local mTodayNode = container:getVarNode("mTodayNode")
    local mMask = container:getVarSprite("mMask")
    local mBack = container:getVarSprite("mCalendar")

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.rewardData.type, self.rewardData.itemId, self.rewardData.count)
    
    local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)
    
    NodeHelper:setSpriteImage(container, {mIconSprite = resInfo.icon, mDiBan = iconBgSprite})
    NodeHelper:setQualityFrames(container, { mQuality = resInfo.quality })
    NodeHelper:setStringForLabel(container, { mNumLabel = tostring(resInfo.count) })
    if self.mState == DayLogin30ItemState.HaveReceived then
        mMask:setVisible(true)
        mGetSprite:setVisible(true)
        mDayLabel:setString(common:getLanguageString("@Receive"))
        mDayLabel:setColor(ccc3(248, 205, 127))
        mBack:setVisible(false)
    elseif self.mState == DayLogin30ItemState.Null then
        mMask:setVisible(currentDay > self.id)
        mGetSprite:setVisible(false)
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(currentDay > self.id and ccc3(56, 50, 53) or ccc3(81, 75, 78))
        mBack:setVisible(false)
    elseif self.mState == DayLogin30ItemState.CanGet then
        if currentDay == self.id then
            mGetSprite:setVisible(false)
        end
        mMask:setVisible(false) 
        mBack:setVisible(true)
        mGetSprite:setVisible(false)
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(ccc3(81, 75, 78))
    end
    for i = 1, 5 do -- icon星星
        container:getVarSprite("mStar" .. i):setVisible(self.rewardData.type == 40000 and resInfo.quality >= i)
    end

    mTodayNode:setVisible(currentDay == self.id)

end

-- item
function DayLogin30Item:onClick(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    CCLuaLog("DayLogin30Item ---------- " .. self.id)

    if self.rewardData ~= nil then
        GameUtil:showTip(container:getVarNode("mIconSprite"), self.rewardData)
    end
end
-----------------------------------
function DayLogin30Item:onAutoClick()
    if self.mState == DayLogin30ItemState.CanGet then
        local msg = Activity5_pb.StepSummonReq()
        msg.action = 1
        msg.type = DATA_TYPE
        common:sendPacket(HP_pb.ACTIVITY190_STEP_SUMMON_C, msg, true)
    end
end

-----------------------------------------------

function CostLoginPage:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function CostLoginPage:createPage(_parentPage)
    
    local slf = self

    parentPage = _parentPage

    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function (eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    return container
end

function CostLoginPage:onEnter(container)
    mItemList = { }
    mIsInitScrollView = false
    mSigninCount = 0
    selfContainer = container
    NodeHelper:setNodesVisible(container,{mOpenNode = true,mBannerCost = true,mBannerFree = false})
    self:initData()
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    --NodeHelper:setSpriteImage(container,{mBanner = "300 Summons_Text.png"})
    self:sendLoginSignedInfoReqMessage()
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["CostLoginPage"] = container
end

function CostLoginPage:initData()
    local container = selfContainer
    mItemHeight = 0
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local curMonth = curServerTime.month
    configData = ConfigManager.getFreeSummonData3()

    ItemCount = 0
    local CostCount = 1
    RewardCount = 0
    for _,data in pairs (configData) do
        if data.type == DATA_TYPE then
            ItemCount = ItemCount + 1
            RewardCount = RewardCount + data.Rewards.count
            CostCount = data.needCount
        end
    end
    NodeHelper:setStringForLabel(container,{mCostOpen = common:getLanguageString("@RechargeCountOpen",CostCount - serverData.BuyCount)})
    if next(serverData) and serverData.BuyCount >= CostCount then
        NodeHelper:setNodesVisible(container,{mOpenNode = false})
    end
    NodeHelper:setStringForLabel(container,{ mCostCount = CostCount,mRewardCount = RewardCount})
end

function CostLoginPage:onExit(container)
    mItemHeight = 0
    parentPage:removePacket(opcodes)
    if container.mScrollView then
        container.mScrollView:removeAllCell()
        container.mScrollView = nil
        container.mScrollViewRootNode = nil
    end
    selfContainer = nil
end

function CostLoginPage:getTableLen(t)
    local len = 0
    for k, v in pairs(t) do
        len = len + 1
    end
    return len
end

function CostLoginPage:refreshAll(container)
    currentDay = serverData.monthOfDay
    local text=common:getLanguageString("@DayLogin30_LoginDay").." "..common:getLanguageString("@DayLogin30_CurrontDay",serverData.signedDays)
    NodeHelper:setStringForLabel(container,{mText=text})
    self:refreshItem(container)
    if currentDay <0 then 
        NodeHelper:setMenuItemEnabled(container, "mBtn", false)
        --NodeHelper:setNodesVisible(container,{mOpenNode = true})
        return 
    end
    if mItemList[currentDay].mState == DayLogin30ItemState.CanGet then
        NodeHelper:setMenuItemEnabled(container, "mBtn", true)
    else
        NodeHelper:setMenuItemEnabled(container, "mBtn", false)
    end
end

function CostLoginPage:refreshItem(container)
    -- mItemList
    if not mIsInitScrollView then
        self:initSecondScrollView(container)
        mIsInitScrollView = true
    end

    for k, v in pairs(mItemList) do
        v:setState(DayLogin30ItemState.Null)
    end

    if mItemList[currentDay] then
        for i=1,currentDay do
            mItemList[i]:setState(DayLogin30ItemState.CanGet)
        end
    end
    for i=1,serverData.signedDays do
        if mItemList[i] then
            mItemList[i]:setState(DayLogin30ItemState.HaveReceived)
        end
    end
    for i = currentDay + 1, #mItemList do
        if mItemList[i] then
            mItemList[i]:setState(DayLogin30ItemState.Null)
        end
    end
    for k, v in pairs(mItemList) do
        v:refresh(v:getCCBFileNode())
    end
end

function CostLoginPage:onExecute(container)

end

function CostLoginPage:onReturn(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
    PageManager.popPage(thisPageName)
end
function CostLoginPage:setSeverData(msg)
     serverData = { }
     serverData.monthOfDay = msg.nowDay       
     serverData.gotAwardChest = { }
     serverData.signedDays = msg.takeDay[DATA_TYPE]
     serverData.BuyCount = msg.count
     local RewardRedPage=require("Reward.RewardRedPointMgr")
     --RewardRedPage:FreeSummonRedPointSync(msg)
     if selfContainer then
        self:initData()
        self:refreshAll(selfContainer)
     end
    -- if msg.action==1 then
    --     MessageBoxPage:Msg_Box(common:getLanguageString("@HasDraw"))
    -- end
end
function CostLoginPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACTIVITY190_STEP_SUMMOM_S then
        --local msg = Activity5_pb.FreeSummonResp()
        --msg:ParseFromString(msgBuff)
       
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end

function CostLoginPage:AllSigned()
   return serverData and serverData.signedDays == ItemCount
end
--

function CostLoginPage:initSecondScrollView(container)
    container.mScrollView = container:getVarScrollView("mContent")

    if container.mScrollView == nil or container.mScrollViewRootNode then return end
    container.mScrollViewRootNode = container.mScrollView:getContainer()
    container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
    container.m_pScrollViewFacade:init(5, 3)

    container.mScrollView:removeAllCell()
    for i = 1, ItemCount do
        local cell = CCBFileCell:create()
        local panel = DayLogin30Item:new({ id = i, ccbiFile = cell, mState = 0, rewardData = nil })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(DayLogin30Item.ccbiFile)
        container.mScrollView:addCellBack(cell)
        local height = cell:getContentSize().height
        if height > mItemHeight then
            mItemHeight = height
        end
        mItemList[i] = panel
    end

    container.mScrollView:orderCCBFileCells()
end

function CostLoginPage:sendLoginSignedInfoReqMessage()
    local msg = Activity5_pb.StepSummonReq()
    msg.action=0
    common:sendPacket(HP_pb.ACTIVITY190_STEP_SUMMON_C, msg, false)
end


function CostLoginPage:onClick()
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON_900) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON_900))
    else
        if mItemList[currentDay] then
            mItemList[currentDay]:onAutoClick()
        end
    end
end


return CostLoginPage