----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local NodeHelper = require("NodeHelper")

local ActivityBasePage = require("Activity.ActivityBasePage")

local thisPageName = "CumulativeLoginPage"
local opcodes = {
	ACC_LOGIN_INFO_C = HP_pb.ACC_LOGIN_INFO_C;
	ACC_LOGIN_INFO_S = HP_pb.ACC_LOGIN_INFO_S;
	ACC_LOGIN_AWARDS_C = HP_pb.ACC_LOGIN_AWARDS_C;
	ACC_LOGIN_AWARDS_S = HP_pb.ACC_LOGIN_AWARDS_S;
};
local option = {
	ccbiFile = "Act_TimeLimitCumulativeLandContent.ccbi",
	timerName = "Activity_CumulativeLogin",
};

----------------- local data -----------------
local CumulativeLoginPage = ActivityBasePage:new(option,thisPageName,opcodes)
CumulativeLoginPage.timerLabel = "mActivityDaysNum"

local thisActivityInfo = {CumulativeLoginDays = 0, RemainTime = 0, gotAwardCfgId = {}}
-----------------------------------------------
--------------------------Content--------------
local CumulativeLoginContent = {
	ccbiFile = "Act_TimeLimitCumulativeLandListContent.ccbi",
}

function CumulativeLoginContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function CumulativeLoginContent:onRefreshContent(ccbRoot)
    local rewardInfo = thisActivityInfo.rewardCfg[self.id]
    local container = ccbRoot:getCCBFileNode()	
	if rewardInfo~=nil then
	    local nodeVisible = {}
	    local labelString = {}
        labelString.mContinuousLandingReward = common:getLanguageString("@CumulativeLandingReward",tostring(rewardInfo.day))
        
        if rewardInfo.day > thisActivityInfo.CumulativeLoginDays then
            NodeHelper:setMenuItemEnabled(container,"mRewardBtn",false)
            labelString.mReceiveText = common:getLanguageString("@SevenDayQuestDay2Desc")
            NodeHelper:setNodeIsGray(container , { mReceiveText = true })
        else
        	if thisActivityInfo.gotAwardCfgId[rewardInfo.id] then
        	    NodeHelper:setMenuItemEnabled(container,"mRewardBtn",false)
        		labelString.mReceiveText = common:getLanguageString("@ReceiveDone")
                NodeHelper:setNodeIsGray(container , { mReceiveText = true })
        	else
        		NodeHelper:setMenuItemEnabled(container,"mRewardBtn",true)
        		labelString.mReceiveText = common:getLanguageString("@Receive")
                NodeHelper:setNodeIsGray(container , { mReceiveText = false })
        	end
        end
	    
	    local rewardItems = {}
	    for _, item in ipairs(common:split(rewardInfo.reward, ",")) do
	        local _type, _id, _count = unpack(common:split(item, "_"));
	        table.insert(rewardItems, {
	            type    = tonumber(_type),
	            itemId  = tonumber(_id),
	            count   = tonumber(_count),
	        });
	    end
	    NodeHelper:fillRewardItem(container,rewardItems,4)
        NodeHelper:setStringForLabel(container, labelString)
	end
end


function CumulativeLoginContent:onFrame1( container ) 
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index] 
    self:onShowItemInfo(container, itemInfo, 1)
end

function CumulativeLoginContent:onFrame2( container )
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index] 
    self:onShowItemInfo(container, itemInfo, 2)
end

function CumulativeLoginContent:onFrame3( container )
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index] 
    self:onShowItemInfo(container, itemInfo, 3)
end

function CumulativeLoginContent:onFrame4( container )
    local index = self.id
    local itemInfo = thisActivityInfo.rewardCfg[index] 
    self:onShowItemInfo(container, itemInfo, 4)
end

function CumulativeLoginContent:onShowItemInfo( container , itemInfo, rewardIndex )
    local rewardItems = {}
    if itemInfo.reward ~= nil then
        for _, item in ipairs(common:split(itemInfo.reward, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type    = tonumber(_type),
                itemId  = tonumber(_id),
                count   = tonumber(_count)
            });
        end
    end
    
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), rewardItems[rewardIndex])
    
end

