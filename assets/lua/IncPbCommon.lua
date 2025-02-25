
GameConfig = require("GameConfig");
ConfigManager = require("ConfigManager");
PageManager = require("PageManager");
EquipManager = require("Equip.EquipManager");
require("Activity.ActivityInfo");

ViewPlayerInfo = require("PlayerInfo.ViewPlayerInfo");
UserEquipManager = require("Equip.UserEquipManager");
ResManagerForLua = require("ResManagerForLua");

mCurLangPath = "none";
function RegisterLuaPage(pageName)
	
	registerScriptPage(pageName);
	
end


function getRewardInfo(msg)
    if msg~=nil then
        local contentTable=getResTable(msg)
        if contentTable~=nil then
            local contentStr=""
            local j=1
            for i=1,table.maxn(contentTable) do
                local info=ResManager:getInstance():getResInfoByTypeAndId(contentTable[i].type,contentTable[i].itemId,contentTable[i].count)
                if j~=1 then
                    contentStr=contentStr..","
                end
                contentStr=contentStr..info.name.."x"..info.count
                j=j+1
            end
            return contentStr
        end
        return msg
    else
        return msg
    end
end

function autoReturn(s, width)
    local les = string.len(s)
    local ret = ""
    local count = 0
    for i=1,les do
        local v = string.byte(s,i)
        if bit:band(v,128)==0 then
            count = count + 0.5
            if(count>width)then
                ret = ret .. "\n"
                count = 0
            end
        end
        if bit:band(v,128)~=0 and bit:band(v,64)~=0 then
            count = count + 1
            if(count>width)then
                ret = ret .. "\n"
                count = 0
            end
        end
        ret = ret .. string.char(v)
    end
    return ret
end

function Split(str, delim, maxNb)
    if string.find(str, delim) == nil then
        return {str}
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
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
--分割字符串的函数
--[[
	用法:
	local list = SplitEx("abc,123,345", ",")
	然后list里面就是
	abc
	123
	345
	了。第二个参数可以是多个字符，但是不能是Lua正则表达式。例如. ，或者 %w 之类的。
	增强版等以后再放出来吧，这个应该大部分够用了。
--]]
function SplitEx(szFullString, szSeparator)  
	local nFindStartIndex = 1  
	local nSplitIndex = 1  
	local nSplitArray = {}  
	while true do  
	   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
	   if not nFindLastIndex then  
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
		break  
	   end  
	   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
	   nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
	   nSplitIndex = nSplitIndex + 1  
	end  
	return nSplitArray  
end  
--[[ 
是否为西班牙
--]]
function getI18nSrcPathLua()
    if mCurLangPath == "none" then
        mCurLangPath = GamePrecedure:getInstance():getI18nSrcPath()
    end
    return mCurLangPath;
end
function IsSpanishLanguage()
    local strcurLang = getI18nSrcPathLua();
    if strcurLang == "Spanish"then
        bSpanishLanguage = true
    else
        bSpanishLanguage = false
    end

    return bSpanishLanguage;
end
--[[ 
是否为俄语
--]]
function IsRussianLanguage()
    local strcurLang = getI18nSrcPathLua();
    if strcurLang == "Russian"then
        bRussianLanguage = true
    else
        bRussianLanguage = false
    end

    return bRussianLanguage;
end

function IsPortugueseLanguage()
    local strcurLang = getI18nSrcPathLua();
    if strcurLang == "Portuguese" then
        bPortugueseLanguage = true
    else
        bPortugueseLanguage = false
    end

    return bPortugueseLanguage;
end

function IsFrenchLanguage()
    local strcurLang = getI18nSrcPathLua();
    if strcurLang == "French" or strcurLang == "Spanish" then
        bFrenchLanguage = true
    else
        bFrenchLanguage = false
    end

    return bFrenchLanguage;
end
function IsEnglishLanguage()
    local strcurLang = getI18nSrcPathLua();
    if strcurLang == "English"then
        bEnglishLanguage = true
    else
        bEnglishLanguage = false
    end

    return bEnglishLanguage;
end
--[[ 
语种泰语
--]]
function IsThaiLanguage()
    local strcurLang =  getI18nSrcPathLua();
    if strcurLang == "Thai"then
        bThaiLanguage = true
    else
        bThaiLanguage = false
    end

    return bThaiLanguage;
end
--针对法国数字千分号"."和小数点","处理 
--[[ 
123456.9处理后的结果为123.456,9
--]]
function ProcessFrancNum(productPrice)

    local strResult = "";--最终结果
    strPrice = productPrice
    strResult = string.gsub(strPrice,"%.",",")

    return strResult;--暂时不处理千分号问题。
