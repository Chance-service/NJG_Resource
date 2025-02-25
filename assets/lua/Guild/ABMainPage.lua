
----------------------------------------------------------------------------------
local Const_pb = require "Const_pb"
local UserInfo = require("PlayerInfo.UserInfo");
local HP_pb = require("HP_pb")
local thisPageName = "ABMainPage"  
local NodeHelper = require("NodeHelper");
local ABManager = require("Guild.ABManager")
local AB_pb = require("AllianceBattle_pb")
local GuildDataManager = require("Guild.GuildDataManager")
local BasePage = require("BasePage")
local GuildData = require("Guild.GuildData")
require("ABHelpPage")
require("ABFightListPage")

local opcodes = {
    ALLIANCE_BATTLE_ENTER_C                 = HP_pb.ALLIANCE_BATTLE_ENTER_C,
    ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_C = HP_pb.ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_C,
    ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_S = HP_pb.ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_S
}

local option = {
	ccbiFile = "GuildTournamentPage.ccbi",
	handlerMap = {
		onReturnBtn = "onReturn",
		onAgainstPlan = "onAgainstPlan",
        onDrawOpen = "onAgainstPlan",
		onLastReport = "onLastReport",
		onOpponentInformation = "onOpponentInformation",
		onMatchInvestment = "onMatchInvestment",
        onHelp = "onHelp"
	},
	DataHelper = ABManager
}

local ABMainPage = BasePage:new(option,thisPageName,nil,opcodes)
local timerName = "ABStageTimer"


----------------------------------------------------------------------------------

-----------------------------------------------
--BEGIN ABMainPrepareContent 魔兽元气排行content
----------------------------------------------
local ABMainPrepareContent = {
    ccbiFile = "GuildTournamentContent.ccbi"
}
function ABMainPrepareContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABMainPrepareContent.onRefreshItemView(container);
    elseif eventName == "onViewGuildInfo" then
        ABMainPrepareContent.onViewGuildInfo(container)
	end	
end

function ABMainPrepareContent.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    if ABManager.rankList==nil then return end
    local rankInfo =  ABManager.rankList.rankItemInfos[index]
    if rankInfo~=nil then
        local labelStr = {
            mRankNum = tostring(index),
            mGuildName = rankInfo.name,
            mPresidentName = rankInfo.captainName,
            mVitalityNum = rankInfo.vitality,
            mLastChampion = ""
        }

        if rankInfo:HasField("lastResult") then
            if rankInfo.lastResult <= 4 then
               -- labelStr.mGuildName = "("..common:getLanguageString("@ABRankingResult"..rankInfo.lastResult)..")"..rankInfo.name
               labelStr.mLastChampion = "("..common:getLanguageString("@ABRankingResult"..rankInfo.lastResult)..")"
            end
        end
        
        NodeHelper:setStringForLabel(container, labelStr);
    end
    NodeHelper:setNodesVisible(container,{mRankingNum4 = math.mod(index,2) == 1})
end

function ABMainPrepareContent.onViewGuildInfo(container)
    local index = container:getItemDate().mID;
    if ABManager.rankList==nil then return end
    local rankInfo =  ABManager.rankList.rankItemInfos[index]
    if rankInfo~=nil then
        setABTeamInfoCtrlBtn(true)
        PageManager.viewAllianceTeamInfo(rankInfo.id)
    end
end
--END ABMainPrepareContent

-----------------------------------------------
--BEGIN ABMainFightingContent 对阵图排行content
----------------------------------------------
local ABMainFightingContent = {
    ccbiFile = "GuildTreeDiagramItem.ccbi"
}
function ABMainFightingContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABMainFightingContent.onRefreshItemView(container);
    elseif string.sub(eventName,1,10)=="onGuildBtn" then
        local index = tonumber(string.sub(eventName,11))
        local tab = 0--math.ceil(index/2)
        if index > 16 then 
            tab = math.ceil((index-16)/2)
        else
            tab = math.ceil((index+16)/2)
        end

        if ABManager.fightList~=nil then
            local info = ABManager.fightList.round32_16[tab]

            local id = 0
            if index%2 == 0 then
                id = info.rightId
            else
                id = info.leftId
            end
            showABFightListPage(id)
        end
    elseif eventName == "onAgainstPlan" then
        if ABManager.battleState==AB_pb.PREPARE then
	    elseif ABManager.fightList~=nil then
            showABFightListPage() 
	    end
	end	
