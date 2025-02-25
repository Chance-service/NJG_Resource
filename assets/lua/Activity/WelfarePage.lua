----------------------------------------------------------------------------------
--[[
	特典
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Recharge_pb = require "Recharge_pb"
local thisPageName = "WelfarePage"
local UserInfo = require("PlayerInfo.UserInfo")
local BuyManager = require("BuyManager")
require("Activity.ActivityConfig")
require("MainScenePage")
local mScrollViewRef = { }
local mContainerRef = { }

local WelfarePage = { }
local mChildNodeCount = 6
local mCurrentIndex = 0
local fOneItemWidth = 0
local fScrollViewWidth = 0

local WelfareContent = {
    ccbiFile = "Act_TimeLimitActIconContent_1.ccbi"
}
local mWelfareContainerRef = { } -- 存储上方页签 Container
local mSalePacketContainerRef = { } -- 存储折扣礼包 Container
CloseTime = "CloseTime"
local tShowIds = { } -- 当前页面开启的活动id

local mSubNode = nil
--RechargeCfg = { }
local option = {
    ccbiFile = "Act_FixedTimeMainPage.ccbi",
    handlerMap = {
        onClose = "onClose",
        onHelp = "onHelp",
        onArrowLeft = "onLeftActivityBtn",
        onArrowRight = "onRightActivityBtn",
    },
    opcodes = {
        FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
        SHOP_HONEYP_S = HP_pb.SHOP_HONEYP_S,
        SHOP_HONEYP_C = HP_pb.SHOP_HONEYP_C, -- getHoneyP
        SHOP_HONEYP_BUY_S = HP_pb.SHOP_HONEYP_BUY_S,
        ACCOUNT_BOUND_REWARD_S = HP_pb.ACCOUNT_BOUND_REWARD_S
    }
}
local PageType = {
    FirstRecharge = 84,
    SaleGift = 82,
    MouthCard = 83,
    DailtQuest = 87
}
-- 角色类型
local RoleType = {
    FIGHTER = 1,
    HUNTER = 2,
    MAGICER = 3
}
function WelfarePage:onEnter(container)
    tShowIds = { }
    mWelfareContainerRef = { }
    mSalePacketContainerRef = { }
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mScrollView", 5)
    self:initSecondScrollView(container)
    container.scrollview = container:getVarScrollView("mScrollView")
    container.scrollview2 = container:getVarScrollView("mContent")
    mScrollViewRef = container.scrollview
    mContainerRef = container
    mSubNode = container:getVarNode("mSubNode")
    -- 绑定子页面ccb的节点
    mSubNode:removeAllChildren()
    container.scrollview:setTouchEnabled(true)
    container.scrollview:setBounceable(false)
    fScrollViewWidth = container.scrollview:getViewSize().height
    local len = #ActivityInfo.OtherPageids
    for k = 1, #ActivityInfo.OtherPageids do
        tShowIds[#tShowIds + 1] = ActivityInfo.OtherPageids[k]
    end

    local t = { }

    for i = #tShowIds, 0, -1 do
        table.insert(t, tShowIds[i])
    end

    tShowIds = t

    mCurrentIndex = #tShowIds

    if option.openActivityId then
        for i, v in ipairs(tShowIds) do
            if v == option.openActivityId then
                mCurrentIndex = i
            end
        end
        option.openActivityId = nil
    end
    -- tShowIds = {82,83,84};
    -- init package
    UserInfo.sync()
    local userItemId = UserInfo.roleInfo.itemId
    if userItemId > 3 then
        userItemId = userItemId - 3
    end

    local ActivityManager = require("Activity/ActivityManager")
    ActivityManager.setActivityType(ActivityType.Privilege)

    self:registerPacket(container)
    self:refreshActivityNotice(container)
    --    if #RechargeCfg == 0 then

    --    end
    self:getShopList(container)
    self:buildPaging(container)
    self:SelectPaging(container)
    local PageJumpMange = require("PageJumpMange")
    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            WelfarePage[PageJumpMange._CurJumpCfgInfo._SecondFunc](self, container, PageJumpMange._CurJumpCfgInfo._SecondFunc_Param);
        end
        if PageJumpMange._CurJumpCfgInfo._ThirdFunc == "" then
            PageJumpMange._IsPageJump = false
        end
    end
    local a = mCurrentIndex

    if (Golb_Platform_Info.is_r18) then --R18
        BuyManager:SendtogetHoneyP() -- getHoneyp
    end
end
function WelfarePage:changeToActivityPageById(container, activityId)
    local childContainer = mWelfareContainerRef[activityId]
    if childContainer then
        WelfareContent.onHand(childContainer)
    end
end
function WelfarePage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function WelfarePage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function WelfarePage:refreshActivityNotice(container)
    common:sendEmptyPacket(HP_pb.RED_POINT_LIST_C, false)
end

function WelfarePage:getShopList(container)
    --local msg = Recharge_pb.HPFetchShopList()
    --msg.platform = libPlatformManager:getPlatform():getClientChannel()
    --if Golb_Platform_Info.is_win32_platform then
    --    msg.platform = GameConfig.win32Platform
    --end
    --CCLuaLog("PlatformName2:" .. msg.platform)
    --pb_data = msg:SerializeToString()
    --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
end

function WelfarePage:initSecondScrollView(container)
    container.mScrollView2 = container:getVarScrollView("mContent")
    -- 初始化一次后不再进行初始化
    if container.mScrollView2 == nil or container.mScrollViewRootNode2 then return end
    container.mScrollViewRootNode2 = container.mScrollView2:getContainer()
    container.m_pScrollViewFacade2 = CCReViScrollViewFacade:new_local(container.mScrollView2)
    container.m_pScrollViewFacade2:init(5, 3)
end

-- 接收服务器回包
function WelfarePage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --CCLuaLog("Recharge ShopItemNum :" .. #msg.shopItems)
        --return
    else
        BuyManager:onReceiveBuyPacket(opcode, msgBuff)
    end

    if WelfarePage.subPage then
        WelfarePage.subPage:onReceivePacket(container)
    end
end
function WelfarePage:onExecute(container)
    if WelfarePage.subPage then
        WelfarePage.subPage:onExecute(container)
    end
end

function WelfarePage:SelectPaging(container)
    container.m_pScrollViewFacade:refreshDynamicScrollView()
    local pageType = tShowIds[mCurrentIndex]
    local activityCfg = ActivityConfig[pageType]
    if activityCfg then
        GameConfig.NowSelctActivityId = pageType
        local page = activityCfg.page
        if page and page ~= "" and mSubNode then
            if WelfarePage.subPage then
                WelfarePage.subPage:onExit(container)
                WelfarePage.subPage = nil
            end
            mSubNode:removeAllChildren()
            WelfarePage.subPage = require(page)
            WelfarePage.sunCCB = WelfarePage.subPage:onEnter(container)
            mSubNode:addChild(WelfarePage.sunCCB)
            WelfarePage.sunCCB:setAnchorPoint(ccp(0, 0))
            WelfarePage.sunCCB:release()

            local ActionLog_pb = require("ActionLog_pb")
            local message = ActionLog_pb.HPActionRecord()
            if message ~= nil then
                message.activityId = pageType
                message.actionType = Const_pb.SEL_PAGINATION_INTO
                local pb_data = message:SerializeToString()
                PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false)
            end
        end
        -- 记录最有一次进入这些界面的时间
        if pageType == 84 or pageType == 24 or pageType == 83 then
            local tabTime = os.date("*t")
            tabTime.hour = 0
            tabTime.min = 0
            tabTime.sec = 0
            local time = os.time(tabTime)
            if pageType == 84 then
                CCUserDefault:sharedUserDefault():setStringForKey("LastClickTime_" .. UserInfo.playerInfo.playerId, time)
            elseif pageType == 24 then
                CCUserDefault:sharedUserDefault():setStringForKey("LastClickWeekCardTime_" .. UserInfo.playerInfo.playerId, time)
            else
                CCUserDefault:sharedUserDefault():setStringForKey("LastClickMonthCardTime_" .. UserInfo.playerInfo.playerId, time)
            end
        end
    end
end

-- 构建分页
function WelfarePage:buildPaging(container)
    local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
    local iCount = 0
    local fOneItemHeight = 0
    local currentPos = 0
    local interval = 10
    for i = 1, #tShowIds do
        local pItemData = CCReViSvItemData:new_local()
        pItemData.mID = i
        pItemData.m_iIdx = i
        pItemData.m_ptPosition = ccp(0, (fOneItemWidth + interval) * iCount)

        if iCount < iMaxNode then
            ccbiFile = WelfareContent.ccbiFile
            local pItem = ScriptContentBase:create(ccbiFile)
            pItem:release()
            pItem.id = iCount
            pItem:registerFunctionHandler(WelfareContent.onFunction)
            fOneItemHeight = pItem:getContentSize().width

            if fOneItemWidth < pItem:getContentSize().height then
                fOneItemWidth = pItem:getContentSize().height
            end
            currentPos = currentPos + fOneItemWidth
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        else
            container.m_pScrollViewFacade:addItem(pItemData)
        end
        iCount = iCount + 1
    end
    local size = CCSizeMake(fOneItemHeight, fOneItemWidth * iCount + interval * (iCount - 1))
    container.mScrollView:setContentSize(size)
    container.mScrollView:setContentOffset(ccp(0, 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1)
    container.mScrollView:forceRecaculateChildren()
    ScriptMathToLua:setSwallowsTouches(container.mScrollView)

    local h = mScrollViewRef:getContentSize().height
    local vh = mScrollViewRef:getViewSize().height

    mScrollViewRef:setContentOffset(ccp(0, vh - h))

    mScrollViewRef:setContentOffsetInDuration(ccp(0, vh - h), 0)
    local c = 0
    mScrollViewRef:getContainer():stopAllActions()
    mScrollViewRef:setContentOffsetInDuration(ccp(0, 0), 0)
end
function WelfarePage:buildAllItem(container)

end
function WelfarePage:calOffsetByIndex(index)
    local offset = fScrollViewWidth - (index) * fOneItemWidth
    return offset
end

function WelfarePage:fillRewardItem(container, rewardCfg, maxSize, isShowNum)
    local maxSize = maxSize or 4
    isShowNum = isShowNum or false
    local nodesVisible = { }
    local lb2Str = { }
    local sprite2Img = { }
    local menu2Quality = { }

    for i = 1, maxSize do
        local cfg = rewardCfg[i]
        nodesVisible["mRewardNode" .. i] = cfg ~= nil

        if cfg ~= nil then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
            if resInfo ~= nil then
                sprite2Img["mPic" .. i] = resInfo.icon
                sprite2Img["mFrameShade"] = NodeHelper:getImageBgByQuality(resInfo.quality)
                lb2Str["mNum" .. i] = "x" .. cfg.count
                lb2Str["mName" .. i] = resInfo.name
                menu2Quality["mFrame" .. i] = resInfo.quality

                if isShowNum then
                    resInfo.count = resInfo.count or 0
                    lb2Str["mNum" .. i] = resInfo.count .. "/" .. cfg.count
                end
                if cfg.type == 40000 then
                    -- 装备根据配置增加金装特效
                    local aniNode = container:getVarNode("mAni" .. i)
                    if aniNode then
                        aniNode:removeAllChildren()
                        local ccbiFile = GameConfig.GodlyEquipAni[cfg.isgold]
                        aniNode:setVisible(false)
                        if ccbiFile ~= nil then
                            local ani = ScriptContentBase:create(ccbiFile)
                            ani:release()
                            ani:unregisterFunctionHandler()
                            aniNode:addChild(ani)
                            aniNode:setVisible(true)
                        end
                    end
                    -- 装备根据配置增加金装特效
                end
                -- html
                local htmlNode = container:getVarLabelBMFont("mName" .. i)
                if not htmlNode then
                    htmlNode = container:getVarLabelTTF("mName" .. i)
                end
                if htmlNode then
                    local htmlLabel
                    -- 泰语太长 修改htmlLabel的大小
                    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
                        htmlNode:setVisible(false)
                        htmlLabel = NodeHelper:setCCHTMLLabelAutoFixPosition(htmlNode, CCSize(110, 32), resInfo.name)
                        htmlLabel:setScaleX(htmlNode:getScaleX())
                        htmlLabel:setScaleY(htmlNode:getScaleY())
                    end
                end
            else
                CCLuaLog("Error::***reward item not found!!")
            end
        end
    end

    NodeHelper:setNodesVisible(container, true)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)
end
function WelfareContent.onRefreshItemView(container)
    local levelId = tonumber(container:getItemDate().mID)
    if mWelfareContainerRef[tShowIds[levelId]] == nil then
        mWelfareContainerRef[tShowIds[levelId]] = container
    end

    local image = ActivityConfig[tShowIds[levelId]].image
    NodeHelper:setMenuItemImage(container, { mBtn = { normal = image .. ".png", press = image .. "_Choose.png", disabled = image .. "_Choose.png" } })

    NodeHelper:setMenuItemsEnabled(container, { mBtn = levelId ~= mCurrentIndex })

    NodeHelper:setNodesVisible(container, { mBackNode = (levelId == mCurrentIndex), mFrontNode = levelId == mCurrentIndex })

    NodeHelper:setMenuItemsEnabled(container, { mState = levelId ~= mCurrentIndex })

    NodeHelper:setNodesVisible(container, { mIconNew = ActivityInfo.NoticeInfo.commonAct[tShowIds[levelId]] })

    NodeHelper:setNodesVisible(container, { mState_1 = levelId ~= mCurrentIndex, mState_2 = levelId == mCurrentIndex, mEffectNode = levelId == mCurrentIndex })
end

function WelfareContent.onHand(container)
    local Id = tonumber(container:getItemDate().mID)
    if mCurrentIndex == Id then
        return
    end
    mCurrentIndex = Id
    WelfarePage:SelectPaging(mContainerRef)
end
function WelfareContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        WelfareContent.onRefreshItemView(container)
    elseif eventName == "onChanllage" then

    elseif eventName == "onMap" then

    elseif eventName == "onBtn" then
        WelfareContent.onHand(container)
    end
end
function WelfarePage:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function WelfarePage:onClose(container)
    PageManager.popPage(thisPageName)
end

function WelfarePage:onHelp(container)
    local xx = 10
end
function WelfarePage:onLeftActivityBtn(container)
    local xx = 10
end
function WelfarePage:onRightActivityBtn(container)
    local xx = 10
end
local function m_BtnDelay(menuItem)
    local array = CCArray:create()
    local btnUnableAction = CCCallFunc:create( function()
        NodeHelper:setMenuEnabled(menuItem, false)
    end )
    local btnAbleAction = CCCallFunc:create( function()
        NodeHelper:setMenuEnabled(menuItem, true)
    end )
    array:addObject(btnUnableAction)
    array:addObject(CCDelayTime:create(0.3))
    array:addObject(btnAbleAction)
    local seq = CCSequence:create(array)
    menuItem:runAction(seq)
end
local function m_AllBtnDelay()
    m_BtnDelay(mContainerRef:getVarMenuItemImage("mLeftArrow"))
    m_BtnDelay(mContainerRef:getVarMenuItemImage("mRightArrow"))
end
function WelfarePage:onArrowLeft(container)
    m_AllBtnDelay()
    newIndex = mCurrentIndex - 1
    newIndex = math.max(newIndex, 1)
    newIndex = math.min(newIndex, mChildNodeCount)
    WelfarePage:MoveToIndex(newIndex)
end

function WelfarePage:onArrowRight(container)
    m_AllBtnDelay()
    newIndex = mCurrentIndex + 1
    newIndex = math.max(newIndex, 1)
    newIndex = math.min(newIndex, mChildNodeCount)
    WelfarePage:MoveToIndex(newIndex)
end
function WelfarePage:MoveToIndex(index)
    mCurrentIndex = index
    local index = EliteMapInfoPageBase:calNewIndexBycurOffset(curOffset)
    local newOffset = WelfarePage:calOffsetByIndex(index)
    CCLuaLog("newOffset" .. newOffset .. "index = " .. index)
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(0.1))
    local functionAction = CCCallFunc:create( function()
        mScrollViewRef:getContainer():stopAllActions()
        mScrollViewRef:setContentOffsetInDuration(ccp(mScrollViewRef:getContentOffset().x, newOffset), 0.2)
    end )
    array:addObject(functionAction)
    local seq = CCSequence:create(array)
    mScrollViewRef:runAction(seq)
end
function WelfarePage:onExit(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container)

    if container.m_pScrollViewFacade2 then
        container.m_pScrollViewFacade2:clearAllItems()
        container.m_pScrollViewFacade2:delete()
        container.m_pScrollViewFacade2 = nil
    end
    if container.mScrollViewRootNode2 then
        container.mScrollViewRootNode2:removeAllChildren()
        container.mScrollViewRootNode2 = nil
    end
    TimeCalculator:getInstance():removeTimeCalcultor(CloseTime)
    if WelfarePage.subPage then
        WelfarePage.subPage:onExit(container)
        WelfarePage.subPage = nil
    end
end

function WelfarePage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "WelfarePage" then
            if extraParam == "activityNoticeInfo" then
                if container.mScrollViewRootNode then
                    local children = container.mScrollViewRootNode:getChildren()
                    if children then
                        for i = 1, children:count(), 1 do
                            if children:objectAtIndex(i - 1) then
                                local node = tolua.cast(children:objectAtIndex(i - 1), "ScriptContentBase")
                                local levelId = tonumber(node:getItemDate().mID)
                                if tShowIds[levelId] == 95 then
                                    if registDay == 1 and ActivityInfo.NoticeInfo.OtherPageids[95] then -- vip礼包红点特殊处理
                                        if UserInfo.playerInfo.gold >= 50 and CCUserDefault:sharedUserDefault():getIntegerForKey("VIPGiftPage" .. UserInfo.serverId .. UserInfo.playerInfo.playerId .. registDay) == 0 then
                                            ActivityInfo.NoticeInfo.OtherPageids[95] = true
                                        else
                                            ActivityInfo.NoticeInfo.OtherPageids[95] = nil
                                        end
                                    end
                                end
                                NodeHelper:setNodesVisible(node, { mIconNew = ActivityInfo.NoticeInfo.OtherPageids[tShowIds[levelId]] == true })
                            end
                        end
                    end
                end
            end
        end
    end
    if WelfarePage.subPage and WelfarePage.subPage.onReceiveMessage then
        WelfarePage.subPage:onReceiveMessage(container)
    end
end

local CommonPage = require("CommonPage")
NewServerActivity = CommonPage.newSub(WelfarePage, thisPageName, option)

function WelfarePage_setPart(openActivityId)
    option.openActivityId = openActivityId
end
