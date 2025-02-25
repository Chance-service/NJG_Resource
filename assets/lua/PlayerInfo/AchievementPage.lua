

local NodeHelper = require("NodeHelper")
local Quest_pb = require("Quest_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local thisPageName = "AchievementPage"
local AchievementManager = require("PlayerInfo.AchievementManager")

GoogleTaskType =
{
    TYPE_INIT = 1,
    TYPE_ADD = 2,
    TYPE_DELETE = 3,
}
local option = {
    ccbiFile = "NewPeopleTeakPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        onUnfinished = "onProgress",
        onCompleted = "onComplete",
        onReceiveGift = "onReceiveGift",
        onHelp = "onHelp"
    }
}

local AchievementPageBase = {}

local PageType = {
    PROGRESS = 1,   -- 进行中
    COMPLETE = 2    -- 已完成
}
local curPageType
local selectedIndex = 1
local mainContainer
local scrollViewOffset = nil 
local rewardedList = {}
local lastContentSize = 0
------------------ scrollview -------------------------
local AchievementItem = {
    ccbiFile = "NewPeopleTeakContent2.ccbi",
    ccbiFileWithBar = "NewPeopleTeakContent1.ccbi",
    ccbiFileComplete = "NewPeopleTeakContent3.ccbi"
}
local libPlatformListener = {}
AchievementPageBase.libPlatformListener = nil
function libPlatformListener:P2G_UNLOCK_ACHIEVEMENT(listener)
    if not listener then return end
    local strResult = listener:getResultStr()
    local strTable = json.decode(strResult)
    local result = json.decode(strTable.value);
    if result.value == false then --失败 则 通知到服务器
        --result.taskid
        AchievementPageBase:SendMsgToServer(nil,GoogleTaskType.TYPE_ADD,result.id)
    else
        AchievementPageBase:SendMsgToServer(nil,GoogleTaskType.TYPE_DELETE,result.id)
    end 
end
function AchievementItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		AchievementItem.onRefreshItemView(container)
    elseif eventName == "onGoTo" then
        AchievementItem.onGoTo(container)
    elseif eventName == "onGetIn" then
        AchievementItem.onDetails(container)
    elseif eventName == "onReceiveReward" then
        AchievementItem.onReward(container)
    elseif eventName == "onFrame1" then
        AchievementItem.showTips(container)
	end
end

function AchievementItem.onRefreshItemView(container)
    local index = container:getItemDate().mID
    local lb2str = {}
    local nodesVisiable = {}
    if curPageType == PageType.PROGRESS then
        local questInfo = AchievementManager.QuestList[index]
        if questInfo == {} or questInfo == nil then return end
        local achievementInfo = AchievementManager:getAchievementInfo(questInfo.id)
        if achievementInfo == {} or achievementInfo == nil then return end
        local timesStr = questInfo.finishedCount .. "/" .. achievementInfo.target
        if achievementInfo.achievementType == 1 then
            lb2str.mTaskText = timesStr
        else 
            lb2str.mTaskText = ""
        end
        lb2str.mTaskName = achievementInfo.name 
        if index == selectedIndex then
            lb2str.mTaskExplain =  common:stringAutoReturn(achievementInfo.content or "", GameConfig.LineWidth.AchievementContent) 
            NodeHelper:fillRewardItem(container,achievementInfo.reward,1)
            nodesVisiable.mSelecteBG = true
            nodesVisiable.mUpPic = false
            nodesVisiable.mDownPic = false

            if Golb_Platform_Info.is_r2_platform then
                local str_local = achievementInfo.content or ""
                local htmlNode = container:getVarNode("mTaskExplain")
                if htmlNode then
                    NodeHelper:setCCHTMLLabelAutoFixPosition( htmlNode, CCSize(350,96),str_local)
                    htmlNode:setVisible(false)
                end
            end
        else 
            nodesVisiable.mSelecteBG = false
            nodesVisiable.mUpPic = false
            nodesVisiable.mDownPic = true
        end
        if questInfo.questState == Const_pb.ING then
            nodesVisiable.mGoToNode = true
            nodesVisiable.mReceiveRewardNode = false
            nodesVisiable.mFinishPic = false
        elseif questInfo.questState == Const_pb.FINISHED then
            nodesVisiable.mGoToNode = false
            nodesVisiable.mReceiveRewardNode = true
            nodesVisiable.mFinishPic = false
        elseif questInfo.questState == Const_pb.REWARD then
            nodesVisiable.mGoToNode = false
            nodesVisiable.mReceiveRewardNode = false
            nodesVisiable.mFinishPic = true
        end

    else
        local questInfo = AchievementManager.CompleteList[index]
        if questInfo == {} or questInfo == nil then return end
        local finishAchievemenInfo = AchievementManager:getAchievementInfo(questInfo)
        if finishAchievemenInfo == {} or finishAchievemenInfo == nil then return end
        lb2str.mTaskName = finishAchievemenInfo.name 
        lb2str.mTaskText = common:stringAutoReturn(finishAchievemenInfo.content or "", GameConfig.LineWidth.AchievementCompleteContent) 
        
        local normalImage = NodeHelper:getImageByQuality(finishAchievemenInfo.quality)
        NodeHelper:setSpriteImage(container, {mQualityItem = normalImage})
        if string.sub(finishAchievemenInfo.icon, 1, 7) == "UI/Role" then 
             NodeHelper:setNodeScale(container, "mSkillPic", 0.84, 0.84)
        else
            NodeHelper:setNodeScale(container, "mSkillPic", 1, 1)
        end
    end
    NodeHelper:setStringForLabel(container, lb2str)
    NodeHelper:setNodesVisible(container, nodesVisiable)
