local NodeHelper     = require("NodeHelper")
local Activity5_pb   = require("Activity5_pb")
local HP_pb          = require("HP_pb")
local CommonPage     = require("CommonPage")

local thisPageName   = 'SummonPickUpDataMgr'
local option = {
    ccbiFile   = "",
    handlerMap = {},
}

-- 儲存抽卡數據（建議用小寫開頭的局部變量）
local pickUpData = {}

local SummonPickUpDataBase = {}

-- 輔助函數：更新單個抽卡數據
local function updatePickUpData(info)
    if not info or not info.id then return end
    pickUpData[info.id] = {
        id             = info.id,
        leftTime       = info.leftTime,
        freeTimes      = info.freeTimes,
        onceCostGold   = info.onceCostGold,
        tenCostGold    = info.tenCostGold,
        leftAwardTimes = info.leftAwardTimes,
        ticket         = info.ticket,
        reward         = info.reward,
    }
end

-- 根據傳入的數據更新抽卡數據
function SummonPickUpDataBase_SetInfo(data)
    local targetId = data.id or 0
    if targetId == 0 then
        pickUpData = {}
    end

    for _, info in pairs(data.allInfo or {}) do
        if targetId == 0 or info.id == targetId then
            updatePickUpData(info)
            if targetId ~= 0 then
                break
            end
        end
    end

    local pickUpPage = require("Summon.SummonSubPage_PickUp")
    if pickUpPage and type(pickUpPage.initData) == "function" then
        pickUpPage:initData()
    end
end

-- 獲取抽卡數據
function SummonPickUpDataBase_getData()
    return pickUpData
end

-- 清空獎勵數據
function SummonPickUpDataBase_ClearReward()
    for _, data in pairs(pickUpData) do
        data.reward = {}
    end
end

-- 設置時間
function SummonPickUpDataBase_setTime(id,time)
    if pickUpData[id] then
        pickUpData[id].leftTime = time
    end
end

local SummonPickUpData = CommonPage.newSub(SummonPickUpDataBase, thisPageName, option)
return SummonPickUpData
