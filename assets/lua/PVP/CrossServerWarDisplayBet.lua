
--------------------------------------------------------------------------------

--require the other module
local CsBattle_pb = require "CsBattle_pb"
local HP_pb = require("HP_pb")
local CSTools = require("CSTools")
local CommonPage = require("CommonPage");
local RoleManager = require("PlayerInfo.RoleManager")
local UserInfo = require("PlayerInfo.UserInfo")
--register the other module

local NO_PLAYER_PIC = "UI/CrossServerWar/u_ico000.png";
local RoleCfg = ConfigManager.getRoleCfg()
CrossServerWarDisplayBetGlobalVariable = {
	PlayerVSInfo = {},
	betPlayer = nil,
	playerIdentify = nil,
	battleId = nil,
	firstFlag = true
};

--function table
local CrossServerWarDisplayBet = {};
local PacketHandler = {};
--local ScrollViewController = {};
local Tools = {};
local ControllersHandler = {};
local CacheHandler = {};
local TimerHandler = {};



--current adventure container
local ADVENTURE_CONTAINER = {
	ID = 49,
	TAG = nil
};

--protobuf container
local PROTOBUF_CONTAINER = {
	OPCODE_CS_BET_CLICK_C = HP_pb.OPCODE_CS_BET_CLICK_C,
	OPCODE_CS_BET_CLICK_S = HP_pb.OPCODE_CS_BET_CLICK_S,
    OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S
};

--bet state
local BET_STATE = {
	SELECTED_STATE = 1,
	UNSELECTED_STATE = 2
};

local SELECTED_DIR = {
	LEFT_STATE = 1,
	RIGHT_STATE = 2
};

local selected = nil;

-- functions table
local functionNameHandlerMap = {
	luaLoad = "onLoad",
	luaInit = "onInit",
	luaEnter = "onEnter",
	luaExecute = "onExecute",
	luaUnload = "onUnload",
	luaExit = "onExit",
	luaReceivePacket = "onReceivePacket",
	onConfirm = "onBetButton",
	onClose = "backToBattlePage",
	--onClose = "onBetButton",
	onLBottomRourBtn = "clickLeftBet",
	onRBottomRourBtn = "clickRightBet",
    onLFrame = "clickLeftFrame",
    onRFrame = "clickRightFrame"
};

function luaCreat_CrossServerWarDisplayBet( container )
	CCLuaLog("luaCreat_CrossServerWarDisplayBet");
	container:registerFunctionHandler(CrossServerWarDisplayBet.onFunction);
end

function CrossServerWarDisplayBet.onFunction( eventName, container )
	local funcName = functionNameHandlerMap[eventName];

	if Tools.checkValue(funcName) then
		CrossServerWarDisplayBet[funcName](container);
	else
		CCLuaLog("unExpected eventName : ".. eventName);
	end
end

function CrossServerWarDisplayBet.onLoad( container )
	CCLuaLog("#Z:CrossServerWarDisplayBet onLoad!");
	container:loadCcbiFile("CrossServerWarBottomPour.ccbi");
end

function CrossServerWarDisplayBet.onInit( container )

end

function CrossServerWarDisplayBet.onEnter( container )
	CrossServerWarDisplayBetGlobalVariable.firstFlag = false;
	PacketHandler.registerAllPackets(container);
	ControllersHandler.refreshAllControllersInfo(container);
	ControllersHandler.setExplain(container);
end

function CrossServerWarDisplayBet.onExecute( container )

end

function CrossServerWarDisplayBet.onExit( container )
	--clear select state
	selected = nil;
	PacketHandler.removeAllPackets(container);
end

function CrossServerWarDisplayBet.onUnload( container )

end

