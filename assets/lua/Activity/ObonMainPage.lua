
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local UserMercenaryManager = require("UserMercenaryManager")
local ActivityDialogConfig = require("Activity.ActivityDialogConfig");
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb");
local thisPageName = 'ObonMainPage'
local ObonMainPage = {}
local thisActivityInfo = {}
local _StageId = nil;--当前阶段的ID
local _GetIndex = nil;--当前显示阶段的ID
local isOpenTreasure = false;--判断是否打开的当前的宝箱
local MercenaryRoleInfos = {} -- 佣兵碎片数据包
local ghostAni1 = nil -- 下拉信息
local ghostAni2 = nil -- 宝箱状态信息
local ghostAni3 = nil -- 宝箱状态信息
local ghostAni1Flag = true -- 控制下拉状态
local COUNT_LIMIT = 10;--10次奖励
local alreadyShowReward = {}--界面上已经显示的奖励
local alreadyShowReward_multiple = {}--界面上已经显示的奖励
local m_NowSpine = nil--界面上已经显示的奖励
local m_NowSpineFlag = false--界面上已经显示的奖励
----------------scrollview-------------------------

local RequestNumber = {
	syncServerData = 0,--第一次请求
	requestProgress = 1, --单次抽奖和免费 
	tenRewards = 2, --10次抽奖
	receiveBox = 3, --领礼包
}

--2倍和5倍
local multiple_x2 = 2;
local multiple_x5 = 5;

local SaveServerData = {}

local opcodes = {
	OBON_C = HP_pb.OBON_C,
	OBON_S = HP_pb.OBON_S,
	ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S,
};

local option = {
     ccbiFile1 = "Act_TimeLimitGhostAni1.ccbi",
     ccbiFile2 = "Act_TimeLimitGhostAni2.ccbi",
     ccbiFile3 = "Act_TimeLimitGhostAni3.ccbi",
}

ObonMainPage.timerName = "syncServerActivityTimes";
ObonMainPage.RemainTime = -1;

--重置数据
function ObonMainPage:resetData()
	thisActivityInfo = {}
	_StageId = nil;--当前阶段的ID
	isOpenTreasure = false;
	self:ClearALreadyShowReward();
	m_NowSpine = nil;
	m_NowSpineFlag = false;
end

--读取配置文件信息
function ObonMainPage:getReadTxtInfo()
    local list = ConfigManager.getObonConfigCfg()
    for k, v in pairs(list)  do--宝箱预览奖励
		thisActivityInfo.activityCfg = v;
	end

	list = ConfigManager.getObonRewardCfg()
	thisActivityInfo.treasureList1 = {}
	thisActivityInfo.treasureList2 = {}
	for i = 1,#list do--宝箱预览奖励
		table.insert( thisActivityInfo["treasureList"..list[i].type] , list[i].rewards[1]);
	end

	list = ConfigManager.getObonStageInfoCfg()
	thisActivityInfo.stageCfg = {}
	for i = 1,#list do--阶段信息
		thisActivityInfo.stageCfg[list[i].stage] = list[i];
	end	
end

function ObonMainPage:onEnter(ParentContainer)
	self:resetData();
	self:getReadTxtInfo()
	local container = ScriptContentBase:create("Act_TimeLimitGhostContent.ccbi")
	self.container = container
    self.container:registerFunctionHandler(ObonMainPage.onFunction)
	self:registerPacket(ParentContainer);  
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	
	NodeHelper:setStringForLabel(self.container, { mLastTime = ""});
	NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
	self:addAniChild();
    self:HideRewardNode(self.container);
    self:requestServerData(RequestNumber.syncServerData);
    self:onShowDialog();
    -- self:initDataTest(1);--测试使用
    -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    
	return self.container
end

