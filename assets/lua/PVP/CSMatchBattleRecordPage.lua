
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local BasePage = require("BasePage")
local HP_pb = require("HP_pb")
local GSMatch_pb = require("GSMatch_pb")
local thisPageName = "CSMatchBattleRecordPage"
local opcodes = {
    GS_MATCH_REVENGE_LIST_S = HP_pb.GS_MATCH_REVENGE_LIST_S,
    GS_MATCH_BATTLE_S = HP_pb.GS_MATCH_BATTLE_S,
    GS_MATCH_VIEW_BATTLE_S = HP_pb.GS_MATCH_VIEW_BATTLE_S,
    GS_MATCH_REVENGE_S = HP_pb.GS_MATCH_REVENGE_S,
}
local option = {
    ccbiFile = "CrossServerMatchingBattleInformationPopUp",
    handlerMap ={
        onTurnOff   = "onClose",
        onHelp      = "onHelp",
        onRefresh   = "onRefresh",
        onBattleInformation = "onBattleInformation",
        onRevengeList = "onRevengeList",
    },
}
local CSMatchBattleRecordPage = BasePage:new(option,thisPageName,nil,opcodes)
-- 本地变量
local m_tTabType = {
    battleList = 1,
    revengeList = 2,
}
local m_nWinMail = 33                       -- 主动攻击胜利邮件模板
local m_nLoseMail = 34                      -- 主动攻击失败邮件模板
local m_nNowTab = m_tTabType.battleList     -- 当前所选页签
local m_tBattleInfo = {}                    -- 排行信息
local m_tRevengeInfo = {}                   -- 复仇信息
-------------------------- logic method ------------------------------------------
function CSMatchBattleRecordPage:refreshTab( container )
    NodeHelper:setMenuItemSelected(container,{
        mRankingRewardBtn   = (m_nNowTab==m_tTabType.battleList),
        mRevengeListBtn     = (m_nNowTab==m_tTabType.revengeList),
    })
end
function CSMatchBattleRecordPage:refreshPage( container )
    m_tBattleInfo = CSMatchData.getBattleRecords().battleResults
    m_tRevengeInfo = CSMatchData.getRevengeRecords().battleResults or {}
    -- 刷新tab
    self:refreshTab(container)
    -- 排行
    self:rebuildAllItem(container)
end
-------------------------- state method -------------------------------------------
function CSMatchBattleRecordPage:onEnter(container)
    self:registerPacket(container)
    m_nNowTab = m_tTabType.battleList
    NodeHelper:initScrollView(container,"mContent",3)
    self.refreshPage(container)
end
function CSMatchBattleRecordPage:onExit(container)
    self:removePacket(container)
end

----------------------------click method -------------------------------------------
----------------------------scroll View-------------------------------------------
-- 战斗信息列表
local m_tBattleListItem = {
    ccbiFile = "CrossServerMatchingBattleInformationContent.ccbi"
}
function m_tBattleListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        m_tBattleListItem.onRefreshItemView(container);
    elseif eventName == "onSeeBattle" then
        m_tBattleListItem.onSeeBattle(container);
    end     
end
function m_tBattleListItem.onRefreshItemView( container )
    local index = container:getItemData().mID
    local tBattleInfo = m_tBattleInfo[index]
    -- 文字部分
    local sMailObj = ""
    local sTitle = ""
    local str = ""
    local tMailParams = common:split(tBattleInfo.mailInfo,"_")
    if tBattleInfo.mailId==1 then
        sMailObj = MailContetnCfg[m_nWinMail]
    elseif tBattleInfo.mailId==2 then
        sMailObj = MailContetnCfg[m_nLoseMail]
    end
    sTitle = sMailObj.content
    for _,mailCont in pairs(tMailParams) do
        local vStr = "#v"..i.."#"
        sTitle = GameMaths:replaceStringWithCharacterAll(sTitle,vStr,mailCont)     
    end
    local tag = GameConfig.Tag.HtmlLable
    local size = CCSizeMake(GameConfig.LineWidth.MailContent, 200);
    local labelNode = container:getVarLabelBMFont("mText")
    str = FreeTypeConfig[56].content
    str = GameMaths:replaceStringWithCharacterAll(str,"#v1#",sTitle)
    if labelNode ~= nil then
        NodeHelper:addHtmlLable(labelNode, str ,tag, size)
    end
