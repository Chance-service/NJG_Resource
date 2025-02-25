----------------------------------------------------------------------------------
-- 竞技页面 点主界面按钮显示
----------------------------------------------------------------------------------
local HP = require("HP_pb");
local CampWarManager = require("CampWarManager")
local WorldBoss_pb = require("WorldBoss_pb")
local MultiElite_pb = require("MultiElite_pb")
local GVG_pb = require("GroupVsFunction_pb")
local CsBattle_pb = require("CsBattle_pb")
local GVGManager = require("GVGManager")
local OSPVPManager = require("OSPVPManager")
local MultiEliteDataManger = require("Battle.MultiEliteDataManger")
local NewbieGuideManager = require("Guide.NewbieGuideManager")
local GuildData = require("Guild.GuildData")
local LevelReleaseFunctionList = require("LevelReleaseFunctionList")
local Arena_pb = require("Arena_pb")
local HelpFightDataManager = require("PVP.HelpFightDataManager")
local PageJumpMange = require("PageJumpMange")
local opcodes = {
    MULTI_ELITE_OPEN_TIME_C = HP.MULTI_ELITE_OPEN_TIME_C,
    MULTI_ELITE_OPEN_TIME_S = HP.MULTI_ELITE_OPEN_TIME_S,
    FETCH_WORLD_BOSS_BANNER_C = HP.FETCH_WORLD_BOSS_BANNER_C,
    FETCH_WORLD_BOSS_BANNER_S = HP.FETCH_WORLD_BOSS_BANNER_S,
    WORLD_BOSS_AUTO_JOIN_C = HP.WORLD_BOSS_AUTO_JOIN_C,
    WORLD_BOSS_AUTO_JOIN_S = HP.WORLD_BOSS_AUTO_JOIN_S,
    FETCH_WORLD_BOSS_INFO_C = HP.FETCH_WORLD_BOSS_INFO_C,
    FETCH_WORLD_BOSS_INFO_S = HP.FETCH_WORLD_BOSS_INFO_S,
    MULTIELITE_LIST_INFO_C = HP.MULTIELITE_LIST_INFO_C,
    MULTIELITE_LIST_INFO_S = HP.MULTIELITE_LIST_INFO_S,
    ELITE_ROOM_LIST_INFO_C = HP.ELITE_ROOM_LIST_INFO_C,
    MULIELTIE_ROOM_INFO_C = HP.MULIELTIE_ROOM_INFO_C,
    MULTIELITE_ROOM_MEMBER_SYNC_S = HP.MULTIELITE_ROOM_MEMBER_SYNC_S,
};

local CS_Battle_Stage = {
    NOTSTART = 0,
    -- 未开启
    SIGNUP = 2,
    -- 报名阶段
    SIGNUP_END = 3,
    -- 报名结束
    LS_KNOCKOUT = 4,
    -- 本服淘汰赛阶段
    LS_16TO8 = 6,
    -- 本服16进8阶段
    LS_8TO4 = 8,
    -- 本服8进4阶段
    LS_4TO2 = 10,
    -- 本服4进2阶段
    LS_2TO1 = 12,
    -- 本服2进1阶段
    CS_KNOCKOUT = 14,
    -- 跨服淘汰赛阶段
    CS_16TO8 = 16,
    -- 跨服16进8阶段
    CS_8TO4 = 18,
    -- 跨服8进4阶段
    CS_4TO2 = 20,
    -- 跨服4进2阶段
    CS_2TO1 = 22,
    -- 跨服2进1阶段
    FINAL_REVIEW = 24,
    -- 决赛回顾阶段
    FINISHED = 26-- 比赛结束
}
local option = {
    ccbiFile = "ManyPeopleArenaPageNew_1.ccbi",
    --ccbiFile_WIN32 = "ManyPeopleArenaPageNew_1.ccbi",
    handlerMap =
    {
        onMainRegimentWar = "onMainRegimentWar",
        onCampWar = "onCampWar",
        onGuildWar = "onGuildWar",
        onWorldBoss = "onWorldBoss",
        onRaid = "onTeamCopy",
        onAutomaticJoin = "onAutomaticJoin",
        onHelp = "onHelp",
        onReturnBtn = "onReturn",
        onManyPeopleMap = "onManyPeople",
        onCrossServerWar = "onCrossServerWar",
        onArena = "onArena",
        onGVG = "onGVG",
        onGVEAuto = "onGVEAuto",
        onPVP = "onPVP",
        onHelpFightReward = "onHelpFightReward",
        onGotoHelpFight = "onGotoHelpFight",
    }
};
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = "PVPActivityPage";