--是否弹出对话
function ObonMainPage:onShowDialog()
	local saveDialogStatus = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "ObonDialogShow";
	local dialogStatus = CCUserDefault:sharedUserDefault():getStringForKey(saveDialogStatus);--保存当前的阶段，判断是否更新
	if not dialogStatus or dialogStatus == "" then--如果没有弹出过，则弹出对话
		require("ActivityDialogConfigPage");
	    ActivityDialogConfigBase_setAlreadySelItem(105);
		PageManager.pushPage("ActivityDialogConfigPage");
		CCUserDefault:sharedUserDefault():setStringForKey(saveDialogStatus, saveDialogStatus);
		CCUserDefault:sharedUserDefault():flush();
	end
end

function ObonMainPage.onFunction(eventName,container)
	if eventName == "onRewardPreview" then
		ObonMainPage:onRewardPreview(container)
	elseif eventName == "onIllustatedOpen" then
		ObonMainPage:onTreasurePreview();
    elseif eventName == "onFree" then
    	ObonMainPage:onFree();
    elseif eventName == "onDiamond" then
    	ObonMainPage:onDiamond();
    elseif eventName == "onRight" then
    	ObonMainPage:onRight(container);
    elseif eventName == "onLeft" then
		ObonMainPage:onLeft(container);
	elseif eventName == "luaOnAnimationDone" then
		ObonMainPage:onAnimationDone(container);
	elseif eventName == "onClick" then
		ObonMainPage:onClick(container);
	elseif eventName == "onSoulStar1" then
		ObonMainPage:onSoulStar1(container);
	elseif eventName:sub(1, 6) == "onHand" then
		ObonMainPage:onHand(container,eventName);
	end
end

--测试数据
function ObonMainPage:initDataTest(id)
	SaveServerData = {};
	SaveServerData.oneCostGold = 100;--一次消耗的金币
	SaveServerData.tenCostGold = 1200;--10次消耗的金币
	SaveServerData.remainderTime = 134422;--活动剩余时间134422
	ObonMainPage.RemainTime = SaveServerData.remainderTime
	
	_StageId = 2;
	_GetIndex = _StageId;
	SaveServerData.mustGet = 10;--必得
	SaveServerData.buffLeaveTime = 14422;
	SaveServerData.freeTime = 0;
	SaveServerData.buffLeaveTimeName = "";
	SaveServerData.freeTimeName = "";

	if SaveServerData.buffLeaveTime > 0 then
		SaveServerData.buffLeaveTimeName = "buffLeaveTimeName";
	end

	if SaveServerData.freeTime > 0 then
		SaveServerData.freeTimeName = "onFreeTimeName";
	end

    thisActivityInfo.stageInfo = {}
	for i = 1,3 do
		local cfg = {}
		cfg.progress = i;
		cfg.status = true;
		if i == 2 then
			cfg.status = false;
		end
		thisActivityInfo.stageInfo[i] = cfg;
	end

	self:refreshPage();
	self:onChangeTimes();
end

function ObonMainPage:refreshPage()
	ObonMainPage:updateGold()
	if SaveServerData.freeTime <= 0 then --有免费次数
        NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false});
	else
		NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true});
		NodeHelper:setStringForLabel(self.container, { mCostNum = SaveServerData.oneCostGold });--1回消耗钻石
	end
	NodeHelper:setStringForLabel(self.container, { mDiamondText = SaveServerData.tenCostGold });--10回消耗钻石
	NodeHelper:setStringForLabel(self.container, { mNowRate = common:getLanguageString(thisActivityInfo.stageCfg[_GetIndex].name)});--阶段名字
	NodeHelper:setStringForLabel(self.container, { mLuckyRate = common:getLanguageString("@GhostLuckyTxt".._GetIndex)..thisActivityInfo.stageCfg[_GetIndex].probability.."%" });--幸运概率
	NodeHelper:setStringForLabel(self.container, { mActDouble = SaveServerData.mustGet..common:getLanguageString("@GhostDoubleTxt")});--多少回必得
	self:onChangeLantern();
	self:onChangeProgress();
	self:updateTreasureStatus();
	self:showRoleSpine();
end

