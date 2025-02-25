--------------------------
--[[
    背景:mBg
    每日Node:mDaily
    每日標題:mDailyTitle
    每日helpBtn:onDailyHelp
    每日上半部標題:mDailyTopTxt
    個人紅底:mSelfRedNode
    個人籃底:mSelfBlueNode
    個人頭像:mSelfHeadNode
    個人分數:mPlayerScore
    個人姓名:mPlayerName
    個人名次文字:mSelfRankText
    個人名次圖:mSelfRankSprite
    Daily領獎按鈕:onDailyReward
    DailyScrollview:mDailyScrollview
    每日獎項詳細:mDailyRanking
    每日獎項詳細Scrollview:mDailyRankScrollview
    每日獎項Title:mDailyRankingTitle

    隊伍標題:mTeamTitle
    隊伍helpBtn:onTeamHelp
    隊伍Node:mTeam
    Team領獎按鈕:onTeamReward
    隊伍獎項詳細:mTeamRanking
    隊伍獎項詳細Scrollview:mTeamRankScrollview
    隊伍獎項Title:mTeamRankTitle

    隊伍每日標題:mTeamDailyTitle
    隊伍每日第一名紅底:mTeamDailyFirstRedNode
    隊伍每日第一名紅旗:mTeamDailyFirstRedFlag
    隊伍每日第一名藍底:mTeamDailyFirstBlueNode
    隊伍每日第一名藍旗:mTeamDailyFirstBlueFlag
    隊伍每日第一名頭像:mTeamDailyFirstHeadNode
    隊伍每日第一名名稱:mTeamDailyFirstName
    隊伍每日第一名分數:mTeamDailyFirstScore

    隊伍每日第二名紅底:mTeamDailySecondRedNode
    隊伍每日第二名紅旗:mTeamDailySecondRedFlag
    隊伍每日第二名藍底:mTeamDailySecondBlueNode
    隊伍每日第二名藍旗:mTeamDailySecondBlueFlag
    隊伍每日第二名頭像:mTeamDailySecondHeadNode
    隊伍每日第二名名稱:mTeamDailySecondName
    隊伍每日第二名分數:mTeamDailySecondScore

    隊伍活動標題:mTeamActTitle
    隊伍活動第一名紅底:mActFirstRedNode
    隊伍活動第一名紅旗:mActFirstRedFlag
    隊伍活動第一名藍底:mActFirstBlueNode
    隊伍活動第一名藍底:mActFirstBlueFlag
    隊伍活動第一名頭像:mActFirstHeadNode
    隊伍活動第一名名稱:mActFirstName
    隊伍活動第一名分數:mActFirstScore

    隊伍活動第二名紅底:mActSecondRedNode
    隊伍活動第二名紅旗:mActSecondRedFlag
    隊伍活動第二名藍底:mActSecondBlueNode
    隊伍活動第二名藍底:mActSecondBlueFlag
    隊伍活動第二名頭像:mActSecondHeadNode
    隊伍活動第二名名稱:mActSecondName
    隊伍活動第二名分數:mActSecondScore

]]--
-------------------------------


local NodeHelper = require("NodeHelper")
local thisPageName = 'GloryHolePage'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");
local UserInfo=require("UserInfo")
local GloryHoleDataBase=require("GloryHole.GloryHolePageData")
local MissionMainPage = require("MissionMainPage")

local RewardCfg=ConfigManager.getGloryHoleRankRewardCfg()

local selfContainer
local GloryHoleRankBase = {}
local parentPage = nil

local ItemCCB = {}

local RankingContent = {
    ccbiFile = "GloryHoleRankingTeamContent.ccbi",
}
local RewardContent={
    ccbiFile = "GloryHoleRankingRewardContent.ccbi",
}

local option = {
    ccbiFile = "GloryHoleRanking.ccbi",
    handlerMap =
    {
        onDailyReward="onDailyReward",
        onDailyHelp = "onHelp",
        onClose="onClose"
    },
}

