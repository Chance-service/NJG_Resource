local GVGManager = require("GVGManager")
local HP_pb = require("HP_pb")
local GVG_pb = require("GroupVsFunction_pb")
local Const_pb = require("Const_pb")
local thisPageName = "GVGRewardPage"
 
local GVGRewardPageBase = {
    rewardInfo = {},
    citys = {},
    nowRewarding = {}
}

local option = {
    ccbiFile = "GVGRewardPage.ccbi",
    handlerMap = {
        onReturnBtn = "onClose",
        onOpen = "onOpen",
        onGet = "onGet",
        onHelp = "onHelp"
    },
    opcodes = {
        PLAYER_AWARD_S = HP_pb.PLAYER_AWARD_S,
    }
}

local GVGInfoContent = {
    ccbiFile = "GVGRewardContent.ccbi",
    cityList = {}
}

local SCALE_MAP = {
    0.65,
    0.6,
    0.5
}

local sendReward = -1

local isOpenAni = false

local isLastOpen = false

local originalX,originalY = 0,0

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
    local imgMap = {}

    local data = GVGRewardPageBase.citys[index]
    if data then
        lb2Str.mCityName = data.cityName
        imgMap.mCityIcon = {normal = data.cityImg}
    end
    NodeHelper:setMenuItemImage(container,imgMap)
    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
end

function GVGInfoContent:onCity(container)
    local id = self.id
    local index = self.index
    local data = GVGRewardPageBase.citys[index]
    if data then
        GVGManager.setMailTargetCity(id)
        GVGManager.isGVGPageOpen = true
        GVGManager.reqGuildInfo()
    end
end

