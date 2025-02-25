require "HP_pb"
require "ProfRank_pb"
local Const_pb = require("Const_pb")
local NewbieGuideManager = require("NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "Ranking.ProfessionRankingEXPage"
local NodeHelper = require("NodeHelper")
local OSPVPManager = require("OSPVPManager")
local Ranks_pb = require("Ranks_pb")
require("Util.RedPointManager")
local option = {
    ccbiFile = "FightingRankingPageEX.ccbi",
    handlerMap =
    {
        onRank_1 = "onRank_1",
        onRank_2 = "onRank_2",
        onRank_3 = "onRank_3",
        onRank_4 = "onRank_4",


        onHelp = "onHelp",
        onReturn = "onReturn",
        onReward="onReward",
        onClose="onClose"
    },
    -- opcode = opcodes
}

for i = 1, 4 do
    for j = 1, 4 do
        option.handlerMap["onSubBtn" .. i .. j] = "onSubBtn"
    end
end

local RewardCfg=ConfigManager.getRankReward()

local ProfessionRankingEXPageBase = { buttonTable = { }, subButtonTable = { } }
local ProfessionRankingEXPageContent = {
    [1] = { BG = "BG/Activity/Rank_1_bg.png", S9 = "BG/Activity/Rank_5_s9.png" },
    [2] = { BG = "BG/Activity/Rank_2_bg.png", S9 = "BG/Activity/Rank_5_s9.png" },
    [3] = { BG = "BG/Activity/Rank_3_bg.png", S9 = "BG/Activity/Rank_5_s9.png" },
    [4] = { BG = "BG/Activity/Rank_4_bg.png", S9 = "BG/Activity/Rank_5_s9.png" },
}
local titleManager = require("PlayerInfo.TitleManager")
local MonsterCfg = { }
local roleConfig = { }
local ProfessionType = {
    RANK_1 = 1,
    RANK_2 = 2,
    RANK_3 = 3,
    RANK_4 = 4,
}

local PageInfo = {
    curProType = ProfessionType.RANK_1,
    subType = 1,
    -- ProfessionType.WARRIOR,
    selfRank = "--",
    selfRankInfo = { },
    rankInfos = { },
    viewHolder = { },
    -- 玩家排行数据
    playerItemInfo = nil,
    -- 帮会排行数据
    allianceItemInfo = nil,
    -- 自己的排行数据
    mySelf = nil,
    -- 自己帮会排行数据
    mySelfAlliance = nil,
    itemContainer = { }
}
local TopNodes={
    [1] = { Head = "mFirstHead" , Name = "mFirstName" , Num = "mFirstNum" },
    [2] = { Head = "mSecondHead" , Name = "mSecondName" , Num = "mSecondNum" },
    [3] = { Head = "mThirdHead" , Name = "mThirdName" , Num = "mThirdNum" },
}
local RewardContent={
    ccbiFile = "FightingRankingMissionContent.ccbi",
}
local PlayerSignaturePositionX = 0
local PlayerSignaturePositionY = 0

local currentRankType = Const_pb.LEVEL_ALL_RANK


local RankData = {


}
local RewardData={ }
local AchivedData={}
local PageTable={}
local PlayerInfo={}
----------------------------------------------------
function ProfessionRankingEXPageContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    PageInfo.itemContainer[self.id] = container
    -- 是否是联盟排行
    local isGuild = PageInfo.curProType == 4
    local contentId = self.id
    -- self.serverData
    local itemInfo = PageInfo.rankInfos[contentId]
    local test = container:getVarNode("mHeadNode")
    NodeHelper:setNodesVisible(container, { mGuildRankNode = isGuild, mRankNode = not isGuild })
    if isGuild then
        ProfessionRankingEXPageBase:setGuildMessage(container, itemInfo, false)
    else
        ProfessionRankingEXPageBase:setPlayerMessage(container, itemInfo, false, self.id)
    end
end

function ProfessionRankingEXPageContent:onHand(container)
    local contentId = self.id
    local itemInfo = PageInfo.rankInfos[contentId]

   -- PageManager.viewPlayerInfo(itemInfo.playerId, true)
end

function ProfessionRankingEXPageBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    container:registerMessage(MSG_REFRESH_REDPOINT)
    --self:initData()

    -- NodeHelper:initScrollView( container,"mRankingBtnContent",4)
    ProfessionRankingEXPageBase.container = container

   -- self:initPage(container)
    --self:selectTab(container, PageInfo.curProType)
    --self:selectSubBtnTab(container, PageInfo.subType)
    container.scrollview = container:getVarScrollView("mRankingContent")
    self:refreshPage(container)
    self:getPageInfo(container)
    local idx=0
    for k,v in pairs (RewardData) do
        idx=idx+1
    end
    self:refreshAllPoint(container)
    
    container.scrollview = container:getVarScrollView("mRankingContent")
    NodeHelper:autoAdjustResizeScrollview(container.scrollview)
    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite2"))
    container.scrollview:orderCCBFileCells()

    local Bg=container:getVarNode("mBg")
    local Scale=NodeHelper:getScaleProportion()
    Bg:setScale(Scale*1.2)
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FIGHT_NUM)
end

function ProfessionRankingEXPageBase:initData()
    PageInfo.curProType = 1
    PageInfo.subType = 1
    RankData = { }
    PageInfo.itemContainer = { }
end

