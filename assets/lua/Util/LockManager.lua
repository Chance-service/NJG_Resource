--[[ 
    name: LockManager
    desc: 管理各頁面是否上鎖
    author: Hikaha
    update: 2024/1/15 16:10
--]]
local HP_pb = require("HP_pb")
local NodeHelper = require("NodeHelper")
local UserInfo = require("PlayerInfo.UserInfo")
local ConfigManager = require("ConfigManager")
local mapCfg = ConfigManager.getNewMapCfg()
local lockCfg = ConfigManager.getFunctionUnlock()

local LockManager = { }
local lockData = { }
-- 上鎖條件
LockManager.LockCondition = {
    FOREVER = 0, STAGE = 1, LEVEL = 2, HERO_LEVEL = 3, HERO_STAR = 4, VIP = 5
}

--[[ 取得 特定UI 是否有上鎖(不限類型) ]]
function LockManager_getShowLockByPageName(pageName, options)
    if not lockData[pageName] then   -- 沒有設定 > 不上鎖
        return false
    end
    local condition = common:split(lockData[pageName].condition, ",")
    local value = common:split(lockData[pageName].value, ",")
    for i = 1, #condition do
        if tonumber(condition[i]) == LockManager.LockCondition.FOREVER then
            return true
        elseif tonumber(condition[i]) == LockManager.LockCondition.STAGE then
            if UserInfo.stateInfo.passMapId and UserInfo.stateInfo.passMapId < tonumber(value[i]) then
                return true
            end
        elseif tonumber(condition[i]) == LockManager.LockCondition.LEVEL then
            if UserInfo.roleInfo.level and UserInfo.roleInfo.level < tonumber(value[i]) then
                return true
            end
        elseif tonumber(condition[i]) == LockManager.LockCondition.HERO_LEVEL then
            if not options or not options.hero_level then
                return true
            end
            if options.hero_level < tonumber(value[i]) then
                return true
            end
        elseif tonumber(condition[i]) == LockManager.LockCondition.HERO_STAR then
            if not options or not options.hero_star then
                return true
            end
            if options.hero_star < tonumber(value[i]) then
                return true
            end
        elseif tonumber(condition[i]) == LockManager.LockCondition.VIP then
            if UserInfo.playerInfo.vipLevel and UserInfo.playerInfo.vipLevel < tonumber(value[i]) then
                return true
            end
        end
    end
    return false
end

--[[ 取得 特定UI 的 上鎖提示字串  ]]
function LockManager_getLockStringByPageName(pageName)
    if not lockData[pageName] then
        return ""
    end
    if lockData[pageName].str == common:getLanguageString("@StageOpen") then
        local mapStr = mapCfg[tonumber(lockData[pageName].value)].Chapter .. "-" .. mapCfg[tonumber(lockData[pageName].value)].Level
        return common:getLanguageString(lockData[pageName].str, mapStr)
    elseif lockData[pageName].str == common:getLanguageString("@LevelOpen") then
        return common:getLanguageString(lockData[pageName].str, lockData[pageName].value)
    else
        return lockData[pageName].str
    end
end

--[[ 初始化 解鎖資料  ]]
function LockManager_initUnclokData()
    local data = { }
    for i = 1, #lockCfg do
        if lockCfg[i].type == 2 then
            data[tonumber(lockCfg[i].Function)] = {
                condition = lockCfg[i].unlockType,
                value = lockCfg[i].unlockValue,
                str = lockCfg[i].unlockStr,
            }
        end
    end
    return data
end
lockData = LockManager_initUnclokData()

return LockManager