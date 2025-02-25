----------------------------------------------------------------------------------
-- 活动面板 这个是一个通用的   ，  里面包含了各种小活动
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local Recharge_pb = require "Recharge_pb"
local thisPageName = "LimitActivityPage"
local UserInfo = require("PlayerInfo.UserInfo")
require("Activity.ActivityConfig")
require('MainScenePage')
local mScrollViewRef = { }
local mContainerRef = { }
local mSubNode = nil

local LimitActivityPage = { }
local mCurrentIndex = 0;

local WelfareContent = {
    ccbiFile = "Act_TimeLimitActIconContent_2.ccbi"
}
CloseTime = "CloseTime"
local tShowIds = { } -- 当前页面开启的活动id
local titleStr = ""
local mCurrentType = -1  -- 0 = 新手活动页面   1 = 限定活动界面
--RechargeCfg = RechargeCfg or { }


local option = {
    ccbiFile = "Act_TimeLimitMainPage.ccbi",
    handlerMap =
    {
        onReturnBtn = "onClose",
        onHelp = "onHelp",
        onArrowLeft = "onLeftActivityBtn",
        onArrowRight = "onRightActivityBtn",
        onReceive = "onReceive",
        onWishing = "onWishing",
    },
    opcodes =
    {

    },
    data = nil
}
local PageType = {
    FirstRecharge = 84,
    SaleGift = 82,
    MouthCard = 83
}

function LimitActivityPage:onEnter(container)
    -- tShowIds = {}
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    -- NodeHelper:initScrollView(container, "mContent", 5);
    container.scrollview = container:getVarScrollView("mContent");
    mSubNode = container:getVarNode("mContentNode")
    -- 绑定子页面ccb的节点
    mSubNode:removeAllChildren()
    mScrollViewRef = container.scrollview;
    mContainerRef = container;
    container.scrollview:setTouchEnabled(true)
    -- container.scrollview:setBounceable(false)


    --[[
    local len = #ActivityInfo.ids;
    for k=1,#ActivityInfo.ids do
		tShowIds[#tShowIds+1] = ActivityInfo.ids[k]
	end
    --]]

    if #tShowIds == 0 then
        local len = #ActivityInfo.LimitPageIds;
        for k = 1, #ActivityInfo.LimitPageIds do
            tShowIds[#tShowIds + 1] = ActivityInfo.LimitPageIds[k]
        end
    end

    if mCurrentType == 0 then
        container.scrollview:setTouchEnabled(false)
    end

    if #tShowIds < 4 then
        container.scrollview:setTouchEnabled(false)
    else
        container.scrollview:setTouchEnabled(true)
    end

    mCurrentIndex = 1
    if option.openActivityId then
        for i, v in ipairs(tShowIds) do
            if v == option.openActivityId then
                mCurrentIndex = i
            end
        end
        option.openActivityId = nil
    end

    self:refreshActivityNotice(container)
    self:registerPacket(container);
    self:getShopList(container);

    -- self:refreshPage(container)
    self:buildPaging(container)
    self:SelectPaging(container)

    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString(titleStr) })
    -- NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@FixedTimeActTitle")})	
    titleStr = ""

    local currPage = MainFrame:getInstance():getCurShowPageName();
    local x = 0

end


function LimitActivityPage:getShopList(container)
    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --if Golb_Platform_Info.is_win32_platform then
    --    msg.platform = GameConfig.win32Platform
    --end
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --local pb_data = msg:SerializeToString()
    --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
end

function LimitActivityPage:refreshActivityNotice(container)
    common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
end

function LimitActivityPage:SelectPaging(container)
    self:refreshPage(container)
end
function LimitActivityPage:registerPacket(container)
    container:registerPacket(HP_pb.FETCH_SHOP_LIST_S)
end
function LimitActivityPage:removePacket(container)
    container:removePacket(HP_pb.FETCH_SHOP_LIST_S)
end


---------------------------------------------------------------------------------
-- 标签页
function WelfareContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        WelfareContent.onRefreshItemView(container);
    elseif eventName == "onChanllage" then

    elseif eventName == "onMap" then

    elseif eventName == "onBtn" then
        WelfareContent.onHand(container);
    end
end
function WelfareContent:onRefreshContent(ccbRoot)

    local container = ccbRoot:getCCBFileNode()
    local levelId = self.id
    local image = ActivityConfig[tShowIds[levelId]].image
    -- NodeHelper:setMenuItemImage(container, { mBtn = {normal = image .. ".png"} })
    NodeHelper:setMenuItemImage(container, { mBtn = { normal = image .. ".png", press = image .. "_Choose.png", disabled = image .. "_Choose.png" } })
    NodeHelper:setMenuItemsEnabled(container, { mBtn = levelId ~= mCurrentIndex })


    -- mAniNode = levelId == mCurrentIndex
    if mCurrentType == 0 then
        -- 新手活动界面
        if ActivityInfo.NoticeInfo.NovicePageIds[126] then
            if CCUserDefault:sharedUserDefault():getIntegerForKey("ActTimeLimit_126" .. UserInfo.serverId .. UserInfo.playerInfo.playerId .. 1) == 1 then
                if not(CCUserDefault:sharedUserDefault():getIntegerForKey("ActTimeLimit_126canPlay" .. UserInfo.serverId .. UserInfo.playerInfo.playerId) == 1) or UserInfo.playerInfo.gold < CCUserDefault:sharedUserDefault():getIntegerForKey("ActTimeLimit_126Need" .. UserInfo.serverId .. UserInfo.playerInfo.playerId) then
                    ActivityInfo.NoticeInfo.NovicePageIds[126] = nil
                end
            end
        end
        NodeHelper:setNodesVisible(container, { mIconNew = ActivityInfo.NoticeInfo.NovicePageIds[tShowIds[levelId]] == true })
    elseif mCurrentType == 1 then
        -- 限定活动界面
        NodeHelper:setNodesVisible(container, { mIconNew = ActivityInfo.NoticeInfo.LimitPageIds[tShowIds[levelId]] == true })
    end
    local isShow = levelId ~= mCurrentIndex
    NodeHelper:setNodesVisible(container, { mAniNode1 = not isShow, mAniNode2 = not isShow })

