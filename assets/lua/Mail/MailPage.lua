----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
-- require "ExploreEnergyCore_pb"
local thisPageName = "MailPage"
local HP = require("HP_pb")
local NodeHelper = require("NodeHelper")
local common = require("common")
local MailDataHelper = require("Mail.MailDataHelper")
------------local variable for system global api--------------------------------------
local tostring = tostring;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------
local MailPageBase = {};

local opcodes =
    {
        OPCODE_MAIL_INFO_C = HP.MAIL_INFO_C,
        OPCODE_MAIL_GET_C = HP.MAIL_GET_C,
        OPCODE_MAIL_GET_S = HP.MAIL_GET_S,
        OPCODE_MAIL_SEE_ARENA_REPORT_C = HP.MAIL_SEE_ARENA_REPORT_C,
        OPCODE_MAIL_SEE_ARENA_REPORT_S = HP.MAIL_SEE_ARENA_REPORT_S,
        MAIL_SEE_MULTIELITE_BATTLE_REPORT_S = HP.MAIL_SEE_MULTIELITE_BATTLE_REPORT_S,
        APPROVAL_REFUSED_OPER_S = HP.APPROVAL_REFUSED_OPER_S,
        PLAYER_AWARD_S=HP_pb.PLAYER_AWARD_S
    }

local option = {
    ccbiFile = "MailPopUp.ccbi",
    handlerMap =
    {
        onClose = "onClose",
        onKeyReceive = "onRewardAll",
        onAllDelete = "onDeleteAll",
        onOrdinary = "onOrdinary",
        onSystem = "onSystem",
        onReward = "onReward",
        onView = "onView"
    },
    opcode = opcodes
};

local MailItem = {
    ccbiFile = "MailContent.ccbi"
}

local PageTab = {
    CommonMail = 1,
    SystemMail = 2
}

local PageType = PageTab.CommonMail

--[[
MailInfo =
{
lastMail = {},
mails ={},
mailAreanAll = {},
kakaoMail = {},	--kakao好友发来的礼物列表
}
--]]
MailInfo = {}
MailInfo.kakaoMail = {}
MailInfo.FBMail = {}
local REWRAD_LINE_COUNT = 25;

local mainContainer = nil;
local MyFBFriendInfo = {}
local MailContetnCfg = ConfigManager.getMailContentCfg();
local MailContent = nil

local ZHANBAO_MAILID = {
    MAIN_TYPE = 5,
    SUB_TYPE = 6,
    MULTIELITE_WIN_TYPE = 27,
    MULTIELITE_LOSE_TYPE = 28,
}

local GUILD_MAIL = {
    [106] = true,
    [107] = true,
    [108] = true,
    [109] = true,
    [110] = true,
    [111] = true,
    [112] = true,
    applyMailId = 106,
}

local libPlatformListener = {}
local isReceiveGift = false
local isReceiveMailDone = true -- 控制领取每封邮件，只有在领取成功后才能领取下一封，防止快速点击领取造成服务器拒绝处理
local isReceiveAllKakoGift = false
-- 注销登陆，刷新信息-------------------------
function RESETINFO_MAILS()
    --[[
    MailInfo = {}
    MailInfo.mails = {}
    MailInfo.lastMail = {}
    MailInfo.mailAreanAll = {}
    MailInfo.kakaoMail = {}
    requestId = 0
    mailInvalidateList = {}
    --]]
    MailInfo.kakaoMail = {}
    MailInfo.FBMail = {}
    MailDataHelper:ResetMailData()
