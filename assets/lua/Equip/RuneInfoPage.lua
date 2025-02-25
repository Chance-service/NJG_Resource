------------------------------------------------------------
-- 全域狀態初始化
------------------------------------------------------------
RuneInfoState = RuneInfoState or {
    pageType = 0,
    runeId   = 0,
    roleId   = nil,
    pos      = nil,
    runeInfo = nil,
    container = nil
}

------------------------------------------------------------
-- 常數定義區
------------------------------------------------------------
local ITEM_TYPE_TOOL   = 30000    -- 道具類型（例如：工具類）
local ITEM_ID_COST     = 7501     -- 升星（星級提升）消耗道具 ID
local ITEM_ID_REFINE   = 7502     -- 精煉消耗道具 ID
local ITEM_ID_LOCK     = 7503     -- 鎖定/解鎖消耗道具 ID

local MAX_ATTR_NUM        = 4
local MAX_SKILL_COUNT     = 5
local DEEP_COMPARE_OFFSET = 10000000
local DEFAULT_HIDDEN_TEXT = "??????"
local LOCK_SCALE          = 0.8

------------------------------------------------------------
-- 模組引入與變數定義
------------------------------------------------------------
local FateDataManager    = require("FateDataManager")
local MysticalDress_pb   = require("Badge_pb")
local CommItem           = require("CommUnit.CommItem")
local InfoAccesser       = require("Util.InfoAccesser")
local CommonPage         = require("CommonPage")
local ConfigManager      = require("ConfigManager")  -- 請根據實際情況引入
local NodeHelper         = require("NodeHelper")       -- 請根據實際情況引入
local common             = require("common")           -- 請根據實際情況引入
local HP_pb              = require("HP_pb")
local Const_pb           = require("Const_pb")

local RuneInfoPage = {}
local runeInfo = nil  -- 當前符文資料

local option = {
    ccbiFile   = "RunePopUp.ccbi",
    handlerMap = {
        onClose   = "onClose",
        onFusion  = "onFusion",
        onChange  = "onChange",
        onEquip   = "onEquip",
        onRefine  = "onRefine",
        onConfirm = "onConfirm",
        onGiveUp  = "onGiveUp",
        onLock    = "onLock"
    },
    opcodes = {
        MYSTICAL_DRESS_CHANGE_C = HP_pb.BADGE_DRESS_C,
        MYSTICAL_DRESS_CHANGE_S = HP_pb.BADGE_DRESS_S,
        BADGE_REFINE_C          = HP_pb.BADGE_REFINE_C,
        BADGE_REFINE_S          = HP_pb.BADGE_REFINE_S,
    },
}

local IllItemContent = { ccbiFile = "EquipmentItem_Rune.ccbi" }
local SkillContent   = { ccbiFile = "RuneEquipPopUp_EntryContent.ccbi", LowerNode = {} }
local LockPopUp, SpRefinPopUp = nil, nil

------------------------------------------------------------
-- 輔助函數（例如深層比較、建立 cell、加入 cell 等）
------------------------------------------------------------
local function ensureNumericKeys(tbl)
    local new = {}
    for k, v in pairs(tbl) do
        if type(k) == "number" then new[k] = v end
    end
    return new
end

local function deepCompare(t1, t2, offset)
    t1, t2 = ensureNumericKeys(t1), ensureNumericKeys(t2)
    if not next(t1) or not next(t2) then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then
        return math.abs(t1 - t2) == offset
    end
    for k, v in pairs(t1) do
        if not (t2[k] and (v == t2[k] or math.abs(v - t2[k]) == offset)) then
            return false
        end
    end
    return true
end

local function createCell(cfg)
    local cell  = CCBFileCell:create()
    cell:setCCBFile(SkillContent.ccbiFile)
    local panel = common:new(cfg, SkillContent)
    cell:registerFunctionHandler(panel)
    return cell
end

local function addCells(scrollview, list, pos, isRefine)
    for i = 1, #list do
        scrollview:addCell(createCell({ lockId = i, id = list[i], Pos = pos, isRefine = isRefine }))
    end
    for i = #list + 1, MAX_SKILL_COUNT do
        scrollview:addCell(createCell({ LimitId = i, isLimit = true }))
    end
