--region CSManager.lua

local CSManager = {
    PacketHandler = { },
    CacheHandler = { },
    Tools = {},
    -- packet cache
    WarStateCache =
    {
        playerIdentify = nil,
        state = nil,
        closeState = nil,
        openState = nil,
        serverNames = nil
    },
    WorshipStateCache =
    {
        primaryState = nil,
        middleState = nil,
        advancedState = nil
    },
    WorshipRewardCache =
    {
        worshipType = nil,
        worshipSucc = nil,
        worshipState = nil,
        worshipSilver = nil
    },
    SignUpCache =
    {
        playerIdentify = nil,
        signUp = nil,
        signUpState = nil
    },
    RuleCache =
    {
        serverNames = nil
    },
    --protobuf container
    PROTOBUF_CONTAINER = {
	    OPCODE_CS_BATTLESTATE_C = HP_pb.OPCODE_CS_BATTLESTATE_C,--cross server war state
	    OPCODE_CS_BATTLESTATE_S = HP_pb.OPCODE_CS_BATTLESTATE_S,
	    OPCODE_CS_WORSHIPSTATE_C = HP_pb.OPCODE_CS_WORSHIPSTATE_C,--worship state
	    OPCODE_CS_WORSHIPSTATE_S = HP_pb.OPCODE_CS_WORSHIPSTATE_S,
	    OPCODE_CS_WORSHIPGET_C = HP_pb.OPCODE_CS_WORSHIPGET_C,--worship ok
	    OPCODE_CS_WORSHIPGET_S = HP_pb.OPCODE_CS_WORSHIPGET_S,
	    OPCODE_CS_SIGNUP_C = HP_pb.OPCODE_CS_SIGNUP_C,--sign up 
	    OPCODE_CS_SIGNUP_S = HP_pb.OPCODE_CS_SIGNUP_S,
	    OPCODE_CS_REFRESH_BATTLEARRAY_C = HP_pb.OPCODE_CS_REFRESH_BATTLEARRAY_C,--update the battle array info
	    OPCODE_CS_REFRESH_BATTLEARRAY_S = HP_pb.OPCODE_CS_REFRESH_BATTLEARRAY_S,
	    OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	    OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S,
	    OPCODE_CS_Rule_C = HP_pb.OPCODE_CS_RULE_C,
	    OPCODE_CS_Rule_S = HP_pb.OPCODE_CS_RULE_S
    },
    PAGE_STATE = {
	    WAR_OPEN_STATE = 1,
	    WAR_CLOSE_STATE = 2,
	    WORSHIP_STATE = 3
	},
    WORSHIP_LEVEL = {
	    PRIMARY_LEVEL = 1,
	    MIDDLE_LEVEL = 2,
	    ADVANCED_LEVEL = 3
    }
}

local CS_Battle_Stage = {
	NOTSTART	 = 0,	--Î´¿ªÆô
	SIGNUP 		 = 2,	--±¨Ãû½×¶Î
	SIGNUP_END	 = 3,	--±¨Ãû½áÊø
	LS_KNOCKOUT  = 4, 	--±¾·þÌÔÌ­Èü½×¶Î
	LS_16TO8	 = 6, 	--±¾·þ16½ø8½×¶Î
	LS_8TO4		 = 8, 	--±¾·þ8½ø4½×¶Î
	LS_4TO2		 = 10, 	--±¾·þ4½ø2½×¶Î
	LS_2TO1		 = 12, 	--±¾·þ2½ø1½×¶Î
	CS_KNOCKOUT	 = 14, 	--¿ç·þÌÔÌ­Èü½×¶Î
	CS_16TO8	 = 16, 	--¿ç·þ16½ø8½×¶Î
	CS_8TO4		 = 18, 	--¿ç·þ8½ø4½×¶Î
	CS_4TO2		 = 20,	--¿ç·þ4½ø2½×¶Î
	CS_2TO1		 = 22, 	--¿ç·þ2½ø1½×¶Î
	FINAL_REVIEW = 24, 	--¾öÈü»Ø¹Ë½×¶Î
	FINISHED	 = 26 	--±ÈÈü½áÊø
}

local CsBattle_pb = require("CsBattle_pb")
local CSTools = require("CSTools")
local UserInfo = require("PlayerInfo.UserInfo")


--begin Packet handler

--¿ç·þ×´Ì¬ÇëÇó
function CSManager.PacketHandler.requireWarState( container )
    common:sendEmptyPacket( CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLESTATE_C , true )
