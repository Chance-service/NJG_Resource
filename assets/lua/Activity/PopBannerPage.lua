------------------------------------------------------------------------------------
---- 公告頁面
------------------------------------------------------------------------------------
local HP = require("HP_pb");
require("Activity.ActivityConfig");
require("Activity.ActivityInfo");
local MultiEliteDataManger = require("Battle.MultiEliteDataManger")
local WorldBossManager = require("PVP.WorldBossManager")

local BannerCfg = ConfigManager:getBannerCfg()
local option = {
    ccbiFile = "PopBanner.ccbi",
    --ccbiFile_WIN32 = "ManyPeopleArenaPageNew_1.ccbi",
    handlerMap =
    {
        onReturnBtn = "onReturn",
    }
};

local opcodes = {
    -- 每日副本
    MULTIELITE_LIST_INFO_C = HP.MULTIELITE_LIST_INFO_C,
    MULTIELITE_LIST_INFO_S = HP.MULTIELITE_LIST_INFO_S,
    MULIELTIE_ROOM_INFO_C = HP.MULIELTIE_ROOM_INFO_C,
    -- World Boss
    FETCH_WORLD_BOSS_INFO_C = HP.FETCH_WORLD_BOSS_INFO_C,
    FETCH_WORLD_BOSS_INFO_S = HP.FETCH_WORLD_BOSS_INFO_S,
}

local maxBanner = 6
local bannerHeight = 270
local countBanner = #BannerCfg
local countDownTime = {}
local multiCountDownKey = "MULTI_REFRESH_TIME"
local worldbossCountDownKey = "WORLDBOSS_REFRESH_TIME"

for i = 1, countBanner do
    option.handlerMap["onBanner_" .. i] = "onTouchBanner";
end

local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = "PopBannerPage";

local CommonPage = require("CommonPage");
local PopBannerPage = CommonPage.new("PopBannerPage", option);
local NodeHelper = require("NodeHelper");

local htmlTimeLabel = {}

----------------------------------------------------------------------------------
-- PopBannerPage页面中的事件处理
----------------------------------------------
function PopBannerPage.onEnter(container)
    container.mScrollView = container:getVarScrollView("mContent")

    container:getVarNode("mPanel"):setContentSize(CCSizeMake(container:getVarNode("mPanel"):getContentSize().width, bannerHeight * countBanner + 160))
    container:getVarNode("mContentNode"):setPositionY(1760 - bannerHeight *  (maxBanner - countBanner))
    container:getVarNode("mPanel"):setPositionY(-580 + bannerHeight *  (maxBanner - countBanner))

    local imgMap = {}
    countDownTime[multiCountDownKey] = 0
    for i = 1, maxBanner do 
        if i <= countBanner then
            imgMap["mPopBanner_" .. i] = BannerCfg[i].Image .. ".png"
            if BannerCfg[i].activityId == ActivityConfig.RAID or BannerCfg[i].activityId == ActivityConfig.WORLD_BOSS then       
                htmlTimeLabel[BannerCfg[i].activityId] = CCHTMLLabel:createWithString((FreeTypeConfig[10097] and FreeTypeConfig[10097].content), CCSizeMake(415, 10))
                container:getVarLabelTTF("mTimeTxt" .. i):addChild(htmlTimeLabel[BannerCfg[i].activityId])
                htmlTimeLabel[BannerCfg[i].activityId]:setAnchorPoint(ccp(0, 0))
                htmlTimeLabel[BannerCfg[i].activityId]:setPositionY(2)
            end
        end
        container:getVarSprite("mPopBanner_" .. i):setVisible(i <= countBanner)
        NodeHelper:setStringForLabel(container, { ["mTimeTxt" .. i] = "" })
        local actId = BannerCfg[i] and BannerCfg[i].activityId
        if actId and ActivityConfig[actId] and ActivityConfig[actId].activityType then
            if ActivityConfig[actId].activityType == ActivityConfig.RAID or ActivityConfig[actId].activityType == ActivityConfig.WORLD_BOSS then
                NodeHelper:setNodesVisible(container, { ["mCountTxt" .. i] = true })
                NodeHelper:setStringForLabel(container, { ["mCountTxt" .. i] = common:getLanguageString("@RaidMapTimesTxt", "") })
            else
                NodeHelper:setNodesVisible(container, { ["mCountTxt" .. i] = false })
            end
        else
            NodeHelper:setNodesVisible(container, { ["mCountTxt" .. i] = false })
        end
    end
    NodeHelper:setSpriteImage(container, imgMap)
    container.mScrollView:setTouchEnabled(countBanner > 4)

    CCUserDefault:sharedUserDefault():setStringForKey("OpenPopBanner" .. UserInfo.playerInfo.playerId, tostring(GamePrecedure:getInstance():getServerTime()))

    PopBannerPage:getMapInfo(container)
    PopBannerPage:getWorldBossInfo(container)

    PopBannerPage:registerPacket(container)
end

