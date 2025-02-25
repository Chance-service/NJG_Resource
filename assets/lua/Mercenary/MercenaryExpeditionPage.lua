----------------------------------------------------------------------------------
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local MercenaryExpedition_pb = require("MercenaryExpedition_pb")
local Recharge_pb = require "Recharge_pb"
local UserInfo = require("PlayerInfo.UserInfo")
local PushNotificationsManager = require("PushNotificationsManager")
local UserMercenaryManager = require("UserMercenaryManager")
local thisPageName = "MercenaryExpeditionPage"
local MercenaryExpeditionPage = {}
local MercenaryExpeditionCfg = {}
local MercenaryRewardPreviewCfg = nil
MercenaryExpeditionPage.IsInThisPage = false;
local roleConfig = {}
local _mercenaryInfos = {}
local mContainer = nil
local CountDownHandler=nil
_mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
local TaskContent = {
    ccbiFile = "MercenaryExpeditionSendContent.ccbi",
}
local TaskInfo = {
    allTask = {},
    curTimes = 0,
    allTimes = 0,
    refreshCost = 50,
    nextRefreshTime = 0
}

local option = {
    ccbiFile = "MercenaryExpeditionPopUp.ccbi",
    handlerMap =
    {
        onClose = "onReturn",
        onHelp = "onHelp",
        onRefresh = "onRefresh",
        onFrame1 = "onFrame1",
        onFrame2 = "onClickItemFrame",
        onFrame3 = "onClickItemFrame",
        onFrame4 = "onClickItemFrame",
        onFrame5 = "onClickItemFrame",
        onReceive = "onReceive",
        onRewardPreview = "onRewardPreview",
    },
    opcodes =
    {
        MERCENERY_EXPEDITION_INFO_S = HP_pb.MERCENERY_EXPEDITION_INFO_S,
        MERCENERY_DISPATCH_S = HP_pb.MERCENERY_DISPATCH_S,
        MERCENERY_EXPEDITION_FAST_S = HP_pb.MERCENERY_EXPEDITION_FAST_S;
        MERCENERY_EXPEDITION_GIVEUP_S = HP_pb.MERCENERY_EXPEDITION_GIVEUP_S;
        MERCENERY_EXPEDITION_REFRESH_S = HP_pb.MERCENERY_EXPEDITION_REFRESH_S;
        MERCENERY_EXPEDITION_FINISH_S = HP_pb.MERCENERY_EXPEDITION_FINISH_S
    }
}
function MercenaryExpeditionPage:registerPacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end
function MercenaryExpeditionPage:removePacket(container)
    for key, opcode in pairs(option.opcodes) do
        if string.sub(key, -1) == "S" then
            mContainer:removePacket(opcode)
        end
    end
end
function MercenaryExpeditionPage:onEnter(container)
    -- PushNotificationsManager.TaskTimeCalcultor = { }
    NodeHelper:setStringForLabel(container,{mSendTimes=""})
    mContainer = container
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:initScrollView(container, "mContent", 10);
    MercenaryExpeditionCfg = ConfigManager.getMercenaryExpeditionCfg()
    roleConfig = ConfigManager.getRoleCfg()
    self:registerPacket(mContainer)
    self:getDataInfo(container);
    MercenaryExpeditionPage.IsInThisPage = true;
    
    common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
