-- Author:Ranjinlan
-- Create Data: [2018-05-15 14:24:40]

local Const_pb = require("Const_pb")
local HP_pb = require("HP_pb")
local UserMercenaryManager = require("UserMercenaryManager")
local MysticalDress_pb = require('Badge_pb')
local FateDataInfo = require("FateDataInfo")
local haveReceiveAllData = false --补丁专用变量，防止角色身上穿的私装在私装数据库里找不到

local FateDataManager = {
    currentHuntingIndex = 1,
    ModelName = "FateDataModel",
    FateWearSelectItem = {
        ccbiFile = "RuneSelectPopUpContent.ccbi",
        _bg1DefaultSize = nil, --背景1默认大小
        _bg2DefaultSize = nil, --背景2默认大小
        _DefaultItemSize = nil, --默认大小
        _contentPosY = nil,     --默认总节点的y位置
    }
}
local mNoRoleFateDataList = {}  --穿戴中的也會在裡面
local mRoleFateDataList = {}

--------------------------------------------------------
--同步命格 HPMysticalDressInfoSync
function FateDataManager:syncFateDatas(msg)
    if msg.type == MysticalDress_pb.UPDATE then
        for _, v in ipairs(msg.dresses) do
            local runeId = v.id
            local oriRoleId = mNoRoleFateDataList[v.id] and mNoRoleFateDataList[v.id].roleId
            local newRoleId = v.roleId
            if mNoRoleFateDataList[runeId] then
                --脱下之前的
                if oriRoleId then
                    if mRoleFateDataList[oriRoleId][runeId] then
                        mRoleFateDataList[oriRoleId][runeId] = nil
                    end
                    --mRoleFateDataList[newRoleId] = mRoleFateDataList[newRoleId] or { }
                    --mRoleFateDataList[newRoleId][v.id] = nil
                end
                mNoRoleFateDataList[v.id]:update(v)
            else
                mNoRoleFateDataList[v.id] = FateDataInfo.new(v)
            end
            --穿上现在的
            if newRoleId ~= 0 then
                mRoleFateDataList[newRoleId] = mRoleFateDataList[newRoleId] or {}
                mRoleFateDataList[newRoleId][runeId] = true
            end
        end
        local RuneInfoPage = require("Equip.RuneInfoPage")
        RuneInfoPage:RefreshLockIcon()
        PackagePage_refreshPage()
        PageManager.refreshPage(FateDataManager.ModelName, "UpdateData")
        local RuneBuildSelectPage = require ("RuneBuildSelectPage")
        RuneBuildSelectPage:RefreshPage()
        local InventoryPage = require("Inventory.InventoryPage")
        InventoryPage:refreshPage()
    elseif msg.type == MysticalDress_pb.All then
        mNoRoleFateDataList = { }
        mRoleFateDataList = { }
        for _,v in ipairs(msg.dresses) do
            mNoRoleFateDataList[v.id] = FateDataInfo.new(v)
            --穿上现在的
            if v.roleId ~= 0 then
                mRoleFateDataList[v.roleId] = mRoleFateDataList[v.roleId] or { }
                mRoleFateDataList[v.roleId][v.id] = true
            end
        end
        haveReceiveAllData = true
        PageManager.refreshPage(FateDataManager.ModelName, "ResetData")
        --local mercenarysInfo = UserMercenaryManager:getUserMercenaryInfos() or {}
        --FateDataManager:resetAllRoleId(mercenarysInfo)
    end
end

--删除命格 HPMysticalDressRemoveInfoSync
function FateDataManager:deleteDateDatas(msg)
    for _,v in ipairs(msg.remIds) do
        if mNoRoleFateDataList[v] then
            mNoRoleFateDataList[v] = nil
        else
            common:sendEmptyPacket(HP_pb.MYSTICAL_DRESS_RELOAD_C, false);
            --assert("false", "not find fate data to delete" )
        end
    end
    PageManager.refreshPage(FateDataManager.ModelName,"DeleteData")