end

function ABMainFightingContent.onRefreshItemView(container)
    local nodeVisible = {}
    local labelStr = {}

    --押注信息显示
    local currentRound = ABManager:getCurrentRound()
    local investedId = 0
    if currentRound~=0 then
        local roundNum = 64 / math.pow(2,currentRound)
        for i=1,#ABManager.fightList["round"..roundNum.."_"..(roundNum/2)] do
            local info = ABManager.fightList["round"..roundNum.."_"..(roundNum/2)][i]
            
            if info:HasField("investedId") then
                investedId = info.investedId
            end
        end
    end
    --对阵图显示
    if ABManager.fightList~=nil then
        labelStr.mChampionName = common:getLanguageString("@GuildDrawChampion")
        for i=1,#ABManager.fightList.round2_1 do
            local info = ABManager.fightList.round2_1[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                winnerId = info.winId
                if info.winId == info.leftId then
                    nodeVisible["mWinLine2"..tostring(i).."1"] = true
                    nodeVisible["mWinLine2"..tostring(i).."2"] = false

                    --显示冠军label
                    labelStr.mChampionName = info.leftName
                else
                    nodeVisible["mWinLine2"..tostring(i).."1"] = false
                    nodeVisible["mWinLine2"..tostring(i).."2"] = true

                    --显示冠军label
                    labelStr.mChampionName = info.rightName
                end
            end
        end

        local leftIndex = 0
        local rightIndex = 0
        for i=1,#ABManager.fightList.round32_16 do
            local info = ABManager.fightList.round32_16[i]
            if i <= 8 then
                leftIndex = (i*2) - 1 + 16
                rightIndex = (i*2) + 16 
            else
                leftIndex = (i - 8) * 2 - 1
                rightIndex = (i - 8) * 2 
            end

            labelStr["mGuildName"..(leftIndex)] = info.leftName
            labelStr["mGuildName"..(rightIndex)] = info.rightName

            if AllianceId ~= nil and AllianceId ~= 0  then
                if info.leftId == AllianceId then
                    if container:getVarMenuItemImage("mBtnPic" .. (leftIndex)) ~= nil then
                        container:getVarMenuItemImage("mBtnPic" .. (leftIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.Mine))
                    end
                --[[
                else
                    if container:getVarMenuItemImage("mBtnPic" .. (leftIndex)) ~= nil then
                        container:getVarMenuItemImage("mBtnPic" .. (leftIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.DefaultLeft))
                    end
                ]]
                end

                if info.rightId == AllianceId then
                    if container:getVarMenuItemImage("mBtnPic" .. (rightIndex)) ~= nil then
                        container:getVarMenuItemImage("mBtnPic" .. (rightIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.Mine))
                    end
                --[[
                else
                    if container:getVarMenuItemImage("mBtnPic" .. (rightIndex)) ~= nil then
                        container:getVarMenuItemImage("mBtnPic" .. (rightIndex)):setNormalImage(CCSprite:create(GameConfig.ABGuildBackgroundImg.DefaultRight))
                    end
                ]]
                end
           end

           if winnerId ~= nil and winnerId ~= 0 then
                if container:getVarSprite("mChampionPic" .. (leftIndex) ) ~= nil then
                    container:getVarSprite("mChampionPic" .. (leftIndex) ):setVisible( info.leftId == winnerId )
                end 
                if container:getVarSprite("mChampionPic" .. (rightIndex) ) ~= nil then
                    container:getVarSprite("mChampionPic" .. (rightIndex) ):setVisible( info.rightId == winnerId )
                end
            end

            if investedId~=0 then
                if investedId==info.leftId then
                    labelStr["mGuildName"..(leftIndex)] = info.leftName.."("..common:getLanguageString("@ABBetWord")..")"
                elseif investedId==info.rightId then
                    labelStr["mGuildName"..(rightIndex)] = info.rightName.."("..common:getLanguageString("@ABBetWord")..")"
                end
            end
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine32"..tostring(i).."1"] = true
                    nodeVisible["mWinLine32"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine32"..tostring(i).."1"] = false
                    nodeVisible["mWinLine32"..tostring(i).."2"] = true
                end

                nodeVisible.mResult32 = true
            else
                nodeVisible["mResult32"..i]=false
            end
        end
        
        for i=1,#ABManager.fightList.round16_8 do
            local info = ABManager.fightList.round16_8[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine16"..tostring(i).."1"] = true
                    nodeVisible["mWinLine16"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine16"..tostring(i).."1"] = false
                    nodeVisible["mWinLine16"..tostring(i).."2"] = true
                end
                nodeVisible.mResult16 = true
            else
                nodeVisible["mResult16"..i]=false
            end
        end
        
        for i=1,#ABManager.fightList.round8_4 do
            local info = ABManager.fightList.round8_4[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine8"..tostring(i).."1"] = true
                    nodeVisible["mWinLine8"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine8"..tostring(i).."1"] = false
                    nodeVisible["mWinLine8"..tostring(i).."2"] = true
                end
                nodeVisible.mResult8 = true
            else
                nodeVisible["mResult8"..i]=false
            end
        end
        
        for i=1,#ABManager.fightList.round4_2 do
            local info = ABManager.fightList.round4_2[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine4"..tostring(i).."1"] = true
                    nodeVisible["mWinLine4"..tostring(i).."2"] = false
                else
                    nodeVisible["mWinLine4"..tostring(i).."1"] = false
                    nodeVisible["mWinLine4"..tostring(i).."2"] = true
                end
            end
        end
        --[[
        for i=1,#ABManager.fightList.round2_1 do
            local info = ABManager.fightList.round2_1[i]
            
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    nodeVisible["mWinLine2"..tostring(i).."1"] = true
                    nodeVisible["mWinLine2"..tostring(i).."2"] = false

                    --container:getVarSprite("mChampionPic" .. (leftIndex) ):setVisible( true )
                else
                    nodeVisible["mWinLine2"..tostring(i).."1"] = false
                    nodeVisible["mWinLine2"..tostring(i).."2"] = true

                    --container:getVarSprite("mChampionPic" .. (rightIndex) ):setVisible( true )
                end
            end
        end
        ]]
    end
    
    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
end
--END ABMainPrepareContent

-----------------------------------------------
--ABMainPage页面中的事件处理
----------------------------------------------
function ABMainPage:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    self:registerPacket(container)
    
    NodeHelper:initScrollView(container, "mContent", 8);
	if container.mScrollView~=nil then
		container:autoAdjustResizeScrollview(container.mScrollView);
	end
	
	NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite2"))
    NodeHelper:autoAdjustResizeScale9Sprite(container:getVarScale9Sprite("mScale9Sprite1"))
    --对阵图的scrollview
	container.mFightScrollView = container:getVarScrollView("mContent1");	
	if container.mFightScrollView ~= nil then
	    container.mFightScrollViewRootNode = container.mFightScrollView:getContainer();
	    container.m_pFightScrollViewFacade = CCReViScrollViewFacade:new_local(container.mFightScrollView);
	    container.m_pFightScrollViewFacade:init(4, 3);
        container.m_pFightScrollViewFacade:setBouncedFlag(false);
		--container:autoAdjustResizeScrollview(container.mFightScrollView);
	end

	if Golb_Platform_Info.is_entermate_platform then
		NodeHelper:setNodesVisible(container,{mBT_Help_Node = false})
	end
    self:getPageInfo(container)

    
    
    NodeHelper:setLabelOneByOne(container,"mGuildGetVitality","mGuildVitalityNum",5,true)
    --NodeHelper:setLabelOneByOne(container,"mSelectionPeriod","mFinish",5,true)
    NodeHelper:setLabelOneByOne(container,"mGuildRanking","mGuildRankingNum",5,true)
    NodeHelper:setLabelOneByOne(container,"mAgainstGuild","mGuildNameLab",5,true)

    if Golb_Platform_Info.is_r2_platform then
        local finishNum = container:getVarNode("mFinishNum")
        local finishTitle = container:getVarNode("mFinish")

        if finishNum ~= nil and finishTitle ~= nil then
            finishNum:setPositionY(finishTitle:getPositionY())
            finishNum:setAnchorPoint(finishTitle:getAnchorPoint());
            --NodeHelper:setLabelOneByOne(container,"mFinish","mFinishNum",5,true)
        end
        if IsThaiLanguage() then
            
            NodeHelper:MoveAndScaleNode(container, {mGuildTournamentText1 = common:getLanguageString("@GuildTournamentText1")},0,0.8,0.8)
        end
    end
end

function ABMainPage:getPageInfo(container)
    self:refreshPage(container)
end

function ABMainPage:onExecute(container)
	self:onTimer(container,"stageLeftTime","mFinishNum")

    ABManager:autoChangeState()

    --NodeHelper:setLabelOneByOne(container,"mFinish","mFinishNum")
end

function ABMainPage:onExit(container)
	NodeHelper:deleteScrollView(container);	
    if container.mFightScrollView~=nil then
        container.mFightScrollView:getContainer():removeAllChildren();
        if container.m_pFightScrollViewFacade then
		    container.m_pFightScrollViewFacade:delete();
		    container.m_pFightScrollViewFacade = nil;
        end
        container.mFightScrollView = nil
	end

    if TimeCalculator:getInstance():hasKey("stageLeftTime") then
		TimeCalculator:getInstance():removeTimeCalcultor("stageLeftTime");	
    end

    container:removeMessage(MSG_MAINFRAME_REFRESH);
end
----------------------------------------------------------------

function ABMainPage:refreshPreparePage(container)
    local nodeVisible = {
        mPicHelpBtn = false,
        mGuildABNode = true,
        mGuildListNode = true,
        mContent = true,
        mContent1 = false,
		mTournamentTex = true,
        mRoundNum = false,
		mGuildTreeNode = false
    }
    local labelStr = {}

    if ABManager.rankList ~=nil then
        if AllianceOpen== false then
            --没有公会
            nodeVisible.mGuildGetVitality = false;
            nodeVisible.mGuildVitalityNum = false;
            nodeVisible.mGuildRanking = false
            nodeVisible.mGuildRankingNum = false
            nodeVisible.mAgainstGuild = false
            nodeVisible.mGuildNameLab = false
            labelStr = {
                mJoinBattleTex = common:getLanguageString("@ABPrepareState")
            }
        else
            labelStr = {
                mGuildVitalityNum = tostring(ABManager.rankList.selfTotalVitality),
                mJoinBattleTex = common:getLanguageString("@ABPrepareState")
            }
			NodeHelper:setLabelOneByOne(container,"mGuildGetVitality","mGuildVitalityNum",5)
            if ABManager.rankList.selfRank <=0 then    
                labelStr.mGuildRankingNum = common:getLanguageString("@ABRankOutOf32")
            else
                labelStr.mGuildRankingNum = tostring(ABManager.rankList.selfRank)
            end

            if ABManager.rankList:HasField("estimateAllianceItemInfo") then
                local enemyInfo = ABManager.rankList.estimateAllianceItemInfo
                labelStr.mGuildNameLab = common:getLanguageString("@EstimateAgainstGuild",enemyInfo.name,enemyInfo.level,enemyInfo.memSize)
            else
                if ABManager.rankList:HasField("selfRank") and ABManager.rankList.selfRank<=32 then
                    labelStr.mGuildNameLab = common:getLanguageString("@ABRankOutOf32")
                else
                    labelStr.mAgainstGuild = common:getLanguageString("@ABFailure") 
                    nodeVisible.mGuildNameLab = false
                end     
            end

            if ABManager.battleState == AB_pb.Draw_Lots_WAIT then 
                labelStr.mAgainstGuild = ""
                nodeVisible.mGuildNameLab = false
            end
        end      
    end
    labelStr.mJoinBettleTex = common:getLanguageString("@ABJoinTex")

    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABMainPage:refreshFightingPage(container)
    local nodeVisible = {
        mPicHelpBtn = false,
        mGuildABNode = true,
        mGuildGetVitality = false,
        mGuildVitalityNum = false,
        mGuildRanking = false,
        mGuildRankingNum = false,
        mGuildListNode = false,
        mContent = false,
        mContent1 = true,
		mTournamentTex = false,
        mRoundNum = true,
		mGuildTreeNode = true
    }
    local labelStr = {}
    
    --底部文字显示
    if ABManager.fightList ~=nil then
        if ABManager.battleState == AB_pb.SHOW_TIME then
            --空判断
        elseif AllianceOpen== false  then
            --没有公会
            labelStr.mAgainstGuild = common:getLanguageString("@ABNotJoinGuild")
            nodeVisible.mGuildNameLab = false
        elseif (not ABManager.fightList:HasField("estimateAllianceItemInfo")) and ABManager.battleState ~= AB_pb.SHOW_TIME then
            --未进入32强
            labelStr.mAgainstGuild = common:getLanguageString("@ABFailure") 
            nodeVisible.mGuildNameLab = false
        else
            nodeVisible.mAgainstGuild = true
            nodeVisible.mGuildNameLab = true

            if ABManager:checkIsFightingState() then
                nodeVisible.mGuildNameLab = false
            end

            if ABManager.fightList:HasField("failureGroup") then
                local round = 32/(math.pow(2,ABManager.fightList.failureGroup-1))

                if round==2 then 
                    labelStr.mAgainstGuild = common:getLanguageString("@ABFailureTex2")
                else
                    labelStr.mAgainstGuild = common:getLanguageString("@ABFailureTex",round)
                end

                nodeVisible.mGuildNameLab = true
            end
            local enemyInfo = ABManager.fightList.estimateAllianceItemInfo
            if enemyInfo~=nil then
                labelStr.mGuildNameLab = common:getLanguageString("@EstimateAgainstGuild",enemyInfo.name,enemyInfo.level,enemyInfo.memSize)
            end
        end
    end
    
    if ABManager.FightReport.CurrentFight~=nil and ABManager:checkGuildInFightList() then
        labelStr.mJoinBettleTex = common:getLanguageString("@CheckReport")
    else
        labelStr.mJoinBettleTex = common:getLanguageString("@ABJoinTex2")
    end
    
    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABMainPage:refreshPage(container)
    --设置文本信息
    local labelStr={}
    local nodeVisible = {}
    local TexSetting = ABManager:getConfigDataByKey("TexSetting")
    local state = ABManager.battleState
    for k,v in pairs(TexSetting) do
        if TexSetting[k][state]~=nil then
            nodeVisible[k] = TexSetting[k][state].visible
            labelStr[k] = TexSetting[k][state].tex
        end
    end
    NodeHelper:setStringForLabel(container, labelStr);
    NodeHelper:setNodesVisible(container,nodeVisible)
    --设置数据信息
	if ABManager.battleState == AB_pb.PREPARE or ABManager.battleState == AB_pb.Draw_Lots_WAIT then
		--prepare state
		self:refreshPreparePage(container)
		self:rebuildAllItem(container)
	else
		--Fighting state
		self:refreshFightingPage(container)
		self:rebuildAllItem(container)
	end

    --抽签提示按钮
    self:changeBallotState(container, false)
    NodeHelper:setNodesVisible(container, {mDrawbtn = false})
    NodeHelper:setNodesVisible(container, {mAgainstPlanBtn = true})
    if ABManager.battleState == AB_pb.Draw_Lots_WAIT and GuildData.GuildBattleBallot then
        NodeHelper:setNodesVisible(container, {mDrawbtn = true})
        NodeHelper:setNodesVisible(container, {mAgainstPlanBtn = false})

        if not ABManager:getHasDraw() then 
            self:changeBallotState(container, true)
        end
    end
end

function ABMainPage:updateBallotState(container)
    self:changeBallotState(container, false)
    if not ABManager:getHasDraw() then 
        self:changeBallotState(container, true)
    end
end

function ABMainPage:changeBallotState(container, _bool)
    NodeHelper:setNodesVisible(container, {mNewClick = _bool})
end

----------------Scroll View------------------------
function ABMainPage:rebuildAllItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end

function ABMainPage:clearAllItem(container)
    NodeHelper:clearScrollView(container);

    if container.mFightScrollView~=nil then
        container.mFightScrollView:getContainer():removeAllChildren();
    end
end

function ABMainPage:buildItem(container)
    if ABManager.battleState == AB_pb.PREPARE or ABManager.battleState == AB_pb.Draw_Lots_WAIT then
        if ABManager.rankList~=nil then
            local rankSize = ABManager.rankList.rankItemInfos and #ABManager.rankList.rankItemInfos or 0
            NodeHelper:buildScrollView(container, rankSize, ABMainPrepareContent.ccbiFile, ABMainPrepareContent.onFunction)
        end
    elseif ABManager.fightList~=nil then
        local fOneItemHeight = 0
        local fOneItemWidth = 0
        local pItem = ScriptContentBase:create(ABMainFightingContent.ccbiFile)
		pItem.id = 1
		pItem:registerFunctionHandler(ABMainFightingContent.onFunction)
        if container.mFightScrollView~=nil then
            local pItemData = CCReViSvItemData:new_local()
		    pItemData.mID = 1
		    pItemData.m_iIdx = 1
		    pItemData.m_ptPosition = ccp(0, 0)
            container.m_pFightScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)

		    if fOneItemHeight < pItem:getContentSize().height then
			    fOneItemHeight = pItem:getContentSize().height
		    end

		    if fOneItemWidth < pItem:getContentSize().width then
			    fOneItemWidth = pItem:getContentSize().width
		    end

            local size = CCSizeMake(fOneItemWidth, fOneItemHeight)
            container.mFightScrollView:setContentSize(size)
            container.mFightScrollView:setContentOffset(ccp(0, container.mFightScrollView:getViewSize().height - container.mFightScrollView:getContentSize().height * container.mFightScrollView:getScaleY()))
            container.m_pFightScrollViewFacade:setDynamicItemsStartPosition(0);
            container.mFightScrollView:forceRecaculateChildren();
            ScriptMathToLua:setSwallowsTouches(container.mFightScrollView)
        end
    end
end
----------------click event------------------------
function ABMainPage:onReturn(container)
	PageManager.changePage("GuildPage")
end

function ABMainPage:onHelp(container)
    showABHelpPageAtIndex()
end	

function ABMainPage:onOpponentInformation(container)
    if ABManager.battleState==AB_pb.PREPARE then
        if ABManager.rankList~=nil and ABManager.rankList:HasField("estimateAllianceItemInfo") then
            setABTeamInfoCtrlBtn(false)
            PageManager.viewAllianceTeamInfo(ABManager.rankList.estimateAllianceItemInfo.id)
        else
            MessageBoxPage:Msg_Box_Lan("@ABNoEstimateAlliance");
            return
        end
    elseif ABManager.fightList~=nil then
        if ABManager.fightList~=nil and ABManager.fightList:HasField("estimateAllianceItemInfo") then
            setABTeamInfoCtrlBtn(false)
            PageManager.viewAllianceTeamInfo(ABManager.fightList.estimateAllianceItemInfo.id)
        else
            MessageBoxPage:Msg_Box_Lan("@ABNoEstimateAlliance");
            return
        end
    else
        MessageBoxPage:Msg_Box_Lan("@ABNoEstimateAlliance");
    end
end	

function ABMainPage:onAgainstPlan(container)
    CCLuaLog("##ABManager.battleState = "..tostring(ABManager.battleState))
    CCLuaLog("##ABManager.battleState = "..tostring(ABManager.battleState))
    if ABManager.battleState==AB_pb.PREPARE then
	    MessageBoxPage:Msg_Box_Lan("@ABFightNoStart");
    elseif ABManager.battleState==AB_pb.Draw_Lots_WAIT then 
        if GuildData.GuildBattleBallot then 
            PageManager.pushPage("GuildBattleBallot")
        else
            MessageBoxPage:Msg_Box_Lan("@ABFightNoStart")
        end        
	elseif ABManager.fightList~=nil then
        showABFightListPage() 
	end
end	

function ABMainPage:onLastReport(container) 
    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPLastBattleFightInfo();
    common:sendPacket(opcodes.ALLIANCE_BATTLE_LAST_STAGE_FIGHT_INFO_C, msg);
end	

function ABMainPage:onHelp(container)
    showABHelpPageAtIndex(1)
end

function ABMainPage:onMatchInvestment(container)
    if AllianceOpen==false then 
         MessageBoxPage:Msg_Box_Lan("@NoAlliance");
        return 
    end

	if ABManager.battleState==AB_pb.PREPARE or ABManager.battleState==AB_pb.Draw_Lots_WAIT then
	    PageManager.changePage("ABJoinPage")
	elseif ABManager.fightList~=nil then
        if ABManager.FightReport.CurrentFight~=nil and ABManager:checkGuildInFightList() then
           PageManager.changePage("ABTeamFightPage")
        else
           setABTeamInfoCtrlBtn(true)
           PageManager.viewAllianceTeamInfo(GuildDataManager:getGuildId())
        end
	end
end	

function ABMainPage:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_MAINFRAME_REFRESH then
        local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam;
        --刷新抽签的状态
        if pageName == thisPageName and extraParam == "updateBallotState" then --
            self:updateBallotState(container)
        elseif pageName == "ABManager" then
            PageManager.changePage("GuildPage")
		end
    end
end