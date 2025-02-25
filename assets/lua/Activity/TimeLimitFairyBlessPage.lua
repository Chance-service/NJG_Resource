
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local Activity2_pb = require("Activity2_pb")
local UserItemManager = require("Item.UserItemManager")
local HP_pb = require("HP_pb");
local thisPageName = 'TimeLimitFairyBlessPage'
local TimeLimitFairyBlessPage = {}
local thisActivityInfo = {}

----------------scrollview-------------------------

local ItemType = {
	common = 3,--普通
	middleRank = 2,--中级
	high = 1--高级
}

local SaveServerData = {}

local opcodes = {
	SYNC_FAIRY_BLESS_C = HP_pb.SYNC_FAIRY_BLESS_C,
	SYNC_FAIRY_BLESS_S = HP_pb.SYNC_FAIRY_BLESS_S,
	FAIRY_BLESS_C 	 = HP_pb.FAIRY_BLESS_C,
};

TimeLimitFairyBlessPage.timerName = "syncServerTimesFairyBless";
TimeLimitFairyBlessPage.RemainTime = -1;

--修改item的信息  index 1代表 第一个按钮  2 第二个按钮   3  第三个按钮
function TimeLimitFairyBlessPage:onChangeUIData(container,index,cfg)
	local lb2Str = {};
    local sprite2Img = {};
    local scaleMap = {}
    local menu2Quality = {};
	local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count);
    sprite2Img["mPic" .. index]         = resInfo.icon;
    sprite2Img["mFrameShade" .. index]   = NodeHelper:getImageBgByQuality(resInfo.quality);
    lb2Str["mNum" .. index]          = "x" .. GameUtil:formatNumber( cfg.count );
    menu2Quality["mFrame" .. index]     = resInfo.quality
    NodeHelper:setSpriteImage(container, sprite2Img);
    NodeHelper:setQualityFrames(container, menu2Quality);
    NodeHelper:setStringForLabel(container, lb2Str);
    if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
        NodeHelper:setNodeScale(container, "mPic" .. index, 0.84, 0.84)
    else
        NodeHelper:setNodeScale(container, "mPic" .. index, 1, 1)
    end
end

--读取配置文件信息
function TimeLimitFairyBlessPage:getReadTxtInfo()
	local list = ConfigManager.getFairyBlessCfg()
	thisActivityInfo.activityCfg = {}
	for i = 1,#list do
		thisActivityInfo.activityCfg[list[i].type] = list[i];--以类型作为索引值
	end
end
function TimeLimitFairyBlessPage:onEnter(ParentContainer)
	self:getReadTxtInfo()
	local container = ScriptContentBase:create("Act_TimeLimitGirlsCareContent.ccbi")
	self.container = container
	self:registerPacket(ParentContainer);
	NodeHelper:initScrollView(self.container, "mContent", 7)
	self.container:registerFunctionHandler(TimeLimitFairyBlessPage.onFunction)
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
	NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"),0.5)
 --    local lb2Str = {};
	-- lb2Str["mTimeInfo1"] = common:getLanguageString('@ACTTLGirlsCareProgressTxt1')
	-- lb2Str["mTimeInfo2"] = common:getLanguageString('@ACTTLGirlsCareProgressTxt2')
	-- lb2Str["mTimeInfo3"] = common:getLanguageString('@ACTTLGirlsCareProgressTxt3')
	-- NodeHelper:setStringForLabel(self.container, lb2Str);
	common:sendEmptyPacket(opcodes.SYNC_FAIRY_BLESS_C , true)
	ActivityInfo.changeActivityNotice(103)--隐藏红点
	-- self:refreshPage()
	-- self:showRoleSpine(container)
	return self.container
end

--添加SPINE动画
function TimeLimitFairyBlessPage:showRoleSpine(container)
    local heroNode = container:getVarNode("mSpineNode")
    if heroNode then
        local visibleSize = CCEGLView:sharedOpenGLView():getFrameSize()
        local width,height =  visibleSize.width ,visibleSize.height
        local rate = visibleSize.height/visibleSize.width
        local desighRate = 1280/720
        rate = rate / desighRate
        heroNode:removeAllChildren()
        local spine = nil

        local roldData = ConfigManager.getRoleCfg()[123]
        local spinePath, spineName = unpack(common:split((roldData.spine), ","))
        
        spine = SpineContainer:create(spinePath, spineName)
        local spineNode = tolua.cast(spine, "CCNode")
        heroNode:addChild(spineNode)
        heroNode:setScale(rate)
        spine:runAnimation(1, "Stand", -1)
        -- local deviceHeight = CCDirector:sharedDirector():getWinSize().height
        -- if deviceHeight < 900 then --ipad change spine position
        --     NodeHelper:autoAdjustResetNodePosition(spineNode,-0.3)  
        -- end
    end 
end

