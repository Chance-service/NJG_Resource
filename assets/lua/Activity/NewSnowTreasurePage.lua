
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local ResManagerForLua = require("ResManagerForLua")
local NewSnowInfoData = require("Activity.NewSnowInfoData")

local thisPageName = "NewSnowTreasurePage"
local thisCcbiTable = {}
local isOpenaAniRuning = false
local opcodes = {
    PRINCE_DEVILS_PANEL_C = HP_pb.PRINCE_DEVILS_PANEL_C,
    PRINCE_DEVILS_PANEL_S = HP_pb.PRINCE_DEVILS_PANEL_S,

    PRINCE_DEVILS_OPEN_C = HP_pb.PRINCE_DEVILS_OPEN_C,
    PRINCE_DEVILS_OPEN_S = HP_pb.PRINCE_DEVILS_OPEN_S,
}

local activityId = 91

local option = {
	ccbiFile = "Act_TimeLimitLoadTreasureContent.ccbi",
	handlerMap = {
		onReturnButton		= "onBack",
		onHelp				= "onHelp",
        onPreviewReward     = "onPreviewReward",
        onRanking     = "onRanking",
        onHelp              = "onHelp",
        onClose             = "onClose"
	},
	opcode = opcodes
}

for i = 1, NewSnowInfoData.COUNT_TREASURE_MAX do
	option.handlerMap[string.format("onSnowball%d", i)] = "onTreasure"
    option.handlerMap[string.format("onSnowBallFrame%d", i)] = "onShowItem"
end

for i = 1, 4 do
    option.handlerMap[string.format("onRewardFrame%d", i)] = "onRewardFrame"
end


local timerInfo = {
    activityTimerName = "NewSnowTreasureActivity",
    freeTimesCDName = "freeTimesCDName"
}
local SnowBallItem = {
    ccbiFile = "A_LoadBall.ccbi"
}

local NewSnowTreasurePageBase = {}

-------------------------------------------------------------------------
function NewSnowTreasurePageBase:onEnter( ParentContainer )
    isOpenaAniRuning = false
    local container = ScriptContentBase:create(option.ccbiFile)
    self.container = container
    luaCreat_NewSnowTreasurePage(container)
    self:registerPacket( ParentContainer )
    local mScale9Sprite1 = container:getVarScale9Sprite("mScale9Sprite1")
    if mScale9Sprite1 ~= nil then
        ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite1 )
    end
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    local bg = container:getVarSprite("mBGPic")
    bg:setScaleY((mScale9Sprite1:getContentSize().height - 67)/532)
    self:showSpineInfo(container);
    common:sendEmptyPacket( opcodes.PRINCE_DEVILS_PANEL_C, true )
    return container
end
function NewSnowTreasurePageBase:showSpineInfo(container)
    local AniNode = container:getVarNode("mLoadAni");
    if AniNode then
	    AniNode:removeAllChildren();
	    local spine = SpineContainer:create("Spine/baozang","baozang");
	    local spineNode = tolua.cast(spine, "CCNode");
	    AniNode:addChild(spineNode);
	    spine:runAnimation(1, "animation", -1);
    end
end
function NewSnowTreasurePageBase:refreshView( container )
    UserInfo.syncPlayerInfo()
    if NewSnowInfoData.activityLeftTime > 0 and not TimeCalculator:getInstance():hasKey(timerInfo.activityTimerName) then
		TimeCalculator:getInstance():createTimeCalcultor(timerInfo.activityTimerName, NewSnowInfoData.activityLeftTime)
    elseif NewSnowInfoData.activityLeftTime <= 0 then
        NodeHelper:setStringForLabel(container, { mLoginDaysNum = common:getLanguageString("@ActivityEnd")})
	end
    local lb2Str = {
        mDiamondNUm     = UserInfo.playerInfo.gold,
        mCredits        = NewSnowInfoData.score,
        mTenTimesNeedGold = NewSnowInfoData.consumeGold
    }
    if NewSnowInfoData.freeTime > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(timerInfo.freeTimesCDName, NewSnowInfoData.freeTime);
        container:getVarNode( "mFreeNode"):setVisible(true);
    else
        lb2Str["mTenTimesNeedGold"] = common:getLanguageString("@curFree");
        container:getVarNode( "mFreeNode"):setVisible(false);
    end
    
    NodeHelper:setStringForLabel( container, lb2Str )
    self:refreshItemView( container )
