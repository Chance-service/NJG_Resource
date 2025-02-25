----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "TreasureRaiderDiscountPage"
local UserMercenaryManager = require("UserMercenaryManager")
local RoleOpr_pb = require("RoleOpr_pb")
local MercenaryRoleInfos = {}
local ConfigManager = require("ConfigManager")
local alreadyShowReward = {}--界面上已经显示的奖励
local alreadyShowReward_multiple = {}--界面上已经显示的奖励
local activitiId = 36;
local _MercenaryInfo = ConfigManager.getNewLuckdrawMercenaryURCfg()[1]
local MercenaryCfg = nil
local COUNT_LIMIT = 10
local mConstCount = 0
local ReqAnim = 
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = {}
}

local opcodes = {
	NEW_UR_INFO_S = HP_pb.NEW_UR_INFO_S,
	NEW_UR_SEARCH_S = HP_pb.NEW_UR_SEARCH_S,
	ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
}

local option = {
	ccbiFile = "Act_TimeLimitNewGachaContent.ccbi",
	handlerMap ={
		onReturnButton 	= "onClose",
		onHelp 		= "onHelp",
		onSearchOnce		= "onOnceSearch",
		onSearchTen 		= "onTenSearch",
		onRewardPreview = "onRewardPreview",
		onIllustatedOpen = "onIllustatedOpen",
		onBoxPreview = "onBoxPreview",
	},
}
for i = 1,10 do
	option.handlerMap["onHand" ..i] = "onHand";
end

local TreasureRaiderBaseUR =  {}
TreasureRaiderBaseUR.timerName = "Activity_New_TreasureRaider"
TreasureRaiderBaseUR.timerLabel = "mTanabataCD"
TreasureRaiderBaseUR.timerKeyBuff = "Activity_Timer_Key_Buff"
TreasureRaiderBaseUR.timerFreeCD = "Activity_Timer_Free_CD"

local multiple_x2 = 2;
local multiple_x5 = 5;
local TreasureRaiderDataHelper = {
	RemainTime 			= 0,
	showItems			= {},
	freeTreasureTimes 	= 0,
	leftTreasureTimes 	= 0,
	onceCostGold 		= 0,
	tenCostGold 		= 0,
    TreasureRaiderConfig = ConfigManager.getTresureRaiderRewardURCfg() or {},
}
local bIsSearchBtn = false --点击按钮触发的动画,还是协议遇到宝箱触发的动画
local bIsMeetBox = false --是否遇到奇遇宝箱
local nSearchTimes = 1 --寻宝次数
-------------------------- logic method ------------------------------------------
function TreasureRaiderBaseUR:onTimer(container)
	if not TimeCalculator:getInstance():hasKey(self.timerName) then
	    if TreasureRaiderDataHelper.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(container, {[self.timerLabel] = endStr});
            NodeHelper:setNodesVisible(container, { mFreeText = false,
                                            mCostNodeVar = true,
                                            mSuitFreeTime = false,
                                            mNoBuf = false});
	    elseif TreasureRaiderDataHelper.RemainTime < 0 then
	        NodeHelper:setStringForLabel(container, {[self.timerLabel] = ""});
        end
        local endStr = common:getLanguageString("@ActivityEnd");
	    NodeHelper:setStringForLabel(container, {[self.timerLabel] = endStr});
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime + 1 > TreasureRaiderDataHelper.RemainTime then
		return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { [self.timerLabel] = timeStr});
    if remainTime <= 0 then
        common:sendEmptyPacket(HP_pb.GET_ACTIVITY_LIST_C, false)
	    timeStr = common:getLanguageString("@ActivityEnd");
        TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	    PageManager.popPage(thisPageName)
        NodeHelper:setStringForLabel(container, {[self.timerLabel] = timeStr});
    end

    if TimeCalculator:getInstance():hasKey(self.timerFreeCD) then
        local timerFreeCD = TimeCalculator:getInstance():getTimeLeft(self.timerFreeCD);
        if timerFreeCD > 0 then
            timeStr = common:second2DateString(timerFreeCD, false);
            NodeHelper:setStringForLabel(container, { mSuitFreeTime = timeStr});
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
            NodeHelper:setNodesVisible(container, { mFreeText = true,
                                                    mCostNodeVar = false,
                                                    mSuitFreeTime = false,
                                                })
        end
    end

    if TimeCalculator:getInstance():hasKey(self.timerKeyBuff) then
        local timerKeyBuff = TimeCalculator:getInstance():getTimeLeft(self.timerKeyBuff);
        if timerKeyBuff > 0 then
            timeStr = common:second2DateString(timerKeyBuff, false);
            NodeHelper:setStringForLabel(container, { mBuffCD = timeStr});
        else
            TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff);
            NodeHelper:setStringForLabel(container, { mBuffCD = ""});
            NodeHelper:setNodesVisible(container, { mNoBuff = false,mNoBuffTips = true})
        end
    end
