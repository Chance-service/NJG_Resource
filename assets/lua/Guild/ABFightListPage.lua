
local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper")
local AllianceBattle_pb = require("AllianceBattle_pb")
local GameConfig = require("GameConfig")
require("ABFightReportPage")
require("ABBetPage")
local thisPageName = "ABFightListPage"
local opcodes = {
ALLIANCE_BATTLE_INSPIRE_S = HP_pb.ALLIANCE_BATTLE_INSPIRE_S
}

local option = {
	ccbiFile = "GuildAgainstPlanPopUp.ccbi",
	handlerMap = {
		onClose = "onClose"
	},
	DataHelper = ABManager
}

local isLast = false
local fightList = nil --保存显示列表
local AllianceId = nil --用于筛选
local TitleIndex = {}

local ABFightListPage = BasePage:new(option,thisPageName,nil,opcodes)



-----------------------------------------------
--BEGIN ABFightListContent 对阵列表content
----------------------------------------------
local ABFightListContent = {
    ccbiFile = "GuildAgainstPlanContent.ccbi"
}

function ABFightListContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABFightListContent.onRefreshItemView(container);
	elseif eventName == "onMatchInvestment" then
	    ABFightListContent.onMatchInvestment(container)
    elseif eventName == "onInspire" then
	    ABFightListContent.onInspire(container)
	end	
end

function ABFightListContent.onRefreshItemView(container)
    local index = container:getItemDate().mID;
    local isTitle = 0;
    
    --判断是否是title项
    for i=1,#TitleIndex do
        if index==TitleIndex[i] then
            isTitle = i
            break
        end
    end
    
    local labelStr = {}
    local nodeVisible = {}
    local labelColor = {}
    
    --默认显示红色按钮
    nodeVisible.mMatch1 = true
    nodeVisible.mMatch2 = false

    if isTitle~=0 then
        nodeVisible.mCamp = false
        nodeVisible.mMatchNode = false
        nodeVisible.mMatchTime = true
        labelStr.mMatchTimeLab = fightList[index]
    else
        local info = fightList[index]
        nodeVisible.mCamp = true
        nodeVisible.mMatchNode = true  
        nodeVisible.mMatchTime = false  
        
        if info~=nil then
            --押注阶段
            if info.state == AllianceBattle_pb.AF_NONE then
                --判断是否已押注
                local GuildDataManager = require("Guild.GuildDataManager")
                local curAllianceId = GuildDataManager:getGuildId();
                if curAllianceId == nil then 
                    NodeHelper:setNodesVisible(container,{mInspireNode = false})
                else
                    --如果selfInspireNum>0，表示可以鼓舞的状态，否则，不能鼓舞，如刚12级过来投资的人
                    if curAllianceId == info.leftId or curAllianceId == info.rightId then 
                        if ABManager.selfInspireNum >= 0 then 
                            NodeHelper:setNodesVisible(container,{mInspireNode = true})
                        else
                            NodeHelper:setNodesVisible(container,{mInspireNode = false})
                        end
                    else
                        NodeHelper:setNodesVisible(container,{mInspireNode = false})
                    end
                    
                end
               
                if info:HasField("investedId") then
                    labelStr.mMatchInvestment = common:getLanguageString("@ABHasBet")
                    nodeVisible.mMatch2 = true
                    nodeVisible.mMatch1 = false
                else
                    labelStr.mMatchInvestment = common:getLanguageString("@ABBet")
                    NodeHelper:setMenuItemEnabled(container, "mMatchBtn", true )
                    if ABManager.hasBet == true then
                         NodeHelper:setMenuItemEnabled(container, "mMatchBtn", false )
                    end
                end
            --战斗中阶段 
            elseif info.state == AllianceBattle_pb.AF_FIGHTING then
                labelStr.mMatchInvestment = common:getLanguageString("@ABInFignt")
                NodeHelper:setNodesVisible(container,{mInspireNode = false})
            --战斗结束查看战报阶段
            elseif info.state == AllianceBattle_pb.AF_END then
                labelStr.mMatchInvestment = common:getLanguageString("@ABReport")
                NodeHelper:setNodesVisible(container,{mInspireNode = false})
            end
            --公会双方名称
            labelStr.mCamp1 = info.leftName
            labelStr.mCamp2 = info.rightName
            --判断输赢公会（必须处于战斗结束阶段才显示）
            if info:HasField("winId") and info.state==AllianceBattle_pb.AF_END then
                if info.winId == info.leftId then
                    labelColor.mCamp1 = ABManager:getConfigDataByKey("WinColor")
                    labelColor.mCamp2 = ABManager:getConfigDataByKey("LoseColor")
                else
                    labelColor.mCamp1 = ABManager:getConfigDataByKey("LoseColor")
                    labelColor.mCamp2 = ABManager:getConfigDataByKey("WinColor")
                end
            end
        end
    end
    NodeHelper:setColorForLabel(container,labelColor)
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)
end

