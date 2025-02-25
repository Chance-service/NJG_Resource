local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "DayLogin30Page"
local HP_pb = require("HP_pb")
local Activity4_pb = require("Activity4_pb")

require("MainScenePage")

local DayLogin30Page = {
}
local configData = nil
local mIsInitScrollView = false
local mSigninCount = 0
local mItemList = { }
local mBoxList = { }
local currentDay = 0
local serverData = nil
local leftSupplementaryCount = 0
local mBoxBar = nil
local mItemHeight = 0
local option = {
    ccbiFile = "DayLogin30.ccbi",
    handlerMap = {
        onReturn = "onReturn",
        onClick = "onClick",
    },
}
local parentPage = nil

local supplementaryCountTable = { }

local opcodes = {
    ACC_LOGIN_SIGNED_INFO_C = HP_pb.ACC_LOGIN_SIGNED_INFO_C,
    ACC_LOGIN_SIGNED_INFO_S = HP_pb.ACC_LOGIN_SIGNED_INFO_S,
    ACC_LOGIN_SIGNED_AWARD_C = HP_pb.ACC_LOGIN_SIGNED_AWARD_C,
    ACC_LOGIN_SIGNED_OPENCHEST_C = HP_pb.ACC_LOGIN_SIGNED_OPENCHEST_C,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S
}

local GetBoxDay = { }
local ItemCount = 30
-----------------------------------
-- Item
local DayLogin30ItemState = {
    Null = 0,
    HaveReceived = 1,
    Supplementary = 2,
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
        local itemInfo = configData[self.id]
        if itemInfo.items ~= nil then
            for _, item in ipairs(common:split(itemInfo.items, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"))
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                } )
            end
        end
        self.rewardData = rewardItems[1]
    end

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.rewardData.type, self.rewardData.itemId, self.rewardData.count)

    local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)

    NodeHelper:setSpriteImage(container, { mIconSprite = resInfo.icon, mDiBan = iconBgSprite })
    -- NodeHelper:setColorForLabel(container, { mNumLabel = ConfigManager.getQualityColor()[resInfo.quality].textColor })
    NodeHelper:setQualityFrames(container, { mQuality = resInfo.quality })
    local icon = container:getVarSprite("mIconSprite")
    icon:setPosition(ccp(0, 0))

    local mIconSprite = container:getVarSprite("mIconSprite")
    NodeHelper:setStringForLabel(container, { mNumLabel = (self.rewardData.type == 40000 and "" or tostring(resInfo.count)) })

    -- self.mReceivedSprite = self.container:getVarSprite("mReceivedSprite")
    local mGetSprite = container:getVarSprite("mGetSprite")
    local mDayLabel = container:getVarLabelTTF("mDayLabel")
    local mItemNode = container:getVarNode("mItemNode")
    local mTodayNode = container:getVarNode("mTodayNode")
    local mMask = container:getVarSprite("mMask")
    local mBack = container:getVarSprite("mCalendar")

    if self.mState == DayLogin30ItemState.HaveReceived then
        mMask:setVisible(true)
        mGetSprite:setVisible(true)
        mDayLabel:setString(common:getLanguageString("@Receive"))
        mDayLabel:setColor(ccc3(248, 205, 127))
    end

    if self.mState == DayLogin30ItemState.Supplementary then
        mMask:setVisible(true)
        mGetSprite:setVisible(false)
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(ccc3(56, 50, 53))
    end

    if self.mState == DayLogin30ItemState.Null then
        mMask:setVisible(currentDay > self.id)
        mGetSprite:setVisible(false)
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(currentDay > self.id and ccc3(56, 50, 53) or ccc3(81, 75, 78))
        mBack:setVisible(false)
    end

    if self.mState == DayLogin30ItemState.CanGet then
        if currentDay == self.id then
            mGetSprite:setVisible(false)
        end
        mMask:setVisible(false)
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
    CCLuaLog("DayLogin30Item ---------- " .. self.id)
    CCLuaLog("DayLogin30Item State---------- " .. self.mState)
    if self.mState == DayLogin30ItemState.CanGet then
        local msg = Activity4_pb.LoginSignedAwardReq()
        msg.Level = self.id
        if self.mState == DayLogin30ItemState.CanGet then
            msg.type = 1
        end
        common:sendPacket(opcodes.ACC_LOGIN_SIGNED_AWARD_C, msg, false)
    end
end

-----------------------------------------------

function DayLogin30Page:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function DayLogin30Page:createPage(_parentPage)
    
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

