local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = 'ChatSkinBuyPage'
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")
local json = require('json')

local ChatSkinBuyPage = {
    bought = false,
    timerName = "ChatSkinBuyPage",
    leftTime = 0,
    leftTimes = {},
}

local ChatSkinBuyContent = {
    ccbiFile    = "Act_TimeLimitChatFrameListContent.ccbi"
}

local opcodes = {
	CHAT_SKIN_INFO_S 		= HP_pb.CHAT_SKIN_INFO_S,
    CHAT_SKIN_BUY_S = HP_pb.CHAT_SKIN_BUY_S
}

local skinActCfg = {}

local skinData = {}

local removeNotice = true

local onBuying = false

function ChatSkinBuyContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

---siq
function ChatSkinBuyContent:onBtn(container)
    local skinInfo = skinData[self.index]
    if skinInfo then
        if skinInfo.bought and skinInfo.bought > 0 then return end
        if skinInfo.rechargeId and skinInfo.rechargeId > 0 then
            self:buyGoods(skinInfo.rechargeId)
        elseif skinInfo.price and skinInfo.price > 0 then
            local msg = Activity2_pb.HPChatSkinBuy();
            msg.skinId = self.id
	        common:sendPacket(HP_pb.CHAT_SKIN_BUY_C, msg, true);
        end
    end
end

function ChatSkinBuyContent:onHand(container)
    --local rewardIndex = tonumber(eventName:sub(8))--数字
    local id = self.id
    local data = skinActCfg[id]

    if data then
        GameUtil:showTip(container:getVarNode('mPic'), data.rewards[1])
    end
end

function ChatSkinBuyContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local data

    for i,v in ipairs(skinActCfg) do
        if v.skinId == id then
            data = v
            break
        end
    end
    local skinInfo = skinData[index]

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local scale9Img = {}
    local scale9Size = {}
    local capInsets = {}

    if data then
        local rect = CCRectMake(0,0,85,61)
        if data.skinRes:find("u_ChatBG") then
            rect = CCRectMake(0,0,143,61)
        end
        scale9Img.mChatBGWhite = {
            name = data.skinRes,
            rect = rect
        }
        scale9Size.mChatBGWhite = CCSizeMake(370,65)
        capInsets.mChatBGWhite = {
            left = 47,
            right = 37,
            top = 30,
            bottom = 30
        }

        lb2Str.mDiscountTxt = common:getLanguageString(data.skinName)
        lb2Str.mTime = common:getLanguageString("@TLChatFrameTimeTxt" ,skinInfo.skinTime)

        if skinInfo.bought and skinInfo.bought > 0 then
            lb2Str.mBuy = common:getLanguageString("@HasBuy")
            visibleMap.mBuy = true
            visibleMap.mCostNode = false
            NodeHelper:setMenuItemEnabled(container, "mBtn", false)
        elseif skinInfo.price and skinInfo.price > 0 then
            lb2Str.mCostNum = skinInfo.price
            visibleMap.mBuy = false
            visibleMap.mCostNode = true
            NodeHelper:setMenuItemEnabled(container, "mBtn", true)
        elseif skinInfo.rechargeId and skinInfo.rechargeId > 0 then
            local SalePrice = 0
            for i = 1,#RechargeCfg do
                if tonumber(RechargeCfg[i].productId) == tonumber(skinInfo.rechargeId) then
                    SalePrice = RechargeCfg[i].productPrice;
                    break
                end
            end
            lb2Str.mBuy = common:getLanguageString("@RMB") .. tostring(SalePrice)
            visibleMap.mBuy = true
            visibleMap.mCostNode = false
            NodeHelper:setMenuItemEnabled(container, "mBtn", true)
        end

        NodeHelper:setColorForLabel(container,{mExample = data.textColor or GameConfig.ColorMap.COLOR_WHITE })
    end
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setScale9SpriteImage(container,scale9Img, capInsets ,scale9Size)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function ChatSkinBuyContent:buyGoods(id)
    local itemInfo = nil
    for i = 1,#RechargeCfg do
        CCLuaLog('buyGoods: productName=' .. RechargeCfg[i].productName.."id="..id)
        if tonumber(RechargeCfg[i].productId) == tonumber(id) then
            itemInfo = RechargeCfg[i];
            break
        end
    end
    if itemInfo == nil then return end
    CCLuaLog('buyGoods: productId=' .. itemInfo.productId.."id="..id)
    local buyInfo = BUYINFO:new() 
    buyInfo.productType = itemInfo.productType;  
    buyInfo.name = itemInfo.name;  
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
--    if Golb_Platform_Info.is_yougu_platform then   -- 悠谷平台需要转换 productType
--        local rechargeTypeCfg = ConfigManager.getRecharageTypeCfg()
--        if rechargeTypeCfg[itemInfo.productType] then
--            _type = tostring(rechargeTypeCfg[itemInfo.productType].type)
--        end
--    end
    
    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = {productType = _type, name = itemInfo.name, ratio = _ratio}
    buyInfo.extras = json.encode(extrasTable)
    
    --libPlatformManager:getPlatform():buyGoods(buyInfo)
    local BuyManager = require("BuyManager")
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end

