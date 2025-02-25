
require "Activity_pb"
local NodeHelper = require("NodeHelper")
local Activity_pb = require("Activity_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local UserEquipManager = require("Equip.UserEquipManager")
local ActivityInfo = ("ActivityInfo")
local NewbieGuideManager = require("Guide.NewbieGuideManager")

local option = {
	ccbiFile = "FirstRechargePackage.ccbi",
	handlerMap = {
        onClose	= "onClose",
        onRecharge	= "onRecharge",
        onViewBackpack	= "onViewBackpack",
		onHelp			= "onHelp"
    }
}

local FirstGiftPackBase = {}

local FirstGiftPackItem = {
	ccbiFile = "FirstRechargePackageContent.ccbi",
}

local PageInfo = {
	firstGiftpackInfo = {},
    firstGiftpackShowInfo = {},
	rewardState = false,
    isFirstPayMoney = false
}
--角色类型
local FirstGiftRoleType = {
    FIGHTER = 1,
    HUNTER = 2,
    MAGICER = 3
}

local thisPageName = "FirstGiftPackPage"
-----------------------------FirstGiftPackItem----------------------------------

function FirstGiftPackItem.onFunction( eventName, container )
	if eventName == "luaRefreshItemView" then
		FirstGiftPackItem.onRefreshItemView(container)
	elseif eventName == "onReceiveReward" then --领取礼包
		FirstGiftPackItem.onReceiveGift(container)
    elseif eventName:sub(1, 7) == "onFrame" then--显示tips
        FirstGiftPackItem.onShowItemInfo(container,eventName)
	end
end

function FirstGiftPackItem.onRefreshItemView( container )
	local contentId = container:getItemDate().mID
	local itemInfo = PageInfo.firstGiftpackShowInfo[1]
    if not itemInfo then return end
    --获取礼包列表
	local rewardItems = {}
	if itemInfo.giftpack ~= nil then
		for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
			local _type, _id, _count = unpack(common:split(item, "_"));
			table.insert(rewardItems, {
				type 	= tonumber(_type),
				itemId	= tonumber(_id),
				count 	= tonumber(_count)
			})
		end
    end
    --TODO 主界面首充礼包小手新手引导
--[[    if EFUNSHOWNEWBIE() and  Newbie.step ~= 0 and  Newbie.step ==  Newbie.getIdByTag("newbie_MainFirstPayGift_Show") then
        Newbie.show(Newbie.getIdByTag("newbie_MainFirstPayGift_Show"))
        container:getVarNode("mNewbeeHintNode100"):setVisible(true)
    end]]
	NodeHelper:fillRewardItem(container, rewardItems)
    FirstGiftPackItem:refreshChildPage( container )

end
--处理礼包奖励单个查看
function FirstGiftPackItem.onShowItemInfo( container , eventName )

    --TODO 主界面首充礼包小手新手引导
--[[    if EFUNSHOWNEWBIE() and  Newbie.step ~= 0 and  Newbie.step ==  Newbie.getIdByTag("newbie_MainFirstPayGift_Show") then
        container:getVarNode("mNewbeeHintNode100"):setVisible(false)
        Newbie.next()
    end]]
    local index = container:getItemDate().mID
    local itemInfo = PageInfo.firstGiftpackShowInfo[index]
    if not itemInfo then return end
    local rewardItems = {}
    if itemInfo.giftpack ~= nil then
        for _, item in ipairs(common:split(itemInfo.giftpack, ",")) do
            local _type, _id, _count = unpack(common:split(item, "_"));
            table.insert(rewardItems, {
                type 	= tonumber(_type),
                itemId	= tonumber(_id),
                count 	= tonumber(_count)
            });
        end
    end

    local rewardIndex = tonumber(eventName:sub(15))--截取“mPic1”-“4”最后一位数字
    GameUtil:showTip(container:getVarNode('mPic' .. rewardIndex), rewardItems[rewardIndex])

end
--点击领取礼包
function FirstGiftPackItem.onReceiveGift(container)

    if (not PageInfo.rewardState) and PageInfo.isFirstPayMoney then

--        local bagSize = UserInfo.stateInfo.currentEquipBagSize or 40
        UserInfo.sync()
        if UserInfo.level > 0 then
            --查看装备背包是否空间不足
            local euqipBagFull = UserEquipManager:checkEquipPackageIsFull()
            if euqipBagFull then --装备背包已满
                MessageBoxPage:Msg_Box_Lan("@Activity_Open_BackpackInfo")
                return
            end
            PageManager.refreshPage("MainScenePage")--刷新一下主界面
--            FirstGiftPackItem:refreshChildPage( container )
            common:sendEmptyPacket( HP_pb.FIRST_GIFTPACK_AWARD_C , true )
            common:sendEmptyPacket( HP_pb.FIRST_GIFTPACK_INFO_C , true )
            PageManager.popPage(thisPageName)--关闭当前界面
            PackagePage_showEquipItems()
        end

    else
        if PageInfo.rewardState then
--            FirstGiftPackItem:refreshChildPage( container )
            return
        elseif not PageInfo.rewardState then -- 没领过不满足条件，按钮未灰色时
--            FirstGiftPackItem:refreshChildPage( container )
--            MessageBoxPage:Msg_Box_Lan("@Activity_UnPayAny_ShowTips")
        end

    end

end
function FirstGiftPackItem:refreshChildPage(container)

    if (not PageInfo.rewardState) and PageInfo.isFirstPayMoney then
        --未领取并且已经进行首充时
        container:getVarMenuItemImage("mReceiveReward"):unselected()
    elseif PageInfo.rewardState or (not PageInfo.isFirstPayMoney)  then
        --已经领取 、没有首充时
--        container:getVarMenuItemImage("mReceiveReward"):selected()
        local menuShow = container:getVarNode("mReceiveRewardCCMenu")
        menuShow:setVisible(false)
    end

end
-----------------------------FirstGiftPackItem----------------------------------
-----------------------------FirstGiftPackBase----------------------------------
function FirstGiftPackBase:onEnter( container )
	self:registerPacket( container )
	container:registerMessage(MSG_MAINFRAME_REFRESH)
	PageInfo.firstGiftpackInfo = ConfigManager.getFirstGiftPack()
    NodeHelper:initScrollView(container, "mScroll", 3)
    UserInfo.sync()
    if FirstGiftRoleType.FIGHTER == UserInfo.roleInfo.itemId or FirstGiftRoleType.FIGHTER == UserInfo.roleInfo.itemId - 3 then
        if #PageInfo.firstGiftpackShowInfo <= 0 then
            table.insert(PageInfo.firstGiftpackShowInfo, {
                id 	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.FIGHTER].id,
                giftpack	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.FIGHTER].giftpack
            })
        end
    elseif FirstGiftRoleType.HUNTER == UserInfo.roleInfo.itemId or FirstGiftRoleType.HUNTER == UserInfo.roleInfo.itemId - 3  then
        if #PageInfo.firstGiftpackShowInfo <= 0 then
            table.insert(PageInfo.firstGiftpackShowInfo, {
                id 	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.HUNTER].id,
                giftpack	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.HUNTER].giftpack
            })
        end
    elseif FirstGiftRoleType.MAGICER == UserInfo.roleInfo.itemId or FirstGiftRoleType.MAGICER == UserInfo.roleInfo.itemId - 3  then
        if #PageInfo.firstGiftpackShowInfo <= 0 then
            table.insert(PageInfo.firstGiftpackShowInfo, {
                id 	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.MAGICER].id,
                giftpack	= PageInfo.firstGiftpackInfo[FirstGiftRoleType.MAGICER].giftpack
            })
        end
    end

	if container.mScrollView ~=nil then
		--container:autoAdjustResizeScrollview(container.mScrollView)
	end
	self:rebuildAllItems( container )
	self:getRewardStatus( container )
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_FIRSTGIFTPACK)
end	