function ProfessionRankingEXPageBase:initPage(container)
    self:registerPacket(container)
    UserInfo.sync()
    roleConfig = ConfigManager.getRoleCfg()
   
    ProfessionRankingEXPageBase.buttonTable = { }
    ProfessionRankingEXPageBase.subButtonTable = { }
    for i = 1, 4 do
        table.insert(ProfessionRankingEXPageBase.buttonTable, container:getVarMenuItemImage("mButton_" .. i))
    end

    for i = 1, #RankType[ProfessionType.RANK_1] do
        if ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_1] == nil then
            ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_1] = { }
        end
        table.insert(ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_1], container:getVarMenuItemImage("mSubBtn1" .. i))
        NodeHelper:setStringForLabel(container, { ["mSubBtnText" .. ProfessionType.RANK_1 .. i] = common:getLanguageString(SubBtnText[ProfessionType.RANK_1][i]) })
    end

    for i = 1, #RankType[ProfessionType.RANK_2] do
        if ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_2] == nil then
            ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_2] = { }
        end
        table.insert(ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_2], container:getVarMenuItemImage("mSubBtn2" .. i))
        NodeHelper:setStringForLabel(container, { ["mSubBtnText" .. ProfessionType.RANK_2 .. i] = common:getLanguageString(SubBtnText[ProfessionType.RANK_2][i]) })
    end

    for i = 1, #RankType[ProfessionType.RANK_3] do
        if ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_3] == nil then
            ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_3] = { }
        end
        table.insert(ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_3], container:getVarMenuItemImage("mSubBtn3" .. i))
        NodeHelper:setStringForLabel(container, { ["mSubBtnText" .. ProfessionType.RANK_3 .. i] = common:getLanguageString(SubBtnText[ProfessionType.RANK_3][i]) })
    end

    for i = 1, #RankType[ProfessionType.RANK_4] do
        if ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_4] == nil then
            ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_4] = { }
        end
        table.insert(ProfessionRankingEXPageBase.subButtonTable[ProfessionType.RANK_4], container:getVarMenuItemImage("mSubBtn4" .. i))
        NodeHelper:setStringForLabel(container, { ["mSubBtnText" .. ProfessionType.RANK_4 .. i] = common:getLanguageString(SubBtnText[ProfessionType.RANK_4][i]) })
        container:getVarNode("mSubBtnText" .. ProfessionType.RANK_4 .. i):setScale(10)
    end

    NodeHelper:setNodesVisible(container, { mExchangeContentNode = false, mSelfNode = false })

    local mPlayerSignature = container:getVarLabelTTF("mPlayerSignature")
    PlayerSignaturePositionX, PlayerSignaturePositionY = mPlayerSignature:getPosition()
end

function ProfessionRankingEXPageBase:refreshPage(container)

    local bl = true
    if bl then
    else
        local lb2Str = {
            mName = UserInfo.roleInfo.name,
            -- mName					= UserInfo.getStageAndLevelStr() .. " " .. UserInfo.roleInfo.name,
            mLv = UserInfo.getStageAndLevelStr(),
            -- mRankingNum = common:getLanguageString("@Ranking") .. PageInfo.selfRank,
            -- mFightingNum = common:getLanguageString("@Fighting") .. UserInfo.roleInfo.marsterFight-- UserInfo.roleInfo.fight
        }

        NodeHelper:setStringForLabel(container, lb2Str)
        --[[    local showCfg = LeaderAvatarManager.getCurShowCfg()
	local headPic = showCfg.icon[UserInfo.roleInfo.prof]]
        --local icon, bgIcon = common:getPlayeIcon(UserInfo.roleInfo.prof, GameConfig.headIconNew or UserInfo.playerInfo.headIcon)
        --NodeHelper:setSpriteImage(container, { mPic = icon, mPicBg = bgIcon })

        if PageInfo.curProType == ProfessionType.RANK_1 then
            NodeHelper:setStringForLabel(container, { mFightingNum = common:getLanguageString("@Fighting") .. itemInfo.rankData })
        elseif PageInfo.curProType == ProfessionType.RANK_2 then
            NodeHelper:setStringForLabel(container, { mFightingNum = common:getLanguageString("@Fighting") .. itemInfo.rankData })
        elseif PageInfo.curProType == ProfessionType.RANK_3 then
            NodeHelper:setStringForLabel(container, { mFightingNum = common:getLanguageString("@Fighting") .. itemInfo.rankData })
        end

    end

end

function ProfessionRankingEXPageBase:getPageInfo(container)
    if ProfessionRankingEXCacheInfo[PageInfo.curProType][PageInfo.subType] ~= nil then
        self:onReceiveRankingInfo(container, ProfessionRankingEXCacheInfo[PageInfo.curProType][PageInfo.subType])
    end

end

function ProfessionRankingEXPageBase:onExecute(container)

end

function ProfessionRankingEXPageBase:onExit(container)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container)
end

function ProfessionRankingEXPageBase:onReturn(container)
    container:removeMessage(MSG_REFRESH_REDPOINT)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    PageManager.popPage(thisPageName)
end

function ProfessionRankingEXPageBase:onReward(container)
    NodeHelper:setNodesVisible(container,{mMission=true})
    ProfessionRankingEXPageBase:BuildRewardScrollview(container)
