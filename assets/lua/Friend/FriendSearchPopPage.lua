--[[ 
    FriendSearchPopPage
--]]

-- 模組引用
local NodeHelper          = require("NodeHelper")
local FriendManager       = require("FriendManager")
local FriendSearchResult  = require("FriendSearchResult")
local FriendRecommend_pb  = require('FriendRecommend_pb')
local CommonPage          = require('CommonPage')
local HP_pb               = require("HP_pb")
local Friend_pb           = require("Friend_pb")

-- 當前頁面名稱與 ccbi 設定
local thisPageName = 'FriendSearchPopPage'
local option = {
    ccbiFile   = "FriendSearchPopUp.ccbi",
    handlerMap = {
        onClose             = 'onClose',
        onSearch            = 'onSearch',
        onInPutBtn          = 'onInPutBtn',
        onRefresh           = 'onRefresh',
        luaInputboxEnter    = 'onInputboxEnter',
        luaonCloseKeyboard  = "luaonCloseKeyboard",
        onChoiceIDBtn       = "onChoiceIDBtn",
        onChoiceNameBtn     = "onChoiceNameBtn"
    },
    opcodes = {
        FRIEND_FIND_S            = HP_pb.FRIEND_FIND_S,
        RECOMMEND_FRIEND_LIST_S  = HP_pb.RECOMMEND_FRIEND_LIST_S,
    }
}

-- 常數定義
local FRIEND_SEARCH_ID_MAX  = 100000000
local NAME_MAX_CHARACTERS   = 20

-- 狀態變數（僅在此模組內使用）
local searchMode   = "id"   -- "id" 或 "name"
local searchInput  = ""
local friendsList  = {}
FriendSendedList   = {}
-- Friend 項目的設定
local FriendItem = { ccbiFile = 'FriendApplicationContent.ccbi' }

--===========================================================================
-- 工具函數
--===========================================================================

-- 替代 MessageBoxPage 的簡單提示函數
local function showMessage(messageKey)
    -- 此處僅作日誌輸出，根據需求可以改成彈窗提示或其他方式
    CCLuaLog("提示: " .. messageKey)
end

local function validateIdInput(input)
    local id = tonumber(input)
    if not id or id >= FRIEND_SEARCH_ID_MAX then
        showMessage('@GuildInputSearchNumber')
        return false
    end
    return true
end

local function validateNameInput(input)
    local length = GameMaths:calculateStringCharacters(input)
    if length > NAME_MAX_CHARACTERS then
        showMessage("@GuildAnnouncementTooLong")
        return false
    elseif GameMaths:isStringHasUTF8mb4(input) then
        showMessage("@NameHaveForbbidenChar")
        return false
    end
    return true
end

local function getSearchHint()
    return searchMode == "id" and '@FriendInputHintTex' or '@searchFriendByNameHint'
end

--===========================================================================
-- FriendSearchBase 主要功能
--===========================================================================

local FriendSearchBase = {}

function FriendSearchBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function FriendSearchBase:onEnter(container)
    self:registerPacket(container)
    container:registerLibOS()

    -- 預設搜尋模式為 ID 搜尋
    searchMode  = "id"
    searchInput = ""
    self:refreshPage(container)

    -- 根據平台設定編輯框
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        self:setupEditBox(container)
    end

    self:getFriendList(container)
    self:onChoiceIDBtn(container)
end

