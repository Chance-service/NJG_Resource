
----------------------------------------------------------------------------------

local thisPageName = "ActivityPage"
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local NodeHelper = require("NodeHelper")
local option = {
	ccbiFile = "ActivitiesPage.ccbi",
	handlerMap = {
		onHelp	= "onHelp",
		onReturn = "onReturn"
	},
	opcode = opcodes
}
local LIFELONG_TAG = 778
local _lifeLongContentContainer = nil
----------------- global data -----------------

----------------- local data -----------------
local ActivityPageBase = {}


local ActivityItem = {
    ccbiFile = "ActivitiesContent.ccbi",
}

function ActivityItem.onFunction(eventName, container)
    if eventName == "luaInitItemView" then
        ActivityItem.onRefreshItemView(container)
    elseif eventName == "onActivities" then
        ActivityItem.goActivityPage(container)
    end
end

function ActivityItem.onRefreshItemView(container)
    local index = container.mID
    local id = ActivityInfo.ids[index]
    local cfg = ActivityConfig[id]
    if cfg == nil then
        CCLuaLog("Error:: activity not found!!")
        return
    end
    local mActivityEntrance = container:getVarNode("mActivityEntrance")
    if cfg.image==nil and cfg.ccbi~=nil and id==45 then
        local ccbi = CCBManager:getInstance():createAndLoad2(cfg.ccbi)
        if ccbi then
        	_lifeLongContentContainer = nil
            mActivityEntrance:addChild(ccbi,1,LIFELONG_TAG)
            _lifeLongContentContainer = mActivityEntrance
        end
    else
        if id == Const_pb.SHOOT_ACTIVITY then --气枪打靶
            local image = ActivityInfo.shootActivityRewardState == 1 and "UI/Activities/u_icoqySuitShoot.png" or "UI/Activities/u_icoqySuitShootNew.png"
            NodeHelper:setNormalImages(container, {mActivities = image})
        else
            NodeHelper:setNormalImages(container, {mActivities = cfg.image})
        end
    end
    -- if not Golb_Platform_Info.is_entermate_platform then
        -- NodeHelper:setStringForLabel(container,{
        -- mActivitesTitle = Language:getInstance():getString(cfg.dict)})	
    -- else
        -- NodeHelper:setStringForLabel(container,{
        -- mActivitesTitle		= ""})	
    -- end
    local showRedPoint = false
    if id ~= ActivityInfo.closeId then
        --local isNew = ActivityInfo.activities[id]["isNew"]
        local noticeCount = ActivityInfo.rewardCount[id] or 0
            showRedPoint = noticeCount > 0
    end
    NodeHelper:setNodesVisible(container, {mActivitiesPoint = showRedPoint})
    if container:getVarSprite("mActivitiesPoint") then 
        container:getVarSprite("mActivitiesPoint"):setZOrder(10)
    end 
end

function ActivityItem.goActivityPage(container)
    local index = container.mID
    local id = ActivityInfo.ids[index]
	
    ActivityPage_goActivity(id)
end
-----------------------------------------------
--ActivityPageBase页面中的事件处理
----------------------------------------------
function ActivityPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    if mScale9Sprite ~= nil then
        container:autoAdjustResizeScale9Sprite( mScale9Sprite )
    end
    NodeHelper:initRawScrollView(container, "mContent")
    if container.mScrollView ~= nil then
        container:autoAdjustResizeScrollview(container.mScrollView)
    end
    self:refreshPage(container)
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_ACTIVE)
end

function ActivityPageBase:onExit(container)
    if _lifeLongContentContainer then
        _lifeLongContentContainer:removeChildByTag(LIFELONG_TAG, true)
    end
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:deleteScrollView(container)
end

function ActivityPageBase:onReturn(container)
    PageManager.changePage("MainScenePage")
end
----------------------------------------------------------------

function ActivityPageBase:refreshPage(container)
    self:rebuildAllItem(container)
end
----------------scrollview-------------------------
function ActivityPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ActivityPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end
function ActivityPageBase:buildScrollView( container, size, ccbiFile, funcCallback )
    if size == 0 or ccbiFile == nil or ccbiFile == "" or funcCallback == nil then
        return
    end

    local width = container.mScrollView:getContentSize().width
    local height = 0
	
    for i = size, 1, -1 do
        --local pItem = ScriptContentBase:create(ccbiFile, i);
        local pItem = CCBManager:getInstance():createAndLoad2(ccbiFile)
        pItem.mID = i
        pItem:registerFunctionHandler(funcCallback)
        pItem.__CCReViSvItemNodeFacade__:initItemView()
        container.mScrollView:addChild(pItem)
        --pItem:release()
        pItem:setAnchorPoint(ccp(0, 0))
        pItem:setPosition(ccp(0, height))
        height = height + pItem:getContentSize().height
    end

    local size = CCSizeMake(width, height)
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	container.mScrollView:forceRecaculateChildren()
end
function ActivityPageBase:buildItem(container)
	self:buildScrollView(container, #ActivityInfo.ids, ActivityItem.ccbiFile, ActivityItem.onFunction)
end
	
----------------click event------------------------	
function ActivityPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACTIVE)
end	

function ActivityPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        if pageName == thisPageName then
            self:refreshPage(container)
        end
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
ActivityPage = CommonPage.newSub(ActivityPageBase, thisPageName, option)

--活动跳转, openWay:打开方式，'change' or 'push'  or 'onClick'
function ActivityPage_goActivity(id)
    local ActivityFunction  = require("Activity.ActivityFunction")
    local cfg = ActivityConfig[id]
    if cfg.openWay == "none" then return end
	
    if not ActivityInfo.activities[id] then
        MessageBoxPage:Msg_Box_Lan("@ActivityNotOpen")
        return
    end
    if cfg.activityType == 2 then
        PageManager.setJumpTo("NewActivityPage", id)
        PageManager.pushPage("NewActivityPage")
    else	
        GlobalData.nowActivityId = id
        if cfg.openWay == "push" then
            PageManager.pushPage(cfg.page)
        elseif cfg.openWay == "click" then
            if ActivityFunction[id] ~= nil then
                ActivityFunction[id]()
            end
        else
            PageManager.changePage(cfg.page)
        end
    end
    --检测红点是否取消
    ActivityInfo:saveVersion(id)
    ActivityInfo:checkReward()
end