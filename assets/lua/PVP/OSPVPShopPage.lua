local thisPageName = "OSPVPShopPage"
local OSPVPShopPage = {}
local ShopDataManager = require("ShopDataManager")
local OSPVPManager = require("OSPVPManager")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")

local option = {
    ccbiFile = "PVPShopContent.ccbi",
    handlerMap = {

    },
    opcodes = {
    }
}

local shopList = {}

local lockBuy = true

local OSPVPVsContent = {
    ccbiFile = "FairContentItem.ccbi",
    item = "FairContent.ccbi",
}

function OSPVPVsContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function OSPVPVsContent:onRefreshContent(ccbRoot)
    local index = self.index
    local root = ccbRoot:getCCBFileNode()

    local node1 = root:getVarNode("mPosition1")
    local node2 = root:getVarNode("mPosition2")
    
    local data1 = shopList[index * 2 - 1]
    local data2 = shopList[index * 2]
    node1:removeAllChildren()
    if data1 then
        self:initOneItem(node1,data1)
    end
    node2:removeAllChildren()
    if data2 then
        self:initOneItem(node2,data2)
    end
end

function OSPVPVsContent:initOneItem(base,data)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local menuImg = {}

    local resInfo = ResManagerForLua:getResInfoByTypeAndId(data.itemType, data.itemId)
	if not resInfo then return end

    local container = ScriptContentBase:create(OSPVPVsContent.item)
    local lb2Str = {
		mNumber 			= data.count,
		mCommodityName 		= resInfo.name,
        --mCommodityNum 		= data.price,
       mCommodityNum =  GameUtil:formatNumber(mCommodityNum),
        mLv                 = ""
	}
    sprite2Img.mConsumptionType = "UI/Common/Icon/Icon_PVP_S.png"
    sprite2Img.mPic = resInfo.icon
    visibleMap.mLabel = false
    menu2Quality.mHand = resInfo.quality
    if string.sub(resInfo.icon, 1, 7) == "UI/Role" then 
        scaleMap.mPic = 0.84
	else
        scaleMap.mPic = 1
	end

    base:addChild(container)
    container:registerFunctionHandler(function(eventName, container)
        if self[eventName] and type(self[eventName]) == "function" then
            self[eventName](self,container,data)
        end
    end)

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setNormalImages(container, menuImg)
end

function OSPVPVsContent:onHand(container,data)
    GameUtil:showTip(container:getVarNode('mPic'), {
        type = data.itemType,
        itemId = data.itemId
    })
end

function OSPVPVsContent:onbuy(container,data)
    if lockBuy then return end
    if OSPVPManager:getCsMoney() < data.price then
        MessageBoxPage:Msg_Box("@ERRORCODE_26004")
        return
    end
    ShopDataManager.buyShopItemsRequest(1,Const_pb.CROSS_MARKET,data.id, 1)
end

function OSPVPShopPage:create(base, ParentContainer)
    local o = {}
    self.__index = self
    setmetatable(o,self)
    o:onLoad(base, ParentContainer)
    return o
end

function OSPVPShopPage:onLoad(base, ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    container:registerFunctionHandler(function(evt, container)
        local funcName = option.handlerMap[evt]
        if self[funcName] and type(self[funcName]) == "function" then
            self[funcName](self,container)
        end
    end)
    self.container = container
    base:addChild(container)

    local scrollview = container:getVarScrollView("mContent");
	if scrollview ~= nil then
		ParentContainer:autoAdjustResizeScrollview(scrollview);
	end		
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
	
	local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end

    local ConfigManager = require("ConfigManager")
    local tempShopCfg = ConfigManager.getOSPVPShopCfg()

    for i,v in ipairs(tempShopCfg) do
        table.insert(shopList,{
            id = v.id,
            price = v.price,
            itemType = v.item[1].type,
            itemId = v.item[1].itemId,
            count = v.item[1].count,
        })
    end
    table.sort(shopList,function(a,b)
        return a.id < b.id
    end)

    self:onEnter(container)
end

function OSPVPShopPage:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 10);
    ShopDataManager.sendShopItemInfoRequest(Const_pb.INIT_TYPE,Const_pb.CROSS_MARKET)
    self:refreshPage(container)
    self:clearAndReBuildAllItem(container)
end

