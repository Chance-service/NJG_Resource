----------------------------------------------------------------------------------
-- FriendPageOptimized.lua
-- 優化後的好友面板
----------------------------------------------------------------------------------

-- 模組引用
local Friend_pb           = require "Friend_pb"
local Const_pb            = require "Const_pb"
local HP_pb               = require "HP_pb"
local GameConfig          = require "GameConfig"
local NewbieGuideManager  = require("NewbieGuideManager")
local RoleManager         = require("PlayerInfo.RoleManager")
local json                = require('json')
local UserInfo            = require("PlayerInfo.UserInfo")
local NodeHelper          = require("NodeHelper")
local ViewPlayerInfo      = require("PlayerInfo.ViewPlayerInfo")
local CommonPage          = require("CommonPage")
local FriendManager       = require("FriendManager")


-- 畫面名稱與常量定義
local thisPageName        = "FriendPage"
local FRIEND_MAX_NUM      = 50
local SORT_IMG_ASC        = "Friends_btn_03_1.png"   -- 升序圖標
local SORT_IMG_DESC       = "Friends_btn_03_0.png"   -- 降序圖標
local EDITING_IMG         = "Friends_btn_02.png"     -- 編輯中圖標
local NOTEDITING_IMG      = "Friends_btn_01.png"     -- 非編輯中圖標

-- 狀態變數
local isRaise             = true      -- 升/降序標記
local isEditMode          = false     -- 編輯模式標記
local ChooseIndex         = {}        -- 編輯模式中選中的好友 id 集合

-- 畫面配置
local option = {
    ccbiFile = "FriendPage.ccbi",
    entermateCcbiFile = "FriendPage_KR.ccbi",
    handlerMap = {
        onSearchFriend    = "onSearchFriend",
        onFriendRecommend = "onFriendRecommend",
        onGetAllGift      = "onGetAllGift",
        onSendAllGift     = "onSendAllGift",
        onHelp            = "onHelp",
        onClose           = "onClose",
        onSort            = "onSort",
        onEdit            = "onEdit",
        onDeleteAll       = "onDeleteAll"
    },
    opcodes = {
        FRIEND_POINT_GET_S = HP_pb.FRIEND_POINT_GET_S,
        FRIEND_POINT_GIFT_S = HP_pb.FRIEND_POINT_GIFT_S,
    }
}

----------------------------------------------------------------------------------
-- 工具函數
----------------------------------------------------------------------------------

-- 調整多個 Scale9Sprite 節點（自適應尺寸）
local function adjustScale9Sprites(container, spriteNames)
    for _, name in ipairs(spriteNames) do
        local sprite = container:getVarScale9Sprite(name)
        if sprite then
            container:autoAdjustResizeScale9Sprite(sprite)
        end
    end
end

-- 排序好友列表，根據 offlineTime、level 與 playerId
local function sortFriendList(list)
    table.sort(list, function(a, b)
        local a_off = a.offlineTime
        local b_off = b.offlineTime
        if a_off == b_off then
            if a.level ~= b.level then
                return a.level > b.level
            else
                return a.playerId < b.playerId
            end
        else
            if isRaise then
                return a_off < b_off
            else
                return a_off > b_off
            end
        end
    end)
end

----------------------------------------------------------------------------------
-- mercenaryHeadContent: 負責刷新頭像節點內容
----------------------------------------------------------------------------------
local mercenaryHeadContent = {
    ccbiFile = "FormationTeamContent.ccbi"
}

function mercenaryHeadContent:refreshItem(container, info)
    local roleIcon = ConfigManager.getRoleIconCfg()
    local trueIcon = GameConfig.headIconNew or info.headIcon

    if not roleIcon[trueIcon] then
        local icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
        if NodeHelper:isFileExist(icon) then
            NodeHelper:setSpriteImage(container, { mHead = icon })
        end
        NodeHelper:setStringForLabel(container, { mLv = info.level })
    else
        NodeHelper:setSpriteImage(container, { mHead = roleIcon[trueIcon].MainPageIcon })
        NodeHelper:setStringForLabel(container, { mLv = info.level })
    end

    NodeHelper:setNodesVisible(container, {
        mClass = false, mElement = false, mMarkFighting = false,
        mMarkChoose = false, mMarkSelling = false, mMask = false,
        mSelectFrame = false, mStageImg = false
    })
end

