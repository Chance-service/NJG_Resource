local GVGManager = require("GVGManager")
local thisPageName = "GVGPreparePage"

local GVGPreparePageBase = {
    leftTime = 0,
    timerName = "GVGPreparePage",
}
 
local option = {
    ccbiFile = "GVGPreparePage.ccbi",
    handlerMap = {
        onReturnBtn = "onReturnBtn",
        onHelp = "onHelp"
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGPrepareContent.ccbi",
    rankList = {}
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
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local data = GVGInfoContent.rankList[index]
    if data then
        lb2Str.mRankNum = data.rank
        lb2Str.mID = data.id
        lb2Str.mGuildLv = "Lv." .. data.level
        lb2Str.mGuildName = data.name
        lb2Str.mVitalityNum = data.value
    end
    visibleMap.mRankingNum4 = index % 2 == 0

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGPreparePageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)

    local scrollview=container:getVarScrollView("mContent");
	if scrollview~=nil then
		container:autoAdjustResizeScrollview(scrollview);
	end		
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
	
	local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		container:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end
end

function GVGPreparePageBase:onEnter(container)
    self:registerPacket(container)

    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);

    --GVGManager.reqVitalityRank()
    self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function GVGPreparePageBase:onExecute(container)
    local timeStr = '00:00:00'
	if TimeCalculator:getInstance():hasKey(GVGPreparePageBase.timerName) then
		GVGPreparePageBase.closeTimes = TimeCalculator:getInstance():getTimeLeft(GVGPreparePageBase.timerName)
		if GVGPreparePageBase.closeTimes > 0 then
			 timeStr = common:getLanguageString("@GVGCountDownTxt") .. common:second2DateString(GVGPreparePageBase.closeTimes , true)
		end
        if GVGPreparePageBase.closeTimes <= 0 then
		    timeStr = common:getLanguageString("@GVGIsOpening")
	    end
        NodeHelper:setStringForLabel(container, { mTime = timeStr})
	end
end

function GVGPreparePageBase:onExit(container)
    self:removePacket(container)
end

function GVGPreparePageBase:onHelp(container)
    PageManager.showHelp(GameConfig.HelpKey.HELP_GVG)
end

function GVGPreparePageBase:onReturnBtn(container)
    local pageName = GVGManager.getFromPage() or "PVPActivityPage"
    GVGManager.setFromPage(nil)
	PageManager.changePage(pageName)
end

function GVGPreparePageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGPreparePageBase:refreshPage(container)
    local rankList = GVGManager.getRankList(GVGManager.TODAY_RANK)
    local lb2Str = {}
    if #rankList > 0 then
        GVGPreparePageBase.leftTime = GVGManager.getPrepareTimeLeft()
        if GVGPreparePageBase.leftTime > 0 then
            lasttime = GVGPreparePageBase.leftTime
            TimeCalculator:getInstance():createTimeCalcultor(GVGPreparePageBase.timerName, GVGPreparePageBase.leftTime);
        else
            lb2Str.mTime = common:getLanguageString("@GVGIsOpening")
        end
    else
        lb2Str.mTime = common:getLanguageString("@GVGIsOpening")
    end

    NodeHelper:setStringForLabel(container, lb2Str)
end

function GVGPreparePageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onTodayRank then
                self:clearAndReBuildAllItem(container)
                self:refreshPage(container)
            end
        end
	end
end

function GVGPreparePageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local rankList = GVGManager.getRankList(GVGManager.TODAY_RANK)
    table.sort(rankList, function(a,b)
        return a.rank < b.rank
    end)
    if #rankList >= 1 then
        GVGInfoContent.rankList = rankList
        for i,v in ipairs(rankList) do
            local titleCell = CCBFileCell:create()
            local panel = GVGInfoContent:new({id = v.teamId, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(GVGInfoContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
end

function GVGPreparePageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGPreparePageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGPreparePage = CommonPage.newSub(GVGPreparePageBase, thisPageName, option);