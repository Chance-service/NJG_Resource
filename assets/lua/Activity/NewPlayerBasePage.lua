----------------------------------------------------------------------------------
--[[
	新手活動
--]]
----------------------------------------------------------------------------------
local UserInfo = require("PlayerInfo.UserInfo")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local Player_pb = require("Player_pb")
local Const_pb = require("Const_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local GuideManager = require("Guide.GuideManager")
local NewPlayerBasePage = { } --

local option = {
    ccbiFile = "NewPlayer_BasePage.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
        onAddCoin = "onAddCoin",
        onAddDiamond = "onAddDiamond",
    },
    opcodes =
    {
    }
}
local timerNameTable = {
    [ACTIVITY_TYPE.NEWPLAYER_LEVEL9] = "Activity_NewPlayer9",
}
local thisPageName = "NewPlayerBasePage"
local thisPageContainer = nil
local mSubNode = nil
local activityTime = 0
local mIsUpdateTime = false
--------------------------------------------------------------------
local pageType = 0
local pageId = 0
local itemId = 1
--------------------------------------------------------------------------------------
local NewPlayerBaseBtn = { ccbiFile = "NewPlayer_BasePageContent.ccbi" }
function NewPlayerBaseBtn:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function NewPlayerBaseBtn:setIsRedPoint(isRedPoint)
    self.isRedPoint = isRedPoint
end

function NewPlayerBaseBtn:setActivityId(activityId)
    self.activityId = activityId
end

function NewPlayerBaseBtn:onBtn(container)
    if pageId == self.activityId then
        return
    end
    itemId = self.id
    pageId = self.activityId
    NewPlayerBasePage:refreshPage(thisPageContainer)
end

function NewPlayerBaseBtn:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    NodeHelper:setNodesVisible(container, { mFairContentNode = (self.activityId > 0) })
    if self.activityId > 0 then
        local normalImg = ActivityConfig[self.activityId].image and ActivityConfig[self.activityId].image .. ".png" or ""
        local pressImg = ActivityConfig[self.activityId].image and ActivityConfig[self.activityId].image .. "_On.png" or ""
        NodeHelper:setMenuItemImage(container, { mBtn = { normal = normalImg, press = pressImg, disabled = pressImg } })
        NodeHelper:setMenuEnabled(container:getVarMenuItemImage("mBtn"), self.activityId ~= pageId )
        NodeHelper:setNodesVisible(container, { mRedPoint = ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[self.activityId] and true or false })
        NodeHelper:setNodesVisible(container, { mSelectEffect = (self.activityId == pageId) })
    end
end
--------------------------------------------------------------------------------------
function NewPlayerBasePage:onEnter(container)
    thisPageContainer = container
    ----------------------

    container:registerMessage(MSG_SEVERINFO_UPDATE)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerMessage(MSG_MAINFRAME_POPPAGE)

    container.mScrollView = container:getVarScrollView("mScrollView")
    mSubNode = container:getVarNode("mContentNode")
    if mSubNode then
        mSubNode:removeAllChildren()
    end
    pageId = ActivityInfo.NewPlayerLevel9Ids and ActivityInfo.NewPlayerLevel9Ids[1] or 0
    self:refreshUserInfo(container)
    self:registerPacket(container)
    self:buildScrollView(container)
    self:refreshPage(container)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["NewPlayerBasePage"] = container
end