end
function ProfessionRankingEXPageBase:BuildRewardScrollview(container)
    local Scrollview=container:getVarScrollView("mMissionScrollview")
    if not Scrollview then return end
    Scrollview:removeAllCell()
    local NotAchiveTable={}
    local CanGetTable={}
    local GotTable={}

    for _,data in pairs (PageTable)  do
        if AchivedData[data.id] and RewardData[data.id] then
            table.insert(CanGetTable,data)
        elseif AchivedData[data.id] and not RewardData[data.id] then
            table.insert(GotTable,data)
            
        elseif not AchivedData[data.id] then
            table.insert(NotAchiveTable,data)
        end
    end
    local function sortByMission(tbl)
        table.sort(tbl, function(a, b)
            return a.mission < b.mission
        end)
    end

    sortByMission(GotTable)
    sortByMission(CanGetTable)
    sortByMission(NotAchiveTable)

    local NowGoalString=common:getLanguageString("@Rankserverallclear")
    if #NotAchiveTable~=0 then
        NowGoalString = common:getLanguageString(NotAchiveTable[1].content,NotAchiveTable[1].mission)
    end
    if NotAchiveTable[1] and NotAchiveTable[1].type == 3 then
        local stage = NotAchiveTable[1].mission
        local configData = ConfigManager.getNewMapCfg()[stage]
        local ch = configData.Chapter
        local childCh = configData.Level
        local string = ch .. "-" .. childCh
        NowGoalString = common:getLanguageString(NotAchiveTable[1].content,string)
    end
    NodeHelper:setStringForLabel(container,{mNowGoal=NowGoalString})
    local FinalTable={}
    FinalTable=tableSync(CanGetTable,tableSync(NotAchiveTable,GotTable)) or {}
     for key,_data in pairs (FinalTable) do
        local Data=_data
        local cell = CCBFileCell:create()
        cell:setCCBFile(RewardContent.ccbiFile)
        cell:setScale(0.95)
        local String=common:getLanguageString(Data.content,Data.mission)
        if Data.type == 3 then
            local configData = ConfigManager.getNewMapCfg()[Data.mission]
            local ch = configData.Chapter
            local childCh = configData.Level
            String= ch .. "-" .. childCh
            String=common:getLanguageString(Data.content,String)
        end
        local handler = common:new({id = Data.id,Type=Data.type,lang=String,Reward=Data.Reward}, RewardContent)
        cell:registerFunctionHandler(handler)
        Scrollview:addCell(cell)
    end
    Scrollview:orderCCBFileCells()
end
function tableSync(t1, t2)
   if #t1==0 and #t2==0 then return {} end
   if #t1==0 and #t2~=0 then return t2 end
   if #t1~=0 and #t2==0 then return t1 end 
   for k, v in ipairs(t2) do
       table.insert(t1, v)
   end
   return t1
end
function RewardContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local StringTable={}

    local state=1--1:CanGet 2:Got 3:notAchive
    if AchivedData[self.id] and RewardData[self.id] then
        StringTable["mBtnTxt"]=common:getLanguageString("@Draw")
        state=1
    elseif AchivedData[self.id] and not RewardData[self.id] then
        StringTable["mBtnTxt"]=common:getLanguageString("@HasDraw")
        state=2
    elseif not AchivedData[self.id] then
        StringTable["mBtnTxt"]=common:getLanguageString("@Underway")
        state=3
    end
    NodeHelper:setMenuItemsEnabled(container,{mBtn=(state==1)})
    local RankingLobby = require("Ranking.ProfessionRankingLobby")
    local trueType = RankingLobby:getTrueType(PageInfo.curProType, PageInfo.subType)
    local pageId = math.floor(RedPointManager.PAGE_IDS.RANKING_BP_REWARD / 10) * 10 + trueType
    NodeHelper:setNodesVisible(container, { mRedNode = (state == 1) })
    NodeHelper:setNodesVisible(container, { selectedNode = (state == 2) })
    --item
    self.rewardItems={}
    local _type, _id, _count = unpack(common:split(self.Reward, "_"));
    self.rewardItems= {
          type    = tonumber(_type),
           itemId  = tonumber(_id),
          count   = tonumber(_count),
          }
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(self.rewardItems.type, self.rewardItems.itemId,self.rewardItems.count)
    local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
    NodeHelper:setNodesVisible(container,{mStarNode=false,nameBelowNode=false, mPoint = false})
    local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
    NodeHelper:setMenuItemImage(container, {mHand1 = {normal = normalImage}})
    NodeHelper:setSpriteImage(container, {mPic1 = resInfo.icon, mFrameShade1 = iconBg})
    NodeHelper:setStringForLabel(container,{mNumber1_1=self.rewardItems.count})
    --String
    StringTable["mGoal"] = self.lang
    local NameNode=container:getVarNode("mPlayerName")
    if PlayerInfo[self.id] then
        StringTable["mPlayerName"]=PlayerInfo[self.id].playerName 
        NameNode:setPositionX(-40)
    else
         StringTable["mPlayerName"]=common:getLanguageString("@Rankservernoplayer")
         NameNode:setPositionX(-155)
    end
    NodeHelper:setStringForLabel(container,StringTable)
    --Head
    local NewHeadIconItem = require("NewHeadIconItem")
    local parentNode = container:getVarNode("mHeadNode")
    if parentNode then
        if  PlayerInfo[self.id] then
            parentNode:removeAllChildrenWithCleanup(true)
            local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
            headNode:setAnchorPoint(ccp(0.5, 0.5))
            
            parentNode:addChild(headNode)
            NodeHelper:setNodesVisible(headNode, {mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false,
                mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false, mLvNode = false})
            local icon = common:getPlayeIcon(1, PlayerInfo[self.id].HeadIcon)
            if NodeHelper:isFileExist(icon) then
                NodeHelper:setSpriteImage(headNode, {mHead = icon})
            end
        else
            parentNode:removeAllChildrenWithCleanup(true)
        end
    end
end
function RewardContent:onHand1(container)
    GameUtil:showTip(container:getVarNode('mPic1'), self.rewardItems)
end
function RewardContent:onBtn(container)
    if RewardData then
       local RankingLobby=require("Ranking.ProfessionRankingLobby")
       RankingLobby:GetReward(RewardData)
    end
end
function ProfessionRankingEXPageBase:onClose(container)
    NodeHelper:setNodesVisible(container,{mMission=false})
end

function ProfessionRankingEXPageBase:onRank_1(container, index)
    if PageInfo.curProType == ProfessionType.RANK_1 then
        -- ProfessionRankingEXPageBase:selectTab(container, index)
        return
    end
    PageInfo.subType = 1
    PageInfo.curProType = ProfessionType.RANK_1
    ProfessionRankingEXPageBase:selectTab(ProfessionRankingEXPageBase.container, ProfessionType.RANK_1)
    ProfessionRankingEXPageBase:selectSubBtnTab(ProfessionRankingEXPageBase.container, PageInfo.subType)
    ProfessionRankingEXPageBase:refreshPage(ProfessionRankingEXPageBase.container)
    ProfessionRankingEXPageBase:getPageInfo(ProfessionRankingEXPageBase.container)
