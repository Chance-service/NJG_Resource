-- FateWearsSelectPage.lua
local FateWearsSelectPageBase = {}

--------------------------------------------------------------------------------
-- 引入依賴模組
--------------------------------------------------------------------------------
local HP_pb               = require("HP_pb")
local MysticalDress_pb    = require("Badge_pb")
local NodeHelper          = require("NodeHelper")
local FateDataManager     = require("FateDataManager")
local UserMercenaryManager= require("UserMercenaryManager")
local json                = require("json")
local CommonPage          = require("CommonPage")

--------------------------------------------------------------------------------
-- 配置參數與按鈕事件映射
--------------------------------------------------------------------------------
local option = {
    ccbiFile = "RuneSelectPopUp.ccbi",
    handlerMap = {
        onDisEquip = "onDisEquip",
        onClose    = "onClose",
        onFilter   = "onFilter",
        onReset    = "onReset",
    },
    opcode = {
        MYSTICAL_DRESS_CHANGE_C = HP_pb.BADGE_DRESS_C,
        MYSTICAL_DRESS_CHANGE_S = HP_pb.BADGE_DRESS_S,
    },
}
for i = 1, 5 do
    option.handlerMap["onRare" .. i] = "onRare"
end
for i = 1, 2 do
    option.handlerMap["onStatus" .. i] = "onStatus"
end
for i = 1, 7 do
    option.handlerMap["onAttr" .. i] = "onAttr"
end

--------------------------------------------------------------------------------
-- 模組內部變數及常量
--------------------------------------------------------------------------------
local ItemInfo     = FateDataManager.FateWearSelectItem
local currRuneData = {}  -- 當前符石屬性（用於比較顯示差值）
local Items        = {}  -- 保存所有項目的引用
local ItemSize     = CCSize(613, 134)
local attrId       = { [1] = 101, [2] = 106, [3] = 107, [4] = 111, [5] = 108, [6] = 109, [7] = 110 }

local PageInfo = {
    roleId          = nil,  -- 角色ID
    locPos          = nil,  -- 裝備位置
    currentFateData = nil,  -- 當前裝備的符石資料
    fateIdList      = {},
    bg1DefaultSize  = nil,
    bg2DefaultSize  = nil,
    bg3DefaultSize  = nil,
}

local BtnState = {} -- 用來記錄過濾按鈕狀態

--------------------------------------------------------------------------------
-- 工具函數：存取按鈕狀態（此處可提前緩存 CCUserDefault）
--------------------------------------------------------------------------------
local function saveBtnStates(btnState)
    local serializedState = json.encode(btnState)
    CCUserDefault:sharedUserDefault():setStringForKey("RuneWeareBtnStateKey", serializedState)
    CCUserDefault:sharedUserDefault():flush()
end

local function loadBtnStates()
    local serializedState = CCUserDefault:sharedUserDefault():getStringForKey("RuneWeareBtnStateKey")
    if serializedState == "" then return {} end
    return json.decode(serializedState)
end

--------------------------------------------------------------------------------
-- 工具函數：排序符石（依稀有度、星級，再按屬性分數排序）
--------------------------------------------------------------------------------
local function sortFates(fateData_1, fateData_2)
    local conf1 = fateData_1:getConf()
    local conf2 = fateData_2:getConf()
    if conf1.rare ~= conf2.rare then
        return conf1.rare > conf2.rare
    end
    if conf1.star ~= conf2.star then
        return conf1.star > conf2.star
    end
    local score1 = UserEquipManager:calAttrScore(conf1.basicAttr) + UserEquipManager:calAttrScore(fateData_1.attr)
    local score2 = UserEquipManager:calAttrScore(conf2.basicAttr) + UserEquipManager:calAttrScore(fateData_2.attr)
    return score1 > score2
end

--------------------------------------------------------------------------------
-- 工具函數：組合符石屬性條目（基本屬性 + 隨機屬性）
--------------------------------------------------------------------------------
local function getAttributes(conf, randomAttr)
    local attrs = {}
    local basicInfo = common:split(conf.basicAttr, ",")
    local randInfo  = common:split(randomAttr, ",")
    for _, info in ipairs(basicInfo) do
        table.insert(attrs, info)
    end
    for _, info in ipairs(randInfo) do
        if string.find(info, "_") then
            table.insert(attrs, info)
        end
    end
    return attrs
end