end

function FateDataManager:ResetData()
    haveReceiveAllData = false
    mNoRoleFateDataList = {}
    mRoleFateDataList = {}
end

function FateDataManager:ResetForAssembly()
    --FateDataManager:onAllMercenarysInfoSync()
end

--[[
--刷新命格的角色索引Id
function FateDataManager:resetAllRoleId(mercenarysInfo)
    mRoleFateDataList = {}
    for _,mercenaryInfo in pairs(mercenarysInfo or {}) do
        if #(mercenaryInfo.dress or {}) > 0 then
            mRoleFateDataList[mercenaryInfo.roleId] = mercenaryInfo.dress
            for _,roleDressPb in ipairs(mercenaryInfo.dress) do
                local fateData = mNoRoleFateDataList[roleDressPb.id]
                if fateData then
                    fateData:updateRoleInfo(mercenaryInfo.roleId,roleDressPb.loc)
                else
                    --补丁 防止因为网络原因 只收到角色数据没收到私装数据
                    if not haveReceiveAllData then
                        common:sendEmptyPacket(HP_pb.MYSTICAL_DRESS_RELOAD_C, false);
                    end
                    --assert(false,"not fate to wear!!!!!!")
                end
            end
        end
    end
end
]]

--设置猎命当前点亮的位置
function FateDataManager:setHuntingInfo(msg)
    FateDataManager.currentHuntingIndex = msg.id 
end
--[[
--同步所有副将时候，刷新命格的角色索引Id
function FateDataManager:onAllMercenarysInfoSync()
    for _,v in pairs(mNoRoleFateDataList) do
        v:updateRoleInfo(nil)
    end
    local mercenarysInfo = UserMercenaryManager:getUserMercenaryInfos() or {}
    FateDataManager:resetAllRoleId(mercenarysInfo or {})
end
]]
--同步副将时候，刷新命格的角色索引Id
function FateDataManager:onOneMercenarysInfoSync(mercenaryInfo)
    if not mercenaryInfo then return end
    --[[
    local roleFateData = mRoleFateDataList[mercenaryInfo.roleId]
    if roleFateData then
        --把之前该角色穿的衣服删除
        for _,roleDressPb in ipairs(roleFateData) do
            local fateData = mNoRoleFateDataList[roleDressPb.id]
            if fateData then
                fateData:updateRoleInfo(nil)
            end
        end
        mRoleFateDataList[mercenaryInfo.roleId] = nil
    end
    --将现在角色穿的设置好
    if #(mercenaryInfo.dress or {}) > 0 then
        mRoleFateDataList[mercenaryInfo.roleId] = mercenaryInfo.dress
        for _,roleDressPb in ipairs(mercenaryInfo.dress) do
            local fateData = mNoRoleFateDataList[roleDressPb.id]
            if fateData then
                fateData:updateRoleInfo(mercenaryInfo.roleId,roleDressPb.loc)
            end
        end
    end
    --]]
    local roleId = mercenaryInfo.roleId
    --脱下之前的
    mRoleFateDataList[roleId] = mRoleFateDataList[roleId] or {}
    local data = mRoleFateDataList[roleId]
    for id in pairs(data) do
        local fateData = mNoRoleFateDataList[id]
        if fateData then
            fateData:updateRoleInfo()
            data[id] = nil
        end
    end
    --穿上现在的
    for _,roleDressPb in ipairs(mercenaryInfo.dress or {}) do
        local fateData = mNoRoleFateDataList[roleDressPb.id]
        if fateData then
            fateData:updateRoleInfo(roleId,roleDressPb.loc)
            data[roleDressPb.id] = true
        end
    end
end

--获取所有命格
function FateDataManager:getAllFateDatas()
    return mNoRoleFateDataList
end

--通过命格唯一索引获取命格
function FateDataManager:getFateDataById(id)
    if not id then return end
    return mNoRoleFateDataList[id]
end

