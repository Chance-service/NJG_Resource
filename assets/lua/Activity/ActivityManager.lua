local ActivityManager = { }

ActivityType = {
    -- 限定
    Limit = 1,
    -- 扭蛋
    Gashapon = 2,
    -- 新手
    Novice = 3,
    -- 特典
    Privilege = 4
}

ActivityManager._activityType = ActivityType.Limit
ActivityManager._activityInfos = { }
ActivityManager.setActivityType = function(activityType)
    ActivityManager._activityType = activityType
end

ActivityManager.getActivityType = function()
    return ActivityManager._activityType
end

ActivityManager.setActivityInfo = function(activityId, msg)
    ActivityManager._activityInfos[activityId] = msg
end

ActivityManager.getActivityInfo = function(activityId)
    return ActivityManager._activityInfos[activityId]
end

return ActivityManager