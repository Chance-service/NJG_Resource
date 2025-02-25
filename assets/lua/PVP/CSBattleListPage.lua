
----------------------------------------------------------------------------------
local CsBattle_pb = require("CsBattle_pb")
local CommonPage = require("CommonPage")
local CSTools = require("PVP.CSTools")
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local roleConfig = ConfigManager.getRoleCfg()
local thisPageName = "CSBattleListPage"

local opcodes = {
	OPCODE_CS_WARPLAYBACK_LISTSTATE_C = HP_pb.OPCODE_CS_WARPLAYBACK_LISTSTATE_C,
	OPCODE_CS_WARPLAYBACK_LISTSTATE_S = HP_pb.OPCODE_CS_WARPLAYBACK_LISTSTATE_S,
	OPCODE_CS_WARPLAYBACK_C = HP_pb.OPCODE_CS_WARPLAYBACK_C,
	OPCODE_CS_WARPLAYBACK_S = HP_pb.OPCODE_CS_WARPLAYBACK_S,
	OPCODE_CS_MYPLAYBACK_C = HP_pb.OPCODE_CS_MYPLAYBACK_C,
	OPCODE_CS_MYPLAYBACK_S = HP_pb.OPCODE_CS_MYPLAYBACK_S,
    OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S
}

local option = {
	ccbiFile = "CrossServerWarPopUp.ccbi",
	handlerMap = {
		onClose	= "onClose"
	},
}

local GroupId = {
	Winner	= 1,
	Loser	= 2
}

local CSBattleList = {}

BattleList = {
	Type_MyBattle = 1,
	Type_Playback = 2
}

local battleInfo = {
	battleId   = 1,
	battleType = BattleList.Type_MyBattle,
	battleList = {},
	result = {},
	vsInfo = {}
}

function BattleList.setType(battleId, bType)
	battleInfo.battleId	  = battleId
	battleInfo.battleType = bType
	battleInfo.battleList = {}
	battleInfo.vsInfo = {}
end

function BattleList.setVSInfo(vsInfo, playerId)
	BattleList.setType(vsInfo.battleId, BattleList.Type_Playback)
	local needChangePos = (not vsInfo.hasChangePos) and playerId and (vsInfo.player2.playerIdentify == playerId);
	battleInfo.vsInfo = {
		id = vsInfo.vsIdentify,
		leftPlayer = CSTools.getPlayerInfo(needChangePos and vsInfo.player2 or vsInfo.player1),
		rightPlayer = CSTools.getPlayerInfo(needChangePos and vsInfo.player1 or vsInfo.player2),
		stage = vsInfo.battleStage,
		hasChangePos = vsInfo.hasChangePos or needChangePos
	}
end

local BattleResult = {
	Lose	= 0,
	WIN		= 1
}

local WinnerType = {
	Left = 1,
	Right = 2
}

local function sortMyGame(battle1, battle2)
	if battle1.battleId ~= battle2.battleId then
		return battle1.battleId > battle2.battleId
	end

	if battle1.stage ~= battle2.stage then
		return battle1.stage > battle2.stage
	end

	if battle1.groupId ~= battle2.groupId then
		return battle1.groupId > battle2.groupId
	end

	return battle1.id > battle2.id
end
----------------------------------------------------------------------------------
--scrollview 中的单个item
--------------------------------------------
local CSBattleListItem = {
	ccbiFile = "CrossServerWarPopUpContent.ccbi"
}

function CSBattleListItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		CSBattleListItem.onRefreshItemView(container)
	elseif eventName == "onView" then
		CSBattleListItem.onViewBattle(container)
    elseif eventName == "onLeftFrame" then
        local contentId = container:getItemDate().mID
	    local item = battleInfo.battleList[contentId]
	    local leftPlayer = item.leftPlayer
		CSBattleListItem.requirePlayInfo(leftPlayer)
    elseif eventName == "onRightFrame" then
        local contentId = container:getItemDate().mID
	    local item = battleInfo.battleList[contentId]
	    local rightPlayer = item.rightPlayer or {}
		CSBattleListItem.requirePlayInfo(rightPlayer)
	end
