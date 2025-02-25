--[[
  	 套装图鉴
]]

local HP_pb = require("HP_pb") -- 包含协议id文件
local EquipManager = require("Equip.EquipManager")
local SuitShowManage = require("Battle.MultiEliteSuitShowManage")
local thisPageName = "SuitDisplayPage"
local m_BegainX = 0
local m_EndX = 0
local totalSize = 0
local fOneItemWidth = 0
local fScrollViewWidth = 0
local m_currentIndex = 1
local mIsShowSpecialWeapon = true  -- 是否显示专用武器
-- 是不是显示所有的品质  如果没指定最大品质的话，从最低品质到最高品质都能看到
-- 默认都能看到
local mIsShowAllQuality = true
local maxPage = 4 -- 大页数
local svMaxHeight = 600
local svMinHeight = 300

local mScrollViewRef = { }
local mContainerRef = { }
local suitCfg = ConfigManager.getSuitCfg() -- 套装配表
local isMercenaryEquip = false -- 当前是否是佣兵专属装备
local mercenaryEquips = { } -- 按等级和品级标示的 "k"..tostring(level)..tostring(quality)
local curMercenaryEquips = { } -- 当前选择的佣兵装备页
local isRefreshItemView = false

local isOpenMercenary = false -- 是否跳转到佣兵专属装备
local openMercenaryLevel = 0
local openMercenaryQuality = 0
local refreshItemContainer = { } -- 滚动层container
----这里是协议的id
local opcodes = {
    EQUIP_RESONANCE_INFO_C = HP_pb.EQUIP_RESONANCE_INFO_C,
    HEAD_FRAME_STATE_INFO_S = HP_pb.HEAD_FRAME_STATE_INFO_S
}

local option = {
    ccbiFile = "SuitIllustratedPopUp.ccbi",
    handlerMap =
    {
        -- 按钮点击事件
        onClose = "onClose",
        onRole1 = "OnRole",
        -- 按钮点击事件
        onRole2 = "OnRole",
        onRole3 = "OnRole",
        onHelp = "onHelp",
        onArrowLeft = "onArrowLeft",
        onArrowRight = "onArrowRight",
        onSpecialEquip = "onSpecialEquip"
    },
    opcode = opcodes,
    cacheData = { }
}


local imageData = {
    QualityImage = { [1] = "Activity_common_R.png", [2] = "Activity_common_SR.png", [3] = "Activity_common_SSR.png", [4] = "Activity_common_UR.png" },
    RoleImage = { [1] = "UI/Common/Activity/Act_RoleImage/Activity_common_wujiang.png", [2] = "UI/Common/Activity/Act_RoleImage/Activity_common_gongshou.png", [3] = "UI/Common/Activity/Act_RoleImage/Activity_common_ceshi.png" }
}



local curSelcetBtnIndex = 1 -- 当前选中的按钮
local SuitDisplayPageBase = { }
-- 等级
--[[
显示顺序
55_R -> 55_SR -> 55_SSR -> 70_R -> 70_SR -> 70_SSR -> 85_R -> 85_SR -> 85_SSR
	 -> 100_R -> 100_SR -> 100_SSR -> 100_UR
]]

local mConstLevelTable = {
    [1] = { level = 55, quality = 3, },
    [2] = { level = 70, quality = 3, },
    [3] = { level = 85, quality = 3, },
    [4] = { level = 100, quality = 4, },
}

local LevelTable = {
    --    [1] = { level = 55, quality = 3, },
    --    [2] = { level = 70, quality = 3, },
    --    [3] = { level = 85, quality = 3, },
    --    [4] = { level = 100, quality = 4, },
}
-- 战士套装
local WarriorSuits = {
    -- [1] = EquipManager:getWarriorSuit(1),
    -- [2] = EquipManager:getWarriorSuit(2),
    -- [3] = EquipManager:getWarriorSuit(3),
    -- [4] = EquipManager:getWarriorSuit(4)
}