function CrossServerWarDisplayBet.onBetButton( container )
	local msgFlag = false;
	if CrossServerWarDisplayBetGlobalVariable.betPlayer ~= nil  and string.len(CrossServerWarDisplayBetGlobalVariable.betPlayer) ~= 0 then
		MessageBoxPage:Msg_Box_Lan("@CSBeted");
		msgFlag = true;
	elseif (not Tools.checkBetCostEnough()) and selected ~= nil then
		MessageBoxPage:Msg_Box_Lan("@CSBetGoldsNotEnough");
		msgFlag = true;
	elseif selected == nil then
		MessageBoxPage:Msg_Box_Lan("@CSSelectedBetButton");
		msgFlag = true;
	end

	if (not msgFlag) and selected ~= nil then
		PacketHandler.requireBetMSG(container);
	end
end

function CrossServerWarDisplayBet.clickLeftFrame( container )
    CrossServerWarDisplayBet.requirePlayInfo( CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1 )
end

function CrossServerWarDisplayBet.clickRightFrame( container )
    CrossServerWarDisplayBet.requirePlayInfo( CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2 )
end

function CrossServerWarDisplayBet.requirePlayInfo( player )

    if Tools.checkValue(player) then  
		local playerIdentify = player.playerIdentify;

		if playerIdentify ~= nil then
			if playerIdentify ~= nil then
				--local player = Tools.getPlayIdByPlayerIdentify(playerIdentify);
				--if player ~= nil then

					local msg = CsBattle_pb.OPCSBattleArrayInfo();
					msg.viewIdentify = playerIdentify;
					msg.version = 1;

					local pb_data = msg:SerializeToString();
					PacketManager:getInstance():sendPakcet(PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_C,pb_data,#pb_data,true);
					--ScriptMathToLua:showTeamBattleView(tonumber(player),1,false);
				--end
			end
		end
	end

end

function CrossServerWarDisplayBet.onReceivePacket( container )
	local code = container:getRecPacketOpcode();

	if code == PROTOBUF_CONTAINER.OPCODE_CS_BET_CLICK_S then
		local msg = CsBattle_pb.OPCSBattleBetPlayerRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.betSucc then
			MessageBoxPage:Msg_Box_Lan("@CSBetSucc");
			CrossServerWarDisplayBetGlobalVariable.betPlayer = msg.betPlayer;
			ControllersHandler.changeBetRadioState(BET_STATE.SELECTED_STATE,container);

			local betDir = ControllersHandler.checkSelectedDirection();
			if betDir == SELECTED_DIR.LEFT_STATE then
				CrossServerWarDisplayBet.clickLeftBet(container);
			elseif betDir == SELECTED_DIR.RIGHT_STATE then
				CrossServerWarDisplayBet.clickRightBet(container);
			else
				CrossServerWarDisplayBet.clickNone(container);
			end
		else
			MessageBoxPage:Msg_Box_Lan("@CSBetFailed");
		end
    elseif code == PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S then
		local msg = CsBattle_pb.OPCSBattleArrayInfoRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.resultOK then
			--MessageBoxPage:Msg_Box("@CSGetBattleInfoSuccess");
		else
			MessageBoxPage:Msg_Box("@CSGetBattleInfoFailed");
		end
        if msg:HasField("playerInfo") then
            PageManager.viewCSPlayerInfo( msg.playerInfo )
        end
	end
end

function CrossServerWarDisplayBet.backToBattlePage( container )
	local msg = MsgMainFramePopPage:new()
	msg.pageName = "CrossServerWarDisplayBet"
	MessageManager:getInstance():sendMessageForScript(msg);
end

--777. param mark : controllers handler
function ControllersHandler.refreshAllControllersInfo( container )
	-- left head pic
	local discipleLeftPic = RoleCfg[CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerItemId].icon;
	if Tools.checkValue(discipleLeftPic) then
		container:getVarSprite("mLNemIco"):setTexture(discipleLeftPic);
	end

	local leftPlayerFrame = container:getVarMenuItemImage("mLFrame");
	--common:setFrameQuality(leftPlayerFrame, leftDisciple.quality);

	--left name
	container:getVarLabelTTF("mLPlayerName"):setString(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerName);

	--left level
	--container:getVarLabelBMFont("mLLVNum"):setString(--"LV." .. CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerLevel);
    container:getVarLabelBMFont("mLLVNum"):setString(UserInfo.getOtherLevelStr(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.rebirthStage, CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerLevel))

	--left server name
	container:getVarLabelBMFont("mLServer"):setString(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.serverName);
    --left Profession
    container:getVarSprite("mProfession1"):setTexture( RoleManager:getOccupationIconById(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerItemId) )
	-- right head pic
	if CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerItemId ~= 0 then
		local discipleRightPic = RoleCfg[CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerItemId].icon;
		if Tools.checkValue(discipleRightPic) then
			container:getVarSprite("mRMemIco"):setTexture(discipleRightPic);
		end

		--local rightPlayerFrame = container:getVarMenuItemImage("mRFrame");
		--common:setFrameQuality(rightPlayerFrame, rightDisciple.quality);

		--right name
		container:getVarLabelTTF("mRPlayerName"):setString(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerName)

		--right level
		container:getVarLabelBMFont("mRLVNum"):setString(UserInfo.getOtherLevelStr(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.rebirthStage, CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerLevel));
		--right server name
		container:getVarLabelBMFont("mRServer"):setString(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.serverName);
        --right Profession
        container:getVarSprite("mProfession2"):setTexture( RoleManager:getOccupationIconById(CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerItemId) )
	else
		container:getVarSprite("mRMemIco"):setTexture(NO_PLAYER_PIC);

		local noPlayerStr = Language:getInstance():getString("@CSNotPlayer")
		local noServerStr = Language:getInstance():getString("@CSNotPlayerServer")
		container:getVarLabelTTF("mRPlayerName"):setString(noPlayerStr);
		container:getVarLabelBMFont("mRLVNum"):setString("LV.0");
		container:getVarLabelBMFont("mRServer"):setString(noServerStr);
	end

	--current battle time
	local currentTime = CSTools.getCurrentStageBattleTime(CrossServerWarDisplayBetGlobalVariable.battleId);
	if Tools.checkValue(currentTime) then
		container:getVarLabelBMFont("mNextCD"):setString(currentTime);
	end

	-- bet button state
	if CrossServerWarDisplayBetGlobalVariable.betPlayer ~= nil  and string.len(CrossServerWarDisplayBetGlobalVariable.betPlayer) ~= 0 then
		ControllersHandler.changeBetRadioState(BET_STATE.SELECTED_STATE,container)

		local betDir = ControllersHandler.checkSelectedDirection();
		if betDir == SELECTED_DIR.LEFT_STATE then
			CrossServerWarDisplayBet.clickLeftBet(container);
		elseif betDir == SELECTED_DIR.RIGHT_STATE then
			CrossServerWarDisplayBet.clickRightBet(container);
		else
			CrossServerWarDisplayBet.clickNone(container);
		end

	else
		ControllersHandler.changeBetRadioState(BET_STATE.UNSELECTED_STATE,container)
	end

end


function CrossServerWarDisplayBet.clickLeftBet( container )
	selected = SELECTED_DIR.LEFT_STATE;

	container:getVarMenuItemImage("mRBottomRourBtn"):unselected();
	container:getVarMenuItemImage("mLBottomRourBtn"):selected();
end

function CrossServerWarDisplayBet.clickRightBet( container )
	selected = SELECTED_DIR.RIGHT_STATE;

	container:getVarMenuItemImage("mRBottomRourBtn"):selected();
	container:getVarMenuItemImage("mLBottomRourBtn"):unselected();
end

function CrossServerWarDisplayBet.clickNone( container )
	container:getVarMenuItemImage("mRBottomRourBtn"):unselected();
	container:getVarMenuItemImage("mLBottomRourBtn"):unselected();
end

function ControllersHandler.changeBetRadioState( switch, container)
	if switch == BET_STATE.SELECTED_STATE then
		container:getVarMenuItemImage("mLBottomRourBtn"):setEnabled(false);
		container:getVarMenuItemImage("mRBottomRourBtn"):setEnabled(false);
		container:getVarMenuItemImage("mConfirm"):setEnabled(false);
	elseif switch == BET_STATE.UNSELECTED_STATE then
		container:getVarMenuItemImage("mLBottomRourBtn"):setEnabled(true);
		container:getVarMenuItemImage("mRBottomRourBtn"):setEnabled(true);
		container:getVarMenuItemImage("mConfirm"):setEnabled(true);
	end
end

function ControllersHandler.checkSelectedDirection()
	local player1 = CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerIdentify;
	local player2 = CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerIdentify;
	local playerBet = CrossServerWarDisplayBetGlobalVariable.betPlayer;

	if playerBet == player1 then
		return SELECTED_DIR.LEFT_STATE;
	elseif playerBet == player2 then
		return SELECTED_DIR.RIGHT_STATE;
	end

	return nil;
end

function ControllersHandler.setExplain( container )
		--set cuurent stage bet cost
	local betCostLabel = container:getVarLabelBMFont("mBPExplain");
	local betCost = CSTools.getCurrentBetCost(CrossServerWarDisplayBetGlobalVariable.battleId);
	local explainStr = Language:getInstance():getString("@CSExplain"):gsub("#v1#",tostring(betCost));

	if Tools.checkValue(betCostLabel) then
		local count = VaribleManager:getInstance():getSetting("CrossServerWarDisplayLineCount")
		betCostLabel:setString(common:stringAutoReturn(explainStr, count));
	end
end

--999. param mark : packet manager
function PacketHandler.requireBetMSG( container )
	local msg = CsBattle_pb.OPCSBattleBetPlayer();

	local betPlayerFlag = nil;
	if selected == SELECTED_DIR.LEFT_STATE then
		betPlayerFlag = CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player1.playerIdentify;
	elseif selected == SELECTED_DIR.RIGHT_STATE then
		betPlayerFlag = CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo.player2.playerIdentify;
	end

	msg.playerIdentify = CrossServerWarDisplayBetGlobalVariable.playerIdentify;
	msg.betPlayer = betPlayerFlag;
	msg.betStage = CSTools.getCurrentStage(CrossServerWarDisplayBetGlobalVariable.battleId);

	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(PROTOBUF_CONTAINER.OPCODE_CS_BET_CLICK_C,pb_data,#pb_data,true);
end

function PacketHandler.registerAllPackets( container )
	container:registerPacket(PROTOBUF_CONTAINER.OPCODE_CS_BET_CLICK_S);
    container:registerPacket(PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
end

function PacketHandler.removeAllPackets( container )
	container:removePacket(PROTOBUF_CONTAINER.OPCODE_CS_BET_CLICK_S);
    container:removePacket(PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
end




-- 999. tools functions
function Tools.checkValue( obj )
	return obj ~= nil;
end

function Tools.numAGreaterThanNumB( numA, numB )
	if not Tools.checkValue(numA) or not Tools.checkValue(numB) then
		return false;
	end

	return tonumber(numA) > tonumber(numB);
end

function Tools.numAGreaterOrEqualsToNumB( numA, numB )
	if not Tools.checkValue(numA) or not Tools.checkValue(numB) then
		return false;
	end

	return tonumber(numA) >= tonumber(numB);
end

function Tools.numALessThanNumB( numA, numB )
	if not Tools.checkValue(numA) or not Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) < tonumber(numB);
end

function Tools.numALessOrEqualsToNumB( numA, numB )
	if not Tools.checkValue(numA) or not Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) <= tonumber(numB);
end

function Tools.numAEqualsToNumB( numA, numB )
	if not Tools.checkValue(numA) or not Tools.checkValue(numB) then
		return false;
	end
	return tonumber(numA) == tonumber(numB);
end

function Tools.checkBetCostEnough()
    local UserInfo = require("PlayerInfo.UserInfo")
    UserInfo.sync()
	local limitGolds = CSTools.getCurrentBetCost(CrossServerWarDisplayBetGlobalVariable.battleId);

	if UserInfo.playerInfo.coin >= limitGolds then
		return true;
	end

	return false;
end
