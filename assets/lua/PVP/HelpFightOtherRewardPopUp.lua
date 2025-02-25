
local thisPageName = "HelpFightOtherRewardPopUp"
local Mail_pb = require("Mail_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Arena_pb = require "Arena_pb"
local NodeHelper = require("NodeHelper")
local MailDataHelper = require("Mail.MailDataHelper")
local ArenaData = require("Arena.ArenaData")
local UserInfo = require("PlayerInfo.UserInfo")
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local EighteenPrinces_pb = require("EighteenPrinces_pb")
local rewardCfg = ConfigManager.getHelpFightRewardCfg()
local opcodes =
{
    EIGHTEENPRINCES_HELP_HISTORY_S = HP_pb.EIGHTEENPRINCES_HELP_HISTORY_S,
    EIGHTEENPRINCES_HELP_REWARD_S = HP_pb.EIGHTEENPRINCES_HELP_REWARD_S,
    EIGHTEENPRINCES_HELP_ONEKEYAWARD_S = HP_pb.EIGHTEENPRINCES_HELP_ONEKEYAWARD_S,
}

local option = {
    ccbiFile = "HelpFightOtherRewardPopUp.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onClose = "onClose",
        onPurchaseTimes = "purchaseTimes",
        onAllReceive = "onAllReceive",
    },
    opcode = opcodes
}
local _surplusChallengeTimes = 0
local _arenaBuyTimesInitCost = ""
local _arenaAlreadyBuyTimes = nil
local _chanllengeContainer = nil
local _func = nil
local HelpFightOtherRewardPopUp = { }
local ArenaRecordItem = { }
local MailContetnCfg = ConfigManager.getMailContentCfg()
local RoleConfig = { }
local myHistoryData = nil
local itemList = nil
-----------------------------------------------------------------

function ArenaRecordItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ArenaRecordItem.onRefreshItemView(container)
    end
end

function ArenaRecordItem:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local index = self.id
    if myHistoryData and myHistoryData.historyInfos and myHistoryData.historyInfos[index] then
        local useTime = os.date("!*t", tonumber(myHistoryData.historyInfos[index].helpTime) - common:getServerOffset_UTCTime())
        local libStr = {
            mlv =   UserInfo.getOtherLevelStr(nil,myHistoryData.historyInfos[index].level),
            mRewardNum = "",
        }
        local year =  string.format("%02d",tonumber(useTime.year))
        local month =  string.format("%02d",tonumber(useTime.month))
        local day =  string.format("%02d",tonumber(useTime.day))
        local hour =  string.format("%02d",tonumber(useTime.hour))
        local min =  string.format("%02d",tonumber(useTime.min))
        local  mArenaRecordTex =  common:fill(FreeTypeConfig[999].content,year.."-"..month.."-"..day .." "..hour ..":"..min, myHistoryData.historyInfos[index].name)
        --common:fillNormalHtmlStr(999,useTime.year.."-"..useTime.month.."-"..useTime.day .." "..useTime.hour ..":".. useTime.min, myHistoryData.historyInfos[index].name)  --common:getLanguageString("@Elighteenbtncontent2")

        local tag = GameConfig.Tag.HtmlLable;
        local nameNode = container:getVarNode("mArenaRecordTex");
        NodeHelper:addHtmlLable(nameNode, mArenaRecordTex, tag,CCSizeMake(300, 100));
        NodeHelper:setStringForLabel(container,libStr)
        local roleConfig = ConfigManager.getRoleCfg()
        local  icon ,frame = common:getPlayeIcon(myHistoryData.historyInfos[index].prof,myHistoryData.historyInfos[index].headIcon)
        NodeHelper:setSpriteImage(container,{mPic = icon},{mPic = 0.77})
        if myHistoryData.historyInfos[index].headIcon == 0 then
            NodeHelper:setQualityFrames(container, {mHand = GameConfig.QualityImage[1]});
        else
            if myHistoryData.historyInfos[index].headIcon >= 1000 then
                NodeHelper:setSpriteImage(container, {mHand = GameConfig.QualityImage[1],mFrameShade =frame },{mHand = 1,mFrameShade =0.77})
            else
                NodeHelper:setQualityFrames(container, {mHand = roleConfig[myHistoryData.historyInfos[index].headIcon].quality});
            end
        end
        local btnLabel = container:getVarLabelBMFont("mChallengeBtnText")
        local menuItemImage = container:getVarMenuItemImage("mBtn")
        if myHistoryData.historyInfos[index].isGet == 1 then
            NodeHelper:setNodeIsGray(container, { mRewardNode = true })
            btnLabel:setString(common:getLanguageString("@MissionDay7_ReceivedHave"))
            menuItemImage:setEnabled(false)
        else
            NodeHelper:setNodeIsGray(container, { mRewardNode = false })
            btnLabel:setString(common:getLanguageString("@Receive"))
            menuItemImage:setEnabled(true)
        end

        local lb2Str,quaMap,picMap = {},{},{}

        local resCfg = rewardCfg[myHistoryData.historyInfos[index].helpCount].rewards
        if not resCfg then return end
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(resCfg.type, resCfg.itemId, resCfg.count);
        local str = resInfo.name
        lb2Str["mRewardNum"] = resCfg.count
        quaMap["mRewardFeet"] = resInfo.quality
        picMap["mRewardPic"] = resInfo.icon
        NodeHelper:setStringForLabel(container, lb2Str)
        NodeHelper:setQualityFrames(container, quaMap)
        NodeHelper:setSpriteImage(container, picMap)
    end
