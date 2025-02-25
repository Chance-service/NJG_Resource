----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local UserItemManager = require("Item.UserItemManager");
local UserMercenaryManager = require("UserMercenaryManager")
local ActivityDialogConfig = require("Activity.ActivityDialogConfig");
local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb");
local thisPageName = 'HalloweenMainPage'
local HalloweenMainPage = {}
local thisActivityInfo = {}
local _GetIndex = nil;--当前显示阶段的ID

local MercenaryRoleInfos = {} -- 佣兵碎片数据包

local _IsFirstOnenterFlag = false;
local _IsClickBtnFlag = false;
local MercenaryCfg = nil;
local MercenaryId = nil;
----------------scrollview-------------------------
-- 0：同步 1：单次抽奖和免费 2：10次抽奖 3：兑换
local RequestNumber = {
	syncServerData = 0,--第一次请求
	requestProgress = 1, --单次抽奖和免费 
	tenRewards = 2, --10次抽奖
	receiveExchange = 3, --兑换
}

local SaveServerData = {}
local SaveRedPointData = {}

local opcodes = {
	HALLOWEEN_C = HP_pb.HALLOWEEN_C,
	HALLOWEEN_S = HP_pb.HALLOWEEN_S,
	ROLE_PANEL_INFOS_C = HP_pb.ROLE_PANEL_INFOS_C,
    ROLE_PANEL_INFOS_S = HP_pb.ROLE_PANEL_INFOS_S
};

HalloweenMainPage.timerName = "syncServerActivityTimes";
HalloweenMainPage.RemainTime = -1;

--重置数据
function HalloweenMainPage:resetData()
	SaveServerData = {};
	thisActivityInfo = {}
	HalloweenMainPage.RemainTime = -1;
	_GetIndex = 0;
	_ProgressTimerNode = nil -- 进度条
    math.randomseed(os.time());
    MercenaryCfg = ConfigManager.getRoleCfg()
    SaveRedPointData = {}
    SaveRedPointData.RedPoint = {}
    SaveRedPointData.IsChange = {}
    SaveRedPointData.SaveRedPointState = {}
    SaveRedPointData.GetRedPointState = {}
    for i = 1, 3 do
    	SaveRedPointData.RedPoint[i] = true
    	SaveRedPointData.IsChange[i] = false
    	SaveRedPointData.SaveRedPointState[i] = false
    end
    MercenaryId = nil
    _IsClickBtnFlag = false;
    _IsFirstOnenterFlag = false;
end

--读取配置文件信息
function HalloweenMainPage:getReadTxtInfo()
	-- 主页兑换活动配置
    thisActivityInfo.activityCfg = ConfigManager.getHalloweenExchangeDisplayCfg()
	--获取道具ID
	thisActivityInfo.ExhibitionItems = ConfigManager.getHalloweenExhibitionItemsCfg()
end

function HalloweenMainPage:setVisiblesMenu(flag)
	for i = 1, 3 do
		NodeHelper:setMenuItemEnabled( self.container, "mTopBtn"..i, flag);
	end
end

function HalloweenMainPage:onEnter(ParentContainer)
	self:resetData();
	self:getReadTxtInfo()
	self.container = ScriptContentBase:create("Act_TimeLimitHalloweenContent.ccbi")
    self.container:registerFunctionHandler(HalloweenMainPage.onFunction)
	self:registerPacket(ParentContainer);  
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
	--刚进来不让点击
	HalloweenMainPage:setVisiblesMenu(false)
	NodeHelper:setMenuItemEnabled( self.container, "mChangeBtn", false);
	NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
    NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
	NodeHelper:setStringForLabel(self.container, { mLastTime = ""});
	NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""})
    -- self:initDataTest();--测试使用
    self:getNowSelectIndex();
    self:requestServerData(RequestNumber.syncServerData);
	return self.container
end

