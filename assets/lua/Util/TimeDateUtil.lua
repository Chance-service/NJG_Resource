
--[[ 
    name: 時間日期工具 
    desc: 時間/日期相關
    author: youzi
    update: 2023/5/20 10:56
    description: 
        主要是使用 os.time(date) 把 日期 轉換為 時間 時，會強制將date當作區域日期。
        所以若要轉換utcDate -> utcTime，就需要先把utcDate轉換為localDate。
        區域時間 localTime 基本上不會從像是os.time中被取得，只會出現在計算過程中的特殊狀況。
--]]


local TimeDateUtil = {}

-- 轉換 ---------------------

--[[ 物件型 包裝 ]]
function TimeDateUtil:timeDate(time)
    local timeDate = {}
    
    timeDate.utcTime = time
    
    --[[ 取得 UTC時間 ]]
    function timeDate:getUTCTime ()
        return self.utcTime
    end
    --[[ 以 UTC時間 設置 ]]
    function timeDate:setUTCTime (time)
        timeDate.utcTime = time
    end

    --[[ 取得 UTC日期 ]]
    function timeDate:getUTCDate ()
        return TimeDateUtil:utcTime2Date(self.utcTime)
    end
    --[[ 以 UTC日期 設置 ]]
    function timeDate:setUTCDate (date)
        self.utcTime = TimeDateUtil:utcDate2Time(date)
    end

    --[[ 取得 區域日期 ]]
    function timeDate:getLocalDate ()
        return TimeDateUtil:utcTime2LocalDate(self.utcTime)
    end
    --[[ 以 區域日期 設置 ]]
    function timeDate:setLocalDate (date)
        self.utcTime = TimeDateUtil:localDate2UTCTime(date)
    end

    return timeDate
end

--[[ 取得 UTC到區域時區 的時間差距]]
function TimeDateUtil:getTimezoneOffset()
    return os.time() - os.time(os.date("!*t"))
end

--[[ 區域日期 轉換至 UTC日期 ]]
function TimeDateUtil:dateLocal2UTC (localDate)
    local utcTime = os.time(localDate) - self:getTimezoneOffset()
    return self:utcTime2Date()
end
--[[ 區域日期 轉換至 UTC時間 ]]
function TimeDateUtil:localDate2UTCTime (localDate)
    return os.time(localDate)
end

--[[ UTC時間 轉換至 UTC日期 ]]
function TimeDateUtil:utcTime2Date (utcTime)
    return os.date("!*t", utcTime)
end
--[[ UTC時間 轉換至 區域日期 ]]
function TimeDateUtil:utcTime2LocalDate (utcTime)
    return os.date("*t", utcTime)
end

--[[ UTC時間 進位整理 ]]
-- 例如 25時 61分 61秒 -> 1天 2時 2分 1秒
function TimeDateUtil:utcDateCarry (date)
    return self:utcTime2Date(self:utcDate2Time(date))
end

--[[ UTC日期 轉換至 區域日期 ]]
function TimeDateUtil:dateUTC2Local (utcDate)
    local utcTime = os.time(utcDate)
    return os.date("!*t", utcTime + self:getTimezoneOffset())
end
--[[ UTC日期 轉換至 UTC時間 ]]
function TimeDateUtil:utcDate2Time (utcDate)
    -- 基準日期
    local emptyDate = {year = 1970, month = 1, day = 1, hour = 0, min = 0, sec = 0}
    -- 時區差異 
    local timezoneOffset = self:getTimezoneOffset()
    -- 防錯補正時間 (多1天的時間 否則 轉換過程中若因為時區而出現小於0的時間會變成nil)
    local fixDayTimestamp = 86400

    local resDate = {}
    for k, v in pairs(emptyDate) do
        if utcDate[k] == nil then
            resDate[k] = emptyDate[k]
        else
            resDate[k] = utcDate[k]
        end
    end

    -- 添加 防錯補正 (多1天的時間)
    resDate.day = resDate.day + 1

    -- 轉換回區域時間後 +時區差異 -防錯補正 = UTC時間
    return os.time(resDate) + timezoneOffset - fixDayTimestamp
end


-- 取得 ---------------------

--[[ 可容許的誤差 ]]
TimeDateUtil.allowDiffClientServerTime_sec = 15

--[[ 取得安全client時間 (盡可能貼近Server時間) ]]
function TimeDateUtil:getClientSafeTime()
    local serverTime = GamePrecedure:getInstance():getServerTime()
    local systemTime = os.time()
    local overTime = systemTime - serverTime
    if overTime < 0 then
        return serverTime
    elseif overTime > self.allowDiffClientServerTime_sec then 
        return serverTime
    else
        return systemTime
    end
end

--[[ 取得 跨日時間 ]]
function TimeDateUtil:getNextDayUTCTime(utcOffset)
    if utcOffset == nil then utcOffset = 8 end

    local nextTime

    -- Client安全時間 (不差Server時間太多)
    local clientSafeTime = self:getClientSafeTime()

    -- 刷新日期 先設為 本地日期
    local nextDate = self:utcTime2LocalDate(clientSafeTime)
    
    -- 調整 刷新日期 為 以UTC+8而言 的 明天00h:00m
    nextDate.day = nextDate.day + 1
    nextDate.hour = 0
    -- nextDate.min = nextDate.min + 1 -- test
    nextDate.min = 0
    nextDate.sec = 0
    -- 調整 刷新日期 校正回UTC+0
    nextDate.hour = nextDate.hour - utcOffset

    nextTime = self:utcDate2Time(nextDate)

    return nextTime
end

return TimeDateUtil