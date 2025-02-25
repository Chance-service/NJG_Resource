local thisPageName = "GVGMercenaryInfoPage"
local GVGManager = require("GVGManager")

local GVGMercenaryInfoPageBase = {
    showType = 2
}
 
local option = {
    ccbiFile = "GVGMercenaryInfoPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGMercenaryInfoContent.ccbi",
    teamList = {}
}

local roleCfg = {}

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
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGInfoContent.teamList[index]
    if data then
        visibleMap.mEmpty = false
        if data.cityId and data.cityId > 0 then
            local cityData = GVGManager.getCityCfg(data.cityId)
            if GVGManager.isOwnCity(data.cityId) then
                lb2Str.mEmpty = common:getLanguageString("@GVGisDef",cityData.cityName)
            else
                lb2Str.mEmpty = common:getLanguageString("@GVGisAtk",cityData.cityName)
            end
            visibleMap.mEmpty = true
        end

        for i = 1, 3 do
            local roleId = data.roleIds[i]
            local node = container:getVarNode("mPic" .. i):getParent()
            if roleId then
                local roleInfo = roleCfg[roleId]
                sprite2Img["mPic" .. i] = roleInfo.icon
                menu2Quality["mHand" .. i] = roleInfo.quality
                node:setVisible(true)
            else
                node:setVisible(false)
            end
        end
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onGoTo(container)
    local index = self.index
    local data = GVGInfoContent.teamList[index]
    if data.cityId and data.cityId > 0 then
        PageManager.popPage(thisPageName)
        GVGManager.setTargetCityId(data.cityId)
    end
end

function GVGMercenaryInfoPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGMercenaryInfoPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    roleCfg = ConfigManager.getRoleCfg()
    NodeHelper:initScrollView(container, "mContent", 10);
    --self:clearAndReBuildAllItem(container)
    GVGManager.reqPlayerTeamList()
end

function GVGMercenaryInfoPageBase:onExecute(container)

end

function GVGMercenaryInfoPageBase:onExit(container)
    self:removePacket(container)
end

function GVGMercenaryInfoPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGMercenaryInfoPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGMercenaryInfoPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onPlayerTeamList then
                self:clearAndReBuildAllItem(container)
            end
        end
	end
end

function GVGMercenaryInfoPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local teamList = GVGManager.getPlayerTeams()
    GVGInfoContent.teamList = teamList
    if #teamList >= 1 then
        for i,v in ipairs(teamList) do
            local titleCell = CCBFileCell:create()
            local panel = GVGInfoContent:new({id = v.teamId, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(GVGInfoContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
        NodeHelper:setNodesVisible(container,{mEmpty = false})
    else
        NodeHelper:setStringForLabel(container,{mEmpty = common:getLanguageString("@GVGTeamListEmpty")})
        NodeHelper:setNodesVisible(container,{mEmpty = true})
    end
end

function GVGMercenaryInfoPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGMercenaryInfoPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGMercenaryInfoPage = CommonPage.newSub(GVGMercenaryInfoPageBase, thisPageName, option);