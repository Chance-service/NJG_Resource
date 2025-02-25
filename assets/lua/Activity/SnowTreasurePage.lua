
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local ResManagerForLua = require("ResManagerForLua")

local thisPageName = "SnowTreasurePage"
local COUNT_TREASURE_MAX = 12

local opcodes = {
    SNOWFIELD_TREASURE_INFO_C = HP_pb.SNOWFIELD_TREASURE_INFO_C,
    SNOWFIELD_TREASURE_INFO_S = HP_pb.SNOWFIELD_TREASURE_INFO_S,

    SNOWFIELD_BUY_PHYC_C = HP_pb.SNOWFIELD_BUY_PHYC_C,
    
    SNOWFIELD_EXCHANGE_C = HP_pb.SNOWFIELD_EXCHANGE_C,
    SNOWFIELD_EXCHANGE_S = HP_pb.SNOWFIELD_EXCHANGE_S,

    SNOWFIELD_SEARCH_C = HP_pb.SNOWFIELD_SEARCH_C,
    SNOWFIELD_SEARCH_S = HP_pb.SNOWFIELD_SEARCH_S,

    SET_CONTINUE_SEARCH_MODE_C = HP_pb.SET_CONTINUE_SEARCH_MODE_C,
    SET_CONTINUE_SEARCH_MODE_S = HP_pb.SET_CONTINUE_SEARCH_MODE_S
}

local option = {
	ccbiFile = "Act_SnowTreasureHuntPagePopUp.ccbi",
	handlerMap = {
		onReturnButton		= "onBack",
		onHelp				= "onHelp",
        onAddEnergy         = "onBuyEnergy",
        onTreasureExchange  = "onTreasureExchange",
        onFrame1            = "onShowGift",
        onCollectReward     = "onSearchSwitch",
        onHelp              = "onHelp"
	},
	opcode = opcodes
}

for i = 1, COUNT_TREASURE_MAX do
	option.handlerMap[string.format("onSnowball%d", i)] = "onTreasure"
    option.handlerMap[string.format("onSnowBallFrame%d", i)] = "onShowItem"
end

local thisActivityInfo = {
    activityId = Const_pb.SNOWFIELD_TREASURE,       -- 活动id
    activityLeftTime = 0,                           -- 活动剩余时间
    curPhyc = 0,                                    -- 当前体力
    maxPhyc = 0,                                    -- 体力最大回复上限
    nextSearchPhyc = 0,                             -- 下次寻宝所需体力
    nextPhycRecoverTime = 0,                        -- 下次体力恢复时间
    snowfieldCell = {},                             -- 雪地itemInfo
    mode = 1,                                       -- 寻宝模式 (1 单翻模式 2 连翻模式)
    continueSearchLeftTime = 0,                     -- 连翻倒计时
    curStage = 0,                                   -- 当前探宝进度
    totalStage = 0,                                 -- 探宝总进度
    todayBuyPhycTimes = 0,                          -- 今日已购买体力次数
    nextBuyPhycGold = 0,                             -- 下次购买体力价格
    isExchangedFinal = false                        -- 是否已经兑换过最终奖励
}

local timerInfo = {
    activityTimerName = "SnowTreasureActivity_" .. thisActivityInfo.activityId,
    powerTimerName = "SnowTreasureActivity_power_" .. thisActivityInfo.activityId,
    searchTimerName = "SnowTreasureActivity_search_" .. thisActivityInfo.activityId
}

local SnowTreasurePageBase = {}

-------------------------------------------------------------------------
function SnowTreasurePageBase:onEnter( container )
    self:registerPacket( container )
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    common:sendEmptyPacket( opcodes.SNOWFIELD_TREASURE_INFO_C, true )
end