----------------------------------------------------------------------------------
-- FriendItem: 單個好友項目
----------------------------------------------------------------------------------
local FriendItem = {
    ccbiFile = "FriendContent.ccbi",
    entermateCcbiFile = "FriendContent_KR.ccbi",
}

function FriendItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- 更新好友項目的內容
function FriendItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local friendId = self.id
    local info = FriendManager.getFriendInfoById(friendId)
    if not info then return end

    local lb2Str = {
        mName         = info.name,
        mLevelNum     = UserInfo.getOtherLevelStr(info.rebirthStage, info.level),
        mFightingNum  = GameUtil:formatDotNumber(info.fightValue)
    }
    if info.offlineTime and info.offlineTime >= 1 then
        lb2Str.mLastLandTime = common:getLanguageString("@FriendLastTimeTxt", common:secondToDateXX(info.offlineTime, 7))
        NodeHelper:setColorForLabel(container, { mLastLandTime = "247 18 228" })
    else
        lb2Str.mLastLandTime = common:getLanguageString("@FriendOnlineTxt")
        NodeHelper:setColorForLabel(container, { mLastLandTime = "0 224 0" })
    end

    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setMenuItemEnabled(container, "mGetGift", info.haveGift)
    NodeHelper:setMenuItemEnabled(container, "mSendGift", info.canGift)

    -- 創建並更新頭像節點
    local headNode = ScriptContentBase:create(mercenaryHeadContent.ccbiFile)
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildren()
    mercenaryHeadContent:refreshItem(headNode, info)
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:addChild(headNode)

    -- 根據編輯模式顯示按鈕與選中狀態
    NodeHelper:setNodesVisible(container, { mSelectBtn = isEditMode, mBtns = not isEditMode })
    local isSelected = ChooseIndex[self.id] or false
    NodeHelper:setNodesVisible(container, { mSelectImg = isSelected })
end

-- 同意好友申請
function FriendItem:onSure(container)
    FriendManager.agreeApply(self.id)
end

-- 編輯模式下切換選中狀態
function FriendItem:onSelect(container)
    ChooseIndex[self.id] = not ChooseIndex[self.id]
    NodeHelper:setNodesVisible(container, { mSelectImg = ChooseIndex[self.id] })
end

-- 進入私聊
function FriendItem:onSendMail(container)
    local id = self.id
    local info = FriendManager.getFriendInfoById(id)
    local ChatManager = require("Chat.ChatManager")
    local chatUnit = Friend_pb.MsgBoxUnit()
    resetMenu("mChatBtn", true)
    chatUnit.playerId   = id
    chatUnit.name       = info.name
    chatUnit.level      = info.level
    chatUnit.roleItemId = info.roleId
    chatUnit.avatarId   = info.avatarId
    chatUnit.headIcon   = info.headIcon

    if isSaveChatHistory then
        ChatManager.insertSortChatPrivate(id)
    end
    ChatManager.insertPrivateMsg(id, chatUnit, nil, false, false)
    ChatManager.setCurrentChatPerson(id)
    PageManager.popAllPage()
    if MainFrame:getInstance():getCurShowPageName() ~= "ChatPage" then
        BlackBoard:getInstance():delVarible("PrivateChat")
        BlackBoard:getInstance():addVarible("PrivateChat", "PrivateChat")
        PageManager.pushPage("ChatPage")
    end
    PageManager.refreshPage("ChatPage", "PrivateChat")
end

-- 領取好友禮物
function FriendItem:onGetGift(container)
    local info = FriendManager.getFriendInfoById(self.id)
    if info and info.haveGift then
        FriendManager.requestGiftFrom(self.id)
    end
end

-- 送出好友禮物
function FriendItem:onSendGift(container)
    local info = FriendManager.getFriendInfoById(self.id)
    if info and info.canGift then
        FriendManager.requestGiftTo(self.id)
    end
end

-- 刪除好友
function FriendItem:onDelete(container)
    FriendManager.deleteById(self.id)
end

-- 點擊查看好友詳情（如有需要可啟用）
function FriendItem:onViewDetail(container)
    -- local id = self.id
    -- FriendManager.setViewPlayerId(id)
    -- ViewPlayerInfo:getInfo(id)
end

----------------------------------------------------------------------------------
-- FriendPageBase: 好友面板主頁面
----------------------------------------------------------------------------------
local FriendPageBase = {}

