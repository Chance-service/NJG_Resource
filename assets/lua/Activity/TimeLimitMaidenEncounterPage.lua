
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb");
local thisPageName = 'TimeLimitMaidenEncounterPage'
local TimeLimitMaidenEncounterPage = {}
local thisActivityInfo = {}
local _ProgressTimerNode = nil;--进度条
local _StageId = nil;--当前阶段的ID
local isCreateProgress = false;--判断是否已经创建进度条
local WitchLeaveRequestDataFlag = false;--女巫离开请求数据
local _isRefreshFlag = false;--判断是否提示刷新
----------------scrollview-------------------------

local ItemType = {
	common = 1,--普通少女
	devil = 2,--女巫
}

local RequestNumber = {
	syncServerData = 0,--第一次请求
	interact = 1, --互动
	refreshMaiden = 2, --刷新
	addFill = 3, --加满
}

local SaveServerData = {}

local opcodes = {
	SYNC_MAIDEN_ENCOUNTER_C = HP_pb.SYNC_MAIDEN_ENCOUNTER_C,
	SYNC_MAIDEN_ENCOUNTER_S = HP_pb.SYNC_MAIDEN_ENCOUNTER_S
};

TimeLimitMaidenEncounterPage.timerName = "syncServerActivityTimes";
TimeLimitMaidenEncounterPage.RemainTime = -1;
TimeLimitMaidenEncounterPage.timeNameWitch = "";--女巫离开的倒计时

--重置数据
function TimeLimitMaidenEncounterPage:resetData()
	thisActivityInfo = {}
	_ProgressTimerNode = nil;--进度条
	_StageId = nil;--当前阶段的ID
	isCreateProgress = false;--判断是否已经创建进度条
	WitchLeaveRequestDataFlag = false;--女巫离开请求数据
	SaveServerData.isShow = true;--默认进来不让其互动
end

--读取配置文件信息
function TimeLimitMaidenEncounterPage:getReadTxtInfo()
	local list = ConfigManager.getMaidenEncountCfg()
	thisActivityInfo.activityCfg = {}
	for i = 1,#list do
		thisActivityInfo.activityCfg[list[i].id] = list[i];--以ID作为索引值
	end
	thisActivityInfo.stageCfg = ConfigManager.getMaidenEncountStageCfg()
end
function TimeLimitMaidenEncounterPage:onEnter(ParentContainer)
	self:resetData();
	self:getReadTxtInfo()
	_isRefreshFlag = false;
	local container = ScriptContentBase:create("Act_TimeLimitGirlsMeetContent.ccbi")
	self.container = container
    self.container:registerFunctionHandler(TimeLimitMaidenEncounterPage.onFunction)
	self:registerPacket(ParentContainer);  
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	NodeHelper:setNodeVisible(container:getVarNode("mIconFrame"),false);--隐藏上面的道具显示
	-- ActivityInfo.changeActivityNotice(104)--隐藏红点
	-- self:initDataTest(1);--测试使用
	self:requestServerData(RequestNumber.syncServerData);
	return self.container
end

function TimeLimitMaidenEncounterPage:showUIContent(type)

end

function TimeLimitMaidenEncounterPage.onFunction(eventName,container)
	if eventName == "onPreview" then
		TimeLimitMaidenEncounterPage:onPreview(container)
	elseif eventName == "onGirlsMeetHelp" then
		TimeLimitMaidenEncounterPage:onHelp();
	elseif eventName == "onChange" then
		TimeLimitMaidenEncounterPage:onChange();
	elseif eventName == "onDevilClick" then
		TimeLimitMaidenEncounterPage:onDevilClick();
    elseif eventName == "onFree" then
    	TimeLimitMaidenEncounterPage:onRefreshGirls();
    elseif eventName == "onDiamond" then
    	TimeLimitMaidenEncounterPage:onDiamond();
    elseif eventName == "onClick" then
		TimeLimitMaidenEncounterPage:onClick();
	elseif eventName == "luaRefreshItemView" then
	end
