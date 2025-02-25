
--------------------------------------------------------------------------------

--require the other module
require "CsBattle_pb"
require "CSBattleRewardPage"
local CSTools = require("CSTools")
local CommonPage = require("CommonPage");
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local RoleCfg = ConfigManager.getRoleCfg()

--register the other module
registerScriptPage('CrossServerWarDisplayBet')
registerScriptPage("CSBattleListPage")


-- global variable
CrossServerWarDisplayGlobal = {
	playerIdentify = nil,
	battleId = nil
};

--current adventure container
local ADVENTURE_CONTAINER = {
	ID = 49,
	TAG = nil
};

-- war state contronller
local buildStateFlag = -1;

-- bet button controller
local centerButtonRefreshKey = true;
local titleRefreshKey = true;

--protobuf container
local PROTOBUF_CONTAINER = {
	OPCODE_CS_WARINFO_C = HP_pb.OPCODE_CS_WARINFO_C,--war view info
	OPCODE_CS_WARINFO_S = HP_pb.OPCODE_CS_WARINFO_S,
	--OPCODE_CS_BET_CLICK_C = 2017;
	--OPCODE_CS_BET_CLICK_S = 2018;
	OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S,
	OPCODE_CS_REFRESH_BATTLEARRAY_C = HP_pb.OPCODE_CS_REFRESH_BATTLEARRAY_C,--update the battle array info
	OPCODE_CS_REFRESH_BATTLEARRAY_S = HP_pb.OPCODE_CS_REFRESH_BATTLEARRAY_S
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

-- center button stage
local CENTER_BUTTON_STAGE = {
	BET_STAGE = 1,
	BATTLE_STAGE = 2,
	REVIEW_STAGE = 3
};

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

--battle state timer
local BattleStateTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
};

local Battle16To8StateTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
};

local BattleArrayAndTitleTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
};

local BattleTitleTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
}

local BattleListWinerOrLoserTimer = {
	timerName = nil,
	timerContainer = nil,
	timerExist = false,
	defaultTime = 1
};


-- select battle list
local BATTLE_LIST = {
	WINNER_LIST = 1,
	LOSER_LIST = 2
};
--packet cache
local BattleViewCache = {
	playerIdentify = nil,
	winPlayers = {},
	losePlayers = {},
	betPlayer = nil
};


--winner or loser display
local WINNER_SHOW = true;

--function table
local CrossServerWarDisplay = {};
local PacketHandler = {};
local Tools = {};
local ControllersHandler = {};
local CacheHandler = {};
local TimerHandler = {};

-- all cells controllers
local AllCellsControllers = {};

--battle list controllers
local BattleListControllers = {
	mScrollView = nil,
	mRootNode = nil,
	mScrollViewFacade = nil
}

--left or right win
local WINNER_DIRECTION = {
	LEFT_WIN = 1,
	RIGHT_WIN = 2
};

--bet,battling,review
local CURRENT_DETAIL_STAGE = {
	BET_STAGE = 1,
	BATTLE_STAGE = 2,
	REVIEW_STAGE = 3
}

local currentDetailStage = nil;


-- win or lose pic
local VSPIC = {
	RIGHT_PIC = "UI/CrossServerWar/u_CrossServerWarBPRewardBG01.png",
	LEFT_PIC = "UI/CrossServerWar/u_CrossServerWarBPRewardBG00.png",
	LOSE_RIGHT_PIC = "UI/CrossServerWar/u_CrossServerWarBPRewardBG01B.png",
	LOSE_LEFT_PIC = "UI/CrossServerWar/u_CrossServerWarBPRewardBG00B.png"
};

-- title pic
local TITLE_PIC = {
	PIC_16 = "UI/CrossServerWar/u_CrossServerWarEventsTex16.png",
	PIC_8 = "UI/CrossServerWar/u_CrossServerWarEventsTex8.png",
	PIC_4 = "UI/CrossServerWar/u_CrossServerWarEventsTex4.png",
	PIC_2 = "UI/CrossServerWar/u_CrossServerWarEventsTex2.png"
};

--no player pic
local NO_PLAYER_PIC = "UI/CrossServerWar/u_ico000.png";

--function table
local functionNameHandlerMap = {
	luaLoad = "onLoad",
	luaInit = "onInit",
	luaEnter = "onEnter",
	luaExecute = "onExecute",
	luaUnload = "onUnload",
	luaExit = "onExit",
	luaReceivePacket = "onReceivePacket",
	onImperialBtn = "showWinnerList",
	onSupernovaBtn = "showLoserList",
	onMyGame = "backToMain",
	onMyGameBtn = "showMyGame",
	onMyBottomPourBtn = "showMyBet",
	onUpdateTeamBtn = "commitBattleArrayInfo",
	luaGameMessage = "onGameMessage"
};

function luaCreat_CrossServerWarDisplay( container )
	CCLuaLog("luaCreat_CrossServerWar");
	container:registerFunctionHandler(CrossServerWarDisplay.onFunction);
end

function CrossServerWarDisplay.onFunction( eventName, container )
	local funcName = functionNameHandlerMap[eventName];

	if Tools.checkValue(funcName) then
		CrossServerWarDisplay[funcName](container);
	else
		CCLuaLog("unExpected eventName : ".. eventName);
	end
end

function CrossServerWarDisplay.onLoad( container )
	CCLuaLog("#Z:CrossServerWarDisplay onLoad!");
	container:loadCcbiFile("CrossServerWarEventView.ccbi");
end

function CrossServerWarDisplay.onInit( container )

end

function CrossServerWarDisplay.onEnter( container )
	ControllersHandler.getAllControllers(container);
	ControllersHandler.setAllControllersNotDisplay(container);
	PacketHandler.registerAllPackets(container);
	PacketHandler.requireBattleViewMSG(container);
	--ControllersHandler.checkTitleAndBattleArrayBtn(container)
	container:getVarMenuItemImage("mUpdateTeamBtn"):setEnabled(false);
	ControllersHandler.setTitles(container);
	container:registerMessage(MSG_MAINFRAME_POPPAGE);--register pop page
    local CSManager = require("PVP.CSManager")

    --container:getVarLabelBMFont("mPromotionLab"):setString( CSManager.getCurrentStageString() )
end

