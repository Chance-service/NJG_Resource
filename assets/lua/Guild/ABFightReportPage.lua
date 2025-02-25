

local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper");
local GameConfig = require("GameConfig")
local HP_pb = require("HP_pb")
local thisPageName = "ABFightReportPage"
local opcodes = {
    ALLIANCE_BATTLE_TEAM_FIGHT_INFO_C = HP_pb.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_C,
    ALLIANCE_BATTLE_TEAM_FIGHT_INFO_S = HP_pb.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_S,
    ALLIANCE_BATTLE_FIGHT_REPORT_C = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_C,
    ALLIANCE_BATTLE_FIGHT_REPORT_S = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_S
}

local option = {
	ccbiFile = "GuildCheckReportPopUp.ccbi",
	handlerMap = {
		onClose = "onClose",
        onBUffFeet1 = "onLeftBuffer",
        onBUffFeet2 = "onRightBuffer",
	},
	DataHelper = ABManager
}
local ABFightReportPage = nil
local onFunctionEx = function(eventName,container)
    if string.sub(eventName,1,12)=="onShowBattle" then
        ABFightReportPage:onShowBattle(container,tonumber(string.sub(eventName,-1))) 
    end
end
ABFightReportPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes)
local FightId = nil
local isLast = false
local MaxSize = 5
local inValidList = {}

--工会buffer节点参数
local guildBufferParams = {
	        mainNode = "mBuffNode",
	        countNode = "",
            nameNode = "",
            frameNode = "mBuffFeet",
            picNode = "mBuffPic",
            startIndex = 1
}

function ABFightReportPage:onEnter(container)  
    self:registerPacket(container)
    
    NodeHelper:initScrollView(container, "mContent", 5);
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
    
    self:getPageInfo(container)
end



function ABFightReportPage:getPageInfo(container)
    --战报信息作缓存，如存在则不再请求
    if ABManager:getVariableByKeyAndIndex("FightReport",FightId)~=nil then
        self:refreshPage(container)
    else
        ABManager.CurrentFightReportId = FightId
        local AllianceBattle_pb = require("AllianceBattle_pb")
	    local msg = AllianceBattle_pb.HPAllianceTeamFight();
        msg.isLastSession = isLast
	    msg.unitId = FightId
	    common:sendPacket(opcodes.ALLIANCE_BATTLE_TEAM_FIGHT_INFO_C, msg);
    end
end


