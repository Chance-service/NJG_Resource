local NodeHelper = require("NodeHelper")
local thisPageName = 'TowerRankPage'


local selfContainer
local TowerRankBase = {}
local parentPage = nil

local ItemCCB = {}

local RankRewardPopCCB = nil

local RankingContent = {
    ccbiFile = "Tower_RankingContent.ccbi",
}
local RankRewardContent={
    ccbiFile = "Tower_PopupContent.ccbi",
}

local TowerRankInfo = {}

local option = {
    ccbiFile = "Tower_Ranking.ccbi",
    handlerMap =
    {
        onDailyReward="onDailyReward",
        onDailyHelp = "onHelp",
        onClose="onClose",
        onRankingReward = "onRankingReward"
    },
}

function TowerRankBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container,eventName)
        end
    end)
    
    return container
end
function TowerRankBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function TowerRankBase:onRankingReward(container)
   local parentNode = container:getVarNode("mPopUpNode")
   if parentNode then 
       parentNode:removeAllChildren()
       RankRewardPopCCB = ScriptContentBase:create("Tower_Popup")
       parentNode:addChild(RankRewardPopCCB)
       RankRewardPopCCB:registerFunctionHandler(RankRewardPopFunction)
       RankRewardPopCCB:setAnchorPoint(ccp(0.5,0.5))
       TowerRankBase:setRewardPopCCB(RankRewardPopCCB)
   end
end
function RankRewardPopFunction(eventName,container)
    if eventName == "onClose" then
        local parentNode = selfContainer:getVarNode("mPopUpNode")
        if parentNode then
            parentNode:removeAllChildren()
        end
    end
end
function TowerRankBase:setRewardPopCCB(container)
    local scrollview = container:getVarScrollView("mContent")
    local cfg =  ConfigManager.getTowerRank()
    for k,value in pairs (cfg) do
        local cell = CCBFileCell:create()
        cell:setCCBFile(RankRewardContent.ccbiFile)
        local panel = common:new({data = value}, RankRewardContent)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)
    end
    scrollview:orderCCBFileCells()
    scrollview:setTouchEnabled(true)
    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@MineRankPrize") })
end
function RankRewardContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local RewardCfg =  ConfigManager.getTowerRank()
    local stringTable = {}
    if self.data.id>1 and RewardCfg[self.data.id].minRank-RewardCfg[self.data.id-1].minRank >1 then
        stringTable["mTitleTxt"] = RewardCfg[self.data.id-1].minRank+1 .."-".. RewardCfg[self.data.id].minRank
    else
        stringTable["mTitleTxt"] = common:getLanguageString("@FishingRankingNumber", RewardCfg[self.data.id].minRank ) 
    end
    NodeHelper:setStringForLabel(container,stringTable)
    local Items = self.data.reward
    NodeHelper:setNodesVisible(container,{mPassed = false})
    for i = 1 ,4 do
         local parentNode=container:getVarNode("mPosition"..i)
         parentNode:removeAllChildren()
          if Items[i] then
            local ItemNode = ScriptContentBase:create("CommItem")
            ItemNode:setScale(0.8)
            --ItemNode:registerFunctionHandler(ItemCCB.onFunction)
            ItemNode.Reward= Items[i]
            NodeHelper:setNodesVisible(ItemNode,{selectedNode=false,mStarNode=false,nameBelowNode=false, mPoint = false})
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(Items[i].type, Items[i].itemId, Items[i].count)
            local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
            local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setMenuItemImage(ItemNode, {mHand1 = {normal = normalImage}})
            NodeHelper:setSpriteImage(ItemNode, {mPic1 = resInfo.icon, mFrameShade1 = iconBg})
            NodeHelper:setStringForLabel(ItemNode,{mNumber1_1=Items[i].count})
            parentNode:addChild(ItemNode)
        end
    end
end
function ItemCCB.onFunction(eventName, container)
    if eventName=="onHand1" then
     GameUtil:showTip(container:getVarNode('mPic1'), container.Reward)
    end
end
function TowerRankBase:onEnter(container)
    --parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    selfContainer=container
    NodeHelper:setNodesVisible(container,{mTeam=false,mDaily=true})
    --local StringTable={}
    --StringTable["mDailyTopTxt"]=common:getLanguageString("@UrLotteryRank")
    --StringTable["mDailyTitle"]=common:getLanguageString("@GloryHoleranking02")
    --StringTable["mPurpleTxt"]=common:getLanguageString("@PVPAutoTxt")
    --NodeHelper:setStringForLabel(container,StringTable)
    --Bg
    container:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())

    local Activity6_pb = require("Activity6_pb")
    local msg = Activity6_pb.SeasonTowerReq()
    msg.action = 1
    common:sendPacket(HP_pb.ACTIVITY194_SEASON_TOWER_C, msg, true)

    container.mScrollView=container:getVarScrollView("mContent")
    TowerRankBase:ReSizeScrollview(container.mScrollView)
end
function TowerRankBase:ReSizeScrollview(scrollView)
    local logicSize = ccp(GameConfig.ScreenSize.width, GameConfig.ScreenSize.height)
    local realSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
    local offY = realSize.height - logicSize.y
    local oldSize = scrollView:getViewSize()
    oldSize.height = oldSize.height + offY
    scrollView:setViewSize(oldSize)