function CrossServerWarDisplay.onExecute( container )


	-- bet/battle/review refresh
	--if (not BattleStateTimer.timerExist) and Tools.detailStageHasChanged() then
	if (not BattleStateTimer.timerExist) then
		ControllersHandler.refreshBattleStateByTimer(container);
	end

	if BattleStateTimer.timerExist then
		TimerHandler.refreshBattleState(container);
	end

	-- 16->8,8->4...stage
	if (not Battle16To8StateTimer.timerExist) then
		ControllersHandler.refresh16To8StateByTimer(container);
	end

	if Battle16To8StateTimer.timerExist then
		TimerHandler.refresh16To8State(container);
	end

	--refresh title and battlearray button
	--***now the title refresh by other timer
	--if (not BattleArrayAndTitleTimer.timerExist) then
		ControllersHandler.refreshTitleAndBattleArrayBtnByTimer(container);
	--end

	--if BattleArrayAndTitleTimer.timerExist then
		--TimerHandler.refreshTitleAndBattleArrayBtn(container);
	--end

	--refresh title
	if (not BattleTitleTimer.timerExist) then
		ControllersHandler.refreshTitleByTimer(container);
	end

	if BattleTitleTimer.timerExist then
		TimerHandler.refreshTitle(container);
	end

	--refresh the winer or loser list
	if (not BattleListWinerOrLoserTimer.timerExist) then
		if CrossServerWarDisplayGlobal.battleId > 0 then
			if CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
				ControllersHandler.refreshBattleListWinnerOrLoserByTimer(container);
			end
		end
	end

	if BattleListWinerOrLoserTimer.timerExist then
		TimerHandler.refreshBattleListWinnerOrLoser(container);
	end

	--the war ended, close the page
	if CrossServerWarDisplayGlobal.battleId > 0 then
		if CSTools.battleReviewEnded(CrossServerWarDisplayGlobal.battleId) then
			CrossServerWarDisplay.backToMain(container);
		end
	end
end

function CrossServerWarDisplay.onUnload( container )

end

function CrossServerWarDisplay.onExit( container )
	--clear state flag
	buildStateFlag = -1;
	AllCellsControllers = {};
	ControllersHandler.clearAllItems();
	PacketHandler.removeAllPackets(container);
end

function CrossServerWarDisplay.onReceivePacket( container )
	local code = container:getRecPacketOpcode();

	if code == PROTOBUF_CONTAINER.OPCODE_CS_WARINFO_S then
		local msg = CsBattle_pb.OPCSBattleRequestStageInfoRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		--cache the msg
		CacheHandler.cacheBattleListInfoMSG(msg);

		--get bet flag
		CrossServerWarDisplayBetGlobalVariable.betPlayer = BattleViewCache.betPlayer;
		--Only state change just refresh the page, but review state also rebuild

			if (buildStateFlag == -1) or (BattleViewCache.battleStage ~= -1 and buildStateFlag ~= BattleViewCache.battleStage) or (CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId)) then
			--select winner list
				if WINNER_SHOW then
					ControllersHandler.setBattleListButtonState(container, BATTLE_LIST.WINNER_LIST);
				else--select loser list
					ControllersHandler.setBattleListButtonState(container, BATTLE_LIST.LOSER_LIST);
				end

				ControllersHandler.rebuildBattleList();
				ControllersHandler.checkBattleState();
				buildStateFlag = BattleViewCache.battleStage;
			end

		--refresh center button flag
		if (not CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId)) then
			centerButtonRefreshKey = true;
		else
			centerButtonRefreshKey = false;
		end
		-- refresh title flag
		titleRefreshKey = true;

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
	elseif code == PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S then
		local msg = CsBattle_pb.OPCSBattleUpdateBattleArrayRet();
		local msgBuffer = container:getRecPacketBuffer();
		msg:ParseFromString(msgBuffer);

		if msg.resultOK then
			MessageBoxPage:Msg_Box("@CSRefershBattleArraySuccess");
		else
			MessageBoxPage:Msg_Box("@CSRefershBattleArrayFailed");
		end
	end
end

function CrossServerWarDisplay.commitBattleArrayInfo( container )
    PageManager.showConfirm( common:getLanguageString("@CSRefreshBattArrayTitle") ,common:getLanguageString("@CSRefreshBattArrayContent") , PacketHandler.requireRefreshBattleArray )
	--PacketHandler.requireRefreshBattleArray(container);
end

function CrossServerWarDisplay.showWinnerList( container )
	centerButtonRefreshKey = true;
	ControllersHandler.setBattleListButtonState(container, BATTLE_LIST.WINNER_LIST)
	ControllersHandler.switchBattleWinnerOrLoserList(BATTLE_LIST.WINNER_LIST);
end

function CrossServerWarDisplay.showLoserList( container )
	centerButtonRefreshKey = true;
	ControllersHandler.setBattleListButtonState(container, BATTLE_LIST.LOSER_LIST)
	ControllersHandler.switchBattleWinnerOrLoserList(BATTLE_LIST.LOSER_LIST);
end

function CrossServerWarDisplay.backToMain( container )
    PageManager.changePage("CrossServerWar")
end

function CrossServerWarDisplay.showMyGame( container )
	BattleList.setType(CrossServerWarDisplayGlobal.battleId, BattleList.Type_MyBattle)
	PageManager.pushPage("CSBattleListPage")
end

function CrossServerWarDisplay.showMyBet( container )
	PageManager.hideCover("CrossServerWarDisplay")
	CSBattle_ShowMyBet(CrossServerWarDisplayGlobal.battleId)
end

function CrossServerWarDisplay.onGameMessage( container )
	local message = container:getMessage()
	if message:getTypeId() == MSG_MAINFRAME_POPPAGE --[[MSG_MAINFRAME_CHANGEPAGE]] then
		local pageName = MsgMainFramePopPage:getTrueType(message).pageName
		if pageName == "CrossServerWarDisplayBet" then -- return from luckyprize rank page
			ControllersHandler.refreshWinnerFlag();
		end

	end
end

--888. param mark : controllers handler
function ControllersHandler.refreshWinnerFlag()
	for i = 1, table.maxn(AllCellsControllers) do
		local cellContainer = AllCellsControllers[i];
		local cellInfo = nil;
		local id = cellContainer:getItemDate().mID;

		--select winner list
		if WINNER_SHOW then
			cellInfo = BattleViewCache.winPlayers[id];
		else--select loser list
			cellInfo = BattleViewCache.losePlayers[id];
		end

		--set bet player
		local leftPicFlag = false;
		local rightPicFlag = false;
		if string.len(cellInfo.player1.playerIdentify) > 0 and (cellInfo.player1.playerIdentify == CrossServerWarDisplayBetGlobalVariable.betPlayer) then
			leftPicFlag = true;
			rightPicFlag = false;
		end

		if string.len(cellInfo.player2.playerIdentify) > 0 and cellInfo.player2.playerIdentify == CrossServerWarDisplayBetGlobalVariable.betPlayer then
			leftPicFlag = false;
			rightPicFlag = true;
		end

		cellContainer:getVarSprite("mLeftPic"):setVisible(leftPicFlag);
		cellContainer:getVarSprite("mRightPic"):setVisible(rightPicFlag);
	end