end
function MercenaryExpeditionPage:getDataInfo(container)
    local msg = MercenaryExpedition_pb.HPMercenaryExpeditionInfo()
    msg.action=1
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_INFO_C, pb, #pb, true)
end
function MercenaryExpeditionPage_getSimpleInfo()
    local msg = MercenaryExpedition_pb.HPMercenaryExpeditionInfo()
    msg.action=2
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_INFO_C, pb, #pb, false)
end
function MercenaryExpeditionPage:refreshPage(container)
    local strTimes = common:getLanguageString('@Mercenarytime',TaskInfo.allTimes-TaskInfo.curTimes,TaskInfo.allTimes)
    -- local strTimes = common:getLanguageString('@TodayMercenaryExpeditionNum', TaskInfo.curTimes, TaskInfo.allTimes);
    local strMap =
        {
            mSendTimes = strTimes,
            mRefreshTxt = TaskInfo.refreshCost,
        }
    NodeHelper:setStringForLabel(mContainer, strMap);
    -- NodeHelper:addItemIsEnoughHtmlLab(mContainer, "mRefreshCostText", TaskInfo.refreshCost, UserInfo.playerInfo.gold, GameConfig.Tag.HtmlLable)
    if TaskInfo.nextRefreshTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor("TaskALL", TaskInfo.nextRefreshTime)
    end
    self:clearAllItem(container)
    -- PushNotificationsManager.TaskTimeCalcultor = { }
    NodeHelper:buildScrollView(container, #TaskInfo.allTask, TaskContent.ccbiFile, TaskContent.onFunction)

    require("Util.RedPointManager")
    RedPointManager_setShowRedPoint(RedPointManager.PAGE_IDS.LOBBY_BOUNTY_BTN, 1, (TaskInfo.allTimes > TaskInfo.curTimes))
end
function MercenaryExpeditionPage:clearAllItem(container)
    container.m_pScrollViewFacade:clearAllItems();
    container.mScrollViewRootNode:removeAllChildren();
    --for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
    --    if Info.mType == 0 then
    --        Info.mContainer = nil
    --    end
    --end
end
function MercenaryExpeditionPage:rebuildAllItem(container)

end

function MercenaryExpeditionPage:onRewardPreview(container)
    if MercenaryRewardPreviewCfg == nil then
        MercenaryRewardPreviewCfg = {}
        local itemInfo = ConfigManager.getMercenaryRewardCfg()
        for i = 1, #itemInfo do
            MercenaryRewardPreviewCfg[i] = itemInfo[i].rewards[1]
        end
    end
    RegisterLuaPage("GodEquipPreview")
    ShowEquipPreviewPage(MercenaryRewardPreviewCfg, common:getLanguageString("@RewardPreviewTitle"), common:getLanguageString("@MercenaryRewardPreviewDesc"))
    PageManager.pushPage("GodEquipPreview");
end
-- 接收服务器回包
function MercenaryExpeditionPage:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.MERCENERY_EXPEDITION_INFO_S or opcode == HP_pb.MERCENERY_DISPATCH_S or
        opcode == HP_pb.MERCENERY_EXPEDITION_GIVEUP_S or opcode == HP_pb.MERCENERY_EXPEDITION_REFRESH_S then
        local msg = MercenaryExpedition_pb.HPMercenaryExpeditionInfoRet()
        --[[
        message TaskItem
        {
        required int32 taskId = 1;//任务Id
        required int32 taskStatus = 2;//任务状态   0:未领取的任务 1:进行中的任务
        repeated int32 taskRewards = 3;//任务奖励
        optional int32 mercenaryId = 4;//进行中的佣兵Id
        optional int32 lastTimes = 5;//完成任务剩余时间
        }
        message HPMercenaryExpeditionInfoRet
        {
        repeated TaskItem allTask = 1; //所有的任务信息
        required int32 curTimes = 2; //本日当前已领取的远征次数
        required int32 allTimes = 3; //本日总的任务次数
        required int32 refreshCost = 4;//任务刷新消费
        }
        
        ]]
        --
        if opcode == HP_pb.MERCENERY_DISPATCH_S then
            MessageBoxPage:Msg_Box(common:getLanguageString("@AddMissionSuccessNotice"))
        end
        --[[if opcode == HP_pb.MERCENERY_EXPEDITION_FINISH_S then
        MessageBoxPage:Msg_Box(common:getLanguageString("@MercenaryExpeditionFinish"))
        end]]
        --
        msg:ParseFromString(msgBuff)
        TaskInfo.allTask = msg.allTask;
        TaskInfo.curTimes = msg.curTimes;
        TaskInfo.allTimes = msg.allTimes;
        TaskInfo.refreshCost = msg.refreshCost;
        TaskInfo.nextRefreshTime = msg.nextRefreshTime
        self:refreshPage(container);
    --[[if SaleContent.salePacketLastTime > 0 then
    TimeCalculator:getInstance():createTimeCalcultor(CloseTime, SaleContent.salePacketLastTime)
    end]]
    --
        if TaskInfo.curTimes == TaskInfo.allTimes then
            NoticePointState.isChange=true
            NoticePointState.EXPEDITION_POINT=false
        else
            NoticePointState.EXPEDITION_POINT=true
        end

        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            PageManager.pushPage("NewbieGuideForcedPage")
        end
    elseif opcode == HP_pb.MERCENERY_EXPEDITION_FINISH_S or opcode == HP_pb.MERCENERY_EXPEDITION_FAST_S then
        -- self:getDataInfo(container)
        local msg = MercenaryExpedition_pb.HPMercenaryExpeditionFinishRet()
        msg:ParseFromString(msgBuff)
        local taskId = msg.taskId;
        local TaskCfg = MercenaryExpeditionCfg[taskId]
        if not TaskCfg then
            return
        end
        MessageBoxPage:Msg_Box(common:getLanguageString("@MercenaryExpeditionFinish", common:getLanguageString(TaskCfg.name)))
        local taskName = "Task_01_" .. taskId
        local tmpTaskTimeCalcultor = {}
        --for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
        --    if keyName == taskName and Info.mType == 0 then
        --        TimeCalculator:getInstance():removeTimeCalcultor(keyName);
        --    else
        --        tmpTaskTimeCalcultor[keyName] = Info
        --    end
        --end
        --PushNotificationsManager.TaskTimeCalcultor = tmpTaskTimeCalcultor;
        MainFrame_refreshTimeCalculator()
    end
end

function MercenaryExpeditionPage:onExecute(container)
    self.container = container
    --for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
    --    if TimeCalculator:getInstance():hasKey(keyName) and Info.mType == 0 then
    --        -- 活动剩余时间
    --        local cdString = "00:00:00"
    --        local leftTime = TimeCalculator:getInstance():getTimeLeft(keyName)
    --        local fastCost = MercenaryExpeditionPage.GetFastFinishCost(leftTime)
    --        if leftTime > 0 then
    --            cdString = GameMaths:formatSecondsToTime(leftTime)-- 秒
    --        end
    --        --PushNotificationsManager.TaskTimeCalcultor[keyName].mFastCost = fastCost
    --        if Info.mContainer ~= nil then
    --            NodeHelper:setStringForLabel(Info.mContainer, {mTime = cdString})
    --        end
    --    end
    --end
    local timeStr = '00:00:00'
    if TimeCalculator:getInstance():hasKey("TaskALL") then
        TaskInfo.nextRefreshTime = TimeCalculator:getInstance():getTimeLeft("TaskALL")
        if TaskInfo.nextRefreshTime > 0 then
            timeStr = GameMaths:formatSecondsToTime(TaskInfo.nextRefreshTime)
        elseif TaskInfo.nextRefreshTime <= 0 then
            TimeCalculator:getInstance():removeTimeCalcultor("TaskALL")
            self:getDataInfo(container)
        end
    end
    NodeHelper:setStringForLabel(container, {mTime = common:getLanguageString("@MercenaryExpeditionRefreshTimeTxt") .. timeStr})
end
function MercenaryExpeditionPage:ShowGiftItemInfo(container)
    local itemInfo = tGiftInfo.itemInfo
    if not itemInfo then return end
    local rewardItems = {}
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count),
                isgold = itemInfo.isgold
            });
        end
    end
    self:fillRewardItem(container, rewardItems, 3)
    NodeHelper:setMenuItemEnabled(container, "mRechargeBtn", false);
