-- 成長戰令
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local thisPageName = "IAPSubPage_GrowthFund"
local Activity5_pb = require("Activity5_pb")
local HP_pb = require("HP_pb")
local BuyManager = require("BuyManager")

local GrowthFundPage = { }

local option = {
    ccbiFile = "GrowthBundle.ccbi",
    handlerMap =
    {
        onHelp = "onHelp",
        onPlayer = "onPlayer",
        onStory = "onStory",
        onTower = "onTower",
        onType1 = "onType1",
        onType2 = "onType2",
        onBuy = "onBuy"
    },
}

local GrowthFundContent = {
    ccbiFile = "GrowthBundleItem.ccbi",
    rewardIds = {}
}

local opcodes = {
    ACTIVITY162_Growth_LV_S = HP_pb.ACTIVITY162_Growth_LV_S,
    ACTIVITY163_Growth_CH_S = HP_pb.ACTIVITY163_Growth_CH_S,
    ACTIVITY164_Growth_TW_S = HP_pb.ACTIVITY164_Growth_TW_S,
    GROWTH_PASS_BUY_SUCC_S = HP_pb.GROWTH_PASS_BUY_SUCC_S,
    FETCH_SHOP_LIST_S = HP_pb.FETCH_SHOP_LIST_S,
    PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
}
local GROWTH_PAGE_TYPE = {
    LEVEL = 1, STAGE = 2, TOWER = 3
}
local GROWTH_DATA = {
    [GROWTH_PAGE_TYPE.LEVEL] = { goodsId = { 101 }, cfg = ConfigManager.getGrowthLvCfg(), package = HP_pb.ACTIVITY162_Growth_LV_C }, 
    [GROWTH_PAGE_TYPE.STAGE] = { goodsId = { 102, 104 }, cfg = ConfigManager.getGrowthChCfg(), package = HP_pb.ACTIVITY163_Growth_CH_C },  
    [GROWTH_PAGE_TYPE.TOWER] = { goodsId = { 103 }, cfg = ConfigManager.getGrowthTwCfg(), package = HP_pb.ACTIVITY164_Growth_TW_C }, 
}
local nowPageType = GROWTH_PAGE_TYPE.LEVEL

local currCfg = { }
local removeNotice = true
local sendReward = false
local Current_Type = 1
local parentPage = nil
local MAX_TYPE = 2
local Content = {
    [GROWTH_PAGE_TYPE.LEVEL] = { action = 0, costFlag = { false }, freeReward = { }, costRewards = { }, init = false },
    [GROWTH_PAGE_TYPE.STAGE] = { action = 0, costFlag = { false, false }, freeReward = { }, costRewards = { }, init = false },
    [GROWTH_PAGE_TYPE.TOWER] = { action = 0, costFlag = { false }, freeReward = { }, costRewards = { }, init = false },
}

local currentScrollviewOffset = nil

local requesting = false

local mainContainer = nil

function GrowthFundPage:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    -- 註冊 呼叫行為
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)

    return container