-- 分頁按鈕初始化
function NewPlayerBasePage:buildScrollView(container)
    local totalCount = 0
    local activityInfo = ActivityInfo.NewPlayerLevel9Ids
    totalCount = math.max(#activityInfo, 5)

    container.mScrollView:setTouchEnabled(totalCount > 5)

    local cell = nil
    local items = { }
    for i = totalCount, 1, -1 do
        cell = CCBFileCell:create()
        cell:setCCBFile(NewPlayerBaseBtn.ccbiFile)
        local handler = common:new( { id = i, activityId = activityInfo[i] or 0 }, NewPlayerBaseBtn)
        cell:registerFunctionHandler(handler)
        container.mScrollView:addCell(cell)
        items[i] = { cls = handler, node = cell }
    end
    container.mScrollView:orderCCBFileCells()
    self.mAllRoleItem = items

    if not self.mAllRoleItem then
        self.mAllRoleItem = { }
    end
end
---------------------------------------------------------------------------------
function NewPlayerBasePage:refreshPage(container)
    for i = 1, #self.mAllRoleItem do
        self.mAllRoleItem[i].cls:onRefreshContent(self.mAllRoleItem[i].node)
    end
    if ActivityConfig[pageId] and ActivityConfig[pageId].page then
        NewPlayerBasePage.subPage = require(ActivityConfig[pageId].page)
        NewPlayerBasePage.sunCCB = NewPlayerBasePage.subPage:onEnter(container)
        mSubNode:removeAllChildrenWithCleanup(true)
        mSubNode:addChild(NewPlayerBasePage.sunCCB)
        return true
    end
    return false
end

function NewPlayerBasePage:onRefreshPageRedPoint()
    if not _mercenaryContainerInfo then return end
    for i = 1, #_mercenaryContainerInfo do
        local tempcontainer = _mercenaryContainerInfo[i]
        if not tempcontainer then return end
        local dataInfo = _mercenaryInfos.roleInfos[i]
        if not dataInfo then return end
        if dataInfo.roleStage == 1 then
            local redPoint = UserEquipManager:getEquipMercenaryCount(dataInfo.roleId)
            if redPoint ~= nil and redPoint > 0 then
                NodeHelper:setNodesVisible(tempcontainer, { mMercenaryCallNode = true })
            else
                NodeHelper:setNodesVisible(tempcontainer, { mMercenaryCallNode = false })
            end
        end
    end
end

function NewPlayerBasePage:onReceiveMessage(container)
    if NewPlayerBasePage.subPage and NewPlayerBasePage.subPage["onReceiveMessage"] then
        NewPlayerBasePage.subPage:onReceiveMessage(container)
    end
    local message = container:getMessage()
    local typeId = message:getTypeId()
    local opcode = container:getRecPacketOpcode()
    if typeId == MSG_MAINFRAME_REFRESH then

    end
end

-- 接收服务器回包
function NewPlayerBasePage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if NewPlayerBasePage.subPage then
        NewPlayerBasePage.subPage:onReceivePacket(container)
        self:refreshUserInfo(container)
    end
end

function NewPlayerBasePage:onExecute(container)
    if NewPlayerBasePage.subPage and NewPlayerBasePage.subPage["onExecute"] then
        NewPlayerBasePage.subPage:onExecute(container)
    end
end

function NewPlayerBasePage:updateTime(container)
    if activityTime > 0 then
        if not TimeCalculator:getInstance():hasKey(timerNameTable[pageType]) then
            TimeCalculator:getInstance():createTimeCalcultor(timerNameTable[pageType], activityTime)
        end
        mIsUpdateTime = true
    else
        mIsUpdateTime = false
    end
end

-- 刷新玩家金幣&鑽石數量
function NewPlayerBasePage:refreshUserInfo(container)
    local coinStr = GameUtil:formatNumber(UserInfo.playerInfo.coin)
    local diamondStr = GameUtil:formatNumber(UserInfo.playerInfo.gold)
    NodeHelper:setStringForLabel(container, { mCoin = coinStr, mDiamond = diamondStr })
end
--
function NewPlayerBasePage:onReturn(container)
    if mSubNode:getChildrenCount() ~= 0 then
        if NewPlayerBasePage.subPage then
            NewPlayerBasePage.subPage:onExit(container)
            NewPlayerBasePage.subPage = nil
            NewPlayerBasePage.sunCCB = nil
        end
        mSubNode:removeAllChildren()
        pageId = 0
        itemId = 1
    end
    PageManager.popPage(thisPageName)
end
function NewPlayerBasePage:onExit(container)
    TimeCalculator:getInstance():removeTimeCalcultor(timerNameTable[pageType])
    pageType = 0
    container:removeMessage(MSG_SEVERINFO_UPDATE)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removeMessage(MSG_MAINFRAME_POPPAGE)
    if NewPlayerBasePage.subPage then
        NewPlayerBasePage.subPage:onExit(container)
        NewPlayerBasePage.subPage = nil
    end
    if container.mScrollView then
        container.mScrollView:removeAllCell()
    end
    mIsUpdateTime = false
    self:removePacket(container)
end
--
function NewPlayerBasePage:onAddCoin(container)
    --PageManager.pushPage("MoneyCollectionPage")
end
--
function NewPlayerBasePage:onAddDiamond(container)
    local MainScenePageInfo = require("MainScenePage")
    MainScenePageInfo.onFunction("onRecharge", container)
end

function NewPlayerBasePage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function NewPlayerBasePage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function NewPlayerBasePage:setActivityTime(time)
    activityTime = time
    self:updateTime(container)
end

function NewPlayerBasePage:getActivityTime()
    if not TimeCalculator:getInstance():hasKey(timerNameTable[pageType]) then
        return 0
    else
        return TimeCalculator:getInstance():getTimeLeft(timerNameTable[pageType])
    end
end

function NewPlayerBasePage_setPageType(_pageType)
    pageType = _pageType
end

local CommonPage = require("CommonPage")
NewPlayerBasePage = CommonPage.newSub(NewPlayerBasePage, thisPageName, option)
return NewPlayerBasePage