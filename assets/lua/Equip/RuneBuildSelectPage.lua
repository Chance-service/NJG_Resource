---- 符文合成選擇頁面
local FateDataManager = require("FateDataManager")
local runePage = require("RunePage")
local CommonPage = require('CommonPage')
local RuneBuildSelectPage = { }

local thisPageName = "RuneBuildSelectPage"
local option = {
    ccbiFile = "RuneBuildSelectPopUp2.ccbi",
    handlerMap = {
        onClose       = "ClosePage",
        onCancel      = "ClosePage",
        onConfirm     = "ConfirmSelection",
        onFilter      = "ToggleFilter",
        onReset       = "ResetFilters",
        onLock        = "LockRune"
    },
    opcodes = {},
}

-- 常數與內部狀態
local ROW_COUNT         = 2
local LINE_COUNT        = 5
local MAX_SELECT_NUM    = 5

-- 物品顯示模板
local RuneItemContent = {
    ccbiFile = "CommItem.ccbi"
}

-- 優化：將頁面內部狀態封裝到 state 表中，避免全局變量污染
local state = {
    pageContainer     = nil,
    nonWearRuneTable  = {},   -- 未穿戴符文資料
    nonWearRuneItems  = {},   -- scrollview 內的 cell 與 handler
    runeTouchLayers   = {},   -- 各 cell 內的觸控層
    selectState       = {},   -- 各符文的選中狀態（鍵為符文 id）
    nowSelectRank     = 0,
    nowSelectNum      = 0,
    nowClickId        = 0,
    lastNode          = {},
    BtnState          = {},   -- 過濾按鈕狀態
}

-- 對應屬性按鈕的 ID 映射表
local attrIdMapping = {
    [1] = 101,
    [2] = 106,
    [3] = 107,
    [4] = 111,
    [5] = 108,
    [6] = 109,
    [7] = 110,
}

-- 觸控相關數據
local TOUCH_DATA = {
    TOUCH_ID            = 0,
    TOUCH_TIMECOUNT     = 0,
    TOUCH_TIMEINTERVAL  = 1,   -- 觸控持續時間（秒）門檻
    TOUCH_MAX_TIMEINTERVAL = 5,
    IS_TOUCHING         = false,
    MOVE_X              = 0,
    MOVE_Y              = 0,
}

-- 註冊 Rare、Status、Attr 按鈕的 handler（事件名稱後綴必須為數字）
for i = 1, 5 do
    option.handlerMap["onRare" .. i] = "OnRareButton"
end
for i = 1, 2 do
    option.handlerMap["onStatus" .. i] = "OnStatusButton"
end
for i = 1, 7 do
    option.handlerMap["onAttr" .. i] = "OnAttrButton"
end

--------------------------------------------------
-- 幫助函數：合併基本屬性與隨機屬性（避免重複代碼）
--------------------------------------------------
local function combineAttributes(basicAttr, randAttr)
    local attrInfo = {}
    if basicAttr then
        for _, v in ipairs(common:split(basicAttr, ",")) do
            table.insert(attrInfo, v)
        end
    end
    if randAttr then
        for _, v in ipairs(common:split(randAttr, ",")) do
            if string.find(v, "_") then
                table.insert(attrInfo, v)
            end
        end
    end
    return attrInfo
end

--------------------------------------------------
-- 儲存與讀取過濾按鈕狀態（序列化到 UserDefault）
--------------------------------------------------
local function saveButtonStates(btnState)
    local serializedState = json.encode(btnState)
    CCUserDefault:sharedUserDefault():setStringForKey("RuneForgeBtnStateKey", serializedState)
    CCUserDefault:sharedUserDefault():flush()
end

local function loadButtonStates()
    local serializedState = CCUserDefault:sharedUserDefault():getStringForKey("RuneForgeBtnStateKey")
    if serializedState == "" then return {} end
    return json.decode(serializedState)
end

