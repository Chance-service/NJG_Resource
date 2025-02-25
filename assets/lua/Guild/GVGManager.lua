--[[----------------------------------------------
@ module("GVGManager")
 
--]]----------------------------------------------
local ConfigManager = require("ConfigManager")
local common = require("common")
local HP_pb = require("HP_pb")
local Alliance_pb = require('Alliance_pb')
local GVG_pb = require("GroupVsFunction_pb")
local Battle_pb = require("Battle_pb")
local PageManager = require("PageManager")
local UserMercenaryManager = require("UserMercenaryManager")
local UserInfo = require("PlayerInfo.UserInfo")
local GuildData = require("Guild.GuildData")
local GameConfig = require("GameConfig")
local table = table
local pairs = pairs
local ipairs = ipairs
local string = string
local math = math
local os = os
local MessageBoxPage = MessageBoxPage
local PacketScriptHandler = PacketScriptHandler
local print = print
local tostring = tostring
local tonumber = tonumber
local CCLuaLog = CCLuaLog


module("GVGManager")
-----debug
local debugLocal = false
debugCityId = 0

-----GVG活动开启标识
isGVGOpen = false

-----GVG加载开关
isGVGPageOpen = false

--临时开关
isGVGPageOpenTmp = false

-----公会红点检查开关
needCheckGuildPoint = false

----刷新页面事件定义
moduleName = "GVG"  ----页面统一tag

isFromRankReqMap = false

onMapInfo = "onMapInfo"                     ----地图详情
onGVGStatus = "onGVGStatus"                 ----GVG系统状态改变
onReceiveRolesInfo = "onReceiveRolesInfo"   ----获取玩家所有佣兵
onCityTeamList = "onCityTeamList"           ----城市队伍列表
onPlayerTeamList = "onPlayerTeamList"       ----玩家队伍列表
onChangeOrder = "onChangeOrder"             ----更换防守顺序
onJoinTeam = "onJoinTeam"                   ----报名成功
onCityChange = "onCityChange"               ----城市变更
onGotoCity = "onGotoCity"                   ----大地图跳转
onTodayRank = "onTodayRank"                 ----今日排名
onYesterdayRank = "onYesterdayRank"         ----昨日排名
onBattleInfo = "onBattleInfo"               ----战斗信息
onRewardInfo = "onRewardInfo"               ----领奖信息
onGVGConfig = "onGVGConfig"                 ----GVG配置同步
onTeamNumChange = "onTeamNumChange"         ----城市队伍数变化
onCityBattleNotice = "onCityBattleNotice"   ----城市战斗提醒
onGuildData = "onGuildData"                 ----公会数据

-----服务器时间与本地时间的差值(每次同步时计算)
serverTimeOffset = 0

-----本地战报悬挂时间
local battleShowTime = 31

------大地图配置
local cityConfig = {}
------大地图详情
local mapInfo = {}
------大地图城市信息
local cityInfo = {}
------城市攻防记录
local cityLog = {}
----本公会信息
local guildInfo = {}
----本人公会职位
local guildPos = 0
------城池队伍列表
local cityTeamsList = {}
------玩家队伍列表
local playerTeamList = {}
------玩家佣兵列表
local playerRoleList = {}
------总战斗列表(只包括拥有战报的战斗)
local battleList = {}
------今日排名
local todayRankList = {}
------昨日排名
local yesterdayRankList = {}

-----当前城市战斗信息
local curBattle = {}
local curBattleLogs = {}
local curBattleInfo = nil

-----每个城市最后一场战斗缓存
local lastBattleCache = {}
function getMapInfo()
   return mapInfo
end
function getGuildInfo()
   return guildInfo
end
function getCurBattleInfo()
    return curBattleInfo
end

function getCurBattleList()
    return curBattleLogs
end

function getCurBattle()
    return curBattle
end

function clearCurBattle()
    curBattle = {}
    curBattleLogs = {}
    curBattleInfo = nil
end
function cleatMapAndCityInfoTmp()
     mapInfo = {}
     ------大地图城市信息
     cityInfo = {}  
end
-----当前操作城市ID
local curCityId = 0

function setCurCityId(cityId)
    curCityId = cityId
    if cityId == 0 then
        clearCurBattle()
    end
end

function getCurCityId()
    return curCityId
end

-----队伍详情列表显示种类
SHOWTYPE_ATK     = 1    ----进攻列表
SHOWTYPE_DEF     = 2    ----防御列表

local showType = 1

function setShowType(_showType)
    showType = _showType
end

function getShowType()
    return showType
end

-----行动力消耗定义
ENERGY_ATK = 1
ENERGY_DEF = 1

function getNeedEnergy(showType)
    if showType == SHOWTYPE_ATK then
        return ENERGY_ATK
    elseif showType == SHOWTYPE_DEF then
        return ENERGY_DEF
    end
    return 0
end

-----大地图跳转目标城市
local targetCityId = 0

function getTargetCityId()
    return targetCityId
end

function setTargetCityId(cityId)
    targetCityId = cityId
    PageManager.refreshPage(moduleName, onGotoCity)
end

-----GVG领奖信息
local rewardInfo = {}

function getRewardInfo()
    return rewardInfo
end

-----观看GVG战报
local isWatchingGVG = false

function getIsWatchingGVG()
    return isWatchingGVG
end

function setIsWatchingGVG(flag)
    isWatchingGVG = flag
end

-----GVG配置时间
local GVGConfig = {}

local function convertToHour(millis)
    local second = math.floor(millis / 1000)
    local hour = math.floor(second / 3600)
    local min = math.floor(second / 60) - hour * 60
    return string.format("%02d:%02d", hour,min)
end

function getDeclareStartTime()
    return convertToHour(GVGConfig.declareStart or 0),GVGConfig.declareStart or 0
end

function getDeclareEndTime()
     return convertToHour(GVGConfig.declareEnd or 0),GVGConfig.declareEnd or 0
end

function getFightingStartTime()
     return convertToHour(GVGConfig.battleStart or 0),GVGConfig.battleStart or 0
end

function getFightingEndTime()
    return convertToHour(GVGConfig.battleEnd or 0),GVGConfig.battleEnd or 0
end

function getReviveStartTime()
    return convertToHour(GVGConfig.reviveStartTime or 0),GVGConfig.reviveStartTime or 0
end

function getDeclareTimes()
    if not guildInfo then return -1 end
    if guildInfo.id == 0 then return -1 end
    if getGuildPos() == 0 then return -1 end
    local gvgStatus = getGVGStatus()
    if gvgStatus ~= GVG_pb.GVG_STATUS_PREPARE then return -1 end
    if not todayRankList or #todayRankList == 0 then return -1 end
    local guildId = guildInfo.id
    local hasRight = false

    local maxNumber = 15
    if todayRankList and  #todayRankList > 16 then
        maxNumber = #todayRankList 
    end
    for k,v in pairs(todayRankList) do
        if v.id == guildId and v.rank <= maxNumber then
            hasRight = true
            break
        end
    end
    if not hasRight then return -1 end
    local times = 0
    for k,v in pairs(cityInfo) do
        if v.atkGuild and v.atkGuild.guildId > 0 and v.atkGuild.guildId == guildInfo.id then
            times = times + 1
        end
    end
    return times
end
function getNextMatchTime()
    return convertToHour(GVGConfig.suplyTime or 0),GVGConfig.suplyTime or 0
end
-----邮件跳转城市
local mailTargetCity = 0

function setMailTargetCity(cityId)
    mailTargetCity = cityId or 0
end

function getMailTargetCity()
    return mailTargetCity or 0