end

function CSBattleListItem.requirePlayInfo( player )
    if player ~= nil then  
		local playerIdentify = player.id;

		if playerIdentify ~= nil then
			if playerIdentify ~= nil then
				--local player = Tools.getPlayIdByPlayerIdentify(playerIdentify);
				--if player ~= nil then

					local msg = CsBattle_pb.OPCSBattleArrayInfo();
					msg.viewIdentify = playerIdentify;
					msg.version = 1;

					local pb_data = msg:SerializeToString();
					PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CS_BATTLEARRAY_INFO_C,pb_data,#pb_data,false);
					--ScriptMathToLua:showTeamBattleView(tonumber(player),1,false);
				--end
			end
		end
	end
end

function CSBattleListItem.onRefreshItemView(container)
	local contentId = container:getItemDate().mID
	local item = battleInfo.battleList[contentId]
    
	local isMyBattle = battleInfo.battleType == BattleList.Type_MyBattle
	NodeHelper:setNodeVisible(container:getVarNode("mMyGameNode"), false)

	local leftPlayer = item.leftPlayer
	local rightPlayer = item.rightPlayer or {}

	local lb2Str = {
		mLeftServer		 = leftPlayer.serverName or "",
		mRightServer	 = rightPlayer.serverName or ""
	}
	if Golb_Platform_Info.is_r2_platform and IsThaiLanguage() then
        NodeHelper:setNodeScale(container, "mPUCTitle", 0.6 , 0.6)
        NodeHelper:SetNodePostion(container, "mPUCTitle",10,0)  
    end
	--local groupId = item.groupId
	--if groupId == GroupId.Winner or groupId == GroupId.Loser then
	--	lb2Str["mPUCTitle"] = common:getLanguageString(string.format("@CSBattleName_%d_%d", item.stage, groupId))
	--else
		lb2Str["mPUCTitle"] = common:getLanguageString("@CSBattleName_" .. item.stage)
	--end

	NodeHelper:setStringForLabel(container, lb2Str)
 	container:getVarLabelTTF('mLeftPlayerName'):setFontSize(20)
 	container:getVarLabelTTF('mRightPlayerName'):setFontSize(20)
	NodeHelper:setStringForTTFLabel(container, {
		mLeftPlayerName	 = leftPlayer.name or "",
		mRightPlayerName = rightPlayer.name or ""
	})

	CSBattleListItem.showPlayerIcon(container, leftPlayer.discipleId, rightPlayer.discipleId)
	CSBattleListItem.showPlayerState(container, true, leftPlayer.id == item.winner)
	CSBattleListItem.showPlayerState(container, false, rightPlayer.id == item.winner)
end

function CSBattleListItem.showPlayerState(container, isLeftPos, isWinner)
	local pos = isLeftPos and "Left" or "Right"
	local state = isWinner and "Win" or "Lose"
	-- variable -> gameConfig
	local cfgBgPic = string.format("CSBattlePlayerBg_%s_%s", pos, state)
	local bgPic = GameConfig[cfgBgPic]
	--container:getVarSprite(string.format("m%sbg", pos)):setTexture(bgPic)
	local cfgStatePic = string.format("CSBattle_%s_Icon", state)
	local statePic = GameConfig[cfgStatePic]
	local label = container:getVarLabelBMFont(string.format("m%sPic", pos))
	local color = {CSBattle_Win_Icon="244 236 119",CSBattle_Lose_Icon="115 167 242"}
	if label then
		local str = Language:getInstance():getString(statePic)
    	label:setString(str)
		local cc = StringConverter:parseColor3B(color[cfgStatePic])
		label:setColor(cc);
	end
end