--添加SPINE动画
function HalloweenMainPage:showRoleSpine()
	local spineId = thisActivityInfo.activityCfg[_GetIndex].spineId
	if spineId == MercenaryId then
		return;
	end
	MercenaryId = spineId
    local heroNode = self.container:getVarNode("mSpine")
    local m_NowSpine = nil
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width,height =  visibleSize.width ,visibleSize.height
        local rate = visibleSize.height/visibleSize.width
        local desighRate = 1280/720
        rate = rate / desighRate
        heroNode:removeAllChildren()
        
        local roldData = ConfigManager.getRoleCfg()[MercenaryId]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        m_NowSpine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(m_NowSpine, "CCNode")  
        --heroNode:setScale(rate)
        heroNode:addChild(spineNode)
		m_NowSpine:runAnimation(1, "Stand", -1)
        -- local deviceHeight = CCDirector:sharedDirector():getWinSize().height
        -- if deviceHeight < 900 then --ipad change spine position
        --     NodeHelper:autoAdjustResetNodePosition(spineNode,-0.3)  
        -- end
    end
    HalloweenMainPage:updateMercenaryNumber()
end

function HalloweenMainPage.onFunction(eventName,container)
	if eventName == "onChangeBtn" then
		HalloweenMainPage:onChangeBtn(container)
	elseif eventName == "onRewardPreview" then
		HalloweenMainPage:onRewardPreview();
    elseif eventName == "onSearchOnce" then
    	HalloweenMainPage:onFree();
    elseif eventName == "onSearchTen" then
    	HalloweenMainPage:onDiamond();
    elseif eventName == "onIllustatedOpen" then
        HalloweenMainPage:onIllustatedOpen()
	elseif eventName:sub(1, 7) == "onFrame" then
		HalloweenMainPage:onHand(container,eventName);
	elseif eventName:sub(1, 11) == "onBtnChoose" then
		HalloweenMainPage:onBtnChoose(container,eventName);
	end
end

function HalloweenMainPage:getNowSelectIndex()
	local saveDialogStatus = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "HalloweenMainPage";
	local dialogStatus = CCUserDefault:sharedUserDefault():getStringForKey(saveDialogStatus);--保存当前的阶段，判断是否更新
	if not dialogStatus or dialogStatus == "" then--如果没有弹出过，则弹出对话
		_GetIndex = 3;
	else
		_GetIndex = tonumber(dialogStatus);
	end
	for i = 1, 3 do
		saveDialogStatus  = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "HalloweenMainPage_OnChooseBtnRedPoint_"..i;
		dialogStatus = CCUserDefault:sharedUserDefault():getStringForKey(saveDialogStatus);
		if not dialogStatus or dialogStatus == ""  then
			SaveRedPointData.GetRedPointState[i] = nil
		else
			if dialogStatus == "true" then
				SaveRedPointData.GetRedPointState[i] = true
			else
				SaveRedPointData.GetRedPointState[i] = false
			end
		end
	end
end

function HalloweenMainPage:updateRedPoint(index)
	SaveRedPointData.RedPoint[index] = false
	if not _IsFirstOnenterFlag then
		_IsFirstOnenterFlag = true;
		for i = 1, #thisActivityInfo.activityCfg do
			local isEnough = false
			if SaveRedPointData.GetRedPointState[i] ~= nil then
				isEnough = SaveRedPointData.GetRedPointState[i]
			else
				isEnough = HalloweenMainPage:isEnoughFlag(thisActivityInfo.activityCfg[i].id)
			end
			SaveRedPointData.IsChange[i] = isEnough
			SaveRedPointData.SaveRedPointState[i] = isEnough
			SaveRedPointData.RedPoint[i] = isEnough
			NodeHelper:setNodesVisible(self.container, { ["mNewPoint"..i] = isEnough});
		end
        SaveRedPointData.RedPoint[index] = false
	else
		for i = 1, #thisActivityInfo.activityCfg do
			local isEnough = HalloweenMainPage:isEnoughFlag(thisActivityInfo.activityCfg[i].id)
			if isEnough and _IsClickBtnFlag then--信息有变更
				if isEnough and not SaveRedPointData.IsChange[i] then--如果不是第一次点击
					isEnough = true
				elseif isEnough and SaveRedPointData.IsChange[i] then
					isEnough = SaveRedPointData.RedPoint[i]
				end
			elseif isEnough then
				isEnough = SaveRedPointData.RedPoint[i]
			end
			SaveRedPointData.IsChange[i] = HalloweenMainPage:isEnoughFlag(thisActivityInfo.activityCfg[i].id)
			SaveRedPointData.SaveRedPointState[i] = isEnough
			NodeHelper:setNodesVisible(self.container, { ["mNewPoint"..i] = isEnough});
		end
	end
	SaveRedPointData.SaveRedPointState[index] = false