end
function WelfareContent:onBtn(container)
    local Id = self.id
    if mCurrentIndex == Id then
        return
    end
    mCurrentIndex = Id;
    local ActionLog_pb = require("ActionLog_pb")
    local message = ActionLog_pb.HPActionRecord()
    if message ~= nil then
        message.activityId = tShowIds[mCurrentIndex];
        message.actionType = Const_pb.SEL_LIMIT_PAGINATION_INTO;
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false);
    end
    LimitActivityPage:SelectPaging(mContainerRef)

end
-- 构建标签页
function LimitActivityPage:buildPaging(container)
    NodeHelper:buildCellScrollView(container.scrollview, #tShowIds, WelfareContent.ccbiFile, WelfareContent)
    if mCurrentIndex > 4 then
        --
        container.scrollview:locateToByIndex(mCurrentIndex - 1)
    end
end
-- 标签页
---------------------------------------------------------------------------------
function LimitActivityPage:refreshPage(container)
    container.scrollview:refreshAllCell()
    local activityId = tShowIds[mCurrentIndex]
    GameConfig.NowSelctActivityId = activityId
    local activityCfg = ActivityConfig[activityId]
    if activityCfg then
        local page = activityCfg.page
        if page and page ~= "" and mSubNode then
            if LimitActivityPage.subPage then
                LimitActivityPage.subPage:onExit(container)
                LimitActivityPage.subPage = nil
            end
            mSubNode:removeAllChildren()
            LimitActivityPage.subPage = require(page)
            LimitActivityPage.sunCCB = LimitActivityPage.subPage:onEnter(container , option.data)
            mSubNode:addChild(LimitActivityPage.sunCCB)
            LimitActivityPage.sunCCB:setAnchorPoint(ccp(0, 0))
            LimitActivityPage.sunCCB:release()
            option.data = nil
        end
    end
end

function LimitActivityPage:onWishing(container)
    -- container:runAnimation("Anim1")
end
-- 接收服务器回包
function LimitActivityPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --CCLuaLog("Recharge ShopItemNum :" .. #msg.shopItems)
    end

    if LimitActivityPage.subPage then
        LimitActivityPage.subPage:onReceivePacket(container)
    end

end

function LimitActivityPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "LimitActivityPage" then
            if extraParam == "activityNoticeInfo" then
                container.scrollview:refreshAllCell()
            elseif extraParam == "changeActivity" then
                if option.openActivityId and option.openActivityId ~= tShowIds[mCurrentIndex] then
                    local oldIndex = mCurrentIndex
                    for i, v in ipairs(tShowIds) do
                        if v == option.openActivityId then
                            mCurrentIndex = i
                        end
                    end
                    option.openActivityId = nil
                    if oldIndex ~= mCurrentIndex then
                        self:SelectPaging(container)
                    end
                end
            end

        end
    end
    if LimitActivityPage.subPage and LimitActivityPage.subPage.onReceiveMessage then
        LimitActivityPage.subPage:onReceiveMessage(container)
    end
end

function LimitActivityPage:onExecute(container)
    if LimitActivityPage.subPage then
        LimitActivityPage.subPage:onExecute(container)
    end
end
function LimitActivityPage:onClose(container)
    MainFrame_onMainPageBtn()
end
function LimitActivityPage:onExit(container)
    self:removePacket(container)
    mSubNode = nil
    mScrollViewRef = nil
    mContainerRef = nil
    container.scrollview:removeAllCell()
    container.scrollview = nil
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    if LimitActivityPage.subPage then
        LimitActivityPage.subPage:onExit(container)
        LimitActivityPage.subPage = nil
    end
    onUnload(thisPageName, container)
end
function LimitActivityPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEWACTIVITY)
end
local CommonPage = require('CommonPage')
NewServerActivity = CommonPage.newSub(LimitActivityPage, thisPageName, option)



function LimitActivityPage_setCurrentPageType(currentType)
    -- 0 = 新手活动页面   1 = 限定活动界面
    mCurrentType = currentType
    if mCurrentType == 0 then
        local ActivityManager = require("Activity/ActivityManager")
        ActivityManager.setActivityType(ActivityType.Novice)
    elseif mCurrentType == 1 then
        local ActivityManager = require("Activity/ActivityManager")
        ActivityManager.setActivityType(ActivityType.Limit)
    end

end 

function LimitActivityPage_setPart(openActivityId, data)
    option.openActivityId = openActivityId
    option.data = data or  nil
end 

function LimitActivityPage_setIds(t)
    tShowIds = t
end

function LimitActivityPage_setTitleStr(s)
    titleStr = s
end
