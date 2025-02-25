local HP_pb = require("HP_pb")
local SecretMsg_pb = require("SecretMsg_pb")
require("SecretMessage.SecretMessageManager")
local thisPageName = "SecretMessage.SecretMessagePage"
local UserMercenaryManager = require("UserMercenaryManager")
local AlbumIndivualPage=require("Album.AlbumSubPage_Indiviual")
local ItemManager = require("Item.ItemManager")
----------------------------------------------------------
-- CONST
local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)
local MAIN_PAGE_ITEM_SIZE = CCSize(650, 145)
local CHAT_MSG_WIDTH = 460
local CHAT_BG_SPACING = 20
local CHAT_CCB_SPACING = 5
local CHAT_CCB_MIN_HEIGHT = 120
local CHAT_CCB_WIDTH = 650
local CHAT_SCROLLVIEW_BASE_POSY = 120

local TYPING_SOUND=""

local Canloop=false
local AlbumData
----------------------------------------------------------
local opcodes = {
        --SECRET_MESSAGE_ACTION_C = HP_pb.SECRET_MESSAGE_ACTION_C, -- 請求回答訊息
        SECRET_MESSAGE_ACTION_S = HP_pb.SECRET_MESSAGE_ACTION_S, -- 返回回答訊息
}

local option = {
    ccbiFile = "SecretMessage.ccbi",
    handlerMap =
    {
        onAlbum = "onAlbum",
        onReturn = "onReturn",
        onFilter = "onFilter",
        onReturnToMainPage = "onReturnToMainPage",
        onHelp = "onHelp",
        onPhoto = "onPhoto",
        onCloseImage = "onCloseImage"
    },
    opcode = opcodes
}
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end
for i = 1, 2 do
    option.handlerMap["onAnswer" .. i] = "onAnswer"
end
----------------------------------------------------------
local SecretMessagePage = {}
local SecretMessageItems = {}
local ChatItems = {}

local heroCfg = ConfigManager.getNewHeroCfg()
local AlbumCfg = ConfigManager.getAlbumData()
local mainContainer = nil
local mainPageElement = 0
local mainPageClass = 0
local nowPageType = GameConfig.SECRET_PAGE_TYPE.MAIN_PAGE
local nowChatId = 0
local oriChatScrollViewHeight = 0
local answerBgHeight = 0

local chatMsgTotalHeight = 0

local Answered = false

local Old_heroData = nil
local OldPoint = {}
local PicTable={}
local keyTable={ }
local tabData
local GetPower
----------------------------------------------------------
-- MAIN PAGE ITEM
local SecretMessageItem = {
    ccbiFile = "SecretMessageContent.ccbi",
}
function SecretMessageItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SecretMessageItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function SecretMessageItem:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function SecretMessageItem:refresh()
    local albumCount = 0
    if self.container == nil then
        return
    end
    local txt = self.isNew and common:getLanguageString(self.data.questionStr) or common:getLanguageString(self.data.endStr)
    local count = utf8Sub(txt, 26)
    local subStr = string.sub(txt, 1, count) .. "..."
    NodeHelper:setNodesVisible(self.container, {mRedPoint = false})
    NodeHelper:setSpriteImage(self.container, {mHeadIcon = "UI/Role/Portrait_" .. string.format("%02d", self.data.itemId) .. "000.png"})
    NodeHelper:setStringForLabel(self.container, {mTitle = common:getLanguageString("@HeroName_" .. self.data.itemId),
        mContent = subStr})

    local AlbumData=SecretMessageManager_getAlbumData(self.data.itemId)
    local txt = AlbumData.UnLockCount .. "/ "..AlbumData.ImgCount
    NodeHelper:setStringForLabel(self.container, {mNum = txt})

    -- 新手教學
    if self.data.itemId == 1 then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["SecretMessageItemFire1"] = self.container
    end
end
function utf8Sub(str, n)
    local i = 1
    local len = #str
    local count = 0
    
    while count < n and i <= len do
        count = count + 1
        local byte = string.byte(str, i)
        if byte >= 240 then
            i = i + 4
        elseif byte >= 224 then
            i = i + 3
        elseif byte >= 192 then
            i = i + 2
        else
            i = i + 1
        end
    end
    
    return i - 1
end

function SecretMessageItem:onClick(container)
    Canloop=false
    nowPageType = GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE
    nowChatId = self.data.itemId
    SecretMessagePage:onRefreshPage(mainContainer, true)