function FriendSearchBase:setupEditBox(container)
    -- 創建編輯框並綁定事件
    FriendSearchBase.editBox = NodeHelper:addEditBox(
        CCSize(470, 40), 
        container:getVarNode("mDecisionTex"), 
        function(eventType)
            if eventType == "began" then
                FriendSearchBase.editBox:setText(searchInput)
            elseif eventType == "ended" or eventType == "return" then
                FriendSearchBase.onEditBoxReturn(container, FriendSearchBase.editBox, FriendSearchBase.editBox:getText())
                NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
            elseif eventType == "changed" then
                FriendSearchBase.onEditBoxReturn(container, FriendSearchBase.editBox, FriendSearchBase.editBox:getText(), true)
            end
        end, 
        ccp(-235, 0), 
        common:getLanguageString(getSearchHint())
    )

    container:getVarNode("mDecisionTex"):setVisible(false)
    container:getVarNode("mDecisionTexHint"):setVisible(false)
    NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })

    local color = StringConverter:parseColor3B("135 54 38")
    FriendSearchBase.editBox:setFontColor(color)
    FriendSearchBase.editBox:setText("")
    FriendSearchBase.editBox:setMaxLength(NAME_MAX_CHARACTERS)
    NodeHelper:setMenuItemEnabled(container, "mInputBtn", false)
end

function FriendSearchBase:onExit(container)
    searchInput = ""
    container:removeLibOS()
end

function FriendSearchBase:onRefresh(container)
    self:getFriendList(container)
end

function FriendSearchBase:refreshPage(container)
    local lb2Str = {
        mTitle         = common:getLanguageString('@FriendSearch'),
        mDes           = common:getLanguageString('@FriendSearchExplain'),
        mDecisionTexHint = common:getLanguageString(getSearchHint())
    }
    NodeHelper:setStringForLabel(container, lb2Str)

    local visibleMap = {
        mLastBtnNode   = true,
        mSearch        = true,
        mChangeNameNode = false
    }
    NodeHelper:setNodesVisible(container, visibleMap)
end

function FriendSearchBase:BuildScrollview(container)
    local scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()

    for k, data in pairs(friendsList) do
        if type(k) == 'number' then 
            local cell  = CCBFileCell:create()
            cell:setCCBFile(FriendItem.ccbiFile)
            local panel = common:new({ Info = data }, FriendItem)
            cell:registerFunctionHandler(panel)
            scrollview:addCell(cell)
        end
    end

    scrollview:orderCCBFileCells()
end

--===========================================================================
-- FriendItem 顯示邏輯
--===========================================================================

function FriendItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local stringTable = {
        mName       = self.Info.name,
        mFightingNum= self.Info.fightValue,
    }
    local visibleMap = {
        mBtns          = false,
        mApplyBtn      = true,
        mLastLandTime  = false,
        mLevelNum      = false,
    }

    NodeHelper:setMenuItemEnabled(container, "mApply", not FriendSendedList[self.Info.playerId] or false)
    NodeHelper:setStringForLabel(container, stringTable)
    NodeHelper:setNodesVisible(container, visibleMap)

    -- 設置頭像
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildrenWithCleanup(true)
    local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:addChild(headNode)

    local headVisibles = {
        mClass    = false, mElement  = false, mMarkFighting = false, mMarkChoose = false, 
        mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false, mLvNode = true
    }
    NodeHelper:setNodesVisible(headNode, headVisibles)
    
    local icon = common:getPlayeIcon(1, self.Info.headIcon or 1000)
    if NodeHelper:isFileExist(icon) then
        NodeHelper:setSpriteImage(headNode, { mHead = icon })
    end
    NodeHelper:setStringForLabel(headNode, { mLv = self.Info.level })
end

function FriendItem:onApply(container)
    NodeHelper:setMenuItemEnabled(container, "mApply", false)
    FriendManager.sendApplyById(self.Info.playerId)
end

--===========================================================================
-- 事件處理函數
--===========================================================================

function FriendSearchBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function FriendSearchBase:onSearch(container)
    if searchInput == "" then
        showMessage(searchMode == "id" and "@FriendInputNoneTxt" or "@searchFriendByNameInput")
        return
    end

    if searchMode == "id" then
        local id = tonumber(searchInput)
        if not id then
            CCLuaLog("FriendSearchBase:onSearch - Invalid id: " .. tostring(searchInput))
            showMessage("@FriendInputNoneTxt")
            return
        end

        if FriendManager.getFriendInfoById(id).playerId then
            showMessage("@AlreadyBeFriendTxt")
            return
        end

        FriendManager.searchFriendById(id)
    else -- name 搜尋
        if FriendManager.getFriendInfoByName(searchInput).playerId then
            showMessage("@AlreadyBeFriendTxt")
            return
        end

        FriendManager.searchFriendByName(searchInput)
    end
