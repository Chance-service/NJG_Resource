local NodeHelper = require("NodeHelper")
local thisPageName = 'GloryHolePage'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");
local UserInfo = require("UserInfo")
local GloryHoleDataBase = require("GloryHole.GloryHolePageData")
local MissionMainPage = require("MissionMainPage")
local InfoAccesser = require("Util.InfoAccesser")
local ItemManager = require("ItemManager")

local GloryHoleCfg=ConfigManager.getGloryHoleCfg()

local GloryHoleBase = {}
local PageInfo = nil
local UsingItem = 0
local UsingItems = {}
local parentPage = nil

local NowHeroId=990

local isPractice = false
local GloryHoleDailyQuestPointCfg = ConfigManager.getGloryHoleDailyQuestPointCfg()

local selfContainer = nil

local ChosenTeam=0

local CountDown

local isOpen = false

local RankInfo = {
    
    }

local itemInfo = {}
local ItemIcon = {[1] = "GloryHole_btn02_03.png", [2] = "GloryHole_btn02_04.png", [3] = "GloryHole_btn02_06.png", [4] = "GloryHole_btn02_05.png"}
local itemCount = {}

local option = {
    ccbiFile = "GloryHole.ccbi",
    handlerMap =
    {
    },
}
local DailyMissionContent = {
    ccbiFile = "GloryHole_EventMissionContent.ccbi",
    BarLong = 121
}
local AchivementContent = {
    ccbiFile = "GloryHole_EventMissionContent.ccbi",
    BarLong = 121
}
local DailyCCB = {}
local Target = {}

local ItemInfoTable = {}

local BUY_TIMES_LIMIT = 3
local FREE_TIMES_LIMIT = 3

local GloryHoleTable={}

local isPlayedOpenAni = false

local isPlaying = false


local opcodes = {
    ACTIVITY175_GLORY_HOLE_S = HP_pb.ACTIVITY175_GLORY_HOLE_S,
    ACTIVITY176_ACTIVITY_EXCHANGE_S = HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_S,
    PLAYER_AWARD_S=HP_pb.PLAYER_AWARD_S
}
function GloryHoleBase:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    
    
    return container
end
function GloryHoleBase:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function GloryHoleBase:setOpenAni(bool)
    isPlayedOpenAni = bool
end
function GloryHoleBase:getOpenAni()
    return isPlayedOpenAni
end
function GloryHoleBase:onEnter(container)
    parentPage:registerPacket(opcodes)
    container:registerFunctionHandler(GloryHoleBase.onFunction)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    self.container = container
    container:runAnimation("OpenAni")
    require("TransScenePopUp")
    TransScenePopUp_closePage()
    selfContainer = container
    --Bg
    container:getVarNode("mBg"):setScale(NodeHelper:getScaleProportion())
    --Data
    PageInfo = GloryHoleDataBase:getData()
    --Timer
    if CountDown~=nil then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CountDown)
        CountDown = nil
    end
    --PageInfo
    GloryHoleBase:SetPageInfo(container)

    local GuideManager = require("Guide.GuideManager")
    if not GuideManager.isInGuide then 
        GuideManager.openOtherGuideFun(GuideManager.guideType.GLORY_HOLE, false)
    end