function PopBannerPage.onExecute(container, dt)
    local serverTime = os.time()  -- 當前的Unix Time
    local serverTimeTable = os.date("!*t", serverTime + GameConfig.SaveingTime * 3600)  -- 轉換成table格式(+8hr)
    serverTimeTable.day = serverTimeTable.day + 1
    serverTimeTable.hour = 0
    serverTimeTable.min = 0
    serverTimeTable.sec = 0
    local serverTime2 = os.time(serverTimeTable)    -- 隔天00:00:00的Unix Time
    local diffTime = os.difftime(serverTime2, serverTime)
    local h = math.floor(diffTime / 3600)
    local m = math.floor((diffTime - h * 3600) / 60)

    local timeStr = (FreeTypeConfig[10097] and FreeTypeConfig[10097].content) or ""
    timeStr = GameMaths:replaceStringWithCharacterAll(timeStr, "#v1#", h)
    timeStr = GameMaths:replaceStringWithCharacterAll(timeStr, "#v2#", m)
    htmlTimeLabel[ActivityConfig.RAID]:setString(timeStr)

    local worldbossType = WorldBossManager.BossState
    local worldbossTimeStr = ""
    if TimeCalculator:getInstance():hasKey(worldbossCountDownKey) then
		local leftTime = TimeCalculator:getInstance():getTimeLeft(worldbossCountDownKey)
		if leftTime >= 0 then
            h = math.floor(leftTime / 3600)
            m = math.floor((leftTime - h * 3600) / 60)
            if worldbossType == 1 or  -- 戰鬥結束
               worldbossType == 2 then  -- 戰鬥前30分
                worldbossTimeStr = (FreeTypeConfig[10099] and FreeTypeConfig[10099].content) or ""
            elseif worldbossType == 3 then  -- 戰鬥中
                worldbossTimeStr = (FreeTypeConfig[10098] and FreeTypeConfig[10098].content) or ""
            end
            worldbossTimeStr = GameMaths:replaceStringWithCharacterAll(worldbossTimeStr, "#v1#", h)
            worldbossTimeStr = GameMaths:replaceStringWithCharacterAll(worldbossTimeStr, "#v2#", m)
		end
	end
    htmlTimeLabel[ActivityConfig.WORLD_BOSS]:setString(worldbossTimeStr)
end

function PopBannerPage.onNovice(activityId)
    -- 新手活动
    CCLuaLog("新手活动")
    require("LimitActivityPage")
    local checkAct = false
    for i = 1, #ActivityInfo.NovicePageIds do
        if ActivityInfo.NovicePageIds[i] == activityId then
            checkAct = true
            break
        end
    end
    if not checkAct then -- not openAct
        CCLuaLog("新手活动未開啟")
        return
    end
    --MainScenePageInfo.onActionRecord(container, activityId, Const_pb.RED_POINT_INTO)
    LimitActivityPage_setPart(activityId)
    LimitActivityPage_setIds(ActivityInfo.NovicePageIds)
    LimitActivityPage_setCurrentPageType(0)
    LimitActivityPage_setTitleStr("@NewbieActTitle")
    PageManager.changePage("LimitActivityPage");
end
function PopBannerPage.onNiudan(activityId)

    local FetterManager = require("FetterManager")
    FetterManager.clear()
    FetterManager.reqFetterInfo()

    require("GashaponPage")
    local checkAct = false
    for i = 1, #ActivityInfo.NiuDanPageIds do
        if ActivityInfo.NiuDanPageIds[i] == activityId then
            checkAct = true
            break
        end
    end
    if not checkAct then -- not openAct
        CCLuaLog("扭蛋活动未開啟")
        return
    end
    --local GuideManager = require("Guide.GuideManager")
    local FetterManager = require("FetterManager")
    local cur,total = FetterManager.getIllCollectRate()
    if --[[GuideManager.currGuide[GuideManager.guideType.MERCENARY_GUIDE] ~= 0]] cur <= 0 and UserInfo.roleInfo.level < 8 then   --等級不足
        MessageBoxPage:Msg_Box_Lan(common:getLanguageString("@LevelRelease18"))
        return
    end
    GashaponPage_setPart(activityId)
    GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
    GashaponPage_setTitleStr("@NiuDanTitle")
    PageManager.changePage("GashaponPage")
    resetMenu("mGuildPageBtn", true)
end
function PopBannerPage.onWelfare(activityId)
    require("WelfarePage")
    local checkAct = false
    for i = 1, #ActivityInfo.OtherPageids do
        if ActivityInfo.OtherPageids[i] == activityId then
            checkAct = true
            break
        end
    end
    if not checkAct then -- not openAct
        CCLuaLog("特典活动未開啟")
        return
    end
    WelfarePage_setPart(activityId)
    PopBannerPage.onReturn()
    PageManager.pushPage("WelfarePage")