--------------------------------------------------
-- 以下為 RuneBuildSelectPage 的各成員函數（頁面生命週期及事件處理）
--------------------------------------------------

function RuneBuildSelectPage:onEnter(container)
    state.pageContainer = container
    self:InitializeData(container)
    self:InitializeUI(container)
    self:RefreshPage(container)
end

function RuneBuildSelectPage:ToggleFilter(container)
    local filterNode = container:getVarNode("mFilter")
    NodeHelper:setNodesVisible(container, { mFilter = not filterNode:isVisible() })
end

function RuneBuildSelectPage:ResetFilters(container)
    if next(state.BtnState) then
        for key, _ in pairs(state.BtnState) do
            state.BtnState[key] = false
            NodeHelper:setMenuItemImage(container, { ["m" .. key] = { normal = "RunePopup_RuneSelect_img4.png" } })
        end
        saveButtonStates(state.BtnState)
        self:SyncContent(container)
    end
end

function RuneBuildSelectPage:ToggleButtonState(container, eventName, btnType, btnPrefix)
    local index   = string.sub(eventName, -1)
    local btnKey  = btnType .. index
    local nodeName = btnPrefix .. index

    if state.BtnState[btnKey] then
        NodeHelper:setMenuItemImage(container, { [nodeName] = { normal = "RunePopup_RuneSelect_img4.png" } })
        state.BtnState[btnKey] = false
    else
        NodeHelper:setMenuItemImage(container, { [nodeName] = { normal = "RunePopup_RuneSelect_img5.png" } })
        state.BtnState[btnKey] = true
    end
    saveButtonStates(state.BtnState)
    self:SyncContent(container)
end

function RuneBuildSelectPage:OnRareButton(container, eventName)
    self:ToggleButtonState(container, eventName, "Rare", "mRare")
end

function RuneBuildSelectPage:OnAttrButton(container, eventName)
    self:ToggleButtonState(container, eventName, "Attr", "mAttr")
end

function RuneBuildSelectPage:OnStatusButton(container, eventName)
    self:ToggleButtonState(container, eventName, "Status", "mStatus")
end

function RuneBuildSelectPage:SyncContent(container)
    state.BtnState = loadButtonStates()
    self:RebuildRuneItems(container)
end

function RuneBuildSelectPage:InitializeData(container)
    state.nonWearRuneTable = FateDataManager:getNotWearFateList()
    state.nonWearRuneItems = {}
    state.runeTouchLayers  = {}
    state.selectState      = {}
    state.nowSelectRank    = 0
    self:ClearTouchData(container)
    self:SortRuneData()
end

function RuneBuildSelectPage:InitializeUI(container)
    NodeHelper:initScrollView(container, "mContent", 30)
end

function RuneBuildSelectPage:ConfirmSelection(container)
    local selectRuneInfos = {}
    local index = 1
    for k, v in pairs(state.selectState) do
        if v.isSelect then
            selectRuneInfos[index] = v.info
            index = index + 1
        end
    end
    state.selectState = {}
    RunePageBase_setSelectInfo(selectRuneInfos)
    self:ClosePage(container)
end