end

function TimeLimitMaidenEncounterPage:refreshPage(id)
    SaveServerData.id = id;
	local mType = thisActivityInfo.activityCfg[id].type;
	if ItemType.common == mType then--显示少女
		self:showUI(true);
	elseif ItemType.devil == mType then--显示女巫
		self:showUI(false);
	end
	TimeLimitMaidenEncounterPage:updateGold()
	
end

--更新金币
function TimeLimitMaidenEncounterPage:updateGold()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

function TimeLimitMaidenEncounterPage:showUI(flag)--true:显示少女；false：显示女巫
	NodeHelper:setNodeVisible(self.container:getVarNode("mIcon1"), flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mNormalNode"), flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mFreeBtnNode"), flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mDiamondBtnNode"), flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mIcon2"), not flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mDevilNode"), not flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mDevilInfo"), not flag)--@GirlsMeetCurrentRate
	if flag then--显示少女
		self:updateMaidenUI()
	else
		self:updateDevilUI();--显示女巫
	end
end

--显示女巫的UI信息
function TimeLimitMaidenEncounterPage:updateDevilUI()
    self.container:runAnimation("Devil_btnNormal");
    NodeHelper:setStringForLabel(self.container,{mDevilInfo = common:getLanguageString('@GirlsMeetCurrentRate5')});--GirlsMeetCurrentRate
    NodeHelper:setStringForLabel(self.container,{mTalk2 = common:getLanguageString(thisActivityInfo.activityCfg[SaveServerData.id].describe)});
    local itemObj = thisActivityInfo.activityCfg[SaveServerData.id].consumeItems[1]
    local haveNum = UserItemManager:getCountByItemId(itemObj.itemId);
--    haveNum = 0;
    self:setItemNumber(haveNum);
    local showGold = false;
    if haveNum ~= nil and haveNum >= itemObj.count then
    	NodeHelper:setStringForLabel(self.container,{mDevilIconCostNum = itemObj.count});--GirlsMeetCurrentRate
    	self:showDevilGoldOrItem(true);
    else
    	NodeHelper:setStringForLabel(self.container,{mDevilDiamondCostNum = thisActivityInfo.activityCfg[SaveServerData.id].consumeGold});--GirlsMeetCurrentRate
    	self:showDevilGoldOrItem(false);
    end
end

--显示消耗道具还是钻石
function TimeLimitMaidenEncounterPage:showDevilGoldOrItem(flag)
	NodeHelper:setNodeVisible(self.container:getVarNode("mDevilItemCostNode"), flag)
    NodeHelper:setNodeVisible(self.container:getVarNode("mDevilDiamondCostNode"), not flag)
end

function TimeLimitMaidenEncounterPage:setItemNumber(num)
	NodeHelper:setStringForLabel(self.container, { mIconNum = num });
end

