registerScriptPage("LeaveMessageDetailPage")
local thisPageName = "ArenaRecordPage"
local Mail_pb = require("Mail_pb")
local HP = require("HP_pb")
local Const_pb = require("Const_pb")
local Arena_pb = require "Arena_pb"
local NodeHelper = require("NodeHelper")
local MailDataHelper = require("Mail.MailDataHelper")
local ArenaData = require("Arena.ArenaData")
local UserInfo = require("PlayerInfo.UserInfo")
local opcodes =
{
    OPCODE_MAIL_SEE_ARENA_REPORT_C = HP.MAIL_SEE_ARENA_REPORT_C,
    OPCODE_MAIL_SEE_ARENA_REPORT_S = HP.MAIL_SEE_ARENA_REPORT_S,
    BUY_CHALLENGE_TIMES_S = HP_pb.BUY_CHALLENGE_TIMES_S
}

local option = {
    ccbiFile = "ArenaRecordPopUp.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onClose = "onClose",
        onPurchaseTimes = "purchaseTimes"
    },
    opcode = opcodes
}
local _surplusChallengeTimes = 0
local _arenaBuyTimesInitCost = ""
local _arenaAlreadyBuyTimes = nil
local _chanllengeContainer = nil
local _func = nil
local ArenaRecordPageBase = { }
local ArenaRecordItem = { }
local MailContetnCfg = ConfigManager.getMailContentCfg()
local challengeItemContainer = { }
local RoleConfig = { }
-----------------------------------------------------------------

function ArenaRecordItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        ArenaRecordItem.onRefreshItemView(container)
    elseif eventName == "onHand" then
        ArenaRecordItem.onHand(container)
    elseif eventName == "onFrame" then
        ArenaRecordItem.onFrame(container)
    elseif eventName == "onChallenge" then
        ArenaRecordItem.onChallenge(container)
    elseif eventName == "onLeaveMessage" then
        ArenaRecordItem.onLeaveMessage(container)
    end
end 

function ArenaRecordItem.onRefreshItemView(container)
    local index = container:getItemDate().mID
    --challengeItemContainer[index] = container
--    if challengeItemContainer[index] == nil then

