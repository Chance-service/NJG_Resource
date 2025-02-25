
----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local UserMercenaryManager = require("UserMercenaryManager")
local ActivityDialogConfig = require("Activity.ActivityDialogConfig");
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb");
local thisPageName = 'TurntableMainPage'
local TurntableMainPage = {}
local thisActivityInfo = {}
local _GetIndex = nil;--当前显示阶段的ID

local MercenaryRoleInfos = {} -- 佣兵碎片数据包
local _nLoopCur = nil -- 下拉信息
local _nLoopCount = nil
local _ProgressTimerNode = nil -- 进度条
local _offsetY = nil -- 偏移量
local _offsetY2 = nil -- 偏移量

local COUNT_LIMIT = 10;--10次奖励
local alreadyShowReward = {}--界面上已经显示的奖励
local alreadyShowReward_multiple = {}--界面上已经显示的奖励
local m_AnimationEnd = false--动画是否结束
local m_ShowExchangePageAlreadyFlag = false--判断是否已经弹出过兑换界面

local MercenaryCfg = nil;
local TurntableMercenaryId = nil;
local _IsFirstRoll = nil;
local _IsFirstCircleRoll = nil;
local _SpriteWidth = nil;
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
	TURNTABLE_C = HP_pb.TURNTABLE_C,
	TURNTABLE_S = HP_pb.TURNTABLE_S,
	ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
};

TurntableMainPage.timerName = "syncServerActivityTimes";
TurntableMainPage.RemainTime = -1;

--重置数据
function TurntableMainPage:resetData()
	SaveServerData = {};
	thisActivityInfo = {}
	m_ShowExchangePageAlreadyFlag = false
	TurntableMainPage.RemainTime = -1;
	_IsFirstRoll = 0;
	_offsetY = 0;
	_offsetY2 = 0;
	_IsFirstCircleRoll = 0;
	_ProgressTimerNode = nil -- 进度条
	m_AnimationEnd = false
    math.randomseed(os.time());
    MercenaryCfg = ConfigManager.getRoleCfg()
    local MercenaryIdCfg = ConfigManager.getTurntableMercenaryIdCfg()
    for i,v in pairs(MercenaryIdCfg) do
        TurntableMercenaryId = v.id
    end
end

--读取配置文件信息
function TurntableMainPage:getReadTxtInfo()
	-- 主页转盘活动配置
    thisActivityInfo.activityCfg = ConfigManager.getTurntableRewardCfg()
    -- 宝箱奖励配置
	local list = ConfigManager.getTurntableBoxAwardCfg()
	for i = 1,#list do--宝箱预览奖励
		if not thisActivityInfo["treasureList"..list[i].type] then
			thisActivityInfo["treasureList"..list[i].type] = {}
		end
		table.insert( thisActivityInfo["treasureList"..list[i].type] , list[i].rewards[1]);
	end
end

function TurntableMainPage:onEnter(ParentContainer)
	self:resetData();
	self:getReadTxtInfo()
	local container = ScriptContentBase:create("Act_TimeLimitCircleContent.ccbi")
	self.container = container
    self.container:registerFunctionHandler(TurntableMainPage.onFunction)
	self:registerPacket(ParentContainer);  
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	--刚进来不让点击
	NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
    NodeHelper:setMenuItemEnabled( self.container, "mFree", false);

	NodeHelper:setStringForLabel(self.container, { mLastTime = ""});
	NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
	self:initMainPagePic();
    self:requestServerData(RequestNumber.syncServerData);
    -- self:initDataTest();--测试使用
    -- common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, true)
    
	return self.container
end

function TurntableMainPage.onFunction(eventName,container)
	if eventName == "onChange" then
		TurntableMainPage:onChange(container)
	elseif eventName == "onIllustatedOpen" then
		TurntableMainPage:onTreasurePreview();
    elseif eventName == "onFree" then
    	TurntableMainPage:onFree();
    elseif eventName == "onDiamond" then
    	TurntableMainPage:onDiamond();
	elseif eventName:sub(1, 8) == "onGetBox" then
		TurntableMainPage:onGetBox(container,eventName);
	elseif eventName == "onClick" then
		TurntableMainPage:onClick(container);
	elseif eventName == "onSoulStar1" then
		TurntableMainPage:onSoulStar1(container);
	elseif eventName:sub(1, 7) == "onFrame" then
		TurntableMainPage:onHand(container,eventName);
	end
end

