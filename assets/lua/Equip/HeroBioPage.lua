local HP_pb = require("HP_pb")
local Activity4_pb = require("Activity4_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "HeroBioPage"
local PAGE_INFO = {
    PAGE_NUM = 2,
    SCROLLVIEW_VIEWWIDTH = 0,
    SCROLLVIEW_VIEWHEIGHT = 0,
    SCROLLVIEW_POSY = 0,
    TAB_NORMAL_IMG = "HeroBio_img_3.png",
    TAB_SELECT_IMG = "HeroBio_img_2.png",
}

local opcodes = {
    ACTIVITY152_C = HP_pb.ACTIVITY152_C,
    ACTIVITY152_S = HP_pb.ACTIVITY152_S,
}

local option = {
    ccbiFile = "EquipmentPageRoleContent_HeroBio.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
        onReward = "onReward",
    },
    opcode = opcodes
}
for i = 1, PAGE_INFO.PAGE_NUM do
    option.handlerMap["onTab" .. i] = "onTab"
end

local HeroBioPage = { }
-- 頁面類型
local PROTO_ACTION = { SYNC = 0, REWARD = 1 }
local PAGE_TYPE = { NONE = 0, PROFILE = 1, STORY = 2 }
local PROFILE_CONTENT_TYPE = { CHARACTERISTIC = 1, HOBBY = 2 }
local nowPageType = PAGE_TYPE.NONE
local pageRoleId = 0
local serverData = nil
-----------------------------------
local HeroBioProfileItem = {
    ccbiFile = "EquipmentPageRoleContent_HeroBio_txt.ccbi",
}
local HeroBioStoryItem = {
    ccbiFile = "EquipmentPageRoleContent_HeroBio_txt2.ccbi",
}
-----------------------------------
function HeroBioPage:refreshProfileItem(container)
    NodeHelper:setStringForLabel(container, {
        mClanTxt = common:getLanguageString("@HeroClan_" .. pageRoleId), mHeightTxt = common:getLanguageString("@HeroHeight_" .. pageRoleId),
        mAgeTxt = common:getLanguageString("@HeroAge_" .. pageRoleId), mWeightTxt = common:getLanguageString("@HeroWeight_" .. pageRoleId),
        mBirthdayTxt = common:getLanguageString("@HeroBirthday_" .. pageRoleId), mMeasureTxt = common:getLanguageString("@HeroMeasure_" .. pageRoleId),
    })
end

function HeroBioPage:refreshStoryItem(container, id)
    if container == nil then
        return
    end
    if nowPageType == PAGE_TYPE.PROFILE then
        if id == PROFILE_CONTENT_TYPE.CHARACTERISTIC then
            NodeHelper:setStringForLabel(container, {
                mTitle = common:getLanguageString("@Characteristic"), mTxt = common:getLanguageString("@HeroCharacteristic_" .. pageRoleId),
            })
        elseif id == PROFILE_CONTENT_TYPE.HOBBY then
            NodeHelper:setStringForLabel(container, {
                mTitle = common:getLanguageString("@Hobby"), mTxt = common:getLanguageString("@HeroHobby_" .. pageRoleId),
            })
        end
    elseif nowPageType == PAGE_TYPE.STORY then
        if id == 0 then
            local str = common:getLanguageString("@HeroStory_" .. pageRoleId)
            --local str=NodeHelper:FunSetLinefeed(tmp,110)
            NodeHelper:setStringForLabel(container, {
                mTitle = common:getLanguageString("@HeroStoryTitle"), mTxt = str})
            container:getVarLabelTTF("mTxt"):setDimensions(CCSizeMake(570, 1000))
        end
    end
    return self:resizeItem(container)
end

function HeroBioPage:resizeItem(container)
    local txt = container:getVarLabelTTF("mTxt")
    local titleNode = container:getVarNode("mTitleNode")
    local contentNode = container:getVarNode("mContentNode")
    local arrowNode = container:getVarNode("mArrowNode")

    local txtHeight = txt:getContentSize().height
    txt:setPositionY(txtHeight)
    contentNode:setContentSize(CCSize(contentNode:getContentSize().width, txtHeight))
    titleNode:setPositionY(txtHeight + arrowNode:getContentSize().height)
    local oldSize = 
    container:setContentSize(CCSize(container:getContentSize().width, txtHeight + arrowNode:getContentSize().height + titleNode:getContentSize().height))
    return container:getContentSize().height
