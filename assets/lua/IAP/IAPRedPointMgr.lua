local Activity5_pb = require("Activity5_pb")
local HP_pb = require("HP_pb")
local thisPageName="IAPRedPoint"
local IAPRedPoint={}

local option = {
    ccbiFile = "",
    handlerMap = {
    }
}
--日曆紅點
local PRPoint=false
local NRPoint=false
local CalendarPoint=false

function Calendar_sendNRInfo()
    local msg = Activity5_pb.SupportCalendarReq()
    msg.action = 0
    msg.type = 1
    common:sendPacket(HP_pb.SUPPORT_CALENDAR_ACTION_C, msg, false)
end

function Calendar_sendPRInfo()
    local msg = Activity5_pb.SupportCalendarReq()
    msg.action = 0
    msg.type = 2
    common:sendPacket(HP_pb.SUPPORT_CALENDAR_ACTION_C, msg, false)
end

function IAPRedPoint:ClaendarRedPointSync(msg)
     local serverData = {}
     serverData.isbuy = msg.buy
     serverData.signedDays = #msg.signedDays
     local curTime = common:getServerTimeByUpdate()
     local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
     local currentDay = curServerTime.day

     if serverData.isbuy then
         if serverData.signedDays == currentDay then
             if msg.type==1 then
                NRPoint=false
             elseif msg.type==2 then
                PRPoint=false
             end
         else
             if msg.type==1 then
                NRPoint=true
             elseif msg.type==2 then
                PRPoint=true
             end
         end
     end

     if NRPoint or PRPoint then 
        CalendarPoint=true
     else
        CalendarPoint=false
     end

     IAPRedPoint:RedPointControl()
end

--月卡紅點
local SmallPoint=false
local LargePoint=false
local MonthCardPoint=false

function IAPRedPoint:SmallMonthCardRedPointSync(msg)
    local SeverData={}
    SeverData.leftDays_Small = msg.leftDays
    if SeverData.leftDays_Small <= 0 then
        SeverData.leftDays_Small = 0
    end
    SeverData.isTodayRewardGot_Small = msg.isTodayRewardGot
    SeverData.isMonthCardUser_Small = (SeverData.leftDays_Small > 0)

    if SeverData.isMonthCardUser_Small then
        if not SeverData.isTodayRewardGot_Small then
            SmallPoint=true
        else
            SmallPoint=false
        end
    end

    if SmallPoint or LargePoint then
        MonthCardPoint=true
    else
        MonthCardPoint=false
    end
    IAPRedPoint:RedPointControl()
end

function IAPRedPoint:LargeMonthCardRedPointSync(msg)
    local SeverData={}
     SeverData.leftDays_Large = msg.leftDays
     if SeverData.leftDays_Large <= 0 then
         SeverData.leftDays_Large = 0
     end
     SeverData.isMonthCardUser_Large = (SeverData.leftDays_Large > 0)
     if SeverData.isMonthCardUser_Large then
         SeverData.isTodayRewardGot_Large = (msg.isTodayReward==1)
     else
         SeverData.isTodayRewardGot_Large = false
     end

     if SeverData.isMonthCardUser_Large then
        if not SeverData.isTodayRewardGot_Large then
            LargePoint=true
        else
            LargePoint=false
        end
     end

     if SmallPoint or LargePoint then
        MonthCardPoint=true
     else
        MonthCardPoint=false
     end
     IAPRedPoint:RedPointControl()
end

--紅點控制
function IAPRedPoint:RedPointControl()
    if CalendarPoint or MonthCardPoint then
        NoticePointState.isChange=true
        NoticePointState.IAP_POINT=true
    else
        NoticePointState.isChange=true
        NoticePointState.IAP_POINT=false
    end
end

local CommonPage = require('CommonPage')
IAPRedPoint = CommonPage.newSub(IAPRedPoint, thisPageName, option)

return IAPRedPoint