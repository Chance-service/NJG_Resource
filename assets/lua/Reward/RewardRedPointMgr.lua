require("Util.LockManager")
local thisPageName="RewardRedPoint"
local RewardRedPoint={}

local option = {
    ccbiFile = "",
    handlerMap = {
    }
}
--召喚券紅點
local Summon900Point=false

function RewardRedPoint:FreeSummonRedPointSync(msg)
    local serverData = {}
    serverData.monthOfDay = msg.nowDay       
    serverData.signedDays = msg.takeDay
    
    if serverData.signedDays == serverData.monthOfDay then
        Summon900Point = false
    else
        if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.SUMMON_900) and serverData.signedDays ~= 90 then
            Summon900Point = true
        end
    end
    
    RewardRedPoint:RedPointControl()
end

--登入紅點
local DailyRedPoint=false

function RewardRedPoint:DailyLoginRedPoint(msg)
    local SeverData={}
    SeverData.monthOfDay = msg.monthOfDay
    SeverData.signedDays = { }
    for i = 1, #msg.signedDays do
        SeverData.signedDays[msg.signedDays[i]] = msg.signedDays[i]
    end
   
    for k,v in pairs (SeverData.signedDays) do
        if v==SeverData.monthOfDay then 
            DailyRedPoint=false
            return
        else
             DailyRedPoint=true
        end
    end
    

    RewardRedPoint:RedPointControl()
end


--紅點控制
function RewardRedPoint:RedPointControl()
    if Summon900Point or DailyRedPoint then
        NoticePointState.isChange=true
        NoticePointState.REWARD_POINT=true
    else
        NoticePointState.isChange=true
        NoticePointState.REWARD_POINT=false
    end
end

local CommonPage = require('CommonPage')
RewardRedPoint = CommonPage.newSub(RewardRedPoint, thisPageName, option)

return RewardRedPoint