local decisionTitle = "";
local decisionMsg = "";
local decisionCB = nil;
local CSManager = require("PVP.CSManager")
local CommonPage = require("CommonPage");
local PVPActivityPage = CommonPage.new("PVPActivityPage", option);
local NodeHelper = require("NodeHelper");
local WorldBossManager = require("PVP.WorldBossManager");
local lastTimeInfo = {
    closeLeftTimeKey = 'CampLeftCDForCloseActivity',
    openLeftTimeKey = 'CampLeftCDForOpenActivity',
    RegimentWarKey = 'RegimentWarCDActivity',
}


----------------------------------------------------------------------------------
-- PVPActivityPage页面中的事件处理
----------------------------------------------
function PVPActivityPage.onEnter(container)
        container.mScrollView = container:getVarScrollView("mContent")
        --    container:registerMessage(MSG_MAINFRAME_REFRESH)
        NodeHelper:autoAdjustResizeScrollview(container.mScrollView)
        local bgScale = NodeHelper:getAdjustBgScale(1)
        if bgScale < 1 then bgScale = 1 end
        local sprite = container:getVarSprite("mScale9Sprite1");
        if sprite then
            sprite:setScale(bgScale);
        end
         -- 一个高度是 362
        container.mScrollView:setContentOffset(container.mScrollView:minContainerOffset())

    -----------------------------------------------------
    --container.mScrollView:setBounceable(false)
    -- container.mScrollView:setTouchEnabled()
    -----------------------------------------------------
    PVPActivityPage:registerPacket(container);
    PVPActivityPage:sendMsgForWorldBossBanner(container);

    NodeHelper:setNodesVisible(container, { mHelpBtnNode = false })
    -- 隐藏帮助按钮

    -- NodeHelper:autoAdjustResetNodePosition(container:getVarSprite("mBGPic"),-1)
    NodeHelper:setNodesVisible(container,
            {
                mWorldBossTitlePoint = false,
                mRaidNode = true
            } );
    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mRaidNode = false })
    end
    -- Ë¢ÐÂºìµã
    -- if not PageInfo.BattleLeftTime or PageInfo.BattleLeftTime <= 0 then
    -- 	PVPActivityPage:registerGlobalPacket( container )
    -- 	local msg = TeamBattle_pb.HPTeamBattleInfo()
    -- 	local pb_data = msg:SerializeToString()
    -- 	PacketManager:getInstance():sendPakcet(globalOpcodes.TEAM_BATTLE_INFO_C, pb_data, #pb_data, true)
    -- end
    local campWarTime = ""
    if CampWarManager.leftTime > 0 then
        if TimeCalculator:getInstance():hasKey(lastTimeInfo.closeLeftTimeKey) then
            CampWarManager.leftTime = TimeCalculator:getInstance():getTimeLeft(lastTimeInfo.closeLeftTimeKey)
        end
        campWarTime = GameMaths:formatSecondsToTime(CampWarManager.leftTime)
        TimeCalculator:getInstance():createTimeCalcultor(lastTimeInfo.closeLeftTimeKey, CampWarManager.leftTime);
    end

    local regumentLastTime = ""
    if PageInfo.BattleLeftTime > 0 then
        if TimeCalculator:getInstance():hasKey(lastTimeInfo.RegimentWarKey) then
            PageInfo.BattleLeftTime = TimeCalculator:getInstance():getTimeLeft(lastTimeInfo.RegimentWarKey)
        end
        regumentLastTime = GameMaths:formatSecondsToTime(PageInfo.BattleLeftTime)
        TimeCalculator:getInstance():createTimeCalcultor(lastTimeInfo.RegimentWarKey, PageInfo.BattleLeftTime);
    end
    NodeHelper:setStringForLabel(container, { mCampWarTime = campWarTime, mRegimentWarTime = regumentLastTime, })
    NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_PvpActivity)

    NodeHelper:setNodesVisible(container, { mGVGNode = true })
    --GVGManager.reqGVGConfig()

    PVPActivityPage:refreshOSPVPTime(container)

    if GameConfig.isIOSAuditVersion then
        NodeHelper:setNodesVisible(container, { mRaidNode = false, mWorldBossNode = false, mComingSoonNode = false })
    end

    if Golb_Platform_Info.is_win32_platform then
        NodeHelper:setNodesVisible(container, { mRaidNode = true, mWorldBossNode = true, mComingSoonNode = true })
    end
    --世界boss上鎖
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.WORLDBOSS_OPEN_LEVEL and UserInfo.hasAlliance == true then
        NodeHelper:setNodesVisible(container, { mWorldBossNode_lock = false })
    else
        NodeHelper:setNodesVisible(container, { mWorldBossNode_lock = true })
    end
    --花嫁上鎖
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MultiEliteLimitLevel then
        NodeHelper:setNodesVisible(container, { mRaidNode_lock = false })
    else
        NodeHelper:setNodesVisible(container, { mRaidNode_lock = true })
    end
    --深淵上鎖
    if HelpFightDataManager:isOpen() then
        NodeHelper:setNodesVisible(container, { mHelpFightNode_lock = false })
    else
        NodeHelper:setNodesVisible(container, { mHelpFightNode_lock = true })
    end

    if PageJumpMange._IsPageJump then
        if PageJumpMange._CurJumpCfgInfo._SecondFunc ~= "" then
            PVPActivityPage[PageJumpMange._CurJumpCfgInfo._SecondFunc](container)
        end
        if PageJumpMange._CurJumpCfgInfo._ThirdFunc == "" then
            PageJumpMange._IsPageJump = false
        end
    end
    --    local scale = NodeHelper:getAdjustBgScale(0)
    --    if scale >= 1 then scale = 1 end
    --    local adjustNode = container:getVarNode("mAdjustNode")
    --    adjustNode:setScale(scale)

    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["PVPActivityPage"] = container
    PVPActivityPage.refreHelpFightRoleHeadIcon(container)