--    end

    local mail = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", index)
    local itemInfo = {
        [1] = "",
        -- name
        [2] = 0,
        -- id
        [3] = 0,
        -- level
        [4] = 0,
        -- itemId
        [5] = 0,-- rebirthStage
    }
    local sTitle = ""
    if mail.mailId ~= 0 then
        local mailObj = MailContetnCfg[mail.mailId];
        if mailObj ~= nil then

            sTitle = mailObj.content

            local pSize = table.maxn(mail.params)
            for i = 1, 4, 1 do
                local vStr = "#v" .. i .. "#";
                local paramStr = common:checkStringLegal(mail.params[i])
                local mailTimeFormat = common:getLanguageString("@MailTimeFormat")
                if string.find(paramStr, "-") and not string.find(mailTimeFormat, "@") then
                    local day = Split(mail.params[i], " ")[1]
                    local time = Split(mail.params[i], " ")[2]
                    time = time or ""
                    local dayTime = Split(day, "-")
                    paramStr = TimeFormat(common:getLanguageString("@MailTimeFormat"), dayTime[1], dayTime[2], dayTime[3]) .. " " .. time
                end
                sTitle = GameMaths:replaceStringWithCharacterAll(sTitle, vStr, paramStr);
            end
            local nFristParam = -1;

            if mail.mailId == 9 then
                if #mail.params == 11 then
                    -- 2.9µÄÊý¾Ý
                    -- mail.params[9] = 0;
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 10 then
                if #mail.params == 8 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 11 then
                if #mail.params == 8 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 12 then
                if #mail.params == 10 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            end
            if mail.mailId ~= 9 then
                if mail.mailId == 10 or mail.mailId == 11 then
                    nFristParam = 2
                elseif mail.mailId == 12 then
                    nFristParam = 4
                else
                    nFristParam = #mail.params - 6
                end
            else
                nFristParam = 4
            end

            for i = 1, #itemInfo, 1 do
                itemInfo[i] = mail.params[nFristParam + i]
            end

        end
    else
        sTitle = common:stringAutoReturn(mail.title, REWRAD_LINE_COUNT);
    end

    local str = FreeTypeConfig[56].content
    str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle)

    labelNode = container:getVarLabelTTF("mArenaRecordTex")
    NodeHelper:setStringForLabel(container, { mArenaRecordTex = "" })
    local tag = GameConfig.Tag.HtmlLable
    local size = CCSizeMake(GameConfig.LineWidth.ArenaRecordContent, 200);

    if labelNode ~= nil then
        NodeHelper:addHtmlLable(labelNode, str, tag, size)
    end

    container:getVarLabelTTF("mLv"):setString(UserInfo.getOtherLevelStr(tonumber(itemInfo[5]), tonumber(itemInfo[3])))

    --[[    local headPic = RoleConfig[tonumber(itemInfo[4])]["icon"]
    NodeHelper:setSpriteImage(container, { mPic = headPic })]]
    mail.params[#mail.params] = mail.params[#mail.params] or 0
    local icon, bgIcon = common:getPlayeIcon(tonumber(itemInfo[4]), mail.params[#mail.params])
    NodeHelper:setSpriteImage(container, { mPic = icon, mPicBg = bgIcon });

    local lb2Str = {
        mChallengeBtnText = common:getLanguageString("@FightBack")
    }
    NodeHelper:setStringForLabel(container, lb2Str)
end


function ArenaRecordItem.onFrame(container)
    local index = container:getItemDate().mID
    local mail = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", index)
    local itemInfo = {
        [1] = "",
        -- name
        [2] = 0,
        -- id
        [3] = 0,
        -- level
        [4] = 0,
        -- itemId
        [5] = 0,-- rebirthStage
    }
    if mail.mailId == 9 then
        if #mail.params == 11 then
            -- 2.9µÄÊý¾Ý
            -- mail.params[9] = 0;
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 10 then
        if #mail.params == 8 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 11 then
        if #mail.params == 8 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 12 then
        if #mail.params == 10 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    end
    local nFristParam = -1;
    if mail.mailId ~= 9 then
        if mail.mailId == 10 or mail.mailId == 11 then
            nFristParam = 2
        elseif mail.mailId == 12 then
            nFristParam = 4
        else
            nFristParam = #mail.params - 6
        end
    else
        nFristParam = 4
    end

    for i = 1, #itemInfo, 1 do
        itemInfo[i] = mail.params[nFristParam + i]
    end

    PageManager.viewPlayerInfo(tonumber(itemInfo[2]), true)
end

function ArenaRecordItem.onHand(container)
    local index = container:getItemDate().mID
    local mail = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", index)
    local type1 = mail.type
    local count = #mail.params;
    local msg = Arena_pb.HPArenaReportReq()
    if mail.type == 5 and(mail.mailId == 9 or mail.mailId == 10 or mail.mailId == 11 or mail.mailId == 12) then
        count = count - 1
    end
    msg.reportId = tonumber(mail.params[count])
    common:sendPacket(HP.MAIL_SEE_ARENA_REPORT_C, msg)
end

function ArenaRecordItem.onChallenge(container)
    if _surplusChallengeTimes <= 0 then
        _chanllengeContainer = container
        local title = Language:getInstance():getString("@ArenaPurchaseTimesTitle")
        local message = Language:getInstance():getString("@DoChanllengeArenaPurchaseTimesMsg")
        local infoTab = { _arenaBuyTimesInitCost }
        PageManager.showConfirm(title, common:getGsubStr(infoTab, message), function(isSure)
            if isSure and UserInfo.isGoldEnough(_arenaBuyTimesInitCost) then
                ArenaRecordPageBase_BuyTimes();
            end
        end );
        return
    end

    local index = container:getItemDate().mID
    local mail = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", index)

    local itemInfo = {
        [1] = "",
        -- name
        [2] = 0,
        -- id
        [3] = 0,
        -- level
        [4] = 0,
        -- itemId
        [5] = 0,-- rebirthStage
    }
    local sTitle = ""
    if mail.mailId ~= 0 then
        local mailObj = MailContetnCfg[mail.mailId];
        if mailObj ~= nil then

            sTitle = mailObj.content

            local pSize = table.maxn(mail.params)
            for i = 1, 4, 1 do
                local vStr = "#v" .. i .. "#";
                local paramStr = common:checkStringLegal(mail.params[i])
                local mailTimeFormat = common:getLanguageString("@MailTimeFormat")
                if string.find(paramStr, "-") and not string.find(mailTimeFormat, "@") then
                    local day = Split(mail.params[i], " ")[1]
                    local time = Split(mail.params[i], " ")[2]
                    time = time or ""
                    local dayTime = Split(day, "-")
                    paramStr = TimeFormat(common:getLanguageString("@MailTimeFormat"), dayTime[1], dayTime[2], dayTime[3]) .. " " .. time
                end
                sTitle = GameMaths:replaceStringWithCharacterAll(sTitle, vStr, paramStr);
            end
            local nFristParam = -1;

            if mail.mailId == 9 then
                if #mail.params == 11 then
                    -- 2.9µÄÊý¾Ý
                    -- mail.params[9] = 0;
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 10 then
                if #mail.params == 8 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 11 then
                if #mail.params == 8 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            elseif mail.mailId == 12 then
                if #mail.params == 10 then
                    -- 2.9µÄÊý¾Ý
                    table.insert(mail.params, 0);
                end
            end
            if mail.mailId ~= 9 then
                if mail.mailId == 10 or mail.mailId == 11 then
                    nFristParam = 2
                elseif mail.mailId == 12 then
                    nFristParam = 4
                else
                    nFristParam = #mail.params - 6
                end
            else
                nFristParam = 4
            end

            for i = 1, #itemInfo, 1 do
                itemInfo[i] = mail.params[nFristParam + i]
            end

        end
    else
        sTitle = common:stringAutoReturn(mail.title, REWRAD_LINE_COUNT);
    end



    local msg = Arena_pb.HPChallengeDefender()
    msg.monsterId = 0
    msg.defendeRank = 0

    -- 11==>4   9==>6  10==>4   12==>6  2==>4

    if mail.mailId == 11 then
        if mail.params and mail.params[4] then
            msg.playerId = tonumber(mail.params[4])
        else
            return
        end
    elseif mail.mailId == 9 then
        if mail.params and mail.params[6] then
            msg.playerId = tonumber(mail.params[6])
        else
            return
        end
    elseif mail.mailId == 10 then
        if mail.params and mail.params[4] then
            msg.playerId = tonumber(mail.params[4])
        else
            return
        end
    elseif mail.mailId == 12 then
        if mail.params and mail.params[6] then
            msg.playerId = tonumber(mail.params[6])
        else
            return
        end
    end

    pb_data = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.CHALLENGE_DEFENDER_C, pb_data, #pb_data, true)

    -- PageManager.showFightPage("BattlePage")
    -- resetMenu("mBattlePageBtn", true)
    ArenaRecordPageBase:onClose()

end

function ArenaRecordItem.onLeaveMessage(container)
    local index = container:getItemDate().mID
    local mail = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", index)
    local itemInfo = {
        [1] = "",
        -- name
        [2] = 0,
        -- id
        [3] = 0,
        -- level
        [4] = 0,
        -- itemId
        [5] = 0,-- rebirthStage
    }
    if mail.mailId == 9 then
        if #mail.params == 11 then
            -- 2.9µÄÊý¾Ý
            -- mail.params[9] = 0;
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 10 then
        if #mail.params == 8 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 11 then
        if #mail.params == 8 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    elseif mail.mailId == 12 then
        if #mail.params == 10 then
            -- 2.9µÄÊý¾Ý
            table.insert(mail.params, 0);
        end
    end
    local nFristParam = -1;
    if mail.mailId ~= 9 then
        if mail.mailId == 10 or mail.mailId == 11 then
            nFristParam = 2
        elseif mail.mailId == 12 then
            nFristParam = 4
        else
            nFristParam = #mail.params - 6
        end
    else
        nFristParam = 4
    end

    for i = 1, #itemInfo, 1 do
        itemInfo[i] = mail.params[nFristParam + i]
    end

    LeaveMsgDetail_setPlayId(tonumber(itemInfo[2]), itemInfo[1])
    PageManager.pushPage("LeaveMessageDetailPage")

end

function ArenaRecordPageBase:onEnter(container)

    local messageText = container:getVarLabelTTF("mMessage")
    messageText:setString("")

    container:registerMessage(MSG_MAINFRAME_REFRESH)
    RoleConfig = ConfigManager.getRoleCfg()
    NodeHelper:initScrollView(container, "mContent", 5)
    challengeItemContainer = {}
    self:initUi(container)
    self:registerPacket(container)
    self:getPageInfo(container)

end

function ArenaRecordPageBase:initUi(container)
    local lb2Str = {
        mRemainingChallengesNum = common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. _surplusChallengeTimes
    }
    NodeHelper:setStringForLabel(container, lb2Str)
end

function ArenaRecordPageBase:getPageInfo(container)
    if MailDataHelper:getVariableByKey("mailAreanAll") ~= nil and #MailDataHelper:getVariableByKey("mailAreanAll") ~= 0 then
        self:rebuildAllItem(container)
    end

    local msg = Mail_pb.OPMailInfo()

    if MailDataHelper:getVariableByKey("lastMail") ~= nil and MailDataHelper:getVariableByKey("lastMail").id ~= nil then
        msg.version = MailDataHelper:getVariableByKey("lastMail").id
    else
        msg.version = 0;
    end

    local pb_data = msg:SerializeToString()
    container:sendPakcet(HP.MAIL_INFO_C, pb_data, #pb_data, true)
end

---------------------------------------------------
function ArenaRecordPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.OPCODE_MAIL_SEE_ARENA_REPORT_S then
        -- 邮件查看竞技场战报
        local msg = Arena_pb.HPArenaChallengeReportRes()
        msg:ParseFromString(msgBuff)
        common:arenaViewBattle(msg.battleInfo)
    elseif opcode == HP_pb.BUY_CHALLENGE_TIMES_S then
        local msg = Arena_pb.HPBuyChallengeTimesRet()
        msg:ParseFromString(msgBuff)
        self:buyTimesRet(container, msg)
        if _chanllengeContainer ~= nil then
            ArenaRecordItem.onChallenge(_chanllengeContainer)
            _chanllengeContainer = nil
        end
    end
end

function ArenaRecordPageBase:buyTimesRet(container, msg)
    _surplusChallengeTimes = msg.surplusChallengeTimes
    container:getVarLabelTTF("mRemainingChallengesNum"):setString(common:getLanguageString("@TodayTheNumberOfRemainingChallenges") .. _surplusChallengeTimes)
    _arenaBuyTimesInitCost = msg.nextBuyPrice
    _arenaAlreadyBuyTimes = msg.alreadyBuyTimes
end	

function ArenaRecordPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function ArenaRecordPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function ArenaRecordPageBase:onExecute(container)
    --TODO反击倒计时更新
--    for k, v in pairs(challengeItemContainer) do
--        if v then
--            if TimeCalculator:getInstance():hasKey("challengeCountDownKey") then
--                local timer = TimeCalculator:getInstance():getTimeLeft("challengeCountDownKey")
--                if timer > 0 then
--                    NodeHelper:setStringForLabel(v, { mCountDownText = tonumber(timer) .. "s" })
--                    NodeHelper:setNodesVisible(v, { mCountDownText = true, mChallengeBtnNode = false })
--                else
--                    NodeHelper:setNodesVisible(v, { mCountDownText = false, mChallengeBtnNode = true })
--                end
--            else
--                NodeHelper:setNodesVisible(v, { mCountDownText = false, mChallengeBtnNode = true })
--            end
--        end
--    end
end

function ArenaRecordPageBase:onExit(container)
    challengeItemContainer = { }
    NodeHelper:deleteScrollView(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container:removePacket(HP_pb.REPLACE_DEFENDER_LIST_S)
    self:removePacket(container)
    onUnload(thisPageName, container);

    if _func then
        _func()
        _func = nil
    end

end

function ArenaRecordPageBase:onHelp(container)

end

function ArenaRecordPageBase:purchaseTimes(container)
    ArenaRecordPageBase_BuyTimes()
end

function ArenaRecordPageBase:onClose(container)
    ArenaData.notifyArenaRecordCancelRedPoint()
    -- PageManager.refreshPage("ArenaRecordPageRedPoint")
    local mailAreanAll = MailDataHelper:getVariableByKey("mailAreanAll")
    if mailAreanAll ~= nil and #mailAreanAll ~= 0 then
        local maxMailId = MailDataHelper:getVariableByKeyAndIndex("mailAreanAll", table.maxn(mailAreanAll)).id
        local msg = Arena_pb.HPRecordMaxArenaMailId()
        msg.maxMailId = maxMailId
        common:sendPacket(HP_pb.SET_ARENA_RECORD_C, msg, false)
    end


    PageManager.popPage(thisPageName)
end

function ArenaRecordPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:rebuildAllItem(container)
        end
    end
end

function ArenaRecordPageBase:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ArenaRecordPageBase:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end

function ArenaRecordPageBase:buildItem(container)
    if (MailDataHelper:getVariableByKey("mailAreanAll") == nil) then
        return;
    end
    local maxSize = table.maxn(MailDataHelper:getVariableByKey("mailAreanAll"));
    NodeHelper:buildScrollViewWithCache(container, maxSize, "ArenaRecordContent.ccbi", ArenaRecordItem.onFunction);
end

local function toPurchaseTimes(boo, times)
    if boo then
        local msg = Arena_pb.HPBuyChallengeTimes()
        msg.times = times
        pb_data = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.BUY_CHALLENGE_TIMES_C, pb_data, #pb_data, true)
    end
end

function ArenaRecordPageBase_BuyTimes()
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


function ArenaRecordPageBase_setData(data)
    _surplusChallengeTimes = data.surplusChallengeTimes
    _arenaBuyTimesInitCost = data.arenaBuyTimesInitCost
    _arenaAlreadyBuyTimes = data.arenaAlreadyBuyTimes
    _func = data.func or nil
end
-----------------------------------------------------------------
local CommonPage = require("CommonPage")
ArenaRecordPage = CommonPage.newSub(ArenaRecordPageBase, thisPageName, option)