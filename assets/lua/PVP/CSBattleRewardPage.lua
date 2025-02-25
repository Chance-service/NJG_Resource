
----------------------------------------------------------------------------------
local CsBattle_pb = require("CsBattle_pb")
local NodeHelper = require("NodeHelper")
--require "Convert_pb"
local RoleCfg = ConfigManager.getRoleCfg()
local CSTools = require("PVP.CSTools")
local CommonPage = require("CommonPage");
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "CSBattleRewardPage"
local opcodes = {
	OPCODE_CS_SHOW_REWARDS_C = HP_pb.OPCODE_CS_SHOW_REWARDS_C,
	OPCODE_CS_SHOW_REWARDS_S = HP_pb.OPCODE_CS_SHOW_REWARDS_S,
	OPCODE_CS_GET_REWARD_RANK_C = HP_pb.OPCODE_CS_GET_REWARD_RANK_C,
	OPCODE_CS_GET_REWARD_RANK_S = HP_pb.OPCODE_CS_GET_REWARD_RANK_S,
	OPCODE_CS_GET_REWARD_BET_C = HP_pb.OPCODE_CS_GET_REWARD_BET_C,
	OPCODE_CS_GET_REWARD_BET_S = HP_pb.OPCODE_CS_GET_REWARD_BET_S,
	OPCODE_GOT_REWARDS = HP_pb.OPCODE_GOT_REWARDS,
	OPCODE_CONVERT_INFO_C = HP_pb.OPCODE_CONVERT_INFO_C,
	OPCODE_CONVERT_INFO_S = HP_pb.OPCODE_CONVERT_INFO_S,
	OPCODE_CONVERT_DO_CONVERT_C = HP_pb.OPCODE_CONVERT_DO_CONVERT_C,
	OPCODE_CONVERT_DO_CONVERT_S = HP_pb.OPCODE_CONVERT_DO_CONVERT_S,
    OPCODE_CS_BATTLEARRAY_INFO_C = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_C,
	OPCODE_CS_BATTLEARRAY_INFO_S = HP_pb.OPCODE_CS_BATTLEARRAY_INFO_S
}
local AdventureId_Exchange = 52

USER_PROPERTY = 10000;
USER_PROPERTY_SILVER_COINS = 1002;

local option = {
	ccbiFile = "CrossServerWarReward.ccbi",
	handlerMap = {
		onLocalWOTK		= "switchRewardType",
		onCrossWOTK 	= "switchRewardType",
		onBPReward		= "switchRewardType",
		onMidReward		= "goExchange",
		onFourEmperor	= "switchGroupId",
		onTheSupernova	= "switchGroupId",
		onBack			= "onBack"
	},
	opcode = opcodes
}

local CSBattleReward = {}

local RewardType = {
	LocalServer = 1,
	CrossServer = 2,
	Bet			= 3,
	Exchange	= 4
}
local GroupId = {
	Winner	= 1,
	Loser	= 2,
	Size	= 2
}

local RewardType2BtnName = {
	[RewardType.LocalServer]	= "mLocalWOTK",
	[RewardType.CrossServer] 	= "mCrossWOTK",
	[RewardType.Bet]			= "mBPReward",
	[RewardType.Exchange]		= "mMidReward"
}
--回按钮选中效果不明显，故将选中的高亮(unselected),未选中的变暗(selected)
--所以此处按钮名与groupId是反对应的
local GroupId2BtnName = {
	[GroupId.Winner]	= "mFourEmperor",
	[GroupId.Loser]		= "mTheSupernova"
}

local rewardInfo = {
	battleId 	= 1,
	rewardType 	= RewardType.LocalServer,
	groupId		= GroupId.Winner,
	exchanges	= {},
}
if UserInfo.roleInfo.prof==1 then
	rewardInfo.rewardItems = ConfigManager.getCSWarriorRewardConfig()
elseif UserInfo.roleInfo.prof==2 then
	rewardInfo.rewardItems = ConfigManager.getCSHunterRewardConfig()
elseif UserInfo.roleInfo.prof==3 then
	rewardInfo.rewardItems = ConfigManager.getCSMagicianRewardConfig()
end

local RewardState = {
	UNABLE   = 1,
	ENABLE   = 2,
	RECEIVED = 3
}

--table of (rank, state)
local rankStatus = {}

--table of (vsPlayer, hasBet, state)
local betStatus = {}

local function getRankType()
	return (rewardInfo.rewardType - 1) * GroupId.Size + rewardInfo.groupId
end

local function getRewardStatus()
	if rewardInfo.rewardType == RewardType.Bet then
		return betStatus
	end
	return (rankStatus or {})[getRankType()]
