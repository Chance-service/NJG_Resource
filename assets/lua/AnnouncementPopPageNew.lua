----------------------------------------------------------------------------------
-- AnnouncementPopPage.lua
----------------------------------------------------------------------------------
local thisPageName = "AnnouncementPopPageNew"

local ConfigManager      = require("ConfigManager")
local AnnounceDownLoad   = require("AnnounceDownLoad")
local NodeHelper         = require("NodeHelper")
local HP_pb              = require("HP_pb")
local Bulletin           = require("Bulletin_pb")
require("Util.LockManager")

local AnnouncementPopPageBase = {}

-- 定義接收封包 opcodes
local opcodes = {
    BULLETIN_TITLE_LIST_S   = HP_pb.BULLETIN_TITLE_LIST_S,
    BULLETIN_CONTENT_SYNC_S = HP_pb.BULLETIN_CONTENT_SYNC_S
}

local option = {
    ccbiFile   = "AnnouncementPage.ccbi",
    handlerMap = {
        onClose  = "onClose",
        onNormal = "onNormal",
        onAct    = "onAct",
        onSelect = "onSelect",
        onBack   = "onBack",
        toAct    = "toAct"
    },
    opcode     = opcodes
}

-- 不同版面所使用的 CCB 文件
local buildItems = {
    [2] = "AnnouncementPageContentA.ccbi",
    [1] = "AnnouncementPageContentB.ccbi"
}

-- 行為按鈕的處理函數集合
local ActItem = {}
local StrItem = {}

-- 封裝內部狀態（原本全局變數）
AnnouncementPopPageBase.allInfo             = {}
AnnouncementPopPageBase.nowTag              = 2
AnnouncementPopPageBase.isOpen              = false
AnnouncementPopPageBase.openList            = {}
AnnouncementPopPageBase.readyToGetMainScene = false
AnnouncementPopPageBase.configContent       = nil

local annoCfg = ConfigManager.getAnnounceCfg()

-- 各活動跳轉功能定義
local toActFunctions = {
    [1] = { 
        Fun   = function()
                    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
                    if tonumber(closeR18) == 1 then
                        MessageBoxPage:Msg_Box(common:getLanguageString("@ComingSoon"))
                        return
                    end
                    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.GLORY_HOLE) then
                        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.GLORY_HOLE))
                    else
                        local Activity5_pb = require("Activity5_pb")
                        local msg = Activity5_pb.GloryHoleReq()
                        msg.action = 0
                        common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)
                    end
                end,
        ActId = 175
    },
    [2] = { 
        Fun   = function()
                    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.MONTHLY_CARD) then
                        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.MONTHLY_CARD))
                    else
                        require("IAP.IAPPage"):setEntrySubPage("MonthCard")
                        PageManager.pushPage("IAP.IAPPage")
                    end
                end
    },
    [3] = { 
        Fun   = function(txt)
                    if not txt then
                        MessageBoxPage:Msg_Box("URL EMPTY")
                        return
                    end
                    common:openURL(txt)
                end
    },
    [4] = { 
        Fun   = function()
                    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.Event001) then
                        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.Event001))
                    else
                        local key     = "ACT191_" .. UserInfo.playerInfo.playerId
                        local timeTxt = CCUserDefault:sharedUserDefault():getStringForKey(key)
                        local event001Page = require("Event001Page")
                        if timeTxt == "" or event001Page:getStageInfo().startTime ~= tonumber(timeTxt) then
                            PageManager.pushPage("Event001VideoBlack")
                        else
                            PageManager.pushPage("Event001Page")
                        end
                    end
                end
    }
}

----------------------------------------------------------------------------------
-- 日期與顯示狀態相關函數
----------------------------------------------------------------------------------
local function getCurrentDateString()
    local dateTable = os.date("*t")
    return string.format("%04d_%02d_%02d", dateTable.year, dateTable.month, dateTable.day)
end

local function markAnnouncementShownToday()
    local key       = "ANN_ACT_" .. UserInfo.playerInfo.playerId
    local todayDate = getCurrentDateString()
    AnnouncementPopPageBase.readyToGetMainScene = true
    CCUserDefault:sharedUserDefault():setStringForKey(key, todayDate)
    CCUserDefault:sharedUserDefault():flush()
end

function AnnouncementPopPageBase.isShownToday()
    local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
    if tonumber(closeR18) == 1 then
        return true
    end
    local key         = "ANN_ACT_" .. UserInfo.playerInfo.playerId
    local storedValue = CCUserDefault:sharedUserDefault():getStringForKey(key)
    return storedValue == getCurrentDateString()
end

function AnnouncementPopPageBase.isPageOpen()
    return AnnouncementPopPageBase.isOpen
end

function AnnouncementPopPageBase.showSync()
    if AnnouncementPopPageBase.isShownToday() then
        -- 當日已顯示過公告，直接跳過
        return false
    else
        PageManager.pushPage(thisPageName)
        markAnnouncementShownToday()
        return true
    end