end
function GloryHoleBase:SetPageInfo(container)
    --BtnState
    isOpen = PageInfo.isOpen
    if isOpen then
         NodeHelper:setNodesVisible(container,{mEnter = true,mPratice = false})
    else
         NodeHelper:setNodesVisible(container,{mEnter = false,mPratice = true})
    end
    --InfoState
     NodeHelper:setNodesVisible(container,{mOpenTxt = isOpen,mCloseTxt = not isOpen})
    --TeamChose
    if PageInfo.teamId == 0 then
        NodeHelper:setNodesVisible(container, {mChoose = true, mBottom = false, mChoseClose = false,mTeamBlueFlag2=false,mTeamRedFlag2=false, mTip01 = true,mTip02 = false})
        NodeHelper:setNodesVisible(container,{mTeam1Choose=false,mTeam2Choose=false})
    elseif not isPractice then
        NodeHelper:setNodesVisible(container, {mChoose = false, mBottom = true})
    end
     NodeHelper:setStringForLabel(container,{mChooseTitle=common:getLanguageString("@TeamChosen")})
    --Flag
     local isTeam1 = PageInfo.teamId == 1 and isOpen
     local isTeam2 = PageInfo.teamId == 2 and isOpen
     
     NodeHelper:setNodesVisible(container, {
         mTeamBlueFlag = isTeam1,
         mTeamBlueFlag2 = isTeam1,
         mTeamRedFlag = isTeam2,
         mTeamRedFlag2 = isTeam2
     })

    --PageInfo
    UserInfo.sync()
    local StringTable = {}
    local ScaleTable = {}
    local Team1Txt = "0%"
    local Team2Txt = "0%"
    local DailyLeftTime = PageInfo.dailyLeftTime --common:second2DateString2(PageInfo.dailyLeftTime, false)
    local ActLeftTime = PageInfo.actLeftTime--common:second2DateString2(PageInfo.actLeftTime, false)
    local TotalScore = PageInfo.Team1_Score + PageInfo.Team2_Score
    local BestScore = PageInfo.BestScore
    if BestScore == 0 then BestScore = "---" end
    if isOpen then
        if TotalScore ~= 0 then
            Team1Txt = string.format("%.1f", (PageInfo.Team1_Score / TotalScore) * 100) .. "%"
            Team2Txt = string.format("%.1f", (PageInfo.Team2_Score / TotalScore) * 100) .. "%"
        end
    else
        Team1Txt = "50%"
        Team2Txt = "50%"
    end
    StringTable["mBlueTxt"] = Team1Txt
    StringTable["mRedTxt"] = Team2Txt
    ScaleTable["mBlueTxt"] = 0.8
    ScaleTable["mRedTxt"] = 0.8
    StringTable["mParticipants"] = PageInfo.participants
    if PageInfo.challengeTime ~= 0 then
        StringTable["mChallengeTxt"] = common:getLanguageString("@TodayFreeTreasureHunt")
        StringTable["mChallengeTime"] =  PageInfo.challengeTime.." / ".. FREE_TIMES_LIMIT
    else 
        StringTable["mChallengeTxt"] = common:getLanguageString("@Eighteenbtncontent11")
        StringTable["mChallengeTime"] =  PageInfo.CanBuyCount
    end
    if not CountDown then
        CountDown = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function()
            -- 更新 leftTime
            DailyLeftTime = DailyLeftTime - 1
            GloryHoleDataBase:setLeftTime(DailyLeftTime)
            local txt2 = ""
            --每日時間
            if DailyLeftTime > 86400 then
                txt2 = common:getDayNumber(DailyLeftTime) + 1 .. common:getLanguageString("@Days")
            else
                txt2 = common:dateFormat2String(DailyLeftTime, true)
            end
            if isOpen then
                NodeHelper:setStringForLabel(container, {mDailyLeftTime=txt2})
            else
                NodeHelper:setStringForLabel(container, {mOpenTime=txt2})
            end
        end, 1, false)
    end
    --StringTable["mTime"] = ActLeftTime
    --StringTable["mDailyLeftTime"] = DailyLeftTime
    StringTable["mBestScore"] = BestScore
    StringTable["mVipLv"] = 5
    StringTable["mTime"] = common:getLanguageString("@GloryHoleOpenDay")
    NodeHelper:setStringForLabel(container, StringTable)
    
    NodeHelper:setNodesVisible(container, {mItem = false, mBootser = false, mMission = false})
    for key, value in pairs(ScaleTable) do
        local node = container:getVarNode(key)
        if node then
            node:setScale(value)
        end
    end
    --ItemBtn
    if not GloryHoleBase:VIPSync() then
        NodeHelper:setMenuItemImage(container, {mItem1 = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"}})
        NodeHelper:setNodesVisible(container, {mVipLv = false})
    end
    --TableSort
    GloryHoleTable={}
    for key,value in pairs (GloryHoleCfg) do
        if not GloryHoleTable[value.HeroId] then
            GloryHoleTable[value.HeroId]={}
        end
        if not GloryHoleTable[value.HeroId][value.Type] then
            GloryHoleTable[value.HeroId][value.Type]={}
        end
        GloryHoleTable[value.HeroId][value.Type]=value
    end
    --BGSpine
    GloryHoleBase:buildBGSpine(container)
end
function GloryHoleBase:buildBGSpine(container)
    -- 獲取父節點
    local parentNode = container:getVarNode("mSpine")
    if not parentNode then
        print("Parent node 'mSpine' not found.")
        return
    end

    -- 清空父節點的所有子節點
    parentNode:removeAllChildren()

    -- 函數：安全創建 Spine 物件
    local function createSpineSafely(spineName)
        if not spineName or spineName == "" then
            print("Invalid spine name provided.")
            return nil
        end

        local success, spineContainer = pcall(function()
            return SpineContainer:create("Spine/Gloryhole", spineName)
        end)

        if success and spineContainer then
            return spineContainer
        else
            print("Error creating SpineContainer for:", spineName)
            return nil
        end
    end

    -- 函數：將 Spine 添加到父節點並播放動畫
    local function addSpineToParentWithAnimation(spineName, parent, animationName)
        local spine = createSpineSafely(spineName)
        if not spine then
            return
        end

        local spineNode = tolua.cast(spine, "CCNode")
        if not spineNode then
            print("Failed to cast SpineContainer to CCNode for:", spineName)
            return
        end

        parent:addChild(spineNode)
        spineNode:setScale(NodeHelper:getScaleProportion())

        local animSuccess = pcall(function()
            spine:runAnimation(1, animationName, -1)
        end)
        if not animSuccess then
            print("Failed to run animation:", animationName, "for spine:", spineName)
        end
    end

    -- 添加並運行背景 Spine 動畫
    local spineNames = {
        {name = "NGUI_93_GloryholeBG", animation = "animation"},
        {name = "NGUI_93_GloryholeTOP", animation = "animation"}
    }

    for _, spineInfo in ipairs(spineNames) do
        addSpineToParentWithAnimation(spineInfo.name, parentNode, spineInfo.animation)
    end
end

function GloryHoleBase:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.ACTIVITY175_GLORY_HOLE_S then
        local msg = Activity5_pb.GloryHoleResp()
        msg:ParseFromString(msgBuff)
        if msg.action == 0 then
            GloryHoleBase_SetInfo(msg)
            self:SetPageInfo(self.container)
            isPlaying = false
        elseif msg.action == 2 then
            GloryHoleBase_SetInfo(msg)
            parentPage:onEnter(parentPage.container)
        elseif msg.action == 3 then
            local items = {}
            if GloryHoleBase:VIPSync() and UsingItem ~= 0 then
                items[1] = UsingItem
            elseif not GloryHoleBase:VIPSync() then
                for k, v in pairs(UsingItems) do
                    items[k] = v
                end
            end
            local maxScore = msg.gameInfo.maxScore
            isPractice = false

            local PlayData=GloryHoleTable[NowHeroId][PageInfo.teamId-1]
            local PlayPage = require("GloryHolePlayPage")
            PlayPage:setData( "Play", maxScore, items,PlayData)
            isPlaying = true
            PageManager.pushPage("GloryHolePlayPage")

            GloryHoleBase:ClearItems(self.container)
        elseif msg.action == 6 or msg.action == 7 then
            GloryHoleBase_SetInfo(msg)
            GloryHoleBase:BuildScrollview(self.container, false)
            NodeHelper:setNodesVisible(self.container, {mMission = true})
            if msg.action == 7 then
                --MessageBoxPage:Msg_Box(common:getLanguageString('@RewardItem2'))
            end
        elseif msg.action == 8 or msg.action == 9 or msg.action == 10 then
            GloryHoleBase_SetInfo(msg)
            GloryHoleBase:BuildScrollview(self.container, true)
            NodeHelper:setNodesVisible(self.container, {mMission = true})
            if msg.action ~= 8 then
               --MessageBoxPage:Msg_Box(common:getLanguageString('@RewardItem2'))
            end
        end
    elseif opcode == HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_S then
        local msg = Activity5_pb.ActivityExchangeResp()
        msg:ParseFromString(msgBuff)
        for key, data in pairs(msg.exchangeInfo) do
            local id = data.exchangeItem and common:split(data.exchangeItem, "_")[2]
            if id == nil then return end
            if not ItemInfoTable[id] then
                ItemInfoTable[id] = {Cost = 0, got = 0}
            end
            ItemInfoTable[id].Cost = data.consumeItem
            ItemInfoTable[id].mID = data.exchangeId
            ItemInfoTable[id].got = data.gotCount
        end
    end
     if opcode == HP_pb.PLAYER_AWARD_S then
        if isPlaying then
            local msg = Reward_pb.HPPlayerReward();
            msg:ParseFromString(msgBuff)
            if msg ~= nil then
              local rewards = msg.rewards.showItems
                local showReward = { }
                for i = 1, #rewards do
                    local oneReward = rewards[i]
                    if oneReward.itemCount > 0 then
                        local resInfo = { }
                        resInfo["type"] = oneReward.itemType
                        resInfo["itemId"] = oneReward.itemId
                        resInfo["count"] = oneReward.itemCount
                        --- ??代表神器
                        if oneReward:HasField("itemStatus") and oneReward["itemStatus"] == 1 then
                            resInfo["isGodly"] = true
                        end
                        showReward[#showReward + 1] = resInfo
                    end
                end
                local PlayPage = require("GloryHolePlayPage")
                PlayPage:setRewardData(showReward)
            end
        else
            local PackageLogicForLua = require("PackageLogicForLua")
            PackageLogicForLua.PopUpReward(msgBuff)
        end
    end
end
function GloryHoleBase:SetContentSize(container, MaxData, Data)
    
    local Scale = Data / tonumber(MaxData) or 0
    if Scale > 1 then Scale = 1 end
    local Bar = tolua.cast(container:getVarNode("mBar"), "CCScale9Sprite")
    Bar:setContentSize(CCSize(399 * Scale, Bar:getContentSize().height))
    if Data == 0 then
        NodeHelper:setNodesVisible(container, {mBar = false})
    else
        NodeHelper:setNodesVisible(container, {mBar = true})
    end
end
function GloryHoleBase_refreshPage()
    UsingItem = 0
    UsingItems = {}
    parentPage:onEnter(parentPage.container)
end
function GloryHoleBase:BuildScrollview(container, isDaily)
    local _Daily = false
    local Scrollview
    local Data = GloryHoleDataBase:getMission()
    if isDaily ~= nil then
        _Daily = isDaily
    end
    if _Daily then
        local parent = container:getVarNode("mTaskNode")
        parent:removeAllChildrenWithCleanup(true)
        local TaskCCB = ScriptContentBase:create("GloryHole_DailyContent")
        Target = {[25]={},[50]={},[75]={},[100]={}}
        for i = 1, 4 do
            local TargetId = Data.DailyMission.Target[i] and Data.DailyMission.Target[i].dailyPointNumber
            if TargetId then
                Target[TargetId] = Data.DailyMission.Target[i] and Data.DailyMission.Target[i].dailyPointNumber or {}
            end
        end
        TaskCCB:registerFunctionHandler(DailyCCB.onFunction)
        GloryHoleBase:SetContentSize(TaskCCB, 100, Data.DailyPoint)
        NodeHelper:setStringForLabel(TaskCCB, {mNowPoint = Data.DailyPoint or 0})

       local boxVisibilityConditions = {
            [25] = "mBoxPoint1",
            [50] = "mBoxPoint2",
            [75] = "mBoxPoint3",
            [100] = "mBoxPoint4"
        }
        
        -- 設定節點的可見狀態（自動處理條件）
        for point, boxName in pairs(boxVisibilityConditions) do
            local isVisible = Data.DailyPoint >= point and Target[point] ~= point
            NodeHelper:setNodesVisible(TaskCCB, {[boxName] = isVisible})
        end
        
        -- 處理每個目標點數的子節點顯示邏輯
        for i, v in pairs(Target) do
            local dailyPointReached = Data.DailyPoint >= i -- 當前點數是否達標
            local isRewardCollected = (i == v) -- 是否已領取
        
            for j = 0, 2 do
                local curName = string.format("mTaskRewardBox%d_%d", j, i)
                local sprite = TaskCCB:getVarNode(curName)
        
                if sprite then
                    if j == 0 then
                        -- 不可領取（未達成）
                        sprite:setVisible(not dailyPointReached)
                    elseif j == 1 then
                        -- 可領取（達標但未領取）
                        sprite:setVisible(dailyPointReached and not isRewardCollected)
                    elseif j == 2 then
                        -- 已領取
                        sprite:setVisible(isRewardCollected)
                    end
                end
            end
        end

        parent:addChild(TaskCCB)
        local Scrollview = TaskCCB:getVarScrollView("mContent")
        Scrollview:removeAllCell()
        for _, Data in pairs(Data.DailyMission.Quest) do
            local Info = Data
            local cell = CCBFileCell:create()
            cell:setCCBFile(DailyMissionContent.ccbiFile)
            local handler = common:new({Data = Info}, DailyMissionContent)
            cell:registerFunctionHandler(handler)
            Scrollview:addCell(cell)
        end
        Scrollview:orderCCBFileCells()
    else
        local scrollview = container:getVarScrollView("mAchiveScrollview")
        scrollview:removeAllCell()
        local TypeTable = {}
        for key, value in pairs(Data.Achivement) do
            if not TypeTable[value.missionType] then
                TypeTable[value.missionType] = {}
            end
            table.insert(TypeTable[value.missionType], {Type = value.missionType,
                Count = value.count,
                took = value.took})
        end
        local BuildTable={}
        local finishedTable={}
        local cfg = ConfigManager.getGloryHoleQuestCfg()
        local Table = {}
        for key, value in pairs(cfg) do
            if not Table[value.showType] then
            Table[value.showType] = {}
            end
            table.insert(Table[value.showType], value)
        end
        for k, v in pairs(TypeTable) do
             local Info = v
             if #Info[1].took<#Table[k] then
                table.insert(BuildTable,Info)
             else
                table.insert(finishedTable,Info)
             end
        end
        for k,v in pairs (finishedTable) do
            table.insert(BuildTable,v)
        end
        for i = 1, #BuildTable do
            local Info = BuildTable[i][1]
            local cell = CCBFileCell:create()
            cell:setCCBFile(AchivementContent.ccbiFile)
            local handler = common:new({id = i, Type = Info.Type, Count = Info.Count, Took = Info.took}, AchivementContent)
            cell:registerFunctionHandler(handler)
            cell:setScale(0.99)
            scrollview:addCell(cell)
        end
        scrollview:orderCCBFileCells()
    end
end
function DailyMissionContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local cfg = ConfigManager.getGloryHoleDailyQuest()
    local questId = self.Data.questId
    local takeStatus = self.Data.takeStatus
    local questStatus = self.Data.questStatus
    local taskRewards = self.Data.taskRewards
    local questCompleteCount = self.Data.questCompleteCount
    local StringTable = {}
    local VisableTable = {}
    local value = cfg[questId]
    local normalImage = NodeHelper:getImageByQuality(value.quality)
    local iconBg = NodeHelper:getImageBgByQuality(value.quality)
    if questCompleteCount > value.targetCount then
        questCompleteCount = value.targetCount
    end
    container:getVarNode("mContent"):setScale(0.9)
    container:getVarLabelTTF("mContent"):setDimensions(CCSize(340, 100))
    VisableTable["mStarNode"] = false
    VisableTable["selectedNode"] = false
    VisableTable["nameBelowNode"] = false
    VisableTable["mPoint"] = false
    StringTable["mContent"] = common:getLanguageString(value.content)
    StringTable["mName"] = common:getLanguageString(value.name)
    StringTable["mCount"] = questCompleteCount .. "/" .. value.targetCount
    StringTable["mBtnTxt"] = common:getLanguageString("@GVGRewardGetTxt")
    if takeStatus == 1 then
        StringTable["mBtnTxt"] = common:getLanguageString("@AlreadyReceive")
    end
    StringTable["mNumber1_1"] = value.des
    AchivementContent:setContentScale(container, value.targetCount, questCompleteCount)
    NodeHelper:setStringForLabel(container, StringTable)
    NodeHelper:setMenuItemsEnabled(container, {mBtn = (takeStatus == 0 and questStatus == 1)})
    NodeHelper:setNodesVisible(container, VisableTable)
    NodeHelper:setSpriteImage(container, {mFrameShade1 = iconBg, mPic1 = value.icon})
    NodeHelper:setMenuItemImage(container, {mHand1 = {normal = normalImage}})
end
function AchivementContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    local cfg = ConfigManager.getGloryHoleQuestCfg()
    local Table = {}
    for key, value in pairs(cfg) do
        if not Table[value.showType] then
            Table[value.showType] = {}
        end
        table.insert(Table[value.showType], value)
    end
    
    local StringTable = {}
    local VisableTable = {}
    local TypeTable = Table[self.Type]
    local State --1:Not Finish 2:Finish NotReceive 3:Received
    VisableTable["mStarNode"] = false
    VisableTable["selectedNode"] = false
    VisableTable["nameBelowNode"] = false
    VisableTable["mPoint"] = false
    
    for k, v in pairs(TypeTable) do
        local _type, _id, _count = unpack(common:split(v.reward, "_"))
        self.reward = v.reward
        local cfg = {Type = tonumber(_type), id = tonumber(_id), count = tonumber(count)}
        local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.Type, cfg.id, cfg.count)
        local normalImage = NodeHelper:getImageByQuality(resInfo.quality)
        local iconBg = NodeHelper:getImageBgByQuality(resInfo.quality)
        NodeHelper:setMenuItemImage(container, {mHand1 = {normal = normalImage}})
        container:getVarNode("mContent"):setScale(0.9)
        container:getVarLabelTTF("mContent"):setDimensions(CCSize(340, 100))
        
        NodeHelper:setSpriteImage(container, {mPic1 = resInfo.icon, mFrameShade1 = iconBg})
        StringTable["mNumber1_1"] = _count
        if self.Count < v.questType then
            State = 1
            StringTable["mContent"] = common:getLanguageString(v.content)
            StringTable["mName"] = common:getLanguageString(v.name)
            if self.Count <1000 or v.questType <1000 then
                StringTable["mCount"] = self.Count .. "/" .. v.questType
            else
                StringTable["mCount"] = math.floor(self.Count/1000) .. "K/" .. v.questType/1000 .. "K"
            end
            StringTable["mBtnTxt"] = common:getLanguageString("@GVGRewardGetTxt")
            AchivementContent:setContentScale(container, v.questType, self.Count)
            break
        else
            if self.Took[k] then
                State = 3
                StringTable["mContent"] = common:getLanguageString(v.content)
                StringTable["mName"] = common:getLanguageString(v.name)
                if self.Count <1000 and v.questType <1000 then
                    StringTable["mCount"] = self.Count .. "/" .. v.questType
                else
                    StringTable["mCount"] = math.floor(self.Count/1000) .. "K/" .. v.questType/1000 .. "K"
                end
                StringTable["mBtnTxt"] = common:getLanguageString("@AlreadyReceive")
                AchivementContent:setContentScale(container, v.questType, self.Count)
            else
                State = 2
                StringTable["mContent"] = common:getLanguageString(v.content)
                StringTable["mName"] = common:getLanguageString(v.name)
               if self.Count <1000 and v.questType <1000 then
                   StringTable["mCount"] = self.Count .. "/" .. v.questType
               else
                   StringTable["mCount"] = math.floor(self.Count/1000) .. "K/" .. v.questType/1000 .. "K"
               end
                StringTable["mBtnTxt"] = common:getLanguageString("@GVGRewardGetTxt")
                AchivementContent:setContentScale(container, v.questType, self.Count)
                self.ReceiveCount = v.questType
                break
            end
        end
    end
    NodeHelper:setStringForLabel(container, StringTable)
    NodeHelper:setMenuItemsEnabled(container, {mBtn = (State == 2)})
    NodeHelper:setNodesVisible(container, VisableTable)
end
function AchivementContent:onBtn()
    local Type = self.Type
    local Count = self.ReceiveCount
    GloryHoleBase:InfoRequest(7, Type, Count)
end
function AchivementContent:onHand1(container)
    local reward = common:split(self.reward, "_")
    local cfg = {type = tonumber(reward[1]),
        itemId = tonumber(reward[2]),
        count = tonumber(reward[3])};
    GameUtil:showTip(container:getVarNode('mPic1'), cfg)
end
function DailyMissionContent:onBtn()
    local id = self.Data.questId
    GloryHoleBase:InfoRequest(9, id)
end
function DailyMissionContent:onHand1(container)
    local reward = common:split(self.Data.taskRewards, "_")
    local cfg = {
        type = tonumber(reward[1]),
        itemId = tonumber(reward[2]),
        count = tonumber(reward[3])};
    GameUtil:showTip(container:getVarNode('mPic1'), cfg)
end
function AchivementContent:setContentScale(container, MaxData, SeverData)
    local Scale = SeverData / tonumber(MaxData) or 0
    if Scale > 1 then Scale = 1 end
    local Bar = tolua.cast(container:getVarNode("mCountSprite"), "CCScale9Sprite")
    Bar:setContentSize(CCSize(DailyMissionContent.BarLong * Scale, Bar:getContentSize().height))
    if SeverData == 0 then
        NodeHelper:setNodesVisible(container, {mCountSprite = false})
    else
        NodeHelper:setNodesVisible(container, {mCountSprite = true})
    end
end
function GloryHoleBase:ClearItems(container)
    UsingItem = 0
    UsingItems = {}
    local ItemMap = {}
    if GloryHoleBase:VIPSync() then
        ItemMap["mItem1"] = {normal = "GloryHole_btn03_01.png", press = "GloryHole_btn03_02.png"}
        ItemMap["mItem2"] = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"}
    else
        ItemMap["mItem1"] = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"}
        ItemMap["mItem2"] = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"}
    end
    NodeHelper:setMenuItemImage(container, ItemMap)
    NodeHelper:setNodesVisible(container, {mChosen1 = false, mChosen2 = false, mChosen3 = false, mChosen4 = false})
end
function GloryHoleBase:onClose(container)
    parentPage:removePacket(opcodes)
    --parentPage.container:unregisterFunctionHandler()
    if CountDown~=nil then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(CountDown)
        CountDown = nil
    end
    UsingItem = 0
    UsingItems = {}
    isPlayedOpenAni = false
    --PageManager.popPage(thisPageName)
end
function GloryHoleBase:onExecute(container)

end
function DailyCCB.onFunction(eventName, container)
    local BgImg = "message_GH_bg.png"
    local function handleEvent(targetIndex, dataPoint, rewardPoint)
        local Data = GloryHoleDataBase:getMission()
        if Target[targetIndex] == targetIndex then
            MessageBoxPage:Msg_Box_Lan("@dailyQuestPointGotTxt")
        elseif Target[targetIndex] ~= targetIndex and Data.DailyPoint < rewardPoint then
            RegisterLuaPage("DailyTaskRewardPreview")
            ShowRewardPreview(GloryHoleDailyQuestPointCfg[rewardPoint].award, common:getLanguageString("@TaskDailyRewardPreviewTitle"), common:getLanguageString("@TaskDailyRewardPreviewInfo"), BgImg)
            PageManager.pushPage("DailyTaskRewardPreview")
        else
            GloryHoleBase:InfoRequest(10, nil, rewardPoint)
        end
    end
    
    if eventName == "onGetBox1" then
        handleEvent(25, 25, 25)
    elseif eventName == "onGetBox2" then
        handleEvent(50, 50, 50)
    elseif eventName == "onGetBox3" then
        handleEvent(75, 75, 75)
    elseif eventName == "onGetBox4" then
        handleEvent(100, 100, 100)
    end
end
function GloryHoleBase_refreshItem()
    updateItemDetails(20001, "mItemTitle1", "mItemTxt1", "mItemLeft1")
    updateItemDetails(20002, "mItemTitle2", "mItemTxt2", "mItemLeft2")
    updateItemDetails(20004, "mItemTitle3", "mItemTxt3", "mItemLeft3")
end
 function updateItemDetails(itemId, titleKey, descKey, itemLeftKey)
    local StringTable={ }
     -- ?取物品?量
     local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, itemId).count or 0
 
     -- 更新??和描述
     StringTable[titleKey] = common:getLanguageString("@Item_" .. itemId)
     StringTable[descKey] = common:getLanguageString("@Item_Desc_" .. itemId)
 
     -- 更新剩余?量
     if itemCount > 0 then
         StringTable[itemLeftKey] = common:getLanguageString("@drawFashionTxt2") .. itemCount
     else
         StringTable[itemLeftKey] = common:getLanguageString("@TapToBuy")
     end
     NodeHelper:setStringForLabel(selfContainer, StringTable)
 end
function GloryHoleBase.onFunction(eventName, container)
    if eventName == "luaExecute" then
        if GloryHoleBase:VIPSync() then
            NodeHelper:setNodesVisible(container, {mChosen1 = (1 == UsingItem), mChosen2 = (2 == UsingItem), mChosen3 = (3 == UsingItem), mChosen4 = (4 == UsingItem)})
        else
            NodeHelper:setNodesVisible(container, {mChosen1 = false, mChosen2 = false, mChosen3 = false, mChosen4 = false})
            for k, v in pairs(UsingItems) do
                NodeHelper:setNodesVisible(container, {["mChosen" .. v] = true})
            end
        end
        
    elseif eventName == "onTeam1" then
        ChosenTeam=1
    elseif eventName == "onTeam2" then
        ChosenTeam=2
    elseif eventName == "onTeam" then
        if ChosenTeam==1 then
            GloryHoleBase:onTeam1(container)
        elseif ChosenTeam==2 then
            GloryHoleBase:onTeam2(container)
        else
            if isPractice then
                MessageBoxPage:Msg_Box(common:getLanguageString("@GloryHoleModeChosenHint"))
            else
                MessageBoxPage:Msg_Box(common:getLanguageString("@GloryHoleTeamChosenHint"))
            end
        end
    elseif eventName == "onItem" then
        NodeHelper:setNodesVisible(container, {mBootser = true})
        local StringTable = {}    

        GloryHoleBase_refreshItem()

        for i = 1, 3 do
            local messageTxt = container:getVarLabelTTF("mItemTxt" .. i)
            messageTxt:setDimensions(CCSize(220, 100))
        end
        
        GloryHoleBase:ItemInfoRequest()
    elseif eventName == "onItem1" then
        local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, 20001).count or 0
        if itemCount == 0 then
            PageManager.BuyActivityItem(175, 20001, 30000, ItemInfoTable)--(ActivityId,itemId,itemType,table)
            return
        end
        if GloryHoleBase:VIPSync() then
            if UsingItem == 1 then
                UsingItem = 0
            else
                UsingItem = 1
            end
        else
            GloryHoleBase:ItemChose(1)
        end
    elseif eventName == "onItem2" then
        local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, 20002).count or 0
        if itemCount == 0 then
            PageManager.BuyActivityItem(175, 20002, 30000, ItemInfoTable)--(ActivityId,itemId,itemType,table)
            return
        end
        if GloryHoleBase:VIPSync() then
            if UsingItem == 2 then
                UsingItem = 0
            else
                UsingItem = 2
            end
        else
            GloryHoleBase:ItemChose(2)
        end
    elseif eventName == "onItem3" then
        local itemCount = InfoAccesser:getUserItemInfo(Const_pb.TOOL, 20004).count or 0
        if itemCount == 0 then
            PageManager.BuyActivityItem(175, 20004, 30000, ItemInfoTable)--(ActivityId,itemId,itemType)
            return
        end
        if GloryHoleBase:VIPSync() then
            if UsingItem == 3 then
                UsingItem = 0
            else
                UsingItem = 3
            end
        else
            GloryHoleBase:ItemChose(3)
        end
    --elseif eventName == "onItem4" then
    --    if GloryHoleBase:VIPSync() then
    --        if UsingItem == 4 then
    --            UsingItem = 0
    --        else
    --            UsingItem = 4
    --        end
    --    else
    --        GloryHoleBase:ItemChose(4)
    --    end
    elseif eventName == "onConfirmItem" then
        NodeHelper:setNodesVisible(container, {mBootser = false})
        -- 初始化 ItemMap
        local ItemMap = {
            mItem1 = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"},
            mItem2 = {normal = "GloryHole_btn02_01.png", press = "GloryHole_btn02_02.png"}
        }
                
        local function updateItemMap(item1Icon, item2Icon)
            if item1Icon then
                ItemMap["mItem1"] = {normal = item1Icon, press = item1Icon}
            end
            if item2Icon then
                ItemMap["mItem2"] = {normal = item2Icon, press = item2Icon}
            end
        end
        
        if GloryHoleBase:VIPSync() then
            if UsingItem == 0 then
                updateItemMap("GloryHole_btn03_01.png", "GloryHole_btn02_01.png")
            else
                updateItemMap("GloryHole_btn03_01.png", ItemIcon[UsingItem])
            end
        elseif UsingItems[1] and UsingItems[2] then
            updateItemMap(ItemIcon[UsingItems[1]], ItemIcon[UsingItems[2]])
        elseif UsingItems[1] then
            updateItemMap(ItemIcon[UsingItems[1]], nil)
        elseif UsingItems[2] then
            updateItemMap(nil, ItemIcon[UsingItems[2]])
        end
        NodeHelper:setMenuItemImage(container, ItemMap)

    elseif eventName == "onReturn" then
        GloryHoleBase:onClose(container)
    elseif eventName == "onVIP" then
        if GloryHoleBase:VIPSync() then
            --PageManager.pushPage("Recharge.RechargeVIPPage")
             local title = common:getLanguageString("@Activate");
             local msg = common:getLanguageString("@GloryHoleVIP5Hint");
             PageManager.showConfirm(title, msg, function(isSure)
                 if isSure then
                     require("IAP.IAPPage"):setEntrySubPage("Diamond")
                     PageManager.pushPage("IAP.IAPPage")   
                 end
             end,nil,"@DimondShopTitle","@Confirmation")
        else
            NodeHelper:setNodesVisible(container, {mBootser = true})

            GloryHoleBase_refreshItem()

            for i = 1, 3 do
                local messageTxt = container:getVarLabelTTF("mItemTxt" .. i)
                messageTxt:setDimensions(CCSize(220, 100))
            end
            NodeHelper:setStringForLabel(container, StringTable)
            
            GloryHoleBase:ItemInfoRequest()
        end
    elseif eventName == "onMission" then
        NodeHelper:setNodesVisible(container, {mMission = true, mDailyOn = true, mAchiveOn = false, mAchiveScrollview = false, mTaskNode = true, mNotOpenMask = not isOpen})
        if isOpen then
            GloryHoleBase:InfoRequest(8, teamId, newScore, costItem, useItem, gameStatus)
        end
        GloryHoleBase:InfoRequest(6, teamId, newScore, costItem, useItem, gameStatus)
        NodeHelper:setNodesVisible(container, {mDailyOn = true, mAchiveOn = false, mAchiveScrollview = false, mTaskNode = true,mNotOpenMask = not isOpen})
        NodeHelper:setStringForLabel(container, {mTitle = common:getLanguageString("@Act141DailyTasksBtnText")})
    elseif eventName == "onDailyMission" then
        NodeHelper:setNodesVisible(container, {mMission = true, mDailyOn = true, mAchiveOn = false, mAchiveScrollview = false, mTaskNode = true, mNotOpenMask = not isOpen})
        NodeHelper:setMenuItemsEnabled(container, {mDailyOn = false, mAchiveOn = true})
        NodeHelper:setStringForLabel(container, {mTitle = common:getLanguageString("@Act141DailyTasksBtnText")})
    elseif eventName == "onAchiveMission" then
        NodeHelper:setNodesVisible(container, {mMission = true, mDailyOn = false, mAchiveOn = true, mAchiveScrollview = true, mTaskNode = false , mNotOpenMask = false})
        NodeHelper:setMenuItemsEnabled(container, {mDailyOn = true, mAchiveOn = false})
        NodeHelper:setStringForLabel(container, {mTitle = common:getLanguageString("@TaskAchievementName")})
    elseif eventName == "onCloseMission" then
        NodeHelper:setNodesVisible(container, {mMission = false})
        container:getVarNode("mTaskNode"):removeAllChildren()
    elseif eventName == "onPlay" then
        local currentHour = os.date("*t").hour
        if currentHour>=23 then
            MessageBoxPage:Msg_Box(common:getLanguageString("@GloryHoleOpenDay3"))
            return
        end
        --Item
        local useItem = {["addbar"] = false,
            ["offset"] = false,
            ["addGain"] = false}
        local function setUseItem(flag)
            if flag == 1 then
                useItem["offset"] = true
            elseif flag == 2 then
                useItem["addbar"] = true
            elseif flag == 3 then
                useItem["addGain"] = true
            end
        end
        if GloryHoleBase:VIPSync() and UsingItem ~= 0 then
            setUseItem(UsingItem)
        elseif not GloryHoleBase:VIPSync() then
            for _, v in pairs(UsingItems) do
                setUseItem(v)
            end
        end
        --Game
        if PageInfo.challengeTime > 0 then
            GloryHoleBase:InfoRequest(3, nil, nil, nil, useItem)
        elseif PageInfo.challengeTime == 0 and PageInfo.CanBuyCount >0 then
            local title = common:getLanguageString("@MultiTimesQuit")
            local msg = common:getLanguageString("@DoChanllengeArenaPurchaseTimesMsg", PageInfo.NowPayNum)
            PageManager.showConfirm(title, msg, function(isSure)
                if isSure then
                    GloryHoleBase:InfoRequest(3, nil, nil, true, useItem)
                end
            end, true, nil, nil, true, 0.9);
        elseif PageInfo.challengeTime == 0 and PageInfo.CanBuyCount <=0 then
            MessageBoxPage:Msg_Box(common:getLanguageString('@BuyCountLimit'))
        end
    elseif eventName == "onPractice" then
        ChosenTeam=0       
        GloryHoleBase:InfoRequest(5, nil, nil, nil, useItem)
        NodeHelper:setNodesVisible(container, {mChoose = true,mTip01 = false,mTip02 = true})
        NodeHelper:setStringForLabel(container,{mChooseTitle=common:getLanguageString("@ModeChosen")})
        isPractice = true
    elseif eventName == "onChoseClose" and isPractice then
        NodeHelper:setNodesVisible(container, {mChoose = false, mChoseClose = true})
    elseif eventName == "onHelp" then
        GloryHoleBase:onHelp(container)
    end
    if GloryHoleBase:VIPSync() then
        NodeHelper:setNodesVisible(container, {mChosen1 = (1 == UsingItem), mChosen2 = (2 == UsingItem), mChosen3 = (3 == UsingItem), mChosen4 = (4 == UsingItem)})
    else
        NodeHelper:setNodesVisible(container, {mChosen1 = false, mChosen2 = false, mChosen3 = false, mChosen4 = false})
        for k, v in pairs(UsingItems) do
            NodeHelper:setNodesVisible(container, {["mChosen" .. v] = true})
        end
    end
    NodeHelper:setNodesVisible(container,{mTeam1Choose=(ChosenTeam==1),mTeam2Choose=(ChosenTeam==2)})