end

local function getRankRewardId()
	return (getRewardStatus() or {})['rank'] or 0
end
----------------------------------------------------------------------------------
--scrollview 中的单个item
--------------------------------------------
local CSBattleRewardItem = {
	ccbiFile = "CrossServerWarRewardContent1.ccbi"
}

function CSBattleRewardItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		CSBattleRewardItem.onRefreshItemView(container)
	elseif eventName == "onDrawBtn" then
		CSBattleRewardItem.onGetReward(container)
	elseif tostring(eventName):sub(1, -2) == "onRewardFrame" then
		CSBattleRewardItem.showResInfo(container, tostring(eventName):sub(-1) + 0)
	end
end

function CSBattleRewardItem.onRefreshItemView(container)
	local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID
	local rewardItem = items[rewardContentId]

	local isFinalWinners = rewardContentId == 1 or rewardContentId == 2 --1: champion, 2: second place
	NodeHelper:setNodeVisible(container:getVarNode("mRewardNode1"), not isFinalWinners)
	NodeHelper:setNodeVisible(container:getVarNode("mRewardNode2"), isFinalWinners)

	if isFinalWinners then
	--	local rewardTexture = common:getSettingVar(string.format("CS_Reward_Title_Num_%d", rewardContentId))
	--	container:getVarSprite("mWarRewardPic"):setTexture(rewardTexture)
		local rewardDic = common:getSettingVar(string.format("CS_Reward_Title_Num_%d", rewardContentId))
		container:getVarLabelTTF("mWarRewardTex"):setString(common:getLanguageString(rewardDic))
	else
	--	local rewardTexture = string.format(common:getSettingVar("CS_Reward_Title_Num"), rewardContentId)
	--	container:getVarSprite("mRewardNumPic"):setTexture(rewardTexture)
		local rewardDic = string.format(common:getSettingVar("CS_Reward_Title_Num"), rewardContentId)
		container:getVarLabelTTF("mWarRewardNumTex"):setString(common:getLanguageString(rewardDic,rewardContentId))
	end

	local rewardStatus = getRewardStatus() or {}
	local lb2Str = {}
    
--	local rewardObj = Split(common:trim(rewardItem), ",")
	local scale = container:getVarSprite("mRewardItem1"):getScale()
	for k = 1, 4 do
		local rewardInfo = rewardItem[k]
		local hasRewardInfo = rewardInfo ~= nil

		local itemNode = container:getVarNode("mItemNode" .. k)
		itemNode:setVisible(hasRewardInfo)

		if hasRewardInfo then
       
            local rewardsType = rewardInfo.type
            local rewardsId = rewardInfo.itemId
            local rewardsQuantity = rewardInfo.count
			--local rewardsType, rewardsId, rewardsQuantity = unpack(Split(rewardInfo, ":"))
			local reward = ResManagerForLua:getResInfoByTypeAndId(rewardsType, rewardsId, rewardsQuantity)

			local iconNode = container:getVarSprite("mRewardItem" .. k)
			iconNode:setTexture(reward.icon)
			--NodeHelper:setScaleByResInfoType(iconNode, reward.itemType, scale)

			local qualityNode = container:getVarMenuItemImage("mRewardFrame" .. k)
            local qualityTab = {}
            qualityTab["mRewardFrame" .. k] = reward.quality
            NodeHelper:setQualityFrames( container , qualityTab )
            if Golb_Platform_Info.is_r2_platform then
                if rewardsQuantity >= 1000 then
                    rewardsQuantity = rewardsQuantity/1000 .. "K"
                end
            else
                rewardsQuantity = GameUtil:formatNumber(rewardsQuantity);
            end
			
            lb2Str[string.format("mRewardItemNum%d", k)] = rewardsQuantity
		end
	end
	NodeHelper:setStringForLabel(container, lb2Str)

	local hasRankReward = not rewardStatus.state
	local canReward = hasRankReward and getRankRewardId() == rewardContentId
	container:getVarMenuItem("mDrawBtn"):setEnabled(canReward)
    if not canReward and getRankRewardId() == rewardContentId then
        container:getVarLabelBMFont("mDrawTex"):setString( common:getLanguageString( "@HasDraw" ) )
    else
        container:getVarLabelBMFont("mDrawTex"):setString( common:getLanguageString( "@Draw" ) )
    end
end

--点击领奖事件处理
function CSBattleRewardItem.onGetReward(container)
	CSBattleRewardItem.sendPacketForReward(container)
end

function CSBattleRewardItem.sendPacketForReward(container)
	local msg = CsBattle_pb.OPCSBattleFetchAward()
	msg.battleId = rewardInfo.battleId
	msg.rankType = getRankType()
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CS_GET_REWARD_RANK_C, pb_data, #pb_data, true)
end