end
----------------------------------------------------------
-- CHAT PAGE ITEM
local ChatMessageItem = {
    ccbiFileLeft = "SecretMessageChatLeftContent.ccbi",
    ccbiFileRight = "SecretMessageChatRightContent.ccbi",
}
function ChatMessageItem:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ChatMessageItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function ChatMessageItem:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function ChatMessageItem:refresh()
    if self.container == nil then
        return
    end
    local msg = self.msg
    local FileName
    if string.find(msg, "Pic") then
        FileName = ChatMessageItem:getFileName(msg)
        NodeHelper:setNodesVisible(self.container, {mTexNode = false, mPhoto = true})
        NodeHelper:setSpriteImage(self.container, {mPhotoImg = "UI/Common/Album/" .. FileName .. ".jpg"})
        self.FileName = "UI/Common/Album/FullSprite/" .. FileName .. ".jpg"
    else
        NodeHelper:setNodesVisible(self.container, {mTexNode = true, mPhoto = false})
        --local lastContainer = ChatItems[#ChatItems].node:getCCBFileNode()
        --lastContainer:runAnimation("Default Timeline")
    end
    if not self.isMine then
        NodeHelper:setSpriteImage(self.container, {mHeadImg = "UI/Role/Portrait_" .. string.format("%02d", self.itemId) .. "000.png"})
    else
        NodeHelper:setSpriteImage(self.container, {mHeadImg = "UI/Role/Portrait_99900.png"})
    end
    local parentNode = self.container:getVarLabelTTF("mInputTex")
    parentNode:removeAllChildrenWithCleanup(true)
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", self.msg), 0, CCSizeMake(CHAT_MSG_WIDTH, 200))
    local htmlHeight = msgHtml:getContentSize().height
    local msgBgHeight = htmlHeight + CHAT_BG_SPACING * 2
    local bg = self.container:getVarScale9Sprite("mChatBG")
    bg:setContentSize(CCSize(CHAT_MSG_WIDTH + CHAT_BG_SPACING * 2, msgBgHeight))
    local ccbHeight = math.max(CHAT_CCB_MIN_HEIGHT, msgBgHeight + CHAT_CCB_SPACING * 2)
    
    local img = self.container:getVarSprite("mHeadImg")
    img:getParent():setPositionY(ccbHeight / 2)
    bg:getParent():setPositionY(ccbHeight / 2)
    
    self.height = ccbHeight
end
function ChatMessageItem:onPhoto(container, isGuide)
    --NodeHelper:setNodesVisible(mainContainer, {mPhotoNode = true})
    --NodeHelper:setSpriteImage(mainContainer, {mBigPhoto = self.FileName})
    local photoPage=require('AlbumPhotoDisplay')
    photoPage:PhotoInfo(self.FileName)
    PageManager.pushPage('AlbumPhotoDisplay')
end
function SecretMessagePage:onCloseImage()
    NodeHelper:setNodesVisible(mainContainer, {mPhotoNode = false})
end
function ChatMessageItem:getFileName(msg)
    local tmp = common:split(msg, "_")
    local fileName = ""
    local fileType = ""
    local heroId = string.sub(tmp[2], 2, 3)
    local fileIndex = string.sub(tmp[2], 4, 5)
    
    if string.sub(tmp[2], 1, 1) == "1" then
        fileType = "intimacy"
    elseif string.sub(tmp[2], 1, 1) == "2" then
        fileType = "love"
    elseif string.sub(tmp[2], 1, 1) == "3" then
        fileType = "sexy"
    end
    
    fileName = fileType .. "_" .. heroId .. "_" .. fileIndex
    return fileName
end

function ChatMessageItem:calItemHeight(msg)
    local tempNode = CCNode:create()
    local htmlModel = FreeTypeConfig[702].content
    local msgHtml = NodeHelper:addHtmlLable(tempNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", msg), 0, CCSizeMake(CHAT_MSG_WIDTH, 200))
    local htmlHeight = msgHtml:getContentSize().height
    local msgBgHeight = htmlHeight + CHAT_BG_SPACING * 2
    local ccbHeight = math.max(CHAT_CCB_MIN_HEIGHT, msgBgHeight + CHAT_CCB_SPACING * 2)
    return ccbHeight
end
----------------------------------------------------------
function SecretMessagePage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function SecretMessagePage:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container, eventName)
        end
    end)
    
    return container