function ChatSkinBuyPage.onFunction(eventName,container)
	
end

function ChatSkinBuyPage:onEnter(ParentContainer)
	local container = ScriptContentBase:create("Act_TimeLimitChatFrameContent.ccbi")
	self.container = container

    skinActCfg = ConfigManager.getChatSkinCfg()

    local scrollview = container:getVarScrollView("mContent");
	if scrollview ~= nil then
		ParentContainer:autoAdjustResizeScrollview(scrollview);
	end
    local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end

    NodeHelper:initScrollView(container, "mContent", 3);
    
    NodeHelper:setStringForLabel(container,{
--        mVIPLimitTxt = common:getLanguageString("@GrowthFundVIPBuyTxt",GameConfig.growthVipLevel),
--        mBuyNum = GameConfig.growthNeedGold,
--        mCompleteTxt = common:getLanguageString("@HasBuy"),
    })

    self.container:registerFunctionHandler(ChatSkinBuyPage.onFunction)
	self:registerPacket(ParentContainer)
    common:sendEmptyPacket( HP_pb.CHAT_SKIN_INFO_C , true)
--    skinData = {
--        {
--            skinId = 1001,
--            skinTime = 7,
--            bought = 1,
--            price = 1000
--        },
--        {
--            skinId = 1002,
--            skinTime = 5,
--            bought = 1,
--            rechargeId = 1
--        },
--        {
--            skinId = 1003,
--            skinTime = 3,
--            bought = 0,
--            price = 1000
--        },
--        {
--            skinId = 2001,
--            skinTime = 7,
--            price = 1000
--        },
--        {
--            skinId = 3001,
--            skinTime = 9,
--            bought = 1,
--            rechargeId = 2
--        },
--    }

    --self:clearAndReBuildAllItem(container)
    
	return self.container
end

function ChatSkinBuyPage:onExecute(container)
    local timeStr = '00:00:00'
	if TimeCalculator:getInstance():hasKey(ChatSkinBuyPage.timerName) then
		ChatSkinBuyPage.closeTimes = TimeCalculator:getInstance():getTimeLeft(ChatSkinBuyPage.timerName)
		if ChatSkinBuyPage.closeTimes > 0 then
			 timeStr = common:second2DateString(ChatSkinBuyPage.closeTimes , false)
		end
        if ChatSkinBuyPage.closeTimes <= 0 then
		    timeStr = common:getLanguageString("@ActivityEnd")
	    end
        NodeHelper:setStringForLabel(self.container, { mTanabataCD = timeStr})
	end
end

function ChatSkinBuyPage:onReceivePacket(ParentContainer)
    local opcode = ParentContainer:getRecPacketOpcode();
	local msgBuff = ParentContainer:getRecPacketBuffer();
    if opcode == HP_pb.CHAT_SKIN_INFO_S then
        local msg = Activity2_pb.HPChatSkinActivityInfo()
		msg:ParseFromString(msgBuff)

        skinData = msg.skins
        self:clearAndReBuildAllItem(self.container)

        ChatSkinBuyPage.leftTime = msg.leftTime

        common:sendEmptyPacket( HP_pb.CHAT_SKIN_CLEAR_RED_POINT_C , false)
        ActivityInfo.changeActivityNotice(Const_pb.CHAT_SKIN)
        self:refreshPage(container)
    elseif opcode == HP_pb.CHAT_SKIN_BUY_S then
        common:sendEmptyPacket( HP_pb.CHAT_SKIN_INFO_C , true)
    end
end

function ChatSkinBuyPage:onExit(container)
    self:removePacket(container)
    skinActCfg = {}
    skinData = {}
    removeNotice = true
    onBuying = false
    self.container.mScrollView:removeAllCell()

    onUnload(thisPageName,container)
end

function ChatSkinBuyPage:refreshPage(container)
    local lb2Str = {}
    if ChatSkinBuyPage.leftTime > 0 then
        lasttime = ChatSkinBuyPage.leftTime
        TimeCalculator:getInstance():createTimeCalcultor(ChatSkinBuyPage.timerName, ChatSkinBuyPage.leftTime);
    else
        lb2Str.mTanabataCD = common:getLanguageString("@ActivityEnd")
    end

    NodeHelper:setStringForLabel(self.container, lb2Str)
end

function ChatSkinBuyPage:clearAndReBuildAllItem(container)
    table.sort(skinData, function(a,b)
        return a.skinId > b.skinId
    end)
    container.mScrollView:removeAllCell()
    for i,v in ipairs(skinData) do
        local titleCell = CCBFileCell:create()
        local panel = ChatSkinBuyContent:new({id = v.skinId, index = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(ChatSkinBuyContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function ChatSkinBuyPage:registerPacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:registerPacket(opcode)
		end
	end
end

function ChatSkinBuyPage:removePacket(ParentContainer)
	for key, opcode in pairs(opcodes) do
		if string.sub(key, -1) == "S" then
			ParentContainer:removePacket(opcode)
		end
	end
end


return ChatSkinBuyPage