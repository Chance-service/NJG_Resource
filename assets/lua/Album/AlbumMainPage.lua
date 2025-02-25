local HP_pb = require("HP_pb")
require("SecretMessage.SecretMessageManager")
local thisPageName = "Album.AlbumMainPage"
local AlbumIndivualPage=require("Album.AlbumSubPage_Indiviual")
----------------------------------------------------------
-- CONST
local FILTER_WIDTH = 500
local FILTER_OPEN_HEIGHT = 142
local FILTER_CLOSE_HEIGHT = 74
local filterOpenSize = CCSize(FILTER_WIDTH, FILTER_OPEN_HEIGHT)
local filterCloseSize = CCSize(FILTER_WIDTH, FILTER_CLOSE_HEIGHT)
local ALBUM_ITEM_SIZE = CCSize(214, 302)
----------------------------------------------------------
local opcodes = {
    SECRET_MESSAGE_ACTION_S = HP_pb.SECRET_MESSAGE_ACTION_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    SIGN_SYNC_S = HP_pb.SIGN_SYNC_S
}

local option = {
    ccbiFile = "Album.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
        onFilter = "onFilter",
    },
    opcode = opcodes
}
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement"
end
for i = 0, 4 do
    option.handlerMap["onClass" .. i] = "onClass"
end
----------------------------------------------------------
local AlbumMainPage = { }
local AlbumItems = { }

local heroCfg = ConfigManager.getNewHeroCfg()
local element = 0
local class = 0

local mainContainer = nil

local HeroData=nil


local guideId = nil
----------------------------------------------------------
-- MAIN PAGE ITEM
local AlbumItem = {
    ccbiFile = "AlbumContent.ccbi",
}
function AlbumItem:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end


function AlbumItem:onRefreshContent(ccbRoot)
    self.container = ccbRoot:getCCBFileNode()
    self:refresh()
end

function AlbumItem:getCCBFileNode()
    return self.ccbiFile:getCCBFileNode()
end

function AlbumItem:refresh()
    if self.container == nil then
        return
    end
    if self.itemId~=990 then
        local SecretMessagePage=require("SecretMessage.SecretMessagePage")
        local AlbumData=SecretMessageManager_getAlbumData(self.itemId)
        NodeHelper:setSpriteImage(self.container, { mImg = "UI/RoleShowCards/Hero_" .. string.format("%02d", self.itemId) .. "000.png" })
        NodeHelper:setStringForLabel(self.container, { mName = common:getLanguageString("@HeroName_" .. self.itemId),mCount=AlbumData.UnLockCount .." / ".. AlbumData.ImgCount})
        --if albumCount>0 then
        --    NodeHelper:setNodeIsGray(self.container,{mImg=false})
        --else
        --    NodeHelper:setNodeIsGray(self.container,{mImg=true})
        --end
        --AlbumItem:RedSync(self.container,self.itemId)
        NodeHelper:setNodesVisible(self.container,{mRedNode=false})
        NodeHelper:setNodesVisible(self.container, {mCountBg = true, mCount = true})
    else
        NodeHelper:setSpriteImage(self.container, { mImg = "UI/RoleShowCards/Hero_" ..  self.itemId .. "000.png" })
        NodeHelper:setStringForLabel(self.container, { mName = common:getLanguageString("@HeroName_" .. self.itemId)})
    end
end
function AlbumItem:RedSync(container,id)
    local KEY=CCUserDefault:sharedUserDefault():getStringForKey("Album") 
    local keyTable={}
    if  KEY~="" then
        for k,v in pairs (common:split(KEY,",")) do
            local id,state=unpack(common:split(v,"_"))
            if id~="" then
                keyTable[tonumber(id)]=state
            end
        end
        for _id,state in pairs (keyTable) do
            local tmp=tonumber(string.sub(_id,2,3))
            if tmp==id and state=="false" then
                NodeHelper:setNodesVisible(container,{mRedNode=true})
                return
            else
                NodeHelper:setNodesVisible(container,{mRedNode=false})
            end
        end
    end
end
function AlbumItem:onAlbum(container)
    local nowChatId = self.itemId
    local data=nil
    if nowChatId~=990 and HeroData then
        for _,v in ipairs (HeroData) do
            if v.heroId==nowChatId then
                data=v
            end
        end 
    end
    AlbumIndivualPage:SetId(nowChatId,data)
    PageManager.pushPage("Album.AlbumPage")
end
----------------------------------------------------------
function AlbumMainPage:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function AlbumMainPage:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container,eventName)
        end
    end)
    
    return container
end

function AlbumMainPage:onExecute(container)
end

function AlbumMainPage:onEnter(container)
    mainContainer = container
    self:registerPacket(container)

    container.mScrollView = container:getVarScrollView("mContent")
    -- scrollview自適應
    NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
    -- 設定過濾按鈕
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    filterBg:setContentSize(filterCloseSize)
    NodeHelper:setNodesVisible(container, { mClassNode = false })

    self:initScrollView(container)

    self:onElement(container, "onElement0") 
    self:onClass(container, "onClass0") 
    --
    --self:onRefreshPage(container, true)
    if HeroData == nil then
        local msg = SecretMsg_pb.secretMsgRequest()
        msg.action = 0
        common:sendPacket(HP_pb.SECRET_MESSAGE_ACTION_C, msg, false)
    end

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["AlbumMainPage"] = container
    PageManager.pushPage("NewbieGuideForcedPage")
