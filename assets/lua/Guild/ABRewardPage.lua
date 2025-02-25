
local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper")
local AllianceBattle_pb = require("AllianceBattle_pb")
local GuildDataManager = require("Guild.GuildDataManager")
local HP_pb = require("HP_pb")
require("ABFightReportPage")
require("ABBetPage")
local thisPageName = "ABRewardPage"
local opcodes = {
    ALLIANCE_BATTLE_ENTER_C = HP_pb.ALLIANCE_BATTLE_ENTER_C
}

local option = {
	ccbiFile = "GuildBattleRewardPage.ccbi",
	handlerMap = {
		onReturnBtn = "onReturn",
        onTeamInformationBtn = "onTeamInformationBtn",
        onHelp = "onHelp"
	},
	DataHelper = ABManager
}

local rewardParams = {
	        mainNode = "mRewardNode",
	        countNode = "mNum",
            nameNode = "mName",
            frameNode = "mFeet",
            picNode = "mRewardPic",
            startIndex = 1
}

local resultTex = {
    [1] = common:getLanguageString("@ABResult1"),
    [2] = common:getLanguageString("@ABResult2"),
    [3] = common:getLanguageString("@ABResult3"),
    [4] = common:getLanguageString("@ABResult4"),
    [5] = common:getLanguageString("@ABResult5"),
    [6] = common:getLanguageString("@ABResult6")
}


local ABRewardPage = BasePage:new(option,thisPageName,nil,opcodes)
local MaxSize = 8


-----------------------------------------------
--BEGIN ABMainShowContent 展示阶段content
----------------------------------------------
local ABRewardShowContent = {
    ccbiFile = "GuildBattleRewardContent.ccbi"
}
function ABRewardShowContent.onFunction(eventName,container)
    if eventName == "luaRefreshItemView" then
		ABRewardShowContent.onRefreshItemView(container);
    elseif string.sub(eventName,1,6) == "onFeet" then
        local result = container.id;
        if result==1 then
        elseif result==2 then
        elseif result<=4 then
            result = 3
        elseif result<=8 then
            result = 4
        end
        local index = tonumber(string.sub(eventName,-1))
        local rankCfg = ABManager:getConfigDataByKeyAndIndex("QuarterFinalsReward",result)
        if rankCfg~= nil then 
            ABRewardShowContent:showItemTip(container,rankCfg.reward,index,"mFeet")
        end
    elseif eventName == "onHead" then
        ABRewardShowContent.onShowTeamInfo(container)
	end	
end

function ABRewardShowContent.onRefreshItemView(container)
    
end

function ABRewardShowContent:showItemTip(container,cfg,rewardIndex,nodeNmae)
	if cfg~=nil and cfg[rewardIndex] ~= nil then
	    GameUtil:showTip(container:getVarNode(nodeNmae .. rewardIndex), common:table_merge(cfg[rewardIndex],{buyTip=true,hideBuyNum=true}));
	end
end

function ABRewardShowContent.onShowTeamInfo(container)
    local index = container.id
    if ABManager.rankList~=nil then
        local info = ABManager.rankList.rankItemInfos[index]
        if info~=nil then
            setABTeamInfoCtrlBtn(false)
            PageManager.viewAllianceTeamInfo(info.id)
        end
    end
end
--END ABMainShowContent


function ABRewardPage:getPageInfo(container)
    self:refreshPage(container)
    self:rebuildAllItem(container)
end

function ABRewardPage:onEnter(container)  
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);

    NodeHelper:initScrollView(container, "mContent", 5);
    if container.mScrollView~=nil then
        container:autoAdjustResizeScrollview(container.mScrollView);
    end
    
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
    if mScale9Sprite ~= nil then
        container:autoAdjustResizeScale9Sprite( mScale9Sprite )
    end
    local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
    if mScale9Sprite2 ~= nil then
        container:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
    end    
    
    self:getPageInfo(container)
end


