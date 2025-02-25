
--				
--------------------------------------------------------------------------------

--require the other module
registerScriptPage("CSRankingPage")
local CsBattle_pb = require "CsBattle_pb"
local CSTools = require("PVP.CSTools")
local CSManager = require("PVP.CSManager")
local CommonPage = require("CommonPage");
local NodeHelper = require("NodeHelper")
local RoleCfg = ConfigManager.getRoleCfg()
--register the other module
registerScriptPage('CrossServerWarDisplay')

--current adventure container
local ADVENTURE_CONTAINER = {
	ID = 49,
	TAG = nil
};

--page status

USER_PROPERTY_GOLD_COINS = 1001;
USER_PROPERTY_SILVER_COINS = 1002;

-- war stage
local WAR_STAGE = {
	UNOPEN_STAGE = 0,
	SIGNUP_STAGE = 2,
	PER_KONCKOUTR_STAGE = 4,
	PER_16TO8_STAGE = 6,
	PER_8TO4_STAGE = 8,
	PER_4TO2_STAGE = 10,
	PER_2TO1_STAGE = 12,
	CRO_KONCKOUTR_STAGE = 14,
	CRO_16TO8_STAGE = 16,
	CRO_8TO4_STAGE = 18,
	CRO_4TO2_STAGE = 20,
	CRO_2TO1_STAGE = 22,
	REVIEW_STAGE = 24,
	FINISH_STAGE = 26
};

--war detail stage
local WAR_DETAIL_STAGE = {
	UNOPEN_STAGE = 0,
	SIGNUP_STAGE = 1,
	PER_KONCKOUTR_STAGE = 2,
	PER_16TO8_BET_STAGE = 3,
	PER_16TO8_BATTLE_STAGE = 4,
	PER_16TO8_REVIEW_STAGE = 5,
	PER_8TO4_BET_STAGE = 6,
	PER_8TO4_BATTLE_STAGE = 7,
	PER_8TO4_REVIEW_STAGE = 8,
	PER_4TO2_BET_STAGE = 9,
	PER_4TO2_BATTLE_STAGE = 10,
	PER_4TO2_REVIEW_STAGE = 11,
	PER_2TO1_BET_STAGE = 12,
	PER_2TO1_BATTLE_STAGE = 13,
	PER_2TO1_REVIEW_STAGE = 14,
	CRO_KONCKOUTR_STAGE = 15,
	CRO_16TO8_BET_STAGE = 16,
	CRO_16TO8_BATTLE_STAGE = 17,
	CRO_16TO8_REVIEW_STAGE = 18,
	CRO_8TO4_BET_STAGE = 19,
	CRO_8TO4_BATTLE_STAGE = 20,
	CRO_8TO4_REVIEW_STAGE = 21,
	CRO_4TO2_BET_STAGE = 22,
	CRO_4TO2_BATTLE_STAGE = 23,
	CRO_4TO2_REVIEW_STAGE = 24,
	CRO_2TO1_BET_STAGE = 25,
	CRO_2TO1_BATTLE_STAGE = 26,
	CRO_2TO1_REVIEW_STAGE = 27,
	REVIEW_STAGE = 28,
	FINISH_STAGE = 29
};

-- worship id
local WORSHIP_LEVEL = {
	PRIMARY_LEVEL = 1,
	MIDDLE_LEVEL = 2,
	ADVANCED_LEVEL = 3
};

-- battle array
local BATTLE_ARRAY = {
	CHAMPION = 1,
	SECONDPLACE = 2,
	THIRD = 3
}

-- worship state
local WORSHIP_GET_STATE = {
	GET_STATE = 1,
	NOT_GET_STATE = 0
};

-- worship rewards or cost
local WORSHIP_TABLE_STATE = {
	REWARD_STATE = 1,
	COST_STATE = 2
};

-- sign up ok or not ok
local SIGNUP_STATE = {
	SIGNUP_YES = 0,
	SIGNUP_NO = -1
};

--packet error code
local ERROR_CONTAINER = {
	NO_POWER = 1,
};

--function table
local CrossServerWar = {};
--local ScrollViewController = {};
local ControllersHandler = {};
local TimerHandler = {};
local AnimationHandler = {};

--current page controllers
local PageControllers = {
	warNode = nil,
	warOpenNode = nil,
	warCloseNode = nil,
	worshipNode = nil
};

-- Timer
local WarStateTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
};

local OpenWarStateTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
}

local OngoingOneTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 999
};

local OngoingTwoTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 999
};

-- worship rewards
local WorshipRewards = {
	primary = {},
	middle = {},
	advanced = {}
};

local WorshipCost = {
	primary = {};
	middle = {};
	advanced = {};
};


local buildStateFlag = nil;


local ProgressNodePic = {
	closePic = "UI/CrossServerWar/u_CrossServerWarEventsExp1B.png",
	openPic = "UI/CrossServerWar/u_CrossServerWarEventsExp1.png"
}

-- functions table
local functionNameHandlerMap = {
	luaLoad = "onLoad",
	luaInit = "onInit",
	luaEnter = "onEnter",
	luaExecute = "onExecute",
	luaUnload = "onUnload",
	luaExit = "onExit",
	luaReceivePacket = "onReceivePacket",
	onFightGetRewardBtn = "goRewardPage",
	onWorshipButton = "goToWorshipPage",
	onBack = "backToWarPage",
	onLWBtn = "getPrimaryWorship",
	onIWBtn = "getMiddleWorship",
	onSWBtn = "getAdvancedWorship",
	onEnrollBtn = "signUpOrRefreshBattleArray",
	onViewMatchBtn = "goWarViewPage",
	onFirstPic = "showChampionBattleArray",
	onSecondPic = "showSecondplaceBattleArray",
	onThirdPic = "showThirdBattleArray",
	onRuleBtn = "showRule",
	luaOnAnimationDone = "runContinueAnimation",
    onKingList = "onKingList",
    onRebornList = "onRebornList"
};

function luaCreat_CrossServerWar( container )
	CCLuaLog("luaCreat_CrossServerWar");
	container:registerFunctionHandler(CrossServerWar.onFunction);
end

function CrossServerWar.onFunction( eventName, container )
	local funcName = functionNameHandlerMap[eventName];

	if CSManager.Tools.checkValue(funcName) then
		CrossServerWar[funcName](container);
	else
		CCLuaLog("unExpected eventName : ".. eventName);
	end
end

-- 1. main events functions
function CrossServerWar.onLoad( container )
	CCLuaLog("#Z:CrossServerWar onLoad!");
	container:loadCcbiFile("CrossServerWar.ccbi");
end

function CrossServerWar.onInit( container )

end

function CrossServerWar.onEnter( container )
	ControllersHandler.getAllControllers(container);

	--ControllersHandler.setAllControllersNotDisplay(container);
	CrossServerWar.registerAllPackets(container)
    container:getVarNode("mViewMatchNode"):setVisible(false)
    container:getVarNode("mAniNode"):setVisible(false)
    container:getVarNode("mNoWar"):setVisible(false)
    if Golb_Platform_Info.is_r2_platform then
        local varmap = {
            mCSGoldenOfGroupKing = common:getLanguageString("@CSGoldenOfGroupKing"),
            mCSSilverOfGroupKing = common:getLanguageString("@CSSilverOfGroupKing"),
            mCSGoldenOfGroupReborn = common:getLanguageString("@CSGoldenOfGroupReborn")
        }
        NodeHelper:MoveAndScaleNode(container,varmap,0,0.65);
        NodeHelper:setNodeScale(container, "mTitleNumSubTitle", 0.7 , 0.7)
        if IsThaiLanguage() then
            NodeHelper:SetNodePostion(container, "m16Into8Tex",20,0)
            NodeHelper:SetNodePostion(container, "mFinalsTex",-20,0)  

           NodeHelper:setNodeScale(container, "mNowTime1", 0.7 , 0.7)
           NodeHelper:setNodeScale(container, "mNowTime2", 0.7 , 0.7)
           NodeHelper:setNodeScale(container, "mNowTex01", 0.7 , 0.7)
           NodeHelper:setNodeScale(container, "mNowTex02", 0.7 , 0.7)

        end
    end
	CSManager.PacketHandler.requireWarState(container);
	
