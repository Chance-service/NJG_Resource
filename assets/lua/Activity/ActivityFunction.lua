local Activity3_pb = require("Activity3_pb")
local HP_pb = require("HP_pb")
local ActivityFunction = {}

ActivityFunction[5] = function()
   
end

--显示活动提示
function ActivityFunction:showAcivityId()
    local DoubleActivityDisplayCfg = ConfigManager.getDoubleActivityDisplayCfg()
    local showAllActivityInfo = {}
    for k = 1, #ActivityInfo.doubleIds do
        for i = 1, #DoubleActivityDisplayCfg do
            if DoubleActivityDisplayCfg[i].activityId == ActivityInfo.doubleIds[k] then
                table.insert(showAllActivityInfo, DoubleActivityDisplayCfg[i])
            end
        end
    end

    table.sort(showAllActivityInfo, function(a, b)
	if a.id > b.id then
                return false
	end
        return true
    end)
    return showAllActivityInfo
end

--是否有高速战斗消耗减半的活动
function ActivityFunction:isHaveHightSpeedBattle()
    local isHave = false
    for i = 1, #ActivityInfo.doubleIds do
        if ActivityInfo.doubleIds[i] == 19 then
            isHave = true
            break
        end
    end
    return isHave
end

--移除活动红点,传入活动的ID
function ActivityFunction:removeActivityRedPoint(activityId)
    local msg = Activity3_pb.RemoveSpecialRedPoint()
    msg.activityId = activityId
    common:sendPacket(HP_pb.REMOVE_SPECIAL_RED_POINT, msg, false)
end

return ActivityFunction