function TimeLimitFairyBlessPage.onFunction(eventName,container)
	if eventName == "onPreview" then
		TimeLimitFairyBlessPage:onPreview(container)
	elseif eventName == "luaRefreshItemView" then
	elseif string.sub(eventName,1,6) == "onFree" then
		TimeLimitFairyBlessPage:onFreeCallback(eventName, container)
	end
end

function TimeLimitFairyBlessPage:refreshPage(msg)
	SaveServerData.flower = msg.flower
	SaveServerData.fairyBlessInfo = msg.fairyBlessInfo
	TimeLimitFairyBlessPage:updateGold()
	NodeHelper:setStringForLabel(self.container, { mActDouble = common:getLanguageString('@ACTTLGirlsCareInfo',msg.flower) });
	-- local lb2Str = {};
	-- local list = msg.fairyBlessInfo
	-- for i = 1,#list do
	-- 	lb2Str["mTimes"..list[i].type] = list[i].progress.."/"..thisActivityInfo.activityCfg[list[i].type].totalProgress;
	-- end
	-- NodeHelper:setStringForLabel(self.container, lb2Str);
	self:onChangeTimes(msg.leftTime);
end

function TimeLimitFairyBlessPage:updateGold()
    NodeHelper:setStringForLabel(self.container, { mDiamondNum = UserInfo.playerInfo.gold });
end

function TimeLimitFairyBlessPage:onExecute(ParentContainer)
	self:onTimer(self.container)
end

function TimeLimitFairyBlessPage:onPreview(container)
	PageManager.pushPage("FairyBlessAwardShowPage")
end
function TimeLimitFairyBlessPage:onReceiveMessage(eventName, container)
     TimeLimitFairyBlessPage:updateGold()
     common:sendEmptyPacket(opcodes.SYNC_FAIRY_BLESS_C , true)
end
function TimeLimitFairyBlessPage:onFreeCallback(eventName, container)
	local index = tonumber(eventName:sub(7))
	CCLuaLog("onFree --------------------- :"..eventName);
	if SaveServerData.flower >= thisActivityInfo.activityCfg[index].costFlower then--鲜花足够
		local msg = Activity2_pb.FairyBlessReq();
		-- 由于表里面的数据是从高级到低级排序，
		msg.type = thisActivityInfo.activityCfg[index].type;--配表的类型
		common:sendPacket(opcodes.FAIRY_BLESS_C, msg, false);
	else
		local title = common:getLanguageString('@LackofflowersTitle')
		local message = common:getLanguageString('@Lackofflowers')
		PageManager.showConfirm(title, message,
			function (agree)
			    if agree then
			    	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","ActivityFairyBless_enter_rechargePage")
					PageManager.pushPage("RechargePage");
			    	PageManager.popPage(thisPageName)
			   	end
			end
		)
	end
end

--计算倒计时
function TimeLimitFairyBlessPage:onTimer(container)
	if not TimeCalculator:getInstance():hasKey(self.timerName) then
	    if TimeLimitFairyBlessPage.RemainTime == 0 then
	        local endStr = common:getLanguageString("@ActivityEnd");
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = endStr})	
	    elseif TimeLimitFairyBlessPage.RemainTime < 0 then
	        NodeHelper:setStringForLabel(self.container,{mTanabataCD = ""})	
        end
        return; 
    end

	local remainTime = TimeCalculator:getInstance():getTimeLeft(self.timerName);
	if remainTime + 1 > TimeLimitFairyBlessPage.RemainTime then
		return;
	end
	local timeStr = common:second2DateString(remainTime, false);
	NodeHelper:setStringForLabel(container, { mTanabataCD = timeStr});
end

function TimeLimitFairyBlessPage.onRefreshItemView(container)
	
end

function TimeLimitFairyBlessPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode()
	local msgBuff = ParentContainer:getRecPacketBuffer()
    if opcode == HP_pb.SYNC_FAIRY_BLESS_S then
		local msg = Activity2_pb.SyncFairyBlessRes();
		msg:ParseFromString(msgBuff);
		self:refreshPage(msg);
    end
end

function TimeLimitFairyBlessPage:onChangeTimes(times)
	TimeLimitFairyBlessPage.RemainTime = times;
	if TimeLimitFairyBlessPage.RemainTime > 0 and not TimeCalculator:getInstance():hasKey(self.timerName) then
		TimeCalculator:getInstance():createTimeCalcultor(self.timerName, TimeLimitFairyBlessPage.RemainTime)
	end
end

function TimeLimitFairyBlessPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function TimeLimitFairyBlessPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end

function TimeLimitFairyBlessPage:onExit(ParentContainer)
	TimeCalculator:getInstance():removeTimeCalcultor(self.timerName);
 	self:removePacket(ParentContainer);
 	NodeHelper:deleteScrollView(self.container);
 	SaveServerData = {}
	onUnload(thisPageName, self.container);
end

return TimeLimitFairyBlessPage