end

function ProfessionRankingEXPageBase:onRank_2(container, index)
    if PageInfo.curProType == ProfessionType.RANK_2 then
        -- ProfessionRankingEXPageBase:selectTab(container, index)
        return
    end
    PageInfo.subType = 1
    PageInfo.curProType = ProfessionType.RANK_2
    ProfessionRankingEXPageBase:selectTab(ProfessionRankingEXPageBase.container, ProfessionType.RANK_2)
    ProfessionRankingEXPageBase:selectSubBtnTab(ProfessionRankingEXPageBase.container, PageInfo.subType)
    ProfessionRankingEXPageBase:refreshPage(ProfessionRankingEXPageBase.container)
    ProfessionRankingEXPageBase:getPageInfo(ProfessionRankingEXPageBase.container)
end

function ProfessionRankingEXPageBase:onRank_3(container, index)
    if PageInfo.curProType == ProfessionType.RANK_3 then
        -- ProfessionRankingEXPageBase:selectTab(container, index)
        return
    end

    PageInfo.subType = 1
    PageInfo.curProType = ProfessionType.RANK_3
    ProfessionRankingEXPageBase:selectTab(ProfessionRankingEXPageBase.container, ProfessionType.RANK_3)
    ProfessionRankingEXPageBase:selectSubBtnTab(ProfessionRankingEXPageBase.container, PageInfo.subType)
    ProfessionRankingEXPageBase:refreshPage(ProfessionRankingEXPageBase.container)
    ProfessionRankingEXPageBase:getPageInfo(ProfessionRankingEXPageBase.container)
end

function ProfessionRankingEXPageBase:onRank_4(container, index)
    if PageInfo.curProType == ProfessionType.RANK_4 then
        -- ProfessionRankingEXPageBase:selectTab(container, index)
        return
    end

    PageInfo.subType = 1
    PageInfo.curProType = ProfessionType.RANK_4
    ProfessionRankingEXPageBase:selectTab(ProfessionRankingEXPageBase.container, ProfessionType.RANK_4)
    ProfessionRankingEXPageBase:selectSubBtnTab(ProfessionRankingEXPageBase.container, PageInfo.subType)
    ProfessionRankingEXPageBase:refreshPage(ProfessionRankingEXPageBase.container)
    ProfessionRankingEXPageBase:getPageInfo(ProfessionRankingEXPageBase.container)
end

function ProfessionRankingEXPageBase:onSubBtn(container, eventName)
    local index = tonumber(string.sub(eventName, 10, string.len(eventName)))
    local subType = index
    if PageInfo.subType == subType then
        return
    end
    PageInfo.subType = index
    ProfessionRankingEXPageBase:selectSubBtnTab(ProfessionRankingEXPageBase.container, PageInfo.subType)
    ProfessionRankingEXPageBase:refreshPage(ProfessionRankingEXPageBase.container)
    ProfessionRankingEXPageBase:getPageInfo(ProfessionRankingEXPageBase.container)
end

function ProfessionRankingEXPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_FIGHT_NUM)
end


function ProfessionRankingEXPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onLocalPlayerInfo then
                if container.scrollview then
                    container.scrollview:refreshAllCell()
                end
                self:refreshPage(container)
            end
        end
    elseif typeId == MSG_REFRESH_REDPOINT then
        self:refreshAllPoint(container)
    end
end

function ProfessionRankingEXPageBase:refreshAllPoint(container)
    local RankingLobby = require("Ranking.ProfessionRankingLobby")
    local trueType = RankingLobby:getTrueType(PageInfo.curProType, PageInfo.subType)
    local pageId = math.floor(RedPointManager.PAGE_IDS.RANKING_BP_TREASURE / 10) * 10 + trueType
    NodeHelper:setNodesVisible(container, { mRedNode = RedPointManager_getShowRedPoint(pageId) })
end