end

-----排行榜跳转返回
local isFromRank = false

function setIsFromRank(flag)
    isFromRank = flag
end

function getIsFromRank()
    return isFromRank
end

local fromPage = nil

function setFromPage(pageName)
    fromPage = pageName
end

function getFromPage()
    return fromPage
end

-----是否已经打开派遣
local isOpenJoinPage = false

function setIsOpenJoinPage(flag)
    isOpenJoinPage = flag
end

function getIsOpenJoinPage()
    return isOpenJoinPage
end

-----城市队伍实时数量
local cityTeamNumList = {}
--local isSyncTeamNum = false

function initCityTeamNum(msg,force)
    if not force and cityTeamNumList[msg.cityId] then
        local time = cityTeamNumList[msg.cityId].time
        if time < msg.currentTime then
            cityTeamNumList[msg.cityId] = {
                atk = msg.atkNumbers,
                def = msg.defNumbers,
                time = msg.currentTime
            }
        end
    else
        local curTime = math.max(msg.currentTime, (os.time() + serverTimeOffset) * 1000)
        cityTeamNumList[msg.cityId] = {
            atk = msg.atkNumbers,
            def = msg.defNumbers,
            time = curTime
        }
    end
    PageManager.refreshPage(moduleName,onTeamNumChange)
end

function getCityTeamNum(cityId)
    cityId = cityId or getCurCityId()
    if cityTeamNumList[cityId] then
        local data = cityTeamNumList[cityId]
        local cityInfo = getCityInfo(cityId)
        if cityInfo.status ~= GVG_pb.CITY_STATUS_FIGHTING then  ---非战斗状态屏蔽进攻队伍数
            data.atk = 0
        elseif not cityInfo.defGuild or cityInfo.defGuild.guildId == 0 then  ---NPC城防守队伍为1
            data.def = 1
        end
        return data.atk, data.def
    end
    return 0,0
end

function clearCityTeamNum(cityId)
	cityId = cityId or getCurCityId()
	cityTeamNumList[cityId] = nil
	
	PageManager.refreshPage(moduleName,onTeamNumChange)
end

function clearAllCityTeamNum()
	cityTeamNumList = {}
	
	PageManager.refreshPage(moduleName,onTeamNumChange)
end

-----未查看的战斗提醒数
local cityBattleNotice = {}

function insertCityBattleNotice(cityId)
    cityBattleNotice[cityId] = (cityBattleNotice[cityId] or 0) + 1

    PageManager.refreshPage(moduleName, onCityBattleNotice)
end

function getCityBattleNotice(cityId)
    cityId = cityId or getCurCityId()
    return cityBattleNotice[cityId] or 0
end

function clearCityBattleNotice(cityId)
    cityId = cityId or getCurCityId()
    cityBattleNotice[cityId] = 0

    PageManager.refreshPage(moduleName, onCityBattleNotice)
end

function getAllCityBattleNoticeNum()
    local num = 0
    for k,v in pairs(cityBattleNotice) do
        num = num + v
    end
    return num
end

function clearAllBattleNotice()
    cityBattleNotice = {}

    PageManager.refreshPage(moduleName, onCityBattleNotice)
end

-----排行榜类型定义
TODAY_RANK = 1
YESTERDAY_RANK = 2
NOW_RANK =  3 

-----------清理所有缓存数据
function clearAllData()
    clearCurBattle()
    ------大地图配置
    cityConfig = {}
    ------大地图详情
    mapInfo = {}
    ------大地图城市信息
    cityInfo = {}
    ------城市攻防记录
    cityLog = {}
    ----本公会信息
    guildInfo = {}
    ----本人公会职位
    guildPos = 0
    ------城池队伍列表
    cityTeamsList = {}
    ------玩家队伍列表
    playerTeamList = {}
    ------玩家佣兵列表
    playerRoleList = {}
    ------总战斗列表(只包括拥有战报的战斗)
    battleList = {}
    ------今日排名
    todayRankList = {}
    ------昨日排名
    yesterdayRankList = {}

    isFromRank = false

    mailTargetCity = 0

    curCityId = 0

    --cityTeamNumList = {}
end

----------------大地图相关-----------------------
-----------准备时间剩余
function getPrepareTimeLeft()
    local date = os.date("*t")
    date.hour = 0
    date.min = 0
    date.sec = 0
    date.day = date.day + 1
    local openTime = os.time(date)
    
    return openTime - (os.time() + serverTimeOffset)
end
-----------城市配置
function initCityConfig()
    cityConfig = ConfigManager.getGVGCfg()
end

function getCityNums()
    return #cityConfig
end

-----GVG配置请求
function reqGVGConfig()
    common:sendEmptyPacket(HP_pb.GVG_CONFIG_C,false)
end

-----GVG地图详情请求
function reqMapInfo()
    if UserInfo.roleInfo.level < GameConfig.ALLIANCE_OPEN_LEVEL then return end
    common:sendEmptyPacket(HP_pb.GVG_MAP_INFO_C, true)
end
-----公会信息请求
function reqGuildInfo()
    if UserInfo.roleInfo.level < GameConfig.ALLIANCE_OPEN_LEVEL then return end
    local msg = Alliance_pb.HPAllianceEnterC() 
	common:sendPacket(HP_pb.ALLIANCE_ENTER_C, msg, true)
end

function initGVGConfig(data)
    GVGConfig = data
    isGVGOpen = data.isGVGOpen
    if isGVGOpen and needCheckGuildPoint then
        --reqRewardInfo()
    end
    --GVG已经开启  并且从允许打开GVG地图的地方触发的操作
    if isGVGPageOpen and isGVGOpen then
        isFromRankReqMap = false 
        reqMapInfo()
    end
    --GVG未开启  并且从允许打开GVG地图的地方触发的操作
    if  not isGVGOpen  and  isGVGPageOpen then
        isGVGPageOpen  = false 
        local localSeverTimeTmp = common:getServerTimeByUpdate()
        local serverTimeTab = {}
        local serverTime = 0

        if  localSeverTimeTmp then
            serverTimeTab = os.date("!*t", localSeverTimeTmp - common:getServerOffset_UTCTime())
            serverTime = serverTimeTab.hour*3600 + serverTimeTab.min*60+serverTimeTab.sec
            if serverTimeTab.day == 15  or serverTimeTab.day == 30 then
               if serverTime  > 4 * 3600 then--开启当天 4点以后 如果状态还是未开始 就是工会数量不足的原因
                 MessageBoxPage:Msg_Box("@ERRORCODE_33030")
               else--4点以前是不到开启时间
                 if serverTimeTab.day > 15 then
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_33029",30))
                 else
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_33029",15)) 
                 end
               end
            else--其他时间未开启就是时间不对
                 if serverTimeTab.day > 15 then
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_33029",30))
                 else
                    MessageBoxPage:Msg_Box(common:getLanguageString("@ERRORCODE_33029",15)) 
                 end
            end
        end
    end
    PageManager.refreshPage(moduleName, onGVGConfig)
end

local function transformCityData(protoData)
    local city = {}
    city.cityId = protoData.cityId
    city.status = protoData.status
    city.defGuild = {
        guildId = protoData.defGuild.guildId,
        name = protoData.defGuild.name
    }
    city.atkGuild = {
        guildId = protoData.atkGuild.guildId,
        name = protoData.atkGuild.name
    }
    city.defTeamNum = protoData.defTeamNum
    city.reAtkGuildId = protoData.reAtkGuildId
    city.fightbackTime = protoData.fightbackTime
    city.isReAtk = protoData.isReAtk
    return city
end