end

-- 前往
function AchievementItem.onGoTo(container)
    local index = container:getItemDate().mID
    local questInfo = AchievementManager.QuestList[index]
    local achievementInfo = AchievementManager:getAchievementInfo(questInfo.id)
    AchievementManager:changePageByType(achievementInfo.questType)
end

-- 详细
function AchievementItem.onDetails(container)
    local index = container:getItemDate().mID
    if selectedIndex ~= index then
        selectedIndex = index
        scrollViewOffset = mainContainer.mScrollView:getContentOffset()
        PageManager.refreshPage(thisPageName)
--    else 
--        selectedIndex = 0
--        scrollViewOffset = mainContainer.mScrollView:getContentOffset()
--        PageManager.refreshPage(thisPageName)
    end 
end

-- 领取单个奖励
function AchievementItem.onReward(container)
    local index = container:getItemDate().mID
    local questInfo = AchievementManager.QuestList[index]
    AchievementManager:singleReward(questInfo.id)
    scrollViewOffset = mainContainer.mScrollView:getContentOffset()
    if Golb_Platform_Info.is_r2_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA ~= 2 then
        AchievementPageBase.CallGoogleTask(questInfo.id)
    end
end
function AchievementPageBase.CallGoogleTask(taskid)
      --unlock google task
    local TaskCfg = ConfigManager.getGoogleTaskCfg()
    local taskInfo = TaskCfg[tonumber(taskid)];
    if taskInfo~= nil then
         local strtable = {
            id = tostring(taskInfo.id),
            gid = tostring(taskInfo.gid),
        }
        local JsMsg  = cjson.encode(strtable)
        libPlatformManager:getPlatform():sendMessageG2P("G2P_UNLOCK_ACHIEVEMENT",JsMsg)
    end
    --unlock google task
end
-- 奖励tips
function AchievementItem.showTips(container)
    local index = container:getItemDate().mID
    local questInfo = AchievementManager.QuestList[index]
    if questInfo == {} or questInfo == nil then return end
    local achievementInfo = AchievementManager:getAchievementInfo(questInfo.id)
    if achievementInfo == {} or achievementInfo == nil then return end
    GameUtil:showTip(container:getVarNode('mFrame1'),achievementInfo.reward[1])
end

---------------------------------------------------------------
function AchievementPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    self:initScrollView(container)
    curPageType = PageType.PROGRESS
    self:selectType(container)
    container:runAnimation("DodgeEffectb")	
    selectedIndex = 1
    mainContainer = container
    AchievementManager:requestAchievementInfo()
    --self:refreshPage(container)
    AchievementPageBase.libPlatformListener = LibPlatformScriptListener:new(libPlatformListener)
    --向服务器获取未 成功通知到google的成就
    if Golb_Platform_Info.is_r2_platform and BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA ~= 2 then
        --self:SendMsgToServer(container,GoogleTaskType.TYPE_INIT,0);
    end
    --向服务器获取未 成功通知到google的成就

     --代码控制修改title的大小。修改ccbi对其他版本有影响
    if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
       NodeHelper:MoveAndScaleNode(container,{mTitle = common:getLanguageString("@NewPeopleTeakTitle")},-3,0.9);
    end
end

function AchievementPageBase:refreshPage(container)
    self:refreshProgress(container)
    self:rebuildItem(container)
end