end

function ControllersHandler.getAllControllers( container )
	BattleListControllers.mScrollView = container:getVarScrollView("mEventViewSV");

	if Tools.checkValue(BattleListControllers.mScrollView) then
		BattleListControllers.mRootNode = BattleListControllers.mScrollView:getContainer();
		BattleListControllers.mScrollViewFacade = CCReViScrollViewFacade:new(BattleListControllers.mScrollView);
		BattleListControllers.mScrollViewFacade:init(6,6);
	end
    if BattleListControllers.mScrollView ~= nil then
		container:autoAdjustResizeScrollview( BattleListControllers.mScrollView )
	end
	
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
end

function ControllersHandler.setAllControllersNotDisplay( container )

end

function ControllersHandler.setBattleListButtonState( container, switch )
	if switch == BATTLE_LIST.WINNER_LIST then
		container:getVarMenuItemImage("mImperialBtn"):selected();
		container:getVarMenuItemImage("mSupernovaBtn"):unselected();
	end

	if switch == BATTLE_LIST.LOSER_LIST then
		container:getVarMenuItemImage("mSupernovaBtn"):selected();
		container:getVarMenuItemImage("mImperialBtn"):unselected();
	end
end

function ControllersHandler.rebuildBattleList()
	ControllersHandler.clearAllItems();
	AllCellsControllers ={};
	ControllersHandler.buildBattleList();
end

function ControllersHandler.clearAllItems()
	if Tools.checkValue(BattleListControllers.mScrollViewFacade) then
		BattleListControllers.mScrollViewFacade:clearAllItems();
	end
	if Tools.checkValue(BattleListControllers.mRootNode) then
		BattleListControllers.mRootNode:removeAllChildren();
	end
end

function ControllersHandler.buildBattleList()
	local iMaxNode = BattleListControllers.mScrollViewFacade:getMaxDynamicControledItemViewsNum();
	local iCount = 0;
	local fOneItemHeight = 0;
	local fOneItemWidth = 0;

	local cellsCount = 0;
	--display winner
	if WINNER_SHOW then
		cellsCount = table.maxn(BattleViewCache.winPlayers);
	else -- display loser
		cellsCount = table.maxn(BattleViewCache.losePlayers);
	end

		for i = 1, cellsCount, 1 do
			local pItemData = CCReViSvItemData:new();
			pItemData.mID = i;
			pItemData.m_iIdx = iCount;
			pItemData.m_ptPosition = ccp(0,fOneItemHeight*iCount);

			if iCount < iMaxNode then
				local pItem = ScriptContentBase:create("CrossServerWarEventViewContent.ccbi");

				pItem.id = iCount;
				pItem:registerFunctionHandler(ControllersHandler.createCellCallFunc);

				if fOneItemHeight < pItem:getContentSize().height then
					fOneItemHeight = pItem:getContentSize().height
				end

				if fOneItemWidth < pItem:getContentSize().width then
					fOneItemWidth = pItem:getContentSize().width
				end
				BattleListControllers.mScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)

			else
				BattleListControllers.mScrollViewFacade:addItem(pItemData)
			end
			iCount = iCount + 1;
		end

		local size = CCSizeMake(fOneItemWidth, fOneItemHeight*iCount)
		BattleListControllers.mScrollView:setContentSize(size);
		BattleListControllers.mScrollView:setContentOffset(ccp(0, BattleListControllers.mScrollView:getViewSize().height - BattleListControllers.mScrollView:getContentSize().height*BattleListControllers.mScrollView:getScaleY()));
		BattleListControllers.mScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
		BattleListControllers.mScrollView:forceRecaculateChildren();
		ScriptMathToLua:setSwallowsTouches(BattleListControllers.mScrollView)
end

function ControllersHandler.createCellCallFunc( eventName, container )
	CCLuaLog("Z#: createCellCallFunc");

	if eventName == "luaRefreshItemView" then
		ControllersHandler.createCell(container);
	elseif eventName == "onChargeBtn" then
		ControllersHandler.clickBetButton(container);
	elseif eventName == "onReplayBtn" then
		ControllersHandler.clickReplayButton(container);
	elseif eventName == "onLeftFrame" then
		ControllersHandler.clickLeftPlayer(container);
	elseif eventName == "onRightFrame" then
		ControllersHandler.clickRightPlayer(container);
	end
end

--battle state change 1.bet 2.battleing 3.review
function ControllersHandler.changeCenterButtonState( stage)
	local betButtonVis = false;
	local battleButtonVis = false;
	local reviewButtonVis = false;

	if stage == CENTER_BUTTON_STAGE.BET_STAGE then
		betButtonVis = true;
		battleButtonVis = false;
		reviewButtonVis = false;
	elseif stage == CENTER_BUTTON_STAGE.BATTLE_STAGE then
		betButtonVis = false;
		battleButtonVis = true;
		reviewButtonVis = false;
	elseif stage == CENTER_BUTTON_STAGE.REVIEW_STAGE then
		betButtonVis = false;
		battleButtonVis = false;
		reviewButtonVis = true;
	end

	for i = 1, table.maxn(AllCellsControllers) do
		AllCellsControllers[i]:getVarNode("mChargeNode"):setVisible(betButtonVis);
		AllCellsControllers[i]:getVarNode("mPlayingNode"):setVisible(battleButtonVis);
		AllCellsControllers[i]:getVarNode("mReplayNode"):setVisible(reviewButtonVis);

		if CrossServerWarDisplayBetGlobalVariable.betPlayer ~= nil and CrossServerWarDisplayBetGlobalVariable.betPlayer ~= "" then
			AllCellsControllers[i]:getVarMenuItemImage("mChargeBtn"):setEnabled(false);
		else
			AllCellsControllers[i]:getVarMenuItemImage("mChargeBtn"):setEnabled(true);
		end
	end

end

function ControllersHandler.switchBattleWinnerOrLoserList( state )
	if state == BATTLE_LIST.WINNER_LIST then
		WINNER_SHOW = true;
	elseif state == BATTLE_LIST.LOSER_LIST then
		WINNER_SHOW = false;
	end

	ControllersHandler.rebuildBattleList();
end