--展示奖励描述信息
function CSBattleRewardItem.showResInfo(container, resIndex)
	local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID
	local rewardItem = items[rewardContentId]
   
	--local rewardObj = Split(common:trim(rewardItem), ",")
    
	--local rewardsType, rewardsId = unpack(Split(rewardObj[resIndex], ":"))
    local resCfg = rewardItem[resIndex]
	if resCfg ~= nil then
	    GameUtil:showTip( container:getVarNode(string.format("mRewardFrame%d", resIndex)), resCfg )
    end
end
--------------------------------------------------------------
local CSBattleBetRewardItem = {
	ccbiFile = "CrossServerWarRewardContent2.ccbi"
}

function CSBattleBetRewardItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		CSBattleBetRewardItem.onRefreshItemView(container)
	elseif eventName == "onDrawBtn" then
		CSBattleBetRewardItem.onGetReward(container)
    elseif eventName == "onLeftFrame" then
        CSBattleBetRewardItem.clickLeftFrame( container )
    elseif eventName == "onRightFrame" then
        CSBattleBetRewardItem.clickRightFrame( container )
	end
end

function CSBattleBetRewardItem.onRefreshItemView(container)
	local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID
	local rewardItem = items[rewardContentId]

	local leftPlayer = rewardItem.leftPlayer
	local rightPlayer = rewardItem.rightPlayer or {}
	local lb2Str = {
		mBPRewardTitle 	 = common:getLanguageString("@CSBattleName_" .. rewardContentId),
		mRewardNum		 = CSBattleBetRewardItem.getSilverCount(rewardItem.reward),
		mBetNum 		 = CSBattleBetRewardItem.getSilverCount(rewardItem.bet),
		mLeftServer		 = leftPlayer.serverName,
		mRightServer	 = rightPlayer.serverName or ""
	}

	NodeHelper:setStringForLabel(container, lb2Str)
	NodeHelper:setStringForTTFLabel(container, {
		mLeftPlayerName	 = leftPlayer.name,
		mRightPlayerName = rightPlayer.name or ""
	})
	local winnerId = common:trim(rewardItem.winner)
	local betPlayerId = rewardItem.betPlayerId
	CSBattleBetRewardItem.showPlayerIcon(container, leftPlayer.discipleId, rightPlayer.discipleId)
	CSBattleBetRewardItem.showPlayerState(container, true, winnerId == "" or winnerId == leftPlayer.id, betPlayerId == leftPlayer.id)
	CSBattleBetRewardItem.showPlayerState(container, false, winnerId == "" or winnerId == rightPlayer.id, betPlayerId == rightPlayer.id)

	local isGoingOn = CSTools.isBetGoingOn(rewardInfo.battleId, rewardContentId)
	container:getVarNode("mUnderwayNode"):setVisible(isGoingOn)
	container:getVarNode("mEndedNode"):setVisible(not isGoingOn)

	container:getVarMenuItem("mDrawBtn"):setEnabled(rewardItem.state == RewardState.ENABLE)
end

function CSBattleBetRewardItem.clickLeftFrame( container )
    local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID

    local status = betStatus[rewardContentId]
    CSBattleBetRewardItem.requirePlayerInfo( status.leftPlayer ) 
end

function CSBattleBetRewardItem.clickRightFrame( container )
    local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID

	local status = betStatus[rewardContentId]
    CSBattleBetRewardItem.requirePlayerInfo( status.rightPlayer ) 
end

function CSBattleBetRewardItem.requirePlayerInfo( player )
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
					PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CS_BATTLEARRAY_INFO_C,pb_data,#pb_data,true);
					--ScriptMathToLua:showTeamBattleView(tonumber(player),1,false);
				--end
			end
		end
	end
end

function CSBattleBetRewardItem.showPlayerState(container, isLeftPos, isWinner, hasBeted)
	local pos = isLeftPos and "Left" or "Right"
	local state = isWinner and "Win" or "Lose"
	local bgPic = common:getSettingVar(string.format("CSBattlePlayerBg_%s_%s", pos, state))
	container:getVarSprite(string.format("m%sPic", pos)):setTexture(bgPic)
	NodeHelper:setNodeVisible(container:getVarNode(string.format("m%sChargePic", pos)), hasBeted)
end