function ABFightListContent.onInspire(container)
    local title = Language:getInstance():getString("@ABFightListInspireTitle")	
	--local message = Language:getInstance():getString("@ABFightListInspireMsg")
    local selfInspireNum = ABManager.selfInspireNum
    local totalSelfInspireNum = ABManager.totalSelfInspireNum
    assert(selfInspireNum~=nil,"Error in selfInspireNum~=nil")
    if selfInspireNum >=5 then 
       local totalInspirePer = ABManager:getConfigDataByKeyAndIndex("InspireRewardPercent",totalSelfInspireNum)
       local message = common:getLanguageString("@ABFightListInspireReachLimitMsg",totalInspirePer).."1"
       PageManager.showConfirmMoreLine(title,message, function(isSure)
		    if isSure then
               --MessageBoxPage:Msg_Box_Lan("@ABFightListReachLimit")
		    end
	    end,true);
    else
        local costDiamond = ABManager:getConfigDataByKeyAndIndex("InspireCostDiamond",selfInspireNum)
        assert(costDiamond~=nil,"Error in costDiamond~=nil")
        local bloodPer = ABManager:getConfigDataByKeyAndIndex("InspireBloodEnhancePercent",selfInspireNum)
        assert(bloodPer~=nil,"Error in bloodPer~=nil")
        local attactPer = ABManager:getConfigDataByKeyAndIndex("InspireAttactEnhancePercent",selfInspireNum)
        assert(attactPer~=nil,"Error in attactPer~=nil")
        local totalInspirePer = ABManager:getConfigDataByKeyAndIndex("InspireRewardPercent",totalSelfInspireNum)
        assert(totalInspirePer~=nil,"Error in totalInspirePer~=nil")
        local rewardPerTime = ABManager:getConfigDataByKey("InspireRewardPerTime")

	    local finalMsg = common:getLanguageString("@ABFightListInspireMsg",costDiamond,
        bloodPer,attactPer,totalInspirePer,selfInspireNum,totalInspirePer);
	    PageManager.showConfirmMoreLine(title,finalMsg, function(isSure)
            local UserInfo = require("PlayerInfo.UserInfo");
            if ABManager.selfInspireNum<5 then
                if isSure and UserInfo.isGoldEnough(costDiamond) then
                    common:sendEmptyPacket(HP_pb.ALLIANCE_BATTLE_INSPIRE_C,true)
                end
		    else
                return PageManager:popAllPage();
            end
	    end,false);
    end
    
end


function ABFightListContent.onMatchInvestment(container)
    local index = container:getItemDate().mID;

    --根据状态选择要跳转的页面
    local info = fightList[index]
    if info~=nil then
        if info.state == AllianceBattle_pb.AF_NONE then
            --判断当前点击项是第几轮
            local fightRound = 1
            for i=1,#TitleIndex do
                if TitleIndex[i+1]==nil then
                    fightRound = i
                    break
                end
                if index>TitleIndex[i] and index<TitleIndex[i+1] then
                    fightRound = i
                    break
                end
            end
            showBetPageByFightId(info.id,fightRound,isLast)
        elseif info.state == AllianceBattle_pb.AF_FIGHTING then
            MessageBoxPage:Msg_Box_Lan("@ABFightNoFinish");
            return
        elseif info.state == AllianceBattle_pb.AF_END then
            showABFightReportByFightId(info.id,isLast)
        end
    end
end
--END ABMainPrepareContent