function ControllersHandler.clickBetButton( container )
	local cellInfo = nil;
	local id = container:getItemDate().mID;

	--select winner list
	if WINNER_SHOW then
		cellInfo = BattleViewCache.winPlayers[id];
	else--select loser list
		cellInfo = BattleViewCache.losePlayers[id];
	end

	CrossServerWarDisplayBetGlobalVariable.PlayerVSInfo = Tools.deepcopy(cellInfo);
	if CrossServerWarDisplayBetGlobalVariable.firstFlag then
		CrossServerWarDisplayBetGlobalVariable.betPlayer = BattleViewCache.betPlayer;
	end
	CrossServerWarDisplayBetGlobalVariable.playerIdentify = CrossServerWarDisplayGlobal.playerIdentify;
	CrossServerWarDisplayBetGlobalVariable.battleId = CrossServerWarDisplayGlobal.battleId;

	local msg = MsgMainFramePushPage:new();
	msg.pageName = "CrossServerWarDisplayBet"
	MessageManager:getInstance():sendMessageForScript(msg);

end

function ControllersHandler.clickReplayButton( container )
	local cellInfo = nil;
	local id = container:getItemDate().mID;

	--select winner list
	if WINNER_SHOW then
		cellInfo = BattleViewCache.winPlayers[id];
	else--select loser list
		cellInfo = BattleViewCache.losePlayers[id];
	end
	BattleList.setVSInfo(cellInfo, CrossServerWarDisplayGlobal.playerIdentify)
	PageManager.pushPage("CSBattleListPage")
end

function ControllersHandler.createCell( container )

	local maxIndex = table.maxn(AllCellsControllers);
	AllCellsControllers[maxIndex + 1] = container;

	local cellInfo = nil;
	local id = container:getItemDate().mID;

	--select winner list
	if WINNER_SHOW then
		cellInfo = BattleViewCache.winPlayers[id];
	else--select loser list
		cellInfo = BattleViewCache.losePlayers[id];
	end

	--set left player info
	container:getVarLabelTTF("mLeftPlayerName"):setString(cellInfo.player1.playerName);
	container:getVarLabelBMFont("mLeftServer"):setString(cellInfo.player1.serverName);
	local discipleLeftPic = RoleCfg[cellInfo.player1.playerItemId].icon
	if Tools.checkValue(discipleLeftPic) then
		container:getVarSprite("mLeftMem"):setTexture(discipleLeftPic);
	end

	local leftPlayerFrame = container:getVarMenuItemImage("mLeftFrame");
	--NodeHelper:setFrameQuality(leftPlayerFrame, leftDisciple.quality)

	--set right player info

	if cellInfo.player2.playerItemId ~= 0 then
		container:getVarLabelTTF("mRightPlayerName"):setString(cellInfo.player2.playerName);
		container:getVarLabelBMFont("mRightServer"):setString(cellInfo.player2.serverName);
		local discipleRightPic = RoleCfg[cellInfo.player2.playerItemId].icon
		if Tools.checkValue(discipleRightPic) then
			container:getVarSprite("mRightMem"):setTexture(discipleRightPic);
		end

		local rightPlayerFrame = container:getVarMenuItemImage("mRightFrame");
		--NodeHelper:setFrameQuality(rightPlayerFrame, rightDisciple.quality);

	else	--if the player2 has not
		container:getVarSprite("mRightPic"):setVisible(false);

		local noPlayerStr = Language:getInstance():getString("@CSNotPlayer")
		local noServerStr = Language:getInstance():getString("@CSNotPlayerServer")
		container:getVarLabelTTF("mRightPlayerName"):setString(noPlayerStr);
		container:getVarLabelBMFont("mRightServer"):setString(noServerStr);

		-- no palyer pic
		container:getVarSprite("mRightMem"):setTexture(NO_PLAYER_PIC);
	end

	--set bet player
	local leftPicFlag = false;
	local rightPicFlag = false;

	if string.len(cellInfo.player1.playerIdentify) > 0 and (cellInfo.player1.playerIdentify == CrossServerWarDisplayBetGlobalVariable.betPlayer) then
		leftPicFlag = true;
		rightPicFlag = false;
	end

	if string.len(cellInfo.player2.playerIdentify) > 0 and cellInfo.player2.playerIdentify == CrossServerWarDisplayBetGlobalVariable.betPlayer then
		leftPicFlag = false;
		rightPicFlag = true;
	end

	container:getVarSprite("mLeftPic"):setVisible(leftPicFlag);
	container:getVarSprite("mRightPic"):setVisible(rightPicFlag);
end

