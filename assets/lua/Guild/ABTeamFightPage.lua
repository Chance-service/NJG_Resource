
----------------------------------------------------------------------------------
local Const_pb = require "Const_pb"
local UserInfo = require("PlayerInfo.UserInfo");

local thisPageName = "ABTeamFightPage"
local NodeHelper = require("NodeHelper");

local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local AllianceBattle_pb = require("AllianceBattle_pb")
local HP_pb = require("HP_pb")
local GuildDataManager = require("Guild.GuildDataManager")
require("ABHelpPage")

local opcodes = {
    ALLIANCE_BATTLE_ENTER_C           = HP_pb.ALLIANCE_BATTLE_ENTER_C,
    ALLIANCE_BATTLE_TEAM_FIGHT_INFO_C = HP_pb.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_C,
    ALLIANCE_BATTLE_TEAM_FIGHT_INFO_S = HP_pb.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_S,
    ALLIANCE_BATTLE_FIGHT_REPORT_C    = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_C,
    ALLIANCE_BATTLE_FIGHT_REPORT_S    = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_S
}

local option = {
	ccbiFile = "GuildTeamFightInfoPage.ccbi",
	handlerMap = {
		onReturnBtn = "onReturn",
        onHelp = "onHelp",
        onTeamInformationBtn = "onTeamInformationBtn",
        onPictureHelpBtn = "onPictureHelpBtn"	
	},
	DataHelper = ABManager
}

local roundTitle = {
    [1] = common:getLanguageString("@ABFightTex1",tostring(32)),
    [2] = common:getLanguageString("@ABFightTex1",tostring(16)),
    [3] = common:getLanguageString("@ABFightTex1",tostring(8)),
    [4] = common:getLanguageString("@ABFightTex2"),
    [5] = common:getLanguageString("@ABFightTex3")
}

local roundStr = {
    [1] = "@ABFightRoundUnit1",
    [2] = "@ABFightRoundUnit2",
    [3] = "@ABFightRoundUnit3"
}

local ABTeamFightPage = BasePage:new(option,thisPageName,nil,opcodes)
local FightId = nil
local TimerName = "ABFightingLeftTimer"
local mCurrentRound = 1
----------------------------------------------------------------------------------
-----------------------------------------------
--BEGIN ABTeamFightThreeContent ս���б�content
----------------------------------------------
local ABTeamFightThreeContent = {
    ccbiFile = "GuildTeamFightInfoItem1.ccbi"
}
function ABTeamFightThreeContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABTeamFightThreeContent.onRefreshItemView(container);
	elseif string.sub(eventName,1,13) == "onCheckReport" then
	    ABTeamFightThreeContent.onCheckReport(container,tonumber(string.sub(eventName,-1)))
	end	
end

function ABTeamFightThreeContent.onRefreshItemView(container)
    local labelStr = {}
    local nodeVisible = {}
    local labelColor = {}
    local spriteImg = {}
    
    local info = ABManager.FightReport.CurrentFight
    if info~=nil then
        labelStr.mRoundNum = common:getLanguageString(roundStr[1])
        for i=1,3 do
            labelStr["mName"..(i*2-1)] = ABManager:getConfigDataByKeyAndIndex("Battlefield",i).name
            labelStr["mName"..(i*2)] = ABManager:getConfigDataByKeyAndIndex("Battlefield",i).name

            local detailInfo = info.detailUnit[i]

            --�жϽ��������ִθ��ڱ�������ʾ��������ѳ�����ʾ���
            if mCurrentRound > i then
                if detailInfo.winId <= 3 then
                    spriteImg["mPic"..(i*2-1)] = ABManager:getConfigDataByKeyAndIndex("FightPic",1)
                    spriteImg["mPic"..(i*2)] = ABManager:getConfigDataByKeyAndIndex("FightPic",4)
                    nodeVisible["mWinPic"..(i*2-1)] = true
                    nodeVisible["mLose"..(i*2)] = true
                else
                    spriteImg["mPic"..(i*2-1)] = ABManager:getConfigDataByKeyAndIndex("FightPic",3)
                    spriteImg["mPic"..(i*2)] = ABManager:getConfigDataByKeyAndIndex("FightPic",2)
                    nodeVisible["mWinPic"..(i*2)] = true
                    nodeVisible["mLose"..(i*2-1)] = true
                end
            end
        end

        --����ս�������жϣ�ǰ����
        if mCurrentRound <= 3 then
            --��һ������ѳ�
            if mCurrentRound > 2 then
                container:runAnimation("BattleHit5")
                nodeVisible.mCheckBtnNode3 = false
            --��1,2������ѳ�
            elseif mCurrentRound > 1 then
                container:runAnimation("BattleHit3")
                nodeVisible.mCheckBtnNode2 = false
                nodeVisible.mCheckBtnNode3 = false
            --ȫ��δ��
            else
                container:runAnimation("BattleHit1")
                nodeVisible.mCheckBtnNode1 = false
                nodeVisible.mCheckBtnNode2 = false
                nodeVisible.mCheckBtnNode3 = false
            end
        end
    end

    NodeHelper:setSpriteImage(container, spriteImg);
    NodeHelper:setColorForLabel(container,labelColor)
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABTeamFightThreeContent.onCheckReport(container,index)
    if not ABManager.FightReport or not ABManager.FightReport.CurrentFight then return end
    local info = ABManager.FightReport.CurrentFight.detailUnit[index]
    
    local baseinfo = ABManager.FightReport.CurrentFight
    ABManager:setBattleExtralParams(baseinfo,info)

    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPAllianceTeamFightReport();
    msg.battleId = info.id
    common:sendPacket(opcodes.ALLIANCE_BATTLE_FIGHT_REPORT_C, msg);
