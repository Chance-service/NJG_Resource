-- 7天登入
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "MissionDay7Page"
local HP_pb = require("HP_pb")
local SevenDayQuest_pb = require("SevenDayQuest_pb")
local PageJumpMange = require("PageJumpMange")
require("MainScenePage")
local GuideManager = require("Guide.GuideManager")
local NewPlayerBasePage = require("NewPlayerBasePage")

local MissionDay7Page = {
}
local mConfigData = nil
local mServerData = nil
local mCurrentDay = 1
local mCurrentTabPage = 1

local mItemList = { }
local mPageShowData = { }
local mCanGetRewardIdData = { }
local mRedPointIsShowData = { }

local selfContainer = nil
local mTimeLabel = nil
local mBoxBar = nil

local option = {
    ccbiFile = "NewPlayer_MissionDay7Page.ccbi",

    handlerMap =
    {
        onHelp = "onHelp",
    }
}
for i = 1, 7 do
    option.handlerMap["onRTableClick_" .. i] = "onRTableClick"
    option.handlerMap["onBaoXiangClick_" .. i] = "onBaoXiangClick"
end

local opcodes = {
    SEVENDAY_QUEST_INFO_C = HP_pb.SEVENDAY_QUEST_INFO_C,
    SEVENDAY_QUEST_INFO_S = HP_pb.SEVENDAY_QUEST_INFO_S,
    SEVENDAY_QUEST_AWARD_C = HP_pb.SEVENDAY_QUEST_AWARD_C,
    SEVENDAY_QUEST_AWARD_S = HP_pb.SEVENDAY_QUEST_AWARD_S,
    SEVENDAY_QUEST_ACHIEVE_AWARD_C = HP_pb.SEVENDAY_QUEST_ACHIEVE_AWARD_C,
    SEVENDAY_QUEST_ACHIEVE_AWARD_S = HP_pb.SEVENDAY_QUEST_ACHIEVE_AWARD_S,
    SEVENDAY_QUEST_STATUS_UPDATE = HP_pb.SEVENDAY_QUEST_STATUS_UPDATE,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

local DAY_NUM = 7
local BOX_NUM = 4
local BOX_STATE = {
    NULL = 0,
    RECEIVED = 1,
    CAN_GET = 2,
}
local QUEST_STATE = {
    NULL = 0,
    ING = 1,
    COMPLETE = 2,
    RECEIVED = 3
}
local DAY_SPRITE_TABLE = {
    NORMAL = "BG/UI/NewPlayerMilestone_img3.png",
    SELECT = "BG/UI/NewPlayerMilestone_img4.png",
    LOCK = "BG/UI/NewPlayerMilestone_img3.png"
}
local DAY_FNT_TABLE = {
    NORMAL = "Lang/Font_HT_TabSidePageOpen.fnt",
    SELECT = "Lang/Font_HT_TabSidePageSelect.fnt",
    LOCK = "Lang/Font_HT_TabSidePageLock.fnt"
}

local redBtnFntFile = "Lang/Font-HT-Button-red.fnt"
local blueBtnFntFile = "Lang/Font-HT-Button-Blue.fnt"
-------------------------------------------------------
-- item
local ITEM_BAR_HEIGHT = 22
local ITEM_BAR_WIDTH = 150
local SCALE9_BASE_INSET = 3.75
local Item = {
    ccbiFile = "NewPlayer_MissionDay7Item.ccbi",
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

function Item:initData()
    self.mServerData = nil
    self.mConfigData = nil
end

function Item:getId()
    return self.id
end
function Item:getContain()
    return self.container
end

function Item:setData(serverData, configData)
    self.mServerData = serverData
    self.mConfigData = configData
end

function Item:refresh()
    if self.container == nil or self.mServerData == nil or self.mConfigData == nil then return end
    -- 第四列特殊处理
    if mCurrentTabPage == 4 and self.mServerData.state == 3 then
        self.mServerData.finishCount = self.mConfigData.taskTarget
    end
    NodeHelper:setStringForLabel(self.container, { mMessageLabel = common:getLanguageString(self.mConfigData.task, self.mConfigData.taskTarget, self.mServerData.finishCount, self.mConfigData.taskTarget) })

    self:refreshProp()

    self.bar = --[[self.bar or ]]self.container:getVarScale9Sprite("mBar")
    self.bar:setVisible(self.mServerData.finishCount > 0)
    local per = math.min(1, self.mServerData.finishCount / self.mConfigData.taskTarget)
    NodeHelper:setStringForLabel(self.container, { mBarTxt =  self.mServerData.finishCount .. "/" .. self.mConfigData.taskTarget })
    if self.mServerData.state == QUEST_STATE.COMPLETE or   -- 任務完成，可領取獎勵
       self.mServerData.state == QUEST_STATE.RECEIVED then   -- 任務完成，已領取獎勵
        per = 1
        NodeHelper:setStringForLabel(self.container, { mBarTxt =  self.mConfigData.taskTarget .. "/" .. self.mConfigData.taskTarget })
    end

    NodeHelper:setNodesVisible(self.container, { mBar = (per > 0) })
    -- 重設9宮格點位(避免數值太小時變形)
    self.bar:setInsetLeft((per * ITEM_BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (per * ITEM_BAR_WIDTH / 2))
    self.bar:setInsetRight((per * ITEM_BAR_WIDTH > SCALE9_BASE_INSET * 2) and SCALE9_BASE_INSET or (per * ITEM_BAR_WIDTH / 2))
    self.bar:setContentSize(CCSize(per * ITEM_BAR_WIDTH, ITEM_BAR_HEIGHT))

    if mCurrentDay > mServerData.registerDay then
        if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_WIN32 then
            NodeHelper:setNodesVisible(self.container, { mBtnNode = true, mBuyNode = false })
            --local menuItemImage = self.container:getVarMenuItemImage("mBtn")
            NodeHelper:setMenuItemImage(self.container, { mBtn = { disabled = "NG4_Silver_S.png" } })
            NodeHelper:setMenuItemsEnabled(self.container, { mBtn = false })
            --menuItemImage:setEnabled(false)
            local btnLabel = self.container:getVarLabelTTF("mBtnLabel")
            btnLabel:setString(common:getLanguageString("@SevenDayQuestTomorrowOpenBtn"))
            --NodeHelper:setNodeIsGray(self.container, { mBtnLabel = true })
            return
        end
    end

    if self.mConfigData.type == 0 then
        NodeHelper:setNodesVisible(self.container, { mBtnNode = true, mBuyNode = false })
        local btnLabel = self.container:getVarLabelTTF("mBtnLabel")
        --btnLabel:setFntFile(redBtnFntFile)
        NodeHelper:setNodeIsGray(self.container, { mBtnLabel = false })

        local menuItemImage = self.container:getVarMenuItemImage("mBtn")
        --NodeHelper:setMenuItemImage(self.container, { mBtn = { normal = "common_ht_btn_red_middle.png", disabled = "common_ht_btn_gray_middle.png" } })
        menuItemImage:setEnabled(true)

        if self.mServerData.state == QUEST_STATE.ING then    -- 任務進行中
            NodeHelper:setMenuItemImage(self.container, { mBtn = { normal = "NG4_Silver_N.png", 
                                                                   disabled = "NG4_Silver_S.png", 
                                                                   press = "NG4_Silver_S.png" } })
            --btnLabel:setFntFile(blueBtnFntFile)
            btnLabel:setString(common:getLanguageString("@MissionDay7_GoTo"))
            NodeHelper:setNodeIsGray(self.container, { mBtnLabel = false })
            menuItemImage:setEnabled(true)
            if self.mConfigData.jumpId == 0 then    -- 不可跳轉，設成灰色不可點擊
                btnLabel:setString(common:getLanguageString("@KeyReceive2"))
                NodeHelper:setNodeIsGray(self.container, { mBtnLabel = true })
                menuItemImage:setEnabled(false)
            end
        elseif self.mServerData.state == QUEST_STATE.COMPLETE then  -- 任務完成，可領取獎勵
            NodeHelper:setMenuItemImage(self.container, { mBtn = { normal = "NG4_Golden_N.png", 
                                                                   disabled = "NG4_Grey.png",
                                                                   press = "NG4_Golden_S.png" } })
            --btnLabel:setFntFile(redBtnFntFile)
            btnLabel:setString(common:getLanguageString("@KeyReceive2"))
            NodeHelper:setNodeIsGray(self.container, { mBtnLabel = false })
            menuItemImage:setEnabled(true)
        elseif self.mServerData.state == QUEST_STATE.RECEIVED then   -- 任務完成，已領取獎勵
            NodeHelper:setMenuItemImage(self.container, { mBtn = { normal = "NG4_Silver_N.png", 
                                                                   disabled = "NG4_Silver_S.png",
                                                                   press = "NG4_Silver_S.png" } })
            --btnLabel:setFntFile(redBtnFntFile)
            btnLabel:setString(common:getLanguageString("@MissionDay7_ReceivedHave"))
            --NodeHelper:setNodeIsGray(self.container, { mBtnLabel = true })
            menuItemImage:setEnabled(false)
        end

    elseif self.mConfigData.type == 1 then  -- 購買按鈕
        NodeHelper:setNodesVisible(self.container, { mBtnNode = false, mBuyNode = true })
        local price, oldPrice = unpack(common:split(self.mConfigData.price, "_"))
        NodeHelper:setStringForLabel(self.container, { mBuyPriceLabel = price, mOldPriceLabel = oldPrice })
        local menuItemImage = self.container:getVarMenuItemImage("mBuyBtn")

        menuItemImage:setEnabled(true)
        NodeHelper:setNodeIsGray(self.container, { mBuyPriceLabel = false })
        NodeHelper:setNodeIsGray(self.container, { mPriceIcon = false })

        if self.mServerData.state == 1 or self.mServerData.state == 2 then
            menuItemImage:setEnabled(true)
            NodeHelper:setNodeIsGray(self.container, { mBuyPriceLabel = false })
            NodeHelper:setNodeIsGray(self.container, { mPriceIcon = false })
        elseif self.mServerData.state == 3 then
            menuItemImage:setEnabled(false)
            --NodeHelper:setNodeIsGray(self.container, { mBuyPriceLabel = true })
            --NodeHelper:setNodeIsGray(self.container, { mPriceIcon = true })
        end
    end

end

function Item:refreshProp()
    self.RewardProp = { }

    local rewardItems = { }
    local itemInfo = self.mConfigData.reward
    for _, item in ipairs(common:split(itemInfo, ",")) do
        local _type, _id, _count = unpack(common:split(item, "_"))
        table.insert(rewardItems, {
            type = tonumber(_type),
            itemId = tonumber(_id),
            count = tonumber(_count)
        } )
    end

    NodeHelper:fillRewardItem(self.container, rewardItems)

    self.RewardProp = rewardItems
end

function Item:setState(state)
    self.mServerData.state = state
    self:refresh()
end

function Item:onBuyBtnClick(container)
    local price, oldPrice = unpack(common:split(self.mConfigData.price, "_"))
    if UserInfo.isGoldEnough(price) then
        self:sendGetReward(self.id)
    end
end

function Item:onBtnClick(container)
    if self.mConfigData.type == 0 then
        if self.mServerData.state == QUEST_STATE.ING then
            if self.mConfigData.jumpId == 23 then
                if UserInfo.roleInfo.level < GameConfig.ELITEMAP_OPEN_LEVEL then
                    MessageBoxPage:Msg_Box_Lan("@EliteMapNotEnoughLevel")
                    return
                end
            end
            PageJumpMange.JumpPageById(self.mConfigData.jumpId)
        elseif self.mServerData.state == QUEST_STATE.COMPLETE then
            self:sendGetReward(self.id)
        end
    elseif self.mConfigData.type == 1 then
        local price, oldPrice = unpack(common:split(self.mConfigData.price, "_"))
        if UserInfo.isCoinEnough(price) then
            self:sendGetReward(self.id)
        end
    end
end

function Item_sendGetReward(id)
    local itemServerData = MissionDay7Page.getItemServerData(selfContainer, id)
    if itemServerData.state == QUEST_STATE.RECEIVED then
        GuideManager.IsNeedShowPage = false
        GuideManager.setNextNewbieGuide()
        PageManager.pushPage("NewbieGuideForcedPage")
    elseif itemServerData.state == QUEST_STATE.ING then
        GuideManager.IsNeedShowPage = false
        GuideManager.setNextNewbieGuide()
        PageManager.pushPage("NewbieGuideForcedPage")
    else
        local msg = SevenDayQuest_pb.SevenDayQuestAwardReq()
        msg.questId = id
        common:sendPacket(opcodes.SEVENDAY_QUEST_AWARD_C, msg, false)
    end

end
function Item:sendGetReward(id)
    local msg = SevenDayQuest_pb.SevenDayQuestAwardReq()
    msg.questId = id
    common:sendPacket(opcodes.SEVENDAY_QUEST_AWARD_C, msg, false)
end

function Item:onFrame1(container)
    GameUtil:showTip(container:getVarNode("mFrame" .. 1), self.RewardProp[1])
end
function Item:onFrame2(container)
    GameUtil:showTip(container:getVarNode("mFrame" .. 2), self.RewardProp[2])
end
function Item:onFrame3(container)
    GameUtil:showTip(container:getVarNode("mFrame" .. 3), self.RewardProp[3])
end
function Item:onFrame4(container)
    GameUtil:showTip(container:getVarNode("mFrame" .. 4), self.RewardProp[4])
end

-------------------------------------------------------

function MissionDay7Page:onEnter(container)
    self:registerPacket(container)
    if not self.container or tolua.isnull(self.container) then
        self.container = ScriptContentBase:create(option.ccbiFile)
    end
    self.container:registerFunctionHandler(MissionDay7Page.onFunction)
    selfContainer = self.container
    local bg = self.container:getVarSprite("mBGSprite")
    --bg:setScale(NodeHelper:getScaleProportion())
    self:initData()
    self:initUi(self.container)
    --container:registerMessage(MSG_MAINFRAME_REFRESH)

    NodeHelper:setNodesVisible(self.container, { mInfoNode = false })

    self:sendLoginSignedInfoReqMessage()

    -- 新手教學
    GuideManager.PageContainerRef["MissionDay"] = self.container
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.currGuide[GuideManager.guideType.SEVENDAY_GUIDE] ~= 0 then
        if GuideManager.isInGuide == false then
            GuideManager.currGuideType = GuideManager.guideType.SEVENDAY_GUIDE
            GuideManager.newbieGuide()
        end
    end
    return self.container
end

function MissionDay7Page:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode")
    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[118]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode")
        spineNode:addChild(spineToNode)
        spineToNode:setTag(10086)
        spine:runAnimation(1, "Stand", -1)

        local spinePosOffset = mConfigData[10001].tagName --偏移
        local spineScale = mConfigData[10001].task --缩放
        
        local offset_X_Str, offset_Y_Str = unpack(common:split((spinePosOffset), ","))
        NodeHelper:setNodeOffset(spineToNode, tonumber(offset_X_Str), tonumber(offset_Y_Str))
        spineToNode:setScale(spineScale)
    end
end

function MissionDay7Page:initData()
    mConfigData = ConfigManager.getSevenDayQuestData()
    mServerData = nil
    mCurrentDay = 0
    mCurrentTabPage = 1
    mRedPointIsShowData = { }
    mPageShowData = { }

    for i = 1, DAY_NUM do
        mPageShowData[i] = { }
        mRedPointIsShowData[i] = { isShow = false }
    end
    for k, v in pairs(mConfigData) do
        if v.day > 0 and v.tagNum > 0 then
            table.insert(mPageShowData[v.day], v)
        end
    end
    for i = 1, DAY_NUM do
        table.sort(mPageShowData[i], function(data1, data2)
            return data1.taskTarget < data2.taskTarget
        end)
    end
end

function MissionDay7Page:initUi(container)
    mTimeLabel = container:getVarLabelTTF("mTimerTxt")

    self.mScrollView = container:getVarScrollView("mContent")

    --self:initSpine(self.container)

    mBoxBar = container:getVarNode("mBoxBar")
    mBoxBar:setScaleX(0)
end

function MissionDay7Page:onExit(container)
    self:removePacket(container)
    if container.mScrollView then
        container.mScrollView:removeAllCell()
        container.mScrollView = nil
        container.mScrollViewRootNode = nil
    end
end

function MissionDay7Page:refreshAll(container)
    if mCurrentDay == 0 then
        mCurrentDay = 2
        if GuideManager.isInGuide then
            mCurrentDay = 2
        else
            if mServerData.registerDay >= 7 then
                mCurrentDay = 7
            else
                mCurrentDay = mServerData.registerDay + 1 or 2
            end
        end
    end
    for i = 1, BOX_NUM do
        local label = container:getVarLabelBMFont("mBaoXiangText_" .. i)
        if mServerData.pointCore[i] then
            label:setString(mServerData.pointCore[i].pointNumber .. "")
        end
    end

    self:checkRedPoint()
    self:refreshRedPoint(container) -- 天數頁籤紅點
    self:refreshDayTableBtn(container, mCurrentDay) -- 頁籤顯示
    self:refreshUserInfo(container) -- 玩家鑽石/金幣
    self:setHasPoint(container, mServerData.hasPoint)   -- 寶箱進度
    for k, v in pairs(mServerData.pointCore) do -- 寶箱狀態
        self:setBoxState(container, v.pointNumber, v.state)
    end
    local isHaveBoxGet = self:getBoxCanGet()
    if isHaveBoxGet then
        ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] = true
    end
end
-- 刷新玩家金幣&鑽石數量
function MissionDay7Page:refreshUserInfo(container)
    local coinStr = GameUtil:formatNumber(UserInfo.playerInfo.coin)
    local diamondStr = GameUtil:formatNumber(UserInfo.playerInfo.gold)
    NodeHelper:setStringForLabel(container, { mCoin = coinStr, mDiamond = diamondStr })
end
-- 寶箱點數顯示
function MissionDay7Page:setHasPoint(container, count)
    mServerData.hasPoint = count
    NodeHelper:setStringForLabel(container, { mCountLabel = mServerData.hasPoint })
    mBoxBar:setScaleX(self:getBarScaleX(mServerData.hasPoint))
end
-- 進度條scale
function MissionDay7Page:getBarScaleX(mSigninCount)
    local scaleXTable = { }
    local totlaPoint = 0
    for i = 1, BOX_NUM do
        local regionPoint = mServerData.pointCore[i].pointNumber - totlaPoint
        totlaPoint = mServerData.pointCore[i].pointNumber
        table.insert(scaleXTable, { mServerData.pointCore[i].pointNumber, (1 / BOX_NUM) / regionPoint })
    end
    local scaleX = 0
    for i = 1, #scaleXTable do
        if mSigninCount < scaleXTable[i][1] then
            if i == 1 then
                scaleX = scaleX + mSigninCount * scaleXTable[i][2]
            else
                scaleX = scaleX + (i - 1) * (1 / BOX_NUM) + ((mSigninCount - scaleXTable[i - 1][1]) * scaleXTable[i][2])
            end
            break
        elseif mSigninCount == scaleXTable[i][1] then
            scaleX = i * (1 / BOX_NUM)
            break
        end
    end
    return scaleX
end

function MissionDay7Page:getItemServerData(id)
    for k, v in pairs(mServerData.allQuest) do
        if v.questId == id then
            return v
        end
    end
end

function MissionDay7Page:getBoxIndex(pointCount)
    local n = 0
    for k, v in pairs(mServerData.pointCore) do
        if v.pointNumber == pointCount then
            n = k
            break
        end
    end
end

function MissionDay7Page:setBoxState(container, pointCount, state)
    for k, v in pairs(mServerData.pointCore) do
        if v.pointNumber == pointCount then
            v.state = state
            break
        end
    end

    self:refreshBox(container, self:getBoxIndex(pointCount))
end

function MissionDay7Page:setBoxAniState(item, boxState)
    if type(item) == "userdata" then
        if boxState == BOX_STATE.NULL then
            NodeHelper:setNodeVisible(item, false)
            -- item:runAnimation("Null")
            -- item:setZOrder(0)
        elseif boxState == BOX_STATE.RECEIVED then
            NodeHelper:setNodeVisible(item, false)
            -- item:runAnimation("Null")
            -- item:setZOrder(0)
        elseif boxState == BOX_STATE.CAN_GET then
            NodeHelper:setNodeVisible(item, true)
            -- item:runAnimation("CloseState")
            -- item:setZOrder(1)
        end
    end
end

function MissionDay7Page:refreshBox(container, index)
    for k = 1, BOX_NUM do
        local boxState = BOX_STATE.NULL
        local node = container:getVarNode("mBoxEffect" .. k)

        local label = container:getVarLabelBMFont("mBaoXiangText_" .. k)
        label:setString(mServerData.pointCore[k].pointNumber)
        local menuItemImage = container:getVarMenuItemImage("mBaoXiangBtn_" .. k)
        local mBoxSprite = container:getVarSprite("mBoxSprite" .. k)
        mBoxSprite:setVisible(true)
        mBoxSprite:setTexture("Imagesetfile/DayLogin30/DayLogin30_treasurebox.png")
        local boxPoint = container:getVarSprite("mBoxPoint" .. k)
        if self:getIsCanGetBox(k) then
            if self:getIsGetBox(k) then
                -- 已领取
                menuItemImage:setEnabled(false)
                mBoxSprite:setTexture("DayLogin30_treasurebox_open.png")
                boxState = BOX_STATE.RECEIVED
                boxPoint:setVisible(false)
            else
                -- 可领取
                menuItemImage:setEnabled(true)
                boxState = BOX_STATE.CAN_GET
                boxPoint:setVisible(true)
            end
        else
            -- 未达到领取条件
            menuItemImage:setEnabled(true)
            boxState = BOX_STATE.NULL
            boxPoint:setVisible(false)
        end

        self:setBoxAniState(node, boxState)
    end
end

function MissionDay7Page:getIsCanGetBox(index)
    return mServerData.hasPoint >= mServerData.pointCore[index].pointNumber
end

function MissionDay7Page:getIsGetBox(index)
    return mServerData.pointCore[index].state == 2
end

function MissionDay7Page:onExecute(container)
    self:onTimer(container)
end

function MissionDay7Page:onTimer(container)
    local remainTime = NewPlayerBasePage:getActivityTime()
    local timeStr = common:second2DateString5(remainTime, false)
    mTimeLabel:setString("" .. timeStr)
end

function MissionDay7Page:onHelp(container)

end

function MissionDay7Page:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
    container:registerPacket(HP_pb.SEVENDAY_QUEST_STATUS_UPDATE)
end

function MissionDay7Page:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.SEVENDAY_QUEST_INFO_S then   -- 任務內容初始化
        local msg = SevenDayQuest_pb.SevenDayQuestRep()
        msg:ParseFromString(msgBuff)
        curLoginDay = msg.registerDay   -- 登入天數
        mServerData = { }
        mServerData.surplusTime = msg.surplusTime   -- 剩餘時間
        mServerData.registerDay = msg.registerDay   -- 登入天數
        mServerData.hasPoint = msg.hasPoint         -- 寶箱點數
        mServerData.allQuest = { }                  -- 任務資訊
        mServerData.pointCore = { }                 -- 寶箱資訊
        for i = 1, #msg.allQuest do
            mServerData.allQuest[i] = msg.allQuest[i]
        end
        for i = 1, #msg.pointCore do
            mServerData.pointCore[i] = msg.pointCore[i]
        end
        table.sort(mServerData.pointCore, function(pointCore1, pointCore2)
            return pointCore1.pointNumber < pointCore2.pointNumber
        end )

        NodeHelper:setNodesVisible(self.container, { mInfoNode = true })
        self:refreshAll(self.container)
        local NewPlayerBasePage = require("NewPlayerBasePage")
        NewPlayerBasePage:setActivityTime(mServerData.surplusTime)
    elseif opcode == HP_pb.SEVENDAY_QUEST_AWARD_S then  -- 任務獎勵
        local msg = SevenDayQuest_pb.SevenDayQuestAwardRep()
        msg:ParseFromString(msgBuff)
        if msg.flag == 1 then
            mServerData.hasPoint = mServerData.hasPoint + msg.addPoint
            self:setHasPoint(self.container, mServerData.hasPoint)
            self:setItemState(msg.questId, msg.state)
            self:refreshAll(self.container)
            --MessageBoxPage:Msg_Box_Lan("@RewardItem")
        end
    elseif opcode == HP_pb.SEVENDAY_QUEST_ACHIEVE_AWARD_S then  -- 寶箱獎勵
        local msg = SevenDayQuest_pb.SevenDayPointAwardRep()
        msg:ParseFromString(msgBuff)
        if msg.flag == 1 then
            self:setBoxState(self.container, msg.pointCount, msg.state)
        end
    elseif opcode == HP_pb.SEVENDAY_QUEST_STATUS_UPDATE then   -- 同步任務狀態
        local msg = SevenDayQuest_pb.SyncQuestItemInfo()
        msg:ParseFromString(msgBuff)
        if mServerData == nil then
            return
        end
        for i = 1, #mServerData.allQuest do
            if msg.items ~= nil then
                for j = 1, #msg.items do
                    if mServerData.allQuest[i].questId == msg.items[j].questId then
                        mServerData.allQuest[i].state = msg.items[j].state
                        mServerData.allQuest[i].finishCount = msg.items[j].finishCount
                        break
                    end
                end
            end
        end
        self:refreshAll(self.container)
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.onReceivePlayerAward(msgBuff)
    end
end

function MissionDay7Page:checkRedPoint()
    mCanGetRewardIdData = { }

    for k, v in pairs(mServerData.allQuest) do
        if v.state == QUEST_STATE.COMPLETE then
            local id = v.questId
            local day = mConfigData[id].day
            local index = mConfigData[id].tagNum
            mCanGetRewardIdData[id] = { day = day, index = index }
        end
    end
end

function MissionDay7Page:refreshRedPoint(container)
    local redPointCount = 0
    for i = 1, DAY_NUM do
        local sp = container:getVarSprite("mDayPoint_" .. i)
        local isShow = self:getIsShowDayRedPoint(i)
        if isShow then
            redPointCount = redPointCount + 1
        end
        sp:setVisible(isShow)
    end
    if redPointCount == 0 then
        ActivityInfo.changeActivityNotice(Const_pb.ACCUMULATIVE_LOGIN_SEVEN)
    else
        ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[Const_pb.ACCUMULATIVE_LOGIN_SEVEN] = true
    end
end

function MissionDay7Page:getIsShowDayRedPoint(day)
    local isShow = false
    if day > mServerData.registerDay then
        return false
    end
    for k, v in pairs(mCanGetRewardIdData) do
        if v.day == day then
            isShow = true
            break
        end
    end

    return isShow
end

function MissionDay7Page:getBoxCanGet()
    local isHaveBoxGet = false
    for k = 1, BOX_NUM do
        if self:getIsCanGetBox(k) then
            if self:getIsGetBox(k) then

            else
                isHaveBoxGet = true
                break
            end
        end
    end
    return isHaveBoxGet
end

function MissionDay7Page:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
    container:removePacket(HP_pb.SEVENDAY_QUEST_STATUS_UPDATE)
end

function MissionDay7Page:removeScrollViewItems(container)
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
end

function MissionDay7Page:initScrollViewItems(container)
    self:removeScrollViewItems()
    mItemList = { }

    local itemData = { }
    -- 已完成
    for k, v in pairs(mPageShowData[mCurrentDay]) do
        local itemServerData = self:getItemServerData(v.id)
        if itemServerData.state == QUEST_STATE.COMPLETE then
            local t = { configData = v, serverData = itemServerData }
            table.insert(itemData, t)
        end
    end
    -- 進行中
    for k, v in pairs(mPageShowData[mCurrentDay]) do
        local itemServerData = self:getItemServerData(v.id)
        if itemServerData.state == QUEST_STATE.ING then
            local t = { configData = v, serverData = itemServerData }
            table.insert(itemData, t)
        end
    end
    -- 已結束
    for k, v in pairs(mPageShowData[mCurrentDay]) do
        local itemServerData = self:getItemServerData(v.id)
        if itemServerData.state == QUEST_STATE.RECEIVED then
            local t = { configData = v, serverData = itemServerData }
            table.insert(itemData, t)
        end
    end

    for k, v in pairs(itemData) do
        local cell = CCBFileCell:create()
        local panel = Item:new({ id = v.configData.id, mServerData = v.serverData, mConfigData = v.configData })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(Item.ccbiFile)
        self.mScrollView:addCell(cell)
        table.insert(mItemList, panel)
    end

    self.mScrollView:orderCCBFileCells()
end

function MissionDay7Page:setItemState(id, state)
    for k, v in pairs(mItemList) do
        if v:getId() == id then
            -- v:setState(state)
        end
    end

    for k, v in pairs(mServerData.allQuest) do
        if v.questId == id then
            v.state = state
        end
    end
end

function MissionDay7Page:sendLoginSignedInfoReqMessage()
    local msg = SevenDayQuest_pb.SevenDayQuestReq()
    common:sendPacket(opcodes.SEVENDAY_QUEST_INFO_C, msg, false)
end

function MissionDay7Page:refreshDayTableBtn(container, index)
    if mServerData == nil then return end

    if index > mServerData.registerDay + 1 then -- 天數不足
        --if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_WIN32 then
            MessageBoxPage:Msg_Box_Lan("@SevenDayQuestDay2Desc")
            return
        --end
    end

    mCurrentDay = index
    for i = 1, DAY_NUM do
        if i <= mServerData.registerDay + 1 then
            local bmFontLabel = container:getVarLabelBMFont("mRTableLabel_" .. i)
            if index == i then
                bmFontLabel:setFntFile(DAY_FNT_TABLE.SELECT)
                NodeHelper:setNormalImages(container, { ["mDayBtn_" .. i] = DAY_SPRITE_TABLE.SELECT })
            else
                bmFontLabel:setFntFile(DAY_FNT_TABLE.NORMAL)
                NodeHelper:setNormalImages(container, { ["mDayBtn_" .. i] = DAY_SPRITE_TABLE.NORMAL })
            end
        end
    end
    self:initScrollViewItems(container)
end

function MissionDay7Page:sendGetBoxAwardsMessage(index)
    if mServerData == nil then return end

    if mServerData.hasPoint >= mServerData.pointCore[index].pointNumber then
        local msg = SevenDayQuest_pb.SevenDayPointAwardReq()
        msg.pointCount = mServerData.pointCore[index].pointNumber
        common:sendPacket(opcodes.SEVENDAY_QUEST_ACHIEVE_AWARD_C, msg, false)
    else
        local id = 1000 + index
        local rewardItems = { }

        local itemInfo = mConfigData[id]
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"))
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } )
        end

        RegisterLuaPage("GodEquipPreview")
        ShowEquipPreviewPage(rewardItems, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@RewardPreviewTitleTxt"))
        PageManager.pushPage("GodEquipPreview")
    end
end

function MissionDay7Page:onBaoXiangClick(container, eventName)
    local box = tonumber(eventName:sub(-1))
    self:sendGetBoxAwardsMessage(box)
end

function MissionDay7Page:onRTableClick(container, eventName)
    local page = tonumber(eventName:sub(-1))
    self:refreshDayTableBtn(container, page)
    MissionDay7Page:refreshRedPoint(self.container)
end

function MissionDay7Page.onFunction(eventName, container)
    if string.find(eventName, "onRTableClick_") then
        MissionDay7Page:onRTableClick(container, eventName)
    elseif string.find(eventName, "onBaoXiangClick_") then
        MissionDay7Page:onBaoXiangClick(container, eventName)
    elseif eventName == option.handlerMap.onHelp then
        MissionDay7Page:onHelp(container)
    end
end

local CommonPage = require("CommonPage")
cccc = CommonPage.newSub(MissionDay7Page, thisPageName, option)

return MissionDay7Page