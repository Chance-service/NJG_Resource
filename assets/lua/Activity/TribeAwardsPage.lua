
local NodeHelper = require("NodeHelper")
local ActivityBasePage = require("Activity.ActivityBasePage")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local TribeAwardsDataManager = require("Activity.TribeAwardsDataManager")
local copyRewardInfo = {}
local thisPageName = "TribeAwardsPage"
local opcodes = {
	
}

local option = {
	ccbiFile = "Act_TribeAwardsPopUp.ccbi",
	handlerMap ={
		onReturnButton 	= "onClose",
		onHelp 		    = "onHelp",
        onLucky         = "onLucky",
        onLeftBtn       = "onLeft",
        onRightBtn      = "onRight"
	},
}

local  activitiId = 37
--活动基本信息

local ITEM_PER_LINE= 3
local mScrollView         ={}		
local mContainer          ={}
local getReward           = 0  --是否有奖励
local isLevelComplete     = 0  --是否获得全部级别奖励
local TribeAwardsPage={}
TribeAwardsPage.timerName = "Activity_TribeAward";
local RewardItem = {
	ccbiFile = "Act_TribeAwardsContent.ccbi",
}
function RewardItem.onFunction(eventName, container)
    if eventName == "luaRefreshItemView" then
		RewardItem.onRefreshItemView(container);
    elseif eventName:sub(1,13) == "onRewardFrame" then
        RewardItem.showItemInfo(container,eventName)
    end
end
function RewardItem.showItemInfo(container, eventName)
	local index = container:getItemDate().mID
    local itemInfo = copyRewardInfo[index]	
	local rewardIndex = tonumber(eventName:sub(14))
    local rewardItems = {}
    rewardItems = RewardItem:getItemList(container,itemInfo)
	GameUtil:showTip(container:getVarNode('mMaterialFrame' .. tonumber(eventName:sub(14))), rewardItems[rewardIndex])
end

function RewardItem.onRefreshItemView(container)
	local index = container:getItemDate().mID;
    local itemInfo = copyRewardInfo[index]	
    local rewardShowTable = {}
    rewardShowTable = RewardItem:getItemList(container,itemInfo)
    RewardItem:fillRewardItem(container, rewardShowTable)
end

function RewardItem:getItemList(container,itemInfo)
    local rewardList ={}
    if itemInfo.award~=nil then
        for _, item in ipairs(itemInfo.award) do
	        table.insert(rewardList, {
		        type 	= tonumber(item.type),
				itemId	= tonumber(item.itemId),
				count 	= tonumber(item.count)
			});
         end            
    end
    return rewardList
end
function RewardItem:fillRewardItem(container, rewardCfg)	
	local nodesVisible = {};
	local lb2Str = {};
	local sprite2Img = {};
	local menu2Quality = {};
	
	for i = 1, ITEM_PER_LINE do
		local cfg = rewardCfg[i];
		nodesVisible["mRewardNode"..i] = cfg ~= nil;
		
		if cfg ~= nil then
			local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
			if resInfo ~= nil then
				sprite2Img["mRewardPic" .. i] 		= resInfo.icon;
				lb2Str["mReward" .. i]				= "x" .. cfg.count;
            --    lb2Str["mRewardName" .. i]				= resInfo.name;
                menu2Quality["mMaterialFrame" .. i]		= resInfo.quality;
			else
				CCLuaLog("Error::***reward item not found!!");
			end
		end
	end
	
	NodeHelper:setNodesVisible(container, nodesVisible);
	NodeHelper:setStringForLabel(container, lb2Str);
	NodeHelper:setSpriteImage(container, sprite2Img);
	NodeHelper:setQualityFrames(container, menu2Quality);

end

function TribeAwardsPage:onTimer(container)
    if not TimeCalculator:getInstance():hasKey(self.timerName) then
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime + 1 > TribeAwardsDataManager.remainTime then
		return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { mActivityDaysNum = timeStr});

    if remainTime <= 0 then
	    timeStr = common:getLanguageString("@ActivityEnd");
	    PageManager.popPage(thisPageName)
    end
end

