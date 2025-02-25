----------------------------------------------------------------------------------
-- 扭蛋面板   ， 不和活动公用
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local Recharge_pb = require "Recharge_pb"
local thisPageName = "GashaponPage"
local UserInfo = require("PlayerInfo.UserInfo")
require("Activity.ActivityConfig")
require('MainScenePage')
local mScrollViewRef = { }
local mContainerRef = { }
local mSubNode = nil

local GashaponPage = { }
local mCurrentIndex = 0;

local WelfareContent = {
    ccbiFile = "Act_TimeLimitActIconContent_2.ccbi"
}
CloseTime = "CloseTime"
local tShowIds = { } -- 当前页面开启的活动id
local titleStr = ""
--RechargeCfg = RechargeCfg or { }
local openActivityNum = 0   --打开活动的个数
local openActivityNumCache = 6 --打开活动的次数限制开始清缓存

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

    }
}


function GashaponPage:onEnter(container)

    -- tShowIds = {}
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    -- NodeHelper:initScrollView(container, "mContent", 5);
    container.scrollview = container:getVarScrollView("mContent");
    mSubNode = container:getVarNode("mContentNode")
    -- 绑定子页面ccb的节点
    mSubNode:removeAllChildren()
    mScrollViewRef = container.scrollview;
    mContainerRef = container;


    if #tShowIds == 0 then
        local len = #ActivityInfo.NiuDanPageIds;
        for k = 1, #ActivityInfo.NiuDanPageIds do
            tShowIds[#tShowIds + 1] = ActivityInfo.NiuDanPageIds[k]
        end
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


    local ActivityManager = require("Activity/ActivityManager")
    ActivityManager.setActivityType(ActivityType.Gashapon)

    self:refreshActivityNotice(container)
    self:registerPacket(container);
    -- self:getShopList(container);

    -- self:refreshPage(container)
    self:buildPaging(container)
    self:SelectPaging(container)

    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString(titleStr) })

    titleStr = ""

    --[[    local  tmpCount = CCUserDefault:sharedUserDefault():getIntegerForKey("GashaponPage"..UserInfo.playerInfo.playerId);
    if tmpCount == 0 then
        CCUserDefault:sharedUserDefault():setIntegerForKey("GashaponPage"..UserInfo.playerInfo.playerId,1);
    end]]

    NodeHelper:autoAdjustResetNodePosition(container:getVarNode("mGachaBg"), -0.5)
    container:getVarNode("mGachaBg"):setVisible(false)
end


function GashaponPage:getShopList(container)
    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --if Golb_Platform_Info.is_win32_platform then
    --    msg.platform = GameConfig.win32Platform
    --end
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --local pb_data = msg:SerializeToString()
    --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
end

function GashaponPage:refreshActivityNotice(container)
    common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
end

function GashaponPage:SelectPaging(container)
    self:refreshPage(container)
end
function GashaponPage:registerPacket(container)
    container:registerPacket(HP_pb.FETCH_SHOP_LIST_S)
end
function GashaponPage:removePacket(container)
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
    NodeHelper:setNodesVisible(container, { mIconNew = ActivityInfo.NoticeInfo.NiuDanPageIds[tShowIds[levelId]] == true and tShowIds[levelId] ~= 109 })
    local isShow = levelId ~= mCurrentIndex
    NodeHelper:setNodesVisible(container, { mAniNode1 = not isShow, mAniNode2 = not isShow })
end
function WelfareContent:onBtn(container)
    local Id = self.id
    if mCurrentIndex == Id then
        return
    end
    NodeHelper:playMusic("click_1.mp3")
    mCurrentIndex = Id;
    local ActionLog_pb = require("ActionLog_pb")
    local message = ActionLog_pb.HPActionRecord()
    if message ~= nil then
        message.activityId = tShowIds[mCurrentIndex];
        message.actionType = Const_pb.SEL_LIMIT_PAGINATION_INTO;
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false);
    end
    GashaponPage:SelectPaging(mContainerRef)