end

-- 發送鎖定/解鎖封包
local function setToLock(lockFlag, id)
    local msg = MysticalDress_pb.HPBadgeRefineReq()
    msg.badgeId = runeInfo.id
    msg.lockSlot:append(id)
    msg.action = lockFlag and 3 or 4
    common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
end

------------------------------------------------------------
-- 主流程函數
------------------------------------------------------------
function RuneInfoPage:onEnter(container)
    self.pageContainer = container
    RuneInfoState.container = container
    self:registerPacket(container)
    self:initData()
    self:initUI(container)
    self:refreshPage(container)
end

function RuneInfoPage:initData()
    local list = FateDataManager:getAllFateList()
    for _, v in ipairs(list) do
        if v.id == RuneInfoState.runeId then
            runeInfo = v
            RuneInfoState.runeInfo = v
            break
        end
    end
end

function RuneInfoPage:initUI(container)
    -- 若沒有符文資料，則清空畫面並返回
    if not runeInfo then
        NodeHelper:setStringForLabel(container, { mRuneName = "" })
        for i = 1, MAX_ATTR_NUM do
            NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = false })
        end
        NodeHelper:setNodesVisible(container, { mEffectNode = false, mSkillNullStr = true })
        return
    end

    -- 取得符文設定並更新符文名稱
    local cfg = ConfigManager.getFateDressCfg()[runeInfo.itemId]
    local runeName = common:getLanguageString(cfg.name) .. common:getLanguageString("@Rune")
    NodeHelper:setStringForLabel(container, { mRuneName = runeName })

    -- 合併基本屬性與隨機屬性（只取含 "_" 的）
    local attrInfo = {}
    for _, a in ipairs(common:split(cfg.basicAttr, ",")) do
        table.insert(attrInfo, a)
    end
    for _, a in ipairs(common:split(runeInfo.attr, ",")) do
        if string.find(a, "_") then
            table.insert(attrInfo, a)
        end
    end

    -- 更新屬性顯示
    for i = 1, MAX_ATTR_NUM do
        local nodeKey = "mAttrNode" .. i
        if attrInfo[i] then
            NodeHelper:setNodesVisible(container, { [nodeKey] = true })
            local parts = common:split(attrInfo[i], "_")
            local attrId, attrNum = parts[1], parts[2]
            NodeHelper:setSpriteImage(container, { ["mAttrImg" .. i] = "attri_" .. attrId .. ".png" })
            NodeHelper:setStringForLabel(container, { 
                ["mAttrName" .. i]  = common:getLanguageString("@AttrName_" .. attrId),
                ["mAttrValue" .. i] = attrNum 
            })
        else
            NodeHelper:setNodesVisible(container, { [nodeKey] = false })
        end
    end

    -- 根據精煉狀態更新介面（以下程式碼略，可依需求補全）
    runeInfo.lockCount = 0
    local isRefine = false
    if not deepCompare(runeInfo.readyToRefine or runeInfo.newSkill, runeInfo.skill, DEEP_COMPARE_OFFSET) then
        NodeHelper:setNodesVisible(container, { mRefineBtn1 = false, mRefineBtn2 = true, mEmptyTxt1 = false, mEmptyTxt2 = false })
        if not runeInfo.readyToRefine then
            runeInfo.readyToRefine = runeInfo.newSkill
        end
        isRefine = true
    elseif #runeInfo.newSkill > 0 then
        for _, v in ipairs(runeInfo.newSkill) do
            if tonumber(v) and v > DEEP_COMPARE_OFFSET then
                runeInfo.lockCount = runeInfo.lockCount + 1
            end
        end
        NodeHelper:setNodesVisible(container, { mEmptyTxt1 = false, mEmptyTxt2 = false })
        NodeHelper:setMenuItemsEnabled(container, { mBtn2 = true })
    elseif cfg.slot > 0 then
        NodeHelper:setNodesVisible(container, { mEmptyTxt1 = false, mEmptyTxt2 = false })
        NodeHelper:setMenuItemsEnabled(container, { mBtn2 = true })
    else
        NodeHelper:setMenuItemsEnabled(container, { mBtn2 = false })
        NodeHelper:setNodesVisible(container, { mEmptyTxt1 = false, mEmptyTxt2 = false })
    end

    -- 建立 ScrollView 內容
    if isRefine then
        self:buildUpperScrollview(container, true)
        self:buildLowerScrollview(container, true)
    else
        self:buildUpperScrollview(container)
        self:buildLowerScrollview(container)
    end

    -- 設定按鈕文字（依據頁面類型）
    local btnTxt = RuneInfoState.pageType == GameConfig.RuneInfoPageType.EQUIPPED and
                   { mBtnTxt3 = common:getLanguageString("@TakeOff"), mBtn1Txt = common:getLanguageString("@Replace") } or
                   { mBtnTxt3 = common:getLanguageString("@Mosaic"),  mBtn1Txt = common:getLanguageString("@Compound") }
    NodeHelper:setStringForLabel(container, btnTxt)

    -- 上鎖狀態設定
    NodeHelper:setNodesVisible(container, { mLock = true })
    local img = (RuneInfoState.runeInfo.lock == 0) and "RunePopup_RuneStats_Lock0.png" or "RunePopup_RuneStats_Lock1.png"
    NodeHelper:setNormalImage(RuneInfoState.container, "mLock", img)

    -- 設定升星消耗道具的 UI（此處略部份細節）
    local costItem   = CommItem:new()
    local costItemUI = costItem:requestUI()
    local starUpCostNode = container:getVarNode("starUpCostNode")
    starUpCostNode:addChild(costItemUI)
    costItemUI:setScale(0.5)
    local sz = costItemUI:getContentSize()
    costItemUI:setPosition(ccp(sz.width * -0.25, sz.height * -0.25))
    costItem:autoSetByItemInfo(InfoAccesser:getItemInfo(ITEM_TYPE_TOOL, ITEM_ID_COST, 1), false)
    self:RefreshItemCount(container)