function ObonMainPage:onChangeProgress()
	-- local playerSprite = self.container:getVarSprite("mShootBG");
	local playerSprite = CCSprite:create("UI/Common/BG/Act_TL_Ghost_BG_".._GetIndex..".png")
	local playerNode = self.container:getVarSprite("mShootBG")
	local size = playerSprite:getContentSize()
	playerNode:removeAllChildren()

	if _GetIndex <= _StageId then--小于等于当前阶段是亮的
		 playerNode:addChild(playerSprite)
        playerSprite:setPosition(ccp(size.width/2,size.height/2));
	else
		--图片置灰
		local graySprite = GraySprite:new()
		local texture = playerSprite:getTexture()
		graySprite:initWithTexture(texture,CCRectMake(0,0,size.width,size.height))
		playerNode:addChild(graySprite)
		graySprite:setPosition(ccp(size.width/2,size.height/2));
	end

	--当前阶段，并且已经达到最大进度的时候
	if thisActivityInfo.stageInfo[_GetIndex].progress >= thisActivityInfo.stageCfg[_GetIndex].progress then
		NodeHelper:setStringForLabel(self.container, { mRate = common:getLanguageString("@ObonStageProgress")});--当前进度
	else
		NodeHelper:setStringForLabel(self.container, { mRate = common:getLanguageString("@GhostRateTxt".._GetIndex)..thisActivityInfo.stageInfo[_GetIndex].progress.."/"..thisActivityInfo.stageCfg[_GetIndex].progress });--当前进度
	end
	-- NodeHelper:setSpriteImage(self.container, { mShootBG = "UI/Common/BG/Act_TL_Ghost_BG_".._GetIndex..".png" });
end

--更新金币
function ObonMainPage:updateGold()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

function ObonMainPage:onAnimationDone( container )
	local animationName=tostring(container:getCurAnimationDoneName())
	if string.sub(animationName,1,8)=="ItemAni_" then
        local index = tonumber(string.sub(animationName,-2))
		if index < #SaveServerData.rewards then
            self:refreshRewardNode(container,index+1)
        else
            --播放完毕
            m_NowSpineFlag = false;
	        NodeHelper:setMenuItemEnabled( self.container, "mDiamond", true);
	        NodeHelper:setMenuItemEnabled( self.container, "mFree", true);
            --
        end
    elseif animationName == "Born2" then
    	ghostAni3:runAnimation("Loop2")
    elseif animationName == "Born5" then
    	ghostAni3:runAnimation("Loop5")
	end
end

function ObonMainPage:onSoulStar1(container)--Normal Close Open
	if ghostAni1Flag then
		ghostAni1Flag = false;
		ghostAni1:runAnimation("Close")
	else
		ghostAni1Flag = true;
		ghostAni1:runAnimation("Open")
	end
end

--更新宝箱状态
function ObonMainPage:updateTreasureStatus()
	if not thisActivityInfo.stageInfo[_GetIndex].status and thisActivityInfo.stageInfo[_GetIndex].progress >= thisActivityInfo.stageCfg[_GetIndex].progress then
		ghostAni2:runAnimation("Open")
	elseif thisActivityInfo.stageInfo[_GetIndex].status then
		ghostAni2:runAnimation("Ready")
	else
		ghostAni2:runAnimation("Normal")
	end
end

--添加两个动画节点
function ObonMainPage:addAniChild()
	--下拉动画节点
	ghostAni1 = ScriptContentBase:create(option.ccbiFile1)
	local rightNode = self.container:getVarNode('mRightFrameNode')
	rightNode:addChild(ghostAni1)
	ghostAni1:registerFunctionHandler(ObonMainPage.onFunction)
    ghostAni1:runAnimation("Open")
    ghostAni1:release();
    NodeHelper:setStringForLabel(ghostAni1, { mName = common:getLanguageString(thisActivityInfo.activityCfg.name)});--名字

    ---箱子动画节点
	ghostAni2 = ScriptContentBase:create(option.ccbiFile2)
	local leftNode = self.container:getVarNode('mBoxNode')
	leftNode:addChild(ghostAni2)
    ghostAni2:runAnimation("Normal")
	ghostAni2:registerFunctionHandler(ObonMainPage.onFunction)
    ghostAni2:release();

    --灯笼播放节点
	ghostAni3 = ScriptContentBase:create(option.ccbiFile3)
	local leftNode = self.container:getVarNode('mLightNode')
	leftNode:addChild(ghostAni3)
	ghostAni3:registerFunctionHandler(ObonMainPage.onFunction)
    ghostAni3:release();