function TribeAwardsPage:refreshPage(container)
    self:setVisible(container,1)
    if TribeAwardsDataManager.remainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TribeAwardsDataManager.remainTime);
	end

     --进度条
    local luckyPercent = 0
    local luckyBar = container:getVarScale9Sprite("mLuckyValue")
    if TribeAwardsDataManager.currentIndex == TribeAwardsDataManager.currentState then
        TribeAwardsDataManager.currentLuckyValue = TribeAwardsDataManager.trueLuckyValue 
    else 
        TribeAwardsDataManager.currentLuckyValue = 0
    end
    luckyPercent = TribeAwardsDataManager.currentLuckyValue/TribeAwardsDataManager.maxLuckyValue[TribeAwardsDataManager.currentIndex]
	if luckyBar~=nil and luckyPercent>=0 then
		luckyBar:setScaleX(math.min(luckyPercent, 1.0))
	end	
    
     --左右箭头  拼手气按钮
    if  TribeAwardsDataManager.currentIndex ~= 1 and TribeAwardsDataManager.currentIndex ~= TribeAwardsDataManager.totalSize then
        NodeHelper:setNodesVisible(container,{mLeftNode = true})
        NodeHelper:setNodesVisible(container,{mRightNode = true})
		NodeHelper:setMenuItemEnabled(container,"mLeftBtn",true)
		NodeHelper:setMenuItemEnabled(container,"mRightBtn",true)
    elseif TribeAwardsDataManager.currentIndex== 1 then
        NodeHelper:setNodesVisible(container,{mLeftNode = false})
        NodeHelper:setNodesVisible(container,{mRightNode = true})
		NodeHelper:setMenuItemEnabled(container,"mRightBtn",true)
	elseif TribeAwardsDataManager.currentIndex == TribeAwardsDataManager.totalSize then
        NodeHelper:setNodesVisible(container,{mRightNode = false})
        NodeHelper:setMenuItemEnabled(container,"mLuckyNode",false)
        NodeHelper:setNodesVisible(container,{mLeftNode = true})
		NodeHelper:setMenuItemEnabled(container,"mLeftBtn",true)
    end

	local incentiveStr = common:getLanguageString("@TribeAwardsDrawIncentive",TribeAwardsDataManager.currentIndex)  --抽奖奖励
    local surplusStr = common:getLanguageString("@TribeAwardsSurplusNumber",TribeAwardsDataManager.leftTimes) --剩余次数
    local consumeStr = common:getLanguageString("@TribeAwardsCumulativeConsumption",TribeAwardsDataManager.totalConsume) --累计消耗
    local luckyValueStr= common:getLanguageString("@TribeAwardsLuckyValue",TribeAwardsDataManager.currentLuckyValue,TribeAwardsDataManager.maxLuckyValue[TribeAwardsDataManager.currentIndex]) --幸运值
    local consumeScoreStr= common:getLanguageString("@ConsumeScore",TribeAwardsDataManager.consumeScore[TribeAwardsDataManager.currentIndex]) 
	UserInfo.syncPlayerInfo()
	local label2Str = {
		mLuckyValueNum 	= luckyValueStr,
		mSurplusNum 	= surplusStr,
		mCumulativeNum 			= consumeStr,
		mDrawIncentive 		= incentiveStr,
        mIntegralConsumeNum   = consumeScoreStr
	}
	NodeHelper:setStringForLabel(container,label2Str)
	NodeHelper:setLabelOneByOne(container, "mSurplusTitle", "mSurplusNum", 5)
	NodeHelper:setLabelOneByOne(container, "mCumulativeTitle", "mCumulativeNum", 5)
    NodeHelper:setLabelOneByOne(container, "mDrawIncentiveTitle", "mDrawIncentive", 0)
    --如果有奖励 弹出奖励界面
    if getReward ==1 then
        --PageManager.pushPage("TribeAwardsRewardPage")
        getReward =0
    end
    --预览界面按钮置灰 
    if isLevelComplete == 1 or TribeAwardsDataManager.currentIndex ~= TribeAwardsDataManager.currentState then
        NodeHelper:setMenuItemEnabled(container,"mLuckyNode",false)
    else
        NodeHelper:setMenuItemEnabled(container,"mLuckyNode",true)
    end
 
     --取消红点
   if TribeAwardsDataManager.leftTimes<=0 then
	    ActivityInfo:decreaseReward(activitiId)
    end
end

function TribeAwardsPage:onExecute( container )
	self:onTimer(container)
end

function TribeAwardsPage:onExit(container)
    NodeHelper:deleteScrollView(container)
    TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
    isLevelComplete = 0
    self:removePacket(container)
    copyRewardInfo = {}
