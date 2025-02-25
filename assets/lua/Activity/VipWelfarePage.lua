--[[
	VIP特权
--]]
require "Activity_pb"
local UserInfo = require("PlayerInfo.UserInfo");
local CommonPage = require("CommonPage")
local NewbieGuideManager = require("NewbieGuideManager")

local option = {
	ccbiFile = "Act_FixedTimeVIPWelfareContent.ccbi",
	handlerMap = {
		onReturnButton	= "onBack",
		onRechargeBtn	= "onRecharge",
		onReceiveBtn	= "onReceiveReward",
		onHelp			= "onHelp"
	}
}
local NodeHelper = require("NodeHelper");
local VipWelfarePageBase = {}
local thisActivityId = 23
local VipWelfareItem = {
	ccbiFile = "Act_FixedTimeVIPWelfareListContent.ccbi",
}

local PageInfo = {
	vipWelfareInfo = {},
	rewardState = false
}

local thisPageName = "VipWelfarePage"
---------------------------------------------------------------

function VipWelfareItem.onFunction( eventName, container )
	if eventName == "luaRefreshItemView" then
		VipWelfareItem.onRefreshItemView(container)
	elseif eventName:sub(1, 7) == "onFrame" then
		VipWelfareItem.onShowItemInfo( container , eventName )
	end
end

function VipWelfareItem:onRefreshContent( ccbRoot )
    local container = ccbRoot:getCCBFileNode()	
	local index = self.id
	local itemInfo = PageInfo.vipWelfareInfo[index]	
	container:getVarLabelBMFont("mVipNum"):setString("VIP"..tostring(itemInfo.id))
	--container:getVarScale9Sprite("mSelecteBG"):setVisible(itemInfo.id == UserInfo.playerInfo.vipLevel)

    local bl = itemInfo.id == UserInfo.playerInfo.vipLevel
	NodeHelper:setNodesVisible(container ,  {mSelecteBG = bl})

    NodeHelper:setNodeIsGray(container, {mVipNum = not bl , mVipImage = not bl})

	local children = container:getVarScale9Sprite("mS9_1"):getChildren()
	if not bl then
		GraySprite:AddColorGrayToNode(tolua.cast(children:objectAtIndex(0), "CCNode"))
	else
		GraySprite:RemoveColorGrayToNode(tolua.cast(children:objectAtIndex(0), "CCNode"))
	end

	local rewardItems = {}
	if itemInfo.reward ~= nil then
		for _, item in ipairs(common:split(itemInfo.reward, ",")) do
			local _type, _id, _count = unpack(common:split(item, "_"));
			table.insert(rewardItems, {
				type 	= tonumber(_type),
				itemId	= tonumber(_id),
				count 	= tonumber(_count)
			});
		end
	end
	NodeHelper:fillRewardItem(container, rewardItems)
	self.rewardItems = rewardItems
end

function VipWelfareItem:onFrame1( container ) 
	self:onShowItemInfo(container, self.rewardItems[1], 1)    
end

function VipWelfareItem:onFrame2( container )
	self:onShowItemInfo(container, self.rewardItems[2], 2)
end

function VipWelfareItem:onFrame3( container )
	self:onShowItemInfo(container, self.rewardItems[3], 3)
end


function VipWelfareItem:onFrame4( container )
	self:onShowItemInfo(container, self.rewardItems[4], 4)
end


function VipWelfareItem:onShowItemInfo( container , itemInfo, rewardIndex )
    GameUtil:showTip(container:getVarNode('mFrame' .. rewardIndex), itemInfo)
end

function VipWelfarePageBase:onEnter( parentContainer )

	local container = ScriptContentBase:create(option.ccbiFile)
	self.container = container
	container.mScrollView = container:getVarScrollView("mContent")
	luaCreat_VipWelfarePage(container)
	self:registerPacket( parentContainer )	
	PageInfo.vipWelfareInfo = ConfigManager.getVipWelfareCfg()
	-- if container.mScrollView ~=nil then
		-- container:autoAdjustResizeScrollview(container.mScrollView);
	-- end
	self:rebuildAllItems( container )
	self:getRewardStatue( container )
	NewbieGuideManager.showHelpPage(GameConfig.HelpKey.HELP_VIPWELFARE)

	return container
end	

function VipWelfarePageBase:getRewardStatue( container )
	common:sendEmptyPacket( HP_pb.VIP_WELFARE_INFO_C , true )
end