end

--奖励动画
function ObonMainPage:refreshRewardNode(container,index)
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

function ObonMainPage:ClearALreadyShowReward()
	alreadyShowReward = {}
    alreadyShowReward_multiple = {}
end

function ObonMainPage:HideRewardNode(container)
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

--添加SPINE动画
function ObonMainPage:showRoleSpine()
    local heroNode = self.container:getVarNode("mSpine1")
    if heroNode and m_NowSpine == nil then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width,height =  visibleSize.width ,visibleSize.height
        local rate = visibleSize.height/visibleSize.width
        local desighRate = 960/640
        rate = rate / desighRate
        heroNode:removeAllChildren()
        local roldData = ConfigManager.getRoleCfg()[thisActivityInfo.activityCfg.id]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        
        m_NowSpine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(m_NowSpine, "CCNode")  
        heroNode:addChild(spineNode)
		m_NowSpine:runAnimation(1, "Stand", -1)
    end
    if _GetIndex == _StageId then
    	heroNode:setVisible(true);
    else
    	heroNode:setVisible(false);
    end
end

function ObonMainPage:onHand(container,eventName)
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

--点击右边
function ObonMainPage:onRight(container)
	if m_NowSpineFlag then
		return;
	end
	self:ClearALreadyShowReward();
	self:HideRewardNode(self.container);
	container:runAnimation("StandAni")
	_GetIndex = _GetIndex + 1;
	self:onChangeIndex(_GetIndex)
	self:onChangeDonwLine(true);
end

--点击左边
function ObonMainPage:onLeft(container)
	if m_NowSpineFlag then
		return;
	end
	self:ClearALreadyShowReward();
	self:HideRewardNode(self.container);
	container:runAnimation("StandAni")
	_GetIndex = _GetIndex - 1;
	self:onChangeIndex(_GetIndex)
	self:onChangeDonwLine(true);
end

function ObonMainPage:onChangeIndex(index)
    _GetIndex = index;
	if index == 3 then
		local redPoint = thisActivityInfo.stageInfo[1].status or thisActivityInfo.stageInfo[2].status
		NodeHelper:setNodesVisible(self.container, { mArrowLeftPoint = redPoint, mArrowRightPoint = false});
		NodeHelper:setNodesVisible(self.container, { mLeftNode = true, mRightNode = false});
	elseif index == 1 then
		local redPoint = thisActivityInfo.stageInfo[2].status or thisActivityInfo.stageInfo[3].status
		NodeHelper:setNodesVisible(self.container, { mArrowLeftPoint = false, mArrowRightPoint = redPoint});
		NodeHelper:setNodesVisible(self.container, { mLeftNode = false, mRightNode = true});
	else
		NodeHelper:setNodesVisible(self.container, { mArrowLeftPoint = thisActivityInfo.stageInfo[1].status, mArrowRightPoint = thisActivityInfo.stageInfo[3].status});
		NodeHelper:setNodesVisible(self.container, { mLeftNode = true, mRightNode = true});
	end
	self:refreshPage();
end

function ObonMainPage:onChangeLantern(index)
	--当前阶段相同
	if SaveServerData.buf_multiple == multiple_x5 then -- 5倍
		ghostAni3:runAnimation("Born5")
	elseif SaveServerData.buf_multiple == multiple_x2 then -- 2倍
		ghostAni3:runAnimation("Born2")
	else
		ghostAni3:runAnimation("Normal")
	end
end

function ObonMainPage:onChangeDonwLine(flag)
	if ghostAni1Flag == flag then
		return;
	end
	ghostAni1Flag = flag;
	if ghostAni1Flag then
		ghostAni1:runAnimation("Open")
	else
		ghostAni1:runAnimation("Close")
	end