end

function HalloweenMainPage:onRewardPreview( container )
	require("NewSnowPreviewRewardPage")
    if not thisActivityInfo.LookReward then
    	-- 查看奖励配置
		thisActivityInfo.LookReward = ConfigManager.getHalloweenLookRewardCfg()
    end
    local commonRewardItems = {}
    local luckyRewardItems = {}
    if thisActivityInfo.LookReward ~= nil then
        for _, item in ipairs(thisActivityInfo.LookReward) do
            if item.type == 1 then
                table.insert(commonRewardItems, {
                    type    = tonumber(item.rewards[1].type),
                    itemId  = tonumber(item.rewards[1].itemId),
                    count   = tonumber(item.rewards[1].count)
                });
            else
                table.insert(luckyRewardItems, {
                    type    = tonumber(item.rewards[1].type),
                    itemId  = tonumber(item.rewards[1].itemId),
                    count   = tonumber(item.rewards[1].count)
                });
            end
        end
    end		
	NewSnowPreviewRewardPage_SetConfig(luckyRewardItems, commonRewardItems, "@HalloweenRewardPreviewTxt1", "@HalloweenRewardPreviewTxt2", "HelpHalloween")
	PageManager.pushPage("NewSnowPreviewRewardPage")
end

function HalloweenMainPage:initMainPagePic(selectId)
	local cfg = {};
    local lb2Str = {};
    local sprite2Img = {};
    local menu2Quality = {};
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1
    for i = 1, #thisActivityInfo.activityCfg do
        cfg = thisActivityInfo.activityCfg[i]
        if cfg.id == selectId then--改变数据
        	break;
        end
    end

    for i = 1, 4 do
        local reward = cfg.rewards[i]
        if reward then--改变数据
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(reward.type, reward.itemId, reward.count);
            sprite2Img["mPic" .. i]         = resInfo.icon;
            sprite2Img["mFrameShade".. i]   = NodeHelper:getImageBgByQuality(resInfo.quality);
            lb2Str["mNum" .. i]          = "x" .. GameUtil:formatNumber( reward.count );
            lb2Str["mName" .. i]            = resInfo.name;
            menu2Quality["mFrame" .. i]      = resInfo.quality
            NodeHelper:setSpriteImage(self.container, sprite2Img);
            NodeHelper:setQualityFrames(self.container, menu2Quality);
            NodeHelper:setStringForLabel(self.container, lb2Str);
            if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
                NodeHelper:setNodeScale(self.container, "mPic" .. i, 1, 1)
            else
                NodeHelper:setNodeScale(self.container, "mPic" .. i, 1, 1)
            end
            NodeHelper:setNodesVisible(self.container, { ["mRewardNode"..i] = true});
        else
        	NodeHelper:setNodesVisible(self.container, { ["mRewardNode"..i] = false});
        end
    end

    for i = 1, 2 do
    	local consumeItems = cfg.consume[i]
    	if consumeItems then--mCostIcon mCostNum
    		local haveNum = UserItemManager:getCountByItemId(cfg.consume[i].itemId);
    		NodeHelper:setStringForLabel(self.container, { ["mCostNum"..i] = "x"..consumeItems.count });
   			NodeHelper:setSpriteImage(self.container, {["mCostIcon"..i] = "BG/Activity_109/I_"..consumeItems.itemId..".png" });
    		NodeHelper:setNodesVisible(self.container, { ["mCostNode"..i] = true});
    		if haveNum >= consumeItems.count then
    			NodeHelper:setColorForLabel(self.container,{ ["mCostNum"..i] = "155,92,78"--[[GameConfig.ColorMap.COLOR_BROWN]]})
    		else
    			NodeHelper:setColorForLabel(self.container,{ ["mCostNum"..i] = GameConfig.ColorMap.COLOR_RED})
    		end
    	else
    		NodeHelper:setNodesVisible(self.container, { ["mCostNode"..i] = false});
    	end
    end
    if cfg.times == 0 then
    	NodeHelper:setStringForLabel(self.container, { mChangeLimit = "" });
    else
    	for i = 1,#SaveServerData.HalloweenExchangeInfo do
	    	if SaveServerData.HalloweenExchangeInfo[i].id == selectId then
	    		local times = cfg.times - SaveServerData.HalloweenExchangeInfo[i].exchangeTimes
	    		NodeHelper:setStringForLabel(self.container, { mChangeLimit = SaveServerData.HalloweenExchangeInfo[i].exchangeTimes.."/"..cfg.times });
	    		if times > 0 then
	    			NodeHelper:setColorForLabel(self.container,{ mChangeLimit = "155,92,78"})
	    		else
	    			NodeHelper:setColorForLabel(self.container,{ mChangeLimit = GameConfig.ColorMap.COLOR_RED})
	    		end
	    		break;
	    	end
	    end
	end
	local isBtnFlag = HalloweenMainPage:isEnoughFlag(selectId)
	NodeHelper:setMenuItemEnabled( self.container, "mChangeBtn", true);
