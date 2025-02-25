--[[----------------------------------------------
@ module("OSPVPManager")
 
--]]----------------------------------------------
local ConfigManager = require("ConfigManager")
local common = require("common")
local HP_pb = require("HP_pb")
local Battle_pb = require("Battle_pb")
local CsBattle_pb = require("CsBattle_pb")
local Shop_pb = require("Shop_pb")
local Const_pb = require("Const_pb")
local PageManager = require("PageManager")
local UserMercenaryManager = require("UserMercenaryManager")
local UserInfo = require("PlayerInfo.UserInfo")
local ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo");
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
local rawset = rawset
local rawget = rawget

module("OSPVPManager")

moduleName = "OSPVPManager"

local buyTimesCost = {50,100,150,200,250,250}

------属性表
local selfProps = {
    ----自己的跨服标识
    selfIdentify = {
        get = 2,
        set = 2,
        default = -1,
        --notClean = true
    },

    ----是否用于打开主UI的请求
    isEnter = {
        get = 1,
        set = 1,
        default = false
    },

    ----系统开启状态
    systemStatus = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName, onSystemStatus)
        end,
        default = CsBattle_pb.DATA_MAINTAIN,
        --notClean = true
    },

    ----当前对手列表
    curVsList = {
        get = function(value)
            table.sort(value, function(a,b)
                if a.score ~= b.score then
                    return a.score > b.score
                else
                    return a.rank < b.rank
                end
            end)
            return value
        end,
        set = function(v)
            local list = {}
            for i,v in ipairs(v.value) do
                table.insert(list,v)
            end
            v.value = list
            PageManager.refreshPage(moduleName, onVsList)
        end,
        default = {},
        --notClean = true
    },

    ----剩余挑战次数
    leftVsTime = {
        get = 1,
        set = function(v)
            PageManager.refreshPage(moduleName, onLeftVsTime)
        end,
        default = 0,
        --notClean = true
    },

    ----剩余购买次数
    leftBuyTime = {
        get = 1,
        set = function(v)
            PageManager.refreshPage(moduleName, onLeftVsTime)
        end,
        default = 0,
        --notClean = true
    },

    ----总购买次数
    totalBuyTime = {
        get = function()
            return 5
        end,
        set = 0,
        default = 5,
    },

    ----已购买次数
    buyedTime = {
        get = function()
            return _M:getTotalBuyTime() - _M:getLeftBuyTime()
        end,
        set = 0,
        default = 0
    },

    ----玩家对象
    playerInfo = {
        get = 2,
        set = function(v)
            local value = v.value
            if value.score then
                _M:setScore(value.score)
            end
            if value.rank then
                _M:setRank(value.rank)
            end
            if value.continueWin then
                _M:setContinueWin(value.continueWin)
            end
            if value.identify then
                _M:setSelfIdentify(value.identify)
            end
            local oldStage = _M:getOldStage()
            if not oldStage then
                _M:setOldRank(value.rank)
                _M:setOldScore(value.score)
            end
            PageManager.refreshPage(moduleName, onPlayerInfo)
        end,
        --notClean = true
    },

    ----积分
    score = {
        get = 1,
        set = function(v)
            PageManager.refreshPage(moduleName, onStage)
        end,
        default = 0,
        --notClean = true
    },
    
    ----排名
    rank = {
        get = 1,
        set = function(v)
            PageManager.refreshPage(moduleName, onStage)
        end,
        default = 0,
        --notClean = true
    },

    ----连胜
    continueWin = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName, onContinueWin)
        end,
        default = 0,
        --notClean = true
    },

    ----缓存战阶
    oldStage = {
        get = function()
            local rank = _M:getOldRank()
            local score = _M:getOldScore()
            if rank == -1 or score == -1 then
                return nil
            else
                return checkStage(score,rank)
            end
        end,
        set = 0,
        default = nil
    },

    ----缓存排名
    oldRank = {
        get = 2,
        set = 2,
        default = -1,
        --notClean = true
    },

    ----缓存积分
    oldScore = {
        get = 2,
        set = 2,
        default = -1,
        --notClean = true
    },

    ----当前战报
    curBattle = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName, onNewBattle)
        end
    },

    ----当前胜负
    curResult = {
        get = 1,
        set = 1,
        default = nil
    },

    ----当前战报防御者
    curDef = {
        get = function()
            return string.format("%s%s",_M:getCurDefServer(),_M:getCurDefName())
        end,
        set = 0,
        default = ""
    },

    curDefName = {
        get = 2,
        set = 2,
        default = ""
    },

    curDefServer = {
        get = 2,
        set = 2,
        default = ""
    },

    ----战报列表
    battleList = {
        get = function(value)
            table.sort(value, function(a,b)
                return a.battleId > b.battleId
            end)
            return value
        end,
        set = function(v)
            PageManager.refreshPage(moduleName, onBattleList)
        end,
        default = {}
    },

    ----查看历史战报
    recordBattle = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName, onRecordBattle)
        end
    },

    ----历史战报进攻者
    recordAtk = {
        get = 2,
        set = 2,
        default = ""
    },

    ----排行榜
    rankList = {
        get = function(value)
            table.sort(value, function(a,b)
                if a.score ~= b.score then
                    return a.score > b.score
                else
                    return a.rank < b.rank
                end
            end)
            return value
        end,
        set = function(v)
            PageManager.refreshPage(moduleName, onRankList)
        end,
        default = {}
    },

    selfServerRankList = {
        get = function()
            local allList = _M:getRankList()
            local list = {}
            for _,data in ipairs(allList) do
                local serverId = string.gsub(data.serverName,".*#","")
                if tonumber(serverId) == tonumber(UserInfo.serverId) then
                    table.insert(list,data)
                end
            end
            return list
        end,
        set = 0,
        default = {}
    },

    ----跨服币
    csMoney = {
        get = 2,
        set = function(v)
            PageManager.refreshPage(moduleName, onCsMoney)
        end,
        default = 0,
    },

    ----当前最高战阶
    maxStage = {
        get = 1,
        set = 0,
        default = 5,
        notClean = true
    },

    ----动画锁，true时锁住
    stageAnimFlag = {
        get = 1,
        set = 1,
        default = false,
    },

    ----本服玩家积分缓存
    localPlayerList = {
        get = 2,
        set = function()
            PageManager.refreshPage(moduleName, onLocalPlayerInfo)
        end,
        default = {},
        notClean = true
    },

    ----是否查看跨服阵容
    isWatchOSPlayer = {
        get = 1,
        set = 1,
        default = false,
    }
}