end

-------------------------- state method -------------------------------------------
function TreasureRaiderBaseUR:getPageInfo( container )
	common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
	common:sendEmptyPacket(HP_pb.NEW_UR_INFO_C)
end

function TreasureRaiderBaseUR:onHand(container,eventName)
    local index = tonumber(string.sub(eventName,7,string.len(eventName)))
    local _type, _id, _count = unpack(common:split(alreadyShowReward[index], "_"));
    local items = {}
    table.insert(items, {
		type 	= tonumber(_type),
		itemId	= tonumber(_id),
		count 	= tonumber(_count)
	});
    GameUtil:showTip(container:getVarNode('mPic'..index), items[1])

end

function TreasureRaiderBaseUR:onEnter( parentContainer )
    _MercenaryInfo = ConfigManager.getNewLuckdrawMercenaryURCfg()[1]
    MercenaryCfg = ConfigManager.getRoleCfg()
	local container = ScriptContentBase:create(option.ccbiFile)
	self.container = container
	luaCreat_TreasureRaiderDiscountPage(container)	
	self:registerPacket(parentContainer)
	self:onShowDialog();
	self:getPageInfo(parentContainer)
    --TreasureRaiderDataHelper.TreasureRaiderConfig =  ConfigManager.getNewTresureRaiderRewardCfg()
	NodeHelper:setNodesVisible(container,{mDoubleNode = true})

	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode")) 	

	NodeHelper:setStringForLabel(container, {mCostTxt1 = common:getLanguageString("@TROneTime"), 
											 mCostTxt2 = common:getLanguageString("@TRTenTimes")})
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = {}
     }
	self:ClearALreadyShowReward()
	self:HideRewardNode(parentContainer)
    local spineNode = container:getVarNode("mSpine");

    local roldData = ConfigManager.getRoleCfg()[_MercenaryInfo.itemId]
    if spineNode and roldData then
        spineNode:removeAllChildren();
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        local spine = SpineContainer:create(spinePath, spineName)
        local spineToNode = tolua.cast(spine, "CCNode");
        spineToNode:setScale(0.9)
        spineNode:addChild(spineToNode);
        spine:runAnimation(1, "Stand", -1);
    end
    NodeHelper:setSpriteImage(container,{mNamePic = _MercenaryInfo.pic })
    NodeHelper:setNodesVisible(self.container, { mPercent1 = false, mPercent2 = false})

    
     for k, v in pairs(TreasureRaiderDataHelper.TreasureRaiderConfig) do
        if v.type == 1 then
            mConstCount = v.needRewardValue.count
            break
        end
    end

	return container
end

--是否弹出对话
function TreasureRaiderBaseUR:onShowDialog()
	local saveDialogStatus = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "TreasureRaiderBaseUR";
	local dialogStatus = CCUserDefault:sharedUserDefault():getStringForKey(saveDialogStatus);--保存当前的阶段，判断是否更新
	if not dialogStatus or dialogStatus == "" then--如果没有弹出过，则弹出对话
		require("ActivityDialogConfigPage");
	    ActivityDialogConfigBase_setAlreadySelItem(107);
		PageManager.pushPage("ActivityDialogConfigPage");
		CCUserDefault:sharedUserDefault():setStringForKey(saveDialogStatus, saveDialogStatus);
		CCUserDefault:sharedUserDefault():flush();
	end