end

function FriendSearchBase.onEditBoxReturn(container, editBox, content, isChange)
    if searchMode == "id" then
        if not validateIdInput(content) then
            searchInput = ""
            editBox:setText(searchInput)
            NodeHelper:setStringForTTFLabel(container, { mDecisionTex = "" })
            return
        end
        searchInput = tostring(math.floor(tonumber(content)))
    else
        if not validateNameInput(content) then
            editBox:setText("")
            return
        end
        searchInput = content
    end

    NodeHelper:setStringForTTFLabel(container, { mDecisionTex = searchInput })
    NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
end

function FriendSearchBase:getFriendList(container)
    common:sendEmptyPacket(HP_pb.RECOMMEND_FRIEND_LIST_C, false)
end

function FriendSearchBase:onInPutBtn(container)
    libOS:getInstance():showInputbox(false, "")
    NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
    NodeHelper:cursorNode(container, "mDecisionTex", true)
end

function FriendSearchBase:luaonCloseKeyboard(container)
    CCLuaLog("FriendSearchBase:luaonCloseKeyboard")
    NodeHelper:cursorNode(container, "mDecisionTex", false)
end

function FriendSearchBase:onInputboxEnter(container)
    local content = container:getInputboxContent()
    if searchMode == "id" then
        if not validateIdInput(content) then return end
    else
        if not validateNameInput(content) then return end
    end

    searchInput = content
    NodeHelper:setStringForTTFLabel(container, { mDecisionTex = searchInput })
    NodeHelper:setNodesVisible(container, { mDecisionTexHint = false })
    NodeHelper:cursorNode(container, "mDecisionTex", true)
end

function FriendSearchBase:onReceivePacket(container)
    local opcode  = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.FRIEND_FIND_S then
        local msg = Friend_pb.FriendItem()
        msg:ParseFromString(msgBuff)
        FriendSearchResultBase_onSearchResult(msg)
        --self:onClose(container)
    elseif opcode == HP_pb.RECOMMEND_FRIEND_LIST_S then
        local msg = FriendRecommend_pb.HPFriendRecommendRet()
        msg:ParseFromString(msgBuff)
        friendsList = msg.friendRecommendItem or {}
        self:BuildScrollview(container)
    end
end

function FriendSearchBase:onChoiceIDBtn(container)
    searchMode  = "id"
    searchInput = ""
    self:updateInputUI(container)
end

function FriendSearchBase:onChoiceNameBtn(container)
    searchMode  = "name"
    searchInput = ""
    self:updateInputUI(container)
end

function FriendSearchBase:updateInputUI(container)
    local hintText = common:getLanguageString(getSearchHint())

    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 or Golb_Platform_Info.is_win32_platform then
        FriendSearchBase.editBox:setText(searchInput)
        FriendSearchBase.editBox:setPlaceHolder(hintText)
    else
        NodeHelper:setStringForTTFLabel(container, { mDecisionTex = searchInput, mDecisionTexHint = hintText })
        NodeHelper:setNodesVisible(container, { mDecisionTexHint = true })
    end

    -- 更新選中狀態 (mIdChoice02 與 mNameChoice02 為 UI 標示元件)
    NodeHelper:setNodesVisible(container, { mIdChoice02 = (searchMode == "id") })
    NodeHelper:setNodesVisible(container, { mNameChoice02 = (searchMode == "name") })
end

-- 註冊與反註冊封包
function FriendSearchBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FriendSearchBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then
            container:removePacket(opcode)
        end
    end
end

--===========================================================================
-- 模組初始化：創建子頁面
--===========================================================================

local FriendSearchPopPage = CommonPage.newSub(FriendSearchBase, thisPageName, option)
return FriendSearchPopPage