end

--判断道具和次数时候足够
function HalloweenMainPage:isEnoughFlag(selectId)
	local cfg = {};
    for i = 1, #thisActivityInfo.activityCfg do
        cfg = thisActivityInfo.activityCfg[i]
        if cfg.id == selectId then--改变数据
        	break;
        end
    end
	local isItmeEnough = true
    --判断道具是否足够
    for i = 1,#cfg.consume do
    	local haveNum = UserItemManager:getCountByItemId(cfg.consume[i].itemId);
    	if haveNum < cfg.consume[i].count then
    		isItmeEnough = false
    		break;
    	end
    end
    local isBtnFlag = true;
    if cfg.times ~= 0 then
    	for i = 1,#SaveServerData.HalloweenExchangeInfo do
	    	if SaveServerData.HalloweenExchangeInfo[i].id == selectId then
	    		local times = cfg.times - SaveServerData.HalloweenExchangeInfo[i].exchangeTimes
	    		if times > 0 then
	    			isBtnFlag = isItmeEnough and true
	    		else
	    			isBtnFlag = false
	    		end
	    		break;
	    	end
	    end
	else
		isBtnFlag = isItmeEnough
	end
	return isBtnFlag
end

function HalloweenMainPage:refreshPage()
	HalloweenMainPage:updateGold()
	if SaveServerData.freeTime == 0 then --有免费次数  KingPalaceFree1Text
		NodeHelper:setStringForLabel(self.container, { mFreeText = common:getLanguageString("@KingPalaceFree1Text")});--多少回必得
        NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false});
        NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
    elseif  SaveServerData.freeTime < 0 then
        NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true});
		NodeHelper:setStringForLabel(self.container, { mCostNum = SaveServerData.oneCostGold });--1回消耗钻石
        NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
	else
		NodeHelper:setNodesVisible(self.container, { mFreeText = false, mCostNodeVar = true});
		NodeHelper:setStringForLabel(self.container, { mCostNum = SaveServerData.oneCostGold });--1回消耗钻石
	end--mOwnNum mOwnIcon
	local lb2Str = {};
	for i = 1,3 do
		local haveNum = UserItemManager:getCountByItemId(thisActivityInfo.ExhibitionItems[i].items[1].itemId);
		lb2Str["mOwnNum" .. i] = ""..haveNum;
	end
	NodeHelper:setStringForLabel(self.container, lb2Str);
	NodeHelper:setStringForLabel(self.container, { mDiamondText = SaveServerData.tenCostGold });--10回消耗钻石
	NodeHelper:setStringForLabel(self.container, { mActDouble = common:getLanguageString("@HalloweenRewardPrompt")});--多少回必得
end

--更新金币
function HalloweenMainPage:updateGold()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

function HalloweenMainPage:onHand(container,eventName)
	if not _IsFirstOnenterFlag then
		return
	end
    local index = tonumber(string.sub(eventName,8,string.len(eventName)))
    local cfg = {};
    --mFrameShade1 mPic1 mHand1 mName1 mNumber1 mGoodsAni1
    for i = 1, #thisActivityInfo.activityCfg do
        cfg = thisActivityInfo.activityCfg[i]
        if cfg.id == _GetIndex then--改变数据
        	break;
        end
    end
    local _type, _id, _count = cfg.rewards[index].type,cfg.rewards[index].itemId,cfg.rewards[index].count;
    local items = {}
    table.insert(items, {
		type 	= tonumber(_type),
		itemId	= tonumber(_id),
		count 	= tonumber(_count)
	});
    GameUtil:showTip(container:getVarNode('mPic'..index), items[1])