function TurntableMainPage:initMainPagePic()
	local cfg = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1 
    for i = 1, #thisActivityInfo.activityCfg do
        cfg = thisActivityInfo.activityCfg[i]
        if cfg then--改变数据
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.rewards[1].type, cfg.rewards[1].itemId, cfg.rewards[1].count);
            sprite2Img["mPic" .. i]         = resInfo.icon;
            sprite2Img["mFrameShade".. i]   = NodeHelper:getImageBgByQuality(resInfo.quality);
            lb2Str["mNum" .. i]          = "x" .. GameUtil:formatNumber( cfg.rewards[1].count );
            lb2Str["mName" .. i]            = resInfo.name;
            menu2Quality["mFrame" .. i]      = resInfo.quality
            NodeHelper:setSpriteImage(self.container, sprite2Img);
            NodeHelper:setQualityFrames(self.container, menu2Quality);
            NodeHelper:setStringForLabel(self.container, lb2Str);
            if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
                NodeHelper:setNodeScale(self.container, "mPic" .. i, 0.84, 0.84)
            else
                NodeHelper:setNodeScale(self.container, "mPic" .. i, 1, 1)
            end
        end
    end
end

--测试数据
function TurntableMainPage:initDataTest()
	SaveServerData = {};
	SaveServerData.oneCostGold = 100;--一次消耗的金币
	SaveServerData.tenCostGold = 1200;--10次消耗的金币
	SaveServerData.remainderTime = 134422;--活动剩余时间134422  leftTime
	TurntableMainPage.RemainTime = SaveServerData.remainderTime
	
	SaveServerData.credits = 10;--当前积分
	SaveServerData.mustGet = 10;--必得luckyValue
	SaveServerData.freeTime = 10;--免费次数 freeCD
	SaveServerData.totalTimes = 50;--获得宝箱总的次数
	SaveServerData.canOpenBox = {10,30,50};--宝箱次数
	SaveServerData.condition = {false,false,false};--宝箱开启状态
	SaveServerData.multiple = {false,false,false};--奖励对应的倍数
	SaveServerData.reward = {false,false,false};--奖励
	self:refreshPage();
	self:onChangeTimes();
end

function TurntableMainPage:refreshPage()
	TurntableMainPage:updateGold()
	if SaveServerData.freeTime <= 0 then --有免费次数  KingPalaceFree1Text
		NodeHelper:setStringForLabel(self.container, { mFreeText = common:getLanguageString("@KingPalaceFree1Text")});--多少回必得
        NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false});
	else
		NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true});
		NodeHelper:setStringForLabel(self.container, { mCostNum = SaveServerData.oneCostGold });--1回消耗钻石
	end
	NodeHelper:setStringForLabel(self.container, { mDiamondText = SaveServerData.tenCostGold });--10回消耗钻石

	NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@TurntableIntegral",SaveServerData.credits)});--阶段名字T
	NodeHelper:setStringForLabel(self.container, { mActDouble = common:getLanguageString("@TurntableShallbePrompt",SaveServerData.mustGet,MercenaryCfg[TurntableMercenaryId].name)});--多少回必得
    TurntableMainPage:updateBoxInfo(self.container);
end