end

function NewSnowTreasurePageBase:onActivityTimer( container )
    local timerName = timerInfo.activityTimerName
    if TimeCalculator:getInstance():hasKey(timerName) then
        local remainTime = TimeCalculator:getInstance():getTimeLeft(timerName);
        if remainTime + 1 > NewSnowInfoData.activityLeftTime then
	        return;
        end
        print("remainTime = ",remainTime)
        NewSnowInfoData.activityLeftTime = math.max(remainTime, 0)
        local timeStr = common:second2DateString(NewSnowInfoData.activityLeftTime, false)
        NodeHelper:setStringForLabel(container, { mLoginDaysNum = timeStr } )
    end
    local timeStr = '00:00:00'
    if TimeCalculator:getInstance():hasKey(timerInfo.freeTimesCDName) then
		local freeTimesCD = TimeCalculator:getInstance():getTimeLeft(timerInfo.freeTimesCDName)
		if freeTimesCD > 0 then
			 timeStr = GameMaths:formatSecondsToTime(freeTimesCD)
		end
        if freeTimesCD <= 0 then
            --免费
            TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.freeTimesCDName)
            container:getVarNode( "mFreeNode"):setVisible(false);
            NodeHelper:setStringForLabel(container, { mTenTimesNeedGold = common:getLanguageString('@curFree')})
        else
            container:getVarNode( "mFreeNode"):setVisible(true);
            NodeHelper:setStringForLabel(container, { mFreeTimes = common:getLanguageString('@SuitFreeOneTime',timeStr)})
	    end
	end
end

function NewSnowTreasurePageBase:refreshItemView( container )
    if #thisCcbiTable == 0 then
       
    end
    
    for i = 1,NewSnowInfoData.COUNT_TREASURE_MAX,1 do
        self:setSnowCcbi(container,i);
    end
    for _,v in ipairs( NewSnowInfoData.devilsIndexInfo ) do
        local mSnowNode = container:getVarNode("mSnowNode"..v.index);
        if mSnowNode then
            mSnowNode:setVisible(false);
        end
        container:getVarNode("mSnowballNode"..v.index):setVisible(false)
        container:getVarNode("mSnowBallPrize"..v.index):setVisible(true)
        local tab = Split( v.award , "_" )
        local reward = ResManagerForLua:getResInfoByTypeAndId( tonumber(tab[1]),tonumber(tab[2]),tonumber(tab[3]) )
        
        container:getVarMenuItemImage( "mSnowBallFrame" .. v.index):setVisible(true)
        container:getVarMenuItemImage( "mSnowBallFrame" .. v.index):setNormalImage( CCSprite:create( NodeHelper:getImageByQuality( reward.quality ) ) )

        container:getVarLabelBMFont( "mSnowBallNum" ..v.index ):setString( reward.count )
        container:getVarSprite( "mSnowBallPic" .. v.index ):setVisible( true )
        container:getVarSprite( "mSnowBallPic" .. v.index ):setTexture( reward.icon )
        container:getVarSprite( "mSnowBallPic" .. v.index ):setScale(reward.iconScale)
    end
    
end
function SnowBallItem:onWealthyClub(container)
    local animationName=tostring(container:getCurAnimationDoneName())
    if animationName == "TouchEnd" then
        isOpenaAniRuning = false
        NewSnowTreasurePageBase.sendOpenPacket(tonumber(container:getTag()));
    end