end

function TreasureRaiderBaseUR:onIllustatedOpen(container)
	require("SuitDisplayPage")
	SuitDisplayPageBase_setMercenaryEquip(3)
    PageManager.pushPage("SuitDisplayPage");
end
function TreasureRaiderBaseUR:HideRewardNode(container)
    local visibleMap = {}
    for i = 1 ,10 do
        visibleMap["mRewardNode"..i] = false
    end
	
	local aniShadeVisible = false
	if #alreadyShowReward > 0 then
		for i = 1 , #alreadyShowReward do
			visibleMap["mRewardNode"..i] = true
			local reward = alreadyShowReward[i];
			local rewardItems = {}
			local _type, _id, _count = unpack(common:split(reward, "_"));
			table.insert(rewardItems, {
				type 	= tonumber(_type),
				itemId	= tonumber(_id),
				count 	= tonumber(_count),
				});
			NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = i ,frameNode = "mHand",countNode = "mNumber"})
		end
		aniShadeVisible = true
		-- container:runAnimation("ShowItem")
	end    
	NodeHelper:setNodesVisible(container, visibleMap)
end

function TreasureRaiderBaseUR:refreshRewardNode(container,index)
    local visibleMap = {}
    visibleMap["mRewardNode"..index] = true

    local reward = alreadyShowReward[index];
    local multiple = alreadyShowReward_multiple[index];
    local rewardItems = {}
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type 	= tonumber(_type),
        itemId	= tonumber(_id),
        count 	= tonumber(_count),
        });
    visibleMap["m2Time"..index] = multiple == multiple_x2
    visibleMap["m5Time"..index] = multiple == multiple_x5
    NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = index ,frameNode = "mHand",countNode = "mNumber"})
    NodeHelper:setNodesVisible(container, visibleMap )
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0"..Aniname
    end
    
    container:runAnimation("ItemAni_"..Aniname)
end

function TreasureRaiderBaseUR:ClearALreadyShowReward()
	alreadyShowReward = {}
    alreadyShowReward_multiple = {}
end

function TreasureRaiderBaseUR:refreshPage( container )
	if TreasureRaiderDataHelper.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TreasureRaiderDataHelper.RemainTime)
	end
    if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerFreeCD, TreasureRaiderDataHelper.freeTreasureTimes)
	end
    if TreasureRaiderDataHelper.leftBuffTimes > 0 then
        
        NodeHelper:setNodesVisible(container, { 
                                                mTimes2 = TreasureRaiderDataHelper.buf_multiple == multiple_x2,
                                                mTimes5 = TreasureRaiderDataHelper.buf_multiple == multiple_x5,})
        TimeCalculator:getInstance():createTimeCalcultor(self.timerKeyBuff, TreasureRaiderDataHelper.leftBuffTimes)
    else
        
    end
	--local freeTimesStr = common:getLanguageString("@TreasureRaiderFreeOneTime", TreasureRaiderDataHelper.freeTreasureTimes)
	UserInfo.syncPlayerInfo()
	local label2Str = {
		mCostNum 	= TreasureRaiderDataHelper.onceCostGold,
		mDiamondText 	= TreasureRaiderDataHelper.tenCostGold,
		--mSuitFreeTime 			= freeTimesStr,
		mDiamondNum 		= UserInfo.playerInfo.gold,
        mActDouble = common:getLanguageString("@NeedXTimesGet",TreasureRaiderDataHelper.leftAwardTimes,MercenaryCfg[_MercenaryInfo.itemId].name , mConstCount)
	}
	NodeHelper:setStringForLabel(container,label2Str)
	
	
	NodeHelper:setLabelOneByOne(container, "mSearchTimesTitle", "mSearchTimes")
	NodeHelper:setLabelOneByOne(container, "mFreeNumTitle", "mFreeNum")
	
	NodeHelper:setNodesVisible(container, { mFreeText = TreasureRaiderDataHelper.freeTreasureTimes <= 0,
                                            mCostNodeVar = TreasureRaiderDataHelper.freeTreasureTimes > 0,
                                            mSuitFreeTime = TreasureRaiderDataHelper.freeTreasureTimes > 0,
                                            mNoBuff = TreasureRaiderDataHelper.leftBuffTimes > 0,
                                            mNoBuffTips = TreasureRaiderDataHelper.leftBuffTimes <= 0
                                            })