function RuneBuildSelectPage:SortRuneData()
    table.sort(state.nonWearRuneTable, function(v1, v2)
        local cfg1 = ConfigManager.getFateDressCfg()[v1.itemId]
        local cfg2 = ConfigManager.getFateDressCfg()[v2.itemId]
        if v1.rare ~= v2.rare then
            return v1.rare < v2.rare
        end
        if v1.star ~= v2.star then
            return v1.star < v2.star
        end
        local attrInfo1 = combineAttributes(cfg1.basicAttr, v1.attr)
        local attrInfo2 = combineAttributes(cfg2.basicAttr, v2.attr)
        for i = 1, math.max(#attrInfo1, #attrInfo2) do
            if attrInfo1[i] and not attrInfo2[i] then
                return true
            elseif not attrInfo1[i] and attrInfo2[i] then
                return false
            else
                local attr1, value1 = unpack(common:split(attrInfo1[i], "_"))
                local attr2, value2 = unpack(common:split(attrInfo2[i], "_"))
                if tonumber(attr1) ~= tonumber(attr2) then
                    return tonumber(attr1) < tonumber(attr2)
                end
                if tonumber(value1) ~= tonumber(value2) then
                    return tonumber(value1) < tonumber(value2)
                end
            end
        end
        return false
    end)
end

function RuneBuildSelectPage:RefreshPage(container)
    self:RebuildRuneItems(state.pageContainer)
    NodeHelper:setNodesVisible(state.pageContainer, { mPageType1 = false, mFilter = false, mLock = false })
    local conf = nil
    if state.lastNode.id then
        conf = state.selectState[state.lastNode.id].info:getConf()
    end
    self:UpdateRuneDetailPanel(conf, state.lastNode.id)
end

--------------------------------------------------
-- 判斷符文是否符合過濾條件（Rare / Status / Attr）
--------------------------------------------------
local function shouldDisplayRune(data)
    local hasRareFilter   = false
    local hasStatusFilter = false
    local hasAttrFilter   = false

    for key, selected in pairs(state.BtnState) do
        if string.find(key, "Rare") and selected then
            hasRareFilter = true
        elseif string.find(key, "Status") and selected then
            hasStatusFilter = true
        elseif string.find(key, "Attr") and selected then
            hasAttrFilter = true
        end
    end

    local matchesRare   = not hasRareFilter
    local matchesStatus = not hasStatusFilter
    local matchesAttr   = not hasAttrFilter

    local function rareMatches(rare, star)
        return data.rare == rare and data.star == star
    end

    local rareMapping = {
        [1] = {1, 1},
        [2] = {1, 2},
        [3] = {2, 1},
        [4] = {2, 2},
        [5] = {3, 1},
    }

    if hasRareFilter then
        for btnKey, selected in pairs(state.BtnState) do
            if selected and btnKey:find("Rare") then
                local filterNum = tonumber(btnKey:sub(-1))
                local mapping   = rareMapping[filterNum]
                if mapping and rareMatches(mapping[1], mapping[2]) then
                    matchesRare = true 
                    break
                end
            end
        end
    end

    if hasStatusFilter then
        for key, selected in pairs(state.BtnState) do
            if string.find(key, "Status") and selected then
                local basic = tonumber(string.sub(key, -1))
                if basic == 1 then
                    basic = 113
                elseif basic == 2 then
                    basic = 114
                end
                if basic == tonumber(common:split(data.basicAttr, "_")[1]) then
                    matchesStatus = true
                    break
                end
            end
        end
    end

    if hasAttrFilter then
        for key, selected in pairs(state.BtnState) do
            if string.find(key, "Attr") and selected then
                local index   = tonumber(string.sub(key, -1))
                local entries = common:split(data.basicAttr, ",")
                local ids     = {}
                for _, entry in ipairs(entries) do
                    local parts = common:split(entry, "_")
                    table.insert(ids, tonumber(parts[1]))
                end
                for _, v in pairs(ids) do
                    if attrIdMapping[index] == v then
                        matchesAttr = true
                        break
                    end
                end
            end
        end
    end

    return matchesRare and matchesStatus and matchesAttr
end

function RuneBuildSelectPage:RebuildRuneItems(container)
    if not container then return end
    container.mScrollView:removeAllCell()
    state.nonWearRuneItems = {}
    state.nowSelectRank    = 0
    state.nowSelectNum     = 0
    local showCount  = 0
    table.sort(state.nonWearRuneTable, function(a, b) return a.id < b.id end)
    for i = 1, #state.nonWearRuneTable do
        local cell = CCBFileCell:create()
        cell:setCCBFile(RuneItemContent.ccbiFile)
        local info = state.nonWearRuneTable[i]
        if info:getConf().afterId ~= -1 then  -- afterId = -1 表示無法合成
            local handler = RuneItemContent:new({ id = i, runeInfo = info })
            cell:registerFunctionHandler(handler)
            local data = info:getConf()
            cell:setScale(0.9)
            if shouldDisplayRune(data) then
                cell:setContentSize(CCSizeMake(136 * 0.9, 136 * 0.9))
                container.mScrollView:addCell(cell)
            end
            state.nonWearRuneItems[info.id] = { cls = handler, node = cell }
            if not state.selectState[info.id] then
                state.selectState[info.id] = { isSelect = false, info = info, isTouch = false }
            end
            showCount = showCount + 1         
        end
    end
    state.nowSelectNum = 0
    for _, data in pairs(state.selectState) do
        if data.isSelect then
            state.nowSelectNum = state.nowSelectNum + 1
        end
    end
    container.mScrollView:orderCCBFileCells()
    NodeHelper:setStringForLabel(container, { mSelectTxt = common:getLanguageString("@RuneSelected", state.nowSelectNum) })
end

function RuneBuildSelectPage:LockRune(container)
    if state.lastNode.id and state.selectState[state.lastNode.id] then
        state.selectState[state.lastNode.id].isSelect = false
        state.selectState[state.lastNode.id].isTouch  = true
        local Badge_pb = require("Badge_pb")
        local msg      = Badge_pb.HPBadgeLockReq()
        msg.badgeId    = state.nowClickId
        common:sendPacket(HP_pb.BADGE_LOCK_C, msg)
    end
end

function RuneBuildSelectPage:ProcessTouch(container)
    if TOUCH_DATA.IS_TOUCHING then
        local dt = GamePrecedure:getInstance():getFrameTime()
        TOUCH_DATA.TOUCH_TIMECOUNT = TOUCH_DATA.TOUCH_TIMECOUNT + dt
        if TOUCH_DATA.TOUCH_TIMECOUNT > (1 / TOUCH_DATA.TOUCH_TIMEINTERVAL) then
            require("RuneInfoPage_Forge")
            RuneForgePage_setPageInfo(GameConfig.RuneInfoPageType.FUSION, TOUCH_DATA.TOUCH_ID)
            PageManager.pushPage("RuneInfoPage_Forge")
            self:ClearTouchData(container)
        end
    end
end

function RuneBuildSelectPage:ClearTouchData(container)
    TOUCH_DATA.TOUCH_ID           = 0
    TOUCH_DATA.TOUCH_TIMECOUNT    = 0
    TOUCH_DATA.TOUCH_TIMEINTERVAL = 1
    TOUCH_DATA.IS_TOUCHING        = false
    TOUCH_DATA.MOVE_X             = 0
    TOUCH_DATA.MOVE_Y             = 0
end

function RuneBuildSelectPage:ClosePage(container)
    PageManager.popPage(thisPageName)
    state = {
        pageContainer     = nil,
        nonWearRuneTable  = {},   -- 未穿戴符文資料
        nonWearRuneItems  = {},   -- scrollview 內的 cell 與 handler
        runeTouchLayers   = {},   -- 各 cell 內的觸控層
        selectState       = {},   -- 各符文的選中狀態（鍵為符文 id）
        nowSelectRank     = 0,
        nowSelectNum      = 0,
        nowClickId        = 0,
        lastNode          = {},
        BtnState          = {},   -- 過濾按鈕狀態
    }
end

function RuneBuildSelectPage:UpdateRuneDetailPanel(data, id)
    local container = state.pageContainer
    if not container then return end
    state.nowClickId = id
    if not data then
        NodeHelper:setNodesVisible(container, { mPageType1 = false, mIcon = true, mItem = false })
    else
        NodeHelper:setNodesVisible(container, { mPageType1 = true, mIcon = false, mItem = true })
        local runeInfo = nil
        for i = 1, #state.nonWearRuneTable do
            if state.nonWearRuneTable[i].id == id then
                runeInfo = state.nonWearRuneTable[i]
                break
            end
        end
        local attrInfo = combineAttributes(data.basicAttr, runeInfo.attr)
        NodeHelper:setNodesVisible(state.pageContainer, { mLock = true })
        local img = (runeInfo.lock == 0) and "RunePopup_RuneStats_Lock0.png" or "RunePopup_RuneStats_Lock1.png"
        NodeHelper:setNormalImage(container, "mLock", img)
        for i = 1, 3 do
            if attrInfo[i] then
                NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = true })
                local attrIdValue, attrNum = unpack(common:split(attrInfo[i], "_"))
                NodeHelper:setSpriteImage(container, { ["mAttrImg" .. i] = "attri_" .. attrIdValue .. ".png" })
                NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i] = ("+" .. attrNum) })
            else
                NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = false })
            end
        end
        local fullName = common:getLanguageString(data.name) .. common:getLanguageString("@Rune")
        NodeHelper:setStringForLabel(container, { mRuneName = fullName })
        for i = 1, 5 do
            if runeInfo.newSkill and runeInfo.newSkill[i] then
                NodeHelper:setNodesVisible(container, { ["mSkill" .. i] = true })
                RuneItemContent:SetHtmlDescription(container, runeInfo.newSkill[i], i)
            else
                local skillDesNode = container:getVarNode("mHtmlNode" .. i)
                skillDesNode:removeAllChildren()
                NodeHelper:setStringForLabel(container, { ["mTxt" .. i] = common:getLanguageString("@RuneSkillTip" .. i) })
            end
        end
        local CommItem    = require("CommUnit.CommItem")
        local InfoAccesser = require("Util.InfoAccesser")
        local costItem    = CommItem:new()
        local costItemUI  = costItem:requestUI()
        container:getVarNode("mItem"):addChild(costItemUI)
        costItemUI:setScale(0.65)
        local itemInfo = InfoAccesser:getItemInfo(90000, data.id, 1)
        costItem:autoSetByItemInfo(itemInfo, false)
    end