end

function TribeAwardsPage:rebuildItem(container)
    self:clearAllItem(container)
    self:buildItem(container)
end
function TribeAwardsPage:clearAllItem(container)
    NodeHelper:clearScrollView(container)
end
function TribeAwardsPage:buildItem(container)
	TribeAwardsDataManager.totalSize = math.ceil(#copyRewardInfo);
	NodeHelper:buildScrollViewHorizontal(container, TribeAwardsDataManager.totalSize, RewardItem.ccbiFile, RewardItem.onFunction,0);
end

function TribeAwardsPage:initScrollView(container)
    NodeHelper:initScrollView(container, "mContent", 4);
    mScrollView = container.mScrollView
    mScrollView:setTouchEnabled(false)
    mScrollView:setBounceable(false)
    mContainer = container
    TribeAwardsDataManager.fScrollViewWidth = mScrollView:getViewSize().width 
end

function TribeAwardsPage:setVisible(container,index)
    if index == 1 then
        NodeHelper:setNodesVisible(container,{mActivityDaysNum = true})
        NodeHelper:setNodesVisible(container,{mLuckyNode = true})
        NodeHelper:setNodesVisible(container,{mLuckyValue = true})
    else 
        NodeHelper:setNodesVisible(container,{mActivityDaysNum = false})     
        NodeHelper:setNodesVisible(container,{mLeftNode = false})
        NodeHelper:setNodesVisible(container,{mRightNode = false})
    --    NodeHelper:setNodesVisible(container,{mLuckyNode = false})
        NodeHelper:setNodesVisible(container,{mLuckyValue = false})
    end
end
        
function TribeAwardsPage:getConfig(container)
    copyRewardInfo = common:deepCopy( TribeAwardsDataManager.rewardInfo )
    TribeAwardsDataManager.totalSize = #copyRewardInfo
    local size = TribeAwardsDataManager.totalSize
    copyRewardInfo = common:reverseArray(copyRewardInfo,TribeAwardsDataManager.totalSize)
    --初始化 最大幸运值 积分    
    for i=1,size do 
        TribeAwardsDataManager.maxLuckyValue[i] = copyRewardInfo[size+1-i].luckyvalue
        TribeAwardsDataManager.consumeScore[i] =  copyRewardInfo[size+1-i].score
    end
end

function TribeAwardsPage:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_TRIBEAWAED);
end

function TribeAwardsPage:onEnter(container)
    self:getConfig(container)
    --隐藏进度条和按钮
    self:setVisible(container,0)    
    self:registerPacket( container )	
    self:getPageInfo(container)
    self:initScrollView(container)
    self:rebuildItem(container)
end

function TribeAwardsPage:setScrollView(container)
    local newOffset = TribeAwardsDataManager.fScrollViewWidth - (TribeAwardsDataManager.currentState)*TribeAwardsDataManager.fScrollViewWidth
    mScrollView:setContentOffset(ccp(newOffset, mScrollView:getContentOffset().y))
	self:refreshPage(mContainer)
end

function TribeAwardsPage:onClose( container )
    PageManager.refreshPage("ActivityPage")
	PageManager.popPage(thisPageName)
end

function TribeAwardsPage:getPageInfo(container)
    common:sendEmptyPacket(HP_pb.COMMENDATION_TRIBE_INFO_C,false)
end

function TribeAwardsPage:registerPacket(container)
    container:registerPacket(HP_pb.COMMENDATION_TRIBE_INFO_S)
	container:registerPacket(HP_pb.COMMENDATION_TRIBE_LUCK_S)
end

function TribeAwardsPage:removePacket(container)
    container:removePacket(HP_pb.COMMENDATION_TRIBE_INFO_S)
	container:removePacket(HP_pb.COMMENDATION_TRIBE_LUCK_S)
end

