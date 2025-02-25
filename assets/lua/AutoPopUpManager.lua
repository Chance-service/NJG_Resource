require("Util.LockManager")
--local ActivityInfo = require("ActivityInfo")
local ConfigManager = require("ConfigManager")

local thisPageName = "AutoPopupManager"

local AutoPopupManager = { }
local cfg = ConfigManager.getWindowPopupCfg()

local POP_TYPE = { NONE = 0, DAILY = 1, ALWAYS = 2 }
local POP_PAGE = {
    [1] = { fun = function()
                local FreeSummonPage=require("Reward.RewardSubPage_FreeSummon")
                if FreeSummonPage:hasData() then
                    PageManager.pushPage("Reward.RewardPage")
                end
            end, lock = GameConfig.LOCK_PAGE_KEY.SUMMON_900, activityId = 0 },
    [2] = { fun = function()
                PageManager.pushPage("LivenessPage")
            end, lock = nil, activityId = 122 },
    [3] = { fun = function()
                require("NewPlayerBasePage")
                NewPlayerBasePage_setPageType(ACTIVITY_TYPE.NEWPLAYER_LEVEL9)
                PageManager.pushPage("NewPlayerBasePage")
            end, lock = nil, activityId = 114 },
    [4] = { fun = function()
                local closeR18 = VaribleManager:getInstance():getSetting("IsCloseR18")
                if tonumber(closeR18) ~= 1 then
                    PageManager.pushPage("AnnouncementPopPageNew")
                end
            end, lock = nil, activityId = 0 },
    [5] = { fun = function()
                local IAPDataMgr = require("IAP.IAPDataMgr")
                require("IAP.IAPPage"):setEntrySubPage("Recharge")
                PageManager.pushPage("IAP.IAPPage")
            end, lock = GameConfig.LOCK_PAGE_KEY.DAILY_BUNDLE, activityId = 0 },
}
local POP_UP_SAVE_KEY = "POP_ALL_"

PopUpDatas = { }

function AutoPopupManager_checkAutoPopup()
    local GuideManager = require("Guide.GuideManager")
    if GuideManager.isInGuide then
        return  -- 新手教學中
    end
    local currPage = MainFrame:getInstance():getPageNum()
    if currPage > 0 then
        return -- 有其他頁面
    end
    -- 彈跳禮包
    local PopSaledata = next(ActPopUpSaleSubPage_Content_getServerData())
    if not PopSaledata then
        local MainScenePageInfo = require("MainScenePage")
        MainScenePageInfo.RequestData()
        return
    end
    if not LockManager_getShowLockByPageName(GameConfig.LOCK_PAGE_KEY.POPUP_SALE) then
        AutoPopupManager_setPopUpIds()
        for i = 1, #AutoPopupManager.PopUpIds  do
            if AutoPopupManager:showPopUpSale(AutoPopupManager.PopUpIds[i]) then
                return
            end
        end
    end
    -- 其他彈跳頁面
    if #PopUpDatas <= 0 then
        AutoPopupManager_sortCfg()
    end
    for i = 1, #PopUpDatas do
        PopUpDatas[i].saveDate = PopUpDatas[i].saveDate or CCUserDefault:sharedUserDefault():getStringForKey(POP_UP_SAVE_KEY .. i .. "_" .. UserInfo.playerInfo.playerId)
        local saveDate = PopUpDatas[i].saveDate
        local todayDate = AutoPopupManager:getCurrentDateString()
        local pageData = POP_PAGE[PopUpDatas[i].id]
        if pageData then
            local activityOpen = false
            local unlock = false
            if pageData.activityId <= 0 or ActivityInfo:getActivityIsOpenById(pageData.activityId) then
                activityOpen = true
            end
            if not pageData.lock or (not LockManager_getShowLockByPageName(pageData.lock)) then
                unlock = true
            end
            if activityOpen and unlock then
                if PopUpDatas[i].type == POP_TYPE.DAILY then
                    if saveDate ~= todayDate then
                        pageData.fun()
                        CCUserDefault:sharedUserDefault():setStringForKey(POP_UP_SAVE_KEY .. i .. "_" .. UserInfo.playerInfo.playerId, todayDate)
                        PopUpDatas[i].saveDate = todayDate
                        break
                    end
                elseif PopUpDatas[i].type == POP_TYPE.ALWAYS then
                    pageData.fun()
                    PopUpDatas[i].saveDate = todayDate
                    break
                end
            end
        end
    end
