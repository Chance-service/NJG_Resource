
local common = { };
------------local variable for system api--------------------------------------
local tostring = tostring;
local tonumber = tonumber;
local string = string;
local pairs = pairs;
--------------------------------------------------------------------------------

common.platform = {
    CC_PLATFORM_UNKNOWN = 0,
    CC_PLATFORM_IOS = 1,
    CC_PLATFORM_ANDROID = 2,
    CC_PLATFORM_WIN32 = 3,
    CC_PLATFORM_MARMALADE = 4,
    CC_PLATFORM_LINUX = 5,
    CC_PLATFORM_BADA = 6,
    CC_PLATFORM_BLACKBERRY = 7,
    CC_PLATFORM_MAC = 8,
    CC_PLATFORM_NACL = 9,
    CC_PLATFORM_EMSCRIPTEN = 10,
    CC_PLATFORM_TIZEN = 11,
    CC_PLATFORM_WINRT = 12,
    CC_PLATFORM_WP8 = 13
}

function dump(value, desciption, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = { }
    local result = { }

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = common:split(debug.traceback("", 2), "\n")
    print("dump from: " .. common:trim(traceback[3]))

    local function _dump(value, desciption, indent, nest, keylen)
        desciption = desciption or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        if type(value) ~= "table" then
            result[#result + 1] = string.format("%s%s%s = %s", indent, _v(desciption), spc, _v(value))
        elseif lookupTable[value] then
            result[#result + 1] = string.format("%s%s%s = *REF*", indent, desciption, spc)
        else
            lookupTable[value] = true
            if nest > nesting then
                result[#result + 1] = string.format("%s%s = *MAX NESTING*", indent, desciption)
            else
                result[#result + 1] = string.format("%s%s = {", indent, _v(desciption))
                local indent2 = indent .. "    "
                local keys = { }
                local keylen = 0
                local values = { }
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end )
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result + 1] = string.format("%s}", indent)
            end
        end
    end
    _dump(value, desciption, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end


isReloadPage = false

function reloadCurPage(...)
    isReloadPage = true
end

debugPage = { }

function onUnload(pageName, container)
    if CC_TARGET_PLATFORM_LUA == common.platform.CC_PLATFORM_WIN32 and(debugPage[pageName] or isReloadPage) then
        local reloadPageName = pageName
        debugPage[pageName] = nil
        isReloadPage = false
        package.loaded[pageName] = nil
        require(pageName)
        if _G["luaCreat_" .. reloadPageName] then
            _G["luaCreat_" .. reloadPageName](container)
        end
    end
end


function common:numberIsOdd(digit)
    local isOdd =((digit % 2) == 1)
    return isOdd
end

function common:numberIsEven(digit)
    local isOdd =((digit % 2) == 0)
    return isOdd
end


function common:getSettingVar(varName)
    local setting, name = VaribleManager:getInstance():getSetting(varName)
    return setting
end


function common:getColorFromSetting(varName)
    -- parseColor3B returns multi value
    local color3B = StringConverter:parseColor3B(self:getSettingVar(varName))
    return color3B
end

function common:getImageFileLargeQuality(quality)
    if quality ~= nil then
        local filePath = VaribleManager:getInstance():getSetting("ImageFileLargeQuality" .. tostring(quality))
        return filePath
    end
    return nil
end

function common:getMemBgImageFileQuality(quality)
    if quality ~= nil then
        local filePath = VaribleManager:getInstance():getSetting("MemBgImageFileQuality" .. tostring(quality))
        return filePath
    end
    return nil
end

function common:getQualityMaskImageFile(quality)
    if quality ~= nil then
        local filePath = VaribleManager:getInstance():getSetting("ImageFileQualityMask" .. tostring(quality))
        return filePath
    end
    return nil
end

function common:setBlackBoardVariable(key, val)
    key = tostring(key)
    if BlackBoard:getInstance():hasVarible(key) then
        BlackBoard:getInstance():setVarible(key, val)
    else
        BlackBoard:getInstance():addVarible(key, val)
    end
end

-- Be carefull: hasVarible, getVarible has double return value
function common:getBlackBoardVariable(key)
    if BlackBoard:getInstance():hasVarible(key) then
        return(BlackBoard:getInstance():getVarible(key))
    end
    return nil
end

function common:getAdventureIdByTag(tag)
    local item = ServerDateManager:getInstance():getAdventureItemInfoByID(tag)
    if item ~= nil then
        return item.adventureId
    end
    return 0
end
function common:getHighSpeedPointAndChangePoint()
    local leftTime = false
    -- 挑战红点
    local isCancelBattlePoint = false
    -- 高速战斗红点
    local UserItemManager = require("Item.UserItemManager");
    if UserItemManager:isHaveHighSpeedPoint() then
        isCancelBattlePoint = true
    else
        isCancelBattlePoint = false
    end
    local UserInfo = require("PlayerInfo.UserInfo")
    if UserInfo.stateInfo.bossFightTimes <= 0 then
        leftTime = false
    else
        if UserInfo.stateInfo.passMapId < 6 then
            leftTime = true
        else
            UserInfo.roleInfo.level = UserInfo.roleInfo.level or 1
            if UserInfo.roleInfo.level >= 25 then
                leftTime = true
            else
                leftTime = false
            end
        end
    end
    local clickTimes = CCUserDefault:sharedUserDefault():getIntegerForKey("ClickChangeBoss" .. UserInfo.serverId .. UserInfo.playerInfo.playerId)
    if clickTimes >= 2 then
        leftTime = false
    end
    return isCancelBattlePoint, leftTime
end
function common:getLanguageString(key, ...)
    return self:fill(Language:getInstance():getString(key), ...)
end

function common:getDayNumber(second)
    -- 获取多少天
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateDay = 0;

    local h = tonumber(hms[1])
    if h > 0 then
        if h >= 24 then
            dateDay = math.floor(h / 24)
        end
    end
    return dateDay;
end

function common:trimAll(s)
    return string.gsub(s or "", "%s", "")
end

-- 显示时间格式为：00:00:00
function common:dateFormat2String(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])
    if h > 0 then
        if h >= 24 then
            local d = math.floor(h / 24)
            if d > 0 then
                dateStr = dateStr .. d .. ":"
            end
        end
        local hour =(h % 24);
        if hour < 10 then
            dateStr = dateStr .. "0" .. hour .. ":"
        else
            dateStr = dateStr .. hour .. ":"
        end
    end

    local m = tonumber(hms[2])
    if m < 10 then
        dateStr = dateStr .. "0" .. m
    else
        dateStr = dateStr .. m
    end

    if withSecond == nil or withSecond == true or dateStr == "" then
        local s = tonumber(hms[3])
        if s < 10 then
            dateStr = dateStr .. ":" .. "0" .. s
        else
            dateStr = dateStr .. ":" .. s
        end
    end
    return dateStr
end

--顯示時分秒
function common:dateFormat2String2(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])

        
        local d = math.floor(h / 24)
            if d > 0 then
                dateStr = dateStr .. d .. ":"
            end
        local hour =(h % 24);
        if hour < 10 then
            dateStr = dateStr .. "0" .. hour .. ":"
        else
            dateStr = dateStr .. hour .. ":"
        end
   

    local m = tonumber(hms[2])
    if m < 10 then
        dateStr = dateStr .. "0" .. m
    else
        dateStr = dateStr .. m
    end

    if withSecond == nil or withSecond == true or dateStr == "" then
        local s = tonumber(hms[3])
        if s < 10 then
            dateStr = dateStr .. ":" .. "0" .. s
        else
            dateStr = dateStr .. ":" .. s
        end
    end
    return dateStr
end

function common:second2DateString(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])
    if h > 0 then
        if h >= 24 then
            local d = math.floor(h / 24)
            dateStr = d .. Language:getInstance():getString("@Days")
        end
        dateStr = dateStr ..(h % 24) .. Language:getInstance():getString("@Hour")
    end

    local m = tonumber(hms[2])
    if h > 0 or m > 0 then
        dateStr = dateStr .. m .. Language:getInstance():getString("@Minute")
    end

    if withSecond == nil or withSecond == true or dateStr == "" then
        local s = tonumber(hms[3])
        dateStr = dateStr .. s .. Language:getInstance():getString("@Second")
    end

    return dateStr
end
-- 当时间为0时不显示时、分、秒
function common:second2DateString2(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])
    if h > 0 then
        if h >= 24 then
            local d = math.floor(h / 24)
            dateStr = d .. Language:getInstance():getString("@Days")
        end
        if h % 24 ~= 0 then
            dateStr = dateStr ..(h % 24) .. Language:getInstance():getString("@Hour")
        end
    end

    local m = tonumber(hms[2])
    if m > 0 then
        dateStr = dateStr .. m .. Language:getInstance():getString("@Minute")
    end

    if withSecond == nil or withSecond == true or dateStr == "" then
        local s = tonumber(hms[3])
        dateStr = dateStr .. s .. Language:getInstance():getString("@Second")
    end

    return dateStr
