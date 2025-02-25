--[[

--]]

local BasePage = require("BasePage")
local ABManager = require("Guild.ABManager")
local NodeHelper = require("NodeHelper");
local thisPageName = "ABBetPage"
local HP_pb = require("HP_pb")
require("ABTeamInfoPage")
local opcodes = {
    ALLIANCE_BATTLE_FIGHT_BET_C = HP_pb.ALLIANCE_BATTLE_FIGHT_BET_C,
    ALLIANCE_BATTLE_FIGHT_BET_S = HP_pb.ALLIANCE_BATTLE_FIGHT_BET_S,
    ALLIANCE_BATTLE_FIGHT_REPORT_C = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_C,
    ALLIANCE_BATTLE_FIGHT_REPORT_S = HP_pb.ALLIANCE_BATTLE_FIGHT_REPORT_S
}

local option = {
	ccbiFile = "GuildBetPopUp.ccbi",
	handlerMap = {
		onClose = "onClose",
		onBet = "onBet",
		onLeftGuild = "onLeftGuild",
		onRightGuild = "onRightGuild",
        onBUffFeet1 = "onLeftBuffer",
        onBUffFeet2 = "onRightBuffer",
	},
	DataHelper = ABManager
}
--奖励信息填充参数
local winRewardParams = {
	        mainNode = "mWinRewardNode",
	        countNode = "mWinNum",
            nameNode = "mWinName",
            frameNode = "mWinFrame",
            picNode = "mWinPic",
            startIndex = 1
}
--失败奖励信息填充参数
local loseRewardParams = {
	        mainNode = "mFailRewardNode",
	        countNode = "mFailNum",
            nameNode = "mFailName",
            frameNode = "mFailFrame",
            picNode = "mFailPic",
            startIndex = 1
}

--工会buffer节点参数
local guildBufferParams = {
	        mainNode = "mBuffNode",
	        countNode = "",
            nameNode = "",
            frameNode = "mBuffFeet",
            picNode = "mBuffPic",
            startIndex = 1
}

--预声明
local ABBetPage = nil
--拓展onFunction方法
function onFunctionEx(eventName,container)
    if string.sub(eventName,1,10) == "onWinFrame" then
        local betRewardCfg = ABManager:getConfigDataByKey("BetConfig")
        if betRewardCfg[FightRound]~=nil then  
            local index = tonumber(string.sub(eventName,-1))
            ABBetPage:showItemTip(container,betRewardCfg[FightRound].winReward,index,"mWinFrame")
        end
    elseif string.sub(eventName,1,11) == "onFailFrame" then
        local betRewardCfg = ABManager:getConfigDataByKey("BetConfig")
        if betRewardCfg[FightRound]~=nil then  
            local index = tonumber(string.sub(eventName,-1))
            ABBetPage:showItemTip(container,betRewardCfg[FightRound].failReward,index,"mFailFrame")
        end
    end
end
--页面创建
ABBetPage = BasePage:new(option,thisPageName,onFunctionEx,opcodes)
--显示的战斗id、轮数、选择的公会、是否是上一届
local FightId = nil
local FightRound = nil
local SelectAllanceId = nil
local isLast = false
--获得页面信息通用接口，onEnter之后调用
function ABBetPage:getPageInfo(container)
    self:refreshPage(container)
end


