----------------------------------------------------------------------------------
--任务面板  主界面点任务
----------------------------------------------------------------------------------
local thisPageName = "MissionMainPage"
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local MissionManager = require("MissionManager")
local isBattleView = false  --是否是战斗界面过来


local MissionMainPage = {}
local option = {
	ccbiFile = "TaskPage.ccbi",
	handlerMap = {
		onReturnBtn    = "onClose",
        onHelp      = "onHelp",
        onAgencyBtn = "onAgencyBtn",
        onDailyBtn = "onDailyBtn",
        onAchievementBtn = "onAchievementBtn",
	},
    opcodes = {
        QUEST_GET_QUEST_LIST_C = HP_pb.QUEST_GET_QUEST_LIST_C,--获取任务列表
        QUEST_GET_QUEST_LIST_S = HP_pb.QUEST_GET_QUEST_LIST_S,--任务列表反馈
        QUEST_GET_SINGLE_QUEST_REWARD_C = HP_pb.QUEST_GET_SINGLE_QUEST_REWARD_C,--领取单个任务或成就奖励
        QUEST_SINGLE_UPDATE_S = HP_pb.QUEST_SINGLE_UPDATE_S,--更新单条任务或成就
        QUEST_GET_ACHIVIMENT_LIST_C = HP_pb.QUEST_GET_ACHIVIMENT_LIST_C,--请求成就列表
        QUEST_GET_ACHIVIMENT_LIST_S = HP_pb.QUEST_GET_ACHIVIMENT_LIST_S,--返回成就列表
        DAILY_QUEST_INFO_C 	= HP_pb.DAILY_QUEST_INFO_C,--每日任务列表
        DAILY_QUEST_INFO_S	= HP_pb.DAILY_QUEST_INFO_S,--返回每日任务列表
        TAKE_DAILY_QUEST_AWARD_C    = HP_pb.TAKE_DAILY_QUEST_AWARD_C,--每日任务奖励领取
        TAKE_DAILY_QUEST_AWARD_S	= HP_pb.TAKE_DAILY_QUEST_AWARD_S,--每日任务奖励领取反馈
        TAKE_DAILY_QUEST_POINT_AWARD_C = HP_pb.TAKE_DAILY_QUEST_POINT_AWARD_C,--活跃度领奖
        TAKE_DAILY_QUEST_POINT_AWARD_S = HP_pb.TAKE_DAILY_QUEST_POINT_AWARD_S,--活跃度领奖反馈
        WEEKLY_QUEST_INFO_C = HP_pb.WEEKLY_QUEST_INFO_C,
        WEEKLY_QUEST_INFO_S = HP_pb.WEEKLY_QUEST_INFO_S,
        TAKE_WEEKLY_QUEST_AWARD_C = HP_pb.TAKE_WEEKLY_QUEST_AWARD_C,
        TAKE_WEEKLY_QUEST_AWARD_S = HP_pb.TAKE_WEEKLY_QUEST_AWARD_S,
        TAKE_WEEKLY_QUEST_POINT_AWARD_C = HP_pb.TAKE_WEEKLY_QUEST_POINT_AWARD_C,
        TAKE_WEEKLY_QUEST_POINT_AWARD_S = HP_pb.TAKE_WEEKLY_QUEST_POINT_AWARD_S,
        PLAYER_AWARD_S=HP_pb.PLAYER_AWARD_S
	}
}

local mCurrentIndex = 0;
local mFristSelectMissionType = MissionManager._missionType.MISSION_DAILY_TASK
function MissionMainPage:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    container:registerMessage(MSG_REFRESH_REDPOINT)
    MissionManager._curMissionType = mFristSelectMissionType
	local mSubNode = container:getVarNode("mContentNode")	--绑定子页面ccb的节点
	if mSubNode then
        CCLuaLog("MissionMainPage:onEnter removeAllChildren")
        mSubNode:removeAllChildren()
    end
    --NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    self:registerPacket(container)
    self:refreshPage(container)
    self:refreshRedPointInfo(container)
    local GuideManager = require("Guide.GuideManager")
    GuideManager.PageContainerRef["MissionMainPage"] = container
end

function MissionMainPage:setBtnStatus( container )
    NodeHelper:setMenuItemSelected(container, 
        {
            mAgencyBtn = MissionManager._curMissionType == MissionManager._missionType.MISSION_MAIN_TASK,
            mDailyBtn = MissionManager._curMissionType == MissionManager._missionType.MISSION_DAILY_TASK,
            mAchievementBtn = MissionManager._curMissionType == MissionManager._missionType.MISSION_ACHIEVEMENT_TASK,
        }
    )
    NodeHelper:setColorForLabel(container, { mAgencyName = (MissionManager._curMissionType == MissionManager._missionType.MISSION_MAIN_TASK and 
                                                            GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT),
                                             mDailyName = (MissionManager._curMissionType == MissionManager._missionType.MISSION_DAILY_TASK and 
                                                            GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT),
                                             mAchievementName = (MissionManager._curMissionType == MissionManager._missionType.MISSION_ACHIEVEMENT_TASK and 
                                                            GameConfig.COMMON_TAB_COLOR.SELECT or GameConfig.COMMON_TAB_COLOR.UNSELECT), })
end
function MissionMainPage_setMissionType(_type)
    MissionManager._curMissionType = _type
end
function MissionMainPage:setMissionType(_type)
    MissionManager._curMissionType = _type
end

function MissionMainPage:onAgencyBtn( container )
    if MissionManager._curMissionType == MissionManager._missionType.MISSION_MAIN_TASK then 
		self:setBtnStatus(container)
        return 
    end
    --MissionManager._curMissionType = MissionManager._missionType.MISSION_MAIN_TASK
     MissionMainPage:setMissionType(MissionManager._missionType.MISSION_MAIN_TASK)
    self:refreshPage(container);