end

--点击免费次数或者单次的回调
function ObonMainPage:onFree()
	self:onChangeIndex(_StageId)
	self:onChangeDonwLine(false);
	if SaveServerData.freeTime <= 0 or UserInfo.playerInfo.gold >= SaveServerData.oneCostGold then
		self:requestServerData(RequestNumber.requestProgress);
	else
		self:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.oneCostGold,RequestNumber.requestProgress);
	end
end

--点击十次回调
function ObonMainPage:onDiamond()
	self:onChangeIndex(_StageId)
	self:onChangeDonwLine(false);
	if UserInfo.playerInfo.gold >= SaveServerData.tenCostGold then
		self:requestServerData(RequestNumber.tenRewards);
	else
		self:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.tenCostGold,RequestNumber.tenRewards);
	end
end

function ObonMainPage:rechargePageFlag(titleDic,descDic,needGold,messageNumber,isConcat)
	local title = common:getLanguageString(titleDic)
	local message = common:getLanguageString(descDic)
	if isConcat then
		message = common:getLanguageString(descDic,needGold)
	else
		message = common:getLanguageString(descDic)
	end
	PageManager.showConfirm(title, message,
		function (agree)
		    if agree then
		    	if UserInfo.playerInfo.gold >= needGold then--加满需要的钻石
		    		self:requestServerData(messageNumber);
		    	else--钻石不足充值
		    		libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","ActivityObonMainPage_enter_rechargePage")
					PageManager.pushPage("RechargePage");
		    	end
		   	end
		end
	)
end

function ObonMainPage:onReceiveMessage(eventName, container)
     ObonMainPage:updateGold()
end

function ObonMainPage:onExecute(ParentContainer)
	self:onTimer()
end


function ObonMainPage:onClick(container)--Normal Ready Open
	self:onTreasurePreview();
end

--宝箱奖励预览
function ObonMainPage:onTreasurePreview(container)
	if thisActivityInfo.stageInfo[_GetIndex].status then
		self:requestServerData(RequestNumber.receiveBox);
	else
		PageManager.pushPage("ObonStageAwardPreviewPage");
	end
end

--阶段奖励预览
function ObonMainPage:onRewardPreview(container)
	require("NewSnowPreviewRewardPage")
    NewSnowPreviewRewardPage_SetConfig(thisActivityInfo.treasureList1 , thisActivityInfo.treasureList2,"@ObonPreviewPrompt1", "@ObonPreviewPrompt2")
    PageManager.pushPage("NewSnowPreviewRewardPage");
end

