local thisPageName = "OSPVPRankPage"
local OSPVPRankPage = {}

local option = {
    ccbiFile = "PVPRankingContent.ccbi",
    handlerMap = {
        onAuto = "onAuto",
        onHand = "onHand"
    },
    opcodes = {
    }
}

local OSPVPVsContent = {
    ccbiFile = "PVPRankingListContent.ccbi",
}

local isLocalServer = false

local curList = {}

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

    local data = curList[index]

    if data then
        local roleCfg = OSPVPManager.getRoleCfg(data.roleItemId)
        local stage = OSPVPManager.checkStage(data.score,data.rank)

        for i = 1, 3 do
            visibleMap["mProfession" .. i] = i == roleCfg.profession
        end
        
        local showCfg = LeaderAvatarManager.getOthersShowCfg(data.avatarId)
	    local icon = showCfg.icon[roleCfg.profession]
        sprite2Img.mPic = icon

        lb2Str.mLv = UserInfo.getOtherLevelStr(data.rebirthStage, data.level)
        local serverId = string.gsub(data.serverName,".*#","")
        lb2Str.mServer = common:getLanguageString("@PVPServerName",GamePrecedure:getInstance():getServerNameById(tonumber(serverId)));
        lb2Str.mPointNum = common:getLanguageString("@PointNum") .. data.score
        lb2Str.mArenaName = data.name
        lb2Str.mFightingNumTitle = common:getLanguageString("@Fighting") .. data.fightValue
        lb2Str.mRankingNum = data.rank

        visibleMap.mGuildName = false
        menuImg.mHand = stage.stageIcon

        visibleMap.mTrophyBG01 = data.rank == 1
        visibleMap.mTrophyBG02 = data.rank == 2
        visibleMap.mTrophyBG03 = data.rank == 3
        visibleMap.mTrophy01 = data.rank == 1
        visibleMap.mTrophy02 = data.rank == 2
        visibleMap.mTrophy03 = data.rank == 3
        visibleMap.mTrophy04 = data.rank > 3
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setNormalImages(container, menuImg)
end

function OSPVPVsContent:onHand(container)
    OSPVPManager.reqOSPlayerInfo(self.id)
end

function OSPVPRankPage:create(base, ParentContainer)
    local o = {}
    self.__index = self
    setmetatable(o,self)
    o:onLoad(base, ParentContainer)
    return o
end

function OSPVPRankPage:onLoad(base, ParentContainer)
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
    
    local scrollview2 = container:getVarScrollView("mServerContent");
	if scrollview2 ~= nil then
		ParentContainer:autoAdjustResizeScrollview(scrollview2);
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

function OSPVPRankPage:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 10);
    container.mSelfServerScrollview = container:getVarScrollView("mServerContent")
    OSPVPManager.reqRankInfo()

    self:refreshPage(container)
    self:clearAndReBuildAllItem(container)
end

function OSPVPRankPage:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}
    local menuImg = {}

    local list = OSPVPManager:getRankList()
    local data = list[1]

    if data then
        local roleCfg = OSPVPManager.getRoleCfg(data.roleItemId)
        local stage = OSPVPManager.checkStage(data.score,data.rank)
        for i = 1, 3 do
            visibleMap["mProfession" .. i] = i == roleCfg.profession
        end

        local showCfg = LeaderAvatarManager.getOthersShowCfg(data.avatarId)
	    local icon = showCfg.icon[roleCfg.profession]
        sprite2Img.mPic = icon

        lb2Str.mLv = UserInfo.getOtherLevelStr(data.rebirthStage, data.level)
        
        local serverId = string.gsub(data.serverName,".*#","")
        lb2Str.mServer = common:getLanguageString("@PVPServerName",GamePrecedure:getInstance():getServerNameById(tonumber(serverId)));
        lb2Str.mPointNumFirst = common:getLanguageString("@PointNum") .. data.score
        lb2Str.mName = data.name
        lb2Str.mFirstFightingNum = data.fightValue
        lb2Str.mGuildName = "" --data.guildName or ""

        menuImg.mHand = stage.stageIcon
    end

    --local selfInfo = OSPVPManager:getPlayerInfo()
    lb2Str.mPointNum = OSPVPManager:getScore()
    local rank = OSPVPManager:getRank()
    if rank > 0 then
        lb2Str.mPersonal = common:getLanguageString("@PVPRankPersonalTxt", rank)
    else
        lb2Str.mPersonal = common:getLanguageString("@PVPRankNoTxt")
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
    NodeHelper:setNormalImages(container, menuImg)
    NodeHelper:setMenuItemSelected(container,{mAutoBtn = isLocalServer})
end

function OSPVPRankPage:onExecute(container)

end

function OSPVPRankPage:onExit(container)
    onUnload(thisPageName,container)
end

function OSPVPRankPage:onAuto(container)
    isLocalServer = not isLocalServer
    self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function OSPVPRankPage:onHand(container)
    local list = OSPVPManager:getRankList()
    local data = list[1]
    if data then
        OSPVPManager.reqOSPlayerInfo(data.identify)
    end
end

function OSPVPRankPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
    local container = self.container
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onRankList then
                self:clearAndReBuildAllItem(container)
                self:refreshPage(container)
            end
        end
	end
end

function OSPVPRankPage:clearAndReBuildAllItem(container)
    if isLocalServer then
        container.mSelfServerScrollview:removeAllCell()
        curList = OSPVPManager:getSelfServerRankList()
        if #curList >= 1 then
            for i,v in ipairs(curList) do
                local titleCell = CCBFileCell:create()
                local panel = OSPVPVsContent:new({id = v.identify, index = i})
                titleCell:registerFunctionHandler(panel)
                titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
                container.mSelfServerScrollview:addCellBack(titleCell)
            end
            container.mSelfServerScrollview:orderCCBFileCells()
        end
        NodeHelper:setNodesVisible(container,{
            mEmptyFetterTxt = #curList < 1,
            mContent = false,
            mOtherServerNode = false,
            mServerContent = true,
        })
    else
        container.mScrollView:removeAllCell()
        curList = OSPVPManager:getRankList()
        local queenFlag = false
        if #curList >= 1 then
            for i,v in ipairs(curList) do
                if i == 1 then
                    local stage = OSPVPManager.checkStage(v.score,v.rank)
                    if stage.id == OSPVPManager:getMaxStage() then
                        queenFlag = true
                    else
                        local titleCell = CCBFileCell:create()
                        local panel = OSPVPVsContent:new({id = v.identify, index = i})
                        titleCell:registerFunctionHandler(panel)
                        titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
                        container.mScrollView:addCellBack(titleCell)
                    end
                elseif i > 1 then
                    local titleCell = CCBFileCell:create()
                    local panel = OSPVPVsContent:new({id = v.identify, index = i})
                    titleCell:registerFunctionHandler(panel)
                    titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
                    container.mScrollView:addCellBack(titleCell)
                end
            end
            container.mScrollView:orderCCBFileCells()
        end
        NodeHelper:setNodesVisible(container,{
            mEmptyFetterTxt = #curList < 1,
            mContent = true,
            mOtherServerNode = true,
            mServerContent = false,
            mQueenNode = queenFlag,
            mQueenEmpty = not queenFlag
        })
    end
    
end

return OSPVPRankPage