end
function m_tBattleListItem.onSeeBattle( container )
    local index = container:getItemData().mID
    local tBattleInfo = m_tBattleInfo[index]
    local msg = GSMatch_pb.GSMatchViewBattle()
    msg.mailId = tBattleInfo.mailId
    common:sendPacket(HP_pb.GS_MATCH_VIEW_BATTLE_C,msg)
end
-- 复仇信息列表
local m_tRevengeListItem = {
    ccbiFile = "CrossServerMatchingRevengeListContent"
}
function m_tRevengeListItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        m_tRevengeListItem.onRefreshItemView(container)
    elseif eventName == "onHand" then
        m_tRevengeListItem.onHand(container)
    elseif eventName == "onRevenge" then
        m_tRevengeListItem.onRevenge(container)
    end     
end
function m_tRevengeListItem.onRefreshItemView( container )
    local index = container:getItemData().mID
    local tRevengeInfo = m_tRevengeInfo[index]
    -- 头像
    local headPic = roleConfig[tRevengeInfo.roleId].icon
    local proPic = roleConfig[tRevengeInfo.prof%100].proIcon
    NodeHelper:setSpriteImage(container, {
        mHand           = headPic,
        mProfession     = proPic,
    })
    -- 其他信息
    local lb2Str = {
        mLv                 = "Lv." .. tRevengeInfo.playerLevel,
        mFightingNum        = tRevengeInfo.fightValue,
        mPlayerName         = tRevengeInfo.playerName,
        mServerName         = tRevengeInfo.serverName,
        mSurplusBloodNum    = bloodPercent.."%"
    }
    NodeHelper:setStringForLabel(container,lb2Str)
end
function m_tRevengeListItem.onHand(container)
    local index = container:getItemData().mID
    local sPlayerIdentify = m_tRevengeInfo[index].playerIdentify
    local msg = CsBattle_pb.OPCSBattleArrayInfo()
    msg.viewIdentify = sPlayerIdentify
    msg.version = 1
    common:sendPacket(HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,msg)
end
function m_tRevengeListItem.onRevenge( container )
    local index = container:getItemData().mID
    local sPlayerIdentify = m_tRevengeInfo[index].playerIdentify
    local msg = GSMatch_pb.GSMatchRevenge()
    msg.playerIdentify = sPlayerIdentify
    common:sendPacket(HP_pb.GS_MATCH_REVENGE_C,msg)
end
--
function CSMatchRankPage:rebuildAllItem(container)
    NodeHelper:clearAllItem(container)
    
    if m_nNowTab == m_tTabType.battleList then
        NodeHelper:buildScrollView(container,#m_tBattleInfo,m_tBattleListItem.ccbiFile,m_tBattleListItem.onFunction)
    elseif m_nNowTab == m_tTabType.revengeList then
        NodeHelper:buildScrollView(container,#m_tRevengeInfo,m_tRevengeListItem.ccbiFile,m_tRevengeListItem.onFunction)
    end
end
----------------------------packet method -------------------------------------------
function CSMatchBattleRecordPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.GS_MATCH_BATTLE_S then
        local msg = GSMatch_pb.GSMatchBattleRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setBattleResult(msg)
        PageManager.viewBattlePage(msg.battleInfo)
    elseif opcode == opcodes.GS_MATCH_VIEW_BATTLE_S then
        local msg = GSMatch_pb.GSMatchBattleListRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setBattleRecords(msg)
        self:refreshPage(container)
    elseif opcode == opcodes.GS_MATCH_REVENGE_S then
        local msg = GSMatch_pb.GSMatchBattleListRet()
        msg:ParseFromString(msgBuff)
        CSMatchData.setRevengeRecords(msg)
        self:refreshPage(container)
    end
end
function CSMatchBattleRecordPage:registerPacket( container )
    for key, opcode in opcodes do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function CSMatchBattleRecordPage:registerPacket( container )
    for key, opcode in opcodes do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------------------------- end  ----------------------------------------------------