--显示少女的UI信息
function TimeLimitMaidenEncounterPage:updateMaidenUI()
	self.container:runAnimation("Normal_btnNormal");
    
	local percent = nil
	local percentNum = nil
	for i = 1,#thisActivityInfo.stageCfg do
		if thisActivityInfo.stageCfg[i].stage == SaveServerData.stage then
			percent = SaveServerData.progress.."/"..thisActivityInfo.stageCfg[i].totalProgress;
            percentNum =SaveServerData.progress / thisActivityInfo.stageCfg[i].totalProgress  * 100;
			percentNum = math.floor( percentNum );
			_StageId = i;
			break;
		end
	end
	local addFillGold = thisActivityInfo.activityCfg[SaveServerData.id].consumeGold * (thisActivityInfo.stageCfg[_StageId].totalProgress-SaveServerData.progress)
    NodeHelper:setStringForLabel(self.container,{mGirlsMeetRate = common:getLanguageString('@GirlsMeetCurrentRate'..SaveServerData.stage,percent)});--显示阶段和进度
    NodeHelper:setStringForLabel(self.container,{mDiamondText = addFillGold});--common:getLanguageString('@GirlsMeetCurrentRate',"40%")
    NodeHelper:setStringForLabel(self.container,{mTalk1 = common:getLanguageString(thisActivityInfo.activityCfg[SaveServerData.id].describe)});
    self:showRoleSpine();
    self:addProgressUI(percentNum);
    local isFree = false;
    local itemObj = thisActivityInfo.activityCfg[SaveServerData.id].consumeItems[1]
    local haveNum = UserItemManager:getCountByItemId(itemObj.itemId);
    self:setItemNumber(haveNum);
    if SaveServerData.freeInteractTimes > 0 then--显示免费互动次数
    	NodeHelper:setNodeVisible(self.container:getVarNode("mGirlsMeetFreeTimes"), true)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mItemCostNode"), false)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mDiamondCostNode"), false)
        NodeHelper:setStringForLabel(self.container,{mGirlsMeetFreeTimes = common:getLanguageString('@GirlsMeetFreeTimes',SaveServerData.freeInteractTimes.."/"..thisActivityInfo.activityCfg[SaveServerData.id].freeCount)});--@GirlsMeetFreeTimes common:getLanguageString('@ACTTLGirlsCareInfo',msg.flower)
    elseif haveNum >= itemObj.count then--显示道具
    	NodeHelper:setNodeVisible(self.container:getVarNode("mGirlsMeetFreeTimes"), false)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mItemCostNode"), true)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mDiamondCostNode"), false)
        NodeHelper:setStringForLabel(self.container,{mIconCostNum = itemObj.count});
    else--显示金币
    	NodeHelper:setNodeVisible(self.container:getVarNode("mGirlsMeetFreeTimes"), false)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mItemCostNode"), false)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mDiamondCostNode"), true)
        NodeHelper:setStringForLabel(self.container,{mDiamondCostNum = thisActivityInfo.activityCfg[SaveServerData.id].consumeGold});
    end

    --少女的免费刷新次数
    if SaveServerData.freeRefreshTimes > 0 then
        NodeHelper:setNodeVisible(self.container:getVarNode("mCostNodeVar"), false)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mFreeText"), true)
        NodeHelper:setStringForLabel(self.container,{mFreeText = common:getLanguageString('@GirlsMeetFree1Text',SaveServerData.freeRefreshTimes)});
    else
        NodeHelper:setNodeVisible(self.container:getVarNode("mCostNodeVar"), true)
    	NodeHelper:setNodeVisible(self.container:getVarNode("mFreeText"), false)
        NodeHelper:setStringForLabel(self.container,{mCostNum = thisActivityInfo.activityCfg[SaveServerData.id].refreshConsumeGold});
    end
end

--添加SPINE动画
function TimeLimitMaidenEncounterPage:showRoleSpine()
    local heroNode = self.container:getVarNode("mSpineNode")
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width,height =  visibleSize.width ,visibleSize.height
        local rate = visibleSize.height/visibleSize.width
        local desighRate = 1280/720
        rate = rate / desighRate
        heroNode:removeAllChildren()
        local spine = nil

        local roldData = ConfigManager.getRoleCfg()[thisActivityInfo.activityCfg[SaveServerData.id].spineId]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        spine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(spine, "CCNode")
        heroNode:addChild(spineNode)
        spine:runAnimation(1, "Stand", -1)
    end 
end

--显示当前的进度
function TimeLimitMaidenEncounterPage:addProgressUI(percentNum)
	if not isCreateProgress then
		isCreateProgress = true;
		local mExpBar = self.container:getVarNode("mProgress")
		local sprite = CCSprite:create("UI/Common/Activity/Act_TL_GirlsMeet/Act_TL_GirlsMeet_Icon_8.png")
		_ProgressTimerNode = CCProgressTimer:create(sprite)
		_ProgressTimerNode:setType(kCCProgressTimerTypeBar)
		_ProgressTimerNode:setMidpoint(CCPointMake(0, 0))
        -- _ProgressTimerNode:setScale(1.3)
		_ProgressTimerNode:setBarChangeRate(CCPointMake(0, 1))
		_ProgressTimerNode:setAnchorPoint(ccp(0.5,0))
		mExpBar:addChild(_ProgressTimerNode)
		_ProgressTimerNode:setPercentage(100)--percentNum翔哥改的2017-8-2
	else
		_ProgressTimerNode:setPercentage(100)--percentNum翔哥改的2017-8-2
	end