end

function RuneInfoPage:RefreshItemCount(container)
    local cost  = ConfigManager.getFateDressCfg()[runeInfo.itemId].refineCost[runeInfo.lockCount + 1]
    local have  = InfoAccesser:getUserItemInfo(Const_pb.TOOL, ITEM_ID_COST).count or 0
    NodeHelper:setStringForLabel(container, { starUpCostTxt_1 = have .. "/" .. cost })
end

function RuneInfoPage:RefreshLockIcon()
    if not RuneInfoState.runeInfo then return end
    NodeHelper:setNodesVisible(container, { mLock = true })
    local img = (RuneInfoState.runeInfo.lock == 0) and "RunePopup_RuneStats_Lock0.png" or "RunePopup_RuneStats_Lock1.png"
    NodeHelper:setNormalImage(RuneInfoState.container, "mLock", img)
    runeInfo = RuneInfoState.runeInfo
    self.pageContainer = RuneInfoState.container
end

function RuneInfoPage:buildUpperScrollview(container, isRefine)
    local scrollview = container:getVarScrollView("mUpperScrollview")
    if not scrollview then return end
    scrollview:removeAllCell()
    addCells(scrollview, runeInfo.skill, "Up", isRefine)
    scrollview:setTouchEnabled(false)
    scrollview:orderCCBFileCells()
end

function RuneInfoPage:buildLowerScrollview(container, isRefine)
    local scrollview = container:getVarScrollView("mLowerScrollview")
    if not scrollview then return end
    scrollview:removeAllCell()
    if isRefine and runeInfo.readyToRefine and #runeInfo.readyToRefine > 0 then
        addCells(scrollview, runeInfo.readyToRefine, "Low", true)
    elseif not isRefine then
        if runeInfo.newSkill and #runeInfo.newSkill > 0 then
            addCells(scrollview, runeInfo.newSkill, "Low", false)
        else
            local skillCount = ConfigManager.getFateDressCfg()[runeInfo.itemId].slot
            for i = 1, skillCount do
                scrollview:addCell(createCell({ id = i, Pos = "Low", isRefine = false }))
            end
            for i = skillCount + 1, 5 do
                scrollview:addCell(createCell({ LimitId = i, isLimit = true }))
            end
        end
    end
    scrollview:setTouchEnabled(false)
    scrollview:orderCCBFileCells()
