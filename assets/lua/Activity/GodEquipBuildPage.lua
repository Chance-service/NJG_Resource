
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo");
local thisPageName = 'GodEquipBuildPage'
local Activity_pb = require("Activity_pb");
local HP_pb = require("HP_pb");
local GodEquipBuild_pb = require("GodEquipBuild_pb");

local ItemManager = require "Item.ItemManager"
local GodEquipBuildPage = {}
local thisPageNameContainer = nil
local EquipCfg = {}
local GodEquipBuildCfg ={}
local GodEquipContainer = {}--只构建一次scrollview  存储Container
local ReqAnim = 
{
    isSingle = false,
    isFirst = true,
    isAnimationRuning = false,
    showNewReward = {}
}
local GodEquipContent = {
    AllContainer = {},
    --ccbFile = "Act_SuitForgePageContent.ccbi"
    ccbFile = "Act_TimeLimitSuitForgeListContent.ccbi"
}
local opcodes = {
	EQUIP_BUILD_ACT_INFO_C = HP_pb.EQUIP_BUILD_ACT_INFO_C,
	EQUIP_BUILD_ACT_INFO_S = HP_pb.EQUIP_BUILD_ACT_INFO_S,
    EQUIP_BUILD_EVENT_C = HP_pb.EQUIP_BUILD_EVENT_C,
    EQUIP_BUILD_EVENT_S = HP_pb.EQUIP_BUILD_EVENT_S,
}
local option = {
	--ccbiFile = "Act_SuitForgePage.ccbi",
    ccbiFile = "Act_TimeLimitSuitForgeContent.ccbi",
	handlerMap = {
		onReturnButton = "onClose",
        onHelp      = "onHelp",
        onIllustatedOpen = "onIllustatedOpen",
        onBackpackOpen = "onBackpackOpen",
        onReceive   = "onReceive",
		onWishing =  "onWishing",
        onFree = "onFree",
        onDiamond = "onDiamond",
        onRewardPreview = "onRewardPreview"
	},
}
for i = 1,10 do
	option.handlerMap["onHand" ..i] = "onHand";
end

function GodEquipBuildPage.onFunction(eventName,container)
    if eventName == "onSearchOnce" then
        GodEquipBuildPage:onFree(container)
    elseif eventName == "onSearchTen" then
        GodEquipBuildPage:onDiamond(container)
    elseif eventName == "onIllustatedOpen" then
        GodEquipBuildPage:onIllustatedOpen(container)
    elseif eventName == "onBackpackOpen" then
        GodEquipBuildPage:onBackpackOpen(container)
    elseif eventName == "onRewardPreview" then
        GodEquipBuildPage:onRewardPreview(container)
    elseif eventName == "luaOnAnimationDone" then
        GodEquipBuildPage:onAnimationDone(container)
    elseif eventName == "onHand1" then
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand2" then  
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand3" then
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand4" then 
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand5" then
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand6" then 
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand7" then
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand8" then 
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand9" then
        GodEquipBuildPage:onHand(container,eventName)
    elseif eventName == "onHand10" then 
        GodEquipBuildPage:onHand(container,eventName)
    end
end

--当前页面信息
local PageInfo = {
    singleCost = 200,
    tenCost = 1800,
    closeTimes = 200,
    freeTimesCD = 28800,
    allEquip = { },
    freeTimesCDName = "freeTimesCDName",
	timerName = "GodEquipBuildPage",
	timeLeft = 0,
}
local alreadyShowReward = {}--界面上已经显示的奖励
local needShowReward = {}--当前锻造的奖励
local COUNT_LIMIT = 10
local lasttime = 0;--用于计算时间差
------------------------------scrollview-------------------------
function GodEquipContent.onRefreshItemView(container)
	local id = tonumber(container:getItemDate().mID)
    local equipData = PageInfo.allEquip[id]
    local _type, _id, _count = unpack(common:split(equipData.reward, "_"));
    local resInfo = ResManagerForLua:getResInfoByTypeAndId(tonumber(_type), tonumber(_id), tonumber(_count));
    if GodEquipContent.AllContainer[id] == nil then
        GodEquipContent.AllContainer[id] = container
    end
    NodeHelper:setSpriteImage(container,{mPic = resInfo.icon})
    NodeHelper:setMenuItemQuality(container, "mHand", resInfo.quality);
    if equipData.curCount <= 100 then
        NodeHelper:setStringForLabel(container,{mNumber = equipData.curCount.."/"..equipData.allCount});
    else
        NodeHelper:setStringForLabel(container,{mNumber = ""});
    end
