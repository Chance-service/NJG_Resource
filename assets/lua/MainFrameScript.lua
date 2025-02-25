-- MainFrameScript
----����MainFrame��һЩ�¼��������ȸ���
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local UserInfo = require("PlayerInfo.UserInfo")
local isCreateTimeCalculator = false
require("CCBIObjectPool")
isOpenNewGuide = true

local MainFrameScript = { }
local libPlatformListener = { }
function libPlatformListener:onKusoPay(listener)
    if not listener then return end
    local strResult = listener:getResultStr()
    CCLuaLog("onKusoPay : " .. strResult)
    local Shop_pb = require("Shop_pb")
    local msg = Shop_pb.SixNineCoinTakeRequest()
    local orderId, token, nonce, goodsId = unpack(common:split(strResult, "|"))
    msg.token = token
    msg.orderid = orderId
    msg.nonce = nonce
    msg.goodsId = tonumber(goodsId)
    common:sendPacket(HP_pb.SHOP_69COIN_TAKE_C, msg, true)
end
MainFrameScript.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)

function setCCBMenuAnimation(menuName, actionName)
    local container = tolua.cast(MainFrame:getInstance(), "CCBContainer")
    if container then
        local btn = container:getCCMenuItemCCBFileFromCCB(menuName)
        --local btn = container:getCCMenuItemImageFromCCB(menuName)
        if btn then
            -- btn:runExtraAnimation(actionName)
            btn:changeState(actionName)
            --if actionName == "Normal" then
            --    btn:unselected()
            ----elseif actionName == "TouchBegin" then
            --elseif actionName == "Selected" then
            --    btn:selected()
            --end
        end
    end
end
function resetAllMenu()
    setCCBMenuAnimation("mMainPageBtn", "Normal")
    setCCBMenuAnimation("mBattlePageBtn", "Normal")
    --setCCBMenuAnimation("mChatBtn", "Normal")
    setCCBMenuAnimation("mBackpackPageBtn", "Normal")
    setCCBMenuAnimation("mEquipmentPageBtn", "Normal")
    setCCBMenuAnimation("mLeaderPageBtn", "Normal")
end
function resetMenu(menuName, needResetAll)
    needResetAll = needResetAll or false
    if needResetAll then
        resetAllMenu()
        -- setCCBMenuAnimation(menuName,"Normal")
    end
    setCCBMenuAnimation(menuName, "TouchBegin")
end
-- 家園
function MainFrame_onMainPageBtn(isTouchButton, isKeepAllPage)
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "MainScenePage" and isTouchButton then
        PageManager.pushPage("NewbieGuideForcedPage")
        return
    else
        if isTouchButton then
            local transPage = require("TransScenePopUp")
            TransScenePopUp_setCallbackFun(function()
                --MainFrame:getInstance():showPage("MainScenePage")
                PageManager.changePage("MainScenePage", false)
                PageManager.popPage("NgBattleEditTeamPage")
                local GuideManager = require("Guide.GuideManager")
                GuideManager.newbieGuide()
            end)
            resetMenu("mMainPageBtn", true)
            UserInfo.sync()
            if not isKeepAllPage then
                MainFrame:getInstance():popAllPage()
            end
            PageManager.pushPage("TransScenePopUp")
        else
            resetMenu("mMainPageBtn", true)
            PageManager.changePage("MainScenePage")
            local GuideManager = require("Guide.GuideManager")
            GuideManager.newbieGuide()
        end
    end