end

----------------------------------------------------------------------------------
-- Page Life Cycle
----------------------------------------------------------------------------------
function AnnouncementPopPageBase:onEnter(container)
    self.container = container
    NodeHelper:setNodesVisible(container, { mTag1 = (self.nowTag == 2), mTag2 = (self.nowTag == 1), mBack = false })
    self:registerPackets()
    common:sendEmptyPacket(HP_pb.BULLETIN_TITLE_LIST_C, true)
    self.isOpen = true
end

function AnnouncementPopPageBase:onClose()
    self:unregisterPackets()
    AnnouncementPopPageBase.allInfo = {}
    PageManager.popPage(thisPageName)
    self.isOpen = false
end

----------------------------------------------------------------------------------
-- 封包處理
----------------------------------------------------------------------------------
function AnnouncementPopPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.BULLETIN_TITLE_LIST_S then
        local msg = Bulletin.BulletinTitleInfo()
        msg:ParseFromString(msgBuff)
        AnnouncementPopPageBase.allInfo = {}
        self.openList = {}
        for _, info in ipairs(msg.allInfo) do
            if info.show then
                table.insert(AnnouncementPopPageBase.allInfo, {
                    id        = info.id,
                    kind      = info.kind,
                    titleStr  = info.titleStr,
                    updateTime= info.updateTime,
                    sort      = info.sort
                })
                table.insert(self.openList, tostring(info.id) .. ".txt")
            end
        end
        self:deleteUnusedFiles()
        table.sort(AnnouncementPopPageBase.allInfo, function(a, b) return a.sort < b.sort end)
        self:buildScrollView()
    elseif opcode == opcodes.BULLETIN_CONTENT_SYNC_S then
        local msg = Bulletin.BulletinContentRsp()
        msg:ParseFromString(msgBuff)
        local id              = msg.id
        local lastRefreshTime = 0
        local downloadUrl     = msg.txturl
        local urlParts        = common:split(downloadUrl, "/")
        local fileName        = urlParts[#urlParts]

        for _, info in ipairs(AnnouncementPopPageBase.allInfo) do
            if info.id == id then
                lastRefreshTime = info.updateTime
                break
            end
        end

        local path = ""
        for i = 1, #urlParts do
            if i ~= 1 and i ~= 2 then
                path = path .. "/" .. urlParts[i]
            end
        end

        local site = ""
        if UserInfo.serverId ~= 9 then
            site = VaribleManager:getInstance():getSetting("AnnouncementURL") .. path
        else
            site = "http://backend.quantagalaxies.com:34567" .. downloadUrl
        end
        AnnounceDownLoad.setData(site, fileName, lastRefreshTime)
        AnnounceDownLoad.start()
    end
end

----------------------------------------------------------------------------------
-- 檔案處理（清除非伺服器上的公告檔案）
----------------------------------------------------------------------------------
function AnnouncementPopPageBase:deleteUnusedFiles()
    local CCFileUtils = CCFileUtils:sharedFileUtils()
    local serverFiles = {}
    for _, fileName in ipairs(self.openList) do
        serverFiles[fileName] = true
    end
    local directoryPath = CCFileUtils:getWritablePath() .. "Annoucement/"
    deleteExpiredFiles(directoryPath, serverFiles)
end

local function listTxtFiles(directoryPath)
    local fileList = {}
    local command = 'ls "' .. directoryPath .. '"'
    if package.config:sub(1,1) == '\\' then
        command = 'dir "' .. directoryPath .. '" /b'
    end
    local pfile = io.popen(command)
    if pfile then
        for file in pfile:lines() do
            if file:sub(-4) == ".txt" then
                table.insert(fileList, file)
            end
        end
        pfile:close()
    end
    return fileList
end

local function getFileName(filePath)
    local fileName = filePath:match("^.+/(.+)$")
    if not fileName then
        fileName = filePath:match("^.+\\(.+)$")
    end
    return fileName
end

function deleteExpiredFiles(directoryPath, serverFileDict)
    local fileList = listTxtFiles(directoryPath)
    for _, file in ipairs(fileList) do
        local fullPath = directoryPath .. file
        local fileName = getFileName(fullPath)
        if not serverFileDict[fileName] then
            local result = os.remove(fullPath)
            if result then
                print("Deleted expired file: " .. file)
            else
                print("Failed to delete file: " .. file)
            end
        end
    end
end

----------------------------------------------------------------------------------
-- 畫面顯示
----------------------------------------------------------------------------------
function AnnouncementPopPageBase:buildScrollView()
    local container  = self.container
    NodeHelper:setNodesVisible(container, { mTag1 = (self.nowTag == 2), mTag2 = (self.nowTag == 1), mBack = false })
    local scrollView = container:getVarScrollView("mAnnMsgContent")
    scrollView:removeAllCell()

    for _, data in ipairs(AnnouncementPopPageBase.allInfo) do
        if data.kind == self.nowTag then
            local cell = CCBFileCell:create()
            cell:setCCBFile(buildItems[self.nowTag])
            local handler
            if self.nowTag == 2 then
                handler = common:new({ id = data.id }, ActItem)
            else
                handler = common:new({ id = data.id }, StrItem)
            end
            cell:registerFunctionHandler(handler)
            scrollView:addCell(cell)
        end
    end

    scrollView:setTouchEnabled(true)
    scrollView:orderCCBFileCells()
end

function AnnouncementPopPageBase:onNormal()
    if self.nowTag == 1 then return end
    self.nowTag = 1
    self:buildScrollView()
end

function AnnouncementPopPageBase:onAct()
    if self.nowTag == 2 then return end
    self.nowTag = 2
    self:buildScrollView()
end

function AnnouncementPopPageBase:onBack()
    self:buildScrollView()
end

function AnnouncementPopPageBase:setMessage(dataCfg)
    local container = self.container
    self.configContent = dataCfg
    self:buildHtml()
    NodeHelper:setNodesVisible(container, { mBack = true })
end

function AnnouncementPopPageBase:buildHtml()
    local scrollView = self.container:getVarScrollView("mAnnMsgContent")
    if not scrollView then return end
    local viewSize   = scrollView:getViewSize()
    scrollView:removeAllCell()

    local htmlLabel  = CCHTMLLabel:createWithString(self.configContent, viewSize, "Helvetica")
    local contentHeight = htmlLabel:getContentSize().height
    htmlLabel:setPosition(ccp(0, -50))
    scrollView:addChild(htmlLabel)
    scrollView:setContentSize(CCSizeMake(scrollView:getContentSize().width, contentHeight))

    local targetPosition = ccp(0, 0)
    htmlLabel:runAction(CCMoveTo:create(0.5, targetPosition))
    scrollView:setContentOffset(ccp(0, viewSize.height - contentHeight))
end
function AnnouncementPopPageBase:getDetail(id)
    for _, v in pairs(AnnouncementPopPageBase.allInfo) do
        if v.id == id then
            return v
        end
    end
    return nil
end

----------------------------------------------------------------------------------
-- 子元件處理（ActItem 與 StrItem）
----------------------------------------------------------------------------------
function ActItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local data = AnnouncementPopPageBase:getDetail(self.id)
    if not data then return end

    local parts = common:split(data.titleStr, "_")
    self.ActId = tonumber(parts[1])
    self.txt   = parts[2] or ""
    self.Jump = annoCfg[self.ActId].isJump

    local bannerImg = ""
    if annoCfg[self.ActId] then
        bannerImg = annoCfg[self.ActId].Banner
        NodeHelper:setNodesVisible(container, { mBtn = (self.Jump > 0) })
    end
    if bannerImg ~= "" then
        NodeHelper:setSpriteImage(container, { bannerImg = bannerImg })
    end

    if self.Jump == 3 then
        NodeHelper:setStringForLabel(container, { mTxt = common:getLanguageString("@GoToHttp") })
    else
        NodeHelper:setStringForLabel(container, { mTxt = common:getLanguageString("@GoToActivity") })
    end
end

function ActItem:onBannerClick()
    local msg = Bulletin.BulletinContentRet()
    msg.id = self.id
    common:sendPacket(HP_pb.BULLETIN_CONTENT_SYNC_C, msg, true)
end

function ActItem:toAct()
    if toActFunctions[self.Jump] then
        toActFunctions[self.Jump].Fun(self.txt)
    end
    PageManager.popPage(thisPageName)
end

function StrItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local data = AnnouncementPopPageBase:getDetail(self.id)
    if not data then return end
    NodeHelper:setStringForLabel(container, { titleText = data.titleStr })
end

function StrItem:onBannerClick()
    local msg = Bulletin.BulletinContentRet()
    msg.id = self.id
    common:sendPacket(HP_pb.BULLETIN_CONTENT_SYNC_C, msg, true)
end



----------------------------------------------------------------------------------
-- 封包註冊／移除
----------------------------------------------------------------------------------
function AnnouncementPopPageBase:registerPackets()
    for key, opcode in pairs(opcodes) do
        if key:sub(-1) == "S" then
            self.container:registerPacket(opcode)
        end
    end
end

function AnnouncementPopPageBase:unregisterPackets()
    for key, opcode in pairs(opcodes) do
        if key:sub(-1) == "S" then
            self.container:removePacket(opcode)
        end
    end
end

----------------------------------------------------------------------------------
-- 建立頁面實例
----------------------------------------------------------------------------------
local CommonPage = require("CommonPage")
local AnnouncementPopPage = CommonPage.newSub(AnnouncementPopPageBase, thisPageName, option)
return AnnouncementPopPage