function CSBattleListItem.showPlayerIcon(container, leftDiscipleId, rightDiscipleId)
	if leftDiscipleId then
		local leftDisciple = roleConfig[leftDiscipleId] --DiscipleTableManager:getInstance():getDiscipleItemByID(leftDiscipleId)
		container:getVarSprite("mLeftMemPic"):setTexture(leftDisciple.icon)
		-- common:setFrameQuality(container:getVarMenuItemImage("mLeftFrame"), leftDisciple.quality)
	end
	if rightDiscipleId then
		local rightDisciple = roleConfig[rightDiscipleId] -- DiscipleTableManager:getInstance():getDiscipleItemByID(rightDiscipleId)
		container:getVarSprite("mRightMemPic"):setTexture(rightDisciple.icon)
		-- common:setFrameQuality(container:getVarMenuItemImage("mRightFrame"), rightDisciple.quality)
	else
		container:getVarSprite("mRightMemPic"):setTexture(GameConfig.CSBattleEmpty_Icon)
		-- common:setFrameQuality(container:getVarMenuItemImage("mRightFrame"))
	end
end


--点击领奖事件处理
function CSBattleListItem.onViewBattle(container)
	local contentId = container:getItemDate().mID
	local item = battleInfo.battleList[contentId]
	if battleInfo.battleType == BattleList.Type_MyBattle and not item.isKnockout then
		battleInfo.battleType = BattleList.Type_Playback
		battleInfo.vsInfo = common:deepCopy(item)
		battleInfo.battleList = {}
		PageManager.refreshPage(thisPageName)
	else
		--懂什么意思 todo
		--local fp = FightPage:getInstance()
		--fp:setFightType(FT_Playback)

		CSBattleListItem.sendPacketForReward(container)
	end
end

function CSBattleListItem.sendPacketForReward(container)
	local contentId = container:getItemDate().mID
	GlobalData.ViewCSPlayerBattleContentId = contentId
	local item = battleInfo.battleList[contentId]

	local msg = CsBattle_pb.OPCSBattleViewBattle()
	msg.vsIdentify = item.id
	msg.turnIndex = contentId - 1
	common:sendPacket(opcodes.OPCODE_CS_WARPLAYBACK_C,msg)
end

function ViewCSPlayerInfo( contentId,playerId )
	if contentId==nil or contentId==0 then return end

	local item = battleInfo.battleList[contentId]
    local leftPlayer = item.leftPlayer
    local rightPlayer = item.rightPlayer
    if string.find(leftPlayer.id,tostring(playerId)) then
		CSBattleListItem.requirePlayInfo(leftPlayer)
	else
		CSBattleListItem.requirePlayInfo(rightPlayer)
	end
end
----------------------------------------------------------------------------------
--CSBattleList页面中的事件处理
----------------------------------------------
function CSBattleList:onEnter(container)
	self:registerPacket(container)
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	container:getVarNode("mPopUpTexNode"):setVisible(false)
	self:getBattleList(container)

end

function CSBattleList:getBattleList(container)
	if battleInfo.battleType == BattleList.Type_MyBattle then
		local msg = CsBattle_pb.OPCSBattleFetchMyBattle()
		msg.battleId = battleInfo.battleId
		common:sendPacket(opcodes.OPCODE_CS_MYPLAYBACK_C,msg)
	elseif battleInfo.battleType == BattleList.Type_Playback then
		local msg = CsBattle_pb.OPCSBattleRequestVsInfo()
		msg.vsIdentify = battleInfo.vsInfo.id
		common:sendPacket(opcodes.OPCODE_CS_WARPLAYBACK_LISTSTATE_C,msg)
	end
end

--回包处理
function CSBattleList:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.OPCODE_CS_MYPLAYBACK_S then
		local msg = CsBattle_pb.OPCSBattleFetchMyBattleRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveMyBattle(container, msg)
		return
	end
	if opcode == opcodes.OPCODE_CS_WARPLAYBACK_LISTSTATE_S then
		local msg = CsBattle_pb.OPCSBattleRequestVsInfoRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveListState(container, msg)
		return
	end
    if opcode == opcodes.OPCODE_CS_WARPLAYBACK_S then
		local msg = Battle_pb.BattleInfo()
		msg:ParseFromString(msgBuff)
		--self:onReceivePlaybackInfo(container, msg)
		local enemyName = ""
		local myName = ""
		assert(msg.battleData.character,"no character in CSbattle")
		table.foreachi(msg.battleData.character,function( i,v )
			if v.pos==0 then
				myName = v.name
			elseif v.pos==1 then
				enemyName = v.name
			end
		end)
        PageManager.viewBattlePage(msg,myName,enemyName)
		return
	end
	if opcode == opcodes.OPCODE_USER_BATTLERET_S then
		PageManager.viewBattlePage(msgBuff)
		return
	end

    if opcode == opcodes.OPCODE_CS_BATTLEARRAY_INFO_S then
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

