local GVGManager = require("GVGManager")
local thisPageName = "GVGAllInfoPage"

local GVGAllInfoPageBase = {
    
}

local option = {
    ccbiFile = "GVGOverviewPopUp.ccbi",
    handlerMap = {
        onClose = "onClose",
        mOverview = "onOverview"
    },
    opcodes = {
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGOverviewContent.ccbi",
    cityMap = {}
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
    local labelColorMap = {}

    local data = GVGInfoContent.cityMap[index]
    if data then
        for i = 1, 3 do
            lb2Str["mCityNum" .. i] = "X" .. data["level" .. (4 - i)]
        end
        lb2Str.mReport = data.guildName
        if GVGManager.isSelfGuild(data.id) then
            visibleMap.mMyCity = true
            visibleMap.mOwnAllianceBg = true
            visibleMap.mNormal = false
            visibleMap.mOtherAllianceBg = false
        else
            visibleMap.mNormal = true
            visibleMap.mOtherAllianceBg = true
            visibleMap.mMyCity = false
            visibleMap.mOwnAllianceBg = false
        end
    end

    NodeHelper:setColorForLabel(container,labelColorMap)
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGAllInfoPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGAllInfoPageBase:onEnter(container)
    self:registerPacket(container)
    container:registerMessage(MSG_MAINFRAME_REFRESH)
    NodeHelper:initScrollView(container, "mContent", 10);
    container.mLogScrollview = container:getVarScrollView("mInfoContent")

    GVGManager.reqVitalityRank()

    self:refreshPage(container)
    self:clearAndReBuildAllItemBattle(container)
end

function GVGAllInfoPageBase:onExecute(container)

end

function GVGAllInfoPageBase:onExit(container)
    self:removePacket(container)
end

function GVGAllInfoPageBase:onClose(container)
    PageManager.popPage(thisPageName)
end

function GVGAllInfoPageBase:onOverview(container)
    GVGManager.setIsFromRank(true)
    PageManager.changePage("GVGRankPage")
end

function GVGAllInfoPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
end

function GVGAllInfoPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onTodayRank then
                self:clearAndReBuildAllItem(container)
            elseif extraParam == GVGManager.onCityChange then
                self:clearAndReBuildAllItem(container)
                self:clearAndReBuildAllItemBattle(container)
            end
        end
	end
end

function GVGAllInfoPageBase:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    local capitalOwner,capital = GVGManager.getCapitalOwner()
    --local mReport = container:getVarNode("mReport")
    --lb2Str.mReport = ""
    if capitalOwner and capitalOwner > 0 then
        local str = common:fill(FreeTypeConfig[3000].content,capital.defGuild.name)
        --local labChatHtml = NodeHelper:addHtmlLable(mReport ,str , GameConfig.Tag.HtmlLable ,CCSizeMake(270, 30))
        visibleMap.mItemGrey = false
        visibleMap.mItem = true
        visibleMap.mChange = false
        visibleMap.mChangeNow = true
    else
        local str =  common:fill(FreeTypeConfig[3011].content,common:getLanguageString("@GVGNoCapital"))
        --local labChatHtml = NodeHelper:addHtmlLable(mReport ,str , GameConfig.Tag.HtmlLable ,CCSizeMake(270, 30))
        visibleMap.mItemGrey = true
        visibleMap.mItem = false
        visibleMap.mChange = true
        visibleMap.mChangeNow = false
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    --NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGAllInfoPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local cityMap = GVGManager.getGuildCityMap()    
    GVGInfoContent.cityMap = cityMap
    for i = 1, #cityMap do
        local v = cityMap[i]
        local titleCell = CCBFileCell:create()
        local panel = GVGInfoContent:new({id = v.id, index = i})
        titleCell:registerFunctionHandler(panel)
        titleCell:setCCBFile(GVGInfoContent.ccbiFile)
        container.mScrollView:addCellBack(titleCell)
    end
    container.mScrollView:orderCCBFileCells()
end

function GVGAllInfoPageBase:clearAndReBuildAllItemBattle(container)
    container.mLogScrollview:removeAllCell()
    local wordList = GVGManager.getCityBattleRecords()
    local currentPos = 0
	local size = #wordList
    if size > 0 then
	    for i = size, 1,-1 do
		    local oneContent = wordList[i]
		    if oneContent~=nil then
			    local content = CCHTMLLabel:createWithString(oneContent,CCSize(240,48),"Helvetica");
			    content:setPosition(ccp(-20,currentPos));
			    content:setTag(i);
			    currentPos = currentPos + content:getContentSize().height + GameConfig.FightLogSlotWidth;
			    container.mLogScrollview:addChild(content)
		    end
	    end
    else
        local oneContent = FreeTypeConfig[3001].content
        local content = CCHTMLLabel:createWithString(oneContent,CCSize(240,48),"Helvetica");
		content:setPosition(ccp(0,currentPos));
		content:setTag(1);
		currentPos = currentPos + content:getContentSize().height + GameConfig.FightLogSlotWidth;
		container.mLogScrollview:addChild(content)
    end
	container.mLogScrollview:setContentSize(CCSize(240,currentPos));
	local viewHeight = container.mLogScrollview:getViewSize().height
    local minOff = container.mLogScrollview:maxContainerOffset()
    container.mLogScrollview:setContentOffset(minOff)
end

function GVGAllInfoPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGAllInfoPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGAllInfoPage = CommonPage.newSub(GVGAllInfoPageBase, thisPageName, option);