function ABBetPage:refreshPage(container)   
    
    local labelStr = {}
    local nodeVisible = {}
    local spriteImg = {}
    local menuItemPic = {}
    --获得战斗信息
    local info = ABManager:getAFUnitById(FightId)
    --如果是上一届，获得上届战斗信息（一般不存在这种情况，防止服务器发送错误数据）
    if isLast then
        info = ABManager:getLastAFUnitById(FightId)
    end

    if info~=nil then

        if SelectAllanceId==info.leftId then
            NodeHelper:setNodesVisible(container,{mLeftChoosePic = true,mRightChoosePic = false})
        elseif SelectAllanceId==info.rightId then
            NodeHelper:setNodesVisible(container,{mLeftChoosePic = false,mRightChoosePic = true})
        else
            NodeHelper:setNodesVisible(container,{mLeftChoosePic = false,mRightChoosePic = false}) 
        end  

        local betRewardCfg = ABManager:getConfigDataByKey("BetConfig")
    
        if betRewardCfg[FightRound]~=nil then    
            --填充奖励信息
            NodeHelper:fillRewardItemWithParams(container, betRewardCfg[FightRound].winReward, 4,winRewardParams)
            NodeHelper:fillRewardItemWithParams(container, betRewardCfg[FightRound].failReward, 4,loseRewardParams)
            --填充押注所需金币或钻石
            if betRewardCfg[FightRound].costGold~=0 then
                labelStr.mBetCost = common:getLanguageString("@ABBetTex2",betRewardCfg[FightRound].costGold)
            else
                labelStr.mBetCost = common:getLanguageString("@ABBetTex3",betRewardCfg[FightRound].costCoins)
            end
            NodeHelper:setLabelOneByOne(container, "mBetCostTitle", "mBetCost")
        end

        --设置左右公会名称，注释信息为为公会头像优化预留接口
        labelStr.mLeftName = info.leftName
        --menuItemPic.mLeftBtn = ABManager:getConfigDataByKey("AlliancePic").left
        labelStr.mRightName = info.rightName
        --menuItemPic.mRightBtn = ABManager:getConfigDataByKey("AlliancePic").right

        --判断是否已经押注
        if ABManager.hasBet then
            if info:HasField("investedId") then
                SelectAllanceId = info.investedId
                --默认选择已押注公会
                if SelectAllanceId==info.leftId then
                    NodeHelper:setNodesVisible(container,{mLeftChoosePic = true,mRightChoosePic = false})
                else
                    NodeHelper:setNodesVisible(container,{mLeftChoosePic = false,mRightChoosePic = true})
                end
            else
                --押注的不是该场，不显示选择图标
                NodeHelper:setNodesVisible(container,{mLeftChoosePic = false,mRightChoosePic = false})
            end
            --押注按钮文本和状态设置
            labelStr.mBetLabel = common:getLanguageString("@ABHasBet")
            NodeHelper:setMenuItemEnabled(container,"mBetBtn",false)
        else
            NodeHelper:setMenuItemEnabled(container,"mBetBtn",true)
            labelStr.mBetLabel = common:getLanguageString("@ABBet")
        end
    end
    NodeHelper:setNormalImages(container,menuItemPic)
    NodeHelper:setSpriteImage(container, spriteImg);
    NodeHelper:setStringForLabel(container,labelStr)
    NodeHelper:setNodesVisible(container,nodeVisible)

   
    
    -- if info:HasField("leftBuffId") then
    --     if info.leftBuffId > 0 then
    --        guildBufferParams.startIndex = 1
    --        local bufferList = {}
    --        table.insert(bufferList ,GameConfig.ABGuildBufferInfo[info.leftBuffId] )
    --        NodeHelper:fillRewardItemWithParams(container, bufferList, 1,guildBufferParams)
    --     end
    -- end

    -- if info:HasField("rightBuffId") then
    --     if info.rightBuffId > 0 then
    --        guildBufferParams.startIndex = 2
    --        local bufferList = {}
    --        table.insert(bufferList ,GameConfig.ABGuildBufferInfo[info.rightBuffId] )
    --        NodeHelper:fillRewardItemWithParams(container, bufferList, 1,guildBufferParams)
    --     end
    -- end

    NodeHelper:setNodesVisible(container,{ mBuffNode1 = info:HasField("leftBuffId") and info.leftBuffId > 0 })
    NodeHelper:setNodesVisible(container,{ mBuffNode2 = info:HasField("rightBuffId") and info.rightBuffId > 0 })

end

--------------Click Event--------------------------------------
function ABBetPage:onBet(container)
    PageManager.showConfirm(common:getLanguageString("@InvestmentTipTitle"),common:getLanguageString("@InvestmentTip"), 
        function(isSure)
            if isSure then
		        local AllianceBattle_pb = require("AllianceBattle_pb")
                local msg = AllianceBattle_pb.HPInvest();
                msg.versusId = FightId
                msg.allianceId = SelectAllanceId
                common:sendPacket(opcodes.ALLIANCE_BATTLE_FIGHT_BET_C, msg);
            end
	    end
    );
end

function ABBetPage:onLeftGuild(container)
    local info = ABManager:getAFUnitById(FightId)

    if isLast then
        info = ABManager:getLastAFUnitById(FightId)
    end

    if SelectAllanceId == info.leftId or ABManager.hasBet then
        setABTeamInfoCtrlBtn(true)
        PageManager.viewAllianceTeamInfo(info.leftId)
        return 
    end

    SelectAllanceId = info.leftId
    NodeHelper:setNodesVisible(container,{mLeftChoosePic = true,mRightChoosePic = false})
end

function ABBetPage:onRightGuild(container)
    local info = ABManager:getAFUnitById(FightId)

    if isLast then
        info = ABManager:getLastAFUnitById(FightId)
    end

    if SelectAllanceId == info.rightId or ABManager.hasBet then
        setABTeamInfoCtrlBtn(true)
        PageManager.viewAllianceTeamInfo(info.rightId)
        return 
    end

    SelectAllanceId = info.rightId
    NodeHelper:setNodesVisible(container,{mLeftChoosePic = false,mRightChoosePic = true})
end

function ABBetPage:showItemTip(container,cfg,rewardIndex,nodeNmae)
	if cfg~=nil and cfg[rewardIndex] ~= nil then
	    GameUtil:showTip(container:getVarNode(nodeNmae .. rewardIndex), common:table_merge(cfg[rewardIndex],{buyTip=true,hideBuyNum=true}));
	end
end

function ABBetPage:onLeftBuffer( container )
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

function ABBetPage:onRightBuffer( container )
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
function showBetPageByFightId(id,round,islast)
    FightId = id   
    FightRound = round
    isLast = islast or false
    if isLast==false then
        if ABManager:getAFUnitById(FightId)~=nil then
            SelectAllanceId = ABManager:getAFUnitById(FightId).leftId
        end
    else
        if ABManager:getLastAFUnitById(FightId)~=nil then
            SelectAllanceId = ABManager:getLastAFUnitById(FightId).leftId
        end
    end
     
    PageManager.pushPage("ABBetPage")
end