local opcodes = {
    ACTIVITY175_GLORY_HOLE_S = HP_pb.ACTIVITY175_GLORY_HOLE_S,
}
function GloryHoleRankBase:createPage(_parentPage)
    
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
function GloryHoleRankBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function GloryHoleRankBase:onDailyReward(container)
    GloryHoleRankBase:BuildRewardScrollview(container)
    NodeHelper:setNodesVisible(container,{mDailyRanking=true})
    NodeHelper:setStringForLabel(container,{mDailyRankTitle=common:getLanguageString("@GloryHoleranking02")})
end
function GloryHoleRankBase:onClose(container)
    NodeHelper:setNodesVisible(container,{mDailyRanking=false})
end
function GloryHoleRankBase:BuildRewardScrollview(container)
    local Scrollview=container:getVarScrollView("mDailyRankScrollview")
    Scrollview:removeAllCell()
    --GloryHoleRankBase:ReSizeScrollview(Scrollview)
    for i=1,#RewardCfg do
        local Data=RewardCfg[i].DailyReward
        local cell = CCBFileCell:create()
        cell:setCCBFile(RewardContent.ccbiFile)
        local handler = common:new({id = i,Reward=Data}, RewardContent)
        cell:registerFunctionHandler(handler)
        Scrollview:addCell(cell)
    end
    Scrollview:orderCCBFileCells()
end
function RewardContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local VisableTable={}
    for i=1,4 do
        local parentNode=container:getVarNode("mPosition"..i)
        parentNode:removeAllChildren()
        if self.Reward[i] then
            local ItemNode = ScriptContentBase:create("CommItem")
            ItemNode:setScale(0.8)
            ItemNode:registerFunctionHandler(ItemCCB.onFunction)
            ItemNode.Reward= self.Reward[i]
            NodeHelper:setNodesVisible(ItemNode,{selectedNode=false,mStarNode=false,nameBelowNode=false, mPoint = false})
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.Reward[i].type, self.Reward[i].itemId, self.Reward[i].count)
            local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
            local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
            NodeHelper:setMenuItemImage(ItemNode, {mHand1 = {normal = normalImage}})
            NodeHelper:setSpriteImage(ItemNode, {mPic1 = resInfo.icon, mFrameShade1 = iconBg})
            NodeHelper:setStringForLabel(ItemNode,{mNumber1_1=self.Reward[i].count})
            parentNode:addChild(ItemNode)
        end
    end
    local string=""
    if self.id>1 and RewardCfg[self.id].minRank-RewardCfg[self.id-1].minRank >1 then
        string=RewardCfg[self.id-1].minRank+1 .."-".. RewardCfg[self.id].minRank
    else
        string=common:getLanguageString("@FishingRankingNumber", RewardCfg[self.id].minRank ) 
    end
    NodeHelper:setStringForLabel(container,{mRankText=string})
end
function ItemCCB.onFunction(eventName, container)
    if eventName=="onHand1" then
     GameUtil:showTip(container:getVarNode('mPic1'), container.Reward)
    end
end
function GloryHoleRankBase:onEnter(container)
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    selfContainer=container
    NodeHelper:setNodesVisible(container,{mTeam=false,mDaily=true})
    local StringTable={}
    StringTable["mDailyTopTxt"]=common:getLanguageString("@UrLotteryRank")
    StringTable["mDailyTitle"]=common:getLanguageString("@GloryHoleranking02")
    StringTable["mPurpleTxt"]=common:getLanguageString("@PVPAutoTxt")
    NodeHelper:setStringForLabel(container,StringTable)
    --Bg
    container:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())

    --GloryRankInfo=GloryHoleDataBase:getRank()
    local Activity5_pb = require("Activity5_pb")
    local msg=Activity5_pb.GloryHoleReq()
    msg.action=1
    common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)

    container.mDailyScrollView=container:getVarScrollView("mDailyScrollview")
    GloryHoleRankBase:ReSizeScrollview(container.mDailyScrollView)