end

--one
local ABTeamFightOneContent = {
    ccbiFile = "GuildTeamFightInfoItem2.ccbi"
}
function ABTeamFightOneContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABTeamFightOneContent.onRefreshItemView(container);
	elseif eventName == "onCheckReport1" then
	    ABTeamFightOneContent.onCheckReport(container,index)
	end	
end

function ABTeamFightOneContent.onRefreshItemView(container)
    local index = container.mID;
    
    local labelStr = {}
    local nodeVisible = {}
    local labelColor = {}
    local spriteImg = {}
    
    local info = ABManager.FightReport.CurrentFight
    if info~=nil then
        labelStr.mRoundNum = common:getLanguageString(roundStr[index-2])
        --����ս��δ����
        if mCurrentRound ==index then
            container:runAnimation("BattleHit1")
            nodeVisible.mCheckBtnNode = false
        --����ս������
        elseif mCurrentRound > index then
            if info.detailUnit[index].winId<=3 then
                spriteImg.mPic1 = ABManager:getConfigDataByKeyAndIndex("FightPic",1)
                spriteImg.mPic2 = ABManager:getConfigDataByKeyAndIndex("FightPic",4)
                nodeVisible["mWinPic1"] = true
            else
                spriteImg.mPic1 = ABManager:getConfigDataByKeyAndIndex("FightPic",3)
                spriteImg.mPic2 = ABManager:getConfigDataByKeyAndIndex("FightPic",2)
                nodeVisible["mWinPic2"] = true
            end
        end

        labelStr.mName1 = ABManager:getConfigDataByKeyAndIndex("Battlefield",info.detailUnit[index].leftTeamIndex).name
        labelStr.mName2 = ABManager:getConfigDataByKeyAndIndex("Battlefield",info.detailUnit[index].rightTeamIndex).name
    end
    
    NodeHelper:setSpriteImage(container, spriteImg);
    NodeHelper:setColorForLabel(container,labelColor)
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABTeamFightOneContent.onCheckReport(container)
    local index = container.mID;
    ABManager.isLookGuildFightFlag = true;
    local info = ABManager.FightReport.CurrentFight.detailUnit[index]   

    local baseinfo = ABManager.FightReport.CurrentFight
    ABManager:setBattleExtralParams(baseinfo,info)

    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPAllianceTeamFightReport();
    msg.battleId = info.id
    common:sendPacket(opcodes.ALLIANCE_BATTLE_FIGHT_REPORT_C, msg);
end
--END ABTeamFightThreeContent



-----------------------------------------------
--ABTeamFightPageҳ���е��¼�����
----------------------------------------------
function ABTeamFightPage:getPageInfo(container)
    if ABManager.FightReport~=nil  and ABManager.FightReport.CurrentFight~=nil then
        local nodeVisible = {}
        for i=1,6 do
            nodeVisible["mWinPic"..i] = false
            nodeVisible["mLose"..i] = false
        end
        
        NodeHelper:setNodesVisible(container,nodeVisible)
        self:refreshPage(container)
        self:rebuildAllItem(container)
    end
end
----------------------------------------------------------------


function ABTeamFightPage:refreshPage(container)
	local labelStr = {}
    local nodeVisible = {}

    local info = ABManager.FightReport.CurrentFight
    if info~=nil then
        labelStr.mName1 = info.leftName
        labelStr.mName2 = info.rightName
        labelStr.mTitle = common:getLanguageString(roundTitle[info.fightGroup])
    end
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABTeamFightPage:onExit(container)
    self:removePacket(container)
	NodeHelper:deleteScrollView(container);
    self.mRebuildLock = true

    if TimeCalculator:getInstance():hasKey("stageLeftTime") then
		TimeCalculator:getInstance():removeTimeCalcultor("stageLeftTime");	
    end
    container:removeMessage(MSG_MAINFRAME_REFRESH);



	local info = ABManager.FightReport.CurrentFight
    if info==nil then return end
    for i=1, #info.detailUnit do
        if TimeCalculator:getInstance():hasKey(TimerName..tostring(i)) then
           TimeCalculator:getInstance():removeTimeCalcultor(TimerName..tostring(i))
        end
    end