end
function NewSnowTreasurePageBase:setSnowCcbi(container,index)
    if container == nil then return end;
    local mSnowballNode = container:getVarNode("mSnowballNode"..index);
    local mSnowNode = container:getVarNode("mSnowNode"..index);
    if  thisCcbiTable[index] == nil then
        container:getVarNode("mSnowBallPrize"..index):setVisible(false)
	    local ccbi = ScriptContentBase:create(SnowBallItem.ccbiFile);
	    ccbi:registerFunctionHandler(SnowBallItem.onWealthyClub);
        ccbi:runAnimation("Normal");
        table.insert(thisCcbiTable, ccbi);
        ccbi:setTag(#thisCcbiTable)
        if mSnowNode then
            mSnowNode:setVisible(true);
        end
        if mSnowballNode then
            mSnowballNode:removeAllChildren();
            mSnowballNode:setVisible(true)
            mSnowballNode:addChild(ccbi,1);
        end
        ccbi:release()
    else
         if mSnowNode then
            mSnowNode:setVisible(true);
            mSnowballNode:setVisible(true)
        end
    end
end

function NewSnowTreasurePageBase:onExecute( ParentContainer )
    self:onActivityTimer( self.container )
end

function NewSnowTreasurePageBase:onExit( ParentContainer )
    thisCcbiTable = {}
    TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.activityTimerName)
    TimeCalculator:getInstance():removeTimeCalcultor(timerInfo.freeTimesCDName)
	self:removePacket(ParentContainer)
    onUnload(thisPageName, self.container)
end

function NewSnowTreasurePageBase:onReceivePacket( ParentContainer )
    local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()

    if opcode == opcodes.PRINCE_DEVILS_PANEL_S or opcode == opcodes.PRINCE_DEVILS_OPEN_S then
        local msg = Activity2_pb.HPPrinceDevilsPanelInfoRes()
		msg:ParseFromString( msgBuff )
        if msg.activityLeftTime == 0 then
            ActivityConfig[activityId].bannerShowTime = 3
            ActivityConfig[activityId].order = 9999
            NewSnowInfoData.activityLeftTime = msg.activityLeftTime
            PageManager.pushPage("NewSnowScoreExchangePage");
            --return;
        end
        self:receiveActivityInfo( self.container, msg )
    elseif opcode == opcodes.NEW_SNOWFIELD_RANK_S then

    end
end

function NewSnowTreasurePageBase:onReceiveMessage(ParentContainer)
	local message = ParentContainer:getMessage();
	local typeId = message:getTypeId();

	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName;
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
		if pageName == thisPageName then
            self.container:getVarLabelBMFont("mCredits"):setString(extraParam)
        end
	end
end
function NewSnowTreasurePageBase:receiveActivityInfo( container, msg )
    NewSnowInfoData.activityLeftTime = msg.activityLeftTime;
    NewSnowInfoData.freeTime = msg.freeTime;
    NewSnowInfoData.score = msg.score;
    NewSnowInfoData.devilsIndexInfo = msg.devilsIndexInfo;
    NewSnowInfoData.luck = msg.luck;
    NewSnowInfoData.consumeGold = msg.consumeGold
    if NewSnowInfoData.luck and msg.luckAward ~= "" then
        NewSnowInfoData.luckAward = common:parseItemWithComma(msg.luckAward)
    end
    local snowfieldCellSize = #NewSnowInfoData.devilsIndexInfo
    local scal = NewSnowInfoData.OpacityValue[snowfieldCellSize+1]
    local mSnowState = container:getVarSprite("mSnowState");
    if mSnowState then
        mSnowState:setOpacity(scal);
    end
    if NewSnowInfoData.luck then
        NewSnowTreasurePageBase:refreshLuckRewarShowBox(container)
        -- container:runAnimation("Open");
        thisCcbiTable = {}
    end
    if NewSnowInfoData.freeTime > 0 then
        ActivityInfo.changeActivityNotice(Const_pb.PRINCE_DEVILS);
    end
    self:refreshView( container );
end