function SnowTreasurePageBase:refreshView( container )
    UserInfo.syncPlayerInfo()

    local lb2Str = {
        mDiamondNUm     = UserInfo.playerInfo.gold,
        --mCD             = thisActivityInfo.activityLeftTime,
        mEnergyNum      = thisActivityInfo.curPhyc .. "/" .. thisActivityInfo.maxPhyc,
        mExplorationConsumptionNum = common:getLanguageString( "@ExplorationConsumptionNum", tostring( thisActivityInfo.nextSearchPhyc ) ),
        mRecoveryTime   = GameMaths:formatSecondsToTime(thisActivityInfo.nextPhycRecoverTime),
        mExplorationNum = "(" .. thisActivityInfo.curStage .. "/" .. thisActivityInfo.totalStage .. ")",
        --mTimeLimit      = thisActivityInfo.continueSearchLeftTime
    }
    NodeHelper:setStringForLabel( container, lb2Str )

    if thisActivityInfo.mode == 1 then
        container:getVarLabelBMFont("mTurnOnLab"):setString( common:getLanguageString("@TurnOn") )
        NodeHelper:setStringForLabel(container, { mTimeLimit = common:getLanguageString("@SnowTreasureDefaultTimes") } )
    else
        container:getVarLabelBMFont("mTurnOnLab"):setString( common:getLanguageString("@TurnOff") )
    end

    local rewardId = ActivityConfig[thisActivityInfo.activityId].reward[thisActivityInfo.curStage]
	
    local rewardParams = {
        mainNode = "mPrize",
        nameNode = "mNum",
        frameNode = "mFrame",
        picNode = "mPic",
        startIndex = 1
    }
	if rewardId~=nil then
	    local cfg = ConfigManager.getRewardById(rewardId)
	    --table.insert( cfg , ConfigManager.getRewardById(rewardId) )
        NodeHelper:fillRewardItemWithParams(container, cfg, 1,rewardParams)
    else
        container:getVarMenuItemImage( "mFrame1" ):setNormalImage( CCSprite:create( NodeHelper:getImageByQuality( 1 ) ) )
        container:getVarSprite( "mPic1" ):setTexture( GameConfig.MercenarySkillState.forbidden )
	end
    
    self:refreshItemView( container )

    if thisActivityInfo.activityLeftTime > 0 and not TimeCalculator:getInstance():hasKey(timerInfo.activityTimerName) then
		TimeCalculator:getInstance():createTimeCalcultor(timerInfo.activityTimerName, thisActivityInfo.activityLeftTime)
	end

    if thisActivityInfo.nextPhycRecoverTime > 0 and not TimeCalculator:getInstance():hasKey( timerInfo.powerTimerName ) then
        TimeCalculator:getInstance():createTimeCalcultor(timerInfo.powerTimerName, thisActivityInfo.nextPhycRecoverTime)
    end

    if thisActivityInfo.continueSearchLeftTime > 0 and not TimeCalculator:getInstance():hasKey( timerInfo.searchTimerName ) then
        TimeCalculator:getInstance():createTimeCalcultor(timerInfo.searchTimerName, thisActivityInfo.continueSearchLeftTime)
    end

end

function SnowTreasurePageBase:onActivityTimer( container )
    local timerName = timerInfo.activityTimerName
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
	if remainTime + 1 > thisActivityInfo.activityLeftTime then
		return;
	end

	thisActivityInfo.activityLeftTime = math.max(remainTime, 0)
	local timeStr = common:second2DateString(thisActivityInfo.activityLeftTime, false)
	NodeHelper:setStringForLabel(container, { mCD = timeStr } )
end

function SnowTreasurePageBase:onPowerTimer( container )
    local timerName = timerInfo.powerTimerName
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);

    if remainTime == 0 then
        common:sendEmptyPacket( opcodes.SNOWFIELD_TREASURE_INFO_C, true )
        TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.powerTimerName)
        return
    end

	if remainTime + 1 > thisActivityInfo.nextPhycRecoverTime then
        --common:sendEmptyPacket( opcodes.SNOWFIELD_TREASURE_INFO_C, true )
        --TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.powerTimerName)
		return;
	end
    
    

	thisActivityInfo.nextPhycRecoverTime = math.max(remainTime, 0)
	local timeStr = GameMaths:formatSecondsToTime(thisActivityInfo.nextPhycRecoverTime)
	NodeHelper:setStringForLabel(container, { mRecoveryTime = timeStr } )