end

function CSManager.PacketHandler.requireWorshipState( container )
	local msg = CsBattle_pb.OPCSBattleRequestWorship();
	msg.battleId = CSManager.WarStateCache.closeState.battleId;
	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPSTATE_C,pb_data,#pb_data,true);
end

--±¨Ãû
function CSManager.PacketHandler.requireWorshipReward( container, level )
	local msg = CsBattle_pb.OPCSBattleWorship();
	msg.worshipType = level;
	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPGET_C,pb_data,#pb_data,false);
end

function CSManager.PacketHandler.requireRefreshBattleArray( boo )
    if not boo then return end
	local msg = CsBattle_pb.OPCSBattleUpdateBattleArray();
	msg.playerIdentify = CSManager.WarStateCache.playerIdentify;

	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_C,pb_data,#pb_data,true);
end

--±¨Ãû
function CSManager.PacketHandler.requireSignUp( container )
   
    UserInfo.sync()
	local currentLevel = UserInfo.roleInfo.level  --ServerDateManager:getInstance():getUserBasicInfo().level;
    if CSManager.WarStateCache.closeState.battleId == 0 then
        return ;
    end
	local limitLevel = CSTools.getTimeItem(CSManager.WarStateCache.closeState.battleId).signUpLimitLevel;

	if currentLevel >= limitLevel then
		local msg = CsBattle_pb.OPCSBattleSignup();
		msg.playerIdentify = CSManager.WarStateCache.playerIdentify;
		msg.battleId = CSManager.WarStateCache.closeState.battleId;

		local pb_data = msg:SerializeToString();
		PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_SIGNUP_C,pb_data,#pb_data,true);
        --common:sendEmptyPacket( CSManager.PROTOBUF_CONTAINER.OPCODE_CS_SIGNUP_C , true )
	else
		local levelStr = Language:getInstance():getString("@CSSignUpLevelLimit")  
		levelStr=string.gsub(levelStr,"#v1#",limitLevel)
		MessageBoxPage:Msg_Box(levelStr);
	end
end

--¿ç·þ¹æÔòÇëÇó
function CSManager.PacketHandler.requireRuleInfo( container )
	local msg = CsBattle_pb.OPCSBattleRequestRule();
	local battleId = nil;
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		msg.battleId = CSManager.WarStateCache.closeState.battleId;
    else
    if CSManager.WarStateCache.openState then
        msg.battleId = 0;
    else
        msg.battleId = CSManager.WarStateCache.openState.battleId;
    end

	end

	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_Rule_C,pb_data,#pb_data,true);
end

--end Packet handler