end
function TowerRank_refresh()
    TowerRankBase:refresh(selfContainer)
end
function TowerRankBase:refresh(container)
    if container==nil then return end
    local TowerDataBase = require "Tower.TowerPageData"
    TowerRankInfo=TowerDataBase:getRank()
    if container and container.mScrollView then
        TowerRankBase:initScrollView(container)
    end
    local SelfTable=TowerRankInfo
    local StringTable={}
    local VisableTable={}
    local SpriteImg=GameConfig.ArenaRankingIcon[1]
    if SelfTable.selfRank==2 then
        SpriteImg=GameConfig.ArenaRankingIcon[2]
    elseif SelfTable.selfRank==3 then
        SpriteImg=GameConfig.ArenaRankingIcon[3]
    end
    NodeHelper:setSpriteImage(container,{mRankSprite=SpriteImg})
    VisableTable["mRankSprite"]=(SelfTable.selfRank<4 and SelfTable.selfRank~=0)
    StringTable["mRankText"]=SelfTable.selfRank
    if SelfTable.selfRank==0 then
        StringTable["mSelfRankText"]="-"
    end
    StringTable["mPlayerScore"]=SelfTable.Score
    StringTable["mPlayerName"]=SelfTable.selfName
    local Stage = 0
    local TakedId = require("Tower.TowerPageData"):getData().takedId
    Stage = #TakedId
    StringTable["mSelfTxt"]= common:getLanguageString("@SeasonTowerXstage",Stage) .." ".. os.date("%Y/%m/%d %H:%M:%S", math.floor(SelfTable.selfDoneTime/1000))
    if SelfTable.selfFloor == 0 then
        StringTable["mSelfTxt"] = "-"
        VisableTable["mRankSprite"] = false
        StringTable["mRankText"]="-"
    end
    NodeHelper:setStringForLabel(container,StringTable)
    NodeHelper:setNodesVisible(container,VisableTable)

    local NewHeadIconItem = require("NewHeadIconItem")
    local parentNode = container:getVarNode("mSelfHeadNode")
    parentNode:removeAllChildrenWithCleanup(true)
    local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:addChild(headNode)
    NodeHelper:setNodesVisible(headNode, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                                mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false ,mLvNode=false})
     local icon = common:getPlayeIcon(1,SelfTable.selfHead)
     if NodeHelper:isFileExist(icon) then
         NodeHelper:setSpriteImage(headNode, { mHead = icon })
     end
end
function TowerRankBase:initScrollView(container)
    local RankTable = TowerRankInfo.otherItem
    if RankTable== nil then return end
    for i=1 ,#RankTable do
        local info=RankTable[i]
        local cell = CCBFileCell:create()
        cell:setCCBFile(RankingContent.ccbiFile)
        local handler = common:new({data = info,id = i}, RankingContent)
        cell:registerFunctionHandler(handler)
        container.mScrollView:addCell(cell)
    end
    
    container.mScrollView:orderCCBFileCells()
end
function RankingContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local VisableTable={}
    local StringTable={}
    local PosY = container:getPositionY()
    container:setPositionX(600*self.data.rank)
    local array = CCArray:create()
    array:addObject(CCMoveTo:create(0.3, ccp(0,PosY)))
    container:runAction(CCSequence:create(array))
    local SpriteImg=GameConfig.ArenaRankingIcon[1]
    if self.data.rank==2 then
        SpriteImg=GameConfig.ArenaRankingIcon[2]
    elseif self.data.rank==3 then
        SpriteImg=GameConfig.ArenaRankingIcon[3]
    end
    VisableTable["mRankSprite"]=(self.data.rank<4)
    StringTable["mRankText"]=self.data.rank
    StringTable["mPlayerName"]=self.data.name
    local timeTxt = common:getLanguageString("@SeasonTowerXstage",self.data.MaxFloor) .." "..os.date("%Y/%m/%d %H:%M:%S", math.floor(self.data.doneTime/1000))
     if self.data.MaxFloor -1 == 0 then
       timeTxt = "-"
    end
    StringTable["mDesc"]= timeTxt
    NodeHelper:setStringForLabel(container,StringTable)
    NodeHelper:setNodesVisible(container,VisableTable)
    NodeHelper:setSpriteImage(container,{mRankSprite=SpriteImg})

    local NewHeadIconItem = require("NewHeadIconItem")
    if container==nil then return end
    local parentNode = container:getVarNode("mHeadNode")
    parentNode:removeAllChildrenWithCleanup(true)
    local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
    headNode:setAnchorPoint(ccp(0.5, 0.5))
    parentNode:addChild(headNode)
    NodeHelper:setNodesVisible(headNode, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                                mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false ,mLvNode=false})
     local icon = common:getPlayeIcon(1,self.data.headIcon)
     if NodeHelper:isFileExist(icon) then
         NodeHelper:setSpriteImage(headNode, { mHead = icon })
     end
end
function TowerRankBase:setTime(txt)
   if selfContainer and txt then
        NodeHelper:setStringForLabel(selfContainer,{mCountDown = common:getLanguageString("@SeasonTowerEndTime",txt)})
   end
end

-- 說明頁
function TowerRankBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GLORY_HOLE_RANKING)
end
local CommonPage = require('CommonPage')
TowerRankPage = CommonPage.newSub(TowerRankBase, thisPageName, option)

return TowerRankPage