function CSBattleList:getPlayerInfo(csPlayerInfo)
	local playerInfo = {
		discipleId = csPlayerInfo.playerItemId,
		name = csPlayerInfo.playerName,
		id = csPlayerInfo.playerIdentify
	}
	if csPlayerInfo:HasField("serverName") then
		playerInfo.serverName = csPlayerInfo.serverName
	end
	return playerInfo
end

function CSBattleList:onReceiveMyBattle(container, msg)
	local battles = {}
	for _, vsInfo in ipairs(msg.myBattleVs) do
		local battle = {
			id = vsInfo.vsIdentify,
			battleId = vsInfo.battleId,
			leftPlayer = CSTools.getPlayerInfo(vsInfo.player1),
			stage = vsInfo.battleStage,
			hasChangePos = false
		}
		if vsInfo:HasField("player2") then
			battle.rightPlayer = CSTools.getPlayerInfo(vsInfo.player2)

			if battle.rightPlayer.id == msg.playerIdentify then
				local tmp = battle.rightPlayer;
				battle.rightPlayer = battle.leftPlayer;
				battle.leftPlayer = tmp;
				battle.hasChangePos = true;
			end
		end
		if vsInfo:HasField("winnerPlayer") then
			battle.winner = vsInfo.winnerPlayer
		end
		table.insert(battles, battle)
	end

	local isCsKnockout = msg.csGoingStage > 0 and CSTools.isCrossBattleBegin(battleInfo.battleId)
	local loseCount = 0
	for _, vsInfo in ipairs(msg.konckoutVs) do
		local battle = {
			isKnockout = true,
			id = vsInfo.vsIdentify,
			battleId = vsInfo.battleId,
			leftPlayer = CSTools.getPlayerInfo(vsInfo.player1),
			stage = vsInfo.battleStage,
			groupId = vsInfo.battleGroup,
			hasChangePos = false
		}
		if vsInfo:HasField("player2") then
			battle.rightPlayer = CSTools.getPlayerInfo(vsInfo.player2)
			
		    if battle.rightPlayer.id == msg.playerIdentify then
				local tmp = battle.rightPlayer;
				battle.rightPlayer = battle.leftPlayer;
				battle.leftPlayer = tmp;
				battle.hasChangePos = true;
			end
		end
		if vsInfo:HasField("winnerPlayer") then
			battle.winner = vsInfo.winnerPlayer
		end
		table.insert(battles, battle)
		if not (isCsKnockout and battle.stage <= msg.lsGoingStage) then
			loseCount = loseCount + 1
		end
	end

	table.sort(battles, sortMyGame)
	battleInfo.battleList = battles
	battleInfo.result = {
		isCsKnockout = isCsKnockout,
		isInWinnerGroup = (isCsKnockout and msg.csGoingGroup or msg.lsGoingGroup) == GroupId.Winner,
		loseCount = loseCount,
		winCount = (isCsKnockout and msg.totalCsKonckout or msg.totalLsKonckout) - loseCount,
		rankStage = isCsKnockout and msg.csGoingStage or msg.lsGoingStage
	}
	self:rebuildAllItem(container)
end