end

------------------------------------------------------------
-- SkillContent 模組（部分事件與內容顯示邏輯）
------------------------------------------------------------
function SkillContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local runecfg   = ConfigManager.getFateDressCfg()[runeInfo.itemId]
    if self.isLimit then
        NodeHelper:setNodesVisible(container, { mLimitNode = true })
        NodeHelper:setStringForLabel(container, { mLimitTxt = common:getLanguageString("@RuneSkillTip" .. self.LimitId) })
        return
    else
        NodeHelper:setNodesVisible(container, { mLimitNode = false })
    end

    if runeInfo.newSkill and runeInfo.newSkill[self.lockId] and runeInfo.newSkill[self.lockId] > 10000000 then
        NodeHelper:setNodesVisible(container, { mLockBg = true })
        if self.id > 10000000 then self.id = self.id - 10000000 end
        self.Lock = true
    end

    if self.Pos == "Low" then
        if self.isRefine then
            NodeHelper:setStringForLabel(container, { mTxt = "" })
            self:setHtmlString(container, self.id)
        else
            NodeHelper:setStringForLabel(container, { mTxt = DEFAULT_HIDDEN_TEXT })
            container:getVarNode("mHtmlNode"):removeAllChildren()
        end
        NodeHelper:setNodesVisible(container, { mRefine = false, mLock = false })
        SkillContent.LowerNode[self.id] = container
        SkillContent:setLockState(container, self.Lock, self.id, self.Pos, self.isRefine)
    else
        NodeHelper:setNodesVisible(container, { mLock = true })
        self:setHtmlString(container, self.id)
        SkillContent:setLockState(container, self.Lock, self.id)
        NodeHelper:setNodesVisible(container, { mRefine = (runecfg.unlocksp == 1 and not self.Lock) })
        if self.Refine then NodeHelper:setNodesVisible(container, { mLock = false, mRefine = false }) end
    end
end

function SkillContent:setHtmlString(container, id, option, parent)
    local cfg = ConfigManager.getBadgeSkillCfg()[id]
    if not cfg then return end
    local node = parent and container:getVarNode(parent) or container:getVarNode("mHtmlNode")
    if node then node:removeAllChildren() end
    local label = CCHTMLLabel:createWithString(
                      (FreeTypeConfig[cfg.skill] and FreeTypeConfig[cfg.skill].content or ""),
                      CCSizeMake(option and option.width or 450, 50),
                      "Barlow-SemiBold")
    if option then label:setScale(option.Scale or 1) end
    label:setAnchorPoint(parent and ccp(0.5, 0.5) or ccp(0, 0.5))
    if node then node:addChild(label) end
    NodeHelper:setStringForLabel(container, { mTxt = "" })
end

function SkillContent:onLock(container)
    if self.Lock then
        PageManager.showConfirm(common:getLanguageString("@Unlock"), common:getLanguageString("@Unlock_desc"),
            function(isSure) if isSure then setToLock(false, self.lockId) end end, true, "@Unlock", "@CancelingSaving")
    else
        if runeInfo.lockCount == #runeInfo.skill - 1 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@Lock_ERROR"))
            return
        end
        LockPopUp = ScriptContentBase:create("RunePopUp_Lock")
        -- 直接從全域取得頁面 container
        RuneInfoState.container:getVarNode("mPopUpNode"):addChild(LockPopUp)
        LockPopUp:setAnchorPoint(ccp(0.5, 0.5))
        SkillContent:SetLockPopupPage(LockPopUp, self.id)
        runeInfo.nowClickId = self.lockId
        LockPopUp:registerFunctionHandler(RuneLockPopUpFun)
    end
end

function SkillContent:onRefine(container)
    SpRefinPopUp = ScriptContentBase:create("RunePopUp_Refresh")
    -- 直接從全域取得頁面 container
    RuneInfoState.container:getVarNode("mPopUpNode"):addChild(SpRefinPopUp)
    SpRefinPopUp:setAnchorPoint(ccp(0.5, 0.5))
    runeInfo.nowClickId = self.lockId
    SkillContent:SetRefinePopupPage(SpRefinPopUp, self.id)
    SpRefinPopUp:registerFunctionHandler(RuneRefinePopUpFun)