end
function SecretMessagePage:onEnter(container)

    local msg = SecretMsg_pb.secretMsgRequest()
    msg.action = 0
    common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, false)

    AlbumData=SecretMessageManager_getAlbumData(nowChatId)
    self:getPower()
     if not GetPower then
       GetPower = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            self:getPower()
            end, 30 , false)
     end

    NodeHelper:setNodesVisible(container, {mAnswerNode = false})
    PicTable={}
    tabData=parentPage
    --self:UserSync()
    SecretMessageManager_initLanguage()
    mainContainer = container
    self:registerPacket(container)
    container.mMainScrollView = container:getVarScrollView("mMainContent")
    container.mChatScrollView = container:getVarScrollView("mChatContent")
    -- scrollview, 背景自適應
    local scale9Sprite = container:getVarScale9Sprite("mBg")
    local scale9Sprite2 = container:getVarScale9Sprite("mChatBg")
    local scale9Sprite3 = container:getVarScale9Sprite("mBg2")
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite)
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite2)
    NodeHelper:autoAdjustResizeScale9Sprite(scale9Sprite3)
    NodeHelper:autoAdjustResizeScrollview(container.mMainScrollView)
    NodeHelper:autoAdjustResizeScrollview(container.mChatScrollView)
    -- 設定過濾按鈕
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, {mClassNode = false})
    
    oriChatScrollViewHeight = container.mChatScrollView:getViewSize().height
    
    self:onElement(container, "onElement0")
    self:onClass(container, "onClass0")
    
    self:onRefreshPage(container, true)
    
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["SecretMessagePage"] = container
    PageManager.pushPage("NewbieGuideForcedPage")
