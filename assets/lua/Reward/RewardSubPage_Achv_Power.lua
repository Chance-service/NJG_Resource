--[[ 
    name: RewardSubPage_Achv_Power
    desc: 獎勵 子頁面 成就 等級
    author: youzi
    update: 2023/7/11 17:21
    description:
         
--]]

-- 引用 ------------------

local NodeHelper = require("NodeHelper")
local TimeDateUtil = require("Util.TimeDateUtil")

--------------------------

--[[ 本體 ]]
local Inst = require("Reward.RewardSubPage_Achv_Base"):new()
function Inst:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--[[ 子頁面資訊 ]]
Inst.subPageName = "PowerAchv"

--[[ UI檔案 ]]
Inst.ccbiFile = "PowerAchievement.ccbi"

--[[ 到期時間 ]]
Inst.endTime = nil

--[[ 當 頁面 執行 ]]
Inst._Base_onExecute = Inst.onExecute
function Inst:onExecute()
    -- 呼叫 父類
    Inst._Base_onExecute()

    local clientTime = os.time()

    -- 免費補充剩餘時間
    local endLeftTime = -1

    -- 若 存在 到期時間
    if self.endTime ~= nil then
        -- 計算 到期剩餘時間
        endLeftTime = self.endTime - clientTime
        -- 小於0 視為 0
        if endLeftTime < 0 then endLeftTime = 0 end
    end

    -- 設置 到期剩餘時間
    self:setLeftTime(endLeftTime)

    -- 若 仍在冷卻 則 冷卻
    if self.requestCooldownLeft > 0 then
        self.requestCooldownLeft = self.requestCooldownLeft - 1
    end


    if self.endTime ~= nil then
        -- 若到期 
        if clientTime > self.endTime then
            -- 踢出頁面
            PageManager.popPage(self.parentPage.pageName)
        end
    end
end


--[[ 處理 回傳 ]]
Inst._Base_handle_QUEST_GET_ACTIVITY_LIST_S = Inst.handle_QUEST_GET_ACTIVITY_LIST_S
function Inst:handle_QUEST_GET_ACTIVITY_LIST_S (msgInfo)
    
    -- 設置 結束時間
    self.endTime = os.time() + msgInfo.leftTime

    -- 呼叫父類
    self._Base_handle_QUEST_GET_ACTIVITY_LIST_S(self, msgInfo)
end


--[[ 設置 剩餘時間 ]]
function Inst:setLeftTime (leftTime)

    local date = TimeDateUtil:utcTime2Date(leftTime)
    if date.sec > 0 then
        date.sec = 0
        date.min = date.min+1
    end
    date = TimeDateUtil:utcDateCarry(date)

    --dump(date, "date")

    NodeHelper:setStringForTTFLabel(self.container, {
        mTimerTxt = string.format(common:getLanguageString("@Reward.PowerAchv.leftTimeCounter"), date.day-1, date.hour, date.min)
    })
end

return Inst