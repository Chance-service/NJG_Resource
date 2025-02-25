local HP_pb = require("HP_pb")
local ClimbingTower_pb = require("ClimbingTower_pb")
local ClibingTowerBasicCfg = ConfigManager.getClimbingTowerBasicCfg()
local ClibingTowerMapCfg = ConfigManager.getClimbingTowerMapCfg()
local multiMonsterCfg = ConfigManager.getMultiMonsterCfg()
local skillCfg = ConfigManager.getSkillCfg()
local UserInfo = require("PlayerInfo.UserInfo")
local OSPVPManager = require("OSPVPManager")

local ClimbingDataManager = {
    mapInfo = {},
    PlayerInfo = {},
    RankInfo = {},
    SweepInfo = {},
    ChallengeData = {},
    isFromClimbingTower = false
}

function ClimbingDataManager:getCurMapCfg(curMapId)
    return ClibingTowerMapCfg[curMapId]
end

function ClimbingDataManager:getMonsterInfo(curMapId)
     local monsterConfig = ClibingTowerMapCfg[curMapId].monster

    local monsterCfg = ConfigManager.getMonsterCfg()
    local skillCfg = ConfigManager.getSkillCfg()

    local monsterInfo = {}

    for i=1,#monsterConfig do
        local monster = {}
        monster.id = tonumber(monsterConfig[i])

        if monster.id~=0 then
            monster.name = monsterCfg[monster.id]["name"]
            monster.pic = monsterCfg[monster.id]["icon"]
            monster.level = monsterCfg[monster.id]["level"]
            --monster.isBoss = monsterCfg[monster.id]["isBoss"]
            monster.skillName = {}
            local skillId = {}
            for _, item in ipairs(common:split(monsterCfg[monster.id]["skills"], ",")) do
                table.insert(skillId,tonumber(item))
            end

            for k,v in pairs(skillId) do
                if skillCfg[v]~=nil then
                    table.insert(monster.skillName,skillCfg[v]["name"])
                end
            end
            table.insert(monsterInfo,monster)
        end
    end
    return monsterInfo
end

--爬塔请求
function ClimbingDataManager:sendInfoReq()
    local msg = ClimbingTower_pb.HPClimbingTowerInfoReq()
    common:sendPacket(HP_pb.CLIMBINGTOWER_INFO_C , msg ,false)
end

function ClimbingDataManager:setClimbingTowerInfo(msg)
    local tmpTable = {}
    tmpTable.totalStar = msg.totalStar
    tmpTable.curLayer = msg.curLayer
    tmpTable.historicHighStar = msg.historicHighStar
    tmpTable.todayResetTimes = msg.todayResetTimes
    tmpTable.sweepTimes = msg.sweepTimes
    tmpTable.passLayers = msg.passLayers
    tmpTable.sweepTimeRemain = msg.sweepTimeRemain
    ClimbingDataManager.PlayerInfo = tmpTable
end

function ClimbingDataManager:getClimbingTowerInfo()
    return ClimbingDataManager.PlayerInfo
end

function ClimbingDataManager:getClimbingTowerBasicConfig()
    return ClibingTowerBasicCfg
end

function ClimbingDataManager:getClimbingTowerMapConfig()
    return ClibingTowerMapCfg
end

--奖励预览
function ClimbingDataManager:getClimbingTowerRewardData()
    local rewardTable = {}
    for i = 1, #ClibingTowerMapCfg do
        if i%5 == 0 then
            local tmpTable = {}
            tmpTable.id = i
            tmpTable.reward = ClibingTowerMapCfg[i]
            table.insert(rewardTable,tmpTable)
        end
    end
    return rewardTable
end

--获得显示的地图消息
function ClimbingDataManager:getClimbingTowerShowMapData(passLayers)
    local showCount = 0
    passLayers = passLayers or 1
    local maxCount = #ClibingTowerMapCfg
    local downIndex = yuan3((passLayers - ClibingTowerBasicCfg[1].downParam) <= 0,1,passLayers - ClibingTowerBasicCfg[1].downParam)
    local upIndex = yuan3((passLayers + ClibingTowerBasicCfg[1].upParam) >= maxCount,maxCount,passLayers + ClibingTowerBasicCfg[1].upParam)
    local mapTable = {}
    for i = 1, #ClibingTowerMapCfg do
        if i > upIndex then
            break
        else
            if i >= downIndex and i <= upIndex then
                table.insert(mapTable,ClibingTowerMapCfg[i])
            end
        end
    end
    showCount = upIndex - downIndex + 1
    return showCount, mapTable
end

--爬塔排行榜请求
function ClimbingDataManager:sendClimbingRankReq()
    local msg = ClimbingTower_pb.HPClimbingTowerInfoReq()
    common:sendPacket(HP_pb.CLIMBINGTOWER_RANK_C , msg ,false)
end

function ClimbingDataManager:setClibingTowerRankData(msg)
    ClimbingDataManager.RankInfo.selfRank = {}
    ClimbingDataManager.RankInfo.allRank = {}
    ClimbingDataManager.RankInfo.selfRank = msg.self
    ClimbingDataManager.RankInfo.allRank = msg.ranks
end

function ClimbingDataManager:getClibingTowerRank()
    return ClimbingDataManager.RankInfo
end


--爬塔挑战请求
function ClimbingDataManager:sendClimbingChallengeReq(challengeLayer)
    local msg = ClimbingTower_pb.HPClimbingTowerChallengeReq()
    msg.challengeLayer =     challengeLayer
    common:sendPacket(HP_pb.CLIMBINGTOWER_CHALLENG_C , msg ,false)
end

function ClimbingDataManager:setClimbingChallengeData(msg)
    local tmpTable = { }
    tmpTable.challengeResult = msg.challengeResult
    tmpTable.battleInfo = msg.battleInfo
    tmpTable.curLayer = msg.curLayer
    tmpTable.challengeNum = msg.challengeNum
    tmpTable.reward = msg.reward
    tmpTable.isFromClimbingTower = true
    ClimbingDataManager.ChallengeData = msg
    ClimbingDataManager.isFromClimbingTower = true
end

function ClimbingDataManager:setClimbingChallengeEnd(isEnd)
    ClimbingDataManager.isFromClimbingTower = isEnd
end

function ClimbingDataManager:getClimbingChalengeData()
    return ClimbingDataManager.ChallengeData
end

--爬塔扫荡请求
function ClimbingDataManager:sendClimbingSweepReq()
    local msg = ClimbingTower_pb.HPClimbingTowerSweepReq()
    common:sendPacket(HP_pb.CLIMBINGTOWER_SWEEP_C , msg ,false)
end

function ClimbingDataManager:setClibingTowerSweepData(msg)
    ClimbingDataManager.SweepInfo.sweepLayer = msg.sweepLayer
    ClimbingDataManager.SweepInfo.stopLayer = msg.sweepLayer
    ClimbingDataManager.SweepInfo.timeRemain = msg.timeRemain
end

function ClimbingDataManager:getClibingTowerSweep()
    return ClimbingDataManager.SweepInfo
end

--爬塔重置请求
function ClimbingDataManager:sendClimbingResetReq()
    local msg = ClimbingTower_pb.HPClimbingTowerResetReq()
    common:sendPacket(HP_pb.CLIMBINGTOWER_RESET_C , msg ,false)
end



return ClimbingDataManager