end


function ArenaRecordItem:onRewardFeet01(container)
    local contentId = self.id
    HelpFightOtherRewardPopUp:onFeetById(container,contentId)
end

function HelpFightOtherRewardPopUp:onFeetById(container,index)
    if myHistoryData and myHistoryData.historyInfos and myHistoryData.historyInfos[index] then
        local resCfg = rewardCfg[myHistoryData.historyInfos[index].helpCount].rewards
        if resCfg then
            GameUtil:showTip(container:getVarNode("mRewardFeet"), resCfg)
        end
    end
end

function ArenaRecordItem:onHand(container)
--[[    local index = self.id
    if myHistoryData and myHistoryData.historyInfos and myHistoryData.historyInfos[index] then
        PageManager.viewPlayerInfo(myHistoryData.historyInfos[index], true)
    end]]
end

function ArenaRecordItem:onRefreshAllItem()
    for i = 1, #itemList do
        local item = itemList[i];
        if item then
            local item = itemList[i];
            if item then
                item.cls:onRefreshItem(item.node:getCCBFileNode());
            end
        end
    end
end

function ArenaRecordItem:onRefreshItem(container)
    if container == nil then
        return
    end
    local index = self.id
    local libStr = {}
    local mapIndex = 18 - index + 1
    libStr.mArenaRecordTex = "测试"
    NodeHelper:setStringForLabel(container,libStr)
end

function ArenaRecordItem:onReward(container)
    local index = self.id
    HelpFightDataManager:sendEighteenPrincesHelpRewardReq(myHistoryData.historyInfos[index].historyId)
end

function HelpFightOtherRewardPopUp:onEnter(container)

    local messageText = container:getVarLabelTTF("mMessage")
    messageText:setString("")

    container:registerMessage(MSG_MAINFRAME_REFRESH)
    RoleConfig = ConfigManager.getRoleCfg()
    container.mScrollView  = container:getVarScrollView("mContent")
    self:initData(container)
    self:initUi(container)
    self:registerPacket(container)
    --self:rebuildAllItem(container)
    HelpFightDataManager:sendEighteenPrincesHistoryReq()
end

function HelpFightOtherRewardPopUp:initData(container)
    myHistoryData = nil
    itemList = nil
    _surplusChallengeTimes = 0
end

function HelpFightOtherRewardPopUp:initUi(container)
    local lb2Str = {
        mRemainingChallengesNum = common:getLanguageString("@Eighteenbtncontent1",_surplusChallengeTimes),
        mTitle = common:getLanguageString("@Eighteentitle2")
    }
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setNodesVisible(container,{mAddNode = false,mAllReceiveNode = false})
end

function HelpFightOtherRewardPopUp:refreshUI(container)
    _surplusChallengeTimes = myHistoryData.todayCount or 0
    local lb2Str = {
        mRemainingChallengesNum = common:getLanguageString("@Eighteenbtncontent1",_surplusChallengeTimes),
    }
    NodeHelper:setStringForLabel(container, lb2Str)
end



---------------------------------------------------
function HelpFightOtherRewardPopUp:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.EIGHTEENPRINCES_HELP_HISTORY_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesHelpHistoryRet()
        msg:ParseFromString(msgBuff)
        myHistoryData =  HelpFightDataManager:EighteenPrincesHistoryFun(msg)
        self:refreshUI(container)
        self:rebuildAllItem(container)
    elseif  opcode == opcodes.EIGHTEENPRINCES_HELP_REWARD_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesHelpRewardRet()
        msg:ParseFromString(msgBuff)
        if msg.result == 1 then
            myHistoryData =  HelpFightDataManager:EighteenPrincesHelpRewardFun(msg)
            self:rebuildAllItem(container)
        end
    elseif  opcode == opcodes.EIGHTEENPRINCES_HELP_ONEKEYAWARD_S then
        local msg = EighteenPrinces_pb.HPEighteenPrincesHelpRewardRet()
        msg:ParseFromString(msgBuff)
        if msg.result == 1 then
            myHistoryData =  HelpFightDataManager:EighteenPrincesHelpRewardFun(msg)
            self:rebuildAllItem(container)
        end
    end
