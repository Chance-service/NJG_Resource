local HP_pb = require("HP_pb")
local StarSoul_pb = require("StarSoul_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserItemManager = require("Item.UserItemManager")
local LeaderDataMgr = require("Leader.LeaderDataMgr")
local thisPageName = "LeaderSubPage_HolyGrail"
local holyGrailCfg = ConfigManager.getStarSoulCfg() -- 聖所表格
local holyGrailTable = { }
local attrCfg = ConfigManager.getAttrPureCfg() -- 判斷屬性是顯示數值還是百分比
local nextStarId = nil  -- 下一個等級
local nowStageId = nil  -- 當前階段
local btnCCBs = { }
local mainContainer = nil
local curItemEnough = true
local isPlayAni = false
local isMaxLevel = false
local isPlayCloseAni = false
local _AnimationCCB = nil
local isInit = true
local parentPage = nil
local effectSpineParent = nil    -- 特效spine父節點
local effectSpine = nil  -- 特效spine

local opcodes = {
    SYNC_STAR_SOUL_S = HP_pb.SYNC_STAR_SOUL_S,
    -- 返回星魂訊息
    ACTIVE_STAR_SOUL_S = HP_pb.ACTIVE_STAR_SOUL_S -- 啟動星魂返回訊息
}

local option = {
    ccbiFile = "SoulStarPage_HolyGrail.ccbi",
    handlerMap =
    {
        onReturnBtn = "onReturn",
        onImmediatelyDekaron = "onImmediatelyDekaron",
        onHelp="onHelp",
    },
    opcode = opcodes
}

local HolyGrailPageBase = { }
local itemContainerTable = { }
-- 聖所屬性
local HolyGrailAttr = {
    Const_pb.HP, Const_pb.ATTACK_attr, Const_pb.PHYDEF,
    Const_pb.BUFF_PHYDEF_PENETRATE, Const_pb.BUFF_RETURN_BLOOD, Const_pb.BUFF_CRITICAL_DAMAGE
}
-----------------------------------
-- Item
local btnState = {
    CLEAR = 1, -- 已完成
    NOW = 2, -- 進行中
    NON_OPEN = 3, -- 未開放
}

local HolyGrailPageItem = {
    ccbiFile = "SoulStarBtn1_HolyGrail.ccbi",
}
function HolyGrailPageItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function HolyGrailPageItem:refreshBar(container)
    local barNode = container:getVarNode("mRoundNode")
    self.bar = barNode:getChildByTag(111)
    if self.bar then
        local per = 0
        if isMaxLevel then
            per = 1
        elseif nextStarId and nowStageId then
            per = ((nextStarId - 1) - (holyGrailTable[nowStageId][1].id - 1)) / (holyGrailTable[nowStageId][#holyGrailTable[nowStageId]].id - (holyGrailTable[nowStageId][1].id - 1))
        end
        self.bar:setPercentage(per * 100)
    else
        local bg = CCSprite:create("HolyGrail_img_3.png")
        self.bar = CCProgressTimer:create(bg)
        barNode:addChild(self.bar)
        self.bar:setPosition(ccp(0, 0))
        self.bar:setType(kCCProgressTimerTypeRadial)
        self.bar:setMidpoint(ccp(0.5, 0.5))
        self.bar:setPercentage(0)
        self.bar:setTag(111)
    end
end

function HolyGrailPageItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    itemContainerTable = itemContainerTable or { }
    itemContainerTable[self.container] = self.id
    self:refresh(self.container)
end

function HolyGrailPageItem:setState(state)
    self.mState = state
end

function HolyGrailPageItem:getStage()
    return self.mState
end

function HolyGrailPageItem:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function HolyGrailPageItem:refresh(container)
    if container == nil then
        return
    end
    self:refreshBar(container)
    for i = 1, 3 do
        NodeHelper:setNodesVisible(container, { ["mStateIcon" .. i] = i == self.mState })
    end
    NodeHelper:setNodesVisible(container, { ["mStateArrow1"] = ((self.mState == btnState.CLEAR) and not self.isEnd),
                                            ["mStateArrow2"] = ((self.mState == btnState.NON_OPEN or self.mState == btnState.NOW) and not self.isEnd),
                                            ["mRoundNode"] = (self.mState == btnState.NOW) })
end

function HolyGrailPageItem:onClick(container)

end

function HolyGrailPageBase:onEnter(container)
    self.container = container
    isInit = true
    isPlayCloseAni = false
    mainContainer = container
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    HolyGrailPageBase:sendSyncStarSoul()


    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    self:initPageCfg(container)
    self:initScrollView(container)
    self:initAttrWindow(container)
    self:initSpine(container)
    self.subPageCfg = LeaderDataMgr:getSubPageCfg(self.subPageName)
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    --if self.subPageCfg.saveData and self.subPageCfg.saveData[1] then
    --    self:onRefreshPage(self.container, self.subPageCfg.saveData[1])
    --else
        self:onRefreshPage(self.container, 0)
    --end
    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["HolyGrailPage"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function HolyGrailPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_HOLYGRILL)
end

function HolyGrailPageBase:onExecute(container)

end
-- 建立升級特效spine
function HolyGrailPageBase:initSpine(container)
    effectSpine = SpineContainer:create("Spine/NGUI", "NGUI_78_HolyGrail")
    local spineNode = tolua.cast(effectSpine, "CCNode")
    spineNode:setScale(NodeHelper:getScaleProportion())
    effectSpineParent = container:getVarNode("mAnimationNode")
    effectSpineParent:removeAllChildrenWithCleanup(true)
    effectSpineParent:addChild(spineNode)
end
-- ScrollView初始化
function HolyGrailPageBase:initScrollView(container)
    container.mScrollView = container:getVarScrollView("mContent")

    if container.mScrollView == nil then return end
    container.mScrollView:setVisible(false)
    container.m_pScrollViewFacade = CCReViScrollViewFacade:new_local(container.mScrollView)
    container.m_pScrollViewFacade:init(5, 3)

    container.mScrollView:removeAllCell()
    for i = 1, #holyGrailTable do
        local cell = CCBFileCell:create()
        local panel = HolyGrailPageItem:new({ id = i, ccbiFile = cell, mState = btnState.NON_OPEN, isEnd = (i == #holyGrailTable), cfg = holyGrailTable[i] })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(HolyGrailPageItem.ccbiFile)
        container.mScrollView:addCellBack(cell)
        btnCCBs[i] = panel
    end
     
    container.mScrollView:orderCCBFileCells()
    container.mScrollView:setContentOffset(ccp(0, 0))
end
-- 屬性視窗初始化
function HolyGrailPageBase:initAttrWindow(container)
    NodeHelper:setStringForTTFLabel(container, { mLevelTxt = "" })
    for i = 1, #HolyGrailAttr do
        --if HolyGrailAttr[i] == 113 then
        --    NodeHelper:setStringForTTFLabel(container, { ["mAttrTxt" .. i] = common:getLanguageString("@Damage") })
        --elseif HolyGrailAttr[i] == 106 then
        --    NodeHelper:setStringForTTFLabel(container, { ["mAttrTxt" .. i] = common:getLanguageString("@Armor") })
        --elseif HolyGrailAttr[i] == 2103 then
        --    NodeHelper:setStringForTTFLabel(container, { ["mAttrTxt" .. i] = common:getLanguageString("@AttrName_1007") })
        --else
            NodeHelper:setStringForTTFLabel(container, { ["mAttrTxt" .. i] = common:getLanguageString("@AttrName_" .. HolyGrailAttr[i]) })
        --end
        NodeHelper:setStringForTTFLabel(container, { ["mAttrNum" .. i] = "" })
        NodeHelper:setStringForTTFLabel(container, { ["mAttrPlus" .. i] = "" })
        NodeHelper:setSpriteImage(container, { ["mAttrIcon" .. i] = "ability_".. HolyGrailAttr[i] .. ".png" })
    end
end
-- 計算聖所累計屬性
function HolyGrailPageBase:calAttrWindow(id)
    local totalAttrTable = { }
    local addAttrTable = { }

    local data = holyGrailCfg[id]
    local dataAdd = holyGrailCfg[nextStarId]
    if data then
        for attr = 1, #data["attrs"] do
            local attrInfo = common:split(data["attrs"][attr], "_")
            local num = tonumber(attrInfo[2])
            table.insert(totalAttrTable, tonumber(attrInfo[1]), num)
        end
    end
    if dataAdd then
        for attr = 1, #dataAdd["attrs"] do
            local attrInfo = common:split(dataAdd["attrs"][attr], "_")
            local num = tonumber(attrInfo[2]) - (totalAttrTable[tonumber(attrInfo[1])] or 0)
            table.insert(addAttrTable, tonumber(attrInfo[1]), num)
        end
    end
    
    return totalAttrTable, addAttrTable
end
-- 顯示刷新
function HolyGrailPageBase:onRefreshPage(container, id, isActive)
    local cfg = holyGrailCfg[id]
    local lb2StrStuff = { }
    local lb2StrColor = { }
    local hasCount1 = UserItemManager:getCountByItemId(cfg.costItems[1].itemId)
    local hasCount2 = UserInfo.playerInfo.gold
    lb2StrStuff["mGold"] = hasCount1
    lb2StrStuff["mReo"] = GameUtil:formatDotNumber(hasCount2)
    
    curItemEnough = true
    isMaxLevel = (holyGrailCfg[id] and not holyGrailCfg[id + 1]) and true or false
    nextStarId = id + 1
    if isMaxLevel then
        nowStageId = holyGrailCfg[id].starType + 1
    else
        nowStageId = holyGrailCfg[nextStarId].starType
    end
    local totalAttrTable, addAttrTable = self:calAttrWindow(id)
    NodeHelper:setMenuItemEnabled(container, "mMidBtn", not isMaxLevel)
    
    NodeHelper:setStringForTTFLabel(container, { mLevelTxt = (common:getLanguageString("@ReinLevel") .. id) })
    -- ScrollView
    if isInit then
        container.mScrollView:locateToByIndex(math.min(nowStageId, #holyGrailTable - 1))
        isInit = false
    end
    container.mScrollView:setVisible(true)
    for k, v in pairs(btnCCBs) do
        v:setState((nowStageId > k and btnState.CLEAR) or 
                   (nowStageId == k and btnState.NOW) or
                   (btnState.NON_OPEN))
    end
    for k, v in pairs(itemContainerTable) do
        btnCCBs[v]:refresh(k)
    end
    -- 屬性視窗
    for i = 1, #HolyGrailAttr do
        local attr = HolyGrailAttr[i]
        local total = totalAttrTable[attr]
        local add = addAttrTable[attr]
        if attrCfg[attr] and tonumber(attrCfg[attr]["attrType"]) == 1 then
            NodeHelper:setStringForTTFLabel(container, { ["mAttrNum" .. i] = string.format("%.1f", (total or 0)) .. "%" })
            NodeHelper:setStringForTTFLabel(container, { ["mAttrPlus" .. i] = "(+" .. string.format("%.1f", (add or 0)) .. "%)" })
        else
            NodeHelper:setStringForTTFLabel(container, { ["mAttrNum" .. i] = (total or 0) })
            NodeHelper:setStringForTTFLabel(container, { ["mAttrPlus" .. i] = "(+" .. (add or 0) .. ")" })
        end
        if container:getVarLabelTTF("mAttrPlus" .. i) then
            local width = container:getVarLabelTTF("mAttrPlus" .. i):getTexture():getContentSize().width
            container:getVarLabelTTF("mAttrNum" .. i):setPositionX(293 - width)
        end
    end
    -- 消耗
    local cost = isMaxLevel and 0 or holyGrailCfg[nextStarId].costItems[1].count
    local hasCount = 0
    if isMaxLevel then
        hasCount = UserItemManager:getCountByItemId(holyGrailCfg[id].costItems[1].itemId)
    elseif holyGrailCfg[nextStarId].costItems[1].type == 30000 then
        hasCount = UserItemManager:getCountByItemId(holyGrailCfg[nextStarId].costItems[1].itemId)
    end
    if isMaxLevel then
        lb2StrStuff["mCostTxt"] = hasCount .. "/" .. "-"
    else
        lb2StrStuff["mCostTxt"] = hasCount .. "/" .. cost
    end
    if hasCount < cost then
        lb2StrColor["mCostTxt"] = "255 0 23"
        curItemEnough = false
    else
        lb2StrColor["mCostTxt"] = "127 108 102"
        curItemEnough = true
    end
    NodeHelper:setStringForLabel(container, lb2StrStuff)
    NodeHelper:setColorForLabel(container, lb2StrColor)

    -- 紅點
    parentPage:registerMessage(MSG_REFRESH_REDPOINT)
    self:refreshAllPoint(container)
end

function HolyGrailPageBase:initPageCfg(container)
    holyGrailTable = { }
    for k, v in pairs(holyGrailCfg) do
        if v.id ~= 0 then
            holyGrailTable[v.starType] = holyGrailTable[v.starType] or { }
            table.insert(holyGrailTable[v.starType], v)
        end
    end
end

function AnimationFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        local animationName = tostring(container:getCurAnimationDoneName())
        if animationName == "SoulStarLevelUpAni" then
            NodeHelper:setNodesVisible(container, { mAnimationNode = false })
            isPlayAni = false
        end
    end
end

function HolyGrailPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function HolyGrailPageBase:createPage(_parentPage)
    
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

-- Server回傳
function HolyGrailPageBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    
    if opcode == HP_pb.SYNC_STAR_SOUL_S then
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id)

        --self.subPageCfg.saveData = self.subPageCfg.saveData or { }
        --self.subPageCfg.saveData[1] = id
        return
    elseif opcode == HP_pb.ACTIVE_STAR_SOUL_S then
        effectSpine:runAnimation(1, "animation", 0)
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(self.container, id, true)

        --self.subPageCfg.saveData = self.subPageCfg.saveData or { }
        --self.subPageCfg.saveData[1] = id

        require("Util.RedPointManager")
        local pageId = RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN
        RedPointManager_refreshPageShowPoint(pageId, 1, id)
        return
    end
end

function HolyGrailPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HolyGrailPageBase:removePacket(container)
   parentPage:removePacket(opcodes)
end

-- 請求同步
function HolyGrailPageBase:sendSyncStarSoul()
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.SyncStarSoul()
    msg.group = 1
    common:sendPacket(HP_pb.SYNC_STAR_SOUL_C, msg, false)
end

-- 升級聖所
function HolyGrailPageBase:sendActiveStarSoul(id)
    if not curItemEnough then
        local str = Language:getInstance():getString("@SoulNotEnoughTxt")
        MessageBoxPage:Msg_Box(str)
        return
    end
    -- 正在播放動畫
    --if isPlayAni then
    --    return
    --end
    --isPlayAni = true
    NodeHelper:setMenuItemEnabled(mainContainer, "mMidBtn", false)
    
    local HP_pb = require("HP_pb")
    local msg = StarSoul_pb.ActiveStarSoul()
    msg.id = id
    common:sendPacket(HP_pb.ACTIVE_STAR_SOUL_C, msg, false)
end

function HolyGrailPageBase:onImmediatelyDekaron(container)--Train按鈕
    self:sendActiveStarSoul(nextStarId)
end

function HolyGrailPageBase:onReturn(container)
    PageManager.setAllNotice()
    PageManager.popPage(thisPageName)
end

function HolyGrailPageBase:onExit(container)
    self:removePacket(container)
    btnCCBs = { }
    itemContainerTable = { }
    mainContainer = nil
end

function HolyGrailPageBase:refreshAllPoint(container)
    require("Util.RedPointManager")
    NodeHelper:setNodesVisible(container, { mRedPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.GRAIL_HOLY_BTN, 1) })
end

function HolyGrailPageBase:onReceiveMessage(message)
    local typeId = message:getTypeId()

    if typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(mainContainer)
    end
end

function HolyGrailPageBase_calIsShowRedPoint(id)
    if not id then
        return false
    end
    local cfg = holyGrailCfg[id]

    local curItemEnough = true
    local nextStarId = id + 1
    if not holyGrailCfg[nextStarId] then
        return false
    end
    -- 消耗
    local cost = holyGrailCfg[nextStarId].costItems[1].count
    local hasCount = 0
    if holyGrailCfg[nextStarId].costItems[1].type == 30000 then
        hasCount = UserItemManager:getCountByItemId(holyGrailCfg[nextStarId].costItems[1].itemId)
    end
    if hasCount < cost then
        curItemEnough = false
    else
        curItemEnough = true
    end
    return curItemEnough
end

return HolyGrailPageBase
