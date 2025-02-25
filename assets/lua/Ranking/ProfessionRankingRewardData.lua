local thisPageName = "Ranking.ProfessionRankingReward"
require "HP_pb"
local Activity4_pb = require("Activity4_pb")
local Ranks_pb = require("Ranks_pb")
local Const_pb = require("Const_pb")
require("Util.RedPointManager")

local opcodes =
    {
        ACTIVITY153_S=HP_pb.ACTIVITY153_S,
        RANKING_LIST_S=HP_pb.RANKING_LIST_S
    }
local option = {
    ccbiFile = "FightingRankingReward.ccbi",
    handlerMap = {
        onBP="onBP",
        onLv="onLv",
        onStage="onStage",
        onLight="onLight",
        onDark="onDark",
        onFire="onFire",
        onWater="onWater",
        onWind="onWind",
        ---------------
        onHelp="onHelp",
        onReturn="onReturn"
    },
    opcode = opcodes,
};
local RankingReward = {}

local RewardData = {
    --戰力
    [1] = { [1] = 1 },
    -- 等級
    [2] = { [1] = 2 },
    -- 關卡
    [3] = { [1] = 3 },
    -- 工會
    [4] = { [1] = 9 },
    --屬性  火,水,風,光,暗
    [5] = { [1] = 7, [2] = 6, [3] = 8, [4] = 4, [5] = 5  }
}
 
 local InfoTable={}

function RankingReward:onEnter(container)

end


function RankingReward:setData(msg)
    for i=1,5 do 
        for j=1,5 do
            if RewardData[i][j] then
                local canGet,Achive,Page,Player = RankingReward:DataSort(msg, i, j)
                if not canGet then 
                    canGet={}
                    Achive={}
                    Page={}
                    Player={}
                end
                if not InfoTable[i] then
                    InfoTable[i]= {}
                end
                if not InfoTable[i][j] then
                    InfoTable[i][j]={}   
                end
                 if not InfoTable[i][j]["CanGetTable"] then
                    InfoTable[i][j]["CanGetTable"] ={}
                end
                InfoTable[i][j]["CanGetTable"]=canGet
                if not InfoTable[i][j]["AchiveTable"] then
                    InfoTable[i][j]["AchiveTable"] ={}
                end
                InfoTable[i][j]["AchiveTable"]=Achive
                if not InfoTable[i][j]["PageTable"] then
                    InfoTable[i][j]["PageTable"] ={}
                end
                InfoTable[i][j]["PageTable"]=Page
                if not InfoTable[i][j]["PlayerInfo"] then
                    InfoTable[i][j]["PlayerInfo"] ={}
                end
                InfoTable[i][j]["PlayerInfo"]=Player
                if not InfoTable[i][j]["Count"] then
                    InfoTable[i][j]["Count"] =0
                end
                local count=0
                for k,v in pairs (canGet) do
                    count=count+1
                end
                InfoTable[i][j]["Count"]=count
            end
        end
    end
    local RankingLobby=require("Ranking.ProfessionRankingLobby")
    RankingLobby:refreshData()
    --RankingReward:ShowRed()
end
function RankingReward:GetInfo()
    return InfoTable
end
function RankingReward:ShowRed()
    --local Lobby2=require("Lobby2Page")
    --for i=1,5 do 
    --    if not InfoTable[i] then break end
    --    for j=1,5 do
    --        if InfoTable[i][j] and InfoTable[i][j]["Count"]>0 then                
    --            Lobby2:RankRedNode(true)
    --            return
    --        end
    --    end
    --end
    --Lobby2:RankRedNode(false)
end
function RankingReward:DataSort(msg, ProType, subType)
    local PageTable = {}
    local AchiveTable = {}
    local CanGetTable = {}
    local PlayerInfo = {}
    local cfg = ConfigManager.getRankReward()
    local RewardTable = {}
    
    for k, val in pairs(cfg) do
        for i = 1, 5 do
            for j = 1, 5 do
                if RewardData[i][j] and val.type == RewardData[i][j] then
                    if not RewardTable[i] then
                        RewardTable[i] = {}
                    end
                    if not RewardTable[i][j] then
                        RewardTable[i][j] = {}
                    end
                    RewardTable[i][j][val.id] = val
                end
            end
        end
    end
    if not RewardTable[ProType] then return end
    PageTable = RewardTable[ProType][subType]
    for key, value in pairs(msg.completeInfo) do
        local Num = tonumber(value.cfgId)
        if Num and PageTable[Num] then
            AchiveTable[Num] = value
            if not PlayerInfo[Num] then
                PlayerInfo[Num] = {playerName = "", HeadIcon = 1}
            end
            PlayerInfo[Num].playerName = value.playerName
            PlayerInfo[Num].HeadIcon = value.HeadIcon
        end
    end
    local count = 0
    for key, value in pairs(AchiveTable) do
        CanGetTable[key] = value
        count = count + 1
    end
    for k, v in pairs(msg.gotId) do
        local Num = tonumber(v)
        if CanGetTable[Num] then
            CanGetTable[Num] = nil
            count = count - 1
        end
    end
    local truePageId = math.floor(RedPointManager.PAGE_IDS.RANKING_BP_REWARD / 100) * 100 + RewardData[ProType][subType]
    RedPointManager_setShowRedPoint(truePageId, 1, (count > 0))
    return CanGetTable,AchiveTable,PageTable,PlayerInfo
end


local CommonPage = require('CommonPage')
RankingReward = CommonPage.newSub(RankingReward, thisPageName, option)

return RankingReward