end
-- 构建标签页
function GashaponPage:buildPaging(container)
    NodeHelper:buildCellScrollView(container.scrollview, #tShowIds, WelfareContent.ccbiFile, WelfareContent)
    if mCurrentIndex > 4 then
        --
        container.scrollview:locateToByIndex(mCurrentIndex - 1)
    end
end
-- 标签页
---------------------------------------------------------------------------------
function GashaponPage:refreshPage(container)

    container.scrollview:refreshAllCell()
    local activityId = tShowIds[mCurrentIndex]
    GameConfig.NowSelctActivityId = activityId
    local activityCfg = ActivityConfig[activityId]
    if activityCfg then
        local page = activityCfg.page
        if page and page ~= "" and mSubNode then
            if GashaponPage.subPage then
                GashaponPage.subPage:onExit(container)
                GashaponPage.subPage = nil
            end
            mSubNode:removeAllChildren()

            --if  not GameConfig.isReBackVer28 then 
            openActivityNum = openActivityNum + 1
            if openActivityNum >= openActivityNumCache then 
                openActivityNum = 0 
                GameUtil:purgeCachedData()
            end
            --end 
            GashaponPage.subPage = require(page)
            GashaponPage.sunCCB = GashaponPage.subPage:onEnter(container)
            mSubNode:addChild(GashaponPage.sunCCB)
            GashaponPage.sunCCB:setAnchorPoint(ccp(0, 0))
            GashaponPage.sunCCB:release()
        end
    end
end

function GashaponPage:onWishing(container)
    container:runAnimation("Anim1")
end
-- 接收服务器回包
function GashaponPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --CCLuaLog("Recharge ShopItemNum :" .. #msg.shopItems)
    end

    if GashaponPage.subPage then
        GashaponPage.subPage:onReceivePacket(container)
    end

end

function GashaponPage:isCancleThisPageRedPoint()
    ActivityInfo.NiuDanPageIds = ActivityInfo.NiuDanPageIds or {}
    ActivityInfo.NoticeInfo.NiuDanPageIds = ActivityInfo.NoticeInfo.NiuDanPageIds or {}
    local needShow = false
    for i = 1, #ActivityInfo.NiuDanPageIds do
        if ActivityInfo.NoticeInfo.NiuDanPageIds[ActivityInfo.NiuDanPageIds[i]] == true and ActivityInfo.NiuDanPageIds[i] ~= 109 then
           needShow = true
           return
        end
    end
    if not needShow then
        NodeHelper:mainFrameSetPointVisible( { mNiuDanPagePoint = needShow })
    end
end

function GashaponPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "GashaponPage" then
            if extraParam == "activityNoticeInfo" then
                container.scrollview:refreshAllCell()
                GashaponPage:isCancleThisPageRedPoint()
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
    if GashaponPage.subPage and GashaponPage.subPage.onReceiveMessage then
        GashaponPage.subPage:onReceiveMessage(container)
    end
end

function GashaponPage:onExecute(container)
    if GashaponPage.subPage then
        GashaponPage.subPage:onExecute(container)
    end
end
function GashaponPage:onClose(container)
    MainFrame_onMainPageBtn()
end
function GashaponPage:onExit(container)
    self:removePacket(container)
    mSubNode = nil
    container.scrollview:removeAllCell()
    mScrollViewRef = nil
    mContainerRef = nil

    container:removeMessage(MSG_MAINFRAME_REFRESH)
    if GashaponPage.subPage then
        GashaponPage.subPage:onExit(container)
        GashaponPage.subPage = nil
    end
    onUnload(thisPageName, container)
    openActivityNum = 0 
    GameUtil:purgeCachedData()

end
function GashaponPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEWACTIVITY)
end
local CommonPage = require('CommonPage')
NewServerActivity = CommonPage.newSub(GashaponPage, thisPageName, option)


function GashaponPage_setPart(openActivityId)
    option.openActivityId = openActivityId
end 

function GashaponPage_setIds(t)
    tShowIds = t
end

function GashaponPage_setTitleStr(s)
    titleStr = s
end

function GashaponPage_setBgVisible(isVisible)
    if mContainerRef ~= nil then
        mContainerRef:getVarNode("mGachaBg"):setVisible(isVisible)
    end
end