--获取没穿戴的命格列表
function FateDataManager:getNotWearFateList(roleId, includeFateType)
    local list = { }
    if roleId then
        local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
        if mercenaryInfo then
            --相同类型的不让穿了
            local DressTypeList = { }
            for _, roleDressPb in ipairs(mercenaryInfo.dress or { }) do
                local fateData = FateDataManager:getFateDataById(roleDressPb.id)
                if fateData then
                    DressTypeList[fateData:getConf().type] = true
                end
            end
            if includeFateType then
                DressTypeList[includeFateType] = nil
            end
            for _, v in pairs(mNoRoleFateDataList) do
                if v.roleId == nil and not DressTypeList[v:getConf().type] then
                    list[#list + 1] = v
                end
            end
        end
    else
        for _,v in pairs(mNoRoleFateDataList) do
            if v.roleId == nil then
                list[#list + 1] = v
            end
        end
    end
    return list
end

-- 獲得全部符石
function FateDataManager:getAllFateList()
    local list = {}
    for _, v in pairs(mNoRoleFateDataList) do
        --if v.roleId == nil then
            list[#list + 1] = v
        --end
    end
    return list
end
-- 獲得全部符石(排除特定角色裝備中的)
function FateDataManager:getAllFateList2(roleId)
    local list = {}
    for _, v in pairs(mNoRoleFateDataList) do
        if v.roleId ~= roleId then
            list[#list + 1] = v
        end
    end
    return list
end

function FateDataManager:getPackageCount()
    local count = 0
    for _,v in pairs(mNoRoleFateDataList) do
        if v.roleId == nil then
            count = count + 1
        end
    end
    return count
end
--是否有没穿戴的命格
function FateDataManager:isHaveNotWearFate(roleId)
    if roleId then
        local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
        if mercenaryInfo and mercenaryInfo.status == Const_pb.FIGHTING then
            --相同类型的不让穿了
            local DressTypeList = {}
            for _,roleDressPb in ipairs(mercenaryInfo.dress or {}) do
                local fateData = FateDataManager:getFateDataById(roleDressPb.id)
                if fateData then
                    DressTypeList[fateData:getConf().type] = true
                end
            end
            for _,v in pairs(mNoRoleFateDataList) do
                if v.roleId == nil and not DressTypeList[v:getConf().type] then
                    return true
                end
            end
        end
    else
        for _,v in pairs(mNoRoleFateDataList) do
            if v.roleId == nil then
                return true
            end
        end
    end
    return false
end

--获取副将是否显示命格红点
function FateDataManager:checkShowFateRedPoint(roleId)
    if not roleId then 
        return false
    end
    local haveFateToWear = FateDataManager:isHaveNotWearFate(roleId)
    if haveFateToWear then
        local lockNum = FateDataManager:getFateWearNum(UserInfo.roleInfo.level)
        local mercenaryInfo = UserMercenaryManager:getUserMercenaryById(roleId)
        if mercenaryInfo and mercenaryInfo.status == Const_pb.FIGHTING and #(mercenaryInfo.dress or {}) < lockNum then
            return true
        end
    end
    return false
end

--命格穿戴数量
function FateDataManager:getFateWearNum(level)
    local num = 0
    for i,v in ipairs(GameConfig.FateLevelLimit) do
        if v > level then
            break
        end
        num = i
    end
    return num
end

function FateDataManager:getUnlockLevel(locPos)
    return GameConfig.FateLevelLimit[locPos]
end

function FateDataManager:getIsShowNotice(nowLevel)
    for k, v in pairs(mNoRoleFateDataList) do
        if not v.roleId then
            if v:getConf().rank > nowLevel then
                return true
            end
        end
    end
    return false
end

function FateDataManager:getUserRuneCountByCfgId(cfgId)
    local count = 0
    for k, v in pairs(mNoRoleFateDataList) do
        if v.itemId == cfgId then
            count = count + 1
        end
    end
    return count
end

return FateDataManager