function initMapInfo(data)
    mapInfo = data
    if data.currentTime and data.currentTime > 0 then
        serverTimeOffset = math.floor(data.currentTime / 1000) - os.time()
    end
    
    if debugLocal then
        for i = 1, #data.citys do
            if data.citys[i].defGuild.guildId == guildInfo.id then
                debugCityId = data.citys[i].cityId
                break
            end
        end
    end

    cityLog = {}
    if mapInfo.records then
        for i = 1, #mapInfo.records do
            local rec = mapInfo.records[i]
            local newRec = {
                cityId = rec.cityId,
                atkName = rec.atkName,
                defName = rec.defName,
                isAtkWin = rec.isAtkWin,
                isReAtk = rec.isReAtk
            }
            table.insert(cityLog,newRec)
        end
    end
    cityInfo = {}
    if mapInfo.citys then
        for i = 1, #mapInfo.citys do
            local city = transformCityData(mapInfo.citys[i])
            table.insert(cityInfo, city)
        end
    end

    if not isFromRankReqMap then
      PageManager.refreshPage(moduleName, onMapInfo)
      reqSyncTeamNum()
    else
      PageManager.refreshPage("GVGRankPage", onMapInfo)
    end
     
end

function initGuildInfo(data)
    if data.myInfo then
        guildPos = data.myInfo.postion
    end
    guildInfo = GuildData.allianceInfo.commonInfo
    PageManager.refreshPage(moduleName,onGuildData)
end

function getGuildPos()
    return guildPos or 0
end

function isSelfGuild(guildId)
    if not guildInfo then return false end
    if guildInfo.id == 0 then return false end
    return guildInfo.id == guildId
end

function getCityBattleRecords()
    local records = {}
    if cityLog then
        for i = 1, #cityLog do
            local record = cityLog[i]
            local str = ""
            local cfg = getCityCfg(record.cityId)
            local isNPC = false
            if not record.defName or record.defName == "" then
                isNPC = true
            end
            if isNPC then
                if record.isAtkWin == 1 then
                    local freeTypeCfg = ConfigManager.getFreeTypeCfg(3007)
                    str = common:fill(freeTypeCfg.content,record.atkName, cfg.cityName)
                else
                    local freeTypeCfg = ConfigManager.getFreeTypeCfg(3008)
                    str = common:fill(freeTypeCfg.content,record.atkName, cfg.cityName)
                end
            else
                if record.isReAtk then
                    if record.isAtkWin == 1 then
                        if cfg.level == 3 then
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3009)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        else
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3009)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        end
                    else
                        if cfg.level == 3 then
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3010)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        else
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3010)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        end
                    end
                else
                    if record.isAtkWin == 1 then
                        if cfg.level == 3 then
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3003)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        else
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3002)
                            str = common:fill(freeTypeCfg.content,record.atkName,record.defName, cfg.cityName)
                        end
                    else
                        if cfg.level == 3 then
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3005)
                            str = common:fill(freeTypeCfg.content,record.defName,record.atkName, cfg.cityName)
                        else
                            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3004)
                            str = common:fill(freeTypeCfg.content,record.defName,record.atkName, cfg.cityName)
                        end
                    end
                end
            end
            table.insert(records,str)
        end
    end
    return records
end

function getGVGStatus()
    return mapInfo.status or GVG_pb.GVG_STATUS_ENDING
end

function getWaitSuplyTime()
    return mapInfo.waitSuplyTime  or 0 
end
function autoDeclareBattle()
    local canDeclareCityList = {}
    if cityConfig then
        for i = 1, #cityConfig do
            local city = cityConfig[i]
            if  canDeclareCity(city.id) then
                table.insert(canDeclareCityList,city);
            end
        end
    end
    if #canDeclareCityList > 0  then 
       table.sort(canDeclareCityList, function(a,b)
          return a.id > b.id
       end)
    end
    local declaresTimes = 0
    for i = 1 ,#canDeclareCityList do
        local cityInfo = canDeclareCityList[i]
        if declaresTimes < 2 then 
            declareBattle(cityInfo.id)
            declaresTimes  = declaresTimes + 1 
        end
    end
end
function getCanDeclareCityList()
    local canDeclareCityList = {}
    for i = 1, #cityConfig do
        local city = nil 
        for j = 1, #cityInfo do
            if cityInfo[j].cityId == cityConfig[i].id then
                city  = cityInfo[j]
                break 
            end

        end
        if city  then 
            if  canDeclareCity(city.cityId,true) then
                table.insert(canDeclareCityList,city);
            end
        else
            city = cityConfig[i]
            if  canDeclareCity(city.id,true) then
                city = 
                {
                    cityId = city.id,
                    atkGuild = {guildId =0 , name = ""} ,
                    defGuild = {guildId =0 , name = common:getLanguageString("@GVGNpcName", city.cityName)}
                }
                table.insert(canDeclareCityList,city);
            end
        end
    end
    if #canDeclareCityList > 0  then 
       table.sort(canDeclareCityList, function(a,b)
          return a.cityId > b.cityId
       end)
    end

    return canDeclareCityList
end
function setGVGStatus(status)
    if status == GVG_pb.GVG_STATUS_PREPARE then
        mapInfo.status = GVG_pb.GVG_STATUS_PREPARE
        if common:getPlaformType() == common.platform.CC_PLATFORM_WIN32 then
           autoDeclareBattle()
        end 
    elseif status == GVG_pb.GVG_STATUS_FIGHTING then
        mapInfo.status = GVG_pb.GVG_STATUS_FIGHTING
    elseif status == GVG_pb.GVG_STATUS_ENDING or status == GVG_pb.GVG_STATUS_AWARD then
        mapInfo.status = GVG_pb.GVG_STATUS_ENDING
        clearAllBattleNotice()
		clearAllCityTeamNum()
    end

    local serverTimeTab = os.date("!*t", common:getServerTimeByUpdate() - common:getServerOffset_UTCTime())

    if status == GVG_pb.GVG_STATUS_AWARD and (serverTimeTab.day == 14 or serverTimeTab.day == 29) then
       mapInfo.status = GVG_pb.GVG_STATUS_AWARD
    else
        PageManager.refreshPage(moduleName, onGVGStatus)
        isFromRankReqMap = false 
        reqMapInfo()
    end
end

function getOwnGuildCitys()
    if not guildInfo then return {} end
    if guildInfo.id and guildInfo.id > 0 then
        return getCityListByGID(guildInfo.id)
    else
        return {}
    end
end
function getDelcaredCitys()
    if not guildInfo then return {} end
    if guildInfo.id and guildInfo.id > 0 then
        return getCityListByGIDAtk(guildInfo.id)
    else
        return {}
    end
