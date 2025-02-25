----------------------------------------------------------------------------------
--[[
	 成就
--]]
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'MissionLineTask'
local Activity_pb = require("Activity_pb");
local MissionManager = require("MissionManager")
local HP_pb = require("HP_pb");
local ItemManager = require "Item.ItemManager"
local Const_pb = require("Const_pb")
local Quest_pb = require("Quest_pb")
local GuideManager = require("Guide.GuideManager")
require("Shop_pb");
local MissionLineTask = {
}
local _lineTaskPacket = nil
local _curShowTaskInfo = nil
local curPagePacketData = nil
local selfContainer = nil
local ITEM_COUNT_PER_LINE = 2
local TaskContent = {}
local questCfg = {}
local _taskTypeIndex = -1
local goBattlePage = false;--下一帧跳转到战斗界面
local isReceiveSeverMsg = false
local BAR_WIDTH = 100
local BAR_HEIGHT = 21

function TaskContent_onConfirmation(id,isSpecial)
    local taskId = id or 1
    local packetInfo = _curShowTaskInfo[taskId]
    local cfgInfo = questCfg[packetInfo.id]
    if packetInfo.questState == Const_pb.FINISHED then--领奖
        local msg = Quest_pb.HPGetSingeQuestReward()
        msg.questId = packetInfo.id
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C, pb, #pb, true) 
    else
        if isSpecial then
            GuideManager.setNextNewbieGuide()
        end
        GuideManager.IsNeedShowPage = false
        PageManager.pushPage( "NewbieGuideForcedPage" )
    end
end
function TaskContent_onSpecialConfirmation (container)
    TaskContent_onConfirmation(GuideManager.taskId,true)
end
function TaskContent:onConfirmation(content)
    local container = content:getCCBFileNode()
	local taskId = self.id
    local packetInfo = _curShowTaskInfo[taskId]
    local cfgInfo = questCfg[packetInfo.id]
    if packetInfo.questState == Const_pb.ING then
        if cfgInfo.isJump == 1 then--跳转
            local GuideManager = require("Guide.GuideManager")
            if GuideManager.isInGuide then
                MessageBoxPage:Msg_Box(common:getLanguageString("@TutorialError"))
                return
            end
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
        end
    elseif packetInfo.questState == Const_pb.FINISHED then--领奖
        local msg = Quest_pb.HPGetSingeQuestReward()
        msg.questId = packetInfo.id
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C, pb, #pb, true)
    end

end

function TaskContent:onPreLoad(content)

end

function TaskContent:onUnLoad(content)

end

function TaskContent:onDetial(container)
    local index = self.id
    local ItemInfo = _curShowTaskInfo[index].taskRewards
    local Rewards=common:split(ItemInfo, "_")
    local items = { type=tonumber(Rewards[1]/10000),
                   itemId=tonumber(Rewards[2]),
                   count=tonumber(Rewards[3]) }
    GameUtil:showTip(container:getVarNode("mDetial"), items)
end