--------------------------------------------------------------------------------
-- 工具函數：更新屬性節點
-- showDiff 為 true 時顯示屬性變化（用於裝備列表）；否則只更新當前符石數據
--------------------------------------------------------------------------------
local function updateAttributes(container, attributes, currentData, showDiff)
    for i = 1, 3 do
        if attributes[i] then
            local attr, value = unpack(common:split(attributes[i], "_"))
            NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = true })
            NodeHelper:setSpriteImage(container, { ["mAttrImg" .. i] = "attri_" .. attr .. ".png" })
            NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i] = value })
            if showDiff then
                if currentData and currentData[attr] then
                    local diff = value - currentData[attr]
                    if diff > 0 then
                        NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = "(+" .. diff .. ")" })
                        NodeHelper:setColorForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.PLUS })
                    elseif diff < 0 then
                        NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = "(" .. diff .. ")" })
                        NodeHelper:setColorForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.MINUS })
                    else
                        NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = "" })
                    end
                else
                    NodeHelper:setStringForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = "(+" .. value .. ")" })
                    NodeHelper:setColorForLabel(container, { ["mAttrTxt" .. i .. "_" .. i] = GameConfig.ATTR_CHANGE_COLOR.PLUS })
                end
            else
                if currentData then
                    currentData[attr] = value
                end
            end
        else
            NodeHelper:setNodesVisible(container, { ["mAttrNode" .. i] = false })
        end
    end
end

--------------------------------------------------------------------------------
-- 工具函數：更新符石圖標（背景、圖片、邊框、星級）
--------------------------------------------------------------------------------
local function updateRuneIcon(childNode, conf)
    local sprite2Img = {}
    if conf then
        sprite2Img["mBg"]    = NodeHelper:getImageBgByQuality(conf.rare)
        sprite2Img["mPic"]   = conf.icon
        sprite2Img["mFrame"] = NodeHelper:getImageByQuality(conf.rare)
        NodeHelper:setNodesVisible(childNode, { mLock = false, mPoint = false, mStarNode = true })
        for star = 1, 6 do
            NodeHelper:setNodesVisible(childNode, { ["mStar" .. star] = (star == conf.star) })
        end
    else
        sprite2Img["mBg"]    = "UI/Mask/Image_Empty.png"
        sprite2Img["mPic"]   = "UI/Mask/Image_Empty.png"
        sprite2Img["mFrame"] = "UI/Mask/Image_Empty.png"
        NodeHelper:setNodesVisible(childNode, { mLock = false, mPoint = false, mStarNode = false })
    end
    NodeHelper:setSpriteImage(childNode, sprite2Img)
end

--------------------------------------------------------------------------------
-- FateWearsSelectItem：符石項目操作
--------------------------------------------------------------------------------
local FateWearsSelectItem = {}

function FateWearsSelectItem.onFunction(eventName, container)
    if eventName == "luaInitItemView" then
        FateWearsSelectItem.onRefreshItemView(container)
    elseif eventName == "onEquipRune" then
        FateWearsSelectItem.onEquipRune(container)
    end
end

function FateWearsSelectItem.onRefreshItemView(container)
    local contentId = container:getTag()
    local fateData  = PageInfo.fateIdList[contentId]
    if not fateData then return end

    local conf     = fateData:getConf()
    local fullName = common:getLanguageString(conf.name) .. common:getLanguageString("@Rune")
    local attrs    = getAttributes(conf, fateData.attr)

    -- 保存項目引用，並預解析基本屬性數據以供過濾時使用
    Items[fateData.id] = { container = container, conf = conf }
    local basicEntries = common:split(conf.basicAttr, ",")
    local statusVal = nil
    local attrIds   = {}
    if basicEntries[1] then
        local parts = common:split(basicEntries[1], "_")
        statusVal = tonumber(parts[1])
    end
    for _, entry in ipairs(basicEntries) do
        local parts = common:split(entry, "_")
        table.insert(attrIds, tonumber(parts[1]))
    end
    Items[fateData.id].parsed = {
        rare   = conf.rare,
        status = statusVal,
        attrIds= attrIds,
    }

    updateAttributes(container, attrs, currRuneData, true)

    local strMap    = { mRuneName = fullName }
    local childNode = container:getVarMenuItemCCB("mIcon"):getCCBFile()
    updateRuneIcon(childNode, conf)
    NodeHelper:setStringForLabel(container, strMap)

    if fateData.roleId then
        local curRoleInfo = UserMercenaryManager:getUserMercenaryById(fateData.roleId)
        local itemId = curRoleInfo.itemId
        NodeHelper:setNodesVisible(container, { mBtnNode1 = false, mBtnNode2 = true })
        NodeHelper:setStringForLabel(container, { mHeroName = common:getLanguageString("@HeroName_" .. itemId) })
    else
        NodeHelper:setNodesVisible(container, { mBtnNode1 = true, mBtnNode2 = false })
    end
