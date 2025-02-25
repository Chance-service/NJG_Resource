
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'QiXiQiYuan'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
require("SteriousShop");
require("Shop_pb");

local QiXiQiYuan = {}
local opcodes = {
	EXPEDITION_ARMORY_INFO_C 		= HP_pb.EXPEDITION_ARMORY_INFO_C,
	EXPEDITION_ARMORY_INFO_S		= HP_pb.EXPEDITION_ARMORY_INFO_S
}
local ExpeditionDataHelper = require("Activity.ExpeditionDataHelper")
local CurrentStageId = 1
function QiXiQiYuan.onFunction(eventName,container)
	if eventName == "onWishing" then
		PageManager.pushPage("ExpeditionContributePage")
	elseif eventName == "onStageReward" then
		PageManager.pushPage("ExpeditionMaterialsRewardPage")
	elseif eventName == "onRankReward" then
		PageManager.pushPage("ExpeditionRankPage")
	end
end

function QiXiQiYuan:onEnter(ParentContainer)
	self.container = ScriptContentBase:create("Act_TanabataPage1.ccbi")
	self.container:registerFunctionHandler(QiXiQiYuan.onFunction)
	self:registerPacket(ParentContainer)
	self:getActivityInfo()
	return self.container
end

function QiXiQiYuan:onExit()
	
end

function QiXiQiYuan:onExecute(ParentContainer)
	local timerName = ExpeditionDataHelper.getPageTimerName()
	if not TimeCalculator:getInstance():hasKey(timerName) then
	    if ExpeditionDataHelper.getActivityRemainTime() <= 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container, {mTanabataCD = endStr});
        end
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
	if remainTime + 1 > ExpeditionDataHelper.getActivityRemainTime() then
		return;
	end	
	
	ExpeditionDataHelper.setActivityRemainTime(remainTime)
	local timeStr = common:second2DateString(ExpeditionDataHelper.getActivityRemainTime(), false);
	
	if ExpeditionDataHelper.getActivityRemainTime() <= 0 then
	    timeStr = common:getLanguageString("@ActivityEnd");
    end
	NodeHelper:setStringForLabel(self.container, {mTanabataCD = timeStr});
end


function QiXiQiYuan:getActivityInfo()
    local msg = Activity_pb.HPExpeditionArmoryInfo();
    msg.version = 1
	common:sendPacket(opcodes.EXPEDITION_ARMORY_INFO_C, msg);
end
function QiXiQiYuan:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.EXPEDITION_ARMORY_INFO_S then
		ExpeditionDataHelper.onReceiveExpeditionInfo(msgBuff)
		CurrentStageId = ExpeditionDataHelper.getCurrentStageId()
		self:refreshPage()
		return;
	end
end
function QiXiQiYuan:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function QiXiQiYuan:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function QiXiQiYuan:onExit(ParentContainer)
	local timerName = ExpeditionDataHelper.getPageTimerName()
	TimeCalculator:getInstance():removeTimeCalcultor(timerName)
	self:removePacket(ParentContainer)
end

function QiXiQiYuan:refreshPage()
	local timerName = ExpeditionDataHelper.getPageTimerName()
    local remainTime = ExpeditionDataHelper.getActivityRemainTime()
    if remainTime > 0 and not TimeCalculator:getInstance():hasKey(timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(timerName, remainTime);
	end
	if CurrentStageId < 1 then
	    CurrentStageId = 1
	elseif CurrentStageId > ExpeditionDataHelper.getMaxStageId() then
	    CurrentStageId = ExpeditionDataHelper.getMaxStageId()
	end
	
	local mStageInfo = ExpeditionDataHelper.getStageInfoByStageId(CurrentStageId)
	if mStageInfo~=nil then
		local str = ""
		if mStageInfo.needExp==0 then
			str = tostring(mStageInfo.curExp).."/"..common:getLanguageString("@ExpeditionFinalStage")
	    else
            str = tostring(mStageInfo.curExp).."/"..tostring(mStageInfo.needExp)
        end
		NodeHelper:setStringForLabel(self.container, {mSeepNum = str})
	end
		
	NodeHelper:setStringForLabel(self.container,{mExpeditionNowSeep = common:getLanguageString("@ExpeditionNowSeep" .. CurrentStageId)})
	
	self.container:runAnimation("Anim" .. CurrentStageId)
end

return QiXiQiYuan