function TaskContent:onRefreshContent(content)
	local container = content:getCCBFileNode()
	local taskId = self.id
    local packetInfo = _curShowTaskInfo[taskId]
    local cfgInfo = questCfg[packetInfo.id]
    local statusText = "@Receive"
    local buttonBMFontText = container:getVarLabelBMFont("mConfirmation")
    --local isGray = false
    NodeHelper:setNodesVisible(container, { mPoint = false })
    if packetInfo.questState == Const_pb.ING then
        statusText = cfgInfo.isJump == 1 and common:getLanguageString("@Goto") or common:getLanguageString("@inProgress")
        if cfgInfo.isJump == 1 then--确认 跳转
            --NodeHelper:setNodesVisible(container, { mGotoNode = true, mConfirmationNode = false })
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", true)    
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Blue.fnt") --蓝色字正常
             --isGray = false
        else --进行中
            --NodeHelper:setNodesVisible(container, { mGotoNode = false, mConfirmationNode = true })
            NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", false)    
            --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Blue.fnt") --蓝色字置灰
           -- isGray = true
        end
    elseif packetInfo.questState == Const_pb.FINISHED then
        statusText = common:getLanguageString("@ActDailyMissionBtn_Receive")
       -- NodeHelper:setNodesVisible(container, { mGotoNode = false, mConfirmationNode = true })
        NodeHelper:setMenuItemEnabled(container,"mConfirmationBtn",true)    --红色字正常
        NodeHelper:setNodesVisible(container, { mPoint = true })
        --buttonBMFontText:setFntFile("Lang/Font-HT-Button-Golden.fnt")
         --isGray = false
    elseif packetInfo.questState == Const_pb.REWARD then
        --NodeHelper:setNodesVisible(container, { mGotoNode = false, mConfirmationNode = true })
        NodeHelper:setMenuItemEnabled(container, "mConfirmationBtn", false)
        --NodeHelper:setMenuItemEnabled(container, "mGotoBtn", false)    --红色字置灰
        --buttonBMFontText:setFntFile("Lang/Font-HT-Button-red.fnt")
        --isGray = true
    end
    local finishCount = packetInfo.finishedCount
    local targetCount = cfgInfo.targetCount
    if cfgInfo.showType == 1 then
        targetCount = 1
        if packetInfo.questState == Const_pb.ING then
            finishCount = 0
        else
            finishCount = 1
        end
    end
    --if finishCount > targetCount then
    if packetInfo.questState == Const_pb.FINISHED then
        finishCount = targetCount
    end

    local strLabel = {
        -- 競技場名次任務特殊處理
        mTaskTimes = (cfgInfo.targetType == 45) and ((packetInfo.questState == Const_pb.FINISHED) and "1/1" or "0/1") or 
                                                      GameUtil:formatNumber(finishCount) .. "/" .. GameUtil:formatNumber(targetCount),
        mConfirmation = statusText,
        mTaskReward = GameUtil:formatNumber(cfgInfo.des),
        mSkillTex = "",
    }
    local bar = container:getVarScale9Sprite("mTaskBar")
    -- 競技場名次任務特殊處理
    if cfgInfo.targetType == 45 then
        if packetInfo.questState == Const_pb.FINISHED then
            bar:setContentSize(CCSize(BAR_WIDTH, BAR_HEIGHT))
        else
            bar:setContentSize(CCSize(BAR_WIDTH * 0, BAR_HEIGHT))
        end
    else
        bar:setContentSize(CCSize(BAR_WIDTH * math.min(1, math.max(0.14, finishCount / targetCount)), BAR_HEIGHT))
    end
    NodeHelper:setNodesVisible(container, { mTaskBar = (finishCount > 0) })

    --NodeHelper:setNodeIsGray(container, { mConfirmation = isGray })
    
    local iconBg = NodeHelper:getImageBgByQuality(cfgInfo.quality)
    local normalImage = NodeHelper:getImageByQuality(cfgInfo.quality)
    NodeHelper:setSpriteImage(container, { mQualityItem = normalImage, mIconBg = iconBg })

    container:getVarLabelTTF("mSkillTex"):removeAllChildren()
   
    local TextContent={
        mSkillTex = '<p style="margin:10px;" ><font color="#737466">' .. common:getLanguageString(cfgInfo.content, cfgInfo.targetCount) .. '</font></p>',
    }
		
    local Text = CCHTMLLabel:createWithString(TextContent.mSkillTex, CCSizeMake(400, 30), "Barlow-Bold")
    
    Text:setScale(0.8)
    Text:setAnchorPoint(ccp(0, 1))
    Text:setPosition(ccp(0, 10))
    container:getVarLabelTTF("mSkillTex"):addChild(Text)

    NodeHelper:setNodesVisible(container, { mLivenessNode = false })
    NodeHelper:setStringForLabel(container, strLabel)
    --if finishCount==targetCount then 
    --if packetInfo.questState == Const_pb.FINISHED then 
    --    NodeHelper:setColorForLabel(container, { mTaskTimes = "219 115 17" } )
    --else
    --    NodeHelper:setColorForLabel(container, { mTaskTimes = "255 255 255" } )
    --end
    NodeHelper:setSpriteImage(container, { mSkillPic = cfgInfo.icon })
   
    --if string.sub(cfgInfo.icon, 1, 7) == "UI/Role" then 
    --    NodeHelper:setNodeScale(container, "mSkillPic", 1, 1)
    --else
    --    NodeHelper:setNodeScale(container, "mSkillPic", 1, 1)
    --end
    if taskId == 1 then
        GuideManager.PageContainerRef["MissionLineTask"] = container
    end

    if taskId >= 8 or taskId >= #_curShowTaskInfo then
        if GuideManager.IsNeedShowPage then
            GuideManager.IsNeedShowPage = false

            PageManager.pushPage("NewbieGuideForcedPage")
            PageManager.popPage("NewGuideEmptyPage")
        end
    end
end

function MissionLineTask.onFunction(eventName, container)
	if eventName == "onBuyAll" then
		
	end