end
-- 戰鬥
function MainFrame_onBattlePageBtn(isTouchButton)
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "NgBattlePage" and isTouchButton then
        PageManager.pushPage("NewbieGuideForcedPage")
        return
    else
        if isTouchButton then
            local transPage = require("TransScenePopUp")
            TransScenePopUp_setCallbackFun(function()
                local battlePage = require("NgBattlePage")
                require("NewBattleConst")
                require("NgBattleDataManager")
                NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.AFK)
                PageManager.changePage("NgBattlePage", false)
            end)
            resetMenu("mBattlePageBtn", true)
            UserInfo.sync()
            PageManager.pushPage("TransScenePopUp")
        else
            resetMenu("mBattlePageBtn", true)
            local battlePage = require("NgBattlePage")
            require("NewBattleConst")
            require("NgBattleDataManager")
            NgBattleDataManager_setBattleType(NewBattleConst.SCENE_TYPE.AFK)
            PageManager.changePage("NgBattlePage")
        end
    end
end
-- ����
function MainFrame_onChatBtn()
    PageManager.pushPage("ChatPage")
    resetMenu("mChatBtn", true)
    local GuideManager = require("Guide.GuideManager")
    GuideManager.newbieGuide()
    return 0
end
-- 召喚
function MainFrame_onBackpackPageBtn(_page)
    if LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON) then
        MessageBoxPage:Msg_Box(LockManager_getLockStringByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON))
        setCCBMenuAnimation("mBackpackPageBtn", "Normal")
    else
         local Activity6_pb = require("Activity6_pb")
         local msg = Activity6_pb.SuperPickUpSync()
         msg.id = 0
         common:sendPacket(HP_pb.ACTIVITY197_SUPER_PICKUP_INFO_C, msg, true)
        --local transPage = require("TransScenePopUp")
        --TransScenePopUp_setCallbackFun(function()
        --    local GuideManager = require("Guide.GuideManager")
        --    if GuideManager.isInGuide then
        --        require("Summon.SummonPage"):setEntrySubPage("Premium")
        --    elseif type(_page) == "string" then
        --        require("Summon.SummonPage"):setEntrySubPage(_page)
        --    end
        --    PageManager.pushPage("Summon.SummonPage")
        --end)
        --setCCBMenuAnimation("mBackpackPageBtn", "Normal")
        --UserInfo.sync()
        --PageManager.pushPage("TransScenePopUp")
    end
end
-- 冒險
function MainFrame_onEquipmentPageBtn(isTouchButton)
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "Lobby2Page" and isTouchButton then
        PageManager.pushPage("NewbieGuideForcedPage")
        return
    else
        if isTouchButton then
            local transPage = require("TransScenePopUp")
            TransScenePopUp_setCallbackFun(function()
                PageManager.changePage("Lobby2Page", false)
                PageManager.popPage("NgBattleEditTeamPage")
            end)
            resetMenu("mEquipmentPageBtn", true)
            PageManager.pushPage("TransScenePopUp")
        else
            resetMenu("mEquipmentPageBtn", true)
            PageManager.changePage("Lobby2Page")
        end
    end
end
-- 英雄
function MainFrame_onLeaderPageBtn(isTouchButton)
    local currPage = MainFrame:getInstance():getCurShowPageName()
    if currPage == "EquipmentPage" and isTouchButton then
        PageManager.pushPage("NewbieGuideForcedPage")
        return
    else
        if isTouchButton then
            local transPage = require("TransScenePopUp")
            TransScenePopUp_setCallbackFun(function()
                PageManager.changePage("EquipmentPage", false)
                local GuideManager = require("Guide.GuideManager")
                GuideManager.newbieGuide()
            end)
            resetMenu("mLeaderPageBtn", true)
            PageManager.pushPage("TransScenePopUp")
        else
            resetMenu("mLeaderPageBtn", true)
            PageManager.changePage("EquipmentPage")
            local GuideManager = require("Guide.GuideManager")
            GuideManager.newbieGuide()
        end
    end
end
-- ����        �����ť�޸ĵ�������?
function MainFrame_onMainGuild()
    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.ALLIANCE_OPEN_LEVEL then
        PageManager.changePage("GuildPage")
    else
        MessageBoxPage:Msg_Box(common:getLanguageString("@AllianceLevelNotReached", GameConfig.ALLIANCE_OPEN_LEVEL))
    end
    -- resetMenu("mGuildPageBtn", true)
    --    local GuideManager = require("Guide.GuideManager");
    --    GuideManager.newbieGuide();
    return 0
