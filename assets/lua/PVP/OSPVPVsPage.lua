local thisPageName = "OSPVPVsPage"
local OSPVPManager = require("OSPVPManager")
local CsBattle_pb = require("CsBattle_pb")
local UserInfo = require("PlayerInfo.UserInfo")
local OSPVPVsPage = {}

local option = {
    ccbiFile = "PVPBattleContent.ccbi",
    handlerMap = {
        onBuy = "onBuy",
        onReport = "onReport",
        onRefresh = "onRefresh"
    },
    opcodes = {
    }
}

local OSPVPVsContent = {
    ccbiFile = "PVPBattleListContent.ccbi",
}

local initFrame = false

local offsetWidth = 0.007

local targetWidth = -1

local tempStatus = false

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

    local list = OSPVPManager:getCurVsList()
    local data = list[index]

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
        lb2Str.mReward = common:getLanguageString("@PVPRankTxt") .. data.rank
        lb2Str.mContinueWin = common:getLanguageString("@PVPContinueWinTimes", data.continueWin)

        menuImg.mHand = stage.stageIcon

        --local awards = OSPVPManager.checkReward(data.rank)
        --if awards and awards[1] then
        visibleMap.mIconNumber = false
        --end

        visibleMap.mTrophyBG01 = false
        visibleMap.mTrophyBG02 = false
        visibleMap.mTrophyBG03 = false
        visibleMap.mTrophyBG04 = false
        local selfRank = OSPVPManager:getRank()
        if selfRank then
            if data.rank < selfRank then
                visibleMap.mTrophyBG01 = index == 1
                visibleMap.mTrophyBG02 = index ~= 1
            else
                visibleMap.mTrophyBG03 = not initFrame
                visibleMap.mTrophyBG04 = initFrame
            end
        end
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setNormalImages(container, menuImg)
end

function OSPVPVsContent:onDekaron(container)
    local id = self.id
    local index = self.index
    local list = OSPVPManager:getCurVsList()
    local data = list[index]
    if data then
        local serverId = string.gsub(data.serverName,".*#","")
        local serverName = GamePrecedure:getInstance():getServerNameById(tonumber(serverId));
        OSPVPManager:setCurDefName(data.name)
        OSPVPManager:setCurDefServer(common:getLanguageString("@PVPServerName",serverName))
        OSPVPManager.reqBattle(id)
    end
end

function OSPVPVsContent:onHand(container)
    OSPVPManager.reqOSPlayerInfo(self.id)
end

function OSPVPVsPage:create(base, ParentContainer)
    local o = {}
    self.__index = self
    setmetatable(o,self)
    o:onLoad(base, ParentContainer)
    return o
end

function OSPVPVsPage:onLoad(base, ParentContainer)
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

function OSPVPVsPage:onEnter(container)
    NodeHelper:initScrollView(container, "mContent", 10);
    self:clearAndReBuildAllItem(container)
    self:refreshPage(container)
end

function OSPVPVsPage:refreshPage(container)
    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}
    local selectedMap = {}

    local score = OSPVPManager.score
    local rank = OSPVPManager.rank
    local oldStage = OSPVPManager:getOldStage()
    local curStage = OSPVPManager.checkStage(score,rank)
    local nextStage = OSPVPManager.checkNextStage(score,rank)
    lb2Str.mPointNum = string.format("%d/%d",score, nextStage.score - 1)

    lb2Str.mTimes = common:getLanguageString("@PVPBattleTimes") .. " " .. OSPVPManager:getLeftVsTime()

    local midStr = ""
    local rank = OSPVPManager:getRank()
    if rank > 0 then
        midStr = midStr .. common:getLanguageString("@PVPRankPersonalTxt", rank)
    else
        midStr = midStr .. common:getLanguageString("@PVPRankNoTxt")
    end
    midStr = midStr .. "  " .. common:getLanguageString("@PVPContinueWinTimes", OSPVPManager:getContinueWin())
    lb2Str.mWinTimes = midStr

    sprite2Img.mNowPic = curStage.stageImg
    sprite2Img.mNowPic1 = nextStage.stageImg

    
    local mPointBar = container:getVarScale9Sprite("mPointBar")
    local flag = OSPVPManager.stageAnimFlag
    local oldScore = OSPVPManager:getOldScore()
    local score = OSPVPManager:getScore()
    if flag then
        container:runAnimation("Anim1")
        local curScore = curStage.score
        local nextScore = nextStage.score
        if oldStage and curStage.id ~= oldStage.id then
            curScore = oldStage.score
            nextScore = curStage.score
            sprite2Img.mNowPic = oldStage.stageImg
            sprite2Img.mNowPic1 = curStage.stageImg
            visibleMap.mNextPic = false
            visibleMap.mNextPic1 = false
        else
            sprite2Img.mNowPic = curStage.stageImg
            sprite2Img.mNowPic1 = nextStage.stageImg
            visibleMap.mNextPic = false
            visibleMap.mNextPic1 = false
        end
        
        local percent = (oldScore - curScore) / (nextScore - curScore)
        mPointBar:setScaleX(percent)
    else
        if oldStage and curStage.id ~= oldStage.id then
            sprite2Img.mNowPic = oldStage.stageImg
            sprite2Img.mNowPic1 = curStage.stageImg
            if curStage.id == OSPVPManager:getMaxStage() then
                container:runAnimation("Top")
            else
                container:runAnimation("Chage")
                sprite2Img.mNextPic = curStage.stageImg
                sprite2Img.mNextPic1 = nextStage.stageImg
            end
        else
            if curStage.id == OSPVPManager:getMaxStage() then
                container:runAnimation("TopIdol")
            else
                container:runAnimation("Anim1")
                sprite2Img.mNowPic = curStage.stageImg
                sprite2Img.mNowPic1 = nextStage.stageImg
                visibleMap.mNextPic = false
                visibleMap.mNextPic1 = false
            end
        end
        
        if OSPVPManager.curResult ~= nil then
            local result = OSPVPManager.curResult
            local def = OSPVPManager:getCurDefName()
            if result then
                MessageBoxPage:Msg_Box(common:getLanguageString("@PVPResultWin",score - oldScore))
            else
                MessageBoxPage:Msg_Box(common:getLanguageString("@PVPResultLose"))
            end

            OSPVPManager.curResult = nil
            OSPVPManager:setCurDefName("")
            OSPVPManager:setCurDefServer("")
        end

        local curScore = curStage.score
        local nextScore = nextStage.score
        local percent = (score - curScore) / (nextScore - curScore)
        
        if score > oldScore then
            local oldPercent = (math.max(oldScore,curScore) - curScore) / (nextScore - curScore)
            mPointBar:setScaleX(oldPercent)
            targetWidth = percent
        else
            mPointBar:setScaleX(percent)
        end
        OSPVPManager:setOldScore(score)
        OSPVPManager:setOldRank(rank)
    end

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    NodeHelper:setMenuItemSelected(container,selectedMap)
end