end
function GodEquipBuildPage:onClose(container,name)
    PageManager.refreshPage("ActivityPage")
	PageManager.popPage(thisPageName);
    --SimpleAudioEngine:sharedEngine():playEffect("xiangcai.mp3",false);
end
function GodEquipBuildPage:onHelp(container,name)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GODEQUIPBUILD)
end

function GodEquipContent.onHand(container)
    local contentId = container:getItemDate().mID;
    local items = {}
    local _type, _id, _count = unpack(common:split(PageInfo.allEquip[contentId].reward, "_"));
	table.insert(items, {
		type 	= tonumber(_type),
		itemId	= tonumber(_id),
		count 	= tonumber(_count)
	});
    GameUtil:showTip(container:getVarNode('mPic'), items[1])
end
function GodEquipContent.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		GodEquipContent.onRefreshItemView(container);
    elseif eventName == "onHand" then
		GodEquipContent.onHand(container);
	end
end
------------------------------scrollview-------------------------
function GodEquipBuildPage:GodEquipBuildEvent(container,isSingle)
    
    if ReqAnim.isAnimationRuning then
        return
    end
    if ReqAnim.isFirst then
        ReqAnim.isSingle = isSingle;
        container:runAnimation("ClickAni")
        ReqAnim.isFirst = false
        return 
    end
    UserInfo.sync();
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40;
    local count = UserEquipManager:countEquipAll();
    local needtips = count >=bagSize;

    --[[local willgetCount = 10;
    if isSingle then
        willgetCount = 1
    end
    if bagSize - count < willgetCount then
        needtips = true
    end]]--
    if needtips then
        local title = common:getLanguageString("@EquipBagFullTitle");
        local msg = common:getLanguageString("@EquipBagFullMsg");
        PageManager.showConfirm(title, msg, function(isSure)
            if isSure then
	           --PageManager.refreshPage("ActivityPage","GodEquipBuild")
              -- MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
                PackagePage_setAct(89)
                MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
                MainFrame_onBackpackPageBtn();

            end
        end);
        return 
    end
    local msg = GodEquipBuild_pb.EquipBuildReq()
    msg.isSingle = isSingle
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(HP_pb.EQUIP_BUILD_EVENT_C, pb , #pb, true)
end

function GodEquipBuildPage:onHand(container,eventName)
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
function GodEquipBuildPage:onFree(container)
    GodEquipBuildPage:GodEquipBuildEvent(container,true);
end
function GodEquipBuildPage:onDiamond(container)

    GodEquipBuildPage:GodEquipBuildEvent(container,false);
end
function GodEquipBuildPage:onRewardPreview(container)
	RegisterLuaPage("GodEquipPreview")
	ShowEquipPreviewPage(ConfigManager.getGodEquipPreviewCfg(),common:getLanguageString("@RewardPreviewTitle"),common:getLanguageString("@ForgingPoolShowMsg"))
    PageManager.pushPage("GodEquipPreview");
end

function GodEquipBuildPage:onIllustatedOpen(container)
    require("SuitDisplayPage")
    SuitDisplayPageBase_setEquip(16)
    PageManager.pushPage("SuitDisplayPage");
end
function GodEquipBuildPage:onBackpackOpen(container)
    PackagePage_setAct(89)
    MainFrame:getInstance():onMenuItemAction("onEquipmentPageBtn" , nil)
    MainFrame_onBackpackPageBtn();
end

function GodEquipBuildPage:onEnter(ParentContainer)
    self.container = ScriptContentBase:create("Act_TimeLimitSuitForgeContent.ccbi")
    self.container:registerFunctionHandler(GodEquipBuildPage.onFunction)
    self:registerPacket(ParentContainer)
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mBtmNode"))
    NodeHelper:autoAdjustResetNodePosition(self.container:getVarNode("mMidNode"), 0.5)
    thisPageNameContainer = self.container
    --self:getActivityInfo()
    --thisPageNameContainer = self.container
    GodEquipContent.AllContainer = {}
    EquipCfg = ConfigManager.getEquipCfg()
    GodEquipBuildCfg = ConfigManager.getGodEquipBuildCfg()
    NodeHelper:initScrollView(self.container, "mContent", 5);
    self.container.scrollview=self.container:getVarScrollView("mContent");
    self.container.scrollview:setTouchEnabled(true)
    ReqAnim = {
        isSingle = false,
        isFirst = false,
        isAnimationRuning = false,
        showNewReward = {}
     }
    ---------------------------------------------隐藏奖励节点
    self:HideRewardNode(self.container)
    NodeHelper:setNodesVisible(self.container, {mBackpackPagePoint = false})--红点
    ---------------------------------------------隐藏奖励节点
    self:registerPacket(ParentContainer)
    self:getActivityInfo()

    return self.container

end

function GodEquipBuildPage:HideRewardNode(container)
    local visibleMap = {}
    for i = 1 ,10 do
        visibleMap["mRewardNode"..i] = false
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    alreadyShowReward = {}
end
function GodEquipBuildPage:onAnimationDone(container)
	local animationName=tostring(container:getCurAnimationDoneName())
	if string.sub(animationName,1,8)=="ItemAni_" then
        local index = tonumber(string.sub(animationName,-2))
		if index < #alreadyShowReward and index < 10 then
            self:refreshRewardNode(container,index+1)
        else

            if alreadyShowReward[11] and index == 10 then
                local reward = alreadyShowReward[11];
                local rewardItems = common:parseItemWithComma( reward )
                -- local _type, _id, _count = unpack(common:split(reward, "_"));
                -- table.insert(rewardItems, {
                --     type    = tonumber(_type),
                --     itemId  = tonumber(_id),
                --     count   = tonumber(_count),
                --     });
                
                local CommonRewardPage = require("CommonRewardPage")
                CommonRewardPageBase_setPageParm(rewardItems, true) --, msg.rewardType
                PageManager.pushPage("CommonRewardPage")
            end
            --播放完毕
            NodeHelper:setNodesVisible(container, { mBackpackbtn = true,mIllustatedbtn = true,mRewardBtn = true})
            NodeHelper:setMenuItemEnabled( container, "mDiamond", true);
            NodeHelper:setMenuItemEnabled( container, "mFree", true);
            --
            local rewardItems = {}
            if #ReqAnim.showNewReward > 0 then
                if #ReqAnim.showNewReward > 10 then 
                    for i = 1,10 do
                        local _type, _id, _count = unpack(common:split(ReqAnim.showNewReward[i], "_"));
                        table.insert(rewardItems, {
    			            itemType 	= tonumber(_type),
    			            itemId	= tonumber(_id),
    			            itemCount 	= tonumber(_count)
    		            });
                    end
                    ----最后特殊奖励可能是多个
                    local tempItems = common:parseItemWithCommaId( alreadyShowReward[11] )
                    for i=1,#tempItems do
                        rewardItems[#rewardItems+1] = tempItems[i]
                    end
                else
                    for i = 1,#ReqAnim.showNewReward do
                        local _type, _id, _count = unpack(common:split(ReqAnim.showNewReward[i], "_"));
                        table.insert(rewardItems, {
                            itemType    = tonumber(_type),
                            itemId  = tonumber(_id),
                            itemCount   = tonumber(_count)
                        });
                    end
                end
            end
            NodeHelper:showRewardText(container, rewardItems)
            --ReqAnim.showNewReward = {}
            ReqAnim.isAnimationRuning = false;
            self:getActivityInfo()
        end
	end
    if animationName == "ClickAni" then
        GodEquipBuildPage:GodEquipBuildEvent(container,ReqAnim.isSingle);
    end
end
function GodEquipBuildPage:refreshRewardNode(container,index)
    local visibleMap = {}
    visibleMap["mRewardNode"..index] = true

    local reward = alreadyShowReward[index];
    local rewardItems = {}
    local _type, _id, _count = unpack(common:split(reward, "_"));
    table.insert(rewardItems, {
        type 	= tonumber(_type),
        itemId	= tonumber(_id),
        count 	= tonumber(_count),
        });

    NodeHelper:fillRewardItemWithParams(container, rewardItems,1,{startIndex = index ,frameNode = "mHand",countNode = "mNumber"})
    NodeHelper:setNodesVisible(container, visibleMap )
    local Aniname = tostring(index)
    if index < 10 then
        Aniname = "0"..Aniname
    end
    
    container:runAnimation("ItemAni_"..Aniname)
end
function GodEquipBuildPage:refreshPage(container)
    UserInfo.sync();
    local labelText = {}
    if PageInfo.closeTimes > 0 then
        lasttime = PageInfo.closeTimes
        TimeCalculator:getInstance():createTimeCalcultor(PageInfo.timerName, PageInfo.closeTimes);
    else
        labelText.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end
    if PageInfo.freeTimesCD > 0 then
        TimeCalculator:getInstance():createTimeCalcultor(PageInfo.freeTimesCDName, PageInfo.freeTimesCD);
    else
        NodeHelper:setNodesVisible(container, {mFreeText = true,mCostNodeVar = false,mSuitFreeTime = false})
    end
    labelText.mDiamondNum = UserInfo.playerInfo.gold
    labelText.mDiamondText = tostring(PageInfo.tenCost)
    labelText.mCostNum = tostring(PageInfo.singleCost)
    NodeHelper:setStringForLabel(container,labelText);

    if #GodEquipContent.AllContainer == 0 then--构建scrollview
        NodeHelper:buildScrollViewHorizontal(container, #PageInfo.allEquip, GodEquipContent.ccbFile, GodEquipContent.onFunction,10)
        --限制居中的
        local size = #PageInfo.allEquip
        if size <= 5 then 
            local node = container:getVarNode("mContent")
            local x = node:getPositionX()
            node:setPositionX(x + (530-size*106)/2);
            node:setTouchEnabled(false)
            NodeHelper:setNodesVisible(container, {mArrow = false})
        end
    else
        for k,v in pairs(GodEquipContent.AllContainer) do
            GodEquipContent.onRefreshItemView(v);
        end
    end

    

    self:refreshEquipBagInfo(container);
end
function GodEquipBuildPage:refreshEquipBagInfo(container)
    UserInfo.sync();
    local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40;
    local count = UserEquipManager:countEquipAll();
    NodeHelper:setNodesVisible(container, {mBackpackPagePoint = count >= bagSize})--红点
    NodeHelper:setStringForLabel(container,{ mBackpackNum = count.."/"..bagSize});

end
function GodEquipBuildPage:onExecute(ParentContainer)
	local timeStr = '00:00:00'
	if TimeCalculator:getInstance():hasKey(PageInfo.timerName) then
		PageInfo.closeTimes = TimeCalculator:getInstance():getTimeLeft(PageInfo.timerName)
		if PageInfo.closeTimes > 0 then
			 timeStr = common:second2DateString(PageInfo.closeTimes , false)
		end
        if PageInfo.closeTimes <= 0 then
		    timeStr = common:getLanguageString("@ActivityEnd")
	    end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr})
        if (lasttime - PageInfo.closeTimes) >= 2 then--N秒刷新背包信息一次
            lasttime = PageInfo.closeTimes
            self:refreshEquipBagInfo(self.container);
        end
	end
    timeStr = '00:00:00'
    if TimeCalculator:getInstance():hasKey(PageInfo.freeTimesCDName) then
		PageInfo.freeTimesCD = TimeCalculator:getInstance():getTimeLeft(PageInfo.freeTimesCDName)
		if PageInfo.freeTimesCD > 0 then
			 timeStr = GameMaths:formatSecondsToTime(PageInfo.freeTimesCD)
		end
        if PageInfo.freeTimesCD <= 0 then
            NodeHelper:setNodesVisible(self.container, {mFreeText = true,mCostNodeVar = false,mSuitFreeTime = false})
        else
            ActivityInfo.changeActivityNotice(Const_pb.GODEQUIP_FORGING)
            NodeHelper:setNodesVisible(self.container, {mFreeText = false,mCostNodeVar = true,mSuitFreeTime = true})
            NodeHelper:setStringForLabel(self.container, { mSuitFreeTime = common:getLanguageString('@SuitFreeOneTime',timeStr)})
	    end
	end
	
end
function GodEquipBuildPage:getActivityInfo()
    common:sendEmptyPacket(opcodes.EQUIP_BUILD_ACT_INFO_C , true)
end
function GodEquipBuildPage:RequestFishingEvent(isSingle)
    
end
function GodEquipBuildPage:onReceivePacket(ParentContainer)
	local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == opcodes.EQUIP_BUILD_ACT_INFO_S then
		local msg = GodEquipBuild_pb.GodEquipBuildInfoRet()
		msg:ParseFromString(msgBuff)
        PageInfo.singleCost = msg.singleCost
        PageInfo.tenCost = msg.tenCost
        PageInfo.closeTimes = msg.closeTimes
        PageInfo.freeTimesCD = msg.freeTimesCD
        PageInfo.allEquip = msg.allEquip
        self:refreshPage(self.container)
    elseif opcode == opcodes.EQUIP_BUILD_EVENT_S then
        local msg = GodEquipBuild_pb.EquipBuildRet()
		msg:ParseFromString(msgBuff)
        ReqAnim.showNewReward = {}
        ReqAnim.showNewReward = msg.reward
        local reward = msg.reward
        local beginIndex = 1;
        if (#alreadyShowReward + #reward) > COUNT_LIMIT then
            self:HideRewardNode(self.container);
        else
            beginIndex = #alreadyShowReward + 1;
        end
        for i = 1,#reward do
            alreadyShowReward[#alreadyShowReward+1] = reward[i]
        end

        NodeHelper:setNodesVisible(self.container, { mBackpackbtn = false,mIllustatedbtn = false,mRewardBtn = false})
        NodeHelper:setMenuItemEnabled( self.container, "mDiamond", false);
        NodeHelper:setMenuItemEnabled( self.container, "mFree", false);
        ReqAnim.isAnimationRuning = true
        self:refreshRewardNode(self.container,beginIndex);
	end
end

function GodEquipBuildPage:registerPacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GodEquipBuildPage:removePacket(container)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end
function GodEquipBuildPage:onExit(ParentContainer)
    self:removePacket( ParentContainer )
    NodeHelper:deleteScrollView(self.container);
    TimeCalculator:getInstance():removeTimeCalcultor(PageInfo.timerName)
    onUnload(thisPageName, self.container);
end
-- local CommonPage = require('CommonPage')
-- GodEquipBuild= CommonPage.newSub(GodEquipBuildPage, thisPageName, option)
return GodEquipBuildPage