end

function PVPActivityPage.onExecute(container)
    PVPActivityPage.refreshRegimentRedPoint(container)
    PVPActivityPage.refreshCampWarRedPoint(container)

    local campWarTime = ""
    if TimeCalculator:getInstance():hasKey(lastTimeInfo.closeLeftTimeKey) then
        local leftTime = TimeCalculator:getInstance():getTimeLeft(lastTimeInfo.closeLeftTimeKey)
        CampWarManager.leftTime = leftTime
        campWarTime = GameMaths:formatSecondsToTime(leftTime)
    end

    --[[local ArenaInfo = require("ArenaPage")
    local mArenaPoint = container:getVarNode("mMPArenaPoint")
    local mRemainingChallengesNum1 = ArenaInfo.SelfInfo.surplusChallengeTimes
    if mRemainingChallengesNum1 <= 0 then
    	mArenaPoint:setNodesVisible(false)
    end]]
    --

    local regumentLastTime = ""
    if TimeCalculator:getInstance():hasKey(lastTimeInfo.RegimentWarKey) then
        local leftTime = TimeCalculator:getInstance():getTimeLeft(lastTimeInfo.RegimentWarKey)
        PageInfo.BattleLeftTime = leftTime
        regumentLastTime = GameMaths:formatSecondsToTime(leftTime)
    end

    NodeHelper:setStringForLabel(container, { mCampWarTime = campWarTime, mRegimentWarTime = regumentLastTime, })

    PVPActivityPage.refreshArenaRedPoint(container)
    PVPActivityPage.refreshWorldBossRedPoint(container)
    PVPActivityPage.refreshMultiEliteRedPoint(container)

    PVPActivityPage.refreshHelpFightRedPoint(container)

    -- CSManager.refreshCrossServerWarRedPoint( container )
