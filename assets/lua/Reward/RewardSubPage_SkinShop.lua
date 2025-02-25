local NodeHelper = require("NodeHelper")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local Shop_pb = require("Shop_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local InfoAccesser = require("Util.InfoAccesser")
local NgHeadIconItem = require("NgHeadIconItem")
local thisPageName = 'IAPSubPage_SkinShop'
local SkinShop = {}
local _mercenaryInfos = {}
local scrollview = nil
local mCurHeroElement = 0
local BuyNode = nil
local SkinShopContent = {}

local HEAD_SCALE = 1
local headIconSize = CCSize(170 * HEAD_SCALE, 300 * HEAD_SCALE)
local ContentSize = {}
local Skins = {}
local SkinCoin = 0
local SeverData = {}



-----------------------------------------------
local option = {
    ccbiFile = "SkinShop.ccbi",
    handlerMap =
    {
        onHead = "onHead",
        onConfirmation = "onConfirmation"
    },
}
for i = 0, 5 do
    option.handlerMap["onElement" .. i] = "onElement" .. i
end
local opcodes = {
    DISCOUNT_GIFT_INFO_S = HP_pb.DISCOUNT_GIFT_INFO_S,
    DISCOUNT_GIFT_BUY_SUCC_S = HP_pb.DISCOUNT_GIFT_BUY_SUCC_S,
    DISCOUNT_GIFT_GET_REWARD_S = HP_pb.DISCOUNT_GIFT_GET_REWARD_S,
    SHOP_BUY_S = HP_pb.SHOP_BUY_S,
    SHOP_ITEM_S = HP_pb.SHOP_ITEM_S
}

function SkinShop:createPage(_parentPage)
    
    local slf = self
    
    parentPage = _parentPage
    
    local container = ScriptContentBase:create(option.ccbiFile)
    
    container:registerFunctionHandler(function(eventName, container)
        local funcName = option.handlerMap[eventName]
        local func = slf[funcName]
        if func then
            func(slf, container)
        end
    end)
    return container
end

function SkinShop:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SkinShop:onEnter(Parentcontainer)
    self.container = Parentcontainer
    parentPage:registerPacket(opcodes)
    parentPage:registerMessage(MSG_MAINFRAME_REFRESH)
    NgHeadIconItem_setPageType(GameConfig.NgHeadIconType.SKIN_PAGE)
    local element = 0
    for i = 0, 5 do
        Parentcontainer:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    Skins = {}
    self.mAllHeroItem = {}
    
    --self:refreshPage(Parentcontainer)
    local bg = Parentcontainer:getVarSprite("mBg")
    bg:setScale(NodeHelper:getScaleProportion())
    
    getShopList()
end
function SkinShop:refreshPage(container)
    local itemInfo = InfoAccesser:getUserItemInfo(Const_pb.TOOL, 6002)
    local count = itemInfo.count or 0
    NodeHelper:setStringForLabel(self.container, {mCoinCount = count})
    _mercenaryInfos.roleInfos = UserMercenaryManager:getMercenaryStatusInfos()
    if _mercenaryInfos.roleInfos == nil then
        return
    end
    local roleInfos = _mercenaryInfos.roleInfos
    sortData(roleInfos)
    scrollview = container:getVarScrollView("mContent")
    scrollview:removeAllCell()
    self:buildHeroScrollView(container)
end
function sortData(info)
    if info == nil or #info == 0 then
        return
    end
    table.sort(info, function(info1, info2)
        if info1 == nil or info2 == nil then
            return false
        end
        local mInfo = UserMercenaryManager:getUserMercenaryInfos()
        local mInfo1 = mInfo[info1.roleId]
        local mInfo2 = mInfo[info2.roleId]
        if mInfo1 == nil then
            return false
        end
        if mInfo2 == nil then
            return true
        end
        if mInfo1.starLevel ~= mInfo2.starLevel then
            return mInfo1.starLevel > mInfo2.starLevel
        elseif mInfo1.level ~= mInfo2.level then
            return mInfo1.level > mInfo2.level
        elseif mInfo1.fight ~= mInfo2.fight then
            return mInfo1.fight > mInfo2.fight
        elseif mInfo1.singleElement ~= mInfo2.singleElement then
            return mInfo1.singleElement < mInfo2.singleElement
        end
        return false
    end)
    local t = {}
    local FormationManager = require("FormationManager")
    local info = FormationManager:getMainFormationInfo()
    for i = 1, #info.roleNumberList do
        if info.roleNumberList[i] > 0 then
            local index = SkinShop:getMercenaryIndex(info.roleNumberList[i])
            if index > 0 then
                --local data = table.remove(_mercenaryInfos.roleInfos, index)
                --table.insert(t, data)
            end
        end
    end
    for k, v in pairs(_mercenaryInfos.roleInfos) do
        table.insert(t, v)
    end
    _mercenaryInfos.roleInfos = t
    return t
end
function SkinShop:getMercenaryIndex(roleId)
    local index = 0
    for i = 1, #_mercenaryInfos.roleInfos do
        if _mercenaryInfos.roleInfos[i].itemId == roleId then
            index = i
            break
        end
    end
    return index
end
function SkinShop:buildHeroScrollView(container)
    Skins = {}
    local cfg = ConfigManager.getSkinCfg()
    for i = 1, #cfg do
        if cfg[i].isShow == 1 then
            table.insert(Skins, cfg[i])
        end
    end
    table.sort(Skins, function(data1, data2)
        if data1 and data2 then
            return data1.Sort < data2.Sort
        else
            return false
        end
    end)
    local cell = nil
    local items = {}
    local roleId = 0
    for i = 1, #Skins do
        local itemId = Skins[i].HeroId
        for j = 1, #_mercenaryInfos.roleInfos do
            if _mercenaryInfos.roleInfos[j].itemId == itemId then
                roleId = _mercenaryInfos.roleInfos[j].roleId
            end
        end
        local iconItem = self:createCCBFileCell(roleId, i, scrollview)
        iconItem.itemId = itemId
        NgHeadIconItem:setRoleDataByItemId(iconItem)
        table.insert(items, iconItem)
    end
    self.mAllHeroItem = items
    scrollview:orderCCBFileCells()


end

function SkinShop:SetData(iconItem, itemId)
    iconItem.roleData = iconItem.roleData or {}
    local heroCfg = ConfigManager.getNewHeroCfg()[itemId]
    iconItem.roleData.element = heroCfg.Element
end

function SkinShop:createCCBFileCell(roleId, id, scrollView)
    local cell = CCBFileCell:create()
    cell:setCCBFile("SkinShopContent.ccbi")
    local handler = common:new({id = id, roleId = roleId}, SkinShopContent)
    cell:registerFunctionHandler(handler)
    scrollView:addCell(cell)
    ContentSize.width = cell:getContentSize().width
    ContentSize.height = cell:getContentSize().height
    
    return {cell = cell, handler = handler}
end
function SkinShopContent:onRefreshContent(ccbRoot)
    local container = ccbRoot:getCCBFileNode()
    self.container = container
    local count = Skins[self.id].Cost[1].count
    local skinName = common:getLanguageString(Skins[self.id].SkinName)
    local heroName = common:getLanguageString("@HeroName_" .. Skins[self.id].HeroId)
    local curRoleInfo = UserMercenaryManager:getUserMercenaryById(self.roleId)
    NodeHelper:setScale9SpriteImage2(self.container, {mIcon = "UI/RoleShowCards/Hero_" .. string.format("%02d", Skins[self.id].HeroId) .. string.format("%03d", Skins[self.id].HeroId) .. ".png"})
    NodeHelper:setStringForLabel(self.container, {mCost = count, mName = skinName, mHero = heroName})

    for i = 1, #SeverData do
        if SeverData[i].itemId==Skins[self.id].HeroId and SeverData[i].count==0 then
            NodeHelper:setMenuItemsEnabled(self.container, {mConfirmationBtn = false})
            return
        elseif SeverData[i].itemId==Skins[self.id].HeroId and SeverData[i].count==1 then
         NodeHelper:setMenuItemsEnabled(self.container, {mConfirmationBtn = true})
        --NodeHelper:setNodesVisible(container,{mGot=true,mCost=false,mCoin=false})
        --NodeHelper:setStringForLabel(container,{mGot=common:getLanguageString("@HasBuy")})
        end
    end
end
function SkinShopContent:onConfirmation()
    local itemInfo = InfoAccesser:getUserItemInfo(Const_pb.TOOL, 6002)
    if itemInfo.count < Skins[self.id].Cost[1].count then
        MessageBoxPage:Msg_Box(common:getLanguageString("@NotEnoughExchangeCoin"))
        return
    end
    local msg = Shop_pb.BuyShopItemsRequest();
    msg.type = 1
    msg.id = Skins[self.id].Item[1].itemId
    msg.amount = 1
    msg.shopType = Const_pb.SKIN_MARKET
    common:sendPacket(HP_pb.SHOP_BUY_C, msg, false)
end
function getShopList()
    local msg = Shop_pb.ShopItemInfoRequest()
    msg.type = Const_pb.INIT_TYPE
    msg.shopType = 16
    common:sendPacket(HP_pb.SHOP_ITEM_C, msg, true)
end
function SkinShopContent:onHead(container)
    --local rolePage = require("NgArchivePage")
    --NgArchivePage_setToSkin(true, 2)--從此頁面開啟會直接按skin按鈕 並傳2號skin
    --local mID = Skins[self.id].HeroId
    --rolePage:setMercenaryId(mID)
    --PageManager.pushPage("NgArchivePage")
end
function SkinShop:onElement0(container)
    local element = 0
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:onElement1(container)
    local element = 1
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:onElement2(container)
    local element = 2
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:onElement3(container)
    local element = 3
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:onElement4(container)
    local element = 4
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:onElement5(container)
    local element = 5
    mCurHeroElement = element
    self:setFilterVisible(container)
    for i = 0, 5 do
        container:getVarSprite("mElement" .. i):setVisible(element == i)
    end
    scrollview:orderCCBFileCells()
end
function SkinShop:setFilterVisible(container)
    
    if self.mAllHeroItem then
        for i = 1, #self.mAllHeroItem do
            local isVisible = (mCurHeroElement == self.mAllHeroItem[i].roleData.element or mCurHeroElement == 0)
            self.mAllHeroItem[i].cell:setVisible(isVisible)
            self.mAllHeroItem[i].cell:setContentSize(isVisible and CCSize(ContentSize.width, ContentSize.height) or CCSize(0, 0))
        end
    end
end

function SkinShop:onExit(container)
    parentPage:removePacket(opcodes)
    PageManager.popPage(thisPageName)
end
function SkinShop:onReceivePacket(packet)
    local opcode = packet.opcode
    local msgBuff = packet.msgBuff
    if opcode == HP_pb.SHOP_BUY_S then
        local msg = Shop_pb.BuyShopItemsResponse()
        msg:ParseFromString(msgBuff)
       for i = 1, #msg.data do
            table.insert(SeverData, {
                count = msg.data[i].amount,
                itemId = msg.itemInfo[i].itemId
            })
        end
        self:refreshPage(self.container)
    end
    if opcode == HP_pb.SHOP_ITEM_S then
        local msg = Shop_pb.ShopItemInfoResponse()
        msg:ParseFromString(msgBuff)
        for i = 1, #msg.data do
            table.insert(SeverData, {
                count = msg.data[i].amount,
                itemId = msg.itemInfo[i].itemId
            })
        end
        self:refreshPage(self.container)
    end
end
function SkinShop:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:registerPacket(opcode)
        end
    end
end
function SkinShop:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            ParentContainer:removePacket(opcode)
        end
    end
end
function SkinShop:onExecute(container)

end



return SkinShop