end

-- Ť���¼�
function MainFrame_onNiudanBtn(index)
    -- local index = index or 1
    --local GuideManager = require("Guide.GuideManager")
    local FetterManager = require("FetterManager")
    local cur,total = FetterManager.getIllCollectRate()
    if --[[GuideManager.currGuide[GuideManager.guideType.MERCENARY_GUIDE] ~= 0]] cur <= 0 and UserInfo.roleInfo.level < 8 then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@LevelRelease18"))
        return
    end
    
    local toIndex = 1
    if type(index) == "number" then
        toIndex = index
    end
    local FetterManager = require("FetterManager")
    FetterManager.clear()
    FetterManager.reqFetterInfo()

    require("GashaponPage")
    local activityId = nil
    local GuideManager = require("Guide.GuideManager")

    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)

    if GuideManager.currGuide[GuideManager.guideType.NIUDAN_GUIDE] ~= 0 then
        --新手教學強制跳去常規池
        for i = 1, #ActivityInfo.NiuDanPageIds do
            if ActivityInfo.NiuDanPageIds[i] == 99 then
                activityId = ActivityInfo.NiuDanPageIds[i]
                break
            end
        end
        if GuideManager.isInGuide == false and activityId == 99 then
            GuideManager.currGuideType = GuideManager.guideType.NIUDAN_GUIDE
            GuideManager.newbieGuide()
        end
    else
        for i = 1, #ActivityInfo.NiuDanPageIds do
            if ActivityInfo.NoticeInfo.NiuDanPageIds[ActivityInfo.NiuDanPageIds[i]] == true then
                activityId = ActivityInfo.NiuDanPageIds[i]
                break
            end
        end
    end
    activityId = activityId or ActivityInfo.NiuDanPageIds[1]

    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        --activityId = 139
    end
    GashaponPage_setPart(activityId)
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")

    --    LimitActivityPage_setPart(ActivityInfo.NiuDanPageIds[1])
    --    LimitActivityPage_setIds(ActivityInfo.NiuDanPageIds)
    --    LimitActivityPage_setTitleStr("@NiuDanTitle")
    --    PageManager.changePage("LimitActivityPage")
    --    resetMenu("mGuildPageBtn", true)
end

function MainFrame_onForge()
    PageManager.pushPage("EquipIntegrationPage")
--    resetMenu("mChatBtn", true)
--    local GuideManager = require("Guide.GuideManager")
--    GuideManager.newbieGuide()
    return 0
end

-- 刷新紅點
function MainFrame_refreshAllRedPoint()
    require("Util.RedPointManager")
    NodeHelper:mainFrameSetPointVisible({
        mMainScenePagePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_MAIN_BTN),
        mLobby2PagePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.LOBBY2_MAIN_BTN),
        mBattlePagePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.BATTLE_MAIN_BTN),
        mLeaderPagePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.HERO_MAIN_BTN),
        mBackpackPagePoint = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.SUMMON_MAIN_BTN),
    })