end

function CrossServerWar.onExecute( container )

	--if is close war state, refresh sign up button state
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		ControllersHandler.checkSignUpButtonState(container);
	end

	-- refresh the page war state
	if (not WarStateTimer.timerExist) then
		ControllersHandler.checkWarPageState(container);
	end
	--if war state timer exist, refresh the war state timer
	if WarStateTimer.timerExist then
		TimerHandler.refreshWarStateTimer(container);
	end


	--refersh the open war page state
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE and not (OpenWarStateTimer.timerExist) then
		ControllersHandler.refershOpenWarPage(container);
	end
	if OpenWarStateTimer.timerExist then
		TimerHandler.refreshOpenWarPageInfo(container)
	end



	--refresh the open war Timer
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then

		if OngoingOneTimer.timerExist then
			TimerHandler.ongoingTimerOne(container);
		end

		if OngoingTwoTimer.timerExist then
			TimerHandler.ongoingTimerTwo(container);
		end

		--refresh for knockout period to show the button of myGame
		if (CSManager.WarStateCache.openState.battleId > 0) then
			if CSTools.isKnockOutEnd(CSManager.WarStateCache.openState.battleId) then
				CrossServerWar.showMyGameBtn(container);
			end
		end
	end
end

function CrossServerWar.onExit( container )
	buildStateFlag = 0;
	CrossServerWar.removeAllPackets(container);
end

function CrossServerWar.onUnload( container )
    
end

function CrossServerWar.onKingList( container )
    CSRankingPageBase_setType(1)
    PageManager.pushPage( "CSRankingPage" )
end

function CrossServerWar.onRebornList( container )
    CSRankingPageBase_setType(2)
    PageManager.pushPage( "CSRankingPage" )
end

--2. go to select page
function CrossServerWar.goToWorshipPage( container )
	--1. if first go to WorshipPage, set Controllers info
	ControllersHandler.initWorshipPageControllersInfo(container);
	--2. change page
	ControllersHandler.switchPageState(CSManager.PAGE_STATE.WORSHIP_STATE);
	--3. require packet, control worship state
	CSManager.PacketHandler.requireWorshipState(container);
end

function CrossServerWar.getCurrentBattleId()
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
        if CSManager.WarStateCache.openState.battleId == nil then
            return 0
        else
            return tonumber(CSManager.WarStateCache.openState.battleId)
        end

	elseif CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		if CSManager.WarStateCache.closeState.latestBattleId == nil then
            return 0
        else
            return CSManager.WarStateCache.closeState.latestBattleId
        end
	end
end

--reward page
function CrossServerWar.goRewardPage( container )

	local battleId = tonumber(CrossServerWar.getCurrentBattleId())
    if battleId == nil then
        battleId = 0
    end

	if battleId < 1 then
		battleId = 1
		--[[
		MessageBoxPage:Msg_Box("@NoRewardList")
		return
		--]]
	end
	CSBattleReward_SetBattleId(battleId)
	PageManager.changePage("CSBattleRewardPage")
end

function CrossServerWar.goToWarOpenPage( container )
	--1. refresh the controllers state
    local str = CSManager.getCurrentStageString();
    if Golb_Platform_Info.is_r2_platform then
        NodeHelper:setNodeScale(container, "mPromotionLab", 0.75, 0.75)
    end
    container:getVarLabelBMFont("mPromotionLab"):setString( str )
	ControllersHandler.refreshControllersState(CSManager.PAGE_STATE.WAR_OPEN_STATE, container);
	--2. change page
	ControllersHandler.switchPageState(CSManager.PAGE_STATE.WAR_OPEN_STATE);
end

function CrossServerWar.goToWarClosePage( container )
    if not CSManager.WarStateCache.closeState.signUp and CSTools.timeAtStage(CSManager.WarStateCache.closeState.battleId, WAR_STAGE.SIGNUP_STAGE) then
        container:getVarNode("mAniNode"):setVisible( true )
        --container:runAnimation("Default Timeline")
    end
	--1. refresh the controllers state
	ControllersHandler.refreshControllersState(CSManager.PAGE_STATE.WAR_CLOSE_STATE, container);
	--2. change page
	ControllersHandler.switchPageState(CSManager.PAGE_STATE.WAR_CLOSE_STATE);
end

function CrossServerWar.backToWarPage( container )
    PageManager.changePage("PVPActivityPage")
end

-- click worship button
function CrossServerWar.getPrimaryWorship( container )
	CSManager.PacketHandler.requireWorshipReward(container, CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL);
end

function CrossServerWar.getMiddleWorship( container )
	CSManager.PacketHandler.requireWorshipReward(container, CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL);
end

function CrossServerWar.getAdvancedWorship( container )
	CSManager.PacketHandler.requireWorshipReward(container, CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL);
end

function CrossServerWar.signUpOrRefreshBattleArray( container )

	if CSManager.WarStateCache.closeState.signUp then
        PageManager.showConfirm( common:getLanguageString("@CSRefreshBattArrayTitle") ,common:getLanguageString("@CSRefreshBattArrayContent") , CSManager.PacketHandler.requireRefreshBattleArray )
		--CSManager.PacketHandler.requireRefreshBattleArray(container);
	else
		CSManager.PacketHandler.requireSignUp(container);
        container:runAnimation("GetInto")
	end
end

function CrossServerWar.goWarViewPage( container )
	CrossServerWarDisplayGlobal.playerIdentify = CSManager.WarStateCache.playerIdentify;
	CrossServerWarDisplayGlobal.battleId = CSManager.WarStateCache.openState.battleId;

	if CSManager.WarStateCache.openState.battleId > 0 then
		if CSTools.isKnockOutEnd(CSManager.WarStateCache.openState.battleId) then
			CrossServerWar.showMyGame()
			return
		end
	end

    PageManager.changePage("CrossServerWarDisplay")
    --[[
	local msg = MsgMainFramePushPage:new();
	msg.pageName = "CrossServerWarDisplay";
	MessageManager:getInstance():sendMessageForScript(msg)
    ]]--
end

function CrossServerWar.showMyGameBtn(container)
	container:getVarNode("mViewMatchNode"):setVisible(true);
	container:getVarLabelBMFont("mViewMatchTex"):setString(common:getLanguageString("@MyGame"))
end

function CrossServerWar.showMyGame()
	BattleList.setType(CrossServerWarDisplayGlobal.battleId, BattleList.Type_MyBattle)
	PageManager.pushPage("CSBattleListPage")
end

-- show user battle
function CrossServerWar.showChampionBattleArray()
	CrossServerWar.showBattleArray(BATTLE_ARRAY.CHAMPION);
end

function CrossServerWar.showSecondplaceBattleArray()
	CrossServerWar.showBattleArray(BATTLE_ARRAY.SECONDPLACE);
end

function CrossServerWar.showThirdBattleArray()
	CrossServerWar.showBattleArray(BATTLE_ARRAY.THIRD);
end