end

--点击少女刷新回调
function TimeLimitMaidenEncounterPage:onRefreshGirls()
	if SaveServerData.isShow then --展示阶段
		MessageBoxPage:Msg_Box_Lan("@GhostEndExhibition")
		return
	end
	_isRefreshFlag = true;
    local needGold = thisActivityInfo.activityCfg[SaveServerData.id].refreshConsumeGold
	if SaveServerData.freeRefreshTimes ~= nil and SaveServerData.freeRefreshTimes > 0 then
		if SaveServerData.progress > 0 then
			self:rechargePageFlag('@GirlsMeetUpdatePromptTitle','@GirlsMeetUpdatePrompt',-1,RequestNumber.refreshMaiden);
		else
			self:requestServerData(RequestNumber.refreshMaiden);
		end
	elseif UserInfo.playerInfo.gold < needGold then
		self:rechargePageFlag('@HintTitle','@LackGold',needGold,RequestNumber.refreshMaiden);
	elseif SaveServerData.progress > 0  then
    	self:rechargePageFlag('@GirlsMeetUpdatePromptTitle','@GirlsMeetUpdatePrompt',-1,RequestNumber.refreshMaiden);
    else
    	self:requestServerData(RequestNumber.refreshMaiden);
	end
end

function TimeLimitMaidenEncounterPage:setTipsWords()
	if SaveServerData.id ~= nil then
		local mType = thisActivityInfo.activityCfg[SaveServerData.id].type;
		if ItemType.common == mType then--显示少女
			MessageBoxPage:Msg_Box_Lan("@GirlsMeetRefreshSuccess")
		elseif ItemType.devil == mType then--显示女巫
			MessageBoxPage:Msg_Box_Lan("@GirlsMeetDriveSuccess")
		end
	end
	_isRefreshFlag = false;
end

--点击少女刷加满回调
function TimeLimitMaidenEncounterPage:onDiamond()
	if SaveServerData.isShow then --展示阶段
		MessageBoxPage:Msg_Box_Lan("@GhostEndExhibition")
		return
	end
	local addFillGold = thisActivityInfo.activityCfg[SaveServerData.id].consumeGold * (thisActivityInfo.stageCfg[_StageId].totalProgress-SaveServerData.progress)
	self:rechargePageFlag('@GirlsMeetTopupPromptTitle','@GirlsMeetTopupPrompt',addFillGold,RequestNumber.addFill,true);
end

function TimeLimitMaidenEncounterPage:rechargePageFlag(titleDic,descDic,needGold,messageNumber,isConcat)
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
		    		libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","ActivityFairyBless_enter_rechargePage")
					PageManager.pushPage("RechargePage");
		    	end
		   	end
		end
	)
end

function TimeLimitMaidenEncounterPage:onReceiveMessage(eventName, container)
     TimeLimitMaidenEncounterPage:updateGold()
end

function TimeLimitMaidenEncounterPage:onExecute(ParentContainer)
	self:onTimer()
end

function TimeLimitMaidenEncounterPage:onPreview(container)
	PageManager.pushPage("MaidenEncounterAwardPreviewPage");
end

function TimeLimitMaidenEncounterPage:onDevilClick(container)
	if SaveServerData.isShow then --展示阶段
		MessageBoxPage:Msg_Box_Lan("@GhostEndExhibition")
		return
	end
	_isRefreshFlag = true;
	self:onRequestData();
end