function FirstGiftPackBase:getRewardStatus( container )
	common:sendEmptyPacket( HP_pb.FIRST_GIFTPACK_INFO_C , true )
end

--------------------------------------ShowUI-------------------------------------------
--领取按钮是否可点击
function FirstGiftPackBase:refreshPage( container )

    if PageInfo.firstGiftpackShowInfo then
        self:rebuildAllItems(container)
    end

end

function FirstGiftPackBase:rebuildAllItems( container )
	self:clearAllItems( container )
	self:buildAllItems( container )
end

function FirstGiftPackBase:clearAllItems( container )
	NodeHelper:clearScrollView(container)
end
--初始化界面ScrollView内部显示内容
function FirstGiftPackBase:buildAllItems( container )
	NodeHelper:buildScrollView(container, #PageInfo.firstGiftpackShowInfo, FirstGiftPackItem.ccbiFile, FirstGiftPackItem.onFunction)
end

function FirstGiftPackBase:onExecute( container )

end
--退出此界面之后销毁包
function FirstGiftPackBase:onExit( container )
	self:removePacket( container )
end
--------------------------------------clickEvent-------------------------------------------
function FirstGiftPackBase:onHelp( container )
    PageManager.showHelp(GameConfig.HelpKey.HELP_FIRSTGIFTPACK)
end
function FirstGiftPackBase:onClose( container )
	PageInfo.firstGiftpackShowInfo = {}
    PageManager.popPage(thisPageName)
    --TODO 主界面首充礼包小手新手引导  弹出框 分享提示框
--[[    if EFUNSHOWNEWBIE() and  Newbie.step ~= 0 and  Newbie.step ==  Newbie.getIdByTag("newbie_MainFBShareBtn") then
        Newbie.show(Newbie.getIdByTag("newbie_MainFBShareBtn"))
    end]]
end
function FirstGiftPackBase:onRecharge( container )
    PageManager.popPage(thisPageName)
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","FirstGiftPack_enter_rechargePage")
	PageManager.pushPage("RechargePage")
end
function FirstGiftPackBase:onViewBackpack(container)
    PackagePage_showEquipItems()
end
--------------------------------------messageReceive&send-------------------------------------------

--接收服务器回包
function FirstGiftPackBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.FIRST_GIFTPACK_INFO_S then
		local msg = Activity_pb.HPFirstRechargeGiftInfo()
		msg:ParseFromString(msgBuff)
		PageInfo.rewardState = (msg.giftStatus == 1)
        PageInfo.isFirstPayMoney = (msg.isFirstPay == 1)--是否为首次充值
		self:refreshPage( container )
		return
	end
	if opcode == HP_pb.FIRST_GIFTPACK_AWARD_S then
		local msg = Activity_pb.HPFirstRechargeGiftAwardRet()
		msg:ParseFromString(msgBuff)
		PageInfo.rewardState = (msg.giftStatus == 1)
--        common:sendEmptyPacket( HP_pb.FIRST_GIFTPACK_INFO_C , true )
--        self:refreshPage( container )
--		ActivityInfo.activities[Const_pb.FIRST_GIFTPACK]["isNew"] = false
--		ActivityInfo:showFirstGiftPackNotice(false,false)--设置显示红点

		return
	end
end
--接收界面消息，刷新界面
function FirstGiftPackBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:rebuildAllItems( container )
			self:getRewardStatus( container )
		end
	end
end
--注册首充礼包充值info及reward消息
function FirstGiftPackBase:registerPacket(container)
	container:registerPacket(HP_pb.FIRST_GIFTPACK_INFO_S)
	container:registerPacket(HP_pb.FIRST_GIFTPACK_AWARD_S)
end
--销毁首充礼包充值info及reward消息
function FirstGiftPackBase:removePacket(container)
	container:removePacket(HP_pb.FIRST_GIFTPACK_INFO_S)
	container:removePacket(HP_pb.FIRST_GIFTPACK_AWARD_S)
end
----------------------------registPage-----------------------------------
local CommonPage = require("CommonPage")
FirstGiftPackPage = CommonPage.newSub(FirstGiftPackBase, thisPageName, option)