function DayLogin30Page:onEnter(container)
    self.container = container
    self:initData()
    self:initUi(container)
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)

    self:sendLoginSignedInfoReqMessage()
    GameConfig.isJump30DayPage = false
    CCUserDefault:sharedUserDefault():setStringForKey("Open30DayPage" .. UserInfo.playerInfo.playerId, tostring(GamePrecedure:getInstance():getServerTime()))
    CCUserDefault:sharedUserDefault():setIntegerForKey("FirstOpen30DayPage" .. UserInfo.serverId .. UserInfo.playerInfo.playerId, 1)
    self:SetSpine(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["DayLogin30Page"] = container
end
function DayLogin30Page:SetSpine(container)
local spinePath = "Spine/NG2D"
    local spineName = "NG2D_18"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    parentNode:setPosition(ccp(0,-600))
    parentNode:removeAllChildrenWithCleanup(true)
    local Ani01 = CCCallFunc:create(function()
            parentNode:addChild(spineNode)
            spine:runAnimation(1, "animation", -1)
    end)
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(0.2))
    array:addObject(Ani01)
    array:addObject(CCDelayTime:create(2))
    parentNode:runAction(CCSequence:create(array))
end

function DayLogin30Page:initData()
    mItemHeight = 0
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local curMonth = curServerTime.month
    configData = self:getCurrentMonthCfg(ConfigManager.getDayLogin30Data(), curMonth)

    ItemCount = 0
    for i = 1, 31 do
        if configData[i] ~= nil then
            ItemCount = ItemCount + 1
        end
    end
    mItemList = { }
    serverData = nil
    mIsInitScrollView = false
    mSigninCount = 0
    leftSupplementaryCount = 0

    for i = 0, 15 do
        supplementaryCountTable[i] = ConfigManager.getVipCfg()[i].dayLogin30SupplementaryCount
    end
    local aaa = 0
end

function DayLogin30Page:initUi(container)
    local mInfoNode = container:getVarNode("mInfoNode")
    local worldX, _ = GetScreenWidthAndHeight()
    local mInfoNodeWorld = mInfoNode:getParent():convertToWorldSpace(ccp(mInfoNode:getPositionX(), mInfoNode:getPositionY()))
    local mInfoNodeNewPos = mInfoNode:getParent():convertToNodeSpace(ccp(worldX / 2, mInfoNodeWorld.y))
    mInfoNode:setPosition(mInfoNodeNewPos)
    local strTabel = {
        mTitle = common:getLanguageString("@DayLogin30Title"),
        -- title
        mLeiJiDengLuText = common:getLanguageString("@DayLogin30_LoginDay"),
        -- title
        mBuQianCiShuText = common:getLanguageString("@DayLogin30_CanSupplement"),-- title
    }

    NodeHelper:setStringForLabel(container, strTabel)
end

function DayLogin30Page:onExit(container)
    mItemHeight = 0
    parentPage:removePacket(opcodes)
    if container.mScrollView then
        container.mScrollView:removeAllCell()
        container.mScrollView = nil
        container.mScrollViewRootNode = nil
    end
end

function DayLogin30Page:getTableLen(t)
    local len = 0
    for k, v in pairs(t) do
        len = len + 1
    end
    return len
end

function DayLogin30Page:refreshAll(container)
    currentDay = serverData.monthOfDay
    leftSupplementaryCount = supplementaryCountTable[UserInfo.playerInfo.vipLevel] - (self:getTableLen(serverData.supplSignedDays) or 0)
    if leftSupplementaryCount <= 0 then
        leftSupplementaryCount = 0
    end
    local strTabel = {
        mLoginDayCountText = self:getTableLen(serverData.signedDays) + self:getTableLen(serverData.supplSignedDays),-- .. " / " .. ItemCount,
        mSupplementCountText = leftSupplementaryCount .. " / " .. supplementaryCountTable[UserInfo.playerInfo.vipLevel]
    }

    NodeHelper:setStringForLabel(container, strTabel)
    mSigninCount = self:getTableLen(serverData.signedDays) + self:getTableLen(serverData.supplSignedDays)

    self:refreshItem(container)

    local id = Const_pb.ACCUMULATIVE_LOGIN_SIGNED
    if isGetAward and (getTabelLength(serverData.signedDays) + getTabelLength(serverData.supplSignedDays)) >= currentDay then
        ActivityInfo.changeActivityNotice(id)
    end
    if leftSupplementaryCount == 0 then
        if isGetAward then
            ActivityInfo.changeActivityNotice(id)
        end
    end

    if mItemList[currentDay].mState == DayLogin30ItemState.CanGet then
        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", true)
    else
        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", false)
    end
end