end
-- ScrollView初始化
function AlbumMainPage:initScrollView(container)
    --local cell = CCBFileCell:create()
    --cell:setCCBFile(AlbumItem.ccbiFile)
    --local handler = common:new( { itemId = 990}, AlbumItem)
    --cell:registerFunctionHandler(handler)
    --container.mScrollView:addCell(cell)
    local cfg=ConfigManager.getAlbumData()
    local tmp={}
    local OpenedHero={}
    for key,value in pairs (cfg) do
        if not tmp[value.itemId] then
            tmp[value.itemId]={}
            table.insert (OpenedHero,value.itemId)
        end
    end
    table.sort (OpenedHero,function(a,b) return a<b end)
    for k,v in  pairs(OpenedHero) do
         if heroCfg[v] then
            local cell = CCBFileCell:create()
            cell:setCCBFile(AlbumItem.ccbiFile)
            local handler = common:new( { itemId = v, element = heroCfg[v].Element, class = heroCfg[v].Job }, AlbumItem)
            cell:registerFunctionHandler(handler)
            container.mScrollView:addCell(cell)
            AlbumItems[k] = { cls = handler, node = cell }
        end
    end
    --for i = 1, #heroCfg do
    --    if i < 500 and heroCfg[i] then
    --        local cell = CCBFileCell:create()
    --        cell:setCCBFile(AlbumItem.ccbiFile)
    --        local handler = common:new( { itemId = i, element = heroCfg[i].Element, class = heroCfg[i].Job }, AlbumItem)
    --        cell:registerFunctionHandler(handler)
    --        container.mScrollView:addCell(cell)
    --        AlbumItems[i] = { cls = handler, node = cell }
    --    end
    --end

    container.mScrollView:orderCCBFileCells()
end
-- 顯示刷新
function AlbumMainPage:onRefreshPage()
    if not mainContainer then return end
    mainContainer.mScrollView:removeAllCell()
    self:initScrollView(mainContainer)
end

function AlbumMainPage:onFilter(container)
    local isShowClass = container:getVarNode("mClassNode"):isVisible()
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    if isShowClass then
        filterBg:setContentSize(filterCloseSize)
        NodeHelper:setNodesVisible(container, { mClassNode = false })
    else
        filterBg:setContentSize(filterOpenSize)
        NodeHelper:setNodesVisible(container, { mClassNode = true })
    end
end

function AlbumMainPage:onElement(container, eventName)
    element = tonumber(eventName:sub(-1))
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    container.mScrollView:orderCCBFileCells()
end

function AlbumMainPage:onClass(container, eventName)
    class = tonumber(eventName:sub(-1))
    self:setFilterVisible(container)
    for i = 0, 4 do
        container:getVarSprite("mClass" .. i):setVisible(class == i)
    end
    container.mScrollView:orderCCBFileCells()
end

function AlbumMainPage:setFilterVisible(container)
    for i = 1, #AlbumItems do
        local isVisible = (element == AlbumItems[i].cls.element or element == 0) and
                          (class == AlbumItems[i].cls.class or class == 0)
        AlbumItems[i].node:setVisible(isVisible)
        AlbumItems[i].node:setContentSize(isVisible and ALBUM_ITEM_SIZE or CCSize(0, 0))
    end
end

function AlbumMainPage:onReturn(container)
    PageManager.popPage(thisPageName)
end

function AlbumMainPage:onExit(container)
    AlbumItems = { }
    element = 0
    class = 0
    container.mScrollView:removeAllCell()
    HeroData=nil
    guideId = nil
end

-- Server回傳
function AlbumMainPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SECRET_MESSAGE_ACTION_S then
        local msg = SecretMsg_pb.secretMsgResponse()
        msg:ParseFromString(msgBuff)
        local syncMsg = msg.syncMsg
        SecretMessageManager_setServerData(syncMsg)
        if msg.action==2 then
            AlbumIndivualPage_refresh()
        end
        AlbumIndivualPage:refresh()
        HeroData= msg.syncMsg.heroInfo
        AlbumMainPage:onRefreshPage()
    elseif opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
    if opcode == HP_pb.SIGN_SYNC_S then
       AlbumIndivualPage:refresh()
    end
end

function AlbumMainPage:registerPacket(container)
    parentPage:registerPacket(opcodes)
end

function AlbumMainPage:removePacket(container)
     parentPage:removePacket(opcodes)
end

function AlbumMainPage_onGuideAlbumItem()
    local data = nil
    if guideId and HeroData then
        for _,v in ipairs (HeroData) do
            if v.heroId == guideId then
                data = v
            end
        end 
    end
    AlbumIndivualPage:SetId(guideId, data)
    PageManager.pushPage("Album.AlbumPage")
end

return AlbumMainPage 