end

function AutoPopupManager_setPopUpIds()
    local SpTable = { 132, 177 }
    local PopUpCfg1 = ConfigManager.getPopUpCfg()
    local PopUpCfg2 = ConfigManager.getPopUpCfg2()
    AutoPopupManager.PopUpIds = { }
    for i = 1, #PopUpCfg1 do
      table.insert(AutoPopupManager.PopUpIds ,PopUpCfg1[i].activityId)
    end
    for key, _ in pairs (PopUpCfg2) do
        table.insert(AutoPopupManager.PopUpIds, tonumber(key))
    end
    for i = 1, #SpTable do
        table.insert(AutoPopupManager.PopUpIds, SpTable[i]) 
    end
end

function AutoPopupManager:showPopUpSale(id)
    local actData = AutoPopupManager:getActData(id)
    if actData and actData.isShowIcon then
        local giftId = actData.id
        if giftId > 1000 then id = 187 end

        local popActStr = AutoPopupManager:getPopActStr(id, giftId)

        local dayString = AutoPopupManager:getCurrentDateString()
        if not dayString then
            print("Error: 無法取得有效的日期字串")
            return false
        end
        if popActStr ~= dayString then
            AutoPopupManager:updatePopActStrForAll(dayString)
            AutoPopupManager:pushPopUpPage(id)
            return true
        end
    end
    return false
end

function AutoPopupManager:updatePopActStrForAll(value)
    for _, otherId in pairs(ActivityInfo.PopUpSaleIds) do
        if otherId == 187 then
            local data = ActPopUpSaleSubPage_Content_getServerData()
            for k,v in pairs (data) do
                CCUserDefault:sharedUserDefault():setStringForKey(
                "POP_ACT_" .. otherId .. "_" .. k .. "_" .. UserInfo.playerInfo.playerId,
                value
                )
            end
            break
        end
        local otherActData = AutoPopupManager:getActData(otherId)
        if otherActData and otherActData.isShowIcon then
            local otherGiftId = otherActData.id
            CCUserDefault:sharedUserDefault():setStringForKey(
                "POP_ACT_" .. otherId .. "_" .. otherGiftId .. "_" .. UserInfo.playerInfo.playerId,
                value
            )
        end
    end
end

function AutoPopupManager:pushPopUpPage(id)
    local actPopupSalePage = require("ActPopUpSale.ActPopUpSalePage")
    actPopupSalePage:setEntryTab(tostring(id))
    PageManager.pushPage("ActPopUpSale.ActPopUpSalePage")
end

function AutoPopupManager:getActData(id)
    if id == 187 then
        ActPopUpSaleSubPage_Content_getServerData()
    end    
    if id == 132 or id == 177 then
        return _G["ActPopUpSaleSubPage_" .. id .. "_getIsShowMainSceneIcon"]()
    else
        require("ActPopUpSale.ActPopUpSaleSubPage_Content")
        return ActPopUpSaleSubPage_Content_getIsShowMainSceneIcon(id)
    end
end

function AutoPopupManager:getPopActStr(id, giftId)
    return CCUserDefault:sharedUserDefault():getStringForKey(
        "POP_ACT_" .. id .. "_" .. giftId .. "_" .. UserInfo.playerInfo.playerId
    )
end

function AutoPopupManager_sortCfg()
    for k, v in pairs(cfg) do
        if v.type ~= POP_TYPE.NONE then
            table.insert(PopUpDatas, v)
        end
    end
    table.sort(PopUpDatas, function(data1, data2)
        if data1 and data2 then
            return data1.rank < data2.rank
        else
            return false
        end
    end)
end

function AutoPopupManager:getCurrentDateString()
    local dateTable = os.date("*t")
    local year = dateTable.year
    local month = string.format("%02d", dateTable.month)  -- Ensure two digits
    local day = string.format("%02d", dateTable.day)      -- Ensure two digits
    return year .. "_" .. month .. "_" .. day
end