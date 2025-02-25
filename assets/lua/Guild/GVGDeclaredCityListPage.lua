local thisPageName = "GVGDeclaredCityListPage"
local GVGManager = require("GVGManager")

local GVGDeclaredCityListPageBase = {
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

local GVGDeclareInfoContent = {
    ccbiFile = "GVGOwnSideCityContent.ccbi",
    cityList = {}
}

local SCALE_MAP = {
    1.0,
    1.0,
    1.0
}

function GVGDeclareInfoContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function GVGDeclareInfoContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    --local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGDeclareInfoContent.cityList[index]
    local guildInfo = GVGManager.getGuildInfo()
    local staticData = GVGManager.getCityCfg(id)
    if data then
        lb2Str.mName = staticData.cityName
        lb2Str.mNum = common:getLanguageString("@GuildNameAnd").." "..data.defGuild.name
        if data.defGuild and data.defGuild.guildId == 0 then
           lb2Str.mNum = common:getLanguageString("@GuildNameAnd").." "..common:getLanguageString("@GVGNpcName", staticData.cityName)
        end
        if staticData.level == 0 then
           visibleMap.mNum = false
        end
        if data.atkGuild and data.atkGuild.guildId > 0 then
            lb2Str.mInfo = common:getLanguageString("@GVGIsUnderAtk", data.atkGuild.name)
           
            visibleMap.mInfo = true

             if staticData.level == 0 then
                visibleMap.mInfo = false
            end
--            if guildInfo and guildInfo.id ~= data.atkGuild.guildId  then 
--               NodeHelper:setMenuItemEnabled(container, "mGoToBtn", false);
--               NodeHelper:setNodeIsGray(container, { mBtnTxt = true })
--            end
        else
            --lb2Str.mInfo = common:getLanguageString("@GuildNameAnd").." "..data.defGuild.name
            visibleMap.mInfo = false
        end
        sprite2Img.mPic = staticData.cityImg
        scaleMap.mPic = SCALE_MAP[staticData.level]
        --menu2Quality.mHand = staticData.level + 1
    end
    visibleMap.mPointNode = false 
--    local noticeNum = GVGManager.getCityBattleNotice(id)
--    if noticeNum > 0 then
--        visibleMap.mPointNode = true
--        lb2Str.mPointNum = noticeNum
--    else
--        visibleMap.mPointNode = false
--    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    --NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGDeclareInfoContent:onGoTo(container)
    local id = self.id
    if id > 0 then
        PageManager.popPage(thisPageName)
        GVGManager.setTargetCityId(id)
    end
end

function GVGDeclaredCityListPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGDeclaredCityListPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
end

function GVGDeclaredCityListPageBase:onExecute(container)

end

function GVGDeclaredCityListPageBase:onExit(container)
    self:removePacket(container)
end

function GVGDeclaredCityListPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGDeclaredCityListPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGDeclaredCityListPageBase:onReceiveMessage(container)
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
function GVGDeclaredCityListPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local cityList = GVGManager.getDelcaredCitys()
    NodeHelper:setStringForLabel(container,{mTitle = common:getLanguageString("@GVGDeclaredTitle")})
    NodeHelper:setStringForLabel(container,{mTitleIntro = common:getLanguageString("@GVGDeclaredIntro")})
    GVGDeclareInfoContent.cityList = cityList
    if #cityList >= 1 then
        for i,v in ipairs(cityList) do
            local titleCell = CCBFileCell:create()
            local panel = GVGDeclareInfoContent:new({id = v.cityId, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(GVGDeclareInfoContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
        NodeHelper:setNodesVisible(container,{mEmpty = false})
    else
        NodeHelper:setStringForLabel(container,{mEmpty = common:getLanguageString("@GVGDeclaredCityEmpty")})
        NodeHelper:setNodesVisible(container,{mIntroBg = false})
        NodeHelper:setNodesVisible(container,{mEmpty = true})
    end
end

function GVGDeclaredCityListPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGDeclaredCityListPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGDeclaredCityListPage = CommonPage.newSub(GVGDeclaredCityListPageBase, thisPageName, option);