function GVGRewardPageBase:refreshPage(container)
    local data = GVGManager.getRewardInfo()
    local citys,rewarding = GVGManager.getRewardCityList()

    local sprite2Img = {}
    local scaleMap = {}
    local menu2Quality = {}
    local lb2Str = {}
    local visibleMap = {}

    if #rewarding > 0 then
        GVGRewardPageBase.nowRewarding = rewarding[1]

        NodeHelper:setMenuItemEnabled(container,"mOpenBtn",true)
    else
        GVGRewardPageBase.nowRewarding = {}
        isOpenAni = true
        if #citys == 0 then
            visibleMap.mBoxNode = false
            visibleMap.mBoxOpenNode = false
            isOpenAni = false
        end

        NodeHelper:setMenuItemEnabled(container,"mOpenBtn",false)
    end
    local curLevel = 1
    if GVGRewardPageBase.nowRewarding.level then
        curLevel = GVGRewardPageBase.nowRewarding.level
    elseif #citys > 0 then
        curLevel = citys[#citys].level or 1
    end
    sprite2Img.mBoxOpen = string.format("UI/Common/Image/Image_GvG_Box_Open%d.png", curLevel)
    sprite2Img.mBox = string.format("UI/Common/Image/Image_GvG_Box%d.png", curLevel)
    sprite2Img.mBoxCanOpen = string.format("UI/Common/Image/Image_GvG_Box%d.png", curLevel)
    if isOpenAni then
        if #rewarding == 0 then
            container:runAnimation("BoxOpen")
        end
    else
        if #rewarding > 0 then
            container:runAnimation("BoxStand")
        else
            container:runAnimation("Default Timeline")
        end
    end

    if data.reward and data.reward ~= "" then
        local reward = ConfigManager.getRewardByString(data.reward)
        local totalCoin = 0
        local totalGold = 0
        for i = 1, #reward do
            local rec = reward[i]
            if rec.type == 10000 then
                if rec.itemId == Const_pb.COIN then
                    totalCoin = totalCoin + rec.count
                elseif rec.itemId == Const_pb.GOLD then
                    totalGold = totalGold + rec.count
                end
            end
        end
        if totalGold > 0 then
            sprite2Img.mResIcon1 = "UI/Common/Icon/Icon_Diamond_S.png"
            lb2Str.mResNum1 = totalGold
        else
            sprite2Img.mResIcon1 = "UI/Common/Icon/Icon_Gold_S.png"
            lb2Str.mResNum1 = totalCoin
        end
        NodeHelper:setMenuItemEnabled(container,"mGet",true)
    else
        lb2Str.mResNum1 = 0
        sprite2Img.mResIcon1 = "UI/Common/Icon/Icon_Gold_S.png"
        NodeHelper:setMenuItemEnabled(container,"mGet",false)
    end
    lb2Str.mCityNumTxt = common:getLanguageString("@GVGRewardCityNumTxt", #citys)
    lb2Str.mBoxLevel = common:getLanguageString("@GVGRewardBoxLevel", #rewarding)

    NodeHelper:setNodesVisible(container,visibleMap)
    NodeHelper:setStringForLabel(container,lb2Str)
    NodeHelper:setSpriteImage(container,sprite2Img,scaleMap)
    NodeHelper:setQualityFrames(container, menu2Quality)
    
	NodeHelper:mainFrameSetPointVisible(
		{
            --mGuildPagePoint = NoticePointState.GUILD_SIGNIN or NoticePointState.ALLIANCE_BOSS_OPEN or GVGManager.needShowRewardNotice(),
			mGuildPagePoint = NoticePointState.GUILD_SIGNIN or NoticePointState.ALLIANCE_BOSS_OPEN
		}
	)

    GVGRewardPageBase.citys = citys
    
    self:clearAndReBuildAllItem(container)
end

function GVGRewardPageBase:onLoad(container)
    container:loadCcbiFile(option.ccbiFile)
end

function GVGRewardPageBase:onEnter(container)
    self:registerPacket(container)
    NodeHelper:initScrollView(container, "mContent", 10);
    originalX,originalY = container.mScrollView:getPosition()
    container:registerMessage(MSG_MAINFRAME_REFRESH) 
    self:refreshPage(container)
end

function GVGRewardPageBase:onExecute(container)
    if sendReward >= 0 then
        local dt = os.time() - sendReward
        if dt >= 1 then
            sendReward = -1
            GVGManager.reqRewardInfo()
        end
    end
end

function GVGRewardPageBase:onExit(container)
    self:removePacket(container)
    GVGRewardPageBase.rewardInfo = {}
    GVGRewardPageBase.nowRewarding = {}
    sendReward = -1
    isOpenAni = false
end

function GVGRewardPageBase:onClose(container)
    PageManager.changePage("GuildPage")
end

function GVGRewardPageBase:onOpen(container)
    local cityId = GVGRewardPageBase.nowRewarding.id
    if cityId then
        isOpenAni = true
        container:runAnimation("BoxAni")
        NodeHelper:setMenuItemEnabled(container,"mOpenBtn",false)
    end
end

function GVGRewardPageBase:onHelp(container)
	PageManager.showHelp(GameConfig.HelpKey.HELP_GVG_REWARD)
end

function GVGRewardPageBase:onAnimationDone(container)
    local animationName=tostring(container:getCurAnimationDoneName())
	if animationName == "BoxAni" then
        local citys,rewarding = GVGManager.getRewardCityList()
        local cityId = GVGRewardPageBase.nowRewarding.id
        if #rewarding - 1 > 0 then
            container:runAnimation("BoxChoice")
            --NodeHelper:setStringForLabel(container,{mBoxLevel = common:getLanguageString("@GVGRewardBoxLevel", #rewarding - 1)})
        else
            container:runAnimation("BoxOpen")
            --NodeHelper:setStringForLabel(container,{mBoxLevel = common:getLanguageString("@GVGRewardBoxLevel", 0)})
        end
        if cityId then
            sendReward = os.time()
            GVGManager.reqGetGVGBox(cityId)
        end
    elseif animationName == "BoxChoice" then
        isOpenAni = false
        self:refreshPage(container)
        --GVGManager.reqRewardInfo()
    elseif animationName == "BoxOpen" then
        if isLastOpen then
            isLastOpen = false
            --GVGManager.reqRewardInfo()
        end
	end
end

function GVGRewardPageBase:onGet(container)
    if sendReward >= 0 then return end
    sendReward = os.time()
    GVGManager.reqGetGVGAward()
    NodeHelper:setMenuItemEnabled(container,"mGet",false)
end

function GVGRewardPageBase:onReceivePacket(container)
	local opcode = container:getRecPacketOpcode()
	local msgBuff = container:getRecPacketBuffer()
    if opcode == HP_pb.PLAYER_AWARD_S then
    end
end

function GVGRewardPageBase:clearAndReBuildAllItem(container)
    container.mScrollView:removeAllCell()
    local citys = GVGRewardPageBase.citys
    
    if #citys >= 1 then
        for i,v in ipairs(citys) do
            --for j = 1, (math.random(1,2) == 1 and 2 or 10)  do
                local titleCell = CCBFileCell:create()
                local panel = GVGInfoContent:new({id = v.id, index = i})
                titleCell:registerFunctionHandler(panel)
                titleCell:setCCBFile(GVGInfoContent.ccbiFile)
                container.mScrollView:addCellBack(titleCell)
            --end
        end
        container.mScrollView:orderCCBFileCells()
        self:doScrollviewAlign(container.mScrollView)
    end
end

function GVGRewardPageBase:doScrollviewAlign(scrollView)
    local size = scrollView:getContentSize()
    if size.width < 590 then
        local offset = scrollView:maxContainerOffset()
        
        scrollView:setPosition(ccp(originalX - offset.x, originalY))
        local offMin = scrollView:maxContainerOffset()
        scrollView:setContentOffset(offMin)
        scrollView:setBounceable(false)
    else
        local offMin = scrollView:maxContainerOffset()
        scrollView:setContentOffset(offMin)
        scrollView:setBounceable(true)
    end
end

function GVGRewardPageBase:onReceiveMessage(container)
	local message = container:getMessage()
	local typeId = message:getTypeId()
	if typeId == MSG_MAINFRAME_REFRESH then
		local pageName = MsgMainFrameRefreshPage:getTrueType(message).pageName
        local extraParam = MsgMainFrameRefreshPage:getTrueType(message).extraParam
        if pageName == GVGManager.moduleName then
            if extraParam == GVGManager.onRewardInfo then
                self:refreshPage(container)
            elseif extraParam == GVGManager.onMapInfo then
                --local status = GVGManager.getGVGStatus()
                --local GVG_pb = require("GroupVsFunction_pb")
                --if status ~= GVG_pb.GVG_STATUS_WAITING then
                if GVGManager.isGVGPageOpen then
                    PageManager.changePage("GVGMapPage")
                end
                --else
                    --PageManager.changePage("GVGPreparePage")
                --end
            end
        end
	end
end

function GVGRewardPageBase:registerPacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:registerPacket(opcode)
		end
	end
end

function GVGRewardPageBase:removePacket(container)
	for key, opcode in pairs(option.opcodes) do
		if string.sub(key, -1) == "S" then
			container:removePacket(opcode)
		end
	end
end

-------------------------------------------------------------------------
local CommonPage = require("CommonPage");
local GVGRewardPage = CommonPage.newSub(GVGRewardPageBase, thisPageName, option);