function FriendPageBase:onLoad(container)
    local ccbiFile = (not Golb_Platform_Info.is_entermate_platform) and option.ccbiFile or option.entermateCcbiFile
    container:loadCcbiFile(ccbiFile)
    container.scrollview = container:getVarScrollView("mContent")
    adjustScale9Sprites(container, {"mScale9Sprite2", "mScale9Sprite3"})
end

function FriendPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10)
    NodeHelper:setNodesVisible(container, {
        mRecommendPoint = FriendManager.needCheckNotice(),
        mSearchNode     = not isEditMode,
        mDelNode        = isEditMode
    })
    self:onRequestData(container)
    isRaise = true
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FRIEND)
end

function FriendPageBase:onRequestData(container)
    FriendManager.requestFriendList()
end

function FriendPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_FRIEND)
end

function FriendPageBase:getKakaoFriendsList()
    FriendPageBase.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)
    libPlatformManager:getPlatform():OnKrgetFriendLists()
end

-- 切換排序（升/降序）
function FriendPageBase:onSort(container)
    isRaise = not isRaise
    local sortImg = isRaise and SORT_IMG_ASC or SORT_IMG_DESC
    NodeHelper:setNormalImage(container, "mSort", sortImg)
    self:rebuildAllItem(container)
end

-- 編輯模式切換
function FriendPageBase:onEdit(container)
    isEditMode = not isEditMode
    NodeHelper:setNodesVisible(container, { mSearchNode = not isEditMode, mDelNode = isEditMode })
    local sortImg = isEditMode and EDITING_IMG or NOTEDITING_IMG
    NodeHelper:setNormalImage(container, "mEdit", sortImg)
    ChooseIndex = {}  -- 重置選中狀態
    self:rebuildAllItem(container)
end

-- 編輯模式下批量刪除選中好友
function FriendPageBase:onDeleteAll(container)
    local ids = {}
    for id, selected in pairs(ChooseIndex) do
        if selected then
            table.insert(ids, tonumber(id))
        end
    end
    if next(ids) then
        FriendManager.deleteByIds(ids)
    end
end

function FriendPageBase:onExecute(container)
    -- 如有需要，可補充額外執行邏輯
end

