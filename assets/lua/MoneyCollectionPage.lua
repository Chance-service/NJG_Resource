local HP_pb = require("HP_pb")-- 包含协议id文件
local thisPageName = "MoneyCollectionPage"
local CoinCfg = ConfigManager.ShopBuyCoin()
local CoinLvCfg = ConfigManager.ShopBuyCoinLv()
local rewadItems = {}
local buyCount = 1
local BuyLimit = 0

----这里是协议的id
local opcodes = {
    SHOP_BUY_S = HP_pb.SHOP_BUY_S,
    SHOP_ITEM_S = HP_pb.SHOP_ITEM_S
}

local option = {
    ccbiFile = "MoneyCollection.ccbi",
    handlerMap = {
        -- 按钮点击事件
        onClose = "onClose",
        onBuy = "onBuy",
        onHelp="onHelp"
    },
    opcode = opcodes
}

local MoneyCollectionBase = {}
function MoneyCollectionBase:onEnter(container)
    self:registerPacket(container)
    self.container=container
    local DiamondCount = 0
    local CoinCount = 0
    NodeHelper:setStringForLabel(container, {mDiamond = DiamondCount, mCoin = CoinCount,mBtn=common:getLanguageString("@buy")})
    BuyLimit = ConfigManager.getVipCfg()[UserInfo.playerInfo.vipLevel].buyCoinTime
    if (BuyLimit == nil) then BuyLimit = 0 end
    self:getInfo()
end
function MoneyCollectionBase:onClose(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
    if container.scrollview then
        container.scrollview:removeAllCell()
        container.scrollview = nil
    end
    PageManager.popPage(thisPageName)
end
function MoneyCollectionBase:onBuy()
    local msg = Shop_pb.BuyShopItemsRequest();
    msg.type = 1
    msg.shopType = 2
    common:sendPacket(HP_pb.SHOP_BUY_C, msg, false)
end
function MoneyCollectionBase:getInfo()
    local msg = Shop_pb.ShopItemInfoRequest()
    msg.type = 1
    msg.shopType = 2
    common:sendPacket(HP_pb.SHOP_ITEM_C, msg, true)
end
function MoneyCollectionBase:PlayAnim(container, index)
    local spinePath = "Spine/NGUI"
    local spineName = "NGUI_09_Coin"
    local spine = SpineContainer:create(spinePath, spineName)
    local spineNode = tolua.cast(spine, "CCNode")
    local parentNode = container:getVarNode("mSpine")
    
    parentNode:removeAllChildrenWithCleanup(true)
    
    local CoinAnim01 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1, "normal", 0)
    end)
    
    local CoinAnim02 = CCCallFunc:create(function()
        parentNode:addChild(spineNode)
        spine:runAnimation(1, "extra", 0)
    end)
    
    local clear = CCCallFunc:create(function()
        parentNode:removeAllChildrenWithCleanup(true)
    end)
    
    local array = CCArray:create()
    
    array:addObject(CCDelayTime:create(0.2))
    
    if (index == 1) then
        array:addObject(CoinAnim01)
    else
        array:addObject(CoinAnim02)
    end
    
    array:addObject(CCDelayTime:create(2))
    array:addObject(clear)
    parentNode:runAction(CCSequence:create(array))
end
function MoneyCollectionBase:refresh(container)
    NodeHelper:setStringForLabel(self.container, {mDiamond = rewadItems.Price, mCoin = rewadItems.count,mTimes=common:getLanguageString("@ShopCount",rewadItems.data)})
    if rewadItems.data==0 then
        NodeHelper:setMenuItemsEnabled(self.container,{mBuy=false})
    end
--local award = {}
--table.insert(award,{type=10000,count=rewadItems.count,itemId=1002})
-- local CommonRewardPage = require("CommPop.CommItemReceivePage")
--CommonRewardPage:setData(award, common:getLanguageString("@ItemObtainded"), nil)
--PageManager.pushPage("CommPop.CommItemReceivePage")
end
function MoneyCollectionBase:onExit(container)
    self:removePacket(container)
    onUnload(thisPageName, container)
    PageManager.popPage(thisPageName)

    local GuideManager = require("Guide.GuideManager")
    if GuideManager.currGuide[GuideManager.guideType.NEWBIE_GUIDE] ~= 0 then
        local guideCfg = GuideManager.getStepCfgByIndex(GuideManager.currGuideType, GuideManager.getCurrentStep())
        if guideCfg and guideCfg.showType == 8 then
            GuideManager.forceNextNewbieGuide()
        end
    end
end



function MoneyCollectionBase:onReceivePacket(container)
    
    local opcode = container:getRecPacketOpcode()
    local msgBuff = container:getRecPacketBuffer()
    if (opcode == HP_pb.SHOP_BUY_S) then
        local msg = Shop_pb.BuyShopItemsResponse()
        msg:ParseFromString(msgBuff)
        --rewadItems.count = msg.itemInfo[1].count
        --rewadItems.Price = msg.itemInfo[1].price
        rewadItems.data = msg.data[1].amount
        rewadItems.isDouble = msg.isDouble[1]
        
        if (rewadItems.isDouble) then
            self:PlayAnim(container, 2)
        else
            self:PlayAnim(container, 1)
        end
        MoneyCollectionBase:getInfo()
    end
    if (opcode == HP_pb.SHOP_ITEM_S) then
        local msg = Shop_pb.ShopItemInfoResponse()
        msg:ParseFromString(msgBuff)
        rewadItems.count = msg.itemInfo[1].count
        rewadItems.Price = msg.itemInfo[1].price
        rewadItems.data = msg.data[1].amount
    end
    self:refresh(container)
end

function MoneyCollectionBase:onReceiveMessage(container)
    local message = container:getMessage()
    local typeId = message:getTypeId()
    if typeId == MSG_SEVERINFO_UPDATE then
        -- 这里有好多消息类型
        local opcode = MsgSeverInfoUpdate:getTrueType(message).opcode
        
        if opcode == HP_pb.HEAD_FRAME_STATE_INFO_S then
            end
    end
end

function MoneyCollectionBase:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function MoneyCollectionBase:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function MoneyCollectionBase:onHelp(container)
     PageManager.showHelp(GameConfig.HelpKey.HELP_MONEYCOLLECTION)
end

local CommonPage = require("CommonPage")
local MoneyCollectionPage = CommonPage.newSub(MoneyCollectionBase, thisPageName, option)

return MoneyCollectionPage
