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

-- �U�����ձƵ{ ID�]�����ܼơ^
local schedulerId = nil
local CCFileUtils = CCFileUtils:sharedFileUtils()

--------------------------------------------------------------------------------
--[[
    �ھ��ɦW����x�s�ɮ׻P JSON ��s�ɮת�������|�A
    ���P���x���|�i�ण�P
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
-- �]�w�U�� URL�B�ɮצW�ٻP��s�ɶ�
--------------------------------------------------------------------------------
function AnnounceDownLoad.setData(url, _fileName, _updateTime)
    AnnounceDownLoad.url      = url
    AnnounceDownLoad.fileName = _fileName
    AnnounceDownLoad.updateTime = _updateTime
end

--------------------------------------------------------------------------------
-- �ҰʤU�����ˬd�y�{
--------------------------------------------------------------------------------
function AnnounceDownLoad.start(type)
    AnnounceDownLoad.requireConfig()
end

--------------------------------------------------------------------------------
-- �ˬd�P�U���t�m�ɮ�
--------------------------------------------------------------------------------
function AnnounceDownLoad.requireConfig()
    local savePath, jsonPath = getPaths(AnnounceDownLoad.fileName)

    -- �Y�ݭn��s�h�U���ɮ�
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

    -- ����Ū���U���᪺�ɮפ��e
    local file = io.open(savePath, "r")
    if not file then
        return
    end

    local content = file:read("*a")
    file:close()

    local maxAttempts  = 50   -- ���� 50 ���A�C�� 0.2 ��]�� 10 ��^
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
                -- ���Ĥ��eŪ����A�������ըóB�z���e
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
-- �U���ɮר�ơ]�ϥ� CurlDownload�^
--------------------------------------------------------------------------------
function downloadFile(url, savePath)
    CurlDownload:getInstance():downloadFile(url, savePath)
    CurlDownload:getInstance():update(1)
    return true
end

--------------------------------------------------------------------------------
-- �إ��ɮרüg�J���e
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
-- �ˬd�O�_�ݭn��s
-- �Y JSON �]�w�ɤ��s�b�ΨS����e�ɮת��O���A�h�ݭn��s
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
-- ��s JSON �ɮפ���e�ɮת���s�ɶ�
--------------------------------------------------------------------------------
function updateJsonFile(jsonPath, url)
    local data = readJsonFile(jsonPath) or {}
    data[AnnounceDownLoad.fileName] = AnnounceDownLoad.updateTime
    writeJsonFile(jsonPath, data)
end

--------------------------------------------------------------------------------
-- Ū�� JSON �ɮרæ^�Ǫ��
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
-- ��ʮ榡�� JSON �r��]�Ϩ��Ū�^
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
-- �N���g�J JSON �ɮרöi��榡��
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
