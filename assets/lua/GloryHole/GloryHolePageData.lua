local NodeHelper = require("NodeHelper")
local thisPageName = 'GloryHoleDataMgr'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");

local GloryHoleDataBase = {}

local PageInfo={
    teamId=0,
    challengeTime=0,
    actLeftTime=0,
    dailyLeftTime=0,
    participants=0,
    Team1_Score=0,
    Team2_Score=0,
    BestScore=0,
    CanBuyCount=0,
    NowPayNum=0,
    isOpen = false
}
local RankInfo={
    Self={Rank=1,maxScore=0,playerId=1,Name="",teamId=0,headerId=1},
    Daily={},
    Team={Team1={},Team2={}},
    HistoryRank={},
    isOpen = false
}
local MissionInfo={DailyMission={Quest={},Target={}},
                    Achivement={}
                    }

local option = {
    ccbiFile = "GloryHole.ccbi",
    handlerMap = {},
}

local opcodes = {
    ACTIVITY175_GLORY_HOLE_S = HP_pb.ACTIVITY175_GLORY_HOLE_S,
}

function GloryHoleBase_SetInfo(data)
    if data.action==0 or data.action==2 then
        PageInfo.teamId = data.actInfo.teamId

        local GloryHoleCfg=ConfigManager.getGloryHoleCfg()
        local weekDay = tonumber(os.date("%w"))
        local opendays = common:split(GloryHoleCfg[1].openDays, ",")
        local isOpen = false
        for _, v in pairs(opendays) do
            if weekDay == tonumber(v) then
                isOpen = true
                break
            end
        end
        if not isOpen and PageInfo.teamId == 0 then
            PageInfo.teamId = 3
        end
        PageInfo.isOpen = isOpen
        PageInfo.challengeTime=data.actInfo.challengeTime
        PageInfo.CanBuyCount=data.actInfo.usePay
        PageInfo.NowPayNum=data.actInfo.nowPayNum
        PageInfo.actLeftTime=data.actInfo.actLeftTime
        PageInfo.dailyLeftTime=data.actInfo.dailyLeftTime
        PageInfo.participants=data.actInfo.participants
        PageInfo.BestScore=data.actInfo.maxScore
        PageInfo.Team1_Score=0
        PageInfo.Team2_Score=0
        for _,data in pairs(data.actInfo.teamitem) do
            local team = data.teamId
            if team == 1 then
                 PageInfo.Team1_Score = data.score
            elseif team == 2 then
                 PageInfo.Team2_Score = data.score
            end
        end
    end
    if data.action==1 then
        --Self
        RankInfo.isOpen = PageInfo.isOpen
        RankInfo.Self.Rank=data.rankInfo.ownItem.rank
        RankInfo.Self.Score=data.rankInfo.ownItem.score
        RankInfo.Self.maxRank=data.rankInfo.ownItem.maxrank
        RankInfo.Self.teamId=data.rankInfo.ownItem.teamId
        if not isOpen and RankInfo.Self.teamId == 0 then
           RankInfo.Self.teamId = 3
        end
        RankInfo.Self.maxScore=data.rankInfo.ownItem.maxscore
        RankInfo.Self.Name=data.rankInfo.ownItem.name
        RankInfo.Self.headerId=data.rankInfo.ownItem.headerId
        RankInfo.Self.playerId=data.rankInfo.ownItem.playerId
        --Daily
        RankInfo.Daily={}
        for i=1 ,#data.rankInfo.dailyitem do
            table.insert(RankInfo.Daily,{Rank=data.rankInfo.dailyitem[i].rank,
                                         Score=data.rankInfo.dailyitem[i].score,
                                         playerId=data.rankInfo.dailyitem[i].playerId,
                                         Name=data.rankInfo.dailyitem[i].name,
                                         teamId=data.rankInfo.dailyitem[i].teamId,
                                         headerId=data.rankInfo.dailyitem[i].headerId
                                        })
             table.sort(RankInfo.Daily,function(a,b) return (a.Rank > b.Rank) end )
        end
        --Team
        RankInfo.Team.Team1.Score=0
        RankInfo.Team.Team1.TeamId=1
        RankInfo.Team.Team2.Score=0
        RankInfo.Team.Team2.TeamId=2
        for _,data in pairs (data.rankInfo.teamitem) do
            local team = data.teamId
            if team == 1 then
                RankInfo.Team.Team1.Score = data.score
            elseif team == 2 then
                RankInfo.Team.Team2.Score = data.score
            end
        end
        --HistoryRank
        RankInfo.HistoryRank={}
        for i=1 ,#data.rankInfo.maxitem do
            table.insert(RankInfo.HistoryRank,{Rank=data.rankInfo.maxitem[i].rank,
                                               Score=data.rankInfo.maxitem[i].score,
                                               playerId=data.rankInfo.maxitem[i].playerId,
                                               Name=data.rankInfo.maxitem[i].name,
                                               teamId=data.rankInfo.maxitem[i].teamId,
                                               headerId=data.rankInfo.maxitem[i].headerId
                                               })
             table.sort(RankInfo.HistoryRank,function(a,b) return (a.Rank > b.Rank) end )
        end
    end
    if data.action==6 or data.action==7 then
        for i=1,#data.missionInfo.missionItem do
            local cfg=ConfigManager.getGloryHoleQuestCfg()
            MissionInfo.Achivement[i]= data.missionInfo.missionItem[i]
        end
    end
    if data.action==8 or data.action==9 or data.action==10 then
        local finishedQuest={}
        MissionInfo.DailyMission.Quest={}
        for i=1,#data.dailyInfo.allDailyQuest do
            if data.dailyInfo.allDailyQuest[i].takeStatus==1 then
                table.insert(finishedQuest,data.dailyInfo.allDailyQuest[i])
            else
                table.insert(MissionInfo.DailyMission.Quest,data.dailyInfo.allDailyQuest[i])
            end
        end
        MissionInfo.DailyPoint=data.dailyInfo.dailyPoint
        for i = 1,4 do
             MissionInfo.DailyMission.Target[i]=data.dailyInfo.dailyPointCore[i] or nil
        end
        table.merge(MissionInfo.DailyMission.Quest,finishedQuest)
        function table.merge(t1, t2)
            for k, v in ipairs(t2) do
                table.insert(t1, v)
            end
            return t1
        end
    end
end

function GloryHoleDataBase:getData()
    return PageInfo
end

function GloryHoleDataBase:setLeftTime(time)
    PageInfo.dailyLeftTime = time
end

function GloryHoleDataBase:getRank()
    return RankInfo
end
function GloryHoleDataBase:getMission()
    return MissionInfo
end


local CommonPage = require('CommonPage')
GloryHoleData = CommonPage.newSub(GloryHoleDataBase, thisPageName, option)

return GloryHoleData