function CrossServerWar.showBattleArray( flag )
	local playId = nil;
	if flag == BATTLE_ARRAY.CHAMPION then
		if CSManager.WarStateCache.closeState.winTop1Player ~= nil then
			playId = CSManager.WarStateCache.closeState.winTop1Player.playerIdentify;
		end
	elseif flag == BATTLE_ARRAY.SECONDPLACE then
		if CSManager.WarStateCache.closeState.loseTop1Player~= nil then
			playId = CSManager.WarStateCache.closeState.loseTop1Player.playerIdentify;
		end
	elseif flag == BATTLE_ARRAY.THIRD then
		if CSManager.WarStateCache.closeState.winTop2Player ~= nil then
			playId = CSManager.WarStateCache.closeState.winTop2Player.playerIdentify;
		end
	end

	if playId ~= nil then
		-- local player = CSManager.Tools.getPlayIdByPlayerIdentify(playId);
		-- if player ~= nil then
		-- 	ScriptMathToLua:showTeamBattleView(tonumber(player),1,false);
		-- end
		local msg = CsBattle_pb.OPCSBattleArrayInfo();
		msg.version = 1;
		msg.viewIdentify = playId;
		
		local pb_data = msg:SerializeToString();
		PacketManager:getInstance():sendPakcet(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_C,pb_data,#pb_data,true);
	else
		MessageBoxPage:Msg_Box("@CSNoBattleArray");
	end
end

function CrossServerWar.showRule( container )
	if CSManager.RuleCache.serverNames == nil or string.len(CSManager.RuleCache.serverNames) <= 0 then
		CSManager.PacketHandler.requireRuleInfo(container);
	else
		CrossServerWar.showRulePage(container);
	end

end

function CrossServerWar.showRulePage( container )
	if CSManager.Tools.checkValue(CSManager.RuleCache.serverNames) then
        RuleConfg = ConfigManager.getHelpCfg( GameConfig.HelpKey.HELP_CROSSSERVER )
		local helpInfoStr = string.gsub( RuleConfg[1].content , "#v1#", CSManager.RuleCache.serverNames)
		--common:goHelpPage(helpInfoStr)
        PageManager.showHelp( nil, common:getLanguageString("@CrossServerRole"), false ,helpInfoStr)
	else
		MessageBoxPage:Msg_Box("@CSRuleInfoFailed");
	end
end

--777. packet handler

function CrossServerWar.registerAllPackets( container )
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLESTATE_S);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPSTATE_S);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPGET_S);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_SIGNUP_S);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
	--container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_GOT_REWARDS);
	container:registerPacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_Rule_S);
end

function CrossServerWar.removeAllPackets( container )
	container:removePacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLESTATE_S)
	container:removePacket(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPSTATE_S)
	container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPGET_S);
	container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_SIGNUP_S);
	container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S);
	container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
	--container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_GOT_REWARDS);
	container:removeMessage(CSManager.PROTOBUF_CONTAINER.OPCODE_CS_Rule_S);
end

function CrossServerWar.onReceivePacket( container )
	local code = container:getRecPacketOpcode();

    --跨服状态回包
	if code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLESTATE_S then 
		local msg = CsBattle_pb.OPCSBattleStateRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		-- cache the msg
		CSManager.CacheHandler.cacheWarStateMSG(msg);
		--set main node display
		ControllersHandler.setMainNodeDisplay()

		if msg.connectedCsServer == 1 then
			-- go to page
			if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
				CrossServerWar.goToWarOpenPage( container );
			elseif CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
				CrossServerWar.goToWarClosePage( container );
			end
		else
			ControllersHandler.setAllControllersNotDisplay(container);
		end
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPSTATE_S then
		local msg = CsBattle_pb.OPCSBattleRequestWorshipRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		-- cache the msg
		CSManager.CacheHandler.cacheWorshipStateMSG(msg);

		--refresh controllers state
		ControllersHandler.refreshWorshipState(container);
    --膜拜回包
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_WORSHIPGET_S then
		local msg = CsBattle_pb.OPCSBattleWorshipRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		-- cache the msg
		CSManager.CacheHandler.cacheWorshipRewardMSG(msg);

		if CSManager.WorshipRewardCache.worshipSucc then
			--refresh the worship button
			ControllersHandler.refershWorshipButtons(container);
			--ControllersHandler.refreshLocalMemory(container);
			MessageBoxPage:Msg_Box("@CSWorshipSuccess");
		else
			MessageBoxPage:Msg_Box("@CSWorshipFailed");
		end
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_SIGNUP_S then
		local msg = CsBattle_pb.OPCSBattleSignupRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		-- cache the msg
		CSManager.CacheHandler.cacheSignUpMSG(msg);
		NodeHelper:setStringForLabel(container, {mRegistrationNum = CSManager.WarStateCache.closeState.signUpCount or 0})

		if CSManager.Tools.numAEqualsToNumB(CSManager.SignUpCache.signUpState, SIGNUP_STATE.SIGNUP_YES) then
			ControllersHandler.refershSignButton(container);
			MessageBoxPage:Msg_Box("@CSSignUpSuccess");
		else
			MessageBoxPage:Msg_Box("@CSSignUpFailed");
		end
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S then
		local msg = CsBattle_pb.OPCSBattleUpdateBattleArrayRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.resultOK then
			MessageBoxPage:Msg_Box("@CSRefershBattleArraySuccess");
		else
			MessageBoxPage:Msg_Box("@CSRefershBattleArrayFailed");
		end
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S then
		local msg = CsBattle_pb.OPCSBattleArrayInfoRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.resultOK then
			--MessageBoxPage:Msg_Box("@CSGetBattleInfoSuccess");
		else
			MessageBoxPage:Msg_Box("@CSGetBattleInfoFailed");
		end
        --
        if msg:HasField("playerInfo") then
            PageManager.viewCSPlayerInfo( msg.playerInfo )
        end

	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_GOT_REWARDS then
		local msg = UserRewards_pb.OPUserRewardRet()
		local msgBuff = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuff)
		CSManager.PacketHandler.onReceiveReward(container, msg)
    --跨服规则回包
	elseif code == CSManager.PROTOBUF_CONTAINER.OPCODE_CS_Rule_S then
		local msg = CsBattle_pb.OPCSBattleRequestRuleRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		CSManager.CacheHandler.cacheRuleMSG(msg);
		CrossServerWar.showRulePage( container )
	end
end

-- 888. all controllers handler
function ControllersHandler.getAllControllers( container )
	PageControllers.warNode = container:getVarNode("mMainNode");
	PageControllers.warOpenNode = container:getVarNode("mMakeWar");
	PageControllers.warCloseNode = container:getVarNode("mNoWar");
	PageControllers.worshipNode = container:getVarNode("mWTKNode");
end

function ControllersHandler.setAllControllersNotDisplay( container )
	if CSManager.Tools.checkValue(PageControllers.warCloseNode) then
		PageControllers.warCloseNode:setVisible(false);
	end

	if CSManager.Tools.checkValue(PageControllers.warOpenNode) then
		PageControllers.warOpenNode:setVisible(false);
	end

	if CSManager.Tools.checkValue(PageControllers.worshipNode) then
		PageControllers.worshipNode:setVisible(false);
	end

	if CSManager.Tools.checkValue(PageControllers.warNode) then
		PageControllers.warNode:setVisible(false);
	end
end

function ControllersHandler.setMainNodeDisplay()
	if CSManager.Tools.checkValue(PageControllers.warNode) then
		PageControllers.warNode:setVisible(true);
	end
end

function ControllersHandler.refreshControllersState( state, container)
	if state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
		--timer auto refresh the open page controllers info
		ControllersHandler.setWarOpenControllersInfo(container);
	elseif state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		ControllersHandler.setWarCloseControllersInfo(container);
	end
end