function CSBattleBetRewardItem.showPlayerIcon(container, leftDiscipleId, rightDiscipleId)
	if leftDiscipleId then
		local discipleLeftPic = RoleCfg[leftDiscipleId].icon;
		container:getVarSprite("mLeftMemPic"):setTexture( discipleLeftPic )
		--common:setFrameQuality(container:getVarMenuItemImage("mLeftFrame"), leftDisciple.quality)
	end
	if rightDiscipleId then
		local discipleRightPic = RoleCfg[rightDiscipleId].icon;
		container:getVarSprite("mRightMemPic"):setTexture(discipleRightPic)
		--common:setFrameQuality(container:getVarMenuItemImage("mRightFrame"), rightDisciple.quality)
	else
		container:getVarSprite("mRightMemPic"):setTexture(common:getSettingVar("CSBattleEmpty_Icon"))
	--	common:setFrameQuality(container:getVarMenuItemImage("mRightFrame"))
	end
end

function CSBattleBetRewardItem.getSilverCount(bagStr)


--	local rewardObj = Split(common:trim(bagStr), ",")
--	for _, rewardStr in ipairs(rewardObj) do
		--local itemType, itemId, itemCount = unpack(Split(rewardStr, ":"))

    for i=1,#bagStr do 
        local itemType = bagStr[i].type
        local itemId = bagStr[i].itemId
        local itemCount = bagStr[i].count
		if tonumber(itemType) == USER_PROPERTY and tonumber(itemId) == USER_PROPERTY_SILVER_COINS then
			return tonumber(itemCount)
		end
	end
	return 0
end

--点击领奖事件处理
function CSBattleBetRewardItem.onGetReward(container)
	CSBattleBetRewardItem.sendPacketForReward(container)
end

function CSBattleBetRewardItem.sendPacketForReward(container)
	local msg = CsBattle_pb.OPCSBattleFetchBetAward()
	msg.battleId = rewardInfo.battleId
	msg.betStage = container:getItemDate().mID
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CS_GET_REWARD_BET_C, pb_data, #pb_data, true)
end

--------------------------------------------------------------------------
local CSBattleExchangeRewardItem = {
	ccbiFile = "MidAutumnExchangeContent.ccbi"
}

function CSBattleExchangeRewardItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		CSBattleExchangeRewardItem.onRefreshItemView(container)
    elseif eventName == "onMAECButton" then
        CSBattleExchangeRewardItem.doExchange(container)
    elseif eventName == "MAECFaceTarget" then
		CSBattleExchangeRewardItem.showResInfo(container)
	end
end

function CSBattleExchangeRewardItem.onRefreshItemView(container)
	local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardContentId = container:getItemDate().mID
	local rewardItem = items[rewardContentId]
    local scale = container:getVarSprite("mMAECIcoPic1"):getScale()

	for i = 1, 3 do
		local consumeCfg = rewardItem.consumes[i]
		local hasConsume = not not consumeCfg

		container:getVarLabelBMFont("mMAECEqNameNum" .. i):setVisible(hasConsume)
		container:getVarLabelBMFont("mMAECNum" .. i):setVisible(hasConsume)
		container:getVarSprite("mMAECIcoPic" .. i):setVisible(hasConsume)
		container:getVarMenuItemImage("mMAECFace" .. i):setVisible(hasConsume)

		if hasConsume then
			local info =ResManagerForLua:getResInfoByTypeAndId(consumeCfg.type, consumeCfg.id, consumeCfg.count)
			container:getVarLabelBMFont("mMAECEqNameNum" .. i):setString(info.name)
			container:getVarLabelBMFont("mMAECNum" .. i):setString(string.format("(%d/%d)", consumeCfg.ownedCount, consumeCfg.count))
			container:getVarSprite("mMAECIcoPic" .. i):setTexture(info.icon)
			common:setScaleByResInfoType(container:getVarSprite("mMAECIcoPic" .. i), info.quality, scale)
			common:setFrameQuality(container:getVarMenuItemImage("mMAECFace" .. i), info.quality)
		end
	end

	local target = rewardItem.target
	local infoTarget = ResManagerForLua:getResInfoByTypeAndId(target.type, target.id, target.count)
	container:getVarLabelBMFont("mMAECEqNameNumTarget"):setString(infoTarget.name)
	container:getVarLabelBMFont("mMAECNumTarget"):setString(string.format("(%d)", target.count))

	container:getVarSprite("mMAECIcoPicTarget"):setTexture(infoTarget.icon)

	common:setScaleByResInfoType(container:getVarSprite("mMAECIcoPicTarget"), infoTarget.quality, scale)
	common:setFrameQuality(container:getVarMenuItemImage("mMAECFaceTarget"), infoTarget.quality)

	container:getVarLabelBMFont("mMAECExChangeNum"):setVisible(false)
end