-- begin Cache Handler
function CSManager.CacheHandler.cacheWarStateMSG( msg )
	CSManager.WarStateCache.state = msg.state;
	CSManager.WarStateCache.serverNames = msg.serverNames;
	CSManager.WarStateCache.playerIdentify = msg.playerIdentify;

	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
		CSManager.WarStateCache.openState = {};
		CSManager.WarStateCache.openState.battleId = msg.openState.battleId;
		CSManager.WarStateCache.openState.stage = msg.openState.stage;
        if msg.openState:HasField("lsGoingStage") then
            if msg.openState.lsGoingStage == nil then
                CSManager.WarStateCache.openState.lsGoingStage = 0
            else
                CSManager.WarStateCache.openState.lsGoingStage = tonumber(msg.openState.lsGoingStage);
            end
        end
        if msg.openState:HasField("lsGoingGroup") then
            if msg.openState.lsGoingGroup == nil then
                CSManager.WarStateCache.openState.lsGoingGroup = 0;
            else
                CSManager.WarStateCache.openState.lsGoingGroup = tonumber(msg.openState.lsGoingGroup);
            end

        end
        if msg.openState:HasField("csGoingStage") then
            if msg.openState.csGoingStage == nil then
                CSManager.WarStateCache.openState.csGoingStage = 0;
            else
                CSManager.WarStateCache.openState.csGoingStage = tonumber(msg.openState.csGoingStage);
            end

        end
        if msg.openState:HasField("csGoingGroup") then
            if msg.openState.csGoingGroup == nil then
                CSManager.WarStateCache.openState.csGoingGroup = 0;
            else
                CSManager.WarStateCache.openState.csGoingGroup = tonumber(msg.openState.csGoingGroup);
            end
        end
	elseif CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		CSManager.WarStateCache.closeState = {};
		CSManager.WarStateCache.closeState.battleId = tonumber(msg.closeState.battleId);
		CSManager.WarStateCache.closeState.latestBattleId = tonumber(msg.closeState.latestBattleId);
		CSManager.WarStateCache.closeState.signUp = msg.closeState.signUp;
		CSManager.WarStateCache.closeState.signUpCount = tonumber(msg.closeState.signUpCount);

		if msg.closeState:HasField("winTop1Player") then
			CSManager.WarStateCache.closeState.winTop1Player = {};
			CSManager.WarStateCache.closeState.winTop1Player.playerIdentify = msg.closeState.winTop1Player.playerIdentify;
			CSManager.WarStateCache.closeState.winTop1Player.serverName = msg.closeState.winTop1Player.serverName;
			CSManager.WarStateCache.closeState.winTop1Player.playerLevel = tonumber(msg.closeState.winTop1Player.playerLevel);
			CSManager.WarStateCache.closeState.winTop1Player.playerName = msg.closeState.winTop1Player.playerName;
			CSManager.WarStateCache.closeState.winTop1Player.playerItemId =tonumber(msg.closeState.winTop1Player.playerItemId);
		end

		if msg.closeState:HasField("winTop2Player") then
			CSManager.WarStateCache.closeState.winTop2Player = {};
			CSManager.WarStateCache.closeState.winTop2Player.playerIdentify = msg.closeState.winTop2Player.playerIdentify;
			CSManager.WarStateCache.closeState.winTop2Player.serverName = msg.closeState.winTop2Player.serverName;
			CSManager.WarStateCache.closeState.winTop2Player.playerLevel = tonumber(msg.closeState.winTop2Player.playerLevel);
			CSManager.WarStateCache.closeState.winTop2Player.playerName = msg.closeState.winTop2Player.playerName;
			CSManager.WarStateCache.closeState.winTop2Player.playerItemId = tonumber(msg.closeState.winTop2Player.playerItemId);
		end


		if msg.closeState:HasField("loseTop1Player") then
			CSManager.WarStateCache.closeState.loseTop1Player = {};
			CSManager.WarStateCache.closeState.loseTop1Player.playerIdentify = msg.closeState.loseTop1Player.playerIdentify;
			CSManager.WarStateCache.closeState.loseTop1Player.serverName = msg.closeState.loseTop1Player.serverName;
			CSManager.WarStateCache.closeState.loseTop1Player.playerLevel = tonumber(msg.closeState.loseTop1Player.playerLevel);
			CSManager.WarStateCache.closeState.loseTop1Player.playerName = msg.closeState.loseTop1Player.playerName;
			CSManager.WarStateCache.closeState.loseTop1Player.playerItemId = tonumber(msg.closeState.loseTop1Player.playerItemId);
		end

	end

end

function CSManager.CacheHandler.cacheWorshipStateMSG( msg )
	CSManager.WorshipStateCache.primaryState = msg.primaryState;
	CSManager.WorshipStateCache.middleState = msg.middleState;
	CSManager.WorshipStateCache.advancedState = msg.advancedState;
end

function CSManager.CacheHandler.cacheWorshipRewardMSG( msg )
	CSManager.WorshipRewardCache.worshipType = msg.worshipType;
	CSManager.WorshipRewardCache.worshipSucc = msg.worshipSucc;
	CSManager.WorshipRewardCache.worshipState = msg.worshipState;
	--CSManager.WorshipRewardCache.worshipSilver = msg.worshipSilver;
end

function CSManager.CacheHandler.cacheSignUpMSG( msg )
	CSManager.SignUpCache.playerIdentify = msg.playerIdentify;
	CSManager.SignUpCache.signUp = msg.signUp;
	CSManager.SignUpCache.signUpState = msg.signUpState;
	CSManager.WarStateCache.closeState.signUpCount = msg.signUpCount;
end