local stageCfg = {}
local roleCfg = {}
local rankRewardCfg = {}

------事件------
onSystemStatus = "onSystemStatus"       -----系统状态
onVsList = "onVsList"                   -----对战列表
onLeftVsTime = "onLeftVsTime"           -----剩余次数变化
onStage = "onStage"                     -----战阶相关变化
onNewBattle = "onNewBattle"             -----新战斗
onBattleList = "onBattleList"           -----战报列表
onRecordBattle = "onRecordBattle"       -----历史战斗
onRankList = "onRankList"               -----排行列表
onSync = "onSync"                       -----手动同步
onPlayerInfo = "onPlayerInfo"           -----玩家信息
onCsMoney = "onCsMoney"                 -----跨服币同步
onContinueWin = "onContinueWin"         -----连胜
onLocalPlayerInfo = "onLocalPlayerInfo" -----本服玩家积分信息

----------------
-----本地数据处理---------

function initAllCfg()
    stageCfg = common:deepCopy(ConfigManager.getOSPVPStageCfg())
    table.sort(stageCfg, function(a,b)
        if a.score ~= b.score then
            return a.score > b.score
        else
            return a.rank < b.rank
        end
    end)

    roleCfg = common:deepCopy(ConfigManager.getRoleCfg())

    rankRewardCfg = common:deepCopy(ConfigManager.getOSPVPRankRewardCfg())
    table.sort(rankRewardCfg, function(a,b)
        return a.minRank < b.minRank
    end)
end

function checkStage(score,rank)
    for i,v in ipairs(stageCfg) do
        if v.score <= score and (v.rank >= rank or v.rank == 0) then
            return v
        end
    end
    return stageCfg[1]
end