end
-- Main Page ScrollView初始化
function SecretMessagePage:initMainScrollView(container)
    if container.mMainScrollView == nil then return end
    container.mMainScrollView:removeAllCell()
    SecretMessageItems = {}
    local messageQueue = SecretMessageManager_getMessageQueue()
    NodeHelper:setStringForLabel(container, {mMessageNum = common:getLanguageString("@SecrecNotice") .. #messageQueue})
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        table.sort(messageQueue, function(d1, d2)
            if d1 and d2 then
                return d1.itemId == 1
            end
            if d1 then
                return false
            end
            if d2 then
                return d2.itemId == 1
            end
            return false
        end)
    end
    for i = 1, #messageQueue do
        if not self:isInMessageItemId(messageQueue[i].itemId) then
            local idx = #SecretMessageItems + 1
            local cfg = heroCfg[messageQueue[i].itemId]
            if cfg then 
                local cell = CCBFileCell:create()
                cell:setCCBFile(SecretMessageItem.ccbiFile)
                local handler = common:new({id = idx, data = messageQueue[i], element = cfg.Element, class = cfg.Job, isNew = true}, SecretMessageItem)
                cell:registerFunctionHandler(handler)
                container.mMainScrollView:addCell(cell)
                SecretMessageItems[idx] = {cls = handler, node = cell}
            end
        end
    end
    -- 建立對話歷史紀錄
    local heroData = SecretMessageManager_getAllHeroData()
    if heroData then
        for i = 1, 24 do
            if heroData[i] and heroData[i].history and #heroData[i].history > 0 and not self:isInMessageItemId(i) then
                local idx = #SecretMessageItems + 1
                local cfg = heroCfg[i]
                local cell = CCBFileCell:create()
                cell:setCCBFile(SecretMessageItem.ccbiFile)
                local data = {itemId = i, endStr = common:getLanguageString(heroData[i].history[#heroData[i].history].endStr)}
                local handler = common:new({id = idx, data = data, element = cfg.Element, class = cfg.Job, isNew = false}, SecretMessageItem)
                cell:registerFunctionHandler(handler)
                container.mMainScrollView:addCell(cell)
                SecretMessageItems[idx] = {cls = handler, node = cell}
            end
        end
    end
    self:setFilterVisible(container)
    container.mMainScrollView:orderCCBFileCells()
end
function table.merge(t1, t2)
    for k, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end
function SecretMessagePage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_SECRETMSG);
end
-- Chat Page ScrollView初始化
function SecretMessagePage:initChatScrollView(container, isShowNewChat)
    if container.mChatScrollView == nil then return end
    container.mChatScrollView:removeAllCell()
    ChatItems = {}
    -- 建立對話歷史紀錄
    local historyMsg = SecretMessageManager_getHistoryMessageByItemId(nowChatId)
    if historyMsg then
        for i = 1, #historyMsg do
            local MsgIndex=3
            for j = 1, MsgIndex do
                local idx = #ChatItems + 1
                local cell = CCBFileCell:create()
                cell:setCCBFile((j == 2) and ChatMessageItem.ccbiFileRight or ChatMessageItem.ccbiFileLeft)
               local msg = ((j == 1) and common:getLanguageString(historyMsg[i].questionStr))
                   or ((j == 2) and common:getLanguageString(historyMsg[i].ansStr))
                   or ((j == 3) and common:getLanguageString(historyMsg[i].endStr))
                   or ""
                if historyMsg[i].itemId then
                    local handler = common:new({id = idx, msg = msg, itemId = historyMsg[i].itemId, isMine = (j == 2)}, ChatMessageItem)
                    cell:registerFunctionHandler(handler)
                    container.mChatScrollView:addCell(cell)
                    ChatItems[idx] = {cls = handler, node = cell}
                    local height = ChatMessageItem:calItemHeight(msg)
                    ChatItems[idx].node:setContentSize(CCSize(CHAT_CCB_WIDTH, height))
                    chatMsgTotalHeight = chatMsgTotalHeight + height
                end
            end
        end
    end
    --self:UserSync()
    -- 建立未回答的訊息
    local message = SecretMessageManager_getFirstMessageByItemId(nowChatId)
    -- 新增回答cell
    if message and isShowNewChat then
        local idx = #ChatItems + 1
        local cell = CCBFileCell:create()
        cell:setCCBFile(ChatMessageItem.ccbiFileLeft)
        local handler = common:new({id = idx, msg = (common:getLanguageString(message.questionStr)), itemId = message.itemId, isMine = false}, ChatMessageItem)
        cell:registerFunctionHandler(handler)
        container.mChatScrollView:addCell(cell)
        ChatItems[idx] = {cls = handler, node = cell}
        local height = ChatMessageItem:calItemHeight(common:getLanguageString(message.questionStr))
        ChatItems[idx].node:setContentSize(CCSize(CHAT_CCB_WIDTH, height))
        
        chatMsgTotalHeight = chatMsgTotalHeight + height
        if not Canloop then
            self:setAnswerFrame(container, message)
        end
        NodeHelper:setNodesVisible(container, {mAnswerNode = true})
    else
        NodeHelper:setNodesVisible(container, {mAnswerNode = false})
    end
    container.mChatScrollView:orderCCBFileCells()
    container.mChatScrollView:locateToByIndex(#ChatItems - 1)
end
function SecretMessagePage:UserSync()
    --if新圖
    keyTable={ }
    if  KEY~="" then
        for k,v in pairs (common:split(KEY,",")) do
            local id,state=unpack(common:split(v,"_"))
            if id~="" then
                keyTable[tonumber(id)]=state
            end
        end
    end
    --local encodedData = CCCrypto:encodeBase64(KEY)
    --local decodedData= CCCrypto:decodeBase64(encodedData)
     --CCUserDefault:sharedUserDefault():setStringForKey("Album", KEY);
     --SecretMessagePage_RefreshTab()
end
function SecretMessagePage:NotAllSaw()
   --local KEY=CCUserDefault:sharedUserDefault():getStringForKey("Album") 
   --if string.find(KEY,"false") then
   --    return true
   --end
   --return false
end
-- 檢查是否已經有該英雄的訊息物件
function SecretMessagePage:isInMessageItemId(itemId)
    for i = 1, #SecretMessageItems do
        if SecretMessageItems[i].cls.data.itemId == itemId then
            return true
        end
    end
    return false
end
function SecretMessagePage_RefreshBar()
    local container=mainContainer
    local Power=SecretMessageManager_getPower()
    local PowerLimit=ConfigManager.getVipCfg()[UserInfo.playerInfo.vipLevel].PowerLimit
    local txt= Power.. "/" ..PowerLimit
    NodeHelper:setStringForLabel(container,{mMainPowerNum=txt,mChatPowerNum=txt})
    NodeHelper:setScale9SpriteBar(container,"mMainPowerBar",Power,PowerLimit,350)
end
-- 顯示刷新
function SecretMessagePage:onRefreshPage(container, isShowNewChat)
    SecretMessagePage_RefreshBar()
    if nowPageType == GameConfig.SECRET_PAGE_TYPE.MAIN_PAGE then
        NodeHelper:setNodesVisible(container, {mMainPageNode = true, mChatPageNode = false,mTopnode=true})  
        mainContainer:getVarNode("mPopUpNode"):removeAllChildren()    
        self:initMainScrollView(container)
    elseif nowPageType == GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
        local Point=SecretMessageManager_getAllHeroData()[nowChatId].favorabilityPoint
         AlbumData=SecretMessageManager_getAlbumData(nowChatId)
        NodeHelper:setStringForLabel(container,{mLove=Point.." / "..AlbumData.NowLimit})
        if self:isInMessageItemId(nowChatId) then
            NodeHelper:setNodesVisible(container, {mAnswerNode = false})
            self:initChatScrollView(container, isShowNewChat)
            NodeHelper:setNodesVisible(container, {mMainPageNode = false, mChatPageNode = true,mTopnode=false})
            local ImgName="UI/Role/Portrait_" .. string.format("%02d", nowChatId) .. "000.png"
            NodeHelper:setSpriteImage(container, {mChatImg = ImgName,mHeadIcon = ImgName})
            NodeHelper:setStringForLabel(container, {mChatTitle = common:getLanguageString("@HeroName_" .. nowChatId)})
            local message = SecretMessageManager_getFirstMessageByItemId(nowChatId)
            if ChatItems[#ChatItems + 1] == nil and Canloop then
                local lastContainer = ChatItems[#ChatItems].node:getCCBFileNode()
                -- 隱藏回答視窗
                local ansNode = container:getVarNode("mAnswerNode")
                ansNode:setPositionY(-answerBgHeight)
                --輸入中動畫
                local array = CCArray:create()
                array:addObject(CCCallFunc:create(function()
                    NodeHelper:setNodesVisible(lastContainer, {mTexNode = false})
                    lastContainer:runAnimation("loop")
                end))
                --if TYPING_SOUND~="" then
                --    SoundManager:getInstance():playEffectByName(TYPING_SOUND,false)
                --end
                array:addObject(CCDelayTime:create(3))
                array:addObject(CCCallFunc:create(function()
                    local msg = ChatItems[#ChatItems].cls.msg
                    if not string.find(msg, "Pic") then
                        NodeHelper:setNodesVisible(lastContainer, {mTexNode = true})
                        lastContainer:runAnimation("Default Timeline")
                    end
                    self:setAnswerFrame(container, message)
                    local ansNode = container:getVarNode("mAnswerNode")
                    local array3 = CCArray:create()
                    array3:addObject(CCMoveTo:create(0.1, ccp(0, 0)))
                    ansNode:runAction(CCSequence:create(array3))
                end))
                container:runAction(CCSequence:create(array))
            end
        else
            self:returnToMainPage(container)
        end
    else
        self:returnToMainPage(container)
    end
end
-- 設定回答視窗
function SecretMessagePage:setAnswerFrame(container, message)
    if not message then
        return
    end
    -- CONST
    local BG_SPACING_BOTTOM = 19 -- 選項二底圖底端~背景圖底端的距離
    local BG_SPACING_CENTER = 14 -- 選項一底圖底端~選項二底圖頂端間隔
    local BG_SPACING_TOP = 17 -- 選項一底圖頂端~背景圖頂端的距離
    local BG_BASE_WIDTH = 720 -- 背景圖寬度
    local BG_BASE_POSY = 105 -- 背景圖初始y座標
    local ANS_BTN_WIDTH = 680 -- 選項按鈕寬度
    local ANS_TXT_WIDTH = 570 -- 選項文字框寬度
    local ANS_BTN_BASE_SIZE = 50 -- 選項按鈕圖基礎長寬
    local ANS_BG_SPACING = 15 -- 選項文字框~選項背景圖頂(底)端距離
    local SCROLL_ANSFRAME_DIS_DIFF = 30 -- 滾動框跟回答框底部y座標差
    --
    local totalBtnHeight = 0
    for i = 2, 1, -1 do
        local parentNode = container:getVarLabelTTF("mAnswerStr" .. i)
        parentNode:setString("")
        parentNode:removeAllChildrenWithCleanup(true)
        local htmlModel = FreeTypeConfig[702].content
        local msgHtml = NodeHelper:addHtmlLable(parentNode, GameMaths:replaceStringWithCharacterAll(htmlModel, "#v2#", common:getLanguageString(message["ansStr" .. i])), 0, CCSizeMake(ANS_TXT_WIDTH, 200))
        local htmlHeight = msgHtml:getContentSize().height
        local msgBgHeight = htmlHeight + ANS_BG_SPACING * 2
        local ansBg = container:getVarScale9Sprite("mAnswerBg" .. i)
        ansBg:setContentSize(CCSize(ANS_BTN_WIDTH, msgBgHeight))
        
        container:getVarNode("mAnswerNode" .. i):setPositionY(BG_BASE_POSY + BG_SPACING_BOTTOM + totalBtnHeight + msgBgHeight / 2 + (i == 2 and 0 or BG_SPACING_CENTER))
        totalBtnHeight = totalBtnHeight + msgBgHeight
        
        container:getVarMenuItemImage("mAnsBtn" .. i):setScaleY(msgBgHeight / ANS_BTN_BASE_SIZE)
    end
    local bg = container:getVarScale9Sprite("mAnswerBg")
    answerBgHeight = BG_SPACING_BOTTOM + BG_SPACING_CENTER + BG_SPACING_TOP + totalBtnHeight
    bg:setContentSize(CCSize(BG_BASE_WIDTH, answerBgHeight))
    -- 移動scrollview高度
    if chatMsgTotalHeight + answerBgHeight - SCROLL_ANSFRAME_DIS_DIFF > container.mChatScrollView:getViewSize().height then
        container.mChatScrollView:setPositionY(math.max(CHAT_SCROLLVIEW_BASE_POSY, answerBgHeight + BG_BASE_POSY))
        local diffY = math.max(CHAT_SCROLLVIEW_BASE_POSY, answerBgHeight + BG_BASE_POSY) - CHAT_SCROLLVIEW_BASE_POSY
        local size = container.mChatScrollView:getViewSize()
        container.mChatScrollView:setViewSize(CCSize(size.width, size.height - math.max(0, diffY)))
    end
end
function SecretMessagePage:getRoleTable()
    local RoleTable={}
    for k,data in pairs (AlbumCfg) do
        if data.itemId==nowChatId then
            table.insert(RoleTable,data)
        end
    end
    table.sort(RoleTable, function(a, b)
            return a.id < b.id
    end)
    return RoleTable
end
function SecretMessagePage:PopUP()
    local cfg=SecretMessagePage:getRoleTable()
    local id=0
    for k,v in pairs (cfg) do
        if v.Score==AlbumData.NowLimit then
            id=k
        end 
    end
    PopUpCCB = ScriptContentBase:create("AlbumIndvidualPopoutContent")
    mainContainer:getVarNode("mPopUpNode"):addChild(PopUpCCB)
    SetPopupPage(PopUpCCB,cfg[id])
    PopUpCCB.cfg=cfg[id]
    PopUpCCB:registerFunctionHandler(SecertPopUpCCBFun)
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["AlbumIndvidualPopup"] = PopUpCCB
    -- 新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        GuideManager.forceNextNewbieGuide()
    end
end
function SecertPopUpCCBFun(eventName,container)
    if eventName=="onClose" then
        mainContainer:getVarNode("mPopUpNode"):removeAllChildren()
    elseif eventName=="onConfirm" then
        local cfg=container.cfg
        local AlbumData=SecretMessageManager_getAlbumData(nowChatId)
        local Point=SecretMessageManager_getAllHeroData()[nowChatId].favorabilityPoint
        if Point>=AlbumData.NowLimit and cfg.id<1000 then
            AlbumIndivualPage:sendUnLock(cfg.id)
            mainContainer:getVarNode("mPopUpNode"):removeAllChildren()
            return
        end
        if cfg.id>1000 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AlbumMessage_04",cfg.Score))
        elseif Point<AlbumData.NowLimit then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AlbumMessage_02",cfg.Score))
        end
    end
end
function SecretMessagePage:onAnswer(container, eventName)
    local Point=SecretMessageManager_getAllHeroData()[nowChatId].favorabilityPoint
    if SecretMessageManager_getPower()<25 then
        MessageBoxPage:Msg_Box(common:getLanguageString("@NoPower"))
        return 
    end
    if Point>=AlbumData.NowLimit then
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
        --SecretMessagePage:PopUP()
         local id=0
         local cfg=SecretMessagePage:getRoleTable()
         for k,v in pairs (cfg) do
             if v.Score==AlbumData.NowLimit then
                 id=k
             end 
         end
        AlbumIndivualPage:SetId(nowChatId)
        PageManager.pushPage("Album.AlbumPage")
        AlbumIndivualPage:isFromMsg(true,id)
        return 
    end
    local selectId = tonumber(eventName:sub(-1))
    local message = SecretMessageManager_getFirstMessageByItemId(nowChatId)
    -- scrollview回歸原始長度
    container.mChatScrollView:setViewSize(CCSize(container.mChatScrollView:getViewSize().width, oriChatScrollViewHeight))

    Old_heroData = SecretMessageManager_getAllHeroData()
    OldPoint.data01 = Old_heroData[message.itemId].intimacyPoint
    OldPoint.data02 = Old_heroData[message.itemId].favorabilityPoint
    OldPoint.data03 = Old_heroData[message.itemId].sexyPoint
    OldPoint.itemId = message.itemId
    local array = CCArray:create()
    -- 新增回答cell
    array:addObject(CCCallFunc:create(function()
        local idx = #ChatItems + 1
        local cell = CCBFileCell:create()
        cell:setCCBFile(ChatMessageItem.ccbiFileRight)
        local handler = common:new({id = idx, msg = common:getLanguageString(message["ansStr" .. selectId]), itemId = message.itemId, isMine = true}, ChatMessageItem)
        cell:registerFunctionHandler(handler)
        container.mChatScrollView:addCell(cell)
        ChatItems[idx] = {cls = handler, node = cell}
        local height = ChatMessageItem:calItemHeight(common:getLanguageString(message.questionStr))
        ChatItems[idx].node:setContentSize(CCSize(CHAT_CCB_WIDTH, height))
        container.mChatScrollView:orderCCBFileCells()
        container.mChatScrollView:locateToByIndex(idx - 1)
    end))
    -- scrollview回歸原位
    array:addObject(CCMoveTo:create(0.1, ccp(container.mChatScrollView:getPositionX(), CHAT_SCROLLVIEW_BASE_POSY)))
    -- 傳送回答
    array:addObject(CCCallFunc:create(function()
        SecretMessagePage:sendAnswer(container, message.questId, selectId)
    end))
    container.mChatScrollView:runAction(CCSequence:create(array))
    
    -- 隱藏回答視窗
    local ansNode = container:getVarNode("mAnswerNode")
    local array2 = CCArray:create()
    array2:addObject(CCMoveTo:create(0.1, ccp(0, -answerBgHeight)))
    ansNode:runAction(CCSequence:create(array2))
end

function SecretMessagePage:onAlbum(container)
    PageManager.pushPage("Album.AlbumMainPage")
end

function SecretMessagePage:onFilter(container)
    local isShowClass = container:getVarNode("mClassNode"):isVisible()
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        filterBg:setContentSize(filterCloseSize)
        NodeHelper:setNodesVisible(container, {mClassNode = false})
    else
        filterBg:setContentSize(filterOpenSize)
        NodeHelper:setNodesVisible(container, {mClassNode = true})
    end
end

function SecretMessagePage:onElement(container, eventName)
    local element = tonumber(eventName:sub(-1))
    mainPageElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    container.mMainScrollView:orderCCBFileCells()
end

function SecretMessagePage:onClass(container, eventName)
    local class = tonumber(eventName:sub(-1))
    mainPageClass = class
    self:setFilterVisible(container)
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(class == i)
    end
    container.mMainScrollView:orderCCBFileCells()
end

function SecretMessagePage:setFilterVisible(container)
    for i = 1, #SecretMessageItems do
        local isVisible = (mainPageElement == SecretMessageItems[i].cls.element or mainPageElement == 0) and
            (mainPageClass == SecretMessageItems[i].cls.class or mainPageClass == 0)
        SecretMessageItems[i].node:setVisible(isVisible)
        SecretMessageItems[i].node:setContentSize(isVisible and MAIN_PAGE_ITEM_SIZE or CCSize(0, 0))
    end
end

function SecretMessagePage:onReturn(container)
    PageManager.popPage(thisPageName)
--MainFrame_onMainPageBtn()
end
function SecretMessagePage_getState()
    return nowPageType
end
function SecretMessagePage_RefreshTab()
    --local tmp={}
    --tmp['redpoint']=SecretMessagePage:NotAllSaw()
    --parentPage.tabStorage:refreshTab2(tabData,2,tmp)
end
function SecretMessagePage:onExit(container)
    if nowPageType == GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
        self:onReturnToMainPage(container)
    else
        SecretMessageItems = {}
        ChatItems = {}
        nowPageType = GameConfig.SECRET_PAGE_TYPE.MAIN_PAGE
        nowChatId = 0
        mainPageElement = 0
        mainPageClass = 0
        chatMsgTotalHeight = 0
        container:stopAllActions()
        container.mMainScrollView:removeAllCell()
        container.mChatScrollView:removeAllCell()
        container.mChatScrollView:stopAllActions()
        container.mChatScrollView:setPositionY(CHAT_SCROLLVIEW_BASE_POSY)
        container.mChatScrollView:setViewSize(CCSize(container.mChatScrollView:getViewSize().width, oriChatScrollViewHeight))
        local ansNode = container:getVarNode("mAnswerNode")
        ansNode:stopAllActions()
        ansNode:setPositionY(0)
        if GetPower ~=nil then
            CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(GetPower)
            GetPower=nil
        end
    end
end

function SecretMessagePage:onReturnToMainPage(container)
    container:stopAllActions()
    container.mChatScrollView:stopAllActions()
    container.mChatScrollView:setPositionY(CHAT_SCROLLVIEW_BASE_POSY)
    container.mChatScrollView:setViewSize(CCSize(container.mChatScrollView:getViewSize().width, oriChatScrollViewHeight))
    local ansNode = container:getVarNode("mAnswerNode")
    ansNode:stopAllActions()
    ansNode:setPositionY(0)
    self:returnToMainPage(container)
end

function SecretMessagePage:returnToMainPage(container)
    chatMsgTotalHeight = 0
    nowChatId = 0
    nowPageType = GameConfig.SECRET_PAGE_TYPE.MAIN_PAGE
    self:onRefreshPage(container, true)
end

-- Server回傳
function SecretMessagePage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SECRET_MESSAGE_ACTION_S then
        Canloop=true
        local msg = SecretMsg_pb.secretMsgResponse()
        msg:ParseFromString(msgBuff)
        local action = msg.action
         if action==2 then
            local syncMsg = msg.syncMsg
            SecretMessageManager_setServerData(syncMsg)
            AlbumIndivualPage_refresh()
            return
        end
        if action==3 then
            SecretMessageManager_setServerData(msg)
            return
        end
        if action == 4 then
            local syncMsg = msg.syncMsg
            SecretMessageManager_setServerData(syncMsg)
            AlbumIndivualPage:refresh()
            return
        end
        -- 新手教學
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            GuideManager.forceNextNewbieGuide()
        end
        local syncMsg = msg.syncMsg
        SecretMessageManager_setServerData(syncMsg)
        if nowPageType == GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(1))
            array:addObject(CCCallFunc:create(function()SecretMessagePage:onRefreshPage(mainContainer, false) end))
            mainContainer:runAction(CCSequence:create(array))
        end
        if nowPageType == GameConfig.SECRET_PAGE_TYPE.CHAT_PAGE then
            local array = CCArray:create()
            array:addObject(CCDelayTime:create(6))
            array:addObject(CCCallFunc:create(function()SecretMessagePage:newQues(mainContainer) end))
            mainContainer:runAction(CCSequence:create(array))
        end
        if action == 0 then
            AlbumData=SecretMessageManager_getAlbumData(nowChatId)
            self:onRefreshPage(mainContainer, true)
            return
        end
        SecretMessagePage:GradeGet()
    end
end
function SecretMessagePage:GradeGet()
    local heroData = SecretMessageManager_getAllHeroData()
    --local message = SecretMessageManager_getFirstMessageByItemId(nowChatId)
    local NewPoint = {}
    NewPoint.data01 = heroData[OldPoint.itemId].intimacyPoint
    NewPoint.data02 = heroData[OldPoint.itemId].favorabilityPoint
    NewPoint.data03 = heroData[OldPoint.itemId].sexyPoint
    
    
    local delta_intimacyPoint = NewPoint.data01 - OldPoint.data01
    local delta_favorabilityPoint = NewPoint.data02 - OldPoint.data02
    local delta_sexyPoint = NewPoint.data03 - OldPoint.data03
    
    NodeHelper:setStringForLabel(mainContainer, { mBM02 = "-25", mBM03 = "+" .. delta_favorabilityPoint})
    NodeHelper:setBMFontFile(mainContainer, {mBM01 = "Lang/NG_PIC1.fnt", mBM02 = "Lang/NG_PIC2.fnt", mBM03 = "Lang/NG_PIC3.fnt"})
    mainContainer:runAnimation("AddPoint")
    local Point=SecretMessageManager_getAllHeroData()[nowChatId].favorabilityPoint
    local id=0
    local cfg=SecretMessagePage:getRoleTable()
    for k,v in pairs (cfg) do
        if v.Score==AlbumData.NowLimit then
            id=k
        end 
    end
    if Point>=AlbumData.NowLimit then
        local array = CCArray:create()
        array:addObject(CCDelayTime:create(2))
        array:addObject(CCCallFunc:create(function() 
                                            AlbumIndivualPage:SetId(nowChatId)
                                            PageManager.pushPage("Album.AlbumPage")
                                            AlbumIndivualPage:isFromMsg(true,id)
                                           end))
        mainContainer:runAction(CCSequence:create(array))
    end
end
function SecretMessagePage:newQues(container)
    Canloop=true
    local message = SecretMessageManager_getFirstMessageByItemId(nowChatId)
    if message then
        container:stopAllActions()
        container.mChatScrollView:stopAllActions()
        container.mChatScrollView:setPositionY(CHAT_SCROLLVIEW_BASE_POSY)
        container.mChatScrollView:setViewSize(CCSize(container.mChatScrollView:getViewSize().width, oriChatScrollViewHeight))
        local ansNode = container:getVarNode("mAnswerNode")
        ansNode:stopAllActions()
        ansNode:setPositionY(0)
        SecretMessagePage:onRefreshPage(mainContainer, true)
    end
end

function SecretMessagePage:testReceivePacket(container)
    local array = CCArray:create()
    array:addObject(CCDelayTime:create(2))
    array:addObject(CCCallFunc:create(function()SecretMessagePage:onRefreshPage(container, false) end))
    container:runAction(CCSequence:create(array))
end

function SecretMessagePage:sendAnswer(container, questId, ans)

    local msg = SecretMsg_pb.secretMsgRequest()
    msg.action = 1
    msg.msgId = questId
    msg.choice = ans - 1 -- server使用0跟1
    common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, false)
end
function SecretMessagePage:getPower(container)
    local msg = SecretMsg_pb.secretMsgRequest()
    msg.action = 3
    common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, false)
end

function SecretMessagePage:registerPacket(container)
    parentPage:registerPacket(opcodes)
end

function SecretMessagePage:removePacket(container)
    parentPage:removePacket(opcodes)
end
function SecretMessagePage:onExecute(container)
end
function SecretMessagePage_setPageType(pageType)
    nowPageType = pageType
end

function SecretMessagePage_setPageItemId(id)
    nowChatId = id
end
--local CommonPage = require('CommonPage')
return SecretMessagePage