function VipWelfarePageBase:refreshPage( container )

    if PageInfo.rewardState then
		container:getVarMenuItemImage("mReceiveBtn"):setEnabled(false)
        NodeHelper:setNodeIsGray(container, {mGetBtnLabel = true})
	else
		container:getVarMenuItemImage("mReceiveBtn"):setEnabled(true)
        NodeHelper:setNodeIsGray(container, {mGetBtnLabel = false})
	end
--	if PageInfo.rewardState then
--		container:getVarMenuItemImage("mReceiveBtn"):selected()
--	else
--		container:getVarMenuItemImage("mReceiveBtn"):unselected()
--	end
end

function VipWelfarePageBase:rebuildAllItems( container )
	UserInfo.sync()
	self:buildAllItems( container )
	self:setCurVipReward( container )
end

function VipWelfarePageBase:setCurVipReward( container )
	local totalOffset = container.mScrollView:getContentOffset()
	if UserInfo.playerInfo.vipLevel < 2 then
	    return
	end

	container.mScrollView:locateToByIndex( UserInfo.playerInfo.vipLevel - 1 )
end

function VipWelfarePageBase:clearAllItems( container )
	NodeHelper:clearScrollView(container)
end

function VipWelfarePageBase:buildAllItems( container )
	container.mScrollView:removeAllCell()
	NodeHelper:buildCellScrollView(container.mScrollView,#PageInfo.vipWelfareInfo, VipWelfareItem.ccbiFile, VipWelfareItem)
end

function VipWelfarePageBase:onExecute( container )

end

function VipWelfarePageBase:onExit( parentContainer )
	self:removePacket( parentContainer )
	self.container.mScrollView:removeAllCell()
	onUnload(thisPageName, self.container)
end

function VipWelfarePageBase:onBack( container )
	PageManager.popPage(thisPageName)
    PageManager.refreshPage("ActivityPage");
end 

function VipWelfarePageBase:onRecharge( container )
	libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE","VIPPerks_enter_rechargePage")
	PageManager.pushPage("RechargePage")
end

function VipWelfarePageBase:onHelp( container )
	PageManager.showHelp(GameConfig.HelpKey.HELP_VIPWELFARE)
end

function VipWelfarePageBase:onReceiveReward( container )
	if PageInfo.rewardState then
		MessageBoxPage:Msg_Box_Lan("@VipWelfareAlreadyReceive")
		self:refreshPage( container )
	else
		UserInfo.sync()
		if UserInfo.playerInfo.vipLevel > 0 then
			common:sendEmptyPacket( HP_pb.VIP_WELFARE_AWARD_C , true )
		else
			MessageBoxPage:Msg_Box_Lan("@VipLevelNotEnough")
		end
	end
end	

function VipWelfarePageBase:onReceivePacket(parentContainer)
	local opcode = parentContainer:getRecPacketOpcode();
	local msgBuff = parentContainer:getRecPacketBuffer();
    if opcode == HP_pb.VIP_WELFARE_INFO_S then
		local msg = Activity_pb.HPVipWelfareInfoRet()
		msg:ParseFromString(msgBuff)
		PageInfo.rewardState = msg.awardStatus == 1
		self:refreshPage( self.container )
		return;
	end
	if opcode == HP_pb.VIP_WELFARE_AWARD_S then
		local msg = Activity_pb.HPVipWelfareRewardRet()
		msg:ParseFromString(msgBuff)
		PageInfo.rewardState = msg.awardStatus == 1
		ActivityInfo.activities[Const_pb.VIP_WELFARE]["isNew"] = false
        ActivityInfo.changeActivityNotice( thisActivityId, false )
		--ActivityInfo:showNotice(false)
		self:refreshPage( self.container )
        VipWelfarePageBase:clearNotice()
		return;
	end		
end

function VipWelfarePageBase:clearNotice( )
    --红点消除
    ActivityInfo.changeActivityNotice(Const_pb.VIP_WELFARE);
end


function VipWelfarePageBase:onReceiveMessage(parentContainer)
	local message = parentContainer:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
		if pageName == thisPageName then
			self:rebuildAllItems( self.container )
			self:getRewardStatue( self.container )
		end
	end
end

function VipWelfarePageBase:registerPacket(parentContainer)
	parentContainer:registerPacket(HP_pb.VIP_WELFARE_INFO_S)
	parentContainer:registerPacket(HP_pb.VIP_WELFARE_AWARD_S)	
end

function VipWelfarePageBase:removePacket(parentContainer)
	parentContainer:removePacket(HP_pb.VIP_WELFARE_INFO_S)
	parentContainer:removePacket(HP_pb.VIP_WELFARE_AWARD_S)	
end
---------------------------------------------------------------
VipWelfarePage = CommonPage.newSub(VipWelfarePageBase, thisPageName, option);

return VipWelfarePage