--更新宝箱状态
function TurntableMainPage:updateBoxInfo(container)
	NodeHelper:setStringForLabel(self.container, { mBoxNum1 = SaveServerData.condition[1],mBoxNum2 = SaveServerData.condition[2],
												mBoxNum3 = SaveServerData.condition[3]});--阶段名字T

    if SaveServerData.totalTimes >= SaveServerData.condition[1] and SaveServerData.canOpenBox[1] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_30 = false , mTaskRewardBox1_30 = true,mTaskRewardBox2_30 = fasle})
    elseif SaveServerData.totalTimes >= SaveServerData.condition[1] and not SaveServerData.canOpenBox[1] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_30 = false , mTaskRewardBox1_30 = false,mTaskRewardBox2_30 = true})
    else
    	NodeHelper:setNodesVisible(container, { mTaskRewardBox0_30 = true , mTaskRewardBox1_30 = false,mTaskRewardBox2_30 = false})
    end

    if SaveServerData.totalTimes >= SaveServerData.condition[2] and SaveServerData.canOpenBox[2] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_60 = false , mTaskRewardBox1_60 = true,mTaskRewardBox2_60 = false})
    elseif SaveServerData.totalTimes >= SaveServerData.condition[2] and not SaveServerData.canOpenBox[2] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_60 = false , mTaskRewardBox1_60 = false,mTaskRewardBox2_60 = true})
    else
    	NodeHelper:setNodesVisible(container, { mTaskRewardBox0_60 = true , mTaskRewardBox1_60 = false,mTaskRewardBox2_60 = false})
    end

    if SaveServerData.totalTimes >= SaveServerData.condition[3] and SaveServerData.canOpenBox[3] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_100 = false , mTaskRewardBox1_100 = true,mTaskRewardBox2_100 = false})
    elseif SaveServerData.totalTimes >= SaveServerData.condition[3] and not SaveServerData.canOpenBox[3] then
        NodeHelper:setNodesVisible(container, { mTaskRewardBox0_100 = false , mTaskRewardBox1_100 = false,mTaskRewardBox2_100 = true})
    else
    	NodeHelper:setNodesVisible(container, { mTaskRewardBox0_100 = true , mTaskRewardBox1_100 = false,mTaskRewardBox2_100 = false})
    end

    local parentNode = container:getVarNode("mLivenessBar")
    if not parentNode then return end
	
    if not _ProgressTimerNode then
    	parentNode:removeAllChildren()
    	local imageName = "UI/Common/Activity/Act_TL_Circle/Act_TL_Circle_Bar.png"
    	local sprite = CCSprite:create(imageName)
	    _ProgressTimerNode = CCProgressTimer:create(sprite)
	    _ProgressTimerNode:setType(kCCProgressTimerTypeBar)
	    _ProgressTimerNode:setMidpoint(CCPointMake(0, 0))
	    _ProgressTimerNode:setBarChangeRate(CCPointMake(1, 0))
	    _ProgressTimerNode:setAnchorPoint(ccp(0,0.5))
	    parentNode:addChild(_ProgressTimerNode)
	    _SpriteWidth = sprite:getContentSize().width
    end
    local percentNum = SaveServerData.totalTimes/SaveServerData.condition[3]*100
    _ProgressTimerNode:setPercentage(percentNum);
    --调整宝箱的位置
    local avg = math.floor( _SpriteWidth / 2 )
    for i = 1,3 do
        local nodeX = _SpriteWidth * SaveServerData.condition[i]/SaveServerData.condition[3] - avg
        local node = container:getVarNode("mBox"..i)
        node:setPositionX(nodeX)
    end
end

function TurntableMainPage:onGetBox(container,eventName)
	local curBoxId = tonumber(string.sub(eventName, -1, -1)) 
    local curState = 0
    if SaveServerData.totalTimes >= SaveServerData.condition[curBoxId] and not SaveServerData.canOpenBox[curBoxId] then
        curState = 2
    elseif SaveServerData.totalTimes >= SaveServerData.condition[curBoxId] and SaveServerData.canOpenBox[curBoxId] then
        curState = 1
    else
    	 curState = 0
    end
    if curState == 2 then--已完成
        MessageBoxPage:Msg_Box_Lan("@TurntableComplete")
    elseif curState == 0 then --未完成，预览奖励
        RegisterLuaPage("DailyTaskRewardPreview")
        ShowRewardPreview(thisActivityInfo["treasureList"..curBoxId],common:getLanguageString("@TaskDailyRewardPreviewTitle"),common:getLanguageString("@RewardShallbePrompt"))
        PageManager.pushPage("DailyTaskRewardPreview");
    else--请求奖励
        self:requestServerData(RequestNumber.receiveBox,curBoxId);
   end
end

--更新金币
function TurntableMainPage:updateGold()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

function TurntableMainPage:onHand(container,eventName)
    local index = tonumber(string.sub(eventName,8,string.len(eventName)))
    local _type, _id, _count = thisActivityInfo.activityCfg[index].rewards[1].type,thisActivityInfo.activityCfg[index].rewards[1].itemId,thisActivityInfo.activityCfg[index].rewards[1].count;
    local items = {}
    table.insert(items, {
		type 	= tonumber(_type),
		itemId	= tonumber(_id),
		count 	= tonumber(_count)
	});
    GameUtil:showTip(container:getVarNode('mPic'..index), items[1])
end

--点击免费次数或者单次的回调
function TurntableMainPage:onFree()
	if SaveServerData.freeTime <= 0 or UserInfo.playerInfo.gold >= SaveServerData.oneCostGold then
		self:requestServerData(RequestNumber.requestProgress);
	else
		self:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.oneCostGold,RequestNumber.requestProgress);
	end
