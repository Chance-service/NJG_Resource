local GVGManager = require("GVGManager")
local thisPageName = "GVGCityInfoPage"

local GVGCityInfoPageBase = {
    showType = 2
}
 
local option = {
    ccbiFile = "GVGCityInfoPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
    }
}

local SCALE_MAP = {
    0.65,
    0.6,
    0.5
}

local GVGEveryDayRewardTabNow  = nil

function GVGCityInfoPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    --local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGManager.getCityInfo()
    local cfg = GVGManager.getCityCfg()
    if data then
        lb2Str.mCityName = cfg.cityName
        if data.defGuild and data.defGuild.guildId > 0 then
            lb2Str.mGuildName = data.defGuild.name
        else
            lb2Str.mGuildName = common:getLanguageString("@GVGNpcName", cfg.cityName)
        end
        lb2Str.mCityLevelNum = common:getLanguageString("@GVGCityLevelNum") .." ".. cfg.level
        local tax = cfg.cityTax[1]

        --lb2Str.mCityReward = common:getLanguageString("@GVGCityRewardTxt2", cfg.boxName)


        if tax and cfg.level > 0 then
            local resInfo = ResManagerForLua:getResInfoByTypeAndId(GVGEveryDayRewardTabNow[4 - cfg.level][1].type, GVGEveryDayRewardTabNow[4 - cfg.level][1].itemId,GVGEveryDayRewardTabNow[4 - cfg.level][1].count);
            lb2Str.mCityReward = common:getLanguageString("@GVGCityRewardTxt2", resInfo.name .. "X" .. resInfo.count)
        else
            lb2Str.mCityReward = common:getLanguageString("@GVGCityRewardTxt2", 0)
        end


        lb2Str.mCityControl = common:getLanguageString("@GVGCityControlTxt") .. common:getLanguageString("@GVGCityControlRule" .. cfg.level)
        lb2Str.mCityInfo = common:getLanguageString("@GVGCityRewardTxt1", cfg.obtainScore)

        sprite2Img.mPic = cfg.cityImg
        --scaleMap.mPic = SCALE_MAP[cfg.level]
        --menu2Quality.mHand = cfg.level + 1
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    --NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGCityInfoPageBase:getEveryDayReward()

    local _mGVGEveryDayReward = ConfigManager.getGVGEveryDayRewardCfg();
    local indexEveryDayNow = 0 
    GVGEveryDayRewardTabNow   = nil

     if GVGEveryDayRewardTabNow == nil then
        GVGEveryDayRewardTabNow = {}
        for i = 1 ,#_mGVGEveryDayReward do
             local dateTableStart,dateTableEnd = unpack(common:split(_mGVGEveryDayReward[i].date, ","));

             local dateStart,timeStart = unpack(common:split(dateTableStart, "_"));
             local yearStart,monthStart,dayStart = unpack(common:split(dateStart, "-"));
             local hourStart,minStart,secStart = unpack(common:split(timeStart, ":"));

             local dateEnd,timeEnd = unpack(common:split(dateTableEnd, "_"));
             local yearEnd,monthEnd,dayEnd = unpack(common:split(dateEnd, "-"));
             local hourEnd,minEnd,secEnd = unpack(common:split(timeEnd, ":"));


             yearStart,monthStart,dayStart,hourStart,minStart,secStart = tonumber(yearStart),tonumber(monthStart),tonumber(dayStart),tonumber(hourStart),tonumber(minStart),tonumber(secStart)
             yearEnd,monthEnd,dayEnd,hourEnd,minEnd,secEnd = tonumber(yearEnd),tonumber(monthEnd),tonumber(dayEnd),tonumber(hourEnd),tonumber(minEnd),tonumber(secEnd)

            local timeZone = os.difftime(os.time(), os.time(os.date("!*t", os.time())))
            local matchTimeStart = os.time({day=dayStart, month=monthStart, year = yearStart, hour=hourStart, min=minStart, sec=secStart}) -- 指定时间的时间戳
            matchTimeStart = matchTimeStart +  ServerOffset_UTCTime + timeZone 
            local matchTimeEnd = os.time({day=dayEnd, month=monthEnd, year = yearEnd, hour=hourEnd, min=minEnd, sec=secEnd}) -- 指定时间的时间戳
            matchTimeEnd = matchTimeEnd  +  ServerOffset_UTCTime + timeZone 

            if localSeverTime  > matchTimeStart and localSeverTime  <  matchTimeEnd then --当前赛季  上一个赛季
                indexEveryDayNow = indexEveryDayNow + 1  
                GVGEveryDayRewardTabNow[indexEveryDayNow] = _mGVGEveryDayReward[i].rewards
            end 
        end
    end

end
function GVGCityInfoPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGCityInfoPageBase:onEnter(container)
    self:registerPacket(container)
    self:getEveryDayReward()
    self:refreshPage(container)
end

function GVGCityInfoPageBase:onExecute(container)
    
end

function GVGCityInfoPageBase:onExit(container)
    self:removePacket(container)
    GVGManager.setCurCityId(0)
end

function GVGCityInfoPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGCityInfoPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGCityInfoPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		
	end
end

function GVGCityInfoPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGCityInfoPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGCityInfoPage = CommonPage.newSub(GVGCityInfoPageBase, thisPageName, option);