end

function PVPActivityPage.isShowPVPActivityRedPoint()
    UserInfo.syncRoleInfo()
    local level = UserInfo.roleInfo.level
    local ArenaData = require("Arena.ArenaData")
    local ChallengeTimes = ArenaData.getArenaChallengeTimes()
    local ArenaFight = level >= GameConfig.Default.ArenaOpenLvLimit and ChallengeTimes > 0
    
    if ArenaFight then
        return true
    else
        return false
    end
end

function PVPActivityPage.isShowEventActivityRedPoint()
    UserInfo.syncRoleInfo()
    local level = UserInfo.roleInfo.level
    local CampWarManager = require("PVP.CampWarManager")
    local worldBossFlag = NoticePointState.WORlDBOSS_POINT  and level >= GameConfig.WORLDBOSS_OPEN_LEVEL and UserInfo.hasAlliance
    local multiElite = tonumber(level) > tonumber(GameConfig.MultiEliteLimitLevel) and MultiEliteDataManger:getNotice()

    if worldBossFlag or multiElite  then
        return true
    else
        return false
    end
end

function PVPActivityPage.onHelpFightReward(container)
    if HelpFightDataManager:isOpen() then
        PageManager.pushPage("HelpFightOtherRewardPopUp")
    else
        MessageBoxPage:Msg_Box_Lan( common:getLanguageString( "@Eighteentip7"))
    end
end

function PVPActivityPage.onGotoHelpFight(container)
    if HelpFightDataManager:isOpen() then
        PageManager.changePage("HelpFightMapPage")
    else
        MessageBoxPage:Msg_Box_Lan( common:getLanguageString( "@Eighteentip7"))
    end
end

function PVPActivityPage.refreshCampWarRedPoint(container)
    local CampWarManager = require("PVP.CampWarManager")
    local flag = CampWarManager.isShowCampRedPoint()
    NodeHelper:setNodesVisible(container,
    {
        mCampWarPoint = worldBossFlag
    } );

end

function PVPActivityPage.refreshRegimentRedPoint(container)
    NodeHelper:setNodesVisible(container,
    {
        mRegimentWarPoint = NoticePointState.REGINMENTWAR_POINT
    } );
end

function PVPActivityPage.refreshWorldBossRedPoint(container)
    NodeHelper:setNodesVisible(container,
    {
        mWorldBossTitlePoint = NoticePointState.WORlDBOSS_POINT and UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.WORLDBOSS_OPEN_LEVEL
    } );
end
function PVPActivityPage.refreshMultiEliteRedPoint(container)
    UserInfo.syncRoleInfo()
    local level = UserInfo.roleInfo.level
    if tonumber(level) < GameConfig.MultiEliteLimitLevel then
        NodeHelper:setNodesVisible(container, { mRaidTitlePoint = false })
        return
    end
    MultiEliteDataManger.mapInfo = MultiEliteDataManger.mapInfo or { }
    MultiEliteDataManger.mapInfo.todayLeftTimes = MultiEliteDataManger.mapInfo.todayLeftTimes or 0
    NodeHelper:setNodesVisible(container,
    {
        mRaidTitlePoint = MultiEliteDataManger:getNotice()
    } );
end

function PVPActivityPage.refreshHelpFightRedPoint(container)
    local isRed =  HelpFightDataManager:isOpen() and HelpFightDataManager:returnNotice()
    NodeHelper:setNodesVisible(container, { mHelpFightRewarPoint = isRed} );
end

function PVPActivityPage.refreshArenaRedPoint(container)
    local ArenaData = require("Arena.ArenaData")
    local level = UserInfo.roleInfo.level
    local isRed = ArenaData and level >= GameConfig.Default.ArenaOpenLvLimit and ArenaData.getArenaChallengeTimes() > 0
    NodeHelper:setNodesVisible(container, { mArenaTitlePoint = isRed} );
end

