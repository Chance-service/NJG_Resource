
local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Recharge_pb = require "Recharge_pb"
local thisPageName = "NewActivityPage"
local UserInfo = require("PlayerInfo.UserInfo")
require("Activity.ActivityConfig")
require('MainScenePage')
local mScrollViewRef = {}
local mContainerRef = {}
local mSubNode = nil

local NewActivityPage = {}
local mChildNodeCount = 6;
local mCurrentIndex = 0;
local fOneItemWidth = 0
local fScrollViewWidth = 0

local WelfareContent = {
ccbiFile 	= "WelfarePanging.ccbi"
}
local mWelfareContainerRef = {};--存储上方页签 Container
local mSalePacketContainerRef = {};--存储折扣礼包 Container
CloseTime = "CloseTime" 
local tShowIds = {} -- 当前页面开启的活动id
--首冲礼包信息GameConfig
local tGiftInfo  = {
    itemInfo = {},
    rewardState = false,
    isFirstPayMoney = false
}
--月卡信息
local tMonthCardInfo  = {
    leftDays = 0,
    isTodayRewardGot = false,
    isMonthCardUser = false,
}
--折扣礼包信息
local SaleContent = {
ccbiFile 	= "Act_OnSaleAndRechargeContent1.ccbi",
alreadyBuytList = {},
receiveTimes = {},
salePacketLastTime = 0
}
local FirstGiftCfg = {}
local MonthCardCfg = {}
local SalepacketCfg = {}

--RechargeCfg = {}
local option = {
	ccbiFile = "Act_NewActivityPage.ccbi",
	handlerMap = {
		onReturnButton 					= "onClose",
        onHelp      = "onHelp",
        onArrowLeft = "onLeftActivityBtn",
        onArrowRight = "onRightActivityBtn",
        onReceive   = "onReceive",
		onWishing =  "onWishing",
	},
    opcodes = {

	}
}
local PageType = {
	FirstRecharge = 84,
	SaleGift = 82,
	MouthCard = 83
}

