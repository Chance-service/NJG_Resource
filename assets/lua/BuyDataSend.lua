
local Recharge_pb = require("Recharge_pb")
local BuyManager = require("BuyManager")
local thisPageName = "BuyDataSend"

local option = {
    ccbiFile = "",
    handlerMap = {
    }
}

local opcodes = {
        DISCOUNT_GIFT_INFO_S = HP_pb.DISCOUNT_GIFT_INFO_S,
}

local BuyDataSend={}

function BuyDataSend:registerPacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:registerPacket(opcode)
        end
    end
end

function BuyDataSend:removePacket(container)
    for key, opcode in pairs(opcodes) do
        if string.sub(key, -1) == "S" then
            container:removePacket(opcode)
        end
    end
end

function BuyDataSend:setCfg(data)
    RechargeCfg=data
end

function BuyDataSend:BuyItem(id)
    if RechargeCfg[1]==nil then return end
    local itemInfo = nil
    for i = 1, #RechargeCfg do
        if tonumber(RechargeCfg[i].productId) == id then
            itemInfo = RechargeCfg[i]
            break
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

local CommonPage = require('CommonPage')
BuyDataSend = CommonPage.newSub(BuyDataSend, thisPageName, option)

return BuyDataSend