function ControllersHandler.setWarCloseControllersInfo( container )
	if CSManager.Tools.checkValue(CSManager.WarStateCache.closeState) then
		--check the war is more than 1,diaplay...
		local RoleManager = require("PlayerInfo.RoleManager")
		--show sign up count
		NodeHelper:setStringForLabel(container, {mRegistrationNum = CSManager.WarStateCache.closeState.signUpCount or 0})
		--clear first,second,third player info
		ControllersHandler.clearWinnerList(container);

		if CSManager.Tools.numAGreaterOrEqualsToNumB(CSManager.WarStateCache.closeState.battleId, 1) and CSManager.WarStateCache.closeState.battleId ~= nil then
			local currentWarCountStr = CSManager.WarStateCache.closeState.battleId;
			local nextWarStartTimeStr = nil;
			if currentWarCountStr > 0 then
				nextWarStartTimeStr = CSTools.getWarStartTime(currentWarCountStr);
			end

			-- set jieshu label
			local currentCount = tonumber(currentWarCountStr);
			if CSManager.Tools.checkValue(container:getVarLabelTTF("mTitleNumSubTitle")) then
				--[[
				if currentCount > 10 then
					if currentCount < 100 then
						container:getVarNode("mTitleNode1"):setVisible(false);
						container:getVarNode("mTitleNode3"):setVisible(true);
						
						--local countA = math.floor(currentCount / 10);
						--local countB = currentCount % 10;
						
						--if countA == 1 then
						--	countA = 10;
						--end 
						
						--local picStr1 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countA..".png";
						--local picStr2 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countB..".png";
						
						--container:getVarSprite("mTitleNumSub1"):setTexture(picStr1);
						--container:getVarSprite("mTitleNumSub2"):setTexture(picStr2);
						container:getVarLabelTTF("mTitleNumSubTitle"):setString(common:getLanguageString("@CSTimeOfCS"),currentCount)
					end
				else
					container:getVarNode("mTitleNode1"):setVisible(true);
					container:getVarNode("mTitleNode3"):setVisible(false);
					--local picStr = "UI/CrossServerWar/u_CrossServerWarTitleNum"..currentWarCountStr..".png";
					--container:getVarSprite("mTitleNum1"):setTexture(picStr);
					container:getVarLabelTTF("mTitleNumSubTitle"):setString(common:getLanguageString("@CSTimeOfCS"),currentCount)
				end]]
				container:getVarNode("mTitleNode1"):setVisible(true);
				container:getVarLabelTTF("mTitleNumSubTitle"):setString(common:getLanguageString("@CSTimeOfCS",currentCount))
			end
			-- set new jieshu time
			if CSManager.Tools.checkValue(container:getVarLabelBMFont("mCD")) then
				container:getVarLabelBMFont("mCD"):setString(nextWarStartTimeStr);
			end

		else--When in the "0", diaplay ...

		end
					--set the three winner label
			if CSManager.Tools.checkValue(container:getVarLabelTTF("mFirstName")) then
				if CSManager.Tools.checkValue(container:getVarLabelBMFont("mFirstServer")) then
					if CSManager.Tools.checkValue(CSManager.WarStateCache.closeState.winTop1Player) then
						local nameStr = CSManager.WarStateCache.closeState.winTop1Player.playerName;
						local serverStr = CSManager.WarStateCache.closeState.winTop1Player.serverName;
						container:getVarLabelTTF("mFirstName"):setString(nameStr);
						container:getVarLabelBMFont("mFirstServer"):setString(serverStr);
					end
				end
			end
			if CSManager.Tools.checkValue(container:getVarLabelTTF("mSecoundName")) then
				if CSManager.Tools.checkValue(container:getVarLabelBMFont("mSecoundServer")) then
					if CSManager.Tools.checkValue(CSManager.WarStateCache.closeState.loseTop1Player) then
						local nameStr = CSManager.WarStateCache.closeState.loseTop1Player.playerName;
						local serverStr = CSManager.WarStateCache.closeState.loseTop1Player.serverName;
						container:getVarLabelTTF("mSecoundName"):setString(nameStr);
						container:getVarLabelBMFont("mSecoundServer"):setString(serverStr);
					end
				end
			end
			if CSManager.Tools.checkValue(container:getVarLabelTTF("mThirdName")) then
				if CSManager.Tools.checkValue(container:getVarLabelBMFont("mThirdServer")) then
					if CSManager.Tools.checkValue(CSManager.WarStateCache.closeState.winTop2Player) then
						local nameStr = CSManager.WarStateCache.closeState.winTop2Player.playerName;
						local serverStr = CSManager.WarStateCache.closeState.winTop2Player.serverName;
						container:getVarLabelTTF("mThirdName"):setString(nameStr);
						container:getVarLabelBMFont("mThirdServer"):setString(serverStr);
					end
				end
			end
            
            container:getVarNode("mHandNode1"):setVisible( true )
            container:getVarNode("mHandNode2"):setVisible( true )
            container:getVarNode("mHandNode3"):setVisible( true )
            if CSManager.WarStateCache.closeState.winTop1Player ~= nil then 
                container:getVarLabelBMFont("mLv1"):setString(common:getLanguageString("@MyLevel", CSManager.WarStateCache.closeState.winTop1Player.playerLevel))
                container:getVarSprite("mPic1"):setTexture( RoleCfg[CSManager.WarStateCache.closeState.winTop1Player.playerItemId].icon )
                container:getVarSprite("mProfession1"):setTexture( RoleManager:getOccupationIconById(CSManager.WarStateCache.closeState.winTop1Player.playerItemId) )
                container:getVarLabelBMFont("mCSWarTitle"):setVisible(true)

                container:getVarNode("mKingList"):setVisible( true )
                container:getVarNode("mRebornList"):setVisible( true )
            else
                container:getVarLabelBMFont("mLv1"):setVisible( false )
                container:getVarSprite("mPic1"):setTexture( GameConfig.CSBattle_NoPlayer_Icon )
                container:getVarNode("mOccupationNode1"):setVisible( false )
                container:getVarLabelBMFont("mCSWarTitle"):setVisible(false)

                container:getVarNode("mKingList"):setVisible( false )
                container:getVarNode("mRebornList"):setVisible( false )
            end

            if CSManager.WarStateCache.closeState.loseTop1Player ~= nil then          
                container:getVarLabelBMFont("mLv2"):setString(common:getLanguageString("@MyLevel", CSManager.WarStateCache.closeState.loseTop1Player.playerLevel))
                container:getVarSprite("mPic2"):setTexture( RoleCfg[CSManager.WarStateCache.closeState.loseTop1Player.playerItemId].icon )
                container:getVarSprite("mProfession2"):setTexture( RoleManager:getOccupationIconById(CSManager.WarStateCache.closeState.loseTop1Player.playerItemId) )
            else
                container:getVarLabelBMFont("mLv2"):setVisible( false )
                container:getVarSprite("mPic2"):setTexture( GameConfig.CSBattle_NoPlayer_Icon )
                container:getVarNode("mOccupationNode2"):setVisible( false )
            end

            if CSManager.WarStateCache.closeState.winTop2Player ~= nil then
                container:getVarLabelBMFont("mLv3"):setString(common:getLanguageString("@MyLevel", CSManager.WarStateCache.closeState.winTop2Player.playerLevel))
                container:getVarSprite("mPic3"):setTexture( RoleCfg[CSManager.WarStateCache.closeState.winTop2Player.playerItemId].icon )
                container:getVarSprite("mProfession3"):setTexture( RoleManager:getOccupationIconById(CSManager.WarStateCache.closeState.winTop2Player.playerItemId) )
            else
                container:getVarLabelBMFont("mLv3"):setVisible( false )
                container:getVarSprite("mPic3"):setTexture( GameConfig.CSBattle_NoPlayer_Icon )
                container:getVarNode("mOccupationNode3"):setVisible( false )
            end

	end
end

function ControllersHandler.clearWinnerList( container )
		container:getVarLabelTTF("mFirstName"):setString("");
		container:getVarLabelBMFont("mFirstServer"):setString("");
		container:getVarLabelTTF("mSecoundName"):setString("");
		container:getVarLabelBMFont("mSecoundServer"):setString("");
		container:getVarLabelTTF("mThirdName"):setString("");
		container:getVarLabelBMFont("mThirdServer"):setString("");
end