function checkNextStage(score,rank)
    local temp = nil
    for i,v in ipairs(stageCfg) do
        if v.score <= score and (v.rank >= rank or v.rank == 0) then
            return temp or v
        else
            temp = v
        end
    end
end

function checkReward(rank)
    if _M:getSystemStatus() == CsBattle_pb.DATA_MAINTAIN or _M:getSystemStatus() == CsBattle_pb.NOT_ENOUGH_CONDITION then
        return
    end
    for i,v in ipairs(rankRewardCfg) do
        if rank <= v.minRank and rank > 0 then
            return v.awards
        end 
    end
end

function initModule()
    common:initModuleProperty(_M, selfProps, true)
end

function clearTempData()
    common:resetModuleProperty(_M, selfProps, true)
    --roleCfg = {}
    --stageCfg = {}
end

function getRoleCfg(roleId)
    return roleCfg[roleId]
end

function getBuyTimeCost(buyTime)
    buyTime = math.min(buyTime,#buyTimesCost)
    return buyTimesCost[buyTime] or 0
end

function checkLocalPlayerInfo(playerId)
    local list = _M:getLocalPlayerList()
    return list[playerId]
end
--------------------------
----------服务器请求-------------
function reqVSInfo()
    if UserInfo.roleInfo.level < GameConfig.Default.OSPVPOpenLvLimit then return end
    common:sendEmptyPacket(HP_pb.OSPVP_VS_INFO_C, true)
end

function reqSyncPlayer()
    common:sendEmptyPacket(HP_pb.OSPVP_SYNC_PLAYER_C, false)
end

function reqRefreshVsInfo()
    common:sendEmptyPacket(HP_pb.OSPVP_REFRESH_VS_INFO_C, true)
end

function reqBattleList()
    common:sendEmptyPacket(HP_pb.OSPVP_BATTLELIST_C, true)
end

function reqBattleInfo(battleId)
    local msg = CsBattle_pb.BattleRequest()
    msg.battleId = battleId
    common:sendPacket(HP_pb.OSPVP_BATTLE_C,msg ,true)
end

function reqBattle(vsId)
    local msg = CsBattle_pb.PlayerVsRequest()
    msg.identify = vsId
    msg.sourceId = _M:getSelfIdentify()
    common:sendPacket(HP_pb.OSPVP_VS_C,msg , false)
end

function reqRankInfo()
    common:sendEmptyPacket(HP_pb.OSPVP_RANK_INFO_C, true)
end

function reqOSPlayerInfo(identify)
    local msg = CsBattle_pb.PlayerSnapshotRequest()
    msg.seeIdentify = identify
    common:sendPacket(HP_pb.OSPVP_PLAYER_ROLES_INFO_C, msg , true)
end

function reqAddPVPNum(times)
    local msg = CsBattle_pb.BuyBattleTimesRequest()
    msg.battleTimes = times
    common:sendPacket(HP_pb.OSPVP_BUY_VS_NUM_C,msg, true)
end

function reqBuyItem()

end

function reqLocalPlayerInfo(playerIds)
    -----本函数暂时作废
    if true then return end
    local msg = CsBattle_pb.PlayerRankRequest()
    for i,v in ipairs(playerIds) do
        msg.playerIds:append(v)
    end
    common:sendPacket(HP_pb.OSPVP_PLAYERS_RANK_C, msg, false)
end
----------------------------------

-------------服务器返回------------

function onVsInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
		local msg = CsBattle_pb.OSMainInfoResponse();
		local msgbuff = handler:getRecPacketBuffer();
		msg:ParseFromString(msgbuff)

        --initFetter(msg)
        if msg.vsPlayers then
            _M:setCurVsList(msg.vsPlayers)
        end
        if msg:HasField("leftTimes") then
            _M:setLeftVsTime(msg.leftTimes)
        end
        if msg:HasField("leftBuyTimes") then
            _M:setLeftBuyTime(msg.leftBuyTimes)
        end
        if msg:HasField("selfInfo") then  
            _M:setPlayerInfo(msg.selfInfo)
        end
        if msg:HasField("enterState") then
            _M:setSystemStatus(msg.enterState)
        else
            _M:setSystemStatus(CsBattle_pb.NORMAL)
        end
    end
end
local HPVSInfo = PacketScriptHandler:new(HP_pb.OSPVP_VS_INFO_S, onVsInfoResp)

function onSyncPlayerResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.PlayerInfoSyncResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        MessageBoxPage:Msg_Box("@CSPVPSyncSuccess")
        if msg:HasField("enterState") then
            _M:setSystemStatus(msg.enterState)
        end
        if msg:HasField("isSuccess") then
            local selfInfo = _M:getPlayerInfo()
            if selfInfo then
                selfInfo.rebirthStage = UserInfo.roleInfo.rebirthStage
                selfInfo.level = UserInfo.roleInfo.level
                selfInfo.fightValue = UserInfo.roleInfo.marsterFight
                selfInfo.rank = rank
                selfInfo.score = score
                selfInfo.continueWin = _M:getContinueWin()
                _M:setPlayerInfo(selfInfo)
            end
        end
    end
end
local HPSyncPlayer = PacketScriptHandler:new(HP_pb.OSPVP_SYNC_PLAYER_S, onSyncPlayerResp)

function onRefreshInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.RefreshVsResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        local curList = _M:getCurVsList()
        if msg.vsPlayers then
            local isSame = true
            if #curList ~= #msg.vsPlayers then 
                isSame = false
            else
                for i,v in ipairs(msg.vsPlayers) do
                    local one = common:table_filter(curList, function(_,_v)
                        return _v.identify == v.identify and _v.rank == v.rank
                    end)
                    if common:table_isSame(one, {}) then
                        isSame = false
                        break
                    end
                end
            end
            if isSame then
                MessageBoxPage:Msg_Box("@CSPVPSameList")
            end
            _M:setCurVsList(msg.vsPlayers)
        end
        if msg:HasField("enterState") then
            _M:setSystemStatus(msg.enterState)
        end
    end
end
local HPRefreshVSInfo = PacketScriptHandler:new(HP_pb.OSPVP_REFRESH_VS_INFO_S, onRefreshInfoResp)

function onChallengeResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.ChallengeResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)
        if msg:HasField("leftTimes") then
            _M:setLeftVsTime(msg.leftTimes)
        end
        if msg:HasField("leftBuyTimes") then
            _M:setLeftBuyTime(msg.leftBuyTimes)
        end
        if msg:HasField("battle") then
            _M:setCurBattle(msg.battle)
            local selfInfo = _M:getPlayerInfo()
            if selfInfo then
                PageManager.viewBattlePage(msg.battle, selfInfo.name, _M:getCurDef())
            end
        end
        if msg:HasField("isWin") ~= nil then
            curResult = msg.isWin
        end
        stageAnimFlag = true
        if msg:HasField("score") then
            _M:setScore(msg.score)
        end
        if msg:HasField("rank") then
            _M:setRank(msg.rank)
        end
        local oldStage = _M:getOldStage()
        if not oldStage then
            _M:setOldRank(msg.rank)
            _M:setOldScore(msg.score)
        end
        if msg.vsPlayers then
            _M:setCurVsList(msg.vsPlayers)
        end
        if msg:HasField("continueWin") then  
            _M:setContinueWin(msg.continueWin)
        end
        if msg:HasField("enterState") then
            _M:setSystemStatus(msg.enterState)
        end
    end