function CumulativeLoginContent:onRewardBtn(container)
    local index = self.id;
    if thisActivityInfo.gotAwardCfgId[index] then
        MessageBoxPage:Msg_Box_Lan("@VipWelfareAlreadyReceive");
        return 
    end
	local msg = Activity_pb.HPAccLoginAwards();
	msg.rewwardDay = index;
	common:sendPacket(opcodes.ACC_LOGIN_AWARDS_C, msg);
end
-----------------------end Content------------

---------------------------------------------------------------

function CumulativeLoginPage:getPageInfo(container)
	thisActivityInfo.rewardCfg = ConfigManager.getCumulativeLogin()
    local msg = Activity_pb.HPAccLoginInfo();
	common:sendPacket(opcodes.ACC_LOGIN_INFO_C, msg);
	self:rebuildAllItem(container)
	-- self:refreshPage(container)
end

function CumulativeLoginPage:refreshPage(container)
	
	NodeHelper:setStringForLabel(container,{mLoginDaysNum = thisActivityInfo.CumulativeLoginDays})	
	if thisActivityInfo.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(option.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(option.timerName, thisActivityInfo.RemainTime);
	end	
	container.mScrollView:refreshAllCell()
	-- self:setCurDayReward()
end


function CumulativeLoginPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.ACC_LOGIN_INFO_S then
		local msg = Activity_pb.HPAccLoginInfoRet();
		msg:ParseFromString(msgBuff);
		
		thisActivityInfo.CumulativeLoginDays = msg.loginDays
		thisActivityInfo.RemainTime = msg.leftTime
		thisActivityInfo.gotAwardCfgId = {}
		for i = 1, #msg.gotAwardCfgId do
			thisActivityInfo.gotAwardCfgId[msg.gotAwardCfgId[i]] = true
		end		
		self:refreshPage(self.container)
    elseif opcode == HP_pb.ACC_LOGIN_AWARDS_S then
		local msg = Activity_pb.HPAccLoginAwardsRet();
		msg:ParseFromString(msgBuff);
		
		thisActivityInfo.RemainTime = msg.leftTime
		for i = 1, #msg.gotAwardCfgId do
			thisActivityInfo.gotAwardCfgId[msg.gotAwardCfgId[i]] = true
		end			
		self.container.mScrollView:refreshAllCell()
		self:clearNotice()
	end
end

function CumulativeLoginPage:clearNotice( )
    --红点消除
    local hasNotice = false

    for i,v in ipairs(thisActivityInfo.rewardCfg) do
    	if v.day <= thisActivityInfo.CumulativeLoginDays and not thisActivityInfo.gotAwardCfgId[i] then
    		hasNotice = true
    		break
    	end
    end
    if not hasNotice then
        ActivityInfo.changeActivityNotice(Const_pb.ACCUMULATIVE_LOGIN);
    end
end

function CumulativeLoginPage:onTimer(container)
	local timerName = option.timerName;

	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local RemainTime = TimeCalculator:getInstance():getTimeLeft(timerName);

	if RemainTime + 1 > thisActivityInfo.RemainTime then
		return;
	end

	thisActivityInfo.RemainTime = math.max(RemainTime, 0);
	local timeStr = common:second2DateString(thisActivityInfo.RemainTime, false);
	NodeHelper:setStringForLabel(container, {mActivityDaysNum = timeStr});
end

function CumulativeLoginPage:rebuildAllItem(container)

    container.mScrollView:removeAllCell()
    for i,v in ipairs(thisActivityInfo.rewardCfg) do
        local titleCell = CCBFileCell:create()
        local panel = CumulativeLoginContent:new({id = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(CumulativeLoginContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()

end

function CumulativeLoginPage:setCurDayReward( container )
	local totalOffset = container.mScrollView:getContentOffset()
	local currentDay = self.DataHelper:getVariableByKey("mReceiveDays")
	if currentDay == 0 or currentDay == 1 then
	    return
	end
	
	local curY = totalOffset.y + container.mScrollView:getContentSize().height * ( currentDay - 1) / (#self.DataHelper:getConfigDataByKey("DailyRewardItem"))
	
	if curY > 0  then
		curY = 0
	end
	
	local curOffset = CCPointMake( totalOffset.x , curY ) 
	NodeHelper:setScrollViewStartOffset(container,curOffset)
end


return CumulativeLoginPage

----------------click event------------------------	

-------------------------------------------------------------------------
