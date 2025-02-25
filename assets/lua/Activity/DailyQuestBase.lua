
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Recharge_pb = require "Recharge_pb"
local thisPageName = "DailyQuestBase"
local UserInfo = require("PlayerInfo.UserInfo")
local Const_pb = require("Const_pb")
require("Activity.ActivityConfig")
require('MainScenePage')
local mScrollViewRef = {}
local mContainerRef = {}
local mSubNode = nil

local DailyQuestBase = {}

local option = {
	ccbiFile = "Act_DailyMission.ccbi",
	handlerMap = {
		onReturnButton 					= "onClose",
        onHelp      = "onHelp",
	},
    opcodes = {

	}
}
function DailyQuestBase:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
	mSubNode = container:getVarNode("mSubNode")	--绑定子页面ccb的节点
	mSubNode:removeAllChildren()
    mContainerRef = container;

    self:refreshPage(container)  
end
--标签页
---------------------------------------------------------------------------------
function DailyQuestBase:refreshPage(container)
	local activityCfg = ActivityConfig[Const_pb.DAILY_QUEST]
	if activityCfg then
		local page = activityCfg.page
		if page and page ~= "" and mSubNode then
			if DailyQuestBase.subPage then
				DailyQuestBase.subPage:onExit(container)
				DailyQuestBase.subPage = nil
			end
			mSubNode:removeAllChildren()
			DailyQuestBase.subPage = require(page)
			DailyQuestBase.sunCCB = DailyQuestBase.subPage:onEnter(container)
			mSubNode:addChild(DailyQuestBase.sunCCB)
			DailyQuestBase.sunCCB:setAnchorPoint(ccp(0,0))
			DailyQuestBase.sunCCB:release()
		end
	end
end

--接收服务器回包
function DailyQuestBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	if DailyQuestBase.subPage then
		DailyQuestBase.subPage:onReceivePacket(container)
	end
end
function DailyQuestBase:onExecute(container)
	if DailyQuestBase.subPage then
		DailyQuestBase.subPage:onExecute(container)
	end
end

function DailyQuestBase:onClose( container )
    PageManager.popPage(thisPageName)
end
function DailyQuestBase:onExit(container)
	if DailyQuestBase.subPage then
		DailyQuestBase.subPage:onExit(container)
		DailyQuestBase.subPage = nil
	end
end
function DailyQuestBase:onHelp(container)
	--PageManager.showHelp(GameConfig.HelpKey.HELP_QIXI)
end
local CommonPage = require('CommonPage')
DailyQuestBase= CommonPage.newSub(DailyQuestBase, thisPageName, option)