end

--------------------------------------------------
-- 以下為 RuneItemContent 模組（生成 cell 顯示內容與觸控處理）
--------------------------------------------------

function RuneItemContent:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RuneItemContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container  = container

    if self.runeInfo then
        self.cfg = ConfigManager.getFateDressCfg()[self.runeInfo.itemId]
        local visibleMap = {
            mCheck         = not state.selectState[self.runeInfo.id].isTouch and self.runeInfo.lock == 0,
            selectedNode   = (state.selectState[self.runeInfo.id].isSelect and self.runeInfo.lock == 0) or state.selectState[self.runeInfo.id].isTouch,
            mStarNode      = true, 
            mSkill         = false,
            nameBelowNode  = false,
            mNumber1_1     = false,
            mPoint         = false,
            mLock          = self.runeInfo.lock == 1
        }
        NodeHelper:setNodesVisible(container, visibleMap)
        NodeHelper:setSpriteImage(container, { mPic1 = self.cfg.icon,  
                                               mFrameShade1 = NodeHelper:getImageBgByQuality(self.cfg.rare) })
        NodeHelper:setQualityFrames(container, { mHand1 = self.cfg.rare })
        for star = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. star] = (star == self.cfg.star) })
        end
        local attrInfo = combineAttributes(self.cfg.basicAttr, self.runeInfo.attr)
        for i = 1, 3 do
            if attrInfo[i] then
                NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = true })
                local attrIdValue, attrNum = unpack(common:split(attrInfo[i], "_"))
                NodeHelper:setSpriteImage(container, { ["mAttrImg" .. i] = "attri_" .. attrIdValue .. ".png" })
                NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i] = ("+" .. attrNum) })
            else
                NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = false })
            end
        end
        self:InitializeTouchLayer(container)
    end