function OSPVPVsPage:onExecute(container)
    if targetWidth ~= -1 then
        local mPointBar = container:getVarScale9Sprite("mPointBar")
        local scaleX = mPointBar:getScaleX()
        scaleX = scaleX + offsetWidth
        mPointBar:setScaleX(scaleX)
        if scaleX >= targetWidth then
            targetWidth = -1
        end
    end

    if OSPVPManager.stageAnimFlag ~= tempStatus then
        tempStatus = OSPVPManager.stageAnimFlag
        self:refreshPage(container)
    end
end

function OSPVPVsPage:onExit(container)
    targetWidth = -1
    onUnload(thisPageName,container)
end

function OSPVPVsPage:onAnimationDone(container)
    local animationName = tostring(container:getCurAnimationDoneName())
    if animationName == "Top" then
        container:runAnimation("TopIdol")
    end
end

function OSPVPVsPage:onBuy(container)
    local title = common:getLanguageString("@BuyTimesTitle")
    local message = common:getLanguageString("@OSPVPBuyMaxNum", OSPVPManager:getTotalBuyTime())
    PageManager.showCountTimesPage(
        title,
        message,
        OSPVPManager:getLeftBuyTime(),
        function(times)
            local totalPrice = 0
            local buyedTimes = OSPVPManager:getBuyedTime()
            local totalTimes = OSPVPManager:getTotalBuyTime()
            for i= buyedTimes + 1,buyedTimes + times do 
                local index = i;
                if i > totalTimes then
                    index = totalTimes
                end

                local costInfo = OSPVPManager.getBuyTimeCost(index)
                if costInfo ~= nil then
                    totalPrice = totalPrice + costInfo
                end
            end

            return totalPrice
        end,
        Const_pb.MONEY_GOLD,
        function(flag, times)
            if flag then
                OSPVPManager.reqAddPVPNum(times)
            end
        end,
        nil,nil,nil,5
        )
end

function OSPVPVsPage:onReport(container)
    OSPVPManager.reqSyncPlayer()
end

function OSPVPVsPage:onRefresh(container)
    OSPVPManager.reqRefreshVsInfo()
end

function OSPVPVsPage:onReceiveMessage(message)
	local typeId = message:getTypeId()
    local container = self.container
	if typeId == MSG_MAINFRAME_REFRESH then        
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == OSPVPManager.moduleName then
            if extraParam == OSPVPManager.onStage then
                self:refreshPage(container)
            elseif extraParam == OSPVPManager.onVsList then
                self:clearAndReBuildAllItem(container)
            elseif extraParam == OSPVPManager.onLeftVsTime then
                self:refreshPage(container)
            elseif extraParam == OSPVPManager.onPlayerInfo then
                self:refreshPage(container)
            elseif extraParam == OSPVPManager.onContinueWin then
                self:refreshPage(container)
            end
        end
	end
end

function OSPVPVsPage:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local list = OSPVPManager:getCurVsList()
    if #list >= 1 then
        initFrame = false
        for i,v in ipairs(list) do
            local titleCell = CCBFileCell:create()
            local panel = OSPVPVsContent:new({id = v.identify, index = i})
            titleCell:registerFunctionHandler(panel)
            titleCell:setCCBFile(OSPVPVsContent.ccbiFile)
            container.mScrollView:addCellBack(titleCell)
        end
        container.mScrollView:orderCCBFileCells()
    end
    NodeHelper:setNodesVisible(container,{mEmptyFetterTxt = #list < 1})
end

return OSPVPVsPage