end
--------------------------------------------
-- 平台回调 接收kakao好友礼物
function libPlatformListener:P2G_KR_RECEIVE_GIFT(listener)
    isReceiveMailDone = true
    if not listener then return end
    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
    local result = strTable.result
    
    if result and MailItem.giftId then
        for k, v in ipairs(MailInfo.kakaoMail) do
            if v.id == MailItem.giftId then
                MailInfo.kakaoMail[k] = nil
                break
            end
        end
        local values = {}
        table.foreach(MailInfo.kakaoMail, function(k, v)values[#values + 1] = v end)
        MailInfo.kakaoMail = values
    else
        end
    MailPageBase:rebuildAllItem(MailPageBase.container)
    MailPageBase:refreshPage(MailPageBase.container)
    MailPageBase.giftId = nil
    if isReceiveAllKakoGift then
        -- MessageBoxPage:Msg_Box('------mails count : ' .. #MailInfo.kakaoMail)
        isReceiveAllKakoGift = false
        if #MailInfo.kakaoMail > 0 then
            MailPageBase:receiveAllKakoGift()
        else
            isReceiveAllKakoGift = false
        end
    end
end
-- 平台回调 获取kakao好友礼物列表
function libPlatformListener:P2G_KR_GET_GIFT_LIST(listener)
    if not listener then return end
    
    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
    local giftList = strTable.giftlist
    -- 排除iOS平台错误
    if Golb_Platform_Info.is_entermate_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
        MailInfo.kakaoMail = giftList
    else
        MailInfo.kakaoMail = json.decode(giftList)
    end
    MailPageBase:rebuildAllItem(MailPageBase.container)
    MailPageBase:refreshPage(MailPageBase.container)

end
function libPlatformListener:P2G_GET_ALL_REQUEST(listener)
    if not listener then
        return
    end
    local msg = listener:getResultStr()
    local FBMailAll = {}
    MailInfo.FBMail = {}
    if msg ~= "" then
        -- MailInfo.FBMail = json.decode(msg)
        FBMailAll = json.decode(msg)
        local deleteinfo = {}
        for i = 1, #FBMailAll do
            if #MailInfo.FBMail == 0 then
                local str = Split(FBMailAll[i].data, ",")
                if #str == 2 then
                    MailInfo.FBMail[1] = FBMailAll[i]
                end
            
            elseif #MailInfo.FBMail > 0 then
                local datainfo = FBMailAll[i]
                local find = false
                for k = 1, #MailInfo.FBMail do
                    if datainfo.data == MailInfo.FBMail[k].data then
                        deleteinfo[#deleteinfo + 1] = FBMailAll[i]
                        find = true
                    end
                end
                if find == false then
                    local str = Split(FBMailAll[i].data, ",")
                    if #str == 2 then
                        MailInfo.FBMail[#MailInfo.FBMail + 1] = FBMailAll[i]
                    elseif str ~= "" then
                        deleteinfo[#deleteinfo + 1] = FBMailAll[i]
                    end
                
                end
            end
        end
        
        for i = 1, #deleteinfo do
            local strtable = {
                requestid = deleteinfo[i].requestId,
            }
            local JsMsg = cjson.encode(strtable)
            libPlatformManager:getPlatform():sendMessageG2P("G2P_DEL_SAME_REQUEST", JsMsg)
        end
    
    end
    
    MailPageBase:rebuildAllItem(MailPageBase.container)
    MailPageBase:refreshPage(MailPageBase.container)
end
function libPlatformListener:P2G_DELETE_REQUEST(listener)
    local msg = listener:getResultStr()
    if msg ~= "faild" then
        -- 删除成功 msg为平台传递来的 requestid  暂时不用这个处理逻辑。重新请求下列表
        libPlatformManager:getPlatform():sendMessageG2P("G2P_GET_ALL_REQUEST", "G2P_GET_ALL_REQUEST")
    end
    isReceiveMailDone = true
end
function libPlatformListener:P2G_Friend_List(listener)
    local msg = listener:getResultStr()
    CCLuaLog("onReceiveCommonMessage =====mailpage======= P1:Tag:")
    MyFBFriendInfo = {}
    MyFBFriendInfo = json.decode(msg)
end
--------------------------------------------
------------------创建content回掉----------------------
function MailItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        MailItem.onRefreshItemView(container);
    elseif eventName == "onReward" or eventName == "onCancel" then
        MailItem.onReward(container);
    elseif eventName == "onView" then
        MailItem.onView(container);
    elseif eventName == "onDetial" then
        MailItem.onDetial(container);
    end
end

--------------------查看战报轮具体信息，进入MailBattlePage--------------------------
function MailItem:onView(container, index)
    local index = index or self.id
    local Mail_pb = require("Mail_pb")
    local Arena_pb = require "Arena_pb"
    local mail = nil
    if PageType == PageTab.CommonMail then
        mail = MailDataHelper:getVariableByKeyAndIndex("commonMails", index);
    else
        mail = MailDataHelper:getVariableByKeyAndIndex("systemMails", index);
    end
    
    -- local mail = MailDataHelper:getVariableByKeyAndIndex("mails",index);
    if mail.type == Mail_pb.ARENA or (mail.type == Mail_pb.ARENA_ALL and mail.mailId == 10) then
        --
        -- PageManager.changePage("ArenaPage")
        --local count = #mail.params;
        --if mail.type == 5 and (mail.mailId == 9 or mail.mailId == 10 or mail.mailId == 11 or mail.mailId == 12) then
        --    count = count - 1
        --end
        --local msg = Arena_pb.HPArenaReportReq()
        --msg.reportId = tonumber(mail.params[count])
        --common:sendPacket(HP.MAIL_SEE_ARENA_REPORT_C, msg)
        return
    end
    if mail.mailId == ZHANBAO_MAILID.MAIN_TYPE or mail.mailId == ZHANBAO_MAILID.SUB_TYPE then
        --local maxParams = table.maxn(mail.params);
        --MailDataHelper:addOrSetVariableByKey("requestId", mail.params[maxParams])
        --registerScriptPage("MailBattlePage")
        --PageManager.pushPage("MailBattlePage")
        return
    end
    if mail.mailId == GUILD_MAIL.applyMailId then
        -- 会长批准玩家加入公会
        local alliance = require('Alliance_pb')
        local msg = alliance.HPApprovalRefusedOperC()
        local params = json.decode(mail.passthroughParams)
        msg.allianceId = params.allianceId
        msg.playerId = params.id
        msg.state = 1
        -- 0.拒绝 1.批准
        msg.emailId = mail.id
        
        common:sendPacket(HP.APPROVAL_REFUSED_OPER_C, msg)
        return
    end
end
function MailItem:onDetial(container)
    
    local index = self.id
    local mail
    if index > #MailDataHelper:getVariableByKey("mails") then
        if Golb_Platform_Info.is_r2_platform then
            mail = MailInfo.FBMail[index - #MailInfo.FBMail];
        else
            mail = MailInfo.kakaoMail[index - #MailInfo.kakaoMail];
        end
    
    elseif PageType == PageTab.CommonMail then
        mail = MailDataHelper:getVariableByKeyAndIndex("commonMails", index);
    else
        mail = MailDataHelper:getVariableByKeyAndIndex("systemMails", index);
    end
    local rewardStr, Num, info = MailItem.getRewardStr(mail.item);
    local items = {
        type = tonumber(info.itemType),
        itemId = tonumber(info.itemId),
        count = tonumber(info.count)
    };
    
    GameUtil:showTip(container:getVarNode("onDetial"), items)
end
function MailItem:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local index = self.id
    local mail
    if index > #MailDataHelper:getVariableByKey("mails") then
        if Golb_Platform_Info.is_r2_platform then
            mail = MailInfo.FBMail[index - #MailInfo.FBMail];
        else
            mail = MailInfo.kakaoMail[index - #MailInfo.kakaoMail];
        end
    
    elseif PageType == PageTab.CommonMail then
        mail = MailDataHelper:getVariableByKeyAndIndex("commonMails", index);
    else
        mail = MailDataHelper:getVariableByKeyAndIndex("systemMails", index);
    end
    
    
    MailItem.changeContentType(container, mail, index);

end
local function spriteTime(paramStr)
    local strArray = splitStr(paramStr, ":")
    if #strArray == 3 and string.match(string.sub(paramStr, -3), ":%d") then
        paramStr = string.sub(paramStr, 1, #paramStr - 3)
    end
    return paramStr
end
local function changeTimestampToDateStr(timestamp)
    local loginDaySever = --os.date("%Y-%m-%d", timestamp)
        os.date("%x", timestamp)
    return loginDaySever
end
----------根据邮件类型，刷新content-------------
function MailItem.changeContentType(container, mail, index)
    -- local index = container:getItemDate().mID
    local Mail_pb = require("Mail_pb")
    local createDate = nil
    if mail then
        createDate = mail.createTime
    
    end
    createDate = changeTimestampToDateStr(createDate)
    
    
    if index > #MailDataHelper.mails then
        -- kakao好友发来的礼物
        if Golb_Platform_Info.is_r2_platform then
            local fbinfo = MailInfo.FBMail[index - #MailDataHelper.mails]
            if not fbinfo then return end
            
            local visibleMap =
                {
                    mMailPrizeNode = true,
                    mMailReportsNode = false,
                    mMailSystemNode = false,
                    mMailGVGNode = false,
                    mSendTime = false,
                }
            local str = "";
            local labelNode = container:getVarLabelTTF("mMaillPrizeExplain")
            local datainfo = Split(fbinfo.data, ",")
            local strText = "";
            if datainfo[1] == "sendRequst" then
                str = common:getLanguageString('@R2FBShareReceiveQuest', fbinfo.fromUserFbName)
                strText = common:getLanguageString('@R2FBShareReceiveQuestbtn')
            elseif datainfo[1] == "askRequst" then
                str = common:getLanguageString('@R2FBShareSendQuest', fbinfo.fromUserFbName)
                strText = common:getLanguageString('@R2FBShareSendQuestBtn')
            end
            
            local lb2Str = {
                mMailContent_reward = strText
            }
            
            NodeHelper:setStringForLabel(container, lb2Str)
            NodeHelper:setNodesVisible(container, visibleMap)
            
            
            local fbname = fbinfo.fromUserFbName
            
            
            
            local tag = GameConfig.Tag.HtmlLable
            local size = CCSizeMake(GameConfig.LineWidth.MailContent, 150);
            if labelNode ~= nil then
                NodeHelper:addHtmlLable_Tips(labelNode, str, tag, size)
            end
        else
            local visibleMap =
                {
                    mMailPrizeNode = true,
                    mMailReportsNode = false,
                    mMailSystemNode = false,
                    mSendTime = false,
                }
            
            NodeHelper:setNodesVisible(container, visibleMap)
            
            local giftInfo = MailInfo.kakaoMail[index - #MailDataHelper.mails]
            if not giftInfo then return end
            local nickname = giftInfo.nickname
            local item = giftInfo.itemname
            local str = '<font color="#625141" face = "Barlow-Bold" >#v1#</font>';
            str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", nickname);
            --str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", item);
            --str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", "");
            local labelNode = container:getVarLabelTTF("mMaillPrizeExplain")
            local tag = GameConfig.Tag.HtmlLable
            local size = CCSizeMake(GameConfig.LineWidth.MailContent, 150);
            if labelNode ~= nil then
                NodeHelper:addHtmlLable_Tips(labelNode, str, tag, size)
            end
        end
    else
        local rewardNodeVis = false;
        local normalNodeVis = false;
        local battleNodeVis = true;
        local gvgNodeVis = false
        -- local titleStr = {};
        local sTitle = "";
        local labelNode = "";
        local str = "";
        local mailId = mail.mailId
        if mail.mailId == 1 or mail.mailId == 56 then
            if #mail.params < 2 then
                table.insert(mail.params, 1, "")
            end
        end
        if mail.mailId ~= 0 then
            local mailObj = MailContetnCfg[mail.mailId];
            if mailObj ~= nil and mail.mailId ~= GUILD_MAIL.applyMailId then
                
                sTitle = mailObj.content;
                
                local pSize = table.maxn(mail.params);
                for i = 1, pSize, 1 do
                    local vStr = "#v" .. i .. "#";
                    local paramStr = mail.params[i]
                    local strArray = splitStr(paramStr, ":")
                    if #strArray == 3 and string.match(string.sub(paramStr, -3), ":%d") then
                        paramStr = string.sub(paramStr, 1, #paramStr - 3)
                    end
                    
                    if Golb_Platform_Info.is_r2_platform and string.find(paramStr, "-") then
                        local day = Split(mail.params[i], " ")[1]
                        local time = Split(mail.params[i], " ")[2]
                        time = time or ""
                        local dayTime = Split(day, "-")
                        if GamePrecedure:getInstance():getI18nSrcPath() == "French" then
                            local dayStr = TimeFormat(common:getLanguageString("@MailTimeFormat"), dayTime[1], dayTime[2], dayTime[3])
                            local timeSplit = ""
                            if time ~= "" then
                                timeSplit = Split(time, ":")
                                paramStr = dayStr .. " " .. "à" .. " " .. timeSplit[1] .. "h" .. timeSplit[2]
                            else
                                paramStr = dayStr
                            end
                        else
                            if #dayTime >= 3 then
                                paramStr = TimeFormat(common:getLanguageString("@MailTimeFormat"), dayTime[1], dayTime[2], dayTime[3]) .. " " .. time
                            end
                        end
                    end
                    if string.find(paramStr, "@") then
                        paramStr = common:getLanguageString(paramStr)
                    end
                    if NodeHelper:CheckIsReward(paramStr) then
                        local resInfo = NodeHelper:getItemInfo(paramStr, "_");
                        paramStr = resInfo.name
                    end
                    if mail.type == Mail_pb.GVG_MAIL then
                        if mailId == 140 and i == 3 then
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            paramStr = GVGManager.getCityCfg(tonumber(paramStr)).cityName or ""
                        elseif mailId == 141 and i == 3 then
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            paramStr = GVGManager.getCityCfg(tonumber(paramStr)).cityName or ""
                        elseif mailId == 142 and i == 2 then
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            paramStr = GVGManager.getCityCfg(tonumber(paramStr)).cityName or ""
                        elseif mailId == 143 and i == 3 then
                            local GVGManager = require("GVGManager")
                            GVGManager.initCityConfig()
                            paramStr = GVGManager.getCityCfg(tonumber(paramStr)).cityName or ""
                        end
                    
                    end
                    sTitle = GameMaths:replaceStringWithCharacterAll(sTitle, vStr, paramStr);
                end
            end
        else
            sTitle = mail.title
        -- common:stringAutoReturn(mail.title, REWRAD_LINE_COUNT);
        end
        
        local mailHtmlLength = GameConfig.LineWidth.MailContent
        if mail.type == Mail_pb.Normal then
            normalNodeVis = true;
            rewardNodeVis = false;
            battleNodeVis = true;
            gvgNodeVis = false
            
            if mail.mailId == GUILD_MAIL.applyMailId then
                normalNodeVis = false
                battleNodeVis = true
                str = ""
                if MailContetnCfg[mail.mailId] then
                    local params = mail.passthroughParams
                    if params then
                        params = json.decode(params)
                        local createTime = params.createTime
                        createTime = spriteTime(createTime)
                        local isRebirthStage = params.rebirthStage
                        local level = params.level
                        local RoleManager = require("PlayerInfo.RoleManager")
                        local prof = RoleManager:getOccupationById(params.prof)
                        local UserInfo = require("PlayerInfo.UserInfo")
                        if isRebirthStage then
                            level = UserInfo.getOtherLevelStr(1, tonumber(level))
                            prof = common:getLanguageString("@NewProfessionName_" .. tonumber(params.prof))
                        else
                            level = UserInfo.getOtherLevelStr(0, tonumber(level))
                            prof = common:getLanguageString("@ProfessionName_" .. tonumber(params.prof))
                        end
                        str = common:fill(MailContetnCfg[mail.mailId].content, createTime, params.playerName, level, prof, params.fightValue)
                    end
                end
                labelNode = container:getVarLabelTTF("mMaillReports")
                NodeHelper:setStringForLabel(container, {mReportBtnTxt1 = common:getLanguageString("@Admit"), mReportBtnTxt2 = common:getLanguageString("@Refuse")})
            else
                str = FreeTypeConfig[56].content;
                str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle);
                -- titleStr = {mMaillSystem = str};
                --labelNode = container:getVarLabelTTF("mMaillSystem");
                labelNode = container:getVarLabelTTF("mMaillReports");
            -- mailHtmlLength = GameConfig.LineWidth.MailContent + 70
            end
        elseif mail.type == Mail_pb.Battle then
            normalNodeVis = false;
            rewardNodeVis = false;
            battleNodeVis = true;
            gvgNodeVis = false
            
            str = FreeTypeConfig[56].content;
            str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle);
            -- titleStr = {mMaillReports = str};
            labelNode = container:getVarLabelTTF("mMaillReports");
            NodeHelper:setStringForLabel(container, {mReportBtnTxt1 = common:getLanguageString("@View"), mReportBtnTxt2 = common:getLanguageString("@Delete")})
        elseif mail.type == Mail_pb.Reward then
            normalNodeVis = false;
            rewardNodeVis = true;
            battleNodeVis = false;
            gvgNodeVis = false
            local rewardStr, Num, info = MailItem.getRewardStr(mail.item)
            
            NodeHelper:setSpriteImage(container, {mBg = NodeHelper:getImageBgByQuality(info.quality), mPic = info.icon})
            NodeHelper:setQualityFrames(container, {mFrame = info.quality})
            container:getVarLabelTTF("ItemNum"):setString(GameUtil:formatNumber(Num) or 1)
            local time = container:getVarLabelTTF("TimeTxt")
            time:setString(createDate)
            --local timeTxt = createDate
            --local timefont = '<font color="#ff9000">#v1#</font>'
            --timefont = GameMaths:replaceStringWithCharacterAll(timefont, "#v1#", timeTxt);
            --local htmlLabel = CCHTMLLabel:createWithString(timefont, CCSizeMake(300, 10), "Barlow-Bold")
            --htmlLabel:setAnchorPoint(ccp(1, 0.5))
            --htmlLabel:setPosition(ccp(0, -5))
            --htmlLabel:setScale(0.8)
            --time:removeAllChildren()
            --time:addChild(htmlLabel)
            --str = sTitle
            str = FreeTypeConfig[56].content
            str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle)
            --str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", rewardStr)
            --str = GameMaths:replaceStringWithCharacterAll(str, "#v2#", "")
            titleStr = { mMaillPrizeExplain = str }
            labelNode = container:getVarLabelTTF("mMaillPrizeExplain")
        elseif mail.type == Mail_pb.ARENA or mail.type == Mail_pb.ARENA_ALL then
            normalNodeVis = false
            rewardNodeVis = false
            battleNodeVis = true
            gvgNodeVis = false
            
            str = FreeTypeConfig[56].content
            str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle)
            -- titleStr = {mMaillReports = str}
            labelNode = container:getVarLabelTTF("mMaillReports")
            
            NodeHelper:setStringForLabel(container, {mReportBtnTxt1 = common:getLanguageString("@CSBattlePlayback"), mReportBtnTxt2 = common:getLanguageString("@Delete")})
        elseif mail.type == Mail_pb.GVG_MAIL then
            normalNodeVis = false;
            rewardNodeVis = false;
            battleNodeVis = false;
            gvgNodeVis = true
            str = FreeTypeConfig[56].content;
            str = GameMaths:replaceStringWithCharacterAll(str, "#v1#", sTitle);
            
            -- titleStr = {mMaillSystem = str};
            labelNode = container:getVarLabelTTF("mGVGExplain");
        end
        
        local platformName = GamePrecedure:getInstance():getPlatformName()
        local label = container:getVarLabelTTF("mSendTime")
        if label then
            label:setVisible(false)
        end
        if Golb_Platform_Info.is_r2_platform then
            
            if mail.createTime then
                if label then
                    label:setVisible(true)
                    local timeFormat = common:getLanguageString("@MailTimeFormat")
                    if timeFormat == "@MailTimeFormat" then
                        timeFormat = "%m/%d/%Y"
                    end
                    local timeStr = os.date(timeFormat, mail.createTime)
                    label:setString(timeStr)
                end
            end
        end
        NodeHelper:setStringForLabel(container, timeStr);
        local tag = GameConfig.Tag.HtmlLable
        local size = CCSizeMake(mailHtmlLength, 150);
        CCLuaLog("----------------- str " .. str)
        if labelNode ~= nil then
            labelNode:setScale(0.8)
            NodeHelper:addHtmlLable_1(labelNode, str, tag, size)
            labelNode:setVisible(true)
        end
        
        local visibleMap =
            {
                mMailPrizeNode = rewardNodeVis,
                mMailReportsNode = battleNodeVis,
                mMailSystemNode = normalNodeVis,
                mMailGVGNode = gvgNodeVis
            }
        
        NodeHelper:setNodesVisible(container, visibleMap);
    end
end

function MailItem:onGVG(container)
    local index = self.id
    local mail = MailDataHelper:getVariableByKeyAndIndex("systemMails", index)
    local cityId = tonumber(mail.params[3])
    local GVGManager = require("GVGManager")
    GVGManager.setMailTargetCity(cityId)
    GVGManager.isGVGPageOpen = true
    GVGManager.reqGuildInfo()
end

function MailItem.getRewardStr(items)
    local ResManager = require("ResManagerForLua");
    local maxSize = table.maxn(items);
    
    local str = ""
    local info = nil
    for i = 1, 1, 1 do
        local item = items[i];
        local resInfo = ResManager:getResInfoByTypeAndId(item.itemType, item.itemId, item.itemCount);
        if tonumber(resInfo.itemId) ~= 1010 and tonumber(resInfo.itemId) ~= 1011 then
            Num = item.itemCount;
        end
        str = str .. resInfo.name .. " x " .. item.itemCount .. " ";
        
        if not info then
            info = resInfo
        end
    end
    
    --str = common:stringAutoReturn(str, REWRAD_LINE_COUNT);
    return str, Num, info
end

----------领取邮件按钮点击事件-------------
function MailItem:onCancel(container)
    MailPageBase:onReward(container, self.id)
end
function MailPageBase:onReward(container, index)
    index = index or self.id
    if not isReceiveMailDone then return end
    isReceiveMailDone = false
    local mail = nil
    if PageType == PageTab.CommonMail then
        mail = MailDataHelper:getVariableByKeyAndIndex("commonMails", index);
    else
        mail = MailDataHelper:getVariableByKeyAndIndex("systemMails", index);
    end
    if mail and mail.mailId == GUILD_MAIL.applyMailId then
        -- 会长拒绝玩家加入公会
        local function sendRefuseMail(content)
            local alliance = require('Alliance_pb')
            local msg = alliance.HPApprovalRefusedOperC()
            local params = json.decode(mail.passthroughParams)
            msg.allianceId = params.allianceId
            msg.playerId = params.id
            msg.state = 0
            -- 0.拒绝 1.批准
            msg.emailId = mail.id
            msg.content = content
            common:sendPacket(HP.APPROVAL_REFUSED_OPER_C, msg)
        end
        isReceiveMailDone = true
        local GuildRefuseAcceptBase = require('GuildRefuseAcceptPage')
        GuildRefuseAcceptBase:setcallBack(sendRefuseMail)
        PageManager.pushPage('GuildRefuseAcceptPage')
        return
    end
    if mail then
        MailPageBase:sendMsgForMailGetInfo(mainContainer, mail.id);
    end
    
    MailItem:onView(container, index);
end

----------------------------------------------------------------------------------
function MailPageBase:receiveAllKakoGift()
    if #MailInfo.kakaoMail > 0 then
        libPlatformManager:getPlatform():OnKrReceiveGift(tostring(MailInfo.kakaoMail[1].id), tostring(GamePrecedure:getInstance():getServerID()))
        MailItem.giftId = MailInfo.kakaoMail[1].id
        isReceiveAllKakoGift = true
    end
end
-----------------------------------------------
--------------------开启有新邮件提示标记---------------------
function MailPageBase:sendGetNewInfoMessage(container)
    local msg = MsgMainFrameGetNewInfo:new()
    msg.type = Const_pb.NEW_MAIL;
    MessageManager:getInstance():sendMessageForScript(msg)
end

--------------------关闭有新邮件提示标记---------------------
-- function MailPageBase:sendClosesNewInfoMessage( container )
-- local msg = MsgMainFrameGetNewInfo:new()
-- msg.type = GameConfig.NewPointType.TYPE_MAIL_CLOSE;
-- MessageManager:getInstance():sendMessageForScript(msg)
-- end
function MailPageBase:onInit(container)
end

function MailPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile);
    NodeHelper:initScrollView(container, "mContent", 4);
end

function MailPageBase:onEnter(container)
    isReceiveMailDone = true
    isReceiveAllKakoGift = false
    MailPageBase.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)
    MailPageBase.container = container
    if Golb_Platform_Info.is_entermate_platform then
        libPlatformManager:getPlatform():OnKrgetGiftLists()
    end
    if Golb_Platform_Info.is_win32_platform then
        --[[	MailInfo.kakaoMail = {{id ="1",
        imageurl = "",
        itemcode = "",
        itemname = "abc1",
        nickname = "朴哲勋"},
        {id ="2",
        imageurl = "",
        itemcode = "",
        itemname = "abc2",
        nickname = "abc22"},
        }--]]
        MailInfo.FBMail = {}
    
    end
    self:registerPacket(container)
    mainContainer = container;
    container.scrollview = container:getVarScrollView("mContent")
    self:rebuildAllItem(container)
    self:refreshPage(container);
    -- self:sendGetNewInfoMessage( container )
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    self:sendMsgForMailInfo(container);
-- self:rebuildAllItem(container);
end

function MailPageBase:onExecute(container)
    if isReceiveGift then
        for k, v in ipairs(MailInfo.kakaoMail) do
            if v.id == MailItem.giftId then
                MailInfo.kakaoMail[k] = nil
                break
            end
        end
        local values = {}
        table.foreach(MailInfo.kakaoMail, function(k, v)values[#values + 1] = v end)
        MailInfo.kakaoMail = values
        MailPageBase:rebuildAllItem(MailPageBase.container)
        MailPageBase:refreshPage(MailPageBase.container)
        isReceiveGift = false
    end
end

function MailPageBase:onExit(container)
    local Mail_pb = require("Mail_pb")
    if MailPageBase.libPlatformListener then
        MailPageBase.libPlatformListener:delete()
    end
    local boo = true
    for k, v in ipairs(MailDataHelper:getVariableByKey("mails")) do
        if v.type == Mail_pb.Reward then
            boo = false
        end
        if GUILD_MAIL[v.mailId] then
            boo = false
        end
    end
    if boo then
        MailDataHelper:sendClosesNewInfoMessage()
    end
    
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    container.scrollview:removeAllCell()
    onUnload(thisPageName, container)
end
----------------------------------------------------------------
function MailPageBase:refreshPage(container)
    local rewardCount = 0
    if PageType == PageTab.CommonMail then
        rewardCount = table.maxn(MailDataHelper:getVariableByKey("commonMails"))
    else
        rewardCount = table.maxn(MailDataHelper:getVariableByKey("systemMails"))
    end
    local mailNoticeStr = common:getLanguageString("@MailNotice", rewardCount)
    
    --if PageType == PageTab.CommonMail then
    --    MailDataHelper.newCommonMail = false
    --else
    --    MailDataHelper.newSystemMail = false
    --end
    
    require("Util.RedPointManager")
    local nodeVisible = {
        mOrdinaryPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.MAIL_NORMAL_TAB),
        mMailSystemPoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.MAIL_SYSTEM_TAB)
    }
    
    if rewardCount <= 0 then
        mailNoticeStr = common:getLanguageString("@MailNoticeNo")
    end
    if rewardCount>0 then
        NodeHelper:setMenuItemsEnabled(mainContainer,{mBtn1=true,mBtn2=true})
    else
        NodeHelper:setMenuItemsEnabled(mainContainer,{mBtn1=false,mBtn2=false})
    end
    NodeHelper:setNodesVisible(container, { mNoMailNode = rewardCount <= 0 })
    
    NodeHelper:setNodesVisible(container, nodeVisible)
    NodeHelper:setStringForLabel(container, { mMailPromptTex = mailNoticeStr })
    self:setTabSelected(container)
end
----------------scrollview-------------------------
function MailPageBase:rebuildAllItem(container)
    self:clearAllItem(container);
    self:buildItem(container);
end

function MailPageBase:clearAllItem(container)
    local scrollview = container.scrollview
    scrollview:removeAllCell();
end

function MailPageBase:buildItem(container)
    if (MailDataHelper:getVariableByKey("mails") == nil) then
        return;
    end
    
    local maxSize = 0
    if PageType == PageTab.CommonMail then
        maxSize = table.maxn(MailDataHelper:getVariableByKey("commonMails"));
        NodeHelper:setNodesVisible(container,{mBtnNode1=false,mBtnNode2=true})
    else
        maxSize = table.maxn(MailDataHelper:getVariableByKey("systemMails"));
        NodeHelper:setNodesVisible(container,{mBtnNode1=true,mBtnNode2=false})
    end
    if #MailInfo.kakaoMail > 0 and PageType == PageTab.CommonMail then
        maxSize = maxSize + #MailInfo.kakaoMail
    end
    if #MailInfo.FBMail > 0 and PageType == PageTab.CommonMail then
        maxSize = maxSize + #MailInfo.FBMail
    end
    
    -- NodeHelper:buildScrollView(container, maxSize, MailItem.ccbiFile, MailItem.onFunction);
    local scrollview = container.scrollview
    local ccbiFile = MailItem.ccbiFile
    local totalSize = maxSize
    if totalSize == 0 then return end
    local cell = nil
    for i = 1, totalSize do
        cell = CCBFileCell:create()
        cell:setCCBFile(ccbiFile)
        
        local panel = common:new({id = totalSize - i + 1}, MailItem)
        cell:registerFunctionHandler(panel)
        
        scrollview:addCell(cell)
        local pos = ccp(0, cell:getContentSize().height * (i - 1))
        cell:setPosition(pos)
    end
    local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * totalSize)
    scrollview:setContentSize(size)
    scrollview:setContentOffset(ccp(0, scrollview:getViewSize().height - scrollview:getContentSize().height))
    scrollview:forceRecaculateChildren()
end

function MailPageBase:onOrdinary(container)
    if PageType == PageTab.CommonMail then
        self:setTabSelected(container)
        return
    end
    NodeHelper:setNodesVisible(container,{mBtnNode1=false,mBtnNode2=true})
    PageType = PageTab.CommonMail
    self:rebuildAllItem(container);
    self:refreshPage(container);
end

function MailPageBase:onSystem(container)
    if PageType == PageTab.SystemMail then
        self:setTabSelected(container)
        return
    end
    NodeHelper:setNodesVisible(container,{mBtnNode1=true,mBtnNode2=false})
    PageType = PageTab.SystemMail
    self:rebuildAllItem(container);
    self:refreshPage(container);
end

function MailPageBase:setTabSelected(container)
    local isCommonTab = PageType == PageTab.CommonMail
    NodeHelper:setMenuItemSelected(container, {
        mOrdinaryBtn = isCommonTab,
        mMailSystemBtn = not isCommonTab
    })
    NodeHelper:setColorForLabel(container, { mOrdinaryTxt = isCommonTab and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT,
                                             mSystemTxt = not isCommonTab and GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT })
end
----------------click event------------------------
function MailPageBase:onClose(container)
    PageManager.setAllNotice()
    PageManager.popPage(thisPageName);
end

function MailPageBase:onRewardAll(container)
    local Mail_pb = require("Mail_pb")
    local msg = Mail_pb.OPMailGet();
    msg.id = 0;
    msg.type = 2
    msg.mailClassify = PageType
    
    local pb_data = msg:SerializeToString();
    container:sendPakcet(opcodes.OPCODE_MAIL_GET_C, pb_data, #pb_data, true);
   -- MessageBoxPage:Msg_Box(common:getLanguageString('@AlreadyReceive'))
    -- for k,v in ipairs(MailInfo.kakaoMail) do
    -- 	libPlatformManager:getPlatform():OnKrReceiveGift(tostring(v.id),tostring(GamePrecedure:getInstance():getServerID()))
    -- end
    MailPageBase:receiveAllKakoGift()
    --MessageBoxPage:Msg_Box(common:getLanguageString('@AlreadyReceive'))
-- MailInfo.kakaoMail = {}
end

function MailPageBase:onSingleRead(container)
    local Mail_pb = require("Mail_pb")
    local msg = Mail_pb.OPMailGet();
    msg.id = 0;
    msg.type = 2
    msg.mailClassify = PageType
    
    local pb_data = msg:SerializeToString();
    container:sendPakcet(opcodes.OPCODE_MAIL_GET_C, pb_data, #pb_data, true);

-- for k,v in ipairs(MailInfo.kakaoMail) do
-- 	libPlatformManager:getPlatform():OnKrReceiveGift(tostring(v.id),tostring(GamePrecedure:getInstance():getServerID()))
-- end
-- MailInfo.kakaoMail = {}
end

function MailPageBase:onDeleteAll(container)
    local Mail_pb = require("Mail_pb")
    local msg = Mail_pb.OPMailGet();
    msg.id = 0;
    msg.type = 1
    msg.mailClassify = PageType
    
    local pb_data = msg:SerializeToString();
    container:sendPakcet(opcodes.OPCODE_MAIL_GET_C, pb_data, #pb_data, true);
end
---------------------------------------------------
function MailPageBase:onReceivePacket(container)
    local Arena_pb = require "Arena_pb"
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    
    --[[
    if opcode == opcodes.OPCODE_MAIL_INFO_S then
    local msg = Mail_pb.OPMailInfoRet()
    msg:ParseFromString(msgBuff)
    self:onReceiveMailInfo(container, msg)
    return
    end
    --]]
    if opcode == opcodes.APPROVAL_REFUSED_OPER_S then
        local alliance = require('Alliance_pb')
        local msg = alliance.HPApprovalRefusedOperS()
        msg:ParseFromString(msgBuff)
        local state = msg.state
        -- 0.拒绝 1.批准
        if state == 0 then
            -- MessageBoxPage:Msg_Box_Lan("@AllianceRefuseOK")
            elseif state == 1 then
            -- MessageBoxPage:Msg_Box_Lan("@AllianceApplyOk")
            end
            MailDataHelper:removeMailById(msg.emailId)
            self:rebuildAllItem(container);
            self:refreshPage(container)
            return
    end
    if opcode == opcodes.OPCODE_MAIL_SEE_ARENA_REPORT_S then
        -- 邮件查看竞技场战报
        local msg = Arena_pb.HPArenaChallengeReportRes()
        msg:ParseFromString(msgBuff)
        -- CCLuaLog("msg.resultShow.battleInfo"..tostring(msg.resultShow.battleInfo))
        common:arenaViewBattle(msg.battleInfo)
        return
    end
    if opcode == opcodes.OPCODE_MAIL_GET_S then
        isReceiveMailDone = true
        UserInfo.checkLevelUp()
        --MessageBoxPage:Msg_Box(common:getLanguageString('@AlreadyReceive'))
        -- 	local msg = Mail_pb.OPMailGetRet()
        -- 	msg:ParseFromString(msgBuff)
        -- 	self:onReceiveMailGetInfo(container, msg)
        return
    else
        MailDataHelper:onReceivePacket(container, self)
    end
    if opcode == HP_pb.PLAYER_AWARD_S then
        local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end

--------------------领取回包---------------------
-- function MailPageBase:onReceiveMailGetInfo( container, msg )
--    local type = 1
--    if msg:HasField("mailClassify") then
--        if msg.mailClassify==1 then
--            type = 1
--        else
--            type = 2
--        end
--    end
--    if msg:HasField("type") and msg.type~=0 then
--        if msg.type == 1 then
--            local i = 1
--            while i <= #MailDataHelper:getVariableByKey("mails") do
--                local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);
--                if mail~=nil and mail.type ~= Mail_pb.Reward and mail.mailClassify==type then
--                    table.remove(MailDataHelper:getVariableByKey("mails"), i);
--                    MailDataHelper:removeVariableByKey("mailInvalidateList",i)
--                else
--                    i = i+1
--                end
--            end
--        elseif msg.type == 2 then
--            local i = 1
--            while i <= #MailDataHelper:getVariableByKey("mails") do
--                local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);
--                if mail~=nil and mail.type == Mail_pb.Reward and mail.mailClassify==type then
--                    table.remove(MailDataHelper:getVariableByKey("mails"), i);
--                    MailDataHelper:removeVariableByKey("mailInvalidateList",i)
--                else
--                    i = i+1
--                end
--            end
--        end
--    else
--        local deleteId = msg.id;
--        local maxSize = table.maxn(MailDataHelper:getVariableByKey("mails"));
--        local deleteIndex = 0;
--        local count = 1;
--        for i =1, maxSize, 1 do
--            local mail = MailDataHelper:getVariableByKeyAndIndex("mails",i);
--            if mail.id == deleteId then
--                deleteIndex = i;
--            end
--        end
--        table.remove(MailDataHelper:getVariableByKey("mails"), deleteIndex);
--        MailDataHelper:removeVariableByKey("mailInvalidateList",deleteId)
--    end
--    --table.remove(MailDataHelper:mailInvalidateList , deleteId)
--    MailDataHelper:RefreshMail()
-- self:rebuildAllItem(container);
-- self:refreshPage(container);
-- end
--------------------请求服务端邮件列表信息---------------------
function MailPageBase:sendMsgForMailInfo(container)
    local Mail_pb = require("Mail_pb")
    local msg = Mail_pb.OPMailInfo();
    
    -- local index = table.maxn(MailInfo.mails);
    if MailDataHelper:getVariableByKey("lastMail") ~= nil and #MailDataHelper:getVariableByKey("lastMail") ~= 0 then
        -- local mail = MailInfo.mails[index];
        -- if mail ~= nil then
        msg.version = MailDataHelper:getVariableByKey("lastMail").id
    -- else
    -- msg.version = 0;
    -- end
    else
        msg.version = 0;
    end
    
    local pb_data = msg:SerializeToString();
    container:sendPakcet(opcodes.OPCODE_MAIL_INFO_C, pb_data, #pb_data, true);
end

--------------------请求领取邮件---------------------
function MailPageBase:sendMsgForMailGetInfo(container, id)
    local Mail_pb = require("Mail_pb")
    local msg = Mail_pb.OPMailGet();
    msg.id = id;
    
    local pb_data = msg:SerializeToString();
    container:sendPakcet(opcodes.OPCODE_MAIL_GET_C, pb_data, #pb_data, true);
end


function MailPageBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function MailPageBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end


---------得到当前礼品类型邮件总个数----------
function MailPageBase:getCurrentRewardCount()
    local Mail_pb = require("Mail_pb")
    if (MailDataHelper:getVariableByKey("mails") == nil) then
        return;
    end
    
    --
    local maxSize = 0
    local mails = {}
    local count = 0;
    
    if PageType == PageTab.CommonMail then
        maxSize = table.maxn(MailDataHelper:getVariableByKey("commonMails"));
        mails = MailDataHelper:getVariableByKey("commonMails")
    else
        maxSize = table.maxn(MailDataHelper:getVariableByKey("systemMails"));
        mails = MailDataHelper:getVariableByKey("systemMails")
    end
    
    for i = 1, maxSize do
        local mail = mails[i];
        if mail.type == Mail_pb.Reward then
            count = count + 1;
        end
    end
    
    return count;
end



function MailPageBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    local GVGManager = require("GVGManager")
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        if pageName == thisPageName then
            self:rebuildAllItem(container);
            self:refreshPage(container);
        elseif pageName == GVGManager.moduleName then
            local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
            if extraParam == GVGManager.onMapInfo then
                -- local status = GVGManager.getGVGStatus()
                -- if status ~= GVG_pb.GVG_STATUS_WAITING then
                if GVGManager.isGVGOpen then
                    PageManager.changePage("GVGMapPage")
                end
            -- else
            -- PageManager.changePage("GVGPreparePage")
            -- end
            end
        end
    end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local MailPage = CommonPage.newSub(MailPageBase, thisPageName, option);