end

--点击十次回调
function TurntableMainPage:onDiamond()
	if UserInfo.playerInfo.gold >= SaveServerData.tenCostGold then
		self:requestServerData(RequestNumber.tenRewards);
	else
		self:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.tenCostGold,RequestNumber.tenRewards);
	end
end

function TurntableMainPage.showMsgFinish(node)
    _offsetY = 360 - node:getRotation()%360 - 15;
end

function TurntableMainPage:arrowRotateTo(nodeName,num)
    m_AnimationEnd = true
    NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
    NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
	local obj = self.container:getVarNode(nodeName);
    local temp = 30 * (num - 1) + 15 + _IsFirstRoll;
	local jiaodu = temp + _offsetY + 2
    local act = CCEaseExponentialInOut:create(CCRotateBy:create(8, 360*10 + jiaodu));
    --CCEaseSineInOut
    local actFunc = CCCallFuncN:create(TurntableMainPage.showMsgFinish);
    --local act1 = CCEaseSineOut:create(CCRotateBy:create(jiaodu / 50,jiaodu))
    local spawnArr = CCArray:create()
    spawnArr:addObject(act)
    spawnArr:addObject(actFunc)
    obj:runAction(CCSequence:create(spawnArr));
    self:circleRotateTo("mPercentNumImage",temp);
end

function TurntableMainPage.showCircleFinish(node)
    _offsetY2 = 360 - node:getRotation()%360;
    TurntableMainPage:pushRewardPage()
end


function TurntableMainPage:pushRewardPage()
	local rewardItems = {}
	for i = 1, #SaveServerData.rewards do
		local items = common:parseItemWithComma(SaveServerData.rewards[i])
		-- items[1].count = items[1].count * SaveServerData.reward_multiple[i]
		items[1].count = items[1].count
		items[1].multiple = SaveServerData.reward_multiple[i]
--		table.insert(rewardItems,items[1]);
        rewardItems[i] = items[1]
	end
	
	local CommonRewardPage = require("CommonRewardPage")
    CommonRewardPageBase_setPageParm(rewardItems, true,nil,SaveServerData.reward_multiple) --, msg.rewardType
    PageManager.pushPage("CommonRewardPage")
    m_AnimationEnd = false
    NodeHelper:setMenuItemEnabled( self.container, "mDiamond", true);
    NodeHelper:setMenuItemEnabled( self.container, "mFree", true);
end

function TurntableMainPage:circleRotateTo(nodeName,rotateAngle)
	local num = SaveServerData.reward_multiple[#SaveServerData.reward_multiple]
	local mulNum = {1,5,2}
	local nIdx = 0;
	for key, value in pairs(mulNum) do
		if(value == num) then
			nIdx = key;
			break
		end
	end
	-- nIdx = math.random(1,3);
	local obj = self.container:getVarNode(nodeName);
    local jiaodu = 360 - (2*nIdx - 1) * 60 + _offsetY2 + rotateAngle - _IsFirstRoll;
    local act = CCEaseExponentialInOut:create(CCRotateBy:create(10, 360*10 + jiaodu));
    --CCEaseSineInOut
    local actFunc = CCCallFuncN:create(TurntableMainPage.showCircleFinish);
    --local act1 = CCEaseSineOut:create(CCRotateBy:create(jiaodu / 50,jiaodu))
    local spawnArr = CCArray:create()
    spawnArr:addObject(act)
    spawnArr:addObject(actFunc)
    obj:runAction(CCSequence:create(spawnArr));
    _IsFirstCircleRoll = 300;
    _IsFirstRoll = 15;
end

function TurntableMainPage:rechargePageFlag(titleDic,descDic,needGold,messageNumber,isConcat)
	if UserInfo.playerInfo.gold >= needGold then--加满需要的钻石
		self:requestServerData(messageNumber);
	else--钻石不足充值
		common:rechargePageFlag("TurntableMainPage")
	end
end

function TurntableMainPage:onReceiveMessage(eventName, container)
     TurntableMainPage:updateGold()
end

function TurntableMainPage:onExecute(ParentContainer)
	self:onTimer()
end


function TurntableMainPage:onClick(container)--Normal Ready Open
	self:onTreasurePreview();
end

--服务器信息同步
function TurntableMainPage:analysisServerData(msg)

	SaveServerData.oneCostGold = msg.oneCost;--一次消耗的金币
	SaveServerData.tenCostGold = msg.tenCost;--10次消耗的金币
	SaveServerData.remainderTime = msg.leftTime;--活动剩余时间134422
	TurntableMainPage.RemainTime = SaveServerData.remainderTime;

	SaveServerData.freeTime = msg.freeCD;--免费的时间
	SaveServerData.credits = msg.credits;--当前积分
	SaveServerData.mustGet = msg.luckyValue;--必得luckyValue
	SaveServerData.totalTimes = msg.totalTimes;--获得宝箱总的次数
	SaveServerData.canOpenBox = msg.canOpenBox;--宝箱次数
	SaveServerData.condition = msg.condition;--宝箱开启状态
	SaveServerData.id = msg.id;--获得的物品ID


	if SaveServerData.freeTime > 0 then
		ActivityInfo.changeActivityNotice(108)--隐藏红点
	end

	----------------更新UI---------------------
	self:refreshPage();
	if SaveServerData.remainderTime <= 0 then
		local endStr = common:getLanguageString("@ActivityEnd");
	    NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})
	    NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
    	NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
    	self.container:getVarNode("mRewardNode"):setVisible(false)
    	if not m_ShowExchangePageAlreadyFlag then
    		m_ShowExchangePageAlreadyFlag = true
    		PageManager.pushPage("TurntableExchangePage");
    	end
    	
	else
		NodeHelper:setMenuItemEnabled( self.container, "mDiamond", true);
    	NodeHelper:setMenuItemEnabled( self.container, "mFree", true);
		self:onChangeTimes();
	end

	-- 抽奖的时候才有
	--奖励对应的倍数  长度和reward对应
	if #msg.multiple > 0 then
		SaveServerData.reward_multiple = msg.multiple
	end

    --抽奖奖励(只有抽奖的时候才会有)
	if #msg.reward > 0 then
		SaveServerData.rewards = msg.reward
        self:rotateInfo();
	end