end
--[[
--Ӷ��
function MainFrame_onMercenaryPageBtn()
	local UserInfo = require("PlayerInfo.UserInfo");
	UserInfo.sync()
	if UserInfo.roleInfo.level < GameConfig.LevelLimit.MecenaryLvLimit then
		MessageBoxPage:Msg_Box("@MercenaryLevelNotEnough")
	else
		PageManager.changePage("EquipMercenaryPage");
	end
	resetMenu("mEquipmentPageBtn")
	return 0
end

--��ɫ��Ϣ
function MainFrame_onPlayerInfoPageBtn()
	PageManager.pushPage("PlayerInfoPage");
	return 1;
end
--����
function MainFrame_onSkillPageBtn()
	PageManager.changePage("SkillPage");
	require("Skill.SEManager")
	if mSERedPoint==false then
		PageManager.showRedNotice("Skill", false);
	end
	resetMenu("mSkillPageBtn",true)
	return 0;
end
--]]
-- ��¼����δ�������ͨ�?
function MainFrame_createTimeCalculator()
    --    if isCreateTimeCalculator then
    --        return
    --    else
    --        isCreateTimeCalculator = true
    --    end
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
        libOS:getInstance():clearNotification()
    else
        libPlatformManager:getPlatform():sendMessageG2P("G2P_CLEAN_NOTIFICATION_ONCE", "")
        libPlatformManager:getPlatform():sendMessageG2P("G2P_CLEAN_NOTIFICATION_LOOP", "")
    end
    local PushNotificationsManager = require("PushNotificationsManager")
    if PushNotificationsManager == nil or not PushNotificationsManager._bOpenAPN then
        return
    end
    local index = 10
    UserInfo.sync()
    for mID, PushCfg in pairs(PushNotificationsManager._PushCfg) do
        if UserInfo.roleInfo and UserInfo.roleInfo.level and UserInfo.roleInfo.level >= PushCfg._minLevel and UserInfo.roleInfo.level <= PushCfg._maxLevel then
            if PushCfg._Type == 0 then
                local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
                local msg = MercenaryExpedition_pb.HPMercenaryExpeditionInfo()
                msg.action=2
                local pb = msg:SerializeToString()
                if UserInfo.roleInfo and not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.BOUNTY) then
                    PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_INFO_C, pb, #pb, false)
                end
            elseif PushCfg._Type == 1 then
                -- ����24Сʱ֪ͨ��������
                local todayDateTime = os.time()
                local keyName = "Task_0" .. PushCfg._Id .. "_" .. todayDateTime
                -- PushNotificationsManager.setTaskTimeCalcultor(keyName, PushCfg, nil, 0)
                PushNotificationsManager.TaskTimeCalcultor[keyName] = {
                    mKey = keyName,
                    mId = PushCfg._Id,
                    mType = PushCfg._Type,
                    mIcon = PushCfg._Icon,
                    mSound = PushCfg._Sound,
                    mText = PushCfg._Text,
                    minLevel = PushCfg._minLevel,
                    maxLevel = PushCfg._maxLevel,
                    mTime = PushCfg._Time,
                    mDateStart = PushCfg._DateStart,
                    mDateEnd = PushCfg._DateEnd,
                    mContainer = nil,
                    mFastCost = 0,
                }
            elseif PushCfg._Type == 2 then
                local todayDateTime = os.time()
                local startDateTime = os.time( { day = PushCfg._DateStart[3], month = PushCfg._DateStart[2], year = PushCfg._DateStart[1], hour = 0, minute = 0, second = 0 })
                local endDateTime = os.time( { day = PushCfg._DateEnd[3], month = PushCfg._DateEnd[2], year = PushCfg._DateEnd[1], hour = 24, minute = 0, second = 0 })
                -- CCLuaLog("startDateTime:***____"..startDateTime.."endDateTime"..endDateTime.."PushCfg._Text"..PushCfg._Text)
                if tonumber(todayDateTime) >= tonumber(startDateTime) and tonumber(todayDateTime) <= tonumber(endDateTime) then
                    local keyName = "Task_0" .. PushCfg._Id .. "_" .. todayDateTime

                    local leftTime = getLeftTime(PushCfg._Time[1], PushCfg._Time[2], PushCfg._Time[3])

                    -- CCLuaLog("keyName:***____"..keyName.."leftTime"..leftTime.."PushCfg._Text"..PushCfg._Text)

                    TimeCalculator:getInstance():createTimeCalcultor(keyName, leftTime)
                    -- PushNotificationsManager.setTaskTimeCalcultor(keyName, PushCfg, nil, 0)
                    PushNotificationsManager.TaskTimeCalcultor[keyName] = {
                        mKey = keyName,
                        mId = PushCfg._Id,
                        mType = PushCfg._Type,
                        mIcon = PushCfg._Icon,
                        mSound = PushCfg._Sound,
                        mText = PushCfg._Text,
                        minLevel = PushCfg._minLevel,
                        maxLevel = PushCfg._maxLevel,
                        mTime = PushCfg._Time,
                        mDateStart = PushCfg._DateStart,
                        mDateEnd = PushCfg._DateEnd,
                        mContainer = nil,
                        mFastCost = 0
                    }
                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
                        libOS:getInstance():addNotification(PushCfg._Text, leftTime, true)
                    else
                        index = index + 1
                        local strtable = {
                            title = keyName,
                            timeleft = leftTime,
                            gamemsg = PushCfg._Text,
                            action = "android.intent.action.MY_ALERT_RECEIVER_" .. index,
                            sound = PushCfg._Sound,
                            dayloop = true
                        }
                        local JsMsg = cjson.encode(strtable)
                        libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
                    end
                end
            elseif PushCfg._Type == 3 then
                local todayDateTime = os.time()
                local leftTime = getLeftTime(PushCfg._Time[1], PushCfg._Time[2], PushCfg._Time[3])
                local startDateTime = os.time( { day = PushCfg._DateStart[3], month = PushCfg._DateStart[2], year = PushCfg._DateStart[1], hour = 0, minute = 0, second = 0 })
                local endDateTime = os.time( { day = PushCfg._DateEnd[3], month = PushCfg._DateEnd[2], year = PushCfg._DateEnd[1], hour = PushCfg._Time[1], minute = PushCfg._Time[2], second = PushCfg._Time[3] })
                -- CCLuaLog("3___startDateTime:***____"..startDateTime.."endDateTime"..endDateTime.."PushCfg._Text"..PushCfg._Text.."Todaytime"..todayDateTime)
                if tonumber(todayDateTime) >= tonumber(startDateTime) and tonumber(todayDateTime) <= tonumber(endDateTime) then
                    local keyName = "Task_0" .. PushCfg._Id .. "_" .. todayDateTime
                    TimeCalculator:getInstance():createTimeCalcultor(keyName, leftTime)
                    -- PushNotificationsManager.setTaskTimeCalcultor(keyName, PushCfg, nil, 0)
                    -- CCLuaLog("3q___startDateTime:***____"..startDateTime.."endDateTime"..endDateTime.."PushCfg._Text"..PushCfg._Text.."Todaytime"..todayDateTime)
                    PushNotificationsManager.TaskTimeCalcultor[keyName] = {
                        mKey = keyName,
                        mId = PushCfg._Id,
                        mType = PushCfg._Type,
                        mIcon = PushCfg._Icon,
                        mSound = PushCfg._Sound,
                        mText = PushCfg._Text,
                        minLevel = PushCfg._minLevel,
                        maxLevel = PushCfg._maxLevel,
                        mTime = PushCfg._Time,
                        mDateStart = PushCfg._DateStart,
                        mDateEnd = PushCfg._DateEnd,
                        mContainer = nil,
                        mFastCost = 0
                    }
                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
                        libOS:getInstance():addNotification(PushCfg._Text, leftTime, false)
                    else
                        index = index + 1
                        local strtable = {
                            title = keyName,
                            timeleft = leftTime,
                            gamemsg = PushCfg._Text,
                            action = "android.intent.action.MY_ALERT_RECEIVER_" .. index,
                            sound = PushCfg._Sound,
                            dayloop = false
                        }
                        local JsMsg = cjson.encode(strtable)
                        libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
                    end
                    todayDateTime = todayDateTime + 86400
                    leftTime = leftTime + 86400
                end
            end
        end
    end
    --    -----------************�����ϰ汾�ͻ���***************---------------
    --    if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_IOS then
    --        local leftTime9 = getLeftTime(9, 0, 0)
    --        local leftTime21 = getLeftTime(21, 0, 0)
    --        local strtable = {
    --            lefttime8 = leftTime9,
    --            -- �����´�9��ʱ����
    --            lefttime8msg = Language:getInstance():getString("@Notification8Daily"),
    --            lefttime20 = leftTime21,
    --            -- �����´�21��ʱ����
    --            lefttime20msg = Language:getInstance():getString("@Notification20Daily"),
    --            needLoop = true;-- �Ƿ�ÿ��ѭ�� false��ʾֻ��Ӧһ��
    --        }
    --        local JsMsg = cjson.encode(strtable)
    --        --libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
    --    end
    ------------*****************************-----------------