end

function FateWearsSelectItem.onEquipRune(container)
    local contentId = container:getTag()
    local fateData  = PageInfo.fateIdList[contentId]
    if not fateData then return end

    local msg = MysticalDress_pb.HPMysticalDressChange()
    if PageInfo.currentFateData then
        msg.type       = 3
        msg.offEquipId = PageInfo.currentFateData.id
    else
        msg.type = 1
    end
    msg.roleId    = PageInfo.roleId
    msg.loc       = PageInfo.locPos
    msg.onEquipId = fateData.id
    common:sendPacket(HP_pb.BADGE_DRESS_C, msg)
    MessageBoxPage:Msg_Box("@HasEquiped")
end

--------------------------------------------------------------------------------
-- FateWearsSelectPageBase：頁面主要邏輯
--------------------------------------------------------------------------------
function FateWearsSelectPageBase:onEnter(container)
    PageInfo.fateIdList = FateDataManager:getAllFateList2(PageInfo.roleId) or {}
    table.sort(PageInfo.fateIdList, sortFates)
    self:registerPacket(container)
    self:initPage(container)
    self:showCurrentFateInfo(container)
    self:BuildAllItems(container)

    -- 新手引導
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["RuneSelectPage"] = container
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function FateWearsSelectPageBase:initPage(container)
    NodeHelper:initRawScrollView(container, "mContent")
    local isEquip = (PageInfo.currentFateData ~= nil)
    NodeHelper:setNodesVisible(container, { mPageType1 = isEquip, mPageType2 = not isEquip, mFilter = false })
    currRuneData = {}
end

function FateWearsSelectPageBase:showCurrentFateInfo(container)
    local childNode = container:getVarMenuItemCCB("mIcon"):getCCBFile()
    if PageInfo.currentFateData then
        local conf     = PageInfo.currentFateData:getConf()
        local fullName = common:getLanguageString(conf.name) .. common:getLanguageString("@Rune")
        local attrs    = getAttributes(conf, PageInfo.currentFateData.attr)
        updateAttributes(container, attrs, currRuneData, false)
        local strMap   = { mRuneName = fullName }
        updateRuneIcon(childNode, conf)
        NodeHelper:setStringForLabel(container, strMap)
    else
        updateRuneIcon(childNode, nil)
    end
end