-- 猎人套装
local HunterSuits = {
    --    [1] = EquipManager:getHunterSuit(1),
    --    [2] = EquipManager:getHunterSuit(2),
    --    [3] = EquipManager:getHunterSuit(3),
    --    [4] = EquipManager:getHunterSuit(4)
}
-- 法师套装
local MasterSuits = {
    --    [1] = EquipManager:getMasterSuit(1),
    --    [2] = EquipManager:getMasterSuit(2),
    --    [3] = EquipManager:getMasterSuit(3),
    --    [4] = EquipManager:getMasterSuit(4)
}

function getSuitsInfo(prof)
    local suitsTable = { }
    for k, v in ipairs(LevelTable) do
        local level = v.level
        local quality = v.quality
        if mIsShowAllQuality then
            for i = 1, quality do
                local info, isHasMercenaryEquip, mercenarySuit = EquipManager:getSuit(prof, i, level)
                if #info > 0 then
                    suitsTable[#suitsTable + 1] = info
                    if isHasMercenaryEquip then
                        suitsTable[#suitsTable].isHasMercenaryEquip = true
                        mercenaryEquips["k" .. tostring(level) .. tostring(i)] = mercenarySuit
                    end
                end
            end
        else
            local info, isHasMercenaryEquip, mercenarySuit = EquipManager:getSuit(prof, quality, level)
            if #info > 0 then
                suitsTable[#suitsTable + 1] = info
                if isHasMercenaryEquip then
                    suitsTable[#suitsTable].isHasMercenaryEquip = true
                    mercenaryEquips["k" .. tostring(level) .. tostring(quality)] = mercenarySuit
                end
            end
        end
    end
    return suitsTable
end

local suitDatas = {
    --    [1] = getSuitsInfo(1),
    --    -- 战士套装
    --    [2] = getSuitsInfo(2),
    --    -- 猎人套装
    --    [3] = getSuitsInfo(3)-- 法师套装
}


function SuitDisplayPageBase:onEnter(container)

    self:initData()

    self.roleImage = container:getVarSprite("mRolePic")

    self:registerPacket(container)
    SuitDisplayPageBase.PanelTable = { }
    SuitDisplayPageBase.container = container
    container.scrollview = container:getVarScrollView("mContent")
    container.scrollview:registerScriptHandler(self, CCScrollView.kScrollViewScrollEnd)
    mScrollViewRef = container.scrollview
    mContainerRef = container
    container.scrollview:setTouchEnabled(true)
    container.scrollview:setBounceable(false)
    --- 佣兵专属
    NodeHelper:initScrollView(container, "mMercenaryContent", 4);
    container.scrollview2 = container:getVarScrollView("mMercenaryContent");
    -- if container.scrollview2 ~= nil then
    --     container:autoAdjustResizeScrollview(container.scrollview2);
    -- end

    SuitDisplayPageBase.showIsMercenaryEquip(container, isMercenaryEquip)
    curSelcetBtnIndex = 1
    -- m_currentIndex = 1

    local selectMap = { }
    selectMap["mRole" .. curSelcetBtnIndex] = true
    NodeHelper:setMenuItemSelected(container, selectMap)
    -- NodeHelper:setMenuItemEnabled( container, "mRole"..curSelcetBtnIndex, false )
    option.cacheData = { }

    isRefreshItemView = false
    if not isOpenMercenary then
        isMercenaryEquip = false
        -- m_currentIndex = 1
    else
        isMercenaryEquip = true
        self:goMercenaryEquip(container, openMercenaryLevel, openMercenaryQuality)
    end


    self:rebuildAllItem(container);
    self:refreshPage(container);
end


function SuitDisplayPageBase:initData()
    if #LevelTable == 0 then
        LevelTable = mConstLevelTable
    end
    suitDatas = {
        [1] = getSuitsInfo(1),
        -- 战士套装
        [2] = getSuitsInfo(2),
        -- 猎人套装
        [3] = getSuitsInfo(3)-- 法师套装
    }
end


function SuitDisplayPageBase.showIsMercenaryEquip(container, _isMercenaryEquip)
    NodeHelper:setNodesVisible(container, {
        mContent = not _isMercenaryEquip,
        mMercenaryContent = _isMercenaryEquip,
        mArrowLeft = not _isMercenaryEquip,
        mArrowRight = not _isMercenaryEquip,
        mSuitBGNode = not _isMercenaryEquip,
        mMBGNode = _isMercenaryEquip,
        mSuit9SNode = not _isMercenaryEquip,
        mM9SNode = _isMercenaryEquip
    } )

    -- NodeHelper:setNodesVisible(container, { mArrowLeft = mIsShowAllQuality, mArrowRight = mIsShowAllQuality })
    if not _isMercenaryEquip and not mIsShowAllQuality then
        NodeHelper:setNodesVisible(container, { mArrowLeft = false, mArrowRight = false })
    end

    if _isMercenaryEquip then
        NodeHelper:setStringForLabel(container, { mConfirmation = common:getLanguageString("@SuitSpecialEquipBtnTxt2") })
    else
        NodeHelper:setStringForLabel(container, { mConfirmation = common:getLanguageString("@SuitSpecialEquipBtnTxt1") })
    end
end

function SuitDisplayPageBase:OnRole(container, eventName)
    if isMercenaryEquip then
        -- isMercenaryEquip = false
        self:onSpecialEquip(container)
        -- local selectMap = {}
        -- selectMap["mRole"..curSelcetBtnIndex ] = true
        -- NodeHelper:setMenuItemSelected(container,selectMap)
        -- return
    end

    option.cacheData = { }
    local selectMap = { }
    selectMap["mRole" .. curSelcetBtnIndex] = false
    NodeHelper:setMenuItemSelected(container, selectMap)
    -- NodeHelper:setMenuItemEnabled( container, "mRole"..curSelcetBtnIndex, true )
    curSelcetBtnIndex = tonumber(string.sub(eventName, -1, -1))
    selectMap["mRole" .. curSelcetBtnIndex] = true
    NodeHelper:setMenuItemSelected(container, selectMap)
    -- NodeHelper:setMenuItemEnabled( container, "mRole"..curSelcetBtnIndex, false )
    -- m_currentIndex = 1
    self:rebuildAllItem(container);
    self:refreshPage(container);
end

function SuitDisplayPageBase:scrollViewDidDeaccelerateStop(scrollview)
    if scrollview then
        scrollview:getContainer():stopAllActions()
        local mContentWidth = SuitDisplayPageBase.PanelTable[1].cell:getContentSize().width
        local currentOffset = scrollview:getContentOffset().x
        local initSpeed = scrollview:getScrollDistanceInit()
        if initSpeed.x < 0 and m_currentIndex < #SuitDisplayPageBase.PanelTable then
            m_currentIndex = m_currentIndex + 1
        elseif initSpeed.x > 0 and m_currentIndex > 1 then
            m_currentIndex = m_currentIndex - 1
        end
        CCLuaLog("##m_currentIndex = " .. tostring(m_currentIndex))
        SuitDisplayPageBase.PanelTable[m_currentIndex].cell:locateTo(CCBFileCell.LT_Bottom, 0, 0.2)
        SuitDisplayPageBase:refreshPage(SuitDisplayPageBase.container)
    end
end

function SuitDisplayPageBase:MoveToIndex(index)
    m_currentIndex = index
    if SuitDisplayPageBase.PanelTable[m_currentIndex] then
        SuitDisplayPageBase.container.scrollview:getContainer():stopAllActions()
        SuitDisplayPageBase.PanelTable[m_currentIndex].cell:locateTo(CCBFileCell.LT_Bottom, 0, 0.2)
        SuitDisplayPageBase:refreshPage(SuitDisplayPageBase.container)
    end
end

function SuitDisplayPageBase:MoveToLeft()
    newIndex = m_currentIndex - 1
    newIndex = math.max(newIndex, 1)
    newIndex = math.min(newIndex, totalSize)
    SuitDisplayPageBase:MoveToIndex(newIndex)
end

function SuitDisplayPageBase:MoveToRight()
    newIndex = m_currentIndex + 1
    newIndex = math.max(newIndex, 1)
    newIndex = math.min(newIndex, totalSize)
    SuitDisplayPageBase:MoveToIndex(newIndex)
end

function SuitDisplayPageBase:onArrowLeft(container)
    self:MoveToLeft()
end

function SuitDisplayPageBase:onArrowRight(container)
    self:MoveToRight()
end

function SuitDisplayPageBase:onClose(container)
    PageManager.popPage(thisPageName)
    m_currentIndex = 1
end

function SuitDisplayPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
        local msg = HeadFrame_pb.HPHeadFrameStateRet()
        msg:ParseFromString(msgBuff)
        protoDatas = msg

        -- self:rebuildItem(container)
        return
    end
end

function SuitDisplayPageBase:onReceiveMessage(container)
    local message = container:getMessage();
    local typeId = message:getTypeId();
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode;

        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then

        end
    end
end

function SuitDisplayPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function SuitDisplayPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode);
        end
    end
end 

----------------scrollview-------------------------
function SuitDisplayPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:createContentItem(container)
end

function SuitDisplayPageBase:clearAllItem(container)
    local scrollview = container.scrollview
    scrollview:removeAllCell()
end
local SuitDisplayItem = { }
function SuitDisplayItem:onFrame(container, frameId)
    local index = self.id
    local equipId = suitDatas[curSelcetBtnIndex][index][frameId]["equipId"]
    SuitShowManage.EquipId = tonumber(equipId)
    PageManager.pushPage("MultiEliteSuitShowDetailPage")
end

function SuitDisplayItem:onFrame1(content)
    self:onFrame(container, 1)
end
function SuitDisplayItem:onFrame2(content)
    self:onFrame(container, 2)
end
function SuitDisplayItem:onFrame3(content)
    self:onFrame(container, 3)
end
function SuitDisplayItem:onFrame4(content)
    self:onFrame(container, 4)
end
function SuitDisplayItem:onFrame5(content)
    self:onFrame(container, 5)
end
function SuitDisplayItem:onFrame6(content)
    self:onFrame(container, 6)
end
function SuitDisplayItem:onFrame7(content)
    self:onFrame(container, 7)
end
function SuitDisplayItem:onFrame8(content)
    self:onFrame(container, 8)
end
function SuitDisplayItem:onFrame9(content)
    self:onFrame(container, 9)
end
function SuitDisplayItem:onFrame10(content)
    self:onFrame(container, 10)
end
function SuitDisplayItem:onRefreshContent(content)
    local pageId = self.id
    local container = content:getCCBFileNode()
    for i = 1, 10 do
        local pageInfo = suitDatas[curSelcetBtnIndex][pageId][i]
        -- 每页显示的装备信息
        if pageInfo then
            local data = EquipManager:getEquipCfgById(pageInfo["equipId"])
            NodeHelper:setSpriteImage(container, { ["mPic" .. i] = data.icon })
            NodeHelper:setQualityFrames(container, { ["mFrame" .. i] = data.quality })
            -- NodeHelper:setSpriteImage(container, {["mFrameShade"..i] = NodeHelper:getImageBgByQuality(data.quality)})
            NodeHelper:setNodeVisible(container:getVarNode("mRewardNode" .. i), true)
        else
            NodeHelper:setNodeVisible(container:getVarNode("mRewardNode" .. i), false)
        end
    end
end

function SuitDisplayPageBase:createContentItem(container)
    local scrollview = container.scrollview
    local ccbiFile = "SuitIllustatedContent.ccbi"
    -- maxPage = #suitDatas[m_currentIndex]curSelcetBtnIndex
    maxPage = #suitDatas[curSelcetBtnIndex]
    totalSize = maxPage

    if totalSize == 0 or ccbiFile == nil or ccbiFile == '' then return end
    SuitDisplayPageBase.PanelTable = { }
    for i = 1, totalSize do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local panel = common:new( { id = i }, SuitDisplayItem)
        cell:registerFunctionHandler(panel)

        scrollview:addCell(cell)
        local pos = ccp(cell:getContentSize().width *(i - 1), 0)
        cell:setPosition(pos)
        SuitDisplayPageBase.PanelTable[i] = panel
        panel.cell = cell
    end
    local size = CCSizeMake(cell:getContentSize().width * totalSize, cell:getContentSize().height)
    scrollview:setContentSize(size)
    if m_currentIndex and SuitDisplayPageBase.PanelTable[m_currentIndex] then
        SuitDisplayPageBase.PanelTable[m_currentIndex].cell:locateTo(CCBFileCell.LT_Bottom)
    else
        scrollview:setContentOffset(ccp(0, 0))
    end
    scrollview:forceRecaculateChildren()
end

function SuitDisplayPageBase:onExecute(container)

end

function SuitDisplayPageBase:onExit(container)
    mIsShowSpecialWeapon = true
    mIsShowAllQuality = true
    LevelTable = { }
    isOpenMercenary = false
    -- 是否跳转到佣兵专属装备
    isMercenaryEquip = false
    openMercenaryLevel = 0
    openMercenaryQuality = 0
    self:removePacket(container)
    self:clearAllItem(container)
    refreshItemContainer = { }
end

function SuitDisplayPageBase:refreshPage(container)


    self.roleImage:setTexture(imageData.RoleImage[curSelcetBtnIndex])
    self.roleImage:setScale(1)
    NodeHelper:setNodesVisible(container, {
        mLeftArrow = true,
        mRightArrow = true,
        mRolePic1 = curSelcetBtnIndex == 1,
        mRolePic2 = curSelcetBtnIndex == 2,
        mRolePic3 = curSelcetBtnIndex == 3,
    } )
    if m_currentIndex == 1 then
        NodeHelper:setNodesVisible(container, { mLeftArrow = false, mRightArrow = true })
    elseif m_currentIndex == maxPage then
        NodeHelper:setNodesVisible(container, { mLeftArrow = true, mRightArrow = false })
    end

    ----显示佣兵专属装备按钮
    if suitDatas[curSelcetBtnIndex][m_currentIndex].isHasMercenaryEquip then
        NodeHelper:setNodesVisible(container, { mSpecialEquipBtnNode = true })
    else
        NodeHelper:setNodesVisible(container, { mSpecialEquipBtnNode = false })
    end

    if not mIsShowSpecialWeapon then
        NodeHelper:setNodesVisible(container, { mSpecialEquipBtnNode = false })
    end

    local data = EquipManager:getEquipCfgById(suitDatas[curSelcetBtnIndex][m_currentIndex][1]["equipId"])
    local level = suitDatas[curSelcetBtnIndex][m_currentIndex][1]["level"]
    local quality = suitDatas[curSelcetBtnIndex][m_currentIndex][1]["suitQuality"]
    CCLuaLog("###refreshPage m_currentIndex = " .. tostring(m_currentIndex))
    CCLuaLog("###refreshPage quality = " .. tostring(quality))
    local suitId = data.suitId
    NodeHelper:setSpriteImage(container, { mRoleLevel = imageData.QualityImage[quality] })
    -- NodeHelper:setSpriteImage(container, {mRoleLevel = "UI/Common/Font/Font_Suit_"..tostring(quality)..".png"})
    NodeHelper:setStringForLabel(container, { mSuitName = suitCfg[suitId].suitName .. "(Lv." .. level .. ")" })

    if suitDatas[curSelcetBtnIndex][m_currentIndex].isHasMercenaryEquip then
        -- 有专属武器
    else
        -- 没有专属武器
    end
    -- TODO

    local equipData = suitDatas[curSelcetBtnIndex][m_currentIndex][1]
    if equipData then
        local strTb = { }
        local equipId = equipData.equipId
        local EquipCfg = EquipManager:getEquipCfgById(equipId)
        local suitId = EquipManager:getSuitIdById(equipId)
        if suitId > 0 then
            local quality = EquipManager:getQualityById(equipId)
            -- 名字
            local name = EquipManager:getNameById(equipId)
            local t = common:split(name, "−")
            if t then
                if t[1] then
                    local nameStr = common:getLanguageString("@LevelName", t[1]);
                    nameStr = common:fillHtmlStr("Quality_" .. quality, nameStr .. "(Lv." .. level .. ")")
                    table.insert(strTb, nameStr)
                end
            end

            table.insert(strTb, common:fillHtmlStr("EquipSuitAttrs"))
            local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
            local suitCfg = ConfigManager.getSuitCfg()
            for i = 1, #suitCfg[suitId].conditions, 1 do
                local suitAttrCfg = ConfigManager.getSuitAtrrCfg()
                local suitAttrId = suitCfg[suitId].attrIds[i]
                table.insert(strTb, common:fillHtmlStr("EquipSuitAttrsF", suitCfg[suitId].conditions[i], suitAttrCfg[suitAttrId].describe))
            end
        end

        local str = table.concat(strTb, '<br/>')
        local label = container:getVarNode("mSuitMessageText")
        if label then
            NodeHelper:addHtmlLable(label, str, GameConfig.Tag.HtmlLable, CCSizeMake(380, 30))
        end
    else
        NodeHelper:setNodesVisible(container, { mSuitMessageNode = false })
    end
end

-- 刷新套装属性
function SuitDisplayPageBase:refreshSuitMessage(container)

end

function SuitDisplayPageBase:onSpecialEquip(container)
    isMercenaryEquip = not isMercenaryEquip
    local data = EquipManager:getEquipCfgById(suitDatas[curSelcetBtnIndex][m_currentIndex][1]["equipId"])
    local level = suitDatas[curSelcetBtnIndex][m_currentIndex][1]["level"]
    local quality = suitDatas[curSelcetBtnIndex][m_currentIndex][1]["suitQuality"]

    self:goMercenaryEquip(container, level, quality)

    NodeHelper:setNodesVisible(container, { mSuitMessageNode = not isMercenaryEquip })

end

local maxOffsize = 0
function SuitDisplayPageBase:goMercenaryEquip(container, level, quality)
    NodeHelper:setNodesVisible(container, { mSuitMessageNode = not isMercenaryEquip })

    SuitDisplayPageBase.showIsMercenaryEquip(container, isMercenaryEquip)
    if isMercenaryEquip and isRefreshItemView then
        container.scrollview2:setContentOffset(ccp(0, maxOffsize.y))
        curMercenaryEquips = mercenaryEquips["k" .. tostring(level) .. tostring(quality)]
        for i = 1, #refreshItemContainer do
            SuitDisplayPageBase.onRefreshItemView(refreshItemContainer[i])
        end
    elseif isMercenaryEquip then
        curMercenaryEquips = mercenaryEquips["k" .. tostring(level) .. tostring(quality)]
        isRefreshItemView = true
        self:buildItem(container)
    end
    NodeHelper:setNodesVisible(container, { mSuitMessageNode = false })
end

local ITEM_COUNT_PER_LINE = 10
function SuitDisplayPageBase:buildItem(container)
    container.scrollview2:getContainer():removeAllChildren()
    --- 这里是清空滚动层
    CCLuaLog("###  curMercenaryEquips = " .. tostring(#curMercenaryEquips))
    size = math.ceil(#curMercenaryEquips / ITEM_COUNT_PER_LINE)
    NodeHelper:buildScrollView(container, size, "SuitIllustatedContent.ccbi", SuitDisplayPageBase.onFunctionx)
    maxOffsize = container.scrollview2:getContentOffset()
end

function SuitDisplayPageBase.onFunctionx(eventName, container)
    if eventName == "luaRefreshItemView" then
        --- 每个子空间创建的时候会调用这个函数
        -- refreshItemContainer = container
        refreshItemContainer[#refreshItemContainer + 1] = container
        SuitDisplayPageBase.onRefreshItemView(container);
    elseif string.sub(eventName, 1, 7) == "onFrame" then
        -- 点击每个子空间的时候会调用函数
        local index = string.sub(eventName, -1, -1)
        index = tonumber(index)
        if index == 0 then
            index = tonumber(string.sub(eventName, 8, 9))
        end
        local contentId = container:getItemDate().mID;
        local baseIndex =(contentId - 1) * ITEM_COUNT_PER_LINE;
        index = index + baseIndex

        local equipId = curMercenaryEquips[index]["equipId"]
        -- PageManager.showEquipInfo(userEquipId);
        -- local SuitShowManage = require("Battle.MultiEliteSuitShowManage")
        SuitShowManage.EquipId = tonumber(equipId)
        PageManager.pushPage("MultiEliteSuitShowDetailPage")
    end
end

function SuitDisplayPageBase.onRefreshItemView(container)
    local NodeHelper = require("NodeHelper");
    local contentId = container:getItemDate().mID;
    -- 获取到时第几行
    local baseIndex =(contentId - 1) * ITEM_COUNT_PER_LINE;
    --

    for i = 1, ITEM_COUNT_PER_LINE do
        local pageInfo = curMercenaryEquips[baseIndex + i]
        -- 每页显示的装备信息
        if pageInfo then
            local data = EquipManager:getEquipCfgById(pageInfo["equipId"])
            NodeHelper:setSpriteImage(container, { ["mPic" .. i] = data.icon })
            NodeHelper:setQualityFrames(container, { ["mFrame" .. i] = data.quality })
            NodeHelper:setNodeVisible(container:getVarNode("mRewardNode" .. i), true)
        else
            NodeHelper:setNodeVisible(container:getVarNode("mRewardNode" .. i), false)
        end
    end
end

-- 帮助页面
function SuitDisplayPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SUITHANDBOOK)
end

-- 传入想打开的分页的页数 佣兵专属
function SuitDisplayPageBase_setMercenaryEquip(currentIndex)
    isOpenMercenary = true
    m_currentIndex = currentIndex
    LevelTable = mConstLevelTable
    suitDatas = {
        [1] = getSuitsInfo(1),
        -- 战士套装
        [2] = getSuitsInfo(2),
        -- 猎人套装
        [3] = getSuitsInfo(3)-- 法师套装
    }
    openMercenaryLevel = suitDatas[1][m_currentIndex][1]["level"]
    openMercenaryQuality = suitDatas[1][m_currentIndex][1]["suitQuality"]
end

-- 传入想打开的分页的页数 人物装备图鉴
function SuitDisplayPageBase_setEquip(currentIndex)
    isOpenMercenary = false
    m_currentIndex = currentIndex
end

--[[
lv = 套装等级
quality = 品质
currentIndex = 从第几页开始显示
isShowSpecialWeapon = 是不是显示专属武器按钮
isShowAllQuality = 是不是显示左右箭头   如果只需要显示一个品质的套装时候 不需要显示左右箭头
--]]
function SuitDisplayPageBase_setEquipLv(lv, quality, currentIndex, isShowSpecialWeapon, isShowAllQuality)
    -- 是不是显示专属武器按钮
    mIsShowSpecialWeapon = isShowMultiple
    -- 是不是显示左右箭头
    mIsShowAllQuality = isShowAllQuality
    -- 需要显示的品质
    LevelTable = { }
    for i = 1, #mConstLevelTable do
        if mConstLevelTable[i].level == lv then
            table.insert(LevelTable, { level = lv, quality = quality })
            break
        end
    end
    SuitDisplayPageBase_setEquip(currentIndex)
    isOpenMercenary = false
end


local CommonPage = require('CommonPage')
SuitDisplayPageBase = CommonPage.newSub(SuitDisplayPageBase, thisPageName, option)