end
function MissionMainPage:onDailyBtn( container )
    if MissionManager._curMissionType == MissionManager._missionType.MISSION_DAILY_TASK then 
		self:setBtnStatus(container)
		return 
    end
    MissionMainPage:setMissionType(MissionManager._missionType.MISSION_DAILY_TASK)
    --MissionManager._curMissionType = MissionManager._missionType.MISSION_DAILY_TASK
    self:refreshPage(container);
end
function MissionMainPage:onAchievementBtn( container )
    if MissionManager._curMissionType == MissionManager._missionType.MISSION_ACHIEVEMENT_TASK then 
		self:setBtnStatus(container)
		return 
    end
    MissionManager._curMissionType = MissionManager._missionType.MISSION_ACHIEVEMENT_TASK
    self:refreshPage(container);
end
function MissionMainPage_onAchievementBtn( container )
    if MissionManager._curMissionType == MissionManager._missionType.MISSION_ACHIEVEMENT_TASK then 
		self:setBtnStatus(container)
		return 
    end
    MissionManager._curMissionType = MissionManager._missionType.MISSION_ACHIEVEMENT_TASK
    MissionMainPage:refreshPage(container);
end

function MissionMainPage:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function MissionMainPage:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function MissionMainPage:refreshPage(container)
    local mSubNode = container:getVarNode("mContentNode")	--绑定子页面ccb的节点
    local shopInfo = MissionManager.getMissionInfo()
	if shopInfo then
		local page = shopInfo._scriptName
		if page and page ~= "" and mSubNode then
            if MissionMainPage.subPage then
                MissionMainPage.subPage:onExit(container)
                MissionMainPage.subPage = nil
            end
            CCLuaLog("MissionMainPage:refreshPage removeAllChildren")
	        mSubNode:removeAllChildren()

	        MissionMainPage.subPage = require(page)
	        MissionMainPage.sunCCB = MissionMainPage.subPage:onEnter(container)
	        mSubNode:addChild(MissionMainPage.sunCCB)
	        --MissionMainPage.sunCCB:setAnchorPoint(ccp(0,0))
            if MissionMainPage.subPage["getPacketInfo"] then
                MissionMainPage.subPage:getPacketInfo(MissionManager._curMissionType)
            end
	        MissionMainPage.sunCCB:release()
            self:setBtnStatus(container);
		end
	end
end
function MissionMainPage:refreshRedPointInfo(container)
    require("Util.RedPointManager")
    local nodeVisible = {
        mTaskBtnPoint1 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 1),
        mTaskBtnPoint2 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 2),
        mTaskBtnPoint3 = RedPointManager_getShowRedPoint(RedPointManager.PAGE_IDS.QUEST_TYPE_TAB, 3),
    }
    NodeHelper:setNodesVisible(container,nodeVisible)
end
function MissionMainPage:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == thisPageName and extraParam == "jumpToDaily" then
			self:onDailyBtn(container)
		end
        if pageName == thisPageName and extraParam == "refreshSignState"  then
            MissionMainPage.subPage:onReceiveMessage(container)
        end
    elseif typeId == MSG_REFRESH_REDPOINT then
        self:refreshRedPointInfo(container)
	end
end
--接收服务器回包
function MissionMainPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	if MissionMainPage.subPage then
		MissionMainPage.subPage:onReceivePacket(container)
	end
    if opcode == HP_pb.QUEST_SINGLE_UPDATE_S or opcode == HP_pb.TAKE_DAILY_QUEST_AWARD_S or opcode == HP_pb.TAKE_WEEKLY_QUEST_AWARD_S or
       opcode == HP_pb.TAKE_DAILY_QUEST_POINT_AWARD_S or opcode == HP_pb.TAKE_WEEKLY_QUEST_POINT_AWARD_S then
        MissionManager.getRedPointStatus()
        --MessageBoxPage:Msg_Box(common:getLanguageString('@RewardItem2'))
    end
    if opcode == HP_pb.PLAYER_AWARD_S then
        if not PageManager.getIsInSummonPage() then
            local PackageLogicForLua = require("PackageLogicForLua")
            PackageLogicForLua.PopUpReward(msgBuff)
        end
    end

end
function MissionMainPage:onExecute(container)
	if MissionMainPage.subPage then
		MissionMainPage.subPage:onExecute(container)
	end

end
function MissionMainPage:onClose( container )
    -- if isBattleView then 
    --     isBattleView = false
    --     MainFrame_onBattlePageBtn()
    -- else
        --MainFrame_onMainPageBtn()
    --end
    PageManager.popPage(thisPageName)
    --新手教學
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.currGuide[GuideManager.currGuideType])
        if guideCfg and guideCfg.showType == 8 then
            GuideManager.forceNextNewbieGuide()
        end
    end
end
function MissionMainPage:onExit(container)
    mFristSelectMissionType = MissionManager._missionType.MISSION_DAILY_TASK
	if MissionMainPage.subPage then
		MissionMainPage.subPage:onExit(container)
		MissionMainPage.subPage = nil
	end
    self:removePacket(container)
    local GuideManager = require("Guide.GuideManager")
    GuideManager.newbieGuide()

end
function MissionMainPage:onHelp(container)
    local info = MissionManager._missionInfo[MissionManager._curMissionType]
    PageManager.showHelp(info._helpFile)
end

function MissionMainPage_setIsBattleView(_bool , FristSelectMissionType)
    isBattleView = _bool
    mFristSelectMissionType = FristSelectMissionType or MissionManager._missionType.MISSION_DAILY_TASK
end

local CommonPage = require('CommonPage')
MissionMainPage= CommonPage.newSub(MissionMainPage, thisPageName, option)

return MissionMainPage