end
function getGuildCityMap()
   local obtainScoreLevel1,obtainScoreLevel2,obtainScoreLevel3
   for k,v in pairs(cityConfig) do 
            if v.level == 1  then
            obtainScoreLevel1 = v.obtainScore
            elseif  v.level == 2 then
            obtainScoreLevel2 = v.obtainScore
            elseif v.level == 3 then 
            obtainScoreLevel3 = v.obtainScore
            end
    end
    local map = {}
    if cityInfo then
        for k,v in pairs(cityInfo) do
            if v.defGuild and v.defGuild.guildId > 0 then
                local defGuildId = v.defGuild.guildId
                if defGuildId > 0 then
                    if not map[defGuildId] then
                        map[defGuildId] = {
                            id = defGuildId,
                            level0 = 0,
                            level1 = 0,
                            level2 = 0,
                            level3 = 0,
                            guildName = v.defGuild.name
                        }
                    end
                    local cfg = getCityCfg(v.cityId)
                    local rec = map[defGuildId]
                    local levelKey = "level" .. cfg.level
                    rec[levelKey] = rec[levelKey] + 1
                end
            end
        end
    end
    local maxNumber = 15
    if todayRankList and  #todayRankList > 16 then
        maxNumber = #todayRankList 
    end
    if todayRankList then
        for i = 1, maxNumber do
            local v = todayRankList[i]
            if not map[v.id] then
                map[v.id] = {
                    id = v.id,
                    level0 = 0,
                    level1 = 0,
                    level2 = 0,
                    level3 = 0,
                    guildName = v.name
                }
            end
        end
    end
    local list = {}
    for k,v in pairs(map) do
        table.insert(list,v)
    end
    table.sort(list, function(a,b)
        local aPt = a.level3 * obtainScoreLevel3 + a.level2 * obtainScoreLevel2 + a.level1 * obtainScoreLevel1
        local bPt = b.level3 * obtainScoreLevel3 + b.level2 * obtainScoreLevel2 + b.level1 * obtainScoreLevel1
        if aPt ~= bPt then return aPt > bPt
        else return a.id > b.id end
    end)
    return list
end

function getCanReviveCitylist()
    local citys = {}
    local i = 1
    for k,v in pairs(cityConfig) do
        if v.level == 0 then
            local info = getCityInfo(k)
            if info then
                 citys[i] = {
                    cityId = k,
                    level = 0,
                    status = math.random(1,4),
                    defGuild = {
                        guildId = i,
                        name = "defendAlliance"
                    },
                    defTeamNum = 0
                }
                i = i + 1
            end
        end
    end
    return citys
end
function getCityListByGID(guildId)
    local citys = {}
    if debugLocal then
        local i = 1
        for k,v in pairs(cityConfig) do
            citys[i] = {
                cityId = k,
                status = math.random(1,4),
                defGuild = {
                    guildId = i,
                    name = "防御公会"
                },
                atkGuild = {
                    guildId = i,
                    name = "进攻公会"
                },
                defTeamNum = math.random(0,150)
            }
            i = i + 1
        end
    else
        if cityInfo then
            for i = 1, #cityInfo do
                local city = cityInfo[i]
                if city.defGuild and city.defGuild.guildId == guildId then
                    table.insert(citys, city)
                end    
            end
        end
    end

    return citys
end


function getCityListByGIDAtk(guildId)
    local citys = {}
    if debugLocal then
        local i = 1
        for k,v in pairs(cityConfig) do
            citys[i] = {
                cityId = k,
                status = math.random(1,4),
                defGuild = {
                    guildId = i,
                    name = "防御公会"
                },
                atkGuild = {
                    guildId = i,
                    name = "进攻公会"
                },
                defTeamNum = math.random(0,150)
            }
            i = i + 1
        end
    else
        if cityInfo then
            for i = 1, #cityInfo do
                local city = cityInfo[i]
                if city.atkGuild and city.atkGuild.guildId == guildId then
                    table.insert(citys, city)
                end    
            end
        end
    end

    return citys
end

function getCapitalOwner()
    local ownerId = 0
    local capital = GVG_pb.CityInfo()
    if cityInfo then
        for k,v in pairs(cityInfo) do
            local cfg = getCityCfg(v.cityId)
            if cfg.level == 3 then
                if v.defGuild then
                    ownerId = v.defGuild.guildId
                    capital = v
                    break
                end
            end
        end
    end
    return ownerId,capital
end

function getCapitalId()
    local cityId = 0
    for k,v in pairs(cityConfig) do
        if v.level == 3 then
            cityId = k
            break
        end
    end
    return cityId
end

function getCityCfg(cityId)
    cityId = cityId or getCurCityId()
    return cityConfig[cityId] or {}
end

function getCityInfo(cityId)
    cityId = cityId or getCurCityId()
    local data = {}
    if cityInfo then
        for i = 1, #cityInfo do
            local city = cityInfo[i]
            if city.cityId == cityId then
                data = city
                break
            end
        end
    end
    return data
end

function changeCityStatus(cityId, status, dispatch)
    cityId = cityId or getCurCityId()
    if cityInfo then
        for i = 1, #cityInfo do
            local city = cityInfo[i]
            if city.cityId == cityId then
                city.status = status
                if status == GVG_pb.CITY_STATUS_FORBIDDEN or status == GVG_pb.CITY_STATUS_FIGHTING then
                    city.fightbackTime = 0
                end
                break
            end
        end
    end
    if dispatch then
        PageManager.refreshPage(moduleName, onCityChange)
    end
end

function clearCityProtect(cityId, changeStatus, dispatch)
    

end

function getCityStatus(cityId)
    cityId = cityId or getCurCityId()
    local info = getCityInfo(cityId)
    if info then
        return info.status
    else
        local GVGStatus = getGVGStatus()
        if GVGStatus == GVG_pb.GVG_STATUS_PREPARE then
            return GVG_pb.CITY_STATUS_NORMAL
        else 
            return GVG_pb.CITY_STATUS_FORBIDDEN
        end
    end
end

function checkIsChain(cityId)
    cityId = cityId or getCurCityId()
    local cfg = getCityCfg(cityId)
    local citys = getOwnGuildCitys()

    for k,v in pairs(citys) do
        for i = 1, #cfg.chains do
            local chainId = tonumber(cfg.chains[i])
            if chainId == v.cityId then 
                return true
            end
        end
    end
    return false
end
--isRecord true 是统计可以宣战的城池 不管别人有没有人宣  以及自己的宣战次数是否够不够
function canDeclareCity(cityId,isRecord)
    cityId = cityId or getCurCityId()
    isRecord = isRecord  or false 
    if not guildInfo then return false end
    if isOwnCity(cityId) then return false end

    local cfg = getCityCfg(cityId) 
    if cfg.level == 0 then return false  end  --检测该城是不是复活点

    local info = getCityInfo(cityId)
    if info and info.status == GVG_pb.CITY_STATUS_DECLARED and not isRecord then return false end

    --已经宣战次数小于两次
    local declareTimes = getDeclareTimes()
    if declareTimes >= 2 and not isRecord then  return false end 

    --GVG状态必须是宣战期间
    local gvgStatus = getGVGStatus()
    if gvgStatus ~= GVG_pb.GVG_STATUS_PREPARE then return false end

    if #getOwnGuildCitys() == 1 then  --只有一座城并且该城是复活点  判定为可以宣战
       local citys = getOwnGuildCitys()
       local cityIdTmp = citys[1]
       local cfg = getCityCfg(cityIdTmp.cityId) 
       if cfg.level == 0 then 
         return checkIsChain(cityId)
      end  
    end

   
   
    if getGuildPos() == 0 then return false end
    if not todayRankList or #todayRankList == 0 then return false end
    local guildId = guildInfo.id
    local maxNumber = 15
    if todayRankList and  #todayRankList > 16 then
        maxNumber = #todayRankList 
    end

    for k,v in pairs(todayRankList) do
        if v.id == guildId and v.rank <= maxNumber then
            --临时注释掉
            --if #getOwnGuildCitys() == 1 then return true end
            return checkIsChain(cityId)
        end
    end
    return false
end

--如果玩家城池被占领后可以马上选择一座复活城池