function FriendPageBase:onExit(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:deleteScrollView(container)
end

function FriendPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

----------------------------------------------------------------------------------
-- 數據刷新與滾動列表構建
----------------------------------------------------------------------------------
function FriendPageBase:refreshPage(container)
    local friendList = FriendManager.getFriendList()
    local friendSize = #friendList
    local hasFriend = friendSize > 0

    local canGift  = self:isAnyCanGift(friendList)
    local haveGift = self:isAnyHaveGift(friendList)
    NodeHelper:setNodesVisible(container, {
        mScale9Sprite2 = hasFriend,
        NoFriendTxt    = not hasFriend,
        NoFriendSprite = not hasFriend,
        mGiftPoint     = canGift or haveGift,
    })

    local onlineSize = 0
    for _, info in ipairs(friendList) do
        if not info.offlineTime or info.offlineTime == 0 then
            onlineSize = onlineSize + 1
        end
    end

    local friendshipPoint = UserInfo.stateInfo.friendship or 0
    local lb2Str = {
        mFriendPointNum  = tostring(friendshipPoint),
        mFriendLimitNum  = common:getLanguageString('@FriendNumLimitTxt', tostring(friendSize)),
        mFriendOnlineNum = common:getLanguageString('@Friend.currentOnlineNumDesc', tostring(onlineSize))
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setMenuItemEnabled(container, "mGetAllGift", haveGift)
    NodeHelper:setMenuItemEnabled(container, "mSendAllGift", canGift)

    -- 刷新後退出編輯模式
    isEditMode = false
    NodeHelper:setNodesVisible(container, { mSearchNode = not isEditMode, mDelNode = isEditMode })

    local sortImg = isEditMode and EDITING_IMG or NOTEDITING_IMG
    NodeHelper:setNormalImage(container, "mEdit", sortImg)
end

function FriendPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function FriendPageBase:clearAllItem(container)
    container.mScrollView:removeAllCell()
end

function FriendPageBase:buildItem(container)
    local list = FriendManager.getFriendList()
    sortFriendList(list)
    local friendSize = #list
    print(list)
    local ccbiFile = FriendItem.ccbiFile
    if friendSize < 1 or not ccbiFile or ccbiFile == '' then
        return
    end

    for _, friendInfo in ipairs(list) do
        local cell = CCBFileCell:create()
        local panel = FriendItem:new({ id = friendInfo.playerId })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(ccbiFile)
        container.mScrollView:addCellBack(cell)
    end
    container.mScrollView:orderCCBFileCells()
end

----------------------------------------------------------------------------------
-- 點擊事件處理
----------------------------------------------------------------------------------
function FriendPageBase:onSearchFriend(container)
    if #FriendManager.getFriendList() >= FRIEND_MAX_NUM then
        MessageBoxPage:Msg_Box("@FriendNumReachLimitTxt")
        return
    end
    PageManager.pushPage("FriendSearchPopPage")
end

function FriendPageBase:onFriendRecommend(container)
    PageManager.pushPage("FriendApplyPage")
end

function FriendPageBase:onGetAllGift(container)
    local friendList = FriendManager.getFriendList()
    if #friendList == 0 then
        MessageBoxPage:Msg_Box_Lan("@Eighteentip2")
    else
        if self:isAnyHaveGift(friendList) then
            FriendManager.requestGiftFrom(0)
        else
            MessageBoxPage:Msg_Box_Lan("@Eighteentip2")
        end
    end
end

function FriendPageBase:onSendAllGift(container)
    local friendList = FriendManager.getFriendList()
    if #friendList == 0 then
        MessageBoxPage:Msg_Box_Lan("@Eighteentip2")
    else
        if self:isAnyCanGift(friendList) then
            FriendManager.requestGiftTo(0)
        else
            MessageBoxPage:Msg_Box_Lan("@Eighteentip2")
        end
    end
end

----------------------------------------------------------------------------------
-- 回包處理
----------------------------------------------------------------------------------
function FriendPageBase:onReceivePacket(container)
    local opcode  = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.FRIEND_POINT_GET_S then
        local msg = Friend_pb.HPGetFriendshipRes()
        msg:ParseFromString(msgBuff)
        FriendManager.requestFriendList()
        local tipKey = (msg.friendId == 0) and "@FriendpointGetall" or "@FriendpointGet"
        MessageBoxPage:Msg_Box_Lan(tipKey)
    elseif opcode == HP_pb.FRIEND_POINT_GIFT_S then
        local msg = Friend_pb.HPGiftFriendshipReq()
        msg:ParseFromString(msgBuff)
        FriendManager.requestFriendList()
        local tipKey = (msg.friendId == 0) and "@FriendpointSendall" or "@FriendpointSend"
        MessageBoxPage:Msg_Box_Lan(tipKey)
    end
end

----------------------------------------------------------------------------------
-- 訊息監聽處理 (使用分派表簡化 if/else 結構)
----------------------------------------------------------------------------------
local messageDispatch = {
    [FriendManager.onNewFriendApply] = function(container)
        NodeHelper:setNodesVisible(container, { mRecommendPoint = true })
    end,
    [FriendManager.onNoticeChecked] = function(container)
        NodeHelper:setNodesVisible(container, { mRecommendPoint = false })
    end,
    [FriendManager.onSyncList] = function(container, self)
        self:refreshPage(container)
        self:rebuildAllItem(container)
    end,
}

function FriendPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    if message:getTypeId() == MSG_MAINFRAME_REFRESH then
        local trueMsg = MsgMainFrameRefreshPage:getTrueType(message)
        if trueMsg.pageName == thisPageName then
            local dispatcher = messageDispatch[trueMsg.extraParam]
            if dispatcher then
                dispatcher(container, self)
            end
        end
    end
end

----------------------------------------------------------------------------------
-- 封包註冊與移除
----------------------------------------------------------------------------------
function FriendPageBase:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function FriendPageBase:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if key:sub(-1) == "S" then
            container:removePacket(opcode)
        end
    end
end

----------------------------------------------------------------------------------
-- 工具函數：檢查是否存在可送/可領禮物的好友
----------------------------------------------------------------------------------
function FriendPageBase:isAnyCanGift(friendList)
    for _, info in ipairs(friendList) do
        if info.canGift then
            return true
        end
    end
    return false
end

function FriendPageBase:isAnyHaveGift(friendList)
    for _, info in ipairs(friendList) do
        if info.haveGift then
            return true
        end
    end
    return false
end

----------------------------------------------------------------------------------
-- 模塊導出：繼承 CommonPage 創建新頁面
----------------------------------------------------------------------------------
local FriendPage = CommonPage.newSub(FriendPageBase, thisPageName, option)
return FriendPage