function PVPActivityPage.refreHelpFightRoleHeadIcon(container)
    if  HelpFightDataManager.myHelpMercenary then
        local icon = common:getPlayeIcon(1,HelpFightDataManager.myHelpMercenary[1].roleItemId)
        NodeHelper:setSpriteImage(container,{mPic = icon})
    else
        NodeHelper:setSpriteImage(container,{mPic = "Imagesetfile/HelpFight/Kingdom_myEmptyHelpFight.png"})
    end
    local sprite = container:getVarSprite("mPic")
    if sprite then
        sprite:setVisible(false)
    end
end



function PVPActivityPage:refreshMultiEliteTimeButton(container)

    if #MultiEliteDataManger.StartTime == 2 and #MultiEliteDataManger.EndTime == 2 then
        local time1 = tonumber(MultiEliteDataManger.StartTime[1]) / 1000
        local time2 = tonumber(MultiEliteDataManger.StartTime[2]) / 1000
        local time3 = tonumber(MultiEliteDataManger.EndTime[1]) / 1000
        local time4 = tonumber(MultiEliteDataManger.EndTime[2]) / 1000
        local timeStr1 = os.date("%H:%M", time1)
        local timeStr2 = os.date("%H:%M", time2)
        local timeStr3 = os.date("%H:%M", time3)
        local timeStr4 = os.date("%H:%M", time4)
        local TimeStr = timeStr1 .. "-" .. timeStr3 .. "\n" .. timeStr2 .. "-" .. timeStr4


        local lb2Str = {
            mRaidOpeningTime = TimeStr
        }
        NodeHelper:setStringForLabel(container, lb2Str);
    end
    -- if MultiEliteDataManger:getMapInfo().curDayBattleTimes and MultiEliteDataManger:getMapInfo().curDayBattleTimes > 0 then
    -- 	NodeHelper:setStringForLabel(container,{mRaidInfoTxt = ""})
    -- 	NodeHelper:setNodesVisible(container,{mRewardIcon = false})
    -- else
    -- 	NodeHelper:setStringForLabel(container,{mRaidInfoTxt = common:getLanguageString("@RaidRewardInfoTxt")})
    -- 	NodeHelper:setNodesVisible(container,{mRewardIcon = true})
    -- end
end

function PVPActivityPage:refreshGVGTime(container)
    local time1 = GVGManager.getDeclareStartTime()
    local time2 = GVGManager.getDeclareEndTime()
    local time3 = GVGManager.getFightingStartTime()
    local time4 = GVGManager.getFightingEndTime()
    local TimeStr = common:getLanguageString("@GVGDeclareTime", time1, time2) .. "\n" .. common:getLanguageString("@GVGFightingTime", time3, time4)

    local lb2Str = {
        mGVGOpeningTime = TimeStr
    }
    NodeHelper:setStringForLabel(container, lb2Str);
end


function PVPActivityPage:refreshWorldBossButton(container)

    -- 显示时间
    -- 秒转化成小时
    local state = WorldBossManager.BossState
    local cancelStr = ""
    if state == 3 then
        cancelStr = common:getLanguageString("@GVEOpenBtnTxt")
    else
        cancelStr = common:getLanguageString("@GVEAutoBtnTxt")
    end

    local lb2Str = {
        mCancel = cancelStr
    }
    if #WorldBossManager.StartTime == 2 then
        local time1 = tonumber(WorldBossManager.StartTime[1]) / 1000
        local time2 = tonumber(WorldBossManager.StartTime[2]) / 1000

        local timeStr1 = os.date("%H:%M", time1)
        local timeStr2 = os.date("%H:%M", time2)

        local TimeStr = common:getLanguageString("@GVEOpeningTimeTxt", timeStr1, timeStr2)

        lb2Str.mOpeningTimesTxt = TimeStr
    end
    NodeHelper:setStringForLabel(container, lb2Str);
end

function PVPActivityPage:refreshOSPVPTime(container)
    local lb2Str = { }
    lb2Str.mPVPOpeningTime = string.format("\n%s", common:getLanguageString("@OSPVPTime1"))
    -- ,common:getLanguageString("@OSPVPTime2"))
    NodeHelper:setStringForLabel(container, lb2Str);
end


