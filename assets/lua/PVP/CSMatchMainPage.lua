
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local GSMatch_pb = require("GSMatch_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local CSMatchData = require("PVP.CSMatchData")
local roleCfg = ConfigManager.getRoleCfg()
local thisPageName = "CSMatchMainPage"
local opcodes = {
    GS_MATCH_PAGEINFO_S = HP_pb.GS_MATCH_PAGEINFO_S,
    GS_MATCH_BTN_S = HP_pb.GS_MATCH_BTN_S,
    GS_MATCH_BATTLE_S = HP_pb.GS_MATCH_BATTLE_S,
    GS_MATCH_WINSTREAK_LIST_S = HP_pb.GS_MATCH_WINSTREAK_LIST_S,
    GS_MATCH_BATTLE_LIST_S = HP_pb.GS_MATCH_BATTLE_LIST_S,
}
local option = {
    ccbiFile = "",
    handlerMap ={
        onHelp                  = "onHelp",
        onStartMatching         = "onStartMatching",
        onBeganToChallenge      = "onBeganToChallenge",
        onRank                  = "onRank",
        onBattleInformation     = "onBattleInformation",
    },
}
for i=1,2 do
    option.handlerMap["onBUffFeet"..i] = "onBuffFeet"
end
local CSMatchMainPage = BasePage:new(option,thisPageName,nil,opcodes)
local pageInfo = {
    m_tPlayersInfo = {},                -- 两侧人物信息
    m_nLeftLoseTimes = 0,               -- 剩余失败次数
    m_nWinStreaks = 0,                  -- 当前连胜次数
    m_bIsStartChallenge = false,        -- true_挑战 or false_vs图标
}
pageInfo.m_tPlayersInfo[1] = {}
pageInfo.m_tPlayersInfo[2] = {}
local m_sDelayBtnEnableKey = "CSMatchBtnDelayKey"
-------------------------- logic method ------------------------------------------
function CSMatchMainPage:showLocalPageInfo( container )
    -- 首页上面人物信息
    UserInfo.sync()
    local lb2Str = {
        mName = UserInfo.roleInfo.name,
        mCoin = UserInfo.playerInfo.coin,
        mGold = UserInfo.playerInfo.gold,
        mLV = UserInfo.getStageAndLevelStr()
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    local sprite2Img = {
        mVip = UserInfo.getVipImage()
    }
    NodeHelper:setSpriteImage(container, sprite2Img)
end
function CSMatchMainPage:refreshPage( container )
    local lb2Str = {}
    local img2Spr = {}
    for i=1,#pageInfo.m_tPlayersInfo do
        lb2Str["mOccupation"..i] = tostring(roleCfg[pageInfo.m_tPlayersInfo[i].roleId].name)
        lb2Str["mPlayerName"..i] = tostring(pageInfo.m_tPlayersInfo[i].playerName)
        lb2Str["mServerName"..i] = tostring(pageInfo.m_tPlayersInfo[i].serverName)
        lb2Str["mLeftBlood"..i] = tostring(pageInfo.m_tPlayersInfo[i].bloodNum)
        lb2Str["mFightValue"..i] = tostring(pageInfo.m_tPlayersInfo[i].fightValue)
        local buffLevel = tonumber(pageInfo.m_tPlayersInfo[i].debuffLevel)
        -- buff node显隐
        local buffNode = "mBuffNode"..i
        NodeHelper:setNodesVisible(container,{buffNode=(isShowBuff~=nil)})
        if buffLevel~=nil then
            NodeHelper:setSpriteImage(container,{buffNode = GameConfig.CSMatchBuff[buffLevel]})
        end
    end
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setNormalImages(container,img2Spr)
    local leftTimesStr = common:getLanguageString("@CSMatchLeftLoseTimes",pageInfo.leftLoseTimes)
    local winStreaksStr = common:getLanguageString("@CSMatchWinStreaks",pageInfo.winStreaks)
    NodeHelper:setStringForLabel(container,{
        mLeftLoseTimesLabel = leftTimesStr,
        mCurrentStreakLab = winStreaksStr
    })
    NodeHelper:setNodesVisible(container,{mBeganChallengeNode = pageInfo.m_bIsStartChallenge})
    NodeHelper:setNodesVisible(container,{mVSPicNode = pageInfo.m_bIsStartChallenge})
    -- 钮是在30秒内不可用
    if TimeCalculator:hasKey(m_sDelayBtnEnableKey) and TimeCalculator:getTimeLeft(m_sDelayBtnEnableKey)>0 then
        NodeHelper:setMenuItemEnabled(container,"mStartMathcingBtn",false)
    else
        NodeHelper:setMenuItemEnabled(container,"mStartMathcingBtn",true)
    end
end
-------------------------- state method -------------------------------------------
function CSMatchMainPage:onEnter(container)
    self:registerPacket(container)
    -- 首页上面人物信息
    self:showLocalPageInfo(container)
    local msg = GSMatch_pb.GSMatchInfo()
    msg.playerId = UserInfo.playerInfo.playerId
    common:sendPacket(HP_pb.CS_MATCH_PAGEINFO_C,msg)
end
function CSMatchMainPage:onExit(container)
    self:removePacket(container)
end
function CSMatchMainPage:onExecute(container)
    if TimeCalculator:hasKey(m_sDelayBtnEnableKey) and TimeCalculator:getTimeLeft(m_sDelayBtnEnableKey)>0 then
        local leftTime = TimeCalculator:getTimeLeft(m_sDelayBtnEnableKey)
        local lbStr = common:getLanguageString("@CSMatchEnableTimeCount"..leftTime)
        NodeHelper:setStringForLabel(container,{mStartMathcingLab = lbStr})
    else
        local lbStr = common:getLanguageString("@CSMatchStartMatchLab")
        NodeHelper:setStringForLabel(container,{mStartMathcingLab = lbStr})
    end
end
function CSMatchMainPage:onRank(  )
    common:sendEmptyPacket(HP_pb.GS_MATCH_WINSTREAK_LIST_C)
end
function CSMatchMainPage:onBattleInformation(  )
    
end
----------------------------click method -------------------------------------------
-- showTip
function CSMatchMainPage:onBuffFeet( container,eventName )
    local index = string.sub(eventName,-1)
    local buffLevel = tonumber(pageInfo.m_tPlayersInfo[index].debuffLevel)
    local buffNode = "mBuffFeet"..index
    GameUtil:showTip(container:getVarNode(buffNode),GameConfig.CSMatchBufferInfo[buffLevel] )
end
-- 匹配按钮
function CSMatchMainPage:onStartMatching( container )
    local msg = GSMatch_pb.GSMatchGuy()
    msg.playerId = UserInfo.playerInfo.palyerId
    common:sendPacket(HP_pb.GS_MATCH_BTN_C,msg)
end
-- 开始战斗
function CSMatchMainPage:onBeganToChallenge( container )
    common:sendEmptyPacket(HP_pb.GS_MATCH_BATTLE_C)
end
-- 查看排行
function CSMatchMainPage:onRank( container )
    common:sendEmptyPacket(HP_pb.GS_MATCH_WINSTREAK_LIST_C)
end
-- 查看战斗信息
function CSMatchMainPage:onBattleInformation( container )
    common:sendEmptyPacket(HP_pb.GS_MATCH_BATTLE_LIST_C)
end
----------------------------packet method -------------------------------------------
function CSMatchMainPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.GS_MATCH_PAGEINFO_S then
        local msg = GSMatch_pb.CSMatchInfoRet()
        msg:ParseFromString(msgBuff)
        -- 页面信息赋值
        pageInfo.m_tPlayersInfo[1] = msg.playersInfo
        pageInfo.m_nLeftLoseTimes = msg.leftLoseTimes
        pageInfo.m_nWinStreaks = msg.winStreaks
        self:refreshPage(container)
    elseif opcode == opcodes.GS_MATCH_BTN_S then
        local msg = GSMatch_pb.GSMatchGuyRet()
        msg:ParseFromString(msgBuff)
        pageInfo.m_tPlayersInfo[2] = msg.opponentInfo
        -- 按钮禁用30s
        TimeCalculator:createTimeCalculator(m_sDelayBtnEnableKey,GameConfig.CSMatchBtnDelayTime)
        self:refreshPage(container)
    elseif opcode == opcodes.GS_MATCH_BATTLE_S then
        local msg = GSMatch_pb.GSMatchBattleRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setBattleResult(msg)
        PageManager.viewBattlePage(msg.battleInfo)
    elseif opcode == opcodes.GS_MATCH_WINSTREAK_LIST_S then
        local msg = GSMatch_pb.GSMatchWinTreaksRankListRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setRankLists(msg)
        PageManager.pushPage("CSMatchRankPage")
    elseif opcode == opcodes.GS_MATCH_BATTLE_LIST_S then
        local msg = GSMatch_pb.GSMatchBattleListRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setBattleRecords(msg)
        PageManager.pushPage("CSMatchBattleRecordPage")
    end
end
function CSMatchMainPage:registerPacket( container )
    for key, opcode in opcodes do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function CSMatchMainPage:removePacket( container )
    for key, opcode in opcodes do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------------------------- end  ----------------------------------------------------