function DayLogin30Page:refreshItem(container)
    -- mItemList
    if not mIsInitScrollView then
        self:initSecondScrollView(container)
        mIsInitScrollView = true
    end

    for k, v in pairs(mItemList) do
        v:setState(DayLogin30ItemState.Null)
    end

    if mItemList[currentDay] then
        mItemList[currentDay]:setState(DayLogin30ItemState.CanGet)
    end
    for k, v in pairs(serverData.signedDays) do
        mItemList[v]:setState(DayLogin30ItemState.HaveReceived)
    end
    for k, v in pairs(serverData.supplSignedDays) do
        mItemList[v]:setState(DayLogin30ItemState.HaveReceived)
    end
    for i = currentDay + 1, #mItemList do
        if mItemList[i] then
            mItemList[i]:setState(DayLogin30ItemState.Null)
        end
    end
    local count = leftSupplementaryCount
    for i = 1, currentDay - 1 do
        if mItemList[i] then
            if mItemList[i]:getStage() == DayLogin30ItemState.Null and count > 0 then
                mItemList[i]:setState(DayLogin30ItemState.Supplementary)
            end
        end
    end
    for k, v in pairs(mItemList) do
        v:refresh(v:getCCBFileNode())
    end
end

function DayLogin30Page:onExecute(container)

end

function DayLogin30Page:onReturn(container)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return
    end
    common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
    PageManager.popPage(thisPageName)
    if not GameConfig.isIOSAuditVersion then
        -- 不是审核走正常流程
        if GetIsShowLimit124() then
            PageManager.pushPage("ActTimeLimit_124")
        end
        require("ActTimeLimit_137")
        local ispop = ActTimeLimit_137_isPopPage()
        if ispop then
            PageManager.pushPage("ActTimeLimit_137")
        end

        require("ActTimeLimit_140")
        ispop = ActTimeLimit_140_isPopPage()
        if ispop then
            PageManager.pushPage("ActTimeLimit_140")
        end
    end
end

function DayLogin30Page:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACC_LOGIN_SIGNED_INFO_S then
        local msg = Activity4_pb.LoginSignedRep()
        msg:ParseFromString(msgBuff)
        serverData = { }
        serverData.monthOfDay = msg.monthOfDay
        --if serverData.monthOfDay > ItemCount then
        --    serverData.monthOfDay = ItemCount
        --end
        serverData.signedDays = { }
        serverData.supplSignedDays = { }
        serverData.gotAwardChest = { }
        for i = 1, #msg.signedDays do
            serverData.signedDays[msg.signedDays[i]] = msg.signedDays[i]
        end

        for i = 1, #msg.supplSignedDays do
            serverData.supplSignedDays[msg.supplSignedDays[i]] = msg.supplSignedDays[i]
        end

        for i = 1, #msg.gotAwardChest do
            serverData.gotAwardChest[msg.gotAwardChest[i]] = msg.gotAwardChest[i]
        end

        local RewardRedPage=require("Reward.RewardRedPointMgr")
        RewardRedPage:DailyLoginRedPoint(msg)

        self:refreshAll(self.container)
        --self:autoGetReward(self.container)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end

--

function DayLogin30Page:initSecondScrollView(container)
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
    if serverData.monthOfDay > 15 then
        if ItemCount < 31 then
            container.mScrollView:setContentOffset(ccp(0, 0))
        else
            if serverData.monthOfDay == 31 then
                container.mScrollView:setContentOffset(ccp(0, 0))
            else
                container.mScrollView:setContentOffset(ccp(0, 0 - mItemHeight - 5))
            end
        end
    end
end

function DayLogin30Page:sendLoginSignedInfoReqMessage()
    local msg = Activity4_pb.LoginSignedInfoReq()
    common:sendPacket(opcodes.ACC_LOGIN_SIGNED_INFO_C, msg, false)
end

function DayLogin30Page:autoGetReward()
    --for i = 1, currentDay - 1 do
        if mItemList[currentDay] then
            --if mItemList[i]:getStage() == DayLogin30ItemState.Null and count > 0 then
                mItemList[currentDay]:onAutoClick()
            --end
        end
    --end
end

function DayLogin30Page:onClick()
    if mItemList[currentDay] then
        mItemList[currentDay]:onAutoClick()
    end
end

function DayLogin30Page:getCurrentMonthCfg(allConfig, curMonth)
    local currentConfig = {}
    for k, v in pairs(allConfig) do
        if k < 1000 and v.month == curMonth then
            currentConfig[v.day] = v
        elseif k > 1000 then
            currentConfig[k] = v
        end
    end
    return currentConfig
end

return DayLogin30Page