function ABFightListPage:onEnter(container)  
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    NodeHelper:initScrollView(container, "mContent", 12);
    NodeHelper:setLabelOneByOne(container, "mFightText1", "mFightText2")
    
    self:getPageInfo(container)
end

function ABFightListPage:getPageInfo(container)
    self:refreshPage(container)
end

function ABFightListPage:onRefreshPage(container)   
    self:refreshPage(container)
end

function ABFightListPage:refreshPage(container)   
    local labelStr = {}  

    NodeHelper:setStringForLabel(container, labelStr);

    self:refreshShowList(container)
end

function ABFightListPage:refreshShowList(container)
    
    
    fightList = {}
	--判断是否是上一届
    local tempList = nil
    if isLast then
        if ABManager.lastFightList==nil then return end
        tempList = ABManager.lastFightList
    else
        if ABManager.fightList==nil then return end
        tempList = ABManager.fightList
    end
    --判断是否筛选，遍历战斗将需要显示的战斗条目压入fightList
    if AllianceId==nil then
        TitleIndex = {}
        TitleIndex = {[1]=1}
        
        fightList[1] = common:getLanguageString("@ABFightListTitleTime1")
        for i=1,#tempList.round32_16 do
            local info = tempList.round32_16[i]
            table.insert(fightList,info)
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[2]] = common:getLanguageString("@ABFightListTitleTime2")
        for i=1,#tempList.round16_8 do
            local info = tempList.round16_8[i]
            table.insert(fightList,info)
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[3]] = common:getLanguageString("@ABFightListTitleTime3")
        for i=1,#tempList.round8_4 do
            local info = tempList.round8_4[i]
            table.insert(fightList,info)
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[4]] = common:getLanguageString("@ABFightListTitleTime4")
        for i=1,#tempList.round4_2 do
            local info = tempList.round4_2[i]
            table.insert(fightList,info)
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[5]] = common:getLanguageString("@ABFightListTitleTime5")
        for i=1,#tempList.round2_1 do
            local info = tempList.round2_1[i]
            table.insert(fightList,info)
        end
    else
        TitleIndex = {}    
        TitleIndex = {[1]=1}
        
        fightList[1] = common:getLanguageString("@ABFightListTitleTime1")
        for i=1,#tempList.round32_16 do
            local info = tempList.round32_16[i]
            if info.leftId == AllianceId or info.rightId == AllianceId then
                table.insert(fightList,info)
                break
            end
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[2]] = common:getLanguageString("@ABFightListTitleTime2")
        for i=1,#tempList.round16_8 do
            local info = tempList.round16_8[i]
            if info.leftId == AllianceId or info.rightId == AllianceId then
                table.insert(fightList,info)
                break
            end
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[3]] = common:getLanguageString("@ABFightListTitleTime3")
        for i=1,#tempList.round8_4 do
            local info = tempList.round8_4[i]
            if info.leftId == AllianceId or info.rightId == AllianceId then
                table.insert(fightList,info)
                break
            end
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[4]] = common:getLanguageString("@ABFightListTitleTime4")
        for i=1,#tempList.round4_2 do
            local info = tempList.round4_2[i]
            if info.leftId == AllianceId or info.rightId == AllianceId then
                table.insert(fightList,info)
                break
            end
        end
        table.insert(TitleIndex,(#fightList)+1)
        
        fightList[TitleIndex[5]] = common:getLanguageString("@ABFightListTitleTime5")
        for i=1,#tempList.round2_1 do
            local info = tempList.round2_1[i]
            if info.leftId == AllianceId or info.rightId == AllianceId then
                table.insert(fightList,info)
                break
            end
        end
    end
    self:rebuildAllItem(container)  
end

function ABFightListPage:onExecute(container)
end

--------------ScrollView---------------------------------------

function ABFightListPage:buildItem(container)  
    if fightList~=nil then
        local size = #fightList
        NodeHelper:buildScrollView(container, size, ABFightListContent.ccbiFile, ABFightListContent.onFunction)
    end
end

--------------Click Event--------------------------------------

--------------Call Function------------------------------------
function showABFightListPage(allianceId,islast) 
    isLast = islast or false
    AllianceId = allianceId 
    PageManager.pushPage("ABFightListPage")
end