end

function HalloweenMainPage:onBtnChoose(container,eventName)
	_IsClickBtnFlag = false;
    local index = tonumber(string.sub(eventName,12,string.len(eventName)))
    if _GetIndex == index then
    	return;
    end
    self:updataUIInfo(index);
end

function HalloweenMainPage:updataUIInfo(index)
	for i = 1, 3 do
    	if i == index then
    		_GetIndex = i
    		NodeHelper:setNodesVisible(self.container, { ["mChoose"..i] = true});
    		HalloweenMainPage:initMainPagePic(i)
    	else
    		NodeHelper:setNodesVisible(self.container, { ["mChoose"..i] = false});
    	end
    end
    HalloweenMainPage:updateRedPoint(index)
    HalloweenMainPage:showRoleSpine()
end

--点击免费次数或者单次的回调
function HalloweenMainPage:onFree()
	--if SaveServerData.freeTime <= 0 or UserItemManager:getCountByItemId(thisActivityInfo.ExhibitionItems[1].items[1].itemId) >= SaveServerData.oneCostGold then
		HalloweenMainPage:requestServerData(RequestNumber.requestProgress);
	--else
	--	HalloweenMainPage:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.oneCostGold,RequestNumber.requestProgress);
	--end
end

--点击十次回调
function HalloweenMainPage:onDiamond()
	--if UserItemManager:getCountByItemId(thisActivityInfo.ExhibitionItems[1].items[1].itemId) >= SaveServerData.tenCostGold then
    	HalloweenMainPage:requestServerData(RequestNumber.tenRewards);
	--else
	--	HalloweenMainPage:rechargePageFlag('@HintTitle','@LackGold',SaveServerData.tenCostGold,RequestNumber.tenRewards);
	--end
end

function HalloweenMainPage:pushRewardPage()
	local data = {};
	data.freeCd = SaveServerData.freeTime;
	data.onceGold = SaveServerData.oneCostGold;
	data.tenGold = SaveServerData.tenCostGold;
	data.itemId = nil;
	data.rewards = SaveServerData.rewards;
	local CommonRewardAni = require("CommonRewardAniPage")
	if not CommonRewardAni:isPop() then
		PageManager.pushPage("CommonRewardAniPage")
		CommonRewardAni:setFirstData(data, data.rewards, HalloweenMainPage.onFree,HalloweenMainPage.onDiamond, 4)
	else
		CommonRewardAni:setFirstData(data, data.rewards, HalloweenMainPage.onFree,HalloweenMainPage.onDiamond, 4, true)
	end
end


function HalloweenMainPage:rechargePageFlag(titleDic,descDic,needGold,messageNumber,isConcat)
	common:rechargePageFlag("HalloweenMainPage")
end

function HalloweenMainPage:onReceiveMessage(eventName, container)
     HalloweenMainPage:updateGold()
end

function HalloweenMainPage:onExecute(ParentContainer)
	self:onTimer()
end

--服务器信息同步
function HalloweenMainPage:analysisServerData(msg)
	SaveServerData.oneCostGold = msg.onceCostGold;--一次消耗的金币
	SaveServerData.tenCostGold = msg.tenCostGold;--10次消耗的金币
	SaveServerData.remainderTime = msg.leftTime;--活动剩余时间134422
	SaveServerData.leftDisplayTime = msg.leftDisplayTime;--活动展示时间134422
	SaveServerData.freeTime = msg.freeCD;--免费的时间
	SaveServerData.freeTimeName = "FreeTimeCD";--免费次数 freeCD
	SaveServerData.HalloweenExchangeInfo = msg.info;--万圣节活动兑换结构体id,exchangeTimes兑换次数
	if SaveServerData.freeTime ~= 0 then
		ActivityInfo.changeActivityNotice(109)--隐藏红点
	end

	----------------更新UI---------------------
	self:refreshPage();
	self:updataUIInfo(_GetIndex);
	if msg.leftTime <= 0 then
		SaveServerData.remainderTime = msg.leftDisplayTime
		local endStr = common:getLanguageString("@ActivityDisplayTime");
	    NodeHelper:setStringForLabel(self.container,{mNowTimeTxt = endStr})
	    NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
    	NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
    	self.container:getVarNode("mRewardNode"):setVisible(false)
	else
		NodeHelper:setMenuItemEnabled( self.container, "mDiamond", true);
    	NodeHelper:setMenuItemEnabled( self.container, "mFree", true);
	end
    --抽奖奖励(只有抽奖的时候才会有)
	if #msg.reward > 0 then
		SaveServerData.rewards = msg.reward
        self:pushRewardPage();
	end
	HalloweenMainPage.RemainTime = SaveServerData.remainderTime;
	self:onChangeTimes();
	HalloweenMainPage:setVisiblesMenu(true)
