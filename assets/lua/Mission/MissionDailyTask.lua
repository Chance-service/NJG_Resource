----------------------------------------------------------------------------------
--[[
	每日任务
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'MissionDailyTask'
local Activity_pb = require("Activity_pb");
local MissionManager = require("MissionManager")
local HP_pb = require("HP_pb");
local ItemManager = require "Item.ItemManager"
local Const_pb = require("Const_pb")
local dailyQuest_pb = require("dailyQuest_pb")
local CommonRewardPage = require("CommonRewardPage")
require("Shop_pb");
local MissionDailyTask = {
}
local DailyQuestCfg = { }-- 任务配置
local DailyQuestPointCfg = { }-- 活跃点配置
local _dailyQuestPacketInfo = { }-- 任务数据包
local _curPoint = 0-- 当前活跃点
local _LastPoint = 0-- 记录上次活跃点 用于做动画
local _dailyPointCore = { }-- 活跃度状态信息
local selfContainer = nil
local _ProgressTimerNode = nil
local _isNeedRunAni = false-- 是否第一次播放 进度条动画
local goBattlePage = false;-- 下一帧跳转到战斗界面
local _curAllTaskCanGetPoint = 0 -- 当前所有任务可获取到的总任务点数
local _isAlreadyInitProgress = false
local BAR_WIDTH = 100
local BAR_HEIGHT = 21

function MissionDailyTask.onFunction(eventName, container)
    if eventName:sub(1, 8) == "onGetBox" then
        local curBoxId = tonumber(string.sub(eventName, -1, -1))
        local curState = _dailyPointCore[curBoxId].state
        if curState == 2 then
            MessageBoxPage:Msg_Box_Lan("@dailyQuestPointGotTxt")
        elseif curState == 0 then
            -- 未完成，预览奖励
            RegisterLuaPage("DailyTaskRewardPreview")
            ShowRewardPreview(DailyQuestPointCfg[curBoxId].award, common:getLanguageString("@TaskDailyRewardPreviewTitle"), common:getLanguageString("@TaskDailyRewardPreviewInfo"))
            PageManager.pushPage("DailyTaskRewardPreview");
        else
            local CommonRewardPage = require("CommPop.CommItemReceivePage")
            CommonRewardPage:setData(DailyQuestPointCfg[curBoxId].award, common:getLanguageString("@ItemObtainded"), nil)
            PageManager.pushPage("CommPop.CommItemReceivePage")

            --CommonRewardPageBase_setPageParm(DailyQuestPointCfg[curBoxId].award, curState == 1)
            --PageManager.pushPage("CommonRewardPage")
            CCLuaLog("####eventName:sub(1, 8) == onGetBox######")
            --[[ if
            RegisterLuaPage("ResListPage");
            ResListPage_setList(cfg, callback);
            PageManager.pushPage("ResListPage");
            end]]
            --
            local index = tonumber(string.sub(eventName, -1))
            local msg = dailyQuest_pb.HPTakeDailyPointAward()
            msg.pointCount = _dailyPointCore[index].dailyPointNumber
            local pb = msg:SerializeToString()
            PacketManager:getInstance():sendPakcet(HP_pb.TAKE_DAILY_QUEST_POINT_AWARD_C, pb, #pb, true)
            
        end
    elseif eventName == "onTask" then
        PageManager.pushPage("LivenessPage")
    end
end
function MissionDailyTask:onEnter(ParentContainer)
    _LastPoint = 0
    _isNeedRunAni = false
    _isAlreadyInitProgress = false
    local missionInfo = MissionManager.getMissionInfo()
    selfContainer = ScriptContentBase:create(missionInfo._ccbi)
    selfContainer:registerFunctionHandler(MissionDailyTask.onFunction)
    selfContainer.scrollview = selfContainer:getVarScrollView("mContent");
    --if selfContainer.scrollview ~= nil then
    --    ParentContainer:autoAdjustResizeScrollview(selfContainer.scrollview);
    --end
    --NodeHelper:autoAdjustResizeScale9Sprite(selfContainer:getVarScale9Sprite("mScale9Sprite1"))
    for i = 1, 4 do
        NodeHelper:setNodesVisible(selfContainer, { ["mBoxPoint" .. i] = false })
    end

    DailyQuestCfg = ConfigManager.getDailyQuestCfg()
    DailyQuestPointCfg = ConfigManager.getDailyQuestPointCfg()

    return selfContainer
end
function MissionDailyTask:initProgressTimer(container)
    if _isAlreadyInitProgress then return end
    local parentNode = container:getVarNode("mLivenessBar")
    if not parentNode then return end
    parentNode:setVisible(true)
    parentNode:removeAllChildren()
    local maxPoint = 0
    local imageName = ""
    for i = 1, #GameConfig.dailyTaskLevelPoint do
        local cfg = GameConfig.dailyTaskLevelPoint[i]
        if tonumber(cfg.level) >= UserInfo.roleInfo.level then
            maxPoint = tonumber(cfg.point);
            break
        end
    end
    if _curAllTaskCanGetPoint >= 100 then
        imageName = "DayLogin30_image_7.png"
        NodeHelper:setNodesVisible(container, {
            mBarBG2 = false,
            mBarBG1 = false,
            mBox3 = true,
            mBox1 = true,
            mBox2 = true,
            -- mBox4 = false
        } )
    else
        -- imageName = "Task_Bar_1.png"
        imageName = "DayLogin30_image_7.png"
        NodeHelper:setNodesVisible(container, {
            mBarBG2 = false,
            mBarBG1 = false,
            mBox3 = true,
            mBox1 = true,
            mBox2 = true,
            -- mBox4 = false
        } )

        --        NodeHelper:setNodesVisible(container, {
        --            mBarBG2 = true,
        --            mBarBG1 = false,
        --            mBox3 = true,
        --            mBox1 = true,
        --            mBox2 = true,
        --            mBox4 = true
        --        } )

    end
    local spriteBg = CCSprite:create("DayLogin30_image_6.png")
    spriteBg:setAnchorPoint(ccp(0, 0.5))
    --spriteBg:setPositionX(67)
    parentNode:addChild(spriteBg)
    local sprite = CCSprite:create(imageName)
    _ProgressTimerNode = CCProgressTimer:create(sprite)
    _ProgressTimerNode:setType(kCCProgressTimerTypeBar)
    _ProgressTimerNode:setMidpoint(CCPointMake(0, 0))
    _ProgressTimerNode:setBarChangeRate(CCPointMake(1, 0))
    _ProgressTimerNode:setAnchorPoint(ccp(0, 0.5))
    --_ProgressTimerNode:setPositionX(67)
    parentNode:addChild(_ProgressTimerNode)

    -- 调整宝箱位置
    --local spriteWidth = sprite:getContentSize().width
    --for i = 1, #DailyQuestPointCfg do
    --    local cfg = DailyQuestPointCfg[i]
    --    local nodeX =(cfg.point / --[[_curAllTaskCanGetPoint]]100) * spriteWidth
    --    local node = container:getVarNode(cfg.nodeName)
    --    node:setPositionX(nodeX)
    --end

    ------------------------------------------------------------------------------------
    -- 活跃度活动特殊处理
    --local loginPoint = 100
    --local nodeX =(100 / _curAllTaskCanGetPoint) * spriteWidth
    --local node = container:getVarNode("mSignBtnNode")
    --node:setPositionX(nodeX)
    --node:setVisible(true)
    --NodeHelper:setStringForLabel(container, { mTaskNum = loginPoint })
    ------------------------------------------------------------------------------------
    -- 调整宝箱位置
    _isAlreadyInitProgress = true
end
function MissionDailyTask:getPacketInfo()
    common:sendEmptyPacket(HP_pb.DAILY_QUEST_INFO_C, true)
end
function MissionDailyTask:refreshPage()
    self:initProgressTimer(selfContainer)
    self:rebuildAllItem();
    -- 活跃度处理
    local strLabel = {
        --mRewardNum = common:getLanguageString("@TaskDailyLiveness") .. _curPoint
    }

     local PointPos = {25, 50, 75, 100}
    local NewPos = { }

    for i = 1, #_dailyPointCore do
        NewPos[i]=_dailyPointCore[i].dailyPointNumber
    end

    local function mapPercentage(percent)
        for i = 1, #NewPos - 1 do
            if percent >= NewPos[i] and percent <= NewPos[i + 1] then
                -- 在找到的区间内进行插值
                local ratio = (percent - NewPos[i]) / (NewPos[i + 1] - NewPos[i])
                return PointPos[i] + ratio * (PointPos[i + 1] - PointPos[i])
            end
        end
        -- 如果超出范围，返回原始值
        return percent
    end

   if _curPoint ~= _LastPoint then
    -- 计算原始的百分比
        local toPercent = _curPoint / _curAllTaskCanGetPoint * 100
        
        -- 使用表格控制的映射规则调整百分比
        toPercent = mapPercentage(toPercent)
        
        if toPercent >= 100 then
            toPercent = 100
        end
        
        -- 计算 _LastPoint 对应的百分比并进行映射
        local fromPercent = _LastPoint / _curAllTaskCanGetPoint * 100
        fromPercent = mapPercentage(fromPercent)
        
        if not _isNeedRunAni then
            _ProgressTimerNode:setPercentage(toPercent)
            _isNeedRunAni = true
        else
            local actionTo = CCProgressFromTo:create(0.8, fromPercent, toPercent)
            _ProgressTimerNode:runAction(actionTo)
        end
        
        _LastPoint = _curPoint
    end
    NodeHelper:setStringForLabel(selfContainer, { mNowPoint = _curPoint })
    --selfContainer:getVarLabelTTF("mNowPoint"):setString(_curPoint .. "/" .. _curAllTaskCanGetPoint)
    


    -- 活跃度处理
    local spriteName = { 25, 50, 75, 100 }
    for i = 1, #_dailyPointCore do
        --[[mTaskRewardBox0_30
        mTaskRewardBox1_30
        mTaskRewardBox2_30
        mTaskRewardBox0_60
        mTaskRewardBox1_60
        mTaskRewardBox2_60
        mTaskRewardBox0_100
        mTaskRewardBox1_100
        mTaskRewardBox2_100
        ]]
        --
        for i = 1, #_dailyPointCore do
            strLabel["mBoxNum" .. i] = _dailyPointCore[i].dailyPointNumber
            for j = 0, 2 do
                local curName = "mTaskRewardBox" .. j .. "_" .. spriteName[i]
                local sprite = selfContainer:getVarNode(curName);

                if sprite then
                    sprite:setVisible(j == _dailyPointCore[i].state)
                end
            end
            NodeHelper:setNodesVisible(selfContainer, { ["mBoxPoint" .. i] = (1 == _dailyPointCore[i].state) })
        end
    end
    NodeHelper:setStringForLabel(selfContainer, strLabel);
    --MissionDailyTask:onfreshSignState()
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        PageManager.pushPage("NewbieGuideForcedPage")
    end
end

function  MissionDailyTask:onfreshSignState()

    local mSignSprite = selfContainer:getVarNode("mSignSprite");
    local mSignEffect = selfContainer:getVarNode("mSingEffectNode");
    if _curPoint >=100 then
        ActivityInfo.NoticeInfo.LivenessIds = ActivityInfo.NoticeInfo.LivenessIds or {}
        if getTabelLength(ActivityInfo.NoticeInfo.LivenessIds) == 0   then
            mSignSprite:setVisible(true)
            mSignEffect:setVisible(false)
        else
            mSignSprite:setVisible(false)
            mSignEffect:setVisible(true)
        end

    else
        mSignSprite:setVisible(true)
        mSignEffect:setVisible(false)
    end
end
----------------scrollview-------------------------
local TaskContent = {

}

function TaskContent:onPreLoad(content)

end

function TaskContent:onUnLoad(content)

end

function TaskContent:onConfirmation(content)
    local container = content:getCCBFileNode()
    local taskId = self.id
    local packetInfo = _dailyQuestPacketInfo[taskId]
    local cfgInfo = DailyQuestCfg[packetInfo.questId]
    if packetInfo.questStatus == 0 and cfgInfo then
        local GuideManager = require("Guide.GuideManager")
        if GuideManager.isInGuide then
            MessageBoxPage:Msg_Box(common:getLanguageString("@TutorialError"))
            return
        end
        if cfgInfo.isJump == 1 then
            -- 跳转
            local PageJumpMange = require("PageJumpMange")
            if cfgInfo.jumpValue == 22 then
                goBattlePage = true
            elseif cfgInfo.jumpValue == 38 then
                local  HelpFightDataManager = require("PVP.HelpFightDataManager")
                if HelpFightDataManager:isOpen() then
                    PageJumpMange.JumpPageById(cfgInfo.jumpValue)
                else
                    MessageBoxPage:Msg_Box_Lan( common:getLanguageString( "@Eighteentip7"))
                end
            else
                PageJumpMange.JumpPageById(cfgInfo.jumpValue)
            end
            PageManager.popPage("MissionMainPage")
        end
    elseif packetInfo.questStatus == 1 and packetInfo.takeStatus == 0 then
        -- 领奖
        TaskContent.getRewards(packetInfo.questId);
    end
end


function TaskContent_getRewards(id)
    TaskContent.getRewards(id)
end
function TaskContent.getRewards(id)
    local msg = dailyQuest_pb.HPTakeDailyQuestAward()
    msg.questId = id
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.TAKE_DAILY_QUEST_AWARD_C, pb, #pb, true)   
end
function TaskContent:onRefreshContent(content)
    local container = content:getCCBFileNode()
    local index = self.id
    local ItemInfo = _dailyQuestPacketInfo[index]
    local ItemCfg = DailyQuestCfg[ItemInfo.questId]

    --[[
        message QuestItem
        {
	        required int32 questId = 1;//任务Id
	        required int32 takeStatus = 2;//领取状态   0:未领取的任务 1:已经领取
	        required int32 questStatus = 3;//任务状态   0:未完成 1:已经完成
	        required string taskRewards = 4;//任务奖励
	        required int32 questCompleteCount = 5;//完成目标数量

        }
    ]]
    --
   
    -- 按钮状态 1：领取奖励  0：前往完成 2:已领取
    local BtnText = ""
    local buttonBMFontText = container:getVarLabelTTF("mConfirmation")
    --NodeHelper:setNodeIsGray(container, { mConfirmation = false })
    NodeHelper:setNodesVisible(container, { mPoint = false })
    if ItemInfo.questStatus == 0 then
        -- 0:未完成
        BtnText = "@ActDailyMissionBtn_Go";
        if ItemCfg.isJump == 1 then
            -- 跳转
            --NodeHelper:setNodesVisible(container, { mGotoNode = true, mConfirmationNode = false, })
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", true)
            --NodeHelper:setMenuItemEnabled(container, "mGotoBtn", true)
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Blue.fnt")
            -- 蓝色字正常
            --NodeHelper:setNodeIsGray(container, { mConfirmation = false })
        else
            BtnText = "@inProgress";
            --NodeHelper:setNodesVisible(container, { mGotoNode = false, mConfirmationNode = true, })
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", false)
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Blue.fnt")
            -- 蓝色字置灰
            --NodeHelper:setNodeIsGray(container, { mConfirmation = true })
        end

    elseif ItemInfo.questStatus == 1 then
        -- 1:已经完成
        if ItemInfo.takeStatus == 0 then
            -- 未领取
            BtnText = "@ActDailyMissionBtn_Receive"
            --NodeHelper:setNodesVisible(container, { mGotoNode = false, mConfirmationNode = true, })
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", true)
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Golden.fnt")
            --NodeHelper:setNodeIsGray(container, { mConfirmation = false })
            NodeHelper:setNodesVisible(container, { mPoint = true })
        elseif ItemInfo.takeStatus == 1 then
            -- 已领取 按钮置灰
            -- mRewardDayBtn
            BtnText = "@ActDailyMissionBtn_Finish"
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", false)
            --NodeHelper:setMenuItemEnabled(container, "mGotoBtn", false)
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Blue.fnt")
            --NodeHelper:setNodeIsGray(container, { mConfirmation = true })
        end
    end
    local finishCount = ItemInfo.questCompleteCount
    local targetCount = ItemCfg.targetCount
    if ItemCfg.showType == 1 then
        targetCount = 1
        if ItemInfo.questStatus == 0 then
            finishCount = 0
        else
            finishCount = 1
        end
    end
    if finishCount > targetCount then
        finishCount = targetCount
    end
    local strLabel = {
        mTaskTimes = GameUtil:formatNumber(finishCount) .. "/" .. GameUtil:formatNumber(targetCount), 
        mConfirmation = common:getLanguageString(BtnText),
        mTaskReward = ItemCfg.des,
        mSkillTex = "",
    }
    local bar = container:getVarScale9Sprite("mTaskBar")
    bar:setContentSize(CCSize(BAR_WIDTH * math.min(1, math.max(0.14, finishCount / targetCount)), BAR_HEIGHT))
    NodeHelper:setNodesVisible(container, { mTaskBar = (finishCount > 0) })

    container:getVarLabelTTF("mSkillTex"):removeAllChildren()
    --container:getVarLabelTTF("mRewardNum"):removeAllChildren()
    NodeHelper:setStringForLabel(container, { mRewardNum = "" })
   
    local TextContent={
        --mRewardNum = '<font color="#5e4d3d">' .. common:getLanguageString("@TaskDailyRewardPreviewInfo1", ItemCfg.point) .. '</font>',
        mSkillTex = '<p style="margin:10px;" ><font color="#737466">' .. common:getLanguageString(ItemCfg.content) .. '</font></p>',
    }
		
    local Text = CCHTMLLabel: createWithString(TextContent.mSkillTex, CCSizeMake(400, 30), "Barlow-Bold")
    --local RewardNum = CCHTMLLabel: createWithString(TextContent.mRewardNum, CCSizeMake(200, 30), "Barlow-Bold"),
    
    Text:setScale(0.8)
    --RewardNum:setScale(0.8)
    Text:setAnchorPoint(ccp(0, 1))
    --RewardNum:setAnchorPoint(ccp(1, 0))
    Text:setPosition(ccp(0, 10))
    container:getVarLabelTTF("mSkillTex"):addChild(Text)
    --container:getVarLabelTTF("mRewardNum"):addChild(RewardNum)

    local normalImage = NodeHelper:getImageByQuality(ItemCfg.quality)
    local iconBg = NodeHelper:getImageBgByQuality(ItemCfg.quality)
    
    NodeHelper:setSpriteImage(container, { mQualityItem = normalImage })
    --if string.sub(ItemCfg.icon, 1, 7) == "UI/Role" then
    --    NodeHelper:setNodeScale(container, "mSkillPic", 1, 1)
    --else
    --    NodeHelper:setNodeScale(container, "mSkillPic", 1, 1)
    --end
    
    NodeHelper:setStringForLabel(container, strLabel)
    --if finishCount == targetCount then  
    --    NodeHelper:setColorForLabel(container, { mTaskTimes ="219 115 17" } )
    --else
    --    NodeHelper:setColorForLabel(container, { mTaskTimes ="255 255 255" } )
    --end
    --NodeHelper:setNodesVisible(container, { mLivenessNode = true })
    NodeHelper:setSpriteImage(container, { mSkillPic = ItemCfg.icon, mIconBg = iconBg })
    
    if index == 1 then
        local GuideManager = require("Guide.GuideManager")
        GuideManager.PageContainerRef["TaskContent"] = container
    end
end
function TaskContent:onDetial(container)
    local index = self.id
    local ItemInfo = _dailyQuestPacketInfo[index].taskRewards;
    local Rewards=common:split(ItemInfo,"_")
    local items= {  type=tonumber(Rewards[1]/10000),
                    itemId=tonumber(Rewards[2]),
                    count=tonumber(Rewards[3]) }
    GameUtil:showTip(container:getVarNode("mDetial"), items)
end
function MissionDailyTask:rebuildAllItem()
    self:clearAllItem();
    self:buildItem();
end

function MissionDailyTask:clearAllItem()
    local scrollview = selfContainer.scrollview
    scrollview:removeAllCell();
end

function MissionDailyTask:buildItem()
    local size = #_dailyQuestPacketInfo
    NodeHelper:buildCellScrollView(selfContainer.scrollview, size, "TaskContent.ccbi", TaskContent)
end

function MissionDailyTask:onBuyBtn(container)


end

function MissionDailyTask:getActivityInfo()

end
local function sortInfoList(info)
    table.sort(info,
    function(e1, e2)
        if not e2 then return true end
        if not e1 then return false end
        local task1Cfg = DailyQuestCfg[e1.questId]
        local task2Cfg = DailyQuestCfg[e2.questId]
        -- sortId
        if task1Cfg.sortId < task2Cfg.sortId then
            return true
        else
            return false
        end
    end
    );
end
local function sortQuestInfo(info)
    sortInfoList(info)
    local finshList = { }
    local othersList = { }
    local canGetReward = { }
    _dailyQuestPacketInfo = { }
    _curAllTaskCanGetPoint = 0
    for i = 1, #info do
        local ItemCfg = DailyQuestCfg[info[i].questId];
        _curAllTaskCanGetPoint = 100--_curAllTaskCanGetPoint + ItemCfg.point
        if info[i].questStatus == 1 and info[i].takeStatus == 1 then
            table.insert(finshList, info[i])
        elseif info[i].questStatus == 1 and info[i].takeStatus == 0 then
           table.insert(canGetReward, info[i])
        else
            table.insert(othersList, info[i])
        end
    end
    for i = 1, #canGetReward do
        table.insert(_dailyQuestPacketInfo, canGetReward[i])
    end
    for i = 1, #othersList do
        table.insert(_dailyQuestPacketInfo, othersList[i])
    end
    for i = 1, #finshList do
        table.insert(_dailyQuestPacketInfo, finshList[i])
    end
end
function MissionDailyTask:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
    local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.DAILY_QUEST_INFO_S or opcode == HP_pb.TAKE_DAILY_QUEST_AWARD_S then
        if opcode == HP_pb.TAKE_DAILY_QUEST_AWARD_S then
            _isNeedRunAni = true
            --MessageBoxPage:Msg_Box(common:getLanguageString('@RewardItem2'))
        end
        local msg = dailyQuest_pb.HPDailyQuestInfoRet()
        msg:ParseFromString(msgBuff)
        sortQuestInfo(msg.allDailyQuest);
        _curPoint = msg.dailyPoint
        _dailyPointCore = msg.dailyPointCore


        --------------------------------------------------------------------------
        --local index = 0
        --for i = 1 , #_dailyPointCore do
        --    if _dailyPointCore[i].dailyPointNumber == 100 then
        --       index = i
        --       break
        --    end
        --end
        --if index ~= 0 then
        --  table.remove(_dailyPointCore , index)
        --end
        --------------------------------------------------------------------------


        table.sort(_dailyPointCore, function(point1, point2)
            if not point1 then return true end
            if not point2 then return false end
            return point1.dailyPointNumber < point2.dailyPointNumber
        end );
        -- local _curAllTaskCanGetPoint = 0 --当前任务可获取到的总任务点数
        self:refreshPage()
    elseif opcode == HP_pb.TAKE_DAILY_QUEST_POINT_AWARD_S then
        local msg = dailyQuest_pb.HPTakeDailyPointAwardRet()
        msg:ParseFromString(msgBuff)
        for i = 1, #_dailyPointCore do
            if _dailyPointCore[i].dailyPointNumber == msg.pointCount then
                _dailyPointCore[i].state = msg.state
                break
            end
        end
        self:refreshPage()
    end
end

function MissionDailyTask:onReceiveMessage(ParentContainer)
    local message = ParentContainer:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == "MissionMainPage" then
            if extraParam == "refreshSignState" then
                --MissionDailyTask:onfreshSignState()
            end
        end
    end
end

function MissionDailyTask:removePacket(ParentContainer)
    ParentContainer:removeMessage(MSG_MAINFRAME_REFRESH);
end
function MissionDailyTask:onExecute(container)
    if goBattlePage == true then
        goBattlePage = false
--        MainFrame_onBattlePageBtn();
    end
end
function MissionDailyTask:onExit(ParentContainer)
    _ProgressTimerNode = nil
end

return MissionDailyTask