function OSPVPShopPage:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}
    local menuImg = {}

    local data = OSPVPManager:getPlayerInfo()
    if data then
        local roleCfg = OSPVPManager.getRoleCfg(UserInfo.roleInfo.itemId)
        local rank = OSPVPManager:getRank()
        local score = OSPVPManager:getScore()
        local stage = OSPVPManager.checkStage(score,rank)
        for i = 1, 3 do
            visibleMap["mProfession" .. i] = i == roleCfg.profession
        end

        local showCfg = LeaderAvatarManager.getCurShowCfg()
	    local icon = showCfg.icon[roleCfg.profession]
        sprite2Img.mArenaPic = icon

        lb2Str.mLv = UserInfo.getOtherLevelStr(data.rebirthStage, data.level)
        
        lb2Str.mPointNum = common:getLanguageString("@Ranking") .. rank
        lb2Str.mArenaName = data.name
        lb2Str.mFightingNumTitle = common:getLanguageString("@Fighting") .. (data.fightValue > 0 and data.fightValue or UserInfo.roleInfo.marsterFight)
        lb2Str.mReward = ""

        local moneyCfg = ConfigManager.getFreeTypeCfg(4002)
        local moneyStr = common:fill(moneyCfg.content, common:getLanguageString("@CSPVPCoinTitle"), OSPVPManager:getCsMoney())
        local moneyLabel = NodeHelper:setCCHTMLLabelDefaultPos( container:getVarNode("mIconNumber") , CCSize(600,200) , moneyStr)
	    moneyLabel:setAnchorPoint(ccp(0, 0.5))

        visibleMap.mReward = true

        local awards = OSPVPManager.checkReward(rank)
        if awards and awards[1] then
            local award = awards[1]
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(award.type,award.itemId)
            local freeTypeCfg = ConfigManager.getFreeTypeCfg(4001)
            local str = common:fill(freeTypeCfg.content, resInfo.name, award.count)

            local lab = NodeHelper:setCCHTMLLabelDefaultPos( container:getVarNode("mReward") , CCSize(600,200) , str)
	        lab:setAnchorPoint(ccp(0, 0.5))
        else
            lb2Str.mReward = common:getLanguageString("@PVPIconNumberTxt") .. common:getLanguageString("@noReward")
        end

        sprite2Img.mHeadFrame = stage.stageIcon
    else
        data = UserInfo.roleInfo

        local roleCfg = OSPVPManager.getRoleCfg(data.itemId)
        for i = 1, 3 do
            visibleMap["mProfession" .. i] = i == roleCfg.profession
        end

        sprite2Img.mArenaPic = roleCfg.icon

        lb2Str.mLv = UserInfo.getOtherLevelStr(data.rebirthStage, data.level)
        
        lb2Str.mPointNum = common:getLanguageString("@Ranking") .. common:getLanguageString("@noRanking")
        lb2Str.mArenaName = data.name
        lb2Str.mFightingNumTitle = common:getLanguageString("@Fighting") .. data.marsterFight
        lb2Str.mReward = ""

        local moneyCfg = ConfigManager.getFreeTypeCfg(4002)
        local moneyStr = common:fill(moneyCfg.content, common:getLanguageString("@CSPVPCoinTitle"), OSPVPManager:getCsMoney())
        local moneyLabel = NodeHelper:setCCHTMLLabelDefaultPos( container:getVarNode("mIconNumber") , CCSize(600,200) , moneyStr)
	    moneyLabel:setAnchorPoint(ccp(0, 0.5))

        visibleMap.mReward = true

        --local awards = OSPVPManager.checkReward(data.rank)
        --if awards and awards[1] then
        lb2Str.mReward = common:getLanguageString("@PVPIconNumberTxt") .. common:getLanguageString("@noReward")
        --end

        sprite2Img.mHeadFrame = GameConfig.QualityImage[1]
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
    NodeHelper:setNormalImages(container, menuImg)
end

function OSPVPShopPage:onExecute(container)
end

function OSPVPShopPage:onExit(container)
    shopList = {}
    lockBuy = true
    onUnload(thisPageName,container)
end

function OSPVPShopPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
    local container = self.container
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onCsMoney then
                self:refreshPage(container)
            end
        end
	end
end

function OSPVPShopPage:onReceivePacket(opcode,msgBuff)
    if opcode == HP_pb.SHOP_ITEM_S then
        local msg = Shop_pb.ShopItemInfoResponse()
		msg:ParseFromString(msgBuff)

        if msg.shopType == Const_pb.CROSS_MARKET then
            shopList = msg.itemInfo
            lockBuy = false
            self:clearAndReBuildAllItem(self.container)
        end
    end
end

function OSPVPShopPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    if #shopList >= 1 then
        for i = 1, math.ceil(#shopList/2) do
            local titleCell = CCBFileCell:create()
            local panel = OSPVPVsContent:new({index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
    --NodeHelper:setNodesVisible(container,{mEmptyFetterTxt = #shopList < 1})
end

return OSPVPShopPage