---------点击事件----------
function PVPActivityPage.onExit(container)
    local GVGManager = require("GVGManager")
    GVGManager.isGVGPageOpen = false
    PVPActivityPage:removePacket(container)
    onUnload(thisPageName, container)
end

function PVPActivityPage.onHelp(container)
    -- CCLuaLog("........");
    PageManager.showHelp(GameConfig.HelpKey.HELP_PVP)

end

function PVPActivityPage.onReturn(container)
    MainFrame_onMainPageBtn()
end

function PVPActivityPage.onGVG(container)
    local UserInfo = require("PlayerInfo.UserInfo")
    if UserInfo.roleInfo.level < 12 then
        -- 主将12级开起联盟城战
        MessageBoxPage:Msg_Box_Lan("@GVGLowLevel")
        return
    end
    local GVGManager = require("GVGManager")
    --"GuildPage"
    GVGManager.setFromPage(thisPageName)
    --GVGManager.setFromPage("GuildPage")
    if GVGManager.isGVGOpen then
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    else
        GVGManager.reqVitalityRank()
    end
end

function PVPActivityPage.onPVP(container)
    -- OSPVPManager.initAllCfg()
    if UserInfo.roleInfo.level < GameConfig.Default.OSPVPOpenLvLimit then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@OSPVPOpenLimit", GameConfig.Default.OSPVPOpenLvLimit))
        return
    end
    -- if OSPVPManager:getSystemStatus() ~= CsBattle_pb.NORMAL then
    OSPVPManager.isEnter = true
    OSPVPManager.reqVSInfo()
    -- else
    -- PageManager.changePage("OSPVPPage")
    -- end
end

function PVPActivityPage_onArena()
    PVPActivityPage.onArena(container)
end

function PVPActivityPage.onArena(container)
    if UserInfo.roleInfo.level < GameConfig.Default.ArenaOpenLvLimit then
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@ArenaLimit", GameConfig.Default.ArenaOpenLvLimit))
        return
    end
    PageManager.changePage("ArenaPage")
end

function PVPActivityPage.onMainRegimentWar(container)
    if UserInfo.roleInfo.fight < GameConfig.TeamBattleLimit then
        MessageBoxPage:Msg_Box_Lan("@TeamBattleLimit")
        return
    end
    PageManager.changePage("RegimentWarPage");
end

function PVPActivityPage.onCampWar(container)
    local CampWarManager = require("PVP.CampWarManager")
    CampWarManager.EnterPageByState()
end

function PVPActivityPage.onGuildWar(container)
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.ALLIANCE_OPEN_LEVEL then
        local AllianceBattle_pb = require("AllianceBattle_pb")
        local HP_pb = require("HP_pb")
        local msg = AllianceBattle_pb.HPAFMainEnter();
        common:sendPacket(HP_pb.ALLIANCE_BATTLE_ENTER_C, msg);
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@AllianceLevelNotReached', GameConfig.ALLIANCE_OPEN_LEVEL))
    end
end

function PVPActivityPage.onWorldBoss_1(container)
    PVPActivityPage.onWorldBoss(container)
end

function PVPActivityPage.onWorldBoss(container)
    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.WORLDBOSS_OPEN_LEVEL then
       if   UserInfo.hasAlliance == true   then
            PVPActivityPage:sendMsgForWorldBossinfo(container);
        else
            MessageBoxPage:Msg_Box(common:getLanguageString('@JoinAlliance'))
        end
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@worldBossLimit', GameConfig.WORLDBOSS_OPEN_LEVEL))
    end
end



function PVPActivityPage.onGVEAuto(container)

    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.WORLDBOSS_OPEN_LEVEL then
        if GuildData.MyAllianceInfo.hasAlliance then
            local state = WorldBossManager.BossState
            if state ~= 3 then
                PageManager.pushPage("GVEAutoFightSelectPage")
            else
                -- PVPActivityPage:sendMsgForWorldBossinfo(container)
                MessageBoxPage:Msg_Box(common:getLanguageString("@GVEOpening"))
            end
        else
            MessageBoxPage:Msg_Box(common:getLanguageString('@JoinAlliance'))
        end
    else
        MessageBoxPage:Msg_Box(common:getLanguageString('@worldBossLimit', GameConfig.WORLDBOSS_OPEN_LEVEL))
    end