function CSBattleList:onReceiveListState(container, msg)
	if not msg.resultOK then
		MessageBoxPage:Msg_Box_Lan("@GetBattleListStateFailed")
		self:rebuildAllItem(container)
		return
	end

	local vsInfo = battleInfo.vsInfo
	for _, winner in ipairs(msg.winnerId) do
		local battle = common:deepCopy(vsInfo)
		if battle.hasChangePos then
		    battle.winner = winner == WinnerType.Left and vsInfo.rightPlayer.id or vsInfo.leftPlayer.id
		else
		    battle.winner = winner == WinnerType.Right and vsInfo.rightPlayer.id or vsInfo.leftPlayer.id
		end
		table.insert(battleInfo.battleList, battle)
	end
	self:rebuildAllItem(container)
end

function CSBattleList:onReceivePlaybackInfo(container, msg)
	if not msg.resultOK then
		MessageBoxPage:Msg_Box_Lan("@CSWarPlaybackNotGot")
	end
end

function CSBattleList:onReceiveMessage(container)
    local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:getBattleList(container)
		end
	end
end

function CSBattleList:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function CSBattleList:buildItem(container)
	local isMyGame = battleInfo.battleType == BattleList.Type_MyBattle
	local titleKey = isMyGame and "@CSMyBattle" or "@CSBattlePlayback"
	local lb2Str = {
		mPopUpTitle = common:getLanguageString(titleKey)
	}
	if isMyGame then
		local isCsKnockout = battleInfo.result.isCsKnockout
		local battleName = CSTools.getKnockoutBattleName(isCsKnockout)
		local winCount = battleInfo.result.winCount
		local loseCount = battleInfo.result.loseCount
		local rank = CSTools.stageToRank(battleInfo.result.rankStage, not isCsKnockout)
		--2强 还是 亚军
		if rank == 2 and CSTools.isBeforeTheFinal(battleInfo.battleId, isCsKnockout) then
			rank = 3
		end
		local rankStr = common:getLanguageString("@CSBattleRank_" .. rank)
		if rank ~= 0 then
			local groupStr = battleInfo.result.isInWinnerGroup and "@FourEmperor" or "@TheSupernova"
			rankStr = common:getLanguageString(groupStr) .. rankStr
		end
		lb2Str["mTheWarTimesTex"] = common:getLanguageString("@CSKnockoutCount", battleName, winCount, loseCount, rankStr)
	end
    if Golb_Platform_Info.is_r2_platform then
        NodeHelper:MoveAndScaleNode(container, lb2Str,0,0.7)
    else
        NodeHelper:setStringForLabel(container, lb2Str)
    end
    --NodeHelper:setLabelOneByOne(container, "mPopUpTitle", "mTheWarTimesTex", 5 , true);
    if Golb_Platform_Info.is_r2_platform then
        NodeHelper:setNodesVisible(container,{mPopUpTitle = false});
        NodeHelper:SetNodePostion(container, "mTheWarTimesTex",-50,0)
        
    end
	self:switchScrollView(container)
	NodeHelper:buildScrollView(container,#battleInfo.battleList,CSBattleListItem.ccbiFile,CSBattleListItem.onFunction)
end
function CSBattleList:switchScrollView(container)
	local isMyGame = battleInfo.battleType == BattleList.Type_MyBattle
	local svName = isMyGame and "mPopUpSV2" or "mPopUpSV"
	container:getVarNode("mPopUpTexNode"):setVisible(isMyGame)
	container:getVarNode("mPopUPSV2"):setVisible(isMyGame)
	container:getVarScrollView("mPopUpSV"):setVisible(not isMyGame)
	NodeHelper:initScrollView(container,svName)
end
function CSBattleList:clearAllItem(container)
	NodeHelper:clearScrollView(container)
end
function CSBattleList:onClose(container)
	PageManager.popPage(thisPageName)
end
function CSBattleList:onExit(container)
	GlobalData.ViewCSPlayerBattleContentId = nil
	NodeHelper:deleteScrollView(container)
	self:removePacket(container)
	container:removeMessage(MSG_MAINFRAME_REFRESH)
end
function CSBattleList:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end
function CSBattleList:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
--------------------------------------------------------------------------------
local CSBattleListPage = CommonPage.newSub(CSBattleList, thisPageName, option)