function canReviveCity(cityId)
   local localSeverTimeTmp =  common:getServerTimeByUpdate()
    --8:00 - 22:00 不能复活
    if  localSeverTimeTmp then
        local serverTimeTab = os.date("!*t", localSeverTimeTmp - common:getServerOffset_UTCTime())
        local serverTime = serverTimeTab.hour*3600 + serverTimeTab.min*60+serverTimeTab.sec
        local _,declareStartTime = getDeclareStartTime()
        local _,fightEndTime = getFightingEndTime()
        local _,reviveStartTime = getReviveStartTime()
        declareStartTime = declareStartTime / 1000
        fightEndTime = fightEndTime / 1000
        reviveStartTime = reviveStartTime / 1000
        if serverTime >= declareStartTime and  serverTime <  reviveStartTime then
            return false 
        end
    end


    cityId = cityId or getCurCityId()
    if not guildInfo then return false end       -- 检测是不是有联盟
    if isOwnCity(cityId) then return false end   --检测是不是自己的城
    local info = getCityInfo(cityId)
    if info and info.status == GVG_pb.CITY_STATUS_DECLARED then 
    return false end  --检测该城的状态

    if getGuildPos() == 0 then return false end  --不是盟主或者副盟主 false

    if getGVGStatus() == GVG_pb.GVG_STATUS_PREPARE or getGVGStatus() == GVG_pb.GVG_STATUS_FIGHTING  then return false end  --检测GVG状态 宣战不能复活
    

    local cfg = getCityCfg(cityId) 
    if cfg.level ~= 0 then return false  end  --检测该城是不是复活点

    if  info.defGuild and info.defGuild.guildId > 0 then return false end   --检测该城有没有被占领

    if not todayRankList or #todayRankList == 0 then return false end  --检测是不是已经生成了入围名单
    
    --检测自己的联盟是不是在入围名单里面
    local guildId = guildInfo.id
    local isInRank = false 

    local maxNumber = 15
    if todayRankList and  #todayRankList > 16 then
        maxNumber = #todayRankList 
    end

    for k,v in pairs(todayRankList) do
        if v.id == guildId and v.rank <= maxNumber then
           isInRank = true 
        end
    end

   if not isInRank then  return false end
   
    if #getOwnGuildCitys() == 0 then return true end    --检测自己联盟有没有城

    --local gvgStatus = getGVGStatus()
    --if gvgStatus ~= GVG_pb.GVG_STATUS_PREPARE then return false end
    --if getGuildPos() == 0 then return false end
    --if not yesterdayRankList or #yesterdayRankList == 0 then return false end
    


    return false
end

function canAtkCity(cityId)
    cityId = cityId or getCurCityId()
    if not guildInfo then return false end
    if isOwnCity(cityId) then return false end
    local info = getCityInfo(cityId)
    if not info then return false end
    if not info.atkGuild then return false end
    if info.status == GVG_pb.CITY_STATUS_DECLARED and info.fightbackTime and info.fightbackTime > 0 then return false end
    local status = getGVGStatus()
    if status ~= GVG_pb.GVG_STATUS_FIGHTING then return false end
    local guildId = guildInfo.id
    return info.atkGuild.guildId == guildInfo.id
end

function canReAtkCity(cityId)
    return  false 
    --不要反攻的操作
--    cityId = cityId or getCurCityId()
--    if not guildInfo then return false end
--    if isOwnCity(cityId) then return false end
--    local info = getCityInfo(cityId)
--    if not info then return false end
--    if not info.reAtkGuildId then return false end
--    if not info.status == GVG_pb.CITY_STATUS_REATTACK then return false end
--    if getGuildPos() < 1 then return false end
--    local guildId = guildInfo.id
--    CCLuaLog("reatk city id:" .. info.cityId)
--    CCLuaLog("reatk city status:" .. info.status)
--    CCLuaLog("reatk city reAtkGuildId :" .. info.reAtkGuildId)
--    return guildId == info.reAtkGuildId
end

function cityHasDefender(cityId)
    cityId = cityId or getCurCityId()
    local info = getCityInfo(cityId)
    if not info.defGuild then return false end
    return info.defGuild.guildId > 0
end

--是否可以驻屯
function canSendRoleCity(cityId)
    cityId = cityId or getCurCityId()
    if not guildInfo then return false end

    local cfg = getCityCfg(cityId) 
    if cfg.level == 0 then return false  end  --检测该城是不是复活点

    local info = getCityInfo(cityId)

    local gvgStatus = getGVGStatus()

    if gvgStatus == GVG_pb.GVG_STATUS_PREPARE or gvgStatus== GVG_pb.GVG_STATUS_WAITING then 
       
    else
        return false  
    end

    if not todayRankList or #todayRankList == 0 then return false end
    local guildId = guildInfo.id

    local maxNumber = 15
    if todayRankList and  #todayRankList > 16 then
        maxNumber = #todayRankList
    end

    for k,v in pairs(todayRankList) do
        if v.id == guildId and v.rank <= maxNumber then
            return true
        end
    end
    return false
end


function isOwnCity(cityId)
    cityId = cityId or getCurCityId()
    if not guildInfo then return false end
    if guildInfo and guildInfo.id then
        return isGuildHasCity(guildInfo.id or 0, cityId)
    else
        return false
    end
end

function isGuildHasCity(guildId, cityId)
    cityId = cityId or getCurCityId()
    if guildId > 0 then
        if cityInfo then
            for i = 1, #cityInfo do
                local city = cityInfo[i]
                if city.cityId == cityId then
                    if city.defGuild and city.defGuild.guildId == guildId then
                        return true
                    else
                        return false
                    end
                end
            end
        end
    end
    return false
end

function changeCity(data)
    local needClear = false
    if cityInfo then
        local isExist = false
        for i = 1, #cityInfo do
            local city = cityInfo[i]
            if city.cityId == data.cityId then
                city.status = data.status
                if data.defGuild then
                    if data.defGuild.guildId ~= city.defGuild.guildId then
                        local record = {}
                        record.cityId = data.cityId
                        record.atkName = data.defGuild.name
                        record.defName = city.defGuild.name
                        record.isAtkWin = 1
                        record.isReAtk = data.status ~= GVG_pb.CITY_STATUS_REATTACK
                        table.insert(cityLog,record)
                        needClear = true
                    end
                    --city.defGuild = GVG_pb.GuildInfo()
                    city.defGuild.guildId = data.defGuild.guildId
                    city.defGuild.name = data.defGuild.name
                end
                if data.atkGuild then
                    --city.atkGuild = GVG_pb.GuildInfo()
                    city.atkGuild.guildId = data.atkGuild.guildId
                    city.atkGuild.name = data.atkGuild.name
                end
                if data.defTeamNum then
                    city.defTeamNum = data.defTeamNum
                end
                if data.reAtkGuildId then
                    city.reAtkGuildId = data.reAtkGuildId
                end
                if data.fightbackTime then
                    city.fightbackTime = data.fightbackTime
                else
                    city.fightbackTime = 0
                end
                if data:HasField("isReAtk") then
                    city.isReAtk = data.isReAtk
                end
                isExist = true
                break
            end
        end
        if not isExist then      
            local city = transformCityData(data)
            table.insert(cityInfo ,city)
        end
        PageManager.refreshPage(moduleName , onCityChange)
    end
    if needClear then
        clearCityBattleLog(data.cityId)
        clearCityBattleNotice(data.cityId)
		clearCityTeamNum(data.cityId)
    end
end

function getGuildColor(guildId)
    
end

function declareBattle(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.DeclareBattleRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.DECLARE_BATTLE_C, msg, true)
end

function declareReAtk(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.DeclareBattleRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.FIGHT_BACK_C, msg, true)
end


function revieveDeclare(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.BuyReviveRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.BUY_REVIVE_C, msg, false)
end


function getAtkFlag()

end