end
function GloryHoleRankBase:ReSizeScrollview(scrollView)
    local logicSize = ccp(GameConfig.ScreenSize.width, GameConfig.ScreenSize.height)
    local realSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
    local offY = realSize.height - logicSize.y
    local oldSize = scrollView:getViewSize()
    oldSize.height = oldSize.height + offY
    scrollView:setViewSize(oldSize)
    if offY>0 then
        scrollView:setPositionY(scrollView:getPositionY()-105)
    end
end
function GloryHoleDailyRank_refresh()
    GloryHoleRankBase:refresh(selfContainer)
end
function GloryHoleRankBase:refresh(container)
    if container==nil then return end
    GloryRankInfo=GloryHoleDataBase:getRank()
    if container and container.mDailyScrollView then
        GloryHoleRankBase:initScrollView(container)
    end
    local SelfTable=GloryRankInfo.Self
    local StringTable={}
    local VisableTable={}
    local SpriteImg=GameConfig.ArenaRankingIcon[1]
    if SelfTable.Rank==2 then
        SpriteImg=GameConfig.ArenaRankingIcon[2]
    elseif SelfTable.Rank==3 then
        SpriteImg=GameConfig.ArenaRankingIcon[3]
    end
    NodeHelper:setSpriteImage(container,{mSelfRankSprite=SpriteImg})
    VisableTable["mSelfRedNode"]=(SelfTable.teamId==2)
    VisableTable["mSelfBlueNode"]=(SelfTable.teamId==1)
    VisableTable["mSelfWhiteNode"] = (SelfTable.teamId==3)
    VisableTable["mSelfRankSprite"]=(SelfTable.Rank<4 and SelfTable.Rank~=0)
    StringTable["mSelfRankText"]=SelfTable.Rank
    if SelfTable.Rank==0 then
        StringTable["mSelfRankText"]="-"
    end
    StringTable["mPlayerScore"]=SelfTable.Score
    StringTable["mPlayerName"]=SelfTable.Name
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
     local icon = common:getPlayeIcon(1,SelfTable.headerId)
     if NodeHelper:isFileExist(icon) then
         NodeHelper:setSpriteImage(headNode, { mHead = icon })
     end
end
function GloryHoleRankBase:initScrollView(container)
    local PageTable=GloryRankInfo.Daily
    if PageTable== nil then return end
    for i=#PageTable ,1 ,-1 do
        local Info=PageTable[i]
        local cell = CCBFileCell:create()
        cell:setCCBFile(RankingContent.ccbiFile)
        local handler = common:new({playerId = Info.playerId,Score=Info.Score,Name=Info.Name,teamId=Info.teamId,Rank=Info.Rank,headerId=Info.headerId}, RankingContent)
        cell:registerFunctionHandler(handler)
        container.mDailyScrollView:addCell(cell)
    end
    
    container.mDailyScrollView:orderCCBFileCells()
end
function RankingContent:onRefreshContent(ccbRoot)
--[[mRankSprite
    mRankText
    mHeadNode
    mFightingNum
    mArenaName
    mBlue
    mRed
    ]]
    local container = ccbRoot:getCCBFileNode()
    local VisableTable={}
    local StringTable={}
    local SpriteImg=GameConfig.ArenaRankingIcon[1]
    if self.Rank==2 then
        SpriteImg=GameConfig.ArenaRankingIcon[2]
    elseif self.Rank==3 then
        SpriteImg=GameConfig.ArenaRankingIcon[3]
    end
    VisableTable["mRed"]=(self.teamId==2)
    VisableTable["mBlue"]=(self.teamId==1)
    VisableTable["mRankSprite"]=(self.Rank<4)
    StringTable["mRankText"]=self.Rank
    StringTable["mFightingNum"]=self.Score
    StringTable["mArenaName"]=self.Name
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
     local icon = common:getPlayeIcon(1,self.headerId)
     if NodeHelper:isFileExist(icon) then
         NodeHelper:setSpriteImage(headNode, { mHead = icon })
     end
end
-- 說明頁
function GloryHoleRankBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GLORY_HOLE_RANKING)
end
local CommonPage = require('CommonPage')
GloryHolePage = CommonPage.newSub(GloryHoleRankBase, thisPageName, option)

return GloryHolePage