function CSManager.CacheHandler.cacheRuleMSG( msg )
    
    local serverNames = msg.serverNames;
    if Golb_Platform_Info.is_r2_platform then--r2 美观优化显示
        serverNames = string.sub(serverNames,1,#serverNames-1)
        serverNames = string.gsub(serverNames, ",", ", ")
    end
    
	CSManager.RuleCache.serverNames = serverNames;

end
-- end Cache Handler



-- begin. tools functions
function CSManager.Tools.checkValue( obj )
	return obj ~= nil;
end

function CSManager.Tools.numAGreaterThanNumB( numA, numB )
	if not CSManager.Tools.checkValue(numA) or not CSManager.Tools.checkValue(numB) then
		return false;
	end

	return tonumber(numA) > tonumber(numB);
end

function CSManager.Tools.numAGreaterOrEqualsToNumB( numA, numB )
	if not CSManager.Tools.checkValue(numA) or not CSManager.Tools.checkValue(numB) then
		return false;
	end

	return tonumber(numA) >= tonumber(numB);
end

function CSManager.Tools.numALessThanNumB( numA, numB )
	if not CSManager.Tools.checkValue(numA) or not CSManager.Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) < tonumber(numB);
end

function CSManager.Tools.numALessOrEqualsToNumB( numA, numB )
	if not CSManager.Tools.checkValue(numA) or not CSManager.Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) <= tonumber(numB);
end

function CSManager.Tools.numAEqualsToNumB( numA, numB )
    
	if not CSManager.Tools.checkValue(numA) or not CSManager.Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) == tonumber(numB);
end

function CSManager.Tools.getCSWorshipItemByWorshipId( worshipId )
    local WorshipCfg = ConfigManager.getWorshipCfg()
    assert(WorshipCfg[worshipId],"WorshipCfg is nil the id is "..tostring(worshipId))
	return (WorshipCfg[worshipId]);
end

function CSManager.Tools.checkWorshipMoneyEnough(state)
    --todo 
	if state == CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL then
        UserInfo.sync()
		--1.primary_level
		local primaryWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL);
		--cost
		local worshipCost = primaryWorshipItem.worshipCost;
		local worshipCostItem = ConfigManager.parseItemOnlyWithUnderline( worshipCost )--Split(worshipCost, "_", 3);
		local costItem = ResManagerForLua:getResInfoByTypeAndId(worshipCostItem.type,worshipCostItem.itemId,worshipCostItem.count);


		if costItem.itemId==USER_PROPERTY_SILVER_COINS then
			if UserInfo.playerInfo.coin >= costItem.count then
				return true;
			end
		end

		if costItem.itemId==USER_PROPERTY_GOLD_COINS then
			if UserInfo.playerInfo.gold >=  tonumber(costItem.count) then
				return true;
			end
		end
	end

	if state == CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL then
		--2.middle_level
		local middleWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL);
		--cost
		local worshipCostMiddle = middleWorshipItem.worshipCost;
		local middleWoshipCostItem = ConfigManager.parseItemOnlyWithUnderline( worshipCostMiddle )--Split(worshipCostMiddle, "_", 3);
		local middleCostItem = ResManagerForLua:getResInfoByTypeAndId(middleWoshipCostItem.type,middleWoshipCostItem.itemId,middleWoshipCostItem.count);

		if middleCostItem.itemId==USER_PROPERTY_SILVER_COINS then
			if UserInfo.playerInfo.coin >= tonumber(middleCostItem.count) then
				return true;
			end
		end

		if middleCostItem.itemId==USER_PROPERTY_GOLD_COINS then
			if UserInfo.playerInfo.gold >= tonumber(middleCostItem.count) then
				return true;
			end
		end
	end

	--3.advanced_level
	if state == CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL then
		local advancedWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL);
		--cost
		local worshipCostAdvanced = advancedWorshipItem.worshipCost;
		local advancedWoshipCostItem = ConfigManager.parseItemOnlyWithUnderline(worshipCostAdvanced)--Split(worshipCostAdvanced, "_", 3);
		local advancedCostItem = ResManagerForLua:getResInfoByTypeAndId(advancedWoshipCostItem.type,advancedWoshipCostItem.itemId,advancedWoshipCostItem.count);

		if advancedCostItem.itemId==USER_PROPERTY_SILVER_COINS then
			if UserInfo.playerInfo.coin >= tonumber(advancedCostItem.count) then
				return true;
			end
		end

		if advancedCostItem.itemId==USER_PROPERTY_GOLD_COINS then
			if  UserInfo.playerInfo.gold >= tonumber(advancedCostItem.count) then
				return true;
			end
		end
	end

	return false;

end

function CSManager.Tools.getPlayIdByPlayerIdentify(identify)
	local playId = Split(identify, "*", 3);
	local index = table.maxn(playId);
	return playId[index];
end


--end Tools