end
function MercenaryExpeditionPage.GetFastFinishCost(second)
    -- floor(剩余分钟^0.75*0.5+0.5）  剩余分钟如果不足1分钟，按照一分钟计算
    local minute = math.ceil(second / 60)
    local Cost = math.floor(math.pow(minute, 0.75) * 0.5 + 0.5)
    return Cost
end
function MercenaryExpeditionPage:buildAllItem(container)

end
function TaskContent.onRefreshItemView(container)
    --[[
    message TaskItem
    {
    required int32 taskId = 1;//任务Id.
    required int32 taskStatus = 2;//任务状态   0:未领取的任务 1:进行中的任务
    repeated string taskRewards = 3;//任务奖励
    optional int32 mercenaryId = 4;//进行中的佣兵Id
    optional int32 lastTimes = 5;//完成任务剩余时间
    }
    ]]
    --
    local mID = tonumber(container:getItemDate().mID)
    local SingleTask = TaskInfo.allTask[mID]
    local TaskCfg = MercenaryExpeditionCfg[SingleTask.taskId]
    local strMap = {}
    strMap.mMapName = common:getLanguageString(TaskCfg.name);
    local nodeVisble = {}
    local nodePic = {}
    local sprite2Img={}
    local lb2Str={}
    local menu2Quality={}
    
    --NodeHelper:setMenuItemImage(container, { mExpeditionBtn = { normal = "NG2_Golden_N.png", disabled = "NG2_Grey.png" } })
    -- Reward Icon
    -- NodeHelper:setNodesVisible(container, { mRewardNode1 = false, mRewardNode2 = false, mRewardNode3 = false })
    local rewardItem = TaskCfg.reward[1]
    --NodeHelper:setNodesVisible(container, { ["mRewardNode"] = (rewardItem[1] ~= nil) })
    if rewardItem ~= nil then
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(rewardItem.type, rewardItem.itemId, rewardItem.count)
        if resInfo ~= nil then
            sprite2Img["mPic"] = resInfo.icon
            sprite2Img["mBg"] = NodeHelper:getImageBgByQuality(resInfo.quality)
            lb2Str["mNum"] = GameUtil:formatNumber(rewardItem.count)
            menu2Quality["mFrame"] = resInfo.quality
            NodeHelper:setStringForLabel(container, lb2Str)
            NodeHelper:setSpriteImage(container, sprite2Img)
            NodeHelper:setQualityFrames(container, menu2Quality)
        end
    end
    
    -- Job Icon
    --local jobLimit = common:split(TaskCfg.limit, ",")
    --for i = 1, 6 do
    --    NodeHelper:setNodesVisible(container, { ["mJob" .. i] = (jobLimit[i] ~= nil) })
    --    if jobLimit[i] then
    --        NodeHelper:setSpriteImage(container, { ["mJob" .. i] = GameConfig.MercenaryClassImg[tonumber(jobLimit[i])] })
    --    end
    --end
    if SingleTask.taskStatus == 0 then
        -- 未领取的任务
        nodeVisble = {
            mFastNode = false,
            mExpeditionNode = true,
            mMerMisTimeLab = false,
            mMercenaryHead = false,
            RewardNode = false,
            mTime = true,
            mMerMisLimLab1 = false,
            mMerMisLimLab2 = true,
        }
        strMap["mTime"] = GameMaths:formatSecondsToTime(TaskCfg.taskTime * 60)-- 秒
    elseif SingleTask.taskStatus == 1 and SingleTask.lastTimes > 1000 then
        -- 进行中的任务
      --  local roleTable = {}
      --  local MercenaryId = SingleTask.mercenaryId
      --  if MercenaryId ~= 0 then
      --      if _mercenaryInfos == nil then
      --          _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
      --      end
      --      for i = 1, #_mercenaryInfos.roleInfos do
      --          for j=1,#MercenaryId do
      --               if tonumber(_mercenaryInfos.roleInfos[i].roleId) == MercenaryId[j] then
      --                   roleTable = NodeHelper:getNewRoleTable(_mercenaryInfos.roleInfos[i].itemId)
      --                   break
      --               else
      --                   roleTable = nil
      --               end
      --          end
      --      end
      --  else
      --      roleTable = nil
      --  end
       -- nodeVisble = {
       --     mFastNode = true,
       --     mExpeditionNode = true,
       --     mMerMisTimeLab = true,
       --     mMercenaryHead = false,
       --     RewardNode = true,
       --     mMerMisLimLab1 = true,
       --     mMerMisLimLab2 = false,
       -- }
        local leftTime = math.floor(SingleTask.lastTimes / 1000)
        local keyName = "Task_01_" .. SingleTask.taskId
        if leftTime > 0 then
            NodeHelper:setMenuItemEnabled(container, "mExpeditionMenuBtn", false)
            local txt = common:getLanguageString("@MercenaryStatus_Expedition")
            NodeHelper:setStringForLabel(container, {mDispatchTxt = txt})
            --TimeCalculator:getInstance():createTimeCalcultor(keyName, leftTime)
            --PushNotificationsManager.TaskTimeCalcultor[keyName] = {
            --    mKey = keyName,
            --    mId = PushNotificationsManager._PushCfg[1]._Id,
            --    mType = PushNotificationsManager._PushCfg[1]._Type,
            --    mIcon = PushNotificationsManager._PushCfg[1]._Icon,
            --    mSound = PushNotificationsManager._PushCfg[1]._Sound,
            --    mText = PushNotificationsManager._PushCfg[1]._Text,
            --    minLevel = PushNotificationsManager._PushCfg[1]._minLevel,
            --    maxLevel = PushNotificationsManager._PushCfg[1]._maxLevel,
            --    mTime = PushNotificationsManager._PushCfg[1]._Time,
            --    mDateStart = PushNotificationsManager._PushCfg[1]._DateStart,
            --    mDateEnd = PushNotificationsManager._PushCfg[1]._DateEnd,
            --    mContainer = container,
            --    mFastCost = 0
            --}
           --MainFrame_refreshTimeCalculator()
           CountDownHandler= CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
           leftTime=leftTime-1     
           local txt=GameMaths:formatSecondsToTime(leftTime)
           local nodeTTF = container:getVarLabelTTF("mTime")
           if nodeTTF then
               nodeTTF:setString(tostring(txt))
           end
        end, 1.0, false)
            --strMap["mTime"] = GameMaths:formatSecondsToTime(leftTime)-- 秒
        else
            TimeCalculator:getInstance():removeTimeCalcultor(keyName)
            --if PushNotificationsManager.TaskTimeCalcultor[keyName] then
            --    PushNotificationsManager.TaskTimeCalcultor[keyName].mContainer = nil
            --end
            strMap["mTime"] = GameMaths:formatSecondsToTime(0)-- 秒
        end
    end
    --setLevel
    NodeHelper:setSpriteImage(container,{mStarLevel=GameConfig.ExpeditionLevel[TaskCfg.level]})
    nodeVisble["mStarLevel"]=false
    --setBg
    local bgNode = CCSprite:create(TaskCfg.pic)
    local BackGround=tolua.cast(container:getVarNode("mBackground"), "CCScale9Sprite")
    local BackGroundSize=BackGround:getContentSize()
    BackGround:setSpriteFrame(bgNode:displayFrame())
    BackGround:setContentSize(BackGroundSize)
    --setString
    NodeHelper:setStringForLabel(container, strMap)
    NodeHelper:setNodesVisible(container, nodeVisble)