function getDefFlag()

end

-------------规则与排行--------------------------------

function reqVitalityRank()
    common:sendEmptyPacket(HP_pb.TODAY_VITALITY_RANKS_C, true)
end

function reqYesterdayVitalityRank()
    common:sendEmptyPacket(HP_pb.YESTERDAY_VITALITY_RANKS_C, true)
end

function initTodayRank(data)
    todayRankList = data.ranks

    PageManager.refreshPage(moduleName, onTodayRank)
end

function initYesterdayRank(data)
    yesterdayRankList = data.ranks

    PageManager.refreshPage(moduleName, onYesterdayRank)
end

function getRankList(rankType)
    if rankType == TODAY_RANK then
        return todayRankList
    elseif rankType == YESTERDAY_RANK then
        return yesterdayRankList
    end
end

--------------------------佣兵队列---------------------------------

function joinAtkTeam(cityId,teamArr)
    local msg = GVG_pb.SendRoleRequest()
    msg.cityId = cityId
    for i = 1, #teamArr do
        msg.roleIds:append(teamArr[i])
    end
    common:sendPacket(HP_pb.CITY_ATTACKER_C, msg, true)
end

function joinDefTeam(cityId,teamArr)
    local msg = GVG_pb.SendRoleRequest()
    msg.cityId = cityId
    for i = 1, #teamArr do
        msg.roleIds:append(teamArr[i])
    end
    common:sendPacket(HP_pb.CITY_DEFENDER_C, msg, false)
end

function reqCityAtkList(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.CityTeamRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.VIEW_ATTACK_TEAM_C , msg,false)
end

function reqCityDefList(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.CityTeamRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.VIEW_DEFENDER_TEAM_C , msg, false)
    return true
end

function reqPlayerTeamList()
    common:sendEmptyPacket(HP_pb.VIEW_TEAM_C ,true)
end

function reqSyncTeamNum()
    if getGVGStatus() ~= GVG_pb.GVG_STATUS_FIGHTING then 
        PageManager.refreshPage(moduleName,onTeamNumChange)
        return 
    end
    --if isSyncTeamNum then return end
    common:sendEmptyPacket(HP_pb.TEAM_NUMBER_C,true)
end

function initCityTeamList(data, showType)
    if not cityTeamsList[data.cityId] then
        cityTeamsList[data.cityId] = {}
    end
    cityTeamsList[data.cityId][showType] = data.teams

    PageManager.refreshPage(moduleName, onCityTeamList)
end

function insertCityTeamList(cityId,showType,data)
    cityId = cityId or getCurCityId()
    if cityId > 0 then
        if not cityTeamsList[cityId] then
            cityTeamsList[cityId] = {}
        end
        if not cityTeamsList[cityId][showType] then
            local msg = GVG_pb.CityTeamResponse()
            cityTeamsList[cityId][showType] = msg.teams
        end
        local team = GVG_pb.TeamInfo()
        team.teamId = #cityTeamsList[cityId][showType] + 1
        team.playerId = UserInfo.playerInfo.playerId
        team.playerName = UserInfo.roleInfo.name
        team.playerLevel = UserInfo.roleInfo.level
        team.rebirthStage = UserInfo.roleInfo.rebirthStage
        team.fightNum = UserInfo.roleInfo.fight
        team.cityId = cityId
        for i = 1, #data do
            team.roleIds:append(data[i])
        end
        cityTeamsList[cityId][showType]:add(team)
        
        if showType == SHOWTYPE_DEF then
            local info = getCityInfo(cityId)
            info.defTeamNum = info.defTeamNum + 1
        end
    end
end

function initPlayerTeamList(data)
    playerTeamList = data.teams or {}

    PageManager.refreshPage(moduleName, onPlayerTeamList)
end

function changeDefOrder(cityId, old, new)
    local msg = GVG_pb.ChangeDefenceOrderRequest()
    msg.cityId = cityId
    msg.oldTeamId = old
    msg.newTeamId = new

    common:sendPacket(HP_pb.DEFENDER_REORDER_C, msg, true)
end

function getPlayerTeams()
    local arr = {}
    if debugLocal then
        for i = 1, 10 do
            arr[i] = {
                teamId = i,
                playerId = 1,
                playerName = "1のa",
                playerLevel = 120,
                rebirthStage = 1,
                fightNum = 99999,
                cityId = i,
                roleIds = {math.random(101,109),math.random(111,115),math.random(116,120)}
            }
        end
    else
        arr = playerTeamList
    end

    return arr
end

function getCityTeams(cityId, showType)
    if cityTeamsList[cityId] and cityTeamsList[cityId][showType] then
        return cityTeamsList[cityId][showType]
    end
    return {}
end

function reqRoleInfo()
    common:sendEmptyPacket(HP_pb.VIEW_ROLE_TEAM_C, true)
end

function initPlayerRoles(data)
    --playerRoleList = data.roles or {}
    local rolesInfo = UserMercenaryManager:getUserMercenaryInfos()
    playerRoleList = {} 
    local roleTmp =   data.roles or {}
    for k,v in pairs(roleTmp) do
        for m,n in pairs(rolesInfo) do 
             if v.roleId  == m then
               table.insert(playerRoleList, v)
               break
             end
         end
    end
    PageManager.refreshPage(moduleName, onReceiveRolesInfo)
end

function getAllRoles()
    local arr = {}
    if debugLocal then
        local rolesInfo = UserMercenaryManager:getUserMercenaryInfos()
        for k,v in pairs(rolesInfo) do
            local item = {
                roleId = v.roleId,
                status = math.random(1,4),
                energy = math.random(0,4)
            }
            table.insert(arr, item)
        end
    else
        arr = playerRoleList or {}
    end

    return arr
end

-----------领奖---------------------------

function reqRewardInfo()
    common:sendEmptyPacket(HP_pb.CITY_REWARD_SHOW_C, true)
end

function reqGetGVGAward()
    common:sendEmptyPacket(HP_pb.GET_CITY_REWARD_C, false)
end

function reqGetGVGBox(cityId)
    local msg = GVG_pb.RewardRequest()
    msg.cityId = cityId

    common:sendPacket(HP_pb.GET_CITY_BOX_C, msg, false)
end

function initRewardInfo(data)
    rewardInfo = data

    PageManager.refreshPage(moduleName, onRewardInfo)
end

function needShowRewardNotice()
    if not rewardInfo then return false end
    local _,rewarding = getRewardCityList()
    if #rewarding > 0 then return true end
    if rewardInfo.reward and rewardInfo.reward ~= "-1" and rewardInfo.reward ~= "" then return true end
    return false
end

function getRewardCityList()
    local arr = {}
    local rewarding = {}
    if rewardInfo then
        initCityConfig()
        local rewardingCityIds = rewardInfo.rewardingCityIds or {}
        for i = 1, #rewardingCityIds do
            local cfg = getCityCfg(rewardingCityIds[i])
            table.insert(arr,cfg)
            table.insert(rewarding,cfg)
        end
        local rewardedCityIds = rewardInfo.rewardedCityIds or {}
        for i = 1, #rewardedCityIds do
            local cfg = getCityCfg(rewardedCityIds[i])
            table.insert(arr,cfg)
        end        
    end
    local function sortCity(a,b)
        if a.level ~= b.level then
            return a.level > b.level
        else
            return a.id < b.id
        end
    end
    table.sort(arr,sortCity)
    table.sort(rewarding,sortCity)
    return arr,rewarding
end