end
-- ֪ͨ�仯����±���ͨ�?
function MainFrame_refreshTimeCalculator()
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
        libOS:getInstance():clearNotification()
    else
        libPlatformManager:getPlatform():sendMessageG2P("G2P_CLEAN_NOTIFICATION_ONCE", "")
        libPlatformManager:getPlatform():sendMessageG2P("G2P_CLEAN_NOTIFICATION_LOOP", "")
    end
    local PushNotificationsManager = require("PushNotificationsManager")
    if PushNotificationsManager == nil or not PushNotificationsManager._bOpenAPN then
        return
    end
    local index = 10
    UserInfo.sync()
    for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
        if UserInfo.roleInfo and UserInfo.roleInfo.level and UserInfo.roleInfo.level >= Info.minLevel and UserInfo.roleInfo.level <= Info.maxLevel then
            index = index + 1
            if TimeCalculator:getInstance():hasKey(keyName) then
                -- �ʣ��ʱ��
                local leftTime = TimeCalculator:getInstance():getTimeLeft(keyName)
                if leftTime > 0 then
                    local needLoop = false
                    if Info.mType == 2 then
                        needLoop = true
                    end
                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
                        libOS:getInstance():addNotification(Info.mText, leftTime, needLoop)
                    else
                        local strtable = {
                            title = keyName,
                            timeleft = leftTime,
                            gamemsg = Info.mText,
                            action = "android.intent.action.MY_ALERT_RECEIVER_" .. index,
                            sound = Info.mSound,
                            dayloop = needLoop-- -- �Ƿ�ÿ��ѭ�� false��ʾֻ��Ӧһ��
                        }
                        local JsMsg = cjson.encode(strtable)
                        libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
                    end
                end
            end
            -- ����24Сʱ֪ͨ��������
            if Info.mType == 1 then
                local leftTime = 86400
                local time = os.time() + leftTime
                local bSilence = false
                for mID, SilenceCfg in pairs(PushNotificationsManager._SilenceCfg) do
                    local timeStart = os.time( { day = os.date("%d"), month = os.date("%m"), year = os.date("%Y"), hour = SilenceCfg._StartTime[1], minute = SilenceCfg._StartTime[2], second = SilenceCfg._StartTime[3] })
                    local timeEnd = os.time( { day = os.date("%d"), month = os.date("%m"), year = os.date("%Y"), hour = SilenceCfg._EndTime[1], minute = SilenceCfg._EndTime[2], second = SilenceCfg._EndTime[3] })
                    if time > timeStart and time < timeEnd then
                        bSilence = true
                    end
                end
                if not bSilence then
                    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_IOS then
                        libOS:getInstance():addNotification(Info.mText, leftTime, false)
                    else
                        local strtable = {
                            title = keyName,
                            timeleft = leftTime,
                            gamemsg = Info.mText,
                            action = "android.intent.action.MY_ALERT_RECEIVER_" .. index,
                            sound = Info.mSound,
                            dayloop = false-- �Ƿ�ÿ��ѭ�� false��ʾֻ��Ӧһ��
                        }
                        local JsMsg = cjson.encode(strtable)
                        libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
                    end
                end
            end
        end
    end
    local timeStr = "00:00:00"
    if TimeCalculator:getInstance():hasKey("TaskALL") then
        local nextRefreshTime = TimeCalculator:getInstance():getTimeLeft("TaskALL")
        if nextRefreshTime > 0 then
            -- timeStr = GameMaths:formatSecondsToTime(nextRefreshTime)
        elseif nextRefreshTime <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor("TaskALL")
        end
    end
    -----------************�����ϰ汾�ͻ���***************---------------
    if CC_TARGET_PLATFORM_LUA ~= common.platform.CC_PLATFORM_IOS then
        local leftTime9 = getLeftTime(9, 0, 0)
        local leftTime21 = getLeftTime(21, 0, 0)
        local strtable = {
            lefttime8 = leftTime9,
            -- �����´�9��ʱ����
            lefttime8msg = Language:getInstance():getString("@Notification8Daily"),
            lefttime20 = leftTime21,
            -- �����´�21��ʱ����
            lefttime20msg = Language:getInstance():getString("@Notification20Daily"),
            needLoop = true-- �Ƿ�ÿ��ѭ�� false��ʾֻ��Ӧһ��
        }
        local JsMsg = cjson.encode(strtable)
        -- libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg)
        local strtable24 = {
            leftgame24 = 60 * 60 * 24,
            leftgame24msg = Language:getInstance():getString("@Notification24hours"),
            needLoop = false-- �Ƿ�ÿ��ѭ�� false��ʾֻ��Ӧһ��
        }
        local JsMsg24 = cjson.encode(strtable24)
        -- libPlatformManager:getPlatform():sendMessageG2P("G2P_SHOW_NOTIFICATION", JsMsg24)
    end
    -----------***************************---------------