function ProfessionRankingEXPageBase:onReceiveRankingInfo(container, msg)
   if PageInfo.curProType==5 then
        -- 英雄排行数据
        PageInfo.playerItemInfo = msg.HeroItemInfo
          -- 自己的排行数据
         PageInfo.selfRankInfo = msg.mySelf
         PageInfo.rankInfos =msg.HeroItemInfo
   else
         -- 玩家排行数据
         PageInfo.playerItemInfo = msg.playerItemInfo
         -- 帮会排行数据
         PageInfo.allianceItemInfo = msg.allianceItemInfo
         -- 自己的排行数据
         PageInfo.selfRankInfo = msg.mySelf
         if msg:HasField("mySelfAlliance") then
             -- 自己帮会排行数据
             PageInfo.mySelfAlliance = msg.mySelfAlliance
         else
             PageInfo.mySelfAlliance = nil
         end

         local isGuild = PageInfo.curProType == 4
         if isGuild then
             PageInfo.rankInfos = msg.allianceItemInfo
         else
             PageInfo.rankInfos = msg.playerItemInfo
         end
        
         PageInfo.selfRankInfo = msg.mySelf
    end
     table.sort(PageInfo.rankInfos, function(p1, p2)
             if not p2 then return true end
             if not p1 then return false end

             return p1.rankNum > p2.rankNum
         end )
    -----下面是自己的数据

    NodeHelper:setNodesVisible(container, { mSelfGuildRankNode = isGuild, mSelfRankNode = not isGuild })
    if isGuild then
        ProfessionRankingEXPageBase:setGuildMessage(container, PageInfo.mySelfAlliance, true)
    else
        ProfessionRankingEXPageBase:setPlayerMessage(container, PageInfo.selfRankInfo, true)
    end
    -- 下面是创建item数据
    self:rebuildAllItem(container)
    --
    NodeHelper:setNodesVisible(container, { mExchangeContentNode = true, mSelfNode = true })
    
    local function resetNameAndNum(startIndex)
        for i = startIndex, 3 do
            local Name = container:getVarLabelTTF(TopNodes[i].Name)
            local Num = container:getVarLabelTTF(TopNodes[i].Num)
            Name:setString("---")
            Num:setString("---")
        end
    end
    
    if #PageInfo.rankInfos == 0 then
        resetNameAndNum(1)
    elseif #PageInfo.rankInfos == 1 then
        resetNameAndNum(2)
    elseif #PageInfo.rankInfos == 2 then
        resetNameAndNum(3)
    end

    --前三數據
   for k, v in pairs(PageInfo.rankInfos) do
    local itemInfo = v
    if itemInfo.rankNum and itemInfo.rankNum <= 3 then
        local NewHeadIconItem = require("NewHeadIconItem")
        local parentNode = container:getVarNode(TopNodes[itemInfo.rankNum].Head)
        if parentNode then
            -- 头像
            parentNode:removeAllChildrenWithCleanup(true)
            local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
            headNode:setAnchorPoint(ccp(0.5, 0.5))
            
            parentNode:addChild(headNode)
            NodeHelper:setNodesVisible(headNode, {mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false,
                mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false, mLvNode = false})
            
            local icon = common:getPlayeIcon(itemInfo.prof, itemInfo.headIcon)
            if PageInfo.curProType==5 then
                local ID= string.format("%02d",itemInfo.itemId).. string.format("%03d",itemInfo.skinId)
                icon=common:getPlayeIcon(nil,ID)
            end
            if NodeHelper:isFileExist(icon) then
                NodeHelper:setSpriteImage(headNode, {mHead = icon})
            end
            --姓名
            local NodeName = TopNodes[itemInfo.rankNum].Name
            container:getVarLabelTTF(NodeName):setString(itemInfo.playerName)
            --數值
            local NumNode = container:getVarLabelTTF(TopNodes[itemInfo.rankNum].Num)
            if currentRankType == Const_pb.CUSTOMPASS_BOSS_RANK then
                --關卡
                if itemInfo.rankData == 0 then
                    NumNode:setString("---")
                else
                    local configData = ConfigManager.getNewMapCfg()[itemInfo.rankData]
                    local ch = configData.Chapter
                    local childCh = configData.Level
                    local String="Chapter " .. ch .. "-" .. childCh
                    NumNode:setString(String)
                    if string.len(String) >8 then
                        NumNode:setScale(0.6)
                    else
                        NumNode:setScale(0.7)
                    end
                end
            elseif currentRankType == Const_pb.LEVEL_ALL_RANK or currentRankType == Const_pb.LEVEL_PROFJS_RANK or currentRankType == Const_pb.LEVEL_PROFGS_RANK or currentRankType == Const_pb.LEVEL_PROFCS_RANK then
                --等級
                NumNode:setString(UserInfo.getOtherLevelStr(itemInfo.rebirthStage, itemInfo.rankData))
            elseif currentRankType == Const_pb.SCORE_ALL_RANK or currentRankType == Const_pb.SCORE_PROFJS_RANK or currentRankType == Const_pb.SCORE_PROFGS_RANK or currentRankType == Const_pb.SCORE_PROFCS_RANK then
                --戰力
                local Num = GameUtil:formatDotNumber(itemInfo.rankData)
                if string.len(Num) >8 then
                    NumNode:setScale(0.8)
                else
                    NumNode:setScale(0.9)
                end
                NumNode:setString(Num)
            elseif PageInfo.curProType==5 then
                local Num = itemInfo.rankData
                NumNode:setString(Num)
            end
        end
    end
end


end
function ProfessionRankingEXPageBase:SetInfo(curProType,subType,RankType)
    PageInfo.curProType=curProType
    PageInfo.subType=subType
    currentRankType=RankType
end
function ProfessionRankingEXPageBase:SetRewardInfo(canGet,achived,_pageTable,_playerInfo)
    RewardData=canGet
    AchivedData=achived
    PlayerInfo=_playerInfo
    PageTable=_pageTable
    local idx=0
    for k,v in pairs (RewardData) do
        idx=idx+1
    end
    if ProfessionRankingEXPageBase.container then 
        ProfessionRankingEXPageBase:BuildRewardScrollview(ProfessionRankingEXPageBase.container)
    end
end
function ProfessionRankingEXPageBase:signatureMove(container, isSelf, index)
    if not isSelf then
        container = PageInfo.itemContainer[index]
    end
    local mPlayerSignature = container:getVarLabelTTF("mPlayerSignature")
    local mPersonalSignatureS9 = container:getVarScale9Sprite("mPersonalSignatureS9")
    local width = mPlayerSignature:getContentSize().width + 10
    mPlayerSignature:stopAllActions()
    if width > mPersonalSignatureS9:getContentSize().width then
        mPlayerSignature:setPosition(ccp(-PlayerSignaturePositionX, PlayerSignaturePositionY))
        local array = CCArray:create()
        array:addObject(CCMoveBy:create(10, ccp(-width * 2, 0)))
        local CallFuncN_1 = CCCallFuncN:create(function(node)
            node:setPosition(ccp(-PlayerSignaturePositionX, PlayerSignaturePositionY))
        end)
        array:addObject(CallFuncN_1)
        local CallFuncN_2 = CCCallFuncN:create(function(node)
            ProfessionRankingEXPageBase:signatureMove(container, isSelf, index)
        end)
        array:addObject(CallFuncN_2)
        mPlayerSignature:runAction(CCSequence:create(array))
    else
        mPlayerSignature:stopAllActions()
        mPlayerSignature:setPosition(ccp(PlayerSignaturePositionX, PlayerSignaturePositionY))
    end
end