--[[
    if tonumber(productPrice)>= 1000 then--小于四位数直接替换“.”大于四位数分开处理。

        local strBegin = "";
        local strEnd = "";

        local len = string.find(strResult,",")
        if len == nil then
            strBegin = strResult;
        else--如果存在小数，则把小数点及其小数存储起来
            strBegin = string.sub(strResult,1,len-1)
            strEnd = string.sub(strResult,len,#strResult)
        end

        strBegin = string.reverse(strBegin);
            
        local ResidueNum ="";--不需要转换的num
        local nNum = (#strBegin-1)/3;--整数部分需要嵌入的"."个数
        local time1 = #strBegin%3;--整数部分不需要处理的个数exp:23456  23不需要处理
        if time1~=nil then
            if time1 == 0 then
                time1 = 3;
            end
            ResidueNum = string.sub(strBegin,#strBegin-time1+1,#strBegin)
        end
        local tempResult = "";
        for idx = 1,nNum do
            local temp =string.sub(strBegin,1,3)
            strBegin = string.sub(strBegin,4,#strBegin)
            tempResult = tempResult..temp.."."
        end
        tempResult = tempResult..ResidueNum
        strResult = string.reverse(tempResult)..strEnd
    end
    return strResult
--]]
end	
function getResTable(str)
    local  _tableItem=Split(str,",")
    local _tableRes={}
    if _tableItem==str then
       local _resItem=Split(str,"_")
       if _resItem==str then
           _resItem=nil
       else
           _tableRes[1]={}
            if table.maxn(_resItem)==3 then
                _tableRes[1].type=_resItem[1]
                _tableRes[1].itemId=_resItem[2]
                _tableRes[1].count=_resItem[3]
            else
                _tableRes[1]=nil
            end
       end
    else
        for i=1, table.maxn(_tableItem) do
            _tableRes[i]={}
            local _resItem=Split(_tableItem[i],"_")
            if _resItem==str then
                _tableRes[i]=nil
            else
                if table.maxn(_resItem)==3 then
                    _tableRes[i].type=_resItem[1]
                    _tableRes[i].itemId=_resItem[2]
                    _tableRes[i].count=_resItem[3]
                else
                    _tableRes[i]=nil
                end
            end
        end
    end
    return _tableRes
end

function getToolsCount(itemId)
    local _toolsInfo=ServerDateManager:getInstance():getUserToolInfoByItemId(itemId)
    local _count=0
    if _toolsInfo~=nil then
        _count=_toolsInfo.count
    end
    return _count
end	
-------------------------------------------------------------
QualityInfo =
{
	MaxQuality=5,
	MinQuality=1,
	NoQuality=4,
}

MemProfiler = { currMem = 0 }

function MemProfiler:start()
	self.currMem = collectgarbage("count")
	common:log("Current Lua Memory Size::  %d", self.currMem)
end

function MemProfiler:record()
	local mem = collectgarbage("count")
	common:log("Current Lua Memory Size::  %d ,Added Count::  %d", mem, mem - self.currMem)
	self.currMem = mem
end

-- format为 "%m/%d/%Y" 或者"%d/%m/%Y" 匹配不同国家的时间格式
function TimeFormat(format,year,month,day,noUseSplit)
	local splitStrTable = {"/",".","-",":"}
	local splitStr = "/"
	for k,v in ipairs(splitStrTable) do
		if string.find(format,"%"..v) then
			splitStr = v
			break
		end
	end
	local timeFormatStr = Split(format,"%"..splitStr)
	local time = {["%Y"] = year,["%m"] = month,["%d"] = day}
	if noUseSplit then
		splitStr = " "
	end
    if #timeFormatStr >= 3 then
	    local timeAfterFormat = time[timeFormatStr[1]] .. splitStr .. time[timeFormatStr[2]] .. splitStr .. time[timeFormatStr[3]]
    end
	return timeAfterFormat
end

--字符串分割   
function splitStr(content, token)  
    if not content or not token then return end  
    local strArray = {}  
    local i = 1  
    local contentLen = string.len(content)  
    while true do  
        -- true是用来避开string.find函数对特殊字符检查 特殊字符 "^$*+?.([%-"  
        local beginPos, endPos = string.find(content, token, 1, true)   
        if not beginPos then  
            strArray[i] = string.sub(content, 1, contentLen)  
            break  
        end  
        strArray[i] = string.sub(content, 1, beginPos-1)  
        content = string.sub(content, endPos+1, contentLen)  
        contentLen = contentLen - endPos  
        i = i + 1  
    end  
    return strArray  
end

function getTabelLength(table)
    local count=0
    for k,v in pairs(table) do
        count = count + 1
    end
    return count
end