function TimeLimitMaidenEncounterPage:onClick(container)
	if SaveServerData.isShow then --展示阶段
		MessageBoxPage:Msg_Box_Lan("@GhostEndExhibition")
		return
	end
	_isRefreshFlag = false;
	self:onRequestData();
end

--点击少女互动和恶魔驱赶回调
function TimeLimitMaidenEncounterPage:onRequestData(container)
	
    local mType = thisActivityInfo.activityCfg[SaveServerData.id].type;
	if ItemType.common == mType then--显示少女点击动画
		self.container:runAnimation("Normal_btnPush");
	else--显示女巫点击动画
		self.container:runAnimation("Devil_btnPush");
	end

	local itemObj = thisActivityInfo.activityCfg[SaveServerData.id].consumeItems[1]
    local haveNum = UserItemManager:getCountByItemId(itemObj.itemId);
    local needGold = thisActivityInfo.activityCfg[SaveServerData.id].consumeGold
	if SaveServerData.freeInteractTimes ~= nil and SaveServerData.freeInteractTimes > 0 then
		self:requestServerData(RequestNumber.interact);
	elseif haveNum >= itemObj.count or UserInfo.playerInfo.gold >= needGold then
		self:requestServerData(RequestNumber.interact);
	else
    	self:rechargePageFlag('@HintTitle','@LackGold',needGold,RequestNumber.interact);
	end
end

function TimeLimitMaidenEncounterPage:onChange(container)
    PageManager.pushPage("MaidenEncounterItemExchangePage");
end

function TimeLimitMaidenEncounterPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_MAIDEN_ENCOUNTER)
end

function TimeLimitMaidenEncounterPage:analysisServerData(msg)
	if _isRefreshFlag then
		self:setTipsWords();
	end
    SaveServerData = {};
	--增加展示期 isShow ：  false活动阶段   true展示阶段
	SaveServerData.isShow = msg.isShow;
	WitchLeaveRequestDataFlag = false;
	SaveServerData.id = msg.id;--唯一ID
	SaveServerData.remainderTime = msg.remainderTime;--活动剩余时间
	SaveServerData.freeInteractTimes = 0;
	SaveServerData.freeRefreshTimes = 0;
	SaveServerData.progress = nil;
	SaveServerData.stage = nil;
	SaveServerData.devilRefreshTime = nil;

	if msg:HasField("freeInteractTimes") then--剩余免费互动次数  少女有
		SaveServerData.freeInteractTimes = msg.freeInteractTimes;
	end

	if msg:HasField("freeRefreshTimes") then--剩余免费刷新次数  少女有
		SaveServerData.freeRefreshTimes = msg.freeRefreshTimes;
	end

	--1）红点:只有在有免费互动次数的时候有红点  
	if SaveServerData.freeInteractTimes <= 0 then
		ActivityInfo.changeActivityNotice(104)--隐藏红点
	end

	if msg:HasField("progress") then--当前互动进度  少女有
		SaveServerData.progress = msg.progress;
	end

	if msg:HasField("stage") then--当前互动阶段  少女有
		SaveServerData.stage = msg.stage;
	end

	self:removeDevilTime();
	SaveServerData.devilRefreshTime = nil;--每次初始化一下时间
	if msg:HasField("devilRefreshTime") then--恶魔刷新时间,只有恶魔有
		SaveServerData.devilRefreshTime = msg.devilRefreshTime;
		TimeLimitMaidenEncounterPage.timeNameWitch = "showDevilTimeName"
	end
	self:refreshPage(SaveServerData.id);
	
    if SaveServerData.isShow then --展示阶段
         TimeLimitMaidenEncounterPage:onChange();
         local endStr = common:getLanguageString("@ActivityEnd");
         TimeLimitMaidenEncounterPage.RemainTime = 0;
         NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})
    else
    	self:onChangeTimes(SaveServerData.remainderTime);
	end
end

