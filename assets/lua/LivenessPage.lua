local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "LivenessPage"
local HP_pb = require("HP_pb")
local Activity4_pb = require("Activity4_pb")
local CONST = require("Battle.NewBattleConst")

local LivenessPage = {
}
LivenessPage.timerName = "LivenessPage_timerName"
local configData = nil
local mIsInitScrollView = false
local mIsUpdateTime = false
local mSigninCount = 0
local mItemList = { }
local serverData = nil
local mIsJumpToDaily = false
local option = {
    ccbiFile = "LivenessPage.ccbi",
    handlerMap = {
        onClose = "onClose",
        onClaim = "onClaim",
        onClick = "onClick",
        onHand = "onHand",
    }
}
local opcodes = {
    ACTIVECOMPLIANCE_INFO_C = HP_pb.ACTIVECOMPLIANCE_INFO_C,
    ACTIVECOMPLIANCE_INFO_S = HP_pb.ACTIVECOMPLIANCE_INFO_S,
    ACTIVECOMPLIANCE_AWARD_C = HP_pb.ACTIVECOMPLIANCE_AWARD_C,
    ACTIVECOMPLIANCE_AWARD_S = HP_pb.ACTIVECOMPLIANCE_AWARD_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}

-----------------------------------
-- Item
local LivenessPageItemState = {
    Null = 0,
    -- 已領取
    HaveReceived = 1,
    -- 可補簽
    Supplementary = 2,
    -- 可以領取
    CanGet = 3
}

local LivenessPageItem = {
    ccbiFile = "DayLogin30Item.ccbi",
}
function LivenessPageItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function LivenessPageItem:onRefreshContent(ccbRoot)
    self:refresh(ccbRoot:getCCBFileNode())
end

function LivenessPageItem:setState(state)
    self.mState = state
end

function LivenessPageItem:getState()
    return self.mState
end

function LivenessPageItem:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function LivenessPageItem:refresh(container)
    if container == nil then
        return
    end

    if self.rewardData == nil then
        local rewardItems = { }
        local itemInfo = configData[self.id]
        if itemInfo.items ~= nil then
            for _, item in ipairs(common:split(itemInfo.items, ",")) do
                local _type, _id, _count = unpack(common:split(item, "_"));
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
    NodeHelper:setQualityFrames(container, { mQuality = resInfo.quality })
    local icon = container:getVarSprite("mIconSprite")
    --icon:setPosition(ccp(0, 0))

    NodeHelper:setStringForLabel(container, { mNumLabel = (self.rewardData.type == 40000 and "" or tostring(resInfo.count)) })

    local mGetSprite = container:getVarSprite("mGetSprite")
    local mDayLabel = container:getVarLabelTTF("mDayLabel")
    local mTodayNode = container:getVarNode("mTodayNode")
    local mMask = container:getVarSprite("mMask")
    local mSpine=container:getVarNode("mSpine")
    LivenessPageItem:setAnim(container)
    if self.mState == LivenessPageItemState.HaveReceived then
        mDayLabel:setString(common:getLanguageString("@Receive"))
        mDayLabel:setColor(ccc3(248, 205, 127))
        mSpine:setVisible(false)
    end
    if self.mState == LivenessPageItemState.Null then
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(ccc3(81, 75, 78))
        mSpine:setVisible(false)
    end
    if self.mState == LivenessPageItemState.CanGet then
        mDayLabel:setString(common:getLanguageString("@DayLogin30_CurrontDay", string.format("%02d", self.id)))
        mDayLabel:setColor(ccc3(81, 75, 78))
        mSpine:setVisible(true)
    end
    mMask:setVisible(self.mState == LivenessPageItemState.HaveReceived)
    mGetSprite:setVisible(self.mState == LivenessPageItemState.HaveReceived)
    mTodayNode:setVisible(self.mState == LivenessPageItemState.CanGet)
    for i = 1, 5 do -- icon星星
        container:getVarSprite("mStar" .. i):setVisible(self.rewardData.type == 40000 and resInfo.quality >= i)
    end