function ControllersHandler.setWarOpenControllersInfo(container)
	
	--clear tiemr label info
	TimerHandler.removeTwoTimer();
	container:getVarLabelBMFont("mNowTime1"):setString("")
    container:getVarLabelBMFont("mNowTime2"):setString("")

	--runAnimation
	container:runAnimation("StarAni");
	--clear stage label info
	container:getVarLabelBMFont("mNowTex01"):setString("")
	container:getVarLabelBMFont("mNowTex02"):setString("")
	container:getVarLabelBMFont("mNextTex01"):setString("")
	local onDateStr1 = "";
	local onDateStr2 = "";
	local nextDateStr1 = "";

	if CSManager.Tools.checkValue(CSManager.WarStateCache.openState) then
		if CSManager.Tools.numAGreaterOrEqualsToNumB(CSManager.WarStateCache.openState.battleId, 1) and CSManager.WarStateCache.openState.battleId ~= nil then

			--ongoingStages
			local battleId = CSManager.WarStateCache.openState.battleId;
			if battleId > 0 then
				local ongoingStagesStr = CSTools.getOngoingStages(battleId);

                

				if CSManager.Tools.checkValue(ongoingStagesStr) then
					local ongoings = Split(ongoingStagesStr, "#", 2);
                    local animalPic = GameConfig.CSAnimalPic[ tonumber(ongoings[1]) ]
					
                    if animalPic ~= nil then
						local str = Language:getInstance():getString(animalPic)
                        if Golb_Platform_Info.is_r2_platform then
                            container:getVarLabelTTF("mEventSchedulePic"):setScale(0.8);
                        end
                        container:getVarLabelTTF("mEventSchedulePic"):setString( str )
                    end
					for i = 1, table.maxn(ongoings), 1 do
                       

						local ongoingStr = Language:getInstance():getString("@CSTimeStage"..ongoings[i]);
						if CSManager.Tools.numAEqualsToNumB(i, 1) then

							container:getVarLabelBMFont("mNowTex01"):setString(ongoingStr);
                            NodeHelper:setLabelOneByOne(container, "mNowTex01", "mNowTime1", 10, true)
    
							--ongoingStages Timer
								TimerHandler.createOneTimer(CSTools.getStageRemainTime(battleId, ongoings[i]), container);
								onDateStr1 = CSTools.getStartDateStr(battleId, ongoings[i])
						end

						if CSManager.Tools.numAEqualsToNumB(i, 2) then
							container:getVarLabelBMFont("mNowTex02"):setString(ongoingStr);
                            NodeHelper:setLabelOneByOne(container, "mNowTex02", "mNowTime2", 10, true)
							--ongoingStages Timer
								TimerHandler.createTwoTimer(CSTools.getStageRemainTime(battleId, ongoings[i]), container);
								onDateStr2 = CSTools.getStartDateStr(battleId, ongoings[i])
						end
					end
				end
			end
			
			
			-- set jieshu label
			local currentCount = tonumber(battleId);
			if CSManager.Tools.checkValue(container:getVarSprite("mTitleNumSubTitle")) then
				--[[
				if currentCount > 10 then
					if currentCount < 100 then
						container:getVarNode("mTitleNode1"):setVisible(false);
						container:getVarNode("mTitleNode3"):setVisible(true);
						
						local countA = math.floor(currentCount / 10);
						local countB = currentCount % 10;
						
						if countA == 1 then
							countA = 10;
						end 
						
						local picStr1 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countA..".png";
						local picStr2 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countB..".png";
						
						container:getVarSprite("mTitleNumSub1"):setTexture(picStr1);
						container:getVarSprite("mTitleNumSub2"):setTexture(picStr2);
						
					end
				else
					container:getVarNode("mTitleNode1"):setVisible(true);
					container:getVarNode("mTitleNode3"):setVisible(false);
					local picStr = "UI/CrossServerWar/u_CrossServerWarTitleNum"..currentCount..".png";
					container:getVarSprite("mTitleNum1"):setTexture(picStr);
				end]]
				container:getVarNode("mTitleNode1"):setVisible(true);
				container:getVarLabelTTF("mTitleNumSubTitle"):setString(common:getLanguageString("@CSTimeOfCS",currentCount))
			end
			
			

			--nextStages
			if battleId > 0 then
				local nextStageStr = CSTools.getNextStage(CSManager.WarStateCache.openState.battleId);
				if CSManager.Tools.checkValue(nextStageStr) then
					local nextStr = Language:getInstance():getString("@CSNextStage"..nextStageStr);
					container:getVarLabelBMFont("mNextTex01"):setString(nextStr);
					nextDateStr1 = CSTools.getBigStageStartDateStr(battleId, nextStageStr)
				end
			end

			--stage progress bar label
			local time16To8Str = Language:getInstance():getString("@CSTimeStage16To8Time");
			local time8To4Str = Language:getInstance():getString("@CSTimeStage8To4Time");
			local time4To2Str = Language:getInstance():getString("@CSTimeStage4To2Time");
			local time2To1Str = Language:getInstance():getString("@CSTimeStage2To1Time");

			container:getVarLabelBMFont("mTime1"):setString(time16To8Str);
			container:getVarLabelBMFont("mTime2"):setString(time8To4Str);
			container:getVarLabelBMFont("mTime3"):setString(time4To2Str);
			container:getVarLabelBMFont("mTime4"):setString(time2To1Str);

			ControllersHandler.setProgressBarState(container);

			--saishichakan button check
			if CSManager.WarStateCache.openState.battleId > 0 then
				local currentOpenStage = CSTools.getCurrentStage(CSManager.WarStateCache.openState.battleId);
				if (
					CSManager.Tools.numAGreaterOrEqualsToNumB(currentOpenStage, WAR_STAGE.PER_16TO8_STAGE) 
						and CSManager.Tools.numALessOrEqualsToNumB(currentOpenStage, WAR_STAGE.PER_2TO1_STAGE)
					) or
					(CSManager.Tools.numAGreaterOrEqualsToNumB(currentOpenStage, WAR_STAGE.CRO_16TO8_STAGE) 
						and CSManager.Tools.numALessOrEqualsToNumB(currentOpenStage, WAR_STAGE.CRO_2TO1_STAGE)
					) or
					(CSManager.Tools.numAEqualsToNumB(currentOpenStage, WAR_STAGE.REVIEW_STAGE))
				then
						container:getVarNode("mViewMatchNode"):setVisible(true);
						container:getVarLabelBMFont("mViewMatchTex"):setString(common:getLanguageString("@ViewMatch"))
				elseif CSTools.isKnockOutEnd(CSManager.WarStateCache.openState.battleId) then
					CrossServerWar.showMyGameBtn(container);
				else
						container:getVarNode("mViewMatchNode"):setVisible(false);
				end

				-- set progress visible
				if(CSManager.Tools.numAEqualsToNumB(currentOpenStage, WAR_STAGE.REVIEW_STAGE)) then
					container:getVarNode("mExpNode"):setVisible(false);
				else
					container:getVarNode("mExpNode"):setVisible(true);
				end
			end

		end
	end
	NodeHelper:setStringForLabel(container, {
		mNowDay1 = onDateStr1,
		mNowDay2 = onDateStr2,
		mNextDay = nextDateStr1
	})
end