--点击领奖事件处理
function CSBattleExchangeRewardItem.doExchange(container)
	CSBattleExchangeRewardItem.sendPacketForReward(container)
end

function CSBattleExchangeRewardItem.sendPacketForReward(container)
	local msg = Convert_pb.OPConvert()
	msg.adventureId = AdventureId_Exchange
	msg.id = container:getItemDate().mID + 0
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CONVERT_DO_CONVERT_C, pb_data, #pb_data, true)
end

--展示奖励描述信息
function CSBattleExchangeRewardItem.showResInfo(container, resIndex)
	local items = CSBattleReward:getRewardItems()
	if not items then return end
	local rewardItem = items[container:getItemDate().mID]
	local resCfg = rewardItem.target
    if resCfg ~= nil then
	    GameUtil:showTip( container:getVarNode(string.format("mRewardFrame", resIndex)), resCfg )
    end

end

----------------------------------------------------------------------------------
--CSBattleReward页面中的事件处理
----------------------------------------------
function CSBattleReward:onEnter(container)
    local CSManager = require("PVP.CSManager")
	self:registerPacket(container)

	self:getRewardInfo(container)
	container:getVarNode("mMainBtnNode"):setVisible(false)
	container:getVarMenuItemImage(RewardType2BtnName[rewardInfo.rewardType]):selected()
	container:getVarMenuItemImage(GroupId2BtnName[rewardInfo.groupId]):selected()
    --container:getVarMenuItemImage(GroupId2BtnName[rewardInfo.groupId]):setEnabled(false)

    container:getVarMenuItemImage(GroupId2BtnName[ 3 - rewardInfo.groupId ]):unselected()
    --container:getVarMenuItemImage(GroupId2BtnName[ 3 - rewardInfo.groupId ]):setEnabled(true)
    local currentCount = tonumber(CSManager.WarStateCache.openState and CSManager.WarStateCache.openState.battleId or CSManager.WarStateCache.closeState.battleId )
    --local picStr = "UI/CrossServerWar/u_CrossServerWarTitleNum"..currentCount..".png";
 
	container:getVarLabelTTF("mTitleNumSubTitle"):setString(common:getLanguageString("@CSTimeOfCS",currentCount));

    CSBattleReward:adaptationScrollView( container )
    NodeHelper:setLabelOneByOne(container, "mYourRanking", "mYourRankingNum", 5, true)
      --代码控制修改title的大小。修改ccbi对其他版本有影响
    if Golb_Platform_Info.is_r2_platform then
       	local VarTable = {
		    mLocalWOTKBtn = common:getLanguageString("@LocalWOTK"),
            mCrossWOTKBtn = common:getLanguageString("@CrossWOTK"),
            mBPRewardBtn = common:getLanguageString("@BPReward"),
	    };
       NodeHelper:MoveAndScaleNode(container,VarTable,0,0.7);
    end
    
end