end

function RuneItemContent:InitializeTouchLayer(container)
    local parent = container:getVarNode("mFrameShade1")
    if not parent then
        print("Invalid node: mFrameShade1 is nil")
        return
    end

    if self.runeInfo then
        local runeId = self.runeInfo.id
        parent:removeAllChildrenWithCleanup(true)
        state.runeTouchLayers[runeId] = nil

        local layer = CCLayer:create()
        layer:setContentSize(parent:getContentSize())
        parent:addChild(layer)

        local function onTouch(eventName, pTouch)
            if eventName == "began" then
                return RuneItemContent:HandleTouchBegin(container, eventName, pTouch, runeId)
            elseif eventName == "moved" then
                return RuneItemContent:HandleTouchMove(container, eventName, pTouch, runeId)
            elseif eventName == "ended" then
                return RuneItemContent:HandleTouchEnd(container, eventName, pTouch, runeId)
            elseif eventName == "cancelled" then
                return RuneItemContent:HandleTouchCancel(container, eventName, pTouch, runeId)
            end
        end

        layer:registerScriptTouchHandler(onTouch, false, 0, false)
        layer:setTouchEnabled(true)
        state.runeTouchLayers[runeId] = layer
    end
end

function RuneItemContent:HandleTouchBegin(container, eventName, pTouch, id)
    local rect  = GameConst:getInstance():boundingBox(state.runeTouchLayers[id])
    local point = state.runeTouchLayers[id]:convertToNodeSpace(pTouch:getLocation())
    if GameConst:getInstance():isContainsPoint(rect, point) then
        RuneBuildSelectPage:ClearTouchData(container)
        TOUCH_DATA.TOUCH_ID = id
        CCLuaLog("HandleTouchBegin, TOUCH_ID: " .. id)
        TOUCH_DATA.IS_TOUCHING = true
        return true
    end
    return false 
