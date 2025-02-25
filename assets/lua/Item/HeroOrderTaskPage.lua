
local BasePage             = require("BasePage")
local NodeHelper           = require("NodeHelper")
local HeroOrderItemManager = require("Item.HeroOrderItemManager")
local sThisPageName        = "HeroOrderTaskPage"
local Const_pb             = require("Const_pb")
local UserItemManager      = require("Item.UserItemManager")
local common               = require("common")

local option = {
    ccbiFile      = "BackpackHeroPopUp2.ccbi",
    ccbiEmptyFile = "BackpackHeroPopUp3.ccbi",
    handlerMap = {
       onClose = "onClose",
       onBHPShop = "onBHPShop",
       onBHPHistory = "onBHPHistory"
    }
}
PAGE_TYPE = {
    SHOP_PAGE =  1,--商店页面
    LIST_PAGE = 2 --任务详细界面
}
local mTaskListInfo = {}
local mShopListInfo = {}
local mTaskFinishTimes = {}
local mCurPageType = PAGE_TYPE.SHOP_PAGE;
local HeroOrderTaskPage = BasePage:new(option, sThisPageName)

local mTaskItem = {
	ccbiFile = "BackpackHeroContent.ccbi",
    ccbiFileShop = "BackpackHeroProduct.ccbi"
};

function mTaskItem.onFunction(eventName, container)
	if eventName == "luaRefreshItemView" then
        mTaskItem.onRefreshItemView(container)
    elseif eventName == "onbuy" then
        mTaskItem.onbuyItem(container)
    end
end	
function mTaskItem.onbuyItem(container)
    local index = container:getItemDate().mID;
    local itemInfo = mShopListInfo[index];
    local HeroToken_pb  =   require("HeroToken_pb")
    local message = HeroToken_pb.HPShopBuyBean();
    if message~=nil then
        message.itemId = itemInfo.itemId;
        message.price = itemInfo.buyPrice;
        local pb_data = message:SerializeToString();
        PacketManager:getInstance():sendPakcet(HP_pb.HERO_TOKEN_BUY_INFO_C,pb_data,#pb_data,true);
    end
end
function mTaskItem.onRefreshItemView(container)
    if mCurPageType == PAGE_TYPE.LIST_PAGE then
         mTaskItem.newTaskItem(container, container:getItemDate().mID)
    else
         mTaskItem.newShopItem(container, container:getItemDate().mID)
    end
    
end

function mTaskItem.newTaskItem(container, index)
	local itemInfo = mTaskListInfo[index];
	local mResInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, itemInfo.nHeroOrderId, 1);
    local strLabel = {
        ["mNameLabel"]   = mResInfo.name
    }
    local mGoalContent = container:getVarLabelBMFont("mKillNum")
    local mScheduleNum  = container:getVarLabelBMFont("mScheduleNum")
    local mGoalStr   = common:fillHtmlStr("HeroOrderTaskGoalStr" , tostring(itemInfo.nLevelLimit))
    NodeHelper:addHtmlLable(mGoalContent, mGoalStr, GameConfig.Tag.HtmlLable, CCSizeMake(700,100));

    local mScheduleStr = common:fillHtmlStr("HeroOrderTaskProgressStr", tostring(itemInfo.nCurProgress), tostring(itemInfo.nTotalProgress))
    NodeHelper:addHtmlLable(mScheduleNum, mScheduleStr, GameConfig.Tag.HtmlLable + 1, CCSizeMake(700,100));
	NodeHelper:setStringForLabel(container, strLabel)
	NodeHelper:setSpriteImage(container,    {["mPic"] = mResInfo.icon})
	NodeHelper:setQualityFrames(container,  {["mHand"] = mResInfo.quality})
    NodeHelper:setNodesVisible(container,   {["mCompleted"] = itemInfo.bComplete})
end

function mTaskItem.newShopItem(container, index)
	local itemInfo = mShopListInfo[index];
    local mResInfo = ResManagerForLua:getResInfoByMainTypeAndId(Const_pb.TOOL, itemInfo.itemId, 1);
    --local strNum = common:getLanguageString("@BPHLeftTime")..itemInfo.buyTimes
    local strLabel = {
        mNameLabel    = mResInfo.name,
        mBuyNum = tostring(itemInfo.buyTimes),
        mBPHprice = tostring(itemInfo.buyPrice),
        mItemCount = "x "..tostring(itemInfo.itemCount)
    }
    NodeHelper:setStringForLabel(container, strLabel)
    NodeHelper:setSpriteImage(container,    {mPic = mResInfo.icon})
	NodeHelper:setQualityFrames(container,  {mHand = mResInfo.quality})
    NodeHelper:setNodesVisible(container,   {mItemLabel = itemInfo.bComplete})
end

