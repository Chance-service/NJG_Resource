
local tostring         = tostring
local tonumber         = tonumber
local ConfigManager    = require("ConfigManager")
local PageManager      = require("PageManager")
local GameConfig       = require("GameConfig")
local HeroOrderItemManager = {
	
}

local mTaskListInfo = {}
local mHeroTaskCfg  = ConfigManager:getHeroOrderTaskCfg()
local mCurItemId    = nil
local mCurTaskNum   = 0
local mShopListInfo = {}
local mTaskFinishTimes = {
    taskFinishLefttimes = 0,--s剩余完成次数
    taskFinishAlltimes = 0,--当天 总的任务任务次数
}

function HeroOrderItemManager:resetData()
    mTaskListInfo = {}
    mShopListInfo = {}
    mCurItemId    = nil
    mCurTaskNum   = 0
end

function HeroOrderItemManager:updateTaskListInfo(info)
    mTaskListInfo   = {}
    for i = 1, #info do
        local mItemList = {}
        local mTempTaskInfo = HeroOrderItemManager:getTaskCfgByTaskId(info[i].taskId)
        mItemList.nTaskId        = info[i].taskId
        --mItemList.sHeroOrderName = mTempTaskInfo.heroOrderName
        mItemList.nLevelLimit    = mTempTaskInfo.levelLimit
        mItemList.nTotalProgress = mTempTaskInfo.monsterNumNeedKill
        mItemList.nCurProgress   = info[i].status
        mItemList.bComplete      = (info[i].status == mTempTaskInfo.monsterNumNeedKill) 
        mItemList.nHeroOrderId   = mTempTaskInfo.heroOrderId
        table.insert(mTaskListInfo, mItemList)
    end
    mCurTaskNum = #mTaskListInfo
end
function HeroOrderItemManager:updateShopListInfo(info)
    mShopListInfo = info
end
function HeroOrderItemManager:getShopListInfo()
    return mShopListInfo;
end
function HeroOrderItemManager:getTaskFinishInfo()
    return mTaskFinishTimes;
end
function HeroOrderItemManager:updateHeroTokenInfo(msg)
    HeroOrderItemManager:updateTaskListInfo(msg.taskStatusBeanList)
    HeroOrderItemManager:updateShopListInfo(msg.ShopStatusBeanList)
    mTaskFinishTimes.taskFinishAlltimes = msg.taskFinishAlltimes
    mTaskFinishTimes.taskFinishLefttimes = msg.taskFinishLefttimes
end

function HeroOrderItemManager:updateStatusByTaskId(taskId)
    for i = 1, #mTaskListInfo do
        if mTaskListInfo[i].nTaskId == taskId then
           mTaskListInfo[i].nCurProgress = mTaskListInfo[i].nTotalProgress
           mItemList.bComplete = true
           return
        end
    end
end

function HeroOrderItemManager:getTaskListInfo()
	return mTaskListInfo
end

function HeroOrderItemManager:getTaskTotalNum()
	return GameConfig.HeroTokenLimit.TaskLimit
end

function HeroOrderItemManager:getTaskNum()
	return mCurTaskNum;
end

function HeroOrderItemManager:addTaskNum(nValue)
    mCurTaskNum = mCurTaskNum + nValue
end

function HeroOrderItemManager:getHeroLevelLimit()
    return GameConfig.HeroTokenLimit.LevelLimit
end

function HeroOrderItemManager:getTaskCfgByTaskId( taskId )
	if mHeroTaskCfg == nil then
		mHeroTaskCfg = ConfigManager:getHeroOrderTaskCfg()
	end
	return mHeroTaskCfg[taskId]
		 
end

function HeroOrderItemManager:getCurSelectItemInfo()
    local UserItemManager  = require("Item.UserItemManager")
    return UserItemManager:getUserItemByItemId(mCurItemId);
end

function HeroOrderItemManager:showHeroOrderItemInfo(itemId)
    mCurItemId = itemId
    PageManager.pushPage("HeroOrderItemPage")
end

return HeroOrderItemManager

--endregion