end

function RuneItemContent:HandleTouchMove(container, eventName, pTouch, id)
    if id == TOUCH_DATA.TOUCH_ID then
        local delta = pTouch:getDelta()
        TOUCH_DATA.MOVE_X = TOUCH_DATA.MOVE_X + math.abs(delta.x)
        TOUCH_DATA.MOVE_Y = TOUCH_DATA.MOVE_Y + math.abs(delta.y)
        if TOUCH_DATA.MOVE_Y > 10 then
            RuneBuildSelectPage:ClearTouchData(container)
        end
    end
end

function RuneItemContent:HandleTouchEnd(container, eventName, pTouch, id)
    local itemNode = state.nonWearRuneItems[TOUCH_DATA.TOUCH_ID]
    if itemNode and TOUCH_DATA.TOUCH_TIMECOUNT <= (1 / TOUCH_DATA.TOUCH_TIMEINTERVAL) then
        local isSelect = not state.selectState[TOUCH_DATA.TOUCH_ID].isSelect
        if isSelect then  -- 選中處理
            local conf = state.selectState[TOUCH_DATA.TOUCH_ID].info:getConf()
            if state.nowSelectNum >= MAX_SELECT_NUM then
                MessageBoxPage:Msg_Box_Lan("@GemSynLimit")
            elseif state.selectState[TOUCH_DATA.TOUCH_ID].info.lock == 1 then
                if state.lastNode.container and state.selectState[state.lastNode.id].isTouch then
                    NodeHelper:setNodesVisible(state.lastNode.container, { selectedNode = false, mCheck = true })
                end
                if state.lastNode.id then
                    state.selectState[state.lastNode.id].isTouch = false
                end
                state.selectState[TOUCH_DATA.TOUCH_ID].isTouch = true
                NodeHelper:setNodesVisible(itemNode.cls.container, { selectedNode = true, mCheck = false })
                RuneBuildSelectPage:UpdateRuneDetailPanel(conf, TOUCH_DATA.TOUCH_ID)
                state.lastNode.container = itemNode.cls.container
                state.lastNode.id        = TOUCH_DATA.TOUCH_ID
            elseif state.nowSelectRank == 0 or state.nowSelectRank == conf.rank then
                if state.lastNode.container and state.selectState[state.lastNode.id].isTouch then
                    NodeHelper:setNodesVisible(state.lastNode.container, { selectedNode = false, mCheck = true })
                end
                if state.lastNode.id then
                    state.selectState[state.lastNode.id].isTouch = false
                end
                state.lastNode.container = itemNode.cls.container
                state.lastNode.id        = TOUCH_DATA.TOUCH_ID
                NodeHelper:setNodesVisible(itemNode.cls.container, { selectedNode = isSelect, mCheck = true })
                state.selectState[TOUCH_DATA.TOUCH_ID].isSelect = isSelect
                itemNode.isSelect = isSelect
                state.nowSelectRank = conf.rank
                state.nowSelectNum  = math.min(state.nowSelectNum + 1, MAX_SELECT_NUM)
                NodeHelper:setStringForLabel(state.pageContainer, { mSelectTxt = common:getLanguageString("@RuneSelected", state.nowSelectNum) })
                RuneBuildSelectPage:UpdateRuneDetailPanel(conf, TOUCH_DATA.TOUCH_ID)
            else
                MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@ERRORCODE_81702"))
            end
        else  -- 取消選中處理
            state.nowSelectNum = math.max(state.nowSelectNum - 1, 0)
            if state.nowSelectNum <= 0 then
                state.nowSelectRank = 0
            end
            RuneBuildSelectPage:UpdateRuneDetailPanel()
            NodeHelper:setNodesVisible(state.pageContainer, { mLock = false })
            NodeHelper:setNodesVisible(itemNode.cls.container, { selectedNode = isSelect, mCheck = true })
            state.selectState[TOUCH_DATA.TOUCH_ID].isTouch  = false
            state.selectState[TOUCH_DATA.TOUCH_ID].isSelect = isSelect
            itemNode.isSelect = isSelect
            NodeHelper:setStringForLabel(state.pageContainer, { mSelectTxt = common:getLanguageString("@RuneSelected", state.nowSelectNum) })
        end
    end
    RuneBuildSelectPage:ClearTouchData(container)
