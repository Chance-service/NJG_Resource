--超值補給
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "IAPSubPage_Calendar"
local HP_pb = require("HP_pb")
local Activity5_pb = require("Activity5_pb")
local BuyManager = require("BuyManager")
require("MainScenePage")

local Calendar = {}
local configData = nil
local mIsInitScrollView = false
local mItemList = {}
local currentDay = 0
local serverData = nil
local mItemHeight = 0
local curCalendar = 1

local option = {
    ccbiFile = "Calendar.ccbi",
    handlerMap = {
        onReturn = "onReturn",
        onClick = "onClick",
        onNR = "onNR",
        onRR = "onPR",
    },
}
local parentPage = nil

local requesting = false
local supplementaryCountTable = {}

local opcodes = {
    SUPPORT_CALENDAR_ACTION_S = HP_pb.SUPPORT_CALENDAR_ACTION_S,
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S
}

local GetBoxDay = {}
local ItemCount = 30

local NR_CALENDAR=7
local PR_CALENDAR=8
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
local timestr=""

local DayLogin30Item = {
    ccbiFile = "DayLogin30Item.ccbi",
}
function DayLogin30Item:new(o)
    o = o or {}
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
        local rewardItems = {}
        local itemInfo = configData[self.id]
        if itemInfo.items ~= nil then
            for _, item in ipairs(common:split(itemInfo.items, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"))
                table.insert(rewardItems, {
                    type = tonumber(_type),
                    itemId = tonumber(_id),
                    count = tonumber(_count)
                })
            end
        end
        self.rewardData = rewardItems[1]
    end
    
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.rewardData.type, self.rewardData.itemId, self.rewardData.count)
    
    local iconBgSprite = NodeHelper:getImageBgByQuality(resInfo.quality)
    
    NodeHelper:setSpriteImage(container, {mIconSprite = resInfo.icon, mDiBan = iconBgSprite})
    -- NodeHelper:setColorForLabel(container, { mNumLabel = ConfigManager.getQualityColor()[resInfo.quality].textColor })
    NodeHelper:setQualityFrames(container, {mQuality = resInfo.quality})
    local icon = container:getVarSprite("mIconSprite")
    icon:setPosition(ccp(0, 0))
    
    local mIconSprite = container:getVarSprite("mIconSprite")
    NodeHelper:setStringForLabel(container, {mNumLabel = (self.rewardData.type == 40000 and "" or tostring(resInfo.count))})
    
    -- self.mReceivedSprite = self.container:getVarSprite("mReceivedSprite")
    local mGetSprite = container:getVarSprite("mGetSprite")
    local mDayLabel = container:getVarLabelTTF("mDayLabel")
    local mItemNode = container:getVarNode("mItemNode")
    local mTodayNode = container:getVarNode("mTodayNode")
    local mMask = container:getVarSprite("mMask")
    local mBack = container:getVarSprite("mCalendar")
    
    if self.mState == DayLogin30ItemState.HaveReceived then
        mBack:setVisible(false)
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
        mBack:setVisible(false)
        mMask:setVisible(currentDay > self.id)
        mGetSprite:setVisible(false)
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(currentDay > self.id and ccc3(56, 50, 53) or ccc3(81, 75, 78))
    end
    
    if self.mState == DayLogin30ItemState.CanGet then
        mBack:setVisible(true)
        mGetSprite:setVisible(false)
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
    if #serverData.signedDays == currentDay then return end
    local msg = Activity5_pb.SupportCalendarReq()
    if serverData.isbuy then
        msg.action = 2
        msg.type = curCalendar
        common:sendPacket(HP_pb.SUPPORT_CALENDAR_ACTION_C, msg, false)
    else
        if curCalendar==1 then
            BuyItem(NR_CALENDAR)
        else
            BuyItem(PR_CALENDAR)
        end
    end
    
    
end

-----------------------------------------------
function Calendar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 建立頁面UI ]]
function Calendar:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    
    return container
end

function Calendar:onEnter(container)
    self.container = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    self:sendLoginSignedInfoReqMessage()
    GameConfig.isJump30DayPage = false
    requesting = false
    CCUserDefault:sharedUserDefault():setStringForKey("Open30DayPage" .. UserInfo.playerInfo.playerId, tostring(GamePrecedure:getInstance():getServerTime()))
    CCUserDefault:sharedUserDefault():setIntegerForKey("FirstOpen30DayPage" .. UserInfo.serverId .. UserInfo.playerInfo.playerId, 1)
    NodeHelper:setNodesVisible(container, {
        mNRNode = true,
        mPRNode = false,
        NRIcon = true,
        PRIcon = false, })
    NodeHelper:setMenuItemsEnabled(container, {NRBtn = false, PRBtn = true,mBtn=false})
    NodeHelper:setStringForLabel(self.container,{mCost=Calendar_getPrice(NR_CALENDAR)})
    --self:ShopListQuest()
    self:initData(false)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["Calendar"] = container
