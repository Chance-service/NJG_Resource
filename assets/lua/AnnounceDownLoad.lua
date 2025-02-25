local json    = require('json')
local socket  = require("socket.socket")
local http    = require("socket.http")
local ltn12   = require("ltn12")

local AnnounceDownLoad = {
    firstEnterGame = false,
    url            = "",
    fileName       = "",
    updateTime     = "",
}

-- 下載重試排程 ID（局部變數）
local schedulerId = nil
local CCFileUtils = CCFileUtils:sharedFileUtils()

--------------------------------------------------------------------------------
--[[
    根據檔名獲取儲存檔案與 JSON 更新檔案的完整路徑，
    不同平台路徑可能不同
--]]
local function getPaths(fileName)
    local writablePath = CCFileUtils:getWritablePath()
    local savePath, jsonPath
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 then
        savePath = writablePath .. "/Annoucement/" .. fileName
        jsonPath = writablePath .. "/Annoucement/update_info.json"
    else
        savePath = writablePath .. "hotUpdate/Annoucement/" .. fileName
        jsonPath = writablePath .. "hotUpdate/Annoucement/update_info.json"
    end
    return savePath, jsonPath
end

--------------------------------------------------------------------------------
-- 設定下載 URL、檔案名稱與更新時間
--------------------------------------------------------------------------------
function AnnounceDownLoad.setData(url, _fileName, _updateTime)
    AnnounceDownLoad.url      = url
    AnnounceDownLoad.fileName = _fileName
    AnnounceDownLoad.updateTime = _updateTime
end

--------------------------------------------------------------------------------
-- 啟動下載或檢查流程
--------------------------------------------------------------------------------
function AnnounceDownLoad.start(type)
    AnnounceDownLoad.requireConfig()
end

--------------------------------------------------------------------------------
-- 檢查與下載配置檔案
--------------------------------------------------------------------------------
function AnnounceDownLoad.requireConfig()
    local savePath, jsonPath = getPaths(AnnounceDownLoad.fileName)

    -- 若需要更新則下載檔案
    if isUpdateRequired(AnnounceDownLoad.url, jsonPath) then
        local result = downloadFile(AnnounceDownLoad.url, savePath)
        if result then
            CCLuaLog("File successfully downloaded and saved.")
            updateJsonFile(jsonPath, AnnounceDownLoad.url)
        else
            CCLuaLog("Failed to download the file.")
            return
        end
    end

    -- 嘗試讀取下載後的檔案內容
    local file = io.open(savePath, "r")
    if not file then
        return
    end

    local content = file:read("*a")
    file:close()

    local maxAttempts  = 50   -- 嘗試 50 次，每次 0.2 秒（約 10 秒）
    local attemptCount = 0

    if content == "" then
        schedulerId = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(function(dt)
            attemptCount = attemptCount + 1

            local file = io.open(savePath, "r")
            if not file then
                print("Error: Cannot open file at " .. savePath)
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(schedulerId)
                schedulerId = nil
                return
            end

            local content = file:read("*a")
            file:close()

            if content:match("%S") then
                -- 有效內容讀取到，取消重試並處理內容
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(schedulerId)
                schedulerId = nil
                local AnnouncementPopPageBase = require("AnnouncementPopPageNew")
                AnnouncementPopPageBase:setMessage(content)
            elseif attemptCount >= maxAttempts then
                CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(schedulerId)
                schedulerId = nil
                print("Error: Could not retrieve content after " .. maxAttempts .. " attempts.")
            end
        end, 0.2, false)
        return
    end

    local AnnouncementPopPageBase = require("AnnouncementPopPageNew")
    AnnouncementPopPageBase:setMessage(content)
end

--------------------------------------------------------------------------------
-- 下載檔案函數（使用 CurlDownload）
--------------------------------------------------------------------------------
function downloadFile(url, savePath)
    CurlDownload:getInstance():downloadFile(url, savePath)
    CurlDownload:getInstance():update(1)
    return true
end

--------------------------------------------------------------------------------
-- 建立檔案並寫入內容
--------------------------------------------------------------------------------
function createFile(savePath, content)
    local file = io.open(savePath, "w")
    if not file then
        CCLuaLog("Failed to create file: " .. savePath)
        return false
    end

    file:write(content)
    file:close()
    CCLuaLog("File created and content written: " .. savePath)
    return true
end

--------------------------------------------------------------------------------
-- 檢查是否需要更新
-- 若 JSON 設定檔不存在或沒有當前檔案的記錄，則需要更新
--------------------------------------------------------------------------------
function isUpdateRequired(url, jsonPath)
    local data = readJsonFile(jsonPath)
    if not data or not data[AnnounceDownLoad.fileName] then
        return true
    end

    local lastUpdateTime = data[AnnounceDownLoad.fileName]
    return AnnounceDownLoad.updateTime > lastUpdateTime  
end

--------------------------------------------------------------------------------
-- 更新 JSON 檔案中當前檔案的更新時間
--------------------------------------------------------------------------------
function updateJsonFile(jsonPath, url)
    local data = readJsonFile(jsonPath) or {}
    data[AnnounceDownLoad.fileName] = AnnounceDownLoad.updateTime
    writeJsonFile(jsonPath, data)
end

--------------------------------------------------------------------------------
-- 讀取 JSON 檔案並回傳表格
--------------------------------------------------------------------------------
function readJsonFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return json.decode(content)
end

--------------------------------------------------------------------------------
-- 手動格式化 JSON 字串（使其易讀）
--------------------------------------------------------------------------------
function formatJsonString(jsonString)
    local formatted   = ""
    local indentLevel = 0
    local inQuote     = false

    for i = 1, #jsonString do
        local char = jsonString:sub(i, i)

        if char == "\"" and jsonString:sub(i - 1, i - 1) ~= "\\" then
            inQuote = not inQuote
        end

        if not inQuote then
            if char == "{" or char == "[" then
                indentLevel = indentLevel + 1
                formatted = formatted .. char .. "\n" .. string.rep("    ", indentLevel)
            elseif char == "}" or char == "]" then
                indentLevel = indentLevel - 1
                formatted = formatted .. "\n" .. string.rep("    ", indentLevel) .. char
            elseif char == "," then
                formatted = formatted .. char .. "\n" .. string.rep("    ", indentLevel)
            else
                formatted = formatted .. char
            end
        else
            formatted = formatted .. char
        end
    end

    return formatted
end

--------------------------------------------------------------------------------
-- 將表格寫入 JSON 檔案並進行格式化
--------------------------------------------------------------------------------
function writeJsonFile(filePath, data)
    CCLuaLog("writing: " .. filePath)
    local file = io.open(filePath, "w")
    if not file then
        CCLuaLog("Failed to open file for writing: " .. filePath)
        return false
    end

    local jsonContent = json.encode(data)
    jsonContent = formatJsonString(jsonContent)
    file:write(jsonContent)
    file:close()
    return true
end

return AnnounceDownLoad
