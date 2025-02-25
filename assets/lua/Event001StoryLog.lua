local HP_pb = require("HP_pb")
require("SecretMessage.SecretMessageManager")
local EventDataMgr = require("Event001DataMgr")
local thisPageName = "Event001StoryLog"
----------------------------------------------------------

local option = {
    ccbiFile = "Album.ccbi",
    handlerMap =
    {
        onReturn = "onReturn",
    },
    opcode = opcodes
}
----------------------------------------------------------
local StoryLogPageBase = { }
local AlbumSideStory = {}
local Datas={}

local mainContainer = nil

----------------------------------------------------------
function StoryLogPageBase:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self
    return o
end

function StoryLogPageBase:createPage(_parentPage)
    
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

function StoryLogPageBase:onExecute(container)
end

function StoryLogPageBase:onEnter(container)
    mainContainer = container
    NodeHelper:setNodesVisible(mainContainer,{mElementNode=false})
    container.mScrollView = container:getVarScrollView("mContent")
    -- scrollview自適應
    NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
    local oldSize = container.mScrollView:getViewSize()
    oldSize.width = oldSize.width + 50
    container.mScrollView:setViewSize(oldSize)
    local X=container.mScrollView:getPositionX()
    container.mScrollView:setPositionX(X-10)
   self:initScrollView(container)
end
-- ScrollView初始化
function StoryLogPageBase:initScrollView(container)
    for key,value in pairs (Datas) do
        cell = CCBFileCell:create()
        cell:setCCBFile("AlbumSideStoryContent.ccbi")
        local panel = common:new({itemId=key,id = value.id,chapter = value.chapter, level=value.level ,storyIdx=value.StoryIdx , mapId=value.mapId, MapIdx=value.MapIdx}, AlbumSideStory)
        cell:registerFunctionHandler(panel)
        container.mScrollView:addCell(cell)
    end
    container.mScrollView:setTouchEnabled(true)
    container.mScrollView:orderCCBFileCells()
end
-- 顯示刷新
function StoryLogPageBase:onRefreshPage(container)
end
function AlbumSideStory:onRefreshContent(content)
    local container = content:getCCBFileNode()
    --[[
    mBg:背景
    mLock:解鎖Node
    mMask:遮罩
    mTxt:標題
    ]]
    local Event001Base = require "Event001Page"
    local Passed = Event001Base:getStageInfo().PassedId
    local Img = EventDataMgr[EventDataMgr.nowActivityId].STAGE_CFG[Passed].storyBanner
    NodeHelper:setSpriteImage(container, { mBg = Img })
    UserInfo.sync()
    --local passedMap = UserInfo.stateInfo.passMapId
    
    NodeHelper:setNodesVisible(container,{mLock=false,mMask=false})
    if self.mapId and Passed>=self.mapId then
        NodeHelper:setNodesVisible(container,{mLock=false,mMask=false})
        self.isLock=false
    else
         NodeHelper:setNodesVisible(container,{mLock=true,mMask=true})
         self.isLock=true
    end
    local idx= self.chapter .. string.format("%02d",self.level)..self.storyIdx
    local string=common:getLanguageString("@ActivitystoryTitle" .. idx ) 
    NodeHelper:setStringForLabel(container,{mTxt=string})

end
function AlbumSideStory:onBtn()
    if self.isLock then
        local string= common:getLanguageString("@ActivitystoryTitleLock")
        MessageBoxPage:Msg_Box(string)
        return 
    end
    require("Event001AVG")
    Event001AVG_setPhotoRole(nil, self.chapter, self.level,self.storyIdx)
    PageManager.pushPage("Event001AVG")
end

function StoryLogPageBase:SetData(data)
    Datas=data
end

function StoryLogPageBase:onReturn(container)
    PageManager.popPage(thisPageName)
end
function StoryLogPageBase:setMovieVisible(isVisible)
    NodeHelper:setNodesVisible(mainContainer,{mLayerColor = isVisible,mBg = isVisible , mTop = isVisible , mBottom = isVisible})
    NodeHelper:setNodesVisible(parentPage.container,{mPushAnimNode = isVisible})
end

local CommonPage = require("CommonPage")
local StoryLogPage = CommonPage.newSub(StoryLogPageBase, thisPageName, option)

return StoryLogPage