--888. param mark : cache handler
function CacheHandler.cacheBattleListInfoMSG( msg )
	BattleViewCache.playerIdentify = msg.playerIdentify;
	BattleViewCache.betPlayer = msg.betPlayer;
	BattleViewCache.battleStage = msg.battleStage;

	--shengzhe zu
	BattleViewCache.winPlayers = {}
	for i = 1, table.maxn(msg.winPlayers), 1 do
		BattleViewCache.winPlayers[i] = {hasChangePos = false};
		BattleViewCache.winPlayers[i].vsIdentify = msg.winPlayers[i].vsIdentify;
		BattleViewCache.winPlayers[i].battleId = msg.winPlayers[i].battleId;
		BattleViewCache.winPlayers[i].battleStage = msg.winPlayers[i].battleStage;
		BattleViewCache.winPlayers[i].winnerPlayer = msg.winPlayers[i].winnerPlayer;

		if msg.playerIdentify == msg.winPlayers[i].player2.playerIdentify then
			BattleViewCache.winPlayers[i].player2 = {};
			BattleViewCache.winPlayers[i].player2.playerIdentify = msg.winPlayers[i].player1.playerIdentify;
			BattleViewCache.winPlayers[i].player2.playerName = msg.winPlayers[i].player1.playerName;
			BattleViewCache.winPlayers[i].player2.playerItemId = msg.winPlayers[i].player1.playerItemId;
			BattleViewCache.winPlayers[i].player2.playerLevel = msg.winPlayers[i].player1.playerLevel;
			BattleViewCache.winPlayers[i].player2.serverName = msg.winPlayers[i].player1.serverName;
			BattleViewCache.winPlayers[i].player2.rebirthStage = msg.winPlayers[i].player1.rebirthStage;

			BattleViewCache.winPlayers[i].player1 = {};
			BattleViewCache.winPlayers[i].player1.playerIdentify = msg.winPlayers[i].player2.playerIdentify;
			BattleViewCache.winPlayers[i].player1.playerName = msg.winPlayers[i].player2.playerName;
			BattleViewCache.winPlayers[i].player1.playerItemId = msg.winPlayers[i].player2.playerItemId;
			BattleViewCache.winPlayers[i].player1.playerLevel = msg.winPlayers[i].player2.playerLevel;
			BattleViewCache.winPlayers[i].player1.serverName = msg.winPlayers[i].player2.serverName;
			BattleViewCache.winPlayers[i].player1.rebirthStage = msg.winPlayers[i].player2.rebirthStage;

            BattleViewCache.winPlayers[i].hasChangePos = true;
		else
			BattleViewCache.winPlayers[i].player1 = {};
			BattleViewCache.winPlayers[i].player1.playerIdentify = msg.winPlayers[i].player1.playerIdentify;
			BattleViewCache.winPlayers[i].player1.playerName = msg.winPlayers[i].player1.playerName;
			BattleViewCache.winPlayers[i].player1.playerItemId = msg.winPlayers[i].player1.playerItemId;
			BattleViewCache.winPlayers[i].player1.playerLevel = msg.winPlayers[i].player1.playerLevel;
			BattleViewCache.winPlayers[i].player1.serverName = msg.winPlayers[i].player1.serverName;
			BattleViewCache.winPlayers[i].player1.rebirthStage = msg.winPlayers[i].player1.rebirthStage;

			BattleViewCache.winPlayers[i].player2 = {};
			BattleViewCache.winPlayers[i].player2.playerIdentify = msg.winPlayers[i].player2.playerIdentify;
			BattleViewCache.winPlayers[i].player2.playerName = msg.winPlayers[i].player2.playerName;
			BattleViewCache.winPlayers[i].player2.playerItemId = msg.winPlayers[i].player2.playerItemId;
			BattleViewCache.winPlayers[i].player2.playerLevel = msg.winPlayers[i].player2.playerLevel;
			BattleViewCache.winPlayers[i].player2.serverName = msg.winPlayers[i].player2.serverName;
			BattleViewCache.winPlayers[i].player2.rebirthStage = msg.winPlayers[i].player2.rebirthStage;
		end


	end

	--baizhe zu
	BattleViewCache.losePlayers = {}
	for i = 1, table.maxn(msg.losePlayers), 1 do

			BattleViewCache.losePlayers[i] = {hasChangePos = false};
			BattleViewCache.losePlayers[i].vsIdentify = msg.losePlayers[i].vsIdentify;
			BattleViewCache.losePlayers[i].battleId = msg.losePlayers[i].battleId;
			BattleViewCache.losePlayers[i].battleStage = msg.losePlayers[i].battleStage;
			BattleViewCache.losePlayers[i].winnerPlayer = msg.losePlayers[i].winnerPlayer;

		if msg.playerIdentify == msg.losePlayers[i].player2.playerIdentify then
			BattleViewCache.losePlayers[i].player2 = {};
			BattleViewCache.losePlayers[i].player2.playerIdentify = msg.losePlayers[i].player1.playerIdentify;
			BattleViewCache.losePlayers[i].player2.playerName = msg.losePlayers[i].player1.playerName;
			BattleViewCache.losePlayers[i].player2.playerItemId = msg.losePlayers[i].player1.playerItemId;
			BattleViewCache.losePlayers[i].player2.playerLevel = msg.losePlayers[i].player1.playerLevel;
			BattleViewCache.losePlayers[i].player2.serverName = msg.losePlayers[i].player1.serverName;
			BattleViewCache.losePlayers[i].player2.rebirthStage = msg.losePlayers[i].player1.rebirthStage;

			BattleViewCache.losePlayers[i].player1 = {};
			BattleViewCache.losePlayers[i].player1.playerIdentify = msg.losePlayers[i].player2.playerIdentify;
			BattleViewCache.losePlayers[i].player1.playerName = msg.losePlayers[i].player2.playerName;
			BattleViewCache.losePlayers[i].player1.playerItemId = msg.losePlayers[i].player2.playerItemId;
			BattleViewCache.losePlayers[i].player1.playerLevel = msg.losePlayers[i].player2.playerLevel;
			BattleViewCache.losePlayers[i].player1.serverName = msg.losePlayers[i].player2.serverName;
			BattleViewCache.losePlayers[i].player1.rebirthStage = msg.losePlayers[i].player2.rebirthStage;
            
            BattleViewCache.losePlayers[i].hasChangePos = true;
		else
			BattleViewCache.losePlayers[i].player1 = {};
			BattleViewCache.losePlayers[i].player1.playerIdentify = msg.losePlayers[i].player1.playerIdentify;
			BattleViewCache.losePlayers[i].player1.playerName = msg.losePlayers[i].player1.playerName;
			BattleViewCache.losePlayers[i].player1.playerItemId = msg.losePlayers[i].player1.playerItemId;
			BattleViewCache.losePlayers[i].player1.playerLevel = msg.losePlayers[i].player1.playerLevel;
			BattleViewCache.losePlayers[i].player1.serverName = msg.losePlayers[i].player1.serverName;
			BattleViewCache.losePlayers[i].player1.rebirthStage = msg.losePlayers[i].player1.rebirthStage;

			BattleViewCache.losePlayers[i].player2 = {};
			BattleViewCache.losePlayers[i].player2.playerIdentify = msg.losePlayers[i].player2.playerIdentify;
			BattleViewCache.losePlayers[i].player2.playerName = msg.losePlayers[i].player2.playerName;
			BattleViewCache.losePlayers[i].player2.playerItemId = msg.losePlayers[i].player2.playerItemId;
			BattleViewCache.losePlayers[i].player2.playerLevel = msg.losePlayers[i].player2.playerLevel;
			BattleViewCache.losePlayers[i].player2.serverName = msg.losePlayers[i].player2.serverName;
			BattleViewCache.losePlayers[i].player2.rebirthStage = msg.losePlayers[i].player2.rebirthStage;
		end
	end
end


--refresh battle state by timer
function ControllersHandler.refreshBattleStateByTimer( container )
	if (not BattleStateTimer.timerExist) and centerButtonRefreshKey then
		BattleStateTimer.timerName = "BattleStateTimer_" .. ADVENTURE_CONTAINER.ID;
		TimeCalculator:getInstance():createTimeCalcultor(BattleStateTimer.timerName,BattleStateTimer.defaultTime);
		BattleStateTimer.timerExist = true;

		if CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
			centerButtonRefreshKey = false;
		end
	end
end

