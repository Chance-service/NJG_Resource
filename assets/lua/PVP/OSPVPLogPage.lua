local thisPageName = "OSPVPLogPage"
local UserInfo = require("PlayerInfo.UserInfo")
local OSPVPLogPage = {}

local option = {
    ccbiFile = "PVPLogContent.ccbi",
    handlerMap = {

    },
    opcodes = {
    }
}

local OSPVPVsContent = {
    ccbiFile = "PVPLogListContent.ccbi",
}

function OSPVPVsContent:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function OSPVPVsContent:onRefreshContent(ccbRoot)
    local id = self.id
    local index = self.index
    local container = ccbRoot:getCCBFileNode()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local menuImg = {}

    local list = OSPVPManager:getBattleList()
    local data = list[index]

    if data then
        if data.vsInfo then
            local roleCfg = OSPVPManager.getRoleCfg(data.vsInfo.roleItemId)
            local stage = OSPVPManager.checkStage(data.vsInfo.score,data.vsInfo.rank)
            local serverId = string.gsub(data.vsInfo.serverName,".*#","")
            lb2Str.mArenaName = common:getLanguageString("@PVPServerName",GamePrecedure:getInstance():getServerNameById(tonumber(serverId)));
            lb2Str.mLv = UserInfo.getOtherLevelStr(data.vsInfo.rebirthStage, data.vsInfo.level)
            for i = 1, 3 do
                visibleMap["mProfession" .. i] = i == roleCfg.profession
            end
            local showCfg = LeaderAvatarManager.getOthersShowCfg(data.vsInfo.avatarId)
	        local icon = showCfg.icon[roleCfg.profession]
            sprite2Img.mPic = icon

            menuImg.mHand = stage.stageIcon
            lb2Str.mResult = common:getLanguageString("@PVPLogResult", data.vsInfo.name, common:getLanguageString((data.isWin and "@defeat" or "@Win")))
        end
        lb2Str.mPersonalSignature = data.scoreChange
        visibleMap.mWin = data.isWin
        visibleMap.mLose = not data.isWin
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setNormalImages(container, menuImg)
end

function OSPVPVsContent:onHand(container)
    local list = OSPVPManager:getBattleList()
    local index = self.index
    local data = list[index]

    if data and data.vsInfo then
        OSPVPManager.reqOSPlayerInfo(data.vsInfo.identify)
    end
end

function OSPVPVsContent:onGo(container)
    local list = OSPVPManager:getBattleList()
    local index = self.index
    local data = list[index]

    if data and data.battleId then
        local serverId = string.gsub(data.vsInfo.serverName,".*#","")
        local serverName = GamePrecedure:getInstance():getServerNameById(tonumber(serverId));
        OSPVPManager:setRecordAtk(string.format("(%s)%s",serverName,data.vsInfo.name))
        OSPVPManager.reqBattleInfo(data.battleId)
    end
end

function OSPVPLogPage:create(base, ParentContainer)
    local o = {}
    self.__index = self
    setmetatable(o,self)
    o:onLoad(base, ParentContainer)
    return o
end

function OSPVPLogPage:onLoad(base, ParentContainer)
    local container = ScriptContentBase:create(option.ccbiFile)
    container:registerFunctionHandler(function(evt, container)
        local funcName = option.handlerMap[evt]
        if self[funcName] and type(self[funcName]) == "function" then
            self[funcName](self,container)
        end
    end)
    self.container = container
    base:addChild(container)

    local scrollview = container:getVarScrollView("mContent");
	if scrollview ~= nil then
		ParentContainer:autoAdjustResizeScrollview(scrollview);
	end		
	
	local mScale9Sprite = container:getVarScale9Sprite("mScale9Sprite1")
	if mScale9Sprite ~= nil then
		ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite )
	end
	
	local mScale9Sprite2 = container:getVarScale9Sprite("mScale9Sprite2")
	if mScale9Sprite2 ~= nil then
		ParentContainer:autoAdjustResizeScale9Sprite( mScale9Sprite2 )
	end

    self:onEnter(container)
end

function OSPVPLogPage:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 10);
    OSPVPManager.reqBattleList()
    self:clearAndReBuildAllItem(container)
end

function OSPVPLogPage:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}


    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
end

function OSPVPLogPage:onExecute(container)

end

function OSPVPLogPage:onExit(container)
    onUnload(thisPageName,container)
end

function OSPVPLogPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
    local container = self.container
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onBattleList then
                self:clearAndReBuildAllItem(container)
            end
        end
	end
end

function OSPVPLogPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local list = OSPVPManager:getBattleList()
    if #list >= 1 then
        for i,v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = OSPVPVsContent:new({id = v.battleId, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
    NodeHelper:setNodesVisible(container,{mEmptyTxt = #list < 1})
end

return OSPVPLogPage