end

--计算倒计时
function HalloweenMainPage:onTimer()
	--免费CD倒计时
	if SaveServerData.freeTime ~= nil and SaveServerData.freeTime == 0 and TimeCalculator:getInstance():hasKey(SaveServerData.freeTimeName) then--mCostIcon
		TimeCalculator:getInstance():removeTimeCalcultor(SaveServerData.freeTimeName);
		NodeHelper:setStringForLabel(self.container, { mFreeText = common:getLanguageString("@KingPalaceFree1Text")});--多少回必得
        NodeHelper:setNodesVisible(self.container, { mFreeText = true, mCostNodeVar = false});
        NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
    elseif SaveServerData.freeTime ~= nil and SaveServerData.freeTime < 0 and TimeCalculator:getInstance():hasKey(SaveServerData.freeTimeName) then--mCostIcon
        SaveServerData.freeTime = TimeCalculator:getInstance():getTimeLeft(SaveServerData.freeTimeName);
		local timeStr = common:second2DateString(SaveServerData.freeTime, false);
		NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = ""});
	elseif  SaveServerData.freeTime ~= nil and SaveServerData.freeTime > 0 then
		SaveServerData.freeTime = TimeCalculator:getInstance():getTimeLeft(SaveServerData.freeTimeName);
		local timeStr = common:second2DateString(SaveServerData.freeTime, false);
		NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = timeStr});
	end
	--活动时间倒计时
	if HalloweenMainPage.RemainTime == -1 or not TimeCalculator:getInstance():hasKey(self.timerName) then
		return;
	end
	if HalloweenMainPage.RemainTime <= 0 and TimeCalculator:getInstance():hasKey(self.timerName) then
	    if HalloweenMainPage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif HalloweenMainPage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
        HalloweenMainPage.RemainTime = -1;
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime <= 0 then --倒计时完毕重新请求
		HalloweenMainPage.RemainTime = remainTime;
	 	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	 	NodeHelper:setStringForLabel(self.container, { mTanabataCD = ""});
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr});
end

function HalloweenMainPage:requestServerData(type,id,mult)
	if type ~= RequestNumber.syncServerData then
		_IsClickBtnFlag = true;
	end
	local msg = Activity3_pb.HalloweenReq();
	msg.type = type;--0：同步 1：单次抽奖和免费 2：10次抽奖 3：兑换
	if id ~= nil and mult ~= nil then
		msg.exchangeId = id;--兑换配表对应的ID
		msg.multiple = mult;--倍数
	end
	common:sendPacket(opcodes.HALLOWEEN_C, msg, true);
end

--更新佣兵碎片数量
function HalloweenMainPage:updateMercenaryNumber()
	if _GetIndex <= 0 or _GetIndex == nil then
		return
	end
	local spineId = thisActivityInfo.activityCfg[_GetIndex].spineId
	for i = 1,#MercenaryRoleInfos do
        --local curMercenary = UserMercenaryManager:getUserMercenaryById(MercenaryRoleInfos[i].roleId)
		if spineId == MercenaryRoleInfos[i].itemId then
			NodeHelper:setStringForLabel(self.container, { mCoinNum = common:getLanguageString("@HalloweenFragmentNumberTxt",MercenaryCfg[spineId].name) .. MercenaryRoleInfos[i].soulCount.."/"..MercenaryRoleInfos[i].costSoulCount});
			break;
		end
	end
end

function HalloweenMainPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.HALLOWEEN_S then
		local msg = Activity3_pb.HalloweenRes();
		msg:ParseFromString(msgBuff);
		self:analysisServerData(msg);
		common:sendEmptyPacket(HP_pb.ROLE_PANEL_INFOS_C, false)
	elseif opcode == HP_pb.ROLE_PANEL_INFOS_S then
        local msg = RoleOpr_pb.HPRoleInfoRes();
		msg:ParseFromString(msgBuff);
        MercenaryRoleInfos = msg.roleInfos
        HalloweenMainPage:updateMercenaryNumber()
    end
end

function HalloweenMainPage:onChangeTimes()
	--活动剩余时间
	if HalloweenMainPage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, HalloweenMainPage.RemainTime)
	end	
	--免费CD时间
	if SaveServerData.freeTime > 0 and not TimeCalculator:getInstance():hasKey(SaveServerData.freeTimeName) then
		TimeCalculator:getInstance():createTimeCalcultor(SaveServerData.freeTimeName, SaveServerData.freeTime)
	end
end

--兑换
function HalloweenMainPage:onChangeBtn(container)
	for i = 1, #thisActivityInfo.activityCfg do
        local cfg = thisActivityInfo.activityCfg[i]
        if cfg.id == _GetIndex then--改变数据
        	HalloweenMainPage:onBuyTimes(container,cfg)
        	break;
        end
    end
end


function HalloweenMainPage:onBuyTimes(container,cfg)
    -- local max = ScoreExchangePageInfo.surplusScore
    local title = common:getLanguageString("@LoadTreasureTableTitle")
    local message = common:getLanguageString("@ManyPeopleShopGiftInfoTxt")
    local tips = "@NoGemBuyCount"
    local times = 0--次数限制
    local rewards = cfg.rewards[1]--奖励
    local consumeItems = cfg.consume[i]
    local multiple = 1
    local max = 999999
    for i = 1,#SaveServerData.HalloweenExchangeInfo do
    	if SaveServerData.HalloweenExchangeInfo[i].id == cfg.id then
    		times = cfg.times - SaveServerData.HalloweenExchangeInfo[i].exchangeTimes
    		break;
    	end
    end
    local haveNum = UserItemManager:getCountByItemId(cfg.consume[1].itemId);
    local maxNum = math.floor(haveNum / cfg.consume[1].count)
    for i = 1,#cfg.consume do
    	haveNum = UserItemManager:getCountByItemId(cfg.consume[i].itemId);
    	local itemCount = math.floor(haveNum / cfg.consume[i].count)
    	if itemCount < maxNum then
    		maxNum = itemCount
    	end
    end
    if cfg.times == 0 then
    	times = maxNum
    	tips = "@NoGemBuyCount"
    else
    	if times > maxNum then
    		times = maxNum
    		tips = "@TLExchangeNotEnough"
    	end
    end
    local title = common:getLanguageString("@ExchangeCountTitle")
    local message = common:getLanguageString("@SuitPatchNumberTitle")

    PageManager.showCommonCountTimesPage(title,message,times,
        function(count)
            return count*multiple
        end
    ,3, 
    function ( isBuy, count  )
        if isBuy then
            HalloweenMainPage:requestServerData(RequestNumber.receiveExchange,cfg.id,count);
        end
    end, nil, nil, tips, multiple, false)
end

function HalloweenMainPage:onIllustatedOpen(container)
    local FetterManager = require("FetterManager")
    FetterManager.showFetterPage(MercenaryId)
end

function HalloweenMainPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function HalloweenMainPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function HalloweenMainPage:saveNowSelectIndex()
	local saveDialogStatus = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "HalloweenMainPage";
	CCUserDefault:sharedUserDefault():setStringForKey(saveDialogStatus, tostring(_GetIndex));
	for i = 1, 3 do
		saveDialogStatus  = UserInfo.playerInfo.playerId .. UserInfo.serverId .. "HalloweenMainPage_OnChooseBtnRedPoint_"..i;
		local state = SaveRedPointData.SaveRedPointState[i]
		CCUserDefault:sharedUserDefault():setStringForKey(saveDialogStatus, tostring(state));
	end
	CCUserDefault:sharedUserDefault():flush();
end
function HalloweenMainPage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
	TimeCalculator:getInstance():removeTimeCalcultor(SaveServerData.freeTimeName);
 	self:removePacket(ParentContainer);
 	MercenaryCfg = nil;
 	self:saveNowSelectIndex();
	onUnload(thisPageName, self.container);
end

return HalloweenMainPage