function AchievementPageBase:onExit(container)
    self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:deleteScrollView(container)

    if container.m_pScrollViewFacade2 then
		container.m_pScrollViewFacade2:clearAllItems();
	end
	if container.mScrollViewRootNode2 then
		container.mScrollViewRootNode2:removeAllChildren();
	end

	if container.m_pScrollViewFacade2 then
		container.m_pScrollViewFacade2:delete();
		container.m_pScrollViewFacade2 = nil;
	end
	container.mScrollViewRootNode2 = nil;
	container.mScrollView2 = nil;

    scrollViewOffset = nil
    mainContainer = nil
    selectedIndex = 0
    lastContentSize = 0
    
    if AchievementPageBase.libPlatformListener then
		AchievementPageBase.libPlatformListener:delete()
        AchievementPageBase.libPlatformListener = nil
	end
end

function AchievementPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function AchievementPageBase:refreshProgress(container)
    local progressStr = ""
    local progressNum = 0
    
    if AchievementManager.AchievementState == 12 then
        NodeHelper:setNodesVisible(container,{mReceiveGiftNode = false,
                                                mReceiveAniNode = false})
        progressStr = "100%"
        progressNum = 1
    else
        progressStr = AchievementManager:finishedNumToPercentStr()
        progressNum = AchievementManager:calCurFinishedNum() / #AchievementManager.QuestList

        if AchievementManager:calCurFinishedNum() ==  #AchievementManager.QuestList then
            NodeHelper:setNodeVisible(container:getVarNode("mReceiveAniNode"), true)
			container:runAnimation("DodgeEffecta")	
        else 
            NodeHelper:setNodeVisible(container:getVarNode("mReceiveAniNode"), false)
			container:runAnimation("DodgeEffectb")	
        end
    end

    NodeHelper:setStringForLabel(container, {mExperienceNum = progressStr})

    local expBar = container:getVarNode("mVipExp")
    expBar:setScaleX(progressNum)
    -- 刷新外面的红点
    AchievementManager:updateRedPoint()
end

function AchievementPageBase:initScrollView(container)
    local svName = "mContent1"
    NodeHelper:initScrollView(container, svName, 5)

    container.mScrollView2=container:getVarScrollView("mContent2");
	if container.mScrollView2~=nil then
        --初始化scrollview
        container.mScrollViewRootNode2 = container.mScrollView2:getContainer();
	    container.m_pScrollViewFacade2 = CCReViScrollViewFacade:new_local(container.mScrollView2);
	    container.m_pScrollViewFacade2:init(8, 3);
	end
end

function AchievementPageBase:rebuildItem(container)
    self:clearAllItem(container)
	self:buildItem(container)
end

function AchievementPageBase:clearAllItem(container)
	NodeHelper:clearScrollView(container);
end

function AchievementPageBase:buildItem(container)
    if curPageType == PageType.PROGRESS then
        self:buildScrollviewWithDetails(container)
    else 
        self:buildScrollViewNormal(container)
    end
end

-- 未完成页签 点击出现详细信息时 使用另一个ccbi
function AchievementPageBase:buildScrollviewWithDetails(container)
    local size = #AchievementManager.QuestList

	local ccbiFile = AchievementItem.ccbiFile

	if size == 0 or ccbiFile == nil or ccbiFile == ''then return end
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
    local fOneItemHeightMin = 0
    local fOneItemHeightMax = 0
	local fOneItemWidth = 0
	local currentPos = 0
	for i=size, 1,-1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, currentPos)

		if iCount < iMaxNode then
			if i == selectedIndex then
				ccbiFile = AchievementItem.ccbiFileWithBar
			else
				ccbiFile = AchievementItem.ccbiFile
			end
			local pItem = ScriptContentBase:create(ccbiFile)
			pItem.id = iCount
			pItem:registerFunctionHandler(AchievementItem.onFunction)	
            if ccbiFile == AchievementItem.ccbiFile then
                fOneItemHeightMin = pItem:getContentSize().height	
            else 
                fOneItemHeightMax = pItem:getContentSize().height
            end
            fOneItemHeight = pItem:getContentSize().height	
			currentPos = currentPos + fOneItemHeight
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end

			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end

	local size = CCSizeMake(fOneItemWidth, currentPos)
	container.mScrollView:setContentSize(size)
    if scrollViewOffset then 
--        local offset = scrollViewOffset.y --+ (lastContentSize - currentPos)
--        if #AchievementManager.QuestList >= math.ceil(container.mScrollView:getViewSize().height / fOneItemHeightMin) then 
--            offset = offset>0 and 0 or offset;
--        end
        container.mScrollView:setContentOffset(scrollViewOffset)
        --container.mScrollView:setContentOffset(ccp(0, scrollViewOffset.y))
    else 
        container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
    end
    --lastContentSize = currentPos
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();

end