end

function SnowTreasurePageBase:onSearchTimer( container )
    local timerName = timerInfo.searchTimerName
	if not TimeCalculator:getInstance():hasKey(timerName) then return; end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName)

    if remainTime == 0 then
        common:sendEmptyPacket( opcodes.SNOWFIELD_TREASURE_INFO_C, true )
        TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
        return
    end

	if remainTime + 1 > thisActivityInfo.continueSearchLeftTime then
        --common:sendEmptyPacket( opcodes.SNOWFIELD_TREASURE_INFO_C, true )
        --TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
		return;
	end

    if remainTime == 0 then
        thisActivityInfo.continueSearchLeftTime = 0
        thisActivityInfo.mode = 1
        self:refreshView( container )

    end

	thisActivityInfo.continueSearchLeftTime = math.max(remainTime, 0)
	local timeStr = GameMaths:formatSecondsToTime(thisActivityInfo.continueSearchLeftTime)
	NodeHelper:setStringForLabel(container, { mTimeLimit = timeStr } )
end

function SnowTreasurePageBase:refreshItemView( container )
    for i = 1,COUNT_TREASURE_MAX,1 do
        container:getVarNode( "mSnowballNode" .. i ):setVisible( true )
        container:getVarMenuItemImage( "mSnowBallFrame" .. i):setNormalImage( CCSprite:create( NodeHelper:getImageByQuality( 1 ) ) )
        container:getVarSprite( "mHaveReceived" .. i ):setVisible( false )
        container:getVarLabelBMFont( "mSnowBallNum" .. i ):setString( "" )
        container:getVarSprite( "mSnowBallPic" .. i ):setVisible( false )
    end

    if thisActivityInfo.mode == 1 then return end

    for _,v in ipairs( thisActivityInfo.snowfieldCell ) do
        container:getVarNode( "mSnowballNode" .. v.index ):setVisible(false)
        local tab = Split( v.award , "_" )
        local reward = ResManagerForLua:getResInfoByTypeAndId( tonumber(tab[1]),tonumber(tab[2]),tonumber(tab[3]) )
        
        container:getVarMenuItemImage( "mSnowBallFrame" .. v.index):setNormalImage( CCSprite:create( NodeHelper:getImageByQuality( reward.quality ) ) )
        container:getVarSprite( "mHaveReceived" .. v.index ):setVisible( true )
        container:getVarLabelBMFont( "mSnowBallNum" ..v.index ):setString( reward.count )
        container:getVarSprite( "mSnowBallPic" .. v.index ):setVisible( true )
        container:getVarSprite( "mSnowBallPic" .. v.index ):setTexture( reward.icon )
    end
    
end

function SnowTreasurePageBase:onExecute( container )
    self:onActivityTimer( container )
    self:onPowerTimer( container )
    self:onSearchTimer( container )
end

function SnowTreasurePageBase:onExit( container )
    TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.activityTimerName)
    TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.powerTimerName)
    TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
	self:removePacket(container)
    container:removeMessage(MSG_MAINFRAME_REFRESH)
end

function SnowTreasurePageBase:onReceivePacket( container )
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == opcodes.SNOWFIELD_TREASURE_INFO_S then
        local msg = Activity_pb.HPSnowfieldTreasureInfoRet()
		msg:ParseFromString( msgBuff )
        self:receiveActivityInfo( container, msg )
    elseif opcode == opcodes.SNOWFIELD_SEARCH_S then
        local msg = Activity_pb.HPSnowfieldSearchRet()
        msg:ParseFromString( msgBuff )
        self:receiveSearchInfo(container, msg )
    elseif opcode == opcodes.SET_CONTINUE_SEARCH_MODE_S then
        local msg = Activity_pb.HPSetContinueSearchModeRet()
        msg:ParseFromString( msgBuff )
        self:receiveModeInfo(container, msg )
    elseif opcode == opcodes.SNOWFIELD_EXCHANGE_S then