end

function RuneLockPopUpFun(eventName, container)
    if eventName == "onUse" then
        local cost = ConfigManager.getFateDressCfg()[runeInfo.itemId].lockCost[runeInfo.lockCount + 1]
        local have = InfoAccesser:getUserItemInfo(Const_pb.TOOL, ITEM_ID_LOCK).count or 0
        if tonumber(cost) > have then
            MessageBoxPage:Msg_Box(common:getLanguageString("@LackItem"))
        else
            setToLock(true, runeInfo.nowClickId)
            local p = RuneInfoState.container:getVarNode("mPopUpNode")
            if p then p:removeAllChildren() end
        end
    elseif eventName == "onClose" then
        local p = RuneInfoState.container:getVarNode("mPopUpNode")
        if p then p:removeAllChildren() end
    end
end

function RuneRefinePopUpFun(eventName, container)
    if eventName == "onRefine" then
        local msg = MysticalDress_pb.HPBadgeRefineReq()
        msg.badgeId = runeInfo.id; msg.action = 2; msg.slotId = runeInfo.nowClickId
        common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
    elseif eventName == "onClose" or eventName == "onGiveUp" then
        local msg = MysticalDress_pb.HPBadgeRefineReq()
        msg.badgeId = runeInfo.id; msg.action = 5
        common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
    elseif eventName == "onConfirm" then
        RuneInfoPage:onConfirm(container)
    end
end

function SkillContent:SetLockPopupPage(container, id)
    local costItem   = CommItem:new()
    local ui         = costItem:requestUI()
    container:getVarNode("mCostNode"):addChild(ui)
    ui:setScale(LOCK_SCALE)
    local sz = ui:getContentSize()
    ui:setPosition(ccp(sz.width * -0.4, sz.height * -0.4))
    costItem:autoSetByItemInfo(InfoAccesser:getItemInfo(ITEM_TYPE_TOOL, ITEM_ID_LOCK, 1), false)
    local cost = ConfigManager.getFateDressCfg()[runeInfo.itemId].lockCost[runeInfo.lockCount + 1]
    local have = InfoAccesser:getUserItemInfo(Const_pb.TOOL, ITEM_ID_LOCK).count or 0
    NodeHelper:setStringForLabel(container, { mCostTxt = have .. "/" .. cost,
                                               mItemName = common:getLanguageString("@Item_" .. ITEM_ID_LOCK) })
    local opts = { PosY = 30, Scale = 1.5, width = 350 }
    SkillContent:setHtmlString(container, id, opts)
    NodeHelper:setScale9SpriteBar(container, "mBar", have, cost, 404)
end

function SkillContent:SetRefinePopupPage(container, id)
    local costItem   = CommItem:new()
    local ui         = costItem:requestUI()
    container:getVarNode("mCostNode"):addChild(ui)
    ui:setScale(LOCK_SCALE)
    local sz = ui:getContentSize()
    ui:setPosition(ccp(sz.width * -0.4, sz.height * -0.4))
    costItem:autoSetByItemInfo(InfoAccesser:getItemInfo(ITEM_TYPE_TOOL, ITEM_ID_REFINE, 1), false)
    local cost = 1
    local have = InfoAccesser:getUserItemInfo(Const_pb.TOOL, ITEM_ID_REFINE).count or 0
    NodeHelper:setStringForLabel(container, { mItemCostTxt = have .. "/" .. cost,
                                               mItemName    = common:getLanguageString("@Item_" .. ITEM_ID_REFINE) })
    local opts = { PosY = 30, Scale = 1.5, width = 350 }
    SkillContent:setHtmlString(container, id, opts)
    opts.PosY = 12
    SkillContent:setHtmlString(container, id, opts, "mSkillName1")
    NodeHelper:setScale9SpriteBar(container, "mBar", have, cost, 404)
end

