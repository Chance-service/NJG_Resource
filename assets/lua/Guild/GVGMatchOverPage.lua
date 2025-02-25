local GVGManager = require("GVGManager")
local thisPageName = "GVGMatchOverPage"

local GVGMatchOverPageBase = {
    rankType = 2
}
 
local option = {
    ccbiFile = "GVGMatchOverRankPage.ccbi",
    handlerMap = {
        onReturnBtn = "onReturnBtn",
        onRankTodayBtn = "onRankTodayBtn",
        onRankYesterdayBtn = "onRankYesterdayBtn",
        onHelp = "onHelp"
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGMatchOverRankContent.ccbi",
    rankList = {}
}
local maxNumber = 15 
local GVGMatchRewardTab   = nil
local GVGMatchRewardTabNow = nil 
function GVGInfoContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function GVGInfoContent:onPreLoad(ccbRoot)
end

function GVGInfoContent:onUnLoad(ccbRoot)
end

function GVGInfoContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGInfoContent.rankList[index]
    if data then
        lb2Str['mRankNum']= data.rank
        lb2Str['mGuildScore'] = data.score
        lb2Str['mGuildName']= data.name
        if data.rank <=3 then
            lb2Str['mGuildReward'] = data.value
            for j = 1 , #GVGMatchRewardTabNow[index]  do 
                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[index][j].type/10000,GVGMatchRewardTabNow[index][j].itemId,GVGMatchRewardTabNow[index][j].count)
                if  j > 1 then 
                    lb2Str['mGuildReward'] = lb2Str['mGuildReward'] .."\n"..resInfo.name.."X"..resInfo.count
                else 
                    lb2Str['mGuildReward'] = resInfo.name..' X '..resInfo.count
                end
            end
--            local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[index][1].type/10000,GVGMatchRewardTabNow[index][1].itemId,GVGMatchRewardTabNow[index][1].count)
--            lb2Str.mGuildReward=resInfo.name.. ' X '..resInfo.count
        elseif data.rank >= 4 and data.rank <= 10 then
            lb2Str['mGuildReward'] = data.value
--            local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[4][1].type/10000,GVGMatchRewardTabNow[4][1].itemId,GVGMatchRewardTabNow[4][1].count)
--            lb2Str.mGuildReward=resInfo.name.. ' X '..resInfo.count

            for j = 1 , #GVGMatchRewardTabNow[4]  do 
                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[4][j].type/10000,GVGMatchRewardTabNow[4][j].itemId,GVGMatchRewardTabNow[4][j].count)
                if  j > 1 then 
                   lb2Str['mGuildReward'] = lb2Str['mGuildReward'] .."\n"..resInfo.name.."X"..resInfo.count
                else 
                   lb2Str['mGuildReward']= resInfo.name..' X '..resInfo.count
                end
            end
        elseif data.rank >= 11 and data.rank <= maxNumber  then
            lb2Str['mGuildReward'] = data.value
--            local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[5][1].type/10000,GVGMatchRewardTabNow[5][1].itemId,GVGMatchRewardTabNow[5][1].count)
--            lb2Str.mGuildReward=resInfo.name.. ' X '..resInfo.count

            for j = 1 , #GVGMatchRewardTabNow[4]  do 
                local resInfo  = ResManagerForLua:getResInfoByMainTypeAndId(GVGMatchRewardTabNow[5][j].type/10000,GVGMatchRewardTabNow[5][j].itemId,GVGMatchRewardTabNow[5][j].count)
                if  j > 1 then 
                    lb2Str['mGuildReward'] = lb2Str['mGuildReward'] .."\n"..resInfo.name.."X"..resInfo.count
                else 
                    lb2Str['mGuildReward'] = resInfo.name..' X '..resInfo.count
                end
            end

        end
    end
    
   
    NodeHelper:setNodesVisible(container,{mRankingNum1 = false,mRankingNum2 = false,mRankingNum3 = false,
		mRankingNum4 = false})
	if index > 3 then
		NodeHelper:setNodesVisible(container,{mRankingNum4 = true})--math.mod(index,2) == 1})
	else
		NodeHelper:setNodesVisible(container,{[string.format("mRankingNum%d",index)] = true})
	end

    --visibleMap.mRankingNum4 = index % 2 == 0

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onViewGuildInfo(container)
    local index = self.index
    local data = GVGInfoContent.rankList[index]
    if data then
        --PageManager.viewAllianceTeamInfo(data.id)
    end
end
function GVGMatchOverPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGMatchOverPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);

    local libStr = {} 
    local  str   = common:getLanguageString("@GVGMatchOverIntro")
    libStr["mGVGLastMatchTxt"] = common:stringAutoReturn(str,29)
    NodeHelper:setStringForLabel(container,libStr)