end

function TreasureRaiderBaseUR:onExecute( parentContainer )
	self:onTimer(self.container)
end

--更新佣兵碎片数量
function TreasureRaiderBaseUR:updateMercenaryNumber()
	for i = 1,#MercenaryRoleInfos do
        --local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
		if _MercenaryInfo.itemId == MercenaryRoleInfos[i].itemId then
			NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@RoleFragmentNumberTxt",MercenaryCfg[_MercenaryInfo.itemId].name) .. MercenaryRoleInfos[i].soulCount.."/"..MercenaryRoleInfos[i].costSoulCount});
			break;
		end
	end
end

--收包
function TreasureRaiderBaseUR:onReceivePacket(parentContainer)
    local opcode = parentContainer:getRecPacketOpcode()
	local msgBuff = parentContainer:getRecPacketBuffer()
	if opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber();
    end
	if opcode ~= HP_pb.NEW_UR_INFO_S and opcode ~= HP_pb.NEW_UR_SEARCH_S then
		return
	end
	local msg = Activity3_pb.SyncNewURInfo()
	msg:ParseFromString(msgBuff)
	
	TreasureRaiderDataHelper.RemainTime 		= msg.leftTime or 0
	TreasureRaiderDataHelper.showItems 			= msg.items or {}
	TreasureRaiderDataHelper.freeTreasureTimes 	= msg.freeCD or 0
	TreasureRaiderDataHelper.onceCostGold 		= msg.onceCostGold or 0
	TreasureRaiderDataHelper.tenCostGold 		= msg.tenCostGold or 0

    TreasureRaiderDataHelper.buf_multiple 		= msg.buf_multiple or 1
    TreasureRaiderDataHelper.leftBuffTimes 		= msg.leftBuffTimes or 0
    TreasureRaiderDataHelper.leftAwardTimes     = msg.leftAwardTimes or 10
	dump(TreasureRaiderDataHelper)
	if opcode == HP_pb.NEW_UR_INFO_S then
		--同步
		if TreasureRaiderDataHelper.showItems~=nil and TreasureRaiderDataHelper.showItems~="" then
			--bIsMeetBox = true
			--container:runAnimation("OpenChest")
		end
	elseif opcode == HP_pb.NEW_UR_SEARCH_S then
		common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
		-- 有奇遇宝箱播放动画，弹出窗口
		if TreasureRaiderDataHelper.showItems~=nil and TreasureRaiderDataHelper.showItems~="" then
			bIsMeetBox = true
		end
		ReqAnim.showNewReward = {}
        ReqAnim.showNewReward = msg.reward
		local reward = msg.reward
        local beginIndex = 1;
        if (#alreadyShowReward + #reward) > COUNT_LIMIT then
            self:HideRewardNode(self.container);
			self:ClearALreadyShowReward()
        else
            beginIndex = #alreadyShowReward + 1;
        end
        for i = 1,#reward do
            alreadyShowReward[#alreadyShowReward+1] = reward[i]
            alreadyShowReward_multiple[#alreadyShowReward_multiple+1] = msg.reward_multiple[i]
        end
        NodeHelper:setNodesVisible(self.container, { mRewardBtn = false, mIllustatedOpen =false})
        NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
        ReqAnim.isAnimationRuning = true
		self:refreshRewardNode(self.container,beginIndex);  		
	end
	if TreasureRaiderDataHelper.freeTreasureTimes > 0 then
		ActivityInfo.changeActivityNotice(107)
	end
	self:refreshPage(self.container)
end

function TreasureRaiderBaseUR:onExit( parentContainer )
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerKeyBuff);
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerFreeCD);
    local spineNode = self.container:getVarNode("mSpine");
    if spineNode then
        spineNode:removeAllChildren();
    end  
    MercenaryCfg = nil
    self:removePacket(parentContainer)
    onUnload(thisPageName, self.container)
end

function TreasureRaiderBaseUR:onAnimationDone( container )
	local animationName=tostring(container:getCurAnimationDoneName())
	if string.sub(animationName,1,8)=="ItemAni_" then
        local index = tonumber(string.sub(animationName,-2))
		if index < #alreadyShowReward then
            self:refreshRewardNode(container,index+1)
        else
            --播放完毕
	        NodeHelper:setNodesVisible(self.container, { mRewardBtn = true, mIllustatedOpen = true})
	        NodeHelper:setMenuItemEnabled( self.container, "mDiamond", true);
	        NodeHelper:setMenuItemEnabled( self.container, "mFree", true);
            --
            ReqAnim.isAnimationRuning = false;
            if bIsMeetBox then
            	bIsMeetBox = false
	            local rewardItems = common:parseItemWithComma(TreasureRaiderDataHelper.showItems)       	
				if rewardItems and #rewardItems > 0 then
					local CommonRewardPage = require("CommonRewardPage")
					CommonRewardPageBase_setPageParm(rewardItems, true, 2)
					PageManager.pushPage("CommonRewardPage")
				end
            end
        end
	end
end
----------------------------click client -------------------------------------------
function TreasureRaiderBaseUR:onOnceSearch( container )
	UserInfo.syncPlayerInfo()
	-- 当前拥有钻石小于消耗钻石
	if TreasureRaiderDataHelper.freeTreasureTimes > 0 and
	UserInfo.playerInfo.gold < TreasureRaiderDataHelper.onceCostGold then
		common:rechargePageFlag("TreasureRaiderBaseUR")
		return
	end
	local msg = Activity3_pb.NewURSearch()
	msg.searchTimes = 1
	common:sendPacket(HP_pb.NEW_UR_SEARCH_C, msg)	
end

function TreasureRaiderBaseUR:onTenSearch( container )
	UserInfo.syncPlayerInfo()
	-- 当前拥有钻石小于消耗钻石
	local needGold = TreasureRaiderDataHelper.tenCostGold
	if needGold <=0 then needGold=0 end
	if UserInfo.playerInfo.gold < needGold then
		common:rechargePageFlag("TreasureRaiderBaseUR")
		return
	end
	local msg = Activity3_pb.NewURSearch()
	msg.searchTimes = 10
	common:sendPacket(HP_pb.NEW_UR_SEARCH_C, msg)	
end

function TreasureRaiderBaseUR:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function TreasureRaiderBaseUR:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

function TreasureRaiderBaseUR:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_NEW_TREASURERAIDER);
end

function TreasureRaiderBaseUR:onRewardPreview( container )
	require("NewSnowPreviewRewardPage")
    local TreasureCfg = TreasureRaiderDataHelper.TreasureRaiderConfig
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
	NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems, "@ACTTLNewTreasureRaiderInfoTxt1", "@ACTTLNewTreasureRaiderInfoTxt2")
	PageManager.pushPage("NewSnowPreviewRewardPage")
end

function TreasureRaiderBaseUR:onBoxPreview( container )
	require("NewSnowPreviewRewardPage")
    local TreasureCfg = TreasureRaiderDataHelper.TreasureRaiderConfig
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
	NewSnowPreviewRewardPage_SetConfig(commonRewardItems, luckyRewardItems)
	PageManager.pushPage("NewSnowPreviewRewardPage")
end

local CommonPage = require('CommonPage')
TreasureRaiderDiscountPage= CommonPage.newSub(TreasureRaiderBaseUR, thisPageName, option)

return TreasureRaiderDiscountPage