end



function PVPActivityPage.onTeamCopy(container)
    UserInfo.sync()
    if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MultiEliteLimitLevel then
        PVPActivityPage:sendMsgForTeamCopyinfo(container)
    else
        local meg = common:getLanguageString("@MultiMapOpen", GameConfig.MultiEliteLimitLevel)
        MessageBoxPage:Msg_Box(meg)
    end
    -- PageManager.changePage("WorldBossFinalpage");
end

function PVPActivityPage.onAutomaticJoin(container)

    -- vip等级的比较
    local vipLevel = UserInfo.playerInfo.vipLevel;
    if tonumber(vipLevel) < 1 then
        MessageBoxPage:Msg_Box_Lan("@AutoJoinNeedVIP1")
    else
        PVPActivityPage:sendMsgForAutoJoin(container);
    end

end

function PVPActivityPage.onManyPeople(container)
    UserInfo.syncRoleInfo()
    local level = UserInfo.roleInfo.level
    if tonumber(level) < GameConfig.MultiEliteLimitLevel then
        MessageBoxPage:Msg_Box_Lan("@MultiEliteEnterLevelLimit")
        return
    end
    common:sendEmptyPacket(HP_pb.MULTIELITE_LIST_INFO_C, false)
end

function PVPActivityPage.onCrossServerWar(container)
    UserInfo.sync()
    if not UserInfo.stateInfo.isCSOPen then
        MessageBoxPage:Msg_Box_Lan("@CSNotBegin")
        return
    end

    if UserInfo.roleInfo.level < 50 then
        MessageBoxPage:Msg_Box_Lan("@CSLevelNotEnough")
        return
    end

    PageManager.changePage("CrossServerWar")
end
-------------------------------------------------------
function PVPActivityPage:sendMsgForAutoJoin(container)
    -- PacketManager:getInstance():sendPakcet(opcodes.WORLD_BOSS_AUTO_JOIN_C,"",0, true)
    common:sendEmptyPacket(opcodes.WORLD_BOSS_AUTO_JOIN_C, false)
end


function PVPActivityPage:sendMsgForWorldBossBanner(container)
    -- PacketManager:getInstance():sendPakcet(opcodes.FETCH_WORLD_BOSS_BANNER_C, "", 0, true);
    common:sendEmptyPacket(opcodes.MULTI_ELITE_OPEN_TIME_C, true)
    common:sendEmptyPacket(opcodes.FETCH_WORLD_BOSS_BANNER_C, true)
end

function PVPActivityPage:sendMsgForWorldBossinfo(container)
    --    PacketManager:getInstance():sendPakcet(opcodes.FETCH_WORLD_BOSS_INFO_C, "", 0, true);
    common:sendEmptyPacket(opcodes.FETCH_WORLD_BOSS_INFO_C, true)
end

function PVPActivityPage:sendMsgForTeamCopyinfo(container)
    --    PacketManager:getInstance():sendPakcet(opcodes.FETCH_WORLD_BOSS_INFO_C, "", 0, true);
    common:sendEmptyPacket(opcodes.MULTIELITE_LIST_INFO_C, false)
end


