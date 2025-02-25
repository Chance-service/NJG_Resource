local HP_pb = require("HP_pb")
local StarSoul_pb = require("StarSoul_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserItemManager = require("Item.UserItemManager")
local thisPageName = "HolyGrailPage"
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
    },
    opcode = opcodes
}

local HolyGrailPageBase = { }
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
function HolyGrailPageBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function HolyGrailPageItem:refreshBar(container)
    if self.bar then
        local per = 0
        if nextStarId and nowStageId then
            per = ((nextStarId - 1) - (holyGrailTable[nowStageId][1].id - 1)) / (holyGrailTable[nowStageId][#holyGrailTable[nowStageId]].id - (holyGrailTable[nowStageId][1].id - 1))
        end
        self.bar:setPercentage(per * 100)
    else
        local bg = CCSprite:create("HolyGrail_img_3.png")
        local barNode = container:getVarNode("mRoundNode")
        self.bar = CCProgressTimer:create(bg)
        barNode:addChild(self.bar)
        self.bar:setPosition(ccp(0, 0))
        self.bar:setType(kCCProgressTimerTypeRadial)
        self.bar:setMidpoint(ccp(0.5, 0.5))
        self.bar:setPercentage(0)
    end
end

function HolyGrailPageItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
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
    isInit = true
    --isPlayAni = false
    isPlayCloseAni = false
    mainContainer = container
    self:registerPacket(container)
    HolyGrailPageBase:sendSyncStarSoul()


    local bg = container:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    self:initPageCfg(container)
    self:initScrollView(container)
    self:initAttrWindow(container)
    
    -- 增加升級動畫
    --local node = container:getVarNode("mAnimationNode")
    --NodeHelper:setNodesVisible(container, { mAnimationNode = false })
    --if node then
    --    _AnimationCCB = ScriptContentBase:create("eff_YangChengSuo_03.ccbi")
    --    if _AnimationCCB then
    --        node:addChild(_AnimationCCB)
    --        _AnimationCCB:registerFunctionHandler(AnimationFunction)
    --    end
    --end
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
    nextStarId = id + 1
    nowStageId = holyGrailCfg[nextStarId].starType
    local totalAttrTable, addAttrTable = self:calAttrWindow(id)
    NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
    --if isActive then
    --    if _AnimationCCB then
    --        NodeHelper:setNodesVisible(container, { mAnimationNode = true })
    --        _AnimationCCB:runAnimation("SoulStarLevelUpAni")
    --    end
    --end
    
    NodeHelper:setStringForTTFLabel(container, { mLevelTxt = (common:getLanguageString("@ReinLevel") .. id) })
    -- ScrollView
    if isInit then
        container.mScrollView:locateToByIndex(math.min(nowStageId, #holyGrailTable - 1))
        isInit = false
    end
    container.mScrollView:setVisible(true)
    for k, v in pairs(btnCCBs) do
        v:setState((holyGrailCfg[nextStarId].starType > k and btnState.CLEAR) or 
                   (holyGrailCfg[nextStarId].starType == k and btnState.NOW) or
                   (btnState.NON_OPEN))
        v:refresh(v.container)
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
        local width = container:getVarLabelTTF("mAttrPlus" .. i):getTexture():getContentSize().width
        container:getVarLabelTTF("mAttrNum" .. i):setPositionX(293 - width)
    end
    -- 消耗
    local cost = holyGrailCfg[nextStarId].costItems[1].count
    local hasCount = 0
    if holyGrailCfg[nextStarId].costItems[1].type == 30000 then
        hasCount = UserItemManager:getCountByItemId(holyGrailCfg[nextStarId].costItems[1].itemId)
    end
    lb2StrStuff["mCostTxt"] = hasCount .. "/" .. cost
    if hasCount < cost then
        lb2StrColor["mCostTxt"] = "255 0 23"
        curItemEnough = false
    else
        lb2StrColor["mCostTxt"] = "127 108 102"
        curItemEnough = true
    end
    NodeHelper:setStringForLabel(container, lb2StrStuff)
    NodeHelper:setColorForLabel(container, lb2StrColor)
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

function HolyGrailPageBase:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "SoulStarClose" then
        self:onClose(container)
    elseif animationName == "SoulStarOpen" then
        container:runAnimation("Stand")
    elseif animationName == "Activate" then
        container:runAnimation("Rotation")
    elseif animationName == "Rotation" then
        container:runAnimation("Stand")
        if isMaxLevel then
            -- 最大等级兼容动画做的处理
            NodeHelper:setNodesVisible(container, { mStandLightIcon = true, mLastRight = false, mMidGrey = true })
        else
            NodeHelper:setMenuItemEnabled(container, "mMidBtn", true)
        end
        NodeHelper:setNodesVisible(container, { mNew = true })
        isPlayAni = false
    elseif animationName == "ChangeStar" then
        container:runAnimation("Stand")
    end
end
-- Server回傳
function HolyGrailPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    if opcode == HP_pb.SYNC_STAR_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.SyncStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(container, id)
        return
    elseif opcode == HP_pb.ACTIVE_STAR_SOUL_S then
        isMaxLevel = false
        local msg = StarSoul_pb.ActiveStarSoulRet()
        msg:ParseFromString(msgBuff)
        local id = msg.id
        self:onRefreshPage(container, id, true)
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
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
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
    mainContainer = nil
end

return HolyGrailPageBase
