local thisPageName = "GVGTeamInfoPage"
local GVGManager = require("GVGManager")
local GVG_pb = require("GroupVsFunction_pb")

local GVGTeamInfoPageBase = {
    showType = 2,
    curListLen = -1,
}
 
local option = {
    ccbiFile = "GVGTeamInfoPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGTeamInfoContent.ccbi",
    list = {}
}

local roleCfg = {}

local curCellList = {}

local ORDER_MAP = {"1st","2nd","3rd"}

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

    local data = GVGInfoContent.list[index]
    if data then
        lb2Str.mName = data.playerName
        lb2Str.mLV = UserInfo.getOtherLevelStr(data.rebirthStage, data.playerLevel)
        lb2Str.mFightPoint = common:getLanguageString("@Fighting") .. data.fightNum

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

        if GVGManager.getGuildPos() >= 1 and GVGManager.isOwnCity(GVGManager.getCurCityId()) and GVGManager.getShowType() == GVGManager.SHOWTYPE_DEF then
            if GVGManager.getGVGStatus() == GVG_pb.GVG_STATUS_FIGHTING then
                visibleMap.mDeleteNode = data.teamId and data.teamId > 1
                visibleMap.mDownNode = data.teamId and data.teamId > 0
            else
                visibleMap.mDeleteNode = data.teamId and data.teamId > 0
                visibleMap.mDownNode = data.teamId and data.teamId >= 0 and index < #GVGInfoContent.list
            end
        else
            visibleMap.mDeleteNode = false
            visibleMap.mDownNode = false
        end
        local orderStr = index
        if index <= 3 then
            orderStr = ORDER_MAP[index]
        end
        lb2Str.mTitleNum = common:getLanguageString("@GVGRankingTxt", index)
        
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onDelete(container)
    local index = self.index
    local data = GVGInfoContent.list[index]

    GVGManager.changeDefOrder(GVGManager.getCurCityId(), data.teamId, data.teamId - 1)
end

function GVGInfoContent:onDown(container)
    local index = self.index
    local data = GVGInfoContent.list[index]

    GVGManager.changeDefOrder(GVGManager.getCurCityId(), data.teamId, data.teamId + 1)
end

function GVGTeamInfoPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGTeamInfoPageBase:onEnter(container)
	NodeHelper:initScrollView(container, "mContent", 10);
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    roleCfg = ConfigManager.getRoleCfg()
    self:registerPacket(container)

    self:reqData(container)
    
    --self:clearAndReBuildAllItem(container)
end

function GVGTeamInfoPageBase:reqData(container)
    local showType = GVGManager.getShowType()
    GVGTeamInfoPageBase.showType = showType
    if showType == GVGManager.SHOWTYPE_ATK then
        GVGManager.reqCityAtkList(GVGManager.getCurCityId())
    elseif showType == GVGManager.SHOWTYPE_DEF then
        local ret = GVGManager.reqCityDefList(GVGManager.getCurCityId())
        if ret == false then
            self:reBuildAllItem(container)
        end
    end
end

function GVGTeamInfoPageBase:onExecute(container)
    
end

function GVGTeamInfoPageBase:onExit(container)
    self:removePacket(container)
    if GVGManager.getGVGStatus() ~= GVG_pb.GVG_STATUS_FIGHTING then
        GVGManager.setCurCityId(0)
    end
    GVGInfoContent.list = {}
    GVGTeamInfoPageBase.showType = 2
    GVGTeamInfoPageBase.curListLen = -1
    roleCfg = {}
    curCellList = {}
end

function GVGTeamInfoPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGTeamInfoPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGTeamInfoPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onCityTeamList then
                self:reBuildAllItem(container)
            elseif extraParam == GVGManager.onChangeOrder then
                self:reqData(container)
            elseif extraParam == GVGManager.onTeamNumChange then
                local teamList = GVGManager.getCityTeams(GVGManager.getCurCityId(), GVGTeamInfoPageBase.showType)
                local atkNum,defNum = GVGManager.getCityTeamNum()
                if GVGTeamInfoPageBase.showType == GVGManager.SHOWTYPE_ATK then
                    if #teamList ~= atkNum then
                        self:reqData(container)
                    end
                elseif GVGTeamInfoPageBase.showType == GVGManager.SHOWTYPE_DEF then
                    if #teamList ~= defNum then
                        self:reqData(container)
                    end
                end
            end
        end
	end
end

function GVGTeamInfoPageBase:reBuildAllItem(container)
    local teamList = GVGManager.getCityTeams(GVGManager.getCurCityId(), GVGTeamInfoPageBase.showType)
    --[[
    table.sort(teamList,function(a,b)
        return a.teamId < b.teamId
    end)
    ]]
    local offSet = container.mScrollView:getContentOffset()
    local minOff = container.mScrollView:minContainerOffset()
    GVGInfoContent.list = teamList
    if #teamList >= 1 then
        if #teamList > GVGTeamInfoPageBase.curListLen then
            for i,v in ipairs(teamList) do
                if not curCellList[i] then
                    local titleCell = CCBFileCell:create()
                    local panel = GVGInfoContent:new({id = v.teamId, index = i})
                    titleCell:registerFunctionHandler(panel)
                    titleCell:setCCBFile(GVGInfoContent.ccbiFile)
                    container.mScrollView:addCellBack(titleCell)
                    curCellList[i] = titleCell
                end
            end
            container.mScrollView:orderCCBFileCells()
        elseif #teamList < GVGTeamInfoPageBase.curListLen then
            for i = #teamList, GVGTeamInfoPageBase.curListLen do
                if curCellList[i] then
                    container.mScrollView:removeCell(curCellList[i])
                    curCellList[i] = nil
                end
            end
            container.mScrollView:orderCCBFileCells()
        end
        container.mScrollView:refreshAllCell()
        GVGTeamInfoPageBase.curListLen = #teamList
        NodeHelper:setNodesVisible(container,{mEmpty = false})
    else
        local str = ""
        if GVGTeamInfoPageBase.showType == GVGManager.SHOWTYPE_ATK then
            str = common:getLanguageString("@GVGAtkListEmpty")
        else
            str = common:getLanguageString("@GVGDefListEmpty")
        end
        NodeHelper:setStringForLabel(container,{mEmpty = str})
        NodeHelper:setNodesVisible(container,{mEmpty = true})
    end
    local newMinOff = container.mScrollView:minContainerOffset()
    local maxOff = container.mScrollView:maxContainerOffset()
    local dy = newMinOff.y - minOff.y
    container.mScrollView:setContentOffset(ccp(0, math.max( math.min(maxOff.y, offSet.y + dy), newMinOff.y)))
end

function GVGTeamInfoPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGTeamInfoPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGTeamInfoPage = CommonPage.newSub(GVGTeamInfoPageBase, thisPageName, option);