-- refersh 16->8,8->4...stage
function ControllersHandler.refresh16To8StateByTimer( container )
	if buildStateFlag ~= CSTools.getCurrentStage(CrossServerWarDisplayGlobal.battleId) and (CSTools.getCurrentStage(CrossServerWarDisplayGlobal.battleId) ~= nil) then
		if (not Battle16To8StateTimer.timerExist) then
			Battle16To8StateTimer.timerName = "Battle16To8StateTimer_" .. ADVENTURE_CONTAINER.ID;
			TimeCalculator:getInstance():createTimeCalcultor(Battle16To8StateTimer.timerName,Battle16To8StateTimer.defaultTime);
			Battle16To8StateTimer.timerExist = true;

		end
	end
end

-- refresh battle array button and title
function ControllersHandler.refreshTitleAndBattleArrayBtnByTimer( container )
	-- local createTimer = false;

	-- for i = 1, table.maxn(BattleViewCache.losePlayers), 1 do
	-- 	local identifyPlayer1 = BattleViewCache.losePlayers[i].player1.playerIdentify;
	-- 	local identifyPlayer2 = BattleViewCache.losePlayers[i].player2.playerIdentify;
	-- 	local indentifyOwer = CrossServerWarDisplayGlobal.playerIdentify;

	-- 	if (indentifyOwer == identifyPlayer1) or (indentifyOwer == identifyPlayer2) then
	-- 		if (not BattleArrayAndTitleTimer.timerExist) then
	-- 			createTimer = true;
	-- 		end
	-- 	end
	-- end

	-- for i = 1, table.maxn(BattleViewCache.winPlayers), 1 do
	-- 	local identifyPlayer1 = BattleViewCache.winPlayers[i].player1.playerIdentify;
	-- 	local identifyPlayer2 = BattleViewCache.winPlayers[i].player2.playerIdentify;
	-- 	local indentifyOwer = CrossServerWarDisplayGlobal.playerIdentify;
		
	-- 	if (indentifyOwer == identifyPlayer1) or (indentifyOwer == identifyPlayer2) then
	-- 		if (not BattleArrayAndTitleTimer.timerExist) then
	-- 			createTimer = true;
	-- 		end
	-- 	end
	-- end

	-- if createTimer then
	-- 	BattleArrayAndTitleTimer.timerName = "BattleArrayAndTitleTimer_" .. ADVENTURE_CONTAINER.ID;
	-- 	TimeCalculator:getInstance():createTimeCalcultor(BattleArrayAndTitleTimer.timerName,BattleArrayAndTitleTimer.defaultTime);
	-- 	BattleArrayAndTitleTimer.timerExist = true;
	-- 	createTimer = false;
	-- end


	ControllersHandler.checkTitleAndBattleArrayBtn(container);
end

function ControllersHandler.refreshTitleByTimer( container )
	if titleRefreshKey then
		BattleTitleTimer.timerName = "BattleTitleTimer_" .. ADVENTURE_CONTAINER.ID;
		TimeCalculator:getInstance():createTimeCalcultor(BattleTitleTimer.timerName,BattleTitleTimer.defaultTime);
		BattleTitleTimer.timerExist = true;

		titleRefreshKey = false;
	end
end

--refresh the battle list winner or loser
function ControllersHandler.refreshBattleListWinnerOrLoserByTimer(container)

	local winnerPlayerWinners = nil;

	if table.maxn(BattleViewCache.winPlayers) > 0 then
		winnerPlayerWinners = BattleViewCache.winPlayers[1].winnerPlayer;
	end

	if (winnerPlayerWinners == nil or string.len(winnerPlayerWinners) <= 0) then
		if CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
			--require info first
			--ControllersHandler.requierBattleViewMSGByFilter(container);
			BattleListWinerOrLoserTimer.timerName = "BattleListWinerOrLoserTimer_" .. ADVENTURE_CONTAINER.ID;
			TimeCalculator:getInstance():createTimeCalcultor(BattleListWinerOrLoserTimer.timerName,BattleListWinerOrLoserTimer.defaultTime);
			BattleListWinerOrLoserTimer.timerExist = true;
		end
	end
end

-- function ControllersHandler.requierBattleViewMSGByFilter( container )
-- 	local winnerPlayerWinners = nil;
-- 	local winnerPlayerLosers = nil;

-- 	if table.maxn(BattleViewCache.winPlayers) > 0 then
-- 		winnerPlayerWinners = BattleViewCache.winPlayers[1].winnerPlayer;
-- 	end

-- 	if table.maxn(BattleViewCache.losePlayers) > 0 then
-- 		winnerPlayerLosers = BattleViewCache.losePlayers[1].winnerPlayer;
-- 	end

-- 	if (winnerPlayerWinners == nil or winnerPlayerWinners == "") and (winnerPlayerLosers == nil or winnerPlayerLosers == "") then
-- 		PacketHandler.requireBattleViewMSG(container);
-- 	end
-- end

function ControllersHandler.checkBattleState()
	local stage = nil;
	-- bet stage
	if CSTools.checkBetStage(CrossServerWarDisplayGlobal.battleId) then
		stage = CENTER_BUTTON_STAGE.BET_STAGE;
	end

	--battle stage
	if CSTools.checkBattleStage(CrossServerWarDisplayGlobal.battleId) then
		stage = CENTER_BUTTON_STAGE.BATTLE_STAGE;
	end

	--review stage
	if CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
		stage = CENTER_BUTTON_STAGE.REVIEW_STAGE;
	end

	ControllersHandler.changeCenterButtonState(stage);
end

function ControllersHandler.checkTitleAndBattleArrayBtn( container )

	local battleBtnEnabled = false;

	--set battle array btn
	if CSTools.checkBetStage(CrossServerWarDisplayGlobal.battleId) then
		if ControllersHandler.checkPlayerInWar() then
			battleBtnEnabled = true;
		else
			battleBtnEnabled = false;
		end
	end

	if CSTools.checkBattleStage(CrossServerWarDisplayGlobal.battleId) then
		battleBtnEnabled = false;
	end

	if CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
		if ControllersHandler.checkPlayerInWar() then
			battleBtnEnabled = true;
		else
			battleBtnEnabled = false;
		end
	end

	if (not battleBtnEnabled) then
		if container:getVarMenuItemImage("mUpdateTeamBtn"):isEnabled() then
			container:getVarMenuItemImage("mUpdateTeamBtn"):setEnabled(battleBtnEnabled);
		end
	end

	if battleBtnEnabled then
		if (not container:getVarMenuItemImage("mUpdateTeamBtn"):isEnabled()) then
			container:getVarMenuItemImage("mUpdateTeamBtn"):setEnabled(battleBtnEnabled);
		end
	end
end

