
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local CSMatchData = require("PVP.CSMatchData")
local CsBattle_pb = require("CsBattle_pb")
local roleConfig = ConfigManager.getRoleCfg()
local rankRewardCfg = ConfigManager.getCSMatchRewardCfg()
local thisPageName = "CSMatchRankPage"
local opcodes = {
    OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S
}
local option = {
    ccbiFile = "CrossServerMatchingRankPage",
    handlerMap ={
        onReturnButton          = "onClose",
        onHelp                  = "onHelp",
        onStreakRanking         = "onStreakRanking",
        onAwardList             = "onAwardList",
    },
}
local CSMatchRankPage = BasePage:new(option,thisPageName,nil,opcodes)
-- 本地变量
local m_tTabType = {
    streakRank = 1,
    rewardRank = 2,
}
local m_nNowTab = m_tTabType.streakRank -- 当前所选页签
local m_tRanksInfo = {}                    -- 排行信息
-------------------------- logic method ------------------------------------------
function CSMatchRankPage:refreshTab( container )
    NodeHelper:setMenuItemSelected(container,{
        mStreakRankingBtn   = (m_nNowTab==m_tTabType.streakRank),
        mAwardListBtn       = (m_nNowTab==m_tTabType.rewardRank),
    })
end
function CSMatchRankPage:refreshPage( container )
    -- 刷新tab
    self:refreshTab(container)
    -- 当前排名
    local myRank = CSMatchData.getRankLists().nowRankNum
    NodeHelper:setStringForLabel(container,{mYourCurrentRankNum = myRank})
    -- 排行
    self:rebuildAllItem(container)
end
-------------------------- state method -------------------------------------------
function CSMatchRankPage:onEnter(container)
    container:registerPacket(opcodes.OPCODE_CS_BATTLEARRAY_INFO_S)
    m_nNowTab = m_tTabType.streakRank
    NodeHelper:initScrollView(container,"mContent",3)
    m_tRanksInfo = CSMatchData.getRankLists().ranksInfo
    self.refreshPage(container)
end
function CSMatchRankPage:onExit(container)
    container:removePacket(HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S)
end
----------------------------click method------------------------------------------
function CSMatchRankPage:onStreakRanking(container)
    if m_nNowTab ~= m_tTabType.streakRank then
        m_nNowTab = m_tTabType.streakRank
        self:refreshPage(container)
    end
end
function CSMatchRankPage:onAwardList( container )
    if m_nNowTab ~= m_tTabType.rewardRank then
        m_nNowTab = m_tTabType.rewardRank
        self:refreshPage(container)
    end
end
function CSMatchRankPage:onClose( container )
    PageManager.popPage(thisPageName)
end
----------------------------scroll View-------------------------------------------
-- 排行列表
local m_tRankItem = {
    ccbiFile = "CrossServerMatchingStreakRankContent"
}
function m_tRankItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        m_tRankItem.onRefreshItemView(container);
    elseif eventName == "onHand" then
        m_tRankItem.onHand(container);
    end     
end
function m_tRankItem.onRefreshItemView( container )
    local index = container:getItemData().mID
    local tRankInfo = m_tRanksInfo[index]
    -- 头像
    local headPic = roleConfig[tRankInfo.roleId].icon
    local proPic = roleConfig[tRankInfo.prof%100].proIcon
    NodeHelper:setSpriteImage(container, {
        mHand           = headPic,
        mProfession     = proPic,
    })
    -- 其他信息
    local lb2Str = {
        mLv                     = "Lv." .. tRankInfo.playerLevel,
        mRankNum                = tRankInfo.playerLevel,
        mPlayerName             = tRankInfo.playerName,
        mTodayHighestStreakNum  = tRankInfo.winStreaks,
        mServerName             = tRankInfo.serverName,
        mSurplusBloodNum        = bloodPercent.."%"
    }
    NodeHelper:setStringForLabel(container,lb2Str)
end
function m_tRankItem.onHand( container )
    local index = container:getItemData().mID
    local sPlayerIdentify = m_tRanksInfo[index].playerIdentify
    local msg = CsBattle_pb.OPCSBattleArrayInfo()
    msg.viewIdentify = sPlayerIdentify
    msg.version = 1
    common:sendPacket(HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,msg)
end
-- 奖励列表
local m_tRewardItem = {
    ccbiFile = "CrossServerMatchingStreakRankContent"
}
function m_tRewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        m_tRewardItem.onRefreshItemView(container)
    elseif eventName:sub(1,7) == "onFrame" then
        m_tRewardItem.onTip(container,eventName)
    end     
end
function m_tRewardItem.onRefreshItemView( container )
    local index = container:getItemData().mID
    local rewardCfg = rankRewardCfg[index]
    NodeHelper:fillRewardItem(container, rewardCfg.items, 4)
    common:getLanguageString("@CSMatchStreakRanking",rewardCfg.rank)
    NodeHelper:setStringForLabel(container,{mRankingNum})
end
function m_tRewardItem.onTip( container,eventName )
    local index = container:getItemData().mID
    local rewardCfg = rankRewardCfg[index]
    local rewardIndex = tonumber(eventName:sub(8))
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), rewardCfg.items[rewardIndex])
end
--
function CSMatchRankPage:rebuildAllItem(container)
    NodeHelper:clearAllItem(container)
    -- 排行列表
    if m_nNowTab == m_tTabType.streakRank then
        NodeHelper:buildScrollView(container,#m_tRanksInfo,m_tRankItem.ccbiFile,m_tRankItem.onFunction)
    elseif m_nNowTab == m_tTabType.rewardRank then
        NodeHelper:buildScrollView(container,#rankRewardCfg,m_tRewardItem.ccbiFile,m_tRewardItem.onFunction)
    end
end
----------------------------packet method -------------------------------------------
function CSMatchMainPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.OPCODE_CS_BATTLEARRAY_INFO_S then
        local msg = CsBattle_pb.OPCSBattleArrayInfoRet()
        msg:ParseFromString(msgBuff)
        if not msg.resultOK then
            MessageBoxPage:Msg_Box("@CSGetBattleInfoFailed");
        end
        if msg:HasField("playerInfo") then
            PageManager.viewCSPlayerInfo( msg.playerInfo )
        end
    end
end
---------------------------- end  ----------------------------------------------------