function ProfessionRankingEXPageBase:setPlayerMessage(container, data, isSelf, index)

    if isSelf then
        NodeHelper:setNodesVisible(container, { mNotMessageNode = false })
    else

    end
    --ProfessionRankingEXPageBase:setS9Image(container, data.rankNum, isSelf)

    if data then
            -- 头像
            local NewHeadIconItem = require("NewHeadIconItem")
            local parentNode = container:getVarNode("mHeadNode")
            parentNode:removeAllChildrenWithCleanup(true)
            local headNode = ScriptContentBase:create("FormationTeamContent.ccbi")
            headNode:setAnchorPoint(ccp(0.5, 0.5))
            
            parentNode:addChild(headNode)
            NodeHelper:setNodesVisible(headNode, { mClass = false, mElement = false, mMarkFighting = false, mMarkChoose = false, 
                                                mMarkSelling = false, mMask = false, mSelectFrame = false, mStageImg = false ,mLvNode=false})

            local icon = common:getPlayeIcon(data.prof,data.headIcon)
            if PageInfo.curProType==5 then
                if isSelf and data.itemId==-1 then
                    local roleIcon = ConfigManager.getRoleIconCfg()
                    local trueIcon = GameConfig.headIconNew or UserInfo.playerInfo.headIcon
                    if not roleIcon[trueIcon] then
                        icon = common:getPlayeIcon(UserInfo.roleInfo.prof, trueIcon)
                    else
                        icon= roleIcon[trueIcon].MainPageIcon
                    end
                else
                    local ID= string.format("%02d",data.itemId).. string.format("%03d",data.skinId)
                    icon=common:getPlayeIcon(nil,ID)
                end
            end
            if NodeHelper:isFileExist(icon) then
                NodeHelper:setSpriteImage(headNode, { mHead = icon })
            end

        -- 名字
        if isSelf then
            local Rank=data.rankNum
            if Rank<0 then Rank="-" end
            NodeHelper:setStringForLabel(container, { mSelfName = data.playerName,mSelfRankText=Rank})
        else
            NodeHelper:setStringForLabel(container, { mPlayerName = data.playerName })
        end
        -- 联盟   data:HasField("allianceName") and data:HasField("allianceId")
       --if data.allianceId ~= 0 then
       --    NodeHelper:setStringForLabel(container, { mPlayerGuildName = common:getLanguageString("@GuildLabel") .. data.allianceName .. "(ID " .. data.allianceId .. ")" })
       --else
       --    NodeHelper:setStringForLabel(container, { mPlayerGuildName = common:getLanguageString("@GuildLabel") .. common:getLanguageString("@NoAlliance") })
       --end
        NodeHelper:setNodesVisible(container,{ mPlayerGuildName = false })
        -- 签名
        local sign=common:getLanguageString("@Achvmt4")
        local defult=common:getLanguageString("@SingTip")
        if data.signature ~=defult then sign = data.signature end
        NodeHelper:setStringForLabel(container, { mPlayerSignature = sign })
        NodeHelper:setBlurryString(container, "mPlayerSignature", sign, 600, 25)
        NodeHelper:setNodesVisible(container, { mPersonalSignatureNode = true })
        ProfessionRankingEXPageBase:signatureMove(container, isSelf, index)

        if currentRankType == Const_pb.CUSTOMPASS_BOSS_RANK then
            -- 普通关卡
            if data.rankData == 0 then
                NodeHelper:setStringForLabel(container, { mRankInfo = "---" })
            else
                local configData = ConfigManager.getNewMapCfg()[data.rankData]
                NodeHelper:setNodesVisible(container,{ mBP = false })
                local ch = configData.Chapter
                local childCh =configData.Level
                if isSelf then
                    NodeHelper:setStringForLabel(container, { mSelfRankInfo = "Chapter "..ch.."-"..childCh })
                else
                    NodeHelper:setStringForLabel(container, { mRankInfo = "Chapter "..ch.."-"..childCh })
                end

            end
             NodeHelper:setNodesVisible(container,{ mBP = false })
        elseif currentRankType == Const_pb.CUSTOMPASS_TRAINING_RANK then
            -- 训练所
            if data.rankData == 0 then
                NodeHelper:setStringForLabel(container, { mRankInfo = "---" })
            else
                local configData = ConfigManager.getEliteMapCfg()[data.rankData]
                if configData then
                    local strMapId = tostring(data.rankData)
                    local subMapId = string.sub(strMapId, -1)
                    local str = "Lv." .. configData.level .. "" .. configData.name .. "(" .. subMapId .. ")"
                    NodeHelper:setStringForLabel(container, { mRankInfo = str })
                else
                    NodeHelper:setStringForLabel(container, { mRankInfo = "" })
                end
            end
            NodeHelper:setNodesVisible(container,{ mBP = false })
        elseif currentRankType == Const_pb.LEVEL_ALL_RANK or currentRankType == Const_pb.LEVEL_PROFJS_RANK or currentRankType == Const_pb.LEVEL_PROFGS_RANK or currentRankType == Const_pb.LEVEL_PROFCS_RANK then
            -- 等级
            if isSelf then
                NodeHelper:setStringForLabel(container, { mSelfRankInfo = UserInfo.getStageAndLevelStr() })
            else
                NodeHelper:setStringForLabel(container, { mRankInfo = UserInfo.getOtherLevelStr(data.rebirthStage, data.rankData) })
            end
            NodeHelper:setNodesVisible(container,{ mBP = false })
        elseif currentRankType == Const_pb.SCORE_ALL_RANK or currentRankType == Const_pb.SCORE_PROFJS_RANK or currentRankType == Const_pb.SCORE_PROFGS_RANK or currentRankType == Const_pb.SCORE_PROFCS_RANK then
            -- 战力
            local Num = nil
            if isSelf then
                Num = string.format("%35s", GameUtil:formatDotNumber(UserInfo.roleInfo.marsterFight))
                  NodeHelper:setStringForLabel(container, { mSelfRankInfo = Num })
            else
                Num = string.format("%30s", GameUtil:formatDotNumber(data.rankData))
                 NodeHelper:setStringForLabel(container, { mRankInfo = Num })
            end
          
            --container:getVarNode("mRankInfo"):setScale(1.2)
            NodeHelper:setNodesVisible(container, { mBP = true })
        elseif PageInfo.curProType==5 then
            local Num=0
            if isSelf then
                if  data.rankData==-1 then
                    NodeHelper:setStringForLabel(container, { mSelfRankInfo = "---" })
                else
                     NodeHelper:setStringForLabel(container, { mSelfRankInfo = data.rankData })
                end
            else
                NodeHelper:setStringForLabel(container, { mRankInfo = data.rankData })
            end

        else
            NodeHelper:setStringForLabel(container, { mRankInfo = data.rankData })
            NodeHelper:setNodesVisible(container, { mBP = false })
        end

        -- infoData

        local mRankInfo = container:getVarLabelTTF("mRankInfo")
        local mRankInfoS9 = container:getVarScale9Sprite("mRankInfoS9")
        mRankInfoS9:setContentSize(CCSizeMake(200, 30))
        
        if data.rankNum == -1 then
            NodeHelper:setNodesVisible(container, { mRankImage = false })
            NodeHelper:setStringForLabel(container, { mRankText = "500+" })
        else
            local pSprite = container:getVarSprite("mRankImage")
            if data.rankNum > 0 and data.rankNum <= 3 then
                NodeHelper:setNodesVisible(container, { mRankImage = true })
                pSprite:setTexture(GameConfig.ArenaRankingIcon[data.rankNum])
                NodeHelper:setStringForLabel(container, { mRankText = data.rankNum })
                NodeHelper:setNodesVisible(container, { mRankText = false })
            else
                NodeHelper:setNodesVisible(container, { mRankImage = false })
                if data.rankNum == 0 then
                    pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
                    NodeHelper:setStringForLabel(container, { mRankText = "500+" })
                    NodeHelper:setNodesVisible(container, { mRankText = true })
                else
                    pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
                    NodeHelper:setStringForLabel(container, { mRankText = data.rankNum })
                    
                    NodeHelper:setNodesVisible(container, { mRankText = true })
                end
            end
        end
        --if isSelf then
        --    NodeHelper:setSpriteImage(container, { mProfession = GameConfig.ProfessionIcon[data.prof] })
        --else
        --    NodeHelper:setSpriteImage(container, { mProfession = GameConfig.ProfessionIcon[data.prof - 3] })
        --end
    end