function ObonMainPage:analysisServerData(msg)
	SaveServerData = {};
	_StageId = msg.currentStage;--当前阶段的ID
	_GetIndex = _StageId;
	local saveStageName = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "ObonNowStage"
	local nowStage = CCUserDefault:sharedUserDefault():getStringForKey(saveStageName)--保存当前的阶段，判断是否更新
	if not nowStage or nowStage == "" then
		CCUserDefault:sharedUserDefault():setStringForKey(saveStageName, tostring(_StageId))
		CCUserDefault:sharedUserDefault():flush()
	elseif _StageId ~= 1 and tonumber(nowStage) ~= _StageId then
		CCUserDefault:sharedUserDefault():setStringForKey(saveStageName, tostring(_StageId))
		CCUserDefault:sharedUserDefault():flush()
		local messageTips = common:getLanguageString("@ObonCompletePrompt",_StageId)
		MessageBoxPage:Msg_Box_Lan(messageTips);
	end

    self:removeOnFreeTime();
    self:removeBuffLeaveTime();

	SaveServerData.oneCostGold = msg.onceCostGold;--一次消耗的金币
	SaveServerData.tenCostGold = msg.tenCostGold;--10次消耗的金币
	SaveServerData.remainderTime = msg.leftTime;--活动剩余时间134422
	ObonMainPage.RemainTime = SaveServerData.remainderTime;
	
	SaveServerData.buf_multiple = msg.buf_multiple;--当前buf倍数, 没有buf为1
	SaveServerData.mustGet = msg.leftAwardTimes;--必得
	SaveServerData.buffLeaveTime = msg.leftBuffTimes;--buff离开的时间
	SaveServerData.freeTime = msg.freeCD;--免费的时间
	SaveServerData.buffLeaveTimeName = "";
	SaveServerData.freeTimeName = "";

	if SaveServerData.buffLeaveTime > 0 then
		SaveServerData.buffLeaveTimeName = "buffLeaveTimeName";
	end

	if SaveServerData.freeTime > 0 then
		SaveServerData.freeTimeName = "onFreeTimeName";
	end

	local progressList = msg.progress--当前的所有进度
	local allStatus = msg.canGetGift--当前的所有进度的宝箱状态

	local isGetBox = false;--是否有宝箱没有领取
    thisActivityInfo.stageInfo = {}
	for i = 1,#progressList do
		local cfg = {}
		cfg.progress = progressList[i];
		cfg.status = allStatus[i];
		thisActivityInfo.stageInfo[i] = cfg;
		if cfg.status then
			isGetBox = true;
		end
	end

	if SaveServerData.freeTime > 0 and not isGetBox then
		ActivityInfo.changeActivityNotice(105)--隐藏红点
	end

	SaveServerData.rewards = {}
	SaveServerData.reward_multiple = {}
	
	--奖励对应的倍数  长度和reward对应
	if #msg.reward_multiple > 0 then
		SaveServerData.reward_multiple = msg.reward_multiple
	end

    --抽奖奖励(只有抽奖的时候才会有)
	if #msg.reward > 0 then
		local beginIndex = 1;
        if (#alreadyShowReward + #msg.reward) > COUNT_LIMIT then
            self:HideRewardNode(self.container);
			self:ClearALreadyShowReward()
        else
            beginIndex = #alreadyShowReward + 1;
        end
        for i = 1,#msg.reward do
            alreadyShowReward[#alreadyShowReward+1] = msg.reward[i]
            alreadyShowReward_multiple[#alreadyShowReward_multiple+1] = msg.reward_multiple[i]
        end

		SaveServerData.rewards = msg.reward
		m_NowSpineFlag = true;
		NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
		self:refreshRewardNode(self.container,beginIndex);
	end

	----------------更新UI---------------------
	self:onChangeIndex(_GetIndex);
	self:onChangeTimes();

	if isOpenTreasure then--宝箱奖励弹出提示
		isOpenTreasure = false;
		MessageBoxPage:Msg_Box(common:getLanguageString("@obonMailPrompt"))
	end
	common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
end

--计算倒计时
function ObonMainPage:onTimer()
	self:onBuffLeaveTime();
	self:onFreeTime();
	if not TimeCalculator:getInstance():hasKey(self.timerName) then
	    if ObonMainPage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif ObonMainPage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime <= 0 then --倒计时完毕重新请求
	 	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	 	NodeHelper:setStringForLabel(self.container, { mTanabataCD = ""});
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr});
end

--计算buff离开倒计时
function ObonMainPage:onBuffLeaveTime()
	if SaveServerData.buffLeaveTimeName ~= "" and SaveServerData.buffLeaveTimeName ~= nil then
		if not TimeCalculator:getInstance():hasKey(SaveServerData.buffLeaveTimeName) then
		    if SaveServerData.buffLeaveTime <= 0 then
		        NodeHelper:setStringForLabel(self.container,{mLastTime = ""})
	        end
	        return; 
	    end

		local remainTime = TimeCalculator:getInstance():getTimeLeft(SaveServerData.buffLeaveTimeName);
		if remainTime <= 0 then --倒计时完毕重新请求
			self:removeBuffLeaveTime();
		 	NodeHelper:setStringForLabel(self.container, { mLastTime = ""});
		 	self:requestServerData(RequestNumber.syncServerData);
		else
			local timeStr = common:dateFormat2String(remainTime, true);
			NodeHelper:setStringForLabel(self.container, { mLastTime = timeStr});
		end
	end
end

function ObonMainPage:removeBuffLeaveTime()
	if SaveServerData.buffLeaveTimeName ~= "" then
        TimeCalculator:getInstance():removeTimeCalcultor(SaveServerData.buffLeaveTimeName);
		SaveServerData.buffLeaveTimeName = ""
	end
	NodeHelper:setStringForLabel(self.container, { mLastTime = ""});
end

--计算免费次数倒计时
function ObonMainPage:onFreeTime()
	if SaveServerData.freeTimeName ~= "" and SaveServerData.freeTimeName ~= nil then
		if not TimeCalculator:getInstance():hasKey(SaveServerData.freeTimeName) then
		    if SaveServerData.freeTime <= 0 then
		        NodeHelper:setStringForLabel(self.container,{mSuitFreeTime = ""})
	        end
	        return; 
	    end

		local remainTime = TimeCalculator:getInstance():getTimeLeft(SaveServerData.freeTimeName);
		if remainTime <= 0 then --倒计时完毕重新请求
			self:removeOnFreeTime();
		 	NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
		 	self:requestServerData(RequestNumber.syncServerData);
		else
			local timeStr = common:dateFormat2String(remainTime, true);
			NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = timeStr});
		end
	end