function ControllersHandler.checkPlayerInWar()
	local result = false;
	for i = 1, table.maxn(BattleViewCache.losePlayers), 1 do
		local identifyPlayer1 = BattleViewCache.losePlayers[i].player1.playerIdentify;
		local identifyPlayer2 = BattleViewCache.losePlayers[i].player2.playerIdentify;
		local indentifyOwer = CrossServerWarDisplayGlobal.playerIdentify;

		if (indentifyOwer == identifyPlayer1) or (indentifyOwer == identifyPlayer2) then
				result = true;
		end
	end

	for i = 1, table.maxn(BattleViewCache.winPlayers), 1 do
		local identifyPlayer1 = BattleViewCache.winPlayers[i].player1.playerIdentify;
		local identifyPlayer2 = BattleViewCache.winPlayers[i].player2.playerIdentify;
		local indentifyOwer = CrossServerWarDisplayGlobal.playerIdentify;
		
		if (indentifyOwer == identifyPlayer1) or (indentifyOwer == identifyPlayer2) then
				result = true;
		end
	end

	return result;
end

function ControllersHandler.setTitles(container)
	local currentWarStage = CSTools.getCurrentStage(CrossServerWarDisplayGlobal.battleId);

	local titleStr = "";
	local titleStage = nil;

	if currentWarStage == WAR_STAGE.PER_16TO8_STAGE or currentWarStage == WAR_STAGE.CRO_16TO8_STAGE then
		titleStr = "@MatchStage16"
		titleStage = WAR_STAGE.PER_16TO8_STAGE;
	end

	if currentWarStage == WAR_STAGE.PER_8TO4_STAGE or currentWarStage == WAR_STAGE.CRO_8TO4_STAGE then
		titleStr = "@MatchStage8"
		titleStage = WAR_STAGE.PER_8TO4_STAGE;
	end

	if currentWarStage == WAR_STAGE.PER_4TO2_STAGE or currentWarStage == WAR_STAGE.CRO_4TO2_STAGE then
		titleStr = "@MatchStage4"
		titleStage = WAR_STAGE.PER_4TO2_STAGE;
	end

	if currentWarStage == WAR_STAGE.PER_2TO1_STAGE or currentWarStage == WAR_STAGE.CRO_2TO1_STAGE or currentWarStage == WAR_STAGE.REVIEW_STAGE then
		titleStr = "@MatchStage2"
		titleStage = WAR_STAGE.PER_2TO1_STAGE;
	end

	local CSManager = require("PVP.CSManager")
    container:getVarLabelBMFont("mEventLab"):setString( common:getLanguageString( titleStr ) )
    local currentCount = tonumber( CSManager.WarStateCache.openState.battleId )
    --local picStr = "UI/CrossServerWar/u_CrossServerWarTitleNum"..currentCount..".png"
	container:getVarLabelTTF("mTitleNum"):setString(common:getLanguageString("@CSTimeOfCS",currentCount))
end

function ControllersHandler.clickLeftPlayer( container )


	local id = container:getItemDate().mID;
	local player = nil;

	if WINNER_SHOW then
		player = BattleViewCache.winPlayers[id].player1;
	else -- display loser
		player = BattleViewCache.losePlayers[id].player1;
	end

	if player ~= nil and string.len(player.playerIdentify) > 0 then
		ControllersHandler.requireBattleArrayPage(player);
	else
		MessageBoxPage:Msg_Box(common:getLanguageString( "@error_12" ));
	end
end

function ControllersHandler.clickRightPlayer( container )
	local id = container:getItemDate().mID;

	local player= nil;

	if WINNER_SHOW then
		player = BattleViewCache.winPlayers[id].player2;
	else -- display loser
		player = BattleViewCache.losePlayers[id].player2;
	end

	if player ~= nil and string.len(player.playerIdentify) > 0 then
		ControllersHandler.requireBattleArrayPage(player);
	else
		MessageBoxPage:Msg_Box(common:getLanguageString( "@error_12" ));
	end
end

function ControllersHandler.requireBattleArrayPage( player )
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