end

function ProfessionRankingEXPageBase:setGuildMessage(container, data, isSelf)
    if isSelf then

    else

    end
    -- 联盟
    if data == nil then
        -- 没加入工会
        NodeHelper:setNodesVisible(container, { mSelfRinkInfoNode = false, mNotMessageNode = true, mSelfGuildRankNode = false, mRankImage = false })
    else
        --ProfessionRankingEXPageBase:setS9Image(container, data.rankNum, isSelf)
        NodeHelper:setNodesVisible(container, { mSelfRinkInfoNode = true, mNotMessageNode = false, mSelfGuildRankNode = true, mRankImage = true })
        -- 名字
        NodeHelper:setStringForLabel(container, { mGuildName = data.allianceName .. "(ID " .. data.allianceId .. ")" })
        -- 人数
        NodeHelper:setStringForLabel(container, { mGuildPlayerNum = common:getLanguageString("@FightingRankingcontent5") .. data.memberNum .. "/" .. data.maxMember })
        -- 加入条件
        local conditionStr = common:getLanguageString("@FightingRankingcontent1")
        if data.limitJoin <= 0 and data.checkLeaderMail == 0 then
            -- 无条件
            conditionStr = conditionStr .. common:getLanguageString("@FightingRankingcontent4")
        end
        if data.limitJoin > 0 and data.checkLeaderMail == 1 then
            -- 有战力要求  需要盟主审核
            conditionStr = conditionStr .. common:getLanguageString("@FightingRankingcontent2", data.limitJoin) .. "," .. common:getLanguageString("@FightingRankingcontent3")
        end
        if data.limitJoin > 0 and data.checkLeaderMail == 0 then
            -- 有战力要求  不需要盟主审核
            conditionStr = conditionStr .. common:getLanguageString("@FightingRankingcontent2", data.limitJoin)
        end
        if data.limitJoin <= 0 and data.checkLeaderMail == 1 then
            -- 没有战力要求  需要盟主审核
            conditionStr = conditionStr .. common:getLanguageString("@FightingRankingcontent3")
        end

        NodeHelper:setStringForLabel(container, { mGuildMessage = conditionStr })
        -- infoData

        if currentRankType == Const_pb.ALLIANCE_LEVEL_RANK then
            NodeHelper:setStringForLabel(container, { mRankInfo = "Lv." .. data.rankData })
        elseif currentRankType == Const_pb.ALLIANCE_VITALITY_RANK then
            NodeHelper:setStringForLabel(container, { mRankInfo = common:getLanguageString("@FightingRankinglable8") .. ":" .. data.rankData })
        elseif currentRankType == Const_pb.ALLIANCE_BOSSHARM_RANK then
            if data.rankData <= 0 then
                data.rankData = 0
            end
            NodeHelper:setStringForLabel(container, { mRankInfo = common:getLanguageString("@FightingRankingcontent6") .. data.rankData })
        end


        local mRankInfo = container:getVarLabelTTF("mRankInfo")
        local mRankInfoS9 = container:getVarScale9Sprite("mRankInfoS9")
        mRankInfoS9:setContentSize(CCSizeMake(mRankInfo:getContentSize().width + 7, 30))
        if mRankInfo:getContentSize().width + 7 < 51 then
            mRankInfoS9:setContentSize(CCSizeMake(51, 30))
        end

        if data.rankNum == -1 then
            NodeHelper:setNodesVisible(container, { mRankImage = false })
        else
            NodeHelper:setNodesVisible(container, { mRankImage = true })
            local pSprite = container:getVarSprite("mRankImage")
            if data.rankNum > 0 and data.rankNum <= 3 then
                pSprite:setTexture(GameConfig.ArenaRankingIcon[data.rankNum])
                NodeHelper:setStringForLabel(container, { mRankText = data.rankNum })
                NodeHelper:setNodesVisible(container, { mRankText = false })
            else
                NodeHelper:setNodesVisible(container, { mRankImage = false })
                if data.rankNum == 0 then
                    pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
                    NodeHelper:setStringForLabel(container, { mRankText = "500+" })
                    NodeHelper:setNodesVisible(container, { mRankText = true })
                else
                    pSprite:setTexture(GameConfig.ArenaRankingIcon[4])
                    NodeHelper:setStringForLabel(container, { mRankText = data.rankNum })
                    NodeHelper:setNodesVisible(container, { mRankText = true })
                end
            end
        end
    end