--stage progress bar
function ControllersHandler.setProgressBarState( container )
	if CSManager.WarStateCache.openState.battleId > 0 then
	-- clear all progress bar
		container:getVarSprite("mExp"):setScale(0);
		container:getVarSprite("mExpPoint1"):setTexture(ProgressNodePic.closePic);
		container:getVarSprite("mExpPoint2"):setTexture(ProgressNodePic.closePic);
		container:getVarSprite("mExpPoint3"):setTexture(ProgressNodePic.closePic);
		container:getVarSprite("mExpPoint4"):setTexture(ProgressNodePic.closePic);

		local curProgressScale = 0;
		local tex16To8 = ProgressNodePic.closePic;
		local tex8To4 = ProgressNodePic.closePic;
		local tex4To2 = ProgressNodePic.closePic;
		local tex2To1 = ProgressNodePic.closePic;

		local currentBattleId = CSManager.WarStateCache.openState.battleId;

		local currentStage = CSTools.getCurrentStage(currentBattleId);

		if CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.PER_16TO8_STAGE) or CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.CRO_16TO8_STAGE) then
			curProgressScale = 0;
			tex16To8 = ProgressNodePic.openPic;
			tex8To4 = ProgressNodePic.closePic;
			tex4To2 = ProgressNodePic.closePic;
			tex2To1 = ProgressNodePic.closePic;
		end

		if CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.PER_8TO4_STAGE) or CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.CRO_8TO4_STAGE) then
			curProgressScale = 0.3;
			tex16To8 = ProgressNodePic.openPic;
			tex8To4 = ProgressNodePic.openPic;
			tex4To2 = ProgressNodePic.closePic;
			tex2To1 = ProgressNodePic.closePic;
		end

		if CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.PER_4TO2_STAGE) or CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.CRO_4TO2_STAGE) then
			curProgressScale = 0.68;
			tex16To8 = ProgressNodePic.openPic;
			tex8To4 = ProgressNodePic.openPic;
			tex4To2 = ProgressNodePic.openPic;
			tex2To1 = ProgressNodePic.closePic;
		end

		if CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.PER_2TO1_STAGE) or CSManager.Tools.numAEqualsToNumB(currentStage, WAR_STAGE.CRO_2TO1_STAGE) then
			curProgressScale = 1.0;
			tex16To8 = ProgressNodePic.openPic;
			tex8To4 = ProgressNodePic.openPic;
			tex4To2 = ProgressNodePic.openPic;
			tex2To1 = ProgressNodePic.openPic;
		end

		container:getVarSprite("mExp"):setScale(curProgressScale);
		container:getVarSprite("mExpPoint1"):setTexture(tex16To8);
		container:getVarSprite("mExpPoint2"):setTexture(tex8To4);
		container:getVarSprite("mExpPoint3"):setTexture(tex4To2);
		container:getVarSprite("mExpPoint4"):setTexture(tex2To1);
	end
end

function ControllersHandler.switchPageState( state )
	if state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
		if CSManager.Tools.checkValue(PageControllers.warCloseNode) then
			PageControllers.warCloseNode:setVisible(false);
		end

		if CSManager.Tools.checkValue(PageControllers.warOpenNode) then
			PageControllers.warOpenNode:setVisible(true);
		end

		if CSManager.Tools.checkValue(PageControllers.worshipNode) then
			PageControllers.worshipNode:setVisible(false);
		end
		
		if CSManager.Tools.checkValue(PageControllers.warNode) then
			PageControllers.warNode:setVisible(true);
		end
	elseif state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		if CSManager.Tools.checkValue(PageControllers.warCloseNode) then
			PageControllers.warCloseNode:setVisible(true);
		end

		if CSManager.Tools.checkValue(PageControllers.warOpenNode) then
			PageControllers.warOpenNode:setVisible(false);
		end

		if CSManager.Tools.checkValue(PageControllers.worshipNode) then
			PageControllers.worshipNode:setVisible(false);
		end
		
		if CSManager.Tools.checkValue(PageControllers.warNode) then
			PageControllers.warNode:setVisible(true);
		end
	elseif state == CSManager.PAGE_STATE.WORSHIP_STATE then
		if CSManager.Tools.checkValue(PageControllers.warCloseNode) then
			PageControllers.warCloseNode:setVisible(false);
		end

		if CSManager.Tools.checkValue(PageControllers.warOpenNode) then
			PageControllers.warOpenNode:setVisible(false);
		end

		if CSManager.Tools.checkValue(PageControllers.worshipNode) then
			PageControllers.worshipNode:setVisible(true);
		end
		
		if CSManager.Tools.checkValue(PageControllers.warNode) then
			PageControllers.warNode:setVisible(false);
		end
	end
end

function ControllersHandler.checkSignUpButtonState( container )
	--when sign up , set signup button visible
	local currentBattleId = CSManager.WarStateCache.closeState.battleId;

	if currentBattleId > 0 then
		if CSTools.timeAtStage(currentBattleId, WAR_STAGE.SIGNUP_STAGE) then
			container:getVarNode("mEnrollNode"):setVisible(true);
            container:getVarNode("mRegistrationNode"):setVisible(true)
		else
			container:getVarNode("mEnrollNode"):setVisible(false);
            container:getVarNode("mRegistrationNode"):setVisible(false)
		end
	end

	--set sign up label is update battle array or sign up
	local signUpStr = nil;
	if CSManager.WarStateCache.closeState.signUp then
		signUpStr = Language:getInstance():getString("@CSUpdateBattleArray");
	else
		signUpStr = Language:getInstance():getString("@CSSignUp");
	end
	container:getVarLabelBMFont("mEnrollTex"):setString(signUpStr);
end

-- refresh the page war state
function ControllersHandler.checkWarPageState( container )
	--page is open_war state
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
		local currentBattleId = CSManager.WarStateCache.openState.battleId;
		--check state will be close_war state
		if currentBattleId ~= nil and currentBattleId > 0 then
			if (not CSTools.openWarState(currentBattleId)) then
				TimerHandler.requireWarStateByTimer();
			end
		end
	end

	--page is close_war state
	if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_CLOSE_STATE then
		local currentBattleId = CSManager.WarStateCache.closeState.battleId;
		--check state will be open_war state
		if currentBattleId ~= nil and currentBattleId > 0 then
			if CSTools.openWarState(currentBattleId) then
				TimerHandler.requireWarStateByTimer();
			end
		end
	end
end

-- refresh the open war page
function ControllersHandler.refershOpenWarPage( container )
	if CSManager.WarStateCache.openState.battleId > 0 then
		if buildStateFlag ~= CSTools.getCurrentStage(CSManager.WarStateCache.openState.battleId) and (CSTools.getCurrentStage(CSManager.WarStateCache.openState.battleId) ~= nil) then
			--page is open_war state
			if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
				--check state is open_war state
				if (CSTools.openWarState(CSManager.WarStateCache.openState.battleId)) then
					TimerHandler.refershOpenWarInfo();
				end
			end

			buildStateFlag = CSTools.getCurrentStage(CSManager.WarStateCache.openState.battleId);
		end
	end
end

-- refresh the signup button
function ControllersHandler.refershSignButton( container )

	--**refresh war state cache
	CSManager.WarStateCache.closeState.signUp = true;
	local signUpStr = Language:getInstance():getString("@CSUpdateBattleArray");
	container:getVarLabelBMFont("mEnrollTex"):setString(signUpStr);
end
----------------------------worship state-----------------------------------
--init worship page state
function ControllersHandler.initWorshipPageControllersInfo(container)

	ControllersHandler.setWorshipControllersInfo(container);
end