function NewActivityPage:onEnter(container)
    tShowIds = {}
    mWelfareContainerRef = {}
    mSalePacketContainerRef = {}
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    NodeHelper:initScrollView(container, "mScrollView", 5);
	container.scrollview=container:getVarScrollView("mScrollView");--标题滑动框 
    container.scrollview2=container:getVarScrollView("mContent");
	mSubNode = container:getVarNode("mSubNode")	--绑定子页面ccb的节点
	mSubNode:removeAllChildren()
    mScrollViewRef = container.scrollview;
    mContainerRef = container;
    container.scrollview:setTouchEnabled(true)
	--container.scrollview:setBounceable(false)
    fScrollViewWidth = container.scrollview:getViewSize().width
    local len = #ActivityInfo.NewPageids;
    for k=1,#ActivityInfo.NewPageids do
		tShowIds[#tShowIds+1] = ActivityInfo.NewPageids[k]
	end
    --tShowIds = {82,83,84};
    --init package
	mCurrentIndex = 1
	if PageManager.getJumpTo("NewActivityPage") then
		if PageManager.getJumpTo("NewActivityPage") == 25 then
			mCurrentIndex = 1
			PageManager.clearJumpTo()
		end
	end
	
    --self:refreshPage(container)  
    self:buildPaging(container)  
    self:SelectPaging(container)
end
function NewActivityPage:SelectPaging(container)
    for i = 1,#mWelfareContainerRef do
        local  visible = false;
        if i == mCurrentIndex then 
            visible = true
        end
        NodeHelper:setNodesVisible(mWelfareContainerRef[i],{mHand3BG = visible})
    end
    self:refreshPage(container)
end
function NewActivityPage:registerPacket(container)

end
function NewActivityPage:removePacket(container)

end
---------------------------------------------------------------------------------
--标签页
function WelfareContent.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
		WelfareContent.onRefreshItemView(container);
	elseif eventName == "onChanllage" then
		
	elseif eventName == "onMap" then

    elseif eventName == "onHand" then
		WelfareContent.onHand(container);
	end
end
function WelfareContent.onRefreshItemView(container)

	local levelId = tonumber(container:getItemDate().mID)
    if mWelfareContainerRef[levelId] == nil then
        mWelfareContainerRef[levelId] = container;
    end
	local image  = ActivityConfig[tShowIds[levelId]].image;
    NodeHelper:setNormalImages(container, { mHand = image})

end
function WelfareContent.onHand(container)
	local Id = tonumber(container:getItemDate().mID)
    if mCurrentIndex == Id then
        return 
    end
    mCurrentIndex = Id;
    NewActivityPage:SelectPaging(mContainerRef)

end
--构建标签页
function NewActivityPage:buildPaging(container)
	local iMaxNode = container.m_pScrollViewFacade:getMaxDynamicControledItemViewsNum()
	local iCount = 0
	local fOneItemHeight = 0
	local currentPos = 0;
    local interval = 15;
	for i= 1, #tShowIds do
		local pItemData = CCReViSvItemData:new_local()		
		pItemData.mID = i
		pItemData.m_iIdx = i
		pItemData.m_ptPosition = ccp((fOneItemWidth+interval) * iCount,0)
		
		if iCount < iMaxNode then
			ccbiFile = WelfareContent.ccbiFile
			local pItem = ScriptContentBase:create(ccbiFile);
			--pItem:release();
			pItem.id = iCount
			pItem:registerFunctionHandler(WelfareContent.onFunction)
			fOneItemHeight = pItem:getContentSize().height
			
			if fOneItemWidth < pItem:getContentSize().width then
				fOneItemWidth = pItem:getContentSize().width
			end
			currentPos = currentPos + fOneItemWidth
			container.m_pScrollViewFacade:addItem(pItemData, pItem.__CCReViSvItemNodeFacade__)
		else
			container.m_pScrollViewFacade:addItem(pItemData)
		end
		iCount = iCount + 1
	end
   local size = CCSizeMake(fOneItemWidth* iCount + interval * (iCount-1), fOneItemHeight)
	container.mScrollView:setContentSize(size)
	container.mScrollView:setContentOffset(ccp(0, 0))
	container.m_pScrollViewFacade:setDynamicItemsStartPosition(iCount - 1);
	container.mScrollView:forceRecaculateChildren();
	ScriptMathToLua:setSwallowsTouches(container.mScrollView)
end
--标签页
---------------------------------------------------------------------------------
function NewActivityPage:refreshPage(container)
	local activityId = tShowIds[mCurrentIndex]
	local activityCfg = ActivityConfig[activityId]
	if activityCfg then
		local page = activityCfg.page
		if page and page ~= "" and mSubNode then
    if NewActivityPage.subPage then
        NewActivityPage.subPage:onExit(container)
        NewActivityPage.subPage = nil
    end
	mSubNode:removeAllChildren()
			NewActivityPage.subPage = require(page)
	NewActivityPage.sunCCB = NewActivityPage.subPage:onEnter(container)
	mSubNode:addChild(NewActivityPage.sunCCB)
	NewActivityPage.sunCCB:setAnchorPoint(ccp(0,0))
	NewActivityPage.sunCCB:release()
		end
	end
end

function NewActivityPage:onWishing(container)
	container:runAnimation("Anim1")
end
--接收服务器回包
function NewActivityPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
	if NewActivityPage.subPage then
		NewActivityPage.subPage:onReceivePacket(container)
	end
end
function NewActivityPage:onExecute(container)
	if NewActivityPage.subPage then
		NewActivityPage.subPage:onExecute(container)
	end
end
function NewActivityPage:onClose( container )
    PageManager.popPage(thisPageName)
end
function NewActivityPage:onExit(container)
	if NewActivityPage.subPage then
		NewActivityPage.subPage:onExit(container)
		NewActivityPage.subPage = nil
	end
end
function NewActivityPage:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_NEWACTIVITY)
end
local CommonPage = require('CommonPage')
NewServerActivity= CommonPage.newSub(NewActivityPage, thisPageName, option)