end

function HeroBioPage:onEnter(container)
    serverData = nil
    NodeHelper:setNodesVisible(container, { mRewardNode = self:checkCanReward(container) })

    container:registerMessage(MSG_REFRESH_REDPOINT)
    self:registerPacket(container)
    self:syncServerData(container)
    self:initPageData(container)
    self:initSpine(container)
    self:initScrollView(container)

    NodeHelper:setStringForLabel(container, { mTitle = common:getLanguageString("@HeroName_" .. pageRoleId)})
end
-- 資料初始化
function HeroBioPage:initPageData(container)
    nowPageType = PAGE_TYPE.NONE
end
-- Spine初始化
function HeroBioPage:initSpine(container)
    local parentNode = container:getVarNode("mSpine")
    local spine = SpineContainer:create("NG2D", "NG2D_" .. string.format("%02d", pageRoleId))
    local spineNode = tolua.cast(spine, "CCNode")
    spine:runAnimation(1, "animation", -1)
    spineNode:setScale(NodeHelper:getScaleProportion())
    parentNode:addChild(spineNode)
    -- Particle測試
    --if pageRoleId == 21 then
    --    local parNode = container:getVarNode("mParticleNode")
    --    local particleName = "PFX06_Snow.plist"
    --    local particle = CCParticleSystemQuad:create("UI/particle/" .. particleName)
    --    particle:setAutoRemoveOnFinish(true)
    --    parNode:addChild(particle)
    --end
end
-- ScrollView初始化
function HeroBioPage:initScrollView(container)
    NodeHelper:initScrollView(container, "mContent", 10)
    PAGE_INFO.SCROLLVIEW_VIEWWIDTH = container.mScrollView:getViewSize().width
    PAGE_INFO.SCROLLVIEW_VIEWHEIGHT = container.mScrollView:getViewSize().height
    PAGE_INFO.SCROLLVIEW_POSY = container.mScrollView:getPositionY()
end
-- 刷新頁面內容
function HeroBioPage:refreshPage(container)
    container.mScrollView:removeAllCell()
    container.m_pScrollViewFacade:clearAllItems()
    local nowHeight = 0
    if nowPageType == PAGE_TYPE.PROFILE then
        for i = 1, 2 do
            local pItemData = CCReViSvItemData:new_local()
            local pItem = ScriptContentBase:create(HeroBioStoryItem.ccbiFile)
            local itemHeight = self:refreshStoryItem(pItem, i)
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
            pItemData.m_ptPosition = ccp(0, nowHeight)
            nowHeight = nowHeight + itemHeight
        end
        local pItemData = CCReViSvItemData:new_local()
        local pItem = ScriptContentBase:create(HeroBioProfileItem.ccbiFile)
        self:refreshProfileItem(pItem)
        container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        pItemData.m_ptPosition = ccp(0, nowHeight)
        nowHeight = nowHeight + pItem:getContentSize().height
    elseif nowPageType == PAGE_TYPE.STORY then
        local pItemData = CCReViSvItemData:new_local()
        local pItem = ScriptContentBase:create(HeroBioStoryItem.ccbiFile)
        local itemHeight = self:refreshStoryItem(pItem, 0)
        container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
        pItemData.m_ptPosition = ccp(0, nowHeight)
        nowHeight = nowHeight + itemHeight
    end
    container.mScrollView:setContentSize(CCSize(PAGE_INFO.SCROLLVIEW_VIEWWIDTH, nowHeight))
    container.mScrollView:setViewSize(CCSize(PAGE_INFO.SCROLLVIEW_VIEWWIDTH, math.min(nowHeight, PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)))
    container.mScrollView:setContentOffset(ccp(0, nowHeight >= PAGE_INFO.SCROLLVIEW_VIEWHEIGHT and PAGE_INFO.SCROLLVIEW_VIEWHEIGHT - nowHeight or 0))
    container.m_pScrollViewFacade:setDynamicItemsStartPosition(0)
    container.mScrollView:forceRecaculateChildren()
    container.mScrollView:setTouchEnabled(nowHeight > PAGE_INFO.SCROLLVIEW_VIEWHEIGHT)
    container.mScrollView:setPositionY(nowHeight >= PAGE_INFO.SCROLLVIEW_VIEWHEIGHT and PAGE_INFO.SCROLLVIEW_POSY 
                                       or (PAGE_INFO.SCROLLVIEW_POSY + (PAGE_INFO.SCROLLVIEW_VIEWHEIGHT - nowHeight)))

    NodeHelper:setNodesVisible(container, { mRewardNode = self:checkCanReward(container) })
    if nowPageType == PAGE_TYPE.STORY then
        container.mScrollView:setTouchEnabled(false)
    end