end
function LivenessPageItem:setAnim(container)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_06_WaitItem"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode=container:getVarNode("mSpine")
    parentNode:removeAllChildrenWithCleanup(true)
    parentNode:addChild(spineNode)
    spine:runAnimation(1, "animation", -1)
    parentNode:setScale(0.75)
    parentNode:setPositionY(5)
end
-- item點擊
function LivenessPageItem:onClick(container)
    if self.rewardData ~= nil then
        GameUtil:showTip(container:getVarNode("mIconSprite"), self.rewardData)
    end
end

-----------------------------------------------
function LivenessPage:onEnter(container)
    self.container = container
    self:initData()
    self:initUi(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:sendLoginSignedInfoReqMessage()
end

function LivenessPage:initSpine(container)
    local spineNode = container:getVarNode("mSpineNode")
    if spineNode:getChildByTag(10086) == nil then
        spineNode:removeAllChildren()

        local spine = SpineContainer:create("NG2D", "NG2D_21")
        local spineToNode = tolua.cast(spine, "CCNode")
        spineNode:addChild(spineToNode)
        spineToNode:setTag(10086)
        spineToNode:setScale(NodeHelper:getScaleProportion())
        spine:runAnimation(1, "animation", -1)
    end
    local heroCfg = ConfigManager.getNewHeroCfg()[21]
    if heroCfg then
        local chibiParentNode = container:getVarNode("mSpine2")
        chibiParentNode:removeAllChildrenWithCleanup(true)
        local spineFolder, spineName = unpack(common:split(heroCfg.Spine, ","))
        --if not NodeHelper:isFileExist(spineFolder .. "/" .. spineName .. "000" .. ".json") and
        --   not NodeHelper:isFileExist(spineFolder .. "/" .. spineName .. "000" .. ".skel") then
        --    return
        --end
        local chibiSpine = SpineContainer:create(spineFolder, spineName .. "000")
        local chibiSpineNode = tolua.cast(chibiSpine, "CCNode")
        chibiSpine:runAnimation(1, CONST.BUFF_SPINE_ANI_NAME.WAIT, -1)
        chibiParentNode:addChild(chibiSpineNode)
    end
end

function LivenessPage:initData()
    configData = ConfigManager.getActDailyPointRewardCfg()
end

function LivenessPage:initUi(container)
    self:initSpine(self.container)
end

-------------------------------onClick--------------------------------
function LivenessPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function LivenessPage:onClaim(container)
    if mItemList[serverData.days]:getState() == LivenessPageItemState.CanGet then
        local msg = Activity4_pb.ActiveComplianceAwardReq()
        msg.day = serverData.days
        common:sendPacket(opcodes.ACTIVECOMPLIANCE_AWARD_C, msg, false)
    else
        --MessageBoxPage:Msg_Box_Lan("@ERRORCODE_9006")
    end
end

function LivenessPage_onClaim(container)
    --LivenessPage:onClaim(container)
end

-- 角色點擊
function LivenessPage:onHand(container)
    local rolePage = require("NgArchivePage")
    PageManager.pushPage("NgArchivePage")
    rolePage:setMercenaryId(21)
    --NgArchivePage_setToSkin(false, 1)
end
----------------------------------------------------------------------

function LivenessPage:onExit(container)
    local spineNode = container:getVarNode("mSpineNode")
    spineNode:removeAllChildren()

    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName)
    mIsUpdateTime = false
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    mIsInitScrollView = false
    self:removePacket(container)
    if container.mScrollView then
        container.mScrollView:removeAllCell()
        container.mScrollView = nil
        container.mScrollViewRootNode = nil
    end
end

function LivenessPage:refreshAll(container)
    self:updateTime(container)
    self:refreshItem(container)

    if #serverData.awardDays == serverData.days then
        ActivityInfo.changeActivityNotice(122)
        PageManager.refreshPage("MissionMainPage", "refreshSignState")
    end
    if mItemList[serverData.days]:getState() == LivenessPageItemState.CanGet then
        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", true)
    else
        NodeHelper:setMenuItemEnabled(container, "mReceiveBtn", false)
    end