end
function Calendar:ShopListQuest()
    if not requesting then
        --requesting = true
        --
        --local msg = Recharge_pb.HPFetchShopList()
        --msg.platform = GameConfig.win32Platform
        --CCLuaLog("PlatformName2:" .. msg.platform)
        --pb_data = msg:SerializeToString()
        --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    end
end
function Calendar:initData(isPR)
    mItemHeight = 0
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local curMonth = curServerTime.month
    local curYear=curServerTime.year
    local end_of_month=0
    -- 计算月底的日期
    if curMonth~=12 then
        end_of_month=os.time{year = curYear, month = curMonth + 1, day = 1,hour=0,min=0,sec=0}-1
    else
        end_of_month=os.time{year = curYear+1, month = 1, day = 1,hour=0,min=0,sec=0}-1
    end
    -- 计算剩余的秒数
    local seconds_until_end_of_month = end_of_month-curTime

    configData = self:getCurrentMonthCfg(ConfigManager.SupportCalender30(), curMonth)
    timestr=common:second2DateString2(seconds_until_end_of_month, false);
    NodeHelper:setStringForLabel(self.container, {refreshAutoCountdownText = timestr})
    ItemCount = 0
    for i = 1, 31 do
        if configData[i] ~= nil then
            ItemCount = ItemCount + 1
        end
    end
    mIsInitScrollView = false
    
    for i = 0, 15 do
        supplementaryCountTable[i] = ConfigManager.getVipCfg()[i].dayLogin30SupplementaryCount
    end
end

function Calendar:onExit(container)
    mItemHeight = 0
    parentPage:removePacket(opcodes)
    if container.mScrollView then
        container.mScrollView:removeAllCell()
        container.mScrollView = nil
        container.mScrollViewRootNode = nil
    end
    PageManager.refreshPage("MainScenePage", "refreshInfo")
end

function Calendar:getTableLen(t)
    local len = 0
    for k, v in pairs(t) do
        len = len + 1
    end
    return len
end

function Calendar:refreshAll(container)
    parentPage:updateCurrency()
    if serverData.isbuy then
        NodeHelper:setStringForLabel(container,{mCost=common:getLanguageString("@Receive")})
        NodeHelper:setNodesVisible(container,{mCoin=false})
    else
        NodeHelper:setNodesVisible(container,{mCoin=true})
    end
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    currentDay = curServerTime.day
     if #serverData.signedDays == currentDay then
         NodeHelper:setMenuItemsEnabled(container,{mBtn=false})
     else
         NodeHelper:setMenuItemsEnabled(container,{mBtn=true})
     end
    self:refreshItem(container)
end

function Calendar:refreshItem(container)
    -- mItemList
    if not mIsInitScrollView then
        self:initSecondScrollView(container)
        mIsInitScrollView = true
    end
    
    for k, v in pairs(mItemList) do
        v:setState(DayLogin30ItemState.Null)
    end
    for i = 1, currentDay do
        if mItemList[i] then
            mItemList[i]:setState(DayLogin30ItemState.CanGet)
        end
    end
    
    
    for i = currentDay + 1, #mItemList do
        if mItemList[i] then
            mItemList[i]:setState(DayLogin30ItemState.Null)
        end
    end
    for k, v in pairs(serverData.signedDays) do
        mItemList[v]:setState(DayLogin30ItemState.HaveReceived)
    end
    for k, v in pairs(mItemList) do
        v:refresh(v:getCCBFileNode())
    end
end

function Calendar:onExecute(container)

end

function Calendar:onReturn(container)
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

function Calendar:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SUPPORT_CALENDAR_ACTION_S then
        local msg = Activity5_pb.SupportCalendarRep()
        msg:ParseFromString(msgBuff)
        serverData = {}
        serverData.action = msg.action
        serverData.isbuy = msg.buy
        serverData.curMonth = msg.curMonth
        serverData.signedDays = {}
        for i = 1, #msg.signedDays do
            serverData.signedDays[msg.signedDays[i]] = msg.signedDays[i]
        end
        local IAPRedPage=require("IAP.IAPRedPointMgr")
        IAPRedPage:ClaendarRedPointSync(msg)
        if serverData.action==2 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@HasDraw"))
        end
        self:refreshAll(self.container)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
        --MessageBoxPage:Msg_Box(common:getLanguageString("@RewardItem"))
                self:refreshAll(self.container)
    elseif opcode==HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg=msg.shopItems
        --
        --requesting = false
    end