end

function ObonMainPage:removeOnFreeTime()
	if SaveServerData.freeTimeName ~= "" then
        TimeCalculator:getInstance():removeTimeCalcultor(SaveServerData.freeTimeName);
		SaveServerData.freeTimeName = ""
	end
	NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
end

function ObonMainPage:requestServerData(type)
	local msg = Activity3_pb.ObonReq();
	msg.type = type;
	isOpenTreasure = false;--其他都奖励不弹提示
	if RequestNumber.receiveBox == type then -- 请求保险的时候，带上当前阶段
		isOpenTreasure = true;--宝箱弹出提示
		msg.stage = thisActivityInfo.stageCfg[_GetIndex].stage;
	end
	common:sendPacket(opcodes.OBON_C, msg, true);
end

--更新佣兵碎片数量
function ObonMainPage:updateMercenaryNumber()
	for i = 1,#MercenaryRoleInfos do
        --local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
		if thisActivityInfo.activityCfg.id == MercenaryRoleInfos[i].itemId then
			NodeHelper:setStringForLabel(ghostAni1, { mCoin = common:getLanguageString("@GhostCoinTxt").. MercenaryRoleInfos[i].soulCount.."/"..MercenaryRoleInfos[i].costSoulCount});
			break;
		end
	end
end

function ObonMainPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.OBON_S then
		local msg = Activity3_pb.ObonRet();
		msg:ParseFromString(msgBuff);
		self:analysisServerData(msg);
	elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        self:updateMercenaryNumber();
    end
end

function ObonMainPage:onChangeTimes()
	--活动剩余时间
	if ObonMainPage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, ObonMainPage.RemainTime)
	end

	--buff离开的时间
	if SaveServerData.buffLeaveTime > 0 and SaveServerData.buffLeaveTimeName ~= "" and not TimeCalculator:getInstance():hasKey(SaveServerData.buffLeaveTimeName) then
		TimeCalculator:getInstance():createTimeCalcultor(SaveServerData.buffLeaveTimeName, SaveServerData.buffLeaveTime)
	end

	--免费时间
	if SaveServerData.freeTime > 0 and SaveServerData.freeTimeName ~= "" and not TimeCalculator:getInstance():hasKey(SaveServerData.freeTimeName) then
		TimeCalculator:getInstance():createTimeCalcultor(SaveServerData.freeTimeName,SaveServerData.freeTime)
	end
end

function ObonMainPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function ObonMainPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function ObonMainPage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
 	self:removePacket(ParentContainer);
 	self:removeBuffLeaveTime();
 	self:removeOnFreeTime();
	onUnload(thisPageName, self.container);
end

return ObonMainPage