end
function GloryHoleBase:onTeam1(container)
     local items = {}
     if GloryHoleBase:VIPSync() and UsingItem ~= 0 then
         items[1] = UsingItem
     elseif not GloryHoleBase:VIPSync() then
         for k, v in pairs(UsingItems) do
             items[k] = v
         end
     end
     local PlayPage = require("GloryHolePlayPage")
     local PlayData=GloryHoleTable[NowHeroId][0]
     PlayPage:setData( "Pratice", nil, items,PlayData)
     if isPractice then
         PageManager.pushPage("GloryHolePlayPage")
         NodeHelper:setNodesVisible(container, {mChoose = false})
     else
         GloryHoleBase:InfoRequest(2, 1)
     end
     NodeHelper:setNodesVisible(container, {mChoose = false})
end
function GloryHoleBase:onTeam2(container)
     local items = {}
     if GloryHoleBase:VIPSync() and UsingItem ~= 0 then
         items[1] = UsingItem
     elseif not GloryHoleBase:VIPSync() then
         for k, v in pairs(UsingItems) do
             items[k] = v
         end
     end
     local PlayData=GloryHoleTable[NowHeroId][1]
     local PlayPage = require("GloryHolePlayPage")
     PlayPage:setData("Pratice", nil, items,PlayData)
     if isPractice then
         PageManager.pushPage("GloryHolePlayPage")
         NodeHelper:setNodesVisible(container, {mChoose = false})
     else
         GloryHoleBase:InfoRequest(2, 2)
     end
     NodeHelper:setNodesVisible(container, {mChoose = false})