function ABFightReportPage:refreshPage(container)    
    local labelStr = {}
    local nodeVisible = {}
    local labelColor = {}
    
    local info = ABManager:getVariableByKeyAndIndex("FightReport",FightId)
    local baseInfo = isLast and ABManager:getLastAFUnitById(FightId) or ABManager:getAFUnitById(FightId)
    --保存轮空的战报
    inValidList = {}

    if info~=nil and baseInfo~=nil then
        labelStr.mGuildName1 = info.leftName
        labelStr.mGuildName2 = info.rightName
        
        local unitCount = 1
        local winCount = 0;
        local loseCount = 0
        nodeVisible.mRound2 = false
        nodeVisible.mRound3 = false
        --local size = #info.detailUnit
        for i=1,#info.detailUnit do
            --判断前三条是否存在轮空
            if info.leftTeamIndex~=info.rightTeamIndex and unitCount<=3 then
                if unitCount==3 then
                    table.insert(inValidList,3)
                elseif unitCount==2 then
                    table.insert(inValidList,2)
                    table.insert(inValidList,3)
                end
                unitCount = 4
            end
            --双方公会名称
            local unit = info.detailUnit[i]
            labelStr["mName"..(unitCount*2-1)] = common:getLanguageString("@ABTeamName"..unit.leftTeamIndex)
            labelStr["mName"..(unitCount*2)] = common:getLanguageString("@ABTeamName"..unit.rightTeamIndex)
            --判断胜利队伍
            if unit:HasField("winId") then
                if unit.winId<=3 then
                    labelColor["mName"..(unitCount*2-1)] = ABManager:getConfigDataByKey("WinColor")
                    labelColor["mName"..(unitCount*2)] = ABManager:getConfigDataByKey("LoseColor")

                    winCount = winCount + 1
                else
                    labelColor["mName"..(unitCount*2-1)] = ABManager:getConfigDataByKey("LoseColor")
                    labelColor["mName"..(unitCount*2)] = ABManager:getConfigDataByKey("WinColor")

                    loseCount = loseCount + 1
                end
            end
            unitCount = unitCount + 1
            --判断是否显示第四场和第五场战斗
            nodeVisible.mRound2 = unitCount>4
            nodeVisible.mRound3 = unitCount>5
        end
        --判断胜利公会
        if winCount>loseCount then
            nodeVisible.mWin1 = true
            nodeVisible.mDefeat2 = true
            nodeVisible.mWin2 = false
            nodeVisible.mDefeat1 = false            
        else
            nodeVisible.mWin2 = true
            nodeVisible.mDefeat1 = true
            nodeVisible.mWin1 = false
            nodeVisible.mDefeat2 = false             
        end     
        
        if baseInfo.winId == baseInfo.leftId then
            labelColor.mGuildName1 = ABManager:getConfigDataByKey("WinColor")
            labelColor.mGuildName2 = ABManager:getConfigDataByKey("LoseColor")
        else
            labelColor.mGuildName1 = ABManager:getConfigDataByKey("LoseColor")
            labelColor.mGuildName2 = ABManager:getConfigDataByKey("WinColor")
        end
    end
        

    
    NodeHelper:setColorForLabel(container,labelColor)
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)

  
    
    -- if baseInfo:HasField("leftBuffId") then
    --     if baseInfo.leftBuffId > 0 then
    --        guildBufferParams.startIndex = 1
    --        local bufferList = {}
    --        table.insert(bufferList ,GameConfig.ABGuildBufferInfo[baseInfo.leftBuffId] )
    --        NodeHelper:fillRewardItemWithParams(container, bufferList, 1,guildBufferParams)
    --     end
    -- end

    -- if baseInfo:HasField("rightBuffId") then
    --     if baseInfo.rightBuffId > 0 then
    --        guildBufferParams.startIndex = 2
    --        local bufferList = {}
    --        table.insert(bufferList ,GameConfig.ABGuildBufferInfo[baseInfo.rightBuffId] )
    --        NodeHelper:fillRewardItemWithParams(container, bufferList, 1,guildBufferParams)
    --     end
    -- end
    if baseInfo:HasField("leftBuffId") then
        NodeHelper:setStringForLabel(container,{ mBuffPic1 = baseInfo.leftBuffId })
    end
    if baseInfo:HasField("rightBuffId") then
        NodeHelper:setStringForLabel(container,{ mBuffPic2 = baseInfo.rightBuffId })
    end
    NodeHelper:setNodesVisible(container,{ mBuffNode1 = baseInfo:HasField("leftBuffId") and baseInfo.leftBuffId > 0 })
    NodeHelper:setNodesVisible(container,{ mBuffNode2 = baseInfo:HasField("rightBuffId") and baseInfo.rightBuffId > 0 })
end
--------------Click Event--------------------------------------
function ABFightReportPage:onShowBattle(container,id) 
    local info = ABManager:getVariableByKeyAndIndex("FightReport",FightId)
    if info==nil then return end
    --轮空提示文字
    for i=1,#inValidList do
        if id==inValidList[i] then
            MessageBoxPage:Msg_Box_Lan("@ABRoundEmpty");
            return
        end
    end
    --请求战斗数据
    ABManager:setBattleExtralParams(info,info.detailUnit[id])

    local AllianceBattle_pb = require("AllianceBattle_pb")
    local msg = AllianceBattle_pb.HPAllianceTeamFightReport();
    msg.battleId = info.detailUnit[id].id
    common:sendPacket(opcodes.ALLIANCE_BATTLE_FIGHT_REPORT_C, msg);
end

function ABFightReportPage:onLeftBuffer( container )
    local info = ABManager:getAFUnitById(FightId)
    --如果是上一届，获得上届战斗信息（一般不存在这种情况，防止服务器发送错误数据）
    if isLast then
        info = ABManager:getLastAFUnitById(FightId)
    end

    if info:HasField("leftBuffId") then
        if info.leftBuffId > 0 then
            GameUtil:showTip(container:getVarNode("mBuffNode1"),GameConfig.ABGuildBufferInfo[info.leftBuffId] )
        end
    end

end

function ABFightReportPage:onRightBuffer( container )
     local info = ABManager:getAFUnitById(FightId)
    --如果是上一届，获得上届战斗信息（一般不存在这种情况，防止服务器发送错误数据）
    if isLast then
        info = ABManager:getLastAFUnitById(FightId)
    end

    if info:HasField("rightBuffId") then
        if info.rightBuffId > 0 then
           GameUtil:showTip(container:getVarNode("mBuffNode2"),GameConfig.ABGuildBufferInfo[info.rightBuffId] )
        end
    end

end

--------------Call Function------------------------------------
function showABFightReportByFightId(id,islast) 
    isLast = islast or false
    FightId = id   
    PageManager.pushPage("ABFightReportPage")
end