--收包
function TribeAwardsPage:onReceivePacket(container)
    TribeAwardsDataManager.rewardIds = {}
    local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.COMMENDATION_TRIBE_INFO_S then
	    local msg = Activity_pb.HPCommendationTribe()
		msg:ParseFromString(msgBuff)	
		TribeAwardsDataManager.currentState 		= msg.curStage or 0
        TribeAwardsDataManager.leftTimes          = msg.leftCount or 0
        TribeAwardsDataManager.totalConsume       = msg.costGold or 0
        TribeAwardsDataManager.trueLuckyValue  = msg.curLuckyValue or 0
        TribeAwardsDataManager.remainTime         = msg.leftTime or 0 
    end
    if TribeAwardsDataManager.currentState > 5 then
        isLevelComplete = 1
    end
    TribeAwardsDataManager.currentState = math.min(TribeAwardsDataManager.currentState,5)
    TribeAwardsDataManager.currentIndex = TribeAwardsDataManager.currentState

    if opcode == HP_pb.COMMENDATION_TRIBE_LUCK_S then
		local msg = Activity_pb.HPCommendationTribeLuck()
        msg:ParseFromString(msgBuff);
        for _, item in ipairs(common:split(msg.rewards, ",")) do
            table.insert(TribeAwardsDataManager.rewardIds,item)
        end
        getReward = 1
	end

    --第一次进入定位到当前等级
    self:setScrollView(container)
	self:refreshPage(container)
end
function TribeAwardsPage:onLucky(container) 
    if TribeAwardsDataManager.leftTimes <= 0 then
        MessageBoxPage:Msg_Box_Lan("@LeftTimesLimited");
        return
    end
    common:sendEmptyPacket(HP_pb.COMMENDATION_TRIBE_LUCK_C,false);
    
end
-- 控制按钮不可按
local function m_BtnDelay( menuItem )
    local array = CCArray:create()
    local btnUnableAction = CCCallFunc:create(function( )
        NodeHelper:setMenuEnabled(menuItem,false)
    end)
    local btnAbleAction = CCCallFunc:create(function( )
        NodeHelper:setMenuEnabled(menuItem,true)
    end)
    array:addObject(btnUnableAction)
    array:addObject(CCDelayTime:create(0.3))
    array:addObject(btnAbleAction)
    local seq = CCSequence:create(array)
    menuItem:runAction(seq)
end
local function m_AllBtnDelay( container )
    m_BtnDelay(container:getVarMenuItemImage("mLeftBtn"))
    m_BtnDelay(container:getVarMenuItemImage("mRightBtn"))
end
---滑动
function TribeAwardsPage:onLeft(container)
	m_AllBtnDelay( container )
    NodeHelper:setMenuItemEnabled(container,"mLeftBtn",false)
    TribeAwardsDataManager.currentIndex = TribeAwardsDataManager.currentIndex - 1
	TribeAwardsDataManager.currentIndex = math.max(TribeAwardsDataManager.currentIndex,1)
	TribeAwardsDataManager.currentIndex = math.min(TribeAwardsDataManager.currentIndex,TribeAwardsDataManager.totalSize)
    CCLuaLog(" TribeAwardsPage:onLeft "..TribeAwardsDataManager.currentIndex)
	TribeAwardsPage:MoveToIndex(TribeAwardsDataManager.currentIndex)
end
function TribeAwardsPage:onRight(container)
	m_AllBtnDelay( container )
    NodeHelper:setMenuItemEnabled(container,"mRightBtn",false)
    TribeAwardsDataManager.currentIndex = TribeAwardsDataManager.currentIndex + 1
	TribeAwardsDataManager.currentIndex = math.max(TribeAwardsDataManager.currentIndex,1)
	TribeAwardsDataManager.currentIndex = math.min(TribeAwardsDataManager.currentIndex,TribeAwardsDataManager.totalSize)
    CCLuaLog(" TribeAwardsPage:onLeft "..TribeAwardsDataManager.currentIndex)
	TribeAwardsPage:MoveToIndex(TribeAwardsDataManager.currentIndex)
end
function TribeAwardsPage:MoveToIndex(index)
	local newOffset = TribeAwardsDataManager.fScrollViewWidth - (index)*TribeAwardsDataManager.fScrollViewWidth
	local array = CCArray:create();	
	array:addObject(CCDelayTime:create(0.1));
	local functionAction = CCCallFunc:create(function ()
	    mScrollView:getContainer():stopAllActions()
		mScrollView:setContentOffsetInDuration(ccp(newOffset, mScrollView:getContentOffset().y),0.2);
		self:refreshPage(mContainer)
	end)
	array:addObject(functionAction);
	local seq = CCSequence:create(array);	
	mScrollView:runAction(seq)	
end
local CommonPage = require("CommonPage");
TribeAwardsPage = CommonPage.newSub(TribeAwardsPage, thisPageName, option);