end
function PopBannerPage.onLimitAct(activityId)
    CCLuaLog("限定活动")

    FetterManager.clear()
    FetterManager.reqFetterInfo()

    require("LimitActivityPage")
    local ActionLog_pb = require("ActionLog_pb")
    local message = ActionLog_pb.HPActionRecord()
    local checkAct = false
    for i = 1, #ActivityInfo.LimitPageIds do
        if ActivityInfo.LimitPageIds[i] == activityId then
            checkAct = true
            break
        end
    end
    if not checkAct then -- not openAct
        CCLuaLog("限定活动未開啟")
        return
    end
    if message ~= nil then
        message.activityId = activityId;
        message.actionType = Const_pb.RED_POINT_INTO
        local pb_data = message:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.ACTION_INTO_RECORD_C, pb_data, #pb_data, false);
    end

    LimitActivityPage_setPart(activityId)
    LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
    local startIndex = 0
    LimitActivityPage_setCurrentPageType(1)
    LimitActivityPage_setTitleStr("@FixedTimeActTitle")
    PageManager.changePage("LimitActivityPage")
end

function PopBannerPage.onBannerByOrder(num)
    local actId = BannerCfg[num].Page
    if actId == 0 then
        return
    end
    if actId and ActivityConfig[actId].activityType then
        if ActivityConfig[actId].activityType == ActivityConfig.RAID then  -- 修學旅行
            local UserInfo = require("PlayerInfo.UserInfo")
            UserInfo.sync()
            if UserInfo.roleInfo and UserInfo.roleInfo.level >= GameConfig.MultiEliteLimitLevel then
                --common:sendEmptyPacket(opcodes.MULTIELITE_LIST_INFO_C, true)
                PageManager.changePage("MultiEliteMapPage")
            else
                local meg = common:getLanguageString("@MultiMapOpen", GameConfig.MultiEliteLimitLevel)
                MessageBoxPage:Msg_Box(meg)
            end
        elseif ActivityConfig[actId].activityType == ActivityConfig.EXPEDITION then  -- 遠足
            MainFrame_onEquipmentPageBtn()
        elseif ActivityConfig[actId].activityType == ActivityConfig.WORLD_BOSS then -- 世界BOSS
            PageManager.changePage("WorldBossFinalpage")
        else
            CCLuaLog("活動種類無法辨識")
        end
    end
end

function PopBannerPage.onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.MULTIELITE_LIST_INFO_S then
        local msg = MultiElite_pb.HPMultiEliteListInfoRet()
        msg:ParseFromString(msgBuff)
        MultiEliteDataManger:setMapInfo(msg)
        for i = 1, maxBanner do 
            local actId = BannerCfg[i] and BannerCfg[i].activityId
            if actId and ActivityConfig[actId] and ActivityConfig[actId].activityType then
                if ActivityConfig[actId].activityType == ActivityConfig.RAID then
                    NodeHelper:setNodesVisible(container, { ["mCountTxt" .. i] = true })
                    NodeHelper:setStringForLabel(container, { ["mCountTxt" .. i] = common:getLanguageString("@RaidMapTimesTxt", tonumber(MultiEliteDataManger:getMapInfo().todayLeftTimes)) })
                end
            end
        end
    elseif opcode == opcodes.FETCH_WORLD_BOSS_INFO_S then
        local msg = WorldBoss_pb.HPWorldBossInfo()
        msg:ParseFromString(msgBuff)
        WorldBossManager.ReceiveHPWorldBossInfo(msg)
        TimeCalculator:getInstance():createTimeCalcultor(worldbossCountDownKey, WorldBossManager.leftTime)
        for i = 1, maxBanner do 
            local actId = BannerCfg[i] and BannerCfg[i].activityId
            if actId and ActivityConfig[actId] and ActivityConfig[actId].activityType then
                if ActivityConfig[actId].activityType == ActivityConfig.WORLD_BOSS then
                    NodeHelper:setNodesVisible(container, { ["mCountTxt" .. i] = true })
                    NodeHelper:setStringForLabel(container, { ["mCountTxt" .. i] = common:getLanguageString("@RaidMapTimesTxt", WorldBossManager.challengTime) })
                end
            end
        end
    end
end

function PopBannerPage:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function PopBannerPage:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end
---------点击事件----------
function PopBannerPage.onExit(container)
 -- PopBannerPage:removePacket(container)
    onUnload(thisPageName, container)
    PopBannerPage:removePacket(container)
    TimeCalculator:getInstance():removeTimeCalcultor(worldbossCountDownKey)
end

function PopBannerPage.onReturn(container)
    --PageManager.popPage(thisPageName)
    MainFrame_onMainPageBtn()
end

function PopBannerPage.onTouchBanner(container,eventName )
    local index = tonumber(string.sub(eventName, -1));
   PopBannerPage.onBannerByOrder(index)
end

function PopBannerPage:getMapInfo(container)
	common:sendEmptyPacket(HP_pb.MULTIELITE_LIST_INFO_C, false)
end
function PopBannerPage:getWorldBossInfo(container)
	common:sendEmptyPacket(HP_pb.FETCH_WORLD_BOSS_INFO_C)
end

return PopBannerPage