---------战斗队列-------------------------
local function isSameBattle(battle1, battle2)
    local char1 = battle1.battleData.character or {}
    local char2 = battle2.battleData.character or {}
    if #char1 ~= #char2 then return false end
    table.sort(char1, function(a,b)
        return a.pos < b.pos
    end)
    table.sort(char2, function(a,b)
        return a.pos < b.pos
    end)
    for i = 1, #char1 do
        local charA = char1[i]
        local charB = char2[i]
        if charA.id ~= charB.id         then return false end
        if charA.hp ~= charB.hp         then return false end
        if charA.mp ~= charB.mp         then return false end
        if charA.curHp ~= charB.curHp   then return false end
        if charA.curMp ~= charB.curMp   then return false end        
    end

    return true
end

function reqCityBattleInfo(cityId)
    cityId = cityId or getCurCityId()
    local msg = GVG_pb.CityBattleInfoRequest()
    msg.cityId = cityId
    common:sendPacket(HP_pb.VIEW_CITY_BATTLE_C, msg , true)
end

function initCityBattleList(data)
    if data.cityId ~= getCurCityId() then return end
    curBattle = {
        cityId = data.cityId,
        attackerName = "",
        defenderName = ""
    }

    if data.battle and data.battle.battleType == Battle_pb.BATTLE_GVG_CITY then
        curBattleInfo = data.battle
        curBattle.attackerName = data.attackerName
        curBattle.defenderName = data.defenderName
        if not data.defenderName or data.defenderName == "" then
            local cfg = getCityCfg()
            curBattle.defenderName = common:getLanguageString("@GVGNpcName" ,cfg.cityName)
        end
        local needRefresh = false
        local battleTime = os.time() + serverTimeOffset
        if data.battleTime and data.battleTime > 0 then
            battleTime = math.floor(data.battleTime / 1000)
        end
        local curTime = os.time() + serverTimeOffset
        if data.currentTime and data.currentTime > 0 then
            curTime = math.floor(data.currentTime / 1000)
            serverTimeOffset = curTime - os.time()
        end
        if lastBattleCache[data.cityId] then
            local lastBattle = lastBattleCache[data.cityId]
            if isSameBattle(lastBattle.battle, data.battle) then
                if lastBattle.time + battleShowTime < curTime then
                    curBattleInfo = nil
                    curBattle.attackerName = ""
                    curBattle.defenderName = ""
                else
                    data.battleLogs:remove(#data.battleLogs)
                end
            else
                needRefresh = true
                data.battleLogs:remove(#data.battleLogs)
            end
        else
            if curTime - battleTime >= battleShowTime then
                curBattleInfo = nil
                curBattle.attackerName = ""
                curBattle.defenderName = ""
            else
                data.battleLogs:remove(#data.battleLogs)
            end
            needRefresh = true
        end
        if needRefresh then
            lastBattleCache[data.cityId] = {
                time = battleTime,
                battle = data.battle
            }
        end
    end
    
    local tempLogs = {}
    for i = 1, #data.battleLogs do
        local rec = data.battleLogs[i]
        local str = ""
        if not rec.defName or rec.defName == "" then
            local cfg = getCityCfg()
            rec.defName = common:getLanguageString("@GVGNpcName" ,cfg.cityName)
        end
       
        if rec.isAtkWin == 1 then
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3101)
            str = common:fill(freeTypeCfg.content,rec.atkName, rec.defName, (rec.continueWin) or 0)
        else
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3102)
            str = common:fill(freeTypeCfg.content,rec.defName, rec.atkName, (rec.continueWin) or 0)
        end
        table.insert(tempLogs, {
            content = str,
            continueWin = (rec.continueWin) or 0,
            isAtkWin = rec.isAtkWin
        })
    end
    curBattleLogs = tempLogs
    PageManager.refreshPage(moduleName, onBattleInfo)
end

function insertCityBattleList(data)
    if data.cityId == getCurCityId() then
        pushIntoLog(false, false)
        curBattleInfo = data.battle
        curBattle.defTeamNumbers = data.defTeamNumbers
        curBattle.atkTeamNumbers = data.atkTeamNumbers
        print("==================================================")
        print("cityId:",data.cityId)
        print("curBattle atk numbers push:" , data.atkTeamNumbers)
        print("curBattle def numbers push:" , data.defTeamNumbers)
        print("==================================================")
        curBattle.attackerName = data.attackerName
        curBattle.defenderName = data.defenderName
        lastBattleCache[data.cityId] = {
            battle = data.battle,
            time = os.time() + serverTimeOffset
        }
        PageManager.refreshPage(moduleName, onBattleInfo)
    end
end

local function getKillNum(battle)
    local character = battle.battleData.character
    local atkDeadNum = 0
    local defDeadNum = 0
    for i = 1, #character do
        local char = character[i]
        if char.pos % 2 == 0 then atkDeadNum = atkDeadNum + 1
        else defDeadNum = defDeadNum + 1 end
    end
    if battle.fightResult == 1 then return defDeadNum
    else return atkDeadNum end
end

function getLastLog()
    local lastRec = {}
    if curBattleLogs then
        lastRec = curBattleLogs[#curBattleLogs] or {}
    end
    return lastRec
end

function pushIntoLog(clearBattle, dispatchMsg, oldCityInfo)
    if curBattleInfo then
        local isAtkWin = curBattleInfo.fightResult
        local str = ""
        local continueWin = 0
        if oldCityInfo then
            --[[TODO:HTML]]
            local cfg = getCityCfg()
            local defName = common:getLanguageString("@GVGNpcName" ,cfg.cityName)
            if oldCityInfo.defGuild and oldCityInfo.defGuild.guildId > 0 then
                defName = oldCityInfo.defGuild.name
            end
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(3103)
            str = common:fill(freeTypeCfg.content, oldCityInfo.atkGuild.name, defName, cfg.cityName)
        else
            local deadNum = getKillNum(curBattleInfo) or 0
            continueWin = deadNum
            local lastRec = curBattleLogs[#curBattleLogs]
            if lastRec then
                if lastRec.isAtkWin == isAtkWin then
                    if lastRec.continueWin then
                        continueWin = lastRec.continueWin + deadNum
                    end
                end
            end
            if isAtkWin == 1 then
                local freeTypeCfg = ConfigManager.getFreeTypeCfg(3101)
                str = common:fill(freeTypeCfg.content,curBattle.attackerName, curBattle.defenderName, continueWin or 0)
            else
                local freeTypeCfg = ConfigManager.getFreeTypeCfg(3102)
                str = common:fill(freeTypeCfg.content,curBattle.defenderName, curBattle.attackerName, continueWin or 0)
            end
            
        end
        table.insert(curBattleLogs,{
            content = str,
            continueWin = continueWin,
            isAtkWin = isAtkWin
        })
    end
    if clearBattle then
        curBattleInfo = nil        
        curBattle.attackerName = ""
        curBattle.defenderName = ""
    end
    if dispatchMsg then
        PageManager.refreshPage(moduleName, onBattleInfo)
    end
end

function clearCityBattleLog(cityId)
    if lastBattleCache[cityId] then lastBattleCache[cityId] = nil end
    if cityId == getCurCityId() then
        curBattleLogs = {}
        curBattle = {}
    end
end

function getFirstRoleInfoByBattleData(battleData)
    local firstAtk ,firstDef = {},{}
    if battleData.character then
        for i = 1, #battleData.character do
            local char = battleData.character[i]
            if char.pos == 0 then
                firstAtk = char
            elseif char.pos == 1 then
                firstDef = char
            end
        end
    end
    return firstAtk, firstDef
end

-------------------服务器返回处理------------------------

function onMapInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.MapInfoResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initMapInfo(msg)
    end
end
HPMapInfo = PacketScriptHandler:new(HP_pb.GVG_MAP_INFO_S, onMapInfoResp);

function onAtkTeamResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityTeamResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initCityTeamList(msg, SHOWTYPE_ATK)
    end
end
HPCityTeamAtk = PacketScriptHandler:new(HP_pb.VIEW_ATTACK_TEAM_S, onAtkTeamResp);

function onDefTeamResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityTeamResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initCityTeamList(msg, SHOWTYPE_DEF)
    end
end
HPCityTeamDef = PacketScriptHandler:new(HP_pb.VIEW_DEFENDER_TEAM_S, onDefTeamResp);

function onChangeOrderResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.ChangeDefenceOrderResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        if msg.result == 1 then
            PageManager.refreshPage(moduleName, onChangeOrder)
        elseif msg.result == 0 then
            MessageBoxPage:Msg_Box("@GVGTeamTooOld")
            reqCityDefList()
        end
    end
end
HPChangeOrder = PacketScriptHandler:new(HP_pb.DEFENDER_REORDER_S, onChangeOrderResp);

function onPlayerRoleListResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.PlayerRoleListResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initPlayerRoles(msg)

        if not isOpenJoinPage then
            PageManager.pushPage("GVGTeamJoinPage")
        end
    end
end
HPPlayerRoleList = PacketScriptHandler:new(HP_pb.VIEW_ROLE_TEAM_S, onPlayerRoleListResp);

function onDeclareBattleResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.DeclareBattleResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        changeCity(msg.citys)
    end
end

HPDeclareBattle = PacketScriptHandler:new(HP_pb.DECLARE_BATTLE_S, onDeclareBattleResp);
HPDeclareReAtk = PacketScriptHandler:new(HP_pb.FIGHT_BACK_S, onDeclareBattleResp);

function onReviveDeclareResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.BuyReviveResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
        changeCity(msg.cityInfo)
    end
end

HPReviveDeclare = PacketScriptHandler:new(HP_pb.BUY_REVIVE_S, onReviveDeclareResp);


function onTodayVitalityRankResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.VitalityRanksResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initTodayRank(msg)
    end
end
HPTodayVitalityRank = PacketScriptHandler:new(HP_pb.TODAY_VITALITY_RANKS_S, onTodayVitalityRankResp);

function onYesterdayVitalityRankResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.SeasonRankingsResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initYesterdayRank(msg)
    end
end
HPYesterdayVitalityRank = PacketScriptHandler:new(HP_pb.YESTERDAY_VITALITY_RANKS_S, onYesterdayVitalityRankResp);

function onSendRoleResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.SendRoleResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        PageManager.refreshPage(moduleName, onJoinTeam)
    end
end
HPSendRoleDef = PacketScriptHandler:new(HP_pb.CITY_DEFENDER_S, onSendRoleResp);
HPSendRoleAtk = PacketScriptHandler:new(HP_pb.CITY_ATTACKER_S, onSendRoleResp);

function onGuildInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = Alliance_pb.HPAllianceEnterS();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initGuildInfo(msg)
    end
end
HPGuildInfo = PacketScriptHandler:new(HP_pb.ALLIANCE_ENTER_S, onGuildInfoResp);

function onViewTeamResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.PlayerTeamListResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initPlayerTeamList(msg)
    end
end
HPViewTeam = PacketScriptHandler:new(HP_pb.VIEW_TEAM_S, onViewTeamResp)

function onGVGStatusChange(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.GVGStatusChange();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        setGVGStatus(msg.status)
    end
end
HPGVGStatusChange = PacketScriptHandler:new(HP_pb.PUSH_GVG_STATE_S, onGVGStatusChange)

function onCityStatusChange(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityInfo();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        changeCity(msg)
    end
end
HPCityStatusChange = PacketScriptHandler:new(HP_pb.PUSH_CITY_STATE_S, onCityStatusChange)

function onBattlePush(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityBattlePush();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        if msg.cityId == getCurCityId() then
            reqCityBattleInfo()
        end
        if isOwnCity(msg.cityId) then
            insertCityBattleNotice(msg.cityId)
        end
    end
end
HPBattlePush = PacketScriptHandler:new(HP_pb.PUSH_GVG_BATTLE_S, onBattlePush)

function onBattleInfoList(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityBattleInfoResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initCityBattleList(msg)
    end
end
HPBattleInfoList = PacketScriptHandler:new(HP_pb.VIEW_CITY_BATTLE_S, onBattleInfoList)

function onRewardInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.CityRewardResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
        
        needCheckGuildPoint = false
        initRewardInfo(msg)
    end
end
HPRewardInfo = PacketScriptHandler:new(HP_pb.CITY_REWARD_SHOW_S, onRewardInfoResp)

function onGVGConfigResp(eventName,handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.GvgConfig();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initGVGConfig(msg)
    end
end
HPGVGConfig = PacketScriptHandler:new(HP_pb.GVG_CONFIG_S, onGVGConfigResp)

function onGVGTeamNumberPush(eventName,handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.TeamNumberPush();

		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        initCityTeamNum(msg)
    end
end
HPTeamNum = PacketScriptHandler:new(HP_pb.TEAM_NUMBER_PUSH_S, onGVGTeamNumberPush)

function onGVGTeamNumberSync(eventName,handler)
    if eventName == "luaReceivePacket" then
		local msg = GVG_pb.TeamNumberResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)
        for i = 1, #msg.teams do
            initCityTeamNum(msg.teams[i],true)
        end
        --isSyncTeamNum = true
    end
end
HPTeamNumSync = PacketScriptHandler:new(HP_pb.TEAM_NUMBER_S, onGVGTeamNumberSync)

function validateAndRegister()
    HPMapInfo:registerFunctionHandler(onMapInfoResp)
    HPCityTeamAtk:registerFunctionHandler(onAtkTeamResp)
    HPCityTeamDef:registerFunctionHandler(onDefTeamResp)
    HPChangeOrder:registerFunctionHandler(onChangeOrderResp)
    HPPlayerRoleList:registerFunctionHandler(onPlayerRoleListResp)
    HPDeclareBattle:registerFunctionHandler(onDeclareBattleResp)
    HPDeclareReAtk:registerFunctionHandler(onDeclareBattleResp)
    HPReviveDeclare:registerFunctionHandler(onReviveDeclareResp)
    HPTodayVitalityRank:registerFunctionHandler(onTodayVitalityRankResp)
    HPYesterdayVitalityRank:registerFunctionHandler(onYesterdayVitalityRankResp)
    HPSendRoleAtk:registerFunctionHandler(onSendRoleResp)
    HPSendRoleDef:registerFunctionHandler(onSendRoleResp)
    HPGuildInfo:registerFunctionHandler(onGuildInfoResp)
    HPViewTeam:registerFunctionHandler(onViewTeamResp)
    HPGVGStatusChange:registerFunctionHandler(onGVGStatusChange)
    HPCityStatusChange:registerFunctionHandler(onCityStatusChange)
    HPBattlePush:registerFunctionHandler(onBattlePush)
    HPBattleInfoList:registerFunctionHandler(onBattleInfoList)
    HPRewardInfo:registerFunctionHandler(onRewardInfoResp)
    HPGVGConfig:registerFunctionHandler(onGVGConfigResp)
    HPTeamNum:registerFunctionHandler(onGVGTeamNumberPush)
    HPTeamNumSync:registerFunctionHandler(onGVGTeamNumberSync)
end

function unRegister()

end