end
function MainFrame_onClick_onFunction(eventName, container)
    if eventName == "luaOnAnimationDone" then
        local animationName = tostring(container:getCurAnimationDoneName())
        if animationName == "InputClick" then
            local parent = container:getParent()
            -- tolua.cast(container:getParent(),'CCLayer')
            local tag = tonumber(container:getTag())
            if tag and parent then
                if parent:getChildByTag(tag) then
                    parent:removeChildByTag(tag, false)
                end
                CCBIObjectPool:Instance():PushInputClickCCBI(container)
            end
        end
    end
end
function MainFrame_onClick()
    if GameConfig.isRigistInput then
        return
    end
    GameConfig.isRigistInput = true
    local mainFrame = tolua.cast(MainFrame:getInstance(), "CCBScriptContainer")
    local layer = mainFrame:getVarNode("mNotTouch")
    local Tag = 1
    if not layer then
        layer = CCLayer:create()
        layer:setTag(100001)
        mainFrame:addChild(layer)
        layer:setContentSize(CCEGLView:sharedOpenGLView():getDesignResolutionSize())
        layer:registerScriptTouchHandler( function(eventName, pTouch)
            if eventName == "began" then

            elseif eventName == "moved" then

            elseif eventName == "ended" then
                Tag = Tag + 1
                -- local pItem = ScriptContentBase:create("ClickFx.ccbi")
                local pItem = CCBIObjectPool:Instance():PopInputClickCCBI()
                if pItem ~= nil then
                    pItem:setTag(Tag)
                    pItem:registerFunctionHandler(MainFrame_onClick_onFunction)
                    layer:addChild(pItem)
                    local point = pTouch:getLocation()
                    local point1 = layer:getParent():convertToNodeSpace(point)
                    pItem:setPosition(ccp(point1.x, point1.y))
                    pItem:runAnimation("InputClick")
                end
            elseif eventName == "cancelled" then

            end
        end
        , false, -129, false)
        layer:setTouchEnabled(true)
        layer:setVisible(true)
    end
end

-- 新手遮罩開關
function MainFrame_setGuideMask(isVisible)
    local mainFrame = tolua.cast(MainFrame:getInstance(), "CCBScriptContainer")
    --local mask = mainFrame:getVarNode("mGuideMask")
    NodeHelper:setNodesVisible(mainFrame, { mGuideMask = isVisible })
end