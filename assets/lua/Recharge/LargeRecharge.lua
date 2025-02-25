require "Recharge_pb"

local json = require('json')
local thisPageName = "LargeRecharge"

local option = {
	ccbiFile = "LargeRechargePopUp.ccbi",
	handlerMap = {
		onMoney1 		= "onMoney1",
		onMoney2		= "onMoney2",
		onMoney3        = "onMoney3",
		onClose			= "onClose"
	}
};
local LargeRechargeBase = {}
local pageInfo = {
	largeRechargeList = {}
}
--------------------------------------------------------------

function LargeRechargeBase:onEnter( container )
	for i = 1,#pageInfo.largeRechargeList do
		container:getVarLabelBMFont("mMoney" .. i):setString(common:getLanguageString("@RMB") .. pageInfo.largeRechargeList[i].productPrice)
	end
	
end

function LargeRechargeBase:onExecute( container )
	
end

function LargeRechargeBase:onExit( container )
	
end

function LargeRechargeBase:onMoney1( container )
	self:onRechanrge(1)
end

function LargeRechargeBase:onMoney2( container )
	self:onRechanrge(2)
end

function LargeRechargeBase:onMoney3( container )
	self:onRechanrge(3)
end

function LargeRechargeBase:onRechanrge( index )
	
	local itemInfo = pageInfo.largeRechargeList[index]
		
	if itemInfo.productType == 1  then
		PacketManager:getInstance():sendPakcet(HP_pb.MONTHCARD_PREPARE_BUY, "", 0, false)
	end
		
	local buyInfo = BUYINFO:new()
	buyInfo.productType         = itemInfo.productType;  
    buyInfo.name                = itemInfo.name;   
	buyInfo.productCount = 1
	buyInfo.productName = itemInfo.productName
	buyInfo.productId = itemInfo.productId
	buyInfo.productPrice = itemInfo.productPrice
	buyInfo.productOrignalPrice = itemInfo.gold
	
	buyInfo.description = ""
    if itemInfo:HasField("description") then
        buyInfo.description = itemInfo.description
    end

    buyInfo.serverTime = GamePrecedure:getInstance():getServerTime()
    
	local _type = tostring(itemInfo.productType)
--	if Golb_Platform_Info.is_yougu_platform then   -- 悠谷平台需要转换 productType
--		local rechargeTypeCfg = ConfigManager.getRecharageTypeCfg()
--		if rechargeTypeCfg[itemInfo.productType] then
--		    _type = tostring(rechargeTypeCfg[itemInfo.productType].type)
--		end
--    end
	
	local _ratio = tostring(itemInfo.ratio)
	local extrasTable = {productType = _type, name = itemInfo.name, ratio = _ratio}
	buyInfo.extras = json.encode(extrasTable)
	
	--libPlatformManager:getPlatform():buyGoods(buyInfo)
    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end

function LargeRechargeBase:onClose( container )
	PageManager.popPage( thisPageName )
end

function Set_LargeRechargeList( largeRechargeList )
	pageInfo.largeRechargeList = largeRechargeList
end

---------------------------------------------------------------
local CommonPage = require("CommonPage");
local RechargePage = CommonPage.newSub(LargeRechargeBase, thisPageName, option)
LargeRechargeBase = nil