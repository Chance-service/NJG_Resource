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
    每日獎項詳細Scrollview:mDailyRankingScrollview
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
local thisPageName = 'GloryHoleSubPage_TeamRank'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");
local UserInfo=require("UserInfo")
local GloryHoleDataBase=require("GloryHole.GloryHolePageData")
local MissionMainPage = require("MissionMainPage")
GloryRankInfo={}

local RewardCfg=ConfigManager.getGloryHoleRankRewardCfg()
local ItemCCB={}

local GloryHoleRankBase = {}
local parentPage = nil
local selfContainer

local option = {
    ccbiFile = "GloryHoleRanking.ccbi",
    handlerMap =
    {
        onTeamReward="onTeamReward",
        onTeamHelp = "onHelp",
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
function GloryHoleRankBase:onTeamReward(container)
    NodeHelper:setNodesVisible(container,{mTeamRanking=true})
    GloryHoleRankBase:BuildItem(container)
end
function GloryHoleRankBase:onClose(container)
    NodeHelper:setNodesVisible(container,{mTeamRanking=false})
end
function GloryHoleRankBase:BuildItem(container)
    for i=1,2 do
        local Data=RewardCfg[i].TeamReward
        for j=1,6 do
            local NodeName="ItemPosition"..i.."_"..j
            NodeHelper:setNodesVisible(container,{NodeName=Data[j]})
            local parentNode=container:getVarNode(NodeName)
            parentNode:removeAllChildren()
            if Data[j] then
                local ItemNode = ScriptContentBase:create("CommItem")
                ItemNode:setScale(0.8)
                ItemNode:registerFunctionHandler(ItemCCB.onFunction)
                ItemNode.Reward= Data[j]
                NodeHelper:setNodesVisible(ItemNode,{selectedNode=false,mStarNode=false,nameBelowNode=false, mPoint = false})
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(Data[j].type, Data[j].itemId, Data[j].count)
                local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
                local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
                NodeHelper:setMenuItemImage(ItemNode, {mHand1 = {normal = normalImage}})
                NodeHelper:setSpriteImage(ItemNode, {mPic1 = resInfo.icon, mFrameShade1 = iconBg})
                NodeHelper:setStringForLabel(ItemNode,{mNumber1_1=Data[j].count})
                parentNode:addChild(ItemNode)
            end
        end
    end
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
    NodeHelper:setNodesVisible(container,{mTeam=true,mDaily=false})
    NodeHelper:setStringForLabel(container,{mTeamRankTitle=common:getLanguageString("@GloryHoleranking01")})
    --Bg
    container:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())
    GloryRankInfo=GloryHoleDataBase:getRank()
    local Activity5_pb = require("Activity5_pb")
    local msg=Activity5_pb.GloryHoleReq()
    msg.action=1
    common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)
end
function GloryHoleTeamRank_refresh()
    GloryHoleRankBase:refresh(selfContainer)
end
function GloryHoleRankBase:refresh(container)
    if container==nil then return end
    local PageTable=GloryRankInfo.Team
    if PageTable== nil then return end
    local isOpen = GloryRankInfo.isOpen
    local SelfTeamId=GloryRankInfo.Self.teamId
    NodeHelper:setNodesVisible(container,{mActRedFlag=(SelfTeamId==2 and isOpen),
                                          mActBlueFlag=(SelfTeamId==1 and isOpen)})
    NodeHelper:setStringForLabel(container,{mActBlueScore=PageTable.Team1.Score,mActRedScore=PageTable.Team2.Score})
    if PageTable.Team1.Score and PageTable.Team2.Score then
        if PageTable.Team1.Score>PageTable.Team2.Score then
            NodeHelper:setSpriteImage(container,{mBlueRank="Gloryhole_Ranking_img12.png",mRedRank="Gloryhole_Ranking_img13.png"})
        else
            NodeHelper:setSpriteImage(container,{mBlueRank="Gloryhole_Ranking_img13.png",mRedRank="Gloryhole_Ranking_img12.png"})
        end
    end
    
end
-- 說明頁
function GloryHoleRankBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GLORY_HOLE_RANKING)
end
local CommonPage = require('CommonPage')
GloryHolePage = CommonPage.newSub(GloryHoleRankBase, thisPageName, option)

return GloryHolePage
