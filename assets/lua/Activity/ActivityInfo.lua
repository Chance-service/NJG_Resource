local Activity_pb = require("Activity_pb")
local Activity2_pb = require("Activity2_pb")
local HP_pb = require("HP_pb")
local Const_pb = require("Const_pb")
local MainScenePage = require("MainScenePage")
local Event = require("Util.Event")
require("Activity.ActivityConfig")

ActivityInfo = {
    closeId = 99999,
    -- ‘敬请期待’伪活动id
    ids = { },
    -- 这个就存一些个别的活动吧
    -- 活动id
    OtherPageids = { },
    -- 其他页面显示的活动id-------------特权里面的
    OtherPageTotalReward = 0,
    -- 其他页面总共有多少奖励可领-------------庆典页面
    OtherPageRewardCount = { },
    -- 活动界面有多少奖励可领，用于红点-------------庆典页面
    NiuDanPageIds = { 101, 90, 86, 36 },
    -- 扭蛋页面活动id
    NovicePageIds = { 82, 3 },
    -- 新手9級活動id
    NewPlayerLevel9Ids = { },
    -- 彈跳禮包活動id
    PopUpSaleIds = { },
    -- 新手登入活動
    NewPlayerLogin = { },
    -- 限定活动id
    LimitPageIds = { },
    -- 活跃度活动id
    LivenessIds = { },
    NewPageids = { },
    -- 新活动类型id
    NewPageidsRewardCount = { },
    RewardIds = { },
    NoticeInfo = {
        limitAct = { },
        commonAct = { },
        OtherPageids = { },
        NovicePageIds = { },
        NiuDanPageIds = { },
        LimitPageIds = { },
        NewPlayerLevel9Ids = { },
        PopUpSaleIds = { },
        NewPlayerLogin = { },
        RewardIds = { },
        LivenessIds = { },
        ids = { }
    },
    rewardCount = { },
    -- 活动界面有多少奖励可领，用于红点
    newCount = 0,
    -- 新活动个数
    totalReward = 0,
    -- 活动界面总共有多少奖励可领
    activities = { },
    -- 活动数据，主要是version
    cache = { },
    allIds = { },
    -- 服务器同步下来的所有活动id
    doubleIds = { },
    -- 一些双倍经验等活动，不显示在活动列表的
    shootActivityRewardState = 1,-- 打靶活动的奖池状态(1:奖池1,2:奖池2)
    
    -- 更新事件
    onUpdate = Event:new(),
}
local TodoTrue = false
local isFirstEnter = false -- vip福利活动 可领取奖励后 第一次进入页面
local m_sScheduleTimeKey = "ActivitySyncTimeLimits" -- 如果在1秒内接收到多次，return掉
local m_nScheduleTime = 1
--------------------------------------------------------------------------------
------------local variable for system api--------------------------------------
local tostring = tostring
local tonumber = tonumber
local string = string
local pairs = pairs
--------------------------------------------------------------------------------
-- 同步活动列表
function onActivityOpenSync(eventName, handler)
    -- 如果在1秒内接收到多次，return掉
    if TimeCalculator:getInstance():hasKey(m_sScheduleTimeKey) and
       TimeCalculator:getInstance():getTimeLeft(m_sScheduleTimeKey) ~= 0 then
        return
    end

    local UserInfo = require("PlayerInfo.UserInfo")
    if eventName == "luaReceivePacket" then
        local msg = Activity_pb.HPOpenActivitySyncS()
        msg:ParseFromString(handler:getRecPacketBuffer())
        -- 20190524
        if not GameConfig.isIOSAuditVersion then
            checkServerVersion()
        end

        UserInfo.syncPlayerInfo()
        ActivityInfo.NovicePageIds = { }
        -- 新手活动
        ActivityInfo.NiuDanPageIds = { }
        -- 扭蛋里面的活动
        ActivityInfo.NewPlayerLevel9Ids = { }
        ActivityInfo.PopUpSaleIds = { }
        ActivityInfo.NewPlayerLogin = { }
        ActivityInfo.RewardIds = { }
        ActivityInfo.LimitPageIds = { }
        -- 限定活动
        ActivityInfo.rewardCount = { }
        ActivityInfo.LivenessIds = { }
        ActivityInfo.totalReward = 0
        ActivityInfo.newCount = 0
        ActivityInfo.OtherPageids = { }
        ActivityInfo.NewPageids = { }
        ActivityInfo.ids = { }
        ActivityInfo.OtherPageTotalReward = 0
        -- 其他页面总共有多少奖励可领
        ActivityInfo.OtherPageRewardCount = { }
        -- 活动界面有多少奖励可领，用于红点
        ActivityInfo.allIds = { }
        ActivityInfo.NewPageidsRewardCount = { }

        local hasNew = false
        local ids = { }
        local activities = { }
        local doubleIds = { }
        for _, activity in ipairs(msg.activity) do
            local id = activity.activityId
            table.insert(ActivityInfo.allIds, id)
            if ActivityConfig[id] ~= nil then
                local actInfo = ActivityInfo.activities[id] or { }
                local oldVersion = actInfo.version
                local newVersion = math.max(activity.stageId, 1)
                if oldVersion == nil then
                    local key = string.format("Activity_%d_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId, id)
                    oldVersion = CCUserDefault:sharedUserDefault():getIntegerForKey(key) or 0
                end

                -- 是否是新活动，或者是新的一期活动
                local isNew = oldVersion < newVersion
                if isNew and id ~= 19 then
                    hasNew = true
                    ActivityInfo.newCount = ActivityInfo.newCount + 1
                end
                activities[id] = {
                    version = oldVersion,
                    newVersion = newVersion,
                    isNew = isNew
                }
                table.insert(ids, id)
            else
                local confManager = require("ConfigManager")
                local loginCfg = confManager.getMainActivityShowCfg()
                local cfg = loginCfg[id]
                if cfg then
                    table.insert(doubleIds, id)
                end
            end
        end
        ActivityInfo.doubleIds = doubleIds
        -- 如果活动开启，消耗钻石减半
        if common:table_hasValue(ids, 19) then
            GlobalData.diamondRatio = 0.5
            ids = common:table_removeFromArray(ids, 19)
            table.remove(activities, 19)
        else
            GlobalData.diamondRatio = nil
        end

        -- 检测现有活动中是否有已经关闭的
        for id, _ in pairs(ActivityInfo.activities) do
            if id ~= ActivityInfo.closeId and activities[id] == nil then
                local pageName = ActivityConfig[id]["page"] or ""
                if pageName == MainFrame:getInstance():getCurShowPageName() then
                    MessageBoxPage:Msg_Box_Lan("@CurrentActivityIsClosed")
                    -- PageManager.changePage("ActivityPage");
                end
            end
        end

        ActivityInfo.activities = activities


        table.sort(ids, function(id_1, id_2)
            local order_1 = ActivityConfig[id_1]["order"] or 99999;
            local order_2 = ActivityConfig[id_2]["order"] or 99999;

            if order_1 ~= order_2 then
                return order_1 < order_2
            end
            return id_1 < id_2
        end )

        -- 至少XX个活动，不够显示“敬请期待”
        -- for i = #ids + 1, GameConfig.Count.MinActivity do
        -- 	table.insert(ids, ActivityInfo.closeId);
        -- end
        for i = 1, #ids do
            if ActivityConfig[ids[i]] then
                if ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 1 then
                    -- 特典里面的
                    table.insert(ActivityInfo.OtherPageids, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 2 then
                    table.insert(ActivityInfo.NewPageids, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 3 then

                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 4 then
                    -- 新手活动
                    table.insert(ActivityInfo.NovicePageIds, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 5 then
                    -- 扭蛋里面的活动
                    if ActivityInfo.isAdd(ids[i]) then
                        table.insert(ActivityInfo.NiuDanPageIds, ids[i])
                    end
                    --                    if ids[i] == 127 then
                    --                        if UserInfo.roleInfo.level >= 85 then
                    --                            table.insert(ActivityInfo.NiuDanPageIds, ids[i])
                    --                        end
                    --                    else
                    --                        table.insert(ActivityInfo.NiuDanPageIds, ids[i])
                    --                    end

                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 6 then
                    -- 限定活动
                    if ActivityConfig[ids[i]].isTimeLimitLuckDrawCard then
                        -- 如果是限定活动抽卡  添加到扭蛋列表里面
                        table.insert(ActivityInfo.NiuDanPageIds, ids[i])
                    end
                    table.insert(ActivityInfo.LimitPageIds, ids[i])
                    -- table.insert(ActivityInfo.ids, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == ACTIVITY_TYPE.NEWPLAYER_LEVEL9 then
                    -- 新手等級9開啟活動
                    table.insert(ActivityInfo.NewPlayerLevel9Ids, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == ACTIVITY_TYPE.POPUP_SALE then
                    -- 彈跳禮包開啟活動
                    table.insert(ActivityInfo.PopUpSaleIds, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == ACTIVITY_TYPE.NEWPLAYER_LOGIN then
                    -- 新手登入開啟活動
                    table.insert(ActivityInfo.NewPlayerLogin, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == ACTIVITY_TYPE.REWARD then
                    -- 福袋活動
                    table.insert(ActivityInfo.RewardIds, ids[i])
                elseif ActivityConfig[ids[i]].activityType and ActivityConfig[ids[i]].activityType == 100 then
                    -- 活跃度
                    table.insert(ActivityInfo.LivenessIds, ids[i])
                else
                    table.insert(ActivityInfo.ids, ids[i])
                end
            end
        end

        local activitySortConfig = ConfigManager.getActivitySortCfg()

        --        -- 限定
        --        table.sort(ActivityInfo.LimitPageIds, function(id1, id2)
        --            if ActivityConfig[id1].order < ActivityConfig[id2].order then
        --                return true
        --            end
        --        end )

        --        --扭蛋
        --        table.sort(ActivityInfo.NiuDanPageIds, function(id1, id2)
        --            if ActivityConfig[id1].order < ActivityConfig[id2].order then
        --                return true
        --            end
        --        end )

        -- 限定
        table.sort(ActivityInfo.LimitPageIds, function(id1, id2)
		local data1 = activitySortConfig[id1]
                local data2 = activitySortConfig[id2]
                if data1 and data2 then
                    if data1.order < data2.order then
                        return true
                    end
                end
            end )

        -- 扭蛋
        table.sort(ActivityInfo.NiuDanPageIds, function(id1, id2)
                local data1 = activitySortConfig[id1]
                local data2 = activitySortConfig[id2]
                if data1 and data2 then
                    if data1.order < data2.order then
                        return true
                    end
                end
            end)

        -- 新手
        table.sort( ActivityInfo.NovicePageIds, function(id1, id2)
                local data1 = activitySortConfig[id1]
                local data2 = activitySortConfig[id2]
                if data1 and data2 then
                    if data1.order < data2.order then
                        return true
                    end
                end
            end )

        -- 特典
        table.sort( ActivityInfo.OtherPageids, function(id1, id2)
                local data1 = activitySortConfig[id1]
                local data2 = activitySortConfig[id2]
                if data1 and data2 then
                    if data1.order < data2.order then
                        return true
                    end
                end
            end )

        if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
            --table.insert(ActivityInfo.NiuDanPageIds, 139)
        end

        -- 临时先这么排序  后面用-----
        --        local t = { }
        --        for i = #ActivityInfo.NiuDanPageIds, 0, -1 do
        --            table.insert(t, ActivityInfo.NiuDanPageIds[i])
        --        end
        --        ActivityInfo.NiuDanPageIds = t


        -- ActivityInfo.ids = ids;
        -- table.insert(ActivityInfo.ids, 103);
        -- table.insert(ActivityInfo.ids, 102);

        PageManager.refreshPage("MainScenePage", "updateActivity")
        PageManager.refreshPage("ActivityPage")

        -- 發送 更新事件
        ActivityInfo.onUpdate:emit()
    end
    --
    TimeCalculator:getInstance():createTimeCalcultor(m_sScheduleTimeKey, m_nScheduleTime)
end

ActivityListen = PacketScriptHandler:new(HP_pb.OPEN_ACTIVITY_SYNC_S, onActivityOpenSync)


-- OtherPageids = 1   NovicePageIds = 4  NiuDanPageIds = 5  LimitPageIds = 6

function onActivityNoticeSync(eventName, handler)
    local UserInfo = require("PlayerInfo.UserInfo")
    if eventName == "luaReceivePacket" then
        local msg = Activity2_pb.HPRedPointInfo()
        msg:ParseFromString(handler:getRecPacketBuffer())
        if ActivityInfo.NoticeInfo == nil then
            ActivityInfo.NoticeInfo = { }
        end
        ActivityInfo.NoticeInfo.limitAct = { }
        ActivityInfo.NoticeInfo.commonAct = { }

        ActivityInfo.NoticeInfo.OtherPageids = { }
        ActivityInfo.NoticeInfo.NovicePageIds = { }
        ActivityInfo.NoticeInfo.NiuDanPageIds = { }
        ActivityInfo.NoticeInfo.LimitPageIds = { }
        ActivityInfo.NoticeInfo.NewPlayerLevel9Ids = { }
        ActivityInfo.NoticeInfo.PopUpSaleIds = { }
        ActivityInfo.NoticeInfo.NewPlayerLogin = { }
        ActivityInfo.NoticeInfo.RewardIds = { }
        ActivityInfo.NoticeInfo.LivenessIds = { }
        ActivityInfo.NoticeInfo.ids = { }
        local activityId = 1
        for i = 1, #msg.pointActivityIdList do
            activityId = tonumber(msg.pointActivityIdList[i])
            if ActivityConfig[activityId] then
                if ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 1 then
                    ActivityInfo.NoticeInfo.OtherPageids[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 4 then
                    ActivityInfo.NoticeInfo.NovicePageIds[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 5 then


                    if ActivityInfo.isAdd(activityId) then
                        ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                        PageManager.showRedNotice("Guild", true)
                    end

                    --                    if activityId == 127 then
                    --                        if UserInfo.roleInfo.level >= 85 then
                    --                            ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                    --                            PageManager.showRedNotice("Guild", true)
                    --                        end
                    --                    else
                    --                        ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                    --                        PageManager.showRedNotice("Guild", true)
                    --                    end


                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 6 then
                    ----------
                    if ActivityConfig[activityId].isTimeLimitLuckDrawCard then
                        ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                        PageManager.showRedNotice("Guild", true)
                    end
                    ----------
                    if activityId ~= 26 then
                        -- 不要超学园祭红点
                        ActivityInfo.NoticeInfo.LimitPageIds[activityId] = true
                    end
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.REWARD then
                    ActivityInfo.NoticeInfo.RewardIds[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 100 then
                    -- 活跃度
                    ActivityInfo.NoticeInfo.LivenessIds[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.NEWPLAYER_LEVEL9 then
                    -- 新手lv9活動
                    ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.POPUP_SALE then
                    -- 彈跳禮包
                    ActivityInfo.NoticeInfo.PopUpSaleIds[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.NEWPLAYER_LOGIN then
                    -- 新手登入
                    ActivityInfo.NoticeInfo.NewPlayerLogin[activityId] = true
                else
                    -- 其他活动
                    ActivityInfo.NoticeInfo.ids[activityId] = true
                end
            end

        end
        dump(ActivityInfo.NoticeInfo)
        -- ActivityInfo:showNotice(common:table_count(ActivityInfo.NoticeInfo.commonAct) > 0)

        PageManager.refreshPage("LimitActivityPage", "activityNoticeInfo")
        PageManager.refreshPage("GashaponPage", "activityNoticeInfo")
        PageManager.refreshPage("WelfarePage", "activityNoticeInfo")
        PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")

    end
end

function onActivityNoticeSigleSync(eventName, handler)
    local UserInfo = require("PlayerInfo.UserInfo")
    if eventName == "luaReceivePacket" then
        local msg = Activity2_pb.HPRedPointInfo()
        msg:ParseFromString(handler:getRecPacketBuffer())
        local activityId = 1
        for i = 1, #msg.pointActivityIdList do
            activityId = tonumber(msg.pointActivityIdList[i])
            if ActivityConfig[activityId] then
                if ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 1 then
                    ActivityInfo.NoticeInfo.commonAct[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 100 then
                    ActivityInfo.NoticeInfo.LivenessIds[activityId] = true
                elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 5 then
                    if ActivityInfo.isAdd(activityId) then
                        ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                        PageManager.showRedNotice("Guild", true)
                    end
                    --                    if activityId == 127 then
                    --                        if UserInfo.roleInfo.level >= 85 then
                    --                            ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                    --                            PageManager.showRedNotice("Guild", true)
                    --                        end
                    --                    else
                    --                        ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = true
                    --                        PageManager.showRedNotice("Guild", true)
                    --                    end

                else
                    -- 其他活动
                    ActivityInfo.NoticeInfo.ids[activityId] = true
                    -- ActivityInfo.NoticeInfo.limitAct[activityId] = true
                end
            end
        end
        dump(ActivityInfo.NoticeInfo)
        ActivityInfo:showNotice(common:table_count(ActivityInfo.NoticeInfo.commonAct) > 0)
        PageManager.refreshPage("LimitActivityPage", "activityNoticeInfo")
        PageManager.refreshPage("GashaponPage", "activityNoticeInfo")
        PageManager.refreshPage("WelfarePage", "activityNoticeInfo")
        PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
    end
end


function ActivityInfo.isAdd(activityId)
    local activityId = tonumber(activityId)
    local UserInfo = require("PlayerInfo.UserInfo")
    local bl = false
    if activityId == 127 or activityId == 125 then
        -- 活动127 125 ， 85级开入口
        if UserInfo.roleInfo then 
             bl = false--tonumber(UserInfo.roleInfo.level) >= 85
        end 
        
        --        if UserInfo.roleInfo.level >= 85 then
        --            bl = true
        --        end
    else
        bl = true
    end

    return bl
end

function ActivityInfo.changeActivityNotice(activityId, notice)
    local activityId = tonumber(activityId)
    if ActivityConfig[activityId] == nil then
        return
    end

    if ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 1 then
        if ActivityInfo.NoticeInfo.OtherPageids[activityId] and not notice then
            ActivityInfo.NoticeInfo.OtherPageids[activityId] = nil
            PageManager.refreshPage("WelfarePage", "activityNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 4 then
        if ActivityInfo.NoticeInfo.NovicePageIds[activityId] and not notice then
            ActivityInfo.NoticeInfo.NovicePageIds[activityId] = nil
            PageManager.refreshPage("LimitActivityPage", "activityNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 5 then
        if ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] and not notice then
            ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = nil
            PageManager.refreshPage("GashaponPage", "activityNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 6 then
        if ActivityInfo.NoticeInfo.LimitPageIds[activityId] and not notice then
            -----------------------------------------------------------------
            if ActivityConfig[activityId].isTimeLimitLuckDrawCard then
                ActivityInfo.NoticeInfo.NiuDanPageIds[activityId] = nil
                PageManager.refreshPage("GashaponPage", "activityNoticeInfo")
            end
            -----------------------------------------------------------------
            ActivityInfo.NoticeInfo.LimitPageIds[activityId] = nil
            PageManager.refreshPage("LimitActivityPage", "activityNoticeInfo")
        end

    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.NEWPLAYER_LEVEL9 then
        if ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[activityId] and not notice then
            ActivityInfo.NoticeInfo.NewPlayerLevel9Ids[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.POPUP_SALE then
        if ActivityInfo.NoticeInfo.PopUpSaleIds[activityId] and not notice then
            ActivityInfo.NoticeInfo.PopUpSaleIds[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.NEWPLAYER_LOGIN then
        if ActivityInfo.NoticeInfo.NewPlayerLogin[activityId] and not notice then
            ActivityInfo.NoticeInfo.NewPlayerLogin[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == ACTIVITY_TYPE.REWARD then
        if ActivityInfo.NoticeInfo.RewardIds[activityId] and not notice then
            ActivityInfo.NoticeInfo.RewardIds[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    elseif ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 100 then
        if ActivityInfo.NoticeInfo.LivenessIds[activityId] and not notice then
            ActivityInfo.NoticeInfo.LivenessIds[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    else
        if ActivityInfo.NoticeInfo.ids[activityId] and not notice then
            ActivityInfo.NoticeInfo.ids[activityId] = nil
            PageManager.refreshPage("MainScenePage", "showNodeNoticeInfo")
        end
    end


    if ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 1 then

    end

    if ActivityConfig[activityId].activityType and ActivityConfig[activityId].activityType == 1 then
        if ActivityInfo.NoticeInfo.commonAct[activityId] and not notice then
            ActivityInfo.NoticeInfo.commonAct[activityId] = nil
            PageManager.refreshPage("WelfarePage", "activityNoticeInfo")
            if common:table_count(ActivityInfo.NoticeInfo.commonAct) == 0 then
                ActivityInfo:showNotice(false)
            end
        else
            -- todo
        end
    else
        if ActivityInfo.NoticeInfo.limitAct[activityId] and not notice then
            ActivityInfo.NoticeInfo.limitAct[activityId] = nil
            PageManager.refreshPage("LimitActivityPage", "activityNoticeInfo")
        else
            -- todo
        end
    end
end

ActivityNoticeListen = PacketScriptHandler:new(HP_pb.RED_POINT_LIST_SYNC_S, onActivityNoticeSync)
ActivityNoticeSignleListen = PacketScriptHandler:new(HP_pb.RED_POINT_SINGLE_SYNC_S, onActivityNoticeSigleSync)

function ActivityInfo:showNotice(visible)
    if visible then
        PageManager.refreshPage("MainScenePage", "showActivityNotice")
    else
        PageManager.refreshPage("MainScenePage", "hideActivityNotice")
    end
end

function ActivityInfo:validateAndRegister()
    CCLuaLog("ActivityInfo:validateAndRegister()")

    ActivityListen:registerFunctionHandler(onActivityOpenSync)
    ActivityNoticeListen:registerFunctionHandler(onActivityNoticeSync)
    ActivityNoticeSignleListen:registerFunctionHandler(onActivityNoticeSigleSync)
end

-- 本地缓存活动期数
function ActivityInfo:saveVersion(id)
    local UserInfo = require("PlayerInfo.UserInfo")
    local activity = ActivityInfo.activities[id] or { }
    if not activity.isNew then
        return
    end

    local key = string.format("Activity_%d_%d_%d", UserInfo.serverId, UserInfo.playerInfo.playerId, id)
    CCUserDefault:sharedUserDefault():setIntegerForKey(key, activity.newVersion)
    CCUserDefault:sharedUserDefault():flush()
    ActivityInfo.activities[id]["version"] = activity.newVersion
    ActivityInfo.activities[id]["isNew"] = false
    ActivityInfo.newCount = math.max(ActivityInfo.newCount - 1, 0)

    PageManager.refreshPage("ActivityPage")
end

-- activityId = 活动id
-- data = 传到子界面的数据
function ActivityInfo.jumpToActivityById(activityId, data)
    if ActivityConfig[activityId] then
        local activityType = ActivityConfig[activityId].activityType
        if ActivityInfo:getActivityIsOpenById(activityId) then
            if activityType and activityType == ActivityConfig.SPECIAL_EDITION then
                -- 特典里面的
                require("WelfarePage")
                WelfarePage_setPart(activityId)
                PageManager.pushPage("WelfarePage")
            elseif activityType and activityType == ActivityConfig.NOVICE then
                -- 新手活动

            elseif activityType and activityType == ActivityConfig.GASHAPON then
                -- 扭蛋里面的活动
                require("GashaponPage")
                GashaponPage_setPart(activityId)
                GashaponPage_setIds(ActivityInfo.NiuDanPageIds)
                GashaponPage_setTitleStr("@NiuDanTitle")
                PageManager.changePage("GashaponPage")
                resetMenu("mGuildPageBtn", true)
            elseif activityType and activityType == ActivityConfig.LIMIT then
                -- 限定活动
                require("LimitActivityPage")
                LimitActivityPage_setPart(activityId, data)
                LimitActivityPage_setCurrentPageType(1)
                LimitActivityPage_setIds(ActivityInfo.LimitPageIds)
                LimitActivityPage_setTitleStr("@FixedTimeActTitle")
                PageManager.changePage("LimitActivityPage")
            end
        else
            -- TODO活动未开启
           --  MessageBoxPage:Msg_Box_Lan("")
        end
    else
        -- TODO活动id错误
        -- MessageBoxPage:Msg_Box_Lan("")
    end
end

function ActivityInfo:decreaseReward()
    -- body
end

-- 检测某id活动是否开启状态
function ActivityInfo:getActivityValid(id)
    local isValid = false
    if common:table_hasValue(ActivityInfo.allIds, id) or
       common:table_hasValue(ActivityInfo.OtherPageids, id) or
       common:table_hasValue(ActivityInfo.NewPageids, id) then
        isValid = true
    end
    return isValid
end

function ActivityInfo:getActivityIsOpenById(activityId)
    local bl = false
    for i = 1, #ActivityInfo.allIds do
        if ActivityInfo.allIds[i] == activityId then
            bl = true
            break
        end
    end

    return bl
end

function ActivityInfo:getActivitySortData(activityId)
    local activitySortConfig = ConfigManager.getActivitySortCfg()
    for k, v in pairs(activitySortConfig) do
        if activityId == v.id then
            return v
        end
    end
end


--------------------------------------------------------------------------------