function SkillContent:setLockState(container, Lock, id, Pos, isRefine)
    if Lock then
        NodeHelper:setNodesVisible(container, { mLockBg = true, mRefine = false })
        SkillContent:setHtmlString(container, id)
        NodeHelper:setMenuItemImage(container, { mLock = { normal = "RunePopup_RuneStats_Lock1.png" } })
    else
        if Pos == "Low" then
            NodeHelper:setNodesVisible(container, { mLockBg = false, mRefine = false })
            if not isRefine then
                NodeHelper:setStringForLabel(container, { mTxt = DEFAULT_HIDDEN_TEXT })
                container:getVarNode("mHtmlNode"):removeAllChildren()
            end
        else
            NodeHelper:setNodesVisible(container, { mLockBg = false, mRefine = true })
            NodeHelper:setMenuItemImage(container, { mLock = { normal = "RunePopup_RuneStats_Lock0.png" } })
        end
    end
end

------------------------------------------------------------
-- 按鈕事件（裝備、精煉、換裝等）
------------------------------------------------------------
function RuneInfoPage:onFusion(container)
    if RuneInfoState.pageType == GameConfig.RuneInfoPageType.EQUIPPED then
        self:onChange(container)
    else
        if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.FORGE) then
            MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.FORGE))
        else
            require("EquipIntegrationPage")
            EquipIntegrationPage_SetCurrentPageIndex(1)
            PageManager.pushPage("EquipIntegrationPage")
        end
    end
    PageManager.popPage("RuneInfoPage")
end

function RuneInfoPage:onRefine(container)
    local msg = MysticalDress_pb.HPBadgeRefineReq()
    msg.badgeId = runeInfo.id; msg.action = 1
    common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
end

function RuneInfoPage:onConfirm(container)
    local msg = MysticalDress_pb.HPBadgeRefineReq()
    msg.badgeId = runeInfo.id; msg.action = 0
    common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
end

function RuneInfoPage:onGiveUp(container)
    local msg = MysticalDress_pb.HPBadgeRefineReq()
    msg.badgeId = runeInfo.id; msg.action = 5
    common:sendPacket(option.opcodes.BADGE_REFINE_C, msg, true)
end

function RuneInfoPage:onChange(container)
    require("FateWearsSelectPage")
    FateWearsSelectPage_setFate({
        roleId        = RuneInfoState.roleId,
        locPos        = RuneInfoState.pos,
        currentFateId = RuneInfoState.runeId
    })
    PageManager.pushPage("FateWearsSelectPage")
end

function RuneInfoPage:onEquip(container)
    if RuneInfoState.pageType == GameConfig.RuneInfoPageType.EQUIPPED then
        if RuneInfoState.runeId and RuneInfoState.roleId and RuneInfoState.pos then
            local msg = MysticalDress_pb.HPMysticalDressChange()
            msg.roleId     = RuneInfoState.roleId
            msg.loc        = RuneInfoState.pos
            msg.type       = 2  -- 1: 裝備符石  2: 脫下符石  3: 交換符石
            msg.offEquipId = RuneInfoState.runeId
            common:sendPacket(option.opcodes.MYSTICAL_DRESS_CHANGE_C, msg)
            MessageBoxPage:Msg_Box("@RemoveEquip")
        end
    elseif RuneInfoState.pageType == GameConfig.RuneInfoPageType.NON_EQUIPPED then
        PageManager.popPage("RuneInfoPage")
        MainFrame_onLeaderPageBtn()
    end
end

function RuneInfoPage:refreshPage(container)
    local itemNode = ScriptContentBase:create(IllItemContent.ccbiFile)
    local parent = self.pageContainer:getVarNode("mIconNode")
    itemNode:setAnchorPoint(ccp(0.5, 0.5))
    parent:removeAllChildren()
    IllItemContent:refresh(itemNode)
    parent:addChild(itemNode)
end

------------------------------------------------------------
-- IllItemContent 處理（圖示、框架、星級）
------------------------------------------------------------
function IllItemContent:refresh(container)
    if runeInfo then
        local cfg = ConfigManager.getFateDressCfg()[runeInfo.itemId]
        NodeHelper:setNodesVisible(container, { mCheckNode = false, mStarNode = true })
        NodeHelper:setSpriteImage(container, {
            mPic        = cfg.icon,
            mFrameShade = NodeHelper:getImageBgByQuality(cfg.rare),
            mFrame      = NodeHelper:getImageByQuality(cfg.rare)
        })
        for star = 1, 6 do
            NodeHelper:setNodesVisible(container, { ["mStar" .. star] = (star == cfg.star) })
        end
    else
        NodeHelper:setNodesVisible(container, { mCheckNode = false, mStarNode = false })
        NodeHelper:setSpriteImage(container, {
            mPic        = "UI/Mask/Image_Empty.png",
            mFrameShade = "UI/Mask/Image_Empty.png",
            mFrame      = "UI/Mask/Image_Empty.png"
        })
    end