function ABRewardPage:refreshPage(container)   
    local labelStr = {}
        
    NodeHelper:setStringForLabel(container, labelStr);
end

function ABRewardPage:onExecute(container)
	self:onTimer(container,"stageLeftTime","mFinishNum")

    ABManager:autoChangeState()
end

function ABRewardPage:onReceiveMessage(container)
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

function ABRewardPage:buildItem(container)
    if ABManager.rankList~=nil then
        local size = #ABManager.rankList.rankItemInfos
        --NodeHelper:buildScrollView(container, (#ABManager.rankList.rankItemInfos), ABRewardShowContent.ccbiFile, ABRewardShowContent.onFunction)

	    local fOneItemHeight = 0
	    local fOneItemWidth = 0
		
	    for i=size, 1, -1 do
			local pItem = ScriptContentBase:create(ABRewardShowContent.ccbiFile)
			pItem.id = i
			pItem:registerFunctionHandler(ABRewardShowContent.onFunction)
            pItem:setPositionY(fOneItemHeight)

            --设置基础信息
            local index = i
            local nodeVisible = {}
            local labelStr = {}
            local imgMenu = {}
			local titleHeight = 0
            local info = ABManager.rankList.rankItemInfos[index]
            if info~=nil then
                --基本信息
                labelStr.mGuildName = info.name
                if info:HasField("result") then
                    imgMenu.mHeadPic = ABManager:getConfigDataByKeyAndIndex("QuarterFace",info.result)
                    labelStr.mResultTex = resultTex[info.result]

                    local titleCount = math.pow(2,(info.result-2)) + 1 
                    if index ~= titleCount and index > 1 then 
                        nodeVisible.mTitleNode = false
                        local newSize = pItem:getContentSize()
                        local titleNode = pItem:getVarNode("mTitleNode")
                        if titleNode~=nil then
                            newSize.height = newSize.height - titleNode:getContentSize().height
							titleHeight = titleNode:getContentSize().height
                        end
                        pItem:setContentSize(newSize)
                    end
                end
                --填充奖励
                local rankRewardCfg = ABManager:getConfigDataByKeyAndIndex("QuarterFinalsReward",info.result)
                if rankRewardCfg~=nil then
                    NodeHelper:fillRewardItemWithParams(pItem, rankRewardCfg.reward, 4,rewardParams)
                end

                NodeHelper:setNormalImages(pItem,imgMenu)
                NodeHelper:setStringForLabel(pItem, labelStr);
                NodeHelper:setNodesVisible(pItem,nodeVisible)
            end

			fOneItemHeight = fOneItemHeight+pItem:getContentSize().height
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.mScrollView:getContainer():addChild(pItem)
	    end

	    local size = CCSizeMake(fOneItemWidth, fOneItemHeight)
	    container.mScrollView:setContentSize(size)
	    container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height * container.mScrollView:getScaleY()))
	    container.mScrollView:forceRecaculateChildren();
	    ScriptMathToLua:setSwallowsTouches(container.mScrollView)  
    end
end

--------------Click Event--------------------------------------

function ABRewardPage:showItemTip(container,rewardId,rewardIndex)
	if rewardInfo~=nil then
	    local cfg = ConfigManager.getRewardById(rewardId); 
	    if cfg[rewardIndex] ~= nil then
	        GameUtil:showTip(container:getVarNode('mFeet0' .. rewardIndex), common:table_merge(cfg[rewardIndex],{buyTip=true,hideBuyNum=true}));
	    end
	end
end

function ABRewardPage:onTeamInformationBtn(container)
    if AllianceOpen then
        setABTeamInfoCtrlBtn(false)
        PageManager.viewAllianceTeamInfo(GuildDataManager:getGuildId())
    else 
        MessageBoxPage:Msg_Box_Lan("@NoAlliance");
    end
end

function ABRewardPage:onHelp(container)
    require("ABHelpPage")
	showABHelpPageAtIndex(1)
end

function ABRewardPage:onReturn(container)
	PageManager.changePage("ABMainPage")
end