--    local _mGVGMatchReward = ConfigManager.getGVGMatchRewardCfg();
--    if GVGMatchRewardTab == nil  then
--        GVGMatchRewardTab = {}
--        for i= 1 ,#_mGVGMatchReward do
--            GVGMatchRewardTab[i] = _mGVGMatchReward[i].rewards[1]
--        end
--    end


    local _mGVGMatchReward = ConfigManager.getGVGMatchRewardCfg();

    local serverTimeTab = os.date("!*t", localSeverTime - ServerOffset_UTCTime)
    --local serverTime = serverTimeTab.hour*3600 + serverTimeTab.min*60+serverTimeTab.sec
    local dateTable = {}

    local indexLast = 0 
    local indexNow = 0 
    local indexNext = 0 

     if GVGMatchRewardTabNow == nil then
        GVGMatchRewardTabNow = {}
        for i = 1 ,#_mGVGMatchReward do
             local dateTableStart,dateTableEnd = unpack(common:split(_mGVGMatchReward[i].date, ","));

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
            --matchTimeStart = matchTimeStart - timeZone - ServerOffset_UTCTime
            matchTimeStart = matchTimeStart + ServerOffset_UTCTime + timeZone

            local matchTimeEnd = os.time({day=dayEnd, month=monthEnd, year = yearEnd, hour=hourEnd, min=minEnd, sec=secEnd}) -- 指定时间的时间戳
            --matchTimeEnd = matchTimeEnd - timeZone - ServerOffset_UTCTime
            matchTimeEnd = matchTimeEnd + ServerOffset_UTCTime + timeZone
            --local timeamp = localSeverTime - ServerOffset_UTCTime
            --if localSeverTime - ServerOffset_UTCTime > matchTimeStart and localSeverTime - ServerOffset_UTCTime <  matchTimeEnd then --当前赛季  上一个赛季
            if localSeverTime > matchTimeStart and localSeverTime <  matchTimeEnd then --当前赛季  上一个赛季
                indexNow = indexNow + 1  
                GVGMatchRewardTabNow[indexNow] = _mGVGMatchReward[i].rewards
            end 
        end
    end



    self:onRankYesterdayBtn(container)
    
end

function GVGMatchOverPageBase:onExecute(container)

end

function GVGMatchOverPageBase:onExit(container)
    self:removePacket(container)
end

function GVGMatchOverPageBase:onRankTodayBtn(container)
    GVGManager.reqVitalityRank()
    if GVGMatchOverPageBase.rankType == GVGManager.YESTERDAY_RANK then
       container.mScrollView:removeAllCell()
    end
    GVGMatchOverPageBase.rankType = GVGManager.TODAY_RANK
    self:refreshPage(container)
end

function GVGMatchOverPageBase:onRankYesterdayBtn(container)
    GVGManager.reqYesterdayVitalityRank()
    if GVGMatchOverPageBase.rankType == GVGManager.TODAY_RANK then
       container.mScrollView:removeAllCell()
    end
    GVGMatchOverPageBase.rankType = GVGManager.YESTERDAY_RANK
    self:refreshPage(container)
end

function GVGMatchOverPageBase:onReturnBtn(container)
    PageManager.popPage(thisPageName)
    PageManager.changePage('GuildPage')
end

function GVGMatchOverPageBase:onHelp(container)
    --PageManager.changePage("GVGMapPage")
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVGLIST_INTRO);
end
function GVGMatchOverPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGMatchOverPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onTodayRank then
                if GVGMatchOverPageBase.rankType == GVGManager.TODAY_RANK then
                    self:clearAndReBuildAllItem(container)
                end
            elseif extraParam == GVGManager.onYesterdayRank then
                if GVGMatchOverPageBase.rankType == GVGManager.YESTERDAY_RANK then
                     self:clearAndReBuildAllItem(container)
                end
            end
        end
	end
end

function GVGMatchOverPageBase:refreshPage(container)
    local todayBtn = container:getVarMenuItem("mRankTodayBtn")
    local yesterdayBtn = container:getVarMenuItem("mRankYesterdayBtn")
    if GVGMatchOverPageBase.rankType == GVGManager.TODAY_RANK then
        todayBtn:selected()
        yesterdayBtn:unselected()
    elseif GVGMatchOverPageBase.rankType == GVGManager.YESTERDAY_RANK then
        todayBtn:unselected()
        yesterdayBtn:selected()
    end
end

function GVGMatchOverPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local rankList = GVGManager.getRankList(GVGMatchOverPageBase.rankType)
    table.sort(rankList, function(a,b)
        return a.rank < b.rank
    end)
    GVGInfoContent.rankList = rankList
    maxNumber = 15 
    if rankList and #rankList > 16 then 
        maxNumber = #rankList
    end
    if #rankList >= 1 then
        for i,v in ipairs(rankList) do
            if i<= maxNumber then
                local titleCell = CCBFileCell:create()
                local panel = GVGInfoContent:new({id = v.rank, index = i})
                titleCell:registerFunctionHandler(panel)
                titleCell:setCCBFile(GVGInfoContent.ccbiFile)
                container.mScrollView:addCellBack(titleCell)
            end
        end
        container.mScrollView:orderCCBFileCells()
    end
end

function GVGMatchOverPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGMatchOverPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGMatchOverPage = CommonPage.newSub(GVGMatchOverPageBase, thisPageName, option);