end

------------------------------------------------------------
-- 封包註冊與接收
------------------------------------------------------------
function RuneInfoPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then container:registerPacket(opcode) end
    end
end

function RuneInfoPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then container:removePacket(opcode) end
    end
end

function RuneInfoPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local buff   = container:getRecPacketBuffer()
    self:RefreshItemCount(container)
    if opcode == option.opcodes.MYSTICAL_DRESS_CHANGE_S then
        PageManager.refreshPage("EquipLeadPage", "refreshPage")
        PageManager.popPage("RuneInfoPage")
    elseif opcode == option.opcodes.BADGE_REFINE_S then
        local msg = MysticalDress_pb.HPBadgeRefineRet()
        msg:ParseFromString(buff)
        if msg.action == 0 or msg.action == 3 or msg.action == 4 then
            runeInfo.newSkill = msg.refineId
            self:initUI(self.pageContainer)
            NodeHelper:setNodesVisible(self.pageContainer, { mRefineBtn1 = true, mRefineBtn2 = false })
            NodeHelper:setNodesVisible(SpRefinPopUp, { mSkillNode = false, mItemNode = true })
            local p = self.pageContainer:getVarNode("mPopUpNode")
            if p then p:removeAllChildren() end
        elseif msg.action == 1 then
            runeInfo.readyToRefine = msg.refineId
            NodeHelper:setNodesVisible(self.pageContainer, { mRefineBtn1 = false, mRefineBtn2 = true })
            self:buildUpperScrollview(self.pageContainer, true)
            self:buildLowerScrollview(self.pageContainer, true)
        elseif msg.action == 2 then
            NodeHelper:setNodesVisible(SpRefinPopUp, { mSkillNode = true, mItemNode = false })
            local opts = { PosY = 12, Scale = 1.5, width = 350 }
            SkillContent:setHtmlString(SpRefinPopUp, msg.refineId[runeInfo.nowClickId], opts, "mSkillName2")
        elseif msg.action == 5 then
            runeInfo.readyToRefine = nil
            runeInfo.newSkill = msg.refineId
            NodeHelper:setNodesVisible(self.pageContainer, { mRefineBtn1 = true, mRefineBtn2 = false })
            self:initUI(self.pageContainer)
            local p = self.pageContainer:getVarNode("mPopUpNode")
            if p then p:removeAllChildren() end
        else
            NodeHelper:setNodesVisible(self.pageContainer, { mRefineBtn1 = true, mRefineBtn2 = false })
        end
    end
end

function RuneInfoPage:onClose()
    -- 清空全域狀態
    RuneInfoState = {
        pageType = 0,
        runeId   = 0,
        roleId   = nil,
        pos      = nil,
    }
    runeInfo = nil
    PageManager.popPage("RuneInfoPage")
end

function RuneInfoPage:onLock()
    local Badge_pb = require("Badge_pb")
    local msg      = Badge_pb.HPBadgeLockReq()
    msg.badgeId    = RuneInfoState.runeId
    common:sendPacket(HP_pb.BADGE_LOCK_C, msg,false)
end  

------------------------------------------------------------
-- 外部設定頁面資訊用函式
------------------------------------------------------------
function RuneInfoPage_setPageInfo(pageType, runeId, roleId, pos)
    RuneInfoState.pageType = pageType
    RuneInfoState.runeId   = runeId
    RuneInfoState.roleId   = roleId
    RuneInfoState.pos      = pos
end

------------------------------------------------------------
-- 模組封裝與返回
------------------------------------------------------------
RuneInfoPage = CommonPage.newSub(RuneInfoPage, "RuneInfoPage", option)
return RuneInfoPage