--        local msg = Activity_pb.HPSnowfieldExchangeRet() 
--        msg:ParseFromString( msgBuff )
--        thisActivityInfo.isExchangedFinal = msg.isExchangedFinal
    end

end

function SnowTreasurePageBase:onReceiveMessage(container)
	local message = container:getMessage();
	local typeId = message:getTypeId();

	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
		if pageName == thisPageName then
			container:getVarLabelBMFont("mEnergyNum"):setString( thisActivityInfo.curPhyc .. "/" .. thisActivityInfo.maxPhyc )
			UserInfo.syncPlayerInfo()
            container:getVarLabelBMFont("mDiamondNUm"):setString(UserInfo.playerInfo.gold)
            if thisActivityInfo.nextPhycRecoverTime <= 0 then
                container:getVarLabelBMFont("mRecoveryTime"):setString( GameMaths:formatSecondsToTime(thisActivityInfo.nextPhycRecoverTime) )
                TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.powerTimerName)
            else
                TimeCalculator:getInstance():createTimeCalcultor(timerInfo.powerTimerName, thisActivityInfo.nextPhycRecoverTime)
            end
		    
        end
	end
end

function SnowTreasurePageBase:receiveModeInfo( container, msg )
    thisActivityInfo.mode = msg.mode
    thisActivityInfo.snowfieldCell = msg.snowfieldCell
    thisActivityInfo.nextSearchPhyc = msg.nextSearchCostPhyc
    if msg:HasField("continueSearchLeftTime") then
        thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
        if msg.continueSearchLeftTime <= 0 then
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
            TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
        else
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
        end
    end
    self:refreshView( container )
end

function SnowTreasurePageBase:receiveSearchInfo( container, msg )
    thisActivityInfo.nextSearchPhyc = msg.nextSearchCostPhyc
    if msg:HasField("continueSearchLeftTime") then
        if msg.continueSearchLeftTime <= 0 then
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
            TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
        else
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
        end
    end
    if msg:HasField("curStage") then
        thisActivityInfo.curStage = msg.curStage
    end
    if msg:HasField("mode") then
        thisActivityInfo.mode = msg.mode
    end
    for _,v in ipairs( thisActivityInfo.snowfieldCell ) do
        if v.index == msg.snowfieldCell.index then
            v = msg.snowfieldCell
            return
        end
    end

    table.insert( thisActivityInfo.snowfieldCell , msg.snowfieldCell )

    self:refreshView( container )

end

function SnowTreasurePageBase:receiveActivityInfo( container, msg )
    thisActivityInfo.activityLeftTime = msg.activityLeftTime
    thisActivityInfo.curPhyc = msg.curPhyc
    thisActivityInfo.maxPhyc = msg.maxPhyc
    thisActivityInfo.nextSearchPhyc = msg.nextSearchPhyc
    thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
    thisActivityInfo.nextPhycRecoverTime = msg.nextPhycRecoverTime
    thisActivityInfo.snowfieldCell = msg.snowfieldCell
    thisActivityInfo.mode = msg.mode
    
    if msg:HasField("continueSearchLeftTime") then
        if msg.continueSearchLeftTime <= 0 then
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
            TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.searchTimerName)
        else
            thisActivityInfo.continueSearchLeftTime = msg.continueSearchLeftTime
        end
        
    end

    thisActivityInfo.curStage = msg.curStage
    thisActivityInfo.totalStage = msg.totalStage
    thisActivityInfo.todayBuyPhycTimes = msg.todayBuyPhycTimes
    thisActivityInfo.nextBuyPhycGold = msg.nextBuyPhycGold
    thisActivityInfo.isExchangedFinal = msg.isExchangedFinal
    self:refreshView( container )