end
function GloryHoleBase:ItemChose(idx)
    if #UsingItems == 0 then
        UsingItems[1] = idx
    elseif UsingItems[1] and UsingItems[1] == idx then
        UsingItems[1] = nil
    elseif UsingItems[2] and UsingItems[2] == idx then
        UsingItems[2] = nil
    elseif UsingItems[1] and UsingItems[1] ~= idx and not UsingItems[2] then
        UsingItems[2] = idx
    elseif UsingItems[2] and UsingItems[2] ~= idx and not UsingItems[1] then
        UsingItems[1] = idx
    elseif UsingItems[1] and UsingItems[1] ~= idx and UsingItems[2] and UsingItems[2] ~= idx then
        UsingItems[2] = idx
    end
end
function GloryHoleBase:VIPSync()
    return false --UserInfo.playerInfo.vipLevel < 5
end
function GloryHoleBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_DAILY_BUNDLE)
end
function GloryHoleBase:InfoRequest(action, teamId, newScore, costItem, useItem, gameStatus)
    local Activity5_pb = require("Activity5_pb")
    local msg = Activity5_pb.GloryHoleReq()
    msg.action = action
    if teamId then
        msg.teamId = teamId
    end
    if newScore then
        msg.newScore = newScore
    end
    if costItem then
        msg.costItem = true
    end
    if useItem then
        msg.useItem.addbar = useItem["addbar"]
        msg.useItem.offset = useItem["offset"]
        msg.useItem.addGain = useItem["addGain"]
    end
    if gameStatus then
        msg.gameStatus.fanatic = gameStatus.fanatic
        msg.gameStatus.good = gameStatus.good
    end
    common:sendPacket(HP_pb.ACTIVITY175_GLORY_HOLE_C, msg, true)

end
function GloryHoleBase:ItemInfoRequest()
    local msg = Activity5_pb.ActivityExchangeReq()
    msg.action = 0
    msg.activityId = 175
    common:sendPacket(HP_pb.ACTIVITY176_ACTIVITY_EXCHANGE_C, msg, true)
end
function GloryHoleBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GLORY_HOLE)
end
local CommonPage = require('CommonPage')
GloryHolePage = CommonPage.newSub(GloryHoleBase, thisPageName, option)

return GloryHolePage