end
function GrowthFundPage:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function GrowthFundContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()
    local data = currCfg[index]
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local colorMap = {}
    
    for i = 2, 4 do
        visibleMap["mRewardNode" .. i] = false
    end
    if data then
        --ContentControl
        visibleMap["mUpperLine"] = true
        visibleMap["mLowerLine"] = true
        if (index == 1) then
            visibleMap["mUpperLine"] = false
        elseif (index == #currCfg) then
            visibleMap["mLowerLine"] = false
        end
        self:ButtonControl(container, data)
        
        NodeHelper:setNodesVisible(container, { mReceived1 = false, mReceived2 = self.status == 3, mReceived3 = self.status == 3, mReceived4 = self.status == 3 })
        if self.status == 2 or self.status == 3 or self.status == 5 then
            NodeHelper:setNodesVisible(container, { mReceived1 = true })
        else
            NodeHelper:setNodesVisible(container, { mReceived1 = false })
        end
        --FreeRewards
        local FreeRewards = data.FreeRewards[1]
        local FreeResInfo = ResManagerForLua:getResInfoByTypeAndId(FreeRewards.type, FreeRewards.itemId, FreeRewards.count)
        sprite2Img["mPic1"] = FreeResInfo.icon
        sprite2Img["mFrameShade1"] = NodeHelper:getImageBgByQuality(FreeResInfo.quality)
        menu2Quality["mFrame1"] = FreeResInfo.quality
        lb2Str["mNum1"] = tostring(FreeRewards.count)
        lb2Str["mName1"] = "" --FreeResInfo.name;
        if (nowPageType == GROWTH_PAGE_TYPE.STAGE) then
            local mapCfg = ConfigManager.getNewMapCfg()
            local chapter = mapCfg[data.level].Chapter
            local level = mapCfg[data.level].Level
            lb2Str["mLv"] = chapter .. "-" .. level
        else
            lb2Str["mLv"] = data.level
        end
        --CostRewards
        for i = 1, #data.CostRewards do
            local cfg = data.CostRewards[i]
            visibleMap["mRewardNode" .. i + 1] = cfg ~= nil;
            if (cfg ~= nil) then
                local resInfo = ResManagerForLua:getResInfoByTypeAndId(cfg.type, cfg.itemId, cfg.count)
                if resInfo ~= nil then
                    sprite2Img["mPic" .. i + 1] = resInfo.icon
                    lb2Str["mNum" .. i + 1] = GameUtil:formatNumber(cfg.count)
                    lb2Str["mName" .. i + 1] = "" --resInfo.name
                    menu2Quality["mFrame" .. i + 1] = resInfo.quality
                    colorMap["mName" .. i + 1] = ConfigManager.getQualityColor()[resInfo.quality].textColor
                else
                    CCLuaLog("Error::***reward item not found!!")
                end
            end
        end
    end
    NodeHelper:setNodesVisible(container, visibleMap)
    NodeHelper:setStringForLabel(container, lb2Str)
    NodeHelper:setSpriteImage(container, sprite2Img)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setColorForLabel(container, colorMap)
end

function GrowthFundContent:ButtonControl(container, data)
    local CanReceive = common:getLanguageString("@Receive");
    local Received = common:getLanguageString("@ReceiveDone");
    local NotAchieve = common:getLanguageString("@Underway");
    local ReceivedButNotGrowthPass = common:getLanguageString("@buy");
    local Developing = "ComingSoon"
    --[[
    status=
    1 通行證已購買 未領取
    2 通行證已購買 已領取免費獎勵
    3 通行證已購買 已領取全部獎勵
    4 通行證未購買 未領取免費獎勵
    5 通行證未購買 已領取免費獎勵
    6 未達成目標
    
    ]]
    --LevelButton / StageButton
    if (nowPageType == GROWTH_PAGE_TYPE.LEVEL) or (nowPageType == GROWTH_PAGE_TYPE.STAGE) then
        local userLevel = ((nowPageType == GROWTH_PAGE_TYPE.LEVEL) and UserInfo.roleInfo.level) or 
                          ((nowPageType == GROWTH_PAGE_TYPE.STAGE) and UserInfo.stateInfo.passMapId) or 0
        if (userLevel >= data.level) then
            if Content[nowPageType].costFlag[Current_Type] then
                if Content[nowPageType].costRewards[data.id] ~= 0 then
                    NodeHelper:setStringForLabel(container, { mBtnLabel = Received })
                    NodeHelper:setMenuItemsEnabled(container, { mBtn = false })
                    self.status = 3
                else
                    if Content[nowPageType].freeReward[data.id] ~= 0 then
                        self.status = 2
                    else
                        self.status = 1
                    end
                    NodeHelper:setStringForLabel(container, { mBtnLabel = CanReceive })
                    NodeHelper:setMenuItemsEnabled(container, { mBtn = true })
                end
            else
                if Content[nowPageType].freeReward[data.id] ~= 0 then
                    NodeHelper:setStringForLabel(container, { mBtnLabel = ReceivedButNotGrowthPass })
                    NodeHelper:setMenuItemsEnabled(container, { mBtn = false })
                    self.status = 5
                else
                    NodeHelper:setStringForLabel(container, { mBtnLabel = CanReceive })
                    NodeHelper:setMenuItemsEnabled(container, { mBtn = true })
                    self.status = 4
                end
            end
        else
            NodeHelper:setStringForLabel(container, { mBtnLabel = NotAchieve })
            NodeHelper:setMenuItemsEnabled(container, { mBtn = false })
            self.status = 6
        end
    end
    --TowerButton
    if (nowPageType == GROWTH_PAGE_TYPE.TOWER) then
        NodeHelper:setStringForLabel(container, { mBtnLabel = Developing })
        NodeHelper:setMenuItemsEnabled(container, { mBtn = false })
    end
end
function GrowthFundContent:onBtnClick(container)
    local scrollview = mainContainer:getVarScrollView("mContent")
    currentScrollviewOffset = scrollview:getContentOffset() 
    local ItemInfo = GROWTH_DATA[nowPageType].cfg[self.id]
    local id = ItemInfo.id
    if self.status == 3 or self.status == 6 then return end
    --領取
    local msg = Activity5_pb.GrowthPassReq()
    msg.action = 1
    msg.cfgId = id
    local pb = msg:SerializeToString()
    PacketManager:getInstance():sendPakcet(GROWTH_DATA[nowPageType].package, pb, #pb, true)
    self:AwardPage(ItemInfo)
end
function GrowthFundContent:AwardPage(ItemInfo)
    local award = {}
    
    if self.status == 2 then
        award = ItemInfo.CostRewards
    elseif self.status == 1 then
        award = table.merge(ItemInfo.FreeRewards, ItemInfo.CostRewards)
    elseif self.status == 4 then
        award = ItemInfo.FreeRewards
    end
    
    local CommonRewardPage = require("CommPop.CommItemReceivePage")
    CommonRewardPage:setData(award, common:getLanguageString("@ItemObtainded"), nil)
    PageManager.pushPage("CommPop.CommItemReceivePage")
end
function table.merge(t1, t2)
    for k, v in ipairs(t2) do
        table.insert(t1, v)
    end
    return t1
end
function GrowthFundContent:onFrame1(container)
    GrowthFundContent:onShowItemInfo(container, self.id, 1, true)
end
function GrowthFundContent:onFrame2(container)
    GrowthFundContent:onShowItemInfo(container, self.id, 2, false)
end
function GrowthFundContent:onFrame3(container)
    GrowthFundContent:onShowItemInfo(container, self.id, 3, false)
end
function GrowthFundContent:onFrame4(container)
    GrowthFundContent:onShowItemInfo(container, self.id, 4, false)
end
function GrowthFundContent:onShowItemInfo(container, index, goodIndex, isFree)
    local packetItem = GROWTH_DATA[nowPageType].cfg[index].CostRewards
    if (isFree) then
        packetItem = GROWTH_DATA[nowPageType].cfg[index].FreeRewards
    end
    if (isFree) then
        GameUtil:showTip(container:getVarNode('mPic' .. goodIndex), packetItem[goodIndex])
    else
        GameUtil:showTip(container:getVarNode('mPic' .. goodIndex), packetItem[goodIndex - 1])
    end
end
function GrowthFundPage:onEnter(ParentContainer)
    self.container = ParentContainer
    mainContainer = ParentContainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    parentPage:registerMessage(MSG_RECHARGE_SUCCESS)
    requesting = false

    for i = 1, 3 do
        local bg = ParentContainer:getVarSprite("mBGSprite" .. i)
        bg:setScale(NodeHelper:getScaleProportion())

        Content[i].init = false
    end

    if RechargeCfg == {} then
        --local msg = Recharge_pb.HPFetchShopList()
        --msg.platform = GameConfig.win32Platform
        --pb_data = msg:SerializeToString()
        --PacketManager:getInstance():sendPakcet(HP_pb.FETCH_SHOP_LIST_C, pb_data, #pb_data, true)
    else
        self:onStory(self.container)
    end

    self:refreshUI(ParentContainer)
end
function GrowthFundPage:refresh(container)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == GROWTH_DATA[nowPageType].goodsId[Current_Type] then
            itemInfo = RechargeCfg[i]
            break
        end
    end
    local scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()

    NodeHelper:setMenuItemsEnabled(container, { 
        mPlayer = (nowPageType ~= GROWTH_PAGE_TYPE.LEVEL), 
        mStory = (nowPageType ~= GROWTH_PAGE_TYPE.STAGE), 
        mTower = (nowPageType ~= GROWTH_PAGE_TYPE.TOWER) 
    })

    local currencyDatas = parentPage:updateCurrency()
    
    NodeHelper:setNodesVisible(container, { 
        mCost = (Content[nowPageType].costFlag[Current_Type] == false), 
        mBought = (Content[nowPageType].costFlag[Current_Type] == true), 
        mCoin = (Content[nowPageType].costFlag[Current_Type] == false) 
    })
    NodeHelper:setMenuItemsEnabled(container, { mBuy = (Content[nowPageType].costFlag[Current_Type] == false) })
    if (Content[nowPageType].costFlag[Current_Type] == false) and itemInfo then
        NodeHelper:setStringForLabel(container, { mCost = itemInfo.productPrice })
    end
    currCfg = { }
    for i, v in pairs(GROWTH_DATA[nowPageType].cfg) do
        if not v["type"] or v["type"] == Current_Type then
            table.insert(currCfg, v)
        end
    end

    for i, v in pairs(currCfg) do
        cell = CCBFileCell:create()
        cell:setCCBFile("GrowthBundleItem.ccbi")
        cell:setAnchorPoint(ccp(0.5, 0.5))
        cell:setContentSize(CCSize(cell:getContentSize().width, cell:getContentSize().height))
        local panel = common:new({id = v.id, index = i}, GrowthFundContent)
        cell:registerFunctionHandler(panel)
        scrollview:addCell(cell)
        local pos = ccp(0, cell:getContentSize().height * (#currCfg - i))
        cell:setPosition(pos)
    end
    local size = CCSizeMake(cell:getContentSize().width, cell:getContentSize().height * #currCfg)
    scrollview:setContentSize(size)
    if not currentScrollviewOffset then
        scrollview:setContentOffset(ccp(0, -cell:getContentSize().height * #currCfg + 605))
    else
        scrollview:setContentOffset(currentScrollviewOffset)
    end
    scrollview:forceRecaculateChildren()
end
function GrowthFundPage:refreshUI(container)
    local visibleMap = { }
    for i = 1, 3 do
        visibleMap["mTitle" .. i] = (nowPageType == i)
        visibleMap["mBGSprite" .. i] = (nowPageType == i)
        visibleMap["mIcon" .. i] = (nowPageType == i)
        visibleMap["mActive" .. i] = (nowPageType == i)
    end
    for i = 1, MAX_TYPE do
        visibleMap["mTypeNode" .. i] = (GROWTH_DATA[nowPageType].cfg[1]["type"] and GROWTH_DATA[nowPageType].goodsId[Current_Type] and (Current_Type == i)) and true or false
    end
    visibleMap["mPassed"] = (nowPageType ~= GROWTH_PAGE_TYPE.TOWER) and true or false
    
    NodeHelper:setNodesVisible(container, visibleMap)

    local string = ""
    if (nowPageType == GROWTH_PAGE_TYPE.LEVEL) then
        string = common:getLanguageString("@TotalPassLevel", UserInfo.roleInfo.level)
    elseif (nowPageType == GROWTH_PAGE_TYPE.STAGE) then
        local mapCfg = ConfigManager.getNewMapCfg()
        local chapter = mapCfg[UserInfo.stateInfo.passMapId].Chapter
        local level = mapCfg[UserInfo.stateInfo.passMapId].Level
        string = common:getLanguageString("@TotalPassStage", chapter .. "-" .. level)
    end
    NodeHelper:setStringForLabel(container, { mPassed = string })
end

function GrowthFundPage:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.GROWTH_PASS_BUY_SUCC_S then
        local msg = Activity5_pb.GrowthPassReq()
        msg.action = 0
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(GROWTH_DATA[nowPageType].package, pb, #pb, false)
        CCLuaLog(">>>>>>GROWTH_PASS_BUY_SUCC_S")
    elseif opcode == HP_pb.ACTIVITY162_Growth_LV_S or opcode == HP_pb.ACTIVITY163_Growth_CH_S or opcode == HP_pb.ACTIVITY164_Growth_TW_S then
        local msg = (opcode == HP_pb.ACTIVITY163_Growth_CH_S) and Activity5_pb.GrowthCHPassRes() or Activity5_pb.GrowthPassRes()
        msg:ParseFromString(msgBuff)
        Content[nowPageType].action = msg.action
        Content[nowPageType].costFlag = msg.costFlag
        Content[nowPageType].freeReward = msg.freeCfgId
        Content[nowPageType].costRewards = msg.costCfgId
        Content[nowPageType].init = true
        RewardSort()
        self:refresh(self.container)
        self:refreshUI(self.container)
        requesting = false
    elseif opcode == HP_pb.FETCH_SHOP_LIST_S then
        --local msg = Recharge_pb.HPShopListSync()
        --msg:ParseFromString(msgBuff)
        --RechargeCfg = msg.shopItems
        --self:onCurrentPage(self.container)
    elseif  opcode == HP_pb.PLAYER_AWARD_S then
       local PackageLogicForLua = require("PackageLogicForLua")
        PackageLogicForLua.PopUpReward(msgBuff)
    end
end
function RewardSort()
    local Free = { }
    local Cost = { }
    for i = 1, #GROWTH_DATA[nowPageType].cfg do
        Free[i] = 0
        Cost[i] = 0
    end
    for _, v in pairs(Content[nowPageType].freeReward) do
        Free[v] = v
    end
    for _, v in pairs(Content[nowPageType].costRewards) do
        Cost[v] = v
    end
    Content[nowPageType].freeReward = Free
    Content[nowPageType].costRewards = Cost
    if type(Content[nowPageType].costFlag) == "boolean" then
        Content[nowPageType].costFlag = { Content[nowPageType].costFlag }
    elseif type(Content[nowPageType].costFlag) == "table" then
        local costFlag = { }
        for i = 1, MAX_TYPE do
            table.insert(costFlag, false)
        end
        for i = 1, #Content[nowPageType].costFlag do
            costFlag[Content[nowPageType].costFlag[i]] = true
        end
        Content[nowPageType].costFlag = costFlag
    end
end
function GrowthFundPage:onBuy(container)
    local scrollview = container:getVarScrollView("mContent")
    currentScrollviewOffset = scrollview:getContentOffset() 
    BuyItem(GROWTH_DATA[nowPageType].goodsId[Current_Type])
end
function BuyItem(id)
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            itemInfo = RechargeCfg[i]
            break;
        end
    end
    local buyInfo = BUYINFO:new()
    buyInfo.productType = itemInfo.productType
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
    local _ratio = tostring(itemInfo.ratio)
    local extrasTable = {productType = _type, name = itemInfo.name, ratio = _ratio}
    buyInfo.extras = json.encode(extrasTable)
    
    BuyManager.Buy((UserInfo.playerInfo.playerId), buyInfo)
end
function GrowthFundPage:onExecute(container)

end

function GrowthFundPage:onExit(container)
    currentScrollviewOffset = nil
    parentPage:removePacket(opcodes)
    removeNotice = true
    sendReward = false

    PageManager.refreshPage("MainScenePage", "refreshInfo")
end
function GrowthFundPage:registerPacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end
function GrowthFundPage:removePacket(ParentContainer)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function GrowthFundPage:onCurrentPage(container)
    if not Content[nowPageType].init then
        local msg = Activity5_pb.GrowthPassReq()
        msg.action = 0
        local pb = msg:SerializeToString()
        PacketManager:getInstance():sendPakcet(GROWTH_DATA[nowPageType].package, pb, #pb, true)
    else
        self:refresh(self.container)
        self:refreshUI(self.container)
    end
end
function GrowthFundPage:onPlayer(container)
    nowPageType = GROWTH_PAGE_TYPE.LEVEL
    Current_Type = 1

    self:onCurrentPage(container)
end
function GrowthFundPage:onStory(container)
    nowPageType = GROWTH_PAGE_TYPE.STAGE
    Current_Type = 1

    self:onCurrentPage(container)
end
function GrowthFundPage:onTower(container)
    local isClose = true
    if isClose then
        MessageBoxPage:Msg_Box(common:getLanguageString("@WaitingOpen"))
        return
    end
    nowPageType = GROWTH_PAGE_TYPE.TOWER
    Current_Type = 1

    self:onCurrentPage(container)
end

function GrowthFundPage:onType1(container)
    Current_Type = 1
    self:refresh(self.container)
    self:refreshUI(self.container)
end

function GrowthFundPage:onType2(container)
    
    Current_Type = 2
    self:refresh(self.container)
    self:refreshUI(self.container)
end

function GrowthFundPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
	if typeId == MSG_RECHARGE_SUCCESS then
        CCLuaLog(">>>>>>onReceiveMessage GrowthFundPage")
        if not requesting then
		    local msg = Activity5_pb.GrowthPassReq()
            msg.action = 0
            local pb = msg:SerializeToString()
            PacketManager:getInstance():sendPakcet(GROWTH_DATA[nowPageType].package, pb, #pb, false)

            requesting = true
        end
	end
end

return GrowthFundPage