function ControllersHandler.setWorshipControllersInfo( container )
	--can not click
	container:getVarMenuItemImage("mLWBtn"):setEnabled(false);
	container:getVarMenuItemImage("mIWBtn"):setEnabled(false);
	container:getVarMenuItemImage("mSWBtn"):setEnabled(false);

	--1.primary_level
	local primaryWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL);
	--cost
	local worshipCost = primaryWorshipItem.worshipCost;
	ControllersHandler.itemFormat( worshipCost, CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL,WORSHIP_TABLE_STATE.COST_STATE);
	local primaryCostStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL, WORSHIP_TABLE_STATE.COST_STATE);
	container:getVarLabelBMFont("mLWNum1"):setString(primaryCostStr);

	--rewards
	local worshipRewards = primaryWorshipItem.worshipReward;
	ControllersHandler.itemFormat( worshipRewards, CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL,WORSHIP_TABLE_STATE.REWARD_STATE);
	local primaryRewardsStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL, WORSHIP_TABLE_STATE.REWARD_STATE);
	container:getVarLabelBMFont("mLWNum2"):setString(primaryRewardsStr);

	--2.middle_level
	local middleWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL);
	--cost
	local worshipCostMiddle = middleWorshipItem.worshipCost;
	ControllersHandler.itemFormat( worshipCostMiddle, CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL,WORSHIP_TABLE_STATE.COST_STATE);
	local middleCostStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL, WORSHIP_TABLE_STATE.COST_STATE);
	container:getVarLabelBMFont("mIWNum1"):setString(middleCostStr);
	--rewards
	local worshipRewardsMiddle = middleWorshipItem.worshipReward;
	ControllersHandler.itemFormat( worshipRewardsMiddle, CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL,WORSHIP_TABLE_STATE.REWARD_STATE);
	local middleRewardsStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL, WORSHIP_TABLE_STATE.REWARD_STATE);
	container:getVarLabelBMFont("mIWNum2"):setString(middleRewardsStr);

	--3.advanced_level
	local advancedWorshipItem = CSManager.Tools.getCSWorshipItemByWorshipId(CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL);
	--cost
	local worshipCostAdvanced = advancedWorshipItem.worshipCost;
	ControllersHandler.itemFormat( worshipCostAdvanced, CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL,WORSHIP_TABLE_STATE.COST_STATE);
	local advancedCostStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL, WORSHIP_TABLE_STATE.COST_STATE);
	container:getVarLabelBMFont("mSWNum1"):setString(advancedCostStr);
	--rewards
	local worshipRewardsAdvanced = advancedWorshipItem.worshipReward;
	ControllersHandler.itemFormat( worshipRewardsAdvanced, CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL,WORSHIP_TABLE_STATE.REWARD_STATE);
	local advancedRewardsStr = ControllersHandler.itemString( CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL, WORSHIP_TABLE_STATE.REWARD_STATE);
	container:getVarLabelBMFont("mSWNum2"):setString(advancedRewardsStr);

	local currentWarCountStr = CSManager.WarStateCache.closeState.battleId;

	-- set jieshu label
	local currentCount = tonumber(currentWarCountStr);
	if CSManager.Tools.checkValue(container:getVarSprite("mTitleNumSubTitle1")) then
		--[[
		if currentCount > 10 then
			if currentCount < 100 then
				container:getVarNode("mTitleNode2"):setVisible(false);
				container:getVarNode("mTitleNode4"):setVisible(true);
				
				local countA =math.floor(currentCount / 10);
				local countB = currentCount % 10;
						


				if countA == 1 then
					countA = 10;
				end 
				
				local picStr1 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countA..".png";
				local picStr2 = "UI/CrossServerWar/u_CrossServerWarTitleNum"..countB..".png";
				container:getVarSprite("mTitleNumSub3"):setTexture(picStr1);
				container:getVarSprite("mTitleNumSub4"):setTexture(picStr2);
						
			end
		else
			container:getVarNode("mTitleNode2"):setVisible(true);
			container:getVarNode("mTitleNode4"):setVisible(false);
			local picStr = "UI/CrossServerWar/u_CrossServerWarTitleNum"..currentWarCountStr..".png";
			container:getVarSprite("mTitleNum2"):setTexture(picStr);
		end]]
		container:getVarNode("mTitleNode1"):setVisible(true);
		container:getVarLabelTTF("mTitleNumSubTitle1"):setString(common:getLanguageString("@CSTimeOfCS",currentCount))
	end

end

--rOrC:rewards or cost
function ControllersHandler.itemFormat( itemStr, worshipLevel, rOrC)

	--clear before info
	if worshipLevel == CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			WorshipRewards.primary = {};
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			WorshipCost.primary = {};
		end
	end

	if worshipLevel == CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			WorshipRewards.middle = {};
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			WorshipCost.middle = {};
		end
	end

	if worshipLevel == CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			WorshipRewards.advanced = {};
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			WorshipCost.advanced = {};
		end
	end

	local item = Split(itemStr, ",", 3);
	for i = 1, table.maxn(item), 1 do
		local items = ConfigManager.parseItemOnlyWithUnderline(item[i])--Split(item[i], "_", 3);

		if worshipLevel == CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL then
			if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
				WorshipRewards.primary[i] = {};
				WorshipRewards.primary[i].itemType = items.type;
				WorshipRewards.primary[i].itemId = items.itemId;
				WorshipRewards.primary[i].counts = items.count;
			end

			if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
				WorshipCost.primary[i] = {};
				WorshipCost.primary[i].itemType = items.type;
				WorshipCost.primary[i].itemId = items.itemId;
				WorshipCost.primary[i].counts = items.count;
			end
		end

		if worshipLevel == CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL then
			if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
				WorshipRewards.middle[i] = {};
				WorshipRewards.middle[i].itemType = items.type;
				WorshipRewards.middle[i].itemId = items.itemId;
				WorshipRewards.middle[i].counts = items.count;
			end

			if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
				WorshipCost.middle[i] = {};
				WorshipCost.middle[i].itemType = items.type;
				WorshipCost.middle[i].itemId = items.itemId;
				WorshipCost.middle[i].counts = items.count;
			end
		end

		if worshipLevel == CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL then
			if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
				WorshipRewards.advanced[i] = {};
				WorshipRewards.advanced[i].itemType = items.type;
				WorshipRewards.advanced[i].itemId = items.itemId;
				WorshipRewards.advanced[i].counts = items.count;
			end

			if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
				WorshipCost.advanced[i] = {};
				WorshipCost.advanced[i].itemType = items.type;
				WorshipCost.advanced[i].itemId = items.itemId;
				WorshipCost.advanced[i].counts = items.count;
			end
		end

	end
end

--rOrC:rewards or cost
function ControllersHandler.itemString( worshipLevel, rOrC)
	local str = "";
	local itemsTable = {};


	if worshipLevel == CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			itemsTable = WorshipRewards.primary;
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			itemsTable = WorshipCost.primary;
		end
	end

	if worshipLevel == CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			itemsTable = WorshipRewards.middle;
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			itemsTable = WorshipCost.middle;
		end
	end

	if worshipLevel == CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL then
		if rOrC == WORSHIP_TABLE_STATE.REWARD_STATE then
			itemsTable = WorshipRewards.advanced;
		end

		if rOrC == WORSHIP_TABLE_STATE.COST_STATE then
			itemsTable = WorshipCost.advanced;
		end
	end

	for i = 1, table.maxn(itemsTable), 1 do
        
		local itemTemp = ResManagerForLua:getResInfoByTypeAndId(tonumber(itemsTable[i].itemType),tonumber(itemsTable[i].itemId),tonumber(itemsTable[i].counts));
		str = str .. itemTemp.name.."?"..itemTemp.count.." ";
	end

	return str;
end


function ControllersHandler.refreshWorshipState( container )
	--primary worship button
	if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipStateCache.primaryState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL) then
		container:getVarMenuItemImage("mLWBtn"):setEnabled(true);
	else
		container:getVarMenuItemImage("mLWBtn"):setEnabled(false);
	end
	--middle worship button
	if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipStateCache.middleState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL) then 
		container:getVarMenuItemImage("mIWBtn"):setEnabled(true);
	else
		container:getVarMenuItemImage("mIWBtn"):setEnabled(false);
	end
	--advanced worship button
	if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipStateCache.advancedState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL) then
		container:getVarMenuItemImage("mSWBtn"):setEnabled(true);
	else
		container:getVarMenuItemImage("mSWBtn"):setEnabled(false);
	end
end

function ControllersHandler.refershWorshipButtons( container )

	if CSManager.WorshipRewardCache.worshipType == CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL then
		--primary worship button
		if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipRewardCache.worshipState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.PRIMARY_LEVEL) then
			container:getVarMenuItemImage("mLWBtn"):setEnabled(true);
		else
			container:getVarMenuItemImage("mLWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mIWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mSWBtn"):setEnabled(false);
		end
	end

	if CSManager.WorshipRewardCache.worshipType == CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL then
		--middle worship button
		if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipRewardCache.worshipState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.MIDDLE_LEVEL) then
			container:getVarMenuItemImage("mIWBtn"):setEnabled(true);
		else
			container:getVarMenuItemImage("mLWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mIWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mSWBtn"):setEnabled(false);
		end
	end

	if CSManager.WorshipRewardCache.worshipType == CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL then
		--advanced worship button
		if CSManager.Tools.numAEqualsToNumB(CSManager.WorshipRewardCache.worshipState, WORSHIP_GET_STATE.NOT_GET_STATE) and CSManager.Tools.checkWorshipMoneyEnough(CSManager.WORSHIP_LEVEL.ADVANCED_LEVEL) then
			container:getVarMenuItemImage("mSWBtn"):setEnabled(true);
		else
			container:getVarMenuItemImage("mLWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mIWBtn"):setEnabled(false);
			container:getVarMenuItemImage("mSWBtn"):setEnabled(false);
		end
	end