end
local HPChanllenge = PacketScriptHandler:new(HP_pb.OSPVP_VS_CHALLENGE_S, onChallengeResp)

function onDefenderResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.DefenderResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("score") then
            _M:setScore(msg.score)
        end
        if msg:HasField("rank") then
            _M:setRank(msg.rank)
        end
        if msg:HasField("continueWin") then
            _M:setContinueWin(msg.continueWin)
        end
    end
end
local HPDefender = PacketScriptHandler:new(HP_pb.OSPVP_VS_DEFENDER_S, onDefenderResp)

function onBattleListResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.BattleRecordResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg.battles then
            _M:setBattleList(msg.battles)
        end
    end
end
local HPBattleList = PacketScriptHandler:new(HP_pb.OSPVP_BATTLELIST_S, onBattleListResp)

function onBattleResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.BattleResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("battle") then
            _M:setRecordBattle(msg.battle)
            stageAnimFlag = true
            local selfInfo = _M:getPlayerInfo()
            if selfInfo then
                PageManager.viewBattlePage(msg.battle, _M:getRecordAtk(), selfInfo.name)
            end
        end
    end
end
local HPBattle = PacketScriptHandler:new(HP_pb.OSPVP_BATTLE_S, onBattleResp)

function onRankInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.RankResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg.players then
            _M:setRankList(msg.players)
        end
    end