end

function TurntableMainPage:rotateInfo()
    self:arrowRotateTo("mArrowImage",SaveServerData.id);
end

--计算倒计时
function TurntableMainPage:onTimer()
	if TurntableMainPage.RemainTime == -1 or not TimeCalculator:getInstance():hasKey(self.timerName) then
		return;
	end

	if TurntableMainPage.RemainTime <= 0 and TimeCalculator:getInstance():hasKey(self.timerName) then
	    if TurntableMainPage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif TurntableMainPage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
        TurntableMainPage.RemainTime = -1;
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime <= 0 then --倒计时完毕重新请求
		TurntableMainPage.RemainTime = remainTime;
	 	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	 	NodeHelper:setStringForLabel(self.container, { mTanabataCD = ""});
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr});
end

function TurntableMainPage:requestServerData(type,boxId)
	local msg = Activity3_pb.TurntableReq();
	msg.type = type;
	if RequestNumber.receiveBox == type then -- 请求宝箱的时候，带上当前阶段
		msg.boxId = boxId;
	end
	common:sendPacket(opcodes.TURNTABLE_C, msg, true);
end

--更新佣兵碎片数量
function TurntableMainPage:updateMercenaryNumber()
	for i = 1,#MercenaryRoleInfos do
        --local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
		if TurntableMercenaryId == MercenaryRoleInfos[i].itemId then
			NodeHelper:setStringForLabel(self.container, { mPointNum = common:getLanguageString("@TurntableMercenaryNumber",MercenaryCfg[TurntableMercenaryId].name) .. MercenaryRoleInfos[i].soulCount.."/"..MercenaryRoleInfos[i].costSoulCount});
			break;
		end
	end
end

function TurntableMainPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.TURNTABLE_S then
		local msg = Activity3_pb.TurntableRet();
		msg:ParseFromString(msgBuff);
		self:analysisServerData(msg);
		common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
	elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        TurntableMainPage:updateMercenaryNumber()
    end
end

function TurntableMainPage:onChangeTimes()
	--活动剩余时间
	if TurntableMainPage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TurntableMainPage.RemainTime)
	end
end

--交换
function TurntableMainPage:onChange(container)
	 PageManager.pushPage("TurntableExchangePage");
end

function TurntableMainPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function TurntableMainPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function TurntableMainPage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
 	self:removePacket(ParentContainer);
 	_ProgressTimerNode = nil -- 进度条
 	MercenaryCfg = nil;
	onUnload(thisPageName, self.container);
end

return TurntableMainPage