end

function ABTeamFightPage:onExecute(container)  
    --ʱ���жϣ����5��ս������ս����ĳ��ս������ˢ��ҳ��
    local info = ABManager.FightReport.CurrentFight
    for i=1, #info.detailUnit do
        if TimeCalculator:getInstance():hasKey(TimerName..tostring(i)) then
            info.detailUnit[i].leftTime = TimeCalculator:getInstance():getTimeLeft(TimerName..tostring(i));
            if info.detailUnit[i].leftTime <= 0 then
                TimeCalculator:getInstance():removeTimeCalcultor(TimerName..tostring(i))
                self:rebuildAllItem(container)
            end
        end
    end

    self:onTimer(container,"stageLeftTime","mFinishNum")
    ABManager:autoChangeState()
end

function ABTeamFightPage:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();
	if typeId == MSG_SEVERINFO_UPDATE then
		self:onUpdateServerInfo(container)	
	elseif typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == self.pageName then
			self:onRefreshPage(container);
        elseif pageName == "ABManager" then
            PageManager.changePage("GuildPage")
		end
	end
end

--------------ScrollView---------------------------------------
function ABTeamFightPage:buildItem(container)  
    local info = ABManager.FightReport.CurrentFight
    if info~=nil then
        local fOneItemHeight = 0
	    local fOneItemWidth = 0  
        mCurrentRound = 1
        --������ʱ��
        for i=1, #info.detailUnit do
            local detailInfo = info.detailUnit[i]
            if not TimeCalculator:getInstance():hasKey(TimerName..tostring(i))  then
                if detailInfo.leftTime>0 then
                    TimeCalculator:getInstance():createTimeCalcultor(TimerName..tostring(i), detailInfo.leftTime);
                end
            else
                TimeCalculator:getInstance():removeTimeCalcultor(TimerName..tostring(i))
                if detailInfo.leftTime>0 then
                    TimeCalculator:getInstance():createTimeCalcultor(TimerName..tostring(i), detailInfo.leftTime);
                end
            end
            --�жϵ�ǰ�ִ�
            if detailInfo.leftTime<=0 then
                mCurrentRound = i+1
            end
        end
        
        --���ݵ�ǰ�ִΣ�ѹ��content
        local iCount = 1
        local size = mCurrentRound >= 3 and mCurrentRound or 3
        if mCurrentRound > (#info.detailUnit) then
            size = mCurrentRound-1
        end
	    for i=size,3,-1 do
            local pItem = nil
            local pItemData = CCReViSvItemData:new_local()
		    pItemData.mID = i-2
		    pItemData.m_iIdx = i-2
		    pItemData.m_ptPosition = ccp(0, fOneItemHeight)

            if i <= 3 then
                pItem = ScriptContentBase:create(ABTeamFightThreeContent.ccbiFile)
                pItem:registerFunctionHandler(ABTeamFightThreeContent.onFunction)
                pItem.mID = 1
                pItem.id = 1
            else
                pItem = ScriptContentBase:create(ABTeamFightOneContent.ccbiFile)
                pItem:registerFunctionHandler(ABTeamFightOneContent.onFunction)
                pItem.mID = i
                pItem.id = i - 3
            end
            pItem:setPositionY(fOneItemHeight)

			fOneItemHeight = fOneItemHeight + pItem:getContentSize().height

            if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
            container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
            iCount = iCount + 1
	    end
        local size = CCSizeMake(fOneItemWidth, fOneItemHeight)
	    container.mScrollView:setContentSize(size)
	    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
        container.m_pScrollViewFacade:setDynamicItemsStartPosition(0);
	    container.mScrollView:forceRecaculateChildren();
	    ScriptMathToLua:setSwallowsTouches(container.mScrollView)  
    end
end

----------------click event------------------------
function ABTeamFightPage:onReturn(container)
	PageManager.changePage("ABMainPage")
end

function ABTeamFightPage:onHelp(container)
	showABHelpPageAtIndex(1)
end	

function ABTeamFightPage:onTeamInformationBtn(container)
    require("ABTeamInfoPage")
    setABTeamInfoCtrlBtn(false)
	PageManager.viewAllianceTeamInfo(GuildDataManager:getGuildId())
end	

function ABTeamFightPage:onPictureHelpBtn(container)
	showABHelpPageAtIndex(1)
end	
-------------------------------------------------------------------------