end

function TaskContent.onHand(container)
    local Id = tonumber(container:getItemDate().mID)
    if mCurrentIndex == Id then
        return
    end
    mCurrentIndex = Id;
    MercenaryExpeditionPage:SelectPaging(mContainerRef);

end
function TaskContent.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
        TaskContent.onRefreshItemView(container);
    elseif eventName == "onExpeditionMenuBtn" then
        -- 远征派遣
        local isTaskCount = 0
        for i = 1, #TaskInfo.allTask do
            if TaskInfo.allTask[i].taskStatus == 1 and TaskInfo.allTask[i].lastTimes then
                isTaskCount = isTaskCount + 1
            end
        end
        if isTaskCount >= 5 then
            MessageBoxPage:Msg_Box_Lan("@MercenarySendNumLimit")
            return
        else
            local MercenaryExpeditionSendPage = require("MercenaryExpeditionSendPageNew")
            local mID = tonumber(container:getItemDate().mID)
            local SingleTask = TaskInfo.allTask[mID]
            local TaskCfg = MercenaryExpeditionCfg[SingleTask.taskId]
            MercenaryExpeditionSendPage.setPageInfo(SingleTask, TaskCfg.limit);
            PageManager.pushPage("MercenaryExpeditionSendPageNew")
        end
    elseif eventName == "onFast" then
        -- 快速完成
        local mID = tonumber(container:getItemDate().mID)
        local SingleTask = TaskInfo.allTask[mID]
        local keyName = "Task_01_" .. SingleTask.taskId
        --local Cost = PushNotificationsManager.TaskTimeCalcultor[keyName].mFastCost;
        local title = common:getLanguageString("@MercenaryExpeditionFinishTitle");
        local msg = common:getLanguageString("@MercenaryExpeditionFinishAsk", Cost);
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
                local msg = MercenaryExpedition_pb.HPMercenaryExpeditionFast()
                msg.taskId = SingleTask.taskId;
                local pb = msg:SerializeToString()
                PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_FAST_C, pb, #pb, true)
            else
                local msg = MercenaryExpedition_pb.HPMercenaryExpeditionGiveUp()
                msg.taskId = SingleTask.taskId;
                local pb = msg:SerializeToString()
                PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_GIVEUP_C, pb, #pb, true)
            end
        end, true, "@MercenaryExpeditionFinishButton", "@MercenaryExpeditionGiveUpBtn", true);
    elseif eventName=="onFrame1" then
     local mID = tonumber(container:getItemDate().mID)
         local SingleTask = TaskInfo.allTask[mID]
         local TaskCfg = MercenaryExpeditionCfg[SingleTask.taskId]
         local item=TaskCfg.reward[1]
         GameUtil:showTip(container:getVarNode("mFrame"),item)
    end