end
local HPRankInfo = PacketScriptHandler:new(HP_pb.OSPVP_RANK_INFO_S, onRankInfoResp)

function onPlayerInfoResp(eventName,handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.PlayerSnapshotResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("snapshot") then
            --_M:setSnapShot(msg.snapshot)
            isWatchOSPlayer = true
            ViewPlayerInfo:setCSInfo(msg.snapshot, msg.seeIdentify)
            PageManager.pushPage("ViewPlayMenuPage");
        end
    end
end
local HPPlayerInfo = PacketScriptHandler:new(HP_pb.OSPVP_PLAYER_ROLES_INFO_S, onPlayerInfoResp)

function onBuyNumResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.BuyBattleTimesResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("leftTimes") then
            _M:setLeftVsTime(msg.leftTimes)
        end
        if msg:HasField("leftBuyTimes") then
            _M:setLeftBuyTime(msg.leftBuyTimes)
        end
        if msg:HasField("enterState") then
            _M:setSystemStatus(msg.enterState)
        end
    end
end
local HPBuyNum = PacketScriptHandler:new(HP_pb.OSPVP_BUY_VS_NUM_S, onBuyNumResp)

function onCsShopResponse(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = Shop_pb.ShopItemInfoResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg.shopType == Const_pb.CROSS_MARKET then
            for k,v in pairs(msg.data) do
                if v.dataType == Const_pb.CROSS_COIN_TYPE then
                    _M:setCsMoney(v.amount)
                    break
                end
            end
        end
    end
end
local HPCrossShop = PacketScriptHandler:new(HP_pb.SHOP_ITEM_S, onCsShopResponse)

function onLocalPlayerInfoResp(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.PlayerRankResponse();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg.playerRanks then
            local list = _M:getLocalPlayerList()
            for i,v in ipairs(msg.playerRanks) do
                list[v.playerId] = v
            end
            _M:setLocalPlayerList(list)
        end
    end
end
local HPLocalPlayer = PacketScriptHandler:new(HP_pb.OSPVP_PLAYERS_RANK_S, onLocalPlayerInfoResp)

function onSystemStatePush(eventName, handler)
    if eventName == "luaReceivePacket" then
        local msg = CsBattle_pb.StateChange();
	    local msgbuff = handler:getRecPacketBuffer();
	    msg:ParseFromString(msgbuff)

        if msg:HasField("state") then
            _M:setSystemStatus(msg.state)
        end
        reqVSInfo()
    end
end
local HPState = PacketScriptHandler:new(HP_pb.PUSH_CROSS_STATE_S, onSystemStatePush)

function validateAndRegister()
    HPVSInfo:registerFunctionHandler(onVsInfoResp)
    HPSyncPlayer:registerFunctionHandler(onSyncPlayerResp)
	HPBuyNum:registerFunctionHandler(onBuyNumResp)
	HPPlayerInfo:registerFunctionHandler(onPlayerInfoResp)
	HPRankInfo:registerFunctionHandler(onRankInfoResp)
	HPBattle:registerFunctionHandler(onBattleResp)
	HPBattleList:registerFunctionHandler(onBattleListResp)
	HPDefender:registerFunctionHandler(onDefenderResp)
	HPChanllenge:registerFunctionHandler(onChallengeResp)
	HPRefreshVSInfo:registerFunctionHandler(onRefreshInfoResp)
    HPCrossShop:registerFunctionHandler(onCsShopResponse)
    HPLocalPlayer:registerFunctionHandler(onLocalPlayerInfoResp)
    HPState:registerFunctionHandler(onSystemStatePush)
end



-----------------------------------
initAllCfg()
initModule()