end

function SnowTreasurePageBase:onBack( container )
    PageManager.popPage(thisPageName)
end

function SnowTreasurePageBase:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_SNOWTREASURE)
end

function SnowTreasurePageBase:onBuyEnergy( container )
    local title = common:getLanguageString("@BuyEnergyTitle")
    local msg = common:getLanguageString("@BuyEnergyMsg" , thisActivityInfo.todayBuyPhycTimes , thisActivityInfo.nextBuyPhycGold )
    PageManager.showConfirm(title, msg, function(isSure)
			if isSure and UserInfo.isGoldEnough( thisActivityInfo.nextBuyPhycGold ) then
				common:sendEmptyPacket( opcodes.SNOWFIELD_BUY_PHYC_C )
			end
		end )
end

function SnowTreasurePageBase:onTreasure( container , eventName )
    local index = tonumber(eventName:sub(11,12))
    local msg = Activity_pb.HPSnowfieldSearch()
    msg.snowfieldCellIndex = index
    common:sendPacket( opcodes.SNOWFIELD_SEARCH_C , msg )
end

function SnowTreasurePageBase:onSearchSwitch( container )
    if thisActivityInfo.mode == 2 then
        local title = common:getLanguageString("@SearchSwitchTitle")
        local msg = common:getLanguageString("@SearchSwitchMsg" )
        PageManager.showConfirm(title, msg, function(isSure)
			if isSure then
				local msg = Activity_pb.HPSetContinueSearchMode()
                msg.type = thisActivityInfo.mode    
                common:sendPacket(opcodes.SET_CONTINUE_SEARCH_MODE_C , msg)
			end
		end )
    else
        local msg = Activity_pb.HPSetContinueSearchMode()
        msg.type = thisActivityInfo.mode    
        common:sendPacket(opcodes.SET_CONTINUE_SEARCH_MODE_C , msg)
    end
end

function SnowTreasurePageBase:onTreasureExchange( container )
    registerScriptPage("SnowTreasureExchange")
    SnowTreasureExchange_SetIsExchangedFinal( thisActivityInfo.isExchangedFinal )
    PageManager.pushPage( "SnowTreasureExchange" )
end

function SnowTreasurePageBase:onShowGift( container )
    local rewardId = ActivityConfig[thisActivityInfo.activityId].reward[thisActivityInfo.curStage]
    if rewardId ~= nil then
        local cfg = ConfigManager.getRewardById(rewardId)     
	    GameUtil:showTip(container:getVarNode('mPrize1'), cfg[1])
    end

end

function SnowTreasurePageBase:onShowItem( container ,eventName)
    local index = tonumber(eventName:sub(16,17))
	local itemInfo = {}
    for k,v in ipairs( thisActivityInfo.snowfieldCell ) do
        if index == v.index then
            itemInfo = v
        end
    end
	
	local rewardItems = {}
	if itemInfo.award ~= nil then
		for _, item in ipairs(common:split(itemInfo.award, ",")) do
			local _type, _id, _count = unpack(common:split(item, "_"));
			table.insert(rewardItems, {
				type 	= tonumber(_type),
				itemId	= tonumber(_id),
				count 	= tonumber(_count)
			});
		end
	end
	GameUtil:showTip(container:getVarNode('mSnowBallPrize' .. index), rewardItems[1])
end

function SnowTreasurePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function SnowTreasurePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function SnowTreasurePage_SetAddPhycInfo( msg )
    thisActivityInfo.curPhyc = msg.curPhyc
    thisActivityInfo.nextPhycRecoverTime = msg.nextPhycRecoverTime
    thisActivityInfo.todayBuyPhycTimes = msg.todayBuyPhycTimes
    thisActivityInfo.nextBuyPhycGold = msg.nextBuyPhycGold
end
-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
SnowTreasurePage = CommonPage.newSub(SnowTreasurePageBase, thisPageName, option)