end

--
function Calendar:initSecondScrollView(container)
    container.mScrollView = container:getVarScrollView("mContent")
    
    if container.mScrollView == nil then return end
    container.mScrollViewRootNode = container.mScrollView:getContainer()
    container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
    container.m_pScrollViewFacade:init(5, 3)
    
    container.mScrollView:removeAllCell()
    for i = 1, ItemCount do
        local cell = CCBFileCell:create()
        local panel = DayLogin30Item:new({id = i, ccbiFile = cell, mState = 0, rewardData = nil})
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
-- if #serverData.signedDays> 15 then
--     if ItemCount < 31 then
--         container.mScrollView:setContentOffset(ccp(0, 0))
--     else
--         if serverData.monthOfDay == 31 then
--             container.mScrollView:setContentOffset(ccp(0, 0))
--         else
--             container.mScrollView:setContentOffset(ccp(0, 0 - mItemHeight - 5))
--         end
--     end
-- end
end

function Calendar:sendLoginSignedInfoReqMessage()
    local msg = Activity5_pb.SupportCalendarReq()
    msg.action = 0
    msg.type = curCalendar
    common:sendPacket(HP_pb.SUPPORT_CALENDAR_ACTION_C, msg, false)
end

function Calendar:onClick()
    if mItemList[currentDay] then
        mItemList[currentDay]:onAutoClick()
    end
end
function Calendar:getCurrentMonthCfg(allConfig, curMonth)
    local currentConfig = {}
    local cfg = self:SortConfig(allConfig)
    for k, v in pairs(cfg) do
        if k < 1000 and v.month == curMonth then
            currentConfig[v.day] = v
        end
    end
    return currentConfig
end
function Calendar:SortConfig(Config)
    local PRcfg = {};
    local NRcfg = {};
    for k, v in pairs(Config) do
        if v.type == 1 then
            table.insert(NRcfg, v)
        elseif v.type == 2 then
            table.insert(PRcfg, v)
        end
    end
    if (curCalendar == 2) then return PRcfg else return NRcfg end
end

function Calendar:onNR(container)
    curCalendar = 1
    self:sendLoginSignedInfoReqMessage()
    NodeHelper:setNodesVisible(container, {
        mNRNode = true,
        mPRNode = false,
        NRIcon = true,
        PRIcon = false, })
    NodeHelper:setMenuItemsEnabled(container, {NRBtn = false, PRBtn = true})
    self:initData(false)
    NodeHelper:setStringForLabel(self.container,{mCost=Calendar_getPrice(NR_CALENDAR)})
end
function Calendar:onPR(container)
    curCalendar = 2
    self:sendLoginSignedInfoReqMessage()
    NodeHelper:setNodesVisible(container, {
        mNRNode = false,
        mPRNode = true,
        NRIcon = false,
        PRIcon = true, })
    NodeHelper:setMenuItemsEnabled(container, {NRBtn = true, PRBtn = false})
    self:initData(true)
    NodeHelper:setStringForLabel(self.container,{mCost=Calendar_getPrice(PR_CALENDAR)})
end

function Calendar:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        CCLuaLog(">>>>>>onReceiveMessage Calendar")
        Calendar:sendLoginSignedInfoReqMessage()
		--self:ShopListQuest()
	end
end
function Calendar_getPrice(id)
   local itemInfo = nil
   for i=1 ,#RechargeCfg do
       if tonumber(RechargeCfg[i].productId)==id then
           itemInfo=RechargeCfg[i]
           break
       end
   end
   return itemInfo.productPrice
end
function BuyItem(id)
   local itemInfo = nil
   for i=1 ,#RechargeCfg do
       if tonumber(RechargeCfg[i].productId)==id then
           itemInfo=RechargeCfg[i]
           break
       end
   end
    local buyInfo = BUYINFO:new()
    buyInfo.productType = itemInfo.productType
    buyInfo.name = itemInfo.name;
    buyInfo.productCount = 1
    buyInfo.productName = itemInfo.productName
    buyInfo.productId = itemInfo.productId
    buyInfo.productPrice = itemInfo.productPrice
    buyInfo.productOrignalPrice = itemInfo.gold

    buyInfo.description = ""
    if itemInfo:HasField("description") then
        buyInfo.description = itemInfo.description
    end
    buyInfo.serverTime = GamePrecedure:getInstance():getServerTime()

    local _type = tostring(itemInfo.productType)
     local _ratio = tostring(itemInfo.ratio)
    local extrasTable = { productType = _type, name = itemInfo.name, ratio = _ratio }
    buyInfo.extras = json.encode(extrasTable)

    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end
return Calendar