function CSManager.refreshCrossServerWarRedPoint( container )
    local CSTools = require("PVP.CSTools")
    local CSTimeListCfg = ConfigManager.getCSTimeListCfg()
    local hasRedPoint = false
    for i = 1,#CSTimeListCfg,1 do
        local timeItem = CSTimeListCfg[i]
        if CSTools.isPeriodStart( timeItem, CS_Battle_Stage.SIGNUP ) and not CSTools.isPeriodStart( timeItem, CS_Battle_Stage.FINAL_REVIEW ) then
            hasRedPoint = true
        end
    end

    container:getVarNode("mCrossServerWarPoint"):setVisible( hasRedPoint and UserInfo.stateInfo.isCSOPen and (UserInfo.roleInfo.level >= 50) )

end

function CSManager.refreshCrossServerWarMainRedPoint( container )
    local CSTools = require("PVP.CSTools")
    local CSTimeListCfg = ConfigManager.getCSTimeListCfg()
    local hasRedPoint = false
    for i = 1,#CSTimeListCfg,1 do
        local timeItem = CSTimeListCfg[i]
        if CSTools.isPeriodStart( timeItem, CS_Battle_Stage.SIGNUP ) and not CSTools.isPeriodStart( timeItem, CS_Battle_Stage.FINAL_REVIEW ) then
            hasRedPoint = true
        end
    end
	
    container:getVarSprite("mCrossServerWarPoint"):setVisible( hasRedPoint and  UserInfo.stateInfo.isCSOPen and (UserInfo.roleInfo.level >= 50) )
	if hasRedPoint and  UserInfo.stateInfo.isCSOPen then
		container:getVarSprite("mManyPeopleArenaPoint"):setVisible( false )
	end
    
end

function CSManager.getCurrentStageString()
    if CSManager.WarStateCache.openState.battleId > 0 then
        local currentStage = CSTools.getCurrentStage(CSManager.WarStateCache.openState.battleId)
        if currentStage < 4 then return "" end
        local goIntoStr = ""
        local group = ""
        local goingGroup
        local stage
        if CSManager.WarStateCache.openState.csGoingStage ~= nil and CSTools.isLCBattleEnd( CSManager.WarStateCache.openState.battleId ) then
            if currentStage > tonumber(CSManager.WarStateCache.openState.csGoingStage) then
                goIntoStr = common:getLanguageString("@CSStop")
            else
                goIntoStr = common:getLanguageString("@CSPromotion")
            end
            goingGroup = CSManager.WarStateCache.openState.csGoingGroup
            stage = CSManager.WarStateCache.openState.csGoingStage
        else
            if CSManager.WarStateCache.openState.lsGoingStage == nil then
                CSManager.WarStateCache.openState.lsGoingStage = 0
            end
            if currentStage > tonumber(CSManager.WarStateCache.openState.lsGoingStage) then
                goIntoStr = common:getLanguageString("@CSStop")
            else
                goIntoStr = common:getLanguageString("@CSPromotion")
            end
            goingGroup = tonumber(CSManager.WarStateCache.openState.lsGoingGroup)
            stage = tonumber(CSManager.WarStateCache.openState.lsGoingStage)
        end
        
        if goingGroup == 1 then
            group = common:getLanguageString("@WinnerGroup")
        else
            group = common:getLanguageString("@ResurrectionGroup")
        end
        if CSManager.WarStateCache.openState.csGoingStage == nil then
            CSManager.WarStateCache.openState.csGoingStage = 0
        end
        if tonumber(CSManager.WarStateCache.openState.csGoingStage) == 23 then --����ھ����⴦��
            goIntoStr = common:getLanguageString("@CSBeing")
        end
        if tonumber(CSManager.WarStateCache.openState.lsGoingStage) == 0 or CSManager.WarStateCache.openState.lsGoingStage == nil then --δ�����̭��
            gruop = ""
            return ""
        end
        
        if not CSTools.isPeriodEnd(CSTools.getTimeItem(CSManager.WarStateCache.openState.battleId), CS_Battle_Stage.LS_KNOCKOUT) then
            return ""
        end
        local strTab = {}
        table.insert( strTab , group)
        return goIntoStr .. common:getGsubStr( strTab ,common:getLanguageString( "@CSCurrentStage" .. stage ))

    end
    return ""
end

function Reset_crossServerData()
    CSManager.RuleCache.serverNames = ""
end

return CSManager;
--endregion
