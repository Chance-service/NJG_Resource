----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local UserInfo = require("PlayerInfo.UserInfo")
local option = {
	ccbiFile = "GVEAutoPopUp.ccbi",
	handlerMap = {
		onAutoNormal		= "onAutoNormal",
		onAutoHigh		= "onAutoHigh",
        onClose         = "onClose"
	},
    opcode = {
        WORLD_BOSS_AUTO_JOIN_S = HP_pb.WORLD_BOSS_AUTO_JOIN_S,
    }		
};

local thisPageName = "GVEAutoFightSelectPage";
local CommonPage = require("CommonPage");
local HP_pb = require("HP_pb");
local WorldBossManager = require("PVP.WorldBossManager");
local GVEAutoFightSelectPage = CommonPage.new("GVEAutoFightSelectPage", option);
local NodeHelper = require("NodeHelper");
local selectType = 0
----------------------------------------------------------------------------------
--GVEAutoFightSelectPage????????????
----------------------------------------------
function GVEAutoFightSelectPage.onEnter(container)
	GVEAutoFightSelectPage.registerPacket(container)
	GVEAutoFightSelectPage.refreshPage(container)

     local lb2Str = {
        mNormalLabel = common:getLanguageString("@GVEAutoNormalTxt"),
        mNormalLabelMessage = common:getLanguageString("@GVEAutoVIPLimitTxt"),

        mHighLabel = common:getLanguageString("@GVEAutoHighTxt"),

        mHighInfo = common:getLanguageString("@GVEAutoHighInfoTxt"),

        AutoBattleTxt_1 = common:getLanguageString("@GVEAutoBattleTxt"),
        AutoBattleTxt_2 = common:getLanguageString("@GVEAutoBattleTxt"),
    }
    NodeHelper:setStringForLabel(container, lb2Str);
end

function GVEAutoFightSelectPage.onExit(container)
	GVEAutoFightSelectPage.removePacket(container)
end
--TODO : ????  ---??????map
function GVEAutoFightSelectPage.refreshPage(container)
	selectType = WorldBossManager.autoJoinState or 0
   	NodeHelper:setNodesVisible(container, {mNormalChoice02 = WorldBossManager.autoJoinState == 1,
   											mHighChoice02 = WorldBossManager.autoJoinState == 2,
   											})
   	NodeHelper:setStringForLabel(container, {mHighCost = GameConfig.GVEAutoFightPrice})
end

function GVEAutoFightSelectPage.onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.WORLD_BOSS_AUTO_JOIN_S then
        local msg = WorldBoss_pb.HPBossAutoBattleReq();
		msg:ParseFromString(msgBuff);
		selectType = msg.bossAutoBattleType
		WorldBossManager.autoJoinState = selectType
	   	NodeHelper:setNodesVisible(container, {mNormalChoice02 = WorldBossManager.autoJoinState == 1,
	   											mHighChoice02 = WorldBossManager.autoJoinState == 2,
	   											})
    end
end

---TODO ?????? ????????
function GVEAutoFightSelectPage.onAutoNormal(container)
	if UserInfo.playerInfo.vipLevel >= GameConfig.GVEAutoFightVipLowLimit then
		if selectType == 1 then
			local WorldBoss_pb = require("WorldBoss_pb")
			local msg = WorldBoss_pb.HPBossAutoBattleReq();
			msg.bossAutoBattleType = 0 
			common:sendPacket(HP_pb.WORLD_BOSS_AUTO_JOIN_C, msg);		
		else
			local WorldBoss_pb = require("WorldBoss_pb")
			local msg = WorldBoss_pb.HPBossAutoBattleReq();
			msg.bossAutoBattleType = 1 
			common:sendPacket(HP_pb.WORLD_BOSS_AUTO_JOIN_C, msg);
	   	end
   	else
   		MessageBoxPage:Msg_Box_Lan("@VipLimit")
   	end
end
---TODO ?????? ????????
--TODO : ????  ---??????map
function GVEAutoFightSelectPage.onAutoHigh(container)
	if UserInfo.playerInfo.vipLevel >= GameConfig.GVEAutoFightVipHightLimit then
		if selectType == 2 then
			local WorldBoss_pb = require("WorldBoss_pb")
			local msg = WorldBoss_pb.HPBossAutoBattleReq();
			msg.bossAutoBattleType = 0 
			common:sendPacket(HP_pb.WORLD_BOSS_AUTO_JOIN_C, msg);
		else
        	local title = common:getLanguageString("@GVEAutoFightTips");
        	local msg = common:getLanguageString("@GVEAutoFightHightSure");			
	        PageManager.showConfirm(title, msg, function(isSure)
	            if isSure then
					local WorldBoss_pb = require("WorldBoss_pb")
					local msg = WorldBoss_pb.HPBossAutoBattleReq();
					msg.bossAutoBattleType = 2 
					common:sendPacket(HP_pb.WORLD_BOSS_AUTO_JOIN_C, msg);
	            end
	        end);
		end
   	else
   		MessageBoxPage:Msg_Box_Lan("@VipLimit")
   	end
end	
function GVEAutoFightSelectPage.onClose(container)
    PageManager.popPage(thisPageName)
end	