end
--格式: xxD xxH xxM xxS
function common:second2DateString3(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])
    local m = tonumber(hms[2])
    local s = tonumber(hms[3])

    dateStr = string.format("%02d", math.floor(h / 24)) .. "D "
    dateStr = dateStr .. string.format("%02d", math.floor(h % 24)) .. "H "
    dateStr = dateStr .. string.format("%02d", math.floor(m)) .. "M "
    if withSecond == nil or withSecond == true or dateStr == "" then   
        dateStr = dateStr .. string.format("%02d", math.floor(s)) .. "S"
    end

    return dateStr
end

function common:second2DateString4(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr ={}
    local h = tonumber(hms[1])
    local m = tonumber(hms[2])
    local s = tonumber(hms[3])
    dateStr[1]=string.format("%02d", math.floor(h / 24))
    dateStr[2]=string.format("%02d", math.floor(h % 24))
    dateStr[3]=string.format("%02d", math.floor(m))
    if withSecond == nil or withSecond == true or dateStr == "" then   
        dateStr[4]=string.format("%02d", math.floor(s))
    end

    return dateStr
end
--格式: 讀取@CountdownTime1/@CountdownTime2字串
function common:second2DateString5(second, withSecond)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")

    local h = math.floor(tonumber(hms[1]) % 24)
    local m = tonumber(hms[2])
    local s = tonumber(hms[3])
    local d = math.floor(tonumber(hms[1]) / 24)
    if withSecond == nil or withSecond == true then   
        return common:getLanguageString("@CountdownTime2", d, h, m, s)
    else
        return common:getLanguageString("@CountdownTime1", d, h, m)
    end
end

-- 添加某个时间分量到时间日期串，如 append（result, 10，分，不允许0（allowZero=false))
function common:appendTimePart(dateSet, value, unit, allowZero)
    if allowZero then
        if value >= 0 then
            dateSet[#dateSet + 1] = value .. unit
        end
    else
        if value > 0 then
            dateSet[#dateSet + 1] = value .. unit
        end
    end
end

-- 秒转日期，返回包含两个单位的串（如：10天20时、10小时20分（秒）...)
function common:secondToDateXXYY(second)
    local h = math.floor(second / 3600)
    local d = math.floor(h / 24)
    local m = math.floor((second - h * 3600) / 60)
    local s = math.floor(second - h * 3600 - 60 * m)

    local result = { }

    local timeParts = {
        d,(h -(d * 24)),m,s
    }

    local timeUnits = {
        '' .. Language:getInstance():getString("@Days"),
        '' .. Language:getInstance():getString("@Hour"),
        '' .. Language:getInstance():getString("@Minute"),
        '' .. Language:getInstance():getString("@Second")
    }
    local function removeEndSpace(str)
        local newStr = string.reverse(str)
        local a, b = string.find(newStr, " ")
        if a == 1 then
            newStr = string.sub(newStr, a + 1, string.len(newStr))
        end
        str = string.reverse(newStr)
        return str
    end
    for i = 1, #timeParts do
        common:appendTimePart(result, timeParts[i], timeUnits[i], false)
        if (#result > 1) then
            return removeEndSpace(result[1] .. result[2])
            -- return result[1]..result[2]
        end
    end

    if #result == 1 then
        return removeEndSpace(result[1])
    else
        return '' .. Language:getInstance():getString('@TimeEnd')
    end
end
-- 秒转日期，返回包含一个单位的串（如：10天，20时、20分（秒）...)
function common:secondToDateXX(second, max)
    local h = math.floor(second / 3600)
    local d = math.floor(h / 24)
    local useMax = false
    if max and type(max) == "number" then
        useMax = d > max
        d = math.min(max, d)
    end
    local m = math.floor((second - h * 3600) / 60)
    local s = math.floor(second - h * 3600 - 60 * m)

    local result = { }

    local timeParts = {
        d,(h -(d * 24)),m,s
    }

    local timeUnits = {
        '' .. Language:getInstance():getString("@Days"),
        '' .. Language:getInstance():getString("@Hour"),
        '' .. Language:getInstance():getString("@Minute"),
        '' .. Language:getInstance():getString("@Second")
    }
    local function removeEndSpace(str)
        local newStr = string.reverse(str)
        local a, b = string.find(newStr, " ")
        if a == 1 then
            newStr = string.sub(newStr, a + 1, string.len(newStr))
        end
        str = string.reverse(newStr)
        return str
    end
    for i = 1, #timeParts do
        common:appendTimePart(result, timeParts[i], timeUnits[i], false)
        if (#result > 1) then
            if useMax then
                return common:getLanguageString("@GuildMemberTwoDayAfter1", removeEndSpace(result[1]))
            else
                return removeEndSpace(result[1])
            end
            -- return result[1]..result[2]
        end
    end

    if #result == 1 then
        if useMax then
            return common:getLanguageString("@GuildMemberTwoDayAfter1", removeEndSpace(result[1]))
        else
            return removeEndSpace(result[1])
        end
    else
        return '' .. Language:getInstance():getString('@TimeEnd')
    end
end

function common:secondToDateXX2(second, max)
    local h = math.floor(second / 3600)
    local d = math.floor(h / 24)
    local useMax = false
    if max and type(max) == "number" then
        useMax = d > max
        d = math.min(max, d)
    end
    local m = math.floor((second - h * 3600) / 60)
    local s = math.floor(second - h * 3600 - 60 * m)

    local result = { }

    local timeParts = {
        d,(h -(d * 24)),m,s
    }

    local timeUnits = {
        '' .. "D",
        '' .. "hr",
        '' .. "min",
        '' .. "sec"
    }
    local function removeEndSpace(str)
        local newStr = string.reverse(str)
        local a, b = string.find(newStr, " ")
        if a == 1 then
            newStr = string.sub(newStr, a + 1, string.len(newStr))
        end
        str = string.reverse(newStr)
        return str
    end
    for i = 1, #timeParts do
        common:appendTimePart(result, timeParts[i], timeUnits[i], false)
        if (#result > 1) then
            if useMax then
                return common:getLanguageString("@GuildMemberTwoDayAfter1", removeEndSpace(result[1]))
            else
                return removeEndSpace(result[1])
            end
            -- return result[1]..result[2]
        end
    end

    if #result == 1 then
        if useMax then
            return common:getLanguageString("@GuildMemberTwoDayAfter1", removeEndSpace(result[1]))
        else
            return removeEndSpace(result[1])
        end
    else
        return '' .. Language:getInstance():getString('@TimeEnd')
    end
end

function common:stringToInt(str)
    local sum = 0
    local len = string.len(str)
    for index = 1, len do
        local byteValue = string.byte(str, index) - string.byte('0')
        local inc = byteValue * math.pow(10, len - index)
        sum = sum + inc
    end
    return sum
end
--------- 123456 ==>> *****6
function common:changeStringToPwdStyle(pwd)
    local nLen = string.len(pwd)
    local outPwd = ""
    for i = 1, nLen do
        if i == nLen then
            outPwd = outPwd .. string.sub(pwd, -1)
        else
            outPwd = outPwd .. "*"
        end
    end
    return outPwd
end


--[[
function common:secondToDateXXYY(second)
	h = math.floor(second / 3600)
	d = math.floor(h / 24)
	m = math.floor((second - h * 3600) / 60)
	s = (second - h*3600 - 60 * m)

	result = {}

	common:appendTimePart(result, d, Language:getInstance():getString("@Days"), false)

	h = h - (d * 24)
	common:appendTimePart(result, h, Language:getInstance():getString("@Hour"), false)
	if #result > 1 then
		return result[1]..result[2]
	end

	common:appendTimePart(result, m, Language:getInstance():getString("@Minute"), false)
	if #result > 1 then
		return result[1]..result[2]
	end

	common:appendTimePart(result, s, Language:getInstance():getString("@Second"), false)
	if #result > 1 then
		return result[1]..result[2]
	end

	if #result == 1 then
		return result[1]
	end

	return '' .. Language:getInstance():getString('@TimeEnd')
end
--]]
function common:second2DateHourString(second)
    local hms = Split(GameMaths:formatSecondsToTime(second), ":")
    local dateStr = ""

    local h = tonumber(hms[1])
    if h > 0 then
        if h >= 24 then
            local d = math.floor(h / 24)
            dateStr = d .. Language:getInstance():getString("@Days")
        end
        dateStr = dateStr ..(h % 24) .. Language:getInstance():getString("@Hour")
    end

    return dateStr
end

function common:isCrossDay(lastTime)
    if lastTime then
        return self:isDifferendDay(lastTime, GamePrecedure:getInstance():getServerTime())
    end
    return false
end

function common:isDifferendDay(time1, time2)
    local ymd1 = Split(GameMaths:formatTimeToDate(tonumber(time1)), " ")
    local ymd2 = Split(GameMaths:formatTimeToDate(tonumber(time2)), " ")

    return ymd1[1] ~= ymd2[1]
end

function common:showGiftPackage(itemId)
    local item = ToolTableManager:getInstance():getToolItemByID(itemId)
    if item.includeStr == "none" or self:trim(item.includeStr) == "" then return end
    local gifts = Split(item.includeStr, ",")

    GoodsViewPage.mViewGoodsListInfo = { }
    for index, giftStr in ipairs(gifts) do
        local giftInfo = Split(giftStr, ":")
        self:table_map(giftInfo, tonumber)
        local gift = ResManager:getInstance():getResInfoByTypeAndId(giftInfo[1], giftInfo[2], giftInfo[3])
        GoodsViewPage.mViewGoodsListInfo[index] = {
            type = ResManager:getInstance():getResMainType(gift.type),
            name = gift.name,
            icon = gift.icon,
            count = gift.count,
            quality = gift.quality
        }
    end

    GoodsViewPage.mTitle = "@PackPreviewTitleView"
    GoodsViewPage.mMsgContent = "@PackPreviewMsgView"

    MainFrame:getInstance():pushPage("GoodsShowListPage")
end


function common:showGiftPackageWithTitle(itemId, packageTitle, packageDesc)
    local item = ToolTableManager:getInstance():getToolItemByID(itemId)
    if item.includeStr == "none" or self:trim(item.includeStr) == "" then return end
    local gifts = Split(item.includeStr, ",")

    GoodsViewPage.mViewGoodsListInfo = { }
    for index, giftStr in ipairs(gifts) do
        local giftInfo = Split(giftStr, ":")
        self:table_map(giftInfo, tonumber)
        local gift = ResManager:getInstance():getResInfoByTypeAndId(giftInfo[1], giftInfo[2], giftInfo[3])
        GoodsViewPage.mViewGoodsListInfo[index] = {
            type = ResManager:getInstance():getResMainType(gift.type),
            name = gift.name,
            icon = gift.icon,
            count = gift.count,
            quality = gift.quality
        }
    end

    GoodsViewPage.mTitle = packageTitle
    GoodsViewPage.mMsgContent =(packageDesc ~= nil) and packageDesc or '@PackPreviewMsgView'

    MainFrame:getInstance():pushPage("GoodsShowListPage")
end
-- end

function common:showResInfo(itemType, itemId)
    local resType = ResManagerForLua:getResMainType(itemType)
    if resType == TOOLS_TYPE then
        local item = ToolTableManager:getInstance():getToolItemByID(itemId)
        if item.includeStr == "none" or self:trim(item.includeStr) == "" then
            PropInfoPage:showPropInfoPage(itemId, 2, false)
            -- 2: SHOW_TYPE
        else
            self:showGiftPackage(itemId)
        end
    elseif resType == EQUIP_TYPE then
        EquipHandInfoPage:showEquipPage(itemId, true)
    elseif resType == DISCIPLE_TYPE or resType == DISCIPLE_TYPE then
        DiscipleHandInfoPage:showDisciplePage(itemId, true)
    elseif resType == SKILL_TYPE then
        SkillHandInfoPage:showSkillPage(itemId, true)
    elseif resType == TREASURE_TYPE then
        if BlackBoard:getInstance():hasVarible("IsTreasureItem") == false then
            BlackBoard:getInstance():addVarible("IsTreasureItem", true);
        else
            BlackBoard:getInstance():setVarible("IsTreasureItem", true);
        end
        BlackBoard:getInstance().ShowTreasure = itemId;
        PageManager.pushPage("TreasureInfoPage");
    end
    -- using the following code after the big version released
    -- PopupPageManager:showResInfo(itemType, itemId)
end

function common:showResInfoByRewardContent(rewardContent, index)
    local rewardItems = getResTable(rewardContent)
    for i = 1, table.maxn(rewardItems) do
        if index == i then
            local rewardItem = rewardItems[i]
            if rewardItem ~= nil then
                PopupPageManager:showResInfo(rewardItem.type, rewardItem.itemId)
            end
        end
    end
end

function common:goHelpPage(helpString)
    local helpInfo = { }
    local attrs = { "title", "content" }
    for _, item in ipairs(Split(helpString, "#")) do
        table.insert(helpInfo, self:table_combine(attrs, Split(item, "_")))
    end

    CommonHelpPageVar.set(helpInfo)
    MainFrame:getInstance():pushPage("CommonHelpPage")
end

function common:table_combine(keys, values)
    local tb = { }
    for index, key in ipairs(keys) do
        tb[key] = values[index]
    end
    return tb
end

function common:table_combineNumber(keys, start, step)
    local tb = { };

    local val = start or 0;
    local step = step or 1;
    for _, key in ipairs(keys) do
        tb[key] = val;
        val = val + step;
    end

    return tb;
end

-- simple and rough version, be careful
function common:table_merge(...)
    local tb = { }
    for i = 1, select("#", ...) do
        table.foreach((select(i, ...)), function(k, v)
            tb[k] = v
        end )
    end
    return tb
end

function common:table_map(tb, func)
    table.foreach(tb, function(k, v) tb[k] = func(v) end)
end

function common:table_reflect(tb, func)
    local _tb = { };
    table.foreach(tb, function(k, v) _tb[k] = func(v) end);
    return _tb;
end

function common:table_keys(tb)
    local keys = { }
    for k, _ in pairs(tb) do table.insert(keys, k) end
    return keys
end

function common:table_values(tb)
    local values = { }
    table.foreach(tb, function(k, v) table.insert(values, v) end)
    return values
end

function common:table_hasValue(tb, val)
    for _, v in pairs(tb) do
        if v == val then return true; end
    end
    return false;
end

-- not deep copy
function common:table_removeFromArray(tb, val)
    local _tb = { };
    for _, v in ipairs(tb) do
        if v ~= val then
            table.insert(_tb, v);
        end
    end
    return _tb;
end

-- not deep copy
function common:table_sub(tb, start, len)
    local _tb = { };
    for i = start, start + len - 1 do
        local v = tb[i];
        if v then
            table.insert(_tb, v);
        end
    end
    return _tb;
end

function common:table_tail(tb, len)
    local _tb = { };
    for i = #tb, #tb - len + 1, -1 do
        local v = tb[i];
        if v then
            table.insert(_tb, v);
        end
    end
    return _tb;
end

function common:table_isEmpty(tb)
    if tb then
        for _, v in pairs(tb) do
            return false;
        end
    end
    return true;
end

function common:table_filter(tb, filter)
    local _tb = { };
    for k, v in pairs(tb) do
        if filter(k, v) then
            _tb[k] = v;
        end
    end
    return _tb;
end

function common:table_arrayFilter(tb, filter)
    local _tb = { };
    for _, v in pairs(tb) do
        if filter(v) then
            table.insert(_tb, v);
        end
    end
    return _tb;
end

function common:table_flip(tb)
    local _tb = { };
    table.foreach(tb, function(k, v) _tb[v] = k; end);
    return _tb;
end

function common:table_implode(tb, glue)
    local str = "";
    for k, v in pairs(tb) do
        if str ~= "" then
            str = str .. glue;
        end
        str = str .. tostring(v);
    end
    return str;
end

function common:table_count(tb)
    local c = 0;
    for k, v in pairs(tb) do c = c + 1; end
    return c;
end

function common:table_arrayIndex(tb, v)
    for i, _v in ipairs(tb) do
        if _v == v then
            return i;
        end
    end
    return -1;
end

function common:table_isSame(tb_1, tb_2)
    -- to be better
    for k, v in pairs(tb_1) do
        if v ~= tb_2[k] then
            return false;
        end
    end
    for k, v in pairs(tb_2) do
        if v ~= tb_1[k] then
            return false;
        end
    end
    return true;
end

--- 消除换行符制表符\n\r\t
function common:deleteNTR(s)
    return s:gsub("\\n", ""):gsub("\\r", ""):gsub("\\t", ""):gsub("\n", ""):gsub("\r", ""):gsub("\t", "")
end

function common:trim(s)
    return(tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function common:fill(s, ...)
    local o = tostring(s)
    for i = 1, select("#", ...) do
        -- o = o:gsub("#v" .. i .. "#", tostring(select(i, ...)))
        o = GameMaths:replaceStringWithCharacterAll(o, "#v" .. i .. "#", tostring(select(i, ...)))
    end
    return o
end

function common:fill_1(s, t)
    local str = tostring(s)
    for i = 1, #t do
        str = string.gsub(str , "#v" .. i .. "#" , t[i] , 1)
    end
    return str
end


function common:getPowSize(num)
    local powSize = 1;
    while num ~= 1 do
        num = math.ceil(num / 2)
        powSize = powSize * 2
    end
    return powSize
end

function common:deepCopy(object)
    local lookup_table = { }

    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = { }
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end

function common:stringAutoReturn(s, width, glue)
    local glue = glue or "\n";
    local lines = self:split(tostring(s), "\n")
    for i, line in ipairs(lines) do
        if width ~= nil and tonumber(width) >= 0 then
            lines[i] = GameMaths:stringAutoReturnForLua(line, width, 0)
        end
    end
    return table.concat(lines, glue)
end

function common:setQualityColor(node, quality)
    if node == nil then
        CCLuaLog("Error in common:setQualityColor==> node is nil")
        return
    end

    quality = common:getQuality(quality)

    local color = self:getSettingVar("FrameColor_Quality" .. quality)
    local color3B = StringConverter:parseColor3B(color)
    node:setColor(color3B)
end

function common:setFrameQuality(node, quality)
    if node == nil then
        CCLuaLog("Error in common:setFrameQuality==> node is nil")
        return
    end

    quality = common:getQuality(quality)

    node:setNormalImage(getFrameNormalSpirte(quality))
    node:setSelectedImage(getFrameSelectedSpirte(quality))
end

function common:getQuality(quality)
    if quality > QualityInfo.MaxQuality or quality < QualityInfo.MinQuality then
        quality = QualityInfo.NoQuality
    end
    return quality
end

function common:setScaleByResInfoType(node, itemType, commonScale)
    if node == nil then
        CCLuaLog("node is Null for set scale")
        return
    end

    itemType = tonumber(itemType or 0)
    local resType = ResManager:getInstance():getResMainType(itemType)
    local scale = commonScale or 0.4

    if resType == DISCIPLE_TYPE or resType == DISCIPLE_BOOK then
        scale = scale * 3.0
    end
    node:setScale(scale)
end

function common:Log(str)
    if Golb_Platform_Info.is_win32_platform then
        CCLuaLog(str)
    end
end

function common:log(format, ...)
    CCLuaLog(string.format(format, ...))
end

function common:sendPacket(opcode, message, needWaiting)
    local pb_data = message:SerializeToString();
    local needWaiting = needWaiting == nil and true or needWaiting;
    PacketManager:getInstance():sendPakcet(opcode, pb_data, #pb_data, needWaiting);
end

function common:sendEmptyPacket(opcode, needWaiting)
    local needWaiting = needWaiting == nil and true or needWaiting;
    PacketManager:getInstance():sendPakcet(opcode, "", 0, needWaiting);
end

function common:getEquipPartName(partId)
    return self:getLanguageString(string.format("@EquipPart_" .. partId));
end

function common:getAttrName(attrId)
    return self:getLanguageString(string.format("@AttrName_" .. attrId));
end

function common:getGsubStr(infoTab, str)
    if infoTab == nil or #infoTab == 0 then return end
    for i = 1, #infoTab, 1 do
        str = string.gsub(str, "#v" .. i .. "#", infoTab[i])
    end
    return str
end

function common:split(str, delim, maxNb)

   if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0
        -- No limit
    end
    local result = { }
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function common:fillHtmlStr(key, ...)
    local id = GameConfig.FreeTypeId[key];
    if id ~= nil then
        local cfg = FreeTypeConfig[id];
        if cfg then
            return common:fill(cfg.content, ...);
        end
    end
    return "";
end
-- 广播中翅膀要变颜色，加了NormalHtmlLabel.txt
function common:fillNormalHtmlStr(id, ...)
    local ConfigManager = require("ConfigManager")
    local HtmlCfg = ConfigManager.getNormalHtmlCfg()
    if id ~= nil then
        local cfg = HtmlCfg[id];
        if cfg then
            return common:fill(cfg.content, ...);
        end
    end
    return "";
end

function common:getColorFromConfig(key)
    local cfg = GameConfig.Color[key] or { };
    local r, g, b = unpack(cfg);
    return ccc3(r, b, b);
end


function common:popString(str, colorKey)
    local wordList = { str };
    local colorList = { GameConfig.ColorMap[colorKey] };
    insertMessageFlow(wordList, colorList);
end

function common:popRewardString(rewardsCfg)
    local wordList = { }
    local colorList = { }
    local rewards = rewardsCfg
    for i = 1, #rewards do
        local oneReward = rewards[i]
        if oneReward.count > 0 then
            local ResManager = require "ResManagerForLua"
            local resInfo = ResManager:getResInfoByTypeAndId(oneReward.type, oneReward.itemId, oneReward.count);
            local getReward = Language:getInstance():getString("@GetRewardMSG");
            -- GodlyEquip
            local rewardName = resInfo.name;
            if resInfo.mainType == Const_pb.EQUIP then
                rewardName = string.format("%d %s", EquipManager:getLevelById(oneReward.itemId), rewardName);
                rewardName = common:getR2LVL() .. rewardName
            end
            local rewardStr = rewardName .. " ×" .. oneReward.count .. " ";
            local itemColor = ""
            if resInfo.quality == 1 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
            elseif resInfo.quality == 2 then
                itemColor = GameConfig.ColorMap.COLOR_GREEN
            elseif resInfo.quality == 3 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 4 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 5 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 6 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 7 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 8 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 9 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 10 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 11 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 12 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 13 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            elseif resInfo.quality == 14 then
                itemColor = GameConfig.ColorMap.COLOR_RED
            elseif resInfo.quality == 15 then
                itemColor = GameConfig.ColorMap.COLOR_BLUE
            elseif resInfo.quality == 16 then
                itemColor = GameConfig.ColorMap.COLOR_PURPLE
            elseif resInfo.quality == 17 then
                itemColor = GameConfig.ColorMap.COLOR_ORANGE
            end
            -- local newEquipStr = common:fill(equipStr,rewardStr)
            -- table.insert(wordList,rewardStr)
            local finalStr = getReward
            finalStr = finalStr .. rewardStr
            table.insert(wordList, finalStr)
            table.insert(colorList, itemColor)
        end
    end
    insertMessageFlow(wordList, colorList)
end

function common:checkStringLegal(str)
    -- str = RestrictedWord:getInstance():filterWordSentence(str)
    str = str:gsub("&", "*")
    str = str:gsub("#", "*")
    str = str:gsub("<", "*")
    str = str:gsub(">", "*")
    return str
end
-- true 男 false 女

function common:checkPlayerSexByItemId(itemId)
    if itemId >= 1 and itemId <= 3 then
        return true
    else
        return false
    end
end

function common:table_size_raw(inputTable)
    local size = 0;
    for k, v in pairs(inputTable) do
        size = size + 1
    end
    return size
end

function common:getShortName(sName, nMaxCount, nShowCount)
    if sName == nil or nMaxCount == nil then
        return
    end
    local sStr = sName
    local tCode = { }
    local tName = { }
    local nLenInByte = #sStr
    local nWidth = 0
    if nShowCount == nil then
        nShowCount = nMaxCount - 3
    end
    for i = 1, nLenInByte do
        local curByte = string.byte(sStr, i)
        local byteCount = 0;
        if curByte > 0 and curByte <= 127 then
            byteCount = 1
        elseif curByte >= 192 and curByte < 223 then
            byteCount = 2
        elseif curByte >= 224 and curByte < 239 then
            byteCount = 3
        elseif curByte >= 240 and curByte <= 247 then
            byteCount = 4
        end
        local char = nil
        if byteCount > 0 then
            char = string.sub(sStr, i, i + byteCount - 1)
            i = i + byteCount - 1
        end
        if byteCount == 1 then
            nWidth = nWidth + 1
            table.insert(tName, char)
            table.insert(tCode, 1)

        elseif byteCount > 1 then
            nWidth = nWidth + 2
            table.insert(tName, char)
            table.insert(tCode, 2)
        end
    end

    if nWidth > nMaxCount then
        local _sN = ""
        local _len = 0
        for i = 1, #tName do
            _sN = _sN .. tName[i]
            _len = _len + tCode[i]
            if _len >= nShowCount then
                break
            end
        end
        sName = _sN .. "..."
    end
    return sName
end


function common:parseItemWithComma(rewards)
    local rewardItems = { }
    if rewards ~= nil then
        for _, item in ipairs(self:split(rewards, ",")) do
            local _type, _id, _count = unpack(self:split(item, "_"));
            table.insert(rewardItems, {
                type = tonumber(_type),
                itemId = tonumber(_id),
                count = tonumber(_count)
            } );
        end
    end
    return rewardItems
end
-- -
function common:parseItemWithCommaId(rewards)
    local rewardItems = { }
    if rewards ~= nil then
        for _, item in ipairs(self:split(rewards, ",")) do
            local _type, _id, _count = unpack(self:split(item, "_"));
            table.insert(rewardItems, {
                itemType = tonumber(_type),
                itemId = tonumber(_id),
                itemCount = tonumber(_count)
            } );
        end
    end
    return rewardItems
end

function common:isKakaoImgExist(fileName)
    local fileFloder = "httpImg/"
    return CCFileUtils:sharedFileUtils():isFileExist(fileFloder .. fileName)
end
function common:CompletedImgName(name)
    -- 处理资源图片文件。如果没后缀则添加后缀 20150331

    local imgName;
    name = string.lower(name)
    -- 转换成小写
    local sss = string.sub(name, -4)
    if string.sub(name, -4) == ".jpg" or string.sub(name, -4) == ".png" then
        imgName = name
    else
        imgName = name .. ".jpg"
    end
    return imgName
end
function common:getHtmlImgName(url)
    local imgName = url
    while (string.find(imgName, "/")) do
        local first, last = string.find(imgName, "/")
        imgName = string.sub(imgName, last + 1, string.len(imgName))
    end
    return imgName
end

function common:getR2LVL()
    local str = Language:getInstance():getString("@Lvl")
    if str == "@Lvl" then
        str = "Lv."
    end
    return str
end

function common:getR2LVLName(level, name)
    local str = Language:getInstance():getString("@LvlName")
    if str == "@LvlName" then
        str = "Lv."
        str = str .. level .. name
    else
        str = common:fill(str, level, name)
    end
    return str
end

function common:getR2FrHonner(honner)
    local str = Language:getInstance():getString("@Honor_Fr")
    if str == "@Honor_Fr" then
        str = honner .. common:getLanguageString('@Honor')
    else
        str = common:fill(str, honner)
    end
    return str
end

function common:getSkillDetailLength()
    if Golb_Platform_Info.is_r2_platform then
        return 27
    elseif Golb_Platform_Info.is_efun_platform then
        return 17
    elseif Golb_Platform_Info.is_entermate_platform then
        return 22
    elseif Golb_Platform_Info.is_gNetop_platform then
        return 20
    end
    return 17
end


function common:reverseArray(inpuTable, size)
    local newArray = { }
    for k, v in pairs(inpuTable) do
        newArray[size] = v
        size = size - 1
    end
    return newArray
end

function common:getI18nChatMsg(msgContent)
    local str = msgContent
    local json = require('json')
    local temp = json.decode(str)
    if temp ~= nil then
        local serverKey = temp.key
        local cfg = ConfigManager.getServerBroadCodeCfg()
        if serverKey ~= nil and cfg ~= nil then
            for k, v in ipairs(temp.data) do
                if string.find(v, "@") then
                    temp.data[k] = Language:getInstance():getString(v)
                end
            end
            for k, v in pairs(cfg) do
                if v.serverKey == serverKey then
                    str = self:fill(v.langKey, unpack(temp.data))
                    return str
                end
            end
        end
    end
    return str
end


function common:getI18nLanguageType(srcPath)
    local cfg = ConfigManager.getI18nTxtCfg()
    for k, v in pairs(cfg) do
        if v.srcPath == srcPath then
            return v.languageType
        end
    end
    return -1
end

function common:getSelfI18nLanguageType()
    local path = GamePrecedure:getInstance():getI18nSrcPath()
    local lType = self:getI18nLanguageType(path)
    return lType
end
function common:table_is_empty(t)
    return _G.next(t) == nil
end

function common:getSelfI18nLanguageMvpType()
    local path = GamePrecedure:getInstance():getI18nSrcPath()
    local cfg = ConfigManager.getI18nTxtCfg()
    for k, v in pairs(cfg) do
        if v.srcPath == path then
            return v.r2MvpRecharge
        end
    end
    return 0
end

function common:getSelfI18nLanguageName()
    local path = GamePrecedure:getInstance():getI18nSrcPath()
    local cfg = ConfigManager.getI18nTxtCfg()
    for k, v in pairs(cfg) do
        if v.srcPath == path then
            return v.languageName
        end
    end
    return "en"
end

-- 根据包名获取渠道包的标识  即包名最后一段
function common:getChannelName()
    -- body
    local instance = libOS:getInstance();
    -- body
    local channelName = ""
    -- 判断函数是否存在
    if type(instance.getPackageNameToLua) ~= "function" then
        return channelName;
    end
    -- 存在则处理换包逻辑
    local packageName = libOS:getInstance():getPackageNameToLua()
    if packageName ~= "" then
        local packageNameArray = common:split(packageName, "%.")
        channelName = packageNameArray[#packageNameArray]
    end
    return channelName;
end
function clearTable(t)
    -- body
    for key, value in pairs(t) do
        t[key] = nil
    end
end

function yuan3(condition, param1, param2)
    -- body
    if condition == true then
        return param1
    else
        return param2
    end
end
-- 根据包名获取渠道包的标识  即包名最后一段
function common:getChannelName()
    -- body
    local instance = libOS:getInstance();
    -- body
    local channelName = ""
    -- 判断函数是否存在
    if type(instance.getPackageNameToLua) ~= "function" then
        return channelName;
    end
    -- 存在则处理换包逻辑
    local packageName = libOS:getInstance():getPackageNameToLua()
    if packageName ~= "" then
        local packageNameArray = common:split(packageName, "%.")
        channelName = packageNameArray[#packageNameArray]
    end
    return channelName;
end

function common:openURL(url)
    if BlackBoard:getInstance().PLATFORM_TYPE_FOR_LUA == 2 then
        if string.sub(url, 1, 5) == "https" then
            libOS:getInstance():openURLHttps(url)
        else
            libOS:getInstance():openURL(url)
        end
    else
        libOS:getInstance():openURL(url)
    end
end

--
function common:formatString(srcString, ...)
    for i, v in ipairs(arg) do
        srcString = string.gsub(srcString, "{" .. i .. "}", v)
    end
    return srcString
end
function common:new(target, source)
    target = target or { }
    setmetatable(target, source)
    source.__index = source
    return target
end
function common:numberRounding(num)
    if tonumber(num) >= 0.5 then
        return math.ceil(num)
    end

    return math.floor(num)
end

function common:toHex(num)
    local HEX_MAP = {
        [10] = "A",
        [11] = "B",
        [12] = "C",
        [13] = "D",
        [14] = "E",
        [15] = "F",
    }
    local hexBase = num % 16
    local hexNext = math.floor(num / 16)
    local hexStr = ""
    if HEX_MAP[hexBase] then
        hexStr = hexStr .. HEX_MAP[hexBase]
    else
        hexStr = hexStr .. tostring(hexBase)
    end
    if hexNext > 0 then
        hexStr = common:toHex(hexNext) .. hexStr
    end

    return hexStr
end
-- 充值弹出
-- currencyType = 货币类型  0 = 金币 1 = 钻石
function common:rechargePageFlag(activityName, currencyType)
    if activityName == nil then
        activityName = ""
    end
    local title = common:getLanguageString('@HintTitle')
    local message = common:getLanguageString('@LackGold')
    PageManager.showConfirm(title, message,
    function(agree)
        if agree then
            -- 钻石不足充值
            libPlatformManager:getPlatform():sendMessageG2P("G2P_ENTER_RECHARGE_PAGE", "Activity_enter_rechargePage_" .. activityName)
            PageManager.pushPage("RechargePage")
        end
    end
    )
end

 
-- 竞技场战报弹出
function common:arenaViewBattle(battleInfo)
    local UserInfo = require("PlayerInfo.UserInfo")
    local chars = battleInfo.battleData.character;
    local leftName = ""
    local rightName = ""
    for i = #chars, 1, -1 do
        local pos = chars[i].pos;
        if common:numberIsEven(pos) then
            local playId = chars[i].playerId == UserInfo.playerInfo.playerId
            if playId then
                leftName = common:getLanguageString("@Self")
                rightName = common:getLanguageString("@Enemy")
            else
                leftName = common:getLanguageString("@Enemy")
                rightName = common:getLanguageString("@Self")
            end
            break
        end
    end
    PageManager.viewBattlePage(battleInfo, leftName, rightName)
end
--- 批量处理一个table的setter getter(元表和显式方法)
--- 作用域 , 1 public 2 private 0 null
--- 以function作为setter和getter时，作用域为private
function common:initModuleProperty(_module, propertyMap, changeMeta)
    local propMap = rawget(_module, "_P") or { }
    for k, v in pairs(propertyMap) do
        local upKey = string.upper(string.sub(k, 1, 1)) .. string.sub(k, 2)
        if v.get and(type(v.get) == "function" or v.get > 0) then
            _module["get" .. upKey] = function(_module)
                local value = nil
                if not changeMeta then
                    value = _module[k]
                else
                    value = v.value or v.default
                end
                if type(v.get) == "function" then
                    return v.get(value)
                else
                    return value
                end
            end
        end
        if v.set and(type(v.set) == "function" or v.set > 0) then
            _module["set" .. upKey] = function(_module, value)
                if not changeMeta then
                    _module[k] = value
                else
                    v.value = value
                end
                if type(v.set) == "function" then
                    v.set(v)
                end
            end
        end
        if not changeMeta then
            if v.default then
                _module[k] = v.default
            end
        else
            if v.default then
                v.value = v.default
            end
        end
        propMap[k] = v
    end
    rawset(_module, "_P", propMap)
    if changeMeta then
        local __newIndex = function(t, k, v)
            local propMap = rawget(t, "_P") or { }
            if propMap[k] and propMap[k].set and propMap[k].set == 1 then
                propMap[k].value = v
                rawset(t, "_P", propMap)
            else
                error("this props is not allowed to set value")
            end
        end
        local __index = function(t, k)
            local propMap = rawget(t, "_P") or { }
            if propMap[k] and propMap[k].get and propMap[k].get == 1 then
                if propMap[k].value ~= nil then
                    return propMap[k].value
                else
                    return propMap[k].default
                end
            else
                error("this props is not allowed to get value")
            end
        end
        local meta = getmetatable(_module) or { }
        meta.__newindex = __newIndex
        meta.__index = __index
        setmetatable(_module, meta)
    end
end
------清理和还原上面方法赋值的table属性
function common:resetModuleProperty(_module, propertyMap, changeMeta)
    local propMap = rawget(_module, "_P") or { }
    for k, v in pairs(propertyMap) do
        if not v.notClean then
            local upKey = string.upper(string.sub(k, 1, 1)) .. string.sub(k, 2)
            if not changeMeta then
                _module[k] = v.default
            else
                v.value = v.default
            end
            propMap[k] = v
        end
    end
    rawset(_module, "_P", propMap)
end

function common:getTableLen(t)
    local len = 0

    for k, v in pairs(t) do
        len = len + 1
    end

    return len
end

----------------------------------------------------------------
function logTableAll(mTable, head)
    if not head then
        head = ""
    end

    CCLuaLog(head .. "{")
    local newHead = "	" .. head
    for key, value in pairs(mTable) do
        if type(value) == "table" then
            CCLuaLog(newHead .. "\"" .. tostring(key) .. "\" = ")
            logTableAll(value, newHead)
        elseif type(value) == "string" then
            CCLuaLog(newHead .. "\"" .. tostring(key) .. "\" = \"" .. tostring(value) .. "\",")
        else
            CCLuaLog(newHead .. "\"" .. tostring(key) .. "\" = " .. tostring(value) .. ",")
        end
    end
    CCLuaLog(head .. "},")
end

function GetWordToNodeSpacePosition(container, nodeName, offsetX, offsetY)
    if container ~= nil then
        local node = container:getVarNode(nodeName)
        if node ~= nil then
            local screenSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
            local wordx = screenSize.width
            local wordy = screenSize.height
            local pointPos = node:getParent():convertToNodeSpace(ccp(wordx - offsetX, wordy - offsetY))
            return pointPos
        else
            return ccp(0, 0)
        end
    end
    return ccp(0, 0)
end

function GetScreenWidthAndHeight()
    local screenSize = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
    local wordx = screenSize.width
    local wordy = screenSize.height
    return wordx, wordy
end
function GetIsShow30Day()
    local isShow = false
    local GuideManager = require("Guide.GuideManager")
    local UserInfo = require("PlayerInfo.UserInfo")
    if GuideManager.isInGuide  then
        return isShow
    end
    --[[    if not isShow then
        return isShow
    end]]
    -- 审核期间不弹30天登录
    if GameConfig.isIOSAuditVersion then
        isShow = false
        return isShow
    end


    local curTime = common:getServerTimeByUpdate()
    local UserInfo = require("PlayerInfo.UserInfo")
    local lastShow30DayTime = CCUserDefault:sharedUserDefault():getStringForKey("Open30DayPage" .. UserInfo.playerInfo.playerId)
    if lastShow30DayTime == "" then
        if ActivityInfo.Day30Ids == nil or #ActivityInfo.Day30Ids == 0 then
            isShow = false
        else
            isShow = true
        end
    else
        local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
        local curDay = curServerTime.day
        local lastShow30DayPageSeverTime = os.date("!*t", tonumber(lastShow30DayTime) - common:getServerOffset_UTCTime())
        local lastShow30DayPageDay = lastShow30DayPageSeverTime.day
        if tonumber(curDay) ~= tonumber(lastShow30DayPageDay) then
            if ActivityInfo.Day30Ids == nil or #ActivityInfo.Day30Ids == 0 then
                isShow = false
            else
                isShow = true
            end
        else
            isShow = false
        end
    end
    return isShow
end

function GetIsShowPopBanner()
    local isShow = false
    local GuideManager = require("Guide.GuideManager")
    local UserInfo = require("PlayerInfo.UserInfo")
    if GuideManager.isInGuide or tonumber(UserInfo.roleInfo.level) < 5 then
        return isShow
    end
    --[[    if not isShow then
        return isShow
    end]]
    -- 审核期间不弹30天登录
    if GameConfig.isIOSAuditVersion then
        isShow = false
        return isShow
    end

    local BannerCfg = ConfigManager:getBannerCfg()
    local curTime = common:getServerTimeByUpdate()
    local lastShowPopBanner = CCUserDefault:sharedUserDefault():getStringForKey("OpenPopBanner" .. UserInfo.playerInfo.playerId)
    if lastShowPopBanner == "" then
        if BannerCfg == nil or #BannerCfg == 0 then
            isShow = false
        else
            isShow = true
        end
    else
        local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
        local curDay = curServerTime.day
        local lastShowPopBannerSeverTime = os.date("!*t", tonumber(lastShowPopBanner) - common:getServerOffset_UTCTime())
        local lastShowPopBannerDay = lastShowPopBannerSeverTime.day
        if tonumber(curDay) ~= tonumber(lastShowPopBannerDay) then
            if BannerCfg == nil or #BannerCfg == 0 then
                isShow = false
            else
                isShow = true
            end
        else
            isShow = false
        end
    end
    return isShow
end

function GetIsShowLimit124()
    local isShow = false
    local GuideManager = require("Guide.GuideManager")
    local UserInfo = require("PlayerInfo.UserInfo")
    if GuideManager.isInGuide or tonumber(UserInfo.roleInfo.level) < 13 or UserInfo.isUseLottery then
        return isShow
    end
    local curTime = common:getServerTimeByUpdate()
    local UserInfo = require("PlayerInfo.UserInfo")
    local lastShow30DayTime = CCUserDefault:sharedUserDefault():getStringForKey("OpenActTimeLimit124Page" .. UserInfo.playerInfo.playerId)
    local isHaveId = ActivityInfo:getActivityIsOpenById(124)
    if lastShow30DayTime == "" then
        if isHaveId == false then
            isShow = false
        else
            isShow = true
        end
    else
        local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
        local curDay = curServerTime.day
        local lastShow30DayPageSeverTime = os.date("!*t", tonumber(lastShow30DayTime) - common:getServerOffset_UTCTime())
        local lastShow30DayPageDay = lastShow30DayPageSeverTime.day
        if tonumber(curDay) ~= tonumber(lastShow30DayPageDay) then
            if isHaveId == false then
                isShow = false
            else
                isShow = true
            end
        else
            isShow = false
        end
    end
    return isShow
end

function LoginOverOneDay()
    local isOver = false
    if GameConfig.loginTimeStamp == nil then
        return isOver
    end
    local loginDaySever = os.date("!*t", GameConfig.loginTimeStamp - common:getServerOffset_UTCTime())
    local curTime = common:getServerTimeByUpdate()
    local curServerTime = os.date("!*t", curTime - common:getServerOffset_UTCTime())
    local curDay = curServerTime.day
    local loginDay = loginDaySever.day
    if tonumber(loginDay) ~= tonumber(curDay) then
        isOver = true
    else
        isOver = false
    end
    return isOver
end

function common:getCurServerTime()
    local curTime = GamePrecedure:getInstance():getServerTime()
    return curTime
end

function common:getServerOffset_UTCTime()
    if ServerOffset_UTCTime == nil then
        return -9 * 3600
    else
        return ServerOffset_UTCTime
    end
end
function common:getServerTimeByUpdate()
    if localSeverTime == nil then
        return GamePrecedure:getInstance():getServerTime()
    else
        return localSeverTime
    end
end

function common:getPlayeIcon(prof, iconID, isChatPage)
    local table = {
        MainPageIcon =
        {
            [1] = "UI/Role/Portrait_99900.png",
        },
        chatIcon =
        {
            [1] = "UI/Role/Portrait_99900.png",
        },
    }
    local bgQulity = {
        MainPageIcon =
        {
            [1] = "Imagesetfile/ChangeIcon/ChangeIcon_bluewbg.png",
        },
        chatIcon =
        {
            [1] = "Imagesetfile/ChangeIcon/ChangeIcon_chatbluebg.png",
        },
    }
    prof = prof or 1
    iconID = iconID or 0
    isChatPage = isChatPage or false
    local bgPath = nil
    if isChatPage then
        bgPath = "Imagesetfile/ChangeIcon/ChangeIcon_chatbluebg.png"
    else
        bgPath = "Imagesetfile/ChangeIcon/ChangeIcon_bluewbg.png"
    end

    if iconID == nil or tonumber(iconID) == 0 then
        if isChatPage then
            return table.chatIcon[tonumber(prof)] or table.chatIcon[1], bgPath
        else
            return table.MainPageIcon[tonumber(prof)] or table.MainPageIcon[1], bgPath
        end
    else
        --local roleTable = NodeHelper:getNewRoleTable(tonumber(iconID))
        if isChatPage then
            return "UI/Role/Portrait_" .. string.format("%05d", iconID) .. ".png", bgPath
        else
            return "UI/Role/Portrait_" .. string.format("%05d", iconID) .. ".png", bgPath
        end
    end
end
function common:getPlaformType()
    return CC_TARGET_PLATFORM_LUA
end
function common:getPopUpData(GiftId)
    local cfg = ConfigManager.getPopUpCfg2()
    local _data = common:deepCopy(cfg)
    for _, data in pairs(_data) do
        if data.GiftId == GiftId then                   
            data.Icon = "BG/Act_TimeLimit_132/" ..data.Icon
            data.BG = "BG/Act_TimeLimit_132/" .. data.BG               
            return data
        end
    end
end
return common;