end
function MissionLineTask:onEnter(ParentContainer)
    local missionInfo = MissionManager.getMissionInfo()
    selfContainer = ScriptContentBase:create(missionInfo._ccbi)
    selfContainer:registerFunctionHandler(MissionLineTask.onFunction)
    selfContainer.scrollview=selfContainer:getVarScrollView("mContent");
    --if selfContainer.scrollview~=nil then
    --    ParentContainer:autoAdjustResizeScrollview(selfContainer.scrollview);
    --end
    NodeHelper:autoAdjustResizeScale9Sprite(selfContainer:getVarScale9Sprite("mScale9Sprite1"))
    NodeHelper:autoAdjustResizeScale9Sprite(selfContainer:getVarScale9Sprite("mScale9Sprite2"))
    questCfg = ConfigManager.getQuestCfg()  
    
    local s9 = selfContainer:getVarScale9Sprite("mScale9Sprite2")
    if s9 then
    s9:setVisible(false)
    end
	return selfContainer
end

function MissionLineTask:getPacketInfo(index)
    _taskTypeIndex = index
    if _taskTypeIndex == MissionManager._missionType.MISSION_MAIN_TASK then
        common:sendEmptyPacket(HP_pb.QUEST_GET_QUEST_LIST_C, true)
    else
        common:sendEmptyPacket(HP_pb.QUEST_GET_ACHIVIMENT_LIST_C, true)
    end
    NodeHelper:setNodesVisible(selfContainer, { mBanner1 = _taskTypeIndex == MissionManager._missionType.MISSION_MAIN_TASK, mBanner2 = _taskTypeIndex == MissionManager._missionType.MISSION_ACHIEVEMENT_TASK })
end
function MissionLineTask:refreshPage()
	
end

function MissionLineTask:onExecute(ParentContainer)
	if goBattlePage == true then
        goBattlePage = false
        --MainFrame_onBattlePageBtn();
    end
end
----------------scrollview-------------------------


function MissionLineTask:rebuildAllItem()
    self:clearAllItem();
	self:buildItem();
end
function MissionLineTask:clearAllItem()
   	local scrollview = selfContainer.scrollview
    if scrollview then
	    scrollview:removeAllCell();
    end
end

function MissionLineTask:buildItem()
    NodeHelper:buildCellScrollView(selfContainer.scrollview, #_curShowTaskInfo, "TaskContent.ccbi",TaskContent)
    --[[local scrollview = selfContainer.scrollview
    if scrollview == nil then return end
    local cell = nil
    local size  = common:table_count(_curShowTaskInfo)
    for i=1, size, 1 do
        cell = CCBFileCell:create()
		cell:setCCBFile("TaskContent.ccbi")
        local handler = common:new({ id = i},TaskContent)
        cell:registerFunctionHandler(handler)
        scrollview:addCell(cell)
        local pos = ccp(0,cell:getContentSize().height*(size-i))
        cell:setPosition(pos)	
    end
    local ccSzie = scrollview:getViewSize()	
	
	local sizeRect = CCSizeMake(cell:getContentSize().width,cell:getContentSize().height*size)
	scrollview:setContentSize(sizeRect)
	scrollview:setContentOffset(ccp(0,scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
	scrollview:forceRecaculateChildren()]]--
end

function MissionLineTask:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.QUEST_GET_QUEST_LIST_S or opcode == HP_pb.QUEST_GET_ACHIVIMENT_LIST_S then
		local msg = Quest_pb.HPGetQuestListRet()
		msg:ParseFromString(msgBuff)
		_lineTaskPacket,_curShowTaskInfo = MissionManager.AnalysisPacket(msg)
        self:rebuildAllItem()
    elseif opcode == HP_pb.QUEST_SINGLE_UPDATE_S then--_curShowTaskInfo内删除已领奖任务，添加当前类型中的下一个任务
        local msg = Quest_pb.HPQuestUpdate()
        msg:ParseFromString(msgBuff)
        local index = 0
        for k, v in pairs(_curShowTaskInfo) do
            index = index + 1
            if v.id == msg.quest.id then
                table.remove(_curShowTaskInfo,index);
                if #_lineTaskPacket[questCfg[msg.quest.id].team] > 0 then
                    table.insert(_curShowTaskInfo,_lineTaskPacket[questCfg[msg.quest.id].team][1]);
                    table.remove(_lineTaskPacket[questCfg[msg.quest.id].team],1);
                end
                break
            end
        end
        MissionManager.sortData(_curShowTaskInfo);
        --[[table.sort( _curShowTaskInfo,function (task1,task2)
            return questCfg[task1.id].sortId < questCfg[task2.id].sortId
        end);]]--
        self:rebuildAllItem()

        local NgBattlePage=require("Battle.NgBattlePage")
        NgBattlePage:setQuestBtn(_curShowTaskInfo)
	end
   
end



function MissionLineTask:onExit(ParentContainer)
    self:clearAllItem();
end
return MissionLineTask