--发包获取活动信息
function CSBattleReward:getRewardInfo(container)
	local msg = CsBattle_pb.OPCSBattleRequestAwardInfo()
	msg.battleId = rewardInfo.battleId

	local pb_data = msg:SerializeToString()
	container:sendPakcet(opcodes.OPCODE_CS_SHOW_REWARDS_C, pb_data, #pb_data, true)
end

--回包处理
function CSBattleReward:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == opcodes.OPCODE_CS_SHOW_REWARDS_S then
		local msg = CsBattle_pb.OPCSBattleRequestAwardInfoRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveRewardInfo(container, msg)
		return
	end

    if opcode == opcodes.OPCODE_CS_GET_REWARD_RANK_S then
		local msg = CsBattle_pb.OPCSBattleFetchAwardRet()
		msg:ParseFromString(msgBuff)
		self:onFetchRewardRet(container, msg)
		return
	end

    if opcode == opcodes.OPCODE_CS_GET_REWARD_BET_S then
		local msg = CsBattle_pb.OPCSBattleFetchBetAwardRet()
		msg:ParseFromString(msgBuff)
		self:onFetchBetRewardRet(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_GOT_REWARDS then
		local msg = UserRewards_pb.OPUserRewardRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveReward(container, msg)
		return
	end
    if opcode == opcodes.OPCODE_CONVERT_INFO_S then
		local msg = Convert_pb.OPConvertInfoRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveExchangeInfo(container, msg)
		return
	end

	if opcode == opcodes.OPCODE_CONVERT_DO_CONVERT_S then
		local msg = Convert_pb.OPConvertRet()
		msg:ParseFromString(msgBuff)
		self:onReceiveExchangeRet(container, msg)
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

function CSBattleReward:onReceiveRewardInfo(container, msg)
	for _, info in ipairs(msg.awardInfo) do
		local isLocal = info.rankType <= GroupId.Size
		rankStatus[info.rankType] = {
			rank = CSTools.stageToRank(info.finalStage, isLocal),
			state = info.drawed
		}
	end
	for _, info in ipairs(msg.betAwardInfo) do
		local vsPlayer = info.vsPlayer
		local status = {
			leftPlayer = CSTools.getPlayerInfo(vsPlayer.player1),
			betPlayerId = info.betPlayer,
			state = info.awardState
		}
		if vsPlayer:HasField("player2") then
			status.rightPlayer = CSTools.getPlayerInfo(vsPlayer.player2)

			if status.rightPlayer.id == msg.playerIdentify then
				local tmp = status.rightPlayer;
				status.rightPlayer = status.leftPlayer;
				status.leftPlayer = tmp;
			end
		end
		if vsPlayer:HasField("winnerPlayer") then
			status.winner = vsPlayer.winnerPlayer
		end
		betStatus[vsPlayer.battleStage] = status
	end
	self:rebuildAllItem(container)
end

function CSBattleReward:onFetchRewardRet(container, msg)
	if not msg.fetchSucc then
		MessageBoxPage:Msg_Box("@FetchRewardFailed")
		return
	end
	local status = rankStatus[msg.rankType]
	status.rank = CSTools.stageToRank(msg.finalStage)
	status.state = msg.drawed
	self:refreshContent(container)
end

function CSBattleReward:onFetchBetRewardRet(container, msg)
	if not msg.fetchSucc then
		MessageBoxPage:Msg_Box("@FetchBetRewardFailed")
		return
	end
	local status = betStatus[msg.betStage]
	status.state = msg.awardState
	self:refreshContent(container)
end

function CSBattleReward:onReceiveExchangeInfo(container, msg)
	rewardInfo.exchanges = {}
	for _, item in ipairs(msg.item) do
		local target = item.target;
		local exchange = {
			target = {
				type = target.targetsType,
				id = target.targetsId,
				count = target.targetsQuantity
			},
			consumes = {}
		}
		for _, consume in ipairs(item.consume) do
			table.insert(exchange.consumes, {
				type = consume.consumesType,
				id = consume.consumesId,
				count = consume.consumesQuantity,
				ownedCount = consume.itemCount
			})
		end
		table.insert(rewardInfo.exchanges, exchange)
	end
	self:switchRewardType(container, "onMidReward")
end

function CSBattleReward:onReceiveReward(container, msg)
	if msg:HasField("errorCode") then
		MessageBoxPage:Msg_Box("@CSRewardError" .. msg.errorCode)
		return
	end
	local rewardMsg = {
		discipleInfo = msg.discipleInfo,
		soulInfo = msg.soulInfo,
		toolInfo = msg.toolInfo,
		equipInfo = msg.equipInfo,
		skillInfo = msg.skillInfo,
		skillBookInfo = msg.skillBookPartItem
	}
	if msg:HasField("silver") then
		rewardMsg.silverCoins = msg.silver
	end
	if msg:HasField("gold") then
		rewardMsg.goldCoins = msg.gold
	end
	DropManager.gotRewards(rewardMsg)

	self:prepareRewardView(msg.reward)
	MainFrame:getInstance():pushPage("GoodsShowListPage")
end

function CSBattleReward:onReceiveExchangeRet(container, msg)
	if msg:HasField("errorCode") then
		MessageBoxPage:Msg_Box("@AdventureConvertError" .. msg.errorCode)
		return
	end

	local rewardMsg = {
		discipleInfo = msg.discipleInfo,
		soulInfo = msg.soulInfo,
		toolInfo = msg.toolInfo,
		equipInfo = msg.equipInfo,
		skillInfo = msg.skillInfo,
		skillBookInfo = msg.skillBookPartItem
	}
	if msg:HasField("silverCoins") then
		rewardMsg.silverCoins = msg.silverCoins
	end
	if msg:HasField("goldCoins") then
		rewardMsg.goldCoins = msg.goldCoins
	end
	DropManager.gotRewards(rewardMsg)
	for _, info in ipairs(msg.deletedEquip) do
		ServerDateManager:getInstance():removeEquipInfoById(info)
	end
	for _, info in ipairs(msg.deleteSkill) do
		ServerDateManager:getInstance():removeSkillInfoById(info)
	end

	self:prepareRewardView(msg.reward)
	MainFrame:getInstance():pushPage("GoodsShowListPage")

	if msg:HasField("converInfo") then
		self:onReceiveExchangeInfo(container, msg.converInfo)
	end
	self:refreshContent(container)
end

function CSBattleReward:rebuildAllItem(container)
	self:clearAllItem(container);
	self:buildItem(container);
end

function CSBattleReward:buildItem(container)
	if rewardInfo.rewardType ~= RewardType.Bet then
		local rewardStatus = getRewardStatus() or {}
		local lb2Str = {
			mYourRankingNum = common:getLanguageString(string.format("@CSBattleRank_%d", rewardStatus.rank or 999))
		}
		NodeHelper:setStringForLabel(container, lb2Str)
	end
	self:switchScrollView(container)
    --NodeHelper:initScrollView(container, "mContent", 4)
	self:initScrollView(container)
end

function CSBattleReward:switchScrollView(container)
	local isRankType = rewardInfo.rewardType == RewardType.LocalServer or rewardInfo.rewardType == RewardType.CrossServer
	local svName = isRankType and "mRewardSV" or "mBPRewardSV"
	container:getVarNode("mMainBtnNode"):setVisible(isRankType)
	container:getVarScrollView("mBPRewardSV"):setVisible(not isRankType)
	container.mScrollView = container:getVarScrollView(svName)
	container.mScrollViewRootNode = container.mScrollView:getContainer()
	container.m_pScrollViewFacade = CCReViScrollViewFacade:new(container.mScrollView)
	container.m_pScrollViewFacade:init(6,6)
end

function CSBattleReward:adaptationScrollView( container )
    local scrollView1 = container:getVarScrollView( "mRewardSV" )
    local scrollView2 = container:getVarScrollView( "mBPRewardSV" )

    if scrollView1 ~= nil then
		container:autoAdjustResizeScrollview( scrollView1 )
	end
	
    if scrollView2 ~= nil then
		container:autoAdjustResizeScrollview( scrollView2 )
	end

    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end

end

function CSBattleReward:getRewardItems()
	local items = {}
	local rType = rewardInfo.rewardType
	if rType == RewardType.Bet then
		local rawItems = CSTools.getBetConfig(rewardInfo.battleId)
		for id, status in pairs(getRewardStatus() or {}) do
			items[id] = status
            items[id]['bet'] = {}
            items[id]['reward'] = {}
            local _type, _id, _count = unpack( common:split(rawItems[id]['bet'], "_") );
			table.insert( items[id]['bet'] , {
                type 	= tonumber(_type),
				itemId	= tonumber(_id),
				count 	= tonumber(_count)
            })
            local _typeReward, _idReward, _countReward = unpack( common:split(rawItems[id]['reward'], "_") );
			table.insert(items[id]['reward'] , {
                type 	= tonumber(_typeReward),
				itemId	= tonumber(_idReward),
				count 	= tonumber(_countReward)
            })
		end
		return items
	end

	if rType == RewardType.Exchange then
		return rewardInfo.exchanges
--		return ConfigManager.getCSExchange()
	end

	local groupId = rewardInfo.groupId
    local rewardsItem = rewardInfo.rewardItems[rewardInfo.battleId]

	--local rewardsItem = CSRewardsTableManager:getInstance():getCSRewardsItemBybattleId(rewardInfo.battleId)
	if rType == RewardType.LocalServer then
		if groupId == GroupId.Winner then
			items = {
				[1] = rewardsItem.perWinners1Reward,
				[2] = rewardsItem.perWinners2Reward,
				[4] = rewardsItem.perWinners4Reward,
				[8] = rewardsItem.perWinners8Reward,
				[16] = rewardsItem.perWinners16Reward
			}
		elseif groupId == GroupId.Loser then
			items = {
				[1] = rewardsItem.perLosers1Reward,
				[2] = rewardsItem.perLosers2Reward,
				[4] = rewardsItem.perLosers4Reward,
				[8] = rewardsItem.perLosers8Reward,
				[16] = rewardsItem.perLosers16Reward
			}
		end
	elseif rType == RewardType.CrossServer then
		if groupId == GroupId.Winner then
			items = {
				[1] = rewardsItem.croWinners1Reward,
				[2] = rewardsItem.croWinners2Reward,
				[4] = rewardsItem.croWinners4Reward,
				[8] = rewardsItem.croWinners8Reward,
				[16] = rewardsItem.croWinners16Reward
			}
		elseif groupId == GroupId.Loser then
			items = {
				[1] = rewardsItem.croLosers1Reward,
				[2] = rewardsItem.croLosers2Reward,
				[4] = rewardsItem.croLosers4Reward,
				[8] = rewardsItem.croLosers8Reward,
				[16] = rewardsItem.croLosers16Reward
			}
		end
	end
	return items
end

function CSBattleReward:getContentItem()
	local rType = rewardInfo.rewardType
	if rType == RewardType.Bet then
		return CSBattleBetRewardItem
	elseif rType == RewardType.Exchange then
		return CSBattleExchangeRewardItem
	end
	return CSBattleRewardItem
end

function CSBattleReward:goExchange(container)
	local msg = Convert_pb.OPConvertInfo()
	msg.adventureId = AdventureId_Exchange
    msg.bNeedUpdate = 0
	msg.version = 1
	local pb_data = msg:SerializeToString()
	PacketManager:getInstance():sendPakcet(opcodes.OPCODE_CONVERT_INFO_C,pb_data,#pb_data,true)
end

function CSBattleReward:initScrollView(container)
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum();
	local iCount = 0;
	local fOneItemHeight = 0;
	local fOneItemWidth = 0;

	local rewardItems = self:getRewardItems()
	local contentItem = self:getContentItem()
	local topNums = common:table_keys(rewardItems)
	table.sort(topNums)
	for _, num in ipairs(topNums) do
		local pItemData = CCReViSvItemData:new()
		pItemData.mID = num
		pItemData.m_iIdx = num
		pItemData.m_ptPosition = ccp(0, fOneItemHeight * iCount)

		if iCount < iMaxNode then
			local pItem = ScriptContentBase:create(contentItem.ccbiFile)
			pItem.id = iCount
			pItem:registerFunctionHandler(contentItem.onFunction)
			if  fOneItemHeight < pItem:getContentSize().height then
				fOneItemHeight = pItem:getContentSize().height
			end
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount+1
	end
	local size = CCSizeMake(fOneItemWidth, fOneItemHeight * iCount)
	container.mScrollView:setContentSize(size);
	container.mScrollView:setContentOffset(ccp(0, container.mScrollView:getViewSize().height - container.mScrollView:getContentSize().height*container.mScrollView:getScaleY()));
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount-1);
	container.mScrollView:forceRecaculateChildren()
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end

function CSBattleReward:clearAllItem(container)
	if container.m_pScrollViewFacade then
		container.m_pScrollViewFacade:clearAllItems()
		container.mScrollViewRootNode:removeAllChildren()
	end
end

function CSBattleReward:switchRewardType(container, eventName)
	local rType = ({
		onLocalWOTK	= RewardType.LocalServer,
		onCrossWOTK	= RewardType.CrossServer,
		onBPReward	= RewardType.Bet,
		onMidReward	= RewardType.Exchange
	})[eventName]
	container:getVarMenuItemImage(RewardType2BtnName[rType]):selected()
	if rewardInfo.rewardType == rType then return end
	container:getVarMenuItemImage(RewardType2BtnName[rewardInfo.rewardType]):unselected()
	rewardInfo.rewardType = rType
	self:rebuildAllItem(container)
end

function CSBattleReward:switchGroupId(container, eventName)
	local groupId = ({
		onFourEmperor	= GroupId.Winner,
		onTheSupernova	= GroupId.Loser
	})[eventName]
	container:getVarMenuItemImage(GroupId2BtnName[groupId]):selected()
    --container:getVarMenuItemImage(GroupId2BtnName[groupId]):setEnabled(false)

    container:getVarMenuItemImage(GroupId2BtnName[ 3 - groupId ]):unselected()
    --container:getVarMenuItemImage(GroupId2BtnName[ 3 - groupId ]):setEnabled(true)
	if rewardInfo.groupId == groupId then return end
	
	rewardInfo.groupId = groupId
	self:rebuildAllItem(container)
end

function CSBattleReward:onBack(container)
	PageManager.changePage("CrossServerWar")
end

function CSBattleReward:refreshContent(container)
	self:rebuildAllItem(container)
end

--获取奖励信息展示前准备
function CSBattleReward:prepareRewardView(rewardInfo)
	common:prepareRewardPage(rewardInfo,"@RewardTitle","@RewardMsgContent")
end

function CSBattleReward:onExit(container)
	self:clearAllItem(container)
	if container.m_pScrollViewFacade then
		container.m_pScrollViewFacade:delete()
		container.m_pScrollViewFacade = nil
	end
	self:removePacket(container)
end

function CSBattleReward:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function CSBattleReward:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
-------------------------------------------------------------------------
CSBattleRewardPage = CommonPage.newSub(CSBattleReward, thisPageName, option)

function CSBattle_ShowMyBet(cBattleId)
	rewardInfo.battleId = cBattleId
	rewardInfo.rewardType = RewardType.Bet
	PageManager.changePage(thisPageName)
end

function CSBattleReward_SetBattleId(cBattleId)
	rewardInfo.battleId = cBattleId
end