end

function LivenessPage:refreshItem(container)
    if not mIsInitScrollView then
        mItemList = { }
        self:initScrollView(container)
        mIsInitScrollView = true
    end

    for k, v in pairs(mItemList) do
        if serverData.days >= k then
            if self:isContain(serverData.awardDays, k) then
                -- 已領取
                v:setState(LivenessPageItemState.HaveReceived)
            else
                -- 可領取
                v:setState(LivenessPageItemState.CanGet)
            end
        else
            -- 未達標
            v:setState(LivenessPageItemState.Null)
        end
    end

    -- 刷新item
    for k, v in pairs(mItemList) do
        v:refresh(v:getCCBFileNode())
    end
end

function LivenessPage:isContain(t, num)
    for i = 1, #t do
        if t[i] == num then
            return true
        end
    end
    return false
end

function LivenessPage:updateTime(container)
    if serverData.surplusTime > 0 then
        if not TimeCalculator:getInstance():hasKey(self.timerName) then
            TimeCalculator:getInstance():createTimeCalcultor(self.timerName, serverData.surplusTime)
        end
        mIsUpdateTime = true
    else
        mIsUpdateTime = false
    end
end

function LivenessPage:onExecute(container)
    if mIsUpdateTime then
        if not TimeCalculator:getInstance():hasKey(self.timerName) then
            if serverData.surplusTime == 0 then
                local endStr = common:getLanguageString("@ActivityEnd")
                NodeHelper:setStringForLabel(container, { mTimeTxt = endStr })
            elseif serverData.surplusTime < 0 then
                NodeHelper:setStringForLabel(container, { mTimeTxt = "" })
            end
            return
        end

        local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName)
        if remainTime + 1 > serverData.surplusTime then
            return
        end
        local timeStr =  common:second2DateString4(remainTime,true)
        local text=string.format(common:getLanguageString("@ActPopUpSale.LeftTimeText.dhm"),timeStr[1], timeStr[2], timeStr[3], timeStr[4])
        NodeHelper:setStringForLabel(container, { mTimeTxt = text })
    end
end

function LivenessPage:onClose(container)
    PageManager.popPage(thisPageName)
end

function LivenessPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function LivenessPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.ACTIVECOMPLIANCE_INFO_S or opcode == HP_pb.ACTIVECOMPLIANCE_AWARD_S then
        local msg = Activity4_pb.ActiveComplianceAwardRep()
        msg:ParseFromString(msgBuff)
        serverData = msg
        self:refreshAll(container)
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.onReceivePlayerAward(msgBuff)
    end
end

--
function LivenessPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function LivenessPage:initScrollView(container)
    container.mScrollView = container:getVarScrollView("mContent")
    if container.mScrollView == nil or container.mScrollViewRootNode then return end
    container.mScrollViewRootNode = container.mScrollView:getContainer()
    container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
    container.m_pScrollViewFacade:init(0, 0)

    container.mScrollView:removeAllCell()
    for i = 1, #configData do
        local cell = CCBFileCell:create()
        local panel = LivenessPageItem:new( { id = i, ccbiFile = cell, mState = 0, rewardData = nil })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(LivenessPageItem.ccbiFile)
        container.mScrollView:addCellBack(cell)
        mItemList[i] = panel
    end
    container.mScrollView:orderCCBFileCells()
    container.mScrollView:setTouchEnabled(false)
end

function LivenessPage:sendLoginSignedInfoReqMessage()
    local msg = Activity4_pb.ActiveComplianceInfoReq()
    common:sendPacket(opcodes.ACTIVECOMPLIANCE_INFO_C, msg, false)
end

local CommonPage = require("CommonPage")
Activity_LivenessPage = CommonPage.newSub(LivenessPage, thisPageName, option)

return LivenessPage