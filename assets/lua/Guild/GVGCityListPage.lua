local thisPageName = "GVGCityListPage"
local GVGManager = require("GVGManager")

local GVGCityListPageBase = {
    showType = 2
}
 
local option = {
    ccbiFile = "GVGOwnSideCityPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGOwnSideCityContent.ccbi",
    cityList = {}
}

local SCALE_MAP = {
    1.0,
    1.0,
    1.0
}

function GVGInfoContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function GVGInfoContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    --local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGInfoContent.cityList[index]
    local staticData = GVGManager.getCityCfg(id)
    if data then
        lb2Str.mName = staticData.cityName
        lb2Str.mNum = common:getLanguageString("@GVGDefenderTeamNum",(data.defTeamNum or 0))
        if staticData.level == 0 then
           visibleMap.mNum = false
        end
        if data.atkGuild and data.atkGuild.guildId > 0 then
            lb2Str.mInfo = common:getLanguageString("@GVGIsUnderAtk", data.atkGuild.name)
           
            visibleMap.mInfo = true

             if staticData.level == 0 then
                visibleMap.mInfo = false
            end
        else
            visibleMap.mInfo = false
        end
        sprite2Img.mPic = staticData.cityImg
        scaleMap.mPic = SCALE_MAP[staticData.level]
        --menu2Quality.mHand = staticData.level + 1
    end
    local noticeNum = GVGManager.getCityBattleNotice(id)
    if noticeNum > 0 then
        visibleMap.mPointNode = true
        lb2Str.mPointNum = noticeNum
    else
        visibleMap.mPointNode = false
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    --NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onGoTo(container)
    local id = self.id
    if id > 0 then
        PageManager.popPage(thisPageName)
        GVGManager.setTargetCityId(id)
    end
end

function GVGCityListPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGCityListPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
end

function GVGCityListPageBase:onExecute(container)

end

function GVGCityListPageBase:onExit(container)
    self:removePacket(container)
end

function GVGCityListPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGCityListPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGCityListPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onCityBattleNotice then
                container.mScrollView:refreshAllCell()
            end
        end
	end
end
--返回 是否展示城池  是否展示复活Tip
function GVGCityListPageBase:needShowReviveCity(ownCityList)
   if #ownCityList <= 0 then
        if not GVGManager.getGuildInfo() then return false ,false  end  --自己无联盟
        local guildId = GVGManager.getGuildInfo().id
        for k,v in pairs(GVGManager.getRankList(GVGManager.TODAY_RANK)) do
            if v.id == guildId and v.rank <= 15 then --自己的工会在入围名单内
               local localSeverTimeTmp =  common:getServerTimeByUpdate()
                if  localSeverTimeTmp then
                    local serverTimeTab = os.date("!*t", localSeverTimeTmp - common:getServerOffset_UTCTime())
                    local serverTime = serverTimeTab.hour*3600 + serverTimeTab.min*60+serverTimeTab.sec
                    local _,declareStartTime = GVGManager.getDeclareStartTime()
                    local _,fightEndTime = GVGManager.getFightingEndTime()
                    local _,reviveStartTime = GVGManager.getReviveStartTime()
                    declareStartTime = declareStartTime / 1000
                    fightEndTime = fightEndTime / 1000
                    reviveStartTime = reviveStartTime / 1000
                    if serverTime >= declareStartTime and  serverTime <  fightEndTime then
                       return false,false
                    end
                    if serverTime >= fightEndTime and  serverTime <  reviveStartTime then  --21:45 - 22:00 时间段展示提示复活
                       return  false , true 
                    else
                       return true ,false
                    end
                end
            end
        end
    end
    return false ,false 
end
function GVGCityListPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local cityList = GVGManager.getOwnGuildCitys()
    local isShowReviveTip = false
    local isNeedShowReviveCity = false 
    --自己联盟都被打了之后  显示可以复活的城池
    local isNeedShowReviveCity,isShowReviveTip = self:needShowReviveCity(cityList)
    if isNeedShowReviveCity  then
       cityList =  GVGManager.getCanReviveCitylist()
       NodeHelper:setStringForLabel(container,{mTitleIntro = common:getLanguageString("@GVGRebirthCityChoose")})
    else
       NodeHelper:setStringForLabel(container,{mTitleIntro = common:getLanguageString("@GVGOwnCityChoose")})
    end 

    GVGInfoContent.cityList = cityList

    if #cityList >= 1 then
        for i,v in ipairs(cityList) do
            local titleCell = CCBFileCell:create()
            local panel = GVGInfoContent:new({id = v.cityId, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(GVGInfoContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
        NodeHelper:setNodesVisible(container,{mEmpty = false})
    else
       if isShowReviveTip then
          NodeHelper:setStringForLabel(container,{mEmpty = common:getLanguageString("@GVGNoCityOwn")})
       else
          NodeHelper:setStringForLabel(container,{mEmpty = common:getLanguageString("@GVGCityListEmpty")})
       end
        NodeHelper:setNodesVisible(container,{mIntroBg = false})
        NodeHelper:setNodesVisible(container,{mEmpty = true})
    end
end

function GVGCityListPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGCityListPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGCityListPage = CommonPage.newSub(GVGCityListPageBase, thisPageName, option);