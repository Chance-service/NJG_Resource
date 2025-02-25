local HP_pb = require("HP_pb")
require("SecretMessage.SecretMessageManager")
local thisPageName = "Album.StoryLog"
----------------------------------------------------------
local opcodes = {
    
    }
local mainContainer = nil
local option = {
    ccbiFile = "Album.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
    },
    opcode = opcodes
}
----------------------------------------------------------
local StoryLogPage = {}
local AlbumItems = {}
local mapCfg = ConfigManager.getNewMapCfg()
local passedMap = 0

----------------------------------------------------------
-- MAIN PAGE ITEM
local AlbumItem = {
    ccbiFile = "AlbumContent.ccbi",
}
function AlbumItem:new(o)
    o = o or {}
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
    if self.itemId ~= 990 then
        NodeHelper:setSpriteImage(self.container, {mImg = "UI/HeroMemories/AlbumReview_" .. string.format("%03d",self.itemId+1) .. ".png"})
        NodeHelper:setNodesVisible(self.container, {mCountBg = false, mCount = false, mRedNode = false})
        local passed = false
        if mapCfg[passedMap].Chapter / 4 + 1 > self.itemId then
            passed = true
        end
        NodeHelper:setStringForLabel(self.container, {mName = common:getLanguageString("@AlbumReviewTitle" .. string.format("%03d",self.itemId))})
        NodeHelper:setNodeIsGray(self.container, {mImg = not passed})
    else
        NodeHelper:setSpriteImage(self.container, {mImg = "UI/HeroMemories/AlbumReview_001.png"})
        --NodeHelper:setSpriteImage(self.container, {mImg = "UI/RoleShowCards/Hero_" .. self.itemId .. "000.png"})
        NodeHelper:setNodesVisible(self.container, {mCountBg = false, mCount = false, mRedNode = false})
        NodeHelper:setStringForLabel(self.container, {mName = common:getLanguageString("@HeroName_" .. self.itemId)})
    end
end
function AlbumItem:onAlbum(container)
    if self.itemId ~= 990 then
        local StoryTable = AlbumItem:CreateMapTable(self.itemId)
        if StoryTable==nil then return end
        local StoryLogPage= require("Album.AlbumStoryPage")
        StoryLogPage:SetData(StoryTable)
        PageManager.pushPage("Album.AlbumStoryPage")
    else
        PageManager.pushPage("Album.AlbumHCGPage")
    end
end
function AlbumItem:CreateMapTable(mID)
    if math.ceil(mapCfg[passedMap].Chapter / 4) >= mID then
        local MapTable = {}
        local fetterControlCfg = ConfigManager:getFetterBDSMControlCfg()
        local idx = mID
        if idx ~= 1 then
            idx = idx * 4 - 3
        end
        for i = idx, mID * 4 do
            local _chapter = i
            for j = 1, 99 do
                local _level = j
                local _mapId=AlbumItem:MapIdSync(_chapter,_level)
                for k=1,2 do
                    local _id = tonumber(string.format("%02d", _chapter) .. string.format("%02d", _level) ..k.."01")
                    if fetterControlCfg[_id] then
                       table.insert(MapTable, { mapId=_mapId, id=_id,chapter=_chapter,level=_level,StoryIdx=k ,MapIdx=mID})
                    end                   
                end
            end
        end
        return MapTable
    end
end
function AlbumItem:MapIdSync(chapter,level)
    for k,v in pairs (mapCfg) do
        if v.Chapter==chapter and v.Level==level then
            return v.ID
        end
    end
end
----------------------------------------------------------
function StoryLogPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function StoryLogPage:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- ???U ?I?s??
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container, eventName)
        end
    end)
    
    return container
end

function StoryLogPage:onExecute(container)
end

function StoryLogPage:onEnter(container)
    mainContainer = container
    self:registerPacket(container)
    UserInfo.sync()
    passedMap = UserInfo.stateInfo.passMapId
    container.mScrollView = container:getVarScrollView("mContent")
    NodeHelper:setNodesVisible(mainContainer,{mElementNode=false})
    -- scrollview??A??
    NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
    -- ?]?w?L?o???s
    local filterBg = container:getVarScale9Sprite("mFilterBg")
    NodeHelper:setNodesVisible(container, {mClassNode = false})
    
    self:initScrollView(container)

    --新手教學
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["StoryLogPage"] = container
    PageManager.pushPage("NewbieGuideForcedPage")
end
-- ScrollView??l??
function StoryLogPage:initScrollView(container)
    local cell = CCBFileCell:create()
    cell:setCCBFile(AlbumItem.ccbiFile)
    local handler = common:new({itemId = 990}, AlbumItem)
    cell:registerFunctionHandler(handler)
    container.mScrollView:addCell(cell)
    for i = 1, 6 do
        local cell = CCBFileCell:create()
        cell:setCCBFile(AlbumItem.ccbiFile)
        local handler = common:new({itemId = i}, AlbumItem)
        cell:registerFunctionHandler(handler)
        container.mScrollView:addCell(cell)
        AlbumItems[i] = {cls = handler, node = cell}
    end
    
    container.mScrollView:orderCCBFileCells()
end
-- ????s
function StoryLogPage:onRefreshPage()
    mainContainer.mScrollView:removeAllCell()
    self:initScrollView(mainContainer)
end

function StoryLogPage:onReturn(container)
    PageManager.popPage(thisPageName)
end

function StoryLogPage:onExit(container)
    AlbumItems = {}
    container.mScrollView:removeAllCell()
end


function StoryLogPage:registerPacket(container)
    parentPage:registerPacket(opcodes)
end

function StoryLogPage:removePacket(container)
    parentPage:removePacket(opcodes)
end

function StoryLogPage:setMovieVisible(isVisible)
    NodeHelper:setNodesVisible(mainContainer,{mLayerColor = isVisible,mBg = isVisible , mTop = isVisible , mBottom = isVisible})
    NodeHelper:setNodesVisible(parentPage.container,{mPushAnimNode = isVisible})
end

return StoryLogPage