function HeroOrderTaskPage:onLoad(container)
    HeroOrderTaskPage:initData();

	if #mTaskListInfo == 0 then
        if Golb_Platform_Info.is_r2_platform then
            container:loadCcbiFile(option.ccbiFile);
        else
            container:loadCcbiFile(option.ccbiEmptyFile);
        end
	else
        container:loadCcbiFile(option.ccbiFile);
	end
end
function HeroOrderTaskPage:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()

    if opcode == HP_pb.HERO_TOKEN_BUY_INFO_S then
		local msg = HeroToken_pb.HPShopBuyBeanRet();
		msg:ParseFromString(msgBuff)
		if msg ~= nil then 
            mShopListInfo = msg.ShopStatusBeanList;
            self:rebuildAllItem(container);
            HeroOrderItemManager:updateShopListInfo(msg.ShopStatusBeanList)
            if msg.isReset then--购买失败，物品已刷新
                MessageBoxPage:Msg_Box_Lan("@ABFightNoStart");
            end
		end

	end
end
function HeroOrderTaskPage:onBHPShop(container)
    if mCurPageType == PAGE_TYPE.SHOP_PAGE then
		self:setPageType(container)
        return;
    end
    mCurPageType = PAGE_TYPE.SHOP_PAGE;
    self:rebuildAllItem(container);
end
function HeroOrderTaskPage:onBHPHistory(container)
    if mCurPageType == PAGE_TYPE.LIST_PAGE then
		self:setPageType(container)
        return;
    end
    mCurPageType = PAGE_TYPE.LIST_PAGE;	
    self:rebuildAllItem(container);
end

function HeroOrderTaskPage:onEnter(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH);
    if Golb_Platform_Info.is_r2_platform then
        mCurPageType = PAGE_TYPE.SHOP_PAGE
    else
        mCurPageType = PAGE_TYPE.LIST_PAGE
    end
	if #mTaskListInfo ~= 0 or Golb_Platform_Info.is_r2_platform then
		NodeHelper:initScrollView(container, "mContent", 5)
		container.scrollview = container:getVarScrollView("mContent")
		container.scrollview:setVisible(true)
		HeroOrderTaskPage:rebuildAllItem(container);
	end
    container:registerPacket(HP_pb.HERO_TOKEN_BUY_INFO_S)
    local mBackpackHeroTittle = container:getVarLabelBMFont("mBackpackHeroTittle")
    mBackpackHeroTittle:setString(common:getLanguageString("@HeroOrderTaskTitle"))

    NodeHelper:setStringForLabel(container,{mTodayBHPnum = tostring(mTaskFinishTimes.taskFinishLefttimes)});
    NodeHelper:setLabelOneByOne(container,"mTodayBHPFinishleft","mTodayBHPnum",5,true);
    

end

function HeroOrderTaskPage:initData()

    mTaskListInfo = HeroOrderItemManager:getTaskListInfo();
    mShopListInfo = HeroOrderItemManager:getShopListInfo();
    mTaskFinishTimes = HeroOrderItemManager:getTaskFinishInfo();
    --[[if Golb_Platform_Info.is_win32_platform then
        mShopListInfo = 
        {
            {   itemId = 85040,
                itemType = 3,
                buyTimes = 2,
                buyPrice = 10086
            },
            {   itemId = 84040,
                itemType = 3,
                buyTimes = 8,
                buyPrice = 90000
            }
        }
    end]]--
    
end

function HeroOrderTaskPage:setPageType(container)
	local isShop = mCurPageType == PAGE_TYPE.SHOP_PAGE
	NodeHelper:setMenuItemSelected(container, {
		mBHPShop	= isShop,
		mBHPHistory	= not isShop
	})
end

function HeroOrderTaskPage:refreshPage(container)  
    HeroOrderTaskPage:initData()
    HeroOrderTaskPage:rebuildAllItem(container)    
end

function HeroOrderTaskPage:rebuildAllItem(container)
	HeroOrderTaskPage:clearAllItem(container);
	HeroOrderTaskPage:buildItem(container);
end

function HeroOrderTaskPage:clearAllItem(container)
	NodeHelper:clearScrollView(container);
end

function HeroOrderTaskPage:buildItem(container)
    if mCurPageType == PAGE_TYPE.LIST_PAGE then
        NodeHelper:buildScrollView(container, #mTaskListInfo, mTaskItem.ccbiFile, mTaskItem.onFunction);
    else
        NodeHelper:buildScrollView(container, #mShopListInfo, mTaskItem.ccbiFileShop, mTaskItem.onFunction);
    end
	if Golb_Platform_Info.is_r2_platform then
		self:setPageType(container)
	end
end

function HeroOrderTaskPage:onExit( container )
	-- body
     container:removeMessage(MSG_MAINFRAME_REFRESH)
     container:removePacket(HP_pb.HERO_TOKEN_BUY_INFO_S)
end

function HeroOrderTaskPage:onClose(container)
    PageManager.popPage(sThisPageName)
end


--endregion