--计算倒计时
function TimeLimitMaidenEncounterPage:onTimer()
	if not TimeCalculator:getInstance():hasKey(self.timerName) then
	    if TimeLimitMaidenEncounterPage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif TimeLimitMaidenEncounterPage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime <= 0 and WitchLeaveRequestDataFlag == false then --倒计时完毕重新请求
	 	WitchLeaveRequestDataFlag = true;--防止不断请求
	 	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	 	self:removeDevilTime();
	 	NodeHelper:setStringForLabel(self.container, { mDevilTime = ""});
	 	self:requestServerData(RequestNumber.syncServerData);
	 	return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr});

	------------------恶魔离开的倒计时--------------
	if TimeLimitMaidenEncounterPage.timeNameWitch == "" or SaveServerData.devilRefreshTime == nil or not TimeCalculator:getInstance():hasKey(TimeLimitMaidenEncounterPage.timeNameWitch) then
		return;
	end

	if TimeLimitMaidenEncounterPage.timeNameWitch ~= "" and TimeCalculator:getInstance():hasKey(TimeLimitMaidenEncounterPage.timeNameWitch) then--判断是否有女巫的时间
		remainTime = TimeCalculator:getInstance():getTimeLeft(TimeLimitMaidenEncounterPage.timeNameWitch);
		if remainTime <= 0 and WitchLeaveRequestDataFlag == false then --倒计时完毕重新请求
		 	WitchLeaveRequestDataFlag = true;--防止不断请求
		 	self:removeDevilTime();
		 	NodeHelper:setStringForLabel(self.container, { mDevilTime = ""});
		 	self:requestServerData(RequestNumber.syncServerData);
		end
		timeStr = common:second2DateString(remainTime, false);
		NodeHelper:setStringForLabel(self.container, { mDevilTime = common:getLanguageString('@GirlsMeetDevilTime',timeStr)});
	else
		NodeHelper:setStringForLabel(self.container, { mDevilTime = ""});
	end
end

function TimeLimitMaidenEncounterPage.onRefreshItemView(container)
	
end


function TimeLimitMaidenEncounterPage:requestServerData(type)
	local msg = Activity2_pb.SyncMaidenEncounterReq();
	msg.type = type;
	common:sendPacket(opcodes.SYNC_MAIDEN_ENCOUNTER_C, msg, true);
end

function TimeLimitMaidenEncounterPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.SYNC_MAIDEN_ENCOUNTER_S then
		local msg = Activity2_pb.SyncMaidenEncounterRes();
		msg:ParseFromString(msgBuff);
		self:analysisServerData(msg);
    end
end

function TimeLimitMaidenEncounterPage:onChangeTimes(times)
	TimeLimitMaidenEncounterPage.RemainTime = times;
	if TimeLimitMaidenEncounterPage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TimeLimitMaidenEncounterPage.RemainTime)
	end
	if TimeLimitMaidenEncounterPage.timeNameWitch ~= "" and SaveServerData.devilRefreshTime and SaveServerData.devilRefreshTime > 0 then--判断是否有女巫的时间
		if not TimeCalculator:getInstance():hasKey(TimeLimitMaidenEncounterPage.timeNameWitch) then
			TimeCalculator:getInstance():createTimeCalcultor(TimeLimitMaidenEncounterPage.timeNameWitch, SaveServerData.devilRefreshTime)
		end
	end
end

function TimeLimitMaidenEncounterPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function TimeLimitMaidenEncounterPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function TimeLimitMaidenEncounterPage:removeDevilTime()
	if TimeLimitMaidenEncounterPage.timeNameWitch ~= "" then--如果之前有时间，去掉
		TimeCalculator:getInstance():removeTimeCalcultor(TimeLimitMaidenEncounterPage.timeNameWitch);
		TimeLimitMaidenEncounterPage.timeNameWitch = ""
	end
end

function TimeLimitMaidenEncounterPage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
 	self:removePacket(ParentContainer);
 	self:removeDevilTime();
	onUnload(thisPageName, self.container);
end

return TimeLimitMaidenEncounterPage