function PVPActivityPage.onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.TEAM_BATTLE_SYNC_S then
        local msg = TeamBattle_pb.HPTeamBattleSyncS()
        msg:ParseFromString(msgBuff)
        PageInfo.BattleLeftTime = msg.period

        local regumentLastTime = ""
        if PageInfo.BattleLeftTime > 0 then
            regumentLastTime = GameMaths:formatSecondsToTime(PageInfo.BattleLeftTime)
            TimeCalculator:getInstance():createTimeCalcultor(lastTimeInfo.RegimentWarKey, PageInfo.BattleLeftTime);
        end
        NodeHelper:setStringForLabel(container, { mRegimentWarTime = regumentLastTime, })
    end
    if opcode == opcodes.FETCH_WORLD_BOSS_BANNER_S then
        local msg = WorldBoss_pb.HPWorldBossBannerInfo();
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveHPWorldBossBannerInfo(msg)
        PVPActivityPage:refreshWorldBossButton(container)
        return
    end
    if opcode == opcodes.MULTI_ELITE_OPEN_TIME_S then
        local msg = MultiElite_pb.HPMultiEliteTimeOrBattleTimes();
        msg:ParseFromString(msgBuff)
        MultiEliteDataManger:ReceiveMultiEliteTimeOrBattleTimes(msg)
        PVPActivityPage:refreshMultiEliteTimeButton(container)
        return
    end


    if opcode == opcodes.FETCH_WORLD_BOSS_INFO_S then
        local msg = WorldBoss_pb.HPWorldBossInfo();
        msg:ParseFromString(msgBuff)
        WorldBossManager.enterFinalPageFrom = 1
        -- WorldBossManager.ReceiveHPWorldBossInfo_InBanner(msg)
        WorldBossManager.ReceiveHPWorldBossInfo(msg)
        WorldBossManager.EnterPageByState()
        return
    end

    if opcode == opcodes.MULTIELITE_ROOM_MEMBER_SYNC_S then
        local msg = MultiElite_pb.HPMultiEliteRoomMemberSync()
        msg:ParseFromString(msgBuff)
        MultiEliteDataManger:setRoomMembers(msg)
        PageManager.changePage("MultiEliteRoomMembersPage")
        return
    end

    if opcode == opcodes.MULTIELITE_LIST_INFO_S then
        local msg = MultiElite_pb.HPMultiEliteListInfoRet()
        msg:ParseFromString(msgBuff)
        MultiEliteDataManger:setMapInfo(msg)
        if msg:HasField("curBattleMapId") and msg:HasField("curRoomId") then
            common:sendEmptyPacket(opcodes.MULIELTIE_ROOM_INFO_C, false)
        else
            local ActionLog_pb = require("ActionLog_pb")
            local HP_pb = require("HP_pb")
            local Const_pb = require("Const_pb");
            local message = ActionLog_pb.HPActionRecord()
            if message ~= nil then
                message.activityId = Const_pb.MODULE_MULTIELITE;
                message.actionType = Const_pb.MULTIELITE_INTO;
                local pb_data = message:SerializeToString();
                PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false);
            end
            PageManager.changePage("MultiEliteMapPage")
        end

        return
    end

end


function PVPActivityPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function PVPActivityPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function PVPActivityPage.onReceiveMessage(container, message)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onMapInfo then
                -- local status = GVGManager.getGVGStatus()
                -- if status ~= GVG_pb.GVG_STATUS_WAITING then
                if GVGManager.isGVGPageOpen then
                    --PageManager.changePage("GVGMapPage")
                end
                -- else
                -- PageManager.changePage("GVGPreparePage")
                -- end
            elseif extraParam == GVGManager.onGVGConfig then
                PVPActivityPage:refreshGVGTime(container)
            elseif extraParam == GVGManager.onTodayRank then
                if not GVGManager.isGVGOpen then
                    PageManager.changePage("GVGPreparePage")
                end
            end
        elseif pageName == thisPageName then
            if extraParam == "WorldBoss" then
                PVPActivityPage:refreshWorldBossButton(container)
            elseif extraParam == "refreshHelpFightIcon" then
                PVPActivityPage.refreHelpFightRoleHeadIcon(container)
            end
        elseif pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onSystemStatus then
                if OSPVPManager.isEnter then
                    OSPVPManager.isEnter = false
                    PageManager.changePage("OSPVPPage")
                end
            end
        end
    end
end

function PVPActivityPage_setNewCCBFILE(isNew)
    if isNew then
        option.ccbiFile = "ManyPeopleArenaPageNew.ccbi"
    else
        option.ccbiFile = "ManyPeopleArenaPage.ccbi"
    end
    PageManager.changePage("PVPActivityPage")
end
--[[local CommonPage = require("CommonPage");
local PVPActivityPage = CommonPage.new("PVPActivityPage", option);]]

return PVPActivityPage