end
-- 領獎按鈕
function HeroBioPage:onReward(container)
    
    local HP_pb = require("HP_pb")
    local msg = Activity4_pb.HeroDramaReq()
    msg.action = PROTO_ACTION.REWARD
    msg.heroId = pageRoleId
    common:sendPacket(HP_pb.ACTIVITY152_C, msg, false)
end
-- 選擇分類頁籤
function HeroBioPage:onTab(container, eventName)
    local index = tonumber(eventName:sub(-1))
    if nowPageType == index then
        return
    end
    nowPageType = index
    for i = 1, PAGE_INFO.PAGE_NUM do
        NodeHelper:setNodesVisible(container, { ["mTabSelect" .. i] = (nowPageType == i) })
        NodeHelper:setMenuItemImage(container, { ["mTab" .. i] = { normal = (nowPageType == i) and PAGE_INFO.TAB_SELECT_IMG or PAGE_INFO.TAB_NORMAL_IMG } })
    end
    self:refreshPage(container)
end
-- 同步資料
function HeroBioPage:syncServerData(container)
    local HP_pb = require("HP_pb")
    local msg = Activity4_pb.HeroDramaReq()
    msg.action = PROTO_ACTION.SYNC
    common:sendPacket(HP_pb.ACTIVITY152_C, msg, false)
end
-- 檢查是否可以領獎勵
function HeroBioPage:checkCanReward(container)
    if not serverData then
        return false
    end
    -- 檢查是否擁有角色
    if not UserMercenaryManager:getUserMercenaryByItemId(pageRoleId) then
        return false
    end
    local canReward = true
    for i = 1, #serverData do
        if pageRoleId == tonumber(serverData[i]) then
            canReward = false
            break
        end
    end
    return canReward
end
-- 檢查是否可以領獎勵(itemId)
function HeroBioPage_checkCanRewardByRoleId(itemId)
    if not serverData then
        return false
    end
    local info = UserMercenaryManager:getUserMercenaryByItemId(itemId)
    if not info then
        return false
    end
    local canReward = true
    for i = 1, #serverData do
        if itemId == tonumber(serverData[i]) then
            canReward = false
            break
        end
    end
    return canReward
end
-- Server回傳
function HeroBioPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    if opcode == HP_pb.ACTIVITY152_S then
        local msg = Activity4_pb.HeroDramaRes()
        msg:ParseFromString(msgBuff)
        local action = msg.action
        if action == PROTO_ACTION.SYNC then
            serverData = msg.gotHero
            self:onTab(container, tostring(PAGE_TYPE.PROFILE))
        elseif action == PROTO_ACTION.REWARD then
            serverData = msg.gotHero
            -- 紅點
            RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.INFO_REWARD_BTN, pageRoleId)
            RedPointManager_refreshPageShowPoint(RedPointManager.PAGE_IDS.INFO_REWARD_BTN2, pageRoleId)
            NodeHelper:setNodesVisible(container, { mRewardNode = self:checkCanReward(container) })

            local rewards = msg.reward
            local rewardTable = { }
            local _type, _itemId, _count = unpack(common:split(rewards, "_"))
            table.insert(rewardTable, { type = tonumber(_type), itemId = tonumber(_itemId), count = tonumber(_count) })
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(rewardTable, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")
        end
    end
end

function HeroBioPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        NodeHelper:setNodesVisible(container, { mRewardNode = self:checkCanReward(container) })
    end
end

function HeroBioPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HeroBioPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function HeroBioPage:onReturn(container)
    PageManager.popPage(thisPageName)
end

function HeroBioPage:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_REFRESH_REDPOINT)
end

function HeroBioPage_setPageRoleId(id)
    pageRoleId = id
end

function HeroBioPage_setServerData(_serverData)
    serverData = _serverData
end

function HeroBioPage_calIsShowRedPoint(itemId)
    return HeroBioPage_checkCanRewardByRoleId(itemId), itemId
end

function HeroBioPage_getPageRoleId()
    return serverData
end

local CommonPage = require('CommonPage')
local HeroBioPage = CommonPage.newSub(HeroBioPage, thisPageName, option)