function NewSnowTreasurePageBase:refreshLuckRewarShowBox( container )
    local rewardParams = {
        mainNode = "mRewardNode",
        frameNode = "mMaterialFrame",
        countNode = "mReward",
        nameNode = "mRewardName",
        picNode = "mRewardPic"
    }
    local size = #NewSnowInfoData.luckAward
    NodeHelper:fillRewardItemWithParams(container,NewSnowInfoData.luckAward,4,rewardParams)
    
end

function NewSnowTreasurePageBase:onBack( container )
    PageManager.refreshPage("ActivityPage")
    PageManager.popPage(thisPageName)
end

function NewSnowTreasurePageBase:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_NEWSNOWTREASURE)
end
function NewSnowTreasurePageBase.sendOpenPacket(index)
    local msg = Activity2_pb.HPPrinceDevilsSearchReq()
    msg.devilsIndex = index
    CCLuaLog("=======================================sendOpenPacket:"..index)
    common:sendPacket( opcodes.PRINCE_DEVILS_OPEN_C , msg )
end
function NewSnowTreasurePageBase:onTreasure( container , eventName )
     if NewSnowInfoData.activityLeftTime <= 0 then
        MessageBoxPage:Msg_Box_Lan("@ActivityEnd")
        return 
	end
    if NewSnowInfoData.freeTime ~= 0 then
        local isGoldEnough = UserInfo.isGoldEnough(NewSnowInfoData.consumeGold)
        if not isGoldEnough then
            return;
        end
	end
     if not isOpenaAniRuning then
        local index = tonumber(eventName:sub(11,12))
        local ccbi = thisCcbiTable[index]
        if ccbi then
            ccbi:runAnimation("TouchEnd");
            isOpenaAniRuning = true
        end
    end
end

function NewSnowTreasurePageBase:onRewardFrame( container , eventName )
    local index = tonumber(string.sub(eventName,14,-1))
    local luckAward = NewSnowInfoData.luckAward
    local size = #luckAward
	if luckAward == nil or size <= 0 then return end

	local item = luckAward[index]
    if item~=nil then
		GameUtil:showTip(container:getVarNode('mMaterialFrame' .. index), item)
    end
end

function NewSnowTreasurePageBase:onShowItem( container ,eventName)
    local index = tonumber(eventName:sub(16,17))
	local itemInfo = {}
    for k,v in ipairs( NewSnowInfoData.devilsIndexInfo ) do
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
	GameUtil:showTip(container:getVarNode('mSnowBallFrame' .. index), rewardItems[1])
end

function NewSnowTreasurePageBase:onClose( container )
    common:popRewardString(NewSnowInfoData.luckAward)
	container:runAnimation("Default Timeline");
end

function NewSnowTreasurePageBase:onPreviewReward( container )
    require("NewSnowPreviewRewardPage")
    local TreasureCfg = NewSnowInfoData.newSnowTreasureCfg
    local commonRewardItems = {}
    local luckyRewardItems = {}
    if TreasureCfg ~= nil then
        for _, item in ipairs(TreasureCfg) do
            if item.type == 1 then
                table.insert(commonRewardItems, {
                    type    = tonumber(item.needRewardValue.type),
                    itemId  = tonumber(item.needRewardValue.itemId),
                    count   = tonumber(item.needRewardValue.count)
                });
            else
                table.insert(luckyRewardItems, {
                    type    = tonumber(item.needRewardValue.type),
                    itemId  = tonumber(item.needRewardValue.itemId),
                    count   = tonumber(item.needRewardValue.count)
                });
            end
        end
    end

    NewSnowPreviewRewardPage_SetConfig(commonRewardItems ,luckyRewardItems,"@LuckyRewardText", "@CommonPrizeText")
    PageManager.pushPage("NewSnowPreviewRewardPage");	
end

function NewSnowTreasurePageBase:onRanking( container )
    PageManager.pushPage("NewSnowScoreExchangePage");	
end

function NewSnowTreasurePageBase:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function NewSnowTreasurePageBase:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage")
NewSnowTreasurePage = CommonPage.newSub(NewSnowTreasurePageBase, thisPageName, option)
return NewSnowTreasurePage