end

function MercenaryExpeditionPage_onGuideTask()
    local MercenaryExpeditionSendPage = require("MercenaryExpeditionSendPageNew")
    local mID = 1
    local SingleTask = TaskInfo.allTask[mID]
    local TaskCfg = MercenaryExpeditionCfg[SingleTask.taskId]
    MercenaryExpeditionSendPage.setPageInfo(SingleTask, TaskCfg.limit);
    PageManager.pushPage("MercenaryExpeditionSendPageNew")
end

function MercenaryExpeditionPage:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function MercenaryExpeditionPage:onReturn(container)
    GameUtil:purgeCachedData()
    PageManager.popPage(thisPageName)
    --MainFrame_onMainPageBtn()
end

function MercenaryExpeditionPage:onRefresh(container)
    local title = common:getLanguageString("@MercenaryExpeditionFreshTitle");
    local msg = common:getLanguageString("@MercenaryExpeditionFreshAsk", TaskInfo.refreshCost);
    PageManager.showConfirm(title, msg, function(isSure)
        if isSure then
            local msg = MercenaryExpedition_pb.HPRefreshExpedition()
            local pb = msg:SerializeToString()
            PacketManager:getInstance():sendPakcet(HP_pb.MERCENERY_EXPEDITION_REFRESH_C, pb, #pb, true)
        end
    end, true, nil, nil, nil, 0.9);

end
function MercenaryExpeditionPage:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_MERCENARY_EXPEDITIONPAGE)
end
function MercenaryExpeditionPage:onExit(container)
    MercenaryExpeditionPage.IsInThisPage = false;
    container:removeMessage(MSG_MAINFRAME_REFRESH)
    self:removePacket(container)
    NodeHelper:deleteScrollView(container);
    if CountDownHandler then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CountDownHandler)
        CountDownHandler = nil  
    end

    --for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
    --    if Info.mType == 0 then
    --        Info.mContainer = nil
    --    end
    --end
    MercenaryRewardPreviewCfg = nil
    onUnload(thisPageName, container);
-- for keyName, Info in pairs(PushNotificationsManager.TaskTimeCalcultor) do
-- TimeCalculator:getInstance():removeTimeCalcultor(keyName);
-- end
end

function MercenaryExpeditionPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        
        end
end

local CommonPage = require('CommonPage')
local MercenaryExpeditionPagebase = CommonPage.newSub(MercenaryExpeditionPage, thisPageName, option)
return MercenaryExpeditionPage