end

function RuneItemContent:HandleTouchCancel(container, eventName, pTouch, id)
    return RuneItemContent:HandleTouchEnd(container, eventName, pTouch, id)
end

function RuneItemContent:PreLoad(ccbRoot)
    -- 根據需要實現預加載邏輯
end

function RuneItemContent:UnLoad(ccbRoot)
    -- 根據需要實現卸載邏輯
end

function RuneItemContent:HandleHand(container)
    -- 根據需要實現手勢處理邏輯
end

function RuneItemContent:SetHtmlDescription(container, skillId, idx)
    if skillId > 10000000 then
        skillId = skillId - 10000000
    end
    local cfg = ConfigManager.getBadgeSkillCfg()[skillId]
    if not cfg then return end
    local freeTypeId   = cfg.skill
    local skillDesNode = container:getVarNode("mHtmlNode" .. idx)
    skillDesNode:removeAllChildren()
    local htmlContent = ""
    if FreeTypeConfig[freeTypeId] then
        htmlContent = FreeTypeConfig[freeTypeId].content or ""
    end
    local htmlLabel = CCHTMLLabel:createWithString(htmlContent, CCSizeMake(235, 50), "Barlow-SemiBold")
    htmlLabel:setAnchorPoint(ccp(0, 0.5))
    skillDesNode:addChild(htmlLabel)
    NodeHelper:setStringForLabel(container, { ["mTxt" .. idx] = "" })
end

--------------------------------------------------
-- 將本頁面繼承到 CommonPage 並返回
--------------------------------------------------
RuneBuildSelectPage = CommonPage.newSub(RuneBuildSelectPage, thisPageName, option)
return RuneBuildSelectPage