-- 已完成页签 
function AchievementPageBase:buildScrollViewNormal(container)
    local size = #AchievementManager.CompleteList
    local ccbiFile = AchievementItem.ccbiFileComplete
    if size == 0 or ccbiFile == nil or ccbiFile == ''then return end
	local iMaxNode = container.m_pScrollViewFacade2:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local fOneItemWidth = 0
	local currentPos = 0
	for i=size, 1,-1 do
		local pItemData = CCReViSvItemData:new_local()
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp(0, currentPos)
		
		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create(ccbiFile)
			pItem.id = iCount
			pItem:registerFunctionHandler(AchievementItem.onFunction)			
			fOneItemHeight = pItem:getContentSize().height			
			currentPos = currentPos + fOneItemHeight
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end

			container.m_pScrollViewFacade2:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade2:addItem(pItemData)
		end
		iCount = iCount + 1
	end
	
	local size = CCSizeMake(fOneItemWidth, currentPos)
	container.mScrollView2:setContentSize(size)
    container.mScrollView2:setContentOffset(ccp(0, container.mScrollView2:getViewSize().height - container.mScrollView2:getContentSize().height * container.mScrollView2:getScaleY()))
	
	container.m_pScrollViewFacade2:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView2:forceRecaculateChildren();
end



function AchievementPageBase:selectType(container)
    if curPageType == PageType.PROGRESS then
        NodeHelper:setMenuItemSelected(container, {mUnfinished = true,
                                                   mCompleted = false}) 
        NodeHelper:setNodesVisible(container, {mExpNode1 = true,
                                                mExpNode2 = false})
    else 
        NodeHelper:setMenuItemSelected(container, {mUnfinished = false,
                                                   mCompleted = true}) 
        NodeHelper:setNodesVisible(container, {mExpNode1 = false,
                                                mExpNode2 = true})
    end
end
function AchievementPageBase:SendMsgToServer(container,type,id)
    if Golb_Platform_Info.is_r2_platform then
        local msg = Player_pb.HPGoogleAchieveMsg()
        msg.type = type;
        if type == 3 or type == 2 then
            msg.achieveinfo:append(tostring(id));
            
        end
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(HP_pb.PLAYER_GOOGLE_ACHIEVE_C, pb, #pb, false)
    end
end
function AchievementPageBase:onProgress(container)
    if curPageType ~= PageType.PROGRESS then
        curPageType = PageType.PROGRESS
        selectedIndex = 1
        scrollViewOffset = nil
        lastContentSize = 0
        self:selectType(container)
        self:rebuildItem(container)
    else 
        self:selectType(container)
    end
end

function AchievementPageBase:onComplete(container)
    if curPageType ~= PageType.COMPLETE then
        curPageType = PageType.COMPLETE
        selectedIndex = 0
        scrollViewOffset = nil 
        lastContentSize = 0
        self:selectType(container)
        self:rebuildItem(container)
    else 
        self:selectType(container)
    end
end

function AchievementPageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_ACHIEVEMENT)
end

function AchievementPageBase:onReceiveGift(container)
    PageManager.pushPage("AchievementRewardPage")
end

function AchievementPageBase:onReceivePacket(container)
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.QUEST_GET_QUEST_LIST_S then
        local msg = Quest_pb.HPGetQuestListRet()
        msg:ParseFromString(msgBuff)
        AchievementManager:receiveAchievementInfo(msg)
        scrollViewOffset = nil
        selectedIndex = 1
        self:refreshPage(container)
    elseif opcode == HP_pb.QUEST_SINGLE_UPDATE_S then
        local msg = Quest_pb.HPQuestUpdate()
        msg:ParseFromString(msgBuff)
        AchievementManager:updateQuest(msg.quest)
        self:refreshPage(container)
    end
    --[[elseif opcode == HP_pb.PLAYER_GOOGLE_ACHIEVE_S then
         local msg = Player_pb.HPGoogleAchieveMsgRet()
          msg:ParseFromString(msgBuff)
          local allInfo = msg.achieveinfo
          for l = 1,#allInfo do
               AchievementPageBase.CallGoogleTask(allInfo[l])
          end
    end]]--
end

function AchievementPageBase:registerPacket(container)
    container:registerPacket(HP_pb.QUEST_GET_QUEST_LIST_S)
    container:registerPacket(HP_pb.QUEST_SINGLE_UPDATE_S)
end

function AchievementPageBase:removePacket(container)
    container:removePacket(HP_pb.QUEST_GET_QUEST_LIST_S)
    container:removePacket(HP_pb.QUEST_SINGLE_UPDATE_S)
end

function AchievementPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			self:refreshPage(container);
		end
	end
end
-----------------------------------------------------------------
local CommonPage = require("CommonPage");
local AchievementPage = CommonPage.newSub(AchievementPageBase, thisPageName, option);
return AchievementPageBase;