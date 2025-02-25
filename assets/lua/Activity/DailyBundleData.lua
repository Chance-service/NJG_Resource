local NodeHelper = require("NodeHelper")
local thisPageName = 'DailyBundleDataBase'
local Activity5_pb = require("Activity5_pb");
local HP_pb = require("HP_pb");

local DailyBundleDataBase = {}

local PageInfo={
    VIP_EXP = 0,
    ReceivedItem={ },
    GetReward = { },
}

local option = {
    handlerMap = {},
}



function DailyBundleBase_SetInfo(msg)
    PageInfo.VIP_EXP = msg.rechargeTotal
    PageInfo.ReceivedItem = msg.gotAwardCfgId
    PageInfo.GetReward = msg.reward
end

function DailyBundleDataBase:getData()
    return PageInfo
end

function DailyBundleDataBase:isGetAll()
    return #PageInfo.ReceivedItem == 3 
end




local CommonPage = require('CommonPage')
DailyBundleData = CommonPage.newSub(DailyBundleDataBase, thisPageName, option)

return DailyBundleData