end

function HelpFightOtherRewardPopUp:buyTimesRet(container, msg)
    _surplusChallengeTimes = msg.surplusChallengeTimes
    container:getVarLabelTTF("mRemainingChallengesNum"):setString(common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. _surplusChallengeTimes)
    _arenaBuyTimesInitCost = msg.nextBuyPrice
    _arenaAlreadyBuyTimes = msg.alreadyBuyTimes
end

function HelpFightOtherRewardPopUp:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function HelpFightOtherRewardPopUp:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function HelpFightOtherRewardPopUp:onExecute(container)

end

function HelpFightOtherRewardPopUp:onExit(container)
    HelpFightDataManager.isNotice = self:checkRedPoint(container)
    myHistoryData = nil
    itemList = nil
    container.mScrollView:removeAllCell()
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removePacket(HP_pb.REPLACE_DEFENDER_LIST_S)
    self:removePacket(container)
    onUnload(thisPageName, container);

    if _func then
        _func()
        _func = nil
    end

end

function HelpFightOtherRewardPopUp:onHelp(container)

end

function HelpFightOtherRewardPopUp:purchaseTimes(container)
    --HelpFightOtherRewardPopUp_BuyTimes()
end


function HelpFightOtherRewardPopUp:onAllReceive(container)
    HelpFightDataManager:sendEighteenPrincesHelpAllRewardReq()
end

function HelpFightOtherRewardPopUp:checkRedPoint()
    if  myHistoryData then
        local isRed = false
        for i = 1, #myHistoryData.historyInfos do
            if myHistoryData.historyInfos[i].isGet == 0 then
                isRed = true
            end
        end
        return isRed
    end
    return HelpFightDataManager.isNotice
end

function HelpFightOtherRewardPopUp:onClose(container)
    PageManager.popPage(thisPageName)
end

function HelpFightOtherRewardPopUp:onReceiveMessage(container)
--[[    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefresHP_pbage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:rebuildAllItem(container)
        end
    end]]
end

function HelpFightOtherRewardPopUp:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function HelpFightOtherRewardPopUp:clearAllItem(container)
    container.mScrollView:removeAllCell()
end

function HelpFightOtherRewardPopUp:buildItem(container)
    myHistoryData = myHistoryData or {}
    myHistoryData.historyInfos =myHistoryData.historyInfos or {}
    local maxSize = #myHistoryData.historyInfos
    if maxSize == 0 then
        local messageText = container:getVarLabelTTF("mMessage")
        messageText:setString(common:getLanguageString("@Eighteenbtncontent9"))
        NodeHelper:setNodesVisible(container,{mAllReceiveNode = false })
    else
        NodeHelper:setNodesVisible(container,{mAllReceiveNode = true })
        local messageText = container:getVarLabelTTF("mMessage")
        messageText:setString("")
        itemList =  NodeHelper:buildCellScrollView(container.mScrollView, maxSize, "HelpFightOtherRewardContent.ccbi", ArenaRecordItem);
    end

end

local function toPurchaseTimes(boo, times)
    if boo then
        local msg = Arena_pb.HP_pbBuyChallengeTimes()
        msg.times = times
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.BUY_CHALLENGE_TIMES_C, pb_data, #pb_data, true)
    end
end

function HelpFightOtherRewardPopUp_BuyTimes()
    -- 根据vip等级,判断剩余购买次数
    UserInfo.syncPlayerInfo()
    local costCfg = ConfigManager.getBuyCostCfg()
    local vipLevel = UserInfo.playerInfo.vipLevel

    local leftTime = 999
    local title = common:getLanguageString("@BuyTimesTitle")
    local message = common:getLanguageString("@BuyTimesArenaMsg")
    local buyedTimes = _arenaAlreadyBuyTimes or 0

    PageManager.showCountTimesPage(title, message, leftTime,
            function(times)
                local totalPrice = 0

                for i = buyedTimes + 1, buyedTimes + times do
                    local index = i;
                    if i > #costCfg then
                        index = #costCfg
                    end

                    local costInfo = costCfg[index]
                    if costInfo ~= nil then
                        totalPrice = totalPrice + costInfo.arenaTimes
                    end
                end

                return totalPrice
            end
    , Const_pb.MONEY_GOLD, toPurchaseTimes)
end


function HelpFightOtherRewardPopUp_setData(data)
    _surplusChallengeTimes = data.surplusChallengeTimes
    _arenaBuyTimesInitCost = data.arenaBuyTimesInitCost
    _arenaAlreadyBuyTimes = data.arenaAlreadyBuyTimes
    _func = data.func or nil
end
-----------------------------------------------------------------
local CommonPage = require("CommonPage")
HelpFightOtherRewardPopUp = CommonPage.newSub(HelpFightOtherRewardPopUp, thisPageName, option)