end

function ProfessionRankingEXPageBase:setS9Image(container, rank, isSelf)
    if isSelf then
        return
    end
    -------------------------------------------------------------
    local bgRect = CCRectMake(0, 0, 0, 0)
    local bgMap = {
        mS9Bg =
        {
            name = "",
            rect = bgRect
        }
    }

    local bgInsets = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0
    }

    if rank > 0 and rank <= 3 then
        NodeHelper:setNodesVisible(container, { mS9Bg = true, mS9Bg2 = false })
        bgMap.mS9Bg.name = ProfessionRankingEXPageContent[rank].BG
    else
        NodeHelper:setNodesVisible(container, { mS9Bg = true, mS9Bg2 = false })
        bgMap.mS9Bg.name = ProfessionRankingEXPageContent[4].BG
    end

    NodeHelper:setScale9SpriteImage(container, bgMap, { mS9Bg = bgInsets }, { mS9Bg = CCSizeMake(638, 151) })


    -------------------------------------------------------------
    --local infoRect = CCRectMake(0, 0, 51, 30)
    --local infoMap = {
    --    mRankInfoS9 =
    --    {
    --        name = "",
    --        rect = infoRect
    --    }
    --}
    --
    --local infoInsets = {
    --    left = 25,
    --    right = 25,
    --    top = 14,
    --    bottom = 14
    --}
    --
    --if rank > 0 and rank <= 3 then
    --    infoMap.mRankInfoS9.name = ProfessionRankingEXPageContent[rank].S9
    --else
    --    infoMap.mRankInfoS9.name = ProfessionRankingEXPageContent[4].S9
    --end

    --NodeHelper:setScale9SpriteImage(container, infoMap, { mRankInfoS9 = infoInsets }, { mRankInfoS9 = CCSizeMake(71, 30) })

    -------------------------------------------------------------
    local PersonalSignatureRect = CCRectMake(0, 0, 51, 30)
    local PersonalSignatureMap = {
        mPersonalSignatureS9 =
        {
            name = "",
            rect = PersonalSignatureRect
        }
    }

    local PersonalSignatureInsets = {
        left = 25,
        right = 25,
        top = 9,
        bottom = 9
    }

    if rank > 0 and rank <= 3 then
        PersonalSignatureMap.mPersonalSignatureS9.name = ProfessionRankingEXPageContent[rank].S9
    else
        PersonalSignatureMap.mPersonalSignatureS9.name = ProfessionRankingEXPageContent[4].S9
    end

    NodeHelper:setScale9SpriteImage(container, PersonalSignatureMap, { mPersonalSignatureS9 = PersonalSignatureInsets }, { mPersonalSignatureS9 = CCSizeMake(383, 30) })

    -------------------------------------------------------------

    local GuildSignature = CCRectMake(0, 0, 51, 30)
    local GuildSignatureMap = {
        mGuildSignatureS9 =
        {
            name = "",
            rect = GuildSignature
        }
    }

    local GuildSignatureInsets = {
        left = 25,
        right = 25,
        top = 9,
        bottom = 9
    }

    if rank > 0 and rank <= 3 then
        GuildSignatureMap.mGuildSignatureS9.name = ProfessionRankingEXPageContent[rank].S9
    else
        GuildSignatureMap.mGuildSignatureS9.name = ProfessionRankingEXPageContent[4].S9
    end

    NodeHelper:setScale9SpriteImage(container, GuildSignatureMap, { mGuildSignatureS9 = GuildSignatureInsets }, { mGuildSignatureS9 = CCSizeMake(383, 30) })

    -------------------------------------------------------------
end

function ProfessionRankingEXPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ProfessionRankingEXPageBase:clearAllItem(container)
    local scrollview = container.scrollview
    scrollview:removeAllCell()
end

function ProfessionRankingEXPageBase:buildItem(container)
    PageInfo.itemContainer = { }
    local scrollview = container.scrollview
    local ccbiFile = "FightingRankingContentEX.ccbi"
    local totalSize = #PageInfo.rankInfos
    if totalSize == 0 then return end
    local spacing = 5
    local cell = nil
    for i = totalSize,1,-1 do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        local panel = common:new( { id = i, serverData = PageInfo.rankInfos[i] }, ProfessionRankingEXPageContent)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)
    end
    scrollview:setTouchEnabled(true)
    scrollview:orderCCBFileCells()
end

function ProfessionRankingEXPageBase:registerPacket(container)
    container:registerPacket(HP_pb.RANKING_LIST_S)
end

function ProfessionRankingEXPageBase:removePacket(container)
    container:removePacket(HP_pb.RANKING_LIST_S)
end

function ProfessionRankingEXPage_reset()
    -- ProfessionRankingEXCacheInfo = { }
    ProfessionRankingEXCacheInfo = {
        [1] = { },
        [2] = { },
        [3] = { },
        [4] = { }
    }
end
----------------------------------------------------
local CommonPage = require("CommonPage")
ProfessionRankingEXPage = CommonPage.newSub(ProfessionRankingEXPageBase, thisPageName, option)
return ProfessionRankingEXPage