function FateWearsSelectPageBase:BuildAllItems(container)
    NodeHelper:clearScrollView(container)
    local items = nil
    if #PageInfo.fateIdList > 0 then
        items = NodeHelper:buildRawScrollView(container, #PageInfo.fateIdList, ItemInfo.ccbiFile, FateWearsSelectItem.onFunction)
    end

    -- 更新過濾按鈕圖片（根據 BtnState）
    for key, selected in pairs(BtnState) do
        local imageName = selected and "RunePopup_RuneSelect_img5.png" or "RunePopup_RuneSelect_img4.png"
        NodeHelper:setMenuItemImage(container, { ["m" .. key] = { normal = imageName } })
    end

    if items and items[1] then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["RuneSelectItem"] = items[1]
    end
end

function FateWearsSelectPageBase:onDisEquip(container)
    local msg = MysticalDress_pb.HPMysticalDressChange()
    msg.roleId     = PageInfo.roleId
    msg.loc        = PageInfo.locPos
    msg.type       = 2  -- 脫下符石
    msg.offEquipId = PageInfo.currentFateData.id
    common:sendPacket(option.opcode.MYSTICAL_DRESS_CHANGE_C, msg)
    MessageBoxPage:Msg_Box("@RemoveEquip")
end

function FateWearsSelectPageBase:onFilter(container)
    local filterNode = container:getVarNode("mFilter")
    NodeHelper:setNodesVisible(container, { mFilter = not filterNode:isVisible() })
end

function FateWearsSelectPageBase:onReset(container)
    if next(BtnState) then
        for k, _ in pairs(BtnState) do
            BtnState[k] = false
            NodeHelper:setMenuItemImage(container, { ["m" .. k] = { normal = "RunePopup_RuneSelect_img4.png" } })
        end
        saveBtnStates(BtnState)
        self:ContentSync(container)
    end
end

function FateWearsSelectPageBase:onButtonToggle(container, eventName, btnType, btnPrefix)
    local index    = string.sub(eventName, -1)
    local btnKey   = btnType .. index
    local nodeName = btnPrefix .. index

    BtnState[btnKey] = not BtnState[btnKey]
    local imageName  = BtnState[btnKey] and "RunePopup_RuneSelect_img5.png" or "RunePopup_RuneSelect_img4.png"
    NodeHelper:setMenuItemImage(container, { [nodeName] = { normal = imageName } })
    saveBtnStates(BtnState)
    self:ContentSync(container)
end

function FateWearsSelectPageBase:onRare(container, eventName)
    self:onButtonToggle(container, eventName, "Rare", "mRare")
end

function FateWearsSelectPageBase:onAttr(container, eventName)
    self:onButtonToggle(container, eventName, "Attr", "mAttr")
end

function FateWearsSelectPageBase:onStatus(container, eventName)
    self:onButtonToggle(container, eventName, "Status", "mStatus")
end

--------------------------------------------------------------------------------
-- 篩選函數：預先構造查詢表，利用預解析資料過濾項目
--------------------------------------------------------------------------------
local function filterItems(items, btnState)
    local result = {}

    -- 緩存局部方法
    local find   = string.find
    local sub    = string.sub
    local tonumber = tonumber
    local ipairs = ipairs
    local pairs = pairs

    -- 構造查詢表
    local rareFilters, statusFilters, attrFilters = {}, {}, {}
    local rareCount, statusCount, attrCount = 0, 0, 0

    for key, selected in pairs(btnState) do
        if selected then
            if find(key, "Rare") then
                local filterVal = tonumber(sub(key, -1))
                if filterVal then
                    rareFilters[filterVal] = true
                    rareCount = rareCount + 1
                end
            elseif find(key, "Status") then
                local basic = tonumber(sub(key, -1))
                if basic == 1 then
                    basic = 113
                elseif basic == 2 then
                    basic = 114
                end
                statusFilters[basic] = true
                statusCount = statusCount + 1
            elseif find(key, "Attr") then
                local index = tonumber(sub(key, -1))
                local filterVal = attrId[index]
                if filterVal then
                    attrFilters[filterVal] = true
                    attrCount = attrCount + 1
                end
            end
        end
    end

    for id, data in pairs(items) do
        local parsed = data.parsed
        if parsed then
            local matchesRare   = (rareCount == 0 or rareFilters[parsed.rare] == true)
            local matchesStatus = (statusCount == 0 or statusFilters[parsed.status] == true)
            local matchesAttr   = false
            if attrCount == 0 then
                matchesAttr = true
            else
                for _, aId in ipairs(parsed.attrIds) do
                    if attrFilters[aId] then
                        matchesAttr = true
                        break
                    end
                end
            end
            if matchesRare and matchesStatus and matchesAttr then
                result[id] = data.conf
            end
        end
    end

    return result
end

function FateWearsSelectPageBase:ContentSync(container)
    BtnState = loadBtnStates() or {}
    local filteredItems = filterItems(Items, BtnState)
    
    -- 直接遍歷 Items 根據篩選結果更新顯示
    for id, item in pairs(Items) do
        if filteredItems[id] then
            item.container:setContentSize(ItemSize)
            item.container:setVisible(true)
        else
            item.container:setContentSize(CCSizeMake(0, 0))
            item.container:setVisible(false)
        end
    end
    self:BuildAllItems(container)
    print("Content synchronized.")
end

function FateWearsSelectPageBase:onExit(container)
    self:removePacket(container)
    local currentNode = container:getVarNode("mNowNode")
    if currentNode then currentNode:removeAllChildren() end
    NodeHelper:deleteScrollView(container)
end

function FateWearsSelectPageBase:onClose(container)
    PageManager.popPage("FateWearsSelectPage")
end

--------------------------------------------------------------------------------
-- 封包註冊與接收處理
--------------------------------------------------------------------------------
function FateWearsSelectPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcode) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FateWearsSelectPageBase:removePacket(container)
    for key, opcode in pairs(option.opcode) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function FateWearsSelectPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    if opcode == option.opcode.MYSTICAL_DRESS_CHANGE_S then
        PageManager.refreshPage("EquipLeadPage", "refreshPage")
        PageManager.popPage("FateWearsSelectPage")
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    end
end

--------------------------------------------------------------------------------
-- 對外接口：設置角色ID、裝備位置和當前符石資料
--------------------------------------------------------------------------------
function FateWearsSelectPage_setFate(data)
    PageInfo.roleId          = data.roleId
    PageInfo.locPos          = data.locPos
    PageInfo.currentFateData = FateDataManager:getFateDataById(data.currentFateId)
end

--------------------------------------------------------------------------------
-- 通過 CommonPage.newSub 建立新頁面
--------------------------------------------------------------------------------
FateWearsSelectPage = CommonPage.newSub(FateWearsSelectPageBase, "FateWearsSelectPage", option)
return FateWearsSelectPage