end

--1000. Timer
function TimerHandler.requireWarStateByTimer()
	--if Timer not exist, create
	if (not WarStateTimer.timerExist) then
		WarStateTimer.timerName = "WarStateTimer_" .. ADVENTURE_CONTAINER.ID;
		--create Timer
		TimeCalculator:getInstance():createTimeCalcultor(WarStateTimer.timerName, WarStateTimer.defaultTime);
		--timer exist flag be true
		WarStateTimer.timerExist = true;
	end
end

function TimerHandler.refreshWarStateTimer( container )

	if not TimeCalculator:getInstance():hasKey(WarStateTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(WarStateTimer.timerName)
	--when more than 1 second, add 1
	--if CSManager.Tools.numAGreaterThanNumB( leftTime + 1, WarStateTimer.defaultTime ) then
	--	return
	--end

	WarStateTimer.defaultTime = leftTime;

	if CSManager.Tools.numALessOrEqualsToNumB(WarStateTimer.defaultTime, 0) then
		WarStateTimer.defaultTime = 0
	end

	if CSManager.Tools.numAEqualsToNumB(WarStateTimer.defaultTime, 0) then
		--1. require war state info
		CSManager.PacketHandler.requireWarState(container)
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(WarStateTimer.timerName);
		--3. timer exist flag be false
		WarStateTimer.timerExist = false;
		WarStateTimer.defaultTime = 10;
	end
end

--refresh open war info
function TimerHandler.refershOpenWarInfo()
	if (not OpenWarStateTimer.timerExist) then
		OpenWarStateTimer.timerName = "OpenWarStateTimer_"..ADVENTURE_CONTAINER.ID;
		TimeCalculator:getInstance():createTimeCalcultor(OpenWarStateTimer.timerName,OpenWarStateTimer.defaultTime);
		OpenWarStateTimer.timerExist = true;
	end
end

function TimerHandler.refreshOpenWarPageInfo( container )
	if not TimeCalculator:getInstance():hasKey(OpenWarStateTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(OpenWarStateTimer.timerName)

	--when more than 1 second, add 1
--	if CSManager.Tools.numAGreaterThanNumB( leftTime + 1, OpenWarStateTimer.defaultTime ) then
	--	return
	--end

	OpenWarStateTimer.defaultTime = leftTime;

	if CSManager.Tools.numALessOrEqualsToNumB(OpenWarStateTimer.defaultTime, 0) then
		OpenWarStateTimer.defaultTime = 0
	end

	-- timer end ,call function
	if CSManager.Tools.numAEqualsToNumB(OpenWarStateTimer.defaultTime, 0) then
		--1. require war state info
		ControllersHandler.setWarOpenControllersInfo(container);
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(OpenWarStateTimer.timerName);
		--3. timer exist flag be false
		OpenWarStateTimer.timerExist = false;
		OpenWarStateTimer.defaultTime = 0;
	end
end


function TimerHandler.createOneTimer( leftTime, container)
	--remove before timer
	TimeCalculator:getInstance():removeTimeCalcultor(OngoingOneTimer.timerName);
	--create new timer
	TimerHandler.createOngoingOneTimer(leftTime,container);
end

function TimerHandler.createTwoTimer( leftTime, container)
	--remove before timer
	TimeCalculator:getInstance():removeTimeCalcultor(OngoingTwoTimer.timerName);
	--create new timer
	TimerHandler.createOngoingTwoTimer(leftTime,container);
end


function TimerHandler.createOngoingOneTimer( leftTime, container)
	OngoingOneTimer.defaultTime = leftTime;
	OngoingOneTimer.timerContainer = container:getVarLabelBMFont("mNowTime1");

	if OngoingOneTimer.timerContainer == nil then return end;

	if OngoingOneTimer.defaultTime > 0 then
		OngoingOneTimer.timerName = "OngoingOneTimer_"..ADVENTURE_CONTAINER.ID;
		OngoingOneTimer.timerContainer:retain();
		TimeCalculator:getInstance():createTimeCalcultor(OngoingOneTimer.timerName, OngoingOneTimer.defaultTime)
		OngoingOneTimer.timerExist = true;
		TimerHandler.setOneTimerString();
	else
		OngoingOneTimer.timerContainer:setString("")
	end
end

function TimerHandler.createOngoingTwoTimer( leftTime, container)
	OngoingTwoTimer.defaultTime = leftTime;
	OngoingTwoTimer.timerContainer = container:getVarLabelBMFont("mNowTime2");

	if OngoingTwoTimer.timerContainer == nil then return end;

	if OngoingTwoTimer.defaultTime > 0 then
		OngoingTwoTimer.timerName = "OngoingTwoTimer_"..ADVENTURE_CONTAINER.ID;
		OngoingTwoTimer.timerContainer:retain();
		TimeCalculator:getInstance():createTimeCalcultor(OngoingTwoTimer.timerName, OngoingTwoTimer.defaultTime)
		OngoingTwoTimer.timerExist = true;
		TimerHandler.setTwoTimerString();
	else
		OngoingTwoTimer.timerContainer:setString("")
	end
end

function TimerHandler.ongoingTimerOne(container)
	if not TimeCalculator:getInstance():hasKey(OngoingOneTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(OngoingOneTimer.timerName)
	if leftTime + 1 > OngoingOneTimer.defaultTime then
		return
	end

	OngoingOneTimer.defaultTime = leftTime
	if OngoingOneTimer.defaultTime <= 0 then
		OngoingOneTimer.defaultTime = 0
		TimeCalculator:getInstance():removeTimeCalcultor(OngoingOneTimer.timerName);
		OngoingOneTimer.timerExist = false;
	end

	TimerHandler.setOneTimerString();
end

function TimerHandler.ongoingTimerTwo( container )

	if not TimeCalculator:getInstance():hasKey(OngoingTwoTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(OngoingTwoTimer.timerName)
	if leftTime + 1 > OngoingTwoTimer.defaultTime then
		return
	end

	OngoingTwoTimer.defaultTime = leftTime
	if OngoingTwoTimer.defaultTime <= 0 then
		OngoingTwoTimer.defaultTime = 0
		TimeCalculator:getInstance():removeTimeCalcultor(OngoingTwoTimer.timerName);
		OngoingTwoTimer.timerExist = false;
	end

	TimerHandler.setTwoTimerString();
end

function TimerHandler.setOneTimerString()
	if OngoingOneTimer.timerContainer ~= nil then
		local timeStr = TimerHandler.secondsToTimeStr(OngoingOneTimer.defaultTime)
		OngoingOneTimer.timerContainer:setString(timeStr)
	end
end

function TimerHandler.setTwoTimerString()
	if OngoingTwoTimer.timerContainer ~= nil then
		local timeStr = TimerHandler.secondsToTimeStr(OngoingTwoTimer.defaultTime)
		OngoingTwoTimer.timerContainer:setString(timeStr)
	end
end

function TimerHandler.secondsToTimeStr(second)
	return second <= 0 and "" or common:getLanguageString("@CSTimeLeft", GameMaths:formatSecondsToTime(second))
end

function TimerHandler.removeTwoTimer()
	TimeCalculator:getInstance():removeTimeCalcultor(OngoingOneTimer.timerName);
	TimeCalculator:getInstance():removeTimeCalcultor(OngoingTwoTimer.timerName);
end

--Animation handler
function CrossServerWar.runContinueAnimation( container )
    local eventName=tostring(container:getCurAnimationDoneName())
    if eventName == "starAni" then
	    container:runAnimation("ContinueAni");
    elseif eventName == "GetInto" then
        PageControllers.warCloseNode:setVisible( true )
    elseif eventName == "Enter" then
        if CSManager.WarStateCache.state == CSManager.PAGE_STATE.WAR_OPEN_STATE then
            PageControllers.warCloseNode:setVisible( false )
        end
    end
end