--888. param mark : timer
function TimerHandler.refreshBattleState( container )
	if not TimeCalculator:getInstance():hasKey(BattleStateTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(BattleStateTimer.timerName)

	--when more than 1 second, add 1
	--timer default time is 0 ,
	--if Tools.numAGreaterThanNumB( leftTime + 1, BattleStateTimer.defaultTime ) then
		--return
	--end

	BattleStateTimer.defaultTime = leftTime;

	if Tools.numALessOrEqualsToNumB(BattleStateTimer.defaultTime, 0) then
		BattleStateTimer.defaultTime = 0
	end

	-- timer end ,call function
	if Tools.numAEqualsToNumB(BattleStateTimer.defaultTime, 0) then
		--1. require war state info
		ControllersHandler.checkBattleState();
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(BattleStateTimer.timerName);
		--3. timer exist flag be false
		BattleStateTimer.timerExist = false;
		BattleStateTimer.defaultTime = 0
	end
end

function TimerHandler.refresh16To8State( container )

	if not TimeCalculator:getInstance():hasKey(Battle16To8StateTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(Battle16To8StateTimer.timerName)

	--when more than 1 second, add 1
--	if Tools.numAGreaterThanNumB( leftTime + 1, Battle16To8StateTimer.defaultTime ) then
	--	return
	--end

	Battle16To8StateTimer.defaultTime = leftTime;

	if Tools.numALessOrEqualsToNumB(Battle16To8StateTimer.defaultTime, 0) then
		Battle16To8StateTimer.defaultTime = 0
	end

	-- timer end ,call function
	if Tools.numAEqualsToNumB(Battle16To8StateTimer.defaultTime, 0) then
		--1. require war state info
		PacketHandler.requireBattleViewMSG(container);
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(Battle16To8StateTimer.timerName);
		--3. timer exist flag be false
		Battle16To8StateTimer.timerExist = false;
		Battle16To8StateTimer.defaultTime = 10
	end
end

-- function TimerHandler.refreshTitleAndBattleArrayBtn( container )

-- 	if not TimeCalculator:getInstance():hasKey(BattleArrayAndTitleTimer.timerName) then return end

-- 	local leftTime = TimeCalculator:getInstance():getTimeLeft(BattleArrayAndTitleTimer.timerName)

-- 	--when more than 1 second, add 1
-- 	-- default is 0
-- 	--if Tools.numAGreaterThanNumB( leftTime + 1, BattleArrayAndTitleTimer.defaultTime ) then
-- 	--	return
-- 	--end

-- 	BattleArrayAndTitleTimer.defaultTime = leftTime;

-- 	if Tools.numALessOrEqualsToNumB(BattleArrayAndTitleTimer.defaultTime, 0) then
-- 		BattleArrayAndTitleTimer.defaultTime = 0
-- 	end

-- 	-- timer end ,call function
-- 	if Tools.numAEqualsToNumB(BattleArrayAndTitleTimer.defaultTime, 0) then
-- 		--1. require war state info
-- 		ControllersHandler.checkTitleAndBattleArrayBtn(container);
-- 		--2. remove the Timer
-- 		TimeCalculator:getInstance():removeTimeCalcultor(BattleArrayAndTitleTimer.timerName);
-- 		--3. timer exist flag be false
-- 		BattleArrayAndTitleTimer.timerExist = false;
-- 		BattleArrayAndTitleTimer.defaultTime = 10
-- 	end
-- end

function TimerHandler.refreshBattleListWinnerOrLoser( container )
	if not TimeCalculator:getInstance():hasKey(BattleListWinerOrLoserTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(BattleListWinerOrLoserTimer.timerName)

	--when more than 1 second, add 1
--	if Tools.numAGreaterThanNumB( leftTime + 1, BattleListWinerOrLoserTimer.defaultTime ) then
	--	return
	--end

	BattleListWinerOrLoserTimer.defaultTime = leftTime;

	if Tools.numALessOrEqualsToNumB(BattleListWinerOrLoserTimer.defaultTime, 0) then
		BattleListWinerOrLoserTimer.defaultTime = 0
	end

	-- timer end ,call function
	if Tools.numAEqualsToNumB(BattleListWinerOrLoserTimer.defaultTime, 0) then
		--1. require battle list info
		PacketHandler.requireBattleViewMSG( container )
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(BattleListWinerOrLoserTimer.timerName);
		--3. timer exist flag be false
		BattleListWinerOrLoserTimer.timerExist = false;
		BattleListWinerOrLoserTimer.defaultTime = 10;
	end

end

function TimerHandler.refreshTitle( container )

	if not TimeCalculator:getInstance():hasKey(BattleTitleTimer.timerName) then return end

	local leftTime = TimeCalculator:getInstance():getTimeLeft(BattleTitleTimer.timerName)

	--when more than 1 second, add 1
--	if Tools.numAGreaterThanNumB( leftTime + 1, BattleListWinerOrLoserTimer.defaultTime ) then
	--	return
	--end

	BattleTitleTimer.defaultTime = leftTime;

	if Tools.numALessOrEqualsToNumB(BattleTitleTimer.defaultTime, 0) then
		BattleTitleTimer.defaultTime = 0
	end

	-- timer end ,call function
	if Tools.numAEqualsToNumB(BattleTitleTimer.defaultTime, 0) then
		--1. set titles info
		ControllersHandler.setTitles(container);
		--2. remove the Timer
		TimeCalculator:getInstance():removeTimeCalcultor(BattleTitleTimer.timerName);
		--3. timer exist flag be false
		BattleTitleTimer.timerExist = false;
		BattleTitleTimer.defaultTime = 0;
	end
end

--999. param mark : packet manager
function PacketHandler.requireBattleViewMSG( container )
	local msg = CsBattle_pb.OPCSBattleRequestStageInfo();
	msg.playerIdentify = CrossServerWarDisplayGlobal.playerIdentify;
	msg.battleId = CrossServerWarDisplayGlobal.battleId;
	msg.battleStage = tonumber(CSTools.getCurrentStage(CrossServerWarDisplayGlobal.battleId));

	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(PROTOBUF_CONTAINER.OPCODE_CS_WARINFO_C,pb_data,#pb_data,true);
end

function PacketHandler.registerAllPackets( container )

	container:registerPacket(PROTOBUF_CONTAINER.OPCODE_CS_WARINFO_S);
	container:registerPacket(PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
	container:registerPacket(PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S);

end

function PacketHandler.removeAllPackets( container )
	container:removePacket(PROTOBUF_CONTAINER.OPCODE_CS_WARINFO_S);
	container:removePacket(PROTOBUF_CONTAINER.OPCODE_CS_BATTLEARRAY_INFO_S);
	container:removePacket(PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_S);
	container:removeMessage(MSG_MAINFRAME_POPPAGE)
end

function PacketHandler.requireRefreshBattleArray( boo )
    if not boo then return end
	local msg = CsBattle_pb.OPCSBattleUpdateBattleArray();
	msg.playerIdentify = CrossServerWarDisplayGlobal.playerIdentify;

	local pb_data = msg:SerializeToString();
	PacketManager:getInstance():sendPakcet(PROTOBUF_CONTAINER.OPCODE_CS_REFRESH_BATTLEARRAY_C,pb_data,#pb_data,true);
end


--1000. param mark : Tools function
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

function Tools.deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
	if type(object) ~= "table" then
		return object
	elseif lookup_table[object] then
		return lookup_table[object]
	end  -- if
	local new_table = {}
	lookup_table[object] = new_table
	for index, value in pairs(object) do
		new_table[_copy(index)] = _copy(value)
	end  -- for
	return setmetatable(new_table, getmetatable(object))
	end  -- function _copy
	return _copy(object)
end  -- function deepcopy

function Tools.getPlayIdByPlayerIdentify(identify)
	local playId = Split(identify, "*", 3);
	local index = table.maxn(playId);
	return playId[index];
end

function Tools.getCurrentDetailStage()
	if CSTools.checkBetStage(CrossServerWarDisplayGlobal.battleId) then
		currentDetailStage = CURRENT_DETAIL_STAGE.BET_STAGE;
	elseif CSTools.checkBattleStage(CrossServerWarDisplayGlobal.battleId) then
		currentDetailStage = CURRENT_DETAIL_STAGE.BATTLE_STAGE;
	elseif CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId) then
		currentDetailStage = CURRENT_DETAIL_STAGE.REVIEW_STAGE;
	end
end

function Tools.detailStageHasChanged()

	local result = false;

	if currentDetailStage == CURRENT_DETAIL_STAGE.BET_STAGE then
		result = (not CSTools.checkBetStage(CrossServerWarDisplayGlobal.battleId));
	elseif currentDetailStage == CURRENT_DETAIL_STAGE.BATTLE_STAGE then
		result = (not CSTools.checkBattleStage(CrossServerWarDisplayGlobal.battleId));
	elseif currentDetailStage == CURRENT_DETAIL_STAGE.REVIEW_STAGE then
		result = (not CSTools.checkReviewStage(CrossServerWarDisplayGlobal.battleId));
	elseif currentDetailStage == nil then
		result = true;
	end

	--refresh current detail stage
	if result then
		Tools.getCurrentDetailStage();
	end

	return result;
end
